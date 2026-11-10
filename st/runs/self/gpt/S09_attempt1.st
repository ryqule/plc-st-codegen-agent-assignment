PROGRAM S09
VAR_INPUT
    SourceLevel         : REAL;
    DestinationLevel    : REAL;
    TransferEnable      : BOOL;
    SourceLow           : BOOL;
    DestinationHighHigh : BOOL;
    PumpFault           : BOOL;
    Reset               : BOOL;
END_VAR

VAR_OUTPUT
    TransferPump         : BOOL := FALSE;
    SourceLowAlarm       : BOOL := FALSE;
    DestinationHighAlarm : BOOL := FALSE;
END_VAR

VAR
    ResetPrevious : BOOL := FALSE;
    resetEdge     : BOOL := FALSE;
END_VAR

(* Non-retentive initialization. No timers are required.
   Detect a Reset rising edge using the previous scan's input. *)
resetEdge := Reset AND NOT ResetPrevious;
ResetPrevious := Reset;

(* Independent, condition-dominant alarm latches.
   Reset cannot clear an alarm while its condition is active. *)
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

(* Recompute the pump command every scan.
   All stop inputs dominate; level permissives remain mandatory
   while running, as required by invariant S09-L1.
   Latched alarms do not introduce additional pump interlocks. *)
TransferPump :=
    TransferEnable
    AND (SourceLevel > 20.0)
    AND (DestinationLevel < 80.0)
    AND NOT SourceLow
    AND NOT DestinationHighHigh
    AND NOT PumpFault;

END_PROGRAM