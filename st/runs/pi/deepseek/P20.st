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
    MotorForward   : BOOL;
    MotorReverse   : BOOL;
    kick           : BOOL;
    CompletionLight: BOOL;
    firingTemp     : REAL;
END_VAR

VAR
    (* Automatic sequence state machine *)
    AutoState      : INT := 0;
    (* 0 = idle / waiting for material at feed
       1 = moving feed -> wash
       2 = at wash, waiting washComplete
       3 = moving wash -> weight
       4 = at weight, waiting weightComplete
       5 = moving weight -> firing
       6 = at firing, waiting firingComplete
       7 = moving firing -> output
       8 = at output, product present *)

    (* Edge / pulse helpers *)
    kickPulse      : BOOL := FALSE;
    prevWeightComp : BOOL := FALSE;
    prevMode       : BOOL := FALSE;

    (* Qualified weight flag *)
    qualified      : BOOL;
    unqualified    : BOOL;
END_VAR

(* ------------------------------------------------------------------ *)
(* Weight qualification (endpoints inclusive)                          *)
(* ------------------------------------------------------------------ *)
qualified   := (weight >= 100.0) AND (weight <= 200.0);
unqualified := NOT qualified;

(* ------------------------------------------------------------------ *)
(* Mode change aborts an in-flight automatic sequence                  *)
(* ------------------------------------------------------------------ *)
IF Mode <> prevMode THEN
    AutoState := 0;
END_IF;
prevMode := Mode;

(* ------------------------------------------------------------------ *)
(* Default outputs                                                     *)
(* ------------------------------------------------------------------ *)
MotorForward    := FALSE;
MotorReverse    := FALSE;
kick            := FALSE;
CompletionLight := FALSE;

(* ------------------------------------------------------------------ *)
(* MANUAL MODE                                                         *)
(* ------------------------------------------------------------------ *)
IF NOT Mode THEN
    (* Interlocked manual jog: both pressed -> both off *)
    IF ForwardButton AND NOT ReverseButton THEN
        MotorForward := TRUE;
    ELSIF ReverseButton AND NOT ForwardButton THEN
        MotorReverse := TRUE;
    END_IF;
    (* Auto state reset while in manual *)
    AutoState := 0;
END_IF;

(* ------------------------------------------------------------------ *)
(* AUTOMATIC MODE                                                      *)
(* ------------------------------------------------------------------ *)
IF Mode THEN
    CASE AutoState OF
        0:  (* Idle: wait for material at feed station *)
            IF SensorFeed THEN
                AutoState := 1;
            END_IF;

        1:  (* Moving feed -> wash *)
            MotorForward := TRUE;
            IF SensorWash THEN
                AutoState := 2;
            END_IF;

        2:  (* At wash: motor stopped, wait washComplete *)
            IF washComplete THEN
                AutoState := 3;
            END_IF;

        3:  (* Moving wash -> weight *)
            MotorForward := TRUE;
            IF SensorWeight THEN
                AutoState := 4;
            END_IF;

        4:  (* At weight: motor stopped, wait weightComplete *)
            IF weightComplete AND NOT prevWeightComp THEN
                IF qualified THEN
                    (* Compute firing temperature: 100..200 -> 500..550 *)
                    firingTemp := 500