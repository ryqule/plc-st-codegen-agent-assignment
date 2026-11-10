```st
PROGRAM P16
VAR_INPUT
    processLength : USINT;
    sensor1 : BOOL;
    sensor2 : BOOL;
    sensor3 : BOOL;
    sensor4 : BOOL;
    sensor5 : BOOL;
    station1Start : BOOL;
    station2Complete : BOOL;
    station3Complete : BOOL;
    station4Complete : BOOL;
    processSequence : ARRAY[1..8] OF USINT;
END_VAR
VAR_OUTPUT
    conveyorLeft : BOOL;
    conveyorRight : BOOL;
END_VAR
VAR
    (* States: 0 = idle, 1 = moving, 2 = processing, 3 = done. *)
    state : USINT := 0;
    currentStation : USINT := 1;
    targetStation : USINT := 1;
    sequenceIndex : USINT := 0;
    validLength : BOOL;

    (* Named specification predicates; moveIssued is a one-scan pulse. *)
    moveIssued : BOOL := FALSE;
    targetSensor : BOOL := FALSE;
    processingStationReached : BOOL := FALSE;
    completeSignal : BOOL := FALSE;
    done : BOOL := FALSE;
END_VAR

conveyorLeft := FALSE;
conveyorRight := FALSE;
moveIssued := FALSE;
validLength := (processLength >= 1) AND (processLength <= 8);

(* Output-station detection dominates all routing, including invalid lengths.
   There is no reset input; completion remains latched. *)
IF sensor5 THEN
    currentStation := 5;
    targetStation := 5;
    state := 3;
END_IF;

IF validLength AND (state <> 3) THEN
    CASE state OF
        0:
            IF sensor1 AND station1Start THEN
                currentStation := 1;
                sequenceIndex := 1;
                targetStation := processSequence[sequenceIndex];
                moveIssued := TRUE;
                state := 1;
            END_IF;

        2:
            CASE currentStation OF
                2: completeSignal := station2Complete;
                3: completeSignal := station3Complete;
                4: completeSignal := station4Complete;
            ELSE
                completeSignal := FALSE;
            END_CASE;

            IF completeSignal AND (sequenceIndex < processLength) THEN
                sequenceIndex := sequenceIndex + 1;
                targetStation := processSequence[sequenceIndex];
                moveIssued := TRUE;
                state := 1;
            END_IF;
    END_CASE;
END_IF;

(* Select only the destination sensor, not intermediate station sensors. *)
CASE targetStation OF
    1: targetSensor := sensor1;
    2: targetSensor := sensor2;
    3: targetSensor := sensor3;
    4: targetSensor := sensor4;
    5: targetSensor := sensor5;
ELSE
    targetSensor := FALSE;
END_CASE;

IF validLength AND (state = 1) THEN
    IF targetSensor THEN
        currentStation := targetStation;
        IF targetStation = 5 THEN
            state := 3;
        ELSE