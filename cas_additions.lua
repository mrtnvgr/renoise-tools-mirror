--Cas` Code
-------------------------------------------------------------------------------------------
-- GUI --
local rs
local dialog = nil
local vb = nil
local src_table = {}

---------------------------------------
-- Lists source track for a sendtrack
---------------------------------------

--go to source track
local function go_to_src(n)
  renoise.song().selected_track_index = src_table[n]
end

--close dialog
local function close_dialog()
  if ( dialog and dialog.visible ) then
    dialog:close()
  end
end

--key handler
local function key_dialog_src(d, k)
  if (k.character and k.character >= "0" and k.character <= "9") then
    local num = tonumber(k.character)
    if num == 0 then
      num = 10
    end
    go_to_src(num)
    close_dialog()
  elseif ( k.name == "esc" ) then
    close_dialog()
  else
    return k
  end
end

--show source GUI
function show_src_gui()
  
  vb = renoise.ViewBuilder()
  local song = renoise.song()
  local name = ""
  
  if song.selected_track.type == renoise.Track.TRACK_TYPE_SEND then 
    src_table = find_sources(song.selected_track_index - song.sequencer_track_count - 1)
    
    local dialog_content = vb:column {
      
       id = "list_s",
       vb:row { 
         id = "selector_s",
         style = "group",
         vb:text{ text = "Sources:" }
        }
      }
    
    for i,ti in ipairs(src_table) do
      name = song:track(ti).name
      vb.views['list_s']:add_child(vb:button {
         text = ""..i..". "..name,
         released = function() go_to_src(i) close_dialog() end })
    end
    dialog = renoise.app():show_custom_dialog( "Sources", dialog_content, key_dialog_src )
  end
end

--navigate from send track to source track
function find_sources(strk_no)
 
  local song = renoise.song()
  local src_table = {}
  
  for track = 1,song.sequencer_track_count+strk_no do
    for devid,device in ipairs(song:track(track).devices) do
      if device.name == "#Send" and device:parameter(3).value == (strk_no - 1) then
        table.insert(src_table, track) 
      end
    end
  end
  
  return src_table
end

---------------------------------
-- Lists send tracks to send to
---------------------------------
--main
function insert_send_dest(num, amt, insapp)
  --print("sendtrack#"..num)
  --print("that's "..renoise.song():track(renoise.song().sequencer_track_count+1+num).name)
  if insapp then
    rs:insert_track_at(renoise.song().sequencer_track_count+1+num+insapp)
    num = num + insapp
  end
  local insert_spot = math.max(rs.selected_device_index, 1)+1  -- math.max for if no instrument selected, +1 because the sampler/mixerdevice counts but you can't place a device before it
  local senddevice = rs.selected_track:insert_device_at("Audio/Effects/Native/#Send", insert_spot)
  senddevice.active_preset_data = [[<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="9">
  <DeviceSlot type="SendDevice">
    <IsMaximized>true</IsMaximized>
    <SendAmount>
      <Value>]]..
      amt..[[</Value>
    </SendAmount>
    <SendPan>
      <Value>0.5</Value>
    </SendPan>
    <DestSendTrack>
      <Value>]]..
  (num-1)..  -- because inside send devices the send tracks are counted starting with zero, just as CV destination stuff inside *devices
[[</Value>
    </DestSendTrack>
    <MuteSource>false</MuteSource>
    <SmoothParameterChanges>true</SmoothParameterChanges>
  </DeviceSlot>
</FilterDevicePreset>
]]
end

--key handler
local function key_dialog_dest(d, k)
  if k.name == "up" then
    vb.views["dest"].value = math.max(vb.views["dest"].value-1, 1)
  elseif k.name == "down" then
    vb.views["dest"].value = math.min(vb.views["dest"].value+1, #vb.views["dest"].items)
  elseif k.name == "space" then
    if vb.views["amount"].value > 0 then
      vb.views["amount"].value = 0
    else
      vb.views["amount"].value = 1
    end
  elseif k.name == "right" then
    if k.modifiers == "shift" then
      vb.views["amount"].value = math.min(vb.views["amount"].value+.05, vb.views["amount"].max)
    else
      vb.views["amount"].value = math.min(vb.views["amount"].value+.25, vb.views["amount"].max)
    end
  elseif k.name == "left" then
    if k.modifiers == "shift" then
      vb.views["amount"].value = math.max(vb.views["amount"].value-.05, vb.views["amount"].min)
    else
      vb.views["amount"].value = math.max(vb.views["amount"].value-.25, vb.views["amount"].min)
    end
  elseif k.character then
    -- direct select by alphanumeric char
    local num = 1 
    -- CHANGED 24/01/14, given the default value of 1 to avoid later attempted arithmetic on a nil value
    
    if k.character >= "1" and k.character <= "9" then
      num = tonumber(k.character)
    elseif k.character >= "a" and k.character <= "z" then
      num = string.byte(k.character)-87
    elseif k.character >= "A" and k.character <= "A" then
      num = string.byte(k.character)-29
    end
    insert_send_dest(num, vb.views["amount"].value)
    close_dialog()
  elseif k.name == "return" then
    -- route to existing track
    insert_send_dest(vb.views["dest"].value, vb.views["amount"].value)
    close_dialog()
  elseif k.name == "ins" then
    -- insert new send track
    insert_send_dest(vb.views["dest"].value, vb.views["amount"].value, 0)
    close_dialog()
  elseif k.name == "del" then
    -- append new send track
    insert_send_dest(vb.views["dest"].value, vb.views["amount"].value, 1)
    close_dialog()
  elseif k.name == "home" then
    -- insert new send track at #1
    insert_send_dest(1, vb.views["amount"].value, 0)
    close_dialog()
  elseif k.name == "end" then
    -- append new send track at the end
    insert_send_dest(rs.send_track_count, vb.views["amount"].value, 1)
    close_dialog()
  elseif k.name == "esc" then
    -- cancel
    close_dialog()
  end
end

--show source GUI
function show_dest_gui()
  vb = renoise.ViewBuilder()
  rs = renoise.song()
  
  if rs.send_track_count>1 then
    local sendnames = {}
    for i=1,rs.send_track_count do
      if i<10 then
        sendnames[i+1] = ""..i..". "..rs:track(i+rs.sequencer_track_count+1).name
      elseif (i-9)<26 then
        sendnames[i+1] = string.char(87+i)..". "..rs:track(i+rs.sequencer_track_count+1).name
      elseif (i-35)<26 then
        sendnames[i+1] = string.char(29+i-26)..". "..rs:track(i+rs.sequencer_track_count+1).name
      end
    end
    
    local dialog_content = vb:row {
      margin = 5, spacing = 2,
      vb:column {
        vb:text { text = "Dest." },
        vb:chooser { id = "dest", items = sendnames },
      },
      vb:column {
        vb:text { text = "Amount" },
        vb:minislider { id = "amount", min = 0, max = 1 },
      },
    }
    
    dialog = renoise.app():show_custom_dialog( "Insert Send to", dialog_content, key_dialog_dest )
  else
    renoise.app():show_status("Only one send track available - please use either the 'Insert Send device' or the 'Route to new Send' shortcut")
  end
end


----------------------------------------------------------------------------------------------------
--adds a send track to the end of the pattern/tracks, instantly routes to there (-INF, KeepSource)
----------------------------------------------------------------------------------------------------
function route_to_new_send_track()
  local song = renoise.song()
  song:insert_track_at(#song.tracks + 1)
  local insert_spot = math.max(song.selected_device_index, 1)+1  -- math.max for if no instrument selected, +1 because the sampler/mixerdevice counts but you can't place a device before it
  local senddevice = song.selected_track:insert_device_at("Audio/Effects/Native/#Send", insert_spot)
  senddevice.active_preset_data = [[<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="9">
  <DeviceSlot type="SendDevice">
    <IsMaximized>true</IsMaximized>
    <SendAmount>
      <Value>0.0</Value>
    </SendAmount>
    <SendPan>
      <Value>0.5</Value>
    </SendPan>
    <DestSendTrack>
      <Value>]]..
  (song.send_track_count-1)..  -- because inside send devices the send tracks are counted starting with zero, just as CV destination stuff inside *devices
[[</Value>
    </DestSendTrack>
    <MuteSource>false</MuteSource>
    <SmoothParameterChanges>true</SmoothParameterChanges>
  </DeviceSlot>
</FilterDevicePreset>
]]
  song.selected_device_index=insert_spot
  song.selected_track_index=#song.tracks
end
--end Cas` code

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
