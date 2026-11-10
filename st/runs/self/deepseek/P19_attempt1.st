```st
FUNCTION_BLOCK FB_MechanicalArm
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
    (* Edge detection *)
    StartPrev      : BOOL;
    StartRising    : BOOL;

    (* Mode memory to detect mode changes *)
    ModePrev       : INT;
    ModeCur        : INT;

    (* Automatic sequence state machine *)
    AutoStep       : INT;
    CycleStarted   : BOOL;
    CycleRestart   : BOOL;

    (* Internal command requests from automatic sequence *)
    rMoveDown      : BOOL;
    rMoveUp        : BOOL;
    rMoveLeft      : BOOL;
    rMoveRight     : BOOL;
    rGrip          : BOOL;
    rRelease       : BOOL;

    (* Manual command requests *)
    mMoveDown      : BOOL;
    mMoveUp        : BOOL;
    mMoveLeft      : BOOL;
    mMoveRight     : BOOL;
    mGrip          : BOOL;
    mRelease       : BOOL;

    (* Safety *)
    SafetyOK       : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Mode encoding: 0=none, 1=manual, 2=single step, 3=single cycle, 4=continuous *)
IF ManualMode THEN
    ModeCur := 1;
ELSIF SingleStepMode THEN
    ModeCur := 2;
ELSIF SingleCycleMode THEN
    ModeCur := 3;
ELSIF ContinuousMode THEN
    ModeCur := 4;
ELSE
    ModeCur := 0;
END_IF

(* Start rising edge *)
StartRising := Start AND NOT StartPrev;
StartPrev   := Start;

(* Safety permissive: EmergencyStop FALSE means stop *)
SafetyOK := EmergencyStop;

(* ------------------------------------------------------------------ *)
(* Mode change resets the automatic sequence *)
IF ModeCur <> ModePrev THEN
    AutoStep     := 0;
    CycleStarted := FALSE;
    CycleRestart := FALSE;
END_IF
ModePrev := ModeCur;

(* ------------------------------------------------------------------ *)
(* Automatic sequence state machine (single step / single cycle / continuous) *)
(* Steps:
   0  : idle / waiting for start
   10 : move down
   20 : grip
   30 : move up
   40 : move right
   50 : move down
   60 : release
   70 : move up
   80 : move left
   90 : cycle complete
*)

rMoveDown  := FALSE;
rMoveUp    := FALSE;
rMoveLeft  := FALSE;
rMoveRight := FALSE;
rGrip      := FALSE;
rRelease