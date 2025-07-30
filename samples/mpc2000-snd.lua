--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai MPC2000 SND file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function mpc2000_loadsample(filename, load_sample_here)
  local smp 
  local d = "" -- in memory copy
  local aiff_file = ""
  local loop_start = 0
  local loop_end = 0
  local loop_mode = renoise.Sample.LOOP_MODE_OFF
  local t -- temp
  
  -- Set endianness
  lsb_first = true
  
  -- select sample
  if load_sample_here == nil then
    smp = renoise.song().selected_sample
  else
    smp = load_sample_here
  end
  
  renoise.app():show_status("Importing MPC2000/XL Sample...")
  dprint("mpc2000_loadsample: filename=", filename)
  
  
  local f_in = io.open(filename, "rb")
  
  -- Did we open the file successfully
  if f_in == nil then
    renoise.app():show_status("Couldn't open sample file: " .. filename .. ".")
    return false
  end
  
  f_in:seek("set")
   
  d = f_in:read("*a")
  
  -- close file descriptors
  f_in:close()

  -- check validity
  if read_word_from_memory(d, 1) ~= 1025 then
    d = ""
    return false
  end

  -- generate aiff
  aiff_file = generate_aiff(read_byte_from_memory(d, 22) + 1,
                            read_word_from_memory(d, 41), 16, d:sub(44))
  

  -- import audio
  if smp.sample_buffer.has_sample_data == true then
    if smp.sample_buffer.read_only == true then
      -- abort
      d=""
      return false
    end
  end
  
  smp:clear()
  if smp.sample_buffer:load_from(aiff_file) == false then
    d=""
    return false
  end

  -- get metadata 
  loop_end = read_dword_from_memory(d, 27)
  if loop_end > read_dword_from_memory(d, 31) then
    loop_end = read_dword_from_memory(d, 31)
  end
  loop_start = loop_end - read_dword_from_memory(d, 35) + 1
  if loop_start < 0 then
    loop_start = 0
  end
  t = read_byte_from_memory(d, 39)
  if t == 1 then
    loop_mode = renoise.Sample.LOOP_MODE_FORWARD
  end
  
  -- set metadata
  smp.name = read_string_from_memory(d, 3, 16)
  smp.transpose = byte_to_twos_compliment(read_byte_from_memory(d, 21))
  if loop_mode == renoise.Sample.LOOP_MODE_FORWARD then
    smp.loop_start = loop_start
    smp.loop_end = loop_end
    smp.loop_mode = loop_mode
  end
  -- success
  d=""
  
  return true
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
function snd_integration_func(filename)
  mpc2000_loadsample(filename, nil, renoise.song().selected_sample, nil)
  return true
end

snd_integration = { category = "sample",
                    extensions = {"snd"},
                    invoke = snd_integration_func}  -- returns true

if renoise.tool():has_file_import_hook("sample", {"snd"}) == false then
  renoise.tool():add_file_import_hook(snd_integration)
end
