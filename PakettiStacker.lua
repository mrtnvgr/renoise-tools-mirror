local vb = renoise.ViewBuilder()


local dialog = nil
local dialog_content = nil


function returnpe()
    renoise.app().window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
end

-- Function to set loop mode for all samples in the selected instrument
function set_loop_mode_for_selected_instrument(loop_mode)
  local song=renoise.song()
  local instrument = song.selected_instrument

  if not instrument then
    renoise.app():show_status("No instrument selected.")
    return
  end

  local samples = instrument.samples
  local num_samples = #samples

  if num_samples < 1 then
    renoise.app():show_status("No samples in the selected instrument.")
    return
  end

  -- Create a lookup table for human-readable loop mode names
  local loop_mode_names = {
    [renoise.Sample.LOOP_MODE_OFF] = "Off",
    [renoise.Sample.LOOP_MODE_FORWARD] = "Forward",
    [renoise.Sample.LOOP_MODE_REVERSE] = "Reverse",
    [renoise.Sample.LOOP_MODE_PING_PONG] = "PingPong"
  }

  for i = 1, num_samples do
    samples[i].loop_mode = loop_mode
  end


  local mode_name = loop_mode_names[loop_mode] or "Unknown"
  renoise.app():show_status("Loop mode set to " .. mode_name .. " for " .. num_samples .. " samples.")
  --returnpe()
end

-- Fix velocity mappings of all samples in the selected instrument and disable vel->vol
function fix_sample_velocity_mappings()
  local song=renoise.song()
  local instrument = song.selected_instrument

  if not instrument then
    renoise.app():show_status("No instrument selected.")
    return
  end

  -- Check if the instrument has slices
  if instrument.samples[1].slice_markers ~= nil then
    renoise.app():show_status("Slices detected, isolating slices to individual instruments.")
    PakettiIsolateSlicesToInstrument()
  end
  local instrument = renoise.song().selected_instrument
  local samples = instrument.samples
  local num_samples = #samples

  if num_samples < 1 then
    renoise.app():show_status("No samples found in the selected instrument.")
    return
  end

  -- Define the velocity range (01 to 127)
  local velocity_min = 1
  local velocity_max = 127
  local velocity_step = math.floor((velocity_max - velocity_min + 1) / num_samples)

  -- Base note and note range to apply to all samples
  local base_note = 48 -- Default to C-4
  local note_range = {base_note, base_note} -- Restrict to a single key

  for i = 1, num_samples do
    local sample = samples[i]
    local start_velocity = velocity_min + (i - 1) * velocity_step
    local end_velocity = start_velocity + velocity_step - 1

    -- Adjust for the last sample to ensure it ends exactly at 127
    if i == num_samples then
      end_velocity = velocity_max
    end

    -- Disable vel->vol
    sample.sample_mapping.map_velocity_to_volume = false

    -- Update sample mapping
    sample.sample_mapping.base_note = base_note
    sample.sample_mapping.note_range = note_range
    sample.sample_mapping.velocity_range = {start_velocity, end_velocity}
  end

  renoise.app():show_status("Velocity mappings updated, vel->vol set to OFF for " .. num_samples .. " samples.")
end

function jump_to_pattern_segment(segment_number)
  local song=renoise.song()
  song.transport.follow_player = false
  local pattern_length = song.selected_pattern.number_of_lines
  local segment = math.floor(pattern_length / 8)
  song.selected_line_index = segment * (segment_number - 1) + 1  -- Added +1 to start from first row
  returnpe()
end
-- Write notes with ramp-up velocities (01 to 127)
function write_velocity_ramp_up()
  local song=renoise.song()
  local pattern = song.selected_pattern
  local start_line_index = song.selected_line_index  
  local line_index = song.selected_line_index
  local instrument_index = song.selected_instrument_index
  
  local notecoll
  if song.selected_note_column_index == 0 then
    notecoll = 1
  else
    notecoll = song.selected_note_column_index
  end

  -- Check if track is a note track
  if renoise.song().selected_track.type ~= 1 then
    renoise.app():show_status("Cannot write notes to non-note tracks.")
    return
  end

  -- Get unique velocity ranges
  local velocity_ranges = {}
  local samples = renoise.song().selected_instrument.samples
  for _, sample in ipairs(samples) do
    local range_key = table.concat(sample.sample_mapping.velocity_range, "-")
    velocity_ranges[range_key] = sample.sample_mapping.velocity_range
  end

  -- Convert to array and sort by lower velocity bound
  local unique_ranges = {}
  for _, range in pairs(velocity_ranges) do
    table.insert(unique_ranges, range)
  end
  table.sort(unique_ranges, function(a, b) return a[1] < b[1] end)

  local num_ranges = #unique_ranges
  if num_ranges < 1 then
    renoise.app():show_status("No velocity mappings found.")
    return
  end

  -- Calculate how many notes we can write before hitting the pattern limit
  local max_lines = pattern.number_of_lines
  local available_lines = max_lines - line_index + 1
  local notes_to_write = math.min(num_ranges, available_lines)

  local base_note = 48 -- C-4

  -- Write notes using the actual velocity ranges
  for i = 1, notes_to_write do
    local velocity = unique_ranges[i][1] -- Use the lower bound of each range
    local line = pattern.tracks[song.selected_track_index].lines[line_index + i - 1]
    if line and line.note_columns and line.note_columns[notecoll] then
      line.note_columns[notecoll].note_value = base_note
      line.note_columns[notecoll].instrument_value = instrument_index - 1
      line.note_columns[notecoll].volume_value = velocity
    end
  end

  song.selection_in_pattern = {
    start_line = start_line_index,
    end_line = start_line_index + notes_to_write - 1,
    start_track = song.selected_track_index,
    end_track = song.selected_track_index,
    start_column = notecoll,
    end_column = notecoll
  }

  renoise.app():show_status("Ramp-up velocities written based on " .. notes_to_write .. " unique velocity ranges.")
end

-- Write notes with ramp-down velocities starting from the last sample's lower velocity bound
function write_velocity_ramp_down()
  local song=renoise.song()
  local pattern = song.selected_pattern
  local start_line_index = song.selected_line_index
  local instrument_index = song.selected_instrument_index
  
  local notecoll
  if song.selected_note_column_index == 0 then
    notecoll = 1
  else
    notecoll = song.selected_note_column_index
  end

  -- Check if track is a note track
  if renoise.song().selected_track.type ~= 1 then
    renoise.app():show_status("Cannot write notes to non-note tracks.")
    return
  end

  -- Get unique velocity ranges
  local velocity_ranges = {}
  local samples = renoise.song().selected_instrument.samples
  for _, sample in ipairs(samples) do
    local range_key = table.concat(sample.sample_mapping.velocity_range, "-")
    velocity_ranges[range_key] = sample.sample_mapping.velocity_range
  end

  -- Convert to array and sort by lower velocity bound (descending)
  local unique_ranges = {}
  for _, range in pairs(velocity_ranges) do
    table.insert(unique_ranges, range)
  end
  table.sort(unique_ranges, function(a, b) return a[1] > b[1] end)

  local num_ranges = #unique_ranges
  if num_ranges < 1 then
    renoise.app():show_status("No velocity mappings found.")
    return
  end

  -- Calculate how many notes we can write before hitting the pattern limit
  local max_lines = pattern.number_of_lines
  local available_lines = max_lines - start_line_index + 1
  local notes_to_write = math.min(num_ranges, available_lines)

  local base_note = 48

  -- Write notes using the actual velocity ranges in descending order
  for i = 1, notes_to_write do
    local velocity = unique_ranges[i][1] -- Use the lower bound of each range
    local line = pattern.tracks[song.selected_track_index].lines[start_line_index + i - 1]
    if line and line.note_columns and line.note_columns[notecoll] then
      line.note_columns[notecoll].note_value = base_note
      line.note_columns[notecoll].instrument_value = instrument_index - 1
      line.note_columns[notecoll].volume_value = velocity
    end
  end

  song.selection_in_pattern = {
    start_line = start_line_index,
    end_line = start_line_index + notes_to_write - 1,
    start_track = song.selected_track_index,
    end_track = song.selected_track_index,
    start_column = notecoll,
    end_column = notecoll
  }

  renoise.app():show_status("Ramp-down velocities written based on " .. notes_to_write .. " unique velocity ranges.")
end

-- Write notes with random velocities, respecting the last sample's velocity range
function write_random_velocity_notes()
  local song=renoise.song()
  local pattern = song.selected_pattern
  local start_line_index = song.selected_line_index
  local instrument_index = song.selected_instrument_index
  
  local notecoll
  if song.selected_note_column_index == 0 then
    notecoll = 1
  else
    notecoll = song.selected_note_column_index
  end

  -- Check if track is a note track
  if renoise.song().selected_track.type ~= 1 then
    renoise.app():show_status("Cannot write notes to non-note tracks.")
    return
  end

  -- Get unique velocity ranges
  local velocity_ranges = {}
  local samples = renoise.song().selected_instrument.samples
  for _, sample in ipairs(samples) do
    local range_key = table.concat(sample.sample_mapping.velocity_range, "-")
    velocity_ranges[range_key] = sample.sample_mapping.velocity_range
  end

  -- Convert to array
  local unique_ranges = {}
  for _, range in pairs(velocity_ranges) do
    table.insert(unique_ranges, range)
  end

  local num_ranges = #unique_ranges
  if num_ranges < 1 then
    renoise.app():show_status("No velocity mappings found.")
    return
  end

  -- Calculate how many notes we can write before hitting the pattern limit
  local max_lines = pattern.number_of_lines
  local available_lines = max_lines - start_line_index + 1
  local notes_to_write = math.min(num_ranges, available_lines)

  local base_note = 48

  -- Write notes with random velocities within the available ranges
  for i = 1, notes_to_write do
    -- Pick a random range
    local random_range_index = math.random(1, num_ranges)
    local range = unique_ranges[random_range_index]
    
    -- Pick a random velocity within that range
    local velocity = math.random(range[1], range[2])
    local line = pattern.tracks[song.selected_track_index].lines[start_line_index + i - 1]
    if line and line.note_columns and line.note_columns[notecoll] then
      line.note_columns[notecoll].note_value = base_note
      line.note_columns[notecoll].instrument_value = instrument_index - 1
      line.note_columns[notecoll].volume_value = velocity
    end
  end

  song.selection_in_pattern = {
    start_line = start_line_index,
    end_line = start_line_index + notes_to_write - 1,
    start_track = song.selected_track_index,
    end_track = song.selected_track_index,
    start_column = notecoll,
    end_column = notecoll
  }

  renoise.app():show_status("Random velocities written based on " .. notes_to_write .. " unique velocity ranges.")
end

renoise.tool():add_keybinding{name="Global:Paketti:Stack All Samples in Instrument with Velocity Mapping Split",invoke=function() fix_sample_velocity_mappings() end}
renoise.tool():add_keybinding{name="Global:Paketti:Write Velocity Ramp Up for Stacked Instrument",invoke=function() write_velocity_ramp_up() end}
renoise.tool():add_keybinding{name="Global:Paketti:Write Velocity Ramp Down for Stacked Instrument",invoke=function() write_velocity_ramp_down() end}
renoise.tool():add_keybinding{name="Global:Paketti:Write Velocity Random for Stacked Instrument",invoke=function() write_random_velocity_notes() end}

function on_switch_changed(selected_value)
  local instrument = renoise.song().selected_instrument
  local num_samples = #instrument.samples

  -- Check if the first sample has slices
  local has_slices = false
  if num_samples > 0 and instrument.samples[1].slice_markers ~= nil then
    has_slices = #instrument.samples[1].slice_markers > 0
  end

  if has_slices then
    -- Already have slices
   --f wipeslices()
    if selected_value ~= "OFF" then
      slicerough(selected_value)
      renoise.app():show_status("Slices updated to " .. tostring(selected_value) .. " divisions.")
    else
      renoise.app():show_status("Slices cleared. No further slicing performed.")
    end
  else
    -- No slices currently
    if num_samples == 1 then
      -- Single sample, no slices
      if selected_value ~= "OFF" then
        slicerough(selected_value)
        renoise.app():show_status("Sample sliced into " .. tostring(selected_value) .. " divisions.")
      else
        renoise.app():show_status("Slice function is OFF. No slicing performed.")
      end
    else
      -- Multiple samples, no slices
      renoise.app():show_status("Multiple samples detected. No slicing performed.")
    end
  end
end

function pakettiStackerDialog(proceed_with_stacking, on_switch_changed, PakettiIsolateSlicesToInstrument)
  if dialog and dialog.visible then
    print ("BLAA")
  dialog:close()
  dialog = nil
  dialog_content = nil
  return 
  end

  
--  local dialog = nil

  local switch_values = {"OFF", "2", "4", "8", "16", "32", "64", "128"}
  local switch_index = 1 -- Default to "OFF"

  -- Function to close the dialog
  local function closeST_dialog()
    if dialog and dialog.visible then
      dialog:close()
      dialog = nil
    end
  end

  -- Dialog Content Definition
  local dialog_content = vb:column{
    vb:row{vb:button{text="Browse",notifier=function() pitchBendMultipleSampleLoader() end}},
    vb:row{vb:text{text="Set Slice Count",width=100,style = "strong",font = "bold"},
vb:switch {
--  id="wipeslice",
  items = switch_values,
  width=250,
  value = switch_index,
  notifier=function(index)
    local selected_value = switch_values[index]
    if selected_value ~= "OFF" then
      -- Do not revert to OFF here. Just call on_switch_changed.
      on_switch_changed(tonumber(selected_value))
      renoise.app().window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
    else
      wipeslices()
      on_switch_changed("OFF")
    end
  end}},
   vb:row{
        vb:button{
            text="Proceed with Stacking",
            width=150,
            notifier=function()
                proceed_with_stacking()
                returnpe() 
            end
        },
        vb:button{
            text="Auto Stack from Pattern",
            width=150,
            notifier=function()
                auto_stack_from_existing_pattern()
            end
        }
    },
    
    vb:row{vb:text{text="Stack Ramp",width=100,font = "bold",style = "strong",},
      vb:button{text="Up",notifier=function() write_velocity_ramp_up()
      returnpe() end},
      vb:button{
        text="Down",
        notifier=function() write_velocity_ramp_down() 
        returnpe() end},
      vb:button{
        text="Random",
        notifier=function() write_random_velocity_notes() 
        returnpe() end}},
vb:row{vb:text{text="Set Loop Mode",width=100, style="strong",font="bold"},
vb:button{text="Off",notifier=function() set_loop_mode_for_selected_instrument(renoise.Sample.LOOP_MODE_OFF) end},
vb:button{text="Forward",notifier=function() set_loop_mode_for_selected_instrument(renoise.Sample.LOOP_MODE_FORWARD) end},
vb:button{text="PingPong",notifier=function() set_loop_mode_for_selected_instrument(renoise.Sample.LOOP_MODE_PING_PONG) end},
vb:button{text="Reverse",notifier=function() set_loop_mode_for_selected_instrument(renoise.Sample.LOOP_MODE_REVERSE)end}

},
vb:row{vb:text{text="PitchStepper",width=100,font="bold",style="strong"},
vb:button{text="+12 -12",width=50,notifier=function() PakettiFillPitchStepper() end},
vb:button{text="+24 -24",width=50,notifier=function() PakettiFillPitchStepperTwoOctaves() end},
vb:button{text="0",width=50,notifier=function() PakettiClearStepper("Pitch Stepper") end},
},
vb:row{
vb:text{text="Instrument Pitch",width=100,font="bold",style="strong"},
vb:switch {
  width=250,
--  id = "instrument_pitch",
  items = {"-24", "-12", "0", "+12", "+24"},
  value = 3,
  notifier=function(index)
    -- Convert the selected index to the corresponding pitch value
    local pitch_values = {-24, -12, 0, 12, 24}
    local selected_pitch = pitch_values[index] -- Lua uses 1-based indexing for tables
    
    -- Update the instrument transpose
    renoise.song().selected_instrument.transpose = selected_pitch
  end
}},
vb:row{
  vb:button{
    text="Follow Pattern",
    notifier=function()
      if renoise.song().transport.follow_player then
        renoise.song().transport.follow_player = false
      else
        renoise.song().transport.follow_player = true
      end
    returnpe() end},
   vb:button{text="1/8", notifier=function() jump_to_pattern_segment(1) end},
   vb:button{text="2/8", notifier=function() jump_to_pattern_segment(2) end},
   vb:button{text="3/8", notifier=function() jump_to_pattern_segment(3) end},
   vb:button{text="4/8", notifier=function() jump_to_pattern_segment(4) end},
   vb:button{text="5/8", notifier=function() jump_to_pattern_segment(5) end},
   vb:button{text="6/8", notifier=function() jump_to_pattern_segment(6) end},
   vb:button{text="7/8", notifier=function() jump_to_pattern_segment(7) end},
   vb:button{text="8/8", notifier=function() jump_to_pattern_segment(8) end}}}
  -- Show the dialog
  local keyhandler = create_keyhandler_for_dialog(
    function() return dialog end,
    function(value) dialog = value end
  )
  dialog = renoise.app():show_custom_dialog("Paketti Stacker", dialog_content, keyhandler)
