--[[============================================================================
com.yinxs.ClearTrack.xrnx/main.lua
============================================================================]]--

-- Register Keybindings

renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Clear Track Below Cursor",
  invoke = function(repeated)
  	clear_track_below_cursor()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Column Operations:Clear Column Below Cursor",
  invoke = function(repeated)
  	clear_column_below_cursor()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Clear Track Above Cursor",
  invoke = function(repeated)
  	clear_track_above_cursor()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Column Operations:Clear Column Above Cursor",
  invoke = function(repeated)
  	clear_column_above_cursor()
  end
}


-- Track related functions

function clear_track_below_cursor()
  local start_line = renoise.song().transport.edit_pos.line
  local end_line = renoise.song().selected_pattern.number_of_lines
  clear_track(start_line, end_line)
end

function clear_track_above_cursor()
  local start_line = 1
  local end_line = renoise.song().transport.edit_pos.line - 1
  if (end_line >= 1) then
    clear_track(start_line, end_line)
  end
end


-- Column related functions

function clear_column_below_cursor()
  local start_line = renoise.song().transport.edit_pos.line
  local end_line = renoise.song().selected_pattern.number_of_lines
  clear_column(start_line, end_line)
end

function clear_column_above_cursor()
  local start_line = 1
  local end_line = renoise.song().transport.edit_pos.line - 1
  if (end_line >= 1) then
	  clear_column(start_line, end_line)
  end
end


-- Clearing functionality

function clear_track(start_line, end_line)
  local pattern_track = renoise.song().selected_pattern_track 
  for line_index = start_line, end_line do
    pattern_track:line(line_index):clear()    
  end
end

function clear_column(start_line, end_line)
  local pattern_track = renoise.song().selected_pattern_track 
  local note_column_index = renoise.song().selected_note_column_index
  for line_index = start_line, end_line do
  	local note_column = pattern_track:line(line_index).note_columns[note_column_index]
    note_column.note_value = renoise.PatternTrackLine.EMPTY_NOTE
    note_column.instrument_value = renoise.PatternTrackLine.EMPTY_INSTRUMENT
    note_column.volume_value = renoise.PatternTrackLine.EMPTY_VOLUME
    note_column.panning_value = renoise.PatternTrackLine.EMPTY_PANNING
    note_column.delay_value = renoise.PatternTrackLine.EMPTY_DELAY
  end
end
