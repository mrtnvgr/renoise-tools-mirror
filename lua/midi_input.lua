--
-- midi_input
--



--pres rel pads
for nte_2 = 0, 119 do
  rnt:add_midi_mapping {
    name = ("Tools:KangarooX120:Pads:Pad %.3d"):format( nte_2 +1 ),
    invoke = function( message )
      if message:is_trigger() then
        kng_midi_in_pad_vol_restore( nte_2 )
        return kng_osc_bt_pad_pres( nte_2 )
      else
        return kng_osc_bt_pad_rel( nte_2 )
      end
    end
  }
end

--velocity knobs (1, 120)
local KNG_PAD_ROT_VEL_POS = {}
for pos = 0, 119 do
  KNG_PAD_ROT_VEL_POS[pos] = 0
end
--rprint( KNG_PAD_ROT_VEL_POS )
for nte_2 = 0, 119 do
  rnt:add_midi_mapping {
    name = ("Tools:KangarooX120:Pads:Velocity Knob %.3d"):format( nte_2 +1 ),
    invoke = function( message )
      if message:is_abs_value() then
        local val = message.int_value
        if ( KNG_PAD_ROT_VEL_POS[nte_2] > vws["KNG_PAD_ROT_VEL_"..nte_2].value -1 ) and
           ( KNG_PAD_ROT_VEL_POS[nte_2] < vws["KNG_PAD_ROT_VEL_"..nte_2].value +1 ) then
          vws["KNG_PAD_ROT_VEL_"..nte_2].value = val
        end
        KNG_PAD_ROT_VEL_POS[nte_2] = val --soft takeover
      else
        return
      end
    end
  }
end

--velocity knobs restart
local KNG_ROT_VEL_RESTART_ALL_POS = 0
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Pads:Velocity Knob Restart All",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( KNG_ROT_VEL_RESTART_ALL_POS > vws.KNG_ROT_VEL_RESTART_ALL.value -1 ) and
         ( KNG_ROT_VEL_RESTART_ALL_POS < vws.KNG_ROT_VEL_RESTART_ALL.value +1 ) then
        vws.KNG_ROT_VEL_RESTART_ALL.value = val
      end
      KNG_ROT_VEL_RESTART_ALL_POS = val --soft takeover
    else
      return
    end
  end
}

--grill to octaves 8+4 or 3x4 or white
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Pads:Grill to Octaves 8+4 / 3x4 / WHITE",
  invoke = function( message )
    if message:is_trigger() then
      if ( KNG_GRID_OCTAVES == 1 ) then
        return kng_grid_octaves( 2 )
      elseif ( KNG_GRID_OCTAVES == 2 ) then
        return kng_grid_octaves( 3 )
      else
        return kng_grid_octaves( 1 )
      end
      kng_nte_ini( vws.KNG_VB_NTE_SEL.value )
    else
      return
    end
  end
}

--panic pad
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Panic Pad",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_bt_panic()
    else
      return
    end
  end
}

--hold pad
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Mode Hold Pad",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_bt_sus_mode()
    else
      return
    end
  end
}

--hold chain pad
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Mode Hold Chain Pad",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_bt_sus_chain_mode()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--piano keys (1, 120)
for nte = 0, 119 do
  rnt:add_midi_mapping {
    name = ("Tools:KangarooX120:Piano Keys:Key %.3d  (%s)"):format( nte , kng_note_tostring( nte ) ),
    invoke = function( message )
      if message:is_trigger() then
        kng_midi_in_pno_vol_restore( nte )
        --print("nte", nte)
        return kng_osc_bt_pno_pres( nte )
      else
        return kng_osc_bt_pno_rel( nte )
      end
    end
  }
end

--piano jump octave 0 or 9
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Jump to Octave 0",
  invoke = function( message )
    if message:is_trigger() then
      return kng_piano_jump_0()
    else
      return
    end
  end
}
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Jump to Octave 9",
  invoke = function( message )
    if message:is_trigger() then
      return kng_piano_jump_9()
    else
      return
    end
  end
}

--piano jump octave to left or right
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Jump Octave to Left",
  invoke = function( message )
    if message:is_trigger() then
      return kng_piano_jump_l()
    else
      return
    end
  end
}
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Jump Octave to Right",
  invoke = function( message )
    if message:is_trigger() then
      return kng_piano_jump_r()
    else
      return
    end
  end
}

--key note off
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Key 120  (Note OFF)",
  invoke = function( message )
    if message:is_trigger() then
      return kng_note_off_empty( 120 )
    else
      return
    end
  end
}

--key note empty
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Keys:Key 121  (Note Empty)",
  invoke = function( message )
    if message:is_trigger() then
      return kng_note_off_empty( 121 )
    else
      return kng_pad_note_sel( 121 ), kng_jump_lines()
    end
  end
}

