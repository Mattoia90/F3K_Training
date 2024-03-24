--[[
	F3K Training - 	Mike, ON4MJ

	task_n.lua
	Task N : Best flight (10 min window)
--]]


local taskN = dofile( F3K_SCRIPT_PATH .. 'lasttaskbase.lua' )


taskN.MAX_FLIGHT_TIME = 600
taskN.COUNT = 1


-- public interface
function taskN.init( win )
	taskN.WINDOW_TIME = win
	taskN.commonInit( 'Best Flight', taskN.COUNT, 'taskn' )
end


return taskN
