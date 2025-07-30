---@diagnostic disable: undefined-global, lowercase-global, deprecated, undefined-field, cast-local-type
-- literatura
-- https://www.dsprelated.com/freebooks/pasp/Extended_Karplus_Strong_Algorithm.html

VERSION = "0.01"
AUTHOR = "martblek (martblek@gmail.com)"

vb = renoise.ViewBuilder()
vbs = vb.views
dialog = nil
rns = nil
rnt = renoise.tool()
ra = renoise.app()


NOTES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

require "src/files"
require "src/gui"

renoise.tool():add_menu_entry{
  name = "Sample Editor: Rezonator",
  invoke = function()
    prepare_for_start()
  end
}

renoise.tool():add_keybinding{
  name="Global:Tools: Rezonator",
  invoke=function()
    prepare_for_start()
  end
}

_AUTO_RELOAD_DEBUG = function()
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


-- not used yet
function BPM_to_time(bpm, beat, measure, note_len)
  -- note_len is 1, 2, 4, 8, 16, 32
  local beat_duration = 60 / measure
  local measure_duration = beat_duration * beat
  return measure_duration / note_len
end


function gaussian_rnd(N)
  local i=nil
  local sum = 0
  local rnd = math.random
  for i=1, N do
    sum = sum + rnd()
  end
  return sum / N
end


function log2(n)
  return math.log(n) / math.log(2)
end


function pitch(f)
  local base_freq = 440
  if settings.tunning == 2 then
    base_freq = 432
  end
  return 69 + int(12 * log2(f / base_freq))
end


function freq(midi_note)
  local base_freq = 440
  if settings.tunning == 2 then
    base_freq = 432
  end
  return base_freq * 2 ^ ((midi_note - 69) / 12)
end


function miditone(t)
  local note = 0
  local octave = 0
  for k, v in pairs(NOTES) do
    if string.sub(t, 1, 1) == v then
      note = k
      if string.sub(t, 2, 2) == "#" then
        note = note + 1
        octave = tonumber(string.sub(t, 3, 3))
      else
        octave = tonumber(string.sub(t, 2, 2))
      end
      break
    end
  end
  return 12 * (int(octave) + 1) + note - 1
end


function tone(t)
  return freq(miditone(t))
end

--[[-----------------------------------------------------------------------------------
NOISE GENERATORS
]]-------------------------------------------------------------------------------------

function create_white_noise(wave_len)
  local rnd = math.random
  local buff = {}
  local i = nil
  for i=0, wave_len do
    buff[i] = gaussian_rnd(settings.gauss_rnd) * 2 - 1
  end
  return buff
end


function create_pink_noise(sample_len)
  local b0, b1, b2, b3, b4, b5, b6 = 0, 0, 0, 0, 0, 0, 0
  local pink = 0
  local buff = {}
  local i = nil
  local rnd = math.random
  for i=0, sample_len do
    local white_noise = (gaussian_rnd(settings.gauss_rnd) * 2 - 1)
    b0 = 0.99886 * b0 + white_noise * 0.0555179
    b1 = 0.99332 * b1 + white_noise * 0.0750759
    b2 = 0.96900 * b2 + white_noise * 0.1538520
    b3 = 0.86650 * b3 + white_noise * 0.3104856
    b4 = 0.55000 * b4 + white_noise * 0.5329522
    b5 = -0.7616 * b5 - white_noise * 0.0168980
    pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white_noise * 0.5362
    b6 = white_noise * 0.115926
    buff[i] = pink * 0.11
  end
  return buff
end


function create_brownian_noise(sample_len)
  local rnd = math.random
  local buff = {}
  local i = nil
  local last_val = 0
  for i=0, sample_len do
    local white_noise = (gaussian_rnd(settings.gauss_rnd) * 2 - 1)
    local val = (last_val + (0.02 * white_noise)) / 1.02
    last_val = val
    buff[i] = val * 3.5
  end
  return buff
end

--[[--------------------------------------------------------------------------
POST FILTERS
]]----------------------------------------------------------------------------

function Lfilter(b, a, input)
  local out = {}
  for i=1, table.getn(input) do
    local tmp = 0
    out[i] = 0
    for j = 1, table.getn(b) do
      if i - j < 0 then
        -- continue
      else
        tmp = tmp + b[j] * input[i - j + 1]
      end
    end
    for j=2, table.getn(a) do
      if i - j < 0 then
        -- continue
      else
        tmp = tmp - a[j] * out[i - j + 1]
      end
    end
    tmp = tmp / a[1]
    out[i] = tmp
  end
  return out
