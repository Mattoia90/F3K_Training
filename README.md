# F3K TRAINING

Actual version: 
#### 3.04.05

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
- false: no task description, the prep time is shorter and the countdown starts directly from local PREP_COUNTDOWN seconds (default 10, e.g. 5 for a faster start; range 0..10).

### Start at the first launch (PREP_COUNTDOWN = 0)
With TASK_DESCRIPTION = false and PREP_COUNTDOWN = 0 there is no prep time and no countdown:
1. Select the task and move the menu switch to run: the task waits, showing the full working time.
2. Hold the prelaunch switch (more than 0.6 s) and release it when you launch: the working time and the first flight start together.
3. A quick pull of the prelaunch switch while waiting is ignored.

Task C (AULD) and Free Flight have no prep time and are not affected.

## TASK E - POKER (E = 10 min, EE = 15 min)
Up to 3 target times, each announced before the launch. You can launch as many times as you need to reach or exceed the announced target, and it can't be changed until it has been reached. The last call can be "end of working time" (W), which gets one attempt only. The score is the sum of the reached targets.

The target is chosen with the menu scroll input (MENU_SCROLL_ENCODER, the throttle by default):
1. At the start of the task, and after landing a flight that reached its target, the target is **W** (all the remaining working time), whatever the stick position.
2. Move the stick to choose another target: stick up = longer. The value is a share of the remaining working time, in 10 s steps; stick fully up = W. You can already choose the first target during the prep time (or, with PREP_COUNTDOWN = 0, before the first launch).
3. Launch: the target is locked and announced ("target 2 minutes 30", or "end of working time"), and the flight timer counts down from it with the voice countdown.
4. Target reached in the air: "well done", and the target is credited. After the landing you can choose the next one.
5. Target not reached: it stays locked (the screen shows "Lock") and the stick is ignored until it is reached. "Sorry, but you can't improve anymore" is played at the launch if the locked target is longer than the remaining working time.
6. W: credited with the flight time up to the end of the working time; if you land before the end, the task ends with no score for it.

The task ends after 3 reached targets or at the end of the working time.


The task log records the flight times of Poker, not the announced targets; the TaskLog page doesn't score Poker yet.

## TASK HISTORY LOG
In the same Custom.lua file, set local TASK_LOG = true to keep a history of the tasks flown.
At the end of each task (or when it is stopped with the switch after at least one flight) a line is appended to 'SDVolume':\SCRIPTS\F3K_TRAINING\TasksLog\yyyyMMdd.csv (one file per day):
```
Date;Time;Task;Window;Status;Flights
2026-11-04;15:32:10;Last Flight;600;END;95;72;110
```
- Window: working time in seconds (0 when the task has none).
- Status: END (task completed) or STOP (stopped with the switch).
- Flights: every flight time in seconds, in the order flown.

To analyse the logs open the TaskLog page https://rcglideranalytics.com/F3kTraining/TaskLog (or the "TaskLog" link at the top of the configuration page) and load one or more CSV files: it shows the flights of each session against their targets, the END / STOP status and a score normalized to 1000 (1000 = every target fully reached; Free Flight has no target).

The file is written only once per task, so logging doesn't slow down the timers. The TasksLog folder must exist on the SD card (it is included in F3K_TRAINING): Lua scripts can't create folders, so without it nothing is written.

## CONFIGURATION PAGE
Instead of editing Custom.lua by hand you can use the online configuration page (no installation needed).
The configuration and task log pages are now hosted on:
- Configurator: https://rcglideranalytics.com/F3kTraining/Configurator
- TaskLog: https://rcglideranalytics.com/F3kTraining/TaskLog

With the login you can save your configurations and reuse them later.

**Version upgrade:** when you install a new version of F3K Training, if the new version contains a changed custom.lua file, your custom.lua must be set again starting from the new version's file (open the new custom.lua in the Configurator and apply your saved configuration), otherwise the new options are missing.

1. Open https://rcglideranalytics.com/F3kTraining/Configurator in a browser (Chrome or Edge recommended: they can save the file in place; other browsers download the updated file).
2. Click "Open custom.lua…" (or drop the file on the page) and select `F3K_TRAINING/custom.lua`, either from this folder or directly from the radio SD card ('SDVolume':\SCRIPTS\F3K_TRAINING\custom.lua).
3. Choose your radio model (FrSky Taranis X9D Plus 2019, Q X7, X-Lite Pro, RadioMaster Zorro, TX16S) to see where the switches are, then click a control on the drawing to assign it, or use "Apply example settings".
4. Set PRELAUNCH_SWITCH, MENU_SWITCH, MENU_SCROLL_ENCODER, TASK_DESCRIPTION, PREP_COUNTDOWN (0..10), TASK_LOG and LAUNCH_HEIGHT_VOICE. Switches, buttons, pots, sliders and sticks not shown on the drawing can be selected from the lists or typed with "Other…".
5. Click "Save" (or "Download custom.lua") and copy the file to 'SDVolume':\SCRIPTS\F3K_TRAINING\ if you did not save it there directly.

Only those seven values are changed; the rest of custom.lua is kept as it is. The radio drawings follow the manufacturers' manuals: check the switches in the radio's hardware / switch test screen if your radio was modified.

