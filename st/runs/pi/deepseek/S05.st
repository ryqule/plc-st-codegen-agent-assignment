```st
FUNCTION_BLOCK FB_CoolingFanStaging
VAR_INPUT
    Temperature : REAL;
    Fan1Fault   : BOOL;
    Fan2Fault   : BOOL;
    CycleTime   : TIME;
    Enable      : BOOL;
END_VAR

VAR_OUTPUT
    Fan1         : BOOL;
    Fan2         : BOOL;
    CoolingAlarm : BOOL;
END_VAR

VAR
    (* Stage: 0 = off, 1 = one fan, 2 = two fans *)
    Stage : INT := 0;

    (* Dwell timers - elapsed accumulators *)
    Fan1OnElapsed  : TIME := T#0s;
    Fan1OffElapsed : TIME := T#0s;
    Fan2OnElapsed  : TIME := T#0s;
    Fan2OffElapsed : TIME := T#0s;

    (* Internal desired (pre-dwell, post-interlock) fan commands *)
    Fan1Cmd : BOOL := FALSE;
    Fan2Cmd : BOOL := FALSE;

    (* Derived conditions *)
    InvalidTemp    : BOOL;
    BothFansFaulted: BOOL;
    AnyHealthy     : BOOL;

    (* Dwell-done flags *)
    Fan1OnDone  : BOOL;
    Fan2OnDone  : BOOL;
    Fan1OffDone : BOOL;
    Fan2OffDone : BOOL;

    (* Hysteresis / stage transition requests *)
    StageNext : INT;
END_VAR

BEGIN

    (* ------------------------------------------------------------------
       Input validation
       ------------------------------------------------------------------ *)
    InvalidTemp     := (Temperature < -20.0) OR (Temperature > 80.0);
    BothFansFaulted := Fan1Fault AND Fan2Fault;
    AnyHealthy      := (NOT Fan1Fault) OR (NOT Fan2Fault);

    (* ------------------------------------------------------------------
       Dwell timer accumulation for each fan.
       A fan "on dwell timer" accumulates only while the fan is on;
       an "off dwell timer" accumulates only while the fan is off.
       These are reset to zero when the opposite action occurs.
       ------------------------------------------------------------------ *)
    IF Fan1 THEN
        Fan1OnElapsed  := Fan1OnElapsed + CycleTime;
        Fan1OffElapsed := T#0s;
    ELSE
        Fan1OffElapsed := Fan1OffElapsed + CycleTime;
        Fan1OnElapsed  := T#0s;
    END_IF;

    IF Fan2 THEN
        Fan2OnElapsed  := Fan2OnElapsed + CycleTime;
        Fan2OffElapsed := T#0s;
    ELSE
        Fan2OffElapsed := Fan2OffElapsed + CycleTime;
        Fan2OnElapsed  := T#0s;
    END_IF;

    Fan1OnDone  := Fan1OnElapsed  >= T#10s;
    Fan2OnDone  := Fan2OnElapsed  >= T#10s;
    Fan1OffDone := Fan1OffElapsed >= T#10s;
    Fan2OffDone := Fan2OffElapsed >= T#10s;

    (* ------------------------------------------------------------------
       Immediate override: invalid temperature, disabled, or both faulted.
       Per spec, invalid/!Enable forces fans off this scan (X(!Fan1 & !Fan2)).
       Both-faulted also forces off and raises alarm.
       ------------------------------------------------------------------ *)
    IF (NOT Enable) OR InvalidTemp OR BothFansFaulted THEN
        Fan1 := FALSE;
        Fan2 := FALSE;
        Stage :=