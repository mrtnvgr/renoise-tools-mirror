local U = require 'Utilities'

local P = {}

local preferences = nil
local template_dialog = nil
local view_template_dialog = nil


function P.templates_folder()
  P.load_preferences()
  return  preferences.templates_folder.value
end


function P.load_preferences()
  preferences = renoise.Document.create("QuickTemplatePreferences") {
    templates_folder = "",
  }

  preferences:load_from("config.xml")
  P.clean_loaded_data()
  return preferences 
end

function P.clean_loaded_data()
  if preferences ~= nil then

    preferences.templates_folder.value =  string.trim(preferences.templates_folder.value)
    preferences.templates_folder.value =  string.gsub(preferences.templates_folder.value, "\/$", "")
    preferences.templates_folder.value =  string.gsub(preferences.templates_folder.value, "\\$", "")
  end
end

function P.save_preferences()
  if preferences ~= nil then
    P.clean_loaded_data()

    preferences:save_as("config.xml")
  else
  end
end

function P.template_dialog_keyhander(dialog, key)
  if key.name == "esc" then
   --  P.save_preferences()
    template_dialog:close()
  else
    return key
  end
end



function P.template_dialog_init(update_func)
  local vb = renoise.ViewBuilder()
  
  view_template_dialog = vb:column {
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,

    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Templates folder:               ",
        tooltip = "Templates",
      },
      vb:textfield {
        value = preferences.templates_folder.value,
        width = 300,
        tooltip = "Templates folder",
        id = "tempfield",
      },
      vb:button {
        text = "Choose",
        released = function()
          vb.views.tempfield.value = renoise.app():prompt_for_path("Choose template directory")
        end
      },
   },
    
    vb:horizontal_aligner {
      mode = "justify",    
      vb:button {
        text = "Save & Close",
        released = function()
          preferences.templates_folder.value = vb.views.tempfield.value
          P.save_preferences()
          template_dialog:close()
          if (update_func) then
            update_func()
          end
          renoise.app():show_status("Template preferences saved.")
        end
      },
    },

  }
end



function P.display_template_dialog(update_func)
 
  -- Remove any existing dialog
  if template_dialog then
    template_dialog = nil
  end
  
  P.load_preferences()
  P.template_dialog_init(update_func)
  template_dialog = renoise.app():show_custom_dialog("Quick Template Preferences", view_template_dialog, P.template_dialog_keyhander)
end


return P

