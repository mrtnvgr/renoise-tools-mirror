--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Fader support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
fader_position = 0
fader_flipped = false


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function move_fader_to(position)
  -- Moves the fader to the specified position (0-1023)
  if connected == true then
    if position > 1023 then
      position = 1023
    elseif position < 0 then
      position = 0
    end
    local msb = math.floor(position / 8)
    local lsb = (position - (msb * 8))*16
    midi_out_device:send({0xE0, lsb, msb})
  end
end


function fader_to_value(lsb, msb)
  -- Converts the two recieved midi bytes to a fader value 0-1023
  return (lsb / 16) + (msb * 8)
end


function write_automation_point(parameter_index)
  -- Writes an automation point at the current time for the selected parameter
  -- device index = 1 (TrackVolPan)
  -- parameter 1 = pan; parameter 2 = volume
  
end
