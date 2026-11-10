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
    leadPump : BOOL := FALSE;
    prevLeadPump : BOOL := FALSE;
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
    demand := FALSE;
    activePump := 0;
    activeOnTime := T#0s;
    activePumpMinOn2sDone := FALSE;
ELSE
    IF LevelHigh THEN
        demand := TRUE;
    END_IF;

    IF demand THEN
        IF (activePump = 1) AND Pump1Fault THEN
            activePump := 0;
        ELSIF (activePump = 2) AND Pump2Fault THEN
            activePump := 0;
        END_IF;

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

        IF activePump <> previousActivePump THEN
            activeOnTime := T#0s;
        END_IF;

        IF activePump = 0 THEN
            activeOnTime := T#0s;
            activePumpMinOn2sDone := FALSE;
        ELSE
            IF activeOnTime < T#2s THEN
                IF CycleTime >= (T#2s - activeOnTime) THEN
                    activeOnTime := T#2s;
                ELSE
                    activeOnTime := activeOnTime + CycleTime;
                END_IF;
            END_IF;
            activePumpMinOn2sDone := activeOnTime >= T#2s;
        END_IF;

        IF LevelLow AND activePumpMinOn2sDone THEN
            demandCycleComplete := TRUE;
            demand := FALSE;
            activePump := 0;
            activeOnTime := T#0s;
            activePumpMinOn2sDone := FALSE;
            leadPump := NOT prevLeadPump;
        END_IF;
    ELSE
        activePump := 0;
        activeOnTime := T#0s;
        activePumpMinOn2sDone := FALSE;
    END_IF;

    Pump1Run := demand AND (activePump = 1) AND NOT Pump1Fault;
    Pump2Run := demand AND (activePump = 2) AND NOT Pump2Fault;
    NoAvailablePump := demand AND