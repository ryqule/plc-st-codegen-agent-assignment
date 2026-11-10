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
    ResetRising  : BOOL;
    ValidReset   : BOOL;
    PowerUpDone  : BOOL := FALSE;
END_VAR

(* Power-up initialization: relay off, trip latched until a valid reset.
   PowerUpDone is FALSE on first scan, so the trip is forced latched. *)
IF NOT PowerUpDone THEN
    TripLatched := TRUE;
    SafetyRelay := FALSE;
    PowerUpDone := TRUE;
END_IF

(* Rising-edge detection on ResetButton *)
ResetRising := ResetButton AND NOT ResetPrev;
ResetPrev   := ResetButton;

(* Valid reset: rising edge while guard closed, E-stop OK, and AutoPermit FALSE *)
ValidReset := ResetRising AND GuardClosed AND EStopOK AND NOT AutoPermit;

(* Trip latch logic:
   - Any safety violation (guard open or E-stop active) latches the trip
     in the same scan.
   - A valid reset clears the trip.
   - Otherwise the trip holds its previous state. *)
IF (NOT GuardClosed) OR (NOT EStopOK) THEN
    TripLatched := TRUE;
ELSIF ValidReset THEN
    TripLatched := FALSE;
END_IF

(* Safety relay: only energize when all permissives are satisfied and
   no trip is latched. Evaluated after the latch update so a violation
   in this scan drops the relay in the same scan. *)
SafetyRelay := GuardClosed AND EStopOK AND AutoPermit AND NOT TripLatched;

END_FUNCTION_BLOCK