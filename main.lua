--[[
------------------------------------------------------------------------------
	____ _  _ ___  ___  ____ ____ ___  ____ _  _ ___     ____ _ ___  
	|__/ |  | |__] |__] |___ |__/ |__] |__| |\ | |  \ __ |__| | |  \ 
	|  \ |__| |__] |__] |___ |  \ |__] |  | | \| |__/    |  | | |__/ 

	DLT <dave.tichy@gmail.com>
------------------------------------------------------------------------------
	Enhanced Rubber Band Time Stretch plugin for Renoise
------------------------------------------------------------------------------

	v0.7: 2020-06-01
	----
		- Fixed path issues on Windows
		- Windows tested working

	v0.6: 2020-05-19
	----
		- Improved status messaging
		- Added coroutines to help keep UI from locking up during long operations
		- Improved codebase
		- Fixed: Incorrectly shifted loop points when timestretching
		- Fixed: Loop mode reset for some pitch shifted samples
		- Fixed: UI issues with button disabling and status text

	v0.5: 2020-05-04
	----
		- General: Create new instrument to hold temp samples (in case we're stretching a sliced sample)
		- General: Shift markers inside and following shifted selection, based on original % location in file
		- Shift loop points inside and following shifted selection
		- Feature: Add functionality to build a multisample instrument from a single repitched sample, to preserve sample tail and lengths.
		- Multisampler: Add repitched samples at interval of n notes (octave, tritone, minor 3rd, etc)

	
	KNOWN BUGS:
	----------------
		- BUG: Multisampled instruments sometimes botch the keyzone position of the primary sample
		- BUG: Some slices disappear when resyncing after stretching sliced samples

	Someday / Maybe:
	----------------
		* [High] Performance: Improve speed of selection/temp buffer copying - maybe xLib? [copy_sample_buffer()]
		* [High] Time Stretch: Sliced samples: Deal with slice marker points shifting
		* [High] Multisampler: Bump loop points to nearest zero crossing on multisample instruments
		* [High] Time Stretch: Bump loop points to nearest zero crossing
		* [Medium] Multisampler: Add setting to enable/disable zero crossing detection for copied loop points
		* [Medium] Time Stretch: Add setting to enable/disable zero crossing detection for copied loop points
		* [Medium] General: Add support for saving presets
		* [Low] Time Stretch GUI: Implement key binding to increment/decrement # of lines/bars on stretch dialog

--]]


--=============================================================================
-- "Globals" and Requires
--=============================================================================

options = {}

require "renoise.http.util"

require "util"

require "coroutine_runner"
local TASKER = Dlt_CoroutineRunner()



DEFAULT_SETTINGS = {
	stretch = {
		---------
		interval = 16,
		unit = 2, -- beats
		crispness = 5, -- Rubberband's default, great for most things
		loose = true, --great for preserving drum transients
		smoothing = false,
		centerfocus = false,
		threads = true,
		---
		lock_slices = false,
		lock_loop_points = false,
		---
		gui = {
			show_advanced = false,
		},
	},

	pitch = {
		-------
		cents = 100,
		crispness = 5, -- Rubberband's default, great for most things
		preserve_formant = true,
		threads = true,
		smoothing = false,
		centerfocus = false,
		---
		gui = {
			show_advanced = false,
		},
	},

	multisample = {
		-------------
		crispness = 3, -- Seems to work well for basses
		preserve_formant = true,
		threads = true,
		smoothing = false,
		centerfocus = false,
		cents = 100, -- TODO: Allow adjustment to make microtonal intruments?
		---
		sample_interval = 3, -- semitones between resamples/new keyzones
		start_note = 24,
		end_note = 84,
		apply_microfades = true,
		create_new_instrument = false,
		resample_successively = false,
		---
		gui = {
			show_advanced = false,
		},
	}

}

--=============================================================================
-- Preferences, Menus, & Keybindings
--=============================================================================
function get_rubberband_binary ()
	-------------------------------
	if os.platform() == 'MACINTOSH' then
		-- Make sure we're executable
    io.chmod(renoise.tool().bundle_path .. 'bin/mac/rubberband', 755);
		return renoise.tool().bundle_path .. 'bin/mac/rubberband'
	elseif os.platform() == 'WINDOWS' then
		return renoise.tool().bundle_path .. 'bin\\win\\rubberband.exe'
	else
		return 'rubberband'
	end
	---
