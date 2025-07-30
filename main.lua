_AUTO_RELOAD_DEBUG = function() end

require("color")

local name = "tint"

local tool = renoise.tool()
---@enum RetainMode
local RetainMode = {
  add = 1,
  max = 2,
  replace = 3,
  custom = 4,
  clear = 5,
}
local RetainModes = { "Add", "Max", "Replace", "Custom", "Clear" }
local RetintTargets = { "All", "Sequencer", "Send", "Selected" }
local SpectrumDirection = { "Colder", "Warmer" }

---@class TintPrefs : renoise.Document.DocumentNode
---@field highlight renoise.Document.ObservableBoolean
---@field opacity renoise.Document.ObservableNumber
---@field override_opacity_offset renoise.Document.ObservableNumber
---@field retain_mode renoise.Document.ObservableNumber
---@field offset renoise.Document.ObservableNumber
---@field scale renoise.Document.ObservableNumber
---@field saturation renoise.Document.ObservableNumber
---@field value renoise.Document.ObservableNumber
---@field direction renoise.Document.ObservableNumber
---@field target renoise.Document.ObservableNumber
---@field auto_apply renoise.Document.ObservableBoolean
---@field keep_master_gray renoise.Document.ObservableBoolean

---@type TintPrefs
local prefs = renoise.Document.create("ScriptingToolPreferences")({
  highlight = true,
  opacity = 16,
  override_opacity_offset = 16,
  retain_mode = 5,
  -- bloom = 0,
  offset = 0.0,
  scale = 0.95,
  saturation = 0.8,
  value = 0.8,
  direction = 1,
  target = 1,
  auto_apply = true,
  keep_master_gray = true,
})

tool.preferences = prefs

local dialog = nil

local last_selected = 0
local last_opacity = 0

---@type fun(t : number) :  number
local function cos(t)
  return (math.cos(t * 3.14159265 * 2.0) * 0.5 + 0.5)
end

---@alias NormalColor {[1]:number, [1]:number, [1]:number}

---@type fun(t : number, offset : number, scale : number) : NormalColor
local function spectrum(t, offset, scale)
  if prefs.direction.value == 2 then
    t = 1 - t - 0.15
  end
  t = t * scale + offset
  return { cos(t), cos(t - 1.0 / 3.0), cos(t + 1.0 / 3.0) }
end

---@type fun(cs:NormalColor) : RGBColor
local function normal2byte(cs)
  local byte = function(x)
    return math.floor(x * 255)
  end
  return { byte(cs[1]), byte(cs[2]), byte(cs[3]) }
end

---@type fun(v:number, mn:number, mx:number):number
local function clamp(v, mn, mx)
  return math.min(mx, math.max(mn, v))
end

---@type fun(last:integer, next : integer) : integer
local function get_opacity(last, next)
  if last == 0 then
    return next
  end

  local m = prefs.retain_mode.value
  if m == RetainMode.add then
    return last + next
  elseif m == RetainMode.max then
    return math.max(last, next)
  elseif m == RetainMode.replace then
    return next
  elseif m == RetainMode.custom then
    return last + prefs.override_opacity_offset.value
  elseif m == RetainMode.clear then
    return next
  end
  return next
end

---@param opacity integer
local function refresh_highlight(opacity)
  local song = renoise.song()
  if song == nil then return end
  local selected = song.selected_track_index
  if song.tracks[last_selected] then
    if prefs.retain_mode.value == RetainMode.clear then
      song.tracks[last_selected].color_blend = 0
    else
      song.tracks[last_selected].color_blend = last_opacity
    end
  end
  last_selected = selected
  last_opacity = song.selected_track.color_blend
  song.selected_track.color_blend = clamp(get_opacity(last_opacity, opacity), 0, 100)
end

local function highlight_track()
  if prefs.highlight.value then
    refresh_highlight(prefs.opacity.value)
    -- local function(i, selected, opacity, bloom)
    --   if selected == i then return opacity
    --   elseif i == selected - 1 or i == selected + 1 then return bloom
    --   else return 0 end
    -- end
  end
end

---@type fun(index : integer, count : integer) : RGBColor
local function spectrum_color(index, count)
  local t = index / count
  local hsv = rgbToHsv(normal2byte(spectrum(t, prefs.offset.value, prefs.scale.value)))
  hsv[2] = prefs.saturation.value
  hsv[3] = prefs.value.value
  return hsvToRgb(hsv)
end

