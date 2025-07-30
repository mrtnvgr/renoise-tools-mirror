--256
--when a new send is added D+D in MON mode-- tool restarts.  NEED to check if mon mode is already present on startup and set up the tool accordingly/ cancel mon mode.


--Renoise Keybinds and menus
-------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:Send Mixer",
  invoke = function()main()end  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Send Mixer",
  invoke = function()main()end  
}

--import extra .lua files from rest of tool 
require "functions"

--------------------------------------------------------------------------------
--some basic colors for gui elements
--------------------------------------------------------------------------------
--e.g. For changing vb.views["sample present colour 2"].color when states change
COLOR_GREY = {0x30,0x42,0x42}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}
COLOR_RED_MILD = {0x90,0x10,0x10}

--Constants holding first index of color-code: Used to identify color in vb.views table i.e.
--if vb.views["button"].color[1] == COLOR_ORANGE_FLAG then --etc
COLOR_GREY_FLAG = COLOR_GREY[1]
COLOR_ORANGE_FLAG = COLOR_ORANGE[1]
COLOR_YELLOW_FLAG = COLOR_YELLOW[1]
COLOR_BLUE_FLAG = COLOR_BLUE[1]  
COLOR_RED_FLAG = COLOR_RED[1]
COLOR_GREEN_FLAG = COLOR_GREEN[1]
COLOR_RED_MILD_FLAG = COLOR_RED_MILD[1]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--global variables
local my_dialog = nil 
local g_target_send_track_zro = 0 --as in renoise counts from zero
local timer_running = false
local bypass_timer = false
local vb = nil
local g_total_tracks = nil
--global constant to note when using `master track count` in arithmetic
MASTER_TRACK_COUNT = 1
--for use in arithmetic adjusting when renoise API counts from zero and lua counts from 1
LUA_COUNTS_FROM_ONE = 1

--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
local function status(message)
  renoise.app():show_status("Send Mixer Tool: ("..message..")")
end

