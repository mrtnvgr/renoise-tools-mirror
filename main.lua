local name = "cycler"

---@type renoise.ScriptingTool
local tool = renoise.tool()

require("state")

---@type CyclerState
local state = nil

local help = {
	edit = {
		{ "escape", "select mode" },
	},
	select = {
		{ "enter",         "edit mode" },
		{ "escape",        "close window" },
		{ "left-right",    "select track" },
		{ "up-down",       "select instrument" },
		{ "alt + up-down", "select pattern" },
	},
}

---@class CyclerPrefs : renoise.Document.DocumentNode
---@field autorender renoise.Document.ObservableBoolean

local default_prefs = {
	autorender = true
}

---@type CyclerPrefs
local prefs = renoise.Document.create("ScriptingToolPreferences")(default_prefs)
renoise.tool().preferences = prefs
prefs.autorender.value = true

---@type fun(song: renoise.Song, pattern_index: integer, track_index: integer, renderer_type: integer, script: string, transpose_octave: boolean)
local function save_script(song, pattern_index, track_index, renderer_type, script, transpose_octave)
	if state then
		local oct = ""
		if transpose_octave then
			oct = song.transport.octave .. ""
		end

		local t = state:pattern_track(song, pattern_index, track_index)
		t.script.value = script
		t.renderer_type.value = RendererType.from_integer(renderer_type)
		t.instrument.value = song.selected_instrument_index
		t.octave.value = oct

		song.tool_data = state:to_string()
	end
end

---@type fun(song: renoise.Song, cycle: string):string[]
local function generate_cycle_script(_, cycle)
	local script = "return cycle([=[" .. cycle .. "]=])"
	return { script }
end

---@alias NoteColumnMapper fun(song: renoise.Song, from: renoise.NoteColumn, to: renoise.NoteColumn)

---@type NoteColumnMapper
local function copy_note_column(song, from, to)
	to:copy_from(from)
	if from.note_value ~= renoise.PatternLine.EMPTY_NOTE then
		if from.instrument_value == 255 then
			to.instrument_value = song.selected_instrument_index - 1
		end
	end
end

---@type fun(song: renoise.Song, phrase: renoise.InstrumentPhrase, map_note_column: NoteColumnMapper)
local function copy_phrase_to_pattern(song, phrase, map_note_column)
	local t = song:track(song.selected_track_index)
	t.visible_note_columns = math.max(phrase.visible_note_columns, t.visible_note_columns)
	t.visible_effect_columns = math.max(phrase.visible_effect_columns, t.visible_effect_columns)
	t.panning_column_visible = phrase.panning_column_visible or t.panning_column_visible
	t.delay_column_visible = phrase.delay_column_visible or t.delay_column_visible
	t.volume_column_visible = phrase.volume_column_visible or t.volume_column_visible

	local pt = song.selected_pattern:track(song.selected_track_index)
	pt:clear()
	for i = 1, math.min(phrase.number_of_lines, song.selected_pattern.number_of_lines) do
		local l = phrase:line(i)
		local pl = pt:line(i)
		for n = 1, phrase.visible_note_columns do
			local from = l:note_column(n)
			local to = pl:note_column(n)
			map_note_column(song, from, to)
		end
	end
end

---@type table<RendererType, Renderer>
local renderers = {
	["cycle"] = {
		render = generate_cycle_script,
		copy = copy_note_column,
	},
	["raw"] = {
		render = function(_, text)
			return { text }
		end,
		copy = copy_note_column,
	},
	-- ["mapped"] = {
	--   render = function(song, text)
	--     local cycle = generate_cycle_script(song, text)
	--     local mapping = ""
	--     return cycle..mapping
	--   end,
	--   copy = function(song, from, to)
	--   end
	-- }
}

