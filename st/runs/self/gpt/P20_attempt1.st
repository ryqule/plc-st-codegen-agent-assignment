The supplied invariants contain conflicts:
- **L1/L2 versus L8:** manual motion is required by L1/L2 but prohibited by L8 when `SensorOutput` is TRUE.
- **L4 versus wash departure:** L4 prohibits automatic motion while `SensorWash` remains TRUE, even after `washComplete`.

The program below gives the explicit sensor-stop invariants priority. Thus, manual motion is inhibited by `SensorOutput`, and departure from washing requires `SensorWash` to clear. These conflicting demands cannot all be satisfied simultaneously.

`qualifiedWeight` denotes the inclusive numerical range. `unqualifiedWeight` denotes an out-of-range weight during the automatic weighing decision; this makes L7 compatible with the recorded one-scan rejection pulse.

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
    MotorReverse