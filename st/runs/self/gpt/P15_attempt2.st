```st
PROGRAM P15
VAR_INPUT
    estop            : BOOL;
    opeMode          : BOOL;
    valveAStart      : BOOL;
    valveBStart      : BOOL;
    valveCStart      : BOOL;
    valveDStart      : BOOL;
    mixMotorStart    : BOOL;
    autoStart        : BOOL;
    processMode      : BOOL;
    levelSensor      : INT;
    mixMotorComplete : BOOL;
END_VAR

VAR_OUTPUT
    valveARun   : BOOL := FALSE;
    valveBRun   : BOOL := FALSE;
    valveCRun   : BOOL := FALSE;
    valveDRun   : BOOL := FALSE;
    mixMotorRun : BOOL := FALSE;
END_VAR

VAR CONSTANT
    IDLE      : INT := 0;
    FILL_A    : INT := 1;
    FILL_B    : INT := 2;
    FILL_C    : INT := 3;
    MIX       : INT := 4;
    DISCHARGE : INT := 5;
END_VAR

VAR
    step     : INT := 0;
    nextStep : INT := 0;

    previousA    : BOOL := FALSE;
    previousB    : BOOL := FALSE;
    previousC    : BOOL := FALSE;
    previousD    : BOOL := FALSE;
    previousMix  : BOOL := FALSE;
    previousAuto : BOOL := FALSE;

    edgeA    : BOOL;
    edgeB    : BOOL;
    edgeC    : BOOL;
    edgeD    : BOOL;
    edgeMix  : BOOL;
    edgeAuto : BOOL;

    manualA   : BOOL := FALSE;
    manualB   : BOOL := FALSE;
    manualC   : BOOL := FALSE;
    manualD   : BOOL := FALSE;
    manualMix : BOOL := FALSE;
END_VAR

(* Detect edges in every mode, including while emergency stop is active. *)
edgeA := valveAStart AND NOT previousA;
edgeB := valveBStart AND NOT previousB;
edgeC := valveCStart AND NOT previous