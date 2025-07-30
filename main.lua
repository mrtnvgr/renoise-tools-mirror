--include other files from the tool
-----------------------------------
--require "functions"
require "timer_notifier_function"

----------
--keybinds
----------
--Open tool
renoise.tool():add_keybinding {
  name = "Global:Tools:`QVA` Quick Vol ADHSR",
  invoke = function()main_toggle()end
  
}
--------------
--Toggle view
--------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`QVA` Toggle Modulation To Pattern View",
  invoke = function()toggle_through_pattern_and_mod_view()end
  
}
-----------------
--main menu entry
-----------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Quick Vol ADHSR",
  invoke = function() main_start()
  end
}
-----------------------
--intrument menu entry
-----------------------
renoise.tool():add_menu_entry {
  name = "Instrument Box:Quick Vol ADHSR",
  invoke = function() main_start()
  end
}



---------------
-- Globals--
---------------
---------------
--GUI
my_dialog = nil
vb = renoise.ViewBuilder()
--variable to hold AHDSR device object
ahdsr = nil

bypass_set_adsr_from_slider = false
slider_name_string = "Atk   Hold   Dcy   Sus    Rel"
letter_update = false

--flags
timer_updating = false
sample_or_instrument_selection_has_changed = false

function change_sample_selection_flag()
  sample_or_instrument_selection_has_changed = true
end

--constants
CAPTURE = ">"

--e.g. For changing vb.views["sample present colour 2"].color when states change
COLOR_GREY = {40,40,40}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}--COLOR_GREEN = {0x10,0xFF,0x10}

--Parameter indexes for ahdsr device
BYPASS = 1
ATTACK = 1
HOLD = 2
DECAY = 3
SUSTAIN = 4
RELEASE = 5

--toggle the tool open and closed (keyboard shortcut start-up)
-------------------------------------------------------------
function main_toggle()
----------------------
 --close dialog if it is open
  if (my_dialog and my_dialog.visible) then 
     --remove all notifiers
     remove_notifiers()
     --close dialog
     my_dialog:close()
     --reset globals
     ahdsr = nil
     --reset global my_dialog
     my_dialog = nil 
     return
  else --run main
    main()
  end
end

--always open/ restart tool (menu entry start-up)
-------------------------------------------------
function main_start()
---------------------
  if (my_dialog and my_dialog.visible) then 
     --remove all notifiers
     remove_notifiers()
     --close dialog
     my_dialog:close()
     --reset globals
     ahdsr = nil
     --reset global my_dialog
     my_dialog = nil 
  end
  --run main
  main()
end
----------------------------------------------------------


renoise.tool():add_keybinding {
  name = "Global:Tools:`QVA` Quick Vol Open Envelope",
  invoke = function()add_or_open_envelope_device()end
  
}
----------------------------------------------------------------------------------
--function to add an envelope device in the modulation set (after the AHDSR if present)
----------------------------------------------------------------------------------
function add_or_open_envelope_device()
--------------------------------------

   local song = renoise.song()
   --1 Look For Already present envelope
   for i = 1, #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices do
     --if one is found then SET TO THAT AHDSR as ahdsr object; i.e. the one we will control from the tool GUI
     local dev = song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i]
     if dev.display_name == "QuickVol Envelope" and
       type(dev == "SampleEnvelopeModulationDevice") then --make sure an envelope device
        --toggle external editor'
        if dev.external_editor_visible == true then
          dev.external_editor_visible = false
        else
          dev.external_editor_visible = true
        end
        return
     end
   end
   
  -- oprint(song.instruments[song.selected_instrument_index].sample_modulation_sets[1])
                  
   --if no envelope device is present then add one
   local device_count = #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices
   local new_envelope = song.instruments[song.selected_instrument_index].sample_modulation_sets[1]:insert_device_at("Modulation/Envelope",1,device_count+1)--index
  
   --create default points for envelope
   new_envelope:add_point_at(1,1)
   new_envelope:add_point_at(100,1)

   new_envelope.display_name = "QuickVol Envelope"
   new_envelope.external_editor_visible = true

   --API STUFF
  --if (type(renoise.song().instruments[1].sample_modulation_sets[1].devices[1]) == "SampleEnvelopeModulationDevice") then
   -- renoise.song().instruments[1].sample_modulation_sets[1].devices[1].external_editor_visible = true
  --end
  
