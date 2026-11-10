```st
PROGRAM P12
VAR_INPUT
    THICKNESS_FAULT : BOOL;
    THICKNESS_SIGNAL_VALID : BOOL;
    CUTTING_RUN : BOOL;
    FaultTimestamp : DINT;
    CycleTime : TIME;
END_VAR
VAR_OUTPUT
    THICKNESS_ALARM : BOOL := FALSE;
    Slab_Fault_Counter : UINT := 0;
    Slab_Runtime_Accumulator : LTIME := LTIME#0ns;
    Slab_Fault_History : ARRAY[0..4] OF DINT := [0, 0, 0, 0, 0];
END_VAR
VAR
    initialized : BOOL := FALSE;
    prevFault : BOOL := FALSE;
    validFault : BOOL;
    faultRise : BOOL;
    alarmHold : BOOL := FALSE;
    hold500msDone : BOOL := FALSE;
    holdRemaining : LTIME := LTIME#0ns;
    elapsed : LTIME;
    i : INT;
END_VAR

(* Non-retained initialization precedes the first input evaluation. *)
IF NOT initialized THEN
    THICKNESS_ALARM := FALSE;
    Slab_Fault_Counter := 0;
    Slab_Runtime_Accumulator := LTIME#0ns;
    FOR i := 0 TO 4 DO
        Slab_Fault_History[i] := 0;
    END_FOR;
    prevFault := FALSE;
    alarmHold := FALSE;
    hold500msDone := FALSE;
    holdRemaining := LTIME#0ns;
    initialized := TRUE;
END_IF;

(* CycleTime is required to be positive by the input contract. *)
elapsed := TIME_TO_LTIME(CycleTime);
validFault := THICKNESS_SIGNAL_VALID AND THICKNESS_FAULT;
faultRise := validFault AND NOT prevFault;

IF NOT THICKNESS_SIGNAL_VALID THEN
    (* Invalidity overrides both persistent faults and an unfinished hold. *)
    THICKNESS_ALARM := FALSE;
    alarmHold := FALSE;
    hold500msDone := FALSE;
    holdRemaining := LTIME#0ns;
ELSE
    IF faultRise THEN
        (* Each new occurrence restarts its own minimum holding interval. *)
        alarmHold := TRUE;
        hold500msDone := FALSE;
        holdRemaining := LTIME#500ms;

        (* Explicit modulo increment avoids an out-of-range conversion. *)
        IF Slab_Fault_Counter = UINT#65535 THEN
            Slab_Fault_Counter := UINT#0;
        ELSE
            Slab_Fault_Counter := Slab_Fault_Counter + UINT#1;
        END_IF;

        FOR i := 4 TO 1 BY -1 DO
            Slab_Fault_History[i] := Slab_Fault_History[i - 1];
        END_FOR;
        Slab_Fault_History[0] := FaultTimestamp;

    E