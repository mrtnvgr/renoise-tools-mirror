--[[============================================================================
com.duncanhemingway.drawtomator.xrnx (main.lua)
============================================================================]]--

--------------------------------------------------------------------------------
-- global declarations
--------------------------------------------------------------------------------

s = 0
time  = 0
time2 = 0
clock  = 0
clock2 = 0
pause_time  = 0
pause_time2 = 0
xnotifier = {}
ynotifier = {}
xnotifier2 = {}
ynotifier2 = {}
log  = { time={}, xy={} }
log2 = { time={}, xy={} }
manual = true
doofer = nil
the_gui = nil
select_one = true
vb = renoise.ViewBuilder()

--------------------------------------------------------------------------------
-- menu entry
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Drawtomator",
  invoke = function()
    if not the_gui then initialise() end
    if not the_gui or not the_gui.visible then the_gui = renoise.app():show_custom_dialog("Drawtomator", dialog_content) end
  end
}

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- round float values

function round(value)
  return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end

function round3(value) -- renoise internally uses bpm values at 3 decimal places
  return value >= 0 and math.floor(value * 1000 + 0.5) / 1000 or math.ceil(value * 1000 - 0.5) / 1000
end

function round8(value)
  return value >= 0 and math.floor(value * 100000000 + 0.5) / 100000000 or math.ceil(value * 100000000 - 0.5) / 100000000
end

-- get sign from number

function sign(value)
   if     value < 0 then return -1
   elseif value > 0 then return 1
   else return 0
   end
end

-- map 0-1 from xypad to parameter range

function map_range(xy, value, lr)
  local min = s:track(vb.views[xy .. "dest_track" .. lr].value):device(vb.views[xy .. "dest_device" .. lr].value - 1):parameter(vb.views[xy .. "dest_parameter" .. lr].value - 1).value_min
  local max = s:track(vb.views[xy .. "dest_track" .. lr].value):device(vb.views[xy .. "dest_device" .. lr].value - 1):parameter(vb.views[xy .. "dest_parameter" .. lr].value - 1).value_max
  return min + value * (max - min)
end

-- get Lines automation scaling at position between points

function scaling_at_position(position, scaling)
  if (scaling == 0) then return position;
  else
    if (scaling > 0) then return     math.pow(    position, 1 + math.pow( scaling, math.exp(1)/2) * 16)
    else                  return 1 - math.pow(1 - position, 1 + math.pow(-scaling, math.exp(1)/2) * 16)
    end
  end
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
  if vb.views.pad1x0y0 == nil then
    for n = 1, 2 do
      local lr = ""
      if n == 2 then lr = "2" end
      local canvas = vb:column {}
      for y = 53, 0, -1 do
        local row = vb:row {}
        for x = 0, 53 do
          row:add_child(
            vb:bitmap {
              id = "pad" .. n .. "x" .. tostring(x) .. "y" .. tostring(y),
              bitmap = "images/black.bmp",
              mode = vb.views["drawing_colour" .. lr].items[vb.views["drawing_colour" .. lr].value]:lower() .. "_color"
            }
          )
        end
        canvas:add_child(row)
      end
      _G["gui_xypad" .. lr]:add_child(canvas)
    end
  end

  s = renoise.song()
  vb.views.xdest_track.value      = 1
  vb.views.ydest_track.value      = 1
  vb.views.xdest_device.value     = 1
  vb.views.ydest_device.value     = 1
  vb.views.xdest_parameter.value  = 1
  vb.views.ydest_parameter.value  = 1
  vb.views.xdest_track2.value     = 1
  vb.views.ydest_track2.value     = 1
  vb.views.xdest_device2.value    = 1
  vb.views.ydest_device2.value    = 1
  vb.views.xdest_parameter2.value = 1
  vb.views.ydest_parameter2.value = 1
  vb.views.insert_midi_device.active = true -- reset these for new song
  vb.views.insert_track.active       = true
  vb.views.detect_midi_device.active = true

  add_notifier(renoise.tool().app_new_document_observable, initialise)
  add_notifier(s.tracks_observable, dest_change,  { source="track" })  -- notifier is never removed so object doesn't need to be registered
  add_notifier(s.tracks_observable, dest_change2, { source="track" })
  xnotifier  = { source="device", xy="x", track=1 } -- need to register object so individual track notifiers can be removed
  ynotifier  = { source="device", xy="y", track=1 }
  xnotifier2 = { source="device", xy="x", track=1 }
  ynotifier2 = { source="device", xy="y", track=1 }
  add_notifier(s:track(1).devices_observable, dest_change, xnotifier)
  add_notifier(s:track(1).devices_observable, dest_change, ynotifier)
  add_notifier(s:track(1).devices_observable, dest_change2, xnotifier2)
  add_notifier(s:track(1).devices_observable, dest_change2, ynotifier2)
  populate_tracks()
  populate_devices_parameters("x", 1, 0, "")
  populate_devices_parameters("y", 1, 0, "")
  populate_devices_parameters("x", 1, 0, "2")
  populate_devices_parameters("y", 1, 0, "2")
end

-- drawing functions

