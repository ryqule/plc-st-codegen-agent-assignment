FUNCTION_BLOCK FB_DualCompressorLeadLag
VAR_INPUT
    Demand            : BOOL;
    Compressor1Fault  : BOOL;
    Compressor2Fault  : BOOL;
    PressureLow       : BOOL;
    Reset             : BOOL;
END_VAR
VAR_OUTPUT
    Compressor1Run    : BOOL;
    Compressor2Run    : BOOL;
    LeadIs1           : BOOL := TRUE;
    Fault             : BOOL;
END_VAR
VAR
    ResetPrev         : BOOL;
    ResetEdge         : BOOL;
    DemandActive      : BOOL;
    DemandActivePrev  : BOOL;
    CycleEnd          : BOOL;
    PrevLeadIs1       : BOOL;
    BothFaults        : BOOL;
    AnyFault          : BOOL;
    Healthy1          : BOOL;
    Healthy2          : BOOL;
    RunPermissive     : BOOL;
END_VAR

// --- Edge detection for Reset ---
ResetEdge := Reset AND NOT ResetPrev;
ResetPrev := Reset;

// --- Fault evaluation ---
BothFaults := Compressor1Fault AND Compressor2Fault;
AnyFault   := Compressor1Fault OR Compressor2Fault;
Healthy1   := NOT Compressor1Fault;
Healthy2   := NOT Compressor2Fault;

// --- Latch Fault when both compressors fault ---
IF BothFaults THEN
    Fault := TRUE;
END_IF;

// --- Reset rising edge clears Fault only when both faults clear and Demand FALSE ---
IF ResetEdge AND NOT Compressor1Fault AND NOT Compressor2Fault AND NOT Demand THEN
    Fault := FALSE;
END_IF;

// --- Demand cycle tracking (cycle ends when Demand or PressureLow goes FALSE) ---
DemandActive := Demand AND PressureLow;
CycleEnd := DemandActivePrev AND NOT DemandActive;

// --- Lead alternation on completed demand cycle ---
IF CycleEnd THEN
    PrevLeadIs1 := LeadIs1;
    LeadIs1 := NOT LeadIs1;
END_IF;

// --- Run permissive ---
RunPermissive := DemandActive AND NOT Fault;

// --- Output interlock: never run both, only healthy compressor ---
Compressor1Run := FALSE;
Compressor2Run := FALSE;

IF RunPermissive THEN
    IF LeadIs1 THEN
        // Lead is compressor 1
        IF Healthy1 THEN
            Compressor1Run := TRUE;
        ELSIF Healthy2 THEN
            Compressor2Run := TRUE;
        END_IF;
    ELSE
        // Lead is compressor 2
        IF Healthy2 THEN
            Compressor2Run := TRUE;
        ELSIF Healthy1 THEN
            Compressor1Run := TRUE;
        END_IF;
    END_IF;
END_IF;

// --- Final safety interlock: never both ---
IF Compressor1Run AND Compressor2Run THEN
    Compressor1Run := FALSE;
    Compressor2Run := FALSE;
END_IF;

// --- Update demand-active history for next scan ---
DemandActivePrev := DemandActive;

END_FUNCTION_BLOCK