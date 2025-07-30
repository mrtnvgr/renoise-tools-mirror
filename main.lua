 --[[------------------------------------------------------------------------------------
  
  GRANDE UTOPIA ANALYZER v1.0  
  
  Copyright 2014 Matthias Ehrmann, 
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License. 
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 

  Unless required by applicable law or agreed to in writing, software distributed 
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
  CONDITIONS OF ANY KIND, either express or implied. See the License for the specific 
  language governing permissions and limitations under the License.
  
--------------------------------------------------------------------------------------]]--

------------------------- VARIABLES / PREFS

bass_l = nil
bass_r = nil
mids_a_l = nil
mids_a_r = nil
tweeter_l = nil
tweeter_r = nil
mids_b_l = nil
mids_b_r = nil
sub_l = nil
sub_r = nil
backgr = nil
spacer_l = nil
spacer_r = nil
logo = nil
      
view = nil
dialog = nil

last_ani_nr = {}
last_ani_nr["bass_l"] = 1
last_ani_nr["bass_r"] = 1
last_ani_nr["mids_a_l"] = 1
last_ani_nr["mids_a_r"] = 1
last_ani_nr["tweeter_l"] = 1
last_ani_nr["tweeter_r"] = 1
last_ani_nr["mids_b_l"] = 1
last_ani_nr["mids_b_r"] = 1
last_ani_nr["sub_l"] = 1
last_ani_nr["sub_r"] = 1
last_ani_nr["logo"] = 1

detector = nil

prefs = renoise.Document.create("GrandeAnalyzerPreferences") {
  enabled = true
}
prefs:load_from("config.xml")
--prefs:save_as("config.xml")

------------------------------ VIEW AND DIALOG

-- indicates if dialog is visible/valid
function dialog_visible()  
  return dialog and dialog.visible
end

-- dialog handler
function close_dialog()
  if dialog_visible() then
    dialog:close()
  end
  dialog = nil
  view = nil
  bass_l = nil
  bass_r = nil
  mids_a_l = nil
  mids_b_r = nil
  tweeter_l = nil
  tweeter_r = nil
  mids_b_l = nil
  mids_b_r = nil
  sub_l = nil
  sub_r = nil
  backgr = nil
  spacer_l = nil
  spacer_r = nil
  logo = nil
end
  
function open_dialog()
  local mode = "plain"
  local vb = renoise.ViewBuilder()  
  bass_l =
    vb:bitmap {
      mode = mode,
      bitmap = "res/bass/bass01.png"
    }  
  bass_r = 
    vb:bitmap {
      mode = mode,
      bitmap = "res/bass/bass01.png"
    }  
  mids_a_l =
    vb:bitmap {
      mode = mode,
      bitmap = "res/mids_a/mids_a01.png"
    }  
  mids_a_r =
    vb:bitmap {
      mode = mode,
      bitmap = "res/mids_a/mids_a01.png"
    }  
  tweeter_l =
    vb:bitmap {
      mode = mode,
      bitmap = "res/tweeter/tweeter01.png"
    }  
  tweeter_r =
    vb:bitmap {
      mode = mode,
      bitmap = "res/tweeter/tweeter01.png"
    }  
  mids_b_l =
    vb:bitmap {
      mode = mode,
      bitmap = "res/mids_b/mids_b01.png"
    }  
  mids_b_r =
    vb:bitmap {
      mode = mode,
      bitmap = "res/mids_b/mids_b01.png"
    }  
  sub_l =
    vb:bitmap {    
      mode = mode,
      bitmap = "res/sub/sub01.png"
    }
  sub_r =
    vb:bitmap {    
      mode = mode,
      bitmap = "res/sub/sub01.png"
    }
  backgr =
    vb:bitmap {
      mode = mode,
      bitmap = "res/raw/dirk.png",
      notifier = function() 
        if (backgr.bitmap == "res/raw/dirk.png") then 
          backgr.bitmap = "res/raw/yoda.png" 
        else 
          backgr.bitmap = "res/raw/dirk.png" 
        end 
      end       
    }
  spacer_l = 
    vb:bitmap {
      mode = mode,
      width = 20,
      bitmap = "res/raw/spacer_smaller.png" 
    }  
  spacer_r = 
    vb:bitmap {
      mode = mode,
      bitmap = "res/raw/spacer.png" 
    }
  logo = 
    vb:bitmap {
      mode = mode,
      bitmap = "res/raw/renoise_logo01.png" 
    }  

  view = vb:column {
    margin = 0,
    spacing = 0,  
    vb:row {
       margin = 0,
       spacing = 0,    
       vb:column {   
          margin = 0,
          spacing = 0,        
          vb:row {
            margin = 0,
            spacing = 0,        
            logo,
            spacer_l, 
          },
          bass_l,
          mids_a_l,
          tweeter_l,
          mids_b_l,
          sub_l          
        },
       vb:column {   
          margin = 0,
          spacing = 0,
          backgr
       },
       vb:column {   
          margin = 0,
          spacing = 0,
          spacer_r,
          bass_r,
          mids_a_r,
          tweeter_r,
          mids_b_r,
          sub_r          
        }    
     }   
  }
  if (view) then      
      dialog = 
        renoise.app():show_custom_dialog("Grande Utopia Analyzer", view)  
  end  
