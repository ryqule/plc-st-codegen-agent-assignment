```st
FUNCTION_BLOCK FB_AutomatedFillingLine
VAR_INPUT
    bottleSensor            : BOOL; (* bottle detected at sensor *)
    cleaningConfirmButton   : BOOL; (* operator confirms cleaning complete *)
    fillingConfirmButton    : BOOL; (* operator confirms filling complete *)
    cappingConfirmButton    : BOOL; (* operator confirms capping complete *)
    packingConfirmButton    : BOOL; (* operator confirms packing complete *)
    finishedButton          : BOOL; (* operator confirms bottle picked up *)
END_VAR

VAR_OUTPUT
    Pump_Motor          : BOOL; (* cleaning pump motor *)
    Filling_Valve       : BOOL; (* filling valve *)
    Capping_Machine     : BOOL; (* capping machine *)
    Packing_Machine     : BOOL; (* packing machine *)
    Completion_Light    : BOOL; (* packaging completion indicator *)
END_VAR

VAR
    (* Internal phase enumeration: 0=IDLE 1=CLEAN 2=FILL 3=CAP 4=PACK 5=PACKED *)
    phase               : INT;

    (* Rising-edge detection memories *)
    rtBottleSensor      : R_TRIG;
    rtCleaningConfirm   : R_TRIG;
    rtFillingConfirm    : R_TRIG;
    rtCappingConfirm    : R_TRIG;
    rtPackingConfirm    : R_TRIG;
    rtFinished          : R_TRIG;

    (* Edge pulses captured this scan *)
    bottlePulse         : BOOL;
    cleaningPulse       : BOOL;
    fillingPulse        : BOOL;
    cappingPulse        : BOOL;
    packingPulse        : BOOL;
    finishedPulse       : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Edge detection on all operator/sensor inputs                        *)
(* ------------------------------------------------------------------ *)
rtBottleSensor(CLK := bottleSensor);
bottlePulse := rtBottleSensor.Q;

rtCleaningConfirm(CLK := cleaningConfirmButton);
cleaningPulse := rtCleaningConfirm.Q;

rtFillingConfirm(CLK := fillingConfirmButton);
fillingPulse := rtFillingConfirm.Q;

rtCappingConfirm(CLK := cappingConfirmButton);
cappingPulse := rtCappingConfirm.Q;

rtPackingConfirm(CLK := packingConfirmButton);
packingPulse := rtPackingConfirm.Q;

rtFinished(CLK := finishedButton);
finishedPulse := rtFinished.Q;

(* ------------------------------------------------------------------ *)
(* State machine transitions.                                          *)
(* PRIORITY NOTE: The requirements only define normal sequential       *)
(* operation; there is no specified E-Stop/Stop input in the interface *)
(* so none is fabricated. Only the declared inputs drive transitions.  *)
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
            phase := 0; (* IDLE *)
        END_IF;

ELSE