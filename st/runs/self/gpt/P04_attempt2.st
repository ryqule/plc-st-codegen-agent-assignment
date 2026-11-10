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
    debounceElapsed : TIME := T#0ms;
    viscosityValid  : BOOL := FALSE;
    parametersValid : BOOL := FALSE;
END_VAR

parametersValid := (DebounceTime > T#0ms) AND (CycleTime > T#0ms);

(* Reset debounce immediately on emergency stop, signal loss,
   or invalid timing parameters. *)
IF NOT PASTE_E_STOP_NC
   OR NOT parametersValid
   OR NOT VISCOSITY_OK THEN
    debounceElapsed := T#0ms;
    viscosityValid := FALSE;
ELSE
    (* Cap elapsed time at the threshold without overflowing TIME. *)
    IF debounceElapsed < DebounceTime THEN
        IF CycleTime >= (DebounceTime - debounceElapsed) THEN
            debounceElapsed := DebounceTime;
        ELSE
            debounceElapsed := debounceElapsed + CycleTime;
        END_IF;
    ELSE
        debounceElapsed := DebounceTime;
    END_IF;

    viscosityValid := (debounceElapsed >= DebounceTime);
END_IF;

VFD_RUN := PASTE_E_STOP_NC AND parametersValid AND viscosityValid;

(* Preserve accumulated runtime whenever the pump is stopped. *)
IF VFD_RUN THEN
    PUMP_RUNTIME_ACC := PUMP_RUNTIME_ACC + TIME_TO_LTIME(CycleTime);
END_IF;

(* Informational only; does not inhibit operation. *)
PUMP_MAINT_DUE := (PUMP_RUNTIME_ACC >= LTIME#500h);

END_PROGRAM