--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Song Edit Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SongEditMode' (BaseMode)

--[[
  self.track = renoise.song().selected_track
]]--


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SongEditMode:encoder(delta)
  -- handle encoder turns
  if prompt then
    prompt:encoder(delta)
  else
    local rs = renoise.song()
    local i = clamp(rs.selected_sequence_index+delta,
                    1, #renoise.song().sequencer.pattern_sequence)
                  
    rs.selected_sequence_index = i
  end
end


function SongEditMode:button(button_id)
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
    -- pattern length prompt
    set_led(LED_SETTING, LED_BLINK)
    set_prompt(PROMPT_PATT_LEN)
  
  elseif button_id == BTN_X then
    -- clone pattern in seq
    local pat = rs.sequencer:insert_new_pattern_at(rs.selected_sequence_index+1)
    rs.selected_sequence_index = rs.selected_sequence_index + 1
    rs.selected_pattern:copy_from(rs.patterns[rs.sequencer:pattern(rs.selected_sequence_index-1)])
    set_led(LED_X, LED_FLASH)
    
  elseif button_id == BTN_Y then
    -- delete pattern in seq
    local rs = renoise.song()
    rs.sequencer:delete_sequence_at(rs.selected_sequence_index)
    set_led(LED_Y, LED_FLASH)

  elseif button_id == BTN_PEDAL then
    -- clear pattern
    rs.selected_pattern:clear()
    set_led(LED_PEDAL, LED_FLASH)

  elseif button_id == BTN_NOTECC then
    -- n/a

  elseif button_id == BTN_MIDICH then
    -- track index prompt
    set_led(LED_MIDICH, LED_BLINK)
    set_prompt(PROMPT_TRACK_IDX)

  elseif button_id == BTN_SWTYPE then
    -- metronome toggle
    rs.transport.metronome_enabled = not rs.transport.metronome_enabled

  elseif button_id == BTN_RELVAL then
    -- track output / delay prompt
    set_led(LED_RELVAL, LED_BLINK)
    set_prompt(PROMPT_TRACK_OUTDEL)

  elseif button_id == BTN_VELOCITY then
    -- n/a
    

  elseif button_id == BTN_PORT then
    -- bpm prompt
    set_led(LED_PORT, LED_BLINK)
    set_prompt(PROMPT_BPM)

  elseif button_id == BTN_SCENE then
    -- sequencer position prompt
    set_led(LED_SCENE, LED_BLINK)
    set_prompt(PROMPT_SEQ_IDX)

  elseif button_id == BTN_MESSAGE then
    -- exit back to pattern edit mode
    set_mode(MODE_PATT)

  elseif button_id == BTN_FIXEDVEL then
    -- n/a

  elseif button_id == BTN_PROGCHANGE then
    -- n/a

  elseif button_id == BTN_KNOB1ASSIGN then
    -- track mute
    if self.track.type == renoise.Track.TRACK_TYPE_MASTER then
      return
    end
    if self.track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
      self.track:unmute()
    else
      self.track:mute()
    end
    self:update_mute_solo()
    

  elseif button_id == BTN_KNOB2ASSIGN then
    -- track solo
    if self.track.type == renoise.Track.TRACK_TYPE_MASTER then
      return
    end
    self.track:solo()
    self:update_mute_solo()

  elseif button_id == BTN_HOLD then
    -- toggle pattern loop
    rs.transport.loop_pattern = not rs.transport.loop_pattern
    
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


function SongEditMode:rotary(rotary_id, value)
  -- handle rotary events
  local rs = renoise.song()
  
  if rotary_id == ROT_1 then
    -- track volume
    rs.selected_track.postfx_volume.value = (value/127)
    
  elseif rotary_id == ROT_2 then
    -- track panning
    local pan = rs.selected_track.postfx_panning
    if value < 50 then
      pan.value_string = string.format("%u L", 50-value)
    elseif value > 77 then  --127-50
      pan.value_string = string.format("%u R", value-77)
    else
      pan.value_string = "Center"
    end
  end
end


function SongEditMode:pad(pad, velocity)
  -- toggle pattern track mute
  pad = pad - 1
  
  local rs = renoise.song()
  local y0 = math.floor(pad/4)
  local x0 = pad - (y0*4)
  local ti = rs.selected_track_index
  local si = rs.transport.edit_pos.sequence
          
  if ti + x0 <= #rs.tracks then  --not master
    if rs.tracks[ti+x0].type ~= renoise.Track.TRACK_TYPE_MASTER then
      if si+y0 <= #rs.sequencer.pattern_sequence then
        local old_val = rs.sequencer:track_sequence_slot_is_muted(ti+x0,si+y0)
        rs.sequencer:set_track_sequence_slot_is_muted(ti+x0,si+y0, not old_val)
        if old_val then
          -- was muted, now on
          set_led(pad, LED_ON)
        else
          -- was on, now muted
          set_led(pad, LED_OFF)
        end
      end
    end
  end
end


function SongEditMode:update_pad_mutes()
  -- update the pad mutes
  local rs = renoise.song()
  local x = rs.selected_track_index
  local x_max = #rs.tracks +1
  local y = rs.transport.edit_pos.sequence
  local y_max = #rs.sequencer.pattern_sequence +1
  for i = 0, 3 do  --col
    for j = 0, 3 do  --row
      if x+i < x_max then
        if y+j < y_max then
          if rs.sequencer:track_sequence_slot_is_muted(x+i, y+j)  then
            set_led((j*4)+i, LED_OFF)
          else
            set_led((j*4)+i, LED_ON)
          end
        else
          set_led((j*4)+i, LED_OFF)
        end
      else
        set_led((j*4)+i, LED_OFF)
      end
    end
  end 
end


function SongEditMode:update_mute_solo()
  -- update the mute/solo leds
  local rs = renoise.song()
  
  if self.track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
    set_led(LED_KNOB1ASSIGN, LED_ON)
  else
    local state = LED_OFF
    for i = 1, #rs.tracks do
      if rs.tracks[i].mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
        state = LED_BLINK
      end
    end
    set_led(LED_KNOB1ASSIGN, state)
  end
  
  if self.track.solo_state then
    set_led(LED_KNOB2ASSIGN, LED_ON)
  else
    local state = LED_OFF
    for i = 1, #rs.tracks do
      if rs.tracks[i].solo_state then
        state = LED_BLINK
      end
    end
    set_led(LED_KNOB2ASSIGN, state)
  end
end

--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function SongEditMode:track_index_hook()

  self:detach_track_hooks()

  self.track = renoise.song().selected_track
  
  self:attach_track_hooks()

  if self.track.type == renoise.Track.TRACK_TYPE_MASTER then
    set_lcd("mst", true)
  else
    set_lcd(string.format("t%02x", renoise.song().selected_track_index), true)
  end
  
  -- update
  self:update_pad_mutes()
  self:update_mute_solo()
end


function SongEditMode:pattern_loop_hook()
  if renoise.song().transport.loop_pattern then
    set_led(LED_HOLD, LED_ON)
  else
    set_led(LED_HOLD, LED_OFF)
  end
end


function SongEditMode:metronome_state_hook()
  if renoise.song().transport.metronome_enabled then
    set_led(LED_SWTYPE, LED_ON)
  else
    set_led(LED_SWTYPE, LED_OFF)
  end
end


function SongEditMode:play_state_hook()
  if renoise.song().transport.playing then
    set_led(LED_ROLL, LED_ON)
  else
    set_led(LED_ROLL, LED_OFF)
  end
end


function SongEditMode:edit_mode_hook()
  if renoise.song().transport.edit_mode then
    set_led(LED_FLAM, LED_ON)
  else
    set_led(LED_FLAM, LED_OFF)
  end
end


function SongEditMode:bpm_hook()
  set_lcd(string.format("%03d", renoise.song().transport.bpm), true)
end


function SongEditMode:seq_pos_hook()
  self:update_pad_mutes()
end


function SongEditMode:track_volume_hook()
  set_lcd(vol_to_lcd(self.track.postfx_volume.value), true)
end


function SongEditMode:track_panning_hook()
  set_lcd(pan_to_lcd(self.track.postfx_panning.value), true)
end


function SongEditMode:track_output_routing_hook()
  set_lcd(string.format("o%02d", table.find(self.track.available_output_routings,
                                            self.track.output_routing), true))
end


function SongEditMode:track_output_delay_hook()
  set_lcd(string.format("%03d", math.floor(self.track.output_delay*10)), true)
end



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SongEditMode:__init()
  local rs = renoise.song()
  local raw = renoise.app().window
  
  -- setup display
  raw.upper_frame_is_visible = true
  raw.active_upper_frame = renoise.ApplicationWindow.UPPER_FRAME_MASTER_SPECTRUM
  raw.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
  raw.pattern_advanced_edit_is_visible = false
  raw.pattern_matrix_is_visible = true
  raw.sample_record_dialog_is_visible = false
  raw.lower_frame_is_visible = true
  raw.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
      
  -- known state
  all_led_off()
  
  -- attach handlers and call to set states
  if not rs.selected_track_index_observable:has_notifier(self,self.track_index_hook) then
    rs.selected_track_index_observable:add_notifier(self,self.track_index_hook)
  end
  if not rs.transport.loop_pattern_observable:has_notifier(self,self.pattern_loop_hook) then
    rs.transport.loop_pattern_observable:add_notifier(self,self.pattern_loop_hook)
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
  if not rs.transport.bpm_observable:has_notifier(self,self.bpm_hook) then
    rs.transport.bpm_observable:add_notifier(self,self.bpm_hook)
  end
  if not rs.selected_sequence_index_observable:has_notifier(self,self.seq_pos_hook) then
    rs.selected_sequence_index_observable:add_notifier(self,self.seq_pos_hook)
  end  
  
  -- set state
  set_pad_mapping({0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F,
                   0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F})
  set_led(LED_MESSAGE, LED_ON)
  self.track = renoise.song().selected_track
  self.mode = MODE_SONG
  
  self:track_index_hook()
  self:pattern_loop_hook()
  self:metronome_state_hook()
  self:play_state_hook()
  self:edit_mode_hook()
    
  -- set mode indicator
  set_lcd('Son')
end


function SongEditMode:exit()
  -- remove hooks
  local rs = renoise.song()
  if rs.selected_track_index_observable:has_notifier(self,self.track_index_hook) then
    rs.selected_track_index_observable:remove_notifier(self,self.track_index_hook)
  end
  if rs.transport.loop_pattern_observable:has_notifier(self,self.pattern_loop_hook) then
    rs.transport.loop_pattern_observable:remove_notifier(self,self.pattern_loop_hook)
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
  if rs.transport.bpm_observable:has_notifier(self,self.bpm_hook) then
    rs.transport.bpm_observable:remove_notifier(self,self.bpm_hook)
  end
  if rs.selected_sequence_index_observable:has_notifier(self,self.seq_pos_hook) then
    rs.selected_sequence_index_observable:remove_notifier(self,self.seq_pos_hook)
  end
  print("")
end


function SongEditMode:attach_track_hooks()
  -- attach handlers
  if not self.track.postfx_volume.value_observable:has_notifier(self,self.track_volume_hook) then
    self.track.postfx_volume.value_observable:add_notifier(self,self.track_volume_hook)
  end
  if not self.track.postfx_panning.value_observable:has_notifier(self,self.track_panning_hook) then
    self.track.postfx_panning.value_observable:add_notifier(self,self.track_panning_hook)
  end
  if not self.track.output_routing_observable:has_notifier(self,self.track_output_routing_hook) then
    self.track.output_routing_observable:add_notifier(self,self.track_output_routing_hook)
  end
  if not self.track.output_delay_observable:has_notifier(self,self.track_output_delay_hook) then
    self.track.output_delay_observable:add_notifier(self,self.track_output_delay_hook)
  end
end


function SongEditMode:detach_track_hooks()
  -- detach handlers
  if self.track.postfx_volume.value_observable:has_notifier(self,self.track_volume_hook) then
    self.track.postfx_volume.value_observable:remove_notifier(self,self.track_volume_hook)
  end
  if self.track.postfx_panning.value_observable:has_notifier(self,self.track_panning_hook) then
    self.track.postfx_panning.value_observable:remove_notifier(self,self.track_panning_hook)
  end
  if self.track.output_routing_observable:has_notifier(self,self.track_output_routing_hook) then
    self.track.output_routing_observable:remove_notifier(self,self.track_output_routing_hook)
  end
  if self.track.output_delay_observable:has_notifier(self,self.track_output_delay_hook) then
    self.track.output_delay_observable:remove_notifier(self,self.track_output_delay_hook)
  end
end
