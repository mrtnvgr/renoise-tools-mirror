------------------------------------------------------------------------------------------
--Timer calls this function once every 50ms to update the GUI
------------------------------------------------------------------------------------------

--Parameter indexes for ahdsr device
BYPASS = 1
ATTACK = 1
HOLD = 2
DECAY = 3
SUSTAIN = 4
RELEASE = 5

ATTACK_SCALING = 6
DECAY_SCALING = 7
RELEASE_SCALING = 8

--Also called on initialisation of the script.
------------------------------------------------------------------------------------------
function set_gui_values()
  
  --set flag
  timer_updating = true
  --song object
  local song = renoise.song()
  local inst = song.selected_instrument_index
  
  --HOUSEKEEPING
  ---------------------
  --check GUI is active(can remain attached if GUI is closed by [X]), if not:
  --remove notifiers
  if my_dialog and (my_dialog.visible == false) then
   --remove all notifiers
    remove_notifiers()
    --reset flags
    timer_updating = false
    sample_or_instrument_selection_has_changed = false
    return 
  end
  
  --UPDATE GUI COLORS AND TEXT
  ----------------------------
  -----------------
  --NOTE could be more efficient with track notifier on a global---
  --update track list as user may have added or deleted tracks
  vb.views["track name"].items = get_renoise_track_names()
  -----------------
   
  --If no sample selected then de-activate valuebox
  if song.selected_sample_index == nil then
    vb.views["sample offset"].active = false
  else
    vb.views["sample offset"].active = true
  end
  --update value to match sample offset cammand in instrument phrase if present               
  if (#song.instruments[inst].phrases > 0) and (song.instruments[inst].phrases[1]:line(1).effect_columns[1].number_string == "0S") then 
    vb.views["sample offset"].value = song.instruments[inst].phrases[1]:line(1).effect_columns[1].amount_value
  else
    vb.views["sample offset"].value = 0
  end
  
  --update phrase present light/button
  if 1 == false then-- (song.instruments[inst]:can_insert_phrase_at(1) == false)then 
    vb.views["phrase present LED"].color = COLOR_ORANGE
  else
    vb.views["phrase present LED"].color = COLOR_GREY
  end
  
  --check for present phrase and set LED button accordingly
  if #song.instruments[inst].phrases > 0 then
    vb.views["phrase present LED"].color = COLOR_ORANGE
  else
    vb.views["phrase present LED"].color = COLOR_GREY
  end
  
  --Update left colour button; indicate if a sample present
  if first_sample_name() ~= "" then
    --sample present
    vb.views["sample is_present colour"].color = COLOR_GREEN
 
  --if the sample is present but the neares note does not match it, indicate with red button
  else
    vb.views["sample is_present colour"].color = COLOR_GREY
  end
  
  --reset
  vb.views["sample is_present colour"].text = ""
  
  vb.views["capture"].color = COLOR_GREEN
  
   --if empty pattern track then mark it
  if song.selected_pattern_track.is_empty then
    vb.views["capture"].text = "E"
    vb.views["capture"].color = COLOR_GREY
  else --not an empty pattern track so:
    vb.views["capture"].text = "" 
    vb.views["sample is_present colour"].text = "" 
  end
  
  
  
  
  
  --Update Graphic Envelope Button (renoise mod envelope)
  --------------------------------
  --default button color to GREY
  vb.views["graph env button"].color = COLOR_GREY
  --modulation set which would contain graphic envelope if added by user:
  local mod_set = song.instruments[song.selected_instrument_index].sample_modulation_sets[1]
  
  --auto-close graph envelope as selected instrument does not match the encvelope
 -- mod_set.devices[i].external_editor_visible = false
  
  --loop all instruments and close any open envelopes
  for i = 1,#song.instruments do
    local mod_set = song:instrument(i):sample_modulation_set(1)
    --loop devices in modulation set
    for j = 1,#mod_set.devices do
      --if envelope exists and visible
      if mod_set.devices[j].display_name == "QuickVol Envelope" and
        mod_set.devices[j].external_editor_visible == true then
       
          if i ~= song.selected_instrument_index then
           -- mod_set.devices[j].external_editor_visible = false
            --open editor for current instrument
           -- if mod_set.devices[song.selected_instrument_index]
            
            
          else
           vb.views["graph env button"].color = COLOR_ORANGE
         end
      end
    end
  end
  
  
  -------------------------------------------------------
  --[For GRAPHIC ENVELOPE Checkbox] loop to see if Mod ENVELOPE is enabled
  -------------------------------------------------------
  --default to off
  vb.views["graph env check"].value = false
  --loop devices in modulation set of selected instrument
  for j = 1,#mod_set.devices do
    if mod_set.devices[j].display_name == "QuickVol Envelope" then
      --device is found:
      if mod_set.devices[j].enabled == false then
        vb.views["graph env check"].value = false
      else
        vb.views["graph env check"].value = true
      end
    end
  end
  
  --------------------------------------------
  --reset ahdsr to nil before re-assigning it (nil works as a flag in the next bits of code)
  -------------------------------------------
  ahdsr = nil
  
  --1 Look For already present ahdsr device, if found assign it to ahdsr variable
  for i = 1, #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices do
    --if one is found then SET TO THAT AHDSR as ahdsr object; i.e. the one we will control from the tool GUI
    if song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i].name == "Volume AHDSR" then
      ahdsr = song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i]
      break
    end
  end
  
  --(CASE 1) No AHDSR loaded in instrument modulation chain.
  --so disable controls
  -----------------------------------------------------
  if ahdsr == nil then
    
    --set track name to show in popup
    vb.views["track name"].value = song.selected_track_index  ---- string.sub(song.selected_track.name, 1, 30)
    
    --set the right hand color button to grey to show there is no envelope
  --  vb.views["sample present colour 2"].color = COLOR_GREY
    vb.views["capture"].color = COLOR_GREY
   
    --update names to show no samples are in the intrument 
    vb.views["inst name"].text = selected_instrument_name()
    vb.views["samp name"].text = first_sample_name()
        
    --now disable controls ahdsr
    vb.views["attack"].active = false
    vb.views["hold"].active = false
    vb.views["decay"].active = false
    vb.views["sustain"].active = false
    vb.views["release"].active = false
      
    --set readout
    vb.views["readout"].text = ""
    
    --blank slider names --"   Atk   Hold   Dcay   Sus    Rel"
    vb.views["slider names"].text = ""
    --keep the checkbox active so we can add a new cevice, just set it to off (false)
    vb.views["enabled"].value = false
    
    --zero out gui values
    vb.views["attack"].value = 0
    vb.views["hold"].value = 0
    vb.views["decay"].value = 0
    vb.views["sustain"].value = 0
    vb.views["release"].value = 0
    --slope rotaries
    vb.views["attack slope"].value = 0
    vb.views["decay slope"].value = 0
    vb.views["release slope"].value = 0
    --reset flags
    timer_updating = false
    sample_or_instrument_selection_has_changed = false
    return
  end
  
  --(CASE 2) AHDSR device found loaded in instrument:
  --so update gui sliders etc. to match
  ----------------------------------------------------------
  
  --set the right hand color button to yellow if decice is enabled but blue if it is not
  if ahdsr.enabled then
   -- vb.views["sample present colour 2"].color = COLOR_YELLOW
    --now check if the selected intrument matches the track, turn the button red if not
    if (check_selected_track_and_inst_match() == false) and (ahdsr) then  
      --set the capture color to red
      vb.views["capture"].color = COLOR_RED
      vb.views["sample is_present colour"].text = CAPTURE
      if song.selected_pattern_track.is_empty == false then
        vb.views["capture"].text = CAPTURE
      end
    end
  else
   --envelope temporarily bypassed 
   vb.views["capture"].color = COLOR_BLUE
   vb.views["sample is_present colour"].text = ""
  end
  
  --update track and instrument name on GUI
  --set track name to show in popup
  vb.views["track name"].value = song.selected_track_index  ---- string.sub(song.selected_track.name, 1, 30)

  vb.views["inst name"].text = selected_instrument_name()
  vb.views["samp name"].text = first_sample_name()  
  
  --enable slider names --"   Atk   Hold   Dcay   Sus    Rel"
  vb.views["slider names"].text = slider_name_string
  
  --set readout this flag is conreolled by the two notifiers in the tool
  if (sample_or_instrument_selection_has_changed == true) then
    vb.views["readout"].text = "----"
  end

  --set whether the controls are ACTIVE by the device state this locks the sliders if the ahdsr is bypassed
  --in order to stop inadvertant adjustments that wouldn`t be heard
  vb.views["attack"].active = ahdsr.enabled
  vb.views["hold"].active = ahdsr.enabled
  vb.views["decay"].active = ahdsr.enabled
  vb.views["sustain"].active = ahdsr.enabled
  vb.views["release"].active = ahdsr.enabled
  --we need to be able to switch envelope on and off so set checkbox enabled here
  vb.views["enabled"].active = true
 -- vb.views["in sampler"].text = "Enable Envelope:"  

  --set the slider VALUES from ahdsr
  vb.views["attack"].value = ahdsr:parameter(ATTACK).value
  vb.views["hold"].value = ahdsr:parameter(HOLD).value
  vb.views["decay"].value = ahdsr:parameter(DECAY).value
  vb.views["sustain"].value = ahdsr:parameter(SUSTAIN).value
  vb.views["release"].value = ahdsr:parameter(RELEASE).value
  vb.views["enabled"].value = ahdsr.enabled

  --AHDSR slope values have a range from [-1 to +1].  We need to scale this to [0 to 1] to fit the rotaries
  local attack_slope_val = 0.5 + (ahdsr:parameter(ATTACK_SCALING).value/2) 
  local decay_slope_val = 0.5 + (ahdsr:parameter(DECAY_SCALING).value/2)
  local release_slope_val = 0.5 + (ahdsr:parameter(RELEASE_SCALING).value/2)
  
  
  --slope rotaries
  vb.views["attack slope"].value = attack_slope_val
  vb.views["decay slope"].value = decay_slope_val
  vb.views["release slope"].value = release_slope_val

  --reset timer flag
  timer_updating = false
  sample_or_instrument_selection_has_changed = false

end --eof
-------------------------
-------------------------
-------------------------
