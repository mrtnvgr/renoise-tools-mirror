--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Sampler edit mode code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variable
-------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function samp_init()
  -- TODO:attach hooks
  if renoise.song().selected_sample_observable:has_notifier(samp_samp_select_hook) == false then
    renoise.song().selected_sample_observable:add_notifier(samp_samp_select_hook)
  end
  if renoise.song().selected_sample.volume_observable:has_notifier(samp_samp_volume_pan_change_hook) == false then
    renoise.song().selected_sample.volume_observable:add_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.panning_observable:has_notifier(samp_samp_volume_pan_change_hook) == false then
    renoise.song().selected_sample.panning_observable:add_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.transpose_observable:has_notifier(samp_trans_tune_change_hook) == false then
    renoise.song().selected_sample.transpose_observable:add_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.fine_tune_observable:has_notifier(samp_trans_tune_change_hook) == false then
    renoise.song().selected_sample.fine_tune_observable:add_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.beat_sync_enabled_observable:has_notifier(samp_beatsync_toggle_hook) == false then
    renoise.song().selected_sample.beat_sync_enabled_observable:add_notifier(samp_beatsync_toggle_hook)
  end
  if renoise.song().selected_sample.autoseek_observable:has_notifier(samp_autoseek_change_hook) == false then
    renoise.song().selected_sample.autoseek_observable:add_notifier(samp_autoseek_change_hook)
  end
  
  -- TODO:leds
  led_on(LED_PLUGIN)
  samp_beatsync_toggle_hook()
  samp_autoseek_change_hook()
  samp_record_dialog_state_hook()

  -- TODO:lcd display
  samp_samp_select_hook()
  samp_samp_volume_pan_change_hook()

  -- mode state
  current_mode = MODE_SAMP
end


function samp_exit()
  -- TODO:detach hooks
  if renoise.song().selected_sample_observable:has_notifier(samp_samp_select_hook) == true then
    renoise.song().selected_sample_observable:remove_notifier(samp_samp_select_hook)
  end
  if renoise.song().selected_sample.volume_observable:has_notifier(samp_samp_volume_pan_change_hook) == true then
    renoise.song().selected_sample.volume_observable:remove_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.panning_observable:has_notifier(samp_samp_volume_pan_change_hook) == true then
    renoise.song().selected_sample.panning_observable:remove_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.transpose_observable:has_notifier(samp_trans_tune_change_hook) == true then
    renoise.song().selected_sample.transpose_observable:remove_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.fine_tune_observable:has_notifier(samp_trans_tune_change_hook) == true then
    renoise.song().selected_sample.fine_tune_observable:remove_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.beat_sync_enabled_observable:has_notifier(samp_beatsync_toggle_hook) == true then
    renoise.song().selected_sample.beat_sync_enabled_observable:remove_notifier(samp_beatsync_toggle_hook)
  end
  if renoise.song().selected_sample.autoseek_observable:has_notifier(samp_autoseek_change_hook) == true then
    renoise.song().selected_sample.autoseek_observable:remove_notifier(samp_autoseek_change_hook)
  end
  
  
  -- turn off leds that are used in this mode
  led_off(LED_PLUGIN)
  led_off(LED_F1)
  led_off(LED_F2)
  led_off(LED_F3)
  led_off(LED_F4)
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function samp_samp_select_hook()
  -- update display
  local n = string.sub(renoise.song().selected_sample.name, 1, 10)
  local l = string.len(n)
  
  if l < 10 then
    for i = 1,(10-l) do
      n = n .. " "
    end
  end
  upper_display_hold_cancel()
  display_message(string.format("%02u.%02u:",
                                renoise.song().selected_instrument_index,
                                renoise.song().selected_sample_index)
                  .. n, 0)
  -- update hooks
  if renoise.song().selected_sample.volume_observable:has_notifier(samp_samp_volume_pan_change_hook) == false then
    renoise.song().selected_sample.volume_observable:add_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.panning_observable:has_notifier(samp_samp_volume_pan_change_hook) == false then
    renoise.song().selected_sample.panning_observable:add_notifier(samp_samp_volume_pan_change_hook)
  end
  if renoise.song().selected_sample.transpose_observable:has_notifier(samp_trans_tune_change_hook) == false then
    renoise.song().selected_sample.transpose_observable:add_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.fine_tune_observable:has_notifier(samp_trans_tune_change_hook) == false then
    renoise.song().selected_sample.fine_tune_observable:add_notifier(samp_trans_tune_change_hook)
  end
  if renoise.song().selected_sample.beat_sync_enabled_observable:has_notifier(samp_beatsync_toggle_hook) == false then
    renoise.song().selected_sample.beat_sync_enabled_observable:add_notifier(samp_beatsync_toggle_hook)
  end
  if renoise.song().selected_sample.autoseek_observable:has_notifier(samp_autoseek_change_hook) == false then
    renoise.song().selected_sample.autoseek_observable:add_notifier(samp_autoseek_change_hook)
  end
  -- update leds
  samp_beatsync_toggle_hook()
  samp_autoseek_change_hook()
