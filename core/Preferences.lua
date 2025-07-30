--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Preferences Code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
RENDER_SAMPLE_RATES = {"22050", "44100", "48000", "88200", "96000"}
RENDER_BIT_DEPTHS   = {"16", "24", "32"}
RENDER_PRIORITY     = {"low", "realtime", "high"}



--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
preferences = nil
local pref_dialog = nil
local view_pref_dialog = nil
  


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function load_preferences()
  -- initialise default and overwrite with settings from the config file

  preferences = renoise.Document.create("CellsParameters") {
    channel_count = 8,              -- number of channels
    cells_count = 7,                -- number of cells per channel excluding stop
    cell_height = 20,               -- height of each cell
    cell_width  = 76,               -- width of each cell
    base_bpm    = 130,              -- base BPM from which we can variate
    bpm_deviation = 16,             -- deviation from the base BPM we can handle
    automatic_cue_mute = true,      -- automatically mute cue output if same as
                                    -- main outputs
    single_output_mode = false,     -- MAIN = left, CUE = right
    master_output_device = "",
    cue_output_device = "",
    --master_output_device = renoise.song().tracks[1].available_output_routings[2],      -- master output device
    --cue_output_device = renoise.song().tracks[1].available_output_routings[2],         -- cue output device
    auto_select_sample = false,     -- automatically select sample for cell
    auto_select_track = false,      -- automatically select tracks on operations
    blank_is_stop = false,          -- blank (invalid) cells are stop buttons
    render_priority = "high",       -- rendering priority
    render_interpolation = "cubic", -- rendering interpolation
    render_bit_depth = 24,          -- rendering bit depth
    render_sample_rate = 48000,     -- rendering sample rate
    controllers = {                 -- controller tree
      controller1 = {
        type = "None",
        in_port = "",
        out_port = "",
      },
      controller2 = {
        type = "None",
        in_port = "",
        out_port = "",
      },
    },
    lan_slave = false,              -- is this node a lan slave
    nodes = {                       -- network node connections
      node1 = {
        ip = "127.0.0.1",           -- localhost
        port = 8000,
        protocol = 2,               -- 1 = TCP, 2 = UDP
      },
      node2 = {
        ip = "0.0.0.0",
        port = 8000,
        protocol = 2,               -- 1 = TCP, 2 = UDP
        enable = false,
      },
      node3 = {
        ip = "0.0.0.0",
        port = 8000,
        protocol = 2,               -- 1 = TCP, 2 = UDP
        enable = false,
      },
      node4 = {
        ip = "0.0.0.0",
        port = 8000,
        protocol = 2,               -- 1 = TCP, 2 = UDP
        enable = false,
      },
    },
  }
  preferences:load_from("config.xml")
end



function save_preferences()
  -- save the current settings to the config file
  if preferences ~= nil then
    preferences:save_as("config.xml")
  else
  end
end


--------------------------------------------------------------------------------
-- GUI Code
--------------------------------------------------------------------------------
function pref_dialog_keyhander(dialog, key)
  if key.name == "esc" then
    save_preferences()
    pref_dialog:close()
  else
    return key
  end
end



