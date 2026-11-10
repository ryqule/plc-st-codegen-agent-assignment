FUNCTION_BLOCK AerationBlowerDelayedStart
VAR_INPUT
    DO_LOW              : BOOL;   (* Dissolved oxygen below threshold, aeration needed *)
    AERATION_E_STOP_NC  : BOOL;   (* TRUE = E-stop inactive (permissive), FALSE = E-stop active *)
END_VAR

VAR_OUTPUT
    BLOWER_RUN                  : BOOL;  (* Blower motor-contactor run command *)
    AERATION_BLOWER_CYCLE_COUNT : UINT;  (* Count of actual blower starts, saturating *)
END_VAR

VAR
    (* Rising-edge detection for cycle counting *)
    prevBLOWER_RUN : BOOL := FALSE;

    (* Start-delay timer: TON, 5 s *)
    fbStartDelay   : TON;
    startElapsed   : BOOL;  (* TRUE when the 5 s delay has elapsed *)

    (* Combined demand/permissive condition *)
    demandActive   : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Combined condition: demand AND permissive must both be TRUE.        *)
(* E-stop (AERATION_E_STOP_NC = FALSE) dominates and forces OFF.       *)
(* ------------------------------------------------------------------ *)
demandActive := DO_LOW AND AERATION_E_STOP_NC;

(* ------------------------------------------------------------------ *)
(* Start-delay timer.                                                  *)
(* The timer runs only while demandActive is TRUE.                     *)
(* If demandActive drops (DO_LOW FALSE or E-stop active), the timer    *)
(* is reset immediately, so a renewed demand waits the full 5 s.       *)
(* ------------------------------------------------------------------ *)
fbStartDelay(IN := demandActive, PT := T#5s);
startElapsed := fbStartDelay.Q;

(* ------------------------------------------------------------------ *)
(* Blower run command: gated by the completed 5 s delay.               *)
(* Because the timer resets on loss of demandActive, BLOWER_RUN is     *)
(* forced FALSE immediately when demand or permissive is lost.         *)
(* ------------------------------------------------------------------ *)
BLOWER_RUN := demandActive AND startElapsed;

(* ------------------------------------------------------------------ *)
(* Cycle counting: increment once on each FALSE->TRUE transition of    *)
(* BLOWER_RUN. Saturate at UINT max instead of wrapping.               *)
(* ------------------------------------------------------------------ *)
IF BLOWER_RUN AND NOT prevBLOWER_RUN THEN
    IF AERATION_BLOWER_CYCLE_COUNT < 65535 THEN
        AERATION_BLOWER_CYCLE_COUNT := AERATION_BLOWER_CYCLE_COUNT + 1;
    END_IF;
END_IF;

(* Store previous run state for edge detection *)
prevBLOWER_RUN := BLOWER_RUN;

END_FUNCTION_BLOCK