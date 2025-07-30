--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Sample Volume / Panning / NNA Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampVpnPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampVpnPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_VPN
  
  -- high vel default
  self.mode = 1
  set_led(LED_X, LED_ON)

  -- display init
  set_lcd(vol_to_lcd(renoise.song().selected_sample.volume), true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampVpnPrompt:encoder(delta)
  -- encoder change
  local samp = renoise.song().selected_sample
  
  if self.mode == 1 then
    -- vol
    samp.volume = clamp(samp.volume+(delta/127),0,1)
  elseif self.mode == 2 then
    -- pan
    local pan = clamp(math.floor(samp.panning*100)+(delta*1.1),0,100)
    samp.panning = pan/100
  elseif self.mode == 3 then
    -- nna
    samp.new_note_action = clamp(samp.new_note_action+delta,1,3)
  end
  
  -- feedback via notifiers in inst_edit mode
end


function SampVpnPrompt:func_x()
  -- volume
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display 
  set_lcd(vol_to_lcd(renoise.song().selected_sample.volume), true)
end


function SampVpnPrompt:func_y()
  -- panning
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  set_led(LED_PEDAL, LED_OFF)
  
  -- display 
  set_lcd(pan_to_lcd(renoise.song().selected_sample.panning), true)
end


function SampVpnPrompt:func_z()
  -- nna
  self.mode = 3
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_ON)
  
  -- display 
  set_lcd(nna_to_lcd(renoise.song().selected_sample.new_note_action), true)
end
