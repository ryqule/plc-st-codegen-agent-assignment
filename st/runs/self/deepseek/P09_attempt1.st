FUNCTION_BLOCK FB_MovingAverage
VAR_INPUT
    cyclicExecution : BOOL;   (* TRUE: sample every scan, trigger ignored *)
    trigger         : BOOL;   (* rising-edge trigger when not cyclic *)
    value           : LREAL;  (* new data value *)
    windowSize      : INT;    (* 1..100 *)
    reset           : BOOL;   (* reset, highest priority *)
END_VAR

VAR_OUTPUT
    average          : LREAL;
    windowSizeReached: BOOL;
    error            : BOOL;
    status           : WORD;
END_VAR

VAR
    buffer      : ARRAY[0..99] OF LREAL;  (* ring buffer *)
    head        : INT;                     (* next write index *)
    occupancy   : INT;                     (* number of valid samples, 0..windowSize *)
    sum         : LREAL;                   (* running sum of valid samples *)
    prevTrigger : BOOL;                    (* previous trigger state *)
    validWindow : BOOL;
    sampleAccepted : BOOL;
    i           : INT;
END_VAR

(* ---- Window validation ---- *)
validWindow := (windowSize >= 1) AND (windowSize <= 100);

IF NOT validWindow THEN
    error  := TRUE;
    status := 16#8200;
ELSE
    error  := FALSE;
    status := 16#0000;
END_IF

(* ---- Reset has priority ---- *)
IF reset THEN
    FOR i := 0 TO 99 DO
        buffer[i] := 0.0;
    END_FOR;
    head        := 0;
    occupancy   := 0;
    sum         := 0.0;
    average     := 0.0;
    windowSizeReached := FALSE;
    sampleAccepted := FALSE;
    prevTrigger := trigger;
    RETURN;
END_IF

(* ---- Determine whether a sample is accepted this scan ---- *)
sampleAccepted := FALSE;
IF validWindow THEN
    IF cyclicExecution THEN
        sampleAccepted := TRUE;
    ELSE
        sampleAccepted := trigger AND NOT prevTrigger;
    END_IF
END_IF

(* ---- Accept sample: update ring buffer and running sum ---- *)
IF sampleAccepted THEN
    IF occupancy < windowSize THEN
        (* buffer not yet full: append *)
        buffer[head] := value;
        sum := sum + value;
        occupancy := occupancy + 1;
        head := (head + 1) MOD windowSize;
    ELSE
        (* buffer full: evict oldest at head, insert new *)
        sum := sum - buffer[head] + value;
        buffer[head] := value;
        head := (head + 1) MOD windowSize;
    END_IF
END_IF

(* ---- Compute average ---- *)
IF occupancy > 0 THEN
    average := sum / INT_TO_LREAL(occupancy);
ELSE
    average := 0.0;
END_IF

(* ---- Window reached flag ---- *)
windowSizeReached := validWindow AND (occupancy = windowSize);

(* ---- Remember trigger for edge detection ---- *)
prevTrigger := trigger;

END_FUNCTION_BLOCK