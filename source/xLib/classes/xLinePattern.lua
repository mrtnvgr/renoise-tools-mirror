--[[============================================================================
xLinePattern
============================================================================]]--

--[[--

This class represents a 'virtual' renoise.PatternLine
.
#

Create instances as needed, through the constructor method 

]]


class 'xLinePattern'

xLinePattern.COLUMN_TYPES = {
  NOTE_COLUMN = 1,
  EFFECT_COLUMN = 2,
}

xLinePattern.MAX_NOTE_COLUMNS = 12
xLinePattern.MAX_EFFECT_COLUMNS = 8
xLinePattern.EMPTY_VALUE = 255     
xLinePattern.EMPTY_STRING = "00"
xLinePattern.EFFECT_CHARS = {
  "0","1","2","3","4","5","6","7", 
  "8","9","A","B","C","D","E","F", 
  "G","H","I","J","K","L","M","N", 
  "O","P","Q","R","S","T","U","V", 
  "W","X","Y","Z"                  
}

-------------------------------------------------------------------------------
-- constructor
-- @param note_columns (table<xNoteColumn descriptor>)
-- @param effect_columns (table<xEffectColumn descriptor>)

function xLinePattern:__init(note_columns,effect_columns)

  --- table<xNoteColumn>
  self.note_columns = table.create()

  --- table<xEffectColumn>
  self.effect_columns = table.create()

  -- initialize -----------------------

  if note_columns then
    for _,v in ipairs(note_columns) do
      self.note_columns:insert(v)
    end
  end

  if effect_columns then
    for _,v in ipairs(effect_columns) do
      self.effect_columns:insert(v)
    end
  end

  self:apply_descriptor(self.note_columns,self.effect_columns)

end

-------------------------------------------------------------------------------
-- convert descriptors into class instances (empty tables are left as-is)
-- @param note_columns (xNoteColumn or table)
-- @param effect_columns (xEffectColumn or table)

function xLinePattern:apply_descriptor(note_columns,effect_columns)

  if note_columns then
    for k,note_col in ipairs(note_columns) do
      if (type(note_col) == "table") and
        not table.is_empty(note_col)
      then
        -- convert into xNoteColumn 
        self.note_columns[k] = xNoteColumn(note_col)
      end
    end
    for i = #note_columns+1, #self.note_columns do
      self.note_columns[i] = {}
    end
  end
  if effect_columns then
    for k,fx_col in ipairs(effect_columns) do
      if (type(fx_col) == "table") and 
        not table.is_empty(fx_col)
      then
        -- convert into xEffectColumn
        self.effect_columns[k] = xEffectColumn(fx_col)
      end
    end
    for i = #effect_columns+1, #self.effect_columns do
      self.effect_columns[i] = {}
    end

  end

end

-------------------------------------------------------------------------------
-- combined method for writing to pattern or phrase
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int), when writing to pattern
-- @param phrase (renoise.InstrumentPhrase), when writing to phrase
-- @param tokens (table<string>) process these tokens ("note_value", etc)
-- @param include_hidden (bool) apply to hidden columns as well
-- @param expand_columns (bool) reveal columns as they are written to
-- @param clear_undefined (bool) clear existing data when ours is nil

function xLinePattern:do_write(sequence,line,track_idx,phrase,tokens,include_hidden,expand_columns,clear_undefined)

  local rns_line,patt_idx,rns_patt,rns_track,rns_ptrack
  local rns_track_or_phrase

  if track_idx then -- pattern
    rns_line,patt_idx,rns_patt,rns_track,rns_ptrack = 
      xLine.resolve_pattern_line(sequence,line,track_idx)
    rns_track_or_phrase = rns_track
  else -- phrase
    rns_line = xLine.resolve_phrase_line(line)
    rns_track_or_phrase = phrase
  end

  local is_seq_track = (rns_track.type == renoise.Track.TRACK_TYPE_SEQUENCER)

  local visible_note_cols = rns_track_or_phrase.visible_note_columns
  local visible_fx_cols = rns_track_or_phrase.visible_effect_columns

  -- figure out which sub-columns to display (VOL/PAN/DLY)
  if is_seq_track and expand_columns and not table.is_empty(self.note_columns) then
    rns_track_or_phrase.volume_column_visible = rns_track_or_phrase.volume_column_visible or 
      (type(table.find(tokens,"volume_value") or table.find(tokens,"volume_string")) ~= 'nil')
    rns_track_or_phrase.panning_column_visible = rns_track_or_phrase.panning_column_visible or
      (type(table.find(tokens,"panning_value") or table.find(tokens,"panning_string")) ~= 'nil')
    rns_track_or_phrase.delay_column_visible = rns_track_or_phrase.delay_column_visible or
      (type(table.find(tokens,"delay_value") or table.find(tokens,"delay_string")) ~= 'nil')
  end
  
  if is_seq_track then
    self:process_columns(rns_line.note_columns,
      rns_track_or_phrase,
      self.note_columns,
      include_hidden,
      expand_columns,
      visible_note_cols,
      xNoteColumn.output_tokens,
      clear_undefined,
      xLinePattern.COLUMN_TYPES.NOTE_COLUMN)
  else
    if self.note_columns then
      LOG("Can only write note-columns to a sequencer track")
    end
  end

  self:process_columns(rns_line.effect_columns,
    rns_track_or_phrase,
    self.effect_columns,
    include_hidden,
    expand_columns,
    visible_fx_cols,
    xEffectColumn.output_tokens,
    clear_undefined,
    xLinePattern.COLUMN_TYPES.EFFECT_COLUMN)

