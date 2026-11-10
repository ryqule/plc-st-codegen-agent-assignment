```st
PROGRAM P19
VAR_INPUT
    ManualMode : BOOL;
    SingleStepMode : BOOL;
    SingleCycleMode : BOOL;
    ContinuousMode : BOOL;
    EmergencyStop : BOOL;
    Start : BOOL;
    DownButton : BOOL;
    UpButton : BOOL;
    LeftButton : BOOL;
    RightButton : BOOL;
    GripButton : BOOL;
    ReleaseButton : BOOL;
    DownLimitSwitch : BOOL;
    UpLimitSwitch : BOOL;
    LeftLimitSwitch : BOOL;
    RightLimitSwitch : BOOL;
    GripLimitSwitch : BOOL;
    ReleaseLimitSwitch : BOOL;
END_VAR
VAR_OUTPUT
    MoveDown : BOOL;
    MoveUp : BOOL;
    MoveLeft : BOOL;
    MoveRight : BOOL;
    ActivateGrip : BOOL;
    ActivateRelease : BOOL;
END_VAR
VAR
    Initialized : BOOL := FALSE;
    PreviousStart : BOOL := FALSE;
    StartEdge : BOOL;
    Mode : INT := 0;
    PreviousMode : INT := 0;
    ModeChanged : BOOL;

    (* Modes: 0=none, 1=manual, 2=step, 3=cycle, 4=continuous.
       Actions: 1=down, 2=grip, 3=up, 4=right,
                5=down, 6=release, 7=up, 8=left.
       No timers: all completion is determined by feedback.
       Emergency stop gates outputs and freezes sequence progress.
       Mode changes stop and reset the sequence. *)
    Action : INT := 1;
    Running : BOOL := FALSE;
    ActionDone : BOOL;
END_VAR

StartEdge := Start AND NOT PreviousStart;
PreviousStart := Start;

Mode := 0;
IF ManualMode THEN
    Mode := 1;
ELSIF SingleStepMode THEN
    Mode := 2;
ELSIF SingleCycleMode THEN
    Mode := 3;
ELSIF ContinuousMode THEN
    Mode := 4;
END_IF;

IF NOT Initialized THEN
    PreviousMode := Mode;
    Initialized := TRUE;
END_IF;

ModeChanged := Mode <> PreviousMode;
PreviousMode := Mode;

(* Every scan starts with all commands off. *)
MoveDown := FALSE;
MoveUp := FALSE;
MoveLeft := FALSE;
MoveRight := FALSE;
ActivateGrip := FALSE;
ActivateRelease := FALSE;
ActionDone := FALSE;

IF ModeChanged THEN
    Running := FALSE;
    Action := 1;
END_IF;

IF EmergencyStop AND NOT ModeChanged THEN
    IF Mode = 1 THEN
        (* Opposing requests are inhibited together.
           Limit gating and button release apply in the same scan. *)
        MoveDown := DownButton AND NOT DownLimitSwitch
                    AND NOT UpButton;
        MoveUp := UpButton AND NOT UpLimitSwitch
                  AND NOT DownButton;
        MoveLeft := LeftButton AND NOT LeftLimitSwitch
                    AND NOT RightButton;
        MoveRight := RightButton AND NOT RightLimit