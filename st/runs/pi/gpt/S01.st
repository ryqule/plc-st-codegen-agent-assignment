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
    leadPump : BOOL := FALSE; (* FALSE = pump 1; TRUE = pump 2 *)
    prevLeadPump : BOOL := FALSE;
    activePump : INT := 0;    (* 0 = none; 1 = pump 1; 2 = pump 2 *)
    previousActivePump : INT := 0;
    minimumOnElapsed : TIME := T#0s;
    completionPending : BOOL := FALSE;

    healthyPumpAvailable : BOOL := FALSE;
    activePumpMinOn2sDone : BOOL := FALSE;
    demandCycleComplete : BOOL := FALSE;
END_VAR

healthyPumpAvailable := NOT Pump1Fault OR NOT Pump2Fault;
prevLeadPump := leadPump;
demandCycleComplete := FALSE;
previousActivePump := activePump;

IF NOT AutoEnable THEN
    (* Disable overrides demand and minimum dwell, without alternating lead. *)
    demand := FALSE;
    completionPending := FALSE;
    activePump := 0;
    minimumOnElapsed := T#0s;
ELSE
    IF NOT demand AND LevelHigh THEN
        demand := TRUE;
        completionPending := FALSE;
        activePump := 0;
        minimumOnElapsed := T#0s;
    END_IF;

    IF demand THEN
        IF LevelLow THEN
            completionPending := TRUE;
        END_IF;

        (* Remove a faulted active pump before selecting its replacement. *)
        IF (activePump = 1) AND Pump1Fault THEN
            activePump := 0;
        ELSIF (activePump = 2) AND Pump2Fault THEN
            activePump := 0;
        END_IF;

        (* Preserve a healthy active pump; otherwise select a healthy lead
           or its standby in this same scan. *)
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

        IF activePump = 0 THEN
            minimumOnElapsed := T#0s;
        ELSIF activePump <> previousActivePump THEN
            (* A newly started or transferred pump has its own dwell.
               Do not credit the preceding scan interval to this pump. *)
            minimumOnElapsed := T#0s;
        ELSIF (CycleTime > T#0s) AND (minimumOnElapsed < T