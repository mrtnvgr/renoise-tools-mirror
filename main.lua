renoise.tool():add_keybinding {
  name = "Global:Tools:Note Properties",
  invoke = function()main()end
  
}


-------------
--global
-------------
local updating_gui = false
local not_called_by_nudge = true

--GUI
local my_dialog = nil

--custom status message --prefixes tool name and adds brackets  
local function status(message)
  renoise.app():show_status("Note Properties Tool: ("..message..")")
end
---------------------------------------------------------
--create a table that will hold all possible note strings
---------------------------------------------------------
--(pre)table to populate note table with
local note_strings = {
    "C-", "C#", "D-", "D#", "E-", "F-", 
    "F#", "G-", "G#", "A-", "A#", "B-"
   }
--create and populate note_table containing all the note strings available in renoise   
local note_table = {"---"}
local counter = 1 --start after "---" empty note

for octave = 1,10 do
  for notes = 1,12 do
    note_table[counter] = note_strings[notes]..tostring(octave-1)
    counter = counter + 1
  end
end
--add NOTE-OFF and empty note values to osition 121 and 122 in table
table.insert(note_table,"OFF")
table.insert(note_table,"---")


--create a reversed note table for the dropdown
local note_table_reversed = {}
for i = #note_table,1,-1 do
  table.insert(note_table_reversed,note_table[i])
end

function convert_note_value_forward_reverse_table(value)
  
  --1
  if value == 1 then 
    value = 122
  return value
end
end
--------------------------------------
-------------------------------------- 


--------------------------------------
--sets edit pos (no bounds checking)
--------------------------------------
local function set_edit_pos(pattern,track,line,column)
  
  local song = renoise.song()
  local pos = song.transport.edit_pos
  pos.line = line
  pos.sequence = pattern
  --update pos object
  song.transport.edit_pos = pos  
  --set the track
  song.selected_track_index = track
  --set the column --check new note column is visible and show it if not
  if song.tracks[track].visible_note_columns < column then
    song.tracks[track].visible_note_columns = column
  end
  --set the column
  song.selected_note_column_index = column
end


-------------------------------------------------------------------------------------------
--Main
-------------------------------------------------------------------------------------------
function main()



--turns keybinding into toggle for GUI
if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
  my_dialog:close()
  return
end



local song = renoise.song()

--create a table holding string for each row number
local pat_length = song.selected_pattern.number_of_lines
local pat_length_tab = {}
for i = 1,pat_length do
  pat_length_tab[i] = tostring(i-1)
  --add leading zeros for sub 10 values
  if #pat_length_tab[i] < 2 then
    pat_length_tab[i] = "0"..pat_length_tab[i]
  end  
end

local function get_current_note()
  local song = renoise.song()
  
  --are we in a note column
  if not song.selected_note_column then
    return
  end
  
--get current note properties
  local cur_line = song.selected_line_index
  local cur_track = song.selected_track_index
  local cur_col = song.selected_note_column_index
  local cur_pattern = song.selected_pattern_index
  
  return song.patterns[cur_pattern].tracks[cur_track].lines[cur_line]:note_column(cur_col) 
end

--get current note properties
local cur_line = song.selected_line_index
local cur_track = song.selected_track_index
local cur_col = song.selected_note_column_index
local cur_pattern = song.selected_pattern_index

local cur_note = get_current_note()


------------------
--local functions
------------------

-- pattern editor
local function focus_pattern_ed()
  renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
  renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
end


-------------------------------------------------------------------------------------------


local current_track = renoise.song().selected_track_index 
local current_track_name =  renoise.song().tracks[current_track].name 
local vb = renoise.ViewBuilder()


--------------------------------------------------
--Converts pattern volume data to GUI rotary range
--------------------------------------------------
local function volume_to_rotary(cur_note)
  --return early if on fx track
  if cur_note == nil then 
    return
  end
  --bounds checking as other non volume commands can be in the column
  if cur_note.volume_value > 255 then
    return 127 --maximum (volume default) 
  end
  --range of rotary is 127 but renoise returns 255 when volume
  --column is empty so we need to change it back to 127 to fit the rotary range
  if cur_note.volume_value == 255 then
    return 127
  else
    return cur_note.volume_value
  end
