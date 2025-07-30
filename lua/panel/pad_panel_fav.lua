--
-- PAD PANEL_FAV
--


dialog_fav = nil
local title_fav = " FavTouch"



local pht_faw_h = 35
local pht_fav_w = 87
local pht_fav_s = 14



-----------------------------------------------------------------------------------------------
--tables/locals favorites for instrument, tracks and notes (x32)
PHT_FAV_INS = {
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, --x32
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1  --x64
}

PHT_FAV_TRK = {
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, --x32
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1  --x64
}

PHT_FAV_NTE = {
  24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55, --x32
  56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87  --x64
--0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31, --x32
--32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63  --x64
}



--import note, instrument & track values
function pht_fav_tabs( ins, tr, nte )
  local idx = math.floor( vws.PHT_FAV_ROT_SEL.value )
  if ( idx >= 1 ) and ( dialog_fav ) and ( dialog_fav.visible ) then
    dialog_fav:show()
    PHT_FAV_INS[ idx ] = ins
    PHT_FAV_TRK[ idx ] = tr
    PHT_FAV_NTE[ idx ] = nte
    --print( "--PHT_FAV_INS------------------" ) rprint( PHT_FAV_INS )
    --print( "--PHT_FAV_TRK------------------" ) rprint( PHT_FAV_TRK )
    --print( "--PHT_FAV_NTE------------------" ) rprint( PHT_FAV_NTE )
    
    vws["PHT_FAV_BT_"..idx].text = ("%s %.2X  Tr%s"):format( pht_note_tostring ( PHT_FAV_NTE[ idx ] ), PHT_FAV_INS[ idx ] -1, PHT_FAV_TRK[ idx ] )
    
    if ( PHT_FAV_AUTO_DESEL == true ) then
      vws.PHT_FAV_ROT_SEL.value = 0
    else
      if ( PHT_FAV_JUMP_SEL == true ) then
        local max 
        if ( vws.PHT_FAV_X64.visible == false ) then
          max = 32
        else
          max = 64
        end
        if math.floor( vws.PHT_FAV_ROT_SEL.value + 1 ) <= max then
          vws.PHT_FAV_ROT_SEL.value = math.floor( vws.PHT_FAV_ROT_SEL.value + 1 )
        else 
          vws.PHT_FAV_ROT_SEL.value = 0
        end
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--pressed
pht_table_release_fav = {
  false, false, false, false, false, false, false, false, --group 1
  false, false, false, false, false, false, false, false, --group 2
  false, false, false, false, false, false, false, false, --group 3
  false, false, false, false, false, false, false, false, --group 4
  
  false, false, false, false, false, false, false, false, --group 5
  false, false, false, false, false, false, false, false, --group 6
  false, false, false, false, false, false, false, false, --group 7
  false, false, false, false, false, false, false, false, --group 8
}
---
local PHT_FAV_ANCHOR = false
function pht_fav_anchor()
  if ( PHT_FAV_ANCHOR == false ) then
    PHT_FAV_ANCHOR_BTT.bitmap = "./ico/anchor_true_ico.png"
    PHT_FAV_ANCHOR_BTT.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_FAV_ANCHOR = true
  else
    PHT_FAV_ANCHOR_BTT.bitmap = "./ico/anchor_false_ico.png"
    PHT_FAV_ANCHOR_BTT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_ANCHOR = false
  end
