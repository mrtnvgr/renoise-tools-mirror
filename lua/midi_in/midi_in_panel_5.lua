--
-- MIDI_IN PANEL_5
--



-----------------------------------------------------------------------------------------------
--master, panic & unmark
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Master, Panic & Unmark:Master",
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_5( true, "GOLD_ON", 0,119 )
    else
      return pht_master_rel_5( false, "GOLD_OFF1", 0,119 )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Master, Panic & Unmark:Panic",
  invoke = function( message )
    if message:is_trigger() then
      return pht_panic_5( 0,119 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Master, Panic & Unmark:Unmark",
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_5( 0,119 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--multitouch name panel
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:MultiTouch:MultiTouch Panel",
  invoke = function( message )
    if message:is_trigger() then
      return pht_pln_name_multi( "_5" ), pht_mc_pnls_add_timer( "_5" )
    else
      return pht_mc_pnls_remove_timer( "_5" )
    end
  end
}



-----------------------------------------------------------------------------------------------
--all, sustaion & p/r
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Sustain Mode:Touch All Checkbox (ALL)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_5( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Sustain Mode:Sustain Checkbox (SUS)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_5( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Sustain Mode:Pressed & Released Checkbox (P/R)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_5( 3 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--track, instrument lock & anchor
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Track Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_trk_5()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Track Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_TRK_5.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_TRK_5.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Previous Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_prev_plug_pres_repeat_5()
    else
      return pht_prev_plug_pres_repeat_5( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Next Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_next_plug_pres_repeat_5()
    else
      return pht_next_plug_pres_repeat_5( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Plugin Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_show_plug_5()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Instrument Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_ins_5()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Instrument Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_INS_5.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_INS_5.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Unlock & Lock Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_lock_tr_ins_5()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Track & Instrument:Anchor Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_anchor_tr_ins_5()
    else
      return
    end
  end
}


-----------------------------------------------------------------------------------------------
--playback modes, O, P, M
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Playback Modes: Off Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_5( 3 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Playback Modes: Program Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_5( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Playback Modes: Keymap Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_5( 1 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose phrase
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Transpose Keymap:Transpose Phrase Down Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_5( -1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Transpose Keymap:Transpose Phrase Up Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_5( 1 )
    else
      return
    end
  end
}
---
local pht_trn_kym_phr_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Transpose Keymap:Transpose Phrase Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 25/128 )
      if ( pht_trn_kym_phr_pos_5 == vws.PHT_TRANS_PHRASE_5.value ) then
        vws.PHT_TRANS_PHRASE_5.value = val
      end
      pht_trn_kym_phr_pos_5 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose base note
local pht_trn_kym_bse_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Transpose Keymap:Transpose Base Note Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 120/128 )
      if ( pht_trn_kym_bse_pos_5 == vws.PHT_TRANS_NOTE_5.value ) then
        vws.PHT_TRANS_NOTE_5.value = val
      end
      pht_trn_kym_bse_pos_5 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--note volume slider
local pht_nte_vol_sld_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Volume:Note Volume Slider",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( pht_nte_vol_sld_pos_5 >= math.floor( vws.PHT_SLIDER_VOL_5.value -1 ) ) and ( pht_nte_vol_sld_pos_5 < math.floor( vws.PHT_SLIDER_VOL_5.value +1 ) ) then
        vws.PHT_SLIDER_VOL_5.value = val
      end
      pht_nte_vol_sld_pos_5 = val --soft takeover
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Volume:Note Volume Slider = 40",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_VOL_5.value = 64
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--instrument volume slider
local pht_ins_vol_sld_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Volume:Instrument Volume Slider",
  invoke = function( message )
    local val = math.floor( message.int_value * 199/127 )
    if message:is_abs_value() then
      if ( pht_ins_vol_sld_pos_5 >= math.floor( vws.PHT_SLIDER_INS_VOL_5.value -1 ) ) and ( pht_ins_vol_sld_pos_5 < vws.PHT_SLIDER_INS_VOL_5.value +1 ) then
        if ( val < 199 ) then
          vws.PHT_SLIDER_INS_VOL_5.value = val
        else
          vws.PHT_SLIDER_INS_VOL_5.value = 199.526 
        end
      end
      pht_ins_vol_sld_pos_5 = val --soft takeover
      --print ("message.int_value =", message.int_value)
      --print ( math.floor( message.int_value * 199/127 ) )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Volume:Instrument Volume Slider = 0.0 dB",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_5.value = 100
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Volume:Instrument Volume Slider = -INF",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_5.value = 0
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--chords popups & buttons
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Select Chords or Phrases Controls",
  invoke = function( message )
    if message:is_trigger() then
      return pht_cht_pnls_name_multi( "_5" ), pht_cht_pnls_add_timer( "_5" )
    else
      return pht_cht_pnls_remove_timer()
    end
  end
}
---
local pht_chd_sel_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Chords:Chord Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 60/128 + 1 )
      if ( pht_chd_sel_pos_5 == vws.PHT_PP_CHORDS_5.value ) then
        vws.PHT_PP_CHORDS_5.value = val
      end
      pht_chd_sel_pos_5 = val
    end
  end
}
---
local pht_chd_root_pos_5 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Chords:Root Note Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = 99 - math.floor( message.int_value * 99/128 ) --reverse
      if ( pht_chd_root_pos_5 == vws.PHT_PP_ROOT_5.value ) then
        vws.PHT_PP_ROOT_5.value = val
      end
      pht_chd_root_pos_5 = val
    end
  end
}
---
for i = 0, 8 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Panel_5:Chords:Root Note C-"..i.." Selector Button",
    invoke = function( message )
      if message:is_trigger() then
        return pht_select_chord_oct_5( 12 * i + 1 )
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
  name = "Tools:PhraseTouch:Panel_5:Octave "..i..":ON:On Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_5( true, "GOLD_ON", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Octave "..i..":OFF:Off Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_5( false, "GOLD_OFF1", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Octave "..i..":MARK:Mark Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_5( 12*i, 11 + 12*i )
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
  name = "Tools:PhraseTouch:Panel_5:Octave "..math.floor( i/12 )..":ON:"..( "On %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_pres_5( i )
    else
      return pht_osc_bt_sus_5( i )
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Octave "..math.floor( i/12 )..":OFF:"..( "Off %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_rel_5( i )
    else
      return 
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_5:Octave "..math.floor( i/12 )..":MARK:"..( "Mark %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_mark_5( i, 0, 11 )
    else
      return
    end
  end
}
end
