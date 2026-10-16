local helper = require("tests.test_helper")

local function test_task_l_one_flight()
  print("- Testing Task L (One Flight)")
  local script = helper.select_and_load_task(11) -- Index 11: One flight
  helper.assert_eq(mock_env.taskState.name, "One flight", "Task L name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 596) -- Almost perfect (599 - 3)
  helper.assert_timer_started(1, 599, "Flight 1 timer starts with 599s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")
  helper.assert_timer_stopped(0, "Working window timer stops on landing (task ends)")

  helper.assert_eq(mock_env.taskState.times.getTotal(), 596, "One flight counted")
  helper.assert_eq(mock_env.taskState.state, 5, "Task L finishes after one flight")
end

test_task_l_one_flight()
