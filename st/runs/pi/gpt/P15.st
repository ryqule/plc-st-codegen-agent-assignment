```st
PROGRAM P15
VAR_INPUT
    estop : BOOL;
    opeMode : BOOL;
    valveAStart : BOOL;
    valveBStart : BOOL;
    valveCStart : BOOL;
    valveDStart : BOOL;
    mixMotorStart : BOOL;
    autoStart : BOOL;
    processMode : BOOL;
    levelSensor : INT;
    mixMotorComplete : BOOL;
END_VAR

VAR_OUTPUT
    valveARun : BOOL := FALSE;
    valveBRun : BOOL := FALSE;
    valveCRun : BOOL := FALSE;
    valveDRun : BOOL := FALSE;
    mixMotorRun : BOOL := FALSE;
END_VAR

VAR CONSTANT
    IDLE : INT := 0;
    FILL_A : INT := 1;
    FILL_B : INT := 2;
    FILL_C : INT := 3;
    MIX : INT := 4;
    DISCHARGE : INT := 5;
END_VAR

VAR
    step : INT := 0;
    nextStep : INT := 0;

    previousMode : BOOL := FALSE;
    previousA : BOOL := FALSE;
    previousB : BOOL := FALSE;
    previousC : BOOL := FALSE;
    previousD : BOOL := FALSE;
    previousMotor : BOOL := FALSE;
    previousAuto : BOOL := FALSE;

    edgeA : BOOL;
    edgeB : BOOL;
    edgeC : BOOL;
    edgeD : BOOL;
    edgeMotor : BOOL;
    edgeAuto : BOOL;
END_VAR

(* Detect edges in every mode, including during an emergency stop.
   A held button therefore does not become a new command on release. *)
edgeA := valveAStart AND NOT previousA;
edgeB := valveBStart AND NOT previousB;
edgeC := valveCStart AND NOT previousC;
edgeD := valveDStart AND NOT previousD;
edgeMotor := mixMotorStart AND NOT previousMotor;
edgeAuto := autoStart AND NOT previousAuto;

previousA := valveAStart;
previousB := valveBStart;
previousC := valveCStart;
previousD := valveDStart;
previousMotor := mixMotorStart;
previousAuto := autoStart;

(* Commit the transition requested by the preceding scan. *)
step := nextStep;

(* Do not transfer run commands between operation modes. *)
IF opeMode <> previousMode THEN
    step := IDLE;
    nextStep := IDLE;
    valveARun := FALSE;
    valveBRun := FALSE;
    valveCRun := FALSE;
    valveDRun := FALSE;
    mixMotorRun := FALSE;
END