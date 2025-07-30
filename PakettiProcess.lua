-- Global constants for processing
--CHUNK_SIZE = 16777216
CHUNK_SIZE = 4194304
PROCESS_YIELD_INTERVAL = 4.53

-- Localize math library functions for efficiency
local math_log10 = math.log10
local log10 = math.log10
local math_abs   = math.abs

function NormalizeSelectedSliceInSample()
  local noprocess = false
  local song=renoise.song()
  local instrument = song.selected_instrument
  local current_slice = song.selected_sample_index
  local first_sample = instrument.samples[1]
  local current_sample = song.selected_sample
  local start_time = os.clock()

  if not current_sample or not current_sample.sample_buffer.has_sample_data then
    renoise.app():show_status("No sample available")
    return
  end

  print(string.format("\nSample Selected is Sample Slot %d", song.selected_sample_index))
  print(string.format("Sample Frames Length is 1-%d", current_sample.sample_buffer.number_of_frames))

  -----------------------------
  -- CASE 1: No slice markers – process entire sample.
  if #first_sample.slice_markers == 0 then
    local slicer, dialog, vb  -- declare upvalues so process_func can refer to them
    local function process_func()
      local buffer = current_sample.sample_buffer
      local sel_range = buffer.selection_range
      local slice_start, slice_end

      if sel_range[1] and sel_range[2] then
        slice_start = sel_range[1]
        slice_end   = sel_range[2]
        print(string.format("Selection in Sample: %d-%d", slice_start, slice_end))
        print("Normalizing: selection in sample")
      else
        slice_start = 1
        slice_end   = buffer.number_of_frames
        print("Normalizing: entire sample")
      end

      -- Localize properties for efficiency.
      local num_channels = buffer.number_of_channels
      local sample_rate  = buffer.sample_rate
      local bit_depth    = buffer.bit_depth
      local total_frames = slice_end - slice_start + 1
      local get_sample   = buffer.sample_data
      local set_sample   = buffer.set_sample_data

      -- Preallocate flat cache table and per‑channel peak table.
      local channel_peaks = {}
      local sample_cache  = {}
      for ch = 1, num_channels do
        channel_peaks[ch] = 0
        sample_cache[ch]  = {}  -- sample index = absolute frame - slice_start + 1
      end

      buffer:prepare_sample_data_changes()

      local next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL
      local function yield_if_needed()
        if os.clock() >= next_yield_time then
          coroutine.yield()
          next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL
        end
      end

      local processed_frames = 0
      local time_reading = 0

      print(string.format("\nNormalizing %d frames (%.1f sec at %dHz, %d‑bit)", 
            total_frames, total_frames/sample_rate, sample_rate, bit_depth))

      -- First Pass: Cache sample data and compute peak.
      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        local t_block = os.clock()
        for ch = 1, num_channels do
          for i = 0, block_size - 1 do
            local f = frame + i
            local idx = f - slice_start + 1
            local value = get_sample(buffer, ch, f)
            sample_cache[ch][idx] = value
            local abs_val = value < 0 and -value or value
            if abs_val > channel_peaks[ch] then
              channel_peaks[ch] = abs_val
              if channel_peaks[ch] >= 0.999969 then
                print("Found peak of 0.999969 or higher - no normalization needed")

                buffer:finalize_sample_data_changes()
                if dialog and dialog.visible then
                  dialog:close()
                end
                renoise.app():show_status("Found Peak value of 0.999969 or higher, doing nothing.")
                noprocess = true
                return
              end
            end
          end
        end
        time_reading = time_reading + (os.clock() - t_block)
        processed_frames = processed_frames + block_size
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Finding peak... %.1f%%", (processed_frames/total_frames)*100)
        end
        if slicer and slicer:was_cancelled() then
          buffer:finalize_sample_data_changes()
          return
        end
        yield_if_needed()
      end

      -- Find overall peak.
      local peak = 0
      for _, p in ipairs(channel_peaks) do
        if p > peak then peak = p end
      end
      if peak == 0 then
        print("Sample is silent, no normalization needed")
        buffer:finalize_sample_data_changes()
        if dialog and dialog.visible then
          dialog:close()
        end
        return
      end

      local scale = 1.0 / peak
      local db_increase = 20 * math_log10(scale)
      print(string.format("\nPeak amplitude: %.6f (%.1f dB below full scale)", peak, -db_increase))
      print(string.format("Will increase volume by %.1f dB", db_increase))

      -- Second Pass: Apply normalization.
      processed_frames = 0
      local time_processing = 0
      next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL  -- reset yield timer

      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        local t_block = os.clock()
        for ch = 1, num_channels do
          for i = 0, block_size - 1 do
            local f = frame + i
            local idx = f - slice_start + 1
            local cached_value = sample_cache[ch][idx]
            set_sample(buffer, ch, f, cached_value * scale)
          end
        end
        time_processing = time_processing + (os.clock() - t_block)
        processed_frames = processed_frames + block_size
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Normalizing... %.1f%%", (processed_frames/total_frames)*100)
        end
        if slicer and slicer:was_cancelled() then
          buffer:finalize_sample_data_changes()
          return
        end
        yield_if_needed()
      end

      sample_cache = nil
      buffer:finalize_sample_data_changes()

      local total_time = os.clock() - start_time
      local frames_per_sec = total_frames / total_time
      print(string.format("\nNormalization complete:"))
      print(string.format("Total time: %.2f seconds (%.5fM frames/sec)", total_time, frames_per_sec/1000000))
      print(string.format("Reading: %.3f%%, Processing: %.3f%%", 
             (time_reading/total_time)*100, ((total_time-time_reading)/total_time)*100))
      
      if dialog and dialog.visible then
        dialog:close()
      end

      if sel_range[1] and sel_range[2] then
        if noprocess == true then
          renoise.app():show_status("Found Peak value of 0.999969 or higher, doing nothing.")
        return end
        renoise.app():show_status("Normalized selection in " .. current_sample.name)
      else
        renoise.app():show_status("Normalized " .. current_sample.name)
      end
    end

    slicer = ProcessSlicer(process_func)
    dialog, vb = slicer:create_dialog("Normalizing Sample")
    slicer:start()
    return
  end

  -----------------------------
  -- CASE 2: Slice markers exist – process based on current slice.
  do
    local slicer, dialog, vb  -- declare upvalues
    local function process_func()
      local buffer = first_sample.sample_buffer
      local slice_markers = first_sample.slice_markers
      local slice_start, slice_end

      if current_slice == 1 then
        local sel = buffer.selection_range
        if sel[1] and sel[2] then
          slice_start = sel[1]
          slice_end   = sel[2]
          print(string.format("Selection in First Sample: %d-%d", slice_start, slice_end))
          print("Normalizing: selection in first sample")
        else
          slice_start = 1
          slice_end   = buffer.number_of_frames
          print("Normalizing: entire first sample")
        end
      else
        slice_start = current_slice > 1 and slice_markers[current_slice - 1] or 1
        local slice_end_marker = slice_markers[current_slice] or buffer.number_of_frames
        print(string.format("Selection is within Slice %d", current_slice))
        print(string.format("Slice %d bounds: %d-%d", current_slice, slice_start, slice_end_marker))
        local current_buffer = current_sample.sample_buffer
        print(string.format("Current sample selection range: start=%s, end=%s", 
              tostring(current_buffer.selection_range[1]), tostring(current_buffer.selection_range[2])))
        if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
          local rel_sel_start = current_buffer.selection_range[1]
          local rel_sel_end   = current_buffer.selection_range[2]
          local abs_sel_start = slice_start + rel_sel_start - 1
          local abs_sel_end   = slice_start + rel_sel_end - 1
          print(string.format("Selection %d-%d in slice view converts to %d-%d in sample", 
                rel_sel_start, rel_sel_end, abs_sel_start, abs_sel_end))
          slice_start = abs_sel_start
          slice_end   = abs_sel_end
          print("Normalizing: selection in slice")
        else
          slice_end = slice_end_marker
          print("Normalizing: entire slice (no selection in slice view)")
        end
      end

      slice_start = math.max(1, math.min(slice_start, buffer.number_of_frames))
      slice_end   = math.max(slice_start, math.min(slice_end, buffer.number_of_frames))
      print(string.format("Final normalize range: %d-%d", slice_start, slice_end))

      local num_channels = buffer.number_of_channels
      local sample_rate  = buffer.sample_rate
      local total_frames = slice_end - slice_start + 1
      local get_sample   = buffer.sample_data
      local set_sample   = buffer.set_sample_data

      local channel_peaks = {}
      local sample_cache  = {}
      for ch = 1, num_channels do
        channel_peaks[ch] = 0
        sample_cache[ch]  = {}
      end

      buffer:prepare_sample_data_changes()

      local next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL
      local function yield_if_needed()
        if os.clock() >= next_yield_time then
          coroutine.yield()
          next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL
        end
      end

      local processed_frames = 0
      local time_reading = 0

      print(string.format("\nNormalizing %d frames (%.1f sec at %dHz)", total_frames, total_frames/sample_rate, sample_rate))

      -- First Pass: cache and find the peak.
      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        local t_block = os.clock()
        for ch = 1, num_channels do
          for i = 0, block_size - 1 do
            local f = frame + i
            local idx = f - slice_start + 1
            local value = get_sample(buffer, ch, f)
            sample_cache[ch][idx] = value
            local abs_val = value < 0 and -value or value
            if abs_val > channel_peaks[ch] then
              channel_peaks[ch] = abs_val
              if channel_peaks[ch] >= 0.999969 then
                print("Found peak of 0.999969 or higher - no normalization needed")
                buffer:finalize_sample_data_changes()
                if dialog and dialog.visible then
                  dialog:close()
                  noprocess = true
                end
                renoise.app():show_status("Found Peak value of 0.999969 or higher, doing nothing.")
                return
              end
            end
          end
        end
        time_reading = time_reading + (os.clock() - t_block)
        processed_frames = processed_frames + block_size
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Finding peak... %.1f%%", (processed_frames/total_frames)*100)
        end
        if slicer and slicer:was_cancelled() then
          buffer:finalize_sample_data_changes()
          noprocess = true
          return
        end
        yield_if_needed()
      end

      local peak = 0
      for _, channel_peak in ipairs(channel_peaks) do
        if channel_peak > peak then
          peak = channel_peak
        end
      end

      if peak == 0 then
        print("Sample is silent, no normalization needed")
        buffer:finalize_sample_data_changes()
        if dialog and dialog.visible then
          dialog:close()
        end
        return
      end

      local scale = 1.0 / peak
      local db_increase = 20 * math_log10(scale)
      print(string.format("\nPeak amplitude: %.6f (%.1f dB below full scale)", peak, -db_increase))
      print(string.format("Will increase volume by %.1f dB", db_increase))

      processed_frames = 0
      local time_processing = 0
      next_yield_time = os.clock() + PROCESS_YIELD_INTERVAL

      -- Second Pass: normalization.
      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        local t_block = os.clock()
        for ch = 1, num_channels do
          for i = 0, block_size - 1 do
            local f = frame + i
            local idx = f - slice_start + 1
            local value = sample_cache[ch][idx]
            set_sample(buffer, ch, f, value * scale)
          end
        end
        time_processing = time_processing + (os.clock() - t_block)
        processed_frames = processed_frames + block_size
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Normalizing... %.1f%%", (processed_frames/total_frames)*100)
        end
        if slicer and slicer:was_cancelled() then
          buffer:finalize_sample_data_changes()
          noprocess = true
          return
        end
        yield_if_needed()
      end

      sample_cache = nil
      buffer:finalize_sample_data_changes()

      local total_time = os.clock() - start_time
      local frames_per_sec = total_frames / total_time
      print(string.format("\nNormalization complete:"))
      print(string.format("Total time: %.2f seconds (%.1fM frames/sec)", total_time, frames_per_sec/1000000))
      print(string.format("Reading: %.1f%%, Processing: %.1f%%", 
            (time_reading/total_time)*100, ((total_time-time_reading)/total_time)*100))
      
      if dialog and dialog.visible then
        dialog:close()
      end

      if current_slice == 1 then
        local sel = buffer.selection_range
        if sel[1] and sel[2] then
          if noprocess == true then
            renoise.app():show_status("Found Peak value of 0.999969 or higher, doing nothing.")
          return end
          renoise.app():show_status("Normalized selection in " .. current_sample.name)
        else
          renoise.app():show_status("Normalized entire sample")
        end
      else
        local sel = buffer.selection_range
        if sel[1] and sel[2] then
          if noprocess == true then
            renoise.app():show_status("Found Peak value of 0.999969 or higher, doing nothing.")
          return end
          renoise.app():show_status(string.format("Normalized selection in slice %d", current_slice))
        else
          renoise.app():show_status(string.format("Normalized slice %d", current_slice))
        end
        song.selected_sample_index = song.selected_sample_index - 1 
        song.selected_sample_index = song.selected_sample_index + 1
      end
    end

    slicer = ProcessSlicer(process_func)
    dialog, vb = slicer:create_dialog("Normalizing Sample")
    slicer:start()
  end
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Normalize Selected Sample or Slice",invoke=NormalizeSelectedSliceInSample}
renoise.tool():add_keybinding{name="Global:Paketti:Normalize Selected Sample or Slice",invoke=NormalizeSelectedSliceInSample}
renoise.tool():add_midi_mapping{name="Paketti:Normalize Selected Sample or Slice",invoke=function(message) if message:is_trigger() then NormalizeSelectedSliceInSample() end end}
--------

