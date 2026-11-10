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
    timingActive : BOOL := FALSE;
    startTick : UDINT := UDINT#0;
    currentTick : UDINT;
    elapsedMilliseconds : UDINT := UDINT#0;
    startElapsed : TIME := T#0s;
    lastBlowerRun : BOOL := FALSE;
END_VAR

(* Use the CODESYS millisecond clock without a TON library dependency. *)
currentTick := TIME_TO_UDINT(TIME());

IF NOT DO_LOW OR NOT AERATION_E_STOP_NC THEN
    timingActive := FALSE;
    elapsedMilliseconds := UDINT#0;
    startElapsed := T#0s;
    BLOWER_RUN := FALSE;
ELSE
    IF NOT timingActive THEN
        timingActive := TRUE;
        startTick := currentTick;
        elapsedMilliseconds := UDINT#0;
        startElapsed := T#0s;
    ELSIF startElapsed < T#5s THEN
        (* Handle rollover of the 32-bit millisecond clock. *)
        IF currentTick >= startTick THEN
            elapsedMilliseconds := currentTick - startTick;
        ELSE
            elapsedMilliseconds :=
                (UDINT#4294967295 - startTick)
                + currentTick + UDINT#1;
        END_IF;

        IF elapsedMilliseconds >= UDINT#5000 THEN
            elapsedMilliseconds := UDINT#5000;
        END_IF;

        startElapsed := UDINT_TO_TIME(elapsedMilliseconds);
    END_IF;

    BLOWER_RUN := startElapsed >= T#5s;
END_IF;

IF BLOWER_RUN AND NOT lastBlowerRun THEN
    IF AERATION_BLOWER_CYCLE_COUNT < UINT#65535 THEN
        AERATION_BLOWER_CYCLE_COUNT :=
            AERATION_BLOWER_CYCLE_COUNT + UINT#1;
    END_IF;
END_IF;

lastBlowerRun := BLOWER_RUN;

END_PROGRAM