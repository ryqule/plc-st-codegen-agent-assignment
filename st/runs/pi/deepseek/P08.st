```st
FUNCTION_BLOCK FB_AnalogBatchProcessing
VAR_INPUT
    count : DINT;
END_VAR
VAR_IN_OUT
    analogValues : ARRAY[*] OF INT;
    channels     : ARRAY[*] OF ST_AnalogChannel;
END_VAR
VAR
    i        : DINT;
    n        : DINT;
    chIdx    : DINT;
    rawIdx   : DINT;
    rawMin   : REAL;
    rawMax   : REAL;
    raw      : REAL;
    span     : REAL;
    ch       : ST_AnalogChannel;
    mode     : INT;
    ret      : WORD;
    val      : REAL;
    doConv   : BOOL;
    rangeOK  : BOOL;
END_VAR

(* Determine the number of channels to process. count is contractually in
   bounds [0, MIN(analogValues.len, channels.len)], but clamp defensively. *)
n := count;
IF n < 0 THEN
    n := 0;
END_IF
IF n > channels.UPPER - channels.LOWER + 1 THEN
    n := channels.UPPER - channels.LOWER + 1;
END_IF
IF n > analogValues.UPPER - analogValues.LOWER + 1 THEN
    n := analogValues.UPPER - analogValues.LOWER + 1;
END_IF

FOR i := 0 TO n - 1 DO
    (* Ordinal pairing: each array indexed from its own lower bound. *)
    chIdx  := channels.LOWER + i;
    rawIdx := analogValues.LOWER + i;

    ch   := channels[chIdx];
    mode := ch.measuringMode;

    ret    := 16#0000;
    val    := ch.outputValue; (* preserved unless we convert *)
    doConv := FALSE;

    IF ch.enable THEN
        (* Invalid mode takes precedence over invalid range. *)
        IF (mode < 0) OR (mode > 2) THEN
            ret := 16#8001;
        ELSIF ch.hiLIM <= ch.loLIM THEN
            ret := 16#8002;
        ELSE
            raw := INT_TO_REAL(analogValues[rawIdx]);
            CASE mode OF
                0:
                    IF ch.bipolar THEN
                        rawMin := -27648.0;
                        rawMax := 27648.0;
                    ELSE
                        rawMin := 0.0;
                        rawMax := 27648.0;
                    END_IF
                    span := rawMax - rawMin;
                    IF span <> 0.0 THEN
                        val := ch.loLIM + (raw - rawMin) * (ch.hiLIM - ch.loLIM) / span;
                    END_IF
                    ret := 16#0000;
                    doConv := TRUE;
                1:
                    val := raw / 10.0;
                    ret := 16#0000;
                    doConv := TRUE;
                2:
                    val := raw / 100.0;
                    ret := 16#0000;
                    doConv := TRUE;
            END_CASE
        END_IF
    END_IF

    (* Write back only retVal and outputValue. *)
    channels[chIdx].retVal := ret;
    IF doConv THEN
        channels[chIdx].outputValue := val;
    END_IF
    (* If disabled or skipped: retVal=0 on disable (doConv FALSE, ret=0),
       outputValue left untouched. On invalid mode/range, retVal carries the