end


function load_preferences ( )
	--------------------------
	options = renoise.Document.create("RubberbandOptions") {

		path_to_rubberband = get_rubberband_binary(),

		stretch = DEFAULT_SETTINGS.stretch,
		pitch = DEFAULT_SETTINGS.pitch,
		multisample = DEFAULT_SETTINGS.multisample,
	}
	renoise.tool().preferences = options
	---
end

-- TODO: Get this working. Because it doesn't, and it's terrible to look at.
function restore_defaults ( context )
	-----------------------------------

	options:remove_property( options[context] )
	options:add_property(context, DEFAULT_SETTINGS[context])
	renoise.app():show_status("RubberBand-Aid restored defaults for "..context)

	---
end


function setup_keybindings ()
	---------------------------
	renoise.tool():add_keybinding({
		name = "Sample Editor:Process:[RubberBand-Aid] Time Stretch...",
		invoke = function() open_stretch_dialog() end
	})

	renoise.tool():add_keybinding({
		name = "Sample Editor:Process:[RubberBand-Aid] Pitch Shift...",
		invoke = function() open_shift_dialog() end
	})

	renoise.tool():add_keybinding({
		name = "Sample Editor:Process:[RubberBand-Aid] Build Multisample Instrument...",
		invoke = function() open_multisample_dialog() end
	})
	---
end


function setup_menu_entries ()
	----------------------------
	renoise.tool():add_menu_entry({
		name = "Sample Editor:RubberBand-Aid:Time Stretch...",
		invoke = function() open_stretch_dialog() end
	})

	renoise.tool():add_menu_entry({
		name = "Sample Editor:RubberBand-Aid:Pitch Shift...",
		invoke = function() open_shift_dialog() end
	})

	renoise.tool():add_menu_entry({
		name = "Sample Editor:RubberBand-Aid:Build Multisample Instrument...",
		invoke = function() open_multisample_dialog() end
	})

	renoise.tool():add_menu_entry({
		name = "Sample Editor:RubberBand-Aid:Configuration...",
		invoke = function() open_help('config') end
	})

	---
end











load_preferences()
------------------------------------------


function run_sanity_checks()
	--------------------------
	if renoise.song().selected_sample_index == 0 then
		return false
	end

	return true
end










class 'Dlt_SampleTools'
function Dlt_SampleTools:__init ()
------------------------|

end

function Dlt_SampleTools:fade_in (sample, fade_length)
--[[--------------------|
	--]]
	return self:fade_sample(sample, fade_length, false)
end

function Dlt_SampleTools:fade_out (sample, fade_length)
--[[--------------------|
	--]]
	return self:fade_sample(sample, fade_length, true)
end


function Dlt_SampleTools:fade_symmetric (sample, fade_length)
--[[--------------------|
	--]]
	sample = self:fade_sample(sample, fade_length, false)
	return self:fade_sample(sample, fade_length, true)
end

function Dlt_SampleTools:fade_sample (sample, fade_length, bool_fade_in)
--[[--------------------|
	--]]
	bool_fade_in = (bool_fade_in ~= false) -- default: fade out
	fade_length = fade_length or 15 -- frames

	local b = sample.sample_buffer
	local sample_length = b.number_of_frames
	local data = 0
	for c = 1, b.number_of_channels do

		if bool_fade_in then
			-- fade in
			for n = 1, fade_length do
				if n <= sample_length then
					data = b:sample_data(c, n)
					data = ((n - 1) / fade_length) * data -- linear fade in
					b:set_sample_data(c, n, data)
				end
			end
		else
			-- fade out
			for n = 1, fade_length do
				local curr_frame = sample_length - fade_length + n
				if n <= sample_length then
					data = b:sample_data(c, curr_frame)
					data = (1 - (n / fade_length)) * data -- linear fade out
					b:set_sample_data(c, curr_frame, data)
				end
			end
		end

	end
	return sample
end

function Dlt_SampleTools:get_selected_buffer_length ()
--[[--------------------|
	--]]
	return renoise.song().selected_sample.sample_buffer.selection_end - renoise.song().selected_sample.sample_buffer.selection_start
end

function Dlt_SampleTools:get_selected_buffer_length_in_s ()
--[[--------------------|
	--]]
	local num_samples = self:get_selected_buffer_length()
	return num_samples / renoise.song().selected_sample.sample_buffer.sample_rate
