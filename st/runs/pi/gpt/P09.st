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
    status            : WORD := 16#0000;
END_VAR
VAR
    history        : ARRAY[1..100] OF LREAL;
    historyCount   : INT := 0;
    nextIndex      : INT := 1;
    occupancy      : INT := 0;
    prevTrigger    : BOOL := FALSE;
    sampleAccepted : BOOL := FALSE;
    valid          : BOOL := FALSE;
    sampleSum      : LREAL := 0.0;
    readIndex      : INT := 1;
    i              : INT;
END_VAR

(* Validate independently of reset and sampling. *)
valid := (windowSize >= 1) AND (windowSize <= 100);
error := NOT valid;
IF valid THEN
    status := 16#0000;
ELSE
    status := 16#8200;
END_IF;

(* Cyclic mode supersedes triggering; reset suppresses both. *)
sampleAccepted :=
    NOT reset AND
    (cyclicExecution OR (trigger AND NOT prevTrigger));
prevTrigger := trigger;

IF reset THEN
    historyCount := 0;
    nextIndex := 1;
    occupancy := 0;
    sampleSum := 0.0;
    average := 0.0;
    windowSizeReached := FALSE;

    FOR i := 1 TO 100 DO
        history[i] := 0.0;
    END_FOR;
ELSE
    (* Retain the latest 100 accepted samples. This also permits
       recalculation from retained history when windowSize changes. *)
    IF sampleAccepted THEN
        history[nextIndex] := value;

        nextIndex := nextIndex + 1;
        IF nextIndex > 100 THEN
            nextIndex := 1;
        END_IF;

        IF historyCount < 100 THEN
            historyCount := historyCount + 1;
        END_IF;
    END_IF;

    IF valid THEN
        occupancy := historyCount;
        IF occupancy > windowSize THEN
            occupancy := windowSize;
        END_IF;

        sampleSum := 0.0;
        readIndex := nextIndex;

        IF occupancy > 0 THEN
            FOR i := 1 TO occupancy DO
                readIndex := readIndex - 1;
                IF readIndex < 1 THEN
                    readIndex := 100;
                END_IF;
                sampleSum := sampleSum + history[readIndex];
            END_FOR;

            average := sampleSum / INT_TO_LREAL(occupancy);
        ELSE
            average := 0.0;