end

  
function samp_samp_volume_pan_change_hook()
  local v = math.lin2db(renoise.song().selected_sample.volume)
  local p = renoise.song().selected_sample.panning
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

  display_message("V:" .. v_str .. " P:" .. p_str, 16)
end


function samp_trans_tune_change_hook()
  -- update lcd
  lower_display_hold_cancel()
  display_message(string.format("T:%+04dst F:%+04dc",
                                renoise.song().selected_sample.transpose,
                                renoise.song().selected_sample.fine_tune),
                  16)
  lower_display_hold()
end


function samp_autoseek_change_hook()
  -- update led
  if renoise.song().selected_sample.autoseek == true then
    led_on(LED_F1)
  else
    led_off(LED_F1)
  end
end


function samp_beatsync_toggle_hook()
  -- update led
  if renoise.song().selected_sample.beat_sync_enabled == true then
    led_on(LED_F2)
  else
    led_off(LED_F2)
  end
end


function samp_record_dialog_state_hook()
  -- update led
  if renoise.app().window.sample_record_dialog_is_visible == true then
    led_on(LED_F3)
  else
    led_off(LED_F3)
  end
end


--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------
function samp_button(button)
  if button == BUTTON_F1 then
    if shifted == SHIFT_OFF then
      -- autoseek toggle
      renoise.song().selected_sample.autoseek = 
        not renoise.song().selected_sample.autoseek
    elseif shifted == SHIFT_ON then
      --
    end
  elseif button == BUTTON_F2 then
    if shifted == SHIFT_OFF then
      -- beat sync toggle
      renoise.song().selected_sample.beat_sync_enabled =
        not renoise.song().selected_sample.beat_sync_enabled
    elseif shifted == SHIFT_ON then
      --
    end
  elseif button == BUTTON_F3 then
    if shifted == SHIFT_OFF then
      renoise.app().window.sample_record_dialog_is_visible = 
        not renoise.app().window.sample_record_dialog_is_visible
      samp_record_dialog_state_hook() 
    elseif shifted == SHIFT_ON then
      --
    end
  elseif button == BUTTON_F4 then
    if shifted == SHIFT_OFF then
      -- start/stop sample record
      renoise.song().transport:start_stop_sample_recording()
    elseif shifted == SHIFT_ON then
      -- cancel sample record
      renoise.song().transport:cancel_sample_recording()
    end
  elseif button == BUTTON_ENC1TOUCH then
    if shifted == SHIFT_OFF then
      --
    elseif shifted == SHIFT_ON then
      samp_trans_tune_change_hook()
    end
  elseif button == BUTTON_ENC2TOUCH then
    if shifted == SHIFT_OFF then
      --
    elseif shifted == SHIFT_ON then
      samp_trans_tune_change_hook()
    end
  elseif button == BUTTON_ENC3TOUCH then
    if shifted == SHIFT_OFF then
      --
    elseif shifted == SHIFT_ON then
      lower_display_hold_cancel()
      samp_samp_volume_pan_change_hook()
    end
  end
end


function samp_encoder(encoderid, value)
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
      if renoise.song().selected_sample.beat_sync_enabled == false then
        -- transpose
        local t = renoise.song().selected_sample.transpose + value
        if t < -120 then
          t = -120
        elseif t > 120 then
          t = 120
        end
        renoise.song().selected_sample.transpose = t
      end
    end
  elseif encoderid == ENC_MIDDLE then
    if shifted == SHIFT_OFF then
      -- select sample
      local i = renoise.song().selected_sample_index + value
      if i < 1 then
        i = 1
      elseif i > #renoise.song().selected_instrument.samples then
        i = #renoise.song().selected_instrument.samples
      end
      renoise.song().selected_sample_index = i
    elseif shifted == SHIFT_ON then
      if renoise.song().selected_sample.beat_sync_enabled == false then
        -- fine tune
        local f = renoise.song().selected_sample.fine_tune + value
        if f < -127 then
          f = -127
        elseif f > 127 then
          f = 127
        end
        renoise.song().selected_sample.fine_tune = f
      end
    end
  elseif encoderid == ENC_RIGHT then
    if shifted == SHIFT_OFF then
      lower_display_hold_cancel()
      -- sample volume
      local v = math.db2lin(renoise.song().selected_sample.volume) + ((math.db2lin(0.01)-1)*value)
      if v < 1 then
        v = 1
      elseif v > 1.5848931924611 then
        v = 1.5848931924611
      end
      renoise.song().selected_sample.volume = math.lin2db(v)
    elseif shifted == SHIFT_ON then
      lower_display_hold_cancel()
      -- sample pan
      local p = tonumber(string.format("%.2f",
                         renoise.song().selected_sample.panning))
                         + value/100
      if p > 1 then
        p = 1
      elseif p < 0 then
        p = 0
      end
      renoise.song().selected_sample.panning = p
    end
  end
end


function samp_upper_display_release()
  samp_samp_select_hook()
end


function samp_lower_display_release()
  samp_samp_volume_pan_change_hook()
end
