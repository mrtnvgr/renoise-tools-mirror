--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- DSP mode code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variable
-------------------------------------------------------------------------------
dsp_param_index = 1


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function dsp_init()
  if renoise.song().selected_track_index_observable:has_notifier(dsp_track_change_hook) == false then
    renoise.song().selected_track_index_observable:add_notifier(dsp_track_change_hook)
  end
  if renoise.song().selected_device_index_observable:has_notifier(dsp_device_change_hook) == false then
    renoise.song().selected_device_index_observable:add_notifier(dsp_device_change_hook)
  end
  if renoise.song().selected_device ~= nil then
    if renoise.song().selected_device.is_active_observable:has_notifier(dsp_device_enable_change_hook) == false then
      renoise.song().selected_device.is_active_observable:add_notifier(dsp_device_enable_change_hook)
    end
  end
  
  --TODO:leds
  led_on(LED_EQ)
  

  --TODO:lcd display
  clear_display()
  dsp_track_change_hook()
  dsp_param_change_hook()

  -- mode state
  current_mode = MODE_DSP
end


function dsp_exit()
  if renoise.song().selected_track_index_observable:has_notifier(dsp_track_change_hook) == true then
    renoise.song().selected_track_index_observable:remove_notifier(dsp_track_change_hook)
  end
  if renoise.song().selected_device_index_observable:has_notifier(dsp_device_change_hook) == true then
    renoise.song().selected_device_index_observable:remove_notifier(dsp_device_change_hook)
  end
  if renoise.song().selected_device ~= nil then
    if renoise.song().selected_device.is_active_observable:has_notifier(dsp_device_enable_change_hook) == true then
      renoise.song().selected_device.is_active_observable:remove_notifier(dsp_device_enable_change_hook)
    end
  end
  -- turn off leds that are used in this mode
  led_off(LED_EQ)
  led_off(LED_F1)
  led_off(LED_F2)
  led_off(LED_F3)
  led_off(LED_F4)
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function dsp_track_change_hook()
  display_message(string.format("T:%02u", renoise.song().selected_track_index - 1), 12)
  dsp_param_index = 1
  
  -- select a device on track change
  if renoise.song().selected_device_index == nil then
    renoise.song().selected_device_index = 1
  end
  dsp_device_change_hook()
end


function dsp_device_change_hook()
  dsp_param_index = 1
  if renoise.song().selected_device ~= nil then
    local n = renoise.song().selected_device.name
    -- Workaround for long VST effect names
    if string.sub(n, 1, 5) == "VST: " then
      -- find starting position
      local s = string.find(n, ":", 5)
      n = string.sub(n, s+2)
    end
    
    n = string.sub(n, 1, 11)
    
    local l = string.len(n)

    if l < 11 then
      for i = 1,(11-l) do
        n = n .. " "
      end
    end
    display_message(n, 0)
    
    -- bind led updates
    if renoise.song().selected_device.is_active_observable:has_notifier(dsp_device_enable_change_hook) == false then
      renoise.song().selected_device.is_active_observable:add_notifier(dsp_device_enable_change_hook)
    end
    dsp_device_enable_change_hook() --handled LED_F1
    
    if renoise.song().selected_device.external_editor_available == true then
      if renoise.song().selected_device.external_editor_visible == true then
        led_on(LED_F2)
      else
        led_off(LED_F2)
      end
    else
      led_off(LED_F2)
    end
    
    if renoise.song().selected_device_index == 1 then
      led_on(LED_F3)
    else
      led_off(LED_F3)
    end
    if renoise.song().selected_device_index == #renoise.song().selected_track.devices then
      led_on(LED_F4)
    else
      led_off(LED_F4)
    end
  else
    display_message("Select DSP ", 0)
    led_off(LED_F1)
    led_off(LED_F2)
    led_off(LED_F3)
    led_off(LED_F4)
  end
  dsp_param_change_hook()
end


function dsp_device_enable_change_hook()
  if renoise.song().selected_device ~= nil then
    if renoise.song().selected_device.is_active == true then
      led_on(LED_F1)
    else
      led_off(LED_F1)
    end
  end
end


function dsp_param_change_hook()
    -- update display
  if renoise.song().selected_device ~= nil then
    local n = string.sub(renoise.song().selected_device.parameters[dsp_param_index].name, 1, 9)
    local l = string.len(n)
  
    if l < 9 then
      for i = 1,(9-l) do
        n = n .. " "
      end
    end
      
    local s = n .. " "
    n = string.sub(renoise.song().selected_device.parameters[dsp_param_index].value_string, 1, 6)
    l = string.len(n)
  
    if l < 6 then
      for i = 1,(6-l) do
         n = n .. " "
      end
    end
    
    display_message(s .. n, 16)  
  else
    clear_lower_display()
  end
end


--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------
function dsp_button(button)
  if button == BUTTON_F1 then
    -- enable dsp toggle
    if renoise.song().selected_device ~= nil then
      if renoise.song().selected_device.name ~= "TrackVolPan" then
        renoise.song().selected_device.is_active =
        not renoise.song().selected_device.is_active
      end
    end
  elseif button == BUTTON_F2 then
    -- view external editor
    if renoise.song().selected_device.external_editor_available == true then
      renoise.song().selected_device.external_editor_visible
      = not renoise.song().selected_device.external_editor_visible
      if renoise.song().selected_device.external_editor_visible == true then
        led_on(LED_F2)
      else
        led_off(LED_F2)
      end
    end
  --[[ no action for these:
  elseif button == BUTTON_F3 then
    --
  elseif button == BUTTON_F4 then
    --
  elseif button == BUTTON_ENC1TOUCH then
    --
  elseif button == BUTTON_ENC2TOUCH then
    --
  elseif button == BUTTON_ENC3TOUCH then
    --
  ]]--
  end
end


function dsp_encoder(encoderid, value)
  if encoderid == ENC_LEFT then
    -- select dsp
    local i = renoise.song().selected_device_index + value
    if i < 1 then
      i = 1
    elseif i > #renoise.song().selected_track.devices then
      i = #renoise.song().selected_track.devices
    end
    renoise.song().selected_device_index = i
  elseif encoderid == ENC_MIDDLE then
    -- select parameter
    local p = dsp_param_index + value
    if p < 1 then
      p = 1
    elseif p > #renoise.song().selected_device.parameters then
      p = #renoise.song().selected_device.parameters
    end
    dsp_param_index = p
    dsp_param_change_hook()
  elseif encoderid == ENC_RIGHT then
    -- set parameter value
    if renoise.song().selected_device == nil then
      return -- no dsp
    end
    local vmax = renoise.song().selected_device.parameters[dsp_param_index].value_max
    local vmin = renoise.song().selected_device.parameters[dsp_param_index].value_min
      
    local v = renoise.song().selected_device.parameters[dsp_param_index].value
              + value*((vmax - vmin)/256)
      
    if v > vmax then
      v = vmax
    elseif v < vmin then
      v = vmin
    end
    renoise.song().selected_device.parameters[dsp_param_index].value = v
    dsp_param_change_hook()
  end
end


function dsp_upper_display_release()
  clear_upper_display()
  dsp_track_change_hook()
end


function dsp_lower_display_release()
  dsp_param_change_hook()
end
