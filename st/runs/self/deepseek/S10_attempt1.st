```st
FUNCTION_BLOCK FB_HeaterControl
VAR_INPUT
    Temperature : REAL;   (* Process temperature in Celsius *)
    Setpoint    : REAL;   (* Target temperature in Celsius *)
    SensorValid : BOOL;   (* Sensor self-diagnostics valid flag *)
    Enable      : BOOL;   (* Operator/master enable *)
    CycleTime   : TIME;   (* Task cycle time, used for validation timer *)
END_VAR

VAR_OUTPUT
    Heater      : BOOL;   (* Heating demand *)
    SensorFault : BOOL;   (* Latched fault, cleared after 2 s continuous validity *)
END_VAR

VAR
    (* Power-up / initialization bookkeeping *)
    InitDone     : BOOL := FALSE;

    (* Continuous-validity accumulation for fault clearing *)
    ValidTimer   : TIME := T#0s;
    ValidElapsed : BOOL := FALSE;  (* validFor2s atom *)

    (* Input validity flags (combinational) *)
    TempInRange  : BOOL;
    SetInRange   : BOOL;
    InputsValid  : BOOL;

    (* Deadband/threshold constants *)
    Hysteresis   : REAL := 1.0;
    TempMin      : REAL := -20.0;
    TempMax      : REAL := 150.0;
END_VAR

VAR CONSTANT
    VALID_TIME   : TIME := T#2s;
END_VAR

(* ------------------------------------------------------------------ *)
(* Input range validation                                              *)
(* ------------------------------------------------------------------ *)
TempInRange := (Temperature >= TempMin) AND (Temperature <= TempMax);
SetInRange  := (Setpoint    >= TempMin) AND (Setpoint    <= TempMax);

(* Combination validity: sensor flag AND both ranges AND finite values *)
InputsValid := SensorValid AND TempInRange AND SetInRange;

(* ------------------------------------------------------------------ *)
(* Continuous-validity timer accumulation                              *)
(* Accumulates only while InputsValid is TRUE; any invalid scan       *)
(* resets the timer immediately (fault clears only after 2 s of        *)
(* *continuous* validity).                                            *)
(* ------------------------------------------------------------------ *)
IF InputsValid THEN
    ValidTimer := ValidTimer + CycleTime;
    IF ValidTimer >= VALID_TIME THEN
        ValidTimer   := VALID_TIME;   (* saturate to avoid TIME overflow *)
        ValidElapsed := TRUE;
    END_IF;
ELSE
    ValidTimer   := T#0s;
    ValidElapsed := FALSE;
END_IF;

(* ------------------------------------------------------------------ *)
(* Power-up initialization: Heater off, SensorFault on until           *)
(* validation interval completes. InitDone captured on first scan;     *)
(* fault-clearing below overrides it only after 2 s continuous         *)
(* validity.                                                           *)
(* ------------------------------------------------------------------ *)
IF NOT InitDone THEN
    Heater      := FALSE;
    SensorFault := TRUE;
    InitDone    := TRUE;
ELSE
    (* -------------------------------------------------------------- *)
    (* Fault handling dominates: invalid inputs force heater off and  *)
    (* raise fault. validFor2s clears the fault.                      *)
    (* -------------------------------------------------------------- *)
    IF NOT InputsValid THEN
        SensorFault := TRUE;
    ELSIF ValidElapsed THEN
        SensorFault := FALSE;
    END_IF;
    (* If inputs valid but timer not yet elapsed, SensorFault retains  *)
    (* its prior value (latching).                                     *)

    (* -------------------------------------------------------------- *)
    (* Heater interlock: invalid inputs, fault active, or not enabled *)
    (* force heater off (S10-L1, S10-L6, L7).                         *)
    (* -------------------------------------------------