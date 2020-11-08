--[[
	F3K Training - 	Mike, ON4MJ

	task_d.lua
	Task D : Ladder (10 min window)
--]]


local taskD = dofile( F3K_SCRIPT_PATH .. 'taskbase.lua' )


taskD.MAX_FLIGHT_TIME = 30 	-- This won't be a constant here, but for consistency (and memory !), we'll keep it uppercase'd

taskD.flights = {}
taskD.current = 1
taskD.done = false


function taskD.earlyReset()
	if taskD.earlyResetBase() then
		taskD.MAX_FLIGHT_TIME = 30

		taskD.flights = {}
		taskD.current = 1
		taskD.done = false

		taskD.initFlightTimer()

		return true
	end
	return false
end


function taskD.endOfWindow()
	if taskD.timer1.getVal() <= 0 then
		local timeRunning, val = taskD.timer2.stop()
		taskD.timer1.stop()

		taskD.playSound( 'taskend' )

		if timeRunning and not taskD.done then
			val = taskD.MAX_FLIGHT_TIME - val
			taskD.flights[ taskD.current ] = val
			if val >= taskD. MAX_FLIGHT_TIME then
				taskD.times.pushTime( taskD.MAX_FLIGHT_TIME )
				taskD.current = taskD.current + 1
				if taskD.MAX_FLIGHT_TIME == 120 then
					taskD.playSound( 'welldone' )
				end
			end
		end

		taskD.done = true
		taskD.state = 5
		return true
	end
	return false
end

-- state functions
function taskD.flyingState()
	if not taskD.endOfWindow() and not taskD.earlyReset() then
		-- Wait for the pilot to catch/land (he/she's supposed to pull the temp switch at that moment)
		if F3KConfig.landed() then
			taskD.timer2.stop()

			local val = taskD.timer2.getVal()
			taskD.flights[ taskD.current ] = taskD.MAX_FLIGHT_TIME - val
			if val <= 0 then
				-- we did it !
				taskD.times.pushTime( taskD.MAX_FLIGHT_TIME ) -- store it to get the total score later

				taskD.MAX_FLIGHT_TIME = taskD.MAX_FLIGHT_TIME + 15
				taskD.current = taskD.current + 1

				if taskD.MAX_FLIGHT_TIME > 120 then
					-- we're done, congrats !
					taskD.timer1.stop()
					taskD.playSound( 'welldone' )
					taskD.done = true
					taskD.state = 5
				else
					if taskD.MAX_FLIGHT_TIME > taskD.timer1.getVal() then
						-- not enough time remaining to complete the next step
						taskD.playSound( 'cant' )
						taskD.done = true
					else
						taskD.initFlightTimer()

						taskD.playSound( 'nxttarget' )
						taskD.playTime( taskD.MAX_FLIGHT_TIME )
					end
				end
			end
			taskD.state = 4
		end
	end
end


-- public interface
function taskD.init()
	taskD.name = 'Ladder'
	taskD.wav = 'taskd'

	taskD.times = createTimeKeeper( 7, 120 )	-- We'll handle the max flight time ourselves here
	taskD.state = 1

	taskD.initPrepTimer()
	taskD.initFlightTimer()
end


return taskD
