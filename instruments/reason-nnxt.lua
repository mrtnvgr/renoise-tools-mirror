--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Reason NNXT SXT Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function nnxt_is_valid_file(d)
  -- Checks to see if this is a valid SXT file type (0, 1 on error)
  if read_string_from_memory(d, 9, 4) == "PTCH" then
    -- valid file
    return true
  else
    return false
  end
end


function nnxt_parse_refe(d, start_pos, samples)
  -- Parses a sample reference chunk
  local sample_filename
  local sample_filename_len
  
  sample_filename_len = read_byte_from_memory(d, start_pos + 30)
  
  -- validation checks
  if sample_filename_len == 0 then
    -- abort
    return samples
  end
  
  sample_filename = read_string_from_memory(d, start_pos + 31, sample_filename_len)
  
  -- validation checks
  if sample_filename == nil then
    return samples
  elseif sample_filename == "" then
    return samples
  end
  
  -- insert data
  table.insert(samples, {sample_filename})
  
  -- return update values
  return samples
end



function nnxt_parse_metadata(d, start_pos, metadata_index, samples)
  -- Parses sample metadata chunk
  local sample_low_note = read_byte_from_memory(d, start_pos)
  local sample_base_note = read_byte_from_memory(d, start_pos + 1)
  local sample_min_vel = read_byte_from_memory(d, start_pos + 2)
  local sample_max_vel = read_byte_from_memory(d, start_pos + 3)
  local sample_high_note = read_byte_from_memory(d, start_pos + 4)

  -- validation checks
  if sample_low_note == nil then
    return metadata_index, samples
  elseif sample_base_note == nil then
    return metadata_index, samples
  elseif sample_min_vel == nil then
    return metadata_index, samples
  elseif sample_max_vel == nil then
    return metadata_index, samples
  elseif sample_max_vel == nil then
    return metadata_index, samples
  elseif sample_high_note == nil then
    return metadata_index, samples
  end
  
  -- fix 'bug' in Renoise NNXT
  if sample_min_vel == 1 then
    sample_min_vel = 0
  end 
  
  -- increment index
  metadata_index = metadata_index + 1
  
  -- import sample data
  if metadata_index > #samples then
    return metadata_index, samples
  else
    table.insert(samples[metadata_index], sample_low_note)
    table.insert(samples[metadata_index], sample_high_note)
    table.insert(samples[metadata_index], sample_base_note)
    table.insert(samples[metadata_index], sample_min_vel)
    table.insert(samples[metadata_index], sample_max_vel)
  end

  -- return updated values
  return metadata_index, samples
end


function nnxt_import(filename)
  -- Main import function for SXT files
  local inst_name = ""
  local inst_path = ""
  local instrument = renoise.song().selected_instrument
  local d         = ""
  local sample_index = 0
  local start_pos = 1
  local chunk_start = 1
  local working = true
  local sample_path = ""
  local metadata_index = 0
  local samples   = {}
  local sliced_process    -- instance
  
  if filename == nil then
    return false
  elseif filename == "" then
    return false
  end

  renoise.app():show_status("Importing Reason NNXT patch...")

  -- little endian!
  lsb_first = true

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
    renoise.app():show_status("Couldn't open Reason NNXT patch file.")
    return false
  end

  -- check the validity of the file
  if not nnxt_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a valid Reason NNXT patch file.")
    renoise.app():show_status(filename .. " is not a valid Reason NNXT patch file.")
    d = ""
    return false
  end
  
  -- parse sample reference chunks (REFE)
  table.clear(samples)
  while working == true do
    chunk_start = d:find("REFE", start_pos)
    if chunk_start == nil then
      working = false
    else
      samples = nnxt_parse_refe(d, chunk_start, samples)
      start_pos = chunk_start + 4
      sample_index = sample_index + 1
    end
  end
  
  dprint("nnxt_import: parsed ",sample_index, "REFE chunks successfully")
  
  if sample_index > 254 then
    table.clear(samples)
    d = ""
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end

  -- move to end of REFE chunks
  local t = d:find("NNXT Digital Sampler")
  t = d:find("PARM")
  
  -- move to BODY chunk + offset to first sample metadata
  chunk_start = d:find("BODY", t)
  
  t = read_byte_from_memory(d, chunk_start + 14)
  -- ugly hackaround value
  chunk_start = chunk_start + 40 + t
  
  if chunk_start == nil then
    table.clear(samples)
    d = ""
    renoise.app():show_error(filename .. " is not a valid Reason NNXT patch file.")
    renoise.app():show_status(filename .. " is not a valid Reason NNXT patch file.")
    return false
  end
  
  -- parse sample metadata
  working = true
  while chunk_start < d:len() do
    metadata_index, samples = nnxt_parse_metadata(d, chunk_start, metadata_index, samples)
    if metadata_index == #samples then
      break
    end
    chunk_start = chunk_start + 241
  end
  
  -- clear memory
  d=""
  
  sample_path = get_samples_path(inst_name, inst_path, samples[1][1])
  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("Reason NNXT patch import aborted.")
    return false
  end

  -- create the instrument  
  instrument:clear()
  instrument.name = inst_name

  sliced_process = ProcessSlicer(nnxt_import_samples, nil, instrument, sample_path, samples)
  sliced_process:start()
  return true
end
  
  

function nnxt_import_samples(instrument, sample_path, samples)
  local missing_samples = 0
  
  -- main loop
  for i = 1, (#samples) do -- increase i for each sample       
    -- check file exists
    if io.exists(sample_path .. samples[i][1]) == false then
      dprint("nnxt_import_samples: wave file missing:", sample_path .. samples[i][1])
      missing_samples = missing_samples + 1
    else
      -- insert new sample
      local s = instrument:insert_sample_at(#instrument.samples)
     
      -- load wave file (& loop points in 2.7 beta 6+)
      if s.sample_buffer:load_from(sample_path .. samples[i][1]) == true then
        -- set sample name
        dprint("nnxt_import_samples: sample name:", samples[i][1])
        s.name = samples[i][1]
        s.volume = math.db2lin(0)
              
        -- set sample map
        dprint("nnxt_import_samples: low note", samples[i][2])
        dprint("nnxt_import_samples: high note", samples[i][3])
        dprint("nnxt_import_samples: base note", samples[i][4])
        dprint("nnxt_import_samples: low vel", samples[i][5])
        dprint("nnxt_import_samples: high vel", samples[i][6])
        instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                         #instrument.samples-1,  -- sample
                                         samples[i][4], -- base note
                                         {samples[i][2],samples[i][3]}, -- note span
                                         {samples[i][5],samples[i][6]}) -- vel span
      end
    end
    renoise.app():show_status(string.format("Importing Reason NNXT patch (%d%% done)...",((i/#samples))*100))
    -- yield!
    coroutine.yield()
  end
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing Reason NNXT patch complete.")
  else
    renoise.app():show_status(string.format("Importing Reason NNXT patch partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
sxt_integration = { category = "instrument",
                    extensions = {"sxt"},
                    invoke = nnxt_import}           -- currently doesn't return anything

if renoise.tool():has_file_import_hook("instrument", {"sxt"}) == false then
  renoise.tool():add_file_import_hook(sxt_integration)
end
