FUNCTION_BLOCK FB_PartRejector
VAR_INPUT
    PartPresent     : BOOL;
    Defect          : BOOL;
    ConveyorRunning : BOOL;
    CycleTime       : TIME;
    Reset           : BOOL;
END_VAR
VAR_OUTPUT
    RejectSolenoid  : BOOL;
    RejectCount     : UDINT;
END_VAR
VAR
    prevDefect      : BOOL;
    defectRise      : BOOL;
    pulseTimer      : TON;
    pulseActive     : BOOL;
    pulseElapsed    : TIME;
    pulse300msDone  : BOOL;
END_VAR

(* ---------------------------------------------------------------
   Rising-edge detection on Defect.
   A new reject requires Defect to return FALSE before another edge.
   --------------------------------------------------------------- *)
defectRise := Defect AND NOT prevDefect;

(* ---------------------------------------------------------------
   Pulse timer accumulation.
   CycleTime is accumulated by the pulse timer; one scan is the
   timer resolution. The timer runs only while a pulse is active.
   --------------------------------------------------------------- *)
IF pulseActive THEN
    pulseElapsed := pulseElapsed + CycleTime;
ELSE
    pulseElapsed := T#0ms;
END_IF;

pulse300msDone := pulseActive AND (pulseElapsed >= T#300ms);

(* ---------------------------------------------------------------
   Start a new reject pulse on a valid defect rising edge.
   Valid = part present AND conveyor running.
   Count saturates at UDINT maximum (no wraparound).
   --------------------------------------------------------------- *)
IF defectRise AND PartPresent AND ConveyorRunning THEN
    pulseActive := TRUE;
    pulseElapsed := T#0ms;
    IF RejectCount < 16#FFFFFFFF THEN
        RejectCount := RejectCount + 1;
    END_IF;
END_IF;

(* ---------------------------------------------------------------
   Pulse completion: 300 ms elapsed ends the pulse.
   Reset does NOT interrupt an active pulse.
   --------------------------------------------------------------- *)
IF pulse300msDone THEN
    pulseActive := FALSE;
    pulseElapsed := T#0ms;
END_IF;

(* ---------------------------------------------------------------
   Output interlock: solenoid only when a pulse is active AND
   part present AND conveyor running (S08-L1).
   --------------------------------------------------------------- *)
RejectSolenoid := pulseActive AND PartPresent AND ConveyorRunning;

(* ---------------------------------------------------------------
   Reset clears the count but does not interrupt an active pulse.
   --------------------------------------------------------------- *)
IF Reset THEN
    RejectCount := 0;
END_IF;

(* ---------------------------------------------------------------
   Store previous Defect for next-scan edge detection.
   --------------------------------------------------------------- *)
prevDefect := Defect;

END_FUNCTION_BLOCK