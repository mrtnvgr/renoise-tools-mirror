require "control_panel_gui"

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------


function init_controlpanel_dialog()

  check_app_location();
  
  show_controlpanel_dialog();
  
  if converter_dialog and converter_dialog.visible then
    converter_dialog:close()
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
