local helper = require("tests.test_helper")

local function test_task_n_best_flight()
  print("- Testing Task N (Best Flight)")
  local script = helper.select_and_load_task(13) -- Index 13: Best Flight
  helper.assert_eq(mock_env.taskState.name, "Best Flight", "Task N name matches")

  helper.assert_timer_started(0, 16, "Prep timer starts with 16s")
  helper.simulate_prep_time(script, 16)
  helper.assert_timer_started(0, 600, "Working window timer starts with 600s")

  helper.simulate_flight_by_seconds(script, 596) -- Almost perfect (599 - 3)
  helper.assert_timer_started(1, 598, "Flight 1 timer starts with 598s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  -- FIXME: remaining.wav is played double times
  -- Assert that remaining.wav is played exactly twice (known bug in script)
  local remaining_count = 0
  for _, s in ipairs(mock_env.getPlayedSounds()) do
    if s.type == "file" and s.value:match("remaining%.wav") then
      remaining_count = remaining_count + 1
    end
  end
  helper.assert_eq(remaining_count, 2, "Double remaining.wav play occurred (known bug in script)")

  -- Only best flight is kept: 596
  helper.assert_eq(mock_env.taskState.times.getTotal(), 596, "Only best flight kept")
end

local function test_task_n_multiple_flights()
  print("- Testing Task N (Best Flight - Multiple Flights)")
  local script = helper.select_and_load_task(13)
  helper.simulate_prep_time(script, 16)

  helper.simulate_flight(script, 100) -- Flight 1: 100s
  helper.assert_timer_started(1, 598, "Flight 1 timer starts with 598s target")
  helper.assert_timer_stopped(1, "Flight 1 timer stops on landing")

  helper.simulate_flight(script, 250) -- Flight 2: 250s (best)
  helper.assert_timer_started(1, 496, "Flight 2 timer starts with 496s target")
  helper.assert_timer_stopped(1, "Flight 2 timer stops on landing")

  helper.simulate_flight(script, 150) -- Flight 3: 150s
  helper.assert_timer_started(1, 244, "Flight 3 timer starts with 244s target")
  helper.assert_timer_stopped(1, "Flight 3 timer stops on landing")

  helper.assert_eq(mock_env.taskState.times.getTotal(), 250, "Only best flight of 250s is scored")
end

test_task_n_best_flight()
test_task_n_multiple_flights()
