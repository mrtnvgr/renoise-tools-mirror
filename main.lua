--[[============================================================================
com.duncanhemingway.repeaternotation.xrnx (main.lua)
============================================================================]]--

--------------------------------------------------------------------------------
-- global declarations
--------------------------------------------------------------------------------

s = 0
the_gui = nil
notifier = {}
select_one = true
vb = renoise.ViewBuilder()

--------------------------------------------------------------------------------
-- menu entry
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Repeater Notation",
  invoke = function()
    if not the_gui then initialise() end
    if not the_gui or not the_gui.visible then the_gui = renoise.app():show_custom_dialog("Repeater Notation", dialog_content) end
  end
}

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- rounding values

function round(value)
  return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end

function round2(value)
  return value >= 0 and math.floor(value * 100 + 0.5) / 100 or math.ceil(value * 100 - 0.5) / 100
end

function round3(value) -- renoise internally uses bpm values at 3 decimal places
  return value >= 0 and math.floor(value * 1000 + 0.5) / 1000 or math.ceil(value * 1000 - 0.5) / 1000
end

-- add and remove notifiers

function add_notifier(observable, notifier, object)
  if object == nil then
    if not observable:has_notifier(notifier) then observable:add_notifier(notifier) end
  else
    if not observable:has_notifier(notifier, object) then observable:add_notifier(notifier, object) end
  end
end

function remove_notifier(observable, notifier, object)
  if object == nil then
    if observable:has_notifier(notifier) then observable:remove_notifier(notifier) end
  else
    if observable:has_notifier(notifier, object) then observable:remove_notifier(notifier, object) end
  end
end

-- initialise on tool launch or new song

initialise = function()
  s = renoise.song()
  --disable_buttons()
  if vb.views.instr.value > #s.instruments - 1 then vb.views.instr.value = #s.instruments - 1 end
  vb.views.repeater_track.value  = 1
  vb.views.repeater_device.value = 1

  --add_notifier(s.transport.lpb_observable, disable_buttons)
  add_notifier(renoise.tool().app_new_document_observable, initialise)
  add_notifier(s.tracks_observable, repeater_change, { source="track" }) -- notifier is never removed so object doesn't need to be registered
  notifier = { source="device", track=1 }                                -- need to register object so individual track notifiers can be removed
  add_notifier(s:track(1).devices_observable, repeater_change, notifier)

  populate_tracks()
  populate_devices(1, 0)
end

-- (can't use for selection_in_pattern since it's not observable) - disable buttons if the number of of notes required per line exceeds the 12 note-column limit

--function disable_buttons()
  --if vb.views.fraction.value * 4 / s.transport.lpb >= 192 then
       --vb.views.button.active = false
  --else vb.views.button.active = true
  --end
  
  --if s.transport.lpb > 3 then
    --vb.views.sixtyfour.active       = true
    --vb.views.sixtyfourT.active      = true
    --vb.views.onetwentyeight.active  = true
    --vb.views.onetwentyeightT.active = true
    --vb.views.onetwentyeightD.active = true
  --elseif s.transport.lpb == 3 then
    --vb.views.sixtyfour.active       = true
    --vb.views.sixtyfourT.active      = true
    --vb.views.onetwentyeight.active  = true
    --vb.views.onetwentyeightT.active = false
    --vb.views.onetwentyeightD.active = true
  --elseif s.transport.lpb == 2 then
    --vb.views.sixtyfour.active       = true
    --vb.views.sixtyfourT.active      = true
    --vb.views.onetwentyeight.active  = false
    --vb.views.onetwentyeightT.active = false
    --vb.views.onetwentyeightD.active = true
  --elseif s.transport.lpb == 1 then
    --vb.views.sixtyfour.active       = false
    --vb.views.sixtyfourT.active      = false
    --vb.views.onetwentyeight.active  = false
    --vb.views.onetwentyeightT.active = false
    --vb.views.onetwentyeightD.active = false
  --end
--end

-- create indexed table filled for each line

