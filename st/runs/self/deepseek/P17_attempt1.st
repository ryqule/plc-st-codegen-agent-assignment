```st
FUNCTION_BLOCK P17_RecipeManagement
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
    i           : INT;
    found       : BOOL;
    duplicate   : BOOL;
    full        : BOOL;
    freeIndex   : INT;
    reqCount    : INT;
    edgeAdd     : R_TRIG;
    edgeDelete  : R_TRIG;
    edgeModify  : R_TRIG;
    edgeQuery   : R_TRIG;
END_VAR

(* Rising-edge detection for each request *)
edgeAdd(CLK := addRecipe);
edgeDelete(CLK := deleteRecipe);
edgeModify(CLK := modifyRecipe);
edgeQuery(CLK := queryRecipe);

(* Default outputs each scan *)
recipeAdded    := FALSE;
recipeDeleted  := FALSE;
recipeModified := FALSE;
error          := FALSE;
status         := 16#0000;

(* Count simultaneous rising-edge requests *)
reqCount := 0;
IF edgeAdd.Q    THEN reqCount := reqCount + 1; END_IF;
IF edgeDelete.Q THEN reqCount := reqCount + 1; END_IF;
IF edgeModify.Q THEN reqCount := reqCount + 1; END_IF;
IF edgeQuery.Q  THEN reqCount := reqCount + 1; END_IF;

IF reqCount > 1 THEN
    (* Ambiguous simultaneous requests *)
    error  := TRUE;
    status := 16#80FF;
ELSIF reqCount = 1 THEN
    (* Scan database for match, duplicate, and lowest free slot *)
    found     := FALSE;
    duplicate := FALSE;
    full      := TRUE;
    freeIndex := 0;

    FOR i := 1 TO 10 DO
        IF recipe[i].recipeID = 0 THEN
            IF full THEN
                freeIndex := i;
                full := FALSE;
            END_IF;
        ELSIF recipe[i].recipeID = recipeIn.recipeID THEN
            found := TRUE;
        END_IF;
    END_FOR;

    (* Duplicate check for add: any existing slot with same non-zero ID *)
    IF recipeIn.recipeID <> 0 THEN
        FOR i := 1 TO 10 DO
            IF recipe[i].recipeID = recipeIn.recipeID THEN
                duplicate := TRUE;
            END_IF;
        END_FOR;
    END_IF;

    IF edgeQuery.Q THEN
        IF found THEN
            FOR i := 1 TO 10 DO
                IF recipe[i].recipeID = recipeIn.recipeID THEN
                    recipeQueryResult := recipe[i];
                END_IF;
            END_FOR;
            error  := FALSE;
            status := 16#0000;
        ELSE
            error  := TRUE;
            status := 16#8001;
        END_IF;

    ELSIF edgeAdd.Q THEN
        IF duplicate THEN
            error  := TRUE;
            status := 16#8002;
        ELSIF full THEN
            error  := TRUE;
            status := 16#8003;
        ELSE