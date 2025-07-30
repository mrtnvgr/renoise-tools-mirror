--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Waiting Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'WaitingMode' (BaseMode)

--[[
  self.track = renoise.song().selected_track
]]--


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function WaitingMode:encoder(delta)
  -- no action
end


function WaitingMode:button(button_id)
  -- no action
end


function WaitingMode:rotary(rotary_id, value)
  -- no action
end


function WaitingMode:pad(pad, velocity)
  -- no action
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function WaitingMode:lcd_timer()
  set_led(40 + self.lcd_index, LED_FLASH)
  self.lcd_index = (self.lcd_index + 1) % 0x17
end


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function WaitingMode:__init()
  -- set mode indicator
  self.lcd_index = 0
  set_lcd('   ')
  
  self.mode = MODE_WAIT
  
  local rt = renoise.tool()
  
  if not rt:has_timer({self, self.lcd_timer}) then
    rt:add_timer({self, self.lcd_timer}, 50)
  end
end


function WaitingMode:exit()
  -- remove hooks
  local rt = renoise.tool()
  
  if rt:has_timer({self, self.lcd_timer}) then
    rt:remove_timer({self, self.lcd_timer})
  end
end
