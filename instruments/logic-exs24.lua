--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Logic EXS24 Sampler EXS Support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function exs_is_valid_file(d)
  -- Checks to see if this is a valid exs file type (0, 1 on error)
  local retval = false
  if read_byte_from_memory(d, 4) == 0 then
    -- valid file, set endianness and magic header values
    if read_byte_from_memory(d, 1) == 1 then
      dprint("exs_is_valid_file: little endian (TBOS), magic potion cast")
      lsb_first = true
      return string.char(01,01,00,01), string.char(01,01,00,03)
    elseif read_byte_from_memory(d, 1) == 0 then
      dprint("exs_is_valid_file: big endian (SOBT), magic potion cast")
      lsb_first = false
      return string.char(00,01,00,01), string.char(00,01,00,03)
    else
      return "",""
    end
  end
  return "",""
end


function exs_parse_sample_chunk(d, start_pos, samples)
  -- Parses a sample chunk
  local p = d:find(string.char(0), start_pos+20)
  table.insert(samples, d:sub(start_pos+20, p)) 
  return samples
end


function exs_parse_zone_chunk(d, start_pos, zones)
  -- parses a zone chunk
  local zone_rootnote  = read_byte_from_memory(d, start_pos+85)  -- two octave difference?
  local zone_startnote  = read_byte_from_memory(d, start_pos+90) 
  local zone_endnote    = read_byte_from_memory(d, start_pos+91)
  local zone_minvel     = read_byte_from_memory(d, start_pos+93)
  local zone_maxvel     = read_byte_from_memory(d, start_pos+94)
  --local zone_loop_start = read_dword_from_memory(d, start_pos+104)
  --local zone_loop_end   = read_dword_from_memory(d, start_pos+ 108)
  local sample_ref      = read_dword_from_memory(d, start_pos+176) + 1 -- zero indexed
  local zone_finetune   = byte_to_twos_compliment(read_byte_from_memory(d, start_pos+86))
  local zone_pan        = (byte_to_twos_compliment(read_byte_from_memory(d, start_pos+87)) / 200) +0.5

  if zone_rootnote < 0 then
    dprint("exs_parse_zone_chunk: clamping rootnote to 0+")
    zone_rootnote = 0
  end
  
  if zone_startnote < 0 then
    dprint("exs_parse_zone_chunk: clamping startnote to 0+")
    zone_startnote = 0
  end
    
  if zone_endnote > 119 then
    dprint("exs_parse_zone_chunk: clamping endnote to <120")
    zone_endnote = 119
  end
  
  -- import zone data
  table.insert(zones, {sample_ref, zone_rootnote, zone_startnote,
                       zone_endnote, zone_minvel, zone_maxvel,
                       zone_finetune, zone_pan})
  
  return zones
end


