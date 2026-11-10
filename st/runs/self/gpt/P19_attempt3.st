```st
PROGRAM MechanicalArmControl
VAR_INPUT
    ManualMode         : BOOL;
    SingleStepMode     : BOOL;
    SingleCycleMode    : BOOL;
    ContinuousMode     : BOOL;
    EmergencyStop      : BOOL;
    Start              : BOOL;
    DownButton         : BOOL;
    UpButton           : BOOL;
    LeftButton         : BOOL;
    RightButton        : BOOL;
    GripButton         : BOOL;
    ReleaseButton      : BOOL;
    DownLimitSwitch    : BOOL;
    UpLimitSwitch      : BOOL;
    LeftLimitSwitch    : BOOL;
    RightLimitSwitch   : BOOL;
    GripLimitSwitch    : BOOL;
    ReleaseLimitSwitch : BOOL;
END_VAR

VAR_OUTPUT
    MoveDown        : BOOL;
    MoveUp          : BOOL;
    MoveLeft        : BOOL;
    MoveRight       : BOOL;
    ActivateGrip    : BOOL;
    ActivateRelease : BOOL;
END_VAR

VAR
    PreviousStart : BOOL := FALSE;
    StartEdge     : BOOL := FALSE;

    (* 0=none, 1=manual, 2=step, 3=cycle, 4=continuous *)
    CurrentMode  : INT := 0;
    PreviousMode : INT := 0;
    ModeChanged  : BOOL := FALSE;

    (* 1=down, 2=grip, 3=up, 4=right,
       5=down, 6=release, 7=up, 8=left *)
    StepNumber     : INT := 1;
    ActionActive   : BOOL := FALSE;
    ActionComplete : BOOL := FALSE;

    DownRequest    : BOOL := FALSE;
    UpRequest      : BOOL := FALSE;
    LeftRequest    : BOOL := FALSE;
    RightRequest   : BOOL := FALSE;
    GripRequest    : BOOL := FALSE;
    ReleaseRequest : BOOL := FALSE;
END_VAR

(*
    Literal P19-L2 conflicts with P19-L1 during emergency stop and
    with P19-L3 for simultaneous eligible opposing manual requests.
    Explicit alternative: emergency stop dominates, and simultaneous
    eligible opposing requests inhibit both outputs in that pair.

    Initial automatic position is top-left as specified.
    Actions complete using feedback, without timers.
    Mode changes stop and reset the automatic sequence.
    Emergency stop inhibits outputs and pauses sequence progression.
*)

StartEdge := Start AND NOT PreviousStart;
PreviousStart := Start;

CurrentMode := 0;
IF ManualMode THEN
    CurrentMode := 1;
ELSIF SingleStepMode THEN
    CurrentMode := 2;
ELSIF SingleCycleMode THEN
    CurrentMode := 3;
ELSIF ContinuousMode THEN
    CurrentMode := 4;
END_IF;

ModeChanged := CurrentMode <> PreviousMode;
PreviousMode := CurrentMode;

IF ModeChanged THEN
    StepNumber := 1;
    ActionActive := FALSE;
END_IF;

MoveDown := FALSE;
MoveUp := FALSE;
MoveLeft := FALSE;
MoveRight := FALSE;
ActivateGrip := FALSE;
ActivateRelease := FALSE;

DownRequest := FALSE;
UpRequest := FALSE;
LeftRequest := FALSE;
RightRequest := FALSE;
GripRequest := FALSE;
ReleaseRequest := FALSE;
ActionComplete := FALSE;

IF EmergencyStop THEN
    IF CurrentMode = 1 THEN
        DownRequest := DownButton AND