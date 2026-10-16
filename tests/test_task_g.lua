local helper = require("tests.test_helper")

local function test_task_g_5x2()
  print("- Testing Task G (5x2)")
  local script = helper.select_and_load_task(6) -- Index 6: 5x2
  helper.assert_eq(mock_env.taskState.name, "5x2", "Task G name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 117) -- Almost perfect (120 - 3)
  helper.assert_timer_started(1, 120, "Flight 1 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 117)
  helper.assert_timer_started(1, 120, "Flight 2 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 117)
  helper.assert_timer_started(1, 120, "Flight 3 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 117)
  helper.assert_timer_started(1, 120, "Flight 4 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  helper.simulate_flight(script, 117)
  helper.assert_timer_started(1, 120, "Flight 5 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 5 timer stops on landing")

  -- Flights: 117, 117, 117, 117, 117
  -- Best 5: 117, 117, 117, 117, 117 -> sum: 585
  helper.assert_eq(mock_env.taskState.times.getTotal(5), 585, "Best five flights capped at 117s counted")
end

test_task_g_5x2()
