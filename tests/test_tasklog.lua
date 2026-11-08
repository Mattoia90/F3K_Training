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
    "Date;Time;Task;Window;Status;Heights;Flights\n" ..
    "2026-11-04;15:32:10;Last Flight;600;END;;" .. table.concat(flights, ";") .. "\n",
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
  local script = helper.select_and_load_task(20)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)

  script.run()
  helper.simulate_flight(script, 120)
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()

  helper.assert_eq(log.text:match(";Free Flight;0;STOP;;%d+\n$") ~= nil, true, "Free flight logged as STOP")
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


local function test_log_poker()
  print("- Testing task log (Task E Poker, 3 targets / EE stopped)")
  local script = helper.select_and_load_task(17)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)
  helper.simulate_prep_time(script, 16)
  -- after each reached target the selection is back to W: move the stick to choose 10s again
  local function pick_10s()
    mock_env.setSwitch("thr", -800)
    script.run()
    mock_env.setSwitch("thr", -1024)
    script.run()
  end
  pick_10s()
  helper.simulate_flight(script, 5)	-- failed
  helper.simulate_flight(script, 15)
  pick_10s()
  helper.simulate_flight(script, 15)
  helper.assert_eq(#log.opens, 0, "Nothing written before the 3rd target")
  pick_10s()
  helper.simulate_flight(script, 15)	-- 3rd target ends the task
  restore_io()
  -- the mock countdown stops at 0, so flights past the target are logged as the target
  helper.assert_eq(log.text:match(";Poker;600;END;;5;10;10;10\n$") ~= nil, true, "Poker logged as END with every flight")

  script = helper.select_and_load_task(18)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)
  helper.simulate_prep_time(script, 16)
  mock_env.setSwitch("thr", -512)
  script.run()
  helper.simulate_flight(script, 30)	-- failed 220s target
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()
  helper.assert_eq(log.text:match(";Poker 15;900;STOP;;30\n$") ~= nil, true, "Poker 15 logged as STOP")
end


local function test_log_launch_heights()
  print("- Testing task log (launch heights)")
  local script = helper.select_and_load_task(20)
  F3KConfig.TASK_LOG = true
  install_io_stub(true)
  script.run()
  mock_env.setAltitude(100)
  helper.simulate_flight(script, 5)	-- constant altitude: 0 m launch, still logged
  -- 2nd flight: launched at 100 m, climbs to 140 m, landed 5 s later: 40 m launch
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setAltitude(140)
  mock_env.advanceTime(5)
  script.run()
  mock_env.setSwitch("se", 1024)
  script.run()
  mock_env.setSwitch("se", -1024)
  script.run()
  mock_env.setSwitch("sc", 0)
  script.run()
  restore_io()
  mock_env.setAltitude(nil)
  helper.assert_eq(log.text:match(";STOP;0 40;5;5\n$") ~= nil, true, "Launch heights in their own column, before the flights")
end


test_log_end_of_task()
test_log_stopped_task()
test_log_launch_heights()
test_log_free_flight()
test_log_disabled()
test_log_poker()
mock_env.setSwitch("sc", -1024)
