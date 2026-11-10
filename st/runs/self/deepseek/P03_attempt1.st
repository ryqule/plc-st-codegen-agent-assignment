FUNCTION_BLOCK P03_AlarmHandling
VAR_INPUT
    Value     : REAL;   (* Input value *)
    hiLevel   : REAL;   (* High limit alarm value *)
    loLevel   : REAL;   (* Low limit alarm value *)
    hystWindow: REAL;   (* Hysteresis window *)
END_VAR
VAR_OUTPUT
    hiAlarm : BOOL;     (* High limit alarm *)
    loAlarm : BOOL;     (* Low limit alarm *)
    error   : BOOL;     (* FALSE: no error; TRUE: error *)
    status  : WORD;     (* Status code *)
END_VAR
VAR
    validConfig : BOOL;
END_VAR

(* --------------------------------------------------------- *)
(* Configuration validation                                  *)
(* P03-L1: loLevel >= hiLevel -> error 16#8001, no alarms    *)
(* P03-L2: hystWindow >= (hiLevel - loLevel) -> error 16#8002 *)
(* Invalid configuration does not update alarm latches.       *)
(* --------------------------------------------------------- *)
IF loLevel >= hiLevel THEN
    error       := TRUE;
    status      := 16#8001;
    validConfig := FALSE;
    hiAlarm     := FALSE;
    loAlarm     := FALSE;
    (* "exit the program": no further processing this scan *)
    RETURN;
ELSIF hystWindow >= (hiLevel - loLevel) THEN
    error       := TRUE;
    status      := 16#8002;
    validConfig := FALSE;
    (* Per assumption: invalid config does not update latches *)
    RETURN;
ELSE
    error       := FALSE;
    status      := 16#0000;
    validConfig := TRUE;
END_IF;

(* --------------------------------------------------------- *)
(* Hysteresis alarm logic (scan-level latch, equality latched) *)
(* P03-L3: Value > hiLevel          -> hiAlarm next scan     *)
(* P03-L5: hiAlarm & Value >= hiLevel-hystWindow -> stays on *)
(* (else if latched and below window -> clears)               *)
(* P03-L4: Value < loLevel          -> loAlarm next scan     *)
(* P03-L6: loAlarm & Value <= loLevel+hystWindow -> stays on *)
(* --------------------------------------------------------- *)

(* High alarm *)
IF Value > hiLevel THEN
    hiAlarm := TRUE;
ELSIF hiAlarm AND (Value >= (hiLevel - hystWindow)) THEN
    hiAlarm := TRUE;   (* equality latched per source wording *)
ELSE
    hiAlarm := FALSE;
END_IF;

(* Low alarm *)
IF Value < loLevel THEN
    loAlarm := TRUE;
ELSIF loAlarm AND (Value <= (loLevel + hystWindow)) THEN
    loAlarm := TRUE;   (* equality latched per source wording *)
ELSE
    loAlarm := FALSE;
END_IF;

END_FUNCTION_BLOCK