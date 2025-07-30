--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Instrument Index Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'InstIndexPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function InstIndexPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_INST_IDX
  
  -- display index
  set_lcd(string.format("i%02x", renoise.song().selected_instrument_index-1),
          true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function InstIndexPrompt:encoder(delta)
  -- encoder change
  local rs = renoise.song()
  local i = clamp(rs.selected_instrument_index+delta,
                  1, #rs.instruments)
                  
  rs.selected_instrument_index = i
end


function InstIndexPrompt:func_x()
  -- clone
  local rs = renoise.song()
  local new = rs:insert_instrument_at(rs.selected_instrument_index+1)
  new:copy_from(rs.selected_instrument)
  rs.selected_instrument_index = rs.selected_instrument_index + 1
  BasePrompt.func_x(self)
end


function InstIndexPrompt:func_y()
  -- delete
  local rs = renoise.song()
  rs:delete_instrument_at(rs.selected_instrument_index)
  BasePrompt.func_y(self)
end


function InstIndexPrompt:func_z()
  -- delete
  renoise.song().selected_instrument:clear()
  BasePrompt.func_y(self)
end
