----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function mix(x, y, a)
    return (1.0 - a) * x + a * y
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function curve_exponential(x, curvature)
    local scale = 2.0
    local sign = curvature < 0.0 and -1.0 or 1.0
    local b = (math.exp(scale * math.abs(curvature)) - 1.0) / (math.exp(scale) - 1.0)
    b = -5.0 * sign * b
    if math.abs(curvature) > 0.01 then
        return (math.exp(b * x) - 1.0) / (math.exp(b) - 1.0)
    else
        return x
    end
end


function curve_logarithmic(x, curvature)
    local scale = 2.0
    local sign = curvature < 0.0 and -1.0 or 1.0
    local b = (math.exp(scale * math.abs(curvature)) - 1.0) / (math.exp(scale) - 1.0)
    b = 5.0 * sign * b
    if math.abs(curvature) > 0.01 then
        return math.log(x * (math.exp(b) - 1.0) + 1.0) / b
    else
        return x
    end
end

function curve_circular(x, curvature)
    local b = curvature
    if math.abs(curvature) > 0.01 then
        local new_position = (b * x + (1.0 - b) * 0.5)
        local angle = math.acos(1.0 - new_position)
        local result = math.sin(angle)
        return (result - math.sin(math.acos(1.0 - ((1.0 - b) * 0.5))))
            / (math.sin(math.acos(1.0 - (b + (1.0 - b) * 0.5))) - math.sin(math.acos(1.0 - ((1.0 - b) * 0.5))))
    else
        return x
    end
end

function curve_half_sinusoidal(x, curvature)
    local b = math.abs(curvature)
    if curvature > 0.01 then
        if b <= 0.5 then
            b = 2.0 * b
            return (1.0 - b) * x + b * math.sin(x * math.pi/2.0)
        else
            return mix(
                math.sin(x * math.pi/2.0),
                math.sin(math.sin(x * math.pi/2.0) * math.pi/2.0),
                2.0 * curvature - 1.0
            )
        end
    elseif curvature < -0.01 then
        if b <= 0.5 then
            b = 2.0 * b
            return (1.0 - b) * x + b * (math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0)
        else
            return mix(
                math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0,
                math.sin(3.0*math.pi/2.0 + (math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0) * math.pi/2.0) + 1.0,
                2.0 * -curvature - 1.0
            )
        end
    else
        return x
    end
end

function curve_sinusoidal(x, curvature)
    local b = math.abs(curvature)
    if math.abs(curvature) > 0.01 then
        return (1.0 - b) * x + b * (math.sin((x - 0.5) * math.pi) / 2.0 + 0.5)
    else
        return x
    end
end

function curve_arcsinusoidal(x, curvature)
    local b = math.abs(curvature)
    if math.abs(curvature) > 0.01 then
        return (1.0 - b) * x + b * (math.asin(2.0 * x - 1.0) / math.pi + 0.5)
    else
        return x
    end
end

curve_functions =
{
    curve_exponential,
    curve_logarithmic,
    curve_half_sinusoidal,
    curve_sinusoidal,
    curve_circular,
    curve_arcsinusoidal,
}

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
