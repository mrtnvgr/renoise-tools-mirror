--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Preferences Code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
local vb = nil
local dialog = nil


--------------------------------------------------------------------------------
--  Preferences
--------------------------------------------------------------------------------
options = renoise.Document.create("ScriptingToolPreferences") {    
  autostart = false,
  flash_pad = false,
  midi_in_port = "",
  midi_out_port = "",
  lcd_hold_time = 5,
  reverse_pads = false,
}

renoise.tool().preferences = options


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function show_dialog()
  -- show the pKing dialog
  
  if sysex_out then
    -- no changing while connected
    return
  end
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  vb = renoise.ViewBuilder()
  
  local in_port_index
  local out_port_index
  
  if table.find(renoise.Midi.available_input_devices(),
                renoise.tool().preferences.midi_in_port.value) then
    in_port_index = table.find(renoise.Midi.available_input_devices(), 
                               renoise.tool().preferences.midi_in_port.value)
  else
    in_port_index = 1
  end
  
  if table.find(renoise.Midi.available_output_devices(),
                renoise.tool().preferences.midi_out_port.value) then
    out_port_index = table.find(renoise.Midi.available_output_devices(), 
                                renoise.tool().preferences.midi_out_port.value)
  else
    out_port_index = 1
  end
  
  local content = vb:column {
    vb:column {            
      margin = DEFAULT_DIALOG_MARGIN,
      uniform = true,
      spacing = DEFAULT_CONTROL_SPACING,
      
      vb:row{ 
        margin = DEFAULT_MARGIN,
        vb:text {
          width = 170,
          text = "Flash pads on note trigger:",
        },
        vb:checkbox {
          value = options.flash_pad.value,
          notifier = function(i)
            options.flash_pad.value = i
            end
        }, 
      }, 
      
      vb:row{ 
        margin = DEFAULT_MARGIN,
        vb:text {
          width = 170,
          text = "Reverse pads (start lower left):",
        },
        vb:checkbox {
          value = options.reverse_pads.value,
          notifier = function(i)
            options.reverse_pads.value = i
            end
        }, 
      }, 
      
      vb:row{ 
        margin = DEFAULT_MARGIN,
        vb:text {
          width = 170,
          text = "LCD hold time (10th's sec):",
        },
        vb:valuebox {
          min = 5,
          max = 50,
          value = options.lcd_hold_time.value,
          notifier = function(i)
            options.lcd_hold_time.value = i
            end
        }, 
      }, 
      
      vb:row{ 
        margin = DEFAULT_MARGIN,
        vb:text {
          width = 170,
          text = "padKontrol MIDI input port:",
        },
        vb:popup{
          width = 150,
          items = renoise.Midi.available_input_devices(),
          value = in_port_index,
          notifier = function(i)
            renoise.tool().preferences.midi_in_port.value = 
              renoise.Midi.available_input_devices()[i]
            end
        }, 
      }, 
      vb:row{ 
        margin = DEFAULT_MARGIN,
        vb:text {
          width = 170,
          text = "padKontrol MIDI output port:",
        },
        vb:popup{
          width = 150,
          items = renoise.Midi.available_output_devices(),
          value = out_port_index,
          notifier = function(i)
            renoise.tool().preferences.midi_out_port.value = 
              renoise.Midi.available_output_devices()[i]
            end
        }, 
      }, 
    },
  }
  
  dialog = renoise.app():show_custom_dialog("pKing Preferences", content) 
end
