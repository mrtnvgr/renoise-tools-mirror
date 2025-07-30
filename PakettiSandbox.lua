
-- Helper function to convert MIDI note number to note name
function noteNumberToName(note_number)
  local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  local octave = math.floor(note_number / 12) - 1
  local note_index = (note_number % 12) + 1
  return note_names[note_index] .. octave
end

-- Helper function to find APC devices (APC Key 25, APC40, APC mini, etc.)
function findAPCKey25()
  local available_devices = renoise.Midi.available_output_devices()
  
  -- Look for any device containing "apc" in the name
  for _, device_name in ipairs(available_devices) do
    if string.find(string.lower(device_name), "apc") then
      print("Found APC device: " .. device_name)
      return device_name
    end
  end
  
  -- If no APC device found, show available devices for debugging
  print("No APC device found. Available MIDI output devices:")
  for i, device_name in ipairs(available_devices) do
    print(string.format("[%d] => %s", i, device_name))
  end
  
  return nil
end

-- Function to control APC pads with note on/off messages
function pakettiAPCControlPads(message_type)
  print("=== pakettiAPCControlPads called with message_type: " .. tostring(message_type) .. " ===")
  
  local apc_device_name = findAPCKey25()
  
  if not apc_device_name then
    print("ERROR: APC device not found!")
    renoise.app():show_status("APC device not found")
    return
  end
  
  print("Using APC device: " .. apc_device_name)
  local midi_out = renoise.Midi.create_output_device(apc_device_name)
  local base_note = 36 -- This was working - lighting up 4 pads
  
  -- Send the original working range (this was lighting up pads 5-8)
  print("Sending original working range (notes 36-43)...")
  for i = 0, 7 do
    local note = base_note + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}  -- Note On message
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}  -- Note On with velocity 0 (effectively note off)
    end
  end
  
  -- Also try the higher range for the missing pads (44-47)
  print("Also trying higher range (notes 44-47) for missing pads...")
  for i = 0, 3 do
    local note = 44 + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}  -- Note On message
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}  -- Note On with velocity 0 (effectively note off)
    end
  end
  midi_out:close()
  print("=== MIDI messages sent, device closed ===")
end

-- Global variables to track APC pad states separately
local apc_pads_1_4_state = false  -- false = off, true = on
local apc_pads_5_8_state = false  -- false = off, true = on
local apc_all_pads_state = false  -- false = off, true = on

-- Function to toggle APC pads 1-4 on/off
function pakettiAPCTogglePads1to4()
  print("=== pakettiAPCTogglePads1to4 called, current state: " .. tostring(apc_pads_1_4_state) .. " ===")
  
  -- Toggle the state
  apc_pads_1_4_state = not apc_pads_1_4_state
  local message_type = apc_pads_1_4_state and "note_on" or "note_off"
  
  print("New state for pads 1-4: " .. tostring(apc_pads_1_4_state) .. ", sending: " .. message_type)
  pakettiAPCControlFirstFourPads(message_type)
end

-- Function to toggle APC pads 5-8 on/off (using the ORIGINAL working method)
function pakettiAPCTogglePads5to8()
  print("=== pakettiAPCTogglePads5to8 called, current state: " .. tostring(apc_pads_5_8_state) .. " ===")
  
  -- Toggle the state
  apc_pads_5_8_state = not apc_pads_5_8_state
  local message_type = apc_pads_5_8_state and "note_on" or "note_off"
  
  print("New state for pads 5-8: " .. tostring(apc_pads_5_8_state) .. ", sending: " .. message_type)
  
  -- Use the ORIGINAL working method - send the full range 36-43 like before
  local apc_device_name = findAPCKey25()
  
  if not apc_device_name then
    print("ERROR: APC device not found!")
    renoise.app():show_status("APC device not found")
    return
  end
  
  print("Using APC device: " .. apc_device_name)
  local midi_out = renoise.Midi.create_output_device(apc_device_name)
  local base_note = 36 -- Back to the original working setup
  
  -- Send the original working range (notes 36-43) that was lighting up pads 5-8
  print("Sending original working range (notes 36-43) for pads 5-8...")
  for i = 0, 7 do
    local note = base_note + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}  -- Note On message
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}  -- Note On with velocity 0 (effectively note off)
    end
  end
  
  midi_out:close()
  print("=== Pads 5-8 toggle completed (using original method) ===")
end

-- Function to toggle ALL 8 pads with timing and theory-based approach
function pakettiAPCToggleAllPads()
  print("=== pakettiAPCToggleAllPads called, current state: " .. tostring(apc_all_pads_state) .. " ===")
  
  -- Toggle the state
  apc_all_pads_state = not apc_all_pads_state
  local message_type = apc_all_pads_state and "note_on" or "note_off"
  
  print("New state for ALL pads: " .. tostring(apc_all_pads_state) .. ", sending: " .. message_type)
  
  local apc_device_name = findAPCKey25()
  
  if not apc_device_name then
    print("ERROR: APC device not found!")
    renoise.app():show_status("APC device not found")
    return
  end
  
  print("Using APC device: " .. apc_device_name)
  local midi_out = renoise.Midi.create_output_device(apc_device_name)
  
  -- THEORY 1: Send pads 5-8 first (the reliable ones)
  print("Step 1: Controlling pads 5-8 first (notes 36-43)...")
  local base_note = 36
  for i = 0, 7 do
    local note = base_note + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}
    end
  end
  
  -- THEORY 2: Add small delay before sending pads 1-4 range
  print("Step 2: Small delay, then controlling pads 1-4...")
  
  -- Send the multiple ranges that work for pads 1-4
  local test_ranges = {
    {32, "32-35"},
    {44, "44-47"}, 
    {48, "48-51"}
  }
  
  for _, range in ipairs(test_ranges) do
    local start_note = range[1]
    local range_name = range[2]
    print(string.format("Trying range %s...", range_name))
    
    for i = 0, 3 do
      local note = start_note + i
      if message_type == "note_on" then
        print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
        midi_out:send {0x90, note, 127}
      else
        print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
        midi_out:send {0x90, note, 0}
      end
    end
  end
  
  -- THEORY 3: Sync the individual state variables
  apc_pads_1_4_state = apc_all_pads_state
  apc_pads_5_8_state = apc_all_pads_state
  print(string.format("Synced individual states: 1-4=%s, 5-8=%s", 
    tostring(apc_pads_1_4_state), tostring(apc_pads_5_8_state)))
  
  midi_out:close()
  print("=== ALL pads toggle completed ===")
end

