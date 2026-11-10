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

(* Derive scan predicates and detect the reset rising edge. *)
validLevel := (Level >= 0.0) AND (Level <= 100.0);
resetAlarmEdge := ResetAlarm AND NOT previousResetAlarm;

(*
    Update the valve using the alarm state at scan entry.
    This preserves alarm inhibition even on the scan that clears the alarm.
    Neither output is declared RETAIN.
*)
IF HighHigh OR NOT validLevel OR NOT StartPermit OR HighLevelAlarm THEN
    InletValve := FALSE;
ELSIF Level >= 70.0 THEN
    InletValve := FALSE;
ELSIF Level <= 30.0 THEN
    InletValve := TRUE;
END_IF;
(* Otherwise retain the valve state within the hysteresis band. *)

(* HighHigh dominates reset; invalid level alone does not latch the alarm. *)
IF HighHigh THEN
    HighLevelAlarm := TRUE;
ELSIF resetAlarmEdge AND NOT HighHigh AND (Level < 70.0) THEN
    HighLevelAlarm := FALSE;
END_IF;

previousResetAlarm := ResetAlarm;

END_PROGRAM