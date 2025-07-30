---@diagnostic disable: lowercase-global, undefined-global

function clamp(value, minimum, maximum)
  local min = math.min
  local max = math.max
  return max(min(value, maximum), minimum)
end


function Waveshaper_S1(sample_val, amount)
  return 1.5 * sample_val -0.5 * sample_val * sample_val * sample_val
end

--https://www.musicdsp.org/en/latest/Effects/46-waveshaper.html
function Waveshaper_S2(sample_val, amount)
  local abs = math.abs
  local k = 2 * amount / (1 - amount)
  return (1 + k) * sample_val / (1 + k * abs(sample_val))
end

--https://www.musicdsp.org/en/latest/Effects/43-waveshaper.html
function Waveshaper_S3(sample_val, amount)
  local pi = math.pi
  local sin = math.sin
  local z = pi * amount
  local s = 1 / sin(z)
  local b = 1 / amount

  if sample_val > 1.0 then
    return 0.99
  else
    return sin(z * sample_val) * s
  end
end

--https://www.musicdsp.org/en/latest/Effects/41-waveshaper.html
function Waveshaper_S4(sample_val, amount)
  local abs = math.abs
  return sample_val * (abs(sample_val) + amount) / (sample_val ^ 2 + (amount - 1) * abs(sample_val) + 1)
end


--https://www.musicdsp.org/en/latest/Effects/86-waveshaper-gloubi-boulga.html
function GloubiBoulga_waveshaper(sample_val, amount)
  local a, b = 0, 0
  local exp = math.exp
  local sqrt = math.sqrt
  local abs = math.abs

  sample_val = sample_val * amount --0.686306
  a = 1 + exp(sqrt(abs(sample_val)) * -0.75)
  b = exp(sample_val)
  return (b - exp(-sample_val * a)) * b / (b * b + 1)
  --return sample_val - 0.15 * sample_val ^ 2 - 0.15 * sample_val ^ 3
end

--https://www.musicdsp.org/en/latest/Effects/139-lo-fi-crusher.html
function BitCrusher(buffer, bits)
  local int = math.floor
  local normfreq = tmp.SAMPLE_FILTER_FREQ / 44100
  local step = 1 / (2 ^ bits)
  local phasor = 0
  local last = 0
  local buff = {}
  local i=nil

  for i=1, #buffer do
    phasor = phasor + normfreq
    if phasor >= 1.0 then
      phasor = phasor - 1
      last = step * int(buffer[i] / step + 0.5)
    end
    buff[i] = last
  end
  return buff
end


function Foldback_Distortion(sample_val, threshold)
  local abs = math.abs
  if sample_val >= threshold or sample_val <= -threshold then
    return abs(abs((sample_val - threshold) % (threshold * 4)) - threshold * 2) - threshold
  else
    return sample_val
  end
end


function gaussian_mixture(value)
  local x1, x2, x3, x4, x5 = nil, nil, nil, nil, nil
  local exp = math.exp
  x1 = tmp.GAUSSIAN_V1 * exp(tmp.GAUSSIAN_S1 * (value - tmp.GAUSSIAN_N1) ^ 2)
  x2 = tmp.GAUSSIAN_V2 * exp(tmp.GAUSSIAN_S2 * (value - tmp.GAUSSIAN_N2) ^ 2)
  x3 = tmp.GAUSSIAN_V3 * exp(tmp.GAUSSIAN_S3 * (value - tmp.GAUSSIAN_N3) ^ 2)
  x4 = tmp.GAUSSIAN_V4 * exp(tmp.GAUSSIAN_S4 * (value - tmp.GAUSSIAN_N4) ^ 2)
  x5 = tmp.GAUSSIAN_V5 * exp(tmp.GAUSSIAN_S5 * (value - tmp.GAUSSIAN_N5) ^ 2)
  return x1 - x2 + x3 - x4 + x5
end

--https://webaudio.github.io/Audio-EQ-Cookbook/Audio-EQ-Cookbook.txt

function Filters(buffer, filter_type)

  local freq = clamp(tmp.SAMPLE_FILTER_FREQ, 0, 22050)  
  local Q = tmp.SAMPLE_FILTER_QUALITY  
  local gain = tmp.SAMPLE_FILTER_GAIN
  local wet = tmp.SAMPLE_FILTER_WET
  
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

  elseif filter_type == 9 then  -- formant filter
    return FormantFilter(buffer, tmp.SAMPLE_FILTER_VOWEL)

  elseif filter_type == 10 then -- bitcrusher
    return BitCrusher(buffer, clamp(tmp.SAMPLE_FILTER_QUALITY, 1, 16))

  end

  local buff = {}
  local i = nil
  for i=1, #buffer do
    local svalue = buffer[i]
    local output = process(svalue)
    output = svalue * (1 - wet) + (output * wet)
    buff[i] = output
  end
  
  return buff

end

--[[----------------------------------------------------------------
WORK IN PROGRESS FILTERS ETC
]]------------------------------------------------------------------

