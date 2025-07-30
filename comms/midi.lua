--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Midi code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
MSG_BUTTON = 0x90
MSG_ENCODER = 0xB0
MSG_FADER = 0xE0
MSG_STRIP = 0xE9


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
midi_note_names = {"C-", "C#", "D-", "D#", "E-", "F-",
                   "F#", "G-", "G#", "A-", "A#", "B-"}


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
connected = false
midi_in_device = nil
midi_out_device = nil
is_recording_fader = false


--------------------------------------------------------------------------------
-- I/O Functions
--------------------------------------------------------------------------------
function connect()
  -- Connect to an attached AlphaTrack
  -- Enumerate all available midi ports and if we find our AlphaTrack port
  -- connect to it and bind the device variables
  if midi_in_device == nil then
    if os.platform() == "WINDOWS" then
      local input_devices = renoise.Midi.available_input_devices()
      if table.find(input_devices, "AlphaTrack") then
        midi_in_device = renoise.Midi.create_input_device("AlphaTrack",
                              midi_callback, sysex_callback)
      else
        connected = false
        midi_in_device = nil
        return
      end
    end
  end
  
  if midi_out_device == nil then
    if os.platform() == "WINDOWS" then
      local output_devices = renoise.Midi.available_output_devices()
      if table.find(output_devices, "AlphaTrack") then
        midi_out_device = renoise.Midi.create_output_device("AlphaTrack")
      else
        midi_in_device:close()
        midi_in_device = nil
        midi_out_device = nil
        connected = false
        return
      end
    end
  end
  
  -- We are up an running, change state to indicate so
  connected = true
  
  -- Inform the user we were successful
  renoise.app():show_status("AlphaTrack: Connected successfully.")
end


function disconnect()
  -- Disconnect from an attached AlphaTrack
  if midi_in_device ~= nil then
    midi_in_device:close()
  end
  if midi_out_device ~= nil then
    midi_out_device:close()
  end
  midi_in_device = nil
  midi_out_device = nil
  connected = false
  
  -- Inform the user we were successful
  renoise.app():show_status("AlphaTrack: Disconnected successfully.")
end


