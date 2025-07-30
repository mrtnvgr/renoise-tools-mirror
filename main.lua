-- Multi Volume v0.4 by Aftab Hussain aka afta8 (fathand@gmail.com) - 9th April 2014

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


----------------
-- Initialise --
----------------

-- Set up preferences
local options = renoise.Document.create("ScriptingToolPreferences") {
  always_on = false,
  enable_pre = false
}
renoise.tool().preferences = options

-- Global variables
local active_status = false
local tracks_table = nil
local postfx_init_volumes = nil
local postfx_n_functions = nil
local prefx_init_volumes = nil
local prefx_n_functions = nil
local rs

-----------------------
-- Utility functions --
-----------------------
 
-- Function to clamp values
local function clamp_value(input, min_val, max_val)
  return math.min(math.max(input, min_val), max_val)
end

-- Count the number of times a value occurs in a table 
local function table_count(tt, item)
  local count = 0
  for ii,xx in pairs(tt) do
    if xx == item then count = count + 1 end
  end
  return count
end

-- Check if two tables are equal
local function equal(tbl1,tbl2)
  for k,v in pairs(tbl1) do
    if tbl2[k] ~= v then
      return false
    end
  end
  return true
end

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

-- Returns a table of currently selected tracks in pattern matrix
local function selected_tracks()
  local selected = {} -- Table to hold track numbers
  local num_tracks = #rs.tracks 
  local num_seqs = #rs.sequencer.pattern_sequence 
  local count = 1
  -- Loop through sequences
  for s = 1, num_seqs do
    -- Loop through tracks and check if selected
    for t = 1, num_tracks do
      if rs.sequencer:track_sequence_slot_is_selected(t, s) then 
        if table_count(selected, t) == 0 then -- Check for duplicates
          selected[count] = t
          count = count + 1
        end
      end
    end  
  end
  return selected
end


-----------------------------------------
-- Functions for Post FX volume faders --
-----------------------------------------

-- Returns a table of corresponding volumes from a table of track numbers
local function postfx_track_volumes(tracks)
  local volumes = {}
  for t = 1, #tracks do
    volumes[t] = math.lin2db(rs.tracks[tracks[t]].postfx_volume.value)
  end
  return volumes
end

-- Refresh volumes
local function postfx_volume_refresh(tracks, amount, skip)
  for t = 1, #tracks do
    if t ~= skip then
      local new_vol = math.db2lin(postfx_init_volumes[t] + amount)
      rs.tracks[tracks[t]].postfx_volume.value = clamp_value(new_vol, 0, 1.4)
    end
  end
end

-- Add & remove notifiers on post fx volumes for a table of track numbers 
local function add_postfx_vol_notifiers(tracks, n_functions, skip)      
  for t = 1, #tracks do
    if t ~= skip then
      local observable = rs.tracks[tracks[t]].postfx_volume.value_observable  
      notifier.add(observable, n_functions[t])
    end
  end        
end

local function remove_postfx_vol_notifiers(tracks, n_functions, skip)
  for t = 1, #tracks do
    if t ~= skip then
      local observable = rs.tracks[tracks[t]].postfx_volume.value_observable  
      notifier.remove(observable, n_functions[t])
    end
  end
end

-- Returns a table of notifier trigger functions for use in dynamically created notifiers
local function create_postfx_n_functions(tracks)
  local functions = {}
  for n = 1, #tracks do
    -- The template function
    functions[n] = function()
      remove_postfx_vol_notifiers(tracks, postfx_n_functions, n) -- Remove notifiers on all faders except currently selected (prevents notifier feedback loop)
      local diff = math.lin2db(rs.tracks[tracks[n]].postfx_volume.value) - postfx_init_volumes[n] -- Work out difference in volume
      postfx_volume_refresh(tracks, diff, n) -- Apply new volume to faders      
      add_postfx_vol_notifiers(tracks, postfx_n_functions, n) -- Add previously removed notifiers
    end
    -- End template function
  end
  return functions
end


----------------------------------------
-- Functions for Pre FX volume faders --
----------------------------------------

-- Returns a table of corresponding volumes from a table of track numbers
local function prefx_track_volumes(tracks)
  local volumes = {}
  for t = 1, #tracks do
    volumes[t] = math.lin2db(rs.tracks[tracks[t]].prefx_volume.value)
  end
  return volumes
end

-- Refresh volumes
local function prefx_volume_refresh(tracks, amount, skip)
  for t = 1, #tracks do
    if t ~= skip then
      local new_vol = math.db2lin(prefx_init_volumes[t] + amount)
      rs.tracks[tracks[t]].prefx_volume.value = clamp_value(new_vol, 0, 1.4)
    end
  end
end

-- Add & remove notifiers on pre fx volumes for a table of track numbers 
local function add_prefx_vol_notifiers(tracks, n_functions, skip)      
  for t = 1, #tracks do
    if t ~= skip then
      local observable = rs.tracks[tracks[t]].prefx_volume.value_observable  
      notifier.add(observable, n_functions[t])
    end
  end        
