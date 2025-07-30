--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Settings management
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

-- preferences object
parameters = nil


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function load_parameters()
  -- initialise default and overwrite with settings from the config file

  parameters = renoise.Document.create("AlphaTrackPreferences") {
    auto_connect = false,         -- automatically try to connect on startup
    auto_select_window = false,   -- auto select windows toggle
    sticky_shift = true,          -- sticky shift (always on at the moment)
    display_hold_time = 1,        -- display hold delay time
    strip_release_timeout = 0.2   -- strip virtual release timeout in seconds
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
