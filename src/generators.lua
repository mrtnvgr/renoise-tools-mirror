---@diagnostic disable: undefined-global
--[[---------------------------------------------------------------------
Wave Generators                                                         -
]]-----------------------------------------------------------------------

--[[ Convert table

Buffer        Period       Note
10790          128          C-4
10790          64           C-3
10790          32           C-2
10790          16           C-1
5395           8            C-1
2697           4            C-1
1348           2            C-1              128 > C7
674            1            C-1               64 > C7
337            1            C-2               16 > C6
169            1            C-3                8 > C6
84             1            C-4     max period 4 > C6
]]---------------------------------------------------


Oscilator = {
  class=1,
  frequency = 1.0,
  phase=0,
  amplitude=0.5,
  detail=1,
  duty=0.5,
  modulate_freq = false,
  modulate_amp = false,
  modulate_phase = false,
  modulate_detail = false,
}

function Oscilator:new(osc,freq, amp, phase, detail, class, duty)
  osc = osc or {}
  setmetatable(osc, self)
  self.__index = self
  self.freq = freq or 1
  self.amplitude = amp or 0.5
  self.phase = phase or 1
  self.detail = detail or 1
  self.class = class or 1
  self.duty = duty or 0.5
  return osc
end

OSC1 = Oscilator:new(nil, tmp.SAMPLE_FREQUENCY_1, tmp.SAMPLE_AMPLITUDE_1, tmp.SAMPLE_PHASE_1, tmp.SAMPLE_DETAIL_1, tmp.SAMPLE_TYPE_1)
OSC2 = Oscilator:new(nil, tmp.SAMPLE_FREQUENCY_2, tmp.SAMPLE_AMPLITUDE_2, tmp.SAMPLE_PHASE_2, tmp.SAMPLE_DETAIL_2, tmp.SAMPLE_TYPE_2)
OSC3 = Oscilator:new(nil, tmp.SAMPLE_FREQUENCY_3, tmp.SAMPLE_AMPLITUDE_3, tmp.SAMPLE_PHASE_3, tmp.SAMPLE_DETAIL_3, tmp.SAMPLE_TYPE_3)

function Oscilator:simple_arccosine(frame, sample_len, val)
  local pi = math.pi
  local acos = math.acos
  local sum
  for n=1, self.detail do
    sum = sum + self.amplitude * (-1 * 2 + acos(-1 * 2 *math.pi / samples * 2))
  end

  return sum
end

function Oscilator:simple_sine(frame, sample_len, val)
	local pi = math.pi
	local sin = math.sin
  local amplitude = self.amplitude
  local frequency = self.frequency
  local phase = self.phase

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local n = nil
  local sum = 0
  for n=1, self.detail do
      sum = sum + (amplitude/n) *(sin(2 * pi * (frequency*n) * ((frame + phase) / sample_len)))
  end

	return sum 
end

function Oscilator:simple_triangle(frame, sample_len, val)
	local pi = math.pi
	local asin = math.asin
	local sin = math.sin
	local floor = math.floor
	local twopi = 2 * pi
  local amplitude = self.amplitude
  local frequency = self.frequency
  local phase = self.phase
	
  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local n = nil
  local sum = 0
  
  for n=1, self.detail do
    local freq = floor(sample_len / (frequency * n))
    sum = sum + (2*(amplitude/n)/pi) * (asin(sin((twopi / freq) * (frame + phase))))
  end

	return sum --(2 * amplitude / pi) * sum --asin(sin((twopi / freq) * (frame + phase)))
end


function Oscilator:simple_saw(frame, sample_len, val)
  local pi = math.pi
  local tan = math.tan
  local atan = math.atan
  local floor = math.floor
  local frequency = self.frequency
  local amplitude = self.amplitude
  local phase = self.phase

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local n = nil
  local sum = 0
  
  for n=1, self.detail do
    local temp = (pi*(frame + phase)) / floor(sample_len / (frequency*n))
    sum = sum + (-(2 * (amplitude/n)) / pi) * (atan(1 / tan(temp)))
  end

  
  return sum --(-(2 * amplitude) / pi) * sum --atan(1 / tan(temp))
end


function Oscilator:simple_square(frame, sample_len, val)
  local pi = math.pi
	local sin = math.sin
  local frequency = self.frequency
  local amplitude = self.amplitude
  local phase = self.phase

	local function sgn(x)
  		return x > 0 and 1 or (x == 0 and 0 or -1)
	end

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local n = nil
  local sum = 0
  for n=1, self.detail do
    sum = sum + (amplitude/n) * sgn(sin(2 * pi * (frame + phase) / (sample_len / (frequency*n))))
  end

	return sum --amplitude * sum --sgn(sin(2 * pi * (frame + phase) / (sample_len / frequency)))
end


function Oscilator:additive_saw(frame, sample_len, val)
  local sin = math.sin
  local pi = math.pi
  local abs = math.abs
  local floor = math.floor
  local tail = 8 / pi^2
  local frequency = self.frequency
  local amplitude = self.amplitude
  local phase = self.phase

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end
  
  local test = floor(sample_len / frequency)

  local g = 0
  for n=1, abs(floor(self.detail)) do
    g = g + (1 ^(n-1)) / n * sin((2 * pi * n * (frame + phase)) / test)
  end

  local h = amplitude * tail * g

  return h
end


function Oscilator:additive_square(frame, sample_len, val)
  local sin = math.sin
  local pi = math.pi
  local abs = math.abs
  local floor = math.floor
  local tail = 4 / pi
  local frequency = self.frequency
  local amplitude = self.amplitude
  local phase = self.phase

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local test = floor(sample_len / frequency)

  local g = 0
  for n=1, abs(floor(self.detail)) do
    local part_1=(2*n-1)
    local part_2=(part_1* 2 * pi * (frame + phase))
    local part_3=(1/part_1)*sin(part_2 / test)
    g = g + part_3 
  end

  local h = amplitude * tail * g

  return h
end


function Oscilator:additive_tan(frame, sample_len, val)
  local sin=math.sin
  local pi = math.pi
  local frequency = self.frequency
  local amplitude = self.amplitude
  local phase = self.phase
  local sum = 0
  local n = nil

  if self.modulate_amp then
    amplitude = amplitude * val
  end
  if self.modulate_freq then
    frequency = frequency * val
  end
  if self.modulate_phase then
    phase = phase * val
  end

  local part3 = sample_len / frequency

  for n=1, self.detail do
    local part1 = (-1)^(n-1)
    local part2 = (2 * n * pi * (frame + phase))
    sum = sum + (part1 * sin(part2/part3))
  end
  return amplitude * sum
end

