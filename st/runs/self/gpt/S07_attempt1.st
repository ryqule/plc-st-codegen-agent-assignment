PROGRAM S07
VAR_INPUT
    GuardClosed : BOOL;
    EStopOK : BOOL;
    ResetButton : BOOL;
    AutoPermit : BOOL;
END_VAR

VAR_OUTPUT
    SafetyRelay : BOOL := FALSE;
    TripLatched : BOOL := TRUE;
END_VAR

VAR
    ResetButtonPrevious : BOOL := FALSE;
    validReset : BOOL := FALSE;
END_VAR

(* A reset is valid only on a rising edge with safe inputs
   and automatic operation disabled. *)
validReset := ResetButton
              AND NOT ResetButtonPrevious
              AND GuardClosed
              AND EStopOK
              AND NOT AutoPermit;

(* Unsafe inputs dominate reset and latch the trip immediately. *)
IF NOT GuardClosed OR NOT EStopOK THEN
    TripLatched := TRUE;
ELSIF validReset THEN
    TripLatched := FALSE;
END_IF;

(* Recompute the relay every scan from all required permissives. *)
SafetyRelay := GuardClosed
               AND EStopOK
               AND AutoPermit
               AND NOT TripLatched;

(* Track the button even when reset is inhibited. *)
ResetButtonPrevious := ResetButton;

END_PROGRAM