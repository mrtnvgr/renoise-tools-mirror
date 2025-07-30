--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Common control mode code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
MODE_MIX  = 1
MODE_EDIT = 2
MODE_DSP  = 3
MODE_SAMP = 4
MODE_INST = 5


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
current_mode = MODE_EDIT --default on startup


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function attach_common_hooks()
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(common_volume_change_hook) == false then
    renoise.song().selected_track.prefx_volume.value_observable:add_notifier(common_volume_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(common_pan_change_hook) == false then
    renoise.song().selected_track.prefx_panning.value_observable:add_notifier(common_pan_change_hook)
  end
  if renoise.song().selected_track_index_observable:has_notifier(common_track_change_hook) == false then
    renoise.song().selected_track_index_observable:add_notifier(common_track_change_hook)
  end
  if renoise.song().selected_track.solo_state_observable:has_notifier(common_solo_hook) == false then
    renoise.song().selected_track.solo_state_observable:add_notifier(common_solo_hook)
  end
  if renoise.song().selected_track.mute_state_observable:has_notifier(common_mute_hook) == false then
    renoise.song().selected_track.mute_state_observable:add_notifier(common_mute_hook)
  end
  if renoise.song().transport.edit_mode_observable:has_notifier(common_editmode_hook) == false then
    renoise.song().transport.edit_mode_observable:add_notifier(common_editmode_hook)
  end
  if renoise.song().transport.loop_pattern_observable:has_notifier(common_patternloop_hook) == false then
    renoise.song().transport.loop_pattern_observable:add_notifier(common_patternloop_hook)
  end
end


function dettach_common_hooks()
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(common_volume_change_hook) == true then
    renoise.song().selected_track.prefx_volume.value_observable:remove_notifier(common_volume_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(common_pan_change_hook) == true then
    renoise.song().selected_track.prefx_panning.value_observable:remove_notifier(common_pan_change_hook)
  end
  if renoise.song().selected_track_index_observable:has_notifier(common_track_change_hook) == true then
    renoise.song().selected_track_index_observable:remove_notifier(common_track_change_hook)
  end
  if renoise.song().selected_track.solo_state_observable:has_notifier(common_solo_hook) == true then
    renoise.song().selected_track.solo_state_observable:remove_notifier(common_solo_hook)
  end
  if renoise.song().selected_track.mute_state_observable:has_notifier(common_mute_hook) == true then
    renoise.song().selected_track.mute_state_observable:remove_notifier(common_mute_hook)
  end
  if renoise.song().transport.edit_mode_observable:has_notifier(common_editmode_hook) == true then
    renoise.song().transport.edit_mode_observable:remove_notifier(common_editmode_hook)
  end
  if renoise.song().transport.loop_pattern_observable:has_notifier(common_patternloop_hook) == true then
    renoise.song().transport.loop_pattern_observable:remove_notifier(common_patternloop_hook)
  end
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function common_volume_change_hook()
  -- update the display and move the fader on volume change
  if fader_flipped == false then
    move_fader_to(renoise.song().selected_track.prefx_volume.value * 1023
                  / 1.4125375747681)
  end
end


function common_pan_change_hook()
  -- update the display on pan value change
  if fader_flipped == true then
    move_fader_to(renoise.song().selected_track.prefx_panning.value * 1023)
  end
end


function common_track_change_hook()
  -- update on track change
  if renoise.song().selected_track.prefx_volume.value_observable:has_notifier(common_volume_change_hook) == false then
    renoise.song().selected_track.prefx_volume.value_observable:add_notifier(common_volume_change_hook)
  end
  if renoise.song().selected_track.prefx_panning.value_observable:has_notifier(common_pan_change_hook) == false then
    renoise.song().selected_track.prefx_panning.value_observable:add_notifier(common_pan_change_hook)
  end
  common_volume_change_hook()
  common_pan_change_hook()
  
  if renoise.song().selected_track.solo_state_observable:has_notifier(common_solo_hook) == false then
    renoise.song().selected_track.solo_state_observable:add_notifier(common_solo_hook)
  end
  if renoise.song().selected_track.mute_state_observable:has_notifier(common_mute_hook) == false then
    renoise.song().selected_track.mute_state_observable:add_notifier(common_mute_hook)
  end
  common_solo_hook()
  common_mute_hook()

  
  -- show track name on lcd display (bottom row)
  local n = string.sub(renoise.song().selected_track.name, 1, 13)
  local l = string.len(n)
  
  if l < 13 then
    for i = 1,(13-l) do
      n = n .. " "
    end
  end
  lower_display_hold_cancel()
  display_message(string.format("%02u",renoise.song().selected_track_index - 1)
                  .. ":" .. n, 16)
  lower_display_hold()
  
  --update leds (L for seq track, R for send, both for master)
  if renoise.song().selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    led_off(LED_TRACKR)
  else
    led_on(LED_TRACKR)
  end
  if renoise.song().selected_track.type == renoise.Track.TRACK_TYPE_SEND then
    led_off(LED_TRACKL)
  else
    led_on(LED_TRACKL)
  end
end


function common_solo_hook()
  -- update on solo state change
  --print("common_solo_hook")
  if renoise.song().selected_track.solo_state == true then
    led_on(LED_SOLO)
  else
    led_off(LED_SOLO)
  end
end


function common_mute_hook()
  -- update on mute state change
  --print("common_mute_hook")
  if renoise.song().selected_track.mute_state == 1 then
    led_off(LED_MUTE)
  else
    led_on(LED_MUTE)
  end
end


function common_editmode_hook()
  -- updates on toggle of editmode
  if renoise.song().transport.edit_mode == true then
    led_on(LED_RECORD)
  else
    led_off(LED_RECORD)
  end
end


function common_patternloop_hook()
  -- updates on toggle of pattern looping
  if renoise.song().transport.loop_pattern == true then
    led_on(LED_LOOP)
  else
    led_off(LED_LOOP)
  end
end
