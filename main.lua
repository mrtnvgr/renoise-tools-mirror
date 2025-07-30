require "util"
require "engine"
require "gui"

---@type string
name = "launch_lanes"

---@class (exact) LLView
---@field main renoise.Views.View?
---@field clock renoise.Views.RotaryEncoder?
---@field dialog renoise.Dialog?
---@field length_switch renoise.Views.Switch?
---@field current_length renoise.Views.Text?
---@field enabled_check renoise.Views.CheckBox?
---@field tabs renoise.Views.View[]?

---@type LLView
local view = {
  main = nil,
  clock = nil,
  dialog = nil,
  length_switch = nil,
  current_length = nil,
  enabled_check = nil,
}

---@type string
local swap_mod = "alt"

---@enum PostStep
local PostStep = {
  none = 1,
  right = 2,
  last = 3,
}

---@enum Wrap
Wrap = {
  none = 1,
  tracks = 2,
  patterns = 3,
  both = 4
}

---@enum LengthMode
LengthMode = {
  auto = 1,
  fixed = 2,
}

---@enum SwapMode
SwapMode = {
  hold_to_swap = 1,
  hold_to_arm = 2,
  toggle = 3,
}

---@enum HighlightMode
HighlightMode = {
  none = 1,
  colors = 2,
  selection = 3,
}

---@type fun():table<string, ObservableTypes>
local function default_prefs()
  return {
    length = 64,
    length_mode = LengthMode.auto,
    muted_is_gap = true,
    automation_is_gap = false,
    empty_is_gap = true,
    section_is_gap = true,

    highlight = HighlightMode.colors,

    swap_mode = SwapMode.hold_to_swap,

    wrap = Wrap.both,
    lock_playhead = true,
    play_mode = Mode.loop,
    post_step = PostStep.right,
    gap_mode = Gap.ignore,

    cell_keys1 = "123456789",
    cell_keys2 = "qwertyuio",
    cell_keys3 = "asdfghjkl",
    cell_keys4 = "zxcvbnm,.",
    row_key1 = "0",
    row_key2 = "p",
    row_key3 = ";",
    row_key4 = "/",
    mode_keys = "=]\\"
  }
end


---@type fun()
function reset_defaults()
  local dp = default_prefs()
  for key, value in pairs(dp) do
    prefs[key].value = value
  end
end

---@class Prefs : renoise.Document.DocumentNode
---@field length renoise.Document.ObservableNumber
---@field length_mode renoise.Document.ObservableNumber
---@field muted_is_gap renoise.Document.ObservableBoolean
---@field automation_is_gap renoise.Document.ObservableBoolean
---@field empty_is_gap renoise.Document.ObservableBoolean
---@field section_is_gap renoise.Document.ObservableBoolean
---@field highlight renoise.Document.ObservableNumber
---@field swap_mode renoise.Document.ObservableNumber
---@field wrap renoise.Document.ObservableNumber
---@field lock_playhead renoise.Document.ObservableBoolean
---@field play_mode renoise.Document.ObservableNumber
---@field post_step renoise.Document.ObservableNumber
---@field gap_mode renoise.Document.ObservableNumber
---@field cell_keys1 renoise.Document.ObservableString
---@field cell_keys2 renoise.Document.ObservableString
---@field cell_keys3 renoise.Document.ObservableString
---@field cell_keys4 renoise.Document.ObservableString
---@field row_key1 renoise.Document.ObservableString
---@field row_key2 renoise.Document.ObservableString
---@field row_key3 renoise.Document.ObservableString
---@field row_key4 renoise.Document.ObservableString
---@field mode_keys renoise.Document.ObservableString


---@type Model
model = nil


---@type Prefs
prefs = renoise.Document.create("ScriptingToolPreferences")(default_prefs())
prefs.highlight:add_notifier(function() when_song(function (s)
    clear_highlights(s)
    if model ~= nil then
      color_tracks(s, model, true)
    end
  end)
end)

---@type renoise.ScriptingTool
tool = renoise.tool()
tool.preferences = prefs

function run_process()
  local s = renoise.song()
  if s == nil then return end
  -- if view.dialog == nil then
  --   delete_lanes(false)
  --   return
  -- end
  process(s, model)
  if view.clock then
    local l = seq_pattern(s,s.transport.playback_pos.sequence).number_of_lines
    view.clock.max = math.floor( l / s.transport.lpb)
    view.clock.value = model.beat
    view.current_length.text = l..""
  end
end

