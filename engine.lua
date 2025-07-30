require "cell"
require "steps"

-- for some reason the lsp thinks name from main is (table|string) in this file without this
---@type string 
name = "launch_lanes"

---@class Scroll
---@field x integer
---@field y integer

---@class Model
---@field current 1|2
---@field swapped boolean
---@field map Cell[]
---@field last Cell[]
---@field last_scroll Scroll
---@field scroll Scroll
---@field tick 0|1
---@field beat integer
---@field last_length integer
---@field history Cell[][]
---@field history_index integer

---@type fun(s:S):Model
function Model(s)
  return sync(s, {
    current = 1,
    swapped = false,
    map = filled_table(#s.tracks, EmptyCell),
    last = filled_table(#s.tracks, EmptyCell),
    history = {},
    history_index = 0,
    last_scroll = {
      x = 0,
      y = 0,
    },
    scroll = {
      x = 0,
      y = 0
    },
    tick = 1,
    beat = 0,
    last_length = prefs.length.value,
  })
end

---@enum Msg
Msg = {
  stop = "stop",
  mute = "mute",
  solo = "solo",
  step = "step",
  play = "play",
  back = "back",
  mode = "mode",
  history = "history",
  scroll_x = "scroll_x",
  scroll_y = "scroll_y",
}


---@param s S
---@param m Model
---@param x integer
---@param y integer
---@param dir_x integer?
---@param dir_y integer?
---@return Scroll
local function change_scroll(s, m, x, y, dir_x, dir_y)
  if m.scroll.x ~= x or m.scroll.y ~= y then
    if prefs.wrap.value == Wrap.tracks or prefs.wrap.value == Wrap.both then
      x = wrap(x, #s.tracks)
    else
      x = clamp(x, 0, #s.tracks - 1)
    end

    -- jump over collapsed groups
    if dir_x then
      local t = s:track(1 + x)
      if is_group_collapsed(t) then
        if t.type ~= renoise.Track.TRACK_TYPE_GROUP then
          if dir_x == -1 then
            local group_head = get_group_head(s, x, x)
            if group_head > 1 then
              x = group_head - 2
            end
          else
            local group_index = get_closest_uncollapsed_group_index(s, x + 1)
            if group_index then
              x = group_index - 1
            end
          end
        end
      end
    end

    if prefs.wrap.value == Wrap.patterns or prefs.wrap.value == Wrap.both then
      y = wrap(y, #s.sequencer.pattern_sequence - 2)
    else
      y = clamp(y, 0, #s.sequencer.pattern_sequence - 3) 
    end
    return { x = x, y = y }
  else
    return m.scroll
  end
end

---@type table < Msg, fun(m : Model, v : any, s : S)>
Update = {}

Update[Msg.mode] = function(m, v, s)
  prefs.play_mode.value = v
end

-- sets cell.next to the target step
Update[Msg.play] = function(m, v, s)
  for i = 1, #v.cells do
    local track = v.cells[i].track
    local next = extract_cell(s, v.cells[i].step, track)
    local c = m.map[track]

    -- schedule another cell to be played, overrides next if exists
    if not same_cell(c, next) then
      c.next = change_next(s, track, c, next)
    else
    -- toggle the cell if the same pattern is already on
    -- (except when row launching or scheduling from other functions)
      if v.toggle then
        -- if the cell is about to be stopped keep it instead of toggling
        if c.next and c.next.empty then
          c.next = change_next(s, track, c, nil)
        else -- otherwise stop
          c.next = change_next(s, track, c, EmptyCell())
        end
      end
    end
    c.swap = v.swap
  end
  m.swapped = v.swap
end

-- sets the cell.next to empty
Update[Msg.stop] = function(m, v, s)
  for i = 1, #v.cells do
    local track = v.cells[i].track
    local c = m.map[track]
    c.next = change_next(s, track, c, EmptyCell())
    c.swap = v.swap
  end
  m.swapped = v.swap
end

-- sets next to the target and stops everything else
Update[Msg.solo] = function(m, v, s)
  for i = 1, #v.cells do
    local track = v.cells[i].track
    local next = extract_cell(s, v.cells[i].step, track)
    local c = m.map[track]
    c.next = change_next(s, track, c, next)
    c.soloed = true
    c.swap = v.swap
  end

  -- filter all tracks that need to be stopped
  local stopped = fold_table(m.map, 
    function(c, i) 
      if not c.soloed and not c.empty then 
        return {track = i, step = 0 } 
      end
    end
  )
  Update[Msg.stop](m, {toggle = false, cells = stopped, swap = v.swap}, s)
  m.swapped = v.swap
end

-- step cells down or up the sequence
Update[Msg.step] = function(m, v, s)
  if v.dir == nil then v.dir = 1 end
  local stepped = {}
  local stopped = {}
  for i = 1, #v.cells do
    local t = v.cells[i].track
    local c = m.map[t]

    if not c.empty then
      local last_step = c.step
      if c.next and not c.next.empty then 
        last_step = c.next.step 
      end

      
      local next_step = get_next_step_by_prefs(prefs.gap_mode.value, s, t, last_step, v.dir)
      if next_step then
        if next_step == c.step then 
          next_step = get_next_step_by_prefs(prefs.gap_mode.value, s, t, next_step, v.dir) 
        end
      end

      if next_step then
        table.insert(stepped, {track = t, step = next_step})
      else
        table.insert(stopped, {track = t, step = 0})
      end

    end
  end
  
  Update[Msg.play](m, {toggle = false, cells = stepped, swap = v.swap}, s)
  Update[Msg.stop](m, {toggle = false, cells = stopped, swap = v.swap}, s)
end

Update[Msg.back] = function(m, v, s)
  for t = 1, #m.map do
    local c = m.map[t]
    c.next = change_next(s, t, c, m.last[t])
    c.swap = v
  end
  
  m.swapped = v.swap
end

Update[Msg.scroll_x] = function(m, v, s)
  m.last_scroll.x = v.dir
  local x = m.scroll.x + v.dir
  if v.jump then
    x = next_horizontal_island(s, m.scroll.x + 1, m.scroll.y + 3, v.dir)
    x = x - 1
  end
  m.scroll = change_scroll(s, m, x, m.scroll.y, v.dir, nil)
end

Update[Msg.scroll_y] = function(m, v, s)
  m.last_scroll.y = v.dir
  local y = m.scroll.y + v.dir
  if v.jump then
    y = next_vertical_island(s, m.scroll.x + 1, m.scroll.y + 3, v.dir, 
      {section = true, muted = true, empty = true, automation = false}
    ) - 3
  end
  -- print(y)
  m.scroll = change_scroll(s, m, m.scroll.x, y, nil, v.dir)
end

-- todo
Update[Msg.history] = function(m, v, s)
  -- if #m.history > 1 then
  --   local nt = clamp(m.history_index + v.dir, 1, #m.history)
  --   if nt ~= m.history_index then
  --     m.history_index = nt
  --     for t = 1, #m.map do
  --       local c = m.map[t]
  --       c.next = change_cell(s, m, t, c, m.history[m.history_index][t], false)
  --     end
  --     if v.swap then
  --       m.swapped = true
  --     end
  --   end
  -- end
end

---@type fun(s:S, m:Model, msg:{type:Msg, value:any}):Model
local function update(s, m, msg)
  Update[msg.type](m, msg.value, s)
  return m
end

---@type fun(s:S, m:Model):Model
function sync(s, m)
  if #m.map ~= #s.tracks then
    remake_map(s, m, #s.tracks)
  end
  
  if lanes_exist(name) then
    m.scroll = change_scroll(s, m, s.selected_track_index - 1, s.selected_sequence_index - 3)
  else
    m.scroll = change_scroll(s, m, s.selected_track_index - 1, s.selected_sequence_index - 1)
  end
  return m
end

function remake_map(s, m, c)
  m.map = {}
  for t = 1, #s.tracks do
    table.insert(m.map, remember_cell(s, m.current, t))
  end
  clear_highlights(s)
end

---@alias Highlighter fun(s:S, m:Model, forced:boolean)

---@type Highlighter
function select_highlight_tracks(s, m, forced)
  for t = 1, #m.map do
    local c = m.map[t]

    if c.next then
      if c.next.empty then
        if not c.empty then -- stopping
          s.sequencer:set_track_sequence_slot_is_selected(t, c.step, m.tick == 1)
        end
      else
        if not c.empty then
          s.sequencer:set_track_sequence_slot_is_selected(t, c.step, true)
        end
        s.sequencer:set_track_sequence_slot_is_selected(t, c.next.step, m.tick == 0)
      end
    else
      if not c.empty then
        s.sequencer:set_track_sequence_slot_is_selected(t, c.step, true)
      end
    end
  end
end

---@enum HighlightState 
HighlightState = {
  empty = 1,
  starting = 2,
  playing = 3,
  changing = 4,
  stopping = 5,
}

---@type fun(c:Cell):HighlightState
function cell_highlightstate(c)
  if c.empty then
    if c.next then return ifthen(c.next.empty, HighlightState.empty, HighlightState.starting)
    else return HighlightState.empty end
  else
    if c.next then return ifthen(c.next.empty, HighlightState.stopping, HighlightState.changing)
    else return HighlightState.playing end
  end
end

---@alias HighlighterToColor fun(low : RGBColor, high : RGBColor, track_color: RGBColor?, tick: integer) : RGBColor?

---@type table<HighlightState, HighlighterToColor>
highlighted_colors = {
  [HighlightState.empty] = 
    function(low, high, track_color, tick) return nil end,
  [HighlightState.starting] = 
    function(low, high, track_color, tick) 
      if tick == 1 then return high else return low end 
    end,
  [HighlightState.playing] = 
    function(low, high, track_color, tick) return high end,
  [HighlightState.changing] = 
    function(low, high, track_color, tick) return high end,
  [HighlightState.stopping] = 
    function(low, high, tc, tick)
      if tick == 1 then return low 
      else 
        return {bit.rshift(tc[1], 1), bit.rshift(tc[2], 1), bit.rshift(tc[3], 1)} 
      end
    end,
}

---@type RGBColor
Black = {32,32,32}
---@type RGBColor
Gray = {128,128,128}
---@type RGBColor
White = {255,255,255}

---@type {[1]:RGBColor,[2]:RGBColor}
local up_flash = {Gray, White}

---@type Highlighter
local function slot_color_tracks(s, m, forced)
  local next_color = up_flash[m.tick + 1]

  for t = 1, #m.map do
    local c = m.map[t]
    local targets = nil
    if c.empty then
      if c.next and not c.next.empty then -- starting
        targets = {{ c.next.alias, next_color }}
      end
    else
      if c.next then
        if c.next.empty then -- stopping
          if m.tick == 1 then  
            local tc = s:track(t).color
            targets = {{ c.alias, {bit.rshift(tc[1], 1), bit.rshift(tc[2], 1), bit.rshift(tc[3], 1)} }}
          else
            targets = {{ c.alias, Black }}
          end
        else -- changing
          targets = {{ c.next.alias, next_color},{ c.alias, White }}
        end
      elseif forced then
        if not c.empty then
          targets = {{c.alias, White}}
        end
      end
    end

    if targets then
      for ci = 1, #targets do
        local target_track = s:pattern(targets[ci][1]):track(t)
        if not colors_match(targets[ci][2], target_track.color) then
          target_track.color = targets[ci][2]
        end
      end
    end
  end
end

---@type Highlighter[]
track_highlighting = {
  function(s,m, forced) end,
  slot_color_tracks,
  select_highlight_tracks,
}

---@type Highlighter
function color_tracks(s, m, forced)
  track_highlighting[prefs.highlight.value](s, m, forced)
end

---@alias ModelFun fun(s:S, m:Model)

---@type ModelFun
function eval(s, m)
  s.selected_track_index = m.scroll.x + 1
  if lanes_exist(name) then
    s.selected_sequence_index = m.scroll.y + 3
  else    
    s.selected_sequence_index = m.scroll.y + 1
  end

  if not s.transport.loop_pattern then
    s.transport.loop_pattern = true
  end
  if not s.transport.follow_player then
    s.transport.follow_player = false
  end


  local next = seq_pattern(s, flipped(m.current))
  local current = seq_pattern(s, m.current)

  local dirty = false
  local length = prefs.length.value

  for t = 1, #m.map do
    local c = m.map[t]
    if c.next ~= nil then
      dirty = true

      -- save length of new patterns for auto length mode
      if prefs.length_mode.value == LengthMode.auto then
        if not c.next.empty then
          m.last_length = s:pattern(c.next.alias).number_of_lines
          length = m.last_length
        end
      end

      -- when swapping instantly replace the cell with its next
      if c.swap then
        m.map[t] = change_cell(s, t, c, c.next)
        copy_pattern(s, t, current, c.next.alias)

        -- if the cell is turning off, apply muting to try offing hung notes
        if not c.empty and c.next.empty then
          local track = s:track(t)
          if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
            track.mute_state = renoise.Track.MUTE_STATE_OFF
            m.map[t].dirty = true
          end
        end
      end

      copy_pattern(s, t, next, c.next.alias)
    else
      copy_pattern(s, t, next, c.alias)
    end
  end


  if dirty then
    if prefs.length_mode.value == LengthMode.auto then
      next.number_of_lines = length
      prefs.length.value = length
    elseif prefs.length_mode.value == LengthMode.fixed then
      current.number_of_lines = prefs.length.value
      next.number_of_lines = prefs.length.value
    end

    m.last = map_table(m.map, copy_cell)
    m.history_index = m.history_index + 1
    table.insert(m.history, m.history_index, map_table(m.last, copy_cell))

    if m.swapped then
      m.swapped = false
      s.transport.playing = true
    else
      s.transport:set_scheduled_sequence(flipped(m.current))
    end
  end
end


---@type ModelFun
function process(s, m)
  local pos = s.transport.playback_pos
  local dirty = false
  if pos.sequence > 2 then
    if prefs.lock_playhead.value then
      s.transport:trigger_sequence(m.current)
    end
  end

  if pos.sequence == flipped(m.current) then
    m.current = flipped(m.current)
    for t = 1, #m.map do
      local c = m.map[t]
      if c.next ~= nil then
        m.map[t] = change_cell(s, t, m.map[t], c.next)

        local mode = c.next.mode

        if mode == Mode.once then
          m.map[t].next = change_next(s, t, m.map[t], EmptyCell())
        elseif mode == Mode.step then
          local ns = get_next_step_by_prefs(c.next.gap, s, t, c.next.step, 1)
          local step_result = nil
          if ns == nil then
            step_result = EmptyCell()
          else
            step_result = extract_cell(s, ns, t)
            step_result.mode = Mode.step
            step_result.gap = c.next.gap
          end
          m.map[t].next = change_next(s, t, m.map[t], step_result)
        end
        dirty = true
      end
    end
  end


  if dirty then
    sync(s, model)
    eval(s, model)
  end



  local beat = math.floor((pos.line) / s.transport.lpb)

  if m.beat ~= beat or dirty then
    m.beat = beat
    m.tick = m.beat % 2
    for t = 1, #s.tracks do
      local c = m.map[t]
      if c.dirty and not c.mute and s:track(t).mute_state == renoise.Track.MUTE_STATE_OFF then
        c.dirty = false
        s:track(t).mute_state = renoise.Track.MUTE_STATE_ACTIVE
      end
    end
    color_tracks(s, m, false)
  end
end

function no_lanes_warning()
  renoise.app():show_status("No launch lanes! Turn it on using the menu ( Tools / "..name.." ) or configure a shortcut for 'Toggle Lanes'")
end

---@type fun(type:Msg, value:any)
function emit(type, value)
  if lanes_exist(name) then
    local s = renoise.song()
    if s == nil then return end
    model = sync(s, model)
    model = update(s, model, {type = type, value = value})
    eval(s, model)
    color_tracks(s, model, false)
  else
    no_lanes_warning()
  end
end

function resize_lanes(s, length)
  seq_pattern(s, 1).number_of_lines = length
  seq_pattern(s, 2).number_of_lines = length
end

---@type fun(scroll:Scroll, offset:Scroll):Cell[]
function cells_at_offset(scroll, offset)
  local s = renoise.song()
  if s == nil then return {} end
  local c = {
    track = clamp(scroll.x + offset.x, 1, #s.tracks),
    step = clamp(scroll.y + offset.y + 2, 3, #s.sequencer.pattern_sequence)
  }
  local track = s:track(c.track)
  if track.type == renoise.Track.TRACK_TYPE_GROUP then
    ---@cast track renoise.GroupTrack
    if track.group_collapsed then
      return map_table(get_group_track_indices(s, c.track), function(t) return {track = t, step = c.step} end)
    end
  end

  return { c }
end

---@alias CellTarget {track:integer, step:integer}

---@type fun(s:S,scroll_y:integer, y:integer):CellTarget[]
function cells_in_row(s, scroll_y, y)
  local row = {}
  for i = 1, #s.tracks do
    table.insert(row, {
      track = i, 
      step = clamp(scroll_y + y + 2, 3, #s.sequencer.pattern_sequence),
    })
  end
  return row
end
