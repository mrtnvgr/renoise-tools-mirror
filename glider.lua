---@class GliderModel
---@field mods ModKeys
---@field state string
---@field selected integer
---@field column integer
---@field track integer
---@field on integer
---@field off integer
---@field steps integer
---@field lines integer
---@field current_note integer
---@field previous_note integer
---@field remainder integer

---@type fun() : GliderModel
local function GliderModel()
  return {
    mods = {},
    state = "base",
    selected = 1,

    track = 1,
    column = 1,
    on = 0,
    off = 0,
    current_note = renoise.PatternLine.EMPTY_NOTE,
    previous_note = renoise.PatternLine.EMPTY_NOTE,

    remainder = 1,
    lines = 1,
    steps = 1,
  }
end

local FieldList = {"lines", "steps", "remainder"}

local Fields = {
  lines = {
    tooltip = "",
    step = function(m, dir)
      local match_length = m.steps == m.lines
      m.lines = clamp(m.lines + dir, 1, m.off - m.on + 1)
      m.steps = clamp(ifthen(match_length, m.lines, m.steps), 1, m.lines)
    end
  },
  steps = {
    tooltip = "",
    step = function(m, dir)
      m.steps = clamp(m.steps + dir, 1, m.lines)
    end
  },
  remainder = {
    show = "check",
    tooltip = "",
    step = function(m, dir)
      m.remainder = ifthen(m.remainder == 1, 2, 1)
    end
  }
}

