--------------------------------------------------------------------------------
-- SysEx Handler and Librarian
--
-- Copyright 2011 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "parameters"
require "files"
require "midi"
require "menu"


--------------------------------------------------------------------------------
-- Tool initialisation
--------------------------------------------------------------------------------
load_parameters()
add_menu_common()
add_menu_devices()

if parameters.auto_connect.value == true then
  local found = false
  local out_devices = renoise.Midi.available_output_devices()
  local in_devices = renoise.Midi.available_input_devices()

  for i = 1,#out_devices do
    if out_devices[i] == parameters.midi_in_device.value then
      found = true
    end
  end
  
  if found == true then
    -- found input device, connect!
    midi_in_connect(parameters.midi_in_device.value)
  end

  for i = 1,#out_devices do
    if out_devices[i] == parameters.midi_out_device.value then
      found = true
    end
  end
  
  if found == true then
    -- found output device, connect!
    midi_out_connect(parameters.midi_out_device.value)
  end
end
