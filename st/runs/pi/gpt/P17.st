```st
PROGRAM P17
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
    previousAdd    : BOOL := FALSE;
    previousDelete : BOOL := FALSE;
    previousModify : BOOL := FALSE;
    previousQuery  : BOOL := FALSE;

    addEdge    : BOOL;
    deleteEdge : BOOL;
    modifyEdge : BOOL;
    queryEdge  : BOOL;

    requestCount : INT;
    i            : INT;
    matchedIndex : INT;
    freeIndex    : INT;
    found        : BOOL;
    duplicate    : BOOL;
    full         : BOOL;
END_VAR

(* Request edges are detected independently. *)
addEdge := addRecipe AND NOT previousAdd;
deleteEdge := deleteRecipe AND NOT previousDelete;
modifyEdge := modifyRecipe AND NOT previousModify;
queryEdge := queryRecipe AND NOT previousQuery;

previousAdd := addRecipe;
previousDelete := deleteRecipe;
previousModify := modifyRecipe;
previousQuery := queryRecipe;

(* Completion indicators and diagnostic outputs describe this scan.
   Query data remains unchanged unless a query succeeds. *)
recipeAdded := FALSE;
recipeDeleted := FALSE;
recipeModified := FALSE;
error := FALSE;
status := WORD#16#0000;

requestCount := 0;
IF addRecipe THEN
    requestCount := requestCount + 1;
END_IF;
IF deleteRecipe THEN
    requestCount := requestCount + 1;
END_IF;
IF modifyRecipe THEN
    requestCount := requestCount + 1;
END_IF;
IF queryRecipe THEN
    requestCount := requestCount + 1;
END_IF;

IF addEdge OR deleteEdge OR modifyEdge OR queryEdge THEN
    IF requestCount > 1 THEN
        (* Ambiguous requests never change the database. *)
        error := TRUE;
        status := WORD#16#80FF;
    ELSE
        matchedIndex := 0;
        freeIndex := 0;

        FOR i := 1 TO 10 DO
            IF recipe[i].recipeID = 0 THEN
                IF freeIndex = 0 THEN
                    freeIndex := i;
                END_IF;
            ELSIF recipe[i].recipeID = recipeIn.recipeID THEN
                IF matchedIndex = 0 THEN
                    matchedIndex := i;
                END_IF;
            END_IF;
        END_FOR;

        found := matchedIndex <> 0;
        full := freeIndex = 0;

        (* ID zero is reserved and cannot be added as a recipe.
           It is never considered a match for query/delete/modify. *)
        duplicate := found OR (recipeIn.recipeID = 0);

        IF queryEdge THEN
            IF found