```st
FUNCTION_BLOCK FB_JamConveyor
VAR_INPUT
    Start        : BOOL;
    Stop         : BOOL;
    EStopOK      : BOOL;
    PartAtEntry  : BOOL;
    PartAtExit   : BOOL;
    Jam          : BOOL;
    CycleTime    : TIME;
END_VAR

VAR_OUTPUT
    ConveyorForward : BOOL;
    ConveyorReverse : BOOL;
    FaultLatched    : BOOL;
    RetryCount      : USINT;
END_VAR

VAR
    rtPartEntry      : R_TRIG;
    rtStart          : R_TRIG;
    rtExit           : R_TRIG;
    rtJam            : R_TRIG;

    tonReverse       : TON;

    partActive       : BOOL;
    reversing        : BOOL;
    reverse1sDone    : BOOL;
    jamEvent         : BOOL;
END_VAR

(* ---------- Edge detection ---------- *)
rtPartEntry(CLK := PartAtEntry);
rtStart(CLK := Start);
rtExit(CLK := PartAtExit);
rtJam(CLK := Jam);

(* ---------- Reverse timer (1 s bounded retry) ---------- *)
tonReverse(IN := reversing, PT := T#1s);
reverse1sDone := tonReverse.Q;

(* ---------- Safety dominance: E-stop latches fault ---------- *)
IF NOT EStopOK THEN
    FaultLatched := TRUE;
END_IF

(* ---------- Valid fault clear: Start rising edge, EStop OK, no Jam ---------- *)
IF rtStart.Q AND EStopOK AND NOT Jam THEN
    FaultLatched := FALSE;
END_IF

(* ---------- Part cycle start ---------- *)
IF rtPartEntry.Q AND Start AND NOT Stop THEN
    IF NOT FaultLatched THEN
        partActive := TRUE;
    END_IF
END_IF

(* ---------- Part cycle end ---------- *)
IF rtExit.Q THEN
    partActive    := FALSE;
    RetryCount    := 0;
    reversing     := FALSE;
END_IF

(* ---------- Jam event during forward motion ---------- *)
jamEvent := Jam AND ConveyorForward;

(* ---------- State / output computation ---------- *)
(* Default: no motion *)
ConveyorForward := FALSE;
ConveyorReverse := FALSE;

IF NOT EStopOK THEN
    (* E-stop dominates: stop everything, fault latched above *)
    reversing := FALSE;

ELSIF Stop THEN
    (* Stop dominates normal: both directions disabled immediately *)
    ConveyorForward := FALSE;
    ConveyorReverse := FALSE;
    reversing := FALSE;

ELSIF FaultLatched THEN
    (* Fault dominates normal operation *)
    ConveyorForward := FALSE;
    ConveyorReverse := FALSE;
    reversing := FALSE;

ELSE
    (* Normal operation *)
    IF jamEvent THEN
        (* Forward drops same scan; start a reverse attempt *)
        ConveyorForward := FALSE;
        IF RetryCount < 2 THEN
            RetryCount := RetryCount + 1;
            reversing  := TRUE;
        ELSE
            (* Third jam event: latch fault, count stays at 2 *)
            FaultLatched := TRUE;
            reversing    := FALSE;
        END_IF
    ELSIF reversing THEN
        IF reverse1sDone THEN
            (* Reverse interval finished: retry forward if jam cleared *)
            IF NOT Jam THEN
                reversing := FALSE;
                IF partActive THEN
                    ConveyorForward := TRUE;
                END_IF
            END_IF
            (* If jam still active, keep reversing