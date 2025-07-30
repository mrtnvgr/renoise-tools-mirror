
---@enum LpbMode
local LpbMode = {
  empty = 1,
  fixed = 2,
  complex = 3
}
---@enum BpmMode
local BpmMode = {
  empty = 1,
  fixed = 2,
  calc = 3
}
---@enum TplMode
local TplMode = {
  empty = 1,
  fixed = 2,
}
local show_enum = {
  TPL_mode = {"keep TPL", "edit TPL"},
  LPB_mode = {"keep LPB", "edit LPB"},
  BPM_mode = {"keep BPM", "edit BPM", "calc BPM"},
}
---@class BarsModel
---@field state string
---@field mods ModKeys
---@field beats number
---@field beats_fraction_index integer
---@field LPB integer
---@field bars integer
---@field LPB_mode LpbMode
---@field TPL_mode TplMode
---@field TPL TplMode
---@field BPM_mode BpmMode
---@field BPM integer
---@field BPM_X integer
---@field BPM_Y integer
---@field patterns integer
---@field selected integer

---@class Timing
---@field bpm integer?
---@field lpb integer?
---@field tpl integer?


---@type fun(n:integer):integer[]
local function whole_divisors(n)
  local r = {}
  local max = math.floor(n / 2)
  for i = 2, max do
    local remainder = n / i
    if remainder == math.floor(remainder) then table.insert(r, i) end
  end
  table.insert(r, n)
  return r
end

---@alias WholeFraction {numerator:integer, denominator:integer}

---@type fun(wf:WholeFraction):number
local function value_from_fraction(wf)
  return (1.0 / wf.denominator) * wf.numerator
end

---@type fun(a:WholeFraction, b:WholeFraction):boolean
local function by_value(a, b)
  return value_from_fraction(a) < value_from_fraction(b)
end

---@type fun(wf:WholeFraction):string
local function show_whole_fraction(wf)
  return wf.numerator .. "/" .. wf.denominator
end




---@type fun(a:number, b:number):boolean
local function kinda_equals(a, b)
  local precision = 1.0 / 255.0
  return a < b + precision and a > b - precision  
end
---@type fun(a:WholeFraction, b:WholeFraction):boolean
local function fractions_equal(a, b)
  local av = value_from_fraction(a)
  local bv = value_from_fraction(b)
  return kinda_equals(av, bv)
end

---@type fun(divisors:integer[]):WholeFraction[]
local function fractions(divisors)
  local all = {}
  for _, d in ipairs(divisors) do
    for j = 1, d - 1 do
      table.insert(all, {numerator = j, denominator = d})
    end
  end

  local r = {}

  for _, d in ipairs(all) do
    local index = nil
    for i, x in ipairs(r) do
      if fractions_equal(x, d) then
        index = i
        break
      end
    end
    if index == nil then
      table.insert(r, d)
    end
  end

  table.sort(r, by_value)
  return r
end

---@type fun(beats:integer, beat_value:integer):{beats:number, lpbs:integer[]}?
local function valid_lpbs(beats, beat_value)
  local quarter_note = beat_value / 4
  if quarter_note ~= math.floor(quarter_note) then
    return nil
  end

  local bs = beats / quarter_note
  local remainder = bs - math.floor(bs)
  -- local divisor = math.floor(1.0 / remainder + 0.5)

  local ls = {}

  for i = 1, 255 do
    -- if i % divisor == 0 then
    --   table.insert(ls, i)
    -- end
    local irem = i * remainder
    if kinda_equals(irem, math.floor(irem)) then
      table.insert(ls, i)
    end
  end
  return {beats = bs, lpbs = ls}
end

local function beat_fraction(lpb, index)
  local fs = fractions(whole_divisors(lpb))
  if index == 0 or index > #fs then 
    return 0
  else
    return value_from_fraction(fs[index])
  end
end