end

function test_Lfilter()
  local sig = {
      -0.917843918645, 0.141984778794, 1.20536903482,  0.190286794412,-0.662370894973,
      -1.00700480494, -0.404707073677, 0.800482325044, 0.743500089861, 1.01090520172,
       0.741527555207, 0.277841675195, 0.400833448236,-0.2085993586,  -0.172842103641,
      -0.134316096293, 0.0259303398477,0.490105989562, 0.549391221511, 0.9047198589
  }

  --Constants for a Butterworth filter (order 3, low pass)
  local a = {1.00000000, -2.77555756e-16, 3.33333333e-01, -1.85037171e-17}
  local b = {0.16666667, 0.5, 0.5, 0.16666667}

  local result = filter(b,a,sig)
  for i=1,table.getn(result) do
      io.write(result[i] .. ", ")
  end
  print()
  return nil
end

function Filter(buffer, filter_type)

  local freq = settings.filter_frequency  
  local Q = settings.filter_quality  
  local gain = settings.filter_gain
  local wet = settings.filter_wet
  
  local a0, a1, a2 = 0, 0, 0
  local b0, b1, b2 = 0, 0, 0
  local x0, x1, x2 = 0, 0, 0
  local y0, y1, y2 = 0, 0, 0

  local w0 = 2 * math.pi * freq / 44100
  local alpha = math.sin(w0) / (2 * Q)
  local cos_w0 = math.cos(w0)
  local A = 10 ^ (gain / 40)

  local function process(x0)
    y2, y1 = y1, y0
    y0 = (b0 / a0) * x0 + (b1 / a0) * x1 + (b2 / a0) * x2 - (a1 / a0) * y1 - (a2 / a0) * y2
    x2, x1 = x1, x0
    return y0
  end

  if filter_type == 1 then        -- Lowpass filter
    b0 = (1 - cos_w0) / 2
    b1 = 1 - cos_w0
    b2 = (1 - cos_w0) / 2
    a0 = 1 + alpha
    a1 = -2 * cos_w0
    a2 = 1 - alpha
  
  elseif filter_type == 2 then    -- Highpass filter
    b0 = (1 + cos_w0) / 2
    b1 = -(1 + cos_w0)
    b2 = (1 + cos_w0) / 2
    a0 = 1 + alpha
    a1 = -2 * cos_w0
    a2 = 1 - alpha
  
  elseif filter_type == 3 then    -- Bandpass filter
    b0 = Q * alpha
    b1 = 0
    b2 = -Q * alpha
    a0 = 1 + alpha
    a1 = -2 * cos_w0
    a2 = 1 - alpha
  
  elseif filter_type == 4 then    -- Notch filter
    b0 = 1
    b1 = -2 * cos_w0
    b2 = 1
    a0 = 1 + alpha
    a1 = -2 * cos_w0
    a2 = 1 - alpha
  
  elseif filter_type == 5 then    -- Allpass filter
    b0 = 1 - alpha
    b1 = -2 * cos_w0
    b2 = 1 + alpha
    a0 = 1 + alpha
    a1 = -2 * cos_w0
    a2 = 1 - alpha
  
  elseif filter_type == 6 then    -- Peak EQ filter
    b0 = 1 + alpha * A
    b1 = -2 * cos_w0
    b2 = 1 - alpha * A
    a0 = 1 + alpha / A
    a1 = -2 * cos_w0
    a2 = 1 - alpha / A
  
  elseif filter_type == 7 then    -- LowShelf filter
    local tsaa = 2 * math.sqrt(A) * alpha
    b0 = A * ((A + 1) - (A - 1) * cos_w0 + tsaa)
    b1 = 2 * A * ((A - 1) - (A + 1) * cos_w0)
    b2 = A *((A + 1) - (A - 1) * cos_w0 - tsaa)
    a0 = (A + 1) + (A - 1) * cos_w0 + tsaa
    a1 = -2 *((A - 1) + (A + 1) * cos_w0)
    a2 = (A + 1) + (A - 1) * cos_w0 - tsaa
  
  elseif filter_type == 8 then    -- HighShelf filter
    local tsaa = 2 * math.sqrt(A) * alpha
    b0 = A * ((A + 1) + (A - 1) * cos_w0 + tsaa)
    b1 = -2 * A * ((A - 1) + (A + 1) * cos_w0)
    b2 = A * ((A + 1) + (A - 1)*cos_w0 - tsaa)
    a0 = (A + 1) - (A - 1) * cos_w0 + tsaa
    a1 = 2 * ((A - 1) - (A + 1) * cos_w0)
    a2 = (A + 1) - (A - 1) * cos_w0 - tsaa

  end

  local buff = {}
  local i = nil
  for i=0, #buffer do
    local svalue = buffer[i]
    local output = process(svalue)
    output = svalue * (1 - wet) + (output * wet)
    buff[i] = output
  end
  
  return buff

