Task history log folder.
When TASK_LOG = true in custom.lua, one CSV file per day (yyyyMMdd.csv) is written here.
Keep this folder on the SD card: Lua scripts can't create folders.
Line format: Date;Time;Task;Window;Status;Heights;flight times (s)...
Heights = launch heights in meters separated by spaces (one per launch), empty without altitude sensor.
