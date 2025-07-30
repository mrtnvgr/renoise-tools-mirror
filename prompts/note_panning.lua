--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Note Panning Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'NotePanningPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function NotePanningPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_NOTE_PANNING

  -- display value
  local val = renoise.song().selected_note_column.panning_value
  if val == 255 then
    set_lcd('p--')
  else
    set_lcd(string.format("p%02x", val), true)
  end
  
  -- column visibility state
  if renoise.song().selected_track.panning_column_visible then
    set_led(LED_X, LED_ON)
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function NotePanningPrompt:encoder(delta)
  -- encoder change
  
  local val = renoise.song().selected_note_column.panning_value
  
  if (val == 0) and delta == -1 then
    val = 255
    set_lcd(string.format("p--", val), true)
  elseif (val == 255) and (delta == 1) then
    val = 0
    set_lcd(string.format("p%02x", val), true)
  elseif (val == 255) and (delta == -1) then
    -- do nothing
    return
  else
    val = clamp(val+delta, 0, 128)
    set_lcd(string.format("p%02x", val), true)
  end
  
  renoise.song().selected_note_column.panning_value = val
end


function NotePanningPrompt:func_x()
  -- panning volume column visibility
  renoise.song().selected_track.panning_column_visible = not
    renoise.song().selected_track.panning_column_visible
    
  if renoise.song().selected_track.panning_column_visible then
    set_led(LED_X, LED_ON)
  else
    set_led(LED_X, LED_OFF)
  end
end


function NotePanningPrompt:func_y()
  -- center
  renoise.song().selected_note_column.panning_value = 0x40
  
  -- display value
  set_lcd(string.format("p%02x", 0x40), true)
  
  BasePrompt.func_y(self)
end


function NotePanningPrompt:func_z()
  -- clear
  renoise.song().selected_note_column.panning_value = 255
  
  -- display value
  set_lcd("p--",true)
  
  BasePrompt.func_z(self)
end
