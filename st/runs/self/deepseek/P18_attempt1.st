```st
FUNCTION_BLOCK FB_FIFO
VAR_INPUT
    enqueue : BOOL;
    dequeue : BOOL;
    reset   : BOOL;
END_VAR

VAR_OUTPUT
    elementCount : DINT;
    status       : WORD;
END_VAR

VAR_IN_OUT
    item   : VARIANT;
    buffer : VARIANT;
END_VAR

VAR
    head        : DINT;
    tail        : DINT;
    capacity    : DINT;
    arrLen      : DINT;

    (* Edge histories persist across reset per stated assumption *)
    enqueuePrev : BOOL;
    dequeuePrev : BOOL;

    enqueueEdge : BOOL;
    dequeueEdge : BOOL;

    (* Variant helpers for indexed access *)
    vElem  : VARIANT;
    vFront : VARIANT;

    (* Scratch indices for VARIANT address operands *)
    idxHead : DINT;
    idxTail : DINT;

    i : DINT;
END_VAR

(* ------------------------------------------------------------------ *)
(* Derive capacity from caller-supplied buffer: actual array length   *)
(* ------------------------------------------------------------------ *)
arrLen := 0;
IF NOT __ISVALIDREF(buffer) THEN
    (* Cannot determine capacity without a valid buffer reference.
       Keep queue logically empty and non-writable. *)
    capacity := 0;
ELSE
    (* A 1-D array VARIANT supplies its upper bound; capacity = length *)
    capacity := buffer.udiUpperBound + 1; (* closest explicit alternative *)
END_IF
IF capacity < 0 THEN
    capacity := 0;
END_IF
arrLen := capacity;

(* ------------------------------------------------------------------ *)
(* Rising-edge detection (histories persist across reset)             *)
(* ------------------------------------------------------------------ *)
enqueueEdge := enqueue AND NOT enqueuePrev;
dequeueEdge := dequeue AND NOT dequeuePrev;
enqueuePrev := enqueue;
dequeuePrev := dequeue;

(* ------------------------------------------------------------------ *)
(* Default: no error in this invocation                               *)
(* ------------------------------------------------------------------ *)
status := 16#0000;

(* ------------------------------------------------------------------ *)
(* Reset dominates edges and operations                               *)
(* ------------------------------------------------------------------ *)
IF reset THEN
    head := 0;
    tail := 0;
    elementCount := 0;
    status := 16#0000;
    (* Stored buffer values need not be overwritten *)
ELSE
    (* Invariant: clamp/maintain count within 0..capacity *)
    IF elementCount < 0 THEN
        elementCount := 0;
    END_IF
    IF elementCount > capacity THEN
        elementCount := capacity;
    END_IF

    (* Caller contract: at most one request per invocation.
       If both edges are present, neither operation is performed. *)
    IF enqueueEdge AND NOT dequeueEdge THEN
        (* Enqueue *)
        IF elementCount >= capacity THEN
            (* Rejected: full; queue and item unchanged *)
            status := 16#8002;
        ELSE
            (* Append current item value at tail *)
            idxTail := tail;
            buffer[idxTail] := item;
            tail := (tail + 1) MOD capacity;
            elementCount := elementCount + 1;
            status := 16#0000;
        END_IF

    ELSIF dequeueEdge AND NOT enqueueEdge THEN
        (* Dequeue *)
        IF elementCount <= 0 THEN
            (* Rejected: empty; queue and item unchanged *)
            status := 16#8001;
        ELSE
            (* Remove front and write back to item *)
            idxHead := head;
            vFront := buffer[idxHead];
            item := vFront;
            head