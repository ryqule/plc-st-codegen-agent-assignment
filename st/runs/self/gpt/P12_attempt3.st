```st
PROGRAM P12
VAR_INPUT
    THICKNESS_FAULT        : BOOL;
    THICKNESS_SIGNAL_VALID : BOOL;
    CUTTING_RUN            : BOOL;
    FaultTimestamp         : DINT;
    CycleTime              : TIME;
END_VAR

VAR_OUTPUT
    THICKNESS_ALARM          : BOOL := FALSE;
    Slab_Fault_Counter       : UINT := UINT#0;
    Slab_Runtime_Accumulator : LTIME := LTIME#0ns;
    Slab_Fault_History       : ARRAY[0..4] OF DINT;
END_VAR

VAR
    initialized   : BOOL := FALSE;
    prevFault     : BOOL := FALSE;
    faultEdge     : BOOL := FALSE;
    alarmHold     : BOOL := FALSE;
    hold500msDone : BOOL := FALSE;
    noHistoryWrite : BOOL := TRUE;
    holdElapsed   : TIME := T#0ms;
    storedCounter : UINT := UINT#0;
    storedRuntime : LTIME := LTIME#0ns;
    storedHistory : ARRAY[0..4] OF DINT;
    i             : INT;
END_VAR

(* No TON library dependency: elapsed hold time uses positive CycleTime.
   The triggering invocation does not advance the new hold interval. *)

IF NOT initialized THEN
    THICKNESS_ALARM := FALSE;
    prevFault := FALSE;
    alarmHold := FALSE;
    hold500msDone := FALSE;
    holdElapsed := T#0ms;
    storedCounter := UINT#0;
    storedRuntime := LTIME#0ns;
    FOR i := 0 TO 4 DO
        storedHistory[i] := DINT#0;
    END_FOR;
    initialized := TRUE;
END_IF;

faultEdge := FALSE;
noHistoryWrite := TRUE;

IF NOT THICKNESS_SIGNAL_VALID THEN
    THICKNESS_ALARM := FALSE;
    alarmHold := FALSE;
    hold500msDone := FALSE;
    holdElapsed := T#0ms;
    prevFault := FALSE;
ELSE
    faultEdge := THICKNESS_FAULT AND NOT prevFault;

    IF faultEdge THEN
        storedCounter := storedCounter + UINT#1;

        FOR i := 4 TO 1 BY -1 DO
            storedHistory[i] := storedHistory[i - 1];
        END_FOR;
        storedHistory[0] := FaultTimestamp;
        noHistoryWrite := FALSE;

        alarmHold := TRUE;
        hold500msDone := FALSE;
        holdElapsed := T#0ms;
    ELSIF alarmHold THEN
        IF CycleTime > T#0ms THEN
            IF CycleTime >= (T#500ms - holdElapsed) THEN
                holdElapsed := T#500ms;
                hold500msDone := TRUE;
                alarmHold := FALSE;
            ELSE
                holdElapsed := holdElapsed + CycleTime;
            END_IF;
        END_IF;
    END_IF;

    THICKNESS_ALARM := THICKNESS_FAULT OR