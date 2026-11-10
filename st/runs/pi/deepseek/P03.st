FUNCTION_BLOCK P03_AlarmHandling
VAR_INPUT
    Value     : REAL;
    hiLevel   : REAL;
    loLevel   : REAL;
    hystWindow: REAL;
END_VAR
VAR_OUTPUT
    hiAlarm : BOOL;
    loAlarm : BOOL;
    error   : BOOL;
    status  : WORD;
END_VAR
VAR
    validConfig : BOOL;
END_VAR

(* --- Configuration validation ------------------------------------------- *)
(* Error 16#8001: loLevel >= hiLevel. Highest priority.                       *)
IF loLevel >= hiLevel THEN
    error       := TRUE;
    status      := 16#8001;
    validConfig := FALSE;
    hiAlarm     := FALSE;
    loAlarm     := FALSE;
    RETURN;
END_IF

(* Error 16#8002: hysteresis window >= deviation range (hiLevel - loLevel).   *)
(* Invalid configuration does not update alarm latches (per assumption).      *)
IF hystWindow >= (hiLevel - loLevel) THEN
    error       := TRUE;
    status      := 16#8002;
    validConfig := FALSE;
    RETURN;
END_IF

(* Valid configuration *)
error       := FALSE;
status      := 16#0000;
validConfig := TRUE;

(* --- High alarm with hysteresis ----------------------------------------- *)
(* Trigger when Value > hiLevel; latch while Value >= hiLevel - hystWindow.   *)
IF Value > hiLevel THEN
    hiAlarm := TRUE;
ELSIF Value < (hiLevel - hystWindow) THEN
    hiAlarm := FALSE;
END_IF
(* else: within hysteresis band -> keep previous state (latched) *)

(* --- Low alarm with hysteresis ------------------------------------------ *)
(* Trigger when Value < loLevel; latch while Value <= loLevel + hystWindow.   *)
IF Value < loLevel THEN
    loAlarm := TRUE;
ELSIF Value > (loLevel + hystWindow) THEN
    loAlarm := FALSE;
END_IF
(* else: within hysteresis band -> keep previous state (latched) *)

END_FUNCTION_BLOCK