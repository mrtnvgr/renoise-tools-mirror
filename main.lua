
--Menus
-------
renoise.tool():add_menu_entry {
  name = "Instrument Box:Convert Notes in:Track in Pattern",
  invoke = function() change_pattern_track() end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Convert Notes in:Track",
  invoke = function() change_whole_track() end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Convert Notes in:Selection",
  invoke = function() change_selection_in_pattern_track() end
}

--Key Bindings
---------------
renoise.tool():add_keybinding {
  name = "Global:Tools:Convert (Track in Pattern) Instruments to Currently Selected",
  invoke = function() change_pattern_track() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Convert (Whole Track) Instruments to Currently Selected",
  invoke = function() change_whole_track() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Convert (Selection in Pattern) Instruments to Currently Selected",
  invoke = function() change_selection_in_pattern_track() end
}


--1) changes all instrument values in the selected Pattern Track in renoise
-------------------------------
function change_pattern_track()
-------------------------------
  --song object values/properties
  local song = renoise.song()
  local pattern_iter = song.pattern_iterator
  local track_index = song.selected_track_index
  local pattern_index = song.selected_pattern_index
  local inst_number = song.selected_instrument_index
  
  --Zero is/can only be only returned when send/ master selected
  if song.tracks[track_index].visible_note_columns == 0 then
    return
  end
   
  --iterate: over "track in pattern" and change instrument values of all notes 
  for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do
    --change all notes
    if (line.note_string ~= "---") and (line.note_string ~= "OFF") then
      line.instrument_value = (inst_number - 1)
    end
  end
  --update status                  
  renoise.app():show_status("Convert Inst. no. Tool: (Instruments Changed in \"Track in Pattern\")")   
end 


--2) Whole track
-----------------------------
function change_whole_track()
-----------------------------
  --song object values/properties
  local song = renoise.song()
  local pattern_iter = song.pattern_iterator
  local track_index = song.selected_track_index
  local inst_number = song.selected_instrument_index
  
  --Zero is/can only be only returned when send/ master selected
  if song.tracks[track_index].visible_note_columns == 0 then
    return
  end
   
  --iterate over whole "track" and change instrument values of all notes 
  for pos,line in pattern_iter:note_columns_in_track(track_index) do
     --change all notes
    if (line.note_string ~= "---") and (line.note_string ~= "OFF") then
      line.instrument_value = (inst_number - 1)
    end
  end
  --update status                   
  renoise.app():show_status("Convert Inst. no. Tool: (Instruments Changed in \"Track\")")    
end


--3) Pattern Selection
--------------------------------------------
function change_selection_in_pattern_track()
--------------------------------------------
  --song object values/properties
  local song = renoise.song()
  local pattern_iter = song.pattern_iterator
  local track_index = song.selected_track_index
  local pattern_index = song.selected_pattern_index
  local inst_number = song.selected_instrument_index
  
  --Zero is returned when send/ master selected
  if song.tracks[track_index].visible_note_columns == 0 then
    return
  end
   
  --iterate over "Pattern" and change instrument values of all notes 
  for pos,line in pattern_iter:note_columns_in_pattern(pattern_index,track_index) do
    --filter selected only  
    if line.is_selected then --only selection
      --change all notes
      if (line.note_string ~= "---") and (line.note_string ~= "OFF") then
        line.instrument_value = (inst_number - 1)
      end
    end  
  end
  --status                   
  renoise.app():show_status("Convert Inst. no. Tool: (Instruments Changed in \"Selection\")")    
end









