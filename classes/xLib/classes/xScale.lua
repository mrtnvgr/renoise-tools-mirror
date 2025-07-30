--[[============================================================================
xScale
============================================================================]]--

--[[--

Methods for working with notes & harmonic scales
.
#

]]

class 'xScale'


xScale.PENTATONIC_EGYPTIAN = "Egyptian Pentatonic"
xScale.NEAPOLITAN_MAJOR = "Major Neapolitan"
xScale.NEAPOLITAN_MINOR = "Minor Neapolitan"

if (renoise.API_VERSION > 4) then
  xScale.PENTATONIC_EGYPTIAN = "Pentatonic Egyptian"
  xScale.NEAPOLITAN_MAJOR = "Neapolitan Major"
  xScale.NEAPOLITAN_MINOR = "Neapolitan Minor"
end

xScale.SCALES = {
  { name="None", keys={1,1,1,1,1,1,1,1,1,1,1,1}, count=12, },
  { name="Natural Major", keys={1,0,1,0,1,1,0,1,0,1,0,1}, count=7,  },
  { name="Natural Minor", keys={1,0,1,1,0,1,0,1,1,0,1,0}, count=7,  },
  { name="Pentatonic Major", keys={1,0,1,0,1,0,0,1,0,1,0,0}, count=5,  },
  { name="Pentatonic Minor", keys={1,0,0,1,0,1,0,1,0,0,1,0}, count=5,},
  { name="Egyptian Pentatonic", keys={1,0,1,0,0,1,0,1,0,0,1,0}, count=5,}, 
  { name=xScale.PENTATONIC_EGYPTIAN,keys={1,0,1,0,0,1,0,1,0,0,1,0},count=5,}, 
  { name="Blues Major", keys={1,0,1,1,1,0,0,1,0,1,0,0}, count=6,  },
  { name="Blues Minor", keys={1,0,0,1,0,1,1,1,0,0,1,0}, count=6,  },
  { name="Whole Tone", keys={1,0,1,0,1,0,1,0,1,0,1,0}, count=6,  },
  { name="Augmented", keys={1,0,0,1,1,0,0,1,1,0,0,1}, count=6,  },
  { name="Prometheus", keys={1,0,1,0,1,0,1,0,0,1,1,0}, count=6,  },
  { name="Tritone", keys={1,1,0,0,1,0,1,1,0,0,1,0}, count=6,  },
  { name="Harmonic Major", keys={1,0,1,0,1,1,0,1,1,0,0,1}, count=7,  },
  { name="Harmonic Minor", keys={1,0,1,1,0,1,0,1,1,0,0,1}, count=7,  },
  { name="Melodic Minor", keys={1,0,1,1,0,1,0,1,0,1,0,1}, count=7,  },
  { name="All Minor", keys={1,0,1,1,0,1,0,1,1,1,1,1}, count=9,  },
  { name="Dorian", keys={1,0,1,1,0,1,0,1,0,1,1,0}, count=7,  },
  { name="Phrygian", keys={1,1,0,1,0,1,0,1,1,0,1,0}, count=7,  },
  { name="Phrygian Dominant", keys={1,1,0,0,1,1,0,1,1,0,1,0}, count=7,  },
  { name="Lydian", keys={1,0,1,0,1,0,1,1,0,1,0,1}, count=7,  },
  { name="Lydian Augmented", keys={1,0,1,0,1,0,1,0,1,1,0,1}, count=7,  },
  { name="Mixolydian", keys={1,0,1,0,1,1,0,1,0,1,1,0}, count=7,  },
  { name="Locrian", keys={1,1,0,1,0,1,1,0,1,0,1,0}, count=7,  },
  { name="Locrian Major", keys={1,0,1,0,1,1,1,0,1,0,1,0}, count=7,  },
  { name="Super Locrian", keys={1,1,0,1,1,0,1,0,1,0,1,0}, count=7,  },
  { name= xScale.NEAPOLITAN_MAJOR, keys={1,1,0,1,0,1,0,1,0,1,0,1}, count=7,  }, 
  { name=xScale.NEAPOLITAN_MINOR, keys={1,1,0,1,0,1,0,1,1,0,0,1}, count=7,  }, 
  { name="Neapolitan Minor", keys={1,1,0,1,0,1,0,1,1,0,0,1}, count=7,  },
  { name="Romanian Minor", keys={1,0,1,1,0,0,1,1,0,1,1,0}, count=7,  },
  { name="Spanish Gypsy", keys={1,1,0,0,1,1,0,1,1,0,0,1}, count=7,  },
  { name="Hungarian Gypsy", keys={1,0,1,1,0,0,1,1,1,0,0,1}, count=7,  },
  { name="Enigmatic", keys={1,1,0,0,1,0,1,0,1,0,1,1}, count=7,  },
  { name="Overtone", keys={1,0,1,0,1,0,1,1,0,1,1,0}, count=7,  },
  { name="Diminished Half", keys={1,1,0,1,1,0,1,1,0,1,1,0}, count=8,  },
  { name="Diminished Whole", keys={1,0,1,1,0,1,1,0,1,1,0,1}, count=8,  },
  { name="Spanish Eight-Tone", keys={1,1,0,1,1,1,1,0,1,0,1,0}, count=8,  },
  { name="Nine-Tone Scale", keys={1,0,1,1,1,0,1,1,1,1,0,1}, count=9,  },
}


xScale.SCALE_NAMES = {}
for _,v in ipairs(xScale.SCALES) do
  table.insert(xScale.SCALE_NAMES,v.name)
end

--------------------------------------------------------------------------------
--- restricting notes to a specific scale and key 
-- @param note_value (0-119), notes outside this range are returned as-is 
-- @param scale_idx (int), 1=C, 2=C#, 3=D, ...
-- @param scale_key (int), the scale to apply (see xScale.SCALES) 

function xScale.restrict_to_scale(note_value,scale_idx,scale_key)

  if (note_value > 119) then
    return note_value
  end

  if not scale_key then
    scale_key = 1
  end

  local scale = xScale.SCALES[scale_idx]
  local key = note_value%12

  -- scale key means shifting the keys
  local keys = table.rcopy(scale.keys)
  if (scale_key > 1) then
    local tmp = scale_key-1
    while (tmp > 0) do
      local tmp_val = keys[#keys]
      table.insert(keys,1,tmp_val)
      table.remove(keys,#keys)
      tmp = tmp - 1
    end
  end

  local transpose = 0
  local tmp_key
  if (scale_key > 1) and (key == 1) and (keys[1] == 0) then
    -- special case: if we have shifted the keys, the
    -- first entry might be 0 - in this case, we look from
    -- the last entry in the keys table
    tmp_key = #keys-1
  else
    tmp_key = key+1
  end
  while (keys[tmp_key] == 0) do
    tmp_key = tmp_key-1
    transpose = transpose+1
  end
  return note_value - transpose

end