end

-- TODO: Make this MUCH faster
-- TODO: THERE HAS TO BE A BETTER WAY FFS - xLib?!? xSampleBuffer?
function Dlt_SampleTools:copy_sample_buffer (source_sample, dest_sample, start_frame, end_frame)
--[[--------------------|
	Copy a portion of the source sample to a destination sample, clearing the
	contents of the destination.
	--]]
	start_frame = start_frame or 1
	end_frame   = end_frame or source_sample.sample_buffer.end_frame

	local b = source_sample.sample_buffer
	local selection_length = end_frame - start_frame

	-- if longer than ~10 seconds, let's throw in a coroutine.yield() here to keep
	-- things moving along
	TASKER:yield_if( selection_length > 480000 )

	dest_sample.sample_buffer:create_sample_data(b.sample_rate, b.bit_depth, b.number_of_channels, selection_length)

	for channel = 1, b.number_of_channels do
		for frame = 1, selection_length do
			dest_sample.sample_buffer:set_sample_data(channel, frame, b:sample_data(channel, start_frame + frame))
		end
	end
end

function Dlt_SampleTools:copy_loop_data (source_sample, dest_sample)
--[[--------------------|
	--]]
		dest_sample.loop_mode = source_sample.loop_mode
		dest_sample.loop_release = source_sample.loop_release
		dest_sample.loop_start = source_sample.loop_start
		dest_sample.loop_end = source_sample.loop_end
end

function Dlt_SampleTools:add_sample_data (dest, source, pos_offset)
--[[--------------------|
	Writes sample data from a source buffer to a destination buffer, starting
	at an optional offset. NOTE: OVERWRITES sample data existing in dest sample
	(starting from offset through length of source sample).
	--]]
	if source.has_sample_data then
		local end_frame = dest.number_of_frames + source.number_of_frames
		for frame = 1, source.number_of_frames do
			for channel = 1, dest.number_of_channels do
				dest:set_sample_data(channel, pos_offset+frame, source:sample_data(channel, frame))
			end
		end
	end
end

function Dlt_SampleTools:concat_buffers (dest, s1, s2, s3)
--[[--------------------|
	Join up to 3 buffers and copy into the destination buffer
	TODO: Allow joining arbitrary numbers of samples
	--]]
	-- determine new sample length
	local s1_len = 0
	local s2_len = 0
	local s3_len = 0
	if s1.has_sample_data then
		s1_len = s1.number_of_frames
	end
	if s2.has_sample_data then
		s2_len = s2.number_of_frames
	end
	if s3.has_sample_data then
		s3_len = s3.number_of_frames
	end

	local total_length = 1 + s1_len + s2_len + s3_len

	-- initialize destination sample
	dest:create_sample_data(s2.sample_rate, s2.bit_depth, s2.number_of_channels, total_length)

	-- create undo point
	dest:prepare_sample_data_changes()

	local s2_offset = s1_len
	local s3_offset = s1_len + s2_len
	self:add_sample_data(dest, s1, 1)
	TASKER:yield()
	self:add_sample_data(dest, s2, s2_offset)
	TASKER:yield()
	self:add_sample_data(dest, s3, s3_offset)

	-- finish
	dest:finalize_sample_data_changes()
end

function Dlt_SampleTools:resync_slice_markers (sample, selection_start, selection_end, new_length)
--[[--------------------|
	Slides slice markers over in the given sample to accommodate a resized or
	stretched portion.
		From: [   m |start   m        m     |end    m      ]
		To:   [   m |start     m         m      |end    m      ]
	--]]
	local orig_length = selection_end - selection_start + 1
	local suffix_offset = new_length - orig_length

	-- no slice markers, nothing to do
	if table.getn(sample.slice_markers) == 0 then
		return
	end

	for k, pos in ipairs(sample.slice_markers) do
		-- rprint(pos);
		if pos > selection_start then
			-- We need to shift it
			-- BEYOND AFFECTED SELECTION
			if pos >= selection_end then
				local newpos = pos + suffix_offset
				sample:move_slice_marker(pos, newpos)
			else
				local rel_pos = (pos - selection_start) / orig_length * 1.0
				local newpos = (rel_pos * new_length * 1.0) + selection_start
				sample:move_slice_marker(pos, newpos)
			end
		end
	end
end

