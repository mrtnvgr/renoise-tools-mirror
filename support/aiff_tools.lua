--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Aiff file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function generate_aiff(channels, samplerate, bit_depth, audiodata)
  -- writes a aiff file (to a Renoise temporary location) with the supplied data
  local aiff_file = os.tmpname("aiff")
  local frames = audiodata:len() / (channels * (bit_depth / 8))
  local length = audiodata:len() + 27
  
  dprint("generate_aiff: aiff_file=", aiff_file)
  
  local f = io.open(aiff_file, "wb")
  
  -- Did we open the file successfully
  if f == nil then
    return false
  end

  -- main header
  f:write("FORM")
  f:write(hex_pack(string.format("%08X", length))) -- chunk size = file length - 8 
  f:write("AIFF")
  
  -- common chunk
  f:write("COMM") -- (4 bytes)
  f:write(hex_pack("00000012")) -- chunk size = 18 bytes
  f:write(string.char(00, channels))   -- channel count
  f:write(hex_pack(string.format("%08X", frames))) -- sample frames
  f:write(hex_pack(string.format("%04X", bit_depth))) -- bit depth)
  f:write(hex_pack("400E" .. string.format("%04X", samplerate) .. "000000000000"))  -- sample rate as 10 bit float hack

  -- sound data chunk
  f:write("SSND") -- (4 bytes)
  f:write(hex_pack(string.format("%08X", audiodata:len() + 16))) -- chunk size
  f:write(hex_pack("00000000"))   -- offset
  f:write(hex_pack("00000000"))   -- blocksize
  if channels == 1 then
    f:write(audiodata)
  elseif channels == 2 then
    local right_offset = frames * (bit_depth/8)
    for i = 1, frames, (bit_depth / 8) do  -- interleaved audio
      f:write(audiodata:sub(i, i + (bit_depth/8)))                               --left
      f:write(audiodata:sub(right_offset + i, right_offset + i + (bit_depth/8))) --right
    end
  end 
  
  f:flush()
  f:close()
  
  return aiff_file 
end
