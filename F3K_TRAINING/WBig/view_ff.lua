--[[
	F3K Training - 	Mike, ON4MJ

	WBig/task_ff.lua
	Big widget view for the Free Flight task
--]]

-- Not working in 2.1.x
--local CLOCK = getFieldInfo( 'clock' ).id


local task = dofile( F3K_SCRIPT_PATH .. 'task_ff.lua' )


function task.display( context )
	local horizontalDividerY = 115
	local verticalDividerX = 280

	OpenTX.lcd.setColor( CUSTOM_COLOR, context.options.BackgroundColor )
	-- background rect right side
	OpenTX.lcd.drawFilledRectangle( verticalDividerX, 0, context.zone.w - verticalDividerX, context.zone.h - 1, CUSTOM_COLOR )
	-- background rect bottom
	OpenTX.lcd.drawFilledRectangle( 0, horizontalDividerY, verticalDividerX, context.zone.h - horizontalDividerY, CUSTOM_COLOR )
	-- outline left side
	OpenTX.lcd.drawLine( 0, horizontalDividerY, 0, context.zone.h, SOLID, 2 )
	-- outline at top of right box
	OpenTX.lcd.drawLine( verticalDividerX, 0, context.zone.w, 0, SOLID, 2 )
	-- outline at right side
	OpenTX.lcd.drawLine( context.zone.w, 0, context.zone.w, context.zone.h, SOLID, 2 )
	-- outline at bottom
	OpenTX.lcd.drawLine( 0, context.zone.h, context.zone.w, context.zone.h, SOLID, 2 )
	-- top of horizontal box
	OpenTX.lcd.drawLine( 0, horizontalDividerY, verticalDividerX, horizontalDividerY, SOLID, 2 )
	-- left of vertical box
	OpenTX.lcd.drawLine( verticalDividerX, 0, verticalDividerX, context.zone.h - 1, SOLID, 2 )

	OpenTX.lcd.drawText( 10, 133, task.name, 0 )
	
	task.timer1.draw( 55, 13, XXLSIZE )
	task.timer2.draw( 120, 133, 0 )
	OpenTX.lcd.drawTimer( 190, 133, getValue( 'clock' ), 0 )

	for i=0,9 do
		task.times.draw( 312, 3 + 16*i, i+1, 0 )
	end
	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