end


function lowpass(x, dt, RC)
  
  -- RC lowpass filter
  -- dt .. časový interval
  -- RC .. časová konstanta
  
  local i = nil
  local y = {}

  for i=0, #x - 1 do
    y[i] = 0
  end

  local a = dt / (RC + dt)
  y[1] = x[1]

  for i = 1, #x - 1 do
    y[i] = a * x[i] + (1 - a) * y[i - 1]
  end

  return y
end

-- not used yet
function feedback(damp, x0, x1)
  return damp * 0.5 * (x0 + x1)
end


function H_p(p, x, x1)
  -- pick-direction lowpass filter
  return x * (1 - p) / (1 - p * x1)
end


function H_b(delay, x, i, samples, n)
  return x * (0.5 - (samples[int(i - delay) % n]))
end


-- H_d one-zero string damping filter
function damp1(tone, t60, B, x, x1)
  local rho = math.pow(0.001, 1.0 / (tone * t60))
  local b1 = 0.5 * B
  local b0 = 1.0 - b1

  return rho * (b0 * x + b1 * x1)
end


-- H_d two-zero string damping filter
function damp2(tone, t60, B, x, x1, x2)
  local rho = math.pow(0.001, 1.0 / (tone * t60))
  local h0 = (1.0 + B) / 2
  local h1 = (1.0 - B) / 4

  return rho * (h0 * x1 + h1 * (x + x2))
end


--[[--------------------------------------------------------------------------------
STRING GENERATOR
]]----------------------------------------------------------------------------------

function generate(duration, tone, crop)

  local length = int(duration * tonumber(SAMPLERATE[settings.samplerate]))
  if crop == 0 then
    crop = length
  end

  local n = int(length / tone)
  
  -- generate noise source for our instrument
  local signal = nil
  if settings.noise_source == 1 then
    signal = create_white_noise(n)
  elseif settings.noise_source == 2 then
    signal = create_pink_noise(n)
  elseif settings.noise_source == 3 then
    signal = create_brownian_noise(n)
  else
    --
  end

  -- fill delay_line for algorithm
  local i = nil
  local samples = {}
  for i = 0, crop do
    samples[i] = 0
  end

  -- values for RC Filter
  local f0 = settings.RC_f0 * tone
  local RC = 1 / (2.0 * math.pi * f0)
  local dt = settings.RC_dt

  signal = lowpass(signal, dt, RC)

  local M = int(settings.beta * n)

  for i= 0, crop do
    local x = signal[i % n]
    local x1 = signal[(i + 1) % n]
    local x2 = signal[(i-2) % n]

    samples[i] = x

    -- H_d string damping filter
    -- Im using one a two zero together
    if settings.damping_filter == 1 then
      x = damp1(tone, settings.t60, settings.B, x1, x)

    elseif settings.damping_filter == 2 then
      x = damp2(tone, settings.t60, settings.B, x, x1, x2)

    elseif settings.damping_filter == 3 then
      x = damp1(tone, settings.t60, settings.B, x1, x)
      x = damp2(tone, settings.t60, settings.B, x, x1, x2)

    else
      --

    end

    local xf = x1
    
    xf = H_p(settings.p, xf, signal[i % n])


    signal[i % n] = 0.5 * (x + xf)

  end

  if settings.filter < 9 then
    samples = Filter(samples, settings.filter)
  end

  return samples

end

--[[----------------------------------------------------------------------------------------------------
GENERATE CHORD OR SOME
]]------------------------------------------------------------------------------------------------------