function MoogVCF(buffer)

  local output = 0
  local cutoff = tmp.SAMPLE_FILTER_FREQ
  local res = tmp.SAMPLE_FILTER_WET
  local f = (cutoff*2) / 44100
  local k = 3.6 * f - 1.6 * f * f - 1
  local p = (k + 1) * 0.5
  local e = 0.577215664901
  local scale = e^((1 - p)* 1.386249)
  local r = res * scale
  local y4 = output 

  local y1, y2, y3, y4 = 0, 0, 0, 0
  local oldx, oldy1, oldy2, oldy3 = 0, 0, 0, 0

  local buff={}
  local i= nil

  for i=1, #buffer do
  
    local input = buffer[i]
    local x = input - r * y4

    -- four cascaded onepole filters
    y1 = x * p + oldx * p - k * y1
    y2 = y1 * p + oldy1 * p - k * y2
    y3 = y2 * p + oldy2 * p - k * y3
    y4 = y3 * p + oldy3 * p - k * y4

    -- clipper band limited sigmoid
    y4 = y4 - (y4 ^ 3) / 6

    oldx = x
    oldy1 = y1
    oldy2 = y2
    oldy3 = y3

    buff[i] = y4
  end

  return buff

end

--[[---------------------------------------------------------------------------
Simple Lowpass filter / test /
]]-----------------------------------------------------------------------------

function MXFilter(buffer)
    
  local r = tmp.SAMPLE_FILTER_WET
  local f = tmp.SAMPLE_FILTER_FREQ

  local c = 1.0 / math.tan(math.pi * f / 44100)
  local a1 = 1.0 / (1.0 + r * c + c * c)
  local a2 = 2 * a1
  local a3 = a1
  local b1 = 2.0 * (1.0 - c * c) * a1
  local b2 = (1.0 - r * c + c * c) * a1
  local output, output1, output2 = 0, 0, 0
  local input, input1, input2 = 0, 0, 0

  local buff = {}
  for i=1, #buffer do
    local input = buffer[i]
    output = a1 * input + a2 * input1 + a3 * input2 - b1 * output1 - b2 * output2
    input2 = input1
    input1 = input
    output2 = output1
    output1 = output
    buff[i] = output
  end

  return buff

end


--[[--------------------------------------------------------------------------
State variable filter
]]----------------------------------------------------------------------------

function Filter(buffer, filter_type)
  local cutoff = tmp.SAMPLE_FILTER_FREQ
  local value = tmp.SAMPLE_FILTER_QUALITY
  local fs = 44100
  local f = cutoff / fs * 4 ----2 * math.sin(math.pi * cutoff / fs)
  --local q = tmp.SAMPLE_FILTER_WET --resonance / bandwidth 0 < q < 1
  local q = math.sqrt(1.0 - math.atan(math.sqrt(value)) * 2.0 / math.pi)
  local scale = math.sqrt(q)  --q
  local low, high, band, notch = 0, 0, 0, 0
  local buff = {}
  local i = nil

  local max_val = -9999
  local min_val = 9999

  for i=1, #buffer do
    local input = buffer[i]
    low = low + f * band
    high = scale * input - low - q * band
    band = f * high + band
    notch = high + low

    if filter_type == 1 then
      buff[i] = low
    elseif filter_type == 2 then
      buff[i] = high
    elseif filter_type == 3 then
      buff[i] = band
    else
      buff[i] = notch
    end

    -- Prepare values for wave normalization
    if  buff[i]> max_val then
      max_val = buff[i]
    end
    
    if buff[i] < min_val then
      min_val = buff[i]
    end

  end

  local highest = 0

  if max_val > min_val then
    highest = max_val
  else
    highest = math.abs(min_val)
  end

  return buff, highest

end


function FormantFilter(buffer, vowelnum)
  
  local coeff = {}
  local memory = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
  local buff = {}
  local i = nil

  coeff[1] = {3.11044e-06, 8.943665402, -36.83889529, 92.01697887, -154.337906, 181.6233289,
             -151.8651235, 89.09614114, -35.10298511, 8.388101016, -0.923313471} -- A

  coeff[2] = {4.36215e-06, 8.90438318,  -36.55179099, 91.05750846, -152.422234, 179.1170248,
             -149.6496211, 87.78352223, -34.60687431, 8.282228154, -0.914150747} -- E

  coeff[3] = {3.33819e-06, 8.893102966, -36.49532826, 90.96543286, -152.4545478, 179.4835618,
             -150.315433,  88.43409371, -34.98612086, 8.407803364, -0.932568035} -- I

  coeff[4] = {1.13572e-06, 8.994734087, -37.2084849, 93.22900521, -156.6929844, 184.596544,
             -154.3755513, 90.49663749, -35.58964535, 8.478996281, -0.929252233} -- O

  coeff[5] = {4.09431e-07, 8.997322763, -37.20218544, 93.11385476, -156.2530937, 183.7080141,
             -153.2631681, 89.59539726, -35.12454591, 8.338655623, -0.910251753} -- U

  for i=1, #buffer do
    local res = coeff[vowelnum][1] * buffer[i] +
              coeff[vowelnum][2] * memory[1] +
              coeff[vowelnum][3] * memory[2] +
              coeff[vowelnum][4] * memory[3] +
              coeff[vowelnum][5] * memory[4] +
              coeff[vowelnum][6] * memory[5] +
              coeff[vowelnum][7] * memory[6] +
              coeff[vowelnum][8] * memory[7] +
              coeff[vowelnum][9] * memory[8] +
              coeff[vowelnum][10] * memory[9] +
              coeff[vowelnum][11] * memory[10]

    memory[10]= memory[9]
    memory[9]= memory[8]
    memory[8]= memory[7]
    memory[7]= memory[6]
    memory[6]= memory[5]
    memory[5]= memory[4]
    memory[4]= memory[3]
    memory[3]= memory[2]
    memory[2]= memory[1]
    memory[1]= res
  
    buff[i] = res

  end

  return buff

end
