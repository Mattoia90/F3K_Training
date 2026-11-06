--[[
	F3K Training - 	Mike, ON4MJ

	X7/view_e.lua
	Q7 view for the Poker task (also used by EE, the 15 min variant)
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_e.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X7/viewbase.lua' )


-- Target value : 'W' or m:ss
local function drawTarget( x, y, isW, val, att )
	if isW then
		lcd.drawText( x, y, 'W', att )
	else
		lcd.drawTimer( x, y, val, att )
	end
end


function task.display()
	display.drawCommonLarge( task )

	if task.done then
		lcd.drawText( 22, 50, 'Done !', MIDSIZE )
	elseif task.state == 3 then
		-- flying : locked target, then the countdown to it
		drawTarget( 2, 53, task.lockedW, task.locked, 0 )
		task.timer2.draw( 40, 50, MIDSIZE )
	elseif task.locked then
		lcd.drawText( 2, 53, 'Lock', 0 )
		drawTarget( 40, 50, task.lockedW, task.locked, MIDSIZE )
	else
		lcd.drawText( 2, 53, 'Tgt', 0 )
		drawTarget( 40, 50, task.selW, task.selected, MIDSIZE )
	end

	for i=1,task.TARGET_COUNT do
		local y = 2 + 9 * (i - 1)
		lcd.drawText( 88, y, i .. '.', SMLSIZE )
		local val = task.targets[ i ]
		if val then
			lcd.drawTimer( 106, y, val, SMLSIZE )
		end
	end

	lcd.drawFilledRectangle( 85, 47, 52, 18, 0 )
	lcd.drawTimer( 106, 53, task.times.getTotal(), INVERS + SMLSIZE )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