end
-----------------------------------------------
--Converts pattern pan data to GUI rotary range
-----------------------------------------------
local function panning_to_rotary(cur_note)
  --return early if on fx track
  if cur_note == nil then 
    return
  end
 
  --bounds checking as other non panning commands can be in the column
  if cur_note.panning_value > 255 then
    return
    127/2
  end
  --empty column so set rotary at centre pan
  if cur_note.panning_value == 255 then
    return 127/2
  else
    return cur_note.panning_value
  end
end



 ----------------------------------------- --------------------------------------------
 --update tools GUI values with currently selected note values vol pan delay pitch etc.
 --------------------------------------------------------------------------------------
local function timer_calls_this()

  --see if GUI has closed, if it has then remove timer
  if not (my_dialog and my_dialog.visible) then 
    --remove this timer
    if renoise.tool():has_timer(timer_calls_this) then 
      renoise.tool():remove_timer(timer_calls_this)
      return
    end
  end  

  local song = renoise.song()
  
  --get current note properties
  local cur_line_new = song.selected_line_index
  local cur_track_new = song.selected_track_index
  local cur_col_new = song.selected_note_column_index
  local cur_pattern_new = song.selected_pattern_index
  
  --are we in a note column? if not return
  if not song.selected_note_column then
    return
  end
  
  local cur_note_new = song.patterns[cur_pattern_new].tracks[cur_track_new].lines[cur_line_new]:note_column(cur_col_new) 
  -- has selected note changed?
  -- return early if line and column has not changed and function has not been called by delay "nudge" buttons notifiers
  if (cur_line == cur_line_new) and (cur_col == cur_col_new) and (cur_track == cur_track_new) and not_called_by_nudge then
    return
  end
  
  --set flag that GUI is updating
  updating_gui = true
  
  --set current line (from main) to current_line new 
  cur_line = cur_line_new
      
  --set note --as the valuebox is in reverse order we minus vale from #note_table_reversed which is 122
  vb.views["note_name"].value = (#note_table_reversed - cur_note_new.note_value )
  --set velocity
  vb.views["vol"].value = volume_to_rotary(cur_note_new)
  --set pan
  vb.views["pan"].value = panning_to_rotary(cur_note_new)
  --set delay
  vb.views["dly"].value = cur_note_new.delay_value   

  --reset flags
  updating_gui = false
  not_called_by_nudge = true
end
----------------------------------------------------------
--add timer to update the tool GUI every (50) milliseconds
----------------------------------------------------------
if not renoise.tool():has_timer(timer_calls_this) then 
  renoise.tool():add_timer(timer_calls_this,50)
end

--get initial note value for GUI
local function get_initial_note_value(cur_note) 
 if cur_note ~= nil then
   return (cur_note.note_value+1)
 else
   return 1
 end
end

--get initial delay value for GUI
local function get_initial_delay_value()
   if cur_note ~= nil then
   return (cur_note.delay_value)
 else
   return 1
 end
end

-------------------------------------------------------------------------------------------
--GUI
-------------------------------------------------------------------------------------------
local dialog_content = 
  vb:vertical_aligner {
    margin = 8,
    mode = "center",
    
    vb:vertical_aligner {
     -------------------------
     --row 1 - text
     vb:row{
       vb:text{
         text = "  Pitch      Nudge         ",-- Type",  
         font = "bold",
       }
     },
     -------------------------
     --row 2 - pitch controls      
     vb:row{ 
       style = "group",
       margin = 4,
        
        --note pitch
       vb:popup {
         id = "note_name",
         width = 50,
         items = note_table_reversed,
         value = (122 - (get_initial_note_value(cur_note) - 1)) , --value inverted and adjusted as note_table reversed
         notifier = function(value)
                      --only run this if user has changed the value and not the timer function
                      if updating_gui then
                        return
                      end
                      value = 122 - value 
                      local cur_note = get_current_note()
                      --Max is 119 B-9
                        cur_note.note_value = (value )
                    end, 

       },
       --decrease pitch by 1 ST
       vb:button{
         text = "<",
         notifier = function()                    
                      local cur_note = get_current_note()
                      --Max is 119 B-9
                      if cur_note.note_value > 1 then
                        cur_note.note_value = (cur_note.note_value - 1)
                        --update GUI
                        vb.views["note_name"].value =  (122 - (get_initial_note_value(cur_note) - 1))-- --value inverted and adjusted as note_table reversed
                      else
                        status("Lowest Possible Note")
                      end
                    end,
       },
       --increase pitch by 1ST
       vb:button{
         text = ">",
         notifier = function()                    
                      local cur_note = get_current_note()
                      --Max is 119 B-9
                      if cur_note.note_value ~= 119  then
                        cur_note.note_value = (cur_note.note_value + 1)
                        --update GUI
                        vb.views["note_name"].value =  (122 - (get_initial_note_value(cur_note) - 1))--value inverted and adjusted as note_table reversed
                      else
                        status("Highest Possible Note")
                      end
                    end,         
       },
       
       vb:text{
         text = "                         ", --spacer empty text
       },
       --type current sample
     --[[  vb:textfield{
         width = 50,
         id = "textfield",
         value = note_table[get_initial_note_value(cur_note)],
         notifier = function(text_input)
                
                local cur_note = get_current_note()
                --is a note value provided by the user
                local note_provided = true
              
                --create a table to hold all characters from string
                local final_text = ""
                --set to upper case
                text_input = string.upper(text_input)
                 
                for i = 1,#text_input do
                  
                  if string.find(text_input,"A") then
                    final_text = "A"
                    break
                  elseif string.find(text_input,"B") then
                    final_text = "B"
                    break
                  elseif string.find(text_input,"C") then
                    final_text = "C"
                    break
                  elseif string.find(text_input,"D") then
                    final_text = "D"
                    break
                  elseif string.find(text_input,"E") then
                    final_text = "E"
                    break
                  elseif string.find(text_input,"F") then
                    final_text = "F"
                    break
                  elseif string.find(text_input,"G") then
                    final_text = "G"
                    break
                  else --use current note value as none provided by user
                    --take note string aand get first character (1,1)
                    --i.e. get the note name
                    final_text = string.sub(cur_note.note_string,1,1)
                    note_provided = false
                  end
                end
                
                local sharp = false
                --if no note has been provided by the user, we assume thay are just
                --trying to change the octave of the current note; we need to check if the
                --current note is sharp or not
                if not note_provided then
                  --if current note is a sharp then add it
                  if string.sub(cur_note.note_string,2,2) == "#" then
                    final_text = final_text.."#"
                    sharp = true
                  end
                else
                  --add sharp # if present in the user text input
                  for i = 1,#text_input do
                    if string.find(text_input,"#") then
                      final_text = final_text.."#"
                      sharp = true
                      break
                    end
                  end
                end
                
                -- if no sharp add hyphen
                if sharp == false then
                  final_text = final_text.."-"
                end
                
                --add octave
                for i = 1,#text_input do
                  if string.find(text_input,"0") then
                    final_text = final_text.."0"
                    break
                  elseif string.find(text_input,"1") then
                    final_text = final_text.."1"
                    break
                  elseif string.find(text_input,"2") then
                    final_text = final_text.."2"
                    break
                  elseif string.find(text_input,"3") then
                    final_text = final_text.."3"
                    break
                  elseif string.find(text_input,"4") then
                    final_text = final_text.."4"
                    break
                  elseif string.find(text_input,"5") then
                    final_text = final_text.."5"
                    break
                  elseif string.find(text_input,"6") then
                    final_text = final_text.."6"
                    break
                  elseif string.find(text_input,"7") then
                    final_text = final_text.."7"
                    break
                  elseif string.find(text_input,"8") then
                    final_text = final_text.."8"
                    break
                  elseif string.find(text_input,"9") then
                    final_text = final_text.."9"
                    break
                  else --use current note value
                    --get sub string starting at 3 (the octave in a renoise note)
                    local octave = string.sub(cur_note.note_string,3)
                    final_text = final_text..octave
                    break
                  end
                end
               
                --find the string in note_table, which contains all note strings
                for i = 1,#note_table do
                  if final_text == note_table[i] then
                    --change the current note
                    get_current_note().note_value = (i - 1)
                    --update  GUI elements
                    vb.views["note_name"].value = (122 - (get_initial_note_value(cur_note) - 1))-- --value inverted and adjusted as note_table reversed
                    return
                  end
                end 
              end,                

       },--]]
     },
     ----------------------
     --row 3 text 
     vb:row{
      vb:horizontal_aligner{
      -- mode = "distribute",
       width = 170,
         vb:text{
           text = "  Vel      ",
           font = "bold",
         },
         vb:text{
           text = "Pan      ",
           font = "bold",
         },
         vb:text{
           text = "Dly",
           font = "bold",
         },
          vb:text{
           text = "     D.Nud",
           font = "bold",
         },
       },  
     },
     ----------------------
     --row 4 = Vel Pan Dly 
     vb:row{
       style = "group",
       margin = 4,
       vb:horizontal_aligner{
        mode = "distribute",
         width = 125,
           vb:rotary{
             midi_mapping = "ledger.scripts.NoteProperties:Ledger",
             min = 0,
             max = 127,
             value = volume_to_rotary(cur_note),
             id = "vol",
             notifier = function(value)
                            --return early if on fx track
                           
                          local song = renoise.song()
                          --do nothing if called by GUI update/timer
                          if updating_gui then
                            return
                          end
                          
                          --are we in a note column
                           if not song.selected_note_column then
                             return
                           end
                          --show column if hidden
                          song.tracks[song.selected_track_index].volume_column_visible = true
                          --write rotary value to pattern
                          get_current_note().volume_value = value
                        end
           },
           vb:rotary{
             min = 0,
             max = 127,
             value = panning_to_rotary(cur_note),
             id = "pan",
             notifier = function(value)
                         local song = renoise.song()
                           --do nothing if called by GUI update/timer
                          if updating_gui then
                            return
                          end 
                          --are we in a note column
                          if not song.selected_note_column then
                             return
                          end
                          --show pan column if hidden
                          song.tracks[song.selected_track_index].panning_column_visible = true
                          --write rotary value to pattern
                          get_current_note().panning_value = value
                        end
           },
           vb:rotary{
             min = 0,
             max = 255,
             value = get_initial_delay_value(),
             id = "dly",
             notifier = function(value)
                            --return early if on fx track
                          local song = renoise.song()
                           --do nothing if called by GUI update/timer
                          if updating_gui then
                            return
                          end 
                          --are we in a note column
                          if not song.selected_note_column then
                            return
                          end
                          --show pan column if hidden
                          song.tracks[song.selected_track_index].delay_column_visible = true
                          --write rotary value to pattern
                          get_current_note().delay_value = value
                        end
           },
          },
       --Nudge to previous line max delay
       vb:button{
         text = "<",
         notifier = function()
                      --get vars
                      local cur_line = song.selected_line_index
                      local cur_track = song.selected_track_index
                      local cur_col = song.selected_note_column_index
                      local cur_pattern = song.selected_pattern_index
                      
                      local target_column = nil
                      local previous_note = nil
                      
                      local cur_note = get_current_note()
         
                      --Bounds Checking pattern edge
                      if (cur_line == 1) and (cur_note.delay_value == 0) then
                        status("Can Not Nudge Above Pattern")
                        return
                      end       
                      
                      --show column if hidden
                      song.tracks[song.selected_track_index].delay_column_visible = true
                      
                      --nudge the delay value of the current note one less if over 0
                      if cur_note.delay_value > 0 then
                        cur_note.delay_value = cur_note.delay_value - 1
                        --flag that lets nudge call the timer function
                        not_called_by_nudge = false
                        --update rotary after nudging
                        timer_calls_this()
                        --reset flag
                        not_called_by_nudge = true
                        return
                      end
                                        
                      --check note before is clear, then check for first clear note cell.
                      for col = cur_col,12 do
                        if song.patterns[cur_pattern].tracks[cur_track].lines[cur_line-1]:note_column(col).is_empty then
                          previous_note = song.patterns[cur_pattern].tracks[cur_track].lines[cur_line-1]:note_column(col)
                          target_column = col
                          break
                        end
                      end
                      --no free note cells so do nothing and return
                      if previous_note == nil then --TODO BETTER STATUS
                        status("No Free Columns")
                        return
                      end
                      
                      --set delay value to FF
                      get_current_note().delay_value = 255
                      -- Copy the column's content from another column.
                      previous_note:copy_from(get_current_note())
                      -- Clear the current note column.
                      get_current_note():clear()
                      --move the cursor to the new note position
                      
                      --set edit pos - needs to assign an object as values are not directly accessible
                      local pos = song.transport.edit_pos
                      pos.line = cur_line-1
                      song.transport.edit_pos = pos
                      
                      --check new note column is visible and show it if not
                      if song.tracks[cur_track].visible_note_columns < target_column then
                        song.tracks[cur_track].visible_note_columns = target_column
                      end
                                           
                      --move cursor to new notes column
                      song.selected_note_column_index = target_column
                    end,
       },
       --nudge to next line
       vb:button{
         text = ">",
         notifier = function()
         
                      --get vars
                      local cur_line = song.selected_line_index
                      local cur_track = song.selected_track_index
                      local cur_col = song.selected_note_column_index
                      local cur_pattern = song.selected_pattern_index
                      
                      local target_column = nil
                      local previous_note = nil
                               
                      local cur_note = get_current_note()
                      
                      --Bounds Checking pattern edge
                      if (cur_line == song.selected_pattern.number_of_lines) and (cur_note.delay_value == 255) then
                        status("Can Not Nudge Past End Of Pattern")
                        return
                      end
                      
                      --show column if hidden
                      song.tracks[song.selected_track_index].delay_column_visible = true
                      
                      --nudge the delay value of the current note one less if over 0
                      if cur_note.delay_value < 255 then
                        cur_note.delay_value = cur_note.delay_value + 1
                        --flag that lets nudge call the timer function
                        not_called_by_nudge = false
                        --update rotary after nudging
                        timer_calls_this()
                        --reset flag
                        not_called_by_nudge = true
                        
                        return
                      end
                  
                      --check note before is clear, then check for first clear note cell.
                      for col = cur_col,12 do
                        if song.patterns[cur_pattern].tracks[cur_track].lines[cur_line+1]:note_column(col).is_empty then
                          previous_note = song.patterns[cur_pattern].tracks[cur_track].lines[cur_line+1]:note_column(col)
                          target_column = col
                          break
                        end
                      end
                      --no free note cells so do nothing and return
                      if previous_note == nil then --TODO BETTER STATUS
                        status("No Free Columns")
                        return
                      end
                      
                      --set delay value to 0
                      get_current_note().delay_value = 0
                      -- Copy the column's content from another column.
                      previous_note:copy_from(get_current_note())
                      -- Clear the current note column.
                      get_current_note():clear()
                      --move the cursor to the new note position
                      
                      --[[--set edit pos - needs to assign an object as values are not directly accessible
                      local pos = song.transport.edit_pos
                      pos.line = cur_line+1
                      song.transport.edit_pos = pos
                      
                                            
                      --check new note column is visible and show it if not
                      if song.tracks[cur_track].visible_note_columns < target_column then
                        song.tracks[cur_track].visible_note_columns = target_column
                      end
                                           
                      --move cursor to new notes column
                      song.selected_note_column_index = target_column  --]]
                      
                      
                      
                      
                      
                      --all combines now---------------------------
                      set_edit_pos(cur_pattern,cur_track,(cur_line + 1),target_column)
                                 
                    end,
       },
           
           
        
       },
       ----------------------
       --row 4 text 
       vb:row{
         vb:text{
           text = "Pattern Follow",
         }
       },
      ----------------------- 
      --row 5 offset controls      
      vb:row{ 
        style = "group",
        margin = 4,
        
        vb:horizontal_aligner{
        -- mode = "distribute",
         width = 165,
         --[[  vb:valuebox{
             max = song.selected_pattern.number_of_lines,
             value = cur_line,
             notifier = function()             
             end
           },--]]
           
          vb:checkbox{
             value = renoise.song().transport.follow_player,
             bind = renoise.song().transport.follow_player_observable,
             notifier = function()             
             end
           },
         },
       }, 
     }--ver aligner
    }--vert aligner
    
    
--key Handler
local function my_keyhandler_func(dialog,key)

   --hack: toggle keyboard  lock state to allow pattern ed to receive key input
   renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
   renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus

   --if escape pressed then close the dialog else return key to renoise
   if not (key.modifiers == "" and key.name == "esc") then
      return key
   else
     dialog:close()
   end
end                 

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
  --Initialise Script dialog
  my_dialog = renoise.app():show_custom_dialog(
    "Note Properties", dialog_content,my_keyhandler_func)
    
  --close dialog function --for releasing app
  local function closer(d)    
     if d and d.visible then
       d:close()
     end
  end
  
  --notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)


