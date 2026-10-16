--[[
	F3K Training - 	Mike, ON4MJ

	X7/view_k.lua
	Q7 view for the Big Ladder task
--]]


local task = dofile( F3K_SCRIPT_PATH .. 'task_k.lua' )
local display = dofile( F3K_SCRIPT_PATH .. 'X7/viewbase.lua' )


function task.display()
	display.drawCommonLarge( task )

	if not task.done then
		lcd.drawText( 14, 53, task.MAX_FLIGHT_TIME .. 's: ', 0 )
		task.timer2.drawReverse( lcd.getLastPos(), 50, MIDSIZE )
	else
		lcd.drawText( 22, 50, 'Done !', MIDSIZE )
	end

	local total = 0
	for i=0,4 do
	--print("i : " .. i)
		local y = 2 + 9 * i
		local max = 60 + 30 * i

		-- Render as one fixed-width label to avoid RIGHT/alignment differences
		-- across firmware versions that can cause overlap artifacts.
		local targetLabel = string.format( '%3ds', max )
		lcd.drawText( 85, y, targetLabel, SMLSIZE )

		if i < task.current - 1 then
		--print (7-task.current+i)
			local val = task.times.getVal( 7-task.current+i )
			--local val = task.times.getVal( 2 + 1 * i )
			
			--print (val)
			lcd.drawTimer( 106, y, val, SMLSIZE )
			total = total + math.min( max, val )
		end
	end

	lcd.drawFilledRectangle( 85, 47, 52, 18, 0 )
	lcd.drawTimer( 106, 53, total, INVERS + SMLSIZE )

	return OpenTX.backgroundRun( task )
end


return { init=task.init, background=task.background, display=task.display }
