function clamp(v, mn, mx)
  return math.min(mx, math.max(mn, v))
end

function wrapi(a, b)
  return ((((a - 1) % b) + b) % b) + 1
end

function random_from(length, avoid)
  local r = math.floor(math.random() * length) + 1
  if r == avoid then
    r = wrap(r, 1, length)
  end
  return r
end

function line_wrap(line, max)
  return ((line - 1) % max) + 1
end

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

function command_lookup(cs)
  local ls = {}
  for c in pairs(cs) do
    ls[cs[c].alias] = cs[c]
  end
  return ls
end

function pclamp(v, mn, mx)
  return clamp(v, mn, mx)
end

function lclamp(v, mn, mx)
  return math.min(mx, math.max(mn, v))
end

function is_empty_line(l)
  return l.is_empty
end

function clear_line(s, track, pattern, line)
  local p = s:pattern(pattern)
  for t = 1, #s.tracks do
    if t ~= track then
      p:track(t):line(line):clear()
    end
  end
end

function off_line(s, track, pattern, line)
  local p = s:pattern(pattern)
  for t = 1, #s.tracks do
    if t ~= track then
      local l = p:track(t):line(line)
      l:clear()
      for n = 1, s:track(t).visible_note_columns do
        local nc = l:note_column(n)
        nc.note_value = renoise.PatternLine.NOTE_OFF
        nc.instrument_value = 0xFF
      end
    end
  end
end

function with_default(n, d)
  if n == nil then return d else return n end
end
function effect_string(ec)
  return ec.number_string..ec.amount_string
end

function pref_color(p, c)
  return { p[c.."_r"].value, p[c.."_g"].value, p[c.."_b"].value}
end

function top_parent(t, p)
  if t.group_parent then
    return top_parent(t.group_parent, t.group_parent)
  else
    return p
  end
end

function add_notifier(observable, fun)
  if not observable:has_notifier(fun) then
    observable:add_notifier(fun)
  end
end

function remove_notifier(observable, fun)
  if observable:has_notifier(fun) then
    observable:remove_notifier(fun)
  end
end

function toggle_notifier(observable, fun, enable)
  if enable then add_notifier(observable, fun)
  else remove_notifier(observable, fun) end
end

function add_line_notifier(pattern, fun)
  if pattern <= #renoise.song().patterns then
    if not renoise.song():pattern(pattern):has_line_notifier(fun) then
      renoise.song():pattern(pattern):add_line_notifier(fun)
    end
  end
end

function remove_line_notifier(pattern, fun)
  if pattern <= #renoise.song().patterns then
    if renoise.song():pattern(pattern):has_line_notifier(fun) then
      renoise.song():pattern(pattern):remove_line_notifier(fun)
    end
  end
end