function record()
  if log.time[1] == nil then
    log.time[1] = 0
    log.xy[1] = { x=vb.views.xypad.value.x, y=vb.views.xypad.value.y }
    renoise.tool():remove_timer(record)
    renoise.tool():add_timer(record, vb.views.recording_interval.value)
    clock = os.clock()
    return
  end
  time = time + round((os.clock() - clock) * 1000)
  log.time[#log.time + 1] = time
  log.xy[#log.xy + 1]     = { x=vb.views.xypad.value.x, y=vb.views.xypad.value.y }
  local new_x = round(vb.views.xypad.value.x * 53)
  local new_y = round(vb.views.xypad.value.y * 53)
  local old_x = round(log.xy[#log.xy - 1].x  * 53)
  local old_y = round(log.xy[#log.xy - 1].y  * 53)
  local dif_x = math.abs(new_x - old_x)
  local dif_y = math.abs(new_y - old_y)
  vb.views["pad1x" .. tostring(new_x) .. "y" .. tostring(new_y)].bitmap = "images/grey.bmp"
  clock = os.clock()

  if dif_x > 1 or dif_y > 1 then -- if necessary, draw line between old and new points
    local skip_x = 0
    local skip_y = 0
    while new_x ~= old_x or new_y ~= old_y do
      if dif_x > dif_y then skip_y = skip_y + math.min(dif_x, dif_y) / math.max(dif_x, dif_y) -- an axis with less points to move will skip some steps while the other axis moves every step
      else                  skip_x = skip_x + math.min(dif_x, dif_y) / math.max(dif_x, dif_y)
      end
      if skip_x <= 0 or skip_x >= 1 then
        new_x = new_x + sign((old_x - new_x))
        skip_x = skip_x - 1
      end
      if skip_y <= 0 or skip_y >= 1 then
        new_y = new_y + sign((old_y - new_y))
        skip_y = skip_y - 1
      end
      vb.views["pad1x" .. tostring(new_x) .. "y" .. tostring(new_y)].bitmap = "images/grey.bmp"
      if old_x == new_x + sign((old_x - new_x)) and old_y == new_y + sign((old_y - new_y)) then break end -- avoid potential ugly side-step next to old point
    end
  end
end

function replay()
  for c, t in ipairs(log.time) do
    if t > time then
      manual = false
      local time_percent = (time - log.time[c - 1]) / (log.time[c] - log.time[c - 1])
      vb.views.xypad.value = { x=log.xy[c - 1].x + ((log.xy[c].x - log.xy[c - 1].x) * time_percent), y=log.xy[c - 1].y + ((log.xy[c].y - log.xy[c - 1].y) * time_percent) }
      manual = true
      time = time + (round((os.clock() - clock) * 1000)) * (round(vb.views.replay_speed.value) * 0.01)
      clock = os.clock()
      return
    end
  end
  manual = false
  vb.views.xypad.value = { x=log.xy[#log.xy].x, y=log.xy[#log.xy].y } -- move to final position
  vb.views.xypad.value = { x=log.xy[1].x, y=log.xy[1].y }             -- move to first position instantly to avoid waiting for interval
  manual = true
  time = 0
  clock = os.clock()
end

function record2()
  if log2.time[1] == nil then
    log2.time[1] = 0
    log2.xy[1] = { x=vb.views.xypad2.value.x, y=vb.views.xypad2.value.y }
    renoise.tool():remove_timer(record2)
    renoise.tool():add_timer(record2, vb.views.recording_interval2.value)
    clock2 = os.clock()
    return
  end
  time2 = time2 + round((os.clock() - clock2) * 1000)
  log2.time[#log2.time + 1] = time2
  log2.xy[#log2.xy + 1]     = { x=vb.views.xypad2.value.x, y=vb.views.xypad2.value.y }
  local new_x = round(vb.views.xypad2.value.x * 53)
  local new_y = round(vb.views.xypad2.value.y * 53)
  local old_x = round(log2.xy[#log2.xy - 1].x  * 53)
  local old_y = round(log2.xy[#log2.xy - 1].y  * 53)
  local dif_x = math.abs(new_x - old_x)
  local dif_y = math.abs(new_y - old_y)
  vb.views["pad2x" .. tostring(new_x) .. "y" .. tostring(new_y)].bitmap = "images/grey.bmp"
  clock2 = os.clock()

  if dif_x > 1 or dif_y > 1 then -- if necessary, draw line between old and new points
    local skip_x = 0
    local skip_y = 0
    while new_x ~= old_x or new_y ~= old_y do
      if dif_x > dif_y then skip_y = skip_y + math.min(dif_x, dif_y) / math.max(dif_x, dif_y) -- an axis with less points to move will skip some steps while the other axis moves every step
      else                  skip_x = skip_x + math.min(dif_x, dif_y) / math.max(dif_x, dif_y)
      end
      if skip_x <= 0 or skip_x >= 1 then
        new_x = new_x + sign((old_x - new_x))
        skip_x = skip_x - 1
      end
      if skip_y <= 0 or skip_y >= 1 then
        new_y = new_y + sign((old_y - new_y))
        skip_y = skip_y - 1
      end
      vb.views["pad2x" .. tostring(new_x) .. "y" .. tostring(new_y)].bitmap = "images/grey.bmp"
      if old_x == new_x + sign((old_x - new_x)) and old_y == new_y + sign((old_y - new_y)) then break end -- avoid potential ugly side-step next to old point
    end
  end
end

function replay2()
  for c, t in ipairs(log2.time) do
    if t > time2 then
      manual = false
      local time_percent = (time2 - log2.time[c - 1]) / (log2.time[c] - log2.time[c - 1])
      vb.views.xypad2.value = { x=log2.xy[c - 1].x + ((log2.xy[c].x - log2.xy[c - 1].x) * time_percent), y=log2.xy[c - 1].y + ((log2.xy[c].y - log2.xy[c - 1].y) * time_percent) }
      manual = true
      time2 = time2 + (round((os.clock() - clock2) * 1000)) * (round(vb.views.replay_speed2.value) * 0.01)
      clock2 = os.clock()
      return
    end
  end
  manual = false
  vb.views.xypad2.value = { x=log2.xy[#log2.xy].x, y=log2.xy[#log2.xy].y } -- move to final position
  vb.views.xypad2.value = { x=log2.xy[1].x, y=log2.xy[1].y }               -- move to first position instantly to avoid waiting for interval
  manual = true
  time2 = 0
  clock2 = os.clock()
end

-- destination functions

function dest_change(td, change)
  local xy = td.xy
  local times = 1
  local d = 1 -- devices need +/- 1 to account for None
  if td.source == "track" then
    d = 0
    xy = "x"
    times = 2
  end
  for c = 1, times do
    --if change.type ~= "swap" then print(xy, td.source, change.type, change.index, td.track) -- debug
    --else print(xy, td.source, change.type, change.index1, change.index2, td.track) end
    if change.type == "insert" and change.index <= vb.views[xy .. "dest_" .. td.source].value - d then
      if td.source == "device" then -- create temporary buffer
        local items = vb.views[xy .. "dest_device"].items
        items[#items + 1] = "temp"
        vb.views[xy .. "dest_device"].items = items
      end
      select_one = false
      vb.views[xy .. "dest_" .. td.source].value = vb.views[xy .. "dest_" .. td.source].value + 1
      select_one = true
    end

    if change.type == "remove" and change.index <= vb.views[xy .. "dest_" .. td.source].value - d then
      if change.index < vb.views[xy .. "dest_" .. td.source].value - d then
        select_one = false
        vb.views[xy .. "dest_" .. td.source].value = vb.views[xy .. "dest_" .. td.source].value - 1
        select_one = true
      else
        if td.source == "track" then
          vb.views[xy .. "dest_track"].value = 1
          if _G[xy .. "notifier"].track == 1 then -- gui notifier not triggered if value was already 1, so do the necessary changes here
            _G[xy .. "notifier"].track = 1
            add_notifier(s:track(1).devices_observable, dest_change, _G[xy .. "notifier"]) -- old track was deleted, so notifier was automatically removed
          end
        end
        vb.views[xy .. "dest_device"].value = 1
        vb.views[xy .. "dest_parameter"].value = 1
      end
    end

    if change.type == "swap" and (change.index1 == vb.views[xy .. "dest_" .. td.source].value - d or change.index2 == vb.views[xy .. "dest_" .. td.source].value - d) then
      select_one = false
      if change.index1 == vb.views[xy .. "dest_" .. td.source].value - d then
        vb.views[xy .. "dest_" .. td.source].value = change.index2 + d
      else
        vb.views[xy .. "dest_" .. td.source].value = change.index1 + d
      end
      select_one = true
    end

    if td.source == "track" then populate_tracks()
    else populate_devices_parameters(xy, _G[xy .. "notifier"].track, 0, "")
    end
    xy = "y" -- for tracks notifier's second time
  end
end

function dest_change2(td, change)
  local xy = td.xy
  local times = 1
  local d = 1 -- devices need +/- 1 to account for None
  if td.source == "track" then
    d = 0
    xy = "x"
    times = 2
  end
  for c = 1, times do
    --if change.type ~= "swap" then print(xy, td.source, change.type, change.index, td.track) -- debug
    --else print(xy, td.source, change.type, change.index1, change.index2, td.track) end
    if change.type == "insert" and change.index <= vb.views[xy .. "dest_" .. td.source .. "2"].value - d then
      if td.source == "device" then -- create temporary buffer
        local items = vb.views[xy .. "dest_device2"].items
        items[#items + 1] = "temp"
        vb.views[xy .. "dest_device2"].items = items
      end
      select_one = false
      vb.views[xy .. "dest_" .. td.source .. "2"].value = vb.views[xy .. "dest_" .. td.source .. "2"].value + 1
      select_one = true
    end

    if change.type == "remove" and change.index <= vb.views[xy .. "dest_" .. td.source .. "2"].value - d then
      if change.index < vb.views[xy .. "dest_" .. td.source .. "2"].value - d then
        select_one = false
        vb.views[xy .. "dest_" .. td.source .. "2"].value = vb.views[xy .. "dest_" .. td.source .. "2"].value - 1
        select_one = true
      else
        if td.source == "track" then
          vb.views[xy .. "dest_track2"].value = 1
          if _G[xy .. "notifier2"].track == 1 then -- gui notifier not triggered if value was already 1, so do the necessary changes here
            _G[xy .. "notifier2"].track = 1
            add_notifier(s:track(1).devices_observable, dest_change, _G[xy .. "notifier2"]) -- old track was deleted, so notifier was automatically removed
          end
        end
        vb.views[xy .. "dest_device2"].value = 1
        vb.views[xy .. "dest_parameter2"].value = 1
      end
    end

    if change.type == "swap" and (change.index1 == vb.views[xy .. "dest_" .. td.source .. "2"].value - d or change.index2 == vb.views[xy .. "dest_" .. td.source .. "2"].value - d) then
      select_one = false
      if change.index1 == vb.views[xy .. "dest_" .. td.source .. "2"].value - d then
        vb.views[xy .. "dest_" .. td.source .. "2"].value = change.index2 + d
      else
        vb.views[xy .. "dest_" .. td.source .. "2"].value = change.index1 + d
      end
      select_one = true
    end

    if td.source == "track" then populate_tracks()
    else populate_devices_parameters(xy, _G[xy .. "notifier2"].track, 0, "2")
    end
    xy = "y" -- for tracks notifier's second time
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
  vb.views.xdest_track.items  = tracks
  vb.views.ydest_track.items  = tracks
  vb.views.insert_track.items = tracks
  vb.views.xdest_track.tooltip  = vb.views.xdest_track.items[vb.views.xdest_track.value]
  vb.views.ydest_track.tooltip  = vb.views.ydest_track.items[vb.views.ydest_track.value]
  vb.views.insert_track.tooltip = vb.views.insert_track.items[vb.views.insert_track.value]
  vb.views.xdest_track2.items  = tracks
  vb.views.ydest_track2.items  = tracks
  vb.views.xdest_track2.tooltip  = vb.views.xdest_track.items[vb.views.xdest_track.value]
  vb.views.ydest_track2.tooltip  = vb.views.ydest_track.items[vb.views.ydest_track.value]
end

function populate_devices_parameters(xy, t, oldt, lr)
  local d = 0
  local devices    = { "None", "Mixer" }
  local parameters = { "None" }
  
  for d = 2, #s:track(t).devices do
    devices[d + 1] = s:track(t):device(d).display_name
    add_notifier(s:track(t):device(d).display_name_observable, _G["update_device_names" .. lr], _G[xy .. "notifier" .. lr])
  end
  vb.views[xy .. "dest_device" .. lr].items = devices

  d = vb.views[xy .. "dest_device" .. lr].value - 1
  if d > 0 and d <= #s:track(t).devices then -- 2nd arg stops errors when multi-part track swapping
    for p = 1, #s:track(t):device(d).parameters do
      parameters[p + 1] = s:track(t):device(d):parameter(p).name
      --if (s:track(t):device(d).name:sub(2, 5)  == "Form" and p <= 3) or -- need an observable for renoise.song().tracks[].devices[].parameters[].name
         --(s:track(t):device(d).name:sub(9, 12) == "Macr" and p <= 8) or
          --s:track(t):device(d).name:sub(9, 12) == "Auto" or
          --s:track(t):device(d).name:sub(9, 12) == "MIDI" then add_notifier(s:track(t):device(d):parameter(p).name_observable, update_parameter_names, _G[xy .. "notifier" .. lr])
      --end
    end
  end
  vb.views[xy .. "dest_parameter" .. lr].items = parameters
  
  if oldt ~= 0 then
    for d = 2, #s:track(oldt).devices do
      remove_notifier(s:track(oldt):device(d).display_name_observable, _G["update_device_names" .. lr], _G[xy .. "notifier" .. lr])
      --if s:track(t):device(d).name:sub(2, 5)  == "Form" or -- need an observable for renoise.song().tracks[].devices[].parameters[].name
         --s:track(t):device(d).name:sub(9, 12) == "Macr" or
         --s:track(t):device(d).name:sub(9, 12) == "Auto" or
         --s:track(t):device(d).name:sub(9, 12) == "MIDI" then
        --for p = 1, #s:track(oldt):device(d).parameters do
          --if (s:track(oldt):device(d).name:sub(2, 5) == "Form" and p > 3) or (s:track(oldt):device(d).name:sub(9, 12) == "Macr" and p > 8) then break end
          --remove_notifier(s:track(oldt):device(d):parameter(p).name_observable, update_parameter_names, _G[xy .. "notifier .. lr"])
        --end
      --end
    end
  end
end

function update_track_names()
  populate_tracks()
end

function update_device_names(xynotifier)
  populate_devices_parameters(xynotifier.xy, xynotifier.track, 0, "")
end

function update_device_names2(xynotifier2)
  populate_devices_parameters(xynotifier2.xy, xynotifier2.track, 0, "2")
end

--function update_parameter_names(xynotifier) -- need an observable for renoise.song().tracks[].devices[].parameters[].name
  --populate_devices_parameters(xynotifier.xy, xynotifier.track, 0, "")
--end

-- calculate length of pattern

function pattern_length()
  local bpm = 0      -- actual value
  local bpma = 0     -- automation object
  local bpmp = 1     -- current automation point
  local bpmfx = {}   -- effect commands
  local bpmfxi = 0   -- value from a previous pattern that's active before the current pattern's first effect command
  local bpmmin = 20  -- minimum bpm changed from 32 to 20 in v3.4
  local bpmrng = 979 -- range of values (max minus min)
  local newv = true
  local v1, _, v2 = renoise.RENOISE_VERSION:match'(%d+)(%.)(%d+)'
  if tonumber(v1) < 3 or (tonumber(v1) == 3 and tonumber(v2) < 4) then
    newv = false
    bpmmin = 32
    bpmrng = 967
  end

  local lpb = 0
  local lpba = 0
  local lpbp = 1
  local lpbfx = {}
  local lpbfxi = 0

  local mst = {}
  local ptime = 0
  local sp = s.selected_pattern_index

  --get automation and/or effect command data
  for n, t in ripairs(s.tracks) do
    if t.type == 2 then
      mst = {n = n, t = t}
      bpma = s:pattern(sp):track(mst.n):find_automation(mst.t:device(1):parameter(6))
      lpba = s:pattern(sp):track(mst.n):find_automation(mst.t:device(1):parameter(7))
      break
    end
  end
  if newv == true or (bpma == nil or lpba == nil) then -- old version doesn't collect effect commands if both bpm and lpb automations exist
    for l, fx in s.pattern_iterator:effect_columns_in_pattern(sp, 1) do
      if (newv == true or bpma == nil) and tostring(fx):sub(1,2) == "ZT" and tonumber(tostring(fx):sub(3,4), 16) >= bpmmin then
        if not next(bpmfx) and l.line > 1 then                                     -- if the first effect command is not on the first line then work out the initial value
          if sp == 1 then bpmfxi = tonumber(tostring(fx):sub(3,4), 16)             -- if current pattern is first in song then set initial value to the first value from current pattern
          else
            for p = sp - 1, 1, -1 do                                               -- search previous patterns for automations/commands
              local tmpa = s:pattern(p):track(mst.n):find_automation(mst.t:device(1):parameter(6))
              if tmpa ~= nil then
                bpmfxi = round3(tmpa.points[#tmpa.points].value * bpmrng + bpmmin) -- if there's an automation then set initial value to the value of its last point
                break
              else
                for _, fxi in s.pattern_iterator:effect_columns_in_pattern(p, 1) do
                  if tostring(fxi):sub(1,2) == "ZT" and tonumber(tostring(fxi):sub(3,4), 16) >= bpmmin then bpmfxi = tonumber(tostring(fxi):sub(3,4), 16) end
                end
                if bpmfxi > 0 then break end                                       -- if there are effect commands then set initial value to the value of the last one
              end
            end
            if bpmfxi == 0 then bpmfxi = tonumber(tostring(fx):sub(3,4), 16) end   -- if there's no automation/commands then set initial value to the first value from current pattern
          end
        end
        bpmfx[l.line] = tonumber(tostring(fx):sub(3,4), 16)
      end
      if (newv == true or lpba == nil) and tostring(fx):sub(1,2) == "ZL" and tonumber(tostring(fx):sub(3,4), 16) >= 1 then
        if not next(lpbfx) and l.line > 1 then                                     -- if the first effect command is not on the first line then work out the initial value
          if sp == 1 then lpbfxi = tonumber(tostring(fx):sub(3,4), 16)             -- if current pattern is first in song then set initial value to first value from current pattern
          else
            for p = sp - 1, 1, -1 do                                               -- search previous patterns for automations/commands
              local tmpa = s:pattern(p):track(mst.n):find_automation(mst.t:device(1):parameter(7))
              if tmpa ~= nil then
                lpbfxi = tmpa.points[#tmpa.points].value * 255 + 1                 -- if there's an automation then set initial value to the value of its last point
                break
              else
                for _, fxi in s.pattern_iterator:effect_columns_in_pattern(p, 1) do
                  if tostring(fxi):sub(1,2) == "ZL" and tonumber(tostring(fxi):sub(3,4), 16) >= 1 then lpbfxi = tonumber(tostring(fxi):sub(3,4), 16) end
                end
                if lpbfxi > 0 then break end                                       -- if there are effect commands then set initial value to the value of the last one
              end
            end
            if lpbfxi == 0 then lpbfxi = tonumber(tostring(fx):sub(3,4), 16) end   -- if there's no automation/commands then set initial value to the first value from current pattern
          end
        end
        lpbfx[l.line] = tonumber(tostring(fx):sub(3,4), 16)
      end
    end
  end

  -- calculate length of pattern in seconds
  if (bpma == nil or #bpma.points == 1) and (lpba == nil or #lpba.points == 1) and not next(bpmfx) and not next(lpbfx) then -- not next() checks if a table is empty
    for l = 1, s:pattern(sp).number_of_lines do
      ptime = (1 / ((s.transport.bpm / 60) * s.transport.lpb)) + ptime
    end
  else
    for l = 1, s:pattern(sp).number_of_lines do -- bpm/lpb are only updated once per line
      if bpma == nil or (newv == true and bpma.playmode == 1 and bpma.points[bpmp].time ~= l) then -- old version only uses effect commands if bpm automation is empty
        if not next(bpmfx) then bpm = s.transport.bpm
        else
          if bpmfxi == 0 then
            if bpmfx[l] ~= nil then bpm = bpmfx[l] end
          else
            bpm = bpmfxi
            if bpmfx[l + 1] ~= nil then bpmfxi = 0 end
          end
        end
      else
        if l < bpma.points[1].time or bpma.playmode == 1 or bpmp == #bpma.points then bpm = round3(bpma.points[bpmp].value * bpmrng + bpmmin)
        else
          local alength = bpma.points[bpmp + 1].time - bpma.points[bpmp].time
          local apos    = l - bpma.points[bpmp].time
          local lpos    = apos / alength                                        -- position of line along length of automation between current and next point
          local bpmp1   = round3(bpma.points[bpmp].value * bpmrng + bpmmin)     -- current point's value
          local bpmp2   = round3(bpma.points[bpmp + 1].value * bpmrng + bpmmin) -- next point's value
          if bpma.playmode == 2 then bpm = scaling_at_position(lpos, bpma.points[bpmp].scaling) * (bpmp2 - bpmp1) + bpmp1
          else bpm = -1 * lpos^2 * (2 * lpos - 3) * (bpmp2 - bpmp1) + bpmp1
          end
        end
      end
      if lpba == nil or (newv == true and lpba.playmode == 1 and lpba.points[lpbp].time ~= l) then -- old version only uses effect commands if lpb automation is empty
        if not next(lpbfx) then lpb = s.transport.lpb
        else
          if lpbfxi == 0 then
            if lpbfx[l] ~= nil then lpb = lpbfx[l] end
          else
            lpb = lpbfxi
            if lpbfx[l + 1] ~= nil then lpbfxi = 0 end
          end
        end
      else lpb = round(lpba.points[lpbp].value * 255 + 1)
      end
      if bpma ~= nil and bpmp < #bpma.points and bpma.points[bpmp + 1].time == l + 1 then bpmp = bpmp + 1 end
      if lpba ~= nil and lpbp < #lpba.points and lpba.points[lpbp + 1].time == l + 1 then lpbp = lpbp + 1 end
      ptime = (1 / ((bpm / 60) * lpb)) + ptime
    end
  end
  --print(ptime, round(ptime * s.selected_sample.sample_buffer.sample_rate)) -- debug
  return ptime
end

-- create automation for the selected parameter

function create_automation(xy)
  if vb.views[xy .. "dest_device"].value == 2 and (vb.views[xy .. "dest_parameter"].value == 5 or vb.views[xy .. "dest_parameter"].value == 6) then renoise.app():show_warning("Automations cannot be created for Post Volume/Panning parameters.")
  elseif vb.views[xy .. "dest_device"].value > 1 and vb.views[xy .. "dest_parameter"].value > 1 then
    local sp = s.selected_pattern_index
    local pl = s:pattern(sp).number_of_lines
    local ptime = pattern_length()
    local a = s:pattern(sp):track(vb.views[xy .. "dest_track"].value):find_automation(s:track(vb.views[xy .. "dest_track"].value):device(vb.views[xy .. "dest_device"].value - 1):parameter(vb.views[xy .. "dest_parameter"].value - 1))
    if a == nil then a = s:pattern(sp):track(vb.views[xy .. "dest_track"].value):create_automation(s:track(vb.views[xy .. "dest_track"].value):device(vb.views[xy .. "dest_device"].value - 1):parameter(vb.views[xy .. "dest_parameter"].value - 1))
    else a:clear()
    end
    a.playmode = 2
    for c, t in ipairs(log.time) do
      local atime = round8((pl * t) / (10 * ptime * vb.views.replay_speed.value)) -- round8 for line fractions (1/256 goes to 8 decimal places), not doing this can cause first if to fail even though both args show as equal
      if atime == pl then a:add_point_at(pl + 255/256, log.xy[c][xy])
      elseif atime > pl then return
      else a:add_point_at(atime + 1, log.xy[c][xy])
      end
    end
  end
end

function create_automation2(xy)
  if vb.views[xy .. "dest_device2"].value == 2 and (vb.views[xy .. "dest_parameter2"].value == 5 or vb.views[xy .. "dest_parameter2"].value == 6) then renoise.app():show_warning("Automations cannot be created for Post Volume/Panning parameters.")
  elseif vb.views[xy .. "dest_device2"].value > 1 and vb.views[xy .. "dest_parameter2"].value > 1 then
    local sp = s.selected_pattern_index
    local pl = s:pattern(sp).number_of_lines
    local ptime = pattern_length()
    local a = s:pattern(sp):track(vb.views[xy .. "dest_track2"].value):find_automation(s:track(vb.views[xy .. "dest_track2"].value):device(vb.views[xy .. "dest_device2"].value - 1):parameter(vb.views[xy .. "dest_parameter2"].value - 1))
    if a == nil then a = s:pattern(sp):track(vb.views[xy .. "dest_track2"].value):create_automation(s:track(vb.views[xy .. "dest_track2"].value):device(vb.views[xy .. "dest_device2"].value - 1):parameter(vb.views[xy .. "dest_parameter2"].value - 1))
    else a:clear()
    end
    a.playmode = 2
    for c, t in ipairs(log2.time) do
      local atime = round8((pl * t) / (10 * ptime * vb.views.replay_speed2.value)) -- round8 for line fractions (1/256 goes to 8 decimal places), not doing this can cause first if to fail even though both args show as equal
      if atime == pl then a:add_point_at(pl + 255/256, log2.xy[c][xy])
      elseif atime > pl then return
      else a:add_point_at(atime + 1, log2.xy[c][xy])
      end
    end
  end
end

-- control the tool from the MIDI device

function control_tool(d)
  if     d.n == 1 and doofer:parameter(3).value == 100 then vb.views.xypad.value  = { x=d.p.value / 100, y=vb.views.xypad.value.y }
  elseif d.n == 2 and doofer:parameter(3).value == 100 then vb.views.xypad.value  = { x=vb.views.xypad.value.x, y=d.p.value / 100 }
  elseif d.n == 3 and doofer:parameter(3).value  < 100 then vb.views.xypad.value  = { x=vb.views.xypad.snapback.x, y=vb.views.xypad.snapback.y }
  elseif d.n == 4 and doofer:parameter(6).value == 100 then vb.views.xypad2.value = { x=d.p.value / 100, y=vb.views.xypad2.value.y }
  elseif d.n == 5 and doofer:parameter(6).value == 100 then vb.views.xypad2.value = { x=vb.views.xypad2.value.x, y=d.p.value / 100 }
  elseif d.n == 6 and doofer:parameter(6).value  < 100 then vb.views.xypad2.value = { x=vb.views.xypad2.snapback.x, y=vb.views.xypad2.snapback.y }
  end
end

-- detect if the MIDI device has been deleted

function midi_device_check(t)
  for _, d in pairs(t.devices) do
    if rawequal(d, doofer) then return end
  end
  vb.views.insert_midi_device.active = true
  vb.views.insert_track.active       = true
  vb.views.detect_midi_device.active = true
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

gui_xypad = vb:xypad {
  id = "xypad",
  value    = { x=0, y=0 },
  snapback = { x=0, y=0 },
  notifier = function(value)
    if vb.views.xdest_device.value > 1 and vb.views.xdest_parameter.value > 1 then
      s:track(vb.views.xdest_track.value):device(vb.views.xdest_device.value - 1):parameter(vb.views.xdest_parameter.value - 1).value = map_range("x", value.x, "")
    end
    if vb.views.ydest_device.value > 1 and vb.views.ydest_parameter.value > 1 then
      s:track(vb.views.ydest_track.value):device(vb.views.ydest_device.value - 1):parameter(vb.views.ydest_parameter.value - 1).value =  map_range("y", value.y, "")
    end
    if value.x == vb.views.xypad.snapback.x and value.y == vb.views.xypad.snapback.y then -- LIMITATION: user can trigger this by drawing in the Finish Corner
      if renoise.tool():has_timer(record) then
        renoise.tool():remove_timer(record)
        if log.time[1] ~= nil then -- without this it's possible to cause an error by constantly drawing in the Finish Corner
          time = 0
          pause_time = 0
          clock = os.clock()
          renoise.tool():add_timer(replay, vb.views.replay_interval.value)
        end
      end
    else
      if manual and not renoise.tool():has_timer(record) then
        if renoise.tool():has_timer(replay) or vb.views.pause_replay.text == "Unpause Replay" then
          for y = 0, 53 do
            for x = 0, 53 do
              vb.views["pad1x" .. tostring(x) .. "y" .. tostring(y)].bitmap = "images/black.bmp"
            end
          end
          time = 0
          pause_time = 0
          log = { time={}, xy={} }
          if vb.views.pause_replay.text == "Unpause Replay" then vb.views.pause_replay.text = "Pause Replay"
          else renoise.tool():remove_timer(replay)
          end
        end
        renoise.tool():add_timer(record, 1) -- first point can't be recorded immediately cos xypad notifier triggers on all x/y changes regardless of whether they're part of the same singular xy change
      end
    end
  end
}

gui_xdest_track = vb:popup {
  id = "xdest_track",
  width = 81,
  tooltip = "01: Track 01",
  notifier = function(t)
    if select_one then vb.views.xdest_device.value = 1 end
    populate_devices_parameters("x", t, xnotifier.track, "")
    if xnotifier.track <= #s.tracks then -- in case right-most track was deleted
      remove_notifier(s:track(xnotifier.track).devices_observable, dest_change, xnotifier)
    end
    xnotifier.track = t
    add_notifier(s:track(t).devices_observable, dest_change, xnotifier)
    vb.views.xdest_track.tooltip = vb.views.xdest_track.items[vb.views.xdest_track.value]
  end
}

gui_ydest_track = vb:popup {
  id = "ydest_track",
  width = 81,
  tooltip = "01: Track 01",
  notifier = function(t)
    if select_one then vb.views.ydest_device.value = 1 end
    populate_devices_parameters("y", t, ynotifier.track, "")
    if ynotifier.track <= #s.tracks then
      remove_notifier(s:track(ynotifier.track).devices_observable, dest_change, ynotifier)
    end
    ynotifier.track = t
    add_notifier(s:track(t).devices_observable, dest_change, ynotifier)
    vb.views.ydest_track.tooltip = vb.views.ydest_track.items[vb.views.ydest_track.value]
  end
}

gui_xdest_device = vb:popup {
  id = "xdest_device",
  width = 90,
  notifier = function(d)
    if select_one then vb.views.xdest_parameter.value = 1 end
    populate_devices_parameters("x", xnotifier.track, 0, "")
  end
}

gui_ydest_device = vb:popup {
  id = "ydest_device",
  width = 90,
  notifier = function(d)
    if select_one then vb.views.ydest_parameter.value = 1 end
    populate_devices_parameters("y", ynotifier.track, 0, "")
  end
}

gui_xdest_parameter = vb:popup {
  id = "xdest_parameter",
  width = 90
}

gui_ydest_parameter = vb:popup {
  id = "ydest_parameter",
  width = 90
}

gui_insert_midi_device = vb:button {
  id = "insert_midi_device",
  text = "Insert MIDI Device",
  tooltip = "Insert a device into the selected track so that MIDI hardware can be mapped and used to create drawings.",
  notifier = function()
    doofer = s:track(vb.views.insert_track.value):insert_device_at("Audio/Effects/Native/Doofer", 2)
    doofer.active_preset_data = io.open("drawtomator.xrdp", "rb"):read("*all")
    doofer.display_name = "Drawtomator"
    add_notifier(doofer:parameter(1).value_observable, control_tool, { n=1, p=doofer:parameter(1) })
    add_notifier(doofer:parameter(2).value_observable, control_tool, { n=2, p=doofer:parameter(2) })
    add_notifier(doofer:parameter(3).value_observable, control_tool, { n=3, p=doofer:parameter(3) })
    add_notifier(doofer:parameter(4).value_observable, control_tool, { n=4, p=doofer:parameter(4) })
    add_notifier(doofer:parameter(5).value_observable, control_tool, { n=5, p=doofer:parameter(5) })
    add_notifier(doofer:parameter(6).value_observable, control_tool, { n=6, p=doofer:parameter(6) })
    add_notifier(s:track(vb.views.insert_track.value).devices_observable, midi_device_check, s:track(vb.views.insert_track.value))
    vb.views.insert_midi_device.active = false
    vb.views.insert_track.active       = false
    vb.views.detect_midi_device.active = false
  end
}

gui_insert_track = vb:popup {
  id = "insert_track",
  width = 79,
  tooltip = "01: Track 01",
  notifier = function()
    vb.views.insert_track.tooltip = vb.views.insert_track.items[vb.views.insert_track.value]
  end
}

gui_fit_pattern = vb:button {
  text = "Fit To Pattern",
  tooltip = "Set the Replay Speed so the drawing fits into the current pattern",
  notifier = function()
    if #log.time > 0 then vb.views.replay_speed.value = (log.time[#log.time] * 0.1) / pattern_length() end -- if user has disabled Automation Following then calculated time may be different from what's expected
  end
}

gui_create_automations = vb:button {
  text = "Create Automations",
  tooltip = "Use the drawing to create graphical automations for the destination parameters in the current pattern. Overwrites existing automation points.",
  notifier = function()
    if #log.time > 0 then create_automation("x") create_automation("y") end
  end
}

gui_replay_speed = vb:valuebox {
  id = "replay_speed",
  min = 1,
  max = 9999.999,
  value = 100,
  width = 85,
  tostring = function(value) return tostring(("%.3f"):format(value) .. "%") end,
  tonumber = function(value) return tonumber((tostring(value):gsub('%%',''))) end, -- value instead of str to preserve past 3 digits for accurate Fit Pattern > Create Automations. double parentheses to exclude second return value
}

gui_recording_interval = vb:valuebox {
  id = "recording_interval",
  min = 5,
  value = 50,
  width = 50,
  tooltip = "Time (ms) between points of recording. Accuracy is GUI dependant and is poor at low values. High values are more accurate but less information is recorded."
}

gui_replay_interval = vb:valuebox {
  id = "replay_interval",
  min = 5,
  value = 50,
  width = 50,
  tooltip = "Time (ms) between points of playback. Accuracy is GUI dependant and is poor at low values. High values are more accurate but playback is more coarse.",
  notifier = function(value)
    if renoise.tool():has_timer(replay) then
      renoise.tool():remove_timer(replay)
      renoise.tool():add_timer(replay, value)
    end
  end
}

gui_finish_corner = vb:popup {
  width = 90,
  items = { "Bottom Left", "Top Left", "Top Right", "Bottom Right" },
  tooltip = "The snapback point used to detect when drawing has finished. Change the corner if you need its values in your drawing. Will clear existing drawing.",
  notifier = function(value)
    local snapback = { x=0, y=0 }
    if     value == 2 then snapback = { x=0, y=1 }
    elseif value == 3 then snapback = { x=1, y=1 }
    elseif value == 4 then snapback = { x=1, y=0 }
    end
    for y = 0, 53 do
      for x = 0, 53 do
        vb.views["pad1x" .. tostring(x) .. "y" .. tostring(y)].bitmap = "images/black.bmp"
      end
    end
    time = 0
    pause_time = 0
    log = { time={}, xy={} }
    if renoise.tool():has_timer(replay) then renoise.tool():remove_timer(replay) end
    if vb.views.pause_replay.text == "Unpause Replay" then vb.views.pause_replay.text = "Pause Replay" end
    manual = false
    vb.views.xypad.value = snapback
    manual = true
    vb.views.xypad.snapback = snapback
  end
}

gui_drawing_colour = vb:popup {
  id = "drawing_colour",
  width = 90,
  items = { "Button", "Body", "Main" },
  tooltip = "Choose from three different colours available from the Theme.",
  notifier = function(value)
    for y = 0, 53 do
      for x = 0, 53 do
        vb.views["pad1x" .. tostring(x) .. "y" .. tostring(y)].mode = vb.views.drawing_colour.items[value]:lower() .. "_color"
      end
    end
  end
}

gui_pause_replay = vb:button {
  id = "pause_replay",
  width = 108,
  text = "Pause Replay",
  pressed = function()
    if vb.views.pause_replay.text == "Pause Replay" and renoise.tool():has_timer(replay) then
      vb.views.pause_replay.text = "Unpause Replay"
      renoise.tool():remove_timer(replay)
      pause_time = os.clock()
    elseif vb.views.pause_replay.text == "Unpause Replay" then
      vb.views.pause_replay.text = "Pause Replay"
      renoise.tool():add_timer(replay, vb.views.replay_interval.value)
      clock = clock + (os.clock() - pause_time)
    end
  end
}

-- gui2

gui_xypad2 = vb:xypad {
  id = "xypad2",
  value    = { x=0, y=0 },
  snapback = { x=0, y=0 },
  notifier = function(value)
    if vb.views.xdest_device2.value > 1 and vb.views.xdest_parameter2.value > 1 then
      s:track(vb.views.xdest_track2.value):device(vb.views.xdest_device2.value - 1):parameter(vb.views.xdest_parameter2.value - 1).value = map_range("x", value.x, "2")
    end
    if vb.views.ydest_device2.value > 1 and vb.views.ydest_parameter2.value > 1 then
      s:track(vb.views.ydest_track2.value):device(vb.views.ydest_device2.value - 1):parameter(vb.views.ydest_parameter2.value - 1).value =  map_range("y", value.y, "2")
    end
    if value.x == vb.views.xypad2.snapback.x and value.y == vb.views.xypad2.snapback.y then -- LIMITATION: user can trigger this by drawing in the Finish Corner
      if renoise.tool():has_timer(record2)then
        renoise.tool():remove_timer(record2)
        if log2.time[1] ~= nil then -- without this it's possible to cause an error by constantly drawing in the Finish Corner
          time2 = 0
          pause_time2 = 0
          clock2 = os.clock()
          renoise.tool():add_timer(replay2, vb.views.replay_interval2.value)
        end
      end
    else
      if manual and not renoise.tool():has_timer(record2) then
        if renoise.tool():has_timer(replay2) or vb.views.pause_replay2.text == "Unpause Replay" then
          for y = 0, 53 do
            for x = 0, 53 do
              vb.views["pad2x" .. tostring(x) .. "y" .. tostring(y)].bitmap = "images/black.bmp"
            end
          end
          time2 = 0
          pause_time2 = 0
          log2 = { time={}, xy={} }
          if vb.views.pause_replay2.text == "Unpause Replay" then vb.views.pause_replay2.text = "Pause Replay"
          else renoise.tool():remove_timer(replay2)
          end
        end
        renoise.tool():add_timer(record2, 1) -- first point can't be recorded immediately cos xypad notifier triggers on all x/y changes regardless of whether they're part of the same singular xy change
      end
    end
  end
}

gui_xdest_track2 = vb:popup {
  id = "xdest_track2",
  width = 81,
  tooltip = "01: Track 01",
  notifier = function(t)
    if select_one then vb.views.xdest_device2.value = 1 end
    populate_devices_parameters("x", t, xnotifier2.track, "2")
    if xnotifier2.track <= #s.tracks then -- in case right-most track was deleted
      remove_notifier(s:track(xnotifier2.track).devices_observable, dest_change2, xnotifier2)
    end
    xnotifier2.track = t
    add_notifier(s:track(t).devices_observable, dest_change2, xnotifier2)
    vb.views.xdest_track2.tooltip = vb.views.xdest_track2.items[vb.views.xdest_track2.value]
  end
}

gui_ydest_track2 = vb:popup {
  id = "ydest_track2",
  width = 81,
  tooltip = "01: Track 01",
  notifier = function(t)
    if select_one then vb.views.ydest_device2.value = 1 end
    populate_devices_parameters("y", t, ynotifier2.track, "2")
    if ynotifier2.track <= #s.tracks then
      remove_notifier(s:track(ynotifier2.track).devices_observable, dest_change2, ynotifier2)
    end
    ynotifier2.track = t
    add_notifier(s:track(t).devices_observable, dest_change2, ynotifier2)
    vb.views.ydest_track2.tooltip = vb.views.ydest_track2.items[vb.views.ydest_track2.value]
  end
}

gui_xdest_device2 = vb:popup {
  id = "xdest_device2",
  width = 90,
  notifier = function(d)
    if select_one then vb.views.xdest_parameter2.value = 1 end
    populate_devices_parameters("x", xnotifier2.track, 0, "2")
  end
}

gui_ydest_device2 = vb:popup {
  id = "ydest_device2",
  width = 90,
  notifier = function(d)
    if select_one then vb.views.ydest_parameter2.value = 1 end
    populate_devices_parameters("y", ynotifier2.track, 0, "2")
  end
}

gui_xdest_parameter2 = vb:popup {
  id = "xdest_parameter2",
  width = 90
}

gui_ydest_parameter2 = vb:popup {
  id = "ydest_parameter2",
  width = 90
}

gui_detect_midi_device = vb:button {
  id = "detect_midi_device",
  text = "Detect Existing MIDI Device",
  tooltip = "Search through all tracks to find an existing Drawtomator MIDI device. If one is found then it will be linked to the tool.",
  notifier = function()
    for _, t in pairs(s.tracks) do
      for _, d in pairs(t.devices) do
        if d.name == "Doofer" and d.display_name == "Drawtomator" then
          doofer = d
          add_notifier(d:parameter(1).value_observable, control_tool, { n=1, p=d:parameter(1) })
          add_notifier(d:parameter(2).value_observable, control_tool, { n=2, p=d:parameter(2) })
          add_notifier(d:parameter(3).value_observable, control_tool, { n=3, p=d:parameter(3) })
          add_notifier(d:parameter(4).value_observable, control_tool, { n=4, p=d:parameter(4) })
          add_notifier(d:parameter(5).value_observable, control_tool, { n=5, p=d:parameter(5) })
          add_notifier(d:parameter(6).value_observable, control_tool, { n=6, p=d:parameter(6) })
          add_notifier(t.devices_observable, midi_device_check, t)
          vb.views.insert_midi_device.active = false
          vb.views.insert_track.active       = false
          vb.views.detect_midi_device.active = false
          return
        end
      end
    end
  end
}

gui_fit_pattern2 = vb:button {
  text = "Fit To Pattern",
  tooltip = "Set the Replay Speed so the drawing fits into the current pattern",
  notifier = function()
    if #log2.time > 0 then vb.views.replay_speed2.value = (log2.time[#log2.time] * 0.1) / pattern_length() end -- if user has disabled Automation Following then calculated time may be different from what's expected
  end
}

gui_create_automations2 = vb:button {
  text = "Create Automations",
  tooltip = "Use the drawing to create graphical automations for the destination parameters in the current pattern. Overwrites existing automation points.",
  notifier = function()
    if #log2.time > 0 then create_automation2("x") create_automation2("y") end
  end
}

gui_replay_speed2 = vb:valuebox {
  id = "replay_speed2",
  min = 1,
  max = 9999.999,
  value = 100,
  width = 85,
  tostring = function(value) return tostring(("%.3f"):format(value) .. "%") end,
  tonumber = function(value) return tonumber((tostring(value):gsub('%%',''))) end, -- value instead of str to preserve past 3 digits for accurate Fit Pattern > Create Automations. double parentheses to exclude second return value
}

gui_recording_interval2 = vb:valuebox {
  id = "recording_interval2",
  min = 5,
  value = 50,
  width = 50,
  tooltip = "Time (ms) between points of recording. Accuracy is GUI dependant and is poor at low values. High values are more accurate but less information is recorded."
}

gui_replay_interval2 = vb:valuebox {
  id = "replay_interval2",
  min = 5,
  value = 50,
  width = 50,
  tooltip = "Time (ms) between points of playback. Accuracy is GUI dependant and is poor at low values. High values are more accurate but playback is more coarse.",
  notifier = function(value)
    if renoise.tool():has_timer(replay2) then
      renoise.tool():remove_timer(replay2)
      renoise.tool():add_timer(replay2, value)
    end
  end
}

gui_finish_corner2 = vb:popup {
  width = 90,
  items = { "Bottom Left", "Top Left", "Top Right", "Bottom Right" },
  tooltip = "The snapback point used to detect when drawing has finished. Change the corner if you need its values in your drawing. Will clear existing drawing.",
  notifier = function(value)
    local snapback = { x=0, y=0 }
    if     value == 2 then snapback = { x=0, y=1 }
    elseif value == 3 then snapback = { x=1, y=1 }
    elseif value == 4 then snapback = { x=1, y=0 }
    end
    for y = 0, 53 do
      for x = 0, 53 do
        vb.views["pad2x" .. tostring(x) .. "y" .. tostring(y)].bitmap = "images/black.bmp"
      end
    end
    time2 = 0
    pause_time2 = 0
    log2 = { time={}, xy={} }
    if renoise.tool():has_timer(replay2) then renoise.tool():remove_timer(replay2) end
    if vb.views.pause_replay2.text == "Unpause Replay" then vb.views.pause_replay2.text = "Pause Replay" end
    manual = false
    vb.views.xypad2.value = snapback
    manual = true
    vb.views.xypad2.snapback = snapback
  end
}

gui_drawing_colour2 = vb:popup {
  id = "drawing_colour2",
  width = 90,
  items = { "Button", "Body", "Main" },
  tooltip = "Choose from three different colours available from the Theme.",
  notifier = function(value)
    for y = 0, 53 do
      for x = 0, 53 do
        vb.views["pad2x" .. tostring(x) .. "y" .. tostring(y)].mode = vb.views.drawing_colour2.items[value]:lower() .. "_color"
      end
    end
  end
}

gui_pause_replay2 = vb:button {
  id = "pause_replay2",
  width = 108,
  text = "Pause Replay",
  pressed = function()
    if vb.views.pause_replay2.text == "Pause Replay" and renoise.tool():has_timer(replay2) then
      vb.views.pause_replay2.text = "Unpause Replay"
      renoise.tool():remove_timer(replay2)
      pause_time2 = os.clock()
    elseif vb.views.pause_replay2.text == "Unpause Replay" then
      vb.views.pause_replay2.text = "Pause Replay"
      renoise.tool():add_timer(replay2, vb.views.replay_interval2.value)
      clock2 = clock2 + (os.clock() - pause_time2)
    end
  end
}

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
dialog_content = vb:row {
  margin = DEFAULT_MARGIN,
  
vb:column {
  vb:column {
    style = "group",
    width = 340,
    margin = DEFAULT_MARGIN,
    
    vb:horizontal_aligner {
      mode = "justify",
      margin = 10,
      vb:vertical_aligner { gui_xypad, vb:space { height = 6 }, gui_pause_replay },
      vb:vertical_aligner {
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, gui_insert_midi_device,              vb:space { width = 2 }, gui_insert_track },       vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, gui_fit_pattern,                     vb:space { width = 2 }, gui_create_automations }, vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Replay Speed" },   vb:space { width = 2 }, gui_replay_speed },       vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Record/Replay" },  vb:space { width = 2 }, gui_recording_interval,   vb:space { width  = 2 }, gui_replay_interval }, vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Finish Corner" },  vb:space { width = 2 }, gui_finish_corner },      vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Drawing Colour" }, vb:space { width = 2 }, gui_drawing_colour }
      },
    },
  },

  vb:space { height = 5 },
  vb:column {
    style = "panel",
    width = 340,
    margin = 3,
    vb:horizontal_aligner { mode = "justify", vb:text { text = "X-Axis Dest." }, vb:row { gui_xdest_track, vb:space { width = 2 }, gui_xdest_device, vb:space { width = 2 }, gui_xdest_parameter } },
    vb:horizontal_aligner { mode = "justify", vb:text { text = "Y-Axis Dest." }, vb:row { gui_ydest_track, vb:space { width = 2 }, gui_ydest_device, vb:space { width = 2 }, gui_ydest_parameter } }
  },
},

vb:space { width = 5 },

vb:column {
  vb:column {
    style = "group",
    width = 340,
    margin = DEFAULT_MARGIN,
    
    vb:horizontal_aligner {
      mode = "justify",
      margin = 10,
      vb:vertical_aligner { gui_xypad2, vb:space { height = 6 }, gui_pause_replay2 },
      vb:vertical_aligner {
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, gui_detect_midi_device,              vb:space { width = 2 }, }, vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, gui_fit_pattern2,                    vb:space { width = 2 }, gui_create_automations2 }, vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Replay Speed" },   vb:space { width = 2 }, gui_replay_speed2 },       vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Record/Replay" },  vb:space { width = 2 }, gui_recording_interval2,   vb:space { width  = 2 }, gui_replay_interval2 }, vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Finish Corner" },  vb:space { width = 2 }, gui_finish_corner2 },      vb:space { height = 5 },
        vb:horizontal_aligner { mode = "right", vb:space { width = 10 }, vb:text { text = "Drawing Colour" }, vb:space { width = 2 }, gui_drawing_colour2 }
      },
    },
  },

  vb:space { height = 5 },
  vb:column {
    style = "panel",
    width = 340,
    margin = 3,
    vb:horizontal_aligner { mode = "justify", vb:text { text = "X-Axis Dest." }, vb:row { gui_xdest_track2, vb:space { width = 2 }, gui_xdest_device2, vb:space { width = 2 }, gui_xdest_parameter2 } },
    vb:horizontal_aligner { mode = "justify", vb:text { text = "Y-Axis Dest." }, vb:row { gui_ydest_track2, vb:space { width = 2 }, gui_ydest_device2, vb:space { width = 2 }, gui_ydest_parameter2 } }
  }
}
}
