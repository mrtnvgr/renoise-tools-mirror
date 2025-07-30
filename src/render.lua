---@diagnostic disable: lowercase-global, undefined-global, deprecated
--[[-------------------------------------------------------------
MACIULXOCHITL                                                   -
render.lua                                                      -
Temporary ugly sample rendering :(                              -
]]---------------------------------------------------------------

-- Update sample buffer values / is observable better solution ? /

function write_info_to_sample(sample, instrument)
  if sample then
    sample.name = tmp.SAMPLE_NAME
    instrument.name = tmp.INSTRUMENT_NAME
    sample.beat_sync_enabled = tmp.SAMPLE_BEAT_SYNC_ENABLED
    sample.beat_sync_lines = tmp.SAMPLE_BEAT_SYNC_LINES
    sample.beat_sync_mode = tmp.SAMPLE_BEAT_SYNC_MODE
    sample.loop_mode = tmp.SAMPLE_LOOP_MODE
    sample.panning = tmp.SAMPLE_PANNING
    sample.volume = tmp.SAMPLE_VOLUME
    sample.transpose = tmp.SAMPLE_TRANSPOSE
    sample.fine_tune = tmp.SAMPLE_FINE_TUNE
    sample.interpolation_mode = tmp.SAMPLE_INTERPOLATION_MODE
    sample.oversample_enabled = tmp.SAMPLE_OVERSAMPLE_ENABLED
    sample.new_note_action = tmp.SAMPLE_NEW_NOTE_ACTION
    sample.oneshot = tmp.SAMPLE_ONESHOT
    sample.mute_group = tmp.SAMPLE_MUTE_GROUP
    sample.autoseek = tmp.SAMPLE_AUTOSEEK
    sample.autofade = tmp.SAMPLE_AUTOFADE
  end
end

-- Read sample buffer values for saving 

function read_info_from_sample(sample, instrument)
  if sample then
    tmp.SAMPLE_NAME = sample.name
    tmp.INSTRUMENT_NAME = instrument.name
    tmp.SAMPLE_BEAT_SYNC_ENABLED = sample.beat_sync_enabled
    tmp.SAMPLE_BEAT_SYNC_LINES = sample.beat_sync_lines
    tmp.SAMPLE_BEAT_SYNC_MODE = sample.beat_sync_mode
    tmp.SAMPLE_LOOP_MODE = sample.loop_mode
    tmp.SAMPLE_LOOP_RELEASE = sample.loop_release
    tmp.SAMPLE_LOOP_START = sample.loop_start
    tmp.SAMPLE_LOOP_END = sample.loop_end
    tmp.SAMPLE_PANNING = sample.panning
    tmp.SAMPLE_VOLUME = sample.volume
    tmp.SAMPLE_TRANSPOSE = sample.transpose
    tmp.SAMPLE_FINE_TUNE = sample.fine_tune
    tmp.SAMPLE_INTERPOLATION_MODE = sample.interpolation_mode
    tmp.SAMPLE_OVERSAMPLE_ENABLED = sample.oversample_enabled
    tmp.SAMPLE_NEW_NOTE_ACTION = sample.new_note_action
    tmp.SAMPLE_ONESHOT = sample.oneshot
    tmp.SAMPLE_MUTE_GROUP = sample.mute_group
    tmp.SAMPLE_AUTOSEEK = sample.autoseek
    tmp.SAMPLE_AUTOFADE = sample.autofade
  end
end

--[[-------------------------------------------------------------
Paint magic , for now one ugly loop                             -
]]---------------------------------------------------------------

function redraw_sample(info_for_render) 

  math.randomseed(os.time())

  local new_sample = nil
  local new_buffer = nil
  local instrument = renoise.song().selected_instrument
  local selected_sample = renoise.song().selected_sample_index
  local samples_nr = table.getn(instrument.samples)

  MAIN_INSTRUMENT = instrument

  -- this is hack for now, only one sample is permited
  -- at the moment

  if info_for_render == "new_patch" or info_for_render == "new_start" then

    -- if new patch is loaded delete all samples

    --while table.getn(instrument.samples) > 0 do
      --print("Sampl vymazán")
    --  instrument:delete_sample_at(1)
    --end

    if samples_nr == 0 then
      new_sample = instrument:insert_sample_at(1)
    else
      new_sample = renoise.song().selected_sample
    end
    write_info_to_sample(new_sample, instrument)
    info_for_render = false

  else
  
    if table.getn(instrument.samples) > 0 then
      new_sample = renoise.song().selected_sample --instrument:sample(1)
      read_info_from_sample(new_sample, instrument)
      write_info_to_sample(new_sample, instrument)
    else
      new_sample = instrument:insert_sample_at(1)
    end
  end
  MAIN_SAMPLE = new_sample

  -- načti informace ze sample bufferu
  local new_buffer = new_sample.sample_buffer

  -- jestliže má sample buffer stejné hodnoty jako ten předešlý
  -- čili nebyla změněna jeho délka, samplrejt, bitová hloubka nebo
  -- počet kanálů použij již vytvořený buffer

  if new_buffer.has_sample_data
    and new_buffer.number_of_frames == tmp.SAMPLE_FRAMES
    and new_buffer.sample_rate == def.SAMPLE_FREQUENCY
    and new_buffer.bit_depth == def.SAMPLE_BIT_DEPTH
    and new_buffer.number_of_channels == def.SAMPLE_CHANNELS
  
  then
  
    --print("Používám nezměněný sample buffer")
  
  else
  
    -- pokud neplatí podmínky uvedené výše tak vytvářím nový sample buffer
    -- dle podmínek v globálních proměnných

    if
    
      tmp.SAMPLE_FRAMES > 0 and not new_buffer:create_sample_data(def.SAMPLE_FREQUENCY,
                                                                  def.SAMPLE_BIT_DEPTH,
                                                                  def.SAMPLE_CHANNELS,
                                                                  tmp.SAMPLE_FRAMES)
    
    then
      renoise.app():show_error("Error during sample creation!")
      renoise.song():undo()
      return
    else
      write_info_to_sample(MAIN_SAMPLE, MAIN_INSTRUMENT)
    end
  
  end

  new_buffer:prepare_sample_data_changes()

  local math_buffer = {} -- MATH_BUFFER
  local frame = nil

  for frame=1, tmp.SAMPLE_FRAMES do
      
    local val_1, val_2, val_3 = 0, 0, 0
    local result = 0
    
    -- create and distort waves OSC1 is ON forever
 
    if tmp.SAMPLE_TYPE_1 == 1 then
      val_1 = OSC1:simple_saw(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 2 then
      val_1 = OSC1:simple_sine(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 3 then
      val_1 = OSC1:simple_square(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 4 then
      val_1 = OSC1:simple_triangle(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 5 then
      val_1 = OSC1:additive_saw(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 6 then
      val_1 = OSC1:additive_square(frame, tmp.SAMPLE_FRAMES)
    elseif tmp.SAMPLE_TYPE_1 == 7 then
      val_1 = OSC1:additive_tan(frame, tmp.SAMPLE_FRAMES)
    end

    result = val_1

    -- If operation is not none calculate second oscilator

    if tmp.OP1 > 1 or OSC2.modulate_amp or OSC2.modulate_freq or OSC2.modulate_phase then 

      if tmp.SAMPLE_TYPE_2 == 1 then
        val_2 = OSC2:simple_saw(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 2 then
        val_2 = OSC2:simple_sine(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 3 then
        val_2 = OSC2:simple_square(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 4 then
        val_2 = OSC2:simple_triangle(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 5 then
        val_2 = OSC2:additive_saw(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 6 then
        val_2 = OSC2:additive_square(frame, tmp.SAMPLE_FRAMES, val_1)
      elseif tmp.SAMPLE_TYPE_2 == 7 then
        val_2 = OSC2:additive_tan(frame, tmp.SAMPLE_FRAMES, val_1)
      end

      -- add some modulation between waves

      if tmp.OP1 == 2 then
        result = val_1 + val_2
      elseif tmp.OP1 == 3 then
        result = val_1 - val_2
      elseif tmp.OP1 == 4 then
        result = val_1 * val_2
      elseif tmp.OP1 == 5 then
        result = val_1 / val_2
      elseif tmp.OP1 == 6 then
          
        if val_1 < val_2 then 
          result=val_1
        else
          result=val_2
        end
      
      elseif tmp.OP1 == 7 then
          
        if val_1 > val_2 then 
          result=val_1
        else 
          result=val_2
        end
        
      elseif tmp.OP1 == 8 then
        result = val_1 % val_2
      
      else
        result = val_2
      end

    end
      
    -- if operation one and operation two is not none sum waves

    if tmp.OP1 > 1 and tmp.OP2 > 1 or OSC3.modulate_freq or OSC3.modulate_amp or OSC3.modulate_phase then

      if tmp.SAMPLE_TYPE_3 == 1 then
        val_3 = OSC3:simple_saw(frame, tmp.SAMPLE_FRAMES, result)
      
      elseif tmp.SAMPLE_TYPE_3 == 2 then
        val_3 = OSC3:simple_sine(frame, tmp.SAMPLE_FRAMES, result)
        
      elseif tmp.SAMPLE_TYPE_3 == 3 then
        val_3 = OSC3:simple_square(frame, tmp.SAMPLE_FRAMES, result)
        
      elseif tmp.SAMPLE_TYPE_3 == 4 then
        val_3 = OSC3:simple_triangle(frame, tmp.SAMPLE_FRAMES, result)
        
      elseif tmp.SAMPLE_TYPE_3 == 5 then
        val_3 = OSC3:additive_saw(frame, tmp.SAMPLE_FRAMES, result)
        
      elseif tmp.SAMPLE_TYPE_3 == 6 then
        val_3 = OSC3:additive_square(frame, tmp.SAMPLE_FRAMES, result)
        
      elseif tmp.SAMPLE_TYPE_3 == 7 then
        val_3 = OSC3:additive_tan(frame, tmp.SAMPLE_FRAMES, result)
        
      end


      if tmp.OP2 == 2 then
        result = result + val_3
        
      elseif tmp.OP2 == 3 and tmp.OP1 > 1 then
        result = result - val_3
        
      elseif tmp.OP2 == 4 and tmp.OP1 > 1 then
          result = result * val_3
        
      elseif tmp.OP2 == 5 and tmp.OP1 > 1 then
        result = result / val_3
        
      elseif tmp.OP2 == 6 then
          
        if result< val_3 then 
          result=result
          
        else 
          result=val_3
          
        end
        
      elseif tmp.OP2 == 7 then
          
        if result > val_3 then 
          result=result 
          
        else 
            result=val_3 
          
        end
        
      else
        result=val_3
        
      end

    end

    math_buffer[frame] = result

  end

  local function apply_noise(math_buffer)
    if tmp.SAMPLE_NOISE_BOOL then
      local i=nil
      for i=1, #math_buffer do
        math_buffer[i] = math_buffer[i] + Noise[i]
      end
    end
  end

  local function apply_gaussian(math_buffer)
    if tmp.GAUSSIAN_ON_OFF then
      local i=nil
      for i=1, #math_buffer do
        math_buffer[i] = math_buffer[i] * gaussian_mixture(6.283185307179586 * i / #math_buffer)
      end
    end
  end

  local function apply_waveshaper(math_buffer)
    if tmp.FINISHER_POPUP > 1 then
      local finisher = nil
      if tmp.FINISHER_POPUP == 2 then
        finisher = Waveshaper_S1
      elseif tmp.FINISHER_POPUP == 3 then
        finisher = Waveshaper_S2
      elseif tmp.FINISHER_POPUP == 4 then
        finisher = Waveshaper_S3
      elseif tmp.FINISHER_POPUP == 5 then
        finisher = Waveshaper_S4
      elseif tmp.FINISHER_POPUP == 6 then
        finisher = GloubiBoulga_waveshaper
      elseif tmp.FINISHER_POPUP == 7 then
        finisher = Foldback_Distortion
      end

      local i=nil
      for i=1, #math_buffer do
        math_buffer[i] = finisher(math_buffer[i], tmp.FINISHER_AMOUNT)
      end
    end
  end

  local function apply_filter(math_buffer)
    local buff = {}
    if tmp.SAMPLE_FILTER_TOGGLE then
      buff = Filters(math_buffer, tmp.SAMPLE_FILTER_TYPE)
      return buff
    else
      return math_buffer
    end
  end

  local function map_value(value, min1, max1, min2, max2)
    return (value - min1) / (max1 - min1) * (max2 - min2) + min2
  end

  if tmp.MODULATION_FLOW == 1 then
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==2 then
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==3 then
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==4 then
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==5 then
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==6 then
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==7 then
    apply_waveshaper(math_buffer)
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==8 then
    apply_waveshaper(math_buffer)
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==9 then
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==10 then
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
  elseif tmp.MODULATION_FLOW ==11 then
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==12 then
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
  elseif tmp.MODULATION_FLOW ==13 then
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==14 then
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==15 then
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer)
    apply_noise(math_buffer)
    apply_gaussian(math_buffer)
  elseif tmp.MODULATION_FLOW ==16 then
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer)
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
  elseif tmp.MODULATION_FLOW ==17 then
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==18 then
    math_buffer = apply_filter(math_buffer)
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
    apply_noise(math_buffer)
  elseif tmp.MODULATION_FLOW ==19 then
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==20 then
    apply_gaussian(math_buffer)
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==21 then
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
    apply_noise(math_buffer)
    math_buffer = apply_filter(math_buffer)
  elseif tmp.MODULATION_FLOW ==22 then
    apply_gaussian(math_buffer)
    apply_waveshaper(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
  elseif tmp.MODULATION_FLOW ==23 then
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_noise(math_buffer)
    apply_waveshaper(math_buffer)
  elseif tmp.MODULATION_FLOW ==24 then
    apply_gaussian(math_buffer)
    math_buffer = apply_filter(math_buffer)
    apply_waveshaper(math_buffer) 
    apply_noise(math_buffer)
  end
  
  -- find max signal value  
  local i=nil
  local min_val = 9999
  local max_val = -9999
  for i=1, #math_buffer do
    if math_buffer[i] < min_val then min_val = math_buffer[i] end
    if math_buffer[i] > max_val then max_val = math_buffer[i] end
  end

  local normalize = false
  local nval = nil
  if max_val > 1 or math.abs(min_val) > 1 then normalize = true end
  for i=1, #math_buffer do
    if normalize then
      nval = map_value(math_buffer[i], min_val, max_val, -1, 1)
    else
      nval = math_buffer[i]
    end
    new_buffer:set_sample_data(1, i, nval)
  end
  
  -- write to buffer
  new_buffer:finalize_sample_data_changes()
 
  MATH_BUFFER = math_buffer

end