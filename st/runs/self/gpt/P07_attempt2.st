(* Declare ST_Pump as a DUT in the CODESYS project.
   The supplied interface does not specify the priority field type;
   INT is used here. *)
TYPE ST_Pump :
STRUCT
    priority : INT;
    selection : BOOL;
    RunComd : BOOL;
END_STRUCT
END_TYPE

PROGRAM P07
VAR_INPUT
    mode : BOOL;
    start : BOOL;
    stop : BOOL;
END_VAR

VAR_IN_OUT
    pumpGroup : ARRAY[1..5] OF ST_Pump;
END_VAR

VAR
    selectedAuto : ARRAY[1..5] OF BOOL;
    rank : ARRAY[1..5] OF INT;
    i : INT;
    j : INT;
END_VAR

(* Higher numeric priority ranks first.
   Equal priorities are ordered by lower array index. *)
FOR i := 1 TO 5 DO
    rank[i] := 1;

    FOR j := 1 TO 5 DO
        IF pumpGroup[j].priority > pumpGroup[i].priority THEN
            rank[i] := rank[i] + 1;
        ELSIF (pumpGroup[j].priority = pumpGroup[i].priority)
              AND (j < i) THEN
            rank[i] := rank[i] + 1;
        END_IF;
    END_FOR;

    selectedAuto[i] := FALSE;
    pumpGroup[i].RunComd := FALSE;
END_FOR;

(* Stop dominates both modes. Commands are recomputed each scan. *)
IF start AND NOT stop THEN
    IF mode THEN
        FOR i := 1 TO 5 DO
            selectedAuto[i] := rank[i] <= 3;
            pumpGroup[i].RunComd := selectedAuto[i];
        END_FOR;
    ELSE
        FOR i := 1 TO 5 DO
            pumpGroup[i].RunComd := pumpGroup[i].selection;
        END_FOR;
    END_IF;
END_IF;

(* Mapping:
   P07-L1 / T3: stop clears all commands.
   P07-L2: automatic selection uses rank <= 3.
   P07-L3 / T1: manual commands follow selection while start is held.
   P07-L4 holds in automatic mode; unrestricted manual selection
   conflicts with its unconditional three-pump limit.
   T2 conflicts with numeric top-three ranking: [1,5,3,4,2]
   selects pumps 2, 3, and 4, not pumps 2, 4, and 5. *)
END_PROGRAM