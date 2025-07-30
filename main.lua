--TODO

--[[ --Vendor names
for i = 1,#renoise.song().tracks[1].available_device_infos do
  --print(renoise.song().tracks[1].available_device_infos[i].name)
end
--]]

TOOL_NAME = "VSTi From Menu"

--VSTiFromMenu.xrnx
require "Search GUI"
require "extra_shortcuts" 
require "show_doubled_devices"

--------------------------------------------------------------------------------
--helper function : custom status message --prefixes tool name and adds brackets 
--------------------------------------------------------------------------------
function status(message)
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
end


-- create preferences doc
--------------------------
options = renoise.Document.create {
  auto_open = false,
  auto_open_fx = false,
  only_show_unique_vst3 = false,

}
renoise.tool().preferences = options

------------------------------------------------------------------------
------------------------------------------------------------------------
--[1] Instrument Box Function --add_vsts_to_instrument_box()
------------------------------------------------------------------------
-- 1 of two functions called by app_new_document notifier
-------------------------------------
function add_vsts_to_instrument_box()
-------------------------------------

  --plugin infos from API
  --local rns_plugin_infos = renoise.song().instruments[1].plugin_properties.available_plugin_infos
  
  
  --make a deep copy of 'renoise.song().instruments[1].plugin_properties.available_plugin_infos'
  ---------------------------------
  local function deepCopy(original)
  ---------------------------------
    local copy = {}
    for k, v in pairs(original) do
      if type(v) == "table" then
        v = deepCopy(v)
      end
      copy[k] = v
    end
    return copy
  end
  ----
  --call fn to copy .plugin_properties.available_plugin_infos
  local rns_plugin_infos  = deepCopy(renoise.song().instruments[1].plugin_properties.available_plugin_infos)
 
  --we can now alphabetically sort this deep copied table with added function to table.sort()
  --we capitalise the short_name keys and compare them (output is case in-sensitive whichc is what we want)
  table.sort(rns_plugin_infos , function(a, b) return a.short_name:upper() < b.short_name:upper() end)  
 
  local no_of_vsts = #rns_plugin_infos
  
  
   
  --load vsti (instrument plugin) used in menu entry notifiers
  -------------------------------
  local function load_vsti(fn_no)
  -------------------------------
    local inst_index = renoise.song().selected_instrument_index
    renoise.song().instruments[inst_index].plugin_properties:load_plugin(rns_plugin_infos[fn_no].path)
    -- if auto_open then open GUI
    if (options.auto_open.value) then
      if renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_available then
        renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_visible = true
      end
    end
  end 
  ---
  
  local add_divider = "---"
  
  --loop to add all plug types to plug_inst_type{}
  local plug_inst_type = {}
  for i = 1,no_of_vsts do
    if  string.find(rns_plugin_infos[i].path , "VST3/") then
      plug_inst_type[i] = "VST3"
    elseif  string.find(rns_plugin_infos[i].path , "VST/") then
      plug_inst_type[i] = "VST" 
    elseif  string.find(rns_plugin_infos[i].path , "DSSI") then
      plug_inst_type[i] = "DSSI"
    elseif  string.find(rns_plugin_infos[i].path ,"AU") then
      plug_inst_type[i] = "AU"
    end
  end
  
    
  --first clear all VST3 Inst. menu entries if they are present
  --(needed when option is changed to show only unique VST3 and this whole function is recalled)
  ---------------------------------------------------------
  --remove all menu entries in instrument Box VST3 list
  for i = 1,no_of_vsts do
    local menu_entry = nil
    if plug_inst_type[i] == "VST3" then 
       
      if rns_plugin_infos[i].is_bridged then
        menu_entry = "Instrument Box:Load VST3..: * "..rns_plugin_infos[i].short_name
      else
        menu_entry = "Instrument Box:Load VST3..:"..rns_plugin_infos[i].short_name
      end
      --remove menu entry
      if renoise.tool():has_menu_entry(menu_entry) then
        -- remove entry
        renoise.tool():remove_menu_entry(menu_entry)
      end
    end
  end
  local inst_menu_option = add_divider.."Instrument Box:Load VST3..:Only Show Unique VST3 Plugs"           
  --remove this menu entry (or all get added below divider)
  if renoise.tool():has_menu_entry(inst_menu_option) then
    renoise.tool():remove_menu_entry(inst_menu_option)
  end
  -----------



  --remove plugs from the VST3 list that are present in the
  --VST2.4 list --updates the 'deep copied' and sorted table
  ---------------------------------------------
  local function remove_non_unique_vst3_plugs() 
  --------------------------------------------- 
    for i = 1,no_of_vsts do
      if plug_inst_type[i] == "VST3" then
        for j = 1,no_of_vsts do
          if plug_inst_type[j] == "VST" then
            if rns_plugin_infos[i].short_name == rns_plugin_infos[j].short_name then
              plug_inst_type[i] = ""
              --print(rns_plugin_infos[j].short_name)
              break
            end
          end
        end 
      end
    end
  end 
  ---
  --remove plugs doubled in vst3 menu if user specifies
  if options.only_show_unique_vst3.value == true then
    remove_non_unique_vst3_plugs() 
  end
  
  
  --NOW ADD ALL INSTRUMENT BOX MENU ENTRIES
  -----------------------------------------
  
  --Add VST3 (plugin) menu entries with loop
  ---------------------------------------------------
  if no_of_vsts > 0 then --check we have plugs to add 
    local menu_entry = ""
    for i = 1,no_of_vsts do
      if plug_inst_type[i] == "VST3" then 
        --is_bridged? 
        if rns_plugin_infos[i].is_bridged then
          menu_entry = "Instrument Box:Load VST3..: * "..rns_plugin_infos[i].short_name   
        else
          menu_entry = "Instrument Box:Load VST3..:"..rns_plugin_infos[i].short_name   
        end
         --add to menu 
        if not renoise.tool():has_menu_entry(menu_entry) then
            renoise.tool():add_menu_entry {
              name = menu_entry,
              invoke = function() load_vsti(i) end
            }
        end
      end
    end
  end
  
  
  --USER OPTION ENTRY IN VST3 MENU:
  --show unique VST3 plugs only option for 'remove_non_unique_vst3_plugs()' function above
  ------------------------------------
  
  --loop all menu locations
   local inst_menu_option = add_divider.."Instrument Box:Load VST3..:Only Show Unique VST3 Plugs" 
   if not renoise.tool():has_menu_entry(inst_menu_option) then
      -- add entries
      renoise.tool():add_menu_entry {
       name = inst_menu_option,
       selected = function() return options.only_show_unique_vst3.value end, 
       invoke = function()
                  --change options value
                  options.only_show_unique_vst3.value = not options.only_show_unique_vst3.value
                  --re-run whole functions to repopulate menus with or without duplicated vst2/3
                  --the called functions both check: options.only_show_unique_vst3.value
                  add_vsts_to_mixer_and_dsp_lane()
                  add_vsts_to_instrument_box()
                end
      }
    end
 

 
  --Add VST (plugin) menu entries with loop
  ---------------------------------------------------
  if no_of_vsts > 0 then --check we have plugs to add 
    local menu_entry = ""
    for i = 1,no_of_vsts do
      if plug_inst_type[i] == "VST" then 
        --is_bridged? 
        if rns_plugin_infos[i].is_bridged then
          menu_entry = "Instrument Box:Load VST..: * "..rns_plugin_infos[i].short_name
        else
          menu_entry = "Instrument Box:Load VST..:"..rns_plugin_infos[i].short_name
        end
         --add to menu 
        if not renoise.tool():has_menu_entry(menu_entry) then
            renoise.tool():add_menu_entry {
              name = menu_entry,
              invoke = function() load_vsti(i) end
            }
        end
      end
    end
  end
  
  --Add menu entries with loop
  ----------------------------
  if no_of_vsts > 0 then --check we have plugs to add   
    local menu_entry = ""
    for i = 1,no_of_vsts do
      if plug_inst_type[i] == "DSSI" then 
        --is_bridged? 
        if rns_plugin_infos[i].is_bridged then
          menu_entry = "Instrument Box:Load DSSI..: * "..rns_plugin_infos[i].short_name
        else
          menu_entry = "Instrument Box:Load DSSI..:"..rns_plugin_infos[i].short_name
        end
         --add to menu 
        if not renoise.tool():has_menu_entry(menu_entry) then
            renoise.tool():add_menu_entry {
              name = menu_entry,
              invoke = function() load_vsti(i) end
            }
        end
      end
    end
  end
  
  --Add AU menu entries with loop
  ------------------------------- 
  if no_of_vsts > 0 then --check we have plugs to add  
    local menu_entry = ""
    for i = 1,no_of_vsts do
      if plug_inst_type[i] == "AU" then 
        --is_bridged? 
        if rns_plugin_infos[i].is_bridged then
          menu_entry = "Instrument Box:Load AU..: * "..rns_plugin_infos[i].short_name
        else
          menu_entry = "Instrument Box:Load AU..:"..rns_plugin_infos[i].short_name
        end
         --add to menu 
        if not renoise.tool():has_menu_entry(menu_entry) then
            renoise.tool():add_menu_entry {
              name = menu_entry,
              invoke = function() load_vsti(i) end
            }
        end
      end
    end
  end
  
  
  --Now add Preference menu entry to auto open VST GUI
  ----------------------------------------------------
  if not renoise.tool():has_menu_entry("--- Instrument Box:Load VST..: Auto Open Gui") then
  -- triple dash: "---" creates menu divider 
  renoise.tool():add_menu_entry {
     
       name = "--- Instrument Box:Load VST..: Auto Open Gui", 
       selected = function() return options.auto_open.value end, 
       invoke = function() options.auto_open.value = not options.auto_open.value end
       }
  end
  --remove notifier so only runs on renoise start-up
  ---------------------------------------------------
  if renoise.tool().app_new_document_observable:has_notifier(add_vsts_to_instrument_box) then
   renoise.tool().app_new_document_observable:remove_notifier(add_vsts_to_instrument_box)
  end     
