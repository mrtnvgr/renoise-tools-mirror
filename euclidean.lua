---@class NoteHit
---@field note integer
---@field instrument integer
---@field vol integer
---@field pan integer
---@field fx string

---@class EuclidModel
---@field target WriteTarget
---@field pattern boolean[]
---@field state string
---@field notes NoteHit[][]
---@field from integer
---@field to integer
---@field length integer
---@field steps integer
---@field pulses integer
---@field rotate integer
---@field offset integer
---@field shift integer
---@field repeats integer
---@field swing number
---@field swing_window integer
---@field swing_size integer
---@field swing_offset integer
---@field delay number
---@field selected integer
---@field snap integer


---@type fun() : EuclidModel
local function EuclidModel()
  return {
    selected = 1,
    target = "Pattern Editor",
    pattern = {},
    state = "base",
    pulses = 6,
    steps = 8,
    rotate = 0,
    offset = 0,
    shift = 0,
    repeats = 1,
    swing = 0,
    swing_window = 2,
    swing_size = 4,
    swing_offset = 0,
    delay = 0,
    snap = 2,
  }
end

---@type string[]
local Fields = {
  "pulses",
  "steps",
  "rotate",
  "offset",
  "shift",
  "repeats",
  "swing",
  "swing_size",
  "swing_window",
  "swing_offset",
  "delay",
  "snap",
}
---@type table <string, integer>
local Field = {}
for i = 1, #Fields do
  Field[Fields[i]] = i
end

---@enum Snap
local Snap = {
  none = 1,
  line = 2,
}

