(* Automatic scan-by-scan tests for dataset task P02. *)
SETUP
VAR
    fb : __POU_NAME__;
END_VAR
END_SETUP

TEST 'P02-T1 first invocation with zero has no edges'
    fb(value := DWORD#16#00000000);
    ASSERT_FALSE(fb.hasChanged);
    ASSERT_FALSE(fb.hasRisingEdges);
    ASSERT_EQ(fb.risingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfRisingBits, USINT#0);
    ASSERT_FALSE(fb.hasFallingEdges);
    ASSERT_EQ(fb.fallingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfFallingBits, USINT#0);
END_TEST

TEST 'P02-T2 reports the exact rising and falling masks'
    fb(value := DWORD#16#0000000F);
    fb(value := DWORD#16#00000013);
    ASSERT_TRUE(fb.hasChanged);
    ASSERT_TRUE(fb.hasRisingEdges);
    ASSERT_EQ(fb.risingBits, DWORD#16#00000010);
    ASSERT_EQ(fb.noOfRisingBits, USINT#1);
    ASSERT_TRUE(fb.hasFallingEdges);
    ASSERT_EQ(fb.fallingBits, DWORD#16#0000000C);
    ASSERT_EQ(fb.noOfFallingBits, USINT#2);
END_TEST

TEST 'P02-T3 repeated value reports no edges'
    fb(value := DWORD#16#00000015);
    fb(value := DWORD#16#00000015);
    ASSERT_FALSE(fb.hasChanged);
    ASSERT_FALSE(fb.hasRisingEdges);
    ASSERT_EQ(fb.risingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfRisingBits, USINT#0);
    ASSERT_FALSE(fb.hasFallingEdges);
    ASSERT_EQ(fb.fallingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfFallingBits, USINT#0);
END_TEST

TEST 'P02-B1 counts all 32 rising bits including the sign bit'
    fb(value := DWORD#16#FFFFFFFF);
    ASSERT_TRUE(fb.hasChanged);
    ASSERT_TRUE(fb.hasRisingEdges);
    ASSERT_EQ(fb.risingBits, DWORD#16#FFFFFFFF);
    ASSERT_EQ(fb.noOfRisingBits, USINT#32);
    ASSERT_FALSE(fb.hasFallingEdges);
    ASSERT_EQ(fb.fallingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfFallingBits, USINT#0);
END_TEST

TEST 'P02-B2 counts all 32 falling bits when cleared'
    fb(value := DWORD#16#FFFFFFFF);
    fb(value := DWORD#16#00000000);
    ASSERT_TRUE(fb.hasChanged);
    ASSERT_FALSE(fb.hasRisingEdges);
    ASSERT_EQ(fb.risingBits, DWORD#16#00000000);
    ASSERT_EQ(fb.noOfRisingBits, USINT#0);
    ASSERT_TRUE(fb.hasFallingEdges);
    ASSERT_EQ(fb.fallingBits, DWORD#16#FFFFFFFF);
    ASSERT_EQ(fb.noOfFallingBits, USINT#32);
END_TEST
