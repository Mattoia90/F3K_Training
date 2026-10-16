local helper = require("tests.test_helper")

local function test_task_a_10m()
  print("- Testing Task A (Last Flight - 10 min)")
  local script = helper.select_and_load_task(1) -- Index 1: Last flight (10m)
  helper.assert_eq(mock_env.taskState.name, "Last Flight", "Task A name matches")
  helper.assert_eq(mock_env.taskState.WINDOW_TIME, 600, "10 min window")
  helper.assert_sound_played("taska%.wav", "Startup task name should be announced")

  helper.assert_timer_started(0, 16, "Prep timer should start with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer should start with 600s")

  helper.simulate_flight(script, 50)  -- Discarded
  helper.assert_timer_started(1, 300, "Flight 1 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 200) -- Scored (200s). Window remaining: 600 - 16 - 52 - 202 = 330s. 200 < 330, so no stop sound.
  helper.assert_timer_started(1, 300, "Flight 2 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")
  helper.assert_eq(mock_env.taskState.times.getTotal(), 200, "Score of 200s")

  -- Let's finish the task to trigger taskend sound
  mock_env.clearSounds()
  mock_env.advanceTime(600) -- Exceed 10 min window
  script.run()
  helper.assert_timer_stopped(0, "Working window timer stops on window end")
  helper.assert_sound_played("taskend%.wav", "Should play 'taskend' when window expires")
end

local function test_task_a_7m()
  print("- Testing Task A (Last Flight - 7 min)")
  local script7 = helper.select_and_load_task(14) -- Index 14: Last flight (7m)
  helper.assert_eq(mock_env.taskState.name, "Last Flight", "Task A (7m) name matches")
  helper.assert_eq(mock_env.taskState.WINDOW_TIME, 420, "7 min window")
  helper.assert_sound_played("taska%.wav", "Startup task name should be announced")

  helper.assert_timer_started(0, 16, "Prep timer should start with 16s")
  helper.simulate_prep_time(script7, 16)
  helper.assert_timer_started(0, 420, "Working window timer should start with 420s")

  helper.simulate_flight(script7, 50)  -- Discarded
  helper.assert_timer_started(1, 300, "Flight 1 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script7, 150) -- Scored (150s). Window remaining: 420 - 16 - 52 - 152 = 200s. 150 < 200, so no stop sound.
  helper.assert_timer_started(1, 300, "Flight 2 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")
  helper.assert_eq(mock_env.taskState.times.getTotal(), 150, "Score of 150s")
end

local function test_task_a_dont_throw()
  print("- Testing Task A (Don't Throw Scenario)")
  local script = helper.select_and_load_task(1)
  helper.simulate_prep_time(script, 16)

  -- Flight 1: 50s. (Remaining window = 600 - 16 - 52 = 532s)
  helper.simulate_flight(script, 50)

  -- Landed: advance time by 500s. (Remaining window = 532 - 500 = 32s)
  mock_env.advanceTime(500)
  script.run()

  -- Flight 2: launch (takes 2s). (Remaining window = 32 - 2 = 30s)
  -- Fly 28s. (Remaining window = 30 - 28 = 2s)
  mock_env.clearSounds()
  helper.simulate_flight(script, 28)

  helper.assert_sound_played("stop%.wav", "Should play 'stop' (don't throw) when remaining time is less than best flight")
end

test_task_a_10m()
test_task_a_7m()
test_task_a_dont_throw()
