require "downgrade_gui"

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

function init_downgrade_dialog()

  show_downgrade_dialog();
  
  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel:close()
  end
  
  if helper_dialog and helper_dialog.visible then
    helper_dialog:close()
  end
  
  if converter_dialog and converter_dialog.visible then
    converter_dialog:close()
  end

  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:close()
  end

end

function call_downgrade(replace_zk)

  local input_file = renoise.song().file_name;

  if (input_file == "") then
    renoise.app():show_error(MSG_SONG_NOT_SAVED);
    return
  end  
  
  renoise.app():save_song()

  local ret = downgrade(input_file, replace_zk)

  local msg = read_log();
  
  if ret == 0 then    
    renoise.app():load_song(input_file)
    downgrade_dialog:close();
  end
  
  show_downgrade_log_dialog(msg)  
  
end

function downgrade(input_file, replace_zk)
  
  local ret = 0;
  
  local app_cmd = "";  
  local args = "";
  
  if (is_windows_os() == false) then
    app_cmd = "mono ";      
  end  
  
  app_cmd = app_cmd .. app_path ;
  
  args = " -downgrade "
  
  if replace_zk then
    args = args .. " -replaceZK ";
  end
  
  args = args .. " -log " .. LOG_FILENAME;  
  
  local command_line = string.format('""%s" "%s" %s "', app_cmd, input_file, args);
  
  ret = os.execute(command_line);   
  
  return ret;
  
end
