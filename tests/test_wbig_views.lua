local helper = require("tests.test_helper")

-- Color radios run the widget (F3K_TRAINING/main.lua + WBig/ views):
-- TX16S / Horus 480x272, TX15 / GX15 480x320 (full screen widget zone)
local ZONES = { { w = 480, h = 272 }, { w = 480, h = 320 } }

local function menu_ids()
  local f = assert(io.open("./F3K_TRAINING/main.lua", "r"))
  local src = f:read("a")
  f:close()
  local ids, seen = {}, {}
  for id in src:gmatch("{ id='(%w+)'") do
    if not seen[id] then
      seen[id] = true
      ids[#ids + 1] = id
    end
  end
  return ids
end

local function test_wbig_views()
  print("- Testing WBig (color widget) views on 480x272 and 480x320")
  local savedOpenTX = OpenTX

  F3K_SCRIPT_PATH = "/SCRIPTS/F3K_TRAINING/"
  F3KConfig = dofile(F3K_SCRIPT_PATH .. "custom.lua")
  createTimer = dofile(F3K_SCRIPT_PATH .. "timer.lua")
  createTimeKeeper = dofile(F3K_SCRIPT_PATH .. "timekeeper.lua")
  lcd.RGB = function() return 0 end -- makes opentx_srv.lua pick the widget layer
  OpenTX = dofile(F3K_SCRIPT_PATH .. "opentx_srv.lua")

  mock_env.setSwitch("sc", 1024) -- run
  mock_env.setSwitch("se", -1024)

  local ids = menu_ids()
  helper.assert_eq(#ids >= 18, true, "Widget menu task ids parsed")

  for _, id in ipairs(ids) do
    for _, z in ipairs(ZONES) do
      local ctx = { zone = { x = 0, y = 0, w = z.w, h = z.h }, options = { BackgroundColor = 0 } }
      OpenTX.lcd.updateContext(ctx)
      lcd.clear()
      local ok, err = pcall(function()
        local view = dofile(F3K_SCRIPT_PATH .. "WBig/view_" .. id .. ".lua")
        view.init(600)
        view.display(ctx)
      end)
      helper.assert_eq(ok, true, string.format("WBig view %s runs on %dx%d (%s)", id, z.w, z.h, tostring(err)))

      local outside = 0
      for _, d in ipairs(mock_env.getDrawings()) do
        local x, y = d.x or d.x1, d.y or d.y1
        if x < 0 or y < 0 or x > z.w or y > z.h then
          outside = outside + 1
        end
      end
      helper.assert_eq(outside, 0, string.format("WBig view %s draws inside %dx%d", id, z.w, z.h))
    end
  end

  lcd.RGB = nil
  OpenTX = savedOpenTX
end

test_wbig_views()
