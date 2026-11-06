--[[
	F3K Training - 	Mike, ON4MJ

	WBig/view_e.lua
	Big widget view for the Poker task (also used by EE, the 15 min variant)
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_e.lua' )
local widget = dofile( F3K_SCRIPT_PATH .. 'WBig/viewbase.lua' )


-- Target value : 'W' or m:ss
local function drawTarget( x, y, isW, val, att )
	if isW then
		OpenTX.lcd.drawText( x, y, 'W', att )
	else
		OpenTX.lcd.drawTimer( x, y, val, att )
	end
end


function task.display( context )
	widget.drawCommon( context, task )

	if task.done then
		OpenTX.lcd.drawText( 132, 129, 'Done !', MIDSIZE )
	elseif task.state == 3 then
		-- flying : locked target, then the countdown to it
		drawTarget( 120, 133, task.lockedW, task.locked, 0 )
		task.timer2.draw( 184, 129, MIDSIZE )
	elseif task.locked then
		OpenTX.lcd.drawText( 120, 133, 'Lock', 0 )
		drawTarget( 184, 129, task.lockedW, task.locked, MIDSIZE )
	else
		OpenTX.lcd.drawText( 120, 133, 'Target', 0 )
		drawTarget( 184, 129, task.selW, task.selected, MIDSIZE )
	end

	for i=1,task.TARGET_COUNT do
		local y = 10 + 21 * (i - 1)
		OpenTX.lcd.drawText( 300, y, i .. '.', 0 )
		local val = task.targets[ i ]
		if val then
			OpenTX.lcd.drawTimer( 338, y, val, 0 )
		end
	end

	OpenTX.lcd.drawFilledRectangle( 280 + 1, 126, context.zone.w - 281, context.zone.h - 126, TEXT_INVERTED_BGCOLOR )
	OpenTX.lcd.drawTimer( 312, 138, task.times.getTotal(), INVERS )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
