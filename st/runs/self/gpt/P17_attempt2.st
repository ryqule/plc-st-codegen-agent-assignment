```st
(*
    ST_Recipe member types were not supplied by the dataset.
    This DUT provides a concrete definition for a standalone implementation.
    If ST_Recipe already exists in the project, use that DUT instead.
*)
TYPE ST_Recipe :
STRUCT
    recipeID : DINT;
    ingredientType : STRING[80];
    ingredientRatio : REAL;
    productionTemperature : REAL;
END_STRUCT
END_TYPE

PROGRAM P17
VAR_INPUT
    addRecipe : BOOL;
    deleteRecipe : BOOL;
    modifyRecipe : BOOL;
    queryRecipe : BOOL;
    recipeIn : ST_Recipe;
END_VAR

VAR_OUTPUT
    recipeAdded : BOOL;
    recipeDeleted : BOOL;
    recipeModified : BOOL;
    recipeQueryResult : ST_Recipe;
    error : BOOL;
    status : WORD;
END_VAR

VAR_IN_OUT
    recipe : ARRAY[1..10] OF ST_Recipe;
END_VAR

VAR
    previousAdd : BOOL := FALSE;
    previousDelete : BOOL := FALSE;
    previousModify : BOOL := FALSE;
    previousQuery : BOOL := FALSE;

    addEdge : BOOL;
    deleteEdge : BOOL;
    modifyEdge : BOOL;
    queryEdge : BOOL;
    anyEdge : BOOL;
    activeRequests : INT;

    (* 0 = idle, 1 = add, 2 = delete, 3 = modify,
       4 = query, 5 = ambiguous simultaneous requests. *)
    pendingOperation : INT := 0;
    pendingRecipe : ST_Recipe;

    i : INT;
    foundIndex : INT;
    freeIndex : INT;
END_VAR

(* Success indicators are one-scan pulses.
   Error/status retain the most recent response until the next operation.
   Query results retain the most recent successful query. *)
recipeAdded := FALSE;
recipeDeleted := FALSE;
recipeModified := FALSE;

(* Execute the request captured on the preceding scan. *)
IF pendingOperation <> 0 THEN
    error := FALSE;
    status := WORD#16#0000;

    IF pendingOperation = 5 THEN
        error := TRUE;
        status := WORD#16#80FF;
    ELSE
        foundIndex := 0;
        freeIndex := 0;

        FOR i := 1 TO 10 DO
            IF recipe[i].recipeID = 0 THEN
                IF freeIndex = 0 THEN
                    freeIndex := i;
                END_IF;
            ELSIF recipe[i].recipeID = pendingRecipe.recipeID THEN
                IF foundIndex = 0 THEN
                    foundIndex := i;
                END_IF;
            END_IF;
        END_FOR;

        CASE pendingOperation OF
            1: (* Add: ID zero is reserved; duplicate takes precedence. *)
                IF (pendingRecipe.recipeID = 0) OR (foundIndex <> 0) THEN
                    (* No separate reserved-ID error code is specified. *)
                    error := TRUE;
                    status := WORD