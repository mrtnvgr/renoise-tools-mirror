local dsp_notifiers = {}
local global_dsp = nil
local global_dsp_track = nil

local instrument_notifiers = {}
local global_instrument = nil
local gui = nil
local gui_dialog = nil

function show_gui(plugin_type)

  if gui == nil then
    gui = renoise.ViewBuilder()
  else
  
    if gui_dialog.visible then
      return
    else
      gui = nil
      gui = renoise.ViewBuilder()
      gui_dialog = nil
    end
    
  end
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  
  local border_back = gui:column {
    gui:row{
      gui:text{
        text = "Scan current selected:"
      },
      gui:switch {
        id = "plugin_type",
        width = 200,
        value = plugin_type,
        items = {"DSP", "Instrument"},
        notifier = function(new_index)
          if new_index == 2 then
            get_active_instrument_parameters()
            gui.views['mixer_button'].active = false
          else
            gui.views['mixer_button'].active = true
            get_active_DSP_parameters()
          end
        end
      },
      gui:space{ width = 168},
      gui:button{
        text = "Refresh",
        tooltip = "Refresh parameters in dropdown menu.",
        notifier = function()
          if gui.views['plugin_type'].value == 2 then
            get_active_instrument_parameters()
          else
            get_active_DSP_parameters()
          end
          
        end
      },
    },
    gui:row{
      gui:popup{
        id = "plugin_parameter_names",
        value = 1,
        width = 400,
        items = {}
      },
      gui:text{
        id = "plugin_value",
        width = 80,
        text = "None"
      },
      gui:button{
        text = "(un)Mute",
        tooltip = "In case this is triggered by an LFO or some other sequencer device",
        notifier = function()
          local parameter = gui.views['plugin_parameter_names'].value
          local sng = renoise.song()
          
          if gui.views['plugin_type'].value == 2 then
            if sng.instruments[global_instrument] ~= nil then
              local ins = sng.instruments[global_instrument].plugin_properties
            
              if  ins.plugin_loaded then
                local vsti_parameters = ins.plugin_device.parameters
                local func_ref = 'i'..tostring(global_instrument)..'p'..tostring(parameter)
                local pnames = gui.views['plugin_parameter_names'].items
                
                if vsti_parameters[parameter].value_observable:has_notifier(instrument_notifiers[func_ref]) then
                  vsti_parameters[parameter].value_observable:remove_notifier(instrument_notifiers[func_ref])
                  pnames[parameter] = 'M'..pnames[parameter]
                else
                  vsti_parameters[parameter].value_observable:add_notifier(instrument_notifiers[func_ref])
                  pnames[parameter] = string.sub(pnames[parameter],2)
                end
              
                gui.views['plugin_parameter_names'].items = pnames              
              end
              
            end
            
          else
            local vst_parameters = sng.tracks[global_dsp_track].devices[global_dsp].parameters
            local func_ref = 'd'..tostring(global_dsp)..'p'..tostring(parameter)
            local pnames = gui.views['plugin_parameter_names'].items
            if parameter <= #vst_parameters then
              if vst_parameters[parameter].value_observable:has_notifier(dsp_notifiers[func_ref]) then
                vst_parameters[parameter].value_observable:remove_notifier(dsp_notifiers[func_ref])
                pnames[parameter] = 'M'..pnames[parameter]
              else
                vst_parameters[parameter].value_observable:add_notifier(dsp_notifiers[func_ref])
                pnames[parameter] = string.sub(pnames[parameter],2)
              end              
              
              gui.views['plugin_parameter_names'].items = pnames              
            end
          end
          
        end
      },
    },
    gui:horizontal_aligner{
      mode="center",
      gui:row{
        gui:button{
          id = "mixer_button",
          active = false,
          text = "Make visible in mixer view",
          tooltip = "You can rightclick and drag the parameter slider in the mixer-view to enable\n"..
          "automation where in turn you can toggle to view automated parameters only.",
          notifier = function()
          local sng = renoise.song()
            local trig_dsp_parm = gui.views['plugin_parameter_names'].value
            if global_dsp_track ~= nil and trig_dsp_parm ~= nil then
              if sng.tracks[global_dsp_track].devices[global_dsp] ~= nil then
                local parm_visibility = sng.tracks[global_dsp_track].devices[global_dsp].parameters[trig_dsp_parm]
                parm_visibility.show_in_mixer = not parm_visibility.show_in_mixer
              end
            end
            
          end
        },
      },
    },
  }
  
  gui_dialog = renoise.app():show_custom_dialog(
    "Plugin parameter scanner", 
    gui:column {
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,
      border_back,
    }
  )
  if plugin_type == 2 then
    get_active_instrument_parameters()
    gui.views['mixer_button'].active = false
  else
    gui.views['mixer_button'].active = true
    get_active_DSP_parameters()
  end  
    
end

