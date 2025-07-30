--[[============================================================================
main.lua
============================================================================]]--

--thanks to Bantai for TempoTap which was used as a base for this script

local dialog = nil
local vb = nil

local counter = 0
local last_clock = 0

--options

local options = renoise.Document.create {
  beats = 4,
  metronome = true,
  clear = true
}


renoise.tool():add_keybinding {
  name = "Global:Tools:PreClick",
  invoke = function() show_dialog() end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:PreClick Record Now",
  invoke = function() record(options.beats.value) end
}


--------------------------------------------------------------------------------
-- tool setup
--------------------------------------------------------------------------------

renoise.tool().preferences = options

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Pre Click...",
  invoke = function() 
    show_dialog() 
  end
}

--------------------------------------------------------------------------------
-- Record
--------------------------------------------------------------------------------

function record(ticks)


  local solo = 0
  local bpm
  
  bpm = renoise.song().transport.bpm
  
  if (renoise.song().tracks[renoise.song().selected_track_index].solo_state == false) then
    renoise.song().tracks[renoise.song().selected_track_index]:solo()
    solo = 1
  end
  
  renoise.song().tracks[renoise.song().selected_track_index]:mute()
  renoise.song().transport.edit_mode = false
  renoise.song().transport.metronome_enabled = true
  
  renoise.song().transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
  renoise.song().transport.follow_player = false
  
  if (options.clear.value) then
	renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index]:clear()
  end
  
  local tmp = renoise.SongPos()
  tmp.sequence = renoise.song().selected_sequence_index
  tmp.line =1

  
  local cclock = os.clock()
  last_clock = cclock
 
  while cclock + 0.1 < last_clock + ((60/bpm) * ticks) do 
	cclock = os.clock()
  end
  

  if (options.metronome.value == false) then
	renoise.song().transport.metronome_enabled =  false
  end
  
  cclock = os.clock()
  last_clock = cclock
 
  while cclock < (last_clock + 0.05) do 
	cclock = os.clock()
  end
  
  renoise.song().transport.playback_pos = tmp
  renoise.song().transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
  
  if dialog and dialog.visible then
	dialog:close()
  end
  
  renoise.song().transport.follow_player = true
  renoise.song().tracks[renoise.song().selected_track_index]:solo()
  
  if solo == 1 then
    renoise.song().tracks[renoise.song().selected_track_index]:solo()
  end

  cclock = os.clock()
  last_clock = cclock
 
  while cclock < (last_clock + 0.03) do 
	cclock = os.clock()
  end
  renoise.song().transport.playback_pos = tmp
  renoise.song().transport.edit_mode = true

  
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

function show_dialog()

  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local TEXT_ROW_WIDTH = 40

  local dialog_title = "Pre Click"
  local dialog_buttons = {"Close"};

  
  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    uniform = true,

	        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Press any key to begin..."
        },
	
    vb:button {
      text = "CLICK ME",
      width = 35,
      height = 40,
      pressed = function()       
        record(options.beats.value)
      end
    },
    
    vb:column {
       margin = DEFAULT_DIALOG_MARGIN,
       spacing = DEFAULT_CONTROL_SPACING,

       vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Pre Clicks"
        },
        vb:valuebox {
          bind = options.beats,
          min = 2,
          max = 16,
        },
      },
      
      vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Keep Metronome"
        },
        vb:checkbox {
          bind = options.metronome, 
        },
      },       
    
      vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "    Clear This Track"
        },
        vb:checkbox {
          bind = options.clear, 
        }
      },
        

    },      
    
  }
  
  local function key_handler(dialog, key)
    if (key.name == "esc") then
      dialog:close()
    
    else    
      record(options.beats.value)   
    end 
  end
  
  dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content, key_handler)

end