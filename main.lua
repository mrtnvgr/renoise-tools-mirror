--[[  0.82 
--removed esc to exit from keyhandler
--]]


--keybinding
-------------
renoise.tool():add_keybinding {
  name = "Global:Tools:Mix Balancer",
  invoke = function()main()end 
}

-----------------
--Tools main menu entry
-----------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Mix Balancer",
  invoke = function()main()end
}

renoise.tool():add_menu_entry {
  name = "DSP Device:Mix Balancer",
  invoke = function()main(true)end
}


--PREFERENCES VARIABLES FORMAT: options.***var_name***.value
------------------------------------------
--Set up Preferences file
------------------------------------------
--create preferences xml
options = renoise.Document.create {
  auto_limit_enabled  = true,
  selected_gain_mode = "Inverse", --"Current", "Active"
  g_set_gain_buttons_to_half = false,
}



--assign options-object to .preferences so renoise knows to load and update it with the tool
renoise.tool().preferences = options
--------------------------------------------
--------------------------------------------

----------
--globals
----------
--GUI
my_dialog = nil
vb = renoise.ViewBuilder()
--local options.selected_gain_mode.value = false
local fader_yellow_flagged = false
local fader_red_flagged = false
--local options.auto_limit_enabled.value = false




--e.g. For changing ---vb.views["sample present colour 2"].color--- when states change
COLOR_GREY = {0x30,0x42,0x42}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}

-------------------------------------------------------------------------------------
--Functions
-------------------------------------------------------------------------------------
-------------------------------
--convert dB readout to number
---------------------------------------
local function dB_to_number(dB_readout)
----------------------------------------
  if dB_readout == nil then
    return nil 
  end
  --the dB value string readout returns a string in the format: "27.76 dB"
  --return from first character until the third from the end.  i.e. strip out " dB"
  return string.sub(dB_readout, 1, -3) -- 8 from the end until 6 from the end
end

-------------------------------------
--convert number to dB readout format
-------------------------------------
local function number_to_dB(number)
------------------------------------
  return tostring(number).." dB"
end

--------------------------------------------------------
--adds two dB readout string values together numerically
--------------------------------------------------------
local function add_value_strings(string_one,string_two)
-------------------------------------------------------
  local sum_string = dB_to_number(string_one) + dB_to_number(string_two)
  sum_string = number_to_dB(sum_string)
  return sum_string
end

--------------------------------------------------------
--minus string two (dB) from string one (dB) --returns a string
--------------------------------------------------------
local function minus_value_string(string_one,string_two)
--------------------------------------------------------
  --sum_string is now a number
  local sum_string = dB_to_number(string_one) - dB_to_number(string_two)
  
  --weed out rounding errors 
  if (sum_string < 0.1) and (sum_string > -0.1) then
    return "0.00 dB"
  else
    return number_to_dB(sum_string)
  end
end

---------------------------------------------------------------------------------
--returns a text string of the headroom left on the highest sequencer track fader
---------------------------------------------------------------------------------
function get_headroom_from_highest_fader()
------------------------------------------
 --song
 local song = renoise.song()
 
 --variable to store track index with highest fader vvalue
 local higest_fader_index = 1
 local higest_fader_value = 0
 
   --loop all tracks and change volumes
   for track = 1, song.sequencer_track_count do
     --only apply to sequencer tracks that are not on -INF dB
     if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
        (song:track(track).postfx_volume.value_string ~= "-INF dB") then
        
       if song:track(track).postfx_volume.value > higest_fader_value then
         higest_fader_value = song:track(track).postfx_volume.value
         higest_fader_index = track
       end 
     end 
   end
   
   local highest_value_string = song:track(higest_fader_index).postfx_volume.value_string
   
   highest_value_string = string.sub(highest_value_string, 1, 4).." dB"
   --return headroom as a dB string
   return highest_value_string  
end

----------------------------------------
local function get_highest_fader_index()
----------------------------------------
  --song
 local song = renoise.song()
 
 --variable to store track index with highest fader vvalue
 local higest_fader_index = 1
 local higest_fader_value = 0
 
 --loop all tracks and change volumes
 for track = 1, song.sequencer_track_count do
   --only apply to sequencer tracks that are not on -INF dB
   if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
      (song:track(track).postfx_volume.value_string ~= "-INF dB") then
      
     if song:track(track).postfx_volume.value > higest_fader_value then
       higest_fader_value = song:track(track).postfx_volume.value
       higest_fader_index = track
     end 
   end 
 end
 --go to instrument track with highest post fader value
 return higest_fader_index  
end

