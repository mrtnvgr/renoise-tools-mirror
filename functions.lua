---------------------------------------------------------------------------
--Function for shortcut -- `TRT` Toggle Mix Output Stereo To Mono" 
-- makes reference track and master track output mono
---------------------------------------------------------------------------
function mono_tog()
  --get values
  local song = renoise.song()
  --table that holds 2 indexes; the master tack and the reference track
  local track_index_tab = {}
  --the master track is held at position 1
  local MASTER_TRACK_TABLE_POSITION = 1
  --flag to indicate that the mono device has been toggled so it must exist and no mono device needs to be added
  local mono_dev_toggled = false
  --flag to record the master track mute state
  local mute_state = true
  
  --loop backwards through tracks to get master track index
  for trk = #song.tracks, 1, -1 do
    --make sure track is a sequencer track
    if song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER then
     --add master track to the first position of the table
     table.insert(track_index_tab,trk)
     break
    end
  end
  
  --loop forwards through tracks to get reference track index, if it exists
  for trk = 1, #song.tracks do
    --make sure track is a sequencer track
    if song.tracks[trk].name == "`REF` ACTIVE" or 
       song.tracks[trk].name == "`REF` MUTED" then
       --if ref track exists then add it to the secon position of the table
       table.insert(track_index_tab,trk)
     break
    end
  end
  

  
  --if there is a reference track then the tables length will be 2; if only master then tab length will be 1
  --search (both) tracks for an already added "Mono Mix" device to toggle
  for j = 1,#track_index_tab do

    --get devices on track
    local trk_devs = song.tracks[track_index_tab[j]].devices
    
    if j == MASTER_TRACK_TABLE_POSITION then
      --devices in current track
      for i = 1,#trk_devs do
        --if mono mix exists then invert its active state
        if trk_devs[i].display_name == "Mono Mix" then
          if trk_devs[i].is_active == true then
            trk_devs[i].is_active = false
            --record mute state
            mute_state = false
            mono_dev_toggled = true
            break
          end
          if trk_devs[i].is_active == false then
            trk_devs[i].is_active = true
            --record mute state
            mute_state = true
            mono_dev_toggled = true
            break
          end
        end
      end
    
    else --when j == 2 then do the same for a reference track
      
      --devices in reference track
      for i = 1,#trk_devs do
        --if mono mix exists then invert its active state
        if trk_devs[i].display_name == "Mono Mix" then
          trk_devs[i].is_active = mute_state
          mono_dev_toggled = true
          break
        else
          mono_dev_toggled = false
        end
      end
    end  
    if mono_dev_toggled then
      --Just reset flag for next iteration as "Mono Mix" device already in this track
      mono_dev_toggled = false
    else
    --add the device to this track
      
      --no mono mix found, so add one at end of chain and set it to mono
      renoise.song().tracks[track_index_tab[j]]:insert_device_at("Audio/Effects/Native/Stereo Expander", #trk_devs+1)
      --set parameter 1 of device to mono
      song.tracks[track_index_tab[j]].devices[#trk_devs+1].parameters[1].value = 0
      --change display name
      song.tracks[track_index_tab[j]].devices[#trk_devs+1].display_name = "Mono Mix"
      
        song.tracks[track_index_tab[j]].devices[#trk_devs+1].active_preset_data =
        --Note to get this from renoise; export the preset from the device, paste into notepad (a new .lua file) then open in renoise terminal
        --copy pasting direct does not work-- 
         [[<?xml version="1.0" encoding="UTF-8"?>
        <FilterDevicePreset doc_version="10">
          <DeviceSlot type="StereoExpanderDevice">
            <IsMaximized>true</IsMaximized>
            <MonoMixMode>L+R</MonoMixMode>
            <StereoWidth>
              <Value>0.0</Value>
            </StereoWidth>
            <SurroundWidth>
              <Value>0.0</Value>
            </SurroundWidth>
          </DeviceSlot>
        </FilterDevicePreset>]]
        
      --set mute state according to masters mute state
      song.tracks[track_index_tab[j]].devices[#trk_devs+1].is_active = mute_state
    end
  end 
  --update status
  if mute_state == true then
    renoise.app():show_status("Toggle Reference Track Tool: (Mix Playing Mono)")   
  else
    renoise.app():show_status("Toggle Reference Track Tool: (Mix Playing Stereo)") 
  end  
end

--------------------------------------------
--enable autoseek in current selected sample
--------------------------------------------
function enable_autoseek()
  local song = renoise.song()

  --check for sample
   if not song.selected_sample.sample_buffer.has_sample_data then
    renoise.app():show_status([[Toggle Reference Track Tool: (No Sample Selected - Select A Sample To Use This Shortcut)]])  
    return
  end
  --toggle to opposite value
  if song.selected_sample.autoseek == false then
    song.selected_sample.autoseek = true
    renoise.app():show_status("Toggle Reference Track Tool: (Autoseek For Sample: `"..song.selected_sample.name.."` ON)")
  else
    song.selected_sample.autoseek = false
    renoise.app():show_status("Toggle Reference Track Tool: (Autoseek For Sample: `"..song.selected_sample.name.."` OFF)")
  end
end
-------------------------
--select reference track
-------------------------
function go_to_ref_track()
  
  local song = renoise.song()
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do
      --find toggle gainer
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then 
        song.selected_track_index = track
        return
      end
    end
  end
end
--------------------------------------------------------------------------
--Enables autoseek on the selected instrument sample slot 1
--creates a new track at pos 1 in pattern, renames it to `Reference: MUTED`
--Adds a muted gainer named "Reference Gainer" to that track
--------------------------------------------------------------------------
function create_reference_track(routing)


  local song = renoise.song()
  local inst = song.selected_instrument_index
  local master_idx = (song.sequencer_track_count+1)
    
  --check a valid routing
  local routing_valid = false
  for i = 1, #renoise.song().tracks[master_idx].available_output_routings do
    if routing == renoise.song().tracks[master_idx].available_output_routings[i] then 
       routing_valid = true
    end
  end
  --return early if not a valid routing after driver selection change etc
  if not routing_valid then
     renoise.app():show_status("Toggle Reference Track Tool: ("..routing.." Not a valid routing, to refresh menu change the selected instrument, then try again)")
     routing = "Output 1 + 2" --3.0 hack
  end
  
  --check sample is loaded
  if #song.instruments[inst].samples < 1 then
    renoise.app():show_status("Toggle Reference Track Tool: (No sample loaded in the currently selected instrument slot)")
    return
  end

  --enable autoseek in current selected sample
  if song.instruments[inst].samples[1].autoseek == false then
    song.instruments[inst].samples[1].autoseek = true
  end
  
  --check for already added reference tracks by searching for `Reference Gainer`
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do
    
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then
        renoise.app():show_status("Toggle Reference Track Tool: (There is already a reference track present in song)")  
        return --return early if found
      end
    end 
  end
  
  --create a new track at index 1
  song:insert_track_at(1)
  --rename it
  song.tracks[1].name = "`REF` ACTIVE"--..song.selected_instrument.name  
  --add a C-4 at the first line of pattern 1
  song.patterns[1].tracks[1].lines[1].note_columns[1].note_value = 48
  song.patterns[1].tracks[1].lines[1].note_columns[1].instrument_value = (inst - 1)

  --set routing
  song.tracks[1].output_routing = routing
  --make sure track is selected
  song.selected_track_index = 1
  --solo it
  for track = 2, song.sequencer_track_count do
    song.tracks[track]:mute()
  end
  --add a reference gainer
  local ref_gainer = song.tracks [1]:insert_device_at("Audio/Effects/Native/Gainer", 2) --after track device
  --set reference gainers values
  ref_gainer.display_name = "Reference Gainer"
  ---set vol to -INF Db i.e. MUTE 
  ref_gainer.parameters[1].value  = 0
  --hide volume slider in mixer
  ref_gainer:parameter(1).show_in_mixer = false
  --minimize in DSP lane
  song.tracks[1].devices[2].is_maximized = false
  --disable the gainer
  song.tracks[1].devices[2].is_active = false
  renoise.app():show_status("Reference Track Created")  
end

---------------------------------------------------------------------------
--toggles the tracks mute/solo state relative to all other traks in renoise
---------------------------------------------------------------------------
function toggle_ref_track()

  local song = renoise.song()
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do
      --find toggle gainer
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then  
        --if it`s on (meaning track is muted)
        if song.tracks[track].devices[devs].is_active then
          --bypass gainer allowing sound back through
          song.tracks[track].devices[devs].is_active = false
          --solo the track gainer is on
          song.tracks[track]:solo()
          if string.find(song.tracks[track].name, "MUTED") then
            --replace send prefix `MUTE: ` with empty string
            song.tracks[track].name = string.gsub(song.tracks[track].name, "MUTED", "")  
          end
          --set name to ON
          song.tracks[track].name = song.tracks[track].name.."ACTIVE"
          return --all done
        else
          song.tracks[track].devices[devs].is_active = true
          --unmute all tracks
          for trk = 1,#song.tracks do
            song.tracks[trk]:unmute()                      
          end
          --remute the track with the reference gainer on it
         -- song.tracks[track]:mute()
         --
         -----------------------------
         -- song.tracks[track]:mute()
          if string.find(song.tracks[track].name, "ACTIVE") then
            --replace send prefix `MUTE: ` with empty string
            song.tracks[track].name = string.gsub(song.tracks[track].name, "ACTIVE", "")  
          end
          --set name to off
          song.tracks[track].name = song.tracks[track].name.."MUTED"
          return --all done
        end
      end
    end
  end
end

---------------------------------------------------------------------------
--toggles the tracks mute/solo state relative to all other traks in renoise
---------------------------------------------------------------------------
function toggle_ref_track_and_selected_track()

  local song = renoise.song()
  local current_track = song.selected_track_index
  --to get the reference track index so we bypass the solo action if on the ref track
  local ref_track = nil 
  
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do
      --get ref_track index and return early if we are on it
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then 
        ref_track = track 
        if ref_track == current_track then
          renoise.app():show_status([[Toggle Reference Track Tool: (Trying To Toggle Reference Track With Itself
- Select Another Track For This Shortcut To Work)]])     
          return
        end
      end
      
      --find toggle gainer
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then 
        --if it`s on (meaning track is muted)
        if song.tracks[track].devices[devs].is_active then
          --bypass gainer allowing sound back through
          song.tracks[track].devices[devs].is_active = false
          --change track name
          if string.find(song.tracks[track].name, "MUTED") then
            --replace send prefix `MUTE: ` with empty string
            song.tracks[track].name = string.gsub(song.tracks[track].name, "MUTED", "")  
          end
          --set name to ON
          song.tracks[track].name = song.tracks[track].name.."ACTIVE"
            --solo the track gainer is on if not ref track
          if ref_track ~= current_track then
            song.tracks[track]:solo()
            return --all done
          end
        else
          song.tracks[track].devices[devs].is_active = true
          --change track name
          if string.find(song.tracks[track].name, "ACTIVE") then 
            --replace send prefix `MUTE: ` with empty string
            song.tracks[track].name = string.gsub(song.tracks[track].name, "ACTIVE", "")  
          end
          --set name to off
          song.tracks[track].name = song.tracks[track].name.."MUTED"
           --solo the track gainer is on if not ref track
          if ref_track ~= current_track then
            song.tracks[current_track]:solo()
            return --all done
          end
        end
      end
    end
  end
end

--note for later
--renoise.song().instruments[1].samples[1]:insert_slice_marker(total_frames/2)
----------------------------------------------------------------------------------
---function sets extends a shorter song length to length of longer selected sample
----------------------------------------------------------------------------------

function extend_song_to_sample_length()

  local song = renoise.song()
  
  if not song.selected_sample.sample_buffer.has_sample_data then
    renoise.app():show_status([[Toggle Reference Track Tool: (No Sample Selected - Select A Sample To Use This Shortcut)]])  
  return
  end
  
  local selected_sample = song.selected_sample
  --sample length in seconds = total_frames / sample_rate
  --sample rate == frames/seconds
  local sample_rate = selected_sample.sample_buffer.sample_rate
  local total_frames = selected_sample.sample_buffer.number_of_frames
  
  local sample_time_in_seconds = total_frames/sample_rate
  local sample_time_in_minutes = sample_time_in_seconds/60
  
  local bpm = song.transport.bpm
  local lpb = song.transport.lpb
  
  --get sample length in beats
  local sample_length_in_beats = sample_time_in_minutes * bpm
  --current song length in beats
  local song_length_beats = song.transport.song_length_beats
  --difference between the two
  --difference_in_beats is negative if song shorter and v.versa
  local difference_in_beats = song_length_beats - sample_length_in_beats 
  local beats_per_pattern = 64/lpb
  local difference_in_patterns = difference_in_beats/beats_per_pattern
  
  --song shorter than wav
  if difference_in_beats < 0 then
    local patterns_to_add = difference_in_patterns
    patterns_to_add = -(math.ceil(patterns_to_add)) + 1 -- round up, make positive and +1(covers any fraction of pattern)
                                                         -- TODO: Go through and refine (works ok for now though)                                                    
    for i = 1,patterns_to_add do
      if #song.sequencer.pattern_sequence < 1000 then
        song.sequencer:insert_new_pattern_at(#song.sequencer.pattern_sequence + 1)
        renoise.app():show_status("Toggle Reference Track Tool: ("..i.." Patterns Added)")
      else
        renoise.app():show_status("Toggle Reference Track Tool: (Renoise`s 1000 Pattern Limit Reached)")
        break
      end 
    end
 
  else --song longer than wav
    local patterns_to_delete = math.floor(difference_in_patterns)
    -- if nothing to do as song is correct length already
    if patterns_to_delete == 0 then
      renoise.app():show_status("Toggle Reference Track Tool: Song Already Similar Length To Sample `"..song.selected_sample.name.."`")  
    end
    for i = 1,patterns_to_delete do --automatically rounds down as patterns_to_delete generally a fraction
      --check is empty else break as pattern data present
      if song.patterns[song.sequencer.pattern_sequence[#song.sequencer.pattern_sequence]].is_empty then
        song.sequencer:delete_sequence_at(#song.sequencer.pattern_sequence)
        renoise.app():show_status("Toggle Reference Track Tool: ("..i.." Patterns Deleted)")
      else
        renoise.app():show_status("Toggle Reference Track Tool: (Sample: `"..song.selected_sample.name.."` Shorter Than Song: Song Set To Last Active Pattern)")
        break
      end
    end
  end
end



---------------------------------
-- called on doc open to add menu
---------------------------------
function instrument_box_menu()
  
  local song = renoise.song()
  local master_idx = (song.sequencer_track_count+1)
  --where is the master is routed?
  local mst_route = renoise.song().tracks[master_idx].output_routing
  
  
   --1) SHOW GUI TOOLS-MENU
  if not renoise.tool():has_menu_entry("Main Menu:Tools:Ledger`s Scripts:Toggle Reference Track GUI") then
    renoise.tool():add_menu_entry {
      name = "Main Menu:Tools:Ledger`s Scripts:Toggle Reference Track GUI",  
      invoke = function()main()  end  
    }
  end
  
   --2) Inst.box
  if not renoise.tool():has_menu_entry("Instrument Box:Toggle Reference Track:Toggle Reference Track GUI") then
    renoise.tool():add_menu_entry {
      name = "Instrument Box:Toggle Reference Track:Toggle Reference Track GUI",  
      invoke = function()main()  end  
    }
  end
  
  --3) Inst. box
  if not renoise.tool():has_menu_entry("Instrument Box:Toggle Reference Track:Create Reference Track") then
    renoise.tool():add_menu_entry {
      name = "Instrument Box:Toggle Reference Track:Create Reference Track",  
      invoke = function() create_reference_track(mst_route) end  
    }
  end
  
  --4) Inst. box
  if not renoise.tool():has_menu_entry("Instrument Box:Toggle Reference Track:Adjust Song To Selected Sample Length") then
    renoise.tool():add_menu_entry {
      name = "Instrument Box:Toggle Reference Track:Adjust Song To Selected Sample Length",  
      invoke = function() extend_song_to_sample_length() end  
    }
  end
  

  
 
  
 
end


--notifier to add menu on new doc
renoise.tool().app_new_document_observable:add_notifier(function() instrument_box_menu() end) 




