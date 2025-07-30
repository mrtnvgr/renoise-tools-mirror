--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Sample Transpose / Tuning / Interpolation Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampTtiPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampTtiPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_TTI
  
  -- high vel default
  self.mode = 1
  set_led(LED_X, LED_ON)

  -- display init
  set_lcd(tune_to_lcd(renoise.song().selected_sample.transpose), true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampTtiPrompt:encoder(delta)
  -- encoder change
  local samp = renoise.song().selected_sample
  
  if self.mode == 1 then
    -- transpose
    samp.transpose = clamp(samp.transpose+delta, -120, 120)
    
  elseif self.mode == 2 then
    -- fine tune
    samp.fine_tune = clamp(samp.fine_tune+delta, -127, 127)
    
  elseif self.mode == 3 then
    -- interpolation
    samp.interpolation_mode = clamp(samp.interpolation_mode+delta,1,3)
  end
  
  -- feedback via notifiers in inst_edit mode
end


function SampTtiPrompt:func_x()
  -- volume
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display
  set_lcd(tune_to_lcd(renoise.song().selected_sample.transpose), true)
end


function SampTtiPrompt:func_y()
  -- panning
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display 
  set_lcd(tune_to_lcd(renoise.song().selected_sample.fine_tune), true)
end


function SampTtiPrompt:func_z()
  -- nna
  self.mode = 3
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_ON)
  
  -- display 
  set_lcd(interpolate_to_lcd(renoise.song().selected_sample.interpolation_mode), true)
end
