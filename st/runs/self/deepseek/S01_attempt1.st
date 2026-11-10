```st
FUNCTION_BLOCK FB_StandbyPumpAlternation
VAR_INPUT
    AutoEnable  : BOOL;
    LevelHigh   : BOOL;
    LevelLow    : BOOL;
    Pump1Fault  : BOOL;
    Pump2Fault  : BOOL;
    CycleTime   : TIME;
END_VAR
VAR_OUTPUT
    Pump1Run         : BOOL;
    Pump2Run         : BOOL;
    NoAvailablePump  : BOOL;
END_VAR
VAR
    (* Internal state *)
    demand        : BOOL;   (* latched demand *)
    leadPump      : BOOL;   (* FALSE => pump1 lead, TRUE => pump2 lead; power-up: pump1 lead *)
    (* minimum-on timers per pump *)
    tP1           : TON;
    tP2           : TON;
    (* minimum-on elapsed predicates *)
    p1MinOnDone   : BOOL;
    p2MinOnDone   : BOOL;
    (* healthy predicates *)
    p1Healthy     : BOOL;
    p2Healthy     : BOOL;
    healthyAvail  : BOOL;
    (* selected running pump this scan *)
    runP1         : BOOL;
    runP2         : BOOL;
    (* cycle completion edge detection *)
    levelLowPrev  : BOOL;
    cycleComplete : BOOL;
END_VAR

(* ------------------------------------------------------------------
   Healthy predicates: a pump is healthy when it is not faulted.
   ------------------------------------------------------------------ *)
p1Healthy := NOT Pump1Fault;
p2Healthy := NOT Pump2Fault;
healthyAvail := p1Healthy OR p2Healthy;

(* ------------------------------------------------------------------
   Cycle completion: LevelLow rising edge while demand latched,
   following a demand cycle. (Test T6: alternate lead only after a
   completed LevelLow demand cycle.)
   ------------------------------------------------------------------ *)
cycleComplete := LevelLow AND NOT levelLowPrev AND demand;

(* ------------------------------------------------------------------
   AutoEnable FALSE: immediate stop of both pumps and clear demand.
   Lead selection: alternation only occurs on cycle completion.
   ------------------------------------------------------------------ *)
IF NOT AutoEnable THEN
    demand   := FALSE;
    runP1    := FALSE;
    runP2    := FALSE;
ELSE
    (* --------------------------------------------------------------
       Demand latch: set on LevelHigh when healthy pump available;
       cleared when LevelLow (demand completion).
       -------------------------------------------------------------- *)
    IF LevelLow THEN
        demand := FALSE;
    ELSIF LevelHigh AND healthyAvail THEN
        demand := TRUE;
    END_IF;
    (* Note: if both pumps faulted while demand latched, demand stays
       latched (NoAvailablePump raised) until LevelLow or AutoEnable FALSE. *)

    (* --------------------------------------------------------------
       Pump selection while demand latched.
       Priority: healthy lead first; if lead faulted, transfer to
       healthy standby in the same scan.
       -------------------------------------------------------------- *)
    runP1 := FALSE;
    runP2 := FALSE;

    IF demand THEN
        IF NOT leadPump THEN
            (* pump1 is lead *)
            IF p1Healthy THEN
                runP1 := TRUE;
            ELSIF p2Healthy THEN
                runP2 := TRUE;
            END_IF;
        ELSE
            (* pump2 is lead *)
            IF p2Healthy THEN
                runP2 := TRUE;
            ELSIF p1Healthy THEN
                runP1 := TRUE;
            END_IF;
        END_IF;
    END_IF;

    (* --------------------------------------------------------------
       Minimum-on time enforcement (2 s).
       A healthy pump that is running for less than