PROGRAM S06
VAR_INPUT
    Demand : BOOL;
    Compressor1Fault : BOOL;
    Compressor2Fault : BOOL;
    PressureLow : BOOL;
    Reset : BOOL;
END_VAR

VAR_OUTPUT
    Compressor1Run : BOOL := FALSE;
    Compressor2Run : BOOL := FALSE;
    LeadIs1 : BOOL := TRUE;
    Fault : BOOL := FALSE;
END_VAR

VAR
    prevReset : BOOL := FALSE;
    prevCycleActive : BOOL := FALSE;
    prevLeadIs1 : BOOL := TRUE;
    resetEdge : BOOL := FALSE;
    cycleActive : BOOL := FALSE;
    cycleEnd : BOOL := FALSE;
END_VAR

(* Capture scan-level events and the lead before any transition. *)
resetEdge := Reset AND NOT prevReset;
cycleActive := Demand AND PressureLow;
cycleEnd := prevCycleActive AND NOT cycleActive;
prevLeadIs1 := LeadIs1;

(* Alternate once when either demand condition ends an active cycle. *)
IF cycleEnd THEN
    LeadIs1 := NOT prevLeadIs1;
END_IF;

(* Both-fault detection dominates reset and normal operation. *)
IF Compressor1Fault AND Compressor2Fault THEN
    Fault := TRUE;
ELSIF resetEdge
    AND NOT Compressor1Fault
    AND NOT Compressor2Fault
    AND NOT Demand THEN
    Fault := FALSE;
END_IF;

(* Recompute mutually exclusive outputs using current-scan interlocks. *)
Compressor1Run := FALSE;
Compressor2Run := FALSE;

IF cycleActive AND NOT Fault THEN
    IF LeadIs1 THEN
        IF NOT Compressor1Fault THEN
            Compressor1Run := TRUE;
        ELSIF NOT Compressor2Fault THEN
            Compressor2Run := TRUE;
        END_IF;
    ELSE
        IF NOT Compressor2Fault THEN
            Compressor2Run := TRUE;
        ELSIF NOT Compressor1Fault THEN
            Compressor1Run := TRUE;
        END_IF;
    END_IF;
END_IF;

(* Store history for the next scan. *)
prevReset := Reset;
prevCycleActive := cycleActive;

END_PROGRAM