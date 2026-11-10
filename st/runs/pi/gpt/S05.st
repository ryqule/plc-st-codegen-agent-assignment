```st
PROGRAM S05
VAR_INPUT
    Temperature : REAL;
    Fan1Fault : BOOL;
    Fan2Fault : BOOL;
    CycleTime : TIME;
    Enable : BOOL;
END_VAR
VAR_OUTPUT
    Fan1 : BOOL := FALSE;
    Fan2 : BOOL := FALSE;
    CoolingAlarm : BOOL := FALSE;
END_VAR
VAR
    stage : INT := 0;
    invalidTemperature : BOOL;
    bothFansFaulted : BOOL;
    healthyFanAvailable : BOOL;
    twoHealthyFansAvailable : BOOL;

    Fan1MinOn10sDone : BOOL;
    Fan2MinOn10sDone : BOOL;
    Fan1MinOff10sDone : BOOL;
    Fan2MinOff10sDone : BOOL;
    activeFanMinOn10sDone : BOOL;

    Fan1OnElapsed : TIME := T#0s;
    Fan2OnElapsed : TIME := T#0s;
    Fan1OffElapsed : TIME := T#0s;
    Fan2OffElapsed : TIME := T#0s;

    StepTime : TIME;
    RequestFan1 : BOOL;
    RequestFan2 : BOOL;
    NextFan1 : BOOL;
    NextFan2 : BOOL;
END_VAR

(* Negative CycleTime contributes no elapsed time.
   Counters saturate at 10 seconds to avoid overflow. *)
StepTime := CycleTime;
IF StepTime < T#0s THEN
    StepTime := T#0s;
END_IF;

invalidTemperature :=
    NOT ((Temperature >= -20.0) AND (Temperature <= 80.0));
bothFansFaulted := Fan1Fault AND Fan2Fault;
healthyFanAvailable := NOT bothFansFaulted;
twoHealthyFansAvailable := NOT Fan1Fault AND NOT Fan2Fault;

CoolingAlarm := invalidTemperature OR bothFansFaulted;

(* Accumulate time in the commanded state entering this scan. *)
IF Fan1 THEN
    Fan1OffElapsed := T#0s;
    IF StepTime >= (T#10s - Fan1OnElapsed) THEN
        Fan1OnElapsed := T#10s;
    ELSE
        Fan1OnElapsed := Fan1OnElapsed + StepTime;
    END_IF;
ELSE
    Fan1OnElapsed := T#0s;
    IF StepTime >= (T#10s - Fan1OffElapsed) THEN
        Fan1OffElapsed := T#10s;
    ELSE
        Fan1OffElapsed := Fan1OffElapsed + StepTime;
    END_IF;
END_IF;

IF Fan2 THEN
    Fan2OffElapsed := T#0s;
    IF StepTime >= (T#10s - Fan2OnElapsed) THEN
        Fan2OnElapsed := T#10s;
    ELSE
        Fan2OnElapsed := Fan2OnElapsed + StepTime;
    END_IF;
ELSE
    Fan2OnElapsed