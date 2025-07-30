
-- Pattern menu

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Note Off Tool",
  invoke = function() note_off_main()
  end
}

--keybindings

--[1]
renoise.tool():add_keybinding {
  name = "Global:Tools:Add Note-Offs To Empty Cells in Row",
  invoke = function()add_note_offs_to_empty_cells()
  end  
}

--[2]
renoise.tool():add_keybinding {
  name = "Global:Tools:Add Note-Offs To Empty Cells in [Whole Pattern Row]",
  invoke = function()add_note_offs_to_empty_cells_in_pattern()
  end  
}

--[3]
renoise.tool():add_keybinding {
  name = "Global:Tools:Note Off Tool",
  invoke = function()note_off_main()
  end  
}



--------------------------------------------------------------------------------------------------
-- [3] Note off tool Gui etc
--------------------------------------------------------------------------------------------------
local my_dialog = nil

function note_off_main()


--1 dialog at a time
if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
  my_dialog:close()
  return
end

--------------------------------------------------------------
--Local functions
--------------------------------------------------------------
--------------------------------
--get the total number of tracks
--------------------------------
local function get_number_of_tracks() 

local track_table = renoise.song().tracks
local note_tracks = 0  --incrementor
local NOTE_TRACK = 1

  for _,track in ipairs(track_table) do
   
    if track.type == NOTE_TRACK then
      note_tracks = note_tracks + 1
    end    
  end   
 return note_tracks
end
-----------------------
--focus pattern editor
-----------------------
local function focus_pattern()
  renoise.app().window.lock_keyboard_focus = false
  renoise.app().window.lock_keyboard_focus = true
end

--------------------------------------------------------------
--GUI
--------------------------------------------------------------
local vb = renoise.ViewBuilder()
local pattern_index = renoise.song().selected_pattern_index
local pattern_length = renoise.song().patterns[pattern_index].number_of_lines

