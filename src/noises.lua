--[[---------------------------------------------------------------------------
White noise generator
]]-----------------------------------------------------------------------------

Noise = {}   --< noise buffer
BackupNoise = {}

function Regenerate_noise()
  -- I need create some noisy background for now
  -- in future versions this render function will be rewritten
  --print("Noise .. " .. tostring(tmp.SAMPLE_FRAMES))

  if tmp.SAMPLE_NOISE_BOOL then
    if tmp.SAMPLE_NOISE_TYPE == 1 then
      Noise = create_white_noise(tmp.SAMPLE_FRAMES, tmp.SAMPLE_NOISE_AMOUNT)
    elseif tmp.SAMPLE_NOISE_TYPE == 2 then
      Noise = create_pink_noise(tmp.SAMPLE_FRAMES, tmp.SAMPLE_NOISE_AMOUNT)
    elseif tmp.SAMPLE_NOISE_TYPE == 3 then
      Noise = create_brownian_noise(tmp.SAMPLE_FRAMES, tmp.SAMPLE_NOISE_AMOUNT)
    end
    local i=nil
    for i=1, #Noise do
      BackupNoise[i] = Noise[i]
      Noise[i] = Noise[i] * tmp.SAMPLE_NOISE_AMOUNT
    end
  end
end


function customize_noise()
  -- just update values, no new noise
  local i = nil
  for i=1, #Noise do
    Noise[i] = BackupNoise[i] * tmp.SAMPLE_NOISE_AMOUNT
  end
end 


function gaussian_rnd(N)
  -- trochu uhlazenější použití funkce
  -- z knihovny math.random

  local i=nil
  local sum = 0
  local rnd = math.random
  for i=1, N do
    sum = sum + rnd()
  end
  return sum / N
end

--https://noisehack.com/generate-noise-web-audio-api/

function create_white_noise(sample_len, amount)
  -- bílý šum je nejuniverzálnější typ
  -- jsou to jen náhodná data s plochým frekvenčním
  -- spektrem

  local buff = {}
  local i = nil
  
  for i=1, sample_len do
    buff[i] = (gaussian_rnd(def.GAUSSIAN_RND) * 2 - 1)
  end
  
  return buff

end

--[[---------------------------------------------------------------------------
Pink noise generator
]]-----------------------------------------------------------------------------
function create_pink_noise(sample_len, amount)
  local b0, b1, b2, b3, b4, b5, b6 = 0, 0, 0, 0, 0, 0, 0
  local pink = 0
  local buff = {}
  local i = nil
  local rnd = math.random
  for i=1, sample_len do
    local white_noise = (gaussian_rnd(def.GAUSSIAN_RND) * 2 - 1)
    b0 = 0.99886 * b0 + white_noise * 0.0555179
    b1 = 0.99332 * b1 + white_noise * 0.0750759
    b2 = 0.96900 * b2 + white_noise * 0.1538520
    b3 = 0.86650 * b3 + white_noise * 0.3104856
    b4 = 0.55000 * b4 + white_noise * 0.5329522
    b5 = -0.7616 * b5 - white_noise * 0.0168980
    pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white_noise * 0.5362
    b6 = white_noise * 0.115926
    buff[i] = pink * 0.5 --0.11
  end
  return buff
end

--[[---------------------------------------------------------------------------
Brownian Noise
]]-----------------------------------------------------------------------------
function create_brownian_noise(sample_len, amount)
  local rnd = math.random
  local buff = {}
  local i = nil
  local last_val = 0
  for i=1, sample_len do
    local white_noise = (gaussian_rnd(def.GAUSSIAN_RND) * 2 - 1)
    local val = (last_val + (0.02 * white_noise)) / 1.02
    last_val = val
    buff[i] = val * 5.5 --3.5
  end
  return buff
end