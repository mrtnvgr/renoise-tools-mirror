--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai PGM Common Support Interface
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "instruments/mpc1000-pgm"
require "instruments/mpc2000-pgm"


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function pgmcommon_import(filename)
  -- Itendifies filetype and executes associatiated loader
  local d
  
  -- load the file into memory
  d = load_file_to_memory(filename)  
  
  if pgm2000_is_valid_file(d) then
    d = ""
    return pgm2000_import(filename)
  elseif pgm1000_is_valid_file(d) then
    d = ""
    return pgm1000_import(filename)
  else
    renoise.app():show_error(filename .. " is not a supported Akai MPC program.  Sorry.")
    renoise.app():show_status(filename .. " is not a supported Akai MPC program.  Sorry.")
    d = ""
    return false
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
pgm_integration = { category = "instrument",
                    extensions = {"pgm"},
                    invoke = pgmcommon_import}

if renoise.tool():has_file_import_hook("instrument", {"pgm"}) == false then
  renoise.tool():add_file_import_hook(pgm_integration)
end
