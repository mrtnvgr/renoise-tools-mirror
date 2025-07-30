--------------------------------------------------------------------------------
-- Additional File Format Support for Renoise
--
-- Copyright 2011 Martin Bealby (mbealby@gmail.com)
--
-- RGC:Audio SFZ program support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function sfz_note_name_to_number(name_string)
  local notes = "c d ef g a b"
  local note = notes:find(name_string:sub(1,1):lower()) - 1  --c=0
  local o = 0
  
  if tonumber(name_string:sub(2,2)) ~= nil then
    -- white note
    print(name_string:sub(2,2))
    o = tonumber(name_string:sub(2,2))
  else
    if tonumber(name_string:sub(3,3)) ~= nil then
      -- black note
      print(name_string:sub(3,3))
      o = tonumber(name_string:sub(3,3))
      if name_string:sub(2,2):lower() == "b" then
        note = note - 1
      elseif name_string:sub(2,2) == "#" then
        note = note + 1
      end
    else
      return nil
    end
  end

  dprint("sfz_note_name_to_number: string", name_string, "note", note, "octave", o)
  return (o*12)+note
end



function sfz_import(filename)

  -- main akp import function
  local inst_name = ""
  local inst_path = ""
  local instrument = renoise.song().selected_instrument
  local line = ""
  local word = ""
  local parse_table = {}
  local t = ""
  local region_count = 0
  
  -- sample parameters
  local sample = ""
  local lokey = 12
  local hikey = 0
  local lovel = 0
  local hivel = 127
  local basenote = 0
  local transpose = 0
  local tune = 0
  local volume = math.db2lin(0)
  local pan = 0.5
  
  local keymaps = {} 
  local sample_path = ""
  local sliced_process

  if filename == nil then
    return false
  elseif filename == "" then
    return false
  end

  renoise.app():show_status("Importing SFZ instrument...")

  -- extract the instrument path/name
  inst_path, inst_name = split_filename(filename)

  if inst_path == "" then
    return false
  elseif inst_name == "" then
    return false
  end  

  -- open file
  for line in io.lines(filename) do
    -- strip comments to end of line
    if line:find("//") then
      line = line:sub(1, line:find("//")-1)
    end
    
    -- remove redundant CR on unix systems
    local cr_replaced = 0
    line, cr_replaced = line:gsub(string.char(13), "")
    
    -- convert "\" to "/"
    line = line:gsub("\\", "/")
    
    for word in line:gmatch("([^%z =]+)") do
      -- insert in parse table
      table.insert(parse_table, word)
    end
  end
  
  for t=1, #parse_table do
    --TODO: other commands
    if parse_table[t] == "<region>" then
      if sample ~= "" then
        -- add read in region
        table.insert(keymaps, {sample, basenote, lokey, hikey, lovel, hivel, transpose, tune, volume, pan})
        sample=""
      end
    elseif parse_table[t] == "sample" then
      local i=1
      while sample:find(".") == nil do
        sample = sample .. parse_table[t+i] .. " "
        i=i+1
      end
      sample = sample:sub(1,-2) --remove " " from end
    elseif parse_table[t] == "lokey" then
      if tonumber(parse_table[t+1]) == nil then
        lokey = sfz_note_name_to_number(parse_table[t+1])
      else
        lokey = tonumber(parse_table[t+1]) - 12
      end
    elseif parse_table[t] == "hikey" then
      if tonumber(parse_table[t+1]) == nil then
        hikey = sfz_note_name_to_number(parse_table[t+1])
      else
        hikey = tonumber(parse_table[t+1]) - 12
      end
    elseif parse_table[t] == "lovel" then
      lovel = tonumber(parse_table[t+1])
    elseif parse_table[t] == "hivel" then
      hivel = tonumber(parse_table[t+1])
    elseif parse_table[t] == "tune" then
      tune = tonumber(parse_table[t+1])
    elseif parse_table[t] == "transpose" then
      transpose = tonumber(parse_table[t+1])
    elseif parse_table[t] == "volume" then
      volume = tonumber(parse_table[t+1])
    elseif parse_table[t] == "pan" then
      pan = tonumber(parse_table[t+1])
    elseif parse_table[t] == "key" then
      if tonumber(parse_table[t+1]) == nil then
        lokey = sfz_note_name_to_number(parse_table[t+1])
        hikey = sfz_note_name_to_number(parse_table[t+1])
        basenote = sfz_note_name_to_number(parse_table[t+1])
      else
        lokey = tonumber(parse_table[t+1]) - 12
        hikey = tonumber(parse_table[t+1]) - 12
        basenote = tonumber(parse_table[t+1]) - 12
      end
    elseif parse_table[t] == "pitch_keycenter" then
      if tonumber(parse_table[t+1]) == nil then
        basenote = sfz_note_name_to_number(parse_table[t+1])
      else
        basenote = tonumber(parse_table[t+1]) - 12
      end
    end
  end
  
  for z=1,parse_table[7]:len() do
    print(parse_table[7]:byte(z))
    print(parse_table[7]:sub(z,z))
  end
  
  --last region?
  table.insert(keymaps, {sample, basenote, lokey, hikey, lovel, hivel, transpose, tune, volume, pan})

  table.clear(parse_table)
  
  if #keymaps > 254 then
    table.clear(keymaps)
    renoise.app():show_error("Sorry, Renoise is limited to 255 samples per instrument.  The instrument you are trying to import has more than this.")
    renoise.app():show_status(filename .. " has too many samples for Renoise!  Aborting.")
    return false
  end

  -- get the path to the samples
  sample_path = get_samples_path(inst_name, inst_path, keymaps[1][1])  

  if sample_path == "" then
    -- import aborted
    renoise.app():show_status("SFZ instrument import aborted.")
    table.clear(keymaps)
    return false
  end
  
  -- create the instrument  
  instrument:clear()
  instrument.name = inst_name
  
  sliced_process = ProcessSlicer(sfz_import_samples, nil, instrument, sample_path, keymaps)
  sliced_process:start()

  return true
