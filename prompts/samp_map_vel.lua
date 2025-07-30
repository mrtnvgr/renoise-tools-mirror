--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Sample Mapping (velocity) Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampMapVelPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampMapVelPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SMAP_VEL
  
  -- high vel default
  self.mode = 2
  set_led(LED_Y, LED_ON)

  -- display init
  local map = self:get_map() 
  if map then
    set_lcd(string.format("%03d", map.velocity_range[2], true))
  else
    set_lcd('---')
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampMapVelPrompt:encoder(delta)
  -- encoder change
  local map = self:get_map() 
  if map then
    if self.mode == 1 then
      -- low
      local new_range = {clamp(map.velocity_range[1]+delta, 0, map.velocity_range[2]),
                         map.velocity_range[2]}

      map.velocity_range = new_range
      
      set_lcd(string.format("%03d", map.velocity_range[1], true))
    elseif self.mode == 2 then
      -- high
      local new_range = {map.velocity_range[1],
                         clamp(map.velocity_range[2]+delta, map.velocity_range[1], 127)}

      map.velocity_range = new_range
      
      set_lcd(string.format("%03d", map.velocity_range[2], true))
    end
  end
end


function SampMapVelPrompt:func_x()
  -- low note
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  
  local map = self:get_map() 
  if map then
    set_lcd(string.format("%03d", map.velocity_range[1], true))
  else
    set_lcd('---')
  end
end


function SampMapVelPrompt:func_y()
  -- high note
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  
  local map = self:get_map() 
  if map then
    set_lcd(string.format("%03d", map.velocity_range[2], true))
  else
    set_lcd('---')
  end
end


function SampMapVelPrompt:func_z()
  -- set to max
local map = self:get_map() 
  if map then
    map.velocity_range = {0, 127}
    
    if self.mode == 1 then
      set_lcd(string.format("%03d", map.velocity_range[1], true))
    elseif self.mode == 2 then
      set_lcd(string.format("%03d", map.velocity_range[2], true))
    end
  end
end


--------------------------------------------------------------------------------
-- Support Handling Functions
--------------------------------------------------------------------------------
function SampMapVelPrompt:get_map()
  -- get the current sample mapping
  local inst = renoise.song().selected_instrument
  local si = renoise.song().selected_sample_index
  
  local index = -1
  for i = 1, #inst.sample_mappings[1] do
    if inst.sample_mappings[1][i].sample_index == si then
      index = i
    end
  end
  
  if index == -1 then
    return
  else
    return inst.sample_mappings[1][index]
  end
end
