```st
PROGRAM ProductionControl
VAR_INPUT
    Mode : BOOL;
    ForwardButton : BOOL;
    ReverseButton : BOOL;
    SensorFeed : BOOL;
    SensorWash : BOOL;
    SensorWeight : BOOL;
    SensorFiring : BOOL;
    SensorOutput : BOOL;
    washComplete : BOOL;
    weightComplete : BOOL;
    weight : REAL;
    firingComplete : BOOL;
END_VAR

VAR_OUTPUT
    MotorForward : BOOL;
    MotorReverse : BOOL;
    kick : BOOL;
    CompletionLight : BOOL;
    firingTemp : REAL := 0.0;
END_VAR

VAR
    (* 0: idle
       10: moving to washing
       20: waiting for washing completion
       30: moving to weighing
       40: waiting for weighing completion
       50: moving to firing
       60: waiting for firing completion
       70: moving to output
       80: waiting for product removal
       90: waiting for rejected material removal *)
    stage : INT := 0;
    previousMode : BOOL := FALSE;
    modeChanged : BOOL;
    qualifiedWeight : BOOL;
    unqualifiedWeight : BOOL;
END_VAR

modeChanged := Mode <> previousMode;
previousMode := Mode;

MotorForward := FALSE;
MotorReverse := FALSE;
kick := FALSE;
CompletionLight := SensorOutput;

qualifiedWeight := (weight >= 100.0) AND (weight <= 200.0);
unqualifiedWeight := Mode AND NOT modeChanged
                     AND (stage = 40) AND NOT qualifiedWeight;

IF qualifiedWeight THEN
    firingTemp := 500.0 + (weight - 100.0) * 0.5;
END_IF;

IF modeChanged THEN
    (* Abort the automatic sequence on either mode transition. *)
    stage := 0;
END_IF;

IF NOT Mode THEN
    stage := 0;
    MotorForward := ForwardButton AND NOT ReverseButton;
    MotorReverse := ReverseButton AND NOT ForwardButton;

ELSIF NOT modeChanged THEN
    CASE stage OF
        0:
            IF SensorFeed THEN
                IF SensorWash THEN
                    stage := 20;
                ELSE
                    stage := 10;
                    MotorForward := TRUE;
                END_IF;
            END_IF;

        10:
            IF SensorWash THEN
                stage := 20;
            ELSE
                MotorForward := TRUE;
            END_IF;

        20:
            IF washComplete THEN
                stage := 30;
                MotorForward := NOT SensorWeight;
            END_IF;

        30:
            IF SensorWeight THEN
                stage := 40;
            ELSE
                MotorForward := TRUE;
            END_IF;

        40:
            IF weightComplete THEN
                IF qualifiedWeight THEN
                    stage := 50;
                    MotorForward := NOT SensorFiring;
                ELSE
                    kick := TRUE;
                    stage := 90;
                END_IF;
            END_IF;

        50:
            IF SensorF