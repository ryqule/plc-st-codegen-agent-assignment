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
    (* Demand stage: 0 = off, 1 = one fan, 2 = two fans *)
    Stage          : INT := 0;

    (* Per-fan dwell timers, accumulated independently *)
    Fan1OnTimer    : TIME := T#0S;
    Fan1OffTimer   : TIME := T#0S;
    Fan2OnTimer    : TIME := T#0S;
    Fan2OffTimer   : TIME := T#0S;

    (* Timer completion predicates *)
    Fan1MinOnDone  : BOOL;
    Fan1MinOffDone : BOOL;
    Fan2MinOnDone  : BOOL;
    Fan2MinOffDone : BOOL;

    (* Derived conditions *)
    InvalidTemp    : BOOL;
    BothFaulted    : BOOL;
    AnyHealthy     : BOOL;
    TwoHealthy     : BOOL;

    (* Internal fan commands before dwell application *)
    ReqFan1        : BOOL;
    ReqFan2        : BOOL;

    (* Dwell application results *)
    NextFan1       : BOOL;
    NextFan2       : BOOL;

    (* Valid step increment *)
    Step           : TIME;

    (* Minimum dwell constant *)
    MinDwell       : TIME := T#10S;

    (* Loop / index helpers *)
    i              : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* 0. Sanitize cycle time: negative or zero cycle does not advance     *)
(* ------------------------------------------------------------------ *)
IF CycleTime > T#0S THEN
    Step := CycleTime;
ELSE
    Step := T#0S;
END_IF;

(* ------------------------------------------------------------------ *)
(* 1. Derived conditions                                               *)
(* ------------------------------------------------------------------ *)
InvalidTemp := (Temperature < -20.0) OR (Temperature > 80.0);
BothFaulted := Fan1Fault AND Fan2Fault;
AnyHealthy  := NOT BothFaulted;
TwoHealthy  := (NOT Fan1Fault) AND (NOT Fan2Fault);

(* ------------------------------------------------------------------ *)
(* 2. Alarm: invalid temperature or both fans faulted                  *)
(* ------------------------------------------------------------------ *)
CoolingAlarm := InvalidTemp OR BothFaulted;

(* ------------------------------------------------------------------ *)
(* 3. Stage transition logic (hysteresis)                              *)
(*    Stage is evaluated each scan; dwell is applied to fans only.     *)
(* ------------------------------------------------------------------ *)
IF (NOT Enable) OR InvalidTemp THEN
    (* Immediate override: both fans off, stage reset *)
    Stage := 0;
ELSIF BothFaulted THEN
    (* Both faulted: no healthy fan available *)
    Stage := 0;
ELSE
    CASE Stage OF
        0:
            (* Request one fan at >= 35 C *)
            IF (Temperature >= 35.0) AND AnyHealthy THEN
                Stage := 1;
            END_IF;

        1:
            (* Escalate to two fans at >= 45 C *)
            IF (Temperature >= 45.0) AND TwoHealthy THEN
                Stage := 2;
            (* Drop only below 32 C, and only if active fan has met min-on *)
            ELSIF (Temperature < 32.0) THEN