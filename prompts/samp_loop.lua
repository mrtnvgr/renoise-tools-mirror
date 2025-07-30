--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sample Loop Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampLoopPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampLoopPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_LOOP
  
  set_led(LED_X, LED_ON)
  self.mode = 1
  
  -- display init
  set_lcd("   ")
  
  local samp = renoise.song().selected_sample
  local sb = samp.sample_buffer
  
  if sb.has_sample_data then
    sb.selection_range = {samp.loop_start, samp.loop_end}
    sb.display_range = {samp.loop_start, samp.loop_end}
  end
end



--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampLoopPrompt:encoder(delta)
  -- move marker
  
  local samp = renoise.song().selected_sample
  local sb = samp.sample_buffer
  
  if sb.has_sample_data then
    if self.mode == 1 then
      -- start
      local dr = sb.display_range
      local sr = sb.selection_range
      local step = (dr[2]-dr[1])/512
      sb.selection_range = {clamp(sr[1]+(delta*step), dr[1], dr[2]), sr[2]}
      samp.loop_start = sb.selection_range[1]

    elseif self.mode == 2 then
      -- end
      local dr = sb.display_range
      local sr = sb.selection_range
      local step = (dr[2]-dr[1])/512
      sb.selection_range = {sr[1], clamp(sr[2]+(delta*step), dr[1], dr[2])}
      samp.loop_end = sb.selection_range[2]
    
    elseif self.mode == 3 then
      -- loop mode
      samp.loop_mode = clamp(samp.loop_mode + delta, 1, 4)
    end
  end
end


function SampLoopPrompt:func_x()
  -- start
  set_lcd("   ")
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
end


function SampLoopPrompt:func_y()
  -- end
  set_lcd("   ")
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  set_led(LED_PEDAL, LED_OFF)
end


function SampLoopPrompt:func_z()
  -- loop mode
  self.mode = 3
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_ON)
  
  local lm = renoise.song().selected_sample.loop_mode
  
  if lm == renoise.Sample.LOOP_MODE_OFF then
    set_lcd("OFF")
  elseif lm == renoise.Sample.LOOP_MODE_FORWARD then
    set_lcd("FOR")
  elseif lm == renoise.Sample.LOOP_MODE_REVERSE then
    set_lcd("REV")
  elseif lm == renoise.Sample.LOOP_MODE_PING_PONG then
    set_lcd("P-P")
  end

end
