local helper = require("tests.test_helper")

local function test_task_j_last_three()
  print("- Testing Task J (Last Three)")
  local script = helper.select_and_load_task(9) -- Index 9: Last three
  helper.assert_eq(mock_env.taskState.name, "Last three", "Task J name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 50)  -- Discarded
  helper.assert_timer_started(1, 180, "Flight 1 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 2 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 3 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 4 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  -- Last 3 flights: 120, 120, 120 -> sum: 360
  helper.assert_eq(mock_env.taskState.times.getTotal(), 360, "Only last three flights counted (50s discarded)")
end

local function test_task_j_dont_throw()
  print("- Testing Task J (Don't Throw Scenario)")
  local script = helper.select_and_load_task(9)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 150) -- Flight 1 (150s)
  helper.simulate_flight(script, 150) -- Flight 2 (150s)
  mock_env.clearSounds()
  helper.simulate_flight(script, 150) -- Flight 3 (150s). Window remaining: 600 - 16 - 152*3 = 128s. 150 > 128, so stop sound triggers.
  helper.assert_sound_played("stop%.wav", "Should play 'stop' (don't throw) when remaining time is less than oldest flight")
end

test_task_j_last_three()
test_task_j_dont_throw()
