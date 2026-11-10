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
    sensorFault : BOOL;
    heaterOnElapsed : TIME := T#0s;
    cooldownElapsed3s : BOOL := FALSE;

    heaterOnTimer : TON;
    cooldownTimer : TON;
END_VAR

(* Display the supplied analog-input value and setpoint. *)
CurrentTemperature := TemperatureSensorInput;
SetTempDisplay := SetTemperature;

sensorFault :=
    (TemperatureSensorInput < 0.0) OR
    (TemperatureSensorInput > 100.0);

(* Consume timer results from the preceding scan.
   Protection is retained until a completed cooldown has been observed. *)
IF OverheatProtection THEN
    IF cooldownElapsed3s THEN
        OverheatProtection := FALSE;
    END_IF;
ELSIF heaterOnElapsed > T#5s THEN
    OverheatProtection := TRUE;
END_IF;

(* Fault and overheat interlocks dominate temperature demand.
   At equality, there is no below-setpoint heating demand. *)
HeaterOutput :=
    NOT sensorFault
    AND NOT OverheatProtection
    AND (TemperatureSensorInput < SetTemperature);

HeaterStatus := HeaterOutput;

(* CODESYS TIME has millisecond resolution. Using 5001 ms rather
   than 5000 ms preserves the strict "more than 5 s" comparison.
   Any scan with the heater off resets continuous heating time. *)
heaterOnTimer(
    IN := HeaterOutput,
    PT := T#5s1ms
);
heaterOnElapsed := heaterOnTimer.ET;

(* Cooldown continues even during a sensor fault. Sensor recovery
   cannot bypass the protection latch. *)
cooldownTimer(
    IN := OverheatProtection,
    PT := T#3s
);
cooldownElapsed3s := cooldownTimer.Q;

END_FUNCTION_BLOCK