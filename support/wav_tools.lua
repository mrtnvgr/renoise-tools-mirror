--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Wave file support tools (hacky workarounds)
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function wav_get_base_note_from_file(filename)
  -- given a filename to a valid wav file, return the base note from the smpl
  -- chunk in the file.  Returns nil on error.
  local d = ""
  local smpl_chunk_start = 0
  local f = io.open(filename, "rb")
  
  -- Did we open the file successfully
  if f == nil then
    return nil
  end

  -- Create a memory copy
  f:seek("set", 0)
  d = f:read("*a")
  f:close()
  
  -- Did we read any data
  if d == "" then
    return nil
  elseif d == nil then
    return nil
  end
  
  -- Get the offset
  smpl_chunk_start = d:find("smpl", 1)
  
  if smpl_chunk_start == nil then
    return nil
  end
  
  -- Return the result
  return string.byte(d:sub(smpl_chunk_start + 20, smpl_chunk_start + 20)) - 12
end


function generate_wav(channels, samplerate, bit_depth, audiodata)
  -- writes a wav file (to a Renoise temporary location) with the supplied data
  local wav_file = os.tmpname("wav")
  local byte_rate = samplerate * channels * (bit_depth/8)
  local block_align = channels * (bit_depth/8)
  
  dprint("generate_wav: wav_file=", wav_file)
  
  local f = io.open(wav_file, "wb")
  
  -- Did we open the file successfully
  if f == nil then
    return false
  end

  -- main header
  f:write("RIFF")
  f:write(hex_pack_reversed(string.format("%08X", audiodata:len() + 32)))
  f:write("WAVE")
  
  
  -- fmt chunk
  f:write("fmt ")
  f:write(hex_pack_reversed("00000010")) -- chunk size = 16 bytes
  f:write(string.char(01, 00))  -- PCM format (no compression)
  f:write(string.char(channels, 00))   -- channel count
  f:write(hex_pack_reversed(string.format("%08X", samplerate))) -- sample rate
  f:write(hex_pack_reversed(string.format("%08X", byte_rate)))  -- byte rate
  f:write(hex_pack_reversed(string.format("%04X", block_align)))-- block alignment
  f:write(hex_pack_reversed(string.format("%04X", bit_depth)))  -- bit depth


  -- sound data chunk
  f:write("data")
  f:write(hex_pack_reversed(string.format("%08X", audiodata:len()))) -- chunk size
  f:write(hex_pack_reversed("00000000"))   -- offset (4 bytes)
  f:write(hex_pack_reversed("00000000"))   -- blocksize  (4 bytes)
  f:write(audiodata) -- dump audio data (right first, then left channel)
  
  f:flush()
  f:close()
  
  return wav_file 
end
