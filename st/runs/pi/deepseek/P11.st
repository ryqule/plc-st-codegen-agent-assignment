```st
FUNCTION_BLOCK FB_ProductionLine
VAR_INPUT
    Mode           : BOOL; (* 0=manual, 1=automatic *)
    ForwardButton  : BOOL;
    ReverseButton  : BOOL;
    SensorA        : BOOL;
    SensorB        : BOOL;
    SensorC        : BOOL;
    ButtonA        : BOOL;
    ButtonB        : BOOL;
    ButtonC        : BOOL;
END_VAR

VAR_OUTPUT
    MotorForward   : BOOL;
    MotorReverse   : BOOL;
    CompletionLight: BOOL;
END_VAR

VAR
    (* rising-edge memories *)
    ButtonA_mem    : BOOL;
    ButtonB_mem    : BOOL;
    ButtonC_mem    : BOOL;
    Mode_mem       : BOOL;

    (* automatic step state machine *)
    stage          : INT;

    (* edge pulses *)
    ButtonA_pulse  : BOOL;
    ButtonB_pulse  : BOOL;
    ButtonC_pulse  : BOOL;

    (* internal step-complete flags *)
    complete       : BOOL;
END_VAR

VAR CONSTANT
    IDLE       : INT := 0;
    AT_A       : INT := 1;
    TRAVEL_AB  : INT := 2;
    AT_B       : INT := 3;
    TRAVEL_BC  : INT := 4;
    AT_C       : INT := 5;
    DONE       : INT := 6;
END_VAR

(* ---------- Edge detection ---------- *)
ButtonA_pulse := ButtonA AND NOT ButtonA_mem;
ButtonB_pulse := ButtonB AND NOT ButtonB_mem;
ButtonC_pulse := ButtonC AND NOT ButtonC_mem;
ButtonA_mem   := ButtonA;
ButtonB_mem   := ButtonB;
ButtonC_mem   := ButtonC;

(* ---------- Mode change cancels automatic motion and clears step state ---------- *)
IF Mode <> Mode_mem THEN
    stage    := IDLE;
    complete := FALSE;
END_IF
Mode_mem := Mode;

(* ---------- Outputs default ---------- *)
MotorForward    := FALSE;
MotorReverse    := FALSE;

(* ---------- Manual mode ---------- *)
IF NOT Mode THEN
    stage := IDLE;
    complete := FALSE;
    (* Forward/reverse interlock: if both pressed, neither runs *)
    IF ForwardButton AND NOT ReverseButton THEN
        MotorForward := TRUE;
    ELSIF ReverseButton AND NOT ForwardButton THEN
        MotorReverse := TRUE;
    END_IF
    (* completion light follows sensor C only *)
    CompletionLight := SensorC;

(* ---------- Automatic mode ---------- *)
ELSE
    (* State machine *)
    CASE stage OF
        IDLE:
            IF SensorA THEN
                stage := AT_A;
            END_IF

        AT_A:
            IF NOT SensorA THEN
                stage := IDLE;
            ELSIF ButtonA_pulse THEN
                stage := TRAVEL_AB;
            END_IF

        TRAVEL_AB:
            MotorForward := TRUE;
            IF SensorB THEN
                MotorForward := FALSE;
                stage := AT_B;
            END_IF

        AT_B:
            MotorForward := FALSE;
            IF NOT SensorB THEN
                stage := IDLE;
            ELSIF ButtonB_pulse THEN
                stage := TRAVEL_BC;
            END_IF

        TRAVEL_BC:
            MotorForward := TRUE;
            IF SensorC THEN
                MotorForward := FALSE;
                stage := AT_C;
            END_IF

        AT