TYPE ST_AnalogChannel :
STRUCT
    enable        : BOOL;
    hiLIM         : REAL;
    loLIM         : REAL;
    bipolar       : BOOL;
    measuringMode : INT;
    retVal        : WORD;
    outputValue   : REAL;
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_AnalogBatchProcessing
VAR_INPUT
    count : DINT;
END_VAR
VAR_IN_OUT
    analogValues : ARRAY[*] OF INT;
    channels     : ARRAY[*] OF ST_AnalogChannel;
END_VAR
VAR
    ordinal      : DINT;
    rawIndex     : DINT;
    channelIndex : DINT;
    rawLower     : DINT;
    channelLower : DINT;
    rawValue     : REAL;
    rawMin       : REAL;
    rawMax       : REAL;
END_VAR

rawLower := LOWER_BOUND(analogValues, 1);
channelLower := LOWER_BOUND(channels, 1);

IF count > 0 THEN
    FOR ordinal := 0 TO count - 1 DO
        rawIndex := rawLower + ordinal;
        channelIndex := channelLower + ordinal;

        channels[channelIndex].retVal := WORD#0;

        IF channels[channelIndex].enable THEN
            IF (channels[channelIndex].measuringMode < 0)
                OR (channels[channelIndex].measuringMode > 2) THEN
                channels[channelIndex].retVal := WORD#16#8001;

            ELSIF channels[channelIndex].hiLIM
                <= channels[channelIndex].loLIM THEN
                channels[channelIndex].retVal := WORD#16#8002;

            ELSE
                rawValue := INT_TO_REAL(analogValues[rawIndex]);

                CASE channels[channelIndex].measuringMode OF
                    0:
                        rawMax := REAL#27648.0;
                        IF channels[channelIndex].bipolar THEN
                            rawMin := REAL#-27648.0;
                        ELSE
                            rawMin := REAL#0.0;
                        END_IF;

                        channels[channelIndex].outputValue :=
                            channels[channelIndex].loLIM
                            + (rawValue - rawMin)
                            * (channels[channelIndex].hiLIM
                               - channels[channelIndex].loLIM)
                            / (rawMax - rawMin);

                    1:
                        channels[channelIndex].outputValue :=
                            rawValue / REAL#10.0;

                    2:
                        channels[channelIndex].outputValue :=
                            rawValue / REAL#100.0;
                END_CASE;
            END_IF;
        END_IF;
    END_FOR;
END_IF;
END_FUNCTION_BLOCK