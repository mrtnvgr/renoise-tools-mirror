--Meta Mate v1.0 by Aftab Hussain aka afta8 - fathand@gmail.com - 13th April 2014

--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


--------------------------------------------------------------------------------
-- Global variables & helper functions
--------------------------------------------------------------------------------

-- Global variables
local active = false
local mode = nil
local src_meta_device = {track = nil, device = nil, name = nil}
local target_param = {track = nil, device = nil, param = nil}
local param_n_functions = {}
local bypass_n_functions = {}

-- Track or FX chain pointers
local sel_device = nil
local sel_device_index = nil
local sel_track_index = nil
local tracks = nil
local sel_ins = nil

-- Notifier handler functions
local notifier = {}
  function notifier.add(observable, n_function)
    if not observable:has_notifier(n_function) then
      observable:add_notifier(n_function)
    end
  end

  function notifier.remove(observable, n_function)
    if observable:has_notifier(n_function) then
      observable:remove_notifier(n_function)
    end
  end


--------------------------------------------------------------------------------
-- Meta parameter identification functions - Adapted from Snapshot tool
--------------------------------------------------------------------------------

-- Find parameters currently controlled by another meta device
local meta_params = {} -- Global table of parameters controlled by meta devices
local function find_meta_params()
  
  -- Initialise meta params table
  meta_params = {}
  
  -- Iterate tracks
  for track = 1, #tracks do
    
      -- Iterate devices
      for device = 1, #tracks[track].devices do
        -- Iterate parameters
        for parameter = 1, #tracks[track].devices[device].parameters do
      
            local parameter_object = tracks[track].devices[device].parameters[parameter]            
            -- Check it is a track dest meta parameter 
            if  ( string.find(parameter_object.name, "Dest.") or string.find(parameter_object.name, "Out") ) and string.find(parameter_object.name, "Track") then

              -- Check if the effect is assigned
              local fx_dest = tracks[track].devices[device].parameters[parameter+1]
              if fx_dest.value ~= -1 then

                -- Check if the parameter is assigned
                local param_dest = tracks[track].devices[device].parameters[parameter+2]
                if param_dest.value ~= -1 then
                  
                  -- If there is a valid meta destination record the track, device and parameter number
                  local target_track
                  if parameter_object.value == -1 then -- Because track can be current track
                    target_track = track
                  else
                    target_track = parameter_object.value + 1 -- Otherwise read from assignment in device
                  end
                  
                  local target_device = fx_dest.value + 1                  
                  local target_parameter = param_dest.value

                  meta_params[#meta_params+1] = { track = target_track, device = target_device, param = target_parameter }

                end
              end
            end            
        end    
      end
  end  
end


-- Function to test if a given track, device and parameter are meta controlled
local function is_meta(track, device, param) 
  for n = 1, #meta_params do
    if (meta_params[n].track == track) and (meta_params[n].device == device) and (meta_params[n].param == param) then 
      return true
    end
  end
  return false
end


--------------------------------------------------------------------------------
-- Tool functions 
--------------------------------------------------------------------------------

-- Detect if selected device is a compatible meta device
local function is_meta_device()

  local device = sel_device.name
  
  if (device == "*Signal Follower") or
     (device == "*Key Tracker") or
     (device == "*LFO") or
     (device == "*Meta Mixer") or
     (device == "*Velocity Tracker") or
     (device == "*Formula") or
     
     -- Special cases
     (device == "*Hydra") or
     (device == "*XY Pad") then     
     
    -- Set global variables for source device
    src_meta_device.track = sel_track_index
    src_meta_device.device = sel_device_index
    src_meta_device.name = device
        
    return true

  else
  
    renoise.app():show_status("Select a Meta device before running tool")
    return false
  
  end
  
end


-- Set meta destination using parameters set in global variables
local function set_meta_device()

  local source = tracks[src_meta_device.track].devices[src_meta_device.device]
  
  -- Check if target param track is the same as current track
  if target_param.track == sel_track_index then
    target_param.track = -1 -- Set to current track
  else
    target_param.track = target_param.track - 1 -- Set to target track
  end
  
  -- Check for special case meta devices
  if (src_meta_device.name == "*Hydra") or (src_meta_device.name == "*XY Pad") then
    
    -- Set up first parameter position for scanning
    local start_pos = nil
    if src_meta_device.name == "*Hydra" then start_pos = 3
    elseif src_meta_device.name == "*XY Pad" then start_pos = 4
    end
    
    -- Scan and find first available free destination settng
    local track_param = nil
    for param = start_pos, #source.parameters, 5 do
      if source.parameters[param].value == -1 then -- No device assigned
        track_param = param - 1
        break  
      end  
    end
    
    -- Assign destination settings for Hydra or XY-Pad
    if track_param ~= nil then
      source.parameters[track_param].value = target_param.track 
      source.parameters[track_param+1].value = target_param.device - 1
      source.parameters[track_param+2].value = target_param.param
      renoise.app():show_status("Modulation target has been added to Hydra or XY-Pad")
    else
      renoise.app():show_status("All modulation slots have been used up in this device")    
    end
       
  else -- Assign destination setting for a standard meta device
    source.parameters[1].value = target_param.track
    source.parameters[2].value = target_param.device - 1
    source.parameters[3].value = target_param.param
    renoise.app():show_status("Modulation target has been assigned")
  end

  -- Return focus to source meta device to indicate assignment has been done
  if mode == "Mixer" then
    renoise.song().selected_track_index = src_meta_device.track
    renoise.song().selected_track_device_index = src_meta_device.device
  elseif mode == "Instrument" then
    renoise.song().selected_sample_device_chain_index = src_meta_device.track
    renoise.song().selected_sample_device_index = src_meta_device.device
  end  
  
  active = false
    
end


--------------------------------------------------------------------------------
-- Notifier functions 
--------------------------------------------------------------------------------

-- Remove notifier functions on each device parameter
local function remove_notifiers()
  
  -- Iterate tracks
  for track = 1, #param_n_functions do

    -- Iterate devices
    for device = 1, #param_n_functions[track] do
      -- Remove bypass switch notifiers
      local observable = tracks[track].devices[device].is_active_observable
      notifier.remove(observable, bypass_n_functions[track][device])    

      -- Iterate parameters
      for param = 1, #param_n_functions[track][device] do 
        -- Remove parameter notifiers
        local observable = tracks[track].devices[device].parameters[param].value_observable
        notifier.remove(observable, param_n_functions[track][device][param])
      end -- Parameters

    end -- Device  
  end -- Tracks

  -- Clear notifier functions tables
  param_n_functions = {}
  bypass_n_functions = {}
  
end


-- Create notifier functions to be attached/removed from all device parameters
local function create_param_notifiers()

  -- Iterate tracks
  for track = 1, #tracks do

    param_n_functions[track] = {}    
    -- Iterate devices
    for device = 1, #tracks[track].devices do

      param_n_functions[track][device] = {}
      -- Iterate parameters
      for param = 1, #tracks[track].devices[device].parameters do
        
          -- Set up the notifier function for each parameter
          param_n_functions[track][device][param] = function()          
            -- Check if this notifier is meta controlled already
            if is_meta(track, device, param) == false then          
              -- Set global variables to target parameter for the source meta device
              target_param.track = track
              target_param.device = device
              target_param.param = param            
              -- Remove notifiers
              remove_notifiers()                   
              -- Assign the destinations on the source meta device
              set_meta_device()            
            end -- if              
          end -- Dynamically added Function
              
        -- Attach the notifier functions
        local observable = tracks[track].devices[device].parameters[param].value_observable
        notifier.add(observable, param_n_functions[track][device][param])
        
      end -- Parameters   
    end -- Devices
  end -- Tracks

end


-- Create notifier functions to be attached/removed from all device bypass switches
local function create_bypass_notifiers()

  -- Iterate tracks
  for track = 1, #tracks do

    bypass_n_functions[track] = {}    
    -- Iterate devices
    for device = 1, #tracks[track].devices do
        
        -- Set up the notifier function for each bypass switch
        bypass_n_functions[track][device] = function()          
          -- Check if this notifier is meta controlled already
          if is_meta(track, device, 0) == false then          
            -- Set global variables to target parameter for the source meta device
            target_param.track = track
            target_param.device = device
            target_param.param = 0            
            -- Remove notifiers
            remove_notifiers()                    
            -- Assign the destinations on the source meta device
            set_meta_device()            
          end -- if              
        end -- Dynamically added Function
              
        -- Attach the notifier functions
        local observable = tracks[track].devices[device].is_active_observable
        notifier.add(observable, bypass_n_functions[track][device])
        
    end -- Devices
  end -- Tracks

end


--------------------------------------------------------------------------------
-- Invoke functions
--------------------------------------------------------------------------------

-- Main invoke
local function main()

  local function execute()
    if is_meta_device() then
      find_meta_params()
      create_param_notifiers()
      create_bypass_notifiers()
      active = true
      renoise.app():show_status("Select target parameter")  
    end
  end
  
  -- Check tool is not already running (Notifiers active)
  if active == false then   
   
    -- Set track or instrument context
    if renoise.app().window.active_middle_frame == 7 then -- Working on instrument fx

      mode = "Instrument"
      sel_ins = renoise.song().selected_instrument_index
      sel_device = renoise.song().selected_sample_device
      sel_device_index = renoise.song().selected_sample_device_index
      sel_track_index = renoise.song().selected_sample_device_chain_index
      tracks = renoise.song().instruments[sel_ins].sample_device_chains
      if (sel_track_index ~= 0) and (sel_device ~= nil) then 
        execute()
      else
        renoise.app():show_status("Select a Meta device before running tool")
      end  
    
    elseif renoise.app().window.active_middle_frame <= 2 then -- Working on track dsp's

      mode = "Mixer"
      sel_device = renoise.song().selected_track_device
      sel_device_index = renoise.song().selected_track_device_index
      sel_track_index = renoise.song().selected_track_index
      tracks = renoise.song().tracks
      execute()

    else

      mode = nil
      renoise.app():show_message("Meta Mate will only work if Track or Instrument DSP views are visible")

    end

  else
  
    renoise.app():show_status("Meta mate is already running, select a destination parameter")
  
  end
      
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "DSP Device:"..tool_name.."...",
  invoke = main  
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = main
}


