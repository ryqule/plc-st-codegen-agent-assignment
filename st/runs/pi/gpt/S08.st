PROGRAM S08
VAR_INPUT
    PartPresent     : BOOL;
    Defect          : BOOL;
    ConveyorRunning : BOOL;
    CycleTime       : TIME;
    Reset           : BOOL;
END_VAR
VAR_OUTPUT
    RejectSolenoid : BOOL := FALSE;
    RejectCount    : UDINT := UDINT#0;
END_VAR
VAR
    prevDefect     : BOOL := FALSE;
    defectRise     : BOOL := FALSE;
    pulseActive    : BOOL := FALSE;
    pulseElapsed   : TIME := T#0ms;
    pulse300msDone : BOOL := FALSE;
    validReject    : BOOL := FALSE;
END_VAR

defectRise := Defect AND NOT prevDefect;
validReject := defectRise AND PartPresent AND ConveyorRunning;
pulse300msDone := FALSE;

(* Advance an existing pulse. The triggering scan starts at zero;
   subsequent scans accumulate CycleTime, with scan-level resolution. *)
IF pulseActive THEN
    IF CycleTime > T#0ms THEN
        IF CycleTime >= (T#300ms - pulseElapsed) THEN
            pulseElapsed := T#300ms;
            pulseActive := FALSE;
            pulse300msDone := TRUE;
        ELSE
            pulseElapsed := pulseElapsed + CycleTime;
        END_IF;
    END_IF;
END_IF;

(* Count every qualified rising edge, saturating rather than wrapping.
   Reset dominates counting and does not modify the pulse timer. *)
IF Reset THEN
    RejectCount := UDINT#0;
ELSIF validReject THEN
    IF RejectCount < UDINT#4294967295 THEN
        RejectCount := RejectCount + UDINT#1;
    END_IF;
END_IF;

(* Non-retriggering one-shot: a qualified edge starts a pulse when idle.
   Edges during an active pulse are counted without extending that pulse. *)
IF validReject AND NOT pulseActive THEN
    pulseActive := TRUE;
    pulseElapsed := T#0ms;
END_IF;

(* Output permissives dominate; loss of a permissive does not reset
   the internal pulse timer. *)
RejectSolenoid := pulseActive AND PartPresent AND ConveyorRunning;

prevDefect := Defect;
END_PROGRAM