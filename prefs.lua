--------------------------------------------------------------------------------
-- Freeze Track Tool
--
-- Copyright 2011 Martin Bealby
--
-- Preferences handling code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function init_prefs()
  -- init
  local prefs = renoise.Document.create("ScriptingToolPreferences") {
    -- defaults
    bitdepth = 24,
    samplerate = 48000,
    priority = "high",
    interpolation = "cubic",
    delete_source = false,
    pattern_based = true,
    headroom_comp = 6,
  }
  
  -- assign
  renoise.tool().preferences = prefs
end
