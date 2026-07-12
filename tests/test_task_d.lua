local helper = require("tests.test_helper")

local function test_task_d_two_flights()
  print("- Testing Task D (Two Flights)")
  local script = helper.select_and_load_task(4) -- Index 4: Two flights
  helper.assert_eq(mock_env.taskState.name, "Two flights", "Task D name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight(script, 297) -- Almost perfect (300 - 3)
  helper.assert_timer_started(1, 300, "Flight 1 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 297) -- Almost perfect (300 - 3)
  helper.assert_timer_started(1, 300, "Flight 2 timer starts with 300s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  -- Total should be: 297 * 2 = 594
  helper.assert_eq(mock_env.taskState.times.getTotal(), 594, "Two flights sum capped at 297s each")
  helper.assert_eq(mock_env.taskState.state, 5, "Task D should transition to State 5 after two flights")
end

local function test_task_d_window_expires_during_flight()
  print("- Testing Task D (Two Flights - Window Expires Mid-Flight)")
  local script = helper.select_and_load_task(4)
  helper.simulate_prep_time(script, 16)

  -- Flight 1: 500s (lands). Remaining window: 600 - 502 = 98s.
  helper.simulate_flight(script, 500)

  -- Launch Flight 2: pull switch (takes 2s). Remaining window: 96s.
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  script.run() -- now flying

  -- Advance time by exactly the remaining 96s so the window expires
  mock_env.advanceTime(96)
  script.run() -- runs endOfWindow()

  helper.assert_eq(mock_env.taskState.times.getVal(2), 96, "Flight 2 score capped by remaining window time (96s)")
  helper.assert_eq(mock_env.taskState.state, 5, "Task D should transition to State 5 (End) on window expiration")
end

test_task_d_two_flights()
test_task_d_window_expires_during_flight()
