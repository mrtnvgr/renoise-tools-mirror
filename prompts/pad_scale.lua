--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Pad Scale Mapping Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'PadScalePrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function PadScalePrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_PAD_SCALE
  
  -- high vel default
  self.mode = 1
  set_led(LED_X, LED_ON)

  -- display init
  set_lcd(midi_note_to_pk_lcd(pk_pad_map_base), true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function PadScalePrompt:encoder(delta)
  -- encoder change
  local samp = renoise.song().selected_sample
  
  if self.mode == 1 then
    -- root note
    pk_pad_map_base = clamp(pk_pad_map_base+delta, 0x2A, 0x36)
    set_lcd(midi_note_to_pk_lcd(pk_pad_map_base), true)
    
  elseif self.mode == 2 then
    -- scale
    pk_pad_map_scale = clamp(pk_pad_map_scale+delta, 1, 7)
    set_lcd(PK_SCALE_NAMES[pk_pad_map_scale], true)
  end
  
  set_pad_mapping(make_pad_map(renoise.song().selected_instrument, mode.slice_bank)) -- ugly hack for mode.slice_bank
end


function PadScalePrompt:func_x()
  -- root note mode
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display
  set_lcd(midi_note_to_pk_lcd(pk_pad_map_base), true)
end


function PadScalePrompt:func_y()
  -- scale selection
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display 
  set_lcd(PK_SCALE_NAMES[pk_pad_map_scale], true)
end


function PadScalePrompt:func_z()
  -- n/a
end
