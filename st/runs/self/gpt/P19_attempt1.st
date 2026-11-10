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
    StartEdge     : BOOL;

    (* Mode: 0=none, 1=manual, 2=step, 3=cycle, 4=continuous. *)
    CurrentMode  : INT :=