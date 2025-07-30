
-- Removes empty slots that has no sample data, loaded plugin or midi output

function instrument_is_empty(instrument)

  local inst, has_sample_data = renoise.song():instrument(instrument), false
  for _, sample in ipairs(inst.samples) do
    has_sample_data = has_sample_data or sample.sample_buffer.has_sample_data
  end
  if inst.name ~= "" or inst.plugin_properties.plugin_loaded or inst.midi_output_properties.device_name ~= "" or has_sample_data then return false else return true end

end


function remove_empty_slots()

  for instrument in ripairs(renoise.song().instruments) do
    if instrument_is_empty(instrument) and #renoise.song().instruments > 1 then
      renoise.song().delete_instrument_at(renoise.song(),instrument)
    end
  end

end

-- Sort instruments according to a remap table

function sort_instruments(new_mapping, status_text)

  renoise.app():show_status("Moving instruments...")
  table.sort(new_mapping, function(a, b) return a.original_position < b.original_position end)
  local doing_pos = 1
  while doing_pos < table.count(new_mapping) do
    while new_mapping[doing_pos].new_position == doing_pos and doing_pos < table.count(new_mapping) do
      doing_pos = doing_pos + 1
    end
    renoise.song().swap_instruments_at(renoise.song(), doing_pos, new_mapping[doing_pos].new_position)
    new_mapping[doing_pos], new_mapping[new_mapping[doing_pos].new_position] = new_mapping[new_mapping[doing_pos].new_position], new_mapping[doing_pos]
  end
  renoise.app():show_status("Sorted the instrument list by " .. status_text .. ".")

end

-- Returns a remap table according to alphabetically sorted instrument names

