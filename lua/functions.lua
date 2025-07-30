--
-- functions
--


-------------------------------------------------------------------------------------------------
--tables of registry

--pad press
KNG_PAD_NTE = {
    0,  1,  2,  3,  4,  5,  6,  7,
    8,  9, 10, 11, 12, 13, 14, 15,
   16, 17, 18, 19, 20, 21, 22, 23,
   24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39,
   40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55,
   56, 57, 58, 59, 60, 61, 62, 63,

   64, 65, 66, 67, 68, 69, 70, 71,
   72, 73, 74, 75, 76, 77, 78, 79,
   80, 81, 82, 83, 84, 85, 86, 87,
   88, 89, 90, 91, 92, 93, 94, 95,
   96, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119
}
---
KNG_PAD_INS = {
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0
}
---
KNG_PAD_TRK = {
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1
}
---
KNG_PAD_VEL = {
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
    
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95,
   95, 95, 95, 95, 95, 95, 95, 95
}


--pad release
local KNG_PAD_NTE_REL = {
    0,  1,  2,  3,  4,  5,  6,  7,
    8,  9, 10, 11, 12, 13, 14, 15,
   16, 17, 18, 19, 20, 21, 22, 23,
   24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39,
   40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55,
   56, 57, 58, 59, 60, 61, 62, 63,

   64, 65, 66, 67, 68, 69, 70, 71,
   72, 73, 74, 75, 76, 77, 78, 79,
   80, 81, 82, 83, 84, 85, 86, 87,
   88, 89, 90, 91, 92, 93, 94, 95,
   96, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119
}
---
local KNG_PAD_INS_REL = {
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0
}
---
local KNG_PAD_TRK_REL = {
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1
}


--pad 3x4 or whrite keys
local KNG_PAD_NTE_3X4 = {
    0,  1,  2,  3,   12, 13, 14, 15,
    4,  5,  6,  7,   16, 17, 18, 19,
    8,  9, 10, 11,   20, 21, 22, 23,

   24, 25, 26, 27,   36, 37, 38, 39,
   28, 29, 30, 31,   40, 41, 42, 43,
   32, 33, 34, 35,   44, 45, 46, 47,

   48, 49, 50, 51,   60, 61, 62, 63,
   52, 53, 54, 55,   64, 65, 66, 67,
   56, 57, 58, 59,   68, 69, 70, 71,

   72, 73, 74, 75,   84, 85, 86, 87,
   76, 77, 78, 79,   88, 89, 90, 91,
   80, 81, 82, 83,   92, 93, 94, 95,

   96, 97, 98, 99,  108,109,110,111,
  100,101,102,103,  112,113,114,115,
  104,105,106,107,  116,117,118,119
}
--
local KNG_PAD_NTE_K_WHITE = { --120
    0,   2,   4,   5,   7,   9,  11,   121,
   12,  14,  16,  17,  19,  21,  23,   121,
   24,  26,  28,  29,  31,  33,  35,   121,
   36,  38,  40,  41,  43,  45,  47,   121,   
   48,  50,  52,  53,  55,  57,  59,   121,
   60,  62,  64,  65,  67,  69,  71,   121,
   72,  74,  76,  77,  79,  81,  83,   121,
   84,  86,  88,  89,  91,  93,  95,   121,
   96,  98, 100, 101, 103, 105, 107,   121,
  108, 110, 112, 113, 115, 117, 119,   121,
  
    0,   2,   4,   5,   7,   9,  11,   121,
   12,  14,  16,  17,  19,  21,  23,   121,
   24,  26,  28,  29,  31,  33,  35,   121,
   36,  38,  40,  41,  43,  45,  47,   121,   
   48,  50,  52,  53,  55,  57,  59,   121
}



--pad sustain mode
local KNG_PAD_SUS = {
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false
}



--pno sustain mode
local KNG_PNO_SUS = {
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false
}



-------------------------------------------------------------------------------------------------
--osc server (localhost)
KNG_OSC_IP_1 = 127  -- always 127
KNG_OSC_IP_2 = 0    -- 0 to 255
KNG_OSC_IP_3 = 0    -- 0 to 255
KNG_OSC_IP_4 = 1    -- 1 to 255
KNG_OSC_P0RT = 8000 -- 1 to 9999
KNG_OSC_PROT = renoise.Socket.PROTOCOL_UDP



class "KNG_OscClient"
function KNG_OscClient:__init( osc_host, osc_port, protocol )
  self._connection = nil
  local client, socket_error = renoise.Socket.create_client( osc_host, osc_port, protocol )
  if ( socket_error ) then 
    rna:show_warning( "Warning: Failed to start the internal OSC client" )
    self._connection = nil
  else
    self._connection = client
  end
end
---
-- Trigger instrument-note
  --- note_on (bool), true when note-on and false when note-off
  --- instr    (int), the Renoise instrument index 1-254
  --- track    (int), the Renoise track index 
  --- note     (int), the desired pitch, 0-119
  --- velocity (int), the desired velocity, 0-127
function KNG_OscClient:trigger_instrument( note_on, instr, track, note, velocity )
  if not self._connection then
    return false
  end
  local osc_vars = { }
        osc_vars[1] = { tag = "i", value = instr }
        osc_vars[2] = { tag = "i", value = track }
        osc_vars[3] = { tag = "i", value = note  }
        
  local header = nil
  if ( note_on ) then
    header = "/renoise/trigger/note_on"
      osc_vars[4] = { tag = "i", value = velocity }    
  else
    header = "/renoise/trigger/note_off"
  end
  self._connection:send( renoise.Osc.Message( header, osc_vars ) )
  return true
end
---
local KNG_OSC_CLIENT = nil
function kng_osc_client_launch() 
  KNG_OSC_CLIENT = KNG_OscClient( ("%s.%s.%s.%s"):format( KNG_OSC_IP_1, KNG_OSC_IP_2, KNG_OSC_IP_3, KNG_OSC_IP_4 ), KNG_OSC_P0RT, KNG_OSC_PROT ) --127.0.0.1, 8000, 2
end
kng_osc_client_launch()



-------------------------------------------------------------------------------------------------
--midi input

--midi in velocity checkbox
local KNG_MIDI_VEL_PAD_CTRL = false
function kng_midi_pad_ctrl()
  if ( KNG_MIDI_VEL_PAD_CTRL == false ) then
    vws.KNG_BT_MIDI_VEL_PAD_CTRL.color = KNG_CLR.MARKER
    KNG_MIDI_VEL_PAD_CTRL = true
  else
    vws.KNG_BT_MIDI_VEL_PAD_CTRL.color = KNG_CLR.DEFAULT
    KNG_MIDI_VEL_PAD_CTRL = false
  end
end


