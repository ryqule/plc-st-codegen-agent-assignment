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

    Fan1DwellElapsed : TIME := T#0s;
    Fan2DwellElapsed : TIME := T#0s;

    Fan1MinOn10sDone  : BOOL;
    Fan2MinOn10sDone  : BOOL;
    Fan1MinOff10sDone : BOOL;
    Fan2MinOff10sDone : BOOL;
END_VAR

InvalidTemperature :=
    NOT ((Temperature >= -20.0) AND (Temperature <= 80.0));
BothFansFaulted := Fan1Fault AND Fan2Fault;
CoolingAlarm := InvalidTemperature OR BothFansFaulted;

PreviousFan1 := Fan1;
PreviousFan2 := Fan2;

(* Saturating elapsed-time accumulation prevents timer overflow.
   Nonpositive CycleTime does not advance either timer. *)
IF CycleTime > T#0s THEN
    IF Fan1DwellElapsed < T#10s THEN
        IF CycleTime >= (T#10s - Fan1DwellElapsed) THEN
            Fan1DwellElapsed := T#10s;
        ELSE
            Fan1DwellElapsed := Fan1DwellElapsed + CycleTime;
        END_IF;
    END_IF;

    IF Fan2DwellElapsed < T#10s THEN
        IF CycleTime >= (T#10s - Fan2DwellElapsed) THEN
            Fan2DwellElapsed := T#10s;
        ELSE
            Fan2DwellElapsed := Fan2DwellElapsed + CycleTime;
        END_IF;
    END_IF;
END_IF;

Fan1MinOn10sDone := Fan1 AND (Fan1DwellElapsed >= T#10s);
Fan2MinOn10sDone := Fan2 AND (Fan2DwellElapsed >= T#10s);
Fan1MinOff10sDone := NOT Fan1 AND (Fan1DwellElapsed >= T#10s);
Fan2MinOff10sDone := NOT Fan2 AND (Fan2DwellElapsed >= T#10s);

(* Demand hysteresis is independent of physical fan dwell. *)
IF InvalidTemperature OR NOT Enable THEN
    Stage :=