--[[
	F3K Training - 	Mike, ON4MJ

	task_n.lua
	Task N : Best flight (10 min window)
--]]


local taskN = dofile( F3K_SCRIPT_PATH .. 'besttaskbase.lua' )

taskN.MAX_FLIGHT_TIME = 599
taskN.BEST_COUNT = 1

-- public interface
function taskN.init( win )
	taskN.WINDOW_TIME = win
	taskN.commonInit( 'Best Flight', taskN.BEST_COUNT, 'taskn' )
end


return taskN
