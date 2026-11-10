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
    previousReset : BOOL := FALSE;
    previousCycleActive : BOOL := FALSE;
    cycleActive : BOOL := FALSE;
    resetEdge : BOOL := FALSE;
    cycleEnd : BOOL := FALSE;
    prevLeadIs1 : BOOL := TRUE;
    selectedCompressor : USINT := 0;
END_VAR

(* Detect scan-level edges and demand-cycle completion. *)
resetEdge := Reset AND NOT previousReset;
cycleActive := Demand AND PressureLow;
cycleEnd := previousCycleActive AND NOT cycleActive;
prevLeadIs1 := LeadIs1;

(* Alternate exactly once when the demand permissive becomes inactive. *)
IF cycleEnd THEN
    LeadIs1 := NOT prevLeadIs1;
END_IF;

(* Both-fault detection applies even when demand is inactive.
   Clearing requires a fresh reset edge and all specified permissives. *)
IF Compressor1Fault AND Compressor2Fault THEN
    Fault := TRUE;
ELSIF resetEdge
      AND NOT Compressor1Fault
      AND NOT Compressor2Fault
      AND NOT Demand THEN
    Fault := FALSE;
END_IF;

(* Default-off outputs ensure mutual exclusion and immediate interlocking. *)
Compressor1Run := FALSE;
Compressor2Run := FALSE;

IF NOT cycleActive OR Fault THEN
    selectedCompressor := 0;
ELSE
    (* Keep the running compressor through the cycle while it is healthy.
       A fault invalidates its selection before outputs are assigned. *)
    IF (selectedCompressor = 1) AND Compressor1Fault THEN
        selectedCompressor := 0;
    ELSIF (selectedCompressor = 2) AND Compressor2Fault THEN
        selectedCompressor := 0;
    END_IF;

    (* Initial selection or same-scan fault transfer. *)
    IF selectedCompressor = 0 THEN
        IF LeadIs1 THEN
            IF NOT Compressor1Fault THEN
                selectedCompressor := 1;
            ELSIF NOT Compressor2Fault THEN
                selectedCompressor := 2;
            END_IF;
        ELSE
            IF NOT Compressor2Fault THEN
                selectedCompressor := 2;
            ELSIF NOT Compressor1Fault THEN
                selectedCompressor := 1;
            END_IF;
        END_IF;
    END_IF;

    IF selectedCompressor = 1 THEN
        Compressor1Run := NOT Compressor1Fault;
    ELSIF selectedCompressor = 2 THEN
        Compressor2Run := NOT Compressor2Fault;
    END_IF;
END_IF;

previousReset := Reset;
previousCycleActive := cycleActive;

END_PROGRAM