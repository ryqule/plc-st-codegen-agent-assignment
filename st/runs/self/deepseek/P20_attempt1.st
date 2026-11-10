```st
FUNCTION_BLOCK P20_ProductionControl
VAR_INPUT
    Mode           : BOOL;   (* 0 = manual, 1 = automatic *)
    ForwardButton  : BOOL;
    ReverseButton  : BOOL;
    SensorFeed     : BOOL;
    SensorWash     : BOOL;
    SensorWeight   : BOOL;
    SensorFiring   : BOOL;
    SensorOutput   : BOOL;
    washComplete   : BOOL;
    weightComplete : BOOL;
    weight         : REAL;
    firingComplete : BOOL;
END_VAR

VAR_OUTPUT
    MotorForward    : BOOL;
    MotorReverse    : BOOL;
    kick            : BOOL;
    CompletionLight : BOOL;
    firingTemp      : REAL;
END_VAR

VAR
    (* Automatic sequence state machine *)
    AutoState : INT := 0;
    (* 0 = idle / waiting for material at feed
       1 = moving feed -> wash
       2 = at wash, waiting washComplete
       3 = moving wash -> weight
       4 = at weight, waiting weightComplete
       5 = moving weight -> firing
       6 = at firing, waiting firingComplete
       7 = moving firing -> output
       8 = at output (complete) *)

    (* Edge detection for one-scan kick pulse *)
    kickPulse : BOOL := FALSE;

    (* Internal computed values *)
    qualified : BOOL;
    tempCalc  : REAL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Weight qualification and temperature calculation (invariants)       *)
(* Qualified range includes endpoints: 100 <= weight <= 200            *)
(* firingTemp = 500 + (weight - 100) * 0.5                             *)
(* ------------------------------------------------------------------ *)
qualified := (weight >= 100.0) AND (weight <= 200.0);

IF qualified THEN
    tempCalc := 500.0 + (weight - 100.0) * 0.5;
ELSE
    tempCalc := 0.0;
END_IF

(* ------------------------------------------------------------------ *)
(* Mode change aborts an in-flight automatic sequence                  *)
(* ------------------------------------------------------------------ *)
IF NOT Mode THEN
    AutoState := 0;
END_IF

(* ------------------------------------------------------------------ *)
(* Default outputs each scan                                           *)
(* ------------------------------------------------------------------ *)
MotorForward    := FALSE;
MotorReverse    := FALSE;
kick            := FALSE;
CompletionLight := FALSE;

(* ------------------------------------------------------------------ *)
(* MANUAL MODE                                                         *)
(* Forward and reverse interlocked; both pressed -> both off           *)
(* ------------------------------------------------------------------ *)
IF NOT Mode THEN
    IF ForwardButton AND NOT ReverseButton THEN
        MotorForward := TRUE;
    ELSIF ReverseButton AND NOT ForwardButton THEN
        MotorReverse := TRUE;
    ELSE
        (* both pressed or neither pressed: no motion *)
        MotorForward := FALSE;
        MotorReverse := FALSE;
    END_IF
END_IF

(* ------------------------------------------------------------------ *)
(* AUTOMATIC MODE                                                      *)
(* ------------------------------------------------------------------ *)
IF Mode THEN
    CASE AutoState OF
        0: (* Idle: wait for material at feed station *)
            IF SensorFeed THEN
                AutoState := 1;
            END_IF

        1: (* Moving feed -> wash *)
            MotorForward := TRUE;
            IF SensorWash THEN
                MotorForward := FALSE;
                AutoState := 2;
            END_IF

        2: (* At wash: motor stopped, wait washComplete *)
            MotorForward := FALSE;
            MotorReverse := FALSE;
            IF washComplete THEN
                AutoState := 3;
            END_IF

        3: (* Moving wash -> weight *)
            MotorForward