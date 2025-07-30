--
-- MIDI_IN PANEL_8
--



-----------------------------------------------------------------------------------------------
--master, panic & unmark
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Master, Panic & Unmark:Master",
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_8( true, "GOLD_ON", 0,119 )
    else
      return pht_master_rel_8( false, "GOLD_OFF1", 0,119 )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Master, Panic & Unmark:Panic",
  invoke = function( message )
    if message:is_trigger() then
      return pht_panic_8( 0,119 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Master, Panic & Unmark:Unmark",
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_8( 0,119 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--multitouch name panel
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:MultiTouch:MultiTouch Panel",
  invoke = function( message )
    if message:is_trigger() then
      return pht_pln_name_multi( "_8" ), pht_mc_pnls_add_timer( "_8" )
    else
      return pht_mc_pnls_remove_timer( "_8" )
    end
  end
}



-----------------------------------------------------------------------------------------------
--all, sustaion & p/r
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Sustain Mode:Touch All Checkbox (ALL)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_8( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Sustain Mode:Sustain Checkbox (SUS)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_8( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Sustain Mode:Pressed & Released Checkbox (P/R)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_8( 3 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--track, instrument lock & anchor
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Track Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_trk_8()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Track Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_TRK_8.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_TRK_8.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Previous Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_prev_plug_pres_repeat_8()
    else
      return pht_prev_plug_pres_repeat_8( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Next Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_next_plug_pres_repeat_8()
    else
      return pht_next_plug_pres_repeat_8( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Plugin Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_show_plug_8()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Instrument Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_ins_8()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Instrument Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_INS_8.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_INS_8.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Unlock & Lock Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_lock_tr_ins_8()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Track & Instrument:Anchor Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_anchor_tr_ins_8()
    else
      return
    end
  end
}


-----------------------------------------------------------------------------------------------
--playback modes, O, P, M
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Playback Modes: Off Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_8( 3 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Playback Modes: Program Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_8( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Playback Modes: Keymap Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_8( 1 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose phrase
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Transpose Keymap:Transpose Phrase Down Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_8( -1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Transpose Keymap:Transpose Phrase Up Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_8( 1 )
    else
      return
    end
  end
}
---
local pht_trn_kym_phr_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Transpose Keymap:Transpose Phrase Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 25/128 )
      if ( pht_trn_kym_phr_pos_8 == vws.PHT_TRANS_PHRASE_8.value ) then
        vws.PHT_TRANS_PHRASE_8.value = val
      end
      pht_trn_kym_phr_pos_8 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose base note
local pht_trn_kym_bse_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Transpose Keymap:Transpose Base Note Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 120/128 )
      if ( pht_trn_kym_bse_pos_8 == vws.PHT_TRANS_NOTE_8.value ) then
        vws.PHT_TRANS_NOTE_8.value = val
      end
      pht_trn_kym_bse_pos_8 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--note volume slider
local pht_nte_vol_sld_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Volume:Note Volume Slider",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( pht_nte_vol_sld_pos_8 >= math.floor( vws.PHT_SLIDER_VOL_8.value -1 ) ) and ( pht_nte_vol_sld_pos_8 < math.floor( vws.PHT_SLIDER_VOL_8.value +1 ) ) then
        vws.PHT_SLIDER_VOL_8.value = val
      end
      pht_nte_vol_sld_pos_8 = val --soft takeover
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Volume:Note Volume Slider = 40",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_VOL_8.value = 64
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--instrument volume slider
local pht_ins_vol_sld_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Volume:Instrument Volume Slider",
  invoke = function( message )
    local val = math.floor( message.int_value * 199/127 )
    if message:is_abs_value() then
      if ( pht_ins_vol_sld_pos_8 >= math.floor( vws.PHT_SLIDER_INS_VOL_8.value -1 ) ) and ( pht_ins_vol_sld_pos_8 < vws.PHT_SLIDER_INS_VOL_8.value +1 ) then
        if ( val < 199 ) then
          vws.PHT_SLIDER_INS_VOL_8.value = val
        else
          vws.PHT_SLIDER_INS_VOL_8.value = 199.526 
        end
      end
      pht_ins_vol_sld_pos_8 = val --soft takeover
      --print ("message.int_value =", message.int_value)
      --print ( math.floor( message.int_value * 199/127 ) )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Volume:Instrument Volume Slider = 0.0 dB",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_8.value = 100
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Volume:Instrument Volume Slider = -INF",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_8.value = 0
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--chords popups & buttons
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Select Chords or Phrases Controls",
  invoke = function( message )
    if message:is_trigger() then
      return pht_cht_pnls_name_multi( "_8" ), pht_cht_pnls_add_timer( "_8" )
    else
      return pht_cht_pnls_remove_timer()
    end
  end
}
---
local pht_chd_sel_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Chords:Chord Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 60/128 + 1 )
      if ( pht_chd_sel_pos_8 == vws.PHT_PP_CHORDS_8.value ) then
        vws.PHT_PP_CHORDS_8.value = val
      end
      pht_chd_sel_pos_8 = val
    end
  end
}
---
local pht_chd_root_pos_8 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Chords:Root Note Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = 99 - math.floor( message.int_value * 99/128 ) --reverse
      if ( pht_chd_root_pos_8 == vws.PHT_PP_ROOT_8.value ) then
        vws.PHT_PP_ROOT_8.value = val
      end
      pht_chd_root_pos_8 = val
    end
  end
}
---
for i = 0, 8 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Panel_8:Chords:Root Note C-"..i.." Selector Button",
    invoke = function( message )
      if message:is_trigger() then
        return pht_select_chord_oct_8( 12 * i + 1 )
      else
        return
      end
    end
  }  
end



-----------------------------------------------------------------------------------------------
--oct x (0 to 9)
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..i..":ON:On Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_8( true, "GOLD_ON", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..i..":OFF:Off Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_8( false, "GOLD_OFF1", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..i..":MARK:Mark Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_8( 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end



-----------------------------------------------------------------------------------------------
--notes (0 to 119)
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..math.floor( i/12 )..":ON:"..( "On %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_pres_8( i )
    else
      return pht_osc_bt_sus_8( i )
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..math.floor( i/12 )..":OFF:"..( "Off %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_rel_8( i )
    else
      return 
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_8:Octave "..math.floor( i/12 )..":MARK:"..( "Mark %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_mark_8( i, 0, 11 )
    else
      return
    end
  end
}
end
