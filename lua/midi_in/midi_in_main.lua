--
-- MIDI_IN MAIN
--



-----------------------------------------------------------------------------------------------
--main panic & main unmark
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Main Panic Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_panic_main( 0, 119 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Main Unmark Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_unmark_main( 0, 119 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--play, stop, edit mode, undo, redo
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Play Pattern Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_play_pattern()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Stop Pattern Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_stop_pattern()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Edit Mode Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_edit_mode()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Undo Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_undo()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Redo Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_redo()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--show pattern editor, show phrase editor, show plugin editor, show midi monitor, show step sequencer window, show favtouch window
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Pattern Editor Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_jump_pattern_editor()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Phrase Editor Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_jump_phrase_editor()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show/Hide Plugin External Editor Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_show_plugin()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show MIDI Monitor Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_show_midi()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Step Sequencer Window Button",
  invoke = function( message )
    if message:is_trigger() then
      return show_tool_dialog_sequencer()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show FavTouch Window Button",
  invoke = function( message )
    if message:is_trigger() then
      return show_tool_dialog_fav()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--show miscellaneous I, first phrase, previous phrase, next phrase, last phrase
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Miscellaneous I Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_misc_mode_1_add_timer() --pht_miscellaneous_mode_1()
    else
      return pht_misc_mode_1_remove_timer()
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:First Phrase Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_phrase_first()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Previous Phrase Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_phrase_prev_repeat()
    else
      return pht_phrase_prev_repeat( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Next Phrase Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_phrase_next_repeat()
    else
      return pht_phrase_next_repeat( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Last Phrase Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_phrase_last()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--show miscellaneous II
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Miscellaneous II Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_miscellaneous_mode_2()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--show keyboard commmands, show about phrasetouch & help, compact mode view
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Keyboard Commands Button",
  invoke = function( message )
    if message:is_trigger() then
      return show_tool_dialog_keyboard()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show About & User Guide Button",
  invoke = function( message )
    if message:is_trigger() then
      return show_tool_dialog_about()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Compact Mode View Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_compact_mode()
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--panel selectors
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Panel Selector Group 1 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_gr( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Panel Selector Group 5 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_gr( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Panel Selector Group 9 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_gr( 3 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Panel Selector Group 13 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_gr( 4 )
    else
      return
    end
  end
}
---
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show A Note Panel Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_mn( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Two Note Panels Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_mn( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:Show Four Note Panels Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sel_pnl_mn( 3 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--general
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Main Touch All Checkbox (ALL)",
  invoke = function( message )
    if message:is_trigger() then
      return pht_asp_multi( 1 ), pht_touch_all_mode_multi( PHT_ASP_MULTI[1] )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Main Sustain Checkbox (SUS)",
  invoke = function( message )
    if message:is_trigger() then
      return pht_asp_multi( 2 ), pht_sustain_mode_multi( PHT_ASP_MULTI[2] )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Main Pressed & Released Checkbox (P/R)",
  invoke = function( message )
    if message:is_trigger() then
      return pht_asp_multi( 3 ), pht_pres_rel_mode_multi( PHT_ASP_MULTI[3] )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Auto Distribute Tracks Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_distrib_track()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Auto Distribute Instruments Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_distrib_instr()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Main Lock/Unlock Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_lock_tr_ins_multi()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:Main Anchor Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_anchor_tr_ins_multi()
    else
      return
    end
  end
}
---
local pht_kbd_pnl_pos = 0
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Main Controls:General:USB Keyboard Panel Selector Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      local val = math.floor( message.int_value * 17/128 + 1 )
      if ( pht_kbd_pnl_pos == PHT_VB_NOTES.value ) then
        PHT_VB_NOTES.value = val
      end
      pht_kbd_pnl_pos = val
    end
  end
}
