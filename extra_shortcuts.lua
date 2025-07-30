--functions to cycle through the selected plugins presets

------------------------------------------------------------------
--next VSTi presets
renoise.tool():add_keybinding {
  name = "Global:Tools:`VFM` Next VSTi Preset",
  invoke = function() increment_preset() end
}

function increment_preset()
  --renoise vars
  local song = renoise.song()
  local instrument = song.selected_instrument_index
 
  --return if no plugin in the current slot
  if not song.instruments[instrument].plugin_properties.plugin_device then
    renoise.app():show_status("Vsti From Menu Tool (Need to choose a plugin to change preset)")
    return
  end
  
  --plugin preset properties
  local plugin_properties = song.instruments[instrument].plugin_properties
  
  --if one preset or less available then tell user
  if #plugin_properties.plugin_device.presets < 2 then
    renoise.app():show_status("Vsti From Menu Tool (No Other Presets Acessible by Renoise For This Plugin)")
    return
  end
    
  local presets = plugin_properties.plugin_device.presets
  local plugin_device = plugin_properties.plugin_device
  
  -- if not at the last available preset increment to the next one
  if #presets >= (plugin_properties.plugin_device.active_preset + 1) then
    plugin_device.active_preset =  plugin_properties.plugin_device.active_preset + 1 
    renoise.app():show_status("Vsti From Menu Tool ("..plugin_device.active_preset..": "..plugin_device.presets[plugin_device.active_preset]..")")  
  else
    --else cycle back to first preset
    plugin_device.active_preset =  1 
    renoise.app():show_status("Vsti From Menu Tool ("..plugin_device.active_preset..": "..plugin_device.presets[plugin_device.active_preset]..")")
  end
end


--previous VSTi presets
renoise.tool():add_keybinding {
  name = "Global:Tools:`VFM` Previous VSTi Preset",
  invoke = function() decrement_preset() end
}

function decrement_preset()
  --renoise vars
  local song = renoise.song()
  local instrument = song.selected_instrument_index
  
  --return if no plugin in the current slot
  if not song.instruments[instrument].plugin_properties.plugin_device then
    renoise.app():show_status("Vsti From Menu Tool (Need to choose a plugin to change preset)")
    return
  end
  --plugin preset properties
  local plugin_properties = song.instruments[instrument].plugin_properties
  
   --if one preset or less available then tell user
  if #plugin_properties.plugin_device.presets < 2 then
    renoise.app():show_status("Vsti From Menu Tool (No Other Presets Acessible by Renoise For This Plugin)")
    return
  end
   
  local presets = plugin_properties.plugin_device.presets
  local plugin_device = plugin_properties.plugin_device
   
  -- if not at the first available preset increment to the next one
  if  1 < (plugin_device.active_preset) then
    plugin_device.active_preset =  plugin_properties.plugin_device.active_preset - 1 
    renoise.app():show_status("Vsti From Menu Tool ("..plugin_device.active_preset..": "..plugin_device.presets[plugin_device.active_preset]..")")  
  else
    --else cycle back to last preset
    plugin_device.active_preset =  #presets 
    renoise.app():show_status("Vsti From Menu Tool ("..plugin_device.active_preset..": "..plugin_device.presets[plugin_device.active_preset]..")")
  end
end
