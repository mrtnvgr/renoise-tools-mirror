--[[============================================================================
xDebug
============================================================================]]--

--[[--

Debug tracing & logging
.
#

Set one or more expressions to either show all or only a few messages 
from `TRACE` calls.

Some examples: 
     {".*"} -> show all traces
     {"^Display:"} " -> show traces, starting with "Display:" only
     {"^ControlMap:", "^Display:"} -> show "Display:" and "ControlMap:"

]]

--==============================================================================

--_trace_filters = {".*"}


class 'xDebug'

--------------------------------------------------------------------------------

function xDebug.serialize(obj)
  local succeeded, result = pcall(tostring, obj)
  if succeeded then
    return result 
  else
   return "???"
  end
end

--------------------------------------------------------------------------------

function xDebug.concat_args(...)

  local result = ""

  -- concat args to a string
  local n = select('#', ...)
  for i = 1, n do
    local obj = select(i, ...)
    if( type(obj) == 'table') then
      result = result .. xDebug.rdump(obj)
    else
      result = result .. xDebug.serialize(select(i, ...))
      if (i ~= n) then 
        result = result .. "\t"
      end
    end
  end

  return result

end

--------------------------------------------------------------------------------

function xDebug.rdump(t, indent, done)

  local result = "\n"
  done = done or {}
  indent = indent or string.rep(' ', 2)
  
  local next_indent
  for key, value in pairs(t) do
    if (type(value) == 'table' and not done[value]) then
      done[value] = true
      next_indent = next_indent or (indent .. string.rep(' ', 2))
      result = result .. indent .. '[' .. xDebug.serialize(key) .. '] => table\n'
      xDebug.rdump(value, next_indent .. string.rep(' ', 2), done)
    else
      result = result .. indent .. '[' .. xDebug.serialize(key) .. '] => ' .. 
        xDebug.serialize(value) .. '\n'
    end
  end
  
  return result
end

--------------------------------------------------------------------------------
-- calling this will iterate through the entire tool and remove all TRACE
-- statements (for internal use only!!)

function xDebug.remove_trace_statements()

  local msg = "Remove all TRACE statements from source files?"
  local choice = renoise.app():show_prompt("Confirm",msg,{"OK","Cancel"})
  if (choice == "Cancel") then
    return 
  end

  local str_path = renoise.tool().bundle_path
  local file_ext = {"*.lua"}

  -- @return false to stop recursion
  local callback_fn = function(path,file,type)

    if (type == xFilesystem.FILETYPE.FILE) then
      local file_path = path .. "/"..file
      local str_text,err = xFilesystem.load_string(file_path)
      if not str_text then
        if err then
          renoise.app():show_warning(err)
        end
        return false
      end
      local str_new = string.gsub(str_text,"\n%s*TRACE([^\n]*","")
      local passed,err = xFilesystem.write_string_to_file(file_path,str_new)
      if not passed then
        if err then
          renoise.app():show_warning(err)
        end
        return false
      end

    end
  
    return true

  end

  xFilesystem.recurse(str_path,callback_fn,file_ext)

end

--==============================================================================
-- Global namespace
--==============================================================================

-- use LOG to print important messages to the console (errors and warnings)
-- @param (vararg)

function LOG(...)
  local result = ""
  local n = select('#', ...)
  for i = 1, n do
    result = result .. tostring(select(i, ...)) .. "\t"
  end
  print(result)
end

--------------------------------------------------------------------------------
--- TRACE implementation, provide detailed, filtered output 
-- @param (vararg)

if (_trace_filters ~= nil) then
  
  function TRACE(...)

    local result = xDebug.concat_args(...)
  
    -- apply filter
    for _,filter in pairs(_trace_filters) do
      if result:find(filter) then
        print(result)
        break
      end
    end
  end
  
else

  function TRACE()
    -- do nothing
  end
    
end

