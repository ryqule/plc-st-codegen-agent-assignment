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
    stage : INT := 0;
    complete : BOOL := FALSE;

    PreviousMode    : BOOL := FALSE;
    PreviousButtonA : BOOL := FALSE;
    PreviousButtonB : BOOL := FALSE;
    PreviousButtonC : BOOL := FALSE;

    ModeChanged     : BOOL;
    ButtonAComplete : BOOL;
    ButtonBComplete : BOOL;
    ButtonCComplete : BOOL;
END_VAR

(*
    Confirmations are rising-edge events.
    Mode changes cancel automatic motion and clear sequence state.
    No timers or reset input are specified.

    Specification conflict:
    P11-L3 requires forward motion with SensorB FALSE to occur