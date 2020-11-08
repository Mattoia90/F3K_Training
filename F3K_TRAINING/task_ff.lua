--[[
	F3K Training - 	Mike, ON4MJ

	task_ff.lua
	Free flight : start a simple timer when the launch switch is released
	This removes the need to have a copy of the model if you're not flying tasks
--]]

-- Not working in 2.1.x
--local CLOCK = getFieldInfo( 'clock' ).id


local taskFF = {
	running = true,

	times,	-- best times (time keeper object)

	timer1,	-- work time

	state,	-- 1=reset; 2=start; 3=flying; 4=landed, 5=end

	name,
	wav
}



function taskFF.playSound( sound )
	playFile( F3KConfig.SOUND_PATH .. sound .. '.wav' )
end


function taskFF.initTimers()
	-- createTimer parameters : timerId, startValue, countdownBeep, minuteBeep
	taskFF.timer1 = createTimer( 0, 0, 0, true )	-- current flight time
	taskFF.timer2 = createTimer( 1, 0, 0, false )
end


function taskFF.init()
	taskFF.name = 'Free Flight'
	taskFF.wav = 'taskff'

	taskFF.times = createTimeKeeper( 10, 0 )
	taskFF.state = 1 	-- 1=reset
	taskFF.initTimers()
end


-- Recurring tests of the end of task conditions (user reset or work time ellapsed)
function taskFF.earlyReset()
	if getValue( Options.MenuSwitch ) <= 0 then
		-- Stop the timers and reset the internal state
		taskFF.timer1.stop()
		taskFF.timer2.stop()
		taskFF.state = 1
		return true
	end
	return false
end


-- State functions
function taskFF.resetState()
	-- Wait for the start of the task
	if getValue( Options.MenuSwitch ) > 0 then
		taskFF.playSound( taskFF.wav )

		-- reset the scores
		taskFF.times.reset()

		taskFF.initTimers()
		taskFF.timer2.start()

		taskFF.state = 2
	elseif getValue( Options.MenuSwitch ) < 0 then
		taskFF.running = false
	end
end



function taskFF.startedState()
	taskFF.state = 4
end


function taskFF.flyingState()
	if not taskFF.earlyReset() then
		-- Wait for the pilot to catch/land/crash (he/she's supposed to pull the temp switch at that moment)
		if F3KConfig.landed() then
			taskFF.timer1.stop()
			local val = taskFF.timer1.getVal()
			if val > 0 then
				taskFF.times.pushTime( val )
			end
			taskFF.state = 4
		end
	end
end


function taskFF.landedState()
	if not taskFF.earlyReset() then
		-- Wait for the pilot to launch the plane
		if F3KConfig.launched() then
			taskFF.timer1.start()
			taskFF.state = 3
		end
	end
end


function taskFF.endState()
	-- Wait for reset
	if taskFF.earlyReset() then
		F3KConfig.resetLaunchDetection()
	end
end


function taskFF.backgroundState()
	return taskFF.running
end	


-- Run the correct function based on the current state
function taskFF.background()
	({ taskFF.resetState, taskFF.startedState, taskFF.flyingState, taskFF.landedState, taskFF.endState })[ taskFF.state ]()
	return taskFF.running
end


return taskFF
