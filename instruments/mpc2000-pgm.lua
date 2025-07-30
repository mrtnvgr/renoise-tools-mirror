--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai MPC2000 PGM Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "samples/mpc2000-snd"


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function pgm2000_is_valid_file(d)
  -- Checks to see if this is a valid pgm file type (0, 1 on error)
  if read_word_from_memory(d, 1) == 1031 then
    return true
  else
    return false
  end
end


function pgm2000_import(filename)
  local inst_name = ""
  local inst_path = ""
  local sample_path = ""
  local sample_count = 0
  local n=""
  local p=0
  local d=""
  local s = ""
  local samples   = {}    -- imported sample data
  local instrument
  local midimap   = {}    -- imported zone metadata
  local sliced_process
  
  instrument = renoise.song().selected_instrument

  -- little endian!
  lsb_first = true

  -- Main import function for exs files
  if filename == nil then
    return false
  elseif filename == "" then
    return false
  end

  renoise.app():show_status("Importing Akai MPC2000/XL program...")

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
    renoise.app():show_error("Couldn't open Akai MPC2000/XL program.")
    renoise.app():show_status("Couldn't open Akai MPC2000/XL program.")
    return false
  end

  -- check the validity of the file
  if not pgm2000_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a supported Akai MPC2000/XL program.  Sorry.")
    renoise.app():show_status(filename .. " is not a supported Akai MPC2000/XL program.  Sorry.")
    d = ""
    return false
  end

  
  -- parse samples
  table.clear(samples)
  
  sample_count = read_word_from_memory(d,3)

  if sample_count > 254 then
    -- this should never fire!  MPC should limit to 64 samples!
    d = ""
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end

  for i = 1, sample_count do
    dprint("pgm2000_import: read sample name starting at:", (i*17)-12)
    n = read_string_from_memory(d, (i*17)-12, 16)
    if n:sub(1,1) ~= string.char(0) then
      p = string.find(n, " ")
      if p ~= nil then
        n = n:sub(1, p-1)
      end
      table.insert(samples, n)  --note no file extension
    else
      dprint("pgm2000_import: ignoring this samplename as it's invalid")
    end 
  end

  -- parse midi map
  table.clear(midimap)
  for i = 1, 63 do    -- midi map from midi notes 35 to 98
    dprint("pgm2000_import: read midi map for key:", i+34)
    n = read_byte_from_memory(d, (i*25)+150) + 1 -- for samples[] indexing
    if n == 256 then
      n = 0  -- empty
    end
    dprint("pgm2000_import: assigned sample: ",n)
    table.insert(midimap, n)
  end
  

  d=""
  
  -- get the path to the samples
  sample_path = get_samples_path(inst_name, inst_path, samples[1] .. ".snd")  
  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("Akai MPC2000/XL program import aborted.")
    table.clear(samples)
    table.clear(midimap)
    return false
  end
  
  
  -- make an instrument
  instrument:clear()
  instrument.name = inst_name
  
  -- start sliced sample loader
  sliced_process = ProcessSlicer(pgm2000_import_samples, nil, instrument, sample_path, samples, midimap)
  sliced_process:start()
  
  return true
end


function pgm2000_import_samples(instrument, sample_path, samples, midimap)
  local missing_samples = 0
  local i
  local s

  dprint("pgm2000_import_samples: instrument=", instrument)
  dprint("pgm2000_import_samples: sample_path=", sample_path)
  dprint(samples)
  dprint(midimap)

  -- load samples
  for i = 1, #samples do
    s = instrument:insert_sample_at(#instrument.samples)
    if s ~= nil then
      if io.exists(sample_path .. samples[i] .. ".snd") then
        mpc2000_loadsample(sample_path .. samples[i] .. ".snd", s)
      else
        missing_samples = missing_samples + 1
      end
    end
    renoise.app():show_status(string.format("Importing Akai MPC2000/XL program... (%d%% done)", i/#samples * 100))
    -- yield!
    coroutine.yield()
  end
  
  -- start at index 1 and increase
  local current_sample_id = 0
  local current_sample_start = 0
    
  for i = 1, #midimap do
    if midimap[i] ~= current_sample_id then
      -- end of zone, add it!
      if current_sample_id ~= 0 then
        if current_sample_id <= #instrument.samples then
          instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                           current_sample_id,  -- sample
                                           34 + current_sample_start, -- base note
                                           {34 + current_sample_start,34+i-1}, -- note span
                                           {0,127}) -- vel span
        end
      end
      -- update local cache
      current_sample_id = midimap[i]
      current_sample_start = i
      dprint("pgm2000_import: midimap sample =", current_sample_id)
      dprint("pgm2000_import: midimap range = ", 34 + current_sample_start, "to", 34+i-1)
    end  
  end
    
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
end



--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
-- n/a - see mpcCommon-pgm.lua
