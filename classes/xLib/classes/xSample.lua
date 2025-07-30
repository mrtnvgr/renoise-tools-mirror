--[[============================================================================
xSample
============================================================================]]--

--[[--

Static methods for working with renoise.Sample objects
.
#

Requires 
@{xReflection}
@{xSampleMapping}
@{xPhrase}

]]


class 'xSample'

xSample.SAMPLE_INFO = {
  EMPTY = 1,
  SILENT = 2,
  PAN_LEFT = 4,
  PAN_RIGHT = 8,
  DUPLICATE = 16,
  MONO = 32,
  STEREO = 64,
}

xSample.SAMPLE_CHANNELS = {
  LEFT = 1,
  RIGHT = 2,
  BOTH = 3,
}

--- SAMPLE_CONVERT: misc. channel operations
-- MONO_MIX: stereo -> mono mix (mix left and right)
-- MONO_LEFT: stereo -> mono (keep left)
-- MONO_RIGHT: stereo -> mono (keep right)
-- STEREO: mono -> stereo
-- SWAP: stereo (swap channels)
xSample.SAMPLE_CONVERT = {
  MONO_MIX = 1, -- TODO
  MONO_LEFT = 2,
  MONO_RIGHT = 3,
  STEREO = 4,
  SWAP = 5,
}

xSample.BIT_DEPTH = {0,8,16,24,32}



--------------------------------------------------------------------------------
-- credit goes to dblue
-- @param sample (renoise.Sample)
-- @return int (0 when no sample data)

