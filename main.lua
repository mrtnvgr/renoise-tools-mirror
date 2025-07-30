--[[============================================================================
main.lua
============================================================================]]--

-- This is a very simple hexadecimal-decimal converter to rapidly convert between
-- these two number bases which are frequently used in Renoise.
-- Can avoid some headaches.
-- This tool can be reached through Rightclick on pattern editor => Tools or
-- through "Pattern Editor:Tools:Hex-Dec converter" shortcut key

--------------------------------------------------------------------------------
-- tool registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Hex-Dec converter...",
  invoke = function() show_dialog() end  
}

renoise.tool():add_keybinding {
 name = "Pattern Editor:Tools:Hex-Dec converter",
 invoke = function(repeated)
    -- if (not repeated) to ignore key repeats 
    show_dialog()
 end
}

--------------------------------------------------------------------------------
-- requires
--------------------------------------------------------------------------------

require "gui"

