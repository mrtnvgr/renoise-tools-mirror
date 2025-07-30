--class covers most of this script

class 'Groove'

--constructor 
function Groove:__init()

  --(encapsulation?) 
  --private PROPERTIES
  self.__dialog_title = "Groove Control"
  self.__vb = nil
  self.__dialog = nil
  self.__dialog_content = nil

  --calls add_menu() (note you need to call other class functions with "SELF" 'pointer' not Groove:add_menu()
  --SEE invoke = "function() self:show_gui() end" below )
  self:add_menu()
end

--METHODS (functions
---------------------)
function Groove:add_menu()
  --check if menu entry has already been added
  if not renoise.tool():has_menu_entry("Main Menu:Tools:Ledger`s Scripts:Groove Control") then
    --add the menu entry
    renoise.tool():add_menu_entry {
      name = "Main Menu:Tools:Ledger`s Scripts:Groove Control",
      invoke = function() self:show_gui() end
    } 
  end
  --check if keybinding has been added
  if not renoise.tool():has_keybinding("Main Menu:Tools:Ledger`s Scripts:Groove Control") then
    --add the key binding
    renoise.tool():add_keybinding {
      name = "Global:Tools:Groove Control",
    invoke = function() a:show_gui() end
   } 
  end 
end

function Groove:show_gui()

  --check if dialog exists, if it does then close it (acts as toggle)
  if self.__dialog and  self.__dialog.visible then
    self.__dialog:close() 
   return
  end

  --assign viewbuilder
  self.__vb = renoise.ViewBuilder()
 
  --get the percentage of the first groove slider. We set the  initialtext value from this
  local slider_one_value = renoise.song().transport.groove_amounts[1]
  
  --focus pattern editor
  local function focus_pattern_ed()
    renoise.app().window.lock_keyboard_focus = false
    renoise.app().window.lock_keyboard_focus = true
  end

  --local rounding function
  local function round(value)
    value = value * 100
    value =  math.floor(value + 0.5)
  return  value / 100
  end
  
  local function groove_state()
    if renoise.song().transport.groove_enabled then
      return 1
    else
      return 2
    end
  end
  
  ---------------------------------------------------------------------------
  --DOESN`T WORK SO SPACER BELOW
  --determines spaces when initial slider value is added to text field
  local function aligned_precentage(value)
    --multiply by 100 for percentage
    value = value * 100
    local spaces = ""
    
    if (value <= 99) and (value >= 10) then
      spaces = " "
    elseif value <= 11 then
      spaces ="  "
    end
    --return the aligned percentage as a string
    return tostring(value.."%"..spaces)
   end
   
   --------------------------------------------------------------------------------------
    --Function that converts the percentage of the groove slider
    --to the equivalent pattern note delay value (every second 16th note). returns string
    local function convert_pc_to_sixteenth_delay()
      
      --get the groove slider percentage
      local groove_percent = renoise.song().transport.groove_amounts[1]
      --the renoise groove sliders range of 100% seem to covers a range of
      --0% to 66% of the delay range.  The full delay range is FF hex (256 decimal) so 66% is rounded to 170
      local RENOISE_GROOVE_MAX = 170
      
      --scale to 170 ((66%) three quarters of the 256 max delay range)
      local scaled_groove = 100 * (groove_percent/100) * RENOISE_GROOVE_MAX
      --scale to LPB value (default is 4)
      scaled_groove = scaled_groove * (renoise.song().transport.lpb/4)
      --convert to the hex value to show what would be typed into the pattern delay column
      --on every 16th note
      return string.format("%X", scaled_groove)
      
    end
    --------------------------------------------------------------------------------------
  --Function to convert renoise swing percentage to a Linn Drum equivalent (the first drum machine to implement swing in 1979) 
  --In a Linn Drum the swing values range from 50% to 100%
  --The 50% start value means equal time for the first sixteenth note and the second sixteenth note. i.e. 1 vs 2 and 2 vs 4 (of 16)
  --In renoise this is counted as 0% start value.  The renoise range
  --covers from Linns 50% to [[[87.5%]]]] (only three quarters of the Linns full range)
  --The following function accounts for all these factors

  local function convert_renoise_pc_to_Linn_pc()
    
    --get the groove slider percentage
    local groove_percent = renoise.song().transport.groove_amounts[1]
    
    local RENOISE_GROOVE_RANGE = (100/66) --slider covers 66% of a 16th note
    local SCALE_FACTOR = RENOISE_GROOVE_RANGE * 2 --Linns theoretical 0-100% range covers two 16th notes so multiply by 2
    local LINN_RANGE_START_PERCENTAGE = 50 --Linn starts at 50% so we add this at the end of the calculation
                                           
    --scale then * 100 for percent.
    groove_percent =  ((groove_percent / SCALE_FACTOR) * 100) + LINN_RANGE_START_PERCENTAGE
    
   --for drum machines that use Linn groove but start at 0% 
   -- local adjusted_groove = groove_percent / 2
   -- adjusted_groove = string.format("%.1f",adjusted_groove)
   
  -- return (string.format("%.1f",groove_percent).."% ".."["..adjusted_groove.."]") --format to 1dp
    return (string.format("%.1f",groove_percent).."%") --format to 1dp
  end

  
  
  slider_one_value = round(slider_one_value)

  -- The content of the dialog, built with the ViewBuilder.
  self.dialog__content = self.__vb:column {
    margin = 10,
      self.__vb:horizontal_aligner{
        mode = "left",
        margin = 4,
        self.__vb:checkbox{
        bind = renoise.song().transport.groove_enabled_observable,
        notifier = function() focus_pattern_ed() end           
       },
       self.__vb:text{
         text = "Groove Enabled         ", --spacer as doing dynamically with text didn`t seem to work
                                           --(the local function marked DOESN`T WORK above)
       },
       self.__vb:button{
         text = "Mst",
         notifier = function() --go to master track
                    local rns = renoise.song()
                    for i = 1,#rns.tracks do
                      if rns.tracks[i].type == renoise.Track.TRACK_TYPE_MASTER then
                        --set selected track to master
                        rns.selected_track_index = i
                        --select last device in master chain (NOT ABLE TO CHOOSE MASTER SO LEFT OUT)
                       -- rns.selected_device_index = #rns.tracks[i].devices
                      end
                    end
                  end
       } 
    },--horizontal aligner end
    self.__vb:row {
      margin = 4,
      self.__vb:slider {
        value = renoise.song().transport.groove_amounts[1],
        notifier = function(value)
           --round the value
           value = round(value)
           --fill table with the same vales fo all 4 sliders
           local groove_table = {value,value,value,value}
           --update the renoise groove sliders
           renoise.song().transport.groove_amounts = groove_table 
           --update the text
           self.__vb.views["text"].text = aligned_precentage(value)
           --update hex text
           self.__vb.views["hex_text"].text = " 16th Note Delay: "..convert_pc_to_sixteenth_delay()
           --update Linn text
           self.__vb.views["Linn_text"].text = " Drum Machine: "..convert_renoise_pc_to_Linn_pc()
           --focus the pattern editor
           focus_pattern_ed() 
         end
        }, 
        self.__vb:text {
          id = "text",
          text = aligned_precentage(slider_one_value),
          font = "bold"
          }
      },--end of row 1
     
      self.__vb:text{
        id = "hex_text",
        text = " 16th Note Delay: "..convert_pc_to_sixteenth_delay()
      },
      
      self.__vb:text{
        id = "Linn_text",
        text = " Drum Machine: "..convert_renoise_pc_to_Linn_pc()
      },
      
      
    
    }--end of column
    
  --key Handler
  local function my_keyhandler_func(dialog,key)
  
     --always focus the pattern editor so renoise responds to key input
     renoise.app().window.lock_keyboard_focus = false
     renoise.app().window.lock_keyboard_focus = true
  
     --if escape pressed then close the dialog else return key to renoise
     if not (key.modifiers == "" and key.name == "esc") then
        return key
     else
       dialog:close()
     end
  end     
  
  --adds dialog object to the class as Groove.__dialog 
  --show dialog
  self.__dialog = renoise.app():show_custom_dialog(self.__dialog_title, self.dialog__content,my_keyhandler_func) 
  
  --notifier
  
  --update_on_lpb (has to be local or scoped with--- self:update_on_lpb())
  local function update_on_lpb()
    self.__vb.views["hex_text"].text = " 16th Note Delay: "..convert_pc_to_sixteenth_delay()
  end
  
  --add lpb change notifier (released automatically on tool close?)
  --anonymous function used instead of a global?
  if not renoise.song().transport.lpb_observable:has_notifier(function() update_on_lpb() end) then
    renoise.song().transport.lpb_observable:add_notifier(function() update_on_lpb() end)
  end


end --sho_gui()

-----------------------------------------------
--End of Class 'Groove'
-----------------------------------------------


------------------------------------------------------------
-- Debug print
function dbug(msg)
  local base_types = {
    ["nil"]=true, ["boolean"]=true, ["number"]=true,
    ["string"]=true, ["thread"]=true, ["table"]=true
  }
  --if key doesn`t exist then..
  if not base_types[type(msg)] then oprint(msg)
  elseif type(msg) == 'table' then rprint(msg)
  else print(msg) end
end
-------------------------------------------
-----------------------------------------------
--Declare object on renoise startup --adds menu
-----------------------------------------------
a  = Groove()

--------------------------------------------------------------
--notifier to close GUI
--------------------------------------------------------------



--Global function to close the GUI
function closer(a)

  if not a then 
    return
  end
  if a.__dialog and  a.__dialog.visible then
    a.__dialog:close()
  end
end  

--Notifiers need to Attach to a global function
--notifier closes GUI on closing renoise song
--"a" "must be table or class" --it gets passed to closer(a)
renoise.tool().app_release_document_observable:add_notifier(closer,a) 

--------------------------------------------------------------


                                                    