end

--for the checkbox to add or toggle graphinc envelope on/off
--------------------------------------
function add_or_enable_envelope_device()
--------------------------------------
  
  --bypass when called by timer
  if timer_updating == true then
    return
  end

  local song = renoise.song()
   --1 Look For Already present envelope
   for i = 1, #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices do
     --if one is found then SET TO THAT AHDSR as ahdsr object; i.e. the one we will control from the tool GUI
     local dev = song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i]
     if dev.display_name == "QuickVol Envelope" and
       type(dev == "SampleEnvelopeModulationDevice") then --make sure an envelope device
        --toggle axctive state'
        if dev.enabled == true then
          dev.enabled = false
        else
          dev.enabled = true
        end
        return
     end
   end

  --if no envelope device is present then add one
   local device_count = #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices
   local new_envelope = song.instruments[song.selected_instrument_index].sample_modulation_sets[1]:insert_device_at("Modulation/Envelope",1,device_count+1)--index
   
   --create default points for envelope
   new_envelope:add_point_at(1,1)
   new_envelope:add_point_at(100,1)
   
   new_envelope.display_name = "QuickVol Envelope"
   new_envelope.external_editor_visible = true
   --turn button orange as window will now be open
   vb.views["graph env button"].color = COLOR_ORANGE
end
---


-----------------------------------------------------------------------------------------
--Function to iterate over the pattern -> true if selected instrument found, false if not
-----------------------------------------------------------------------------------------
function check_selected_track_and_inst_match()

  local pattern_iter = renoise.song().pattern_iterator
  local track_index = renoise.song().selected_track_index 
  local current_inst_number = (renoise.song().selected_instrument_index - 1) --lua couns from 1 
  local pattern_index = renoise.song().selected_pattern_index
  
  --Zero is returned when send/ master selected
  if renoise.song().tracks[track_index].visible_note_columns == 0 then
   return false
  end
  --loop through pattern_track
  for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index,true) do  --true for visible oonly
    -- if find a note matching the selected instrument then return             
    if current_inst_number == line.instrument_value then
      return true
    end
  end
  -- if we get here no matching note was found
  return false
end

-------------------------
--get renoise track names
-------------------------
function get_renoise_track_names()
  local song = renoise.song()
  local track_name_table = {}
  for track = 1,#song.tracks do
    --if song.tracks[track].type == renoise.Track.TRACK_TYPE_SEQUENCER then
      table.insert(track_name_table,song.tracks[track].name)
   -- end
  end
  
  return track_name_table
end

----------------------------------------------------
--go_to_first_track_containing_selected_instrument()
----------------------------------------------------
function go_to_first_track_containing_selected_instrument()

  local pattern_iter = renoise.song().pattern_iterator
  local target_inst_number = (renoise.song().selected_instrument_index - 1) --lua couns from 1 
  local pattern_index = renoise.song().selected_pattern_index

  for track_index = 1, #renoise.song().tracks do
    --only sequencer tracks for efficiancy
    if renoise.song().tracks[track_index].type == renoise.Track.TRACK_TYPE_SEQUENCER then
      --loop through pattern_track
      for pos,line in pattern_iter:note_columns_in_pattern_track(pattern_index,track_index,true) do  --true for visible oonly
        -- if find a note matching the selected instrument then return           
        if target_inst_number == line.instrument_value then
          --change the track selection to where the note was found
          renoise.song().selected_track_index = track_index
          return
        end
      end
    end
  end
end

-------------------------------------------------------------------------------------
--Function to toggle views between the sampler modulation view and the pattern editor + Samaple editor added
-------------------------------------------------------------------------------------
function toggle_through_pattern_and_mod_view()
  --focus modulation view
  --if in pattern editor then view modulation
  if renoise.app().window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION then   
    renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
  --else default to pattern editor
  else --true then   
    renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  end
end

--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
local function status(message)
  renoise.app():show_status("Quick Adjust Tool: ("..message..")")
end

--------------------------------------------------------------------------------
--returns the first samples name or an empty string if no sample found/ selected
--------------------------------------------------------------------------------
function first_sample_name()
  local song = renoise.song()
  if song.selected_sample then
     return string.sub(song.selected_sample.name, 1, 30) --sample name truncated to 30chars
  end 
  ---else   
  return ""
end

