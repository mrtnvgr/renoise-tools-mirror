renoise.tool():add_keybinding {
  name = "Global:Tools:Clear Junk Data",
  invoke = function()clear_junk_data()
  end  
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Clear Junk Data",
  invoke = function() clear_junk_data()
  end
}

local my_dialog = nil
--------------------------------------------------------------
--main
--------------------------------------------------------------
function clear_junk_data()

--1 dialog at a time
if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
  my_dialog:close()
  return
end

--------------------------------------------------------------
--Local functions
--------------------------------------------------------------

local function get_type_of_tracks() 

local track_table = renoise.song().tracks
local note_tracks = {}  --incrementor
local NOTE_TRACK = 1

  for num,track in ipairs(track_table) do
   
    if track.type == NOTE_TRACK then
      note_tracks[num] = true
    else
      note_tracks[num] = false
    end    
  end   
 return note_tracks
end

--------------------------------------------------------------
--constants 
--------------------------------------------------------------
local NOTE_OFF = 120
local EMPTY_NOTE_CELL = 121
local NOTE_TRACK = 1

-- total_patterns
local total_patterns = #renoise.song().patterns
local max_vb

if total_patterns == 1 then
  max_vb = 2
else max_vb = #renoise.song().patterns
end
--------------------------------------------------------------
--GUI
--------------------------------------------------------------
local vb = renoise.ViewBuilder()


