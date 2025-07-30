--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Pattern edit mode code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variable
-------------------------------------------------------------------------------
local edit_current_line = -1 --force update on init


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function edit_init()
  if renoise.tool().app_idle_observable:has_notifier(edit_idle_hook) == false then
    renoise.tool().app_idle_observable:add_notifier(edit_idle_hook)
  end
  if renoise.song().transport.octave_observable:has_notifier(edit_octave_change_hook) == false then
    renoise.song().transport.octave_observable:add_notifier(edit_octave_change_hook)
  end
  if renoise.song().selected_instrument_index_observable:has_notifier(edit_inst_change_hook) == false then
    renoise.song().selected_instrument_index_observable:add_notifier(edit_inst_change_hook)
  end
  if renoise.song().selected_instrument.name_observable:has_notifier(edit_inst_change_hook) == false then
    renoise.song().selected_instrument.name_observable:add_notifier(edit_inst_change_hook)
  end
  if renoise.song().transport.wrapped_pattern_edit_observable:has_notifier(edit_patternwrap_hook) == false then
    renoise.song().transport.wrapped_pattern_edit_observable:add_notifier(edit_patternwrap_hook)
  end
  if renoise.song().transport.chord_mode_enabled_observable:has_notifier(edit_chordmode_hook) == false then
    renoise.song().transport.chord_mode_enabled_observable:add_notifier(edit_chordmode_hook)
  end
  if renoise.song().transport.record_quantize_enabled_observable:has_notifier(edit_quantize_hook) == false then
    renoise.song().transport.record_quantize_enabled_observable:add_notifier(edit_quantize_hook)
  end
  if renoise.song().transport.record_quantize_lines_observable:has_notifier(edit_quantize_lines_hook) == false then
    renoise.song().transport.record_quantize_lines_observable:add_notifier(edit_quantize_lines_hook)
  end
  if renoise.song().transport.metronome_enabled_observable:has_notifier(edit_metronome_hook) == false then
    renoise.song().transport.metronome_enabled_observable:add_notifier(edit_metronome_hook)
  end 
  if renoise.song().selected_pattern_index_observable:has_notifier(edit_pattern_change_hook) == false then
    renoise.song().selected_pattern_index_observable:add_notifier(edit_pattern_change_hook)
  end  
  if renoise.song().transport.bpm_observable:has_notifier(edit_bpm_delay_change_hook) == false then
    renoise.song().transport.bpm_observable:add_notifier(edit_bpm_delay_change_hook)
  end  
  
  -- leds
  led_on(LED_SEND)
  edit_patternwrap_hook()
  edit_chordmode_hook()
  edit_quantize_hook()
  edit_metronome_hook()
  -- lcd display
  clear_display()
  edit_octave_change_hook()
  edit_inst_change_hook()
  edit_pattern_change_hook()  --force update
  -- mode state
  current_mode = MODE_EDIT
end


function edit_exit()
  if renoise.tool().app_idle_observable:has_notifier(edit_idle_hook) == true then
    renoise.tool().app_idle_observable:remove_notifier(edit_idle_hook)
  end
  if renoise.song().transport.octave_observable:has_notifier(edit_octave_change_hook) == true then
    renoise.song().transport.octave_observable:remove_notifier(edit_octave_change_hook)
  end
  if renoise.song().selected_instrument_index_observable:has_notifier(edit_inst_change_hook) == true then
    renoise.song().selected_instrument_index_observable:remove_notifier(edit_inst_change_hook)
  end
  if renoise.song().selected_instrument.name_observable:has_notifier(edit_inst_change_hook) == true then
    renoise.song().selected_instrument.name_observable:remove_notifier(edit_inst_change_hook)
  end
  if renoise.song().transport.wrapped_pattern_edit_observable:has_notifier(edit_patternwrap_hook) == true then
    renoise.song().transport.wrapped_pattern_edit_observable:remove_notifier(edit_patternwrap_hook)
  end
  if renoise.song().transport.chord_mode_enabled_observable:has_notifier(edit_chordmode_hook) == true then
    renoise.song().transport.chord_mode_enabled_observable:remove_notifier(edit_chordmode_hook)
  end
  if renoise.song().transport.record_quantize_enabled_observable:has_notifier(edit_quantize_hook) == true then
    renoise.song().transport.record_quantize_enabled_observable:remove_notifier(edit_quantize_hook)
  end
  if renoise.song().transport.record_quantize_lines_observable:has_notifier(edit_quantize_lines_hook) == true then
    renoise.song().transport.record_quantize_lines_observable:remove_notifier(edit_quantize_lines_hook)
  end
  if renoise.song().transport.metronome_enabled_observable:has_notifier(edit_metronome_hook) == true then
    renoise.song().transport.metronome_enabled_observable:remove_notifier(edit_metronome_hook)
  end 
  if renoise.song().selected_pattern_index_observable:has_notifier(edit_pattern_change_hook) == true then
    renoise.song().selected_pattern_index_observable:remove_notifier(edit_pattern_change_hook)
  end
  if renoise.song().transport.bpm_observable:has_notifier(edit_bpm_delay_change_hook) == true then
    renoise.song().transport.bpm_observable:remove_notifier(edit_bpm_delay_change_hook)
  end
    
  -- turn off leds that are used in this mode
  led_off(LED_SEND)
  led_off(LED_F1)
  led_off(LED_F2)
  led_off(LED_F3)
  led_off(LED_F4)
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function edit_octave_change_hook()
  display_message(string.format("O:%1u", renoise.song().transport.octave), 13)
