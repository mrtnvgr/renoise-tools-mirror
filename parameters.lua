--------------------------------------------------------------------------------
-- SysEx Handler and Librarian
--
-- Copyright 2011 Martin Bealby
--
-- Settings management
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
parameters = nil  -- preferences object


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function load_parameters()
  -- initialise default and overwrite with settings from the config file
  parameters = renoise.Document.create("SysExPreferences") {
    auto_connect = false,         -- automatically try to connect on startup
    midi_out_device = "None",     -- default midi send device
    midi_in_device = "None",      -- default midi recv device
  }
  parameters:load_from("config.xml")
end


function save_parameters()
  -- save the current settings to the config file
  if parameters ~= nil then
    parameters:save_as("config.xml")
  else
  end
end
