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
    startPermitted : BOOL := FALSE;
    invalidModeDiagnostic : BOOL := FALSE;

    occupied : BOOL := FALSE;
    nightMode : BOOL := FALSE;
    energySave : BOOL := FALSE;
    mode : INT := 0;
END_VAR

(* Snapshot inputs for this scan. *)
occupied := OCCUPANCY_DETECTED;
energySave := ENERGY_SAVING_MODE;
mode := HVAC_MODE_SELECTOR;
nightMode := (mode = 3);

invalidModeDiagnostic := (mode < 0) OR (mode > 3);

(* States: disabled, waiting for 30 seconds, and running.
   Call TON every scan so loss of permission immediately resets timing.
   Changes between valid non-Night modes do not restart the delay. *)
startPermitted :=
    occupied AND NOT nightMode AND NOT invalidModeDiagnostic;

startTimer(IN := startPermitted, PT := T#30s);
startElapsed := startTimer.ET;
startDelayComplete := startTimer.Q;

SUPPLY_FAN_RUN := startPermitted AND startDelayComplete;

(* Calculate the adjustment independently of fan-start timing. *)
TEMP_SETPOINT_ADJUST := 0;

CASE mode OF
    0:  (* Auto *)
        IF NOT occupied THEN
            IF energySave THEN
                TEMP_SETPOINT_ADJUST := 3;
            ELSE
                TEMP_SETPOINT_ADJUST := 2;
            END_IF;
        END_IF;

    1:  (* Comfort *)
        IF NOT occupied THEN
            TEMP_SETPOINT_ADJUST := 1;
        END_IF;

    2:  (* Economy *)
        IF NOT occupied THEN
            TEMP_SETPOINT_ADJUST := 4;
        END_IF;

    3:  (* Night *)
        TEMP_SETPOINT_ADJUST := 4;

ELSE
    (* Invalid selector: safe outputs; diagnostic remains internal. *)
    SUPPLY_FAN_RUN := FALSE;
    TEMP_SETPOINT_ADJUST := 0;
END_CASE;

(* Enforce the adjustment bound explicitly. *)
IF TEMP_SETPOINT_ADJUST > 4 THEN
    TEMP_SETPOINT_ADJUST := 4;
ELSIF TEMP_SETPOINT_ADJUST < -4 THEN
    TEMP_SETPOINT_ADJUST := -4;
END_IF;
END_PROGRAM