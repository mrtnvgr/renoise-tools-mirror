--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Korg Triton KSF Sample file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function ksf_loadsample(filename, load_sample_here)
  local smp
  local d = "" -- in memory copy
  local smd_offset = 0
  local bit_depth = 0
  local sample_rate = 0
  local channels = 0
  local frames = 0
  local loop_enabled = true
  local loop_start = 0
  local loop_end = 0
  local aiff_file = ""

  -- Set endianness
  lsb_first = false  

  -- select sample
  if load_sample_here == nil then
    smp = renoise.song().selected_sample
  else
    smp = load_sample_here
  end

  dprint("ksf_loadsample: filename=", filename)
  
  
  local f_in = io.open(filename, "rb")
  
  -- Did we open the file successfully
  if f_in == nil then
    renoise.app():show_status("Couldn't open sample file: " .. filename .. ".")
    return false
  end
  
  f_in:seek("set")
   
  d = f_in:read("*a")
  
  f_in:close()
  
  -- check validity
  if read_string_from_memory(d, 1, 4) ~= "SMP1" then
    d = ""
    return false
  end
  
  -- find "SMD1" chunk
  smd_offset = d:find("SMD1")
  
  if smd_offset == nil then
    d = ""
    return false
  end
  
  dprint("ksf_loadsample: smd_offset", smd_offset)
   
  
  if bit.band(0x10, read_byte_from_memory(d,smd_offset+12)) == 0x10 then
    d = ""
    dprint("ksf_loadsample: compressed file! ignoring!")
    renoise.app():show_status("Cannot currently handle compressed Korg Triton KSF samples.  Aborting")
    return false
  end
  
  bit_depth = read_byte_from_memory(d, smd_offset+15)
  sample_rate = read_dword_from_memory(d, smd_offset+8)
  channels = read_byte_from_memory(d, smd_offset+14)
  frames = read_dword_from_memory(d, smd_offset+16)
  loop_start = read_dword_from_memory(d, 33)
  loop_end = read_dword_from_memory(d, 37) - 1
  
  if bit.band(0x80, read_byte_from_memory(d,smd_offset+12)) == 0x80 then
    loop_enabled = false
  end
  
  dprint("ksf_loadsample: bit depth", bit_depth)
  dprint("ksf_loadsample: sample rate", sample_rate)
  dprint("ksf_loadsample: channels", channels)
  dprint("ksf_loadsample: frame count", frames)
  dprint("ksf_loadsample: loop start", loop_start)
  dprint("ksf_loadsample: loop end", loop_end)
  dprint("ksf_loadsample: dlen", d:len())
  
  if d:len() < (frames*2) + smd_offset + 19 then
    -- corrupt file
    d = ""
    dprint("ksf_loadsample: corrupt ksf file")
    renoise.app():show_status("Corrupt Korg Triton KSF Sample: " .. filename .. ".")
    return false
  end

  aiff_file = generate_aiff(channels, sample_rate, bit_depth, d:sub(smd_offset+20))
  
  d=""
  
  -- import audio
  if smp.sample_buffer.has_sample_data == true then
    if smp.sample_buffer.read_only == true then
      -- abort
      return false
    end
  end
  
  smp:clear()
  if smp.sample_buffer:load_from(aiff_file) == false then
    return false
  end
  
  d, smp.name = split_filename(filename)
  d =""
  
  if loop_enabled then
    smp.loop_start = loop_start
    smp.loop_end = loop_end
    smp.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
  end
  -- success
  return true
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
ksf_integration = { category = "sample",
                    extensions = {"ksf"},
                    invoke = ksf_loadsample}  -- returns true

if renoise.tool():has_file_import_hook("sample", {"ksf"}) == false then
  renoise.tool():add_file_import_hook(ksf_integration)
end
