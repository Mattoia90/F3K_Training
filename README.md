# F3K TRAINING

## Code provenience:
- https://github.com/Mattoia90/F3K_Training
- https://www.rcgroups.com/forums/showthread.php?2298914-F3K-training-script-for-the-Taranis-Q-and-Horus/page22

## My goals with this fork
- Make it usable and problem free for Radiomaster Zorro (EdgeTX 2.8++)
- Limiting the focus to small B&W screen devices (this is what I own, unable to test on different device)
- Provide fixes and improvements back to upstream repository

## INSTALL IN OPENTX Radio
1. Open SD card of your openTX Radio
2. Copy this folder F3K_TRAINING in folder 'SDVolume':\SCRIPTS
3. Copy the f3k.lua in folder 'SDVolume':\SCRIPTS\TELEMETRY

## CUSTOMIZE SWITCH
This you can manage the prestet swicth to start / stop timer correctly.
1. open the 'sdVolume':\SCRIPTS\F3K_TRAINING folder
2. Open the Custom.lua file.
3. search this line local PRELAUNCH_SWITCH = 'se' and change 'se' with your preset switch if it is not equal.

## HOW TO USE F3K TRAINING
1. Select in the radio the F3K model, go to model setting on section "DISPLAY", in a one empty screen select "script" and then select "f3k.lua".
In EdgeTX (at least on Radiomaster Zorro) these are the telemetry screens
2. Now you can go in the corresponding page of the telemetry
3. Use the sc switch to select between Task selection, stopped and fly mode.
4. Select the task by moving the throttle lever


