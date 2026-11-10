```st
FUNCTION_BLOCK P15_MaterialProportioning
VAR_INPUT
    estop           : BOOL; (* FALSE: emergency stop triggered *)
    opeMode         : BOOL; (* FALSE: manual, TRUE: automatic *)
    valveAStart     : BOOL;
    valveBStart     : BOOL;
    valveCStart     : BOOL;
    valveDStart     : BOOL;
    mixMotorStart   : BOOL;
    autoStart       : BOOL;
    processMode     : BOOL;
    levelSensor     : INT;
    mixMotorComplete: BOOL;
END_VAR
VAR_OUTPUT
    valveARun       : BOOL;
    valveBRun       : BOOL;
    valveCRun       : BOOL;
    valveDRun       : BOOL;
    mixMotorRun     : BOOL;
END_VAR
VAR
    (* Edge detection memories *)
    rtValveAStart   : R_TRIG;
    rtValveBStart   : R_TRIG;
    rtValveCStart   : R_TRIG;
    rtValveDStart   : R_TRIG;
    rtMixMotorStart : R_TRIG;
    rtAutoStart     : R_TRIG;
    (* Manual toggle states *)
    manValveA       : BOOL;
    manValveB       : BOOL;
    manValveC       : BOOL;
    manValveD       : BOOL;
    manMixMotor     : BOOL;
    (* Automatic state machine *)
    step            : INT;
END_VAR
VAR CONSTANT
    IDLE            : INT := 0;
    FILL_A          : INT := 1;
    FILL_B          : INT := 2;
    FILL_C          : INT := 3;
    MIX             : INT := 4;
    DISCHARGE       : INT := 5;
END_VAR

(* Edge detection *)
rtValveAStart(CLK := valveAStart);
rtValveBStart(CLK := valveBStart);
rtValveCStart(CLK := valveCStart);
rtValveDStart(CLK := valveDStart);
rtMixMotorStart(CLK := mixMotorStart);
rtAutoStart(CLK := autoStart);

(* Manual mode toggle handling (only when in manual mode and no e-stop) *)
IF NOT opeMode AND estop THEN
    IF rtValveAStart.Q THEN
        manValveA := NOT manValveA;
    END_IF;
    IF rtValveBStart.Q THEN
        manValveB := NOT manValveB;
    END_IF;
    IF rtValveCStart.Q THEN
        manValveC := NOT manValveC;
    END_IF;
    IF rtValveDStart.Q THEN
        manValveD := NOT manValveD;
    END_IF;
    IF rtMixMotorStart.Q THEN
        manMixMotor := NOT manMixMotor;
    END_IF;
END_IF;

(* Automatic state machine *)
IF NOT opeMode THEN
    (* Leaving automatic mode resets sequence *)
    step := IDLE;
    valveARun := FALSE;
    valveBRun := FALSE;
    valveCRun := FALSE;
    valveDRun := FALSE;
    mixMotorRun := FALSE;
    (* Apply manual toggles *)
    valveARun := manValveA;
    valveBRun := manValveB;
    valveCRun := manValveC;
    valveDRun := manValveD;
    mixMotorRun := manMixMotor;
ELSE