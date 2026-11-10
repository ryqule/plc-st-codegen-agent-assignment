```st
PROGRAM S05
VAR_INPUT
    Temperature : REAL;
    Fan1Fault   : BOOL;
    Fan2Fault   : BOOL;
    CycleTime   : TIME;
    Enable      : BOOL;
END_VAR

VAR_OUTPUT
    Fan1         : BOOL := FALSE;
    Fan2         : BOOL := FALSE;
    CoolingAlarm : BOOL := FALSE;
END_VAR

VAR
    Stage : INT := 0;

    InvalidTemperature : BOOL;
    BothFansFaulted     : BOOL;
    RequestFan1        : BOOL;
    RequestFan2        : BOOL;
    PreviousFan1       : BOOL;
    PreviousFan2       : BOOL;

    (* Elapsed time in each fan's current commanded on/off state. *)
    Fan1DwellElapsed : TIME := T#0s;
    Fan2DwellElapsed : TIME := T#0s;

    Fan1MinOn10sDone  : BOOL;
    Fan2MinOn10sDone  : BOOL;
    Fan1MinOff10sDone : BOOL;
    Fan2MinOff10sDone : BOOL;
END_VAR

(* Range checking also rejects unordered floating-point comparisons. *)
InvalidTemperature :=
    NOT ((Temperature >= -20.0) AND (Temperature <= 80.0));
BothFansFaulted := Fan1Fault AND