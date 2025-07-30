-- Thanks to suva for the function per octave declaration loop :)
-- http://www.protman.com

function ProcessOctave(new_octave)

  local new_pos = 0
  local song = renoise.song()
  local editstep = renoise.song().transport.edit_step

  new_pos = song.transport.edit_pos
  if song.selected_note_column.note_value < 120 then
    song.selected_note_column.note_value = song.selected_note_column.note_value  % 12 + (12 * new_octave)
  end
  new_pos.line = new_pos.line + editstep
  if new_pos.line <= song.selected_pattern.number_of_lines then
     song.transport.edit_pos = new_pos 
  end

end  


for oct=0,9 do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Pattern:Set Note to Octave " .. oct,
    invoke = function() ProcessOctave(oct) end
  }
end 