function normalize_all_samples_in_instrument()
  local instrument = renoise.song().selected_instrument
  if not instrument then
    renoise.app():show_warning("No instrument selected")
    return
  end

  local total_samples = #instrument.samples
  if total_samples == 0 then
    renoise.app():show_warning("No samples in selected instrument")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    local processed_samples = 0
    local skipped_samples = 0

    for sample_idx = 1, total_samples do
      local sample = instrument.samples[sample_idx]
      
      -- Update progress dialog
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Processing sample %d of %d", sample_idx, total_samples)
      end
      
      -- Skip invalid samples
      if not sample or not sample.sample_buffer.has_sample_data then
        skipped_samples = skipped_samples + 1
      else
        local buffer = sample.sample_buffer
        local num_channels = buffer.number_of_channels
        local num_frames = buffer.number_of_frames

        buffer:prepare_sample_data_changes()
        
        -- Set the selected sample index so user can see which sample is being processed
        renoise.song().selected_sample_index = sample_idx

        -- Find peak value across all channels
        local max_peak = 0
        for frame = 1, num_frames, CHUNK_SIZE do
          local chunk_end = math.min(frame + CHUNK_SIZE - 1, num_frames)
          for channel = 1, num_channels do
            for f = frame, chunk_end do
              local sample_value = buffer:sample_data(channel, f)
              max_peak = math.max(max_peak, math.abs(sample_value))
            end
          end
          
          if slicer:was_cancelled() then
            buffer:finalize_sample_data_changes()
            return
          end
          
          coroutine.yield()
        end

        -- Skip if already normalized
        if math.abs(max_peak - 1.0) < 0.0001 then
          buffer:finalize_sample_data_changes()
          skipped_samples = skipped_samples + 1
        else
          -- Apply normalization
          local scale = 1.0 / max_peak
          for frame = 1, num_frames, CHUNK_SIZE do
            local chunk_end = math.min(frame + CHUNK_SIZE - 1, num_frames)
            for channel = 1, num_channels do
              for f = frame, chunk_end do
                local sample_value = buffer:sample_data(channel, f)
                buffer:set_sample_data(channel, f, sample_value * scale)
              end
            end
            
            if slicer:was_cancelled() then
              buffer:finalize_sample_data_changes()
              return
            end
            
            coroutine.yield()
          end

          buffer:finalize_sample_data_changes()
          processed_samples = processed_samples + 1
        end
      end
    end

    if dialog and dialog.visible then
      dialog:close()
    end
    
    local msg = string.format("Normalized %d samples. Skipped %d samples.", 
      processed_samples, skipped_samples)
    renoise.app():show_status(msg)
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Normalizing All Samples")
  slicer:start()
end

renoise.tool():add_keybinding{name="Global:Paketti:Normalize Sample",invoke=function() normalize_selected_sample() end}
renoise.tool():add_keybinding{name="Global:Paketti:Normalize All Samples in Instrument",invoke=function() normalize_all_samples_in_instrument() end}

------
function normalize_and_reduce(scope, db_reduction)
  local function process_sample(sample, reduction_factor)
    if not sample then return false, "No sample provided!" end
    local buffer = sample.sample_buffer
    if not buffer or not buffer.has_sample_data then return false, "Sample has no data!" end

    buffer:prepare_sample_data_changes()

    local max_amplitude = 0
    for channel = 1, buffer.number_of_channels do
      for frame = 1, buffer.number_of_frames do
        local sample_value = math.abs(buffer:sample_data(channel, frame))
        if sample_value > max_amplitude then max_amplitude = sample_value end
      end
    end

    if max_amplitude > 0 then
      local normalization_factor = 1 / max_amplitude
      for channel = 1, buffer.number_of_channels do
        for frame = 1, buffer.number_of_frames do
          local sample_value = buffer:sample_data(channel, frame)
          buffer:set_sample_data(channel, frame, sample_value * normalization_factor * reduction_factor)
        end
      end
    end

    buffer:finalize_sample_data_changes()
    return true, "Sample processed successfully!"
  end

  local reduction_factor = 10 ^ (db_reduction / 20)

  if scope == "current_sample" then
    local sample = renoise.song().selected_sample
    if not sample then renoise.app():show_error("No sample selected!") return end
    local success, message = process_sample(sample, reduction_factor)
    renoise.app():show_status(message)
  elseif scope == "all_samples" then
    local instrument = renoise.song().selected_instrument
    if not instrument or #instrument.samples == 0 then renoise.app():show_error("No samples in the selected instrument!") return end
    for _, sample in ipairs(instrument.samples) do
      local success, message = process_sample(sample, reduction_factor)
      if not success then renoise.app():show_status(message) end
    end
    renoise.app():show_status("All samples in the selected instrument processed.")
  elseif scope == "all_instruments" then
    for _, instrument in ipairs(renoise.song().instruments) do
      if #instrument.samples > 0 then
        for _, sample in ipairs(instrument.samples) do
          local success, message = process_sample(sample, reduction_factor)
          if not success then renoise.app():show_status("Instrument skipped: " .. message) end
        end
      end
    end
    renoise.app():show_status("All instruments processed.")
  else
    renoise.app():show_error("Invalid processing scope!")
  end
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Normalize Selected Sample to -12dB",invoke=function() normalize_and_reduce("current_sample", -12) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Normalize Selected Instrument to -12dB",invoke=function() normalize_and_reduce("all_samples", -12) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Normalize All Instruments to -12dB",invoke=function() normalize_and_reduce("all_instruments", -12) end}
renoise.tool():add_midi_mapping{name="Paketti:Normalize Selected Sample to -12dB",invoke=function(message) if message:is_trigger() then normalize_and_reduce("current_sample", -12) end end}
renoise.tool():add_midi_mapping{name="Paketti:Normalize Selected Instrument to -12dB",invoke=function(message) if message:is_trigger() then normalize_and_reduce("all_samples", -12) end end}
renoise.tool():add_midi_mapping{name="Paketti:Normalize All Instruments to -12dB",invoke=function(message) if message:is_trigger() then normalize_and_reduce("all_instruments", -12) end end}

-- Configuration for process yielding (in seconds)
local PROCESS_YIELD_INTERVAL = 1.5  -- Adjust this value to control how often the process yields

function normalize_selected_sample()
    -- Use pcall for all potentially dangerous operations
    local success, song = pcall(function() return renoise.song() end)
    if not success then
        print("Could not access song")
        return false
    end

    local success_instrument, instrument = pcall(function() return song.selected_instrument end)
    if not success_instrument or not instrument then
        print("Could not access selected instrument")
        return false
    end

    local success_slice, current_slice = pcall(function() return song.selected_sample_index end)
    if not success_slice or not current_slice or current_slice < 1 then
        print("Could not access sample index")
        return false
    end

    local success_first, first_sample = pcall(function() return instrument.samples[1] end)
    if not success_first or not first_sample then
        print("Could not access first sample")
        return false
    end

    local success_current, current_sample = pcall(function() return song.selected_sample end)
    if not success_current or not current_sample then
        print("Could not access selected sample")
        return false
    end

    local success_data, has_sample_data = pcall(function() 
        return current_sample.sample_buffer and current_sample.sample_buffer.has_sample_data 
    end)
    if not success_data or not has_sample_data then
        print("No sample data available")
        return false
    end

    local last_yield_time = os.clock()
    
    -- Function to check if we should yield
    local function should_yield()
        local current_time = os.clock()
        if current_time - last_yield_time >= PROCESS_YIELD_INTERVAL then
            last_yield_time = current_time
            return true
        end
        return false
    end
    
    -- Check if we have valid data
    if not current_sample or not current_sample.sample_buffer or not current_sample.sample_buffer.has_sample_data then
        print("No sample data available")
        return false
    end

    -- Create ProcessSlicer instance and dialog
    local slicer = nil
    local dialog = nil
    local vb = nil
    
    -- Define the process function that will be passed to ProcessSlicer
    local function process_func()
        -- Get the appropriate sample and buffer based on whether we're dealing with a slice
        local sample = current_sample
        local buffer = sample.sample_buffer
        local slice_start = 1
        local slice_end = buffer.number_of_frames
        
        -- If this is a slice, we need to work with the first sample's buffer
        if sample.is_slice_alias then
            buffer = first_sample.sample_buffer
            -- Find the slice boundaries
            if current_slice > 1 and #first_sample.slice_markers > 0 then
                slice_start = first_sample.slice_markers[current_slice - 1]
                slice_end = current_slice < #first_sample.slice_markers 
                    and first_sample.slice_markers[current_slice] - 1 
                    or buffer.number_of_frames
            end
        end
        
        local total_frames = slice_end - slice_start + 1
        
        -- Timing variables
        local time_start = os.clock()
        local time_reading = 0
        local time_processing = 0
        
        print(string.format("\nNormalizing %d frames (%.1f seconds at %dHz)", 
            total_frames, 
            total_frames / buffer.sample_rate,
            buffer.sample_rate))
        
        -- First pass: Find peak and cache data
        local peak = 0
        local processed_frames = 0
        
        -- Pre-allocate tables for better performance
        local channel_peaks = {}
        local sample_cache = {}
        for channel = 1, buffer.number_of_channels do
            channel_peaks[channel] = 0
            sample_cache[channel] = {}
        end
        
        buffer:prepare_sample_data_changes()
        
        -- Process in blocks
        for frame = slice_start, slice_end, CHUNK_SIZE do
            local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
            local block_size = block_end - frame + 1
            
            -- Read and process each channel
            for channel = 1, buffer.number_of_channels do
                local read_start = os.clock()
                local channel_peak = 0
                
                -- Cache the data while finding peak
                sample_cache[channel][frame] = {}
                for i = 0, block_size - 1 do
                    local sample_value = buffer:sample_data(channel, frame + i)
                    sample_cache[channel][frame][i] = sample_value
                    local abs_value = math.abs(sample_value)
                    if abs_value > channel_peak then
                        channel_peak = abs_value
                    end
                end
                
                time_reading = time_reading + (os.clock() - read_start)
                if channel_peak > channel_peaks[channel] then
                    channel_peaks[channel] = channel_peak
                end
            end
            
            -- Update progress and check if we should yield
            processed_frames = processed_frames + block_size
            local progress = processed_frames / total_frames
            if dialog and dialog.visible then
                vb.views.progress_text.text = string.format("Finding peak... %.1f%%", progress * 100)
            end
            
            if slicer:was_cancelled() then
                buffer:finalize_sample_data_changes()
                return
            end
            
            if should_yield() then
              coroutine.yield()
            end
        end
        
        -- Find overall peak
        for _, channel_peak in ipairs(channel_peaks) do
            if channel_peak > peak then
                peak = channel_peak
            end
        end
        
        -- Check if sample is silent
        if peak == 0 then
            print("Sample is silent, no normalization needed")
            buffer:finalize_sample_data_changes()
            if dialog and dialog.visible then
                dialog:close()
            end
            return
        end
        
        -- Calculate and display normalization info
        local scale = 1.0 / peak
        local db_increase = 20 * log10(scale)
        print(string.format("\nPeak amplitude: %.6f (%.1f dB below full scale)", peak, -db_increase))
        print(string.format("Will increase volume by %.1f dB", db_increase))
        
        -- Reset progress for second pass
        processed_frames = 0
        last_yield_time = os.clock()  -- Reset yield timer for second pass
        
        -- Second pass: Apply normalization using cached data
        for frame = slice_start, slice_end, CHUNK_SIZE do
            local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
            local block_size = block_end - frame + 1
            
            -- Process each channel
            for channel = 1, buffer.number_of_channels do
                local process_start = os.clock()
                
                for i = 0, block_size - 1 do
                    local current_frame = frame + i
                    -- Use cached data instead of reading from buffer again
                    local sample_value = sample_cache[channel][frame][i]
                    buffer:set_sample_data(channel, current_frame, sample_value * scale)
                end
                
                time_processing = time_processing + (os.clock() - process_start)
            end
            
            -- Clear cache for this chunk to free memory
            for channel = 1, buffer.number_of_channels do
                sample_cache[channel][frame] = nil
            end
            
            -- Update progress and check if we should yield
            processed_frames = processed_frames + block_size
            local progress = processed_frames / total_frames
            if dialog and dialog.visible then
                vb.views.progress_text.text = string.format("Normalizing... %.1f%%", progress * 100)
            end
            
            if slicer:was_cancelled() then
                buffer:finalize_sample_data_changes()
                return
            end
            
            if should_yield() then
              coroutine.yield()
            end
        end
        
        -- Clear the entire cache
        sample_cache = nil
        
        -- Finalize changes
        buffer:finalize_sample_data_changes()
        
        -- Calculate and display performance stats
        local total_time = os.clock() - time_start
        local frames_per_second = total_frames / total_time
        print(string.format("\nNormalization complete:"))
        print(string.format("Total time: %.2f seconds (%.1fM frames/sec)", 
            total_time, frames_per_second / 1000000))
        print(string.format("Reading: %.1f%%, Processing: %.1f%%", 
            (time_reading/total_time) * 100,
            ((total_time - time_reading)/total_time) * 100))
        
        -- Close dialog when done
        if dialog and dialog.visible then
            dialog:close()
        end
        
        -- Show appropriate status message
        if sample.is_slice_alias then
            renoise.app():show_status(string.format("Normalized slice %d", current_slice))
        else
            renoise.app():show_status("Sample normalized successfully")
        end
    end
    
    -- Create and start the ProcessSlicer
    slicer = ProcessSlicer(process_func)
    dialog, vb = slicer:create_dialog("Normalizing Sample")
    slicer:start()
