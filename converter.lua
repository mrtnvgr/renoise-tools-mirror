require "bass_net"
require "converter_gui"


--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------

local MSG_NEW_PLAYBACK_MODEL_DETECTED = "Warning: new timing model detected: it is strongly reccomanded to use old timing model instead (where tpl is used as speed factor). Choose \"downgrade song\" menu to reverese the current song"

--XML_URL_VERSION = "http://dl.dropbox.com/u/55285635/xrns2xmod_updater.xml";  

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
timing_model_message_already_shown = false;

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

function init_converter_dialog()

  if is_app_located == false then 
    renoise.app():show_warning(MSG_APP_NOT_FOUND);
    init_controlpanel_dialog()
    return
  end
  
  show_converter_dialog();
  
  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel_dialog:close()
  end
  
  if helper_dialog and helper_dialog.visible then
    helper_dialog:close()
  end
  
  if downgrade_dialog and downgrade_dialog.visible then
    downgrade_dialog:close()
  end
  
  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:close()
  end

end

--[[
function check_timing_model()

  if timing_model_message_already_shown then
    return
  end

  local timing_model = renoise.song().transport.timing_model;    
  ]]
  --[[
  if timing_model == renoise.Transport.TIMING_MODEL_LPB then
    timing_model_message_already_shown = true;
    renoise.app():show_warning(MSG_NEW_PLAYBACK_MODEL_DETECTED)  
  end 
  --]]   
--[[
end
]]

function start_conversion()

  -- check_timing_model();
  
  local input_file = renoise.song().file_name;
  
  if (input_file == "") then
    renoise.app():show_error(MSG_SONG_NOT_SAVED);
    return;
  end
  
  if (output_file == "") then
    output_file = save_dialog_file();
    
    if (output_file == "") then 
      return 
    end
  end
  
  local ret = call_executable(input_file);  
  
  local msg = read_log();
  
  show_conversion_log_dialog(msg);
  
end

function read_log()

  local log_message = "";
     
  if io.exists(LOG_FILENAME) then    
  
    for line in io.lines(LOG_FILENAME) do 
      log_message = log_message .. line .. '\n';
    end  
    
    os.remove(LOG_FILENAME);
  end 
  
  return log_message;

end

local function get_dest_format(value)
  return conv_type_value == TYPE_XM and "xm" or "mod"
end

function call_executable(input_file)

  local ret = 0;
  
  local app_cmd = "";  
  local args = "";  
  local conv_type = get_dest_format(conv_type_value)

  app_cmd = app_cmd .. app_path ;
  
  args = " -type " .. conv_type;  
  
  --[[
  if (convfreq) then
    args = args .. " -convfreq ";
  end
  ]]
  
  -- deprecated
  -- args = args .. ' -ptmode=' .. (ptmode and 'true' or 'false') 
  
  if pt_comp_mode == PROTRACKER_COMPATIBILITY_MODE_NONE then
    args = args .. " -ptmode=N "
  elseif pt_comp_mode == PROTRACKER_COMPATIBILITY_MODE_SOFTWARE then
    args = args .. " -ptmode=S "
  elseif pt_comp_mode == PROTRACKER_COMPATIBILITY_MODE_HARDWARE then
    args = args .. " -ptmode=H "
  end
  
  if pt_freq_mode == FREQ_PAL then
    args = args .. " -ntsc=false "
  elseif pt_freq_mode == FREQ_NTSC then
    args = args .. " -ntsc=true "
  end
  
  --args = args .. ' -ptmode=' .. (ptmode and 'true' or 'false')
  
  args = args .. ' -portresh=' .. portamento_accuracy_threshold
    
  if volume_scaling == VOLUME_SCALING_NONE then
    args = args .. " -volumescaling=N "
  elseif volume_scaling == VOLUME_SCALING_SAMPLE then
    args = args .. " -volumescaling=S "
  elseif volume_scaling == VOLUME_SCALING_COLUMN then
    args = args .. " -volumescaling=C "
  end
  
  if (bass_email ~= "") then
    args = args .. " -bass_email " .. bass_email;
  end
  
  if (bass_code ~= "") then
    args = args .. " -bass_code " .. bass_code;
  end

  args = args .. " -tempo " .. initial_tempo
  
  args = args .. " -ticks " .. initial_ticks
  
  args = args .. " -log " .. LOG_FILENAME;  
  
  os.remove(output_file);
  
  local command_line = nil;
  
  if is_windows_os() then
    command_line = string.format('""%s" "%s" %s -out "%s""', app_cmd, input_file, args, output_file)
  else
    command_line = string.format("mono \"%s\" \"%s\" %s -out \"%s\"", app_cmd, input_file, args, output_file)
  end
  
  ret = os.execute(command_line)
  
  return ret;
  
end

function get_volume_scaling_items(format)

  if format == "XM" then
    return {"None", "Sample", "Column"}
  elseif format == "MOD" then
    return {"None", "Sample"}
  end

end

function save_dialog_file()

  local conv_type = get_dest_format(conv_type_value)

  local out = renoise.app():prompt_for_filename_to_write(conv_type, "Output file");
  
  return out;
end

