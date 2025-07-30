--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- Akai S5000/S6000 AKP program support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function akp_is_valid_file(d)
  -- Checks to see if this is a valid AKP file type (0, 1 on error)
  if read_string_from_memory(d, 9, 4) == "APRG" then
    -- valid file
    return true
  else
    return false
  end
end


function akp_parse_kloc(d, start_pos, keygroups)
  -- Parses a KLOC chunk
  local low_note = read_byte_from_memory(d, start_pos + 12) - 12
  local high_note = read_byte_from_memory(d, start_pos + 13)- 12
  local semi_tune = byte_to_twos_compliment(read_byte_from_memory(d, start_pos + 14))
  local fine_tune = byte_to_twos_compliment(read_byte_from_memory(d, start_pos + 15))
  
  if low_note == nil then
    return keygroups
  elseif high_note == nil then
    return keygroups
  elseif semi_tune == nil then
    return keygroups
  elseif fine_tune == nil then
    return keygroups
  end
  
  -- import the midi data
  table.insert(keygroups, {low_note, high_note, semi_tune, fine_tune})
  
  return keygroups
end


function akp_parse_zone(d, start_pos, keygroup_index, keygroups)
  -- Parses a ZONE chunk
  local sample_name_len = read_byte_from_memory(d, start_pos + 9)
  local sample_name = read_string_from_memory(d, start_pos + 10, sample_name_len)
  local sample_min_vel = read_byte_from_memory(d, start_pos + 42)
  local sample_max_vel = read_byte_from_memory(d, start_pos + 43)
  local sample_fine_tune = byte_to_twos_compliment(read_byte_from_memory(d, start_pos + 44))
  local sample_semi_tune = byte_to_twos_compliment(read_byte_from_memory(d, start_pos + 45))
  
  local sample_pan = (byte_to_twos_compliment(read_byte_from_memory(d, start_pos+47)) / 100) +0.5
  
  
  if sample_name_len == nil then
    return keygroup_index, keygroups
  elseif sample_name == nil then
    return keygroup_index, keygroups
  elseif sample_min_vel == nil then
    return keygroup_index, keygroups
  elseif sample_max_vel == nil then
    return keygroup_index, keygroups
  elseif sample_semi_tune == nil then
    return keygroup_index, keygroups
  elseif sample_fine_tune == nil then
    return keygroup_index, keygroups
  end
  
  -- import sample data
  if keygroup_index > # keygroups then
    return keygroup_index, keygroups
  else
    table.insert(keygroups[keygroup_index], sample_name)
    table.insert(keygroups[keygroup_index], sample_semi_tune)
    table.insert(keygroups[keygroup_index], sample_fine_tune)
    table.insert(keygroups[keygroup_index], sample_min_vel)
    table.insert(keygroups[keygroup_index], sample_max_vel)
    table.insert(keygroups[keygroup_index], sample_pan)
  end
  
  return keygroup_index, keygroups
end


function akp_import(filename)
  -- main akp import function
  local inst_name = ""
  local inst_path = ""
  local instrument = renoise.song().selected_instrument
  local d         = ""
  local sample_path = ""
  local keygroup_index = 0
  local start_pos = 1
  local chunk_start = 1
  local working = true
  local keygroups   = {}
  local sample_count = 0
  local sliced_process

  if filename == nil then
    return false
  elseif filename == "" then
    return false
  end

  renoise.app():show_status("Importing Akai S5000/S6000 program...")

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
    renoise.app():show_status("Couldn't open Akai S5000/S6000 program file.")
    return false
  end

  -- check the validity of the file
  if not akp_is_valid_file(d) then
    renoise.app():show_error(filename .. " is not a valid Akai S5000/S6000 program file.")
    renoise.app():show_status(filename .. " is not a valid Akai S5000/S6000 program file.")
    d = ""
    return false
  end

  -- parse keygroups
  table.clear(keygroups)
  while working == true do
    chunk_start = d:find("kloc", start_pos)
    if chunk_start == nil then
      working = false
    else
      keygroups = akp_parse_kloc(d, chunk_start, keygroups)
      start_pos = chunk_start + 4
      keygroup_index = keygroup_index + 1
    end
    
    if working == true then
      -- zone 1 in group
      chunk_start = d:find("zone", start_pos)
      if chunk_start ~= nil then
        keygroup_index, keygroups = akp_parse_zone(d, chunk_start, keygroup_index, keygroups)
        start_pos = chunk_start + 4
      end
      -- zone 2 in group
      chunk_start = d:find("zone", start_pos)
      if chunk_start ~= nil then
        keygroup_index, keygroups = akp_parse_zone(d, chunk_start, keygroup_index, keygroups)
        start_pos = chunk_start + 4
      end
      -- zone 3 in group
      chunk_start = d:find("zone", start_pos)
      if chunk_start ~= nil then
        keygroup_index, keygroups = akp_parse_zone(d, chunk_start, keygroup_index, keygroups)
        start_pos = chunk_start + 4
      end
      -- zone 4 in group
      chunk_start = d:find("zone", start_pos)
      if chunk_start ~= nil then
        keygroup_index, keygroups = akp_parse_zone(d, chunk_start, keygroup_index, keygroups)
        start_pos = chunk_start + 4
      end
    end
  end
  
  d = ""

  for i = 1, #keygroups do
    if keygroups[i][5] ~= "" then
      sample_count = sample_count + 1
    end
    if keygroups[i][11] ~= "" then
      sample_count = sample_count + 1
    end
    if keygroups[i][17] ~= "" then
      sample_count = sample_count + 1
    end
    if keygroups[i][23] ~= "" then
      sample_count = sample_count + 1
    end
  end
  
  if sample_count > 254 then
    table.clear(keygroups)
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end
  
  -- get the path to the samples
  sample_path = get_samples_path(inst_name, inst_path, keygroups[1][5] .. ".wav")  
  
  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("Akai S5000/S6000 program import aborted.")
    return false
  end
  
  -- create the instrument  
  instrument:clear()
  instrument.name = inst_name
  
  sliced_process = ProcessSlicer(akp_import_samples, nil, instrument, sample_path, keygroups)
  sliced_process:start()
  
  return true
