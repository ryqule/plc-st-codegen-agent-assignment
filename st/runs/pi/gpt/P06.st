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
    prevBLOWER_RUN : BOOL := FALSE;
    startPermitted : BOOL;
END_VAR

(* Non-retained initialization: blower OFF, cycle count zero. *)
startPermitted := DO_LOW AND AERATION_E_STOP_NC;

(* Calling TON with IN=FALSE resets both elapsed time and completion. *)
startTimer(IN := startPermitted, PT := T#5s);
startElapsed := startTimer.ET;

(* Demand loss and emergency stop dominate timer completion. *)
BLOWER_RUN := startPermitted AND startTimer.Q;

(* Count each actual start once; saturate rather than wrap. *)
IF BLOWER_RUN AND NOT prevBLOWER_RUN THEN
    IF AERATION_BLOWER_CYCLE_COUNT < UINT#65535 THEN
        AERATION_BLOWER_CYCLE_COUNT :=
            AERATION_BLOWER_CYCLE_COUNT + UINT#1;
    END_IF;
END_IF;

prevBLOWER_RUN := BLOWER_RUN;
END_PROGRAM