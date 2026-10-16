local helper = require("tests.test_helper")

local function test_task_f_3_out_of_6()
  print("- Testing Task F (3 out of 6)")
  local script = helper.select_and_load_task(5) -- Index 5: 3 out of 6
  helper.assert_eq(mock_env.taskState.name, "3oo6", "Task F name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 5)   -- Discarded
  helper.assert_timer_started(1, 180, "Flight 1 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 2 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 5)   -- Discarded
  helper.assert_timer_started(1, 180, "Flight 3 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 4 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  helper.simulate_flight(script, 5)   -- Discarded
  helper.assert_timer_started(1, 180, "Flight 5 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 5 timer stops on landing")

  helper.simulate_flight(script, 120) -- Scored (120s)
  helper.assert_timer_started(1, 180, "Flight 6 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 6 timer stops on landing")

  -- Best 3 are: 120, 120, 120 -> sum is 360
  helper.assert_eq(mock_env.taskState.times.getTotal(3), 360, "Best three flights out of six counted")
  helper.assert_sound_played("stop%.wav", "Should play 'stop' at the end of 6 flights")
  helper.assert_eq(mock_env.taskState.state, 5, "Task F should finish and go to State 5 after 6 flights")
end

local function test_task_f_cant_improve()
  print("- Testing Task F (Can't Improve Scenario)")
  local script = helper.select_and_load_task(5)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 150) -- Flight 1 (150s)
  helper.simulate_flight(script, 150) -- Flight 2 (150s)
  mock_env.clearSounds()
  helper.simulate_flight(script, 150) -- Flight 3 (150s). Window remaining: 600 - 16 - 152*3 = 128s. 150 > 128, so cant improve triggers in landedState.
  
  -- Run task base loop to trigger landedState checks
  script.run()
  helper.assert_sound_played("cant%.wav", "Should play 'cant' when remaining time is less than 3rd best flight")
end

test_task_f_3_out_of_6()
test_task_f_cant_improve()
