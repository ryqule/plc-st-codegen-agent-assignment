```st
FUNCTION_BLOCK P19_MechanicalArm
VAR_INPUT
    ManualMode        : BOOL;
    SingleStepMode    : BOOL;
    SingleCycleMode   : BOOL;
    ContinuousMode    : BOOL;
    EmergencyStop     : BOOL; (* FALSE = emergency stop active *)
    Start             : BOOL;
    DownButton        : BOOL;
    UpButton          : BOOL;
    LeftButton        : BOOL;
    RightButton       : BOOL;
    GripButton        : BOOL;
    ReleaseButton     : BOOL;
    DownLimitSwitch   : BOOL;
    UpLimitSwitch     : BOOL;
    LeftLimitSwitch   : BOOL;
    RightLimitSwitch  : BOOL;
    GripLimitSwitch   : BOOL;
    ReleaseLimitSwitch: BOOL;
END_VAR

VAR_OUTPUT
    MoveDown       : BOOL;
    MoveUp         : BOOL;
    MoveLeft       : BOOL;
    MoveRight      : BOOL;
    ActivateGrip   : BOOL;
    ActivateRelease: BOOL;
END_VAR

VAR
    (* edge detection *)
    StartPrev      : BOOL;
    StartEdge      : BOOL;

    (* automatic sequence state machine *)
    AutoStep       : INT := 0;   (* 0 = idle / not started *)
    CycleStarted   : BOOL := FALSE;

    (* mode memory to detect mode changes *)
    ModePrev       : INT := 0;
    ModeNow        : INT := 0;

    (* internal step completion flags *)
    StepDone       : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Mode encoding: 1=Manual 2=SingleStep 3=SingleCycle 4=Continuous    *)
(* ------------------------------------------------------------------ *)
IF ManualMode THEN
    ModeNow := 1;
ELSIF SingleStepMode THEN
    ModeNow := 2;
ELSIF SingleCycleMode THEN
    ModeNow := 3;
ELSIF ContinuousMode THEN
    ModeNow := 4;
ELSE
    ModeNow := 0;
END_IF

(* Mode change stops and resets the automatic sequence *)
IF ModeNow <> ModePrev THEN
    AutoStep     := 0;
    CycleStarted := FALSE;
END_IF
ModePrev := ModeNow;

(* Start rising edge *)
StartEdge := Start AND NOT StartPrev;
StartPrev := Start;

(* ------------------------------------------------------------------ *)
(* Default: all outputs off (safety / interlock base)                 *)
(* ------------------------------------------------------------------ *)
MoveDown        := FALSE;
MoveUp          := FALSE;
MoveLeft        := FALSE;
MoveRight       := FALSE;
ActivateGrip    := FALSE;
ActivateRelease := FALSE;

(* ------------------------------------------------------------------ *)
(* Emergency stop dominates: FALSE => all outputs off                 *)
(* ------------------------------------------------------------------ *)
IF NOT EmergencyStop THEN
    AutoStep     := 0;
    CycleStarted := FALSE;
    (* outputs already FALSE *)
    RETURN;
END_IF

(* ------------------------------------------------------------------ *)
(* MANUAL MODE                                                        *)
(* ------------------------------------------------------------------ *)
IF ModeNow = 1 THEN
    AutoStep     := 0;
    CycleStarted := FALSE;

    MoveDown        := DownButton    AND NOT DownLimitSwitch;
    MoveUp          := UpButton      AND NOT UpLimitSwitch;
    MoveLeft        := LeftButton    AND NOT LeftLimitSwitch;
    MoveRight       := RightButton   AND NOT RightLimitSwitch;
    ActivateGrip    := GripButton    AND NOT GripLimitSwitch;
    ActivateRelease := ReleaseButton AND NOT ReleaseLimitSwitch;

    (* mutual exclusion safety: vertical / horizontal / grip-release *)
    IF MoveDown AND MoveUp THEN