--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Propellerheads Recycle REX file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function rex_loadsample(filename)
  local smp = renoise.song().selected_sample
  local d = "" -- in memory copy
 

  renoise.app():show_status("Importing Recycle REX Sample...")
  dprint("rex_loadsample: filename=", filename)
  
  -- make sure we are the first sample:
  if renoise.song().selected_sample_index ~= 1 then
    -- clear instrument
    renoise.song().selected_instrument:clear()
    smp = renoise.song().selected_sample
  end


  -- copy to aiff
  local aiff_copy = os.tmpname("aiff")
  
  dprint("rex_loadsample: aiff_copy=", aiff_copy)
  
  local f_in = io.open(filename, "rb")
  
  -- Did we open the file successfully
  if f_in == nil then
    renoise.app():show_status("Couldn't open sample file: " .. filename .. ".")
    return false
  end
  
  local f_out = io.open(aiff_copy, "wb")
  
  -- Did we open the file successfully
  if f_in == nil then
    renoise.app():show_status("Couldn't open sample file: " .. aiff_copy .. ".")
    return false
  end
  
  f_in:seek("set")
  f_out:seek("set")
   
  d = f_in:read("*a")
  f_out:write(d)

  f_out:flush()
  
  -- close file descriptors
  f_in:close()
  f_out:close()
  
  -- import audio
  if smp.sample_buffer.has_sample_data == true then
    if smp.sample_buffer.read_only == true then
      -- abort
      return false
    end
  end
  
  smp:clear()
  if smp.sample_buffer:load_from(aiff_copy) == false then
    return false
  end

  local working = true
  local start_pos = nil

  -- add slice markers
  while working == true do
    dprint("rex_loadsample: finding 'REX ' chunk...")
    start_pos = d:find("REX ", 0)
    if start_pos == nil then
      dprint("rex_loadsample: couldn't find rex info. not adding slices")
      working = false
      d = ""
      return true
    else
      dprint("rex_loadsample: found 'REX ' chunk at ",start_pos)
      working = false
    end
  end

  -- move to start of slices
  start_pos = start_pos + 1032
  working = true
  local slice = 1
  
  -- big endian!
  lsb_first = false
  
  while working == true do
    slice = read_dword_from_memory(d, start_pos) + 1
    if slice == 1 then
      working = false
    else
      dprint("rex_loadsample: found slice marker with value ", slice)
      start_pos = start_pos + 12
      -- add the slice
      smp:insert_slice_marker(slice)
    end
  end
  
  -- add the first slice
  smp:insert_slice_marker(1)
  
  -- clear memory
  d = ""

  -- success
  return true
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
rex_integration = { category = "sample",
                    extensions = {"rex"},
                    invoke = rex_loadsample}  -- returns true

if renoise.tool():has_file_import_hook("sample", {"rex"}) == false then
  renoise.tool():add_file_import_hook(rex_integration)
end
