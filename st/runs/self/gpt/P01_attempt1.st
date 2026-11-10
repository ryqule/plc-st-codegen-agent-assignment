```st
PROGRAM PLC_PRG
VAR_INPUT
    bottleSensor : BOOL;
    cleaningConfirmButton : BOOL;
    fillingConfirmButton : BOOL;
    cappingConfirmButton : BOOL;
    packingConfirmButton : BOOL;
    finishedButton : BOOL;
END_VAR

VAR_OUTPUT
    Pump_Motor : BOOL;
    Filling_Valve : BOOL;
    Capping_Machine : BOOL;
    Packing_Machine : BOOL;
    Completion_Light : BOOL;
END_VAR

VAR CONSTANT
    IDLE : INT := 0;
    CLEAN : INT := 1;
    FILL : INT := 2;
    CAP : INT := 3;
    PACK : INT := 4;
    PACKED : INT := 5;
END_VAR

VAR
    phase : INT := 0;

    cleaningPulse : BOOL;
    fillingPulse : BOOL;
    cappingPulse : BOOL;
    packingPulse : BOOL;
    finishedPulse : BOOL;

    previousCleaning : BOOL := FALSE;
    previousFilling : BOOL := FALSE;
    previousCapping : BOOL := FALSE;
    previousPacking : BOOL := FALSE;
    previousFinished : BOOL := FALSE;
END_VAR

(* Detect confirmation-button rising edges in every phase.
   A held button does not generate another confirmation. *)
cleaningPulse := cleaningConfirmButton AND NOT previousCleaning;
fillingPulse := fillingConfirmButton AND NOT previousFilling;
cappingPulse := cappingConfirmButton AND NOT previousCapping;
packingPulse := packingConfirmButton AND NOT previousPacking;
finishedPulse := finishedButton AND NOT previousFinished;

previousCleaning := cleaningConfirmButton;
previousFilling := fillingConfirmButton;
previousCapping := cappingConfirmButton;
previousPacking := packingConfirmButton;
previousFinished := finishedButton;

(* Accept at most one state transition per invocation.
   Confirmations outside their corresponding phase are ignored.
   No timers or additional safety inputs are specified. *)
CASE phase OF
    IDLE:
        IF bottleSensor THEN
            phase := CLEAN;
        END_IF;

    CLEAN:
        IF cleaningPulse THEN
            phase := FILL;
        END_IF;

    FILL:
        IF fillingPulse THEN
            phase := CAP;
        END_IF;

    CAP:
        IF cappingPulse THEN
            phase := PACK;
        END_IF;

    PACK:
        IF packingPulse THEN
            phase := PACKED;
        END_IF;

    PACKED:
        IF finishedPulse THEN
            phase := IDLE;
        END_IF;
END_CASE;

(* Decode the resulting phase: station outputs are mutually exclusive. *)
Pump