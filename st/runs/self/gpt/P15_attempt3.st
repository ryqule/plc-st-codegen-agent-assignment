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

(* Track button edges continuously, including during emergency stop. *)
edgeA := valveAStart AND NOT previousA;
edgeB := valveBStart AND NOT previousB;
edgeC := valveCStart AND NOT previousC;
edgeD := valveDStart AND NOT previousD;
edgeMix := mixMotorStart AND NOT previousMix;
edgeAuto := autoStart AND NOT previousAuto;

previousA := valveAStart;
previousB := valveBStart;
previousC := valveCStart;
previousD := valveDStart;
previousMix := mixMotorStart;
previousAuto := autoStart;

(* Apply the transition selected in the preceding scan. *)
step := nextStep;

IF opeMode THEN
    IF edgeAuto AND ((step = IDLE) OR (step = DISCHARGE)) THEN
        step := FILL_A;
    END_IF;

    nextStep := step;

    CASE step OF
        IDLE:
            nextStep := IDLE;

        FILL_A:
            IF levelSensor >= 50 THEN
                nextStep := FILL_B;
            END_IF;

        FILL_B:
            IF levelSensor >= 80 THEN
                IF processMode THEN
                    nextStep := FILL_C;
                ELSE
                    nextStep := MIX;
                END_IF;
            END_IF;

        FILL_C:
            IF levelSensor >= 100 THEN
                nextStep := MIX;
            END_IF;

        MIX:
            IF