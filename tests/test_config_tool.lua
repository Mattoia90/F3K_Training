-- Radio configuration tool (F3K_TRAINING/f3kcfg.lua): edits custom.lua like the online Configurator
local helper = require("tests.test_helper")

EVT_VIRTUAL_NEXT, EVT_VIRTUAL_PREV, EVT_VIRTUAL_ENTER, EVT_VIRTUAL_EXIT = 101, 102, 103, 104

local real_io = io
local function read_real(path)
  local f = assert(real_io.open(path, "r"))
  local s = f:read("a")
  f:close()
  return s
end
local original = read_real("./F3K_TRAINING/custom.lua")

-- Same as on the radio: no 'table' library
local function load_tool()
  local env = setmetatable({}, { __index = function(_, k) if k ~= "table" then return _G[k] end end })
  return assert(loadfile("./F3K_TRAINING/f3kcfg.lua", "t", env))()
end

-- Radio-style io (io.read(f, n) / io.write(f, s)) over an in-memory SD card
local function install_sd(files)
  io = {
    open = function(path, mode)
      if mode == "r" then
        if not files[path] then return nil end
        return { path = path, pos = 1 }
      end
      files[path] = ""
      return { path = path }
    end,
    read = function(f, n)
      local s = files[f.path]:sub(f.pos, f.pos + n - 1)
      f.pos = f.pos + #s
      return s
    end,
    write = function(f, s) files[f.path] = files[f.path] .. s end,
    close = function(f) end
  }
end

local function test_parse_build()
  print("- Testing config tool parse / build on the shipped custom.lua")
  local tool = load_tool()
  -- Values saved in custom.lua change with the user's settings: only check that all are found
  local v, q = tool.parse(original)
  helper.assert_eq(v ~= nil, true, "custom.lua parsed")
  helper.assert_eq(type(v.PRELAUNCH_SWITCH), "string", "Prelaunch found")
  helper.assert_eq(type(v.MENU_SCROLL_ENCODER), "string", "Scroll encoder found")
  helper.assert_eq(type(v.TASK_DESCRIPTION), "boolean", "Task description found")
  helper.assert_eq(type(v.PREP_COUNTDOWN), "number", "Prep countdown found")
  helper.assert_eq(type(v.TASK_LOG), "boolean", "Task log found")
  helper.assert_eq(type(v.LAUNCH_HEIGHT_VOICE), "boolean", "Launch height voice found")
  helper.assert_eq(tool.build(original, v, q), original, "No change = identical file")

  local out = tool.build(original, { PRELAUNCH_SWITCH = "sa", PREP_COUNTDOWN = 7, TASK_LOG = true }, q)
  local v2 = tool.parse(out)
  helper.assert_eq(v2.PRELAUNCH_SWITCH, "sa", "Changed prelaunch read back")
  helper.assert_eq(v2.PREP_COUNTDOWN, 7, "Changed countdown read back")
  helper.assert_eq(v2.TASK_LOG, true, "Changed log read back")
  helper.assert_eq(v2.MENU_SWITCH, v.MENU_SWITCH, "Other values untouched")
  helper.assert_eq(out:find("%-%-local PRELAUNCH_SWITCH = 'sh'", 1) ~= nil, true, "Commented line kept")
  local _, changed = out:gsub("\n", "\n")
  local _, lines = original:gsub("\n", "\n")
  helper.assert_eq(changed, lines, "Same number of lines")

  local missing_v, missing = tool.parse("local MENU_SWITCH = 'sc'\n")
  helper.assert_eq(missing_v, nil, "Incomplete file rejected")
  helper.assert_eq(missing, "PRELAUNCH_SWITCH", "First missing setting reported")
end

local function test_ui_save()
  print("- Testing config tool UI: edit prelaunch + task description, save")
  -- Known starting values, whatever the shipped custom.lua says
  local start = load_tool().build(original, { PRELAUNCH_SWITCH = "se", MENU_SWITCH = "sc", TASK_DESCRIPTION = true }, {})
  local files = { ["/SCRIPTS/F3K_TRAINING/custom.lua"] = start }
  install_sd(files)
  local tool = load_tool()
  tool.init()
  tool.run(0)
  tool.run(EVT_VIRTUAL_ENTER)   -- edit Prelaunch (se)
  tool.run(EVT_VIRTUAL_NEXT)    -- next existing source: sf
  tool.run(EVT_VIRTUAL_ENTER)   -- done
  tool.run(EVT_VIRTUAL_NEXT); tool.run(EVT_VIRTUAL_NEXT); tool.run(EVT_VIRTUAL_NEXT)
  tool.run(EVT_VIRTUAL_ENTER)   -- Task description toggled off
  helper.assert_eq(tool.run(EVT_VIRTUAL_EXIT), 0, "First EXIT with unsaved changes only warns")
  for _ = 1, 10 do tool.run(EVT_VIRTUAL_NEXT) end   -- clamps on SAVE
  tool.run(EVT_VIRTUAL_ENTER)
  io = real_io

  local v = tool.parse(files["/SCRIPTS/F3K_TRAINING/custom.lua"])
  helper.assert_eq(v.PRELAUNCH_SWITCH, "sf", "Prelaunch saved")
  helper.assert_eq(v.TASK_DESCRIPTION, false, "Task description saved")
  helper.assert_eq(v.MENU_SWITCH, "sc", "Other values untouched")
  helper.assert_eq(files["/SCRIPTS/F3K_TRAINING/custom.bak"], start, "Backup of the previous file")
  helper.assert_eq(tool.run(EVT_VIRTUAL_EXIT), 1, "EXIT after save quits")
end

local function test_missing_file()
  print("- Testing config tool without custom.lua")
  install_sd({})
  local tool = load_tool()
  tool.init()
  helper.assert_eq(tool.run(0), 0, "Error screen stays")
  helper.assert_eq(tool.run(EVT_VIRTUAL_EXIT), 1, "EXIT quits")
  io = real_io
end

test_parse_build()
test_ui_save()
test_missing_file()
