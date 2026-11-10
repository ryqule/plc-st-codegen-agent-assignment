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
    Initialized : BOOL := FALSE;
    PreviousResetButton : BOOL := FALSE;
    ResetRisingEdge : BOOL := FALSE;
    validReset : BOOL := FALSE;
END_VAR

IF NOT Initialized THEN
    (* Power-up state; sample the button without accepting a startup reset. *)
    SafetyRelay := FALSE;
    TripLatched := TRUE;
    ResetRisingEdge := FALSE;
    validReset := FALSE;
    Initialized := TRUE;
ELSE
    ResetRisingEdge := ResetButton AND NOT PreviousResetButton;
    validReset := ResetRisingEdge
                  AND GuardClosed
                  AND EStopOK
                  AND NOT AutoPermit;

    (* Unsafe inputs dominate all normal commands and reset processing. *)
    IF NOT GuardClosed OR NOT EStopOK THEN
        TripLatched := TRUE;
    ELSIF validReset THEN
        TripLatched := FALSE;
    END_IF;

    (* Evaluate after latch updates so a safety trip drops the relay this scan. *)
    SafetyRelay := GuardClosed
                   AND EStopOK
                   AND AutoPermit
                   AND NOT TripLatched;
END_IF;

PreviousResetButton := ResetButton;
END_PROGRAM