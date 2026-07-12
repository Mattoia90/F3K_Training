local helper = require("tests.test_helper")

local function test_task_b_10m()
  print("- Testing Task B (Last Two - 10 min)")
  local script = helper.select_and_load_task(2) -- Index 2: Last two (10m)
  helper.assert_eq(mock_env.taskState.name, "Last two", "Task B name matches")
  helper.assert_eq(mock_env.taskState.WINDOW_TIME, 600, "10 min window")

  helper.assert_timer_started(0, 16, "Prep timer should start with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer should start with 600s")

  helper.simulate_flight(script, 50)  -- Discarded
  helper.assert_timer_started(1, 240, "Flight 1 timer starts with 240s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 150) -- Scored (150s)
  helper.assert_timer_started(1, 240, "Flight 2 timer starts with 240s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 150) -- Scored (150s)
  helper.assert_timer_started(1, 240, "Flight 3 timer starts with 240s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getTotal(), 300, "Score of 300s (50s discarded)")
end

local function test_task_b_7m()
  print("- Testing Task B (Last Two - 7 min)")
  local script7 = helper.select_and_load_task(15) -- Index 15: Last two (7m)
  helper.assert_eq(mock_env.taskState.name, "Last two", "Task B (7m) name matches")
  helper.assert_eq(mock_env.taskState.WINDOW_TIME, 420, "7 min window")

  helper.assert_timer_started(0, 16, "Prep timer should start with 16s")
  helper.simulate_prep_time(script7, 16)
  helper.assert_timer_started(0, 420, "Working window timer should start with 420s")

  helper.simulate_flight(script7, 50)  -- Discarded
  helper.assert_timer_started(1, 180, "Flight 1 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script7, 100) -- Scored (100s)
  helper.assert_timer_started(1, 180, "Flight 2 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script7, 100) -- Scored (100s)
  helper.assert_timer_started(1, 180, "Flight 3 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getTotal(), 200, "Score of 200s (50s discarded)")
end

local function test_task_b_dont_throw()
  print("- Testing Task B (Don't Throw Scenario)")
  local script = helper.select_and_load_task(2)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 220) -- Flight 1 (220s)
  mock_env.clearSounds()
  helper.simulate_flight(script, 220) -- Flight 2 (220s). Window remaining: 600 - 16 - 222 - 222 = 140s. 220 > 140, so stop sound triggers.
  helper.assert_sound_played("stop%.wav", "Should play 'stop' (don't throw) when remaining time is less than older flight")
end

test_task_b_10m()
test_task_b_7m()
test_task_b_dont_throw()
