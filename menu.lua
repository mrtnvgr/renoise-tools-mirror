--------------------------------------------------------------------------------
-- SysEx Handler and Librarian
--
-- Copyright 2011 Martin Bealby
--
-- Menu integration code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function add_menu_common()
  -- Add common (non MIDI device lists) menu items
  renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:SysEx Librarian:Send SysEx File",
    invoke = function()
      if midi_out then
        -- Connected
        prompt_load_and_send_syx_file()
      else
        renoise.app():show_error("No SysEx MIDI send device selected.")
      end
    end
  }

  renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:SysEx Librarian:Record SysEx",
    selected = function()
      return recording_sysex
    end,
    invoke = function()
      if midi_in then
        if recording_sysex == true then
          -- stop recording
          recording_sysex = false
          
          -- flattern buffer to a single table
          local flat = {}
          for i = 1,#recording_sysex_buffer do
            -- append each 'segment'
            for j = 1,#recording_sysex_buffer[i] do
               table.insert(flat, recording_sysex_buffer[i][j])
            end
          end
          
          recording_sysex_buffer = {}
          
          if #flat > 1 then
            -- save current 'recording'
            save_syx_file(flat)
          end
        else
          --empty buffer and start recording
          recording_sysex_buffer = {}
          recording_sysex = true 
          renoise.app():show_status("SysEx recording started on device:" ..
                                    parameters.midi_out_device.value .. ".")
        end     
      else
        renoise.app():show_error("No SysEx MIDI receive device selected.")
      end
    end
  }

  renoise.tool():add_menu_entry {
    name = "---Main Menu:Tools:SysEx Librarian:Automatically Connect",
    selected = function()
      return parameters.auto_connect.value
    end,
    invoke = function()
      parameters.auto_connect.value = not parameters.auto_connect.value
    end
  }
  
  renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:SysEx Librarian:Save Preferences",
    invoke = function() 
      save_parameters()
    end
  }
end


function add_menu_devices()
  -- Enumerate and list all available devices in the selection menus
  -- End each menu list with 'None' which indicates disconnected
  local out_devices = renoise.Midi.available_output_devices()
  local in_devices = renoise.Midi.available_input_devices()

  for i = 1, #out_devices do
    renoise.tool():add_menu_entry {
      name = "Main Menu:Tools:SysEx Librarian:MIDI Send Device:" .. out_devices[i],
      selected = function()
        if parameters.midi_out_device.value == out_devices[i] then
          return true
        end
      end,
      invoke = function() 
        local old_device = parameters.midi_out_device.value
        
        if parameters.midi_out_device.value ~= "None" then
          midi_out_disconnect()
        end
        
        if midi_out_connect(out_devices[i]) then
          parameters.midi_out_device.value = out_devices[i]
        else
          midi_out_disconnect()
          renoise.app():show_status("SysEx Handler failed to connect.")
          parameters.midi_out_device.value = "None"
        end
      end
    }
  end
 
  for i = 1, #in_devices do
    renoise.tool():add_menu_entry {
      name = "Main Menu:Tools:SysEx Librarian:MIDI Receive Device:" .. in_devices[i],
      selected = function()
        if parameters.midi_in_device.value == in_devices[i] then
          return true
        end
      end,
      invoke = function() 
        local old_device = parameters.midi_in_device.value
        
        if parameters.midi_in_device.value ~= "None" then
          midi_in_disconnect()
        end
        
        if midi_in_connect(in_devices[i]) then
          parameters.midi_in_device.value = in_devices[i]
        else
          midi_in_disconnect()
          renoise.app():show_status("SysEx Handler failed to connect.")
          parameters.midi_in_device.value = "None"
        end
      end
    }
  end
   
  -- Add 'None' entries
  renoise.tool():add_menu_entry {
    name = "---Main Menu:Tools:SysEx Librarian:MIDI Send Device:None",
    selected = function()
      if parameters.midi_out_device.value == "None" then
        return true
      end
    end,
    invoke = function() 
      if parameters.midi_out_device.value ~= "None" then
        midi_out_disconnect()
      end
      parameters.midi_out_device.value = "None"
    end
  }
  
  renoise.tool():add_menu_entry {
    name = "---Main Menu:Tools:SysEx Librarian:MIDI Receive Device:None",
    selected = function()
      if parameters.midi_in_device.value == "None" then
        return true
      end
    end,
    invoke = function() 
      if parameters.midi_in_device.value ~= "None" then
        midi_in_disconnect()
      end
      parameters.midi_in_device.value = "None"
    end
  }
end
