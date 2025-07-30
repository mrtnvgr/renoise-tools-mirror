--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Pattern meta storage in instruments code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function pattern_to_sample(seq_index, track_index)
  -- Parses the selected sequence and track and makes a note array which is
  -- stored in the correct instrument as a blank sample
  
  --
  -- Initialise variables
  --
  local rs = renoise.song()
  local song_lines_per_4lpb_line = rs.transport.lpb / 4
  local pattern = rs.patterns[rs.sequencer.pattern_sequence[seq_index]]
  local pattern_track = pattern.tracks[track_index]
  local note_col_count = rs.tracks[track_index].visible_note_columns
  local instrument_index = 255      -- zero indexed as it is read from the pattern editor
  local note_table = {}

  -- Abort on empty track
  if pattern_track.is_empty then
    renoise.app():show_message("Aborting storing pattern track as selected pattern track is empty")
    return
  end
  
  --
  -- Build the table of notes
  --
  for line = 1, pattern.number_of_lines do
    for note_col = 1, note_col_count do
      local nc = pattern_track:line(line):note_column(note_col)
      
      -- Cache the instrument if it's the first instrument found
      if (nc.instrument_value ~= instrument_index) and (instrument_index == 255) then
        instrument_index = nc.instrument_value
      end
      
      -- Read the notes and build a table in the song LPB
      if not note_table[math.floor(line/song_lines_per_4lpb_line)] then           -- removed 1+
        table.insert(note_table, math.floor(line/song_lines_per_4lpb_line), {})   --  as above
      end

      -- Correct instrument?
      if nc.instrument_value == instrument_index then
      
        -- Store this note columns data if note is not empty
        if nc.note_value ~= renoise.PatternTrackLine.EMPTY_NOTE then
          if #note_table[math.floor(line/song_lines_per_4lpb_line)] < 4 then    -- remopve +1
            table.insert(note_table[math.floor(line/song_lines_per_4lpb_line)], note_col, {nc.note_value, nc.volume_value, nc.delay_value})     -- remove +1
          end
        end
      end
    end
  end
  
  --
  --  Normalise note tables
  --
  
  rprint(note_table)
  
  -- Current entries will be table[line][note_col], but note_col may not be 1, so fill up to that column with empty notes
  for line = 1, #note_table do
    if table.count(note_table[line]) > 0 then
      -- this line has notes
        if not note_table[line][1] then
          table.insert(note_table[line], 1, {renoise.PatternTrackLine.EMPTY_NOTE, 255, 0})
        end
        
        if not note_table[line][2] then
          table.insert(note_table[line], 2, {renoise.PatternTrackLine.EMPTY_NOTE, 255, 0})
        end    
        
        if not note_table[line][3] then
          table.insert(note_table[line], 3, {renoise.PatternTrackLine.EMPTY_NOTE, 255, 0})
        end   
    end
  end
  
  --
  -- Generate the string version
  --
  local str = notetable2string(pattern.name, note_table)
  
  --
  -- Add empty sample to end of instrument and tiny sample mapping so it's visible to Cells!
  --
  if #rs.instruments[instrument_index+1].samples > 254 then
    renoise.app():show_error(string.format("No sample slots available in instrument %d", instrument_index))
    return
  end
  
  local inst = rs.instruments[instrument_index+1]
  
  -- sample
  local samp = inst:insert_sample_at(#inst.samples + 1)
  samp.sample_buffer:create_sample_data(44100, 16, 1, 1) -- dummy data so sample name is visible
  samp.beat_sync_lines = math.floor(pattern.number_of_lines/song_lines_per_4lpb_line)
  
  -- sample mapping
  inst:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                             #inst.samples,
                             0,
                             {0, 0},
                             {127, 127})
  
  -- store string version of note table
  samp.name = str
end


function notetable2string(pattern_name, note_table)
  -- Convert a table of notes to a string suitable for storing as metadata
  
  --[[
    NT1:
    Name:
    Number of lines:
      NoteCount
        Note
        Volume
        Delay
  
  ]]--
  
  local note_string = string.format("NT1:%s:%d:", pattern_name, #note_table)   -- header, name & length
  
  for i = 1, #note_table do
    -- create string version of each line of data
    
    note_string = note_string .. string.format("%d:", #note_table[i]) -- number of notes
    
    for j = 1, #note_table[i] do
      note_string = note_string .. string.format("%d:%d:%d:", note_table[i][j][1],  -- note
                                                             note_table[i][j][2],  -- vol
                                                             note_table[i][j][3])  -- delay
    end
  end
  
  return note_string
end


function notestring2table(string)
  -- Convert a note string into a note table (inverse of notetable2string)
  
  -- returns note_table[]
  
  local settings_table = string_split(string, ":")
  local note_table = {}
  local i
  local line = 0
  
  -- invalid header
  if settings_table[1] ~= "NT1" then
    return {}
  end

  -- add tables for lines
  for i = 1, settings_table[3] do
    table.insert(note_table, {})
  end
  
  --
  -- parse and add notes
  --
  
  i = 4     -- start of first section
  line = 0  -- incremented on each interation
  
  while i < #settings_table do
  
    line = line + 1
      
    if tonumber(settings_table[i]) > 0 then
      -- we have notes on this line
      
      for n = 0, (tonumber(settings_table[i])-1) do
        -- iterate over note columns
        
        table.insert(note_table[line], {tonumber(settings_table[i+(3*n)+1]),
                                        tonumber(settings_table[i+(3*n)+2]),
                                        tonumber(settings_table[i+(3*n)+3])})
      end
      
      -- move i pointer
      i = i + (tonumber(settings_table[i]) * 3) + 1
    else
      -- increment i pointer if no notes
      i = i + 1
    end 
  end

  -- return name of riff and note table
  return note_table
end


function notestring2name(string)
  -- Convert a note string into a note table (inverse of notetable2string)
  
  -- returns note_table[]
  
  local settings_table = string_split(string, ":")

  -- invalid header
  if settings_table[1] ~= "NT1" then
    return ""
  end

  -- return name
  return settings_table[2]
end
  

function string_split(string, deliminator)
  -- Why does Lua not have a built-in split function?
  -- Code taken from http://www.wellho.net/resources/ex.php4?item=u108/split
  local result = {}
  local from = 1
  local delim_from, delim_to = string.find(string, deliminator, from)
  while delim_from do
    table.insert(result, string.sub(string, from, delim_from-1))
    from = delim_to + 1
    delim_from, delim_to = string.find(string, deliminator, from)
  end
  table.insert(result, string.sub(string, from))
  return result
end



--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Cells!:Store pattern track as instrument note pattern",
  invoke = function()
    pattern_to_sample(renoise.song().selected_sequence_index, renoise.song().selected_track_index)
  end
}
