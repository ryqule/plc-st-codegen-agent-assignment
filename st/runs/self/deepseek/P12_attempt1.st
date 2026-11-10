```st
FUNCTION_BLOCK P12_SlabThicknessAlarm
VAR_INPUT
    THICKNESS_FAULT       : BOOL;
    THICKNESS_SIGNAL_VALID: BOOL;
    CUTTING_RUN           : BOOL;
    FaultTimestamp        : DINT;
    CycleTime             : TIME;
END_VAR

VAR_OUTPUT
    THICKNESS_ALARM         : BOOL;
    Slab_Fault_Counter      : UINT;
    Slab_Runtime_Accumulator: LTIME;
    Slab_Fault_History      : ARRAY[0..4] OF DINT;
END_VAR

VAR
    prevFault   : BOOL;      (* last scan valid fault edge memory *)
    alarmHold   : BOOL;      (* hold state for min 500 ms *)
    holdTimer   : TON;       (* 500 ms hold timer *)
    initDone    : BOOL;      (* power-up init latch *)
    i           : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* Power-up initialization: zero counters, accumulator and history    *)
(* ------------------------------------------------------------------ *)
IF NOT initDone THEN
    Slab_Fault_Counter       := 0;
    Slab_Runtime_Accumulator := LTIME#0ms;
    FOR i := 0 TO 4 DO
        Slab_Fault_History[i] := 0;
    END_FOR;
    prevFault  := FALSE;
    alarmHold  := FALSE;
    THICKNESS_ALARM := FALSE;
    initDone   := TRUE;
END_IF

(* ------------------------------------------------------------------ *)
(* Signal-validity handling: invalid clears alarm + hold + edge memory *)
(* and suppresses fault counting, history writes and runtime accrual.  *)
(* ------------------------------------------------------------------ *)
IF NOT THICKNESS_SIGNAL_VALID THEN
    THICKNESS_ALARM := FALSE;
    alarmHold       := FALSE;
    prevFault       := FALSE;
    holdTimer(IN := FALSE);
    (* No history write, no runtime accumulation, no counter increment *)
ELSE
    (* -------------------------------------------------------------- *)
    (* Fault rising-edge detection, counting and history shift.       *)
    (* -------------------------------------------------------------- *)
    IF THICKNESS_FAULT AND NOT prevFault THEN
        IF Slab_Fault_Counter < 65535 THEN
            Slab_Fault_Counter := Slab_Fault_Counter + 1;
        END_IF;
        (* Newest-first fixed 5-entry history; shift older entries up *)
        FOR i := 4 TO 1 BY -1 DO
            Slab_Fault_History[i] := Slab_Fault_History[i - 1];
        END_FOR;
        Slab_Fault_History[0] := FaultTimestamp;
    END_IF;
    prevFault := THICKNESS_FAULT;

    (* -------------------------------------------------------------- *)
    (* Minimum 500 ms alarm hold.                                     *)
    (* -------------------------------------------------------------- *)
    holdTimer(IN := (THICKNESS_FAULT OR alarmHold),
              PT := T#500ms);

    IF THICKNESS_FAULT THEN
        (* Fault active: alarm immediately on, hold latched *)
        THICKNESS_ALARM := TRUE;
        alarmHold       := TRUE;
    ELSE
        IF alarmHold THEN
            (* Fault cleared but hold window may still be running *)
            IF holdTimer.Q THEN
                alarmHold       := FALSE;
                THICKNESS_ALARM := FALSE;
            ELSE
                THICKNESS_ALARM := TRUE;
            END_IF;
        ELSE
            THICKNESS_ALARM := FALSE;