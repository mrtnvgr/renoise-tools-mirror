--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Pattern Length Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'PattLenPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function PattLenPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_PATT_LEN
  
  -- display init
  local rs = renoise.song()
  set_lcd(string.format('%02ub', rs.selected_pattern.number_of_lines/
                                 rs.transport.lpb), true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function PattLenPrompt:encoder(delta)
  -- encoder change
  local rs = renoise.song()
  local lpb = rs.transport.lpb
  local curr_beats = math.floor(rs.selected_pattern.number_of_lines/lpb)
  local beats = clamp(curr_beats+delta, 1, 32)
  rs.selected_pattern.number_of_lines = beats*lpb
  set_lcd(string.format('%02ub', beats), true)
end


function PattLenPrompt:func_x()
  -- n/a
end


function PattLenPrompt:func_y()
  -- n/a
end


function PattLenPrompt:func_z()
  -- n/a
end
