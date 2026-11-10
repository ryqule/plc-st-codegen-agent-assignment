FUNCTION_BLOCK FB_FIFOQueue
VAR_INPUT
    enqueue : BOOL;            (* rising edge requests one enqueue *)
    dequeue : BOOL;            (* rising edge requests one dequeue *)
    reset   : BOOL;            (* TRUE clears queue, dominates *)
END_VAR

VAR_OUTPUT
    elementCount : DINT;       (* number of valid elements, 0..capacity *)
    status       : WORD;       (* 16#0000 ok, 16#8001 empty, 16#8002 full *)
END_VAR

VAR_IN_OUT
    item   : VARIANT;          (* mutable scalar reference *)
    buffer : VARIANT;          (* reference to 1-D array storage *)
END_VAR

VAR
    _enqPrev : BOOL;           (* previous value of enqueue, persists across reset *)
    _deqPrev : BOOL;           (* previous value of dequeue, persists across reset *)
    _head    : DINT;           (* index of front element *)
    _tail    : DINT;           (* index where next element is appended *)
    _capacity: DINT;           (* cached array length, derived from buffer *)
END_VAR