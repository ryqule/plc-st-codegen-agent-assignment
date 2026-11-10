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
    qualifiedRise  : BOOL := FALSE;
    pulseActive    : BOOL := FALSE;
    pulseElapsed   : TIME := T#0ms;
    pulse300msDone : BOOL := FALSE;
END_VAR

(* The unconditional formulas conflict when permissives disappear,
   Reset coincides with a counted edge, or Reset coincides with pulse
   completion. Explicit precedence: output permissives dominate,
   Reset dominates counting, and pulse completion ends the pulse.
   Each qualified edge starts/restarts the pulse interval. *)

defectRise := Defect AND NOT prevDefect;
qualifiedRise := defectRise AND PartPresent AND ConveyorRunning;
prevDefect := Defect;

(* Advance an existing pulse using the supplied scan duration.
   Comparing against remaining time avoids accumulation overflow. *)
pulse300msDone := FALSE;

IF pulseActive THEN
    IF CycleTime > T#0ms THEN
        IF CycleTime >= (T#300ms - pulseElapsed) THEN
            pulseElapsed := T#300ms;
            pulse300msDone := TRUE;
            pulseActive := FALSE;
        ELSE
            pulseElapsed := pulseElapsed + CycleTime;
        END_IF;
    END_IF;
END_IF;

IF qualifiedRise THEN
    pulseActive := TRUE;
    pulseElapsed := T#0ms;
    pulse300msDone := FALSE;
END_IF;

IF Reset THEN
    RejectCount := UDINT#0;
ELSIF qualifiedRise THEN
    IF RejectCount < UDINT#4294967295 THEN
        RejectCount := RejectCount + UDINT#1;
    END_IF;
END_IF;

RejectSolenoid := pulseActive AND PartPresent AND ConveyorRunning;

(* T1: qualified rising edge starts the pulse and increments the count.
   T2: prevDefect prevents repeated-high counting.
   T3 / L1: permissives gate both edge acceptance and physical output.
   T4: Reset clears only the count; pulse timing remains independent.
   T5: the maximum-value guard prevents count wraparound. *)
END_PROGRAM