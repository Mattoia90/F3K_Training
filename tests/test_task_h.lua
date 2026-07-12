local helper = require("tests.test_helper")

local function test_task_h_1234()
  print("- Testing Task H (1234)")
  local script = helper.select_and_load_task(7) -- Index 7: 1234
  helper.assert_eq(mock_env.taskState.name, "1234", "Task H name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  -- We clear sounds before the flight so we only verify flight countdown/count-up triggers
  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 57)  -- Target 1 (60s) - 3s
  helper.assert_timer_started(1, 0, "Flight 1 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s during count-up")
  helper.assert_number_played(45, "Should announce 45s during count-up")
  helper.assert_number_played(56, "Should announce 56s during count-up")

  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 117) -- Target 2 (120s) - 3s
  helper.assert_timer_started(1, 0, "Flight 2 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s during second flight")
  helper.assert_number_played(56, "Should announce 56s during second flight")

  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 177) -- Target 3 (180s) - 3s
  helper.assert_timer_started(1, 0, "Flight 3 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s during third flight")
  helper.assert_number_played(56, "Should announce 56s during third flight")

  mock_env.clearSounds()
  helper.simulate_flight_by_seconds(script, 237) -- Target 4 (240s) - 3s
  helper.assert_timer_started(1, 0, "Flight 4 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")
  helper.assert_number_played(30, "Should announce 30s during fourth flight")
  helper.assert_number_played(56, "Should announce 56s during fourth flight")

  -- Total should be 57 + 117 + 177 + 237 = 588
  helper.assert_eq(mock_env.taskState.times.getTotal(), 588, "All 4 flights scored with almost perfect times")
end

local function test_task_h_out_of_order()
  print("- Testing Task H (1234 - Out of Order Targets)")
  local script = helper.select_and_load_task(7)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 237) -- Achieves 240s target first
  helper.assert_timer_started(1, 0, "Flight 1 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 117) -- Achieves 120s target
  helper.assert_timer_started(1, 0, "Flight 2 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 177) -- Achieves 180s target
  helper.assert_timer_started(1, 0, "Flight 3 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 57)  -- Achieves 60s target
  helper.assert_timer_started(1, 0, "Flight 4 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getTotal(), 588, "Score is still 588s when flown out of order")
end

local function test_task_h_3x3min()
  print("- Testing Task H (1234 - 3x3min flight asserting 8 minute total)")
  local script = helper.select_and_load_task(7)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 180) -- Flight 1: 180s (Target 3 achieved -> 180s)
  helper.assert_timer_started(1, 0, "Flight 1 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 180) -- Flight 2: 180s (Target 4 achieved -> 180s)
  helper.assert_timer_started(1, 0, "Flight 2 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 180) -- Flight 3: 180s (Target 2 achieved -> capped at 120s)
  helper.assert_timer_started(1, 0, "Flight 3 timer starts with 0s (count-up)")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  -- Total score should be 180 + 180 + 120 = 480 seconds (8 minutes)
  helper.assert_eq(mock_env.taskState.times.getTotal(), 480, "Total score should be 480s (8 minutes)")
end

test_task_h_1234()
test_task_h_out_of_order()
test_task_h_3x3min()
