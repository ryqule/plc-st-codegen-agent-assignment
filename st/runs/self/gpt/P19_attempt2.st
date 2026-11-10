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

    (* Modes: 0=none, 1=manual, 2=step, 3=cycle, 4=continuous. *)
    CurrentMode  : INT := 0;
    PreviousMode : INT := 0;
    ModeChanged  : BOOL := FALSE;

    (* Ordered actions:
       1=down, 2=grip, 3=up, 4=right,
       5=down, 6=release, 7=up, 8=left. *)
    StepNumber     : INT := 1;
    ActionActive   : BOOL := FALSE;
    ActionComplete : BOOL := FALSE;

    DownRequest    : BOOL;
    UpRequest      : BOOL;
    LeftRequest    : BOOL;
    RightRequest   : BOOL;
    GripRequest    : BOOL;
    ReleaseRequest : BOOL;
END_VAR

(*
    Specification limitation:
    Literal P19-L2 conflicts with P19-L1 during emergency stop, and
    with P19-L3 when opposing manual requests are simultaneously eligible.
    These formulas cannot all hold for unrestricted declared inputs.
    The explicit alternative below gives emergency stop precedence and
    inhibits both eligible requests in each opposing pair.

    Initial automatic position is top-left as stated in the task.
    No timers are needed: each action completes on its limit feedback.
    Mode changes reset the sequence. Emergency stop inhibits outputs and
    pauses sequence progression; it does not introduce an unspecified reset.
*)

(* Edge history is updated even while stopped, preventing a held Start
   from becoming a new command when emergency stop is cleared. *)
StartEdge := Start AND NOT PreviousStart;
PreviousStart := Start;

CurrentMode := 0;
IF ManualMode THEN
    CurrentMode := 1;
ELSIF SingleStepMode THEN