require "Search_FX_GUI"


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

--Constants holding first index of color-code: Used to identify color in vb.views table i.e.
--if vb.views["button"].color[1] == COLOR_ORANGE_FLAG then --etc
COLOR_GREY_FLAG = 0x30
COLOR_ORANGE_FLAG = 0xFF
COLOR_YELLOW_FLAG = 0xE0
COLOR_BLUE_FLAG = 0x50  
COLOR_RED_FLAG = 0xEE
COLOR_GREEN_FLAG = 0x20
--------------------------------------------------------------------------------

--sets color of New Slot button to red if current inst slot occupied
--grey if not
----------------------------------
function check_if_inst_slot_clear()
  if renoise.song().selected_instrument.name ~= "" then
    return COLOR_RED
  else
    return COLOR_GREY
  end
end
---------------------

--Lock Keyboard Focus FIXED

local my_dialog = nil


--called for creating/ selecting an empty instrument slot in the list to load vst into --called by New Slot button 
function next_empty_instrument_slot()

  local song = renoise.song()
 
  for i = 1,#song.instruments do
    if song.instruments[i].name == "" then
      song.selected_instrument_index = (i)
      renoise.app():show_status("First Empty Instrument Slot Selected")
      return
    end
  end

  --loop was not stopped so need to add empty slot at end if not already the end empty slot
  if song.selected_instrument.name ~= "" then  
    renoise.song():insert_instrument_at(#song.instruments + 1)
    song.selected_instrument_index = #song.instruments
    renoise.app():show_status("New Empty Instrument Added ")
  end
end

-------------------------------------------------------------------------------------------
--Main
-------------------------------------------------------------------------------------------
function search_track()

  -------------------------------------------------------------------------------------------
  --local functions
  -------------------------------------------------------------------------------------------
  
  --generic handler which accepts an optional parameter for dialog
  local function closer(d)
    
    if d then
     -- renoise.song().tracks_observable:remove_notifier(closer,my_dialog) --remove notifiers
  --  renoise.tool().app_release_document_observable:remove_notifier(closer, my_dialog)   
    end       
      
    if d and d.visible then             
      d:close()
    end
  end
  
  --function to focus the pattern editor
  local function focus_pattern_ed()
    renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
    renoise.app().window.lock_keyboard_focus = not renoise.app().window.lock_keyboard_focus
  end
  -------------------------------------------------------------------------------------------
  
  if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
    my_dialog:show()
    return
  end
    
  local no_of_tracks = #renoise.song().tracks
  local matching_string = nil
  local current_track = renoise.song().selected_track_index 
  local current_track_name =  renoise.song().tracks[current_track].name 
  local vb = renoise.ViewBuilder()
  local field_typing = false
  
  --get available plugin infos--short names will be copied to names table, path used to luad plugin
  local vst_table = renoise.song().instruments[1].plugin_properties.available_plugin_infos
  
  --This is the list of strings that will appear in the pop-up
  local popup_names_table = {}
  
  --populate table with the plugin short names
  for i = 1,#vst_table do
    popup_names_table[i] = vst_table[i].short_name
  end
  
  --add a "No Match" field to the beginning
  table.insert(popup_names_table,1,"No Match")
  --add a blank entry to vst table as we need the indexes to match
  table.insert(vst_table,1,{})
   
  ----------------------------------------------------------------------------
  --see what the longest name in the search list to set the GUI popup width by
  ----------------------------------------------------------------------------
  local function get_longest_name()
   --set name length to 1
   local name_length = 10
   --loop to set to longest string
   for i = 1, #popup_names_table do --include ([1] "No Match)"
     if popup_names_table[i]:len() > name_length then
       name_length = popup_names_table[i]:len()
     end
   end
   return name_length
  end
   
  -------------------------------------------------------------------------------------------
  --GUI
  -------------------------------------------------------------------------------------------
  local dialog_content =
    
    vb:vertical_aligner {
    margin = 8,
    mode = "center",
                           
    vb:textfield {
    -- text = current_track_name,
    id = "textfield",
    --set width relative to the longest name in search table (at rough average of 7 pixels per char)
    width = (7 * get_longest_name()),
    },
                            
    vb:popup {
    id = "popup",
    --set width relative to the longest name in search table (at rough average of 7 pixels per char)
    width = (7 * get_longest_name()),
    value = 1,--"No Match"
    items = popup_names_table,
    --updates the textfield when an entry is chosen from the pop-up menu
   -- notifier = function(number) vb.views["textfield"].value = popup_names_table[number] end 
    },
    --spacer text
    vb:horizontal_aligner{
      vb:text{
       text = ""
      }
    },

    vb:horizontal_aligner{
     -- mode = "center",
      vb:button{
        text = "New Slot",
        id = "new slot button",
        height = 20,
        color = check_if_inst_slot_clear(),
        notifier = function()
                     next_empty_instrument_slot()
                     vb.views["new slot button"].color = COLOR_GREY
                   end
      
       },
       vb:text{
         text = "       "
       }
       ,

      
        vb:button {
          width = 60,
          height = 20,
          text = "Load",
          notifier = function() --load vst from popup
            --if no value chosen then return
            if vb.views["popup"].value == 1 then  
              return
            end
            local inst_index = renoise.song().selected_instrument_index
            renoise.song().instruments[inst_index].plugin_properties:load_plugin(vst_table[vb.views["popup"].value].path)
            focus_pattern_ed()
             --open editor if preferenced
            if (options.auto_open.value) then -- auto_open then
              if renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_available then
                renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_visible = true
              end
            end   
            closer(my_dialog)
          end
         },
        vb:text{
         text = "Ed."
         },
        --option to auto-open the GUI on Load
        vb:checkbox {
          value =  options.auto_open.value, 
          notifier = function()  options.auto_open.value = not options.auto_open.value end,
          id = "gui check",
        }
     
    }
  }
  
  ----------------------------------------------------------------------------------------------------        
  -- key handler function()  
  ----------------------------------------------------------------------------------------------------
  local string_holder = ""
  local function my_keyhandler_func(dialog, key) 
   -- rprint(key)
      
   local user_input = vb.views["textfield"].value
   --as function is called before the textfield is updated we need to keep track
   --by adding the new character here
   if key.character then
     user_input = vb.views["textfield"].value..key.character
   end
   --remove end character if backspace
   if key.name == "back" then
     user_input = string.sub(vb.views["textfield"].value, 1, (#user_input - 1)) 
   end
   --remove all character if backspace + Ctrl
   if  (key.modifiers == "control" and key.name == "back") then
     user_input = "" 
   end
   
   -------------------------------------
   --function containing loop that checks the current textfield string against 
   --the available targets in the table
   -------------------------------------
    local function loop_to_match()
      
      --set the user_input string to lower case for comparison
      user_input = string.lower(user_input)
      
      --[Loop 1] --Search for popup entries starting with the same letter as the user_input string
      ----------
      local all_characters_match = nil
      local matching_popup_index = nil
      
      for i = 2,#popup_names_table do
        local compared_popup_string = popup_names_table[i]
        --set to lower case
        compared_popup_string = string.lower(compared_popup_string)
        --get the first letter of the pop-up string and the first letter of the user_input (characters 1 to 1)
  
        --[Nested Loop] through user_input string matching letter by letter from first character
        for j = 1, #user_input do
          if string.sub(user_input,j,j) ~= string.sub(compared_popup_string,j,j) then
            all_characters_match = false 
            break
          else
            all_characters_match = true
          end
        end
        if all_characters_match == true then --match found
          --renoise.song().selected_track_index = track
          vb.views["popup"].value = i
          return
        end
      end

      --[Loop 2] --Nothing found in [Loop 1] so Search for any sub strings in the popup that match the user_input
      ----------
      for i = 2,#popup_names_table do --search from 2 so we don`t include "No Match"
        local compared_popup_string = popup_names_table[i]
        --set to lower case
        compared_popup_string = string.lower(compared_popup_string)
        local found_match = string.find(compared_popup_string,user_input)--normal
        if found_match ~= nil then --match found
          vb.views["popup"].value = i
          break
        else --show "No Match" in the popup 
          vb.views["popup"].value = 1                        
        end
      end
    end --end of local function
   ------------------------------------
   ------------------------------------
    
   --exit when escape pressed
   if (key.modifiers == "" and key.name == "esc") then
     closer(my_dialog)
   end
    
    --toggle the GUI checkbox
    if key.name == "f1" or key.name == "f12" then
      vb.views["gui check"].value = (not vb.views["gui check"].value)
      return
    end
    
   --[[ if key.name == "f9" then
      next_empty_instrument_slot()
      return
    end--]]
    
    --clear the textfield on ctrl + back
    if (key.modifiers == "control" and key.name == "back") then
      field_typing= true
      string_holder = ""
      vb.views["textfield"].value = string_holder
      vb.views["popup"].value = 1 --shows "No Match"
        
    --delete last character when back key pressed  
    elseif key.name == "back" then 
      field_typing= true
      local string_minus_1
      string_minus_1 = string.sub(string_holder, 1, (string.len(string_holder)-1))--remove last character from string
      vb.views["textfield"].value = string_minus_1
      string_holder = string_minus_1
      
      if user_input == "" then --all deleted
        vb.views["popup"].value = 1 --shows "No Match"
        return
      end
      --compare textfield to table
      loop_to_match()
    
    --------------------------------------------------------        
    --Execute (load the vst and exit) when return is pressed  
    -------------------------------------------------------- 
    elseif key.name == "return" then
      
      --when "No Match" do nothing and return
      if vb.views["popup"].value == 1 then
        return
      end
         
      --loop to find vst name that matches the textfield
      for i = 1,#popup_names_table do 
        local name_string = popup_names_table[i]
        local name_string_holder = name_string                  
        local found_match = string.find(name_string,user_input)--normal
       
        --if no match found then exit the tool
        if found_match ~= nil then
          local inst_index = renoise.song().selected_instrument_index
          renoise.song().instruments[inst_index].plugin_properties:load_plugin(vst_table[vb.views["popup"].value].path)   
          focus_pattern_ed()
          --open editor if preferenced
          if (options.auto_open.value) then -- auto_open then
            if renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_available then
              renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_visible = true
            end
          end  
          closer(my_dialog)
          break
        else
          name_string = string.lower(name_string) --try lower case
          --load vst here
          if vb.views["popup"].value ~= 1 then
            local inst_index = renoise.song().selected_instrument_index
            renoise.song().instruments[inst_index].plugin_properties:load_plugin(vst_table[vb.views["popup"].value].path)
            focus_pattern_ed()
            --open editor if preferenced
            if (options.auto_open.value) then -- auto_open then
              if renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_available then
                renoise.song().instruments[inst_index].plugin_properties.plugin_device.external_editor_visible = true
              end
            end        
            closer(my_dialog)
            break
          else
            vb.views["popup"].value = 1               
          end --if else
        end--for
      end 
      
    --Upwards Arrow chooses previous popup entry     
    elseif key.name == "down" then --character input
      if vb.views["popup"].value ~= 1 then
        vb.views["popup"].value = vb.views["popup"].value - 1
      end
    
    --down Arrow  chooses next popup entry      
    elseif key.name == "up" then --character input
      if vb.views["popup"].value ~= #popup_names_table then
        vb.views["popup"].value = vb.views["popup"].value + 1 
      end 
      
    --any other character input      
    elseif key.character ~= nil then --character input
      field_typing = true
      string_holder = string_holder..key.character 
      --add character to textfield
      vb.views["textfield"].value = vb.views["textfield"].value..key.character 
      --compare textfield to table
      loop_to_match() 
    end  --elseif "ky chooser
  end                       
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  --Script dialog
  my_dialog = renoise.app():show_custom_dialog(
      "Search VSTi", dialog_content,my_keyhandler_func)
  
  ------------------------------------------------------------------------------------------
  --notifiers
  ------------------------------------------------------------------------------------------
  renoise.tool().app_release_document_observable:add_notifier(closer, my_dialog)
  renoise.song().tracks_observable:add_notifier(closer,my_dialog)
  
end --end of main
-------------------------------------

--keybinding
renoise.tool():add_keybinding {
  name = "Global:Tools:`VFM` Search and Load VSTi",
  invoke = function()search_track()end
  
}
 
