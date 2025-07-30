--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai S1000/S3000 .p instrument file support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "samples/akai-s1000s"


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function s1000_loadinstrument(filename)
  -- Main import function for .p files
  local d = ""
  local instrument = renoise.song().selected_instrument
  local inst_name = ""
  local inst_path = ""
  local samples = {}
  local sample_path
  local sliced_process

  renoise.app():show_status("Importing Akai S1000 Program...")

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
    renoise.app():show_status("Couldn't open Akai S1000 program file.")
    return false
  end

  -- check the validity of the file
  if read_byte_from_memory(d,1) ~= 1 then
    renoise.app():show_error(filename .. " is not a valid Akai S1000 program file.")
    renoise.app():show_status(filename .. " is not a valid Akai S1000 program file.")
    d = ""
    return false
  end
  
  dprint("s1000_loadinstrument: inst_name", inst_name)
  
  -- parse sample chunks
  for chunk_start=150, ((d:len()/150)-1)*150, 150 do
    dprint("s1000_loadinstrument: chunk_start", chunk_start)
    
    local zone_key_lo = read_byte_from_memory(d, chunk_start + 4)
    local zone_key_hi = read_byte_from_memory(d, chunk_start + 5)
    local zone_transpose = byte_to_twos_compliment(read_byte_from_memory(d, chunk_start + 6))
    local zone_finetune = byte_to_twos_compliment(read_byte_from_memory(d, chunk_start + 7))
    
    for sample_offset = 35,103,34 do
      local vel_lo = read_byte_from_memory(d, chunk_start + sample_offset + 12)
      local vel_hi = read_byte_from_memory(d, chunk_start + sample_offset + 13)
      local transpose = zone_transpose +
                        byte_to_twos_compliment(read_byte_from_memory(d, chunk_start + sample_offset + 15))
      local finetune = zone_finetune +
                       byte_to_twos_compliment(read_byte_from_memory(d, chunk_start + sample_offset + 14))
      local sample_name = ""
      print(d:sub(chunk_start+sample_offset, chunk_start+sample_offset))
      if d:sub(chunk_start+sample_offset, chunk_start+sample_offset):byte() ~= 10 then
        if d:sub(chunk_start+sample_offset, chunk_start+sample_offset):byte() ~= 0 then
          sample_name = akaii_to_ascii(d:sub(chunk_start+sample_offset, chunk_start+sample_offset+11))
          -- strip off trailing whitespace
          while sample_name:sub(sample_name:len(), sample_name:len()) == " " do
            sample_name = sample_name:sub(1, sample_name:len()-1)
          end
          sample_name = sample_name .. ".s"
          -- add into table
          table.insert(samples, {sample_name, zone_key_lo, zone_key_hi, vel_lo, vel_hi, transpose, finetune})
        end
      end
    end
  end

  dprint("s1000_loadinstrument: parsed ",#samples, "sample chunks successfully")


  if #samples > 254 then
    table.clear(samples)
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end
  

  -- get samples location
  sample_path = get_samples_path(inst_name, inst_path, samples[1][1])  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("Akai S1000 program import aborted.")
    return false
  end
  
  -- read AKAII instrument name
  inst_name = akaii_to_ascii(d:sub(4,15))
  
  d = ""
  
  -- prep instrument
  instrument:clear()
  instrument.name = inst_name

  -- load samples
  sliced_process = ProcessSlicer(s1000_loadinstrument_samples, nil, instrument, sample_path, samples)
  sliced_process:start()
  return true
end


function s1000_loadinstrument_samples(instrument, sample_path, samples)
  rprint(samples)
  
  -- iterate over and load samples
  local missing_samples = 0

  for i = 1, #samples do
    -- check file exists
    if io.exists(sample_path .. samples[i][1]) == false then
      -- try with -L.s ending  (ugly workaround)
      samples[i][1] = samples[i][1]:gsub("-l.s", "-L.s", 1)
    end
    if io.exists(sample_path .. samples[i][1]) == false then 
      dprint("s1000_loadinstrument_samples: missing sample=", sample_path .. samples[i][1])
      missing_samples = missing_samples + 1
    else
    -- insert new sample
    local s = instrument:insert_sample_at(#instrument.samples)
              
    -- load wave file (& loop points in 2.7 beta 6+)
    if s1000_loadsample(sample_path .. samples[i][1], s) == true then
      -- set parameters
          
      -- range checks notespans
      local t = samples[i][2]
      if t < 0 then
        t = 0
      elseif t > 119 then
        t = 119
      end
      samples[i][2] = t
      t = samples[i][3]
      if t < 0 then
        t = 0
      elseif t > 119 then
        t = 119
      end
      samples[i][3] = t
      
      -- set transpose
      t = samples[i][6]
      if t < -127 then
        t = -127
      elseif t > 127 then
        t = 127
      end
      s.transpose = t
                
      -- set finetune
      t = samples[i][7]
      if t < -127 then
        t = -127
      elseif t > 127 then
        t = 127
      end
      s.fine_tune = t
          
      -- volume
      s.volume = math.db2lin(-3)
  
      -- create sample mapping
      local base_note = s1000_get_basenote_from_sample(sample_path .. samples[i][1])
          
      if base_note ~= nil then
        instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                         #instrument.samples-1,  -- sample
                                         base_note, --basenote (from .s sample)
                                         {samples[i][2],samples[i][3]}, -- note span
                                         {samples[i][4],samples[i][5]}) -- vel span
      else
        instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                         #instrument.samples-1,  -- sample
                                         60, --basenote fallback
                                         {samples[i][2],samples[i][3]}, -- note span
                                         {samples[i][4],samples[i][5]}) -- vel span
      end
    end
  end  
  renoise.app():show_status(string.format("Importing Akai S1000 program file (%d%% done)...",((i/#samples))*100))
    -- yield!
    coroutine.yield()
  end
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing Akai S1000 program complete.")
  else
    renoise.app():show_status(string.format("Importing Akai S1000 program partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end

--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
function p_integration_func(filename)
  s1000_loadinstrument(filename)
  return true
end

p_integration = { category = "instrument",
                  extensions = {"p"},
                  invoke = p_integration_func}  -- returns true

if renoise.tool():has_file_import_hook("instrument", {"p"}) == false then
  renoise.tool():add_file_import_hook(p_integration)
end
