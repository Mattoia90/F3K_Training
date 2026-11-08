--[[
	F3K Training - 	CIRRUS_RC   08 Mar 2020

	WBig/view_l.lua
	Big widget view for the One Flight task (single flight, max 9:59, 10 min window)
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_l.lua' )
local widget = dofile( F3K_SCRIPT_PATH .. 'WBig/viewbase.lua' )


function task.display( context )
	widget.drawCommon( context, task )

	if task.done then
		OpenTX.lcd.drawText( 160, 129, 'Done !', MIDSIZE )
	else
		OpenTX.lcd.drawText( 140, 133, '9:59: ', 0 )
		task.timer2.drawReverse( 192, 129, MIDSIZE )
	end

	OpenTX.lcd.drawText( 290, 10, '9:59', 0 )
	if task.current > 1 then
		OpenTX.lcd.drawTimer( 338, 10, task.times.getVal( 1 ), 0 )
	end

	OpenTX.lcd.drawFilledRectangle( 281, 130, context.zone.w - 281, context.zone.h - 130, TEXT_INVERTED_BGCOLOR )
	OpenTX.lcd.drawTimer( 312, 139, task.times.getTotal(), INVERS )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
