TOOL_NAME = "Nudge Track Delay"

--Renoise Keybinds and menus
-------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:"..TOOL_NAME,
  invoke = function()main_toggle()end  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:"..TOOL_NAME,
  invoke = function()main_start()end  
}

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
--[[
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
00
--]]

LUA_COUNTS_FROM_1 = 1

--global variables for gui
local my_dialog = nil 
local vb = nil


--toggle the tool open and closed (keyboard shortcut start-up)
-------------------------------------------------------------
function main_toggle()
----------------------
 --close dialog if it is open
  if (my_dialog and my_dialog.visible) then 
    my_dialog:close()
    --reset global my_dialog
     my_dialog = nil 
  else --run main
    main()
  end
end

--always open/ restart tool (menu entry start-up)
-------------------------------------------------
function main_start()
---------------------
  if (my_dialog and my_dialog.visible) then 
    my_dialog:close()
    --reset global my_dialog
     my_dialog = nil 
  end
  --run main
  main()
end
----------------------------------------------------------


--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
local function status(message)
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
end

--rounding numbers
--------------------------------------
function round(num,d_places)
--------------------------------------
  return tonumber(string.format("%."..(d_places or 0).."f", num))
end


--get renoise track names
----------------------------------
function get_renoise_track_names()
----------------------------------
  local song = renoise.song()
  local track_name_table = {}
  --loop all tracks
  for track = 1,#song.tracks do
    table.insert(track_name_table,song.tracks[track].name)
  end
  --return table with track names
  return track_name_table
end


