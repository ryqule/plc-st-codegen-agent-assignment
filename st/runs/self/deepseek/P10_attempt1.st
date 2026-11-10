This function block implements the temperature control logic with sensor-fault handling, bang-bang control around the setpoint, a strict 5 s continuous-heater overheating trip, and a 3 s cooldown lockout before heating may resume. Timers use `TON` whose `ET` and `Q` are read one scan late, so the trip/cooldown actions latch on the scan after the elapsed predicate becomes true, matching the specification's named timer-completion atoms.

```st
FUNCTION_BLOCK FB_TemperatureLogicControl
VAR_INPUT
    TemperatureSensorInput : REAL; (* Analog temperature input, actual temperature *)
    SetTemperature         : REAL; (* Setpoint temperature *)
END_VAR

VAR_OUTPUT
    CurrentTemperature  : REAL; (* Display of the current temperature *)
    SetTempDisplay      : REAL; (* Display of the set temperature *)
    HeaterStatus        : BOOL; (* Display of the heater status *)
    OverheatProtection  : BOOL; (* Display of the overheating protection status *)
    HeaterOutput        : BOOL; (* Control output of the heater *)
END_VAR

VAR
    (* Fault detection *)
    SensorFault         : BOOL;

    (* Overheating protection: heater has run continuously for > 5 s *)
    HeaterOnTimer       : TON;
    HeaterRunActive     : BOOL; (* Heater commanded on and accumulating run time *)

    (* Cooldown after overheat trip: must stay latched until 3 s elapse *)
    CooldownTimer       : TON;
    CooldownComplete    : BOOL;

    (* Derived control requests *)
    HeaterDemand        : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* 1. Status indication (current temperature & setpoint always shown) *)
(* ------------------------------------------------------------------ *)
CurrentTemperature := TemperatureSensorInput;
SetTempDisplay     := SetTemperature;

(* ------------------------------------------------------------------ *)
(* 2. Sensor fault judgment: < 0 or > 100 deg -> fault                  *)
(* ------------------------------------------------------------------ *)
SensorFault := (TemperatureSensorInput < 0.0)
            OR (TemperatureSensorInput > 100.0);

(* ------------------------------------------------------------------ *)
(* 3. Overheating protection trip: continuous heater operation > 5 s    *)
(*    "More than 5 s" is strict: only after 5 s has fully elapsed.     *)
(* ------------------------------------------------------------------ *)
HeaterOnTimer(IN := HeaterRunActive, PT := T#5s);
IF HeaterOnTimer.Q THEN
    OverheatProtection := TRUE;
END_IF

(* ------------------------------------------------------------------ *)
(* 4. Cooldown recovery: protection can only lift after 3 s cooldown    *)
(* ------------------------------------------------------------------ *)
CooldownTimer(IN := OverheatProtection, PT := T#3s);
CooldownComplete := CooldownTimer.Q;

IF OverheatProtection AND CooldownComplete THEN
    OverheatProtection := FALSE;
END_IF
(* Cooldown timer is reset automatically when OverheatProtection=FALSE *)

(* ------------------------------------------------------------------ *)
(* 5. Heater demand (bang-bang control)                                 *)
(*    Safety permissives dominate: sensor fault and overheat protection *)
(*    both force the heater off regardless of temperature comparison.  *)
(*    Heating resumes when valid, below setpoint, and cooldown done.    *)
(* ------------------------------------------------------------------ *)
IF SensorFault THEN
    HeaterOutput := FALSE;
ELSIF OverheatProtection THEN
    HeaterOutput := FALSE;
ELSIF TemperatureSensorInput < SetTemperature THEN
    HeaterOutput := TRUE;
ELSE
    (* Actual temperature >= setpoint: