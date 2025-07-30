--
-- MIDI_IN PANEL_FAV
--



-----------------------------------------------------------------------------------------------
--midi_in pads (1, 32)
for i = 1, 64 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:FavTouch:Pads:"..( "Pad %.2d" ):format( i ),
    invoke = function( message )
      if message:is_trigger() then
        return pht_osc_bt_pres_fav( i )
      else
        return pht_osc_bt_sus_fav( i )
      end
    end
  }
end



-----------------------------------------------------------------------------------------------
--selector & volume rotary
local pht_fav_pad_sel_pos = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Rotary:Pad Selector Rotary",
  invoke = function( message )
    if message:is_abs_value() then
      if ( vws.PHT_FAV_X64.visible == false ) then
        local val = math.floor( ( message.int_value + 1 ) / 4 )
        if ( pht_fav_pad_sel_pos == math.floor( vws.PHT_FAV_ROT_SEL.value ) ) then
          vws.PHT_FAV_ROT_SEL.value = val
        end
        pht_fav_pad_sel_pos = val --soft takeover
      else
        local val = math.floor( ( message.int_value + 1 ) / 2 )
        if ( pht_fav_pad_sel_pos == math.floor( vws.PHT_FAV_ROT_SEL.value ) ) then
          vws.PHT_FAV_ROT_SEL.value = val
        end
        pht_fav_pad_sel_pos = val --soft takeover
      end
    end
  end
}
---
local pht_fav_vol_pos = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Rotary:Volume Rotary",
  invoke = function( message )
    if message:is_abs_value() then
      local val = message.int_value
      if ( pht_fav_vol_pos == math.floor( vws.PHT_FAV_ROT_VEL.value ) ) then
        vws.PHT_FAV_ROT_VEL.value = val
      end
      pht_fav_vol_pos = val --soft takeover
    end
  end
}



-----------------------------------------------------------------------------------------------
--panic & reset buttons
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Panic & Reset:Panic Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_fav_panic()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Panic & Reset:Reset Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_fav_reset()
    else
      return
    end
  end
}


-----------------------------------------------------------------------------------------------
--all, sus, jump & auto checkboxes

rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Sustain Mode:All Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      pht_fav_touch_all_mode()
    else
      return
    end
  end
}
--
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Sustain Mode:Sus Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      pht_fav_sustain_mode()
    else
      return
    end
  end
}
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Selector Mode:Jump Checkox",
  invoke = function( message )
    if message:is_trigger() then
      pht_fav_jump_select()
    else
      return
    end
  end
}
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Selector Mode:Auto Checkox",
  invoke = function( message )
    if message:is_trigger() then
      pht_fav_auto_deselect()
    else
      return
    end
  end
}


-----------------------------------------------------------------------------------------------
--x64, USB keyboard, Pad/SEL, anchor, PhraseTouch
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:x64 Pads Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_fav_x64()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:USB Keyboard Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_fav_keyboard()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Pad/SEL Switch",
  invoke = function( message )
    if message:is_trigger() then
      if ( vws.PHT_FAV_SW_TR_PAD_SEL.value == 1 ) then
        vws.PHT_FAV_SW_TR_PAD_SEL.value = 2
      else
        vws.PHT_FAV_SW_TR_PAD_SEL.value = 1
      end
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Anchor Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_fav_anchor()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:FavTouch:Show PhraseTouch Window Button",
  invoke = function( message )
    if message:is_trigger() then
      return show_tool_dialog()
    else
      return
    end
  end
}
