```st
FUNCTION_BLOCK P13_HVAC_Control
VAR
    (* Timer *)
    tonStartDelay : TON;

    (* Internal state *)
    startElapsed      : TIME := T#0s;
    fanEnableInternal : BOOL := FALSE;
    diagnosticsInvalidMode : BOOL := FALSE;

    (* Constants *)
    START_DELAY : TIME := T#30s;
    ADJ_MIN : INT := -4;
    ADJ_MAX : INT := 4;
END_VAR

VAR_INPUT
    OCCUPANCY_DETECTED   : BOOL;
    ENERGY_SAVING_MODE   : BOOL;
    HVAC_MODE_SELECTOR   : INT;
END_VAR

VAR_OUTPUT
    SUPPLY_FAN_RUN        : BOOL;
    TEMP_SETPOINT_ADJUST  : INT;
END_VAR

VAR
    (* Working *)
    modeValid  : BOOL;
    nightMode  : BOOL;
    occ        : BOOL;
    startCond  : BOOL;
    adjCalc    : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* 1. Validate mode selector; invalid values -> safe outputs           *)
(* ------------------------------------------------------------------ *)
modeValid := (HVAC_MODE_SELECTOR >= 0) AND (HVAC_MODE_SELECTOR <= 3);
diagnosticsInvalidMode := NOT modeValid;

IF NOT modeValid THEN
    (* Safe state: fan off, adjustment 0, reset timer *)
    tonStartDelay(IN := FALSE, PT := START_DELAY);
    startElapsed := T#0s;
    fanEnableInternal := FALSE;
    SUPPLY_FAN_RUN := FALSE;
    TEMP_SETPOINT_ADJUST := 0;
    RETURN;
END_IF

occ       := OCCUPANCY_DETECTED;
nightMode := (HVAC_MODE_SELECTOR = 3);

(* ------------------------------------------------------------------ *)
(* 2. Start-delay logic (interval timer semantics)                     *)
(*    Run only when occupied AND not night. Stop immediately, reset   *)
(*    elapsed time when condition lost.                               *)
(* ------------------------------------------------------------------ *)
startCond := occ AND NOT nightMode;

tonStartDelay(IN := startCond, PT := START_DELAY);

IF startCond AND tonStartDelay.Q THEN
    startElapsed := START_DELAY;      (* elapsed >= 30s reached *)
    fanEnableInternal := TRUE;
ELSIF startCond THEN
    startElapsed := tonStartDelay.ET; (* counting up, < 30s *)
    fanEnableInternal := FALSE;
ELSE
    startElapsed := T#0s;             (* reset on loss of condition *)
    fanEnableInternal := FALSE;
END_IF

(* Fan enable only after full 30s; reassert condition to be safe *)
SUPPLY_FAN_RUN := fanEnableInternal AND occ AND NOT nightMode
                  AND (startElapsed >= START_DELAY);

(* ------------------------------------------------------------------ *)
(* 3. Temperature setpoint adjustment                                 *)
(* ------------------------------------------------------------------ *)
CASE HVAC_MODE_SELECTOR OF
    0: (* Auto *)
        IF occ THEN
            adjCalc := 0;
        ELSIF ENERGY_SAVING_MODE THEN
            adjCalc := 3;
        ELSE
            adjCalc := 2;
        END_IF;

    1: (* Comfort: energy-saving ignored *)
        IF occ THEN
            adjCalc := 0;
        ELSE
            adjCalc := 1;
        END_IF;

    2: (* Economy: energy-saving ignored *)
        IF occ THEN