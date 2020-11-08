--[[
	F3K Training - 	Mike, ON4MJ

	timerkeeper.lua

	Manages the flight times
	 * keeps several flight times
	 * computes the total considering the max flight time
--]]

function createTimeKeeper( size, limit )
	local tab = {}
	local LIMIT = limit


	local function initialize( size )
		for i=1,size do
			tab[ i ] = 0
		end
	end


	-- insert time at the right place in a sorted list
	local function addTime( t )
		local i = #tab - 1
		while i > 0 and t > tab[ i ] do
			tab[ i + 1 ] = tab[ i ]
			i = i - 1
		end
		tab[ i + 1 ] = t
	end


	-- stacks time, discarding the older values
	local function pushTime( t )
		local size = #tab - 1
		for i=2,size do
			tab[ i-1 ] = tab[ i ]
		end
		tab[ size ] = t
	end


	local function getVal( i, truncated )
		-- Precondition : 1 <= i <= (#tab - 1)
		if truncated then
			return math.min( tab[ i ], LIMIT )
		end
		
		return tab[ i ]
	end

	local function getTotal( n )
		local tot = 0
		n = n or #tab-1
		for i=1,n do
			tot = tot + math.min( tab[ i ], LIMIT )  -- had to do the math here instead of calling getVal or I was getting a strange error: Script   F3K error: /SCRIPTS/F3K_TRAINING/timekeeper.lua:57: attempt to perform arithmetic on a lightfunction value
		end
		return tot
	end


	local function reset()
		initialize( #tab )
	end


	local function draw( x, y, i, att )
		local val = tab[ i ]
		if val > 0 then
			OpenTX.lcd.drawTimer( x, y, val, att )
		else
			--OpenTX.lcd.drawText( x, y, '--:--', att )
			OpenTX.lcd.drawEmptyTimer( x, y, att )
		end
	end


	-- "constructor"
	initialize( size + 1 )

	return { 
		addTime=addTime, 
		pushTime=pushTime,
		getVal=getVal,
		getTotal=getTotal,
		reset=reset,
		draw=draw
	}
end

return createTimeKeeper
