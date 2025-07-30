--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Korg Triton KMP Multisample Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function kmp_is_valid_file(d)
  -- Checks to see if this is a valid kmp file type (0, 1 on error)
  if read_string_from_memory(d, 1, 4) == "MSP1" then
    -- valid file
    return true
  else
    return false
  end
end




function kmp_import(filename)
  -- Main import function for kmp files
  local d = ""
  local running = true
  local instrument = renoise.song().selected_instrument
  local inst_name = ""
  local inst_path = ""
  local chunk_start = 0
  local chunk_count = 0
  local samples = {}
  local sample_path
  local sliced_process

  renoise.app():show_status("Importing Korg Triton multisample...")

  lsb_first = false

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
    renoise.app():show_status("Couldn't open Korg Triton multisample file.")
    return false
  end

  -- check the validity of the file
  if not kmp_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a valid Korg Triton multisample file.")
    renoise.app():show_status(filename .. " is not a valid Korg Triton multisample file.")
    d = ""
    return false
  end
  
  -- parse sample chunks
  table.clear(samples)
  chunk_start = d:find("RLP1")
  chunk_count = read_dword_from_memory(d, chunk_start+4) / 18
  
  
  dprint("kmp_import reading from offset", chunk_start, "chunks=", chunk_count)
  
  for i = 1, chunk_count do
    table.insert(samples, {read_string_from_memory(d, chunk_start-18+(i*18)+14, 12),
                           bit.band(read_byte_from_memory(d, chunk_start-18+(i*18)+8)-12,
                                    0x7F),    -- start note (1oct offset)
                           read_byte_from_memory(d, chunk_start-18+(i*18)+9)-12,    -- end note
                           byte_to_twos_compliment(read_byte_from_memory(d, chunk_start-18+(i*18)+10))}) --fine tune
  end

  dprint("kmp_import: parsed ",#samples, "sample chunks successfully")

  d = ""

  if #samples > 254 then
    table.clear(samples)
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end
  

  -- get samples location
  d=1
  running = true
  while d < #samples do
    if samples[d][1] == "SKIPPEDSAMPL" then
      d=d+1
    elseif string.sub(samples[d][1],1,8) == "INTERNAL" then
      d=d+1
    else
      break
    end
  end
  
  if d == #samples then
    if #samples ~= 1 then
      --abort
      d=""
      table.clear(samples)
      return false
    end
  end
  
  -- prep instrument
  instrument:clear()
  instrument.name = inst_name
  
  dprint("kmp_import: inst_name", inst_name)
  dprint("kmp_import: inst_path", inst_path)
  dprint("kmp_import: inst_path", samples[d][1])
  
  sample_path = get_samples_path(inst_name, inst_path, samples[d][1])  
  
  -- load samples
  sliced_process = ProcessSlicer(kmp_import_samples, nil, instrument, sample_path, samples)
  sliced_process:start()
  
  return true
end
  
  
function kmp_import_samples(instrument, sample_path, samples)
  -- sliced sample loading function
  local missing_samples = 0
  local last_high_note = 12
  
  for i = 1, #samples do
    if samples[i][1] == "SKIPPEDSAMPL" then
      -- do nothing (skip)
    elseif string.sub(samples[i][1],1,8) == "INTERNAL" then
      missing_samples = missing_samples + 1 -- we don't have the rom samples
    else
      if io.exists(sample_path .. samples[i][1]) == false then
        missing_samples = missing_samples + 1
      else
        -- load sample
        local s = instrument:insert_sample_at(#instrument.samples)
        ksf_loadsample(sample_path .. samples[i][1], s)
        
        -- set parameters
        s.fine_tune = samples[i][4]
        
        -- set mapping
        instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                         #instrument.samples-1,               -- sample
                                         math.min(119,
                                                  math.max(0,samples[i][2])), -- base note
                                         {last_high_note,
                                          math.min(119,samples[i][3])}, -- note span
                                         {0,127})                       -- vel span
        last_high_note = math.min(119,samples[i][3]) +1
      end
    end
      renoise.app():show_status(string.format("Importing Korg Triton multisample file (%d%% done)...",((i/#samples))*100))
      -- yield!
      coroutine.yield()
  end
  
  
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing Korg Triton multisample file complete.")
  else
    renoise.app():show_status(string.format("Importing Korg Triton multisample partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
kmp_integration = { category = "instrument",
                    extensions = {"kmp"},
                    invoke = kmp_import}       

if renoise.tool():has_file_import_hook("instrument", {"kmp"}) == false then
  renoise.tool():add_file_import_hook(kmp_integration)
end
