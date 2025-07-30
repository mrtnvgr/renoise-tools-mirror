-- Neurogami Utils

--  String stuff
function string.lpad(str, len, char)
  if char == nil then char = ' ' end
  return str .. string.rep(char, len - #str)
end

function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string.lines(s)
  local t = {}
  local function add(line) table.insert(t, line) return "" end
  add((s:gsub("(.-)\r?\n", add)))
  return t
end


function string:words(s)
  local t = {}
  for w in s:gmatch("%S+") do
    table.insert(t, w)
  end
  return t
end

function string:words(s)
  local t = {}
  for w in s:gmatch("%S+") do
    table.insert(t, w)
  end
  return t
end


-- https://helloacm.com/split-a-string-in-lua/
function string.split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end
  return result;
end

-- Other stuff
U = {}


PATH_SEP = "/"
if (os.platform() == "WINDOWS") then
  PATH_SEP = "\\"
end



--- Common util funcitons
function U.clamp_value(value, min_value, max_value)
  return math.min(max_value, math.max(value, min_value))
end


--[[ rPrint(struct, [limit], [indent])   Recursively print arbitrary data. 
Set limit (default 100) to stanch infinite loops.
Indents tables as [KEY] VALUE, nested tables as [KEY] [KEY]...[KEY] VALUE
Set indent ("") to prefix each line:    Mytable [KEY] [KEY]...[KEY] VALUE
--]]
function U.rPrint(s, l, i) -- recursive Print (structure, limit, indent)
  l = (l) or 100; i = i or "";  -- default item limit, indent string
  if (l<1) then print "ERROR: Item limit reached."; return l-1 end;
  local ts = type(s);
  if (ts ~= "table") then print (i,ts,s); return l-1 end
  print (i,ts);           -- print "table"
  for k,v in pairs(s) do  -- print "[KEY] VALUE"
    l = U.rPrint(v, l, i.."\t["..tostring(k).."]");
    if (l < 0) then break end
  end
  return l
end  

-- http://lua-users.org/wiki/SleepFunction
local clock = os.clock
function U.sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end



function U.base_file_name()
  local fname = renoise.song().file_name
  local parts = string.split(fname, PATH_SEP )
  local xname = parts[#parts]
  return xname
end


-- Taken from the CreateTool tool.
-- Why does Renoise Lua not have os.copyfile?

ERROR = {OK=1, FATAL=2, USER=3}

-- Reads entire file into a string
-- (this function is binary safe)
function U.file_get_contents(file_path)
  local mode = "rb"  
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local data=file_ref:read("*all")        
    io.close(file_ref)    
    return data
  else
    return nil,err;
  end
end

-- Writes a string to a file
-- (this function is binary safe)
function U.file_put_contents(file_path, data)
  local mode = "w+b" -- all previous data is erased
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local ok=file_ref:write(data)
    io.flush(file_ref)
    io.close(file_ref)    
    -- print("file_ref returned ", ok ) -- DEBUG
    return ok
  else
    return nil,err;
  end
end


-- Copies the contents of one file into another file.
function U.copy_file_to(source, target)      
  local error = nil
  local code = ERROR.OK
  local ok = nil
  local err = true

  if (not io.exists(source)) then    
    error = "The source file\n\n" .. source .. "\n\ndoes not exist"
    code = ERROR.FATAL
  end
  if (not error and U.may_overwrite(target)) then
    local source_data = U.file_get_contents(source, true)    
    ok,err = U.file_put_contents(target, source_data)        
    error = err          
    -- print("file_put_contents returned ok = ", ok )
  else 
    print("There was an error: ", error )
    code = ERROR.USER
  end
  return ok, error, code
end


-- If file exists, popup a modal dialog asking permission to overwrite.
function U.may_overwrite(path)
  local overwrite = true
  if (io.exists(path) ) then
    local buttons = {"Overwrite", "Keep existing file"}
    local choice = renoise.app():show_prompt("File exists", "The file\n\n " ..path .. " \n\n"
    .. "already exists. Overwrite existing file?", buttons)
    
    overwrite = (choice~=buttons[2])
  end  
  return overwrite
end


return U
