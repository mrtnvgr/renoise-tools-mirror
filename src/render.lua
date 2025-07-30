---@diagnostic disable: undefined-global, lowercase-global, redundant-parameter, deprecated, param-type-mismatch

local random = math.random
local floor = math.floor
local sqrt = math.sqrt
local cos = math.cos
local pi = math.pi


function bernouli(p)
	if random() >= p then
		return 0
	else
		return 1
	end
end


function binomial(n, p)
	local number, probability, va = n or 1, p or 0.5, 0
	for i=1, number do
		va = va + bernouli(probability)
	end
	return floor(va / n)
end


function fill(len, number)
	local buffer = {}
	for i=1, len do
		buffer[i]=number
	end
	return buffer
end


function map_value(value, a, b, c, d)
	return (value - a) / (b - a) * (d - c) + c
end


----------------------------------------------------------------------------------------------------------------
-- KICK DRUM GENERATOR                                                                                         -
----------------------------------------------------------------------------------------------------------------

function kick_drum(duration)
	local samples = duration * SAMPLERATE
	local buffer = {}
	local sel = vbs.kick_wave_selector.value
	local freq = vbs.kick_periods_slider.value

	if sel == 1 then
		for i=1, samples do
			buffer[i] = i / samples
			buffer[i] = sqrt(buffer[i]) * 20 - 0.25
			buffer[i] = buffer[i] * freq * pi
			buffer[i] = cos(buffer[i])
		end

	elseif sel == 2 then --saw
		buffer = MakeOSC(freq * 20, duration, 1, SAMPLERATE, SawWave)

	elseif sel == 3 then -- pulse
		local pulse_len = vbs.kick_pulse_len_slider.value
		buffer = MakeOSC(freq * 20, duration, 1, SAMPLERATE, PulseWave, 0, pulse_len)

	end
	
	-- make filter here
	local filter_type =  vbs.kick_filter_selector.value
	local Q = vbs.kick_filter_Q_slider.value
	if filter_type < #FILTERS then
		buffer = Filter(buffer, filter_type, vbs.kick_filter_slider.value, Q)
	end
	return buffer
end

----------------------------------------------------------------------------------------------------------------
-- SNARE DRUM GENERATOR                                                                                        -
----------------------------------------------------------------------------------------------------------------

function snare_drum(duration)
	
	local function get_noise(samples)
		-- make some noise
		local noise
		if vbs.snare_noise_select.value == 1 then
			noise = create_white_noise(samples)
		elseif vbs.snare_noise_select.value == 2 then
			noise = create_pink_noise(samples)
		elseif vbs.snare_noise_select.value == 3 then
			noise = create_brownian_noise(samples)
		else
			noise = cubic_noise(samples, 1, 1)
		end
		
		-- highpass filter
		local hQ = vbs.snare_highpass_Q_slider.value
		noise = Filter(noise, 2, vbs.snare_highpass_slider.value, hQ)

		-- bandpass filter
		local bQ = vbs.snare_bandpass_Q_slider.value
		noise = Filter(noise, 3, vbs.snare_bandpass_slider.value, bQ)
		return noise
	end

	local function create_envelope(samples)
		local buff = ramp_generator(1, 0, samples)
		local noiz = get_noise(samples)
		for i1=1, samples do
			buff[i1] = buff[i1] ^ 4
			buff[i1] = buff[i1] * noiz[i1] * vbs.snare_noise_volume_slider.value
		end
		return buff
	end

	local samples = duration * SAMPLERATE
	local buffer = {}
	local osc = sine_generator(vbs.snare_osc_frequency_slider.value, samples, vbs.snare_osc_volume_slider.value)

	local noi = create_envelope(samples)
	for i=1, samples do
		buffer[i] = 1 - (i / samples)
		buffer[i] = buffer[i] ^ 4
		buffer[i] = buffer[i] * osc[i]
		buffer[i] = (buffer[i] + noi[i]) / 2
	end

	-- lowpass filter
	local lQ = vbs.snare_lowpass_Q_slider.value
	buffer = Filter(buffer, 1, vbs.snare_lowpass_slider.value, lQ)
	return buffer
end


------------------------------------------------------------------------------------------------------------
-- HIHAT GENERATOR                                                                                         -
------------------------------------------------------------------------------------------------------------

