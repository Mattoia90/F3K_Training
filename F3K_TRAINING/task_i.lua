--[[
	F3K Training - 	Mike, ON4MJ

	task_i.lua
	Task I : Best Three (10 min window)
--]]


local taskI = dofile( F3K_SCRIPT_PATH .. 'besttaskbase.lua' )


taskI.MAX_FLIGHT_TIME = 200
taskI.BEST_COUNT = 3


-- public interface
function taskI.init()
	taskI.commonInit( 'Best three', taskI.BEST_COUNT, 'taski' )
end


return taskI