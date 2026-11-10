```st
PROGRAM S01
VAR_INPUT
    AutoEnable : BOOL;
    LevelHigh : BOOL;
    LevelLow : BOOL;
    Pump1Fault : BOOL;
    Pump2Fault : BOOL;
    CycleTime : TIME;
END_VAR

VAR_OUTPUT
    Pump1Run : BOOL := FALSE;
    Pump2Run : BOOL := FALSE;
    NoAvailablePump : BOOL := FALSE;
END_VAR

VAR
    demand : BOOL := FALSE;

    (* FALSE selects pump 1; TRUE selects pump 2. *)
    leadPump : BOOL := FALSE;
    prevLeadPump : BOOL := FALSE;

    (* 0 = idle, 1 = pump 1, 2 = pump 2. *)
    activePump : USINT := 0;
    previousActivePump : USINT := 0;

    activeOnTime : TIME := T#0s;
    activePumpMinOn2sDone : BOOL := FALSE;
    healthyPumpAvailable : BOOL := FALSE;
    demandCycleComplete : BOOL := FALSE;
END_VAR

prevLeadPump := leadPump;
previousActivePump := activePump;
demandCycleComplete := FALSE;
healthyPumpAvailable := NOT Pump1Fault OR NOT Pump2Fault;

Pump1Run := FALSE;
Pump2Run := FALSE;
NoAvailablePump := FALSE;

IF NOT AutoEnable THEN
    (* Disable immediately cancels demand without alternating the lead. *)
    demand := FALSE;
    activePump := 0;
    activeOnTime := T#0s;
    activePumpMinOn2sDone := FALSE;
ELSE
    IF LevelHigh THEN
        demand := TRUE;
    END_IF;

    IF demand THEN
        (* Fault override immediately removes the affected pump. *)
        IF (activePump = 1) AND Pump1Fault THEN
            activePump := 0;
        ELSIF (activePump = 2) AND Pump2Fault THEN
            activePump := 0;
        END_IF;

        (* Select a healthy pump in this same scan. *)
        IF activePump = 0 THEN
            IF NOT leadPump THEN
                IF NOT Pump1Fault THEN
                    activePump := 1;
                ELSIF NOT Pump2Fault THEN
                    activePump := 2;
                END_IF;
            ELSE
                IF NOT Pump2Fault THEN
                    activePump := 2;
                ELSIF NOT Pump1Fault THEN
                    activePump := 1;
                END_IF;
            END_IF;
        END_IF;

        (* Minimum-on timing belongs to the active pump, not the demand. *)
        IF activePump <> previousActivePump THEN
            activeOnTime := T#0s;
        END_IF;

        IF activePump = 0 THEN
            activeOnTime := T#0s;
            activePumpMinOn2sDone := FALSE;
        ELSE
            (* Saturate at 2 s to avoid accumulated-time overflow. *)
            IF activeOnTime < T#2s THEN
                IF CycleTime >= (T#2s -