------------------------------------------------
--function checks the fader for the given track index
-- and changes the GUI button colors to warn if close to maximum
--returns the warning color as a string if it gets flagged
-------------------------------------------------
function check_if_close_to_fader_max(track_index)
-------------------------------------------------
  
  --flag stops function being called once a single track has been found to be close to max value --in the red
  if fader_red_flagged == true then
   return
  end
  
  local song = renoise.song()
  
  --check if only about 1dB of headroom left on track
  if (tonumber(dB_to_number(song:track(track_index).postfx_volume.value_string)) >= 1.9) then
    vb.views["All - 1dB"].color = COLOR_RED
    fader_red_flagged = true
    return "red"
  end
   
  --yellow flag has already been struck so return to stop the next track in the loop turning the color grey again if it is lower than threshold
  --also save cpu  
 if fader_yellow_flagged == true then
   return "yellow"
 end
  
  --check if we are within about two decibels of the maximum value of this fader.  If so warn by changing buttons colour to yellow
  if tonumber(dB_to_number(song:track(track_index).postfx_volume.value_string)) >= 1 then
    vb.views["All - 1dB"].color = COLOR_YELLOW
    fader_yellow_flagged = true
    return "yellow"                        
  else
    vb.views["All - 1dB"].color = COLOR_GREY
  end
end

-------------------------
--get renoise track names
-------------------------
function get_renoise_track_names()
  local song = renoise.song()
  local track_name_table = {}
  --loop all tracks
  for track = 1,#song.tracks do
    table.insert(track_name_table,song.tracks[track].name)
  end
  --return table with track names
  return track_name_table
end

-----------------------------------------------------------------------------------
--Function called by main gain buttons.  
--Arg 1: gain applied to selected track fader
--Arg 2: gain applied to all other sequencer track faders
--String format including space: increment_gain_button("1.00 dB","-1.00 dB")
-----------------------------------------------------------------------------------
function increment_gain_button(current_track_gain_str,inverse_track_gain_str)
  --song
  local song = renoise.song()
  
  --add a dB to current track; skip -INF tracks
  if song.selected_track.postfx_volume.value_string ~= "-INF dB" then
    song.selected_track.postfx_volume.value_string = add_value_strings(song.selected_track.postfx_volume.value_string,current_track_gain_str)
  end
  
  -- true means current track only mode so return here as current track has been modified
  if options.selected_gain_mode.value == "Current" then
    return
  end                    
   
  --loop all tracks and change volumes
  for track = 1, song.sequencer_track_count do
    --only apply to sequencer tracks that are not the current one
    if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and --weed out non sequencer tracks
       (track ~= song.selected_track_index) and                           --weed out selected track
       (song:track(track).postfx_volume.value_string ~= "-INF dB") and    --weed outsliders set to "-INF dB"
       (not (song:track(track).group_parent and (song:track(track).group_parent.name == song.selected_track.name))) then --weed out sub group tracks
     
      --add the dB amount onto other slider
      if options.selected_gain_mode.value == "Inverse" then 
        --inverse so minus a dB
        song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,inverse_track_gain_str)
      else 
        --same as current track; add a dB
        song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,current_track_gain_str)
      end                               
    end 
  end
  
  --variable stores whether any sliders are in the red or yellow from ||check_if_close_to_fader_max(track)|| function
  local color_flag = nil
  
  --when inverse mode and auto reduction are enabled
  --if any faders are reaching max values reduce all faders accordingly
  -------------------------------------------------------------
  if (options.auto_limit_enabled.value == true) and (options.selected_gain_mode.value == "Inverse") then
                                
     --loop all tracks and check volumes .  If a color_flag is returned "yellow"/"red"
     for track = 1, song.sequencer_track_count do
       --only apply to sequencer tracks that are not on -INF dB
       if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
          (song:track(track).postfx_volume.value_string ~= "-INF dB") then
         --check if we are getting close to fader max on current track (in loop)
         color_flag = check_if_close_to_fader_max(track)
         --when color_flag is red we need to reduce by 2dB so no need to check other tracks for the same
         if color_flag == "red" then
           break
         end
       end 
     end--for loop
     
     ------------
     ------------
     if (color_flag ~= nil) then
       --loop all tracks and change volumes as color_flag has been found
       for track = 1, song.sequencer_track_count do
         --only apply to sequencer tracks that are not on -INF dB
         if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
            (song:track(track).postfx_volume.value_string ~= "-INF dB") and
          (not (song:track(track).group_parent and (song:track(track).group_parent.name == song.selected_track.name))) then --weed out sub group tracksthenthen
            --reduce a dB on fader
            if color_flag == "yellow" then --only take off 1dB
              song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,"-1.00 dB")
            elseif color_flag == "red" then --take off 2 dB
              song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,"-2.00 dB")
            end
         end 
       end
     end
   end
   ----------
   -----------
   
