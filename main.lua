require("util")
require("config")
require("gui")

local name = "chunk_chops"

local dp = default_prefs()
tool = renoise.tool()
prefs = renoise.Document.create("ScriptingToolPreferences")(dp)
tool.preferences = prefs

function reset_defaults()
  for key, value in pairs(dp) do
    print(key, value)
    prefs[key].value = value
  end
end

require("parse")

last_pattern = nil
dirty = false
parse_message = ""
delay_counter = 0

-- function valid_chunk_name(name)
--   return prefs.prefix.value == name:sub(1,#prefs.prefix.value)
-- end

function parse_seed(name)
  return parse_number(with_default(name:match("%$([^%s]+)"), ""), false, nil)
end

function write_seed(name, seed)
  local i = name:find("%$")
  if i == nil then
    return name .. " $" .. seed
  else
    return name:gsub("%$([^%s]+)", "$"..seed)
  end
end

function is_chunk_track(t)
  return t.name:sub(1,1) == prefs.prefix.value and t.type == renoise.Track.TRACK_TYPE_SEQUENCER
end

function is_locked_track(t)
  return t.name:sub(1,1) == "#"
end

function get_target_tracks(s, track, index)
  local name = track.name
  local type = ChunkTrackType.all
  local type_char = name:sub(2,2)
  local tracks = {}
  local append_if_valid = function(t)
    local nt = s:track(t)
    if t ~= index and not is_locked_track(nt) and not is_chunk_track(nt) then
      table.insert(tracks, t)
    end
  end
  
  if type_char then
    type_char = string.lower(type_char)
    if type_char == ChunkTrackType.track then 
      type = ChunkTrackType.track
      local track_count = 1
      local v = name:sub(3,3)
      if v and tonumber(v) then
        track_count = tonumber(v)
      end
      
      for t = index + 1, index + track_count + 1 do
        append_if_valid(t)
      end
    elseif type_char == ChunkTrackType.group then
      local parent = track.group_parent
      if parent ~= nil then
        for t = 1, #s.tracks do
          local tp = top_parent(s:track(t))
          if tp and tp.name == parent.name then
            append_if_valid(t)
          end
        end
      end
    else
      for t = index + 1, #s.tracks do
        append_if_valid(t)
      end
    end
  else
    for t = index + 1, #s.tracks do
      append_if_valid(t)
    end
  end
  return tracks
end



function render_pattern(seed_dir, force_new_seed)
  local s = renoise.song()
  local track = s.selected_track_index
  local name = s.selected_track.name
  if not is_chunk_track(s.selected_track) then 
    return
  end

  local target_tracks = get_target_tracks(s, s.selected_track, s.selected_track_index)

  local seed = with_default(parse_seed(name), prefs.seed.value)
  if not force_new_seed then
    prefs.seed.value = seed
  end

  seed_dir = with_default(seed_dir, 1)


  if s.sequencer:track_sequence_slot_is_muted(track, s.selected_sequence_index) or s:track(track).mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
    return 
  end

  if not prefs.keep_seed.value or force_new_seed then
    prefs.seed.value = prefs.seed.value + seed_dir
  end

  if prefs.write_seed.value then
    s:track(track).name = write_seed(name, prefs.seed.value)
  end

  math.randomseed(prefs.seed.value)

  local cm = render_chunks(s, s.selected_pattern_index, track, target_tracks)
  if prefs.change_color.value then
    s:track(track).color = pref_color(prefs, "idle_color")
  end
end



function on_line_edit(e)
  local s = renoise.song()
  if not is_chunk_track(s:track(e.track)) then return end
  -- if e.track == prefs.track.value then
  if not dirty then
    local chunk_track = s.tracks[s.selected_track_index]
    -- local parsed = parse_line(s, e.track, s:pattern(e.pattern):track(e.track):line(e.line), true)
    -- parse_message = print_status(parsed)
    -- renoise.app():show_status(parse_message)

    if prefs.change_color.value then
      chunk_track.color = pref_color(prefs, "dirty_color")
    end
    dirty = true
  end
  delay_counter = 0
end

function auto_render()
  if not prefs.auto_render.value then return end
  if dirty then
    if delay_counter < prefs.auto_render_delay.value then
      delay_counter = delay_counter + 1
      -- renoise.app():show_status(parse_message)
    else
      dirty = false
      delay_counter = 0
      render_pattern()
    end
  end
end

function on_pattern_select()
  if last_pattern then
    remove_line_notifier(last_pattern, on_line_edit)
    dirty = false
  end
  last_pattern = renoise.song().selected_pattern_index
  add_line_notifier(last_pattern, on_line_edit)
end

function init()
  local song = renoise.song()
  if song ~= nil then
    add_notifier(song.selected_pattern_observable, on_pattern_select)
    on_pattern_select()
    dirty = false
    -- open_dialog(name, prefs)
  end

  if prefs.auto_render.value then
    toggle_auto_render(true)
  end
end

function toggle_auto_render(enable)
  toggle_notifier(tool.app_idle_observable, auto_render, enable)
end

add_notifier(tool.app_new_document_observable, init)


tool:add_menu_entry({
  name = "Main Menu:Tools:" .. name,
  invoke = function() open_dialog(name, prefs) end,
})

tool:add_menu_entry({
  name = "Pattern Editor:" .. name .. ":Render Pattern",
  invoke = render_pattern,
})

tool:add_menu_entry({
  name = "Pattern Editor:" .. name .. ":Render Pattern With New Seed",
  invoke = function() render_pattern(1, true) end,
})

tool:add_keybinding({
  name = "Pattern Editor:Tools:Render Chunk Pattern",
  invoke = function(repeated)
    if not repeated then
      render_pattern()
    end
  end
})
tool:add_keybinding({
  name = "Pattern Editor:Tools:Render Chunk Pattern With New Seed",
  invoke = function(repeated)
    if not repeated then
      render_pattern(1, true)
    end
  end
})

_AUTO_RELOAD_DEBUG = function() end
print(name .. " loaded.")