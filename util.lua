---@alias S renoise.Song
---@alias funS fun(s:S)

---@type fun(x:number, a:number, b:number):number
function clamp(x, a, b)
  return math.max(math.min(x, b), a)
end

---@generic T:any
---@type fun(x:T|nil, d:T):T
function with_default(x, d)
  if x == nil then return d else return x end
end

---@type fun(e:table <string, any>, f:function?):table <string, boolean|any>
function enum_lookup(e, f)
  local ls = {}
  for s in pairs(e) do
    local v = true
    if f ~= nil then
      v = f(e[s])
    end
    ls[e[s]] = v
  end
  return ls
end

---@type fun(source:renoise.PatternTrack, target:renoise.PatternTrack)
function copy_automation(source, target)
  for i = 1, #source.automation do
    local a = source.automation[i]
    if a.dest_parameter then
      local b = target:find_automation(a.dest_parameter)
      if b == nil then
        b = target:create_automation(a.dest_parameter)
      end
      b:copy_from(a)
    end
  end
end

---@type fun(s:S, step:integer):renoise.Pattern
function seq_pattern(s, step)
  return s:pattern(s.sequencer.pattern_sequence[step])
end

---@type fun(s:S, step:integer, track:integer):renoise.PatternTrack
function seq_track(s, step, track)
  return s:pattern(s.sequencer.pattern_sequence[step]):track(track)
end

---@type funS
function clear_selection(s)
  -- s.sequencer.selection_range = {0,0}
  local q = s.sequencer
  for i = 1, #q.pattern_sequence do
    for t = 1, #s.tracks do
      q:set_track_sequence_slot_is_selected(t, i, false)
    end
  end
end

---@type funS
function clear_slot_colors(s)
  local p = nil
  local q = s.sequencer
  for i = 1, #q.pattern_sequence do
    p = s:pattern(q.pattern_sequence[i])
    for t = 1, #s.tracks do
      if p:track(t).color ~= nil then
        p:track(t).color = nil
      end
    end
  end
end

---@type funS
function clear_highlights(s)
  clear_slot_colors(s)
  clear_selection(s)
end

---@type fun(q:renoise.PatternSequencer, count:integer)
function ensure_sequence_steps(q, count)
  if #q.pattern_sequence < count then
    for i = #q.pattern_sequence + 1, count do
      q:insert_new_pattern_at(i)
    end
  end
end

---@type fun(header:string):boolean
function lanes_exist(header)
  local s = renoise.song()
  if s == nil then return false end
  local q = s.sequencer
  return #q.pattern_sequence > 2 and q:sequence_is_start_of_section(1) and q:sequence_section_name(1) == header and q:sequence_is_start_of_section(3)
end

---@type fun(a:integer, b:integer):integer
function wrap(a, b)
  return ((((a) % b) + b) % b)
end

---@type fun(s:S, q:renoise.PatternSequencer)
function clear_lanes(s, q)
  local a = s:pattern(q.pattern_sequence[1])
  local b = s:pattern(q.pattern_sequence[2])
  a:clear()
  b:clear()
  for t = 1, #s.tracks do
    a:track(t).alias_pattern_index = 0
    b:track(t).alias_pattern_index = 0
    q:set_track_sequence_slot_is_muted(t, 1, false)
    q:set_track_sequence_slot_is_muted(t, 2, false)
  end
end

---@generic T
---@generic G
---@type fun(t:table<any, T>, f:fun(g:T):G):table<any,G>
function map_table(t, f)
  local r = {}
  for i = 1, #t do
    table.insert(r, f(t[i]))
  end
  return r
end

---@generic T
---@type fun(c:integer, f:fun(i:integer):T):table<integer,T>
function filled_table(c, f)
  local ts = {}
  for i = 1, c do
    table.insert(ts, f(i))
  end
  return ts
end

---@generic T
---@generic G
---@type fun(t:table<any, T>, f:fun(g:T, i:integer):G?):table<any,G>
function fold_table(t, f)
  local ts = {}
  for i = 1, #t do
    local r = f(t[i], i)
    if r ~= nil then
      table.insert(ts, r)
    end
  end
  return ts
end

