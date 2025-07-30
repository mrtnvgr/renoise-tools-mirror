local Note = require 'note'

local iterator = {}

-- Iterate through all of the note data in a column.
local function column_iterator(song, pattern)
	local note_columns = {}
	for pos, col in song.pattern_iterator:note_columns_in_pattern_track(pattern, song.selected_track_index) do
		if pos.column == song.selected_note_column_index then
			table.insert(note_columns, {{
				pattern = pos.pattern,
				track = pos.track,
				line = pos.line,
				column = pos.column,
			}, col})
		end
	end
	local i = 0
	return function()
		i = i + 1
		if note_columns[i] then
			return unpack(note_columns[i])
		end
	end
end

-- Iterates through all of the note data in a selection.
local function selection_in_pattern_iterator(song, pattern)
	local note_columns = {}
	for pos, col in song.pattern_iterator:note_columns_in_pattern(pattern) do
		if col.is_selected then
			table.insert(note_columns, {{
				pattern = pos.pattern,
				track = pos.track,
				line = pos.line,
				column = pos.column,
			}, col})
		end
	end
	local i = 0
	return function()
		i = i + 1
		if note_columns[i] then
			return unpack(note_columns[i])
		end
	end
end

-- Returns the corresponding note data iterator for the specified scope.
local function get_iterator(song, pattern, scope)
	assert(scope == 'column'
		or scope == 'track'
		or scope == 'selection'
		or scope == 'all_tracks')
	if scope == 'column' then
		return column_iterator(song, pattern)
	elseif scope == 'track' then
		return song.pattern_iterator:note_columns_in_pattern_track(
			pattern,
			song.selected_track_index
		)
	elseif scope == 'selection' then
		return selection_in_pattern_iterator(song, pattern)
	elseif scope == 'all_tracks' then
		return song.pattern_iterator:note_columns_in_pattern(pattern)
	end
end

-- Detects all of the notes within a certain scope.
function iterator.get_notes(song, pattern, scope)
	local notes = {}
	for pos, col in get_iterator(song, pattern, scope) do
		if col.note_value ~= renoise.PatternLine.EMPTY_NOTE then
			local no_previous_note = true
			for _, note in ipairs(notes) do
				if not note:get_finish() and note:is_on(pos.track, pos.column) then
					note:set_finish(pos, col)
					no_previous_note = false
					break
				end
			end
			if col.note_value ~= renoise.PatternLine.NOTE_OFF then
				table.insert(notes, Note(song, pos, col))
			elseif no_previous_note then
				local note = Note(song, pos)
				note:set_finish(pos, col)
				table.insert(notes, note)
			end
		end
	end
	return notes
end

-- Clears all the note data in a certain scope.
function iterator.clear_columns(song, pattern, scope)
	for _, col in get_iterator(song, pattern, scope) do col:clear() end
end

return iterator
