--0.51
--fixed max BPM bug (at its limit +30  button would try and set bpm above 999 and fire error)
--tool updates faster when changing track via popup now 
--when song is saved, tool becomes reset so its mods are not saved with song

TOOL_NAME = "Spotlight Solo"

--[[ 
------------------------------------------
--Set up Preferences file
------------------------------------------
--create xml
local options = renoise.Document.create {
  value_a = false,
  value_b = 10,
}
 --assign options-object to .preferences so renoise knows to load and update it with the tool
renoise.tool().preferences = options
------------------------------------------
------------------------------------------
--variable syntax 
--options.value_a.value
--]]

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


LUA_COUNTS_FROM_1 = 1

--global variables for gui
local my_dialog = nil 
local vb = nil

local g_stored_bpm = nil 
local g_stored_track_index = nil
local timer_running = false




--Renoise Keybinds and menus
-------------------------------

--keybind simply toggles open and closed the gui
renoise.tool():add_keybinding {
  name = "Global:Tools:"..TOOL_NAME,
  invoke = function()main()end  
}
----------------------------------------------------------------------------------
--specialised keybind opens dialog with spotlight solo already active.
--if the dialog is already open it just toggles the spotlight function on and off
----------------------------------------------------------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:"..TOOL_NAME.." Start Active + Toggle Solo",
  invoke = function()

              --1) gui already open
              if (my_dialog and my_dialog.visible) then 
                --check spotlight button color
                if vb.views["spotlight button"].color[1] == COLOR_ORANGE_FLAG then
                  vb.views["spotlight button"].color = COLOR_GREY
                else
                 vb.views["spotlight button"].color = COLOR_ORANGE 
                end
                spotlight_solo()
                --return as solo has been toggled
                return
              end
              
              --2) this is first-run as gui is not already open:  run main()
              main()
              --make sure spotlight is enabled
              vb.views["spotlight button"].color = COLOR_ORANGE 
              spotlight_solo()
           end  
}
-----------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:"..TOOL_NAME,
  invoke = function()main()end  
}




--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
local function status(message)
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
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

--stops tool modifications being saved with song
-----------------------------
function tidy_mixing_gainers_and_bpm()
-----------------------------
  local song = renoise.song()
  --restore song bpm
  song.transport.bpm = g_stored_bpm
  
  --reset button colors
  vb.views["spotlight button"].color = COLOR_GREY 
  vb.views["+30 button"].color = COLOR_GREY
  vb.views["-30 button"].color = COLOR_GREY

  --loop through all tracks an delete any Mixing Gainers
  for track = 1,#song.tracks do
    --loop through track devices
    for device = 2,#song.tracks[track].devices do
      --look for Mixing Gainers already present
      if song.tracks[track].devices[device].display_name == "Mixing Gainer" then
        --delete 
        song.tracks[track]:delete_device_at(device)  
      end 
    end
  end