--piano velocity knob
local KNG_PNO_ROT_VEL_POS = 0
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Velocity Knob",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( KNG_PNO_ROT_VEL_POS > vws.KNG_PNO_ROT_VEL.value -1 ) and
         ( KNG_PNO_ROT_VEL_POS < vws.KNG_PNO_ROT_VEL.value +1 ) then
        vws.KNG_PNO_ROT_VEL.value = val
      end
      KNG_PNO_ROT_VEL_POS = val --soft takeover
    else
      return
    end
  end
}

--piano velocity knob pads panel control
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Velocity Knob for Pads Panel Control",
  invoke = function( message )
    if message:is_trigger() then
      return kng_midi_pad_ctrl()
    else
      return
    end
  end
}


rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Piano Velocity MIDI In Mode",
  invoke = function( message )
    if message:is_trigger() then
      return kng_midi_in_pno_mode()
    else
      return
    end
  end
}


--panic piano
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Panic Piano",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pno_bt_panic()
    else
      return
    end
  end
}

--hold piano
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Mode Hold Piano",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pno_bt_sus_mode()
    else
      return
    end
  end
}

--hold chain piano
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Mode Hold Chain Piano",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pno_bt_sus_chain_mode()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--select pad, transpose notes, select instrument, select track, select color style
local KNG_VB_PAD_SEL_POS = 0
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Select Number Pad",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 121/128 )
      if ( KNG_VB_PAD_SEL_POS > vws.KNG_VB_PAD_SEL.value -1 ) and
         ( KNG_VB_PAD_SEL_POS < vws.KNG_VB_PAD_SEL.value +1 ) then
      vws.KNG_VB_PAD_SEL.value = val
      end
      KNG_VB_PAD_SEL_POS = val --soft takeover
    else
      return
    end
  end
}
---
local KNG_VB_NTE_SEL_POS = 0
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Transpose Notes Pad",
  invoke = function( message )
    if ( KNG_NTE_SEL == true ) then
      if message:is_abs_value() then
        local val = math.floor( message.int_value * 121/128 )
        if ( KNG_VB_NTE_SEL_POS > vws.KNG_VB_NTE_SEL.value -1 ) and
           ( KNG_VB_NTE_SEL_POS < vws.KNG_VB_NTE_SEL.value +1 ) then        
          vws.KNG_VB_NTE_SEL.value = val
        end
        KNG_VB_NTE_SEL_POS = val --soft takeover
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Select Instrument",
  invoke = function( message )
    if message:is_abs_value() then
      if ( vws.KNG_VB_INS_SEL.max > 127 ) then
        vws.KNG_VB_INS_SEL.value = message.int_value
      else
        vws.KNG_VB_INS_SEL.value = math.floor( message.int_value * ( vws.KNG_VB_INS_SEL.max +1 )/128 )
      end
    elseif message:is_rel_value() then
      local sii = song.selected_instrument_index
      if message.int_value > 0 then
        if ( sii < #song.instruments ) then
          song.selected_instrument_index = sii +1
        end
      else
        if ( sii > 1 ) then
          song.selected_instrument_index = sii -1
        end
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Select Track",
  invoke = function( message )
    if message:is_abs_value() then
      if ( vws.KNG_VB_TRK_SEL.max > 127 ) then
        vws.KNG_VB_TRK_SEL.value = message.int_value
      else
        vws.KNG_VB_TRK_SEL.value = math.floor( message.int_value * ( vws.KNG_VB_TRK_SEL.max +1 )/128 )
      end
    elseif message:is_rel_value() then
      local sti = song.selected_track_index
      if message.int_value > 0 then
        if ( sti < #song.tracks ) then
          song.selected_track_index = sti +1
        end
      else
        if ( sti > 1 ) then
          song.selected_track_index = sti -1
        end
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Select Color Pad",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 15/128 ) +1
      vws.KNG_PAD_CLR.value = val
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--controls panel

--show pad
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Pads Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_show()
    else
      return
    end
  end
}

--change pad area
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Change Pad Area",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_visible_loop()
    else
      return
    end
  end
}

--show virtual piano
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Piano Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_piano_show()
    else
      return
    end
  end
}

--show velocity knobs
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Velocity Knobs",
  invoke = function( message )
    if message:is_trigger() then
      return kng_vel_rotary_show( 0, 119 )
    else
      return
    end
  end
}

--continuous pad selector
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Continuous Pad Selector",
  invoke = function( message )
    if message:is_trigger() then
      return kng_pad_note_sel_jump()
    else
      return
    end
  end
}

