--globals
---------
rot_fn = nil
my_dialog = nil
vb = renoise.ViewBuilder()
timer_updating = false
bypass_slider = false
view_auto_cbox_enabled = true --NEED TO ADD TO PREFERENCES
lock_mode = "Multiple Points Envelope"

require "grab_functions"
require "extra_key_functions"
require "rotary_functions"

--[[
--TODO Copy current automation to all empty automations
renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Copy Current Automation To All Empty",  
  invoke = function() copy_to_all_empty()
  end  
}

--]]





---------------------------
--main keybinding opens gui
---------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Automation Single Slider",  
  invoke = function() main()
  end  
}
--------------------------------------------------------------
--------------------------------------------------------------
-------------
--keybinding
-------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Add Inst. Auto Device To Track",  
  invoke = function() add_inst_auto_device()
  end  
}
-------------------------------------------------------
--adds an inst. automation device to the current track 
-------------------------------------------------------
function add_inst_auto_device()
   
  local song = renoise.song()
  --last device index
  local index = #song.selected_track.devices + 1 
  song.selected_track:insert_device_at("Audio/Effects/Native/*Instr. Automation",index)
  --select the device
  song.selected_device_index = #song.selected_track.devices
end
------------------------------------------------------
--------------------------------------------------------

-----------------
--main menu entry
-----------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Automation Single Slider",
  invoke = function() main()
  end
}
--track automation
renoise.tool():add_menu_entry {
  name = "Track Automation:Automation Single Slider",
  invoke = function() main()
  end
}
--track automation list
renoise.tool():add_menu_entry {
  name = "Track Automation List:Automation Single Slider",
  invoke = function() main()
  end
}
---------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Next Automated Parameter",  
  invoke = function() cycle_automated_parameters()
  end  
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Previous Automated Parameter",  
  invoke = function() reverse_cycle_automated_parameters()
  end  
}



renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Duplicate Automation Selection",  
  invoke = function() duplicate_selection_in_automation()
  end  
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`AUS` Set Auto Selection From Pattern Selection",  
  invoke = function() set_automation_range_from_pattern_selection_range()
  end  
}






--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:`ASL` Grab Plugin Parameter ",  
  invoke = function() grab_plugin_parameter_shortcut()
  end  
}
--]]
--note; MIDI mapping at end of file due to upvalues
----------------------------------------------------
-----------------------------------------------------


--TIMER FLAGS
-------------------------------------------------------------------
--flags for timer function, set after new document (song) is loaded
-------------------------------------------------------------------
stored_selected_track_device_index = nil
stored_selected_track_index = nil
stored_selected_automation_parameter = nil
stored_selected_track_device = nil

bypass_timer = false

--function to set initial values/ refresh flag values
-------------------
function set_flags()
  local song = renoise.song()
  --get current automation parameter handle/reference
  stored_selected_automation_parameter = song.selected_automation_parameter
  --store selected device
  stored_selected_track_device = song.selected_track_device
  --store selected device index
  stored_selected_track_device_index = song.selected_track_device_index
  --store selected
  stored_selected_track_index = song.selected_track_index
end
-------------------------------------------------------------------

--e.g. For changing vb.views["sample present colour 2"].color when states change
COLOR_GREY = {0x30,0x42,0x42}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}

COLOR_ORANGE_FLAG = 0xFF
COLOR_RED_FLAG = 0xEE
COLOR_GREY_FLAG = 0x30


--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
function status(message)
  renoise.app():show_status("Auto Slider Tool: ("..message..")")
end

--LOCK MODE BUTTON fn
---------------------------------------
--gets the colour of the lockmode button.  The Lock mode means automation for the whole selected
--pattern will be set to the same value i.e. a straight horizontal line
---------------------------------------
function get_lock_mode_color()
  if lock_mode == "Single Point Envelope" then
    return COLOR_RED
  else
    return COLOR_GREY
  end
end

--counts to 1000 called in the timer
t_counter = 0
function thousand_counter()
  t_counter = t_counter + 1
  if t_counter == 100 then 
    t_counter = 0
  end
  return t_counter
end


--global table to go with the functions
grab_button_available_params = nil --get_device_automatable_parameters(song.selected_track_device_index)
select_index_table = {}


-----------------------------------------------------------------------
--function to return a parameter index in "grab param button" notifier
----------------------------------------------------------------------




-----------------------------------------------------------
--GET ALL AVALIABLE AUTOMATIONS IN A TABLE (basis of tool)
-----------------------------------------------------------
--function returns a table of available (only .is_automatable) automations for the selected track device.
--This includes "Active/bypass" automation as index[1] of the returned table. Renoise treats these as a property of the device
--not as an indexed parameter.  The returned table is used as the basis of automation selection and parameter popup list population
--in this tool.
---------------------------------------------------
---------------------------------------------------
function get_device_automatable_parameters(device_index)
  
  local song = renoise.song()
  local available_automations = {}
  --check if parameter device_index is passed in, if not set to the parent device of the selected automation parameters
  --parent device
  device_index = device_index or get_selected_automation_parent_device_index()
  local device = song.selected_track:device(device_index)
  
  --add active/bypass parameter as no. 1 if it exists (only will not for mixer device)
  if device_index ~= 1 then --weed out mixer
    table.insert(available_automations,device.is_active_parameter)
  end
  --add the rest of the parameters
  for i = 1, #device.parameters do
    if device:parameter(i).is_automatable then--weed out un-automatable devices 
      table.insert(available_automations, device:parameter(i))
    end
  end
  
  return available_automations
end




--used in gui popup to mark a parmater that has active automation
--this makes automated parameters easier to find in list
AUTOMATED_PARAM_MARKER = "~" 

----------------------------------------------------------
--GUI function returns all of the selected devices parameter names
--used to populate popup, requires the result of get_device_automatable_parameters() to be passed
----------------------------------------------------------
function get_all_selected_device_parameter_names(available_parameters)
  
  local song = renoise.song()

  --make sure that mixer device is selected if there is no selected device
  if song.selected_track_device_index == 0 then
    song.selected_track_device_index = 1
  end
  --table to return
  local parameter_name_table = {}
  parameter_name_table.full = {}
  parameter_name_table.automated = {"---"}
  parameter_name_table.automated_selected_index = 1
  parameter_name_table.automated_equivalent_indexes = {}
  
  local available_params = available_parameters --or get_device_automatable_parameters(device_index)
  
  --loop through devices to get names
  for i =  1,#available_params do
    --weed out non automatable parameters
    if available_params[i].is_automatable then
      --add valid parameters to the table
      if available_params[i].is_automated then
        table.insert(parameter_name_table.full, AUTOMATED_PARAM_MARKER.." "..available_params[i].name.." "..AUTOMATED_PARAM_MARKER)--mark automated entries
        table.insert(parameter_name_table.automated, AUTOMATED_PARAM_MARKER.." "..available_params[i].name.." "..AUTOMATED_PARAM_MARKER)--mark automated entries
        table.insert(parameter_name_table.automated_equivalent_indexes,i)
        --if the selected_parameter is automated, record the index here for the automated part of the table
        --this can be used to index parameter_name_table.automated
        if rawequal(song.selected_automation_parameter,available_params[i])~= false then 
          parameter_name_table.automated_selected_index = #parameter_name_table.automated
        end
      else --not automated 
         table.insert(parameter_name_table.full, available_params[i].name)
      end
    end
  end
  
  --if only one parameter is automated don`t use "~" marks in popup 3
  if #parameter_name_table.automated == 2 then
    parameter_name_table.automated[2] = "    "..available_params[parameter_name_table.automated_equivalent_indexes[1]].name
  end
  
  --if no automated parameters found make popup blank with empty string --Will be hidden in gui anyway
  if #parameter_name_table.automated == 1 then
    parameter_name_table.automated = {""}
  end 
  --return table of device names
  return parameter_name_table 
end

--ALREADY AUTOMATED PARAM OBJECT (for popup)
--------------------------------------------------------------------------------------------
--loops through the tool GUI popup list to match name with the selected_automation_parameter
--requires: get_device_automatable_parameters() 
--------------------------------------------------------------------------------------------
function get_selected_automation_parameter_popup_index(available_parameters)
  --(available_parameters)
  local song = renoise.song()
  local available_params = available_parameters --or get_device_automatable_parameters(device_index)

  --loop to see what parameters are automatable and match to popup 
  --(the same weeding out is done when the popup list is populated with get_all_selected_device_parameter_names())
  for i = 1,#available_params do
    ---loop all device parameters
    if rawequal(song.selected_automation_parameter,available_params[i]) ~= false then    
      return i
    end
  end
  return nil
end

--PARENT DEVICE INDEX 
-------------------------------------------------------------------------
--function gets the parent device index for selected_automation_parameter
--on the selected track-- used to sync automation list with GUI when the parameter is changed in the renoise GUI
-------------------------------------------------------------------------
function get_selected_automation_parent_device_index()

  local song = renoise.song()
  --loop devices of selected track
  for device = 1,#song.selected_track.devices do
    ---new in b3 --renoise.song().selected_automation_device
    --see which track device matches the selected_automation_device and return its index
    if rawequal(song.selected_automation_device,song.selected_track:device(device)) ~= false then
      return device
    end
  end
  --no match found so return nil
  return nil
end

--SELECTED TRACK DEVICE NAMES
----------------------------------------------------------
--function returns all of the selected tracks device names
--used to populate popup
----------------------------------------------------------
function get_all_track_device_names()
  
  local song = renoise.song()
  local track = song.selected_track_index
  local name_table = {}
  --loop through devices to get names
  for i =  1,#song:track(track).devices do
    name_table[i] = song:track(track).devices[i].display_name
  end
  --return table of device names
  return name_table 
end



--holds a parameter after automation is deleted with [X] button so we can make sure it is properly set to default value
--it won`t work in the notifier function sometimes as the renoise player will change the result after the function returns
--so we have to tidy it in the timer.
deleted_automation_parameter_to_tidy =  nil 



require "gui_timer_function"



-------
--main
-------
function main()
  
  ----------------------------------------------
  --make sure timer has been released previously
  ----------------------------------------------
  if renoise.tool():has_timer(set_gui_values) then
    renoise.tool():remove_timer(set_gui_values)
  end    
  ----------------------------------------------------------------
  --toggle dialog closed if open; makes keyboard shortcut a toggle
  ----------------------------------------------------------------
  if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
    my_dialog:close()
    --remove timer 
    if renoise.tool():has_timer(set_gui_values) then
      renoise.tool():remove_timer(set_gui_values)
    end
    vb = nil
    return
  end
  -----------
  
  --renoise viewbuilder for gui
  vb = renoise.ViewBuilder()
  --song_object
  local song = renoise.song()
  
  
  --make sure a track device is selected if none is
  if song.selected_track_device_index == 0 then
    song.selected_track_device_index = 1
  end
  
  --get the devices available automation parameters and their names
  --get the available parameters for the target device; all automatable device parameters
  local first_run_available_parameters = get_device_automatable_parameters(song.selected_track_device_index)
  --get all available parameter names (automtable parameters)
  local first_run_selected_device_parameter_names = get_all_selected_device_parameter_names(first_run_available_parameters)
  
  -------------------------------------------------------------------------------------------------------------
  --Match-up/sync automated_parameter to current selected_track_device --RENOISE DOESN`T DO THIS AUTOMATICALLY.
  -------------------------------------------------------------------------------------------------------------
 
  --if the selected parameter is not already a param of the song.selected_track_device then
  --set/ Sync it in this if scope
  if (rawequal(song.selected_automation_device,song.selected_track_device) == false) then
  
    --check parameter 1 is automatable and set to that (default):
    --device has no parameters other than Active/Bypass
    if (#song.selected_track_device.parameters == 0) then
      song.selected_automation_parameter = song.selected_track_device.is_active_parameter
    --mixer device 
    elseif (song.selected_track_device_index == 1) then
      song.selected_automation_parameter = song.selected_track_device:parameter(1)
    --parameter 1 is simply not automatable
    elseif (song.selected_track_device:parameter(1).is_automatable == false) then
      song.selected_automation_parameter = song.selected_track_device.is_active_parameter                                                    
    else
      --select parameter 1
      song.selected_automation_parameter = song.selected_track_device:parameter(1)
    end
    ------
  
    --if song.selected_automation_parameter could not be set above, tool will not run properly so:
    --Show `warning! dialog` and return early
    if song.selected_automation_parameter == nil then
      renoise.app():show_warning(
      ("No Available parameter to Automate, make sure [ONLY] button is not on in automation list"))
      return
    end
    
    --If there is an already automated parameter in the selected device then set song.selected_automation_parameter to that
    -- (if this fails either of the above defaults Active/bypassed or :parameter(1) will be selected)
    if (#first_run_selected_device_parameter_names.automated > 1) then --will be empty if no params {}
      local first_automated_parameter_index = first_run_selected_device_parameter_names.automated_equivalent_indexes[1]
      song.selected_automation_parameter = first_run_available_parameters[first_automated_parameter_index]
    end
  end
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  
  --Initial set flags before the tool/user changes any values; [device/parameter/track]
  set_flags()
  ------------------------------------------------------------------------------------------
  
  ---------------------------------------------------------
  --GUI
  ---------------------------------------------------------

  local dialog_content = vb:vertical_aligner{ 
    id = "all gui",
    margin = 4,
     vb:horizontal_aligner{
      vb:text{
       text = "Selected Device:           "
      },
      vb:button{
       text = "+",
       notifier = function() --button adds an Instrument Automation Device if none are present, else it selects the last present one
                   local song = renoise.song()
                   local auto_device_found = false
                   
                   --loop devices
                   for i = #song.selected_track.devices,1,-1  do
                     if song.selected_track.devices[i].device_path == "Audio/Effects/Native/*Instr. Automation" then
                       auto_device_found = i
                       break
                     end
                   end
                   
                   if auto_device_found == false then
                     add_inst_auto_device()
                     status("Instrument Automation Device Added")
                   else
                     song.selected_track_device_index = auto_device_found
                     status("Last Instrument Automation Device In Track Selected")
                   end
                  end,
      }
     },
    -----------------------------
    vb:horizontal_aligner {
      margin = 4,
      
      vb:column{
       style = "group",
       margin = 4,
       
      vb:horizontal_aligner {
      margin = 4,
      
       vb:popup{
        items = get_all_track_device_names(),
        height = 20,
        width = 120,
        id = "popup 1 device name",
        value = song.selected_track_device_index,--initial value
        notifier = function(value)
                    
                     --return if called by timer
                     if (timer_updating == true) then
                       return
                     end
                     --bypass timer function
                     bypass_timer = true
                     
                     local song = renoise.song()
                     song.selected_track_device_index = value
                     bypass_timer = false
                     
                     --update gui (no table to pass here so it will be populated in set_gui_values() itself)
                     set_gui_values()
                    
                     
                     --[[
                     --cancel parameter-grab if it is enabled--resets [G] button if it was enabled by the user
                     cancel_grab_notifiers()
                     
                     local song = renoise.song()
                     local available_params = get_device_automatable_parameters(value)--pass in the new/ traget device index
                     --set selected device for the current track
                     song.selected_device_index = value
                     --update parameter popup
                     vb.views["popup 2 selected parameter name"].items = get_all_selected_device_parameter_names(available_params).full
                     ----update renoise parameter selection to same as parameter popup
                     song.selected_automation_parameter = available_params[2]
                     vb.views["popup 2 selected parameter name"].value = 2
                     --bypass timer function
                     bypass_timer = false--]]
                   end,
       
        },
       },
        --conatains top row
        vb:row{
        -- style = "group",
         margin = 4,
          vb:checkbox{
          id = "device active cbox",
          active = true,
          value = false,
          notifier =
            function(value)
              --return if called by timer
              if (timer_updating == true) then
                return
              end
              local device = renoise.song().selected_track_device
              if device ~= false then
                device.is_active = value
              end
                
            end
          },
          --enable device text
        vb:text{
         text = "En.    ",
         id = "Enable Text",
        },
        
        --grab / get paramater
        vb:button{
         text = "G",
         color = COLOR_GREY,
         id = "grab param button",
         notifier = function()
         
                      local song = renoise.song()
                      local device = song.selected_device
                      --[[
                      --use button to stop transport on first press
                      if song.transport.playing == true then
                        song.transport.playing = false
                         --return so player can reset an parameters stop moving and next press of button works
                       -- return
                      end
                      --]]
                      
                      --BUTTON BEING SWITCHED OFF
                      --set button to grey and remove notifers             
                      if vb.views["grab param button"].color[1] == 0xEE then-- (0x20 is first number for COLOR_RED)
                        vb.views["grab param button"].color = COLOR_GREY
                        
                        --remove notifiers if still attached
                        for i = 1,(#grab_button_available_params -1) do
                          --remove notifier for each parameter
                          if grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
                            grab_button_available_params[i].value_observable:remove_notifier(select_index_table[i])
                          end
                        end
                        --reset global tables
                        --1)availvable parameters
                        grab_button_available_params = nil
                        --2)table of functions to pass to notifiers
                        select_index_table = {}       
                      
                      --BUTTON ON --set button to green and add notifiers
                      else
                        --CASE: INSTRUMENT AUTOMATIO DEVICE
                        if song.selected_track_device.name == "*Instr. Automation" then
                        --[[
                          --check if selected istrument features in the selected track and is likely the target of the device (uncheckable in API 5)
                          if check_selected_plugin_present_on_current_track() == false then
                            local message = //Selected Instrument Not Found In Current Track.
Make Sure The Instrument Number Matches The Automation Device`s
Target Before Continuing//
                            if renoise.app():show_custom_prompt("WARNING! ", vb:horizontal_aligner{ margin = 4,vb:text{text = message,}}, {"Continue","Cancel"})== "Cancel" then
                              return
                            end 
                          end  
                        --]]
                          -------------
                          local function get_instrument_device_automatable_parameters()  
                            local song = renoise.song()
                            local available_automations = {}
                            --check if parameter device_index is passed in, if not set to the parent device of the selected automation parameters
                            local device =  song.selected_instrument.plugin_properties.plugin_device
                            --add the rest of the parameters
                            for i = 1, #device.parameters do
                              if device:parameter(i).is_automatable then--weed out un-automatable devices 
                                table.insert(available_automations, device:parameter(i))
                              end
                            end
                            return available_automations
                          end                   
                          
                          ----populate global table
                          grab_button_available_params =  get_instrument_device_automatable_parameters()
                          --mark table with automation device object in last position
                          table.insert(grab_button_available_params,song.selected_automation_device)  
                          vb.views["grab param button"].color = COLOR_RED
                          
                          --add notifiers into table of notifiers --IMPORTANT SO WE CAN REFERENCE NOTIFIERS LATER AND REMOVE THEM PROPERLY
                          for i = 1,(#grab_button_available_params - 1) do
                            select_index_table[i] = function() select_index_instrument(i) end
                          end
                          
                          for i = 1,(#grab_button_available_params - 1) do
                            --add notifier for each parameter
                            if not grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
                              grab_button_available_params[i].value_observable:add_notifier(select_index_table[i])
                            end
                          end 
                          
                          set_gui_values()
                          
                          if song.selected_instrument.plugin_properties.plugin_device.external_editor_available then
                            song.selected_instrument.plugin_properties.plugin_device.external_editor_visible = true
                          end
                        
                        else --standard FX plugin
                              
                          --make sure external editor is open (not true for instr. auro)
                          if song.selected_track_device.external_editor_available then
                            song.selected_track_device.external_editor_visible = true
                          else
                            song.selected_track_device.external_editor_visible = false
                          end
                          --get automations for device --ALSO CHEKED INSIDE NOTIFIER FUNCTION --select_index()
                          grab_button_available_params = get_device_automatable_parameters(song.selected_track_device_index)
                          
                          table.insert(grab_button_available_params,song.selected_automation_device) --add in a reference to the parent device at the end
                          vb.views["grab param button"].color = COLOR_RED                
                         
                          --add notifiers into table of notifiers --IMPORTANT SO WE CAN REFERENCE NOTIFIERS LATER AND REMOVE THEM PROPERLY
                          for i = 1,(#grab_button_available_params - 1) do
                            select_index_table[i] = function() select_index(i) end
                          end
                          
                          for i = 1,(#grab_button_available_params - 1) do
                            --add notifier for each parameter
                            if not grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
                              grab_button_available_params[i].value_observable:add_notifier(select_index_table[i])
                            end
                          end                            
                        end
                      end
                    end
        },
        
        vb:button{
         text = "Ext. Ed.",
         id = "external editor button",
         notifier = 
           function()
             local device = renoise.song().selected_track_device
             if (device ~= false) and (device.external_editor_available) then
               device.external_editor_visible = not device.external_editor_visible 
             else
               status("No Available Editor For This Device")
             end
           end
        },
      },--end of vb row containing device name
   
      },
    },
    
    vb:text{
     text = "Selected Param:" 
    },

    --contains name and LED
    vb:horizontal_aligner {
      margin = 4,
      vb:row {
       margin = 4,
       style = "group",
       
       
      vb:popup{  
       items = first_run_selected_device_parameter_names.full,
       height = 23,
       width = 110,
       id = "popup 2 selected parameter name",
       value = get_selected_automation_parameter_popup_index(first_run_available_parameters), --initial value
       notifier = function(value)
                    --return if called by timer
                    if (timer_updating == true) then
                      return
                    end
                    
                    --bypass timer function
                    bypass_timer = true
                    
                    local song = renoise.song()
                    --get_device_automatable_parameters(device_index) loops through a single devices parameters and returns a table.  For efficiency pass the device_index
                    --or it will loop through all devices parameters to find the parent device of current automation.  Here the device is not being changed so we pass 
                    --the selected_device_index
                    local available_params = get_device_automatable_parameters(song.selected_track_device_index)
                    --set the parameter
                    song.selected_automation_parameter = available_params[value]

                    --reset timer flag
                    bypass_timer = false
                    --call timer function (early)to sync better to popup change
                    --available_params passed for efficiency
                    set_gui_values(available_params)      
                    
                  end
       },
       vb:button{
        width = 15,
        height = 22,
        text = "X",
        id = "clear env button",
        notifier = 
           function()
           
             --gets the current sliders value converted to 0-1 for the automation
             local function convert_value_to_slider_range()
               if renoise.song().selected_track_parameter ~= nil then 
                 return(1/renoise.song().selected_track_parameter.value_max) * renoise.song().selected_track_parameter.value
               end 
             end
             --song 
             local song = renoise.song()
             --no parameter selected so return
             if (song.selected_automation_parameter == nil) then
               status("No Param selected")
               return
             end 
               --set flag
             bypass_slider = true

             --clear automation if present          
             if (song.selected_automation_parameter.is_automated == true) then
               --get currently selected automation object (pattern_track)    
               local automation = song.selected_pattern_track:find_automation(song.selected_automation_parameter)
               if automation ~= nil then --if nil there is none in this pattern_track
                 song.selected_pattern_track:delete_automation(song.selected_automation_parameter)
               else--If no automation in current pattern, then loop through song and delete all other patterns (--SECOND PRESS OF X CLEARS ALL)
                 
                --Check with user that they want to delete the whole envelope, return if no
                if renoise.app():show_custom_prompt("WARNING! ", vb:horizontal_aligner{ margin = 4, vb:text{text = "You Are About To Clear Automation From All Patterns,\n                For The Selected Parameter!",}}, {"Continue","Cancel"} ) == "Cancel" then
                  bypass_slider = false
                  return
                end

                 for i = 1, #song.patterns do
                   local automation = song.patterns[i].tracks[song.selected_track_index]:find_automation(song.selected_automation_parameter)
                    if automation ~= nil then
                    --this leaves an automation but can not delete it
                   -- automation:clear()
                     --delete the automation
                     song.patterns[i].tracks[song.selected_track_index]:delete_automation(song.selected_automation_parameter)
                   end
                 end
                 
               end                              
             end
             --set the slider to default value reflect (done first as will create a new automation after via its own notifier)
             --set slider to default value does not work here Button needs to be pressed twice?
             
              --BUG REPORTED---Dealt with imperfectly in the timer function now
             
              song.selected_automation_parameter.value = song.selected_automation_parameter.value_default
              --as the reset will not always work first time then redo in timer.
              if song.selected_automation_parameter.is_automated == false then
                deleted_automation_parameter_to_tidy = song.selected_automation_parameter
              end
           

           
            -- vb.views["auto slider"].value = convert_value_to_slider_range()
            
            
             bypass_slider = false
           end,
           
             --set one point
              --[[ for i = 1,song.selected_pattern.number_of_lines do
                  automation:add_point_at(i, convert_value_to_slider_range() ))
                end --]]
        
       }, 
      },
     },

     vb:text{
      text= " Automated list:", --spacer
      id = "auto param text",
     },
     
     --automated parameters popup
      vb:horizontal_aligner{ 
        mode = "Justify",
        margin = 4,
         vb:row {
         margin = 4,
         style = "group",
      
        vb:popup{
          id = "popup 3 automated params",
          width = 128,
          items = get_all_selected_device_parameter_names(first_run_available_parameters).automated, --initial value
          notifier =  function(value)
                        
                        --housekeeping
                        --------------
                        --return if called by timer
                        if (timer_updating == true) then
                          --only timer can select value 1 without being caught at next conditional
                          return
                        end
                        --value = 1 ("---")
                        if value == 1 then
                          --stops flashy response when scrolling popup
                          vb.views["popup 3 automated params"].value = 2
                          return
                        end
                        --bypass timer function
                        bypass_timer = true
                        
                        -------------------------------------------------------------------
                        --set the selected_automation_parmeter to match the new selection
                        -------------------------------------------------------------------
                        local song = renoise.song()
                        
                        --get_device_automatable_parameters(device_index) loops through a single devices parameters and returns a table.  For efficiency pass the device_index
                        --or it will loop through all devices parameters to find the parent device of current automation.  Here the device is not being changed so we pass 
                        --the selected_device_index
                        --------------------------
                        local available_params = get_device_automatable_parameters(song.selected_track_device_index)
                        --get names table
                        local names = get_all_selected_device_parameter_names(available_params)  
                        
                        --*** set the parameter ***
                        ------------------------
                        song.selected_automation_parameter = available_params[names.automated_equivalent_indexes[value-1]] 
                        --reset timer flag
                        bypass_timer = false
                        --call timer function (early)to sync better to popup change
                        --available_params passed for efficiency
                        set_gui_values(available_params)      
                      end,
        },
       },
     },
     
     
     vb:horizontal_aligner{ 
      -- mode = "Justify",
       margin = 4,  
       
       vb:button{
         text = "Lock",
         color = get_lock_mode_color(),
         id = "write mode button",
         notifier =
          function() --enable disable writing single point envelope.  i.e. 1 point controls value for whole track like a slider alone.
            if lock_mode == "Single Point Envelope" then
              lock_mode = "Multiple Points Envelope"
              vb.views["write mode button"].color = COLOR_GREY
            else
              lock_mode = "Single Point Envelope"
              vb.views["write mode button"].color = COLOR_RED
            end       
          end
         
       },
       --spacer
       vb:text{
        text = "               ",
       },
       
       vb:checkbox{
       value = view_auto_cbox_enabled,
       notifier = function(value)
                    view_auto_cbox_enabled = value
                  end
       
       --TODO ENABLE/ DISABLE AUTO CHANGE VIEW ON ROTARY
       },
       
      vb:button{
       text = "View",
       id = "view button",  
       notifier = 
            function()
              if renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS then
                renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
              else
              renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
              end
            end
       },
      },
    
    ---------------------------
   
   
    ------------------------
     --contains rotary
     vb:horizontal_aligner {
      margin = 4,
      mode = "distribute",
      -------------------------
   
      
      ---------
      vb:rotary{
  
        value = 0.5,--get_selected_track_perameter_value(),
        id = "auto slider",
        width = 80,
        height = 80,
        active = true,
        notifier = 
         function(value)
          --defined in file `require "rotary_functions"`
          --adds automation to the automation ed.
          standard_rotary(value)
          
          --If latch mode is enabled add a timer to refire the function every 50ms.
          --the timer gets removed inside standard_rotary() function or in the latch-button function below
          if vb.views["latch_mode"].color[1] ~= COLOR_GREY_FLAG then --if true latch button is red, so enabled
            if renoise.tool():has_timer(standard_rotary) == false then
               renoise.tool():add_timer(standard_rotary,50)
            end
          end 
        end
      },    
     },--horiz
     
      ----------------------------
     --Latch mode button
     vb:horizontal_aligner {
      margin = 4, 
       vb:button{ 
          text = "Latch",
          color = COLOR_GREY,
          id = "latch_mode",
          notifier = function()
                       --toggle colour between red and grey
                       if vb.views["latch_mode"].color[1] ~= COLOR_GREY_FLAG then
                           --remove timer function if present
                           if renoise.tool():has_timer(standard_rotary) == true then
                             renoise.tool():remove_timer(standard_rotary)
                             --reset flags
                             store_selected_automation_parameter = nil
                             store_line_no = nil
                           end
                           --set button to grey
                           vb.views["latch_mode"].color = COLOR_GREY
                       else
                          --set button to Orange to show engaged (turns red via standard_rotary fn )
                         vb.views["latch_mode"].color = COLOR_ORANGE
                       end
                     end
         },
     --[[  vb:text{
         text = "    Res:"
       },
       vb:valuebox{
       } --]]   
       
       },-----
       
       vb:text{ 
          text = "", --vertical spacer
         },
      
    vb:horizontal_aligner{
      mode = "center",
      
      vb:row{
      style = "group",
      margin = 4,
       
       vb:vertical_aligner{
        
        
         vb:horizontal_aligner{
           --[[
           vb:textfield{
           text = "",
           width = 28,
           id = "selected Parameter value readout",
           },--]]
           ---
         --[[   vb:text{
           text = "("..get_parameters_default_value_as_percentage().."%)",
           id = "default precentage",
           },--]]
          vb:minislider{
          width = 100,
          height = 15,
        -- height = 80,
          id = "minislider readout"
          },
       },    
      },
     },
    },
    vb:horizontal_aligner{
    -- mode = "center",
      vb:text{
      text = "",
      id = "value string"
     },
    },
   --[[ 
    vb:horizontal_aligner{ 
      -- mode = "Justify",
       margin = 4,  
    --New row Controls text
       vb:button{
        text = "Fill Gaps",  ---
        notifier = function()
            local song = renoise.song()
            --renoise.song().selected_track_parameter_index
            local selected_param = song.selected_automation_parameter
            local auto_number = nil
            local selected_track = song.selected_track_index
                  
            --loop through patterns and add current value to each empty automation
            for pattern = 1,#song.patterns do
              local pattern_track = song.patterns[pattern].tracks[selected_track]
              
              --loop to rawequal match selected parmeter to list in pattern_track automation table
              --necessary as the number is not stored as a property of the selected parameter
              for i = 1, #pattern_track.automation do
                if rawequal(pattern_track.automation[i].dest_parameter,selected_param) ~= false then
                  auto_number = i
                  break
                end 
              end
              
              --check for automation in each pattern and add/activate it if not there
              if not auto_number then
                --create automation for the selected parameter
                local new_automation = pattern_track:create_automation(selected_param)
                --scale to 1
                local scaled_value = (selected_param.value/selected_param.value_max)
                new_automation:add_point_at(1 , scaled_value)
                status("Automations Added to All Empty Patterns")
              end
              --reset automation number for each pattern
              auto_number = nil
            end
          end
       },
      }, --]]
     }--end of gui table
  --------------------------------------------
  
  ------------------------------------------------------------------
  --key Handler passes key input to renoise when tool gui is focused
  ------------------------------------------------------------------
  local function my_keyhandler_func(dialog, key)
   --hack to always refocus the pattern editor so renoise responds to key input
   renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
   renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
   return key
  end
  --show and assign dialog
  local title = "Auto Slider"
  my_dialog = renoise.app():show_custom_dialog(title,dialog_content,my_keyhandler_func)
  
 
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    my_dialog = nil    
    if d and d.visible then
      renoise.tool():remove_timer(set_gui_values)
      d:close()
      vb = nil
    end
  end
  --notifier to close dialog on load new song using preceding function
  ----------------------------------------------------------------------
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  
  -----------------------------------
  --add timer to fire once every 40ms
  -----------------------------------
  if not renoise.tool():has_timer(set_gui_values) then
    renoise.tool():add_timer(set_gui_values,40)
  end    

end--end of main


----------------------------------------------
--MIDI Mappings; declared at end for up values
----------------------------------------------
--ROTARY midi mapping function
------------------------------
local function midi_mapping_for_rotary(message)
  -- oprint(message.int_value)
   --do nothing if dialog is closed
  if not (my_dialog and my_dialog.visible) then
    return
  end
  --get the slider/rotary value
  local val = message.int_value
  --scale value from 127 max to 100 max for slider
  val = (1/127)*val
  --update rotary
  vb.views["auto slider"].value = val
end

--add mapping
renoise.tool():add_midi_mapping{
  name = "Automation Single Slider:Large Rotary",
  invoke = function(message) midi_mapping_for_rotary(message)
  end
}







