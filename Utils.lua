
function string.trim(s)
  if s == nil then
    return "" -- Is this a good idea?  TODO Think if silently converting nil to an empty string is a Good Thing
  else
   return (s:gsub("^%s*(.-)%s*$", "%1"))
  end
end

U = {}

function U.i2hex(i)
   return string.format("%02x", i)
end

function U.is_empty_string(str)
   local _s = string.trim(str)
   return _s == ''
end

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

function U.error_message(message)
  local buttons = {"OK"}
  renoise.app():show_prompt(message, buttons)
end

return U