local function step_selected(m, d)
  m.selected = wrapi(m.selected + d, #FieldList)
  -- local f = FieldList[m.selected]
  -- m[f] = 
  -- local needs = Fields[f].needs
  -- if needs == nil or table.find(needs.value, m[needs.field]) ~= nil then
  --   return
  -- else
  --   return step_selected(m, d)
  -- end  
end

-- local noop = function(m) return m end

---@type table <string, UpdateKeys<GliderModel>>
local updates = {
  base = {
    left = function(m)
      Fields[FieldList[m.selected]].step(m, -1)
      return m
    end,
    right = function (m)
      Fields[FieldList[m.selected]].step(m, 1)
      return m
    end,
    up = function (m)
      step_selected(m, -1)
      return m
    end,
    down = function (m)
      step_selected(m, 1)
      return m
    end,
    back = function(m)
      return m
    end,
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

local function interval(m)
  return math.abs(m.current_note - m.previous_note)
end

local function selection_from_model(s, m)
  s.selection_in_pattern = {
    start_track = m.track,
    end_track = m.track,
    start_line = m.on,
    end_line = m.on + (m.lines - 1),
    start_column = m.column,
    end_column = m.column,
  }
end

---@type fun(s:renoise.Song, m : GliderModel)
local function apply(s, m)
  selection_from_model(s, m)

  local pt = s.selected_pattern:track(s.selected_track_index)
  local inter = interval(m)
  local step_size = inter * 16
  local each = step_size / m.steps
  local whole = clamp(math.floor(each), 0, 254)
  local remainder = math.floor((each - whole) * m.steps)


  local euclid = euclid_pattern(m.steps, m.lines, 0)
  -- if not euclid[#euclid] then
  --   euclid[#euclid] = true
  --   for i = #euclid - 1, 1, -1 do
  --     if i == 0 or euclid[i] then
  --       euclid[i] = false
  --       break
  --     end
  --   end
  -- end

  local remainder_pattern = euclid_pattern(remainder, m.steps, 0)

  s.selected_track.sample_effects_column_visible = true
  local i = 0
  local ri = 1
  local last = 0
  for line = m.on, m.off do
    local c = pt:line(line):note_column(m.column)
    if i < m.lines then
      if euclid[i + 1] then
        c.effect_number_string = "0G"
        c.effect_amount_value = ifthen(m.remainder == 1, clamp(whole + ifthen(remainder_pattern[ri], 1, 0), 1, 254), whole)
        last = i
        ri = ri + 1
      else
        c.effect_number_value = 0
        c.effect_amount_value = 0
      end
    else
      c.effect_number_value = 0
      c.effect_amount_value = 0
    end

    i = i + 1
  end
  if m.on + last ~= m.off then
    local ff_column = pt:line(clamp(m.on + last + 1, m.on, m.off)):note_column(m.column)
    ff_column.effect_number_string = "0G"
    ff_column.effect_amount_value = 255
  end
end


---@type PadInit<GliderModel>
local function init(s, m)
  local t = s.selected_track
  if t.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    local  model = GliderModel()
    model.track = s.selected_track_index
    local pt = s.selected_pattern:track(s.selected_track_index)
    local column = s.selected_note_column_index
    local line = s.selected_line_index
    if column == 0 then 
      column = t.visible_note_columns
    end
    model.column = column
    model.on = get_note_on_from_pattern(pt, model.column, line)
    if model.on == 0 then 
      return "make sure you have at least one note in the track you are selected"
    end
    model.off = get_note_off_from_pattern(pt, model.column, line)
    if model.off > model.on then
      model.off = model.off - 1
    end


    model.current_note = pt:line(model.on):note_column(model.column).note_value

    if line == model.on then
      model.lines = model.off - model.on + 1
    else
      model.lines = line - model.on + 1
    end

    selection_from_model(s, model)

    model.steps = model.lines
    if m ~= nil then
    --   model.lines = clamp(m.lines, 1, model.off - model.on + 1)
      if m.steps ~= m.lines then
        model.steps = clamp(m.steps, 1, model.lines)
      end
    end

    local prev = get_note_on_from_song(s, model.track, s.selected_sequence_index, model.on - 1, model.column)
    if prev ~= nil then
      model.previous_note = prev
    else
      return "there is no previous note to glide from"
    end

    if interval(model) == 0 then
      return "the previous note is the same as the current one, there is nothing to glide"
    end
    for i = model.on, model.off do
      local c = pt:line(i):note_column(model.column)
      if c.effect_number_string ~= "00" or c.effect_number_string ~= "0G" then
        -- existing commands
      end
      c.effect_number_value = 0
      c.effect_amount_value = 0
    end

    apply(s, model)
    return model
  else
    return "select a track with note columns to generate glides"
  end
end

---@type PadUpdate<GliderModel>
local function update(s, m, e)
  m.mods = get_mods(e.modifiers)
  if e.state == "released" then return {PadMessage.model, m} end
  if e.modifiers == "shift" then 
    m.state = "shift"
  else
    m.state = "base"
  end

  if updates[m.state] then
    if updates[m.state][e.name] then
      m = updates[m.state][e.name](m)
      apply(s, m)
      return {PadMessage.model, m}
    end
  end
  if e.name == "return" then
    
    return {PadMessage.close, m}
  else
    return {PadMessage.ignore}
  end
end

---@type PadView<GliderModel>
local function view(s, vb, m)
  local v = vb:vertical_aligner{
    width = 150,
    height = 200,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    -- vb:horizontal_aligner{
    --   vb:text{
    --     text = "" 
    --   }
    -- }
  }
  for i = 1, #FieldList do
    local f = FieldList[i]
    if Fields[f].show == "check" then
      v:add_child(
        check_row(vb, m, "remainder", "remainder", {"spread _", "___ drop" }, i == m.selected, Fields[f].tooltip)
      )
    else
      v:add_child(
        value_row(vb, m, f, f, i == m.selected, Fields[f].tooltip, false)
      )
    end
  end
  return vb:row({
    v
  })
end

---@type PadModule<GliderModel>
GliderPad = {
  update = update,
  init = init,
  view = view,
  model = nil,
  title = "glider @icasiino",
  actions = {
    apply_last = function (s, m)
      return GliderPad.init(s, GliderPad.model)
    end
  }
}