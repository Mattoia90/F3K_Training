--[[
	F3K Training

	trainingpath.lua
	Training Path: runs a sequence of tasks like a competition.
	The path files are made by the online Training Path page (RCCoreConfig) and copied to TR_PATHS/<name>.lua:
		return { name='Level 1', prep=180, test=45, nofly=60, tasks={ 'A', 'D' } }
	For every task: prep time -> test flight -> no-fly time -> task working time.

	Menu: select "Training Path", switch to run, scroll the throttle to pick a file, pull the prelaunch switch to start.
	Every task line of the task log gets a Path column (name|runId|index/total), see tasklog.lua.

	Returns a function( viewDir ) building a menu entry object { init, background, display }.
	viewDir is the folder of the task views for this radio: 'WBig/', 'X9/' or 'X7/'
--]]

local PHASES = { 'Prep time', 'Test flight', 'No fly' }
local SOUNDS = { 'prep', 'testfl', 'nofly' }
local KEYS = { 'prep', 'test', 'nofly' }


return function( viewDir )
	local DIR = F3K_SCRIPT_PATH .. 'TR_PATHS/'

	local files = {}
	local sel = -1		-- highlighted file (0 based)
	local preview		-- content of the highlighted file
	local path		-- the running path
	local idx = 0		-- current task (1 based)
	local phase = 0		-- 0=pick a file; 1=prep; 2=test flight; 3=no fly; 4=task; 5=path done
	local timer		-- phase countdown (model timer 0, like the task prep time)
	local lastSecond = 0
	local inner		-- current task view
	local triggerWasOn = true	-- prelaunch switch must be released before it can start the path
	local running = true


	local function loadPath( file )
		local ok, p = pcall( dofile, DIR .. file )
		if ok and type( p ) == 'table' and type( p.tasks ) == 'table' and #p.tasks > 0 then
			return p
		end
		return nil
	end


	local function stop()
		F3KPath = nil
		if timer then
			timer.stop()
		end
		running = false
	end


	local function startPhase( ph )
		phase = ph
		if ph <= 3 then
			local secs = tonumber( path[ KEYS[ ph ] ] ) or 0
			if secs <= 0 then
				return startPhase( ph + 1 )
			end
			timer = createTimer( 0, secs, 0, false )
			timer.start()
			lastSecond = secs + 1
			playFile( F3KConfig.SOUND_PATH .. SOUNDS[ ph ] .. '.wav' )
			if ph == 1 and F3KConfig.TASK_DESCRIPTION then
				playFile( F3KConfig.SOUND_PATH .. 'task' .. string.lower( path.tasks[ idx ] ) .. '.wav' )
			end
		elseif ph == 4 then
			local id = path.tasks[ idx ]
			F3KPath = { name=path.name, run=path.run, index=idx, total=#path.tasks }
			inner = dofile( F3K_SCRIPT_PATH .. viewDir .. 'view_' .. id .. '.lua' )
			inner.init( (id == 'EE' and 15 or 10) * 60 )
			F3KConfig.resetLaunchDetection()
		else
			F3KPath = nil
			inner = nil
			playFile( F3KConfig.SOUND_PATH .. 'pathend.wav' )
		end
	end


	local function startTask( i )
		idx = i
		F3KPath = nil
		inner = nil
		startPhase( 1 )
	end


	local scanned = false	-- the folder is read once, when the file list opens
	local scanError	-- shown on the file list when the folder can't be read

	-- OpenTX has no dir(): probe the fixed names Level_1..5 (website levels) and Path_1..9 (own paths)
	local function probeFiles()
		local names = {}
		for i = 1, 5 do names[ #names + 1 ] = 'Level_' .. i .. '.lua' end
		for i = 1, 9 do names[ #names + 1 ] = 'Path_' .. i .. '.lua' end
		for i = 1, #names do
			local f = io.open( DIR .. names[ i ], 'r' )
			if f then
				io.close( f )
				files[ #files + 1 ] = names[ i ]
			end
		end
		scanError = #files == 0 and 'OpenTX: name files Level_1..5 or Path_1..9' or nil
	end

	-- dir() is EdgeTX only; the folder is passed without the trailing '/'
	local function scanFiles()
		if not dir then
			probeFiles()
			return
		end
		local ok, err = pcall( function()
			for f in dir( string.sub( DIR, 1, -2 ) ) do
				if string.lower( string.sub( f, -4 ) ) == '.lua' then
					files[ #files + 1 ] = f
				end
			end
		end )
		scanError = not ok and tostring( err ) or nil
	end


	local function pick()
		if not scanned then
			scanned = true
			scanFiles()
		end
		if #files == 0 then
			return
		end
		local s = math.floor( (getValue( Options.MenuScrollEncoder ) - 1024) * #files / -2049 )
		s = math.max( 0, math.min( #files - 1, s ) )
		if s ~= sel then
			sel = s
			preview = loadPath( files[ sel + 1 ] )
		end

		local triggerOn = getValue( Options.PrelaunchSwitch ) > 0
		if triggerOn and not triggerWasOn and preview then
			local d = getDateTime()
			path = preview
			path.name = path.name or string.sub( files[ sel + 1 ], 1, -5 )
			path.run = string.format( '%04d%02d%02d%02d%02d%02d', d.year, d.mon, d.day, d.hour, d.min, d.sec )
			startTask( 1 )
		end
		triggerWasOn = triggerOn
	end


	-- runInner=false when the task view's display() has already run the task background
	local function step( runInner )
		if not running then
			return false
		end
		local sw = getValue( Options.MenuSwitch )
		if sw < 0 or (sw == 0 and phase > 0) then
			-- up = back to the menu ; middle = abort the running path (back to the file list)
			if inner then
				inner.background()	-- the task sees the stop and logs it (STOP)
			end
			stop()
			return false
		end
		if sw == 0 then
			return true	-- file list shown, waiting for the run position
		end

		if phase == 0 then
			pick()
		elseif phase <= 3 then
			local val = timer.getVal()
			if val <= 0 then
				startPhase( phase + 1 )
			elseif val <= 10 and val < lastSecond then
				lastSecond = val
				playNumber( val, 0, 0 )
			end
		elseif phase == 4 then
			if runInner and not inner.background() then
				stop()
				return false
			end
			if F3KPath and F3KPath.done then
				if idx < #path.tasks then
					startTask( idx + 1 )
				else
					startPhase( 5 )
				end
			end
		end
		return running
	end


	local function background()
		return step( true )
	end


	local function init()
		F3KPath = nil
	end


	local function display( context )
		if phase == 4 and inner then
			local ok = inner.display( context )
			if not ok then
				stop()
				return false
			end
			return step( false )
		end

		local big = context ~= nil
		local fh = big and 22 or 9
		local x = big and 12 or 2
		local lcdDraw = OpenTX.lcd.drawText

		if phase == 0 then
			lcdDraw( x, 1, 'Training Path', INVERS )
			if #files == 0 then
				lcdDraw( x, 1 + fh, 'No .lua file in', SMLSIZE )
				lcdDraw( x, 1 + fh * 2, string.sub( DIR, 1, -2 ), SMLSIZE )
				if scanError then
					lcdDraw( x, 1 + fh * 3, string.sub( scanError, 1, big and 60 or 30 ), SMLSIZE )
				end
			else
				for i = 0, math.min( #files, big and 5 or 3 ) - 1 do
					local ii = math.max( 0, sel - 1 ) + i
					if ii < #files then
						lcdDraw( x, 1 + fh * (i + 1), files[ ii + 1 ], ii == sel and INVERS or 0 )
					end
				end
				if preview then
					local y = 1 + fh * (big and 7 or 5)
					local t = ''
					for i = 1, #preview.tasks do
						t = t .. preview.tasks[ i ] .. ' '
					end
					lcdDraw( x, y, (preview.prep or 0) .. '/' .. (preview.test or 0) .. '/' .. (preview.nofly or 0) .. 's ' .. t, SMLSIZE )
					lcdDraw( x, y + fh, 'Pull the trigger to start', SMLSIZE )
				end
			end
		elseif phase <= 3 then
			lcdDraw( x, 1, path.name .. ' ' .. idx .. '/' .. #path.tasks .. ' task ' .. path.tasks[ idx ], INVERS )
			lcdDraw( x, big and (1 + fh) or 11, PHASES[ phase ], MIDSIZE )
			-- 128x64 / 212x64: MIDSIZE label (y 11-23) + XXLSIZE timer (32 px, y 27-59); no font between DBLSIZE and XXLSIZE
			timer.draw( big and x or 22, big and (1 + fh * 2 + 10) or 27, XXLSIZE or DBLSIZE )
		else
			lcdDraw( x, 1, path.name, INVERS )
			lcdDraw( x, 1 + fh, 'Training path done !', big and MIDSIZE or 0 )
		end
		return background()
	end


	return { init=init, background=background, display=display }
end