end


function ReverseSelectedSliceInSample()
  local song=renoise.song()
  local instrument = song.selected_instrument
  local current_slice = song.selected_sample_index
  local first_sample = instrument.samples[1]
  local current_sample = song.selected_sample
  local current_buffer = current_sample.sample_buffer
  local last_yield_time = os.clock()
  
  -- Function to check if we should yield
  local function should_yield()
    local current_time = os.clock()
    if current_time - last_yield_time >= PROCESS_YIELD_INTERVAL then
      last_yield_time = current_time
      return true
    end
    return false
  end
  
  -- Check if we have valid data
  if not current_sample or not current_buffer.has_sample_data then
    renoise.app():show_status("No sample available")
    return
  end

  print(string.format("\nSample Selected is Sample Slot %d", song.selected_sample_index))
  print(string.format("Sample Frames Length is 1-%d", current_buffer.number_of_frames))

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    -- Case 1: No slice markers - work on current sample
    if #first_sample.slice_markers == 0 then
      local slice_start, slice_end
      
      -- Check for selection in current sample
      if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
        slice_start = current_buffer.selection_range[1]
        slice_end = current_buffer.selection_range[2]
        print(string.format("Selection in Sample: %d-%d", slice_start, slice_end))
        print("Reversing: selection in sample")
      else
        slice_start = 1
        slice_end = current_buffer.number_of_frames
        print("Reversing: entire sample")
      end
      
      -- Reverse the range
      current_buffer:prepare_sample_data_changes()
      
      local num_channels = current_buffer.number_of_channels
      local frames_to_process = slice_end - slice_start + 1
      local half_frames = math.floor(frames_to_process / 2)
      local processed_frames = 0

      for offset = 0, half_frames - 1 do
        local frame_a = slice_start + offset
        local frame_b = slice_end - offset
        for channel = 1, num_channels do
          local temp = current_buffer:sample_data(channel, frame_a)
          current_buffer:set_sample_data(channel, frame_a, current_buffer:sample_data(channel, frame_b))
          current_buffer:set_sample_data(channel, frame_b, temp)
        end

        processed_frames = processed_frames + 2
        local progress = (processed_frames / frames_to_process) * 100

        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Reversing... %.1f%%", progress)
        end

        if slicer:was_cancelled() then
          current_buffer:finalize_sample_data_changes()
          return
        end

        if should_yield() then
          coroutine.yield()
        end
      end

      current_buffer:finalize_sample_data_changes()
      
      if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
        renoise.app():show_status("Reversed selection in " .. current_sample.name)
      else
        renoise.app():show_status("Reversed " .. current_sample.name)
      end

      if dialog and dialog.visible then
        dialog:close()
      end
      return
    end

    -- Case 2: Has slice markers
    local buffer = first_sample.sample_buffer
    local slice_start, slice_end
    local slice_markers = first_sample.slice_markers

    -- If we're on the first sample
    if current_slice == 1 then
      -- Check for selection in first sample
      if buffer.selection_range[1] and buffer.selection_range[2] then
        slice_start = buffer.selection_range[1]
        slice_end = buffer.selection_range[2]
        print(string.format("Selection in First Sample: %d-%d", slice_start, slice_end))
        print("Reversing: selection in first sample")
      else
        slice_start = 1
        slice_end = buffer.number_of_frames
        print("Reversing: entire first sample")
      end
    else
      -- Get slice boundaries
      slice_start = current_slice > 1 and slice_markers[current_slice - 1] or 1
      local slice_end_marker = slice_markers[current_slice] or buffer.number_of_frames
      local slice_length = slice_end_marker - slice_start + 1

      print(string.format("Selection is within Slice %d", current_slice))
      print(string.format("Slice %d length is %d-%d (length: %d), within 1-%d of sample frames length", 
        current_slice, slice_start, slice_end_marker, slice_length, buffer.number_of_frames))

      -- Debug selection values
      print(string.format("Current sample selection range: start=%s, end=%s", 
        tostring(current_buffer.selection_range[1]), tostring(current_buffer.selection_range[2])))
      
      -- Check if there's a selection in the current slice view
      if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
        local rel_sel_start = current_buffer.selection_range[1]
        local rel_sel_end = current_buffer.selection_range[2]
        
        -- Convert slice-relative selection to absolute position in sample
        local abs_sel_start = slice_start + rel_sel_start - 1
        local abs_sel_end = slice_start + rel_sel_end - 1
        
        print(string.format("Selection %d-%d in slice view converts to %d-%d in sample", 
          rel_sel_start, rel_sel_end, abs_sel_start, abs_sel_end))
            
        -- Use the converted absolute positions
        slice_start = abs_sel_start
        slice_end = abs_sel_end
        print("Reversing: selection in slice")
      else
        -- No selection in slice view - reverse whole slice
        slice_end = slice_end_marker
        print("Reversing: entire slice (no selection in slice view)")
      end
    end

    -- Reverse the range
    buffer:prepare_sample_data_changes()
    
    local num_channels = buffer.number_of_channels
    local frames_to_process = slice_end - slice_start + 1
    local half_frames = math.floor(frames_to_process / 2)
    local processed_frames = 0

    for offset = 0, half_frames - 1 do
      local frame_a = slice_start + offset
      local frame_b = slice_end - offset
      for channel = 1, num_channels do
        local temp = buffer:sample_data(channel, frame_a)
        buffer:set_sample_data(channel, frame_a, buffer:sample_data(channel, frame_b))
        buffer:set_sample_data(channel, frame_b, temp)
      end

      processed_frames = processed_frames + 2
      local progress = (processed_frames / frames_to_process) * 100

      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Reversing... %.1f%%", progress)
      end

      if slicer:was_cancelled() then
        buffer:finalize_sample_data_changes()
        return
      end

      if should_yield() then
        coroutine.yield()
      end
    end

    buffer:finalize_sample_data_changes()

    if current_slice == 1 then
      if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
        renoise.app():show_status("Reversed selection in " .. current_sample.name)
      else
        renoise.app():show_status("Reversed entire sample")
      end
    else
      if current_buffer.selection_range[1] and current_buffer.selection_range[2] then
        renoise.app():show_status(string.format("Reversed selection in slice %d", current_slice))
      else
        renoise.app():show_status(string.format("Reversed slice %d", current_slice))
      end
      -- Refresh view for slices
      song.selected_sample_index = song.selected_sample_index - 1 
      song.selected_sample_index = song.selected_sample_index + 1
    end

    if dialog and dialog.visible then
      dialog:close()
    end
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Reversing Sample")
  slicer:start()
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Reverse Selected Sample or Slice",invoke=ReverseSelectedSliceInSample}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Reverse Selected Sample or Slice",invoke=ReverseSelectedSliceInSample}
renoise.tool():add_midi_mapping{name="Paketti:Reverse Selected Sample or Slice",invoke=function(message) if message:is_trigger() then ReverseSelectedSliceInSample() end end}
--------
-- Version with callback support for automated workflows
function normalize_selected_sample_by_slices_with_callback(completion_callback)
  local selected_sample = renoise.song().selected_sample
  local last_yield_time = os.clock()
  
  -- Function to check if we should yield
  local function should_yield()
    local current_time = os.clock()
    if current_time - last_yield_time >= PROCESS_YIELD_INTERVAL then
      last_yield_time = current_time
      return true
    end
    return false
  end
  
  if not selected_sample or not selected_sample.sample_buffer or not selected_sample.sample_buffer.has_sample_data then
    renoise.app():show_status("Normalization failed: No valid sample to normalize.")
    if completion_callback then completion_callback(false) end
    return
  end

  -- Check if sample has slice markers
  if #selected_sample.slice_markers == 0 then
    -- If no slice markers, fall back to regular normalize
    normalize_selected_sample()
    if completion_callback then completion_callback(true) end
    return
  end

  local sbuf = selected_sample.sample_buffer
  local slice_count = #selected_sample.slice_markers
  
  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil
  
  -- Define the process function
  local function process_func()
    local time_start = os.clock()
    local time_reading = 0
    local time_processing = 0
    local CHUNK_SIZE = 16777216  -- 16MB worth of frames
    local total_frames = sbuf.number_of_frames
    local total_slices = slice_count
    local slices_processed = 0
    
    print(string.format("\nProcessing %d frames across %d slices", total_frames, total_slices))
    
    -- Prepare buffer for changes
    sbuf:prepare_sample_data_changes()
    
    -- Process each slice independently
    for slice_idx = 1, slice_count do
      local slice_start = selected_sample.slice_markers[slice_idx]
      local slice_end = (slice_idx < slice_count) 
        and selected_sample.slice_markers[slice_idx + 1] - 1 
        or sbuf.number_of_frames
      
      local slice_frames = slice_end - slice_start + 1
      
      -- Pre-allocate tables for better performance
      local channel_peaks = {}
      local sample_cache = {}
      for channel = 1, sbuf.number_of_channels do
        channel_peaks[channel] = 0
        sample_cache[channel] = {}
      end
      
      -- First pass: Find peak and cache data
      local highest_detected = 0
      
      -- Process in chunks
      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        
        -- Read and process each channel
        for channel = 1, sbuf.number_of_channels do
          local read_start = os.clock()
          local channel_peak = 0
          
          -- Cache the data while finding peak
          sample_cache[channel][frame] = {}
          for i = 0, block_size - 1 do
            local current_frame = frame + i
            local sample_value = sbuf:sample_data(channel, current_frame)
            sample_cache[channel][frame][i] = sample_value
            local abs_value = math.abs(sample_value)
            if abs_value > channel_peak then
              channel_peak = abs_value
            end
          end
          
          time_reading = time_reading + (os.clock() - read_start)
          if channel_peak > channel_peaks[channel] then
            channel_peaks[channel] = channel_peak
          end
        end
        
        -- Calculate actual progress percentage
        local progress = (slice_idx - 1 + (frame - slice_start) / slice_frames) / total_slices * 100
        
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Processing %03d/%03d - %.1f%%", 
            slice_idx, total_slices, progress)
        end
        
        if slicer:was_cancelled() then
          sbuf:finalize_sample_data_changes()
          if completion_callback then completion_callback(false) end
          return
        end
        
        if should_yield() then
          coroutine.yield()
        end
      end
      
      -- Find overall peak for this slice
      for _, channel_peak in ipairs(channel_peaks) do
        if channel_peak > highest_detected then
          highest_detected = channel_peak
        end
      end
      
      -- Only normalize if the slice isn't silent
      if highest_detected > 0 then
        local scale = 1.0 / highest_detected
        
        -- Second pass: Apply normalization using cached data
        for frame = slice_start, slice_end, CHUNK_SIZE do
          local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
          local block_size = block_end - frame + 1
          
          -- Process each channel
          for channel = 1, sbuf.number_of_channels do
            local process_start = os.clock()
            
            for i = 0, block_size - 1 do
              local current_frame = frame + i
              -- Use cached data instead of reading from buffer again
              local sample_value = sample_cache[channel][frame][i]
              sbuf:set_sample_data(channel, current_frame, sample_value * scale)
            end
            
            time_processing = time_processing + (os.clock() - process_start)
          end
          
          -- Clear cache for this chunk to free memory
          for channel = 1, sbuf.number_of_channels do
            sample_cache[channel][frame] = nil
          end
          
          -- Calculate actual progress percentage (50-100% range for normalization phase)
          local progress = 50 + (slice_idx - 1 + (frame - slice_start) / slice_frames) / total_slices * 50
          
          if dialog and dialog.visible then
            vb.views.progress_text.text = string.format("Normalizing %03d/%03d - %.1f%%", 
              slice_idx, total_slices, progress)
          end
          
          if slicer:was_cancelled() then
            sbuf:finalize_sample_data_changes()
            if completion_callback then completion_callback(false) end
            return
          end
          
          if should_yield() then
            coroutine.yield()
          end
        end
      end
      
      -- Clear the entire cache for this slice
      sample_cache = nil
      slices_processed = slices_processed + 1
    end
    
    -- Finalize changes
    sbuf:finalize_sample_data_changes()
    
    -- Calculate and display performance stats
    local total_time = os.clock() - time_start
    local frames_per_second = total_frames / total_time
    print(string.format("\nSlice normalization complete for %d frames:", total_frames))
    print(string.format("Total time: %.2f seconds (%.1fM frames/sec)", 
      total_time, frames_per_second / 1000000))
    print(string.format("Reading: %.1f%%, Processing: %.1f%%", 
      (time_reading/total_time) * 100,
      ((total_time - time_reading)/total_time) * 100))
    
    -- Close dialog when done
    if dialog and dialog.visible then
      dialog:close()
    end
    
    renoise.app():show_status(string.format("Normalized %d slices independently", slice_count))
    
    -- Call completion callback
    if completion_callback then 
      completion_callback(true)
    end
  end
  
  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Normalizing Slices")
  slicer:start()
