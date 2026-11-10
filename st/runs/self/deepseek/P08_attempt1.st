```st
FUNCTION_BLOCK FB_AnalogBatchProcessing
VAR_INPUT
    count : DINT; (* Number of channels to be converted *)
END_VAR
VAR_IN_OUT
    analogValues : ARRAY[*] OF INT;                 (* Variable-length analog array; read-only *)
    channels     : ARRAY[*] OF ST_AnalogChannel;     (* Channel records; only retVal/outputValue written *)
END_VAR
VAR
    i           : DINT;
    rawLo       : DINT;
    rawHi       : DINT;
    rawSpan     : DINT;
    iValue      : DINT;
    ch          : REFERENCE TO ST_AnalogChannel;
    raw         : INT;
    fRaw        : REAL;
    fSpan       : REAL;
    fLo         : REAL;
    fHi         : REAL;
    n           : DINT;
END_VAR

(* Determine number of iterations, clamped to the smaller array length.
   Contractually count is in bounds; clamping preserves safety. *)
n := count;
IF n > (analogValues.UPPER_BOUND - analogValues.LOWER_BOUND + 1) THEN
    n := analogValues.UPPER_BOUND - analogValues.LOWER_BOUND + 1;
END_IF
IF n > (channels.UPPER_BOUND - channels.LOWER_BOUND + 1) THEN
    n := channels.UPPER_BOUND - channels.LOWER_BOUND + 1;
END_IF
IF n < 0 THEN
    n := 0;
END_IF

FOR i := 0 TO n - 1 DO
    (* Ordinal pairing starts at each array's own lower bound *)
    ch  := channels[channels.LOWER_BOUND + i];
    raw := analogValues[analogValues.LOWER_BOUND + i];

    IF NOT ch.enable THEN
        (* Disabled: retVal = 0, outputValue unchanged (P08-L1) *)
        ch.retVal := 16#0000;
    ELSE
        (* Invalid measuringMode takes precedence over invalid range (P08-L2, P08-L3) *)
        IF (ch.measuringMode <> 0) AND (ch.measuringMode <> 1) AND (ch.measuringMode <> 2) THEN
            ch.retVal := 16#8001;
        ELSIF ch.hiLIM <= ch.loLIM THEN
            ch.retVal := 16#8002;
        ELSE
            CASE ch.measuringMode OF
                0:
                    (* Non-temperature linear scaling *)
                    IF ch.bipolar THEN
                        rawLo := -27648;
                        rawHi := 27648;
                    ELSE
                        rawLo := 0;
                        rawHi := 27648;
                    END_IF
                    rawSpan := rawHi - rawLo;
                    iValue  := INT_TO_DINT(raw);
                    fLo     := ch.loLIM;
                    fHi     := ch.hiLIM;
                    fSpan   := fHi - fLo;
                    fRaw    := DINT_TO_REAL(iValue - rawLo);
                    ch.outputValue := fLo + (fRaw * fSpan) / DINT_TO_REAL(rawSpan);
                    ch.retVal := 16#0000;

                1:
                    (* Standard temperature: raw / 10.0 *)
                    fRaw := INT_TO_REAL(raw);
                    ch.outputValue := fRaw / 10.0;
                    ch.retVal := 16#0000;

                2:
                    (* Climatic temperature: raw / 100.