---@type fun(m:BarsModel):Timing
local function timing_from_model(m)
  local s = renoise.song()
  return {
    bpm  = ifthen(m.BPM_mode == BpmMode.empty, nil,
            ifthen(m.BPM_mode == BpmMode.fixed, m.BPM, 
              round((m.BPM_X/m.BPM_Y) * m.BPM))),
    lpb = ifthen(m.LPB_mode == LpbMode.empty, nil, m.LPB),
    tpl = ifthen(m.TPL_mode == TplMode.empty, nil, m.TPL),
  }    
end

---@type fun(s:S, t:Timing):Timing
local function complete_timing(s, t)
  if t.bpm == nil then t.bpm = s.transport.bpm end
  if t.lpb == nil then t.lpb = s.transport.lpb end
  if t.tpl == nil then t.tpl = s.transport.tpl end
  return t
end

---@type fun(m:BarsModel):integer
local function number_of_lines(m)
  -- local s = renoise.song()
  return ((m.beats + beat_fraction(m.LPB, m.beats_fraction_index)) * m.LPB * m.bars)
end

---@type fun(s : S, i : integer, l : integer, tm : Timing) : boolean
local function write_timing(s, i, l, tm)
  local ps = s.sequencer.pattern_sequence[i]
  local master = s:pattern(ps):track(s.sequencer_track_count + 1)
  local master_track = s:track(s.sequencer_track_count + 1)
  if master.alias_pattern_index ~= 0 then
    return false
  else
    local fx = {}
    if tm.bpm ~= nil then table.insert(fx, {"ZT", round(tm.bpm)}) end
    if tm.lpb ~= nil then table.insert(fx, {"ZL", tm.lpb}) end
    if tm.tpl ~= nil then table.insert(fx, {"ZK", tm.tpl}) end
    if master_track.visible_effect_columns < #fx then 
      master_track.visible_effect_columns = #fx
    end
    for f = 1, math.min(3, master_track.visible_effect_columns) do
      master:line(l):effect_column(f):clear()
    end
    for f = 1, #fx do
      master:line(l):effect_column(f).number_string = fx[f][1]
      master:line(l):effect_column(f).amount_value = fx[f][2]
    end      
    return true
  end  
end



---@type fun(line:renoise.PatternLine, count : integer) : Timing
local function collect_effect_columns(line, count)
  local ls = {}
  for i = 1, count do
    local ec = line:effect_column(i)
    if not ec.is_empty then
      local ns = ec.number_string
      if ns == "ZT" then ls.bpm = ec.amount_value
      elseif ns == "ZL" then ls.lpb = ec.amount_value
      elseif ns == "ZK" then ls.tpl = ec.amount_value 
      end
    end
  end
  return ls
end


---@type fun(s : S, i : integer, l : integer) : Timing
local function read_timing(s, i, l)
  local ps = s.sequencer.pattern_sequence[i]
  local master = s:pattern(ps):track(s.sequencer_track_count + 1)
  local master_track = s:track(s.sequencer_track_count + 1)
  local timing = {bpm = nil, lpb = nil, tpl = nil}
  for li = l, 1, -1 do
    local fx = collect_effect_columns(master:line(li), master_track.visible_effect_columns)
    if timing.bpm == nil and fx.bpm ~= nil then timing.bpm = fx.bpm end
    if timing.lpb == nil and fx.lpb ~= nil then timing.lpb = fx.lpb end
    if timing.tpl == nil and fx.tpl ~= nil then timing.tpl = fx.tpl end
  end
  return timing
end

---@type fun(s:S, m : BarsModel) -- TODO check if there is space for new patterns at all
local function insert_new_patterns(s, m)
  local q = s.selected_sequence_index
  local t = timing_from_model(m)
  for i = 1, m.patterns do
    s.sequencer:insert_new_pattern_at(q + i)
    local p = s:pattern(s.sequencer.pattern_sequence[q + i])
    p.number_of_lines = number_of_lines(m)
    write_timing(s, q + i, 1, t)
  end
  s.selected_sequence_index = q + 1
  s.selected_line_index = 1
