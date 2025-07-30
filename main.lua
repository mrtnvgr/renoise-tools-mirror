--[[============================================================================
com.neurogami.SwapColumns.xrnx/main.lua

A tool to assist in swapping currently-active note column values.

Sort of like automating "mute" ; best used with full-pattern auto-seek samples.

Motivated by a desire to get a choppy scattered percussion effect.

Assumes you have two note columns: The current selected note column ("col1"), 
and one over to the right ("col2").

Takes two values for the audible volume value of notes in each column
Takes a space-separated list of line numbers.

It assumes col1 should start as "active" (i.e. audible).

First line, col1 gets assign its active column, col2 is set to 00.

For each line in the list of line numbers the active column alternates.

In each case one columns gets set to 00 and the other to its active volume.

When run, the tool will clear all column column values in the affected note columns.

Feature ideas:

Currently only works (well) with two columns; no way to swap around  three or more columns.

A fix would be for the code to see if there is an existing volume value.

* If so, and 00, the it assumes some *other* column is set to active, so col1 is left alone
and col2 gets set to 00 as well.  

* If not, and  col1 is not 00, then it sets col2 to 00, but toggles the "col1" active state.

The idea is to somehow look at the existing set of volume values and deduce what should 
happen with this additional note column




============================================================================]]--

require 'Utils'
require 'Core'
require 'Gui'

-- Reload the script whendever this file is saved. 
_AUTO_RELOAD_DEBUG = true

local function swap_columns_gui()
  GUI.current_text = ""
  GUI.show_dialog() 
--   local text = string.trim(GUI.current_text)
end



renoise.tool():add_menu_entry {
  name = "Pattern Editor:Neurogami SwapColumns",
  invoke = swap_columns_gui
}





