```st
FUNCTION_BLOCK P01_FillingLine
VAR_INPUT
    bottleSensor          : BOOL; (* bottle detected at sensor *)
    cleaningConfirmButton : BOOL; (* operator confirms cleaning done *)
    fillingConfirmButton  : BOOL; (* operator confirms filling done *)
    cappingConfirmButton  : BOOL; (* operator confirms capping done *)
    packingConfirmButton  : BOOL; (* operator confirms packing done *)
    finishedButton        : BOOL; (* operator confirms bottle picked up *)
END_VAR
VAR_OUTPUT
    Pump_Motor       : BOOL; (* cleaning pump motor *)
    Filling_Valve    : BOOL; (* filling valve *)
    Capping_Machine  : BOOL; (* capping machine *)
    Packing_Machine  : BOOL; (* packing machine *)
    Completion_Light : BOOL; (* packaging completion light *)
END_VAR
VAR
    (* Edge memories *)
    rBottleSensor          : R_TRIG;
    rCleaningConfirmButton : R_TRIG;
    rFillingConfirmButton  : R_TRIG;
    rCappingConfirmButton  : R_TRIG;
    rPackingConfirmButton  : R_TRIG;
    rFinishedButton        : R_TRIG;

    (* Pulses (one scan) *)
    bottlePulse          : BOOL;
    cleaningPulse        : BOOL;
    fillingPulse         : BOOL;
    cappingPulse         : BOOL;
    packingPulse         : BOOL;
    finishedPulse        : BOOL;

    (* Phase state machine *)
    phase : INT;

    (* Last-cycle diagnostic of finishedPulse used for L5 semantics *)
    finishedPulsePrev : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Edge detection                                                     *)
(* ------------------------------------------------------------------ *)
rBottleSensor(CLK := bottleSensor);
bottlePulse := rBottleSensor.Q;

rCleaningConfirmButton(CLK := cleaningConfirmButton);
cleaningPulse := rCleaningConfirmButton.Q;

rFillingConfirmButton(CLK := fillingConfirmButton);
fillingPulse := rFillingConfirmButton.Q;

rCappingConfirmButton(CLK := cappingConfirmButton);
cappingPulse := rCappingConfirmButton.Q;

rPackingConfirmButton(CLK := packingConfirmButton);
packingPulse := rPackingConfirmButton.Q;

rFinishedButton(CLK := finishedButton);
finishedPulse := rFinishedButton.Q;

(* ------------------------------------------------------------------ *)
(* Phase transition: synchronous, edge-triggered, mutually exclusive  *)
(* Phase codes: 0 = IDLE, 1 = CLEAN, 2 = FILL, 3 = CAP, 4 = PACK,     *)
(*              5 = PACKED                                           *)
(* ------------------------------------------------------------------ *)
CASE phase OF
    0: (* IDLE *)
        IF bottlePulse THEN
            phase := 1; (* CLEAN *)
        END_IF;

    1: (* CLEAN *)
        IF cleaningPulse THEN
            phase := 2; (* FILL *)
        END_IF;

    2: (* FILL *)
        IF fillingPulse THEN
            phase := 3; (* CAP *)
        END_IF;

    3: (* CAP *)
        IF cappingPulse THEN
            phase := 4; (* PACK *)
        END_IF;

    4: (* PACK *)
        IF packingPulse THEN
            phase := 5; (* PACKED *)
        END_IF;

    5: (* PACKED *)
        IF finishedPulse THEN
            phase := 0; (* back to IDLE *)