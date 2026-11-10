```st
FUNCTION_BLOCK FB_BatchMixer
VAR_INPUT
    StartBatch    : BOOL;
    EStopOK       : BOOL;
    WeightA       : REAL;
    WeightB       : REAL;
    TargetA       : REAL;
    TargetB       : REAL;
    MixTime       : TIME;
    CycleTime     : TIME;
    MixComplete   : BOOL;
    DischargePermit : BOOL;
    Reset         : BOOL;
END_VAR

VAR_OUTPUT
    ValveA        : BOOL;
    ValveB        : BOOL;
    Mixer         : BOOL;
    OutletValve   : BOOL;
    BatchFault    : BOOL;
END_VAR

VAR
    stage         : INT;
    mixTimer      : TON;
    rtStart       : R_TRIG;
    rtReset       : R_TRIG;
    startEdge     : BOOL;
    resetEdge     : BOOL;
    validRecipe   : BOOL;
    mixTimeDone   : BOOL;
END_VAR

VAR CONSTANT
    IDLE              : INT := 0;
    FILL_A            : INT := 1;
    FILL_B            : INT := 2;
    MIX               : INT := 3;
    WAIT_MIX_COMPLETE : INT := 4;
    DISCHARGE         : INT := 5;
END_VAR

// Edge detection
rtStart(CLK := StartBatch);
rtReset(CLK := Reset);
startEdge := rtStart.Q;
resetEdge := rtReset.Q;

// Recipe validation
validRecipe := (TargetA > 0.0) AND (TargetB > 0.0) AND (MixTime > T#0s);

// E-stop handling: immediate safe close and latch fault
IF NOT EStopOK THEN
    ValveA := FALSE;
    ValveB := FALSE;
    Mixer := FALSE;
    OutletValve := FALSE;
    BatchFault := TRUE;
    stage := IDLE;
    mixTimer(IN := FALSE, PT := MixTime);
    mixTimeDone := FALSE;
END_IF

// Reset handling: only when EStopOK and all outputs already off
IF resetEdge AND EStopOK AND NOT ValveA AND NOT ValveB AND NOT Mixer AND NOT OutletValve THEN
    BatchFault := FALSE;
    stage := IDLE;
    mixTimer(IN := FALSE, PT := MixTime);
    mixTimeDone := FALSE;
END_IF

// Start rising edge: accept only if valid recipe and not faulted
IF startEdge THEN
    IF (NOT BatchFault) AND validRecipe THEN
        stage := FILL_A;
    ELSE
        // Invalid recipe latches fault; force idle
        BatchFault := TRUE;
        stage := IDLE;
        ValveA := FALSE;
        ValveB := FALSE;
        Mixer := FALSE;
        OutletValve := FALSE;
        mixTimer(IN := FALSE, PT := MixTime);
        mixTimeDone := FALSE;
    END_IF
END_IF

// Mixing timer runs only during MIX stage
mixTimer(IN := (stage = MIX), PT := MixTime);
mixTimeDone := mixTimer.Q;

// State machine (only when E-stop is OK)
IF EStopOK AND (NOT BatchFault) THEN
    CASE stage OF
        IDLE:
            ValveA := FALSE;
            ValveB := FALSE;
            Mixer := FALSE;
            OutletValve := FALSE;

        FILL_A:
            ValveA := TRUE;
            ValveB := FALSE;
            Mix