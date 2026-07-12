local helper = require("tests.test_helper")

local function test_task_m_huge_ladder()
  print("- Testing Task M (Huge Ladder)")
  local script = helper.select_and_load_task(12) -- Index 12: Huge Ladder
  helper.assert_eq(mock_env.taskState.name, "Huge Ladder", "Task M name matches")

  helper.assert_timer_started(0, 20, "Prep timer starts with 20s")
  helper.simulate_prep_time(script, 20)
  helper.assert_timer_started(0, 900, "Working window timer starts with 900s")

  helper.simulate_flight(script, 177) -- Target 1 (180s) - 3s
  helper.assert_timer_started(1, 180, "Flight 1 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 297) -- Target 2 (300s) - 3s
  helper.assert_timer_started(1, 300, "Flight 2 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 417) -- Target 3 (420s) - 3s
  helper.assert_timer_started(1, 420, "Flight 3 timer starts with 420s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")
  helper.assert_timer_stopped(0, "Working window timer stops when task finishes")

  helper.assert_eq(mock_env.taskState.times.getVal(1), 177, "First target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(2), 297, "Second target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(3), 417, "Third target achieved")
  helper.assert_eq(mock_env.taskState.times.getTotal(), 537, "Total score matches sum of flights capped at 180s")
end

test_task_m_huge_ladder()