---------------------------------------------------
--timer()  function constantly called to update the GUI
---------------------------------------------------
---------------------------------------------------
---------------------------------------------------
local function timer()
---------------------------------------------------  
  --flags
  if bypass_timer == true then
    return
  end
  --this is used to bypass any notifier functions that would be called
  --as a result of code in this timer; things with `.value` changes i.e.  vb.views["gui_element_id"].value = x 
  timer_running = true
  ---------------- 
  
  --renoise song object
  local song = renoise.song()
  --the index of the currently selected send track as shown in the tools gui--counts from 1
  local send_index = song.sequencer_track_count + MASTER_TRACK_COUNT + (g_target_send_track_zro + LUA_COUNTS_FROM_ONE)

  --HOUSEKEEPING
  ---------------------
  --check GUI is active(can remain attached if GUI is closed by [X]):
  if my_dialog and (my_dialog.visible == false) then --dialog has been closed
   --1) remove all notifiers (+timers)
    remove_notifiers()
    --2) disable monitor mode if it is enabled
    if string.find(song:track(send_index).name, "MON: ") ~= nil then
      mute_all_tracks_with_silent_gainer()
      --3) unmute all tracks
      for track = 1, #song.tracks do
        song:track(track):unmute() 
      end
    end
    --in case naming has gone wrong and silent gainers are left in the song and missed by the above function then remove them:
    for track = 1, #song.tracks do
      for j = #renoise.song():track(track).devices,2,-1 do
         --4) remove `Silent Gainers` in renoise DSP lane        
         if renoise.song():track(track).devices[j].display_name == "Silent Gainer" then
           renoise.song():track(track):delete_device_at(j)  
         end
      end
    end
    --5) return as tool finished/ closed
    return 
  end

  --restart tool function
  -----------------------------
  local function restart_tool() 
  -----------------------------
    remove_notifiers()
     -- toggle dialog off then on
    if (my_dialog and my_dialog.visible) then 
      my_dialog:close()
      --restart
      main()
    end
  end
  --has user changed track count in renoise by adding/ removing tracks?
  --if so then restart/rebuild the tool (easy way to update gui though resets to centre position and causes `flash`)
  if g_total_tracks ~= (song.sequencer_track_count + song.send_track_count + MASTER_TRACK_COUNT) then
    restart_tool()
    return
  end

  --tool gui updating code--
    
  --1) loop sequencer tracks
  -----------------------
  for track = 1,song.sequencer_track_count do
    --set selected track indicator buttons (GREEN when track selected)
    if track == song.selected_track_index then
      vb.views["selected track"..track].color = COLOR_GREEN
    else
      vb.views["selected track"..track].color = COLOR_GREY
    end
 
    --set all solo buttons (`S` ORANGE when selected)
    if renoise.song().tracks[track].solo_state == true then
      vb.views["solo button"..track].color = COLOR_ORANGE
    else            
      vb.views["solo button"..track].color = COLOR_GREY
    end
    --if its a sequencer track then reset SEND VALUES
    --***This will fire sliders notifiers so we bypass it within that notifier***
    if song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER  or song:track(track).type == renoise.Track.TRACK_TYPE_GROUP then
      local has_send = track_has_send(track)
      vb.views["send slider"..track].value = has_send.send_val --parameter 1 (slider value)
      if has_send.mute_source ~= nil then
        vb.views["muted routing"..track].color = has_send.mute_source --set M. Src. button
        --inactivate button
        vb.views["muted routing"..track].active = true
      else--default to grey when no device present
        vb.views["muted routing"..track].color = COLOR_GREY 
        --inactivate button
        vb.views["muted routing"..track].active = false
      end
    end
    --update sliders so when moved in renoise GUI they will update the tool
    vb.views["send slider"..track].value = track_has_send(track).send_val --parameter 1 (slider value)
  end --track loop
  
  --2)now deal with selected send track
  -----------------------------------
  if renoise.song().send_track_count ~= 0 then
  
    --set send track indicator buttons (green when track selected)
    if send_index == song.selected_track_index then
      vb.views["selected send track"].color = COLOR_GREEN
    else
      vb.views["selected send track"].color = COLOR_GREY
    end
    
    --set send solo button
    if renoise.song():track(send_index).solo_state == true then
      vb.views["send solo button"].color = COLOR_ORANGE
    else            
       vb.views["send solo button"].color = COLOR_GREY
    end --track loop
  
  
     --set MON button state color
     ----------------------------
    for i = 1, #song:track(1).devices do --reverse loop 
      if string.find(song:track(send_index).name, "MON: ") ~= nil then
        vb.views["monitor"].color = COLOR_RED_MILD
        --show auto solo button and text
        vb.views["solo checkbox"].visible = true
        vb.views["auto solo text"].visible = true 
      else 
        vb.views["monitor"].color = COLOR_GREY
        --hide auto solo button and text
        vb.views["solo checkbox"].visible = false
        vb.views["auto solo text"].visible = false
      end
    end
  end--2)
  
  --3) keep send names updated in GUI (this keeps tool updated when send tracks are dragged around too)
  for i = g_total_tracks, (g_total_tracks - song.send_track_count), -1 do
    for j = 1,song.send_track_count do
      vb.views["send button"..j].text = get_send_track_names()[j]
      if j == (g_target_send_track_zro + LUA_COUNTS_FROM_ONE) then
        vb.views["send button"..j].color = COLOR_ORANGE
      end
    end
  end
  
  --4) check track names match (i.e. has track order changed with tracks dragged about by user)
  --if changed then restart the tool
  for track = 1,song.sequencer_track_count do
    if vb.views["text"..track].text ~= song:track(track).name then
      restart_tool()
      return
    end
  end
  
  --5) update post volume slider for the current send track
  vb.views["post vol"].value = song:track(send_index).postfx_volume.value
  --update dB readout text
  vb.views["post readout db"].text = song:track(send_index).postfx_volume.value_string
  
  timer_running = false
end --end of timer()
--------------------------------------------------------------
--------------------------------------------------------------


-----------------------------------------
--removes all added notifiers and timers
-----------------------------------------
function remove_notifiers()
  --remove timer
  if  renoise.tool():has_timer(timer) then
    renoise.tool():remove_timer(timer)
  end
end