function exs_import(filename)
  local inst_path = ""
  local inst_name = ""
  local sample_path = ""
  local instrument = renoise.song().selected_instrument
  local d         = ""
  local samples   = {}
  local zones     = {}
  local magic_zone = ""
  local magic_sample = ""
  
  local sliced_process

  -- Main import function for exs files
  if filename == nil then
    return
  elseif filename == "" then
    return
  end

  renoise.app():show_status("Importing Logic EXS patch...")

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
    renoise.app():show_error("Couldn't open Logic EXS patch.")
    renoise.app():show_status("Couldn't open Logic EXS patch.")
    return false
  end
  
  -- check the validity of the file
  magic_zone, magic_sample = exs_is_valid_file(d)
  
  if magic_zone == "" then
    renoise.app():show_error(filename .. " is not a supported Logic EXS patch type.  Sorry.")
    renoise.app():show_status(filename .. " is not a supported Logic EXS patch type.  Sorry.")
    d = ""
    return false
  end 

  -- parse zone chunks
  table.clear(zones)
  local start_pos = 1
  local chunk_start = 1
  local working = true
  while working == true do
    chunk_start = d:find(magic_zone, start_pos)
    if chunk_start == nil then
      working = false
    else
      zones = exs_parse_zone_chunk(d, chunk_start, zones)
      start_pos = chunk_start + 4
    end
  end
  
  -- TODO: should this be #samples?
  if #zones > 254 then
    table.clear(zones)
    d = ""
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end
  
  if #zones == 0 then
    -- abort
    renoise.app():show_status("Logic EXS patch import found no zone references.")
    d = ""
    table.clear(zones)
    return false
  end
  
  -- parse sample chunks
  table.clear(samples)
  start_pos = chunk_start -- end of zone chunks
  chunk_start = 1
  working = true
  while working == true do
    chunk_start = d:find(magic_sample, start_pos)
    if chunk_start == nil then
      working = false
    else
      samples = exs_parse_sample_chunk(d, chunk_start, samples)
      start_pos = chunk_start + 4
    end
  end

  d = ""
  
  if #samples == 0 then
    -- abort
    renoise.app():show_status("Logic EXS patch import found no sample references.")
    d = ""
    table.clear(samples)
    table.clear(zones)
    return false
  end
  
  -- get the path to the samples
  sample_path = get_samples_path(inst_name, inst_path, samples[1])  
  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_error("Logic EXS patch import aborted.")
    renoise.app():show_status("Logic EXS patch import aborted.")
    d = ""
    table.clear(samples)
    table.clear(zones)
    return false
  end
  
  -- create the instrument  
  instrument:clear()
  instrument.name = inst_name

  sliced_process = ProcessSlicer(exs_import_samples, nil, instrument, sample_path, zones, samples)
  sliced_process:start()
  
  return true
end
  

function exs_import_samples(instrument, sample_path, zones, samples)
  local missing_samples = 0
  -- main loop
  for i = 1, (#zones) do -- increase i for each zone
    if samples[zones[i][1]] ~= nil then
      -- check file exists
      if io.exists(sample_path .. samples[zones[i][1]]) == false then
        missing_samples = missing_samples + 1
      else
        -- insert new sample
        local s = instrument:insert_sample_at(#instrument.samples)
         
        -- load wave file (& loop points in 2.7 beta 6+)
        if s.sample_buffer:load_from(sample_path .. samples[zones[i][1]]) == true then
        
          -- set sample name
          dprint("exs_import_samples: sample name:",  samples[zones[i][1]])
          s.name = samples[zones[i][1]]
            
          dprint("exs_import_samples: volume: 0db")
          s.volume = math.db2lin(0)
          
          dprint("exs_import_samples: finetune", zones[i][7])
          s.fine_tune = zones[i][7]
          
          dprint("exs_import_samples: panning", zones[i][8])
          s.panning = zones[i][8]
             
          -- set sample map
          dprint("exs_import_samples: sample id", #instrument.samples -1)
          dprint("exs_import_samples: base note", zones[i][2])
          dprint("exs_import_samples: low note", zones[i][3])
          dprint("exs_import_samples: high note", zones[i][4])
          dprint("exs_import_samples: low vel", zones[i][5])
          dprint("exs_import_samples: high vel", zones[i][6])
          instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                           #instrument.samples-1,  -- sample
                                           zones[i][2],
                                           {math.min(119,
                                                     math.max(0, zones[i][3])),
                                            math.min(119, zones[i][4])}, -- note span
                                           {zones[i][5],zones[i][6]}) -- vel span
        end
      end
    renoise.app():show_status(string.format("Importing Logic EXS patch (%d%% done)...",((i/#zones))*100))
    -- yield!
    coroutine.yield()
    end
  end
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing Logic EXS patch complete.")
  else
    renoise.app():show_status(string.format("Importing Logic EXS patch partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
exs_integration = { category = "instrument",
                    extensions = {"exs"},
                    invoke = exs_import}            -- currently doesn't return anything

if renoise.tool():has_file_import_hook("instrument", {"exs"}) == false then
  renoise.tool():add_file_import_hook(exs_integration)
end
