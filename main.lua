--[[============================================================================
de.virtualcreations.QuickTemplate.xrnx/main.lua
============================================================================]]--

local menu_prefix = "Quick Template"
local path_slash = "/"
local song_suffix = '.xrns'
local new_project_name = "New project"

local Prefs = require 'Preferences'
local preferences = Prefs.load_preferences()
local entries = {}
local is_template = false

if (os.platform() == "WINDOWS") then
  path_slash = "\\"
end


function load_template_file(template_name) 
  is_template = string.gsub(template_name, song_suffix.."$", "")
  renoise.app():load_song(preferences.templates_folder.value .. path_slash .. template_name)
end
function init_template() 
  if (is_template) then
    renoise.song().name = new_project_name
    renoise.app():save_song_as(preferences.templates_folder.value .. path_slash .. new_project_name .. " (" ..is_template  .. ")" .. song_suffix) 
  end
  is_template = false
end

function update_main_menu()
  preferences = Prefs.load_preferences()
  if (preferences.templates_folder.value == "") then
    return
  end
  if (not io.exists(preferences.templates_folder.value)) then
   return
  end
  local template_files = os.filenames(preferences.templates_folder.value, song_suffix )
  for c in pairs(entries) do
    if (renoise.tool():has_menu_entry(entries[c])) then
      renoise.tool():remove_menu_entry(entries[c])
    end
  end
  entries = {}
  local c = 0
  for i in pairs(template_files) do
    local temp_filename = string.gsub(template_files[i], song_suffix.."$", "")
    local temp_name =("Main Menu:File:"..menu_prefix..":"  ..temp_filename)
    if (string.find(temp_filename, new_project_name) == nil) then 
      entries[c] = temp_name
      c = c+1
      renoise.tool():add_menu_entry {
        name = temp_name,
        invoke = function() load_template_file(template_files[i]) end 
      }
    end
  
  end 

end

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:" .. menu_prefix .. "...",
  invoke = function() Prefs.display_template_dialog(update_main_menu) end
}

update_main_menu() 

-- observables
if (not renoise.tool().app_became_active_observable:has_notifier(update_main_menu)) then
  renoise.tool().app_became_active_observable:add_notifier(update_main_menu)
end
if (not renoise.tool().app_saved_document_observable:has_notifier(update_main_menu)) then
  renoise.tool().app_saved_document_observable:add_notifier(update_main_menu)
end
if (not renoise.tool().app_new_document_observable:has_notifier(init_template)) then
  renoise.tool().app_new_document_observable:add_notifier(init_template)
end



