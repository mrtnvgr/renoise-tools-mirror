-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--functions called when the [G] "Grab" button is pressed on the GUI of the tool
--or to cancel/ clear those grab notifiers added to Plugin Parameters in the timer
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--[G] CANCEL GRAB BUTTON function
----------------------------------------
--called in TIMER and DEVICE POPUP when selected device has changed to cancel the user initiated grab 
--of parameter indexes; [G] BUTTON ON GUI
-------------------------------------------
function cancel_grab_notifiers()

  --do nothing if table doesn`t exist
  if grab_button_available_params == nil then
    return
  end
  
  --remove all notifiers if still attached
  for i = 1,(#grab_button_available_params - 1) do -- -1 as the last index contains the parent device (reference) itelf
    --remove notifier for each parameter
    if grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
      grab_button_available_params[i].value_observable:remove_notifier(select_index_table[i])
    end
  end
  --reset global table of params to nil
  grab_button_available_params = nil
  --2) clear table of functions to pass to notifiers
  select_index_table = {}
  --set the button to grey in case the next conditional fails--default color 
  vb.views["grab param button"].color = COLOR_GREY
end

----------------------------------------------------------------------------
--[G] GRAB BUTTON function (fx)
--added to notifiers for watching a plugins parameters for movements/changes 
----------------------------------------------------------------------------
function select_index(index)
  
  local song = renoise.song()
  
  if grab_button_available_params == nil then
    return
  end
  
  --last index contains parent device object reference
  local last_index = #grab_button_available_params 
  --set the button to grey in case the next conditional fails--default color 
    vb.views["grab param button"].color = COLOR_GREY
  
  --check if the last parameter[index] contains a reference to the currently selected device; if so then set the parameter
  --if not then skip and remove the notifiers as we have moved to a new selected device
  if rawequal(song.selected_automation_device,grab_button_available_params[last_index]) ~= false then
     --set the selected automation                  
    song.selected_automation_parameter = grab_button_available_params[index]
     --status
    status("Selected:    "..grab_button_available_params[index].name)
    --set button to green
    vb.views["grab param button"].color = COLOR_GREEN
    --reset counter for the timer that turns the color back to GREY after some timer iterations.
     t_counter = 0
  end 
 
  --release the notifiers as we only need one of them to fire once
    --remove all notifiers if still attached
  for i = 1,(#grab_button_available_params - 1) do -- -1 as the last index contains the parent device (reference) itelf
    --remove notifier for each parameter
    if grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
      grab_button_available_params[i].value_observable:remove_notifier(select_index_table[i])
    end
  end
  --reset global table of params to nil
  grab_button_available_params = nil
  --2) clear table of functions to pass to notifiers
  select_index_table = {} 
end


----------------------------------------------
--[G] GRAB BUTTON function (instruments)
----------------------------------------------
function select_index_instrument(index)

  --TODO NEEDS TESTS
  local song = renoise.song()
  
  if grab_button_available_params == nil then
    return
  end
  
  --last index contains parent device object reference
  local last_index = #grab_button_available_params 
  --set the button to grey in case the next conditional fails--default color 
   vb.views["grab param button"].color = COLOR_GREY
   
  --check if the last parameter[index] contains a reference to the currently selected device; if so then set the parameter
  --if not then skip and remove the notifiers as we have moved to a new selected device
  ---------------------------------------------------------------------------------------
  if rawequal(song.selected_automation_device,grab_button_available_params[last_index]) ~= false then
    
    --instr.auto device poppups that show the target parameter can only be changed via changing the .active_preset_data .xml
    -- we deal with this here:

    --get preset from selected parameter (inst auto device)
    local preset_xml_string = song.selected_automation_device.active_preset_data
    --inst param first unautomated
    local inst_device_first_free_param = nil
    local parameter_already_assigned_to_popup = false
    
    --loop through inst. auto devices current preset and get the plugin parameters being pointed to
    for i = 1,#song.selected_automation_device.parameters do --35 parameters
      
      local current_num_string = nil
      --get parmater assignments using string.match, count will increment with loop
      --param_number>digits</  [count = param_number], [(%d+) = pattern of digits],[/ = /]
      current_num_string = string.match(preset_xml_string, (i-1)..'>(%d+)</') 
  
      --check that the moved parameter is not an already present selection in one of the popups of the instr. automation device
      if (index - 1) == tonumber(current_num_string) then
        --if it is just set the selected_parameter to this (it is already assigned to target plugin parameter)
        song.selected_automation_parameter = song.selected_track_device.parameters[i]
        --get this index so we can swap parameter assignments later
        parameter_already_assigned_to_popup = (i - 1)
      end
    end
    
    if (parameter_already_assigned_to_popup == false) then
    
      --loop to get first unautomated popup/parameter in device
      for i = 1,#song.selected_automation_device.parameters do 
        --if the target parameter in the VSTi is not automated then we have an available slot in the automation device
        if (not song.selected_automation_device:parameter(i).is_automated) then
          --decrement i to match with Lua (off by one)
          inst_device_first_free_param = (i-1)
          break
        end
      end
      
            
      ---IF inst_device_first_free_param == nil then no free parameters ADD A NEW DEVICE HERE TODO?????
      --------------------------------------------------------------------------------------
      
      --2)set the first unautomated parameter via the modified xml preset string to the newly captured VSTi parameter
      preset_xml_string = string.gsub(preset_xml_string, inst_device_first_free_param..'>(%d+)</', inst_device_first_free_param..'>'..tostring(index-1)..'</',1)

        --load the modified preset
      song.selected_automation_device.active_preset_data = preset_xml_string
  
      --select the relevant automation parameter in the automation list
      -----------------------------------------------------------------
      song.selected_automation_parameter = song.selected_track_device.parameters[inst_device_first_free_param+1]
    end
    
    
  
    --MAKE SURE TOOL GUI UPDATES PROPERLY
    --------------------------------------
    --flag as parameter change as if the same parameter index is still selected, it will not update the name properly otherwise
    stored_selected_automation_parameter = nil 
     
    --RENOISE HACK TO UPDATE SELECTED PARAMETER --THE AUTOMATION LANE HAS TO BE FOCUSED AFTER THE XML PRESET IS LOADED IN ORDER TO UPDATE
    --THE AUTOMATION LIST PARAMETER NAMES WHICH BECAME CHANGED BY THE XML.  lower_frame could store empty view too
    local lower_frame = renoise.app().window.active_lower_frame 
    if renoise.app().window.active_lower_frame == renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS then
      renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
      renoise.app().window.active_lower_frame = lower_frame
    else
      renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
      renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
      renoise.app().window.active_lower_frame = lower_frame
    end
    -----------------------------------
  
  
  
    --if the new parameter name doesn`t match the name of the vsti give the user a warning dialog that the grab failed
    ------------------------------------------------------------------------------------------------------------------
    if song.selected_automation_parameter.name ~= song.selected_instrument.plugin_properties.plugin_device:parameter(index).name then
      local device_selected_name = song.selected_automation_parameter.name
      local instr_param_name = song.selected_instrument.plugin_properties.plugin_device:parameter(index).name
      renoise.app():show_warning( "Grab Failed!\n\nParameter Names Do Not Match,\nCheck The Instr. Automation Device\nIs Targeting The Selected Renoise Instrument\n\nMis-Matched Names:  (1.Plugin / 2. Inst.Auto Device)\n\n".."1. "..instr_param_name.."\n".."2. "..device_selected_name)
      
    end

    
    -- set button to green
    vb.views["grab param button"].color = COLOR_GREEN
    --reset counter for the timer that turns the color back to GREY after some timer iterations.
    t_counter = 0
  end 
    --release the notifiers as we only need one of them to fire once
    --remove all notifiers if still attached
  for i = 1,(#grab_button_available_params - 1) do -- -1 as the last index contains the parent device (reference) itelf
    --remove notifier for each parameter
    if grab_button_available_params[i].value_observable:has_notifier(select_index_table[i]) then
      grab_button_available_params[i].value_observable:remove_notifier(select_index_table[i])
    end
  end
  --reset global table of params to nil
  grab_button_available_params = nil
  --2) clear table of functions to pass to notifiers
  select_index_table = {} 
  
