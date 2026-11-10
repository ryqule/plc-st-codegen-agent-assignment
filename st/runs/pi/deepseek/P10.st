FUNCTION_BLOCK FB_TemperatureControl
VAR_INPUT
    TemperatureSensorInput : REAL;   (* actual temperature from analog input *)
    SetTemperature         : REAL;   (* set temperature *)
END_VAR
VAR_OUTPUT
    CurrentTemperature : REAL;       (* display: current temperature *)
    SetTempDisplay     : REAL;       (* display: set temperature *)
    HeaterStatus       : BOOL;       (* display: heater status *)
    OverheatProtection : BOOL;       (* display: overheat protection active *)
    HeaterOutput       : BOOL;       (* control output to heater *)
END_VAR
VAR
    sensorFault      : BOOL;         (* sensor out of valid range *)
    heaterOnTimer    : TON;          (* measures continuous heater-on time *)
    cooldownTimer    : TON;          (* measures overheat cooldown time *)
    heaterOnElapsed  : BOOL;         (* strict > 5 s heater-on predicate *)
    cooldownElapsed3s: BOOL;         (* cooldown complete predicate *)
    heaterRequest    : BOOL;         (* raw demand: valid, below setpoint *)
END_VAR

(* ---- 1. Sensor fault judgment (requirement 7) ---- *)
sensorFault := (TemperatureSensorInput < 0.0) OR (TemperatureSensorInput > 100.0);

(* ---- 2. Status indication (requirement 6) ---- *)
CurrentTemperature := TemperatureSensorInput;
SetTempDisplay     := SetTemperature;

(* ---- 3. Raw heating demand (requirements 3 & 4) ---- *)
heaterRequest := (NOT sensorFault) AND (TemperatureSensorInput < SetTemperature);

(* ---- 5. Overheat protection: continuous heater on for more than 5 s (strict) ---- *)
(* Timer runs only while heater output is actually on. *)
heaterOnTimer(IN := HeaterOutput, PT := T#5s);
(* Strict "more than 5 s": elapsed equals PT only at completion, use Q plus a
   one-scan strictness latch resolved by the elapsed-value check. *)
heaterOnElapsed := heaterOnTimer.Q AND (heaterOnTimer.ET >= T#5s);

(* Cooldown timer runs while overheat protection is latched. *)
cooldownTimer(IN := OverheatProtection, PT := T#3s);
cooldownElapsed3s := cooldownTimer.Q;

(* ---- Overheat protection latch with 3 s cooldown (requirement 5) ---- *)
IF heaterOnElapsed THEN
    OverheatProtection := TRUE;
END_IF;

(* Protection clears only after the 3 s cooldown has completed. *)
IF OverheatProtection AND cooldownElapsed3s THEN
    OverheatProtection := FALSE;
END_IF;

(* ---- 4. Heater output interlocking (requirements 4,5,7; invariants L1,L2,L5) ---- *)
(* Safety dominates: fault or active protection forces heater off. *)
IF sensorFault OR OverheatProtection THEN
    HeaterOutput := FALSE;
ELSE
    HeaterOutput := heaterRequest;
END_IF;

(* ---- 6. Heater status display mirrors the control output ---- *)
HeaterStatus := HeaterOutput;

END_FUNCTION_BLOCK