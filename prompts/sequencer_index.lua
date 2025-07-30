--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sequencer Index Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SequencerIndexPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SequencerIndexPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SEQ_IDX
    
  -- display index
  set_lcd(string.format("S%02d", renoise.song().selected_sequence_index-1),
          true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SequencerIndexPrompt:encoder(delta)
  -- encoder change
  local rs = renoise.song()
  local i = clamp(rs.selected_sequence_index+delta,
                  1, #renoise.song().sequencer.pattern_sequence)
                  
  rs.selected_sequence_index = i
end


function SequencerIndexPrompt:func_x()
  -- clone
  local rs = renoise.song()
  local pat = rs.sequencer:insert_new_pattern_at(rs.selected_sequence_index+1)
  rs.selected_sequence_index = rs.selected_sequence_index + 1
  rs.selected_pattern:copy_from(rs.patterns[rs.sequencer:pattern(rs.selected_sequence_index-1)])
  BasePrompt.func_x(self)
end


function SequencerIndexPrompt:func_y()
  -- delete
  local rs = renoise.song()
  rs.sequencer:delete_sequence_at(rs.selected_sequence_index)
  BasePrompt.func_y(self)
end


function SequencerIndexPrompt:func_z()
  -- clear
  renoise.song().selected_pattern:clear()
  BasePrompt.func_z(self)
end
