---@diagnostic disable: lowercase-global
---------------------------------------------------------------------------------------------------------------
-- LINEAR RAMP GENERATOR                                                                                      -
---------------------------------------------------------------------------------------------------------------

function ramp_generator(from, to, samples)
	-- linear ramp generator from value, to value
	local buffer = {}
	for i=1, samples do
		if from == 0 and to == 1 then
			buffer[i] = i / samples
		else
			buffer[i] = 1 - (i / samples)
		end
	end
	return buffer
end

function DADenvelope(smpl, start_delay, attack_time, decay_time, nabeh, sestup)
	local samples = smpl * SAMPLERATE
	local delay = math.floor(start_delay * SAMPLERATE)
	local attack = math.floor(attack_time * SAMPLERATE)
	local decay = math.floor(decay_time * SAMPLERATE)
	local ende = samples - (delay + attack + decay)
	local nabeh = nabeh or 2
	local sestup = sestup or 4
	local buffer = {}

	-- start delay
	local pos = 0
	for i=1, delay do
		pos = pos + 1
		buffer[pos] = 0
	end

	-- attack
	local step = 1 / attack
	for i=1, attack do
		pos = pos + 1
		buffer[pos] = (i * step) ^ nabeh
	end

	-- decay
	for i=1, decay do
		pos = pos + 1
		buffer[pos] = (1 - (i / decay)) ^ sestup
	end

	for i=1, ende do   -- some error in function, check this.
		pos = pos + 1
		buffer[pos] = 0
	end

	return buffer

end

---------------------------------------------------------------------------------------------------------------
-- PHASOR                                                                                                     -
---------------------------------------------------------------------------------------------------------------

function sine_generator(frequency, samples, amplitude)
	-- @frequency    ... sine frequency in Hz
	-- @samples      ... number of samples (dutation in sec * 44100)
	-- @amplitude    ... amplitude of sine wave 0 .. 1
	local F = (math.pi * 2 * frequency) / SAMPLERATE
	local buffer = {}
	for T=1, samples do
		buffer[T] = amplitude * math.sin(F * T)
	end
	return buffer
end


function SawWave(ph)
	if ph < 0.5 then
		return 0.35 * math.sin(ph)
	else
		return (0.35 * math.sin(1 - ph)) + 0.5
	end
end


function SquareWave(ph)
	if ph < 0.5 then
		return 0.25
	else
		return 0.75
	end
end


function PulseWave(ph, pw)
	-- pw ... 0 < pw < 1

	--local pw = pw or 0.3
	if ph < pw then
		return 0.25
	else
		return 0.75
	end
end


function Morph(ph, z)
	-- morph between sine and square

	local z = z or 0.25
	local q
	if ph < 0.5 then q=0.25 else q=0.75 end
	local s = ph
	return z * q + (1 - z) * s
end


function FlexiWave(ph, d, v)
	-- Where 0<d<1.
	-- As d and v are varied (there are TWO independent dimensions to play with this time),
	-- a wide range of wave shapes are produced,
	-- from narrow impulses to full cycle sinusoids.
	-- When d=0.5 and v>1.5, formants are created,
	-- centred around harmonics of the fundamental frequency

	local d = d or 0.75
	local v = v or 2.245
	if ph < d then
		return (v * ph) / d
	else
		return (1 - v) * ((ph - d) / (1 - d)) + v
	end
end


function FmOP(buffer1, buffer2, FIF)
	-- fm synth
	-- FIF ... Feed In Factor ... (intensity of modulation) 0 < FIF < 50

	for i=1, #buffer1 do
		buffer2[i] = (buffer2[i] + FIF * buffer1[i]) / 2
	end
	return buffer2
end


function MakeOSC(freq, duration, amplitude, samplerate, PD, phase, pulse_width, morph)
	local Hz = freq or 440
	local SR = samplerate or 44100
	local A = amplitude or 1.0
	local L = (duration * SR) or 22050
	local Phase = phase or 0
	local Phase_Add = Hz / SR
	local buff = {}
	local PD = PD or nil
	local pulse_width=pulse_width or 0.2
	local morph = morph or 0.5

	for T=1, L do
		if PD ~= nil then
			buff[T] = A * math.sin(math.pi * 2 * PD(Phase, pulse_width))
		else
			buff[T] = A * math.sin(math.pi * 2 * Phase)
		end
		Phase = Phase + Phase_Add
		if Phase > 1 then Phase = Phase - 1 end
	end
	return buff
end