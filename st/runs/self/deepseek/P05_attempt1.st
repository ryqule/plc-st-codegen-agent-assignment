FUNCTION_BLOCK WeldGapAlarm
VAR_INPUT
    Gap_Exceeded   : BOOL;   (* Scanner: gap > 1.5 mm *)
    Weld_E_Stop_NC : BOOL;   (* TRUE = E-stop inactive, FALSE = E-stop active *)
    DebounceTime   : TIME;   (* Positive debounce duration under normal monitoring *)
END_VAR

VAR_OUTPUT
    Operator_Alert        : BOOL;  (* Audible/visual alarm command *)
    Weld_Soft_Start_Active : BOOL;  (* Power-up 5 s monitoring inhibition *)
END_VAR

VAR
    InitTimer      : TON;   (* One-shot 5 s power-up interval *)
    DebounceTimer  : TON;   (* Debounce while monitoring normally *)
    InitDone       : BOOL;  (* Power-up interval elapsed *)
    DebounceValid  : BOOL;  (* DebounceTime is positive *)
END_VAR

(* ------------------------------------------------------------------ *)
(* DebounceTime must be positive; treat non-positive as no debounce.  *)
(* ------------------------------------------------------------------ *)
DebounceValid := DebounceTime > T0s;

(* ------------------------------------------------------------------ *)
(* One-shot 5 s power-up initialization interval.                     *)
(* E-stop does not restart the boot interval (per assumptions).       *)
(* ------------------------------------------------------------------ *)
InitTimer(IN := NOT InitDone, PT := T#5s);
IF InitTimer.Q THEN
    InitDone := TRUE;
END_IF;

(* Active inhibition = during the one-shot power-up interval           *)
Weld_Soft_Start_Active := NOT InitDone;

(* ------------------------------------------------------------------ *)
(* Debounce timing for the gap signal.                                *)
(* Cleared during init, during E-stop, and whenever signal is FALSE. *)
(* ------------------------------------------------------------------ *)
IF (NOT InitDone) OR (NOT Weld_E_Stop_NC) OR (NOT Gap_Exceeded) OR (NOT DebounceValid) THEN
    DebounceTimer(IN := FALSE, PT := DebounceTime);
ELSE
    DebounceTimer(IN := TRUE, PT := DebounceTime);
END_IF;

(* ------------------------------------------------------------------ *)
(* Alarm logic with E-stop, init, and signal-drop priority.           *)
(* ------------------------------------------------------------------ *)
IF (NOT Weld_E_Stop_NC) THEN
    (* E-stop dominates: immediate clear *)
    Operator_Alert := FALSE;
ELSIF (NOT InitDone) THEN
    (* Power-up inhibition *)
    Operator_Alert := FALSE;
ELSIF (NOT Gap_Exceeded) THEN
    (* Signal dropped: immediate clear *)
    Operator_Alert := FALSE;
ELSIF (NOT DebounceValid) THEN
    (* No valid debounce configured: pass through signal *);
    Operator_Alert := TRUE;
ELSIF DebounceTimer.Q THEN
    Operator_Alert := TRUE;
ELSE
    Operator_Alert := FALSE;
END_IF;

END_FUNCTION_BLOCK