--KNOWN BUG:  IF reference track is deleted manally while GUI is open and mono is enabled,  it takes two presses of mono button to re-initialise mono state (not major)

--keybinds

require "functions"

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Toggle Reference Track", 
  invoke = function()toggle_ref_track() end   
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Toggle Reference Track With Selected Track", 
  invoke = function()toggle_ref_track_and_selected_track() end   
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Go To Reference Track", 
  invoke = function()go_to_ref_track() end   
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Adjust Song To Selected Sample Length", 
  invoke = function()extend_song_to_sample_length() end   
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Toggle Autoseek On Selected Sample", 
  invoke = function()enable_autoseek() end   
}

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Create Reference Track", 
  invoke = function()
             local song = renoise.song()
             local master_idx = (song.sequencer_track_count+1)
             --where is the master is routed?
             local mst_route = renoise.song().tracks[master_idx].output_routing
             --call function
             create_reference_track(mst_route) 
           end   
}


--Toggle Mono Mix
renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Toggle Mix Output Stereo To Mono", 
  invoke = function()mono_tog() end  
}
------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:`TRT` Reference Track GUI", 
  invoke = function()main() end   
}

--global
bypass_timer = false
TOOL_NAME = "Toggle Ref. Track"

--colours
--e.g. For changing vb.views["button_x"].color when states change
COLOR_GREY = {40,40,40}
COLOR_ORANGE ={0xFF,0x66,0x00}
COLOR_YELLOW = {0xE0,0xE0,0x00}
COLOR_BLUE = {0x50,0x40,0xE0}  
COLOR_RED = {0xEE,0x10,0x10}
COLOR_GREEN = {0x20,0x99,0x20}

--to test `vb.views["button_x"].color` we need to check the first entry of the color table
--i.e. if vb.views["button_x"].color[1] == COLOR_GREY_FLAG
COLOR_GREY_FLAG = 40
COLOR_ORANGE_FLAG = 0xFF
COLOR_YELLOW_FLAG = 0xE0
COLOR_BLUE_FLAG = 0x50 
COLOR_RED_FLAG = 0xEE
COLOR_GREEN_FLAG = 0x20

--global variables for gui
local my_dialog = nil 
local vb = nil

--LOW/MID/HIGH button cutoff frequencies (not used in code as possible Lua rounding errors? )

--LOW_CUTOFF = 0.125
--MID_CUTOFF = 0.348999798
--HIGH_CUTOFF = 0.500999689

local low_filter_preset = 
[[
<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="11">
  <DeviceSlot type="DigitalFilterDevice">
    <IsMaximized>true</IsMaximized>
    <OversamplingFactor>2x</OversamplingFactor>
    <Model>Chebyshev 8n</Model>
    <Type>
      <Value>0.0</Value>
    </Type>
    <Cutoff>
      <Value>0.125</Value>
    </Cutoff>
    <Q>
      <Value>0.0</Value>
    </Q>
    <Ripple>
      <Value>0.0</Value>
    </Ripple>
    <Inertia>
      <Value>0.0078125</Value>
    </Inertia>
    <ShowResponseView>true</ShowResponseView>
    <ResponseViewMaxGain>18</ResponseViewMaxGain>
  </DeviceSlot>
</FilterDevicePreset>]]

local mid_filter_preset = 
[[
<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="11">
  <DeviceSlot type="DigitalFilterDevice">
    <IsMaximized>true</IsMaximized>
    <OversamplingFactor>2x</OversamplingFactor>
    <Model>Chebyshev 8n</Model>
    <Type>
      <Value>1.0</Value>
    </Type>
    <Cutoff>
      <Value>0.348999798</Value>
    </Cutoff>
    <Q>
      <Value>0.227999985</Value>
    </Q>
    <Ripple>
      <Value>0.0</Value>
    </Ripple>
    <Inertia>
      <Value>0.0078125</Value>
    </Inertia>
    <ShowResponseView>true</ShowResponseView>
    <ResponseViewMaxGain>18</ResponseViewMaxGain>
  </DeviceSlot>
</FilterDevicePreset>]]


