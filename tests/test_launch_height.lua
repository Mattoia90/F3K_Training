local helper = require("tests.test_helper")

local function find_text(text)
  for _, d in ipairs(mock_env.getDrawings()) do
    if d.type == "text" and d.text == text then return true end
  end
  return false
end

-- Launch at ground altitude, climb to peak, then sink 10 m (peak passed) unless land_at_peak
local function fly(script, ground, peak, land_at_peak)
  mock_env.setAltitude(ground)
  mock_env.setSwitch("se", 1024)
  mock_env.advanceTime(1)
  script.run()
  mock_env.setSwitch("se", -1024)
  mock_env.advanceTime(1)
  script.run() -- launched
  mock_env.setAltitude(peak)
  mock_env.advanceTime(1)
  script.run()
  helper.assert_eq(find_text("A:" .. peak), true, "Live altitude shown while flying")
  if not land_at_peak then
    mock_env.setAltitude(peak - 10)
    mock_env.advanceTime(1)
    script.run()
  end
  mock_env.setSwitch("se", 1024)
  script.run()
  mock_env.setSwitch("se", -1024)
  script.run()
end


local function test_launch_heights(idx, prep, label)
  print("- Testing launch height (" .. label .. ")")
  local script = helper.select_and_load_task(idx)
  if prep then
    helper.simulate_prep_time(script, prep)
  else
    script.run()
  end

  mock_env.clearSounds()
  fly(script, 100, 160)
  helper.assert_number_played(60, label .. ": launch height announced when the peak is passed")
  fly(script, 102, 132, true)
  local heights = mock_env.taskState.times.getHeights()
  helper.assert_eq(#heights, 2, label .. ": one height per launch")
  helper.assert_eq(heights[1], 60, label .. ": peak - ground altitude")
  helper.assert_eq(heights[2], 30, label .. ": measured until the landing when the peak isn't passed")
  helper.assert_eq(find_text("L:30"), true, label .. ": last launch height shown after the landing")
  mock_env.setAltitude(nil)
end


local function test_voice_disabled()
  print("- Testing launch height (LAUNCH_HEIGHT_VOICE = false)")
  local script = helper.select_and_load_task(1)
  F3KConfig.LAUNCH_HEIGHT_VOICE = false
  helper.simulate_prep_time(script, 16)
  mock_env.clearSounds()
  fly(script, 100, 160)
  local announced = false
  for _, s in ipairs(mock_env.getPlayedSounds()) do
    if s.type == "number" and s.value == 60 then announced = true end
  end
  helper.assert_eq(announced, false, "Launch height not announced")
  helper.assert_eq(mock_env.taskState.times.getLastHeight(), 60, "Launch height still measured")
  mock_env.setAltitude(nil)
end


local function test_no_altitude_sensor()
  print("- Testing launch height (no altitude sensor)")
  local script = helper.select_and_load_task(1)
  helper.simulate_prep_time(script, 16)
  mock_env.clearSounds()
  helper.simulate_flight(script, 30)
  helper.assert_eq(#mock_env.taskState.times.getHeights(), 0, "No height without an altitude sensor")
  helper.assert_eq(find_text("A:?"), true, "Altitude shown as unknown")
end


test_launch_heights(1, 16, "Task A")
test_launch_heights(12, 20, "Task M (15 min base)")
test_launch_heights(20, nil, "Free flight")
test_voice_disabled()
test_no_altitude_sensor()
mock_env.setSwitch("sc", -1024)