---@type fun(k:string):{x: integer, y:integer}?
local function key_to_cell(k)
  k = mugglify_char(k)

  local cell_keys = {
    prefs.cell_keys1.value,
    prefs.cell_keys2.value,
    prefs.cell_keys3.value,
    prefs.cell_keys4.value,
  }

  local row_keys = prefs.row_key1.value..prefs.row_key2.value..prefs.row_key3.value

  for i = 1, #cell_keys do
    local index = string.find(cell_keys[i], k)
    if index then
      return { x = index, y = i }
    end
  end

  local index = string.find(row_keys, k)
  if index then
    return { y = index }
  end

  return nil
end

---@type fun(mods:KeyMods):Msg
local function mods_to_msg(mods)
  if mods.shift and mods.control then
    return Msg.step
  elseif mods.shift then
    return Msg.stop
  elseif mods.control then
    return Msg.solo
  else
    return Msg.play
  end
end


-- ---@type fun(v:number)
-- function on_clock_change(v)
--   -- renoise.song().transport:start_at(v)
-- end

---@type fun(l:integer)
local function on_length_change(l) when_song(function (s)
  if lanes_exist(name) then
    if prefs.length_mode.value == LengthMode.fixed then
      seq_pattern(s, model.current).number_of_lines = prefs.length.value
    end
    -- prefs.length_mode.value = LengthMode.fixed
  end
  end)
end

---@type fun(lm:LengthMode)
local function on_length_mode_change(lm) when_song(function (s)
  if lanes_exist(name) then
    if lm == LengthMode.fixed then
      seq_pattern(s, model.current).number_of_lines = prefs.length.value
    elseif lm == LengthMode.auto then
      seq_pattern(s, model.current).number_of_lines = model.last_length
    end
  end
  end)
end


local function create_lanes()
  local s = renoise.song()
  if s == nil then return end
  s.transport:panic()
  renoise.app().window.pattern_matrix_is_visible = true

  ensure_lanes(s, name, "", prefs.length.value)
  model = Model(s)

  if not tool.app_idle_observable:has_notifier(run_process) then
    tool.app_idle_observable:add_notifier(run_process)
  end

  renoise.app():show_status(name .. " enabled.")
end