---@type fun(song: renoise.Song, paragraphs: string[], map_note_column: NoteColumnMapper, force: boolean, callback: RenderingDoneCallback):string?
local function render_to_pattern(song, paragraphs, map_note_column, copy, callback)
	local i = #song.instruments + 1
	local cleanup = function()
		song:delete_instrument_at(#song.instruments)
	end
	local instrument = song:insert_instrument_at(i)
	local phrase = instrument:insert_phrase_at(1)
	phrase.playback_mode = renoise.InstrumentPhrase.PLAY_SCRIPT
	local script = phrase.script
	script.paragraphs = paragraphs
	script:commit()

	if script.compile_error ~= "" then
		cleanup()
		callback(script.compile_error, 0, 0)
	else
		---@type RenderingDoneCallback
		local rendering_done_callback = function(error, events, skipped)
			if error then
				cleanup()
				callback(error, 0, 0)
			else
				if song.selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
					if copy then
						copy_phrase_to_pattern(song, phrase, map_note_column)
					end
					cleanup()
					callback(nil, events, skipped)
				else
					cleanup()
					callback("Can only render script to a sequencer track!", 0, 0)
				end
			end
		end
		script:render_to_pattern(rendering_done_callback)
	end
end

---@type fun(max: integer, start: integer, dir: integer, test: (fun(i: integer): boolean)?, index: integer?): integer
local function next_index(max, start, dir, test, index)
	if index == nil then
		index = start
	end
	if test == nil then
		test = function(_)
			return true
		end
	end

	index = index + dir
	if index == 0 then
		index = max
	elseif index > max then
		index = 1
	end
	if index == start then
		return index
	end
	if test(index) then
		return index
	else
		return next_index(max, start, dir, test, index)
	end
end

---@type fun(song: renoise.Song)
local function clear_track(song)
	song.selected_pattern:track(song.selected_track_index):clear()
end

---@type fun(song: renoise.Song, dialog: Dialog): string
local function get_header(song, dialog)
	return (song.selected_pattern_index - 1)
			.. " | "
			.. song.selected_track.name
			.. " | #"
			.. song.selected_instrument_index - 1
			.. (dialog.transpose_octave.value and " | " .. song.transport.octave - 4 or "")
end

---@type fun(index: integer): boolean
local function is_sequencer(index)
	local song = renoise.song()
	if song == nil then
		return false
	end
	return song:track(index).type == renoise.Track.TRACK_TYPE_SEQUENCER
end

---@type fun(shortcuts: table<string, string[]>): renoise.Views.Stack
local function map_keys(shortcuts)
	local vb = renoise.ViewBuilder()
	local keys = {}
	local actions = {}
	for _, v in ipairs(shortcuts) do
		table.insert(
			keys,
			vb:button({
				text = v[1],
				font = "mono",
			})
		)
		table.insert(
			actions,
			vb:text({
				font = "mono",
				text = " " .. v[2],
			})
		)
	end
	return vb:row({
		margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
		size = {
			width = "100%",
		},
		views = {
			vb:column({
				size = {
					width = "30%",
				},
				views = keys,
			}),
			vb:column({
				size = {
					width = "70%",
				},
				views = actions,
			}),
		},
	})
end

---@type string?
local text_buffer = nil
---@type boolean
local is_rendering = false
---@type integer
local text_manually_updated = 0

---@type fun(song: renoise.Song, dialog: Dialog, text: string, force: boolean?)
local function render(song, dialog, text, force)
	if is_rendering then
		text_buffer = text
		return
	end
	if text == "" then
		dialog.show_error("")
		save_script(
			song,
			song.selected_pattern_index,
			song.selected_track_index,
			dialog.renderer_type.value,
			"",
			dialog.transpose_octave.value
		)
		return clear_track(song)
	end

	local renderer = renderers[RendererType.from_integer(dialog.renderer_type.value)]
	local script = renderer.render(song, text)

	is_rendering = true
	render_to_pattern(song, script, renderer.copy, prefs.autorender.value or force, function(error, _, skipped)
		is_rendering = false
		if text_buffer then
			local buffered_text = text_buffer
			text_buffer = nil
			render(song, dialog, buffered_text, force)
		else
			if error then
				dialog.show_error(error)
			else
				if skipped > 0 then
					dialog.show_error("Skipped rendering " .. skipped .. " events due to not enough LPB resolution.")
				else
					save_script(
						song,
						song.selected_pattern_index,
						song.selected_track_index,
						dialog.renderer_type.value,
						dialog.input.text,
						dialog.transpose_octave.value
					)
					dialog.show_error("")
				end
			end
		end
	end)
end

---@type fun(song: renoise.Song, dialog: Dialog)
local change_instrument_data = function(song, dialog)
	local t = state:pattern_track(song, song.selected_pattern_index, song.selected_track_index)
	t.instrument.value = song.selected_instrument_index
	dialog.header.text = get_header(song, dialog)
end

---@type fun(song: renoise.Song, dialog: Dialog)
local function load_track_data(song, dialog)
	if not is_sequencer(song.selected_track_index) then
		dialog.input.visible = false
		dialog.show_error("Only sequencer pattern tracks can be scripted")
		return
	elseif dialog == nil then
		return
	else
		dialog.input.visible = true
		dialog.show_error("")
	end
	local t = state:pattern_track(song, song.selected_pattern_index, song.selected_track_index)
	text_manually_updated = 2
	dialog.input.text = t.script.value
	dialog.renderer_type.value = RendererType.to_integer(t.renderer_type.value)
	local i = t.instrument.value
	if i > 0 then
		song.selected_instrument_index = i
	end
	dialog.header.text = get_header(song, dialog)
	dialog.header.color = song.selected_track.color
end

---@type fun(song: renoise.Song, dialog: Dialog): KeyHandlerMemberFunction
local function key_handler(song, dialog)
	return function(_, e)
		if dialog then
			local k = e.name
			if k == "return" then
				dialog.input.edit_mode = true
			elseif k == "esc" then
				dialog.close()
			elseif k == "right" or k == "l" then
				song.selected_track_index = next_index(#song.tracks, song.selected_track_index, 1, function(i)
					return song:track(i).type == renoise.Track.TRACK_TYPE_SEQUENCER
				end)
			elseif k == "left" or k == "h" then
				song.selected_track_index = next_index(#song.tracks, song.selected_track_index, -1, function(i)
					return song:track(i).type == renoise.Track.TRACK_TYPE_SEQUENCER
				end)
			elseif k == "down" or k == "j" then
				if e.modifier_flags.alt then
					song.selected_sequence_index =
							next_index(#song.sequencer.pattern_sequence, song.selected_sequence_index, 1)
				else
					song.selected_instrument_index = next_index(#song.instruments, song.selected_instrument_index, 1)
				end
			elseif k == "up" or k == "k" then
				if e.modifier_flags.alt then
					song.selected_sequence_index =
							next_index(#song.sequencer.pattern_sequence, song.selected_sequence_index, -1)
				else
					song.selected_instrument_index = next_index(#song.instruments, song.selected_instrument_index, -1)
				end
			else
				return e
			end
			-- rprint(e)
		end
	end
end

---@class Dialog
---@field dialog renoise.Dialog
---@field header renoise.Views.Button
---@field input renoise.Views.MultiLineTextField
---@field errors renoise.Views.MultiLineText
---@field select_help renoise.Views.Rack
---@field edit_help renoise.Views.Rack
---@field transpose_octave renoise.Views.CheckBox
---@field show_error fun(s:string)
---@field renderer_type renoise.Views.Switch
---@field close function

---@type fun(song: renoise.Song): Dialog
local function create_dialog(song)
	local vb = renoise.ViewBuilder()
	local width = 300
	local margin = 0

	local select_help = map_keys(help.select)
	local edit_help = map_keys(help.edit)

	local help_text = vb:column({
		size = {
			width = "100%",
		},
		select_help,
		edit_help,
	})

	local errors = vb:multiline_text({
		cursor = "edit_text",
		size = {
			width = "100%",
			height = 200,
		},
		text = "",
		font = "mono",
		style = "border",
		visible = false,
	})

	select_help.visible = false

	local header = vb:button({
		color = song.selected_track.color,
		size = {
			width = "100%",
		},
		font = "mono",
		active = true,
		text = ""
	})

	local renderer_type = vb:switch({
		size = {
			width = "100%",
		},
		items = RendererType.keys(),
		value = RendererType.to_integer(
			state:pattern_track(song, song.selected_pattern_index, song.selected_track_index).renderer_type.value
		),
		tooltip =
		"* 'cycle' mode lets you write only the string part for a cycle expression\n    like 'return cycle(\"ONLY_THIS\")'\n* 'raw' mode simply uses the text as a complete lua phrase script",
	})

	local transpose_octave = vb:checkbox {

	}

	local input = vb:multiline_textfield({
		edit_mode = true,
		cursor = "edit_text",
		size = {
			width = "100%",
			height = 100,
		},
		text = state:pattern_track(song, song.selected_pattern_index, song.selected_track_index).script.value,
		font = "mono",
		style = "border",
		notifier = function(_) end,
	})

	local view = vb:column({
		size = {
			width = width,
		},
		margin = margin,
		header,
		input,
		errors,
		renderer_type,
		transpose_octave,
		help_text,
	})

	local self = {
		header = header,
		errors = errors,
		input = input,
		edit_help = edit_help,
		select_help = select_help,
		renderer_type = renderer_type,
		transpose_octave = transpose_octave,
		show_error = function(text)
			errors.visible = text ~= ""
			errors.text = text
		end,
	}

	local dialog = renoise.app():show_custom_dialog(name, view, key_handler(song, self))

	self.input:add_notifier(function(text)
		if text_manually_updated > 0 then
			text_manually_updated = text_manually_updated - 1
		else
			render(song, self, text)
		end
	end)
	self.dialog = dialog
	self.header.text = get_header(song, self)
	return self
end

---@type Dialog
current_dialog = nil

local function open_dialog()
	local song = renoise.song()
	if song then
		if not is_sequencer(song.selected_track_index) then
			song.selected_track_index = next_index(#song.tracks, song.selected_track_index, 1, is_sequencer)
			if not is_sequencer(song.selected_track_index) then
				renoise.app():show_status("Cannot work on non-sequencer tracks.")
				return
			end
		end
		if state == nil then
			state = CyclerState.from_song(song)
			if song.tool_data then
				state:from_string(song.tool_data)
			end
		end

		if current_dialog then
			current_dialog.close()
			current_dialog = nil
		end

		local dialog = create_dialog(song)
		current_dialog = dialog

		local function track_changed()
			load_track_data(song, dialog)
		end
		local function instrument_changed()
			change_instrument_data(song, dialog)
			render(song, dialog, dialog.input.text)
			-- load_track_data(song, dialog)
		end
		local function pattern_changed()
			load_track_data(song, dialog)
		end

		local function add_notifier(observable, notifier)
			if not observable:has_notifier(notifier) then
				observable:add_notifier(notifier)
			end
		end

		local function remove_notifier(observable, notifier)
			if observable:has_notifier(notifier) then
				observable:remove_notifier(notifier)
			end
		end

		add_notifier(song.selected_track_index_observable, track_changed)
		add_notifier(song.selected_instrument_index_observable, instrument_changed)
		add_notifier(song.selected_pattern_index_observable, pattern_changed)

		local edit_mode = true
		local function update()
			if not dialog.dialog.visible then
				dialog.close()
				return
			end
			if dialog.input then
				if dialog.input.edit_mode ~= edit_mode then
					edit_mode = dialog.input.edit_mode
					dialog.select_help.visible = not edit_mode
					dialog.edit_help.visible = edit_mode
					dialog.input.style = edit_mode and "border" or "body"
					dialog.errors.style = edit_mode and "border" or "body"
					if not edit_mode then
						if not prefs.autorender.value then
							render(song, dialog, dialog.input.text, true)
						end
					end
				end
			end
		end

		if not tool:has_timer(update) then
			tool:add_timer(update, 100)
		end

		dialog.close = function()
			if tool:has_timer(update) then
				tool:remove_timer(update)
			end

			remove_notifier(song.selected_track_index_observable, track_changed)
			remove_notifier(song.selected_instrument_index_observable, instrument_changed)
			remove_notifier(song.selected_pattern_index_observable, pattern_changed)

			renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR

			if dialog.dialog.visible then
				dialog.dialog:close()
			end
		end
	end
end

local open_dialog_name = "Open " .. name .. " dialog"

renoise.tool():add_keybinding({
	name = "Pattern Editor:Tools:" .. open_dialog_name,
	invoke = function(repeated)
		if not repeated then
			open_dialog()
		end
	end,
})

renoise.tool():add_menu_entry({
	name = "Pattern Editor:" .. open_dialog_name,
	invoke = open_dialog,
})

_AUTO_RELOAD_DEBUG = function() end

print(name .. " loaded.")
