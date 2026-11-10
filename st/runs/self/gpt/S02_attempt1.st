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
PreviousStart :=