PROGRAM S10
VAR_INPUT
    Temperature : REAL;
    Setpoint    : REAL;
    SensorValid : BOOL;
    Enable      : BOOL;
    CycleTime   : TIME;
END_VAR

VAR_OUTPUT
    Heater      : BOOL := FALSE;
    SensorFault : BOOL := TRUE;
END_VAR

VAR
    validTemperature : BOOL;
    validSetpoint    : BOOL;
    validInputs      : BOOL;
    validFor2s       : BOOL := FALSE;
    ValidElapsed     : TIME := T#0s;
END_VAR

(* Inclusive Celsius range checks. *)
validTemperature := (Temperature >= -20.0)
                    AND (Temperature <= 150.0);
validSetpoint := (Setpoint >= -20.0)
                 AND (Setpoint <= 150.0);
validInputs := SensorValid AND validTemperature AND validSetpoint;

(* Continuous-validity timer accumulated from CycleTime. *)
IF NOT validInputs THEN
    ValidElapsed := T#0s;
ELSIF ValidElapsed < T#2s THEN
    IF CycleTime > T#0s THEN
        IF CycleTime >= (T#2s - ValidElapsed) THEN
            ValidElapsed := T#2s;
        ELSE
            ValidElapsed := ValidElapsed + CycleTime;
        END_IF;
    END_IF;
END_IF;

validFor2s := validInputs AND (ValidElapsed >= T#2s);
SensorFault := NOT validFor2s;

(* Fault and disable dominate the hysteresis controller. *)
IF (NOT Enable) OR SensorFault OR (NOT validInputs) THEN
    Heater := FALSE;
ELSIF Temperature >= Setpoint THEN
    Heater := FALSE;
ELSIF Temperature <= (Setpoint - 1.0) THEN
    Heater := TRUE;
END_IF;

END_PROGRAM