## CONFIGURE ON THE RADIO (F3K Config tool)
At the field you can change the same seven values directly on the radio, without a computer.
1. The tool is f3kcfg.lua inside the F3K_TRAINING folder, so it is already on the SD card ('SDVolume':\SCRIPTS\F3K_TRAINING\f3kcfg.lua).
2. Open the radio SD card browser, go to SCRIPTS/F3K_TRAINING, long press f3kcfg.lua > Execute. Optional: also copy it to 'SDVolume':\SCRIPTS\TOOLS to start "F3K Config" from the radio Tools menu.
3. Scroll to a setting and press ENTER: ON/OFF settings toggle, the others enter edit mode (scroll to change, ENTER/EXIT to confirm). Only the switches / inputs existing on your radio are listed. For the switches and the menu scroll input you can also just move the control you want (switch, stick, pot, slider) while editing: it is selected automatically, as in the radio's own menus.
4. Select SAVE and press ENTER, then EXIT. The settings are read again when the telemetry script restarts after the tool. If they are not applied, restart the radio.

The tool edits SCRIPTS\F3K_TRAINING\custom.lua (or WIDGETS\F3K_TRAINING\custom.lua on Horus) in the same way as the Configurator, and keeps the previous file as custom.bak. On Horus widgets the switches set in the widget settings take precedence over custom.lua.

## HOW TO SET F3K TRAINING
Select in the radio the F3K model, go to model setting on section "DISPLAY", in a one empty screen select "script" and then select "f3k.lua".
Now you can go in the corresponding page of the telemetry, select your task, toggle the sc switch and play with f3k training!!

### Next version (unreleased)
1. Launch height: with an altitude sensor (`Alt` from a vario / ELRS baro, `GAlt` or `Valt`; see HEIGHT in custom.lua) the height of every launch is measured (peak altitude minus the altitude at the launch, until the peak is passed, 10 s or the landing), announced in meters and shown on screen (X7: `L:` when not flying, live `A:` while flying; X9: `L:` top right; Horus: below the main timer).
2. New LAUNCH_HEIGHT_VOICE option in custom.lua (default true): set it to false to keep the launch height on screen and in the log without the voice announcement.
3. Task log: new Heights column before the flights (`Date;Time;Task;Window;Status;Heights;Flights`), launch heights in meters separated by spaces, empty without altitude sensor.
4. custom.lua changed (HEIGHT now starts with `Alt`, new LAUNCH_HEIGHT_VOICE): when upgrading, set it again starting from the new file.
5. New F3K Config radio tool (F3K_TRAINING/f3kcfg.lua, run it from the SD card browser): change the custom.lua settings on the radio at the field.
6. F3K Config: fixed "not enough memory" on SAVE (the file is now written in pieces, without whole copies in memory).
7. X7 task menu: script version shown in small inverted text at the bottom right, on top of the menu (X9 and color widget already showed it).
8. Color radios (EdgeTX widget, full screen zone): TX16S / Horus (480x272) and TX15 / GX15 (480x320) use the same widget views. New Task K (Big Ladder) and L (One flight) widget views, which crashed the widget before; Task M widget view fixed for the 3 / 5 / 7 min targets.

### Version 3.04.05
1. New Task E Poker (10 min working time) and EE Poker (15 min working time), at the end of the task list: the target is chosen with the menu scroll input, see "TASK E - POKER".
2. Updated some audio file.

### Version 3.04.04
1. New PREP_COUNTDOWN = 0 option (with TASK_DESCRIPTION = false): no prep time and no countdown, the task waits and the first launch with the prelaunch switch (held more than 0.6 s, then released) starts the working time and the first flight together. A quick pull while waiting is ignored. See "Start at the first launch (PREP_COUNTDOWN = 0)".
2. Task C (AULD) and Free Flight have no prep time and are not affected; PREP_COUNTDOWN 1..10 and TASK_DESCRIPTION = true work as before.
3. custom.lua changed (PREP_COUNTDOWN range 0..10, new launch handling): when upgrading, set it again starting from the new file.
4. Unit tests: start at the first launch for Task A, M and QT.

### Version 3.04.02
1. The configuration page and the task log viewer are no longer included in the `config` folder: they are now hosted on https://rcglideranalytics.com/F3kTraining/Configurator and https://rcglideranalytics.com/F3kTraining/TaskLog.
2. With the login the configurations can be saved on the site.
3. When upgrading, if custom.lua has changed in the new version it must be set again starting from the new version's custom.lua.

### Version 3.04.01
1. New TASK_LOG option in custom.lua: history of the tasks flown in TasksLog/yyyyMMdd.csv (one file per day), written once at the end of each task (END) or when it is stopped with the switch (STOP).
2. New TasksLog folder in F3K_TRAINING (it must be copied to the SD card: Lua scripts can't create folders).
3. New task log viewer page `config/tasklog.html`: flights against their targets, END / STOP sessions and a score normalized to 1000.
4. Configuration page: new navigation bar (Home / TaskLog) and TASK_LOG option.
5. Unit tests: task log tests, scripts now run without the Lua 'table' library as on the radio.

### Version 3.04
1. New TASK_DESCRIPTION option in custom.lua: prep countdown announced by the script from 10 (no more delay behind the task description), optional fast start without task description.
2. New configuration page `config/index.html` to edit custom.lua (switches, menu scroll input, task description, prep countdown) with radio switch layouts.

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
