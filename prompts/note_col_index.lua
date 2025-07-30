--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Note Column Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'NoteColIndexPrompt'  (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function NoteColIndexPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_NOTECOL_IDX
  
  -- display index
  set_lcd(string.format("n%02x", renoise.song().selected_note_column_index-1),
          true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function NoteColIndexPrompt:encoder(delta)
  -- encoder change
  local rs = renoise.song()
  local i = clamp(rs.selected_note_column_index+delta,
                  1, rs.selected_track.visible_note_columns)
                  
  rs.selected_note_column_index = i
end


function NoteColIndexPrompt:func_x()
  -- insert
  local rs = renoise.song()
  rs.selected_track.visible_note_columns = clamp(rs.selected_track.visible_note_columns+1, 1, 8)
  local i = clamp(rs.selected_note_column_index+1,
                  1, rs.selected_track.visible_note_columns)
  rs.selected_note_column_index = i
  BasePrompt.func_x(self)
end


function NoteColIndexPrompt:func_y()
  -- delete
  local rs = renoise.song()
  rs.selected_track.visible_note_columns = clamp(rs.selected_track.visible_note_columns-1, 1, 8)
  local i = clamp(rs.selected_note_column_index-1,
                  1, rs.selected_track.visible_note_columns)
  rs.selected_note_column_index = i
  BasePrompt.func_y(self)
end


function NoteColIndexPrompt:func_z()
  -- clear
  local rs = renoise.song()

  for pos,line in rs.pattern_iterator:note_columns_in_pattern(rs.selected_pattern_index) do
    if pos.track == rs.selected_track_index then
      if pos.column == rs.selected_note_column_index then
        line:clear()
      end
    end
  end
  BasePrompt.func_z(self)
end
