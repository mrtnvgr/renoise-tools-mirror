--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

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

-- gloabl variables
rawset(_G, "start_value", 100)
rawset(_G, "end_value", 100)  
rawset(_G, "process_notes", true)


local function showStatus(text)
  renoise.app():show_status(tool_name..": "..text)
end

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function process(start_value, end_value, process_notes)
  if renoise.song().selection_in_pattern == nil then
    showStatus("No selection on current pattern")
    return
  end
  local startLine = renoise.song().selection_in_pattern.start_line
  local endLine = renoise.song().selection_in_pattern.end_line
  local startTrack = renoise.song().selection_in_pattern.start_track
  local endTrack = renoise.song().selection_in_pattern.end_track
  local startColumn = renoise.song().selection_in_pattern.start_column
  local endColumn = renoise.song().selection_in_pattern.end_column 
  
  local function valueMultiplier(line)
    return (start_value - ((line - 1) * ((start_value - end_value) / (endLine - (startLine - 1))))) / 100
  end 
    
  local selectedPattern = renoise.song().selected_pattern
  for t = startTrack, endTrack do
    local track = selectedPattern.tracks[t]
    if t ~= endTrack then
      endColumn = renoise.song().tracks[t].visible_note_columns
    else 
      endColumn = renoise.song().selection_in_pattern.end_column
    end 
    for c = startColumn, endColumn do  
      local lineIndex = 1      
      for l = startLine, endLine do
        if track.lines[l].note_columns[c] ~= nil then
          local volume = track.lines[l].note_columns[c].volume_value
          local note = track.lines[l].note_columns[c].note_value
          local isEmpty = false
          local isNote = note ~= 120 and note ~= 121
          if volume == 255 then
            isEmpty = true
            if isNote or not process_notes then          
              volume = 127
             end
          end        
          local newVolume = valueMultiplier(lineIndex) * volume
          if isNote or not process_notes then
            if newVolume < 127 then
              track.lines[l].note_columns[c].volume_value = valueMultiplier(lineIndex) * volume
            else
              track.lines[l].note_columns[c].volume_value = 127
            end        
            if isEmpty then
              if track.lines[l].note_columns[c].volume_value == 127 then
                track.lines[l].note_columns[c].volume_value = 255
              end
            end
          end
          lineIndex = lineIndex + 1        
        end
      end
    end
  end    
end

local function clear(isNoteOnly)
  if renoise.song().selection_in_pattern == nil then
    showStatus("No selection on current pattern")
    return
  end
  local startLine = renoise.song().selection_in_pattern.start_line
  local endLine = renoise.song().selection_in_pattern.end_line
  local startTrack = renoise.song().selection_in_pattern.start_track
  local endTrack = renoise.song().selection_in_pattern.end_track
  local startColumn = renoise.song().selection_in_pattern.start_column
  local endColumn = renoise.song().selection_in_pattern.end_column 
  
    
  local selectedPattern = renoise.song().selected_pattern
  for t = startTrack, endTrack do
    local track = selectedPattern.tracks[t]
    if t ~= endTrack then
      endColumn = renoise.song().tracks[t].visible_note_columns
    else 
      endColumn = renoise.song().selection_in_pattern.end_column
    end 
    for c = startColumn, endColumn do  
      local lineIndex = 1      
      for l = startLine, endLine do
        if track.lines[l].note_columns[c] ~= nil then
          local volume = track.lines[l].note_columns[c].volume_value
          local note = track.lines[l].note_columns[c].note_value
          local isEmpty = false
          local isNote = note ~= 120 and note ~= 121
          if volume == 255 then
            isEmpty = true
          end                
          if isNote then
            volume = 255
          else
            if not isNoteOnly and not isEmpty then
              volume = 255 
            end
          end
          track.lines[l].note_columns[c].volume_value = volume
          lineIndex = lineIndex + 1
        end
      end      
    end
  end    
end

--------------------------------------------------------------------------------
-- Process automation
--------------------------------------------------------------------------------

local function processAutomation(start_value, end_value)
  local patternTrack = renoise.song().selected_pattern.tracks[renoise.song().selected_track_index] 
  local selectedParameter = renoise.song().selected_parameter

  if (selectedParameter) then
    local automation = current_pattern_track:find_automation(selected_parameter)
  end
  
  if automation == nil then
    return
  end
  
  --[[if renoise.song().selection_in_pattern == nil then
    return
  end
  local startLine = renoise.song().selection_in_pattern.start_line
  local endLine = renoise.song().selection_in_pattern.end_line
  local startTrack = renoise.song().selection_in_pattern.start_track
  local endTrack = renoise.song().selection_in_pattern.end_track
  local startColumn = renoise.song().selection_in_pattern.start_column
  local endColumn = renoise.song().selection_in_pattern.end_column
  
  -- Nothing to do if only one line selected
  if startLine == endLine then
    return
  end
  
  local function valueMultiplier(line)
    return (start_value - ((line - 1) * ((start_value - end_value) / (endLine - (startLine - 1))))) / 100
  end 
    
  local selectedPattern = renoise.song().selected_pattern
  for t = startTrack, endTrack do
    local track = selectedPattern.tracks[t]
    if t ~= endTrack then
      endColumn = renoise.song().tracks[t].visible_note_columns
    else 
      endColumn = renoise.song().selection_in_pattern.end_column
    end 
    for c = startColumn, endColumn do  
      local lineIndex = 1      
      for l = startLine, endLine do
        local volume = track.lines[l].note_columns[c].volume_value
        local note = track.lines[l].note_columns[c].note_value
        local isEmpty = false
        local isNote = note ~= 120 and note ~= 121
        if volume == 255 then
          isEmpty = true
          if isNote then          
            volume = 127
           end
        end        
        local newVolume = valueMultiplier(lineIndex) * volume
        if isNote then
          if newVolume < 127 then
            track.lines[l].note_columns[c].volume_value = valueMultiplier(lineIndex) * volume
          else
            track.lines[l].note_columns[c].volume_value = 127
          end        
          if isEmpty then
            if track.lines[l].note_columns[c].volume_value == 127 then
              track.lines[l].note_columns[c].volume_value = 255
            end
          end
        end
        lineIndex = lineIndex + 1
      end      
    end
  end]]--    
