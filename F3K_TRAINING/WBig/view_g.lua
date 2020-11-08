--[[
	F3K Training - 	Mike, ON4MJ

	WBig/view_g.lua
	Big widget view for the 5x2 task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_g.lua' )
local widget = dofile( F3K_SCRIPT_PATH .. 'WBig/viewbase.lua' )


function task.display( context )
	widget.drawCommonLastBest( context, task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		OpenTX.lcd.drawText( 110, 84, 'Done !', MIDSIZE )
	end

	for i=0,4 do
		task.times.draw( 312, 10 + 22*i, i+1, 0 )
	end

	return OpenTX.backgroundRun( task )
end

return { init=task.init, background=task.background, display=task.display }
