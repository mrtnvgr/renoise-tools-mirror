--[[-------------------------------------------------------------
MACUILXOCHITL                                                   -
martblek (martblek@gmail.com)                                   -
...                                                             -
creates and deforms various waves which,                        -
with the help of old musical gods, are shaped into              -
the greatest possible harmony with the world                    -
-----------------------------------------------------------------

v0.018
Ok. Let the keypresses go through


v0.017
Problem with period on high Cs .. solved
Do not delete samples .. ok 
edit manifest to not show my email .. ok
graphic bug at start where formant filter is visible .. solved


v0.016
Some gui changes
OSC periods and amplitudes now have valuefields again :)
Sak Nik 


v0.015
Added harmonic frequencies to simple waves
Given the ability to render data as mono or affect stereofield.


v0.014
Fixed midi mappings
Fixed minor bug in gui --> from Patches page not switching to page 1
Begin to use observables but still fighting


v0.013 --< Skip release
Fixed bug in midi control for OSC period
Disabled midi mapping for now :( / i must learn all about notifying /
Added 3 new operators Min and Max ,known as Tropical synthesis and Mod operator

Added Modulation extension
Now last 2 oscilators can be modded with previous one by selection



v0.012
Bug with refreshing OPs and Details in OSCs seems to be gone.
Sample buffer values changed to "C" length
Added custom sample buffer widget for modify length
New wave added /sin to Tan/


v0.011
Splitting the source code into parts
GUI changes
Removed welcome screen :)
Sample length is limited to specified values
Added waveforms other than sine wave with view to better repetition
Redesigned saving program settings
Midi mappings and key shortcut added
Some optimizations


v0.010
First public release


]]--------------------------------------------------------------

VERSION = "0.018"
AUTHOR = "martblek (martblek@gmail.com)"
DEBUG = false

PATCHES = nil
MATH_BUFFER = {}     --< this stores calculated values
MIN_VALUE = 9999
MAX_VALUE = -9999
MAIN_SAMPLE = nil
MAIN_INSTRUMENT = nil

vb = nil
dialog = nil
rns = nil
rnt = renoise.tool()
ra = renoise.app()

Notifiers = {}

function Notifiers:add(observable, callable)
  if not observable:has_notifier(callable) then
    observable:add_notifier(callable)
  end
end

function Notifiers:remove(observable, callable)
  if observable:has_notifier(callable) then
    observable:remove_notifier(callable)
  end
end

--[[------------------------------------------------------------- 
Register menu in renoise                                        -
]]---------------------------------------------------------------

require "src/files"
require "src/gui"
require "src/generators"
require "src/render"
require "src/midi_mapping"
require "src/filters"
require "src/noises"

function prepare_for_start()

  -- v teto funkci se provede vše po znovu spuštění toolu
  -- pokud již okno existuje a je otevřené jen ho zobraz

  vb = renoise.ViewBuilder()
  
  if (dialog and dialog.visible) then
    dialog:show()
    return
  end

  -- apply midi mapping before gui fired
  print("Applying midi mapping ...")
  toggle_midi_mapping()

  -- pokud neexistuje tak proveď inicializaci
  print("MX Gui started ...")
  show_gui()

end

renoise.tool():add_menu_entry{
  name = "Sample Editor: Macuilxochitl",
  invoke = function()
    prepare_for_start()
  end
}

renoise.tool():add_keybinding{
  name="Global:Tools:Maciulxochitl",
  invoke=function()
    prepare_for_start()
  end
}

_AUTO_RELOAD_DEBUG = function()
end

function app_idle()
  if not dialog.visible then
    
    print("Removing midi mapping ...")
    toggle_midi_mapping()

    print("Removing notifiers and observables ...")
    --Notifiers:remove(rns.selected_instrument_observable, instrument_changes)
    --Notifiers:remove(rns.selected_sample_observable, sample_buffer_changes)
    Notifiers:remove(rnt.app_idle_observable, app_idle)
    --print("window is hidden")
  
  else
  
    --print("window is showed")
  
  end

end