end

-- ---@type fun(m : BarsModel) : boolean
-- local function insert_new_lines(m)
-- end

--TODO load values
-- save values
-- keep history / quick access
-- show source of values 
-- [bpm] : pattern
-- (bpm) : runtime




---@type fun() : BarsModel
local function BarsModel()
  return {
    state = "base",
    selected = 1,
    beats = 4,
    beats_fraction_index = 0,
    LPB_mode = LpbMode.empty,
    LPB = 4,
    bars = 2,
    TPL_mode = TplMode.empty,
    TPL = 12,
    BPM_mode = BpmMode.empty,
    BPM = 120,
    BPM_X = 4,
    BPM_Y = 4,
    patterns = 1,
  }
end

---@class ValueField
---@field name string
---@field needs { field : string, value : integer[]}?
---@field step fun(m : BarsModel, d : integer) : number?
---@field prefix string?
---@field postfix string?

---@type fun(name:string, ns:{field:string, value:integer[]}?, step:(fun(m:BarsModel, d:integer):number?), prefix:string?, postfix:string?) : ValueField
local function ValueField(name, ns, step, prefix, postfix)
  local r = { name = name, needs = nil, step = step, prefix = prefix , postfix = postfix }
  if ns then
    r.needs = { field = ns[1], value = ns[2]}
  end
  return r
end

---@type fun(m:BarsModel, nt:integer, next:integer, prev:integer):integer
local function if_valid_length(m, nt, next, prev)
  if m.patterns > -1 then
    if nt >= 1 and nt <= renoise.Pattern.MAX_NUMBER_OF_LINES then
      return next
    else
      return prev
    end
  else
    local s = renoise.song()
    if s == nil then return prev end
    if nt >= 1 and nt <= (renoise.Pattern.MAX_NUMBER_OF_LINES - s.selected_pattern.number_of_lines) then
      return next
    else
      return prev
    end
  end
end

---@type fun(nt:number, next:number, prev:number):number
local function if_valid_speed(nt, next, prev)
  if nt >= 32 and nt <= 255 then
    return next
  else
    return prev
  end
end