end

  function proceed_with_stacking()
    local song=renoise.song()
    local current_track = song.selected_track
    
    -- Remove *Instr. Macros device if it exists
    for i = #current_track.devices, 2, -1 do
      if current_track.devices[i].name == "*Instr. Macros" then
        current_track:delete_device_at(i)
        break
      end
    end

    -- Run the isolation function
    PakettiIsolateSlicesToInstrument()
    
    if preferences.pakettiLoaderDontCreateAutomationDevice.value == false then 
    -- Add *Instr. Macros device back
    loadnative("Audio/Effects/Native/*Instr. Macros")
end
    local instrument = song.selected_instrument
    local samples = instrument.samples
    local num_samples = #samples

    -- Base note and note range to apply to all samples
    local base_note = 48 -- Default to C-4
    local note_range = {0, 119} -- Restrict to a single key

    for i = 1, num_samples do
      local sample = samples[i]
      
      -- First slice gets velocity 0, rest get 1-127
      local velocity = (i == 1) and 0 or (i - 1)

      sample.sample_mapping.map_velocity_to_volume = false
      sample.sample_mapping.base_note = base_note
      sample.sample_mapping.note_range = note_range
      sample.sample_mapping.velocity_range = {velocity, velocity} -- Each slice gets exactly one velocity
    end
  end

