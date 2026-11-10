PROGRAM P03
VAR_INPUT
    Value      : REAL;
    hiLevel    : REAL;
    loLevel    : REAL;
    hystWindow : REAL;
END_VAR
VAR_OUTPUT
    hiAlarm : BOOL := FALSE;
    loAlarm : BOOL := FALSE;
    error   : BOOL := FALSE;
    status  : WORD := WORD#16#0000;
END_VAR
VAR
    hiLatched : BOOL := FALSE;
    loLatched : BOOL := FALSE;
END_VAR

(* Configuration errors do not change the internal alarm latches. *)
IF loLevel >= hiLevel THEN
    error := TRUE;
    status := WORD#16#8001;

    (* Required output suppression; internal latches are preserved. *)
    hiAlarm := FALSE;
    loAlarm := FALSE;
    RETURN;
END_IF;

IF hystWindow >= (hiLevel - loLevel) THEN
    error := TRUE;
    status := WORD#16#8002;
    hiAlarm := hiLatched;
    loAlarm := loLatched;
    RETURN;
END_IF;

error := FALSE;
status := WORD#16#0000;

(* Strict comparisons preserve the latch at each hysteresis boundary. *)
IF NOT hiLatched THEN
    IF Value > hiLevel THEN
        hiLatched := TRUE;
    END_IF;
ELSE
    IF Value < (hiLevel - hystWindow) THEN
        hiLatched := FALSE;
    END_IF;
END_IF;

IF NOT loLatched THEN
    IF Value < loLevel THEN
        loLatched := TRUE;
    END_IF;
ELSE
    IF Value > (loLevel + hystWindow) THEN
        loLatched := FALSE;
    END_IF;
END_IF;

hiAlarm := hiLatched;
loAlarm := loLatched;
END_PROGRAM