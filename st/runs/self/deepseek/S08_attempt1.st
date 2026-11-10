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
    pulseActive     : BOOL;
    pulseElapsed    : TIME;
    defectRise      : BOOL;
    pulse300msDone  : BOOL;
END_VAR

(* Rising edge detection on Defect *)
defectRise := Defect AND NOT prevDefect;

(* Pulse timer accumulation: one scan resolution *)
IF pulseActive THEN
    pulseElapsed := pulseElapsed + CycleTime;
    IF pulseElapsed >= T#300ms THEN
        pulse300msDone := TRUE;
    END_IF;
END_IF;

(* Start a new reject pulse on valid defect rising edge *)
IF defectRise AND PartPresent AND ConveyorRunning THEN
    pulseActive  := TRUE;
    pulseElapsed := T#0ms;
    pulse300msDone := FALSE;
    IF RejectCount < 16#FFFFFFFF THEN
        RejectCount := RejectCount + 1;
    END_IF;
END_IF;

(* Pulse completion terminates solenoid *)
IF pulse300msDone THEN
    pulseActive    := FALSE;
    pulseElapsed   := T#0ms;
    pulse300msDone := FALSE;
END_IF;

(* Output: solenoid active only while pulse active and permissives hold *)
RejectSolenoid := pulseActive AND PartPresent AND ConveyorRunning;

(* Reset clears count but does not interrupt active pulse *)
IF Reset THEN
    RejectCount := 0;
END_IF;

(* Store previous defect state *)
prevDefect := Defect;
END_FUNCTION_BLOCK