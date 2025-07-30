
-----------------------
--Keybinding
-----------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:Device Sergeant",
  invoke = function()main_toggle()end
  
}
-----------------------
--Tool menu entry
-----------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Device Sergeant",
  invoke = function()main_start()end
  
}

-----------------------
--Device menu entry
-----------------------
renoise.tool():add_menu_entry {
  name = "DSP Device:Device Sergeant",
  invoke = function()main_start()end
  
}

-----------------------
--Mixer menu entry
-----------------------
renoise.tool():add_menu_entry {
  name = "Mixer:Device Sergeant",
  invoke = function() main_start() end
}


--viewbuilder
local my_dialog = nil
local renaming_dialog = nil
local vb = renoise.ViewBuilder()

--globals
g_selected_device = nil
timer_running = false
popup_called = false

--e.g. For changing vb.views["sample present colour 2"].color when states change
COLOR_GREY = {40,40,40}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_RED_MILD ={0x70,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}--COLOR_GREEN = {0x10,0xFF,0x10}

--toggle the tool open and closed (keyboard shortcut start-up)
-------------------------------------------------------------
function main_toggle()
----------------------
 --close dialog if it is open
  if (my_dialog and my_dialog.visible) then 
    my_dialog:close()
  else --run main
    main()
  end
end

--always open/ restart tool (menu entry start-up)
-------------------------------------------------
function main_start()
---------------------
  if (my_dialog and my_dialog.visible) then 
    my_dialog:close() 
  end
  --run main
  main()
end
----------------------------------------------------------



--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
function status(message)
  renoise.app():show_status("Device Sergeant Tool: ("..message..")")
end


-------------------------------------------
function get_short_name_from_display_name(display_name)
-------------------------------------------
  --reverse the name
  display_name = string.reverse(display_name)
  --find the first colon
  local first_colon = string.find(display_name,":")
  --return if no colon found
  if first_colon == nil then
    return string.reverse(display_name)
  end
  
  --get substring up to colon (minus two chars)
  display_name = string.sub(display_name,1,first_colon-2)
  --reverse name again
  display_name = string.reverse(display_name)
  return display_name

end

--counts all devices with same display name
---------------------------
function get_device_count()
---------------------------
  local song = renoise.song()
  local d_counter = 0
  local table = {}
  table.current = ""
  --count number of devices that will be effected and update text to show
  for track = 1,#song.tracks do
    for dev = 1,#song:track(track).devices do
      if song:track(track):device(dev).display_name == g_selected_device.display_name then
        d_counter = d_counter + 1
        if rawequal(song:track(track):device(dev),song.selected_track_device) == true then
          table.current = tostring(d_counter) 
        end
      end
    end
  end
  table.total = tostring(d_counter)
  return table
end



-----------------
function timer()
-----------------
  --set global timer running
  timer_running = true
  local song = renoise.song()
  
  --make sure a device is selected
  if song.selected_track_device == nil then
    song.selected_track_device_index = 1
  end
  
  --1) check if selected device has changed --rawequal function compares two objects
  if rawequal(g_selected_device,song.selected_track_device) ~= true then --update gui
    --update global
    g_selected_device = song.selected_track_device
    --change textfield readout
    vb.views["device name textfield"].value = get_short_name_from_display_name(g_selected_device.display_name)
   
    --update popup-----------------------
    local parameter_names = {}
    --loop and get parmeter names
    for i = 1, #g_selected_device.parameters do
      table.insert(parameter_names,g_selected_device:parameter(i).name)
    end
    --update popup
    vb.views["param popup"].items = parameter_names
    vb.views["param popup"].value = 1
    local sel_parameter = vb.views["param popup"].value
    --set range of slider
    vb.views["slider"].max = g_selected_device:parameter(sel_parameter).value_max
    vb.views["slider"].min = g_selected_device:parameter(sel_parameter).value_min
    
    --if test TO DEAL WITH BUG IN API?  meta devices returning routing values of -1 if routed to the current track--(been reported, may be fixed by API 6, post renoise 3.1)
    --------------------------------------
    if (g_selected_device:parameter(sel_parameter).value < g_selected_device:parameter(sel_parameter).value_min) then
      vb.views["slider"].value = g_selected_device:parameter(sel_parameter).value_min
    else 
      vb.views["slider"].value = g_selected_device:parameter(sel_parameter).value
    end
    --------------------------------------
    
    --reset All On/Off color buttons in case any left orange
    vb.views["All On"].color = COLOR_GREY
    vb.views["All Off"].color = COLOR_GREY
    
  
    vb.views["device count"].text = "= "..get_device_count().current.."/"..get_device_count().total.." "
   
   

    
  end --end of 1)check if selected device has changed
  
  --CASE: Mixer Device Selected: disable toggle buttons and textfield
  -------------------------------------------------------------------
  if song.selected_track_device_index == 1 then
    vb.views["device name textfield"].active = false
    vb.views["All On"].visible = false
    vb.views["All Off"].visible = false
    vb.views["Toggle All"].visible = false    
    vb.views["+ To Vacant Tracks"].visible = false
    vb.views["Delete All"].visible = false
    vb.views["Rename Current Device Only"].visible = false
    vb.views["Add / Remove text"].visible = false
    vb.views["Rename Text"].visible = false
    vb.views["Map Hydra"].visible = false
    vb.views["Sync / Map"].text = "     Sync Presets"
  else
    vb.views["device name textfield"].active = true
    vb.views["All On"].visible = true
    vb.views["All Off"].visible = true
    vb.views["Toggle All"].visible = true
    vb.views["+ To Vacant Tracks"].visible = true
    vb.views["Delete All"].visible = true
    vb.views["Rename Current Device Only"].visible = true
    vb.views["Add / Remove text"].visible = true
    vb.views["Rename Text"].visible = true
    vb.views["Map Hydra"].visible = true
    vb.views["Sync / Map"].text = "     Sync Presets / Map a Hydra:  "
  end
  
  
  --remove timer if dialog is closed
  ----------------------------------
  if (my_dialog ~= nil) and
     (my_dialog.visible == false) then --gui has been closed
    --reset to nil 
    my_dialog = nil
    --remove this timer function 
    if renoise.tool():has_timer(timer) then
      renoise.tool():remove_timer(timer)
    end
    --check and remove renaming dialog if still open
    if (renaming_dialog ~= nil) and
     (renaming_dialog.visible == true) then
       renaming_dialog:close()
       renaming_dialog = nil
     end
  end
  -----------------------------------
  --update slider readout
  local sel_parameter = vb.views["param popup"].value
  vb.views["slider readout"].text = "  "..g_selected_device:parameter(sel_parameter).value_string
  
  --set global timer running
  timer_running = false
end





------------------------------------------------------------------------------------------
--function to build the GUI content
--returns renoise ViewBuilder for dialog_content for  --renoise.app():show_custom_dialog()
------------------------------------------------------------------------------------------
local function build_gui()
  vb = renoise.ViewBuilder()
  local song = renoise.song()
  
  -----------------------------------
  local function get_current_device()
  -----------------------------------
    local song = renoise.song()
    --make sure device is selected
    if song.selected_track_device == nil then
      song.selected_track_device_index = 1
    end
    return song.selected_track_device 
  end
  --get device  
  local device = get_current_device()
  --updated global
  g_selected_device = device
  
  
  --------------------------------------------
  local function get_selected_dsp_parameters()
  -------------------------------------------- 
    local parameter_names = {}
    local device = get_current_device()
    --loop and get parmeter names
    for i = 1, #device.parameters do
      table.insert(parameter_names,device:parameter(i).name)
    end
    return parameter_names
  end
  --------------------------------------------
  
  local device_active
  if song.selected_track_device.is_active == true then
    device_active = true
  else
    device_active = false
  end
  
  local dialog_content = 
 
  vb:vertical_aligner {
    margin = 4,
    
    --device count readout
    vb:horizontal_aligner{
     vb:text{
      text = "       Selected Device/s:"
     },
     
     vb:text{
      text = "= "..get_device_count().current.."/"..get_device_count().total.." ",
      id = "device count", 
     },
    },
    --select next prev device buttons
    vb:horizontal_aligner{
    margin = 4,
     
     vb:button{
      text = "<",
      id = "sel prev dev",
      notifier = function()
      
                  --focus renoise so selected device is more visible in mixer
                  renoise.app().window.lock_keyboard_focus = false
                  renoise.app().window.lock_keyboard_focus = true
                  
                  local song = renoise.song()
                  local name = song.selected_track_device.display_name
                  local cur_trk = song.selected_track_index
                  local cur_dev_idx = song.selected_track_device_index
                  local cur_dev = song.selected_track_device
                  
                  --loop tracks
                  for track = #song.tracks,1,-1 do
                    local trk = song:track(track)
                    if track == cur_trk then
                       --[1] Current track loop devices
                      for dev = (cur_dev_idx-1),1,-1 do
                        if trk:device(dev).display_name == cur_dev.display_name then
                          --select new device
                          song.selected_track_device_index = dev
                          return
                        end
                      end
                    else
                      --[1] Prev track/s loop devices
                      if track < cur_trk then
                        --loop devices from last device
                        for dev = #trk.devices,1,-1 do
                          if trk:device(dev).display_name == cur_dev.display_name then
                            --select track and device
                            song.selected_track_index = track
                            song.selected_track_device_index = dev
                            return
                          end
                        end
                      end
                    end
                  end
               end 
     },
     
     vb:button{
      text = ">",
      id = "sel next dev",
      notifier = function()
  
              --focus renoise so selected device is more visible in mixer
              renoise.app().window.lock_keyboard_focus = false
              renoise.app().window.lock_keyboard_focus = true
              
              local song = renoise.song()
              local name = song.selected_track_device.display_name
              local cur_trk = song.selected_track_index
              local cur_dev_idx = song.selected_track_device_index
              local cur_dev = song.selected_track_device
              
              --loop tracks
              for track = 1,#song.tracks do
                local trk = song:track(track)
                
                if track == cur_trk then
                   --[1] Current track loop devices
                  for dev = (cur_dev_idx+1),#trk.devices do
                    if trk:device(dev).display_name == cur_dev.display_name then
                      --select new device
                      song.selected_track_device_index = dev
                      return
                    end
                  end
                else
                  --[1] Prev track/s loop devices
                  if track > cur_trk then
                    --loop devices from last device
                    for dev = 1,#trk.devices do
                      if trk:device(dev).display_name == cur_dev.display_name then
                        --select new track and new device
                        song.selected_track_index = track
                        song.selected_track_device_index = dev
                        return
                      end
                    end
                  end
                end
              end
           end  
     },
     
     },
   
  
  
  
    vb:horizontal_aligner{
      margin = 4,
      mode = "distribute",
        --device name
        vb:textfield{
          text = get_short_name_from_display_name(g_selected_device.display_name),
          height = 25,
          width = 160,
          id = "device name textfield",
          notifier = function(text)
                       --bypass if timer running
                       if timer_running == true then
                         return
                       end
                         
                       local song = renoise.song()
                       local target_name = g_selected_device.display_name
                       --loop tracks and change all devices with the same display name to what the user
                       --eners in the textfield
                       for track = 1,#song.tracks do
                         for dev = 1,#song:track(track).devices do
                           if song:track(track):device(dev).display_name == target_name then
                             song:track(track):device(dev).display_name = text
                           end
                         end
                       end
                       
                     end
        },
   
   
     },
     
     vb:horizontal_aligner{
       margin = 4,
       vb:button{
        text = "Toggle",
        id = "Toggle All",
        color = COLOR_GREY,
        width = 52,
        height = 20,
        notifier = function()
                    local song = renoise.song() 
                    --return if on mixer device
                    if song.selected_device_index < 2 then
                      status("Can`t Toggle Tracks` Mixer Device")
                      return
                    end
                    
                    --loop tracks
                     for track = 1,#song.tracks do
                       for dev = 2,#song:track(track).devices do
                         if g_selected_device.display_name == song:track(track):device(dev).display_name then
                           song:track(track):device(dev).is_active = (not song:track(track):device(dev).is_active)
                         end
                       end
                     end
                    -- vb.views["Toggle All"].color = COLOR_ORANGE
                     vb.views["All On"].color = COLOR_GREY
                     vb.views["All Off"].color = COLOR_GREY
                   end
        },
        
         vb:button{
          id = "All On",
          text = "All On",
          color = COLOR_GREY,
          width = 52,
          height = 20,
          notifier = function(value)
                       local song = renoise.song()
                       --return if on mixer device
                       if song.selected_device_index < 2 then
                         status("Can`t Toggle Tracks` Mixer Device")
                         return
                       end
                       --loop tracks
                       for track = 1,#song.tracks do
                         for dev = 2,#song:track(track).devices do
                           if g_selected_device.display_name == song:track(track):device(dev).display_name then
                             song:track(track):device(dev).is_active = true
                           end
                         end
                       end
                      -- vb.views["Toggle All"].color = COLOR_GREY
                       vb.views["All On"].color = COLOR_ORANGE 
                       vb.views["All Off"].color = COLOR_GREY
                     end,
        }, 
        
         vb:button{
          id = "All Off",
          text = "All Off",
          color = COLOR_GREY,
          width = 52,
          height = 20,
          notifier = function(value)
                       local song = renoise.song()
                        --return if on mixer device
                       if song.selected_device_index < 2 then
                         status("Can`t Toggle Tracks` Mixer Device")
                         return
                       end
                       --loop tracks
                       for track = 1,#song.tracks do
                         for dev = 2,#song:track(track).devices do
                           if g_selected_device.display_name == song:track(track):device(dev).display_name then
                             song:track(track):device(dev).is_active = false
                           end
                         end
                       end
                      -- vb.views["Toggle All"].color = COLOR_GREY
                       vb.views["All On"].color = COLOR_GREY
                       vb.views["All Off"].color = COLOR_ORANGE 
                     end,
        }, 
       }, 
     
     
      vb:text{
         text = "           Parameter Macro:"
       },
     
     vb:column{
       style = "group",
       
       vb:horizontal_aligner{
        margin = 4,
        
        --parameter names
         vb:popup{
           items = get_selected_dsp_parameters(),
           width = 160,
           id = "param popup",
           notifier = function()
                        --bypass if timer running
                        if timer_running == true then
                          return
                        end
                        
                        popup_called = true
                        
                        local song = renoise.song()
                        local master_device = get_current_device()
                        local sel_parameter = vb.views["param popup"].value
                        --set range of slider
                        vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                        vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                        --if test TO DEAL WITH BUG IN API?  meta devices returning routing values of -1 if routed to the current track--(been reported, may be fixed by API 6, post renoise 3.1)
                        --------------------------------------
                        if (master_device:parameter(sel_parameter).value < master_device:parameter(sel_parameter).value_min) then
                          vb.views["slider"].value = master_device:parameter(sel_parameter).value_min
                        else 
                          vb.views["slider"].value = master_device:parameter(sel_parameter).value
                        end
                        --------------------------------------
                        
                        popup_called = false  
                      
                      end
         },
       },  
  
      vb:horizontal_aligner{
        margin = 4, 
       vb:minislider{
         width = 160,
         height = 20,
         id = "slider",
         min = g_selected_device:parameter(1).value_min,
         max = g_selected_device:parameter(1).value_max,
         value = g_selected_device:parameter(1).value,
         notifier = function(value)
                      --bypass if timer running
                      if timer_running == true then
                        return
                      end
                      --bypass if popup called
                      if popup_called == true then
                        return
                      end
                      
                      --slider changes value of all similar parameters (DSP with same name) in mixer
                      local song = renoise.song()
                      local master_device = get_current_device()
                      local sel_parameter = vb.views["param popup"].value
                      local sel_parameter_object = master_device:parameter(sel_parameter)
                      --set range of slider
                      vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                      vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                      
                      if vb.views["slider"].value > vb.views["slider"].max or
                         vb.views["slider"].value < vb.views["slider"].min then
                         return
                      end
                      
                      --loop tracks
                      for track = 1,#song.tracks do
                      -- (1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value 
                        --loop devices in track
                        for device = 1,#song:track(track).devices do
                          --get traget device
                          local target_device = song:track(track):device(device)
                          --if target matches master
                          if target_device.display_name == master_device.display_name then
                          -- print((1/sel_parameter_object.value_max) * sel_parameter_object.value)
                           target_device:parameter(sel_parameter).value = vb.views["slider"].value
                          end
                        end
                      end
                    end
       
            },--mini slider
      },--h-aligner
      
      vb:text{
       id = "slider readout"
      },--text
      
      vb:horizontal_aligner{
        margin = 4,
        vb:button{
          id = "nudge down",
          text = "1% v",
          notifier = function()
                   
                      --bypass if timer running
                      if timer_running == true then
                        return
                      end
                      --bypass if popup called
                      if popup_called == true then
                        return
                      end
                      
                      --slider changes value of all similar parameters (DSP with same name) in mixer
                      local song = renoise.song()
                      local master_device = get_current_device()
                      local sel_parameter = vb.views["param popup"].value
                      local sel_parameter_object = master_device:parameter(sel_parameter)
                      --set range of slider
                      vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                      vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                      
                      --loop tracks
                      for track = 1,#song.tracks do
                      -- (1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value 
                        --loop devices in track
                        for device = 1,#song:track(track).devices do
                          --get traget device
                          local target_device = song:track(track):device(device)
                          --if target matches master
                          if target_device.display_name == master_device.display_name then
                          --get 1% of total value
                          local one_percent = 0.01 * vb.views["slider"].max
                            --make sure we stay in bounds
                            if (target_device:parameter(sel_parameter).value - one_percent) >= vb.views["slider"].min then
                              target_device:parameter(sel_parameter).value = target_device:parameter(sel_parameter).value - one_percent
                            else
                              target_device:parameter(sel_parameter).value = vb.views["slider"].min
                            end
                          end
                        end
                      end
                    end
          
        
        },
     
        vb:button{
          id = "nudge up",
          text = "1% ^",
                    notifier = function()
                   
                      --bypass if timer running
                      if timer_running == true then
                        return
                      end
                      --bypass if popup called
                      if popup_called == true then
                        return
                      end
                      
                      --slider changes value of all similar parameters (DSP with same name) in mixer
                      local song = renoise.song()
                      local master_device = get_current_device()
                      local sel_parameter = vb.views["param popup"].value
                      local sel_parameter_object = master_device:parameter(sel_parameter)
                      --set range of slider
                      vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                      vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                      
                      --loop tracks
                      for track = 1,#song.tracks do
                      -- (1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value 
                        --loop devices in track
                        for device = 1,#song:track(track).devices do
                          --get traget device
                          local target_device = song:track(track):device(device)
                          --if target matches master
                          if target_device.display_name == master_device.display_name then
                          --get 1% of total value
                          local one_percent = 0.01 * vb.views["slider"].max
                            --make sure we stay in bounds
                            if (target_device:parameter(sel_parameter).value + one_percent) <= vb.views["slider"].max then
                              target_device:parameter(sel_parameter).value = target_device:parameter(sel_parameter).value + one_percent
                            else
                              target_device:parameter(sel_parameter).value = vb.views["slider"].max
                            end
                          end
                        end
                      end
                    end
          
        },
        
        vb:button{
          id = "5 down",
          text = "5% v",
          notifier = function()
                   
                      --bypass if timer running
                      if timer_running == true then
                        return
                      end
                      --bypass if popup called
                      if popup_called == true then
                        return
                      end
                      
                      --slider changes value of all similar parameters (DSP with same name) in mixer
                      local song = renoise.song()
                      local master_device = get_current_device()
                      local sel_parameter = vb.views["param popup"].value
                      local sel_parameter_object = master_device:parameter(sel_parameter)
                      --set range of slider
                      vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                      vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                      
                      --loop tracks
                      for track = 1,#song.tracks do
                      -- (1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value 
                        --loop devices in track
                        for device = 1,#song:track(track).devices do
                          --get traget device
                          local target_device = song:track(track):device(device)
                          --if target matches master
                          if target_device.display_name == master_device.display_name then
                          --get 1% of total value
                          local five_percent = 0.05 * vb.views["slider"].max
                            --make sure we stay in bounds
                            if (target_device:parameter(sel_parameter).value - five_percent) >= vb.views["slider"].min then
                              target_device:parameter(sel_parameter).value = target_device:parameter(sel_parameter).value - five_percent
                            else
                              target_device:parameter(sel_parameter).value = vb.views["slider"].min
                            end
                          end
                        end
                      end
                    end
          
        
        },
     
        vb:button{
          id = "5 up",
          text = "5% ^",
                    notifier = function()
                   
                      --bypass if timer running
                      if timer_running == true then
                        return
                      end
                      --bypass if popup called
                      if popup_called == true then
                        return
                      end
                      
                      --slider changes value of all similar parameters (DSP with same name) in mixer
                      local song = renoise.song()
                      local master_device = get_current_device()
                      local sel_parameter = vb.views["param popup"].value
                      local sel_parameter_object = master_device:parameter(sel_parameter)
                      --set range of slider
                      vb.views["slider"].max = master_device:parameter(sel_parameter).value_max
                      vb.views["slider"].min = master_device:parameter(sel_parameter).value_min
                      
                      --loop tracks
                      for track = 1,#song.tracks do
                      -- (1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value 
                        --loop devices in track
                        for device = 1,#song:track(track).devices do
                          --get traget device
                          local target_device = song:track(track):device(device)
                          --if target matches master
                          if target_device.display_name == master_device.display_name then
                          --get 1% of total value
                          local five_percent = 0.05 * vb.views["slider"].max
                            --make sure we stay in bounds
                            if (target_device:parameter(sel_parameter).value + five_percent) <= vb.views["slider"].max then
                              target_device:parameter(sel_parameter).value = target_device:parameter(sel_parameter).value + five_percent
                            else
                              target_device:parameter(sel_parameter).value = vb.views["slider"].max
                            end
                          end
                        end
                      end
                    end
          
        }
      
      
      
      
      
       },--nudge buttons horizontal aligner
 
     },
     
      vb:text{ --spacer
      text = ""
     
     },
      vb:text{
      text = "     Sync Presets / Map a Hydra:  ",
      id = "Sync / Map",
     
     },
     
       vb:horizontal_aligner{
        margin = 4,
        
      
           vb:button{
              id = "Sync All Devices",
              text = "Sync All Devices",
              notifier = function(value)
                           local song = renoise.song()
                           
                           --if on mixer device
                           if song.selected_track_device_index == 1 then
                             for track = 1,#song.tracks do
                               --only update similar track types(SEQ/SEND/GROUP/MASTER)
                               if song:track(track).type == song.selected_track.type then
                                 song:track(track):device(1).active_preset_data = g_selected_device.active_preset_data
                               end
                             end
                           end
                           
                           
                           --else loop devicess
                           for track = 1,#song.tracks do
                             local dev_found = false
                             for dev = 2,#song:track(track).devices do
                               if g_selected_device.display_name == song:track(track):device(dev).display_name then
                                 song:track(track):device(dev).active_preset_data = g_selected_device.active_preset_data
                               end
                             end
                           end
                         end,
  
            },
            
            vb:button{
              text = "Map Hydra",
              id = "Map Hydra",
              notifier = function()
              
                          if g_selected_device == nil then
                            status("No Device Selected")
                            return
                          end
                          
                          --get song
                          local song = renoise.song()
                          --add Hydra to current track at next pos
                          local hydra = song.selected_track:insert_device_at("Audio/Effects/Native/*Hydra", song.selected_track_device_index+1)
                         
                          --get tool globals
                          local sel_parameter_idx = vb.views["param popup"].value
                          local target_device_name = g_selected_device.display_name
                          local target_param = g_selected_device:parameter(sel_parameter_idx)
                          --make a table with target parameter slots for hydra
                          
                          local slider_max = g_selected_device:parameter(sel_parameter_idx).value_max
                          local slider_min = g_selected_device:parameter(sel_parameter_idx).value_min
                          --calculate the target value scaled between 0-1 (must be in this range for hydra slider)
                          local scaled_slider_val = g_selected_device:parameter(sel_parameter_idx).value * (1/(slider_max - slider_min))
                           --set hydra input slider to same as tool
                          hydra:parameter(1).value = scaled_slider_val
                          
                          -----------------------------
                          --NOTE: Hydra parameter names
                          -----------------------------
                          --"Out1 Track"
                          --"Out1 Effect"
                          --"Out1 Parameter"
                          --"Out1 Min"
                          --"Out1 Max"
                          --(repeat for Out2,Out3,...
                          
                          --for Effect targets (offset -1)
                          --none = -1
                          --mixer is 0
                          --first device = 1, second 2 etc.
                          

                          --counter
                           local hydra_slot = 1
                         
                           for track = 1,#song.tracks do
                             for dev = 1,#song:track(track).devices do
                               if g_selected_device.display_name == song:track(track):device(dev).display_name then
                                 
                                 for params = 1,#hydra.parameters do 
                                   if hydra:parameter(params).name == "Out"..hydra_slot.." Track" then
                                     hydra:parameter(params).value = track - 1 --offset due to hydra menu entries being offset
                                   end
                                   if hydra:parameter(params).name == "Out"..hydra_slot.." Effect" then
                                     hydra:parameter(params).value = dev - 1 --offset due to hydra menu entries being offset
                                   end
                                   if hydra:parameter(params).name == "Out"..hydra_slot.." Parameter" then
                                     hydra:parameter(params).value = sel_parameter_idx   --sel_parameter index
                                     
                                     if hydra_slot == 9 then
                                       status("Max Hydra Slots Reached")
                                       return --reached max slots
                                     else
                                       hydra_slot = hydra_slot + 1
                                     end
                                     break
                                   end
                                 end
                               end
                             end
                           end
                         end,
  
            },
      },
     
     vb:text{
      text = "       Add / Remove Devices:",
      id = "Add / Remove text",
     
     },
     
      --Add devices row
      vb:horizontal_aligner{  
       margin = 4,
         vb:button{
            id = "+ To Vacant Tracks",
            text = "+ To Vacant Tracks",
            notifier = function(value)
                         local song = renoise.song()
                          --return if on mixer device
                         if song.selected_device_index < 2 then
                           status("Can`t Duplicate Tracks` Mixer Device")
                           return
                         end
                         
                         --loop all tracks
                         for track = 1,#song.tracks do
                           --loop to check for sends so we can insert copied device before any sends in the target track
                           local num_devices_in_track = #song:track(track).devices
                           local insert_pos = num_devices_in_track  + 1
                           for dev = 2,num_devices_in_track do
                             if song:track(track):device(dev).device_path == "Audio/Effects/Native/#Send" then
                               --send device found so set insert_pos tothis position and break loop
                               insert_pos = dev
                               break
                             end
                           end
                           --look for a copy of the device already present in the track
                           local dev_found = false
                           for dev = 2,#song:track(track).devices do
                             if g_selected_device.display_name == song:track(track):device(dev).display_name then
                               dev_found = true
                               break
                             end
                           end
                           --add a copy of device if not found
                           if dev_found == false then
                             if song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER then --skip non sequencer tracks
                               local new_dev = song:track(track):insert_device_at(g_selected_device.device_path, insert_pos)--add at last position in track/ before first send
                               new_dev.active_preset_data = g_selected_device.active_preset_data
                               --if is necessary otherwise full name is given to new devices , including VST vendor (bug?) 
                               if new_dev.display_name ~= g_selected_device.display_name then
                                 new_dev.display_name = g_selected_device.display_name
                               end
                             end
                           end
                         end
                         --trigger timer to update
                         g_selected_device = nil
                       end,

          }, 
            vb:button{
            id = "Delete All",
            text = "Delete All",
            color = COLOR_RED_MILD,
            notifier = function(value)
                         local song = renoise.song()
                          --return if on mixer device
                         if song.selected_device_index < 2 then
                           status("Can`t Delete Tracks` Mixer Device")
                           return
                         end
                         --loop tracks
                         
                         for track = 1,#song.tracks do
                           local dev_found = false
                           for dev = 2,#song:track(track).devices do
                             if g_selected_device.display_name == song:track(track):device(dev).display_name then
                               song:track(track):delete_device_at(dev)
                               break
                             end
                           end
                         end
                         --trigger timer to update
                         g_selected_device = nil
                       end,

          }, 

     },--add devices row 
     
     vb:text{
      text = "      Rename Current Device:",
      id = "Rename Text",
     },
     
    vb:horizontal_aligner{
     margin = 4,

      vb:button{
        id = "Rename Current Device Only",
        text = "Rename Current Device Only",
        notifier = function()
                   
                     local song = renoise.song()
                     if song.selected_track_device_index == 1 then
                       status("Can`t Rename Mixer Device")
                       return
                     end
                     local vb_r = renoise.ViewBuilder()
                   
                     -- close if already open
                     if renaming_dialog and renaming_dialog.visible then
                       renaming_dialog:close()
                       renaming_dialog = nil
                       return
                     end 

                     --buid sub dialog
                     renaming_dialog =
                            
                        vb_r:horizontal_aligner{
                         vb_r:textfield{
                          width = 200,
                          edit_mode = true,
                          text = get_short_name_from_display_name(g_selected_device.display_name),
                          notifier = function(value)
                                       g_selected_device.display_name = value
                                       --close dialog
                                       if renaming_dialog and renaming_dialog.visible then
                                         renaming_dialog:close()
                                         renaming_dialog = nil
                                       end                                    
                                     end
                             },
                            }
                            
                           --build gui
                           renaming_dialog = renoise.app():show_custom_dialog("Rename Current Device", renaming_dialog) 
                           
                   end
      
      },
    },
  }
   
   return dialog_content

end

------------------------------------------------------------
--main
-------------------------------------------------------------
function main()
  
  --[[
  --Housekeeping
  ---------------------
  --check GUI is active and toggle off if so
  if my_dialog and (my_dialog.visible == true) then
    my_dialog:close()
    --my_dialog = nil
    return 
  end
  --]]
  local gui_name = "Device Sergeant"
    
  --build the GUI content
  -----------------------
  local dialog_content = build_gui()
  
  --------------
  --key Handler
  --------------
  local function my_keyhandler_func(dialog,key)
  
     --always focus the pattern editor so renoise responds to key input
     renoise.app().window.lock_keyboard_focus = false
     renoise.app().window.lock_keyboard_focus = true
  
     --if escape pressed then close the dialog else return key to renoise
     if not (key.modifiers == "" and key.name == "esc") then
        return key
     else
       dialog:close()
     end
  end 
    
  --Initialise Script dialog
  --------------------------
  my_dialog = renoise.app():show_custom_dialog(gui_name, dialog_content,my_keyhandler_func)
   
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    my_dialog = nil    
    if d and d.visible then
      d:close()
    end
     --check and remove renaming dialog if still open
    if (renaming_dialog ~= nil) and
     (renaming_dialog.visible == true) then
       renaming_dialog:close()
       renaming_dialog = nil
     end
    
  end
  
  
  
  --notifier to close dialog on load new song using preceding function
  ----------------------------------------------------------------------
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)

  
  
  --add timer to fire once every 50ms
  if not renoise.tool():has_timer(timer) then
    renoise.tool():add_timer(timer,80)
  end
  
  --first run timer (stops gui flashing)
  timer()
    
end
