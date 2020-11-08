--[[
	F3K Training - 	Mike, ON4MJ

	lasttaskbase.lua
	Specific state functions for "last" task serie (again, this will be overrided by specific tasks if needed)
--]]


local taskBase = dofile( F3K_SCRIPT_PATH .. 'taskbase.lua' )


taskBase.COUNT = 0
taskBase.possibleImprovement = 0

taskBase.TIMES_SORTED = false


function taskBase.earlyReset()
	if taskBase.earlyResetBase() then
		taskBase.possibleImprovement = 0
		return true
	end
	return false
end

function taskBase.flyingState()
	if not taskBase.endOfWindow() and not taskBase.earlyReset() then
		-- Wait for the pilot to catch/land (he/she's supposed to pull the temp switch at that moment)
		if F3KConfig.landed() then
			taskBase.timer2.stop()
			taskBase.times.pushTime( taskBase.timer2.getTarget() - taskBase.timer2.getVal() )

			local remaining = math.min( taskBase.timer1.getVal(), taskBase.MAX_FLIGHT_TIME )
			taskBase.possibleImprovement = remaining - taskBase.times.getVal( 1, true )     -- possible improvement against the first flight of the list
			if taskBase.flightCount >= taskBase.COUNT and taskBase.possibleImprovement <= 0 then
				if not taskBase.shoutedStop then
					taskBase.playSound( 'stop' )
					taskBase.shoutedStop = true
				end
			end

			taskBase.state = 4
		else
			if taskBase.timer2.getVal() <= 0 and not taskBase.wellDone then
				if taskBase.times.getTotal() == taskBase.MAX_FLIGHT_TIME * (taskBase.COUNT - 1) then
					taskBase.playSound( 'welldone' )
					taskBase.wellDone = true
					taskBase.shoutedStop = true
				end
			end
		end
	end
end

function taskBase.landedState()
	if not taskBase.endOfWindow() and not taskBase.earlyReset() then
		-- Wait for the pilot to launch the plane
		if F3KConfig.launched() then
			local remaining = taskBase.timer1.getVal()

			if remaining < taskBase.MAX_FLIGHT_TIME then
				taskBase.timer2.start( remaining )
				taskBase.playSound( 'remaining' )
				taskBase.playTime( remaining )
			else
				taskBase.timer2.start()
			end
			taskBase.flightCount = taskBase.flightCount + 1
			taskBase.state = 3

			if taskBase.shoutedStop then
				taskBase.shoutedStop = false
				taskBase.wellDone = false
			end
		end
	end
end


return taskBase