---@type table <string, fun(m:EuclidModel, x : any)>
local set_field = {}
set_field = {
  pulses = function(m, x)
    m.pulses = clamp(x, 1, m.steps)
    set_field.repeats(m, m.repeats)
  end,
  steps = function(m, x)
    m.steps = clamp(x, 1, m.length)
    set_field.pulses(m, m.pulses)
  end,
  rotate = function(m, x)
    m.rotate = wrap(x, m.steps)
  end,
  offset = function(m, x)
    m.offset = wrap(x, m.length)
  end,
  shift = function(m, x)
    m.shift = wrap(x, #m.notes)
  end,
  repeats = function(m, x)
    m.repeats = clamp(x, 1, m.pulses)
  end,
  swing = function(m, x)
    m.swing = clamp(x, 0, 1)
  end,
  swing_size = function(m, x)
    m.swing_size = clamp(x, 2, m.length)
    set_field.swing_window(m, m.swing_window)
    set_field.swing_offset(m, m.swing_offset)
  end,
  swing_window = function(m, x)
    m.swing_window = clamp(x, 0, m.swing_size - 1)
  end,
  swing_offset = function(m, x)
    m.swing_offset = wrap(x, m.swing_size)
  end,
  delay = function(m, x)
    m.delay = clamp(x, 0, 1)
  end,
  snap = function(m, x)
    m.snap = clamp(x, 1, 2)
  end,
}

---@type fun(m : EuclidModel)
local function validate_all(m)
  for i = 1, #Fields do
    set_field[Fields[i]](m, m[Fields[i]])
  end
end

---@type fun(m : EuclidModel, selected:integer, dir:number)
local function offset_field(m, selected, dir)
  if selected == Field.delay or selected == Field.swing then 
    dir = dir * (1.0 / 256)
  end

  set_field[Fields[selected]](m, m[Fields[selected]] + dir)
  if m.target == "Pattern Editor" then
    renoise.song().selected_track.delay_column_visible = m.delay > 0 or m.swing > 0 or m.snap == Snap.none
  else
    local ph = renoise.song().selected_phrase
    if ph then
      ph.delay_column_visible = m.delay > 0 or m.swing > 0 or m.snap == Snap.none
    end
  end
end

---@type table <string, UpdateKeys<EuclidModel>>
local updates = {
  base = {
    left = function(m, mods)
      offset_field(m, m.selected, ifthen(mods.control, -10, -1))
      return m
    end,
    right = function (m, mods)
      offset_field(m, m.selected, ifthen(mods.control, 10, 1))
      return m
    end,
    up = function (m)
      m.selected = wrapi(m.selected - 1, #Fields)
      return m
    end,
    down = function (m)
      m.selected = wrapi(m.selected + 1, #Fields)
      return m
    end,
    back = function(m)
      local field = m.selected
      local defaults = EuclidModel()
      set_field[Fields[field]](m, defaults[Fields[field]])
      return m
    end
  },
  shift = {
    left = function(m)
      return m
    end,
    right = function (m)
      return m
    end,
    up = function (m)
      return m
    end,
    down = function (m)
      return m
    end,
    back = function(m)
      return m
    end
  }

}

---@alias GeneratedLine {line : integer, note : NoteHit[]?, delay : number?}

---@type fun(l : GeneratedLine, line : renoise.PatternLine)
local function write_pattern_line(l, line)
  for ni = 1, #l.note do
    local n = l.note[ni]
    local nc = line:note_column(ni)
    nc.note_value = n.note
    nc.instrument_value = n.instrument
    nc.panning_value = n.pan
    nc.volume_value = n.vol
    nc.effect_number_string = n.fx:sub(1,2)
    nc.effect_amount_string = n.fx:sub(3,4)
    nc.delay_value = math.floor(l.delay * 255 + 0.5)
  end
end



-- ---@type fun(s: renoise.Song, m : EuclidModel, steps:boolean[])
-- local function write_notes_evenly(s, m, steps)
--   local pt = s.selected_pattern:track(s.selected_track_index)
--   for i = m.from, m.to do
--     pt:line(i):clear()
--   end
--   local step_size = #steps / m.length
--   local index = -1
--   local inner_index = 1
--   -- local lpb = s.transport.lpb
--   -- local swing_window = math.ceil((lpb) / m.swing_window)
--   for i = 1, m.length do
--     local t = (i - 1) / m.length
--     local ii = math.floor(t * #steps)
--     if ii ~= index then
--       local li = wrapi(i + m.offset, m.length)
--       local delay = t * #steps - ii
--       index = ii
--       local swing = ifthen(((i - 1 + m.swing_offset) % m.swing_size) < (m.swing_size - m.swing_window), 0, m.swing)
--       -- local swing = ifthen(((i - 1) % lpb) % math.floor(lpb / 2) == 0, m.swing, 0.0)
--       if steps[index + 1] then
--         write_note_hit_to_line(
--           m.notes[wrapi(math.ceil((inner_index + m.shift) / m.repeats), #m.notes)], 
--           pt:line(li),
--           clamp(ifthen(m.snap == Snap.line, m.delay + swing, delay + m.delay + swing), 0, 0.9999999999)
--         )
--         inner_index = inner_index + 1
--       end
--     end
--   end
-- end


---@type fun(m : EuclidModel, steps:boolean[]) : GeneratedLine[]
local function generate_lines(m, steps)
  local ns = {}
  local index = -1
  local inner_index = 1
  for i = 1, m.length do
    local t = (i - 1) / m.length
    local ii = math.floor(t * #steps)
    local li = wrapi(i + m.offset, m.length)
    if ii ~= index then
      local delay = t * #steps - ii
      index = ii
      local swing = ifthen(((li - 1 + m.swing_offset) % m.swing_size) < (m.swing_size - m.swing_window), 0, m.swing)
      if steps[index + 1] then
        table.insert(ns, {
          line = li,
          note = m.notes[wrapi(math.ceil((inner_index + m.shift) / m.repeats), #m.notes)],
          delay = clamp(ifthen(m.snap == Snap.line, m.delay + swing, delay + m.delay + swing), 0, 0.9999999999)
        })
        inner_index = inner_index + 1
      else
        table.insert(ns, {line = li})
      end
    else
      table.insert(ns, {line = li})
    end
  end
  return ns
end


---@type fun(s:renoise.Song, m : EuclidModel)
local function apply(s, m)
  m.pattern = euclid_pattern(m.pulses, m.steps, m.rotate)
  local lines = generate_lines(m, m.pattern)
  if m.target == "Pattern Editor" then
    local pt = s.selected_pattern:track(s.selected_track_index)
    for i = m.from, m.to do
      pt:line(i):clear()
    end
    for i = 1, m.length do
      if lines[i].note then
        write_pattern_line(lines[i], pt:line(lines[i].line))
      end
    end

  elseif m.target == "Phrase Editor" then
    local ph = s.selected_phrase
    if ph then
      for i = m.from, m.to do
        ph:line(i):clear()
      end

      for i = 1, m.length do
        if lines[i].note then
          write_pattern_line(lines[i], ph:line(i))
        end
      end
    end
  end
end

---@type fun(l : renoise.PatternLine, note_columns : integer) : NoteHit[]?
local function pattern_line_to_note_hit(l, note_columns)
  if not l:note_column(1).is_empty then
    local ns = {}
    for i = 1, note_columns do
      local nc = l:note_column(i)
      if not nc.is_empty then
        table.insert(ns, {
          note = nc.note_value,
          instrument = nc.instrument_value,
          pan = nc.panning_value,
          vol = nc.volume_value,
          fx = nc.effect_number_string .. nc.effect_amount_string,
        })
      end
    end
    return  ns
  else
    return nil
  end
end

---@type fun(s: renoise.Song, p : integer, t:integer, from:integer, to:integer) : NoteHit[][]
local function collect_notes_from_pattern(s, p, t, from, to)
  local hs = {}
  local pt = s:pattern(p):track(t)
  local note_columns = s:track(t).visible_note_columns

  for i = from, to do
    local pulses = pattern_line_to_note_hit(pt:line(i), note_columns)
    if pulses then
      table.insert(hs, pulses)
    end
  end
  return hs
end

---@type fun(s: renoise.Song, i : integer, p:integer, from:integer, to:integer) : NoteHit[][]
local function collect_notes_from_phrase(s, i, p, from, to)
  local hs = {}
  local ph = s:instrument(i):phrase(p)
  local note_columns = ph.visible_note_columns

  for li = from, to do
    local pulses = pattern_line_to_note_hit(ph:line(li), note_columns)
    if pulses then
      table.insert(hs, pulses)
    end
  end
  return hs
end

---@type fun(m:EuclidModel)
local function update_length(m)
  m.length = m.to - m.from + 1
end


---@type fun(target : WriteTarget, s:renoise.Song, m:EuclidModel)
local function select_whole(target, s, m)
  m.from = 1
  m.to = s["selected_"..ifthen(target == "Pattern Editor", "pattern", "phrase")].number_of_lines
  update_length(m)
end

-- ---@type fun(s:renoise.Song) : WriteTarget?
-- local function get_target(s)
--   local mf = renoise.app().window.active_middle_frame
--   if mf == renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR then
--     return "Pattern Editor"
--   elseif mf = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR then
--     return "Phrase Editor"
--   else
--     return nil
--   end
-- end


---@type PadInit<EuclidModel, WriteTarget>
local function init(s, m, flag)
  local  model = EuclidModel()
  model.target = flag
  if m ~= nil then
    model.pulses = m.pulses
    model.steps = m.steps
    model.rotate = m.rotate
    model.offset = m.offset
    model.repeats = m.repeats
    model.delay = m.delay
    model.swing = m.swing
    model.snap = m.snap
  end


  if model.target == "Pattern Editor" then
    model.swing_size = s.transport.lpb
    model.swing_window = math.ceil(s.transport.lpb / 2)

    local track = s.selected_track_index
    if s.selected_track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
      return "Wrong Track#You can only generate euclidean rhythms on sequencer tracks. Select something other than a group, send or master track and try again."
    end
    
    select_whole("Pattern Editor", s, model)


    if s.selection_in_pattern then
      model.from = s.selection_in_pattern.start_line
      model.to = s.selection_in_pattern.end_line
      update_length(model)
    end

    if model.length == 1 then 
      select_whole("Pattern Editor", s, model)
    end
    
    s.selection_in_pattern = {
      start_track = track,
      end_track = track,
      start_line = model.from,
      end_line = model.to,
      start_column = 1,
      end_column = s.selected_track.visible_note_columns + s.selected_track.visible_effect_columns
    }
    model.notes = collect_notes_from_pattern(s, s.selected_pattern_index, s.selected_track_index, model.from, model.to)
  else
    local phrase = s.selected_phrase
    if phrase == nil then
      return "No Phrase#You need to select an existing phrase to generate euclidean patterns inside of. Create or select a phrase, put in some notes and try again."
    end

    model.swing_size = phrase.lpb
    model.swing_window = math.ceil(model.swing_size / 2)

    select_whole("Phrase Editor", s, model)

    if s.selection_in_phrase then
      model.from = s.selection_in_phrase.start_line
      model.to = s.selection_in_phrase.end_line
      update_length(model)
    end

    if model.length == 1 then 
      select_whole("Phrase Editor", s, model)
    end
    s.selection_in_phrase = {
      start_line = model.from,
      end_line = model.to,
      start_column = 1,
      end_column = s.selected_phrase.visible_note_columns + s.selected_phrase.visible_effect_columns
    }
    model.notes = collect_notes_from_phrase(s, s.selected_instrument_index, s.selected_phrase_index, model.from, model.to)

  end

  if #model.notes == 0 then
    return "No Notes#You need at least one note in your selection to generate a euclidean pattern!\nType in some note(s) or chord(s) or select some existing ones."
  else
    validate_all(model)
    apply(s, model)
    return model
  end
end

---@type PadUpdate<EuclidModel>
local function update(s, m, e, mods)
  if e.state == "released" then return {PadMessage.model, m} end
  if updates["base"] then
    if updates["base"][e.name] then
      m = updates["base"][e.name](m, mods)
      apply(s, m)
      return {PadMessage.model, m}
    end
  end

  local n = tonumber(e.name, 16)
  if n ~= nil then
    if m.selected ~= Field.delay and m.selected ~= Field.snap then
      set_field[Fields[m.selected]](m, n)
      apply(s, m)
    end
    return {PadMessage.model, m}
  elseif e.name == "return" then
    return {PadMessage.close}
  else
    return {PadMessage.ignore}
  end
end

---@type fun(vb: ViewBuilderInstance, p : boolean[]) : renoise.Views.View
local function pattern_display(vb, p)
  -- local width = 125
  local d = vb:column({
    -- uniform = true,
    width = 8,
    height = "100%",
    spacing = 0,
    margin = 8,
    -- mode = "center",
  })
  local on = {0xaa, 0xaa, 0xaa}
  local off = {0x55, 0x55, 0x55}
  for i = 1, #p do
    d:add_child(vb:button({
      width = 8,
      height = 6,
      -- width = clamp(100 / #p, 4, 100).."%",
      -- width = clamp(125 / #p, 4, 100),
      -- height = (100 / #p).."%",
      color = ifthen(p[i], on, off),
    }))
  end
  return d
end

---@type PadView<EuclidModel>
local function view(s, vb, m)
  local hints = {
    "number of pulses to have",
    "number of steps to distribute the pulses over",
    "rotate the distributed pattern around",
    "offset the pattern by lines",

    "cycle the note values",
    "number of repeats for each note",

    "amount of swing to apply inside the swing window",
    "number of lines to repeat the swing pattern over",
    "where to start swinging along the swing size",
    "shift the swing pattern backwards",

    "delay each pulse using the delay column",
    "quantize to lines or use delay for positioning"
  }
  local v = vb:column{
    -- height = 200,
    width = 125,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    uniform = true,
    value_row(vb, m, "pulses", "pulses", m.selected == Field.pulses, hints[Field.pulses]),
    value_row(vb, m, "steps", "steps", m.selected == Field.steps, hints[Field.steps]),
    value_row(vb, m, "rotate", "rotate", m.selected == Field.rotate, hints[Field.rotate]),
    value_row(vb, m, "offset", "offset", m.selected == Field.offset, hints[Field.offset]),
    value_row(vb, m, "shift", "cycle", m.selected == Field.shift, hints[Field.shift]),
    value_row(vb, m, "repeats", "repeats", m.selected == Field.repeats, hints[Field.repeats]),
    value_row(vb, m, "swing", "swing", m.selected == Field.swing, hints[Field.swing], true),
    value_row(vb, m, "swing_size", "size", m.selected == Field.swing_size, hints[Field.swing_size]),
    value_row(vb, m, "swing_window", "window", m.selected == Field.swing_window, hints[Field.swing_window]),
    value_row(vb, m, "swing_offset", "shift", m.selected == Field.swing_offset, hints[Field.swing_offset]),
    value_row(vb, m, "delay", "delay", m.selected == Field.delay, hints[Field.delay], true),
    check_row(vb, m, "snap", "snap", {"none __", "___ line" }, m.selected == Field.snap, hints[Field.snap]),
    vb:space{},
    vb:multiline_text {
      height = 50,
      width = "100%",
      text = hints[m.selected]
    },
  }
  return vb:row{
    -- uniform = true,
    v,
    -- pattern_display(vb, m.pattern),
  }
end

---@type PadModule<EuclidModel>
EuclidPad = {
  update = update,
  init = init,
  view = view,
  save = true,
}