end --end of main







local function get_current_note()
  local song = renoise.song()
  
  --are we in a note column
  if not song.selected_note_column then
    return
  end
  
--get current note properties
  local cur_line = song.selected_line_index
  local cur_track = song.selected_track_index
  local cur_col = song.selected_note_column_index
  local cur_pattern = song.selected_pattern_index
  
  return song.patterns[cur_pattern].tracks[cur_track].lines[cur_line]:note_column(cur_col) 
end


renoise.tool():add_midi_mapping{
  name = "Ledger.scripts.NoteProperties:Ledger",
  invoke = function(message)
                            --return early if on fx track
                           
 local song = renoise.song()
--do nothing if called by GUI update/timer
if updating_gui then
  return
 end
                          
 --are we in a note column
if not song.selected_note_column then
  return
end
--show column if hidden
song.tracks[song.selected_track_index].volume_column_visible = true
--write rotary value to pattern


  local song = renoise.song()
  
  --are we in a note column
  if not song.selected_note_column then
    return
  end
  
--get current note properties
  local cur_line = song.selected_line_index
  local cur_track = song.selected_track_index
  local cur_col = song.selected_note_column_index
  local cur_pattern = song.selected_pattern_index
  
 -- oprint(message)
 -- print(message.int_value)
  song.patterns[cur_pattern].tracks[cur_track].lines[cur_line]:note_column(cur_col).volume_value = message.int_value

end

}


















