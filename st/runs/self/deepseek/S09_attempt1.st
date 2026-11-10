FUNCTION_BLOCK FB_TwoTankTransfer
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
    TransferPump        : BOOL;
    SourceLowAlarm      : BOOL;
    DestinationHighAlarm: BOOL;
END_VAR
VAR
    ResetPrev           : BOOL;
    ResetEdge           : BOOL;
END_VAR

(* Rising-edge detection for Reset *)
ResetEdge := Reset AND NOT ResetPrev;
ResetPrev := Reset;

(* SourceLow alarm: latch on condition, clear only on Reset edge when condition is FALSE *)
IF SourceLow THEN
    SourceLowAlarm := TRUE;
ELSIF ResetEdge AND NOT SourceLow THEN
    SourceLowAlarm := FALSE;
END_IF;

(* DestinationHighHigh alarm: latch on condition, clear only on Reset edge when condition is FALSE *)
IF DestinationHighHigh THEN
    DestinationHighAlarm := TRUE;
ELSIF ResetEdge AND NOT DestinationHighHigh THEN
    DestinationHighAlarm := FALSE;
END_IF;

(* Transfer pump: start/run only when all permissives hold; stop immediately otherwise *)
TransferPump := TransferEnable
                AND (SourceLevel > 20.0)
                AND (DestinationLevel < 80.0)
                AND NOT SourceLow
                AND NOT DestinationHighHigh
                AND NOT PumpFault;

END_FUNCTION_BLOCK