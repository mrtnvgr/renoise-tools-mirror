--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Mix mode code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variable
-------------------------------------------------------------------------------
local mix_current_line = -1 -- force update on init


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function mix_init()
  if renoise.tool().app_idle_observable:has_notifier(edit_idle_hook) == false then
    renoise.tool().app_idle_observable:add_notifier(edit_idle_hook)
  end
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(mix_vol_pan_change_hook) == false then
    renoise.song().selected_track.prefx_volume.value_observable:add_notifier(mix_vol_pan_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(mix_vol_pan_change_hook) == false then
    renoise.song().selected_track.prefx_panning.value_observable:add_notifier(mix_vol_pan_change_hook)
  end
  if renoise.song().selected_track_index_observable:has_notifier(mix_track_change_hook) == false then
    renoise.song().selected_track_index_observable:add_notifier(mix_track_change_hook)
  end
  if renoise.song().transport.wrapped_pattern_edit_observable:has_notifier(mix_patternwrap_hook) == false then
    renoise.song().transport.wrapped_pattern_edit_observable:add_notifier(mix_patternwrap_hook)
  end
  if renoise.song().transport.chord_mode_enabled_observable:has_notifier(mix_chordmode_hook) == false then
    renoise.song().transport.chord_mode_enabled_observable:add_notifier(mix_chordmode_hook)
  end
  if renoise.song().transport.record_quantize_enabled_observable:has_notifier(mix_quantize_hook) == false then
    renoise.song().transport.record_quantize_enabled_observable:add_notifier(mix_quantize_hook)
  end
  if renoise.song().transport.metronome_enabled_observable:has_notifier(mix_metronome_hook) == false then
    renoise.song().transport.metronome_enabled_observable:add_notifier(mix_metronome_hook)
  end 
  if renoise.song().selected_pattern_index_observable:has_notifier(mix_pattern_change_hook) == false then
    renoise.song().selected_pattern_index_observable:add_notifier(mix_pattern_change_hook)
  end
  if renoise.song().selected_track.output_delay_observable:has_notifier(mix_bpm_delay_change_hook) == false then
    renoise.song().selected_track.output_delay_observable:add_notifier(mix_bpm_delay_change_hook)
  end
  if renoise.song().transport.bpm_observable:has_notifier(mix_bpm_delay_change_hook) == false then
    renoise.song().transport.bpm_observable:add_notifier(mix_bpm_delay_change_hook)
  end
  
  -- leds
  led_on(LED_PAN)
  mix_patternwrap_hook()
  mix_chordmode_hook()
  mix_quantize_hook()
  mix_metronome_hook()
  -- lcd display
  clear_display()
  mix_pattern_change_hook() --force update
  mix_track_change_hook()
  mix_vol_pan_change_hook()
  -- mode state
  current_mode = MODE_MIX
end


function mix_exit()
  if renoise.tool().app_idle_observable:has_notifier(mix_idle_hook) == true then
    renoise.tool().app_idle_observable:remove_notifier(mix_idle_hook)
  end
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(mix_vol_pan_change_hook) == true then
    renoise.song().selected_track.prefx_volume.value_observable:remove_notifier(mix_vol_pan_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(mix_vol_pan_change_hook) == true then
    renoise.song().selected_track.prefx_panning.value_observable:remove_notifier(mix_vol_pan_change_hook)
  end
  if renoise.song().selected_track_index_observable:has_notifier(mix_track_change_hook) == true then
    renoise.song().selected_track_index_observable:remove_notifier(mix_track_change_hook)
  end
  if renoise.song().transport.wrapped_pattern_edit_observable:has_notifier(mix_patternwrap_hook) == true then
    renoise.song().transport.wrapped_pattern_edit_observable:remove_notifier(mix_patternwrap_hook)
  end
  if renoise.song().transport.chord_mode_enabled_observable:has_notifier(mix_chordmode_hook) == true then
    renoise.song().transport.chord_mode_enabled_observable:remove_notifier(mix_chordmode_hook)
  end
  if renoise.song().transport.record_quantize_enabled_observable:has_notifier(mix_quantize_hook) == true then
    renoise.song().transport.record_quantize_enabled_observable:remove_notifier(mix_quantize_hook)
  end
  if renoise.song().transport.metronome_enabled_observable:has_notifier(mix_metronome_hook) == true then
    renoise.song().transport.metronome_enabled_observable:remove_notifier(mix_metronome_hook)
  end 
  if renoise.song().selected_pattern_index_observable:has_notifier(mix_pattern_change_hook) == true then
    renoise.song().selected_pattern_index_observable:remove_notifier(mix_pattern_change_hook)
  end
  if renoise.song().selected_track.output_delay_observable:has_notifier(mix_bpm_delay_change_hook) == true then
    renoise.song().selected_track.output_delay_observable:remove_notifier(mix_bpm_delay_change_hook)
  end
  if renoise.song().transport.bpm_observable:has_notifier(mix_bpm_delay_change_hook) == true then
    renoise.song().transport.bpm_observable:remove_notifier(mix_bpm_delay_change_hook)
  end
  
  -- turn off leds that are used in this mode
  led_off(LED_PAN)
  led_off(LED_F1)
  led_off(LED_F2)
  led_off(LED_F3)
  led_off(LED_F4)
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function mix_track_change_hook()
  display_message(string.format("T:%02u", renoise.song().selected_track_index - 1), 12)
  
  -- bind to new track
  if renoise.song().selected_track.output_delay_observable:has_notifier(mix_bpm_delay_change_hook) == false then
    renoise.song().selected_track.output_delay_observable:add_notifier(mix_bpm_delay_change_hook)
  end
  if renoise.song().transport.bpm_observable:has_notifier(mix_bpm_delay_change_hook) == false then
    renoise.song().transport.bpm_observable:add_notifier(mix_bpm_delay_change_hook)
  end
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(mix_vol_pan_change_hook) == false then
    renoise.song().selected_track.prefx_volume.value_observable:add_notifier(mix_vol_pan_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(mix_vol_pan_change_hook) == false then
    renoise.song().selected_track.prefx_panning.value_observable:add_notifier(mix_vol_pan_change_hook)
  end
end


function mix_idle_hook()
  -- TODO: hacky work around
  if renoise.song().transport.playback_pos.line ~= mix_current_line then
    mix_current_line = renoise.song().transport.playback_pos.line
    display_message(string.format("%03u",renoise.song().selected_pattern_index-1)
                    .. "."
                    .. string.format("%03u", mix_current_line - 1)
                    .. "/"
                    .. string.format("%03u",
                                 renoise.song().selected_pattern.number_of_lines
                                   - 1), 0)
  end
end


function mix_vol_pan_change_hook()
  local v = math.lin2db(renoise.song().selected_track.prefx_volume.value)
  local p = renoise.song().selected_track.prefx_panning.value
  local p_str  = "Ctr"
  local v_str
  
  if v < -99.99 then
    v_str = "-INF dB"
  else
    v_str = string.format("%+6.2f", v) .. "dB"
  end
  
  if p < 0.495 then
    p = 0.505 - p
    p_str = string.format("%02u", p*100) .. "L"
  elseif p > 0.505 then
    p = p - 0.495
    p_str = string.format("%02u", p*100) .. "R"
  end
  lower_display_hold_cancel()
  display_message("V:" .. v_str .. " P:" .. p_str, 16)
end

function mix_patternwrap_hook()
  if renoise.song().transport.wrapped_pattern_edit == true then
    led_on(LED_F1)
  else
    led_off(LED_F1)
  end
end


function mix_chordmode_hook()
  if renoise.song().transport.chord_mode_enabled == true then
    led_on(LED_F2)
  else
    led_off(LED_F2)
  end
end


function mix_quantize_hook()
  if renoise.song().transport.record_quantize_enabled == true then
    led_on(LED_F3)
  else
    led_off(LED_F3)
  end
end


function mix_metronome_hook()
  if renoise.song().transport.metronome_enabled == true then
    led_on(LED_F4)
  else
    led_off(LED_F4)
  end
end


function mix_pattern_change_hook()
  mix_current_line = -1
  mix_idle_hook()
end


function mix_bpm_delay_change_hook()
  lower_display_hold_cancel()
  display_message(string.format("BPM:%03u ", renoise.song().transport.bpm)
                  .. string.format("D:%+04.0fms",
                  renoise.song().selected_track.output_delay), 16)
  lower_display_hold()
end


--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------
function mix_button(button)
  if button == BUTTON_F1 then
    renoise.song().transport.wrapped_pattern_edit =
      (not renoise.song().transport.wrapped_pattern_edit)
  elseif button == BUTTON_F2 then
    renoise.song().transport.chord_mode_enabled =
      (not renoise.song().transport.chord_mode_enabled)
  elseif button == BUTTON_F3 then
    renoise.song().transport.record_quantize_enabled =
      (not renoise.song().transport.record_quantize_enabled)
  elseif button == BUTTON_F4 then
    renoise.song().transport.metronome_enabled =
    (not renoise.song().transport.metronome_enabled)
  elseif button == BUTTON_ENC1TOUCH then
    mix_bpm_delay_change_hook() -- display bpm/delay
  elseif button == BUTTON_ENC2TOUCH then
    mix_bpm_delay_change_hook() -- display bpm/delay
  elseif button == BUTTON_ENC3TOUCH then
    mix_vol_pan_change_hook() -- display vol/pan
  end
end


function mix_encoder(encoderid, value)
  if encoderid == ENC_LEFT then
    -- set the song bpm
    local bpm = renoise.song().transport.bpm + value
    if bpm < 32 then
      bpm = 32
    elseif bpm > 999 then
      bpm = 999
    end
    renoise.song().transport.bpm = bpm
  elseif encoderid == ENC_MIDDLE then
    -- change the track delay
    if renoise.song().selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      local d = renoise.song().selected_track.output_delay + value
      if d < -100 then
        d = -100
      elseif d > 100 then
        d = 100
      end
      renoise.song().selected_track.output_delay = d
    end
  elseif encoderid == ENC_RIGHT then
    -- set track panning or volume
    if fader_flipped == false then
      -- pan
      local p = tonumber(string.format("%.2f",
                         renoise.song().selected_track.prefx_panning.value))
                         + value/100
      if p > 1 then
        p = 1
      elseif p < 0 then
        p = 0
      end
      renoise.song().selected_track.prefx_panning.value = p
    else
      -- volume
      local v = tonumber(string.format("%.2f",
                         renoise.song().selected_track.prefx_volume.value))
                         + value/141.3
      if v > 1.4125375747681 then
        v = 1.4125375747681
      elseif v < 0 then
        v = 0
      end
      renoise.song().selected_track.prefx_volume.value = v
    end
  end
end


function mix_upper_display_release()
  mix_idle_hook()
  mix_track_change_hook()
end


function mix_lower_display_release()
  mix_vol_pan_change_hook()
end
