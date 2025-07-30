--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sample Edit Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampEditMode' (BaseMode)

--[[
  self.sample = renoise.song().selected_sample
  self.slice_bank = 0..1
  self.move_end = true/false
]]--


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampEditMode:encoder(delta)
  -- handle encoder turns
  if prompt then
    prompt:encoder(delta)
  else
    -- move cursor
    if self.sample.sample_buffer.has_sample_data then
      if self.move_end then
        -- end
        local dr = self.sample.sample_buffer.display_range
        local sr = self.sample.sample_buffer.selection_range
        local step = (dr[2]-dr[1])/512
        
        self.sample.sample_buffer.selection_range =
          {sr[1], clamp(sr[2]+(delta*step), dr[1], dr[2])}
      else
        -- start
        local dr = self.sample.sample_buffer.display_range
        local sr = self.sample.sample_buffer.selection_range
        local step = (dr[2]-dr[1])/512
        
        self.sample.sample_buffer.selection_range =
          {clamp(sr[1]+(delta*step), dr[1], dr[2]), sr[2]}
      end
    end
  end
end


function SampEditMode:button(button_id)
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
    -- n/a
  
  elseif button_id == BTN_X then
    -- move selection start
    self.move_end = false
    set_led(LED_X, LED_FLASH)
    
  elseif button_id == BTN_Y then
    -- move selection end
    self.move_end = true
    set_led(LED_Y, LED_FLASH)

  elseif button_id == BTN_PEDAL then
    -- select all
    if self.sample.sample_buffer.has_sample_data then
      self.sample.sample_buffer.selection_range = self.sample.sample_buffer.display_range
       set_led(LED_PEDAL, LED_FLASH)
    end
    
  elseif button_id == BTN_NOTECC then
    -- slicer prompt
    if rs.selected_sample_index == 1 then
      if #rs.selected_instrument.samples > 1 then
        if rs.selected_instrument.samples[2].is_slice_alias then
          if self.sample.sample_buffer.has_sample_data then
            set_led(LED_NOTECC, LED_BLINK)
            set_prompt(PROMPT_SAMP_SLICE)
          end
        end
      end
    end

  elseif button_id == BTN_MIDICH then
    -- autochop prompt
    if rs.selected_sample_index == 1 then
      if self.sample.sample_buffer.has_sample_data then
        set_led(LED_MIDICH, LED_BLINK)
        set_prompt(PROMPT_SAMP_AUTOCHOP)
      end
    end

  elseif button_id == BTN_SWTYPE then
    -- toggle sample record dialog
    set_led(LED_SWTYPE, LED_BLINK)
    set_prompt(PROMPT_SAMP_REC)

  elseif button_id == BTN_RELVAL then
    -- zoom selection
    if self.sample.sample_buffer.has_sample_data then
      self.sample.sample_buffer.display_range = self.sample.sample_buffer.selection_range
      set_led(LED_RELVAL, LED_FLASH)
    end

  elseif button_id == BTN_VELOCITY then
    -- zoom out
    if self.sample.sample_buffer.has_sample_data then
      local dr = self.sample.sample_buffer.display_range
      local sr = self.sample.sample_buffer.selection_range
      local mf = self.sample.sample_buffer.number_of_frames
      local size = sr[2]-sr[1]
      local center = sr[1] + size/2
      self.sample.sample_buffer.display_range =
        {clamp(center-size, 1, mf), clamp(center+size, 1, mf)}
      set_led(LED_VELOCITY, LED_FLASH)
    end

  elseif button_id == BTN_PORT then
    -- zoom max
    if self.sample.sample_buffer.has_sample_data then
      self.sample.sample_buffer.display_range = {1, self.sample.sample_buffer.number_of_frames}
      set_led(LED_PORT, LED_FLASH)
    end

  elseif button_id == BTN_SCENE then
    -- n/a

  elseif button_id == BTN_MESSAGE then
    -- exit back to instrument edit mode
    set_mode(MODE_INST)

  elseif button_id == BTN_FIXEDVEL then
    -- normalise
    -- todo (no api)

  elseif button_id == BTN_PROGCHANGE then
    -- n/a

  elseif button_id == BTN_KNOB1ASSIGN then
    -- chord mode toggle
    rs.transport.chord_mode_enabled = not rs.transport.chord_mode_enabled
    set_led(LED_KNOB1ASSIGN, LED_FLASH)

  elseif button_id == BTN_KNOB2ASSIGN then
    -- toggle selected sample beat sync
    self.sample.beat_sync_enabled = not self.sample.beat_sync_enabled

  elseif button_id == BTN_HOLD then
    -- sample loop prompt
    set_led(LED_HOLD, LED_BLINK)
    set_prompt(PROMPT_SAMP_LOOP)

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


function SampEditMode:rotary(rotary_id, value)
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


function SampEditMode:pad(pad, velocity)
  if options.flash_pad.value then
    set_led(pad-1, LED_FLASH)
  end
end



--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function SampEditMode:inst_index_hook(is_startup)
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


function SampEditMode:sample_hook(is_startup)
  -- remove old hooks
  self:detach_sample_hooks()
  
  -- set new sample pointer
  self.sample = renoise.song().selected_sample
  
  -- attach hooks
  self:attach_sample_hooks()
  
  -- display
  if not is_startup then
    set_lcd(string.format("S%02x", renoise.song().selected_sample_index), true)
  end
end


function SampEditMode:chord_mode_hook()
  if renoise.song().transport.chord_mode_enabled then
    set_led(LED_KNOB1ASSIGN, LED_ON)
  else
    set_led(LED_KNOB1ASSIGN, LED_OFF)
  end
end


function SampEditMode:octave_hook()
  set_lcd(string.format("oc%01d", renoise.song().transport.octave), true)
end


function SampEditMode:samp_sync_state_hook()
  if self.sample.beat_sync_enabled then
    set_led(LED_KNOB2ASSIGN, LED_ON)
  else
    set_led(LED_KNOB2ASSIGN, LED_OFF)
  end
end


function SampEditMode:samp_sync_lines_hook()
  if self.sample.beat_sync_enabled then
    local steps = self.sample.beat_sync_lines / math.max(1,renoise.song().transport.lpb/4)
    set_lcd(string.format("%03d", steps), true)
  end
end


function SampEditMode:samp_volume_hook()
  set_lcd(vol_to_lcd(self.sample.volume), true)
end


function SampEditMode:samp_panning_hook()
  set_lcd(pan_to_lcd(self.sample.panning), true)
end


function SampEditMode:samp_nna_hook()
  set_lcd(nna_to_lcd(self.sample.new_note_action), true)
end


function SampEditMode:samp_transpose_hook()
  set_lcd(tune_to_lcd(self.sample.transpose), true)
end


function SampEditMode:samp_fine_tune_hook()
  set_lcd(tune_to_lcd(self.sample.fine_tune), true)
end


function SampEditMode:samp_interpolation_hook()
  set_lcd(interpolate_to_lcd(self.sample.interpolation_mode), true)
end


function SampEditMode:samp_loop_mode_hook()
  local lm = self.sample.loop_mode
  if lm == renoise.Sample.LOOP_MODE_OFF then
    set_lcd("OFF")
  elseif lm == renoise.Sample.LOOP_MODE_FORWARD then
    set_lcd("FOR")
  elseif lm == renoise.Sample.LOOP_MODE_REVERSE then
    set_lcd("REV")
  elseif lm == renoise.Sample.LOOP_MODE_PING_PONG then
    set_lcd("P-P")
  end
end


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampEditMode:__init()
  local rs = renoise.song()
  local raw = renoise.app().window
  
  -- setup display
  raw.upper_frame_is_visible = true
  raw.active_upper_frame = renoise.ApplicationWindow.UPPER_FRAME_DISK_BROWSER
  raw.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR
  raw.pattern_advanced_edit_is_visible = false
  raw.pattern_matrix_is_visible = false
  raw.sample_record_dialog_is_visible = false
  raw.lower_frame_is_visible = true
  raw.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_INSTRUMENT_PROPERTIES
      
  -- known state
  all_led_off()
  
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
  self.mode = MODE_SAMP
  self.move_end = false
  
  self:inst_index_hook(true)
  self:chord_mode_hook()
  self:sample_hook(true)
  set_led(LED_MESSAGE, LED_ON)
  
  -- set mode indicator
  set_lcd('sam')
end


function SampEditMode:exit()
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


function SampEditMode:attach_sample_hooks()
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
  if not self.sample.loop_mode_observable:has_notifier(self,self.samp_loop_mode_hook) then
    self.sample.loop_mode_observable:add_notifier(self,self.samp_loop_mode_hook)
  end
  
  self:samp_sync_state_hook()
end


function SampEditMode:detach_sample_hooks()
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
  if self.sample.loop_mode_observable:has_notifier(self,self.samp_loop_mode_hook) then
    self.sample.loop_mode_observable:remove_notifier(self,self.samp_loop_mode_hook)
  end
end
