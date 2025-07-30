---@class ChorderModel
---@field line integer?
---@field target WriteTarget
---@field notes integer[]?
---@field selected integer
---@field instrument integer
---@field left_interval integer
---@field right_interval integer
---@field interval_level integer
---@field state ModState
---@field repeated boolean
---@field released boolean
---@field mods ModKeys
---@field major boolean
---@field retrigger boolean

---@type fun() : ChorderModel
local function ChorderModel()
  return {
    line = 0,
    target = "Pattern Editor",
    mods = {},
    notes = {},
    selected = 1,
    instrument = 0,
    interval_level = 2,
    left_interval = 3,
    right_interval = 4,
    state = ModState.none,
    major = false,
    retrigger = false,
    repeated = false,
    released = false,
  }
end

---@type fun(n:integer) : boolean
local function valid_note(n)
  return n < 120 and n >= 0 
end

---@type fun(notes:integer[], interval : integer)
local function insert_note(notes, interval)
  local n = notes[#notes] + interval
  if valid_note(n) then
    table.insert(notes, n)
  end
end

---@type integer[]
local right_intervals = {
  2, 4, 5, 7, 9,  11, 12, 14, 16
}

---@type integer[]
local left_intervals = {
  1, 3, 6, 8, 10,  13, 15, 18, 20
}

---@type string[]
local interval_short_names = {
  "m2", "M2", "m3", "M3", "P4",  "T", "P5", "m6", "M6", "m7", "M7", "Oct",
  "m9", "M9", "m10", "M10", "M11", "T2", "M13", "m14"
}


---@type fun(m:ChorderModel)
local function modify_last(m)
  local i = left_intervals[m.interval_level]
  if m.major then
    i = right_intervals[m.interval_level]
  end
  local n = m.notes[#m.notes - 1] + i
  if valid_note(n) then
    m.notes[#m.notes] = n
  end
end

---@type fun(t:table) : table
local function remove_duplicates(t)
  local r = {}
  for i = 1, #t do
    if table.find(r, t[i]) == nil then
      table.insert(r, t[i])
    end
  end
  return r
end


---@type fun(m:ChorderModel)
local function validate_model(m)
  local last_note_selected = m.notes[m.selected]
  m.notes = remove_duplicates(m.notes)
  table.sort(m.notes)
  local new_selected_index = table.find(m.notes, last_note_selected)
  if new_selected_index ~= nil then
    ---@cast new_selected_index integer
    m.selected = new_selected_index
  end
  m.selected = clamp(m.selected, 1, #m.notes)
end


---@type fun(notes : integer[], index : integer, direction : integer) : integer?
local function find_inverted_note(notes, index, direction)
  local n = notes[index] + direction * 12
  if not valid_note(n) then return nil end
  if table.find(notes, n) ~= nil then
    return find_inverted_note(notes, index, direction + sign(direction))
  else
    return n
  end
end

---@type fun(notes : integer[], index : integer, direction : integer) : integer?
local function find_empty_note(notes, index, direction)
  local n = notes[index] + direction
  if not valid_note(n) then return nil end
  if table.find(notes, n) ~= nil then
    return find_empty_note(notes, index, direction + sign(direction))
  else
    return n
  end
end

---@type fun(notes:integer[], direction:integer) : integer[]
local function transpose_notes(notes, direction)
  local ns = {}
  for i = 1, #notes do
    local n = notes[i] + direction
    if not valid_note(n) then
      return notes
    else
      table.insert(ns, n)
    end
  end
  return ns
end  

---@type fun(m:ChorderModel)
local function invert_up(m)
  local n = find_inverted_note(m.notes, 1, 1)
  if n ~= nil then
    table.remove(m.notes, 1)
    table.insert(m.notes, n)
  end
  m.selected = #m.notes
end

---@type fun(m:ChorderModel)
local function invert_down(m)
  local n = find_inverted_note(m.notes, #m.notes, -1)
  if n ~= nil then
    table.remove(m.notes)
    table.insert(m.notes, 1, n)
  end
  m.selected = 1
end

---@type fun(m:ChorderModel):boolean
local function has_more_than_one(m)
  return #m.notes > 1
end

---@type fun(m:ChorderModel):boolean
local function can_insert_note(m)
  return #m.notes < 12
end

---@type fun(notes : integer[], index : integer, direction : integer)
local function transpose_note(notes, index, direction)
  local n = find_empty_note(notes, index, direction)
  if n ~= nil then
    notes[index] = n
  end
end

---@type fun(m:ChorderModel, direction:integer)
local function select_note(m, direction)
  m.selected = wrapi(m.selected + direction, #m.notes)
end

---@type fun(d:integer)
local function step_line(d)
  local s = renoise.song()
  if s == nil then return end
  if not s.transport.wrapped_pattern_edit then
    s.selected_line_index = wrapi(s.selected_line_index + d, s.selected_pattern.number_of_lines)
  else
    local nt = s.selected_line_index + d
    local seq = s.selected_sequence_index
    if nt < 1 then 
      if seq == 1 then
        return
      else
        s.selected_sequence_index = seq - 1
        s.selected_line_index = s.selected_pattern.number_of_lines
      end
    elseif nt > s.selected_pattern.number_of_lines then
      if seq == #s.sequencer.pattern_sequence then
        return
      else
        s.selected_sequence_index = seq + 1
        s.selected_line_index = 1
      end
    else
      s.selected_line_index = nt
    end
  end
end

---@type table <string, UpdateKeys<ChorderModel>>
local updates = {
  [ModState.none] = {
    space = function (m)
      if m.target == "Pattern Editor" and not m.repeated then
        if m.released then
          renoise.song().transport:stop()
        else
          renoise.song().transport:start_at(m.line)
        end
      end
      return m
    end,
    left = function(m)
      if can_insert_note(m) then
        insert_note(m.notes, left_intervals[m.interval_level])
        m.major = false
        m.selected = #m.notes
      end
      return m
    end,
    right = function (m)
      if can_insert_note(m) then
        insert_note(m.notes, right_intervals[m.interval_level])
        m.major = true
        m.selected = #m.notes
      end
      return m
    end,
    up = function (m)
      if has_more_than_one(m) then
        m.interval_level = clamp(m.interval_level + 1, 1, 9)
        modify_last(m)
      else
        transpose_note(m.notes, 1, 1)
      end
      return m
    end,
    down = function (m)
      if has_more_than_one(m) then
        m.interval_level = clamp(m.interval_level - 1, 1, 9)
        modify_last(m)
      else
        transpose_note(m.notes, 1, -1)
      end
      return m
    end,
    back = function(m)
      if has_more_than_one(m) then
        table.remove(m.notes, m.selected)
      end
      return m
    end
  },
  [ModState.alt] = {
    space = function (m)
      return nil
    end,
    left = function(m)
      return nil
    end,
    right = function (m)
      return nil
    end,
    up = function (m)
      step_line(-1)
      return nil
    end,
    down = function (m)
      step_line(1)
      return nil
    end,
    back = function(m)
      return nil
    end
  },
  [ModState.shift] = {
    space = function (m)
      if not m.repeated and not m.released then
        m.retrigger = not m.retrigger
        renoise.song().transport.playing = m.retrigger
      end
      return m
    end,
    left = function(m)
      if has_more_than_one(m) then
        invert_down(m)
      end
      return m
    end,
    right = function (m)
      if has_more_than_one(m) then
        invert_up(m)
      end
      return m
    end,
    up = function (m)
      m.notes = transpose_notes(m.notes, ifthen(m.mods.control, 1, 12))
      return m
    end,
    down = function (m)
      m.notes = transpose_notes(m.notes, ifthen(m.mods.control, -1, -12))
      return m
    end,
    back = function(m)
      if has_more_than_one(m) then
        table.remove(m.notes)
      end
      return m
    end
  },
  [ModState.control] = {
    left = function(m)
      select_note(m, -1)
      return m
    end,
    right = function (m)
      select_note(m, 1)
      return m
    end,
    up = function (m)
      transpose_note(m.notes, m.selected, 1)
      return m
    end,
    down = function (m)
      transpose_note(m.notes, m.selected, -1)
      return m
    end,
    back = function(m)
      if has_more_than_one(m) then
        table.remove(m.notes)
      end
      return m
    end
  }

}

---@type fun(s:renoise.Song) : integer?
local function line_from_phrase(s)
  if s.selected_phrase then
    local sel = s.selection_in_phrase
    if sel then
      return sel.start_line
    end
  end
  return nil
end

---@type fun(s:renoise.Song, m : ChorderModel)
local function apply(s, m)
  m.line = s.selected_line_index
  validate_model(m)

  if m.target == "Pattern Editor" then  
    for i = 1, s.selected_track.visible_note_columns do
      s.selected_line:note_column(i):clear()
    end
    for i = 1, #m.notes do
      s.selected_line:note_column(i).note_value = m.notes[i]
      s.selected_line:note_column(i).instrument_value = m.instrument
    end
    
    set_pattern_note_columns(s, s.selected_track_index, #m.notes)


    s.selection_in_pattern = {
      start_track = s.selected_track_index,
      end_track = s.selected_track_index,
      start_column = #m.notes,
      end_column = #m.notes,
      start_line = m.line,
      end_line = m.line,
    }
    if m.retrigger and not m.released and not m.repeated then
      s.transport:start_at(m.line)
    end
    
  else
    local line = line_from_phrase(s)
    if line ~= nil then
      m.line = line
      for i = 1, s.selected_phrase.visible_note_columns do
        s.selected_phrase:line(line):note_column(i):clear()
      end

      for i = 1, #m.notes do
        s.selected_phrase:line(line):note_column(i).note_value = m.notes[i]
      end

      set_phrase_note_columns(s.selected_phrase, #m.notes)

      s.selection_in_phrase = {
        start_column = #m.notes,
        end_column = #m.notes,
        start_line = line,
        end_line = line,
      }
    end
    -- reduce_phrase_note_columns(s, s.selected_track_index)
  end
end

---@type fun(s:renoise.Song) : integer[]?
local function get_chord_from_pattern(s)
  local cs = {}
  if s.selected_line then
    for i = 1, s.selected_track.visible_note_columns do
      local n = s.selected_line:note_column(i).note_value
      if valid_note(n) then
        table.insert(cs, n)
      end
    end
  end
  if #cs > 0 then return cs else return nil end
end


---@type fun(s:renoise.Song, line : integer) : integer[]?
local function get_chord_from_phrase(s, line)
  local cs = {}
  for i = 1, s.selected_phrase.visible_note_columns do
    local n = s.selected_phrase:line(line):note_column(i).note_value
    if valid_note(n) then
      table.insert(cs, n)
    end
  end
  if #cs > 0 then return cs else return nil end
end

---@type fun(predicate:boolean, when_true:any, when_false:any):any
local function ifthen(predicate, when_true, when_false)
  if predicate then return when_true else return when_false end  
end

---@type boolean[]
local white_keys = {true, false, true, false, true,  true, false, true, false, true, false, true}
---@type string[]
local note_names = {"C\n", "C\n#", "D\n", "D\n#", "E\n", "F\n", "F\n#", "G\n", "G\n#", "A\n", "A\n#", "B\n"}

---@alias OctaveRange {from : integer, to : integer}

---@type fun(note : integer) : integer
local function octave_of(note)
  return math.floor(note / 12)
end

---@type fun(notes:integer[]) : OctaveRange
local function chord_range(notes)
  return {from = octave_of(notes[1]), to = octave_of(notes[#notes])}
end

---@type fun(vb : ViewBuilderInstance, notes : integer[], selected : integer) : renoise.Views.View
local function chord_display(vb, notes, selected)
  local w = 10
  local ks = vb:horizontal_aligner({
    margin = 0,
    spacing = -5,

    -- width = (to - from) * w
  })
  local from = notes[1]
  local to = notes[#notes]
  to = clamp(to, from + 12, 120)
  local octave = chord_range(notes)
  local white = {0xdd, 0xdd, 0xdd}
  local black = {0x66, 0x66, 0x66}
  local high = {0xaa, 0x66, 0x22}
  local note_index = 0
  for i = from, to do
    local k = i % 12
    local f = table.find(notes, i)
    if f ~= nil then
      note_index = note_index + 1
    end
    local kb = vb:column{
      uniform = true,
      spacing = -2,
      vb:button{
        active = true,
        width = w,
        height = w * 3,
        color = ifthen(white_keys[(k%12) + 1], white, black),
        text = ifthen(f ~= nil and note_index == selected, "*\n", " \n")
      },
      vb:button{
        -- notifier = function() end
        active = true,
        width = w,
        visible = f ~= nil,
        color = ifthen(white_keys[(k%12) + 1], white, black),
        text = ifthen(f ~= nil, note_names[k + 1].."\n"..octave_of(i), " \n"),
      },
    }
    ks:add_child(kb)
  end
  return ks
end

---@type PadInit<ChorderModel>
local function init(s, m, flag)
  local  model = ChorderModel()
  model.target = flag
  if m ~= nil then
    model.retrigger = m.retrigger
  end

  if model.target == "Pattern Editor" then
    if s.selected_track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
      return "Wrong Track#You can only write chords on sequencer tracks. Select something other than a group, send or master track and try again."
    end
    model.line = s.selected_line_index
    model.notes = get_chord_from_pattern(s)

    if model.notes == nil then
      model.notes = { 48 }
      model.instrument = s.selected_instrument_index - 1
    else
      model.instrument = s.selected_line:note_column(1).instrument_value
    end
  else
    local phrase = s.selected_phrase
    if phrase == nil then
      return "No Phrase#You need to select an existing phrase to put chords in. Select a phrase, select a line inside of it and and try again."
    end

    model.line = line_from_phrase(s)
    if model.line == nil then 
      model.line = 1
      renoise.app():show_status("chorder - no line selected in phrase, using first line.")
      -- return "No line selected#Please select a line inside the phrase to start building a chord at. Otherwise tools have no way of knowing your location inside a phrase."
    end

    model.notes = get_chord_from_phrase(s, model.line)

    if model.notes == nil then
      model.notes = { 48 }
    end
  end

  model.selected = #model.notes
  model.state = ModState.none
  model.interval_level = 2
  apply(s, model)
  return model
end

---@type PadUpdate<ChorderModel>
local function update(s, m, e)
  local changed_state = false
  local mods = get_mods(e.modifiers)
  for k, v in pairs(mods) do
    if m[k] ~= v then
      changed_state = true
    end
  end

  m.mods = mods
  m.repeated = e.repeated
  m.released = e.state == "released"

  if m.mods.shift and not m.mods.alt then
    m.state = ModState.shift
  elseif m.mods.control then
    m.state = ModState.control
  elseif m.mods.alt then
    m.state = ModState.alt
  else
    m.state = ModState.none
  end

  if e.state ~= "released" or e.name == "space" then
    if updates[m.state] then
      if updates[m.state][e.name] then
        local next = updates[m.state][e.name](m)
        if next ~= nil then
          apply(s, m)
        end
        return {PadMessage.model, m}
      end
    end
    if e.name == "return" then
      return {PadMessage.close}
    end
  end
  if changed_state then
    return {PadMessage.model, m}
  end
  return {PadMessage.ignore}
end


---@type PadView<ChorderModel>
local function view(s, vb, m)
  local keys = chord_display(vb, m.notes, m.selected)
  local shift_mode = m.state == ModState.shift
  local base_mode = m.state == ModState.none
  local alt_mode = m.state == ModState.alt
  local control_mode = m.state == ModState.control
  local base_style = ifthen(base_mode, "normal", "disabled")
  local shift_style = ifthen(shift_mode, "normal", "disabled")
  local alt_style = ifthen(alt_mode, "normal", "disabled")
  local control_style = ifthen(control_mode, "normal", "disabled")
  local function text(t, style)
    return vb:text {
      font = "mono",
      text = t,
      style = style
    }
  end
  local function horizontal(visible, mode, views)
    local h = vb:horizontal_aligner {
      visible = visible,
      mode = mode,
      width = "100%",
    }
    for i = 1, #views do
      h:add_child(views[i])
    end
    return h
  end
  local updown = function() return text("[up down]", "normal") end
  local v = vb:column{
    height = 200,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
    -- width = 100,
    vb:horizontal_aligner{
      mode = "justify",
      vb:text {
        visible = #m.notes > 1,
        font = "mono",
        style = ifthen(s.transport.playing or m.retrigger, "normal", "disabled"),
        text = ifthen(shift_mode, "[space] toggle", ifthen(m.retrigger, "[shift] auto", "[space] play"))
      },
      vb:text {
        visible = #m.notes > 1,
        font = "mono",
        text = "<| remove"
      },
    },
    keys,
    vb:column{
      width = "100%",
      uniform = true,
      
      horizontal(base_mode, "center", {
        text(ifthen(#m.notes == 1, "transpose", " interval")),
        updown(),
      }),
      horizontal(base_mode, "justify", {
        text("< "..interval_short_names[left_intervals[m.interval_level]]),
        text(interval_short_names[right_intervals[m.interval_level]] .. " >"),
      }),

      horizontal(control_mode, "center", {
        text("transpose"),
        updown(),
      }),
      horizontal(control_mode, "justify", {
        text("< "),
        text(ifthen(#m.notes == 1, "", "select")),
        text(" >"),
      }),

      horizontal(shift_mode, "center", {
        text(ifthen(m.mods.control, "transpose","  octave ")),
        updown(), 
      }),
      horizontal(shift_mode, "justify", {
        text("<  ", shift_style),
        text("invert", shift_style),
        text("  >", shift_style),
      }),

      horizontal(alt_mode, "center", {
        text("   move  "),
        updown(),
      }),
      horizontal(alt_mode, "justify", {
        text("< "),
        text(""),
        text("  >"),
      }),

      horizontal(true, "center", {
        text("[ctrl]", control_style),
        text("[shift]", shift_style),
        text("[alt]", alt_style),
      }),
    },
    -- output,
  }
  return v
end

---@type PadModule<ChorderModel>
ChorderPad = {
  update = update,
  init = init,
  view = view,
  save = true,
}