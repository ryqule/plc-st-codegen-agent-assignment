Standard CODESYS ST does not provide the dataset’s `VARIANT` interface with runtime array-bound and element-type introspection. Therefore, an exact-interface implementation is not representable under the specified profile without additional runtime support.

The closest explicit alternative below preserves all parameter names, uses `DINT` elements, and derives capacity from a caller-supplied variable-length array. **Only `item` and `buffer` have changed types.** Edge histories are updated even during reset, as required.

```st
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

    lowerBound : DINT;
    capacity : DINT;

    (* Zero-based offsets within the caller's array. *)
    head : DINT := 0;
    tail : DINT := 0;
END_VAR

lowerBound := LOWER_BOUND(buffer, 1);
capacity := UPPER_BOUND(buffer, 1) - lowerBound + 1;

IF NOT initialized THEN
    elementCount := 0;
    head := 0;
    tail := 0;
    initialized := TRUE;