function fill_table(table)
  if table == nil then return end

  local value = table
  local itable = {}
  
  if type(table) == "table" then
    for k,v in ipairs(table) do itable[v.time] = v.value end
    for l = 1, s.selected_pattern.number_of_lines do
      if itable[l] ~= nil then value = itable[l]
      else itable[l] = value
      end
    end
  else
    for l = 1, s.selected_pattern.number_of_lines do
      itable[l] = value
    end
  end
  return itable
end

-- clamp Repeater Divisor calculation to upper limit of 128 and 2 decimal places

function clamp(d)
  if d > 128 then d = 128 end
  return string.format("%.2f", d)
end

-- insert notes into pattern/selection

function insert_notes(d, mode, divisor)
  if s.selected_track.type ~= 1 then
    renoise.app():show_status("Repeater Notation: Failed to insert notes. Selected track has no note columns.")
    renoise.app():show_warning("Cannot insert notes. Selected track has no note columns.")
    return
  end

  local sp = s.selected_pattern_index
  local st = s:track(s.selected_track_index)
  local delay = 256
  local note_count = 0
  local columns_needed = 0
  local sline = 1
  local eline = s.selected_pattern.number_of_lines
  local lpb_data = get_globalfx_data("lpb")

  if s.selection_in_pattern ~= nil then
    sline = s.selection_in_pattern.start_line
    eline = s.selection_in_pattern.end_line
  end

  if lpb_data == nil then
    lpb_data = {}
    lpb_data[1] = { time = 1, value = s.transport.lpb }
  end
  lpb_data = fill_table(lpb_data)

  -- trial run of note insertion to detect how many note columns would be needed

  for l = sline, eline do
    local c = 1
    
    if mode ~= nil and mode[l] == 0 then
      delay = 256
    else
      delay = delay - 256

      if l > 1 and mode ~= nil and s:track(vb.views.repeater_track.value):device(vb.views.repeater_device.value - 1):parameter(3).value == 1 and (mode[l] ~= mode[l - 1] or divisor[l] ~= divisor[l - 1]) then
        delay = 0
      end

      while round(delay) < 256 do
        
        if mode ~= nil then
          if     mode[l] == 1 then d = 4096 / clamp(2^(divisor[l] / 32))
          elseif mode[l] == 2 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) 
          elseif mode[l] == 3 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) * 2/3
          elseif mode[l] == 4 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) * 1.5
          end
        end
        
        delay = delay + d * lpb_data[l] / 4

        local n = 1
        while delay > 256 * n and l + (n - 1) < eline do
          delay = (256 * n) + ((delay - (256 * n)) * (4 / lpb_data[l + (n - 1)])) * lpb_data[l + n] / 4
          n = n + 1
        end
        
        if c > columns_needed then columns_needed = c end
        c = c + 1
      end
    end
  end

  if columns_needed > 12 then
    renoise.app():show_status("Repeater Notation: Failed to insert notes. 12 note-column limit exceeded.")
    renoise.app():show_warning("LPB is too low within the pattern/selection. The required amount of notes would exceed the 12 note-column limit.")
    return
  end
  
  -- do note insertion for real
  
  delay = 256
  st.delay_column_visible = true
  if columns_needed > st.visible_note_columns then st.visible_note_columns = columns_needed end
  for l = sline, eline do
    for c = 1, 12 do s:pattern(sp):track(s.selected_track_index):line(l):note_column(c):clear() end
  end

  for l = sline, eline do
    local c = 1
    
    if mode ~= nil and mode[l] == 0 then -- if mode is off then place no note
      delay = 256
    else
      delay = delay - 256

      if l > 1 and mode ~= nil and s:track(vb.views.repeater_track.value):device(vb.views.repeater_device.value - 1):parameter(3).value == 1 and (mode[l] ~= mode[l - 1] or divisor[l] ~= divisor[l - 1]) then
        delay = 0
      end

      while round(delay) < 256 do
        
        local column = s:pattern(sp):track(s.selected_track_index):line(l):note_column(c)
        column.note_value       = vb.views.note.value - 1
        column.instrument_value = vb.views.instr.value
      
        if vb.views.vol.value == 128 then
          column.volume_value = 255
        else
          column.volume_value = vb.views.vol.value
          st.volume_column_visible = true
        end
      
        if vb.views.pan.value == 64 then
          column.panning_value = 255
        else
          column.panning_value = vb.views.pan.value
          st.panning_column_visible = true
        end
      
        if vb.views.fx.value > 1 then
          column.effect_number_string = vb.views.fx.items[vb.views.fx.value]
          column.effect_amount_value  = vb.views.fxvalue.value
          st.sample_effects_column_visible = true
        end
      
        column.delay_value = round(delay)
      
        if mode ~= nil then
          if     mode[l] == 1 then d = 4096 / clamp(2^(divisor[l] / 32))
          elseif mode[l] == 2 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) 
          elseif mode[l] == 3 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) * 2/3
          elseif mode[l] == 4 then d = 4096 / clamp(2^(math.floor(divisor[l] / 32))) * 1.5
          end
        end
        
        delay = delay + d * lpb_data[l] / 4

        local n = 1
        while delay > 256 * n and l + (n - 1) < eline do -- if delay pushes past the curent line, calculate the extra delay using the lpb of the next line(s)
          delay = (256 * n) + ((delay - (256 * n)) * (4 / lpb_data[l + (n - 1)])) * lpb_data[l + n] / 4
          n = n + 1
        end
        
        c = c + 1
        note_count = note_count + 1
      end
    end
    renoise.app():show_status("Repeater Notation: Successfully inserted " .. note_count .. " notes into " .. columns_needed .. " note columns.")
  end