local title = "Set Note Lengths"
local dialog_content = vb:column {
                       
 margin = 4,
  vb:vertical_aligner {
   mode = "distribute",
   spacing = 8,
                        
   vb:column { ----------------------------Range Selection
    style = "group",
    margin = 4,
                         
    vb:text {
     text = "Range:" 
    },
                        
    vb:popup {
     value = 1,
     id = "popup",
     width = 128,
     items = {"Selection in Pattern",
             "Track in Pattern",
             "Patterns From..."
             },
     notifier = function()
     --enable buttons
       if vb.views["popup"].value ==3 then
         vb.views["box1"].visible = true
         vb.views["box2"].visible = true
       else
         vb.views["box1"].visible = false
         vb.views["box2"].visible = false   
       end
     end
     },
     
      vb:horizontal_aligner {  --- pattern range
        mode = "left",
     
     vb:valuebox {
      value = 0,
      visible = false,
      id = "box1"
                },
     vb:valuebox {
      value = 0,
      visible = false,
      id = "box2"
                },       
            
            
          },
   },--column -------------------------
                        
  vb:column {  ---------------------------Values
   style = "group",
  margin = 1,
   
   vb:row {                      
    vb:text {
     text = " Length:                              " -- 
    },
   },
   
   vb:row { 
    vb:text {
     text = " Row:           ",
    },
    vb:button{
     text = "Delay:Tog",
     notifier = function()
     
     local  track = renoise.song().selected_track_index
     local  cur_track = renoise.song().tracks[track]
     cur_track.delay_column_visible = not cur_track.delay_column_visible
     
     renoise.app().window.lock_keyboard_focus = false --focus pattern
     renoise.app().window.lock_keyboard_focus = true
     end
   }
  },
                       
  vb:row {
   margin = 4,
                        
  vb:valuebox { --ro box
   min = 0,
   max = pattern_length,
   value = 1,
   id = "val",
    tostring = function(value) 
     return tostring(value)
    end,
    tonumber = function(str) 
     return tonumber(str)
   end

  
  },
   vb:valuebox { --delay box
   min = 0,
   max = 255,
   value = 0,
   id = "valDel",
    tostring = function(value) 
     return tostring(value)
    end,
    tonumber = function(str) 
     return tonumber(str)
   end
  },                    
                        
  },
 },-------------------
                        
 vb:horizontal_aligner {
 mode = "center",
 margin = 4,
                        
 vb:button {
 text = "Apply",
 height = 24,
 width = 110,
 notifier = function()
-------------------------------------------------------------------------------------------
--Apply Button Notifier
-------------------------------------------------------------------------------------------

--Pattern Data constants
local EMPTY_DELAY = 0 
--local EMPTY_VOL_PAN_DLY = 255
local NOTE_OFF = 120
local EMPTY_NOTE_CELL = 121

local pattern_index = renoise.song().selected_pattern_index
local pattern_length = renoise.song().patterns[pattern_index].number_of_lines

local note_type_holder
local check_down_pattern = true
local index = get_number_of_tracks() --local function

local pattern_iter = renoise.song().pattern_iterator
local track_index = renoise.song().selected_track_index
   
local note_length = vb.views["val"].value   

if vb.views["popup"].value == 3 then 
------------------------------------------------- [TRACK in PATTERN]
-- [Patterns From]
-----------------------------------------------

--first clear all note-OFFs in Track in Pattern

for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do

  if (line.note_value == NOTE_OFF) and (pos.line > 1) then  --leave note-offs in line 1
    line.note_value = EMPTY_NOTE_CELL
    line.delay_value = EMPTY_DELAY 
  end
end

---------------------------------------------
if note_length > 0 then
  local current_pattern_track = renoise.song().patterns[pattern_index].tracks[track_index] 
  
    
    if vb.views["valDel"].value > 0 then  --show delay column if delay value added    
      renoise.song().tracks[track_index].delay_column_visible = true
    end

 --"iterate" downwards: 1 column at a time:  
 --------------------------------------------- 
  for note_col = 1,12 do --column
     
    for line_index = 1,pattern_length  do --line at a time 
      local note_columns = current_pattern_track:line(line_index).note_columns --table
      local current_cell = note_columns[note_col].note_value
            
      if current_cell < 120 then --a note 
        check_down_pattern = true
        
        for length = 1,(note_length) do --go down pattern to add off 
          
          local check_cell = current_pattern_track:line(line_index + (length)).note_columns
          local current_cell_b = check_cell[note_col].note_value
          
          -------------------------------------
          if current_cell_b < 120 then
            check_down_pattern = false
          end
        end

        if check_down_pattern then
          local target_cell = current_pattern_track:line(line_index + note_length).note_columns
           target_cell[note_col].note_value = NOTE_OFF    
           target_cell[note_col].delay_value = vb.views["valDel"].value      
        end
        
       end--current cell
      
    end --for "lines in column"
  end --for "each column"
end -- if > 0


elseif vb.views["popup"].value == 2 then 
------------------------------------------------- [TRACK in PATTERN]
-- [Track in Pattern]
-----------------------------------------------
--first clear all note-OFFs in Track in Pattern

for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do

  if (line.note_value == NOTE_OFF) and (pos.line > 1) then  --leave note-offs in line 1
    line.note_value = EMPTY_NOTE_CELL
    line.delay_value = EMPTY_DELAY 
  end
end

---------------------------------------------
if note_length > 0 then
  local current_pattern_track = renoise.song().patterns[pattern_index].tracks[track_index] 
  
    
    if vb.views["valDel"].value > 0 then  --show delay column if delay value added    
      renoise.song().tracks[track_index].delay_column_visible = true
    end

 --"iterate" downwards: 1 column at a time:  
 --------------------------------------------- 
  for note_col = 1,12 do --column
     
    for line_index = 1,pattern_length  do --line at a time 
      local note_columns = current_pattern_track:line(line_index).note_columns --table
      local current_cell = note_columns[note_col].note_value
            
      if current_cell < 120 then --a note 
        check_down_pattern = true
        
        for length = 1,(note_length) do --go down pattern to add off 
          
          local check_cell = current_pattern_track:line(line_index + (length)).note_columns
          local current_cell_b = check_cell[note_col].note_value
          
          -------------------------------------
          if current_cell_b < 120 then
            check_down_pattern = false
          end
        end

        if check_down_pattern then
          local target_cell = current_pattern_track:line(line_index + note_length).note_columns
           target_cell[note_col].note_value = NOTE_OFF    
           target_cell[note_col].delay_value = vb.views["valDel"].value      
        end
        
       end--current cell
      
    end --for "lines in column"
  end --for "each column"
end -- if > 0



elseif vb.views["popup"].value == 1 then --[SELECTION in PATTERN]
-----------------------------------------------------------------------------
--Get Range of [Selection in Pattern]
-----------------------------------------------------------------------------

local first_selected_track = false
local last_selected_track = false
local first_selected_line = false
local last_selected_line = false
local first_selected_column = false
local last_selected_column = false

for pos,line in pattern_iter:note_columns_in_pattern(pattern_index) do
  
  if line.is_selected and (not first_selected_track) then
    first_selected_track = pos.track
    first_selected_line = pos.line
    first_selected_column = pos.column
  end
  
  if line.is_selected then
    last_selected_track = pos.track
    last_selected_line =  pos.line
    last_selected_column = pos.column
  end
end


------------------------------------------------------------------------------
--Clear all note-OFFs in selection
------------------------------------------------------------------------------

for pos,line in pattern_iter:note_columns_in_pattern(pattern_index,track_index) do

  if line.is_selected then --only if selected

    if (line.note_value == NOTE_OFF) and (pos.line > 1) then  --leave note-offs in line 1
      line.note_value = EMPTY_NOTE_CELL
      line.delay_value = EMPTY_DELAY 
    end
  end
end

-- zero selected as row valuebox/ f.s.track means range exists

if (note_length > 0) and first_selected_track then

---------------------------------------------------------------------------------------------------
for my_note_tracks = first_selected_track, last_selected_track do  --tracks
  local current_pattern_track = renoise.song().patterns[pattern_index].tracks[my_note_tracks] 
  
  if vb.views["valDel"].value > 0 then  --show delay columns if delay value added    
      renoise.song().tracks[my_note_tracks].delay_column_visible = true
    end

 --"iterate" downwards: 1 column at a time
 ---------------------------------------------

  for note_col = 1,12 do
    note_type_holder = 0 --reset for each column
     
      for line_index = first_selected_line,last_selected_line  do -- go downwards through each selected column --
        local note_columns = current_pattern_track:line(line_index).note_columns --table
        local current_cell = note_columns[note_col].note_value
         
        if not note_columns[note_col].is_selected then --break loop if column not selected
          break
        end
      
        if current_cell < 120 then --a note 
      
          check_down_pattern = true
        
          for length = 1,(note_length) do --go down pattern to add off 
          
            local check_cell = current_pattern_track:line(line_index + (length)).note_columns
            local current_cell_b = check_cell[note_col].note_value
          
            -------------------------------------
            if current_cell_b < 120 then
              
              check_down_pattern = false
            end
          end

          if check_down_pattern then
            local target_cell = current_pattern_track:line(line_index + note_length).note_columns
          
           -- if note_columns[note_col].is_selected  then ---selected NEEDED?
              target_cell[note_col].note_value = NOTE_OFF
              target_cell[note_col].delay_value = vb.views["valDel"].value
           -- end -- is selected
          
          end
        end--current cell
      end --for "lines in column"
    end --for "each column"
  end --for "each track in pattern"

else
renoise.app():show_status("Note Off Tool: (No Selection in Pattern)")

end -- if not 0




end --if vb.views["popup"].value == then [RANGE]


 focus_pattern()
end --notifier


    }
   }
  }
 }
 
