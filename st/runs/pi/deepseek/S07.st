FUNCTION_BLOCK FB_GuardDoorSafety
VAR_INPUT
    GuardClosed  : BOOL;
    EStopOK      : BOOL;
    ResetButton  : BOOL;
    AutoPermit   : BOOL;
END_VAR
VAR_OUTPUT
    SafetyRelay  : BOOL;
    TripLatched  : BOOL;
END_VAR
VAR
    ResetPrev    : BOOL := FALSE;
    InitDone     : BOOL := FALSE;
END_VAR

(* Power-up initialization: relay off, trip latched until a valid reset *)
IF NOT InitDone THEN
    SafetyRelay := FALSE;
    TripLatched := TRUE;
    ResetPrev   := ResetButton;
    InitDone    := TRUE;
END_IF

(* Rising-edge detection on ResetButton *)
VAR
    ResetRising : BOOL;
END_VAR
ResetRising := ResetButton AND NOT ResetPrev;
ResetPrev   := ResetButton;

(* Valid reset: rising edge, guard closed, E-stop OK, AutoPermit FALSE *)
IF ResetRising AND GuardClosed AND EStopOK AND NOT AutoPermit THEN
    TripLatched := FALSE;
END_IF

(* Safety trip: guard open or E-stop active -> drop relay same scan, latch trip *)
IF (NOT GuardClosed) OR (NOT EStopOK) THEN
    SafetyRelay := FALSE;
    TripLatched := TRUE;
END_IF

(* Relay energize interlock: all permissives and no latched trip *)
IF GuardClosed AND EStopOK AND AutoPermit AND NOT TripLatched THEN
    SafetyRelay := TRUE;
ELSE
    SafetyRelay := FALSE;
END_IF
END_FUNCTION_BLOCK