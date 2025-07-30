--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

TPC = {}
TPC.current_song = nil
TPC.GUID = 0  -- FIXME: Need to run through the comments and update the GUID value
-- Or: Store the value of the last-used guid on the comments.
TPC.current_track_index = -1
TPC.current_track_name = ""
TPC.current_pattern_index = -1
TPC.current_line_index = -1
TPC.MAXGUID = 255
TPC.GUID_ERROR = -1
TPC.comments_marker   = "..... Track-pattern Comment .... "
TPC.comment_end_marker = "....."

TPC.guid_start_marker = '..guid..'
TPC.guid_end_marker = '..----..'


function TPC.update_guid_count()
 print("TPC.update_guid_count() ... ")
  TPC.GUID = TPC.read_guid_from_comments()
end


-- *******************************************************************
function TPC.write_guid_to_comments()

  local comments = TPC.current_song.comments
  local start = table.find(comments, TPC.guid_start_marker )

  if start ~= nil then -- The guid value has been previouly written
    local ending = table.find(comments, TPC.guid_end_marker, start)
    local first_line = start+1
    local last_line = ending-1
    for old_line = first_line,last_line do
      table.remove(comments, first_line)
    end
    
    table.insert(comments, first_line, tostring(TPC.GUID))
  
  else -- The guid value has never been saved, so create a spot for it
    local first_line = #comments+1
    table.insert(comments, first_line, "")
    table.insert(comments, first_line, TPC.guid_start_marker  )
    table.insert(comments, first_line+1, tostring(TPC.GUID))
    table.insert(comments, first_line+2, TPC.guid_end_marker )
  end

  TPC.current_song.comments = comments  

end

-- ******************************************************************
function TPC.read_guid_from_comments()
  local guid = 0
  local start = table.find(TPC.current_song.comments, TPC.guid_start_marker)

  if start ~= nil then 
    local ending = table.find(TPC.current_song.comments, TPC.guid_end_marker , start)
    guid = TPC.current_song.comments[start+1]
  end  
  
  return tonumber(guid)
end

-- *************************************************************************
function TPC.find_line_guid_value(track, pattern, line) 
  local fx_ns
  for i=1,8 do 
    fx_ns = renoise.song().patterns[pattern].tracks[track].lines[line].effect_columns[i].number_string 
    if (fx_ns == 'NG' ) then 
      return renoise.song().patterns[pattern].tracks[track].lines[line].effect_columns[i].amount_value
    end
  end
  return nil
end


-- *************************************************************************
-- Search the entire track pattern to find the guid
-- closest to the current line.
-- If no guid then return nil.
function TPC.find_nearest_commnent_guid()
  local selected_line_index = renoise.song().selected_line_index 
  local pattern_index       = renoise.song().selected_pattern_index
  local track_index         = renoise.song().selected_track_index

  local abs_diff = 1000
  local best_index = -1
  local guid = nil

  -- This line is always relative to the current pattern; the first line is 1
  -- print("selected_line_index = " , selected_line_index )

  local fx_iter = renoise.song().pattern_iterator:effect_columns_in_pattern_track(pattern_index, track_index, false)

  for pos, col in fx_iter do
    -- pos is a table.
    -- print("pos.line: ", pos.line, "; col.number_string: ",  col.number_string)
    if (col.number_string == 'NG') then
      if math.abs( pos.line - selected_line_index) < abs_diff then
        best_index = pos.line
        abs_diff = math.abs( pos.line - selected_line_index)
        guid = "NG" .. col.amount_string
      end -- if better match
    end -- if this is an actual GUI
  end -- fx_iter

  return guid
end



-- *************************************************************************
function TPC.insert_guid_fx_marker(pattern_index, track_index, line, fx_col, amount_string)
  -- print("Insert vaue of " .. amount_string)
  renoise.song().patterns[pattern_index].tracks[track_index].lines[line].effect_columns[fx_col].number_string = "NG"
  renoise.song().patterns[pattern_index].tracks[track_index].lines[line].effect_columns[fx_col].amount_string = amount_string
end

-- *************************************************************************
function TPC.find_next_free_fx_column(track_index, pattern, line) 
  local nothing = -1

  local fx_ns
  for i=1,8 do 
    -- print("Check pattern ", pattern, "; track ", track_index, "; line: ", line, "; fx col ", i)
    fx_ns = renoise.song().patterns[pattern].tracks[track_index].lines[line].effect_columns[i].number_string 
    -- It seems that if an fx number slot is empty then it has a default string  of "00"
    -- print("fx_ns: " .. fx_ns)
    if (fx_ns == '00' ) then 
      return i
    end
  end
  return nothing
end

