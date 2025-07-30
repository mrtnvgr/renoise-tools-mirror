----------------------
-- PAD PANEL_15      --
----------------------



-----------------------------------------------------------------------------------------------
--select track, selected, instrument, pressed, released & sustain for PHT OSC Server
pht_table_release_15 = {
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 0
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 1
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 2
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 3
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 4
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 5
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 6
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 7
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 8
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 9
}
---
function pht_table_rel_restore_15( val_a, val_b )
  for i = val_a, val_b do
    pht_table_release_15[ i + 1 ] = false
  end
end
---
local pht_sel_ins_pos_15 = 0
function pht_sel_ins_15()
  vws.PHT_VB_SEL_INS_15.max = #song.instruments
  local sii = song.selected_instrument_index
  local val = vws.PHT_VB_SEL_INS_15.value
  local ins_15
  if ( val == 0 ) then
    ins_15 = sii
  else
    if ( val > #song.instruments ) then
      ins_15 = sii
      if ( val ~= sii ) then
        vws.PHT_VB_SEL_INS_15.value = sii
      end
    else
      ins_15 = val
      if ( PHT_ANCHOR_15 == true ) then
        if ( pht_sel_ins_pos_15 == song.selected_instrument_index ) then
          song.selected_instrument_index = val
        end
        pht_sel_ins_pos_15 = val --soft takeover
      end
    end
  end
  return ins_15
end
---
local pht_sel_trk_pos_15 = 0
function pht_sel_trk_15()
  vws.PHT_VB_SEL_TRK_15.max = song.sequencer_track_count --#song.tracks
  local stc = song.sequencer_track_count
  local val = vws.PHT_VB_SEL_TRK_15.value
  local tr_15
  if ( val == 0 ) then
    tr_15 = song.selected_track_index
  else
    if ( val > stc ) then --#song.tracks
      tr_15 = stc
      if ( val ~= stc ) then
        vws.PHT_VB_SEL_TRK_15.value = stc
      end
    else
      tr_15 = val
      if ( PHT_ANCHOR_15 == true ) then
        if ( pht_sel_trk_pos_15 == song.selected_track_index ) then
          song.selected_track_index = val
        end
        pht_sel_trk_pos_15 = val --soft takeover
      end
    end
  end
  return tr_15
end
---
function pht_osc_bt_pres_15( nte_15 )
  local ins_15 = pht_sel_ins_15()
  local tr_15 = pht_sel_trk_15()
  local vel_15 = vws.PHT_SLIDER_VOL_15.value
  pht_change_button_color_15( nte_15 )
  if ( PHT_ASP_15[1] == false ) then
    for i = 0, 119 do  
      pht_osc_client:trigger_instrument( false, ins_15, tr_15, i )
    end
    if ( PHT_ASP_15[3] == true ) then
      if ( pht_table_release_15[ nte_15 + 1 ] == true ) then
        pht_osc_bt_rel_15( nte_15 )
        pht_table_release_15[ nte_15 + 1 ] = false
      else    
        pht_osc_client:trigger_instrument( true, ins_15, tr_15, nte_15, vel_15 )
        for i = 0, 119 do
          if ( i ~= nte_15 ) then
            pht_table_release_15[ i + 1 ] = false
          else
            pht_table_release_15[ i + 1 ] = true
          end
        end
      end
    else
      pht_osc_client:trigger_instrument( true, ins_15, tr_15, nte_15, vel_15 )
    end
  else
    pht_osc_client:trigger_instrument( false, ins_15, tr_15, nte_15 )
    if ( PHT_ASP_15[3] == true ) then
      if ( pht_table_release_15[ nte_15 + 1 ] == true ) then
        pht_osc_bt_rel_15( nte_15 )
        pht_table_release_15[ nte_15 + 1 ] = false
      else    
        pht_osc_client:trigger_instrument( true, ins_15, tr_15, nte_15, vel_15 )
        pht_table_release_15[ nte_15 + 1 ] = true
      end
    else
      pht_osc_client:trigger_instrument( true, ins_15, tr_15, nte_15, vel_15 )
    end
  end
  --phrase name keymapped
  pht_phrase_keymapped_15( ins_15, nte_15 )
  --favtouch32 panel
  if ( PHT_ASP_15[2] == true ) then 
    pht_fav_tabs( ins_15, tr_15, nte_15 )
  end
  --multi_pressed-------------------------------------<<
  --pht_multi_pressed( nte_15, ins_15, tr_15 )--multi
end
---
function pht_osc_bt_rel_15( nte_15 )
  local ins_15 = pht_sel_ins_15()
  local tr_15 = pht_sel_trk_15()
  --off note sound
  if ( PHT_ASP_15[3] == false ) then
    pht_osc_client:trigger_instrument( false, ins_15, tr_15, nte_15 )
  end
  pht_change_button_color_off_15( nte_15 )
  --favtouch32 panel
  if ( PHT_ASP_15[2] == false ) then  
    pht_fav_tabs( ins_15, tr_15, nte_15 )
  end
  --multi_released------------------------------------<<
  --pht_multi_released( nte_15, ins_15, tr_15  )--multi
end
---
function pht_osc_bt_sus_15( nte_15 )
  if ( PHT_ASP_15[2] == false ) then
    pht_osc_bt_rel_15( nte_15 )
  end
  --multi_sustain-------------------------------------<<
  --local ins_15, tr_15 = pht_sel_ins_15(), pht_sel_trk_15()
  --pht_multi_sustain( nte_15, ins_15, tr_15 )--multi
end



-------------------------------------------------------------------------------------------------
--mark table & master
pht_table_mark_15 = {
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 0
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 1
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 2
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 3
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 4
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 5
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 6
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 7
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 8
  false, false, false, false, false, false, false, false, false, false, false, false, --oct 9
}
---
function pht_mark_15( iter, val_a, val_b )
  for i = val_a, val_b do
    if ( i == iter ) then
      if ( pht_table_mark_15[ i + 1 ] == false ) then
        pht_table_mark_15[ i + 1 ] = true
        vws["PHT_NTE_MRK_BTT_15_"..i].color = PHT_MAIN_COLOR.GREY_ON
        --return
        else
        pht_table_mark_15[ i + 1 ] = false
        vws["PHT_NTE_MRK_BTT_15_"..i].color = PHT_MAIN_COLOR.GREY_OFF
      end
    end
  end
  --rprint(pht_table_mark_15)
end
---
function pht_master_15( bool, clr, val_a, val_b )
  local ins_15 = pht_sel_ins_15()
  local tr_15 = pht_sel_trk_15()
  local vel_15 = vws.PHT_SLIDER_VOL_15.value
  --on all marked notes of selected intrument
  for i = val_a, val_b do
    if ( pht_table_mark_15[ i + 1 ] == true ) then
      pht_osc_client:trigger_instrument( bool, ins_15, tr_15, i, vel_15 )
      vws["PHT_NTE_ON_BTT_15_"..i].color = PHT_MAIN_COLOR[clr]
    end
  end
end
---
function pht_master_rel_15( bool, clr, val_a, val_b )
  if ( PHT_ASP_15[2] == false ) then
    pht_master_15( bool, clr, val_a, val_b )
  end
end



-------------------------------------------------------------------------------------------------     
--master panic and unmark
local PHT_MST_PNC_UMK_15 = vb:row { spacing = -3,
  vb:button {
    id = "PHT_GNL_MST_15",
    height = 25,
    width = 56,
    color = PHT_MAIN_COLOR.GOLD_OFF2,
    pressed = function() pht_master_15( true, "GOLD_ON", 0,119 ) end,
    released = function() pht_master_rel_15( false, "GOLD_OFF1", 0,119 ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Master, Panic & Unmark:Master",
    text = "Master",
    tooltip = "General master playback of the selected notes\nUse before the note selectors to mark. Combine it with the 'Sustain' checkbox"
  },
  vb:row { spacing = -2,
    vb:button {
      id = "PHT_GNL_PNC_15",
      height = 25,
      width = 47,
      color = PHT_MAIN_COLOR.RED_OFF_15,
      pressed = function() pht_panic_15( 0,119 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Master, Panic & Unmark:Panic",
      text = "Panic",
      tooltip = "General panic for this panel\n[Ctrl + F1 to F12]"
    },
    vb:button {
      id = "PHT_GNL_UMK_15",
      height = 25,
      width = 15,
      color = PHT_MAIN_COLOR.GREY_OFF,
      pressed = function() pht_unmark_15( 0,119 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Master, Panic & Unmark:Unmark",
      text = "",
      tooltip = "General unmark for this panel"
    }
  }
}
---
function pht_panic_15( val_a, val_b )
  local ins_15 = pht_sel_ins_15()
  local tr_15 = pht_sel_trk_15()
  local vel_15 = vws.PHT_SLIDER_VOL_15.value
  for i = val_a, val_b do
    pht_osc_client:trigger_instrument( false, ins_15, tr_15, i, vel_15 )
    vws["PHT_NTE_ON_BTT_15_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1
  end
  pht_table_rel_restore_15( val_a, val_b )
end
---
function pht_unmark_15( val_a, val_b )
  for i = val_a, val_b do
    pht_table_mark_15[ i + 1 ] = false
    vws["PHT_NTE_MRK_BTT_15_"..i].color = PHT_MAIN_COLOR.GREY_OFF
  end
end



-------------------------------------------------------------------------------------------------
--change button color
function pht_change_button_color_15( value )
  for i = 0,119 do
    if ( i == value ) then
      vws["PHT_NTE_ON_BTT_15_"..i].color = PHT_MAIN_COLOR.GOLD_ON --on
    else
      if ( PHT_ASP_15[1] == false ) then
        vws["PHT_NTE_ON_BTT_15_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1 --off
      end
    end
  end
end 
---
function pht_change_button_color_off_15( value )
  vws["PHT_NTE_ON_BTT_15_"..value].color = PHT_MAIN_COLOR.GOLD_OFF1 --off
end 



-------------------------------------------------------------------------------------------------
--touch all, sustain &, pressed/released
function pht_sustain_mode_15( value )
  if ( value == false ) then
    if ( PHT_ASP_15[3] == true ) then
      vws.PHT_BT_ASP_X3_15.color = PHT_MAIN_COLOR.DEFAULT
      PHT_ASP_15[3] = false
      vws.PHT_BT_ASP_X1_15.active = false
    end
    ---
    for i = 0,119 do
      vws["PHT_NTE_OFF_BTT_15_"..i].width = pht_width_bt_off - 12
      vws["PHT_NTE_ON_BTT_15_"..i].width = pht_width_bt_on + 12
      vws["PHT_NTE_OFF_BTT_15_"..i].active = false
    end
    ---
    for oct = 0, 9 do
      vws["PHT_MST_OFF_BTT_15_"..oct].width = pht_width_bt_off - 12
      vws["PHT_MST_ON_BTT_15_"..oct].width = pht_width_bt_on + 12
      vws["PHT_MST_OFF_BTT_15_"..oct].active = false
    end
    ---
    vws.PHT_GNL_PNC_15.text = ""
    vws.PHT_GNL_PNC_15.width = 47 - 37
    vws.PHT_GNL_MST_15.width = 56 + 37
    vws.PHT_GNL_PNC_15.active = false
  else
    ---
    for i = 0,119 do
      vws["PHT_NTE_ON_BTT_15_"..i].width = pht_width_bt_on
      vws["PHT_NTE_OFF_BTT_15_"..i].width = pht_width_bt_off
      vws["PHT_NTE_OFF_BTT_15_"..i].active = true
    end
    ---
    for oct = 0, 9 do
      vws["PHT_MST_ON_BTT_15_"..oct].width = pht_width_bt_on
      vws["PHT_MST_OFF_BTT_15_"..oct].width = pht_width_bt_off
      vws["PHT_MST_OFF_BTT_15_"..oct].active = true
    end
    ---
    vws.PHT_GNL_MST_15.width = 56
    vws.PHT_GNL_PNC_15.width = 47
    vws.PHT_GNL_PNC_15.text = "Panic"
    vws.PHT_GNL_PNC_15.active = true
  end
end
---
function pht_pres_rel_mode_15( value )
  if ( value == true ) then
    if ( PHT_ASP_15[2] == false ) then
      vws.PHT_BT_ASP_X2_15.color = PHT_MAIN_COLOR.GOLD_ON
      PHT_ASP_15[2] = true
    end
    ---
    for i = 0,119 do
      vws["PHT_NTE_OFF_BTT_15_"..i].width = pht_width_bt_off - 12
      vws["PHT_NTE_ON_BTT_15_"..i].width = pht_width_bt_on + 12
      vws["PHT_NTE_OFF_BTT_15_"..i].active = false
    end
    ---
    for oct = 0, 9 do
      vws["PHT_MST_ON_BTT_15_"..oct].width = pht_width_bt_on
      vws["PHT_MST_OFF_BTT_15_"..oct].width = pht_width_bt_off
      vws["PHT_MST_OFF_BTT_15_"..oct].active = true
    end
    ---
    vws.PHT_GNL_MST_15.width = 56
    vws.PHT_GNL_PNC_15.width = 47
    vws.PHT_GNL_PNC_15.text = "Panic"
    vws.PHT_GNL_PNC_15.active = true
    ---
  else
    ---
    for i = 0,119 do
      vws["PHT_NTE_ON_BTT_15_"..i].width = pht_width_bt_on
      vws["PHT_NTE_OFF_BTT_15_"..i].width = pht_width_bt_off
      vws["PHT_NTE_OFF_BTT_15_"..i].active = true
    end
  end
end
---
PHT_ASP_15 = { false, true, false }
function pht_asp_15( value )
  if ( PHT_ASP_15[value] == false ) then
    PHT_ASP_15[value] = true
    vws["PHT_BT_ASP_X"..value.."_15"].color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_BT_ASP_X1_15.active = true
  else
    PHT_ASP_15[value] = false
    vws["PHT_BT_ASP_X"..value.."_15"].color = PHT_MAIN_COLOR.DEFAULT
  end
  if ( PHT_ASP_15[2] == false ) and ( PHT_ASP_15[3] == false ) then
    vws.PHT_BT_ASP_X1_15.active = false
  end
end
---
local PHT_SUS_TOU_15 = vb:row { spacing = -1,
  vb:button {
    id = "PHT_BT_ASP_X1_15",
    height = 25,
    width = 35,
    text = "ALL",
    pressed = function() pht_asp_15( 1 ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Sustain Mode:Touch All Checkbox (ALL)",
    tooltip = "Touch All Mode\nTouch all the keys for this panel without stopping those already played.\nCombine it with the 'SUS' &/or 'P/R' checkbox"
  },
  vb:row { spacing = -3,
    vb:button {
      id = "PHT_BT_ASP_X2_15",
      height = 25,
      width = 35,
      text = "SUS",
      color = PHT_MAIN_COLOR.GOLD_ON,
      pressed = function() pht_asp_15( 2 ) pht_sustain_mode_15( PHT_ASP_15[2] ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Sustain Mode:Sustain Checkbox (SUS)",
      tooltip = "Sustain Mode\nSustain the key recently pressed and stop the rest for this panel\nCombine it with the 'ALL' &/or 'P/R' checkbox"
    },    
    vb:button {
      id = "PHT_BT_ASP_X3_15",
      height = 25,
      width = 35,
      text = "P/R",
      pressed = function() pht_asp_15( 3 ) pht_pres_rel_mode_15( PHT_ASP_15[3] ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Sustain Mode:Pressed & Released Checkbox (P/R)",
      tooltip = "Pressed & Released for Sustain Mode\nPress and release with the same key for this panel. Recommended for MIDI Pads!\nSUS checkbox must be activated! Combine it with the 'ALL' checkbox"
    }
  }
}


-------------------------------------------------------------------------------------------------
--track selected
function pht_tostring_track_15( number )
  if ( number == 0 ) then
    return "SEL"
  else
    return ("%.3d"):format( number )
  end
end
---
function pht_tonumber_track_15( string )
  if ( string == "SEL" ) or ( string == "sel" ) or ( string == "S" ) or ( string == "s" ) then
    return 0
  else
    return tonumber( string )
  end
end
---
function pht_anchor_track_15( value )
  if ( value == 0 ) then
    vws.PHT_BT_SEL_TRK_15.active = false
  elseif ( PHT_ANCHOR_15 == true ) then
    vws.PHT_BT_SEL_TRK_15.active = true 
  end
end
---
local PHT_SEL_TRK_15 = vb:row { spacing = -3,
  vb:button {
    id = "PHT_BT_SEL_TRK_15",
    active = false,
    height = 25,
    width = 39,
    bitmap = "./ico/track_ico.png",
    notifier = function() pht_sel_trk_15() end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Track Button",
    tooltip = "Jump to the chosen track if anchor is enabled"
  },
  vb:valuebox {
    id = "PHT_VB_SEL_TRK_15",
    height = 25,
    width = 54,
    min = 0,
    max = 999,
    value = 0,
    tostring = function( number ) return pht_tostring_track_15( number ) end,
    tonumber = function( string ) return pht_tonumber_track_15( string ) end,
    notifier = function( value ) pht_sel_trk_15() pht_anchor_track_15( value ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Track Selector Valuebox",
    tooltip = "Choose a track number\n[ SEL = default selected track ]"
  }
}



-------------------------------------------------------------------------------------------------
--plugin & instrument selected
function pht_prev_plug_pres_repeat_15( release )
  if not release then
    if rnt:has_timer( pht_prev_plug_pres_repeat_15 ) then
      pht_prev_plug_pres_15()
      rnt:remove_timer( pht_prev_plug_pres_repeat_15 )
      if not rnt:has_timer( pht_prev_plug_pres_15 ) then
        rnt:add_timer( pht_prev_plug_pres_15, 50 )
      end
    else
      pht_prev_plug_pres_15()
      if not rnt:has_timer( pht_prev_plug_pres_repeat_15 ) then
        rnt:add_timer( pht_prev_plug_pres_repeat_15, 300 )
      end
    end
  else
    if rnt:has_timer( pht_prev_plug_pres_repeat_15 ) then
      rnt:remove_timer( pht_prev_plug_pres_repeat_15 )
    elseif rnt:has_timer( pht_prev_plug_pres_15 ) then
      rnt:remove_timer( pht_prev_plug_pres_15 )
    end
  end
end
---
function pht_next_plug_pres_repeat_15( release )
  if not release then
    if rnt:has_timer( pht_next_plug_pres_repeat_15 ) then
      pht_next_plug_pres_15()
      rnt:remove_timer( pht_next_plug_pres_repeat_15 )
      if not rnt:has_timer( pht_next_plug_pres_15 ) then
        rnt:add_timer( pht_next_plug_pres_15, 50 )
      end
    else
      pht_next_plug_pres_15()
      if not rnt:has_timer( pht_next_plug_pres_repeat_15 ) then
        rnt:add_timer( pht_next_plug_pres_repeat_15, 300 )
      end
    end
  else
    if rnt:has_timer( pht_next_plug_pres_repeat_15 ) then
      rnt:remove_timer( pht_next_plug_pres_repeat_15 )
    elseif rnt:has_timer( pht_next_plug_pres_15 ) then
      rnt:remove_timer( pht_next_plug_pres_15 )
    end
  end
end
---
function pht_prev_plug_pres_15()
  local plug = song:instrument(pht_sel_ins_15()).plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset - 1 > 0 ) then
      plug.active_preset = plug.active_preset - 1
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    else
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    end
  else
    pht_change_status( "No plugin loaded / No programs available!" )
  end
end
---
function pht_next_plug_pres_15()
  local plug = song:instrument(pht_sel_ins_15()).plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset + 1 <= #plug.presets ) then
      plug.active_preset = plug.active_preset + 1
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    else
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    end
  else
    pht_change_status( "No plugin loaded / No programs available!" )
  end
end
---
function pht_show_plug_15()
  local value = vws.PHT_VB_SEL_INS_15.value
  if ( value ~= 0 ) then
    local plp = song:instrument(value).plugin_properties.plugin_device
    if ( plp ~= nil ) then
      if ( plp.external_editor_visible == false ) then
        plp.external_editor_visible = true
      else
        plp.external_editor_visible = false
      end
    end
  end
end
---
function pht_tostring_ins_15( number )
  if ( number == 0 ) then
    return "SEL"
  else
    return ("%.02X"):format( number - 1 )
  end
end
---
function pht_anchor_ins_15( value )
  if ( value == 0 ) then
    vws.PHT_BT_SEL_PLUG_15.active = false
    vws.PHT_BT_SEL_PREV_PLUG_PRES_15.active = false
    vws.PHT_BT_SEL_NEXT_PLUG_PRES_15.active = false
    vws.PHT_BT_SEL_INS_15.active = false
  else
    vws.PHT_BT_SEL_PLUG_15.active = true
    vws.PHT_BT_SEL_PREV_PLUG_PRES_15.active = true
    vws.PHT_BT_SEL_NEXT_PLUG_PRES_15.active = true
    if ( PHT_ANCHOR_15 == true ) then
      vws.PHT_BT_SEL_INS_15.active = true
    end
  end
end
---
function pht_tonumber_ins_15( string )
  if ( string == "SEL" ) or ( string == "sel" ) or ( string == "S" ) or ( string == "s" ) then
    return 0
  else
    return tonumber( string, 16 ) + 1
  end
end
---
local PHT_SEL_INS_15 = vb:row { spacing = -3,
  vb:column { spacing = -3,
    vb:button {
      id = "PHT_BT_SEL_PREV_PLUG_PRES_15",
      active = false,
      height = 14,
      width = 23,
      bitmap = "./ico/mini_up_ico.png",
      pressed = function() pht_prev_plug_pres_repeat_15() end,
      released = function() pht_prev_plug_pres_repeat_15( true ) end,
      --notifier = function() pht_prev_plug_pres_15() end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Previous Plugin Preset Button",
      tooltip = "Previous plugin preset of the choosen instrument"
    },
    vb:button {
      id = "PHT_BT_SEL_NEXT_PLUG_PRES_15",
      active = false,
      height = 14,
      width = 23,
      bitmap = "./ico/mini_down_ico.png",
      pressed = function() pht_next_plug_pres_repeat_15() end,
      released = function() pht_next_plug_pres_repeat_15( true ) end,
      --notifier = function() pht_next_plug_pres_15() end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Next Plugin Preset Button",
      tooltip = "Next plugin preset of the choosen instrument"
    }
  },
  vb:button {
    id = "PHT_BT_SEL_PLUG_15",
    active = false,
    height = 25,
    width = 31,
    bitmap = "./ico/plugin_ico.png",
    notifier = function() pht_show_plug_15() end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Plugin Button",
    tooltip = "Show/Hide the Plugin External Editor (if exist) of the chosen instrument"
  },
  vb:space { width = 5 },
  vb:button {
    id = "PHT_BT_SEL_INS_15",
    active = false,
    height = 25,
    width = 39,
    bitmap = "./ico/instrument_ico.png",
    notifier = function() pht_sel_ins_15() end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Instrument Button",
    tooltip = "Jump to the chosen instrument if anchor is enabled"
  },
  vb:valuebox {
    id = "PHT_VB_SEL_INS_15",
    height = 25,
    width = 54,
    min = 0,
    max = 255,
    value = 0,
    tostring = function( number ) return pht_tostring_ins_15( number ) end,
    tonumber = function( string ) return pht_tonumber_ins_15( string ) end,
    notifier = function( value ) pht_sel_ins_15() pht_anchor_ins_15( value ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Instrument Selector Valuebox",
    tooltip = "Choose a instrument number\n[ SEL = default selected instrument ]"
  }
}



-------------------------------------------------------------------------------------------------
--lock unlock track & instrument selected
function pht_lock_tr_ins_15()
  if ( vws.PHT_VB_SEL_TRK_15.active == true ) then
    vws.PHT_VB_SEL_TRK_15.active = false
    vws.PHT_VB_SEL_INS_15.active = false
    vws.PHT_LOCK_TR_INS_15.bitmap = "./ico/padlock_close_ico.png"
    vws.PHT_LOCK_TR_INS_15.color = PHT_MAIN_COLOR.GOLD_ON
  else
    vws.PHT_VB_SEL_TRK_15.active = true
    vws.PHT_VB_SEL_INS_15.active = true
    vws.PHT_LOCK_TR_INS_15.bitmap = "./ico/padlock_open_ico.png"
    vws.PHT_LOCK_TR_INS_15.color = PHT_MAIN_COLOR.DEFAULT
  end
end
---
local PHT_LOCK_TR_INS_15 = vb:button {
  id = "PHT_LOCK_TR_INS_15",
  height = 25,
  width = 28,
  bitmap = "./ico/padlock_open_ico.png",
  notifier = function() pht_lock_tr_ins_15() end,
  midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Unlock & Lock Checkbox",
  tooltip = "Lock/Unlock the valueboxes for track & instrument selector\nLock it for greater security when playing"
}



-------------------------------------------------------------------------------------------------
--anchor the track & the instrument
PHT_ANCHOR_15 = false
function pht_anchor_tr_ins_15()
  if ( PHT_ANCHOR_15 == false ) then
    PHT_ANCHOR_15 = true
    vws.PHT_ANCHOR_TR_INS_15.bitmap = "./ico/anchor_true_ico.png"
    vws.PHT_ANCHOR_TR_INS_15.color = PHT_MAIN_COLOR.GOLD_ON
    if ( vws.PHT_VB_SEL_TRK_15.value ~= 0 ) then
      vws.PHT_BT_SEL_TRK_15.active = true
    end
    if ( vws.PHT_VB_SEL_INS_15.value ~= 0 ) then
      vws.PHT_BT_SEL_INS_15.active = true
    end
  else
    PHT_ANCHOR_15 = false
    vws.PHT_ANCHOR_TR_INS_15.bitmap = "./ico/anchor_false_ico.png"
    vws.PHT_ANCHOR_TR_INS_15.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_BT_SEL_TRK_15.active = false
    vws.PHT_BT_SEL_INS_15.active = false
  end
end
---
PHT_ANCHOR_TR_INS_15 = vb:button {
  id = "PHT_ANCHOR_TR_INS_15",
  height = 25,
  width = 28,
  bitmap = "./ico/anchor_false_ico.png",
  notifier = function() pht_anchor_tr_ins_15() end,
  midi_mapping = "Tools:PhraseTouch:Panel_15:Track & Instrument:Anchor Checkbox",
  tooltip = "Anchor the track & the instrument\nDisable it for prevents the automatic selection of the track & instrument"
}



-------------------------------------------------------------------------------------------------     
--chord-phrase selector
PHT_CHD_PHR_BT_15 = vb:button {
  id = "PHT_CHD_PHR_BT_15",
  height = 25,
  width = 28,
  bitmap = "./ico/sol_ico.png",
  pressed = function() pht_cht_pnls_name_multi( "_15" ) pht_cht_pnls_add_timer( "_15" ) end,
  released = function() pht_cht_pnls_remove_timer() end,
  midi_mapping = "Tools:PhraseTouch:Panel_15:Select Chords or Phrases Controls",
  tooltip = PHT_CHD_PNL_TOOLTIP
}



-------------------------------------------------------------------------------------------------     
--phrase name keymapped
function pht_phrase_keymapped_15( ins_15, nte_15 )
  vws.PHT_PHRASE_NAME_15.text = "Phrase n/a"
  local inst = song:instrument( ins_15 )
  for i = 1, #inst.phrases do
    if ( inst:phrase( i ).mapping ~= nil ) then
      local note_tab = inst:phrase( i ).mapping.note_range
      if ( nte_15 >= note_tab[ 1 ] ) and ( nte_15 <= note_tab[ 2 ] ) then
        vws.PHT_PHRASE_IDX_15.value = i
        vws.PHT_PHRASE_NAME_15.text = string.sub( inst:phrase( i ).name, 1, 22 ) --range of characters to name (1 to 22)
        --change valuebox transpose note
        pht_vb_trans_note_15( ins_15 )
        return
      end
    end
  end
end
---
function pht_phrase_idx_15( value )
  if ( song.selected_phrase_index > 0 ) and ( value <= #song.selected_instrument.phrases ) then
    song.selected_phrase_index = value
  end
end
---
local PHT_KEY_PHR_15 = vb:row { margin = 1,
  vb:row { spacing = 2,
    vb:row {
      style = "plain",
        vb:valuefield {
        id = "PHT_PHRASE_IDX_15",
        height = 23,
        width = 27,
        min = 0,
        max = 126,
        value = 0,
        align = "center",
        tostring = function( value ) return ( "%.02X" ):format( value ) end,
        tonumber = function( value ) return tonumber( value, 16 ) end,
        notifier = function( value ) pht_phrase_idx_15( value ) end,
        tooltip = "Selected phrase index\nInsert a number to select your phrase\n[ Range: 01 to 7E, 126 values ]"
      }
    },
    vb:row {
      style = "plain",
      tooltip = "Selected phrase name",
      vb:text {
        id = "PHT_PHRASE_NAME_15",
        height = 23,
        width = 142,
        align = "center",
        text = "Phrase Name",
      }
    }
  }
}



-------------------------------------------------------------------------------------------------
--keymap, program & off
function pht_off_prog_map_15( value )
  local inst = song:instrument( pht_sel_ins_15() )
  if ( value == 1 ) then
    inst.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
    pht_change_status( "Playback mode = \"Keymap\" (play multiple phrases)" )
  elseif ( value == 2 ) then    
    inst.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_SELECTIVE
    pht_change_status( "Playback mode = \"Program\" (play a phrase)" )
  else 
    inst.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
    pht_change_status( "Playback mode = \"Off\" (disable phrases)" )
  end
end
---
local PHT_OFF_PROG_MAP_15 = vb:row { spacing = -3,
  vb:button {
    height = 25,
    width = 19,
    notifier = function() pht_off_prog_map_15( 1 ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Playback Modes: Keymap Playback Mode Button",
    bitmap = "./ico/k_ico.png", --text = "K",
    tooltip = "Keymap playback mode to phrases for this panel (play multiple phrases)"
  },
  vb:column { spacing = -3,
    vb:button {
      height = 14,
      width = 21,
      notifier = function() pht_off_prog_map_15( 2 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Playback Modes: Program Playback Mode Button",
      bitmap = "./ico/p_ico.png", --text = "P",
      tooltip = "Program playback mode to phrases for this panel (play a phrase)"
    },
    vb:button {
      height = 14,
      width = 21,
      notifier = function() pht_off_prog_map_15( 3 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Playback Modes: Off Playback Mode Button",
      bitmap = "./ico/o_ico.png", --text = "O",
      tooltip = "Off playback mode to phrases for this panel (disable phrases)"
    }
  }
}



-------------------------------------------------------------------------------------------------
--transpose phrase
function pht_transpose_phrase_15( multi )
  pht_sel_ins_15()
  local value = vws.PHT_TRANS_PHRASE_15.value
  local sph = song.selected_phrase
  local sphi = song.selected_phrase_index
  local inst = song:instrument( pht_sel_ins_15() )
  if ( sph ~= nil ) and ( sphi > 0 ) then
    local nol = inst:phrase( sphi ).number_of_lines
    for i = 1, nol do
      local phr = inst:phrase( sphi )
      if not phr.is_empty then
        for c = 1, 12 do
          local nc = phr:line( i ):note_column( c )
          if ( nc.note_value < 120 ) then
            if ( nc.note_value + value * multi <= 119 ) and ( nc.note_value + value * multi >= 0 ) then
              nc.note_value = nc.note_value + value * multi
            end
          end
        end
      end
    end
  end
end
---
function pht_notifier_phrase_15( value )
  if ( value == 0 ) then
    vws.PHT_BUT_TRANS_DOWN_15.active = false
    vws.PHT_BUT_TRANS_UP_15.active = false
    return " 00"
  else
    vws.PHT_BUT_TRANS_DOWN_15.active = true
    vws.PHT_BUT_TRANS_UP_15.active = true
  end
end
---
PHT_TRA_PHR_15 = vb:row { spacing = -3,
  vb:column { spacing = -3,
    vb:button {
      id = "PHT_BUT_TRANS_UP_15",
      height = 14,
      width = 23,
      bitmap = "./ico/mini_positive_ico.png", --text = "+",
      active = false,
      pressed = function() pht_transpose_phrase_15( 1 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Transpose Keymap:Transpose Phrase Up Button",
      tooltip = "Transpose up the selected phrase"
    },
    vb:button {
      id = "PHT_BUT_TRANS_DOWN_15",
      height = 14,
      width = 23,
      bitmap = "./ico/mini_negative_ico.png", --text = "-",
      active = false,
      pressed = function() pht_transpose_phrase_15( -1 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Transpose Keymap:Transpose Phrase Down Button",
      tooltip = "Transpose down the selected phrase"
    }
  },
  vb:valuebox {
    id = "PHT_TRANS_PHRASE_15",
    height = 25,
    width = 50,    
    min = 0,
    max = 24,
    value = 0,
    notifier = function( value ) pht_notifier_phrase_15( value ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Transpose Keymap:Transpose Phrase Valuebox",
    tooltip = "Choose a number to transpose the selected phrase\n[ Range: 00 to 24 ]"
  }
}



-------------------------------------------------------------------------------------------------
--transpose note value
function pht_vb_trans_note_15( ins_15 )
  local spi = song.selected_phrase_index
  if ( spi > 0 ) then
    local mapping = song:instrument( ins_15 ):phrase( spi ).mapping
    if ( mapping ~= nil ) then
      vws.PHT_TRANS_NOTE_15.value = mapping.base_note
    end
  end
end
---
function pht_trans_note_15( value )
  local spi = song.selected_phrase_index
  if ( spi > 0 ) then
    local mapping = song:instrument( pht_sel_ins_15() ):phrase( spi ).mapping
    if ( mapping ~= nil ) then
      song:instrument( pht_sel_ins_15() ):phrase( spi ).mapping.base_note = value
    end
  end
end
---
local PHT_TRANS_NOTE_15 = vb:row { spacing = -2,
  vb:bitmap {
    height = 25,
    width = 19,
    mode = "body_color",
    bitmap = "./ico/note_transpose_ico.png"
  },
  vb:valuebox {
    id = "PHT_TRANS_NOTE_15",
    height = 25,
    width = 54,
    min = 0,
    max = 119,
    value = 36,
    tostring = function( number ) return pht_note_tostring ( number ) end,
    tonumber = function( string ) return pht_note_tonumber ( string ) end,
    notifier = function( value ) pht_trans_note_15( value ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Transpose Keymap:Transpose Base Note Valuebox",
    tooltip = "Transpose \"base note\" to last played note keymapped\n[ Range: C-0 to B-9 ]\n↑[Ctrl + Shift + (1 to 9..0..'..¡)]  ↓[Ctrl + (1 to 9..0..'..¡)]"
  }
}
---
PHT_PHR_PHRASES_15 = vb:row { spacing = 7,
  id = "PHT_PHR_PHRASES_15",
  vb:row {
    PHT_OFF_PROG_MAP_15,
    PHT_KEY_PHR_15,
  },
  PHT_TRA_PHR_15,
  PHT_TRANS_NOTE_15
}



-------------------------------------------------------------------------------------------------
--chords autoselection
function pht_chd_release_15()
  local ins_15 = pht_sel_ins_15()
  local tr_15 = pht_sel_trk_15()
  for i = 0, 119 do  
    if ( vws["PHT_NTE_ON_BTT_15_"..i].color ~= PHT_MAIN_COLOR.GOLD_OFF1 ) then
      pht_osc_client:trigger_instrument( false, ins_15, tr_15, i )
      vws["PHT_NTE_ON_BTT_15_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1 --off
    end
  end
end
---
function pht_select_chord_15( root )
  pht_chd_release_15()
  local root_reverse = 99 - root
  --restart
  for i = 0, 119 do
    pht_table_mark_15[ i + 1 ] = false
    vws["PHT_NTE_MRK_BTT_15_"..i].color = PHT_MAIN_COLOR.GREY_OFF
  end
  --select chord
  local chd = pht_chd_chords["chd"..vws.PHT_PP_CHORDS_15.value]
  if ( chd ~= nil ) then
    for i = 1, #chd do
      pht_table_mark_15[ chd[i] + root_reverse ] = true
      vws["PHT_NTE_MRK_BTT_15_"..chd[i] + root_reverse - 1 ].color = PHT_MAIN_COLOR.GREY_ON
    end
  end
  --root buttons
  for i = 0, 8 do
    vws["PHT_PP_ROOT_OCT"..i.."_15"].color = PHT_MAIN_COLOR.DEFAULT
  end
      if ( vws.PHT_PP_ROOT_15.value < 04 ) then
    vws.PHT_PP_ROOT_OCT8_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 16 ) then
    vws.PHT_PP_ROOT_OCT7_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 28 ) then
    vws.PHT_PP_ROOT_OCT6_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 40 ) then
    vws.PHT_PP_ROOT_OCT5_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 52 ) then
    vws.PHT_PP_ROOT_OCT4_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 64 ) then
    vws.PHT_PP_ROOT_OCT3_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 76 ) then
    vws.PHT_PP_ROOT_OCT2_15.color = PHT_MAIN_COLOR.GOLD_ON
  elseif ( vws.PHT_PP_ROOT_15.value < 88 ) then
    vws.PHT_PP_ROOT_OCT1_15.color = PHT_MAIN_COLOR.GOLD_ON
  else
    vws.PHT_PP_ROOT_OCT0_15.color = PHT_MAIN_COLOR.GOLD_ON
  end
end
---
function pht_select_chord_oct_15( value )
  vws.PHT_PP_ROOT_15.value = value
end
---
PHT_CHD_CHORDS_15 = vb:row { spacing = 7,
  id = "PHT_CHD_CHORDS_15",
  visible = false,
  vb:popup {
    id = "PHT_PP_CHORDS_15",
    height = 25,
    width = 103,
    value = 1,
    items = pht_chd_names,
    notifier = function() pht_select_chord_15( vws.PHT_PP_ROOT_15.value -1 ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Chord Selector Popup",
    tooltip = "Chord selector\nSelect a chord from the 59 available\n"..pht_chd_list
  },
  vb:row { spacing = -3,
    vb:popup {
      id = "PHT_PP_ROOT_15",
      height = 25,
      width = 60,
      value = 51,
      items = pht_chd_root,
      notifier = function( value ) pht_select_chord_15( value -1 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note Selector Popup",
      tooltip = "Root note selector\nSelect the root note for the chord\n[ Range: C-0 to D-8 ]"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT0_15",
      height = 25,
      width = 21,
      text = "0",
      pressed = function() pht_select_chord_oct_15( 99 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-0 Selector Button",
      tooltip = "Select root note C-0"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT1_15",
      height = 25,
      width = 21,
      text = "1",
      pressed = function() pht_select_chord_oct_15( 87 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-1 Selector Button",
      tooltip = "Select root note C-1"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT2_15",
      height = 25,
      width = 21,
      text = "2",
      pressed = function() pht_select_chord_oct_15( 75 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-2 Selector Button",
      tooltip = "Select root note C-2"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT3_15",
      height = 25,
      width = 32,
      text = "3",
      pressed = function() pht_select_chord_oct_15( 63 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-3 Selector Button",
      tooltip = "Select root note C-3"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT4_15",
      height = 25,
      width = 32,
      text = "4",
      color = PHT_MAIN_COLOR.GOLD_ON,
      pressed = function() pht_select_chord_oct_15( 51 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-4 Selector Button",
      tooltip = "Select root note C-4"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT5_15",
      height = 25,
      width = 32,
      text = "5",
      pressed = function() pht_select_chord_oct_15( 39 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-5 Selector Button",
      tooltip = "Select root note C-5"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT6_15",
      height = 25,
      width = 21,
      text = "6",
      pressed = function() pht_select_chord_oct_15( 27 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-6 Selector Button",
      tooltip = "Select root note C-6"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT7_15",
      height = 25,
      width = 21,
      text = "7",
      pressed = function() pht_select_chord_oct_15( 15 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-7 Selector Button",
      tooltip = "Select root note C-7"
    },
    vb:button {
      id = "PHT_PP_ROOT_OCT8_15",
      height = 25,
      width = 21,
      text = "8",
      pressed = function() pht_select_chord_oct_15( 3 ) end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:Chords:Root Note C-8 Selector Button",
      tooltip = "Select root note C-8"
    }
  }
}


---
local PHT_CONTROLS_15 = vb:row { spacing = 7,
  PHT_MST_PNC_UMK_15,
  PHT_SUS_TOU_15,
  PHT_SEL_TRK_15,
  PHT_SEL_INS_15,
  vb:row { spacing = -3,
    PHT_LOCK_TR_INS_15,
    vb:row { spacing = -1,
      PHT_ANCHOR_TR_INS_15,
      PHT_CHD_PHR_BT_15
    }
  },
  PHT_PHR_PHRASES_15,
  PHT_CHD_CHORDS_15
}



-------------------------------------------------------------------------------------------------
---classes for mst: on, off, mark
class "Mst_On_Btt_15"
function Mst_On_Btt_15:__init( oct, val_a, val_b )
  self.cnt = vb:button {
    id = "PHT_MST_ON_BTT_15_"..oct,
    height = pht_height_bt_on,
    width = pht_width_bt_on,
    color = PHT_MAIN_COLOR.GOLD_OFF2,
    pressed = function() pht_master_15( true, "GOLD_ON", val_a, val_b ) end,
    released = function() pht_master_rel_15( false, "GOLD_OFF1", val_a, val_b ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":ON:On Oct "..oct,
    text = "Oct "..oct
  }
end
---
class "Mst_Off_Btt_15"
function Mst_Off_Btt_15:__init( oct, val_a, val_b )
  self.cnt = vb:button {
    id = "PHT_MST_OFF_BTT_15_"..oct,
    height = pht_height_bt_off,
    width = pht_width_bt_off,
    color = PHT_MAIN_COLOR.RED_OFF_15,
    pressed = function() pht_master_15( false, "GOLD_OFF1", val_a, val_b ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":OFF:Off Oct "..oct,
    text = ""
  }
end
---
class "Mst_Mrk_Btt_15"
function Mst_Mrk_Btt_15:__init( oct, val_a, val_b )
  self.cnt = vb:button {
    id = "PHT_MST_MRK_BTT_15_"..oct,
    height = pht_height_bt_sel,
    width = pht_width_bt_sel,
    color = PHT_MAIN_COLOR.GREY_OFF,
    pressed = function() pht_unmark_15( val_a, val_b ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":MARK:Mark Oct "..oct,
    text = ""
  }
end



-------------------------------------------------------------------------------------------------
---classes for notes: on, off, mark
class "Nte_On_Btt_15"
function Nte_On_Btt_15:__init( i, oct )
  self.cnt = vb:button {
    id = "PHT_NTE_ON_BTT_15_"..i,
    height = pht_height_bt_on,
    width = pht_width_bt_on,
    color = PHT_MAIN_COLOR.GOLD_OFF1,
    pressed = function() pht_osc_bt_pres_15( i ) end,
    released = function() pht_osc_bt_sus_15( i ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":ON:"..( "On %s" ):format( pht_note_tostring( i ) ),
    text = ( "%s" ):format( pht_note_tostring( i ) ),
    tooltip = ""
  }
end
---
class "Nte_Off_Btt_15"
function Nte_Off_Btt_15:__init( i, oct )
  self.cnt = vb:button {
    id = "PHT_NTE_OFF_BTT_15_"..i,
    height = pht_height_bt_off,
    width = pht_width_bt_off,
    color = PHT_MAIN_COLOR.RED_OFF_15,
    pressed = function() pht_osc_bt_rel_15( i ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":OFF:"..( "Off %s" ):format( pht_note_tostring( i ) ),
    text = "",
    tooltip = ""
  }
end
---
class "Nte_Mark_Btt_15"
function Nte_Mark_Btt_15:__init( i, oct, val_a, val_b )
  self.cnt = vb:button {
    id = "PHT_NTE_MRK_BTT_15_"..i,
    height = pht_height_bt_sel,
    width = pht_width_bt_sel,
    color = PHT_MAIN_COLOR.GREY_OFF,
    notifier = function() pht_mark_15( i, val_a, val_b ) end,
    midi_mapping = "Tools:PhraseTouch:Panel_15:Octave "..oct..":MARK:"..( "Mark %s" ):format( pht_note_tostring( i ) ),
    text = "",
    tooltip = ""
  }
end



-------------------------------------------------------------------------------------------------
-- octaves 00 to 09
function pht_octave_00_15()
  local octave_00 = vb:column { style = "plain", margin = 4 }
  octave_00:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 0, 0, 11 ).cnt,
        Mst_Off_Btt_15( 0, 0, 11 ).cnt
      },
      Mst_Mrk_Btt_15( 0, 0, 11 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 11, 0, -1 do
    octave_00:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 0 ).cnt,
          Nte_Off_Btt_15( i, 0 ).cnt
        },
        Nte_Mark_Btt_15( i, 0, 0, 11 ).cnt
      }
    )
  end
  return octave_00
end
---
function pht_octave_01_15()
  local octave_01 = vb:column { style = "plain", margin = 4 }
  octave_01:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 1, 12, 23 ).cnt,
        Mst_Off_Btt_15( 1, 12, 23 ).cnt
      },
      Mst_Mrk_Btt_15( 1, 12, 23 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 23, 12, -1 do
    octave_01:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 1 ).cnt,
          Nte_Off_Btt_15( i, 1 ).cnt
        },
        Nte_Mark_Btt_15( i, 1, 12, 23 ).cnt
      }
    )
  end
  return octave_01
end
---
function pht_octave_02_15()
  local octave_02 = vb:column { style = "plain", margin = 4 }
  octave_02:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 2, 24, 35 ).cnt,
        Mst_Off_Btt_15( 2, 24, 35 ).cnt
      },
      Mst_Mrk_Btt_15( 2, 24, 35 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 35, 24, -1 do
    octave_02:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 2 ).cnt,
          Nte_Off_Btt_15( i, 2 ).cnt
        },
        Nte_Mark_Btt_15( i, 2, 24, 35 ).cnt
      }
    )
  end
  return octave_02
end
---
function pht_octave_03_15()
  local octave_03 = vb:column { style = "plain", margin = 4 }
  octave_03:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 3, 36, 47 ).cnt,
        Mst_Off_Btt_15( 3, 36, 47 ).cnt
      },
      Mst_Mrk_Btt_15( 3, 36, 47 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 47, 36, -1 do
    octave_03:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 3 ).cnt,
          Nte_Off_Btt_15( i, 3 ).cnt
        },
        Nte_Mark_Btt_15( i, 3, 36, 47 ).cnt
      }
    )
  end
  return octave_03
end
---
function pht_octave_04_15()
  local octave_04 = vb:column { style = "plain", margin = 4 }
  octave_04:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 4, 48, 59 ).cnt,
        Mst_Off_Btt_15( 4, 48, 59 ).cnt
      },
      Mst_Mrk_Btt_15( 4, 48, 59 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 59, 48, -1 do
    octave_04:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 4 ).cnt,
          Nte_Off_Btt_15( i, 4 ).cnt
        },
        Nte_Mark_Btt_15( i, 4, 48, 59 ).cnt
      }
    )
  end
  return octave_04
end
---
function pht_octave_05_15()
  local octave_05 = vb:column { style = "plain", margin = 4 }
  octave_05:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 5, 60, 71 ).cnt,
        Mst_Off_Btt_15( 5, 60, 71 ).cnt
      },
      Mst_Mrk_Btt_15( 5, 60, 71 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 71, 60, -1 do
    octave_05:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 5 ).cnt,
          Nte_Off_Btt_15( i, 5 ).cnt
        },
        Nte_Mark_Btt_15( i, 5, 60, 71 ).cnt
      }
    )
  end
  return octave_05
