--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Play the entire song from pattern sequence 1
local function play_song()
  renoise.song().transport:trigger_sequence(renoise.song().sequencer:pattern(renoise.song().sequencer.pattern_sequence[1]))
end

-- Play the looped pattern sequence
local function play_loop_sequence()
  renoise.song().transport:trigger_sequence(renoise.song().transport.loop_start.sequence)
end


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."Play Song From Start",
  invoke = play_song
}

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."Play Looped Pattern Sequence",
  invoke = play_loop_sequence
}


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

renoise.tool():add_midi_mapping {
  name = tool_id..":Play Looped Pattern Sequence...",
  invoke = play_loop_sequence
}

renoise.tool():add_midi_mapping {
  name = tool_id..":Play Song From Start...",
  invoke = play_song
}

