```st
PROGRAM PRG_ProductionLine
VAR
    (* Inputs *)
    Mode           : BOOL; (* 0 = manual, 1 = automatic *)
    ForwardButton  : BOOL;
    ReverseButton  : BOOL;
    SensorA        : BOOL;
    SensorB        : BOOL;
    SensorC        : BOOL;
    ButtonA        : BOOL;
    ButtonB        : BOOL;
    ButtonC        : BOOL;

    (* Outputs *)
    MotorForward   : BOOL;
    MotorReverse   : BOOL;
    CompletionLight: BOOL;

    (* Internal state *)
    stage          : INT;
    ButtonAComplete: BOOL;
    ButtonBComplete: BOOL;
    ButtonCComplete: BOOL;
    complete       : BOOL;

    (* Edge detection *)
    rtA            : R_TRIG;
    rtB            : R_TRIG;
    rtC            : R_TRIG;
    rtMode         : R_TRIG;
    rtSensorC      : R_TRIG;
    rtFwd          : R_TRIG;
    rtRev          : R_TRIG;

    (* Constants for stage values *)
    ST_IDLE_A      : INT := 0;
    ST_TRAVEL_AB   : INT := 1;
    ST_AT_B        : INT := 2;
    ST_TRAVEL_BC   : INT := 3;
    ST_AT_C        : INT := 4;
    ST_DONE        : INT := 5;
END_VAR

(* Edge detection blocks *)
rtA(CLK := ButtonA);
rtB(CLK := ButtonB);
rtC(CLK := ButtonC);
rtMode(CLK := Mode);
rtSensorC(CLK := SensorC);
rtFwd(CLK := ForwardButton);
rtRev(CLK := ReverseButton);

(* Default outputs *)
MotorForward    := FALSE;
MotorReverse    := FALSE;
CompletionLight := FALSE;

(* Mode change resets automatic sequence and cancels motion *)
IF rtMode.Q THEN
    stage           := ST_IDLE_A;
    ButtonAComplete := FALSE;
    ButtonBComplete := FALSE;
    ButtonCComplete := FALSE;
    complete        := FALSE;
END_IF

IF Mode THEN
    (* ================= AUTOMATIC MODE ================= *)
    (* Capture button confirmations as rising-edge events *)
    IF rtA.Q THEN
        ButtonAComplete := TRUE;
    END_IF;
    IF rtB.Q THEN
        ButtonBComplete := TRUE;
    END_IF;
    IF rtC.Q THEN
        ButtonCComplete := TRUE;
    END_IF;

    (* Sequential state machine A -> B -> C *)
    CASE stage OF
        ST_IDLE_A:
            (* Waiting at A; advance when product present and operator confirms *)
            IF SensorA AND ButtonAComplete AND NOT SensorB THEN
                stage := ST_TRAVEL_AB;
            END_IF;

        ST_TRAVEL_AB:
            (* Move product from A to B *)
            IF SensorB THEN
                stage := ST_AT_B;
            ELSE
                MotorForward := TRUE;
            END_IF;

        ST_AT_B:
            (* At B: stopped until ButtonB completion *)
            IF SensorC THEN
                stage := ST_AT_C;
            ELSIF ButtonBComplete THEN
                stage := ST_TRAVEL_BC;
            END_IF;

        ST_TRAVEL_BC:
            (* Move product from B to C *)
            IF SensorC THEN
                stage := ST_AT_C;
            ELSE
                MotorForward := TRUE;
            END_IF;