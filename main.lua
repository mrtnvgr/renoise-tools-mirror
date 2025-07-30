--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

--Note-matrix attributes
note_matrix = {
   [1]='C', [2]='D', [3]='E', [4]='F', [5]='G', [6]='A',
   [7]='B'
}

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value
local ins_figure = 1

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

function key_handler(dialog, key)
  local note_column = renoise.song().selected_note_column_index

  local track = renoise.song().selected_track_index
  local line = renoise.song().selected_line_index
  local pattern = renoise.song().selected_pattern_index
  local selected_line = renoise.song().patterns[pattern].tracks[track].lines[line]
  local note = nil
  if note_column >= 1 then
    note = selected_line.note_columns[note_column].note_string
  end
  
  local pattern_size = renoise.song().patterns[pattern].number_of_lines
  local max_tracks = renoise.song().sequencer_track_count
  local alter = true
 
  -- close on escape...
  if (key.modifiers == "" and key.name == "esc") then
    dialog:close()
    ins_figure = 1

  -- Let's send the text-line contents if present
  elseif (key.name == "return") then
  
  -- update key_text to show what we got
  elseif (key.name == "back") then

  elseif (key.name == "del") then
    ins_figure = 1
    if note ~= nil then
      note = "---"
    end
  elseif (key.name == "down") then
    ins_figure = 1
    if line + 1 <= pattern_size then
      line = line + 1
    else
      line = 1
    end
    renoise.song().selected_line_index = line 
    alter = false

  elseif (key.name == "up") then
    ins_figure = 1
    if line - 1 >= 1 then
      line = line - 1 
    else 
      line = pattern_size
    end

    renoise.song().selected_line_index = line 
    alter = false

  elseif (key.name == "left") then
    ins_figure = 1
    if renoise.song().selected_track_index - 1 >= 1 then
      renoise.song().selected_track_index = renoise.song().selected_track_index - 1
    else
      renoise.song().selected_track_index = max_tracks
    end
    alter = false
    
  elseif (key.name == "right") then
    ins_figure = 1
    if renoise.song().selected_track_index + 1 <= max_tracks then
      renoise.song().selected_track_index = renoise.song().selected_track_index + 1
    else
      renoise.song().selected_track_index = 1
    end
    alter = false

  elseif (key.modifiers == "" and key.name == "tab") then
    ins_figure = 1

    if note_column + 1 <= (renoise.song().tracks[track].visible_note_columns) then
      note_column = note_column + 1
    else
      note_column = 1
    end
    renoise.song().selected_note_column_index = note_column
    alter = false

  elseif (key.modifiers == "shift" and key.name == "tab") then
    ins_figure = 1
    if note_column - 1 >= 1 then
      note_column = note_column - 1
    else
      note_column = renoise.song().tracks[track].visible_note_columns
    end
    renoise.song().selected_note_column_index = note_column
    alter = false
    
  elseif key.character ~= nil then
    if note == nil then
      return key
    end
    for x = 1, 7 do
      if string.upper(key.character) == note_matrix[x] then
        note = key.character..string.sub(note,2,3)
        ins_figure = 1
      end
    end
    for x = 0, 9 do
      if key.character == tostring(x) then
        if string.lower(string.sub(key.name,1,3)) ~= "num" then
          note = string.sub(note,1,2)..key.character
          ins_figure = 1
        else
          local ins_num = tostring(selected_line.note_columns[note_column].instrument_value)
          if ins_figure == 1 then
            ins_num = "00"
            ins_num = key.character..string.sub(ins_num,2,2)
            ins_figure = 2
          else
            if ins_num == ".." then
              ins_num = "00"
            end
            ins_num = string.sub(ins_num,1,1)..key.character
            ins_figure = 1
          end
          selected_line.note_columns[note_column].instrument_value = tonumber(ins_num)
          
        end
      end

    end

    --This is where you can define the key to change the flag of the note
    if key.character == "-" or key.character == "q" then
      ins_figure = 1
      if string.sub(note,2,2) == "-" then
        note = string.sub(note,1,1).."#"..string.sub(note,3,3)
      else
        note = string.sub(note,1,1).."-"..string.sub(note,3,3)
      end
    end
    
  end

  if note == nil then
    return key
  end

  if string.sub(note,3,3) == "-" and string.sub(note,1,1) ~= "-" then
    note = string.sub(note,1,2).."4"
  end
  if string.sub(note,2,2) == "#" and string.sub(note,1,1) == "-" then
    note = "---"
  end
  if string.sub(note,1,1) == "-" and string.sub(note,3,3) ~= "-" then
    note = "C"..string.sub(note,2,3)
  end
  if alter == true then  
    selected_line.note_columns[note_column].note_string = note
  end
  
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  
  -- The content of the dialog, built with the ViewBuilder.
  local content = vb:column {
    margin = 10,
    vb:text {
      width = 40,
      text = ":p, whack the letters for the notes,\nfigures for the octaves\nNumpad figures for instrument\nand the '-' or 'q' key for the flag change\ntab/shift tab to switch notecolumns,\nleft/right to switch tracks\nup/down to browse lines",

    }
    
  } 
  
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content, key_handler)  

end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = show_dialog  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