end

--------
function normalize_selected_sample_by_slices()
  local selected_sample = renoise.song().selected_sample
  local last_yield_time = os.clock()
  
  -- Function to check if we should yield
  local function should_yield()
    local current_time = os.clock()
    if current_time - last_yield_time >= PROCESS_YIELD_INTERVAL then
      last_yield_time = current_time
      return true
    end
    return false
  end
  
  if not selected_sample or not selected_sample.sample_buffer or not selected_sample.sample_buffer.has_sample_data then
    renoise.app():show_status("Normalization failed: No valid sample to normalize.")
    return
  end

  -- Check if sample has slice markers
  if #selected_sample.slice_markers == 0 then
    -- If no slice markers, fall back to regular normalize
    normalize_selected_sample()
    return
  end

  local sbuf = selected_sample.sample_buffer
  local slice_count = #selected_sample.slice_markers
  
  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil
  
  -- Define the process function
  local function process_func()
    local time_start = os.clock()
    local time_reading = 0
    local time_processing = 0
    local CHUNK_SIZE = 16777216  -- 16MB worth of frames
    local total_frames = sbuf.number_of_frames
    local total_slices = slice_count
    local slices_processed = 0
    
    print(string.format("\nProcessing %d frames across %d slices", total_frames, total_slices))
    
    -- Prepare buffer for changes
    sbuf:prepare_sample_data_changes()
    
    -- Process each slice independently
    for slice_idx = 1, slice_count do
      local slice_start = selected_sample.slice_markers[slice_idx]
      local slice_end = (slice_idx < slice_count) 
        and selected_sample.slice_markers[slice_idx + 1] - 1 
        or sbuf.number_of_frames
      
      local slice_frames = slice_end - slice_start + 1
      
      -- Pre-allocate tables for better performance
      local channel_peaks = {}
      local sample_cache = {}
      for channel = 1, sbuf.number_of_channels do
        channel_peaks[channel] = 0
        sample_cache[channel] = {}
      end
      
      -- First pass: Find peak and cache data
      local highest_detected = 0
      
      -- Process in chunks
      for frame = slice_start, slice_end, CHUNK_SIZE do
        local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
        local block_size = block_end - frame + 1
        
        -- Read and process each channel
        for channel = 1, sbuf.number_of_channels do
          local read_start = os.clock()
          local channel_peak = 0
          
          -- Cache the data while finding peak
          sample_cache[channel][frame] = {}
          for i = 0, block_size - 1 do
            local current_frame = frame + i
            local sample_value = sbuf:sample_data(channel, current_frame)
            sample_cache[channel][frame][i] = sample_value
            local abs_value = math.abs(sample_value)
            if abs_value > channel_peak then
              channel_peak = abs_value
            end
          end
          
          time_reading = time_reading + (os.clock() - read_start)
          if channel_peak > channel_peaks[channel] then
            channel_peaks[channel] = channel_peak
          end
        end
        
        -- Calculate actual progress percentage
        local progress = (slice_idx - 1 + (frame - slice_start) / slice_frames) / total_slices * 100
        
        if dialog and dialog.visible then
          vb.views.progress_text.text = string.format("Processing %03d/%03d - %.1f%%", 
            slice_idx, total_slices, progress)
        end
        
        if slicer:was_cancelled() then
          sbuf:finalize_sample_data_changes()
          return
        end
        
        if should_yield() then
          coroutine.yield()
        end
      end
      
      -- Find overall peak for this slice
      for _, channel_peak in ipairs(channel_peaks) do
        if channel_peak > highest_detected then
          highest_detected = channel_peak
        end
      end
      
      -- Only normalize if the slice isn't silent
      if highest_detected > 0 then
        local scale = 1.0 / highest_detected
        
        -- Second pass: Apply normalization using cached data
        for frame = slice_start, slice_end, CHUNK_SIZE do
          local block_end = math.min(frame + CHUNK_SIZE - 1, slice_end)
          local block_size = block_end - frame + 1
          
          -- Process each channel
          for channel = 1, sbuf.number_of_channels do
            local process_start = os.clock()
            
            for i = 0, block_size - 1 do
              local current_frame = frame + i
              -- Use cached data instead of reading from buffer again
              local sample_value = sample_cache[channel][frame][i]
              sbuf:set_sample_data(channel, current_frame, sample_value * scale)
            end
            
            time_processing = time_processing + (os.clock() - process_start)
          end
          
          -- Clear cache for this chunk to free memory
          for channel = 1, sbuf.number_of_channels do
            sample_cache[channel][frame] = nil
          end
          
          -- Calculate actual progress percentage (50-100% range for normalization phase)
          local progress = 50 + (slice_idx - 1 + (frame - slice_start) / slice_frames) / total_slices * 50
          
          if dialog and dialog.visible then
            vb.views.progress_text.text = string.format("Normalizing %03d/%03d - %.1f%%", 
              slice_idx, total_slices, progress)
          end
          
          if slicer:was_cancelled() then
            sbuf:finalize_sample_data_changes()
            return
          end
          
          if should_yield() then
            coroutine.yield()
          end
        end
      end
      
      -- Clear the entire cache for this slice
      sample_cache = nil
      slices_processed = slices_processed + 1
    end
    
    -- Finalize changes
    sbuf:finalize_sample_data_changes()
    
    -- Calculate and display performance stats
    local total_time = os.clock() - time_start
    local frames_per_second = total_frames / total_time
    print(string.format("\nSlice normalization complete for %d frames:", total_frames))
    print(string.format("Total time: %.2f seconds (%.1fM frames/sec)", 
      total_time, frames_per_second / 1000000))
    print(string.format("Reading: %.1f%%, Processing: %.1f%%", 
      (time_reading/total_time) * 100,
      ((total_time - time_reading)/total_time) * 100))
    
    -- Close dialog when done
    if dialog and dialog.visible then
      dialog:close()
    end
    
    renoise.app():show_status(string.format("Normalized %d slices independently", slice_count))
  end
  
  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Normalizing Slices")
  slicer:start()
end

renoise.tool():add_keybinding{name="Global:Paketti:Normalize Sample Slices Independently",invoke=function() normalize_selected_sample_by_slices() end}

-- Function to convert mono sample to specified channels with blank opposite channel
function mono_to_blank(left_channel, right_channel)
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is mono
  if sample.sample_buffer.number_of_channels ~= 1 then
    renoise.app():show_status("Selected sample is not mono.")
    return
  end

  -- Get the sample buffer and its properties
  local sample_buffer = sample.sample_buffer
  local sample_rate = sample_buffer.sample_rate
  local bit_depth = sample_buffer.bit_depth
  local number_of_frames = sample_buffer.number_of_frames
  local sample_name = sample.name

  -- Store the sample mapping properties
  local sample_mapping = sample.sample_mapping
  local base_note = sample_mapping.base_note
  local note_range = sample_mapping.note_range
  local velocity_range = sample_mapping.velocity_range
  local map_key_to_pitch = sample_mapping.map_key_to_pitch
  local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

  -- Create a new temporary sample slot
  local temp_sample_index = #instrument.samples + 1
  instrument:insert_sample_at(temp_sample_index)
  local temp_sample = instrument:sample(temp_sample_index)
  local temp_sample_buffer = temp_sample.sample_buffer
  
  -- Prepare the temporary sample buffer with the same sample rate and bit depth as the original
  temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
  temp_sample_buffer:prepare_sample_data_changes()

  -- Copy the sample data to the specified channels
  for frame = 1, number_of_frames do
    local sample_value = sample_buffer:sample_data(1, frame)
    if left_channel == 1 then
      temp_sample_buffer:set_sample_data(1, frame, sample_value)
      temp_sample_buffer:set_sample_data(2, frame, 0)
    else
      temp_sample_buffer:set_sample_data(1, frame, 0)
      temp_sample_buffer:set_sample_data(2, frame, sample_value)
    end
  end

  -- Finalize changes
  temp_sample_buffer:finalize_sample_data_changes()

  -- Name the new temporary sample
  temp_sample.name = sample_name
  
  -- Delete the original sample and insert the stereo sample into the same slot
  instrument:delete_sample_at(sample_index)
  instrument:insert_sample_at(sample_index)
  local new_sample = instrument:sample(sample_index)
  new_sample.name = sample_name

  -- Copy the stereo data from the temporary sample buffer to the new sample buffer
  local new_sample_buffer = new_sample.sample_buffer
  new_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
  new_sample_buffer:prepare_sample_data_changes()

  for frame = 1, number_of_frames do
    local left_value = temp_sample_buffer:sample_data(1, frame)
    local right_value = temp_sample_buffer:sample_data(2, frame)
    new_sample_buffer:set_sample_data(1, frame, left_value)
    new_sample_buffer:set_sample_data(2, frame, right_value)
  end

  new_sample_buffer:finalize_sample_data_changes()

  -- Restore the sample mapping properties
  new_sample.sample_mapping.base_note = base_note
  new_sample.sample_mapping.note_range = note_range
  new_sample.sample_mapping.velocity_range = velocity_range
  new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
  new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

  -- Delete the temporary sample
  instrument:delete_sample_at(temp_sample_index)

  -- Provide feedback
  renoise.app():show_status("Mono sample successfully converted to specified channels with blank opposite channel.")
