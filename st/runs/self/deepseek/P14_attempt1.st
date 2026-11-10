```st
FUNCTION_BLOCK P14_IPv4Parse
VAR_INPUT
    ipText  : STRING(254);
END_VAR
VAR_OUTPUT
    ipValue : UDINT;
END_VAR
VAR
    i           : INT;              // index into ipText
    octetCount  : INT;              // number of completed/active octets
    segValue    : UINT;             // accumulated value of current octet
    segDigits   : INT;              // digit count in current octet
    valid       : BOOL;             // running validity
    acc         : UDINT;            // assembled address accumulator
    ch          : BYTE;             // current character
    len         : INT;              // string length
    seeNul      : BOOL;             // terminator reached
END_VAR

// ------------------------------------------------------------------
// Parse a bounded dotted-decimal IPv4 string.
// Rules:
//   - exactly four nonempty decimal-digit segments separated by '.'
//   - each segment value 0..255
//   - leading zeros accepted, whitespace/signs rejected
//   - result in network byte order, 0 for invalid (and for 0.0.0.0)
// ------------------------------------------------------------------

// Initialise
ipValue    := 0;
valid      := TRUE;
acc        := 0;
segValue   := 0;
segDigits  := 0;
octetCount := 0;
i          := 0;
seeNul     := FALSE;

// Determine string length (scan for NUL within capacity)
// CODESYS: STRING is NUL-terminated; LEN() gives logical length.
len := LEN(ipText);

// Empty string is invalid
IF len = 0 THEN
    valid := FALSE;
END_IF;

// Walk the string character by character
WHILE valid AND (i < len) DO
    // Read character at position i (1-based indexing in CODESYS STRING helpers)
    ch := STRING_TO_BYTE_AT(ipText, i);

    IF (ch >= 16#30) AND (ch <= 16#39) THEN
        // Decimal digit
        IF segDigits > 9 THEN
            // Excessively long segment - definitely out of range
            valid := FALSE;
        ELSE
            segValue  := segValue * 10 + TO_UINT(ch - 16#30);
            segDigits := segDigits + 1;
            // Early range check to avoid overflow / invalid
            IF segValue > 255 THEN
                valid := FALSE;
            END_IF;
        END_IF;

    ELSIF ch = 16#2E THEN
        // Period: must end a nonempty, in-range segment
        IF segDigits = 0 THEN
            valid := FALSE;          // empty segment (e.g. "1..2")
        ELSE
            octetCount := octetCount + 1;
            IF octetCount > 4 THEN
                valid := FALSE;
            ELSE
                // Shift accumulator left 8 bits and insert octet
                acc := SHL(acc, 8) OR TO_UDINT(segValue);
            END_IF;
            // Reset for next octet
            segValue  := 0;
            segDigits := 0;
        END_IF;

    ELSE
        // Any other character (whitespace, sign, letter, etc.) is invalid
        valid := FALSE;
    END_IF;

    i := i + 1;
END_WHILE;

// Finalise: a valid string must end with