end
---
function pht_octave_06_15()
  local octave_06 = vb:column { style = "plain", margin = 4 }
  octave_06:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 6, 72, 83 ).cnt,
        Mst_Off_Btt_15( 6, 72, 83 ).cnt
      },
      Mst_Mrk_Btt_15( 6, 72, 83 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 83, 72, -1 do
    octave_06:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 6 ).cnt,
          Nte_Off_Btt_15( i, 6 ).cnt
        },
        Nte_Mark_Btt_15( i, 6, 72, 83 ).cnt
      }
    )
  end
  return octave_06
end
---
function pht_octave_07_15()
  local octave_07 = vb:column { style = "plain", margin = 4 }
  octave_07:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 7, 84, 95 ).cnt,
        Mst_Off_Btt_15( 7, 84, 95 ).cnt
      },
      Mst_Mrk_Btt_15( 7, 84, 95 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 95, 84, -1 do
    octave_07:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 7 ).cnt,
          Nte_Off_Btt_15( i, 7 ).cnt
        },
        Nte_Mark_Btt_15( i, 7, 84, 95 ).cnt
      }
    )
  end
  return octave_07
end
---
function pht_octave_08_15()
  local octave_08 = vb:column { style = "plain", margin = 4 }
  octave_08:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 8, 96, 107 ).cnt,
        Mst_Off_Btt_15( 8, 96, 107 ).cnt
      },
      Mst_Mrk_Btt_15( 8, 96, 107 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 107, 96, -1 do
    octave_08:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 8 ).cnt,
          Nte_Off_Btt_15( i, 8 ).cnt
        },
        Nte_Mark_Btt_15( i, 8, 96, 107 ).cnt
      }
    )
  end
  return octave_08
