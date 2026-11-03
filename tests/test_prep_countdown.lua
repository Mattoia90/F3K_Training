local helper = require("tests.test_helper")

-- Same as helper.select_and_load_task, but lets the test override
-- F3KConfig.TASK_DESCRIPTION (custom.lua) before the task starts.
local function load_task(idx, description, countdown)
  mock_env.setTime(0)
  mock_env.clearSounds()
  mock_env.clearTimerEvents()
  mock_env.setSwitch("sc", -1024)
  mock_env.setSwitch("se", -1024)

  local num_tasks = 18
  local thr_val = math.floor(1024 - ((idx - 1) + 0.5) * (2049 / num_tasks))
  mock_env.setSwitch("thr", thr_val)

  local script = dofile("./Telemetry/f3k.lua")
  F3KConfig.TASK_DESCRIPTION = description
  F3KConfig.PREP_COUNTDOWN = countdown or 10
  script.run()
  mock_env.setSwitch("sc", 1024)
  script.run()
  script.run()
  return script
end

local function count_sounds(kind)
  local n = 0
  for _, s in ipairs(mock_env.getPlayedSounds()) do
    if s.type == kind then n = n + 1 end
  end
  return n
end

local function countdown_sequence(from)
  local seq = {}
  for v = from or 10, 1, -1 do
    table.insert(seq, { type = "number", value = v })
  end
  return seq
end

-- Runs the prep time one second at a time
local function run_prep(script, seconds)
  for _ = 1, seconds do
    mock_env.advanceTime(1)
    script.run()
  end
end

local function test_with_description(idx, name, prepTime)
  print("- Testing prep countdown with task description: " .. name)
  local script = load_task(idx, true)
  helper.assert_timer_started(0, prepTime, name .. ": prep timer starts with " .. prepTime .. "s")
  helper.assert_eq(count_sounds("file"), 1, name .. ": task description played")

  run_prep(script, prepTime)
  local seq = { { type = "file", value = "task" } }
  for _, s in ipairs(countdown_sequence()) do table.insert(seq, s) end
  helper.assert_sound_sequence(seq, name .. ": description then countdown 10..1")
  helper.assert_eq(count_sounds("number"), 10, name .. ": only 10 numbers announced")
  helper.assert_eq(mock_env.taskState.state, 4, name .. ": working time started after prep")
end

local function test_without_description(idx, name, countdown, expected)
  expected = expected or countdown
  print(string.format("- Testing prep countdown without task description: %s (PREP_COUNTDOWN=%s)", name, tostring(countdown)))
  local script = load_task(idx, false, countdown)
  helper.assert_timer_started(0, expected, name .. ": short prep timer starts with " .. expected .. "s")
  helper.assert_eq(count_sounds("number"), 1, name .. ": first number announced immediately")

  run_prep(script, expected - 1)
  helper.assert_eq(mock_env.taskState.state, 2, name .. ": still in prep time before " .. expected .. "s")
  run_prep(script, 1)
  helper.assert_sound_sequence(countdown_sequence(expected), name .. ": countdown " .. expected .. "..1, no description")
  helper.assert_eq(count_sounds("file"), 0, name .. ": no task description played")
  helper.assert_eq(count_sounds("number"), expected, name .. ": only " .. expected .. " numbers announced")
  helper.assert_eq(mock_env.taskState.state, 4, name .. ": working time started after " .. expected .. "s")
end

local function test_no_prep_task(idx, name)
  print("- Testing task description option on task without prep time: " .. name)
  load_task(idx, true)
  helper.assert_eq(count_sounds("file"), 1, name .. ": description played when enabled")
  load_task(idx, false)
  helper.assert_eq(count_sounds("file"), 0, name .. ": description not played when disabled")
end

test_with_description(1, "Task A", 16)
test_without_description(1, "Task A", 10)
test_without_description(1, "Task A", 5)
test_without_description(1, "Task A", 30, 10)	-- out of range: limited to 10
test_with_description(12, "Task M", 20)
test_without_description(12, "Task M", 10)
test_without_description(12, "Task M", 5)
test_no_prep_task(3, "Task C")
test_no_prep_task(18, "Free Flight")

-- restore the default for any following test
F3KConfig.TASK_DESCRIPTION = true