function map_alphabetic()

  local map_table = { }
  for i, instrument in ipairs(renoise.song().instruments) do table.insert(map_table, { name = instrument.name, original_position = i }) end
  table.sort(map_table, function(a, b)
    if a.name == b.name then return a.original_position < b.original_position
    else return string.upper(a.name) < string.upper(b.name) end
  end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to reversed order of instruments

function map_reverse()

  local map_table = { }
  for _, instrument in ipairs(renoise.song().instruments) do
    table.insert(map_table, 1, { name = instrument.name, original_position = _ })
  end
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to the total sample size in an instrument

function size_of_instrument(instrument)

  local bitsize = 0
  for _, sample in ipairs(renoise.song():instrument(instrument).samples) do
    if sample.sample_buffer.has_sample_data then
      bitsize = bitsize + sample.sample_buffer.bit_depth * sample.sample_buffer.number_of_frames * sample.sample_buffer.number_of_channels
    end
  end
  return bitsize

end

function map_size()

  local map_table = { }
  for _, instrument in ipairs(renoise.song().instruments) do
    table.insert(map_table, { name = instrument.name, original_position = _, size = size_of_instrument(_) })
  end
  table.sort(map_table, function(b, a)
    if a.size == b.size then return a.original_position < b.original_position
    else return a.size > b.size
    end
  end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to the order of an instruments appearance in the song (scanned vertically)

function map_order_vertical()

  local first_hit, note_cell, map_table, scanned_patterns = { }, 0, { }, { }
  for _, instrument in ipairs(renoise.song().instruments) do table.insert(map_table, { name = instrument.name, original_position = _ }) end
  renoise.app():show_status("Scanning song...")
  for sequence, pattern_index in ipairs(renoise.song().sequencer.pattern_sequence) do
    if scanned_patterns[pattern_index] then else
      scanned_patterns[pattern_index] = true
      local pattern = renoise.song():pattern(pattern_index)
      for line = 1, pattern.number_of_lines do
        for track = 1, renoise.song().sequencer_track_count do
          if not pattern:track(track).is_empty then
            if not pattern:track(track):line(line).is_empty then
              for note_column = 1, renoise.song():track(track).visible_note_columns do
                note_cell = note_cell + 1
                local n_column = pattern:track(track):line(line):note_column(note_column)
                if not n_column.is_empty then
                  if map_table[n_column.instrument_value+1] then
                    if map_table[n_column.instrument_value+1].note_cell then
                      map_table[n_column.instrument_value+1].note_cell = math.min(note_cell, map_table[n_column.instrument_value+1].note_cell)
                  else
                    map_table[n_column.instrument_value+1].note_cell = note_cell
                  end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  for pos in ipairs(map_table) do
    if not map_table[pos].note_cell then map_table[pos].note_cell = math.huge end
  end
  table.sort(map_table, function(a, b)
    if a.note_cell == b.note_cell then return a.original_position < b.original_position
    else return a.note_cell < b.note_cell end
  end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to the order of an instruments appearance in the song (scanned horizontally)

function map_order_horizontal()

  local first_hit, hit_order, map_table, scanned_patterns = { }, 0, { }, { }
  for _, instrument in ipairs(renoise.song().instruments) do table.insert(map_table, { name = instrument.name, original_position = _, first_hit = math.huge }) end
  renoise.app():show_status("Scanning song...")
  for track_index = 1, renoise.song().sequencer_track_count do
    for seq, pattern_index in ipairs(renoise.song().sequencer.pattern_sequence) do
      if scanned_patterns[pattern_index] then else
        scanned_patterns[pattern_index] = true
        local track = renoise.song():pattern(pattern_index):track(track_index)
        if not track.is_empty and renoise.song():track(track_index).type == renoise.Track.TRACK_TYPE_SEQUENCER then
          for line_index, line in ipairs(track.lines) do
            if not line.is_empty then
              for note_column_index = 1, renoise.song():track(track_index).visible_note_columns do
                local val = line:note_column(note_column_index)
                if not val.is_empty then
                  if val.instrument_value ~= 255 then
                    if map_table[val.instrument_value+1] then
                      if map_table[val.instrument_value+1].first_hit > hit_order then
                        hit_order = hit_order + 1
                        map_table[val.instrument_value+1].first_hit = hit_order
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  table.sort(map_table, function(a, b)
    if a.first_hit == b.first_hit then return a.original_position < b.original_position
    else return a.first_hit < b.first_hit end
  end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to a randomized order of instruments

function map_randomize()

  local map_table = { }
  for _, instrument in ipairs(renoise.song().instruments) do table.insert(map_table, { name = instrument.name, original_position = _, random = math.random() }) end
  table.sort(map_table, function(a, b) return a.random < b.random end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Returns a remap table according to the number of times instruments are used in the song

function map_most_used()

  local map_table = { }
  for _, instrument in ipairs(renoise.song().instruments) do table.insert(map_table, { name = instrument.name, original_position = _, population = 0 }) end
  renoise.app():show_status("Scanning song...")
  for seq, pattern_index in ipairs(renoise.song().sequencer.pattern_sequence) do
    for track_index = 1, renoise.song().sequencer_track_count do
      local track = renoise.song():pattern(pattern_index):track(track_index)
      if not track.is_empty and renoise.song():track(track_index).type == renoise.Track.TRACK_TYPE_SEQUENCER then
        for line_index, line in ipairs(track.lines) do
          if not line.is_empty then
            for note_column_index = 1, renoise.song():track(track_index).visible_note_columns do
              local val = line:note_column(note_column_index)
              if not val.is_empty then
                if val.instrument_value ~= 255 and map_table[val.instrument_value+1] then
                  map_table[val.instrument_value + 1].population = map_table[val.instrument_value + 1].population + 1
                end
              end
            end
          end
        end
      end
    end
  end
  table.sort(map_table, function(a, b)
    if a.population == b.population then return a.original_position < b.original_position
    else return a.population > b.population end
  end)
  for instrument = 1, #map_table do
    map_table[instrument].new_position = instrument
  end
  return map_table

end

-- Menu entries

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Name",
  invoke = function() sort_instruments(map_alphabetic(), "name") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Size",
  invoke = function() sort_instruments(map_size(), "total sample size") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Most Used",
  invoke = function() sort_instruments(map_most_used(), "usage in song") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Order In Song (Horizontal)",
  invoke = function() sort_instruments(map_order_horizontal(), "order in song (horizontal)") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Order In Song (Vertical)",
  invoke = function() sort_instruments(map_order_vertical(), "order in song (vertical)") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Randomize",
  invoke = function() sort_instruments(map_randomize(), "random order") end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Sort Instruments...:Reverse",
  invoke = function() sort_instruments(map_reverse(), "reversed order") end
}

renoise.tool():add_menu_entry {
  name = "---Instrument Box:Sort Instruments...:Delete Empty Instruments",
  invoke = function() remove_empty_slots() end
}

