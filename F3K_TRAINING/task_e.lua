--[[
	F3K Training - 	Mike, ON4MJ

	task_e.lua
	Task E : Poker - variable target time (10 or 15 min window)

	Up to 3 target times, announced before the launch. Unlimited launches to reach or exceed
	the announced target; it can't be changed until it has been reached (strict lock).
	The last call may be "end of working time" (W): one attempt only.
	Score = sum of the reached targets.

	Target declaration (MenuScrollEncoder, throttle by default):
	 * after the task start or after landing with a reached target, the target is W (all the remaining
	   working time), whatever the stick position
	 * once the stick moves (> STICK_DEADBAND), the target follows it: stick up = longer,
	   scaled on the remaining working time (rounded up to 10s) in 10s steps; the top end (>= W_ZONE) is W
	 * the target is locked at the launch and announced; the flight timer counts down from it
--]]


local taskE = dofile( F3K_SCRIPT_PATH .. 'taskbase.lua' )


taskE.MAX_FLIGHT_TIME = 600
taskE.TARGET_COUNT = 3
taskE.STICK_DEADBAND = 102	-- ~5% of the stick travel before the selection leaves the W default
taskE.W_ZONE = 0.97		-- stick fraction from which the selection is W

taskE.targets = {}		-- reached targets (seconds)
taskE.selected = 600		-- current selection (seconds; W = remaining working time)
taskE.selW = true
taskE.locked = nil		-- locked target (seconds) or nil
taskE.lockedW = false
taskE.adjusting = false
taskE.refPos = 0
taskE.reached = false		-- the locked target has been reached during the current flight
taskE.done = false


local function playTime( t )
	if playDuration then
		playDuration( t, 0 )
		return
	end
	local val = math.floor( t / 60 )
	if val > 0 then
		playNumber( val, OpenTX.MINUTES, 0 )
	end
	val = t % 60
	if val > 0 then
		playNumber( val, OpenTX.SECONDS, 0 )
	end
end


-- Back to the W default, with the current stick position as reference
local function unlock()
	taskE.locked = nil
	taskE.lockedW = false
	taskE.adjusting = false
	taskE.selW = true
	taskE.refPos = getValue( Options.MenuScrollEncoder )
end


local function clearState()
	taskE.targets = {}
	taskE.reached = false
	taskE.done = false
	unlock()
end


local function endTask()
	taskE.timer1.stop()
	taskE.playSound( 'taskend' )
	taskE.done = true
	taskE.state = 5
end


function taskE.select( remaining )
	if taskE.locked then
		return
	end
	local pos = getValue( Options.MenuScrollEncoder )
	if not taskE.adjusting and math.abs( pos - taskE.refPos ) > taskE.STICK_DEADBAND then
		taskE.adjusting = true
	end

	local f = math.max( 0, math.min( 1, (pos + 1024) / 2048 ) )
	if not taskE.adjusting or f >= taskE.W_ZONE then
		taskE.selW = true
		taskE.selected = remaining
	else
		-- the scale follows the remaining time, rounded up to 10s: stable for 10s at a time
		local scale = math.ceil( remaining / 10 ) * 10
		taskE.selW = false
		taskE.selected = math.max( 10, math.floor( f * scale / 10 ) * 10 )
	end
end


function taskE.earlyReset()
	if taskE.earlyResetBase() then
		clearState()
		return true
	end
	return false
end


function taskE.endOfWindow()
	if taskE.timer1.getVal() <= 0 then
		local timeRunning, val = taskE.timer2.stop()
		taskE.timer1.stop()

		if timeRunning then
			local flown = taskE.timer2.getTarget() - val
			taskE.times.addTime( flown )
			if taskE.lockedW then
				-- W : the flight time up to the end of the working time
				taskE.targets[ #taskE.targets + 1 ] = math.min( flown, taskE.locked )
			elseif val <= 0 and not taskE.reached then
				taskE.targets[ #taskE.targets + 1 ] = taskE.locked
			end
		end

		taskE.playSound( 'taskend' )
		taskE.done = true
		taskE.state = 5
		return true
	end
	return false
end


-- state functions
local baseResetState = taskE.resetState
function taskE.resetState()
	baseResetState()
	if taskE.state == 2 then
		clearState()
		taskE.selected = taskE.WINDOW_TIME
	end
end


local baseStartedState = taskE.startedState
function taskE.startedState()
	-- The first target can be chosen during the prep time (or while waiting for the first launch)
	taskE.select( taskE.WINDOW_TIME )
	baseStartedState()
end


function taskE.landedState()
	if not taskE.endOfWindow() and not taskE.earlyReset() then
		local remaining = taskE.timer1.getVal()
		taskE.select( remaining )

		if F3KConfig.launched() then
			if not taskE.locked then
				taskE.lockedW = taskE.selW
				taskE.locked = taskE.selW and remaining or taskE.selected
			end
			taskE.reached = false
			taskE.timer2.start( taskE.locked )
			taskE.flightCount = taskE.flightCount + 1
			taskE.state = 3

			if taskE.lockedW then
				taskE.playSound( 'endwt' )
			else
				taskE.playSound( 'target' )
				playTime( taskE.locked )
				if taskE.locked > remaining then
					taskE.playSound( 'cant' )
				end
			end
		end
	end
end


function taskE.flyingState()
	if not taskE.endOfWindow() and not taskE.earlyReset() then
		if not taskE.lockedW and not taskE.reached and taskE.timer2.getVal() <= 0 then
			-- Target reached
			taskE.reached = true
			taskE.targets[ #taskE.targets + 1 ] = taskE.locked
			if #taskE.targets >= taskE.TARGET_COUNT then
				taskE.timer2.stop()
				taskE.times.addTime( taskE.locked )
				endTask()
			else
				taskE.playSound( 'welldone' )
			end

		elseif F3KConfig.landed() then
			taskE.timer2.stop()
			taskE.times.addTime( taskE.timer2.getTarget() - taskE.timer2.getVal() )

			if taskE.lockedW then
				-- W landed before the end of the working time : one attempt only, no score
				endTask()
			else
				if taskE.reached then
					unlock()
				end
				taskE.state = 4
			end
		end
	end
end


-- public interface
function taskE.init( win )
	taskE.WINDOW_TIME = win or 600
	taskE.MAX_FLIGHT_TIME = taskE.WINDOW_TIME
	if taskE.WINDOW_TIME > 600 then
		taskE.commonInit( 'Poker 15', taskE.TARGET_COUNT, 'taskee' )
	else
		taskE.commonInit( 'Poker', taskE.TARGET_COUNT, 'taske' )
	end

	taskE.times.getTotal = function()
		local tot = 0
		for i = 1, #taskE.targets do
			tot = tot + taskE.targets[ i ]
		end
		return tot
	end

	clearState()
	taskE.selected = taskE.WINDOW_TIME
end


return taskE
