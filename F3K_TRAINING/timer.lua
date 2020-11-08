--[[
	F3K Training - 	Mike, ON4MJ

	timer.lua

	Wrapper around the timer interface
	
	countdownBeep 	integer (none, beep, voice)
	minuteBeep	bool
--]]

function createTimer( timerId, startValue, countdownBeep, minuteBeep )
	-- Precondition: timerId is either 0 or 1
	local id = timerId
	local timer = model.getTimer( id )
	local originalStartValue = timer.start
	local target = 0


	local function getVal()
		timer.value = model.getTimer( id ).value
		return timer.value
	end

	local function getTarget()
		return target
	end

	local function start( newStartValue )
		model.resetTimer( id )

		if not newStartValue then
			newStartValue = originalStartValue
		end
		timer.value = newStartValue
		timer.start = newStartValue
		target = newStartValue

		timer.mode = 1
		model.setTimer( id, timer )
	end

	local function stop()
		timer = model.getTimer( id )
		local running = (timer.mode > 0)
		timer.mode = 0
		model.setTimer( id, timer )
		return running, timer.value
	end

	local function draw( x, y, att )
		local val = getVal()
		OpenTX.lcd.drawTimer( x, y, val, att )
		return val
	end

	local function drawReverse( x, y, att )
		local val = target - getVal()
		OpenTX.lcd.drawTimer( x, y, val, att )
		return val
	end


	-- "constructor"
	timer.countdownBeep = countdownBeep
	timer.minuteBeep = minuteBeep
	timer.persistent = 0

	if startValue then
		originalStartValue = startValue
		timer.value = startValue
		timer.start = startValue
		target = startValue
	end

	timer.mode = 0
	model.setTimer( id, timer )


	return {
		start = start,
		stop = stop,
		draw = draw,
		drawReverse = drawReverse,
		getVal = getVal,
		getTarget = getTarget
	}
end

return createTimer
