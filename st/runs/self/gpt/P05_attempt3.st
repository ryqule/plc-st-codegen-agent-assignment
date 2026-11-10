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
    firstScan       : BOOL := TRUE;
    bootComplete    : BOOL := FALSE;
    initActive      : BOOL := TRUE;
    gapTiming       : BOOL := FALSE;
    currentTime     : TIME;
    bootStartTime   : TIME := T#0s;
    gapStartTime    : TIME := T#0s;
    debounceElapsed : TIME := T#0s;
END_VAR

(* CODESYS millisecond clock; no TON instances required. *)
currentTime := TIME();

IF firstScan THEN
    bootStartTime := currentTime;
    firstScan := FALSE;
END_IF;

(* The one-shot boot interval runs independently of E-stop. *)
IF NOT bootComplete THEN
    IF (currentTime - bootStartTime) >= T#5s THEN
        bootComplete := TRUE;
    END_IF;
END_IF;

initActive := NOT bootComplete;
Weld_Soft_Start_Active := initActive;

(* Inhibition, E-stop, and a FALSE gap clear debounce state. *)
IF initActive OR NOT Weld_E_Stop_NC OR NOT Gap_Exceeded THEN
    gapTiming := FALSE;
    debounceElapsed := T#0s;
    Operator_Alert := FALSE;
ELSE
    IF NOT gapTiming THEN
        gapStartTime := currentTime;
        debounceElapsed := T#0s;
        gapTiming := TRUE;
    END_IF;

    (* DebounceTime is positive by the input contract. *)
    IF debounceElapsed < DebounceTime THEN
        debounceElapsed := currentTime - gapStartTime;
        IF debounceElapsed > DebounceTime THEN
            debounceElapsed := DebounceTime;
        END_IF;
    END_IF;

    Operator_Alert := debounceElapsed >= DebounceTime;
END_IF;

(* T1 / L1: Boot inhibition asserts soft-start and suppresses the alarm.
   T2: Continuous gap detection alarms after DebounceTime.
   T3 / L2: E-stop or gap clearing resets timing and suppresses the alarm.
   E-stop never pauses or restarts the boot interval. *)
END_PROGRAM