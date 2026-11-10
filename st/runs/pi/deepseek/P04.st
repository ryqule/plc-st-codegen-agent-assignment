Looking at this task, I need to implement:

1. **Debouncing**: `VISCOSITY_OK` must stay TRUE for `DebounceTime` before `viscosityValid` becomes TRUE; invalidate immediately when FALSE.
2. **Safety**: `VFD_RUN` only when `PASTE_E_STOP_NC` TRUE and `viscosityValid`. E-stop drops run immediately and clears debounce timing.
3. **Runtime accumulation**: add `CycleTime` only while `VFD_RUN`, preserve when stopped.
4. **Maintenance**: `PUMP_MAINT_DUE` when runtime >= 500h.
5. **Init**: run OFF, runtime 0, maint FALSE.

**Ambiguities resolved per benchmark assumptions:**
- Timer uses supplied elapsed scan time (`CycleTime`).
- Nonpositive `DebounceTime` or `CycleTime` treated as invalid → inhibits run.
- `DebounceTime`/`CycleTime` are `TIME`, runtime is `LTIME` — comparisons/increments use `DTIME` conversions (100% CODESYS supported).
- LTL P04-L3 says `debounceElapsed >= DebounceTime -> X(viscosityValid)` — so validation happens following scan; I compute the next-state `viscosityValid` from accumulated elapsed, but run gating uses the *current* valid flag consistent with L2 (run ⇒ currently valid). I accumulate elapsed this scan, and the valid flag reflects completion at this scan's end (making L3 hold with next-state X valid), while run is gated on current `viscosityValid` and permissive.

The clean synthesis: maintain `debounceElapsed` (LTIME) and `viscosityValid` (BOOL) as state. Each scan, if `VISCOSITY_OK` and E-stop permissive and not yet valid, add `CycleTime`; when elapsed >= `DebounceTime`, set `viscosityValid` TRUE. If `VISCOSITY_OK` FALSE (or E-stop dropped), reset elapsed to 0 and `viscosityValid` to FALSE immediately. Then compute `VFD_RUN`. Note L3 uses X(viscosityValid), arising naturally since valid is set based on this scan's elapsed and used next scan's run.

Actually, to satisfy L2 (`VFD_RUN -> viscosityValid`) at the same scan where valid becomes TRUE, I should set `viscosityValid` before computing `VFD_RUN`, then run may be TRUE same scan. That still satisfies L3's X. Fine.

```st
FUNCTION_BLOCK FB_JamPump
VAR_INPUT
    VISCOSITY_OK     : BOOL;
    PASTE_E_STOP_NC  : BOOL;
    DebounceTime     : TIME;
    CycleTime        : TIME;
END_VAR
VAR_OUTPUT
    VFD_RUN          : BOOL;
    PUMP_MAINT_DUE   : BOOL;
    PUMP_RUNTIME_ACC : LTIME;
END_VAR
VAR
    debounceElapsed  : LTIME;
    viscosityValid   : BOOL;
    initDone         : BOOL;
    dtDebounce       : LTIME;
    dtCycle          : LTIME;
    maintThreshold   : LTIME := LTIME#500h;
END_VAR

// --- Power-up initialization ---
IF NOT initDone THEN
    VFD_RUN          := FALSE;
    PUMP_RUNTIME_ACC := LTIME#0ms;
    PUMP_MAINT_DUE   := FALSE;
    debounceElapsed  := LTIME#0