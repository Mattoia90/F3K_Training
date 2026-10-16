local helper = require("tests.test_helper")

local function test_task_qt_practice()
  print("- Testing Task QT (QT Practice)")
  local script = helper.select_and_load_task(17) -- Index 17: QT Practice
  helper.assert_eq(mock_env.taskState.name, "QT practice", "Task QT name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 42) -- Flight 1: 42s (delta = 3)
  helper.assert_timer_started(1, 45, "Flight 1 timer starts with 45s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s countdown")
  helper.assert_number_played(15, "Should announce 15s countdown")
  helper.assert_number_played(5, "Should announce 5s countdown")

  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 40) -- Flight 2: 40s (delta = 5)
  helper.assert_timer_started(1, 45, "Flight 2 timer starts with 45s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s countdown during second flight")
  helper.assert_number_played(15, "Should announce 15s countdown during second flight")
  helper.assert_number_played(5, "Should announce 5s countdown during second flight")

  -- Assert times (descending sort order)
  helper.assert_eq(mock_env.taskState.times.getVal(1), 42, "First flight recorded")
  helper.assert_eq(mock_env.taskState.times.getVal(2), 40, "Second flight recorded")

  -- Assert delta calculations
  helper.assert_eq(mock_env.taskState.deltas.min, 3, "Min delta matches")
  helper.assert_eq(mock_env.taskState.deltas.max, 5, "Max delta matches")
  helper.assert_eq(mock_env.taskState.deltas.avg, 4, "Avg delta matches")
end

test_task_qt_practice()
