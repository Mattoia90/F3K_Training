--[[
	F3K Training - 	Mike, ON4MJ

	WBig/view_n.lua
	Big widget view for the Best Flight
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_n.lua' )
local widget = dofile( F3K_SCRIPT_PATH .. 'WBig/viewbase.lua' )


function task.display( context )
	widget.drawCommonLastBest( context, task )

	if task.state == 4 and task.times.getVal( task.BEST_COUNT ) >= task.timer1.getVal() then
		OpenTX.lcd.drawText( 305, 12, 'Done !', MIDSIZE )
	end
	OpenTX.lcd.drawLine( 280, 54, context.zone.w - 1, 54, SOLID, 2 )

	local y = 59
	for i=0,0 do
		task.times.draw( 312, y + 22*i, i+1, 0 )
	end

	return OpenTX.backgroundRun( task )
end



return { init=task.init, background=task.background, display=task.display }