--------------------------------
function get_send_track_names()
--------------------------------
  local send_table = {}
  --loop backwards through tracks
  for i = #renoise.song().tracks,1,-1 do
    if renoise.song().tracks[i].type == renoise.Track.TRACK_TYPE_SEND then
     local shortened_name = string.sub(renoise.song().tracks[i].name, 1, 10) -- get shortened name so buttons don`t auto expand
     table.insert(send_table , 1, shortened_name)
    else
     break
    end
  end
   return send_table
end

----------------------------------
function track_has_send(track_num) 
----------------------------------
  local has_send = {}
  has_send.enabled = false
  has_send.color = COLOR_RED_MILD
  has_send.send_val = 0
  has_send.pan_val = 0
  has_send.device_index = nil
  has_send.mute_source = nil
 
 --loop devices in track
 for j = 2,#renoise.song():track(track_num).devices do
    --check for send device name and sending to track 0 (send 01)  ---NEED TO CHANGE TO SELECTED SEND DEST>
   if (renoise.song():track(track_num).devices[j].name == "#Send") and
      (renoise.song():track(track_num).devices[j].parameters[3].value == g_target_send_track_zro) then
     --set table properties
     has_send.enabled = true
     has_send.send_val = renoise.song():track(track_num):device(j):parameter(1).value --send amount parameter
     has_send.pan_val = renoise.song():track(track_num):device(j):parameter(2).value --pan amount parameter
     has_send.device_index = j
     if string.find(renoise.song():track(track_num).devices[j].active_preset_data,"<MuteSource>true</MuteSource>") ~= nil then
      -- print("1")
       has_send.mute_source = COLOR_RED_MILD
     else
       has_send.mute_source = COLOR_GREY
     end
     return has_send
   end
 end
 --no send found so return default false table
 return has_send
end
---------------------------------------

--returns the send track number 1 to x.. if one is selected else returns 1
--used to open gui on a selected send track
------------------------------
function selected_send_track()
------------------------------
 local song = renoise.song()
 local non_send_tracks = song.sequencer_track_count + 1 --add 1 for master track
 if song.selected_track_index > (non_send_tracks) then
   local selected_send_index = (song.selected_track_index - non_send_tracks)
   return selected_send_index
 else
   return 1
 end
end


--------------------------------------------------------
--Functions To Manage (add/delete) Silent Gainers 
--------------------------------------------------------
function add_silent_gainers(start_track,end_track)
-------------------------------------------------------- 
  local song = renoise.song()
  --set initial parameters vales if not passed
  if start_track == nil then start_track = 1 end
  if end_track == nil then endtrack = #song.tracks end
  
  --loop tracks
  for track = start_track,end_track do
    
    if song:track(track).group_parent == nil then  -- if track has no parent group: we don`t want silent gainers added twice; once to group and its sub tracks
      --add silent gainers to non-target sends
      local insert_spot = #song.tracks[track].devices 
      if song.tracks[track].devices[insert_spot].display_name ~= "Silent Gainer"  then
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
end
-------------------------------------------------------
-----------------------------------------------------------
function delete_silent_gainers(start_track,end_track)
-----------------------------------------------------------
 local song = renoise.song()
 --set initial parameters vales if not passed
 if start_track == nil then start_track = 1 end
 if end_track == nil then endtrack = #song.tracks end
 
 --loop tracks
 for track = start_track,end_track do 
   if #song.tracks[track].devices > 1 then
     for devs = #song.tracks[track].devices,2,-1 do  -- do it in reverse to deal with dev number changing
       if song.tracks[track].devices[devs].display_name == "Silent Gainer"  then
         song.tracks[track]:delete_device_at(devs)
       end
     end
   end
 end    
end
----------------------------------------------------------
----------------------------------------------------------


------------------------------------
------------------------------------
function main()
------------------------------------
------------------------------------

  --toggle dialog so if its already open then close it.  The timer will catch
  --that it is closed and do the housekeeping like removing notifiers (and timer itself)
  if (my_dialog and my_dialog.visible) then 
    my_dialog:close()
    return
  end
  
  --renoise song object
  local song = renoise.song()

  --set globals
  -------------
  --assign global vb to viewbuilder
  vb = renoise.ViewBuilder()
  
  -- if a send is selected change when the tool starts up it will be the hilighted button in the tool gui; else default to 0
  if song.selected_track_index > song.sequencer_track_count + LUA_COUNTS_FROM_ONE then
    g_target_send_track_zro = song.selected_track_index - (song.sequencer_track_count + MASTER_TRACK_COUNT + LUA_COUNTS_FROM_ONE)
  else
    g_target_send_track_zro = 0
  end
  
  --total tracks
  g_total_tracks = (song.sequencer_track_count + song.send_track_count + MASTER_TRACK_COUNT)
  --tool needs at least one sends to start/work so check and add one here
  if song.send_track_count == 0 then 
    renoise.song():insert_track_at(g_total_tracks + 1)
    --updat global track count
    g_total_tracks = g_total_tracks + 1
  end
  -----------------------
  
  --set flag for send renaming textfield.  Used to stop the notifier re-firing when clearing the textfield to: "" (empty string)
  local textfield_flag = false 

 ----------------------------------------------
--GUI
----------------------------------------------     

--variables that will be added to
--dialog_content:add_child(send_row)
local button_strip = vb:row {}
local switch_button
local send_row = vb:row {}

