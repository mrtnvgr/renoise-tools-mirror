--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- File tools support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function split_filename(filename)
  -- Splits a qualified filename into path and filename and returns each or
  -- "", "" on error
  local start_pos = nil
  local end_pos = nil
  local i = 1
  local found = false
  
  -- start of filename (end of path)
  while found == false do
    start_pos = string.find(filename, '[/\\]', -i)
    i = i + 1
    if i > string.len(filename) then 
      return "",""
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
      return "",""
    end
    if end_pos ~= nil then
      found = true
    end
  end
  -- return path/filename
  return string.sub(filename,1, start_pos), string.sub(filename,start_pos+1, end_pos-1)
end


function load_file_to_memory(filename)
  -- Loads the entire contents of the file identified by (qualified) filename
  -- into 'memory' and returns the data or "" on error
  local cache
  local f = io.open(filename, "rb")
  
  if f == nil then
    return ""
  end
  
  f:seek("set", 0)
  cache = f:read("*a")
  io.close(f)
  
  return cache
end


function get_samples_path(instrument_name, instrument_path, sample_filename)
  -- Intelligently guess the sample path from the supplied instrument name,
  -- example sample filename and instrument path
  -- Ask the user if we cannot find it ourselves
  -- Return "" on error/abort
  local sample_path
  
  if io.exists(instrument_path .. sample_filename) == true then
    return instrument_path
  elseif io.exists(instrument_path .. instrument_name .. "/" .. sample_filename) == true then
    return instrument_path .. instrument_name .. "/"
  elseif io.exists(instrument_path .. "samples/" .. sample_filename) == true then
    return instrument_path .. "samples/"
  elseif io.exists(instrument_path .. instrument_name .."-samples/" ..sample_filename) == true then
    return instrument_path .. instrument_name .. "-samples/"
  elseif io.exists(instrument_path .. instrument_name .."_samples/" .. sample_filename) == true then
    return instrument_path .. instrument_name .. "_samples/"
  elseif io.exists(instrument_path .. instrument_name .." samples/" .. sample_filename) == true then
    return instrument_path .. instrument_name .. " samples/"
  elseif io.exists("/Library/Application Support/GarageBand/Instrument Library/Sampler/Sampler Files/" .. instrument_name .. "/" .. sample_filename) == true then  -- added v1.1
    return "/Library/Application Support/GarageBand/Instrument Library/Sampler/Sampler Files/" .. instrument_name .. "/"
  else
  --[[
    if os.getenv("HOME") ~= nil then
      if io.exists(os.getenv("HOME") .. "/Library/Application Support/GarageBand/Instrument Library/Sampler/Sampler Files/" .. instrument_name .. "/" .. sample_filename) == true then  -- added v1.1
        return os.getenv("HOME") .. "/Library/Application Support/GarageBand/Instrument Library/Sampler/Sampler Files/" .. instrument_name .. "/"
      end
    else]]--
      return renoise.app():prompt_for_path("Location of samples for patch: " .. instrument_name)
 --   end
  end
end


function akaii_to_ascii(akaii_string)
  -- Convert 'AKAII' to ASCII for AKAI naming in certain samplers
  local len = akaii_string:len()
  local ascii_string = ""
  
  for i=1, len do
    if string.byte(akaii_string:sub(i,i)) < 10 then
      -- number
      ascii_string = ascii_string .. string.char(string.byte(akaii_string:sub(i,i)) + 48)
    elseif string.byte(akaii_string:sub(i,i)) == 10 then
      -- space
      ascii_string = ascii_string .. " "
    elseif string.byte(akaii_string:sub(i,i)) > 10 then
      if string.byte(akaii_string:sub(i,i)) < 37 then
        -- letter
        ascii_string = ascii_string .. string.char(string.byte(akaii_string:sub(i,i)) + 86)
      elseif string.byte(akaii_string:sub(i,i)) == 37 then 
        -- #
        ascii_string = ascii_string .. "#"
      elseif string.byte(akaii_string:sub(i,i)) == 38 then 
        -- +
        ascii_string = ascii_string .. "+"
      elseif string.byte(akaii_string:sub(i,i)) == 39 then 
        -- -
        ascii_string = ascii_string .. "-"
      elseif string.byte(akaii_string:sub(i,i)) == 40 then 
        -- .
        ascii_string = ascii_string .. "."
      end
    end
  end
  return ascii_string
end