end


-- Function to convert a mono sample to stereo
function convert_mono_to_stereo()
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is mono
  if sample.sample_buffer.number_of_channels ~= 1 then
    renoise.app():show_status("Selected sample is not mono.")
    return
  end

  -- Get the sample buffer and its properties
  local sample_buffer = sample.sample_buffer
  local sample_rate = sample_buffer.sample_rate
  local bit_depth = sample_buffer.bit_depth
  local number_of_frames = sample_buffer.number_of_frames
  local sample_name = sample.name

  -- Store the sample mapping properties
  local sample_mapping = sample.sample_mapping
  local base_note = sample_mapping.base_note
  local note_range = sample_mapping.note_range
  local velocity_range = sample_mapping.velocity_range
  local map_key_to_pitch = sample_mapping.map_key_to_pitch
  local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

  -- Create a new temporary sample slot
  local temp_sample_index = #instrument.samples + 1
  instrument:insert_sample_at(temp_sample_index)
  local temp_sample = instrument:sample(temp_sample_index)
  local temp_sample_buffer = temp_sample.sample_buffer
  
  -- Prepare the temporary sample buffer with the same sample rate and bit depth as the original
  temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
  temp_sample_buffer:prepare_sample_data_changes()

  -- Copy the sample data
  for frame = 1, number_of_frames do
    local sample_value = sample_buffer:sample_data(1, frame)
    temp_sample_buffer:set_sample_data(1, frame, sample_value)
    temp_sample_buffer:set_sample_data(2, frame, sample_value)
  end

  -- Finalize changes
  temp_sample_buffer:finalize_sample_data_changes()

  -- Name the new temporary sample
  temp_sample.name = sample_name
  
  -- Delete the original sample and insert the stereo sample into the same slot
  instrument:delete_sample_at(sample_index)
  instrument:insert_sample_at(sample_index)
  local new_sample = instrument:sample(sample_index)
  new_sample.name = sample_name

  -- Copy the stereo data from the temporary sample buffer to the new sample buffer
  local new_sample_buffer = new_sample.sample_buffer
  new_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
  new_sample_buffer:prepare_sample_data_changes()

  for frame = 1, number_of_frames do
    local sample_value = temp_sample_buffer:sample_data(1, frame)
    new_sample_buffer:set_sample_data(1, frame, sample_value)
    new_sample_buffer:set_sample_data(2, frame, sample_value)
  end

  new_sample_buffer:finalize_sample_data_changes()

  -- Restore the sample mapping properties
  new_sample.sample_mapping.base_note = base_note
  new_sample.sample_mapping.note_range = note_range
  new_sample.sample_mapping.velocity_range = velocity_range
  new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
  new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

  -- Delete the temporary sample
  instrument:delete_sample_at(temp_sample_index)

  -- Provide feedback
  renoise.app():show_status("Mono sample successfully converted to stereo and preserved in the same slot with keymapping settings.")
end