--loop to create buttons for user to select the target send tracks
for button = 1, song.send_track_count do

 switch_button = vb:button { 
      width = 80,
      id = "send button"..button,
     -- width = 100,
      text = get_send_track_names()[button],
      color = COLOR_GREY,
      notifier =  function()
                     --bypass flag
                     bypass_timer = true
                     timer_running = true                    

                     local song = renoise.song()
                 
                     g_total_tracks = (song.sequencer_track_count + song.send_track_count + MASTER_TRACK_COUNT)
                     --set global g_target_send_track_zro the new target send track number (sends count from 0 in renoise)
                     g_target_send_track_zro = (button - LUA_COUNTS_FROM_ONE)
                     local send_index = (song.sequencer_track_count + MASTER_TRACK_COUNT + LUA_COUNTS_FROM_ONE + g_target_send_track_zro)
                                        
                     --if the button is already orange then allow this click to select its send track 
                     if vb.views["send button"..button].color[1] == COLOR_ORANGE_FLAG then       --COLOR_ORANGE ={0xFF,0x66,0x00}
                      song.selected_track_index = (song.sequencer_track_count + button + 1)
                     end
                   
                     --loop to set all button colours to grey
                     ----------------------------------------
                     for sends = 1,song.send_track_count do
                       vb.views["send button"..sends].color = COLOR_GREY
                     end
                     --now set clicked button to orange
                     vb.views["send button"..button].color = COLOR_ORANGE-- ={0xFF,0x66,0x00}
                     
                     -----------------------------
                     --if "MON" button is enabled
                     -----------------------------
                     if vb.views["monitor"].color[1] == COLOR_RED_MILD_FLAG then --COLOR_RED =
                     
                       --1) loop all tracks add silent gainers to all tracks except target send
                       ------------------------------------------------------------------------
                       for track = 1, #song.tracks do
                          --unmute track  --if its a sequencer track then re-get send values 
                         if song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER or
                           song:track(track).type == renoise.Track.TRACK_TYPE_GROUP then 
                           --update slider value
                           vb.views["send slider"..track].value = track_has_send(track).send_val
                         else --SEND TRACKS --manage Silent gainers on Send Tracks
                           if song:track(track).type ~= renoise.Track.TRACK_TYPE_MASTER then
                             --remove silent gainer on target send
                             if track == (song.sequencer_track_count + MASTER_TRACK_COUNT + g_target_send_track_zro + 1)  then
                               --delete silent gainers (start_track,end_track) 
                               delete_silent_gainers(track,track)
                             else
                               --add silent gainers (start_track,end_track)
                               add_silent_gainers(track,track) 
                             end
                           end
                         end --if sequnceror grp track
                       end --for loop
                       -------------                        
                       --2) reverse loop to delete silent gainers from ALL sends if checkbox not active
                       --------------------------------------------------------------------------------
                       if vb.views["solo checkbox"].value == false then
                         for track = #song.tracks,1,-1 do
                           if song:track(track).type == renoise.Track.TRACK_TYPE_SEND then
                             --delete silent gainers (start_track,end_track)
                             delete_silent_gainers(track,track)
                           else
                             break --if we reached master track
                           end   
                         end
                       end
                     end --end of: if MON enabled------
                     
                     --reset flags
                     bypass_timer = false
                     timer_running = false
                     --run timerfn to update gui (can make gui more responsive)
                     timer()
                  end,--end notifier
        }--popup
    --add each iteration into button_strip
    button_strip:add_child(switch_button) 

end --end loop


----------------------------------------------------


