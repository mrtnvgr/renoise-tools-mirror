--------------------------------------------------------------------------------
-- SysEx Handler and Librarian
--
-- Copyright 2011 Martin Bealby
--
-- MIDI Interfacing
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
midi_in = nil  --device
midi_out = nil --device
recording_sysex = false
recording_sysex_buffer = {}


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function midi_in_connect(device)
  -- Connect to a specified midi device for receiving data
  midi_in = renoise.Midi.create_input_device(device, midi_callback,
                                             sysex_callback)

  if midi_in then
    renoise.app():show_status("SysEx Handler (receive) connected to " .. device .. " successfully.")
    return true
  else
    renoise.app():show_status("SysEx Handler (receive) connection to " .. device .. " failed.")
    return false
  end
end


function midi_in_disconnect()
  -- Disconnect the receiving device
  if midi_in then
    midi_in:close()
    midi_in = nil
  end
  renoise.app():show_status("SysEx Handler (receive) disconnected.")
end


function midi_out_connect(device)   
  -- Connect to a specified midi device for sending data                                          
  midi_out = renoise.Midi.create_output_device(device)
  
  if not midi_out then
    midi_in:close()
    renoise.app():show_status("SysEx Handler connection to " ..
                              device ..
                              " failed.")
    return false
  end
  
  renoise.app():show_status("SysEx Handler (send) connected to " ..
                             device ..
                             " successfully.")
  return true
end


function midi_out_disconnect()
  -- Disconnect the sending device
  if midi_out then
    midi_out:close()
    midi_out = nil
  end
  renoise.app():show_status("SysEx Handler (send) disconnected.")
end


function midi_callback(message)
  -- No action / handling required
end


function sysex_callback(message)
  if recording_sysex then
    table.insert(recording_sysex_buffer, message)
    renoise.app():show_status("SysEx Handler received an additional " ..
                              #message .. " bytes.")
  else
    -- ignore
  end
end


function send_sysex(message)
  -- Send a midi message 
  if midi_out then 
    -- Prompt user
    local man = identify_sysex_manufacturer(message)
    local result
    
    if man == "" then
      result = renoise.app():show_prompt("Transmitting SysEx",
                                         "About to transmit " ..
                                         #message ..
                                         " bytes of SysEx to MIDI port '" ..
                                         parameters.midi_out_device:to_string() ..
                                         "'.",
                                         {"Start", "Cancel"})
    else
      result = renoise.app():show_prompt("Transmitting SysEx",
                                         "About to transmit " ..
                                         #message ..
                                         " bytes of SysEx with Manufacturer ID " ..
                                         man ..
                                         " to MIDI port '" ..
                                         parameters.midi_out_device:to_string() ..
                                         "'.",
                                         {"Start", "Cancel"})
    end
    -- User result
    if result == "Start" then
      -- Go go go!
      midi_out:send(message)
      return true
    else
      -- :(
      renoise.app():show_status("SysEx transmit cancelled.")
    end
  else
    renoise.app():show_message("No SysEx MIDI send device selected.")
  end
end


function identify_sysex_manufacturer(message)
  -- Identify the manufacturer ID from a MIDI message
  -- Based on http://home.roadrunner.com/~jgglatt/tech/midispec/id.htm and
  -- http://www.sonicspot.com/guide/midimanufacturers.html
  if #message < 3 then
    -- invalid message
    return ""
  end
  
  if message[2] == 0x01 then
    return "Sequential Circuits"
  elseif message[2] == 0x02 then
    return "Big Briar"
  elseif message[2] == 0x03 then
    return "Octave/Plateau"
  elseif message[2] == 0x04 then
    return "Moog"
  elseif message[2] == 0x05 then
    return "Passport Designs"
  elseif message[2] == 0x06 then
    return "Lexicon"
  elseif message[2] == 0x07 then
    return "Kurzweil"
  elseif message[2] == 0x08 then
    return "Fender"
  elseif message[2] == 0x09 then
    return "Gulbransen"
  elseif message[2] == 0x0A then
    return "Delta Labs"
  elseif message[2] == 0x0B then
    return "Sound Comp"
  elseif message[2] == 0x0C then
    return "General Electro"
  elseif message[2] == 0x0D then
    return "Techmar"
  elseif message[2] == 0x0E then
    return "Matthews Research"
  elseif message[2] == 0x10 then
    return "Oberheim"  
  elseif message[2] == 0x11 then
    return "PAIA"
  elseif message[2] == 0x12 then
    return "Simmons"
  elseif message[2] == 0x13 then
    return "DigiDesign"
  elseif message[2] == 0x14 then
    return "Fairlight"
  elseif message[2] == 0x15 then
    return "JL Cooper"
  elseif message[2] == 0x16 then
    return "Lowery"
  elseif message[2] == 0x17 then
    return "Linn"
  elseif message[2] == 0x18 then
    return "Emu"
  elseif message[2] == 0x1B then
    return "Peavey"
  elseif message[2] == 0x20 then
    return "Bon Tempi"
  elseif message[2] == 0x21 then
    return "SIEL"
  elseif message[2] == 0x23 then
    return "SyntheAxe"
  elseif message[2] == 0x24 then
    return "Hohner"
  elseif message[2] == 0x25 then
    return "Crumar"
  elseif message[2] == 0x26 then
    return "Solton"
  elseif message[2] == 0x27 then
    return "Jellinghaus Ms"
  elseif message[2] == 0x28 then
    return "CTS"
  elseif message[2] == 0x29 then
    return "PPG"
  elseif message[2] == 0x2F then
    return "Elka"
  elseif message[2] == 0x36 then
    return "Cheetah"
  elseif message[2] == 0x3E then
    return "Waldorf"
  elseif message[2] == 0x40 then
    return "Kawai"
  elseif message[2] == 0x41 then
    return "Roland"
  elseif message[2] == 0x42 then
    return "Korg"
  elseif message[2] == 0x43 then
    return "Yamaha"
  elseif message[2] == 0x44 then
    return "Casio"
  elseif message[2] == 0x45 then
    return "Akai"
  elseif message[2] == 0x46 then
    return "Kamiya Studio"
  elseif message[2] == 0x47 then
    return "Akai"
  elseif message[2] == 0x48 then
    return "Victor"
  elseif message[2] == 0x4B then
    return "Fujitsu"
  elseif message[2] == 0x4C then
    return "Sony"
  elseif message[2] == 0x4E then
    return "Teac"  
  elseif message[2] == 0x50 then
    return "Matsushita"
  elseif message[2] == 0x51 then
    return "Fostex"
  elseif message[2] == 0x52 then
    return "Zoom"
  elseif message[2] == 0x54 then
    return "Matsushita"
  elseif message[2] == 0x55 then
    return "Suzuki"
  elseif message[2] == 0x56 then
    return "Fuji Sound"
  elseif message[2] == 0x57 then
    return "Accoustic Technical Laboratory"
  elseif message[2] == 0x7E then
    return "Sample Dump Standard"
  else
    return ""
  end
end
