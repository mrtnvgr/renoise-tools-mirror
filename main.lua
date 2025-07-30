--[[ FILE INFO |
------------------------------------------------------------------------------
   ____ _  _ ___ ____ _  _ ____ ___ _ ____   ____ ____ ____ ____ _ ____ __ _
   |--| |__|  |  [__] |\/| |--|  |  | |___   ==== |=== ==== ==== | [__] | \|
            ___ _ _  _ ____    ___ ____ ____ ____ _  _ ____ ____ 
             |  | |\/| |___     |  |__/ |__| |    |_/  |___ |__/ 
             |  | |  | |___     |  |  \ |  | |___ | \_ |___ |  \ 

	DLT <dave.tichy@gmail.com>
------------------------------------------------------------------------------

	Automatic time tracker for monitoring time spent on each song. Classifies
	time spent based on activity, for insight into which tasks take the most
	time.

	Will create a report file alongside each of your opened XRNS song files:

		- `*songname*.time-report.txt` - A text file containing a human-
		readable report of how much time was spent on the song.  Updates
		automatically whenever you save the song.

------------------------------------------------------------------------------

	v1.4:
	-----
		- Code cleanup
		- Change data location to less volatile location - thanks, @Beatslaughter

	v1.3: 2020-06-04
	----
		- Added tool settings
		- Ability to toggle auto-creation of time reports
		- Ability to have time tracker window open automatically when a song loads
		- Ability to toggle keeping timers running when Renoise loses focus

	v1.2: 2020-06-03
	----
		- NEW: Data files now tucked away in tool folder
		- Shorter report filename -- FOO.tracked_time.report.txt`-> FOO.time-report.txt
		- Conflict management / data file merging
		- Export button to save a time report to the folder of your choice
		- Fix for Windows paths

	v1.1: 2020-06-01
	----
		- Improved performance
		- Bug fixes

	v1.1: 2020-06-01
	----
		- Automatically works in the background, unobtrusively keeping time records
		- Classifies time spent based on activity.
		- Automatically carries over old time tracking data when "Save Song As..."
		- Stops counting automatically when Renoise loses focus
		- Correctly handles computer suspend / lid closed by restarting time on resume
		- Writes out textual report on song save

	KNOWN ISSUES:
	----------------
		- When renaming a song, you must rename the time tracking data file as well

	Someday / Maybe:
	----------------
		- Nothing else... yet.



---------------------------------------------------------------------------
Copyright © 2020 David Lopez Tichy, http://dlt.fm <dave.tichy@gmail.com>
---------------------------------------------------------------------------
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
---------------------------------------------------------------------------


---------------------------------------------------------------------------]]

PATH_SEPARATOR = '/'
if os.platform() == 'WINDOWS' then
	PATH_SEPARATOR = '\\'
end


--===================================================================

class 'Dlt_SessionTimeTracker'

--===================================================================

Dlt_SessionTimeTracker.contexts = {
	SAMPLE_RECORD = 'sample_record',
	PATTERN_EDITOR = 'pattern_editor',
	MIXER = 'mixer',
	PHRASE_EDITOR = 'phrase_editor',
	SAMPLE_KEYZONES = 'sample_keyzones',
	SAMPLE_EDITOR = 'sample_editor',
	SAMPLE_MODULATION = 'sample_modulation',
	SAMPLE_EFFECTS = 'sample_effects',
	PLUGIN_EDITOR = 'plugin_editor',
	MIDI_EDITOR = 'midi_editor',
	OTHER = 'other',
	BG_PLAYBACK = 'bg_playback',
}

Dlt_SessionTimeTracker.FILENAME_DATA = 'tracked_time' --.data'
Dlt_SessionTimeTracker.FILENAME_REPORT = 'time-report'

Dlt_SessionTimeTracker.SAVEMETHOD_NEXTTO = 'nextto'
Dlt_SessionTimeTracker.SAVEMETHOD_TOOLFOLDER = 'toolfolder'
Dlt_SessionTimeTracker.SAVEMETHOD_COMMENT = 'comment'

Dlt_SessionTimeTracker.COMMENT_TOKEN = 'TIME_DATA'
Dlt_SessionTimeTracker.COMMENT_ID_TOKEN = 'SessionTimeTrackerID'

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:__init ()

	self.WINDOW_STATE_FOCUSED = true

	self.song_data = nil

	-- Settings -----------------------------
	
	self.options = renoise.Document.create('TimeTrackerOptions') {
		automatic_reports = true,
		show_on_song_open = false,
		stop_tracking_on_lost_focus = true,
		gui_show_detail = true,
	}
	renoise.tool().preferences = self.options

	-- Callbacks ----------------------------
	
	self.track = function ()
		if not self.song_data then
			self:init_data()
		end
		local context = self:get_context()
		self.song_data:record_activity(context)
	end

	-- Hooks --------------------------------
	
	-- On song save, save the timers as well
	renoise.tool().app_saved_document_observable:add_notifier(function()
		self:save_data()
		if self.options.automatic_reports.value == true then 
			self:save_report() 
		end
	end)

	-- On song load, make sure we've loaded the right timers
	renoise.tool().app_new_document_observable:add_notifier(function()
		self:init_data()
	end)

	-- Start time tracking when Renoise becomes focused application
	renoise.tool().app_became_active_observable:add_notifier(function()
		self.WINDOW_STATE_FOCUSED = true
		self:start_tracking()
	end)

	-- Stop time tracking when Renoise loses focus
	renoise.tool().app_resigned_active_observable:add_notifier(function()
		self.WINDOW_STATE_FOCUSED = false
		if self.options.stop_tracking_on_lost_focus.value == true then
			self:stop_tracking()
		end
	end)

	-- Start ------------

	self:start_tracking()

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:start_tracking ()

	if not renoise.tool():has_timer(self.track) then
		renoise.tool():add_timer(self.track, 1000)
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:stop_tracking ()

	if renoise.tool():has_timer(self.track) then
		renoise.tool():remove_timer(self.track)
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:save_data ()
	
	local songdata_id = self:get_songdata_id()
	local filename = self:get_songdata_filename(songdata_id)
	self.song_data:update_total_time()
	self.song_data:save_as(filename)
	self:update_songdata_id_in_comment()

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_context ()

	if renoise.app().window.sample_record_dialog_is_visible then
		return Dlt_SessionTimeTracker.contexts.SAMPLE_RECORD
	end

	if self.WINDOW_STATE_FOCUSED == false and renoise.song().transport.playing then
		return Dlt_SessionTimeTracker.contexts.BG_PLAYBACK
	end

	local context = renoise.app().window.active_middle_frame

	if context == renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR then
		return Dlt_SessionTimeTracker.contexts.PATTERN_EDITOR
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_MIXER then
		return Dlt_SessionTimeTracker.contexts.MIXER
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR then
		return Dlt_SessionTimeTracker.contexts.PHRASE_EDITOR
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES then
		return Dlt_SessionTimeTracker.contexts.SAMPLE_KEYZONES
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR then
		return Dlt_SessionTimeTracker.contexts.SAMPLE_EDITOR
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION then
		return Dlt_SessionTimeTracker.contexts.SAMPLE_MODULATION
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS then
		return Dlt_SessionTimeTracker.contexts.SAMPLE_EFFECTS
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR then
		return Dlt_SessionTimeTracker.contexts.PLUGIN_EDITOR
	elseif context == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR then
		return Dlt_SessionTimeTracker.contexts.MIDI_EDITOR
	else
		return Dlt_SessionTimeTracker.contexts.OTHER
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:seconds_to_time (secs, use_long)

	use_long = use_long or false

	local MAX_DETAIL_LEVEL = 3

	local DAY = 'd'
	local HR = 'h'
	local MIN = 'm'
	local SEC = 's'
	local SEP = ' '

	if use_long then
		DAY = ' day'
		HR = ' hr'
		MIN = ' min'
		SEC = ' sec'
		SEP = ', '
	end

	secs = tonumber(string.format('%0.f', secs))
	local remainder
	local days_elapsed = math.floor(secs / 86400)
	remainder = (secs % 86400)
	local hours_elapsed = math.floor(remainder / 3600)
	remainder = (secs % 3600)
	local mins_elapsed = math.floor(remainder / 60)
	local secs_elapsed = (remainder % 60)

	local elapsed_time_table = {days=days_elapsed, hours=hours_elapsed, mins=mins_elapsed, secs=secs_elapsed}

	local elapsed = {}
	if days_elapsed > 0 and #elapsed < MAX_DETAIL_LEVEL then table.insert(elapsed, days_elapsed .. DAY) end
	if hours_elapsed > 0 and #elapsed < MAX_DETAIL_LEVEL then table.insert(elapsed, hours_elapsed .. HR) end
	if mins_elapsed > 0 and #elapsed < MAX_DETAIL_LEVEL then table.insert(elapsed, mins_elapsed .. MIN) end
	if secs_elapsed > 0 and #elapsed < MAX_DETAIL_LEVEL then table.insert(elapsed, secs_elapsed .. SEC) end

	if #elapsed == 0 then
		return '-'
	else
		return table.concat(elapsed, SEP), elapsed_time_table
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_song_file_meta ()

	local meta = {}
	for folder, filename, ext in string.gmatch(renoise.song().file_name, '(.*'..PATH_SEPARATOR..')(.*)(.xrns)') do
		meta.folder = folder
		meta.filename = filename
		meta.extension = ext
	end
	return meta

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_report_filename ( dest_folder )

	if not renoise.song().file_name or renoise.song().file_name == '' then
		return nil
	end

	local meta = self:get_song_file_meta()
	dest_folder = dest_folder or meta.folder
	
	-- KEEP ALONGSIDE SONG FILE
	return dest_folder .. meta.filename .. '.'..Dlt_SessionTimeTracker.FILENAME_REPORT ..'.txt'

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:save_report (filename)
	
	filename = filename or self:get_report_filename()
	
	local content = self:get_report_text()
	local report = io.open(filename, 'w')
	report:write(content)
	report:close()

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:export_report ()
	
	local path = renoise.app():prompt_for_path('Time Tracker: Pick Destination Folder for '..self:get_report_filename(''))
	
	if path and path ~= '' then	
		local filename = self:get_report_filename(path)
		self:save_report(filename)
		renoise.app():show_status('[Session Time Tracker] Report saved to '..filename)
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_report_text ( song_data )
	
	song_data = song_data or self.song_data

	local function time_display(context)
		return Dlt_SessionTimeTracker:seconds_to_time(song_data.timers[context].value)
	end

	local meta = self:get_song_file_meta()

	local TTC = Dlt_SessionTimeTracker.contexts
	local content = {
		renoise.song().name ..' (by '..renoise.song().artist..')',
		'[ '.. meta.filename .. '.xrns ]',
		'========================================',
		'Pattern Editor ......... '..time_display(TTC.PATTERN_EDITOR),
		'----------------------------------------',
		'Mixer .................. '..time_display(TTC.MIXER),
		'----------------------------------------',
		'Phrase Editor .......... '..time_display(TTC.PHRASE_EDITOR),
		'Sampler: Recording ..... '..time_display(TTC.SAMPLE_RECORD),
		'Sampler: Keyzones ...... '..time_display(TTC.SAMPLE_KEYZONES),
		'Sampler: Waveform ...... '..time_display(TTC.SAMPLE_EDITOR),
		'Sampler: Modulation .... '..time_display(TTC.SAMPLE_MODULATION),
		'Sampler: Effects ....... '..time_display(TTC.SAMPLE_EFFECTS),
		'----------------------------------------',
		'Plugin Editor .......... '..time_display(TTC.PLUGIN_EDITOR),
		'----------------------------------------',
		'MIDI Editor ............ '..time_display(TTC.MIDI_EDITOR),
		'----------------------------------------',
		'Other .................. '..time_display(TTC.OTHER),
		'Background Playback .... '..time_display(TTC.BG_PLAYBACK),
		'========================================',
		'     TOTAL EDITING TIME: '..Dlt_SessionTimeTracker:seconds_to_time( song_data.total_time.value ),
	}
	return table.concat(content, '\n')

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_songdata_id ()

	if not renoise.song().file_name or renoise.song().file_name == '' then
		return nil
	end
	-- Re-use vim's convention of replacing slashes with % in filenames (for swap, backups, etc)
	return renoise.song().file_name:gsub('[/\\ :]','%%')

end

---------------------------------------------------------------------
function Dlt_SessionTimeTracker:path_is_absolute (path)

	local user_os = os.platform()
	local chr = path:sub(1,1)
	if (user_os == 'MACINTOSH' or user_os == 'LINUX') and chr == PATH_SEPARATOR then
		return true
	elseif user_os == 'WINDOWS' then
		if chr ~= '/' and path:match('.*:') then
			return true
		end
	end
	return false
end

function Dlt_SessionTimeTracker:create_folder_if_not_exist (path)

	local user_os = os.platform()

	local function mkdir_p(path)
		-- path = self:normalize_path(path)
		local dir
		if path:sub(1, 1) == '/' then
			dir = '/'
		else
			dir = ''
		end
		for part in path:gmatch('[^'..PATH_SEPARATOR..']+') do
			dir = dir .. part

			-- print('io.exists('..dir..')')
			if (part ~= '' and not self:path_is_absolute(part) and not io.exists(dir)) then
				local ok, err = os.mkdir(dir)
				if (not ok) then
					return nil, err
				end
			end
			dir = dir .. PATH_SEPARATOR
		end
		return true
	end

	if not io.exists(path) then
		local status, errmsg = mkdir_p(path)
		if status ~= true then
			-- self:fail('Create folder: '..errmsg)
			print('ERROR: Cannot create data folder: '..errmsg)
		end
	end

end


function Dlt_SessionTimeTracker:get_songdata_filename ( songdata_id )

	if not songdata_id then
		return nil
	end

	local user_os = os.platform()
	local save_path = ''

	if user_os == 'WINDOWS' then
		-- Windows
		-- AppData\Roaming\renoise-dlt\session-time-tracker\
		local home = os.getenv('APPDATA')
		save_path = home..PATH_SEPARATOR..'renoise-dlt'..PATH_SEPARATOR..'session-time-tracker'..PATH_SEPARATOR

	elseif user_os == 'MACINTOSH' then
		-- Mac
		-- ~/.config/renoise-dlt/session-time-tracker/
		local home = os.getenv('HOME')
		save_path = home..'/.config/renoise-dlt/session-time-tracker/'
	
	else
		-- Linux
		-- ~/.config/renoise-dlt/session-time-tracker/
		local home = os.getenv('HOME')
		save_path = home..'/.config/renoise-dlt/session-time-tracker/'
	end

	self:create_folder_if_not_exist(save_path)

	return save_path .. songdata_id .. '.xml'
	-- return 'tracking_data' .. PATH_SEPARATOR .. songdata_id .. '.xml'

end

---------------------------------------------------------------------
-- Update song data ID in comment if necessary

function Dlt_SessionTimeTracker:update_songdata_id_in_comment()

	local comment_id = self:get_songdata_id_from_comment()
	local songdata_id = self:get_songdata_id()
	
	if comment_id ~= songdata_id then
		self:save_songdata_id_to_comment()
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:save_songdata_id_to_comment ( songdata_id )

	songdata_id = songdata_id or self:get_songdata_id()
	local comment_data_string = Dlt_SessionTimeTracker.COMMENT_ID_TOKEN..':'..songdata_id

	local comms = {}	
	local had_existing_comment_id = false

	for i=1, #renoise.song().comments do
		if not renoise.song().comments[i]:match(Dlt_SessionTimeTracker.COMMENT_ID_TOKEN..':([^ ]+)') then
			table.insert(comms, renoise.song().comments[i])
		else
			-- If comment already had time data, replace it in place
			had_existing_comment_id = true
			table.insert(comms, comment_data_string)
		end
	end

	-- No time data found, append to end of comments
	if not had_existing_comment_id then
		table.insert(comms, comment_data_string)
	end

	-- replace comments
	renoise.song().comments = comms

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker:get_songdata_id_from_comment ()

	local match = nil
	
	for i=1, #renoise.song().comments do
		match = renoise.song().comments[i]:match(Dlt_SessionTimeTracker.COMMENT_ID_TOKEN..':([^ ]+)')
		if match then 
			return match
		end
	end

	return nil

end

---------------------------------------------------------------------
--== almost bulletproof song data retrieval ==--

function Dlt_SessionTimeTracker:init_data ()

	local song_data = Dlt_SessionTimeTracker_SongData()
	
	local songdata_id = self:get_songdata_id()
	local data_filename = self:get_songdata_filename(songdata_id)
	
	-- check comment for filename ID
	local saved_songdata_id = self:get_songdata_id_from_comment()

	--[  CONFLICT  ]-----------------------------------
	if saved_songdata_id and saved_songdata_id ~= songdata_id then
	
		local song_data_A = Dlt_SessionTimeTracker_SongData()
		local data_filename_A = self:get_songdata_filename(saved_songdata_id)
		local ok,err = song_data_A:load_from(data_filename_A)

		-- if data existed for commented ID, compare with new
		if ok then
			song_data:load_from(data_filename)

			-- DATA FOUND FOR CURRENT FILENAME
			if ok then
				-- Prompt user to 1.) Use A data, 2.) Use B data, or 3.) Add up time?
				local resolved = Dlt_SessionTimeTracker_Gui:resolve_conflict (song_data_A, song_data)
				if resolved then
					song_data = resolved
				end
				self.song_data = song_data
				self.song_data:update_total_time()
				self:update_songdata_id_in_comment()
				do return end
			end
		end
		-- otherwise, no previous data existed that we know of
	end

	--[  PRE-v1.2 DATA FILE MIGRATION ]----------------
	-- If existing time data was stored alongside (from previous versions)
	if songdata_id and not saved_songdata_id then
		local meta = self:get_song_file_meta()
		if meta then
			local inplace_datafile = meta.folder .. meta.filename .. '.'..Dlt_SessionTimeTracker.FILENAME_DATA ..'.xml'
			local song_data_A = Dlt_SessionTimeTracker_SongData()
			local ok,err = song_data_A:load_from(inplace_datafile)
			if ok then
				song_data:load_from(data_filename)
				local resolved = Dlt_SessionTimeTracker_Gui:resolve_conflict (song_data_A, song_data)
				if resolved then
					song_data = resolved
				end
				self.song_data = song_data
				self.song_data:update_total_time()
				self:update_songdata_id_in_comment()
				do return end
			end
		end
	end

	--[  ALL ELSE  ]-----------------------------------
	-- load data if it exists (should cover all other cases)
	if songdata_id then
		local ok,err = song_data:load_from(data_filename)
		self:update_songdata_id_in_comment()
	end
	
	self.song_data = song_data

end

---------------------------------------------------------------------



--===================================================================

class 'Dlt_SessionTimeTracker_SongData' (renoise.Document.DocumentNode)

--===================================================================

function Dlt_SessionTimeTracker_SongData:__init ()

	renoise.Document.DocumentNode.__init(self)

	self.filename = nil

	local _timers = {}
	for k,v in pairs(Dlt_SessionTimeTracker.contexts) do
		_timers[v] = 0
	end

	self:add_properties {
		started_tracking = 0, -- date tracking started for song file
		total_time = 0,
		-- timers = Dlt_SessionTimeTracker_SongData._timers
		timers = _timers
	}

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_SongData:update_total_time ()

	local t = 0
	for k,v in pairs(Dlt_SessionTimeTracker.contexts) do
		t = t + self.timers[v].value
	end
	self.total_time.value = t

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_SongData:record_activity (context)

	if self.started_tracking.value == 0 then
		self.started_tracking.value = os.time()
	end
	self.timers[context].value = self.timers[context].value + 1
	self.total_time.value = self.total_time.value + 1

end

---------------------------------------------------------------------




--===================================================================

class 'Dlt_SessionTimeTracker_Gui'

--===================================================================

function Dlt_SessionTimeTracker_Gui:__init ( Dlt_SessionTimeTracker_instance )

	-- self.vb = renoise.ViewBuilder()
	self.dialogs = {
		summary = nil,
		export = nil,
	}
	self.tracker = Dlt_SessionTimeTracker_instance

	self.callbacks = {
		update_gui = function() self:update_gui() end
	}

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:update_gui ()

	-- Save CPU: Don't update anything if GUI isn't visible
	if self.dialogs.summary and not self.dialogs.summary.visible then
		self:stop_updating_gui()
		do return end
	end

	for k,v in pairs(Dlt_SessionTimeTracker.contexts) do
		self.vb.views['timerval_'..v].text = Dlt_SessionTimeTracker:seconds_to_time(self:timer_value(v))
	end
	self.vb.views.total_time.text = Dlt_SessionTimeTracker:seconds_to_time( self.tracker.song_data.total_time.value )

	local function is_export_possible()
		local songdata_id = self.tracker:get_songdata_id()
		return (songdata_id ~= nil)
	end

	self.vb.views.export_button.active = is_export_possible()

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:timer_value (context)

	return self.tracker.song_data.timers[context].value

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:open_summary ()

	if self.dialogs.summary and self.dialogs.summary.visible then
		self.dialogs.summary:show()
		return
	end

	--local vb = self.vb
	self.vb = renoise.ViewBuilder()
	local vb = self.vb
	local SPACE = 8

	local WIDGET_WIDE = 220
	local WIDGET_NARROW = 125
	
	local function time_display(context)
		return vb:text { 
			id = 'timerval_'..context,
			style = 'strong',
			align='right',
			width=90,
			text = Dlt_SessionTimeTracker:seconds_to_time(self:timer_value(context)),
		}
	end

	local widget_width = function ()
		if self.tracker.options.gui_show_detail.value == true then
			return WIDGET_WIDE
		else
			return WIDGET_NARROW
		end
	end

	local button_mini_toggle = function ()

		local button_state = function()
			if self.tracker.options.gui_show_detail.value == true then
				return 'img/button-gui-minimize.bmp'
			else
				return 'img/button-gui-maximize.bmp'
			end
		end
		-- button_states
		local toggle = function()
			self.tracker.options.gui_show_detail.value = (self.tracker.options.gui_show_detail.value == false)
			vb.views.tracking_detail.visible = self.tracker.options.gui_show_detail.value
			vb.views.button_mini_toggle.bitmap = button_state()
			vb.views.button_mini_toggle.width = widget_width()
			vb.views.gui_total_time.width = widget_width() + renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN*2
			vb.views.gui_container.width = widget_width()
		end
		
		return vb:horizontal_aligner {
			mode = 'center',
			vb:bitmap {
				id = 'button_mini_toggle',
				height = 12,
				mode = 'button_color',
				width = widget_width(),
				bitmap = button_state(),
				notifier = toggle
			},
		}
	end

	local content = vb:column{
		id = 'gui_container',
		width = widget_width(),
		spacing=0,
		vb:column {
			id = 'gui_total_time',
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
			width = widget_width() + renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN*2,
			vb:text {
				text = 'Total Editing Time: ',
				width = '100%',
				align = 'center',
			},
			vb:text {
				id = 'total_time',
				width = '100%',
				align = 'center',
				style = 'strong',
				font = 'bold',
				text = Dlt_SessionTimeTracker:seconds_to_time( self.tracker.song_data.total_time.value ),
			},
		},
		button_mini_toggle(),
		vb:space { height=2},
		vb:column {
			-- margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
			id = 'tracking_detail',
			visible = self.tracker.options.gui_show_detail.value, 
			vb:row {
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
				uniform = true,
				style = 'group',
				-- style = 'plain',
				vb:column {
					time_display(Dlt_SessionTimeTracker.contexts.PATTERN_EDITOR),
					vb:space { height=SPACE, width=90},
					time_display(Dlt_SessionTimeTracker.contexts.MIXER),
					vb:space { height=SPACE},
					time_display(Dlt_SessionTimeTracker.contexts.PHRASE_EDITOR),
					time_display(Dlt_SessionTimeTracker.contexts.SAMPLE_RECORD),
					time_display(Dlt_SessionTimeTracker.contexts.SAMPLE_KEYZONES),
					time_display(Dlt_SessionTimeTracker.contexts.SAMPLE_EDITOR),
					time_display(Dlt_SessionTimeTracker.contexts.SAMPLE_MODULATION),
					time_display(Dlt_SessionTimeTracker.contexts.SAMPLE_EFFECTS),
					vb:space { height=SPACE},
					time_display(Dlt_SessionTimeTracker.contexts.PLUGIN_EDITOR),
					vb:space { height=SPACE},
					time_display(Dlt_SessionTimeTracker.contexts.MIDI_EDITOR),
					vb:space { height=SPACE},
					time_display(Dlt_SessionTimeTracker.contexts.BG_PLAYBACK),
					time_display(Dlt_SessionTimeTracker.contexts.OTHER),
				},
				vb:space { width=5 },
				vb:column {
					vb:text { text='Pattern Editor'},
					vb:space { height=SPACE, width=120},
					vb:text { text='Mixer'},
					vb:space { height=SPACE},
					vb:text { text='Phrase Editor'},
					vb:text { text='Sampler: Recording'},
					vb:text { text='Sampler: Keyzones'},
					vb:text { text='Sampler: Waveform'},
					vb:text { text='Sampler: Modulation'},
					vb:text { text='Sampler: Effects'},
					vb:space { height=SPACE},
					vb:text { text='Plugin Editor'},
					vb:space { height=SPACE},
					vb:text { text='MIDI Editor'},
					vb:space { height=SPACE},
					vb:text { text='Background Playback'},
					vb:text { text='Other'},
				},

			},
			vb:horizontal_aligner {
				mode = 'distribute',
				margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
				vb:button {
					text = 'Settings',
					notifier = function() self:open_settings() end
				},
				vb:button {
					id = 'export_button',
					text = 'Export Report',
					notifier = function() self.tracker:export_report() end,
					active = false,
				},
			},
		},
	}

	self.dialogs.summary = renoise.app():show_custom_dialog('Session Time', content)
	self:start_updating_gui()

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:start_updating_gui ()

	if not renoise.tool():has_timer(self.callbacks.update_gui) then
		renoise.tool():add_timer(self.callbacks.update_gui, 1000)
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:stop_updating_gui ()

	if renoise.tool():has_timer(self.callbacks.update_gui) then
		renoise.tool():remove_timer(self.callbacks.update_gui)
	end

end

---------------------------------------------------------------------
-- @static
-- @return resolved song_data if OK pressed, otherwise nil

function Dlt_SessionTimeTracker_Gui:resolve_conflict (song_data_A, song_data_B)
	
	local T_WIDTH = 300
	local T_HEIGHT = 350

	local vb = renoise.ViewBuilder()
	local content_view = vb:column {
		margin = 5,
		spacing = 5,
		vb:row {
			vb:column {
				spacing = 5,
				style='group',
				vb:multiline_text{
					font = 'mono',
					width = T_WIDTH,
					height = T_HEIGHT,
					text = Dlt_SessionTimeTracker:get_report_text(song_data_A)
				},
			},
			vb:column {
				spacing = 5,
				style='group',
				vb:multiline_text{
					font = 'mono',
					width = T_WIDTH,
					height = T_HEIGHT,
					text = Dlt_SessionTimeTracker:get_report_text(song_data_B)
				}
			},
		},
		vb:horizontal_aligner {
			mode = 'center',
			vb:switch {
				width = T_WIDTH*2,
				height = 25,
				id = 'conflict_choice',
				items = {'Use A', 'Merge: Add values from Both', 'Use B'},
				value = 2,
			},
		},
	}

	local pressed = renoise.app():show_custom_prompt('Session Time Tracker: Resolve Conflict', content_view, {'OK'})

	if pressed == 'OK' then
		local action = vb.views.conflict_choice.value
		if action == 1 then
			-- Use A
			return song_data_A
		elseif action == 3 then
			-- Use B
			return song_data_B
		else
			-- Merge
			for k,v in pairs(Dlt_SessionTimeTracker.contexts) do
				song_data_B.timers[v].value = song_data_B.timers[v].value + song_data_A.timers[v].value
			end
			return song_data_B
		end

	else
		return nil
	end

end

---------------------------------------------------------------------

function Dlt_SessionTimeTracker_Gui:open_settings ()
	
	local vb = renoise.ViewBuilder()
	local SPACE = 5

	local content_view = vb:column {
		margin = SPACE,
		vb:row {
			vb:checkbox {
				id = 'checkbox_automatic_reports',
				notifier = function() self.tracker.options.automatic_reports.value = vb.views.checkbox_automatic_reports.value end,
				value = self.tracker.options.automatic_reports.value,
			},
			vb:text {
				text = 'Automatically save time report on song save'
			}
		},
		vb:row {
			vb:checkbox {
				id = 'checkbox_show_on_song_open',
				notifier = function() self.tracker.options.show_on_song_open.value = vb.views.checkbox_show_on_song_open.value end,
				value = self.tracker.options.show_on_song_open.value,
			},
			vb:text {
				text = 'Show time tracking window whenever a song is opened'
			}
		},
		vb:row {
			vb:checkbox {
				id = 'checkbox_stop_tracking_on_lost_focus',
				notifier = function() self.tracker.options.stop_tracking_on_lost_focus.value = vb.views.checkbox_stop_tracking_on_lost_focus.value end,
				value = self.tracker.options.stop_tracking_on_lost_focus.value,
			},
			vb:text {
				text = 'Stop tracking when Renoise window loses focus'
			}
		}
	}

	local pressed = renoise.app():show_custom_prompt('Session Time Tracker: Settings', content_view, {'OK'})

end

---------------------------------------------------------------------






--===================================================================
--    I N I T I A L I Z E   T O O L 
--===================================================================

-- Start the time tracker automatically if installed
local Dlt_STT = Dlt_SessionTimeTracker()
local TimeTrackerGui

local open_time_tracker = function ()
	if not TimeTrackerGui then 
		TimeTrackerGui = Dlt_SessionTimeTracker_Gui( Dlt_STT ) 
	end
	TimeTrackerGui:open_summary()
end


renoise.tool().app_new_document_observable:add_notifier(function()
	if Dlt_STT.options.show_on_song_open.value == true then
		open_time_tracker()
	end
end)


renoise.tool():add_keybinding {
	name = "Global:Tools:Session Time Tracker (dltfm)",
	invoke = open_time_tracker
}

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:dltfm:Session Time Tracker",
	invoke = open_time_tracker
}