function get_active_instrument_parameters()
  local sng = renoise.song()
  local cur_ins = sng.selected_instrument_index
  
  remove_notifiers()
  
  global_instrument = cur_ins
  
  if sng.instruments[cur_ins].plugin_properties.plugin_loaded == false then
    global_instrument = nil
    return -1
  end  
    
  local vsti_parameters = sng.instruments[cur_ins].plugin_properties.plugin_device.parameters
  
  if sng.instruments[cur_ins].plugin_properties.plugin_device.external_editor_available then
    sng.instruments[cur_ins].plugin_properties.plugin_device.external_editor_visible = true
  end
  
  if gui ~= nil then
    local parameter_names = {}
    
    for x = 1, #vsti_parameters do
      parameter_names[x] = "[".. string.format("%04d", tostring(x)).."] "..vsti_parameters[x].name
    end
    gui.views['plugin_parameter_names'].items = parameter_names
  end

  for x = 1, #vsti_parameters do
    local func_ref = 'i'..tostring(cur_ins)..'p'..tostring(x)
    
    if instrument_notifiers[func_ref] == nil then
      instrument_notifiers[func_ref] = function()
        local title = vsti_parameters[x].name
        local parvalue = vsti_parameters[x].value_string
        gui.views['plugin_parameter_names'].value = x
        gui.views['plugin_value'].text = parvalue
      end
    end
    
    if not vsti_parameters[x].value_observable:has_notifier(instrument_notifiers[func_ref]) then
      vsti_parameters[x].value_observable:add_notifier(instrument_notifiers[func_ref])
    end
    
  end
  
end


function get_active_DSP_parameters()
  local sng = renoise.song()
  local cur_dsp = sng.selected_track_device_index
  local cur_track = sng.selected_track_index
  
  remove_notifiers()
  
  global_dsp = cur_dsp
  global_dsp_track = cur_track
  if sng.tracks[cur_track].devices[cur_dsp] ~= nil then
    if sng.tracks[cur_track].devices[cur_dsp].external_editor_available then
      if not sng.tracks[cur_track].devices[cur_dsp].external_editor_visible then
        sng.tracks[cur_track].devices[cur_dsp].external_editor_visible = true
      end
    end
  else
    return -1
  end
      
  local vst_parameters = sng.tracks[cur_track].devices[cur_dsp].parameters

  if gui ~= nil then
    local parameter_names = {}
    
    for x = 1, #vst_parameters do
      if vst_parameters[x].is_automated and not vst_parameters[x].is_midi_mapped then
        parameter_names[x] = "^".. string.format("%04d", tostring(x)).."^ "..vst_parameters[x].name
      else 
        if not vst_parameters[x].is_automated and vst_parameters[x].is_midi_mapped then
          parameter_names[x] = "*".. string.format("%04d", tostring(x)).."* "..vst_parameters[x].name
        else 
          if vst_parameters[x].is_automated and vst_parameters[x].is_midi_mapped then
            parameter_names[x] = "^".. string.format("%04d", tostring(x)).."* "..vst_parameters[x].name
          else
            parameter_names[x] = "[".. string.format("%04d", tostring(x)).."] "..vst_parameters[x].name
          end
        end
      end
    end
    gui.views['plugin_parameter_names'].items = parameter_names
  end

  for x = 1, #vst_parameters do
    local func_ref = 'd'..tostring(cur_dsp)..'p'..tostring(x)
    
    if dsp_notifiers[func_ref] == nil then
      dsp_notifiers[func_ref] = function()
        local title = vst_parameters[x].name
        local parvalue = vst_parameters[x].value_string
        gui.views['plugin_parameter_names'].value = x
        gui.views['plugin_value'].text = parvalue
      end
    end
    
    if not vst_parameters[x].value_observable:has_notifier(dsp_notifiers[func_ref]) then
      vst_parameters[x].value_observable:add_notifier(dsp_notifiers[func_ref])
    end
    
  end
  
end

function remove_notifiers()

  local sng = renoise.song()

  if global_instrument ~= nil and sng.instruments[global_instrument].plugin_properties.plugin_loaded == true then
    --Clear instrument plugin notifiers if they are already filled
    local vsti_parameters = sng.instruments[global_instrument].plugin_properties.plugin_device.parameters

    for x = 1, #vsti_parameters do
      local func_ref = 'i'..tostring(global_instrument)..'p'..tostring(x)

      if instrument_notifiers[func_ref] ~= nil then
        
        if vsti_parameters[x].value_observable:has_notifier(instrument_notifiers[func_ref]) then
          vsti_parameters[x].value_observable:remove_notifier(instrument_notifiers[func_ref])
        end
        
      end
              
    end
    
  end  
  

  if global_dsp ~= nil and sng.tracks[global_dsp_track].devices[global_dsp] ~= nil then
    --Clear DPS device notifiers if they are already filled
    local vst_parameters = sng.tracks[global_dsp_track].devices[global_dsp].parameters
  
    for x = 1, #vst_parameters do
      local func_ref = 'd'..tostring(global_dsp)..'p'..tostring(x)
    
      if dsp_notifiers[func_ref] ~= nil then
      
        if vst_parameters[x].value_observable:has_notifier(dsp_notifiers[func_ref]) then
          vst_parameters[x].value_observable:remove_notifier(dsp_notifiers[func_ref])
        end
        
      end
              
    end
    
  end  

  instrument_notifiers = {}
  dsp_notifiers = {}
  gui.views['plugin_parameter_names'].items = {}

end

--[[
 renoise.tool():add_menu_entry {
   name = bool_menu[false],
   invoke = set_notifier
}
--]]

 renoise.tool():add_menu_entry {
   name = "Mixer:Track plugin parameters",
   invoke = function () show_gui(1) end
}

 renoise.tool():add_menu_entry {
   name = "DSP Device:Track plugin parameters",
   invoke = function () show_gui(1) end
}

 renoise.tool():add_menu_entry {
   name = "Instrument Box:Track plugin parameters",
   invoke = function () show_gui(2) end
}

 renoise.tool():add_menu_entry {
   name = "Track Automation List:Track plugin parameters",
   invoke = function () show_gui(1) end
}

