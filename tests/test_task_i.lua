local helper = require("tests.test_helper")

local function test_task_i_best_three()
  print("- Testing Task I (Best Three)")
  local script = helper.select_and_load_task(8) -- Index 8: Best three
  helper.assert_eq(mock_env.taskState.name, "Best three", "Task I name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 197) -- Almost perfect (200 - 3)
  helper.assert_timer_started(1, 200, "Flight 1 timer starts with 200s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 197) -- Almost perfect (200 - 3)
  helper.assert_timer_started(1, 200, "Flight 2 timer starts with 200s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 197) -- Almost perfect (200 - 3)
  helper.assert_timer_started(1, 200, "Flight 3 timer starts with 200s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  -- Best 3: 197, 197, 197 -> sum: 591
  helper.assert_eq(mock_env.taskState.times.getTotal(3), 591, "Best three flights counted")
end

test_task_i_best_three()
