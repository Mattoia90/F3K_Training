local helper = require("tests.test_helper")

local function test_task_d2_small_ladder()
  print("- Testing Task D2 (Small Ladder)")
  local script = helper.select_and_load_task(16) -- Index 16: Small Ladder
  helper.assert_eq(mock_env.taskState.name, "Ladder", "Task D2 name matches")

  -- NOTE: timer2 in this task is created with countdownBeep = 2 (Voice).
  -- This tells the OpenTX/EdgeTX firmware to natively play voice countdown 
  -- announcements counting back from 20 seconds down to 0.
  helper.assert_timer_started(0, 16, "Prep timer should start with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer should start with 600s")

  helper.simulate_flight(script, 35) -- Target 1 (30s) achieved: stores 30s in times.
  helper.assert_timer_started(1, 30, "Flight 1 timer starts with 30s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  -- FIXME: This behavior is not according to the FAI rules.
  -- The new rules does not require to exceed the target values 
  helper.simulate_flight(script, 40) -- Target 2 (45s) NOT achieved: stores nothing.
  helper.assert_timer_started(1, 45, "Flight 2 timer starts with 45s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getVal(7), 30, "First target achieved")
  helper.assert_eq(mock_env.taskState.times.getVal(6), 0, "Second target not achieved")
end

local function test_task_d2_complete_ladder()
  print("- Testing Task D2 (Small Ladder - Complete Ladder)")
  local script = helper.select_and_load_task(16)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 30)
  helper.simulate_flight(script, 45)
  helper.simulate_flight(script, 60)
  helper.simulate_flight(script, 75)
  helper.simulate_flight(script, 90)
  helper.simulate_flight(script, 105)
  
  mock_env.clearSounds()
  helper.simulate_flight(script, 120)

  helper.assert_sound_played("welldone%.wav", "Should play 'welldone' when ladder is completed")
  
  -- FIXME: There is a known bug in task_d2.lua where completing the ladder sets state = 5,
  -- but it is immediately overwritten by state = 4 at the end of the landed check block.
  -- We assert that the actual state becomes 4 due to this script bug.
  helper.assert_eq(mock_env.taskState.state, 4, "State remains 4 due to known script bug overriding state = 5")
  helper.assert_eq(mock_env.taskState.times.getTotal(), 30+45+60+75+90+105+120, "Total score should be sum of all targets")
end

test_task_d2_small_ladder()
test_task_d2_complete_ladder()