function hihat(duration)
	local samples = duration * SAMPLERATE
	local env = ramp_generator(1, 0, samples)
	for i=1, #env do
		env[i] = env[i] ^ 4
	end

	-- make two phasors
	local phasor = sine_generator(vbs.hihat1_phasor1_freq_slider.value, samples, 1)
	local phasor1 = sine_generator(vbs.hihat1_phasor2_freq_slider.value, samples, 1)
	for i=1, #phasor do
		phasor[i] = ((phasor[i] + phasor1[i]) / 2) * vbs.hihat1_phasors_volume_slider.value
	end

	-- make some noise
	local noise
	local ntype = vbs.hihat1_noise_select.value
	if ntype == 1 then
		noise = create_white_noise(samples)
	elseif ntype == 2 then
		noise = create_pink_noise(samples)
	else
		noise = create_brownian_noise(samples)
	end

	for i=1, #phasor do
		phasor[i] = phasor[i] + (noise[i] * vbs.hihat1_noisemix_slider.value)
	end

	-- 3x HighPass filter
	local f1Q = vbs.hihat1_filter1_Q_slider.value
	local f2Q = vbs.hihat1_filter2_Q_slider.value
	local f3Q = vbs.hihat1_filter3_Q_slider.value
	phasor = Filter(phasor, 2, vbs.hihat1_filter1_slider.value, f1Q)
	phasor = Filter(phasor, 2, vbs.hihat1_filter2_slider.value, f2Q)
	phasor = Filter(phasor, 2, vbs.hihat1_filter3_slider.value, f3Q)
	for i=1, #phasor do
		phasor[i] = phasor[i] * env[i]
	end
	return phasor
end


-----------------------------------------------------------------------------------------------------------
-- HIHAT USING OSC                                                                                        -
-----------------------------------------------------------------------------------------------------------

function hihat2(duration)
	local samples = duration * SAMPLERATE
	local env = ramp_generator(1, 0, samples)
	for i=1, #env do
		env[i] = env[i] ^ 4
	end
	local f = vbs.hihat2_freq_slider.value
	local phasor = MakeOSC(f * 2, duration, 1, SAMPLERATE, PulseWave)
	local phasor1 = MakeOSC(f * 3, duration, 1, SAMPLERATE, SquareWave)
	local phasor2 = MakeOSC(f * 4.16, duration, 1, SAMPLERATE, SquareWave)
	local phasor3 = MakeOSC(f * 5.43, duration, 1, SAMPLERATE, SquareWave)
	local phasor4 = MakeOSC(f * 6.79, duration, 1, SAMPLERATE, SquareWave)
	local phasor5 = MakeOSC(f * 8.12, duration, 1, SAMPLERATE, SquareWave)
	
	for i=1, #phasor do
		phasor[i] = (phasor[i] + phasor1[i] + phasor2[i] + phasor3[i] + phasor4[i] + phasor5[i]) / 6 * env[i]
	end

	phasor = Filter(phasor, 3, 10000, vbs.hihat2_f1_Q_slider.value)
	phasor = Filter(phasor, 2, 7000, vbs.hihat2_f2_Q_slider.value)
	phasor = Filter(phasor, 2, 7000, vbs.hihat2_f3_Q_slider.value)
	phasor = Filter(phasor, 2, 7000, vbs.hihat2_f4_Q_slider.value)
	
	for i=1, #phasor do
		phasor[i] = phasor[i] * env[i]
	end

	return phasor
end


---------------------------------------------------------------------------------------------------------------
-- CYMBAL                                                                                                     -
---------------------------------------------------------------------------------------------------------------

function cymbal(duration)
	local length = duration * SAMPLERATE
	local freq = vbs.cymbal_frequency_slider.value
	local noise = create_white_noise(length)
	local osc1 = MakeOSC(freq, duration, 1, SAMPLERATE, SquareWave, 0)
	local osc2 = MakeOSC(freq * 1.342, duration, 1, SAMPLERATE, SquareWave, 0)
	local osc3 = MakeOSC(freq * 1.2112, duration, 1, SAMPLERATE, SquareWave, 0)
	local osc4 = MakeOSC(freq * 1.6532, duration, 1, SAMPLERATE, SquareWave, 0)
	local osc5 = MakeOSC(freq * 1.9523, duration, 1, SAMPLERATE, SquareWave, 0)
	local osc6 = MakeOSC(freq * 2.1523, duration, 1, SAMPLERATE, SquareWave, 0)

	for i=1, length do
		local level = (noise[i] * vbs.cymbal_noise_volume_slider.value)
		noise[i] = ((level + osc1[i] + osc2[i] + osc3[i] + osc4[i] + osc5[i] + osc6[i]) / 7) * vbs.cymbal_volume_slider.value
	end

	noise = Filter(noise, 1, vbs.cymbal_filter1_slider.value, 0.6)
	noise = Filter(noise, 2, vbs.cymbal_filter2_slider.value, 1.5)
	noise = Filter(noise, 2, vbs.cymbal_filter3_slider.value, 1.5)
	noise = Filter(noise, 2, vbs.cymbal_filter4_slider.value, 1.5)

	noise = SimpleCombFilter(noise, vbs.cymbal_delay_slider.value, vbs.cymbal_attenuation_slider.value)
	return noise
end


