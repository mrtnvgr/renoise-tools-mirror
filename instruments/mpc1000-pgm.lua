--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai MPC1000 PGM Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function pgm1000_is_valid_file(d)
  -- Checks to see if this is a valid pgm file type (0, 1 on error)
  if read_word_from_memory(d, 1) == 10756 then  --10756
    return true
  else
    return false
  end
end


function pgm1000_import(filename)
  local instrument = renoise.song().selected_instrument
  local inst_name = ""
  local inst_path = ""
  local sample_path = ""
  local samples = {}
  local midimap = {}
  local n1=""
  local n2=""
  local n3=""
  local n4=""
  local t1=0
  local t2=0
  local t3=0
  local t4=0
  local p=0
  local d=""
  local s = ""
  local sliced_process

  -- little endian!
  lsb_first = true

  -- Main import function for exs files
  if filename == nil then
    return false
  elseif filename == "" then
    return false
  end

  renoise.app():show_status("Importing Akai MPC1000 program...")

  -- extract the instrument path/name
  inst_path, inst_name = split_filename(filename)

  if inst_path == "" then
    return false
  elseif inst_name == "" then
    return false
  end  

  -- load the file into memory
  d = load_file_to_memory(filename)  
  
  if d == "" then
    renoise.app():show_error("Couldn't open Akai MPC1000 program.")
    renoise.app():show_status("Couldn't open Akai MPC1000 program.")
    return false
  end

  -- check the validity of the file
  if not pgm1000_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a supported Akai MPC1000 program.  Sorry.")
    renoise.app():show_status(filename .. " is not a supported Akai MPC1000 program.  Sorry.")
    d = ""
    return false
  end

  
  -- parse samples from pads
  table.clear(samples)  
  for pad = 0, 63 do
    -- unrolled loop
    n1 =read_string_from_memory(d, (pad*164)+25, 16)
    if n1:sub(1,1) ~= string.char(0) then
      p = string.find(n1, " ")
      if p ~= nil then
        n1 = n1:sub(1, p-1)
      end
      p = string.find(n1, string.char(0))
      if p ~= nil then
        n1 = n1:sub(1, p-1)
      end
      t1 = word_to_twos_compliment(read_word_from_memory(d, (pad*164)+20+25, 16))
    else
      n1 = ""
      t1 = 0
    end
    n2 =read_string_from_memory(d, (pad*164)+24+25, 16)
    if n2:sub(1,1) ~= string.char(0) then
      p = string.find(n2, " ")
      if p ~= nil then
        n2 = n2:sub(1, p-1)
      end
      p = string.find(n2, string.char(0))
      if p ~= nil then
        n2 = n2:sub(1, p-1)
      end
      t2 = word_to_twos_compliment(read_word_from_memory(d, (pad*164)+44+25, 16))
    else
      n2 = ""
      t2 = 0
    end
    n3 =read_string_from_memory(d, (pad*164)+48+25, 16)
    if n3:sub(1,1) ~= string.char(0) then
      p = string.find(n3, " ")
      if p ~= nil then
        n3 = n3:sub(1, p-1)
      end
      p = string.find(n3, string.char(0))
      if p ~= nil then
        n3 = n3:sub(1, p-1)
      end
      t3 = word_to_twos_compliment(read_word_from_memory(d, (pad*164)+68+25, 16))
    else
      n3 = ""
      t3 = 0
    end
    n4 =read_string_from_memory(d, (pad*164)+72+25, 16)
    if n4:sub(1,1) ~= string.char(0) then
      p = string.find(n4, " ")
      if p ~= nil then
        n4 = n4:sub(1, p-1)
      end
      p = string.find(n4, string.char(0))
      if p ~= nil then
        n4 = n4:sub(1, p-1)
      end
      t4 = word_to_twos_compliment(read_word_from_memory(d, (pad*164)+92+25, 16))
    else
      n4 = ""
      t4 = 0
    end
    
    table.insert(samples, {n1, t1, n2, t2, n3, t3, n4, t4})
    -- TODO: read out pan / volume from 'pad' data
  end

  -- parse midi map
  table.clear(midimap)
  for i = 0, 127 do    -- midi map from midi notes 35 to 98
    n1 = read_byte_from_memory(d, (i)+10585) + 1 -- for samples[] indexing
    -- n = 65 = not mapped
    table.insert(midimap, n1)
  end
  
  d=""
  
  -- get the path to the samples
  sample_path = get_samples_path(inst_name, inst_path, samples[1][1] .. ".wav")  
  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("Akai MPC1000 program import aborted.")
    table.clear(samples)
    table.clear(midimap)
    return false
  end  
  
  -- make an instrument
  instrument:clear()
  instrument.name = inst_name


  sliced_process = ProcessSlicer(pgm1000_import_samples, nil, instrument, samples, sample_path, midimap)
  sliced_process:start()

  return true
end


function pgm1000_import_samples(instrument, samples, sample_path, midimap)
  -- sliced loading function
  local sample_start = 0
  local in_range = false
  local missing_samples = 0
  local s
  local i = 0
  
  -- load pads
  for pad = 1, 64 do
    if samples[pad][1] ~= "" then
      dprint("pgm1000_import_samples:loading pad", pad)
      for sample_slot = 1, 4 do
        -- load samples
        if samples[pad][(sample_slot*2)-1] ~= "" then
          if io.exists(sample_path .. samples[pad][(sample_slot*2)-1] .. ".wav") == false then
            missing_samples = missing_samples + 1
          else
            s = instrument:insert_sample_at(#instrument.samples)
            if s.sample_buffer:load_from(sample_path .. samples[pad][(sample_slot*2)-1] .. ".wav") == true then
              -- successfully loaded sample
              s.name = samples[pad][(sample_slot*2)-1]
              s.volume = math.db2lin(-3)
              
              dprint("tuning for pad", pad, "sample", sample_slot, "is", samples[pad][(sample_slot*2)])
              s.transpose = (samples[pad][(sample_slot*2)])/100
              
              -- set midi zones
              sample_start = 0
              in_range = false
              i = 0
              while true do
                if midimap[i] == pad then
                  if in_range == false then
                    -- update start
                    sample_start = i
                    in_range = true
                  end
                else
                  -- end of map
                  if in_range == true then
                    -- end of range, insert
                    dprint("range for pad", pad, "is", sample_start, "to", i-1)
                    in_range = false
                    instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                                     #instrument.samples-1,
                                                     sample_start, --basenote --TODO!
                                                     {sample_start, i-1}, --notes
                                                     {0,127}) -- vel
                  end
                end
                if i == 64 then
                  break
                end  
                i = i + 1            
              end
            end
          end
        end
      end
    else
      dprint("pgm1000_import_samples:skipping samples loading for pad", pad)
    end
    renoise.app():show_status(string.format("Importing MPC1000 program (%d%% done)...",((pad/64))*100))
    -- yield!
    coroutine.yield()
  end

  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing MPC1000 program complete.")
  else
    renoise.app():show_status(string.format("Importing MPC1000 program partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
-- n/a - see mpcCommon-pgm.lua
