--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Track Output Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'TrackOutputPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function TrackOutputPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_TRACK_OUTDEL
  self.mode = 1

  -- track output index
  local tr = renoise.song().selected_track
  set_lcd(string.format("o%02d", table.find(tr.available_output_routings,
                                            tr.output_routing), true))
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function TrackOutputPrompt:encoder(delta)
  -- encoder change
  local tr = renoise.song().selected_track
  
  if self.mode == 1 then
    -- output
    -- feedback via mode hook 
    local i = clamp(table.find(tr.available_output_routings, tr.output_routing)
                               + delta, 1, #tr.available_output_routings)
    tr.output_routing = tr.available_output_routings[i]
  
  elseif self.mode == 2 then 
    -- set delay
    -- feedback via mode hook 
    tr.output_delay = clamp(tr.output_delay + (delta/10), 0, 99.9)
  end
end


function TrackOutputPrompt:func_x()
  -- set to parent
  local tr = renoise.song().selected_track
  
  if tr.group_parent then
    local i = table.find(tr.available_output_routings, tr.group_parent.name)
    if i then
      tr.output_routing = tr.available_output_routings[i]
      set_led(LED_X, LED_FLASH)
    end
  end
end


function TrackOutputPrompt:func_y()
  -- set to master
  local tr = renoise.song().selected_track
  
  local i = table.find(tr.available_output_routings, "Master")
  if i then
    tr.output_routing = tr.available_output_routings[i]
    set_led(LED_Y, LED_FLASH)
  end
end


function TrackOutputPrompt:func_z()
  -- toggle delay mode
  local tr = renoise.song().selected_track
  
  if self.mode == 1 then
    self.mode = 2
    set_lcd(string.format("%03d", math.floor(tr.output_delay*10)), true)
    set_led(LED_PEDAL, LED_ON)
  else
    self.mode = 1
    set_lcd(string.format("o%02d", table.find(tr.available_output_routings,
                                              tr.output_routing), true))
    set_led(LED_PEDAL, LED_OFF)
  end
end
