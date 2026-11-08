local toolName = "TNS|F3K Config|TNE"
--[[
	F3K Training - radio configuration tool
	Installed with the F3K_TRAINING folder (SCRIPTS/F3K_TRAINING/f3kcfg.lua): start it from the
	SD card browser (long press > Execute). A copy in SCRIPTS/TOOLS also shows it in the Tools menu.

	Edits the user settings of F3K_TRAINING/custom.lua, the same values as the online Configurator:
	only the "local NAME = value" lines are changed, the rest of the file is kept as is.
	No 'table' library on the radio: strings are concatenated by hand.
--]]

local FILES = { '/SCRIPTS/F3K_TRAINING/custom.lua', '/WIDGETS/F3K_TRAINING/custom.lua' }

-- Candidate source names, kept only if they exist on this radio (getFieldInfo)
local function letters()
	local out = {}
	for c = string.byte('a'), string.byte('r') do out[#out + 1] = 's' .. string.char(c) end
	return out
end
local function numbered(prefix, n)
	local out = {}
	for i = 1, n do out[#out + 1] = prefix .. i end
	return out
end
local SWITCHES = { letters(), numbered('sw', 6), numbered('ls', 64) }
local ANALOGS = { { 'rud', 'ele', 'thr', 'ail', 's1', 's2', 's3', 'ls', 'rs', 'lcs', 'rcs', '6pos',
	'trim-rud', 'trim-ele', 'trim-thr', 'trim-ail' }, letters(), numbered('sw', 6), numbered('ls', 64) }

local PARAMS = {
	{ name = 'PRELAUNCH_SWITCH', label = 'Prelaunch', kind = 'src', groups = SWITCHES },
	{ name = 'MENU_SWITCH', label = 'Menu switch', kind = 'src', groups = SWITCHES },
	{ name = 'MENU_SCROLL_ENCODER', label = 'Menu scroll', kind = 'src', groups = ANALOGS },
	{ name = 'TASK_DESCRIPTION', label = 'Task descr.', kind = 'bool' },
	{ name = 'PREP_COUNTDOWN', label = 'Prep count', kind = 'int', min = 0, max = 10 },
	{ name = 'TASK_LOG', label = 'Task log', kind = 'bool', optional = true },	-- missing in older custom.lua
	{ name = 'LAUNCH_HEIGHT_VOICE', label = 'Height voice', kind = 'bool', optional = true }
}

-- Same rule as the Configurator: first uncommented "local NAME = 'x' | "x" | true | false | 123" line
local VALUE_PATTERNS = { "^'[^'\r\n]*'", '^"[^"\r\n]*"', '^true', '^false', '^%-?%d+' }

local function locate( text, name )
	local decl = '[ \t]*local[ \t]+' .. name .. '[ \t]*=[ \t]*'
	local _, e = string.find( text, '^' .. decl )
	if not e then _, e = string.find( text, '\n' .. decl ) end
	if not e then return nil end
	for _, pat in ipairs( VALUE_PATTERNS ) do
		local s2, e2 = string.find( text, pat, e + 1 )
		if s2 then return s2, e2 end
	end
	return nil
end

local function decode( raw )
	local c = string.sub( raw, 1, 1 )
	if c == "'" or c == '"' then return string.sub( raw, 2, -2 ), c end
	if raw == 'true' then return true end
	if raw == 'false' then return false end
	return tonumber( raw )
end

-- Returns values, quotes ; or nil, name of the first missing mandatory setting
local function parse( text )
	local values, quotes = {}, {}
	for _, p in ipairs( PARAMS ) do
		local s, e = locate( text, p.name )
		if s then
			values[ p.name ], quotes[ p.name ] = decode( string.sub( text, s, e ) )
		elseif not p.optional then
			return nil, p.name
		end
	end
	return values, quotes
end

-- Calls put() with the pieces of the new file, in order. The file is never copied as a whole:
-- on the radio the pieces go straight to the SD card (whole-file copies ran out of Lua memory)
local function emit( text, values, quotes, put )
	local edits = {}	-- { s, e, v } sorted by position (no 'table' library: insertion by hand)
	for _, p in ipairs( PARAMS ) do
		local s, e = locate( text, p.name )
		local v = values[ p.name ]
		if s and v ~= nil then
			if p.kind == 'src' then
				local q = quotes[ p.name ] or "'"
				v = q .. v .. q
			end
			local i = #edits
			while i > 0 and edits[ i ].s > s do
				edits[ i + 1 ] = edits[ i ]
				i = i - 1
			end
			edits[ i + 1 ] = { s = s, e = e, v = tostring( v ) }
		end
	end
	local pos = 1
	for _, ed in ipairs( edits ) do
		put( string.sub( text, pos, ed.s - 1 ) )
		put( ed.v )
		pos = ed.e + 1
	end
	put( string.sub( text, pos ) )
end

local function build( text, values, quotes )
	local out = ''
	emit( text, values, quotes, function( s ) out = out .. s end )
	return out
end

local function readAll( path )
	local f = io.open( path, 'r' )
	if not f then return nil end
	local text = ''
	while true do
		local chunk = io.read( f, 1024 )
		if not chunk or #chunk == 0 then break end
		text = text .. chunk
	end
	io.close( f )
	return text
end

local function writeAll( path, text )
	local f = io.open( path, 'w' )
	if not f then return false end
	io.write( f, text )
	io.close( f )
	return true
end

local function sourceList( groups, current )
	local out = {}
	local found = false
	for _, g in ipairs( groups ) do
		for _, name in ipairs( g ) do
			if name == current or getFieldInfo( name ) then
				out[ #out + 1 ] = name
				found = found or name == current
			end
		end
	end
	-- a custom name ("Other…" in the Configurator) is kept as the first choice
	if not found and current then
		local all = { current }
		for _, name in ipairs( out ) do all[ #all + 1 ] = name end
		out = all
	end
	return out
end


-- Field ids of the controls that can be "moved to select" (logical switches change by themselves: skipped)
local function controlIds( list )
	local ids = {}
	for i, name in ipairs( list ) do
		local info = not string.find( name, '^ls%d' ) and getFieldInfo( name )
		if info then ids[ i ] = info.id end
	end
	return ids
end

local MOVE_THRESHOLD = 300	-- of -1024..1024: a switch flip or a clear stick / pot move, not noise


-- >>> UI <<< --
local st = {}		-- path, text, values, quotes, lists, ids, base, sel, top, editing, dirty, warned, msg, err

local function init()
	st = { sel = 1, top = 1, editing = false, dirty = false, warned = false, msg = nil, lists = {}, ids = {} }
	for _, path in ipairs( FILES ) do
		st.text = readAll( path )
		if st.text then st.path = path break end
	end
	if not st.text then
		st.err = 'custom.lua not found'
		return
	end
	local values, quotesOrMissing = parse( st.text )
	if not values then
		st.err = 'Missing ' .. quotesOrMissing
		return
	end
	st.values, st.quotes = values, quotesOrMissing
	for _, p in ipairs( PARAMS ) do
		if p.kind == 'src' then
			st.lists[ p.name ] = sourceList( p.groups, st.values[ p.name ] )
			st.ids[ p.name ] = controlIds( st.lists[ p.name ] )
			p.groups = nil	-- candidate names no longer needed: free the memory
		end
	end
	collectgarbage()
end

local function set( p, v )
	st.values[ p.name ] = v
	st.dirty = true
	st.warned = false
end

local function change( p, dir )
	local v = st.values[ p.name ]
	if p.kind == 'bool' then
		set( p, not v )
	elseif p.kind == 'int' then
		set( p, math.max( p.min, math.min( p.max, v + dir ) ) )
	else
		local list = st.lists[ p.name ]
		local idx = 1
		for i, name in ipairs( list ) do
			if name == v then idx = i end
		end
		set( p, list[ ( idx - 1 + dir ) % #list + 1 ] )
	end
end

-- Remembers the position of every control of the list: the first one moved away from it is selected
local function snapshot( p )
	st.base = {}
	for i, id in pairs( st.ids[ p.name ] ) do st.base[ i ] = getValue( id ) or 0 end
end

local function pickMoved( p )
	for i, id in pairs( st.ids[ p.name ] ) do
		if math.abs( ( getValue( id ) or 0 ) - st.base[ i ] ) > MOVE_THRESHOLD then
			set( p, st.lists[ p.name ][ i ] )
			snapshot( p )
			return
		end
	end
end

local function save()
	-- keep the previous file: a failed write would leave the training script without settings
	local bak = string.gsub( st.path, '%.lua$', '.bak' )
	local ok = writeAll( bak, st.text )
	local f = ok and io.open( st.path, 'w' )
	if f then
		emit( st.text, st.values, st.quotes, function( s ) io.write( f, s ) end )
		io.close( f )
	end

	-- check by reading the file back, with only that copy in memory
	st.text = nil
	collectgarbage()
	st.text = f and readAll( st.path )
	local back = st.text and parse( st.text )
	for _, p in ipairs( PARAMS ) do
		if back and st.values[ p.name ] ~= nil and back[ p.name ] ~= st.values[ p.name ] then back = nil end
	end
	if not back then
		st.err = 'Write error! See custom.bak'
		return
	end
	st.dirty = false
	st.msg = 'Saved'
end

local function valueText( p )
	local v = st.values[ p.name ]
	if v == nil then return 'n/a (old file)' end
	if p.kind == 'bool' then return v and 'ON' or 'OFF' end
	if p.kind == 'int' then return v .. ' s' end
	return string.upper( v )
end

local function draw()
	lcd.clear()
	local big = LCD_W >= 320		-- color radios
	local lh = big and 20 or 8
	local vx = big and 220 or ( LCD_W > 128 and 100 or 64 )
	local h = LCD_H or 64

	lcd.drawText( 1, 0, st.msg or 'F3K Config', INVERS )
	if st.err then
		lcd.drawText( 1, lh + 2, st.err )
		lcd.drawText( 1, 2 * lh + 2, 'EXIT to quit' )
		return
	end

	local rows = #PARAMS + 1
	local visible = math.floor( ( h - lh ) / lh )
	if st.sel < st.top then st.top = st.sel end
	if st.sel >= st.top + visible then st.top = st.sel - visible + 1 end

	for i = st.top, math.min( rows, st.top + visible - 1 ) do
		local y = lh * ( i - st.top + 1 )
		local selected = i == st.sel
		if i > #PARAMS then
			lcd.drawText( 1, y, st.dirty and 'SAVE' or 'SAVE (no changes)', selected and INVERS or 0 )
		else
			local p = PARAMS[ i ]
			lcd.drawText( 1, y, p.label, ( selected and not st.editing ) and INVERS or 0 )
			lcd.drawText( vx, y, valueText( p ), ( selected and st.editing ) and ( INVERS + ( BLINK or 0 ) ) or 0 )
		end
	end
end

local function is( event, a, b, c, d )
	return event ~= nil and event ~= 0 and ( event == a or event == b or event == c or event == d )
end

local function run( event )
	local NEXT = is( event, EVT_VIRTUAL_NEXT, EVT_ROT_RIGHT, EVT_PLUS_BREAK, EVT_PLUS_REPT )
	local PREV = is( event, EVT_VIRTUAL_PREV, EVT_ROT_LEFT, EVT_MINUS_BREAK, EVT_MINUS_REPT )
	local ENTER = is( event, EVT_VIRTUAL_ENTER, EVT_ENTER_BREAK )
	local EXIT = is( event, EVT_VIRTUAL_EXIT, EVT_EXIT_BREAK )
	local dir = NEXT and 1 or ( PREV and -1 or 0 )

	if st.err then
		draw()
		return EXIT and 1 or 0
	end

	local p = PARAMS[ st.sel ]
	if st.editing then
		if dir ~= 0 then change( p, dir ) end
		if p.kind == 'src' then pickMoved( p ) end
		if ENTER or EXIT then
			st.editing = false
			st.msg = nil
		end
	elseif dir ~= 0 then
		st.sel = math.max( 1, math.min( #PARAMS + 1, st.sel + dir ) )
	elseif ENTER then
		st.msg = nil
		if not p then
			if st.dirty then save() end
		elseif st.values[ p.name ] ~= nil then
			if p.kind == 'bool' then
				change( p, 1 )
			else
				st.editing = true
				if p.kind == 'src' then
					snapshot( p )
					st.msg = 'Move control/scroll'
				end
			end
		end
	elseif EXIT then
		if st.dirty and not st.warned then
			st.warned = true
			st.msg = 'Not saved! EXIT=quit'
		else
			return 1
		end
	end

	draw()
	return 0
end

return { init = init, run = run, parse = parse, build = build }