end


--[[ --UNUSED
-------------------------------------------------------
--iterates current track to see if selected vsti/plugin instrument
--has notes there.  If not the target instrument of the automation device
--may be the correct selection
---------------------------------------------------------
function check_selected_plugin_present_on_current_track()
  
  local song = renoise.song()
  local pattern_iter = song.pattern_iterator
  local track_index = song.selected_track_index
  local inst_index = song.selected_instrument_index
  
  --loop and return true if 
  for pos,line in pattern_iter:note_columns_in_track(track_index) do                      
    -- +1 as insts count from 00
    if ((line.instrument_value + 1) == inst_index) then --> docs--[instrument_value, 0-254, 255==Empty]
      return true
    end
  end
  --instrument not found
  return false
end
--]]



--[[
-------------------------------------------------
-------------------------------------------------
EXAMPLE PRESET DATA FOR `INSTR. AUTOMATION DEVICE`
-------------------------------------------------
-------------------------------------------------
>1<
>17<
:values are the plugin device parameter indexes that are being pointed to

use: '>(%d+)</'  ----means one or more numbers (digits) between `>` and `<` symbols.  See Lua docs re: (%d+),for captures and patterns etc.

example:
1) Find-----  string.match(active_preset_data, 7..'>(%d+)</')           
--means get parameter 7 value

2) Replace--  string.gsub(active_preset_data,7..'>(%d+)</','>152</',1)  
--means replace parameter 7 value with 152  --,1 means only do one substitution then return, otherwise 17 and 27 would get cahnged too.

