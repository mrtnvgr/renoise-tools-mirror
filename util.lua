class 'Dlt_Util'



--=============================================================================
-- MUSIC and STRINGS
--=============================================================================

function Dlt_Util:cents_to_interval ( cents )
	------------------------------------------
	
	local N = math.abs(cents)
	local s = tostring(cents)

	if N < 100 then -- cents
		s = cents .. ' cent'
		if N ~= 1 then s = s..'s' end
	elseif N < 1200 then -- semitones
		local semitones = cents / 100
		s = semitones .. ' semitone'
		if semitones ~= 1 then s = s..'s' end
	else -- octaves
		local oct
		if cents < 0 then
			oct = math.ceil( cents / 1200 )
		else 
			oct = math.floor( cents / 1200 )
		end
		s = oct .. ' octave'
		if math.abs(oct) ~= 1 then s = s..'s' end

		local semitones = ( cents - (oct * 1200) ) / 100
		if semitones ~= 0 then
			s = s .. ', ' .. semitones .. ' semitone'
			if semitones ~= 1 then s = s..'s' end
		end
	end
	return s
end



function Dlt_Util:cents_to_musical_interval ( cents )
	--------------------------------------------------
	local N = math.abs(cents)

	local intervals = {}
	intervals[100] = 'Minor 2nd'
	intervals[200] = 'Major 2nd'
	intervals[300] = 'Minor 3rd'
	intervals[400] = 'Major 3rd'
	intervals[500] = 'Perfect 4th'
	intervals[600] = 'Tritone'
	intervals[700] = 'Perfect 5th'
	intervals[800] = 'Minor 6th'
	intervals[900] = 'Major 6th'
	intervals[1000] = 'Minor 7th'
	intervals[1100] = 'Major 7th'
	intervals[1200] = 'Octave'
	intervals[1300] = 'Minor 9th'
	intervals[1400] = 'Major 9th'

	if intervals[N] ~= nil then
		return intervals[N]
	else
		return nil
	end
end

