--[[----------------------------------------------------------------------------
-- Duplex.APCKEY25
----------------------------------------------------------------------------]]--

--[[

Inheritance: APCKEY25 > MidiDevice > Device

A device-specific class, valid for Akai APCKEY25 models

--]]


--==============================================================================

class "APCKEY25" (MidiDevice)

function APCKEY25:__init(display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- define a default colorspace
  self.colorspace = {1, 1, 1}

end

--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_boolean

function APCKEY25:output_boolean(pt,xarg,ui_obj)

  local value = nil

  local color = self:quantize_color(pt.color)
  -- use the local colorspace if it's available
  local colorspace = xarg.colorspace or self.colorspace
  if (colorspace[1]>1) then
    -- clip launch buttons can have multiple colors
    local red = (pt.color[1]==0xff)
    local green = (pt.color[2]==0xff)
    if red and green then
      value = 5 -- yellow
    elseif red then
      value = 3 -- red
    elseif green then
      value = 1 -- green
    else
      value = 0 -- turned off
    end
  else
    -- normal LED buttons are monochrome
    value = (pt.val == true) and xarg.maximum or xarg.minimum
  end

  return value

end