function convert_mono_to_stereo_optimized()
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is mono
  if sample.sample_buffer.number_of_channels ~= 1 then
    renoise.app():show_status("Selected sample is not mono.")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    -- Get the sample buffer and its properties
    local sample_buffer = sample.sample_buffer
    local sample_rate = sample_buffer.sample_rate
    local bit_depth = sample_buffer.bit_depth
    local number_of_frames = sample_buffer.number_of_frames
    local sample_name = sample.name

    -- Store the sample mapping properties
    local sample_mapping = sample.sample_mapping
    local base_note = sample_mapping.base_note
    local note_range = sample_mapping.note_range
    local velocity_range = sample_mapping.velocity_range
    local map_key_to_pitch = sample_mapping.map_key_to_pitch
    local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

    -- Create a new temporary sample slot
    local temp_sample_index = #instrument.samples + 1
    instrument:insert_sample_at(temp_sample_index)
    local temp_sample = instrument:sample(temp_sample_index)
    local temp_sample_buffer = temp_sample.sample_buffer
    
    -- Prepare the temporary sample buffer
    temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
    temp_sample_buffer:prepare_sample_data_changes()

    -- Process in chunks
    local CHUNK_SIZE = 16384
    local processed_frames = 0

    -- Copy the sample data
    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local sample_value = sample_buffer:sample_data(1, f)
        temp_sample_buffer:set_sample_data(1, f, sample_value)
        temp_sample_buffer:set_sample_data(2, f, sample_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Converting to stereo... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        temp_sample_buffer:finalize_sample_data_changes()
        instrument:delete_sample_at(temp_sample_index)
        return
      end

      coroutine.yield()
    end

    -- Finalize changes
    temp_sample_buffer:finalize_sample_data_changes()

    -- Name the new temporary sample
    temp_sample.name = sample_name
    
    -- Delete the original sample and insert the stereo sample into the same slot
    instrument:delete_sample_at(sample_index)
    instrument:insert_sample_at(sample_index)
    local new_sample = instrument:sample(sample_index)
    new_sample.name = sample_name

    -- Copy the stereo data from the temporary sample buffer to the new sample buffer
    local new_sample_buffer = new_sample.sample_buffer
    new_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
    new_sample_buffer:prepare_sample_data_changes()

    processed_frames = 0

    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local left_value = temp_sample_buffer:sample_data(1, f)
        local right_value = temp_sample_buffer:sample_data(2, f)
        new_sample_buffer:set_sample_data(1, f, left_value)
        new_sample_buffer:set_sample_data(2, f, right_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Finalizing... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        new_sample_buffer:finalize_sample_data_changes()
        return
      end

      coroutine.yield()
    end

    new_sample_buffer:finalize_sample_data_changes()

    -- Restore the sample mapping properties
    new_sample.sample_mapping.base_note = base_note
    new_sample.sample_mapping.note_range = note_range
    new_sample.sample_mapping.velocity_range = velocity_range
    new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
    new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

    -- Delete the temporary sample
    instrument:delete_sample_at(temp_sample_index)

    if dialog and dialog.visible then
      dialog:close()
    end

    -- Provide feedback
    renoise.app():show_status("Mono sample successfully converted to stereo.")
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Converting Mono to Stereo")
  slicer:start()
end

function mono_to_blank_optimized(left_channel, right_channel)
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is mono
  if sample.sample_buffer.number_of_channels ~= 1 then
    renoise.app():show_status("Selected sample is not mono.")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    -- Get the sample buffer and its properties
    local sample_buffer = sample.sample_buffer
    local sample_rate = sample_buffer.sample_rate
    local bit_depth = sample_buffer.bit_depth
    local number_of_frames = sample_buffer.number_of_frames
    local sample_name = sample.name

    -- Store the sample mapping properties
    local sample_mapping = sample.sample_mapping
    local base_note = sample_mapping.base_note
    local note_range = sample_mapping.note_range
    local velocity_range = sample_mapping.velocity_range
    local map_key_to_pitch = sample_mapping.map_key_to_pitch
    local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

    -- Create a new temporary sample slot
    local temp_sample_index = #instrument.samples + 1
    instrument:insert_sample_at(temp_sample_index)
    local temp_sample = instrument:sample(temp_sample_index)
    local temp_sample_buffer = temp_sample.sample_buffer
    
    -- Prepare the temporary sample buffer
    temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
    temp_sample_buffer:prepare_sample_data_changes()

    -- Process in chunks
    local CHUNK_SIZE = 16384
    local processed_frames = 0

    -- Copy the sample data to the specified channels
    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local sample_value = sample_buffer:sample_data(1, f)
        if left_channel == 1 then
          temp_sample_buffer:set_sample_data(1, f, sample_value)
          temp_sample_buffer:set_sample_data(2, f, 0)
        else
          temp_sample_buffer:set_sample_data(1, f, 0)
          temp_sample_buffer:set_sample_data(2, f, sample_value)
        end
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Converting to stereo... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        temp_sample_buffer:finalize_sample_data_changes()
        instrument:delete_sample_at(temp_sample_index)
        return
      end

      coroutine.yield()
    end

    -- Finalize changes
    temp_sample_buffer:finalize_sample_data_changes()

    -- Name the new temporary sample
    temp_sample.name = sample_name
    
    -- Delete the original sample and insert the stereo sample into the same slot
    instrument:delete_sample_at(sample_index)
    instrument:insert_sample_at(sample_index)
    local new_sample = instrument:sample(sample_index)
    new_sample.name = sample_name

    -- Copy the stereo data from the temporary sample buffer to the new sample buffer
    local new_sample_buffer = new_sample.sample_buffer
    new_sample_buffer:create_sample_data(sample_rate, bit_depth, 2, number_of_frames)
    new_sample_buffer:prepare_sample_data_changes()

    processed_frames = 0

    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local left_value = temp_sample_buffer:sample_data(1, f)
        local right_value = temp_sample_buffer:sample_data(2, f)
        new_sample_buffer:set_sample_data(1, f, left_value)
        new_sample_buffer:set_sample_data(2, f, right_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Finalizing... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        new_sample_buffer:finalize_sample_data_changes()
        return
      end

      coroutine.yield()
    end

    new_sample_buffer:finalize_sample_data_changes()

    -- Restore the sample mapping properties
    new_sample.sample_mapping.base_note = base_note
    new_sample.sample_mapping.note_range = note_range
    new_sample.sample_mapping.velocity_range = velocity_range
    new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
    new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

    -- Delete the temporary sample
    instrument:delete_sample_at(temp_sample_index)

    if dialog and dialog.visible then
      dialog:close()
    end

    -- Provide feedback
    renoise.app():show_status("Mono sample successfully converted to stereo with blank channel.")
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Converting Mono to Stereo")
  slicer:start()
end

function stereo_to_mono_optimized(keep_channel)
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is stereo
  if sample.sample_buffer.number_of_channels ~= 2 then
    renoise.app():show_status("Selected sample is not stereo.")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    -- Get the sample buffer and its properties
    local sample_buffer = sample.sample_buffer
    local sample_rate = sample_buffer.sample_rate
    local bit_depth = sample_buffer.bit_depth
    local number_of_frames = sample_buffer.number_of_frames
    local sample_name = sample.name

    -- Store the sample mapping properties
    local sample_mapping = sample.sample_mapping
    local base_note = sample_mapping.base_note
    local note_range = sample_mapping.note_range
    local velocity_range = sample_mapping.velocity_range
    local map_key_to_pitch = sample_mapping.map_key_to_pitch
    local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

    -- Create a new temporary sample slot
    local temp_sample_index = #instrument.samples + 1
    instrument:insert_sample_at(temp_sample_index)
    local temp_sample = instrument:sample(temp_sample_index)
    local temp_sample_buffer = temp_sample.sample_buffer
    
    -- Prepare the temporary sample buffer
    temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 1, number_of_frames)
    temp_sample_buffer:prepare_sample_data_changes()

    -- Process in chunks
    local CHUNK_SIZE = 16384
    local processed_frames = 0

    -- Copy the sample data from the specified channel
    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local sample_value = sample_buffer:sample_data(keep_channel, f)
        temp_sample_buffer:set_sample_data(1, f, sample_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Converting to mono... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        temp_sample_buffer:finalize_sample_data_changes()
        instrument:delete_sample_at(temp_sample_index)
        return
      end

      coroutine.yield()
    end

    -- Finalize changes
    temp_sample_buffer:finalize_sample_data_changes()

    -- Name the new temporary sample
    temp_sample.name = sample_name
    
    -- Delete the original sample and insert the mono sample into the same slot
    instrument:delete_sample_at(sample_index)
    instrument:insert_sample_at(sample_index)
    local new_sample = instrument:sample(sample_index)
    new_sample.name = sample_name

    -- Copy the mono data from the temporary sample buffer to the new sample buffer
    local new_sample_buffer = new_sample.sample_buffer
    new_sample_buffer:create_sample_data(sample_rate, bit_depth, 1, number_of_frames)
    new_sample_buffer:prepare_sample_data_changes()

    processed_frames = 0

    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local mono_value = temp_sample_buffer:sample_data(1, f)
        new_sample_buffer:set_sample_data(1, f, mono_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Finalizing... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        new_sample_buffer:finalize_sample_data_changes()
        return
      end

      coroutine.yield()
    end

    new_sample_buffer:finalize_sample_data_changes()

    -- Restore the sample mapping properties
    new_sample.sample_mapping.base_note = base_note
    new_sample.sample_mapping.note_range = note_range
    new_sample.sample_mapping.velocity_range = velocity_range
    new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
    new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

    -- Delete the temporary sample
    instrument:delete_sample_at(temp_sample_index)

    if dialog and dialog.visible then
      dialog:close()
    end

    -- Provide feedback
    local channel_name = keep_channel == 1 and "left" or "right"
    renoise.app():show_status(string.format("Stereo sample successfully converted to mono (kept %s channel).", channel_name))
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Converting Stereo to Mono")
  slicer:start()
end




renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert Mono to Stereo",invoke=convert_mono_to_stereo_optimized}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Mono to Left with Blank Right",invoke=function() mono_to_blank_optimized(1, 0) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Mono to Right with Blank Left",invoke=function() mono_to_blank_optimized(0, 1) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert Stereo to Mono (Keep Left)",invoke=function() stereo_to_mono_optimized(1) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert Stereo to Mono (Keep Right)",invoke=function() stereo_to_mono_optimized(2) end}

renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert Mono to Stereo",invoke=convert_mono_to_stereo_optimized}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Mono to Left with Blank Right",invoke=function() mono_to_blank_optimized(1, 0) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Mono to Right with Blank Left",invoke=function() mono_to_blank_optimized(0, 1) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert Stereo to Mono (Keep Left)",invoke=function() stereo_to_mono_optimized(1) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert Stereo to Mono (Keep Right)",invoke=function() stereo_to_mono_optimized(2) end}

renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert Mono to Stereo",invoke=convert_mono_to_stereo_optimized}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Mono to Right with Blank Left",invoke=function() mono_to_blank_optimized(0, 1) end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Mono to Left with Blank Right",invoke=function() mono_to_blank_optimized(1, 0) end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert Stereo to Mono (Keep Left)",invoke=function() stereo_to_mono_optimized(1) end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert Stereo to Mono (Keep Right)",invoke=function() stereo_to_mono_optimized(2) end}

function stereo_to_mono_mix_optimized()
  -- Ensure a song exists
  if not renoise.song() then
    renoise.app():show_status("No song is currently loaded.")
    return
  end

  -- Ensure an instrument is selected
  local song=renoise.song()
  local instrument = song.selected_instrument
  if not instrument then
    renoise.app():show_status("No instrument is selected.")
    return
  end

  -- Ensure a sample is selected
  local sample_index = song.selected_sample_index
  local sample = instrument:sample(sample_index)
  if not sample then
    renoise.app():show_status("No sample is selected.")
    return
  end

  -- Ensure the sample is stereo
  if sample.sample_buffer.number_of_channels ~= 2 then
    renoise.app():show_status("Selected sample is not stereo.")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    -- Get the sample buffer and its properties
    local sample_buffer = sample.sample_buffer
    local sample_rate = sample_buffer.sample_rate
    local bit_depth = sample_buffer.bit_depth
    local number_of_frames = sample_buffer.number_of_frames
    local sample_name = sample.name

    -- Store the sample mapping properties
    local sample_mapping = sample.sample_mapping
    local base_note = sample_mapping.base_note
    local note_range = sample_mapping.note_range
    local velocity_range = sample_mapping.velocity_range
    local map_key_to_pitch = sample_mapping.map_key_to_pitch
    local map_velocity_to_volume = sample_mapping.map_velocity_to_volume

    -- Create a new temporary sample slot
    local temp_sample_index = #instrument.samples + 1
    instrument:insert_sample_at(temp_sample_index)
    local temp_sample = instrument:sample(temp_sample_index)
    local temp_sample_buffer = temp_sample.sample_buffer
    
    -- Prepare the temporary sample buffer
    temp_sample_buffer:create_sample_data(sample_rate, bit_depth, 1, number_of_frames)
    temp_sample_buffer:prepare_sample_data_changes()

    -- Process in chunks
    local CHUNK_SIZE = 16384
    local processed_frames = 0

    -- Mix both channels to mono
    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        -- Get both channel values
        local left_value = sample_buffer:sample_data(1, f)
        local right_value = sample_buffer:sample_data(2, f)
        
        -- Mix to mono (average of both channels)
        local mono_value = (left_value + right_value) * 0.5
        
        -- Store the mixed value
        temp_sample_buffer:set_sample_data(1, f, mono_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Converting to mono... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        temp_sample_buffer:finalize_sample_data_changes()
        instrument:delete_sample_at(temp_sample_index)
        return
      end

      coroutine.yield()
    end

    -- Finalize changes
    temp_sample_buffer:finalize_sample_data_changes()

    -- Name the new temporary sample
    temp_sample.name = sample_name
    
    -- Delete the original sample and insert the mono sample into the same slot
    instrument:delete_sample_at(sample_index)
    instrument:insert_sample_at(sample_index)
    local new_sample = instrument:sample(sample_index)
    new_sample.name = sample_name

    -- Copy the mono data from the temporary sample buffer to the new sample buffer
    local new_sample_buffer = new_sample.sample_buffer
    new_sample_buffer:create_sample_data(sample_rate, bit_depth, 1, number_of_frames)
    new_sample_buffer:prepare_sample_data_changes()

    processed_frames = 0

    for frame = 1, number_of_frames, CHUNK_SIZE do
      local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
      
      for f = frame, block_end do
        local mono_value = temp_sample_buffer:sample_data(1, f)
        new_sample_buffer:set_sample_data(1, f, mono_value)
      end

      processed_frames = processed_frames + (block_end - frame + 1)
      
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Finalizing... %.1f%%", 
          (processed_frames / number_of_frames) * 100)
      end

      if slicer:was_cancelled() then
        new_sample_buffer:finalize_sample_data_changes()
        return
      end

      coroutine.yield()
    end

    new_sample_buffer:finalize_sample_data_changes()

    -- Restore the sample mapping properties
    new_sample.sample_mapping.base_note = base_note
    new_sample.sample_mapping.note_range = note_range
    new_sample.sample_mapping.velocity_range = velocity_range
    new_sample.sample_mapping.map_key_to_pitch = map_key_to_pitch
    new_sample.sample_mapping.map_velocity_to_volume = map_velocity_to_volume

    -- Delete the temporary sample
    instrument:delete_sample_at(temp_sample_index)

    if dialog and dialog.visible then
      dialog:close()
    end

    -- Provide feedback
    renoise.app():show_status("Stereo sample successfully mixed down to mono.")
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Converting Stereo to Mono (Mix)")
  slicer:start()
end


renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert Stereo to Mono (Mix Both)",invoke=stereo_to_mono_mix_optimized}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert Stereo to Mono (Mix Both)",invoke=stereo_to_mono_mix_optimized}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert Stereo to Mono (Mix Both)",invoke=stereo_to_mono_mix_optimized}
----
function convert_all_samples_to_mono(mode)
  local instrument = renoise.song().selected_instrument
  if not instrument then
    renoise.app():show_warning("No instrument selected")
    return
  end

  local total_samples = #instrument.samples
  if total_samples == 0 then
    renoise.app():show_warning("No samples in selected instrument")
    return
  end

  -- Create ProcessSlicer instance and dialog
  local slicer = nil
  local dialog = nil
  local vb = nil

  -- Define the process function
  local function process_func()
    local processed_samples = 0
    local skipped_samples = 0

    for sample_idx = 1, total_samples do
      local sample = instrument.samples[sample_idx]
      
      -- Update progress dialog
      if dialog and dialog.visible then
        vb.views.progress_text.text = string.format("Processing sample %d of %d", sample_idx, total_samples)
      end
      
      -- Check if we should process this sample
      local should_process = true
      if not sample or not sample.sample_buffer.has_sample_data then
        should_process = false
      elseif sample.sample_buffer.number_of_channels ~= 2 then
        should_process = false
      elseif #sample.slice_markers > 0 then
        should_process = false
      end

      if should_process then
        -- Set the selected sample index so user can see which sample is being processed
        renoise.song().selected_sample_index = sample_idx

        -- Store all sample properties
        local properties = {
          name = sample.name,
          volume = sample.volume,
          panning = sample.panning,
          transpose = sample.transpose,
          fine_tune = sample.fine_tune,
          beat_sync_enabled = sample.beat_sync_enabled,
          beat_sync_lines = sample.beat_sync_lines,
          beat_sync_mode = sample.beat_sync_mode,
          oneshot = sample.oneshot,
          loop_release = sample.loop_release,
          loop_mode = sample.loop_mode,
          mute_group = sample.mute_group,
          new_note_action = sample.new_note_action,
          autoseek = sample.autoseek,
          autofade = sample.autofade,
          oversample_enabled = sample.oversample_enabled,
          interpolation_mode = sample.interpolation_mode,
          sample_mapping = {
            base_note = sample.sample_mapping.base_note,
            note_range = sample.sample_mapping.note_range,
            velocity_range = sample.sample_mapping.velocity_range,
            map_key_to_pitch = sample.sample_mapping.map_key_to_pitch,
            map_velocity_to_volume = sample.sample_mapping.map_velocity_to_volume
          }
        }

        local buffer = sample.sample_buffer
        local num_frames = buffer.number_of_frames
        local new_sample = instrument:insert_sample_at(sample_idx + 1)
        new_sample.sample_buffer:create_sample_data(buffer.sample_rate, buffer.bit_depth, 1, num_frames)
        new_sample.sample_buffer:prepare_sample_data_changes()

        -- Process sample data in chunks
        for frame = 1, num_frames, CHUNK_SIZE do
          local chunk_end = math.min(frame + CHUNK_SIZE - 1, num_frames)
          
          for f = frame, chunk_end do
            local left_value = buffer:sample_data(1, f)
            local right_value = buffer:sample_data(2, f)
            local mono_value
            
            if mode == "left" then
              mono_value = left_value
            elseif mode == "right" then
              mono_value = right_value
            else -- mix
              mono_value = (left_value + right_value) * 0.5
            end
            
            new_sample.sample_buffer:set_sample_data(1, f, mono_value)
          end
          
          if slicer:was_cancelled() then
            new_sample.sample_buffer:finalize_sample_data_changes()
            return
          end
          
          coroutine.yield()
        end

        new_sample.sample_buffer:finalize_sample_data_changes()

        -- Restore all properties
        new_sample.name = properties.name
        new_sample.volume = properties.volume
        new_sample.panning = properties.panning
        new_sample.transpose = properties.transpose
        new_sample.fine_tune = properties.fine_tune
        new_sample.beat_sync_enabled = properties.beat_sync_enabled
        new_sample.beat_sync_lines = properties.beat_sync_lines
        new_sample.beat_sync_mode = properties.beat_sync_mode
        new_sample.oneshot = properties.oneshot
        new_sample.loop_release = properties.loop_release
        new_sample.loop_mode = properties.loop_mode
        new_sample.mute_group = properties.mute_group
        new_sample.new_note_action = properties.new_note_action
        new_sample.autoseek = properties.autoseek
        new_sample.autofade = properties.autofade
        new_sample.oversample_enabled = properties.oversample_enabled
        new_sample.interpolation_mode = properties.interpolation_mode
        new_sample.sample_mapping.base_note = properties.sample_mapping.base_note
        new_sample.sample_mapping.note_range = properties.sample_mapping.note_range
        new_sample.sample_mapping.velocity_range = properties.sample_mapping.velocity_range
        new_sample.sample_mapping.map_key_to_pitch = properties.sample_mapping.map_key_to_pitch
        new_sample.sample_mapping.map_velocity_to_volume = properties.sample_mapping.map_velocity_to_volume

        -- Delete the original stereo sample
        instrument:delete_sample_at(sample_idx)
        processed_samples = processed_samples + 1
      else
        skipped_samples = skipped_samples + 1
      end
    end

    if dialog and dialog.visible then
      dialog:close()
    end
    
    local msg = string.format("Converted %d samples to mono. Skipped %d samples.", 
      processed_samples, skipped_samples)
    renoise.app():show_status(msg)
  end

  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_func)
  dialog, vb = slicer:create_dialog("Converting All Samples to Mono")
  slicer:start()
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to Mono (Keep Left)",invoke=function() convert_all_samples_to_mono("left") end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to Mono (Keep Right)",invoke=function() convert_all_samples_to_mono("right") end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to Mono (Mix Both)",invoke=function() convert_all_samples_to_mono("mix") end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to Mono (Keep Left)",invoke=function() convert_all_samples_to_mono("left") end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to Mono (Keep Right)",invoke=function() convert_all_samples_to_mono("right") end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to Mono (Mix Both)",invoke=function() convert_all_samples_to_mono("mix") end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert All Samples to Mono (Keep Left)",invoke=function() convert_all_samples_to_mono("left") end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Process:Convert All Samples to Mono (Keep Right)",invoke=function() convert_all_samples_to_mono("right") end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Process:Convert All Samples to Mono (Mix Both)",invoke=function() convert_all_samples_to_mono("mix") end}

function convert_bit_depth(target_bits)
    -- Ensure a song exists
    if not renoise.song() then
        renoise.app():show_status("No song is currently loaded.")
        return
    end

    -- Ensure an instrument is selected
    local song=renoise.song()
    local instrument = song.selected_instrument
    if not instrument then
        renoise.app():show_status("No instrument is selected.")
        return
    end

    -- Ensure a sample is selected
    local sample_index = song.selected_sample_index
    local sample = instrument:sample(sample_index)
    if not sample or not sample.sample_buffer.has_sample_data then
        renoise.app():show_status("No sample selected or sample has no data.")
        return
    end

    -- Create ProcessSlicer instance and dialog
    local slicer = nil
    local dialog = nil
    local vb = nil

    -- Helper function for dithering
    local function dither_sample(sample_value, target_bits)
        -- Add triangular dithering (TPDF)
        local r1 = math.random() - 0.5
        local r2 = math.random() - 0.5
        local dither = (r1 + r2) / math.pow(2, target_bits - 1)
        return sample_value + dither
    end

    -- Helper function for bit depth conversion
    local function convert_to_bit_depth(sample_value, target_bits)
        -- First clamp the 32-bit float value to -1.0 to +1.0
        local clamped = math.max(-1.0, math.min(1.0, sample_value))
        
        -- Calculate max value for target bit depth
        local max_value = math.pow(2, target_bits - 1) - 1
        
        -- Scale the float to target range
        local scaled = clamped * max_value
        
        -- Round to nearest integer
        local rounded = math.floor(scaled + 0.5)
        
        -- Convert back to float (-1.0 to +1.0)
        return rounded / max_value
    end

    -- Define the process function
    local function process_func()
        local sample_buffer = sample.sample_buffer
        local total_frames = sample_buffer.number_of_frames
        local num_channels = sample_buffer.number_of_channels
        local processed_frames = 0
        -- Remove local CHUNK_SIZE definition here

        -- Store ALL sample properties
        local properties = {
            -- Basic properties
            name = sample.name,
            volume = sample.volume,
            panning = sample.panning,
            transpose = sample.transpose,
            fine_tune = sample.fine_tune,
            
            -- Beat sync properties
            beat_sync_enabled = sample.beat_sync_enabled,
            beat_sync_lines = sample.beat_sync_lines,
            beat_sync_mode = sample.beat_sync_mode,
            
            -- Loop and playback properties
            oneshot = sample.oneshot,
            loop_release = sample.loop_release,
            loop_mode = sample.loop_mode,
            mute_group = sample.mute_group,
            new_note_action = sample.new_note_action,
            
            -- Audio processing properties
            autoseek = sample.autoseek,
            autofade = sample.autofade,
            oversample_enabled = sample.oversample_enabled,
            interpolation_mode = sample.interpolation_mode,
            
            -- Mapping properties
            sample_mapping = {
                base_note = sample.sample_mapping.base_note,
                note_range = sample.sample_mapping.note_range,
                velocity_range = sample.sample_mapping.velocity_range,
                map_key_to_pitch = sample.sample_mapping.map_key_to_pitch,
                map_velocity_to_volume = sample.sample_mapping.map_velocity_to_volume
            }
        }

        -- Create a new temporary sample slot
        local temp_sample_index = #instrument.samples + 1
        instrument:insert_sample_at(temp_sample_index)
        local temp_sample = instrument:sample(temp_sample_index)
        local temp_sample_buffer = temp_sample.sample_buffer
        
        -- Create new sample buffer with desired bit depth
        temp_sample_buffer:create_sample_data(
            sample_buffer.sample_rate,
            target_bits,
            num_channels,
            total_frames
        )
        temp_sample_buffer:prepare_sample_data_changes()

        -- Process each channel in chunks
        for channel = 1, num_channels do
            for frame = 1, total_frames, CHUNK_SIZE do
                local block_end = math.min(frame + CHUNK_SIZE - 1, total_frames)
                
                for f = frame, block_end do
                    -- Get original sample value
                    local value = sample_buffer:sample_data(channel, f)
                    
                    -- Apply dithering
                    value = dither_sample(value, target_bits)
                    
                    -- Convert to target bit depth
                    value = convert_to_bit_depth(value, target_bits)
                    
                    -- Write to new buffer
                    temp_sample_buffer:set_sample_data(channel, f, value)
                end

                processed_frames = processed_frames + (block_end - frame + 1)
                
                -- Update progress
                if dialog and dialog.visible then
                    local progress = (processed_frames / (total_frames * num_channels)) * 100
                    vb.views.progress_text.text = string.format(
                        "Converting to %d-bit... %.1f%%", target_bits, progress)
                end

                -- Check for cancellation
                if slicer:was_cancelled() then
                    temp_sample_buffer:finalize_sample_data_changes()
                    instrument:delete_sample_at(temp_sample_index)
                    return
                end

                coroutine.yield()
            end
        end

        -- Finalize changes to temporary buffer
        temp_sample_buffer:finalize_sample_data_changes()

        -- Delete the original sample and insert the new one in its place
        instrument:delete_sample_at(sample_index)
        instrument:insert_sample_at(sample_index)
        local new_sample = instrument:sample(sample_index)

        -- Copy the processed data to the new sample
        local new_sample_buffer = new_sample.sample_buffer
        new_sample_buffer:create_sample_data(
            sample_buffer.sample_rate,
            target_bits,
            num_channels,
            total_frames
        )
        new_sample_buffer:prepare_sample_data_changes()

        -- Copy data from temp buffer to new buffer
        for channel = 1, num_channels do
            for frame = 1, total_frames do
                new_sample_buffer:set_sample_data(
                    channel,
                    frame,
                    temp_sample_buffer:sample_data(channel, frame)
                )
            end
        end

        new_sample_buffer:finalize_sample_data_changes()

        -- Restore ALL sample properties
        new_sample.name = properties.name
        new_sample.volume = properties.volume
        new_sample.panning = properties.panning
        new_sample.transpose = properties.transpose
        new_sample.fine_tune = properties.fine_tune
        
        new_sample.beat_sync_enabled = properties.beat_sync_enabled
        new_sample.beat_sync_lines = properties.beat_sync_lines
        new_sample.beat_sync_mode = properties.beat_sync_mode
        
        new_sample.oneshot = properties.oneshot
        new_sample.loop_release = properties.loop_release
        new_sample.loop_mode = properties.loop_mode
        new_sample.mute_group = properties.mute_group
        new_sample.new_note_action = properties.new_note_action
        
        new_sample.autoseek = properties.autoseek
        new_sample.autofade = properties.autofade
        new_sample.oversample_enabled = properties.oversample_enabled
        new_sample.interpolation_mode = properties.interpolation_mode
        
        new_sample.sample_mapping.base_note = properties.sample_mapping.base_note
        new_sample.sample_mapping.note_range = properties.sample_mapping.note_range
        new_sample.sample_mapping.velocity_range = properties.sample_mapping.velocity_range
        new_sample.sample_mapping.map_key_to_pitch = properties.sample_mapping.map_key_to_pitch
        new_sample.sample_mapping.map_velocity_to_volume = properties.sample_mapping.map_velocity_to_volume

        -- Delete the temporary sample
        instrument:delete_sample_at(temp_sample_index)

        if dialog and dialog.visible then
            dialog:close()
        end

        -- Show completion message
        renoise.app():show_status(string.format(
            "Converted '%s' to %d-bit", new_sample.name, target_bits))
    end

    -- Create and start the ProcessSlicer
    slicer = ProcessSlicer(process_func)
    dialog, vb = slicer:create_dialog(string.format("Converting to %d-bit", target_bits))
    slicer:start()
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert to 8-bit", invoke=function() convert_bit_depth(8) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert to 16-bit", invoke=function() convert_bit_depth(16) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert to 24-bit", invoke=function() convert_bit_depth(24) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert to 32-bit", invoke=function() convert_bit_depth(32) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert to 8-bit", invoke=function() convert_bit_depth(8) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert to 16-bit", invoke=function() convert_bit_depth(16) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert to 24-bit", invoke=function() convert_bit_depth(24) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert to 32-bit", invoke=function() convert_bit_depth(32) end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert to 8-bit", invoke=function(message) if message:is_trigger() then convert_bit_depth(8) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert to 16-bit", invoke=function(message) if message:is_trigger() then convert_bit_depth(16) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert to 24-bit", invoke=function(message) if message:is_trigger() then convert_bit_depth(24) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert to 32-bit", invoke=function(message) if message:is_trigger() then convert_bit_depth(32) end end}

function convert_all_samples_to_bit_depth(target_bits)
    -- Ensure a song exists
    if not renoise.song() then
        renoise.app():show_status("No song is currently loaded.")
        return
    end

    -- Ensure an instrument is selected
    local song=renoise.song()
    local instrument = song.selected_instrument
    if not instrument then
        renoise.app():show_status("No instrument is selected.")
        return
    end

    -- Check if we have any samples
    if #instrument.samples == 0 then
        renoise.app():show_status("Selected instrument has no samples.")
        return
    end

    -- Create ProcessSlicer instance and dialog
    local slicer = nil
    local dialog = nil
    local vb = nil

    -- Helper function for dithering
    local function dither_sample(sample_value, target_bits)
        local r1 = math.random() - 0.5
        local r2 = math.random() - 0.5
        local dither = (r1 + r2) / math.pow(2, target_bits - 1)
        return sample_value + dither
    end

    -- Helper function for bit depth conversion
    local function convert_to_bit_depth(sample_value, target_bits)
        local clamped = math.max(-1.0, math.min(1.0, sample_value))
        local max_value = math.pow(2, target_bits - 1) - 1
        local scaled = clamped * max_value
        local rounded = math.floor(scaled + 0.5)
        return rounded / max_value
    end

    -- Define the process function
    local function process_func()
        local total_samples = #instrument.samples
        local processed_samples = 0
        local skipped_samples = 0
        local converted_samples = 0

        -- Process each sample
        for sample_index = 1, total_samples do
            local sample = instrument:sample(sample_index)
            
            -- Update progress
            if dialog and dialog.visible then
                vb.views.progress_text.text = string.format("Processing sample %d/%d...", 
                    sample_index, total_samples)
            end

            -- Skip invalid samples
            if not sample or not sample.sample_buffer.has_sample_data then
                print(string.format("Skipping sample %d: No sample data", sample_index))
                skipped_samples = skipped_samples + 1
            elseif sample.sample_buffer.bit_depth == target_bits then
                print(string.format("Skipping sample %d: Already at %d-bit", sample_index, target_bits))
                skipped_samples = skipped_samples + 1
            else
                -- Set the selected sample index so user can see which sample is being processed
                renoise.song().selected_sample_index = sample_index

                -- Store ALL sample properties
                local properties = {
                    name = sample.name,
                    volume = sample.volume,
                    panning = sample.panning,
                    transpose = sample.transpose,
                    fine_tune = sample.fine_tune,
                    beat_sync_enabled = sample.beat_sync_enabled,
                    beat_sync_lines = sample.beat_sync_lines,
                    beat_sync_mode = sample.beat_sync_mode,
                    oneshot = sample.oneshot,
                    loop_release = sample.loop_release,
                    loop_mode = sample.loop_mode,
                    mute_group = sample.mute_group,
                    new_note_action = sample.new_note_action,
                    autoseek = sample.autoseek,
                    autofade = sample.autofade,
                    oversample_enabled = sample.oversample_enabled,
                    interpolation_mode = sample.interpolation_mode,
                    sample_mapping = {
                        base_note = sample.sample_mapping.base_note,
                        note_range = sample.sample_mapping.note_range,
                        velocity_range = sample.sample_mapping.velocity_range,
                        map_key_to_pitch = sample.sample_mapping.map_key_to_pitch,
                        map_velocity_to_volume = sample.sample_mapping.map_velocity_to_volume
                    }
                }

                local sample_buffer = sample.sample_buffer
                local num_channels = sample_buffer.number_of_channels
                local number_of_frames = sample_buffer.number_of_frames

                -- Create a new temporary sample slot
                local temp_sample_index = #instrument.samples + 1
                instrument:insert_sample_at(temp_sample_index)
                local temp_sample = instrument:sample(temp_sample_index)
                local temp_sample_buffer = temp_sample.sample_buffer
                
                -- Create new sample buffer with desired bit depth
                temp_sample_buffer:create_sample_data(
                    sample_buffer.sample_rate,
                    target_bits,
                    num_channels,
                    number_of_frames
                )
                temp_sample_buffer:prepare_sample_data_changes()

                -- Process in chunks
                local processed_frames = 0  -- Remove local CHUNK_SIZE definition here

                -- Convert the sample data
                for channel = 1, num_channels do
                    for frame = 1, number_of_frames, CHUNK_SIZE do
                        local block_end = math.min(frame + CHUNK_SIZE - 1, number_of_frames)
                        
                        for f = frame, block_end do
                            local value = sample_buffer:sample_data(channel, f)
                            value = dither_sample(value, target_bits)
                            value = convert_to_bit_depth(value, target_bits)
                            temp_sample_buffer:set_sample_data(channel, f, value)
                        end

                        processed_frames = processed_frames + (block_end - frame + 1)
                        
                        -- Calculate overall progress (combine sample index and frame progress)
                        local sample_progress = processed_frames / (number_of_frames * num_channels)
                        local total_progress = ((sample_index - 1) + sample_progress) / total_samples * 100
                        
                        if dialog and dialog.visible then
                            vb.views.progress_text.text = string.format(
                                "Converting sample %d/%d to %d-bit... %.1f%%", 
                                sample_index, total_samples, target_bits, total_progress)
                        end

                        if slicer:was_cancelled() then
                            temp_sample_buffer:finalize_sample_data_changes()
                            instrument:delete_sample_at(temp_sample_index)
                            return
                        end

                        coroutine.yield()
                    end
                end

                -- Finalize changes to temporary buffer
                temp_sample_buffer:finalize_sample_data_changes()

                -- Delete the original sample and insert the new one in its place
                instrument:delete_sample_at(sample_index)
                instrument:insert_sample_at(sample_index)
                local new_sample = instrument:sample(sample_index)

                -- Copy the processed data to the new sample
                local new_sample_buffer = new_sample.sample_buffer
                new_sample_buffer:create_sample_data(
                    sample_buffer.sample_rate,
                    target_bits,
                    num_channels,
                    number_of_frames
                )
                new_sample_buffer:prepare_sample_data_changes()

                -- Copy data from temp buffer to new buffer
                for channel = 1, num_channels do
                    for frame = 1, number_of_frames do
                        new_sample_buffer:set_sample_data(
                            channel,
                            frame,
                            temp_sample_buffer:sample_data(channel, frame)
                        )
                    end
                end

                new_sample_buffer:finalize_sample_data_changes()

                -- Restore ALL sample properties
                new_sample.name = properties.name
                new_sample.volume = properties.volume
                new_sample.panning = properties.panning
                new_sample.transpose = properties.transpose
                new_sample.fine_tune = properties.fine_tune
                new_sample.beat_sync_enabled = properties.beat_sync_enabled
                new_sample.beat_sync_lines = properties.beat_sync_lines
                new_sample.beat_sync_mode = properties.beat_sync_mode
                new_sample.oneshot = properties.oneshot
                new_sample.loop_release = properties.loop_release
                new_sample.loop_mode = properties.loop_mode
                new_sample.mute_group = properties.mute_group
                new_sample.new_note_action = properties.new_note_action
                new_sample.autoseek = properties.autoseek
                new_sample.autofade = properties.autofade
                new_sample.oversample_enabled = properties.oversample_enabled
                new_sample.interpolation_mode = properties.interpolation_mode
                new_sample.sample_mapping.base_note = properties.sample_mapping.base_note
                new_sample.sample_mapping.note_range = properties.sample_mapping.note_range
                new_sample.sample_mapping.velocity_range = properties.sample_mapping.velocity_range
                new_sample.sample_mapping.map_key_to_pitch = properties.sample_mapping.map_key_to_pitch
                new_sample.sample_mapping.map_velocity_to_volume = properties.sample_mapping.map_velocity_to_volume

                
                -- Delete the temporary sample
                instrument:delete_sample_at(temp_sample_index)

                converted_samples = converted_samples + 1
                print(string.format("Converted sample %d to %d-bit", sample_index, target_bits))
            end
        end

        if dialog and dialog.visible then
            dialog:close()
        end

        -- Provide feedback
        local message = string.format(
            "Converted %d samples to %d-bit. Skipped %d samples.", 
            converted_samples, target_bits, skipped_samples
        )
        print(message)
        renoise.app():show_status(message)
    end

    -- Create and start the ProcessSlicer
    slicer = ProcessSlicer(process_func)
    dialog, vb = slicer:create_dialog(string.format("Converting All Samples to %d-bit", target_bits))
    slicer:start()
end

renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to 8-bit", invoke=function() convert_all_samples_to_bit_depth(8) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to 16-bit", invoke=function() convert_all_samples_to_bit_depth(16) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to 24-bit", invoke=function() convert_all_samples_to_bit_depth(24) end}
renoise.tool():add_keybinding{name="Sample Editor:Paketti:Convert All Samples to 32-bit", invoke=function() convert_all_samples_to_bit_depth(32) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to 8-bit", invoke=function() convert_all_samples_to_bit_depth(8) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to 16-bit", invoke=function() convert_all_samples_to_bit_depth(16) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to 24-bit", invoke=function() convert_all_samples_to_bit_depth(24) end}
renoise.tool():add_keybinding{name="Sample Keyzones:Paketti:Convert All Samples to 32-bit", invoke=function() convert_all_samples_to_bit_depth(32) end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert All Samples to 8-bit", invoke=function(message) if message:is_trigger() then convert_all_samples_to_bit_depth(8) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert All Samples to 16-bit", invoke=function(message) if message:is_trigger() then convert_all_samples_to_bit_depth(16) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert All Samples to 24-bit", invoke=function(message) if message:is_trigger() then convert_all_samples_to_bit_depth(24) end end}
renoise.tool():add_midi_mapping{name="Sample Editor:Paketti:Convert All Samples to 32-bit", invoke=function(message) if message:is_trigger() then convert_all_samples_to_bit_depth(32) end end}


-----
--[[----------------------------------------------------------------------------

Cross-fade Sample w/ Fade-In/Out
Averages your sample with its reversed copy,
then applies a 6-frame fade-in & fade-out.

----------------------------------------------------------------------------]]--

local function crossfade_with_fades()
  local song   = renoise.song()
  local sample = song.selected_sample
  if not sample then
    renoise.app():show_status("No sample selected!")
    return
  end

  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    renoise.app():show_status("Selected sample has no data!")
    return
  end

  local n_ch         = buffer.number_of_channels
  local n_fr         = buffer.number_of_frames
  local fade_frames  = 6
  local fade_range   = fade_frames - 1

  -- 1) Read entire buffer into Lua
  local orig = {}
  for ch = 1, n_ch do
    orig[ch] = {}
    for i = 1, n_fr do
      orig[ch][i] = buffer:sample_data(ch, i)
    end
  end

  -- 2) Prepare undo/redo & UI updates
  buffer:prepare_sample_data_changes()

  -- 3) Cross-fade + fades
  for ch = 1, n_ch do
    for i = 1, n_fr do
      -- cross-fade average
      local rev_i = n_fr - i + 1
      local avg   = (orig[ch][i] + orig[ch][rev_i]) * 0.5

      -- apply fade-in/fade-out envelope
      local factor = 1
      if i <= fade_frames then
        -- fade-in from 0 → 1 over fade_frames:
        factor = (i - 1) / fade_range
      elseif i > (n_fr - fade_frames) then
        -- fade-out from 1 → 0 over fade_frames:
        local k = i - (n_fr - fade_frames + 1)  -- 0..fade_range
        factor = 1 - (k / fade_range)
      end

      buffer:set_sample_data(ch, i, avg * factor)
    end
  end

  -- 4) Finalize changes
  buffer:finalize_sample_data_changes()
  renoise.app():show_status("Cross-fade + fades complete.")
