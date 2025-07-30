----------------------------------------------------------------------
--notifiers
----------------------------------------------------------------------


--main notifier; the tool updates every time the track selection changes
----------------------------------------------------------------------
function start()  
  renoise.song().selected_track_index_observable:add_notifier(function()match_instr_to()end)
end

--new document notifier means tool will not run until a renoise song exists (renoise app fully initialised)  
----------------------------------------------------------------------
renoise.tool().app_new_document_observable:add_notifier(function()start()end)

--Preferences to Switch the tool on and off
-------------------------------------------
local options = renoise.Document.create {
  capture_enabled = false
}
renoise.tool().preferences = options

----------------------------------------------------------------------
--Menu entry
----------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Auto-Capture From 1st Note",
  selected = function() return options.capture_enabled.value end,
  invoke = function() 
    options.capture_enabled.value = not options.capture_enabled.value 
  end
}

----------------------------------------------------------------
--Converts decimal number to it`s equivalent hex string
----------------------------------------------------------------
function num_to_hex_string(num)
 
  num = tostring(num)
  num = string.format("%X",num)  

  if #num < 2 then
    return tostring("0"..num)
  end
  
  return num --string
end

--globals
local empty_track_status_fired = nil


-----------------------------------------------------------------
--main function()
-----------------------------------------------------------------

function match_instr_to()
  
  --clear Empty Track status if present  
  if empty_track_status_fired == true then
    --reset flag
    empty_track_status_fired = false
    renoise.app():show_status("")
  end
  
  --return if tool is not enabled in the menu
  if (options.capture_enabled.value == false) then
    return
  end
  -----------------------------------------------------------------
  --Iterate over pattern and return table
  -----------------------------------------------------------------
  local inst_val_tabl = {}
  local pattern_iter = renoise.song().pattern_iterator
  local track_index = renoise.song().selected_track_index 
  local incrementer = 1

  --return if we are on master track
  if renoise.song().tracks[track_index].visible_note_columns == 0 then
    return
  end
  --continue
  local pos_holder = 0
  local position_in_sequencer = 0
  local total_patterns = #renoise.song().patterns
       
  
  for pos,line in pattern_iter:note_columns_in_track(track_index) do
    
    if pos.pattern ~= pos_holder then
      position_in_sequencer = position_in_sequencer + 1
      pos_holder = pos.pattern
      
    end
                              
    if (line.instrument_value ~= 255) then --> docs--[instrument_value, 0-254, 255==Empty]
      inst_val_tabl[incrementer] = line.instrument_value
      incrementer = incrementer + 1 --so we can capture the first note in pos 1 of table
      break
    end
  end--for

  ---------------------------------------------------------------------------
  -- Add Instrument number to line 1
  ----------------------------------------------------------------------------
  
  local inst_number = inst_val_tabl[1]-- check_for_notes_inst_num(inst_val_tabl_table)
  local temp_inst_number = inst_val_tabl[1]
  
  if inst_number == nil then 
    temp_inst_number = 255
  end
  
  if temp_inst_number < 255  then 
    local pattern_1 = renoise.song().sequencer.pattern_sequence[1]
    renoise.song().patterns[pattern_1].tracks[track_index].lines[1].note_columns[1].instrument_value = inst_number
  end
  
  -------------------------------------------------------------------
  --Sort response 
  -------------------------------------------------------------------   

  if inst_number == 255  then
    renoise.song().selected_instrument_index = 1
  elseif inst_number == nil then -- this means there are no notes found in track
    renoise.app():show_status("Autocapture Tool: (Track Is Empty, No Instrument To Capture:)")
    empty_track_status_fired = true
  else
    if #renoise.song().instruments >=  inst_number +1 then
       renoise.song().selected_instrument_index = inst_number +1
       inst_number = num_to_hex_string(inst_number)
       --renoise.app():show_status("Autocapture Tool: (Captured Instrument Number = "..inst_number..")")
    else
       --renoise.app():show_status("Autocapture Tool: (First Instrument Number is not valid!)")
    end     
  end  

end--end of main

----------------
----------------

--EXTRA SHORTCUTS
-------------------------------
--1 Add Or Go To Empty Instrument Slot
--------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`ACF` Add Or Go To Empty Instrument Slot", 
  invoke = function()next_empty_instrument_slot() end  
}

--2 Add Or Go To Empty Track
--------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`ACF` Go To First Empty Track", 
  invoke = function()next_empty_track() end  
}

--3 Both Empty Instrument and Empty Track
--------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`ACF` Go To First Empty Track and Instrument", 
  invoke = function()
    next_empty_instrument_slot()
    next_empty_track()
    renoise.app():show_status("Empty Track And Instrument, Selected ")  
   end  
}
---------------------------------------------------------------
--finds the first empty instrument slot and selects it, if no empty slots one is created at the end of the list
---------------------------------------------------------------
function next_empty_instrument_slot()

  local song = renoise.song()
 
  for i = 1,#song.instruments do
    if song.instruments[i].name == "" then
      song.selected_instrument_index = (i)
      renoise.app():show_status("First Empty Instrument Slot Selected")
      return
    end
  end

  --loop was not stopped so need to add empty slot at end if not already the end empty slot
  if song.selected_instrument.name ~= "" then  
    renoise.song():insert_instrument_at(#song.instruments + 1)
    song.selected_instrument_index = #song.instruments
    renoise.app():show_status("New Empty Instrument Added ")
  end
end


---------------------------------------------------------------
--finds the first empty instrument slot and selects it, if no empty track, one is created at the end
--and named "NEW TRACK"
---------------------------------------------------------------
function next_empty_track()

  local song = renoise.song()
  local mst_index

  --loop through all pattern tracks
  for i = 1,#song.tracks do
    --get the master track index if we get that far
    if song.tracks[i].type == renoise.Track.TRACK_TYPE_MASTER then
      mst_index = i
      break
    end
    
    --if we find an empty on check the rest of the tyrack
    if (song.selected_pattern.tracks[i].is_empty) and (song.tracks[i].type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      
      --loop through song to see if empty
      for j = 1, #song.patterns do
        if not song.patterns[j].tracks[i].is_empty then
          break --data found somewhere so continue to next track
        end
        -- if we are in the last pattern and no notes were found then select this track and return
        --otherwise outer loop can continue
        if j == #song.patterns then
           song.selected_track_index = (i)
           renoise.app():show_status("Empty Track Selected")
           return
        end
      end
    end
  end
  
  --no empty track found so add one
  song:insert_track_at(mst_index)
  song.tracks[mst_index].name = "NEW TRACK"
  song.selected_track_index = (mst_index)
  renoise.app():show_status("No Empty Tracks In This Song, NEW TRACK ADDED")

end





--Auto insert instrument 
----------------------------------------------------------------------
-- renoise.tool():add_keybinding {
--  name = "Global:Tools:Insert instrument no. to pattern",
 -- invoke = function() insert_instrument() end
--}

