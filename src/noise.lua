---@diagnostic disable: lowercase-global, undefined-global

local smooth_value = 4        -- value for smooth gaussian noise


function lerp(t, a, b)
    return a + t * (b - a)
end


function scurve(t)
    return t * t * (3 - 2 * t)
end


function gaussian_rnd(N)
    local sum = 0
    for i=1, N do
      sum = sum + math.random()
    end
    return sum / N
end


function create_white_noise(sample_len, ampl)
    local ampl = ampl or 1
    math.randomseed(os.time())
    local buff = {}
    for i=1, sample_len do
      local val = gaussian_rnd(smooth_value) * 2 - 1
      buff[i] = val * ampl
    end

    for i=2, #buff - 1 do
      -- smooth
      buff[i] = (buff[i-1] + buff[i + 1]) / 2
    end
    return buff
end


function B_white_noise(sampl, prob)
  local samples = sampl
	local buffer = {}
	for i=1, samples do
		if bernouli(prob) == 1 then
			buffer[i] = -1 + 2 * math.random()
		else
			buffer[i] = 0
		end
	end
	return buffer
end


function create_pink_noise(sample_len, ampl)
    local ampl = ampl or 1
    local b0, b1, b2, b3, b4, b5, b6 = 0, 0, 0, 0, 0, 0, 0
    local pink = 0
    local buff = {}
    for i=1, sample_len do
      local white_noise = (gaussian_rnd(smooth_value) * 2 - 1) * ampl
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


function create_brownian_noise(sample_len, ampl)
    local ampl = ampl or 1
    local buff = {}
    local last_val = 0
    for i=1, sample_len do
      local white_noise = (gaussian_rnd(smooth_value) * 2 - 1) * ampl
      local val = (last_val + (0.02 * white_noise)) / 1.02
      last_val = val
      buff[i] = val * 3.5
    end
    return buff
end