end
---
function pht_octave_09_15()
  local octave_09 = vb:column { style = "plain", margin = 4 }
  octave_09:add_child (
    vb:row { spacing = -2,
      vb:row { spacing = -3,
        Mst_On_Btt_15( 9, 108, 119 ).cnt,
        Mst_Off_Btt_15( 9, 108, 119 ).cnt
      },
      Mst_Mrk_Btt_15( 9, 108, 119 ).cnt,
      vb:space { height = 31 }
    }
  )
  for i = 119, 108, -1 do
    octave_09:add_child (
      vb:row { spacing = -2,
        vb:row { spacing = -3,
          Nte_On_Btt_15( i, 9 ).cnt,
          Nte_Off_Btt_15( i, 9 ).cnt
        },
        Nte_Mark_Btt_15( i, 9, 108, 119 ).cnt
      }
    )
  end
  return octave_09
end
---
local PHT_OCTAVES_15 = vb:row {
  margin = 1,
  spacing = 4,
  pht_octave_00_15(),
  pht_octave_01_15(),
  pht_octave_02_15(),
  pht_octave_03_15(),
  pht_octave_04_15(),
  pht_octave_05_15(),
  pht_octave_06_15(),
  pht_octave_07_15(),
  pht_octave_08_15(),
  pht_octave_09_15()
}



