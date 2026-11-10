The specifications contain conflicts that no ST program can satisfy for every input combination:

- **L1/L2 versus L8:** manual motion is required even when `SensorOutput` is TRUE, but L8 requires both motor outputs OFF. The implementation below gives L8 priority.
- **L7 versus one-scan rejection:** if `unqualifiedWeight` means simply an out-of-range weight, sustained `weightComplete` would require sustained `kick`. Below, rejection occurs once when the automatic weighing stage evaluates the product.
- **L4 versus departure from cleaning:** L4 prohibits forward motion while `SensorWash` remains TRUE, even after `washComplete`. Below, the sequence advances, but motion remains inhibited until `SensorWash` clears.

These are explicit limitations, not claims that all formulas are simultaneously satisfied.

```st
PROGRAM ProductionControl
VAR_INPUT
    Mode : BOOL;
    ForwardButton : BOOL;
    ReverseButton : BOOL;
    SensorFeed : BOOL;
    SensorWash : BOOL;
    SensorWeight : BOOL;
    SensorFiring : BOOL;
    SensorOutput : BOOL;
    washComplete : BOOL;
    weightComplete : BOOL;
    weight : REAL;
    firingComplete : BOOL;
END_VAR

VAR_OUTPUT
    MotorForward : BOOL;
    MotorReverse : BOOL;
    kick : BOOL;
    CompletionLight : BOOL;
    firingTemp : REAL;
END_VAR

VAR
    (* States:
       0: waiting for feed
       1: travelling to wash
       2: waiting for cleaning completion
       3: travelling to weighing
       4: waiting for weighing completion
       5: travelling to firing
       6: waiting for firing completion
       7: travelling to output
       8: waiting for rejected material to leave
    *)
    stage : INT := 0;
    previousMode : BOOL := FALSE;
    initialized : BOOL := FALSE;
    qualifiedWeight : BOOL := FALSE;
    forwardRequest : BOOL := FALSE;
END_VAR

(* Every scan starts with inactive motor and rejection commands. *)
MotorForward := FALSE;
MotorReverse := FALSE;
kick := FALSE;
forwardRequest := FALSE;

(* Inclusive qualification range; preserve the linear formula. *)
qualifiedWeight := (weight >= 100.0) AND (weight <= 200.0);
IF qualifiedWeight THEN
    firingTemp := 500.0 + (weight - 100.0) * 0.5;
END_IF;

(* Initialization and every mode change abort the sequence.
   No timers or external function blocks are required. *)
IF NOT initialized THEN
    stage := 0;
    previousMode := Mode;
    initialized := TRUE;
ELSIF Mode <> previousMode THEN
    stage := 0;
END_IF;
previousMode :=