FUNCTION_BLOCK FB_TankFillHysteresis
VAR_INPUT
    Level        : REAL;   (* 0..100 percent *)
    StartPermit  : BOOL;
    HighHigh     : BOOL;
    ResetAlarm   : BOOL;
END_VAR

VAR_OUTPUT
    InletValve      : BOOL;
    HighLevelAlarm  : BOOL;
END_VAR

VAR
    ResetAlarmPrev  : BOOL;   (* previous scan value of ResetAlarm for edge detection *)
    ResetAlarmEdge  : BOOL;   (* rising edge of ResetAlarm *)
    ValidLevel      : BOOL;   (* Level within 0..100 inclusive *)
    FillActive      : BOOL;   (* internal hysteresis latch for valve *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Edge detection on ResetAlarm (rising edge)                          *)
(* ------------------------------------------------------------------ *)
ResetAlarmEdge := ResetAlarm AND NOT ResetAlarmPrev;
ResetAlarmPrev := ResetAlarm;

(* ------------------------------------------------------------------ *)
(* Sensor validity: valid when 0 <= Level <= 100                       *)
(* ------------------------------------------------------------------ *)
ValidLevel := (Level >= 0.0) AND (Level <= 100.0);

(* ------------------------------------------------------------------ *)
(* Alarm latch: set by HighHigh, cleared only by a valid reset edge    *)
(* (ResetAlarm rising edge, HighHigh FALSE, Level < 70)                *)
(* Invalid level does NOT latch the alarm.                             *)
(* ------------------------------------------------------------------ *)
IF HighHigh THEN
    HighLevelAlarm := TRUE;
ELSIF ResetAlarmEdge AND NOT HighHigh AND (Level < 70.0) THEN
    HighLevelAlarm := FALSE;
END_IF;

(* ------------------------------------------------------------------ *)
(* Hysteresis latch for the inlet valve                                *)
(*  - Set when Level <= 30, StartPermit, no HighHigh, valid level,     *)
(*    and no latched alarm.                                            *)
(*  - Held while Level < 70, StartPermit, no HighHigh, valid level.    *)
(*  - Cleared by Level >= 70, HighHigh, invalid level, or no permit.   *)
(* ------------------------------------------------------------------ *)
IF (NOT ValidLevel) OR HighHigh OR (NOT StartPermit) OR HighLevelAlarm THEN
    FillActive := FALSE;
ELSIF Level >= 70.0 THEN
    FillActive := FALSE;
ELSIF Level <= 30.0 THEN
    FillActive := TRUE;
ELSIF FillActive AND (Level < 70.0) THEN
    FillActive := TRUE;
END_IF;

(* ------------------------------------------------------------------ *)
(* Output: valve follows the hysteresis latch, but is hard-inhibited   *)
(* by safety / validity conditions (defensive interlock).              *)
(* ------------------------------------------------------------------ *)
InletValve := FillActive
              AND ValidLevel
              AND StartPermit
              AND NOT HighHigh
              AND NOT HighLevelAlarm;

END_FUNCTION_BLOCK