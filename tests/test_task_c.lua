local helper = require("tests.test_helper")

local function test_task_c_auld()
  print("- Testing Task C (AULD)")
  local script = helper.select_and_load_task(3) -- Index 3: AULD
  helper.assert_eq(mock_env.taskState.name, "AULD", "Task C name matches")

  -- AULD has no prep time timer starting (it just goes straight to landed/awaiting launch)
  script.run()
  helper.assert_eq(mock_env.taskState.state, 4, "Initial state should be Landed (State 4)")

  helper.simulate_flight(script, 177) -- Almost perfect (180 - 3)
  helper.assert_timer_started(1, 180, "Flight 1 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 177)
  helper.assert_timer_started(1, 180, "Flight 2 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 177)
  helper.assert_timer_started(1, 180, "Flight 3 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.simulate_flight(script, 177)
  helper.assert_timer_started(1, 180, "Flight 4 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 4 timer stops on landing")

  helper.simulate_flight(script, 177)
  helper.assert_timer_started(1, 180, "Flight 5 timer starts with 180s target")
  helper.assert_timer_stopped(1, "Flight 5 timer stops on landing")

  -- Total should be: 177 * 5 = 885
  helper.assert_eq(mock_env.taskState.times.getTotal(), 885, "All 5 flights counted at 177s each")
  helper.assert_eq(mock_env.taskState.state, 5, "Task C should finish and go to State 5 after 5 flights")
end

local function test_task_c_early_reset()
  print("- Testing Task C (AULD - Early Reset Scenario)")
  local script = helper.select_and_load_task(3)
  script.run() -- transition to landed state (4)

  -- Launch and fly for 50s
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  script.run()
  helper.assert_timer_started(1, 180, "Flight timer starts with 180s target")

  mock_env.advanceTime(50)
  script.run() -- state is 3 (flying)

  -- Now turn MenuSwitch (SC) off (SC = -1024)
  mock_env.setSwitch("sc", -1024)
  script.run() -- triggers earlyReset()
  helper.assert_timer_stopped(1, "Flight timer stops on early reset")

  helper.assert_eq(mock_env.taskState.state, 1, "State should reset to 1 after early reset")
  helper.assert_eq(mock_env.taskState.flightCount, 0, "Flight count should reset to 0")
end

local function test_task_c_automatic_timeout()
  print("- Testing Task C (AULD - Automatic Target Timeout)")
  local script = helper.select_and_load_task(3)
  script.run() -- transition to landed state (4)

  -- Launch: pull preset switch
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  script.run() -- now flying (State 3)
  helper.assert_timer_started(1, 180, "Flight timer starts with 180s target")

  -- Advance time by 185 seconds (exceeding 180s target)
  mock_env.advanceTime(185)
  script.run() -- runs flyingState, triggers auto-timeout
  helper.assert_timer_stopped(1, "Flight timer stops on timeout")

  helper.assert_eq(mock_env.taskState.times.getVal(5), 180, "Automatically recorded 180s target")
  helper.assert_eq(mock_env.taskState.state, 4, "State should be Landed (State 4) after timeout")
end

test_task_c_auld()
test_task_c_early_reset()
test_task_c_automatic_timeout()
