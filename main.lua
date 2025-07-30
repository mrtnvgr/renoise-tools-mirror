-------------------------------------------------
--imports relevant files
-------------------------------------------------
require "keyfuncs" 
require "cas_additions"

--"keyfuncs" 1
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Cycle Send Track Selection",  
  invoke = function() cycle_send_tracks()
  end  
}
--"keyfuncs" 2
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Add New Send Track",
  invoke = function()add_a_new_send_track()
  end  
}
--"keyfuncs" 3
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Add New Send Device (Keep Source)",
  invoke = function()add_a_new_send_device()
  end  
}
--"keyfuncs" 4
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Monitor Send Tracks"  ,  
  invoke = function() mute_all_tracks_with_silent_gainer()
  end  
}
--"keyfuncs" 5
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Go To Selected Send Device`s Target",  
  invoke = function() go_to_send()
  end  
}
--"keyfuncs" 6
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Toggle Sends Active State",  
  invoke = function() toggle_sends_active_state()
  end  
}
--"keyfuncs" 7
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Cycle Selected Send Device`s Target ->",  
  invoke = function() cycle_send_device_target()
  end  
}
--"keyfuncs" 8
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Cycle Selected Send Device`s Target <-",  
  invoke = function() cycle_send_device_target_backwards()
  end  
}
--"keyfuncs" 9
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Increment FX Track Color Blend",
  invoke = function() blend_group_color() end
}

--"keyfuncs" 10
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Throw To Send",
  invoke = function() throw_to_send() end
}



--------------------------------------------------------
--added by cas -- imported from cas_additions.lua
-------------------------------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Route to New Send Track",
  invoke = function()route_to_new_send_track()
  end  
}
--added by cas in "cas_additions"
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Go to Source ...",
  invoke = function()show_src_gui()
  end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Route to Send Track...",
  invoke = function()show_dest_gui()
  end
}
--------------------------------------------------------
--------------
--in main.lua --(this file)
--------------
--requires global variables visible to the notifiers to reset
renoise.tool():add_keybinding {
  name = "Global:Tools:`GTS` Toggle Last Selected Track",  
  invoke = function() toggle_last_selected_track()
  end  
}
---------------------------------
--globals variables
---------------------------------
--menu substrings
local static_entries = {"Go To Send","Go To Target"}
local menu_locations = {"Mixer:","DSP Device:"}

--table that will stores the all menu entries at any one time so they can be deleted
--when add_menus() is called
local current_menu_strings = {}

----------------------------------------------------------
--Pair of functions to toggle between the current and last
--selected track
----------------------------------------------------------
--globals
local prev_track_index_holder 
local prev_track_index

--triggered by shortcut to change to the last selected track
function toggle_last_selected_track()
  
  local song = renoise.song()
    if song.tracks[prev_track_index] == nil then
      renoise.app():show_status("Toggle Last Selected Track Shortcut: (Previous Track does not exist anymore, please choose a new one)")
    return
    end
  song.selected_track_index = prev_track_index
end

--function attached to notifier to keep track of previous
--selected track index
function update_last_selected_track_index()
 
  local song = renoise.song()
  prev_track_index = prev_track_index_holder 
  prev_track_index_holder = song.selected_track_index
end
--------------------------------------------------------------
--------------------------------------------------------------

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

-----------------------------------------------------------
--table_remove()
--searches through a table to remove the specified string value 
--Lua`s native table.remove() requires the precise location
-----------------------------------------------------------
function table_remove(my_table,string) --called in add menus() 
  
  if (#my_table == 0) or (my_table == nil) then
    return my_table
  end
  
  for i = 1,#my_table do
    if my_table[i] == string then
      table.remove(my_table, i) --this method shifts rest of table so shortens table
    end
  end
  return my_table
end
 
-----------------------------
--select send device()
--selects send device on track being navigated to
-----------------------------
function select_send_device(track_index,send_number) --called in add menus() menu notifiers 

  local song = renoise.song()
   
  for devs = 2,#song.tracks[track_index].devices do
      if song.tracks[track_index].devices[devs].name == "#Send" then
          --check sending to right track
          if song.tracks[track_index].devices[devs].parameters[3].value + 1 == send_number then
            song.selected_device_index  = devs
          break
        end
      end
   end   
end

--------------------------------------------
--get_send_pos_and_routing()
--gets values for all tracks with a send in them and returns
--a table[1..n] where n is the total number of send devices/ nil if no devices in song 
--the fields are:

--source_track_index  --track send is on
--source_track_name   --name of that track
--send_track_number   --send track number the device is routed to (1..x)
--send_track_index    --index of that track its index relative to all other tracks
--send_track_name     --its name string
--------------------------------------------
function get_send_pos_and_routing()
 
  local song = renoise.song()
  local send_table = {source_track_index = {}, source_track_name = {},send_track_number = {},send_track_index={},send_track_name ={}} --key "track", value {}
  local flag = nil
  local master_track_index = (song.sequencer_track_count + 1)
  
  for track = 1,#song.tracks do
    for devs = 2,#song:track(track).devices do
      if song:track(track):device(devs).name == "#Send" then
        local target_send_number = song.tracks[track].devices[devs].parameters[3].value + 1
        local target_track_index = master_track_index + target_send_number
        --add the track number which contains the send
        table.insert(send_table.source_track_index, track)
        --add the number of the send track sent to        
        table.insert(send_table.send_track_number, target_send_number)
        --add index of send track pointed to
        table.insert(send_table.send_track_index,target_track_index)
        --add string for target_track
        table.insert(send_table.send_track_name, song.tracks[target_track_index].name)
        --add source_track_name
        table.insert(send_table.source_track_name, song.tracks[track].name)
        flag = 1
      end
    end
  end
  --return table or nil if table empty
  if flag == 1 then 
    return send_table
  else
    return nil
  end
end

--------------------------------------------
--get_multi_send_pos_and_routing()
--gets values for all tracks with a multiband send in them and returns
--a table[1..n] where n is the total number of multiband send devices/ nil if no devices in song 
--the fields are:

--source_track_index       --track multiband send is on
--source_track_name        --name of that track

--target_tracks[1-n].send_track_number[1-3]   --[1-n] for devices in song  -- send_track_number each band 1-3 is routed to 
--target_tracks[1-n].send_track_index[1-3]    --[1-n] for devices in song  -- index of that track (each band 1-3)
--target_tracks[1-n].send_track_name[1-3]     --[1-n] for devices in song  -- its name string (each band 1-3)
--------------------------------------------
function get_multi_send_pos_and_routing()
 
  local song = renoise.song()
  local send_table = {source_track_index = {}, source_track_name = {}}
  local target_tracks = {}
  
   --key "track", value {}
  local flag = nil
  local master_track_index = (song.sequencer_track_count + 1)
  local ms_counter = 0 --multisend device counter
  
  for track = 1,#song.tracks do
    for devs = 2,#song:track(track).devices do
      if song:track(track):device(devs).name == "#Multiband Send" then
        --increment counter
        ms_counter = ms_counter + 1
       
        --add the track number which contains the send
        table.insert(send_table.source_track_index, track)
         --add source_track_name
        table.insert(send_table.source_track_name, song.tracks[track].name)
        
        --add a sub-table to target_tracks
        target_tracks[ms_counter] = {}
        --add three further sub tables for target( eceiver send tracks) properties
        target_tracks[ms_counter] = {target_send_number = {},target_track_index = {},target_track_name = {}}
        
        --loop to add the properties
        for prop = 1,3 do
          target_tracks[ms_counter].target_send_number[prop] = song.tracks[track].devices[devs].parameters[prop*2].value + 1 --bands 1 at parameter pos 2,4,6 -- by chance   
          target_tracks[ms_counter].target_track_index[prop] = master_track_index + target_tracks[ms_counter].target_send_number[prop]
          target_tracks[ms_counter].target_track_name[prop] = song.tracks[target_tracks[ms_counter].target_track_index[prop]].name
        end
        flag = 1
      end
    end
  end
  send_table.target_tracks = target_tracks
  --return table or nil if table empty
  if flag == 1 then 
    return send_table
  else
    return nil
  end
end

--end of helper functions
----------------------------------------------------------------------------------
----------------------------------

function add_new_go_to_send_menus()

 local song = renoise.song()
  --add menu entries
  if song.selected_device and (song.selected_device.name == "#Send") then
    
    for j = 1,#menu_locations do --both DSP lane and mixer
      if not renoise.tool():has_menu_entry(menu_locations[j].."Go To Send") then
               
         renoise.tool():add_menu_entry {
                         name = menu_locations[j].."Go To Send",
                         invoke = function()  go_to_send() end,
                        } 
      --RECORD INSERTION 
       table.insert(current_menu_strings , menu_locations[j].."Go To Send")
      end
    end
  end 
end

----------------------------------------------
--adds multiband send menu entries for e.g.  
--Go To Send (Low)
--Go To Send (Med)
--Go To Send (High)
-----------------------------------------------
function add_new_go_to_send_menus_from_multi()

 local song = renoise.song()
 
  --add menu entries
  if song.selected_device and (song.selected_device.name == "#Multiband Send") then
    for j = 1,#menu_locations do --both DSP lane and mixer
      --for number of potential targets
      for i = 1, 3 do 
        local send_number = song.selected_device.parameters[i*2].value + 1
        local total_non_sends = (song.sequencer_track_count + 1) --+1 to include master track
        local send_index = send_number + total_non_sends
        -- local send_name = song.tracks[send_index].name
        local tar_name = { "Low", "Mid", "High"} 
      
        if not renoise.tool():has_menu_entry(menu_locations[j].."Go To Send ("..tar_name[i]..")") then
           renoise.tool():add_menu_entry {
                           name = menu_locations[j].."Go To Send ("..tar_name[i]..")",
                           invoke = function()  song.selected_track_index = (song.selected_device.parameters[i*2].value + 1) + total_non_sends end,
                          } 
         --RECORD INSERTION 
         table.insert(current_menu_strings , menu_locations[j].."Go To Send ("..tar_name[i]..")")  
        end
      end
    end
  end 
end

---------------------------------------------------------------------------------------------------
--taken out of above
--menu_locations[j].."Go To Send `"..send_name.."`"

--SOMETHING LIKE THIS NEEDED IF SEND NAMES ARE ADDED TO UPDATE MENU ITEMS WHEN TARGETS ARE CHANGED 
--renoise.song().tracks[].devices[].parameters[].value_observable

 --remove previous notifier
 
-- for perams = 1,3 do
 --  if not renoise.song().tracks[song_selected_track_index].devices[song.selected_device].parameters[perams*2].value_observable:has_notifier(get_multi_send_pos_and_routing)
  --  renoise.song().tracks[song_selected_track_index].devices[song.selected_device].parameters[perams*2].value_observable:add_notifier(get_multi_send_pos_and_routing)
 --  end
-- end
----------------------------------------------------------------------------------------------------
 
----------------------------------------------
--function that adds and removes menu entries
----------------------------------------------
function add_menus() 

  local song = renoise.song() 
  
  --[1] remove all menu entries (all stored in current_menu_strings {}) 
  --------------------------------------------------------------------
  for i = 1,#current_menu_strings do
    if renoise.tool():has_menu_entry(current_menu_strings[i]) then
         renoise.tool():remove_menu_entry(current_menu_strings[i])
    end
  end
  --RECORD REMOVAL by clearing current_menu_strings {}
  current_menu_strings = {}
  
  --[2]function adds Go "To Send `S01`" entries if on a Multiband Send/ nothing if no Multiband Send selected
  add_new_go_to_send_menus_from_multi()
  
  --[3] function adds `Go To Send` menu entries/ nothing if no Send selected
  add_new_go_to_send_menus()
  -------------------------------------
  
  --add new menu entries when a send-track is selected  
  -----------------------------------------------------
  --Send Device
  if (song.selected_track.type == renoise.Track.TRACK_TYPE_SEND) then --tracks_to_add_to_menu[a].index
  --get the current values for each send device
  local send_table = get_send_pos_and_routing() --see function for detailed explaination of fields)
    if send_table then --i.e. there are send devices present in the song
      for j = 1,#menu_locations do -- "Mixer:","DSP Device:" 
        for i = 1, #send_table.source_track_name do
          if send_table.send_track_index[i] == song.selected_track_index then
          --DSP lane and mixer
            if not renoise.tool():has_menu_entry(menu_locations[j].."Go To Source `"..send_table.source_track_name[i].."`") then
              renoise.tool():add_menu_entry {
                               name = menu_locations[j].."Go To Source `"..send_table.source_track_name[i].."`",
                               invoke = function() song.selected_track_index = send_table.source_track_index[i]
                                          --select_send_device(track_index,send_number) -- SWAP THIS FOR LOCAL CODE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                                          select_send_device(send_table.source_track_index[i],send_table.send_track_number[i])  
                                        end,
                              } 
            --RECORD INSERTION 
            table.insert(current_menu_strings , menu_locations[j].."Go To Source `"..send_table.source_track_name[i].."`")
            end
          end  
        end
      end
    end  
  end
 
  --Multiband Send devices
  if (song.selected_track.type == renoise.Track.TRACK_TYPE_SEND) then
  --get the current values for each multiband send device -
  local multi_send_table = get_multi_send_pos_and_routing() --(see function for detailed explaination of fields) 
    if multi_send_table then
      local tar_band_name = { "L", "M", "H"} 
      for j = 1,#menu_locations do -- "Mixer:","DSP Device:"
        for i = 1,#multi_send_table.source_track_name do --number of Multiband Send devices in song
          
          local l_m_h_string = ""
          --first loop send targets to see which point to current send_track
          for p = 1,3 do --number of potential send targets
            if multi_send_table.target_tracks[i].target_track_index[p] == song.selected_track_index then
              -- if one does add relevant L M or H 
              l_m_h_string = l_m_h_string..tar_band_name[p]
            end
          end  

          if l_m_h_string ~= "" then -- if append string L LM or LMH has been created showing there is routing then add the menu entry
            if not renoise.tool():has_menu_entry(menu_locations[j].."Go To Source `"..multi_send_table.source_track_name[i].."` ("..l_m_h_string..")") then
                renoise.tool():add_menu_entry {
                               name = menu_locations[j].."Go To Source `"..multi_send_table.source_track_name[i].."` ("..l_m_h_string..")",
                               invoke = function() song.selected_track_index = multi_send_table.source_track_index[i]
                                          song.selected_track_index =  multi_send_table.source_track_index[i]
                                        end,
                              } 
              --RECORD INSERTION 
              table.insert(current_menu_strings , menu_locations[j].."Go To Source `"..multi_send_table.source_track_name[i].."` ("..l_m_h_string..")")
            end  
          end
        end
      end
    end
  end
end
 
----------------------------------------------------------------------
--notifiers  --Add has notifiers == test for safety!!!!!   
----------------------------------------------------------------------

 --notifier added whenever a new song is loaded 
function start()
  
  -- reset global values for previous track_index, used in "update_last_selected_track_index()"
  -- if not done these will be nil on start-up of renoise and the tool won`t load
  prev_track_index_holder = renoise.song().selected_track_index
  prev_track_index = prev_track_index_holder

  --selected device notifier, this will fire each time a track is changed aswell
  renoise.song().selected_device_observable:add_notifier(function() add_menus() end) 
  --update for last selected track index for toggle shortcut
  renoise.song().selected_track_observable:add_notifier(update_last_selected_track_index)
end  
--notifier to add above notifiers on new song loaded   
renoise.tool().app_new_document_observable:add_notifier(start)




