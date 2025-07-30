--[[============================================================================
Collapse/Expand All Tracks in Group

Author: Florian Krause <siebenhundertzehn@gmail.com>
Version: 0.2
============================================================================]]--

-- Register the tool
renoise.tool():add_menu_entry{
  name = 'Pattern Editor:Group:Collapse/Expand All Tracks in Group',
  invoke = function() main() end
}
renoise.tool():add_menu_entry{
  name = 'Mixer:Track:Collapse/Expand All Tracks in Group',
  invoke = function() main() end
}
  
-- Add key bindings
renoise.tool():add_keybinding{
  name = "Pattern Editor:Track Control:Collapse/Expand All Tracks in Group",
  invoke = function() main() end
}
renoise.tool():add_keybinding{
  name = "Mixer:Track Control:Collapse/Expand All Tracks in Group",
  invoke = function() main() end
}

function main()
  local current_song = renoise.song()
  local selected_track = current_song.tracks[current_song.selected_track_index]
  if selected_track.type == renoise.Track.TRACK_TYPE_GROUP then
    for i=1, #selected_track.members do
      local track = selected_track.members[i]
      if track.collapsed == true then
        track.collapsed = false
      else
        track.collapsed = true
      end
    end
  end
end
