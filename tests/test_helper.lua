-- Shared test helper module
package.path = package.path .. ";./?.lua"
require("tests.mock_opentx")

local helper = {
  passed = 0,
  failed = 0
}

function helper.assert_eq(actual, expected, message)
  if actual == expected then
    helper.passed = helper.passed + 1
  else
    print("  ❌ FAIL: " .. (message or "Assertion failed"))
    print("     Expected: " .. tostring(expected))
    print("     Actual:   " .. tostring(actual))
    helper.failed = helper.failed + 1
  end
end

function helper.select_and_load_task(idx)
  mock_env.setTime(0)
  mock_env.clearSounds()
  mock_env.clearTimerEvents()
  mock_env.setSwitch("sc", -1024) -- menu mode
  
  -- Midpoint stick calculation for 18 menu items
  local target_selection = idx - 1
  local num_tasks = 18
  local thr_val = math.floor(1024 - (target_selection + 0.5) * (2049 / num_tasks))
  mock_env.setSwitch("thr", thr_val)
  
  local main_script = dofile("./Telemetry/f3k.lua")
  main_script.run() -- render menu
  
  mock_env.setSwitch("sc", 1024) -- active run mode
  main_script.run() -- loads task
  main_script.run() -- transitions task state 1 -> 2 (started/prep)
  
  return main_script
end

function helper.simulate_prep_time(main_script, seconds)
  mock_env.advanceTime(seconds)
  main_script.run()
end

function helper.simulate_flight(main_script, flight_duration)
  print(string.format("  🛫 [FLIGHT] Start: %ds", flight_duration))
  -- Launch: pull preset switch
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  main_script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  main_script.run()
  
  -- Fly duration
  local fly_time = flight_duration
  if fly_time > 0 then
    mock_env.advanceTime(fly_time)
    main_script.run()
  end
  
  -- Landing: quick flip of se to avoid double-launch
  mock_env.setSwitch("se", 1024)
  main_script.run()
  mock_env.setSwitch("se", -1024)
  main_script.run()
  print("  🛬 [FLIGHT] End: landed")
end

function helper.simulate_flight_by_seconds(main_script, flight_duration)
  print(string.format("  🛫 [FLIGHT] Start: %ds (second-by-second)", flight_duration))
  -- Launch: pull preset switch
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  main_script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  main_script.run()
  
  -- Fly duration: 1 second at a time to trigger second-by-second updates
  for s = 1, flight_duration do
    mock_env.advanceTime(1)
    main_script.run()
  end
  
  -- Landing: quick flip of se to avoid double-launch
  mock_env.setSwitch("se", 1024)
  main_script.run()
  mock_env.setSwitch("se", -1024)
  main_script.run()
  print("  🛬 [FLIGHT] End: landed")
end

function helper.assert_sound_played(expected_file_pattern, message)
  local sounds = mock_env.getPlayedSounds()
  local found = false
  for _, s in ipairs(sounds) do
    if s.type == "file" and s.value:match(expected_file_pattern) then
      found = true
      break
    end
  end
  helper.assert_eq(found, true, message or ("Expected sound matching pattern: " .. expected_file_pattern))
end

function helper.assert_number_played(expected_val, message)
  local sounds = mock_env.getPlayedSounds()
  local found = false
  for _, s in ipairs(sounds) do
    if (s.type == "number" or s.type == "duration") and s.value == expected_val then
      found = true
      break
    end
  end
  helper.assert_eq(found, true, message or ("Expected number or duration announcement: " .. tostring(expected_val)))
end

function helper.assert_sound_sequence(expected_list, message)
  local sounds = mock_env.getPlayedSounds()
  local matched = 0
  for i, exp in ipairs(expected_list) do
    local actual = sounds[i]
    if not actual then
      print(string.format("  ❌ SEQ FAIL: Sound index %d missing. Expected: %s", i, tostring(exp.value)))
      helper.failed = helper.failed + 1
      return
    end
    
    local ok = false
    if exp.type == "file" and actual.type == "file" then
      ok = actual.value:match(exp.value) ~= nil
    elseif exp.type == "number" and actual.type == "number" then
      ok = actual.value == exp.value
    elseif exp.type == "duration" and actual.type == "duration" then
      ok = actual.value == exp.value
    end
    
    if ok then
      matched = matched + 1
    else
      print(string.format("  ❌ SEQ FAIL: Sound index %d mismatch. Expected type '%s' value '%s', got type '%s' value '%s'",
        i, exp.type, tostring(exp.value), actual.type, tostring(actual.value)))
      helper.failed = helper.failed + 1
      return
    end
  end
  helper.passed = helper.passed + 1
end

function helper.assert_timer_started(timer_id, expected_value, message)
  local found = false
  for _, e in ipairs(mock_env.timerEvents) do
    if e.type == "start" and e.id == timer_id and (not expected_value or e.value == expected_value) then
      found = true
      break
    end
  end
  helper.assert_eq(found, true, message or string.format("Timer %d should be started with value %s", timer_id, tostring(expected_value)))
end

function helper.assert_timer_stopped(timer_id, message)
  local found = false
  for _, e in ipairs(mock_env.timerEvents) do
    if e.type == "stop" and e.id == timer_id then
      found = true
      break
    end
  end
  helper.assert_eq(found, true, message or string.format("Timer %d should be stopped", timer_id))
end

return helper