--midi in velocity value
KNG_MIDI_IN_DEVICE_1 = 1 --(1 to 4+4
KNG_MIDI_IN_DEVICE_2 = 2 --(1 to 4+4
KNG_MIDI_DEVICE_1 = nil --pad
KNG_MIDI_DEVICE_2 = nil --piano
---
local KNG_MIDI_IN_PAD_MODE = true
local KNG_MIDI_IN_PAD_VEL = 96
function kng_midi_in_pad()
  local KNG_INPUTS = renoise.Midi.available_input_devices()
  local KNG_DEVICE_NAME = KNG_INPUTS[KNG_MIDI_IN_DEVICE_1]
  if not table.is_empty( KNG_INPUTS ) then
    if ( KNG_DEVICE_NAME == nil ) then
      if ( KNG_MIDI_DEVICE_1 and KNG_MIDI_DEVICE_1.is_open == true ) then KNG_MIDI_DEVICE_1:close() end
      return
    else
      local function midi_callback(message)
        if ( message[1] >= 0x90 ) and ( message[1] <= 0x9F ) then --0x90 to 0x9F: pad pressed
          if ( KNG_MIDI_IN_PAD_VEL ~= message[3] ) then
            KNG_MIDI_IN_PAD_VEL = message[3]
          end
        end
      end
      if ( KNG_MIDI_DEVICE_1 and KNG_MIDI_DEVICE_1.is_open == true ) then
        return
      else
        KNG_MIDI_DEVICE_1 = renoise.Midi.create_input_device( KNG_DEVICE_NAME, midi_callback )
      end
    end
  end
end
---
local KNG_MIDI_IN_PNO_MODE = true
local KNG_MIDI_IN_PNO_VEL = 96
function kng_midi_in_pno()
  local KNG_INPUTS = renoise.Midi.available_input_devices()
  local KNG_DEVICE_NAME = KNG_INPUTS[KNG_MIDI_IN_DEVICE_2]
  if not table.is_empty( KNG_INPUTS ) then
    if ( KNG_DEVICE_NAME == nil ) then
      if ( KNG_MIDI_DEVICE_2 and KNG_MIDI_DEVICE_2.is_open == true ) then KNG_MIDI_DEVICE_2:close() end
      return
    else
      local function midi_callback(message)
        if ( message[1] >= 0x90 ) and ( message[1] <= 0x9F ) then --0x90 to 0x9F: piano pressed
          if ( KNG_MIDI_IN_PNO_VEL ~= message[3] ) then
            KNG_MIDI_IN_PNO_VEL = message[3]
          end
        end
      end
      if ( KNG_MIDI_DEVICE_2 and KNG_MIDI_DEVICE_2.is_open == true ) then
        return
      else
        KNG_MIDI_DEVICE_2 = renoise.Midi.create_input_device( KNG_DEVICE_NAME, midi_callback )
      end
    end
  end
end

---check input devices and device close (until 4+4 devices)
function kng_check_input_devices()
  local KNG_INPUTS = renoise.Midi.available_input_devices()
  for i = 1, 8 do
    if KNG_INPUTS[i] ~= nil then
      KNG_INPUT_DEVICE[i] = KNG_INPUTS[i]
    else
      KNG_INPUT_DEVICE[i] = "None "..i
    end
  end
end
---
function kng_midi_device_close_1( val )
  kng_check_input_devices()
  if ( KNG_MIDI_DEVICE_1 and KNG_MIDI_DEVICE_1.is_open == true ) then
    KNG_MIDI_DEVICE_1:close()
  end
  KNG_MIDI_IN_DEVICE_1 = val --1 to 4
  --print("KNG_MIDI_IN_DEVICE_1=", KNG_MIDI_IN_DEVICE_1)
end
---
function kng_midi_device_close_2( val )
  kng_check_input_devices()
  if ( KNG_MIDI_DEVICE_2 and KNG_MIDI_DEVICE_2.is_open == true ) then
    KNG_MIDI_DEVICE_2:close()
  end
  KNG_MIDI_IN_DEVICE_2 = val --1 to 4
  --print("KNG_MIDI_IN_DEVICE_2=", KNG_MIDI_IN_DEVICE_2)
end

--midi in pads mode
function kng_midi_in_pad_mode()
  if ( KNG_MIDI_IN_PAD_MODE == false ) then
    vws.KNG_BT_MIDI_IN_PAD_MODE.color = KNG_CLR.MARKER
    KNG_MIDI_IN_PAD_MODE = true
  else
    vws.KNG_BT_MIDI_IN_PAD_MODE.color = KNG_CLR.DEFAULT
    KNG_MIDI_IN_PAD_MODE = false
  end
end

--midi in pad vol restore
function kng_midi_in_pad_vol_restore( nte_2 )
  if ( KNG_MIDI_IN_PAD_MODE == true ) and ( KNG_MIDI_VEL_PAD_CTRL == false ) then
    kng_midi_in_pad()
    vws["KNG_PAD_ROT_VEL_"..nte_2].value = KNG_MIDI_IN_PAD_VEL
  end
end



--midi in piano mode
function kng_midi_in_pno_mode()
  if ( KNG_MIDI_IN_PNO_MODE == false ) then
    vws.KNG_BT_MIDI_IN_PNO_MODE.color = KNG_CLR.MARKER
    KNG_MIDI_IN_PNO_MODE = true
  else
    vws.KNG_BT_MIDI_IN_PNO_MODE.color = KNG_CLR.DEFAULT
    KNG_MIDI_IN_PNO_MODE = false
  end
end

--midi in piano vol restore
function kng_midi_in_pno_vol_restore()
  if ( KNG_MIDI_IN_PNO_MODE == true ) then
    kng_midi_in_pno()
  end
end



-------------------------------------------------------------------------------------------------
--osc pad

--osc pad press an release
local KNG_INS_SEL_PAD = true
local KNG_TRK_SEL_PAD = true
function kng_osc_pad_pres( pad )
  local ins, trk, vel
  ---
  if ( KNG_INS_SEL_PAD == true ) then
    ins = KNG_PAD_INS[ pad + 1 ] + 1
  else
    ins = song.selected_instrument_index
  end
  if ( KNG_TRK_SEL_PAD == true ) then
    trk = KNG_PAD_TRK[ pad + 1 ]
  else
    trk = song.selected_track_index
  end
  ---
  local nte = KNG_PAD_NTE[ pad + 1 ]
  ---
  if ( KNG_MIDI_VEL_PAD_CTRL == false ) then
    if ( KNG_MIDI_IN_PAD_MODE == true ) then
      vel = KNG_MIDI_IN_PAD_VEL
    else
      vel = vws["KNG_PAD_ROT_VEL_"..pad].value
    end
  else
    vel = vws.KNG_PNO_ROT_VEL.value
  end
  ---
  KNG_OSC_CLIENT:trigger_instrument( true, ins, trk, nte, vel )
  vws["KNG_PAD_"..pad].color = KNG_CLR.MARKER
  ---rel
  KNG_PAD_NTE_REL[ pad + 1 ] = nte
  KNG_PAD_INS_REL[ pad + 1 ] = ins
  KNG_PAD_TRK_REL[ pad + 1 ] = trk
end
---
function kng_osc_pad_rel( pad )
  local ins, trk, vel
  ---
  if ( KNG_INS_SEL_PAD == true ) then
    ins = KNG_PAD_INS_REL[ pad + 1 ]
  else
    ins = song.selected_instrument_index
  end
  if ( KNG_TRK_SEL_PAD == true ) then
    trk = KNG_PAD_TRK_REL[ pad + 1 ]
  else
    trk = song.selected_track_index
  end
  ---
  local nte = KNG_PAD_NTE_REL[ pad + 1 ]
  ---
  KNG_OSC_CLIENT:trigger_instrument( false, ins, trk, nte )
  vws["KNG_PAD_"..pad].color = KNG_CLR.DEFAULT
end
---
local KNG_PAD_SUS_MODE = false
function kng_osc_bt_pad_pres( pad )
  if ( KNG_PAD_SUS_MODE == true ) then
    --chain
    kgn_osc_pad_sus_chain( pad )
    --sus
    if ( KNG_PAD_SUS[ pad + 1 ] == false ) then
      kng_osc_pad_pres( pad )
      KNG_PAD_SUS[ pad + 1 ] = true
    else
      kng_osc_pad_rel( pad )
      KNG_PAD_SUS[ pad + 1 ] = false
    end
  else
    kng_osc_pad_pres( pad )
  end
end
---
function kng_osc_bt_pad_rel( pad )
  if ( KNG_PAD_SUS_MODE == false ) then
    kng_osc_pad_rel( pad )
    kng_jump_lines()
    if ( KNG_PAD_SUS[ pad + 1 ] == true ) then
      KNG_PAD_SUS[ pad + 1 ] = false
    end
  else
    return
  end
end


--pad sustain
function kng_pad_bt_sus_mode()
  if ( KNG_PAD_SUS_MODE == false ) then
    vws.KNG_PAD_BT_SUS_MODE.color = KNG_CLR.MARKER
    KNG_PAD_SUS_MODE = true
    vws.KNG_PAD_RW_SUS_CHAIN_MODE.visible = true
  else
    vws.KNG_PAD_BT_SUS_MODE.color = KNG_CLR.DEFAULT
    KNG_PAD_SUS_MODE = false
    vws.KNG_PAD_RW_SUS_CHAIN_MODE.visible = false
  end
end



--pad sustain-chain
local KNG_PAD_SUS_CHAIN_MODE = false
function kgn_osc_pad_sus_chain( pad )
  if ( KNG_PAD_SUS_CHAIN_MODE == true ) then
    for i = 0, 119 do
      if ( i ~= pad ) then
        if ( KNG_PAD_SUS[ i + 1 ] == true ) then
          kng_osc_pad_rel( i )
          KNG_PAD_SUS[ i + 1 ] = false
        end
      end
    end
  end
end
---
function kng_pad_bt_sus_chain_mode()
  if ( KNG_PAD_SUS_CHAIN_MODE == false ) then
    vws.KNG_PAD_BT_SUS_CHAIN_MODE.color = KNG_CLR.MARKER
    KNG_PAD_SUS_CHAIN_MODE = true
  else
    vws.KNG_PAD_BT_SUS_CHAIN_MODE.color = KNG_CLR.DEFAULT
    KNG_PAD_SUS_CHAIN_MODE = false
  end
end


--pad panic
function kng_pad_bt_panic()
  for pad = 0, 119 do
    kng_osc_pad_rel( pad )
    if ( KNG_PAD_SUS[ pad + 1 ] == true ) then
      KNG_PAD_SUS[ pad + 1 ] = false
    end
  end
  --song.transport:panic()
end



-------------------------------------------------------------------------------------------------
--osc piano
function kng_osc_pno_bt_pres_clr( nte )
  vws["KNG_PNO_"..nte].color = KNG_CLR.GRAY_3
end
---
local KNG_TB_CLR_B = {
    1,   3,   6,   8,  10,
   13,  15,  18,  20,  22,
   25,  27,  30,  32,  34,
   37,  39,  42,  44,  46,
   49,  51,  54,  56,  58,
   61,  63,  66,  68,  70,
   73,  75,  78,  80,  82,
   85,  87,  90,  92,  94,
   97,  99, 102, 104, 106,
  109, 111, 114, 116, 118
}
---
function kng_osc_pno_bt_rel_clr( nte )
  local function key_black()
    vws["KNG_PNO_"..nte].color = KNG_CLR.BLACK
  end
  local function key_white()
    vws["KNG_PNO_"..nte].color = KNG_CLR.WHITE
  end
  if ( table.find( KNG_TB_CLR_B, nte, 1) ~= nil ) then
    return key_black()
  else
    return key_white()  
  end
  --[[ --------table.find is better!!!
  for key, val in pairs( KNG_TB_CLR_B ) do
    if ( val == nte + 1 )then
      return key_black()
    end
  end
  ]]
end
---
KNG_SPLIT_PIANO_MODE = false
function kng_bt_split_piano()
  if ( KNG_SPLIT_PIANO_MODE == false ) then
    vws.KNG_VB_SPLIT_PIANO_1.active = true
    vws.KNG_VB_SPLIT_PIANO_2.active = true
    vws.KNG_BT_SPLIT_PIANO.color = KNG_CLR.MARKER
    KNG_SPLIT_PIANO_MODE = true
  else
    vws.KNG_VB_SPLIT_PIANO_1.active = false
    vws.KNG_VB_SPLIT_PIANO_2.active = false
    vws.KNG_BT_SPLIT_PIANO.color = KNG_CLR.DEFAULT
    KNG_SPLIT_PIANO_MODE = false
  end
end
---
function kng_osc_pno_pres( nte )
  local ins, trk, vel
  if ( vws.KNG_VB_INS_SEL.value < 1 ) then
    ins = song.selected_instrument_index
  else
    ins = vws.KNG_VB_INS_SEL.value
  end
  if ( vws.KNG_VB_TRK_SEL.value < 1 ) then
    if ( KNG_SPLIT_PIANO_MODE == false ) then
      trk = song.selected_track_index
    else --split
      if ( nte >= vws.KNG_VB_SPLIT_PIANO_2.value - 1 ) then
        trk = song.selected_track_index + 1
      elseif ( nte < vws.KNG_VB_SPLIT_PIANO_1.value - 1 ) then
        trk = song.selected_track_index - 1
      else
        trk = song.selected_track_index
      end
    end
  else
    trk = vws.KNG_VB_TRK_SEL.value
  end
  if ( KNG_MIDI_IN_PNO_MODE == true ) then
    vel = KNG_MIDI_IN_PNO_VEL
  else
    vel = vws.KNG_PNO_ROT_VEL.value
  end
  KNG_OSC_CLIENT:trigger_instrument( true, ins, trk, nte, vel )
  kng_osc_pno_bt_pres_clr( nte )
  --vws["KNG_PNO_"..nte].color = KNG_CLR.GRAY_3
end
---
function kng_osc_pno_rel( nte )
  local ins, trk
  if ( vws.KNG_VB_INS_SEL.value < 1 ) then
    ins = song.selected_instrument_index
  else
    ins = vws.KNG_VB_INS_SEL.value
  end
  if ( vws.KNG_VB_TRK_SEL.value < 1 ) then
    if ( KNG_SPLIT_PIANO_MODE == false ) then
      trk = song.selected_track_index
    else --split
      if ( nte >= vws.KNG_VB_SPLIT_PIANO_2.value - 1 ) then
        trk = song.selected_track_index + 1
      elseif ( nte < vws.KNG_VB_SPLIT_PIANO_1.value - 1 ) then
        trk = song.selected_track_index - 1
      else
        trk = song.selected_track_index
      end
    end
  else
    trk = vws.KNG_VB_TRK_SEL.value
  end
  KNG_OSC_CLIENT:trigger_instrument( false, ins, trk, nte )
  kng_osc_pno_bt_rel_clr( nte )
end

local KNG_PNO_SUS_MODE = false
function kng_osc_bt_pno_pres( nte )
  if ( KNG_PNO_SUS_MODE == true ) then
    --chain
    kgn_osc_pno_sus_chain( nte )
    --sus
    if ( KNG_PNO_SUS[ nte + 1 ] == false ) then
      kng_osc_pno_pres( nte )
      KNG_PNO_SUS[ nte + 1 ] = true
    else
      kng_osc_pno_rel( nte )
      KNG_PNO_SUS[ nte + 1 ] = false
    end
  else
    kng_osc_pno_pres( nte )
  end
end
---
function kng_osc_bt_pno_rel( nte )
  if ( KNG_PNO_SUS_MODE == false ) then
    kng_osc_pno_rel( nte )
    kng_jump_lines()
    if ( KNG_PNO_SUS[ nte + 1 ] == true ) then
      KNG_PNO_SUS[ nte + 1 ] = false
    end
  else
    return
  end
end



--pno sustain
function kng_pno_bt_sus_mode()
  if ( KNG_PNO_SUS_MODE == false ) then
    vws.KNG_PNO_BT_SUS_MODE.color = KNG_CLR.MARKER
    KNG_PNO_SUS_MODE = true
    vws.KNG_PNO_RW_SUS_CHAIN_MODE.visible = true
  else
    vws.KNG_PNO_BT_SUS_MODE.color = KNG_CLR.DEFAULT
    KNG_PNO_SUS_MODE = false
    vws.KNG_PNO_RW_SUS_CHAIN_MODE.visible = false
  end
end



--pno sustain-chain
local KNG_PNO_SUS_CHAIN_MODE = false
function kgn_osc_pno_sus_chain( nte )
  if ( KNG_PNO_SUS_CHAIN_MODE == true ) then
    for i = 0, 119 do
      if ( i ~= nte ) then
        if ( KNG_PNO_SUS[ i + 1 ] == true ) then
          kng_osc_pno_rel( i )
          KNG_PNO_SUS[ i + 1 ] = false
        end
      end
    end
  end
end
---
function kng_pno_bt_sus_chain_mode()
  if ( KNG_PNO_SUS_CHAIN_MODE == false ) then
    vws.KNG_PNO_BT_SUS_CHAIN_MODE.color = KNG_CLR.MARKER
    KNG_PNO_SUS_CHAIN_MODE = true
  else
    vws.KNG_PNO_BT_SUS_CHAIN_MODE.color = KNG_CLR.DEFAULT
    KNG_PNO_SUS_CHAIN_MODE = false
  end
end



--piano 
function kng_pno_bt_panic()
  for pno = 0, 119 do
    kng_osc_pno_rel( pno )
    if ( KNG_PNO_SUS[ pno + 1 ] == true ) then
      KNG_PNO_SUS[ pno + 1 ] = false
    end
  end
  --song.transport:panic()
end



--jump lines
local KNG_JUMP_LINES = false
function kng_jump_lines()
  if ( KNG_JUMP_LINES == false ) then
    return
  else
    if ( song.transport.edit_mode == true ) then
      if ( song.selected_line_index + song.transport.edit_step <= song.selected_pattern.number_of_lines ) then
        song.selected_line_index = song.selected_line_index + song.transport.edit_step
      else
        song.selected_line_index = song.selected_pattern.number_of_lines
      end
    end
  end
end
---
function kng_bt_jump_lines()
  if ( KNG_JUMP_LINES == false ) then
    KNG_JUMP_LINES = true
    vws.KNG_BT_JUMP_LINES.color = KNG_CLR.MARKER
  else
    KNG_JUMP_LINES = false
    vws.KNG_BT_JUMP_LINES.color = KNG_CLR.DEFAULT
  end
end



-------------------------------------------------------------------------------------------------
--pads
local KNG_PAD_VISIBLE = 1
local KNG_ROT = false
function kng_pad_sel( value )
  if value < 1 then
    for i = 0, 119 do
      vws["KNG_PAD_SEL_"..i].color = KNG_CLR.DEFAULT
    end
  else
    if ( KNG_ROT == false ) then
      kng_vel_rotary_show( 0, 119 )
    end
    for i = 0, 119 do
      if ( i ~= math.floor(value -1) ) then
        vws["KNG_PAD_SEL_"..i].color = KNG_CLR.DEFAULT
      else
        vws["KNG_PAD_SEL_"..i].color = KNG_CLR.MARKER
      end
    end
    if ( KNG_PAD_VISIBLE < 3 ) then
      if ( math.floor(value) > 64 ) then      
        kng_pad_visible(2)
      else
        kng_pad_visible(1)
      end
    end
  end
end
---
function kng_nte_ini( val )
  if ( val < 1 ) then
    return
  else
    for pad = 1, 120 do
      if ( KNG_GRID_OCTAVES == 1 ) then
        if ( val + pad <= 121 ) then
          KNG_PAD_NTE[ pad ] = val + pad - 2
        else
          KNG_PAD_NTE[ pad ] = val + pad - 122
        end
      elseif ( KNG_GRID_OCTAVES == 2 ) then
        if ( val + KNG_PAD_NTE_3X4[pad] < 121 ) then
          KNG_PAD_NTE[ pad ] = val + KNG_PAD_NTE_3X4[pad] - 1
        else
          KNG_PAD_NTE[ pad ] = val + KNG_PAD_NTE_3X4[pad] - 121
        end
      else
        local white = { 1, 13, 25, 37, 49, 61, 73, 85, 97, 109 }
        if ( table.find( white, val, 1 ) ~= nil ) then
          if ( val + KNG_PAD_NTE_K_WHITE[pad] < 121 ) then
            KNG_PAD_NTE[ pad ] = val + KNG_PAD_NTE_K_WHITE[pad] -1
          else
            if ( KNG_PAD_NTE_K_WHITE[pad] ~= 121 ) then
              KNG_PAD_NTE[ pad ] = val + KNG_PAD_NTE_K_WHITE[pad] -121
            else
              KNG_PAD_NTE[ pad ] = 121
            end
          end
        end
      end
      if ( vws.KNG_VB_INS_SEL.value ~= 0 ) then
        KNG_PAD_INS[ pad ] = vws.KNG_VB_INS_SEL.value - 1
      end
      if ( vws.KNG_VB_TRK_SEL.value ~= 0 ) then
        KNG_PAD_TRK[ pad ] = vws.KNG_VB_TRK_SEL.value
      end
      vws["KNG_PAD_"..pad - 1 ].text = ("%.2d\n%s  %.2X\nTr%.2d"):format( pad, kng_note_tostring( KNG_PAD_NTE[ pad ] ), KNG_PAD_INS[ pad ], KNG_PAD_TRK[ pad ] )
    end
  end
end
---
local KNG_VB_INS_SEL_POS = 0
function kng_ins_sel( value )
  if ( value < 1 ) then
    return
  else
    --print(#song.instruments)
    local val = vws.KNG_VB_INS_SEL.value
    vws.KNG_VB_INS_SEL.max = #song.instruments --#song.tracks
    if ( vws.KNG_VB_INS_SEL.value > vws.KNG_VB_INS_SEL.max ) then
      vws.KNG_VB_INS_SEL.value = vws.KNG_VB_INS_SEL.max
    end
    if ( KNG_VB_INS_SEL_POS == song.selected_instrument_index ) then
      song.selected_instrument_index = val
    end
    KNG_VB_INS_SEL_POS = val --soft takeover
  end
end
---
local KNG_VB_TRK_SEL_POS = 0
function kng_trk_sel( value )
  if ( value < 1 ) then
    return
  else
    --print(song.sequencer_track_count)
    local val = vws.KNG_VB_TRK_SEL.value
    vws.KNG_VB_TRK_SEL.max = song.sequencer_track_count --#song.tracks
    if ( vws.KNG_VB_TRK_SEL.value > vws.KNG_VB_TRK_SEL.max ) then
      vws.KNG_VB_TRK_SEL.value = vws.KNG_VB_TRK_SEL.max
    end
    if ( KNG_VB_TRK_SEL_POS == song.selected_track_index ) then
      song.selected_track_index = val
    end
    KNG_VB_TRK_SEL_POS = val --soft takeover
  end
end



--note selection jump
local KNG_JUMP = false
function kng_pad_note_sel_jump()
  if ( KNG_JUMP == false ) then
    KNG_JUMP = true
    vws.KNG_BT_JUMP.color = KNG_CLR.MARKER
    if ( vws.KNG_VB_PAD_SEL.value < 1 ) then
      vws.KNG_VB_PAD_SEL.value = 1
    end
  else
    KNG_JUMP = false
    vws.KNG_BT_JUMP.color = KNG_CLR.DEFAULT
  end
end
---
function kng_pad_note_sel( nte )
  local val = vws.KNG_VB_PAD_SEL.value
  --sel pad
  if ( vws.KNG_VB_PAD_SEL.value < 1 ) then
    return
  else
    local ins, trk
    --ins
    if ( vws.KNG_VB_INS_SEL.value < 1 ) then
      ins = song.selected_instrument_index -1
    else
      ins = vws.KNG_VB_INS_SEL.value -1
    end
    --trk
    if ( vws.KNG_VB_TRK_SEL.value < 1 ) then
      trk = song.selected_track_index
    else
      trk = vws.KNG_VB_TRK_SEL.value
    end
    KNG_PAD_NTE[ val ] = nte
    KNG_PAD_INS[ val ] = ins
    KNG_PAD_TRK[ val ] = trk
    if ( nte ~= 121 ) then
      vws["KNG_PAD_"..val - 1 ].text = ("%.2d\n%s  %.2X\nTr%.2d"):format( val, kng_note_tostring( nte ), ins, trk )
    else
      vws["KNG_PAD_"..val - 1 ].text = ("%.2d\n---  %.2X\nTr%.2d"):format( val, ins, trk )
    end
  end
  ---
  if ( KNG_JUMP == false ) then
    return
  else
    if val + 1 <= 120 then
      vws.KNG_VB_PAD_SEL.value = val + 1
    else
      vws.KNG_VB_PAD_SEL.value = 0
    end
  end
end



--grid octaves
KNG_GRID_OCTAVES = 1
function kng_grid_octaves( val )
  KNG_GRID_OCTAVES = val
  if ( val == 1 ) then
    vws.KNG_GRID_OCTAVES_1.color = KNG_CLR.MARKER
    vws.KNG_GRID_OCTAVES_2.color = KNG_CLR.DEFAULT
    vws.KNG_GRID_OCTAVES_3.color = KNG_CLR.DEFAULT
  elseif ( val == 2 ) then
    vws.KNG_GRID_OCTAVES_1.color = KNG_CLR.DEFAULT
    vws.KNG_GRID_OCTAVES_2.color = KNG_CLR.MARKER  
    vws.KNG_GRID_OCTAVES_3.color = KNG_CLR.DEFAULT
  else
    vws.KNG_GRID_OCTAVES_1.color = KNG_CLR.DEFAULT
    vws.KNG_GRID_OCTAVES_2.color = KNG_CLR.DEFAULT    
    vws.KNG_GRID_OCTAVES_3.color = KNG_CLR.MARKER
  end
end

--lock NTE valuebox
KNG_NTE_SEL = true
function kng_lock_nte( val )
  if ( val == 1 ) then
    vws.KNG_VB_NTE_SEL.active = true
    vws.KNG_LOCK_NTE_1.color = KNG_CLR.MARKER
    vws.KNG_LOCK_NTE_2.color = KNG_CLR.DEFAULT
    KNG_NTE_SEL = true
  else
    vws.KNG_VB_NTE_SEL.active = false
    vws.KNG_LOCK_NTE_1.color = KNG_CLR.DEFAULT
    vws.KNG_LOCK_NTE_2.color = KNG_CLR.MARKER
    KNG_NTE_SEL = false
  end
end



-------------------------------------------------------------------------------------------------
--controls
function kng_piano_show()
  if ( vws.KNG_ALL_PIANO.visible == true ) then
    vws.KNG_ALL_PIANO_SHOW.color = KNG_CLR.DEFAULT
    vws.KNG_ALL_PIANO.visible = false
  else
    vws.KNG_ALL_PIANO_SHOW.color = KNG_CLR.MARKER
    vws.KNG_ALL_PIANO.visible = true
  end
end
---
function kng_pad_show()
  if ( vws.KNG_PAD.visible == true ) then
    vws.KNG_PAD_SHOW.color = KNG_CLR.DEFAULT
    vws.KNG_PAD.visible = false
  else
    vws.KNG_PAD_SHOW.color = KNG_CLR.MARKER
    vws.KNG_PAD.visible = true
  end
end
---
function kng_bank_show()
  if ( vws.KNG_BANKS.visible == false ) then
    if ( KNG_ROT == false ) then
      kng_vel_rotary_show( 0, 119 )
    end
    kng_pad_visible( 1 )
    vws.KNG_BANKS.visible = true
    vws.KNG_BANKS_SHOW.color = KNG_CLR.MARKER
    kng_revise_bank( 1, 96 )
  else
    vws.KNG_BANKS.visible = false
    vws.KNG_BANKS_SHOW.color = KNG_CLR.DEFAULT
  end
end
---
function kng_preferences_show()
  if ( vws.KNG_PREFERENCES.visible == true ) then
    vws.KNG_PREFERENCES_SHOW.color = KNG_CLR.DEFAULT
    vws.KNG_PREFERENCES.visible = false
  else
    if ( vws.KNG_PAD.visible == true ) and ( KNG_PAD_VISIBLE == 3 ) then
      kng_pad_visible( 1 )
    end
    vws.KNG_PREFERENCES_SHOW.color = KNG_CLR.MARKER
    vws.KNG_PREFERENCES.visible = true
  end
end
---
function kng_pad_visible( val )
  if ( val == 1 ) then
    vws.KNG_PAD_07_00.visible = true
    vws.KNG_PAD_14_08.visible = false
    vws.KNG_PAD_VISIBLE_1.color = KNG_CLR.MARKER
    vws.KNG_PAD_VISIBLE_2.color = KNG_CLR.DEFAULT
    vws.KNG_PAD_VISIBLE_3.color = KNG_CLR.DEFAULT
    KNG_PAD_VISIBLE = 1
  elseif  ( val == 2 ) then
    vws.KNG_PAD_07_00.visible = false
    vws.KNG_PAD_14_08.visible = true
    vws.KNG_PAD_VISIBLE_1.color = KNG_CLR.DEFAULT
    vws.KNG_PAD_VISIBLE_2.color = KNG_CLR.MARKER
    vws.KNG_PAD_VISIBLE_3.color = KNG_CLR.DEFAULT
    KNG_PAD_VISIBLE = 2
  else
    vws.KNG_PAD_14_08.visible = true
    vws.KNG_PAD_07_00.visible = true
    vws.KNG_PAD_VISIBLE_1.color = KNG_CLR.DEFAULT
    vws.KNG_PAD_VISIBLE_2.color = KNG_CLR.DEFAULT
    vws.KNG_PAD_VISIBLE_3.color = KNG_CLR.MARKER
    KNG_PAD_VISIBLE = 3
  end
end
---
function kng_pad_visible_loop()
  if ( KNG_PAD_VISIBLE == 1 ) then
    return kng_pad_visible( 2 )
  elseif ( KNG_PAD_VISIBLE == 2 ) then
    return kng_pad_visible( 3 )
  else
    return kng_pad_visible( 1 )
  end
end



-------------------------------------------------------------------------------------------------
--piano
function kng_vel_rotary_show( val_1, val_2 )
  if ( KNG_ROT == false ) then
    --pad
    for i = val_1, val_2 do
      vws["KNG_PAD_ROT_"..i].visible = true
      vws["KNG_PAD_BACKGROUND_"..i].width = 117
    end
    --piano
    vws.KNG_PIANO_WIDTH.width = 857
    vws.KNG_BT_ROT.color = KNG_CLR.MARKER
    if ( vws.KNG_PIANO_WIDTH.spacing < -834 ) then
      vws.KNG_PIANO_WIDTH.spacing = -834
    end      
    KNG_ROT = true
    vws.KNG_SPLIT_PIANO_CONTROLS.visible = true
    vws.KNG_LOGO.visible = true
    vws.KNG_KANGAROO.visible = true
    --operations
    vws.KNG_OPERATIONS_SHOW.visible = true
  else
    --pad
    for i = val_1, val_2 do
      vws["KNG_PAD_ROT_"..i].visible = false
      vws["KNG_PAD_BACKGROUND_"..i].width = 73
    end
    --piano
    vws.KNG_PIANO_WIDTH.width = 505
    vws.KNG_PIANO.width = 599
    vws.KNG_BT_ROT.color = KNG_CLR.DEFAULT
    if ( vws.KNG_PIANO_WIDTH.spacing == -834 ) then
      vws.KNG_PIANO_WIDTH.spacing = -848
    end
    KNG_ROT = false
    vws.KNG_SPLIT_PIANO_CONTROLS.visible = false
    vws.KNG_LOGO.visible = false
    vws.KNG_KANGAROO.visible = false
    --banks
    if ( vws.KNG_BANKS.visible == true ) then
      vws.KNG_BANKS.visible = false
      vws.KNG_BANKS_SHOW.color = KNG_CLR.DEFAULT
    end
    --operations
    vws.KNG_OPERATIONS_SHOW.visible = false
    vws.KNG_OPERATIONS_SHOW.color = KNG_CLR.DEFAULT
    if ( vws.KNG_OPERATIONS.visible == true ) then
      vws.KNG_OPERATIONS.visible = false
    end
  end
end
---
function kng_ins_sel_pad( bol )
  KNG_INS_SEL_PAD = bol
  if ( bol == true ) then
    vws.KNG_INS_SEL_PAD_1.color = KNG_CLR.MARKER
    vws.KNG_INS_SEL_PAD_2.color = KNG_CLR.DEFAULT
  else
    vws.KNG_INS_SEL_PAD_1.color = KNG_CLR.DEFAULT
    vws.KNG_INS_SEL_PAD_2.color = KNG_CLR.MARKER
  end
end
---
function kng_trk_sel_pad( bol )
  KNG_TRK_SEL_PAD = bol
  if ( bol == true ) then
    vws.KNG_TRK_SEL_PAD_1.color = KNG_CLR.MARKER
    vws.KNG_TRK_SEL_PAD_2.color = KNG_CLR.DEFAULT
  else
    vws.KNG_TRK_SEL_PAD_1.color = KNG_CLR.DEFAULT
    vws.KNG_TRK_SEL_PAD_2.color = KNG_CLR.MARKER
  end  
end
---
function kng_ins_sel_pad_loop()
  if ( KNG_INS_SEL_PAD == true ) then
    kng_ins_sel_pad( false )
  else
    kng_ins_sel_pad( true )
  end
end
---
function kng_trk_sel_pad_loop()
  if ( KNG_TRK_SEL_PAD == true ) then
    kng_trk_sel_pad( false )
  else
    kng_trk_sel_pad( true )
  end
end



--piano jump octave 0 and 9
function kng_piano_jump_0()
  vws.KNG_PIANO_WIDTH.spacing = -3
end
---
function kng_piano_jump_9()
  if ( KNG_ROT == false ) then
    vws.KNG_PIANO_WIDTH.spacing = -1186
  else
    vws.KNG_PIANO_WIDTH.spacing = -834
  end
end
---
function kng_piano_jump_l_repeat( release )
  if not release then
    if rnt:has_timer( kng_piano_jump_l_repeat ) then
      kng_piano_jump_l()
      rnt:remove_timer( kng_piano_jump_l_repeat )
      rnt:add_timer( kng_piano_jump_l, 150 )
    else
      kng_piano_jump_l()
      rnt:add_timer( kng_piano_jump_l_repeat, 300 )
    end
  else
    if rnt:has_timer( kng_piano_jump_l_repeat ) then
      rnt:remove_timer( kng_piano_jump_l_repeat )
    elseif rnt:has_timer( kng_piano_jump_l ) then
      rnt:remove_timer( kng_piano_jump_l )
    end
  end
end
---
function kng_piano_jump_l()
  if ( vws.KNG_PIANO_WIDTH.spacing == -1186 ) then
    vws.KNG_PIANO_WIDTH.spacing = -1017
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -1017 ) then
    vws.KNG_PIANO_WIDTH.spacing = -848
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -848 ) or ( vws.KNG_PIANO_WIDTH.spacing == -834 ) then
    vws.KNG_PIANO_WIDTH.spacing = -679
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -679 ) then
    vws.KNG_PIANO_WIDTH.spacing = -510
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -510 ) then
    vws.KNG_PIANO_WIDTH.spacing = -341
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -341 ) then
    vws.KNG_PIANO_WIDTH.spacing = -172
  else
    vws.KNG_PIANO_WIDTH.spacing = -3
  end