local function step_beat_fraction_index(m, dir)
  local fs = fractions(whole_divisors(m.LPB))
  local i = wrap(m.beats_fraction_index + dir, #fs + 1)
  return if_valid_length(m, (m.beats + beat_fraction(m.LPB, i)) * m.LPB * m.bars, i, m.beats_fraction_index)
end


---@type ValueField[]
local Fields = {
  beats = ValueField("beats", nil, function (m, d)
    local nt = m.beats + d
    return if_valid_length(m, (nt + beat_fraction(m.LPB, m.beats_fraction_index)) * m.LPB * m.bars, nt,  m.beats)
  end),
  bars = ValueField("bars", nil, function (m, d)
    local nt = m.bars + d
    return if_valid_length(m, (m.beats + beat_fraction(m.LPB, m.beats_fraction_index)) * m.LPB * nt, nt, m.bars)
  end),
  LPB_mode = ValueField("LPB_mode", nil, function(m, d)
    return wrapi(m.LPB_mode + d, 2)
  end),
  LPB = ValueField("LPB", {"LPB_mode", {LpbMode.fixed}}, function(m, d)
    local nt = clamp(m.LPB + d, 1, 256)
    local fs = fractions(whole_divisors(nt))
    local bi = wrap(m.beats_fraction_index, #fs + 1)
    local valid = if_valid_length(m, (m.beats + beat_fraction(nt, bi)) * m.bars * nt, nt, m.LPB)
    if valid then
      m.beats_fraction_index = bi
    end
    return valid
  end, " | "," lines"),
  BPM_mode = ValueField("BPM_mode", nil, function(m, d)
    return wrapi(m.BPM_mode + d, 3)
  end),
  BPM = ValueField("BPM", {"BPM_mode", { BpmMode.fixed, BpmMode.calc }}, function(m, d)
    if m.BPM_mode == BpmMode.fixed then
      return if_valid_speed(m.BPM + d, m.BPM + d, m.BPM)
    else
      return if_valid_speed((m.BPM + d) * (m.BPM_X / m.BPM_Y), (m.BPM + d), m.BPM)
    end
  end, " | "," beats"),
  BPM_X = ValueField("BPM_X", {"BPM_mode", {BpmMode.calc}}, function(m, d)
    local nt = clamp(m.BPM_X + d, 1, 99)
    return if_valid_speed(m.BPM * (nt / m.BPM_Y), nt, m.BPM_X)
  end, " |  * "," /"),
  BPM_Y = ValueField("BPM_Y", {"BPM_mode", {BpmMode.calc}}, function(m, d)
    local nt = clamp(m.BPM_Y + d, 1, 99)
    return if_valid_speed(m.BPM * (m.BPM_X / nt), nt, m.BPM_Y)
  end, " |     / ",""),
  TPL_mode = ValueField("TPL_mode", nil, function(m, d)
    return wrapi(m.TPL_mode + d, 2)
  end),
  TPL = ValueField("TPL", {"TPL_mode", {LpbMode.fixed}}, function(m, d)
    return  clamp(m.TPL + d, 1, 16)
  end, " | "," ticks"),
  patterns = ValueField("patterns", nil, function(m, d)
    return clamp(m.patterns + d, 0, 32)
  end),
}

local FieldList = {"beats","bars","LPB_mode","LPB","BPM_mode","BPM","BPM_X","BPM_Y","TPL_mode","TPL","patterns"}


local function step_selected(m, d)
  m.selected = wrapi(m.selected + d, #FieldList)
  local f = FieldList[m.selected]
  local needs = Fields[f].needs
  if needs == nil or table.find(needs.value, m[needs.field]) ~= nil then
    return
  else
    return step_selected(m, d)
  end  
end

---@type table <string, UpdateKeys<BarsModel>>
local updates = {
  base = {
    left = function(m)
      m[FieldList[m.selected]] = Fields[FieldList[m.selected]].step(m, ifthen(m.mods.control, -10, -1))
      return m
    end,
    right = function (m)
      m[FieldList[m.selected]] = Fields[FieldList[m.selected]].step(m, ifthen(m.mods.control, 10, 1))
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
      if FieldList[m.selected] == "beats" then
        m.beats_fraction_index = step_beat_fraction_index(m, -1)
      end
      return m
    end,
    right = function (m)
      if FieldList[m.selected] == "beats" then
        m.beats_fraction_index = step_beat_fraction_index(m, 1)
      end
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

---@type fun(s:renoise.Song, m : BarsModel)
local function apply(s, m)
  local fs = fractions(whole_divisors(m.LPB))
  m.beats_fraction_index = wrap(m.beats_fraction_index, #fs + 1)
end

---@type PadInit<BarsModel>
local function init(s, m)

  local  model = BarsModel()
  local t = read_timing(s, s.selected_sequence_index, s.selected_line_index)
  if t.bpm then model.BPM_mode = BpmMode.fixed end
  if t.lpb then model.LPB_mode = LpbMode.fixed end
  if t.tpl then model.TPL_mode = TplMode.fixed end
  t = complete_timing(s, t)

  if m then
    model.beats = m.beats
    model.beats_fraction_index = m.beats_fraction_index
    model.bars = m.bars
    model.patterns = m.patterns
  end
  model.BPM = t.bpm
  model.LPB = t.lpb
  model.TPL = t.tpl
  -- model.line = s.selected_line_index
  return model
end

---@type fun(s:S, t:Timing)
local function apply_timing(s, t)
  if t.bpm then s.transport.bpm = t.bpm end
  if t.lpb then s.transport.lpb = t.lpb end
  if t.tpl then s.transport.tpl = t.tpl end
end

---@type PadUpdate<BarsModel>
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
    if m.patterns == 0 then
      local t = timing_from_model(m)
      write_timing(s, s.selected_sequence_index, 1, t)
      apply_timing(s, t)
      s.selected_pattern.number_of_lines = number_of_lines(m)
    else
      insert_new_patterns(s, m)
    end
    apply_timing(s, timing_from_model(m))

    return {PadMessage.close, m}
  else
    return {PadMessage.ignore}
  end
end

---@type PadView<BarsModel>
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
  local patterns = nil
  local fun = function(a,b,c) return string.char(a)..string.char(b)..string.char(c) end
  for i = 1, #FieldList do
    local f = FieldList[i]
    if (Fields[f].needs == nil or table.find(Fields[f].needs.value, m[Fields[f].needs.field]) ~= nil) then  
      local t = m[f] .. " " .. f
      if string.find(f, "_mode") then
        local target = f:sub(1, #f - #("_mode"))
        -- local current = s.transport[string.lower(target)]
        local current = m[target]

        -- if target == "BPM" then current = string.format("%.2f", current) end
        current = round(current)
        if m[f] > 1 then
          t = show_enum[f][m[f]]
        else
          t = show_enum[f][m[f]].. " "..current..""
        end
      end
      if Fields[f].prefix then
        t =  Fields[f].prefix .. m[f].. Fields[f].postfix
      end
      if f == "patterns" then 
        if m[f] > 0 and m.beats == 4 and m.bars == 0x13 and i == m.selected then
          t = m[f] .." ".. fun(98, 108, 0x6F)..f:sub(3,6).."s"
        end
        if m[f] == 0 then
          t = "edit pattern"
        -- elseif m[f] == -1 then
        --   t = "insert at line"
        end
      end
      -- renoise.song().selected_sample.sample_buffer.set_sample_data(self, channel_index, frame_index, sample_value)
      -- renoise.song().selected_sample.sample_buffer.number_of_frames
      if m[f] == 1 and t:sub(#t) == "s" then
        t = t:sub(1, #t - 1)
      end

      if f == "beats" and m.beats_fraction_index ~= 0 then
        local fs = fractions(whole_divisors(m.LPB))
        t = t .. " + " .. show_whole_fraction(fs[m.beats_fraction_index])
      end

      local vc = vb:text {
        text = ifthen(m.selected == i, string.upper(t), t),
        font = "mono",
        style = ifthen(m.selected == i, "normal", "disabled")
      }

      if f ~= "patterns" then
        v:add_child(vc)
      else
        patterns = vc
      end
    end
  end
  if m.BPM_mode == BpmMode.calc then
    v:add_child(
      vb:horizontal_aligner {
        mode = "right",
        width = "100%",
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        vb:text{
          text = round(m.BPM * (m.BPM_X / m.BPM_Y)) .. " "..
            ifthen(m.BPM_X == 4 and m.BPM_Y == 0x14, fun(84,72,67), "BPM"),
          align = "right",
          style = "disabled"
        }
      }
    )
  end
  v:add_child(
    vb:horizontal_aligner {
      mode = "right",
      width = "100%",
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        text = number_of_lines(m) .. " LINES",
        align = "right",
        style = "disabled"
      }
    }
  )
  if patterns then
    v:add_child(patterns)
  end
  local preview = vb:column {
      spacing = 4,

  }

  for bar = 1, m.bars do
    local _bar = vb:column {
      style = "border"
    }
    for beat = 1, m.beats do
      local _beat = vb:row {
        style = "border",
      }
      for line = 1, m.LPB do
        _beat:add_child(vb:button {
          color = {0xff, 0xff, 0xff},
          width = 4,
          height = 4
        })

      end
      _bar:add_child(_beat)
    end
    preview:add_child(_bar)
  end
  return vb:row({
    v,
    preview
  })
end

---@type PadModule<BarsModel>
BarsPad = {
  update = update,
  init = init,
  view = view
}