--------------------------------------------------
--------------------------------------------------
--example preset data
renoise.song().selected_track_device.active_preset_data =

<?xml version="1.0" encoding="UTF-8"?>
<FilterDevicePreset doc_version="10">
  <DeviceSlot type="InstrumentAutomationDevice">
    <IsMaximized>true</IsMaximized>
    <ParameterNumber0>0</ParameterNumber0>
    <ParameterNumber1>1</ParameterNumber1>
    <ParameterNumber2>2</ParameterNumber2>
    <ParameterNumber3>3</ParameterNumber3>
    <ParameterNumber4>4</ParameterNumber4>
    <ParameterNumber5>5</ParameterNumber5>
    <ParameterNumber6>6</ParameterNumber6>
    <ParameterNumber7>7</ParameterNumber7>
    <ParameterNumber8>8</ParameterNumber8>
    <ParameterNumber9>9</ParameterNumber9>
    <ParameterNumber10>10</ParameterNumber10>
    <ParameterNumber11>11</ParameterNumber11>
    <ParameterNumber12>12</ParameterNumber12>
    <ParameterNumber13>13</ParameterNumber13>
    <ParameterNumber14>14</ParameterNumber14>
    <ParameterNumber15>15</ParameterNumber15>
    <ParameterNumber16>16</ParameterNumber16>
    <ParameterNumber17>17</ParameterNumber17>
    <ParameterNumber18>18</ParameterNumber18>
    <ParameterNumber19>19</ParameterNumber19>
    <ParameterNumber20>20</ParameterNumber20>
    <ParameterNumber21>21</ParameterNumber21>
    <ParameterNumber22>22</ParameterNumber22>
    <ParameterNumber23>23</ParameterNumber23>
    <ParameterNumber24>24</ParameterNumber24>
    <ParameterNumber25>25</ParameterNumber25>
    <ParameterNumber26>26</ParameterNumber26>
    <ParameterNumber27>27</ParameterNumber27>
    <ParameterNumber28>28</ParameterNumber28>
    <ParameterNumber29>29</ParameterNumber29>
    <ParameterNumber30>30</ParameterNumber30>
    <ParameterNumber31>31</ParameterNumber31>
    <ParameterNumber32>32</ParameterNumber32>
    <ParameterNumber33>33</ParameterNumber33>
    <ParameterNumber34>34</ParameterNumber34>
    <VisiblePages>1</VisiblePages>
  </DeviceSlot>
</FilterDevicePreset>

--]]
