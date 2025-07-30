--This file contains self contained functions that are bound to keyboard shortcuts in main.lua
--i.e. they are self contained as in call no other custom functions/global variables

--1 (shortcut number) 
----------------------------------------------------------
--Function selects next send track in the song when called
--if a send not already selected it goes to send 1 
----------------------------------------------------------
function cycle_send_tracks()
  local song = renoise.song()
  local selected_track = song.selected_track_index
  local num_of_sends = song.send_track_count
  
  --no send tracks in song so return
  if num_of_sends == 0 then
    return
  end
 
  local first_send = (#song.tracks - num_of_sends)  + 1 --+1 master track
  local already_on_send = false
  
  --check if we are already on a send track
  for i = first_send, first_send + (num_of_sends - 1) do
    if selected_track == i then
      already_on_send = true
      break
    end 
  end
  --if not then select the first send track
  if not already_on_send then
    song.selected_track_index = first_send
    return 
  end
  --if we are on a send then cycle through them
  --if on last track, goto first send 
  if song.selected_track_index == #song.tracks then
    song.selected_track_index = first_send
  else --goto next send
    song.selected_track_index = (song.selected_track_index  + 1)
  end
end

--2
------------------------------------------------------
--adds a send track to the end of the pattern/tracks
------------------------------------------------------
function add_a_new_send_track()
  
  local song = renoise.song()
  song:insert_track_at(#song.tracks + 1)
  
end

--3
------------------------------------------------------
--adds a send track at the currently selected device
--with a preset of -INF send amount + keep source enabled
--thanks to Cas for code suggestion
------------------------------------------------------
function add_a_new_send_device()
  
  local song = renoise.song()
  local insert_spot
   --return early if on master track as adding sends fire an error here
  if song.selected_track.type == renoise.Track.TRACK_TYPE_MASTER then
    return
  end
  -- math.max for if no device selected, +1 because 
  -- the sampler/mixerdevice counts but you can't place a device before it
  if (song.selected_device ~= nil) and (song.selected_device.display_name == "Silent Gainer")  then
    insert_spot = math.max(song.selected_device_index, 1) --insert send before Silent Gainer
  else
    insert_spot = math.max(song.selected_device_index, 1)+1 
  end
  local send_device = song.selected_track:insert_device_at("Audio/Effects/Native/#Send", insert_spot)
  send_device.active_preset_data =
  
     [[<?xml version="1.0" encoding="UTF-8"?>
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
        <Value>0</Value>
      </DestSendTrack>
      <MuteSource>false</MuteSource>
      <SmoothParameterChanges>true</SmoothParameterChanges>
    </DeviceSlot>
  </FilterDevicePreset>
  ]]
 
  -- select added send device
  song.selected_device_index = insert_spot
  -- if send is muted then unmute
  local send_number = 1 --default routing for new send device
  local non_send_tracks = (song.sequencer_track_count + 1)
  local first_send = non_send_tracks + send_number
  local send_index = non_send_tracks + send_number
  
  --unmute all sends
  if not song.tracks[send_index].mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
    for index = first_send,#song.tracks do
     renoise.song().tracks[index]:unmute()
    end
  end 
end

--4
-----------------------------------------------------------------
--Adds/removes a `Silent Gainer` (gainer with volume set to -INF dB) to each track
--This means the only audible sound comes from the send tracks.
--A toggle flag inverts the function on each run
-----------------------------------------------------------------
function mute_all_tracks_with_silent_gainer()

--declare toggle flag
local add_silent_gainer = true
--set string to prefix sends with
local send_prefix = "MON: "

  local song = renoise.song()
  local num_of_seqs = song.sequencer_track_count --non master or sends

  --check tracks for Silent Gainer presence and set flag accordingly
  for track = 1, num_of_seqs  do
    if #song.tracks[1].devices > 1 then
      for devs = #song.tracks[track].devices,2,-1 do  -- do it in reverse to deal with dev number changing
        if song.tracks[track].devices[devs].display_name == "Silent Gainer"  then
          add_silent_gainer = false
          break
        end
      end 
      if add_silent_gainer == false then
        break
      end
    end
  end
  
  --delete all `Silent Gainers` to unmute tracks
  if not add_silent_gainer then
  renoise.app():show_status("Go To Sends Tool: `All Instrument tracks Audible`")
  
  --Remove "MON" prefix from Send names to show that monitoring is no longer active
  local track_count = #song.tracks
  while send_number(track_count) do
    if string.find(song.tracks[track_count].name, send_prefix) then
    --replace send prefix with empty string
      song.tracks[track_count].name = string.gsub(song.tracks[track_count].name, send_prefix, "")  
    end
    track_count = track_count - 1
  end
    
    for track = 1, num_of_seqs  do
      if #song.tracks[track].devices > 1 then
        for devs = #song.tracks[track].devices,2,-1 do  -- do it in reverse to deal with dev number changing
          if song.tracks[track].devices[devs].display_name == "Silent Gainer"  then
            song.tracks[track]:delete_device_at(devs)
          end
        end
      end
    end
     
  else
  --Add `Silent Gainers` to each sequencer track (instrument tracks) so only sends are audible 
  renoise.app():show_status("Go To Sends Tool: `All Instrument tracks Silent : Monitoring Sends`")
 
  --Prefix Send Names with "MON" to show that monitoring is active
  local track_count = #song.tracks
  while send_number(track_count) do
    song.tracks[track_count].name = send_prefix..song.tracks[track_count].name
    track_count = track_count - 1
  end
   
  
    for track = 1, num_of_seqs  do
      if song.tracks[track].group_parent ~= nil then  
        --dont add silent gainer to grouped tracks as there might
        --be a send in the group track that still needs to receive audio
      else --add a silent gainer
         
         --insert at end of device chain
         local insert_spot = #song.tracks[track].devices 
         local gainer_device = song.tracks[track]:insert_device_at("Audio/Effects/Native/Gainer", insert_spot+1)
         --set display name
         gainer_device.display_name = "Silent Gainer"
         --set volume to zero
         gainer_device:parameter(1).value = 0
         --hide volume slider in mixer
         gainer_device:parameter(1).show_in_mixer = false
         --minimize in DSP lane
         song.tracks[track].devices[insert_spot + 1].is_maximized = false
      end
    end
  end
  --invert boolean flag, so function toggles action on each call
  add_silent_gainer = not add_silent_gainer 
end

--5
------------------------------------------
--navigate from send device to send track
------------------------------------------
function go_to_send()
  
  local song = renoise.song()
  --check that there is a selected device on the track
  -- if not then return early
  if song.selected_device == nil then 
    return
  end
  --check We have send selected
  if song.selected_device.name == "#Send" then
    
    local total_non_sends = (song.sequencer_track_count + 1) --+1 to include master track
    local total_sends = song.send_track_count
    local send_number = (song.selected_device.parameters[3].value + 1) -- 3 = reciever parameter (0 to x) (+1 for Lua)
    
    song.selected_track_index = (total_non_sends + send_number)

  end
end 

--6
--------------------------------------
--Mutes and unmutes all sends at once
--------------------------------------
function toggle_sends_active_state()
  
  local song = renoise.song()

  local num_of_sends = song.send_track_count
  local first_send = (#song.tracks - num_of_sends)  + 1 --+1 master track
  local do_mute = false
  
  if renoise.song().tracks[first_send].mute_state == renoise.Track.MUTE_STATE_ACTIVE then
    do_mute = true
  else do_mute = false
  end
  --loop in reverse for number of sends
  for track = #song.tracks,first_send ,-1 do
    if do_mute then
      renoise.song().tracks[track]:mute()
    else
      renoise.song().tracks[track]:unmute()
    end
  end
end 


--7
------------------------------------------------------------------
--cycles through the routing of the currently selected send device
------------------------------------------------------------------
function cycle_send_device_target()

   local song = renoise.song()
   
  --check that there is a selected device on the track
  -- if not then return early
  if song.selected_device == nil then 
    return
  end
 
  
  --cycle target if on a send device
  if song.selected_device.name == "#Send" then
    local target_peram = song.selected_device.parameters[3]
    local send_index = (target_peram.value + 1) + (song.send_track_count + 1)
    
    --return to routing to first send routing if already on last and unmute target send
    if target_peram.value == (song.send_track_count - 1) then
    --  target_peram.value = 0 --send perameters count from zero in renoise
     -- send_index = (target_peram.value + 1) + (song.sequencer_track_count + 1)
     -- if not song.tracks[send_index].mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
    --    renoise.song().tracks[send_index]:unmute()
    --  end
    else
    --increment to next send routing and unmute target send
      target_peram.value = target_peram.value + 1
      send_index = (target_peram.value + 1) + (song.sequencer_track_count + 1)
      if not song.tracks[send_index].mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then 
        renoise.song().tracks[send_index]:unmute()
      end
    end
  end
end 

--8
------------------------------------------------------------------
--cycles through the routing of the currently selected send device
------------------------------------------------------------------
function cycle_send_device_target_backwards() 

   local song = renoise.song()
   
  --check that there is a selected device on the track
  -- if not then return early
  if song.selected_device == nil then 
    return
  end
 
  --cycle backwards target if on a send device 
  if song.selected_device.name == "#Send" then
    local target_peram = song.selected_device.parameters[3]
    local send_index = (target_peram.value + 1) + (song.send_track_count + 1)
    local non_send_tracks = (song.sequencer_track_count + 1)
    local ACTIVE = renoise.Track.MUTE_STATE_ACTIVE
    
    --return to routing to first send routing if already on last and unmute target send
    if target_peram.value == 0 then
      --target_peram.value = #song.tracks - (non_send_tracks + 1)--send perameters count from zero in renoise
     -- send_index = (#song.tracks)  
     -- if not song.tracks[send_index].mute_state ~= ACTIVE  then
     --   renoise.song().tracks[send_index]:unmute()
     -- end
    else
    --decrement to previous send routing and unmute target send
      target_peram.value = target_peram.value - 1
      send_index = (non_send_tracks) + (target_peram.value + 1) --send perameters count from zero in renoise 
      if not song.tracks[send_index].mute_state ~= ACTIVE  then 
        renoise.song().tracks[send_index]:unmute()
      end
    end
  end
end

--9
----------------------------------------
--make fx and group tracks color blended
----------------------------------------
function blend_group_color()
 
  local song = renoise.song()
  local GROUP = renoise.Track.TRACK_TYPE_GROUP
  local MASTER = renoise.Track.TRACK_TYPE_MASTER
  local SEQ = renoise.Track.TRACK_TYPE_SEQUENCER
  local mst_index = song.sequencer_track_count + 1
  local blend = nil
  --set master track to dull grey color
  song.tracks[mst_index].color = {0xA8,0xA8,0xA8} 
  
  --loop and change color blend for group and master tracks
  for track = 1,#song.tracks do

   if not (song.tracks[track].type == SEQ) then 
     --by only setting blend for the first non sequencer track
     --we get all blend levels in sync
     if not blend then
       blend = song.tracks[track].color_blend
     end
      -- when zero set to strongest blend  
      if blend == 0 then
        song.tracks[track].color_blend = 40
      else --when approaching zero set to 0
        if blend < 20 then 
          song.tracks[track].color_blend = 0
        else --decrement towards zero 
          song.tracks[track].color_blend = blend - 20
        end
      end
    end
  end
end 

--10
----------------------------------------------------------------------
-- Throw to Send, takes the selected DSP, puts it on a new send track
-- and replaces it with a send device to that new track
----------------------------------------------------------------------

function throw_to_send()

  local song = renoise.song()
   
  --check that there is a selected device on the track
  -- if not then return early
  if (song.selected_track_device == nil) or (song.selected_track_device_index == 1) then
    renoise.app():show_status("Go To Sends Tool: `Select A Device To Throw First`") 
    return
  end
  
  --current_track_index
  local selected_track_index = song.selected_track_index
  --selected_device index
  local dsp_index = song.selected_track_device_index
  
  local total_tracks = #song.tracks

  --copy selected device
  local device_path = song.selected_track_device.device_path
  local current_preset = song.selected_track_device.active_preset_data
  
  local selected_device_name = song.selected_track_device.display_name-- short name
  
  --get the device path so we can find out the short name from available device infos
  --later and rename the track to that.
  local sel_dev_path = song.selected_track_device.device_path
  
  --delete selected device
  song.tracks[selected_track_index]:delete_device_at(dsp_index)
  
  --set new index for new send after last track
  local new_send_index = total_tracks + 1
  --create a new send
  renoise.song():insert_track_at(new_send_index)--adds a send after master track
  
  --add deleted device to new send track
  song.tracks[new_send_index]:insert_device_at(device_path, 2)
  --copy preset data
  song.tracks[new_send_index].devices[2].active_preset_data = current_preset
  
  --insert send at original track pointing to new send
  local this_device = song.selected_track:insert_device_at("Audio/Effects/Native/#Send", dsp_index)
 
  --set parameter 3 of the send (Receiver) to new send track 
   this_device.parameters[3].value =  #song.tracks - song.sequencer_track_count - 2 --params count from 0
   
  --unmute the new send if muted
  if not song.tracks[new_send_index].mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
     song.tracks[new_send_index]:unmute()
  end 
  
  --rename send to thrown DSP (long name in case no short name found after)
  song.tracks[new_send_index].name = selected_device_name or "New Send"
  
  --get short name by looping through available devices
  for i = 1,#song.tracks[1].available_devices do
     --match previously selected device name to device infos to get short name.
    if song.tracks[1].available_device_infos[i].path == sel_dev_path then 
      --if found then rename the send track
      song.tracks[new_send_index].name = song.tracks[1].available_device_infos[i].short_name 
      break
    end
  end
end


















