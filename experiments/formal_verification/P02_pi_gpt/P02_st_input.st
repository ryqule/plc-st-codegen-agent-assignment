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

(* Compare with the value saved from the previous invocation.
   On the first invocation, prevValue is zero. *)
risingBits := value AND (NOT prevValue);
fallingBits := prevValue AND (NOT value);
hasChanged := value <> prevValue;

hasRisingEdges := risingBits <> DWORD#0;
hasFallingEdges := fallingBits <> DWORD#0;

noOfRisingBits := USINT#0;
noOfFallingBits := USINT#0;

(* Count all 32 bits using an unsigned DWORD mask. *)
FOR bitIndex := 0 TO 31 DO
    bitMask := SHL(DWORD#1, bitIndex);

    IF (risingBits AND bitMask) <> DWORD#0 THEN
        noOfRisingBits := noOfRisingBits + USINT#1;
    END_IF;

    IF (fallingBits AND bitMask) <> DWORD#0 THEN
        noOfFallingBits := noOfFallingBits + USINT#1;
    END_IF;
END_FOR;

(* Save only after all comparisons and counts are complete. *)
prevValue := value;
END_FUNCTION_BLOCK