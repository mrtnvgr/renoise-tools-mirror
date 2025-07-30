--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Edit Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'InstEditMode' (BaseMode)

--[[
  self.sample = renoise.song().selected_sample
  self.slice_bank = 0..1
]]--


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function InstEditMode:encoder(delta)
  -- handle encoder turns
  if prompt then
    prompt:encoder(delta)
  else
    renoise.song().selected_sample_index =
      clamp(renoise.song().selected_sample_index + delta,
            1, #renoise.song().selected_instrument.samples)
    set_lcd(string.format("S%02x", renoise.song().selected_sample_index), true)
  end
end


function InstEditMode:button(button_id)
  -- handle button press events
  
  -- pass button events to prompt if required
  if prompt then
    if button_id == BTN_SETTING then
      prompt:ok()
      return
    elseif button_id == BTN_X then
      prompt:func_x()
      return
    elseif button_id == BTN_Y then
      prompt:func_y()
      return
    elseif button_id == BTN_PEDAL then
      prompt:func_z()
      return
    end
  end
  
  local rs = renoise.song()
  
  if button_id == BTN_SETTING then
    -- sample edit mode
    set_mode(MODE_SAMP)
  
  elseif button_id == BTN_X then
    -- clone sample slot
    if self.sliced_instrument then
      return
    else
      local inst = renoise.song().selected_instrument
      local si = renoise.song().selected_sample_index
      -- duplicate sample
      local new_samp = inst:insert_sample_at(si+1)
      new_samp:copy_from(renoise.song().selected_sample)
      -- find sample mapping
      local index = -1
      for i = 1, #inst.sample_mappings[1] do
        if inst.sample_mappings[1][i].sample_index == si then
          index = i
        end
      end
      -- duplicate sample mapping
      if index ~= -1 then
        local map = inst.sample_mappings[1][index]
         inst:insert_sample_mapping(1, si+1, map.base_note,
                                    map.note_range,
                                    map.velocity_range)
      end
      renoise.song().selected_sample_index = si + 1
    end
    set_led(LED_X, LED_FLASH)
    
  elseif button_id == BTN_Y then
    -- delete sample slot
    if self.sliced_instrument then
      return
    else
      local inst = renoise.song().selected_instrument
      if #inst.samples > 1 then
        inst:delete_sample_at(renoise.song().selected_sample_index)
      end
    end
    set_led(LED_Y, LED_FLASH)

  elseif button_id == BTN_PEDAL then
    -- clear sample slot
    if self.sliced_instrument then
      return
    else
      self.sample:clear()
    end
    set_led(LED_PEDAL, LED_FLASH)

  elseif button_id == BTN_NOTECC then
    -- selected sample note mapping prompt
    set_led(LED_NOTECC, LED_BLINK)
    set_prompt(PROMPT_SMAP_NOTE)

  elseif button_id == BTN_MIDICH then
    -- selected sample velocity mapping prompt
    set_led(LED_MIDICH, LED_BLINK)
    set_prompt(PROMPT_SMAP_VEL)

  elseif button_id == BTN_SWTYPE then
    -- generate drumkit map (if not sliced sample)
    if not self.sliced_instrument then
      local inst = renoise.song().selected_instrument
      
      -- remove all maps
      for i = #inst.sample_mappings[1], 1, -1 do
        inst:delete_sample_mapping_at(1, i)
      end
      
      -- add new maps
      for i = 1, #inst.samples do
        inst:insert_sample_mapping(1, i, 47+i,
                                   {47+i, 47+i},
                                   {0, 127})
      end
      set_led(LED_SWTYPE, LED_FLASH)
    end
    

  elseif button_id == BTN_RELVAL then
    -- vol env prompt
    -- todo

  elseif button_id == BTN_VELOCITY then
    -- filter cut prompt
    -- todo

  elseif button_id == BTN_PORT then
    -- filter ext prompt
    -- todo

  elseif button_id == BTN_SCENE then
    -- n/a

  elseif button_id == BTN_MESSAGE then
    -- exit back to pattern edit mode
    set_mode(MODE_PATT)

  elseif button_id == BTN_FIXEDVEL then
    -- n/a

  elseif button_id == BTN_PROGCHANGE then
    -- instrument index prompt
    set_led(LED_PROGCHANGE, LED_BLINK)
    set_prompt(PROMPT_INST_IDX)

  elseif button_id == BTN_KNOB1ASSIGN then
    -- chord mode toggle
    rs.transport.chord_mode_enabled = not rs.transport.chord_mode_enabled
    set_led(LED_KNOB1ASSIGN, LED_FLASH)

  elseif button_id == BTN_KNOB2ASSIGN then
    -- toggle selected sample beat sync
    self.sample.beat_sync_enabled = not self.sample.beat_sync_enabled

  elseif button_id == BTN_HOLD then
    -- n/a

  elseif button_id == BTN_FLAM then
    -- sample vol/pan/nna prompt
    set_led(LED_FLAM, LED_BLINK)
    set_prompt(PROMPT_SAMP_VPN)

  elseif button_id == BTN_ROLL then
    -- sample transport/tune/interpolate prompt
    set_led(LED_ROLL, LED_BLINK)
    set_prompt(PROMPT_SAMP_TTI)
  end
end


function InstEditMode:rotary(rotary_id, value)
  -- handle rotary events
  if rotary_id == ROT_1 then
    -- octave / slice bank
    if #renoise.song().selected_instrument.samples[1].slice_markers > 0 then
      -- slice bank
      if value > 64 then
        if self.slice_bank == 1 then
          return
        end
        self.slice_bank = 1
      else
        if self.slice_bank == 0 then
          return
        end
        self.slice_bank = 0
      end
      
      set_lcd(string.format("b%02d", self.slice_bank+1), true)
      
      -- remap pads
      set_pad_mapping(make_pad_map(renoise.song().selected_instrument, self.slice_bank))
    else
      -- octave
      renoise.song().transport.octave = math.floor(value*0.07)
    end
    
  elseif rotary_id == ROT_2 then
    -- selected sample beat sync (1 - 32 x 1/4 notes)
    local step = math.max(1,renoise.song().transport.lpb/4)
    self.sample.beat_sync_lines = (1+math.floor(value/4)) * step
  end
end


function InstEditMode:pad(pad, velocity)
  if options.flash_pad.value then
    set_led(pad-1, LED_FLASH)
  end
end



--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function InstEditMode:inst_index_hook(is_startup)
  if not is_startup then
    set_lcd(string.format("i%02x", renoise.song().selected_instrument_index-1),
            true)
  end
  
  local inst = renoise.song().selected_instrument

  -- sliced instrument?
  self.sliced_instrument = false
  if #inst.samples > 1 then
    if inst.samples[2].is_slice_alias then
      self.sliced_instrument = true
    end
  end
  
  -- remap pads
  set_pad_mapping(make_pad_map(inst, self.slice_bank))
end


function InstEditMode:sample_hook(is_startup)
  -- remove old hooks
  self:detach_sample_hooks()
  
  -- set new sample pointer
  self.sample = renoise.song().selected_sample
  
  -- attach hooks
  self:attach_sample_hooks()
  
  -- display
  if not is_startup then
    set_lcd(string.format("S%02x", renoise.song().selected_sample_index))
  end
end


function InstEditMode:chord_mode_hook()
  if renoise.song().transport.chord_mode_enabled then
    set_led(LED_KNOB1ASSIGN, LED_ON)
  else
    set_led(LED_KNOB1ASSIGN, LED_OFF)
  end
end


function InstEditMode:octave_hook()
  set_lcd(string.format("oc%01d", renoise.song().transport.octave), true)
end


function InstEditMode:samp_sync_state_hook()
  if self.sample.beat_sync_enabled then
    set_led(LED_KNOB2ASSIGN, LED_ON)
  else
    set_led(LED_KNOB2ASSIGN, LED_OFF)
  end
end


function InstEditMode:samp_sync_lines_hook()
  if self.sample.beat_sync_enabled then
    local steps = self.sample.beat_sync_lines / math.max(1,renoise.song().transport.lpb/4)
    set_lcd(string.format("%03d", steps), true)
  end
end


function InstEditMode:samp_volume_hook()
  set_lcd(vol_to_lcd(self.sample.volume), true)
end


function InstEditMode:samp_panning_hook()
  set_lcd(pan_to_lcd(self.sample.panning), true)
end


function InstEditMode:samp_nna_hook()
  set_lcd(nna_to_lcd(self.sample.new_note_action), true)
end


function InstEditMode:samp_transpose_hook()
  set_lcd(tune_to_lcd(self.sample.transpose), true)
end


function InstEditMode:samp_fine_tune_hook()
  set_lcd(tune_to_lcd(self.sample.fine_tune), true)
end


function InstEditMode:samp_interpolation_hook()
  set_lcd(interpolate_to_lcd(self.sample.interpolation_mode), true)
end


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function InstEditMode:__init()
  local rs = renoise.song()
  local raw = renoise.app().window
  
  -- setup display
  raw.upper_frame_is_visible = true
  raw.active_upper_frame = renoise.ApplicationWindow.UPPER_FRAME_DISK_BROWSER
  raw.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_KEYZONE_EDITOR
  raw.pattern_advanced_edit_is_visible = false
  raw.pattern_matrix_is_visible = false
  raw.sample_record_dialog_is_visible = false
  raw.lower_frame_is_visible = true
  raw.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_INSTRUMENT_PROPERTIES
      
  -- known state
  all_led_off()
  set_led(LED_MESSAGE, LED_ON)
  
  -- attach handlers and call to set states
  if not rs.selected_instrument_index_observable:has_notifier(self,self.inst_index_hook) then
    rs.selected_instrument_index_observable:add_notifier(self,self.inst_index_hook)
  end
  if not rs.selected_sample_observable:has_notifier(self,self.sample_hook) then
    rs.selected_sample_observable:add_notifier(self,self.sample_hook)
  end
  if not rs.transport.chord_mode_enabled_observable:has_notifier(self,self.chord_mode_hook) then
    rs.transport.chord_mode_enabled_observable:add_notifier(self,self.chord_mode_hook)
  end
  if not rs.transport.octave_observable:has_notifier(self,self.octave_hook) then
    rs.transport.octave_observable:add_notifier(self,self.octave_hook)
  end
  
  -- set state
  self.sample = renoise.song().selected_sample
  self.slice_bank = 0
  self.mode = MODE_INST
  
  self:inst_index_hook(true)
  self:chord_mode_hook()
  self:sample_hook(true)
  
  -- set mode indicator
  set_lcd('ins')
end


function InstEditMode:exit()
  -- remove hooks
  local rs = renoise.song()
  
  if rs.selected_instrument_index_observable:has_notifier(self,self.inst_index_hook) then
    rs.selected_instrument_index_observable:remove_notifier(self,self.inst_index_hook)
  end
  if rs.selected_sample_observable:has_notifier(self,self.sample_hook) then
    rs.selected_sample_observable:remove_notifier(self,self.sample_hook)
  end
  if rs.transport.chord_mode_enabled_observable:has_notifier(self,self.chord_mode_hook) then
    rs.transport.chord_mode_enabled_observable:remove_notifier(self,self.chord_mode_hook)
  end
  if rs.transport.octave_observable:has_notifier(self,self.octave_hook) then
    rs.transport.octave_observable:remove_notifier(self,self.octave_hook)
  end
end


function InstEditMode:attach_sample_hooks()
  -- attach handlers and call to set states
  
  if not self.sample.beat_sync_enabled_observable:has_notifier(self,self.samp_sync_state_hook) then
    self.sample.beat_sync_enabled_observable:add_notifier(self,self.samp_sync_state_hook)
  end
  if not self.sample.beat_sync_lines_observable:has_notifier(self,self.samp_sync_lines_hook) then
    self.sample.beat_sync_lines_observable:add_notifier(self,self.samp_sync_lines_hook)
  end
  if not self.sample.volume_observable:has_notifier(self,self.samp_volume_hook) then
    self.sample.volume_observable:add_notifier(self,self.samp_volume_hook)
  end
  if not self.sample.panning_observable:has_notifier(self,self.samp_panning_hook) then
    self.sample.panning_observable:add_notifier(self,self.samp_panning_hook)
  end
  if not self.sample.new_note_action_observable:has_notifier(self,self.samp_nna_hook) then
    self.sample.new_note_action_observable:add_notifier(self,self.samp_nna_hook)
  end
  if not self.sample.transpose_observable:has_notifier(self,self.samp_transpose_hook) then
    self.sample.transpose_observable:add_notifier(self,self.samp_transpose_hook)
  end
  if not self.sample.fine_tune_observable:has_notifier(self,self.samp_fine_tune_hook) then
    self.sample.fine_tune_observable:add_notifier(self,self.samp_fine_tune_hook)
  end
  if not self.sample.interpolation_mode_observable:has_notifier(self,self.samp_interpolation_hook) then
    self.sample.interpolation_mode_observable:add_notifier(self,self.samp_interpolation_hook)
  end
  
  self:samp_sync_state_hook()
end


function InstEditMode:detach_sample_hooks()
  -- remove handlers
  
  if self.sample.beat_sync_enabled_observable:has_notifier(self,self.samp_sync_state_hook) then
    self.sample.beat_sync_enabled_observable:remove_notifier(self,self.samp_sync_state_hook)
  end
  if self.sample.beat_sync_lines_observable:has_notifier(self,self.samp_sync_lines_hook) then
    self.sample.beat_sync_lines_observable:remove_notifier(self,self.samp_sync_lines_hook)
  end
  if self.sample.volume_observable:has_notifier(self,self.samp_volume_hook) then
    self.sample.volume_observable:remove_notifier(self,self.samp_volume_hook)
  end
  if self.sample.panning_observable:has_notifier(self,self.samp_panning_hook) then
    self.sample.panning_observable:remove_notifier(self,self.samp_panning_hook)
  end
  if self.sample.new_note_action_observable:has_notifier(self,self.samp_nna_hook) then
    self.sample.new_note_action_observable:remove_notifier(self,self.samp_nna_hook)
  end
  if self.sample.transpose_observable:has_notifier(self,self.samp_transpose_hook) then
    self.sample.transpose_observable:remove_notifier(self,self.samp_transpose_hook)
  end
  if self.sample.fine_tune_observable:has_notifier(self,self.samp_fine_tune_hook) then
    self.sample.fine_tune_observable:remove_notifier(self,self.samp_fine_tune_hook)
  end
  if self.sample.interpolation_mode_observable:has_notifier(self,self.samp_interpolation_hook) then
    self.sample.interpolation_mode_observable:remove_notifier(self,self.samp_interpolation_hook)
  end
end
