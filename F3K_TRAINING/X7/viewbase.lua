local display = {}

-- task (optional): out of flight, the last launch height (L:) replaces the live altitude (A:)
function display.drawTelemetry( task )
	local getFirstValue = OpenTX.getFirstValue
	local modelVoltage = getFirstValue(F3KConfig.MODEL_VOLTAGE)
	local modelText = (modelVoltage ~= nil and string.format("M:%.1f", modelVoltage)) or "M:-.-"
	lcd.drawText(0, 38, modelText, 0)

	local radioVoltage = getFirstValue(F3KConfig.RADIO_VOLTAGE)
	local radioText = (radioVoltage ~= nil and string.format("R:%.1f", radioVoltage)) or "R:-.-"
	lcd.drawText(28, 38, radioText, 0)

	local launch = task and task.state ~= 3 and task.times.getLastHeight()
	local altitude = getFirstValue(F3KConfig.HEIGHT)
	local altitudeText = (launch and string.format("L:%d", launch))
		or (altitude ~= nil and string.format("A:%.0f", altitude)) or "A:?"
	lcd.drawText(56, 38, altitudeText, 0)
end

function display.drawCommon( task )
	lcd.drawText( 2, 2, task.name, 0 )
	task.timer1.draw( 24, 18, DBLSIZE )
	display.drawTelemetry( task )

	lcd.drawLine( 0, 47, 89, 47, SOLID, 2 )
	lcd.drawLine( 90, 0, 90, 63, SOLID, 2 )
end

function display.drawCommonLarge( task )
	lcd.drawText( 2, 2, task.name, 0 )
	task.timer1.draw( 22, 18, DBLSIZE )
	display.drawTelemetry( task )

	lcd.drawLine( 0, 47, 83, 47, SOLID, 2 )
	lcd.drawLine( 84, 0, 84, 63, SOLID, 2 )
end

function display.drawCommonLastBest( task )
	display.drawCommon( task )

	lcd.drawText( 2, 53, 'Current: ', 0 )
	task.timer2.drawReverse( lcd.getLastPos(), 50, MIDSIZE )

	lcd.drawFilledRectangle( 91, 53, 37, 11, 0 )
	lcd.drawTimer( 100, 55, task.times.getTotal(), INVERS )
end


return display