end 


----------------- SIGNAL HANDLERS

function on_subL()
  if (detector) then  
    local ani_nr = 
      math.floor((detector.parameters[3].value/127) * 23 + 0.5) + 1  
    switch_picture(sub_l,"sub","l",ani_nr);    
  end
end

function on_subR()
  if (detector) then  
    local ani_nr = 
      math.floor((detector.parameters[4].value/127) * 23 + 0.5) + 1  
    switch_picture(sub_r,"sub","r",ani_nr);  
  end
end

function on_bassL()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[5].value/127) * 23 + 0.5) + 1  
    switch_picture(bass_l,"bass","l",ani_nr);      
  end
end

function on_bassR()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[6].value/127) * 23 + 0.5) + 1    
    switch_picture(bass_r,"bass","r",ani_nr);  
  end
end

function on_midsL()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[7].value/127) * 23 + 0.5) + 1  
    switch_picture(mids_a_l,"mids_a","l",ani_nr);    
    switch_picture(mids_b_l,"mids_b","l",ani_nr);        
  end
end

function on_midsR()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[8].value/127) * 23 + 0.5) + 1      
    switch_picture(mids_a_r,"mids_a","r",ani_nr);    
    switch_picture(mids_b_r,"mids_b","r",ani_nr);    
  end
end

function on_tweeterL()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[9].value/127) * 23 + 0.5) + 1  
    switch_picture(tweeter_l,"tweeter","l",ani_nr);    
  end
end 

function on_tweeterR()
  if (detector) then
    local ani_nr = 
      math.floor((detector.parameters[10].value/127) * 23 + 0.5) + 1      
    switch_picture(tweeter_r,"tweeter","r",ani_nr);      
  end
end 

---------------- HELPER FUNCTIONS

-- deletes first occurence of device by name
function delete_by_name(trk_index,name)
  local song = renoise.song()
  for i = 2,#song.tracks[trk_index].devices do        
      local devname = song.tracks[trk_index].devices[i].display_name
      if (devname == name) then 
        song.tracks[trk_index]:delete_device_at(i)   
        return
      end
   end
end 

function insert_device(trk_index,device_index,device_type,display_name,preset_path) 
  local song = renoise.song()
  local dev = song.tracks[trk_index]:insert_device_at(device_type, device_index)
  dev.display_name = display_name 
  io.input(preset_path)   
  dev.active_preset_data = io.read("*all")  
  dev.is_maximized = false
  return dev
end

function insert_detector_chain()  

  local song = renoise.song()

  -- search for master track
  local mst_index = 0
  for trk = #song.tracks, 1, -1 do  
    if song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER then
      mst_index = trk     
      break
    end
  end
                
  local last_index = #song.tracks[mst_index].devices
  local GrandeDetector = -1   
 
  local dev = nil
 
  -- Insert GrandeDetector
  dev = insert_device(mst_index, last_index+1,"Audio/Effects/Native/*Instr. MIDI Control",
    "GrandeDetector","res/presets/GrandeDetector.xrdp")
  dev.is_active = false  -- Important: MUST be inactive, otherwise VSTi's might be controlled
  GrandeDetector = last_index + 1
  last_index = GrandeDetector  
    
  -- Insert TweeterFollower  
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "TweeterFollowerR","res/presets/TweeterFollowerR.xrdp")
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 10
  GrandeDetector = GrandeDetector+1 
  
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "TweeterFollowerL","res/presets/TweeterFollowerL.xrdp")
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 9      
  GrandeDetector = GrandeDetector+1        
    
  -- Insert MidsFollower
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
  "MidsFollowerR","res/presets/MidsFollowerR.xrdp")
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 8
  GrandeDetector = GrandeDetector+1          
  
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "MidsFollowerL","res/presets/MidsFollowerL.xrdp")
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 7     
  GrandeDetector = GrandeDetector+1        
 
  -- Insert BassFollower
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "BassFollowerR","res/presets/BassFollowerR.xrdp") 
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 6   
  GrandeDetector = GrandeDetector+1  
  
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "BassFollowerL","res/presets/BassFollowerL.xrdp") 
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 5   
  GrandeDetector = GrandeDetector+1    
 
  -- Insert SubFollower
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "SubFollowerR","res/presets/SubFollowerR.xrdp")   
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 4  
  GrandeDetector = GrandeDetector+1
  
  dev = insert_device(mst_index, last_index,"Audio/Effects/Native/*Signal Follower",
    "SubFollowerL","res/presets/SubFollowerL.xrdp")   
  dev.parameters[2].value = GrandeDetector
  dev.parameters[3].value = 3       
end

