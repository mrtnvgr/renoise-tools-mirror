------------------------------------------
--Set up Preferences file
------------------------------------------
--create xml
local options = renoise.Document.create {
  capture_enabled = false,
  include_fx_columns = true,
  only_sync_selected_group = false
}
 --assign options-object to .preferences so renoise knows to load and update it with the tool
renoise.tool().preferences = options
------------------------------------------
------------------------------------------

--the flag variable
local refresh_tool = false

--the flag function
--pattern changed flag
local function line_has_changed()
  refresh_tool = true
end

----------------------------------------
-----------------------------------------
--Menu Entries and keybindings
-----------------------------------------  
--add a preference menu entry: Auto sync
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Auto Sync All Notes In (*) Groups Enabled",
  selected = function() return options.capture_enabled.value end,
  invoke = function()options.capture_enabled.value = not options.capture_enabled.value
        --When tool installed for the very first time and no new document has been fired make sure notifier is added
      if not renoise.song().patterns[renoise.song().selected_pattern_index]:has_line_notifier(line_has_changed) then
        renoise.song().patterns[renoise.song().selected_pattern_index]:add_line_notifier(line_has_changed)
      end
   end
}
--add a preference menu entry: sync fx columns
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Sync Fx Columns Enabled",
  selected = function() return options.include_fx_columns.value end,
  invoke = function()options.include_fx_columns.value = not options.include_fx_columns.value
   end
}

--add a preference menu entry: only sync selected track (faster but can miss cut and paste updates)
--on unselected tracks
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Only Sync Selected Group Enabled",
  selected = function() return options.only_sync_selected_group.value end,
  invoke = function()options.only_sync_selected_group.value = not options.only_sync_selected_group.value
   end
}


------------------------------------------

--Kmenu collapse all synced tracks
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Collapse All Synced Tracks",
  invoke = function()collapse_all_synced_tracks()
  end  
}
--Key collapse all synced tracks
renoise.tool():add_keybinding {
  name = "Global:Tools:Collapse All Synced Tracks",
  invoke = function()collapse_all_synced_tracks()
  end  
}
--Key sync whole group in song
renoise.tool():add_keybinding {
  name = "Global:Tools:Sync All Notes In Group",
  invoke = function()all_in_group_in_song(renoise.song().selected_track_index,false)
  end  
}
--menu sync whole group in song
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Sync All Notes In Group",
  invoke = function() all_in_group_in_song(renoise.song().selected_track_index,false)
  end
}
--menu create synced track
renoise.tool():add_menu_entry {
  name = "Instrument Box:Create Synced Track",
  invoke = function() create_synced_track()
  end
}
--keybind create synced track
renoise.tool():add_keybinding {
  name = "Global:Tools:Create Synced Track",
  invoke = function()create_synced_track()
  end  
}
--key Alternative Undo
renoise.tool():add_keybinding {
  name = "Global:Tools:Sync All Notes, Alternative Undo",
  invoke = function()undo_without_notifier()
  end  
} 

----------------------------------------------------------
--copy the current pattern_track to the next pattern_track
----------------------------------------------------------

