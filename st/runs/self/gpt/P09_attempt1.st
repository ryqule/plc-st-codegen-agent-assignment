```st
FUNCTION_BLOCK FB
VAR_INPUT
    cyclicExecution : BOOL;
    trigger         : BOOL;
    value           : LREAL;
    windowSize      : INT;
    reset           : BOOL;
END_VAR

VAR_OUTPUT
    average           : LREAL := 0.0;
    windowSizeReached : BOOL := FALSE;
    error             : BOOL := FALSE;
    status            : WORD := WORD#16#0000;
END_VAR

VAR
    history        : ARRAY[0..99] OF LREAL;
    historyCount   : INT := 0;
    nextWrite      : INT := 0;
    occupancy      : INT := 0;

    prevTrigger    : BOOL := FALSE;
    sampleAccepted : BOOL := FALSE;
    valid          : BOOL := FALSE;

    readIndex      : INT;
    i              : INT;
    total          : LREAL;
END_VAR

(* Validate independently of reset and sampling. *)
valid := (windowSize >= 1) AND (windowSize <= 100);
error := NOT valid;

IF valid THEN
    status := WORD#16#0000;
ELSE
    status := WORD#16#8200;
END_IF;