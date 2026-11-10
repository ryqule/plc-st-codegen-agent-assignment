PROGRAM P02RuntimeTest
VAR_OUTPUT
    test_done : BOOL := FALSE;
    passed : UINT := 0;
    failed : UINT := 0;
    first_failed_case : UINT := 0;
    case_pass : ARRAY[1..5] OF BOOL;
    actual_hasChanged : ARRAY[1..5] OF BOOL;
    actual_hasRisingEdges : ARRAY[1..5] OF BOOL;
    actual_risingBits : ARRAY[1..5] OF DWORD;
    actual_noOfRisingBits : ARRAY[1..5] OF USINT;
    actual_hasFallingEdges : ARRAY[1..5] OF BOOL;
    actual_fallingBits : ARRAY[1..5] OF DWORD;
    actual_noOfFallingBits : ARRAY[1..5] OF USINT;
END_VAR
VAR
    scan_no : UINT := 0;
    t1 : FB_DualWordEdgeDetection;
    t2 : FB_DualWordEdgeDetection;
    t3 : FB_DualWordEdgeDetection;
    b1 : FB_DualWordEdgeDetection;
    b2 : FB_DualWordEdgeDetection;
END_VAR

IF NOT test_done THEN
    scan_no := scan_no + 1;
    CASE scan_no OF
        1:
            t1(value := DWORD#16#00000000);
            actual_hasChanged[1] := t1.hasChanged;
            actual_hasRisingEdges[1] := t1.hasRisingEdges;
            actual_risingBits[1] := t1.risingBits;
            actual_noOfRisingBits[1] := t1.noOfRisingBits;
            actual_hasFallingEdges[1] := t1.hasFallingEdges;
            actual_fallingBits[1] := t1.fallingBits;
            actual_noOfFallingBits[1] := t1.noOfFallingBits;
            case_pass[1] := NOT t1.hasChanged AND NOT t1.hasRisingEdges AND
                             t1.risingBits = DWORD#16#00000000 AND t1.noOfRisingBits = USINT#0 AND
                             NOT t1.hasFallingEdges AND t1.fallingBits = DWORD#16#00000000 AND
                             t1.noOfFallingBits = USINT#0;
            IF case_pass[1] THEN
                passed := passed + 1;
            ELSE
                failed := failed + 1;
                IF first_failed_case = 0 THEN first_failed_case := 1; END_IF;
            END_IF;

            t2(value := DWORD#16#0000000F);
            t3(value := DWORD#16#00000015);

            b1(value := DWORD#16#FFFFFFFF);
            actual_hasChanged[4] := b1.hasChanged;
            actual_hasRisingEdges[4] := b1.hasRisingEdges;
            actual_risingBits[4] := b1.risingBits;
            actual_noOfRisingBits[4] := b1.noOfRisingBits;
            actual_hasFallingEdges[4] := b1.hasFallingEdges;
            actual_fallingBits[4] := b1.fallingBits;
            actual_noOfFallingBits[4] := b1.noOfFallingBits;
            case_pass[4] := b1.hasChanged AND b1.hasRisingEdges AND
                             b1.risingBits = DWORD#16#FFFFFFFF AND b1.noOfRisingBits = USINT#32 AND
                             NOT b1.hasFallingEdges AND b1.fallingBits = DWORD#16#00000000 AND
                             b1.noOfFallingBits = USINT#0;
            IF case_pass[4] THEN
                passed := passed + 1;
            ELSE
                failed := failed + 1;
                IF first_failed_case = 0 THEN first_failed_case := 4; END_IF;
            END_IF;

            b2(value := DWORD#16#FFFFFFFF);

        2:
            t2(value := DWORD#16#00000013);
            actual_hasChanged[2] := t2.hasChanged;
            actual_hasRisingEdges[2] := t2.hasRisingEdges;
            actual_risingBits[2] := t2.risingBits;
            actual_noOfRisingBits[2] := t2.noOfRisingBits;
            actual_hasFallingEdges[2] := t2.hasFallingEdges;
            actual_fallingBits[2] := t2.fallingBits;
            actual_noOfFallingBits[2] := t2.noOfFallingBits;
            case_pass[2] := t2.hasChanged AND t2.hasRisingEdges AND
                             t2.risingBits = DWORD#16#00000010 AND t2.noOfRisingBits = USINT#1 AND
                             t2.hasFallingEdges AND t2.fallingBits = DWORD#16#0000000C AND
                             t2.noOfFallingBits = USINT#2;
            IF case_pass[2] THEN
                passed := passed + 1;
            ELSE
                failed := failed + 1;
                IF first_failed_case = 0 THEN first_failed_case := 2; END_IF;
            END_IF;

            t3(value := DWORD#16#00000015);
            actual_hasChanged[3] := t3.hasChanged;
            actual_hasRisingEdges[3] := t3.hasRisingEdges;
            actual_risingBits[3] := t3.risingBits;
            actual_noOfRisingBits[3] := t3.noOfRisingBits;
            actual_hasFallingEdges[3] := t3.hasFallingEdges;
            actual_fallingBits[3] := t3.fallingBits;
            actual_noOfFallingBits[3] := t3.noOfFallingBits;
            case_pass[3] := NOT t3.hasChanged AND NOT t3.hasRisingEdges AND
                             t3.risingBits = DWORD#16#00000000 AND t3.noOfRisingBits = USINT#0 AND
                             NOT t3.hasFallingEdges AND t3.fallingBits = DWORD#16#00000000 AND
                             t3.noOfFallingBits = USINT#0;
            IF case_pass[3] THEN
                passed := passed + 1;
            ELSE
                failed := failed + 1;
                IF first_failed_case = 0 THEN first_failed_case := 3; END_IF;
            END_IF;

            b2(value := DWORD#16#00000000);
            actual_hasChanged[5] := b2.hasChanged;
            actual_hasRisingEdges[5] := b2.hasRisingEdges;
            actual_risingBits[5] := b2.risingBits;
            actual_noOfRisingBits[5] := b2.noOfRisingBits;
            actual_hasFallingEdges[5] := b2.hasFallingEdges;
            actual_fallingBits[5] := b2.fallingBits;
            actual_noOfFallingBits[5] := b2.noOfFallingBits;
            case_pass[5] := b2.hasChanged AND NOT b2.hasRisingEdges AND
                             b2.risingBits = DWORD#16#00000000 AND b2.noOfRisingBits = USINT#0 AND
                             b2.hasFallingEdges AND b2.fallingBits = DWORD#16#FFFFFFFF AND
                             b2.noOfFallingBits = USINT#32;
            IF case_pass[5] THEN
                passed := passed + 1;
            ELSE
                failed := failed + 1;
                IF first_failed_case = 0 THEN first_failed_case := 5; END_IF;
            END_IF;
            test_done := TRUE;
    END_CASE;
END_IF;
