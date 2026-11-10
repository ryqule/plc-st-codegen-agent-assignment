```st
PROGRAM S02
VAR_INPUT
    Start       : BOOL;
    Stop        : BOOL;
    EStopOK     : BOOL;
    PartAtEntry : BOOL;
    PartAtExit  : BOOL;
    Jam         : BOOL;
    CycleTime   : TIME;
END_VAR

VAR_OUTPUT
    ConveyorForward : BOOL := FALSE;
    ConveyorReverse : BOOL := FALSE;
    FaultLatched    : BOOL := FALSE;
    RetryCount      : USINT := 0;
END_VAR

VAR
    (* States: 0 = idle, 1 = forward, 2 = reverse. *)
    state             : USINT := 0;
    partActive        : BOOL := FALSE;
    previousStart     : BOOL := FALSE;
    previousEntry     : BOOL := FALSE;
    startRise         : BOOL;
    entryRise         : BOOL;
    validFaultClear   : BOOL;
    jamEvent          : BOOL;
    reverse1sDone     : BOOL := FALSE;
    reverseElapsed    : TIME := T#0ms;
    wasReversing      : BOOL;
    runPermitted      : BOOL;
END_VAR

(* Sample edges even while stopped or faulted. *)
startRise := Start AND NOT previousStart;
entryRise := PartAtEntry AND NOT previousEntry;
previousStart := Start;
previousEntry := PartAtEntry;

validFaultClear := startRise AND EStopOK AND NOT Jam;
jamEvent := FALSE;
reverse1sDone := FALSE;
wasReversing := ConveyorReverse;

(* Emergency stop has priority over fault clearing. *)
IF NOT EStopOK THEN
    FaultLatched := TRUE;
ELSIF validFaultClear THEN
    FaultLatched := FALSE;
END_IF;

ConveyorForward := FALSE;
ConveyorReverse := FALSE;

runPermitted := Start AND NOT Stop AND EStopOK AND NOT FaultLatched;

(* Exit terminates the cycle regardless of motion permissives. *)
IF PartAtExit THEN
    state := 0;
    partActive := FALSE;
    RetryCount := 0;
    reverseElapsed := T#0ms;

ELSIF runPermitted THEN
    IF (state = 0) AND entryRise THEN
        partActive := TRUE;
        RetryCount := 0;
        reverseElapsed := T#0ms;
        state := 1;
    END_IF;

    CASE state OF
        0:
            (* Idle: both outputs remain off. *)

        1:
            IF Jam THEN
                jamEvent :=