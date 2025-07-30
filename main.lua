require "util"
require "euclidean"
require "chorder"
require "bars"
require "glider"

local name = "genpad"

---@alias WriteTarget "Pattern Editor" | "Phrase Editor"

---@enum PadMessage
PadMessage = {
  model = 1,
  close = 2,
  ignore = 3,
}

---@alias PadInit<T, TF> fun(s : renoise.Song, m : T?, flag : TF) : T|string
---@alias PadUpdate<T> fun(s : renoise.Song, m : T, e : KeyEvent, mods : ModKeys) : {[1] : PadMessage, [2]:T?}
---@alias PadView<T> fun(s : renoise.Song, vb: ViewBuilderInstance, m : T) : renoise.Views.View
---@alias PadModule<T> { init : PadInit<T>, update : PadUpdate<T>, view : PadView<T>, save : boolean?, model : T?, actions : table<string, function>?, title: string?}

---@alias UpdateFun<T> fun(m : T, mods : ModKeys): T
---@alias UpdateKeys<T> { left : UpdateFun<T>, right : UpdateFun<T>, up : UpdateFun<T>, down : UpdateFun<T>, back : UpdateFun<T> }

---@enum PadType
PadType = {
  euclidean = "euclidean",
  chorder = "chorder",
  bars = "bars",
  glider = "glider",
}

local pads = {
  chorder = ChorderPad,
  euclidean = EuclidPad,
  bars = BarsPad,
  glider = GliderPad,
}

local target_pad = PadType.euclidean

---@type renoise.Dialog?
local dialog = nil

local model = nil
---@type renoise.Views.View
local view = nil
---@type renoise.Views.View
local view_container = nil

---@type renoise.Views.MultiLineText?
local output = nil

local function default_prefs()
  return {

  }
end
local prefs = renoise.Document.create("ScriptingToolPreferences")(default_prefs())

local tool = renoise.tool()
tool.preferences = prefs


-- local function show_notes(notes)
--   local 
-- end

local function close_pad()
  if dialog then
    if dialog.visible then
      dialog:close()
    end
    dialog = nil
  end
end

---@type fun(s:renoise.Song, m: any)
local function swap_view(s, m)
  local vb = renoise.ViewBuilder()
  local v = pads[target_pad].view(s, vb, m)
  view_container:remove_child(view)
  view = v
  view_container:add_child(view)
end

local vim_bindings = {
  h = "left",
  j = "down",
  k = "up",
  l = "right",
  x = "back",
}

---@type KeyHandler
local function key_handler(_dialog, e)
  if e.name == "esc" then
    close_pad()
    return 
  end

  local s = renoise.song()
  if s == nil then return end

  local vim_bind = vim_bindings[e.name]
  if vim_bind then
    e.name = vim_bind
  end

  local next = pads[target_pad].update(s, model, e, get_mods(e.modifiers))

  if next[1] == PadMessage.model then
    model = next[2]
    -- if pads[target_pad].save then
    pads[target_pad].model = next[2]
    -- end
    swap_view(s, model)
  elseif next[1] == PadMessage.close then
    close_pad()
  elseif next[1] == PadMessage.ignore then
    return e
  end
end

---@type fun(pad:string, message:string)
local function open_warning(pad, message)
  local title = name .. " - " ..target_pad .. " failed!"
  local text = message
  local ls = string:split(message, "%#")
  if #ls > 1 then
    title = name .. " - " .. target_pad .. ": ".. ls[1]
    text = ls[2]
  end
  local p = renoise.app():show_prompt(title, text, {"Ok"})
end

---@type fun(s:renoise.Song, t: PadType, target : WriteTarget)
local function open_pad(s, t, target)
  s.transport.follow_player = false

  target_pad = t

  local vb = renoise.ViewBuilder()
  model = pads[target_pad].init(s, pads[target_pad].model, target)

  if type(model) == "string" then
    open_warning(target_pad, model)
  else
    view = pads[target_pad].view(s, vb, model)
    view_container = vb:column{
      view
    }
    
    local title = ifthen(pads[target_pad].title ~= nil, pads[target_pad].title, t)
    dialog = renoise.app():show_custom_dialog(title, view_container, key_handler, {send_key_release = true, send_key_repeat = true})
  end
end

local function start_pad(t, target)
  return function(repeated)
    local s = renoise.song()
    if s and not repeated then
      close_pad()
      open_pad(s, t, target)
    end
  end
end

---@type fun(padtype : PadType, target : WriteTarget)
local function add_entries(padtype, target)
  tool:add_keybinding({
    name = target..":Tools:"..name.." - "..padtype,
    invoke = start_pad(padtype, target)
  })
  tool:add_menu_entry({
    name = target..":"..name.." - "..padtype,
    invoke = start_pad(padtype, target)
  })
end

---@type fun(padtype : PadType, target : WriteTarget)
local function add_action_entries(padtype, target)
  local pad = pads[padtype]
  if pad.actions == nil then return end
  for k, action in pairs(pad.actions) do
    tool:add_keybinding({
      name = target..":Tools:"..name.." - "..padtype.." "..string:join(string:split(k, "_"), " "),
      invoke = function()
        local result = action(renoise.song(), pad.model, nil)
        if type(result) == "string" then
          open_warning(padtype, result)
        end
      end
    })
  end
end


add_entries(PadType.euclidean, "Pattern Editor")
add_entries(PadType.euclidean, "Phrase Editor")

add_entries(PadType.chorder, "Pattern Editor")
add_entries(PadType.chorder, "Phrase Editor")

add_entries(PadType.bars, "Pattern Editor")

add_entries(PadType.glider, "Pattern Editor")

add_action_entries(PadType.glider, "Pattern Editor")


_AUTO_RELOAD_DEBUG = function() end

print(name .. " loaded.")
