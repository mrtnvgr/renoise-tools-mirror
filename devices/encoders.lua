--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Fader support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
ENC_LEFT = 0x10
ENC_MIDDLE = 0x11
ENC_RIGHT = 0x12


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function enc_to_rel(revd_val)
  -- Convert a received value from an encoder into a relative value
  if revd_val > 64 then
      return 64 - revd_val
    else
      return revd_val
  end
end
