--[[============================================================================
operators.lua
============================================================================]]--

function arccosine(real_amplification, real_unused, real_x)
  return real_amplification * (-1 + 2 * math.acos(-1 + 2 * real_x) / PI)
end


--------------------------------------------------------------------------------
  
function arcsine(real_amplification, real_unused, real_x)
  return real_amplification * math.asin(-1 + 2 * real_x) / HALFPI
end


--------------------------------------------------------------------------------

function cosine(real_amplification, real_unused, real_x)
  return real_amplification * math.cos(TWOPI*real_x)
end


--------------------------------------------------------------------------------

function noise(real_amplification, real_unused1, real_unused2)
  return real_amplification - 2 * real_amplification * math.random()
end


--------------------------------------------------------------------------------

function pulse(real_amplification, real_width, real_x)
  if real_x > real_width then 
  return -real_amplification 
  else 
  return real_amplification 
  end
end


--------------------------------------------------------------------------------

function saw(real_amplification, real_unused, real_x)
  return real_amplification*(2*real_x-1)
end


--------------------------------------------------------------------------------

function sine(real_amplification, real_unused, real_x)
  return real_amplification * math.sin(TWOPI*real_x)
end


--------------------------------------------------------------------------------

function square(real_amplification, real_unused, real_x)
  return pulse(real_amplification, 0.5, real_x)
end


--------------------------------------------------------------------------------

function tangent(real_amplification, real_width, real_x)
  return real_amplification * math.tan(PI*real_x)*real_width
end


--------------------------------------------------------------------------------

function triangle(real_amplification, real_unused, real_x)
  if real_x < 0.5 then
    return real_amplification*(-1+2*real_x/0.5)
  else
    return triangle(real_amplification,real_unused,1-real_x)
  end
end


--------------------------------------------------------------------------------

function wave(real_amplification, buffer, real_x)
  local int_chan
  local real_value = 0
  if not buffer or not buffer.has_sample_data then
  return 0
  end
  for int_chan = 1, buffer.number_of_channels do
    real_value = real_value + 
    real_amplification * buffer:sample_data(
      int_chan,
    (buffer.number_of_frames-1)*real_x+1
    )
  end
  real_value = real_value / buffer.number_of_channels
  return real_value  
end


--------------------------------------------------------------------------------

function none(real_unused1, real_unused2, real_unused3)
  return 0
end


--------------------------------------------------------------------------------

function square(real_amplification, real_unused, real_x)
  return pulse(real_amplification, 0.5, real_x)
end


--------------------------------------------------------------------------------

function gauss(real_amplification, real_width, real_x)
  --return exp(-x * x * (exp(a * 8) + 5.0)) * 2.0 - 1.0;
  --return real_amplification * math.sin(TWOPI*real_x)
  local x = real_x * 2 - 1
  local a = (real_width - 0.5) * -1
  renoise.app():show_status(string.format("Amp: %09f", a))
  if a < 0.00001 then
    a = 0.00001
  end
  return real_amplification * (math.exp( (-1*x) * x * (math.exp(a * 8) + 5)) * 2 - 1)
end


--------------------------------------------------------------------------------

function diode(real_amplification, real_width, real_x)
  local a = (real_width - 0.5) * -1
  if a < 0.00001 then
    a = 0.00001
  else
    if a > 0.99999 then
      a = 0.99999
    end
  end
  a = a * 2 - 1
  local x = math.cos((real_x + 0.5) * 2 * PI) - a
  if x < 0 then
    x = 0
  end
  return real_amplification * (x / (1 - a) * 2 - 1)
end


--------------------------------------------------------------------------------

function chirp(real_amplification, real_width, real_x)
  local x = real_x * TWOPI
  local a = real_width * 4
  if a < 0 then
    a = a * 2
  end
  a = a * a * a
  return real_amplification * (math.sin(x/2) * math.sin(a * x * x))
end


--------------------------------------------------------------------------------

function chebyshev(real_amplification, real_width, real_x)
  local a = real_width
  renoise.app():show_status(string.format("A: %9f", a))
  a = a * a * a * 30 + 1
  return real_amplification * (math.cos(math.acos(real_x * 2 - 1) * a))
end


--------------------------------------------------------------------------------