-------------------------------------------------------------------------------------------------
--name pannel
local PHT_PNL_NAME_15 = vb:row { 
  vb:space { width = 2 },
  vb:row { spacing = -34,
    vb:button { 
      id = "PHT_PNL_NAME_15",
      height = pht_height_bt_pnl,
      width = pht_width_bt_pnl,
      bitmap = PHT_MAP_PNL_NAME_15,
      color = PHT_MAIN_COLOR.RED_OFF_15,
      pressed = function() pht_pln_name_multi( "_15" ) pht_mc_pnls_add_timer( "_15" ) end,
      released = function() pht_mc_pnls_remove_timer() end,
      midi_mapping = "Tools:PhraseTouch:Panel_15:MultiTouch:MultiTouch Panel",
      tooltip = PHT_MAP_PNL_TOOLTIP
    }
  }
}



-------------------------------------------------------------------------------------------------
--note volume slider
local PHT_SLIDER_VOL_15 = vb:row {
  vb:space { width = 3 },
  vb:column {
    style = "plain",
    margin = 4,
    spacing = 2,
    vb:column {
      spacing = -3,
      vb:valuefield {
        id = "PHT_SLIDER_VAL_15",
        height = 20,
        width = 22,
        align = "center",
        min = 0,
        max = 127,
        value = 95,
        tostring = function( value ) return ( "%.02X" ):format( value ) end,
        tonumber = function( value ) return tonumber( value, 16 ) end,
        notifier = function( value ) vws.PHT_SLIDER_VOL_15.value = value end,
        tooltip = "Enter a specific value for the note volume for this panel"
      },
      vb:column { spacing = -17,
        vb:slider {
          id = "PHT_SLIDER_VOL_15",
          height = pht_height_bar_vol,
          width = pht_width_bar_vol,
          min = 0,
          max = 127,
          value = 95,
          notifier = function( value ) vws.PHT_SLIDER_VAL_15.value = value end,
          midi_mapping = "Tools:PhraseTouch:Panel_15:Volume:Note Volume Slider",
          tooltip = "Note volume slider for this panel\nChange the value before playing any note or phrase\n[ Range: 0 to 7F ]\n"..
                    "Press CTRL also for greater precision!"
        },
        vb:button {
          id = "PHT_RTN_VOL_15",
          height = 17,
          width = 24,
          bitmap = "./ico/mini_return_ico.png",
          color = PHT_MAIN_COLOR.GOLD_OFF1,
          pressed = function() vws.PHT_SLIDER_VOL_15.value = 95 end,
          midi_mapping = "Tools:PhraseTouch:Panel_15:Volume:Note Volume Slider = 40",
          tooltip = "Return volume default value = 40"
        }
      }
    }
  }
}



