--------------------------------------------------------------------------------
-- Freeze Track Tool
--
-- Copyright 2011 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Inludes
--------------------------------------------------------------------------------
require "OneShotIdle"
require "gui"
require "prefs"


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
render_filenames = {}  -- {filename, rendered_flag}
track_index = nil
current_pattern = 1
--render_bitdepth = 24             -- default rendering settings
--render_samplerate = 48000
--render_priority = "high"
--render_interpolation = "cubic"
--render_delete_source = false
--render_pattern_based = true
--render_headroom_comp = 6


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function freeze_track()
  -- Freeze a track... ice ice baby
  -- Are we already rendering?
  if renoise.song().rendering then
    -- yes, abort
    renoise.app():show_status("Rendering in progress, track freezing not available.")
    return
  end

  track_index = renoise.song().selected_track_index
  local song = renoise.song()
  local track = song.tracks[track_index]
  local new_track_name = track.name .. " (FSrc)"
  render_filenames = {}
  current_pattern = 1
  
  -- Check track type
  if track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
    -- not a sequencer track, abort
    renoise.app():show_error("Track freezing not supported for send or master tracks.")
    return
  end
  
  -- We can only load 120 'notes' worth of patterns
  if #renoise.song().patterns > 119 then
    renoise.app():show_error("Sorry, track freezing currently only supports up to 120 patterns.")
    return
  end
  
  -- Don't do recursive freezing as it confused unfreezing
  if track.name:find("Frozen") then
    renoise.app():show_error("Freezing of already frozen tracks is currently not supported.")
    return
  end
  
  -- Check for existing frozen track:
  -- 1. Track name
  for i = 1, #renoise.song().tracks do
    if renoise.song().tracks[i].name == track.name .. " (Frozen)" then
      renoise.app():show_warning("Track '".. track.name ..
                                 "' already appears to be frozen as track " ..
                                 tostring(i) .. ".")
      return
    end
  end
  -- 2. Instrument name
    for i = 1, #renoise.song().instruments do
    if renoise.song().instruments[i].name == track.name .. " (Frozen)" then
      renoise.app():show_warning("Track '".. track.name ..
                                 "' already appears to be frozen as instrument " ..
                                 tostring(i-1) .. ".")
      return
    end
  end
  
  dialog_show()
  
  

end


function freeze_track_pat_launch()
  -- Start pattern based track freezing
  local song = renoise.song()
  local track = song.tracks[track_index]
  
  -- Create table of patterns to render
  for i = 1, #song.patterns do
    table.insert(render_filenames, {"", false})
  end
  
  -- Clear solos
  for i = 1,#song.tracks do
    song.tracks[i].solo_state = false
  end
  
  -- Solo track
  track:solo()
  
  -- Go, go, go!
  freeze_track_pat_pre()
end



