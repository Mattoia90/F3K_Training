--[[
	F3K Training - 	Mike, ON4MJ

	custom.lua
	This file is meant to contain the things which can be customized by the user
	See the documentation
--]]


-- Customize your switches and menu scroll input axis here.

-- On Horus using widgets, you can customize it in the GUI Widget settings menu 
-- by holding the select button while the widget is selected.

local PRELAUNCH_SWITCH = 'se' 		-- temporary switch on the left
--local PRELAUNCH_SWITCH = 'sh'		-- temporary switch on the right (or emulator)
local MENU_SWITCH = 'sc'		-- a 3-pos switch is mandatory here : up=menu; mid=stop; down=run
local MENU_SCROLL_ENCODER = 'thr'
local RADIO_VOLTAGE = { 'Batt' }
local MODEL_VOLTAGE = { 'RxBt', 'Rbt' }
local HEIGHT = { 'GAlt', 'Valt' }

local SOUND_PATH = F3K_SCRIPT_PATH .. 'sounds/'

-- Task description at task start
--   true  : play the task description, then the prep time countdown announces 10..1
--   false : no task description, short prep time counting down directly from PREP_COUNTDOWN
local TASK_DESCRIPTION = true

-- Prep time countdown (seconds) used when TASK_DESCRIPTION = false
-- e.g. 10 (default) or 5 for a faster start; valid range 1..10
local PREP_COUNTDOWN = 10

-- Task history log
--   true  : at the end of each task (or when it is stopped after at least one flight)
--           a line is appended to TasksLog/yyyyMMdd.csv (one file per day)
--   false : no log
-- NB: the TasksLog folder must exist on the SD card (Lua scripts can't create folders)
local TASK_LOG = false




local lastTimeLanded = 0	-- 0=must pull first ; other=time of the last pull

local function resetLaunchDetection()
	lastTimeLanded = 0
end



-- >>> Launch / Land detection <<< ---
local function launched()
	local ret = false
	if getValue( Options.PrelaunchSwitch ) < 0 then
		-- if the tmp switch is held for more than 0.6s, it's a launch ;
		-- otherwise it was just a trigger pull to indicate that the plane has landed
		if lastTimeLanded > 0 then
			if (getTime() - lastTimeLanded) > 60 then
				ret = true
			end
			lastTimeLanded = 0
		end
	else
		if lastTimeLanded == 0 then
			lastTimeLanded = getTime()
		end
	end
	return ret
end

local function landed()
	if getValue( Options.PrelaunchSwitch ) > 0 then
		lastTimeLanded = getTime()
		return true
	end
	return false
end
-- <<< End of launch/land detection section <<< --


--[[
	-- Alternate implementation of the launched / landed logic through traditional Tx programmation
	-- 	* Logical switch LS31 would be "launch detected"
	-- 	* Logical switch LS32 would be "landing detected"

local function launched()
	return getValue( 'ls31' ) > 0
end

local function landed()
	return getValue( 'ls32' ) > 0
end	
--]]

local function safeGetSoundPath(basePath)
	local ok, msg = pcall( function()
		local ver, radio, maj, minor, rev, osname = getVersion()
		if(osname and osname == 'EdgeTX') then
			return F3K_SCRIPT_PATH .. 'sndhd/'
		end
		return basePath
	end )

	if(not ok) then
		print(msg)
		return basePath
	end
	return msg
end

return { 
	MENU_SWITCH = getFieldInfo( MENU_SWITCH ).id,
	PRELAUNCH_SWITCH = getFieldInfo( PRELAUNCH_SWITCH ).id,
	MENU_SCROLL_ENCODER = getFieldInfo( MENU_SCROLL_ENCODER ).id,
	SOUND_PATH = safeGetSoundPath(SOUND_PATH),
	RADIO_VOLTAGE = RADIO_VOLTAGE,
	MODEL_VOLTAGE = MODEL_VOLTAGE,
	HEIGHT = HEIGHT,
	TASK_DESCRIPTION = TASK_DESCRIPTION,
	PREP_COUNTDOWN = PREP_COUNTDOWN,
	TASK_LOG = TASK_LOG,

	resetLaunchDetection = resetLaunchDetection,
	launched = launched,
	landed = landed
}
