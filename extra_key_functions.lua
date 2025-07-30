--2 local functions
-----------------
--function returns a table of all the automatable parameters of a device (for the current selected track)
--accepts a device index or defaults to the currently selected track device
--------------------------------------------------------------
local function get_device_automatable_parameters(device_index)
--------------------------------------------------------------  
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

--PARENT DEVICE INDEX 
-------------------------------------------------------------------------
--function gets the parent device index for selected_automation_parameter
--on the selected track
-------------------------------------------------------------------------
local function get_selected_automation_parent_device_index()
------------------------------------------------------------
  local song = renoise.song()
  --loop devices of selected track
  for device = 1,#song.selected_track.devices do
    --see which track_device matches the selected_automation_device and return its index
    if rawequal(song.selected_automation_device,song.selected_track:device(device)) ~= false then
      return device
    end
  end
  --no match found so return nil
  return nil
end
------------------------
------------------------

--keyboard-shortcut functions follow:

------------------------------------------------------------------------
--function to select the next automated parameter in the automation list
------------------------------------------------------------------------
function cycle_automated_parameters()
-------------------------------------

  --renoise song
  local song = renoise.song()
  local initial_device = song.selected_automation_device
  local initial_parameter = song.selected_automation_parameter
  
  --default parent device as device 1 (when no parameter or device is selected already))
  local parent_dev_index = 1
  local available_params = get_device_automatable_parameters(parent_dev_index)

  --CASE: Automation not visible:
  --show automation lane if not visible, --first press of shortcut only
  ----------------------------------------------------------------------------------------------------
  if (renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS) then
    renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
    --is a parameter selected
    if (initial_parameter ~= nil) then
      --if selected parameter is automated then return
      if (initial_parameter.is_automated == true) then
        return
      else --if it`s not automated then set parameter to first param of first device --default
        song.selected_parameter = available_params[1]
      end
    end
  end
  

  --1a) if no parameter is selected then select the first one for this device -- return if newly selected device is automated
  --------------------------------------------------------------------------------------------------------------------------
  if song.selected_automation_parameter == nil then
    -- ************ Set new selected parameter *********************************
    song.selected_automation_parameter = available_params[1]
    --the first parameter is selected and automated so return
    if song.selected_automation_parameter.is_automated then
      return
    end
  end
  
  --1b) if a parameter is selected then get the current parent device index and the available automatable parameters
  -------------------------------------------------------------------------------------------------------------------
  parent_dev_index = get_selected_automation_parent_device_index()
  --get_device_automatable_parameters(device_index) loops through a single devices parameters and returns a table.  For efficiency pass the device_index
  --or it will loop through all devices parameters to find the parent device of current automation.  Here the device is not being changed so we pass 
  --the selected_device_index
  available_params = get_device_automatable_parameters(parent_dev_index)
  

  --2) if the last parameter has been reached (is selected) then select the first parameter of the next device
  ------------------------------------------------------------------------------------------------------------
  if rawequal(song.selected_automation_parameter,available_params[#available_params]) == true then
    
    --if on last device then return as no more devices to go to
    if parent_dev_index == #song.selected_track.devices then
      return
    end
   
    --index of the next device (default is parent + 1)
    local next_device_index = (parent_dev_index + 1) 
    local num_devices = #song.selected_track.devices
    --are we on the last device?
    if rawequal(song.selected_automation_device,song.selected_track.devices[num_devices]) == true then
      --if so the next device is now 1
      next_device_index = 1
    end
    --get available parameters from the next available device
    available_params = get_device_automatable_parameters(next_device_index)
    -- *** Set new selected parameter ***********************************
    song.selected_automation_parameter = available_params[1]
    --if the newly selected first param is automated then return
    if song.selected_automation_parameter.is_automated then
      return
    else
      song.selected_automation_parameter = initial_parameter
    end
  end
  
  local initial_device_index = parent_dev_index 
  
  -----------------------------------------------------------------------------------------------------------------------------------
  --`for loop` for number of device in track (although loop starts from 1, we can be offset to any device index looping e.g. 3,4,1,2)
  ------------------------------------------------------------------------------------------------------------------------------------
   for devices = 1,#song.selected_track.devices do
   
     local selected_param_index = 0 --default 0 as 1 added in second loop

     --3) loop device to find the selected parameter index
     for i = 1, #available_params do 
       if rawequal(song.selected_automation_parameter,available_params[i]) == true then  
         selected_param_index = i
         break
       end
     end
        
     --loop to select the next automated parameter.  Return if found
     for i = (selected_param_index + 1), #available_params do
       --selects the next automated parameter
       if available_params[i].is_automated == true then
        -- ************ Set new selected parameter *********************************
        song.selected_automation_parameter = available_params[i]
        return
      end
    end
    
    --we`ve reached the last device and found no automated parameters so return
    if parent_dev_index == #song.selected_track.devices then
      return
    end
    
    --move to next device
    ----------------------
    parent_dev_index = (parent_dev_index + 1) 
    --get available parameters from the next available device
    available_params = get_device_automatable_parameters(parent_dev_index)
    
    if initial_device_index == parent_dev_index then
       -- *** Set new selected parameter **********************************
       song.selected_automation_parameter = available_params[1]
       if song.selected_automation_parameter.is_automated then 
         return
       else --parameter was not automated so change back to initial parameter (Case: no automated parameters)
         song.selected_automation_parameter = initial_parameter
         return
       end
    end
  end
