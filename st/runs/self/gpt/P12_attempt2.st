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
    THICKNESS_ALARM       : BOOL := FALSE;
    Slab_Fault_Counter    : UINT := UINT#0;
    Slab_Runtime_Accumulator : LTIME := LTIME#0ns;
    Slab_Fault_History    : ARRAY[0..4] OF DINT;
END_VAR

VAR
    initialized          : BOOL := FALSE;
    prevFault            : BOOL := FALSE;
    faultEdge            : BOOL := FALSE;
    holdStarted          : BOOL := FALSE;
    alarmHold            : BOOL := FALSE;
    hold500msDone        : BOOL := FALSE;
    noHistoryWrite       : BOOL := TRUE;
    holdTimer            : TON;
    storedCounter        : UINT := UINT#0;
    storedRuntime        : LTIME := LTIME#0ns;
    storedHistory        : ARRAY[0..4] OF DINT;
    i                    : INT;
END_VAR

(*
    Non-retained state initializes on application startup.
    TON measures the 500 ms hold using the PLC clock.
    CycleTime is required to be positive.

    CODESYS PROGRAM VAR_OUTPUT does not enforce caller read-only access.
    storedHistory is authoritative; the output is refreshed every scan.
    Configure external symbol access as read-only to prohibit external writes.

    Exact accumulation is limited by the declared UINT