end
---
PHT_FAV_ANCHOR_BTT = vb:button {
  height = 19,
  width = 25,
  bitmap = "./ico/anchor_false_ico.png",
  notifier = function() pht_fav_anchor() end,
  midi_mapping = "Tools:PhraseTouch:FavTouch:Anchor Checkbox",
  tooltip = "Anchor\nAnchor the track & the instrument for each pad\n"..
            "Prevents the automatic selection of track & instrument"
}
---
function pht_osc_bt_pres_fav( idx )
  local ins = PHT_FAV_INS[ idx ]
  local tr
  if ( vws.PHT_FAV_SW_TR_PAD_SEL.value == 1 ) then
    tr = PHT_FAV_TRK[ idx ]
  else
    tr = song.selected_track_index
  end
  local nte = PHT_FAV_NTE[ idx ]
  local vel = vws.PHT_FAV_ROT_VEL.value
  pht_change_button_color_fav( idx )
  if ( PHT_FAV_TOUCH_ALL == false ) then
    for i = 1, 64 do
      local tr
      if ( vws.PHT_FAV_SW_TR_PAD_SEL.value == 1 ) then
        tr = PHT_FAV_TRK[ i ]
      else
        tr = song.selected_track_index
      end
      pht_osc_client:trigger_instrument( false, PHT_FAV_INS[ i ], tr, PHT_FAV_NTE[ i ] )
    end
    
    if ( pht_table_release_fav[ idx ] == true ) then
      pht_change_button_color_off_fav( idx )
      pht_table_release_fav[ idx ] = false
    else    
      pht_osc_client:trigger_instrument( true, ins, tr, nte, vel )
      for i = 1, 64 do
        if ( i ~= idx ) then
          pht_table_release_fav[ i ] = false
        else
          pht_table_release_fav[ i ] = true
        end
      end
    end
  else
    pht_osc_client:trigger_instrument( false, ins, tr, nte )
    if ( pht_table_release_fav[ idx ] == true ) then
      pht_change_button_color_off_fav( idx )
      pht_table_release_fav[ idx ] = false
    else    
      pht_osc_client:trigger_instrument( true, ins, tr, nte, vel )
      pht_table_release_fav[ idx ] = true
    end
  end
  --show phrase name
  pht_phrase_keymapped_fav( ins, nte )
  --select track & instrument
  if ( PHT_FAV_ANCHOR == true ) then
    if ( tr <= song.sequencer_track_count ) then
      song.selected_track_index = tr
    else
      song.selected_track_index = song.sequencer_track_count
    end
    if ( ins <= #song.instruments ) then
      song.selected_instrument_index = ins
    else
      song.selected_instrument_index = #song.instruments
    end
  end
end
---
function pht_osc_bt_rel_fav( idx )
  local ins = PHT_FAV_INS[ idx ]
  local tr
  if ( vws.PHT_FAV_SW_TR_PAD_SEL.value == 1 ) then
    tr = PHT_FAV_TRK[ idx ]
  else
    tr = song.selected_track_index
  end
  local nte = PHT_FAV_NTE[ idx ]
  --off note sound
  pht_osc_client:trigger_instrument( false, ins, tr, nte )
  pht_table_release_fav[ idx ] = false
  pht_change_button_color_off_fav( idx )
end
---
function pht_osc_bt_sus_fav( idx )
  if ( PHT_FAV_SUSTAIN == false ) then
    pht_osc_bt_rel_fav( idx )
  end
end
---
function pht_change_button_color_off_fav( idx )
  vws["PHT_FAV_BT_"..idx].color = PHT_MAIN_COLOR.GOLD_OFF1 --off
end 
---
function pht_change_button_color_fav( idx )
  for i = 1,64 do
    if ( i == idx ) then
      vws["PHT_FAV_BT_"..i].color = PHT_MAIN_COLOR.GOLD_ON --on
    else
      if ( PHT_FAV_TOUCH_ALL == false ) then
        vws["PHT_FAV_BT_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1 --off
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--gui buttons
class "FavPad"
function FavPad:__init( i, spc )
  self.cnt = vb:row { spacing = -2,
    vb:button {
      id = "PHT_FAV_BT_"..i,
      height = pht_faw_h,
      width = pht_fav_w,
      text = ("Pad %.2d"):format( i ),
      color = PHT_MAIN_COLOR.GOLD_OFF1,
      pressed = function() pht_osc_bt_pres_fav( i ) end,
      released = function() pht_osc_bt_sus_fav( i ) end,
      midi_mapping = "Tools:PhraseTouch:FavTouch:Pads:"..( "Pad %.2d" ):format( i )
    },
    vb:button {
      id = "PHT_FAV_BT_SEL_"..i,
      height = pht_faw_h,
      width = pht_fav_s,
      color = PHT_MAIN_COLOR.GREY_OFF,
      notifier = function() vws.PHT_FAV_ROT_SEL.value = i end
    }    
  }
  if ( i == spc ) then
    self.cnt:add_child( vb:space { width = 6 } )
  end
end
---
function pht_fav_buttons_8()
  local pht_fav_btt_8 = vb:row {}
  for i = 57, 64 do
    pht_fav_btt_8:add_child (
      FavPad( i, 60 ).cnt
    )
  end
  return pht_fav_btt_8
end
---
function pht_fav_buttons_7()
  local pht_fav_btt_7 = vb:row {}
  for i = 49, 56 do
    pht_fav_btt_7:add_child (
      FavPad( i, 52 ).cnt
    )
  end
  return pht_fav_btt_7
end
---
function pht_fav_buttons_6()
  local pht_fav_btt_6 = vb:row {}
  for i = 41, 48 do
    pht_fav_btt_6:add_child (
      FavPad( i, 44 ).cnt
    )
  end
  return pht_fav_btt_6
end
---
function pht_fav_buttons_5()
  local pht_fav_btt_5 = vb:row {}
  for i = 33, 40 do
    pht_fav_btt_5:add_child (
      FavPad( i, 36 ).cnt
    )
  end
  return pht_fav_btt_5
end
--- ---
function pht_fav_buttons_4()
  local pht_fav_btt_4 = vb:row {}
  for i = 25, 32 do
    pht_fav_btt_4:add_child (
      FavPad( i, 28 ).cnt
    )
  end
  return pht_fav_btt_4
end
---
function pht_fav_buttons_3()
  local pht_fav_btt_3 = vb:row {}
  for i = 17, 24 do
    pht_fav_btt_3:add_child (
      FavPad( i, 20 ).cnt
    )
  end
  return pht_fav_btt_3
end
---
function pht_fav_buttons_2()
  local pht_fav_btt_2 = vb:row {}
  for i = 9, 16 do
    pht_fav_btt_2:add_child (
      FavPad( i, 12 ).cnt
    )
  end
  return pht_fav_btt_2
end
---
function pht_fav_buttons_1()
  local pht_fav_btt_1 = vb:row {}
  for i = 1, 8 do
    pht_fav_btt_1:add_child (
      FavPad( i, 4 ).cnt
    )
  end
  return pht_fav_btt_1
end



-------------------------------------------------------------------------------------------------     
--phrase name keymapped
function pht_phrase_keymapped_fav( ins, nte )
  vws.PHT_PHRASE_NAME_1.text = "Phrase n/a"
  local inst = song:instrument( ins )
  for i = 1, #inst.phrases do
    if ( inst:phrase( i ).mapping ~= nil ) then
      local note_tab = inst:phrase( i ).mapping.note_range
      if ( nte >= note_tab[ 1 ] ) and ( nte <= note_tab[ 2 ] ) then
        vws.PHT_FAV_PHRASE_IDX.value = i
        vws.PHT_FAV_PHRASE_NAME.text = string.sub( inst:phrase( i ).name, 1, 22 ) --range of characters to name (1 to 22)
        return
      end
    end
  end
end
---
function pht_fav_phrase_idx( value )
  if ( song.selected_phrase_index > 0 ) and ( value <= #song.selected_instrument.phrases ) then
    song.selected_phrase_index = value
  end
end
---
PHT_KEY_PHR_FAV = vb:row { margin = 1,
  vb:row { spacing = 2,
    vb:row {
      style = "plain",
        vb:valuefield {
        id = "PHT_FAV_PHRASE_IDX",
        height = 25,
        width = 27,
        min = 0,
        max = 126,
        value = 0,
        align = "center",
        tostring = function( value ) return ( "%.02X" ):format( value ) end,
        tonumber = function( value ) return tonumber( value, 16 ) end,
        notifier = function( value ) pht_fav_phrase_idx( value ) end,
        tooltip = "Selected phrase index\nInsert a number to select your phrase\n[ Range: 01 to 7E, 126 values ]"
      }
    },
    vb:row {
      style = "plain",
      tooltip = "Selected phrase name",
      vb:text {
        id = "PHT_FAV_PHRASE_NAME",
        height = 25,
        width = 167,
        align = "center",
        text = "Phrase Name",
      }
    }
  }
}
---
function pht_fav_panic()
  local tr
  local vel = vws.PHT_FAV_ROT_VEL.value
  for i = 1, 64 do
    if ( vws.PHT_FAV_SW_TR_PAD_SEL.value == 1 ) then
      tr = PHT_FAV_TRK[ i ]
    else
      tr = song.selected_track_index
    end  
    pht_osc_client:trigger_instrument( false, PHT_FAV_INS[i], tr, PHT_FAV_NTE[i] )
    if ( pht_table_release_fav[i] ~= false ) then
      pht_table_release_fav[i] = false
    end
    vws["PHT_FAV_BT_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1
  end
end
---
function pht_fav_reset()
  vws.PHT_FAV_ROT_SEL.value = 0
  vws.PHT_FAV_ROT_VEL.value = 64
  for i = 1, 64 do
    vws["PHT_FAV_BT_"..i].text = ("Pad %.2d"):format( i )
  end
  pht_fav_panic()
  PHT_FAV_TOUCH_ALL = false
  vws.PHT_FAV_TOUCH_ALL_MODE.color = PHT_MAIN_COLOR.DEFAULT
  vws.PHT_FAV_TOUCH_ALL_MODE.active = true
  PHT_FAV_SUSTAIN = true
  vws.PHT_FAV_SUSTAIN_MODE.color = PHT_MAIN_COLOR.GOLD_ON
  PHT_FAV_AUTO_DESEL = true
  vws.PHT_FAV_AUTO_DESELECT.color = PHT_MAIN_COLOR.GOLD_ON
  vws.PHT_FAV_SW_TR_PAD_SEL.value = 1
  vws.PHT_FAV_PHRASE_IDX.value = 0
  vws.PHT_FAV_PHRASE_NAME.text = "Phrase Name"
end
---
PHT_FAV_REC_PAD_TR = vb:row { margin = 1,
  vb:row { style = "panel", margin = 3, spacing = 7,
    vb:button { 
      id = "PHT_FAV_BT_EDIT_MODE",
      height = 19,
      width = 29,
      
      bitmap = "./ico/rec_on_ico.png",
      notifier = function() pht_edit_mode() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Edit Mode Button",
      tooltip = PHT_EDIT_MODE_TOOLTIP
    },
    vb:row {
      vb:bitmap {
        height = 19,
        width = 19,
        mode = "body_color",
        bitmap = "./ico/track_ico.png",
      },
      vb:switch {
        id = "PHT_FAV_SW_TR_PAD_SEL",
        height = 19,
        width = 75,
        value = 1,
        items = { "Pad", "SEL" },
        midi_mapping = "Tools:PhraseTouch:FavTouch:Pad/SEL Switch",
        tooltip = "Change the writing place of the notes for Edit Mode\n"..
                  "Use \"Pad\" to write the notes in the track shown on each pad\n"..
                  "Use \"SEL\" to write the notes in the selected track"
      },
      PHT_FAV_ANCHOR_BTT
    }
  }
}


-----------------------------------------------------------------------------------------------
--keyboard
local PHT_FAV_SPACE = { 21, 23, 88, 92, 1 }
---
class "FavPad_K"
function FavPad_K:__init( k, w )
  self.cnt = vb:row {
    vb:row {
      style = "plain",
      margin = -2,
      vb:text {
        width = 15,
        align = "center",
        text = k
      }
    },
    vb:space { width = PHT_FAV_SPACE[w] } 
  }
end
---
PHT_FAV_SHOW_KEYS_X64 = vb:column { margin = 1,
  visible = false,
  vb:row {
    FavPad_K( "I", 3 ).cnt, FavPad_K( "9", 3 ).cnt, FavPad_K( "O", 3 ).cnt, FavPad_K( "0", 4 ).cnt, FavPad_K( "P", 3 ).cnt, FavPad_K( "`", 3 ).cnt, FavPad_K( "¡", 3 ).cnt, FavPad_K( "+", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[1] },
  vb:row {
    FavPad_K( "E", 3 ).cnt, FavPad_K( "R", 3 ).cnt, FavPad_K( "5", 3 ).cnt, FavPad_K( "T", 4 ).cnt, FavPad_K( "6", 3 ).cnt, FavPad_K( "Y", 3 ).cnt, FavPad_K( "7", 3 ).cnt, FavPad_K( "U", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[2] },
  vb:row {
    FavPad_K( "H", 3 ).cnt, FavPad_K( "N", 3 ).cnt, FavPad_K( "J", 3 ).cnt, FavPad_K( "M", 4 ).cnt, FavPad_K( "Q", 3 ).cnt, FavPad_K( "2", 3 ).cnt, FavPad_K( "W", 3 ).cnt, FavPad_K( "3", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[1] },
  vb:row {
    FavPad_K( "Z", 3 ).cnt, FavPad_K( "S", 3 ).cnt, FavPad_K( "X", 3 ).cnt, FavPad_K( "D", 4 ).cnt, FavPad_K( "C", 3 ).cnt, FavPad_K( "V", 3 ).cnt, FavPad_K( "G", 3 ).cnt, FavPad_K( "B", 5 ).cnt
  }
}
---
PHT_FAV_SHOW_KEYS_X32 = vb:column { margin = 1,
  visible = false,
  vb:row {
    FavPad_K( "I", 3 ).cnt, FavPad_K( "9", 3 ).cnt, FavPad_K( "O", 3 ).cnt, FavPad_K( "0", 4 ).cnt, FavPad_K( "P", 3 ).cnt, FavPad_K( "`", 3 ).cnt, FavPad_K( "¡", 3 ).cnt, FavPad_K( "+", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[1] },
  vb:row {
    FavPad_K( "E", 3 ).cnt, FavPad_K( "R", 3 ).cnt, FavPad_K( "5", 3 ).cnt, FavPad_K( "T", 4 ).cnt, FavPad_K( "6", 3 ).cnt, FavPad_K( "Y", 3 ).cnt, FavPad_K( "7", 3 ).cnt, FavPad_K( "U", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[2] },
  vb:row {
    FavPad_K( "H", 3 ).cnt, FavPad_K( "N", 3 ).cnt, FavPad_K( "J", 3 ).cnt, FavPad_K( "M", 4 ).cnt, FavPad_K( "Q", 3 ).cnt, FavPad_K( "2", 3 ).cnt, FavPad_K( "W", 3 ).cnt, FavPad_K( "3", 5 ).cnt
  },
  vb:space { height = PHT_FAV_SPACE[1] },
  vb:row {
    FavPad_K( "Z", 3 ).cnt, FavPad_K( "S", 3 ).cnt, FavPad_K( "X", 3 ).cnt, FavPad_K( "D", 4 ).cnt, FavPad_K( "C", 3 ).cnt, FavPad_K( "V", 3 ).cnt, FavPad_K( "G", 3 ).cnt, FavPad_K( "B", 5 ).cnt
  }
}
---
function pht_fav_keyboard()
  if ( PHT_VB_NOTES.value ~= 17 ) then
    PHT_VB_NOTES.value = 17
    if (vws.PHT_FAV_X64.visible == true ) then
      PHT_FAV_SHOW_KEYS_X64.visible = true
    end
    PHT_FAV_SHOW_KEYS_X32.visible = true
    song.transport.octave = 0
  else
    PHT_VB_NOTES.value = 1
    PHT_FAV_SHOW_KEYS_X64.visible = false
    PHT_FAV_SHOW_KEYS_X32.visible = false
    song.transport.octave = 3
  end
end
---
PHT_FAV_KEYBOARD = vb:button {
  id = "PHT_FAV_KEYBOARD",
  height = 27,
  width = 35,
  bitmap = "./ico/keyboard_fav_ico.png",
  notifier = function() pht_fav_keyboard() end,
  midi_mapping = "Tools:PhraseTouch:FavTouch:USB Keyboard Button",
  tooltip = "Enable/disable USB keyboard for control the pads\n"..
            "  -Use the octave 0 (Oct = 0) to control 01 to 32 pads\n"..
            "  -Use the octave 1 (Oct = 1) to control 33 to 64 pads\n"..
            "This option show the name of the keys superimposed\n[Ctrl + Numlock]"
}
---
PHT_FAV_BOTTOM_LOGO = vb:horizontal_aligner {
  width = 113,
  mode = "right",
  visible = true,
  vb:bitmap {
    id = "PHT_FAV_BOTTOM_LOGO",
    height = 24,
    width = 113,
    mode = "body_color",
    bitmap = "./ico/favtouch32_ico.png",
  }
}
---
function pht_fav_x64()
  if ( vws.PHT_FAV_X64.visible == false ) then
    vws.PHT_FAV_X64.visible = true
    if ( PHT_VB_NOTES.value == 17 ) then
      PHT_FAV_SHOW_KEYS_X64.visible = true
    end
    vws.PHT_FAV_ROT_SEL.value = 0
    vws.PHT_FAV_ROT_SEL.max = 64
    vws.PHT_FAV_BT_X64.bitmap = "./ico/panel_3_ico.png"
    vws.PHT_FAV_BOTTOM_LOGO.bitmap = "./ico/favtouch64_ico.png"
    vws.PHT_FAV_TXT_SEL_PAD33.active = true
  else
    vws.PHT_FAV_X64.visible = false
    vws.PHT_FAV_ROT_SEL.value = 0
    vws.PHT_FAV_ROT_SEL.max = 32
    vws.PHT_FAV_BT_X64.bitmap = "./ico/panel_2h_ico.png"
    vws.PHT_FAV_BOTTOM_LOGO.bitmap = "./ico/favtouch32_ico.png"
    vws.PHT_FAV_TXT_SEL_PAD33.active = false
  end
end



-----------------------------------------------------------------------------------------------
--main buttons
PHT_FAV_JUMP_SEL = false
function pht_fav_jump_select()
  if ( PHT_FAV_JUMP_SEL == false ) then
    vws.PHT_FAV_JUMP_SELECT.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_FAV_JUMP_SEL = true
    ---
    vws.PHT_FAV_AUTO_DESELECT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_AUTO_DESEL = false
    if ( vws.PHT_FAV_ROT_SEL.value == 0 ) then
      vws.PHT_FAV_ROT_SEL.value = 1
    end
  else
    vws.PHT_FAV_JUMP_SELECT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_JUMP_SEL = false
    if ( vws.PHT_FAV_ROT_SEL.value ~= 0 ) then
      vws.PHT_FAV_ROT_SEL.value = 0
    end
  end
end
PHT_FAV_AUTO_DESEL = true
function pht_fav_auto_deselect()
  if ( PHT_FAV_AUTO_DESEL == false ) then
    vws.PHT_FAV_AUTO_DESELECT.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_FAV_AUTO_DESEL = true
    ---
    vws.PHT_FAV_JUMP_SELECT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_JUMP_SEL = false
    if ( vws.PHT_FAV_ROT_SEL.value == 0 ) then
      vws.PHT_FAV_ROT_SEL.value = 1
    end
  else
    vws.PHT_FAV_AUTO_DESELECT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_AUTO_DESEL = false
    if ( vws.PHT_FAV_ROT_SEL.value ~= 0 ) then
      vws.PHT_FAV_ROT_SEL.value = 0
    end
  end
end
---
PHT_FAV_JUMP_AUTO = vb:row { spacing = -1, 
  vb:button {
    id = "PHT_FAV_JUMP_SELECT",
    height = 27,
    width = 43,
    text = "JUMP",
    notifier = function() pht_fav_jump_select() end,
    midi_mapping = "Tools:PhraseTouch:FavTouch:Selector Mode:Jump Checkox",
    tooltip = "Jump selection to import favorites\nWhen you save a favorite note on a pad, the selection automatically jumps to the next pad"
  },
  vb:button {
    id = "PHT_FAV_AUTO_DESELECT",
    height = 27,
    width = 43,
    text = "AUTO",
    color = PHT_MAIN_COLOR.GOLD_ON,
    notifier = function() pht_fav_auto_deselect() end,
    midi_mapping = "Tools:PhraseTouch:FavTouch:Selector Mode:Auto Checkox",
    tooltip = "Auto deselection to import favorites\nWhen you save a favorite note on a pad, the selection is automatically deselected. Use this option for greater security"
  }
}
---
PHT_FAV_TOUCH_ALL = false
function pht_fav_touch_all_mode()
  if ( PHT_FAV_TOUCH_ALL == false ) then
    vws.PHT_FAV_TOUCH_ALL_MODE.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_FAV_TOUCH_ALL = true
  else
    vws.PHT_FAV_TOUCH_ALL_MODE.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_TOUCH_ALL = false
  end
end
PHT_FAV_SUSTAIN = true
function pht_fav_sustain_mode()
  if ( PHT_FAV_SUSTAIN == false ) then
    vws.PHT_FAV_SUSTAIN_MODE.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_FAV_SUSTAIN = true
    vws.PHT_FAV_TOUCH_ALL_MODE.active = true
  else
    vws.PHT_FAV_SUSTAIN_MODE.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_SUSTAIN = false
    vws.PHT_FAV_TOUCH_ALL_MODE.active = false
  end
end
---
PHT_FAV_MAIN_BUTTONS = vb:row { spacing = 11,
  vb:row { spacing = 7,
    vb:button {
      id = "PHT_FAV_BT_X64",
      height = 27,
      width = 37,
      bitmap = "./ico/panel_2h_ico.png",
      color = PHT_MAIN_COLOR.SKY_BLUE,
      notifier = function() pht_fav_x64() end,
      midi_mapping = "Tools:PhraseTouch:FavTouch:x64 Pads Button",
      tooltip = "Window modes for 32 or 64 pads"
    },
    PHT_FAV_KEYBOARD,
    PHT_FAV_REC_PAD_TR,
  },
  vb:row { spacing = 7,
    vb:row { spacing = -1, 
      vb:button {
        id = "PHT_FAV_TOUCH_ALL_MODE",
        height = 27,
        width = 35,
        text = "ALL",
        notifier = function() pht_fav_touch_all_mode() end,
        midi_mapping = "Tools:PhraseTouch:FavTouch:Sustain Mode:All Checkbox",
        tooltip = "Touch All Mode\nTouch all the keys for FavTouch panel without stopping those already played.\nCombine it with the \"SUS\" checkbox"
      },
      vb:button {
        id = "PHT_FAV_SUSTAIN_MODE",
        height = 27,
        width = 35,
        text = "SUS",
        color = PHT_MAIN_COLOR.GOLD_ON,
        notifier = function() pht_fav_sustain_mode() end,
        midi_mapping = "Tools:PhraseTouch:FavTouch:Sustain Mode:Sus Checkbox",
        tooltip = "Sustain Mode\nSustain the key recently pressed and stop the rest for FavTouch panel\nCombine it with the \"ALL\" checkbox (work only with the mouse or MIDI Input!)"
      }
    },
    PHT_KEY_PHR_FAV,
    PHT_FAV_JUMP_AUTO,
    vb:button {
      height = 27,
      width = 45,
      text = "Reset",      
      notifier = function() pht_fav_reset() end,
      midi_mapping = "Tools:PhraseTouch:FavTouch:Panic & Reset:Reset Button",
      tooltip = "Reset all options"
    }
  },
  vb:button {
    id = "PHT_FAV_PANIC",
    height = 27,
    width = 57,
    text = "Panic",
    color = PHT_MAIN_COLOR.RED_OFF_1,
    notifier = function() pht_fav_panic() end,
    midi_mapping = "Tools:PhraseTouch:FavTouch:Panic & Reset:Panic Button",
    tooltip = "General panic for FavTouch panel"
  },
  PHT_FAV_BOTTOM_LOGO
}



-----------------------------------------------------------------------------------------------
--rotary controls
function pht_fav_rot_sel( v )
  local sel = vws.PHT_FAV_TXT_SEL
  if ( v >= 1 ) then
    sel.text = ( "%.2d" ):format( v )
  else
    sel.text = "P0"
    vws.PHT_FAV_JUMP_SELECT.color = PHT_MAIN_COLOR.DEFAULT
    PHT_FAV_JUMP_SEL = false
  end
end
---
function pht_fav_rot_vel( v )
  vws.PHT_FAV_TXT_VEL.text = ( "%.2X" ):format( v )
end
---
local pht_fav_rot_sel_loc
function pht_fav_rot_sel_panel( v )
  if v ~= pht_fav_rot_sel_loc then
    local max
    if ( vws.PHT_FAV_X64.visible == false ) then
      max = 32
    else
      max = 64
    end
    for i = 0, max do  
      if i >= 1 then
        if v == i then 
          vws["PHT_FAV_BT_SEL_"..i].color = PHT_MAIN_COLOR.GREY_ON
          --print(v)
        else
          vws["PHT_FAV_BT_SEL_"..i].color = PHT_MAIN_COLOR.GREY_OFF
        end
      end
    end  
  end
  pht_fav_rot_sel_loc = v
end
---
PHT_FAV_ROT = vb:column {
  vb:column { spacing = -3,
    vb:row { spacing = -42,
      vb:rotary {
        id = "PHT_FAV_ROT_SEL",
        height = 62,
        width = 62,
        min = 0,
        max = 32,
        value = 0,
        notifier = function( v ) pht_fav_rot_sel( math.floor(v) ) pht_fav_rot_sel_panel( math.floor(v) ) end,
        midi_mapping = "Tools:PhraseTouch:FavTouch:Rotary:Pad Selector Rotary",
        tooltip = "Pad Selector\n[ P0 = any selection. Range 01 to 32 (or 64) ]\n"..
                  "Press CTRL also for greater precision!"
      },
      vb:column { 
        vb:space { height = 21 },
        vb:text {
          id = "PHT_FAV_TXT_SEL",
          font = "bold",
          text = "P0"
        }
      }
    },
    vb:row {
      vb:button {
        id = "PHT_FAV_TXT_SEL_PAD33",
        active = false,
        height = 18,
        width = 23,
        text = "33",
        notifier = function() if ( vws.PHT_FAV_ROT_SEL.max == 64 ) then vws.PHT_FAV_ROT_SEL.value = 33 end end,
        tooltip = "Selector value = Pad 33"
      },
      vb:space { width = 13 },
      vb:button {
        height = 18,
        width = 23,
        bitmap = "./ico/mini_return_ico.png",
        notifier = function() vws.PHT_FAV_ROT_SEL.value = 0 end,
        tooltip = "Return selector default value = P0"
      }
    }
  },
  vb:space { height = 3 },
  vb:row { spacing = -42,
    vb:rotary {
      id = "PHT_FAV_ROT_VEL",
      height = 62,
      width = 62,
      min = 0,
      max = 127,
      value = 95,
      notifier = function( v ) pht_fav_rot_vel( v ) end,
      midi_mapping = "Tools:PhraseTouch:FavTouch:Rotary:Volume Rotary",
      tooltip = "Volume rotary\nChange the value before playing any note or phrase\n"..
      "Press CTRL also for greater precision!"
    },
    vb:column { 
      vb:space { height = 21 },
      vb:text {
        id = "PHT_FAV_TXT_VEL",
        font = "bold",
        text = "5F"
      }
    }
  }
}



-----------------------------------------------------------------------------------------------
--basic controls
PHT_FAV_BASIC_CONTROLS = vb:column { spacing = 2,
  vb:column {
    vb:row { spacing = -3,
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/undo_ico.png",
        notifier = function() pht_undo() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Undo Button",
        tooltip = "Undo\n[Ctrl + Z]"
      },
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/redo_ico.png",
        notifier = function() pht_redo() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Redo Button",
        tooltip = "Redo\n[Ctrl + Y]"
      }
    },
    vb:row { spacing = -3,
      vb:button {
        id = "PHT_FAV_BT_PLAY",
        height = 28,
        width = 33,        
        bitmap = "./ico/play_ico.png",
        notifier = function() pht_play_pattern() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Play Pattern Button",
        tooltip = "Play the selected pattern\nWith active playback: restore the pattern\nWith inactive playback: continue the pattern\n[Space]  [R.Alt]"
      },
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/stop_first_ico.png",
        notifier = function() pht_stop_pattern() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Stop Pattern Button",
        tooltip = "Stop & jump first line\nStop the selected pattern & jump first line to restore the pattern in two steps\n"..
                "This operation include Panic the sound!\n[Space]  [R.Alt]"
      }
    }
  },
  vb:column { spacing = -3,
    vb:row { spacing = -3,
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/pattern_editor_ico.png",
        notifier = function() pht_jump_pattern_editor() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Pattern Editor Button",
        tooltip = "Select Pattern Editor\n[F9]"
      },
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/phrase_editor_ico.png",
        notifier = function() pht_jump_phrase_editor() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Phrase Editor Button",
        tooltip = "Select Phrase Editor of the selected instrument, with \"Keymap\" mode\n[F10]"
      }
    },
    vb:row { spacing = -3,
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/plugin_ico.png",
        notifier = function() pht_show_plugin() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show/Hide Plugin External Editor Button",
        tooltip = "Show/Hide the Plugin External Editor of the selected instrument. If the plugin not exist, show the Plugin Editor\n[F11]"
      },
      vb:button {
        height = 28,
        width = 33,        
        bitmap = "./ico/midi_ico.png",
        notifier = function() pht_show_midi() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show MIDI Monitor Button",
        tooltip = "Show the MIDI monitor of the selected instrument\n[F12]"
      }
    }
  },
  vb:column { spacing = -3,
    vb:row { spacing = -3,
      vb:button {
        height = 29,
        width = 33,        
        bitmap = "./ico/phr_ico.png",
        notifier = function() show_tool_dialog() end,
        midi_mapping = "Tools:PhraseTouch:FavTouch:Show PhraseTouch Window Button",
        tooltip = "Show PhraseTouch window...[Ctrl + Alt + P, assignable by the user!]"
      },
      vb:button {
        height = 29,
        width = 33,        
        bitmap = "./ico/keyboard_ico.png",
        notifier = function() show_tool_dialog_keyboard() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Keyboard Commands Button",
        tooltip = "Show Keyboard Commands window...\n[Ctrl + K]  [Ctrl + Alt + K, to close]"
      }
    }
  }
}
---
PHT_FAV_BUTTONS = vb:column { style = "panel", margin = 6, spacing = 5,
  vb:column { margin = 1,
    vb:column { style = "plain", margin = 4,
      vb:column { spacing = -148,
        id = "PHT_FAV_X64",
        visible = false,
        vb:row { spacing = 2,
          vb:column {
            pht_fav_buttons_8(),
            pht_fav_buttons_7(),
            vb:space { height = 2 },
            pht_fav_buttons_6(),
            pht_fav_buttons_5(),
            vb:space { height = 4 },
          },
          PHT_FAV_BASIC_CONTROLS
        },
        PHT_FAV_SHOW_KEYS_X64
      },
      vb:column { spacing = -144,
        vb:row { spacing = 3,
          vb:column {
            pht_fav_buttons_4(),
            pht_fav_buttons_3(),
            vb:space { height = 2 },
            pht_fav_buttons_2(),
            pht_fav_buttons_1(),
          },
          PHT_FAV_ROT
        },
        PHT_FAV_SHOW_KEYS_X32
      }
    }
  },
  PHT_FAV_MAIN_BUTTONS
}
---
local content_fav = vb:column { margin = 6,
  PHT_FAV_BUTTONS
}



------------------------------------------------------------------------------------------------
--show dialog_fav
function show_tool_dialog_fav()
  --Avoid showing the same window several times!
  if ( dialog_fav and dialog_fav.visible ) then dialog_fav:show() return end
  dialog_fav = rna:show_custom_dialog( title_fav, content_fav, pht_keyhandler )
end
