--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Note Delay Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'NoteDelayPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function NoteDelayPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_NOTE_DELAY

  -- display delay
  set_lcd(string.format("d%02x", renoise.song().selected_note_column.delay_value), true)
  
  -- column visibility state
  if renoise.song().selected_track.delay_column_visible then
    set_led(LED_X, LED_ON)
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function NoteDelayPrompt:encoder(delta)
  -- encoder change
  
  local val = clamp(renoise.song().selected_note_column.delay_value+delta,
                    0, 255)
  renoise.song().selected_note_column.delay_value = val
  
  -- display delay
  set_lcd(string.format("d%02x", val), true)
end


function NoteDelayPrompt:func_x()
  -- note delay column visibility
  renoise.song().selected_track.delay_column_visible = not
    renoise.song().selected_track.delay_column_visible
    
  if renoise.song().selected_track.delay_column_visible then
    set_led(LED_X, LED_ON)
  else
    set_led(LED_X, LED_OFF)
  end
end


function NoteDelayPrompt:func_y()
  -- max val
  renoise.song().selected_note_column.delay_value = 255
  
  -- display delay
  set_lcd(string.format("d%02x", 255), true)
  
  BasePrompt.func_y(self)
end


function NoteDelayPrompt:func_z()
  -- clear
  renoise.song().selected_note_column.delay_value = 0
  
  -- display delay
  set_lcd(string.format("d%02x", 0), true)
  
  BasePrompt.func_z(self)
end
