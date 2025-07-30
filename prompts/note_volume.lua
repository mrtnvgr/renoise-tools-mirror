--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Note Volume Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'NoteVolumePrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function NoteVolumePrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_NOTE_VOLUME

  -- display value
  local val = renoise.song().selected_note_column.volume_value
  if val == 255 then
    set_lcd('v--')
  else
    set_lcd(string.format("v%02x", val), true)
  end
  
  -- column visibility state
  if renoise.song().selected_track.volume_column_visible then
    set_led(LED_X, LED_ON)
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function NoteVolumePrompt:encoder(delta)
  -- encoder change
  
  local val = renoise.song().selected_note_column.volume_value
  
  if (val == 0) and delta == -1 then
    val = 255
    set_lcd(string.format("v--", val), true)
  elseif (val == 255) and (delta == 1) then
    val = 0
    set_lcd(string.format("v%02x", val), true)
  elseif (val == 255) and (delta == -1) then
    -- do nothing
    return
  else
    val = clamp(val+delta, 0, 127)
    set_lcd(string.format("v%02x", val), true)
  end
  
  renoise.song().selected_note_column.volume_value = val
end


function NoteVolumePrompt:func_x()
  -- note volume column visibility
  renoise.song().selected_track.volume_column_visible = not
    renoise.song().selected_track.volume_column_visible
    
  if renoise.song().selected_track.volume_column_visible then
    set_led(LED_X, LED_ON)
  else
    set_led(LED_X, LED_OFF)
  end
end


function NoteVolumePrompt:func_y()
  -- max val
  renoise.song().selected_note_column.volume_value = 127
  
  -- display value
  set_lcd(string.format("v%02x", 127), true)
  
  BasePrompt.func_y(self)
end


function NoteVolumePrompt:func_z()
  -- clear
  renoise.song().selected_note_column.volume_value = 255
  
  -- display value
  set_lcd("v--", true)
  
  BasePrompt.func_z(self)
end
