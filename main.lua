---@diagnostic disable: undefined-global, deprecated, undefined-field, lowercase-global

--[[

v0.01 Initial release
v0.02 Sample render and other stuff rewrited
      Added more wave types
      Added Morpher with selectable harmonies
      Added saturators / waveshaper /
      Added experimental wovel filter

]]--


VERSION = "0.02"
AUTHOR = "martblek (martblek@gmail.com)"

vb = renoise.ViewBuilder()
vbs = vb.views
dialog = nil
rns = nil
rnt = renoise.tool()
ra = renoise.app()

SAMPLERATE = 44100
BITRATE = 16
BUFFERS = {"84", "168", "336", "676", "1348", "2696", "5396", "10788"}
HARMONIC_SERIES = {}
HARMONY_OFFSET = 1
RENDER_ENABLED = true


OLD_BUFFER = {
	sample_rate=0,
	number_of_frames=0,
	bit_depth=0,
	number_of_channels=0,
}

for i=1, 256 do
  HARMONIC_SERIES[i] = 0
end
HARMONIC_SERIES[1] = 1 

require "src/generators"
require "src/gui"

renoise.tool():add_menu_entry{
  name = "Sample Editor: Harmoniks",
  invoke = function()
    prepare_for_start()
  end
}

renoise.tool():add_keybinding{
  name="Global:Tools: Harmoniks",
  invoke=function()
    prepare_for_start()
  end
}

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

function app_idle()
  if not dialog.visible then
    --
  else
    --print("window is showed")
  end

end


--[[--------------------------------------------------------------------------------
TOOLS
]]----------------------------------------------------------------------------------

function int(number)
  local f = math.floor(number)
  if (number == f) or (number % 2.0 == 0.5) then
    return f
  else
    return math.floor(number + 0.5)
  end
end


function draw_sample()

  if RENDER_ENABLED == false then return end

  local instrument = renoise.song().selected_instrument
  local selected_sample = renoise.song().selected_sample_index
  local samples_nr = table.getn(instrument.samples)

  instrument.name="Harmoniks Instrument"

  local new_sample
  if samples_nr == 0 then
    new_sample = instrument:insert_sample_at(1)
  else
    new_sample = renoise.song().selected_sample
  end

  --new_sample.loop_mode = 2

  local new_buffer = new_sample.sample_buffer

  -- get selected sample buffer len
  local nr_samples = tonumber(BUFFERS[vbs.buffer_len.value])

  local w = vbs.wave_selector.value
  local wave
  if w == 1 then
    wave = sine(nr_samples)
  elseif w == 2 then
    wave = saw(nr_samples)
  elseif w == 3 then
    wave = square(nr_samples)
  elseif w == 4 then
    wave = triangle(nr_samples)
  end

  if new_buffer.has_sample_data
		and nr_samples == OLD_BUFFER.number_of_frames
		and new_buffer.sample_rate == OLD_BUFFER.sample_rate
		and new_buffer.bit_depth == OLD_BUFFER.bit_depth
		and new_buffer.number_of_channels == OLD_BUFFER.number_of_channels

	then
		-- do nothing buffer is unchanged

	else
		-- make new buffer
		new_buffer:create_sample_data(SAMPLERATE, BITRATE, 1, nr_samples)
		OLD_BUFFER.number_of_frames = nr_samples
		OLD_BUFFER.sample_rate = SAMPLERATE
		OLD_BUFFER.bit_depth = BITRATE
		OLD_BUFFER.number_of_channels = 1
	end

  wave = wave_calc(wave)

  if vbs.saturate_selector.value > 1 then
    wave = Saturator(wave, vbs.saturate_selector.value, vbs.saturation_amount.value)
  end

  if vbs.wovel_selector.value > 1 then
    wave = FormantFilter(wave, vbs.wovel_selector.value - 1)
  end

  new_buffer:prepare_sample_data_changes()
  for i=1, #wave do
    new_buffer:set_sample_data(1, i, wave[i] * vbs.master_volume.value)
  end
  new_buffer:finalize_sample_data_changes()
end