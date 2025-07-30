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
local sample_type = "wav"
local saving = false
local status_text = ""
local current_instrument = 1
local current_sample = 1
local ins_folders = {}
local split_folders = true

  -- create a document
local prefs = renoise.Document.create("Preferences") {
  saving_location = ""
}
renoise.tool().preferences = prefs
prefs:load_from("preferences.xml")
if prefs['saving_location'].value == "" then
  prefs['saving_location'].value = renoise.app():prompt_for_path("Store your samples to...")
  prefs:save_as("preferences.xml")
end

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------


local function save_dialog()
  local save_dialog = nil
  local vb = renoise.ViewBuilder()
  local DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = 
    renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_DIALOG_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  local TEXT_ROW_WIDTH = 80
  local type_index = 1
  
  if sample_type == 'flac' then
    type_index = 2
  end

  local textfield_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "Target location:"
    },
    vb:textfield {
      width = 240,
      id = 'pathfield',
      text = prefs['saving_location'].value,
      notifier = function(text)
        prefs['saving_location'].value = text
      end
    },
    vb:button {
      text = "Browse",
      width = 40,
      notifier = function()
         prefs['saving_location'].value = renoise.app():prompt_for_path("Store your samples to...")
         vb.views['pathfield'].text = prefs['saving_location'].value
      end,
    }
  }

  local sample_type_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "Sample type:"
    },
    vb:chooser {
      id = "sample_type",
      value = type_index,
      items = {"wav", "flac"},
      notifier = function(new_index)
        if new_index == 1 then
          sample_type = "wav"
        else
          sample_type = "flac"
        end
      end
    }
  }
    
  local checkbox_row = vb:row {
    vb:checkbox {
      id = "folder_save",
      value = split_folders,
      notifier = function(value)
        split_folders = value
      end,  
    },
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "Use separate instrument folders"
    },  
  }
  
  local button_row = vb:row {
    vb:button {
      text = "Save",
      width = 40,
      notifier = function()
        saving = true
        save_dialog:close()
      end,  
    }
  }
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:column{
      spacing = 4*CONTENT_SPACING,

      vb:row {
        spacing = CONTENT_SPACING,
        
        textfield_row
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:row{

        spacing = 15,
        sample_type_row,
        checkbox_row,
        button_row, 
      },
    }
  }
  
  save_dialog = renoise.app():show_custom_dialog(
    "Save all samples as", dialog_content
  )
      
end


function idle_handler()
  local PATH_SEPARATOR = "/"

  if (os.platform() == "WINDOWS") then
    PATH_SEPARATOR = "\\"
  end  

  local song = renoise.song()
  local available_instruments = #song.instruments
  local available_samples = -1
  local target_root = prefs['saving_location'].value

  if #ins_folders < 1 then
  
    for _ = 1, available_instruments do
      local prefix = ""
      
      if #song.instruments[_].samples > 1 and split_folders == true then
        prefix = "("..tostring(_)..") "
      end
      
      if song.instruments[_].name ~= "" then
        ins_folders[_] = prefix..song.instruments[_].name
      else
        ins_folders[_] = prefix.."Unnamed Instrument"
      end
      
      ins_folders[_] = ins_folders[_]:gsub("[%s\\/:|<>*?]+","_")
    end
    
  end
  
  if saving then
    local ins_folder = ins_folders[current_instrument]
    local samples = song.instruments[current_instrument].samples
  
    if #samples == 1 or split_folders == false then
      PATH_SEPARATOR = ""
    end

    if #samples > 1 and split_folders == false then
      ins_folder = ""
    end
    
    local target_path = target_root..ins_folder..PATH_SEPARATOR
    if samples[current_sample] ~= nil then
      if samples[current_sample].sample_buffer.has_sample_data then
        local sname = samples[current_sample].name
        sname = sname:gsub("[\\/:|<>*?]+","_")
        
        if sname == "" then
          sname = "Unnamed Sample "..tostring(current_sample)
        end
        
        if #samples == 1 then
          sname = ""
        end
        
        while io.exists(target_path..sname.."."..sample_type) do
          sname = sname.."_("..tostring(current_sample)..")" 
        end
        
        if split_folders == true then
          if not io.exists(target_root..ins_folder) and #samples > 1 then
            ok,err = os.mkdir(target_root..ins_folder)
  
            if err then
              renoise.app().show_error("Could not create "..target_root..ins_folder.." :"..err)
            end
          end
        end
        
        status_text = "Exporting "..target_path..sname.."."..sample_type
        renoise.app():show_status(status_text)
        samples[current_sample].sample_buffer:save_as(target_path..sname.."."..sample_type, sample_type)
      end
    end
    current_sample = current_sample + 1

    if current_sample > #samples then
      current_instrument = current_instrument + 1
      current_sample = 1
    end
  end
  
  if current_instrument > available_instruments then
    saving = false
    current_sample = 1
    current_instrument = 1
    renoise.app():show_status("Export finished.")
  end
end




local function save_all_instrument_samples()
  
  if not renoise.tool().app_idle_observable:has_notifier(idle_handler) then
    renoise.tool().app_idle_observable:add_notifier(idle_handler)
  end  
  
  if not saving then
    save_dialog()
  end
  
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Instrument Box:Save All Samples As...",
  invoke = save_all_instrument_samples
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
