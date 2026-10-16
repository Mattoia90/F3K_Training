local helper = require("tests.test_helper")

local function test_task_k_big_ladder()
  print("- Testing Task K (Big Ladder)")
  local script = helper.select_and_load_task(10) -- Index 10: Big Ladder
  helper.assert_eq(mock_env.taskState.name, "Big Ladder", "Task K name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 57)  -- Target 1 (60s) - 3s
  helper.assert_timer_started(1, 60, "Flight 1 timer starts with 60s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 87)  -- Target 2 (90s) - 3s
  helper.assert_timer_started(1, 90, "Flight 2 timer starts with 90s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 117) -- Target 3 (120s) - 3s
  helper.assert_timer_started(1, 120, "Flight 3 timer starts with 120s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 147) -- Target 4 (150s) - 3s
  helper.assert_timer_started(1, 150, "Flight 4 timer starts with 150s target")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  helper.simulate_flight(script, 177) -- Target 5 (180s) - 3s
  helper.assert_timer_started(1, 180, "Flight 5 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 5 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getVal(1), 57, "First target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(2), 87, "Second target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(3), 117, "Third target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(4), 147, "Fourth target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(5), 177, "Fifth target achieved")
  helper.assert_eq(mock_env.taskState.times.getTotal(), 585, "Total score matches sum of flights")
end

test_task_k_big_ladder()
