```st
FUNCTION_BLOCK FB_BatchMixer
VAR_INPUT
    StartBatch      : BOOL;
    EStopOK         : BOOL;
    WeightA         : REAL;
    WeightB         : REAL;
    TargetA         : REAL;
    TargetB         : REAL;
    MixTime         : TIME;
    CycleTime       : TIME;
    MixComplete     : BOOL;
    DischargePermit : BOOL;
    Reset           : BOOL;
END_VAR

VAR_OUTPUT
    ValveA      : BOOL;
    ValveB      : BOOL;
    Mixer       : BOOL;
    OutletValve : BOOL;
    BatchFault  : BOOL;
END_VAR

VAR
    stage           : INT;
    StartBatchPrev  : BOOL;
    ResetPrev       : BOOL;
    startBatchEdge  : BOOL;
    resetEdge       : BOOL;
    validTargets    : BOOL;
    mixAccum        : TIME;
    mixTimerDone    : BOOL;
END_VAR

VAR CONSTANT
    ST_IDLE               : INT := 0;
    ST_FILL_A             : INT := 10;
    ST_FILL_B             : INT := 20;
    ST_MIX                : INT := 30;
    ST_WAIT_MIX_COMPLETE  : INT := 40;
    ST_DISCHARGE          : INT := 50;
END_VAR

// ---------------------------------------------------------------
// Edge detection
// ---------------------------------------------------------------
startBatchEdge := StartBatch AND NOT StartBatchPrev;
resetEdge      := Reset AND NOT ResetPrev;
StartBatchPrev := StartBatch;
ResetPrev      := Reset;

// ---------------------------------------------------------------
// E-stop dominance: immediately close all outputs and latch fault.
// Also invalidate any active batch.
// ---------------------------------------------------------------
IF NOT EStopOK THEN
    ValveA      := FALSE;
    ValveB      := FALSE;
    Mixer       := FALSE;
    OutletValve := FALSE;
    BatchFault  := TRUE;
    stage       := ST_IDLE;
    mixAccum    := T#0s;
    mixTimerDone := FALSE;
END_IF

// ---------------------------------------------------------------
// Reset handling (rising edge, only when safe)
// ---------------------------------------------------------------
IF resetEdge AND EStopOK AND NOT ValveA AND NOT ValveB AND NOT Mixer AND NOT OutletValve THEN
    BatchFault := FALSE;
    stage      := ST_IDLE;
    mixAccum   := T#0s;
    mixTimerDone := FALSE;
END_IF

// ---------------------------------------------------------------
// Recipe validation
// ---------------------------------------------------------------
validTargets := (TargetA > 0.0) AND (TargetB > 0.0) AND (MixTime > T#0s);

// ---------------------------------------------------------------
// Normal operation (only if E-stop is OK)
// ---------------------------------------------------------------
IF EStopOK THEN

    // Start of a new batch
    IF startBatchEdge AND (stage = ST_IDLE) AND NOT BatchFault THEN
        IF validTargets THEN
            stage := ST_FILL_A;
        ELSE
            BatchFault := TRUE;
            stage      := ST_IDLE;
        END_IF
    END_IF

    // State machine
    CASE stage OF
        ST_IDLE:
            ValveA      := FALSE;
            ValveB      := FALSE;
            Mixer       := FALSE;
            OutletValve := FALSE;
            mixAccum    := T#0s;
            mixTimerDone := FALSE;

        ST_FILL_A:
            ValveA      := TRUE;
            ValveB      := FALSE;
            Mix