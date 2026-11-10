```st
FUNCTION_BLOCK FB_FlexibleProcessing
VAR_INPUT
    processLength     : USINT;                       (* 1..8, final active entry must be station 5 *)
    sensor1           : BOOL;                        (* sensor at station 1 *)
    sensor2           : BOOL;                        (* sensor at station 2 *)
    sensor3           : BOOL;                        (* sensor at station 3 *)
    sensor4           : BOOL;                        (* sensor at station 4 *)
    sensor5           : BOOL;                        (* sensor at station 5 *)
    station1Start     : BOOL;                        (* start button at station 1 *)
    station2Complete  : BOOL;                        (* processing complete at station 2 *)
    station3Complete  : BOOL;                        (* processing complete at station 3 *)
    station4Complete  : BOOL;                        (* processing complete at station 4 *)
    processSequence   : ARRAY[1..8] OF USINT;        (* processing sequence *)
END_VAR

VAR_OUTPUT
    conveyorLeft      : BOOL;                        (* conveyor turns left  = decreasing station number *)
    conveyorRight     : BOOL;                        (* conveyor turns right = increasing station number *)
END_VAR

VAR
    (* state machine *)
    state             : INT := 0;
    (* sequence index currently being executed (1-based) *)
    seqIndex          : USINT := 1;
    (* current station the product is at *)
    currentStation    : USINT := 1;
    (* target station for the current move *)
    targetStation     : USINT := 0;
    (* latched move request *)
    moveIssued        : BOOL := FALSE;
    (* done flag *)
    done              : BOOL := FALSE;
    (* validity *)
    seqValid          : BOOL := FALSE;
    (* edge detection *)
    startRising       : R_TRIG;
    (* helper *)
    i                 : USINT;
    tmpLen            : USINT;
END_VAR

VAR CONSTANT
    ST_IDLE           : INT := 0;
    ST_MOVE           : INT := 1;
    ST_WAIT_PROCESS   : INT := 2;
    ST_DONE           : INT := 3;
    ST_FAULT          : INT := 4;
END_VAR

(* ------------------------------------------------------------------ *)
(* Sequence validation: length 1..8, entries 2..4 valid, final = 5    *)
(* ------------------------------------------------------------------ *)
seqValid := FALSE;
tmpLen := processLength;
IF (tmpLen >= 1) AND (tmpLen <= 8) THEN
    IF processSequence[tmpLen] = 5 THEN
        seqValid := TRUE;
        FOR i := 1 TO tmpLen - 1 DO
            IF (processSequence[i] < 2) OR (processSequence[i] > 4) THEN
                seqValid := FALSE;
            END_IF;
        END_FOR;
    END_IF;
END_IF;

(* ------------------------------------------------------------------ *)
(* Edge detection on start button                                     *)
(* ------------------------------------------------------------------ *)
startRising(CLK := station1Start);

(* ------------------------------------------------------------------ *)
(* State machine                                                      *)
(* ------------------------------------------------------------------ *)
CASE state OF

    ST_IDLE:
        conveyorLeft  := FALSE;
        conveyorRight := FALSE;
        moveIssued    := FALSE;
        done          := FALSE;
        seqIndex      := 1;
        currentStation := 1;
        targetStation := 0;

        IF startRising.Q AND sensor1 AND seqValid THEN
            (* first element of sequence *)
            targetStation := processSequence[1];
            IF target