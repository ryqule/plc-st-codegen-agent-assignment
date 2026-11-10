PROGRAM S09
VAR_INPUT
    SourceLevel : REAL;
    DestinationLevel : REAL;
    TransferEnable : BOOL;
    SourceLow : BOOL;
    DestinationHighHigh : BOOL;
    PumpFault : BOOL;
    Reset : BOOL;
END_VAR
VAR_OUTPUT
    TransferPump : BOOL := FALSE;
    SourceLowAlarm : BOOL := FALSE;
    DestinationHighAlarm : BOOL := FALSE;
END_VAR
VAR
    resetPrevious : BOOL := FALSE;
    resetEdge : BOOL := FALSE;
END_VAR

(* Rising-edge detection; a held Reset does not repeatedly clear alarms. *)
resetEdge := Reset AND NOT resetPrevious;
resetPrevious := Reset;

(* Independent alarm latches: active conditions dominate Reset. *)
IF SourceLow THEN
    SourceLowAlarm := TRUE;
ELSIF resetEdge THEN
    SourceLowAlarm := FALSE;
END_IF;

IF DestinationHighHigh THEN
    DestinationHighAlarm := TRUE;
ELSIF resetEdge THEN
    DestinationHighAlarm := FALSE;
END_IF;

(* Re-evaluate all permissives every scan to preserve the pump invariant.
   Alarm history does not inhibit transfer once the input conditions clear. *)
TransferPump :=
    TransferEnable
    AND (SourceLevel > 20.0)
    AND (DestinationLevel < 80.0)
    AND NOT SourceLow
    AND NOT DestinationHighHigh
    AND NOT PumpFault;

END_PROGRAM