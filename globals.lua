--------------------------------------------------------------------------------
-- global variables
--------------------------------------------------------------------------------

-- if you want to do something, each time the script gets loaded, then
-- simply do it here, in the global namespace when your tool gets loaded. 
-- The script will start running as soon as Renoise started, and stop running 
-- as soon as it closes. 
--
-- IMPORTANT: this also means that there will be no song (yet) when this script 
-- initializes, so any access to app().current_document() or song() will fail 
-- here.
-- If you really need the song to initialize your application, do this in
-- the notifications.app_new_document functions or in your action callbacks...

XRNS2XMOD_URL = "https://github.com/fstarred/xrns2xmod/";
XRNS2XMOD_EXE = "Xrns2XModShell.exe";
XRNS2XMOD_DOC_URL = "https://github.com/fstarred/xrns2xmod/wiki";
XRNS2XMOD_TUTORIAL_VIDEO_URL = "http://www.youtube.com/playlist?list=PLZZHTXBWLnp8L60rT10UOZCqe0m5J9Uyr";
XRNS2XMOD_VERSION_INFO_URL = 'http://starredmediasoft.com/xrns2xmod_updater.xml'

-- helper
VALIDATION_XM = 1
VALIDATION_MOD_EXT = 2
VALIDATION_MOD_AMIGA = 3
VALIDATION_NONE = 4

TYPE_XM = 1
TYPE_MOD = 2

DEFAULT_BPM = 125
DEFAULT_TICKS_ROW = 6

DEFAULT_PORTAMENTO_ACCURACY_THRESHOLD = 2

VOLUME_SCALING_NONE = 1
VOLUME_SCALING_SAMPLE = 2
VOLUME_SCALING_COLUMN = 3

PROTRACKER_COMPATIBILITY_MODE_NONE = 1
PROTRACKER_COMPATIBILITY_MODE_SOFTWARE = 2
PROTRACKER_COMPATIBILITY_MODE_HARDWARE = 3

FREQ_PAL = 1
FREQ_NTSC = 2

NOTES_TABLE = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" };

MSG_NOTE_RANGE_WARNING = 'Xrns2XMod warning message:\n\nNote %s is out of range\nValid range detected for this sample (current %s freq: %sHz): %s - %s;\nTo solve this issue, do one of the following: \n-Adjust sample rate from Xrns2XMod >> Instrument Settings >> [Adjust sample rate] \n- Adjust sample rate of the current sample\n\nThis warning can be disabled by selecting \'None\' on \'Range note validation\' of Helper window'
MSG_SONG_NOT_SAVED = "Save song is required";
MSG_APP_NOT_FOUND = "Please locate Xrns2XMod application path from Control Panel";
MSG_RESOURCE_NOT_FOUND = "Resource not found";

LOG_FILENAME = "log.txt";

MAX_BPM = 512

-- dialogs
vb = nil
helper_dialog = nil
converter_dialog = nil
controlpanel_dialog = nil
downgrade_dialog = nil
instrument_settings_dialog = nil
latest_version_dialog = nil

app_path = "";
is_app_located = false;
-- converter
conv_type_value = TYPE_XM;
output_file = "";
convfreq = false;
--ptmode = false;
pt_comp_mode = PROTRACKER_COMPATIBILITY_MODE_HARDWARE
pt_freq_mode = FREQ_PAL
volume_scaling = VOLUME_SCALING_SAMPLE
initial_tempo = DEFAULT_BPM
initial_ticks = DEFAULT_TICKS_ROW
portamento_accuracy_threshold = DEFAULT_PORTAMENTO_ACCURACY_THRESHOLD
-- bass_net
bass_email = ""
bass_code = ""
-- helper
fmt_note_validation = VALIDATION_NONE
g_default_volume = 64
-- control panel
enable_note_validation = true
enable_instrument_settings = false

notifier = {}
  function notifier.add(observable, n_function)
    if not observable:has_notifier(n_function) then
      observable:add_notifier(n_function)
    end
  end

  function notifier.remove(observable, n_function)
    if observable:has_notifier(n_function) then
      observable:remove_notifier(n_function)
    end
  end

--------------------------------------------------------------------------------
-- global functions
--------------------------------------------------------------------------------



local function close_instrument_settings()

  -- force instrument settings dialog to close for any instrument change
  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:close()
  end  

end



-- trigger on any instrument change
local function instrument_change_notifier(action) 
      
  local action_type = action['type']
  local index = action['index']
      
  if action_type then
  
    if action_type == 'insert' then
      if renoise.song().instruments[index] then
        -- attach notifier for any sample changes in existing instrument
        notifier.add(renoise.song().instruments[index].samples_observable, close_instrument_settings)
      end
    --[[    
    elseif action_type == 'remove' then
      -- remove notifier for any sample changes in existing instrument
      notifier.remove(renoise.song().instruments[index].samples_observable, close_instrument_settings)
    ]]
    end        
  end
  
  close_instrument_settings()
  
end


function toggle_notifier_for_note_validation(value)

  local func_notifier = value and notifier.add or notifier.remove
  
  -- attach notifier for any pattern changes in song (insert, delete)
  func_notifier(renoise.song().patterns_observable, attach_pattern_changes)
  
  -- attach notifier for any changes in existing pattern
  for var = 1, table.count(renoise.song().patterns), 1 do
    if value and renoise.song().patterns[var]:has_line_notifier(line_changes_notifier) == false then            
        renoise.song().patterns[var]:add_line_notifier(line_changes_notifier)      
    elseif value == false and renoise.song().patterns[var]:has_line_notifier(line_changes_notifier) then
        renoise.song().patterns[var]:remove_line_notifier(line_changes_notifier)
    end    
  end    
  
end

function toggle_notifier_for_instrument_settings(value)

  local func_notifier = value and notifier.add or notifier.remove

  -- attach notifier for any instruments changes
  func_notifier(renoise.song().instruments_observable, instrument_change_notifier)
  
  -- attach notifier for any sample changes in existing instrument
  for k, v in ipairs( renoise.song().instruments ) do
  
    func_notifier(renoise.song().instruments[k].samples_observable, instrument_change_notifier)
  
  end  
  
end


function check_app_location()

  if (app_path ~= "") then    
    is_app_located = io.exists(app_path);
  end
  
  --[[
  if (is_app_located == false) then
    renoise.app():show_warning(MSG_APP_NOT_FOUND);
  end 
  ]] 
  
  return is_app_located;
end

function is_not_new_song()

  local input_file = renoise.song().file_name;    
  
  return input_file ~= ""  

end

function is_windows_os()
  return os.platform() == "WINDOWS"
end

-- get app path directory without filename
function get_path(str)
    local sep = get_separator()
    
    local match = str:match("(.*"..sep..")")
    if match ~= nil then 
      match = match:sub(1, match:len() - sep:len())
    end    
    return match
end

function get_separator()
  return is_windows_os() and '\\' or '/'
end

function concatenate_path(path_array)
  
  local separator = get_separator()
  
  local output_path = '';
  
  for k, v in ipairs(path_array) do         
    if output_path ~= '' then
      output_path = output_path .. separator 
    end
    output_path = output_path .. path_array[k]        
  end
  
  return output_path
  
end

function get_resource_path()

  local path_folder = get_path(app_path)  
  
  local arr = {path_folder, 'resources'};
  
  local output_folder = concatenate_path(arr)
  
  return output_folder
    
end

