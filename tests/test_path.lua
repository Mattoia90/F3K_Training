local helper = require("tests.test_helper")

-- Training Path (trainingpath.lua): prep -> test flight -> no fly -> task, for every task of TR_PATHS/Level_1.lua (A, D)
local real_io = io
local logText

local function install_io_stub()
  logText = ""
  io = {
    open = function(path, mode)
      if not path:match("TasksLog/") then
        return real_io.open(path, mode)
      end
      if mode == "r" then return {} end -- file exists: no header
      return {}
    end,
    write = function(f, ...) logText = logText .. table.concat({ ... }) end,
    close = function(f) end
  }
end

local function test_path_run()
  print("- Testing Training Path (Level_1: A, D)")
  dir = function() -- EdgeTX dir() iterator over TR_PATHS/
    local list, i = { "readme.txt", "Level_1.lua" }, 0
    return function() i = i + 1; return list[i] end
  end

  local script = helper.select_and_load_task(21) -- TP is the last menu entry
  F3KConfig.TASK_LOG = true
  install_io_stub()
  script.run() -- file list, trigger released

  mock_env.clearSounds()
  mock_env.setSwitch("se", 1024) -- pull the trigger: start the path
  script.run()
  mock_env.setSwitch("se", -1024)
  helper.assert_sound_played("prep%.wav$", "Prep time announced")
  helper.assert_sound_played("taska%.wav$", "First task described at the prep time")
  helper.assert_eq(F3KPath, nil, "No task running during the prep time")

  mock_env.advanceTime(180); script.run()
  helper.assert_sound_played("testfl%.wav$", "Test flight after the prep time")
  mock_env.advanceTime(45); script.run()
  helper.assert_sound_played("nofly%.wav$", "No fly after the test flight")
  mock_env.advanceTime(60); script.run()
  helper.assert_eq(F3KPath and F3KPath.index, 1, "Task 1 running after the no fly time")

  script.run() -- task: reset -> started
  script.run() -- no prep time inside a path: started -> working time
  helper.assert_eq(mock_env.taskState.state, 4, "Working time starts right away")

  helper.simulate_flight(script, 120)
  mock_env.advanceTime(600); script.run()
  helper.assert_eq(logText, "2026-11-04;15:32:10;Last Flight;600;END;;Level_1|20261104153210|1/2;120\n",
    "Task line carries the path run")
  helper.assert_eq(F3KPath, nil, "Back to the prep time of task 2")
  helper.assert_sound_played("taskd%.wav$", "Second task described")

  -- abort in the middle of task 2: STOP is logged with the path
  mock_env.advanceTime(180); script.run()
  mock_env.advanceTime(45); script.run()
  mock_env.advanceTime(60); script.run()
  script.run(); script.run()
  helper.simulate_flight(script, 30)
  logText = ""
  mock_env.setSwitch("sc", 0)
  script.run()
  helper.assert_eq(logText:match(";STOP;;Level_1|20261104153210|2/2;30\n$") ~= nil, true, "Aborted task logged as STOP")
  helper.assert_eq(F3KPath, nil, "Path cleared after the abort")

  io = real_io
  dir = nil
end

test_path_run()
