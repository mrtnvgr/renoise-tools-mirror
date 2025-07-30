renoise.tool():add_keybinding {
  name = "Global:Tools:Set Meta Values",
  invoke = function()main()end
  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Set Meta Values",
  invoke = function()main()end
  
}


local my_dialog = nil 

local hex_table = {"Clear Selection","00"}
local hex_table_del = {"Clear Selection","00"}

--populate vol,pan table
for i = 3,129 do
  hex_table[i] = string.format("%X",(i-2))
  --add leading zeros to single digits
  if #hex_table[i] < 2 then
    hex_table[i] = "0"..hex_table[i]
  end
end

--populate delay table
for i = 3,257 do
  hex_table_del[i] = string.format("%X",(i-2))
   --add leading zeros to single digits
  if #hex_table_del[i] < 2 then
    hex_table_del[i] = "0"..hex_table_del[i]
  end
end

-------------------------------------------------------
--main
-------------------------------------------------------

function main()


local string_holder = {}
local pattern_iter = renoise.song().pattern_iterator
local pattern_index = renoise.song().selected_pattern_index

local vb = renoise.ViewBuilder()
local NOTE_OFF = 120

-- only allows one dialog instance
if (my_dialog and my_dialog.visible) then 
  my_dialog:show()
  return
end


-------------------------------------------------------
--local functions
-------------------------------------------------------
--closer fn
local function closer(d)

  if d and d.visible then             
      d:close()
  end
end

--Get no of tracks
local function get_number_of_tracks() 

local track_table = renoise.song().tracks
local note_tracks = 0  --incrementor
local NOTE_TRACK = 1
local GROUP_TRACK = renoise.Track.TRACK_TYPE_GROUP

  for _,track in ipairs(track_table) do
   
    if track.type == NOTE_TRACK or
      track.type == GROUP_TRACK
    then
      note_tracks = note_tracks + 1
    end    
  end   
 return note_tracks
end


--------------------------------------------------------
--GUI
--------------------------------------------------------
local dialog_content = 

vb:vertical_aligner {
 margin = 8,
 mode = "center",
  
 

  --see typed 
   vb:row {
   style = "group",
  -- width = 100,                   
    vb:text {
     id = "text",
     width = 100,
    }
   },
  --hex value 
  vb:popup {
   id = "popup_hex",
   width = 100,
   value = 1,
   items = hex_table,
  },
  --chosen scope                      
  vb:popup {
   id = "popup",
   width = 100,
   value = 1,
   items = { "[v] Velocity","[p] Pan","[l] Delay"},
   notifier = function(number)
      if number == 3 then
        vb.views["popup_hex"].items = hex_table_del
      else
        vb.views["popup_hex"].items = hex_table
      end
    end
  },
}



---------------------------------------------------------
--keyhandler
---------------------------------------------------------
--oprint(key)

--[character] =>  w
--[modifiers] =>  
--[name] =>  w
--[note] =>  14
--[repeated] =>  false



local function my_keyhandler_func(dialog, key)


pattern_index = renoise.song().selected_pattern_index
--esc to close
if (key.modifiers == "" and key.name == "esc") then
  closer(my_dialog)
  return
end

--convert lower case letters to upper
if key.character and string.upper(key.character) then
  key.character = string.upper(key.character)
end

--choose popup value (vol,pan,dly)
if key.character then
  if string.lower(key.character) == "v" then
   vb.views["popup"].value = 1 --vel
   return
  end

  if string.lower(key.character) == "p" then
   vb.views["popup"].value = 2 --pan
   return
  end

  if string.lower(key.character) == "l" then
   vb.views["popup"].value = 3 --dly
   return
  end  
  
end
 
--filter characters
local allowed_char = false

if (key.name == "return") or (key.name == "numpad enter") then
  allowed_char = true
elseif key.name == "." then
  allowed_char = true
elseif key.character == "A" then
  allowed_char = true
elseif key.character == "B" then
  allowed_char = true 
elseif key.character == "C" then
  allowed_char = true 
elseif key.character == "D" then
  allowed_char = true
elseif key.character == "E" then
  allowed_char = true
elseif key.character == "F" then
  allowed_char = true
elseif (allowed_char == false) and (tonumber(key.character) == nil) then
  return
end
 
--vars
local typed_number_string = ""
local typed_number_value = nil

--capture string in table
if key.character  then 
  if #string_holder < 2 then --two characters only
    table.insert(string_holder,key.character) --add character to string_holder table
    vb.views["text"].text = vb.views["text"].text..string_holder[#string_holder] --update gui
  else --else start again
    vb.views["text"].text = ""
    vb.views["text"].text = key.character
    string_holder = {key.character}
    return
  end
end


--create number string from table: string_holder
for i = 1,#string_holder do
  if string_holder[i] then
    typed_number_string = typed_number_string..string_holder[i]
  end
end



if #typed_number_string < 2 then
  typed_number_string = "0"..typed_number_string
end

--match number to hex
local holder = 1

if vb.views["popup_hex"].value < 3 then
  for i = 2,130 do
    if hex_table[i] == typed_number_string then
      holder = i
      break
    end
  end
else --delay column  
  for i = 2,258 do
    if hex_table_del[i] == typed_number_string then
      holder = i
      break
    end
  end 
end  

if holder then
  if vb.views["popup"].value < 3 and holder > 129 then --lower max if vel,pan chosen after delay
    holder = 129
  end
  vb.views["popup_hex"].value = holder --set view to holder
end

--sets to clear value (i.e. 255)
if holder == 1 and vb.views["popup"].value < 3 then
  holder = 257
end


--print(holder)
--execute
if (key.name == "return") or (key.name == "numpad enter") then

  for track_index = 1,get_number_of_tracks() do
    for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index) do
      if line.note_value < NOTE_OFF then
        if line.is_selected  then
        --set vol, pan, dly to all subsequent notes 
            
            if vb.views["popup"].value == 1 then
              if not renoise.song().tracks[track_index].volume_column_visible then
                renoise.song().tracks[track_index].panning_volume_visible = true
              end
              line.volume_value = holder - 2
            end
            if vb.views["popup"].value == 2 then
              if not renoise.song().tracks[track_index].panning_column_visible then
                renoise.song().tracks[track_index].panning_column_visible = true
              end
              line.panning_value = holder - 2
            end
            if vb.views["popup"].value == 3 then
              if not renoise.song().tracks[track_index].delay_column_visible then
                renoise.song().tracks[track_index].delay_column_visible = true
              end
              if holder > 1 then --clear
                line.delay_value = holder - 2
              else
                line.delay_string = ".."
              end
              
            end         
        end
      end
    end
  end

--clear
typed_number_string = ""
string_holder = {}
--vb.views["text"].value = ""
closer(my_dialog)
end

end --key handler


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Script dialog
my_dialog = renoise.app():show_custom_dialog(
    "Set Meta Value", dialog_content,my_keyhandler_func)



end --main