--send mix strip
---------------
send_row = vb:vertical_aligner {

   mode = "center",
   
   vb:column {
    margin = 8,
    
    vb:row {
    margin = 4,
    style = "group", 
 
     button_strip ,
     
      vb:textfield{
       id = "rename send txt",
       notifier = function(value)
                   
                   bypass_timer = true
                   local song = renoise.song()
                   
                   --if MON enabled then prepend it to text string (value)
                   if vb.views["monitor"].color[1] == 0xEE then --COLOR_RED_MILD = {0xEE,0x10,0x10}
                     value = "MON: "..value
                   end
                   
                   --local flag to stop this function refiring when clearing this textfield below
                   if textfield_flag == true then
                     textfield_flag = false
                     return
                   end   
                       
                   --send index gives lua index for send buttons
                   local send_button_index = g_target_send_track_zro + LUA_COUNTS_FROM_ONE
                   local send_renoise_index = song.sequencer_track_count + send_button_index + MASTER_TRACK_COUNT
                   
                   --rename track in renoise
                   song:track(send_renoise_index).name = value
                   --rename the send button
                   vb.views["send button"..send_button_index].text = get_send_track_names()[send_button_index] --value--
                   --set flag
                   textfield_flag = true
                   --clear current textfield when done
                   vb.views["rename send txt"].value = ""
                   --set timer flag
                   bypass_timer = false 
                   --run timer
                   timer()
                   
                  end
      
      },  
        
      vb:button{
       text = "RESET",
       color = COLOR_GREY,
       id = "reset",
       width = 20,
       notifier = function()
                    --song object
                    local song = renoise.song()
                    local send_index = renoise.song().sequencer_track_count + 2 + g_target_send_track_zro

                    --disable monitor mode if it is enabled
                    if string.find(song:track(send_index).name, "MON: ") ~= nil then
                     -- mute_all_tracks_with_silent_gainer()
                    end
                    
                    --in case naming has gone wrong and silent gainers are left in the song and missed by the above function:
                    for track = 1, #song.tracks do
                      for j = #renoise.song():track(track).devices,2,-1 do
                        --update slider to match target send device          
                        if renoise.song():track(track).devices[j].display_name == "Silent Gainer" then
                           renoise.song():track(track):delete_device_at(j)  
                        end
                      end
                      
                      if string.find(song.tracks[track].name, "MON: ") then
                       --replace send prefix with empty string
                        song.tracks[track].name = string.gsub(song.tracks[track].name, "MON: ", "")  
                      end
                    end
                    
                    --unmute all tracks
                    for track = 1, #song.tracks do
                      --unmute track  
                      song:track(track):unmute()
                      --if its a sequencer track then reset send values 
                      if song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER then
                        vb.views["send slider"..track].value = track_has_send(track).send_val
                      end                
                    end
                    
                    --reset popup
                   -- vb.views["send switch"].items = get_send_track_names()
                  end
     },
     
     vb:text{
       text = "  Vol: ",
     },
     
     vb:minislider{
       id = "post vol",--post mixer volume
       max = song:track(1).postfx_volume.value_max,--post vol max will be same as track one
       height = 18,
       width = 80,
      -- max = 3.0,
      -- min = -24.0,
       notifier = function(value)
       
                   --bypass function if triggered by timer
                    if timer_running == true then
                      return
                    end
                    --bypass timer in case function triggers
                    bypass_timer = true
       
                     --song object
                    local song = renoise.song()
                    local send_index = renoise.song().sequencer_track_count + 2 + g_target_send_track_zro
                    --update target send post mixer volume
                    song:track(send_index).postfx_volume.value = value
                   
                    bypass_timer = false
                    --run timer to speed up gui response
                    timer()
                  end
     
     },
     
      vb:text{
       id = "post readout db",
       text = "0.0dB",
     },
    
     
 
       }, --row
     
     
     --MON ROW   
     ------------
     vb:row{
       margin = 2,
       --selected led (send)
      vb:button{
       color = COLOR_GREY,
       id = "selected send track",
       width = 20,
       notifier = function()
                   local track = renoise.song().sequencer_track_count + MASTER_TRACK_COUNT + g_target_send_track_zro + LUA_COUNTS_FROM_ONE
                   renoise.song().selected_track_index = track
                  end
     },
      --solo (send)
      vb:button{
        text = "S",
       id = "send solo button",
       
       notifier = function()
                    --solo
                    local song = renoise.song()
                    local track = song.sequencer_track_count + MASTER_TRACK_COUNT + g_target_send_track_zro + LUA_COUNTS_FROM_ONE
                    song.tracks[track]:solo()
                  end
      },
      
 
      vb:button{
       text = "MON",
       color = COLOR_GREY,
       id = "monitor",
       width = 20,
       notifier = function()
       
                    --bypass function if triggered by timer
                    if timer_running == true then
                      return
                    end

                   local song = renoise.song()
                   local send_prefix = "MON: "
                   local first_send_index = song.sequencer_track_count + MASTER_TRACK_COUNT + 1
                   local end_track = #song.tracks
                   --target send track of tool
                   local send_index = renoise.song().sequencer_track_count + MASTER_TRACK_COUNT + g_target_send_track_zro + LUA_COUNTS_FROM_ONE
                   
                   -----------------------------------------------------
                   --TURN MON MODE OFF (SWITCH TO GREY)
                   -----------------------------------------------------
                   if vb.views["monitor"].color[1] == COLOR_RED_MILD_FLAG then
                     --set color to Grey (switch off)
                     vb.views["monitor"].color = COLOR_GREY
                     
                     --delete all silent gainers (all tracks)
                     local start_track = 1
                     local end_track = #song.tracks
                     --call delete function
                     delete_silent_gainers(start_track,end_track)
                     
                     --Loop Sends to change names
                     for track = first_send_index,end_track do
                       --remove "MON: :" to send tracks
                       if string.find(song.tracks[track].name, send_prefix) then
                       --replace send prefix with empty string
                         song.tracks[track].name = string.gsub(song.tracks[track].name, send_prefix, "")  
                       end
                     end
                   -----------------------------------------------------
                   else --TURN `MON` MODE ON (SWITCH TO RED)
                   -----------------------------------------------------
                     --set color to Red (switch ON)
                     vb.views["monitor"].color = COLOR_RED_MILD
                     
                     --loop all tracks
                     for track = 1,end_track do
                       --unmute all tracks
                       song:track(track).mute_state = 1
                     end
                     
                     --loop sequencer tracks
                     for track = 1,song.sequencer_track_count do
                       --add silent gainer to sends
                       add_silent_gainers(track,track)
                     end
                     
                     --Loop Sends
                     for track = first_send_index,end_track do
                       --make sure track name does not already contain MON: 
                       if string.find(song.tracks[track].name, send_prefix) == nil then
                         --add "MON: :" to send tracks
                         song:track(track).name = send_prefix..song:track(track).name
                       end
                       --add silent gainer to sends if solo mode is enabled.  We skip send_index as it is the send track we want to solo 
                       if (vb.views["solo checkbox"].value == true) and (track ~= send_index) then
                         add_silent_gainers(track,track)
                       end
                     end
                   end

                   timer_running = false 
                   
                   --run timer to speed up gui response
                   timer()
                 end--end notifier
     },
     
      vb:text {
       text = " Auto Solo: ",
       id = "auto solo text",
       font = "bold",
      },
     
     vb:checkbox {
      id = "solo checkbox",
      value = true,
      notifier = function(value)
                   
                  if vb.views["monitor"].color[1] ~= COLOR_RED_MILD_FLAG then --0xEE then --COLOR_RED = 
                    return
                  end
                  
                  bypass_timer = true
                  
                  local song = renoise.song()
                  
                  local send_index = song.sequencer_track_count + g_target_send_track_zro +2
                  --DELETE GAINERS
                  if value == false then
                    for track = #song.tracks,1,-1 do
                      if song:track(track).type == renoise.Track.TRACK_TYPE_SEND then
                       --delete gainers
                        if #song.tracks[track].devices > 1 then
                          for devs = #song.tracks[track].devices,2,-1 do  -- do it in reverse to deal with dev number changing
                            if song.tracks[track].devices[devs].display_name == "Silent Gainer"  then
                             song.tracks[track]:delete_device_at(devs)
                            end
                          end
                        end
                      else
                        break --if we reached master track
                      end 
                    end--for
                  end --if
                  
                  if value == true then
                    for track = #song.tracks,1,-1 do
                      local insert_spot = #song.tracks[track].devices 
                       if song:track(track).type == renoise.Track.TRACK_TYPE_SEND and
                          track~= send_index  then
                         if song.tracks[track].devices[insert_spot].display_name ~= "Silent Gainer" then
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
                  end --if
                  bypass_timer = false
                end--fn
     }
     
 
     
     
     
    },--row
   

  --[[ vb:column{
    margin = 8,
    style = "group",
     vb:rotary{
      -- active = track_has_send(i).enabled,
      -- id = "pan rotary"..i,
      -- value = track_has_send(i).pan_value,
       notifier = function(value)
       
       --set pan amount value
        renoise.song():track(i):device(track_has_send(i).device_index):parameter(2).value = value
         end
     
     },
     
      vb:horizontal_aligner{
      mode= "justify",
     
       vb:slider{
      --  id = "send slider"..i,
      -- active = track_has_send(i).enabled,
        width = 30,
        height = 150,
      --  value = track_has_send(i).send_val,
       max = 1,
        notifier = function(value)
                   
                  if bypass_timer == true then
                    return
                  end
                   
                   local track = renoise.song().sequencer_track_count + 2 + g_target_send_track_zro
                   renoise.song().selected_track_index = track
                   renoise.song().tracks[track].devices[1].parameters[2].value = value

                    --SET POST SEND VOLUME
                    
                   end
       },--slider
      },--horiz aligner
    },--column--]]
   }, --column  
  } --send row




