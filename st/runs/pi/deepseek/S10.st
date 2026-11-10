FUNCTION_BLOCK FB_HeaterControl
VAR_INPUT
    Temperature : REAL;
    Setpoint    : REAL;
    SensorValid : BOOL;
    Enable      : BOOL;
    CycleTime   : TIME;
END_VAR
VAR_OUTPUT
    Heater      : BOOL;
    SensorFault : BOOL;
END_VAR
VAR
    ValidTimer  : TON;
    InitDone    : BOOL := FALSE;
    InputsValid : BOOL;
END_VAR

(* Input validity: sensor flag plus both values within -20..150 C *)
InputsValid := SensorValid
               AND (Temperature >= -20.0) AND (Temperature <= 150.0)
               AND (Setpoint    >= -20.0) AND (Setpoint    <= 150.0);

(* Continuous-validity timer: runs only while inputs are valid *)
ValidTimer(IN := InputsValid, PT := T#2S);

(* Power-up: heater off, fault on until validation completes *)
IF NOT InitDone THEN
    Heater      := FALSE;
    SensorFault := TRUE;
    IF ValidTimer.Q THEN
        InitDone := TRUE;
    END_IF;
ELSE
    (* Fault handling dominates normal control *)
    IF NOT InputsValid THEN
        Heater      := FALSE;
        SensorFault := TRUE;
    ELSIF ValidTimer.Q THEN
        SensorFault := FALSE;
    END_IF;

    (* Normal control only when inputs valid and no fault *)
    IF InputsValid AND NOT SensorFault THEN
        IF NOT Enable THEN
            Heater := FALSE;
        ELSIF Temperature >= Setpoint THEN
            Heater := FALSE;
        ELSIF Temperature <= (Setpoint - 1.0) THEN
            Heater := TRUE;
        (* else: deadband, retain prior Heater state *)
        END_IF;
    ELSE
        Heater := FALSE;
    END_IF;
END_IF;