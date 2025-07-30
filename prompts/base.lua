--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Base Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'BasePrompt'


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function BasePrompt:__init()
  set_led(LED_SETTING, LED_BLINK)
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  self.prompt = PROMPT_BASE
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function BasePrompt:ok()
  -- ok / enter
  set_led(LED_SETTING, LED_OFF)
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  
  if self.prompt == PROMPT_INST_IDX then
    set_led(LED_PROGCHANGE, LED_OFF)
  elseif self.prompt == PROMPT_TRACK_IDX then
    set_led(LED_MIDICH, LED_OFF)
  elseif self.prompt == PROMPT_SEQ_IDX then
    set_led(LED_SCENE, LED_OFF)
  elseif self.prompt == PROMPT_NOTECOL_IDX then
    set_led(LED_NOTECC, LED_OFF)
  elseif self.prompt == PROMPT_PATT_LEN then
    set_led(LED_SETTING, LED_OFF)
  elseif self.prompt == PROMPT_NOTE_DELAY then
    set_led(LED_RELVAL, LED_OFF)
  elseif self.prompt == PROMPT_NOTE_VOLUME then
    set_led(LED_VELOCITY, LED_OFF)
  elseif self.prompt == PROMPT_NOTE_PANNING then
    set_led(LED_PORT, LED_OFF)
  elseif self.prompt == PROMPT_SMAP_NOTE then
    set_led(LED_NOTECC, LED_OFF)
  elseif self.prompt == PROMPT_SMAP_VEL then
    set_led(LED_MIDICH, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_VPN then
    set_led(LED_FLAM, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_TTI then
    set_led(LED_ROLL, LED_OFF)
  elseif self.prompt == PROMPT_BPM then
    set_led(LED_PORT, LED_OFF)
  elseif self.prompt == PROMPT_TRACK_OUTDEL then
    set_led(LED_RELVAL, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_REC then
    set_led(LED_SWTYPE, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_LOOP then
    set_led(LED_HOLD, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_SLICE then
    set_led(LED_NOTECC, LED_OFF)
  elseif self.prompt == PROMPT_SAMP_AUTOCHOP then
    set_led(LED_MIDICH, LED_OFF)
  elseif self.prompt == PROMPT_PAD_SCALE then
    set_led(LED_MESSAGE, LED_OFF)
  end
  
  prompt = nil
end


function BasePrompt:encoder(delta)
  -- encoder change
  error("Prompt encoder() function needs overriding")
end


function BasePrompt:func_x()
  -- func_x
  set_led(LED_X, LED_FLASH)
end


function BasePrompt:func_y()
  -- func_y
  set_led(LED_Y, LED_FLASH)
end


function BasePrompt:func_z()
  -- func_z
  set_led(LED_PEDAL, LED_FLASH)
end