function freeze_track_pat_pre()
  -- Render a single pattern (pattern based)
  local song = renoise.song()
  local track = song.tracks[track_index]
  local seq = song.sequencer.pattern_sequence
  local seq_slot = 0
  local seq_found = false
  
  renoise.app():show_status(string.format("Track freezing in progress (%d/%d).",
                                          current_pattern,
                                          #render_filenames))
  
  -- Find pattern in sequence
  for i = 1, #seq do
    if seq[i] == current_pattern then
      seq_slot = i
      seq_found = true
    end
  end
  
  if not seq_found then
    render_filenames[current_pattern][2] = false -- pattern ignored
    -- Pattern not in sequencer! - skip and ignore
    current_pattern = current_pattern + 1
    if current_pattern > #render_filenames then
      -- completed
      freeze_pat_complete()
      return
    end
    freeze_track_pat_pre() -- start again
    return -- dont continue when returning from nested calls
  end
  
  local s_pos = renoise.SongPos()
  local e_pos = renoise.SongPos()
  s_pos.sequence = seq_slot
  s_pos.line = 1
  e_pos.sequence = seq_slot
  e_pos.line = song.patterns[current_pattern].number_of_lines
  
  -- Render track to sample
  render_filenames[current_pattern][1] = os.tmpname("wav")
  render_filenames[current_pattern][2] = true
  
  -- Send panic (as per built in rendering)
  renoise.song().transport:panic()
  
  -- Start render
  renoise.song():render({start_pos = s_pos, end_pos = e_pos,
                         sample_rate = renoise.tool().preferences.samplerate.value,
                         bit_depth = renoise.tool().preferences.bitdepth.value,
                         interpolation = renoise.tool().preferences.interpolation.value,
                         priority = renoise.tool().preferences.priority.value},
                         render_filenames[current_pattern][1],
                         freeze_track_pat_post)
end


function freeze_track_pat_post()
  -- Call back function after rendering (pattern based)
  local song = renoise.song()
  local track = song.tracks[track_index]
  
  -- Set completed render flag
  render_filenames[current_pattern][2] = true
  
  -- Another pattern has been rendered
  current_pattern = current_pattern + 1
  
  if current_pattern > #render_filenames then
    -- Completed
    freeze_pat_complete()
  else
    -- Start the next one
    
    --freeze_track_pre() (Cannot nest renders in Renoise 2.7, work around it)
    OneShotIdleNotifier(0.0, freeze_track_pat_pre)
    return
  end
end


function freeze_pat_complete()
  -- Freeze rendering finished, tidy and insert sampels
  local song = renoise.song()
  local track = song.tracks[track_index]
  
  -- Notify user
  renoise.app():show_status("Loading frozen track patterns.")
  
  -- Create instrument to hold rendered patterns
  local inst = song:insert_instrument_at(#song.instruments+1) --last instrument
  inst:clear()
  inst.name = track.name .. " (Frozen)"
     
  -- Create sample slots
  for i = 1, #render_filenames do
    local samp = inst:insert_sample_at(#inst.samples)
  end
    
  -- Load samples & set autoseek
  for i = 1, #render_filenames do
    if render_filenames[i][2] == true then
      inst.samples[i].sample_buffer:load_from(render_filenames[i][1])
      inst.samples[i].autoseek = true
      inst.samples[i].name = "Pattern " .. tostring(i)
      inst.samples[i].volume = math.db2lin(renoise.tool().preferences.headroom_comp.value) 
    end
  end

  -- Setup sample mapping
  for i = 1, #render_filenames do
    inst:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                               i, -- sample index
                               i-1, -- base note (start at lowest note to allow lots of patterns)
                               {i-1, i-1}, -- note span
                               {1, 127}) -- vel span
  end
  
  -- Unsolo old track
  track:solo()
  track:mute()
  
  -- change name
  local old_track_name = track.name
  track.name = track.name .. " (FSrc)"
  
  -- Add new track
  local new_track = song:insert_track_at(track_index+1)
  new_track.name = old_track_name .. " (Frozen)"
  
  -- Add notes to trigger samples
  for i = 1, #render_filenames do
    if render_filenames[i][2] then
      -- add note if pattern was rendered
      local note_col = song.patterns[i].tracks[track_index+1].lines[1].note_columns[1]
      note_col.note_value = i-1 -- start from C4 upwards
      note_col.instrument_value = #song.instruments-1 --last instrument (start @0)
    end
  end
  
  -- Delete source?
  if renoise.tool().preferences.delete_source.value then
    renoise.song():delete_track_at(track_index)
  end
  

  -- Report back to user
  renoise.app():show_status("Track freezing complete.")
end


function freeze_track_lin_launch()

  -- Start pattern based track freezing
  local song = renoise.song()
  local track = song.tracks[track_index]
  local seq = song.sequencer.pattern_sequence

  -- Check for duplication of first pattern
  local first_pattern = seq[1]
  local duplicate_pattern = false
  
  if #seq > 1 then
    for i = 2, #seq do
      if seq[i] == first_pattern then
        duplicate_pattern = true
      end
    end
  end
  
  if duplicate_pattern then
    -- abort
    renoise.app():show_warning("The frozen track will be played from the first "..
                               "pattern (".. tostring(first_pattern-1).. "), "..
                               "however,this pattern is reused later in the "..
                               "song.\nPlease make the first pattern unique "..
                               "before linear track freezing.")
    return
  end

  
  -- Clear solos
  for i = 1,#song.tracks do
    song.tracks[i].solo_state = false
  end
  
  -- Solo track
  track:solo()
  
  -- Go, go, go!
  freeze_track_lin_pre()
end


function freeze_track_lin_pre()
  -- Render a single pattern (pattern based)
  local song = renoise.song()
  local track = song.tracks[track_index]
  local seq = song.sequencer.pattern_sequence
  local seq_len = #seq
  local last_pattern = seq[seq_len]
  local last_pattern_len = song.patterns[last_pattern].number_of_lines
  
  renoise.app():show_status("Track freezing in progress (linear).")
  
  local s_pos = renoise.SongPos()
  local e_pos = renoise.SongPos()
  s_pos.sequence = 1
  s_pos.line = 1
  e_pos.sequence = seq_len
  e_pos.line = last_pattern_len
  
  -- Render track to sample
  table.insert(render_filenames, os.tmpname("wav"))
  
  -- Send panic (as per built in rendering)
  renoise.song().transport:panic()
  
  -- Start render
  renoise.song():render({start_pos = s_pos, end_pos = e_pos,
                         sample_rate = renoise.tool().preferences.samplerate.value,
                         bit_depth = renoise.tool().preferences.bitdepth.value,
                         interpolation = renoise.tool().preferences.interpolation.value,
                         priority = renoise.tool().preferences.priority.value},
                         render_filenames[1],
                         freeze_track_lin_complete)
end


function freeze_track_lin_complete()
  -- Freeze rendering finished, tidy and insert sampels
  local song = renoise.song()
  local track = song.tracks[track_index]
  
  -- Notify user
  renoise.app():show_status("Loading frozen track sample.")
  
  -- Create instrument to hold rendered patterns
  local inst = song:insert_instrument_at(#song.instruments+1) --last instrument
  inst:clear()
  inst.name = track.name .. " (Frozen)"
   
  -- Load sample
  inst.samples[1].sample_buffer:load_from(render_filenames[1])
  inst.samples[1].autoseek = true
  inst.samples[1].name = "Frozen track (linear)"
  inst.samples[1].volume = math.db2lin(renoise.tool().preferences.headroom_comp.value)
  
  -- Unsolo old track
  track:solo()
  track:mute()
  
  -- change name
  local old_track_name = track.name
  track.name = track.name .. " (FSrc)"
  
  -- Add new track
  local new_track = song:insert_track_at(track_index+1)
  new_track.name = old_track_name .. " (Frozen)"
  
  -- Add notes to trigger samples  (C4 for linear rendering)
  local first_pattern = song.sequencer.pattern_sequence[1]
  local note_col = song.patterns[first_pattern].tracks[track_index+1].lines[1].note_columns[1]
  note_col.note_value = 48 -- C4
  note_col.instrument_value = #song.instruments-1 --last instrument (start @0)
  
  -- Delete source?
  if renoise.tool().preferences.delete_source.value then
    renoise.song():delete_track_at(track_index)
  end

  -- Report back to user
  renoise.app():show_status("Track freezing complete.")
end


function unfreeze_track()
  -- Unfreeze a frozen track
  
  -- Are we already rendering?
  if renoise.song().rendering then
    -- yes, abort
    renoise.app():show_status("Rendering in progress, track unfreezing not available.")
    return
  end
  
  local song = renoise.song()
  local track = song.selected_track
  local frozen_track_id = song.selected_track_index
  local is_track_frozen = false
  local found_inst = false
  local original_track_name = ""
  local original_track_id = -1
  
  -- Is it frozen?
  if track.name:find("Frozen") then
    is_track_frozen = true
  end
  
  -- Is it a 'source track' that has been frozen?  (this code by dblue - Thanks!)
  
  -- If we're not on a frozen track, then perhaps the user 
  -- has tried to unfreeze the original track instead?
  -- Let's do a quick search to see if we can find a 
  -- frozen track that matches the current track.  
  if (not is_track_frozen) then
    local track_name_frozen = track.name .. " (Frozen)"
    -- Iterate through tracks
    for i, t in ipairs(song.tracks) do
      -- Only check valid sequencer tracks
      if (t.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
        if (t.name == track_name_frozen) then
          -- We seem to have found the frozen track. Break out of the loop.
          is_track_frozen = true
          frozen_track_id = i
          track = song.tracks[i]
          break
        end
      end
    end
  end

  
  if not is_track_frozen then
    renoise.app():show_error("Cannot identify this track as frozen.\n" ..
                             "Please unfreeze from the frozen track not the original.\n" ..
                             "Alternatively, have you removed the '(Frozen)' tag from the frozen track name?")
    return
  end
  
  -- Check for instrument
  for i = 1, #song.instruments do
    if song.instruments[i].name == track.name then
      if found_inst then
        -- found multiple choices!
        renoise.app():show_error("Found multiple instruments that could be the frozen track.  Aborting.")
        return
      else
        found_inst = i
      end
    end
  end
  
  if not found_inst then
    renoise.app():show_error("Cannot identify this track as frozen.\nHave you removed the '(Frozen)' tag from the instrument name?")
    return
  end
  
  -- Check for original track
  original_track_name = track.name:sub(1, -10) -- strip " (Frozen)"
  
  for i = 1, #song.tracks do
    if song.tracks[i].name == original_track_name .. " (FSrc)" then
      if original_track_id == -1 then
        original_track_id = i
      else
        renoise.app():show_error("Found multiple tracks that could be the original track.  Aborting.")
        return
      end
    end
  end
  
  if original_track_id == -1 then
    renoise.app():show_error("Could not find the original track.  Aborting.")
    return
  end
  
  -- Unmute original
  song.tracks[original_track_id].mute_state = renoise.Track.MUTE_STATE_ACTIVE
  
  -- Delete instrument
  song:delete_instrument_at(found_inst)
  
  -- Delete frozen track
  song:delete_track_at(frozen_track_id)
  
  -- Remove FSrc tag
  song.tracks[original_track_id].name = song.tracks[original_track_id].name:sub(1, -8)
end  


--------------------------------------------------------------------------------
-- Keyboard Mappings
--------------------------------------------------------------------------------
renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Freeze",
  invoke = function ()
    freeze_track()
  end
}


renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Unfreeze",
  invoke = function ()
    unfreeze_track()
  end
}


--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Edit:Freeze Track",
  invoke = function()
    freeze_track()
  end
}


renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Freeze Track",
  invoke = function()
    freeze_track()
  end
}


renoise.tool():add_menu_entry {
  name = "Main Menu:Edit:Unfreeze Track",
  invoke = function()
    unfreeze_track()
  end
}


renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Unfreeze Track",
  invoke = function()
    unfreeze_track()
  end
}


--------------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------------
init_prefs()
