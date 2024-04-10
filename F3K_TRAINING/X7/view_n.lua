--[[
	F3K Training - 	Mike, ON4MJ

	X7/view_n.lua
	Q7 view for the Best Flight
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_n.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X7/viewbase.lua' )


function task.display()
	display.drawCommonLastBest( task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		lcd.drawText( 95, 6, 'Done !', BOLD )
	end
	lcd.drawLine( 91, 20, 127, 20, SOLID, 2 )

	task.times.draw( 100, 24, 1, 0)

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