---@type fun(s:S, header:string, body:string, length:integer)
function ensure_lanes(s, header, body, length)
  local q = s.sequencer

  if not lanes_exist(header) then 
    local selected_step = s.selected_sequence_index
    
    local intro_name = nil
    if q:sequence_is_start_of_section(1) then
      intro_name = q:sequence_section_name(1)
    else
      q:set_sequence_is_start_of_section(1, true)
    end

    local added_steps = 0
    if q:sequence_section_name(1) ~= header then
      q:insert_new_pattern_at(1)
      q:insert_new_pattern_at(1)
      added_steps = 2
    else
      if #q.pattern_sequence < 3 then
        for i = #q.pattern_sequence + 1, 3 do
          q:insert_new_pattern_at(1)
          added_steps = added_steps + 1
        end
      end
    end

    q:set_sequence_is_start_of_section(1, true)
    q:set_sequence_section_name(1, header)

    if not q:sequence_is_start_of_section(3) then
      q:set_sequence_is_start_of_section(3, true)
      q:set_sequence_section_name(3, with_default(intro_name, body))
    end


    s.selected_sequence_index = clamp(selected_step + added_steps, 1, #s.sequencer.pattern_sequence)
  end

  resize_lanes(s, length)  
  clear_lanes(s, q)
  clear_highlights(s)
end

---@type fun(f:fun(s:S))
function when_song(f)
  local s = renoise.song()
  if s ~= nil then f(s) end
end

---@generic T
---@type fun(predicate:boolean?, truth:T, otherwise:T) : T
function ifthen(predicate, truth, otherwise)
  if predicate then return truth else return otherwise end
end

---@type fun(v:integer):integer
function flipped(v)
  if v == 1 then return 2 else return 1 end
end

---@type fun(s:S, from:integer, to:integer, keep_alias:boolean)
function clone_pattern(s, from, to, keep_alias)
  s.sequencer:insert_new_pattern_at(to)
  local fp = s:pattern(s.sequencer.pattern_sequence[from])
  local p = s:pattern(s.sequencer.pattern_sequence[to])
  for t = 1, #s.tracks do
    local ft = fp:track(t)
    local track = p:track(t)
    if ft.alias_pattern_index == 0 then
      track:copy_from(ft)
    else
      if keep_alias then
        track.alias_pattern_index = ft.alias_pattern_index
      else
        track:copy_from(s:pattern(ft.alias_pattern_index):track(t))
      end
    end
    track.color = nil
  end
end

---@type fun(t:renoise.Track|renoise.GroupTrack):boolean
function is_group_collapsed(t)
  if t.group_parent then
    return (t.type == renoise.Track.TRACK_TYPE_GROUP and t.group_collapsed) or is_group_collapsed(t.group_parent)
  else
    return (t.type == renoise.Track.TRACK_TYPE_GROUP and t.group_collapsed)
  end
end

---@type fun(s:S, start_index:integer, index:integer):integer
function get_group_head(s, start_index, index)
  if index == nil then index = start_index end
  if index == 1 then return 1 end
  local track = s:track(index)
  if track.type == renoise.Track.TRACK_TYPE_GROUP then
    if index ~= start_index then 
      if track.group_parent then
        return get_group_head(s, start_index, index - 1)
      else
        return index + 1
      end
    else
      return get_group_head(s, start_index, index - 1)
    end
  else
    if track.group_parent then
      return get_group_head(s, start_index, index - 1)
    else
      return index + 1
    end
  end
end        

---@type fun(s:S, track:integer):integer?
local function get_group_index(s, track)
  local t = s:track(track)
  if t.group_parent == nil then
    if t.type ~= renoise.Track.TRACK_TYPE_GROUP then
      return nil
    else
      return track
    end
  else
    if t.type == renoise.Track.TRACK_TYPE_GROUP then
      return track
    else
      return get_group_index(s, track + 1)
    end
  end
end

---@type fun(s:S, track:integer):integer?
function get_closest_uncollapsed_group_index(s, track)
  local gi = get_group_index(s, track)
  if gi == nil then
    return nil
  else
    if s:track(gi).group_parent and s:track(gi).group_parent.group_collapsed then
      return get_closest_uncollapsed_group_index(s, gi + 1)
    else
      return gi
    end
  end
end

---@type fun(s:S, group_index:integer?, track:integer?, indices:integer[]?):integer[]
function get_group_track_indices(s, group_index, track, indices)
  if group_index == nil then return {} end
  if indices == nil then
    indices = { group_index }
    track = group_index - 1
  end

  if track == 0 or s:track(track).group_parent == nil then 
    return indices
  else
    table.insert(indices, track)
    return get_group_track_indices(s, group_index, track - 1, indices)
  end
end

---@type fun(k:string):string
function mugglify_char(k)
  local magic_chars = {"^","$","(",")","%",".","[","]","*","+","-","?"}
  for i = 1, #magic_chars do
    if magic_chars[i] == k then 
      return "%"..k
    end
  end
  return k
end


---@enum ButtonState
ButtonState = {
  pressed = 0,
  repeated = 1,
  released = 2,
}

---@type fun(state:"released"|"pressed", repeated:boolean):ButtonState
function button_state(state, repeated)
  if state == "released" then return ButtonState.released
  else
    if repeated then return ButtonState.repeated
    else return ButtonState.pressed end
  end
end

---@alias KeyMods {control:boolean, alt:boolean, shift:boolean}

---@type fun(mods:string):KeyMods
function get_mods(mods)
  return {
    control = string.find(mods, "control") or string.find(mods, "command"),
    alt = string.find(mods, "alt") or string.find(mods, "option"),
    shift = string.find(mods, "shift"),
  }
end

---@type fun(s:S, track:integer, pattern:renoise.Pattern, alias:integer)
function copy_pattern(s, track, pattern, alias)
  local pt = pattern:track(track)

  if alias == 0 then
    if pt.is_empty and #pt.automation == 0 and pt.alias_pattern_index == 0 then
      return
    else
      pt:clear()
      pt.alias_pattern_index = 0
      return
    end
  elseif pt.alias_pattern_index == alias then
    return
  else
    pt:clear()
    local np = s:pattern(alias):track(track)
    copy_automation(np, pt)
    pt.alias_pattern_index = alias
  end
end

---@type fun(a:RGBColor?, b:RGBColor?):boolean
function colors_match(a, b)
  if a == nil and b == nil then return true
  else
    if a == nil or b == nil then return false
    else
      for i = 1, 3 do 
        if a[i] ~= b[i] then return false end 
      end
      return true
    end
  end
end