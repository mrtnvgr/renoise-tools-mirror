--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Main tool code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------
require "support"
require "preferences"
require "comms"
require "prompts/support"
require "prompts/base"
require "prompts/bpm"
require "prompts/inst_index"
require "prompts/note_col_index"
require "prompts/note_delay"
require "prompts/note_panning"
require "prompts/note_volume"
require "prompts/patt_len"
require "prompts/samp_autochop"
require "prompts/samp_loop"
require "prompts/samp_map_note"
require "prompts/samp_map_vel"
require "prompts/samp_rec"
require "prompts/samp_slice"
require "prompts/samp_tti"
require "prompts/samp_vpn"
require "prompts/sequencer_index"
require "prompts/track_index"
require "prompts/track_outdel"
require "prompts/pad_scale"
require "modes/support"
require "modes/base"
require "modes/patt_edit"
require "modes/song_edit"
require "modes/inst_edit"
require "modes/samp_edit"
require "modes/waiting"


--------------------------------------------------------------------------------
-- Global Variables
--------------------------------------------------------------------------------
mode = nil
prompt = nil


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function start_pking()
  if connect(options.midi_in_port.value, options.midi_out_port.value) then
    attach_common_mode_hooks()
    set_mode(MODE_PATT)
  else
    renoise.app():show_error("Couldn't establish midi connection.")
  end
end


function stop_pking()
  if prompt then
    prompt:ok()
  end
  
  if mode then
    mode:exit()
  end
  
  disconnect()
  mode = nil
  prompt = nil
end



--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:pKing2:Start",
  invoke = function() start_pking() end
}


renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:pKing2:Stop",
  invoke = function() stop_pking() end
}


renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:pKing2:Preferences",
  invoke = function() show_dialog() end
}
