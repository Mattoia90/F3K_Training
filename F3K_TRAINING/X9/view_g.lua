--[[
	F3K Training - 	Mike, ON4MJ

	X9/view_g.lua
	Taranis view for the 5x2 task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_g.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X9/viewbase.lua' )


function task.display()
	display.drawCommonLastBest( task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		lcd.drawText( 26, 50, 'Done !', MIDSIZE )
	end

	for i=0,4 do
		task.times.draw( 180, 2 + 10*i, i+1, 0 )
	end

	return OpenTX.backgroundRun( task )
end

return { init=task.init, background=task.background, display=task.display }
