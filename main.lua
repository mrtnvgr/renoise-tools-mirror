--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
COLOUR_DEFAULT  = {  0,   0,   0}
COLOUR_BLACK    = {  1,   1,   1}
COLOUR_YELLOW   = {192, 192,  32}
COLOUR_RED      = {192,  32,  32}
COLOUR_ORANGE   = {200, 110,   0}
COLOUR_LORANGE  = {232, 168, 112}
COLOUR_GREEN    = { 32, 192,  32}
COLOUR_DBLUE    = {  0,  80, 240}
COLOUR_LBLUE    = {112, 160, 192}
COLOUR_PURPLE   = {172,   0, 255}
COLOUR_OFFWHITE = {210, 210, 210}
COLOUR_CYAN     = { 32, 192, 192}
COLOUR_GREY     = {128, 128, 128}

SEND_DEVICE_ID      = "Audio/Effects/Native/#Send"
GAIN_DEVICE_ID      = "Audio/Effects/Native/Gainer"
REPEATER_DEVICE_ID  = "Audio/Effects/Native/Repeater"
LIMITER_DEVICE_ID   = "Audio/Effects/Native/Compressor"
DELAY_DEVICE_ID     = "Audio/Effects/Native/Delay"
FILTER_DEVICE_ID    = "Audio/Effects/Native/Filter"
FLANGER_DEVICE_ID   = "Audio/Effects/Native/Flanger"

PLAYMODE_ONESHOT    = 1
PLAYMODE_REPITCH    = 2
PLAYMODE_GRANULAR   = 3
PLAYMODE_SLICES     = 4
PLAYMODE_NOTES      = 5

CELLSTATE_INVALID = 1
CELLSTATE_VALID   = 2
CELLSTATE_PLAYING = 3
CELLSTATE_CUED    = 4

CELLS_FX_FILTER   = 1
CELLS_FX_REPEAT   = 2
CELLS_FX_DELAY    = 3
CELLS_FX_FLANGER  = 4

CELLS_ROUTING_A       = 1
CELLS_ROUTING_MASTER  = 2
CELLS_ROUTING_B       = 3

CELLS_QUANTIZE_HALFBEAT = 1
CELLS_QUANTIZE_1BEAT    = 2
CELLS_QUANTIZE_2BEATS   = 3
CELLS_QUANTIZE_4BEATS   = 4



--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
cells_running = false
quantize_lines = 4*4
local last_cells_check = 0



--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "core/Preferences"
require "core/ControllerFramework"
require "core/CellsChannel"
require "core/CellsMixerFX"
require "core/CellsTransport"
require "core/InstrumentManager"
require "core/NetworkManager"
require "core/OscClient"
require "core/MidiMaps"
require "extras/PatternRendering"
require "extras/SamplePrep"
require "extras/PatternToSample"



--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------
ct = nil  -- CellsTransport
cm = nil  -- CellsMixerFx
im = nil  -- InstrumentManager
cc = {}   -- CellsChannel[]
nm = nil  -- NetworkManager
cf = ControllerFramework()
cells_dialog = nil



--------------------------------------------------------------------------------
-- Controller Maps
--------------------------------------------------------------------------------
require "controllers/ohm64"
require "controllers/launchpad"



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function start()
  -- Start Cells!
  
  -- already running?
  if cells_running then
    renoise.app():show_status("Cells! already running.")
    return
  end
  
  -- reload preferences
  load_preferences()
  
  renoise.app():show_status("Cells! starting...")

  -- Create Transport
  ct = CellsTransport()
  
  -- Create Mixer
  renoise.app():show_status("Cells! starting (preparing sends)...")
  cm = CellsMixerFx()
  
  -- Create Instrument Manager
  renoise.app():show_status("Cells! starting (parsing instruments)...")
  im = InstrumentManager()
  
  -- Create Cells! tracks
  cc = {}
  
  for i = 1, preferences.channel_count.value do
    renoise.app():show_status(string.format("Cells! starting (preparing channel %d)...", i))
    table.insert(cc, CellsChannel(i))
  end
  
  -- Assign channel groups
  cm:AssignChannelGroups()

  -- BNN: moved this to below the channel preparation...
  -- Initialise controllers
  renoise.app():show_status("Cells! starting (initialising controllers)...")
  cf:Reset()
  cf:LoadAllControllers()

  -- Create midi maps
  add_midi_maps()
  
  -- Network Init
  renoise.app():show_status("Cells! starting (initialising network communications)...")
  nm = NetworkManager()

  -- Create Main Dialog
  local vb = renoise.ViewBuilder()
  local main_view_channels = vb:row{}
  
  for i = 1, preferences.channel_count.value do
    main_view_channels:add_child(cc[i]:GetUI())
  end
  
  local main_view = vb:row{
    vb:column{
      main_view_channels,
    
      vb:horizontal_aligner{
        mode = "justify",
        cm:GetCrossFaderUI()
      },
    },
    
    vb:column{
      vb:row {
        style = "group",
          margin = 6,
        vb:horizontal_aligner{
          mode="center",
          spacing = 2,
          margin = 2,
          vb:bitmap{
            bitmap="img/cells_small.png",
            tooltip="Logo kindly made by miron_man from #renoise",
          },
        },
      },
      nm:GetUI(),
      ct:GetUI(),
      cm:GetVolumeUI(),
      cm:GetFxUI(),
    },
  }

  -- Display
  cells_dialog = renoise.app():show_custom_dialog("Cells! 2.0 Beta 2",
                                                  main_view,
                                                  main_key_handler)

  -- Select first cells track
  renoise.song().selected_track_index = 1

  -- Panic to set all notes off etc.
  renoise.song().transport:panic()

  -- We are running
  cells_running = true
  
  -- Run garbage collector
  collectgarbage()
  
  -- Inform user we are ready
  renoise.app():show_status("Cells! started successfully - have fun!")

  -- Start watchdog
  attach_cells_running_hook()
end


function main_key_handler(dialog, key)
  -- Do nothing
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function cells_running_hook(force)
  -- Occasionally check to see if Cells! is running
   
  -- do we check yet?
  if (os.clock() < last_cells_check + 2.0) and not force then
    return
  end

  if (not cells_dialog) or (not cells_dialog.visible) then
    -- cells has been closed, shutdown cleanly
    cells_running = false
    renoise.tool().app_idle_observable:remove_notifier(cells_running_hook)
    cells_dialog = nil
    im:RemoveHooks()
    ct:UnbindHooks()
    im = nil
    cc = {}
    renoise.song().transport:panic()
    renoise.app():show_status("Cells! shutdown")
    collectgarbage()
  end
  
  -- update check time
  last_cells_check = os.clock()
end


function attach_cells_running_hook()
  if not renoise.tool().app_idle_observable:has_notifier(cells_running_hook) then
    renoise.tool().app_idle_observable:add_notifier(cells_running_hook)
  end
end



--------------------------------------------------------------------------------
-- Menu Entries
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Cells!:Start",
  invoke = function() start() end
}