function xSample.get_bit_depth(sample)
  --print("xSample.get_bit_depth(sample)",sample)

  local function reverse(t)
    local nt = {}
    local size = #t + 1
    for k,v in ipairs(t) do
      nt[size - k] = v
    end
    return nt
  end
  
  local function tobits(num)
    local t = {}
    while num > 0 do
      local rest = num % 2
      t[#t + 1] = rest
      num = (num - rest) / 2
    end
    t = reverse(t)
    return t
  end
  
  -- Vars and crap
  local bit_depth = 0
  local sample_max = math.pow(2, 32) / 2
  local buffer = sample.sample_buffer
  
  -- If we got some sample data to analyze
  if (buffer.has_sample_data) then
  
    local channels = buffer.number_of_channels
    local frames = buffer.number_of_frames
    
    for f = 1, frames do
      for c = 1, channels do
      
        -- Convert float to 32-bit unsigned int
        local s = (1 + buffer:sample_data(c, f)) * sample_max
        
        -- Measure bits used
        local bits = tobits(s)
        for b = 1, #bits do
          if bits[b] == 1 then
            if b > bit_depth then
              bit_depth = b
            end
          end
        end

      end
    end
  end
    
  return xSample.bits_to_xbits(bit_depth),bit_depth

end


--------------------------------------------------------------------------------
-- convert any bit-depth to a valid xSample representation
-- @param num_bits (int)
-- @return int (xSample.BIT_DEPTH)

function xSample.bits_to_xbits(num_bits)
  if (num_bits == 0) then
    return 0
  end
  for k,xbits in ipairs(xSample.BIT_DEPTH) do
    if (num_bits <= xbits) then
      return xbits
    end
  end
  error("Number is outside allowed range")

end


--------------------------------------------------------------------------------
-- check if sample has duplicate channel data, is hard-panned or silent
-- (several detection functions in one means less methods are needed...)
-- @param sample  (renoise.Sample)
-- @return enum (xSample.SAMPLE_[...])

function xSample.get_channel_info(sample)
  --print("xSample.get_channel_info(sample)",sample)

  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return xSample.SAMPLE_INFO.EMPTY
  end

  -- not much to do with a monophonic sound...
  if (buffer.number_of_channels == 1) then
    if xSample.sample_buffer_is_silent(buffer,xSample.SAMPLE_CHANNELS.LEFT) then
      return xSample.SAMPLE_INFO.SILENT
    else
      return xSample.SAMPLE_INFO.MONO
    end
  end

  local l_pan = true
  local r_pan = true
  local silent = true
  local duplicate = true

  local l = nil
  local r = nil
  local frames = buffer.number_of_frames
  for f = 1, frames do
    l = buffer:sample_data(1,f)
    r = buffer:sample_data(2,f)
    if (l ~= 0) then
      silent = false
      r_pan = false
    end
    if (r ~= 0) then
      silent = false
      l_pan = false
    end
    if (l ~= r) then
      duplicate = false
      if not silent and not r_pan and not l_pan then
        return xSample.SAMPLE_INFO.STEREO
      end
    end
  end

  if silent then
    return xSample.SAMPLE_INFO.SILENT
  elseif duplicate then
    return xSample.SAMPLE_INFO.DUPLICATE
  elseif r_pan then
    return xSample.SAMPLE_INFO.PAN_RIGHT
  elseif l_pan then
    return xSample.SAMPLE_INFO.PAN_LEFT
  end

  return xSample.SAMPLE_INFO.STEREO

end

--------------------------------------------------------------------------------
-- convert sample: change bit-depth, perform channel operations, crop etc.
-- (jumping through a few hoops to keep keyzone and phrases intact...)
-- @param instr (renoise.Instrument)
-- @param sample_idx (int)
-- @param bit_depth (xSample.BIT_DEPTH)
-- @param channel_action (xSample.SAMPLE_CONVERT)
-- @param range (table) source start/end frames
-- @return renoise.Sample or nil (when failed to convert)

function xSample.convert_sample(instr,sample_idx,bit_depth,channel_action,range)
  --print("xSample.convert_sample(instr,sample_idx,bit_depth,channel_action)",instr,sample_idx,bit_depth,channel_action)

  local sample = instr.samples[sample_idx]
  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return false
  end

  local num_channels = (channel_action == xSample.SAMPLE_CONVERT.STEREO) and 2 or 1
  local num_frames = (range) and (range.end_frame-range.start_frame+1) or buffer.number_of_frames
  --print("num_channels",num_channels)
  --print("num_frames",num_frames)

  local new_sample = instr:insert_sample_at(sample_idx+1)
  local new_buffer = new_sample.sample_buffer
  local success = new_buffer:create_sample_data(
    buffer.sample_rate, 
    bit_depth, 
    num_channels,
    num_frames)  

  if not success then
    error("Failed to create sample buffer")
  end

  -- detect if instrument is in drumkit mode
  -- (when basenote is shifted by one semitone)
  local drumkit_mode = not ((new_sample.sample_mapping.note_range[1] == 0) and 
    (new_sample.sample_mapping.note_range[2] == 119))

  -- initialize certain aspects of sample
  -- before copying over information...
  new_sample.loop_start = 1
  new_sample.loop_end = num_frames

  xReflection.copy_object_properties(sample,new_sample)

  -- only when copying single channel 
  local channel_idx = 1 
  if(channel_action == xSample.SAMPLE_CONVERT.MONO_RIGHT) then
    channel_idx = 2
  end
  
  -- change sample 
  local f = nil
  new_buffer:prepare_sample_data_changes()
  for f_idx = range.start_frame,num_frames do

    if(channel_action == xSample.SAMPLE_CONVERT.MONO_MIX) then
      -- mix stereo to mono signal
      -- TODO 
    else
      -- copy from one channel to target channel(s)
      f = buffer:sample_data(channel_idx,f_idx)
      new_buffer:set_sample_data(1,f_idx,f)
      if (num_channels == 2) then
        f = buffer:sample_data(channel_idx,f_idx)
        new_buffer:set_sample_data(2,f_idx,f)
      end
    end

  end
  new_buffer:finalize_sample_data_changes()
  -- /change sample 

  -- when in drumkit mode, shift back keyzone mappings
  if drumkit_mode then
    xSampleMapping.shift_keyzone_by_semitones(instr,sample_idx+2,-1)
  end

  -- rewrite phrases so we don't loose direct sample 
  -- references when deleting the original sample
  for k,v in ipairs(instr.phrases) do
    xPhrase.replace_sample_index(v,sample_idx,sample_idx+1)
  end

  instr:delete_sample_at(sample_idx)

  return new_sample

end

--------------------------------------------------------------------------------
-- check if the indicated sample buffer is silent
-- @param buffer (renoise.SampleBuffer)
-- @param channels (xSample.SAMPLE_CHANNELS)
-- @return bool (or nil if no data)

function xSample.sample_buffer_is_silent(buffer,channels)
  --print("xSample.sample_buffer_is_silent(buffer,channels)",buffer,channels)

  if not buffer.has_sample_data then
    return 
  end

  local frames = buffer.number_of_frames

  if (channels == xSample.SAMPLE_CHANNELS.BOTH) then
    for f = 1, frames do
      if (buffer:sample_data(1,f) ~= 0) or 
        (buffer:sample_data(2,f) ~= 0) 
      then
        return false
      end
    end
  elseif (channels == xSample.SAMPLE_CHANNELS.LEFT) then
    for f = 1, frames do
      if (buffer:sample_data(1,f) ~= 0) then
        return false
      end
    end
  elseif (channels == xSample.SAMPLE_CHANNELS.RIGHT) then
    for f = 1, frames do
      if (buffer:sample_data(2,f) ~= 0) then
        return false
      end
    end
  end

  return true

end