function copy_pattern_track_to_next_track(selected_track, selected_pattern)
  
  --pattern_track objects for copying
  local current_pat_track = renoise.song().patterns[selected_pattern].tracks[selected_track]
  local next_pat_track = renoise.song().patterns[selected_pattern].tracks[selected_track + 1]
  local pattern_lines = renoise.song().patterns[selected_pattern].number_of_lines
  
  --the API "copy_from" method copys all pattern data, we want to change instrument afterwards.
  local inst_holder
  local first_song_pattern = renoise.song().sequencer.pattern_sequence[1]
  
  --get first instrument number from  line[1].note_column[1] in target track (for retaining the instrument number).
  --when a sync group is set up the target instrument will be already placed in first line[1].note_column[1] of target track.
  if renoise.song().tracks[selected_track+1].type == 1 then --(1 is a sequencer track)
    inst_holder = renoise.song().patterns[first_song_pattern].tracks[selected_track+1]:line(1).note_columns[1].instrument_value
  else 
    inst_holder = nil -- set to nil if a group/send/master track.type
  end 
 
  --do copy/pasting
  if renoise.song().tracks[selected_track + 1].type == 1 then -- 1 is a SEQUENCER TRACK
   
    if (options.include_fx_columns.value) then --API version copies note and fx cols
      next_pat_track:copy_from(current_pat_track)
      
    else -- copy note columns only  
      local lines =  renoise.song().patterns[selected_pattern].tracks[selected_track].lines
      local lines2 =  renoise.song().patterns[selected_pattern].tracks[selected_track + 1].lines
  
      for i = 1,pattern_lines do 
        for column = 1,12 do
          lines2[i].note_columns[column]:copy_from(lines[i].note_columns[column])
        end
      end     
    end
  end
   --reset the first inst number ready for the "change_instrument_numbers()" function to convert all notes to target instrument.
  if renoise.song().tracks[selected_track+1].type == 1 then
    renoise.song().patterns[first_song_pattern].tracks[selected_track+1]:line(1).note_columns[1].instrument_value = inst_holder
  end
end --function


-- (code taken from auto capture script)
-----------------------------------------------------
-- gets instrument number from notes on target track
-----------------------------------------------------
function match_instr_to(track_index)

--Iterate over track to get instrument index value
--------------------------------------------------
  track_index = track_index + 1 --index incremented to get the instrument number of the next(target) track
  local inst_val = nil
  local pattern_iter = renoise.song().pattern_iterator
  
  if renoise.song().tracks[track_index].visible_note_columns == 0 then
    return -- zero means send/master/group selected so return early.      
  end
  --iterate over whole track
  for pos,line in pattern_iter:note_columns_in_track(track_index) do      
    -- get instrument value of first note found                            
    if (line.instrument_value ~= 255 and true) then --> docs--[instrument_value, 0-254, 255==Empty]
      inst_val = line.instrument_value
      break
    end
  end

--Sort response 
---------------  
  if inst_val then
    return inst_val--returns instrument number
  else
    return renoise.song().selected_instrument_index - 1
  end
end --function


---------------------------------------------------------------------------
--iterate over newly pasted pattern_track and change the instrument numbers
---------------------------------------------------------------------------
function change_instrument_numbers(instrument_num,track_index,pattern_index)

  local pattern_iter = renoise.song().pattern_iterator
  track_index = track_index + 1 
 -- local pattern_index = renoise.song().selected_pattern_index
  local inst_number = instrument_num
 -- print(inst_number)
  
  -- Zero is returned when send/ master selected
  if  renoise.song().tracks[track_index].visible_note_columns == 0 then
    return
  end
   
  --iterate:
  --over "track in pattern" and change instrument values of all notes 
  for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do
    
    if line.instrument_value ~= 255 then
      line.instrument_value = (inst_number)
    end
  end                       
end --function

--------------------------
--main
--------------------------
function main()
  local selected_track = renoise.song().selected_track_index
  local target_instrument_num = match_instr_to(selected_track)
  copy_pattern_track_to_next_track(selected_track)
  change_instrument_numbers(target_instrument_num)
end--function

---------------------------------------------
--returns how many parent groups a track has
---------------------------------------------
function num__parent_groups(track)
  --make sure track is valid
  if track < 1 then
    return nil
  end
  --counter is assigned how many groups deep we are
  local group_ob = renoise.song().tracks[track].group_parent
 
  local counter = 0
  while group_ob do
    counter = counter + 1
    group_ob = group_ob.group_parent
  end
  return counter 

end --function

