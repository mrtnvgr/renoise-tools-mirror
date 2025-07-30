--LOCK Keyboard Focus FIXED



------------------------------------------------

local my_dialog = nil

-------------------------------------------------------------------------------------------
--Main
-------------------------------------------------------------------------------------------
function search_fx()

  -------------------------------------------------------------------------------------------
  --local functions
  -------------------------------------------------------------------------------------------
  
  --generic handler which accepts an optional parameter for dialog
  local function closer(d)
    
    if d then
    --renoise.song().tracks_observable:remove_notifier(closer,my_dialog) --remove notifiers
    --renoise.tool().app_release_document_observable:remove_notifier(closer, my_dialog)   
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
  
  --get available plugin infos--short names will be copied to names table, path used to luad plugin
  local rns_track_device_infos = renoise.song().tracks[1].available_device_infos 

  --This is the list of strings that will appear in the pop-up
  local popup_names_table = {}
  
  --populate table with the plugin short names
  for i = 1,#rns_track_device_infos do
    popup_names_table[i] = rns_track_device_infos[i].short_name
  end
  
  --add a "No Match" field to the beginning
  table.insert(popup_names_table,1,"No Match")
  --add a blank entry to vst table as we need the indexes to match
  table.insert(rns_track_device_infos,1,{})
  
  ---------------------------------------------------
  --load VST fx on execution
  ---------------------------------------------------
  --loads effext at last position in the dsp cahin  
  local function load_vst(fx_index) --fx_index is the table index for the plugin
    --get total devices in current tracks chain
    local track = renoise.song().selected_track_index
    local track_device_total = #renoise.song().selected_track.devices
    local current_track = renoise.song().tracks[track]
    local song = renoise.song()

    --load into sample ed
    if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS then
    
      local chain = song.selected_sample_device_chain
      local dev = chain:insert_device_at(rns_track_device_infos[fx_index].path, (#chain.devices + 1))
      --select device
      song.selected_sample_device_index = (#chain.devices)
      --open editor if preferenced
      if (options.auto_open_fx.value) then -- auto_open then
        if dev.external_editor_available then
          dev.external_editor_visible = true
        end
      end 
    else --load to track
      current_track:insert_device_at(rns_track_device_infos[fx_index].path, (track_device_total + 1))
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
  ----------------------------------------------------------------------------
  --see what the longest name in the search list to set the GUI popup width by
  ----------------------------------------------------------------------------
  local function get_longest_name()
   --set name length to 1
   local name_length = 1
   --loop to set to longest string
   for i = 1, #popup_names_table do --including ([1] "No Match")
     if popup_names_table[i]:len() > name_length then
       name_length = popup_names_table[i]:len()
     end
   end
   --multiply the name by 7 (rough average of pixels per character)
   return (name_length * 7)
  end
  
  local longest_name = get_longest_name()
   
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
    width = longest_name,
    },
                            
    vb:popup {
    id = "popup",
    width = longest_name, 
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
      mode = "center",
      vb:button {
        width = 60,
        height = 20,
        text = "Load",
        notifier = function() --load vst from popup
          --if no value chosen then return           
          if vb.views["popup"].value == 1 then  
            return
          end
          --load selected vst in popup
          load_vst(vb.views["popup"].value)
          --focus pattern editor
          focus_pattern_ed()
          --close the GUI
          closer(my_dialog)
        end
      },
      vb:text{
       text = "Ed."
      },
      --option to auto-open the GUI on Load
      vb:checkbox {
        value =  options.auto_open_fx.value, 
        notifier = function()  options.auto_open_fx.value = not options.auto_open_fx.value end,
        id = "gui check",
      }
    }
  }
  
  ----------------------------------------------------------------------------------------------------        
  -- key handler function()  
  ----------------------------------------------------------------------------------------------------
  local string_holder = ""
  ----------------------------------------------------------------------------------------------------
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
    
    --clear the textfield on ctrl + back
    if (key.modifiers == "control" and key.name == "back") then
      string_holder = ""
      vb.views["textfield"].value = string_holder
      vb.views["popup"].value = 1 --shows "No Match"
        
    --delete last character when back key pressed  
    elseif key.name == "back" then 
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
           --if no value chosen then return           
          if vb.views["popup"].value == 1 then  
            return
          end
          --load selected vst in popup
          load_vst(vb.views["popup"].value)
          --focus pattern editor
          focus_pattern_ed()
          --close the GUI
          closer(my_dialog)
          break
        else
          name_string = string.lower(name_string) --try lower case
          --load vst here
          if vb.views["popup"].value ~= 1 then        
          --load selected vst in popup
          load_vst(vb.views["popup"].value)
          --focus pattern editor
          focus_pattern_ed()
          --close the GUI
          closer(my_dialog)      
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
      "Search FX", dialog_content,my_keyhandler_func)
  
  ------------------------------------------------------------------------------------------
  --notifiers
  ------------------------------------------------------------------------------------------
  renoise.tool().app_release_document_observable:add_notifier(closer, my_dialog)
  renoise.song().tracks_observable:add_notifier(closer,my_dialog)
  
end --end of main
-------------------------------------

--keybinding
renoise.tool():add_keybinding {
  name = "Global:Tools:`VFM` Search and Load FX",
  invoke = function()search_fx()end
  
}
 