-- Function to control ONLY the first 4 pads (for testing)
function pakettiAPCControlFirstFourPads(message_type)
  print("=== pakettiAPCControlFirstFourPads called with message_type: " .. tostring(message_type) .. " ===")
  
  local apc_device_name = findAPCKey25()
  
  if not apc_device_name then
    print("ERROR: APC device not found!")
    renoise.app():show_status("APC device not found")
    return
  end
  
  print("Using APC device: " .. apc_device_name)
  local midi_out = renoise.Midi.create_output_device(apc_device_name)
  
  -- Try different note ranges to find what controls pads 1-4
  print("Testing different note ranges for pads 1-4...")
  
  -- Test range 1: notes 32-35
  print("Trying notes 32-35...")
  for i = 0, 3 do
    local note = 32 + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}
    end
  end
  
  -- Test range 2: notes 44-47
  print("Trying notes 44-47...")
  for i = 0, 3 do
    local note = 44 + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}
    end
  end
  
  -- Test range 3: notes 48-51
  print("Trying notes 48-51...")
  for i = 0, 3 do
    local note = 48 + i
    if message_type == "note_on" then
      print(string.format("Sending Note ON - Note: %d (%s), Velocity: 127", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 127}
    else
      print(string.format("Sending Note OFF - Note: %d (%s), Velocity: 0", note, noteNumberToName(note)))
      midi_out:send {0x90, note, 0}
    end
  end
  
  midi_out:close()
  print("=== First four pads test completed ===")
end

renoise.tool():add_midi_mapping{name = "Paketti:APC Light Up All Pads",invoke = function(message) if message:is_trigger() then print("Light Up All Pads MIDI mapping triggered!") pakettiAPCControlPads("note_on") end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Turn Off All Pads",invoke = function(message) if message:is_trigger() then print("Turn Off All Pads MIDI mapping triggered!") pakettiAPCControlPads("note_off") end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Toggle Pads 1-4",invoke = function(message) if message:is_trigger() then print("Toggle Pads 1-4 MIDI mapping triggered!") pakettiAPCTogglePads1to4() end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Toggle Pads 5-8",invoke = function(message) if message:is_trigger() then print("Toggle Pads 5-8 MIDI mapping triggered!") pakettiAPCTogglePads5to8() end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Toggle ALL 8 Pads",invoke = function(message) if message:is_trigger() then print("Toggle ALL 8 Pads MIDI mapping triggered!") pakettiAPCToggleAllPads() end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Test First 4 Pads ON",invoke = function(message) if message:is_trigger() then print("Test First 4 Pads ON triggered!") pakettiAPCControlFirstFourPads("note_on") end end}
renoise.tool():add_midi_mapping{name = "Paketti:APC Test First 4 Pads OFF",invoke = function(message) if message:is_trigger() then print("Test First 4 Pads OFF triggered!") pakettiAPCControlFirstFourPads("note_off") end end}





---
----------
-- Function to toggle showing only one specific column type
function showOnlyColumnType(column_type)
    local song=renoise.song()
    
    -- Validate column_type parameter
    if not column_type or type(column_type) ~= "string" then
        print("Invalid column type specified")
        return
    end
    
    -- Map of valid column types to their corresponding track properties
    local column_properties = {
        ["volume"] = "volume_column_visible",
        ["panning"] = "panning_column_visible",
        ["delay"] = "delay_column_visible",
        ["effects"] = "sample_effects_column_visible"
    }
    
    -- Check if the specified column type is valid
    if not column_properties[column_type] then
        print("Invalid column type: " .. column_type)
        return
    end
    
    -- Check if we're already showing only this column type
    local is_showing_only_this = true
    for track_index = 1, song.sequencer_track_count do
        local track = song.tracks[track_index]
        -- Check if current column is visible and others are hidden
        if not track[column_properties[column_type]] or
           (column_type ~= "volume" and track.volume_column_visible) or
           (column_type ~= "panning" and track.panning_column_visible) or
           (column_type ~= "delay" and track.delay_column_visible) or
           (column_type ~= "effects" and track.sample_effects_column_visible) then
            is_showing_only_this = false
            break
        end
    end
    
    -- Iterate through all tracks (except Master and Send tracks)
    for track_index = 1, song.sequencer_track_count do
        local track = song.tracks[track_index]
        
        -- Hide all columns first
        track.volume_column_visible = false
        track.panning_column_visible = false
        track.delay_column_visible = false
        track.sample_effects_column_visible = false
        
        -- If we weren't already showing only this column, show it
        if not is_showing_only_this then
            track[column_properties[column_type]] = true
        end
    end
    
    -- Show status message
    local message = is_showing_only_this and 
        "Hiding all columns" or 
        "Showing only " .. column_type .. " columns across all tracks"
    renoise.app():show_status(message)
end

renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle Show Only Volume Columns",invoke=function() showOnlyColumnType("volume") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle Show Only Panning Columns",invoke=function() showOnlyColumnType("panning") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle Show Only Delay Columns",invoke=function() showOnlyColumnType("delay") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle Show Only Effect Columns",invoke=function() showOnlyColumnType("effects") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Show Only Volume Columns",invoke=function() showOnlyColumnType("volume") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Show Only Panning Columns",invoke=function() showOnlyColumnType("panning") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Show Only Delay Columns",invoke=function() showOnlyColumnType("delay") end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Show Only Effect Columns",invoke=function() showOnlyColumnType("effects") end}


--
function detect_zero_crossings()
    local song=renoise.song()
    local sample = song.selected_sample
  
    if not sample or not sample.sample_buffer.has_sample_data then
        renoise.app():show_status("No sample selected or sample has no data")
        return
    end
  
    local buffer = sample.sample_buffer
    local zero_crossings = {}
    local max_silence = 0.002472  -- Your maximum silence threshold
  
    print("\n=== Sample Buffer Analysis ===")
    print("Sample length:", buffer.number_of_frames, "frames")
    print("Number of channels:", buffer.number_of_channels)
    print("Scanning for zero crossings (threshold:", max_silence, ")")
  
    -- Scan through sample data in chunks for better performance
    local chunk_size = 1000
    local last_was_silence = nil
  
    for frame = 1, buffer.number_of_frames do
        local value = buffer:sample_data(1, frame)
        local is_silence = (value >= 0 and value <= max_silence)
        
        -- Detect transition points between silence and non-silence
        if last_was_silence ~= nil and last_was_silence ~= is_silence then
            table.insert(zero_crossings, frame)
        end
        
        last_was_silence = is_silence
        
        -- Show progress every chunk_size frames
        if frame % chunk_size == 0 or frame == buffer.number_of_frames then
            renoise.app():show_status(string.format("Analyzing frames %d to %d of %d", 
                math.max(1, frame-chunk_size+1), frame, buffer.number_of_frames))
        end
    end
  
    -- Show results
    local status_message = string.format("\nFound %d zero crossings", #zero_crossings)
    renoise.app():show_status(status_message)
    print(status_message)
  
    -- Animate through the zero crossings
    if #zero_crossings >= 2 then
        -- Create a coroutine to handle the animation
        local co = coroutine.create(function()
            for i = 1, #zero_crossings - 1, 2 do  -- Step by 2 to get pairs of transitions
                if i + 1 <= #zero_crossings then
                    buffer.selection_range = {
                        zero_crossings[i],
                        zero_crossings[i + 1]
                    }
                    renoise.app():show_status(string.format("Selecting zero crossings %d to %d (frames %d to %d)", 
                        i, i+1, zero_crossings[i], zero_crossings[i + 1]))
                    coroutine.yield()
                end
            end
        end)
        
        -- Add timer to step through coroutine
        renoise.tool():add_timer(function()
            if coroutine.status(co) ~= "dead" then
                local success, err = coroutine.resume(co)
                if not success then
                    print("Error:", err)
                    return false
                end
                return true
            end
            return false
        end, 0.5)
    else
        print("Not enough zero crossings found to set loop points")
    end
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Detect Zero Crossings",invoke=detect_zero_crossings}

-- from Paper
-- Rough formula i hacked up: 
-- ( 1 / (floor((5 * rate) / (3 * tempo)) / rate * speed) ) * 10

-- and another Paper example:
-- ( 1 / (floor((5 * rate) / (3 * tempo)) / rate * speed) ) * (rows_per_beat * 2.5)
-- i think this is correct


-- Paper simplified
--- (rows_per_beat * 2.5 * rate) / (floor((5 * rate) / (3 * tempo)) * speed)

-- from 8bitbubsy
-- Take BPM 129 at 44100Hz as an example:
-- samplesPerTick = 44100 / 129 = 341.860465116 --> truncated to 341.
-- BPM = 44100.0 / samplesPerTick (341) = BPM 129.325 

-- another example from 8bitbubsy
-- realBPM = (rate / floor(rate / bpm * 2.5)) / (speed / 15) 
-- result is (15 = 6*2.5)



-- TODO: Does this work if you have a 192 pattern length?
-- TODO: What if you wanna double it or halve it based on how many beats are there
-- in the pattern?
-- TODO: Consider those examples above.
-- Dialog Reference
local dialog = nil

-- Default Values
local speed = 6
local tempo = 125
local real_bpm = tempo / (speed / 6)


-- Function to Calculate BPM
local function calculate_bpm(speed, tempo)
  -- Simple formula: if speed is 6, BPM equals tempo
  -- If speed is higher than 6, BPM is lower, if speed is lower than 6, BPM is higher
  local bpm = tempo / (speed / 6)
  -- Check if BPM is within valid range (20 to 999)
  if bpm < 20 or bpm > 999 then
    return nil, {
      string.format("Invalid BPM value '%.2f'", bpm),
      "Valid values are (20 to 999)"
    }
  end
  return bpm
end

-- GUI Dialog Function
function pakettiSpeedTempoDialog()
  if dialog and dialog.visible then
    dialog:close()
    dialog = nil
    return
  end

  -- Valueboxes for Speed and Tempo
  local vb = renoise.ViewBuilder()
  local dialog_content = vb:column{margin=10,--spacing=8,
    vb:row{
      vb:column{
        vb:text{text="Speed:"},
        vb:valuebox{min=1,max=255,value=speed,
          tostring=function(val) return string.format("%X", val) end,
          tonumber=function(val) return tonumber(val, 16) end,
          notifier=function(val)
            speed = val
            local calculated_bpm, error_msgs = calculate_bpm(speed, tempo)
            real_bpm = calculated_bpm
            vb.views.result_label.text = string.format("Speed %d Tempo %d is %.2f BPM", speed, tempo, real_bpm or 0)
            if error_msgs then
              vb.views.error_label1.text = error_msgs[1]
              vb.views.error_label2.text = error_msgs[2]
            else
              vb.views.error_label1.text = ""
              vb.views.error_label2.text = ""
            end
          end
        }
      },
      vb:column{
        vb:text{text="Tempo:"},
        vb:valuebox{min=32,max=255,value=tempo,
          notifier=function(val)
            tempo = val
            local calculated_bpm, error_msgs = calculate_bpm(speed, tempo)
            real_bpm = calculated_bpm
            vb.views.result_label.text = string.format("Speed %d Tempo %d is %.2f BPM", speed, tempo, real_bpm or 0)
            if error_msgs then
              vb.views.error_label1.text = error_msgs[1]
              vb.views.error_label2.text = error_msgs[2]
            else
              vb.views.error_label1.text = ""
              vb.views.error_label2.text = ""
            end
          end
        }
      }
    },

    -- Result Display
    vb:row{
      vb:text{id="result_label",text=string.format("Speed %d Tempo %d is %.2f BPM", speed, tempo, real_bpm)}
    },

    -- Error Display (split into two rows)
    vb:row{vb:text{id="error_label1",text="",style="strong",font="bold"}},
    vb:row{vb:text{id="error_label2",text="",style="strong",font="bold"}},
    
    -- Set BPM Button
    vb:row{
      vb:button{text="Set BPM",width=60,
        notifier=function()
          if not real_bpm then
            renoise.app():show_status("Cannot set BPM - value out of valid range (20 to 999)")
            return
          end
          renoise.song().transport.bpm = real_bpm
          renoise.app():show_status(string.format("BPM set to %.2f", real_bpm))
        end
      },
      vb:button{text="Close",width=60,
        notifier=function()
          if dialog and dialog.visible then
            dialog:close()
            dialog = nil
          end
        end
      }
    }
  }

  local keyhandler = create_keyhandler_for_dialog(
    function() return dialog end,
    function(value) dialog = value end
  )
  dialog = renoise.app():show_custom_dialog("Speed and Tempo to BPM",dialog_content,keyhandler)
  renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
end

renoise.tool():add_keybinding{name="Global:Paketti:Paketti Speed and Tempo to BPM Dialog...",invoke=pakettiSpeedTempoDialog}

-- Function to check if values exceed Renoise limits and adjust if needed
function adjustValuesForRenoiseLimits(F, K)
  local max_lpb = 256  -- Renoise's maximum LPB
  local max_pattern_length = 512  -- Renoise's maximum pattern length
  local original_F, original_K = F, K
  local divided = false
  
  -- Keep dividing by 2 until within limits
  while (F * K > max_lpb) or (F * K * 4 > max_pattern_length) do
    F = F / 2
    K = K / 2
    divided = true
  end
  
  if divided then
    local choice = renoise.app():show_prompt(
      "Time Signature Warning",
      string.format("Time signature %d/%d exceeds Renoise limits. Would you like to:\n" ..
                   "- Use reduced values (%d/%d)\n" ..
                   "- Enter a new time signature",
                   original_F, original_K, math.floor(F), math.floor(K)),
      {"Use Reduced", "New Time Signature"}
    )
    
    if choice == "New Time Signature" then
      return nil  -- Signal that we need new input
    end
  end
  
  return math.floor(F), math.floor(K)
end

-- Function to configure time signature settings
function configureTimeSignature(F, K)
  local song=renoise.song()
  
  -- Check and adjust values if they exceed limits
  local adjusted_F, adjusted_K = adjustValuesForRenoiseLimits(F, K)
  
  if not adjusted_F then
    -- User chose to enter new values
    renoise.app():show_status("Please select a different time signature")
    return
  end
  
  -- Apply the adjusted values
  F, K = adjusted_F, adjusted_K
  
  -- Calculate new values
  local new_lpb = F * K
  local new_pattern_length = F * K * 4
  
  -- Apply new values (BPM stays unchanged)
  song.transport.lpb = new_lpb
  song.selected_pattern.number_of_lines = new_pattern_length
  
  -- Get master track
  local master_track_index = song.sequencer_track_count + 1
  local master_track = song:track(master_track_index)
  local pattern = song.selected_pattern
  local master_track_pattern = pattern:track(master_track_index)
  local first_line = master_track_pattern:line(1)
  
  print("\n=== Debug Info ===")
  print("Visible effect columns:", master_track.visible_effect_columns)
  
  -- Find first empty effect column or create one if needed
  local found_empty_column = false
  local column_to_use = nil
  
  if master_track.visible_effect_columns == 0 then
    print("No effect columns visible, creating first one")
    master_track.visible_effect_columns = 1
    found_empty_column = true
    column_to_use = 1
  else
    -- Check existing effect columns for an empty one
    print("Checking existing effect columns:")
    for i = 1, master_track.visible_effect_columns do
      local effect_column = first_line:effect_column(i)
      print(string.format("Column %d: number_string='%s', amount_string='%s'", 
        i, effect_column.number_string, effect_column.amount_string))
      
      -- Check if both number and amount are "00" or empty
      if (effect_column.number_string == "" or effect_column.number_string == "00") and
         (effect_column.amount_string == "" or effect_column.amount_string == "00") then
        print("Found empty column at position", i)
        found_empty_column = true
        column_to_use = i
        break
      end
    end
  end
  
  -- If no empty column found among visible ones and we haven't reached the maximum, add a new one
  if not found_empty_column and master_track.visible_effect_columns < 8 then
    print("No empty columns found, adding new column at position", master_track.visible_effect_columns + 1)
    master_track.visible_effect_columns = master_track.visible_effect_columns + 1
    found_empty_column = true
    column_to_use = master_track.visible_effect_columns
  end
  
  if not found_empty_column then
    print("No empty columns available and can't add more")
    renoise.app():show_status("All Effect Columns on Master Track first row are filled, doing nothing.")
    return
  end
  
  print("Using column:", column_to_use)
  print("=== End Debug ===\n")
  
  -- Write LPB command to the found empty column
  first_line:effect_column(column_to_use).number_string = "ZL"
  first_line:effect_column(column_to_use).amount_string = string.format("%02X", new_lpb)
  
  -- Show confirmation message
  local message = string.format(
    "Time signature %d/%d configured: LPB=%d, Pattern Length=%d (BPM unchanged)",
    F, K, new_lpb, new_pattern_length
  )
  print(message)  -- Print to console
  renoise.app():show_status(message)
end

-- Function to show custom time signature dialog
function pakettiBeatStructureEditorDialog()
  -- Check if dialog is already open and close it
  if dialog and dialog.visible then
    dialog:close()
    dialog = nil
    return
  end
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  local function createPresetButton(text, F, K)
    return vb:button{
      text = text,
      width=60,
      notifier=function()
        vb.views.numerator.value = F
        vb.views.denominator.value = K
        renoise.app().window.active_middle_frame = 1
      end
    }
  end
  
  -- Declare updatePreview function before using it
  local function updatePreview()
    local F = tonumber(vb.views.numerator.value) or 0
    local K = tonumber(vb.views.denominator.value) or 0
    local lpb = F * K
    local pattern_length = F * K * 4
    local current_bpm = renoise.song().transport.bpm
    
    local warning = ""
    if lpb > 256 or pattern_length > 512 then
      warning = "\n\nWARNING: CANNOT USE THESE VALUES!\nEXCEEDS RENOISE LIMITS!"
    end
    
    vb.views.preview_text.text = string.format(
      "BPM: %d\n" ..
      "LPB: %d\n" ..
      "Pattern Length: %d%s",
      current_bpm, lpb, pattern_length, warning
    )
    vb.views.preview_text.style = "strong"
    renoise.app().window.active_middle_frame = 1
  end
  
  local function printTimeSignatureInfo()
    local current_bpm = renoise.song().transport.bpm
    
    print("\n=== AVAILABLE TIME SIGNATURES ===")
    print("Current preset buttons:")
    local presets = {
      {4,4}, {3,4}, {7,8}, {7,4}, {7,9},
      {2,5}, {3,5}, {8,5}, {9,5}, {8,10},
      {9,10}, {7,5}, {7,10}, {7,7}, {6,7}, {7,6}
    }
    
    for _, sig in ipairs(presets) do
      local F, K = sig[1], sig[2]
      local lpb = F * K
      local pattern_length = F * K * 4
      print(string.format("%d/%d: LPB=%d, Pattern Length=%d, BPM=%d", 
        F, K, lpb, pattern_length, current_bpm))
    end

    print("\n=== ALL POSSIBLE COMBINATIONS ===")
    for F = 1, 20 do
      for K = 1, 20 do
        local lpb = F * K
        local pattern_length = F * K * 4
        local warning = ""
        if lpb > 256 then warning = warning .. " [EXCEEDS LPB LIMIT]" end
        if pattern_length > 512 then warning = warning .. " [EXCEEDS PATTERN LENGTH LIMIT]" end
        
        if warning ~= "" then
          print(string.format("%d/%d: LPB=%d, Pattern Length=%d, BPM=%d%s", 
            F, K, lpb, pattern_length, current_bpm, warning))
        else
          print(string.format("%d/%d: LPB=%d, Pattern Length=%d, BPM=%d", 
            F, K, lpb, pattern_length, current_bpm))
        end
      end
    end
  end
  
  local dialog_content = vb:column{
    margin=DIALOG_MARGIN,
    spacing=CONTENT_SPACING,
    
    vb:horizontal_aligner{
      mode = "center",
      vb:row{
        spacing=CONTENT_SPACING,
        vb:text{text="Rows per Beat:" },
        vb:valuebox{
          id = "numerator",
          width=70,
          min = 1,
          max = 20,
          value = 4,
          notifier=function() updatePreview() end
        },
        vb:text{text="Beats per Pattern:" },
        vb:valuebox{
          id = "denominator",
          width=70,
          min = 1,
          max = 20,
          value = 4,
          notifier=function() updatePreview() end
        }
      }
    },
    
    vb:space { height = 10 },
    
    -- Common time signatures grid
    vb:column{
      style = "group",
      margin=DIALOG_MARGIN,
      spacing=CONTENT_SPACING,
      
      vb:text{text="Presets:" },
      
      -- Common time signatures first
      vb:row{
        spacing=CONTENT_SPACING,
        createPresetButton("4/4", 4, 4),
        createPresetButton("3/4", 3, 4),
        createPresetButton("5/4", 5, 4),
        createPresetButton("6/8", 6, 8),
        createPresetButton("9/8", 9, 8)
      },
      -- Septuple meters
      vb:row{
        spacing=CONTENT_SPACING,
        createPresetButton("7/4", 7, 4),
        createPresetButton("7/8", 7, 8),
        createPresetButton("7/9", 7, 9),
        createPresetButton("7/5", 7, 5),
        createPresetButton("7/6", 7, 6)
      },
      -- Other time signatures
      vb:row{
        spacing=CONTENT_SPACING,
        createPresetButton("2/5", 2, 5),
        createPresetButton("3/5", 3, 5),
        createPresetButton("8/5", 8, 5),
        createPresetButton("9/5", 9, 5),
        createPresetButton("7/7", 7, 7)
      },
      vb:row{
        spacing=CONTENT_SPACING,
        createPresetButton("8/10", 8, 10),
        createPresetButton("9/10", 9, 10),
        createPresetButton("7/10", 7, 10),
        createPresetButton("3/18", 3, 18),
        createPresetButton("4/14", 4, 14)
      },
    vb:column{
      id = "preview",
    --  style = "group",
    --  margin=DIALOG_MARGIN,
      
      vb:text{
        id = "preview_text",
        text = string.format(
          "BPM: %d\nLPB: %d\nPattern Length: %d",
          renoise.song().transport.bpm,
          renoise.song().transport.lpb,
          renoise.song().selected_pattern.number_of_lines
        )
      }}
    },
    
    vb:horizontal_aligner{
      mode = "center",
      vb:button{
        text="Apply",
        width=90,
        notifier=function()
          local F = tonumber(vb.views.numerator.value)
          local K = tonumber(vb.views.denominator.value)
          
          if not F or not K or F <= 0 or K <= 0 then
            renoise.app():show_warning("Please enter valid positive numbers")
            return
          end
          
          configureTimeSignature(F, K)
        end
      }
    }
  }
  
  printTimeSignatureInfo()  -- Add this before showing the dialog
  updatePreview()  -- Initial preview update
  local keyhandler = create_keyhandler_for_dialog(
    function() return dialog end,
    function(value) dialog = value end
  )
  dialog = renoise.app():show_custom_dialog("Beat Structure Editor",dialog_content,keyhandler)
  renoise.app().window.active_middle_frame = 1
end

renoise.tool():add_keybinding{name="Global:Paketti:Paketti Beat Structure Editor...",invoke=pakettiBeatStructureEditorDialog}
-------

-- Function to toggle columns with configurable options
function toggleColumns(include_sample_effects)
    local song=renoise.song()
    
    -- Check the first track's state to determine if we should show or hide
    local first_track = song.tracks[1]
    local should_show = not (
        first_track.volume_column_visible and
        first_track.panning_column_visible and
        first_track.delay_column_visible and
        (not include_sample_effects or first_track.sample_effects_column_visible)
    )
    
    -- Iterate through all tracks (except Master and Send tracks)
    for track_index = 1, song.sequencer_track_count do
        local track = song.tracks[track_index]
        -- Set all basic columns
        track.volume_column_visible = should_show
        track.panning_column_visible = should_show
        track.delay_column_visible = should_show
        -- Set sample effects based on parameter
        if include_sample_effects then
            track.sample_effects_column_visible = should_show
        else
            track.sample_effects_column_visible = false
        end
    end
    
    -- Show status message
    local message = should_show and 
        (include_sample_effects and "Showing all columns across all tracks" or 
                                  "Showing all columns except sample effects across all tracks") or 
        "Hiding all columns across all tracks"
    renoise.app():show_status(message)
end

renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle All Columns",invoke=function() toggleColumns(true) end}
renoise.tool():add_keybinding{name="Pattern Editor:Paketti:Toggle All Columns (No Sample Effects)",invoke=function() toggleColumns(false) end}