end



--[[----------------------------------------------------------------------------

Cross‐fade Loop + Explicit Edge Fades (1‐sample‐fixed end)
1) Mirror‐average first/last 10% of loop
2) Pre‐loop fade‐out
3) Loop‐start fade‐in
4) Loop‐end fade‐out (fixed)

----------------------------------------------------------------------------]]--

local function crossfade_loop_edges_fixed_end()
  local song  = renoise.song()
  local instr = song.selected_instrument
  local idx   = song.selected_sample_index
  if not instr or idx < 1 then
    renoise.app():show_status("No sample selected!")
    return
  end
  local sample = instr.samples[idx]
  local ls, le = sample.loop_start, sample.loop_end
  if not ls or not le or le <= ls then
    renoise.app():show_status("Invalid loop region!")
    return
  end
  local buf = sample.sample_buffer
  if not buf.has_sample_data then
    renoise.app():show_status("Sample has no data!")
    return
  end

  local n_ch       = buf.number_of_channels
  local region_len = le - ls + 1
  local fade_len   = math.floor(region_len / 10)
  if fade_len < 1 or ls - fade_len < 1 then
    renoise.app():show_status("Loop too short or no pre‐loop space.")
    return
  end

  -- 1) Cache loop region
  local orig = {}
  for ch = 1, n_ch do
    orig[ch] = {}
    for i = 1, region_len do
      orig[ch][i] = buf:sample_data(ch, ls + i - 1)
    end
  end

  buf:prepare_sample_data_changes()

  -- 2) Mirror‐average first/last fade_len frames
  for ch = 1, n_ch do
    for i = 1, fade_len do
      local sp = ls + i - 1
      local ep = le - (i - 1)
      local avg = (orig[ch][i] + orig[ch][region_len - i + 1]) * 0.5
      buf:set_sample_data(ch, sp, avg)
      buf:set_sample_data(ch, ep, avg)
    end
  end

  -- 3) Pre‐loop fade‐out (before loop_start)
  for ch = 1, n_ch do
    for i = 1, fade_len do
      local pos = ls - fade_len + (i - 1)
      local env = (fade_len - i + 1) / fade_len
      local v   = buf:sample_data(ch, pos)
      buf:set_sample_data(ch, pos, v * env)
    end
  end

  -- 4) Loop‐start fade‐in (after loop_start)
  for ch = 1, n_ch do
    for i = 1, fade_len do
      local pos = ls + (i - 1)
      local env = i / fade_len
      local v   = buf:sample_data(ch, pos)
      buf:set_sample_data(ch, pos, v * env)
    end
  end

  -- 5) Loop‐end fade‐out (before loop_end), fixed off‐by‐one
  for ch = 1, n_ch do
    for i = 1, fade_len do
      local pos = (le - fade_len) + (i +1)     -- covers [le-fade_len .. le-1]
      local env = (fade_len - i + 1) / fade_len
      local v   = buf:sample_data(ch, pos)
      buf:set_sample_data(ch, pos, v * env)
    end
  end

  buf:finalize_sample_data_changes()
  renoise.app():show_status(
    ("Cross‐fade loop edges + fixed end‐fade complete (%d frames)."):format(fade_len)
  )
end


