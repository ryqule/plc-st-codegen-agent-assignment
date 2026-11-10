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
    i       : DINT;
    n       : DINT;
    loCh    : DINT;
    loAv    : DINT;
    rawLo   : DINT;
    rawHi   : DINT;
    rawSpan : DINT;
    iValue  : DINT;
    raw     : INT;
    fRaw    : REAL;
    fSpan   : REAL;
    fLo     : REAL;
    fHi     : REAL;
END_VAR

(* Number of iterations, clamped to smallest array length and count *)
n := count;

IF (analogValues.UPPER_BOUND - analogValues.LOWER_BOUND + 1) < n THEN
    n := analogValues.UPPER_BOUND - analogValues.LOWER_BOUND + 1;
END_IF

IF (channels.UPPER_BOUND - channels.LOWER_BOUND + 1) < n THEN
    n := channels.UPPER_BOUND - channels.LOWER_BOUND + 1;
END_IF

IF n < 0 THEN
    n := 0;
END_IF

loCh := channels.LOWER_BOUND;
loAv := analogValues.LOWER_BOUND;

FOR i := 0 TO n - 1 DO
    (* Ordinal pairing begins at each array's own lower bound *)

    (* Disabled channel: status cleared, output preserved (P08-L1) *)
    IF NOT channels[loCh + i].enable THEN
        channels[loCh + i].retVal := 16#0000;

    (* Invalid measuringMode takes precedence (P08-L2) *)
    ELSIF (channels[loCh + i].measuringMode <> 0)
       AND (channels[loCh + i].measuringMode <> 1)
       AND (channels[loCh + i].measuringMode <> 2) THEN
        channels[loCh + i].retVal := 16#8001;

    (* Invalid range (P08-L3) *)
    ELSIF channels[loCh + i].hiLIM <= channels[loCh + i].loLIM THEN
        channels[loCh + i].retVal := 16#8002;

    ELSE
        raw  := analogValues[loAv + i];
        iValue := INT_TO_DINT(raw);

        CASE channels[loCh + i].measuringMode OF
            0:
                (* Non-temperature linear scaling (P08-L4) *)
                IF channels[loCh + i].bipolar THEN
                    rawLo := -27648;
                ELSE
                    rawLo := 0;
                END_IF
                rawHi   := 27648;
                rawSpan := rawHi - rawLo;

                fLo   := channels[loCh + i].loLIM;
                fHi   := channels[loCh + i].hiLIM;
                fSpan := fHi - fLo;
                fRaw  := DINT_TO_REAL(iValue - rawLo);

                channels[loCh + i].outputValue := fLo + (fRaw * fSpan) / DINT_TO_REAL(rawSpan);
                channels[loCh + i].retVal      :=