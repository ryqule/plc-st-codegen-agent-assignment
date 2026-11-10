```st
FUNCTION_BLOCK FB_JamRetry
VAR_INPUT
    Start         : BOOL;
    Stop          : BOOL;
    EStopOK       : BOOL;
    PartAtEntry   : BOOL;
    PartAtExit    : BOOL;
    Jam           : BOOL;
    CycleTime     : TIME;
END_VAR

VAR_OUTPUT
    ConveyorForward : BOOL;
    ConveyorReverse : BOOL;
    FaultLatched    : BOOL;
    RetryCount      : USINT;
END_VAR

VAR
    (* edge detection *)
    rtStart       : R_TRIG;
    rtEntry       : R_TRIG;

    (* part-cycle / motion state *)
    partActive    : BOOL;

    (* reverse timer *)
    tonReverse    : TON;
    reverseActive : BOOL;

    (* jam bookkeeping *)
    jamActive     : BOOL;   (* a jam event is pending handling *)

    (* scanned outputs (internal) *)
    fwdCmd        : BOOL;
    revCmd        : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Edge detection                                                       *)
(* ------------------------------------------------------------------ *)
rtStart(CLK := Start);
rtEntry(CLK := PartAtEntry);

(* ------------------------------------------------------------------ *)
(* Defaults each scan                                                   *)
(* ------------------------------------------------------------------ *)
fwdCmd := FALSE;
revCmd := FALSE;

(* ------------------------------------------------------------------ *)
(* E-stop: level-sensitive, dominates everything, latches fault        *)
(* ------------------------------------------------------------------ *)
IF NOT EStopOK THEN
    FaultLatched  := TRUE;
    fwdCmd        := FALSE;
    revCmd        := FALSE;
    reverseActive := FALSE;
    tonReverse(IN := FALSE, PT := T#1S);
END_IF;

(* ------------------------------------------------------------------ *)
(* Valid fault clear: rising edge of Start while safe                  *)
(* ------------------------------------------------------------------ *)
IF rtStart.Q AND EStopOK AND NOT Jam AND NOT Stop THEN
    FaultLatched := FALSE;
END_IF;

(* ------------------------------------------------------------------ *)
(* PartAtExit: end part cycle, reset retry count                       *)
(* ------------------------------------------------------------------ *)
IF PartAtExit THEN
    partActive    := FALSE;
    RetryCount    := 0;
    reverseActive := FALSE;
    tonReverse(IN := FALSE, PT := T#1S);
    jamActive     := FALSE;
END_IF;

(* ------------------------------------------------------------------ *)
(* PartAtEntry rising edge begins a part cycle while Start & not Stop  *)
(* ------------------------------------------------------------------ *)
IF rtEntry.Q AND Start AND NOT Stop AND EStopOK AND NOT FaultLatched
   AND NOT partActive THEN
    partActive := TRUE;
END_IF;

(* ------------------------------------------------------------------ *)
(* Reverse timer update                                                *)
(* ------------------------------------------------------------------ *)
tonReverse(IN := reverseActive, PT := T#1S);

(* ------------------------------------------------------------------ *)
(* Jam handling                                                        *)
(* ------------------------------------------------------------------ *)
IF EStopOK AND NOT FaultLatched AND NOT Stop THEN

    IF Jam AND fwdCmd THEN
        (* Jam during forward: forward drops same scan, start reverse,
           increment retry count once per jam event.               *)
        fwdCmd := FALSE;
        IF NOT jamActive THEN
            jamActive := TRUE;
            IF RetryCount < 2 THEN
                RetryCount := RetryCount + 1;
                reverseActive := TRUE;
            ELSE
                (* third event at count 2 -> latch fault *)
                FaultLatched  := TRUE;
                reverseActive := FALSE;
            END_IF;
        END_IF;
        revCmd := NOT FaultLatched AND reverseActive;
    ELSE
        (* Jam cleared if not active during forward *)
        IF NOT Jam AND NOT reverseActive THEN