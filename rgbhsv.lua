--[[======================================================

rgbhsv.lua

RGB <-> HSV color conversion functions for lua (Renoise)
these functions converted for lua from original C functions that resided at
http://www.cs.rit.edu/~ncs/color/t_convert.html  (fetched 12.8.2012)

=====================================================]]--

function rgb_to_hsv(rgb)
    --rgb is a table with red, green, blue values 0 to 255
    --returns hsv table with hue(0-360), saturation(0-100), value(0-100)
    local red = rgb[1] / 255
    local green = rgb[2] / 255
    local blue = rgb[3] / 255
    local hue
    local saturation
    local value

    local min = math.min(math.min(red, green), blue)
    local max = math.max(math.max(red, green), blue)
    value = max
    local delta = max - min
    if not (max == 0) then
        saturation = delta / max
    else
        saturation = 0
        hue = -1
    end
    if red == max then
        hue = (green - blue) / delta    --between yellow & magenta
    elseif green == max then
        hue = 2 + (blue - red) / delta  --between cyan & yellow
    else --blue == max
        hue = 4 + (red - green) / delta --between magenta & cyan
    end
    hue = hue * 60      --degrees
    if hue < 0 then
        hue = hue + 360
    end
    return {hue, saturation * 100, value * 100}
end

function hsv_to_rgb(hsv)
    --hsv is a table with hue(0-360), saturation(0-100), value(0-100)
    --returns rgb table with red, green, blue values 0 to 255
    local hue = hsv[1]
    local saturation = hsv[2] / 100
    local value = hsv[3] / 100
    local hue_int, hue_fact
    local p, q, t
    local red, green, blue
    if saturation == 0 then
        --achromatic (grey)
        red = value
        green = value
        blue = value
    else
        hue = hue / 60  --sector 0 to 5
        hue_int = math.floor(hue)
        hue_fact = hue - hue_int        --factorial part of hue
        p = value * ( 1 - saturation)
        q = value * ( 1 - saturation * hue_fact)
        t = value * ( 1 - saturation * ( 1 - hue_fact) )
        if hue_int == 0 then
            red = value
            green = t
            blue = p
        elseif hue_int == 1 then
            red = q
            green = value
            blue = p
        elseif hue_int == 2 then
            red = p
            green = value
            blue = t
        elseif hue_int == 3 then
            red = p
            green = q
            blue = value
        elseif hue_int == 4 then
            red = t
            green = p
            blue = value
        else --hue_int == 5
            red = value
            green = p
            blue = q
        end
    end
    return {red * 255, green * 255, blue * 255}
end



--Original C functions
--[[

// r,g,b values are from 0 to 1
// h = [0,360], s = [0,1], v = [0,1]
//		if s == 0, then h = -1 (undefined)
void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v )
{
	float min, max, delta;
	min = MIN( r, g, b );
	max = MAX( r, g, b );
	*v = max;				// v
	delta = max - min;
	if( max != 0 )
		*s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		*s = 0;
		*h = -1;
		return;
	}
	if( r == max )
		*h = ( g - b ) / delta;		// between yellow & magenta
	else if( g == max )
		*h = 2 + ( b - r ) / delta;	// between cyan & yellow
	else
		*h = 4 + ( r - g ) / delta;	// between magenta & cyan
	*h *= 60;				// degrees
	if( *h < 0 )
		*h += 360;
}

void HSVtoRGB( float *r, float *g, float *b, float h, float s, float v )
{
	int i;
	float f, p, q, t;
	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}
	h /= 60;			// sector 0 to 5
	i = floor( h );
	f = h - i;			// factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );
	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:		// case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}
--]]

