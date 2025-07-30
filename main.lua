--[[============================================================================
main.lua
============================================================================]]--
require 'scale'

local scale_root = 4
local scale_type = 1
local scale_pattern
local ccont = {}

local transpose_chord = true
local transpose_increment = 1

local vb = renoise.ViewBuilder()
local sdisplay = vb:text{ width = 190, font = 'bold' }
local increment_multiple = 1;

--------------------------------------------------------------------------------
function start_preview()  
  renoise.song().transport:start_at(renoise.song().selected_line_index)
end

--------------------------------------------------------------------------------
function stop_preview()
  renoise.song().transport:stop()
end

--------------------------------------------------------------------------------
function insert_note(note, col, insv)
  if renoise.song().selected_note_column_index == 0 then
    return -- Don't enter notes when in effect column
  end
   
  col = col + renoise.song().selected_note_column_index - 1
  
  -- Get the note column
  local nc = renoise.song().selected_line.note_columns[col + 1]
  
  -- Add note
  nc.note_value = note - 4 + renoise.song().transport.octave * 12
  nc.instrument_value = insv - 1
  
  -- Not enough space? Compensate!
  if col >= renoise.song().selected_track.visible_note_columns then
    renoise.song().selected_track.visible_note_columns = col + 1
  end
  
  -- Preview
  start_preview()
  
end

function clear_cb()
  for i, v in ipairs(ccont) do
    if v ~= nil then
      chord_boxes[i]:remove_child(v)
      chord_boxes[i]:resize()
      ccont[i] = nil
    end 
  end
end

--------------------------------------------------------------------------------
function transposeNote(note)
  note = note + 4; --Shift into A centric.

  -- Works on tracker note values, as follows:
  local key_octave = get_note(note);
  local octave = note - key_octave;
  
  local scale_nums = {};
  local scale_num_ct = 0;
  local scale_num = 0;
  
  for i = 0,#scale_pattern do
    local r = i+1;
    if (scale_pattern[r]) then
      scale_num_ct = scale_num_ct + 1;
      scale_nums[scale_num_ct] = r;
      if (key_octave == r) then
        scale_num = scale_num_ct;
      end
    end    
  end

  if (scale_num > 0) then
    scale_num = scale_num + transpose_increment;
    octave = octave + 12 * math.floor((scale_num - 1) / scale_num_ct)
    key_octave = scale_nums[(scale_num - 1) % scale_num_ct + 1];
    print(octave, key_octave, scale_num)
  end
  
  local newnote = octave + key_octave - 4; --shift back to C center.
  
  if (newnote < 0 or newnote >= 120) then 
    return note - 4; --shift back to C center.
  end
  
  return newnote;
end

function transposeSelection()
  local track = renoise.song().selected_track_index
  local line = renoise.song().selected_line_index
  local pattern = renoise.song().selected_pattern_index
  local selected_line = renoise.song().patterns[pattern].tracks[track].lines[line]
  local visiblecols = renoise.song().tracks[track].visible_note_columns;
  local note_column_selected = renoise.song().selected_note_column_index

  for index,note_column in pairs(selected_line.note_columns) do 
    local note = note_column.note_value;
    if index <= visiblecols and note <= 119 then
      if (transpose_chord or index == note_column_selected) then
        note_column.note_value = transposeNote(note);
        print(note_column.note_string)
      end
    end
  end
end

function add_chord(root, chord)
  local cpattern = chord["pattern"]
  local res = ''
  local note_offset = 0
  local current_instrument = renoise.song().selected_instrument_index
  
  for n = 1, #cpattern do
    if cpattern:sub(n, n) == '1' then
      local note = root + n - 1;
      -- Form the string for chord note listing
      if res ~= '' then 
        res = res .. ', '
      else
        res = 'Chord ' ..  get_nname(root) .. chord["code"] .. ': '
      end
      res = res .. get_nname(note)
     
      -- Insert note
      insert_note(note, note_offset, current_instrument)
      note_offset = note_offset + 1
    end
  end
  
  -- OFF rest of the notes
  local vnc = renoise.song().selected_track.visible_note_columns
  if vnc > note_offset then
    for i = note_offset + 1,vnc do
      local nc = renoise.song().selected_line.note_columns[i]
      nc.note_value = 120
      nc.instrument_value = 255
    end
  end 