function Dlt_SampleTools:resync_loop_points (sample, selection_start, selection_end, new_length, orig_loop_start, orig_loop_end)
--[[--------------------|
	Slides loop points over in the given sample to accommodate a resized or
	stretched portion.
	--]]
	-- rprint({selection_start, selection_end, new_length, orig_loop_start, orig_loop_end})
	local orig_length = selection_end - selection_start + 1
	local suffix_offset = new_length - orig_length

	-- rprint({orig_length, new_length})
	if orig_length == new_length then
		sample.loop_start = orig_loop_start
		sample.loop_end = orig_loop_end
		return
	end

	if orig_loop_start > selection_start then
		if orig_loop_start >= selection_end then
			sample.loop_start = orig_loop_start + suffix_offset
		else
			local rel_pos = (orig_loop_start - selection_start) / orig_length * 1.0
			local new_pos = (rel_pos * new_length * 1.0) + selection_start
			sample.loop_start = new_pos
		end
	else
		sample.loop_start = orig_loop_start
	end

	if orig_loop_end > selection_start then
		if orig_loop_end >= selection_end then
			sample.loop_end = orig_loop_end + suffix_offset
		else
			local rel_pos = (orig_loop_end - selection_start) / orig_length * 1.0
			local new_pos = (rel_pos * new_length * 1.0) + selection_start
			sample.loop_end = new_pos
		end
	else
		sample.loop_end = orig_loop_end
	end
end




















class 'Dlt_RubberBand'

function Dlt_RubberBand:__init (path_to_binary)
--[[-------------------|
	--]]
	self.path_to_binary = path_to_binary or options.path_to_rubberband.value

	self.SampleTools = Dlt_SampleTools()

	self.indicators = {
		working = renoise.Document.ObservableBoolean(false),
		status = renoise.Document.ObservableString(''),
		in_binary = renoise.Document.ObservableBoolean(false),
	}

end

function Dlt_RubberBand:set_status (status)
	self.indicators.status.value = status
	renoise.app():show_status('RubberBand-Aid: ' .. status)
end


function Dlt_RubberBand:get_command (arguments, input_filename, output_filename)
--[[-------------------|
	--]]
	arguments = arguments or {}
	input_filename = input_filename or ''
	output_filename = output_filename or ''

	local cli_args = ''
	for k, v in pairs(arguments) do
		cli_args = cli_args .. ' --'..k
		if v ~= '' then
			-- add a value if we have one
			cli_args = cli_args..' '..v
		end
	end

	local path_to_binary = self.path_to_binary
	if os.platform() == 'WINDOWS' then
		path_to_binary = '\"'..path_to_binary..'\"'
		input_filename = '\"'..input_filename..'\"'
		output_filename = '\"'..output_filename..'\"'
	end

	local command = path_to_binary  .. cli_args .. ' ' .. input_filename .. ' ' .. output_filename
	print(command)
	return command
end


function Dlt_RubberBand:failed ()
--[[-------------------|
	--]]
	self:set_status("Failed")
	local buttontext = 'Get Help'
	local response = renoise.app():show_prompt('RubberBand-Aid Failure',
		"RubberBand-Aid failed to run.\n\n"
		.."Make sure the rubberband binary is executable and \n"
		.."all required libraries are installed."
		, {buttontext})
	if response == buttontext then
		open_help('config')
	end
end


function Dlt_RubberBand:process_sample (sample, arguments)
--[[-------------------|
	--]]
	local input_file, output_file
	self.indicators.in_binary.value = true

	input_file = os.tmpname('wav')
	sample.sample_buffer:save_as(input_file, 'wav')
	output_file = os.tmpname('wav')

	TASKER:yield()
	local rb_command = self:get_command(arguments, input_file, output_file)
	if os.platform() == 'WINDOWS' then
		os.execute('"'..rb_command..'"')
	else
		os.execute(rb_command)
	end

	if not io.exists(output_file) then
		self:failed()
	else
		sample.sample_buffer:load_from(output_file)
	end

	-- Clean up
	os.remove( input_file )
	os.remove( output_file )
	self.indicators.in_binary.value = false
end