local title = "Clear Junk Data"
local dialog_content = vb:column {
                        margin = 4,
                        
                        vb:vertical_aligner {
                         mode = "distribute",
                         spacing = 8,
                        
                        vb:column {
                         style = "group",
                         margin = 4,
                         
                        vb:text {
                         text = "Range:" 
                        },
                        
                        vb:popup {
                         value = 1,
                         id = "popup",
                         width = 120,
                         items = {
                           "Track in Pattern",
                           "Selection in Pattern",
                           "Current Pattern",
                           "Track in Song",
                           "Sequencer Range...",
                           "Whole Song"},           
                         }, 
                        },--column
                        
                        vb:column {
                         style = "group",
                         margin = 1,
                         
                        vb:text {
                         text = "What to Clear:" 
                        },
                         
                        vb:row {
                         margin = 4,
                        
                        vb:switch {
                         value = 1,
                         id = "switch",
                         items = {"Note Offs","Meta"},
                         width = 118
                        },                        
                       },
                      },
                        
                        vb:horizontal_aligner {
                         mode = "center",
                         margin = 4,
                        
                        vb:button {
                         text = "Clear!",
                         id = "button",
                         height = 24,
                         width = 110,
                         
 notifier = function()

-----------------------------------------------------
--CLEAR REDUNDENT NOTE OFFS 
-----------------------------------------------------
--status
renoise.app():show_status("Clear Junk Data Tool : (Clearing data...)")
--const.
local NOTE_OFF = 120
local EMPTY_NOTE_CELL = 121
--vars
local current_note_holder = 0
--renoise vals
local pattern_iter = renoise.song().pattern_iterator
local pattern_index = renoise.song().selected_pattern_index
local track_index = renoise.song().selected_track_index
local pattern_length = renoise.song().patterns[pattern_index].number_of_lines
local all_patterns = #renoise.song().patterns
local total_patterns = #renoise.song().patterns

local current_pattern_track = renoise.song().patterns[pattern_index].tracks[track_index] 
local track_table = renoise.song().tracks

local track_type_table = get_type_of_tracks() --local function
local all_tracks = renoise.song().tracks 



if vb.views["switch"].value == 1 then    
---------------------------------------------
--"iterate" downwards: 1 column at a time
---------------------------------------------

if vb.views["popup"].value == 1 then --[TRACK IN PATTERN]

  for note_col = 1,12 do
    current_note_holder = 0 --reset for each column
      
    for line_index = 1, pattern_length do
      local note_columns = current_pattern_track:line(line_index).note_columns --table

     --if second note_off in column found then delete
      if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
        note_columns[note_col].note_value = EMPTY_NOTE_CELL 
      end
   
     --note_off found so initialise holder
      if note_columns[note_col].note_value == NOTE_OFF then
        current_note_holder = NOTE_OFF
  
     --else note found so reset holder
      elseif note_columns[note_col].note_value < NOTE_OFF then
        current_note_holder = 0
      end
    end --for "lines in column"
  end --for "each column"


----------------------------------------------------------------------------------------------------------------
elseif vb.views["popup"].value == 2 then -- [SELECTION IN PATTERN] 


for my_note_tracks = 1, #all_tracks do  --tracks

  if track_type_table[my_note_tracks] then --false if not a note_track
    
    local current_pattern_track = renoise.song().patterns[pattern_index].tracks[my_note_tracks]
  
   --"iterate" downwards: 1 column at a time
   ---------------------------------------------
    for note_col = 1,12 do
      current_note_holder = 0 --reset for each column
     
      for line_index = 1, pattern_length do
        local note_columns = current_pattern_track:line(line_index).note_columns --table
    

         --if second note_off in column found then delete
        if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
          if note_columns[note_col].is_selected  then -- only clear if [SELECTED]
            note_columns[note_col].note_value = EMPTY_NOTE_CELL 
          end
        end
   
         --note_off found so initialise holder
        if note_columns[note_col].note_value == NOTE_OFF then
          current_note_holder = NOTE_OFF

         --else note found so reset holder
        elseif note_columns[note_col].note_value < NOTE_OFF then
          current_note_holder = 0
        end
      end --for "lines in column"    
    end --for "each column"
  end -- if track_type
end --for "each track in pattern"
---------------------------------------------------------------------------------------------------------------------------
elseif vb.views["popup"].value == 3 then -- [PATTERN]


for my_note_tracks = 1, #all_tracks do  --tracks

   if track_type_table[my_note_tracks] then --false if not a note_track
   
     local current_pattern_track = renoise.song().patterns[pattern_index].tracks[my_note_tracks]
    
     --"iterate" downwards: 1 column at a time
     ---------------------------------------------
      for note_col = 1,12 do
        current_note_holder = 0 --reset for each column
     
      for line_index = 1, pattern_length do
        local note_columns = current_pattern_track:line(line_index).note_columns --table

        --if second note_off in column found then delete
        if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
          note_columns[note_col].note_value = EMPTY_NOTE_CELL 
        end
   
        --note_off found so initialise holder
        if note_columns[note_col].note_value == NOTE_OFF then
          current_note_holder = NOTE_OFF
  
        --else note found so reset holder
        elseif note_columns[note_col].note_value < NOTE_OFF then
          current_note_holder = 0
        end   
      end --for "lines in column"
    end --for "each column"
  end -- if track_type
end --for "each track in pattern"

elseif vb.views["popup"].value == 4 then -- [TRACK IN SONG] 

local status_number = 0

for patterns = 1, all_patterns do
  local current_pattern_track = renoise.song().patterns[patterns].tracks[track_index]
 
  pattern_index = patterns
  status_number = status_number +1
  renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
  ..status_number.." / "..total_patterns..")")
 
 for note_col = 1,12 do
    current_note_holder = 0 --reset for each column
     
    for line_index = 1, pattern_length do
      local note_columns = current_pattern_track:line(line_index).note_columns --table

       --if second note_off in column found then delete
      if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
        note_columns[note_col].note_value = EMPTY_NOTE_CELL 
      end
   
       --note_off found so initialise holder
      if note_columns[note_col].note_value == NOTE_OFF then
        current_note_holder = NOTE_OFF
  
       --else note found so reset holder
      elseif note_columns[note_col].note_value < NOTE_OFF then
        current_note_holder = 0
      end   
    end --for "lines in column"
  end --for "each column"
end --for "all patterns"


elseif vb.views["popup"].value == 5 then -- [SEQUENCER RANGE..]

--renoise sequencer tables
local sel_range = renoise.song().sequencer.selection_range
local pat_seq = renoise.song().sequencer.pattern_sequence
--derived loop controllers
local status_number =  sel_range[1] 
local user_chosen_range_start =  sel_range[1]
local user_chosen_range_end =  sel_range[2]


for patterns = user_chosen_range_start, user_chosen_range_end do
  
    pattern_index = pat_seq[patterns]
    status_number = status_number +1
    
    renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
                ..pattern_index.." / "..user_chosen_range_end..")")
 
  
  for my_note_tracks = 1, #all_tracks do  --tracks
  
    if track_type_table[my_note_tracks] then --false if not a note_track
    
    local current_pattern_track = renoise.song().patterns[pattern_index].tracks[my_note_tracks]

     --"iterate" downwards: 1 column at a time
     ---------------------------------------------
      for note_col = 1,12 do
        current_note_holder = 0 --reset for each column
      
        for line_index = 1, pattern_length do
          local note_columns = current_pattern_track:line(line_index).note_columns --table

         --if second note_off in column found then delete
          if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
            note_columns[note_col].note_value = EMPTY_NOTE_CELL 
          end
   
         --note_off found so initialise holder
          if note_columns[note_col].note_value == NOTE_OFF then
            current_note_holder = NOTE_OFF
  
         --else note found so reset holder
          elseif note_columns[note_col].note_value < NOTE_OFF then
             current_note_holder = 0
        end 
        end --for "lines in column"
      end --for "each column"
    end --for "each track in pattern"
  end -- if track_type  
end --for "each pattern in song"




elseif vb.views["popup"].value == 6 then -- [WHOLE SONG]


---Get no of patterns:

local status_number = 0


for patterns = 1, total_patterns do
  pattern_index = patterns
  status_number = status_number +1
  renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
  ..status_number.." / "..total_patterns..")")
  
  for my_note_tracks = 1, #all_tracks do  --tracks
   
    if track_type_table[my_note_tracks] then --false if not a note_track
      local current_pattern_track = renoise.song().patterns[pattern_index].tracks[my_note_tracks]

     --"iterate" downwards: 1 column at a time
     ---------------------------------------------

      for note_col = 1,12 do
        current_note_holder = 0 --reset for each column
      
        for line_index = 1, pattern_length do
          local note_columns = current_pattern_track:line(line_index).note_columns --table

          --if second note_off in column found then delete
          if current_note_holder == NOTE_OFF and note_columns[note_col].note_value == NOTE_OFF then
            note_columns[note_col].note_value = EMPTY_NOTE_CELL 
          end
   
          --note_off found so initialise holder
          if note_columns[note_col].note_value == NOTE_OFF then
            current_note_holder = NOTE_OFF
  
          --else note found so reset holder
          elseif note_columns[note_col].note_value < NOTE_OFF then
           current_note_holder = 0
          end 
        end --for "lines in column"
      end --for "each column"
    end --for "each track in pattern"
  end --for "each pattern in song"
end -- (if track_type?)

end --if --popup




elseif vb.views["switch"].value == 2 then --[meta]

-------------------------------------------------------------
--CLEAR VOL PAN etc.
-------------------------------------------------------------
-- 255 = empty vol,pan
--   0 = delay set to 0 

if vb.views["popup"].value == 1 then --[Meta TRACK IN PATTERN]
--iterate and clear orphaned meta data
  for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do

    if line.note_value > 119 then --note present

      line.instrument_value = 255
      line.volume_value = 255
      line.panning_value = 255
      if line.note_value ~= NOTE_OFF then
        line.delay_value = 00
      end
    end
  end
  
elseif vb.views["popup"].value == 2 then --[meta SELECTION IN PATTERN] 
  
  for pos,line in pattern_iter:note_columns_in_pattern(pattern_index) do
   
      
    if line.is_selected then
      if line.note_value > 119 then --note present

        line.instrument_value = 255
        line.volume_value = 255
        line.panning_value = 255
        if line.note_value ~= NOTE_OFF then --leave note-off delay values
          line.delay_value = 00
        end
      end
    end
  end
  
elseif vb.views["popup"].value == 3 then --[meta PATTERN] 
  
  for pos,line in pattern_iter:note_columns_in_pattern(pattern_index) do

    if line.note_value > 119 then --note present

      line.instrument_value = 255
      line.volume_value = 255
      line.panning_value = 255
      if line.note_value ~= NOTE_OFF then --leave note-off delay values
        line.delay_value = 00
      end
    end
  end

elseif vb.views["popup"].value == 4 then --[Meta WHOLE TRACK]

local pos_holder = 0
local position_in_sequencer = 0

for pos,line in pattern_iter:note_columns_in_track(track_index) do

-- Get current pattern for status i.e.:(Processing Pattern 1/100) 
-- inc. and conditionals needed as pos.pattern returns the number
-- of the pattern and not the position in the sequencer.  
  if pos.pattern ~= pos_holder then
    position_in_sequencer = position_in_sequencer + 1
    pos_holder = pos.pattern
    renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
    ..position_in_sequencer.." / "..total_patterns..")")
  end  

  if line.note_value > 119 then --note present

    line.instrument_value = 255
    line.volume_value = 255
    line.panning_value = 255
    if line.note_value ~= NOTE_OFF then --leave note-off delay values
      line.delay_value = 00
    end
  end