end

----------------------------------------------------------------------------
--function to select the previous automated parameter in the automation list
----------------------------------------------------------------------------
function reverse_cycle_automated_parameters()
-------------------------------------
  
  --renoise song
  local song = renoise.song()
  local initial_device = song.selected_automation_device
  local initial_parameter = song.selected_automation_parameter
  
  --default parent device as last device (when no parameter or device is selected alredy))
  local parent_dev_index = #song.selected_track.devices
  local available_params = get_device_automatable_parameters(parent_dev_index)


  --CASE: Automation not visible:
  --show automation lane if not visible, --first press of shortcut only
  ----------------------------------------------------------------------------------------------------
  if (renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS) then
    renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
    --is a parameter selected
    if (initial_parameter ~= nil) then
      --if it`s automated then return
      if (initial_parameter.is_automated == true) then
        return
      else --if it`s not automated then set parameter to first param of first device
        song.selected_parameter = available_params[#available_params]
      end
    end
  end

  
  --1a) if NO PARAMETER IS SELECTED then select the first one for this device -- return if newly selected device is automated
  --------------------------------------------------------------------------------------------------------------------------
  if song.selected_automation_parameter == nil then
    -- ************ Set new selected parameter *********************************
    song.selected_automation_parameter = available_params[1]
    --the first parameter is selected and automated so return
    if song.selected_automation_parameter.is_automated then
      return
    end
  end
  
  --1b) if a parameter is selected then get the current parent device index and the available automatable parameters
  -------------------------------------------------------------------------------------------------------------------
  parent_dev_index = get_selected_automation_parent_device_index()
  --get_device_automatable_parameters(device_index) loops through a single devices parameters and returns a table.  For efficiency pass the device_index
  --or it will loop through all devices parameters to find the parent device of current automation.  Here the device is not being changed so we pass 
  --the selected_device_index
  available_params = get_device_automatable_parameters(parent_dev_index)

  --2) if the first parameter has been reached (is selected) then select the last parameter of the next device
  ------------------------------------------------------------------------------------------------------------
  if rawequal(song.selected_automation_parameter,available_params[1]) == true then
    
    --if on first device `vol pan width` then return as no more devices to go to
    if parent_dev_index == 1 then
      return
    end
    --index of the next device (default is parent - 1)
    local parent_dev_index = (parent_dev_index - 1) 
    local num_devices = #song.selected_track.devices
    --get available parameters from the next available device
    available_params = get_device_automatable_parameters(parent_dev_index)
    -- *** Set new selected parameter  as last of device***********************************
    song.selected_automation_parameter = available_params[#available_params]
    --if the newly selected  param is automated then return
    if song.selected_automation_parameter.is_automated then
      return
    end
  end
           
  -----------------------------------------------------------------------------------------------------------------------------------
  --`for loop` for number of device in track (although loop starts from 1, we can be offset to any device index looping e.g. 3,4,1,2)
  ------------------------------------------------------------------------------------------------------------------------------------
   for devices = 1,#song.selected_track.devices do
   
     local selected_param_index = #available_params --count from max

     --3) loop device to find selected parameter index
     for i = #available_params,1,-1  do 
       if rawequal(song.selected_automation_parameter,available_params[i]) == true then  
         selected_param_index = i
         break
       end
     end
             
     --loop to select the previous automated parameter.  Return if found
     for i = (selected_param_index - 1), 1,-1  do
       --selects the next automated parameter
       if available_params[i].is_automated == true then
        -- ************ Set new selected parameter *********************************
        song.selected_automation_parameter = available_params[i]
        return
      end
    end
    
    --we`ve reached the first device and found no automated parameters so return
    if parent_dev_index == 1 then
      return
    end
    
    --no automated param found so go to previous device
    parent_dev_index = (parent_dev_index - 1) 
    --get available parameters from the next available device
    available_params = get_device_automatable_parameters(parent_dev_index)
    --set last parameter
    if available_params[#available_params].is_automated then
      song.selected_automation_parameter = available_params[#available_params]
      return
    end
  end
end



---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
function duplicate_selection_in_automation()
--------------------------------------------

  --local function returns value on automation line, between two points
  --accepts two automation points (tables with time and value) and a target time (line)
  ------------------------------------------------------------------------------------
  local function get_automation_value_between_two_points(point_1,point_2,target_time)
  
    local value_1 = point_1.value
    local value_2 = point_2.value
    local point_1_time = point_1.time 
    local point_2_time = point_2.time 
    
    --initial triangle
    --Opposite = difference in value of initial points
    --Adjacent = difference in time of initial points
    local opposite = value_2 - value_1
    local adjacent = point_2_time - point_1_time
     
    --tan_a == opposite / adjacent
    --get tan_a
    local tan_a = math.tan(opposite / adjacent)
      
    --update adjacent which is now from the first automation point to the target_time
    adjacent = target_time - point_1_time
    --now get the opposite side of the new triangle (with point 1 and target point)
    local new_opposite = tan_a * adjacent
   
    --add the opposite side value to value 1 to get full distance of point from 0
    local aut_value = new_opposite + value_1
    --weed out rounding errors
    if aut_value > 1 then aut_value = 1 end
    if aut_value < 0 then aut_value = 0 end
    --return
    return aut_value
  end
  ---------------------------------------------------------------

  --get renoise values
  local song = renoise.song()
  local current_param = song.selected_automation_parameter
  local current_aut = song.selected_pattern_track:find_automation(current_param)
  
  if current_aut == nil then --return and update renoise status bar via custom status function
    status("No Automation Present")
    return
  end
  
  local points = current_aut.points --table with time and value of all autoamtion points
  local num_points = #points
  
  --constants
  local LUA_COUNTS_FROM_1 = 1
  --255/256 (the selection range in renoise counts from 0 which is the first slice of line 1.
  --So at the end of the pattern rather than a whole number we have 255/256 of a whole line.
  local OVERHANG = 0.99609375
  local MAX_SELECTION_VALUE = current_aut.length + OVERHANG
 
 
  --1) GET SELECTION RANGE  (counts from 1 to  x.99609375) (not documented right)
  local selection_start_time = current_aut.selection_start
  local selection_end_time = current_aut.selection_end
  
  --return if no proper selection is made (bug in API?? no nil when there is  no end selection)
  if selection_end_time > current_aut.length + 1 then
    return
  end
  
  --2) Add points to the start and end of the automation if they are not present
  --This makes sure that the selection will have at least the minimum required points, left and right to calculate from
  -----------------------
  --create point at start of whole automation
  if current_aut:has_point_at(1) ~= true then
   -- local scaled_value = (current_param.value * (1/current_param.value_max))
    current_aut:add_point_at(1,points[1].value)
  end
  --create point at end of whole automation
  ----------------------
  if current_aut:has_point_at((current_aut.length + OVERHANG)) ~= true then
   -- local scaled_value = (current_param.value * (1/current_param.value_max))
    current_aut:add_point_at((current_aut.length + OVERHANG) ,points[#points].value)
  end
  --refresh points table
  points = current_aut.points
  ------------------------------

  --3) are range borders on a point? If not add point/s
  ----------------------------------------------
  --selection start (add a point if not present)
  ----------------------------------------------
  local point_count = 0 
  --if no point present at selection start time 
  if current_aut:has_point_at(selection_start_time) ~= true then
    --loop through points
    for i = 1,#points do
      if points[i].time > selection_start_time then
        --get point left of selection_start_time
        point_count = i -1
        break
      end
    end
    --get the value whre the line intersects the selection start
    local start_point_value = get_automation_value_between_two_points(points[point_count],points[point_count+1],selection_start_time)
    --add a point at selection start
    current_aut:add_point_at(selection_start_time,start_point_value)
    --refresh points as one has been added
    points = current_aut.points
  end 
  ---------------
  --selection end (add a point if not present)
  ---------------
  --As the end of the selection is the start of the next selection we want to add a point just before then as a
  --`ramp point` to preserve the shape of the automation
  
  --loop to get points[] index of the end point (-1)
  local end_point_count = 0
  --loop through points backwards
  for i = #points, 1,-1 do
    if points[i].time < selection_end_time then
      end_point_count = i
      break
    end
  end
  
  --if no point is already at the end of the selection
  if current_aut:has_point_at(selection_end_time) ~= true then
    --get (calculate) the value where the line intersects the selection end
    local end_point_value = get_automation_value_between_two_points(points[end_point_count],points[end_point_count+1],selection_end_time)
    --add a point at selection end
    current_aut:add_point_at(selection_end_time,end_point_value)
    --refresh points as one has been added
    points = current_aut.points
 
    --add a ramp point just before
    --add a ramp point (same as end_point_value) just before
   --[[ if current_aut:has_point_at(selection_end_time -(1/256)) == false then 
      current_aut:add_point_at((selection_end_time -(1/256)) ,end_point_value)
      --refresh points as one has been added
      points = current_aut.points
    end--]]
 
  end  
    
    
  --else
    --add a ramp point (same as end_point_value) just before
    if current_aut:has_point_at(selection_end_time -(1/256)) == false then 
      current_aut:add_point_at((selection_end_time -(1/256)) ,points[end_point_count+1].value)
      --refresh points as one has been added
      points = current_aut.points
    end
 -- end 
  ------------------------
  ------------------------

  --4) loop through editor and copy range point by point
  ------------------------------------------------------
  --calc range length
  local range_length =  selection_end_time - selection_start_time
  --set target range values
  local target_range_start = selection_end_time 
  local target_range_end = selection_end_time + range_length
  local reduced_range = false 
  
  --clear target range
  current_aut:clear_range(target_range_start,target_range_end)
  --update points table
  points = current_aut.points
  
  
  --limit the new target range end to the maximum automation length
  if target_range_end > MAX_SELECTION_VALUE then --- (1/256) then
    target_range_end = MAX_SELECTION_VALUE --- (1/256)
    reduced_range = true
  end

  --new start value must be less than the automation length otherwise return
  --as no new range to go into
  if target_range_start >= MAX_SELECTION_VALUE then-- >= target_range_end then
    return
  end
  

  
  
  ---------------
  --loop  to copy
  ---------------
  local num_points = #points
  --loop points
  for i = 1, num_points do 
    --range selection start to end
    if (points[i].time >= selection_start_time) and 
       (points[i].time <= selection_end_time) then

      --if we reached the selection end time then break
      if points[i].time == selection_end_time  then
        break
      end
      --add new automation points shifted forward by range length
      current_aut:add_point_at((range_length + points[i].time),points[i].value, points[i].scaling) --scaling added renoise 3.2
    end
  end
  
  --update points table
  points = current_aut.points
 
  --if the range has been reduced then we need to make sure the final point in the
  --automation is at the right value.  This is where the selection is truncated
  --so either requires copying a value that is a range-length less than the final truncated position
  --or calculating the value of the automation at that same position (a range-length less than the final truncated position)
  --(i.e. MAX_SELECTION_VALUE - range_length)
  ---------------------------------------------------------------------------- 
  local previous_point = nil
  --reduced range tells us we are dealing with a truncated copy
  if reduced_range == true then
    --check if there is a point at MAX_SELECTION_VALUE - range_length
    if current_aut:has_point_at(MAX_SELECTION_VALUE - range_length) then -- + 1/256 --tested and works
      --loop to find point
      for i = 1, #points do 
        --range selection start to end
        if (points[i].time >= selection_start_time) and 
           (points[i].time <= selection_end_time) then
         --get index for the matching point
         if points[i].time == (MAX_SELECTION_VALUE - range_length) then
           previous_point = i
           break
         end
       end 
     end
     --remove last point if it exists
     if current_aut:has_point_at(MAX_SELECTION_VALUE) then 
       current_aut:remove_point_at(MAX_SELECTION_VALUE)
     end 
     --add last point with the copied value 
     current_aut:add_point_at(MAX_SELECTION_VALUE,points[previous_point].value)
     --print("copied")
   else
    --loop to find points either side of position
    for i = 1, #points do 
      --range selection start to end
      if (points[i].time >= selection_start_time) and 
         (points[i].time <= selection_end_time) then
       --is point before the target value on the curve we are trying to replicate?
       if points[i].time < (MAX_SELECTION_VALUE - range_length) then
         previous_point = i
       else--else we`ve past the point so break
         break
       end
     end 
   end 
   --remove last point if it exists
   if current_aut:has_point_at(MAX_SELECTION_VALUE) then 
     current_aut:remove_point_at(MAX_SELECTION_VALUE)
   end
   --update points table (necessary as just re-assigning pointer???)
   points = current_aut.points
   --get missing point value
   local time = (MAX_SELECTION_VALUE - range_length)
   local missing_point_value = get_automation_value_between_two_points(points[previous_point],points[previous_point+1],time)
   --add last point with the calculated value
   current_aut:add_point_at(MAX_SELECTION_VALUE,missing_point_value)
  -- print("calculated")
  end
