```st
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

(* Non-retained initial values establish the power-up state. *)
parametersValid := (DebounceTime > T#0ms) AND (CycleTime > T#0ms);

(* Emergency stop, invalid timing parameters, or raw signal loss
   immediately invalidate the condition and reset debounce timing. *)
IF NOT PASTE_E_STOP_NC
   OR NOT parametersValid
   OR NOT VISCOSITY_OK THEN

    debounceElapsed := T#0ms;
    viscosityValid := FALSE;

ELSE
    (* Accumulate supplied invocation intervals, capped at the threshold.
       Comparing the remaining duration before adding avoids TIME overflow. *)
    IF debounceElapsed < DebounceTime THEN
        IF CycleTime >= (DebounceTime - debounceElapsed) THEN
            debounceElapsed := DebounceTime;
        ELSE
            debounceElapsed := debounceElapsed + CycleTime;
        END_IF;
    ELSE
        debounceElapsed := DebounceTime;
    END_IF;

    viscosityValid := (debounceElapsed >= Deb