--------------------------------------------------------------------------------
-- Midi handlers
--------------------------------------------------------------------------------
function midi_callback(midi_message)
  -- Parse the recieved midi message and forward to the correct function
  if midi_message[1] == MSG_BUTTON then           -- button
    if midi_message[3] == 0x7F then               -- pressed
      local button = midi_message[2]
      
      -- unshifted commands
      if shifted == SHIFT_OFF then
        -- common button handlers
        if button == BUTTON_SOLO then
          -- solo track
          renoise.song().selected_track:solo()
        elseif button == BUTTON_MUTE then
          -- mute track
          if renoise.song().selected_track.mute_state == 1 then
            renoise.song().selected_track:mute()
          else
            renoise.song().selected_track:unmute()
          end
        elseif button == BUTTON_SHIFT then
          -- enter shift mode
          shifted = SHIFT_ON
          led_on(LED_SHIFT)
        elseif button == BUTTON_REW then
          -- previous pattern
          local s = renoise.song().transport.playback_pos
          s.sequence = s.sequence - 1
          if s.sequence > renoise.song().transport.song_length.sequence then
            s.sequence = renoise.song().transport.song_length.sequence
          elseif s.sequence < 1 then
            s.sequence = 1
          end
          renoise.song().transport.edit_pos = s
        elseif button == BUTTON_FFWD then
          -- next pattern
          local s = renoise.song().transport.playback_pos
          s.sequence = s.sequence + 1
          if s.sequence > renoise.song().transport.song_length.sequence then
            s.sequence = renoise.song().transport.song_length.sequence
          elseif s.sequence < 1 then
            s.sequence = 1
          end
          renoise.song().transport.edit_pos = s
        elseif button == BUTTON_STOP then
          -- stop
          if renoise.song().transport.playing == true then
            renoise.song().transport:stop()
          else
            local p = renoise.song().transport.edit_pos
            p.line = 1
            renoise.song().transport.edit_pos = p
            renoise.song().transport.playback_pos = p
          end
        elseif button == BUTTON_PLAY then
          -- play
          renoise.song().transport:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
        elseif button == BUTTON_RECORD then
          -- editmode toggle
          renoise.song().transport.edit_mode =(not renoise.song().transport.edit_mode)
        elseif button == BUTTON_TRACKL then
          -- previous track (wraparound)
          local i = renoise.song().selected_track_index - 1
          if i > # renoise.song().tracks then
            i = 1
          elseif i < 1 then
            i = # renoise.song().tracks
          end
          renoise.song().selected_track_index = i
        elseif button == BUTTON_TRACKR then
          -- next track (wraparound)
          local i = renoise.song().selected_track_index + 1
          if i > # renoise.song().tracks then
            i = 1
          elseif i < 1 then
            i = # renoise.song().tracks
          end
          renoise.song().selected_track_index = i
        elseif button == BUTTON_LOOP then
          -- pattern loop
          renoise.song().transport.loop_pattern =
          (not renoise.song().transport.loop_pattern)
        elseif button == BUTTON_FLIP then
          -- fader flip
          fader_flipped = (not fader_flipped)
          if fader_flipped == true then
            led_on(LED_FLIP)
            common_pan_change_hook()
          else
            led_off(LED_FLIP)
            common_volume_change_hook()
          end
        elseif button == BUTTON_RECARM then
          -- record automation
          is_recording_fader = (not is_recording_fader)
          if is_recording_fader == true then
            led_on(LED_RECARM)
          else
            led_off(LED_RECARM)
          end
         -- mode selection
        elseif button == BUTTON_PAN then
          if current_mode == MODE_MIX then
            return -- do nothing
          elseif current_mode == MODE_EDIT then
            edit_exit()
            mix_init()
          elseif current_mode == MODE_DSP then
            dsp_exit()
            mix_init()
          elseif current_mode == MODE_SAMP then
            samp_exit()
            mix_init()
          elseif current_mode == MODE_INST then
            --inst_exit()
            --mix_init()
          end
        elseif button == BUTTON_SEND then
          if current_mode == MODE_MIX then
            mix_exit()
            edit_init()
          elseif current_mode == MODE_EDIT then
            return -- do nothing
          elseif current_mode == MODE_DSP then
            dsp_exit()
            edit_init()
          elseif current_mode == MODE_SAMP then
            samp_exit()
            edit_init()
          elseif current_mode == MODE_INST then
            --inst_exit()
            --edit_init()
          end
        elseif button == BUTTON_EQ then
          if current_mode == MODE_MIX then
            mix_exit()
            dsp_init()
          elseif current_mode == MODE_EDIT then
            edit_exit()
            dsp_init()
          elseif current_mode == MODE_DSP then
            return -- do nothing
          elseif current_mode == MODE_SAMP then
            samp_exit()
            dsp_init()
          elseif current_mode == MODE_INST then
            --inst_exit()
            --dsp_init()
          end
          
        elseif button == BUTTON_PLUGIN then
          if current_mode == MODE_MIX then
            mix_exit()
            samp_init()
          elseif current_mode == MODE_EDIT then
            edit_exit()
            samp_init()
          elseif current_mode == MODE_DSP then
            dsp_exit()
            samp_init()
          elseif current_mode == MODE_SAMP then
            return -- do nothing
          elseif current_mode == MODE_INST then
            --inst_exit()
            --samp_init()
          end
          
        elseif button == BUTTON_AUTO then
          if current_mode == MODE_MIX then
            --mix_exit()
            --inst_init()
          elseif current_mode == MODE_EDIT then
            --edit_exit()
            --inst_init()
          elseif current_mode == MODE_DSP then
            --dsp_exit()
            --inst_init()
          elseif current_mode == MODE_SAMP then
            --samp_exit()
            --inst_init()
          elseif current_mode == MODE_INST then
            return -- do nothing
          end
        end
        
        -- mode specific button - pass through to mode handler
        if current_mode == MODE_MIX then
          mix_button(button)
        elseif current_mode == MODE_EDIT then
          edit_button(button)
        elseif current_mode == MODE_DSP then
          dsp_button(button)
        elseif current_mode == MODE_SAMP then
          samp_button(button)
        elseif current_mode == MODE_INST then
          --inst_button(button)
        end
        
      elseif shifted == SHIFT_ON then
        -- shifted commands
        if button == BUTTON_SHIFT then
          -- shift toggle
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_FLIP then
          -- 'view' mode
          shifted = SHIFT_VIEW
        elseif button == BUTTON_REW then
          -- undo
          renoise.song():undo()
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_FFWD then
          -- redo
          renoise.song():redo()
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_STOP then
          -- jump to start of song
          local p = renoise.song().transport.edit_pos
          p.line = 1
          p.sequence = 1
          renoise.song().transport.edit_pos = p
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_TRACKR then
          -- insert new track
          local i = renoise.song().selected_track_index + 1
          renoise.song():insert_track_at(i)
          renoise.song().selected_track_index = i
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_TRACKL then
          -- delete current track
          if #renoise.song().tracks > 2 then
            if renoise.song().selected_track.type ~= renoise.Track.TRACK_TYPE_MASTER then
              renoise.song():delete_track_at(renoise.song().selected_track_index)
              shifted = SHIFT_OFF
              led_off(LED_SHIFT)
            end
          end
        elseif button == BUTTON_RECARM then
          -- clear automation if it exists
          local param
          local automation
          if fader_flipped == true then
            -- pan
            param=renoise.song().selected_track.devices[1].parameters[1]
          else
            -- vol
            param=renoise.song().selected_track.devices[1].parameters[2]
          end
          automation = renoise.song().selected_pattern.tracks[renoise.song().selected_track_index]:find_automation(param)
          if automation ~= nil then
            automation:clear()
          end
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        else
          -- mode specific button - pass through to mode handler
          if current_mode == MODE_MIX then
            mix_button(button)
          elseif current_mode == MODE_EDIT then
            edit_button(button)
          elseif current_mode == MODE_DSP then
            dsp_button(button)
          elseif current_mode == MODE_SAMP then
            samp_button(button)
          elseif current_mode == MODE_INST then
            --inst_button(button)
          end
        end
      elseif shifted == SHIFT_VIEW then
        -- shifted view commands
        if button == BUTTON_SHIFT then
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_F1 then
          renoise.app().window:select_preset(1)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_F2 then
          renoise.app().window:select_preset(2)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_F3 then
          renoise.app().window:select_preset(3)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_F4 then
          renoise.app().window:select_preset(4)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_TRACKL then
          renoise.app().window:select_preset(5)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_TRACKR then
          renoise.app().window:select_preset(6)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_LOOP then
          renoise.app().window:select_preset(7)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        elseif button == BUTTON_FLIP then
          renoise.app().window:select_preset(8)
          shifted = SHIFT_OFF
          led_off(LED_SHIFT)
        end
      end
    end
  elseif midi_message[1] == MSG_ENCODER then      -- encoder
    if current_mode == MODE_MIX then
      mix_encoder(midi_message[2], enc_to_rel(midi_message[3]))
    elseif current_mode == MODE_EDIT then
      edit_encoder(midi_message[2], enc_to_rel(midi_message[3]))
    elseif current_mode == MODE_DSP then
      dsp_encoder(midi_message[2], enc_to_rel(midi_message[3]))
    elseif current_mode == MODE_SAMP then
      samp_encoder(midi_message[2], enc_to_rel(midi_message[3]))
    elseif current_mode == MODE_INST then
      --inst_encoder(midi_message[2], enc_to_rel(midi_message[3]))
    end
  elseif midi_message[1] == MSG_FADER then        -- fader (common)
    -- TODO: automation recording
    if is_recording_fader == true then
      local param
      local automation
      if fader_flipped == true then
        -- pan
        param=renoise.song().selected_track.devices[1].parameters[1]
      else
        -- vol
        param=renoise.song().selected_track.devices[1].parameters[2]
      end
      
      automation = renoise.song().selected_pattern.tracks[renoise.song().selected_track_index]:find_automation(param)
      
      if automation == nil then
        -- create automation
        automation = renoise.song().selected_pattern.tracks[renoise.song().selected_track_index]:create_automation(param)
      end
      
      automation:add_point_at(renoise.song().transport.edit_pos.line,
                              fader_to_value(midi_message[2], midi_message[3]) / 1023)
      
    else
      -- just update the current setings
      if fader_flipped == true then
        renoise.song().selected_track.prefx_panning.value =
        fader_to_value(midi_message[2], midi_message[3]) / 1023
      else
        renoise.song().selected_track.prefx_volume.value =
        fader_to_value(midi_message[2], midi_message[3]) * 1.4125375747681 / 1023
      end
    end
  elseif midi_message[1] == MSG_STRIP then        -- touch strip (common)
    -- move the current cursor in the pattern relatively
    -- play position should auto update if single edit/play position enabled
    local edit_pos = renoise.song().transport.edit_pos
    local pat_len = renoise.song().selected_pattern.number_of_lines
    edit_pos.line = edit_pos.line + strip_abs_to_rel(midi_message[3])
    if edit_pos.line < 1 then
      edit_pos.line = 1
    elseif edit_pos.line > pat_len then
      edit_pos.line = pat_len
    end
    renoise.song().transport.edit_pos = edit_pos
  end
end


function sysex_callback(midi_message)
  -- We don't need to handle recieved sysex messages 
end


--------------------------------------------------------------------------------
-- Misc functions
--------------------------------------------------------------------------------
function midi_note_number_to_name(midi_number)
  -- Convert a specified midi note number to the same text as would be
  -- displayed in the pattern editor (3chars)
  local oct = math.floor(midi_number/12)
  return midi_note_names[(midi_number - (12 * oct))+1] .. tostring(oct)
end
