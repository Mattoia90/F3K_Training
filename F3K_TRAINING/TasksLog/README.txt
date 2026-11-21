Task history log folder.
When TASK_LOG = true in custom.lua, one CSV file per day (yyyyMMdd.csv) is written here.
Keep this folder on the SD card: Lua scripts can't create folders.
Line format: Date;Time;Task;Window;Status;Heights;Path;flight times (s)...
Heights = launch heights in meters separated by spaces (one per launch), empty without altitude sensor.
Path = Training Path run as name|runId|index/total (runId = path start yyyyMMddHHmmss), empty outside a path.
Lines written before the Path column was added have no Path cell.