end


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
  
  --update globals
  g_stored_bpm = song.transport.bpm
  g_stored_track_index = song.selected_track_index

  --set globals
  -------------
  --assign global vb to viewbuilder
  vb = renoise.ViewBuilder()
  

  
  
  ----------------------------------------------
  --GUI
  ----------------------------------------------     

  --variables that will be added to
  --dialog_content:add_child(send_row)
  local my_first_row = vb:column { margin = 4}
  -------------------------------
  local my_first_elements = nil
  
  --CONTENT
  ----------------

    --1 button
   my_first_elements =
    vb:column{
     
     vb:text{ 
       text = "BPM",
       id = "original bpm",
      },
      
      vb:row{
       vb:button{ 
        width = 80,
        text = "-30",
        id = "-30 button",
        height = 30,
        color = COLOR_GREY,
        notifier = function()
          local song = renoise.song()
          
          --valid bpm  values are (32 to 999).
          if (song.transport.bpm - 30) > 31 then
            song.transport.bpm = song.transport.bpm - 30
          end
          --run timer to update gui
          timer()
        end,
       
     },
      
     vb:button{ 
      width = 80,
      height = 30,
      text = "+30",
      id = "+30 button",
      color = COLOR_GREY,
      notifier = function()
        local song = renoise.song()
        --valid bpm  values are (32 to 999).
        if (song.transport.bpm + 30) < 1000 then 
          song.transport.bpm = song.transport.bpm + 30 
        end
        --run timer to update gui
        timer()
      end,
      }
     }
    }

    --add each iteration into my_first_row
    my_first_row:add_child(my_first_elements) 

  
  
  --variables that will be added to
  --dialog_content:add_child(send_row)
  local my_second_row = vb:column{ margin = 4}
  -------------------------------
  local my_second_elements = nil
  
  --CONTENT
  ----------------
    --1 button
    my_second_elements = 
    vb:column{
     vb:text{
      text = "Track:"
     },
     
     vb:popup{
        width = 160,
        height = 20,
        items = get_renoise_track_names(),
        value = song.selected_track_index,
        id = "track names",
        notifier = function(value) 
          --return early if it was the timer changing the value and not the user
          if timer_running == true then
            return 
          end
            --change track_selection to match what the user chooses in the popup
          renoise.song().selected_track_index = value
          --update items in case something changed
          vb.views["track names"].items = get_renoise_track_names()
          --run timer to update tool
          timer()
        end
       },
    
    
     vb:text{ 
       text = "Spotlight:"
      },
    vb:row{
      vb:button{ 
        width = 160,
        height = 40,
        text = "Spotlight Solo",
        id = "spotlight button",
        color = COLOR_GREY,
        notifier = function()
          if vb.views["spotlight button"].color[1] == COLOR_ORANGE_FLAG then
            vb.views["spotlight button"].color = COLOR_GREY
          else
           vb.views["spotlight button"].color = COLOR_ORANGE 
          end
        
          spotlight_solo()
        end
       },
      }
     }
                      

    --add each iteration into my_first_row
    my_second_row:add_child(my_second_elements) 

  
  
  --------------------------------------------------------
  --------------------------------------------------------
  --dialog content will contain all of gui; passed to renoise.app():show_custom_dialog()
  local dialog_content = vb:column{margin = 4}
  dialog_content:add_child(my_first_row)
  dialog_content:add_child(my_second_row)


  
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
      TOOL_NAME, dialog_content,my_keyhandler_func)
      
   --update original bmp text 
   
   --rounding function due to lua adding extra decimal places
   --------------------
   local function round(num, numDecimalPlaces)
   --------------------
     local mult = 10^(numDecimalPlaces or 0)
     return math.floor(num * mult + 0.5) / mult
     
   end
   --------
   local rounded_bpm = round(song.transport.bpm, 3)
   local rounded_bpm_string = tostring(rounded_bpm )
   vb.views["original bpm"].text = "BPM: ".."("..rounded_bpm_string..")"


  --add timer to fire once every 30ms (timer can be fast as most code runs on track change)
  if not renoise.tool():has_timer(timer) then
    renoise.tool():add_timer(timer,30)
  end
  
  
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    my_dialog = nil   
    if (d ~= nil) and (d.visible == true) then
      d:close()
      local song = renoise.song()
     -- remove_notifiers()
     --reset song bpm
     song.transport.bpm = g_stored_bpm
    end
  end
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  -------------------------------------------------------------------------------
  --notifier to reset song on save so any modifications tool makes are not saved with song 
  renoise.tool().app_saved_document_observable:add_notifier(tidy_mixing_gainers_and_bpm)
  
  --first run of timer
  -- timer()
end