---------------------------------------------------------
--returns a formatted selected instrument number and name
---------------------------------------------------------
function selected_instrument_name()
  local song = renoise.song()
  local index = tostring((song.selected_instrument_index - 1)):format("%02X")
  index = string.format("%02X",index)
  return string.sub(index.." : "..song.selected_instrument.name, 1, 30)
end  

-----------------------------------------
--add all notifiers and timers
-----------------------------------------
function add_notifiers()
  --add notifiers
  ---------------
  --add INSTRUMENT change notifier
  if not renoise.song().selected_instrument_index_observable:has_notifier(change_sample_selection_flag) then
    --ADD NOTIFIER
    renoise.song().selected_instrument_index_observable:add_notifier(change_sample_selection_flag)
  end
  --add TRACK change notifier
  if not renoise.song().selected_track_index_observable:has_notifier(change_sample_selection_flag) then
    --ADD NOTIFIER
    renoise.song().selected_track_index_observable:add_notifier(change_sample_selection_flag)
  end
  --add timer to fire once every 50ms
  if not renoise.tool():has_timer(set_gui_values) then
    renoise.tool():add_timer(set_gui_values,50)
  end
end

-----------------------------------------
--removes all added notifiers and timers
-----------------------------------------
function remove_notifiers()
   --remove selected instrument notifier
  if  renoise.song().selected_instrument_index_observable:has_notifier(set_gui_values) then
    renoise.song().selected_instrument_index_observable:remove_notifier(set_gui_values)
  end
    --add TRACK change notifier
  if renoise.song().selected_track_index_observable:has_notifier(change_sample_selection_flag) then
   --REMOVE
    renoise.song().selected_track_index_observable:remove_notifier(change_sample_selection_flag)
  end
  --remove timer
  if  renoise.tool():has_timer(set_gui_values) then
    renoise.tool():remove_timer(set_gui_values)
  end
end

----------------------------------------------------
--NOW IN SEPARATE FILE--- function set_gui_values() [[timer function]]
----------------------------------------------------


