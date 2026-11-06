local helper = require("tests.test_helper")

-- Throttle positions (MenuScrollEncoder): f = (thr + 1024) / 2048
local THR_TOP = 1024		-- W
local THR_HALF = 0		-- 50%
local THR_QUARTER = -512	-- 25%
local THR_BOTTOM = -1024	-- 0% -> minimum target (10s)

local function task()
  return mock_env.taskState
end

local function run(script, seconds)
  if seconds and seconds > 0 then
    mock_env.advanceTime(seconds)
  end
  script.run()
end

local function count_files(pattern)
  local n = 0
  for _, s in ipairs(mock_env.getPlayedSounds()) do
    if s.type == "file" and s.value:match(pattern) then n = n + 1 end
  end
  return n
end

-- Window starts at 600s after the 16s prep time
local function load_and_start(idx)
  local script = helper.select_and_load_task(idx or 17)
  helper.simulate_prep_time(script, 16)
  return script
end


local function test_default_is_w()
  print("- Testing Task E (Poker): untouched stick = W, credited at the end of the window")
  local script = helper.select_and_load_task(17)
  helper.assert_eq(task().name, "Poker", "Task E name matches")
  helper.assert_eq(task().WINDOW_TIME, 600, "Task E window is 600s")
  helper.assert_sound_played("taske%.wav", "Task E description played")
  helper.assert_eq(task().selW, true, "Default selection after menu is W (stick left where the menu was)")

  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window starts with 600s")
  run(script, 10)
  helper.assert_eq(task().selW, true, "Still W in the window")
  helper.assert_eq(task().selected, 590, "W selection follows the remaining time")

  mock_env.clearSounds()
  helper.simulate_flight(script, 600)	-- still flying at the end of the window
  helper.assert_timer_started(1, 588, "W flight timer starts with the remaining time")
  helper.assert_sound_played("endwt%.wav", "W announced at launch")
  helper.assert_eq(task().state, 5, "Task ended with the window")
  helper.assert_eq(task().times.getTotal(), 588, "W credited with the flight time up to the end of the window")
end


local function test_target_in_prep_time()
  print("- Testing Task E: target chosen during the prep time")
  local script = helper.select_and_load_task(17)
  mock_env.setSwitch("thr", THR_HALF)
  run(script, 1)
  helper.assert_eq(task().selW, false, "Moving the stick leaves the W default")
  helper.assert_eq(task().selected, 300, "50% of 600s during prep time")

  helper.simulate_prep_time(script, 15)
  mock_env.clearSounds()
  helper.simulate_flight(script, 30)
  helper.assert_timer_started(1, 300, "Target chosen during prep is locked at the first launch")
  helper.assert_sound_played("target%.wav", "Target announced")
  helper.assert_number_played(300, "Target value announced")
  helper.assert_eq(task().locked, 300, "Target locked after a failed attempt")
end


local function test_launch_start()
  print("- Testing Task E: no prep time (PREP_COUNTDOWN=0), target chosen before the first launch")
  mock_env.setTime(0)
  mock_env.clearSounds()
  mock_env.clearTimerEvents()
  mock_env.setSwitch("sc", -1024)
  mock_env.setSwitch("se", -1024)
  mock_env.setSwitch("thr", math.floor(1024 - 16.5 * (2049 / 20)))	-- menu index 17
  local script = dofile("./Telemetry/f3k.lua")
  F3KConfig.TASK_DESCRIPTION = false
  F3KConfig.PREP_COUNTDOWN = 0
  script.run()
  mock_env.setSwitch("sc", 1024)
  script.run()
  script.run()
  helper.assert_eq(task().state, 2, "Waiting for the first launch")

  mock_env.setSwitch("thr", THR_QUARTER)
  run(script, 5)
  helper.assert_eq(task().selected, 150, "25% of 600s while waiting")

  helper.simulate_flight(script, 20)
  helper.assert_timer_started(0, 600, "Working time started at the launch")
  helper.assert_timer_started(1, 150, "First flight started with the chosen target")
  helper.assert_eq(task().locked, 150, "Target locked")

  F3KConfig.TASK_DESCRIPTION = true
  F3KConfig.PREP_COUNTDOWN = 10
end


