local util = {}

-- https://github.com/rxi/lume/blob/master/lume.lua#L87
function util.round(x, increment)
	if increment then return util.round(x / increment) * increment end
	return x >= 0 and math.floor(x + .5) or math.ceil(x - .5)
end

function util.quantize(time, amount, lines, swing)
	amount = amount or 1
	lines = lines or 1
	swing = swing or 0
	local target = util.round(time, 255 * lines)
	if target % (255 * lines * 2) > 0 then
		target = target + 255 * lines * swing
	end
	return util.lerp(time, target, amount)
end

function util.lerp(a, b, f)
	return a + (b - a) * f
end

-- Converts a line number and a delay value to a time.
function util.to_time(line, delay)
	return (line - 1) * 255 + delay
end

-- Converts a time to a line number and a delay value.
function util.from_time(time)
	local line = math.floor(time / 255) + 1
	local delay = time % 255
	return line, delay
end

return util
