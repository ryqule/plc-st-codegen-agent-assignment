```st
FUNCTION_BLOCK HVAC_MultiModeEnergySaving
VAR
    (* Configuration constants *)
    FAN_START_DELAY : TIME := T#30s;

    (* Timer for fan start delay *)
    tonFanStart : TON;

    (* Internal diagnostics *)
    diagInvalidMode : BOOL;

    (* Timer elapsed flag *)
    fanDelayElapsed : BOOL;
END_VAR

VAR_INPUT
    OCCUPANCY_DETECTED   : BOOL;
    ENERGY_SAVING_MODE   : BOOL;
    HVAC_MODE_SELECTOR   : INT;
END_VAR

VAR_OUTPUT
    SUPPLY_FAN_RUN       : BOOL;
    TEMP_SETPOINT_ADJUST : INT;
END_VAR

(* ============================================================
   Implementation
   ============================================================ *)

(* ------------------------------------------------------------
   Diagnostic: detect invalid mode selector values (not 0..3)
   ------------------------------------------------------------ *)
diagInvalidMode := (HVAC_MODE_SELECTOR < 0) OR (HVAC_MODE_SELECTOR > 3);

(* ------------------------------------------------------------
   Temperature setpoint adjustment calculation
   Formulas are invariants; clamp to +/-4 C.
   Invalid mode => adjustment 0 (safe output).
   ------------------------------------------------------------ *)
IF diagInvalidMode THEN
    TEMP_SETPOINT_ADJUST := 0;
ELSE
    CASE HVAC_MODE_SELECTOR OF
        0: (* Auto *)
            IF OCCUPANCY_DETECTED THEN
                TEMP_SETPOINT_ADJUST := 0;
            ELSE
                IF ENERGY_SAVING_MODE THEN
                    TEMP_SETPOINT_ADJUST := 3;
                ELSE
                    TEMP_SETPOINT_ADJUST := 2;
                END_IF;
            END_IF;

        1: (* Comfort *)
            IF OCCUPANCY_DETECTED THEN
                TEMP_SETPOINT_ADJUST := 0;
            ELSE
                TEMP_SETPOINT_ADJUST := 1;
            END_IF;

        2: (* Economy *)
            IF OCCUPANCY_DETECTED THEN
                TEMP_SETPOINT_ADJUST := 0;
            ELSE
                TEMP_SETPOINT_ADJUST := 4;
            END_IF;

        3: (* Night *)
            TEMP_SETPOINT_ADJUST := 4;

        ELSE
            TEMP_SETPOINT_ADJUST := 0;
    END_CASE;
END_IF;

(* Clamp invariant: keep within +/- 4 C *)
IF TEMP_SETPOINT_ADJUST > 4 THEN
    TEMP_SETPOINT_ADJUST := 4;
ELSIF TEMP_SETPOINT_ADJUST < -4 THEN
    TEMP_SETPOINT_ADJUST := -4;
END_IF;

(* ------------------------------------------------------------
   Fan start delay logic
   Conditions required for fan start:
     - occupancy detected
     - mode selector is not Night (3)
     - mode selector is valid
     - energy-saving mode does not affect fan enable
   Timer runs only while conditions are satisfied.
   Loss of occupancy, Night mode, or invalid mode resets timer.
   ------------------------------------------------------------ *)
tonFanStart(
    IN  := OCCUPANCY_DETECTED
           AND (HVAC_MODE_SELECTOR <> 3)
           AND NOT diagInvalidMode,
    PT  := FAN_START_DELAY
);

fanDelayElapsed := tonFanStart.Q;

(* Fan runs only when all conditions hold and 30s