function pref_dialog_init()
  local vb = renoise.ViewBuilder()
  
  --
  -- populate output devices table
  --
  local output_devices = {}
  
  output_devices = renoise.song().tracks[1].available_output_routings
  table.remove(output_devices, 1) -- remove master routing
  
  -- Assign devices if only a single item is present
  rprint(output_devices)
  print('---')
  
  if #output_devices == 1 then
    preferences.master_output_device.value = output_devices[1]
    preferences.cue_output_device.value = output_devices[1]
  end
  
  --
  -- UI
  --
  view_pref_dialog = vb:column {
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Track count:",
        tooltip = "Number of Cells! playback tracks",
      },
      vb:valuebox {
        min = 4,
        max = 16,
        value = preferences.channel_count.value,
        tooltip = "Number of Cells! playback channels",
        notifier = function(v)
          preferences.channel_count.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Cells per track:",
        tooltip = "Number of cells per track",
      },
      vb:valuebox {
        min = 4,
        max = 16,
        value = preferences.cells_count.value,
        tooltip = "Number of cells per track",
        notifier = function(v)
          preferences.cells_count.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Cell height:",
        tooltip = "Height of each cell",
      },
      vb:valuebox {
        min = 16,
        max = 48,
        value = preferences.cell_height.value,
        tooltip = "Height of each cell",
        notifier = function(v)
          preferences.cell_height.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Cell width:",
        tooltip = "Width of each cell",
      },
      vb:valuebox {
        min = 74,
        max = 144,
        value = preferences.cell_width.value,
        tooltip = "Width of each cell",
        notifier = function(v)
          preferences.cell_width.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Master output:",
        tooltip = "Master output device",
      },
      vb:popup {
        width = 120,
        items = output_devices,
        value = table.find(output_devices, preferences.master_output_device.value) or 1,
        tooltip = "Master output device",
        notifier = function(v)
          preferences.master_output_device.value = output_devices[v]
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Cue output:",
        tooltip = "Cue output device",
      },
      vb:popup {
        width = 120,
        items = output_devices,
        value = table.find(output_devices, preferences.cue_output_device.value) or 1,
        tooltip = "Cue output device",
        notifier = function(v)
          preferences.cue_output_device.value = output_devices[v]
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Safe cue output:",
        tooltip = "Autmatically mute the cue output if set to the same as the main output to avoid 'doubling up'",
      },
      vb:checkbox {
        value = preferences.automatic_cue_mute.value,
        tooltip = "Autmatically mute the cue output if set to the same as the main output to avoid 'doubling up'",
        notifier = function(v)
          preferences.automatic_cue_mute.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Single output mode:",
        tooltip = "Run with a single audio output, main output panned left, cue output panned right",
      },
      vb:checkbox {
        value = preferences.single_output_mode.value,
        tooltip = "Run with a single audio output, main output panned left, cue output panned right",
        notifier = function(v)
          preferences.single_output_mode.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Base BPM:",
        tooltip = "Because of the limited range of MIDI controllers, a user can specify a base BPM and a deviation value to increase accuracy",
      },
      vb:valuebox {
        min = 80,
        max = 180,
        value = preferences.base_bpm.value,
        tooltip = "Because of the limited range of MIDI controllers, a user can specify a base BPM and a deviation value to increase accuracy",
        notifier = function(v)
          preferences.base_bpm.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "BPM Deviation:",
        tooltip = "Because of the limited range of MIDI controllers, a user can specify a base BPM and a deviation value to increase accuracy",
      },
      vb:valuebox {
        min = 8,
        max = 64,
        value = preferences.bpm_deviation.value,
        tooltip ="Because of the limited range of MIDI controllers, a user can specify a base BPM and a deviation value to increase accuracy",
        notifier = function(v)
          preferences.bpm_deviation.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Automatic sample select:",
        tooltip = "Automatically selects the sample for a cell when pressed",
      },
      vb:checkbox {
        value = preferences.auto_select_sample.value,
        tooltip = "Automatically selects the sample for a cell when pressed",
        notifier = function(v)
          preferences.auto_select_sample.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Automatic track select:",
        tooltip = "Automatically updates the current channel when an track channel occurs",
      },
      vb:checkbox {
        value = preferences.auto_select_track.value,
        tooltip = "Automatically updates the current channel when an track channel occurs",
        notifier = function(v)
          preferences.auto_select_track.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Blank cells are stops",
        tooltip = "Invalid (blank) cells trigger cued stop",
      },
      vb:checkbox {
        value = preferences.blank_is_stop.value,
        tooltip = "Invalid (blank) cells trigger cued stop",
        notifier = function(v)
          preferences.blank_is_stop.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Rendering bitdepth:",
        tooltip = "Pattern renderer bit depth",
      },
      vb:popup {
        items = RENDER_BIT_DEPTHS,
        value = table.find(RENDER_BIT_DEPTHS, tostring(preferences.render_bit_depth.value)),
        tooltip = "Pattern renderer bit depth",
        notifier = function(v)
          preferences.render_bit_depth.value = tonumber(RENDER_BIT_DEPTHS[v])
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Rendering sample rate:",
        tooltip = "Pattern renderer sample rate",
      },
      vb:popup {
        items = RENDER_SAMPLE_RATES,
        value = table.find(RENDER_SAMPLE_RATES, tostring(preferences.render_sample_rate.value)),
        tooltip = "Pattern renderer sample rate",
        notifier = function(v)
          preferences.render_sample_rate.value = tonumber(RENDER_SAMPLE_RATES[v])
        end
      },
    },    
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Rendering priority:",
        tooltip = "Pattern renderer priority",
      },
      vb:popup {
        items = RENDER_PRIORITY,
        value = table.find(RENDER_PRIORITY, preferences.render_priority.value),
        tooltip = "Pattern renderer priority",
        notifier = function(v)
          preferences.render_priority.value = RENDER_PRIORITY[v]
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Network slave:",
        tooltip = "Define this machine as a network slave node",
      },
      vb:checkbox {
        value = preferences.lan_slave.value,
        tooltip = "Define this machine as a network slave node",
        notifier = function(v)
          preferences.lan_slave.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:text {
        text = "Localhost:               ",
        tooltip = "Localhost OSC server settings",
      },
      vb:valuebox {
        min = 1,
        max = 65535,
        value = preferences.nodes.node1.port.value,
        tooltip = "Local OSC server port",
        notifier = function(v)
          preferences.nodes.node1.port.value = v
        end
      },
      vb:popup {
        items = {"TCP", "UDP"},
        value = preferences.nodes.node1.protocol.value,
        tooltip = "Local OSC server protocol",
        notifier = function(v)
          preferences.nodes.node1.protocol.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:checkbox {
        value = preferences.nodes.node2.enable.value,
        tooltip = "Enable node 2",
        notifier = function(v)
          preferences.nodes.node2.enable.value = v
        end
      },
      vb:textfield {
        value = preferences.nodes.node2.ip.value,
        tooltip = "Node 2 IP",
        notifier = function(v)
          preferences.nodes.node2.ip.value = v
        end
      },
      vb:valuebox {
        min = 1,
        max = 65535,
        value = preferences.nodes.node2.port.value,
        tooltip = "Node 2 port",
        notifier = function(v)
          preferences.nodes.node2.port.value = v
        end
      },
      vb:popup {
        items = {"TCP", "UDP"},
        value = preferences.nodes.node2.protocol.value,
        tooltip = "Node 2 protocol",
        notifier = function(v)
          preferences.nodes.node2.protocol.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:checkbox {
        value = preferences.nodes.node3.enable.value,
        tooltip = "Enable node 3",
        notifier = function(v)
          preferences.nodes.node3.enable.value = v
        end
      },
      vb:textfield {
        value = preferences.nodes.node3.ip.value,
        tooltip = "Node 3 IP",
        notifier = function(v)
          preferences.nodes.node3.ip.value = v
        end
      },
      vb:valuebox {
        min = 1,
        max = 65535,
        value = preferences.nodes.node3.port.value,
        tooltip = "Note 3 port",
        notifier = function(v)
          preferences.nodes.node3.port.value = v
        end
      },
      vb:popup {
        items = {"TCP", "UDP"},
        value = preferences.nodes.node3.protocol.value,
        tooltip = "Node 3 protocol",
        notifier = function(v)
          preferences.nodes.node3.protocol.value = v
        end
      },
    },  
    vb:horizontal_aligner {
      mode = "justify",
      vb:checkbox {
        value = preferences.nodes.node4.enable.value,
        tooltip = "Enable node 4",
        notifier = function(v)
          preferences.nodes.node4.enable.value = v
        end
      },
      vb:textfield {
        value = preferences.nodes.node4.ip.value,
        tooltip = "Node 4 IP",
        notifier = function(v)
          preferences.nodes.node4.ip.value = v
        end
      },
      vb:valuebox {
        min = 1,
        max = 65535,
        value = preferences.nodes.node4.port.value,
        tooltip = "Note 4 port",
        notifier = function(v)
          preferences.nodes.node4.port.value = v
        end
      },
      vb:popup {
        items = {"TCP", "UDP"},
        value = preferences.nodes.node4.protocol.value,
        tooltip = "Node 4 protocol",
        notifier = function(v)
          preferences.nodes.node4.protocol.value = v
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:popup {
        items = cf:ListControllers(),
        value = table.find(cf:ListControllers(), preferences.controllers.controller1.type.value),
        tooltip = "Select the type of controller to use or 'None' to disable",
        notifier = function(v)
          preferences.controllers.controller1.type.value = cf:ListControllers()[v]
        end
      },
      vb:popup {
        items = renoise.Midi.available_input_devices(),
        value = table.find(renoise.Midi.available_input_devices(), preferences.controllers.controller1.in_port.value),
        tooltip = "Select the midi input port for this controller",
        notifier = function(v)
          preferences.controllers.controller1.in_port.value = renoise.Midi.available_input_devices()[v]
        end
      },
      vb:popup {
        items = renoise.Midi.available_output_devices(),
        value = table.find(renoise.Midi.available_output_devices(), preferences.controllers.controller1.out_port.value),
        tooltip = "Select the midi output port for this controller",
        notifier = function(v)
          preferences.controllers.controller1.out_port.value = renoise.Midi.available_output_devices()[v]
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:popup {
        items = cf:ListControllers(),
        value = table.find(cf:ListControllers(), preferences.controllers.controller2.type.value),
        tooltip = "Select the type of controller to use or 'None' to disable",
        notifier = function(v)
          preferences.controllers.controller2.type.value = cf:ListControllers()[v]
        end
      },
      vb:popup {
        items = renoise.Midi.available_input_devices(),
        value = table.find(renoise.Midi.available_input_devices(), preferences.controllers.controller2.in_port.value),
        tooltip = "Select the midi input port for this controller",
        notifier = function(v)
          preferences.controllers.controller2.in_port.value = renoise.Midi.available_input_devices()[v]
        end
      },
      vb:popup {
        items = renoise.Midi.available_output_devices(),
        value = table.find(renoise.Midi.available_output_devices(), preferences.controllers.controller1.out_port.value),
        tooltip = "Select the midi output port for this controller",
        notifier = function(v)
          preferences.controllers.controller2.out_port.value = renoise.Midi.available_output_devices()[v]
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",    
      vb:button {
        text = "Save & Close",
        released = function()
          save_preferences()
          cf:Reset() -- restart controllers
          pref_dialog:close()
          renoise.app():show_status("Cells! preferences saved.")
        end
      },
    },
  }
end



function display_pref_dialog()
  -- Show the preferences dialog
  
  if cells_running then
    renoise.app():show_status("Cells! preferences cannot be modified when Cells! is running.")
    return --abort if cells is running
  end
  
  -- Remove any existing dialog
  if pref_dialog then
    pref_dialog = nil
  end
  
  -- reload
  load_preferences()

  -- Create new dialog
  pref_dialog_init()
  pref_dialog = renoise.app():show_custom_dialog("Cells! Preferences",
                                                 view_pref_dialog,
                                                 pref_dialog_keyhander)
end



--------------------------------------------------------------------------------
-- Menu Entries
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Cells!:Preferences",
  invoke = function() display_pref_dialog() end
}




--------------------------------------------------------------------------------
-- Tool Startup
--------------------------------------------------------------------------------
load_preferences()
