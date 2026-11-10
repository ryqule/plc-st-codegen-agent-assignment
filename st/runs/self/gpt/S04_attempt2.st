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

(* Evaluate reset eligibility before clearing the output commands. *)
outputsWereOff := NOT ValveA AND NOT ValveB
                  AND NOT Mixer AND NOT OutletValve;

ValveA := FALSE;
ValveB := FALSE;
Mixer := FALSE;
OutletValve := FALSE;
mixTimeDone := FALSE;

(* Emergency stop and invalid recipes dominate normal operation. *)
IF NOT EStopOK THEN
    BatchFault := TRUE;
    stage := IDLE;
    mixElapsed := T#0s;

ELSIF startBatchEdge AND
      (NOT validTargets OR (MixTime <= T#0s)) THEN
    BatchFault := TRUE;
    stage := IDLE;
    mixElapsed := T#0s;

ELSE
    IF resetEdge AND outputsWereOff THEN
        BatchFault := FALSE;
    END_IF;

    IF BatchFault THEN
        stage := IDLE;
        mixElapsed := T#0s;
    ELSE
        CASE stage OF
            IDLE:
                mixElapsed := T#0s;
                IF startBatchEdge THEN
                    stage := FILL_A;
                END_IF;

            FILL_A:
                IF WeightA >= TargetA THEN
                    stage := FILL_B;
                END_IF;

            FILL_B:
                IF WeightB >= TargetB THEN
                    mixElapsed := T#0s;
                    stage := MIX;
                END_IF;

            MIX:
                (* Saturating