---------------------------------------------------------------------------------------------------------------
-- CLAPS USING 6 noises and 6 envelopes                                                                     -
---------------------------------------------------------------------------------------------------------------

function claps(duration)
	
	local length = duration * SAMPLERATE
	local delay = vbs.claps_delay_slider.value
	local env = {}
	local attack_time = vbs.claps_attack_time_slider.value
	local decay_time = vbs.claps_decay_time_slider.value
	local attack_shape = vbs.claps_attack_shape_slider.value
	local decay_shape = vbs.claps_decay_shape_slider.value
	local total = vbs.claps_duration_slider.value

	env[1] = DADenvelope(total, 0.0, attack_time, decay_time, attack_shape, decay_shape)
	env[2] = DADenvelope(total, delay, attack_time, decay_time, attack_shape, decay_shape)
	env[3] = DADenvelope(total, delay * 2.4, attack_time, decay_time, attack_shape, decay_shape)
	env[4] = DADenvelope(total, delay * 3.6, attack_time, decay_time, attack_shape, decay_shape)
	env[5] = DADenvelope(total, delay * 4.8, attack_time, decay_time, attack_shape, decay_shape)
	env[6] = DADenvelope(total, delay * 6.0, attack_time, decay_time, attack_shape, decay_shape)
	
	local noise = {}
	for i=1, 6 do
		noise[i] = B_white_noise(length, vbs.claps_noise_amount_slider.value)
		for j=1, length do
			noise[i][j] = noise[i][j] * env[i][j]
		end
	end

	local temp = {}
	local temp2 = {}
	for i=1, length do
		temp[i] = (noise[1][i] + noise[2][i] + noise[3][i] + noise[4][i] + noise[5][i] + noise[6][i])
	end

	temp2 = Filter(temp, 1, vbs.claps_filter_freq_slider.value, vbs.claps_filter_Q_slider.value)
	
	for i=1, #temp do
		temp[i] = temp[i] - temp2[i]
	end

	return temp
end

---------------------------------------------------------------------------------------------------------------
-- DRUM BASED ON KARPLUS-STRONG ALGORITHM                                                                     -
---------------------------------------------------------------------------------------------------------------

