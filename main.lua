--[[ FILE INFO |
------------------------------------------------------------------------------
		___ _  _ ____
		 |  |__| |___
		 |  |  | |___

	▓█████▄ ▓█████  ██▓     ██▓ ██▒   █▓▓█████  ██▀███  ▓█████  ██▀███
	▒██▀ ██▌▓█   ▀ ▓██▒    ▓██▒▓██░   █▒▓█   ▀ ▓██ ▒ ██▒▓█   ▀ ▓██ ▒ ██▒
	░██   █▌▒███   ▒██░    ▒██▒ ▓██  █▒░▒███   ▓██ ░▄█ ▒▒███   ▓██ ░▄█ ▒
	░▓█▄   ▌▒▓█  ▄ ▒██░    ░██░  ▒██ █░░▒▓█  ▄ ▒██▀▀█▄  ▒▓█  ▄ ▒██▀▀█▄
	░▒████▓ ░▒████▒░██████▒░██░   ▒▀█░  ░▒████▒░██▓ ▒██▒░▒████▒░██▓ ▒██▒
	 ▒▒▓  ▒ ░░ ▒░ ░░ ▒░▓  ░░▓     ░ ▐░  ░░ ▒░ ░░ ▒▓ ░▒▓░░░ ▒░ ░░ ▒▓ ░▒▓░
	 ░ ▒  ▒  ░ ░  ░░ ░ ▒  ░ ▒ ░   ░ ░░   ░ ░  ░  ░▒ ░ ▒░ ░ ░  ░  ░▒ ░ ▒░
	 ░ ░  ░    ░     ░ ░    ▒ ░     ░░     ░     ░░   ░    ░     ░░   ░
		 ░       ░  ░    ░  ░ ░        ░     ░  ░   ░        ░  ░   ░
	 ░                              ░
		DLT <dave.tichy@gmail.com>
------------------------------------------------------------------------------

	Batch rendering and archival tool for collecting mixdowns, stems, Renoise
	instruments, and samples, with customizable destination folders, export
	formats, and flexible naming for stems and mixdowns.

	Naming defaults based on: https://www.grammy.com/technical-guidelines

------------------------------------------------------------------------------
																															--f: cybermedium
	v1.0: 2020-06-04
	----
		- Fix for config path

	v0.9:
	----
		- Fix for windows paths

	v0.8:
	----
		- Render mixdown with custom settings
		- Render stems with basic naming convention
		- Specify custom folder for stem output ("Stems/")
		- Specify custom folder for exported instruments ("XRNI/")
		- Specify custom folder for exported raw samples ("Samples/")
		- Export sliced samples separately
		- Setting: Flac or Wav for exported samples
		- Add support for custom naming scheme
		- Add preset management
		- Make sure selected base paths exist, create if not
		- Automatically create a containing folder based on song name
		- Fixed: If song is unsaved (new song), automagic file naming breaks
		- Decouple factory presets from user presets for saving/loading separate 
		  XML files, to avoid missing out when updates to factory settings are 
			pushed


	KNOWN BUGS:
	----------------
		- Untested on Windows
		- Untested on Linux

	Someday / Maybe:
	----------------
	- TODO [High] Avoid overwriting files
	- TODO [Medium] Batch XRNS Renderer: Build list of Renoise song files to batch render
	- TODO [Medium] Add estimated time remaining
	- TODO [Medium] Add exported text file with meta information (instrument sample names, loop points, slice marker locations, FX settings, etc)
	- TODO [Low] Export song also: renoise.app():save_song_as(filename)
	- TODO [Low] Recall presets used on a per-song basis (based on song().file_name?)




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


require 'coroutine_runner'
TASKER = Dlt_CoroutineRunner()
-- TASKER.DEBUG = true

-----------------------------------------------------------------------------


class 'DlvrrNameTailor'
function DlvrrNameTailor:__init()

end

function DlvrrNameTailor:title_case (str)
	return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end

function DlvrrNameTailor:initials (str)
	str = self:title_case(str)
	local initials = {}
	-- get words
	for token in string.gmatch(str, "[^%s-]+") do
		table.insert(initials, token:sub(1,1))
	end

	if #initials == 1 then
		-- if all we have is 1 word, use the whole name
		return str
	else
		return table.concat(initials,'')
	end
end

function DlvrrNameTailor:sample_rate_abbrev (sample_rate)
	if sample_rate % 1000 == 0 then
		return string.format('%2d', sample_rate/1000)..'k'
	else
		return string.format('%.1f', sample_rate/1000)..'k'
	end
end

function DlvrrNameTailor:replace_tokens (text, tokens_table)
	for k, v in pairs(tokens_table) do
		text = string.gsub(text, '{'..k..'}', v)
	end
	return text
end

function DlvrrNameTailor:remove_whitespace (text)
	return string.gsub(text, '[%s-]', '')
end





--===========================================================================
--     ___  ____ ____ ____ ____ ___   _  _ ____ _  _ ___
--     |--' |--< |=== ==== |===  |    |\/| |__, |\/|  |
--
--     P R E S E T   M A N A G E M E N T
-----------------------------------------------------------------------------

-- Preset management
require 'dlt_presets'


class 'DlvrrPreset' (Dlt_Preset)

function DlvrrPreset:__init(opts)
	local current_preset_version = 1
	Dlt_Preset.__init(self, opts, current_preset_version)
end

DlvrrPreset.default_properties = {
	include_mixdown = true,
	include_stems = true,
	include_xrni = true,
	include_samples = true,
	-----------------------
	-- When rendering stems, which to include
	stems_include_tracks = true,
	stems_include_groups = true,
	-----------------------
	use_grammy_naming = true,
	naming_format_mixdown = '{ARTIST} - {SONGNAME}',
	naming_format_stems = '{TRACKNUM}. {TRACKNAME}',
	-----------------------
	save_path_mixdown = '{SONGABSPATH}'..PATH_SEPARATOR..'{SONGNAME_NS}'..PATH_SEPARATOR, -- default this to the same path as song
	save_path_stems = 'Stems'..PATH_SEPARATOR,   -- if no leading '/', relative to mixdown
	save_path_xrni = 'XRNI Instruments'..PATH_SEPARATOR,    -- if no leading '/', relative to mixdown
	save_path_samples = 'Samples'..PATH_SEPARATOR, -- if no leading '/', relative to mixdown
	-----------------------
	export_format_samples = 'wav',
	-----------------------
	render_mixdown_bit_depth = 24,
	render_mixdown_sample_rate = 48000,
	render_mixdown_interpolation = 'precise',
	render_mixdown_priority = 'high',

	render_stems_bit_depth = 24,
	render_stems_sample_rate = 48000,
	render_stems_interpolation = 'precise',
	render_stems_priority = 'high',
}

-------------------------------------------
--     F A C T O R Y   P R E S E T S     --
-------------------------------------------
local FACTORY_PRESETS = {
	{
		_name = 'Default',
		include_stems = false,
		include_xrni = false,
		include_samples = false,
	},
	{
		_name = 'Dated Mixdown, 24/48k',
		include_mixdown = true,
		include_stems = false,
		include_xrni = false,
		include_samples = false,
		use_grammy_naming = false,
		-- naming_format_mixdown = '{ARTIST} - {SONGNAME} ({DATE} {TIME2})',
		-- naming_format_mixdown = '{ARTIST_INIT}_{SONGNAME_NS}_{TRACKNAME}_{SAMPLERATE}{BITDEPTH}_{DATE}_{TIME2}',
		naming_format_mixdown = '{ARTIST_INIT}_{SONGNAME_NS}_{TRACKNAME_NS}_{SAMPLERATE}{BITDEPTH} [{DATE} {TIME2}]',
		naming_format_stems = '{ARTIST_INIT}_{SONGNAME_NS}_{TRACKNUM}_{TRACKNAME_NS}_{SAMPLERATE}{BITDEPTH} [{DATE} {TIME2}]',
	},
	{
		_name = 'Mixdown & All Stems, 24/48k',
		include_xrni = false,
		include_samples = false,
	},
	{
		_name = 'Mixdown & Submixes/Groups, 24/48k',
		include_xrni = false,
		include_samples = false,
		stems_include_tracks = false,
		stems_include_groups = true,
	},
	{
		_name = 'Archival: Mixdown & All Stems, 32/192k',
		include_mixdown = true,
		include_stems = true,
		include_xrni = false,
		include_samples = false,
		render_mixdown_bit_depth = 32,
		render_mixdown_sample_rate = 192000,
		render_mixdown_interpolation = 'precise',
		render_mixdown_priority = 'high',
		render_stems_bit_depth = 32,
		render_stems_sample_rate = 192000,
		render_stems_interpolation = 'precise',
		render_stems_priority = 'high',
	},
	{
		_name = 'Archival: Complete Backup, 32/192k',
		include_mixdown = true,
		include_stems = true,
		include_xrni = true,
		include_samples = true,
		render_mixdown_bit_depth = 32,
		render_mixdown_sample_rate = 192000,
		render_mixdown_interpolation = 'precise',
		render_mixdown_priority = 'high',
		render_stems_bit_depth = 32,
		render_stems_sample_rate = 192000,
		render_stems_interpolation = 'precise',
		render_stems_priority = 'high',
	},
}



class 'DlvrrSongPreset' (Dlt_ContextualPreset)
function DlvrrSongPreset:__init()
	Dlt_ContextualPreset.__init(self)
	self.context = 'song'
end




--===========================================================================
--     _  _ ____ _ __ _
--     |\/| |--| | | \|
--
--     M A I N   D L V R R   C L A S S
-----------------------------------------------------------------------------

class 'Dlvrr'

Dlvrr.CONTEXT_MIXDOWN = 'Mixdown'
Dlvrr.CONTEXT_STEM = 'Stems'
Dlvrr.CONTEXT_XRNI = 'Instruments'
Dlvrr.CONTEXT_SAMPLE = 'Samples'

-----------------------------------------------------------------------------

function Dlvrr:__init( options )

	options = options or {}

	self.prefs = renoise.Document.create("DelivererOptions") {

		last_preset_id = 1,
		-- per_song_settings = Dlt_ContextualPresetList(DlvrrSongPreset),
		gui = {
			last_tab = 1,
		}
	}
	renoise.tool().preferences = self.prefs

	for k,v in pairs(options) do
		self.prefs[k].value = v
	end

	-- Sanity Checks
	if self.prefs.last_preset_id.value == 0 then
		self.prefs.last_preset_id.value = 1
	end

	self.options = DlvrrPreset()
	self.presets = Dlt_PresetList(DlvrrPreset, self.options, FACTORY_PRESETS)
	self.presets.filename = self:get_config_path() .. 'presets.xml'
	self.presets:load_all()
	
	-- print('LOADED '..#self.presets.presets..' PRESETS')

	self.presets:load_preset(self.prefs.last_preset_id.value)

	self.TAILOR = DlvrrNameTailor()

	-- General OK signal
	self.ok_status = renoise.Document.ObservableBoolean(true)
	self.status_message = renoise.Document.ObservableString('')

	self.preset_changed = renoise.Document.ObservableBang()

	self.indicators = {
		batch_progress = renoise.Document.ObservableNumber(0),
		batch_steps = renoise.Document.ObservableNumber(0),
		batch_current_step = renoise.Document.ObservableNumber(0),

		progress = renoise.Document.ObservableNumber(0),
		currently_rendering = renoise.Document.ObservableString(''),
		render_context = renoise.Document.ObservableString('mixdown'),

		currently_saving = renoise.Document.ObservableString(''),
		saving_context = renoise.Document.ObservableString(''),
		saving_step = renoise.Document.ObservableNumber(0),
		saving_total = renoise.Document.ObservableNumber(0),
	}

	self.state_cache = {

	}

	self.callbacks = {
		render_mixdown = function() return self:render_mixdown() end,
		render_all_stems = function() return self:render_all_stems() end,
		update_progress = function() return self:update_progress() end,
	}

	self.presets.selected_preset_index:add_notifier(function()
		self.prefs.last_preset_id.value = self.presets.selected_preset_index.value
	end)

end

-----------------------------------------------------------------------------

function Dlvrr:set_status (status)
	self.status_message.value = status
	renoise.app():show_status('[The Deliverer] '..status)
end

-----------------------------------------------------------------------------

function Dlvrr:all_ok()
	return self.ok_status.value
end

-----------------------------------------------------------------------------

function Dlvrr:run()

end

-----------------------------------------------------------------------------

function Dlvrr:update_xrni_progress()

	if not self:all_ok() then do return end end
	self:set_status('Saving Renoise Instrument '..self.indicators.saving_step.value..'/'..self.indicators.saving_total.value..': ['..self.indicators.currently_saving.value..']')

end

-----------------------------------------------------------------------------

function Dlvrr:update_sample_progress()

	if not self:all_ok() then do return end end
	self:set_status('Saving samples for [' .. self.indicators.currently_saving.value..']: '..self.indicators.saving_step.value..'/'..self.indicators.saving_total.value)

end

-----------------------------------------------------------------------------

function Dlvrr:update_render_progress()

	if not self:all_ok() then do return end end
	self.indicators.progress.value = renoise.song().rendering_progress
	local n = string.format("%.1f%%",self.indicators.progress.value*100)
	self:set_status('Rendering ['..self.indicators.currently_rendering.value..']: '..n)

end

-----------------------------------------------------------------------------

function Dlvrr:note_num_to_note_name (num)

	local notenames_array = { 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-' }
	local octave = math.floor(num/12)
	local note = notenames_array[(num%12)+1]
	return string.format('%s%s', note, octave)

end

-----------------------------------------------------------------------------
-- NB: This will return an empty table if the song hasn't been saved yet.

function Dlvrr:get_current_song_file_meta ()

	local filename = renoise.song().file_name
		-- Returns the Path, Filename, and Extension as 3 values
	local meta = {
		folder = nil,
		filename = nil,
		extension = nil,
	}

	-- for folder, file, ext in string.gmatch(filename, "^(.-)([^\\/]-)%.([^\\/%.]-)%.?$") do
	for folder, file, ext in string.gmatch(filename, "(.*"..PATH_SEPARATOR..")(.*)(.xrns)") do
		meta.folder = folder
		meta.filename = file
		meta.extension = ext
	end

	return meta

end

-----------------------------------------------------------------------------

function Dlvrr:get_path_to_folder_containing_current_song ()

	local m = self:get_current_song_file_meta()
	return m.folder
end

-----------------------------------------------------------------------------
-- Make sure any paths provided come back with trailing slash

function Dlvrr:normalize_path (path)

	local trailing_slashes = path:match("["..PATH_SEPARATOR.."]*$")
	if not trailing_slashes then
		path = path .. PATH_SEPARATOR
	end

	path = string.gsub(path, '//', '/')
	path = string.gsub(path, '\\\\', '\\')
	return path

  -- if trailing_slashes then
    -- path = path:sub(1, -trailing_slashes:len()-1)
  -- end
	-- path = string.gsub(path, '//', '/')
	-- path = string.gsub(path, '\\\\', '\\')
	-- return path .. PATH_SEPARATOR

end

-----------------------------------------------------------------------------
-- Return filename with bad characters replaced

function Dlvrr:sanitize_filename (filename, remove_spaces)

	remove_spaces = remove_spaces or nil

	local bad_characters = {
		'%/', -- backslash
		'\\', -- forward slash
		'%?', -- question mark
		'%%', -- percent
		'%*', -- asterisk
		'%:', -- colon
		'%;', -- semicolon
		'%|', -- pipe
		'%<', -- left angle bracket
		'%>', -- right angle bracket
		'%;', -- semi colon
		"%'", -- single quote
		'%"', -- double quote
		'%+', -- plus sign
		'%#', -- pound sign
		'%&', -- ampersand
		'%{', -- left bracket
		'%}', -- right bracket
		'%$', -- dollar sign
		'%!', -- exclamation mark
		'%@', -- at sign
		'%=', -- equal sign
		-- '%.', -- period?
	}
	for n=1, #bad_characters do
		filename = filename:gsub(bad_characters[n], '')
	end
	-- remove leading and trailing spaces
	filename = filename:match('^%s*(.-)%s*$')

	if remove_spaces then
		filename = filename:gsub('%.', '')
		filename = filename:gsub('[%s-]', '')
	end

	return filename

end

-----------------------------------------------------------------------------

function Dlvrr:is_absolute_path (path)

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

-----------------------------------------------------------------------------

function Dlvrr:get_config_path ()
		
	local user_os = os.platform()
	local config_path = ''

	if user_os == 'WINDOWS' then
		-- Windows
		-- AppData\Roaming\renoise-dlt\session-time-tracker\
		local home = os.getenv('APPDATA')
		config_path = home..PATH_SEPARATOR..'renoise-dlt'..PATH_SEPARATOR..'the-deliverer'..PATH_SEPARATOR

	elseif user_os == 'MACINTOSH' then
		-- Mac
		-- ~/.config/renoise-dlt/session-time-tracker/
		local home = os.getenv('HOME')
		config_path = home..'/.config/renoise-dlt/the-deliverer/'
	
	else
		-- Linux
		-- ~/.config/renoise-dlt/session-time-tracker/
		local home = os.getenv('HOME')
		config_path = home..'/.config/renoise-dlt/the-deliverer/'
	end

	self:create_folder(config_path)

	return config_path
end

-----------------------------------------------------------------------------

function Dlvrr:get_path_for (context)

	local base_path = self.options.save_path_mixdown.value
	local context_path = nil

	local song_path = self:get_path_to_folder_containing_current_song()
	if song_path == nil then
		self:fail('Deliverables cannot be exported on an unsaved song. Save the song to continue.')
		do return end
	end

	base_path = self:normalize_path( base_path )
	base_path = self.TAILOR:replace_tokens(base_path, {
			SONGABSPATH = song_path,
			SONGNAME = self:sanitize_filename(renoise.song().name),
			SONGNAME_NS = self:sanitize_filename(self.TAILOR:remove_whitespace(self.TAILOR:title_case(renoise.song().name))),
		})
	base_path = self:normalize_path( base_path )

	if context == Dlvrr.CONTEXT_MIXDOWN then
		return base_path
	end

	if context == Dlvrr.CONTEXT_STEM then
		context_path = self.options.save_path_stems.value
	elseif context == Dlvrr.CONTEXT_XRNI then
		context_path = self:normalize_path( self.options.save_path_xrni.value )
	elseif context == Dlvrr.CONTEXT_SAMPLE then
		context_path= self:normalize_path( self.options.save_path_samples.value )
	else
		return nil
	end

	if not self:is_absolute_path( context_path ) then
		context_path = base_path .. self:normalize_path( context_path )
	end
	context_path = self.TAILOR:replace_tokens(context_path, {
			SONGABSPATH = song_path,
			SONGNAME = self:sanitize_filename(renoise.song().name),
			SONGNAME_NS = self:sanitize_filename(self.TAILOR:remove_whitespace(self.TAILOR:title_case(renoise.song().name))),
		})
	return self:normalize_path( context_path )

end

-----------------------------------------------------------------------------
-- Emulates "mkdir -p" to create folder and any necessary parent folders

function Dlvrr:create_folder (path)

	local user_os = os.platform()

	local function mkdir_p(path)
		path = self:normalize_path(path)
		local dir
		if path:sub(1, 1) == '/' then
			dir = '/'
		else
			dir = ''
		end
		for part in path:gmatch('[^'..PATH_SEPARATOR..']+') do
			dir = dir .. part

			-- print('io.exists('..dir..')')
			if (part ~= '' and not self:is_absolute_path(part) and not io.exists(dir)) then
				local ok, err = os.mkdir(dir)
				if (not ok) then
					return nil, err
				end
			end
			dir = dir .. PATH_SEPARATOR
		end
		return true
	end

	--[[
	if PATH_SEPARATOR == '/' then
		path = path:sub(1, -2) -- strip trailing slash
	else 
		path = path:sub(1, -3) -- strip trailing slash
	end
	--]]
	if not io.exists(path) then
		local status, errmsg = mkdir_p(path)
		if status ~= true then
			self:fail('Create folder: '..errmsg)
		end
	end

end

-----------------------------------------------------------------------------
-- Returns a filename for the given data formatted according to the Grammy 
-- Producers & Engineers Wing naming recommendations:
--   * https://www.grammy.com/technical-guidelines

function Dlvrr:grammy_format (data)

	local name_elements = {}

	local song_name = renoise.song().name
	if song_name == 'Untitled' then
		local sm = self:get_current_song_file_meta()
		if #sm > 0 then
			song_name = sm.filename
		end
	end

	local function add_element (str)
		table.insert(name_elements, self:sanitize_filename(str, true))
	end

	--------

	if data.artist then
		add_element( self.TAILOR:initials(data.artist) )
	elseif renoise.song().artist ~= 'Somebody' then
		add_element( self.TAILOR:initials(renoise.song().artist) )
	end

	add_element( self.TAILOR:title_case(song_name) )

	if data.number then
		add_element(data.number)
	end

	if data.track then
		add_element( self.TAILOR:title_case(data.track) )
	end

	local samplerate_bitdepth = ''
	if data.sample_rate then
		samplerate_bitdepth = samplerate_bitdepth .. self.TAILOR:sample_rate_abbrev(data.sample_rate)
	end
	if data.bit_depth then
		samplerate_bitdepth = samplerate_bitdepth .. data.bit_depth
	end
	if samplerate_bitdepth ~= '' then
		add_element(samplerate_bitdepth)
	end

	return table.concat(name_elements, '_')

end

-----------------------------------------------------------------------------

function Dlvrr:get_common_naming_tokens ()

	local song_meta = self:get_current_song_file_meta()
	local filename = ''
	if #song_meta > 0 then
		filename = song_meta.filename
	end

	local tokens = {
		ARTIST = renoise.song().artist,
		ARTIST_INIT = self.TAILOR:initials(renoise.song().artist),
		ARTIST_NS = self.TAILOR:remove_whitespace(self.TAILOR:title_case(renoise.song().artist)),
		SONGNAME = renoise.song().name,
		SONGNAME_NS = self.TAILOR:remove_whitespace(self.TAILOR:title_case(renoise.song().name)),
		FILENAME = filename,
		BPM = renoise.song().transport.bpm,
		YYYY = os.date('%Y'),
		YEAR = os.date('%Y'),
		YR = os.date('%y'),
		MO = os.date('%m'),
		DD = os.date('%d'),
		DATE = os.date('%Y-%m-%d'),
		DATE2 = os.date('%Y.%m.%d'),
		DATE3 = os.date('%Y%m%d'),
		HH = os.date('%H'),
		HH12 = os.date('%I'),
		MM = os.date('%M'),
		TIME = os.date('%H:%M'),
		TIME2 = os.date('%H.%M'),
		TIME3 = os.date('%H%M'),
		TIME_PM = os.date('%I:%M%p'),
		TIME_PM2 = os.date('%I.%M%p'),
		TIME_PM3 = os.date('%I%M%p'),
	}
	return tokens

end

-----------------------------------------------------------------------------

function Dlvrr:name_mixdown ()

	local mixdown_name

	if self.options.use_grammy_naming.value == true then
		-- Grammy naming
		local data = {
			track = 'Master',
			sample_rate = self.options.render_mixdown_sample_rate.value,
			bit_depth = self.options.render_mixdown_bit_depth.value,
		}
		mixdown_name = self:grammy_format(data)

	else
		-- Custom naming
		local tokens = self:get_common_naming_tokens()
		tokens.TRACKNAME = 'Master'
		tokens.TRACKNAME_NS = 'Master'
		tokens.BITDEPTH = self.options.render_mixdown_bit_depth.value
		tokens.SAMPLERATE = self.TAILOR:sample_rate_abbrev(self.options.render_mixdown_sample_rate.value)

		local name_format = self.options.naming_format_mixdown.value
		mixdown_name = self.TAILOR:replace_tokens(name_format, tokens)

	end

	return self:sanitize_filename(mixdown_name)

end

-----------------------------------------------------------------------------

function Dlvrr:name_stem (track_idx, track)

	local meta = self:get_stem_meta(track_idx, track)
	local stem_name

	if self.options.use_grammy_naming.value == true then
		-- Grammy naming

		-- group/submix ?
		if meta.type == renoise.Track.TRACK_TYPE_GROUP then
			meta.name = meta.name..' Group'
		end

		local data = {
			track = meta.name,
			number = meta.number,
			sample_rate = meta.sample_rate,
			bit_depth = meta.bit_depth,
		}
		stem_name = self:grammy_format(data)

	else

		local name_format = self.options.naming_format_stems.value

		local tokens = self:get_common_naming_tokens()
		tokens.TRACKNAME = meta.name
		tokens.TRACKNAME_NS = self.TAILOR:remove_whitespace(self.TAILOR:title_case(meta.name))
		tokens.TRACKNUM = meta.number
		tokens.BITDEPTH = meta.bit_depth
		tokens.SAMPLERATE = self.TAILOR:sample_rate_abbrev(meta.sample_rate)

		tokens.MUTESTATE = 'ACTIVE'
		if track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
			tokens.MUTESTATE = 'MUTED'
			if track.mute_state == renoise.Track.MUTE_STATE_OFF then
				tokens.MUTESTATE = 'OFF'
			end
		end

		stem_name = self.TAILOR:replace_tokens(name_format, tokens)

	end

	return self:sanitize_filename(stem_name)

end

-----------------------------------------------------------------------------

function Dlvrr:filename_xrni (idx, name)

	name = name or ''
	if name == '' then name = '(Unnamed)' end

	local precision = string.len(#renoise.song().instruments)
	local numeric_index = string.format('%0'..precision..'d', idx)
	local hex_index =  string.format('%02X', idx-1)
	local name = numeric_index..'. ['..hex_index..'] '..name

	name = self:sanitize_filename(name)
	return name

end

-----------------------------------------------------------------------------

function Dlvrr:filename_sample (idx, instrument, sample)

	-- name = name or ''
	local precision = string.len(#instrument.samples)
	local numeric_index = string.format('%0'..precision..'d', idx)
	local map = sample.sample_mapping
	local range = self:note_num_to_note_name(map.note_range[1])
	local on_off_layer = 'ON'
	if map.layer == renoise.Instrument.LAYER_NOTE_OFF then
		on_off_layer = 'OFF'
	end

	local name = sample.name
	if name == '' then name = '(Unnamed)' end
	name = numeric_index..'. '..name
	-- name = name .. ' (Note '..on_off_layer
	name = name .. ' ['..on_off_layer
	-- name = name .. ', Base '..self:note_num_to_note_name(map.base_note)
	name = name .. ', '..self:note_num_to_note_name(map.base_note)
	if map.note_range[1] ~= map.note_range[2] then
		range = range..' to '..self:note_num_to_note_name(map.note_range[2])
	end
	name = name .. ', '..range..']'
	--print(name)

	name = self:sanitize_filename(instrument.name)..PATH_SEPARATOR..self:sanitize_filename(name)
	return name

end

-----------------------------------------------------------------------------

function Dlvrr:save_instrument ( index )

	if not self:all_ok() then do return end end

	renoise.song().selected_instrument_index = index

	self.indicators.progress.value = 0
	local I = renoise.song().selected_instrument
	local filename = self:filename_xrni( index, I.name )

	local save_path = self:get_path_for(Dlvrr.CONTEXT_XRNI)
	self:create_folder(save_path)

	self.indicators.currently_saving.value = filename
	self.indicators.saving_context.value = 'instrument'
	self.indicators.saving_step.value = index
	self.indicators.saving_total.value = #renoise.song().instruments

	self.indicators.progress.value = 0.5 -- faking it, meh

	self:update_xrni_progress()
	TASKER:yield()
	local success = renoise.app():save_instrument(save_path..filename)
	if not success then
		self:fail('Failed to save Instrument(s).\nDoes the destination folder exist? Is it writable?')
	end
	self.indicators.progress.value = 1
	self:batch_step_increment()
	TASKER:continue()

end

-----------------------------------------------------------------------------

function Dlvrr:save_all_instruments ()

	if not self:all_ok() then do return end end

	local original_instrument = renoise.song().selected_instrument_index
	for i=1, #renoise.song().instruments do
		self:batch_step_add()
		local progress = function() self:update_xrni_progress()	end
		TASKER:add_task( function() self:save_instrument(i) end, progress )
	end
	local restore_state = function()
		renoise.song().selected_instrument_index = original_instrument
		TASKER:continue()
	end
	TASKER:add_task(restore_state)

end

-----------------------------------------------------------------------------

function Dlvrr:save_all_samples ()

	if not self:all_ok() then do return end end

	local sample_instruments = {}

	for i=1, #renoise.song().instruments do
		-- local I = renoise.song():instrument(i)
		if #renoise.song():instrument(i).samples > 0 then
			table.insert(sample_instruments, renoise.song():instrument(i))
		end
	end

	for i=1, #sample_instruments do
		local I = sample_instruments[i]

		self:batch_step_add()
		local f = function()
			if not self:all_ok() then do return end end

			rprint('saving '.. #I.samples..' samples for '..I.name)
			self.indicators.saving_context.value = 'samples'
			self.indicators.saving_step.value = i
			self.indicators.saving_total.value = #sample_instruments
			self.indicators.currently_saving.value = I.name

			local save_path = self:normalize_path(self:get_path_for(Dlvrr.CONTEXT_SAMPLE))
			local save_path_per_instrument = self:normalize_path(save_path..self:sanitize_filename(I.name))
			rprint('creating folder: '..save_path_per_instrument)
			self:create_folder(save_path_per_instrument)

			for n=1, #I.samples do

				if not self:all_ok() then do return end end

				TASKER:yield()
				local sample = I.samples[n]
				local filename = self:filename_sample(n, I, sample)
				local format = self.options.export_format_samples.value
				local filename_complete = save_path..filename..'.'..format
				local success = sample.sample_buffer:save_as(filename_complete, format)
				if not success then
					self:fail('Failed to save Sample(s).\nDoes the destination folder exist? Is it writable?')
				end

				self.indicators.progress.value = n / #I.samples
			end
			self:batch_step_increment()
		end
		local finished = function()
			self:set_status('Saving samples complete.')
			TASKER:continue()
		end
		local progress = function() self:update_sample_progress()	end
		TASKER:add_task( f, progress, finished )
	end

end

-----------------------------------------------------------------------------

function Dlvrr:save_track_states ()

	for i=1, #renoise.song().tracks do
		local t = renoise.song():track(i)
		if t.type ~= renoise.Track.TRACK_TYPE_MASTER then
			local c = {}
			c.solo_state = t.solo_state
			c.mute_state = t.mute_state
			self.state_cache[i] = c
		end
	end

end

-----------------------------------------------------------------------------

function Dlvrr:restore_track_states ()

	for k,v in pairs(self.state_cache) do
		local t = renoise.song():track(k)
		t.solo_state = v.solo_state
		t.mute_state = v.mute_state
	end

end

-----------------------------------------------------------------------------

function Dlvrr:unsolo_all_tracks ()

	for i=1, #renoise.song().tracks do
		renoise.song():track(i).solo_state = false
	end

end

-----------------------------------------------------------------------------

function Dlvrr:init_batch()

	TASKER:unlock()
	self.indicators.batch_steps.value = 1
	self.indicators.batch_current_step.value = 1

end

-----------------------------------------------------------------------------

function Dlvrr:batch_step_add()

	self.indicators.batch_steps.value = self.indicators.batch_steps.value + 1
	self.indicators.batch_progress.value = self.indicators.batch_current_step.value / self.indicators.batch_steps.value

end

-----------------------------------------------------------------------------

function Dlvrr:batch_step_increment()

	-- local csv = self.indicators.batch_current_step.value
	self.indicators.batch_current_step.value = self.indicators.batch_current_step.value + 1
	self.indicators.batch_progress.value = self.indicators.batch_current_step.value / self.indicators.batch_steps.value

end

-----------------------------------------------------------------------------

function Dlvrr:render_mixdown()

	if not self:all_ok() then do return end end

	local o = self.options
	local options = {
		bit_depth = o.render_mixdown_bit_depth.value,
		sample_rate = o.render_mixdown_sample_rate.value,
		interpolation = o.render_mixdown_interpolation.value,
		priority = o.render_mixdown_priority.value,
	}

	local mixdowns_folder = self:get_path_for(Dlvrr.CONTEXT_MIXDOWN)
	if not mixdowns_folder then
		self:fail('Mixdown folder can\'t be determined. This may happen when trying to render an unsaved song.\nTry saving your song and running The DELIVERER again.')
		do return end
	end

	if not io.exists(mixdowns_folder) then
		self:create_folder(mixdowns_folder)
		--return self:fail('Mixdown base folder does not exist:\n'..mixdowns_folder)
	end
	local mixdown_name = self:name_mixdown()
	local filename = mixdowns_folder .. self:sanitize_filename(mixdown_name)

	local rendering_done_callback = function()
		self:set_status('Rendering ['..self.indicators.currently_rendering.value..'] finished..')
		self:batch_step_increment()
		TASKER:continue()
	end

	self.indicators.render_context.value = 'mixdown'
	self.indicators.currently_rendering.value = mixdown_name
	self:update_render_progress()

	self:batch_step_add()
	local f = function()
		if not self:all_ok() then do return end end
		local status, errormsg = renoise.song():render(options, filename, rendering_done_callback)
		-- rprint({status, errormsg})
		if status == false then
			return self:fail(errormsg..'\nHINT: Is the folder read-only?')
		end

		while renoise.song().rendering == true do
			TASKER:yield()
			self.indicators.progress.value = renoise.song().rendering_progress
		end
	end
	local progress = function() self:update_render_progress()	end
	TASKER:add_task(f, progress)

end

-----------------------------------------------------------------------------

function Dlvrr:get_stem_meta ( track_num, Track )

	-- precision for padding zeros
	local precision = string.len(#renoise.song().tracks)

	-- use preferences to format
	local m = {
		number = string.format('%0'..precision..'d', track_num),
		name = Track.name,
		bit_depth = self.options.render_stems_bit_depth.value,
		sample_rate = self.options.render_stems_sample_rate.value,
		type = Track.type,
	}

	return m

end

-----------------------------------------------------------------------------

function Dlvrr:stem_should_render ( track )
	if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and self.options.stems_include_tracks.value == true then
		return true
	elseif track.type == renoise.Track.TRACK_TYPE_GROUP and self.options.stems_include_groups.value == true then
		return true
	else
		return false
	end
end

-----------------------------------------------------------------------------

function Dlvrr:render_all_stems()

	if not self:all_ok() then do return end end

	self:save_track_states()
	self:unsolo_all_tracks()
	for i=1, #renoise.song().tracks do
		if self:stem_should_render(renoise.song().tracks[i]) then
			self:batch_step_add()
			-- TODO: Check for empty tracks (No FX, no patterns)
			local f = function()
				self:render_stem(i)
			end
			local progress = function() self:update_render_progress() end
			TASKER:add_task(f, progress)
		end
	end
	TASKER:add_task(function()
		self:restore_track_states()
	end)

end

-----------------------------------------------------------------------------

function Dlvrr:render_stem( track_idx )

	local t = renoise.song():track(track_idx)

	local stems_folder = self:get_path_for(Dlvrr.CONTEXT_STEM)
	self:create_folder(stems_folder)

	if not self:all_ok() then do return end end

	-- Solo track for rendering
	t.solo_state = true

	local stem_name = self:name_stem( track_idx, t )
	local filename = stems_folder .. self:sanitize_filename(stem_name)

	self.indicators.render_context.value = 'stem'
	self.indicators.currently_rendering.value = stem_name
	self:update_render_progress()

	local o = self.options
	local options = {
		bit_depth = o.render_stems_bit_depth.value,
		sample_rate = o.render_stems_sample_rate.value,
		interpolation = o.render_stems_interpolation.value,
		priority = o.render_stems_priority.value,
	}
	local rendering_done_callback = function()
		-- de-solo track
		t.solo_state = false

		self:set_status('Rendering '..filename..' complete.')
		self:batch_step_increment()
		TASKER:continue()
	end

	local status, errormsg = renoise.song():render(options, filename, rendering_done_callback)
	if status == false then
		return self:fail(errormsg..'\nHINT: Is the folder read-only?')
	end

	while renoise.song().rendering == true do
		TASKER:yield()
		self.indicators.progress.value = renoise.song().rendering_progress
	end

end

-----------------------------------------------------------------------------

function Dlvrr:fail (status, callback, ...)

	TASKER:lock()
	TASKER:cancel_all()
	self.ok_status.value = false
	self:set_status('ERROR: '..status)

	print('FAILED: '..status)

	if callback then
		callback(...)
	end

end

-----------------------------------------------------------------------------

function Dlvrr:update_progress ()
	-- do something.
end












--===========================================================================
--  R E Q U I R E   G U I
-----------------------------------------------------------------------------
require 'gui'

local The_DELIVERER = nil


--===========================================================================
--     ___  _ __ _ ___  _ __ _ ____ ____    /   _  _ ____ __ _ _  _
--     |==] | | \| |__> | | \| |__, ====   /    |\/| |=== | \| |__|
--
--     K E Y B I N D I N G S   /   M E N U   E N T R I E S
-----------------------------------------------------------------------------

renoise.tool():add_keybinding {
	name = "Global:Tools:The Deliverer (dltfm)",
	invoke = function()
		if not The_DELIVERER then The_DELIVERER = DlvrrGui() end
		The_DELIVERER:open()
	end
}

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:dltfm:The Deliverer",
	invoke = function()
		if not The_DELIVERER then The_DELIVERER = DlvrrGui() end
		The_DELIVERER:open()
	end
}


-- vim: foldenable:foldmethod=syntax:foldnestmax=1:foldlevel=0:foldcolumn=3
-- :foldopen=all:foldclose=all
