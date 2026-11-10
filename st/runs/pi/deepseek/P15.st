```st
FUNCTION_BLOCK P15_MaterialProportioning
VAR_INPUT
    estop           : BOOL; (* FALSE: emergency stop triggered; TRUE: normal *)
    opeMode         : BOOL; (* FALSE: manual; TRUE: automatic *)
    valveAStart     : BOOL;
    valveBStart     : BOOL;
    valveCStart     : BOOL;
    valveDStart     : BOOL;
    mixMotorStart   : BOOL;
    autoStart       : BOOL;
    processMode     : BOOL;
    levelSensor     : INT;  (* cm *)
    mixMotorComplete: BOOL;
END_VAR

VAR_OUTPUT
    valveARun   : BOOL;
    valveBRun   : BOOL;
    valveCRun   : BOOL;
    valveDRun   : BOOL;
    mixMotorRun : BOOL;
END_VAR

VAR
    (* step state machine for automatic mode *)
    step            : INT := 0;
    (* edge detection memories *)
    rtA             : R_TRIG;
    rtB             : R_TRIG;
    rtC             : R_TRIG;
    rtD             : R_TRIG;
    rtMix           : R_TRIG;
    rtAuto          : R_TRIG;
    (* manual toggle states *)
    manA            : BOOL;
    manB            : BOOL;
    manC            : BOOL;
    manD            : BOOL;
    manMix          : BOOL;
END_VAR

VAR CONSTANT
    STEP_IDLE    : INT := 0;
    STEP_FILL_A  : INT := 1;
    STEP_FILL_B  : INT := 2;
    STEP_FILL_C  : INT := 3;
    STEP_MIX     : INT := 4;
    STEP_DISCHARGE : INT := 5;
END_VAR

(* ---------- Edge detection ---------- *)
rtA(CLK := valveAStart);
rtB(CLK := valveBStart);
rtC(CLK := valveCStart);
rtD(CLK := valveDStart);
rtMix(CLK := mixMotorStart);
rtAuto(CLK := autoStart);

(* ---------- Global e-stop dominance ---------- *)
IF NOT estop THEN
    (* Emergency stop: force everything off immediately *)
    valveARun   := FALSE;
    valveBRun   := FALSE;
    valveCRun   := FALSE;
    valveDRun   := FALSE;
    mixMotorRun := FALSE;
    (* Reset automatic sequence and manual toggles *)
    step   := STEP_IDLE;
    manA   := FALSE;
    manB   := FALSE;
    manC   := FALSE;
    manD   := FALSE;
    manMix := FALSE;
    RETURN;
END_IF

(* ---------- Mode handling ---------- *)
IF NOT opeMode THEN
    (* ================= Manual mode ================= *)
    (* Automatic step cleared when leaving auto *)
    step := STEP_IDLE;

    (* Toggle on rising edge of each start button *)
    IF rtA.Q THEN
        manA := NOT manA;
    END_IF;
    IF rtB.Q THEN
        manB := NOT manB;
    END_IF;
    IF rtC.Q THEN
        manC := NOT manC;
    END_IF;
    IF rtD.Q THEN
        manD := NOT manD;
    END_IF;
    IF rtMix.Q THEN
        manMix := NOT manMix;
    END_IF;

    valveARun   := manA;
    valveBRun   := manB;
    valveCRun   :=