function Dlt_RubberBand:process_sample_parallelized (sample, arguments)
--[[-------------------|
	--]]
	local input_file, output_file
	self.indicators.in_binary.value = true

	local fn_main = function ()
		input_file = os.tmpname('wav')
		sample.sample_buffer:save_as(input_file, 'wav')
		output_file = os.tmpname('wav')

		local rb_command = self:get_command(arguments, input_file, output_file)
		os.execute(rb_command)

		if not io.exists(output_file) then
			self:failed()
		else
			sample.sample_buffer:load_from(output_file)
		end

		-- Clean up
		os.remove( input_file )
		os.remove( output_file )
	end
	local fn_progress = function ()
		self:set_status('Running Rubber Band...')
	end
	local fn_finished = function ()
		self.indicators.in_binary.value = false
		-- print('we finished')
		TASKER:continue()
	end
	TASKER:add_task(fn_main, fn_progress, fn_finished)
end


function Dlt_RubberBand:process_sample_selection (arguments)
--[[-------------------|
	Applies RubberBand to selection region of renoise.song().selected_sample
	--]]

	-- Don't process if durations will be the same
	if arguments.duration then
		local selection_length_s = self.SampleTools:get_selected_buffer_length_in_s()
		if arguments.duration == selection_length_s then
			self:set_status('Nothing to do: Selection is already at desired length.')
			return
		end
	elseif arguments.time and arguments.time == 1 then
		-- Stretch to 100%
		self:set_status('Nothing to do: Selection is already at desired length.')
		return
	end

	-- Start Processing
	self.indicators.working.value = true
	self:set_status('RubberBand-Aid running...')
	TASKER:yield()

	local INSTRUMENT = renoise.song().selected_instrument
	local SAMPLE = renoise.song().selected_sample
	local BUFFER = SAMPLE.sample_buffer
	local ORIG_INDEX = renoise.song().selected_sample_index
	local ORIG_INSTRUMENT_INDEX = renoise.song().selected_instrument_index

	local start_idx = BUFFER.selection_start
	local end_idx = BUFFER.selection_end
	local sample_length = BUFFER.number_of_frames
	local orig_display_range = BUFFER.display_range
	local orig_display_start = BUFFER.display_start
	local orig_display_length = BUFFER.display_length

	local orig_loop_data = {}
	self.SampleTools:copy_loop_data(SAMPLE, orig_loop_data)

	local whole_sample = nil
	local s1,s2,s3,TEMP_INSTRUMENT
	-- If the whole sample is selected (or none), save time by working on the
	-- whole sample; avoid creating extra instrument/sample buffers
	-- We're doing this with a 1-frame looseness because Renoise is a little
	-- loose with selection_end when select all vs. select none
	if start_idx == 1 and end_idx + 1 >= sample_length then
		whole_sample = true
		s2 = SAMPLE
	end

	if not whole_sample then
		self:set_status('Writing temp buffers...')
		TASKER:yield()
		-- create temp sample containers to hold the pieces
		TEMP_INSTRUMENT = renoise.song():insert_instrument_at(1)
		s3 = TEMP_INSTRUMENT:insert_sample_at(1)
		s2 = TEMP_INSTRUMENT:insert_sample_at(1)
		s1 = TEMP_INSTRUMENT:insert_sample_at(1)
		-- ...and give them some names in case things go wrong
		s1.name = '[RubberBand-Aid] prefix'
		s2.name = '[RubberBand-Aid] selection'
		s3.name = '[RubberBand-Aid] suffix'
	
		-- Just keep the user looking at the same thing
		renoise.song().selected_instrument_index = 1
		renoise.song().selected_sample_index = 2

		if start_idx ~= 1 then
			self.SampleTools:copy_sample_buffer(SAMPLE, s1, 0, start_idx)
		end
		self.SampleTools:copy_sample_buffer(SAMPLE, s2, start_idx, end_idx)
		if end_idx ~= sample_length then
			self.SampleTools:copy_sample_buffer(SAMPLE, s3, end_idx, sample_length)
		end
	end

	-- DO THE MAGIC
	self:set_status("Handing off to Rubber Band binary... This could take a while.")
	-----------------------------------
	self:process_sample(s2, arguments) 
	-- TASKER:yield()
	---------------------------------

	local newlength = s2.sample_buffer.number_of_frames

	if not whole_sample then
		self:set_status("Writing changes to sample...")
		TASKER:yield()
		-- Join the 3 [pre] -> [selection] -> [post] buffers and replace the 
		-- source sample with the new content
		self.SampleTools:concat_buffers(SAMPLE.sample_buffer, s1.sample_buffer, s2.sample_buffer, s3.sample_buffer)

		self:set_status("Cleaning up...")
		TASKER:yield()

		-- Clean up temp sample containers
		renoise.song():delete_instrument_at(1)
		renoise.song().selected_instrument_index = ORIG_INSTRUMENT_INDEX
	end

	-- Shift slice markers, if required
	if options.stretch.lock_slices.value ~= true then
		self.SampleTools:resync_slice_markers(SAMPLE, start_idx, end_idx, newlength)
	end

	-- Shift loop points, if required
	if options.stretch.lock_loop_points.value ~= true then
		self.SampleTools:resync_loop_points(SAMPLE, start_idx, end_idx, newlength, orig_loop_data.loop_start, orig_loop_data.loop_end)
	end
	SAMPLE.loop_mode = orig_loop_data.loop_mode
	SAMPLE.loop_release = orig_loop_data.loop_release

	-- SYNC DISPLAY
	-- 1. Re-show the original sample
	renoise.song().selected_sample_index = ORIG_INDEX

	-- 2. Re-select the same selection of music, taking into account stretching
	SAMPLE.sample_buffer.selection_start = start_idx
	SAMPLE.sample_buffer.selection_end = start_idx + s2.sample_buffer.number_of_frames - 1

	-- 3. Restore the zoom range to where it was before we started
	local zoom_range = orig_display_range
	if zoom_range[2] > SAMPLE.sample_buffer.number_of_frames then
		zoom_range[2] = SAMPLE.sample_buffer.number_of_frames
	end
	SAMPLE.sample_buffer.display_range = zoom_range
	self.indicators.working.value = false
	self:set_status("Done.")