--velocity midi in
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Velocity MIDI In Mode for Pads Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_midi_in_pad_mode()
    else
      return
    end
  end
}

--pad instrument mode
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Pad Instrument Mode",
  invoke = function( message )
    if message:is_trigger() then
      return kng_ins_sel_pad_loop()
    else
      return
    end
  end
}

--pad track mode
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Pad Track Mode",
  invoke = function( message )
    if message:is_trigger() then
      return kng_trk_sel_pad_loop()
    else
      return
    end
  end
}

--split virtual piano
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Split Piano Mode",
  invoke = function( message )
    if message:is_trigger() then
      return kng_bt_split_piano()
    else
      return
    end
  end
}
---
local KNG_VB_SPLIT_PIANO_POS_1 = 0
local KNG_VB_SPLIT_PIANO_POS_2 = 0
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Split Note Selector to Piano to the Left",
  invoke = function( message )
    if ( KNG_SPLIT_PIANO_MODE == true ) then
      if message:is_abs_value() then
        local val = math.floor( message.int_value * 118/128 ) +2
        --print(val)
        if ( KNG_VB_SPLIT_PIANO_POS_1 > vws.KNG_VB_SPLIT_PIANO_1.value -1 ) and
           ( KNG_VB_SPLIT_PIANO_POS_1 < vws.KNG_VB_SPLIT_PIANO_1.value +1 ) then        
          vws.KNG_VB_SPLIT_PIANO_1.value = val
        end
        KNG_VB_SPLIT_PIANO_POS_1 = val --soft takeover
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Split Note Selector to Piano to the Right",
  invoke = function( message )
    if ( KNG_SPLIT_PIANO_MODE == true ) then
      if message:is_abs_value() then
        local val = math.floor( message.int_value * 118/128 ) +3
        --print(val)
        if ( KNG_VB_SPLIT_PIANO_POS_2 > vws.KNG_VB_SPLIT_PIANO_2.value -1 ) and
           ( KNG_VB_SPLIT_PIANO_POS_2 < vws.KNG_VB_SPLIT_PIANO_2.value +1 ) then        
          vws.KNG_VB_SPLIT_PIANO_2.value = val
        end
        KNG_VB_SPLIT_PIANO_POS_2 = val --soft takeover
      else
        return
      end
    end
  end
}

--jump lines step lenght
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Jump Lines Step Length",
  invoke = function( message )
    if message:is_trigger() then
      return kng_bt_jump_lines()
    else
      return
    end
  end
}

--show advanced operations panel
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Advanced Operations Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_operations_show()
    else
      return
    end
  end
}

--show preferences panel
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Preferences Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_preferences_show()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--banks

--show banks panel
rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Show Banks Panel",
  invoke = function( message )
    if message:is_trigger() then
      return kng_bank_show()
    else
      return
    end
  end
}

rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Banks:Show Banks 01-24",
  invoke = function( message )
    if message:is_trigger() then
      return kng_banks_sel( 1 )
    else
      return
    end
  end
}

rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Banks:Show Banks 25-48",
  invoke = function( message )
    if message:is_trigger() then
      return kng_banks_sel( 2 )
    else
      return
    end
  end
}

rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Banks:Show Banks 49-72",
  invoke = function( message )
    if message:is_trigger() then
      return kng_banks_sel( 3 )
    else
      return
    end
  end
}

rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Banks:Show Banks 73-96",
  invoke = function( message )
    if message:is_trigger() then
      return kng_banks_sel( 4 )
    else
      return
    end
  end
}

rnt:add_midi_mapping {
  name = "Tools:KangarooX120:Banks:Show Banks Loop 01-24 to 73-96",
  invoke = function( message )
    if message:is_trigger() then
      if ( vws.KNG_BANKS_1.visible == true ) then
        return kng_banks_sel( 2 )
      elseif ( vws.KNG_BANKS_2.visible == true ) then
        return kng_banks_sel( 3 )
      elseif ( vws.KNG_BANKS_3.visible == true ) then
        return kng_banks_sel( 4 )
      else
        return kng_banks_sel( 1 )
      end
    else
      return
    end
  end
}

--load banks
for val = 1, 96 do
  rnt:add_midi_mapping {
    name = ("Tools:KangarooX120:Banks:Load %.2d"):format( val ),
    invoke = function( message )
      if ( vws["KNG_BANK_BT_LOAD_"..val].active == true ) then
        if message:is_trigger() then
          vws["KNG_BANK_BT_LOAD_"..val].color = KNG_CLR.MARKER
          return 
        else
          vws["KNG_BANK_BT_LOAD_"..val].color = KNG_CLR.DEFAULT
          return kng_load_bank( val )
        end
      else
        return 
      end
    end
  }
end
