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

(* Reconstruct outputs each scan; disable overrides all normal operation. *)
Pump1Run := FALSE;
Pump2Run := FALSE;
NoAvailablePump := FALSE;

IF NOT AutoEnable THEN
    demand := FALSE;
    activePump :=