end







class 'Dlt_RubberBandApi'
function Dlt_RubberBandApi:__init()
	self.RubberBand = Dlt_RubberBand()
	self.SampleTools = Dlt_SampleTools()

	self.indicators = self.RubberBand.indicators
-- 
	-- self.process_timestretch = function(...) return self:timestretch(...) end
	-- self.process_pitchshift = function(...) return self:pitchshift(...) end
	-- self.process_multisampling = function(...) return self:multisample(...) end
end


function Dlt_RubberBandApi:timestretch (unit, interval, opts)
	opts = opts or {}

	-- Table of arguments to Rubberband
	local args = {}

	local bpm = renoise.song().transport.bpm
	local lpb = renoise.song().transport.lpb
	local beat_length = 60.0 / bpm
	local row_length = 60.0 / bpm / lpb

	-- New duration / stretch factor
	if unit == 1 then
		args['duration'] = interval * row_length -- lines
		---
	elseif unit == 2 then
		args['duration'] = interval * beat_length -- beats
		---
	elseif unit == 3 then
		args['duration'] = interval -- seconds
		---
	elseif unit == 4 then
		-- NOTE: we use '--time' instead of '--duration' for % increase/decrease
		args['time'] = interval / 100 -- percent
		---
	end

	-- Options with Values
	----------------------
	if opts.crisp then args['crisp'] = opts.crisp end -- crispness

	-- Toggled Options
	-------------------
	-- Arguments without a value should be set to '' (empty string)
	if opts.threads then args['threads'] = '' end -- multithreading
  if opts.loose then args['loose'] = '' end -- loose timing/better transients
	if opts.smoothing then args['smoothing'] = '' end -- smoothing (for huge stretches)
	if opts.centerfocus then args['centre-focus'] = '' end -- focus on center material quality

		-- self.RubberBand:process_sample_selection( args )
		-- return
	TASKER:add_task(function()
		self.RubberBand:process_sample_selection( args )
	end,
	function() 
		-- progress
	end,
	function()
		-- finished
	end)
end


function Dlt_RubberBandApi:pitchshift ( cents, opts )
	opts = opts or {}

	-- Table of arguments to Rubberband
	local args = {}

	-- Pitch shift
	args['pitch'] = cents / 100.0 -- '--pitch' arg takes semitones

	-- Options with Values
	----------------------
	if opts.crisp then args['crisp'] = opts.crisp end -- crispness

	-- Toggled Options
	-------------------
	-- Arguments without a value should be set to '' (empty string)
	if opts.threads then args['threads'] = '' end -- multithreading
  -- if opts.loose then args['loose'] = '' end -- loose timing/better transients
	if opts.smoothing then args['smoothing'] = '' end -- smoothing (for huge stretches)
	if opts.centerfocus then args['centre-focus'] = '' end -- focus on center material quality

	--args['realtime'] = ''
	-- Use high quality pitch shifting - not sure this actually applies outside
	-- of realtime mode, but it's here anyway
	args['pitch-hq'] = ''

	TASKER:add_task(function()
		self.RubberBand:process_sample_selection( args )
	end,
	function() 
		-- progress
	end,
	function()
		-- finished
	end)