-------------------------------------------------------
--syncs all groups marked with (*) in the song
-------------------------------------------------------
function all_in_group_in_song(selected_track,single_pat)
  
  local song = renoise.song()
     
  --return early if selected track is not in a group
  if song.tracks[selected_track].group_parent == nil then
    return
  end
 
  local valid_group_depth = num__parent_groups(selected_track)
  local selected_pattern = song.selected_pattern_index
  local last_track_in_group_index = selected_track
  local first_track_in_group_index = selected_track
  local SEQ = renoise.Track.TRACK_TYPE_SEQUENCER
  
  -- get number of tracks in group/ first and last track indexes
  -- scan left
  while num__parent_groups(selected_track) == valid_group_depth  do
    if selected_track == 1 then
      first_track_in_group_index = selected_track
      break
    end
    if song.tracks[selected_track].type == 1 then
      first_track_in_group_index = selected_track
    end 
    selected_track  = selected_track  - 1
  end
   selected_track = first_track_in_group_index
  --now scan right
  while num__parent_groups(selected_track) == valid_group_depth do
    if song.tracks[selected_track].type == SEQ then
     last_track_in_group_index = selected_track
    end 
    selected_track  = selected_track  + 1
  end
  
  --return early if only one track
  if first_track_in_group_index == last_track_in_group_index then
    return
  end
  
  
  local start_pat = 1
  local end_pat = #song.patterns

  if single_pat then --set both to current pattern
    start_pat = song.selected_pattern_index
    end_pat = song.selected_pattern_index
  end 
    
  --Copying loop for all tracks in group
  for selected_pattern = start_pat,end_pat do
    
    for i = first_track_in_group_index, last_track_in_group_index do      
      --get target instrument number
      local target_instrument_num = match_instr_to(i,selected_pattern )
      --copy
      copy_pattern_track_to_next_track(i,selected_pattern)
      --then restore the target instrument number
      change_instrument_numbers(target_instrument_num,i,selected_pattern)
      --set track width to first(source) track width and show same vol/pan/delay cols
      if (selected_pattern == start_pat ) and (i ~= first_track_in_group_index) then
        song.tracks[i].visible_note_columns = song.tracks[first_track_in_group_index].visible_note_columns
        song.tracks[i].volume_column_visible = song.tracks[first_track_in_group_index].volume_column_visible
        song.tracks[i].panning_column_visible = song.tracks[first_track_in_group_index].panning_column_visible
        song.tracks[i].delay_column_visible = song.tracks[first_track_in_group_index].delay_column_visible
      end   
    end
  end
end--function

-----------------------------------------------------------
--Scans Pattern for Group names with "*" and syncs them
-----------------------------------------------------------

function auto_sync()
  
  local selected_track_index = renoise.song().selected_track_index
  local selected_track = renoise.song().selected_track
     
  if options.only_sync_selected_group.value then --only sync the group containing the cursor
    
     --return early if selected track not in group 
    if  selected_track.group_parent == nil then
      return
    end
    --check for * in parent name
    if string.find(selected_track.group_parent.name, "*") then 
      all_in_group_in_song(selected_track_index,true)--do syncing
    end
  
  else --sync all groups whether the cursor is in that group or not  
    local rns_tracks = renoise.song().tracks
    local marked_group_names = {}
    
    --get groups marked for syncing
    for t = 1, #rns_tracks do
      if string.find(rns_tracks[t].name, "*") then
        table.insert(marked_group_names,t)
      end
    end
    
    for i = 1, #marked_group_names do
      all_in_group_in_song(marked_group_names[i]-1,true) 
    end   
  end
end--function

------------------------------------------------------------------------------------------- 
--Alternative Undo (Ctrl X) -- This version bypasses line notifier so it is not triggered on undo. 
-------------------------------------------------------------------------------------------
function undo_without_notifier()
 
  local pat_index = renoise.song().selected_pattern_index
  --remove line notifier
  if renoise.song().patterns[pat_index]:has_line_notifier(line_has_changed) then
    renoise.song().patterns[pat_index]:remove_line_notifier(line_has_changed)
  end
  renoise.song():undo() --Global Undo
  --re-initiate line notifier
  if not renoise.song().patterns[pat_index]:has_line_notifier(line_has_changed) then
    renoise.song().patterns[pat_index]:add_line_notifier(line_has_changed)
  end