local high_filter_preset = 
[[
<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="11">
  <DeviceSlot type="DigitalFilterDevice">
    <IsMaximized>true</IsMaximized>
    <OversamplingFactor>2x</OversamplingFactor>
    <Model>Chebyshev 8n</Model>
    <Type>
      <Value>3</Value>
    </Type>
    <Cutoff>
      <Value>0.500999689</Value>
    </Cutoff>
    <Q>
      <Value>0.227999985</Value>
    </Q>
    <Ripple>
      <Value>0.0</Value>
    </Ripple>
    <Inertia>
      <Value>0.0078125</Value>
    </Inertia>
    <ShowResponseView>true</ShowResponseView>
    <ResponseViewMaxGain>18</ResponseViewMaxGain>
  </DeviceSlot>
</FilterDevicePreset>]]

--unused to change filter types on LOW?MID/HIGH buttons
--[[
local g_filter_type = "Chebyshev 8n"
available_filter_types = {"Biquad","Butterworth 4n","Butterworth 8n","Chebyshev 4n","Chebyshev 8n"}

local function substitute_filter_type(num)
  local filter_type =nil
  if num == 1 then filter_type = available_filter_types[1]
    elseif num == 2 then filter_type = available_filter_types[2]
    elseif num == 3 then filter_type = available_filter_types[3]
    elseif num == 4 then filter_type = available_filter_types[4]
    elseif num == 5 then filter_type = available_filter_types[5]
  end


  --substitute new filter typr in
  low_filter_preset = string.gsub(low_filter_preset,g_filter_type,filter_type)
  mid_filter_preset = string.gsub(mid_filter_preset,g_filter_type,filter_type)
  high_filter_preset = string.gsub(high_filter_preset,g_filter_type,filter_type)
  
  g_filter_type = filter_type
end

substitute_filter_type(4)
--]]






--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
local function status(message)
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
end
--------------------------------------------------------------------------------
--gets track index for reference track --identified by reference gainer 
--retruns track index or nil
--------------------------------------------------------------------------------
local function get_ref_track_index()
------------------------------------
  local song = renoise.song()
  for track = 1, #song.tracks do
    for devs = 2, #song.tracks[track].devices do
      if song.tracks[track].devices[devs].display_name == "Reference Gainer" then
        return track --return ref track index
      end
    end
  end
  return nil --return no ref found
end


