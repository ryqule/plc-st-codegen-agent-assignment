FUNCTION_BLOCK FB
VAR_INPUT
    value : DWORD;
END_VAR
VAR_OUTPUT
    hasChanged : BOOL;
    hasRisingEdges : BOOL;
    risingBits : DWORD;
    noOfRisingBits : USINT;
    hasFallingEdges : BOOL;
    fallingBits : DWORD;
    noOfFallingBits : USINT;
END_VAR
VAR
    prevValue : DWORD := DWORD#0;
    bitMask : DWORD;
    bitIndex : INT;
END_VAR

(* Compare against the previous invocation's value, initially zero. *)
risingBits := value AND (NOT prevValue);
fallingBits := prevValue AND (NOT value);
hasChanged := value <> prevValue;

hasRisingEdges := risingBits <> DWORD#0;
hasFallingEdges := fallingBits <> DWORD#0;

(* Count each edge using unsigned 32-bit masks. *)
noOfRisingBits := USINT#0;
noOfFallingBits := USINT#0;

FOR bitIndex := 0 TO 31 DO
    bitMask := SHL(DWORD#1, bitIndex);

    IF (risingBits AND bitMask) <> DWORD#0 THEN
        noOfRisingBits := noOfRisingBits + USINT#1;
    END_IF;

    IF (fallingBits AND bitMask) <> DWORD#0 THEN
        noOfFallingBits := noOfFallingBits + USINT#1;
    END_IF;
END_FOR;

(* Store history only after all outputs have been calculated. *)
prevValue := value;

END_FUNCTION_BLOCK