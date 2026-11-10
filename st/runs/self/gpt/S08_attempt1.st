```st
PROGRAM S08
VAR_INPUT
    PartPresent     : BOOL;
    Defect          : BOOL;
    ConveyorRunning : BOOL;
    CycleTime       : TIME;
    Reset           : BOOL;
END_VAR
VAR_OUTPUT
    RejectSolenoid : BOOL := FALSE;
    RejectCount    : UDINT := UDINT#0;
END_VAR
VAR
    prevDefect     : BOOL := FALSE;
    defectRise     : BOOL := FALSE;
    qualifiedRise  : BOOL := FALSE;
    pulseActive    : BOOL := FALSE;
    pulseElapsed   : TIME := T#0ms;
    pulse300msDone : BOOL := FALSE;
END_VAR

(* Explicit alternative for the conflicting invariants:
   - PartPresent and ConveyorRunning dominate the physical output.
   - Reset dominates counting, but does not change pulse timing.
   - Every qualified edge starts/restarts a 300 ms pulse interval.
   - Timing continues while the physical output is interlocked off.
*)

defectRise := Defect AND NOT prevDefect;
qualifiedRise := defectRise AND PartPresent AND ConveyorRunning;
prevDefect := Defect;

(* Advance an existing pulse using the supplied scan duration.
   Comparing against the remaining time avoids accumulation overflow