local function test_lock_and_three_targets()
  print("- Testing Task E: strict lock, 3 targets, total")
  local script = load_and_start(17)
  mock_env.setSwitch("thr", THR_QUARTER)
  run(script)
  helper.assert_eq(task().selected, 150, "25% of 600s")

  -- Flight 1: fails the 150s target
  helper.simulate_flight(script, 100)
  helper.assert_timer_started(1, 150, "Flight 1 locked at 150s")
  helper.assert_eq(task().state, 4, "Landed")
  helper.assert_eq(task().locked, 150, "Failed target stays locked")

  -- Moving the stick (even to W) has no effect while locked
  mock_env.setSwitch("thr", THR_TOP)
  run(script, 1)
  helper.assert_eq(task().locked, 150, "Stick ignored while locked")
  helper.assert_eq(task().lockedW, false, "W not allowed while a target is locked")

  -- Flight 2: reaches 150s
  mock_env.clearTimerEvents()
  mock_env.clearSounds()
  helper.simulate_flight(script, 160)
  helper.assert_timer_started(1, 150, "Flight 2 reuses the locked target")
  helper.assert_sound_played("welldone%.wav", "Well done when the target is reached")
  helper.assert_eq(#task().targets, 1, "First target credited")
  helper.assert_eq(task().locked, nil, "Unlocked after landing")
  run(script)
  helper.assert_eq(task().selW, true, "Back to the W default after a reached target")

  -- Flight 3: 25% of the remaining time (rounded up to 10s)
  mock_env.setSwitch("thr", THR_QUARTER)
  run(script)
  local remaining = task().timer1.getVal()
  local expected = math.floor(0.25 * math.ceil(remaining / 10) * 10 / 10) * 10
  helper.assert_eq(task().selected, expected, "25% of the remaining time, 10s steps")
  mock_env.clearTimerEvents()
  helper.simulate_flight(script, expected + 5)
  helper.assert_timer_started(1, expected, "Flight 3 locked at the selection")
  helper.assert_eq(#task().targets, 2, "Second target credited")

  -- Flight 4: minimum target, 3rd credit ends the task
  mock_env.setSwitch("thr", THR_BOTTOM)
  run(script)
  helper.assert_eq(task().selected, 10, "Stick at the bottom = 10s")
  mock_env.clearSounds()
  helper.simulate_flight(script, 15)
  helper.assert_eq(#task().targets, 3, "Third target credited")
  helper.assert_eq(task().state, 5, "Task ends after 3 targets")
  helper.assert_sound_played("taskend%.wav", "End of task announced")
  helper.assert_eq(task().times.getTotal(), 150 + expected + 10, "Total is the sum of the targets")
end


local function test_w_landed_early()
  print("- Testing Task E: W landed before the end of the window")
  local script = load_and_start(17)
  helper.simulate_flight(script, 50)
  helper.assert_eq(task().lockedW, true, "W locked")
  helper.assert_eq(task().state, 5, "One attempt only: task ended")
  helper.assert_eq(task().times.getTotal(), 0, "No score")
end


local function test_cant()
  print("- Testing Task E: locked target longer than the remaining time")
  local script = load_and_start(17)
  mock_env.setSwitch("thr", 820)	-- ~90%: 540s
  run(script)
  helper.assert_eq(task().selected, 540, "90% of 600s")
  helper.simulate_flight(script, 100)
  mock_env.clearSounds()
  helper.simulate_flight(script, 10)
  helper.assert_sound_played("cant%.wav", "Can't reach the locked target anymore")
  helper.assert_eq(count_files("welldone"), 0, "No well done")
end


local function test_task_ee()
  print("- Testing Task EE (Poker 15 min)")
  local script = helper.select_and_load_task(18)
  helper.assert_eq(task().name, "Poker 15", "Task EE name matches")
  helper.assert_eq(task().WINDOW_TIME, 900, "Task EE window is 900s")
  helper.assert_sound_played("taskee%.wav", "Task EE description played")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 900, "Working window starts with 900s")
  mock_env.setSwitch("thr", THR_HALF)
  run(script)
  helper.assert_eq(task().selected, 450, "50% of 900s")
end


test_default_is_w()
test_target_in_prep_time()
test_launch_start()
test_lock_and_three_targets()
test_w_landed_early()
test_cant()
test_task_ee()