function table_merge(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

function generate_chord(nchord, crop)
  
  local buff = {}
  
  for num, note in pairs(nchord) do
    
    local silence = int((num - 1) * settings.string_delay * 0.001 * tonumber(SAMPLERATE[settings.samplerate]))
    --print(tostring(silence))
    local empty = {}
    for i=1, silence do
      empty[i] = 0
    end
    
    table_merge(empty, generate(settings.duration, tone(note), crop))
    
    buff[num] = table.rcopy(empty)
  
  end

  local i, j = nil, nil
  local chord = {}
  for i = 1, crop do --settings.duration * tonumber(SAMPLERATE[settings.samplerate])
    chord[i] = 0
    for j = 1, #buff do
      chord[i] = chord[i] + buff[j][i]
    end
  end

  return chord
end

--[[--------------------------------------------------------------------------------------------
CREATE SAMPLE
]]----------------------------------------------------------------------------------------------

function string_draw()
  if settings.render == 1 and settings.sample_autorender == true then
    draw()
  end
end


function draw()

  local note = NOTES[settings.selected_note]..settings.selected_octave
  local crop = 0
  
  if settings.crop > 0.0 then
    crop = 2 * settings.duration * tonumber(SAMPLERATE[settings.samplerate]) * settings.crop
  end
  
  local data = {}
  if settings.render == 1 then
    data = generate(settings.duration, tone(note), crop)
  
  elseif settings.render == 2 then
    
    local chords = {}
    
    if settings.chnote_1_on then
      table.insert(chords, NOTES[settings.chnote_1]..settings.chnote_1_oct)
    end
    
    if settings.chnote_2_on then
      table.insert(chords, NOTES[settings.chnote_2]..settings.chnote_2_oct)
    end
    
    if settings.chnote_3_on then
      table.insert(chords, NOTES[settings.chnote_3]..settings.chnote_3_oct)
    end
    
    if settings.chnote_4_on then
      table.insert(chords, NOTES[settings.chnote_4]..settings.chnote_4_oct)
    end
    
    if settings.chnote_5_on then
      table.insert(chords, NOTES[settings.chnote_5]..settings.chnote_5_oct)
    end

    if settings.chnote_6_on then
      table.insert(chords, NOTES[settings.chnote_6]..settings.chnote_6_oct)
    end

    if settings.chnote_7_on then
      table.insert(chords, NOTES[settings.chnote_7]..settings.chnote_7_oct)
    end

    if settings.chnote_8_on then
      table.insert(chords, NOTES[settings.chnote_8]..settings.chnote_8_oct)
    end

    if settings.stroke == 2 then
      -- upstroke > reverse chord
      local ch = {}
      for _, v in ripairs(chords) do
        table.insert(ch, v)
      end

      chords = table.rcopy(ch)

    elseif settings.stroke == 3 then 
      -- down/up stroke
      local ch = table.rcopy(chords)
      table.remove(chords, #chords)
      for _, v in ripairs(chords) do
        table.insert(ch, v)
      end

      chords = table.rcopy(ch)

    elseif settings.stroke == 4 then
      -- up/down stroke
      local ch = {}
      for _, v in ripairs(chords) do
        table.insert(ch, v)
      end

      table.remove(chords, 1)

      for _, v in pairs(chords) do
        table.insert(ch, v)
      end

      chords = table.rcopy(ch)

    end

    data = generate_chord(chords, crop)
      
  end

  local instrument = renoise.song().selected_instrument
  
  while table.getn(instrument.samples) > 0 do
    instrument:delete_sample_at(1)
  end
  
  if settings.name == "" then
    instrument.name="R3z0n4t0r Instrument"
  else
    instrument.name = settings.name
  end

  local new_sample = instrument:insert_sample_at(1)
  new_sample.name="R3z0n4t0r Sample"
  
  if settings.sample_loop > 1 then
    new_sample.loop_mode = settings.sample_loop
  end

  local new_buffer = new_sample.sample_buffer
  new_buffer:create_sample_data(tonumber(SAMPLERATE[settings.samplerate]), tonumber(BITS[settings.bits]), 1, #data)
  local i = nil

  new_buffer:prepare_sample_data_changes()
  
  if not settings.sample_revert then
  
    for i=1, #data do
      new_buffer:set_sample_data(1, i, data[i])
    end
  
  elseif settings.sample_revert then
    
    for i=1, #data-1 do
      new_buffer:set_sample_data(1, i, data[#data - i])
    end
  
  end
  
  new_buffer:finalize_sample_data_changes()

end