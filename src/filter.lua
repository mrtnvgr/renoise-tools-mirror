---@diagnostic disable: deprecated, lowercase-global, undefined-field

local cos = math.cos
local sin = math.sin
local asin = math.asin
local sinh = math.sinh
local tanh = math.tanh
local pi = math.pi
local twopi = pi * 2
local sqrt = math.sqrt
local floor = math.floor
local abs = math.abs
local fmod = math.fmod


function mod(n, d)
  n = fmod(n, d)
  if n < 0 then n = n + d end
  return n
end

function Saturator(samples, typ, amount)
	local buffer = {}
  local ms = 0

  for i=1, #samples do

    if typ == 2 then
      buffer[i] = sin(samples[i] * amount * 20)

    elseif typ == 3 then
      buffer[i] = tanh(samples[i] * amount * 20)

    elseif typ == 4 then

      if samples[i] >= 0.0 then
        if samples[i] <= amount then
          buffer[i] = samples[i]
          ms = amount
        end

      else
        if samples[i] >= -amount then
          buffer[i] = -amount
          ms = -amount
        end
      end

      local m1 = 1.0 - amount
      buffer[i] = ms + tanh((samples[i] - ms) / m1) * m1

    end
	end
	return buffer
end

function Filter(buffer, filter_type, frequency, quality, gain1, wet1)

    local freq = frequency or 1000
    local Q = quality or 1
    local gain = gain1 or 0.5
    local wet = wet1 or 0.99

    local a0, a1, a2 = 0, 0, 0
    local b0, b1, b2 = 0, 0, 0
    local x0, x1, x2 = 0, 0, 0
    local y0, y1, y2 = 0, 0, 0

    local w0 = 2 * pi * freq / SAMPLERATE
    local alpha = sin(w0) / (2 * Q)
    local cos_w0 = cos(w0)
    local A = 10 ^ (gain / 40)

    local function process(x0)
      -- direct form 1
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
      local tsaa = 2 * sqrt(A) * alpha
      b0 = A * ((A + 1) - (A - 1) * cos_w0 + tsaa)
      b1 = 2 * A * ((A - 1) - (A + 1) * cos_w0)
      b2 = A *((A + 1) - (A - 1) * cos_w0 - tsaa)
      a0 = (A + 1) + (A - 1) * cos_w0 + tsaa
      a1 = -2 *((A - 1) + (A + 1) * cos_w0)
      a2 = (A + 1) + (A - 1) * cos_w0 - tsaa

    elseif filter_type == 8 then    -- HighShelf filter
      local tsaa = 2 * sqrt(A) * alpha
      b0 = A * ((A + 1) + (A - 1) * cos_w0 + tsaa)
      b1 = -2 * A * ((A - 1) + (A + 1) * cos_w0)
      b2 = A * ((A + 1) + (A - 1)*cos_w0 - tsaa)
      a0 = (A + 1) - (A - 1) * cos_w0 + tsaa
      a1 = 2 * ((A - 1) - (A + 1) * cos_w0)
      a2 = (A + 1) - (A - 1) * cos_w0 - tsaa

    end

    local buff = {}
    for i=1, #buffer do
      local svalue = buffer[i]
      local output = process(svalue)
      output = svalue * (1 - wet) + (output * wet)
      buff[i] = output
    end

    return buff

end


function OnePole_LPF(input, response)
  -- response is in ms

  local twopi = math.pi * 2
  local a = math.exp(-twopi / (response * 0.001 * SAMPLERATE))
  local b = 1.0 - a
  local z = 0.0
  local buffer = {}

  for i=1, #input do
    z = (input[i] * b) + (z * a)
    buffer[i] = z
  end
  return buffer
end


function SimpleCombFilter(samples, delayInMiliseconds, decayFactor)
  local buffer = table.rcopy(samples)
  local delaySamples = floor(delayInMiliseconds * (SAMPLERATE / 1000))
  for i=1, #samples - delaySamples do
    buffer[i + delaySamples] = buffer[i + delaySamples] + buffer[i] * decayFactor
  end
  return buffer
end


