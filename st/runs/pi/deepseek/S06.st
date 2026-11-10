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
    DemandActivePrev  : BOOL;
    CycleEnd          : BOOL;
    PrevLeadIs1       : BOOL;
    DemandActive      : BOOL;
END_VAR

(* ---- Edge detection ---- *)
ResetEdge := Reset AND NOT ResetPrev;
ResetPrev := Reset;

(* ---- Demand active condition (process demand permissive) ---- *)
DemandActive := Demand AND PressureLow;

(* ---- Cycle end: Demand or PressureLow becoming FALSE ---- *)
CycleEnd := DemandActivePrev AND NOT DemandActive;
DemandActivePrev := DemandActive;

(* ---- Fault latch: both faults -> latch Fault ---- *)
IF Compressor1Fault AND Compressor2Fault THEN
    Fault := TRUE;
END_IF;

(* ---- Reset: rising edge clears Fault only when both faults clear and Demand FALSE ---- *)
IF ResetEdge AND NOT Compressor1Fault AND NOT Compressor2Fault AND NOT Demand THEN
    Fault := FALSE;
END_IF;

(* ---- Lead alternation after each completed demand cycle ---- *)
IF CycleEnd THEN
    PrevLeadIs1 := LeadIs1;
    LeadIs1 := NOT LeadIs1;
END_IF;

(* ---- Output logic: exactly one healthy compressor while demand active and no fault ---- *)
Compressor1Run := FALSE;
Compressor2Run := FALSE;

IF DemandActive AND NOT Fault THEN
    IF LeadIs1 THEN
        (* Lead is compressor 1 *)
        IF NOT Compressor1Fault THEN
            Compressor1Run := TRUE;
        ELSIF NOT Compressor2Fault THEN
            Compressor2Run := TRUE;
        END_IF;
    ELSE
        (* Lead is compressor 2 *)
        IF NOT Compressor2Fault THEN
            Compressor2Run := TRUE;
        ELSIF NOT Compressor1Fault THEN
            Compressor1Run := TRUE;
        END_IF;
    END_IF;
END_IF;

(* ---- Safety interlock: never run both together ---- *)
IF Compressor1Run AND Compressor2Run THEN
    Compressor1Run := FALSE;
    Compressor2Run := FALSE;
END_IF;

END_FUNCTION_BLOCK