
function safe_set(view_id, value)
  changed_from_renoise = true
  vb.views[view_id].value = value
  changed_from_renoise = nil
end

function show_dialog(tool_name)

 vb = renoise.ViewBuilder()

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local BUTTON_WIDTH = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local button_in_color = nil
  local button_out_color = nil
  local button_multi_track_color = false
  local ins_max = visible_range
  local master_in = 1

  if #instrument < ins_max then
    ins_max = #instrument
  end

  created_range = ins_max

  if multi_track == true then
    button_multi_track_color = {0xff, 0xb6, 0x00}
  else
    button_multi_track_color = {0x2d, 0x11, 0xff}
  end  

  if midi_in_gui == true then
    button_in_color = {0xff, 0xb6, 0x00}
  else
    button_in_color = {0x2d, 0x11, 0xff}
  end   

  if midi_out_gui == true then
    button_out_color = {0xff, 0xb6, 0x00}
  else
    button_out_color = {0x2d, 0x11, 0xff}
  end   

  local dialog_content = vb:column {
    margin = CONTENT_MARGIN
  }

  for _ = 1, #indevices do

    if master.device == master.devices[_] then
      master_in = _
      break
    end    

  end
  
  local chain_device_row = vb:row{
    vb:text {
      text="Solo/Chain device",
    },
    vb:popup{
      width = 150,
      value = master_in,
      tooltip = "This device will override the selected midi"..
      " device for\ninstruments that are checked as solo or chained instrument",
      items = master.devices,
      id='masterdevice',
      --bind=preferences.master_device,
      notifier = function(value)
        master.device = master.devices[value]
        preferences.master_device.value = value+1
        preferences:save_as("preferences.xml")
        for x = 1, #selector.instrument.chain do
        
          if selector.instrument.chain[x] == true then
            
            if solo_instrument == nil then
              changed_from_renoise = true
              set_chain_instrument(x-start_instrument+1,true)
            end        
            
          end
          
        end
        set_solo_instrument()
      end
    },
    vb:text {
      text="Channel",
    },
    vb:valuebox{
      width = 55,
      min = 0,
      max = 16,
      value = master.channel,
      id="masterchannel",
      bind=preferences.master_channel,
      tostring = function(value) 

        if value == 0 then
          return "Any"
         else
          return tostring(value)
        end

      end,
      tonumber = function(str) 
        return tonumber(str)
      end,
      notifier = function(value)
        master.channel = value
        preferences:save_as("preferences.xml")
        for x = 1, #selector.instrument.chain do
          changed_from_renoise = true
          if selector.instrument.chain[x] == true then
            
            if solo_instrument == nil then
              
              set_chain_instrument(x-start_instrument+1,true)
            end        
            
          end
          
        end
        set_solo_instrument()
      end
    },
    vb:space{width=5},
    vb:button {
      text=track_edit_text,
      color = button_multi_track_color,
      tooltip = propagation_info,
      id="button_multi_track",
      notifier = function(value)
--        duplicate_track_actions()
        local song = renoise.song()
        multi_track = not multi_track       
        if multi_track == true then
          button_multi_track_color = {0xff, 0xb6, 0x00}
          if not song.patterns[song.selected_pattern_index]:has_line_notifier(pattern_line_notifier) then
            song.patterns[song.selected_pattern_index]:add_line_notifier(pattern_line_notifier) 
          end
          if not renoise.tool().app_idle_observable:has_notifier(idle_handler) then
            renoise.tool().app_idle_observable:add_notifier(idle_handler)
          end
        else
          button_multi_track_color = {0x2d, 0x11, 0xff}
        end
        vb.views['button_multi_track'].color = button_multi_track_color
--]]
      end
    },    
    vb:space{width=5},
    vb:button {
      text="Midi in",
      color = button_in_color,
      id="button_midi_in",
      notifier = function(value)
        midi_in_gui = not midi_in_gui

        if midi_in_gui == true then
          vb.views['button_midi_in'].color = {0xff, 0xb6, 0x00}
        else
          vb.views['button_midi_in'].color = {0x2d, 0x11, 0xff}
        end
        preferences.midi_in.value = midi_in_gui
        preferences:save_as("preferences.xml")
        toggle_midi_in()        
        
      end
    },    
    vb:button {
      text="Midi out",
      color = button_out_color,
      id="button_midi_out",
      notifier = function(value)
        midi_out_gui = not midi_out_gui

        if midi_out_gui == true then
          vb.views['button_midi_out'].color = {0xff, 0xb6, 0x00}
        else
          vb.views['button_midi_out'].color = {0x2d, 0x11, 0xff}
        end    
        preferences.midi_out.value = midi_out_gui
        preferences:save_as("preferences.xml")
        
        toggle_midi_out()
      end
    }    
  }
  dialog_content:add_child(chain_device_row)

  local title_row = vb:row{
    vb:text {
      text="Solo",
    },
    vb:text {
      text="Chain",
    },
    vb:text {
      text="Ins",
    },
    vb:text {
      text="Name",
    },
    vb:space{width=265},
    vb:text {
      text="Track",
    },
    vb:space{id='space_dev_in',visible = midi_in_gui,width=122},
    vb:text {
      id="column_dev_in",
      text="Device In",
      visible = midi_in_gui,
    },    
    vb:space{id='space_chan_in',visible = midi_in_gui,width=100},
    vb:text {
      id="column_chan_in",
      text="Channel In",
      visible = midi_in_gui,
    },    
--    vb:space{width=60},
    vb:text {
      id="column_dev_out",
      text="Device Out",
      visible = midi_out_gui,
    },    
    vb:space{id='space_chan_out',visible = midi_out_gui,width=92},
    vb:text {
      id="column_chan_out",
      text="Channel Out",
      visible = midi_out_gui,
    },    
    
  }  
  dialog_content:add_child(title_row)

  local cval = nil

  for range = 1,ins_max do
    -- create a row for each instrument
    local t = range+start_instrument-1
    if selector.instrument.indevice[t] ~= "" then
    
      for _ = 1, #devices do
      
        if indevices[_] == selector.instrument.indevice[t] then
          indevice_value = _
          break
        end
        
      end
      
    end
    if selector.instrument.outdevice[t] ~= "" then
    
      for _ = 1, #devices do
      
        if outdevices[_] == selector.instrument.outdevice[t] then
          outdevice_value = _
          break
        end
        
      end
      
    end
    local instrument_row = vb:row {
      vb:space{width=4},
      vb:checkbox{
        id='solo'..tostring(range),
        midi_mapping = "Midi Console:Solo"..tostring(range),
        notifier = function(value)
          if scrolled then
            if scrolled > 1 then
              scrolled = nil
              return
            else
              scrolled = scrolled + 1
            end 
          end           
          if value == true then 
            solo_instrument = range+start_instrument-1
            renoise.song().selected_instrument_index = solo_instrument
            set_solo_instrument()

            for solo_changer = 1, ins_max do
          
              if solo_changer ~= range then
                cval = "solo"..tostring(solo_changer)
                safe_set(cval, false)
              end
            
            end
            
          else
            if master.change then
              return
            end

            local found_checked = false

            for _ = 1, ins_max do
              if vb.views['solo'..tostring(_)].value == true then
                found_checked = true
                break
              end
            end

            if found_checked == false then
              solo_instrument = nil
--              update_device_in(range)
--              update_channel_in(range)
              spawn_midi_in_properties()

              for _ = 1,#selector.instrument.chain do
                local setting = selector.instrument.chain[_]

                if setting ~= false then
                  set_chain_instrument(_,setting)
                end

              end

            end
            
          end
           
        end
      },
      vb:space{width=10},
      vb:checkbox{
        id='chain'..tostring(range),
        midi_mapping = "Midi Console:Chain"..tostring(range),
        notifier = function(value)
          selector.instrument.chain[range+start_instrument-1] = value
            
          if solo_instrument == nil then
              set_chain_instrument(range,value)
          end
        end
      },
      vb:space{width=7},
      vb:text{
        id="ins_number"..tostring(range),
        text=string.format("%02X", range + (start_instrument - 2)),
      },
      vb:valuefield {
        min =0,
        max = #renoise.song().instruments,
        value = 0,
        width =300,
        id="ins_name"..tostring(range),
        tostring = function(value) 
        
          if range + (start_instrument - 1) <= #renoise.song().instruments then
            local ins_name = renoise.song().instruments[range + (start_instrument - 1)].name
            return ins_name
          end
          
        end,
        
        tonumber = function(str) 
        
          if range + (start_instrument - 1) <= #renoise.song().instruments then
            local ins_number = (range + (start_instrument - 1))
            renoise.song().instruments[ins_number].name = str
          end
          
        end,
      
        notifier = function(value)
        end
      },
      vb:popup{
        width = 150,
        value = 1,
        tooltip = "Instrument "..string.format("%02X", range + (start_instrument - 2)),
        items = tracks,
        id = "track"..tostring(range),
        notifier = function(value)
          if changed_from_renoise then
            changed_from_renoise = nil
            return
          end
        
          local xins_device = renoise.song().instruments[t].midi_input_properties
          
          if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
            xins_device.assigned_track_observable:remove_notifier(change_from_renoise)
          end
          local t = range+start_instrument-1
          if value > 1 then
            renoise.song().instruments[t].midi_input_properties.assigned_track = value - 1
            selector.instrument.track[t] = value - 1
          else
            renoise.song().instruments[t].midi_input_properties.assigned_track = 0
            selector.instrument.track[t] = 0
          end
          
          xins_device.assigned_track_observable:add_notifier(change_from_renoise)
        end
      },      
      vb:popup{
        width = 150,
        value = indevice_value,
        tooltip = "Instrument "..string.format("%02X", range + (start_instrument - 2)),
        visible = midi_in_gui,
        items = indevices,
        id = "devicein"..tostring(range),
        notifier = function(value)
          if changed_from_renoise then
            changed_from_renoise = nil
            return
          end

          local t = range+start_instrument-1
          local xins_device = renoise.song().instruments[t].midi_input_properties

          if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
            xins_device.device_name_observable:remove_notifier(change_from_renoise)
          end
          if value > 1 then

            if solo_instrument == nil then
              renoise.song().instruments[t].midi_input_properties.device_name = indevices[value]
              selector.instrument.indevice[t] = indevices[value]
            end

            
          else

            if solo_instrument == nil then
              renoise.song().instruments[t].midi_input_properties.device_name = ""
              selector.instrument.indevice[t] = "Master"
            end

            
          end

          indevice_value = value
          xins_device.device_name_observable:add_notifier(change_from_renoise)
        end
      },
      vb:valuebox{
        width = 55,
        min = 0,
        max = 16,
        value = 0,
        tooltip = "Instrument "..string.format("%02X", range + (start_instrument - 2)),
        visible = midi_in_gui,
        id="channelin"..tostring(range),
        tostring = function(value) 

          if value == 0 then
            return "Any"
          else
            return tostring(value)
          end

        end,
          
        tonumber = function(str) 
          return tonumber(str)
        end,
        notifier = function(value)

          if changed_from_renoise then
            changed_from_renoise = nil
            return
          end

          local t = range+start_instrument-1
          local xins_device = renoise.song().instruments[t].midi_input_properties

          if (xins_device.channel_observable:has_notifier(change_from_renoise)) then
            xins_device.channel_observable:remove_notifier(change_from_renoise)
          end

          if solo_instrument == nil then
            renoise.song().instruments[t].midi_input_properties.channel = value        
            selector.instrument.inchannel[t] = value
          end
          xins_device.channel_observable:add_notifier(change_from_renoise)
        end
        
      },
      vb:popup{
        width = 150,
        value = outdevice_value,
        tooltip = "Instrument "..string.format("%02X", range + (start_instrument - 2)),
        items = outdevices,
        visible = midi_out_gui,
        id = "deviceout"..tostring(range),
        notifier = function(value)

          if changed_from_renoise then
            changed_from_renoise = nil
            return
          end

          local t = range+start_instrument-1
          local xins_device = renoise.song().instruments[t].midi_output_properties

          if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
            xins_device.device_name_observable:remove_notifier(change_from_renoise)
          end

          if value > 1 then
            renoise.song().instruments[t].midi_output_properties.device_name = outdevices[value]
            selector.instrument.outdevice[t] = outdevices[value]
          else
            renoise.song().instruments[t].midi_output_properties.device_name = ""
            selector.instrument.outdevice[t] = "None"
          end

          outdevice_value = value
          xins_device.device_name_observable:add_notifier(change_from_renoise)
        end
      },
      vb:valuebox{
        width = 55,
        min = 1,
        max = 16,
        value = 1,
        visible = midi_out_gui,
        tooltip = "Instrument "..string.format("%02X", range + (start_instrument - 2)),
        id="channelout"..tostring(range),
        tostring = function(value) 
          return tostring(value)
        end,
        tonumber = function(str) 
          return tonumber(str)
        end,
        notifier = function(value)

          if changed_from_renoise then
            changed_from_renoise = nil
            return
          end
          
          local t = range+start_instrument-1
          renoise.song().instruments[t].midi_output_properties.channel = value        
        end
      },
    }

    
    dialog_content:add_child(instrument_row)
    if not renoise.tool():has_midi_mapping("Midi Console:Chain"..tostring(range)) then
      renoise.tool():add_midi_mapping{
        name = "Midi Console:Chain"..tostring(range),
        invoke = function(message)
          if message:is_switch() then
            if range <= created_range then
              vb.views['chain'..tostring(range)].value = not vb.views['chain'..tostring(range)].value
            end
          end
        end
      }
    end
    if not renoise.tool():has_midi_mapping("Midi Console:Solo"..tostring(range)) then
      renoise.tool():add_midi_mapping{
        name = "Midi Console:Solo"..tostring(range),
        invoke = function(message)
          if message:is_switch() then
            if range <= created_range then
              vb.views['solo'..tostring(range)].value = not vb.views['solo'..tostring(range)].value
            end
          end
        end
      }
    end
  end
    local button_row = vb:row{
      vb:space{width = 1},
      vb:button {
        text="clr",
        tooltip = "Clear solo choice",
        notifier = function(value)
          solo_instrument = nil
          update_instrument_list()
        end
      },
      vb:space{width = 5},
      vb:button {
        text="clr",
        tooltip = "Clear chain",
        notifier = function(value)
          for t = 1, #instrument do
            selector.instrument.chain[t] = false
          end

          update_instrument_list()   
        end
      },
      vb:space{width = 50},
      vb:text{
        align = "right",
        text="visible instruments",
      },
      vb:valuebox{
        width = 55,
        min = 5,
        max = 50,
        value = visible_range,
        tooltip = "How many instruments to show (min. 5, max 50)\n"..
                  "Warning:Midi selections are overwritten by instrument property values!",
        id="visible_range",
        bind=preferences.visible_range,
        tostring = function(value) 
          return tostring(value)
        end,
        tonumber = function(str) 
          return tonumber(str)
        end,
        notifier = function(value)
          visible_range = value
          start_instrument = 1
          update_range()
          update_instrument_list()
          preferences:save_as("preferences.xml")

--          toggle_midi_in()
--          toggle_midi_out() 
        end
      },
      vb:space{width = 132},
      vb:button {
        text="Reset track-assignments",
        tooltip = "Reset all assigned tracks to 'current'",
        notifier = function(value)
          for t = 1, #instrument do
            selector.instrument.track[t] = 0 
            instrument[t].midi_input_properties.assigned_track = 0
          end

          update_instrument_list()   
        end
      },
      vb:space{width = 15, id='inwidt1', visible = midi_in_gui},
      vb:button {
        text="Reset device-assignments",
        tooltip = "Reset all assigned devices to 'Master'",
        id='rst_devin',
        visible = midi_in_gui,
        notifier = function(value) 
          local chains_exist = false
          for t = 1, #instrument do
            selector.instrument.indevice[t] = "Master"
            for x = 1, #selector.instrument.chain do
              if selector.instrument.chain[x] == true then
                chains_exist = true
                break
              end
            end
            if chains_exist == false then
              instrument[t].midi_input_properties.device_name = "Master"
            else
              if t >= start_instrument and t <= start_instrument+created_range-1 then
                changed_from_renoise = true
                vb.views['devicein'..tostring(t)].value = 1
              end
            end
          end
        end
      },
      vb:space{width = 6, id='inwidt2', visible = midi_in_gui},
      vb:button {
        text="Rst.chan",
        tooltip = "Reset all assigned channels to 'Any'",
        id='rst_chanin',
        visible = midi_in_gui,
        notifier = function(value)
          local chains_exist = false
          for t = 1, #instrument do
            selector.instrument.inchannel[t] = 0
            for x = 1, #selector.instrument.chain do
              if selector.instrument.chain[x] == true then
                chains_exist = true
                break
              end
            end
            if chains_exist == false then
              instrument[t].midi_input_properties.channel = 0
            else
              if t >= start_instrument and t <= start_instrument+created_range-1 then
                changed_from_renoise = true
                vb.views['channelin'..tostring(t)].value = 0
              end
            end
          end

--          update_instrument_list()   
        end
      },
      vb:space{width = 6, id='outwidt1', visible = midi_out_gui},
      vb:button {
        text="Reset device-assignments",
        tooltip = "Reset all assigned devices to 'None'",
        id='rst_devout',
        visible = midi_out_gui,
        notifier = function(value)
          for t = 1, #instrument do
            selector.instrument.outdevice[t] = "None"
            instrument[t].midi_output_properties.device_name = ""
          end

--          update_instrument_list()   
        end
      },
      vb:space{width = 6, id='outwidt2', visible = midi_out_gui},
      vb:button {
        text="Rst.chan",
        tooltip = "Reset all assigned channels to '1'",
        id='rst_chanout',
        visible = midi_out_gui,
        notifier = function(value)
          for t = 1, #instrument do
            selector.instrument.outchannel[t] = 1
            instrument[t].midi_output_properties.channel = 1
          end
          update_instrument_list()   
        end
      },
    }  
    dialog_content:add_child(button_row)
  selector_dialog = renoise.app():show_custom_dialog(tool_name, dialog_content, key_handler)