--nudge delay value, function accounts of nudging sub-tracks in groups
--------------------------------
function nudge_delay_value(val) 
-------------------------------- 
  --renoise objects
  local song = renoise.song()
  local track = song.selected_track
  local track_idx = song.selected_track_index

  --if on a sequencer track then just adust the delay for this track
  if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    --get current track delay value--needs to be rounded to 3 d.p.for accuracy when checking max and min
    local cur_delay = round(track.output_delay,3) 
    --add to user input val, to current delay
    local new_delay_val = cur_delay + val
    --check if we have reached max/min value
    if (new_delay_val > 100) or (new_delay_val < -100) then
     -- status("Trying To Nudge Out Of Bounds")
      return
    end
    --update current track delay value
    song.selected_track.output_delay = cur_delay + val
    --done so return
   -- status("Track Delay Updated: "..new_delay_val.."ms")
    return
  end
  
  --when a group track then adjust delay on all sub tracks 
  if track.type == renoise.Track.TRACK_TYPE_GROUP then
  
    --returns the renoise track-index of the first track in the specified group
    --------------------------------------------------------------
    local function get_index_of_first_track_in_group(group_index)
    -------------------------------------------------------------
      local song = renoise.song()
      local group_track = song:track(group_index)
      --if group has no members then return nil
      if #group_track.members == 0 then
        return nil
      end
      --get the index of the left hand group
      local left_of_grp_idx = (group_index - #group_track.members) 
      --returns index
      return left_of_grp_idx
    end
    ----------
    
    --get the index of the first track in this group using above fn
    local first_track = get_index_of_first_track_in_group(track_idx)
    --index of track just left of group
    local grp_minus_one = track_idx - 1
    
    --in order to check that any group tracks will not go over the nudge limits (-100 to +100ms)
    --we first have to check.  As we check we add legitimate values to a table.  If all values
    --are legitimate we continue to add in a second loop else return with error.
    
    local legit_vals = {} 
    --reset status
    renoise.app():show_status("")
    
    --loop sub tracks in group
    --------------------------
    for trk = first_track,grp_minus_one do
      local cur_trk = song:track(trk)
     --if a sequencer track then nudge
      if cur_trk.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        --get rounded current track delay value
        local cur_delay = round(cur_trk.output_delay,3)
         --add to user input val, to current delay
        local new_delay_val = cur_delay + val
        --check if we have reached max/min value
        if (new_delay_val > 100) or (new_delay_val < -100) then
          status("Delay Would Be Nudged Out Of Bounds On Track: "..trk)
          return
        end
        legit_vals[trk] = cur_delay + val
      end
    end
    --got here, so values are all legitimate so add to tracks in this loop
    for trk = first_track,grp_minus_one do
      local cur_trk = song:track(trk)
      --update current track delay value
      cur_trk.output_delay = legit_vals[trk]
    end
    
    --done so return
  --  status("Track Delays Updated")
    return
  end --if
  status("Track Needs To Be A Sequencer Or A Group Track")
  
end --fn

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
  
  ----------------------------------------------
  --GUI
  ----------------------------------------------     

  --variables that will be added to
  --dialog_content:add_child(send_row)
  local content = 
         vb:column{
          margin = 4,
          vb:row {
           margin = 4,
           
          vb:popup{
           width = 160,
           -- text = "",
            items = get_renoise_track_names(),
            id = "track name",
            notifier = function(value)
                --change track_selection to match what the user chooses in the popup
                renoise.song().selected_track_index = value
                timer() --updates gui quicker
              end
           },
          },
          
           vb:row {
           margin = 4,
            vb:textfield{
              text = "",
              id = "ms readout",
              width = 120,
           }
          },
         

          
         
          vb:row {
           margin = 4,
           vb:button { 
             width = 80,
             height = 25,
             text = "- 1ms",
             notifier = function()
                 
                 nudge_delay_value(-1)
                 
                 --[[
                 --song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay - 1 --]]
               end,
           },
            vb:button { 
             width = 80,
             height = 25,
             text = "+ 1ms",
             notifier = function()
                 nudge_delay_value(1)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay + 1 --]]
               end,
           },
          },
          vb:row {
            margin = 4,
            vb:button { 
             width = 80,
             height = 25,
             text = "- 0.1ms",
             notifier = function()
                 nudge_delay_value(-0.1)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay - 0.1 --]]
               end,
           },
            vb:button { 
             width = 80,
             height = 25,
             text = "+ 0.1ms",
             notifier = function()
                 nudge_delay_value(0.1)
                --[[ --song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay + 0.1 --]]
               end,
           },
 


          },--row
           vb:row {
           margin = 4,
            vb:button { 
             width = 80,
             height = 25,
             text = "- 0.01ms",
             notifier = function()
                 nudge_delay_value(-0.01)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay - 0.01--]]
               end,
           },
            vb:button { 
             width = 80,
             height = 25,
             text = "+ 0.01ms",
             notifier = function()
                 nudge_delay_value(0.01)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay + 0.01 --]]
               end,
           },

          },--row

           vb:row {
           margin = 4,
            vb:button { 
             width = 80,
             height = 25,
             text = "- 0.001ms",
             notifier = function()
                 nudge_delay_value(-0.001)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay - 0.001--]]
               end,
           },
            vb:button { 
             width = 80,
             height = 25,
             text = "+ 0.001ms",
             notifier = function()
                 nudge_delay_value(0.001)
                 --[[--song
                 local song = renoise.song()
                 --get current track delay value
                 local cur_delay = song.selected_track.output_delay 
                 --update current track delay value
                 song.selected_track.output_delay = cur_delay + 0.001 --]]
               end,
           },
          },--row
         }

 
 
  
  --------------------------------------------------------
  --------------------------------------------------------
  --dialog content will contain all of gui; passed to renoise.app():show_custom_dialog()
  local dialog_content = vb:column{}
  dialog_content:add_child(content)


  
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
 
  --add timer to fire once every 50ms
  if not renoise.tool():has_timer(timer) then
    renoise.tool():add_timer(timer,80)
  end

  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    --close dialog if exists and is open     
    if (d ~= nil) and (d.visible == true) then
      d:close()
     -- remove_notifiers()
    end
    --reset global my_dialog
     my_dialog = nil 
  end
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  -------------------------------------------------------------------------------
  
  --first run of timer
   timer()
end


----------------
--timer function
----------------
function timer()
  
  local song = renoise.song()
  --make sure track names are up to date, i.e if the user has changed them while the tool is open
  vb.views["track name"].items = get_renoise_track_names()
  --update selected track display
  vb.views["track name"].value = song.selected_track_index 
  
  local track_del = tostring(song.selected_track.output_delay)
  vb.views["ms readout"].text = string.format("%.3f", track_del).." ms"
  
  --update ms output text on different track types
  if song.selected_track.type == renoise.Track.TRACK_TYPE_GROUP then
    vb.views["ms readout"].text = "[GROUP OPERATION]"
  end
  
  if song.selected_track.type == renoise.Track.TRACK_TYPE_MASTER then
    vb.views["ms readout"].text = "...Not Available..."
  end
  
  if song.selected_track.type == renoise.Track.TRACK_TYPE_SEND then
    vb.views["ms readout"].text = "...Not Available..."
  end
  
  --remove timer when GUI is closed
  if(my_dialog == nil) or (my_dialog.visible == false) then
    if renoise.tool():has_timer(timer) then
      renoise.tool():remove_timer(timer)
    end
  end
end