end
---
function kng_piano_jump_r_repeat( release )
  if not release then
    if rnt:has_timer( kng_piano_jump_r_repeat ) then
      kng_piano_jump_r()
      rnt:remove_timer( kng_piano_jump_r_repeat )
      rnt:add_timer( kng_piano_jump_r, 150 )
    else
      kng_piano_jump_r()
      rnt:add_timer( kng_piano_jump_r_repeat, 300 )
    end
  else
    if rnt:has_timer( kng_piano_jump_r_repeat ) then
      rnt:remove_timer( kng_piano_jump_r_repeat )
    elseif rnt:has_timer( kng_piano_jump_r ) then
      rnt:remove_timer( kng_piano_jump_r )
    end
  end
end
---
function kng_piano_jump_r()
  if ( vws.KNG_PIANO_WIDTH.spacing == -3 ) then
    vws.KNG_PIANO_WIDTH.spacing = -172
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -172 ) then
    vws.KNG_PIANO_WIDTH.spacing = -341
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -341 ) then
    vws.KNG_PIANO_WIDTH.spacing = -510
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -510 ) then
    vws.KNG_PIANO_WIDTH.spacing = -679
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -679 ) then
    if ( KNG_ROT == false ) then
      vws.KNG_PIANO_WIDTH.spacing = -848
    else
      vws.KNG_PIANO_WIDTH.spacing = -834
    end
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -848 ) then
    vws.KNG_PIANO_WIDTH.spacing = -1017
  elseif ( vws.KNG_PIANO_WIDTH.spacing == -1017 ) then
    vws.KNG_PIANO_WIDTH.spacing = -1186
  end
