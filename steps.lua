---@type fun(s:S, i:integer, d:integer):boolean
local function out_of_pattern(s, i, d)
  return (i == 3 and d == -1) or (i == #s.sequencer.pattern_sequence and d == 1)
end

---@class GapSettings
---@field empty boolean
---@field section boolean
---@field automation boolean
---@field muted boolean


---@return boolean
---@type fun(s:S, t:integer, i:integer, d:integer, gaps:GapSettings):boolean
local function is_gap(s, t, i, d, gaps)
  local pt = seq_track(s, i, t)
  return (#pt.automation == 0 or gaps.automation)
      and (
        ( gaps.empty and s:pattern(s.sequencer.pattern_sequence[i]):track(t).is_empty )
        or (gaps.muted and s.sequencer:track_sequence_slot_is_muted(t, i))
        or ( gaps.section and (
            (d == 1 and s.sequencer:sequence_is_start_of_section(i))
            or (d == -1 and s.sequencer:sequence_is_start_of_section(i + 1))
            )
        )
      )
end

---@alias GapFun fun(s : renoise.Song, t : integer, i : integer, d: integer, gaps: GapSettings?) : integer?

---@type table<Gap, GapFun>
local get_next_step = {
  [Gap.ignore] = function(s, t, i, d, gaps)
    if out_of_pattern(s,i,d) then return nil end
    return i + d
  end,
  [Gap.jump] = function(s, t, i, d, gaps)
    if out_of_pattern(s,i,d) then return nil end
    gaps.section = false
    local length = #s.sequencer.pattern_sequence
    local dest = ifthen(d == -1, 3, length)
    for step = i + d, dest, d do
      if step <= length and step > 2 then
        if not is_gap(s, t, step, d, gaps) then
          return step
        end
      end
    end
    return nil
  end,
  [Gap.stop] = function(s, t, i, d, gaps) 
    if out_of_pattern(s,i,d) then return nil end
    if is_gap(s, t, i + d, d, gaps) then return nil
    else return i + d end
  end,
  [Gap.wrap] = function(s, t, i, d, gaps) 
    if out_of_pattern(s,i,d) then return nil end
    if is_gap(s, t, i + d, d, gaps) then
      local length = #s.sequencer.pattern_sequence
      d = -1 * d
      local dest = ifthen(d == -1, 3, length)
      local opposite_edge = nil
      for step = i + d, dest, d do
        if step <= length and step > 2 then
          if is_gap(s, t, step, d, gaps) then
            return step + (-1 * d)
          end
        end
      end
    end
    return i + d
  end,
}

---@type GapSettings
local empty_and_muted = {muted = true, empty = true, automation = false, section = false}
---@type GapFun
function next_vertical_island(s, t, i, d, gaps)
  local length = #s.sequencer.pattern_sequence
  if out_of_pattern(s,i,d) then return clamp(i, 3, length) end
  local dest = ifthen(d == -1, 3, length)
  local section = {muted = false, empty = false, automation = false, section = true}
  local inside_gap = is_gap(s, t, i, d, empty_and_muted)
  for step = i + d, dest, d do
    if step <= length and step > 2 then
      if inside_gap then
        if not is_gap(s, t, step, d, empty_and_muted) then
          return step
        end
      else
        if is_gap(s, t, step, d, empty_and_muted) then
          inside_gap = true
        elseif is_gap(s, t, step, d, section) then
          return clamp(step, 3, length)
        end
      end
    end
  end
  return clamp(i + d, 3, length)
end

---@type GapFun
function next_horizontal_island(s, t, i, d, gaps)
  local dest = ifthen(d == -1, 1, #s.tracks)
  local inside_gap = is_gap(s, t, i, d, empty_and_muted)
  for o = t, dest, d do
    if inside_gap then
      if not is_gap(s, o, i, d, empty_and_muted) then
        return clamp(o, 1, #s.tracks)
      end
    else
      if is_gap(s, o, i, d, empty_and_muted) then
        inside_gap = true
      end
    end
  end
  return t + d
end

---@return GapSettings
local function pref_gaps()
  return {
    automation = prefs.automation_is_gap.value,
    empty = prefs.empty_is_gap.value,
    muted = prefs.muted_is_gap.value,
    section = prefs.section_is_gap.value,
  }
end

---@type fun(gap_mode: Gap, s:S, t:integer, i:integer, d:integer)
function get_next_step_by_prefs(gap_mode, s, t, i, d)
  return get_next_step[gap_mode](s, t, i, d, pref_gaps())
end