--called by solo button
-------------------------
function spotlight_solo()
-------------------------
 
 local REDUCED_GAIN = 0.2
  ------------------------------------------------------
  --Helper -- return true for chosen track types else return false
  ------------------------------------------------------
  local function valid_track_type(track)
    local song = renoise.song()
    if song.tracks[track].type == renoise.Track.TRACK_TYPE_SEQUENCER or
      song.tracks[track].type == renoise.Track.TRACK_TYPE_SEND then
      return true
    else
      return false
    end
  end

  --Toggle all instances

  local rns = renoise.song()
  
  local found = false
  --loop through all tracks
  for track = 1,#rns.tracks do
    --loop through track devices
    
    for device = 2,#rns.tracks[track].devices do
      --look for Mixing Gainers already present
      if rns.tracks[track].devices[device].display_name == "Mixing Gainer" then
        --delete 
        rns.tracks[track]:delete_device_at(device)  
        found = true
      end 
    end
  end
  
  --Mixing gainers found and deleted so return.  Tool is toggled off
  if found == true then
    vb.views["spotlight button"].color = COLOR_GREY
    status("Spotlight OFF")
    return
  end
  
  --return and update status if we are on a non sequencer or group track
  if rns.selected_track.type == renoise.Track.TRACK_TYPE_MASTER or
     rns.selected_track.type == renoise.Track.TRACK_TYPE_SEND
  then
    status("Spotlight: Only available on a Sequencer or Group track")
    return
  end
  
  status("Spotlight for `"..rns.selected_track.name.."` ON")
  --update color
  vb.views["spotlight button"].color = COLOR_ORANGE
  
  --if the selected track is a sequencer track
  if rns.selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
  --add negative (mixing) gainers to all other sequencer tracks 
    for track = 1,#rns.tracks do 
      if valid_track_type(track) then
        --only add gainers to unselected tracks
        if track ~= rns.selected_track_index then
          --insert at end of device chain
          local insert_spot = #rns.tracks[track].devices 
          local gainer_device = rns.tracks[track]:insert_device_at("Audio/Effects/Native/Gainer", insert_spot+1)
          --set display name
          gainer_device.display_name = "Mixing Gainer"
          --reduce volume 
          gainer_device:parameter(1).value = REDUCED_GAIN
          --hide volume slider in mixer
          gainer_device:parameter(1).show_in_mixer = false
          --minimize in DSP lane
          rns.tracks[track].devices[insert_spot + 1].is_maximized = false
        end
      end
    end
    -- elseif on GROUP TRACK--
  elseif rns.selected_track.type == renoise.Track.TRACK_TYPE_GROUP then 
    --get number of members in the currently selected group
    local sub_tracks = #rns.selected_track.members
          
    --add negative gainers to all sequencer tracks that are not paert of the group
    --this time loop backwards to make skipping group members easier
    for track = #rns.tracks,1,-1 do   
          
      if valid_track_type(track) then
        
        if track ~= rns.selected_track_index then
          --We`ve hit the selected group track
          --sub_tracks acts as a decrementing flag
          --if sub_tracks > 1, decrement it and do nothing else
          if (track <= rns.selected_track_index) and (sub_tracks > 0) then
            sub_tracks = sub_tracks - 1
          else
            --insert at end of device chain
            local insert_spot = #rns.tracks[track].devices 
            local gainer_device = rns.tracks[track]:insert_device_at("Audio/Effects/Native/Gainer", insert_spot+1)
            --set display name
            gainer_device.display_name = "Mixing Gainer"
            --reduce volume 
            gainer_device:parameter(1).value = REDUCED_GAIN
            --hide volume slider in mixer
            gainer_device:parameter(1).show_in_mixer = false
            --minimize in DSP lane
            rns.tracks[track].devices[insert_spot + 1].is_maximized = false
          end
        end
      end
    end   
  end
end
-----------------

-------------------------------
--timer function
-------------------------------
function timer()
-------------------------------
  
  --timer global
  timer_running = true
      
  local song = renoise.song()
  
  --update BMP buttons color
  --------------------------
  if song.transport.bpm > g_stored_bpm then
    --BPM faster
    vb.views["+30 button"].color = COLOR_ORANGE
    vb.views["-30 button"].color = COLOR_GREY
  elseif song.transport.bpm < g_stored_bpm then
    --BPM slower
    vb.views["+30 button"].color = COLOR_GREY
    vb.views["-30 button"].color = COLOR_ORANGE
  else
    --BPM original
    vb.views["+30 button"].color = COLOR_GREY
    vb.views["-30 button"].color = COLOR_GREY
  end
  
  
  --if user changed name of current track, update the track popup items
  if vb.views["track names"].items[song.selected_track_index] ~= song.selected_track.name then
   --update items in case something changed
   vb.views["track names"].items = get_renoise_track_names()
  end
   
  --------------------  
  --has track changed?
  --------------------
  if g_stored_track_index ~= song.selected_track_index then
   --update globals
   g_stored_track_index = song.selected_track_index
   
   --Change track name popup value 
   vb.views["track names"].value = g_stored_track_index
    
   --SPOTLIGHT BUTTON--
   --update solo state to current track if spotlight solo mode is enabled (BUTTON == ORANGE)
   if vb.views["spotlight button"].color[1] == COLOR_ORANGE_FLAG then
      --1)--loop through all tracks an delete any Mixing Gainers
      for track = 1,#song.tracks do
        --loop through track devices
        for device = 2,#song.tracks[track].devices do
          --look for Mixing Gainers already present
          if song.tracks[track].devices[device].display_name == "Mixing Gainer" then
            --delete 
            song.tracks[track]:delete_device_at(device)  
          end 
        end
      end
      --2) call spotlight function
      spotlight_solo()
    end
  end
  
  ---------------------------------
  --remove timer when GUI is closed
  ---------------------------------
  if(my_dialog == nil) or (my_dialog.visible == false) then
    --remove this timer
    if renoise.tool():has_timer(timer) then
      --clear modificarions made by the tool
      tidy_mixing_gainers_and_bpm()
      --remove `this` timer
      renoise.tool():remove_timer(timer)
      --remove tidy on save notifier
      if renoise.tool().app_saved_document_observable:has_notifier(tidy_mixing_gainers_and_bpm) then
        renoise.tool().app_saved_document_observable:remove_notifier(tidy_mixing_gainers_and_bpm)
      end
    end
  end
  
  --timer global
  timer_running = false
    
end





