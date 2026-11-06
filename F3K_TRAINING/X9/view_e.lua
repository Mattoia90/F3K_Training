--[[
	F3K Training - 	Mike, ON4MJ

	X9/view_e.lua
	Taranis view for the Poker task (also used by EE, the 15 min variant)
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_e.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X9/viewbase.lua' )


-- Target value : 'W' or m:ss
local function drawTarget( x, y, isW, val, att )
	if isW then
		lcd.drawText( x, y, 'W', att )
	else
		lcd.drawTimer( x, y, val, att )
	end
end


function task.display()
	display.drawCommon( task )

	if task.done then
		lcd.drawText( 72, 50, 'Done !', MIDSIZE )
	elseif task.state == 3 then
		-- flying : locked target, then the countdown to it
		drawTarget( 72, 53, task.lockedW, task.locked, 0 )
		task.timer2.draw( 104, 50, MIDSIZE )
	elseif task.locked then
		lcd.drawText( 72, 53, 'Lock', 0 )
		drawTarget( 104, 50, task.lockedW, task.locked, MIDSIZE )
	else
		lcd.drawText( 72, 53, 'Target', 0 )
		drawTarget( 104, 50, task.selW, task.selected, MIDSIZE )
	end

	for i=1,task.TARGET_COUNT do
		local y = 2 + 9 * (i - 1)
		lcd.drawText( 166, y, i .. '.', 0 )
		local val = task.targets[ i ]
		if val then
			lcd.drawTimer( 187, y, val, 0 )
		end
	end

	lcd.drawFilledRectangle( 160, 47, 52, 18, 0 )
	lcd.drawTimer( 176, 53, task.times.getTotal(), INVERS )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