end


function edit_inst_change_hook()
  local n = string.sub(renoise.song().selected_instrument.name, 1, 13)
  local l = string.len(n)
  if l < 13 then
    for i = 1,(13-l) do
      n = n .. " "
    end
  end
  lower_display_hold_cancel()
  display_message(string.format("%.2X",
                                renoise.song().selected_instrument_index - 1)
                  .. ":" .. n, 16)
end


function edit_idle_hook()
  -- TODO: hacky work around
  if renoise.song().transport.playback_pos.line ~= edit_current_line then
    edit_current_line = renoise.song().transport.playback_pos.line
    display_message(string.format("%03u",renoise.song().selected_pattern_index-1)
                    .. "."
                    .. string.format("%03u", edit_current_line - 1)
                    .. "/"
                    .. string.format("%03u",
                                 renoise.song().selected_pattern.number_of_lines
                                   - 1), 0)
  end
end


function edit_patternwrap_hook()
  if renoise.song().transport.wrapped_pattern_edit == true then
    led_on(LED_F1)
  else
    led_off(LED_F1)
  end
end


function edit_chordmode_hook()
  if renoise.song().transport.chord_mode_enabled == true then
    led_on(LED_F2)
  else
    led_off(LED_F2)
  end
end


function edit_quantize_hook()
  if renoise.song().transport.record_quantize_enabled == true then
    led_on(LED_F3)
  else
    led_off(LED_F3)
  end
end


function edit_quantize_lines_hook()
  -- show on display
  lower_display_hold_cancel()
  display_message(string.format("Record Quant: %02u", renoise.song().transport.record_quantize_lines), 16)
  lower_display_hold()
end


function edit_metronome_hook()
  if renoise.song().transport.metronome_enabled == true then
    led_on(LED_F4)
  else
    led_off(LED_F4)
  end
end


function edit_pattern_change_hook()
  edit_current_line = -1
  edit_idle_hook()
end


function edit_bpm_delay_change_hook()
  lower_display_hold_cancel()
  display_message(string.format("BPM:%03u         ", renoise.song().transport.bpm), 16)
  lower_display_hold()
end


--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------
function edit_button(button)
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
  elseif button == BUTTON_ENC2TOUCH then
    if shifted == SHIFT_OFF then
      edit_quantize_lines_hook()
    end
  --[[ no action required (always on lcd)
  elseif button == BUTTON_ENC1TOUCH then
    --     ]]-- 
  elseif button == BUTTON_ENC3TOUCH then
    if shifted == SHIFT_ON then
      edit_bpm_delay_change_hook()
    end
  end
end


function edit_encoder(encoderid, value)
  if encoderid == ENC_LEFT then
    if shifted == SHIFT_OFF then
      -- select instrument
      local i = renoise.song().selected_instrument_index + value
      if i < 1 then
        i = 1
      elseif i > #renoise.song().instruments then
        i = #renoise.song().instruments
      end
      renoise.song().selected_instrument_index = i
    elseif shifted == SHIFT_ON then
      -- select pattern in sequence slot
      local p = renoise.song().selected_pattern_index + value
      if p < 1 then
        p = 1
      elseif p > # renoise.song().patterns then
        p = # renoise.song().patterns
      end
      renoise.song().selected_pattern_index = p
    end
  elseif encoderid == ENC_MIDDLE then
    if shifted == SHIFT_OFF then
      -- set record quantize amount
      local q = renoise.song().transport.record_quantize_lines + value
      if q < 1 then
        q = 1
      elseif q > 32 then
        q = 32
      end
      renoise.song().transport.record_quantize_lines = q
    elseif shifted == SHIFT_ON then
      -- set pattern length in beats
      local l = math.floor(renoise.song().selected_pattern.number_of_lines/renoise.song().transport.lpb) + value
      
      if l < 1 then
        l = 1
      elseif (l*renoise.song().transport.lpb) > 512 then
        l = math.floor(512/renoise.song().transport.lpb)
      end
      renoise.song().selected_pattern.number_of_lines = l * renoise.song().transport.lpb
      lower_display_hold_cancel()
      display_message("PatLen(beats):" .. string.format("%02u", l),16)
      lower_display_hold()
    end
  elseif encoderid == ENC_RIGHT then
    if shifted == SHIFT_OFF then
      -- change octave
      local o = renoise.song().transport.octave + value
      if o < 0 then
        o = 0
      elseif o > 8 then
        o = 8
      end
      renoise.song().transport.octave = o
    elseif shifted == SHIFT_ON then
      -- set the song bpm
      local bpm = renoise.song().transport.bpm + value
      if bpm < 32 then
        bpm = 32
      elseif bpm > 999 then
        bpm = 999
      end
      renoise.song().transport.bpm = bpm
    end
  end
end


function edit_upper_display_release()
  -- redraw top lcd line
  edit_idle_hook()
  edit_octave_change_hook()
end


function edit_lower_display_release()
  -- redraw bottom lcd line
  edit_inst_change_hook()
end
