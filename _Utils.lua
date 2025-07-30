
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


return U
