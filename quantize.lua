local iterator = require 'iterator'

-- reads the notes in a pattern, clears the note data, and writes out quantized notes
local function quantize_pattern(song, pattern, scope, nudge, amount, lines, swing, end_mode)
	nudge = nudge or 0
	local notes = iterator.get_notes(song, pattern, scope)
	iterator.clear_columns(song, pattern, scope)
	for _, note in ipairs(notes) do
		note:nudge(nudge)
		note:quantize(amount, lines, swing, end_mode)
		note:resolve_collisions(notes)
		note:write()
	end
end

--[[
	Quantizes notes in the song.
	- scope: what section of the pattern to quantize
		- column - quantize notes in the current column
		- track - quantize notes in the current track
		- selection - quantize highlighted notes
		- all_tracks - quantize all the notes in the pattern
	- whole_song - whether to quantize notes in the whole song or just the current pattern
	- amount - how much to quantize the notes (0% = no effect, 100% = perfect timing)
	- lines - the resolution to quantize to
	- end_mode - how to quantize note endings
		- no_change - don't quantize note endings
		- quantize_end - quantize the end time of notes independent of their start time
		- preserve_length - shift the end time so the note retains its original length
]]
return function(scope, whole_song, nudge, amount, lines, swing, end_mode)
	assert(scope == 'column'
		or scope == 'track'
		or scope == 'selection'
		or scope == 'all_tracks')
	assert(end_mode == 'no_change'
		or end_mode == 'quantize_end'
		or end_mode == 'preserve_length')
	local song = renoise.song()
	song:describe_undo 'Partially Quantize Notes'
	if whole_song then
		for pattern_index, _ in ipairs(song.patterns) do
			quantize_pattern(song, pattern_index, scope, nudge, amount, lines, swing, end_mode)
		end
	else
		quantize_pattern(song, song.selected_pattern_index, scope, nudge, amount, lines, swing, end_mode)
	end
end
