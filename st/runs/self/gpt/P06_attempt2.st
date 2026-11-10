PROGRAM P06
VAR_INPUT
    DO_LOW : BOOL;
    AERATION_E_STOP_NC : BOOL;
END_VAR
VAR_OUTPUT
    BLOWER_RUN : BOOL := FALSE;
    AERATION_BLOWER_CYCLE_COUNT : UINT := UINT#0;
END_VAR
VAR
    startTimer : TON;
    startElapsed : TIME := T#0s;
    lastBlowerRun : BOOL := FALSE;
END_VAR

(* Loss of either condition resets the non-retentive start timer. *)
startTimer(
    IN := DO_LOW AND AERATION_E_STOP_NC,
    PT := T#5s
);
startElapsed := startTimer.ET;

(* Demand and emergency-stop permissive dominate the run command. *)
BLOWER_RUN := DO_LOW
              AND AERATION_E_STOP_NC
              AND startTimer.Q
              AND (startElapsed >= T#5s);

(* Count each actual start once, saturating at the UINT maximum. *)
IF BLOWER_RUN AND NOT lastBlowerRun THEN
    IF AERATION_BLOWER_CYCLE_COUNT < UINT#65535 THEN
        AERATION_BLOWER_CYCLE_COUNT :=
            AERATION_BLOWER_CYCLE_COUNT + UINT#1;
    END_IF;
END_IF;

lastBlowerRun := BLOWER_RUN;

END_PROGRAM