---------------------------------------------
---------------------------------------------
--1) assign a variable as a viewbuilder:row {}

local mixer_strips = vb:row {}
---------------------------------

--2) loop adding child views to the row
---------------------------------------------
--loop to create mixer strips
---------------------------------------------
 for i = 1,renoise.song().sequencer_track_count do
  
   local mixer_strip = vb:vertical_aligner {
  -- margin = 2,
   mode = "center",

   vb:column {
    margin = 8,
    --tack name               
    vb:textfield {
     id = "text"..i,
     width = 52,
     bind = song:track(i).name_observable,
    },
    
    vb:row{
      --select track LED (seq tracks)
      vb:button{
       color = COLOR_GREY,
       id = "selected track"..i,
       width = 20,
       notifier = function()
                    local song = renoise.song()
                    --select track
                    song.selected_track_index = i
                 
                    --select relevant send device
                    for j = 2,#renoise.song():track(i).devices do
                      --check for send device present and pointing to the selected send
                      if (song:track(i).devices[j].name == "#Send") and
                        (song:track(i).devices[j].parameters[3].value == g_target_send_track_zro) then
                        --select device
                        song.selected_track_device_index = j
                      end
                    end
                  end
      },
      
         --solo (seq tracks)
        vb:button{
          text = "S",
          id = "solo button"..i,
         
          notifier = function()
                       --solo
                       renoise.song().tracks[i]:solo()
                       
                       
                       
                       --[[
                       --if in MON mode then mute the send tracks that are not pointed to
                       if vb.views["monitor"].color[1] == COLOR_RED_MILD_FLAG then 
                         local selected = g_target_send_track_zro + MASTER_TRACK_COUNT + song.sequencer_track_count + LUA_COUNTS_FROM_ONE
                        -- vb.views["auto solo text"].text = "  "..song:track(i).name.."  >>>  "..song:track(selected).name
                       
                         for track = #song.tracks,1,-1 do
                           if song:track(track).type == renoise.Track.TRACK_TYPE_SEND then
                              -- print("send")
                             if track == selected then
                             --  print("track selected"..track)
                               song:track(track).mute_state = 1 --active
                             else
                            -- print("track not selected"..track)
                               song:track(track).mute_state = 2 --muted
                             end
                           else
                             --looping backwards so this will break when we hit master track
                             break
                           end
                         end
                       end
                       if renoise.song().tracks[i].mute_state == 2 then
                        -- vb.views["auto solo text"].text = "  All Tracks  >>>  "..song:track(selected).name
                       end--]]
                         
                      -- bypass_timer = true
                         end
        },
      },
      
      
     
     
     vb:column{-- (seq tracks)
      margin = 8,
      style = "group",
       
       --[[vb:rotary{
        -- active = track_has_send(i).enabled,
         id = "pan rotary"..i,
         value = track_has_send(i).pan_value,
         notifier = function(value)
         
         --set pan amount value
          renoise.song():track(i):device(track_has_send(i).device_index):parameter(2).value = value
           end
       
       },--]]
       
        vb:horizontal_aligner{
        mode= "justify",
       
         vb:slider{
          id = "send slider"..i,
        -- active = track_has_send(i).enabled,
          width = 30,
          height = 150,
          value = track_has_send(i).send_val,
          notifier = function(value)
                     
                     --bypass function if triggered by timer
                     if timer_running == true then
                       return
                     end
                     --stop retriggers
                     bypass_timer = true
                     
                     local song = renoise.song()
                     local send_device = nil
                     local device_present = false
                     local track_num = i
                     local silent_gainer_present = false
                     --device pos where new send will be added if needed
                     local insert_position = (#renoise.song():track(track_num).devices + 1)
                     
                   --  g_target_send_track_zro =
                     
                     --loop 1) Find present send device
                     
                     --reverse loop devices in track to see if send already present and get insert position
                     --for adding new send
                     for j = #song:track(track_num).devices,2,-1 do
                       local device = song:track(track_num).devices[j]
                        --check for send device name and sending to track 0 (send 01)  ---NEED TO CHANGE TO SELECTED SEND DEST>
                       if (device_present == false) and
                          (device.name == "#Send") and
                          (device.parameters[3].value == g_target_send_track_zro)then
                          device_present = true
                        
                          if (song.selected_track_index == track_num) then
                            song.selected_device_index = j
                          end
                          --!FOUND! so set the send device to the selected device
                          send_device = device
                          --device found so break the loop
                          break
                       end
                     end
                     
                     --to allow user to delete send devices while GUI is open/ otherwise slider fires to add a new send
                     --again as the slider resets to 0
                     if (device_present == false) and (vb.views["send slider"..i].value == 0) then
                       status("returned")
                       return
                     end
                     
                     --loop 2) Only if device not found
                     
                     --as no device was found we need to check where to put new device 
                     if (device_present == false) then
                       for j = #song:track(track_num).devices,2,-1 do
                         local device = song:track(track_num).devices[j]
                         --check for silent gainers (i.e. when "MON" mode is on)
                         if (device.display_name == "Silent Gainer") and (silent_gainer_present == false) then 
                           silent_gainer_present = true
                           insert_position = insert_position - 1 --so device is added before the Silent Gainer
                         end
                         --check to see if any sends have `Mute Source` enabled.  If they do we want to insert any new
                         --sends before them or they will not get any audio to send 
                         if string.find(device.active_preset_data,"<MuteSource>true</MuteSource>") ~= nil then
                           insert_position = (j) 
                         end
                       end
                     end
                     
  
                     local target_to_string = tostring(g_target_send_track_zro)
                     --add a send device 
                     if send_device == nil then
       
                            send_device = song:track(i):insert_device_at("Audio/Effects/Native/#Send",insert_position)
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
                                      <Value>]]..target_to_string..[[</Value>
                                    </DestSendTrack>
                                    <MuteSource>false</MuteSource>
                                    <SmoothParameterChanges>true</SmoothParameterChanges>
                                  </DeviceSlot>
                                </FilterDevicePreset>
                                ]]
                                
                                
                          vb.views["send slider"..i].active = true
                       -- vb.views["pan rotary"..i].active = true
                    end
  
                    --set send amount value
                    send_device:parameter(1).value = value
          
                    --unmute send track  
                    local send_index =(renoise.song().sequencer_track_count + MASTER_TRACK_COUNT + LUA_COUNTS_FROM_ONE + send_device:parameter(3).value)
                    song.tracks[send_index]:unmute()
                    
                    --reset flag 
                    bypass_timer = false
                   end
         },--slider        
        },--horiz aligner
      },--column

      vb:button{
        width = 30,
        text = "M. Src.",
        color = COLOR_GREY,
        id = "muted routing"..i,
        notifier = function()
                    -- renoise.song():track(i):device(2).active_preset_data
                     
                     local song = renoise.song()
                     local send_device = nil
                     local device_present = false
                     local track_num = i
                     --reverse loop devices in track to see if send already present and get insert position
                     --for adding new send
                     for j = #song:track(track_num).devices,2,-1 do
                       local device = song:track(track_num).devices[j]
                        --check for send device name and sending to track 0 (send 01)  ---NEED TO CHANGE TO SELECTED SEND DEST>
                       if (device_present == false) and
                          (device.name == "#Send") and
                          (device.parameters[3].value == g_target_send_track_zro)then
                          device_present = true
                        
                          if (song.selected_track_index == track_num) then
                            song.selected_device_index = j
                          end
                          --!FOUND! so set the send device to the selected device
                          send_device = device
                          --device found so break the loop
                          break
                       end
                     end
                     -- do nothing if no send device found
                     if send_device == nil then
                       return
                     end
                     --toggle the state of the send
                     if string.find(send_device.active_preset_data,"<MuteSource>true</MuteSource>") ~= nil then
                        --substitute value in preset to false
                        send_device.active_preset_data = string.gsub(send_device.active_preset_data, "<MuteSource>true</MuteSource>", "<MuteSource>false</MuteSource>")
                        vb.views["muted routing"..i].color = COLOR_GREY
                     else
                        --substitute value in preset to true
                        send_device.active_preset_data = string.gsub(send_device.active_preset_data, "<MuteSource>false</MuteSource>", "<MuteSource>true</MuteSource>")
                        vb.views["muted routing"..i].color = COLOR_RED_MILD
                     end
                   end ,
        
       
       },
       
    },
   }--end one mixer strip
  
  --add each iteration to mixer_strips (== vb:row {})         
  mixer_strips:add_child(mixer_strip)    