end

function key_handler(dialog,key)
--  print(key.name)
  
  if key.name == "down" then

    if start_instrument + created_range < #renoise.song().instruments+1 then
      start_instrument = start_instrument + 1
    -- The scrolled variable is to prevent feedback loops
      scrolled = 1
      update_instrument_list()
      scrolled = nil
    end
    
  end
  
  if key.name == "up" then

    if start_instrument > 1 then
      start_instrument = start_instrument - 1
      scrolled = 1
      update_instrument_list()
      scrolled = nil
    end

  end
  
  if key.name == "next" then

    if start_instrument + created_range +created_range < #renoise.song().instruments+1 then
      start_instrument = start_instrument + created_range
    else

      if #renoise.song().instruments > created_range then

        start_instrument = #renoise.song().instruments - created_range+1
      end
    
    end
    -- The scrolled variable is to prevent feedback loops
    scrolled = 1
    update_instrument_list()
    scrolled = nil
  end
  
  if key.name == "prior" then

    if start_instrument-visible_range >= 1 then
      start_instrument = start_instrument - created_range
    else
      start_instrument = 1
    end

    update_instrument_list()
  end
  
  if key.name == "home" then
    start_instrument = 1
    scrolled = 1
    update_instrument_list()
    scrolled = nil
  end
  
  if key.name == "end" then

    if #renoise.song().instruments > created_range then
      start_instrument = #renoise.song().instruments - created_range +1
    end
    -- The scrolled variable is to prevent feedback loops
    scrolled = 1
    update_instrument_list()
    scrolled = nil
  end
  
  if key.name == "f1" then
    midi_in_gui = not midi_in_gui

    if midi_in_gui == true then
      vb.views['button_midi_in'].color = {0xff, 0xb6, 0x00}
    else
      vb.views['button_midi_in'].color = {0x2d, 0x11, 0xff}
    end  

    toggle_midi_in()
    return
  end
  
  if key.name == "f2" then
    midi_out_gui = not midi_out_gui

    if midi_out_gui == true then
      vb.views['button_midi_out'].color = {0xff, 0xb6, 0x00}
    else
      vb.views['button_midi_out'].color = {0x2d, 0x11, 0xff}
    end  

    toggle_midi_out()
    return
  end
  
  return key
end


function toggle_midi_in()
  local instrument = renoise.song().instruments    
  local range_bounds = visible_range

  if range_bounds > #renoise.song().instruments then
     range_bounds = #renoise.song().instruments
  end

  if range_bounds > created_range then
   range_bounds = created_range
  end
  vb.views["column_dev_in"].visible = midi_in_gui
  vb.views["column_chan_in"].visible = midi_in_gui
  vb.views["space_dev_in"].visible = midi_in_gui
  vb.views["space_chan_in"].visible = midi_in_gui

  vb.views["inwidt1"].visible = midi_in_gui
  vb.views["rst_devin"].visible = midi_in_gui
  vb.views["inwidt2"].visible = midi_in_gui
  vb.views["rst_chanin"].visible = midi_in_gui
  
  if midi_in_gui == false and midi_out_gui == true then
    vb.views["space_dev_in"].visible = true
    vb.views["inwidt1"].visible = true
  end

  
  for range = 1,range_bounds do
     local t = range+start_instrument-1
     local midi_in_props = instrument[t].midi_input_properties
     vb.views["devicein"..tostring(range)].visible = midi_in_gui
     vb.views["channelin"..tostring(range)].visible = midi_in_gui
  end

  
end

function toggle_midi_out()
  local instrument = renoise.song().instruments    
  local range_bounds = visible_range
  
  if range_bounds > #renoise.song().instruments then
     range_bounds = #renoise.song().instruments
  end

  if range_bounds > created_range then
   range_bounds = created_range
  end

  vb.views["column_dev_out"].visible = midi_out_gui
  vb.views["column_chan_out"].visible = midi_out_gui
  vb.views["space_chan_out"].visible = midi_out_gui

  vb.views["outwidt1"].visible = midi_out_gui
  vb.views["rst_devout"].visible = midi_out_gui
  vb.views["outwidt2"].visible = midi_out_gui
  vb.views["rst_chanout"].visible = midi_out_gui
  
  if midi_in_gui == false and midi_out_gui == true then
    vb.views["space_dev_in"].visible = true
    vb.views["inwidt1"].visible = true
  end
  
  for range = 1,range_bounds do
     local t = range+start_instrument-1
     local midi_out_props = instrument[t].midi_output_properties
     vb.views["deviceout"..tostring(range)].visible = midi_out_gui
     vb.views["channelout"..tostring(range)].visible = midi_out_gui  
  end

end

function update_track(ins_num)
  local t = ins_num + start_instrument - 1
  local insnum = t - 1
  local track_index = selector.instrument.track[t] or 0

  local popup_index = track_index + 1  -- GUI uses 1-based index

  if popup_index < 1 then popup_index = 1 end
  if popup_index > #tracks then popup_index = #tracks end

  vb.views["track"..tostring(ins_num)].items = tracks
  safe_set("track"..tostring(ins_num), popup_index)
  vb.views["track"..tostring(ins_num)].tooltip = "Instrument "..string.format("%02X", insnum)
end

function update_device_in(ins_num)
  local t = ins_num+start_instrument-1
  local insnum = t - 1  --Instrument number representation in the Renoise Instrument list
  local midi_in_props = instrument[t].midi_input_properties
  
  vb.views["devicein"..tostring(ins_num)].tooltip = "Instrument "..string.format("%02X", insnum)

  if midi_in_props.device_name ~= "" then

    for _ = 1, #indevices do

      if indevices[_] == midi_in_props.device_name then
        safe_set("devicein"..tostring(ins_num), _)
        indevice_value = _
        break
      end

    end

  else
    safe_set("devicein"..tostring(ins_num), 1)
    indevice_value = 1
  end

end

function update_channel_in(ins_num)
  local t = ins_num+start_instrument-1
  local insnum = t - 1  --Instrument number representation in the Renoise Instrument list
  
  safe_set("channelin"..tostring(ins_num), selector.instrument.inchannel[t])    
  vb.views["channelin"..tostring(ins_num)].tooltip = "Instrument "..string.format("%02X", insnum)
end

function update_device_out(ins_num)
  local t = ins_num+start_instrument-1
  local insnum = t - 1  --Instrument number representation in the Renoise Instrument list
  local midi_out_props = instrument[t].midi_output_properties
  
  vb.views["deviceout"..tostring(ins_num)].tooltip = "Instrument "..string.format("%02X", insnum)
  if midi_out_props.device_name ~= "" then

    for _ = 1, #outdevices do
      if outdevices[_] == midi_out_props.device_name then
        vb.views["deviceout"..tostring(ins_num)].value = _
        outdevice_value = _
        break
      end

    end

  else
    vb.views["deviceout"..tostring(ins_num)].value = 1
    outdevice_value = 1
  end

end

function update_channel_out(ins_num)
  local t = ins_num+start_instrument-1
  local insnum = t - 1  --Instrument number representation in the Renoise Instrument list
  
  vb.views["channelout"..tostring(ins_num)].value = selector.instrument.outchannel[t]    
  vb.views["channelout"..tostring(ins_num)].tooltip = "Instrument "..string.format("%02X", insnum)
end

function update_instrument_name (ins_num)
  
  local t = ins_num+start_instrument-1
  --This is quite an ackward trick to update the instrument name fields:
  vb.views["ins_name"..tostring(ins_num)].value = 0
  --^^We have to change the value in the value-field to another value first 
  vb.views["ins_name"..tostring(ins_num)].value = t    
  --else it won't update when it receives a value it alreay has.
  
  vb.views["ins_name"..tostring(ins_num)].max = #renoise.song().instruments        