end



--note off note empty
function kng_note_off_empty( val )
  if ( song.selected_note_column ~= nil ) and ( song.transport.edit_mode == true ) then
    song.selected_note_column:clear() --clear
    song.selected_note_column.note_value = val --120 or 121
  end
end



-------------------------------------------------------------------------------------------------
--advanced operations

--show advanced operations panel
function kng_operations_show()
  if ( vws.KNG_OPERATIONS.visible == false ) then
    vws.KNG_OPERATIONS.visible = true
    vws.KNG_OPERATIONS_SHOW.color = KNG_CLR.MARKER
    if ( KNG_ROT == false ) then
      kng_vel_rotary_show( 0, 119 )
    end
    --pads
    if ( vws.KNG_PAD.visible == true ) then
      vws.KNG_PAD_SHOW.color = KNG_CLR.DEFAULT
      vws.KNG_PAD.visible = false
    end
  else
    vws.KNG_OPERATIONS.visible = false
    vws.KNG_OPERATIONS_SHOW.color = KNG_CLR.DEFAULT
  end
end



--auto sequence
function kng_auto_insert_seq()
  --print( song.selected_sequence_index, #song.sequencer.pattern_sequence )
  if ( song.selected_sequence_index == #song.sequencer.pattern_sequence ) then
    if ( song.selected_sequence_index < 1000 ) then
      song.sequencer:insert_new_pattern_at( song.selected_sequence_index + 1 )
    end
  end
end
---
local KNG_SEQ_SEL
function kng_auto_sequence()
  local ssi = song.selected_sequence_index
  if ( KNG_SEQ_SEL == ssi ) then
    return
  else
    kng_auto_insert_seq()
    KNG_SEQ_SEL = ssi
    print(KNG_SEQ_SEL)
  end
end
---
KNG_AUTO_SEQUENCE = false
function kng_auto_sequence_obs()
  local trans = song.transport
  if ( KNG_AUTO_SEQUENCE == false ) then
    if not rnt:has_timer( kng_auto_sequence ) then
      rnt:add_timer( kng_auto_sequence, 5 )
    end
    kng_auto_sequence()
    trans.follow_player = true
    trans.wrapped_pattern_edit = true
    trans:start( renoise.Transport.PLAYMODE_RESTART_PATTERN )
    rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
    rna.window.pattern_matrix_is_visible = true
    KNG_AUTO_SEQUENCE = true
    vws.KNG_BT_AUTO_SEQUENCE.color = KNG_CLR.MARKER
  else
    if rnt:has_timer( kng_auto_sequence ) then
      rnt:remove_timer( kng_auto_sequence )
    end
    trans:stop()
    KNG_AUTO_SEQUENCE = false
    vws.KNG_BT_AUTO_SEQUENCE.color = KNG_CLR.DEFAULT
  end
end

--[[ *** ERROR INSIDE RENOISE: selected_sequence_index_observable not work correctly in R3.1.1 x64 ***
function kng_auto_sequence_obs()
  if ( KNG_AUTO_SEQUENCE == false ) then
    if not song.selected_sequence_index_observable:has_notifier( kng_auto_sequence ) then
      song.selected_sequence_index_observable:add_notifier( kng_auto_sequence )
    end
    kng_auto_sequence()
    KNG_AUTO_SEQUENCE = true
    vws.KNG_BT_AUTO_SEQUENCE.color = KNG_CLR.MARKER
  else
    if song.selected_sequence_index_observable:has_notifier( kng_auto_sequence ) then
      song.selected_sequence_index_observable:remove_notifier( kng_auto_sequence )
    end
    KNG_AUTO_SEQUENCE = false
    vws.KNG_BT_AUTO_SEQUENCE.color = KNG_CLR.DEFAULT
  end
end
]]



--copy sequence
function kng_select_sequence( value )
  local ssi = song.selected_sequence_index
  --restart selection
  if ( value == 0 ) then
    song.sequencer.selection_range = { 0,0 }
    vws.KNG_BT_COPY_SEQUENCE.active = false
    vws.KNG_BT_CLEAR_SEQUENCE.active = false
  else
  --specify selection
    if ( ssi + value - 1 <= #song.sequencer.pattern_sequence ) then
      vws.KNG_BT_COPY_SEQUENCE.active = true
      vws.KNG_BT_CLEAR_SEQUENCE.active = true
      song.sequencer.selection_range = { 0,0 }
      song.sequencer.selection_range = { ssi, ssi + value - 1 }
    else
      vws.KNG_BT_COPY_SEQUENCE.active = false
      vws.KNG_BT_CLEAR_SEQUENCE.active = false
    end
  end
end
---
function kng_copy_sequence()
  local ssi = song.selected_sequence_index
  --print("ssi", ssi)
  local seq = vws.KNG_VB_SELECT_SEQUENCE
  --print("spat.value",spat.value)
  if ( #song.sequencer.pattern_sequence < 999 - seq.value ) then
    if ( seq.value > 0 ) and ( ssi + seq.value - 1 <= #song.sequencer.pattern_sequence ) then
      --insert sequencer with clone (not sorted)
      song.sequencer:clone_range( ssi, ssi + seq.value - 1 )
      --sort the inserted sequencer
      song.sequencer:sort()
      --select final index
      song.selected_sequence_index = ssi + seq.value
    end
    kng_select_sequence ( seq.value )
  end
end
---
function kng_clear_sequence()
  local ssi = song.selected_sequence_index
  local seq = vws.KNG_VB_SELECT_SEQUENCE
  if ( ssi + seq.value -1 <= #song.sequencer.pattern_sequence ) then
    for i = ssi, ssi + seq.value -1 do
      song:pattern( song.sequencer:pattern( i ) ):clear()
    end
  end
end



--copy track/pattern_track
function kng_bt_copy_ptt_track()
  if ( vws.KNG_BT_COPY_PTT_TRACK.text == "Pattern-Track" ) then
    vws.KNG_BT_COPY_PTT_TRACK.text = "Track"
    vws.KNG_BT_COPY_PTT_TRACK_1.visible = false
    vws.KNG_BT_COPY_PTT_TRACK_2.visible = true
    vws.KNG_BT_COPY_PTT_TRACK_1.tooltip = ""
    vws.KNG_BT_COPY_PTT_TRACK_3.tooltip = "Duplicate the selected track to right (all values and properties). Always include a new track!"
    vws.KNG_BT_CLEAR_PTT_TRACK.tooltip = "Clear selected track"
  else
    vws.KNG_BT_COPY_PTT_TRACK.text = "Pattern-Track"
    vws.KNG_BT_COPY_PTT_TRACK_2.visible = false
    vws.KNG_BT_COPY_PTT_TRACK_1.visible = true
    vws.KNG_BT_COPY_PTT_TRACK_1.tooltip = "Copy the values of the selected pattern-track to left. Never include a new pattern-track & overwrite the values!"
    vws.KNG_BT_COPY_PTT_TRACK_3.tooltip = "Copy the values of the selected pattern-track to right. Never include a new pattern-track & overwrite the values!"
    vws.KNG_BT_CLEAR_PTT_TRACK.tooltip = "Clear selected pattern-track"
  end
end
---
local KNG_COPY_TRACK_VALUES = true
function kng_copy_track_values()
  if ( KNG_COPY_TRACK_VALUES == true ) then
    KNG_COPY_TRACK_VALUES = false
    vws.KNG_BT_COPY_PTT_TRACK_2.color = KNG_CLR.DEFAULT
  else
    KNG_COPY_TRACK_VALUES = true
    vws.KNG_BT_COPY_PTT_TRACK_2.color = KNG_CLR.MARKER
  end
end
---
function kng_copy_track()
  local sti = song.selected_track_index +1
  if ( song.selected_track.type == renoise.Track.TRACK_TYPE_GROUP ) then
    song:insert_group_at( sti )
  else
    song:insert_track_at( sti )
  end
  ---
  local org = song.selected_track
  --oprint(org)
  local des = song:track( sti )
  --define properties
  local id = { "name", "mute_state", "color", "color_blend", "visible_effect_columns", "visible_note_columns",
               "volume_column_visible", "panning_column_visible", "delay_column_visible", "sample_effects_column_visible",
               "collapsed", "group_collapsed",
             }
  if ( org.type == des.type ) then
    if ( org.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
      --clone track propertiess
      for i = 1, #id -1 do
        des[ id[i] ] = org[ id[i] ]
      end
      --clone note columns names & is muted
      for i = 1, 12 do
        des:set_column_name( i, org:column_name(i) )
        des:set_column_is_muted( i, org:column_is_muted(i) )
      end
      --slot is muted
      for s = 1, #song.sequencer.pattern_sequence do
        if song.sequencer:track_sequence_slot_is_muted( sti -1, s ) then
          song.sequencer:set_track_sequence_slot_is_muted( sti, s, true )
        end
      end
      --clone notes
      if ( KNG_COPY_TRACK_VALUES == true ) then
        for s = 1, #song.sequencer.pattern_sequence do
          local ptt = song:pattern( s )
          ptt:track( sti ):copy_from( ptt:track( sti -1 ) )
        end
      end
    else
      --clone group/master/send propertiess
      for i = 1, 5 do
        des[ id[i] ] = org[ id[i] ]
      end
      if ( des.type == renoise.Track.TRACK_TYPE_GROUP ) then
        des[ id[#id] ] = org[ id[#id] ]
      end
      if ( des.type == renoise.Track.TRACK_TYPE_SEND ) then
        des[ id[#id -1] ] = org[ id[#id -1] ]
      end
    end
    song.selected_track_index = sti
  else
    rna:show_status( "KangarooX120:  The type of initial and destination track does not match!" )  
  end
end
--copy pattern-track
function kng_copy_ptt_track( val )
  local org = song.selected_track
  --oprint(org)
  local sti = song.selected_track_index + val
  if ( sti >= 1 ) and ( sti <= song.sequencer_track_count ) then
    local des = song:track( sti )
    --define properties
    local id = { "visible_effect_columns", "visible_note_columns",
                 "volume_column_visible", "panning_column_visible", "delay_column_visible", "sample_effects_column_visible"
               }
    if ( org.type == des.type ) then
      if ( org.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
        --clone track propertiess
        for i = 1, #id do
          if ( i <= 2 ) then
            if ( des[ id[i] ] < org[ id[i] ] ) then
              des[ id[i] ] = org[ id[i] ]
            end
          else
            if ( des[ id[i] ] == false ) then
              des[ id[i] ] = org[ id[i] ]
            end
          end
        end
        --clone track values
        song.selected_pattern:track( sti ):copy_from( song.selected_pattern_track )
        --select track destination
        song.selected_track_index = sti
      else
        rna:show_status( "KangarooX120:  The type selected is a group/master/send, not a track. Please, select a track to copy!" )  
      end
    else
      rna:show_status( "KangarooX120:  The type of destination is not a track. Impossible to copy!" )
    end
  else
    rna:show_status( "KangarooX120:  It is between the limits between the range of tracks. Impossible to copy!" )
  end
end
---
function kng_clear_track_ptt_track()
  if ( vws.KNG_BT_COPY_PTT_TRACK.text == "Track" ) then
    local sti = song.selected_track_index
    for s = 1, #song.sequencer.pattern_sequence do
      local ptt = song:pattern( s )
      ptt:track( sti ):clear()
    end
  else
    song.selected_pattern_track:clear()
  end
end
---
function kng_copy_track_ptt_track( val )
  if ( vws.KNG_BT_COPY_PTT_TRACK.text == "Track" ) then
    kng_copy_track()
  else
    kng_copy_ptt_track( val )
  end
end



--copy note column to left/right
function kng_copy_note_column( val )
  local spi = song.selected_pattern_index
  local sti = song.selected_track_index
  local snci = song.selected_note_column_index
  if ( val == 1 ) then
    if ( snci > 1 ) then  
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern_track( spi, sti ) do
        local columns = line.note_columns
        --copy note column to left
        columns[ snci - 1 ]:copy_from( columns[ snci ] )
      end
      --select new note column index
      song.selected_note_column_index = snci - 1
    end
  else
    if ( snci > 0 and snci < 12 ) then  
      --visible note column state
      if ( song.selected_track.visible_note_columns < snci + 1 ) then
        song.selected_track.visible_note_columns = snci + 1
      end
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern_track( spi, sti ) do
        local columns = line.note_columns
        --copy note column to right
        columns[ snci + 1 ]:copy_from( columns[ snci ] )
      end
      --select new note column index
      song.selected_note_column_index = snci + 1
    end
  end
end
---
function kng_clear_note_column()
  local spi = song.selected_pattern_index
  local sti = song.selected_track_index
  local snci = song.selected_note_column_index
  if ( song.selected_note_column ~= nil ) then  
    local iter = song.pattern_iterator
    for pos, line in iter:lines_in_pattern_track( spi, sti ) do
      local column = line:note_column( snci )
      column:clear()
    end
  end
end



--transpose notes
function kng_transpose_notes()
  local sel = vws.KNG_PP_SEL_AREA.value
  local trn = vws.KNG_VB_TRANSPOSE_NOTES.value --(-24 or +24)
  local spi, sti, snc, snci = song.selected_pattern_index, song.selected_track_index, song.selected_note_column, song.selected_note_column_index
  local nol = song.selected_pattern.number_of_lines
  local tr = song.selected_pattern:track( sti )
  --transpose for line
  if ( sel == 1 ) and ( snc ~= nil ) then
    for c = 1, 12 do
      local nv = song.selected_line:note_column( c )
      if ( nv.note_value <= 119 ) and ( nv.note_value + trn <= 119 ) and ( nv.note_value + trn >= 0 ) then
        nv.note_value = nv.note_value + trn
      end
    end
  end
  --transpose for note column
  if ( sel == 2 ) and ( snc ~= nil ) then
    for l = 1, nol do
      local nv = tr:line( l ):note_column( snci )
      if ( nv.note_value <= 119 ) and ( nv.note_value + trn <= 119 ) and ( nv.note_value + trn >= 0 ) then
        nv.note_value = nv.note_value + trn
      end
    end
  end
  --transpose for all note columns
  if ( sel == 3 ) and ( snc ~= nil ) then
    for l = 1, nol do
      for c = 1, 12 do
        local clm = tr:line( l ):note_column( c )
        if ( clm.note_value <= 119 ) and ( clm.note_value + trn <= 119 ) and ( clm.note_value + trn >= 0 ) then
          clm.note_value = clm.note_value + trn
        end
      end
    end
  end
  --transpose for selection
  if ( sel == 4 ) then
    if ( song.selection_in_pattern ~= nil ) then
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern( spi ) do
        for _, note_column in pairs( line.note_columns ) do
          if ( note_column.is_selected ) then
            if ( note_column.note_value <= 119 ) and ( note_column.note_value + trn <= 119 ) and ( note_column.note_value + trn >= 0 ) then
              note_column.note_value = note_column.note_value + trn
            end
          end
        end
      end
    end
  end
end



--change instrument
function kng_change_instrument_value()
  local sel = vws.KNG_PP_SEL_AREA.value
  local ins = song.selected_instrument_index -1
  local spi, sti, snc, snci = song.selected_pattern_index, song.selected_track_index, song.selected_note_column, song.selected_note_column_index
  local nol = song.selected_pattern.number_of_lines
  local tr = song.selected_pattern:track( sti )
  --transpose for line
  if ( sel == 1 ) and ( snc ~= nil ) then
    for c = 1, 12 do
      local nv = song.selected_line:note_column( c )
      if ( nv.note_value <= 119 ) then
        nv.instrument_value = ins
      end
    end
  end
  --transpose for note column
  if ( sel == 2 ) and ( snc ~= nil ) then
    for l = 1, nol do
      local nv = tr:line( l ):note_column( snci )
      if ( nv.note_value <= 119 ) then
        nv.instrument_value = ins
      end
    end
  end
  --transpose for all note columns
  if ( sel == 3 ) and ( snc ~= nil ) then
    for l = 1, nol do
      for c = 1, 12 do
        local clm = tr:line( l ):note_column( c )
        if ( clm.note_value <= 119 ) then
          clm.instrument_value = ins
        end
      end
    end
  end
  --transpose for selection
  if ( sel == 4 ) then
    if ( song.selection_in_pattern ~= nil ) then
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern( spi ) do
        for _, note_column in pairs( line.note_columns ) do
          if ( note_column.is_selected ) then
            if ( note_column.note_value <= 119 ) then
              note_column.instrument_value = ins
            end
          end
        end
      end
    end
  end 
end



--moddify values
function kng_mod_values()
  local sel = vws.KNG_PP_SEL_AREA.value
  local mod = vws.KNG_PP_MOD_VALUES.value
  local val = vws.KNG_VB_MOD_VALUES.value
  local ptr = song.selected_pattern_track
  local spi = song.selected_pattern_index
  local snc = song.selected_note_column
  local snci= song.selected_note_column_index
  local nol = song.selected_pattern.number_of_lines
  local sti = song.selected_track_index
  local tr  = song.selected_pattern:track( sti )
  --moddify for line
  if ( sel == 1 ) and ( snc ~= nil ) then
    for c = 1, 12 do
      local ncl = song.selected_line:note_column( c )
      if ( ncl.note_value <= 119 )  then
        if ( mod == 1 ) and ( val <= 127 ) then
          ncl.volume_value = val
        end
        if ( mod == 2 ) and ( val <= 127 ) then
          ncl.panning_value = val
        end
        if ( mod == 3 ) and ( val <= 255 ) then
          ncl.delay_value = val
        end
      end
    end  
  end
  --moddify for note column
  if ( sel == 2 ) and ( snc ~= nil ) then
    for l = 1, nol do
      local ncl = ptr:line( l ):note_column( snci )
      if ( ncl.note_value <= 119 )  then
        if ( mod == 1 ) and ( val <= 127 ) then
          ncl.volume_value = val
        end
        if ( mod == 2 ) and ( val <= 127 ) then
          ncl.panning_value = val
        end
        if ( mod == 3 ) and ( val <= 255 ) then
          ncl.delay_value = val
        end
      end
    end
  end
  --moddify for all note columns
  if ( sel == 3 ) and ( snc ~= nil ) then
    for l = 1, nol do
      for c = 1, 12 do
        local ncl = tr:line( l ):note_column( c )
        if ( ncl.note_value <= 119 )  then
          if ( mod == 1 ) and ( val <= 127 ) then
            ncl.volume_value = val
          end
          if ( mod == 2 ) and ( val <= 127 ) then
            ncl.panning_value = val
          end
          if ( mod == 3 ) and ( val <= 255 ) then
            ncl.delay_value = val
          end
        end
      end
    end
  end
  --moddify for selection    
  if ( sel == 4 ) then
    if ( song.selection_in_pattern ~= nil ) then
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern( spi ) do
        for _, ncl in pairs( line.note_columns ) do
          if ( ncl.is_selected ) then
            if ( ncl.note_value <= 119 )  then
              if ( mod == 1 ) and ( val <= 127 ) then
                ncl.volume_value = val
              end
              if ( mod == 2 ) and ( val <= 127 ) then
                ncl.panning_value = val
              end
              if ( mod == 3 ) and ( val <= 255 ) then
                ncl.delay_value = val
              end
            end
          end
        end
      end
    end
  end
end
---
function kng_clear_values()
  local sel = vws.KNG_PP_SEL_AREA.value
  local mod = vws.KNG_PP_MOD_VALUES.value
  local ptr = song.selected_pattern_track
  local spi = song.selected_pattern_index
  local snc = song.selected_note_column
  local snci= song.selected_note_column_index
  local nol = song.selected_pattern.number_of_lines
  local sti = song.selected_track_index
  local tr  = song.selected_pattern:track( sti )
  --moddify for line
  if ( sel == 1 ) and ( snc ~= nil ) then
    for c = 1, 12 do
      local ncl = song.selected_line:note_column( c )
      if ( mod == 1 ) then
        ncl.volume_value = 255
      end
      if ( mod == 2 ) then
        ncl.panning_value = 255
      end
      if ( mod == 3 ) then
        ncl.delay_string = ".."
      end
    end  
  end
  --moddify for note column
  if ( sel == 2 ) and ( snc ~= nil ) then
    for l = 1, nol do
      local ncl = ptr:line( l ):note_column( snci )
      if ( mod == 1 ) then
        ncl.volume_value = 255
      end
      if ( mod == 2 ) then
        ncl.panning_value = 255
      end
      if ( mod == 3 ) then
        ncl.delay_string = ".."
      end
    end
  end
  --moddify for all note columns
  if ( sel == 3 ) and ( snc ~= nil ) then
    for l = 1, nol do
      for c = 1, 12 do
        local ncl = tr:line( l ):note_column( c )
        if ( mod == 1 ) then
          ncl.volume_value = 255
        end
        if ( mod == 2 ) then
          ncl.panning_value = 255
        end
        if ( mod == 3 ) then
          ncl.delay_string = ".."
        end
      end
    end
  end
  --moddify for selection    
  if ( sel == 4 ) then
    if ( song.selection_in_pattern ~= nil ) then
      local iter = song.pattern_iterator
      for pos, line in iter:lines_in_pattern( spi ) do
        for _, ncl in pairs( line.note_columns ) do
          if ( ncl.is_selected ) then
            if ( mod == 1 ) then
              ncl.volume_value = 255
            end
            if ( mod == 2 ) then
              ncl.panning_value = 255
            end
            if ( mod == 3 ) then
              ncl.delay_string = ".."
            end
          end
        end
      end
    end
  end
end



--automation slopes

--first/previous/next sequence
function kng_first_seq_aut()
  song.selected_sequence_index = 1
end
---
function kng_previous_seq_aut()
  kng_kh_nav_sequence( -1 )
end
---
function kng_next_seq_aut()
  kng_kh_nav_sequence( 1 )
end
---
function kng_previous_seq_aut_repeat( release )
  if not release then
    if rnt:has_timer( kng_previous_seq_aut_repeat ) then
      kng_previous_seq_aut()
      rnt:remove_timer( kng_previous_seq_aut_repeat )
      rnt:add_timer( kng_previous_seq_aut, 25 )
    else
      kng_previous_seq_aut()
      kng_select_automation()
      rnt:add_timer( kng_previous_seq_aut_repeat, 400 )
    end
  else
    if rnt:has_timer( kng_previous_seq_aut_repeat ) then
      rnt:remove_timer( kng_previous_seq_aut_repeat )
    elseif rnt:has_timer( kng_previous_seq_aut ) then
      rnt:remove_timer( kng_previous_seq_aut )
    end
  end
end
---
function kng_next_seq_aut_repeat( release )
  if not release then
    if rnt:has_timer( kng_next_seq_aut_repeat ) then
      kng_next_seq_aut()
      rnt:remove_timer( kng_next_seq_aut_repeat )
      rnt:add_timer( kng_next_seq_aut, 25 )
    else
      kng_next_seq_aut()
      kng_select_automation()
      rnt:add_timer( kng_next_seq_aut_repeat, 400 )
    end
  else
    if rnt:has_timer( kng_next_seq_aut_repeat ) then
      rnt:remove_timer( kng_next_seq_aut_repeat )
    elseif rnt:has_timer( kng_next_seq_aut ) then
      rnt:remove_timer( kng_next_seq_aut )
    end
  end
end



--select sequence
function kng_select_automation( value )
  if ( value == 0 ) then
    vws.KNG_BT_AUTOMATION_INVERSE_POINTS.active = false
    vws.KNG_BT_AUTOMATION_SLOPES_DOWN.active = false
    vws.KNG_BT_AUTOMATION_SLOPES_UP.active = false
    vws.KNG_BT_AUTOMATION_SLOPES_L_R.active = false
    ---
    vws.KNG_BT_AUTOMATION_SLOPES_INSERT.active = false
    vws.KNG_BT_AUTOMATION_SLOPES_CLEAR.active = false
    vws.KNG_VB_AUTOMATION_SLOPES_SQU.active = false
    vws.KNG_VB_AUTOMATION_SLOPES_SQU_1.active = false
  else
    vws.KNG_BT_AUTOMATION_INVERSE_POINTS.active = true
    vws.KNG_BT_AUTOMATION_SLOPES_DOWN.active = true
    vws.KNG_BT_AUTOMATION_SLOPES_UP.active = true
    vws.KNG_BT_AUTOMATION_SLOPES_L_R.active = true
    vws.KNG_VB_AUTOMATION_SLOPES_SQU.active = true
    vws.KNG_VB_AUTOMATION_SLOPES_SQU_1.active = true
    ---
    vws.KNG_BT_AUTOMATION_SLOPES_INSERT.active = true
    vws.KNG_BT_AUTOMATION_SLOPES_CLEAR.active = true
    if not ( renoise.app().window.lower_frame_is_visible ) then
      renoise.app().window.lower_frame_is_visible = true
    end
    if ( renoise.app().window.active_lower_frame ~= renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION ) then
      renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
    end
  end
  ---
  --[[ not work without create_automation!
  local sp = song.selected_parameter
  if ( sp ) then
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    local sti = song.selected_track_index
    for seq = ssi, ssi + value -1 do
      if ( seq <= #song.sequencer.pattern_sequence ) then
        local patt = song:pattern( seq )
        local spa = patt:track( sti ):find_automation( sp )
        if ( not spa ) and ( patt ~= nil ) then
          spa = patt:track( sti ):create_automation( sp )
          spa.selection_range = { 1, patt.number_of_lines + 1 }
        end
      end
    end
  end
  ]]
end



--insert automation
function kng_insert_automation()
  local sp = song.selected_parameter
  if ( sp ) then
    local max = vws.KNG_VB_AUTOMATION_SLOPES_MAX.value / 1000
    local min = vws.KNG_VB_AUTOMATION_SLOPES_MIN.value / 1000
    local sub = max - min
    local squ = vws.KNG_VB_AUTOMATION_SLOPES_SQU.value
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value
    else
      num = #song.sequencer.pattern_sequence
    end
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    for seq = ssi, ssi + num -1 do
      if ( seq <= #song.sequencer.pattern_sequence ) then
        local patt = song:pattern( seq )
        local spa = patt:track( sti ):find_automation( sp )
        if ( not spa ) and ( patt ~= nil ) then
          spa = patt:track( sti ):create_automation( sp )
        end
        if ( spa ) then
          local mul = seq - song.selected_sequence_index          
          --local vpnt_1 = max - ( sub * mul / num )
          --local vpnt_2 = max - ( sub * ( mul + 1 ) / num )
          local vpnt_1, vpnt_2 = 0, 1
          if max >= min then
            vpnt_1 = max - ( sub * mul / num )^squ
            vpnt_2 = max - ( sub * ( mul + 1 ) / num )^squ
          else
            vpnt_1 = max + ( min * mul / num )^squ
            vpnt_2 = max + ( min * ( mul + 1 ) / num )^squ
          end
          --print ( vpnt_1, vpnt_2 )
          if ( vpnt_1 >= 0 ) and ( vpnt_1 <= 1 ) then
            spa:add_point_at( 1, vpnt_1 )
          elseif vpnt_1 < 0 then
            spa:add_point_at( 1, 0 )
          elseif vpnt_1 > 1 then
            spa:add_point_at( 1, 1 )
          end
          local time_2 = patt.number_of_lines + 0.99609375
          if ( vpnt_2 >= 0 ) and ( vpnt_2 <= 1 ) then
            spa:add_point_at( time_2, vpnt_2 )
          elseif vpnt_2 < 0 then
            spa:add_point_at( time_2, 0 )
          elseif vpnt_2 > 1 then
            spa:add_point_at( time_2, 1 )
          end
        end
      end
    end
  end
end

--[[
--insert automation
function kng_insert_automation()
  local sp = song.selected_parameter
  if ( sp ) then
    local max = vws.KNG_VB_AUTOMATION_SLOPES_MAX.value / 1000
    local min = vws.KNG_VB_AUTOMATION_SLOPES_MIN.value / 1000
    local sub = max - min
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value
    else
      num = #song.sequencer.pattern_sequence
    end
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    for seq = ssi, ssi + num -1 do
      if ( seq <= #song.sequencer.pattern_sequence ) then
        local patt = song:pattern( seq )
        local spa = patt:track( sti ):find_automation( sp )
        if ( not spa ) and ( patt ~= nil ) then
          spa = patt:track( sti ):create_automation( sp )
        end
        if ( spa ) then
          local mul = seq - song.selected_sequence_index
          local vpnt_1 = max - ( sub * mul / num )
          local vpnt_2 = max - ( sub * ( mul + 1 ) / num )
          --print ( vpnt_1, vpnt_2 )
          if ( vpnt_1 >= 0 ) and ( vpnt_1 <= 1 ) then
            spa:add_point_at( 1, vpnt_1 )
          end
          if ( vpnt_2 >= 0 ) and ( vpnt_2 <= 1 ) then
            spa:add_point_at( patt.number_of_lines + 0.99609375, vpnt_2 )
          end
        end
      end
    end
  end
end
]]

--inverse automation
function kng_inverse_automation()
  vws.KNG_VB_AUTOMATION_SLOPES_MAX.value, vws.KNG_VB_AUTOMATION_SLOPES_MIN.value = vws.KNG_VB_AUTOMATION_SLOPES_MIN.value, vws.KNG_VB_AUTOMATION_SLOPES_MAX.value
  kng_insert_automation()
end



--clear automation
function kng_clear_automation()
  local sp = song.selected_parameter
  if ( sp ) then
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value -1
    else
      num = #song.sequencer.pattern_sequence -1
    end
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index 
    for seq = ssi, ssi + num do
      if ( seq <= #song.sequencer.pattern_sequence ) then
        local patt = song:pattern( seq ):track( sti )
        local spa = patt:find_automation( sp )
        if ( spa ) then
          spa = patt:delete_automation( sp )
        end
      end
    end
  end
end



--inverse existent points
function kng_automation_inverse_points()
  local sp = song.selected_parameter
  if ( sp ) then
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value -1
    else
      num = #song.sequencer.pattern_sequence -1
    end
    if ( KNG_AUTOMATION_L_R == false ) then
      for seq = ssi, ssi + num do
        if ( seq <= #song.sequencer.pattern_sequence ) then
          local spa = song:pattern( seq ):track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              spa:add_point_at( point.time, 1 - point.value )
            end
          end
        end
      end
    else
      for seq = ssi -1, ssi - num, -1 do
        if ( seq >= 1 ) then
          local spa = song:pattern( seq ):track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              spa:add_point_at( point.time, 1 - point.value )
            end
          end
        end
      end
    end
  end
end



--automation up/down the values of points
function kng_down_automation()
  local sp = song.selected_parameter
  if ( sp ) then
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value -1
    else
      num = #song.sequencer.pattern_sequence -1
    end
    if ( KNG_AUTOMATION_L_R == false ) then
      for seq = ssi, ssi + num do
        if ( seq <= #song.sequencer.pattern_sequence ) then
          local patt = song:pattern( seq )
          local spa = patt:track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              if ( point.value - 0.001 >= 0 ) then
                spa:add_point_at( point.time, point.value -0.001 )
              else
                spa:add_point_at( point.time, 0 )
              end
            end
          end
        end
      end
    else
      for seq = ssi -1, ssi - num, -1 do
        if ( seq >= 1 ) then
          local patt = song:pattern( seq )
          local spa = patt:track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              if ( point.value - 0.001 >= 0 ) then
                spa:add_point_at( point.time, point.value -0.001 )
              else
                spa:add_point_at( point.time, 0 )
              end
            end
          end
        end
      end
    end
  end
end
---
function kng_up_automation()
  local sp = song.selected_parameter
  if ( sp ) then
    local ssi = song.selected_sequence_index
    local sti = song.selected_track_index
    local num = 0
    if ( vws.KNG_VB_AUTOMATION_SLOPES.value <= 64 ) then
      num = vws.KNG_VB_AUTOMATION_SLOPES.value -1
    else
      num = #song.sequencer.pattern_sequence -1
    end
    if ( KNG_AUTOMATION_L_R == false ) then    
      for seq = ssi, ssi + num do
        if ( seq <= #song.sequencer.pattern_sequence ) then
          local patt = song:pattern( seq )
          local spa = patt:track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              if ( point.value + 0.001 <= 1 ) then
                spa:add_point_at( point.time, point.value +0.001 )
              else
                spa:add_point_at( point.time, 1 )
              end
            end
          end
        end
      end
    else
      for seq = ssi -1, ssi - num, -1 do
        if ( seq >= 1 ) then
          local patt = song:pattern( seq )
          local spa = patt:track( sti ):find_automation( sp )
          if ( spa ) then
            for _,point in pairs( spa.points ) do
              if ( point.value + 0.001 <= 1 ) then
                spa:add_point_at( point.time, point.value +0.001 )
              else
                spa:add_point_at( point.time, 1 )
              end
            end
          end
        end
      end
    end
  end
end
---
function kng_down_automation_repeat( release )
  if not release then
    if rnt:has_timer( kng_down_automation_repeat ) then
      kng_down_automation()
      rnt:remove_timer( kng_down_automation_repeat )
      rnt:add_timer( kng_down_automation, 1 )
    else
      kng_down_automation()
      rnt:add_timer( kng_down_automation_repeat, 400 )
    end
  else
    if rnt:has_timer( kng_down_automation_repeat ) then
      rnt:remove_timer( kng_down_automation_repeat )
    elseif rnt:has_timer( kng_down_automation ) then
      rnt:remove_timer( kng_down_automation )
    end
  end
end
---
function kng_up_automation_repeat( release )
  if not release then
    if rnt:has_timer( kng_up_automation_repeat ) then
      kng_up_automation()
      rnt:remove_timer( kng_up_automation_repeat )
      rnt:add_timer( kng_up_automation, 1 )
    else
      kng_up_automation()
      rnt:add_timer( kng_up_automation_repeat, 400 )
    end
  else
    if rnt:has_timer( kng_up_automation_repeat ) then
      rnt:remove_timer( kng_up_automation_repeat )
    elseif rnt:has_timer( kng_up_automation ) then
      rnt:remove_timer( kng_up_automation )
    end
  end
end


--sense of the modification
KNG_AUTOMATION_L_R = false  --false = right, true = left
function kng_l_r_automation()
  if ( KNG_AUTOMATION_L_R == false ) then
    KNG_AUTOMATION_L_R = true
    vws.KNG_BT_AUTOMATION_SLOPES_L_R.bitmap = "/ico/mini_arrow_left_p_ico.png"
  else
    KNG_AUTOMATION_L_R = false
    vws.KNG_BT_AUTOMATION_SLOPES_L_R.bitmap = "/ico/mini_arrow_right_p_ico.png"
  end
end
