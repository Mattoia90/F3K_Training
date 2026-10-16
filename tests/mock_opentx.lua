-- Mock implementation of the OpenTX/EdgeTX environment for host testing

-- Globals
LCD_W = 128
INVERS = 1
DBLSIZE = 2
SOLID = 1
WHITE = 0
BLACK = 1
RIGHT = 2
SMLSIZE = 0
MIDSIZE = 1
BOLD = 8

-- Mock states
local mock_time = 0 -- 10ms increments (100 = 1 second)
local played_sounds = {}
local logged_draws = {}
local mocked_switches = {
  ['sc'] = -1024, -- Menu Switch (up = menu, mid = stop, down = run)
  ['se'] = -1024, -- Prelaunch Switch
  ['thr'] = 1024, -- Scroll encoder (1024 selects first task)
}

-- Mocks for core APIs
function getVersion()
  return "2.2.0", "x9d", 2, 2, 0, "EdgeTX"
end

function getFieldInfo(name)
  return { id = name, name = name }
end

function getValue(source)
  return mocked_switches[source] or 0
end

function getSourceIndex(name)
  return name
end

function getSourceValue(id)
  if id == 'Batt' then return 8.2 end
  if id == 'RxBt' or id == 'Rbt' then return 5.0 end
  if id == 'GAlt' or id == 'Valt' then return 120 end
  return 0
end

function getTime()
  return mock_time
end

function playFile(filename)
  table.insert(played_sounds, { type = "file", value = filename })
  print(string.format("  🔊 [AUDIO] File: %s", filename))
end

function playNumber(val, unit, attr)
  table.insert(played_sounds, { type = "number", value = val, unit = unit })
  print(string.format("  🔊 [AUDIO] Number: %s (unit: %s)", tostring(val), tostring(unit)))
end

function playDuration(val, attr)
  table.insert(played_sounds, { type = "duration", value = val })
  print(string.format("  🔊 [AUDIO] Duration: %s seconds", tostring(val)))
end

-- Mock LCD
lcd = {
  clear = function()
    logged_draws = {}
  end,
  drawText = function(x, y, text, flags)
    table.insert(logged_draws, { type = "text", x = x, y = y, text = text, flags = flags })
  end,
  drawNumber = function(x, y, val, flags)
    table.insert(logged_draws, { type = "number", x = x, y = y, val = val, flags = flags })
  end,
  drawTimer = function(x, y, val, flags)
    table.insert(logged_draws, { type = "timer", x = x, y = y, val = val, flags = flags })
  end,
  drawLine = function(x1, y1, x2, y2, pattern, flags)
    table.insert(logged_draws, { type = "line", x1 = x1, y1 = y1, x2 = x2, y2 = y2, pattern = pattern, flags = flags })
  end,
  drawFilledRectangle = function(x, y, w, h, flags)
    table.insert(logged_draws, { type = "rect", x = x, y = y, w = w, h = h, flags = flags })
  end,
  getLastPos = function()
    return 100
  end,
  setColor = function() end
}

-- Mock Model Timers
local model_timers = {
  [0] = { value = 0, start = 0, mode = 0, countdownBeep = 0, minuteBeep = false, persistent = 0 },
  [1] = { value = 0, start = 0, mode = 0, countdownBeep = 0, minuteBeep = false, persistent = 0 }
}

model = {
  getTimer = function(id)
    local t = model_timers[id]
    return {
      value = t.value,
      start = t.start,
      mode = t.mode,
      countdownBeep = t.countdownBeep,
      minuteBeep = t.minuteBeep,
      persistent = t.persistent
    }
  end,
  setTimer = function(id, timer)
    model_timers[id] = timer
  end,
  resetTimer = function(id)
    model_timers[id].value = model_timers[id].start
  end
}

-- Test control helpers
mock_env = {
  timerEvents = {},
  clearTimerEvents = function()
    mock_env.timerEvents = {}
  end,
  setTime = function(seconds)
    mock_time = seconds * 100
  end,
  advanceTime = function(seconds)
    mock_time = mock_time + (seconds * 100)
    for id, t in pairs(model_timers) do
      if t.mode > 0 then
        if (t.start or 0) == 0 then
          t.value = t.value + seconds
        else
          t.value = math.max(0, t.value - seconds)
        end
      end
    end
  end,
  setSwitch = function(name, value)
    mocked_switches[name] = value
  end,
  getPlayedSounds = function()
    return played_sounds
  end,
  clearSounds = function()
    played_sounds = {}
  end,
  getDrawings = function()
    return logged_draws
  end
}

-- Path remapping for tests (remap absolute OpenTX paths to relative ones)
local original_dofile = dofile
function dofile(path)
  local local_path = path:gsub("^/SCRIPTS/F3K_TRAINING/", "./F3K_TRAINING/")
  local_path = local_path:gsub("^/SCRIPTS/TELEMETRY/", "./Telemetry/")
  
  -- Handle case mismatch for view files on Linux (since OpenTX/FAT is case-insensitive)
  local f = io.open(local_path, "r")
  if f then
    f:close()
  else
    local dir, filename = local_path:match("^(.-)([^/]+)$")
    if dir and filename and filename:match("^view_") then
      local_path = dir .. filename:lower()
    end
  end
  
  local result = original_dofile(local_path)
  
  if local_path:match("timer%.lua$") then
    local original_createTimer = result
    result = function(timerId, startValue, countdownBeep, minuteBeep)
      local t = original_createTimer(timerId, startValue, countdownBeep, minuteBeep)
      local original_start = t.start
      local original_stop = t.stop
      
      t.start = function(newStartValue)
        local val = newStartValue or startValue or 0
        table.insert(mock_env.timerEvents, { type = "start", id = timerId, value = val })
        print(string.format("  ⏳ [TIMER] Start: id=%d, value=%ds", timerId, val))
        original_start(newStartValue)
      end
      
      t.stop = function()
        local running, val = original_stop()
        table.insert(mock_env.timerEvents, { type = "stop", id = timerId, value = val })
        print(string.format("  ⏳ [TIMER] Stop: id=%d, value=%ds", timerId, val))
        return running, val
      end
      
      return t
    end
  end

  -- Capture task and view instances for inspection in tests
  if type(result) == "table" then
    if local_path:match("view_[a-z0-9_]+%.lua$") then
      mock_env.currentTask = result
    elseif local_path:match("task_[a-z0-9_]+%.lua$") and not local_path:match("taskbase") and not local_path:match("lasttaskbase") and not local_path:match("besttaskbase") then
      mock_env.taskState = result
    end
  end
  
  return result
end
