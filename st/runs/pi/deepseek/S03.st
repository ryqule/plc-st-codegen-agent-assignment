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
    ResetAlarmPrev  : BOOL;   (* for rising-edge detection *)
    ResetAlarmEdge  : BOOL;
    ValidLevel      : BOOL;
    FillActive      : BOOL;   (* hysteresis latch: TRUE while filling *)
END_VAR

(* --- Edge detection on ResetAlarm --- *)
ResetAlarmEdge := ResetAlarm AND NOT ResetAlarmPrev;
ResetAlarmPrev := ResetAlarm;

(* --- Level validity --- *)
ValidLevel := (Level >= 0.0) AND (Level <= 100.0);

(* --- Alarm latch: set by HighHigh, cleared only by safe reset edge --- *)
IF HighHigh THEN
    HighLevelAlarm := TRUE;
ELSIF ResetAlarmEdge AND NOT HighHigh AND (Level < 70.0) THEN
    HighLevelAlarm := FALSE;
END_IF;

(* --- Fill hysteresis latch --- *)
IF (NOT ValidLevel) OR HighHigh OR (NOT StartPermit) OR HighLevelAlarm OR (Level >= 70.0) THEN
    FillActive := FALSE;
ELSIF (Level <= 30.0) AND StartPermit AND NOT HighHigh AND ValidLevel AND NOT HighLevelAlarm THEN
    FillActive := TRUE;
END_IF;

(* --- Output: valve open only while fill latch active and all permissives hold --- *)
InletValve := FillActive
              AND ValidLevel
              AND StartPermit
              AND NOT HighHigh
              AND NOT HighLevelAlarm
              AND (Level < 70.0);
END_FUNCTION_BLOCK