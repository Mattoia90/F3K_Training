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

local SOUND_PATH = F3K_SCRIPT_PATH .. 'sounds/'




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



return { 
	MENU_SWITCH = getFieldInfo( MENU_SWITCH ).id,
	PRELAUNCH_SWITCH = getFieldInfo( PRELAUNCH_SWITCH ).id,
	MENU_SCROLL_ENCODER = getFieldInfo( MENU_SCROLL_ENCODER ).id,
	SOUND_PATH = SOUND_PATH,

	resetLaunchDetection = resetLaunchDetection,
	launched = launched,
	landed = landed
}