-- *************************************************************************
function TPC.get_current_location_values()
  TPC.current_track_index = TPC.current_song.selected_track_index
  TPC.current_track_name = TPC.current_song.tracks[TPC.current_track_index].name
  TPC.current_pattern_index = TPC.current_song.selected_pattern_index
  TPC.current_line_index = TPC.current_song.selected_line_index
end

-- *************************************************************************
function TPC.get_guids_for_current_pattern_track()
  local guids = {}
  TPC.get_current_location_values()

  for line_idx = 1, TPC.current_song.patterns[TPC.current_pattern_index].number_of_lines do 
    local free_fx_column = TPC.find_next_free_fx_column(TPC.current_track_index, TPC.current_pattern_index, line_idx) 
  end
  return guids 
end

-- *************************************************************************
-- Delete a comment from the song comments
--  TODO: Implement a way to to manage comment deletion
function TPC.delete_comment(guid)
  local comments = TPC.current_song.comments
  local start = table.find(comments, TPC.comments_marker .. guid )
  if start ~= nil then
    local ending = table.find(comments, "...", start)
    for old_line = start,ending+1 do
      table.remove(comments, start)
    end 
  end
  TPC.current_song.comments = comments
end

-- *************************************************************************
function TPC.get_comments(guid)
  local comment = ""

  if (guid == nil ) then
    return comment
  end

  local comment_demarcation = TPC.comments_marker .. guid 
  local start = table.find(TPC.current_song.comments, comment_demarcation)

  if start ~= nil then 
    local ending = table.find(TPC.current_song.comments, TPC.comment_end_marker, start)
    local first_line = start+1
    local last_line = ending-1
    for comment_line = first_line,last_line do
      comment = comment .. TPC.current_song.comments[comment_line]
      if comment_line ~= last_line then
        comment = comment .. "\n"
      end
    end
  end  

  return comment  
end

-- *************************************************************************
function TPC.get_next_guid()
  if (TPC.GUID == TPC.MAXGUID) then
    TPC.GUID = TPC.GUID_ERROR 
  else
    TPC.GUID = TPC.GUID + 1
  end
  TPC.write_guid_to_comments()
  return TPC.GUID 
end

-- *************************************************************************
-- Update the track comments
-- The guid might be nil.  That means this is a new
-- comment.  If so, then the codes to see if there
-- is any comment text.  If so, grab the next guid and use it
-- If not, just return; don't waste a guid.
function TPC.update_comments(guid, text)

  TPC.get_current_location_values()
  -- print("TPC.update_comments has text " .. text )
  if (guid == nil) and (U.is_empty_string(text)) then
    print("Nil guid and empty text so just return.") -- DEBUG
    return -- Do nothing for a new but empty comment
  end

  if (guid == nil) then
    guid = TPC.get_next_guid()
    if (guid == TPC.GUID_ERROR ) then
      print("Reached the max guid; cannot add any more.") --  DEBUG
      U.error_message("You've used up all available comment markers.")
      return
    else

      guid = "NG" .. U.i2hex(guid) 

      -- print("Add comment for TPC.current_track_index ", TPC.current_track_index )
      -- need to insert an fx entry at the next free slot on the current line.
      local available_fx_col = TPC.find_next_free_fx_column(TPC.current_track_index, TPC.current_pattern_index, TPC.current_line_index)  
      if available_fx_col < 0 then
        -- No space on the current line for a new fx item.
        U.error_message("There is no room for a comment entry on the current line.")
        return
      end

      -- add guid to line: available_fx_col
      TPC.insert_guid_fx_marker(TPC.current_pattern_index, TPC.current_track_index, TPC.current_line_index, available_fx_col, string.sub(guid, 3,5) )
    end
  end

  local text_array = U.lines(text)
  local comments = TPC.current_song.comments
  local comment_demarcation = TPC.comments_marker .. guid 
  local start = table.find(comments, comment_demarcation )

  -- print("Using comment_demarcation: ")
  print(comment_demarcation)

  if start ~= nil then -- This guid is in use, we found th previus comments
    local ending = table.find(comments, TPC.comment_end_marker, start)
    local first_line = start+1
    local last_line = ending-1
    for old_line = first_line,last_line do
      table.remove(comments, first_line)
    end
    for v = #text_array,1,-1 do
      table.insert(comments, first_line, text_array[v])
    end
  else -- New comment
    local position = #comments+1
    table.insert(comments, position, "")
    local first_line = position --- FIXME THis looks wonky
    table.insert(comments, first_line, comment_demarcation )
    for v = #text_array,1,-1 do
      table.insert(comments, first_line+1, text_array[v])
    end
    table.insert(comments, first_line+#text_array+1, TPC.comment_end_marker)
  end
  TPC.current_song.comments = comments  
end

return TPC
