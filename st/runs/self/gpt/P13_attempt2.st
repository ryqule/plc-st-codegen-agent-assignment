```st
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
    startElapsed : TIME := T#0s;
    startDelayComplete : BOOL := FALSE;
    startPermitted : BOOL := FALSE;
    timingActive : BOOL := FALSE;
    invalidModeDiagnostic : BOOL := FALSE;

    occupied : BOOL := FALSE;
    nightMode : BOOL := FALSE;
    energySave : BOOL := FALSE;
    mode : INT := 0;

    currentTick : UDINT := 0;
    startTick : UDINT := 0;
    elapsedMilliseconds : UDINT := 0;
END_VAR

(* Snapshot inputs for this scan. *)
occupied := OCCUPANCY_DETECTED;
energySave := ENERGY_SAVING_MODE;
mode := HVAC_MODE_SELECTOR;
nightMode := (mode = 3);
invalidModeDiagnostic := (mode < 0) OR (mode > 3);

startPermitted :=
    occupied AND NOT nightMode AND NOT invalidModeDiagnostic;

(* Use the CODESYS built-in millisecond clock without a TON dependency. *)
currentTick := TIME_TO_UDINT(TIME());

IF NOT startPermitted THEN
    timingActive := FALSE;
    startDelayComplete := FALSE;
    startElapsed := T#0s;
    elapsedMilliseconds := 0;
    startTick := currentTick;
ELSE
    IF NOT timingActive THEN
        timingActive := TRUE;
        startTick := currentTick;
        startElapsed := T#0s;
        elapsedMilliseconds := 0;
        startDelayComplete := FALSE;
    ELSIF NOT startDelayComplete THEN
        (* Handle rollover of the 32-bit millisecond clock. *)
        IF currentTick >= startTick THEN
            elapsedMilliseconds := currentTick - startTick;
        ELSE
            elapsedMilliseconds :=
                (UDINT#4294967295 - startTick) + currentTick + UDINT#1;
        END_IF;

        IF elapsedMilliseconds >= UDINT#30000 THEN
            startElapsed := T#30s;
            startDelayComplete := TRUE;
        ELSE
            startElapsed := UDINT_TO_TIME(elapsedMilliseconds);
        END_IF;
    END_IF;
END_IF;

SUPPLY_FAN_RUN := startPermitted AND startDelayComplete;

(* The adjustment is independent of fan-start timing. *)
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
        IF NOT