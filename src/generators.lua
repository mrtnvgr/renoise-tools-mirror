---@diagnostic disable: lowercase-global, deprecated

local sin = math.sin
local sinh = math.sinh
local cos = math.cos
local abs = math.abs
local tanh = math.tanh
local pi = math.pi
local floor = math.floor
local rnd = math.random


function morph_harmonic_values()
	math.randomseed(os.clock())
	RENDER_ENABLED = false
	local value = 0
	local x = rnd()
	local amount = vbs.morph_amount.value
	
	for i=vbs.from_harmonies.value, vbs.to_harmonies.value do
		local sign = rnd(10)
		if sign > 5 then
			amount = abs(amount)
		else
			amount = -amount
		end
		value = vbs["Harmony"..i].value + amount
		if value > 1 then
			value = 1
		elseif value < -1 then
			value = -1
		end
		vbs["Harmony" .. i].value = value
        HARMONIC_SERIES[i] = value
        if vbs["Harmony"..i].value > 0 or vbs["Harmony"..i].value < 0 then
            vbs["Harmony_btn"..i].color = {0,math.abs(math.floor(255 * value)),0}
        else
            vbs["Harmony_btn"..i].color = {0,0,0}
        end
	end

	RENDER_ENABLED = true
	draw_sample()
end


function int(value)
    -- vrací celé číslo

    local f = math.floor(value)
    if value == f or value % 2 == 0.5 then
        return f
    else
        return math.floor(value + 0.5)
    end
end


function iterpolate(x, y, z)
	return (z - x) / (y - x)
end


function sine(nr_samples)
	local buffer = {}
	for i=1, nr_samples do
		buffer[i] = sin(i * pi / nr_samples * 2)
	end
	return buffer
end


function saw(nr_samples)
	local buffer = {}
	for i=1, nr_samples do
		buffer[i] = (i / nr_samples) * 2 - 1
	end
	return buffer
end


function square(nr_samples)
	local buffer = {}
	for i=1, nr_samples do
		if i < nr_samples / 2 then
			buffer[i] = 1
		else
			buffer[i] = -1
		end
	end
	return buffer
end


function triangle2(nr_samples)
	local buffer = {}
	local section = floor(nr_samples / 4)
	local pos = 0
	for i=1, section do
		pos = pos + 1
		buffer[pos] = i / section
	end
	for i=1,  section * 2 do
		pos = pos + 1
		buffer[pos] = 1 - (i / section)
	end
	for i=1,  section  do
		pos = pos + 1
		buffer[pos] = -1 + (i / section)
	end

	return buffer
end


function triangle(nr_samples)
	local buffer = {}
	local half = floor(nr_samples / 2)
	for i=1, half do
		buffer[i] = -1 + 2 * i / half
	end
	for i=half, nr_samples do
		buffer[i] = 1 - 2 * ((i - half) / half)
	end
	return buffer
end


function white_noise(nr_samples)
	local buffer = {}
	for i=1, nr_samples do
		buffer[i] = -1 + 2 * rnd()
	end
	return buffer
end


function wave_calc(samples)
	local buffer = {}
	for i=1, #samples do
		local normalize, out = 0, 0
		for j=1, 256 do
			local pos = out + samples[((i * j - 1) % #samples) + 1] * HARMONIC_SERIES[j]
			out = pos
			normalize = normalize + abs(HARMONIC_SERIES[j])
		end
		buffer[i] = out / normalize
	end
	return buffer
end

function Saturator(samples, typ, amount)
	local buffer = {}
  	local ms = 0
  	for i=1, #samples do
    	if typ == 2 then
      		buffer[i] = sin(samples[i] * amount * 20)
		elseif typ == 3 then
			local z = pi * amount
			local s = 1.0 / sin(z)
			local b = 1.0 / amount

			if samples[i] > b then
				samples[i] = 1
			else
				samples[i] = sin(z * samples[i]) * s
			end
    	
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
		end
      	local m1 = 1.0 - amount
      	buffer[i] = ms + tanh((samples[i] - ms) / m1) * m1
    end
	return buffer
end

function FormantFilter(buffer, vowelnum)
	local coeff = {}
	local memory = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	local buff = {}
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