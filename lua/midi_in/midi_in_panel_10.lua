--
-- MIDI_IN PANEL_10
--



-----------------------------------------------------------------------------------------------
--master, panic & unmark
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Master, Panic & Unmark:Master",
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_10( true, "GOLD_ON", 0,119 )
    else
      return pht_master_rel_10( false, "GOLD_OFF1", 0,119 )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Master, Panic & Unmark:Panic",
  invoke = function( message )
    if message:is_trigger() then
      return pht_panic_10( 0,119 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Master, Panic & Unmark:Unmark",
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_10( 0,119 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--multitouch name panel
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:MultiTouch:MultiTouch Panel",
  invoke = function( message )
    if message:is_trigger() then
      return pht_pln_name_multi( "_10" ), pht_mc_pnls_add_timer( "_10" )
    else
      return pht_mc_pnls_remove_timer( "_10" )
    end
  end
}



-----------------------------------------------------------------------------------------------
--all, sustaion & p/r
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Sustain Mode:Touch All Checkbox (ALL)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_10( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Sustain Mode:Sustain Checkbox (SUS)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_10( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Sustain Mode:Pressed & Released Checkbox (P/R)",
  invoke = function( message )
    if message:is_trigger() then
      pht_asp_10( 3 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--track, instrument lock & anchor
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Track Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_trk_10()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Track Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_TRK_10.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_TRK_10.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Previous Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_prev_plug_pres_repeat_10()
    else
      return pht_prev_plug_pres_repeat_10( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Next Plugin Preset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_next_plug_pres_repeat_10()
    else
      return pht_next_plug_pres_repeat_10( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Plugin Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_show_plug_10()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Instrument Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_ins_10()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Instrument Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * ( vws.PHT_VB_SEL_INS_10.max + 1 )/128 )
      if ( val <= 128 ) then
        vws.PHT_VB_SEL_INS_10.value = val
      else
        return
      end
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Unlock & Lock Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_lock_tr_ins_10()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Track & Instrument:Anchor Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_anchor_tr_ins_10()
    else
      return
    end
  end
}


-----------------------------------------------------------------------------------------------
--playback modes, O, P, M
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Playback Modes: Off Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_10( 3 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Playback Modes: Program Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_10( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Playback Modes: Keymap Playback Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_off_prog_map_10( 1 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose phrase
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Transpose Keymap:Transpose Phrase Down Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_10( -1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Transpose Keymap:Transpose Phrase Up Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_transpose_phrase_10( 1 )
    else
      return
    end
  end
}
---
local pht_trn_kym_phr_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Transpose Keymap:Transpose Phrase Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 25/128 )
      if ( pht_trn_kym_phr_pos_10 == vws.PHT_TRANS_PHRASE_10.value ) then
        vws.PHT_TRANS_PHRASE_10.value = val
      end
      pht_trn_kym_phr_pos_10 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--transpose base note
local pht_trn_kym_bse_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Transpose Keymap:Transpose Base Note Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 120/128 )
      if ( pht_trn_kym_bse_pos_10 == vws.PHT_TRANS_NOTE_10.value ) then
        vws.PHT_TRANS_NOTE_10.value = val
      end
      pht_trn_kym_bse_pos_10 = val
    end
  end
}



-----------------------------------------------------------------------------------------------
--note volume slider
local pht_nte_vol_sld_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Volume:Note Volume Slider",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( pht_nte_vol_sld_pos_10 >= math.floor( vws.PHT_SLIDER_VOL_10.value -1 ) ) and ( pht_nte_vol_sld_pos_10 < math.floor( vws.PHT_SLIDER_VOL_10.value +1 ) ) then
        vws.PHT_SLIDER_VOL_10.value = val
      end
      pht_nte_vol_sld_pos_10 = val --soft takeover
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Volume:Note Volume Slider = 40",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_VOL_10.value = 64
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--instrument volume slider
local pht_ins_vol_sld_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Volume:Instrument Volume Slider",
  invoke = function( message )
    local val = math.floor( message.int_value * 199/127 )
    if message:is_abs_value() then
      if ( pht_ins_vol_sld_pos_10 >= math.floor( vws.PHT_SLIDER_INS_VOL_10.value -1 ) ) and ( pht_ins_vol_sld_pos_10 < vws.PHT_SLIDER_INS_VOL_10.value +1 ) then
        if ( val < 199 ) then
          vws.PHT_SLIDER_INS_VOL_10.value = val
        else
          vws.PHT_SLIDER_INS_VOL_10.value = 199.526 
        end
      end
      pht_ins_vol_sld_pos_10 = val --soft takeover
      --print ("message.int_value =", message.int_value)
      --print ( math.floor( message.int_value * 199/127 ) )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Volume:Instrument Volume Slider = 0.0 dB",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_10.value = 100
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Volume:Instrument Volume Slider = -INF",
  invoke = function( message )
    if message:is_trigger() then
      vws.PHT_SLIDER_INS_VOL_10.value = 0
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--chords popups & buttons
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Select Chords or Phrases Controls",
  invoke = function( message )
    if message:is_trigger() then
      return pht_cht_pnls_name_multi( "_10" ), pht_cht_pnls_add_timer( "_10" )
    else
      return pht_cht_pnls_remove_timer()
    end
  end
}
---
local pht_chd_sel_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Chords:Chord Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 60/128 + 1 )
      if ( pht_chd_sel_pos_10 == vws.PHT_PP_CHORDS_10.value ) then
        vws.PHT_PP_CHORDS_10.value = val
      end
      pht_chd_sel_pos_10 = val
    end
  end
}
---
local pht_chd_root_pos_10 = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Chords:Root Note Selector Popup",
  invoke = function( message )
    if message:is_abs_value() then
      local val = 99 - math.floor( message.int_value * 99/128 ) --reverse
      if ( pht_chd_root_pos_10 == vws.PHT_PP_ROOT_10.value ) then
        vws.PHT_PP_ROOT_10.value = val
      end
      pht_chd_root_pos_10 = val
    end
  end
}
---
for i = 0, 8 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Panel_10:Chords:Root Note C-"..i.." Selector Button",
    invoke = function( message )
      if message:is_trigger() then
        return pht_select_chord_oct_10( 12 * i + 1 )
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
  name = "Tools:PhraseTouch:Panel_10:Octave "..i..":ON:On Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_10( true, "GOLD_ON", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Octave "..i..":OFF:Off Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_master_10( false, "GOLD_OFF1", 12*i, 11 + 12*i )
    else
      return 
    end
  end
}
end
---
for i = 0, 9 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Octave "..i..":MARK:Mark Oct "..i,
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_10( 12*i, 11 + 12*i )
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
  name = "Tools:PhraseTouch:Panel_10:Octave "..math.floor( i/12 )..":ON:"..( "On %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_pres_10( i )
    else
      return pht_osc_bt_sus_10( i )
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Octave "..math.floor( i/12 )..":OFF:"..( "Off %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_osc_bt_rel_10( i )
    else
      return 
    end
  end
}
end
---
for i = 0, 119 do
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Panel_10:Octave "..math.floor( i/12 )..":MARK:"..( "Mark %s" ):format( pht_note_tostring( i ) ),
  invoke = function( message )
    if message:is_trigger() then
      return pht_mark_10( i, 0, 11 )
    else
      return
    end
  end
}
end