end


function sfz_import_samples(instrument, sample_path, keymaps)
  -- iterate over keymaps loading in samples
  local missing_samples = 0
  local i=0
  

  for i = 1, #keymaps do
    
    -- check file exists 
    if io.exists(sample_path .. keymaps[i][1]) == false then
      dprint("sfz_import_samples: missing sample=", sample_path .. keymaps[i][1])
      missing_samples = missing_samples + 1
    else
      dprint("sfz_import_samples: found sample=", sample_path .. keymaps[i][1])
      -- insert new sample
      local s = instrument:insert_sample_at(#instrument.samples)
            
      -- load wave file (& loop points in 2.7 beta 6+)
      if s.sample_buffer:load_from(sample_path .. keymaps[i][1]) == true then
        -- set parameters
        s.name = keymaps[i][1]
        
        -- range checks notespans
        local t = keymaps[i][2]
        if t < 0 then
          t = 0
        elseif t > 119 then
          t = 119
        end
        keymaps[i][2] = t
        t = keymaps[i][3]
        if t < 0 then
          t = 0
        elseif t > 119 then
          t = 119
        end
        keymaps[i][3] = t
        t = keymaps[i][4]
        if t < 0 then
          t = 0
        elseif t > 119 then
          t = 119
        end
        keymaps[i][4] = t
        
        -- set transpose
        t = keymaps[i][7]
        if t < -127 then
          t = -127
        elseif t > 127 then
          t = 127
        end
        s.transpose = t
              
        -- set finetune
        t = keymaps[i][8]
        if t < -127 then
          t = -127
        elseif t > 127 then
          t = 127
        end
        s.fine_tune = t
        
        -- set volume
        t = keymaps[i][9]
        if t < -144 then
          t = -144
        elseif t > 12 then
          t = 12
        end
        s.volume = math.db2lin(t)
        
        -- set pan
        t = (keymaps[i][10] / 200) + 0.5
        if t < 0 then
          t = 0
        elseif t > 1 then
          t = 1
        end
        s.panning = t
        
        dprint("sfz_import_samples: base note", keymaps[i][2])
        dprint("sfz_import_samples: low note", keymaps[i][3])
        dprint("sfz_import_samples: hi note", keymaps[i][4])
        dprint("sfz_import_samples: low vel", keymaps[i][5])
        dprint("sfz_import_samples: hi vel", keymaps[i][6])
        -- create sample mapping
        instrument:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                                         #instrument.samples-1,  -- sample
                                         keymaps[i][2], --basenote
                                         {keymaps[i][3],keymaps[i][4]}, -- note span
                                         {keymaps[i][5],keymaps[i][6]}) -- vel span
      end
    end
    renoise.app():show_status(string.format("Importing SFZ instrument file (%d%% done)...",((i/#keymaps))*100))
    -- yield!
    coroutine.yield()
  end
  
  -- remove additional 'blank' sample at the end
  if #instrument.samples > 1 then
    instrument:delete_sample_at(#instrument.samples)
  end
  
  if missing_samples == 0 then
    renoise.app():show_status("Importing SFZ instrument complete.")
  else
    renoise.app():show_status(string.format("Importing  SFZ instrument partially complete (%d missing samples).", missing_samples))
    renoise.app():show_warning(string.format("%d samples could not be found when importing this program file.\nThese have been ignored.", missing_samples))
  end
end

--------------------------------------------------------------------------------
-- Disk Browser Integration
--------------------------------------------------------------------------------
sfz_integration = { category = "instrument",
                    extensions = {"sfz"},
                    invoke = sfz_import}            -- currently doesn't return anything

if renoise.tool():has_file_import_hook("instrument", {"sfz"}) == false then
  renoise.tool():add_file_import_hook(sfz_integration)
end
