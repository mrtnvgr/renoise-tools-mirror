-- Load the configuration in the file.ini
function load_configuration(iniFile)

  local file = io.open(iniFile, "r")
  local configuration = {}
  local tag = nil
  local item = nil
  local value = nil

  for line in file:lines() do
    
      if(string.sub(line,1,1) == "[") then
        tag = string.sub(line, 2, string.len(line) - 1 )
        configuration[tag] = {}
      else
        if(trim(line) ~= "") then
          item = string.sub(line, 1, string.find(line, "=") - 1)
          value = string.sub(line, string.find(line, "=") + 1)
          configuration[tag][item] = value
        end
     end

  end

  file:close()
  return configuration

end


-- Save the configuration in the file.ini
function save_configuration(path, tab)

    assert(path ~= nil, "Path can\'t be nil")
    assert(type(tab) == "table", "Second parameter must be a table")

    local f = io.open(path, "w")
    local i = 0

    for key, value in pairs(tab) do
        if i ~= 0 then
            f:write("\n")
        end
        f:write("["..key.."]".."\n")

        for key2, value2 in pairs(tab[key]) do
            key2 = trim(key2)
            value2 = trim(value2)
            key2 = key2:gsub(";", "\\\\;")
            key2 = key2:gsub("=", "\\\\=")
            value2 = value2:gsub(";", "\\\\;")
            value2 = value2:gsub("=", "\\\\=")
            f:write(key2.."="..value2.."\n")
        end

        i = i + 1
    end

    f:close()
end

-- Remove the spaces in the string
function trim (s)
      return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

--[[

TEST

local iniFile = "c:\\\\teste.ini"

-- To save a configuration in file.ini try somenthing like this:
configuration = {system = {buffer = 2 , user="john"}, database = {ip = "1.1.1.1", port = 8}}

save_configuration("C:\\\\Users\\Fabrizio\\Documents\\Lua files\\pippo.ini", configuration)

local rx = load_configuration("C:\\\\Users\\Fabrizio\\Documents\\Lua files\\pippo.ini", configuration)
]]