function SchroederReverb(samples, delayInMiliseconds, decayFactor, mixPercent)
  local buffer = {}
  local comb1 = SimpleCombFilter(samples, delayInMiliseconds, decayFactor)
  local comb2 = SimpleCombFilter(samples, delayInMiliseconds - 11.73, decayFactor - 0.1313)
  local comb3 = SimpleCombFilter(samples, delayInMiliseconds + 19.31, decayFactor - 0.2743)
  local comb4 = SimpleCombFilter(samples, delayInMiliseconds - 7.97, decayFactor - 0.31)

  local mix = {}
  for i=1, #samples do
    buffer[i] = (comb1[i] + comb2[i] + comb3[i] + comb4[i])-- / 4
    mix[i] = ((1 - mixPercent) * samples[i]) + (mixPercent * buffer[i])
  end
  comb1, comb2, comb3, comb4 = nil, nil, nil, nil
  return mix --buffer
end


function CombFilterFB(samples, a, b)
  local delay = a or 3     -- feedback delay (lag) in number of samples
  local alpha = b or 1      -- exponential decay gain, default = 1
  local buffer = table.rcopy(samples)
  for i=1, #samples do
    if i > delay then
      buffer[i] = samples[i] + alpha * buffer[i - delay]
    else
      buffer[i] = samples[i]
    end
  end
  return buffer
end


function CombFilterFF(samples, a, b)
  local delay = a or 3     -- feedforward delay (lag) in number of samples
  local alpha = b or 1      -- exponential decay gain, default = 1
  local buffer = table.rcopy(samples)
  for i=1, #samples do
    if i > delay then
      buffer[i] = samples[i] + alpha * samples[i - delay]
    else
      buffer[i] = samples[i]
    end
  end
  return buffer
end


function square_wave(t)
  local x = sin(t)
  if x > 0.0 then return 1.0 else return -1.0 end
end

function triangle_wave(t)
  return asin(cos(t) / 1.57079633)
end

function xor(a, b)
  if a ~= b then return 1 else return 0 end
end

function RingModulator(input, in1, in2, in3, freq)
  local samples = #input
  local pot1 = in1                           -- frequency scaler [2.0 .. 6.0]
  local ringmod_blend = in2                  -- tremolo blend [0.0 .. 1.0]
  local ringmod_rate = 2.0 + 4.0 * pot1
  local t = 0.0                              -- for time calculations
  local current_modulator = floor(in3)       -- 1 .. sin, 2 .. triangle, 3 .. square
  local ring_buffer = {}

  for i=1, samples do
      local ring_factor
      if current_modulator == 1 then
          ring_factor = sin(pi * t * freq)
      elseif current_modulator == 2 then
          ring_factor = triangle_wave(pi * t * freq)
      elseif current_modulator == 3 then
          ring_factor = square_wave(pi * t * freq)
      elseif current_modulator == 4 then
          local square1 = square_wave(pi * t * freq)
          local square2 = square_wave(pi * t * (freq * sqrt(2)))
          ring_factor = xor(square1, square2)
      end
      t = t + ringmod_rate * 0.02
      if t > twopi then t = t - twopi end
      ring_buffer[i] = (1.0 - ringmod_blend) * input[i] + ringmod_blend * ring_factor * input[i]
  end
  return ring_buffer
end


function DFilter(b,a,input)
  -- constant for Butterworth filter (order 3, LowPass)
  --local a = {1.00000000, -2.77555756e-16, 3.33333333e-01, -1.85037171e-17}
  --local b = {0.16666667, 0.5, 0.5, 0.16666667}
  -- result = DFilter(b, a, signal)
  -- comb
  -- b = {1, 0, 0, 0.5 ^ 3}
  -- a = {1, 0, 0, 0, 0, 0.9 ^ 5}
  local out = {}
  for i=1, #input do
      local tmp = 0
      local j = 0
      out[i] = 0

      for j=1, #b do
          if i - j < 0 then
              --continue
          else
              tmp = tmp + b[j] * input[i - j + 1]
          end
      end

      for j=2, #a do
          if i - j < 0 then
              --continue
          else
              tmp = tmp - a[j] * out[i - j + 1]
          end
      end

      tmp = tmp / a[1]
      out[i] = tmp
  end
  return out
end