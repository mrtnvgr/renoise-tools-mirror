---@enum ModState
ModState = {
  none = 1,
  shift = 2,
  alt = 3,
  control = 4,
}

---@type fun(x : number) : integer
function round(x)
  return math.floor(x + 0.5)
end
---@type fun(x : number) : integer
function sign(x)
  if x < 0 then return -1 else return 1 end
end

---@type fun(x : number, mn : number, mx : number) : number
function clamp(x, mn, mx)
  return math.max(math.min(x, mx), mn)  
end


---@type fun(predicate : boolean, when_true : any, when_false : any) : any
function ifthen(predicate, when_true, when_false)
  if predicate then return when_true else return when_false end  
end

---@type fun(index:integer, length:integer):integer
function wrapi(index, length)
  return ((((index - 1) % length) + length) % length) + 1
end

---@type fun(index:integer, length:integer):integer
function wrap(index, length)
  return ((((index) % length) + length) % length)
end

---@alias ModKeys {control:boolean, alt:boolean, shift:boolean}

---@param mods string
---@return ModKeys
function get_mods(mods)
  return {
    control = string.find(mods, "control") ~= nil or string.find(mods, "command") ~= nil,
    alt = string.find(mods, "alt") ~= nil or string.find(mods, "option") ~= nil,
    shift = string.find(mods, "shift") ~= nil,
  }
end

---@type fun (self, s: string, separator : string) : string[]
function string:split(s, separator)
  local a = {}
  for str in string.gmatch(s, "([^" .. separator .. "]+)") do
    table.insert(a, str)
  end
  return a
end

---@type fun(string, s:string[], separator:string):string
function string:join(strings, separator)
  local a = ""
  for i, s in pairs(strings) do
    if i == 1 then
      a = s
    else
      a = a .. separator .. s
    end
  end
  return a
end

---@type fun(s:renoise.Song, t:integer, min : integer)
function set_pattern_note_columns(s, t, min)
  if s:track(t).type ~= renoise.Track.TRACK_TYPE_SEQUENCER then
    return
  end
  local nc = s:track(t).visible_note_columns
  if min == nil then min = 1 end
  if nc > min then
    for lp, l in s.pattern_iterator:lines_in_track(t) do
      if not l:note_column(nc).is_empty then
        return
      end
    end
    s:track(t).visible_note_columns = nc - 1
    set_pattern_note_columns(s, t, min)
  else
    s:track(t).visible_note_columns = min
  end
end


---@type fun(p : renoise.InstrumentPhrase, min : integer)
function set_phrase_note_columns(p, min)
  local nc = p.visible_note_columns
  if min == nil then min = 1 end
  if nc > min then
    for l = 1, p.number_of_lines do
      if not p:line(l):note_column(nc).is_empty then 
        return 
      end
    end
    p.visible_note_columns = nc - 1
    set_phrase_note_columns(p, min)
  else
    p.visible_note_columns = min
  end
end

---@type fun(pulses:integer, steps:integer, rotate:integer) : boolean[]
function euclid_pattern(pulses, steps, rotate)
  local slope = pulses / steps
  local pattern = {}
  local prev = nil
  for i = 1, steps do
    local curr = math.floor((i - 1) * slope)
    table.insert(pattern, curr ~= prev)
    prev = curr
  end

  for i = 1, rotate do
    table.insert(pattern, 1, table.remove(pattern))
  end
  return pattern
end

---@type fun(pt:renoise.PatternTrack, test:(fun(l:renoise.PatternLine, i:integer):boolean), dir:integer, line:integer) : integer
function get_line_with(pt, test, dir, line)
  if line <= 0 or line > #pt.lines then
    return 0
  else
    if test(pt:line(line), line) then
      return line
    else
      return get_line_with(pt, test, dir, line + dir)
    end
  end
end

---@type fun(pt:renoise.PatternTrack, column:integer, line:integer) : integer
function get_note_on_from_pattern(pt, column, line)
  return get_line_with(
    pt,
    function(l)
      return l:note_column(column).note_value < renoise.PatternLine.NOTE_OFF
    end,
    -1,
    line
  )
end

---@type fun(pt:renoise.PatternTrack, column:integer, line:integer) : integer
function get_note_off_from_pattern(pt, column, line)
  return get_line_with(
    pt,
    function(l, i)
      return l:note_column(column).note_value == renoise.PatternLine.NOTE_OFF or i == #pt.lines
    end,
    1,
    line
  )
end

---@type fun(s:renoise.Song, track:integer, sequence_step:integer, line:integer, column : integer) : integer?
function get_note_on_from_song(s, track, sequence_step, line, column)
  if line == 0 then
    if sequence_step == 1 then
      return nil
    else
      return get_note_on_from_song(s, track, sequence_step - 1, s:pattern(s.sequencer[sequence_step - 1]).number_of_lines, column)
    end
  else
    local pattern = s:pattern(s.sequencer.pattern_sequence[sequence_step])
    local note = pattern:track(track):line(line):note_column(column).note_value
    if note < renoise.PatternLine.NOTE_OFF then
      return note
    else
      return get_note_on_from_song(s, track, sequence_step, line - 1, column)
    end
  end
end

---@type fun(vb:ViewBuilderInstance, m:table<string, any>, key:string, name:string, selected:boolean, tooltip:string, fine:boolean?, unit:string?) : renoise.Views.Aligner
function value_row(vb, m, key, name, selected, tooltip, fine, unit)
    local font = ifthen(selected, "bold", "normal")
    local style = ifthen(selected, "strong", "disabled")
    unit = ifthen(unit ~= nil, unit, "")
    local format_string = ifthen(fine, "%.3f"..unit, "%i"..unit)
    return vb:horizontal_aligner{
      mode = "justify",
      tooltip = tooltip,
      vb:text{
        font = font,
        style = style,
        align = "left",
        text = name
      },
      vb:text({
        font = font,
        style = style,
        align = "right",
        text = string.format(format_string, m[key]),
      })
    }
  end

---@type fun(vb:ViewBuilderInstance, m:table<string, any>, key:string, name:string, labels:string[], selected:boolean, tooltip:string) : renoise.Views.Aligner
function check_row(vb, m, key, name, labels, selected, tooltip)
  local font = ifthen(selected, "bold", "normal")
  local style = ifthen(selected, "strong", "disabled")
  return vb:horizontal_aligner{
    mode = "justify",
    tooltip = tooltip,
    vb:text{
      font = font,
      style = style,
      align = "left",
      text = name
    },
    vb:text{
      font = font,
      style = style,
      align = "right",
      text = labels[m[key]],
    }
  }
end