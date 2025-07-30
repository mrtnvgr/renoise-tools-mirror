
--add a menu item to the context menu in the parameter list  in the Automation view 
renoise.tool():add_menu_entry {
  name = "Track Automation List:Automation Cleaner",
  invoke = function() CleanAutomation(renoise.song().selected_pattern) end 
}


--add a menu item to the context menu in the Automation editor 
renoise.tool():add_menu_entry {
  name = "Track Automation:Automation Cleaner",
  invoke = function() CleanAutomation(renoise.song().selected_pattern) end 
}

renoise.tool():add_menu_entry {
  name = "Track Automation List:Automation Cleaner (all patterns)",
  invoke = function() clean_all_patterns()  end 
}


--add a menu item to the context menu in the Automation editor 
renoise.tool():add_menu_entry {
  name = "Track Automation:Automation Cleaner (all patterns)",
  invoke = function() clean_all_patterns() end 
}

----------------------------------------
function CleanAutomation(current_pattern)
  local current_pattern_track = current_pattern.tracks[renoise.song().selected_track_index]
  
  local selected_parameter = renoise.song().selected_parameter
  
  --if a parameter is selected, get its automation data
  if (selected_parameter) then
    local selected_parameters_automation = current_pattern_track:find_automation(selected_parameter)
    
    --if there is no automation data, quit  
    if (not selected_parameters_automation) then
      renoise.app():show_status("No automation points for current parameter in current pattern")
      return
    end
    
    local pts = selected_parameters_automation.points
  
    --These two arrays are necessary because the points have to be sorted by time
    local times = {} --contains only times, will later be sorted by time
    local points_table = {} --will be used to look up the value for each time point
    
    for a,b in pairs(pts) do
      print(b.time)
      points_table[b.time] = b.value
      table.insert(times, b.time)
    end
    
    --sort the array of times
    table.sort(times)

    
    --do this for all points, except the first and the last
    for i = 2, ((# times)-1)do
      local tim = times[i]
      local prevtim = times[i-1]
      local nexttim = times[i+1]
      
      --if the value of a point lies between the values of the preceding and following points, delete it.
      if (points_table[tim] >= points_table[prevtim]) and (points_table[tim] <= points_table[nexttim])then
        selected_parameters_automation:remove_point_at(tim)
      elseif (points_table[tim] <= points_table[prevtim]) and (points_table[tim] >= points_table[nexttim])then
        selected_parameters_automation:remove_point_at(tim)
      end
    end
    
    --make it smooth
    selected_parameters_automation.playmode = renoise.PatternTrackAutomation.PLAYMODE_CUBIC
  
  --if no parameter is selected, quit
  else
    renoise.app():show_status("No parameter selected in the automation editor")
    return
  end
end  


function clean_all_patterns()
  local previous_pattern = -1
  for pos, _ in renoise.song().pattern_iterator:lines_in_song(true) do
    if pos.pattern ~= previous_pattern then
      previous_pattern = pos.pattern
      CleanAutomation(renoise.song().patterns[pos.pattern])
    end
  end
end