local function my_keyhandler_func(dialog, key)

 if not (key.modifiers == "" and key.name == "esc") then
    return key
  end

end
my_dialog = renoise.app():show_custom_dialog(title, dialog_content,my_keyhandler_func)

end --main

--------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------




 



-- EXTRA SHORTCUT FUNCTIONS:
-------------------------------------------------------
-- [1] [Single Track] Fill empty visible cells in selected
-- line with note-offs
-------------------------------------------------------

function add_note_offs_to_empty_cells()

  local NOTE_OFF = 120
  local EMPTY_NOTE_CELL = 121
 
  local line_index = renoise.song().selected_line_index
  local pattern_index = renoise.song().selected_pattern_index
  local track_index = renoise.song().selected_track_index
  local current_pattern_track = renoise.song().patterns[pattern_index].tracks[track_index]
  local visible_columns = renoise.song().tracks[track_index].visible_note_columns
  
  
  local current_note_holder
  local pattern_length = renoise.song().patterns[pattern_index].number_of_lines

  
  for note_col = 1,visible_columns do
    
    local note_columns = current_pattern_track:line(line_index).note_columns

    if note_columns[note_col].note_value == EMPTY_NOTE_CELL then  --if cell == empty then
      note_columns[note_col].note_value = NOTE_OFF  --set to note_off
    end
  
  end
  
  --clear junk note-offs SMART
  
  local current_note_holder
  local pattern_length = renoise.song().patterns[pattern_index].number_of_lines
  local current_pos = renoise.song().selected_line_index
 
   for note_col = 1,12 do
   
      local note_columns = current_pattern_track:line(current_pos).note_columns
     
      if note_columns[note_col].note_value == NOTE_OFF then
       
      --scan down  
     for line_index = (current_pos + 1),pattern_length do
     local note_columns = current_pattern_track:line(line_index).note_columns --table
       

       --clear note-offs
       if note_columns[note_col].note_value == NOTE_OFF then
         note_columns[note_col].note_value = EMPTY_NOTE_CELL
       end
       
       -- if note found, break
       if note_columns[note_col].note_value < NOTE_OFF then 
         break
       end
     end --for "lines in column"
   
   --scan up
     for line_index = (current_pos - 1),2,-1 do
      local note_columns = current_pattern_track:line(line_index).note_columns --table
      
     
      
       if note_columns[note_col].note_value == NOTE_OFF then
         note_columns[note_col].note_value = EMPTY_NOTE_CELL
       end
       
       if note_columns[note_col].note_value < NOTE_OFF then 
         break
       end
     end --for "lines in column"
   
   
   
    end-- if
   end --for "each column"
