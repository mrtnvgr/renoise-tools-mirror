---@enum CellMode
Mode = {
  once = 1,
  loop = 2,
  step = 3,
}

---@enum Gap
Gap = {
  ignore = 1,
  jump = 2,
  stop = 3,
  wrap = 4
}

---@enum CellState
CellState = {
  none = 0,
  current = 1,
  next = 2,
}

---@class Cell
---@field step integer
---@field alias integer
---@field mute boolean
---@field empty boolean
---@field mode CellMode
---@field gap Gap?
---@field dirty boolean
---@field soloed boolean
---@field swap boolean
---@field next Cell?

---@param step integer
---@param alias integer
---@param mute boolean
---@param empty boolean
---@param mode CellMode
---@param gap Gap?
---@return Cell
function Cell(step, alias, mute, empty, mode, gap)
  return {
    step = step,
    alias = alias, 
    mute = mute,
    empty = empty,
    mode = mode,
    next = nil,
    swap = false,
    dirty = false,
    gap = gap,
    soloed = false,
  }
end

---@return Cell
function EmptyCell()
  return Cell(0,0,false,true, Mode.loop)
end

---@type fun(c:Cell, next:Cell):Cell
function copy_cell(c, next)
  local cc = Cell(c.step, c.alias, c.mute, c.empty, c.mode, c.gap)
  if next then cc.next = c.next end
  return cc
end

---@type fun(a:Cell, b:Cell):boolean
function same_cell(a, b)
  return (a ~= nil and b ~= nil) and a.step == b.step
end

---@type fun(s:S, step:integer, track:integer):Cell
function extract_cell(s, step, track)
  local pattern_index = s.sequencer.pattern_sequence[step]
  local pattern_track = s:pattern(pattern_index):track(track)
  local pattern_alias = pattern_track.alias_pattern_index
  if pattern_alias ~= 0 then
    return Cell(step, pattern_alias, false, s:pattern(pattern_alias):track(track).is_empty, prefs.play_mode.value, prefs.gap_mode.value)
  else
    local empty = pattern_track.is_empty and #pattern_track.automation == 0
    return Cell(step, pattern_index, false, empty, prefs.play_mode.value, prefs.gap_mode.value)
  end
end

---@type fun(s:S, step:integer, track:integer):Cell
function remember_cell(s, step, track)
  local pattern_index = s.sequencer.pattern_sequence[step]
  local pattern_track = s:pattern(pattern_index):track(track)
  local pattern_alias = pattern_track.alias_pattern_index
  if pattern_alias == 0 then
    return EmptyCell()
  else
    return Cell(step, pattern_alias, false, s:pattern(pattern_alias):track(track).is_empty, Mode.loop)
  end
end

---@type fun(s:S, track:integer, prev:Cell, next:Cell):Cell
function change_cell(s, track, prev, next)
  highlight(s, track, prev, CellState.none)
  highlight(s, track, next, ifthen(next.empty, CellState.none, CellState.current))
  -- next.needs_highlight = true
  return next
end

---@type fun(s:S, track:integer, cell:Cell, next:Cell?):Cell
function change_next(s, track, cell, next)
  if cell.next then
    if not same_cell(cell.next, next) then
      highlight(s, track, cell.next, CellState.none)
    end
  end
  if next then
    if not next.empty then
      highlight(s, track, next, CellState.next)
    end
  else
    if not cell.empty then
      highlight(s, track, cell, CellState.current)
    end
  end
  return next
end

---@alias CellHighlighter fun(s:renoise.Song, track:integer, cell:Cell, state:CellState)

---@type CellHighlighter
local function cell_slot_color(s, track, cell, state)
  if cell.alias == 0 then return end
  if not cell.empty then
    if state == CellState.current then
      s:pattern(cell.alias):track(track).color = White
    elseif state == CellState.next then
      -- s:pattern(cell.alias):track(track).color = Black
    else
      s:pattern(cell.alias):track(track).color = nil
    end
  end
end

---@type CellHighlighter
local function cell_select_color(s,track, cell, state)
  if cell.alias == 0 then return end
  if not cell.empty then
    s.sequencer:set_track_sequence_slot_is_selected(track, cell.step, state == CellState.current)
  end
end

---@type table<HighlightMode, CellHighlighter>
local cell_highlighting = {
  function(_s, _t, _c, _cs) end,
  cell_slot_color,
  cell_select_color
}

---@type CellHighlighter
function highlight(s, track, cell, state)
  cell_highlighting[prefs.highlight.value](s, track, cell, state)
end
