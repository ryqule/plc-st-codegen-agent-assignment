PROGRAM S03
VAR_INPUT
    Level : REAL;
    StartPermit : BOOL;
    HighHigh : BOOL;
    ResetAlarm : BOOL;
END_VAR
VAR_OUTPUT
    InletValve : BOOL := FALSE;
    HighLevelAlarm : BOOL := FALSE;
END_VAR
VAR
    previousResetAlarm : BOOL := FALSE;
    resetAlarmEdge : BOOL := FALSE;
    validLevel : BOOL := FALSE;
END_VAR

(* Scan-local input predicates; no timers are required. *)
resetAlarmEdge := ResetAlarm AND NOT previousResetAlarm;
validLevel := (Level >= 0.0) AND (Level <= 100.0);

(* Apply interlocks using the alarm state at scan entry.
   An alarm reset therefore cannot reopen the valve in the same scan. *)
IF HighHigh OR NOT validLevel OR NOT StartPermit OR HighLevelAlarm THEN
    InletValve := FALSE;
ELSIF Level >= 70.0 THEN
    InletValve := FALSE;
ELSIF Level <= 30.0 THEN
    InletValve := TRUE;
END_IF;
(* Between 30 and 70, retain the valve command unless interlocked. *)

(* High-high dominates reset. Invalid level alone does not latch alarm. *)
IF HighHigh THEN
    HighLevelAlarm := TRUE;
ELSIF resetAlarmEdge AND (Level < 70.0) THEN
    HighLevelAlarm := FALSE;
END_IF;

previousResetAlarm := ResetAlarm;
END_PROGRAM