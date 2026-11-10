PROGRAM P13
VAR_INPUT
    OCCUPANCY_DETECTED : BOOL;
    ENERGY_SAVING_MODE : BOOL;
    HVAC_MODE_SELECTOR : INT;
END_VAR
VAR_OUTPUT
    SUPPLY_FAN_RUN : BOOL := FALSE;
    TEMP_SETPOINT_ADJUST : INT := 0;
END_VAR
VAR
    startTimer : TON;
    startElapsed : TIME := T#0s;
    startDelayComplete : BOOL := FALSE;
    occupied : BOOL;
    nightMode : BOOL;
    energySave : BOOL;
    mode : INT;
    modeValid : BOOL;
    invalidModeDiagnostic : BOOL := FALSE;
    fanPermissive : BOOL;
END_VAR

(* Normal calculation starts on the first execution.
   Outputs have non-retained power-up initial values above. *)
occupied := OCCUPANCY_DETECTED;
energySave := ENERGY_SAVING_MODE;
mode := HVAC_MODE_SELECTOR;
nightMode := (mode = 3);
modeValid := (mode >= 0) AND (mode <= 3);
invalidModeDiagnostic := NOT modeValid;

(* Disabled -> timing -> running.
   Loss of any permissive resets the TON on the same scan. *)
fanPermissive := occupied AND NOT nightMode AND modeValid;
startTimer(IN := fanPermissive, PT := T#30s);
startElapsed := startTimer.ET;
startDelayComplete := startTimer.Q;
SUPPLY_FAN_RUN := fanPermissive AND startDelayComplete;

(* Energy saving affects Auto mode only. *)
TEMP_SETPOINT_ADJUST := 0;
CASE mode OF
    0:
        IF NOT occupied THEN
            IF energySave THEN
                TEMP_SETPOINT_ADJUST := 3;
            ELSE
                TEMP_SETPOINT_ADJUST := 2;
            END_IF;
        END_IF;
    1:
        IF NOT occupied THEN
            TEMP_SETPOINT_ADJUST := 1;
        END_IF;
    2:
        IF NOT occupied THEN
            TEMP_SETPOINT_ADJUST := 4;
        END_IF;
    3:
        TEMP_SETPOINT_ADJUST := 4;
ELSE
    (* Invalid selector: fan disabled above, adjustment remains zero. *)
    TEMP_SETPOINT_ADJUST := 0;
END_CASE;

(* Explicit adjustment bound. *)
IF TEMP_SETPOINT_ADJUST > 4 THEN
    TEMP_SETPOINT_ADJUST := 4;
ELSIF TEMP_SETPOINT_ADJUST < -4 THEN
    TEMP_SETPOINT_ADJUST := -4;
END_IF;
END_PROGRAM