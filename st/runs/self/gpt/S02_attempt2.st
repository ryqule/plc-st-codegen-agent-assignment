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
    (* States: 0 = idle, 1 = forward/retry, 2 = reverse. *)
    State             : USINT := 0;
    partActive        : BOOL := FALSE;
    ReverseElapsed    : TIME := T#0ms;
    reverse1sDone     : BOOL := FALSE;
    jamEvent          : BOOL := FALSE;
    validFaultClear   : BOOL := FALSE;

    PreviousStart     : BOOL := FALSE;
    PreviousEntry     : BOOL := FALSE;
    StartRise         : BOOL;
    EntryRise         : BOOL;
    MotionEnabled     : BOOL;
END_VAR

(* Edge histories are updated even while stopped or faulted. *)
StartRise := Start AND NOT PreviousStart;
EntryRise := PartAtEntry AND NOT PreviousEntry;
PreviousStart := Start;
PreviousEntry := PartAtEntry;

ConveyorForward := FALSE;
ConveyorReverse := FALSE;
reverse1sDone := FALSE;
jamEvent := FALSE;

validFaultClear := StartRise AND EStopOK AND NOT Jam;

(* Emergency stop dominates fault clearing and all motion. *)
IF NOT EStopOK THEN
    FaultLatched := TRUE;
ELSIF validFaultClear THEN
    FaultLatched := FALSE;
END_IF;

(* Exit terminates the part regardless of motion permissives. *)
IF PartAtExit THEN
    partActive := FALSE;
    RetryCount := 0;
    State := 0;
    ReverseElapsed := T#0ms;
END_IF;

MotionEnabled := Start AND NOT Stop AND EStopOK AND NOT FaultLatched;

IF MotionEnabled AND NOT PartAtExit THEN
    IF EntryRise AND NOT partActive THEN
        partActive := TRUE;
        RetryCount := 0;
        ReverseElapsed := T#0ms;
        State := 1;
    END_IF;

    IF partActive THEN
        (* Accumulate only an already-active reverse interval.
           Stop or removal of the run request pauses the interval. *)
        IF State = 2 THEN
            IF CycleTime > T#0ms THEN
                IF CycleTime >= (T#1s - ReverseElapsed) THEN
                    ReverseElapsed := T#1s;
                ELSE
                    ReverseElapsed := ReverseElapsed + CycleTime;
                END_IF;
            END_IF;

            IF ReverseElapsed >= T#1s THEN
                reverse1sDone := TRUE;
                ReverseElapsed := T#0ms;
                State := 1;
            END_IF;
        END_IF;

        CASE State