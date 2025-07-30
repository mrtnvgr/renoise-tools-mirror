---@diagnostic disable: undefined-global, lowercase-global, deprecated, undefined-field, cast-local-type

--[[------------------------------------------------------------------------------------------------------

v0.01 initial upload
v0.02 kick filter selector fix
      make master volume for all generators
      in snare section added volume for noise and backdrum
v0.03 added kick wave selector
      hihat section has 2 modes / metalic added /
      added cymbal a claps section
      added randomizer
v0.04 added morpher, a randomizer little bro
      new claps algorithm with DAD (Delay, Attack, Decay) envelope gen.
v0.05 added saturation on master
v0.06 Temporary removed "realtime" sample preview
      due to an unhandled error when manually editing the sample /Djeroek/

v0.07 Added attempt to create glockenspiel and gongs.
      Added some filters and rezonators.
      Added Samplerate and bitrate selection

v0.08 Refresh on Bells and Gongs, glockenspiel someday.
      Added selectable nr. of waves and more.
      Experimental Glitcher section.

]]--------------------------------------------------------------------------------------------------------


VERSION = "0.08"
AUTHOR = "martblek (martblek@gmail.com)"

vb = renoise.ViewBuilder()
vbs = vb.views
dialog = nil

SAMPLERATES = {"11025", "22050", "44100", "48000", "96000", "192000"}
SAMPLERATE = tonumber(SAMPLERATES[3])

BITRATES = {"8", "16", "24", "32"}
BITRATE = tonumber(BITRATES[2])

RENDER_SAMPLE = true


require("src/gui")
require("src/render")
require("src/filter")
require("src/noise")
require("src/osc")
EASING = require("src/easing")

EASEFN = {
  EASING.linear,
  EASING.inQuad,
  EASING.outQuad,
  EASING.inOutQuad,
  EASING.outInQuad,
  EASING.inCubic,
  EASING.outCubic,
  EASING.inOutCubic,
  EASING.outInCubic,
  EASING.inQuart,
  EASING.outQuart,
  EASING.inOutQuart,
  EASING.outInQuart,
  EASING.inQuint,
  EASING.outQuint,
  EASING.inOutQuint,
  EASING.outInQuint,
  EASING.inSine,
  EASING.outSine,
  EASING.inOutSine,
  EASING.outInSine,
  EASING.inExpo,
  EASING.outExpo,
  EASING.inOutExpo,
  EASING.outInExpo,
  EASING.inCirc,
  EASING.outCirc,
  EASING.inOutCirc,
  EASING.outInCirc,
  EASING.inBounce,
  EASING.outBounce,
  EASING.inOutBounce,
  EASING.outInBounce,
  EASING.inElastic,
  EASING.outElastic,
  EASING.inOutElastic,
  EASING.outInElastic,
  EASING.inBack,
  EASING.outBack,
  EASING.inOutBack,
  EASING.outInBack,
}


renoise.tool():add_menu_entry{
  name = "Sample Editor:Almost Drums",
  invoke = function()
    prepare_for_start()
  end
}

renoise.tool():add_keybinding{
  name="Global:Tools:Almost Drums",
  invoke=function()
    prepare_for_start()
  end
}


function key_handler(dialog, key)
  return key
end

_AUTO_RELOAD_DEBUG = function()
end

Notifiers = {}
function Notifiers:add(observable, callable)
  if not observable:has_notifier(callable) then
    observable:add_notifier(callable)
  end
end


function Notifiers:remove(observable, callable)
  if observable:has_notifier(callable) then
    observable:remove_notifier(callable)
  end
end


function tool_idle()
  if not dialog.visible then
    Notifiers:remove(renoise.tool().app_idle_observable, tool_idle)
    Notifiers:remove(renoise.song().selected_instrument_observable, instrument_changed)
  end
end


function sample_changed()
  local sample_index = renoise.song().selected_sample_index
  vbs.drum_switch.value = sample_index
end


function instrument_changed()
  print("instrument changed")
end


function prepare_for_start()
  if(dialog and dialog.visible) then
    dialog:show()
    check_gui_visibility()
    return
  end
  dialog = renoise.app():show_custom_dialog("~ Almost Drums ~", make_gui, key_handler)
  check_gui_visibility()
  Notifiers:add(renoise.tool().app_idle_observable, tool_idle)
  Notifiers:add(renoise.song().selected_instrument_observable, instrument_changed)
end