-------------------------------------------------------------------------------------------------
--instrument volume slider
function pht_slider_ins_val_15( value )
  return math.lin2db(value/100)
end
---
function pht_slider_ins_vol_15( value )
  song:instrument( pht_sel_ins_15() ).volume = value/100
  vws.PHT_SLIDER_INS_VAL_15.value = pht_slider_ins_val_15( value )
end
---
local PHT_SLIDER_INS_VOL_15 = vb:row {
  vb:space { width = 3 },
  vb:column {
    style = "plain",
    margin = 4,
    spacing = 2,
    vb:column {
      spacing = -3,
      vb:valuefield {
        id = "PHT_SLIDER_INS_VAL_15",
        height = 20,
        width = 22,
        align = "center",
        min = -200,
        max = 6,
        value = 0,
        active = false,
        tostring = function( value ) if ( value == -200 ) then return "-INF" else return pht_slider_ins_val_15( value ) end end,
        tonumber = function( value ) return tonumber( value ) end
      },
      vb:column { spacing = -17,
        vb:slider {
          id = "PHT_SLIDER_INS_VOL_15",
          height = pht_height_bar_db,
          width = pht_width_bar_db,
          min = 0,
          max = 199.526, --0 to math.db2lin(6)
          value = 100,
          notifier = function( value ) pht_slider_ins_vol_15( value ) end,
          midi_mapping = "Tools:PhraseTouch:Panel_15:Volume:Instrument Volume Slider",
          tooltip = "Instrument global volume slider for this panel (in dB)\nSelect before a specific instrument in this panel to control it\n[ Range: -INF to 6.0 dB ]\n"..
                    "Press CTRL also for greater precision!"
        },
        vb:column { spacing = -3,
          vb:button {
            id = "PHT_RTN_INS_VOL_15",
            height = 17,
            width = 24,
            bitmap = "./ico/mini_return_ico.png",
            color = PHT_MAIN_COLOR.GOLD_OFF1,
            pressed = function() vws.PHT_SLIDER_INS_VOL_15.value = 100 end,
            midi_mapping = "Tools:PhraseTouch:Panel_15:Volume:Instrument Volume Slider = 0.0 dB",
            tooltip = "Return instrument global volume default value = 0.0 dB"
          },
          vb:button {
            id = "PHT_ZRO_INS_VOL_15",
            height = 17,
            width = 24,
            bitmap = "./ico/arrow_down_ico.png",
            color = PHT_MAIN_COLOR.RED_OFF_15,
            pressed = function() vws.PHT_SLIDER_INS_VOL_15.value = 0 end,
            midi_mapping = "Tools:PhraseTouch:Panel_15:Volume:Instrument Volume Slider = -INF",
            tooltip = "Silence instrument global volume value = -INF"
          }
        }
      }
    }
  }
}
---
local PHT_TRANS_VOL_15 = vb:column { spacing = 4,
  PHT_PNL_NAME_15,
  PHT_SLIDER_VOL_15,
  PHT_SLIDER_INS_VOL_15
}



-------------------------------------------------------------------------------------------------
--gui all
PHT_PAD_PANEL_15 = vb:row { margin = 1,
  --id = "PHT_PAD_PANEL_15",
  vb:column { style = "panel", margin = 6, spacing = 4,
    PHT_CONTROLS_15,
    vb:row {
      PHT_OCTAVES_15,
      PHT_TRANS_VOL_15
    }
  }
}
