--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Binary manipulation code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function byte_to_twos_compliment(value)
  -- convert a raw byte (read from memory/file) to a two compliment signed value
  if value == 0x80 then
    return -128
  elseif value < 0x80 then
    return value
  else
    return -128+(value-0x80)
  end
end


function word_to_twos_compliment(value)
  -- convert a raw word (read from memory/file) to a two compliment signed value
  if value == 0x8000 then
    return -32786
  elseif value < 0x8000 then
    return value
  else
    return -32768+(value-0x8000)
  end
end


function dword_to_twos_compliment(value)
  -- convert a raw dword (read from memory/file) to a two compliment signed value
  if value == 0x80000000 then
    return -2147483648
  elseif value < 0x80000000 then
    return value
  else
    return -2147483648+(value-0x80000000)
  end
end
