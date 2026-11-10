FUNCTION_BLOCK FB
VAR_INPUT
    enqueue : BOOL;
    dequeue : BOOL;
    reset : BOOL;
END_VAR

VAR_OUTPUT
    elementCount : DINT := 0;
    status : WORD := WORD#16#0000;
END_VAR

VAR_IN_OUT
    item : DINT;
    buffer : ARRAY[*] OF DINT;
END_VAR

VAR
    initialized : BOOL := FALSE;
    previousEnqueue : BOOL := FALSE;
    previousDequeue : BOOL := FALSE;
    enqueueEdge : BOOL;
    dequeueEdge : BOOL;

    lowerIndex : DINT;
    upperIndex : DINT;
    capacity : DINT;
    head : DINT;
    tail : DINT;
END_VAR

(* Caller contract:
   - buffer is nonempty; its length is representable as DINT.
   - The same buffer, with unchanged bounds, is used for this instance.
   - enqueue and dequeue are not requested simultaneously.
*)

lowerIndex := LOWER_BOUND(buffer, 1);
upperIndex := UPPER_BOUND(buffer, 1);
capacity := upperIndex - lowerIndex + 1;

IF NOT initialized THEN
    elementCount := 0;
    head := lowerIndex;
    tail := lowerIndex;
    initialized := TRUE;
END_IF;

(* Consume edges every invocation, including invocations during reset. *)
enqueueEdge := enqueue AND NOT previousEnqueue;
dequeueEdge := dequeue AND NOT previousDequeue;
previousEnqueue := enqueue;
previousDequeue := dequeue;

(* Status describes only this invocation. *)
status := WORD#16#0000;

IF reset THEN
    elementCount := 0;
    head := lowerIndex;
    tail := lowerIndex;

ELSIF enqueueEdge THEN
    IF elementCount = capacity THEN
        status := WORD#16#8002;
    ELSE
        buffer[tail] := item;

        IF tail = upperIndex THEN
            tail := lowerIndex;
        ELSE
            tail := tail + 1;
        END_IF;

        elementCount := elementCount + 1;
    END_IF;

ELSIF dequeueEdge THEN
    IF elementCount = 0 THEN
        status := WORD#16#8001;
    ELSE
        item := buffer[head];

        IF head = upperIndex THEN
            head := lowerIndex;
        ELSE
            head := head + 1;
        END_IF;

        elementCount := elementCount - 1;
    END_IF;
END_IF;

END_FUNCTION_BLOCK