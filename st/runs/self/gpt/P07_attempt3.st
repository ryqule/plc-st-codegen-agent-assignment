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

(* Required project repairs identified by the diagnostics:

   C77: ST_Pump must be created as a separate CODESYS DUT object.
   A TYPE declaration embedded in this PROGRAM does not register it.
   Use the dataset's ST_Pump definition, with priority, selection,
   and RunComd fields. The priority field type was not supplied.

   C39: The task must invoke a caller that supplies an existing
   ARRAY[1..5] OF ST_Pump by reference:
       P07(pumpGroup := existingPumpArray);
   Direct task invocation of P07 without that argument is invalid.

   Neither repair can be made inside this PROGRAM while preserving
   the required VAR_IN_OUT interface.
*)

FOR i := 1 TO 5 DO
    selectedAuto[i] := FALSE;
    pumpGroup[i].RunComd := FALSE;
    rank[i] := 1;
END_FOR;

IF start AND NOT stop THEN
    IF mode THEN
        FOR i := 1 TO 5 DO
            FOR j := 1 TO 5 DO
                IF pumpGroup[j].priority > pumpGroup[i].priority THEN
                    rank[i] := rank[i] + 1;
                ELSIF (pumpGroup[j].priority = pumpGroup[i].priority)
                      AND (j < i) THEN
                    rank[i] := rank[i] + 1;
                END_IF;
            END_FOR;

            selectedAuto[i] := rank[i] <= 3;
            pumpGroup[i].RunComd := selectedAuto[i];
        END_FOR;
    ELSE
        FOR i := 1 TO 5 DO
            pumpGroup[i].RunComd := pumpGroup[i].selection;
        END_FOR;
    END_IF;
END_IF;

END_PROGRAM