end--end for loop
------------------------------------------
------------------------------------------

--------------------------------------------------------

--------------------------------------------------------
local dialog_content = vb:column{}

--send_row = vb:row{ style = "panel",send_row}
mixer_strips = vb:row{ style = "body",mixer_strips}
--centre the send buttons as GUI expands
if #renoise.song().tracks > 15 then
  send_row = vb:horizontal_aligner{mode = "center",send_row}
end

dialog_content:add_child(send_row)
dialog_content:add_child(mixer_strips)




  --------------
  --key Handler
  --------------
  local function my_keyhandler_func(dialog,key)
  
     --toggle lock focus hack, allows pattern ed to get key input
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     
     return key

  end 



------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Script dialog
my_dialog = renoise.app():show_custom_dialog(
    "Send Mixer", dialog_content,my_keyhandler_func)



--add timer to fire once every 50ms
if not renoise.tool():has_timer(timer) then
  renoise.tool():add_timer(timer,80)
end
--------------------------------------------    
--close dialog function ON NEW SONG
--------------------------------------------
local function closer(d)
  my_dialog = nil    
  if d and d.visible then
    d:close()
    remove_notifiers()
  end
end
-- notifier to close dialog on load new song
renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
-------------------------------------------------------------------------------

--first run of timer
timer()

end