end --main

-----------------------------------------------------------------------
-- [2] [All Tracks in Pattern] Fill empty visible cells in selected line for
-- whole pattern with note-offs
-----------------------------------------------------------------------

function add_note_offs_to_empty_cells_in_pattern()

  local NOTE_OFF = 120
  local EMPTY_NOTE_CELL = 121
 
  local line_index = renoise.song().selected_line_index
  local pattern_index = renoise.song().selected_pattern_index
  local track_index = renoise.song().selected_track_index
  local visible_columns = renoise.song().tracks[track_index].visible_note_columns
  
  
--Get Number of Note Tracks:
---------------------------------------------------------------
  local track_table = renoise.song().tracks
  local note_tracks = 0  --incrementor

  local NOTE_TRACK = 1

  for k,v in ipairs(track_table) do
   
    if v.type == NOTE_TRACK then
      note_tracks = note_tracks + 1
    end
    
  end

--------------------------------------------------------------

  for index = 1,#renoise.song().tracks do
    if renoise.song().tracks[index].type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
    --do nothing
    else
      --track and no. of visible cols
      local current_pattern_track = renoise.song().patterns[pattern_index].tracks[index]
      visible_columns = renoise.song().tracks[index].visible_note_columns --reset for each track
     
      --add note_offs with loop 
      for note_col = 1,visible_columns do
        
        local note_columns = current_pattern_track:line(line_index).note_columns
        if note_columns[note_col].note_value == EMPTY_NOTE_CELL then
          note_columns[note_col].note_value = NOTE_OFF
        end
      end--for
    end--for
  end
end --main












