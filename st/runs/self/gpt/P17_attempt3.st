```st
(*
    CODESYS project requirement:
    Create ST_Recipe as a DUT using the TYPE declaration below.
    A PROGRAM-only importer must import this DUT separately; putting a
    TYPE declaration in a PROGRAM's declaration editor does not define a DUT.
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

    (* 0 = idle; 1 = add; 2 = delete; 3 = modify;
       4 = query; 5 = ambiguous requests. *)
    pendingOperation : INT := 0;
    pendingRecipe : ST_Recipe;

    i : INT;
    foundIndex : INT;
    freeIndex : INT;
END_VAR

(* Success indicators pulse for one scan. *)
recipeAdded := FALSE;
recipeDeleted := FALSE;
recipeModified := FALSE;

(* Publish the response one scan after detecting the request. *)
IF pendingOperation <> 0 THEN
    error := FALSE;
    status := 16#0000;

    IF pendingOperation = 5 THEN
        error := TRUE;
        status := 16#80FF;
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
            1:
                IF (pendingRecipe.recipeID = 0) OR
                   (foundIndex <> 0) THEN
                    (* ID 0 cannot be stored as an occupied recipe.
                       The dataset supplies no separate reserved-ID code;
                       this implementation uses the add-rejection code. *)
                    error := TRUE;
                    status := 16#8002;
                ELSIF freeIndex = 0 THEN
                    error := TRUE;
                    status := 16