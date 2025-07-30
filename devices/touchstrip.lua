--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Touchstrip support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
strip_last_value = 64
strip_last_touched_time = 0


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function strip_abs_to_rel(value)
  -- convert an absolute value from the controller into a relative value
  -- taking into consideration the time of last touch
  local r = 0
  
  if strip_last_touched_time + parameters.strip_release_timeout
  > os.clock() then
    r = (value - strip_last_value) / 4
  end 
  
  strip_last_value = value
  strip_last_touched_time = os.clock()
  return r
end
