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
    THICKNESS_ALARM       : BOOL;
    Slab_Fault_Counter    : UINT;
    Slab_Runtime_Accumulator : LTIME;
    Slab_Fault_History    : ARRAY[0..4] OF DINT;
END_VAR
VAR
    prevFault             : BOOL;
    alarmHold             : BOOL;
    holdTimer             : TON;
    initialized           : BOOL;
END_VAR

(* --- Power-up initialization --- *)
IF NOT initialized THEN
    Slab_Fault_Counter       := 0;
    Slab_Runtime_Accumulator := LTIME#0s;
    Slab_Fault_History[0]    := 0;
    Slab_Fault_History[1]    := 0;
    Slab_Fault_History[2]    := 0;
    Slab_Fault_History[3]    := 0;
    Slab_Fault_History[4]    := 0;
    prevFault  := FALSE;
    alarmHold  := FALSE;
    holdTimer(IN := FALSE, PT := T#500ms);
    initialized := TRUE;
END_IF

(* --- Invalid signal: dominant reset (P12-L1) --- *)
IF NOT THICKNESS_SIGNAL_VALID THEN
    THICKNESS_ALARM := FALSE;
    alarmHold       := FALSE;
    holdTimer(IN := FALSE, PT := T#500ms);
    prevFault       := FALSE;
    (* No counter increment, no history write, no runtime accumulation *)
    RETURN;
END_IF

(* --- 500 ms hold timer --- *)
holdTimer(IN := alarmHold, PT := T#500ms);

(* --- Fault-edge detection & history shift (P12-L2) --- *)
IF THICKNESS_FAULT AND NOT prevFault THEN
    (* Increment counter (saturating at UINT max) *)
    IF Slab_Fault_Counter < 65535 THEN
        Slab_Fault_Counter := Slab_Fault_Counter + 1;
    END_IF;
    (* Shift history newest-first, fixed at five *)
    Slab_Fault_History[4] := Slab_Fault_History[3];
    Slab_Fault_History[3] := Slab_Fault_History[2];
    Slab_Fault_History[2] := Slab_Fault_History[1];
    Slab_Fault_History[1] := Slab_Fault_History[0];
    Slab_Fault_History[0] := FaultTimestamp;
END_IF

(* --- Alarm activation & hold (P12-L3) --- *)
IF THICKNESS_FAULT THEN
    (* Fault present: alarm active, hold state re-armed *)
    THICKNESS_ALARM := TRUE;
    alarmHold       := TRUE;
ELSIF alarmHold AND NOT holdTimer.Q THEN
    (* Fault gone but minimum hold not yet done: alarm stays on *)
    THICKNESS_ALARM := TRUE;
ELSE
    (* Hold complete (or never armed): alarm off *)
    THICKNESS_ALARM := FALSE;
    alarmHold       := FALSE;
END_IF

(* --- Normal-cutting runtime