end

function update_instrument_number(ins_num)
  local insnum = ins_num+start_instrument-2  --Instrument number representation in the Renoise Instrument list
  vb.views["ins_number"..tostring(ins_num)].text = string.format("%02X", insnum)
end


function update_range()
  if #instrument >= visible_range then
      created_range = visible_range
  else
    created_range = #instrument
  end
  
  if selector_dialog.visible then
    selector_dialog:close()
    show_dialog(tool_name)
  end
  
  instrument = renoise.song().instruments 
end

function update_instrument_list()
  if #instrument ~= instrument_amount then

    if #instrument >= visible_range then
      created_range = visible_range
    else
      created_range = #instrument
    end
    if selector_dialog.visible then
      selector_dialog:close()
    end
    show_dialog(tool_name)
    instrument = renoise.song().instruments 
    return 

  end

   local range_bounds = visible_range

  if range_bounds > #renoise.song().instruments then
     range_bounds = #renoise.song().instruments
  end

  if range_bounds > created_range then
   range_bounds = created_range
  end
  for range = 1,range_bounds do
     local t = range+start_instrument-1
     local insnum = t-1
     local cval = "solo"..tostring(range)

     if solo_instrument ~= nil then

       if solo_instrument == t then
         safe_set(cval, true)     
       else
         local temp_solo = solo_instrument
         safe_set(cval, false) 
         solo_instrument = temp_solo
       end

     else
       safe_set(cval, false) 
     end

     safe_set("chain"..tostring(range), selector.instrument.chain[t])
     
     
     update_instrument_number(range)
     update_instrument_name (range)
     update_track (range)
     if master.change == false then
       update_device_in(range)
       update_channel_in(range)
     end
     update_device_out(range)
     update_channel_out(range)
        
   end

end
