PROGRAM P14
VAR_INPUT
    ipText : STRING(254);
END_VAR
VAR_OUTPUT
    ipValue : UDINT;
END_VAR
VAR
    textLength : INT;
    charIndex : INT;
    currentChar : BYTE;
    octetValue : UDINT;
    assembledValue : UDINT;
    octetCount : INT;
    hasDigits : BOOL;
    valid : BOOL;
    allOctetsInRange0to255 : BOOL;
END_VAR

(* Reparse the current input each scan; invalid input leaves output zero. *)
ipValue := UDINT#0;
textLength := LEN(ipText);
octetValue := UDINT#0;
assembledValue := UDINT#0;
octetCount := 0;
hasDigits := FALSE;
valid := textLength > 0;
allOctetsInRange0to255 := TRUE;

IF valid THEN
    FOR charIndex := 1 TO textLength DO
        currentChar := ipText[charIndex];

        IF (currentChar >= BYTE#16#30) AND
           (currentChar <= BYTE#16#39) THEN
            hasDigits := TRUE;
            octetValue := octetValue * UDINT#10
                          + (BYTE_TO_UDINT(currentChar) - UDINT#48);

            (* Reject before another multiplication can overflow. *)
            IF octetValue > UDINT#255 THEN
                allOctetsInRange0to255 := FALSE;
                valid := FALSE;
                EXIT;
            END_IF;

        ELSIF currentChar = BYTE#16#2E THEN
            (* Only three separators are permitted; segments cannot be empty. *)
            IF (NOT hasDigits) OR (octetCount >= 3) THEN
                valid := FALSE;
                EXIT;
            END_IF;

            assembledValue := SHL(assembledValue, 8) OR octetValue;
            octetCount := octetCount + 1;
            octetValue := UDINT#0;
            hasDigits := FALSE;

        ELSE
            valid := FALSE;
            EXIT;
        END_IF;
    END_FOR;

    IF valid THEN
        IF hasDigits AND (octetCount = 3) THEN
            assembledValue := SHL(assembledValue, 8) OR octetValue;
            octetCount := octetCount + 1;
        ELSE
            valid := FALSE;
        END_IF;
    END_IF;
END_IF;

IF valid AND (octetCount = 4) AND allOctetsInRange0to255 THEN
    ipValue := assembledValue;
END_IF;

END_PROGRAM