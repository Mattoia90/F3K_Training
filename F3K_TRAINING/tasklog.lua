--[[
	F3K Training

	tasklog.lua
	Appends one line per task to TasksLog/yyyyMMdd.csv (one file per day)
	Loaded only when a task ends, so it doesn't use memory during the task
	Format: Date;Time;Task;Window;Status;Heights;Flights (flight times in seconds, in the order flown)
		Heights: launch heights in meters separated by spaces (one per launch), empty without altitude sensor
--]]

return function( task, status )
	local flights = task.times.getFlights()
	if #flights == 0 then
		return
	end

	local d = getDateTime()
	local path = F3K_SCRIPT_PATH .. 'TasksLog/' .. string.format( '%04d%02d%02d.csv', d.year, d.mon, d.day )

	local f = io.open( path, 'r' )
	local header = not f
	if f then
		io.close( f )
	end

	f = io.open( path, 'a' )
	if not f then
		return	-- TasksLog folder missing: fail silently
	end
	if header then
		io.write( f, 'Date;Time;Task;Window;Status;Heights;Flights\n' )
	end
	-- NB: the 'table' library is not available on the radio, so no table.concat here
	local heights = task.times.getHeights()
	local h = ''
	for i = 1, #heights do
		h = h .. (i > 1 and ' ' or '') .. heights[ i ]
	end
	local line = string.format( '%04d-%02d-%02d;%02d:%02d:%02d;%s;%d;%s;%s',
		d.year, d.mon, d.day, d.hour, d.min, d.sec, task.name, task.WINDOW_TIME or 0, status, h )
	for i = 1, #flights do
		line = line .. ';' .. flights[ i ]
	end
	io.write( f, line, '\n' )
	io.close( f )
end
