renoise.tool():add_keybinding {
  name = "Global:Tools:Print My Chords",
  invoke = function()analyse_chords() end
  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Print My Chords",
  invoke = function() analyse_chords()
  end
}



--vars
local my_dialog = nil
local current_key = 4
local maj_or_min = 1
local prev_chord = false
local song_or_selection = 1

REPEATED_CHORD = "--rpt--"



--Master/reference tables
------------------------------------------------------
-- chord id`s derived from chromatic degree in scale i.e.
-- 158 from 1,5,8 = tonic major triad.
-- double entry ids are commented out but left for reference

local chord_table = {} 
chord_table.maj = {}
chord_table.min = {}

--major Chromatic scale numbers: 1,3,5,6,8,10,12
--standard triads
chord_table.maj[1] = { id = 158,  diatonic = true, numeral = "I",   name = "Tonic" } 
chord_table.maj[2] = { id = 3610, diatonic = true, numeral = "ii",  name = "Supertonic" }
chord_table.maj[3] = { id = 5812, diatonic = true, numeral = "iii", name = "Mediant" }
chord_table.maj[4] = { id = 1610, diatonic = true, numeral = "IV",  name = "Sub Dominant" }
chord_table.maj[5] = { id = 3812, diatonic = true, numeral = "V",   name = "Dominant" } 
chord_table.maj[6] = { id = 1510, diatonic = true, numeral = "vi",  name = "Sub Mediant" } 
chord_table.maj[7] = { id = 3612, diatonic = true, numeral = "vii dim", name = "Leading" }


--accidental triads i.e. not in selected key.
chord_table.maj[8] =  { id = 148,  diatonic = false, numeral = "[i]",   name = "" } 
chord_table.maj[9] =  { id = 3710, diatonic = false, numeral = "[II]",  name = "" }
chord_table.maj[10] = { id = 5912, diatonic = false, numeral = "[III]", name = "" }
chord_table.maj[11] = { id = 169,  diatonic = false, numeral = "[iv]",  name = "" }
chord_table.maj[12] = { id = 3811, diatonic = false, numeral = "[v]",   name = "" }
chord_table.maj[13] = { id = 2510, diatonic = false, numeral = "[VI]",  name = "" }
chord_table.maj[14] = { id = 4712, diatonic = false, numeral = "[VII]", name = "" }


--7ths
chord_table.maj[15] = { id = 15812,  diatonic = true, numeral = "I Maj7",    name = "Tonic 7th" } 
chord_table.maj[16] = { id = 13610,  diatonic = true, numeral = "ii min7",   name = "Supertonic 7th" }
chord_table.maj[17] = { id = 35812,  diatonic = true, numeral = "iii min7",  name = "Mediant 7th" }
chord_table.maj[18] = { id = 15610,  diatonic = true, numeral = "IV Maj7",   name = "Sub Dominant 7th" }
chord_table.maj[19] = { id = 36812,  diatonic = true, numeral = "V 7",       name = "Dominant" } 
chord_table.maj[20] = { id = 15810,  diatonic = true, numeral = "vi min7",   name = "Sub Mediant" }
chord_table.maj[21] = { id = 361012, diatonic = true, numeral = "vii dim7 ", name = "Leading" }


--accidental 7ths i.e. not in selected key.
chord_table.maj[22] = { id = 14811,   diatonic = false, numeral = "[i min7)]",  name = "" } 
chord_table.maj[23] = { id = 23710,   diatonic = false, numeral = "[II Maj7]",  name = "" }
chord_table.maj[24] = { id = 35912,   diatonic = false, numeral = "[III 7]",    name = "" }
chord_table.maj[25] = { id = 1694,    diatonic = false, numeral = "[iv min7]",  name = "" }
chord_table.maj[26] = { id = 36811,   diatonic = false, numeral = "[v min7]",   name = "" }
chord_table.maj[27] = { id = 25910,   diatonic = false, numeral = "[VI Maj7]",  name = "" }
chord_table.maj[28] = { id = 471112,  diatonic = false, numeral = "[VII Maj7]", name = "" }


--accidental dominant 7ths
chord_table.maj[29] = { id = 15811,   diatonic = false, numeral = "[I 7]",   name = "" } 
chord_table.maj[30] = { id = 13710,   diatonic = false, numeral = "[II 7]",  name = "" }
chord_table.maj[31] = { id = 35912,   diatonic = false, numeral = "[III 7]", name = "" }
chord_table.maj[32] = { id = 14610,   diatonic = false, numeral = "[IV 7]",  name = "" }
--> V already covered <--   
chord_table.maj[33] = { id = 25810,   diatonic = false, numeral = "[VI 7]",  name = "" }
chord_table.maj[34] = { id = 471012,  diatonic = false, numeral = "[VII 7]", name = "" }


----------------------------------------------------------------------------------------------
--Minor
----------------------------------------------------------------------------------------------

--(Aeolian mode)
--Natural-Minor Chromatic scale numbers:  1,3,4,6,8,9,11
--Natural-Minor Triads
chord_table.min[1] = { id = 148,  diatonic = true, numeral = "i",      name = "Tonic" } 
chord_table.min[2] = { id = 369,  diatonic = true, numeral = "ii dim", name = "Supertonic" }
chord_table.min[3] = { id = 4811, diatonic = true, numeral = "III",    name = "Mediant" }
chord_table.min[4] = { id = 169,  diatonic = true, numeral = "iv",     name = "Sub Dominant" }
chord_table.min[5] = { id = 3811, diatonic = true, numeral = "v",      name = "Dominant" } 
chord_table.min[6] = { id = 149,  diatonic = true, numeral = "VI",     name = "Sub Mediant" } 
chord_table.min[7] = { id = 3611, diatonic = true, numeral = "VII",    name = "Leading" }




--Melodic-Minor Chromatic scale numbers:  1,3,4,6,8,10,12
--Melodic Minor Triads
--chord_table.min[] = { id = 148,   diatonic = true, numeral = "i ",      name = "Tonic" }
chord_table.min[8] = { id = 3610,  diatonic = true, numeral = "ii",      name = "Supertonic" }
chord_table.min[9] = { id = 4812,  diatonic = true, numeral = "III+",    name = "Mediant" }
chord_table.min[10] = { id = 1610,  diatonic = true, numeral = "IV",      name = "Sub Dominant" }
chord_table.min[11] = { id = 3812,  diatonic = true, numeral = "V",       name = "--- minor" } 
chord_table.min[12] = { id = 1410,  diatonic = true, numeral = "vi# dim", name = "Sub Mediant" } 
chord_table.min[13] = { id = 369,   diatonic = true, numeral = "vii# dim",name = "Leading" }

--Harmonic-Minor chromatic scale numbers:  1,3,4,6,8,9,12
--chord_table.min[] = { id = 148,  diatonic = true, numeral = "i",      name = "Tonic" }
--chord_table.min[] = { id = 369,  diatonic = true, numeral = "ii ",    name = "Supertonic" }
--chord_table.min[] = { id = 4812, diatonic = true, numeral = "III+",   name = "Mediant#" }
--chord_table.min[] = { id = 169,  diatonic = true, numeral = "iv",     name = "Sub Dominant" }
--chord_table.min[] = { id = 3812, diatonic = true, numeral = "V",      name = "Dominant" }
--chord_table.min[] = { id = 1410, diatonic = true, numeral = "vi# dim",name = "Sub Mediant" } 
chord_table.min[14] = { id = 3612, diatonic = true, numeral = "vii# dim",name = "Leading" }



--accidental minor triads
chord_table.min[15] = { id = 158,  diatonic = false, numeral = "[I]",    name = "" } 
chord_table.min[16] = { id = 3710, diatonic = false, numeral = "[II]",  name = "" }
chord_table.min[17] = { id = 4711, diatonic = false, numeral = "[iii]", name = "" }
--
chord_table.min[18] = { id = 2611, diatonic = false, numeral = "[vi]",  name = "" }
chord_table.min[19] = { id = 4712, diatonic = false, numeral = "[VII]", name = "" }


--7ths
--Natural-Minor Chromatic scale numbers:  1,3,4,6,8,9,11
--Natural Minor, 7ths
chord_table.min[20] = { id = 14811, diatonic = true, numeral = "i min7",    name = "Tonic 7th" }
chord_table.min[21] = { id = 1369,  diatonic = true, numeral = "ii-dim min7",name = "Supertonic 7th" }
chord_table.min[22] = { id = 34811, diatonic = true, numeral = "III Maj7",  name = "Mediant 7th" }
chord_table.min[23] = { id = 1469,  diatonic = true, numeral = "iv min7",  name = "Sub Dominant 7th" }
chord_table.min[24] = { id = 36811, diatonic = true, numeral = "v min7",    name = "--- minor 7th" } 
chord_table.min[25] = { id = 1489,  diatonic = true, numeral = "VI Maj7",   name = "Sub Mediant 7th" } 
chord_table.min[26] = { id = 36911, diatonic = true, numeral = "VII 7",     name = "Leading 7th" }

--Melodic-Minor Chromatic scale numbers:  1,3,4,6,8,10,12
--Melodic Minor, 7ths
chord_table.min[27] = { id = 14812, diatonic = true, numeral = "i min-Maj7",name = "Tonic 7th" }
chord_table.min[28] = { id = 13610, diatonic = true, numeral = "ii  min7",   name = "Supertonic 7th" }
chord_table.min[29] = { id = 34812, diatonic = true, numeral = "III  Maj7#5",name = "Mediant 7th#" }
chord_table.min[30] = { id = 14610, diatonic = true, numeral = "IV 7 ",     name = "Sub Dominant 7th" }
chord_table.min[31] = { id = 36812, diatonic = true, numeral = "V 7",       name = "--- minor 7th" } 
chord_table.min[32] = { id = 14810, diatonic = true, numeral = "vi# min7b5", name = "Sub Mediant 7th" } --6#dim min 7th??????
chord_table.min[33] = { id = 361012, diatonic = true, numeral = "vii# min7b5", name = "Leading 7th" } --7~ min 7th????

--Harmonic Minor, 7ths
--Harmonic-Minor chromatic scale numbers:  1,3,4,6,8,9,12
--
--chord_table.min[] = { id = 14812, diatonic = true, numeral = "i  (min-Maj 7)",name = "Tonic 7th" }       -- melodic
--chord_table.min[] = { id = 1369,  diatonic = true, numeral = "ii  (dim 7)", name = "Supertonic 7th" }    -- natural
--chord_table.min[] = { id = 34812, diatonic = true, numeral = "III  (Maj 7#5)",name = "Mediant 7th#" }    -- melodic
--chord_table.min[] = { id = 1469,  diatonic = true, numeral = "iv  (min 7) ",name = "Sub Dominant 7th" }  -- natural
--chord_table.min[] = { id = 36812, diatonic = true, numeral = "V  (D7)",  name = "Dominant 7th" }         -- melodic
--chord_table.min[36] = { id = 1489,  diatonic = true, numeral = "VI  (Maj 7)", name = "Sub Mediant 7th" } -- natural
chord_table.min[34] = { id = 36912, diatonic = true, numeral = "vii# dim7",    name = "Leading 7th" }--]]




--scale-key tables
--all 12 possible chromatic scales
local scale_table = {}

scale_table[1]  = {"A-","A#","B-","C-","C#","D-","D#","E-","F-","F#","G-","G#"}
scale_table[2]  = {"A#","B-","C-","C#","D-","D#","E-","F-","F#","G-","G#","A-"}
scale_table[3]  = {"B-","C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#"}
scale_table[4]  = {"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
scale_table[5]  = {"C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-","C-"}
scale_table[6]  = {"D-","D#","E-","F-","F#","G-","G#","A-","A#","B-","C-","C#"}
scale_table[7]  = {"D#","E-","F-","F#","G-","G#","A-","A#","B-","C-","C#","D-"}
scale_table[8]  = {"E-","F-","F#","G-","G#","A-","A#","B-","C-","C#","D-","D#"}
scale_table[9]  = {"F-","F#","G-","G#","A-","A#","B-","C-","C#","D-","D#","E-"}
scale_table[10] = {"F#","G-","G#","A-","A#","B-","C-","C#","D-","D#","E-","F-"}
scale_table[11] = {"G-","G#","A-","A#","B-","C-","C#","D-","D#","E-","F-","F#"}
scale_table[12] = {"G#","A-","A#","B-","C-","C#","D-","D#","E-","F-","F#","G-"}




------------------------------------------------
--main()
------------------------------------------------

function analyse_chords()

--default chord_table
local chosen_chord_table = chord_table.maj

--declare viewbuilder
local vb = renoise.ViewBuilder()


--local functions
-----------------------------------------------------------------------------------
--Find and analyse chord function --gets chord numeral from line using above tables
-----------------------------------------------------------------------------------

local function get_and_analyse(chord_table,scale_table,line_index,chosen_chord_table,pattern_index)

--declare current song position values
local track_index = renoise.song().selected_track_index
local current_pattern_track = renoise.song().patterns[pattern_index].tracks[track_index]

--return early if we are in Mst or Snd tracks
local track_type = renoise.song().tracks[track_index].type
if track_type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
  return
end

--declare table and conditional
local chord_to_analyse_tbl = {}
local notes_found = false

--get note strings and add to chord_to_analyse_tbl
for note_col = 1,12 do
  chord_to_analyse_tbl[note_col] = current_pattern_track:line(line_index).note_columns[note_col].note_string
  chord_to_analyse_tbl[note_col] = string.sub(chord_to_analyse_tbl[note_col], 1,2) -- get substring i.e. note name ("C-" or "OF" or "--")
 
  --Catch empty rows and for early return
  if chord_to_analyse_tbl[note_col] ~= "OF" then
    if chord_to_analyse_tbl[note_col] ~= "--" then
      notes_found = true --note found
    end
  end 
end

--only continue if notes present
if not notes_found then 
  return
end 

--get "interval index table" from names index from chord
local chord_interval_table = {}
local selected_key = scale_table[current_key] --notes of current scale
local new_value = true


for note_in_chord = 1, #chord_to_analyse_tbl do

  for i = 1,12 do --degrees in scale
    --if note values match
    if selected_key[i] == string.sub(chord_to_analyse_tbl[note_in_chord], 1,2) then
    
      for i_2 = 1, #chord_interval_table do --weed out values already added (On first pass, #chord_interval_table == 0)
        if i == chord_interval_table[i_2] then
          new_value = false
          break
        end
      end
      
      if new_value then
        table.insert(chord_interval_table,i)
      end
     
      new_value = true --reset conditional
    end
  end
end

--get number of notes in chord
local number_of_notes_in_chord = 0
if chord_interval_table then
  number_of_notes_in_chord = #chord_interval_table
end

--return early if not at least a triad (3 notes)
if number_of_notes_in_chord < 3 then
  return
end

--sort numerically (tested/works)
table.sort(chord_interval_table)

--create id, by concatinating number strings together
local interval_id_string = ""
for inc =  1,#chord_interval_table do
  interval_id_string = interval_id_string..tostring(chord_interval_table[inc])
end

--turn back to number for comparison with ids in master/reference table
local interval_id_number = tonumber(interval_id_string)

--loop through master/reference table to match id`s
for inc_2 = 1, #chosen_chord_table do
  
      if interval_id_number == chosen_chord_table[inc_2].id then
      
        --prev_chord catches repeat chords and returns "--"
        if prev_chord == interval_id_number then
          prev_chord = interval_id_number
          return chosen_chord_table[inc_2].numeral --REPEATED_CHORD 
        --else return chord roman numeral
        else
          prev_chord = interval_id_number
          return chosen_chord_table[inc_2].numeral --return val when match is found
        end
      end
      --return "?" when chord unrecognised
      if (inc_2 == #chosen_chord_table) and (number_of_notes_in_chord > 2) then
        prev_chord = interval_id_number
        return "?"
      end
    end

end --get_and_analyse() function end



-----------------------------------------
--local analyse current pattern_track fn()
-----------------------------------------

local function show_current_pattern()
--reset prev_chord
prev_chord = 0
--what key is chosen maj or min?
if vb.views["chosen mode"].value == 1 then
  chosen_chord_table = chord_table.maj
else
  chosen_chord_table = chord_table.min
end

--focus pattern editor
renoise.app().window.lock_keyboard_focus = false
renoise.app().window.lock_keyboard_focus = true

local pattern_iter = renoise.song().pattern_iterator
local pattern_index = renoise.song().selected_pattern_index
local track_index = renoise.song().selected_track_index

--clear textfield:
local track_name = renoise.song().tracks[track_index].name
vb.views["text"].text = "\nPattern: "..(pattern_index - 1).."\n"..track_name.."\n"

------------------------------
--iterate over pattern_track
------------------------------
for pos,line in pattern_iter:lines_in_pattern_track(pattern_index,track_index) do
      
  local line_index = pos.line

  --format line index to 3 digits  -- i.e add leading zeros
  local formatted_line = pos.line - 1
  formatted_line = tostring(formatted_line)
  for i = 1,3 do
    if #formatted_line == 3 then
      break     
    end
    formatted_line = "0"..formatted_line
  end 

   local pattern_index = renoise.song().selected_pattern_index
  --get_and_analyse() returns roman numeral string for chord at line_index
  local numeral = get_and_analyse(chord_table,scale_table,line_index,chosen_chord_table,pattern_index)
  
  --print on GUI
  if numeral then
   vb.views["text"].text = vb.views["text"].text.."\n  "..formatted_line..":      "..numeral
  end
       
end --interator
end --end fn

       
--------------------------------------------------------------
--GUI
--------------------------------------------------------------


local dialog_content = vb:column {                       
 
 margin = 4,
 spacing = 2,
 
   vb:column {
    style = "group",
    margin = 4,

     vb:row {
      vb:text {
       text = "Key "
      },
      
      vb:popup {
       id = "popup",
       width = 50,
       value = current_key,
       items = { "A ", "A#", "B ", "C ",
                   "C#", "D ", "D#", "E ",
                   "F ", "F#", "G ", "G#" },
         notifier = function(value)
                      current_key = value
                      --refresh GUI
                      show_current_pattern()
                    end 
        },--popup
        
        vb:text
         { width = 14
         },
        
        vb:chooser {
         items = {"Maj","Min"},
         value = maj_or_min,
         id = "chosen mode",
        
         notifier = function(value)
           maj_or_min = value
           --refresh GUI
           show_current_pattern()
         end
        
        },--column -------------------------
       }--row
      },--column
      
      vb:column { ------------export to txt
     style = "group",
     margin = 4,
     
      
      vb:popup {
         items = {"Song Track","Sequencer Selection"},
         value = song_or_selection,
         id = "Range",
         width = 126,
         notifier = function(value)
           song_or_selection = value
           
         end
        
        },
        
                         
      vb:row { --gap
       height = 2,      
      },
        
          vb:button {
      text = "Save Track To .txt",
      width = 126,
      height = 24,
      notifier = function()
 
----------------------------------------------------------------------- 
----EXPORT SELECTION Only  
-----------------------------------------------------------------------

local range_min
local range_max
local selection_range = renoise.song().sequencer.selection_range


if vb.views["Range"].value == 1 then --Whole Song Track to be exported
   range_min = 1
   range_max = #renoise.song().sequencer.pattern_sequence
elseif vb.views["Range"].value == 2 then--just selected range
  
  if selection_range[1] ~= 0 then --make sure a range is chosen
    range_min = selection_range[1]
    range_max = selection_range[2]
  else
    renoise.app():show_status("Print My Chords Tool: (Please Choose a Range To Export!)")
    return
  end
end


-- dialog
local file_out = renoise.app():prompt_for_filename_to_write(".txt", "Export Sequencer Selection Range to txt")

--if user canceled then return
if file_out == "" then
  return
end


--reset prev_CHORD
prev_chord = 0

--what key is chosen maj or min?
if vb.views["chosen mode"].value == 1 then
  chosen_chord_table = chord_table.maj
else
  chosen_chord_table = chord_table.min
end

--focus pattern editor
renoise.app().window.lock_keyboard_focus = false
renoise.app().window.lock_keyboard_focus = true

local pattern_iter = renoise.song().pattern_iterator
local pattern_index = renoise.song().selected_pattern_index
local track_index = renoise.song().selected_track_index


local xrnx_name = renoise.song().file_name
local current_track_name = renoise.song().selected_track.name

local key_type
local key


-- what key_type
key = scale_table[current_key][1]
key = string.sub(key,1,1)
if vb.views["chosen mode"].value == 1 then
  key_type = "Major"
else
  key_type = "Minor"
end

--Add song path and track name
local text = xrnx_name.."\n\n".."Track: "..current_track_name.."\n\n"..key.." "..key_type

--loop through patterns
for seq = range_min, range_max do
  --from sequencer
  local pattern = renoise.song().sequencer.pattern_sequence[seq]

  --status
  renoise.app():show_status("Print My Chords Tool: (Processing Pattern: "..(seq-1).."/"..(range_max-1)..")")
  --pattern name
  local pat_name = renoise.song().patterns[pattern].name
  --update text
  text = text.."\n\nPattern: "..(pattern - 1).."  "..pat_name.."\n"


  --iterate over pattern_track
  ------------------------------
  for pos,line in pattern_iter:lines_in_pattern_track(pattern,track_index) do
      
    local line_index = pos.line

    --format line index to 3 digits  -- i.e add leading zeros
    local formatted_line = pos.line - 1
    formatted_line = tostring(formatted_line)
    
    for i = 1,3 do
      if #formatted_line == 3 then
        break     
      end
      formatted_line = "0"..formatted_line
    end 

    --Each Line
    ---------------
    --get_and_analyse() returns roman numeral string for chord at line_index
    local numeral = get_and_analyse(chord_table,scale_table,line_index,chosen_chord_table,pattern)
  
    --print on GUI
    if numeral then
     text = text.."\n  "..formatted_line..":      "..numeral
    end     
  end --pos,line single pattern
end --for all patterns


  --export text
  ---------------
  local out = io.open(file_out, "wb")

  if out then 
    out:write(text)
   -- print(file_out)
    renoise.app():open_path(file_out)
    out:close()
  else 
     renoise.app():show_status("No text Exported!")
  end   
end --"Export Whole Track" notifier function
 -------------------------------------------------------------------------------------------------     
      
      },
     },  
                  
    vb:column { ------------Chord Display
     style = "group",
     margin = 4,
     
                         
     vb:button {
      text = "Refresh",
      width = 126,
      height = 30, 
      notifier = function()-----------------------------------------
      --------------------------------------------------------------
      show_current_pattern()
      end   
    
     },
     
    vb:row{ 
      height = 10,                   
      vb:text {
       text = "",
       font = "big",
       id = "text",
      },
    }
  }
}

--end viewbuilder
-------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- 

--initial print on GUI
show_current_pattern()

--key Handler
local function my_keyhandler_func(dialog, key)

 if key.name == "return" then
   show_current_pattern() 
   return
 end


 if not (key.modifiers == "" and key.name == "esc") then
   return key
 else
   dialog:close()
 end
end

--Only 1 dialog at a time
if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
  my_dialog:show()
  --refresh GUI
  show_current_pattern()
  return
end


-- Initiate GUI Dialog
my_dialog = renoise.app():show_custom_dialog("Print My Chords", dialog_content,my_keyhandler_func) 

--closer
local function closer(d)    
  if d and d.visible then
    d:close()
  end
end
----------------------------------------------------------------------------------------------
--Notifier to clear on pattern change
----------------------------------------------------------------------------------------------
renoise.song().selected_pattern_observable:add_notifier(
  function()
    vb.views["text"].text = ""
  end --end notifier 
  ) 

renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  


end --main


