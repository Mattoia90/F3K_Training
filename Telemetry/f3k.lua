F3KVersion = '3.03B'
--[[
	F3K Training - 	Mike, ON4MJ

	telemN.lua
	Main script (provides the UI and loads the relevant task script)

	This is a telemetry script
	REQUIRES OpenTX 2.0.13+

	Provides a serie of specialized timer screens for most F3K tasks
	NB: there's no telemetry at all in this "telemetry" script.

	Releases
	0.9 	Initial release (incorrectly labeled as 1.0 at the time)
	1.0 	Skipped to avoid confusion
	1.01 	Added the preparation time
		Reduced the temp switch hold time to 0.75s
		The short window time was not initialized with a default value
		Better support of custom launch detection functions
	1.02	2.0.15 support : reduced the memory footprint (the short window option had to go, sorry about that)
		When running the "last" tasks several times in a row, the "improve margin"
			message could stay on screen at the beginning of the subsequent tasks
		When running "ladder" several times in a row, the flight timer was not reset
		In last 2&3, you won't be congratulated for maxing a single flight anymore; only for maxing the task
		Added congratulations to 3oo6
		Corrected the initial display of 1234
		Reduced the usage of setTimer(), which seems to write in the eeprom !! 
			(so, probably improved the life expectancy of the TX)
		Reduced the temporary switch holding time again

	2.00	Major refactoring: split the original script in several dynamically loaded files 
			to get rid of all those memory problems
		Added Task M
		Correction of a false launch detection problem when the previous task was "Done !"
	2.01	Fixed a regression introduced in 2.0 which caused the script to crash in several tasks 
			when the plane was still flying at the end of the working time
	2.02	Added a quick turnaround practice task
	2.03	Added variations with a 7-min work time in task A & B
		OpenTX 2.1.x compatibility (not tested on the transmitter)
	2.04	Added a "Free Flight" non-task, which provides a normal usage of the timers
		Added the total flight time to the QT practice
	2.05	Changed the QT practice to count down from 30s
		Solved some OpenTX 2.0 vs. 2.1 incompatibilities
	2.06    xStatiCa (Adam) - Imlemented Horus compatibility for large Widget size.  Other widget sizes will not display properly.
			Allow persistent storage of options if run as a Widget (options storage is a feature of Widgets).

	3.00	Refactoring again : separated the views from the domain.  
		The goal was to go multi-platform : Q7 and Horus (large for now) Widgets support
		Added 2.2 compatibility for the Taranis
	3.01	Horus widget fix : browsing through widgets to install a new one in another zone broke an already installed Training widget.
	3.02	Added AULD
		Fixed a regression introduced in 3.00 where a false launch could be detected when running the same task more than once
	3.03 (BETA) - CIRRUS_UK  --   Changed only apply to Taranis X9.   Work not done on X7 and Horus
			Moved old Task M (Big Ladder) to correct Task K.   Moved old Task D (Small Ladder) to Task D2.  
			---- New Tasks ----     
			Task D (Two flights) - Each competitor has two (2) flights. These two flights will be added together. The maximum accounted single flight time is 300 seconds. Working time is 10 minutes.
			Task L (One flight)  - During the working time, the competitor may launch his model glider one single time. The maximum flight time is limited to 599 seconds (9 minutes 59 seconds).  Working time: 10 minutes.
			Task M Each competitor must launch his/her model glider exactly three (3) times to achieve three (3) target times as follows: 3:00 (180 seconds), 5:00 (300 seconds), 7:00 (420 seconds). 
				The targets must be flown in the increasing order as specified. The actual times of each flight up to (not exceeding) the target time will be added up and used as the final score for the task. 
				The competitors do not have to reach or exceed the target times to count each flight time. Working time: 15 minutes.
--]]

F3K_SCRIPT_PATH = "/SCRIPTS/F3K_TRAINING/"

F3KConfig = dofile( F3K_SCRIPT_PATH .. 'custom.lua')
OpenTX = dofile( F3K_SCRIPT_PATH .. 'opentx_srv.lua' )

createTimer = dofile( F3K_SCRIPT_PATH .. 'timer.lua' )
createTimeKeeper = dofile( F3K_SCRIPT_PATH .. 'timekeeper.lua' )


-- This is assigned here with defaults for non-Widgets compatibility
-- With Widgets on Horus in OpenTX 2.2, Context will get assigned by create()
-- overriding these defaults.
--Context = {
	Options = { 
		MenuSwitch = F3KConfig.MENU_SWITCH,
		PrelaunchSwitch = F3KConfig.PRELAUNCH_SWITCH,
		MenuScrollEncoder = F3KConfig.MENU_SCROLL_ENCODER,
		BackgroundColor = WHITE 
	}
--}



local createMenu
local currentTask


local function init( win )
	currentTask.init( win )
end


local function background()
	if not currentTask.background() then
		currentTask = createMenu()
	end
end


local function display()
	lcd.clear()
	if not currentTask.display() then
		currentTask = createMenu()
	end
end


--[[
	UI to choose the task
--]]
createMenu = function()
	local TASKS = {
		{ id='A', desc='Last flight' },
		{ id='B', desc='Last two' },
		{ id='C', desc='AULD' },
		{ id='D', desc='Two flights' },
		{ id='F', desc='3 out of 6' },
		{ id='G', desc='5x2' },
		{ id='H', desc='1234' },
		{ id='I', desc='Best three' },
		{ id='J', desc='Last three' },
		{ id='K', desc='Big Ladder' },
		{ id='L', desc='One flight' },
		{ id='M', desc='Huge ladder' },
		{ id='A', desc='Last flight (7 min)', win=7 },
		{ id='B', desc='Last two (7 min)', win=7 },
		{ id='D2', desc='Small Ladder'},
		{ id='QT', desc=LCD_W > 128 and 'QT practice (15 x 40s)' or 'QT practice' },
		{ id='FF', desc=LCD_W > 128 and 'Free flight (simple timer)' or 'Free flight' }
	}

	local function dummy()
		return true
	end

	local function display()
		local div = 2048 / (#TASKS)  -- we want [0..n-1] steps
		local selection = math.floor( (getValue( Options.MenuScrollEncoder ) - 1024) / -div )

		for i=0,6 do
			local att = 0
			if i == 3 then
				att = INVERS
			end
			local ii = i + selection - 2
			if ii >= 1 and ii <= #TASKS then
				lcd.drawText( 10, 1 + 9 * i, TASKS[ ii ].id, att )
				lcd.drawText( 25, 1 + 9 * i, TASKS[ ii ].desc, att )
			end
		end

		local taskPath
		if LCD_W > 128 then 
			lcd.drawText( 175, 2, 'F3K', DBLSIZE )
			lcd.drawText( 167, 20, 'Training', 0 )

			lcd.drawText( 180, 54, 'v.', 0 )
			lcd.drawText( lcd.getLastPos(), 54, F3KVersion, 0 )

			taskPath = '/SCRIPTS/F3K_TRAINING/X9/view_'
		else
			taskPath = '/SCRIPTS/F3K_TRAINING/X7/view_'
		end
		if getValue( Options.MenuSwitch ) >= 0 then
			currentTask = dofile( taskPath .. TASKS[ selection+1 ].id .. '.lua' )
			local win = TASKS[ selection+1 ].win or 10
			init( win * 60 )
		end

		return true
	end

	return { init=dummy, background=dummy, display=display }
end

currentTask = createMenu()

return { init=init, background=background, run=display }