function auto_stack_from_existing_pattern()
    print("--- Auto Stack from Existing Pattern ---")
    
    local song = renoise.song()
    local current_track_index = song.selected_track_index
    local current_pattern = song.selected_pattern
    local current_track_data = current_pattern:track(current_track_index)
    local original_instrument_index = song.selected_instrument_index
    
    -- 1. ANALYZE: Read the current track's pattern data
    local slice_sequence = {}
    print("Analyzing pattern data on track " .. current_track_index)
    
    local current_track = song.selected_track
    local visible_note_columns = current_track.visible_note_columns
    
    for line_index = 1, current_pattern.number_of_lines do
        local line = current_track_data:line(line_index)
        for col = 1, visible_note_columns do
            local note_col = line:note_column(col)
            if not note_col.is_empty and note_col.instrument_value == (original_instrument_index - 1) then
                -- Found a note using current instrument - record the slice info
                local slice_info = {
                    line = line_index,
                    column = col,
                    note_value = note_col.note_value,
                    volume = note_col.volume_value,
                    delay = note_col.delay_value,
                    panning = note_col.panning_value,
                    effect_number = note_col.effect_number_value,
                    effect_amount = note_col.effect_amount_value
                }
                table.insert(slice_sequence, slice_info)
                print("Found slice at line " .. line_index .. ", note " .. note_col.note_value .. " (" .. note_value_to_string(note_col.note_value) .. ")")
            end
        end
    end
    
    if #slice_sequence == 0 then
        renoise.app():show_status("No notes found using current instrument on this track")
        print("Error: No notes found using current instrument")
        return
    end
    
    print("Found " .. #slice_sequence .. " notes to convert")
    
    -- 2. STACK: Check if we need to isolate slices first, or just stack existing samples
    local instrument = song:instrument(original_instrument_index)
    local has_slices = instrument.samples[1] and instrument.samples[1].slice_markers and #instrument.samples[1].slice_markers > 0
    
    if has_slices then
        print("Found slices - running isolation...")
        PakettiIsolateSlicesToInstrument() -- Creates individual samples from slices
        -- After isolation, we need to get the NEW instrument that was created
        instrument = song.selected_instrument -- Get the newly created instrument
        original_instrument_index = song.selected_instrument_index -- Update to new instrument index
    end
    
    -- Set up simple velocity mapping for all samples
    print("Setting up velocity mapping...")
    local samples = instrument.samples
    local num_samples = #samples
    
    for i = 1, num_samples do
        local sample = samples[i]
        local velocity = i -- Sample 1 = velocity 1, Sample 2 = velocity 2, etc.
        
        sample.sample_mapping.map_velocity_to_volume = false
        sample.sample_mapping.base_note = 48 -- C-4
        sample.sample_mapping.note_range = {0, 119}
        sample.sample_mapping.velocity_range = {velocity, velocity} -- Each sample gets exactly one velocity
        
        print("Sample " .. i .. " mapped to velocity " .. velocity)
    end
    
    -- 3. CREATE: New track
    print("Creating new track...")
    song:insert_track_at(current_track_index + 1)
    song.selected_track_index = current_track_index + 1
    
    -- 4. TRANSLATE: Convert slice sequence to velocity sequence on new track
    print("Translating slice notes to velocity notes...")
    local new_track_data = current_pattern:track(song.selected_track_index)
    
    for _, slice_info in ipairs(slice_sequence) do
        local line = new_track_data:line(slice_info.line)
        local note_col = line:note_column(slice_info.column)
        
        -- Calculate velocity based on original note value (C-0 = velocity 1, C#0 = velocity 2, etc.)
        local velocity = slice_info.note_value + 1 -- Convert 0-based note to 1-based velocity
        velocity = math.min(127, velocity) -- Cap at 127
        
        -- Write note with velocity = slice mapping
        note_col.note_value = 48 -- C-4 base note for stacked instrument
        note_col.instrument_value = original_instrument_index - 1 -- Use the original (now stacked) instrument
        note_col.volume_value = velocity -- Velocity triggers the right sample
        note_col.delay_value = slice_info.delay
        note_col.panning_value = slice_info.panning
        note_col.effect_number_value = slice_info.effect_number
        note_col.effect_amount_value = slice_info.effect_amount
        
        print("Converted " .. note_value_to_string(slice_info.note_value) .. " to velocity " .. velocity)
    end
    
    renoise.app():show_status("Auto-stacked! " .. #slice_sequence .. " slice notes → velocity-mapped samples on new track")
    print("--- Auto Stack Complete ---")
    returnpe()
end



function LoadSliceIsolateStack()
  -- Initial Operations
  pitchBendMultipleSampleLoader()
  renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
--    renoise.app():show_status("Velocity mappings updated, vel->vol set to OFF for " .. num_samples .. " samples.")

    renoise.song().selected_line_index = 1
pakettiStackerDialog(proceed_with_stacking, on_switch_changed, PakettiIsolateSlicesToInstrument)
    set_loop_mode_for_selected_instrument(renoise.Sample.LOOP_MODE_FORWARD)
 --   selectedInstrumentAllAutoseekControl(1) -- this shouldn't be included in the mix.
    selectedInstrumentAllAutofadeControl(1)
    setSelectedInstrumentInterpolation(4)
    if preferences.pakettiLoaderDontCreateAutomationDevice.value == false then 
    loadnative("Audio/Effects/Native/*Instr. Macros")
    end
    renoise.app():show_status("The Slices have been turned to Samples. The Samples have been Stacked together. The Velocity controls the Sample Selection. The Pattern now has a ramp up for the samples.")
  end

renoise.tool():add_keybinding{name="Global:Paketti:Load&Slice&Isolate&Stack Sample",invoke=function() LoadSliceIsolateStack() end}
renoise.tool():add_keybinding{name="Global:Paketti:Paketti Stacker Dialog...",invoke=function() pakettiStackerDialog(proceed_with_stacking, on_switch_changed, PakettiIsolateSlicesToInstrument) end}
