```st
(*
  P07 - Multi-Pump Switching Control System
  CODESYS-compatible IEC 61131-3 Structured Text

  Interface (exact):
    mode      : BOOL   (FALSE = Manual, TRUE = Automatic)
    start     : BOOL   (start button)
    stop      : BOOL   (stop button, dominant)
    pumpGroup : ARRAY[1..5] OF ST_Pump  (In/Out, by reference)

  ST_Pump is assumed to expose at least:
    priority  : INT   (lower value = higher priority)
    selection : BOOL  (manual selection)
    RunComd   : BOOL  (written by this program)

  Assumptions honored:
    - Stop dominates: when stop is TRUE, all RunComd := FALSE.
    - Auto: exactly the three highest-ranked pumps run while start is held;
      ties break by lower array index.
    - Manual: RunComd[i] := selection[i] while start is held and not stop.
    - Selection/priority changes applied each scan.
    - At most 3 pumps run at any time.
*)

PROGRAM P07_MultiPumpControl
VAR_INPUT
    mode  : BOOL;
    start : BOOL;
    stop  : BOOL;
END_VAR

VAR_IN_OUT
    pumpGroup : ARRAY[1..5] OF ST_Pump;
END_VAR

VAR
    i          : INT;
    j          : INT;
    rank       : ARRAY[1..5] OF INT;   (* rank 1 = highest priority *)
    autoSel    : ARRAY[1..5] OF BOOL;  (* TRUE if pump is in top-3 *)
    tmpPrio    : INT;
    tmpIdx     : INT;
    order      : ARRAY[1..5] OF INT;   (* pump indices sorted by priority *)
    runningCnt : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* 1) Compute ranking of pumps by priority (lower priority value =    *)
(*    higher rank). Ties break by lower array index.                  *)
(* ------------------------------------------------------------------ *)
FOR i := 1 TO 5 DO
    order[i] := i;
END_FOR;

(* Simple selection sort on order[] using priority, tie -> lower index *)
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

(* rank[i] = position of pump i in sorted order *)
FOR i := 1 TO 5 DO
    rank[i] := 0;
    autoSel[i] := FALSE;
END_FOR;
FOR i := 1 TO 5 DO
    rank[order[i]] := i;
END_FOR;

(* Top-3 pumps are auto-selected *)
FOR i := 1 TO 5 DO
    IF rank[i] <= 3 THEN
        autoSel[i] := TRUE;
    END_IF;
END_FOR;

(* ------------------------------------------------------------------ *)
(* 2) Output logic: stop dominates, then mode/start.                  *)
(* ------------------------------------------------------------------ *)
IF stop THEN
    (* Stop has priority: all pumps off *)
    FOR i := 1 TO 5 DO
        pump