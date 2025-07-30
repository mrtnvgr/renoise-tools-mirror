
-- *************************
function string.trim(s)
  if s == nil then
    return "" -- Is this a good idea?  TODO Think if silently converting nil to an empty string is a Good Thing
  else
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end
end

-- *********************************************************************
function string.to_word_table(s)
  local words = {}
  for w in s:gmatch("%S+") do table.insert(words, w) end
  return words
end


-- *********************************************************************
function string.int_list_to_numeric(s)
  local ints = {}
  for w in s:gmatch("%S+") do table.insert( ints, tonumber(w) ) end
  return ints
end



U = {}

-- From https://stackoverflow.com/questions/22185684/how-to-shift-all-elements-in-a-table
function U.wrap( t, l )
  for i = 1, l do
    table.insert( t, 1, table.remove( t, #t ) )
  end
  return t
end


-- *********************************************************************
function U.i2hex(i)
  return string.format("%02x", i)
end

-- *********************************************************************
function U.is_empty_string(str)
  local _s = string.trim(str)
  return _s == ''
end

-- *********************************************************************
-- Split string into array (split at newline)
function U.lines(str)
  local t = {}
  local function helper(line)
    table.insert(t, line)
    return ""
  end
  helper((str:gsub("(.-)\r?\n", helper))) 
  return t  
end

-- *********************************************************************
-- If file exists, popup a modal dialog asking permission to overwrite.
function U.error_message(message)
  local buttons = {"OK"}
  renoise.app():show_prompt(message, buttons)
end


function U.str_table_to_int(t)
  for k,s in pairs(t) do 
    t[k] = tonumber(s)
  end

end


return U