end
  ------------------
  --update selection
  --set start to 1 first, so that boundaries don`t cross during re-assignment
  current_aut.selection_start = 1
  current_aut.selection_end = target_range_end 
  current_aut.selection_start = target_range_start 
  
  --clear unnecessary ramp points
  -------------------------------
 --[[
  for i = 1,#points - 1 do
    if points[i].time == (points[i+1].time - (1/256)) then
      if points[i].value == (points[i+1].value) then
        current_aut:remove_point_at(points[i].time)
      end
    end
  end --]]

end
----------
----------
----------
  
  
--set automation length in auto ed to match pattern ed
-----------------------------------------------------------
function set_automation_range_from_pattern_selection_range()
------------------------------------------------------------

  local song = renoise.song()
  local pat_trk = song.selected_pattern_track
  
  if song.selection_in_pattern == nil then
    renoise.app():show_status("Auto Slider".." Tool: (No Selection Present in pattern Editor)")
  end
  
  --get pattern selection start and end lines
  local start_line = song.selection_in_pattern.start_line
  local end_line = song.selection_in_pattern.end_line
  
  
  local current_param = song.selected_automation_parameter
  local current_aut = song.selected_pattern_track:find_automation(current_param)
  
  if current_aut == nil then
    renoise.app():show_status("Auto Slider".." Tool: (No Automation Is Selected)")
    return
  end
  
  
  
 -- oprint(song.selected_automation_parameter)
  
  current_aut.selection_start = song.selection_in_pattern.start_line
  current_aut.selection_end = song.selection_in_pattern.end_line + 1
  
  
end  

 --- pat_trk.automation[].selection_start, _observable
 --- pat_trk.automation[].selection_end, _observable
 --- pat_trk.automation[].selection_range[], _observable













