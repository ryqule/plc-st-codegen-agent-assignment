PROGRAM P04
VAR_INPUT
    VISCOSITY_OK    : BOOL;
    PASTE_E_STOP_NC : BOOL;
    DebounceTime   : TIME;
    CycleTime      : TIME;
END_VAR

VAR_OUTPUT
    VFD_RUN          : BOOL := FALSE;
    PUMP_MAINT_DUE   : BOOL := FALSE;
    PUMP_RUNTIME_ACC : LTIME := LTIME#0ns;
END_VAR

VAR
    debounceElapsed : LTIME := LTIME#0ns;
    viscosityValid  : BOOL := FALSE;
    timingValid     : BOOL := FALSE;
    debounceTarget  : LTIME := LTIME#0ns;
    elapsedInterval : LTIME := LTIME#0ns;
END_VAR

(* Non-retained declaration initializers establish power-up values. *)
timingValid := (DebounceTime > T#0ms) AND (CycleTime > T#0ms);

IF NOT PASTE_E_STOP_NC OR NOT VISCOSITY_OK OR NOT timingValid THEN
    (* Safety, raw-signal loss, and invalid timing dominate operation. *)
    debounceElapsed := LTIME#0ns;
    viscosityValid := FALSE;
ELSE
    debounceTarget := TIME_TO_LTIME(DebounceTime);
    elapsedInterval := TIME_TO_LTIME(CycleTime);

    (* Saturate at the target instead of allowing timer overshoot. *)
    IF debounceElapsed < debounceTarget THEN
        IF elapsedInterval >= (debounceTarget - debounceElapsed) THEN
            debounceElapsed := debounceTarget;
        ELSE
            debounceElapsed := debounceElapsed + elapsedInterval;
        END_IF;
    END_IF;

    viscosityValid := (debounceElapsed >= debounceTarget);
END_IF;

VFD_RUN := PASTE_E_STOP_NC AND viscosityValid AND timingValid;

(* Charge only the supplied interval of an enabled invocation. *)
IF VFD_RUN THEN
    PUMP_RUNTIME_ACC :=
        PUMP_RUNTIME_ACC + TIME_TO_LTIME(CycleTime);
END_IF;

(* Informational only: never feeds back into the run permissive. *)
PUMP_MAINT_DUE := (PUMP_RUNTIME_ACC >= LTIME#500h);
END_PROGRAM