end


-- TODO: When syncing loop points, try to bump them to the next zero crossing
function Dlt_RubberBandApi:multisample ( interval, start_note, end_note, opts )
	---------------------------------------------------------------------

	-- interval = interval or 12 -- default to octave
	-- start_note = start_note or 0 -- default to entire keybd
	-- end_note = end_note or 119 -- default to entire keybd
	interval = interval or 6 -- tritone
	start_note = start_note or 24 -- C2
	end_note = end_note or 84 -- C7

	-------------------
	opts = opts or {
		crisp = 3,
		threads = true,
		-- repitch each new sample successively from the previous one
		-- (instead of basing all resamples on the original sample).
		-- Can dramatically alter/mangle the character of the sound.
		resample_successively = false,
	}

	-- Table of arguments to Rubberband
	local args = {}

	-- Options with Values
	----------------------
	if opts.crisp then args['crisp'] = opts.crisp end -- crispness

	-- Toggled Options
	-------------------
	-- Arguments without a value should be set to '' (empty string)
	if opts.threads then args['threads'] = '' end -- multithreading
  -- if opts.loose then args['loose'] = '' end -- loose timing/better transients
	if opts.smoothing then args['smoothing'] = '' end -- smoothing (for huge stretches)
	if opts.centerfocus then args['centre-focus'] = '' end -- focus on center material quality

	--args['realtime'] = ''
	-- Use high quality pitch shifting
	args['pitch-hq'] = ''
	-------------------

	self.RubberBand.indicators.working.value = true
	self.RubberBand:set_status('Creating multisampled instrument...')

	TASKER:add_task(function()
		-- TASKER:yield()
		-- In place
		local I = renoise.song().selected_instrument
		local S = renoise.song().selected_sample
		
		-- Copy current sample into new instrument and duplicate settings
		-- local orig_s = renoise.song().selected_sample
		-- orig_loop_mode = orig_s.loop_mode
		-- orig_loop_release = orig_s.loop_release
		-- orig_loop_start = orig_s.loop_start
		-- orig_loop_end = orig_s.loop_end
		-- local I = renoise.song():insert_instrument_at( renoise.song().selected_instrument_index + 1 )
		-- local S = I:insert_sample_at(1)
		-- S:copy_from(orig_s)
		-- I.name = S.name .. ' (Multisampled)'

		local s2, new_idx
		local base_note = S.sample_mapping.base_note
		local num_iterations_down = math.floor((base_note - start_note) / interval)
		local num_iterations_up = math.floor((end_note - base_note) / interval)

		local last_sample = S
		
		-- build out samples under this one
		for n = 1, num_iterations_down do
				s2 = I:insert_sample_at( 1 )
				if opts.resample_successively then
					s2:copy_from(last_sample)
				else
					s2:copy_from(S)
				end

				args['pitch'] = 0 - (interval * n)  -- semitones
				self.RubberBand:process_sample(s2, args)
				-- set proper mapping
				base_note = base_note - interval
				s2.sample_mapping.base_note = base_note
				if n == num_iterations_down then
					-- if this is the last one down, make sure it goes all the way down to start note
					s2.sample_mapping.note_range = { start_note, base_note + interval - 1 }
				else
					s2.sample_mapping.note_range = { base_note, base_note + interval - 1 }
				end
				-- Sync loop points
				self.RubberBand.SampleTools:copy_loop_data(S, s2)
				if opts.apply_microfades then
					self.RubberBand.SampleTools:fade_symmetric(s2, 15)
				end
				last_sample = s2
		end

		-- build out samples above it
		base_note = S.sample_mapping.base_note -- start over
		last_sample = S
		for n = 1, num_iterations_up do

				new_idx = table.maxn(I.samples) + 1
				s2 = I:insert_sample_at( new_idx )
				if opts.resample_successively then
					s2:copy_from(last_sample)
				else
					s2:copy_from(S)
				end

				args['pitch'] = interval * n -- semitones
				self.RubberBand:process_sample(s2, args)
				-- set proper mapping
				base_note = base_note + interval
				s2.sample_mapping.base_note = base_note
				if n == num_iterations_up then
					-- if this is the last one up, make sure it goes all the way up to end note
					s2.sample_mapping.note_range = { base_note, end_note }
				else
					s2.sample_mapping.note_range = { base_note, base_note + interval - 1 }
				end
				-- Sync loop points
				self.RubberBand.SampleTools:copy_loop_data(S, s2)
				if opts.apply_microfades then
					self.RubberBand.SampleTools:fade_symmetric(s2, 15)
				end
				last_sample = s2
		end

		-- Finally make sure original sample is mapped correctly
			base_note = S.sample_mapping.base_note -- start over
			S.sample_mapping.note_range = { base_note, base_note + interval - 1 }
	end,
	function() 
		-- progress
		self.RubberBand:set_status("Building sample set...")
	end,
	function()
		---
		self.RubberBand.indicators.working.value = false
		self.RubberBand:set_status("Done.")
	end)
