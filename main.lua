----------------------------------------------------------------------
--preferences
----------------------------------------------------------------------
local options = renoise.Document.create {
  auto_max_enabled = false,
  auto_max_mixer_device_enabled = false
}
renoise.tool().preferences = options
--options files need to be accessed via 'options.variable.value'
--i.e: 
--local auto_max_boolean = options.auto_max_enabled.value

--"keybinding
-------------
renoise.tool():add_keybinding {
  name = "Global:Tools:`AMX` Minimise All Devices Current Track",  
  invoke = function() collapse_all_devices()
  end  
}
---------------------------------
--menu registration on DSP Device
---------------------------------
--menu check/tick for user to enable tool
-----------------------------
renoise.tool():add_menu_entry {
  name = "DSP Device:Auto Maximize Selected Device:Single Operation",
  selected = function() return options.auto_max_enabled.value end,
  invoke = function() 
    options.auto_max_enabled.value = not options.auto_max_enabled.value
    options.auto_max_mixer_device_enabled.value = false
  end
}
--alternative mode check/tick
-----------------------------
renoise.tool():add_menu_entry {
  name = "DSP Device:Auto Maximize Selected Device:Collapse When Mixer Device Chosen",
  selected = function() return options.auto_max_mixer_device_enabled.value end,
  invoke = function() 
    options.auto_max_mixer_device_enabled.value = not options.auto_max_mixer_device_enabled.value
    options.auto_max_enabled.value = false
  end
}

--keyboard shortcut fn
-------------------------------------------
--collapse all the devices in current track
-------------------------------------------
function collapse_all_devices()  
  --tracks
  local tracks = renoise.song().tracks
  --loop
  for track = 1,#tracks do
     -- from 2 so as not to try to minimize the mixer device
    for i = 2,#tracks[track].devices do
       tracks[track].devices[i].is_maximized = false 
    end
  end
end
----
----------------------------------------------------------------------
--functions that caollapse relevant non-selected devices
----------------------------------------------------------------------
----------------------------------------------------
function maximise_selected_dev_collapse_all_others()
----------------------------------------------------
  --song object
  local song = renoise.song()
  local selected_track = song.selected_track
  local selected_device_index = song.selected_track_device_index
  
  --a device selected?
  if (selected_device_index ~= 0) then    
    --from 2 so as not to try to minimize the mixer device
    for i = 2,#selected_track.devices do
      if (i == selected_device_index) then
        selected_track.devices[i].is_maximized = true
      else
        selected_track.devices[i].is_maximized = false 
      end
    end
  end
end

--function colapses all devices when mixer devices is selected
--otherwise expands any device you select
-----------------------------------------
function collapse_all_devs_except_mixer()
-----------------------------------------
  --song object
  local song = renoise.song()
  local selected_track = song.selected_track
  local selected_device_index = song.selected_track_device_index
 
  --mixer device selected so collapse all
  if selected_device_index == 1 then
    --loop from 2 so as not to try to minimize the mixer device
    for i = 2,#selected_track.devices do
      selected_track:devices(i).is_maximized = false 
    end
  elseif selected_device_index > 1 then
    selected_track:devices(selected_device_index).is_maximized = true
  end
end

--selected device notifier calls main()
---------------
function main()
---------------
  --single click operation enabled in menu
  if (options.auto_max_enabled.value) then 
    maximise_selected_dev_collapse_all_others()
  end
  --mixer device selection enabled in menu
  if (options.auto_max_mixer_device_enabled.value) then 
    collapse_all_devs_except_mixer()
  end
end

-----------
--notifiers
-----------
----------------
function start()
----------------  
  renoise.song().selected_track_observable:add_notifier(main) 
  renoise.song().selected_track_device_observable:add_notifier(main)
end  
--new song notifier makes sure tool starts with aeach new song
renoise.tool().app_new_document_observable:add_notifier(start)





