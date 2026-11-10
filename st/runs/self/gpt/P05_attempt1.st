PROGRAM P05
VAR_INPUT
    Gap_Exceeded   : BOOL;
    Weld_E_Stop_NC : BOOL;
    DebounceTime   : TIME;
END_VAR

VAR_OUTPUT
    Operator_Alert         : BOOL := FALSE;
    Weld_Soft_Start_Active : BOOL := TRUE;
END_VAR

VAR
    InitializationTimer : TON;
    GapDebounceTimer    : TON;
    initActive         : BOOL := TRUE;
    debounceElapsed    : TIME := T#0s;
END_VAR

(* One-shot power-up interval. E-stop does not restart or pause it. *)
InitializationTimer(IN := TRUE, PT := T#5s);
initActive := NOT InitializationTimer.Q;
Weld_Soft_Start_Active := initActive;

(* TON resets Q and ET whenever monitoring is inhibited,
   E-stop is active, or the gap signal is FALSE.
   DebounceTime is required to be positive by the interface contract. *)
GapDebounceTimer(
    IN := NOT initActive AND Weld_E_Stop_NC AND Gap_Exceeded,
    PT := DebounceTime
);
debounceElapsed := GapDebounceTimer.ET;

(* Safety and initialization inhibition dominate the alarm command. *)
Operator_Alert :=
    NOT initActive
    AND Weld_E_Stop_NC
    AND Gap_Exceeded
    AND GapDebounceTimer.Q;

END_PROGRAM