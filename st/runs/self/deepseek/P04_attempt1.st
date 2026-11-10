FUNCTION_BLOCK FB_JamPumpControl
VAR
    (* Edge/state tracking for viscosity debounce *)
    ViscosityDebounceTimer : TON;
    ViscosityValid        : BOOL;
    DebounceElapsed       : LTIME;

    (* Runtime accumulation *)
    RuntimeAcc            : LTIME;

    (* Inputs validity *)
    InputsValid           : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Input validation: nonpositive DebounceTime or CycleTime is invalid *)
(* and inhibits run per the stated assumption.                        *)
(* ------------------------------------------------------------------ *)
InputsValid := (DebounceTime > T#0s) AND (CycleTime > T#0s);

(* ------------------------------------------------------------------ *)
(* Emergency-stop priority: an open E-stop clears incomplete timing   *)
(* and immediately forces the run output off.                         *)
(* ------------------------------------------------------------------ *)
IF NOT PASTE_E_STOP_NC THEN
    ViscosityDebounceTimer(IN := FALSE, PT := DebounceTime);
    ViscosityValid  := FALSE;
    DebounceElapsed := LTIME#0s;
    VFD_RUN         := FALSE;
    PUMP_MAINT_DUE  := (RuntimeAcc >= LTIME#500h);
    PUMP_RUNTIME_ACC := RuntimeAcc;
    RETURN;
END_IF;

(* ------------------------------------------------------------------ *)
(* Viscosity debouncing: accept condition only after VISCOSITY_OK has *)
(* remained TRUE for DebounceTime; invalidate immediately when it falls. *)
(* ------------------------------------------------------------------ *)
ViscosityDebounceTimer(IN := VISCOSITY_OK AND InputsValid, PT := DebounceTime);

IF NOT VISCOSITY_OK THEN
    (* Invalidate immediately *)
    ViscosityValid  := FALSE;
    DebounceElapsed := LTIME#0s;
ELSE
    IF ViscosityDebounceTimer.Q THEN
        ViscosityValid  := TRUE;
        DebounceElapsed := TO_LTIME(DebounceTime);
    ELSE
        (* Still timing; track elapsed *)
        DebounceElapsed := TO_LTIME(ViscosityDebounceTimer.ET);
        IF ViscosityDebounceTimer.ET >= DebounceTime THEN
            DebounceElapsed := TO_LTIME(DebounceTime);
        END_IF;
    END_IF;
END_IF;

(* ------------------------------------------------------------------ *)
(* Run command: only permitted when E-stop permissive is present,     *)
(* inputs are valid, and the viscosity condition is valid.            *)
(* ------------------------------------------------------------------ *)
VFD_RUN := PASTE_E_STOP_NC AND InputsValid AND ViscosityValid;

(* ------------------------------------------------------------------ *)
(* Runtime accumulation using the actual invocation interval.         *)
(* Only accrues while VFD_RUN is TRUE; preserved while stopped.       *)
(* ------------------------------------------------------------------ *)
IF VFD_RUN THEN
    RuntimeAcc := RuntimeAcc + TO_LTIME(CycleTime);
END_IF;

(* ------------------------------------------------------------------ *)
(* Maintenance indication: informational only, never affects operation *)
(* or safety permissive.                                              *)
(* ------------------------------------------------------------------ *)
PUMP_MAINT_DUE := (RuntimeAcc >= LTIME#500h);

(* Publish accumulated runtime *)
PUMP_RUNTIME_ACC := RuntimeAcc;