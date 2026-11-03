# F3K TRAINING

Actual version: 
#### 3.04

Original project on: https://www.rcgroups.com/forums/showthread.php?2298914-F3K-training-script-for-the-Taranis-Q-and-Horus/page22

## INSTALL IN OPENTX Radio
1. Open SD card of your openTX Radio
2. Copy this folder F3K_TRAINING in folder 'SDVolume':\SCRIPTS
3. Copy the f3k.lua in folder 'SDVolume':\SCRIPTS\TELEMETRY

## CUSTOMIZE SWITCH
This you can manage the prestet swicth to start / stop timer correctly.
1. open the 'sdVolume':\SCRIPTS\F3K_TRAINING folder
2. Open the Custom.lua file.
3. search this line local PRELAUNCH_SWITCH = 'se' and change 'se' with your preset switch if it is not equal.

## CUSTOMIZE TASK DESCRIPTION / PREP COUNTDOWN
In the same Custom.lua file, the line local TASK_DESCRIPTION = true selects how a task starts:
- true: the task description is played, then the prep time countdown announces only 10..1 (the description has time to finish).
- false: no task description, the prep time is shorter and the countdown starts directly from local PREP_COUNTDOWN seconds (default 10, e.g. 5 for a faster start; range 1..10).

## HOW TO SET F3K TRAINING
Select in the radio the F3K model, go to model setting on section "DISPLAY", in a one empty screen select "script" and then select "f3k.lua".
Now you can go in the corresponding page of the telemetry, select your task, toggle the sc switch and play with f3k training!!

### Version 3.04
1. New TASK_DESCRIPTION option in custom.lua: prep countdown announced by the script from 10 (no more delay behind the task description), optional fast start without task description.

### Version 3.03B4
1. Fix version detection on EdgeTX 2.10 / 2.12 (widget crash on Horus/TX16S).
2. Fix duration/time announcements on EdgeTX.
3. Fix menu selection with throttle.
4. Basic telemetry values on X7.
5. Display alignment fixes (K, M, D2, QT on X7; D, D2 on Horus widget).
6. Task H (1234): no "seconds" at minute countdown, score capped per target slot.
7. Task N sounds added (+10 dB).
8. Unit tests for all tasks and GitHub Actions CI.


### Version 3.03B3
1. Add New Task N Best Flight.
2. Some improvements on One Flight graphics

### Version 3.03B2
1. Manage some missing view task on X7 folder and errors.
    - view_k.lua
    - view_l.lua
    - view_d.lua
    - view_d2.lua
2. Modify f3k.lua for select last task FF too.
