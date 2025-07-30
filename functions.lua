--helper functions
--------------------------------------------------------------------
--helper function returns the Send Track Number from the passed Track Index
--if the track is not a send it will return nil
--------------------------------------------------------------------
function send_number(track_index)
  
  local song = renoise.song()
  --check it`s a valid track index
  if track_index > #song.tracks
    then return nil
  end 
 
  local num_of_seqs = song.sequencer_track_count --non master or sends
  local send_number = track_index - (num_of_seqs + 1)  --master track is the +1
  
  --make sure passed track index is a send
  if send_number > 0 then 
    return send_number
  else 
    return nil
  end
end


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
    --if device present
    if #song.tracks[track].devices > 1 then
      --loop devices
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
  if add_silent_gainer == false then
  renoise.app():show_status("Send Mixer Tool: `All Instrument tracks Audible`")
  
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
  renoise.app():show_status("Send Mixer Tool: `All Instrument tracks Silent : Monitoring Sends`")
 
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