-- renoise.Track.TRACK_TYPE_SEQUENCER
-- renoise.Track.TRACK_TYPE_MASTER
-- renoise.Track.TRACK_TYPE_SEND
-- renoise.Track.TRACK_TYPE_GROUP

---@alias ColorGenerator fun(base : RGBColor, index : integer, count : integer) : RGBColor

---@type fun(song: renoise.Song, from : integer, to : integer, fn : ColorGenerator)
local function tint_tracks(song, from, to, fn)
  if from == to then
    song.tracks[from].color = fn(song.tracks[from].color, 0, 1)
  else
    local count = to - from + 1
    for t = from, to do
      song.tracks[t].color = fn(song.tracks[t].color, t - from, count)
    end
  end
end

---@type fun(tracks:renoise.Track[], fn : ColorGenerator)
local function tint_track_list(tracks, fn)
  local count = #tracks
  if count == 1 then
    tracks[1].color = fn(tracks[1].color, 0, count)
  else
    for i = 1, count do
      tracks[i].color = fn(tracks[i].color, i - 1, count)
    end
  end
end

---@type fun(ls:any[], predicate : (fun(a: any, i: integer):boolean)) : any[]
local function filter(ls, predicate)
  local r = {}
  for i = 1, #ls do
    if predicate(ls[i], i) then
      table.insert(r, ls[i])
    end
  end
  return r
end

---@type fun(ls:any[], from :integer, to:integer):any[]
local function slice(ls, from, to)
  local r = {}
  for i = from, to do
    if ls[i] then
      table.insert(r, ls[i])
    end
  end
  return r
end

local function grey_master()
  local song = renoise.song()
  if song == nil then return end
  song.tracks[song.sequencer_track_count + 1].color =
    normal2byte({ prefs.value.value, prefs.value.value, prefs.value.value })
end

local function retint_all(song, fn)
  if prefs.keep_master_gray.value then
    tint_track_list(filter(song.tracks, function(t, i)
      return i ~= song.sequencer_track_count + 1
    end), fn)
    grey_master()
  else
    tint_track_list(song.tracks, fn)
  end
end

local function retint_sequencers(song, fn)
  tint_tracks(song, 1, song.sequencer_track_count, fn)
end

