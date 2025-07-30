--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Pattern Edit Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'PattEditMode' (BaseMode)


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function PattEditMode:encoder(delta)
  -- handle encoder turns
  
  if prompt then
    prompt:encoder(delta)
  else
    local rs = renoise.song()
    local sp = renoise.SongPos()
    sp.line = clamp(rs.transport.edit_pos.line + delta,
                    1, rs.selected_pattern.number_of_lines)
    sp.sequence = rs.transport.edit_pos.sequence
    rs.transport.edit_pos = sp
  end
end


function PattEditMode:button(button_id)
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
    elseif button_id == BTN_PROGCHANGE then
      if prompt.prompt == PROMPT_INST_IDX then
        set_mode(MODE_INST)
        return
      end
    elseif button_id == BTN_SCENE then
      if prompt.prompt == PROMPT_SEQ_IDX then
        set_mode(MODE_SONG)
        return
      end
    end
  end
  
  local rs = renoise.song()
  
  if button_id == BTN_SETTING then
    -- pattern length prompt
    set_led(LED_SETTING, LED_BLINK)
    set_prompt(PROMPT_PATT_LEN)
  
  elseif button_id == BTN_X then
    -- insert line in note column
    local start = rs.transport.edit_pos.line
    local pt = rs.selected_pattern_track
    for i = #pt.lines-1, start, -1 do
      pt:line(i+1):copy_from(pt:line(i))
    end
    pt:line(start):clear()
    set_led(LED_PEDAL, LED_X)

  elseif button_id == BTN_Y then
    -- delete line in note column
    local start = rs.transport.edit_pos.line
    local pt = rs.selected_pattern_track
    for i =  start, #pt.lines do
      pt:line(i):copy_from(pt:line(i+1))
    end
    pt:line(#pt.lines):clear()
    set_led(LED_PEDAL, LED_Y)

  elseif button_id == BTN_PEDAL then
    -- clear line in note column
    rs.selected_pattern_track:line(rs.transport.edit_pos.line):clear()
    set_led(LED_PEDAL, LED_FLASH)

  elseif button_id == BTN_NOTECC then
    -- note column index prompt
    set_led(LED_NOTECC, LED_BLINK)
    set_prompt(PROMPT_NOTECOL_IDX)

  elseif button_id == BTN_MIDICH then
    -- track index prompt
    set_led(LED_MIDICH, LED_BLINK)
    set_prompt(PROMPT_TRACK_IDX)

  elseif button_id == BTN_SWTYPE then
    -- toggle metronome
    rs.transport.metronome_enabled = not rs.transport.metronome_enabled

  elseif button_id == BTN_RELVAL then
    -- note delay prompt
    set_led(LED_RELVAL, LED_BLINK)
    set_prompt(PROMPT_NOTE_DELAY)

  elseif button_id == BTN_VELOCITY then
    -- note volume prompt
    set_led(LED_VELOCITY, LED_BLINK)
    set_prompt(PROMPT_NOTE_VOLUME)

  elseif button_id == BTN_PORT then
    -- note pan prompt
    set_led(LED_PORT, LED_BLINK)
    set_prompt(PROMPT_NOTE_PANNING)

  elseif button_id == BTN_SCENE then
    -- seq pos prompt
    set_led(LED_SCENE, LED_BLINK)
    set_prompt(PROMPT_SEQ_IDX)

  elseif button_id == BTN_MESSAGE then
    -- pad scale
    set_led(LED_MESSAGE, LED_BLINK)
    set_prompt(PROMPT_PAD_SCALE)

  elseif button_id == BTN_FIXEDVEL then
    -- insert note off
    rs.selected_note_column:clear()
    rs.selected_note_column.note_value = renoise.PatternTrackLine.NOTE_OFF
    set_led(LED_FIXEDVEL, LED_FLASH)

  elseif button_id == BTN_PROGCHANGE then
    -- instrument index prompt
    set_led(LED_PROGCHANGE, LED_BLINK)
    set_prompt(PROMPT_INST_IDX)

  elseif button_id == BTN_KNOB1ASSIGN then
    -- chord mode toggle
    rs.transport.chord_mode_enabled = not rs.transport.chord_mode_enabled
    set_led(LED_KNOB1ASSIGN, LED_FLASH)

  elseif button_id == BTN_KNOB2ASSIGN then
    -- record quantize / edit step toggle
    rs.transport.record_quantize_enabled = not rs.transport.record_quantize_enabled
    if rs.transport.record_quantize_enabled then
      rs.transport.edit_step = rs.transport.record_quantize_lines
    else
      rs.transport.edit_step = 0
    end
    set_led(LED_KNOB2ASSIGN, LED_FLASH)

  elseif button_id == BTN_HOLD then
    -- pattern follow toggle
    rs.transport.follow_player = not rs.transport.follow_player

  elseif button_id == BTN_FLAM then
    -- edit mode toggle
    rs.transport.edit_mode = not rs.transport.edit_mode

  elseif button_id == BTN_ROLL then
    -- start/stop transport
    if rs.transport.playing then
      rs.transport:stop()
    else 
      rs.transport.loop_pattern = true
      rs.transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
    end
  end
end


function PattEditMode:rotary(rotary_id, value)
  -- handle rotary events
  local rs = renoise.song()
  
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
      rs.transport.octave = math.floor(value*0.07)
    end
    
  elseif rotary_id == ROT_2 then
    -- record quantize / edit step

    -- create table of valid settings for this lpb
    local lpb = rs.transport.lpb
    local dvals = {0.25, 0.5, 1, 2, 4, 6, 8, 12, 24}
    local valid = {}
    local i
      
    for i = 1, #dvals do
      if ((lpb/dvals[i]) % 1 == 0) and ((lpb/dvals[i]) < 32) then
       table.insert(valid, dvals[i])
      end
    end
     
    i = math.floor(1 + ((value/127) * (#valid-1)))
    rs.transport.record_quantize_lines = lpb/valid[i]  
  end
end


function PattEditMode:pad(pad, velocity)
  if options.flash_pad.value then
    set_led(pad-1, LED_FLASH)
  end
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function PattEditMode:inst_index_hook(is_startup)
  if not is_startup then
    set_lcd(string.format("i%02x", renoise.song().selected_instrument_index-1),
            true)
  end
  
  -- remap pads
  set_pad_mapping(make_pad_map(renoise.song().selected_instrument, self.slice_bank))
end


function PattEditMode:track_index_hook()
  if renoise.song().selected_track.type == renoise.Track.TRACK_TYPE_MASTER then
    set_lcd("mst", true)
  else
    set_lcd(string.format("t%02x", renoise.song().selected_track_index), true)
  end
end


function PattEditMode:metronome_state_hook()
  if renoise.song().transport.metronome_enabled then
    set_led(LED_SWTYPE, LED_ON)
  else
    set_led(LED_SWTYPE, LED_OFF)
  end
end


function PattEditMode:play_state_hook()
  if renoise.song().transport.playing then
    set_led(LED_ROLL, LED_ON)
  else
    set_led(LED_ROLL, LED_OFF)
  end
end


function PattEditMode:edit_mode_hook()
  if renoise.song().transport.edit_mode then
    set_led(LED_FLAM, LED_ON)
  else
    set_led(LED_FLAM, LED_OFF)
  end
end


function PattEditMode:chord_mode_hook()
  if renoise.song().transport.chord_mode_enabled then
    set_led(LED_KNOB1ASSIGN, LED_ON)
  else
    set_led(LED_KNOB1ASSIGN, LED_OFF)
  end
end


function PattEditMode:octave_hook()
  set_lcd(string.format("oc%01d", renoise.song().transport.octave), true)
end


function PattEditMode:rec_quant_state_hook()
  if renoise.song().transport.record_quantize_enabled then
    set_led(LED_KNOB2ASSIGN, LED_ON)
    renoise.song().transport.edit_step = renoise.song().transport.record_quantize_lines
  else
    set_led(LED_KNOB2ASSIGN, LED_OFF)
    renoise.song().transport.edit_step = 0
  end
end


function PattEditMode:rec_quant_lines_hook()
  if renoise.song().transport.record_quantize_enabled then
    local ratio = renoise.song().transport.record_quantize_lines / renoise.song().transport.lpb
    local str = ''
    if ratio == 4 then
      -- whole note (4 beats)
      str = '1 1'
    elseif ratio == 2 then
      -- minim
      str = '1 2'
    elseif ratio == 1 then
      -- quarter note (1 beat)
      str = '1 4'
    elseif ratio == 0.5 then
      -- quaver
      str = '1 8'
    elseif ratio == 0.25 then
      -- semiquaver
      str = '116'
    elseif ratio == 0.125 then
      -- demisemiquaver
      str = '132'
    elseif ratio == (1/6) then
      -- quarter note triplets
      str = '4 t'
    elseif ratio == (1/12) then
      -- quaver note triplets
      str = '8 t'
    elseif ratio == (1/24) then
      -- semiquaver note triplets
      str = '16t'
    else
      str = 'qxx'
    end
    set_lcd(str, true)
    renoise.song().transport.edit_step = renoise.song().transport.record_quantize_lines
  end
end


function PattEditMode:play_follow_hook()
  if renoise.song().transport.follow_player then
    set_led(LED_HOLD, LED_OFF)
  else
    set_led(LED_HOLD, LED_ON)
  end
end


function PattEditMode:app_idle_hook()
  local rst = renoise.song().transport
  local floor = math.floor
        
  if self.cached_edit_beat == rst.edit_pos_beats then
    -- same line
    return
  else
    -- different line    
    if rst.playing and rst.edit_mode and rst.follow_player then
      -- playing, edit mode, new beat
      if floor(self.cached_edit_beat) == floor(rst.edit_pos_beats) then
        return
      end
      
      self.cached_edit_beat = rst.edit_pos_beats
      local l = rst.edit_pos.line - 1
      local beat0 = floor(l/rst.lpb)
      local bar0 = floor(beat0/4)
      
      set_lcd(string.format('%01x%01x ', 1+bar0, 1+(beat0%4)))
    else
      --
      self.cached_edit_beat = rst.edit_pos_beats
      local l = rst.edit_pos.line -1
      local beat0 = floor(l/rst.lpb)
      local bar0 = floor(beat0/4)
      local subbeat0 = (((l/rst.lpb) % 1) * rst.lpb) % 16
            
      set_lcd(string.format('%01x%01x%01x', 1+bar0,  1+(beat0%4), subbeat0))
    end
  end
end


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function PattEditMode:__init()
  local rs = renoise.song()
  local raw = renoise.app().window
  
  -- setup display
  raw.upper_frame_is_visible = false
  raw.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  raw.pattern_advanced_edit_is_visible = false
  raw.pattern_matrix_is_visible = false
  raw.sample_record_dialog_is_visible = false
  raw.lower_frame_is_visible = false
  
  -- edit step
  if rs.transport.record_quantize_enabled then
    rs.transport.edit_step = rs.transport.record_quantize_lines
  else
    rs.transport.edit_step = 0
  end
  
  -- pattern loop always on
  rs.transport.loop_pattern = true
  
  -- known state
  all_led_off()
  
  -- attach handlers and call to set states
  if not rs.selected_instrument_index_observable:has_notifier(self,self.inst_index_hook) then
    rs.selected_instrument_index_observable:add_notifier(self,self.inst_index_hook)
  end
  if not rs.selected_track_index_observable:has_notifier(self,self.track_index_hook) then
    rs.selected_track_index_observable:add_notifier(self,self.track_index_hook)
  end
  if not rs.transport.metronome_enabled_observable:has_notifier(self,self.metronome_state_hook) then
    rs.transport.metronome_enabled_observable:add_notifier(self,self.metronome_state_hook)
  end
  if not rs.transport.playing_observable:has_notifier(self,self.play_state_hook) then
    rs.transport.playing_observable:add_notifier(self,self.play_state_hook)
  end
  if not rs.transport.edit_mode_observable:has_notifier(self,self.edit_mode_hook) then
    rs.transport.edit_mode_observable:add_notifier(self,self.edit_mode_hook)
  end
  if not rs.transport.chord_mode_enabled_observable:has_notifier(self,self.chord_mode_hook) then
    rs.transport.chord_mode_enabled_observable:add_notifier(self,self.chord_mode_hook)
  end
  if not rs.transport.octave_observable:has_notifier(self,self.octave_hook) then
    rs.transport.octave_observable:add_notifier(self,self.octave_hook)
  end
  if not rs.transport.record_quantize_enabled_observable:has_notifier(self,self.rec_quant_state_hook) then
    rs.transport.record_quantize_enabled_observable:add_notifier(self,self.rec_quant_state_hook)
  end
  if not rs.transport.record_quantize_lines_observable:has_notifier(self,self.rec_quant_lines_hook) then
    rs.transport.record_quantize_lines_observable:add_notifier(self,self.rec_quant_lines_hook)
  end
  if not rs.transport.follow_player_observable:has_notifier(self,self.play_follow_hook) then
    rs.transport.follow_player_observable:add_notifier(self,self.play_follow_hook)
  end
  if not renoise.tool().app_idle_observable:has_notifier(self,self.app_idle_hook) then
    renoise.tool().app_idle_observable:add_notifier(self,self.app_idle_hook)
  end
  
  -- set state
  self:inst_index_hook(true)
  self:metronome_state_hook()
  self:play_state_hook()
  self:edit_mode_hook()
  self:chord_mode_hook()
  self:rec_quant_state_hook()
  self:play_follow_hook()
  
  self.slice_bank = 0
  self.mode = MODE_PATT
  
  -- set mode indicator
  set_lcd('pat', true)
  
  self.cached_edit_beat = -1
end


function PattEditMode:exit()
  -- remove hooks
  local rs = renoise.song()
  
  if renoise.tool().app_idle_observable:has_notifier(self,self.app_idle_hook) then
    renoise.tool().app_idle_observable:remove_notifier(self,self.app_idle_hook)
  end
  if rs.selected_instrument_index_observable:has_notifier(self,self.inst_index_hook) then
    rs.selected_instrument_index_observable:remove_notifier(self,self.inst_index_hook)
  end
  if rs.selected_track_index_observable:has_notifier(self,self.track_index_hook) then
    rs.selected_track_index_observable:remove_notifier(self,self.track_index_hook)
  end
  if rs.transport.metronome_enabled_observable:has_notifier(self,self.metronome_state_hook) then
    rs.transport.metronome_enabled_observable:remove_notifier(self,self.metronome_state_hook)
  end
  if rs.transport.playing_observable:has_notifier(self,self.play_state_hook) then
    rs.transport.playing_observable:remove_notifier(self,self.play_state_hook)
  end
  if rs.transport.edit_mode_observable:has_notifier(self,self.edit_mode_hook) then
    rs.transport.edit_mode_observable:remove_notifier(self,self.edit_mode_hook)
  end
  if rs.transport.chord_mode_enabled_observable:has_notifier(self,self.chord_mode_hook) then
    rs.transport.chord_mode_enabled_observable:remove_notifier(self,self.chord_mode_hook)
  end
  if rs.transport.octave_observable:has_notifier(self,self.octave_hook) then
    rs.transport.octave_observable:remove_notifier(self,self.octave_hook)
  end
  if rs.transport.record_quantize_enabled_observable:has_notifier(self,self.rec_quant_state_hook) then
    rs.transport.record_quantize_enabled_observable:remove_notifier(self,self.rec_quant_state_hook)
  end
  if rs.transport.record_quantize_lines_observable:has_notifier(self,self.rec_quant_lines_hook) then
    rs.transport.record_quantize_lines_observable:remove_notifier(self,self.rec_quant_lines_hook)
  end
  if rs.transport.follow_player_observable:has_notifier(self,self.play_follow_hook) then
    rs.transport.follow_player_observable:remove_notifier(self,self.play_follow_hook)
  end
end

