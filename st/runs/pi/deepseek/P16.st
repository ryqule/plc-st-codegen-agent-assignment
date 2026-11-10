```st
FUNCTION_BLOCK P16_FlexibleProcessing
VAR_INPUT
    processLength     : USINT;
    sensor1           : BOOL;
    sensor2           : BOOL;
    sensor3           : BOOL;
    sensor4           : BOOL;
    sensor5           : BOOL;
    station1Start     : BOOL;
    station2Complete  : BOOL;
    station3Complete  : BOOL;
    station4Complete  : BOOL;
    processSequence   : ARRAY[1..8] OF USINT;
END_VAR

VAR_OUTPUT
    conveyorLeft      : BOOL;
    conveyorRight     : BOOL;
END_VAR

VAR
    (* State machine *)
    state             : INT := 0;
    seqIndex          : USINT := 1;
    targetStation     : USINT := 0;
    currentStation    : USINT := 0;
    done              : BOOL := FALSE;

    (* Edge detection *)
    startRising       : R_TRIG;
    completeRising2   : R_TRIG;
    completeRising3   : R_TRIG;
    completeRising4   : R_TRIG;

    (* Internal flags *)
    moveIssued        : BOOL := FALSE;
    lengthValid       : BOOL := FALSE;
    targetValid       : BOOL := FALSE;
    completeSignal    : BOOL := FALSE;
    targetSensor      : BOOL := FALSE;
    processingStationReached : BOOL := FALSE;
END_VAR

VAR CONSTANT
    ST_IDLE           : INT := 0;
    ST_MOVING         : INT := 1;
    ST_WAIT_COMPLETE  : INT := 2;
    ST_DONE           : INT := 3;
END_VAR

(* ------------------------------------------------------------------ *)
(* Edge detection                                                      *)
(* ------------------------------------------------------------------ *)
startRising(CLK := station1Start);
completeRising2(CLK := station2Complete);
completeRising3(CLK := station3Complete);
completeRising4(CLK := station4Complete);

(* ------------------------------------------------------------------ *)
(* Validate process length: 1..8, final active entry must be 5         *)
(* ------------------------------------------------------------------ *)
lengthValid := (processLength >= 1) AND (processLength <= 8)
               AND (processSequence[processLength] = 5);

(* ------------------------------------------------------------------ *)
(* Default outputs                                                     *)
(* ------------------------------------------------------------------ *)
conveyorLeft  := FALSE;
conveyorRight := FALSE;

(* ------------------------------------------------------------------ *)
(* State machine                                                       *)
(* ------------------------------------------------------------------ *)
CASE state OF

    ST_IDLE:
        done := FALSE;
        moveIssued := FALSE;
        seqIndex := 1;
        currentStation := 1;
        targetStation := 0;
        processingStationReached := FALSE;

        IF lengthValid AND startRising.Q AND sensor1 THEN
            targetStation := processSequence[seqIndex];
            targetValid := (targetStation >= 2) AND (targetStation <= 5);
            IF targetValid THEN
                state := ST_MOVING;
            END_IF;
        END_IF;

    ST_MOVING:
        (* Determine direction: left = decreasing, right = increasing *)
        IF targetStation > currentStation THEN
            conveyorRight := TRUE;
            conveyorLeft  := FALSE;
        ELSIF targetStation < currentStation THEN
            conveyorLeft  := TRUE;
            conveyorRight := FALSE;
        ELSE
            (* Already at target *)
            conveyorLeft  := FALSE;
            conveyorRight := FALSE;
        END_IF;

        moveIssued := TRUE;

        (* Evaluate target sensor *)
        CASE targetStation