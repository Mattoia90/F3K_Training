--[[
	F3K Training - 	Mike, ON4MJ

	opentx_srv.lua
	Tries to abstract the differences between OpenTX versions
	Does the version detection based on the documented behaviour and the actual one

	backgroundRun()	either runs the background function or not (meant to be called from display)

	CONSTANTS	because units IDs change from one version to the other

	lcd.f()		because there are differences in the display stuff between releases too (alignment, etc...)
--]]


local openTX = {}


local function createLcdLayer()
	TEXT_INVERTED_BGCOLOR = 0

	local function noOp()
	end

	local function drawEmptyTimer( x, y, flags )
		lcd.drawText( x, y, '--:--', flags )
	end

	return {
		clear = lcd.clear,
		drawText = lcd.drawText,
		drawNumber = lcd.drawNumber,
		drawTimer = lcd.drawTimer,
		drawEmptyTimer = drawEmptyTimer,
		drawLine = lcd.drawLine,
		drawFilledRectangle = lcd.drawFilledRectangle,
		setColor = noOp
	}
end


local function createWidgetLayer()
	local Context = nil
	
	-- this must be called at least once before using any draw method
	local function updateContext( context )
		Context = context
	end

	local function noOp()
	end

	function drawText( x, y, text, flags )
		lcd.drawText( Context.zone.x + x, Context.zone.y + y, text, flags )
	end

	function drawNumber( x, y, value, flags )
		lcd.drawNumber( Context.zone.x + x, Context.zone.y + y, value, flags )
	end

	function drawTimer( x, y, value, flags )
		lcd.drawTimer( Context.zone.x + x, Context.zone.y + y, value, flags )
	end

	function drawEmptyTimer( x, y, flags )
		xSize = 9	-- this should change depending on flags (height too, probably)
		yDash = y + 11
		drawLine( x, yDash, x+xSize, yDash, SOLID, 2 )
		x = x + xSize + 2
		drawLine( x, yDash, x+xSize, yDash, SOLID, 2 )
		x = x + xSize + 2
		drawText( x, y, ':', flags )
		x = x + xSize - 2
		drawLine( x, yDash, x+xSize, yDash, SOLID, 2 )
		x = x + xSize + 2
		drawLine( x, yDash, x+xSize, yDash, SOLID, 2 )
	end

	function drawLine( x1, y1, x2, y2, pattern, flags )
		lcd.drawLine( Context.zone.x + x1, Context.zone.y + y1, Context.zone.x + x2, Context.zone.y + y2, pattern, flags )
	end

	function drawFilledRectangle( x, y, w, h, flags )
		lcd.drawFilledRectangle( Context.zone.x + x, Context.zone.y + y, w, h, flags )
	end

	return {
		updateContext = updateContext,
		
		clear = noOp,
		drawText = drawText,
		drawNumber = drawNumber,
		drawTimer = drawTimer,
		drawEmptyTimer = drawEmptyTimer,
		drawLine = drawLine,
		drawFilledRectangle = drawFilledRectangle,
		setColor = lcd.setColor
	}
end


local function runningTwoPointZero()
	RIGHT = 0  -- RIGHT not supported on less than 2.2 so make it a global 0

	openTX.backgroundRun = function( obj )
		return obj.background()
	end
	openTX.MINUTES = 16
	openTX.SECONDS = 17

	openTX.lcd = createLcdLayer()
end


local function runningTwoPointOne()
	RIGHT = 0  -- RIGHT not supported on less than 2.2 so make it a global 0

	openTX.backgroundRun = function( obj )
		return obj.backgroundState()
	end
	openTX.MINUTES = 23
	openTX.SECONDS = 24

	openTX.lcd = createLcdLayer()
end


local function runningTwoPointTwo( widget )
	openTX.backgroundRun = function( obj )
		return obj.background()
	end
	openTX.MINUTES = 25
	openTX.SECONDS = 26

	if widget then
		openTX.lcd = createWidgetLayer()
	else
		openTX.lcd = createLcdLayer()
	end
end

local function runningTwoPointThree( widget )
	openTX.backgroundRun = function( obj )
		return obj.background()
	end
	openTX.MINUTES = 36
	openTX.SECONDS = 37

	if widget then
		openTX.lcd = createWidgetLayer()
	else
		openTX.lcd = createLcdLayer()
	end
end



-- Try and determine if this is a HORUS Tx.  And therefore, if we are in a widget
local widget = false

local ok, msg = pcall( function()
	local dummy = lcd.RGB( 0, 0, 0 )

	-- We survived...  This is a Horus
	widget = true

--	print( 'F3K: Horus Detected' )
end )

if not ok then
	print(msg)
end

ok, msg = pcall( function()
	local ver = getVersion()
	print("Read version "..ver)
	if type( ver ) == 'string' then
		local ver = string.sub( ver, 1, 3 )
		if ver == '2.0' then
			--print( 'F3K: OpenTX Version Detected = 2.0' )
			runningTwoPointZero()
		elseif ver == '2.1' then
			--print( 'F3K: OpenTX Version Detected = 2.1' )
			runningTwoPointOne()
		elseif ver == '2.2' then
			--print( 'F3K: OpenTX Version Detected = 2.2' )
			runningTwoPointTwo( widget )
		else
			--print( 'F3K: OpenTX Version >= 2.3 assumed' )
			runningTwoPointThree( widget )
		end
	end
end )

if not ok then
	print(msg)
	-- no string lib ?
	print( 'F3K: OpenTX Version Detected = 2.0 assumed (no string lib)' )
	runningTwoPointZero()
end


return openTX
