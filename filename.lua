--------------------------------------------------------------------------------
-- Batch Rendering Tool
--
-- Copyright 2011 Martin Bealby
--
-- File name support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function split_filename(filename)
  --[[
    Description: This function parses a specified filename and splits it into
                 three separate strings - path, filename and extension
    Parameters : filename - Fully qualified filename (i.e. includes path)
    Returns    : Three strings 'path, filename, extension' or "","","" on error
  ]]--

  assert(type(filename) == "string", "'filename' is not a string")

  local start_pos = nil
  local end_pos = nil
  local i = 1
  local found = false

  -- start of filename (end of path)
  while found == false do
    start_pos = string.find(filename, '[/\\]', -i)
    i = i + 1
    if i > string.len(filename) then
      return "","",""
    end
    if start_pos ~= nil then
      found = true
    end
  end

  -- end of filename
  found = false
  i = 1
  while found == false do
    end_pos = string.find(filename, '[.]', -i)
    i = i + 1
    if i > string.len(filename) then
      return "","",""
    end
    if end_pos ~= nil then
      found = true
    end
  end
  -- return path/filename
  return string.sub(filename,1, start_pos),
         string.sub(filename,start_pos+1, end_pos-1),
         string.sub(filename,end_pos+1)
end