end

--------------------------------------------------------------------------------
-- shortcut functions
--------------------------------------------------------------------------------
local function fadeIn()
  process(0, 100, process_notes)
end
local function fadeOut()
  process(100, 0, process_notes)
end  
local function halve()
  process(50, 50, process_notes)    
end  
local function double()
  process(200, 200, process_notes)
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()


  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local BUTTON_WIDTH = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DIALOG_WIDTH = 200
  --declare(end_value, 100)
  --print(start_value)

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
    margin = DEFAULT_MARGIN,
        -- Validation button
    vb:horizontal_aligner {
      mode = "center",
      vb:button {
        text = "Fade In",
        width = DIALOG_WIDTH / 4 + 10,
        height = 24,        
        notifier = function()
          fadeIn()
        end
      },
      vb:button {
        text = "Fade Out",
        width = DIALOG_WIDTH / 4 + 10,
        height = 24,        
        notifier = function()
          fadeOut()
        end
      },
      vb:button {
        text = "Halve",
        width = DIALOG_WIDTH / 4 + 10,
        height = 24,        
        notifier = function()
          halve()
        end
      },    
      vb:button {
        text = "Double",
        width = DIALOG_WIDTH / 4 + 10,
        height = 24,        
        notifier = function()
          double()
        end
      }
    },                 
    vb:column {
      -- background that is usually used for "groups"
      style = "group",
      margin = 10,          
      vb:row {
        vb:text {
          text = "Start: "
        },
        vb:valuebox {
          min = 0,
          max = 1000,
          value = start_value,
          notifier = function(value)
            start_value = value
            print(start_value)
          end
        },
        vb:text {
          text = "%"
        },
        vb:text {
          text = "End: "
        },
        vb:valuebox {
          min = 0,
          max = 1000,
          value = end_value,
          notifier = function(value)
            end_value = value
            print(end_value)
          end
        },
        vb:text {
          text = "%"
        }                
      }
    },
    vb:column {      
      style = "body",
      margin = 1,  
      width = DIALOG_WIDTH,
      vb:horizontal_aligner {         
        vb:checkbox {
          --value = true
          value = process_notes,
          notifier = function(checked)
            process_notes = checked
          end                    
          --notifier = function()
          --process(start_value, end_value)                  
          -- end
        },
        vb:text {
          -- dirty, not willing to spend hours in UI management...
          text = "Process notes only                "
        },
        vb:button {
          text = "Clear volume",
          height = 20,
          notifier = function()        
            clear(process_notes)
          end          
        }        
      }
    },
    -- Validation button
    vb:horizontal_aligner {
      mode = "center",      
      vb:button {
        text = "Ok",
        width = DIALOG_WIDTH / 4 + 30,
        height = 24,        
        notifier = function()
        process(start_value, end_value, process_notes)                  
        end
      },
      vb:button {
        text = "Close",
        width = DIALOG_WIDTH / 4 + 30,
        height = 24,        
        notifier = function()        
          dialog:close()
        end
      },      
      vb:button {
        text = "Undo",
        width = DIALOG_WIDTH / 4 - 10,
        height = 24,        
        notifier = function()
          renoise.song():undo()
        end
      },      
      vb:button {
        text = "Redo",
        width = DIALOG_WIDTH / 4 - 10,
        height = 24,        
        notifier = function()
          renoise.song():redo()
        end
      }      
    }    
  }    
  
  local buttons = {"OK"}
  --local dialog_buttons = {"OK"}   
  
  --------------------------------------------------------------------------------
  -- key handler
  --------------------------------------------------------------------------------
  local function key_handler(dialog, key)
    if key.name == "return" or key.name == "numpad enter" then
      process(start_value, end_value, process_notes)
      dialog:close()    
    elseif key.name == "esc" then
      dialog:close()
    -- shortcuts       
    elseif key.name == "1" then      
      if key.modifiers == "control" then
        fadeIn()        
      elseif key.modifiers == "" then
        fadeIn()
        dialog:close()
      end
    elseif key.name == "2" then
      if key.modifiers == "control" then
        fadeOut()        
      elseif key.modifiers == "" then
        fadeOut()
        dialog:close()
      end
    elseif key.name == "3" then
      if key.modifiers == "control" then
        halve()        
      elseif key.modifiers == "" then
        halve()
        dialog:close()
      end      
    elseif key.name == "4" then
      if key.modifiers == "control" then
        double()        
      elseif key.modifiers == "" then
        double()
        dialog:close()
      end      
    else
      return key
    end
  end  
  
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content, key_handler)  
  
  
  -- A custom prompt is a modal dialog, restricting interaction to itself. 
  -- As long as the prompt is displayed, the GUI thread is paused. Since 
  -- currently all scripts run in the GUI thread, any processes that were running 
  -- in scripts will be paused. 
  -- A custom prompt requires buttons. The prompt will return the label of 
  -- the button that was pressed or nil if the dialog was closed with the 
  -- standard X button.  
  --[[ 
    local buttons = {"OK", "Cancel"}
    local choice = renoise.app():show_custom_prompt(
      tool_name, 
      content, 
      buttons
    )  
    if (choice == buttons[1]) then
      -- user pressed OK, do something  
    end
  --]]
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
