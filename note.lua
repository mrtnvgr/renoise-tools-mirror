local Object = require 'classic'
local util = require 'util'

local Note = Object:extend()

function Note:new(song, pos, col)
	self.song = song
	self.pattern = song:pattern(pos.pattern)
	self.track = pos.track
	self.column = pos.column
	self.start = col and {
		value = col.note_value,
		instrument = col.instrument_value,
		volume = col.volume_value,
		pan = col.panning_value,
		time = util.to_time(pos.line, col.delay_value),
	} or {
		value = renoise.PatternLine.EMPTY_NOTE,
		instrument = renoise.PatternLine.EMPTY_INSTRUMENT,
		volume = renoise.PatternLine.EMPTY_VOLUME,
		pan = renoise.PatternLine.EMPTY_PANNING,
		time = -1,
	}
end

function Note:is_on(track, column)
	return self.track == track and self.column == column
end

function Note:get_pattern_length()
	return self.pattern.number_of_lines * 255 - 1
end

function Note:get_finish()
	return self.finish
end

-- Returns whether two notes overlap.
function Note:collides_with(other)
	if self.column ~= other.column then return false end
	local self_start_line = util.from_time(self.start.time)
	local self_finish_line = util.from_time(self.finish and self.finish.time or self:get_pattern_length())
	local other_start_line = util.from_time(other.start.time)
	local other_finish_line = util.from_time(other.finish and other.finish.time or other:get_pattern_length())
	if self_start_line < other_finish_line and other_start_line < self_finish_line then
		return true
	end
end

-- Returns if the note overlaps with any other notes in the list.
function Note:has_collisions(notes)
	for _, other in ipairs(notes) do
		if other == self then return false end
		if self:collides_with(other) then
			return true
		end
	end
	return false
end

-- Shifts the note forward one or more columns to avoid collisions.
function Note:resolve_collisions(notes)
	while self.column < 12 and self:has_collisions(notes) do
		self.column = self.column + 1
		local track = self.song:track(self.track)
		track.visible_note_columns = math.max(track.visible_note_columns, self.column)
	end
end

function Note:set_finish(pos, col)
	self.finish = {
		instrument = col.instrument_value,
		volume = col.volume_value,
		pan = col.panning_value,
		time = util.to_time(pos.line, col.delay_value),
	}
	self.length = self.finish.time - self.start.time
end

function Note:nudge(ticks)
	if self.start.time ~= -1 then
		self.start.time = self.start.time + ticks
		self.start.time = math.min(self.start.time, self:get_pattern_length())
	end
	if self.finish then
		self.finish.time = self.finish.time + ticks
		self.finish.time = math.min(self.finish.time, self:get_pattern_length())
	end
end

function Note:quantize(amount, lines, swing, end_mode)
	assert(end_mode == 'no_change'
		or end_mode == 'quantize_end'
		or end_mode == 'preserve_length')
	if self.start.time == -1 and end_mode ~= 'quantize_end' then return end
	amount = amount or 1
	lines = lines or 1
	if self.start.time ~= -1 then
		self.start.time = util.quantize(self.start.time, amount, lines, swing)
		self.start.time = math.min(self.start.time, self:get_pattern_length())
	end
	if self.finish then
		if end_mode == 'quantize_end' then
			self.finish.time = util.quantize(self.finish.time, amount, lines, swing)
			self.finish.time = math.min(self.finish.time, self:get_pattern_length())
		elseif end_mode == 'preserve_length' then
			self.finish.time = util.lerp(self.finish.time, self.start.time + self.length, amount)
		end
	end
end

function Note:write()
	local pattern_track = self.pattern:track(self.track)
	local start_line, start_delay = util.from_time(self.start.time)
	if self.finish then
		local finish_line, finish_delay = util.from_time(self.finish.time)
		if self.start.time ~= -1 and finish_line == start_line then
			finish_line = finish_line + 1
			finish_delay = 0
		end
		local finish_col = pattern_track:line(finish_line):note_column(self.column)
		finish_col.note_value = renoise.PatternLine.NOTE_OFF
		finish_col.instrument_value = self.finish.instrument
		finish_col.volume_value = self.finish.volume
		finish_col.panning_value = self.finish.pan
		finish_col.delay_value = finish_delay
	end
	if self.start.time == -1 then return end
	local start_col = pattern_track:line(start_line):note_column(self.column)
	start_col.note_value = self.start.value
	start_col.instrument_value = self.start.instrument
	start_col.volume_value = self.start.volume
	start_col.panning_value = self.start.pan
	start_col.delay_value = start_delay
end

return Note
