PROGRAM P05
VAR_INPUT
    Gap_Exceeded : BOOL;
    Weld_E_Stop_NC : BOOL;
    DebounceTime : TIME; (* Required to be positive. *)
END_VAR
VAR_OUTPUT
    Operator_Alert : BOOL := FALSE;
    Weld_Soft_Start_Active : BOOL := TRUE;
END_VAR
VAR
    BootTimer : TON;
    GapTimer : TON;
    InitComplete : BOOL := FALSE;
    initActive : BOOL := TRUE;
    debounceElapsed : TIME := T#0s;
END_VAR

(* One-shot power-up interval. E-stop does not pause or restart it.
   These variables must remain non-retained. *)
BootTimer(IN := NOT InitComplete, PT := T#5s);

IF BootTimer.Q THEN
    InitComplete := TRUE;
END_IF;

initActive := NOT InitComplete;
Weld_Soft_Start_Active := initActive;

(* Calling TON with IN=FALSE resets both ET and Q in this scan.
   No debounce time accumulates during initialization or E-stop. *)
GapTimer(
    IN := NOT initActive AND Weld_E_Stop_NC AND Gap_Exceeded,
    PT := DebounceTime
);
debounceElapsed := GapTimer.ET;

(* Initialization and emergency stop dominate the alarm command. *)
Operator_Alert :=
    NOT initActive
    AND Weld_E_Stop_NC
    AND Gap_Exceeded
    AND GapTimer.Q;

END_PROGRAM