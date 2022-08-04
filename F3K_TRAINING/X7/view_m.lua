--[[
	F3K Training - 	Mike, ON4MJ

	X7/view_m.lua
	Q7 view for the Big Ladder practice task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_m.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X7/viewbase.lua' )


function task.display()
	display.drawCommonLarge( task )

	--draw left bottom current time.
	if task.done then
		lcd.drawText( 22, 50, 'Done !', MIDSIZE )
	else
		lcd.drawText( 14, 53, task.MAX_FLIGHT_TIME .. 's: ', 0 )
		task.timer2.drawReverse( lcd.getLastPos(), 50, MIDSIZE )
	end

	--draw right list of target with the time if is complete.
	local total = 0
	for i=0,2 do
		local y = 6 + 14 * i
		local max = 180 + 120 * i
		lcd.drawNumber( 100, y, max, SMLSIZE + RIGHT )
		lcd.drawText( lcd.getLastPos(), y, 's', SMLSIZE )

		if i < task.current - 1 then
			local val = task.times.getVal( 5 - task.current + i )
			lcd.drawTimer( 106, y, val, SMLSIZE )
			total = total + math.min( max, val )
		end
	end
	-- Draw the right bottom black total
	lcd.drawFilledRectangle( 85, 47, 52, 18, 0 )
	lcd.drawTimer( 106, 53, total, INVERS + SMLSIZE )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
