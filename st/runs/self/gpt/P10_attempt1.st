```st
FUNCTION_BLOCK FB
VAR_INPUT
    TemperatureSensorInput : REAL;
    SetTemperature : REAL;
END_VAR

VAR_OUTPUT
    CurrentTemperature : REAL;
    SetTempDisplay : REAL;
    HeaterStatus : BOOL := FALSE;
    OverheatProtection : BOOL := FALSE;
    HeaterOutput : BOOL := FALSE;
END_VAR

VAR
    sensorFault : BOOL := FALSE;
    heatingRequest : BOOL := FALSE;
    heaterOnElapsed : TIME := T#0s;
    cooldownElapsed3s : BOOL := FALSE;
    releaseProtection : BOOL := FALSE;
    heaterTimer : TON;
    cooldownTimer : TON;
END_VAR

(* The analog module supplies its scaled temperature through the input. *)
CurrentTemperature := TemperatureSensorInput;
SetTempDisplay := SetTemperature;

sensorFault :=
    (TemperatureSensorInput < 0.0) OR
    (TemperatureSensorInput > 100.0);

(* Use the previous scan's cooldown completion:
   protection remains active throughout the completion scan. *)
releaseProtection := OverheatProtection AND cooldownElapsed3s;

IF releaseProtection THEN
    OverheatProtection := FALSE;
END_IF;

(* Fault and protection dominate the temperature demand.
   Equality produces no heating demand. *)
heatingRequest :=
    NOT sensorFault AND
    NOT OverheatProtection AND