end

local function remove_prefx_vol_notifiers(tracks, n_functions, skip)
  for t = 1, #tracks do
    if t ~= skip then
      local observable = rs.tracks[tracks[t]].prefx_volume.value_observable  
      notifier.remove(observable, n_functions[t])
    end
  end
end

-- Returns a table of notifier trigger functions for use in dynamically created notifiers
local function create_prefx_n_functions(tracks)
  local functions = {}
  for n = 1, #tracks do  
    -- The template function
    functions[n] = function()
      remove_prefx_vol_notifiers(tracks, prefx_n_functions, n) -- Remove notifiers on all faders except currently selected (prevents notifier feedback loop)
      local diff = math.lin2db( rs.tracks[tracks[n]].prefx_volume.value ) - prefx_init_volumes[n] -- Work out difference in volume
      prefx_volume_refresh(tracks, diff, n) -- Apply new volume to faders      
      add_prefx_vol_notifiers(tracks, prefx_n_functions, n) -- Add previously removed notifiers
    end
    -- End template function
  end
  return functions
end


-----------------------
-- Control Functions --
-----------------------

-- Initialise and start/stop notifiers on selected volume controls
local function activate()
  tracks_table = selected_tracks()

  postfx_init_volumes = postfx_track_volumes(tracks_table)
  postfx_n_functions = create_postfx_n_functions(tracks_table)
  add_postfx_vol_notifiers(tracks_table, postfx_n_functions)  
  
  if options.enable_pre.value then -- Enable pre fx faders if preferences set
    prefx_init_volumes = prefx_track_volumes(tracks_table)
    prefx_n_functions = create_prefx_n_functions(tracks_table)
    add_prefx_vol_notifiers(tracks_table, prefx_n_functions)  
  end  
end


local function deactivate()
  remove_postfx_vol_notifiers(tracks_table, postfx_n_functions)
  if options.enable_pre.value then -- Enable pre fx faders if preferences set
    remove_prefx_vol_notifiers(tracks_table, prefx_n_functions)
  end
end

-- Function triggered by app idle notifiers (detects when track selection changes)
local function check_selection()
  if not equal(selected_tracks(), tracks_table) then
    deactivate()
    activate()
  end
end

-- App idle notifier functions that observe for changes in track selection
local function run_selection_observer()
  if not (renoise.tool().app_idle_observable:has_notifier(check_selection)) then
    renoise.tool().app_idle_observable:add_notifier(check_selection)
  end
end

local function stop_selection_observer()
  if (renoise.tool().app_idle_observable:has_notifier(check_selection)) then
    renoise.tool().app_idle_observable:remove_notifier(check_selection)
  end
end

-- Tool on/off triggers
local function stop_tool()
  if active_status then -- Only if tool already running
    stop_selection_observer()
    deactivate()
    renoise.app():show_status("Multi Volume Disabled")
    active_status = false
  end
end

local function start_tool()
  if active_status then stop_tool() end -- Stops tool first if already running
  activate()
  run_selection_observer()
  renoise.app():show_status("Multi Volume Enabled")
  active_status = true
end


-----------------------------------------------------------
-- Song Opening/Closing and background running functions --
-----------------------------------------------------------

-- Set up observables
local new_doc_observable = renoise.tool().app_new_document_observable
local close_doc_observable = renoise.tool().app_release_document_observable

-- Open/New song notifier trigger function
local function open_song()
  rs = renoise.song()
  if options.always_on.value then start_tool() end -- Runs the tool if preferences set
end

-- Close song notifier trigger function
local function close_song()
  stop_tool()
end

-- Add the notifiers (always running in background)
notifier.add(new_doc_observable, open_song)
notifier.add(close_doc_observable, close_song)


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()

  -- GUI elements
  local always_on_row = vb:row {
    vb:text {
      text = "Background enable  "
      },    
    vb:checkbox {
      tooltip = "If selected the tool will always be running in the background",
      value = options.always_on.value,
      notifier = function(value)
        options.always_on.value = value
        if value then
          start_tool()
        else
          stop_tool()
        end
      end      
    }
  }

  local enable_prefaders_row = vb:row {
    vb:text {
      text = "Enable Pre Faders   "
      },    
    vb:checkbox {
      tooltip = "If selected the tool can also be used on the pre-fx faders",
      value = options.enable_pre.value,
      notifier = function(value)
        stop_tool()
        options.enable_pre.value = value
        start_tool()        
      end      
    }
  }

  -- GUI layout
  local content = vb:column {
     margin = 6,
     always_on_row,
     enable_prefaders_row
  }      
  
  dialog = renoise.app():show_custom_dialog(tool_name, content)  

end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = show_dialog  
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.." Enable",
  invoke = start_tool
}

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.." Disable",
  invoke = stop_tool
}

--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