end

-- repeater selection

function repeater_change(td, change)
  local d = 1 -- devices need +/- 1 to account for None
  if td.source == "track" then d = 0 end
  
  --if change.type ~= "swap" then print(td.source, change.type, change.index, td.track) -- debug
  --else print(td.source, change.type, change.index1, change.index2, td.track) end
  if change.type == "insert" and change.index <= vb.views["repeater_" .. td.source].value - d then
    if td.source == "device" then -- create temporary buffer
      local items = vb.views.repeater_device.items
      items[#items + 1] = "temp"
      vb.views.repeater_device.items = items
    end
    select_one = false
    vb.views["repeater_" .. td.source].value = vb.views["repeater_" .. td.source].value + 1
    select_one = true
  end

  if change.type == "remove" and change.index <= vb.views["repeater_" .. td.source].value - d then
    if change.index < vb.views["repeater_" .. td.source].value - d then
      select_one = false
      vb.views["repeater_" .. td.source].value = vb.views["repeater_" .. td.source].value - 1
      select_one = true
    else
      if td.source == "track" then
        vb.views.repeater_track.value = 1
        if notifier.track == 1 then -- gui notifier not triggered if value was already 1, so do the necessary changes here
          notifier.track = 1
          add_notifier(s:track(1).devices_observable, repeater_change, notifier) -- old track was deleted, so notifier was automatically removed
        end
      end
      vb.views.repeater_device.value = 1
    end
  end

  if change.type == "swap" and (change.index1 == vb.views["repeater_" .. td.source].value - d or change.index2 == vb.views["repeater_" .. td.source].value - d) then
    select_one = false
    if change.index1 == vb.views["repeater_" .. td.source].value - d then
      vb.views["repeater_" .. td.source].value = change.index2 + d
    else
      vb.views["repeater_" .. td.source].value = change.index1 + d
    end
    select_one = true
  end

  if td.source == "track" then populate_tracks()
  else populate_devices(notifier.track, 0)
  end
end

function populate_tracks()
  local tracks = {}
  local mst = 0
  for t = 1, #s.tracks do
    add_notifier(s:track(t).name_observable, update_track_names)
    if     s:track(t).type == 1 or s:track(t).type == 4 then tracks[t] = ("%02d"):format(tostring(t)) .. ": " .. s:track(t).name
    elseif s:track(t).type == 2 then tracks[t] = "Mst: " .. s:track(t).name mst = t
    else   tracks[t] = "S" .. tostring(t - mst) .. ": " .. s:track(t).name 
    end
  end
  vb.views.repeater_track.items   = tracks
  vb.views.repeater_track.tooltip = vb.views.repeater_track.items[vb.views.repeater_track.value]
end

function populate_devices(t, oldt)
  local d = 0
  local devices = { "None", "Mixer" }
  
  for d = 2, #s:track(t).devices do
    devices[d + 1] = s:track(t):device(d).display_name
    add_notifier(s:track(t):device(d).display_name_observable, update_device_names, notifier)
  end
  vb.views.repeater_device.items = devices

  if oldt ~= 0 then
    for d = 2, #s:track(oldt).devices do
      remove_notifier(s:track(oldt):device(d).display_name_observable, update_device_names, notifier)
    end
  end
end

function update_track_names()
  populate_tracks()
end

function update_device_names(temp_notifier)
  populate_devices(temp_notifier.track, 0)
end

-- get automation and effect commands

function get_current_pattern_automation(track, device, parameter)
  local automation = {}
  local tmpa = s:pattern(s.selected_pattern_index):track(track):find_automation(s:track(track):device(device):parameter(parameter))
  local newv = true
  local bpmmin = 20  -- minimum bpm changed from 32 to 20 in v3.4
  local bpmrng = 979 -- range of values (max minus min)
  local v1, _, v2 = renoise.RENOISE_VERSION:match'(%d+)(%.)(%d+)'
  
  if tonumber(v1) < 3 or (tonumber(v1) == 3 and tonumber(v2) < 4) then
    newv = false
    bpmmin = 32
    bpmrng = 967
  end
  
  if tmpa == nil then return end
  for n, a in ipairs(tmpa.points) do
    if     tmpa.dest_parameter.name == "LPB" then automation[n] = { time = a.time, value = round(a.value * 255) + 1 }
    elseif tmpa.dest_parameter.name == "BPM" then automation[n] = { time = a.time, value = round3(a.value * bpmrng + bpmmin) }
    elseif tmpa.dest_parameter.name == "TPL" then automation[n] = { time = a.time, value = round(a.value * 15) + 1 }
    else                                          automation[n] = { time = a.time, value = a.value }
    end
  end
  return automation    
end

function get_previous_pattern_automation(track, device, parameter)
  local automation = {}
  local newv = true
  local bpmmin = 20  -- minimum bpm changed from 32 to 20 in v3.4
  local bpmrng = 979 -- range of values (max minus min)
  local v1, _, v2 = renoise.RENOISE_VERSION:match'(%d+)(%.)(%d+)'
  
  if tonumber(v1) < 3 or (tonumber(v1) == 3 and tonumber(v2) < 4) then
    newv = false
    bpmmin = 32
    bpmrng = 967
  end
  
  for p = s.selected_pattern_index - 1, 1, -1 do
    local tmpa = s:pattern(p):track(track):find_automation(s:track(track):device(device):parameter(parameter))
    if tmpa ~= nil then
      if     tmpa.dest_parameter.name == "LPB" then return { pattern = p, time = tmpa.points[#tmpa.points].time, value = round(tmpa.points[#tmpa.points].value * 255) + 1 }
      elseif tmpa.dest_parameter.name == "BPM" then return { pattern = p, time = tmpa.points[#tmpa.points].time, value = round3(tmpa.points[#tmpa.points].value * bpmrng + bpmmin) }
      elseif tmpa.dest_parameter.name == "TPL" then return { pattern = p, time = tmpa.points[#tmpa.points].time, value = round(tmpa.points[#tmpa.points].value * 15) + 1 }
      else                                          return { pattern = p, time = tmpa.points[#tmpa.points].time, value = tmpa.points[#tmpa.points].value }
      end
    end
  end
end

function get_current_pattern_effect_commands(track, effect)
  local effect_commands = {}
  local n = 1

  if effect:sub(1,1) == "Z" then
    for pos, fx in s.pattern_iterator:effect_columns_in_pattern(s.selected_pattern_index, 1) do
      if tostring(fx):sub(1,2) == effect and tostring(fx):sub(3,4) ~= "00" then -- this version of the function excludes 00, change this when used for other global commands
        effect_commands[n] = { time = pos.line, value = tonumber(tostring(fx):sub(3,4), 16) }
        n = n + 1
      end
    end
  else
    for pos, fx in s.pattern_iterator:effect_columns_in_pattern_track(s.selected_pattern_index, track, 1) do
      if tostring(fx):sub(1,2) == effect then
        effect_commands[n] = { time = pos.line, value = tonumber(tostring(fx):sub(3,4), 16) }
        n = n + 1
      end
    end
  end

  return effect_commands
end

function get_previous_pattern_effect_commands(track, effect)
  local effect_commands = {}
  
  if effect:sub(1,1) == "Z" then
    for p = s.selected_pattern_index - 1, 1, -1 do
      for pos, fx in s.pattern_iterator:effect_columns_in_pattern(p, 1) do
        if tostring(fx):sub(1,2) == effect and tostring(fx):sub(3,4) ~= "00" then -- this version of the function excludes 00, change this when used for other global commands
          effect_commands = { pattern = p, time = pos.line, value = tonumber(tostring(fx):sub(3,4), 16) }
        end
      end
      if next(effect_commands) ~= nil then return effect_commands end
    end
  else
    for p = s.selected_pattern_index - 1, 1, -1 do
      for pos, fx in s.pattern_iterator:effect_columns_in_pattern_track(p, track, 1) do
        if tostring(fx):sub(1,2) == effect then
          effect_commands = { pattern = p, time = pos.line, value = tonumber(tostring(fx):sub(3,4), 16) }
        end
      end
      if next(effect_commands) ~= nil then return effect_commands end
    end
  end
end

function get_previous_value(track, device, parameter, effect)
  local previousa  = get_previous_pattern_automation(track, device, parameter)
  local previousfx = get_previous_pattern_effect_commands(track, effect)
  
  local newv = true
  local v1, _, v2 = renoise.RENOISE_VERSION:match'(%d+)(%.)(%d+)'
  if tonumber(v1) < 3 or (tonumber(v1) == 3 and tonumber(v2) < 4) then newv = false end

  if newv == true then
    if previousa ~= nil then
      if previousfx ~= nil then
        if     previousa.pattern  > previousfx.pattern then return previousa.value
        elseif previousfx.pattern > previousa.pattern  then return previousfx.value
        elseif previousa.time    >= previousfx.time    then return previousa.value
        else                                                return previousfx.value
        end
      else return previousa.value
      end
    elseif previousfx ~= nil then return previousfx.value
    else return
    end
  else
    if previousa ~= nil then
      if previousfx ~= nil then
        if   previousa.pattern  >= previousfx.pattern then return previousa.value
        else                                               return previousfx.value
        end
      else return previousa.value
      end
    elseif previousfx ~= nil then return previousfx.value
    else return
    end
  end
end

function consolidate_automation_effect_commands(automation, effect_commands)
  if automation == nil or next(automation) == nil then return effect_commands end
  if next(effect_commands) == nil then return automation end
  
  local tmpa  = {}
  local tmpfx = {}
  for k,v in ipairs(automation) do      tmpa[v.time]  = v.value end
  for k,v in ipairs(effect_commands) do tmpfx[v.time] = v.value end
  for k,v in pairs(tmpa) do             tmpfx[k] = v end

  local n = 1
  local effect_commands = {}  
  for k,v in pairs(tmpfx) do
    table.insert(effect_commands, n, { time = k, value = v })
    n = n + 1
  end
  table.sort(effect_commands, function(a,b) return a.time < b.time end)
  return effect_commands
end

function get_globalfx_data(type)
  local sp = s.selected_pattern_index
  local mst = 0
  local effect = 0
  local automation = {}
  local effect_commands = {}
  
  if     type == "bpm" then type = 6 effect = "ZT"
  elseif type == "lpb" then type = 7 effect = "ZL"
  elseif type == "tpl" then type = 8 effect = "ZK"
  end
  
  local newv = true
  local v1, _, v2 = renoise.RENOISE_VERSION:match'(%d+)(%.)(%d+)'
  if tonumber(v1) < 3 or (tonumber(v1) == 3 and tonumber(v2) < 4) then newv = false end

  for n, t in ripairs(s.tracks) do
    if t.type == 2 then
      mst = n
      automation = get_current_pattern_automation(mst, 1, type)
      break
    end
  end

  if newv == true or (newv == false and automation == nil) then
    effect_commands = get_current_pattern_effect_commands(_, effect)
  end
  
  if automation == nil and next(effect_commands) == nil and sp > 1 then
    local previous_value = get_previous_value(mst, 1, type, effect)
    if previous_value ~= nil then
      table.insert(effect_commands, 1, { time = 1, value = previous_value })
    end
  end

  effect_commands = consolidate_automation_effect_commands(automation, effect_commands)
  if next(effect_commands) == nil then return end
  
  if effect_commands[1].time ~= 1 then
    if sp > 1 then
      local previous_value = get_previous_value(mst, 1, type, effect)
      if previous_value ~= nil then
        table.insert(effect_commands, 1, { time = 1, value = previous_value })
      else
        table.insert(effect_commands, 1, { time = 1, value = effect_commands[1].value })
      end
    else
      table.insert(effect_commands, 1, { time = 1, value = effect_commands[1].value })
    end
  end
  return effect_commands
end

function get_effect_commands_only(track, device, parameter)
  local sp = s.selected_pattern_index
  local effect = tostring(device .. parameter)
  local effect_commands = get_current_pattern_effect_commands(track, effect)

  if next(effect_commands) == nil and sp > 1 then
      local previous_value = get_previous_pattern_effect_commands(track, effect)
      if previous_value == nil or next(previous_value) == nil then return end
      table.insert(effect_commands, 1, { time = 1, value = previous_value.value })
  end

  if next(effect_commands) == nil or effect_commands[1].value == nil then return end

  if effect_commands[1].time ~= 1 then
    if sp > 1 then
      local previous_value = get_previous_pattern_effect_commands(track, effect)
      if previous_value ~= nil then
        table.insert(effect_commands, 1, { time = 1, value = previous_value.value })
      else
        table.insert(effect_commands, 1, { time = 1, value = effect_commands[1].value })
      end
    else
      table.insert(effect_commands, 1, { time = 1, value = effect_commands[1].value })
    end
  end

  return effect_commands
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

gui_note = vb:popup {
  id = "note",
  width = 46,
  value = 49,
  items = {
    "C-0", "C#0", "D-0", "D#0", "E-0", "F-0", "F#0", "G-0", "G#0", "A-0", "A#0", "B-0",
    "C-1", "C#1", "D-1", "D#1", "E-1", "F-1", "F#1", "G-1", "G#1", "A-1", "A#1", "B-1",
    "C-2", "C#2", "D-2", "D#2", "E-2", "F-2", "F#2", "G-2", "G#2", "A-2", "A#2", "B-2",
    "C-3", "C#3", "D-3", "D#3", "E-3", "F-3", "F#3", "G-3", "G#3", "A-3", "A#3", "B-3",
    "C-4", "C#4", "D-4", "D#4", "E-4", "F-4", "F#4", "G-4", "G#4", "A-4", "A#4", "B-4",
    "C-5", "C#5", "D-5", "D#5", "E-5", "F-5", "F#5", "G-5", "G#5", "A-5", "A#5", "B-5",
    "C-6", "C#6", "D-6", "D#6", "E-6", "F-6", "F#6", "G-6", "G#6", "A-6", "A#6", "B-6",
    "C-7", "C#7", "D-7", "D#7", "E-7", "F-7", "F#7", "G-7", "G#7", "A-7", "A#7", "B-7",
    "C-8", "C#8", "D-8", "D#8", "E-8", "F-8", "F#8", "G-8", "G#8", "A-8", "A#8", "B-8"
  }
}

gui_instr = vb:valuebox {
  id = "instr",
  width = 46,
  min = 0,
  max = 254, -- only 255 instruments supported (FE)
  steps = {1, 16},
  tostring = function(value) return tostring(("%02X"):format(value)) end,
  tonumber = function(str)   return tonumber(str, 16) end,
  notifier = function(value) if value > #s.instruments - 1 then vb.views.instr.value = #s.instruments - 1 end end
}

gui_vol = vb:valuebox {
  id = "vol",
  width = 46,
  min = 0,
  max = 128,
  value = 128,
  steps = {1, 16},
  tostring = function(value) return tostring(("%02X"):format(value)) end,
  tonumber = function(str)   return tonumber(str, 16) end,
}

gui_pan = vb:valuebox {
  id = "pan",
  width = 46,
  min = 0,
  max = 128,
  value = 64,
  steps = {1, 16},
  tostring = function(value) return tostring(("%02X"):format(value)) end,
  tonumber = function(str)   return tonumber(str, 16) end,
}

gui_fx = vb:popup {
  id = "fx",
  width = 46,
  items = { "00", "0A", "0U", "0D", "0G", "0I", "0O", "0C", "0Q", "0M", "0S", "0B", "0R", "0Y", "0Z", "0V", "0T", "0N", "0E" }
}

gui_fxvalue = vb:valuebox {
  id = "fxvalue",
  width = 46,
  min = 0,
  max = 255,
  value = 00,
  steps = {1, 16},
  tostring = function(value) return tostring(("%02X"):format(value)) end,
  tonumber = function(str)   return tonumber(str, 16) end,
}

gui_button = vb:button {
  id = "button",
  height = 29,
  width = 94,
  text = "1/23.97",
  pressed = function() insert_notes(4096 / vb.views.fraction.value) end
}

gui_slider = vb:slider {
  id = "slider",
  width = 166,
  min = 1,
  max = 128,
  value = 23.97,
  steps = {1, 10},
  notifier = function(value)
    vb.views.fraction.value = round2(value)
    vb.views.button.text = "1/" .. round2(value)
  end
}

gui_fraction = vb:valuefield {
  id = "fraction",
  min = 1,
  max = 128,
  value = 23.97,
  tostring = function(value) return ("%.2f"):format(tostring(round2(value))) end,
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    vb.views.slider.value = round2(value)
  end
}

gui_repeater_track = vb:popup {
  id = "repeater_track",
  width = 120,
  tooltip = "01: Track 01",
  notifier = function(t)
    if select_one then vb.views.repeater_device.value = 1 end
    populate_devices(t, notifier.track)
    if notifier.track <= #s.tracks then -- in case right-most track was deleted
      remove_notifier(s:track(notifier.track).devices_observable, repeater_change, notifier)
    end
    notifier.track = t
    add_notifier(s:track(t).devices_observable, repeater_change, notifier)
    vb.views.repeater_track.tooltip = vb.views.repeater_track.items[vb.views.repeater_track.value]
  end
}

gui_repeater_device = vb:popup {
  id = "repeater_device",
  width = 120,
  notifier = function()
    populate_devices(notifier.track, 0)
    if vb.views.repeater_device.value > 1 and s:track(notifier.track):device(vb.views.repeater_device.value - 1).name == "Repeater" then
      vb.views.repeater_insert_notes.active = true
    else
      vb.views.repeater_insert_notes.active = false
    end
  end
}

gui_repeater_insert_notes = vb:button {
  id = "repeater_insert_notes",
  active = false,
  text = "Insert Notes",
  tooltip = "Insert notes matching the timing of the linked Repeater's parameters.\n This will make use of EFFECT COMMANDS ONLY - DOES NOT USE GRAPHICAL AUTOMATION.",
  notifier = function()
    local mode    = get_effect_commands_only(vb.views.repeater_track.value, vb.views.repeater_device.value - 2, 1)
    local divisor = get_effect_commands_only(vb.views.repeater_track.value, vb.views.repeater_device.value - 2, 2)
    
    if mode == nil and s:track(vb.views.repeater_track.value):device(vb.views.repeater_device.value - 1):parameter(1).value == 0 then
      renoise.app():show_status("Repeater Notation: Failed to insert notes. Repeater Mode never changes from 'Off'.")
      renoise.app():show_warning("No notes were inserted. The Repeater's Mode is set to 'Off' and no effect commands were detected to change this.")
      return
    end
    
    if mode    == nil then mode    = s:track(vb.views.repeater_track.value):device(vb.views.repeater_device.value - 1):parameter(1).value end
    if divisor == nil then divisor = s:track(vb.views.repeater_track.value):device(vb.views.repeater_device.value - 1):parameter(2).value * 256 end
    mode    = fill_table(mode)
    divisor = fill_table(divisor)
    insert_notes(9999, mode, divisor)
  end
}

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
dialog_content = vb:column {
  margin = DEFAULT_MARGIN,
  
  vb:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    
  vb:row {
    style = "panel",
    width = "100%",
    margin = 3,
    vb:space { height = 8 },
    
    vb:horizontal_aligner {
      width = "100%",
      vb:text { text = "Note" }, vb:space { width = 3 }, gui_note, gui_instr,
      vb:space { width = 3 }, vb:text { text = "VolPan" }, vb:space { width = 3 }, gui_vol, gui_pan,
      vb:space { width = 3 }, vb:text { text = "FX" }, gui_fx, gui_fxvalue
    },
  },
  vb:space { height = 1 },
    
    vb:horizontal_aligner {
      vb:column{
        vb:horizontal_aligner {
          gui_button, vb:space { width = 5 },
          vb:vertical_aligner {
            mode = "center",
            vb:horizontal_aligner {
              vb:text { text = "Divisor" }, vb:space { width = 5 },
              gui_slider, vb:space { width = 5 },
              gui_fraction,
            },
          }
        },
        vb:horizontal_aligner {
          vb:button { height = 29, width = 47, text = "1/1",   pressed = function() insert_notes(4096) end },
          vb:button { height = 29, width = 47, text = "1/2",   pressed = function() insert_notes(2048) end },
          vb:button { height = 29, width = 47, text = "1/4",   pressed = function() insert_notes(1024) end },
          vb:button { height = 29, width = 47, text = "1/8",   pressed = function() insert_notes(512)  end },
          vb:button { height = 29, width = 47, text = "1/16",  pressed = function() insert_notes(256)  end },
          vb:button { height = 29, width = 47, text = "1/32",  pressed = function() insert_notes(128)  end },
          vb:button { height = 29, width = 47, text = "1/64",  pressed = function() insert_notes(64)   end, id = "sixtyfour" },
          vb:button { height = 29, width = 47, text = "1/128", pressed = function() insert_notes(32)   end, id = "onetwentyeight" }
        },
        vb:horizontal_aligner {
          vb:button { height = 29, width = 47, text = "1/1T",   pressed = function() insert_notes(4096 * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/2T",   pressed = function() insert_notes(2048 * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/4T",   pressed = function() insert_notes(1024 * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/8T",   pressed = function() insert_notes(512  * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/16T",  pressed = function() insert_notes(256  * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/32T",  pressed = function() insert_notes(128  * 2/3) end },
          vb:button { height = 29, width = 47, text = "1/64T",  pressed = function() insert_notes(64   * 2/3) end, id = "sixtyfourT" },
          vb:button { height = 29, width = 47, text = "1/128T", pressed = function() insert_notes(32   * 2/3) end, id = "onetwentyeightT" }
        },
        vb:horizontal_aligner {
          vb:button { height = 29, width = 47, text = "1/1D",   pressed = function() insert_notes(6144) end },
          vb:button { height = 29, width = 47, text = "1/2D",   pressed = function() insert_notes(3072) end },
          vb:button { height = 29, width = 47, text = "1/4D",   pressed = function() insert_notes(1536) end },
          vb:button { height = 29, width = 47, text = "1/8D",   pressed = function() insert_notes(768)  end },
          vb:button { height = 29, width = 47, text = "1/16D",  pressed = function() insert_notes(384)  end },
          vb:button { height = 29, width = 47, text = "1/32D",  pressed = function() insert_notes(192)  end },
          vb:button { height = 29, width = 47, text = "1/64D",  pressed = function() insert_notes(96)   end },
          vb:button { height = 29, width = 47, text = "1/128D", pressed = function() insert_notes(48)   end, id = "onetwentyeightD" }
        },
      },
    },
  },
  vb:space { height = 5 },
  vb:row {
    style = "panel",
    width = "100%",
    margin = 3,
    
    vb:horizontal_aligner {
      width = "100%",
      vb:space { width = 4 },  vb:text { text = "Repeater" }, vb:space { width = 4 }, gui_repeater_track, vb:space { width = 5 }, gui_repeater_device,
      vb:space { width = 5 }, gui_repeater_insert_notes
    },
  },
}
