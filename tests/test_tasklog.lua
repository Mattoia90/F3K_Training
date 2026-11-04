local helper = require("tests.test_helper")

-- Replace the global io with a stub that captures the TasksLog file writes
-- (other paths, like the mocked dofile's existence check, go to the real io)
local real_io = io
local log

local function install_io_stub(existing)
  log = { opens = {}, text = "" }
  io = {
    open = function(path, mode)
      if not path:match("TasksLog/") then
        return real_io.open(path, mode)
      end
      table.insert(log.opens, { path = path, mode = mode })
      if mode == "r" then
        return existing and {} or nil
      end
      return {}
    end,
    write = function(f, ...)
      log.text = log.text .. table.concat({ ... })
    end,
    close = function(f) end
  }
end

local function restore_io()
  io = real_io
end


local function test_log_end_of_task()
  print("- Testing task log (Task A, end of window)")
  local script = helper.select_and_load_task(1)
  F3KConfig.TASK_LOG = true
  install_io_stub(false)

  helper.simulate_prep_time(script, 16)
  helper.simulate_flight(script, 50)
  helper.simulate_flight(script, 200)
  helper.assert_eq(#log.opens, 0, "Nothing written during the task")

  mock_env.advanceTime(600)
  script.run()
  restore_io()

  local flights = mock_env.taskState.times.getFlights()
  helper.assert_eq(#flights, 2, "Both flights are kept (task A scores only the last one)")
  helper.assert_eq(flights[2], 200, "Flights kept in the order flown")
  helper.assert_eq(log.opens[2] and log.opens[2].path, "/SCRIPTS/F3K_TRAINING/TasksLog/20261104.csv", "One file per day")
  helper.assert_eq(log.opens[2] and log.opens[2].mode, "a", "File opened in append mode")
  helper.assert_eq(log.text,
    "Date;Time;Task;Window;Status;Flights\n" ..
    "2026-11-04;15:32:10;Last Flight;600;END;" .. table.concat(flights, ";") .. "\n",
    "Header + task line written")

  -- Going back to stop from the end state must not log the task again
  install_io_stub(true)
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()
  helper.assert_eq(#log.opens, 0, "No second line after the end of the task")
end


local function test_log_stopped_task()
  print("- Testing task log (Task A, stopped by the user)")
  local script = helper.select_and_load_task(1)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)

  helper.simulate_prep_time(script, 16)
  helper.simulate_flight(script, 80)
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()

  helper.assert_eq(log.text:match("^[^\n]*"):sub(1, 4), "2026", "No header when the file already exists")
  helper.assert_eq(log.text:match(";(%u+);[%d;]+\n$"), "STOP", "Stopped task logged as STOP")
end


local function test_log_free_flight()
  print("- Testing task log (Free Flight, stopped by the user)")
  local script = helper.select_and_load_task(18)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)

  script.run()
  helper.simulate_flight(script, 120)
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()

  helper.assert_eq(log.text:match(";Free Flight;0;STOP;%d+\n$") ~= nil, true, "Free flight logged as STOP")
end


local function test_log_disabled()
  print("- Testing task log (disabled)")
  local script = helper.select_and_load_task(1)
  F3KConfig.TASK_LOG = false
  install_io_stub(false)

  helper.simulate_prep_time(script, 16)
  helper.simulate_flight(script, 80)
  mock_env.advanceTime(600)
  script.run()
  restore_io()

  helper.assert_eq(#log.opens, 0, "No file written when TASK_LOG = false")
end


test_log_end_of_task()
test_log_stopped_task()
test_log_free_flight()
test_log_disabled()
mock_env.setSwitch("sc", -1024)
