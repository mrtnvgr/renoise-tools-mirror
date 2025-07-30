--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Main initialisation code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "parameters"
require "gui"
require "fileops"
require "comms/midi"
require "devices/buttons"
require "devices/encoders"
require "devices/fader"
require "devices/lcd"
require "devices/leds"
require "devices/touchstrip"
require "modes/common"
require "modes/mix"
require "modes/edit"
require "modes/dsp"
require "modes/sample"


--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:AlphaTrack Support:Connect",
  selected = function()
    return connected
  end,
  invoke = function() 
    if (not connected) then
      connect()
      all_leds_off()
      lcd_attach_hooks()
      --set_mode(MODE_MIX)
      attach_common_hooks()
      --update fader/common leds
      common_volume_change_hook()
      common_pan_change_hook()
      common_solo_hook()
      common_mute_hook()
      common_editmode_hook()
      common_patternloop_hook()
      common_track_change_hook()
      --default mode (remember to set current_mode to match!)
      current_mode = MODE_EDIT
      edit_init()
    end
  end
}


renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:AlphaTrack Support:Disconnect",
  selected = function()
    return (not connected)
  end,
  invoke = function() 
    if (connected) then
      lcd_detach_hooks()
      all_leds_off()
      clear_display()
      move_fader_to(0)
      disconnect()
    end
  end
}


renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:AlphaTrack Support:Preferences",
  invoke = function()
    if (not pref_dialog_content) then
      pref_dialog_init()
    end
    pref_dialog = renoise.app():show_custom_dialog("AlphaTrack Preferences",
                                                   pref_dialog_content)
  end
}



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function starting_up_spin()
  -- attach this to the idle loop on startup to attach to an AlphaTrack
  -- it will automagically remove itself if successful
  if renoise.song() ~= nil then
    if (not connected) then
      connect()
      all_leds_off()
      lcd_attach_hooks()
      --set_mode(MODE_MIX)
      attach_common_hooks()
      --update fader/common leds
      common_volume_change_hook()
      common_pan_change_hook()
      common_solo_hook()
      common_mute_hook()
      common_editmode_hook()
      common_patternloop_hook()
      common_track_change_hook()
      --default mode (remember to set current_mode to match!)
      current_mode = MODE_EDIT
      edit_init()
      if renoise.tool().app_idle_observable:has_notifier(starting_up_spin) == true then
        renoise.tool().app_idle_observable:remove_notifier(starting_up_spin)
      end
    end
  end
end


--------------------------------------------------------------------------------
-- Tool startup
--------------------------------------------------------------------------------

load_parameters()
attach_tool_hooks()

if parameters.auto_connect.value == true then
  if renoise.tool().app_idle_observable:has_notifier(starting_up_spin) == false then
    renoise.tool().app_idle_observable:add_notifier(starting_up_spin)
  end
end



