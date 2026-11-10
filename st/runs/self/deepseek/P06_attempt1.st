FUNCTION_BLOCK AerationBlowerDelayedStart
VAR_INPUT
    DO_LOW              : BOOL;   (* Dissolved oxygen below threshold, aeration needed *)
    AERATION_E_STOP_NC  : BOOL;   (* TRUE = E-stop inactive, FALSE = E-stop active *)
END_VAR

VAR_OUTPUT
    BLOWER_RUN                  : BOOL;  (* Blower motor-contactor run command *)
    AERATION_BLOWER_CYCLE_COUNT : UINT;  (* Count of actual blower starts, saturating *)
END_VAR

VAR
    tonStartDelay   : TON;          (* 5 s start-delay timer *)
    rtStartDelay    : R_TRIG;       (* Rising edge of timer completion *)
    rtBlowerRun     : R_TRIG;       (* Rising edge of BLOWER_RUN for cycle counting *)
    startElapsed    : BOOL;         (* Timer completion predicate *)
    prevBlowerRun   : BOOL;         (* Previous scan BLOWER_RUN for edge detection *)
    initDone        : BOOL := FALSE;(* Power-up initialization flag *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Power-up initialization: blower OFF, count zero                     *)
(* ------------------------------------------------------------------ *)
IF NOT initDone THEN
    BLOWER_RUN                  := FALSE;
    AERATION_BLOWER_CYCLE_COUNT := 0;
    prevBlowerRun               := FALSE;
    initDone                    := TRUE;
END_IF

(* ------------------------------------------------------------------ *)
(* Start-delay timer: runs only while both demand and permissive TRUE  *)
(* Any drop of either condition resets the timer immediately.          *)
(* ------------------------------------------------------------------ *)
tonStartDelay(IN := DO_LOW AND AERATION_E_STOP_NC,
              PT := T#5s);

startElapsed := tonStartDelay.Q;

(* ------------------------------------------------------------------ *)
(* Blower enable: gated by timer completion AND both conditions        *)
(* E-stop / demand loss dominates and forces BLOWER_RUN FALSE.         *)
(* ------------------------------------------------------------------ *)
IF (DO_LOW AND AERATION_E_STOP_NC AND startElapsed) THEN
    BLOWER_RUN := TRUE;
ELSE
    BLOWER_RUN := FALSE;
END_IF

(* ------------------------------------------------------------------ *)
(* Cycle counting: increment once per FALSE->TRUE transition of        *)
(* BLOWER_RUN, saturating at UINT max.                                 *)
(* ------------------------------------------------------------------ *)
rtBlowerRun(CLK := BLOWER_RUN);
IF rtBlowerRun.Q THEN
    IF AERATION_BLOWER_CYCLE_COUNT < 65535 THEN
        AERATION_BLOWER_CYCLE_COUNT := AERATION_BLOWER_CYCLE_COUNT + 1;
    END_IF
END_IF

(* Track previous state for edge semantics *)
prevBlowerRun := BLOWER_RUN;

END_FUNCTION_BLOCK