end

-------------------------------------------------------------------------------
-- write to either note or effect column
-- @param rns_columns (array<renoise.NoteColumn>) 
-- @param rns_track_or_phrase (renoise.Track or renoise.InstrumentPhrase) 
-- @param xline_columns (table<xNoteColumn or xEffectColumn>)
-- @param include_hidden (bool) apply to hidden columns as well
-- @param expand_columns (bool) reveal columns as they are written to
-- @param visible_cols (int) number of visible note/effect columns
-- @param tokens (table<string>) process these tokens ("note_value", etc)
-- @param clear_undefined (bool) clear existing data when ours is nil
-- @param col_type (xLinePattern.COLUMN_TYPES)

function xLinePattern:process_columns(
  rns_columns,
  rns_track_or_phrase,
  xline_columns,
  include_hidden,
  expand_columns,
  visible_cols,
  tokens,
  clear_undefined,
  col_type)

	for k,rns_col in ipairs(rns_columns) do
    
    if not expand_columns then
      if not include_hidden and (k > visible_cols) then
        break
      end
    end

    local col = xline_columns[k]
    
    if col then

      if expand_columns 
        and ((type(col)=="xNoteColumn") or (type(col)=="xEffectColumn"))
        or ((type(col) == "table") and not table.is_empty(col))
      then
        if (k > visible_cols) then
          visible_cols = k
        end
      end

      if not include_hidden and (k > visible_cols) then
        break
      end

      -- a table can be the result of a redefined column
      if (type(col) == "table") then
        if (col_type == xLinePattern.COLUMN_TYPES.NOTE_COLUMN) then
          col = xNoteColumn(col)
        elseif (col_type == xLinePattern.COLUMN_TYPES.EFFECT_COLUMN) then
          col = xEffectColumn(col)
        end
      end

      col:do_write(
        rns_col,tokens,clear_undefined)
    else
      if clear_undefined then
        rns_col:clear()
      end
    end
	end

  if (col_type == xLinePattern.COLUMN_TYPES.NOTE_COLUMN) then
    rns_track_or_phrase.visible_note_columns = visible_cols
  elseif (col_type == xLinePattern.COLUMN_TYPES.EFFECT_COLUMN) then
    rns_track_or_phrase.visible_effect_columns = visible_cols
  end

end

-------------------------------------------------------------------------------
-- @param rns_line (renoise.PatternLine)
-- @param max_note_cols (int)
-- @param max_fx_cols (int)
-- @return table, note columns
-- @return table, effect columns

function xLinePattern.do_read(rns_line,max_note_cols,max_fx_cols) 

  local note_cols = {}
  local fx_cols = {}

  for i = 1, max_note_cols do
    local note_col = rns_line.note_columns[i]
    table.insert(note_cols, xNoteColumn.do_read(note_col))
  end

  for i = 1, max_fx_cols do
    local fx_col = rns_line.effect_columns[i]
    table.insert(fx_cols, xEffectColumn.do_read(fx_col))
  end

  return note_cols,fx_cols

end

-------------------------------------------------------------------------------

function xLinePattern:__tostring()

  return type(self)
    ..":column#1="..tostring(self.note_columns[1])

end

-------------------------------------------------------------------------------
-- get midi command from line
-- (look in last note-column, panning + first effect column)
-- @return xMidiCommand or nil if not found

function xLinePattern.get_midi_command(track,line)
  --TRACE("xLinePattern.get_midi_command(track,line)",track,line)

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")

  local note_col = line.note_columns[track.visible_note_columns]
  local fx_col = line.effect_columns[1]

  if (note_col.instrument_value < 255) 
    and (note_col.panning_string:sub(1,1) == "M")
  then
    local msg_type = tonumber(note_col.panning_string:sub(2,2))
    return xMidiCommand{
      instrument_index = note_col.instrument_value+1,
      message_type = msg_type,
      number_value = fx_col.number_value,
      amount_value = fx_col.amount_value,
    }
  end

end

-------------------------------------------------------------------------------
-- set midi command (write to pattern)
-- @param track renoise.Track
-- @param line renoise.PatternLine
-- @param cmd xMidiCommand

function xLinePattern.set_midi_command(track,line,cmd)

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")

  local note_col = line.note_columns[#track.visible_note_columns]
  --[[
  if not note_col then
    LOG("*** Could not locate note-column")
  end
  ]]
  
  -- TODO


end

