--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Hexadecimal manipulation code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function hex_pack(string)
  local raw_string = string.char(tonumber(string:sub(1,2), 16))                    
  for i = 3, (string:len()-1), 2 do
    raw_string = raw_string .. string.char(tonumber(string:sub(i,i+1), 16))
  end
  return raw_string
end


function hex_pack_reversed(string)
  local raw_string = string.char(tonumber(string:sub(string:len()-1,string:len()), 16))                    
  for i = string:len()-3, 1, -2 do
    raw_string = raw_string .. string.char(tonumber(string:sub(i,i+1), 16))
  end
  return raw_string
end
