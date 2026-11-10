(*
  Multi-Pump Switching Control System
  CODESYS-compatible IEC 61131-3 Structured Text

  Interface (exact):
    mode      : BOOL  (FALSE = Manual, TRUE = Automatic)
    start     : BOOL  (Start button)
    stop      : BOOL  (Stop button, dominant)
    pumpGroup : ARRAY[1..5] OF ST_Pump  (In/Out; read priority & selection, write RunComd)

  Assumptions honored:
    - Auto mode selects exactly the three highest-ranked pumps while start is held.
    - Ties break by lower array index.
    - Stop has priority; selection changes applied each scan.
    - At most 3 pumps run at any time.
*)

TYPE ST_Pump :
STRUCT
    priority  : INT;    (* lower value = higher priority *)
    selection : BOOL;   (* manual selection *)
    RunComd   : BOOL;   (* output command *)
END_STRUCT
END_TYPE

PROGRAM P07_MultiPumpControl
VAR
    i          : INT;
    j          : INT;
    rank       : ARRAY[1..5] OF INT;   (* rank 1 = highest priority *)
    order      : ARRAY[1..5] OF INT;   (* pump indices sorted by priority *)
    autoSel    : ARRAY[1..5] OF BOOL;  (* TRUE if pump is in top-3 auto selection *)
    tmpIdx     : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* 1) Compute ranking of pumps by priority (lower value = higher).     *)
(*    Ties broken by lower array index.                                *)
(* ------------------------------------------------------------------ *)
FOR i := 1 TO 5 DO
    order[i] := i;
END_FOR;

FOR i := 1 TO 4 DO
    FOR j := i + 1 TO 5 DO
        IF (pumpGroup[order[j]].priority < pumpGroup[order[i]].priority)
           OR ((pumpGroup[order[j]].priority = pumpGroup[order[i]].priority)
               AND (order[j] < order[i])) THEN
            tmpIdx := order[i];
            order[i] := order[j];
            order[j] := tmpIdx;
        END_IF;
    END_FOR;
END_FOR;

FOR i := 1 TO 5 DO
    rank[order[i]] := i;
END_FOR;

(* ------------------------------------------------------------------ *)
(* 2) Determine auto selection: top-3 by rank.                         *)
(* ------------------------------------------------------------------ *)
FOR i := 1 TO 5 DO
    autoSel[i] := (rank[i] <= 3);
END_FOR;

(* ------------------------------------------------------------------ *)
(* 3) Output logic. Stop dominates.                                    *)
(* ------------------------------------------------------------------ *)
IF stop THEN
    FOR i := 1 TO 5 DO
        pumpGroup[i].RunComd := FALSE;
    END_FOR;
ELSIF start THEN
    IF mode THEN
        FOR i := 1 TO 5 DO
            pumpGroup[i].RunComd := autoSel[i];
        END_FOR;
    ELSE
        FOR i := 1 TO 5 DO
            pumpGroup[i].RunComd := pumpGroup[i].selection;
        END_FOR;
    END_IF;
ELSE
    FOR i := 1 TO 5 DO
        pumpGroup[i].RunComd := FALSE;
    END_FOR;
END_IF;

END_PROGRAM