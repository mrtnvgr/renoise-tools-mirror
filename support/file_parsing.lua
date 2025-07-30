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
lsb_first = true  --endianness


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function read_byte_from_file(fobj, pos)
  -- read a byte at position pos
  if fobj and pos then
    fobj:seek("set", pos-1)  -- index from 1 like the rest of lua
    return read_byte_from_memory(fobj:read(1), 1)
  end
end


function read_word_from_file(fobj, pos)
  -- read a word at position pos
  if fobj and pos then
    fobj:seek("set", pos-1)  -- index from 1 like the rest of lua
    return read_word_from_memory(fobj:read(2), 1)
  end
end


function read_dword_from_file(fobj, pos)
  -- read a dword at position pos
  if fobj and pos then
    fobj:seek("set", pos-1)  -- index from 1 like the rest of lua
    return read_dword_from_memory(fobj:read(4), 1)
  end
end


function read_string_from_file(fobj, pos, len)
  -- read a dword at position pos
  if fobj and pos then
    fobj:seek("set", pos-1)  -- index from 1 like the rest of lua
    return read_string_from_memory(fobj:read(len), pos, len)
  end
end
