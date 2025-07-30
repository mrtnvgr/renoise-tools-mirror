--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Sample Mapping (note) Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampMapNotePrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampMapNotePrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SMAP_NOTE
  
  -- base note default
  self.mode = 3
  set_led(LED_PEDAL, LED_ON)

  -- display init
  local map = self:get_map() 
  if map then
    set_lcd(midi_note_to_pk_lcd(map.base_note, true))
  else
    set_lcd('---')
  end
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampMapNotePrompt:encoder(delta)
  -- encoder change
  local map = self:get_map() 
  if map then
    if self.mode == 1 then
      -- low
      local new_range = {clamp(map.note_range[1]+delta, 0, map.note_range[2]),
                         map.note_range[2]}

      map.note_range = new_range
      
      set_lcd(midi_note_to_pk_lcd(map.note_range[1], true))
    elseif self.mode == 2 then
      -- high
      local new_range = {map.note_range[1],
                         clamp(map.note_range[2]+delta, map.note_range[1], 119)}

      map.note_range = new_range
      
      set_lcd(midi_note_to_pk_lcd(map.note_range[2], true))
    elseif self.mode == 3 then
      -- base note
      local new_note = clamp(map.base_note+delta, 0, 119)

      map.base_note = new_note
      
      set_lcd(midi_note_to_pk_lcd(map.base_note, true))
    end
  end
end


function SampMapNotePrompt:func_x()
  -- low note
  self.mode = 1
  set_led(LED_X, LED_ON)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_OFF)
  
  local map = self:get_map() 
  if map then
    set_lcd(midi_note_to_pk_lcd(map.note_range[1], true))
  else
    set_lcd('---')
  end
end


function SampMapNotePrompt:func_y()
  -- high note
  self.mode = 2
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_ON)
  set_led(LED_PEDAL, LED_OFF)
  
  local map = self:get_map() 
  if map then
    set_lcd(midi_note_to_pk_lcd(map.note_range[2], true))
  else
    set_lcd('---')
  end
end


function SampMapNotePrompt:func_z()
  -- base note
  self.mode = 3
  set_led(LED_X, LED_OFF)
  set_led(LED_Y, LED_OFF)
  set_led(LED_PEDAL, LED_ON)
  
  local map = self:get_map() 
  if map then
    set_lcd(midi_note_to_pk_lcd(map.base_note, true))
  else
    set_lcd('---')
  end
end


--------------------------------------------------------------------------------
-- Support Handling Functions
--------------------------------------------------------------------------------
function SampMapNotePrompt:get_map()
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
