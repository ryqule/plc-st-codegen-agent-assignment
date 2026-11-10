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

    lengthValid : BOOL;
    moveIssued : BOOL := FALSE;
    targetSensor : BOOL := FALSE;
    processingStationReached : BOOL := FALSE;
    completeSignal : BOOL := FALSE;
    done : BOOL := FALSE;
END_VAR

(* Outputs default to stopped on every scan. *)
conveyorLeft := FALSE;
conveyorRight := FALSE;