FUNCTION_BLOCK FB_DualWordEdgeDetection
VAR_INPUT
    value : DWORD; // The input value to be checked for changes and edge triggering
END_VAR

VAR_OUTPUT
    hasChanged      : BOOL;  // True indicates that the input value has changed
    hasRisingEdges  : BOOL;  // True indicates that rising edges have occurred
    risingBits      : DWORD; // Bit stream of rising edges
    noOfRisingBits  : USINT; // Number of rising edges
    hasFallingEdges : BOOL;  // True indicates that falling edges have occurred
    fallingBits     : DWORD; // Bit stream of falling edges
    noOfFallingBits : USINT; // Number of falling edges
END_VAR

VAR
    prevValue : DWORD := 16#00000000; // Previous value, initializes to zero
    i         : INT;
    tmpRise   : USINT;
    tmpFall   : USINT;
END_VAR

// Rising edges: bits that are 1 now and were 0 previously
risingBits := value AND (NOT prevValue);

// Falling edges: bits that were 1 previously and are 0 now
fallingBits := prevValue AND (NOT value);

// Change detection
hasChanged := (value <> prevValue);

// Edge presence flags
hasRisingEdges  := (risingBits <> 16#00000000);
hasFallingEdges := (fallingBits <> 16#00000000);

// Popcount for risingBits
tmpRise := 0;
FOR i := 0 TO 31 DO
    IF ((risingBits SHR i) AND 16#00000001) <> 16#00000000 THEN
        tmpRise := tmpRise + 1;
    END_IF;
END_FOR;
noOfRisingBits := tmpRise;

// Popcount for fallingBits
tmpFall := 0;
FOR i := 0 TO 31 DO
    IF ((fallingBits SHR i) AND 16#00000001) <> 16#00000000 THEN
        tmpFall := tmpFall + 1;
    END_IF;
END_FOR;
noOfFallingBits := tmpFall;

// Update previous value for next scan
prevValue := value;

END_FUNCTION_BLOCK