local function retint_send(song, fn)
  local i = 1
  if prefs.keep_master_gray.value then
    i = 2
    grey_master()
  end
  local from = song.sequencer_track_count + i
  if from >= #song.tracks then
    tint_tracks(song, from, #song.tracks, fn)
  end
end

local function retint_selected(song, fn)
  local s = song.selection_in_pattern
  if s ~= nil then
    local ts = slice(song.tracks, s.start_track, s.end_track)
    if prefs.keep_master_gray.value then
      local mi = song.sequencer_track_count + 1
      if mi >= s.start_track and mi <= s.end_track then
        grey_master()
      end
      ts = filter(ts, function(t, i)
        return i ~= song.sequencer_track_count + 1
      end)
    end
    tint_track_list(ts, fn)
  end
end

local function recolor_tracks(fn)
  local song = renoise.song()
  local ops = { retint_all, retint_sequencers, retint_send, retint_selected }
  print(prefs.target.value)
  ops[tonumber(prefs.target.value)](song, fn)
end

---@type ColorGenerator
local function tint(color, index, count)
  return spectrum_color(index, count)
end

local function try_retint()
  if prefs.auto_apply.value then
    recolor_tracks(tint)
  end
end

local margin = 5
local spacing = 5
local text_width = 70

---@type fun(vb:ViewBuilderInstance, label:string, key:string, def:number, mn:number, mx:number) : renoise.Views.Rack
local function color_param_slider(vb, label, key, def, mn, mx)
  return vb:row({
    margin = margin,
    spacing = spacing,

    vb:text({
      width = text_width,
      text = label,
    }),
    vb:slider({
      width = 200,
      bind = prefs[key],
      min = mn,
      max = mx,
      default = def,
      notifier = try_retint,
    }),
  })
end

local open_dialog = function()
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  local vb = renoise.ViewBuilder()
  local override_slider = vb:row({
    margin = margin,
    spacing = spacing,
    visible = prefs.retain_mode.value == RetainMode.custom,
    vb:text({
      width = text_width,
      text = "offset",
    }),
    vb:valuebox({
      width = text_width,
      bind = prefs.override_opacity_offset,
      min = -100,
      max = 100,
      notifier = highlight_track,
    }),
  })
  local dialog_content = vb:column({
    vb:row({
      margin = margin,
      spacing = spacing,
      vb:text({
        text = "Highlight current track",
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,
      vb:text({
        width = text_width,
        text = "enabled",
      }),
      vb:checkbox({
        bind = prefs.highlight,
        notifier = function()
          if prefs.highlight.value then
            highlight_track()
          else
            refresh_highlight(0)
          end
        end,
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,

      vb:text({
        width = text_width,
        text = "opacity",
      }),
      vb:slider({
        width = 200,
        bind = prefs.opacity,
        min = 0.0,
        max = 100.0,
        default = 16,
        notifier = highlight_track,
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,
      width = 200,
      vb:text({
        width = text_width,
        text = "mode",
      }),
      vb:switch({
        width = 200,
        -- value = 1,
        items = RetainModes,
        bind = prefs.retain_mode,
        notifier = function()
          override_slider.visible = prefs.retain_mode.value == RetainMode.custom
          highlight_track()
        end,
      }),
    }),
    override_slider,
    -- vb:row{
    --   margin = margin,
    --   spacing = spacing,

    --   vb:text {
    --     width = text_width,
    --     text = "bloom"
    --   },
    --   vb:slider {
    --     width = 200,
    --     bind = prefs.bloom,
    --     min = 0.0,
    --     max = 100.0,
    --     default = 0,
    --     notifier = highlight_track
    --   },
    -- },
    vb:row({
      margin = margin,
      spacing = spacing,
      vb:text({
        text = "Recolor tracks using a spectrum",
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,

      vb:text({
        width = text_width,
        text = "targets",
      }),
      vb:switch({
        width = 200,
        -- value = 1,
        items = RetintTargets,
        bind = prefs.target,
        notifier = try_retint,
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,
      vb:text({
        text = "grey Master",
        width = text_width,
      }),
      vb:checkbox({
        bind = prefs.keep_master_gray,
        notifier = try_retint,
      }),
    }),
    vb:row({
      margin = margin,
      spacing = spacing,

      vb:text({
        width = text_width,
        text = "direction",
      }),
      vb:switch({
        width = 200,
        value = 1,
        items = SpectrumDirection,
        bind = prefs.direction,
        notifier = try_retint,
      }),
    }),

    color_param_slider(vb, "offset", "offset", 0, 0, 1),
    color_param_slider(vb, "scale", "scale", 0.95, 0, 1),
    color_param_slider(vb, "saturation", "saturation", 0.8, 0, 1.0),
    color_param_slider(vb, "value", "value", 0.8, 0, 1.0),
    vb:row {
      margin = margin * 2,
      spacing = spacing,
      vb:button{
        width = 50,
        text = "Invert Colors",
        pressed = function()
          -- prefs.offset.value = (prefs.offset.value + 0.5) - math.floor(prefs.offset.value)
          -- prefs.value.value = 1.0 - prefs.value.value
          recolor_tracks(function(color)
            return { 255 - color[1], 255 - color[2], 255 - color[3] }
          end
          )
        end,
      }
    },
    -- strip,
    vb:row({
      margin = margin * 2,
      spacing = spacing,
      vb:text({
        text = "Auto Apply",
      }),
      vb:checkbox({
        bind = prefs.auto_apply,
        notifier = try_retint,
      }),
      vb:button({
        width = 50,
        visible = not prefs.auto_apply,
        text = "Apply Now",
        pressed = function() recolor_tracks(tint) end,
      }),
    }),
  })
  dialog = renoise.app():show_custom_dialog(name, dialog_content)
end

local init = function()
  -- rprint(spectrum(0, 0, 1))
  local notifier = {
    add = function(observable, fun)
      if not observable:has_notifier(fun) then
        observable:add_notifier(fun)
      end
    end,
    remove = function(observable, fun)
      if observable:has_notifier(fun) then
        observable:remove_notifier(fun)
      end
    end,
  }

  local setup_notifiers = function()
    local song = renoise.song()
    if song == nil then return end
    last_selected = song.selected_track_index
    last_opacity = song.selected_track.color_blend
    song.selected_track_index_observable:add_notifier(highlight_track)
    highlight_track()
  end

  notifier.add(renoise.tool().app_new_document_observable, setup_notifiers)
end

tool:add_menu_entry({
  name = "Main Menu:Tools:" .. name,
  invoke = open_dialog,
})

print(name .. " loaded. ")

init()