function karplus_strong_drum(len)
	local n_samples = len * SAMPLERATE
	local samples = {}
	local current_sample = 1
	local previous_value = 1
	
	local wavetable
	local select = vbs.karplus_noise_select.value
	local wav_len = vbs.karplus_wavelen_slider.value

	if select == 1 then
		wavetable = create_white_noise(wav_len)
	elseif select == 2 then
		wavetable = create_pink_noise(wav_len)
	elseif select == 3 then
		wavetable = create_brownian_noise(wav_len)
	elseif select == 4 then
		wavetable = sine_generator(1000, wav_len, 1)
	elseif select == 5 then
		wavetable = MakeOSC(1000, len, 1, SAMPLERATE, SawWave)
	end

	while #samples < n_samples do
		local r = binomial(1, 1 - 1 / vbs.karplus_stretch_slider.value)
		if r == 0 then
			wavetable[current_sample] = 0.5 * (wavetable[current_sample] + previous_value)
		end
		samples[#samples + 1] = wavetable[current_sample]
		previous_value = samples[#samples]
		current_sample = current_sample + 1
		current_sample = (current_sample % #wavetable) + 1
	end

	local fltr1 = vbs.karplus_filter1_selector.value
	local fltr1_freq = vbs.karplus_filter1_freq_slider.value
	local f1Q = vbs.karplus_filter1_Q_slider.value
	local fltr2 = vbs.karplus_filter2_selector.value
	local fltr2_freq = vbs.karplus_filter2_freq_slider.value
	local f2Q = vbs.karplus_filter2_Q_slider.value
	local fltr3 = vbs.karplus_filter3_selector.value
	local fltr3_freq = vbs.karplus_filter3_freq_slider.value
	local f3Q = vbs.karplus_filter3_Q_slider.value
	
	if fltr1 < #FILTERS then
		samples = Filter(samples, fltr1, fltr1_freq, f1Q)
	end
	
	if fltr2 < #FILTERS then
		samples = Filter(samples, fltr2, fltr2_freq, f2Q)
	end
	
	if fltr3 < #FILTERS then
		samples = Filter(samples, fltr3, fltr3_freq, f3Q)
	end

	return samples
end


-------------------------------------------------------------------------------------------------------------
-- GLOCKENSPIEL                                                                                             -
-------------------------------------------------------------------------------------------------------------

function glockenspiel(duration)
	local length = duration * SAMPLERATE
	local freq = vbs.glocken_frequency_slider.value

	local cycle = {}
	local oscs = floor(vbs.glocken_osc_selector_slider.value)
	for i=1, oscs do
		cycle[i] = sine_generator(freq * sqrt(i) * 2, length, 1)
	end

	local env_attack = vbs.glocken_env_attack_slider.value
	local env_decay = vbs.glocken_env_decay_slider.value
	local env = DADenvelope(duration, 0, env_attack, env_decay)
	local buffer = {}
	for i=1, length do
		local sum = 0
		for j=1, #cycle do
			sum = sum + cycle[j][i]
		end
		buffer[i] = (sum / #cycle) * env[i]
	end
	local delay = floor(vbs.glocken_delay_slider.value)
	local decay = vbs.glocken_decay_slider.value

	buffer = SchroederReverb(buffer, delay, decay, vbs.glocken_drywet_slider.value)

	local scaler = vbs.glocken_scaler_slider.value
	local tremolo = vbs.glocken_tremolo_slider.value
	local wave = vbs.glocken_wave_selector.value
	local freq2 = vbs.glocken_carrier_freq_slider.value
	local filter = vbs.glocken_filter_selector.value
	buffer = RingModulator(buffer, scaler, tremolo, wave, freq2)
	if filter < #FILTERS then
		buffer = Filter(buffer, filter, vbs.glocken_filter_frequency_slider.value, vbs.glocken_filter_Q_slider.value, 1, 1)
	end
	return buffer
end


-------------------------------------------------------------------------------------------------------------
-- GLITCHER                                                                                                 -
-------------------------------------------------------------------------------------------------------------

function glitcher()

	RENDER_SAMPLE = false

	local nr_glitches = floor(vbs.glitch_nr_slider.value)
	local glitch_max_dur = vbs.glitch_max_slider.value * 1000
	local buffer = {}
	local mem1 = 0
	--local buff_len = {}

	for i=1, nr_glitches do
		math.randomseed(os.clock() * 100000000000)
		local rand = floor(math.random(100, 800) / 100)
		local rand2 = math.random(10, glitch_max_dur) * 0.001

		while rand == mem1 do
			rand = floor(math.random(100, 800) / 100)
		end

		mem1 = rand
		local data = randomize_selected_sample(rand, rand2, true)

		if vbs.glitch_normalize_selector.value == 2 then
			local maxval = -99999
			for g=1, #data do
				if math.abs(data[g]) > maxval then maxval = math.abs(data[g]) end
			end
			for g=1, #data do
				data[g] = data[g] / maxval
			end
		end

		-- cast random envelope from easing on the sample
		if vbs.glitch_env_all.value == true then
			math.randomseed(os.clock())
			math.random(); math.random(); math.random()
			local fn = math.random(1, 42)
			for j=1, #data do	
				if fn < 34 then
					data[j] = (data[j] * EASEFN[fn](1 - j / #data, 0, 1, 1))
				elseif fn == 34 or fn == 35 or fn == 36 or fn == 37 then
					data[j] = (data[j] * EASEFN[fn](1 - j / #data, 0, 1, 1, math.random(10, 200) * 0.01, math.random()))
				elseif fn == 42 then
					data[j] = data[j]
				else
					data[j] = (data[j] * EASEFN[fn](1 - j / #data, 0, 1, 1, math.random(10, 200) * 0.01))
				end
			end
		end

		local rev = math.random()
		if rev < vbs.glitch_revsample_slider.value then
			for j=1, #data do
				buffer[#buffer + 1] = data[#data + 1 - j]
			end
		else
			for j=1, #data do
				buffer[#buffer + 1] = data[j]
			end
		end

		-- Sample overlaping
		--local sample_overlap = vbs.glitch_sample_overlap_slider.value
		--if sample_overlap > 0.0 and i > 1 then
		--	local overlap_area = buff_len[i - 1] - (buff_len[i - 1] * sample_overlap)
		--end
		--print("Pos: ", i, " Drum: ", rand, " Time: ", rand2, "Buffer: ", #buffer, " Check: ", #buffer / SAMPLERATE)
		--buff_len[i] = #data
	end

	local noise_type = vbs.glitch_noise_selector.value
	local intensity = vbs.glitch_noise_overlap_slider.value
	if noise_type > 1 then
		local noise
		if noise_type == 2 then -- dust
			noise = B_white_noise(#buffer, intensity)
		elseif noise_type == 3 then --white
			noise = create_white_noise(#buffer, intensity)
		elseif noise_type == 4 then --pink
			noise = create_pink_noise(#buffer, intensity)
		elseif noise_type == 5 then --brownian
			noise = create_white_noise(#buffer, intensity)
		end

		for i=1, #buffer do
			buffer[i] = (buffer[i] + noise[i]) / 2
		end
	end

	RENDER_SAMPLE = true
	return buffer
end

-----------------------------------------------------------------------------------------------------
-- MORPH SELECTED SAMPLE                                                                            -
-----------------------------------------------------------------------------------------------------

function morph_selected_sample(sel)

	-- do not render until all is finished
	RENDER_SAMPLE = false

	if sel == 1 then
		--vbs.kick_duration_slider.value = 
		--vbs.kick_periods_slider.value = RndAmt(vbs.kick_periods_slider)
		--vbs.kick_wave_selector.value = RndAmt()
		vbs.kick_pulse_len_slider.value = RndAmt(vbs.kick_pulse_len_slider)
		--vbs.kick_filter_selector.value = RndAmt(
		vbs.kick_filter_slider.value = RndAmt(vbs.kick_filter_slider)
		vbs.kick_filter_Q_slider.value = RndAmt(vbs.kick_filter_Q_slider)

	elseif sel == 2 then
		--vbs.snare_duration_slider.value = rnd(1, 200) * 0.01
		--vbs.snare_noise_select.value = RndAmt(
		vbs.snare_noise_volume_slider.value = RndAmt(vbs.snare_noise_volume_slider)
		vbs.snare_osc_frequency_slider.value = RndAmt(vbs.snare_osc_frequency_slider)
		vbs.snare_osc_volume_slider.value = RndAmt(vbs.snare_osc_volume_slider)
		vbs.snare_highpass_slider.value = RndAmt(vbs.snare_highpass_slider)
		vbs.snare_highpass_Q_slider.value = RndAmt(vbs.snare_highpass_Q_slider)
		vbs.snare_bandpass_slider.value = RndAmt(vbs.snare_bandpass_slider)
		vbs.snare_bandpass_Q_slider.value = RndAmt(vbs.snare_bandpass_Q_slider)
		vbs.snare_lowpass_slider.value = RndAmt(vbs.snare_lowpass_slider)
		vbs.snare_lowpass_Q_slider.value = RndAmt(vbs.snare_lowpass_Q_slider)

	elseif sel == 3 then
		if vbs.hihat_type_switch.value == 1 then
			--vbs.hihat1_duration_slider.value = rnd(1, 200) * 0.01
			--vbs.hihat1_noise_select.value = rnd(3)
			vbs.hihat1_noisemix_slider.value = RndAmt(vbs.hihat1_noisemix_slider)
			vbs.hihat1_phasor1_freq_slider.value = RndAmt(vbs.hihat1_phasor1_freq_slider)
			vbs.hihat1_phasor2_freq_slider.value = RndAmt(vbs.hihat1_phasor2_freq_slider)
			vbs.hihat1_phasors_volume_slider.value = RndAmt(vbs.hihat1_phasors_volume_slider)
			vbs.hihat1_filter1_slider.value = RndAmt(vbs.hihat1_filter1_slider)
			vbs.hihat1_filter1_Q_slider.value = RndAmt(vbs.hihat1_filter1_Q_slider)
			vbs.hihat1_filter2_slider.value = RndAmt(vbs.hihat1_filter2_slider)
			vbs.hihat1_filter2_Q_slider.value = RndAmt(vbs.hihat1_filter2_Q_slider)
			vbs.hihat1_filter3_slider.value = RndAmt(vbs.hihat1_filter3_slider)
			vbs.hihat1_filter3_Q_slider.value = RndAmt(vbs.hihat1_filter3_Q_slider)
		else
			--vbs.hihat2_duration_slider.value = rnd(1, 200) * 0.01
			--vbs.hihat2_freq_slider.value = RndAmt(vbs.hihat2_freq_slider)
			vbs.hihat2_f1_Q_slider.value = RndAmt(vbs.hihat2_f1_Q_slider)
			vbs.hihat2_f2_Q_slider.value = RndAmt(vbs.hihat2_f2_Q_slider)
			vbs.hihat2_f3_Q_slider.value = RndAmt(vbs.hihat2_f3_Q_slider)
			vbs.hihat2_f4_Q_slider.value = RndAmt(vbs.hihat2_f4_Q_slider)
		end

	elseif sel == 4 then
		--vbs.cymbal_duration_slider.value = rnd(1, 200) * 0.01
		--vbs.cymbal_frequency_slider.value = RndAmt(vbs.cymbal_frequency_slider)
		vbs.cymbal_volume_slider.value = RndAmt(vbs.cymbal_volume_slider)
		vbs.cymbal_noise_volume_slider.value = RndAmt(vbs.cymbal_noise_volume_slider)
		vbs.cymbal_filter1_slider.value = RndAmt(vbs.cymbal_filter1_slider)
		vbs.cymbal_filter2_slider.value = RndAmt(vbs.cymbal_filter2_slider)
		vbs.cymbal_filter3_slider.value = RndAmt(vbs.cymbal_filter3_slider)
		vbs.cymbal_filter4_slider.value = RndAmt(vbs.cymbal_filter4_slider)
		vbs.cymbal_delay_slider.value = RndAmt(vbs.cymbal_delay_slider)
		vbs.cymbal_attenuation_slider.value = RndAmt(vbs.cymbal_attenuation_slider)

	elseif sel == 5 then
		--vbs.claps_duration_slider.value = rnd(1, 200) * 0.01
		vbs.claps_noise_amount_slider.value = RndAmt(vbs.claps_noise_amount_slider)
		vbs.claps_filter_freq_slider.value = RndAmt(vbs.claps_filter_freq_slider)
		vbs.claps_filter_Q_slider.value = RndAmt(vbs.claps_filter_Q_slider)
		vbs.claps_delay_slider.value = RndAmt(vbs.claps_delay_slider)
		vbs.claps_attack_time_slider.value = RndAmt(vbs.claps_attack_time_slider)
		vbs.claps_decay_time_slider.value = RndAmt(vbs.claps_decay_time_slider)
		vbs.claps_attack_shape_slider.value = RndAmt(vbs.claps_attack_shape_slider)
		vbs.claps_decay_shape_slider.value = RndAmt(vbs.claps_decay_shape_slider)

	elseif sel == 6 then
		--vbs.karplus_duration_slider.value = rnd(1, 200) * 0.01
		--vbs.karplus_noise_select.value = RndAmt(vbs.karplus_noise_select)
		vbs.karplus_stretch_slider.value = RndAmt(vbs.karplus_stretch_slider)
		vbs.karplus_wavelen_slider.value = RndAmt(vbs.karplus_wavelen_slider)
		--vbs.karplus_filter1_selector.value = rnd(9)
		vbs.karplus_filter1_freq_slider.value = RndAmt(vbs.karplus_filter1_freq_slider)
		vbs.karplus_filter1_Q_slider.value = RndAmt(vbs.karplus_filter1_Q_slider)
		--vbs.karplus_filter2_selector.value = rnd(9)
		vbs.karplus_filter2_freq_slider.value = RndAmt(vbs.karplus_filter2_freq_slider)
		vbs.karplus_filter2_Q_slider.value = RndAmt(vbs.karplus_filter2_Q_slider)
		--vbs.karplus_filter3_selector.value = rnd(9)
		vbs.karplus_filter3_freq_slider.value = RndAmt(vbs.karplus_filter3_freq_slider)
		vbs.karplus_filter3_Q_slider.value = RndAmt(vbs.karplus_filter3_Q_slider)

	elseif sel == 7 then
		--vbs.glocken_duration_slider.value = rnd(200) * 0.01
		--vbs.glocken_frequency_slider.value = RndAmt(vbs.glocken_frequency_slider)
		vbs.glocken_delay_slider.value = RndAmt(vbs.glocken_delay_slider)
		vbs.glocken_decay_slider.value = RndAmt(vbs.glocken_decay_slider)
		vbs.glocken_scaler_slider.value = RndAmt(vbs.glocken_scaler_slider)
		vbs.glocken_tremolo_slider.value = RndAmt(vbs.glocken_tremolo_slider)
		--vbs.glocken_wave_selector.value = RndAmt(vbs.glocken_wave_slider)
		vbs.glocken_carrier_freq_slider.value = RndAmt(vbs.glocken_carrier_freq_slider)
		vbs.glocken_drywet_slider.value = RndAmt(vbs.glocken_drywet_slider)

	end

	RENDER_SAMPLE = true
	render_sample()
end


-----------------------------------------------------------------------------------------------------
-- RANDOMIZE SELECTED SAMPLE                                                                        -
-----------------------------------------------------------------------------------------------------

function randomize_selected_sample(sel, amount, g)

	-- do not render sample until finish
	RENDER_SAMPLE = false
	math.randomseed(os.clock())
	local rnd = math.random
	local amt = amount or 0
	local glitch = g or false

	if sel == 1 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.kick_duration_slider.value = amount
		end
		vbs.kick_periods_slider.value = rnd(9)
		vbs.kick_wave_selector.value = rnd(3)
		vbs.kick_pulse_len_slider.value = rnd(99) * 0.01
		vbs.kick_filter_selector.value = rnd(8)   -- always filter
		vbs.kick_filter_slider.value = rnd(100, 6000)
		vbs.kick_filter_Q_slider.value = rnd(2000) * 0.01
		if glitch then
			return kick_drum(amount)
		end

	elseif sel == 2 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.snare_duration_slider.value = amount --rnd(1, 200) * 0.01
		end
		vbs.snare_noise_select.value = rnd(1, 3)
		vbs.snare_noise_volume_slider.value = rnd(500) * 0.01
		vbs.snare_osc_frequency_slider.value = rnd(200, 4000) * 0.1
		vbs.snare_osc_volume_slider.value = rnd(100) * 0.01
		vbs.snare_highpass_slider.value = rnd(100, 100000) * 0.1
		vbs.snare_highpass_Q_slider.value = rnd(200) * 0.1
		vbs.snare_bandpass_slider.value = rnd(100, 100000) * 0.1
		vbs.snare_bandpass_Q_slider.value = rnd(200) * 0.1
		vbs.snare_lowpass_slider.value = rnd(100, 100000) * 0.1
		vbs.snare_lowpass_Q_slider.value = rnd(200) * 0.1
		if glitch then
			return snare_drum(amount)
		end

	elseif sel == 3 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()

		if glitch then
			vbs.hihat_type_switch.value = rnd(2)
		end

		if vbs.hihat_type_switch.value == 1 then
			if amt > 0 then
				vbs.hihat1_duration_slider.value = amount --rnd(1, 200) * 0.01
			end
			vbs.hihat1_noise_select.value = rnd(3)
			vbs.hihat1_noisemix_slider.value = rnd(1, 20) * 0.1
			vbs.hihat1_phasor1_freq_slider.value = rnd(10, 20000) * 0.1
			vbs.hihat1_phasor2_freq_slider.value = rnd(10, 20000) * 0.1
			vbs.hihat1_phasors_volume_slider.value = rnd(200) * 0.01
			vbs.hihat1_filter1_slider.value = rnd(10, 10000)
			vbs.hihat1_filter1_Q_slider.value = rnd(200) * 0.1
			vbs.hihat1_filter2_slider.value = rnd(10, 10000)
			vbs.hihat1_filter2_Q_slider.value = rnd(200) * 0.1
			vbs.hihat1_filter3_slider.value = rnd(10, 10000)
			vbs.hihat1_filter3_Q_slider.value = rnd(200) * 0.1
			if glitch then
				return hihat(amount)
			end
		else
			if amt > 0 then
				vbs.hihat2_duration_slider.value = amount --rnd(1, 200) * 0.01
			end
			vbs.hihat2_freq_slider.value = rnd(200000) * 0.01
			vbs.hihat2_f1_Q_slider.value = rnd(200) * 0.1
			vbs.hihat2_f2_Q_slider.value = rnd(200) * 0.1
			vbs.hihat2_f3_Q_slider.value = rnd(200) * 0.1
			vbs.hihat2_f4_Q_slider.value = rnd(200) * 0.1
			if glitch then
				return hihat2(amount)
			end
		end

	elseif sel == 4 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.cymbal_duration_slider.value = amount --rnd(1, 200) * 0.01
		end
		vbs.cymbal_frequency_slider.value = rnd(10, 2000)
		vbs.cymbal_volume_slider.value = rnd(1, 50) * 0.1
		vbs.cymbal_noise_volume_slider.value = rnd(50) * 0.1
		vbs.cymbal_filter1_slider.value = rnd(100, 10000)
		vbs.cymbal_filter2_slider.value = rnd(100, 10000)
		vbs.cymbal_filter3_slider.value = rnd(100, 10000)
		vbs.cymbal_filter4_slider.value = rnd(100, 10000)
		math.random(); math.random()
		vbs.cymbal_delay_slider.value = rnd(1, 2000)
		vbs.cymbal_attenuation_slider.value = rnd()
		if glitch then
			return cymbal(amount)
		end

	elseif sel == 5 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.claps_duration_slider.value = amount --rnd(1, 200) * 0.01
		end
		vbs.claps_noise_amount_slider.value = rnd(5, 990) * 0.001
		vbs.claps_filter_freq_slider.value = rnd(1000, 80000) * 0.1
		vbs.claps_filter_Q_slider.value = rnd(1, 200) * 0.1
		vbs.claps_delay_slider.value = rnd(1, 10) * 0.01
		vbs.claps_attack_time_slider.value = rnd(1, 100) * 0.001
		vbs.claps_decay_time_slider.value = rnd(1, 500) * 0.001
		vbs.claps_attack_shape_slider.value = rnd(100, 900) * 0.01
		math.random(); math.random(); math.random()
		vbs.claps_decay_shape_slider.value = rnd(100, 900) * 0.01
		if glitch then
			return claps(amount)
		end

	elseif sel == 6 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.karplus_duration_slider.value = amount --rnd(1, 200) * 0.01
		end
		vbs.karplus_noise_select.value = rnd(1,3)
		vbs.karplus_stretch_slider.value = rnd(10, 100) * 0.1
		vbs.karplus_wavelen_slider.value = rnd(10, 22050)
		vbs.karplus_filter1_selector.value = rnd(9)
		vbs.karplus_filter1_freq_slider.value = rnd(10000)
		vbs.karplus_filter1_Q_slider.value = rnd(200) * 0.1
		vbs.karplus_filter2_selector.value = rnd(9)
		math.random(); math.random(); math.random()
		vbs.karplus_filter2_freq_slider.value = rnd(10000)
		vbs.karplus_filter2_Q_slider.value = rnd(200) * 0.1
		vbs.karplus_filter3_selector.value = rnd(9)
		vbs.karplus_filter3_freq_slider.value = rnd(10000)
		vbs.karplus_filter3_Q_slider.value = rnd(200) * 0.1
		if glitch then
			return karplus_strong_drum(amount)
		end

	elseif sel == 7 then
		math.randomseed(os.clock())
		math.random(); math.random(); math.random()
		if amt > 0 then
			vbs.glocken_duration_slider.value = amount --rnd(1, 10)
		end
		vbs.glocken_frequency_slider.value = rnd(1, 10000)
		vbs.glocken_filter_selector.value = rnd(9)
		vbs.glocken_filter_frequency_slider.value = rnd(10000)
		vbs.glocken_filter_Q_slider.value = rnd(20)
		vbs.glocken_delay_slider.value = rnd(12, 2000)
		vbs.glocken_decay_slider.value = rnd()
		vbs.glocken_scaler_slider.value = rnd(200, 600) * 0.01
		vbs.glocken_tremolo_slider.value = rnd(100) * 0.01
		vbs.glocken_wave_selector.value = rnd(3)
		math.random(); math.random(); math.random()
		vbs.glocken_carrier_freq_slider.value = rnd(10000)
		vbs.glocken_drywet_slider.value = rnd(100) * 0.01
		vbs.glocken_env_attack_slider.value = rnd(1, 100) * 0.001
		vbs.glocken_env_decay_slider.value = rnd(1, 10000) * 0.001
		if glitch then
			return glockenspiel(amount)
		end
	
	else
		-- if error send some karplus data
		if glitch then
			return karplus_strong_drum(amount)
		end

	end

	-- ok all is set then go
	RENDER_SAMPLE = true
	render_sample()
end


-------------------------------------------------------------------------------------------------------------
-- MAIN RENDER FUNCTION                                                                                     -
-------------------------------------------------------------------------------------------------------------

function render_sample()
	
	if RENDER_SAMPLE == false then return end

	local selected_instrument = renoise.song().selected_instrument
	local samples_in_instrument = #selected_instrument.samples

	local data, new_sample

	if samples_in_instrument == 0 then
		new_sample = selected_instrument:insert_sample_at(1)
	else
		new_sample = renoise.song().selected_sample
	end

	if vbs.drum_switch.value == 1 then
		data = kick_drum(vbs.kick_duration_slider.value)
	
	elseif vbs.drum_switch.value == 2 then		
		data = snare_drum(vbs.snare_duration_slider.value)
	
	elseif vbs.drum_switch.value == 3 then
	
		if vbs.hihat_type_switch.value == 1 then
			data = hihat(vbs.hihat1_duration_slider.value)
		elseif vbs.hihat_type_switch.value == 2 then
			data = hihat2(vbs.hihat2_duration_slider.value)
		end
	
	elseif vbs.drum_switch.value == 4 then
		data = cymbal(vbs.cymbal_duration_slider.value)

	elseif vbs.drum_switch.value == 5 then
		data = claps(vbs.claps_duration_slider.value)

	elseif vbs.drum_switch.value == 6 then
		data = karplus_strong_drum(vbs.karplus_duration_slider.value)

	elseif vbs.drum_switch.value == 7 then
		data = glockenspiel(vbs.glocken_duration_slider.value)

	elseif vbs.drum_switch.value == 8 then
		data = glitcher()
	end

	if vbs.saturation_selector.value > 1 then
		data = Saturator(data, vbs.saturation_selector.value, vbs.saturation_amount_slider.value)
	end

	local maxval = -99999
	for i=1, #data do	
		local fn = vbs.envelope.value
		if fn < 34 then
			data[i] = (data[i] * EASEFN[fn](1 - i / #data, 0, 1, 1))
		elseif fn == 34 or fn == 35 or fn == 36 or fn == 37 then
			data[i] = (data[i] * EASEFN[fn](1 - i / #data, 0, 1, 1, vbs.amplitude_slider.value, vbs.period_slider.value))
		elseif fn == 42 then
			data[i] = data[i]
		else
			data[i] = (data[i] * EASEFN[fn](1 - i / #data, 0, 1, 1, vbs.parameter_slider.value))
		end
		if math.abs(data[i]) > maxval then maxval = math.abs(data[i]) end
	end

	local new_buffer = new_sample.sample_buffer
	new_buffer:create_sample_data(SAMPLERATE, BITRATE, 1, #data)
	new_buffer:prepare_sample_data_changes()

	for i=1, #data do
		local value
		if vbs.glitch_normalize_selector.value == 3 then
			value = data[i] / maxval
		else
			value = data[i]
		end
		new_buffer:set_sample_data(1, i, value * vbs.master_volume_slider.value)
	end
	new_buffer:finalize_sample_data_changes()
end
