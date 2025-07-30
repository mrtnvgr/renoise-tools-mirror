--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Parsing support code
--
-- Original code by Martin Bealby, Optimized code by taktik
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
--lsb_first defined in file_parsing.lua


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function read_byte_from_memory(data, pos)
  -- read a byte at position pos
  if data and pos then
    return string.byte(data, pos)
  end
end


function read_word_from_memory(data, pos)
  -- read a word at position pos
  if data and pos then
    if lsb_first then
      return string.byte(data, pos) + 
        bit.lshift(string.byte(data, pos + 1), 8)
    else
      return string.byte(data, pos + 1) +
        bit.lshift(string.byte(data, pos), 8)
    end
  end 
   
end


function read_dword_from_memory(data, pos)
  -- extract a double word at position pos
  if data and pos then
    if lsb_first then
      return string.byte(data, pos) +
        bit.lshift(string.byte(data, pos + 1), 8) +
        bit.lshift(string.byte(data, pos + 2), 16) +
        bit.lshift(string.byte(data, pos + 3), 24)
    else
      return string.byte(data, pos + 3) +
        bit.lshift(string.byte(data, pos + 2), 8) +
        bit.lshift(string.byte(data, pos + 1), 16) +
        bit.lshift(string.byte(data, pos), 24)
    end
  end
end


function read_string_from_memory(data, pos, len)
  -- read a string at position pos of length len
  if data and pos then
    return string.sub(data, pos, pos + len - 1)
  end
end
