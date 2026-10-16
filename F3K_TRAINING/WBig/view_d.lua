--[[
	F3K Training - 	Mike, ON4MJ

	WBig/view_d.lua
	Big widget view for the Two Flights task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_d.lua' )
local widget = dofile( F3K_SCRIPT_PATH .. 'WBig/viewbase.lua' )


function task.display( context )
	widget.drawCommon( context, task )

	if task.done then
		OpenTX.lcd.drawText( 160, 129, 'Done !', MIDSIZE )
	else
		OpenTX.lcd.drawText( 140, 133, '5min: ', 0 )
		task.timer2.drawReverse( 192, 129, MIDSIZE )
	end

	local total = 0
	for i=0,1 do
		local y = 10 + 21 * i
		OpenTX.lcd.drawText( 290, y, '5min', 0 )

		if i < task.current - 1 then
			local val = task.times.getVal( 4 - task.current + i )
			OpenTX.lcd.drawTimer( 338, y, val, 0 )
			total = total + math.min( task.MAX_FLIGHT_TIME, val )
		end
	end

	OpenTX.lcd.drawFilledRectangle( 281, 130, context.zone.w - 281, context.zone.h - 130, TEXT_INVERTED_BGCOLOR )
	OpenTX.lcd.drawTimer( 312, 139, total, INVERS )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