end--fn

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 
--function called all the time the GUI is open
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function timer_function()
  
  --if dialog closed remove timer and other housekeeping
  if  my_dialog == nil or (my_dialog.visible == false) then
    --make sure dialog == nil
    my_dialog = nil
    --remove notifier
    if renoise.tool():has_timer(timer_function) then
      renoise.tool():remove_timer(timer_function)
    end
    return
  end
  
  local song = renoise.song()
  
  --make sure track names are up to date, i.e if the user has changed them while the tool is open
  vb.views["track name"].items = get_renoise_track_names()
  
  --update selected track display
  vb.views["track name"].value = song.selected_track_index 
    
  --update minimum headroom display
  vb.views["headroom dB"].value =  get_headroom_from_highest_fader()
  
  vb.views["post gain txt"].text = song.selected_track.postfx_volume.value_string
  
  --update "G" button color.  If selected track is the highest fader then make button green
  if song.selected_track_index ~= get_highest_fader_index() then
    vb.views["G button"].color = COLOR_GREY
  else
    vb.views["G button"].color = COLOR_GREEN
  end
  
  if options.selected_gain_mode.value == "Current" then
    vb.views["auto"].color = COLOR_GREY
  elseif (options.selected_gain_mode.value == "Inverse") and (options.auto_limit_enabled.value == true) then
    vb.views["auto"].color = COLOR_ORANGE
  end  
                                            
  
  --loop all tracks and check volumes color changed in function: [check_if_close_to_fader_max(track)]
  for track = 1, song.sequencer_track_count do
    --only apply to sequencer tracks that are not on -INF dB
    if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
       (song:track(track).postfx_volume.value_string ~= "-INF dB") then
      --check if we are getting close to fader max on current track (in loop)
      check_if_close_to_fader_max(track)
    end 
  end
   ------------
   ------------
   --reset global GUI button color flags, for next run
   fader_yellow_flagged = false
   fader_red_flagged = false
   ------------------------------------
