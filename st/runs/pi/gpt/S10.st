PROGRAM S10
VAR_INPUT
    Temperature : REAL;
    Setpoint : REAL;
    SensorValid : BOOL;
    Enable : BOOL;
    CycleTime : TIME;
END_VAR
VAR_OUTPUT
    Heater : BOOL := FALSE;
    SensorFault : BOOL := TRUE;
END_VAR
VAR
    validTemperature : BOOL;
    validSetpoint : BOOL;
    validInputs : BOOL;
    validFor2s : BOOL := FALSE;
    ValidElapsed : TIME := T#0ms;
END_VAR

(* Inclusive Celsius limits. *)
validTemperature := (Temperature >= -20.0) AND (Temperature <= 150.0);
validSetpoint := (Setpoint >= -20.0) AND (Setpoint <= 150.0);
validInputs := SensorValid AND validTemperature AND validSetpoint;

(* Accumulate uninterrupted diagnostic validity, independently of Enable.
   Saturate at two seconds to avoid timer arithmetic overflow. *)
IF NOT validInputs THEN
    ValidElapsed := T#0ms;
ELSIF ValidElapsed < T#2s THEN
    IF CycleTime > T#0ms THEN
        IF CycleTime >= (T#2s - ValidElapsed) THEN
            ValidElapsed := T#2s;
        ELSE
            ValidElapsed := ValidElapsed + CycleTime;
        END_IF;
    END_IF;
END_IF;

validFor2s := validInputs AND (ValidElapsed >= T#2s);

(* Invalid diagnostics assert the fault immediately.
   Only uninterrupted two-second validity clears it. *)
IF NOT validInputs THEN
    SensorFault := TRUE;
ELSIF validFor2s THEN
    SensorFault := FALSE;
END_IF;

(* Disable and diagnostic interlocks dominate hysteresis commands. *)
IF (NOT Enable) OR (NOT validInputs) OR SensorFault THEN
    Heater := FALSE;
ELSIF Temperature >= Setpoint THEN
    Heater := FALSE;
ELSIF Temperature <= (Setpoint - 1.0) THEN
    Heater := TRUE;
END_IF;
(* Otherwise retain the previous Heater state inside the deadband. *)
END_PROGRAM