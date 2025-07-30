--------------------------------------------------------------------------------
-- SF2 Importer with Detailed Debugging of Panning, Transpose, Fine-Tune, and Key Ranges
--------------------------------------------------------------------------------
local _DEBUG = true
local function dprint(...)
  if _DEBUG then
    print("SF2 Tool:", ...)
  end
end

-- Convert a 16-bit unsigned generator value to a signed integer (-120..120)
local function to_signed(val)
  val = val % 65536
  if val >= 32768 then
    local neg = val - 65536
    return (neg * 120) / 32768
  else
    return (val * 120) / 32768
  end
end

-- SF2 Parameter name mapping
local SF2_PARAM_NAMES = {
    [0] = "StartAddrsOffset",
    [1] = "EndAddrsOffset",
    [2] = "StartloopAddrsOffset",
    [3] = "EndloopAddrsOffset",
    [4] = "StartAddrsCoarseOffset",
    [5] = "ModLFO_to_Pitch",
    [6] = "VibLFO_to_Pitch",
    [7] = "ModEnv_to_Pitch",
    [8] = "InitialFilterFC",
    [9] = "InitialFilterQ",
    [10] = "ModLFO_to_FilterFC",
    [11] = "ModEnv_to_FilterFC",
    [12] = "EndAddrsCoarseOffset",
    [13] = "ModLFO_to_Volume",
    [15] = "ChorusEffectsSend",
    [16] = "ReverbEffectsSend",
    [17] = "Pan",
    [21] = "ModLFO_Delay",
    [22] = "ModLFO_Freq",
    [23] = "VibLFO_Delay",
    [24] = "VibLFO_Freq",
    [25] = "ModEnv_Delay",
    [26] = "ModEnv_Attack",
    [27] = "ModEnv_Hold",
    [28] = "ModEnv_Decay",
    [29] = "ModEnv_Sustain",
    [30] = "ModEnv_Release",
    [31] = "Key_to_ModEnvHold",
    [32] = "Key_to_ModEnvDecay",
    [33] = "VolEnv_Delay",
    [34] = "VolEnv_Attack",
    [35] = "VolEnv_Hold",
    [36] = "VolEnv_Decay",
    [37] = "VolEnv_Sustain",
    [38] = "VolEnv_Release",
    [39] = "Key_to_VolEnvHold",
    [40] = "Key_to_VolEnvDecay",
    [41] = "Instrument",
    [43] = "KeyRange",
    [44] = "VelRange",
    [45] = "StartloopAddrsCoarse",
    [46] = "Keynum",
    [47] = "Velocity",
    [48] = "InitialAttenuation",
    [50] = "EndloopAddrsCoarse",
    [51] = "CoarseTune",
    [52] = "FineTune",
    [53] = "SampleID",
    [54] = "SampleModes",
    [56] = "ScaleTuning",
    [57] = "ExclusiveClass",
    [58] = "OverridingRootKey"
}

-- Format generator values for debug printing
local function format_param_value(param_id, value)
    if param_id == 43 then -- KeyRange
        local low = value % 256
        local high = math.floor(value / 256) % 256
        return string.format("%d-%d", low, high)
    elseif param_id == 44 then -- VelRange
        local low = value % 256
        local high = math.floor(value / 256) % 256
        return string.format("%d-%d", low, high)
    elseif param_id == 54 then
        local modes = {"None", "Loop", "LoopBidi"}
        return modes[value+1] or "Unknown"
    elseif param_id == 17 then
        return tostring(to_signed(value))
    elseif param_id == 51 or param_id == 52 then
        return tostring((value>=32768) and (value-65536) or value)
    else
        return tostring(value)
    end
end

-- Basic binary readers and utils
local function trim_string(s) return s:gsub("\0","") end

local function read_u16_le(data,pos) 
  if not data or not pos or pos < 1 or pos + 1 > #data then return nil end
  return data:byte(pos) + data:byte(pos+1)*256 
end

local function read_u32_le(data,pos) 
  if not data or not pos or pos < 1 or pos + 3 > #data then return nil end
  return data:byte(pos) + data:byte(pos+1)*256 + data:byte(pos+2)*65536 + data:byte(pos+3)*16777216 
end

local function read_s16_le(data,pos) 
  local v = read_u16_le(data,pos) 
  if not v then return nil end
  return v>=32768 and v-65536 or v 
end

local function clamp(v,minv,maxv) if v<minv then return minv elseif v>maxv then return maxv else return v end end

-- Clamp note values to valid Renoise range (0-119)
local function clamp_note(note)
  return math.min(119, math.max(0, note))
end

