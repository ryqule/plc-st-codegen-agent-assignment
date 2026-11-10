```st
PROGRAM S04
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
    ValveA          : BOOL := FALSE;
    ValveB          : BOOL := FALSE;
    Mixer           : BOOL := FALSE;
    OutletValve     : BOOL := FALSE;
    BatchFault      : BOOL := FALSE;
END_VAR

VAR CONSTANT
    IDLE              : INT := 0;
    FILL_A            : INT := 1;
    FILL_B            : INT := 2;
    MIX               : INT := 3;
    WAIT_MIX_COMPLETE : INT := 4;
END_VAR

VAR
    stage              : INT := 0;
    previousStartBatch : BOOL := FALSE;
    previousReset      : BOOL := FALSE;
    startBatchEdge     : BOOL := FALSE;
    resetEdge          : BOOL := FALSE;
    validTargets       : BOOL := FALSE;
    outputsWereOff     : BOOL := TRUE;
    mixElapsed         : TIME := T#0s;
    mixTimeDone        : BOOL := FALSE;
END_VAR

(* Rising edges are tracked even while faulted or emergency-stopped. *)
startBatchEdge := StartBatch AND NOT previousStartBatch;
resetEdge := Reset AND NOT previousReset;
previousStartBatch := StartBatch;
previousReset := Reset;

validTargets := (TargetA > 0.0) AND (TargetB > 0.0);

(* Evaluate reset eligibility before