end--function

------------------------------------------------------------------------------------------------------
--Add a new track (and group if not already there) and add the currently selected instrument number to
--the first pattern line.  First pattern line is `read` on track copy to define instrument for
--target track
------------------------------------------------------------------------------------------------------
function create_synced_track()
  
  local song = renoise.song()
 
  --add current track and a new track to a group 
  local instr = song.selected_instrument_index
  local track = song.selected_track_index
  local first_song_pattern = song.sequencer.pattern_sequence[1]
  
  --insert new track
  song:insert_track_at(track+1)
  --add current instrument number to first cell
  song.patterns[first_song_pattern].tracks[track+1]:line(1).note_columns[1].instrument_value = instr - 1
  --if already a parent group, check if it`s a sync track 
  if song.tracks[track+1].group_parent then
    if string.find(song.tracks[track+1].group_parent.name, "*") then
      all_in_group_in_song(track+1,false)
      return --already in sync group, so return early
    end
  end
  
  --add group track 
  song:add_track_to_group(track, track+1)
  
  --add * to name of group track
  song.tracks[track+2].name = "*"..renoise.song().tracks[track+2].name
  all_in_group_in_song(track+1,false)

end --function

---------------------------------
--Collapse all synced (*) tracks
---------------------------------
function collapse_all_synced_tracks()
local  song = renoise.song()

  for track = 1,#song.tracks do
    if song.tracks[track].group_parent ~= nil then
      if string.find(song.tracks[track].group_parent.name, "*") then
        --check left to see if first track in group
        --if it is then don`t collapse it
        if num__parent_groups(track) == num__parent_groups(track-1) then
          song.tracks[track].collapsed = true
        end
      end
    end 
  end
end--function
 

-------------------------------------------------------------
--adds `pattern line changed` notifier for refresh tool flag 
-------------------------------------------------------------
local prev_pat_index = nil

function change_notifying_pattern_index()
    
    --notify on pattern change
  if not renoise.song().selected_pattern_index_observable:has_notifier(change_notifying_pattern_index) then
     renoise.song().selected_pattern_index_observable:add_notifier(change_notifying_pattern_index)
  end
  
  --initial pattern pos variables
  local new_pat_index = renoise.song().selected_pattern_index
  if not prev_pat_index == nil then
   
  --remove previous line notifier
    if renoise.song().patterns[prev_pat_index]:has_line_notifier(line_has_changed) then
      renoise.song().patterns[prev_pat_index]:remove_line_notifier(line_has_changed)
    end
  end
  
  --add new line notifier
  if not renoise.song().patterns[new_pat_index]:has_line_notifier(line_has_changed) then
    renoise.song().patterns[new_pat_index]:add_line_notifier(line_has_changed)
  end
  --store pat index for removal on next run
  prev_pat_index = new_pat_index

end--function

------------------
--timer function
------------------
local function timer_calls_this()
  if (options.capture_enabled.value) then
    if refresh_tool then
      auto_sync()--< Main Tool Function - All Group Tracks marked with "*" affected
    end
    refresh_tool = false
  end
end--function

-----------------

-------------------------------------------------------
--Notifiers Called on first run (i.e. outside functions)
--so placed at end of tool so all up-values can be seen
--------------------------------------------------------
--------------------------------------------------------
--add timer
if not renoise.tool():has_timer(timer_calls_this) then 
  renoise.tool():add_timer(timer_calls_this,300)
end

--add document notifier
--changing the document(song) updates line notifier to new pattern, in new song
if not renoise.tool().app_new_document_observable:has_notifier(change_notifying_pattern_index) then 
  renoise.tool().app_new_document_observable:add_notifier(change_notifying_pattern_index)
end