-- Read sample headers
local function read_sample_headers(data)
  local pos = data:find("shdr",1,true)
  if not pos then return renoise.app():show_error("Missing shdr chunk") end
  local size = read_u32_le(data,pos+4)
  local p = pos+8
  local rec = 46
  local hdrs={}
  while p+rec-1 <= pos+7+size do
    local name=data:sub(p,p+19); p=p+20
    local s_start=read_u32_le(data,p);p=p+4
    local s_end=read_u32_le(data,p);p=p+4
    local loop_start=read_u32_le(data,p);p=p+4
    local loop_end=read_u32_le(data,p);p=p+4
    local rate=read_u32_le(data,p);p=p+4
    local pitch=data:byte(p);p=p+1
    local corr=data:byte(p);p=p+1;if corr>=128 then corr=corr-256 end
    local link=read_u16_le(data,p);p=p+2
    local stype=read_u16_le(data,p);p=p+2
    local n=trim_string(name)
    if n:find("EOS") then break end
    table.insert(hdrs,{name=n,s_start=s_start,s_end=s_end,loop_start=loop_start,loop_end=loop_end,sample_rate=rate,orig_pitch=pitch,pitch_corr=corr,sample_link=link,sample_type=stype})
  end
  dprint("Sample headers:",#hdrs)
  return hdrs
end

-- Parse instruments and their zones
local function read_instruments(data, slicer)
  local pdta=data:find("pdta",1,true)
  if not pdta then return {} end
  local inst=data:find("inst",pdta+8,true)
  if not inst then return {} end
  local n=read_u32_le(data,inst+4)
  local p=inst+8
  local instruments={}
  local instrument_count = 0
  local total_instruments = math.floor(n/22)
  
  print(string.format("Reading %d instruments...", total_instruments))
  
  while p+21 <= inst+7+n do
    if slicer and slicer:was_cancelled() then return {} end
    
    local name=trim_string(data:sub(p,p+19))
    local bag=read_u16_le(data,p+20)
    table.insert(instruments,{name=name,bag_index=bag})
    p=p+22
    
    instrument_count = instrument_count + 1
    print(string.format("Reading instrument %03d/%03d: %s", instrument_count, total_instruments, name))
    if slicer and slicer.dialog and slicer.dialog.views.progress_text then 
      slicer.dialog.views.progress_text.text = string.format("Reading Instruments (%03d/%03d): %s", 
        instrument_count, total_instruments, name)
      coroutine.yield() 
    end
  end
  -- ibag
  local ibag=data:find("ibag",pdta+8,true)
  local ibag_n=read_u32_le(data,ibag+4)
  local bpos=ibag+8
  local ibags={}
  while bpos+3 <= ibag+7+ibag_n do
    if slicer and slicer:was_cancelled() then return {} end
    
    table.insert(ibags,{gen_index=read_u16_le(data,bpos),mod_index=read_u16_le(data,bpos+2)})
    bpos=bpos+4
    
    -- Yield every 100 entries to keep UI responsive
    if slicer and (#ibags % 100 == 0) then coroutine.yield() end
  end
  -- igen
  local igen=data:find("igen",pdta+8,true)
  local igen_n=read_u32_le(data,igen+4)
  local gpos=igen+8
  local gens={}
  while gpos+3 <= igen+7+igen_n do
    if slicer and slicer:was_cancelled() then return {} end
    
    table.insert(gens,{op=read_u16_le(data,gpos),amount=read_u16_le(data,gpos+2)})
    gpos=gpos+4
    
    -- Yield every 100 entries to keep UI responsive
    if slicer and (#gens % 100 == 0) then coroutine.yield() end
  end
  -- Build zones
  local result={}
  for i,inst in ipairs(instruments) do
    if slicer and slicer:was_cancelled() then return {} end
    
    local zones={}
    local start_b=inst.bag_index+1
    local end_b=(i<#instruments and instruments[i+1].bag_index) or #ibags
    for bi=start_b,end_b do
      if slicer and slicer:was_cancelled() then return {} end
      
      local bag=ibags[bi]
      local params={}
      local gstart=bag.gen_index+1
      local gend=(bi<#ibags and ibags[bi+1].gen_index) or #gens
      for gi=gstart,gend do
        if slicer and slicer:was_cancelled() then return {} end
        
        local g=gens[gi]
        params[g.op]=g.amount
        dprint("Inst param",g.op,format_param_value(g.op,g.amount))
        
        -- Yield every 100 entries to keep UI responsive
        if slicer and (gi % 100 == 0) then coroutine.yield() end
      end
      local zone={params=params}
      -- key range
      if params[43] then
        local kr=params[43]
        zone.key_range={low=clamp(kr%256,0,119),high=clamp(math.floor(kr/256)%256,0,119)}
      end
      -- velocity range
      if params[44] then
        local vr=params[44]
        zone.vel_range={low=clamp(vr%256,1,127),high=clamp(math.floor(vr/256)%256,1,127)}
        dprint("VelRange for zone",zone.vel_range.low.."-"..zone.vel_range.high)
      end
      -- sample ID
      if params[53] then zone.sample_id=params[53] end
      table.insert(zones,zone)
      
      if slicer then coroutine.yield() end
    end
    table.insert(result,{name=inst.name,zones=zones})
    
    if slicer then coroutine.yield() end
  end
  dprint("Parsed instruments:",#result)
  return result
end

local function read_presets(data, slicer)
  local phdr_pos = data:find("phdr", 1, true)
  if not phdr_pos then
    print("No phdr chunk found.")
    return {}
  end

  local phdr_size = read_u32_le(data, phdr_pos + 4)
  local phdr_data_start = phdr_pos + 8
  local phdr_record_size = 38
  local presets = {}
  local preset_count = 0
  local total_presets = math.floor(phdr_size / phdr_record_size)

  print(string.format("Reading %d presets...", total_presets))

  local pos = phdr_data_start
  while (pos + phdr_record_size -1) <= (phdr_data_start + phdr_size -1) do
    if slicer and slicer:was_cancelled() then return {} end
    
    local preset_name = trim_string(data:sub(pos, pos+19))
    local preset = read_u16_le(data, pos+20)
    local bank = read_u16_le(data, pos+22)
    local pbag_idx = read_u16_le(data, pos+24)
    if preset_name:find("EOP") then break end
    presets[#presets + 1] = {
      name = preset_name,
      preset = preset,
      bank = bank,
      pbag_index = pbag_idx,
      zones = {}
    }
    pos = pos + phdr_record_size
    
    preset_count = preset_count + 1
    print(string.format("Reading preset %03d/%03d: %s (Bank %d, Preset %d)", 
      preset_count, total_presets, preset_name, bank, preset))
    if slicer and slicer.dialog and slicer.dialog.views.progress_text then 
      slicer.dialog.views.progress_text.text = string.format("Reading Presets (%03d/%03d): %s (Bank %d, Preset %d)", 
        preset_count, total_presets, preset_name, bank, preset)
      coroutine.yield() 
    end
  end

  local pdta_pos = data:find("pdta", 1, true)
  if not pdta_pos then
    print("No pdta chunk available for preset analysis.")
    return presets
  end

  local function read_pbag(data, start_pos)
    local pbag_pos = data:find("pbag", start_pos, true)
    if not pbag_pos then
      print("No pbag chunk found.")
      return {}
    end
    local pbag_size = read_u32_le(data, pbag_pos + 4)
    local pbag_data_start = pbag_pos + 8
    local record_size = 4
    local pbag_list = {}
    local pos = pbag_data_start
    while (pos + record_size -1) <= (pbag_data_start + pbag_size -1) do
      if slicer and slicer:was_cancelled() then return {} end
      
      local pgen_idx = read_u16_le(data, pos)
      local pmod_idx = read_u16_le(data, pos+2)
      pbag_list[#pbag_list + 1] = { pgen_index = pgen_idx, pmod_index = pmod_idx }
      pos = pos + record_size
      
      -- Yield every 100 entries to keep UI responsive
      if slicer and (#pbag_list % 100 == 0) then coroutine.yield() end
    end
    return pbag_list
  end

  local function read_pgen(data, start_pos)
    local pgen_pos = data:find("pgen", start_pos, true)
    if not pgen_pos then
      print("No pgen chunk found.")
      return {}
    end
    local pgen_size = read_u32_le(data, pgen_pos + 4)
    local pgen_data_start = pgen_pos + 8
    local record_size = 4
    local pgen_list = {}
    local pos = pgen_data_start
    while (pos + record_size -1) <= (pgen_data_start + pgen_size -1) do
      if slicer and slicer:was_cancelled() then return {} end
      
      local op = read_u16_le(data, pos)
      local amount = read_u16_le(data, pos+2)
      pgen_list[#pgen_list + 1] = { op = op, amount = amount }
      pos = pos + record_size
      
      -- Yield every 100 entries to keep UI responsive
      if slicer and (#pgen_list % 100 == 0) then coroutine.yield() end
    end
    return pgen_list
  end

  local pbag = read_pbag(data, pdta_pos + 8)
  local pgen = read_pgen(data, pdta_pos + 8)
  if (#pbag == 0) or (#pgen == 0) then
    print("No PBAG/PGEN data; returning basic presets only.")
    return presets
  end

  for i, preset in ipairs(presets) do
    if slicer and slicer:was_cancelled() then return {} end
    
    local zone_start = preset.pbag_index + 1
    local zone_end   = #pbag
    if i < #presets then
      zone_end = presets[i+1].pbag_index
    end
    
    -- Skip if zone_start is invalid
    if zone_start <= #pbag then
      for z = zone_start, zone_end do
        if slicer and slicer:was_cancelled() then return {} end
        
        -- Skip if zone index is invalid
        if z > #pbag then
          print(string.format("Warning: Invalid zone index %d for preset '%s' (pbag size: %d)", 
            z, preset.name, #pbag))
          break
        end
        
        local bag = pbag[z]
        -- Skip this zone if bag is nil
        if bag then
          local zone_params = {}
          local pgen_start = bag.pgen_index + 1
          local pgen_end   = #pgen
          if z < #pbag then
            pgen_end = pbag[z+1].pgen_index
          end

          -- Only process if pgen indices are valid
          if pgen_start <= #pgen then
            for pg = pgen_start, pgen_end do
              if slicer and slicer:was_cancelled() then return {} end
              
              if pg > #pgen then
                print(string.format("Warning: Invalid pgen index %d for preset '%s' zone %d (pgen size: %d)", 
                  pg, preset.name, z, #pgen))
                break
              end
              
              local gen = pgen[pg]
              if gen then
                zone_params[gen.op] = gen.amount
              end
              
              -- Yield every 100 entries to keep UI responsive
              if slicer and (pg % 100 == 0) then coroutine.yield() end
            end
            
            local key_range = nil
            if zone_params[43] then
              local kr = zone_params[43]
              local low = kr % 256
              local high = math.floor(kr / 256) % 256
              -- Clamp values to 0-119 range
              low = math.min(119, math.max(0, low))
              high = math.min(119, math.max(0, high))
              key_range = { low = low, high = high }
            end
            
            preset.zones[#preset.zones + 1] = {
              params = zone_params,
              key_range = key_range
            }
          else
            print(string.format("Warning: Invalid pgen_start %d for preset '%s' zone %d (pgen size: %d)", 
              pgen_start, preset.name, z, #pgen))
          end
        else
          print(string.format("Warning: Nil bag at index %d for preset '%s'", z, preset.name))
        end
        
        if slicer then coroutine.yield() end
      end
    else
      print(string.format("Warning: Invalid zone_start %d for preset '%s' (pbag size: %d)", 
        zone_start, preset.name, #pbag))
    end
    
    if slicer then coroutine.yield() end
  end

  return presets
end

-- Helper function to check if an instrument is truly empty
local function is_instrument_empty(instrument)
  -- Check if it has any samples
  if #instrument.samples > 0 then return false end
  
  -- Check if it has MIDI routing set up
  if instrument.midi_input_properties.device_name ~= "" then return false end
  
  -- Check if it has any plugin devices
  if instrument.plugin_properties.plugin_device then return false end
  
  -- If we got here, the instrument is empty
  return true
end

local function import_sf2(file_path)
  -- Create a ProcessSlicer to handle the import
  local slicer = nil
  
  local function process_import()
    local dialog, vb = nil, nil
    dialog, vb = slicer:create_dialog("Importing SF2...")
    
    print("Importing SF2 file: " .. file_path)

    local f = io.open(file_path, "rb")
    if not f then
      renoise.app():show_error("Could not open SF2 file: " .. file_path)
      return false
    end
    local data = f:read("*all")
    f:close()

    if data:sub(1,4) ~= "RIFF" then
      renoise.app():show_error("Invalid SF2 file (missing RIFF header).")
      return false
    end
    print("RIFF header found.")

    local smpl_pos = data:find("smpl", 1, true)
    if not smpl_pos then
      renoise.app():show_error("SF2 file missing 'smpl' chunk.")
      return false
    end
    local smpl_data_start = smpl_pos + 8

    -- Read SF2 components:
    if vb then vb.views.progress_text.text="Reading sample headers..." end
    coroutine.yield()
    
    local headers = read_sample_headers(data)
    if not headers or #headers == 0 then
      renoise.app():show_error("No sample headers found in SF2.")
      return false
    end

    if vb then vb.views.progress_text.text="Reading instruments..." end
    coroutine.yield()
    
    local instruments_zones = read_instruments(data, slicer)
    
    if vb then vb.views.progress_text.text="Reading presets..." end
    coroutine.yield()
    
    local presets = read_presets(data, slicer)
    if #presets == 0 then
      renoise.app():show_error("No presets found in SF2.")
      return false
    end

    -- Build a mapping: one XRNI instrument per preset
    local mappings = {}

    if vb then vb.views.progress_text.text="Processing presets..." end
    coroutine.yield()

    for _, preset in ipairs(presets) do
      if slicer:was_cancelled() then
        return false
      end
      
      print("Preset " .. preset.name)
      local combined_samples = {}
      for _, zone in ipairs(preset.zones) do
        local assigned_samples = {}
        local zone_params = zone.params or {}

        print("Processing preset zone params:")
        for k,v in pairs(zone_params) do
            print("  [" .. k .. "] = " .. v)
        end

        -- If there's an assigned instrument
        if zone_params[41] then
          local inst_idx = zone_params[41] + 1
          local inst_info = instruments_zones[inst_idx]
          if inst_info and inst_info.zones then
            for _, izone in ipairs(inst_info.zones) do
              if izone.sample_id then
                local hdr_idx = izone.sample_id + 1
                local hdr = headers[hdr_idx]
                if hdr then
                  print("  Instrument " .. inst_info.name .. " => Sample " .. hdr.name .. " (SampleID " .. izone.sample_id .. ")")
                  print("  Instrument zone params:")
                  for k,v in pairs(izone.params or {}) do
                      print("    [" .. k .. "] = " .. v)
                  end
                  assigned_samples[#assigned_samples+1] = {
                    header = hdr,
                    zone_params = zone_params,
                    inst_zone_params = izone.params
                  }
                end
              end
            end
          end
        end

        -- Fallback: key_range from the preset zone
        if #assigned_samples == 0 and zone.key_range then
          for _, hdr in ipairs(headers) do
            if hdr.orig_pitch >= zone.key_range.low and hdr.orig_pitch <= zone.key_range.high then
              print("  KeyRange fallback => Sample " .. hdr.name .. " (pitch " .. hdr.orig_pitch .. " in range " .. zone.key_range.low .. "-" .. zone.key_range.high .. ")")
              assigned_samples[#assigned_samples+1] = {
                header = hdr,
                zone_params = zone_params
              }
            end
          end
        end

        -- Substring fallback if we still have no assigned samples
        if #assigned_samples == 0 then
          for _, hdr in ipairs(headers) do
            if hdr.name:lower():find(preset.name:lower()) then
              print("  Substring fallback => Sample " .. hdr.name)
              assigned_samples[#assigned_samples+1] = {
                header = hdr,
                zone_params = zone_params
              }
            end
          end
        end

        for _, smp_entry in ipairs(assigned_samples) do
          combined_samples[#combined_samples+1] = smp_entry
        end
      end

      if #combined_samples > 0 then
        mappings[#mappings+1] = {
          preset_name = preset.name,
          bank = preset.bank,
          preset_num = preset.preset,
          samples = combined_samples,
          fallback_params = (preset.zones[#preset.zones] and preset.zones[#preset.zones].params) or {},
          key_range = (preset.zones[#preset.zones] and preset.zones[#preset.zones].key_range)
        }
      else
        print("Preset " .. preset.name .. " has no assigned samples.")
      end
      
      coroutine.yield()
    end

    if #mappings == 0 then
      renoise.app():show_error("No preset with assigned samples.")
      return false
    end

    local song=renoise.song()
    local imported_count = 0
    local max_instruments = 255
    local empty_slots = 0
    
    -- First count how many empty slots we have
    for i = 1, #song.instruments do
      if is_instrument_empty(song.instruments[i]) then
        empty_slots = empty_slots + 1
      end
    end
    
    print(string.format("Found %d empty instrument slots", empty_slots))

    -- Process each mapping
    for map_idx, map in ipairs(mappings) do
      if slicer:was_cancelled() then
        return false
      end
      
      -- Check if we've hit the absolute limit
      if imported_count >= max_instruments then
        if dialog and dialog.visible then
          dialog:close()
        end
        renoise.app():show_status(string.format(
          "Imported maximum of %d instruments. %d presets were skipped.", 
          max_instruments, #mappings - max_instruments))
        return true
      end
      
      if vb then 
        vb.views.progress_text.text = string.format(
          "Creating instrument %d/%d: %s", 
          map_idx, math.min(#mappings, max_instruments), map.preset_name)
      end
      
      local is_drumkit = (map.bank == 128)
      local preset_file = is_drumkit and
        (renoise.tool().bundle_path .. "Presets/12st_Pitchbend_Drumkit_C0.xrni") or
        "Presets/12st_Pitchbend.xrni"

      -- Try to find an empty slot first
      local empty_slot_found = false
      if #song.instruments < max_instruments then
        for i = 1, #song.instruments do
          if is_instrument_empty(song.instruments[i]) then
            song.selected_instrument_index = i
            empty_slot_found = true
            break
          end
        end
      end
      
      -- If no empty slot found and we haven't hit the limit, create new slot
      if not empty_slot_found and #song.instruments < max_instruments then
        song:insert_instrument_at(song.selected_instrument_index + 1)
        song.selected_instrument_index = song.selected_instrument_index + 1
      elseif not empty_slot_found then
        -- We've hit the limit and found no empty slots
        if dialog and dialog.visible then
          dialog:close()
        end
        renoise.app():show_status(string.format(
          "Imported %d instruments. No more empty slots available.", imported_count))
        return true
      end

      renoise.app():load_instrument(preset_file)

      local r_inst = song.selected_instrument
      if not r_inst then
        renoise.app():show_error("Failed to load XRNI preset for " .. map.preset_name)
        return false
      end

      imported_count = imported_count + 1
      r_inst.name = string.format("%s (Bank %d, Preset %d)", map.preset_name, map.bank, map.preset_num)
      print("Created instrument for preset: " .. r_inst.name)

      local is_first_overwritten = false

      -- Process samples for this mapping
      for smp_idx, smp_entry in ipairs(map.samples) do
        if slicer:was_cancelled() then
          return false
        end
        
        if vb then 
          vb.views.progress_text.text = string.format(
            "Processing sample %d/%d in %s", 
            smp_idx, #map.samples, map.preset_name)
        end
        
        local hdr = smp_entry.header
        local zone_params = smp_entry.zone_params or {}
        local inst_zone_params = smp_entry.inst_zone_params or {}
        local frames = hdr.s_end - hdr.s_start
        if frames <= 0 then
          print("Skipping sample " .. hdr.name .. " (non-positive frame count).")
        else
          -- Determine if sample is stereo
          local is_stereo = false
          if hdr.sample_link ~= 0 then
            if hdr.sample_type == 0 or hdr.sample_type == 1 then
              is_stereo = true
            else
              print("Skipping right stereo channel for " .. hdr.name)
            
            end
          end

          -- Load sample data
          local sample_data = {}
          if is_stereo then
            for f_i = hdr.s_start + 1, hdr.s_end do
              local offset = smpl_data_start + (f_i - 1) * 4
              if offset + 3 <= #data then
                local left_val  = read_s16_le(data, offset)
                local right_val = read_s16_le(data, offset + 2)
                sample_data[#sample_data+1] = { left = left_val/32768.0, right = right_val/32768.0 }
              end
              -- Yield every 100,000 frames
              if f_i % 100000 == 0 then coroutine.yield() end
            end
          else
            for f_i = hdr.s_start + 1, hdr.s_end do
              local offset = smpl_data_start + (f_i - 1) * 2
              if offset + 1 <= #data then
                local raw_val = read_s16_le(data, offset)
                sample_data[#sample_data+1] = raw_val / 32768.0
              end
              -- Yield every 100,000 frames
              if f_i % 100000 == 0 then coroutine.yield() end
            end
          end
          print("Extracted " .. #sample_data .. " frames from sample " .. hdr.name)
          if #sample_data == 0 then
            print("Skipping sample " .. hdr.name .. " (zero frames).")
            
          end

          local sample_slot = nil
          if not is_drumkit then
            if not is_first_overwritten and #r_inst.samples > 0 then
              sample_slot = 1
              is_first_overwritten = true
            else
              sample_slot = #r_inst.samples + 1
              r_inst:insert_sample_at(sample_slot)
            end
          else
            sample_slot = #r_inst.samples + 1
            r_inst:insert_sample_at(sample_slot)
          end

          local reno_smp = r_inst.samples[sample_slot]
          local success, err = pcall(function()
            if is_stereo then
              reno_smp.sample_buffer:create_sample_data(hdr.sample_rate, 16, 2, #sample_data)
            else
              reno_smp.sample_buffer:create_sample_data(hdr.sample_rate, 16, 1, #sample_data)
            end
          end)
          if not success then
            print("Error creating sample data for " .. hdr.name .. ": " .. err)
          else
            -- Fill sample buffer
            local buf = reno_smp.sample_buffer
            buf:prepare_sample_data_changes()  -- Prepare before setting sample data
            if is_stereo then
              for f_i=1, #sample_data do
                buf:set_sample_data(1, f_i, sample_data[f_i].left)
                buf:set_sample_data(2, f_i, sample_data[f_i].right)
                -- Yield every 100,000 frames
                if f_i % 100000 == 0 then coroutine.yield() end
              end
            else
              for f_i=1, #sample_data do
                buf:set_sample_data(1, f_i, sample_data[f_i])
                -- Yield every 100,000 frames
                if f_i % 100000 == 0 then coroutine.yield() end
              end
            end
            buf:finalize_sample_data_changes()  -- Finalize after all sample data is set
            reno_smp.name = hdr.name

            -- Get parameters from both instrument and preset zones
            local inst_zone_params = smp_entry.inst_zone_params or {}
            local zone_params = smp_entry.zone_params or {}

            -- Debug the actual parameters we got
            print("DEBUG RAW PARAMS for " .. hdr.name .. ":")
            print("  Instrument zone params:")
            for k,v in pairs(inst_zone_params) do
                local param_name = SF2_PARAM_NAMES[k] or "Unknown"
                local formatted_value = format_param_value(k, v)
                print(string.format("    [%d:%s] = %s", k, param_name, formatted_value))
            end
            print("  Preset zone params:")
            for k,v in pairs(zone_params) do
                local param_name = SF2_PARAM_NAMES[k] or "Unknown"
                local formatted_value = format_param_value(k, v)
                print(string.format("    [%d:%s] = %s", k, param_name, formatted_value))
            end

            -- Initialize debug strings
            local tuning_info = {}
            local loop_info = {}
            local envelope_info = {}

            -- Tuning parameters
            local coarse_tune = 0
            local fine_tune = 0
            local tuning_source = "none"
            local raw_coarse = 0
            local raw_fine = 0
            
            -- Get tuning values
            if inst_zone_params[51] then
                tuning_source = "instrument"
                raw_coarse = inst_zone_params[51]
                coarse_tune = (raw_coarse >= 32768) and (raw_coarse - 65536) or raw_coarse
            elseif zone_params[51] then
                tuning_source = "preset"
                raw_coarse = zone_params[51]
                coarse_tune = (raw_coarse >= 32768) and (raw_coarse - 65536) or raw_coarse
            end

            if inst_zone_params[52] then
                raw_fine = inst_zone_params[52]
                fine_tune = (raw_fine >= 32768) and (raw_fine - 65536) or raw_fine
                fine_tune = (fine_tune * 100) / 100
            elseif zone_params[52] then
                raw_fine = zone_params[52]
                fine_tune = (raw_fine >= 32768) and (raw_fine - 65536) or raw_fine
                fine_tune = (fine_tune * 100) / 100
            end

            -- Apply pitch correction if available
            if hdr.pitch_corr and hdr.pitch_corr ~= 0 then
                fine_tune = fine_tune + hdr.pitch_corr
            end

            -- Clamp tuning values to valid ranges
            coarse_tune = clamp(coarse_tune, -120, 120)
            fine_tune = clamp(fine_tune, -100, 100)

            -- Pan (SF2 range -120..120 maps proportionally to Renoise 0..1)
            local raw_pan = inst_zone_params[17] or zone_params[17] or map.fallback_params[17]
            if raw_pan ~= nil then
                -- Get signed value already scaled to -120..120
                local pan_val = to_signed(raw_pan)
                -- Convert to 0..1 range proportionally
                local pan_norm = 0.5 + (pan_val / 120) * 0.5
                reno_smp.panning = pan_norm
            else
                reno_smp.panning = 0.5
            end

            -- Loop handling
            local loop_mode = "none"
            -- Account for the +1 offset in sample extraction (we extract from s_start+1, not s_start)
            local loop_start_rel = hdr.loop_start - hdr.s_start + 1
            local loop_end_rel = hdr.loop_end - hdr.s_start
            local loop_length = 0

            if not is_drumkit then
                                 -- BUGFIX: Respect SampleModes parameter (54) for loop detection
                 -- SF2 SampleModes: 0=No loop, 1=Continuous loop, 3=Loop until release (bidirectional)
                 local sample_mode = inst_zone_params[54] or zone_params[54]
                 if sample_mode == 1 then -- Continuous loop
                    if loop_start_rel <= 0 then loop_start_rel = 1 end
                    if loop_end_rel > #sample_data then loop_end_rel = #sample_data end

                    if loop_end_rel > loop_start_rel then
                        reno_smp.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
                        reno_smp.loop_start = loop_start_rel
                        reno_smp.loop_end = loop_end_rel
                        loop_mode = frames < 512 and "forced" or "normal"
                        loop_length = loop_end_rel - loop_start_rel
                    else
                        reno_smp.loop_mode = renoise.Sample.LOOP_MODE_OFF
                    end
                                 elseif sample_mode == 3 then -- Loop until release (bidirectional)
                     if loop_start_rel <= 0 then loop_start_rel = 1 end
                     if loop_end_rel > #sample_data then loop_end_rel = #sample_data end
 
                     if loop_end_rel > loop_start_rel then
                         reno_smp.loop_mode = renoise.Sample.LOOP_MODE_PING_PONG
                        reno_smp.loop_start = loop_start_rel
                        reno_smp.loop_end = loop_end_rel
                        loop_mode = frames < 512 and "forced" or "normal"
                        loop_length = loop_end_rel - loop_start_rel
                    else
                        reno_smp.loop_mode = renoise.Sample.LOOP_MODE_OFF
                    end
                else
                    reno_smp.loop_mode = renoise.Sample.LOOP_MODE_OFF
                end
            end

            -- Key range handling
            local key_range_source = "none"
            local key_range_low = 0
            local key_range_high = 119
            local zone_key_range = nil

            if inst_zone_params[43] then
                key_range_source = "instrument"
                local kr = inst_zone_params[43]
                local orig_low = kr % 256
                local orig_high = math.floor(kr / 256) % 256
                key_range_low = math.min(119, math.max(0, orig_low))
                key_range_high = math.min(119, math.max(0, orig_high))
                zone_key_range = { low = key_range_low, high = key_range_high }
            elseif zone_params[43] then
                key_range_source = "preset"
                local kr = zone_params[43]
                local orig_low = kr % 256
                local orig_high = math.floor(kr / 256) % 256
                key_range_low = math.min(119, math.max(0, orig_low))
                key_range_high = math.min(119, math.max(0, orig_high))
                zone_key_range = { low = key_range_low, high = key_range_high }
            elseif map.key_range then
                key_range_source = "map"
                local orig_low = map.key_range.low
                local orig_high = map.key_range.high
                key_range_low = math.min(119, math.max(0, orig_low))
                key_range_high = math.min(119, math.max(0, orig_high))
                zone_key_range = { low = key_range_low, high = key_range_high }
            end

            -- Apply the key range to the sample mapping
            local base_note = hdr.orig_pitch or 60
            
            -- BUGFIX: Check for OverridingRootKey parameter (58) which should override original pitch
            local override_root_key = inst_zone_params[58] or zone_params[58]
            if override_root_key then
                base_note = override_root_key
                dprint("Using OverridingRootKey:", override_root_key, "instead of original pitch:", hdr.orig_pitch)
            end
            
            -- Clamp base_note to valid range (0-108, where 108 is C-9)
            base_note = math.min(108, math.max(0, base_note))
            reno_smp.sample_mapping.base_note = base_note

            if zone_key_range then
                -- Clamp key range to valid range (0-119)
                local low = clamp_note(zone_key_range.low)
                local high = clamp_note(zone_key_range.high)
                reno_smp.sample_mapping.note_range = { low, high }
                -- Apply velocity range: instrument zone overrides preset zone, defaults to full 1–127
local vel_low, vel_high = 1, 127
local vr = nil

-- instrument‑level has priority
if inst_zone_params[44] then
  vr = inst_zone_params[44]
-- then preset level
elseif zone_params[44] then
  vr = zone_params[44]
end

if vr then
  -- low byte = low, high byte = high
  vel_low  = clamp(vr % 256,  1, 127)
  vel_high = clamp(math.floor(vr/256) % 256, 1, 127)
end

reno_smp.sample_mapping.velocity_range = { vel_low, vel_high }


            else
                if is_drumkit then
                    -- For drumkits, clamp the base note
                    local clamped_base = clamp_note(base_note)
                    reno_smp.sample_mapping.note_range = { clamped_base, clamped_base }
                else
                    reno_smp.sample_mapping.note_range = { 0, 119 }
                end
            end

-- Print comprehensive debug info
            print("TUNING DEBUG for " .. hdr.name .. ": source=" .. tuning_source .. 
                  ", coarse=" .. raw_coarse .. "->" .. coarse_tune .. 
                  ", fine=" .. raw_fine .. "->" .. fine_tune .. 
                  ", pitch_corr=" .. (hdr.pitch_corr or 0))

            print("KEYRANGE DEBUG for " .. hdr.name .. ": source=" .. key_range_source .. 
                  ", range=" .. key_range_low .. "-" .. key_range_high)

            print("LOOP DEBUG for " .. hdr.name .. ": mode=" .. loop_mode .. 
                  ", orig_start=" .. hdr.loop_start .. ", orig_end=" .. hdr.loop_end .. 
                  ", rel_start=" .. loop_start_rel .. ", rel_end=" .. loop_end_rel .. 
                  ", length=" .. loop_length)

            print("PANNING DEBUG for " .. hdr.name .. ": source=" .. (raw_pan and "instrument" or "preset") .. 
                  ", value=" .. (raw_pan and to_signed(raw_pan) or 0))

            -- Apply all values to the sample
            reno_smp.transpose = coarse_tune
            reno_smp.fine_tune = fine_tune

            -- BUGFIX: Apply SF2 volume envelope parameters to Renoise AHDSR device
            local has_envelope_params = false
            local vol_attack = inst_zone_params[34] or zone_params[34]
            local vol_hold = inst_zone_params[35] or zone_params[35] 
            local vol_decay = inst_zone_params[36] or zone_params[36]
            local vol_sustain = inst_zone_params[37] or zone_params[37]
            local vol_release = inst_zone_params[38] or zone_params[38]

            if vol_attack or vol_hold or vol_decay or vol_sustain or vol_release then
                has_envelope_params = true
                dprint("Applying SF2 volume envelope to sample:", reno_smp.name)
                
                -- Get or create Volume AHDSR device for this sample
                local ahdsr_device = setup_volume_ahdsr_device(r_inst, sample_slot)
                
                if ahdsr_device then
                    -- Convert and apply envelope parameters
                    if vol_attack then
                        local attack_seconds = timecents_to_seconds(vol_attack)
                        if attack_seconds then
                            local attack_param = map_envelope_time(attack_seconds)
                            if attack_param then
                                ahdsr_device.parameters[2].value = attack_param -- Attack parameter
                                dprint("  Attack:", vol_attack, "->", attack_seconds, "s ->", attack_param)
                            end
                        end
                    end
                    
                    if vol_hold then
                        local hold_seconds = timecents_to_seconds(vol_hold)
                        if hold_seconds then
                            local hold_param = map_envelope_time(hold_seconds)
                            if hold_param then
                                ahdsr_device.parameters[3].value = hold_param -- Hold parameter
                                dprint("  Hold:", vol_hold, "->", hold_seconds, "s ->", hold_param)
                            end
                        end
                    end
                    
                    if vol_decay then
                        local decay_seconds = timecents_to_seconds(vol_decay)
                        if decay_seconds then
                            local decay_param = map_envelope_time(decay_seconds)
                            if decay_param then
                                ahdsr_device.parameters[4].value = decay_param -- Decay parameter
                                dprint("  Decay:", vol_decay, "->", decay_seconds, "s ->", decay_param)
                            end
                        end
                    end
                    
                    if vol_sustain then
                        local sustain_level = sustain_cb_to_level(vol_sustain)
                        if sustain_level then
                            ahdsr_device.parameters[5].value = sustain_level -- Sustain parameter
                            dprint("  Sustain:", vol_sustain, "cB ->", sustain_level)
                        end
                    end
                    
                    if vol_release then
                        local release_seconds = timecents_to_seconds(vol_release)
                        if release_seconds then
                            local release_param = map_envelope_time(release_seconds)
                            if release_param then
                                ahdsr_device.parameters[6].value = release_param -- Release parameter
                                dprint("  Release:", vol_release, "->", release_seconds, "s ->", release_param)
                            end
                        end
                    end
                end
            end

            -- After first sample import, check for and remove placeholder if it exists
            if not is_drumkit and is_first_overwritten then
              for i=1, #r_inst.samples do
                local s = r_inst.samples[i]
                if s and s.name == "Placeholder sample" and s.sample_buffer.number_of_frames == 2 then
                  print("Removing 2-frame placeholder sample")
                  r_inst:delete_sample_at(i)
                  break
                end
              end
            end
          end
        end
        
        coroutine.yield()
      end

      -- If drumkit => remove placeholder and map each sample to one discrete note
      if is_drumkit then
        if #r_inst.samples > 1 then
          print("Drum preset: removing placeholder sample #1 (" .. r_inst.samples[1].name .. ")")
          r_inst:delete_sample_at(1)
        end
        for i_smp=1, #r_inst.samples do
          local s = r_inst.samples[i_smp]
          local note = clamp_note(i_smp - 1)  -- Clamp the note value
          s.sample_mapping.note_range = { note, note }
          s.sample_mapping.base_note  = note
        end
      end
      
      coroutine.yield()
    end

    if dialog and dialog.visible then
      dialog:close()
    end
    
    if imported_count < #mappings then
      renoise.app():show_status(string.format(
        "Imported %d instruments (%d into empty slots). %d presets were skipped.", 
        imported_count, empty_slots, #mappings - imported_count))
    else
      renoise.app():show_status(string.format(
        "SF2 import complete. Imported %d instruments (%d into empty slots).", 
        imported_count, empty_slots))
    end
    return true
  end
  
  -- Create and start the ProcessSlicer
  slicer = ProcessSlicer(process_import)
  slicer:start()
end


local function import_sf2_multitimbral(filepath)
  renoise.app():show_error("Multitimbral import not implemented.")
  return false
end

if renoise.tool():has_file_import_hook("sample", {"sf2"}) then
  renoise.tool():remove_file_import_hook("sample", {"sf2"})
  print("Removed old SF2 Import Hook")
end

local hook = {
  category = "sample",
  extensions = {"sf2"},
  invoke = import_sf2
}

if not renoise.tool():has_file_import_hook("sample", {"sf2"}) then
  renoise.tool():add_file_import_hook(hook)
end





-- Helper function to find or create Volume AHDSR device
local function setup_volume_ahdsr_device(instrument, sample_index)
    -- Ensure we have a modulation set
    if #instrument.sample_modulation_sets == 0 then
        instrument:insert_sample_modulation_set_at(1)
    end
    
    -- Get the modulation set for this sample
    local mod_set_index = instrument.samples[sample_index].modulation_set_index
    local mod_set = instrument.sample_modulation_sets[mod_set_index]
    
    -- Find existing Volume AHDSR device or create new one
    local ahdsr_device = nil
    for _, device in ipairs(mod_set.devices) do
        if device.name == "Volume AHDSR" then
            ahdsr_device = device
            break
        end
    end
    
    if not ahdsr_device then
        -- Create new Volume AHDSR device
        local device_index = #mod_set.devices + 1
        mod_set:insert_device_at("Volume AHDSR", device_index)
        ahdsr_device = mod_set.devices[device_index]
    end
    
    return ahdsr_device
end

-- Helper function to convert timecents to seconds
local function timecents_to_seconds(timecents)
    if timecents then
        -- Convert unsigned to signed if needed
        if timecents >= 32768 then 
            timecents = timecents - 65536
        end
        -- Convert timecents to seconds: seconds = 2^(timecents/1200)
        return 2^(timecents/1200)
    end
    return nil
end

-- Helper function to convert sustain centibels to 0-1 range
local function sustain_cb_to_level(centibels)
    if centibels then
        -- Convert centibels to decibels (divide by 10)
        local db = centibels / 10
        -- Convert dB to linear (0-1) scale
        return math.min(1, math.max(0, math.db2lin(db)))
    end
    return nil
end

-- Helper function to map envelope time to Renoise parameter range (0-1)
local function map_envelope_time(seconds)
    if not seconds then return nil end
    -- Renoise's envelope time parameters are mapped 0-1 to 0-20 seconds
    return math.min(1, math.max(0, seconds / 20))
end
