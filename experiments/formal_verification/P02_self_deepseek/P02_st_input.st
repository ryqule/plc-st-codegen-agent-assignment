FUNCTION_BLOCK FB_DualWordEdgeDetection
VAR_INPUT
    value : DWORD; // The input value to be checked for changes and edge triggering
END_VAR

VAR_OUTPUT
    hasChanged : BOOL; // True indicates that the input value has changed
    hasRisingEdges : BOOL; // True indicates that rising edges have occurred in the input value
    risingBits : DWORD; // Bit stream of rising edges
    noOfRisingBits : USINT; // Number of rising edges
    hasFallingEdges : BOOL; // True indicates that falling edges have occurred in the input value
    fallingBits : DWORD; // Bit stream of falling edges
    noOfFallingBits : USINT; // Number of falling edges
END_VAR

VAR
    prevValue : DWORD := 0; // Previous value, initialized to zero per assumption
END_VAR

// Compute edge masks
risingBits := value AND (NOT prevValue);
fallingBits := prevValue AND (NOT value);

// Change detection
hasChanged := (value <> prevValue);

// Edge presence flags
hasRisingEdges := (risingBits <> 0);
hasFallingEdges := (fallingBits <> 0);

// Count set bits (popcount) for each mask
noOfRisingBits := CountSetBits(risingBits);
noOfFallingBits := CountSetBits(fallingBits);

// Update previous value for next scan
prevValue := value;

END_FUNCTION_BLOCK

// Helper function: count set bits in a DWORD, result as USINT (0..32)
FUNCTION CountSetBits : USINT
VAR_INPUT
    x : DWORD;
END_VAR
VAR
    v : DWORD;
    c : USINT;
END_VAR

v := x;
c := 0;
WHILE v <> 0 DO
    v := v AND (v - 1); // clear lowest set bit
    c := c + 1;
END_WHILE;
CountSetBits := c;

END_FUNCTION