end
--------------------------------------------------------------------------------
function update()
  clear_cb()
  scale_pattern = get_scale(scale_root, scales[scale_type])
  local res = ''
  local sn = 0
  for n = scale_root, scale_root + 11 do
    if scale_pattern[get_note(n)] then
      print(get_note(n))
      -- Form the string for scale note listing
      if res ~= '' then 
        res = res .. ', '
      else
        res = 'Scale: '
      end
      res = res .. get_nname(n)
    end
  end
  sdisplay.text = res
end

--------------------------------------------------------------------------------
snames = { }
for key, scale in ipairs(scales) do
  table.insert(snames,scale['name'])
end
local dialog_view

function create_dialog ()
  dialog_view = vb:column {  
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    vb:column {
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      vb:row {
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        width = 700,
        style = 'group',
        vb:text { text = 'Key:' },
        vb:popup { 
          items = notes, 
          value = scale_root,
          notifier = function (i) scale_root = i; print(i); update() end 
        },
        vb:text { text = ' Scale:' },
        vb:popup { 
          items = snames,  
          value = scale_type,
          notifier = function (i) scale_type = i; update() end  
        },
        sdisplay
      },
      vb:column {
        width = 700,
        style = 'group',
        vb:row {
          spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
          margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN, 
          vb:text { text = 'Increment:' },
          vb:valuebox {
            min = -128,
            max = 128,
            value = transpose_increment,
            notifier = function(i) transpose_increment = i; end
          },
          vb:text { text = ' Chord mode:' },
          vb:checkbox {
            value = transpose_chord,
            notifier = function(i) transpose_chord = i; end
          },
        }
      }
    }
  }
end

function handle_keys(d, key)
  --print(key.name)
  
  local note_column = renoise.song().selected_note_column_index

  local track = renoise.song().selected_track_index
  local line = renoise.song().selected_line_index
  local pattern = renoise.song().selected_pattern_index
  local selected_line = renoise.song().patterns[pattern].tracks[track].lines[line]
  
  local pattern_size = renoise.song().patterns[pattern].number_of_lines
  local max_tracks = renoise.song().sequencer_track_count

  -- close on escape...
  if (key.modifiers == "" and key.name == "esc") then
    d:close()
  end
  
  if key.name == 'return' then
    transposeSelection();
  end

  if (key.name == 'return' or key.name == "down") then
    local increment = 1;
    if (key.name == 'return') then
      increment = renoise.song().transport.edit_step;
    end
    
    if line + increment <= pattern_size then
      line = line + increment
    else
      line = line + increment - pattern_size;
    end
    renoise.song().selected_line_index = line 

  elseif (key.name == "up") then
    if line - 1 >= 1 then
      line = line - 1 
    else 
      line = pattern_size
    end
    renoise.song().selected_line_index = line 

  elseif (key.name == "left") then
    -- Try to go to the column to the left.
    if note_column - 1 >= 1 then
      note_column = note_column - 1
    else
      -- Go to the prior track.
      if renoise.song().selected_track_index - 1 >= 1 then
        track  = renoise.song().selected_track_index - 1
      else
        track = max_tracks
      end
      renoise.song().selected_track_index = track
      note_column = renoise.song().tracks[track].visible_note_columns
    end
    renoise.song().selected_note_column_index = note_column
    
  elseif (key.name == "right") then
    -- Try to go to the column to the right.
    if note_column + 1 <= (renoise.song().tracks[track].visible_note_columns) then
      note_column = note_column + 1
    else
      -- Go to the next track!
      note_column = 1      
      if renoise.song().selected_track_index + 1 <= max_tracks then
        renoise.song().selected_track_index = renoise.song().selected_track_index + 1
      else
        renoise.song().selected_track_index = 1
      end
    end
    renoise.song().selected_note_column_index = note_column
    
  else
    return key
  end
end

--------------------------------------------------------------------------------
local dialog
function display()
  update()
  
  if dialog_view == nil then
    create_dialog()
  end
  
  if dialog == nil or not dialog.visible then
    dialog = renoise.app():show_custom_dialog('Transposer', 
        dialog_view, handle_keys )
  end
end

--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Transposer...",
   invoke = display
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. "Transposer" .. "...",
  invoke = display
}

