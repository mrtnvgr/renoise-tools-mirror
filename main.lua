TOOL_NAME = "Random Plug"

--helper function : custom status message 
--prefixes tool name and adds brackets 
------------------------------
local function status(message)
------------------------------
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
end

--Renoise Keybinds and menus
-------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:"..TOOL_NAME,
  invoke = function()main_toggle() end  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:"..TOOL_NAME,
  invoke = function()main_start()end  
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:"..TOOL_NAME,
  invoke = function()main_start()end  
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Select Random Plugin Instrument Preset",
  invoke = function()select_random_instrument_preset()end  
}

--global
local bypass_timer = false

--function returns a table of unique,random,consecutive numbers from 1 to (max)<- settable
-------------------------------------------------------------------------------------------
--NOTES:
--------
--i.e. you have a list of 7 meals that you want to cook in random order over 7 days. 
--Each meal must be chosen once with no repeats:
-----------------------------------------------
--call the function
--local random_meal_indexes = get_table_of_random_numbers(7)

--loop to use the 7 new random indexes
--for i = 1,7 do
--  local meal_idx = random_meal_indexes[i]
--  print all_meals[meal_idx]
--end
-----------------------------------------
function get_table_of_random_numbers(max)
-----------------------------------------
  --outer scope table
  local g_index_store = {}
  ------------------------------------------------------------------
  local function get_random_index(max)
  ------------------------------------------------------------------
    --g_index_store will have consecutive entries { [1] = 1, [2] = 2, [3] = 3, [4] = 4, etc..} up to (max)
    --We choose a random index using Luas math.random(), with limit set to size of #g_index_store.
    --Once we have used an entry e.g entry [3] we discard it using lua's table.remove() function. e.g. when 3 has been removed the items become
    --{ [1] = 1, [2] = 2, [3] = 4, [4] = 5, etc..}
    --The value for 3 has now become 4 and the value for 4 has become 5.  g_index_store is now one entry shorter.
    
    --when max is too small fire error
    if max < 2 then
      error("max must be greater than 1")
      return
    end
    
    --if index table has been emptied or it is the first run re-populate it
    if #g_index_store == 0 then
      for i = 1,max do
        --a simple table where { [1] = 1, [2] = 2, [3] = 3 etc..}
        g_index_store[i] = i
      end
    end
      
    --random number
    ---------------
    --get os.time() as a seed
    local t = os.time()
    --as os.time() updates slowly we multiply it by random number before passing to randomseed
    math.randomseed((t * math.random(1,789)))
    --get random number based on os.time()
    local ran_num = nil
    --random number between 1 and the length of the index-storing table
    ran_num = math.random(1, #g_index_store)
    
    --get new random index number from the global g_index_store table
    ---------------------------------------------------------------
    local rand_index = g_index_store[ran_num]
    --discard index value/ entry so the used 'index value' can not be selected again.
    table.remove(g_index_store,ran_num) 
    --return the current index value
    return rand_index
  end
  ----end local function
  
  --to store random numbers
  local random_table = {}
  for i = 1,max do
    random_table[i] = get_random_index(max)
  end
  --return completed table which can be cross-indexed for random indexes in a separate table/list
  return random_table
end
---------------------------------------------------------------------------


--'global' scope
local random_num_tab_preset = nil
--stores total num of presets for the current plug
--when the plug changes this is used as a flag (not 100% perfect as new plug may have same no of presets, but mainly irellevant in that case)
local total_presets = nil
------------------------------------------
function select_random_instrument_preset()
------------------------------------------
  local song = renoise.song()
  local cur_inst = song.selected_instrument
  
  --no plug loaded so return
  if cur_inst.plugin_properties.plugin_loaded == false then
    return
  end 
   
  --selected instrument device
  local cur_inst_device = cur_inst.plugin_properties.plugin_device
  local num_presets = #cur_inst_device.presets
  local last_legitimate_preset_idx = num_presets 
  
  --return if device only has 1 preset
  if num_presets == 1 then
    renoise.app():show_status("Plug Only Has One Preset")
    return
  end
  
  --(re)populate random number table
  if (random_num_tab_preset == nil) or (#random_num_tab_preset == 0) or (total_presets ~= num_presets)then
    random_num_tab_preset = get_table_of_random_numbers(num_presets)
    --update as new instrument has been loaded
    total_presets = num_presets 
  end
  
  local final_rand_num = nil
  
  --counter to break loop/ return if can't find a preset i.e. everything checked seems to be a double
  local counter = 1
  --loop through presets and find if current random preset would have any doubles
  --i.e weed out blank/ unused presets like "Init"/ "Default", depending on how the vendor has named them
  while 1 do
    --flag
    local double_found = false
    
    --make sure table entries are left
    if random_num_tab_preset == nil or #random_num_tab_preset == 0 then
      error("error see line: 157 of main.lua")
    end
    
    --get next random number
    --random number from pos 1 of 'table of random numbers'
    local random_num_at_pos_one = random_num_tab_preset[1]
    --remove pos 1 as we have used it now, new pos 1 will be the next random number
    --once the table is used or gui re-opened up a new one gets generated
    table.remove(random_num_tab_preset,1)
    
    --get name of random preset to test
    local preset_name = cur_inst_device:preset(random_num_at_pos_one)
    
    --loop all presets to test against random preset
    for i = 1,num_presets do
    
      if (preset_name == cur_inst_device:preset(i)) and (i ~= random_num_at_pos_one) then
        --flag that a double has been found for ther preset name (so likely a blank preset: "Init" or "")
        double_found = true
        break 
      end
    end 
    --break while loop if no double was found
    if double_found == false then
      final_rand_num = random_num_at_pos_one
      break
    end
    --break after 20 attempts, and default to slot 1
    if counter > 20 then
      final_rand_num = 1
      break
    end 
    --increment counter
    counter = counter + 1
  end
  
  --select random preset
  ----------------------
  cur_inst_device.active_preset = final_rand_num

  --status message
  local message = "[ "..final_rand_num.." / "..num_presets.." ] : "..cur_inst_device:preset(final_rand_num)
  renoise.app():show_status("Random Preset: "..message.."")
end







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
------------------------------
------------------------------
--helper function : custom status message 
--prefixes tool name and adds brackets 
------------------------------
local function status(message)
------------------------------
  renoise.app():show_status(TOOL_NAME.." Tool: ("..message..")")
end

--globals to store target plug info
local g_inst_name = nil
local g_inst_path = nil
local g_fx_name = nil
local g_fx_path = nil

--toggle lock focus hack
--stops newly loaded plugins stealing focus 
------------------------
function toggle_focus()
-----------------------
  renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus --toggle setting opposite
  renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus --toggle back
end 


--'global' scope
local random_num_tab_inst = nil
--------------------------------
function get_random_instrument()
--------------------------------
  local song = renoise.song()
  local inst = song.selected_instrument
  local num_available_insts = #inst.plugin_properties.available_plugins
  
  --(re)populate random number table
  if random_num_tab_inst == nil or #random_num_tab_inst == 0 then
    random_num_tab_inst = get_table_of_random_numbers(num_available_insts)
  end

  --for index: random number from pos 1 of 'table of random numbers'
  local random_num_at_pos_one = random_num_tab_inst[1]
  
  g_inst_name = inst.plugin_properties.available_plugin_infos[random_num_at_pos_one].short_name
  g_inst_path = inst.plugin_properties.available_plugin_infos[random_num_at_pos_one].path

  --remove pos 1 as we have used it now, new pos 1 will be the next random number
  --once the table is used or gui re-opened up a new one gets generated
  table.remove(random_num_tab_inst,1)
  --update gui
  vb.views["inst text"].text = g_inst_name
  --local
  local hit = num_available_insts - #random_num_tab_inst 
  --update status
  status("Inst: "..tostring(random_num_at_pos_one).."/"..num_available_insts.."   Hit: "..hit)
  
end

--'global' scope
local random_num_tab_fx = nil
--------------------------------
function get_random_fx()
--------------------------------
  local song = renoise.song()
  local track = song.selected_track
  local num_available_fx = #track.available_devices
  
  --(re)populate random number table
  if random_num_tab_fx == nil or #random_num_tab_fx == 0 then
    random_num_tab_fx = get_table_of_random_numbers(num_available_fx)
  end
  
  --random number from pos 1 of 'table of random numbers'
  local random_num_at_pos_one = random_num_tab_fx[1]

  g_fx_name = track.available_device_infos[random_num_at_pos_one].short_name
  g_fx_path = track.available_device_infos[random_num_at_pos_one].path
  
  --remove pos 1 as we have used it now, new pos 1 will be the next random number
  --once the table is used or gui re-opened up a new one gets generated
  table.remove(random_num_tab_fx,1)
  --update gui
  vb.views["fx text"].text = g_fx_name
  --local
  local hit = num_available_fx - #random_num_tab_fx 
  --update status
  status("fx: "..tostring(random_num_at_pos_one).."/"..num_available_fx.."   Hit: "..hit)
end

--------------------------------
function load_random_instrument()
--------------------------------
   local song = renoise.song()
   local inst = song.selected_instrument
   --load the plugin using global g_inst_path
   --math.randomseed(os.time())
   local new_inst = inst.plugin_properties:load_plugin(g_inst_path)
   --return if no instrument loaded
   if new_inst == false then 
     return
   end
   --open the new device gui if it has one
   if inst.plugin_properties.plugin_device.external_editor_available == true then
     inst.plugin_properties.plugin_device.external_editor_visible = true
   end
   toggle_focus()      
end

--------------------------------
function load_random_fx()
--------------------------------
  local song = renoise.song()
  --selected track object
  local cur_track = song.selected_track


  --BUG REPORTED 12th Aug 2020; song.selected_sample_device_chain should return nil when not available but fires error, so no way to check:
  --print(song.selected_sample_device_chain)
  --Use song.selected_sample_device_chain_index instead

  --insert the device to either the sampler if open in middle view, else the main renoise track.
  local device = nil
  --insert to sampler
  if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS then
    --sample_dev chain
    if song.selected_sample_device_chain_index == 0 then
      renoise.app():show_message("A Device Chain Needs To Be Added Or Chosen\nBefore Inserting Random Effect To Sampler")
      return
    end    
    --get selected chain
    local chain = song.selected_sample_device_chain or 1
    local insert_pos = (song.selected_sample_device_index) or (#chain.devices) --<-selected device can be nil
    --catch when no selected device results in 0
    if insert_pos == 0 then
      insert_pos = #chain.devices 
    end
    --increment so device adds after
    insert_pos = insert_pos + 1 
    --insert dev using global g_fx_path
    device = chain:insert_device_at(g_fx_path,insert_pos)
    --select new device
    song.selected_sample_device_index = insert_pos
    --open device gui
    if device.external_editor_available == true then
      device.external_editor_visible = true
    end
  else
    --insert pos at selected device or end of devices if none selected
    local insert_pos = (song.selected_track_device_index) or (#cur_track.devices) --<-selected device can be nil
    --catch when no selected device results in 0
    if insert_pos == 0 then
      insert_pos = #cur_track.devices 
    end
    --increment so device adds after
    insert_pos = insert_pos + 1 
    --insert device to main track/ mixer
    device = cur_track:insert_device_at(g_fx_path,insert_pos)
    --select device
    song.selected_device_index = insert_pos
    --open device gui
    if device.external_editor_available == true then
      device.external_editor_visible = true
    end
  end
  --toggle keboard focus
  toggle_focus()
end

-----------------------------------------
local function get_all_instrument_names()
-----------------------------------------
  local song = renoise.song()
  local insts = song.instruments
  local all_inst_names = {}
  --loop instrument slots
  for i = 1,#insts do
    --get hex format of index 'i'
    local index = tostring((i - 1)):format("%02X")
    --add leading '0' for indexes 1-10
    index = string.format("%02X",index)
    --add formatted entry to table
    all_inst_names[i] = string.sub(index.." : "..insts[i].name, 1, 30)
  end
  return all_inst_names
end
---
--[[
---------------------------------------------------------
--returns a formatted selected instrument number and name
---------------------------------------------------------
local function selected_instrument_name()
  --song
  local song = renoise.song()
  --get hex format of index 'i
  local index = tostring((song.selected_instrument_index - 1)):format("%02X")
  --add leading '0' for indexes 1-10
  index = string.format("%02X",index)
  --return formatted entry
  return string.sub(index.." : "..song.selected_instrument.name, 1, 30)
end  

--]]


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
  
  --reset random tables
  random_num_tab_inst = nil
  random_num_tab_fx = nil
  

  ----------------------------------------------
  --GUI
  ----------------------------------------------     
  
  --constants
  local NEXT_BUTTON_WIDTH = 100
  local ALL_BUTTON_HEIGHT = 29
  local LOAD_BUTTON_WIDTH = 200
  local MARGIN = 2

  
  
  --variables that will be added to
  --dialog_content:add_child(send_row)
  local my_first_row = vb:row {}
  -------------------------------
  local main_col = nil
  
  --DUMMY CONTENT
  ----------------
  --loop to create buttons and add them to my_first_row

    --1 button
    main_col = vb:column{
                  margin = 4,
                  vb:column{
                    vb:row{
                     margin = 4,
                     vb:popup{
                       width = LOAD_BUTTON_WIDTH,
                       id = "inst popup",
                       items = get_all_instrument_names(),
                       value = song.selected_instrument_index,
                       notifier = function(value)
                                    --update flag
                                    bypass_timer = true
                                    song.selected_instrument_index = value
                                  
                                    --UPDATE Inst. Preset button color i.e. green if available 
                                    -----------------------------------------------------------
                                    --default to grey
                                    vb.views["inst presets button"].color = COLOR_GREY
                                    vb.views["inst presets button"].text = "N / A"
                                    vb.views["inst presets button"].active = false
                                    --selected instrument in renoise
                                    local cur_inst = song.selected_instrument
                                    --check instrument plug loaded in the slot
                                    if cur_inst.plugin_properties.plugin_loaded == true then
                                      --selected instrument device
                                      local cur_inst_device = cur_inst.plugin_properties.plugin_device
                                      local num_presets = #cur_inst_device.presets
                                      --do nothing/ remain grey if device only has 1 preset
                                      if num_presets > 1 then
                                        vb.views["inst presets button"].color = COLOR_GREEN
                                        vb.views["inst presets button"].text = "Preset"
                                        vb.views["inst presets button"].active = true
                                      end
                                    end 
                                    bypass_timer = false
                                  end
                      },
                     -- vb:text{
                    --  text = "<-",
                  --   },
                      vb:button{
                      color = COLOR_GREY,
                      id = "inst presets button",
                       text = "Preset", 
                       notifier = function()select_random_instrument_preset()end,
                       
                      },
                      
                     },
                     vb:text{
                      text = "-------------------------------------------------"
                     }
                  },
                   
                   vb:row{
                    margin = MARGIN,

                   vb:button{
                    width = NEXT_BUTTON_WIDTH ,
                    height = ALL_BUTTON_HEIGHT,
                    text = "Next",
                    notifier = function()
                                get_random_instrument()
                              end
                    },
                    
                   vb:text{
                     width = 100--spacer for gui
                   },  
                    vb:button{
                    width = NEXT_BUTTON_WIDTH ,
                    height = ALL_BUTTON_HEIGHT,
                    text = "Next",
                    notifier = function()
                                get_random_fx()
                              end
                    },
                    
                    
                   },
                   
                   vb:row{ 
                    margin = MARGIN,
                    vb:textfield{
                     width = LOAD_BUTTON_WIDTH,
                     height = ALL_BUTTON_HEIGHT + 5,
                     id = "inst text",
                    },
                    
                     vb:textfield{
                     width = LOAD_BUTTON_WIDTH,
                     height = ALL_BUTTON_HEIGHT + 5,
                     id = "fx text",
                    },
                    
                    
                      },
                    vb:row{ 
                    margin = MARGIN,
                     vb:button { 
                       width = LOAD_BUTTON_WIDTH,
                       height = ALL_BUTTON_HEIGHT,
                       text = "Load Instrument",
                       notifier = function()
                                     load_random_instrument()
                                     --update popup items
                                     vb.views["inst popup"].items = get_all_instrument_names()
                                    
                                    end,            
                      },
                      
                      vb:button { 
                       width = LOAD_BUTTON_WIDTH,
                       height =  ALL_BUTTON_HEIGHT,
                       text = "Load Effect",
                       notifier = load_random_fx,
                      },
                     },
                   }--end main_col
                    
  
  --------------------------------------------------------
  --------------------------------------------------------
  --dialog content will contain all of gui; passed to renoise.app():show_custom_dialog()
  local dialog_content = vb:column{}
  dialog_content:add_child(main_col)
  
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
    renoise.tool():add_timer(timer,50)
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
    --remove timer
    if renoise.tool():has_timer(timer) then
      renoise.tool():remove_timer(timer)
    end
  end
  -- notifier to close dialog on load new song
  renoise.tool().app_release_document_observable:add_notifier(closer,my_dialog)
  -------------------------------------------------------------------------------
  
  --first run of timer
  timer()
  
  --first run to get random instrument and fx to show in GUI textfields
  ---------------------------------------------------------------------
  get_random_instrument()
  get_random_fx()
end
--end of main()
---------------

----------------
--timer function
----------------
function timer()
  
  --remove timer when GUI is closed
  if(my_dialog == nil) or (my_dialog.visible == false) then
    if renoise.tool():has_timer(timer) then
     -- print(renoise.tool():has_timer(timer))
      renoise.tool():remove_timer(timer)
     -- print(renoise.tool():has_timer(timer))
    end
  end

  --print(bypass_timer)
  if bypass_timer == true then
    return
   -- print("bypassed")
  end
  
  --song object
  local song = renoise.song()
  local sel_inst_index = song.selected_instrument_index
  local popup = vb.views["inst popup"]
  --update popup if selected instrument changed by user
  if popup.value ~= sel_inst_index then
  --print("changed")
    popup.value = sel_inst_index
  end
  --update instrument popup
  vb.views["inst popup"].items = get_all_instrument_names()
  
  --UPDATE Inst. Preset button color i.e. green if presets available in 
  --selected instrument in renoise  
  -----------------------------------------------------------
  --default to grey
  vb.views["inst presets button"].color = COLOR_GREY
  vb.views["inst presets button"].text = "N / A"
  vb.views["inst presets button"].active = false
  --selected instrument in renoise
  local cur_inst = song.selected_instrument
  --check instrument plug loaded in the slot
  if cur_inst.plugin_properties.plugin_loaded == true then
    --selected instrument device
    local cur_inst_device = cur_inst.plugin_properties.plugin_device
    local num_presets = #cur_inst_device.presets
    --do nothing/ remain grey if device only has 1 preset
    if num_presets > 1 then
      vb.views["inst presets button"].color = COLOR_GREEN
      vb.views["inst presets button"].text = "Preset"
      vb.views["inst presets button"].active = true
    end
  end 
end
--end of timer()



