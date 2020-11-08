--[[
	F3K Training - 	Mike, ON4MJ

	task_m.lua
	Fly-off Task M (Increasing time by 2 minutes “Huge Ladder”)
    Each competitor must launch his/her model glider exactly three (3) times to achieve three (3) target times as follows: 3:00 (180 seconds), 5:00 (300 seconds), 7:00 (420 seconds). The targets must be flown in the increasing order as specified. The actual times of each flight up to (not exceeding) the target time will be added up and used as the final score for the task. The competitors do not have to reach or exceed the target times to count each flight time.
    Working time: 15 minutes.
--]]


local taskM = dofile( F3K_SCRIPT_PATH .. 'taskbase-15min.lua' )


taskM.MAX_FLIGHT_TIME = 180 	-- This won't be a constant here, but for consistency (and memory !), we'll keep it uppercase'd
taskM.TIMES_SORTED = false

taskM.current = 1
taskM.done = false


function taskM.earlyReset() 
	if taskM.earlyResetBase() then
		taskM.MAX_FLIGHT_TIME = 180

		taskM.current = 1
		taskM.done = false

		taskM.initFlightTimer()

		return true
	end
	return false
end


function taskM.endOfWindow()
	if taskM.timer1.getVal() <= 0 then
		local timeRunning, val = taskM.timer2.stop()
		taskM.timer1.stop()

		taskM.playSound( 'taskend' )

		if timeRunning and not taskM.done then
			val = taskM.MAX_FLIGHT_TIME - val
			taskM.times.pushTime( val )
			taskM.current = taskM.current + 1
		end

		taskM.done = true
		taskM.state = 5
		return true
	end
	return false
end


-- state functions
function taskM.flyingState()
	if not taskM.endOfWindow() and not taskM.earlyReset() then
		-- Wait for the pilot to catch/land (he/she's supposed to pull the temp switch at that moment)
		if F3KConfig.landed() then
			taskM.timer2.stop()

			taskM.times.pushTime( taskM.MAX_FLIGHT_TIME - taskM.timer2.getVal() )

			taskM.MAX_FLIGHT_TIME = taskM.MAX_FLIGHT_TIME + 120
			taskM.current = taskM.current + 1

			if taskM.current > 3 then
				taskM.timer1.stop()
				taskM.playSound( 'taskend' )
				taskM.done = true
				taskM.state = 5
			else
				taskM.initFlightTimer()
				taskM.playSound( 'nxttarget' )
				taskM.playTime( taskM.MAX_FLIGHT_TIME )
				taskM.state = 4
			end
		end
	end
end



-- public interface
function taskM.init()
	taskM.name = 'Huge Ladder'
	taskM.wav = 'taskm'

	taskM.times = createTimeKeeper( 3, 180 )	-- We'll handle the max flight time ourselves here
	taskM.state = 1

	taskM.initPrepTimer()
	taskM.initFlightTimer()
end


return taskM
