The dataset has two conflicts:
- **P07-L3 vs P07-L4:** Manual selection of four or five pumps requires them all to run, violating the unconditional three-pump limit.
- **P07-T2:** Descending numeric priority selects pumps **2, 4, 3**, not **2, 4, 5**.

The implementation below preserves direct manual selection, stop priority, and automatic top-three selection. It requires the interface’s `ST_Pump` DUT to exist in the CODESYS project; its definition and `priority` field type were not supplied.

```st
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

(* Recompute every scan. Higher numeric priority ranks first;
   equal priorities are ordered by lower array index. *)
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

(* Stop dominates both modes.