--[[class: NoteColumn
 properties:
    delay_string
    delay_value
    instrument_string
    instrument_value
    is_empty
    is_selected
    note_string
    note_value
    panning_string
    panning_value
    volume_string
    volume_value
 methods:
    __STRICT
    __eq
    __tostring
    clear
    copy_from
--]]

-------------------------------------------------------
--Timer to update to each new note
--------------------------------------------------------
--------------------------------------------------------


 --TODO remove timer when GUI shuts
 
 
 ----------------------------------------- 
 --update current note
 -----------------------------------------
 --[[ local function timer_calls_this()
  
    --see if GUI has closed, if it has then remove timer
    if not (my_dialog and my_dialog.visible) then 
      --remove this timer
      if renoise.tool():has_timer(timer_calls_this) then 
        renoise.tool():remove_timer(timer_calls_this)
        return
      end
    end  

    local song = renoise.song()
    
    --get current note properties
    local cur_line_new = song.selected_line_index
    local cur_track_new = song.selected_track_index
    local cur_col_new = song.selected_note_column_index
    local cur_pattern_new = song.selected_pattern_index
    
    --are we in a note column? if not return
    if not song.selected_note_column then
      return
    end
    
    local cur_note_new = song.patterns[cur_pattern_new].tracks[cur_track_new].lines[cur_line_new]:note_column(cur_col_new) 
    
    -- has selected note changed?
    -- return early if line and column has not changed
    if (cur_line == cur_line_new) and (cur_col == cur_col_new) and (cur_track == cur_track_new) then
      return
    end
    
    --set flag that GUI is updating
    updating_gui = true
    
    --set current line (from main) to current_line new 
    cur_line = cur_line_new
      
    --NEED TO CHECK VALUES IN PATTERn EDITOR ARE IN BOUNDS 0-127
    --set note
    vb.views["note_name"].value = (cur_note_new.note_value + 1)
    --set velocity
    vb.views["vol"].value = volume_to_rotary(cur_note_new)
    --set pan
    vb.views["pan"].value = panning_to_rotary(cur_note_new)
    --set delay
    vb.views["dly"].value = cur_note_new.delay_value   
    
    --reset flag
    updating_gui = false
  end--]]


