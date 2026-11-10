```st
(*
  Recipe Management System
  CODESYS-compatible IEC 61131-3 Structured Text

  Assumptions (per dataset):
  - Operation requests are rising-edge triggered and mutually exclusive.
  - Simultaneous requests are rejected as ambiguous (status 16#80FF).
  - Recipe ID 0 is reserved (empty slot).
  - Database holds up to 10 recipes in ARRAY[1..10] OF ST_Recipe.
*)

TYPE ST_Recipe :
STRUCT
    recipeID              : INT;
    ingredientType        : INT;
    ingredientRatio       : REAL;
    productionTemperature : REAL;
END_STRUCT
END_TYPE

PROGRAM RecipeManagement
VAR_INPUT
    addRecipe    : BOOL;
    deleteRecipe : BOOL;
    modifyRecipe : BOOL;
    queryRecipe  : BOOL;
    recipeIn     : ST_Recipe;
END_VAR

VAR_OUTPUT
    recipeAdded       : BOOL;
    recipeDeleted     : BOOL;
    recipeModified    : BOOL;
    recipeQueryResult : ST_Recipe;
    error             : BOOL;
    status            : WORD;
END_VAR

VAR_IN_OUT
    recipe : ARRAY[1..10] OF ST_Recipe;
END_VAR

VAR
    (* Edge detection *)
    addRecipePrev    : BOOL;
    deleteRecipePrev : BOOL;
    modifyRecipePrev : BOOL;
    queryRecipePrev  : BOOL;

    (* Working flags *)
    reqAdd    : BOOL;
    reqDelete : BOOL;
    reqModify : BOOL;
    reqQuery  : BOOL;
    reqCount  : INT;

    (* Search results *)
    foundIndex : INT;
    found      : BOOL;
    freeIndex  : INT;
    freeFound  : BOOL;

    i : INT;
END_VAR

(* ------------------------------------------------------------------ *)
(* 1. Rising-edge detection for each request                          *)
(* ------------------------------------------------------------------ *)
reqAdd    := addRecipe    AND NOT addRecipePrev;
reqDelete := deleteRecipe AND NOT deleteRecipePrev;
reqModify := modifyRecipe AND NOT modifyRecipePrev;
reqQuery  := queryRecipe  AND NOT queryRecipePrev;

addRecipePrev    := addRecipe;
deleteRecipePrev := deleteRecipe;
modifyRecipePrev := modifyRecipe;
queryRecipePrev  := queryRecipe;

(* ------------------------------------------------------------------ *)
(* 2. Default outputs each scan                                       *)
(* ------------------------------------------------------------------ *)
recipeAdded    := FALSE;
recipeDeleted  := FALSE;
recipeModified := FALSE;
error          := FALSE;
status         := 16#0000;

(* ------------------------------------------------------------------ *)
(* 3. Count simultaneous requests                                     *)
(* ------------------------------------------------------------------ *)
reqCount := 0;
IF reqAdd    THEN reqCount := reqCount + 1; END_IF;
IF reqDelete THEN reqCount := reqCount + 1; END_IF;
IF reqModify THEN reqCount := reqCount + 1; END_IF;
IF reqQuery  THEN reqCount := reqCount + 1; END_IF;

(* ------------------------------------------------------------------ *)
(* 4. Process requests                                                *)
(* ------------------------------------------------------------------ *)
IF reqCount > 1 THEN
    (* Ambiguous: multiple simultaneous requests *)
    error  := TRUE;
    status := 16#80FF;

ELSIF reqCount = 1 THEN

    (* -------------------------------------------------------------- *)
    (* 4a. QUERY                                                      *)
    (* -------------------------------------------------------------- *)
    IF reqQuery THEN
        foundIndex := 0;
        found      := FALSE;
        FOR i := 1 TO 10 DO
            IF (recipe[i].recipeID <> 0) AND
               (recipe[i].recipeID = recipeIn