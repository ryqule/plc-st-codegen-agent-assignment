FUNCTION_BLOCK FB_TwoTankTransfer
VAR_INPUT
    SourceLevel        : REAL;
    DestinationLevel   : REAL;
    TransferEnable     : BOOL;
    SourceLow          : BOOL;
    DestinationHighHigh: BOOL;
    PumpFault          : BOOL;
    Reset              : BOOL;
END_VAR
VAR_OUTPUT
    TransferPump       : BOOL;
    SourceLowAlarm     : BOOL;
    DestinationHighAlarm : BOOL;
END_VAR
VAR
    ResetPrev          : BOOL;
    ResetEdge          : BOOL;
END_VAR

(* Rising-edge detection of Reset *)
ResetEdge := Reset AND NOT ResetPrev;
ResetPrev := Reset;

(* Latch SourceLow alarm: set when SourceLow TRUE, clear only on Reset edge with condition FALSE *)
IF SourceLow THEN
    SourceLowAlarm := TRUE;
ELSIF ResetEdge AND NOT SourceLow THEN
    SourceLowAlarm := FALSE;
END_IF;

(* Latch DestinationHighHigh alarm: set when TRUE, clear only on Reset edge with condition FALSE *)
IF DestinationHighHigh THEN
    DestinationHighAlarm := TRUE;
ELSIF ResetEdge AND NOT DestinationHighHigh THEN
    DestinationHighAlarm := FALSE;
END_IF;

(* Pump command: non-retentive, evaluated each scan.
   Stop conditions dominate: SourceLow, DestinationHighHigh, PumpFault, TransferEnable FALSE.
   Start conditions: TransferEnable, SourceLevel>20, DestinationLevel<80, no stop active. *)
IF TransferEnable
   AND (SourceLevel > 20.0)
   AND (DestinationLevel < 80.0)
   AND NOT SourceLow
   AND NOT DestinationHighHigh
   AND NOT PumpFault THEN
    TransferPump := TRUE;
ELSE
    TransferPump := FALSE;
END_IF;

END_FUNCTION_BLOCK