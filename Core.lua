
--=======================================================================
function print_pairs(t)
  for k,v in pairs(t) do
    print(k, " => ", v)
  end
end

--=======================================================================
-- Takes a list of ints, the number of lines in the pattern, 
-- and the current list of line numbers.
-- The new numbers are created by incrementing from 0
-- and adding each of the `inc_list` values.
--  E.g. 3,2 => 3,5,8,10,13
--  E.g. 3,2,5 => 3,5,10,13,15,20
--
-- The function makes no effort to check for negative increment values 
-- Returns that current list with the generated line numbers inserted, without duplicates
-- That list is unsorted.  
--=======================================================================
function sequence_from_inc_set(inc_list, lines_in_pattern, current_set)
  local inc = 0
  print("sequence_from_inc_set is  using current set:")
  print_pairs(current_set)

  for i=1,lines_in_pattern do 
    inc = inc + inc_list[1]
    if (inc > lines_in_pattern) then
      break
    end

    current_set[inc] = inc
    inc_list = U.wrap(inc_list, 1)
  end

  return current_set
end


--=======================================================================
-- Takes a list of ints, the number of lines in the pattern, 
-- and the current list of line numbers
-- The new numbers are base on whether any LINE_NUM % MOD_INT == 0
--  E.g 3,5 gives 3,5,6,9,10,12,15,18,20, ...
-- Returns that current list with the generated line numbers inserted, 
--    without duplicates
-- That list is unsorted.  
--=======================================================================
function sequence_from_mod_set(mod_list, lines_in_pattern, current_num_set)

  print("We have been passed current_num_set : ")
  print_pairs(current_num_set)

  for i=1,lines_in_pattern do 
    for k,v in pairs(mod_list) do
      if not (i <  v) then
        if ( (i%v == 0 )  ) then
          current_num_set[i] = i
        end
      end

    end
  end


  return current_num_set
end

--=======================================================================
Core = {}


--[[ *******************************************************************
Loop over each line in the applicable note columns.

Clear all volume settings.

Original plan was to keep vol if there was a note on that line,
but that now feels like it applies more to edge cases.
******************************************************************* --]] 
function clear_existing_volumes()

  local _ti = renoise.song().selected_track_index
  local _pi   = renoise.song().selected_pattern_index
  local _co11 = renoise.song().selected_note_column_index
  local _co12 = renoise.song().selected_note_column_index + 1
  local _tp   = renoise.song().patterns[_pi].tracks[_ti]
  local lines_in_pattern = renoise.song().patterns[_pi].number_of_lines


  for i=1,lines_in_pattern do   
    -- if (121 == _tp.lines[i].note_columns[_co11].note_value) then
    _tp.lines[i].note_columns[_co11].volume_string = ''  
    _tp.lines[i].note_columns[_co12].volume_string = ''  
    -- end
  end

  --[[  for i=1,lines_in_pattern-1 do   
  -- if (121 == _tp.lines[i].note_columns[_co12].note_value) then
  _tp.lines[i].note_columns[_co12].volume_string = ''  
  -- end
end
--]]
--
end -- func


-- ======================================================================
-- Assumes current selected note column and column to the right
-- FIXME Need error prevention: 
--  look for 
--    empty or nil values.
--    Out-of-range line numbers  (else it errors out)
--    Out of range volume values
-- ======================================================================
function volume_swap(max_vol1, max_vol2, lines_list)
  print("volume_swap. lines_list:")
  rprint(lines_list)
  clear_existing_volumes()

  local _ti = renoise.song().selected_track_index
  local _pi   = renoise.song().selected_pattern_index
  local _co11 = renoise.song().selected_note_column_index
  local _co12 = renoise.song().selected_note_column_index + 1
  local _tp   = renoise.song().patterns[_pi].tracks[_ti]
  local _col1_active = false
  local lines_in_pattern = renoise.song().patterns[_pi].number_of_lines


  _tp.lines[1].note_columns[_co11].volume_string = max_vol1  
  _tp.lines[1].note_columns[_co12].volume_string = '00'

  local v = 0
  for i,l in ipairs(lines_list) do
    v = l + 1
    print(tostring(v))


    if ( v <= lines_in_pattern ) then
      if (_col1_active == true ) then
        _tp.lines[v].note_columns[_co11].volume_string = max_vol1  
        _tp.lines[v].note_columns[_co12].volume_string = '00'
      else
        _tp.lines[v].note_columns[_co11].volume_string = '00'  
        _tp.lines[v].note_columns[_co12].volume_string = max_vol2 
      end

      _col1_active =  not _col1_active 
    end
  end

end


function Core.new_set_from_funct_string(function_str, current_set)

  
  local _pi   = renoise.song().selected_pattern_index
  local lines_in_pattern = renoise.song().patterns[_pi].number_of_lines


  local func_table = string.to_word_table(function_str)
  local func_char = table.remove(func_table, 1)

  U.str_table_to_int(func_table)
  local generated_line_table = {}
  local sorted_line_numbers = {}

  print("Dispatch on '" .. "'" .. func_char .. "'")

  if (func_char == "+") then
    generated_line_table = sequence_from_inc_set(func_table, lines_in_pattern, current_set)
  end

  if (func_char == "/") then
    generated_line_table = sequence_from_mod_set(func_table, lines_in_pattern, current_set)
  end
  for n in pairs(generated_line_table) do table.insert(sorted_line_numbers, n) end

  table.sort(sorted_line_numbers)

  return sorted_line_numbers
end


-- ======================================================================
Core.set_swap_values = function(gui)
  local vol1 = gui.col1_vol
  local vol2 = gui.col2_vol
  local lines_list = string.int_list_to_numeric(gui.lines_list)
  volume_swap( string.trim(vol1), string.trim(vol2), lines_list)
end

return Core

