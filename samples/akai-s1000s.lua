--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai S1000/S3000 .s sample file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function s1000_get_basenote_from_sample(filename)
  -- extract the base note from the supplied .s format sample
  -- used for s1000 .p program loading
  local d = "" -- in memory copy
  -- Set endianness
  lsb_first = true

  local f_in = io.open(filename, "rb")
  
  -- Did we open the file successfully
  if f_in == nil then
    dprint("s1000_get_basenote_from_sample: couldn't open .s sample", filename)
    return nil
  end
  
  f_in:seek("set")
   
  d = f_in:read("*a")
  
  -- close file descriptors
  f_in:close()

  -- check validity
  if read_byte_from_memory(d, 1) ~= 3 then
    dprint("s1000_get_basenote_from_sample: not an akai s1000 .s sample")
    d = ""
    return nil
  elseif read_byte_from_memory(d, 16) ~= 128 then
    dprint("s1000_get_basenote_from_sample: not an akai s1000 .s sample")
    d = ""
    return nil
  end

  local base_note = read_byte_from_memory(d, 3)
  dprint("s1000_get_basenote_from_sample: base_note", base_note)
  d =""
  return base_note
end


function s1000_loadsample(filename, load_sample_here)
  local smp 
  local d = "" -- in memory copy
  local aiff_file = ""
  local loop_start = 0
  local loop_end = 0
  local sample_name = ""
  local sample_rate = 0
  local fine_tune = 0
  local transpose = 0
  local active_loop_count = 0
  local t -- temp
  
  -- Set endianness
  lsb_first = true
  
  -- select sample
  if load_sample_here == nil then
    smp = renoise.song().selected_sample
  else
    smp = load_sample_here
    renoise.app():show_status("Importing Akai S1000/S3000 Sample...")
  end
  
  
  dprint("s1000_loadsample: filename=", filename)
  
  
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
  if read_byte_from_memory(d, 1) ~= 3 then
    dprint("s1000_loadsample: invalid file (byte1)")
    d = ""
    return false
  elseif read_byte_from_memory(d, 16) ~= 128 then
    dprint("s1000_loadsample: invalid file (byte16)")
    d = ""
    return false
  end
  
  -- get metadata
  sample_name = akaii_to_ascii(d:sub(4,15))
  sample_rate = read_word_from_memory(d, 139)
  fine_tune = byte_to_twos_compliment(read_byte_from_memory(d, 21))
  transpose = byte_to_twos_compliment(read_byte_from_memory(d, 22))
  active_loop_count = read_byte_from_memory(d, 17)
  
  dprint("s1000_loadsample: sample_name", sample_name)
  dprint("s1000_loadsample: sample_rate", sample_rate)
  dprint("s1000_loadsample: fine_tune", fine_tune)
  dprint("s1000_loadsample: transpose", transpose)
  dprint("s1000_loadsample: active_loop_count", active_loop_count)

  -- generate aiff
  aiff_file = generate_aiff(1, sample_rate, 16,
                            d:sub(150))
  

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

  
  -- set metadata
  smp.fine_tune = fine_tune
  smp.transpose = transpose
  smp.name = sample_name
  
  
  -- set looping
  if active_loop_count ~= 0 then
    -- use loop 1
    loop_start = read_dword_from_memory(d, 39)
    loop_end = loop_start + read_dword_from_memory(d, 45)
    -- validate
    if loop_start < 0 then
      loop_start = 0
    elseif loop_start > renoise.song().selected_sample.sample_buffer.number_of_frames then
      loop_start = renoise.song().selected_sample.sample_buffer.number_of_frames
    end
    if loop_end < 0 then
      loop_end = 0
    elseif loop_end > renoise.song().selected_sample.sample_buffer.number_of_frames then
      loop_end = renoise.song().selected_sample.sample_buffer.number_of_frames
    end
    
    dprint("s1000_loadsample: loop_start", loop_start)
    dprint("s1000_loadsample: loop_end", loop_end)
    
    smp.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
    smp.loop_start = loop_start
    smp.loop_end = loop_end
    
  end

  -- success
  d=""
  
  return true
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
function s_integration_func(filename)
  s1000_loadsample(filename, nil)
  return true
end

s_integration = { category = "sample",
                  extensions = {"s"},
                  invoke = s_integration_func}  -- returns true

if renoise.tool():has_file_import_hook("sample", {"s"}) == false then
  renoise.tool():add_file_import_hook(s_integration)
end
