--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Base Mode Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
MODE_BASE     = 1
MODE_PATTEDIT = 2
MODE_INSTEDIT = 3
MODE_SAMPEDIT = 4
MODE_SONGEDIT = 5



--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'BaseMode'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function BaseMode:__init()
end


function BaseMode:exit()
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function BaseMode:encoder(delta)
  -- handle encoder turns
  print("encoder:", delta)
  
  if prompt then
    prompt:encoder(delta)
  end
end


function BaseMode:button(button_id)
  -- handle button press events
  print("button:", button_id)
  
  if prompt then
    if button_id == BTN_SETTING then
      prompt:ok()
    elseif button_id == BTN_X then
      prompt:func_x()
    elseif button_id == BTN_Y then
      prompt:func_y()
    elseif button_id == BTN_PEDAL then
      prompt:func_z()
    end
  end
end


function BaseMode:rotary(rotary_id, value)
  -- handle rotary events
  print("rotary:", rotary_id, value)
end


function BaseMode:pad(pad, velocity)
  print("pad:", pad, velocity)
end