end
  
  
  
function akp_import_samples(instrument, sample_path, keygroups)
  local missing_samples = 0
  rprint(keygroups)
    -- main loop
  for i = 1, (#keygroups) do -- increase i for each keygroup
    for z = 1, 4 do          -- increase z for each zone
      if keygroups[i][6*z-1] ~= "" then
        dprint("akp_import_samples: loading keygroup ", i, " zone ", z)
          
        -- check file exists
        if io.exists(sample_path .. keygroups[i][6*z-1] .. ".wav") == false then
          missing_samples = missing_samples + 1
        else
          -- insert new sample
          local s = instrument:insert_sample_at(#instrument.samples)
            
          -- load wave file (& loop points in 2.7 beta 6+)
          if s.sample_buffer:load_from(sample_path .. keygroups[i][6*z-1] .. ".wav") == true then
            
            -- set sample name
            dprint("akp_import_samples: sample name:", keygroups[i][6*z-1])
            s.name = keygroups[i][6*z-1]
              
            -- set transpose
            local t = keygroups[i][3] + keygroups[i][(6*z)]
            if t < -127 then
              t = -127
            elseif t > 127 then
              t = 127
            end
            dprint("akp_import_samples: transpose:", t)
            s.transpose = t
              
            -- set finetune
            t = keygroups[i][4] + keygroups[i][(6*z)+1]
            if t < -127 then
              t = -127
            elseif t > 127 then
              t = 127
            end
            dprint("akp_import_samples: fine tune:", t)
            s.fine_tune = t
            
            dprint("akp_import_samples: panning:", keygroups[i][(6*z)+4])
            s.fine_tune = keygroups[i][(6*z)+4]
              
            dprint("akp_import_samples: volume: -6db")
            s.volume = math.db2lin(-6)
              
            -- set sample map
            dprint("akp_import_samples: sample id", #instrument.samples -1)
            dprint("akp_import_samples: low note", keygroups[i][1])
            dprint("akp_import_samples: high note", keygroups[i][2])
            dprint("akp_import_samples: low vel", keygroups[i][(6*z)+2])
            dprint("akp_import_samples: high vel", keygroups[i][(6*z)+3])
            
            if keygroups[i][1] == keygroups[i][2] then
              -- single work fugly workaround for basenote (v1.1+)
              instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                               #instrument.samples-1,  -- sample
                                               keygroups[i][1], --base note
                                               {keygroups[i][1],keygroups[i][2]}, -- note span
                                               {keygroups[i][(6*z)+2],keygroups[i][(6*z)+3]}) -- vel span
            else
              instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                               #instrument.samples-1,  -- sample
                                               wav_get_base_note_from_file(sample_path .. keygroups[i][6*z-1] .. ".wav"),
                                               {keygroups[i][1],keygroups[i][2]}, -- note span
                                               {keygroups[i][(6*z)+2],keygroups[i][(6*z)+3]}) -- vel span
            end
          end
        end
      else
        dprint("akp_import_samples: skipping blank keygroup ", i, " zone ", z)
      end
      renoise.app():show_status(string.format("Importing Akai S5000/S6000 program file (%d%% done)...",((i/#keygroups))*100))
      -- yield!
      coroutine.yield()
    end
  end
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing Akai S5000/S6000 program file complete.")
  else
    renoise.app():show_status(string.format("Importing Akai S5000/S6000 program partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end


--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
akp_integration = { category = "instrument",
                    extensions = {"akp"},
                    invoke = akp_import}            -- currently doesn't return anything

if renoise.tool():has_file_import_hook("instrument", {"akp"}) == false then
  renoise.tool():add_file_import_hook(akp_integration)
end
