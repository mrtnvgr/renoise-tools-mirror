--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
OSCILLATOR_VA    = 1
OSCILLATOR_FM    = 2
OSCILLATOR_USER  = 3
OSCILLATOR_SSAW  = 4

VA_WAVEFORM_SIN     = 1
VA_WAVEFORM_TRI     = 2
VA_WAVEFORM_SAW     = 3
VA_WAVEFORM_PULSE   = 4
VA_MAX_LFO_SPEED    = 256
VA_CYCLE_LEN        = 200
VA_HALFCYCLE_LEN    = VA_CYCLE_LEN / 2
VA_QUARTERCYCLE_LEN = VA_CYCLE_LEN / 4
VA_SAW_GRADIENT     = 1 / VA_HALFCYCLE_LEN
VA_TRI_GRADIENT     = 1 / VA_QUARTERCYCLE_LEN
VA_MAX_SAMPLE_LEN   = VA_CYCLE_LEN * (VA_MAX_LFO_SPEED + 1)

FILTER_TYPES = {'LP 2x2 Pole', 'LP 2 Pole', 'LP Biquad', 'LP Moog',
                'LP Single', 'HP 2x2 Pole', 'HP 2 Pole', 'HP Moog'}

OPEN_MODE_NEW  = 1
OPEN_MODE_OPEN = 2

COLOUR_BLACK    = {  1,   1,   1}
COLOUR_YELLOW   = {192, 192,  32}
COLOUR_GREEN    = { 32, 192,  32}
COLOUR_DBLUE    = {  0,  80, 240}
COLOUR_LBLUE    = {112, 160, 192}



--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require 'support'
require 'Oscillators/BaseOscillator'
require 'Oscillators/VaOscillator'
require 'Oscillators/FmOscillator'
require 'Oscillators/UserOscillator'
require 'Oscillators/SsawOscillator'
require 'Envelopes/VolEnvelope'
require 'Envelopes/FilterEnvelope'
require 'Arpeggiator/Arpeggiator'
require 'ReSynth'



--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = 'Main Menu:Tools:ReSynth:Insert new Resynth Instrument',
  invoke = function()
             renoise.song():insert_instrument_at(renoise.song().selected_instrument_index+1)
             renoise.song().selected_instrument_index = renoise.song().selected_instrument_index +1
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}


renoise.tool():add_menu_entry {
  name = 'Main Menu:Tools:ReSynth:Replace with Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}

renoise.tool():add_menu_entry {
  name = 'Main Menu:Tools:ReSynth:Edit Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_OPEN)
           end
}


renoise.tool():add_menu_entry {
  name = 'Instrument Box:ReSynth:Insert new Resynth Instrument',
  invoke = function()
             renoise.song():insert_instrument_at(renoise.song().selected_instrument_index+1)
             renoise.song().selected_instrument_index = renoise.song().selected_instrument_index +1
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}


renoise.tool():add_menu_entry {
  name = 'Instrument Box:ReSynth:Replace with Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}

renoise.tool():add_menu_entry {
  name = 'Instrument Box:ReSynth:Edit Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_OPEN)
           end
}


--------------------------------------------------------------------------------
-- Keybindings
--------------------------------------------------------------------------------
renoise.tool():add_keybinding {
  name = 'Global:ReSynth:Insert new Resynth Instrument',
  invoke = function()
             renoise.song():insert_instrument_at(renoise.song().selected_instrument_index+1)
             renoise.song().selected_instrument_index = renoise.song().selected_instrument_index +1
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}


renoise.tool():add_keybinding {
  name = 'Global:ReSynth:Replace with Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_NEW)
           end
}

renoise.tool():add_keybinding {
  name = 'Global:ReSynth:Edit Resynth Instrument',
  invoke = function()
             ReSynth(renoise.song().selected_instrument_index, OPEN_MODE_OPEN)
           end
}
