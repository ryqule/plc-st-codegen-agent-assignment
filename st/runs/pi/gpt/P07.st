TYPE ST_Pump :
STRUCT
    priority  : INT;
    selection : BOOL;
    RunComd   : BOOL;
END_STRUCT
END_TYPE

PROGRAM P07
VAR_INPUT
    mode  : BOOL;
    start : BOOL;
    stop  : BOOL;
END_VAR
VAR_IN_OUT
    pumpGroup : ARRAY[1..5] OF ST_Pump;
END_VAR
VAR
    i            : INT;
    j            : INT;
    rank         : ARRAY[1..5] OF INT;
    selectedAuto : ARRAY[1..5] OF BOOL;
END_VAR

(* Recalculate ranking every scan.
   Higher numeric priority wins; ties favor the lower array index. *)
FOR i := 1 TO 5 DO
    rank[i] := 1;

    FOR j := 1 TO 5 DO
        IF (pumpGroup[j].priority > pumpGroup[i].priority)
            OR ((pumpGroup[j].priority = pumpGroup[i].priority)
                AND (j < i)) THEN
            rank[i] := rank[i] + 1;
        END_IF;
    END_FOR;

    selectedAuto[i] := rank[i] <= 3;
END_FOR;

(* No latched state or timers. Stop dominates all start commands.
   Every RunComd is assigned on every scan. *)
FOR i := 1 TO 5 DO
    IF stop OR NOT start THEN
        pumpGroup[i].RunComd := FALSE;
    ELSIF mode THEN
        pumpGroup[i].RunComd := selectedAuto[i];
    ELSE
        pumpGroup[i].RunComd := pumpGroup[i].selection;
    END_IF;
END_FOR;
END_PROGRAM