end
  
  
elseif vb.views["popup"].value == 5 then --[SEQUENCER RANGE..]

--renoise sequencer tables
local sel_range = renoise.song().sequencer.selection_range
local pat_seq = renoise.song().sequencer.pattern_sequence
--derived loop controllers
local status_number =  sel_range[1] 
local user_chosen_range_start =  sel_range[1]
local user_chosen_range_end =  sel_range[2]


for pattern = user_chosen_range_start,user_chosen_range_end do 
  local pattern_index = pat_seq[pattern]
  
  for pos,line in pattern_iter:note_columns_in_pattern(pattern_index) do
    --status
    renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
                          ..pattern.." / "..user_chosen_range_end..")")

    if line.note_value > 119 then --note present

      line.instrument_value = 255
      line.volume_value = 255
      line.panning_value = 255
      if line.note_value ~= NOTE_OFF then --leave note-off delay values
        line.delay_value = 00
      end --if
    end --if
  end --for
end --for 

elseif vb.views["popup"].value == 6 then --[Meta WHOLE SONG]

local pos_holder = 0
local position_in_sequencer = 0

for pos,line in pattern_iter:note_columns_in_song() do
 
-- Get current pattern for status i.e.:(Processing Pattern 1/100) 
-- inc. and conditionals needed as pos.pattern returns the number
-- of the pattern and not the position in the sequencer.
  if pos.pattern ~= pos_holder then
    position_in_sequencer = position_in_sequencer + 1
    pos_holder = pos.pattern
    renoise.app():show_status("Clear Junk Data Tool: (Processing Pattern : "
    ..position_in_sequencer.." / "..total_patterns..")")
 end  
     
  
  
    if line.note_value > 119 then --note present

      line.instrument_value = 255
      line.volume_value = 255
      line.panning_value = 255
      if line.note_value ~= NOTE_OFF then --leave note-off delay values
        line.delay_value = 00
      end
    end
  end



end --if [popup] 


end--[ switch]


renoise.app():show_status("Clear Junk Data Tool: (Completed)")
end --notifier function()
------------------------------------------------------                         
    }
   }
  }
 }
 
 --key Handler
local function my_keyhandler_func(dialog, key)

 if not (key.modifiers == "" and key.name == "esc") then
    return key
 else
   dialog:close()
 end
end

my_dialog = renoise.app():show_custom_dialog(title, dialog_content,my_keyhandler_func)

end --main