--main gui function
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
  
   
  -------------------------------------------------------------------------------------------
  --GUI
  -------------------------------------------------------------------------------------------  
  local dialog_content = 
    vb:vertical_aligner {
      margin = 10,
     
    --text line 1 --spacer
    -------------- 
    vb:text{
           text = "",
           id = "wav name",
          },
      --ROW 1
      ---------
      vb:horizontal_aligner{
        mode = "center",
        
        vb:button { 
           width = 80,
           height = 30,
           color = COLOR_GREY,
           text = "Create Reference Track:",
           id = "create ref btn",
           notifier = function()
                          
                         local song = renoise.song()  
                         
                         --1) Dual function button changes to "Go To Reference Track" after one is created
                         ---------------------------------------------------------------------------------
                         if vb.views["create ref btn"].text == "Go To Reference Track" then
                           song.selected_track_index = get_ref_track_index()
                           return
                         end
                         --2)Create ref track
                         --------------------
                         local master_idx = (song.sequencer_track_count+1)
                        --where is the master is routed?
                         local mst_route = renoise.song().tracks[master_idx].output_routing
                         --call function
                         create_reference_track(mst_route)
                         --update play btn text
                         vb.views["play ref"].text = "REF PLAYING"
                         
                         --housekeeping so buttons are refreshed back to default if gui is still open when ref track deleted manually in renoise
                         if vb.views["mono button"].color[1] == COLOR_RED_FLAG then
                           mono_tog() --toggle mono back to default state
                           vb.views["mono button"].color = COLOR_GREY
                         end
                                                  --reset LOW/MID/HIGH
                         vb.views["low button"].color = COLOR_GREY
                         vb.views["mid button"].color = COLOR_GREY
                         vb.views["high button"].color = COLOR_GREY

                       end
            },--button 1
           },--row (horizontal_aligner{) 1
            
            --text line shows instruction on initial screen
            -------
            vb:text{
               text = "",
               id = "start text", 
             },
             
         --ROW 2
         --------
         --controls column --this whole columns contains lower part of GUI and gets hidden until erf track is present
         vb:column{
           id = "controls", 
            
           vb:row{
             vb:text{
               text = "Toggle:                   Single Trk:"--text info row
             },
             vb:checkbox{
              id =  "toggle current box",
              notifier = function(value)
                           local song = renoise.song()
                           if (vb.views["play ref"].color[1] == COLOR_GREY_FLAG) then
                             local selected_track = renoise.song().tracks[song.selected_track_index] 
                             
                           --[[
                             --value false so solo track enabled
                             --sometimes a track will return soloed when really it`s not (API bug? has been reported)
                             --so we need to loop and flag other unmuted sequencer tracks
                             local not_solo_flag = false
                             --loop tracks    
                             for track = 1,#song.tracks do
                               --skip selected track
                               if track ~= song.selected_track_index then
                                 --make sure sequencer track
                                 if song:track(track).type == renoise.Track.TRACK_TYPE_SEQUENCER then
                                   --see if unmuted
                                   if song:track(track).mute_state == renoise.Track.MUTE_STATE_ACTIVE then
                                     not_solo_flag = true
                                   --  print("true")
                                     break
                                   end
                                 end   
                               end
                             end--]]
                             
                             --value true so solo track enabled
                             --sometimes a track will return soloed when really it`s not
                             -- (API bug? has been reported)
                             
                             --if checkbox ticked then solo current track
                             if (value == true) then 
                                selected_track:mute() --hack to make sure solos correctly
                                selected_track:solo()
                               return
                             end
                             
                             --if checkbox un-ticked then unmute all tracks
                             if (value == false) then
                              for track = 1,#song.tracks do
                                if song:track(track).type ~= renoise.Track.TRACK_TYPE_MASTER then
                                  song:track(track).mute_state = renoise.Track.MUTE_STATE_ACTIVE
                                end
                               end
                             end
                           end
                         end
              },
             }, --ROW 2
           
           --ROW 3----
           ----------- 
           vb:row{
             vb:button { 
              width = 160,
              height = 48,
              color = COLOR_GREY,
              text = "SONG PLAYING",
              id = "play ref",
              notifier = function()
                           --toggle the reference track
                           if vb.views["toggle current box"].value == false then
                             toggle_ref_track()
                           else
                             toggle_ref_track_and_selected_track()
                           end
                           
                           --check if active or not
                           local song = renoise.song()
                           local ref_track_idx = get_ref_track_index()
                           --return if no ref track found
                           if ref_track_idx == nil then
                             return
                           end
                           --get ref track object
                           local ref_track = song:track(ref_track_idx)
                          
                          for devs = 2, #ref_track.devices do
                            --find toggle gainer
                            if ref_track.devices[devs].display_name == "Reference Gainer" then 
                              --1): REF TRACK PLAYING
                              if ref_track.devices[devs].is_active ~= true then
                                vb.views["play ref"].color = COLOR_GREEN
                                vb.views["play ref"].text = "REF PLAYING"
                                return
                              else  --2):  REF TRACK MUTED
                                vb.views["play ref"].color = COLOR_GREY
                                vb.views["play ref"].text = "SONG PLAYING"
                                return
                              end
                            end
                          end 
                        end
              },
             },--row 3
             
             --text line above filter buttons
             vb:text{
               text = "Focus:"
              },
             
            --ROW 4---- Filter buttons LOW/MID/HIGH
            -----------
            vb:row{
             vb:button{
                width = 54,
                height = 30,
                text = "LOW",
                id = "low button",
                color = COLOR_GREY,
                notifier = function()
                            local song = renoise.song()
                            local master_index = #song.tracks - song.send_track_count
                            local master_track = song:track(master_index)
                            
                            --find reference track and master track
                            local ref_track_index = false
                            for track = 1, #song.tracks do
                              for devs = 2, #song:track(track).devices do
                                --find toggle gainer
                                if song:track(track).devices[devs].display_name == "Reference Gainer" then 
                                  ref_track_index = track
                                  break
                                end
                              end
                            end
                            --return if no reference track is found
                            if ref_track_index == false then
                              status("No Reference track found")
                              return
                            end
                            
                            local ref_track = song:track(ref_track_index)
                            local ref_filter = nil
                            --1) loop backwards through ref track devices to find filter
                            for devs = 2, #ref_track.devices do
                              --find toggle gainer
                              if ref_track.devices[devs].display_name == "Reference Filter" then 
                                ref_filter = ref_track.devices[devs]
                                break
                              end
                            end
                            
                            local mas_ref_filter = nil
                            --2) loop backwards through master track devices to find filter
                            for devs = 2, #master_track.devices do
                              --find toggle gainer
                              if master_track.devices[devs].display_name == "Reference Filter" then 
                                mas_ref_filter = master_track.devices[devs]
                                break
                              end
                            end
                            
                            --add filter if not present
                             --add filter at end of ref track if not present
                            if ref_filter == nil then
                              ref_filter = ref_track:insert_device_at("Audio/Effects/Native/Digital Filter", #ref_track.devices + 1 )
                              ref_filter.display_name = "Reference Filter"
                              ref_filter.is_active = false --will toggle back on next
                            end
                            
                            --add master filter if not present
                             --add filter at end of ref track if not present
                            if mas_ref_filter == nil then
                              mas_ref_filter = master_track:insert_device_at("Audio/Effects/Native/Digital Filter", #master_track.devices + 1)
                              mas_ref_filter.display_name = "Reference Filter"
                              mas_ref_filter.is_active = false --will toggle back on next
                            end
                            
                           --toggle state
                           if vb.views["low button"].color[1] == COLOR_GREY_FLAG then
                              vb.views["low button"].color = COLOR_ORANGE
                              vb.views["mid button"].color = COLOR_GREY
                              vb.views["high button"].color = COLOR_GREY
                              ref_filter.is_active = true
                              mas_ref_filter.is_active = true
                           else
                             vb.views["low button"].color = COLOR_GREY
                             vb.views["mid button"].color = COLOR_GREY
                              vb.views["high button"].color = COLOR_GREY
                             ref_filter.is_active = false
                             mas_ref_filter.is_active = false
                           end
                            
                            --set to low filter preset
                            ref_filter.active_preset_data = low_filter_preset
                            mas_ref_filter.active_preset_data = low_filter_preset

                           end
                },
              
              vb:button{
                width = 54,
                height = 30,
                text = "MID",
                id = "mid button",
                color = COLOR_GREY,
                notifier = function()
                              local song = renoise.song()
                              local master_index = #song.tracks - song.send_track_count
                              local master_track = song:track(master_index)
                              
                              --find reference track
                              local ref_track_index = false
                              for track = 1, #song.tracks  do
                                for devs = 2, #song:track(track).devices do
                                  --find toggle gainer
                                  if song:track(track).devices[devs].display_name == "Reference Gainer" then 
                                    ref_track_index = track
                                    break
                                  end
                                end
                              end
                              --return if no reference track is found
                              if ref_track_index == false then
                                status("No Reference track found")
                                return
                              end
                              
                              --1) find ref filter
                              local ref_track = song:track(ref_track_index)
                              local ref_filter = nil
                              --loop backwards through devices to find filter
                              for devs = 2, #ref_track.devices do
                                --find toggle gainer
                                if ref_track.devices[devs].display_name == "Reference Filter" then 
                                  ref_filter = ref_track.devices[devs]
                                  break
                                end
                              end
                              
                               local mas_ref_filter = nil
                              --2) loop backwards through master track devices to find filter
                              for devs = 2, #master_track.devices do
                                --find toggle gainer
                                if master_track.devices[devs].display_name == "Reference Filter" then 
                                  mas_ref_filter = master_track.devices[devs]
                                  break
                                end
                              end
                              
                               --add filter at end of ref track if not present
                              if ref_filter == nil then
                                ref_filter = ref_track:insert_device_at("Audio/Effects/Native/Digital Filter", #ref_track.devices+1)
                                ref_filter.display_name = "Reference Filter"
                                ref_filter.is_active = false --will toggle back on next
                              end
                              
                              --add master filter if not present
                             --add filter at end of ref track if not present
                            if mas_ref_filter == nil then
                              mas_ref_filter = master_track:insert_device_at("Audio/Effects/Native/Digital Filter", #master_track.devices+1)
                              mas_ref_filter.display_name = "Reference Filter"
                              mas_ref_filter.is_active = false --will toggle back on next
                            end
                              
                             --toggle state
                             if vb.views["mid button"].color[1] == COLOR_GREY_FLAG then
                                vb.views["mid button"].color = COLOR_ORANGE
                                vb.views["low button"].color = COLOR_GREY
                                vb.views["high button"].color = COLOR_GREY
                                ref_filter.is_active = true
                                mas_ref_filter.is_active = true
                             else
                               vb.views["mid button"].color = COLOR_GREY
                               vb.views["low button"].color = COLOR_GREY
                                vb.views["high button"].color = COLOR_GREY
                               ref_filter.is_active = false
                               mas_ref_filter.is_active = false
                             end
                              
                              --set to mid filter preset
                              ref_filter.active_preset_data = mid_filter_preset
                              mas_ref_filter.active_preset_data = mid_filter_preset 
                           end
                },
               
               vb:button{
                width = 54,
                height = 30,
                text = "HIGH",
                id = "high button",
                color = COLOR_GREY,
                notifier = function()
                             local song = renoise.song()
                             local master_index = #song.tracks - song.send_track_count
                             local master_track = song:track(master_index)
                            
                            --find reference track
                            local ref_track_index = false
                            for track = 1, #song.tracks  do
                              for devs = 2, #song:track(track).devices do
                                --find toggle gainer
                                if song:track(track).devices[devs].display_name == "Reference Gainer" then 
                                  ref_track_index = track
                                  break
                                end
                              end
                            end
                            --return if no reference track is found
                            if ref_track_index == false then
                              status("No Reference track found")
                              return
                            end
                            
                            --1)
                            local ref_track = song:track(ref_track_index)
                            local ref_filter = nil
                            --loop backwards through devices to find filter
                            for devs = 2, #ref_track.devices do
                              --find toggle gainer
                              if ref_track.devices[devs].display_name == "Reference Filter" then 
                                ref_filter = ref_track.devices[devs]
                                break
                              end
                            end
                            
                            local mas_ref_filter = nil
                            --2) loop backwards through master track devices to find filter
                            for devs = 2, #master_track.devices do
                              --find toggle gainer
                              if master_track.devices[devs].display_name == "Reference Filter" then 
                                mas_ref_filter = master_track.devices[devs]
                                break
                              end
                            end
                            
                             --add filter if not present
                             --add filter at end of ref track if not present
                            if ref_filter == nil then
                              ref_filter = ref_track:insert_device_at("Audio/Effects/Native/Digital Filter", #ref_track.devices+1)
                              ref_filter.display_name = "Reference Filter"
                              ref_filter.is_active = false --will toggle back on next
                            end
                            
                             --add master filter if not present
                             --add filter at end of ref track if not present
                            if mas_ref_filter == nil then
                              mas_ref_filter = master_track:insert_device_at("Audio/Effects/Native/Digital Filter", #master_track.devices+1)
                              mas_ref_filter.display_name = "Reference Filter"
                              mas_ref_filter.is_active = false --will toggle back on next
                            end
                            
                           --toggle state
                           if vb.views["high button"].color[1] == COLOR_GREY_FLAG then
                              vb.views["high button"].color = COLOR_ORANGE
                              vb.views["mid button"].color = COLOR_GREY
                              vb.views["low button"].color = COLOR_GREY
                              ref_filter.is_active = true
                              mas_ref_filter.is_active = true
                           else
                             vb.views["high button"].color = COLOR_GREY
                             vb.views["mid button"].color = COLOR_GREY
                              vb.views["low button"].color = COLOR_GREY
                             ref_filter.is_active = false
                             mas_ref_filter.is_active = false
                           end
                            
                            --set to high filter preset
                            ref_filter.active_preset_data = high_filter_preset
                            mas_ref_filter.active_preset_data = high_filter_preset  
                           end
                },
              },--row 4
           --[[   
           vb:row{ --debug
             vb:popup{
               items = available_filter_types,
               width = 120,
               notifier = function(value)
                            substitute_filter_type(value)  
                          end
             }
           },--]]
              
              vb:text{
               text = "Ref Track Volume:"--             Mono:",
              },
              
              
            --ROW 5---- slider and mono button
            ----------- 
            vb:row{
              vb:slider{
                width = 138,
                height = 20,
                min = renoise.song().tracks[1].postfx_volume.value_min,
                max = renoise.song().tracks[1].postfx_volume.value_max,
                value = 1,
                id = "volume slider",
                notifier = function(value)
                             bypass_timer = true
                             local song = renoise.song
                             renoise.song().tracks[1].postfx_volume.value = value
                             bypass_timer = false
                           end
              
              },
              
            -- mono button
          --  vb:row{
              vb:button{
                width = 20,
                height = 20,
                text = "M",
                id = "mono button",
                notifier = function(value)
                             mono_tog()
                             --run timer to update GUi
                             timer()
                           end
               },
            -- },
             },
            },--controls column
           } --Vertical aligner --END of GUI content
  --------------------------------------------------
  --------------------------------------------------
         
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

 
  --add timer to fire once every 80ms
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
      -- remove_notifiers()
      if renoise.tool():has_timer(timer) then
        renoise.tool():remove_timer(timer)
      end
    end
  end
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  -------------------------------------------------------------------------------
  
  --first run of timer
   timer()
