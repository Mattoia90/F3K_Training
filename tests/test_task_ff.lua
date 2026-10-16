local helper = require("tests.test_helper")

local function test_task_ff_free_flight()
  print("- Testing Task FF (Free Flight)")
  local script = helper.select_and_load_task(18) -- Index 18: Free Flight
  helper.assert_eq(mock_env.taskState.name, "Free Flight", "Task FF name matches")

  -- In Free Flight, the transition from state 2 (started) to state 4 (landed) is automatic
  -- Let's run display loop once to trigger this transition
  script.run()
  helper.assert_timer_started(1, 0, "Task session timer (timer2) starts with 0s")
  helper.assert_eq(mock_env.taskState.state, 4, "State should be Landed (State 4)")

  helper.simulate_flight(script, 297)
  helper.assert_timer_started(0, 0, "Flight 1 timer (timer1) starts with 0s")
  helper.assert_timer_stopped(0, "Flight 1 timer (timer1) stops on landing")

  helper.simulate_flight(script, 596)
  helper.assert_timer_started(0, 0, "Flight 2 timer (timer1) starts with 0s")
  helper.assert_timer_stopped(0, "Flight 2 timer (timer1) stops on landing")

  helper.assert_eq(mock_env.taskState.times.getVal(9), 297, "First flight recorded")
  helper.assert_eq(mock_env.taskState.times.getVal(10), 596, "Second flight recorded")
end

test_task_ff_free_flight()
