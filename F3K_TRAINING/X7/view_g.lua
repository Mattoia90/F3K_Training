--[[
	F3K Training - 	Mike, ON4MJ

	X7/view_g.lua
	Q7 view for the 5x2 task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_g.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X7/viewbase.lua' )


function task.display()
	display.drawCommonLastBest( task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		lcd.drawText( 25, 34, 'Done !', MIDSIZE )
	end

	for i=0,4 do
		task.times.draw( 100, 3 + 10*i, i+1, 0 )
	end

	return OpenTX.backgroundRun( task )
end

return { init=task.init, background=task.background, display=task.display }
