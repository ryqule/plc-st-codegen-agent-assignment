```st
PROGRAM P11
VAR_INPUT
    Mode          : BOOL;
    ForwardButton : BOOL;
    ReverseButton : BOOL;
    SensorA       : BOOL;
    SensorB       : BOOL;
    SensorC       : BOOL;
    ButtonA       : BOOL;
    ButtonB       : BOOL;
    ButtonC       : BOOL;
END_VAR
VAR_OUTPUT
    MotorForward    : BOOL;
    MotorReverse    : BOOL;
    CompletionLight : BOOL;
END_VAR
VAR CONSTANT
    WAIT_A    : INT := 0;
    TRAVEL_AB : INT := 1;
    AT_B      : INT := 2;
    TRAVEL_BC : INT := 3;
    AT_C      : INT := 4;
    DONE      : INT := 5;
END_VAR
VAR
    stage           : INT := 0;
    complete        : BOOL := FALSE;
    PreviousMode    : BOOL := FALSE;
    PreviousButtonA : BOOL := FALSE;
    PreviousButtonB : BOOL := FALSE;
    PreviousButtonC : BOOL := FALSE;
    ModeChanged     : BOOL;
    ButtonAComplete : BOOL;
    ButtonBComplete : BOOL;
    ButtonCComplete : BOOL;
END_VAR

ButtonAComplete := ButtonA AND NOT PreviousButtonA;
ButtonBComplete := ButtonB AND NOT PreviousButtonB;
ButtonCComplete := ButtonC AND NOT PreviousButtonC;
ModeChanged := Mode <> PreviousMode;

MotorForward := FALSE;
MotorReverse := FALSE;
CompletionLight := FALSE;

IF ModeChanged THEN
    stage := WAIT_A;
    complete := FALSE;
END_IF;

IF NOT Mode THEN
    stage := WAIT_A;
    complete := FALSE;
    MotorForward := ForwardButton AND NOT ReverseButton;
    MotorReverse := ReverseButton AND NOT ForwardButton;

ELSIF NOT ModeChanged THEN
    CASE stage OF
        WAIT_A:
            IF SensorA AND ButtonAComplete THEN
                IF SensorB THEN
                    stage := AT_B;
                ELSE
                    stage := TRAVEL_AB;
                END_IF;
            END_IF;

        TRAVEL_AB:
            IF SensorB THEN
                stage := AT_B;
            END_IF;

        AT_B:
            IF ButtonBComplete THEN
                IF SensorC THEN
                    stage := AT_C;
                ELSE
                    stage := TRAVEL_BC;
                END_IF;
            END_IF;

        TRAVEL_BC:
            IF SensorC THEN
                stage := AT_C;
            END_IF;

        AT_C:
            IF SensorC AND ButtonCComplete THEN
                complete := TRUE;
                stage := DONE;
            END_IF;

        DONE:
            IF NOT SensorC THEN
                complete := FALSE;
                stage := WAIT_A;
            END_IF;

    ELSE
        stage := WAIT_A;
        complete := FALSE;
    END_CASE;

    MotorForward :=
        ((stage = TRAVEL_AB) AND NOT SensorB)
        OR ((stage = TRAVEL_BC) AND NOT SensorC);
    CompletionLight := complete AND SensorC;
END_IF;

PreviousMode := Mode;
PreviousButtonA := ButtonA;
PreviousButtonB := ButtonB;
PreviousButtonC := ButtonC;

(* Mapping:
   T1 / L1 / L2: mutually exclusive manual direction commands.
   T2: SensorA and rising ButtonA start travel to B.
   L4 / L5: waiting at B or C keeps forward output off.
   T3 / L6 / L7: completion lights only while SensorC is