end












--=============================================================================
-- Initialize Tool
--=============================================================================

require 'gui'
setup_keybindings()
setup_menu_entries()










--[[ FOR REFERENCE ]]
--=============================================================================
--[[
Rubber Band
An audio time-stretching and pitch-shifting library and utility program.
Copyright 2007-2018 Particular Programs Ltd.

   Usage: ./rubberband [options] <infile.wav> <outfile.wav>

You must specify at least one of the following time and pitch ratio options.

  -t<X>, --time <X>       Stretch to X times original duration, or
  -T<X>, --tempo <X>      Change tempo by multiple X (same as --time 1/X), or
  -T<X>, --tempo <X>:<Y>  Change tempo from X to Y (same as --time X/Y), or
  -D<X>, --duration <X>   Stretch or squash to make output file X seconds long

  -p<X>, --pitch <X>      Raise pitch by X semitones, or
  -f<X>, --frequency <X>  Change frequency by multiple X

  -M<F>, --timemap <F>    Use file F as the source for key frame map

A map file consists of a series of lines each having two numbers separated
by a single space.  These are source and target sample frame numbers for fixed
time points within the audio data, defining a varying stretch factor through
the audio.  You must specify an overall stretch factor using e.g. -t as well.

The following options provide a simple way to adjust the sound.  See below
for more details.

  -c<N>, --crisp <N>      Crispness (N = 0,1,2,3,4,5,6); default 5 (see below)
  -F,    --formant        Enable formant preservation when pitch shifting

The remaining options fine-tune the processing mode and stretch algorithm.
These are mostly included for test purposes; the default settings and standard
crispness parameter are intended to provide the best sounding set of options
for most situations.  The default is to use none of these options.

  -L,    --loose          Relax timing in hope of better transient preservation
  -P,    --precise        Ignored: The opposite of -L, this is default from 1.6
  -R,    --realtime       Select realtime mode (implies --no-threads)
         --no-threads     No extra threads regardless of CPU and channel count
         --threads        Assume multi-CPU even if only one CPU is identified
         --no-transients  Disable phase resynchronisation at transients
         --bl-transients  Band-limit phase resync to extreme frequencies
         --no-lamination  Disable phase lamination
         --window-long    Use longer processing window (actual size may vary)
         --window-short   Use shorter processing window
         --smoothing      Apply window presum and time-domain smoothing
         --detector-perc  Use percussive transient detector (as in pre-1.5)
         --detector-soft  Use soft transient detector
         --pitch-hq       In RT mode, use a slower, higher quality pitch shift
         --centre-focus   Preserve focus of centre material in stereo
                          (at a cost in width and individual channel quality)

  -d<N>, --debug <N>      Select debug level (N = 0,1,2,3); default 0, full 3
                          (N.B. debug level 3 includes audible ticks in output)
  -q,    --quiet          Suppress progress output

  -V,    --version        Show version number and exit
  -h,    --help           Show this help

"Crispness" levels:
  -c 0   equivalent to --no-transients --no-lamination --window-long
  -c 1   equivalent to --detector-soft --no-lamination --window-long (for piano)
  -c 2   equivalent to --no-transients --no-lamination
  -c 3   equivalent to --no-transients
  -c 4   equivalent to --bl-transients
  -c 5   default processing options
  -c 6   equivalent to --no-lamination --window-short (may be good for drums)

]]
--=============================================================================