-- check for existing devices and remove them  
function remove_detector_chain()
  
  local song = renoise.song()
  
   -- search for master track
  local mst_index = 0
  for trk = #song.tracks, 1, -1 do  
    if song.tracks[trk].type == renoise.Track.TRACK_TYPE_MASTER then
      mst_index = trk     
      break
    end
  end  
  -- HINT: this is quick and dirty, because
  -- multiple devices with the same name are
  -- not deleted. Moreover, there exists probably
  -- a smarted method of doing this  
  delete_by_name(mst_index,"SubFollowerL")
  delete_by_name(mst_index,"SubFollowerR")
  delete_by_name(mst_index,"BassFollowerL")
  delete_by_name(mst_index,"BassFollowerR")
  delete_by_name(mst_index,"MidsFollowerL")
  delete_by_name(mst_index,"MidsFollowerR")
  delete_by_name(mst_index,"TweeterFollowerL")
  delete_by_name(mst_index,"TweeterFollowerR")
  delete_by_name(mst_index,"GrandeDetector")
end

-- check for detector device by searching for name and add listeners
function connect()
  local song = renoise.song()  
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do       
      if song.tracks[track].devices[devs].display_name == "GrandeDetector" then
        detector = song.tracks[track].devices[devs]              
        detector.parameters[3].value_observable:add_notifier(on_subL)
        detector.parameters[4].value_observable:add_notifier(on_subR)
        detector.parameters[5].value_observable:add_notifier(on_bassL)
        detector.parameters[6].value_observable:add_notifier(on_bassR)
        detector.parameters[7].value_observable:add_notifier(on_midsL)
        detector.parameters[8].value_observable:add_notifier(on_midsR)
        detector.parameters[9].value_observable:add_notifier(on_tweeterL)                   
        detector.parameters[10].value_observable:add_notifier(on_tweeterR)                   
        return
      end
    end 
  end
end

-- check for detector device by searching for name and remove listeners
function disconnect()
  local song = renoise.song()  
  for track = 1, #song.tracks  do
    for devs = 2, #song.tracks[track].devices do       
      if song.tracks[track].devices[devs].display_name == "GrandeDetector" then
        detector = song.tracks[track].devices[devs]              
        detector.parameters[3].value_observable:remove_notifier(on_subL)
        detector.parameters[4].value_observable:remove_notifier(on_subR)
        detector.parameters[5].value_observable:remove_notifier(on_bassL)
        detector.parameters[6].value_observable:remove_notifier(on_bassR)
        detector.parameters[7].value_observable:remove_notifier(on_midsL)
        detector.parameters[8].value_observable:remove_notifier(on_midsR)
        detector.parameters[9].value_observable:remove_notifier(on_tweeterL)                   
        detector.parameters[10].value_observable:remove_notifier(on_tweeterR)
        return
      end
    end 
  end
end

-- animation function
function switch_picture(widget,element,channel,ani_nr)  
  if (ani_nr ~=  last_ani_nr[element..channel]) then
     local path = "res/"..element.."/"..element
     if (ani_nr < 10) then
       path = path.."0"
     end
     path = path..ani_nr..".png"
     widget.bitmap = path    
  end 
end

------------------------------ APPLICATION HANDLERS

function on_song_created()
  if (prefs.enabled.value) then
    remove_detector_chain() -- to be sure
    insert_detector_chain()
    connect()
    close_dialog() -- to be sure
    open_dialog()
  end
end

function on_song_pre_release()
  close_dialog()
  disconnect()
  remove_detector_chain()
end

function on_idle()
  
  -- experimental auto animation
  local ms = os.clock()*1000
  local zs = math.floor(ms / 50 + 0.5)  
  local ani_nr = zs % 72 + 1  
  if (ani_nr ~=  last_ani_nr["logo"]) then
     local path = "res/raw/renoise_logo"
     if (ani_nr < 10) then
       path = path.."0"
     end
     path = path..ani_nr..".png"
     if (logo) then
        logo.bitmap = path       
     end     
  end     
end   

function enable_analyzer()
  prefs.enabled.value = true
  if dialog_visible() then
    return
  else    
    on_song_created()    
  end  
  prefs:save_as("config.xml") 
end

function disable_analyzer()
  on_song_pre_release()
  prefs.enabled.value = false
  prefs:save_as("config.xml") 
end  

-- menu 
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:GrandeAnalyzer:Enable",  
  active = function () return not dialog_visible() end,
  invoke = function() enable_analyzer() end             
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:GrandeAnalyzer:Disable",  
  --active = function() return dialog_visible() end 
  invoke = function() disable_analyzer() end             
}

-- add new song observer
if (not renoise.tool().app_new_document_observable:has_notifier(on_song_created)) then
  renoise.tool().app_new_document_observable:add_notifier(on_song_created)
end

-- add song pre-release observer  
if (not renoise.tool().app_release_document_observable:has_notifier(on_song_pre_release)) then
  renoise.tool().app_release_document_observable:add_notifier(on_song_pre_release)
end

-- add idle oberserver
if (not renoise.tool().app_idle_observable:has_notifier(on_idle)) then
  renoise.tool().app_idle_observable:add_notifier(on_idle)
end
on_idle() -- init


--[[ debug ]]--------------------------------------------------------------]]--

_AUTO_RELOAD_DEBUG = true