end 

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
----main()
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
------------------------
function main(menu_call)
------------------------

  --allows main shortcut to work as toggle
  if my_dialog and (my_dialog.visible) then
    --close dialog
    my_dialog:close()
    --reset globals
    my_dialog = nil
    --return if called by shortcut (toggle) else carry on and re-start tool to bring it back into focus from menu
    if menu_call ~= true then
      return
    end
  end
  

  --song object
  local song = renoise.song()
  
  --reset viewbuilder
  vb = renoise.ViewBuilder()
  my_dialog = nil
  
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  --GUI
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
   
  local dialog_content = 
    vb:vertical_aligner {
      margin = 8,
     -- mode = "center",

       
     
      vb:text{
       text = "Current Track",
      },--text
      
       vb:popup{
         id = "track name",
         items = get_renoise_track_names(),
         value = renoise.song().selected_track_index,
         -- text = string.sub(song.selected_track.name, 1, 30), --track name truncated to 25chars
         width = 126,
         notifier = function(value)
                      --change track_selection to match what the user chooses in the popup
                      renoise.song().selected_track_index = value
                    end
       }, --track name
       
      --  margin = 1,
     
       
     
       vb:text{
        text = "Mode",
       },--text
      
      
     vb:row{--INVERSE BUTTON AND "A" BUTTON
       vb:button{
         id = "Inverse",
         text = "INVERSE",-- options.selected_gain_mode.value,
         width = 108,
         notifier = function(value)
                      --change the mode and accordingly change the buttons appearance to reflect, current track mode or inverse mose
                      if options.selected_gain_mode.value == "Inverse" then
                        options.selected_gain_mode.value = "Current"
                        vb.views["auto"].active = false
                      elseif options.selected_gain_mode.value == "Current" then
                        options.selected_gain_mode.value = "Inverse"
                        vb.views["auto"].active = true
                      end
                      --add third mode here
                                             
                      if options.selected_gain_mode.value == "Current" then
                        vb.views["Inverse"].text = "CURRENT"
                        vb.views["Inverse"].color =  COLOR_YELLOW
                      else
                        vb.views["Inverse"].text = "INVERSE"
                        vb.views["Inverse"].color =  COLOR_GREY
                      end
                    end
        }, -- INVERSE button
        
        vb:button{
          text = "A",

          id = "auto",
          notifier = function()
                       if options.auto_limit_enabled.value == true then
                         options.auto_limit_enabled.value = false
                         vb.views["auto"].color = COLOR_GREY
                       else
                         options.auto_limit_enabled.value = true
                         vb.views["auto"].color = COLOR_ORANGE
                       end
                     end,
         },--"A" button
      },--row
      vb:row{
       vb:text{
        text = "Gain                ",
       },
       vb:text{
        text = "",
        width = 52,
        id = "post gain txt",
       },
       
      },--text
      vb:column{ 
        style = "group",
        margin = 4,
       
       vb:row{
         vb:column{
        
           vb:button{
             text = "+ 1 dB ",
             width = 60,
             height = 34,
             id = "increase 1dB",
             color = COLOR_GREY,
             notifier = function()
             
                         if options.g_set_gain_buttons_to_half.value == false then  
                           --arg 1: selected_track fader,arg 2: all other faders
                           increment_gain_button("1.00 dB","-1.00 dB")
                         else
                           increment_gain_button("0.50 dB","-0.50 dB")
                         end
                         
                       end,
            },--button
           
            vb:button{
             text = "- 1 dB ",
             width = 60,
             height = 34,
             id = "decrease 1dB",
             color = COLOR_GREY,
             notifier = function()
                          
                          if options.g_set_gain_buttons_to_half.value == false then  
                            --arg 1: selected_track fader,arg 2: all other faders
                            increment_gain_button("-1.00 dB","1.00 dB")
                          else
                            increment_gain_button("-0.50 dB","0.50 dB")
                          end
                        end,
            },--button
          },--vertical aligner
          
          vb:column{
           
            vb:button{
             text = "+ 0.2dB",
             width = 60,
             height = 34,
             id = "increase 0.2dB",
             color = COLOR_GREY,
             notifier = function()
             
                         if options.g_set_gain_buttons_to_half.value == false then 
                           --arg 1: selected_track fader,arg 2: all other faders
                           increment_gain_button("0.20 dB","-0.20 dB")
                         else
                           increment_gain_button("0.10 dB","-0.10 dB")
                         end
                       end,
            },--button
           
            vb:button{
             text = "- 0.2dB",
             id = "decrease -0.2dB",
             color = COLOR_GREY,
             width = 60,
             height = 34,
             notifier = function()
                          
                          if options.g_set_gain_buttons_to_half.value == false then 
                            --arg 1: selected_track fader,arg 2: all other faders
                            increment_gain_button("-0.20 dB","0.20 dB")
                          else
                            increment_gain_button("-0.10 dB","0.10 dB")
                          end
                        end,
            },--button
          },--row
          
         },
         --checkbox to set gain buttons to 1/2 value
         vb:row{

          vb:checkbox{--sets the main gain buttons to half their default value
           value = options.g_set_gain_buttons_to_half.value,
           notifier = function(value)
                        --set the global 
                        if value == true then
                          options.g_set_gain_buttons_to_half.value = true
                          --update button text
                          vb.views["increase 1dB"].text = "+ 0.5dB "
                          vb.views["decrease 1dB"].text = "- 0.5dB "
                          vb.views["increase 0.2dB"].text = "+ 0.1dB"
                          vb.views["decrease -0.2dB"].text = "- 0.1dB"
                          
                        else
                          options.g_set_gain_buttons_to_half.value = false
                          --update button text
                          vb.views["increase 1dB"].text = "+ 1 dB "
                          vb.views["decrease 1dB"].text = "- 1 dB "
                          vb.views["increase 0.2dB"].text = "+ 0.2dB"
                          vb.views["decrease -0.2dB"].text = "- 0.2dB"
                        end
                        
                      end
          
          },
          vb:text{
           text = "Fine",
          },
         },
        },
        --------------------------- 

         vb:text{
          text = " All Faders      Headroom",
         },--text
         
         -- All +/- row
         vb:row{
      
           vb:column{
            margin = 4,
            
            vb:button{
             text = "+",
             width = 58,
             height = 20,
             id = "All + 1dB",
             color = COLOR_GREY,
             notifier = function(value)
                         
                          local song = renoise.song()                                                
                          --loop all tracks and change volumes
                          for track = 1, song.sequencer_track_count do
                            --only apply to sequencer tracks that are not on -INF dB
                            if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
                               (song:track(track).postfx_volume.value_string ~= "-INF dB") then
                              -- minus a dB on fader
                              song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,"+1.00 dB")
                            end 
                          end
                          --reset global flag for next run
                          fader_yellow_flagged = false
                        end, 
          
            },--button
            
            vb:button{
             text = "-",
             width = 58,
             height = 20,
             id = "All - 1dB",
             color = COLOR_GREY,
             notifier = function(value)
                       
                         local song = renoise.song()                                                
                         --loop all tracks and change volumes
                         for track = 1, song.sequencer_track_count do
                           --only apply to sequencer tracks that are not on -INF dB
                           if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
                              (song:track(track).postfx_volume.value_string ~= "-INF dB") then
                             -- add a dB on fader
                             song:track(track).postfx_volume.value_string = add_value_strings(song:track(track).postfx_volume.value_string,"-1.00 dB")
                           end 
                         end
                         --reset global flag for next run
                         fader_yellow_flagged = false
                       end, 
  
            },--button
          },--vertical aligner (+/- buttons)
          
          vb:column{
           margin = 4,
          --headroom readout
           vb:textfield{
            id = "headroom dB",
            width = 55,
            text = get_headroom_from_highest_fader()
           },
           
           vb:row{
             margin = 1,
              vb:button{ --spacer
                text = "G",
                height = 20,
                id = "G button",
                notifier = function()
                             renoise.song().selected_track_index = get_highest_fader_index()
                           end
               },
             
               vb:button{
                text = "View",
                height = 20,
                notifier = function()
                             --if mixer not visible then go there else go to pattern editor
                             if not (renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_MIXER) then
                               renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
                             else
                                renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
                             end
                           end
             },--button
           },--button column
         }, 
       },--all +/- row
     }--end of vertical aligner (and dialog content)
  ------------------------------------------------------ 

 
  --check for faders that are close to max (used) and set button colors if needed to warn of high faders
  -------------------------------------------------------------------
  local song = renoise.song()                                                
  --loop all tracks and change volumes
  for track = 1, song.sequencer_track_count do
    --only apply to sequencer tracks that are not on -INF dB
    if (song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER) and
       (song:track(track).postfx_volume.value_string ~= "-INF dB") then --weed out as -INF wont be converted to number
       --check if we are getting close to fader max on current track (in loop)
       check_if_close_to_fader_max(track)
    end 
  end
  --reset global flag for next run of-- check_if_close_to_fader_max()
  fader_yellow_flagged = false
  fader_red_flagged = false
  
  --set the inverse button as may be showing incorrectly
  if options.selected_gain_mode.value == "Current" then
    vb.views["Inverse"].text = "CURRENT"
    vb.views["Inverse"].color =  COLOR_YELLOW
    vb.views["auto"].active = false
  else
    vb.views["Inverse"].text = "INVERSE"
    vb.views["Inverse"].color =  COLOR_GREY
    vb.views["auto"].active = true
  end
  
  --set the "A" button color to show if auto fader reduction mode is enabled
  if options.auto_limit_enabled.value == true then
    vb.views["auto"].color  = COLOR_ORANGE
  else 
    vb.views["auto"].color  = COLOR_GREY
  end
  
  --set text on main buttons depending on the state of the checkbox
  if options.g_set_gain_buttons_to_half.value == true then
    --update button text
    vb.views["increase 1dB"].text = "+ 0.5dB "
    vb.views["decrease 1dB"].text = "- 0.5dB "
    vb.views["increase 0.2dB"].text = "+ 0.1dB"
    vb.views["decrease -0.2dB"].text = "- 0.1dB"
  else
    --update button text
    vb.views["increase 1dB"].text = "+ 1 dB "
    vb.views["decrease 1dB"].text = "- 1 dB "
    vb.views["increase 0.2dB"].text = "+ 0.2dB"
    vb.views["decrease -0.2dB"].text = "- 0.2dB"
  end
  
  --------------------------------------------------------------------

  --update headroom and warning GUI colors on "-" button
  get_headroom_from_highest_fader()

  --------------
  --key Handler
  --------------
  local function my_keyhandler_func(dialog,key)
  
     --toggle lock focus hack, allows pattern ed to get key input
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
     
     
     return key
     --[[--if escape pressed then close the dialog else return key to renoise
     if not (key.modifiers == "" and key.name == "esc") then
        return key
     else
       dialog:close()
     end--]]
  end     
      
  --Initialise Script dialog
  --------------------------
  my_dialog = renoise.app():show_custom_dialog("Mix Balancer", dialog_content,my_keyhandler_func)   
  --------------------------------------------    
  --close dialog function ON NEW SONG
  --------------------------------------------
  local function closer(d)
    my_dialog = nil    
    if d and d.visible then
      d:close()
    end
  end
      
  -- Add a new timer to call timer function
  if not renoise.tool():has_timer(timer_function) then
    renoise.tool():add_timer(timer_function,50)
  end
  --call timer to update gui on opening (saves lag)
  timer_function()
  
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
end--end of main()