end
-----------------------------------------------
----------end of main()------------------------
-----------------------------------------------

function timer()

  if bypass_timer == true then
    return
  end
  
  local song = renoise.song()

  local ref_track_idx = get_ref_track_index()
  
  --CASE NO REFERENCE TRACK FOUND
  if ref_track_idx == nil then
    --clear wav-name text
    vb.views["wav name"].text = ""
    --show help text
    vb.views["start text"].text =
    "   Load a ref .wav in Inst. box"
    --make sure create button is active (Also doubles as `Go To Reference Track` button and can be made inactive in that state, i.e. when ref track is selected)
    vb.views["create ref btn"].active = true
    --set start button to "Create Reference Track"
    vb.views["create ref btn"].text = "Create Reference Track"
    --hide main controls
    vb.views["controls"].visible = false
    --Delete Reference filter on master track
    local master_index = #song.tracks - song.send_track_count
    local master_track = song:track(master_index)
    
    for devs = #master_track.devices,2 ,-1 do
      if master_track.devices[devs].display_name == "Reference Filter" then
        master_track:delete_device_at(devs)
      end
    end
    
  --CASE REFERENCE TRACK IS FOUND
  else
    
    local ref_track = song:track(ref_track_idx)
   
    --Disable `Go To Reference Track` button if on reference track/ else enable
    if (song.selected_track_index == ref_track_idx) then
      vb.views["create ref btn"].text = "REF TRACK SELECTED"
     -- vb.views["create ref btn"].color = COLOR_GREEN
      vb.views["create ref btn"].active = false
    else
      vb.views["create ref btn"].text = "Go To Reference Track"
      vb.views["create ref btn"].color = COLOR_GREY
      vb.views["create ref btn"].active = true
    end
    
    ---UPDATE wav name text
    local ref_note_inst = ""
    --get ref .wav instrument slot index
    local ref_track_note_first_col = song:pattern(1):track(ref_track_idx):line(1):note_column(1)
    if ref_track_note_first_col.instrument_value ~= 255 then--255 is empty
      --get instrument name
      ref_note_inst = song:instrument(ref_track_note_first_col.instrument_value + 1).name
    end
    
    vb.views["wav name"].text = "     "..string.sub(ref_note_inst,1,21) 
    --remove help text
    vb.views["start text"].text = ""
    --show main controls
    vb.views["controls"].visible = true
    
    --REF IS ACTIVE AND PLAYING
    --set the color for the play button
    if song:track(ref_track_idx).name == "`REF` ACTIVE" then
      vb.views["play ref"].color = COLOR_GREEN
      --check if reference track is selected, disable button if single track toggle mode
      if (song.selected_track_index == ref_track_idx) and (vb.views["toggle current box"].value == true) then
        vb.views["play ref"].active = false
        vb.views["play ref"].text = "Can`t Toggle Ref With Itself"
      else --else play ref button back to normal
        vb.views["play ref"].active = true
        vb.views["play ref"].text = "REF PLAYING"
      end 
     
    
    else --REF IS INACTIVE (SONG PLAYING) 
      
      --check if reference track is selected, disable button if single track toggle mode
      if (song.selected_track_index == ref_track_idx) and (vb.views["toggle current box"].value == true) then
        vb.views["play ref"].active = false
        vb.views["play ref"].text = "Can`t Toggle Ref With Itself"
      else --else play ref button back to normal
        vb.views["play ref"].active = true
        vb.views["play ref"].text = "SONG PLAYING"
      end 
    
      vb.views["play ref"].color = COLOR_GREY
    end
    
    --check for state of filter (LOW,MID,HIGH)
    ------------------------------------------
    
    local ref_filter = nil
    --loop backwards through devices to find filter
    for devs = 2, #ref_track.devices do
      --find toggle gainer
      if ref_track:device(devs).display_name == "Reference Filter" then 
        ref_filter = ref_track:device(devs)
        break
      end
    end
    
     --find Mono Mix  device
    for devs = 2, #ref_track.devices do
      if (ref_track:device(devs).display_name == "Mono Mix") then 
        if (ref_track:device(devs).is_active == true) then
          vb.views["mono button"].color = COLOR_RED
          break
        else
          vb.views["mono button"].color = COLOR_GREY
          break
        end  
      end
    end
    
    --THESE Exact values didn`t work (rounding in Lua?) so ranges were done below instead to get filter cutoff values
   -- LOW_CUTOFF = 0.125
   -- MID_CUTOFF = 0.348999798
    --HIGH_CUTOFF = 0.500999689
     
     --If filter is found on reference track get its state/ preset and set the button colors accordingly
      
    if (ref_track ~= nil) and (ref_filter ~= nil) then
      if (ref_filter.parameters[2].value < 0.3) and (ref_filter.is_active) then--== LOW_CUTOFF then  --0.125  is low filter cutoff value
        vb.views["low button"].color = COLOR_ORANGE
      else
        vb.views["low button"].color = COLOR_GREY
      end
      if (ref_filter.parameters[2].value > 0.3) and (ref_filter.parameters[2].value < 0.4) and (ref_filter.is_active) then-- == MID_CUTOFF then
        vb.views["mid button"].color = COLOR_ORANGE
      else
       vb.views["mid button"].color = COLOR_GREY
      end
      if ref_filter.parameters[2].value > 0.4 and (ref_filter.is_active) then-- == HIGH_CUTOFF then
        vb.views["high button"].color = COLOR_ORANGE
      else
        vb.views["high button"].color = COLOR_GREY
      end
    end
    --update volume slider
    vb.views["volume slider"].value = ref_track.postfx_volume.value
  end
  


   --CASE DIALOG CLOSED
  ------------------------------------
  --remove timer when dialog is closed
  ------------------------------------
  if my_dialog and (my_dialog.visible == false) then
    --remove timer
    if renoise.tool():has_timer(timer) then
     renoise.tool():remove_timer(timer)
    end
    
    -----TIDY UP DEVICES THAT THE TOOL ADDED (FILTER AND MONO)---
    
    --get master track object
    local master_index = #song.tracks - song.send_track_count
    local master_track = song:track(master_index)
    
    --Delete Reference filter on master track
    for devs = #master_track.devices,2 ,-1 do
      if master_track.devices[devs].display_name == "Reference Filter" then
        master_track:delete_device_at(devs)
        break
      end
    end
    --Delete Mono Mix device on master
    for devs = 2, #master_track.devices do
      if (master_track:device(devs).display_name == "Mono Mix") then 
       master_track:delete_device_at(devs)
       break
      end
    end
    ---------------------------------------------
    --Delete Reference filter on ref treack track
    if ref_track_idx ~= nil then
      local ref_track = song:track(ref_track_idx)
      for devs = #ref_track.devices,2 ,-1 do
        if ref_track.devices[devs].display_name == "Reference Filter" then
          ref_track:delete_device_at(devs)
          break
        end
      end
    end
    --Delete Mono Mix device on ref
    if ref_track_idx ~= nil then
      local ref_track = song:track(ref_track_idx)
      for devs = 2, #ref_track.devices do
        if (ref_track:device(devs).display_name == "Mono Mix") then 
         ref_track:delete_device_at(devs)
         break
        end
      end
    end
    ---------------------------------------------
  end --end of dialog closed
end--end of timer
-------------------------------------------------
-------------------------------------------------
