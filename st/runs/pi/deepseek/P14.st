FUNCTION_BLOCK FB_IPv4Parse
VAR_INPUT
    ipText : STRING(254);
END_VAR
VAR_OUTPUT
    ipValue : UDINT;
END_VAR
VAR
    i         : INT;
    len       : INT;
    ch        : BYTE;
    octet     : UDINT;
    octetCnt  : INT;
    digitCnt  : INT;
    haveDigit : BOOL;
    valid     : BOOL;
    result    : UDINT;
    octets    : ARRAY[0..3] OF UDINT;
    k         : INT;
END_VAR

(* Clear outputs / working state each scan *)
ipValue := 0;
valid   := TRUE;
result  := 0;
octet   := 0;
octetCnt := 0;
digitCnt := 0;
haveDigit := FALSE;
FOR k := 0 TO 3 DO
    octets[k] := 0;
END_FOR;

(* Determine string length (bounded by 254) *)
len := 0;
FOR i := 0 TO 254 DO
    IF ipText[i] = '' THEN
        EXIT;
    END_IF;
    len := len + 1;
END_FOR;

(* Empty string is invalid *)
IF len = 0 THEN
    valid := FALSE;
END_IF;

(* Parse character by character *)
IF valid THEN
    FOR i := 0 TO len - 1 DO
        ch := ipText[i];
        IF (ch >= 16#30) AND (ch <= 16#39) THEN
            (* decimal digit *)
            IF digitCnt > 3 THEN
                valid := FALSE;
                EXIT;
            END_IF;
            octet := octet * 10 + TO_UDINT(ch - 16#30);
            digitCnt := digitCnt + 1;
            haveDigit := TRUE;
            IF octet > 255 THEN
                valid := FALSE;
                EXIT;
            END_IF;
        ELSIF ch = 16#2E THEN (* '.' *)
            IF NOT haveDigit THEN
                valid := FALSE;
                EXIT;
            END_IF;
            IF octetCnt >= 3 THEN
                valid := FALSE;
                EXIT;
            END_IF;
            octets[octetCnt] := octet;
            octetCnt := octetCnt + 1;
            octet := 0;
            digitCnt := 0;
            haveDigit := FALSE;
        ELSE
            (* any other character (whitespace, sign, letter, etc.) *)
            valid := FALSE;
            EXIT;
        END_IF;
    END_FOR;
END_IF;

(* Finalize last segment *)
IF valid THEN
    IF NOT haveDigit THEN
        valid := FALSE;
    ELSE
        octets[octetCnt] := octet;
        octetCnt := octetCnt + 1;
    END_IF;
END_IF;

(* Require exactly four segments *)
IF valid AND (octetCnt <> 4) THEN
    valid := FALSE;
END_IF;

(* Assemble network byte order *)
IF valid THEN
    result := SHL(octets[0], 24) OR SHL(octets[1], 16) OR SHL(octets[2], 8) OR octets[3];
    ipValue := result;
ELSE
    ipValue := 0;
END_IF;