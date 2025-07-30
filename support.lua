--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Support Code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
PK_NOTE_TABLE = {"C-", "Db", "D-", "Eb", "E-", "F-",
                 "Gb", "G-", "Ab", "A-", "Bb", "B-"}

PK_SCALE_CHROMATIC  = 1
PK_SCALE_MAJOR      = 2
PK_SCALE_MEL_MINOR  = 3
PK_SCALE_HARM_MINOR = 4
PK_SCALE_NAT_MINOR  = 5
PK_SCALE_PENT_MAJ   = 6
PK_SCALE_PENT_MIN   = 7

PK_SCALE_NAMES = {"Chr", " Mj", "MMn", "HMn", "nMn", "PMj", "PMn"}

PK_SCALE_TABLE = {{ 0,  1,  2,  3,  4,  5,  6,  7,    -- chromatic
                    8,  9,  10, 11, 12, 13, 14, 15},
                  { 0,  2,  4,  5,  7,  9, 11, 0xFF,  -- major
                   12, 14, 16, 17, 19, 21, 23, 0xFF},
                  { 0,  2,  3,  5,  7,  9, 11, 0xFF,  -- melodic minor
                   12, 14, 15, 17, 19, 21, 23, 0xFF}, 
                  { 0,  2,  3,  5,  7,  8, 11, 0xFF,  -- harmonic minor
                   12, 14, 15, 17, 19, 20, 23, 0xFF},
                  { 0,  2,  3,  5,  7,  8, 10, 0xFF,  -- natural minor
                   12, 14, 15, 17, 19, 20, 22, 0xFF},
                  { 0,  2,  5,  7,  9,                -- pentatonic major
                   12, 14, 17, 19, 21,
                   24, 26, 29, 31, 33,
                   36},
                  { 0,  3,  5,  7, 10,                -- pentatonic minor
                   12, 15, 17, 19, 22,
                   24, 27, 29, 31, 34,
                   36}
                 }

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
pk_pad_map_base = 0x30 -- middle C
pk_pad_map_scale = PK_SCALE_CHROMATIC


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function clamp(value, min, max)
  return math.max(min, math.min(max, value))
end


function midi_note_to_pk_lcd(note_number)
  -- convert a midi note number to a display suitable for the padkontrol lcd
  return PK_NOTE_TABLE[(note_number%12)+1] .. tostring(math.floor(note_number/12))
end


function make_pad_map(inst, slice_bank0)
  -- generate and return a pad mapping table
  
  
  local pad_mapping = {0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 
                       0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F}
 
  if #inst.samples > 1 then
    if inst.samples[2].is_slice_alias then
      -- sliced sample
      local sm = inst.sample_mappings[renoise.Instrument.LAYER_NOTE_ON]
      
      -- limit bank index to available slice banks
      if not slice_bank0 then
        slice_bank0 = 0
      end
      
      if slice_bank0 * 16 > #sm then
        slice_bank0 = math.floor(#sm/16)
      end
      
      -- clear pad maps      
      local start_map = (slice_bank0 * 16) + 2
      local end_map = math.min(((slice_bank0+1)*16)+1, #sm)
      
        
      for i = start_map, end_map do
        pad_mapping[i-start_map+1] = sm[i].note_range[1] -- low note = high note
      end

    else
      -- scale mapping
      local base = pk_pad_map_base
      local st = PK_SCALE_TABLE[pk_pad_map_scale]
       
      for i = 1, 16 do
        pad_mapping[i] = clamp(base + st[i], 0, 0x7F)
      end
    end
  else
    -- scale mapping
    local base = pk_pad_map_base
    local st = PK_SCALE_TABLE[pk_pad_map_scale]
       
    for i = 1, 16 do
      pad_mapping[i] = clamp(base + st[i], 0, 0x7F)
    end
  end
  
  return pad_mapping
end

function vol_to_lcd(vol)
  return string.format("%03d", math.floor(clamp(vol,0,1)*127))
end


function pan_to_lcd(pan)
  if pan > 0.5 then
    pan = math.floor((0.01+pan) * 100)
  else
    pan = math.floor(pan * 100)
  end
  if pan == 50 then
    return "CEN"
  elseif pan < 50 then
    return string.format("%02dL", 50-pan)
  elseif pan > 50 then
    return string.format("%02dR", pan-51)
  end
end


function nna_to_lcd(nna)
  if nna == renoise.Sample.NEW_NOTE_ACTION_NOTE_CUT then
    return"Cut"
  elseif nna == renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF then
    return "Off"
  elseif nna == renoise.Sample.NEW_NOTE_ACTION_SUSTAIN then
    return "Sus"
  end
end


function tune_to_lcd(trans)
  if trans < -99 then
    return '---'
  elseif trans > 99 then
    return string.format("%03d",trans)
  else
    return string.format("%+03d",trans)
  end
end


function interpolate_to_lcd(interp)
  if interp == renoise.Sample.INTERPOLATE_NONE then
    return "Non"
  elseif interp == renoise.Sample.INTERPOLATE_LINEAR then
    return "LIn"
  elseif interp == renoise.Sample.INTERPOLATE_CUBIC then
    return "Cub"
  end
end
