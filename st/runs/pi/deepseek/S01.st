```st
FUNCTION_BLOCK S01_StandbyPumpAlternation
VAR_INPUT
    AutoEnable  : BOOL;   (* auto mode enable *)
    LevelHigh   : BOOL;   (* high level flag (demand trigger) *)
    LevelLow    : BOOL;   (* low level flag (demand completion) *)
    Pump1Fault  : BOOL;   (* pump 1 fault *)
    Pump2Fault  : BOOL;   (* pump 2 fault *)
    CycleTime   : TIME;   (* scan-cycle increment for min-on timer *)
END_VAR

VAR_OUTPUT
    Pump1Run        : BOOL; (* pump 1 run command *)
    Pump2Run        : BOOL; (* pump 2 run command *)
    NoAvailablePump : BOOL; (* both pumps faulted under demand *)
END_VAR

VAR
    demand           : BOOL := FALSE; (* latched pumping demand *)
    leadPump         : BOOL := TRUE;  (* TRUE => pump1 is lead, FALSE => pump2 *)
    prevLeadPump     : BOOL := TRUE;  (* lead value before alternation *)
    demandCycleComplete : BOOL := FALSE; (* one-scan pulse at LevelLow cycle completion *)
    activePumpIsP1   : BOOL := FALSE; (* which pump is running while min-on timer counts *)
    activePumpMinOn2sDone : BOOL := FALSE; (* min-on timer completion predicate *)
    minOnElapsed     : TIME := T#0s;

    (* internal computed predicates *)
    p1Healthy        : BOOL;
    p2Healthy        : BOOL;
    healthyAvailable : BOOL;
    applyMinOnBlock  : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Healthy (not faulted) predicate for each pump                      *)
(* ------------------------------------------------------------------ *)
p1Healthy := NOT Pump1Fault;
p2Healthy := NOT Pump2Fault;
healthyAvailable := p1Healthy OR p2Healthy;

(* ------------------------------------------------------------------ *)
(* Safety / mode overrides: AutoEnable FALSE dominates everything.     *)
(* Faults force their own pump off.                                    *)
(* ------------------------------------------------------------------ *)
NoAvailablePump := demand AND Pump1Fault AND Pump2Fault;

demandCycleComplete := FALSE;

IF NOT AutoEnable THEN
    (* Immediate stop both pumps, clear demand, reset timer, keep lead *)
    demand            := FALSE;
    Pump1Run          := FALSE;
    Pump2Run          := FALSE;
    minOnElapsed      := T#0s;
    activePumpIsP1    := FALSE;
    activePumpMinOn2sDone := FALSE;
    NoAvailablePump   := FALSE;
    RETURN;
END_IF

(* ------------------------------------------------------------------ *)
(* Demand latching                                                    *)
(* ------------------------------------------------------------------ *)
IF NOT demand THEN
    IF LevelHigh AND healthyAvailable THEN
        demand := TRUE;   (* latch demand, will start lead this scan *)
    END_IF
ELSE
    IF LevelLow THEN
        demand := FALSE;
        demandCycleComplete := TRUE;  (* pulse for alternation *)
    END_IF
END_IF

(* ------------------------------------------------------------------ *)
(* Minimum-on timer: counts while a healthy pump is commanded ON.     *)
(* Fault override does NOT add to timer (it force-stops that pump).   *)
(* ------------------------------------------------------------------ *)
applyMinOnBlock := FALSE;

(* ------------------------------------------------------------------ *)
(* Decide which pump shall run while demand is latched.               *)
(* Rule: use lead if healthy; else if standby healthy, transfer to    *)
(* standby in the same scan. If both faulty -> both off.              *)
(* ------------------------------------------------------------------