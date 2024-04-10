--[[
	F3K Training - 	Mike, ON4MJ

	X9/view_n.lua
	Taranis view for the Best Flight
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_n.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X9/viewbase.lua' )


function task.display()
	display.drawCommonLastBest( task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		lcd.drawText( 166, 4, 'Done !', MIDSIZE )
	end
	lcd.drawLine( 159, 20, 211, 20, SOLID, 2 )

	task.times.draw( 180, 23 , 1, 0 )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }

