----------------------------------------------------
----------------------------------------------------
--timer function (fires every 40ms when gui is open)
----------------------------------------------------
----------------------------------------------------
--checks for user changes in renoise; selected_parameter, selected device
--checks for similar user changes made via gui too
--keeps gui up to date, synced/ readout updated etc.
function set_gui_values(passed_available_params,passed_available_names)
  
  --housekeeping
  ---------------
  --remove timer if GUI closed or my dialog doesn`t exist
  if (my_dialog == nil) or (my_dialog.visible == false) then 
    --remove timer/vb = nil
    if renoise.tool():has_timer(set_gui_values) then
      renoise.tool():remove_timer(set_gui_values)
      vb = nil
      return
    end
  end 
  --flag to bypass dur to conflicting functions true?
  if bypass_timer == true then
    return
  end 
 
  --set flag for competing/conflicting functions
  timer_updating = true
  -------------------------------------
  
  --song object
  local song = renoise.song()
  
  --[G] Grab plugin parameter button
  --return g button to grey after a time bring green
  if thousand_counter() == 25 then
    if vb.views["grab param button"].color[1] == 0x20 then --green 
      vb.views["grab param button"].color = COLOR_GREY
    end
  end
  
  --activate grab button or not
  if song.transport.playing == true then
    vb.views["grab param button"].active = false
  else
    vb.views["grab param button"].active = true
  end 
  
  --will hold table with available parameters (automation list in renoise)
  --we don`t want to get these values more than necessary in the timer from for efficiancy reasons
  --get_device_automatable_parameters(device_index) can be a large loop if the device has a lot of parameters
  local available_parameters = passed_available_params or nil 
  --set available names if passed in
  local available_names = passed_available_names or nil
    
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --make sure parameter from [x] notifier is reset properly (may need 2 runs of timer)
  --catch whebn
  if (deleted_automation_parameter_to_tidy ~= nil) and
    (deleted_automation_parameter_to_tidy.value == deleted_automation_parameter_to_tidy.value_default) then
    status("`"..deleted_automation_parameter_to_tidy.name.."` Automation Deleted and Default Value Restored: "..deleted_automation_parameter_to_tidy.value_string) 
    deleted_automation_parameter_to_tidy = nil
  end
  --catch when automated 1st try.
  if deleted_automation_parameter_to_tidy ~= nil then
    if deleted_automation_parameter_to_tidy.is_automated ~= true then
      deleted_automation_parameter_to_tidy.value = deleted_automation_parameter_to_tidy.value_default
      status("`"..deleted_automation_parameter_to_tidy.name.."` Automation Deleted and Default Value Restored: "..deleted_automation_parameter_to_tidy.value_string)
    end
  end
  
  --ABOVE DOESN`T ALWAYS WORK AS RENOISE PLAYER CAN RESET AFTERWARDS
  --[X] button notifies it didn`t work later by turning yellow and can be re-pressed by user.
  --The second press will restore the value_default
  ------------------------------------------------------------------
  ------------------------------------------------------------------
  
 
  
  --make sure a device is selected if none is
  --this changes stored_device_index index too so stuff will be rightly called later in timer
  if song.selected_track_device_index == 0 then
    song.selected_track_device_index = 1
  end
  
  --make sure parameter is selected too if none is.  we first choose parameter 1 as
  ---------------------------------
  --it helps with visual feedback on device change; otherwise popup 2 always shows Active/bypassed
  if song.selected_automation_parameter == nil then
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
  end
  
  --if parmeter is still nil then blank GUI, SOMETHING WENT WRONG!!: Happens if [ONLY] button is enabled in the automation list)
  if song.selected_automation_parameter == nil then
    vb.views["all gui"].visible = false
    status("If [Only] button is enabled in automation editor, deselect it")
    --reset timer flag
    timer_updating = false
    return
  else
    vb.views["all gui"].visible = true
  end

  -----------------------------------
  --USER CHANGED DEVICE IN RENOISE? 
  ------------------------------------
  -- If so we have to cancel any grab notifiers and make sure a
  --new automation is selected and synced to the new device
  if (rawequal(stored_selected_track_device,song.selected_track_device) == false) then 
 
    --cancel parameter-grab if it is enabled--resets [G] button if it was enabled by the user
    --always done on device change
    cancel_grab_notifiers()
   
    --device changed so we now have to sync a new parameter
    -------------------------------------------------------
    ------------------------------------------
    --check parameter 1 is automatable:
     --device has no parameters other than Active/Bypass
    if (#song.selected_track_device.parameters == 0) then
      song.selected_automation_parameter = song.selected_track_device.is_active_parameter
     -- print("called 1")
    --mixer device 
    elseif (song.selected_track_device_index == 1) then
      song.selected_automation_parameter = song.selected_track_device:parameter(1)
     -- print("called 2")
    --parameter 1 is simply not automatable
    elseif (song.selected_track_device:parameter(1).is_automatable == false) then
      song.selected_automation_parameter = song.selected_track_device.is_active_parameter
    --  print("called 3")                                                   
    else
      --select parameter 1
     -- print(song.selected_automation_parameter.name)
      song.selected_automation_parameter = song.selected_track_device:parameter(1)
    --  (song.selected_automation_parameter.name)
   --   print("called 4")
    end
      
    --if song.selected_automation_parameter could not be set above, tool will not run properly so:
    --Show `warning! dialog` and return early
    if song.selected_automation_parameter == nil
    or (rawequal(stored_selected_automation_parameter,song.selected_automation_parameter) ~= false) then
       vb.views["all gui"].visible = false
       status("If [Only] button is enabled in automation editor, deselect it")
      --reset timer flag
      timer_updating = false
      return
    else
    vb.views["all gui"].visible = true
    end
    --[[
     renoise.app():show_warning(
      ("Parameter not updated, make sure [ONLY] button is not on in automation list and\nsearch box is clear"))
      stored_selected_automation_parameter = song.selected_automation_parameter
      return
    end
    --]] 

    --FOLLOWING MEANS THAT THE FIRST AUTOMATED PARAMETER WILL BE SELECTED IN THE NEW DEVICE IF ONE EXISTS
    --get available parameters
    if available_parameters == nil then
      available_parameters = get_device_automatable_parameters(song.selected_track_device_index)
    end
    
    --get all available parameter names (automtable parameters) if not passed into function
    if available_names == nil then
      available_names = get_all_selected_device_parameter_names(available_parameters)
    end
    --If there is an already automated parameter in the selected device then set song.selected_automation_parameter to that
    -- (if this fails either of the above defaults Active/bypassed or :parameter(1) will be selected)
    if (#available_names.automated > 1) then --will be empty if no params {}
      local automated_parameter_index = available_names.automated_equivalent_indexes[1]
      song.selected_automation_parameter = available_parameters[automated_parameter_index] 
    end
  end

  -------------------------------------
  --USER CHANGED PARAMETER IN RENOISE? (in automation list)
  -------------------------------------
  --(also will have changed if the device changed as above but parameter can do so independently too in automation list)
  -----------------------------------------------------------------------------------------------------
  if (rawequal(stored_selected_automation_parameter,song.selected_automation_parameter) == false) then 
   
    --if the new parameter is in a new device then update the selected track device to be the same
    if (rawequal(song.selected_automation_device,song.selected_track_device) == false) then 
      --this function loops through all the selected-tracks devices and gets the parent device index
      --for the currently selected automation parameter 
      song.selected_track_device_index = get_selected_automation_parent_device_index()
    end
  
    --fn: get_device_automatable_parameters(device_index) loops through a single devices parameters and returns a table.  For efficiency pass the device_index
    --or it will loop through all devices to find the parent device of current automation.
    
    --if available parameters {} has not been passed into function or the device has been changed earlier in this function then: get available parameters for device
    if (available_parameters == nil) or (song.selected_track_device_index ~= stored_selected_track_device_index) then 
      available_parameters = get_device_automatable_parameters(song.selected_track_device_index)
    end
   
    --if parent index exists i.e. an automation parameter is selected with a valid parent device.
    if song.selected_track_device_index ~= nil then
     
      --update selected device popup --when a user changes the parameter in the automation list, the device can change too
      vb.views["popup 1 device name"].items = get_all_track_device_names()
      --update the tool gui selected device name display
      vb.views["popup 1 device name"].value = song.selected_track_device_index
      --update the selected device index.  In renoise the selected device does not follow the selected_automation_parameter
      if available_names == nil or (song.selected_track_device_index ~= stored_selected_track_device_index) then  
        available_names = get_all_selected_device_parameter_names(available_parameters)
      end
      --update parameter names
      vb.views["popup 2 selected parameter name"].items = available_names.full
      --set selected dropdown to current parameter                                                
      vb.views["popup 2 selected parameter name"].value = get_selected_automation_parameter_popup_index(available_parameters)
    end
  end
  ---------------------------------------------------
  --------------------- 
  -------  

  -------------------------------------------------------------------------
  --Destination device object 
  local destination_device = song.selected_track_device
  -------------------------------------------------------------------------

  --ENABLE CHECKBOX on and active if not pointing to renoise mixer device[1]      --master track device 1 = M&T
  if song.selected_track_device_index == 1 then
    --checkbox on but inactive
    vb.views["device active cbox"].value = true
    vb.views["device active cbox"].active = false
  else --active and set by devices state
    vb.views["device active cbox"].value = destination_device.is_active
    vb.views["device active cbox"].active = true
  end
   
  --show/ hide EXTERNAL EDITOR BUTTON if pointing to plugin or not
  ----------------------------------------------------------------
  if destination_device.external_editor_available then
    --change enable text
    vb.views["Enable Text"].text = "En."
    vb.views["external editor button"].visible = true 
    --colour it yellow when external editor is open
    if destination_device.external_editor_visible == true then
      vb.views["external editor button"].color = COLOR_ORANGE
    else
      vb.views["external editor button"].color = COLOR_GREY
    end
    --also show grab [G] button
    vb.views["grab param button"].visible = true
  
  else --hide them
    --unless an inst. automation device is selected and pointing to a VST/ plugin instrument
    if (song.selected_track_device.device_path == "Audio/Effects/Native/*Instr. Automation") and
       (song.selected_instrument.plugin_properties.plugin_device ~= nil) then
   -- and song.selected_track_device:parameter(1).value_string == then
      vb.views["grab param button"].visible = true
      vb.views["external editor button"].visible = false
    else
      vb.views["grab param button"].visible = false
      vb.views["external editor button"].visible = false
    end
  end  
  

  ----------------------------------
  --CURRENT PARAMETER IS AUTOMATED ?
  ----------------------------------
 
  --get tables if not already present
  -------------------------------
  --if the user did not change something in renoise or an available_parameters table
  --was not passed into function then available_parameters should still be nil
  --so get them now as something may have been changed in the gui.
  if available_parameters == nil then
    available_parameters = get_device_automatable_parameters(song.selected_track_device_index)
  end
  
  if available_names == nil then  
    available_names = get_all_selected_device_parameter_names(available_parameters)
  end
  
  --if no automations are present then hide the popup/ else show
  if #available_names.automated < 2 then
    vb.views["popup 3 automated params"].visible = false
  else
    vb.views["popup 3 automated params"].visible = true
  end
  
  -- make sure pop_up 3 is showing the correct parameter
  vb.views["popup 3 automated params"].items = available_names.automated 
  
  ---set [X] button 
  --to GREEN if automation present
  ------------------------------------------------------
  if song.selected_parameter.is_automated then
    -- make sure pop_up 3 is showing the correct parameter 
    vb.views["popup 3 automated params"].value = available_names.automated_selected_index
    --set color
    vb.views["clear env button"].color = COLOR_GREEN --[X] Button
    if renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS then
      vb.views["view button"].color = COLOR_GREEN--View button green to prompt to view automation
    else
      vb.views["view button"].color = COLOR_GREY--View button (grey as automation visible)
    end
    --as we are on an automated parameter
    --update parameter names again if // \\ markers are not present in the currently selected popup item --i.e. add them now
      ------------------------------------------------------------------------------------------------------------------------
    if string.find(vb.views["popup 2 selected parameter name"].items[vb.views["popup 2 selected parameter name"].value],AUTOMATED_PARAM_MARKER) == nil then
     --update parameter names
      vb.views["popup 2 selected parameter name"].items = available_names.full
    end
  
  --to YELLOW. case PARAMETER NOT AUTOMATED and `NOT AT` DEFAULT VALUE
  -------------------------------------------------------  
  elseif song.selected_parameter.value ~= song.selected_parameter.value_default then --not at default value
    -- make sure pop_up 3 is showing the correct parameter 
    vb.views["popup 3 automated params"].value = 1 -- here "---" will be shown as no automated parameter is selected in popup 2
    --set color
    vb.views["clear env button"].color = COLOR_YELLOW
    vb.views["view button"].color = COLOR_GREY--View button
     --update parameter names again if // \\ markers are present in the currently selected popup item -- i.e remove themn now
    if string.find(vb.views["popup 2 selected parameter name"].items[vb.views["popup 2 selected parameter name"].value],AUTOMATED_PARAM_MARKER) ~= nil then
      --update parameter names
      vb.views["popup 2 selected parameter name"].items = available_names.full
    end
    
  --to GREY. case PARAMETER NOT AUTOMATED and `IS AT` DEFAULT VALUE
  ----------------------------------------------------
  else
    -- make sure pop_up 3 is showing the correct parameter 
    vb.views["popup 3 automated params"].value = 1 -- here "---" will be shown as no automated parameter is selected in popup 2
    --set color
    vb.views["clear env button"].color = COLOR_GREY
    vb.views["view button"].color = COLOR_GREY--View button
    --update parameter names again if // \\ markers are present in the currently selected popup item -- i.e remove them now
    if string.find(vb.views["popup 2 selected parameter name"].items[vb.views["popup 2 selected parameter name"].value],AUTOMATED_PARAM_MARKER) ~= nil then
      --update parameter names
      vb.views["popup 2 selected parameter name"].items = available_names.full
    end 
  end --end song.selected_parameter.is_automated checks
  -----------------------------------------------------
  -----------------------------------------------------
 
  --update minislider readout. As selected parameter changes, their ranges change so update that too 
  ------------------------------------

  --selected parameter range
  vb.views["minislider readout"].max = song.selected_parameter.value_max
  vb.views["minislider readout"].min = song.selected_parameter.value_min

  
  --if test TO DEAL WITH BUG IN API?  meta devices returning routing values of -1 if routed to the current track--(been reported, may be fixed by API 6, post renoise 3.1)
  if (song.selected_parameter.value < song.selected_parameter.value_min) then
    vb.views["minislider readout"].value = song.selected_parameter.value_min
  else 
    vb.views["minislider readout"].value = song.selected_parameter.value
  end
  
  --final check for automation names (sometimes with instrument auto.device)
  
  
  --[[
  --show *above popup 3 when there are more than 1 automated params
  local total_automated_params = (#available_names.automated - 1)
  
  if total_automated_params < 2 then
    total_automated_params = ""
  else --format total as bracketed string 
   -- local selected_value = (vb.views["popup 3 automated params"].value - 1)
   -- total_automated_params = "("..selected_value.." / "..(#available_names.automated - 1)..")"
  -- local total = total_automated_params
   -- total_automated_params = ""
  -- for i = 1,total do
     total_automated_params = "\""-- total_automated_params.."*"
  -- end
  end
  
   
  --update text above popup 3
  vb.views["auto param text"].text = " Automated: "..total_automated_params
 --]]
  -------------**************************************************************************************
  --TODO checks for string length so tool GUI doesn`t get automatically widened on extra long value_strings
  --**************************************************************************************************
  
  --add value to gui under slider; --"    " is a spacer
  vb.views["value string"].text = "      "..song.selected_automation_parameter.value_string 
    
  --set flags
  -----------
  set_flags()
  ------------------------------------------------
  --reset timer flag
  timer_updating = false
  
end--eof
---------------------------------------------
---------------------------------------------
