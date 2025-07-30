store_selected_automation_parameter = nil
store_line_no = nil

function standard_rotary(val)
-----------------------------
   --------------------------------------------------------------------------------------------
   --local fn removes the timer that repeatedly calls this function when latch mode is enabled
   --------------------------------------------------------------------------------------------
   local function remove_latch_timer()
     if renoise.tool():has_timer(standard_rotary) == true then
       renoise.tool():remove_timer(standard_rotary)
       --reset flags
       store_selected_automation_parameter = nil
       store_line_no = nil
     -- if renoise.tool():has_timer(standard_rotary) == false then  
      -- end
     end
   end
   -----------------------------------

  local song = renoise.song()
  
  local value =  val
  
  --remove timer and return if gui closes
  if vb == nil then
    remove_latch_timer()
    return
  end
  --no value passed to this function so get from viewbuilder
  if val == nil then
    value = vb.views["auto slider"].value
  end
  
  --bypassed by another function
  if bypass_slider == true then
    return
  end
   
  --reset the green confirmation of grabbed plugin parameter. once we start automating the grabbed parameter here
  if vb.views["grab param button"].color[1] == 0x20 then --green 
    vb.views["grab param button"].color = COLOR_GREY
  end
  --show the automation lane
  if (renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS) and
     (view_auto_cbox_enabled == true)  then
    renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
  end
  --bypass timer function           
  bypass_timer = true
   
  local song = renoise.song()
  local track = song.selected_track_index
  local device = song.selected_track_device
   
  if song.selected_automation_parameter == nil then
    status("No Parameter Selected In Automation List")
    --reset bypass timer flag
    bypass_timer = false 
    return
  end
   
  local automation = song.selected_pattern_track:find_automation(song.selected_automation_parameter) 
  local selected_parameter_name = song.selected_automation_parameter.name
   
  --initialise envelope if it doesn`t exist
  if automation == nil then
    if song.selected_automation_parameter.is_automatable then
      automation = song.selected_pattern_track:create_automation(song.selected_automation_parameter)
    end
  end
   
  if selected_parameter_name == nil then
     status("No Parameter Selected In Automation List")
    return
  else --**** Write to automation *****
                
    --get line_index
    local line = song.selected_line_index 
    --*Lock Mode* one point controls whole envelope (as an unautomated slider does)
    if lock_mode == "Single Point Envelope" then
      automation:clear()
      automation:add_point_at(line,value)
    else --** normal automation **
       
      --[[
      local points_per_line = 12
      local ticks = (256/points_per_line)
      ticks = ticks/256
      --]]
   
       --TODO Sub line automation
       
       --as sometimes running on a timer amke sure only adding to new lines each time
       --so as not to create too many undo points
       --if store_line_no == nil then
       --  store_line_no = line
      -- elseif store_line_no ~= line then
        
         if automation:has_point_at(line) then
           automation:remove_point_at(line)
           automation:clear_range(line, (line+ 1))
         end
          automation:add_point_at(line,value)
          automation:add_point_at((line +1),value)
         end
        -- store_line_no = line
    -- end
   end
   
  
  
   
   -----------------------------------------------
   --if latch button is GREY (i.e. disabled) then remove timer
   if vb.views["latch_mode"].color[1] == COLOR_GREY_FLAG then 
     remove_latch_timer()
      --main timer flag 
     bypass_timer = false 
     return
   end
   
   --pause (orange) when transport stops
   if (song.transport.playing == false) and
      vb.views["latch_mode"].color[1] == COLOR_RED_FLAG then
      --change to orange (paused)
      vb.views["latch_mode"].color = COLOR_ORANGE
      remove_latch_timer()
   --set back to (red) active when transport plays (also means rotary is being used)
   elseif (song.transport.playing == true) then
     vb.views["latch_mode"].color = COLOR_RED    
   end
       
   --check if the selected parameter has changed from when the function was called
   --if it does change then remove timer and change latch mode to orange (paused)
   if store_selected_automation_parameter == nil then
     store_selected_automation_parameter = song.selected_automation_parameter
   elseif rawequal(store_selected_automation_parameter,song.selected_automation_parameter) == false then
     remove_latch_timer()
     vb.views["latch_mode"].color = COLOR_ORANGE  
   end

   
  --main timer flag 
  bypass_timer = false            
end
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
