renoise.tool():add_menu_entry {
  name = "DSP Chain List:List Doubled Devices",
  invoke = function()
             show_doubled_devices()
           end  
}

local my_dialog2  = nil
local vb2 = nil
-------------------------------
function show_doubled_devices()
-------------------------------
  
  
  --refresh dialog 
  if (my_dialog2 and my_dialog2.visible) then 
    my_dialog2:close()
  end
  
  my_dialog2 = nil 
  vb2 = nil
  
  --renoise song object
  local song = renoise.song()
  
  ------------------------------------
  local function get_doubled_devices()
  ------------------------------------
    local song = renoise.song()
    local rns_track_device_infos = renoise.song().tracks[1].available_device_infos
    local no_of_plugs = #rns_track_device_infos 
    
    local plug_vst = {}
    local vst_count = 0
    
    local plug_vst3 = {}
    local vst3_count = 0
    
    --populate tables with vst/vst3
    for i = 1,no_of_plugs do
    
      --get all VST Plugins short names
      if  string.find(rns_track_device_infos[i].path , "VST/") then
        vst_count = vst_count + 1
        plug_vst[vst_count] = rns_track_device_infos[i].short_name 
      elseif  string.find(rns_track_device_infos[i].path , "VST3/") then 
        vst3_count = vst3_count + 1
        plug_vst3[vst3_count] = rns_track_device_infos[i].short_name 
      end
    end
    
    local text = ""
    
    --compare tables for doubles
    local doubled_count = 0
    for i = 1,#plug_vst do
      for j = 1,#plug_vst3 do
        if plug_vst[i] == plug_vst3[j] then
          text = text.."\n".."   "..plug_vst[i]
          doubled_count = doubled_count + 1
          break
        end
      end
    end
    
    text = "\n   "..tostring(doubled_count).." MATCHES FOUND: \n"..text  
    return text
  end
  
  ----------------------------------------
  local function get_doubled_instruments()
  ----------------------------------------
  
    local song = renoise.song()
    local rns_inst_device_infos = renoise.song().instruments[1].plugin_properties.available_plugin_infos
    local no_of_plugs = #rns_inst_device_infos 
    
    local plug_vst = {}
    local vst_count = 0
    
    local plug_vst3 = {}
    local vst3_count = 0
    
    --populate tables with vst/vst3
    for i = 1,no_of_plugs do
    
      --get all VST Plugins short names
      if  string.find(rns_inst_device_infos[i].path , "VST/") then
        
        --("here")
        vst_count = vst_count + 1
        plug_vst[vst_count] = rns_inst_device_infos[i].short_name 
      elseif  string.find(rns_inst_device_infos[i].path , "VST3/") then 
        vst3_count = vst3_count + 1
        plug_vst3[vst3_count] = rns_inst_device_infos[i].short_name 
      end
    end
    
    local text = "" 
    
    --compare tables for doubles
    local doubled_count = 0
    for i = 1,#plug_vst do
      for j = 1,#plug_vst3 do
        if plug_vst[i] == plug_vst3[j] then
          text = text.."\n".."   "..plug_vst[i]
          doubled_count = doubled_count + 1
          break
        end
      end
    end
    
    text = "\n   "..tostring(doubled_count).." MATCHES FOUND: \n"..text  
    return text
  end
  
  ----------------------------------------------------
  local function get_doubled_devices_and_instruments()
  ----------------------------------------------------
    --join and format output of both functions
    return "\n DEVICES PRESENT AS VST 2.4 AND VST3:\n\n FX: \n"..get_doubled_devices().."\n\n\n INSTRUMENTS:\n"..get_doubled_instruments()
  end
 
  --set globals
  -------------
  --viewbuilder instance
  vb2 = renoise.ViewBuilder()
  
  ----------------------------------------------
  --GUI
  ----------------------------------------------     

  --variables that will be added to
  --dialog_content:add_child(send_row)
  local my_first_row = vb2:column{}
  -------------------------------
  local my_first_element = nil
  

    my_first_element = vb2:column{
                        margin = 2,
                         
                         
                          vb2:button{
                           text = "Re-Check",
                           notifier = function()
                                        --update readout string
                                        vb2.views["readout string"].text = get_doubled_devices_and_instruments()--get_doubled_instruments()--get_doubled_devices()
                                        --
                                        status("List Updated")
                                        
                                      end
                          },

                        vb2:multiline_textfield { 
                         id = "readout string",
                         width = 310,
                         height = 400,
                         text = get_doubled_devices_and_instruments() --get_doubled_instruments()--get_doubled_devices()
                        }
                       }


    my_first_row:add_child(my_first_element) 
  

  
  --------------------------------------------------------
  --------------------------------------------------------
  --dialog content will contain all of gui; passed to renoise.app():show_custom_dialog()
  local dialog_content = vb2:column{}
  dialog_content:add_child(my_first_row)
 
  --------------
  --key Handler
  --------------
  local function my_keyhandler_func(dialog,key)
     --toggle lock focus hack, allows pattern ed to get key input
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     return key
  end 
  
 
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  --Script dialog
  my_dialog2 = renoise.app():show_custom_dialog(
      "VSTi From Menu Tool", dialog_content,my_keyhandler_func)

 --[[ 
  --add timer to fire once every 50ms
  if not renoise.tool():has_timer(timer) then
    renoise.tool():add_timer(timer,80)
  end
  --]]
  
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    --close dialog if exists and is open     
    if (d ~= nil) and (d.visible == true) then
      d:close()
     -- remove_notifiers()
    end
    --reset global my_dialog2
     my_dialog2 = nil 
  end
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog2)
  -------------------------------------------------------------------------------
  
  --first run of timer
  -- timer()

  --renoise.app():show_message(display_unused_devices_in_song())
end