local function delete_lanes()
  if lanes_exist(name) then
    local s = renoise.song()
    if s == nil then return end
    local i = s.selected_sequence_index
    s.transport.playing = false
    s.sequencer:delete_sequence_at(1)
    s.sequencer:delete_sequence_at(1)
    s.selected_sequence_index = clamp(i - 2, 1, #s.sequencer.pattern_sequence)
    clear_highlights(s)
  end

  if tool.app_idle_observable:has_notifier(run_process) then
    tool.app_idle_observable:remove_notifier(run_process)
  end

  renoise.app():show_status(name .. " disabled.")
end

---@type fun(enable:boolean?, from_gui:boolean?)
function toggle_lanes(enable, from_gui)
  local s = renoise.song()
  if s == nil then return end
  if enable == nil then
    if lanes_exist(name) then
      delete_lanes()
    else
      create_lanes()
    end
  else
    if enable then
      if not lanes_exist(name) then
        create_lanes()
      end
    else
      delete_lanes()
    end
  end

  if view.enabled_check and not from_gui then
    if lanes_exist(name) then
      view.enabled_check.value = true
    else
      view.enabled_check.value = false
    end
  end

  remake_map(s, model, #s.tracks)
end

local function after_scroll()
  local x = { 0, 1, model.last_scroll.x }
  emit(Msg.scroll_x, {dir = x[prefs.post_step.value]})
end

---@alias Direction -1|1

---@type fun(msg:Msg, swap:boolean, dir:Direction?)
local function current_cell_action(msg, swap, dir) when_song(function (s)
  local v = {
    toggle = true, 
    cells = cells_at_offset(
      { x = s.selected_track_index - 1, y = s.selected_sequence_index - 1 - 2}, 
      { x = 1, y = 1 }
    ), 
    swap = swap,
    dir = dir
  }
  emit(msg, v)
  after_scroll()
  end)
end

---@type fun(msg:Msg, swap:boolean, dir:Direction?)
local function current_row_action(msg, swap, dir) when_song(function (s)
  local v = { 
    toggle = false, 
    cells = cells_in_row(s, s.selected_sequence_index - 3, 1), 
    swap = swap,
    dir = dir,
  }
  emit(msg, v)
  end)
end

---@type fun(k:string, keys:string):integer?
local function key_index(k, keys)
  return string.find(keys, mugglify_char(k))
end

---@type fun(key:string, mods:KeyMods, state:ButtonState)
local function key_action(key, mods, state)
  local s = renoise.song()
  if s == nil then return end
  model = sync(s, model)
  if state == ButtonState.released then return end
  if state ~= ButtonState.repeated then
    if key == "n" then
      if mods.alt then
        clone_pattern(s, model.current, #s.sequencer.pattern_sequence + 1, mods.shift)
      end
    elseif key == "x" then
      if mods.alt then
        toggle_lanes()
      end
    end
  end

  if not lanes_exist(name) then return end

  local scroll_fun = function(msg, dir)
    return function(jump)
      emit(msg, {dir = dir, jump = jump})
    end
  end

  local scroll_funs = {
    up = scroll_fun(Msg.scroll_y, -1),
    down = scroll_fun(Msg.scroll_y, 1),
    left = scroll_fun(Msg.scroll_x, -1),
    right = scroll_fun(Msg.scroll_x, 1),
  }

  local shift_fun = function(dir)
    return function(swap, cells)
      emit(Msg.step, { dir = dir, cells = cells, swap = swap })
    end
  end

  local shift_history = function(dir)
    return function(swap)
      emit(Msg.history, { dir = dir, swap = swap })
    end
  end


  local shift_funs = {
    up = shift_fun(-1),
    down = shift_fun(1),
    left = shift_history(-1),
    right = shift_history(1),
  }

  if key then  
    if mods.control and shift_funs[key] then
      local cells = { { track = model.scroll.x + 1 } }
      if mods.shift then
        cells = {}
        for t = 1, #s.tracks do
          table.insert(cells, {track = t})
        end
      end
      shift_funs[key](mods[swap_mod], cells)
    elseif scroll_funs[key] then
      scroll_funs[key](mods[swap_mod])
    end
  end

  
  if state ~= ButtonState.repeated or prefs.post_step.value ~= PostStep.none then 
    if key == "space" then
      local v = {toggle = true, cells = cells_at_offset(model.scroll, {x = 1, y = 1}), swap = mods[swap_mod] }
      emit(mods_to_msg(mods), v)
      after_scroll()
    elseif key == "return" then
      local v = {toggle = false, cells = cells_at_offset(model.scroll, {x = 1, y = 1}), swap = mods[swap_mod] }
      emit(Msg.solo, v)
      after_scroll()
    elseif key == "back" then
      local v = {toggle = false, cells = cells_at_offset(model.scroll, {x = 1, y = 1}), swap = mods[swap_mod] }
      emit(Msg.stop, v)
      after_scroll()
      -- emit(Msg.back, mods[swap_mod])
    end
  end

  if state ~= ButtonState.repeated then
    if key then
      local grid_press = key_to_cell(key)
      if grid_press then
        if grid_press.x then
          local v = { toggle = true, cells = cells_at_offset(model.scroll, grid_press), swap = mods[swap_mod]}
          emit(mods_to_msg(mods), v)
        else -- row press
          local v = { toggle = false, cells = cells_in_row(s, model.scroll.y, grid_press.y), swap = mods[swap_mod] }
          emit(mods_to_msg(mods), v)
        end
      elseif key == "tab" then
        local v = { toggle = false, cells = cells_in_row(s, model.scroll.y, 1), swap = mods[swap_mod]}
        emit(mods_to_msg(mods), v)
      else
        local mk = key_index(key, prefs.mode_keys.value)
        if mk and mk < 4 then
          emit(Msg.mode, mk)
        end
      end
    end
  end
end

---@type KeyHandler
local function handle_keys(k, e)
  -- if e.modifiers == "" then print("nil") end
  if e.name then
    if e.name == "esc" then
      delete_lanes()
      if view.dialog and view.dialog.visible then
        view.dialog:close()
      end
    else
      -- rprint(e)
      local n = e.name
      if n == "comma" then n = "," elseif n == "period" then n = "." end
      -- if n == nil or n == " " then n = e.name end
      -- print(n)
      key_action(n, get_mods(e.modifiers), button_state(e.state, e.repeated))
    end
  end
end

-- function map_view(vb, map)
--   local r = vb:row{
--     uniform = true
--   }
--   for i = 1, #map do
--     r:add_child(vb:column{
--       vb:text{
--         text = ""..map[i].alias
--       }
--     })
--   end
--   return r
-- end

-- require "midi"
-- leds = new_leds(8, 5)
-- function on_midi(m)
--   local gn = note_to_grid(m.note)
--   -- rprint(gn)
--   if gn then
--     leds.buffer[gn.y][gn.x] = 127
--     leds.dirty = true
--   end
--   -- rprint(m)
-- end
-- connect_midi("APC Key 25 MIDI 1", on_midi)

-- KEYBINDINGS

---@type fun(n:string, fn:function, allow_repeat:boolean?)
local function add_keybinding(n, fn, allow_repeat)
  local fun = nil
  if allow_repeat then
    fun = fn
  else
    fun = function(repeated)
      if not repeated then fn() end
    end
  end
  tool:add_keybinding({
    name = n,
    invoke = fun
  })
end

---@type fun(n:string, fn:function, allow_repeat:boolean?)
local function add_bindings(n, fn, allow_repeat)
  add_keybinding("Pattern Matrix:Tools:LL - "..n, fn, allow_repeat)
  add_keybinding("Pattern Editor:Tools:LL - "..n, fn, allow_repeat)
end

---@type fun(n:string, fn:function, allow_repeat:boolean?)
local function add_global_binding(n, fn, allow_repeat)
  add_keybinding("Global:Tools:LL - "..n, fn, allow_repeat)
end

---@type fun(type : "cell"|"row", msg:Msg, swap:boolean, dir:Direction?):function
local function current_fun(type, msg, swap, dir)
  return function()
    if not lanes_exist(name) then no_lanes_warning()
    else
      if type == "cell" then current_cell_action(msg, swap, dir)
      else current_row_action(msg, swap, dir) end
    end
  end
end

function close_dialog()
  if view.dialog and view.dialog.visible then
    view.dialog:close()
    view.dialog = nil
  end
end

function open_dialog()
  close_dialog()
  view = create_view(name)
  view.dialog = renoise.app():show_custom_dialog(name, view.main, handle_keys, {send_key_repeat = true, send_key_release = true})
  toggle_lanes(true)
end

actions = {"Play", "Solo", "Stop"}
for i = 1, #actions do
  local a = actions[i]
  local m = Msg[string.lower(a)]
  add_bindings("Pattern Arm "..a, current_fun("cell", m, false))
  add_bindings("Pattern Swap "..a, current_fun("cell", m, true))
  add_bindings("Row Arm "..a, current_fun("row", m, false))
  add_bindings("Row Swap "..a, current_fun("row", m, true))
end

local msg = Msg.step
add_bindings("Pattern Arm Step Up", current_fun("cell", msg, false, -1))
add_bindings("Pattern Swap Step Up", current_fun("cell", msg, true, -1))
add_bindings("Row Arm Step Up", current_fun("row", msg, false, -1))
add_bindings("Row Swap Step Up", current_fun("row", msg, true, -1))
add_bindings("Pattern Arm Step Down", current_fun("cell", msg, false, 1))
add_bindings("Pattern Swap Step Down", current_fun("cell", msg, true, 1))
add_bindings("Row Arm Step Down", current_fun("row", msg, false, 1))
add_bindings("Row Swap Step Down", current_fun("row", msg, true, 1))

add_global_binding("Open Controls", open_dialog)
add_global_binding("Toggle Lanes", toggle_lanes)

-- shift select will stop working with these, todo?
function scroll_fun(message, dir) return function() emit(message, dir) end end
add_bindings("Select Next Track (with Wrap)", scroll_fun(Msg.scroll_x, 1), true)
add_bindings("Select Previous Track (with Wrap)", scroll_fun(Msg.scroll_x, -1), true)
add_bindings("Select Next Sequence (with Wrap)", scroll_fun(Msg.scroll_y, 1), true)
add_bindings("Select Previous Sequence (with Wrap)", scroll_fun(Msg.scroll_y, -1), true)

tool:add_menu_entry({
  name = "Main Menu:Tools:" .. name,
  invoke = function() 
    open_dialog() 
  end,
})

prefs.length:add_notifier(on_length_change)
prefs.length_mode:add_notifier(on_length_mode_change)

function init()
  when_song(function (s)
    model = Model(s)
    if view.dialog and view.dialog.visible then
      open_dialog()
    end
  -- toggle_lanes(false)
  -- open_dialog()
  end)
end

tool.app_new_document_observable:add_notifier(init)

_AUTO_RELOAD_DEBUG = function() end

print(name .. " loaded.")

todo = [[
  history
  toggle mods
  solo 
  cell keys take collapse group into account
  modes + hold
  midi io
]]