end  --add_vsts_to_instrument_box

--------------------------------------------------------------------------
--------------------------------------------------------------------------


-------------------------------------------------------------------------
-- [2] Mixer and DSP lane function
-------------------------------------------------------------------------
-- 2 of two functions called by app_new_document notifier
-----------------------------------------
function add_vsts_to_mixer_and_dsp_lane()
-----------------------------------------

 -- local rns_track_device_infos = renoise.song().tracks[1].available_device_infos
  
  --make a deep copy of 'renoise.song().tracks[1].available_device_infos'
  ---------------------------------
  local function deepCopy(original)
  ---------------------------------
    local copy = {}
    for k, v in pairs(original) do
      if type(v) == "table" then
        v = deepCopy(v)
      end
      copy[k] = v
    end
    return copy
  end
  ----
  --call fn
  local rns_track_device_infos = deepCopy(renoise.song().tracks[1].available_device_infos)


  --we can sort this depp cpoied table with added function to table.sort() we capitalise the short_name keys and comaper them (output is case insensitive)
  table.sort(rns_track_device_infos , function(a, b) return a.short_name:upper() < b.short_name:upper() end)
  
  
  local plug_type = {}
  local VSTs = 1
  local no_of_vsts = #rns_track_device_infos
  
  local hidden_plugs = {"*Formula Device",
                  "*MIDI-CC Device",
                --"Distortion",
                --"Filter",
                  "Filter 2",
                --"Gate",
                --"LofiMat",
                  "MasterTrackVolPan",
                --"mpReverb",
                  "SendTrackVolPan",
                  "Shaper",
                  "Stutter",
                  "TrackVolPan"
                  }
  
  --for divided menu entries                
  local add_divider = "---"
                                                  
                  
  --get fx plugin names and add to table "plugins"
  for VSTs = 1,no_of_vsts do
    
    --routing
    if string.find(rns_track_device_infos[VSTs].path , "Audio/Effects/Native/#")then
      plug_type[VSTs] = "Routing"
    --meta
    elseif string.find(rns_track_device_infos[VSTs].path , "Audio/Effects/Native/%*") then
      plug_type[VSTs] = "Meta" 
    --native is last as all renoise fx have native in path
    elseif string.find(rns_track_device_infos[VSTs].path , "Audio/Effects/Native/")then
      plug_type[VSTs] = "Native"
    end
   
    --Plugins
    if  string.find(rns_track_device_infos[VSTs].path , "VST/") then
      plug_type[VSTs] = "VST" 
   
    elseif  string.find(rns_track_device_infos[VSTs].path , "VST3/") then 
      plug_type[VSTs] = "VST3"
    
    elseif  string.find(rns_track_device_infos[VSTs].path , "DSSI/") then
      plug_type[VSTs] = "DSSI"
  
    elseif  string.find(rns_track_device_infos[VSTs].path ,"AU/") then
      plug_type[VSTs] = "AU"
    end
    
    -- remove hidden/ compatability plugs
    if plug_type[VSTs] == "Native/" then
      for i = 1,13 do
        if rns_track_device_infos[VSTs].short_name == hidden_plugs[i] then
          plug_type[VSTs] = "Void"
          break
        end
      end
    end
  end--for
  

  --load VST fx on execution
  --(when an fx is chosen in the menu)
  ------------------------------
  local function load_vst(fn_no)
  ------------------------------
   --get total devices in current tracks chain
    local track = renoise.song().selected_track_index
    local track_device_total = #renoise.song().selected_track.devices
    local current_track = renoise.song().tracks[track]
    local song = renoise.song()
    
    --load into sample ed
    if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS then
    
      local chain = song.selected_sample_device_chain
      local dev = chain:insert_device_at(rns_track_device_infos[fn_no].path, (#chain.devices + 1))
      --select device
      song.selected_sample_device_index = (#chain.devices)
      --open editor if preferenced
      if (options.auto_open_fx.value) then -- auto_open then
        if dev.external_editor_available then
          dev.external_editor_visible = true
        end
      end 
    else --load into track
      current_track:insert_device_at(rns_track_device_infos[fn_no].path, (track_device_total + 1))
      --select device
      renoise.song().selected_track_device_index = (track_device_total + 1)
      
      --open editor if preferenced
      if (options.auto_open_fx.value) then -- auto_open then
        if current_track.devices[(track_device_total + 1)].external_editor_available then
          current_track.devices[(track_device_total + 1)].external_editor_visible = true
        end
      end 
    end
  end
  
 
  ------------------------------------
  --Add Menu entries with loops
  ------------------------------------
  
  --table for each menu area in renoise to be added
  local menu_roots = {"Mixer:","DSPs Chain:","DSP Device:"} --"Track DSPs Chain" is now "DSPs Chain API 4"
  --initialise menu string, it will be concatenated to root
  local menu_entry = "" 
  
  
  
  --remove all VST3 FX menu entries
   ----------------------------------
   for i = 1,no_of_vsts do
     if plug_type[i] == "VST3" then 
       --add * if it is a bridged plugin
       if rns_track_device_infos[i].is_bridged then
         menu_entry = "Load VST 3 fx..: * "..rns_track_device_infos[i].short_name
       else
         menu_entry = "Load VST 3 fx..:"..rns_track_device_infos[i].short_name
       end
       --remove each menu entry
       for root = 1,#menu_roots do
         if renoise.tool():has_menu_entry(add_divider..menu_roots[root]..menu_entry) then
           -- remove entries
           renoise.tool():remove_menu_entry(add_divider..menu_roots[root]..menu_entry)
         end
       end
     end
   end
   --loop to remove 'this' menu  
   for root = 1,#menu_roots do               
     --remove this menu entry (or all get added below divider)
     if renoise.tool():has_menu_entry(add_divider..menu_roots[root].."Load VST 3 fx..:Only Show Unique VST3 Plugs") then
       renoise.tool():remove_menu_entry(add_divider..menu_roots[root].."Load VST 3 fx..:Only Show Unique VST3 Plugs")
     end
   end
   ----------

  
  
  
  
  
  
  ---------------------------------------------------
  --Add VST entries with loops
  ---------------------------------------------------
  for i = 1,no_of_vsts do
  
    if plug_type[i] == "VST" then 
     --add * if it is a bridged plugin
      if rns_track_device_infos[i].is_bridged then
        menu_entry = "Load VST fx..: * "..rns_track_device_infos[i].short_name
      else
        menu_entry = "Load VST fx..:"..rns_track_device_infos[i].short_name
      end
      --add menu entry
      for root = 1,#menu_roots do
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          -- add entries
          renoise.tool():add_menu_entry {
           name = menu_roots[root]..menu_entry,
           invoke = function() load_vst(i) end
          }
        end
      end
    end
  end
  
  --VST3
  ----------
  --USER OPTION: remove plugs from the VST3 list that are present in the
  --VST2.4 list
  ---------------------------------------------
  local function remove_non_unique_vst3_plugs()
  --------------------------------------------- 
    for i = 1,no_of_vsts do
      if plug_type[i] == "VST3" then
        for j = 1,no_of_vsts do
          if plug_type[j] == "VST" then
            if rns_track_device_infos[i].short_name == rns_track_device_infos[j].short_name then
              plug_type[i] = ""
             -- print(rns_track_device_infos[j].short_name)
              break
            end
          end
        end  
      end
    end 
  end 
  ---
  --remove plugs doubled in vst3 menu if user specifies
  if options.only_show_unique_vst3.value == true then
    remove_non_unique_vst3_plugs() 
  end
  
  --ADD VST3's
  -----------  
  for i = 1,no_of_vsts do
    if plug_type[i] == "VST3" then 
     --add * if it is a bridged plugin
      if rns_track_device_infos[i].is_bridged then
        menu_entry = "Load VST 3 fx..: * "..rns_track_device_infos[i].short_name
      else
        menu_entry = "Load VST 3 fx..:"..rns_track_device_infos[i].short_name
      end
      --add menu entry
      for root = 1,#menu_roots do
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          -- add entries
          renoise.tool():add_menu_entry {
           name = menu_roots[root]..menu_entry,
           invoke = function() load_vst(i) end
          }
        end
      end
    end
  end
  
  
  --show unique VST3 plugs only option for 'remove_non_unique_vst3_plugs()' function above
  ------------------------------------
  
 
  --loop all menu locations
  for root = 1,#menu_roots do
   
   if not renoise.tool():has_menu_entry(add_divider..menu_roots[root].."Load VST 3 fx..:Only Show Unique VST3 Plugs") then
      -- add entry to all 'root' locations
      renoise.tool():add_menu_entry {
       name = add_divider..menu_roots[root].."Load VST 3 fx..:Only Show Unique VST3 Plugs",
       selected = function() return options.only_show_unique_vst3.value end, 
       invoke = function()
        
                    --change options value
                    options.only_show_unique_vst3.value = not options.only_show_unique_vst3.value
                 
                    --re-run whole function to repopulate menus with or without duplicated vst2/3
                    -----------------------------------------------------------------------------
                    add_vsts_to_mixer_and_dsp_lane()
                    add_vsts_to_instrument_box()
                  end
         }
    end
  end 

  
  
  ---------------------------------------------------
  --Add DSSI FX entries with loop
  ---------------------------------------------------
   
  for i = 1,no_of_vsts do
    
    if plug_type[i] == "DSSI" then
    
        --add * if it is a bridged plugin
      if rns_track_device_infos[i].is_bridged then
        menu_entry = "Load DSSI fx..: * "..rns_track_device_infos[i].short_name
      else
        menu_entry = "Load DSSI fx..:"..rns_track_device_infos[i].short_name
      end
      --add all menu entry
      for root = 1,#menu_roots do
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          -- add entries
          renoise.tool():add_menu_entry {
           name = menu_roots[root]..menu_entry,
           invoke = function() load_vst(i) end
          }
        end
      end
    end
  end
  
  
  ---------------------------------------------------
  --Add AU FX entries with loop
  ---------------------------------------------------
  
  for i = 1,no_of_vsts do
   
    if plug_type[i] == "AU" then
      
     --add * if it is a bridged plugin
      if rns_track_device_infos[i].is_bridged then
        menu_entry = "Load AU fx..: * "..rns_track_device_infos[i].short_name
      else
        menu_entry = "Load AU fx..:"..rns_track_device_infos[i].short_name
      end
      
      --add menu entry
      for root = 1,#menu_roots do
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          -- add entries
          renoise.tool():add_menu_entry {
           name = menu_roots[root]..menu_entry,
           invoke = function() load_vst(i) end
          }
        end
      end
    end
  end
  
  
  ---------------------------------------------------
  --Add Native FX entries with loops
  ---------------------------------------------------

  for i = 1,no_of_vsts do
  
    if plug_type[i] == "Native"  then
      menu_entry = "Load Native fx..:"..rns_track_device_infos[i].short_name
      
      --add menu entries
      for root = 1,#menu_roots do
        -- add entries
        if not renoise.tool():has_menu_entry(add_divider..menu_roots[root]..menu_entry) then
          renoise.tool():add_menu_entry {
            name = add_divider..menu_roots[root]..menu_entry,
            invoke = function() load_vst(i) end
            }
         end
       end
  
       add_divider = "" --only add a single divider at the beginning
    end
  end
  
  ---------------------------------------------------
  --Add Meta FX Devices with loops
  ---------------------------------------------------
  
  for i = 1,no_of_vsts do
      
    if plug_type[i] == "Meta"  then
      menu_entry = "Load Native fx..:Meta fx..:"..rns_track_device_infos[i].short_name
      
     -- print(menu_entry)
   --add menu entries
      for root = 1,#menu_roots do
        -- add entries
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          renoise.tool():add_menu_entry {
            name = menu_roots[root]..menu_entry,
            invoke = function() load_vst(i) end
            }
        end
      end
    end 
  end
  
  ---------------------------------------------------
  --Add Routing FX Devices with loop
  ---------------------------------------------------
  
  for i = 1,no_of_vsts do
      
    if plug_type[i] == "Routing"  then
      menu_entry = "Load Native fx..:Routing fx..:"..rns_track_device_infos[i].short_name
  
     --add menu entries
      for root = 1,#menu_roots do
        -- add entries
        if not renoise.tool():has_menu_entry(menu_roots[root]..menu_entry) then
          renoise.tool():add_menu_entry {
            name = menu_roots[root]..menu_entry,
            invoke = function() load_vst(i) end
            }
        end
      end
    end
  end
  
  -------------------------------------------------------------------
  --Now add Preference menu as last entry entry to auto open VST GUI
  -------------------------------------------------------------------
  -- triple dash: "---" creates menu divider 
  
     --add menu entries
      for root = 1,#menu_roots do
        if not renoise.tool():has_menu_entry("--- "..menu_roots[root].."Load VST fx..: Auto Open Gui") then
           renoise.tool():add_menu_entry {
             name = "--- "..menu_roots[root].."Load VST fx..: Auto Open Gui", 
             selected = function() return options.auto_open_fx.value end, 
             invoke = function() options.auto_open_fx.value = not options.auto_open_fx.value end
             }
          end
      end
  
  ----------------------------------------------------
  --remove notifier so only runs on renoise start-up
  ----------------------------------------------------
  if renoise.tool().app_new_document_observable:has_notifier(add_vsts_to_mixer_and_dsp_lane) then
   renoise.tool().app_new_document_observable:remove_notifier(add_vsts_to_mixer_and_dsp_lane)
  end

end --add_vsts_to_mixer_and_dsp_lane()



------------------------------------
--Global add new document notifiers
------------------------------------
--these gets removed in  called functions so as not to fire on each new song
--instruments
renoise.tool().app_new_document_observable:add_notifier(add_vsts_to_instrument_box)
--fx
renoise.tool().app_new_document_observable:add_notifier(add_vsts_to_mixer_and_dsp_lane)













 
