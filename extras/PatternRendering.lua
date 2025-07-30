--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Pattern rendering code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
render_file = nil
render_sequence_index = nil
render_is_loop = false
render_beat_count = 1
render_track_index = nil


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function prepare_sample(sample_object, beat_count, is_loop)
  -- Setup a sample for Cells!
  
  if sample_object.is_slice_alias then
    return false
  end
  
  -- set loop mode
  if is_loop then
    sample_object.loop_start = 1
    sample_object.loop_end = sample_object.sample_buffer.number_of_frames
    sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
  else
    sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
  end
  
  -- set beat sync
  sample_object.beat_sync_lines = beat_count * 4
  sample_object.beat_sync_enabled = true
  
  -- set autoseek
  sample_object.autoseek = true
end


function render_pattern_to_sample(sequence_index, is_loop, track_index)
  -- Render the current pattern to a sample if possible
  local rs = renoise.song()
  
  -- already rendering?
  if rs.rendering then
    renoise.app():show_error("Rendering already in progress.")
    return
  end
  
  local pattern = rs.patterns[rs.sequencer.pattern_sequence[sequence_index]]
  local line_count = pattern.number_of_lines
  
  -- validate length
  if (line_count / rs.transport.lpb) * 4 > 512 then
    renoise.app():show_error("This pattern is too long be handled by Cells!")
    return
  end
  
  render_track_index = -1
  
  -- solo if can/required
  if track_index ~= -1 then
    -- ignore soloing on master track
    if rs.tracks[track_index].type ~= renoise.Track.TRACK_TYPE_MASTER then
    
      if rs.tracks[track_index].solo_state == false then
        renoise.song().tracks[track_index]:solo()
        render_track_index = track_index
      end
    end
  end
  
  -- establish rendering region
  local s_pos = renoise.SongPos()
  local e_pos = renoise.SongPos()
  s_pos.sequence = sequence_index
  s_pos.line = 1
  e_pos.sequence = sequence_index
  e_pos.line = line_count
  
  -- temporary file
  render_file = os.tmpname("wav")

  -- render as loop?
  render_is_loop = is_loop
  
  -- beat count
  render_beat_count = line_count / rs.transport.lpb
  
  -- sequence index
  render_sequence_index = sequence_index
  
  -- render
  rs:render({start_pos = s_pos, end_pos = e_pos,
             sample_rate = preferences.render_sample_rate.value,
             bit_depth = preferences.render_bit_depth.value,
             interpolation = preferences.render_interpolation.value,
             priority = preferences.render_priority.value},
            render_file, render_pattern_to_sample_callback)
end


function render_pattern_to_sample_callback()
  -- Callback from rendering routine
  
  local rs = renoise.song()
  local inst_index = -1
  
  -- unsolo if required
  if render_track_index ~= -1 then
    renoise.song().tracks[render_track_index]:solo()
  end
  
  -- search instruments for 'Cells! Unsorted Renders'
  for i = 1, #rs.instruments do
    if rs.instruments[i].name == "Cells! Unsorted Renders" then
      inst_index = i
    end
  end
  
  -- not found, add instrument
  if inst_index == -1 then
    inst_index = #renoise.song().instruments + 1
    rs:insert_instrument_at(inst_index)
    rs.instruments[inst_index].name = "Cells! Unsorted Renders"
  end
  
  -- inst_index is correct, add the sample
  if rs.instruments[inst_index].samples[1].sample_buffer.has_sample_data then
    rs.instruments[inst_index]:insert_sample_at(#rs.instruments[inst_index].samples+1)
  end
  
  -- load the file
  local samp = rs.instruments[inst_index].samples[#rs.instruments[inst_index].samples]
  samp.sample_buffer:load_from(render_file)
  
  -- assign sample settings
  local pattern = rs.patterns[rs.sequencer.pattern_sequence[1]]
  local track_name = ""
  
  if render_track_index ~= -1 then
    track_name = " [" .. rs.tracks[render_track_index].name .. "]"
  end
  
  if pattern.name ~= "" then
    samp.name = "Pattern: "..pattern.name..track_name
  else
    samp.name = string.format("Pattern: %d", rs.sequencer.pattern_sequence[1])..track_name
  end
  
  -- set loop mode
  if render_is_loop then
    samp.loop_start = 1
    samp.loop_end = samp.sample_buffer.number_of_frames
    samp.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
  else
    samp.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
  end
  
  -- set beat sync
  samp.beat_sync_lines = render_beat_count * 4 --4 lpb
  samp.beat_sync_enabled = true
  
  -- set autoseek
  samp.autoseek = true
  
  -- reset
  render_file = nil
  render_is_loop = nil
  render_beat_count = nil
end


--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Cells!:Render current pattern track as repitched loop",
  invoke = function()
    render_pattern_to_sample(renoise.song().selected_sequence_index, true, renoise.song().selected_track_index)
  end
}


renoise.tool():add_menu_entry {
  name = "Pattern Editor:Cells!:Render current pattern track as repitched one-shot",
  invoke = function()
    render_pattern_to_sample(renoise.song().selected_sequence_index, false, renoise.song().selected_track_index)
  end
}



renoise.tool():add_menu_entry {
  name = "Pattern Editor:Cells!:Render current pattern as repitched loop",
  invoke = function()
    render_pattern_to_sample(renoise.song().selected_sequence_index, true, -1)
  end
}


renoise.tool():add_menu_entry {
  name = "Pattern Editor:Cells!:Render current pattern as repitched one-shot",
  invoke = function()
    render_pattern_to_sample(renoise.song().selected_sequence_index, false, -1)
  end
}