-------------------------
-----------------------------------------------------------------------------------------------------------------------------
--main
-----------------------------------------------------------------------------------------------------------------------------
function main()
  
  --make sure flag is set to false
   timer_updating = false
   sample_or_instrument_selection_has_changed = false
  
  --[[
  -----------------------------------------------
  --close dialog if already open, acts as toggle
  -----------------------------------------------
    --remove notifiers
   if my_dialog and (my_dialog.visible) then
     --remove all notifiers
     remove_notifiers()
     --close dialog
     my_dialog:close()
     --reset globals
     ahdsr = nil
     my_dialog = nil
    return
  end
--]]

  local song = renoise.song()
  local instrument = song.selected_instrument_index
  --reset viewbuilder
  vb = renoise.ViewBuilder()
  my_dialog = nil
  

  
  local slider_width_1 = 30
  -------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------
  --GUI
  -------------------------------------------------------------------------------------------  
  local dialog_content = 
    vb:vertical_aligner {
      margin = 8,
      -----------------------------------------
       --row 1 - Track Name     
       vb:row{ 
        -- style = "group",
         margin = 6,
         
              vb:button{
                 text = "C",
                 color = COLOR_GREY,
                 id = "capture",
                 notifier =  function()
                              --precaution
                               if (timer_updating == true) then
                                return
                               end
                               --go to the first pattern_track with note of this instrument in
                               --go_to_first_track_containing_selected_instrument()
                               
                               --go to the first pattern_track with note of this instrument in
                               renoise.song():capture_nearest_instrument_from_pattern()                   
                             end ,
               },
        --change to popup 
        vb:popup{
          id = "track name",
          items = get_renoise_track_names(),
         -- text = string.sub(song.selected_track.name, 1, 30), --track name truncated to 25chars
          width = 126,
          notifier = function(value)
                      --precaution
                       if (timer_updating == true) then
                        return
                       end
                       --change track_selection to match what the user chooses in the popup
                       renoise.song().selected_track_index = value
                     end
        }, --textfield
       },--row: Track Name 
      ----------------------------------------- 
      --row 2 - Instrument Name     
       vb:row{ 
        -- style = "group",
         margin = 6,
      
        vb:textfield{
        id = "inst name",
          text = selected_instrument_name(), --instrument name truncated to 25chars
         -- font = "bold",
         width = 145
        },
     --  },
      },
      ---------------------------------------
      --row 2 - Sample Name     
       vb:row{ 
        -- style = "group",
        margin = 6,
         
          --Sample Present
          vb:button{
          --width = 10,
         -- height = 12,
          text = "C",
          color = COLOR_GREY,
          id = "sample is_present colour",
          notifier = function()
                        --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             --go to the first pattern_track with note of this instrument in
                               go_to_first_track_containing_selected_instrument()
                             --go to the first pattern_track with note of this instrument in
                            -- renoise.song():capture_nearest_instrument_from_pattern()
                      
                     end
          
         },
        
          vb:textfield{
          id = "samp name",
            text = first_sample_name(),
           -- font = "bold",
           width = 126
         },
       },
      
      
      
      vb:vertical_aligner {
      
       -- visible = true,  --causes endless GUI enlargement??
       -- id = "controls visible",
        
        
         -------------------------
         --row  pitch controls      
         vb:row{ 
           style = "group",
           margin = 4,
            
            
           --attack slider
            vb:slider{
               --visible = false,
               width = slider_width_1,
               height = 150,
               min = 0,
               max = 1,
               value = 0,
               id = "attack",
               notifier = function(value)
                              --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                              --update ADSR
                             if ahdsr == nil then
                               return
                             end
                             --check flag
                             if (bypass_set_adsr_from_slider == true) then
                               return
                             end
                            
                             ahdsr.parameters[ATTACK].value = value
                             --update readout
                             vb.views["readout"].text = "(A): "..ahdsr.parameters[ATTACK].value_string
                             --reset check text
                             vb.views["check val"].text = "" 
                          end
             },
             vb:slider{
               width = slider_width_1,
               height = 150,
               min = 0,
               max = 1,
               value = 0,
               id = "hold",
               notifier = function(value)
                              --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             if ahdsr == nil then
                               return
                             end
                             --update ADSR
                             ahdsr.parameters[HOLD].value = value
                             --update readout
                             vb.views["readout"].text = "(H): "..ahdsr.parameters[HOLD].value_string 
                             --reset check text
                             vb.views["check val"].text = "" 
    
                          end
             },
             vb:slider{
               width = slider_width_1,
               height = 150,
               min = 0,
               max = 1,
               value = 0,
               id = "decay",
               notifier = function(value)
                              --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             if ahdsr == nil then
                               return
                             end
                             --update ADSR
                             ahdsr.parameters[DECAY].value = value
                             --update readout
                             vb.views["readout"].text = "(D): "..ahdsr.parameters[DECAY].value_string
                             --reset check text
                             vb.views["check val"].text = ""  
                          end
             },
             vb:slider{
               width = slider_width_1,
               height = 150,
               min = 0,
               max = 1,
               value = 0,
               id = "sustain",
               notifier = function(value)
                              --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             if ahdsr == nil then
                               return
                             end
                            --update ADSR
                            ahdsr.parameters[SUSTAIN].value = value
                            --update readout
                            vb.views["readout"].text = "(S): "..ahdsr.parameters[SUSTAIN].value_string
                            --reset check text
                            vb.views["check val"].text = ""  
    
                          end
             },
             vb:slider{
               width = slider_width_1,
               height = 150,
               min = 0,
               max = 1,
              value = 0,
               id = "release",
               notifier = function(value)
                              --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             
                             if ahdsr == nil then
                               return
                             end
                             --update ADSR
                             ahdsr.parameters[RELEASE].value = value
                             --update readout
                             vb.views["readout"].text = "(R): "..ahdsr.parameters[RELEASE].value_string
                             --reset check text
                             vb.views["check val"].text = ""     
                          end
             },
           }, --row  pitch controls 
           ---------------------------------------
           
           -------------------------
           --row 1 - text
           vb:row{
             vb:text{
               text = slider_name_string,-- Type",  
               font = "bold",
               id = "slider names",
             }
           },
           
           vb:row{
            vb:row{
              margin =2,
              vb:rotary{
               height = 22,
               id = "attack slope",
               notifier = function(value)
                            --stops notifier being fired by automatic GUI updates from timer
                            if (timer_updating == true) then
                              return
                            end
                            --return if no device object
                            if ahdsr == nil then
                              return
                            end
                            --update ADSR
                            ahdsr.parameters[ATTACK_SCALING].value = (value*2) - 1
                            --update readout
                            vb.views["readout"].text = "(AS): "..ahdsr.parameters[ATTACK_SCALING].value_string
                            --reset check text
                            vb.views["check val"].text = ""  
                          end
              },
             },
             
             vb:text{
              width = 24 --spacer text
             },
             
             vb:row{
              margin = 2,
              vb:rotary{
                height = 22,
                id = "decay slope",
                notifier = function(value)
                            --stops notifier being fired by automatic GUI updates from timer
                            if (timer_updating == true) then
                              return
                            end
                            --return if no device object
                            if ahdsr == nil then
                              return
                            end
                            --update ADSR
                            ahdsr.parameters[DECAY_SCALING].value = (value*2) - 1
                            --update readout
                            vb.views["readout"].text = "(DS): "..ahdsr.parameters[DECAY_SCALING].value_string
                            --reset check text
                            vb.views["check val"].text = ""  
                          end
              },
             },
             vb:text{
              width  = 22 --spacer text
             },
             vb:row{
              margin = 2,
              vb:rotary{
               height = 22,
               id = "release slope",
               notifier = function(value)
                            --stops notifier being fired by automatic GUI updates from timer
                            if (timer_updating == true) then
                              return
                            end
                            --return if no device object
                            if ahdsr == nil then
                              return
                            end
                            --update ADSR
                            ahdsr.parameters[RELEASE_SCALING].value = (value*2) - 1
                            --update readout
                            vb.views["readout"].text = "(RS): "..ahdsr.parameters[RELEASE_SCALING].value_string
                            --reset check text
                            vb.views["check val"].text = ""  
                          end
              },
             },
            },
           
           
           --row 2: readout box   
           vb:row{ 
               margin = 8,
                
                vb:textfield{ 
                 text = "---",
                 id = "readout",
                 notifier = function(value)
                             
                             --stops notifier being fired by automatic GUI updates from timer
                             if (timer_updating == true) then
                              return
                             end
                             
                             --function prints the slider value of choice when a user inputs the first letter of the slider name
                              if (ahdsr == nil) then
                                status("No Envelope Present To Show Readout For")  
                                return  
                              end
 
                              
                              if (value == "a") or (value == "A") then
                                vb.views["check val"].text = "A: "..ahdsr.parameters[ATTACK].value_string
                              elseif (value == "h") or (value == "H") then
                                vb.views["check val"].text = "H: "..ahdsr.parameters[HOLD].value_string
                              elseif (value == "d") or (value == "D") then
                                vb.views["check val"].text = "D: "..ahdsr.parameters[DECAY].value_string
                              elseif (value == "s") or (value == "S") then
                                vb.views["check val"].text = "S: "..ahdsr.parameters[SUSTAIN].value_string
                              elseif (value == "r") or (value == "R") then
                                vb.views["check val"].text = "R: "..ahdsr.parameters[RELEASE].value_string 
                              else
                                 --just show nothing
                              end                           
                            end
            
                },--text 

              
              --value readout
              vb:text{
                text = "",
                font = "bold",
                id = "check val"
              }
                
             },
           vb:text{ 
             text = "Enable Envelope:         Offset:", 
             id = "in sampler",
            
            },--text
           
         
           vb:horizontal_aligner{
             -- = "distribute",
             margin = 4,
            
           --row containing enable checkbox and Go To Button
           -------------------------------------------------
           vb:row{ 
             margin = 4,
             spacing = 15, --This sets the width for the bottom group
            -- mode = "justify",
             
             style = "group",
             
             vb:row{
             --------------
                --checkbox
                vb:checkbox{
                value = false,
                --width =30,
                id = "enabled",
              --bind = ahdsr.enabled_observable, --doesn`t work? 
                notifier = function(value)
                              
                             --stops notifier being fired by automatic GUI updates from timer
                              if (timer_updating == true) then
                                return
                              end
                
                             --1 Look For Already present ahdsr
                              for i = 1, #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices do
                                --if one is found then SET TO THAT AHDSR as ahdsr object; i.e. the one we will control from the tool GUI
                                if song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i].name == "Volume AHDSR" then
                                  
                                  break
                                end
                              end
                                            
                             --if no envelope is present and being clicked on then add one
                             
                             local ahdsr_found = false
                             
                             --check for AHDSR device present?
                            for i = 1, #song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices do
                              --if one is found then SET TO THAT AHDSR as ahdsr object; i.e. the one we will control from the tool GUI
                              if song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i].name == "Volume AHDSR" then
                                ahdsr = song.instruments[song.selected_instrument_index].sample_modulation_sets[1].devices[i]
                                ahdsr_found = true
                                break
                              end
                            end
                             --If Checkbox being switched on:
                             -------------------------------------------------------------
                             if value == true then
                                 
                                 --1)add new device if not present
                                 if ahdsr_found == false then
                                  --ADD NEW ahdsr
                                  ahdsr = song.instruments[song.selected_instrument_index].sample_modulation_sets[1]:insert_device_at("Modulation/AHDSR",1,1)--index
                                  --Show on GUI readout that an envelope has been added
                                   vb.views["readout"].text = "New AHDSR Added"
                                  --set initial values
                                  --attack to 0
                                  
                                 -- parameter[1] is the bypassed button
                                  ahdsr.parameters[ATTACK].value = 0
                                  --Hold to 0
                                  ahdsr.parameters[HOLD].value = 0
                                  --Decay to 1
                                  ahdsr.parameters[DECAY].value = 0.5
                                  --Sustain to 0
                                  ahdsr.parameters[SUSTAIN].value = 0
                                  --Release to 0
                                  ahdsr.parameters[RELEASE].value = 0
                                  --switch off device
                                 -- ahdsr.enabled = false
                                end
                                                           
                               --refresh whole GUI
                               --2) Set GUI from ahdsr
                               -- vb.views["sample present colour 2"].color = COLOR_YELLOW
                                --activate the controls ahdsr
                                vb.views["attack"].active = true
                                vb.views["hold"].active = true
                                vb.views["decay"].active = true
                                vb.views["sustain"].active = true
                                vb.views["release"].active = true
                                vb.views["enabled"].active = true
                               -- vb.views["in sampler"].text = "Enable Envelope:"  
                              
                                --ahdsr
                                vb.views["attack"].value = ahdsr.parameters[ATTACK].value
                                vb.views["hold"].value = ahdsr.parameters[HOLD].value
                                vb.views["decay"].value = ahdsr.parameters[DECAY].value
                                vb.views["sustain"].value = ahdsr.parameters[SUSTAIN].value
                                vb.views["release"].value = ahdsr.parameters[RELEASE].value
                               -- vb.views["enabled"].value = ahdsr.enabled
                                
                                --update track and instrument name on GUI
                                vb.views["track name"].value = song.selected_track_index  
                                vb.views["inst name"].text = selected_instrument_name() 
                                vb.views["samp name"].text = first_sample_name()  
                                
                               
                                --enable slider names --"   Atk   Hold   Dcay   Sus    Rel"
                                vb.views["slider names"].text = slider_name_string
                                
                                --enable device
                                ahdsr.enabled = value
                             else --case false then  
                               --disable device (value will be false)
                               if ahdsr ~= nil then
                                 ahdsr.enabled = value
                                 
                                -- vb.views["sample present colour 2"].color = COLOR_BLUE
                               end
                               --disable the controls ahdsr
                                vb.views["attack"].active = false
                                vb.views["hold"].active = false
                                vb.views["decay"].active = false
                                vb.views["sustain"].active = false
                                vb.views["release"].active = false                                                                                                              
                             end
                           end
                },--checkbox end
              
               
                vb:button{
                 text = "View", 
                 notifier = function()
                              --focus modulation view
                              toggle_through_pattern_and_mod_view()
                              set_gui_values()
                            end
               },  --button end  ,
                ------------------
          
              },
             
             
             --two button row
              vb:row{
               vb:button{
                 width = 18,
                -- text = "P",  
                 color = COLOR_GREY,
                 id = "phrase present LED",
                 notifier = function()
                              local song = renoise.song()
                              local inst = song.selected_instrument_index
                              --toggle pattern editor
                              --if viewing mixer or pattern ed, go to sample editor and view phrase
                              if (renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR) or
                                 (renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_MIXER) then
                                 renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR

                                if (renoise.song().instruments[song.selected_instrument_index].phrase_editor_visible ~= true) then
                                  renoise.song().instruments[song.selected_instrument_index].phrase_editor_visible = true
                                end
                                --check phrase at least one is present in order to focus it
                                if #song.instruments[inst].phrases > 0 then 
                                  renoise.song().selected_phrase_index = 1
                                end
                              --else somewhere in the instrument editor will be visible
                              elseif renoise.song().instruments[song.selected_instrument_index].phrase_editor_visible == false then
                                renoise.song().instruments[song.selected_instrument_index].phrase_editor_visible = true
                              --else you will be viewing the phrase editor so go to the pattern editor
                              else
                                renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
                              end
                             --- renoise.song().instruments[].phrase_playback_enabled
                              
                            end--]]  ----
               },
               vb:valuebox{
                id = "sample offset",
                value = 1,
                min = 0,
                max = 255,
                notifier = function(value)
                  
                  --stops notifier being fired by automatic GUI updates from timer
                  if (timer_updating == true) then
                    return
                  end
                      
                  --vars
                  local song = renoise.song()
                  local inst = song.selected_instrument_index
                  local samp = song.selected_sample_index
                  
                  --return if no sample selected/ present
                  if song.selected_sample_index == nil then
                    return
                  end
                  
                  --check for presence phrase
                  if #song.instruments[inst].phrases > 0 then
                    --add in the phrase and 0S00 command if not there
                    --update 0S sample offset command
                    -----------------
                    song.instruments[inst].phrases[1]:line(1).effect_columns[1].number_string = "0S"
                    song.instruments[inst].phrases[1]:line(1).effect_columns[1].amount_value = (value)
                  else
                    --2)Insert a new phrase behind the given phrase index (1 for the first one).
                    song.instruments[inst]:insert_phrase_at(1)         
                    --add S01 command
                    -----------------
                    song.instruments[inst].phrases[1]:line(1).effect_columns[1].number_string = "0S"
                    --add sample offset amount
                    song.instruments[inst].phrases[1]:line(1).effect_columns[1].amount_string = "00"
                    --turn off loop
                    song.instruments[inst].phrases[1].looping = false
                    --select phrase (offset won`t work/ initialise otherwise)  
                    song.selected_phrase_index = 1
                    status("New Phrase Added")
                    return
                  end
                 end,
                },                      
              } ,--2 button row end
               -------------------
            }, --vb:row 
          },--checkbox and button horizontal_aligner
          
          vb:row{
            margin = 2,
            vb:text{  --spacer
              width = 70,
            },
            vb:checkbox{ --enable/disable envelope
              id = "graph env check",
              
              notifier = function() 
                           add_or_enable_envelope_device()
                         end,
            
            },
            
            vb:button{
             id = "graph env button",
             color = COLOR_GREY,
             text = "Graph Env.",
             notifier = function()
               add_or_open_envelope_device()
              end,
             
            }
          
          },
         
       } --vertical aligner
     } --vertical aligner
     
        
  --------------  
  
  --run set_gui_values function (the proper values were not set in building the GUI)
  set_gui_values() 

  
  --------------
  --key Handler
  --------------
  local function my_keyhandler_func(dialog,key)
    -- rprint(key)
     --toggle lock focus hack, allows pattern ed to get key input
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
  
     --if escape pressed then close the dialog else return key to renoise
     if not (key.modifiers == "" and key.name == "esc") then
        return key
     else
       dialog:close()
       ahdsr = nil
     end
  end 
    
  --Initialise Script dialog
  --------------------------
  my_dialog = renoise.app():show_custom_dialog("Quick Vol AHDSR", dialog_content,my_keyhandler_func)   
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    my_dialog = nil    
    --reset envelope dev object 
    ahdsr = nil
    if d and d.visible then
      d:close()
      remove_notifiers()
    end
  end
  
  -----------
  --add notifiers
  -----------
  --add INSTRUMENT change notifier
  if not renoise.song().selected_instrument_index_observable:has_notifier(change_sample_selection_flag) then
    --ADD NOTIFIER
    renoise.song().selected_instrument_index_observable:add_notifier(change_sample_selection_flag)
  end
  
  --add TRACK change notifier
  if not renoise.song().selected_track_index_observable:has_notifier(change_sample_selection_flag) then
    --ADD NOTIFIER
    renoise.song().selected_track_index_observable:add_notifier(change_sample_selection_flag)
  end
  
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  
  --add timer to fire once every 50ms
  if not renoise.tool():has_timer(set_gui_values) then
    renoise.tool():add_timer(set_gui_values,80)
  end

end --end of main
---------------------



