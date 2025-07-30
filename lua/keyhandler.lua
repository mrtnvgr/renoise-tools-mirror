--
-- KEYHANDLER
--



-----------------------------------------------------------------------------------------------
--keyboard notes
function pht_kt_keyboard_notes( note )
  local oct = song.transport.octave
  local nte = note + 12 * oct
  ---phrasetouch
  if ( PHT_VB_NOTES.value ==  1 ) and ( PHT_ASP_1[3] == true ) then pht_osc_bt_pres_1( nte ) end
  if ( PHT_VB_NOTES.value ==  2 ) and ( PHT_ASP_2[3] == true ) then pht_osc_bt_pres_2( nte ) end
  if ( PHT_VB_NOTES.value ==  3 ) and ( PHT_ASP_3[3] == true ) then pht_osc_bt_pres_3( nte ) end
  if ( PHT_VB_NOTES.value ==  4 ) and ( PHT_ASP_4[3] == true ) then pht_osc_bt_pres_4( nte ) end
  if ( PHT_VB_NOTES.value ==  5 ) and ( PHT_ASP_5[3] == true ) then pht_osc_bt_pres_5( nte ) end
  if ( PHT_VB_NOTES.value ==  6 ) and ( PHT_ASP_6[3] == true ) then pht_osc_bt_pres_6( nte ) end
  if ( PHT_VB_NOTES.value ==  7 ) and ( PHT_ASP_7[3] == true ) then pht_osc_bt_pres_7( nte ) end
  if ( PHT_VB_NOTES.value ==  8 ) and ( PHT_ASP_8[3] == true ) then pht_osc_bt_pres_8( nte ) end
  if ( PHT_VB_NOTES.value ==  9 ) and ( PHT_ASP_9[3] == true ) then pht_osc_bt_pres_9( nte ) end
  if ( PHT_VB_NOTES.value == 10 ) and ( PHT_ASP_10[3] == true ) then pht_osc_bt_pres_10( nte ) end
  if ( PHT_VB_NOTES.value == 11 ) and ( PHT_ASP_11[3] == true ) then pht_osc_bt_pres_11( nte ) end
  if ( PHT_VB_NOTES.value == 12 ) and ( PHT_ASP_12[3] == true ) then pht_osc_bt_pres_12( nte ) end
  if ( PHT_VB_NOTES.value == 13 ) and ( PHT_ASP_13[3] == true ) then pht_osc_bt_pres_13( nte ) end
  if ( PHT_VB_NOTES.value == 14 ) and ( PHT_ASP_14[3] == true ) then pht_osc_bt_pres_14( nte ) end
  if ( PHT_VB_NOTES.value == 15 ) and ( PHT_ASP_15[3] == true ) then pht_osc_bt_pres_15( nte ) end
  if ( PHT_VB_NOTES.value == 16 ) and ( PHT_ASP_16[3] == true ) then pht_osc_bt_pres_16( nte ) end
  ---favtouch
  if ( song.transport.octave == 0 ) then
    if ( PHT_VB_NOTES.value == 17 ) and ( nte <= 31 ) then pht_osc_bt_pres_fav( nte + 1 ) end  --range 0 to 63 (64 pads)
  end
  if ( song.transport.octave == 1 ) then
    if ( PHT_VB_NOTES.value == 17 ) and ( nte <= 63 ) then pht_osc_bt_pres_fav( nte + 21 ) end  --range 0 to 63 (64 pads)
  end
end



-----------------------------------------------------------------------------------------------
--octaves ("Oct")
function pht_kh_octaves( value )
  local octave = song.transport.octave + value
  if ( octave >= 0 ) and ( octave <= 8 ) then
    song.transport.octave = octave
  end
end



-----------------------------------------------------------------------------------------------
--panels (1 to 16 + FAV)
function pht_kh_panels( value )
  local panels = PHT_VB_NOTES.value + value
  if ( panels >= 1 ) and ( panels <= 17 ) then
    PHT_VB_NOTES.value = panels
  end
end



-----------------------------------------------------------------------------------------------
--up/down base note
function pht_kh_base_note( panel, value )
  local base = vws["PHT_TRANS_NOTE_"..panel].value + value
  if ( base >= 0 ) and ( base <= 119 ) then
    vws["PHT_TRANS_NOTE_"..panel].value = base
  end
end



-----------------------------------------------------------------------------------------------
--play/stop pattern
function pht_kh_play_stop_pattern( mode )
  local play_mode
  if ( mode == 1 ) then
    play_mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
    pht_change_status( "Restart the current pattern." )
  else
    play_mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
    pht_change_status( "Start & continue the current pattern." )
  end
  if not ( song.transport.playing ) then
    song.transport:start( play_mode )
  else
    song.transport:stop()
    song.transport:panic()
    pht_change_status( "Stop the current pattern & Panic the sound." )
  end
end



-----------------------------------------------------------------------------------------------
--play/stop step sequencer
function pht_kh_play_stop_seq()
  if ( PHT_SEQ_PLAY_STOP == true ) then
    pht_seq_play()
  else
    pht_seq_stop()
  end
end



-----------------------------------------------------------------------------------------------
--play/stop song & step sequencer
function pht_kh_play_stop_pattern_seq( mode )
  local play_mode
  if ( mode == 1 ) then
    play_mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
  else
    play_mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  end
  if not ( song.transport.playing ) then
    song.transport:start( play_mode )
    pht_seq_play()
  else
    pht_seq_stop()
    song.transport:stop()
    song.transport:panic()
    pht_change_status( "Stop the Step Sequencer & the current pattern & Panic the sound." )
  end
end



-----------------------------------------------------------------------------------------------
--edit mode, undo & redo
function pht_kh_edit_mode()
  if ( song.transport.edit_mode == false ) then
    song.transport.edit_mode = true
  else
    song.transport.edit_mode = false
  end
end
---
function pht_kh_undo()
  if ( song:can_undo() ) then
    song:undo()
  end
end
---
function pht_kh_redo()
  if ( song:can_redo() ) then
    song:redo()
  end
end



-----------------------------------------------------------------------------------------------
--import row / insert row
function pht_kh_import_row()
  pht_msc3_import_row()
  if ( song.selected_note_column ~= nil ) then
    local ins = vws.PHT_MSC3_EDIT_NOTES_INS.value
    local trk = song.selected_track_index 
    local nte = vws.PHT_MSC3_EDIT_NOTES_NTE.value
    local vel = vws.PHT_MSC3_EDIT_NOTES_VOL.value - 1
    pht_osc_client:trigger_instrument( true, ins, trk, nte, vel )
    local function trigger_row()
      pht_osc_client:trigger_instrument( false, ins, trk, nte )
      rnt:remove_timer( trigger_row )
    end
    if not rnt:has_timer( trigger_row ) then
      rnt:add_timer( trigger_row, 250 )
    end
  end
end
---
function pht_kh_insert_row()
  pht_msc3_insert_row()
  if ( song.selected_note_column ~= nil ) then
    local ins = vws.PHT_MSC3_EDIT_NOTES_INS.value
    local trk = song.selected_track_index 
    local nte = vws.PHT_MSC3_EDIT_NOTES_NTE.value
    local vel = vws.PHT_MSC3_EDIT_NOTES_VOL.value - 1
    pht_osc_client:trigger_instrument( true, ins, trk, nte, vel )
    local function trigger_row()
      pht_osc_client:trigger_instrument( false, ins, trk, nte )
      rnt:remove_timer( trigger_row )
    end
    if not rnt:has_timer( trigger_row ) then
      rnt:add_timer( trigger_row, 250 )
    end
  end
end



-----------------------------------------------------------------------------------------------
--left/right track | left/right note column
function pht_kh_nav_tracks( value )
  local raw = renoise.ApplicationWindow
  if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_PATTERN_EDITOR ) then
    rna.window.active_middle_frame = raw.MIDDLE_FRAME_PATTERN_EDITOR
    pht_change_status( "Pattern editor selected")
  end
  local sti = song.selected_track_index
  if ( value > 0 ) then
    if ( #song.tracks >= sti + value ) then
      song.selected_track_index = sti + value
    else
      song.selected_track_index = 1
    end
  else
    if ( 1 <= sti + value ) then
      song.selected_track_index = sti + value
    else
      song.selected_track_index = #song.tracks
    end
  end
end
---
function pht_kh_nav_note_columns( value )
  local raw = renoise.ApplicationWindow
  if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_PATTERN_EDITOR ) then
    rna.window.active_middle_frame = raw.MIDDLE_FRAME_PATTERN_EDITOR
    pht_change_status( "Pattern editor selected")
  end
  if ( song.selected_note_column ~= nil ) then
    if ( value > 0 ) then
      if ( song.selected_note_column_index < 12 ) and ( song.selected_track.visible_note_columns > song.selected_note_column_index ) then
        song.selected_note_column_index = song.selected_note_column_index + 1
      else
        if ( song.selected_track.visible_effect_columns > 0 ) then
          song.selected_effect_column_index = 1 --jump note column to effect column
        end
      end
    else
      if ( song.selected_note_column_index > 1 ) then
        song.selected_note_column_index = song.selected_note_column_index - 1
      end
    end
  else
    if ( value > 0 ) then
      if ( song.selected_effect_column_index < 8 ) and ( song.selected_track.visible_effect_columns > song.selected_effect_column_index ) then
        song.selected_effect_column_index = song.selected_effect_column_index + 1
      end
    else
      if ( song.selected_effect_column_index > 1 ) then
        song.selected_effect_column_index = song.selected_effect_column_index - 1
      else
        if ( song.selected_track.visible_note_columns > 0 ) then
          song.selected_note_column_index = song.selected_track.visible_note_columns
        end
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down line
function pht_kh_nav_lines( value )
  local sli = song.selected_line_index
  local nol = song.selected_pattern.number_of_lines
  if ( value > 0 ) then
    if ( nol >= sli + value ) then
      song.selected_line_index = sli + value
    else
      if ( song.selected_sequence_index + 1 <= #song.sequencer.pattern_sequence ) then
        song.selected_sequence_index = song.selected_sequence_index + 1
        song.selected_line_index = 1
      end
    end
  else
    if ( 1 <= sli + value ) then
      song.selected_line_index = sli + value
    else
      if ( song.selected_sequence_index - 1 >= 1 ) then
        song.selected_sequence_index = song.selected_sequence_index - 1
        song.selected_line_index = song.selected_pattern.number_of_lines
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down edit_step
function pht_kh_nav_edit_step( value )
  local sli = song.selected_line_index
  local nol = song.selected_pattern.number_of_lines
  local edit_step = song.transport.edit_step
  if ( value > 0 ) then
    if ( nol >= sli + edit_step ) then
      song.selected_line_index = sli + edit_step
    else
      local difference = edit_step - ( nol - sli )
      --print(difference)
      if ( song.selected_sequence_index + 1 <= #song.sequencer.pattern_sequence ) then
        song.selected_sequence_index = song.selected_sequence_index + 1
        if ( difference <= song.selected_pattern.number_of_lines ) then
          song.selected_line_index = difference
        else
          song.selected_line_index = 1
        end
      else
        song.selected_line_index = song.selected_pattern.number_of_lines
      end
    end
  else
    local difference = edit_step - sli
    --print(difference)
    if ( sli > edit_step ) then
      song.selected_line_index = song.selected_line_index - edit_step
    else
      if ( song.selected_sequence_index - 1 >= 1 ) then
        song.selected_sequence_index = song.selected_sequence_index - 1
        if ( 1 <= song.selected_pattern.number_of_lines - difference ) then
          song.selected_line_index = song.selected_pattern.number_of_lines - difference
        end
      else
        song.selected_line_index = 1
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down sequence
function pht_kh_nav_sequence( value )
  local ssi = song.selected_sequence_index
  local sps = #song.sequencer.pattern_sequence
  if ( value > 0 ) then
    if ( sps >= ssi + value ) then
      song.selected_sequence_index = ssi + value
    else
      song.selected_sequence_index = 1
    end
  else
    if ( 1 <= ssi + value ) then
      song.selected_sequence_index = ssi + value
    else
      song.selected_sequence_index = sps
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down instrument
function pht_kh_nav_instrument( value )
  local sii = song.selected_instrument_index
  local sin = #song.instruments
  if ( value > 0 ) then
    if ( sin >= sii + value ) then
      song.selected_instrument_index = sii + value
    else
      song.selected_instrument_index = 1
    end
  else
    if ( 1 <= sii + value ) then
      song.selected_instrument_index = sii + value
    else
      song.selected_instrument_index = sin
    end
  end
end



-----------------------------------------------------------------------------------------------
--previous/next phrase
function pht_kh_nav_phrase( value )
  local raw = renoise.ApplicationWindow
  if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and ( rna.window.instrument_editor_is_detached == false ) then
    rna.window.active_middle_frame = raw.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
    pht_change_status( "Phrase editor selected")
  end
  local ins = song.selected_instrument
  if ( song.selected_phrase_index > 0 ) then
    local phrase = song.selected_phrase_index + value
    if ( phrase >= 1 ) and ( phrase <= #ins.phrases ) then
      song.selected_phrase_index = phrase
    end
  end
end



-----------------------------------------------------------------------------------------------
--panels navigation
function pht_kh_panel_nav()
  if ( PHT_COMPACT_MODE_STATUS == false ) then
    pht_compact_mode()
  else
    return
  end
end


-----------------------------------------------------------------------------------------------
--note off | note empty
function pht_kh_note_off()
  if ( song.selected_note_column ~= nil ) then
    song.selected_note_column:clear() --clear
    song.selected_note_column.note_value = 120 --off
  end
end
---
function pht_kh_note_empty()
  if ( song.selected_note_column ~= nil ) then
    song.selected_note_column:clear() --clear
    song.selected_note_column.note_value = 121 --empty
  end
end



-----------------------------------------------------------------------------------------------
--keyhandler
function pht_keyhandler( dialog, key )

  print("name:", key.name, "|   modifiers:", key.modifiers, "|   character:", key.character, "|   note:", key.note, "|   repeated:", key.repeated )

  --keyboard notes
  for i = 0, 31 do --32 notes
    if not ( key.modifiers == "control" ) and ( key.note == i ) and not ( key.repeated ) then pht_kt_keyboard_notes( key.note ) end
  end
  
  --octaves ("Oct")
  if not ( key.modifiers == "control" ) and ( key.name == "numpad /") then if not ( key.repeated ) then pht_kh_octaves( -1 ) else pht_kh_octaves( -1 ) end end
  if not ( key.modifiers == "control" ) and ( key.name == "numpad *") then if not ( key.repeated ) then pht_kh_octaves( 1 ) else pht_kh_octaves( 1 ) end end

  --panels (1 to 16 + FAV)
  if ( key.modifiers == "control" ) and ( key.name == "numpad /") then if not ( key.repeated ) then pht_kh_panels( -1 ) else pht_kh_panels( -1 ) end end
  if ( key.modifiers == "control" ) and ( key.name == "numpad *") then if not ( key.repeated ) then pht_kh_panels( 1 ) else pht_kh_panels( 1 ) end end
  if ( key.modifiers == "control" ) and ( key.name == "numlock") and not ( key.repeated ) then pht_fav_keyboard() end
  

  --up/down base note
  if not ( key.modifiers == "shift + control" ) and ( key.modifiers == "control" ) then
    if ( key.name == "1" ) then if not ( key.repeated ) then pht_kh_base_note( 1, -1 )  else pht_kh_base_note( 1, -1 ) end end
    if ( key.name == "2" ) then if not ( key.repeated ) then pht_kh_base_note( 2, -1 )  else pht_kh_base_note( 2, -1 ) end end
    if ( key.name == "3" ) then if not ( key.repeated ) then pht_kh_base_note( 3, -1 )  else pht_kh_base_note( 3, -1 ) end end
    if ( key.name == "4" ) then if not ( key.repeated ) then pht_kh_base_note( 4, -1 )  else pht_kh_base_note( 4, -1 ) end end
    if ( key.name == "5" ) then if not ( key.repeated ) then pht_kh_base_note( 5, -1 )  else pht_kh_base_note( 5, -1 ) end end
    if ( key.name == "6" ) then if not ( key.repeated ) then pht_kh_base_note( 6, -1 )  else pht_kh_base_note( 6, -1 ) end end
    if ( key.name == "7" ) then if not ( key.repeated ) then pht_kh_base_note( 7, -1 )  else pht_kh_base_note( 7, -1 ) end end
    if ( key.name == "8" ) then if not ( key.repeated ) then pht_kh_base_note( 8, -1 )  else pht_kh_base_note( 8, -1 ) end end
    if ( key.name == "9" ) then if not ( key.repeated ) then pht_kh_base_note( 9, -1 )  else pht_kh_base_note( 9, -1 ) end end
    if ( key.name == "0" ) then if not ( key.repeated ) then pht_kh_base_note( 10, -1 ) else pht_kh_base_note( 10, -1 ) end end
    if ( key.name == "'" ) then if not ( key.repeated ) then pht_kh_base_note( 11, -1 ) else pht_kh_base_note( 11, -1 ) end end
    if ( key.name == "¡" ) then if not ( key.repeated ) then pht_kh_base_note( 12, -1 ) else pht_kh_base_note( 12, -1 ) end end
  end
  if not ( key.modifiers == "control" ) and ( key.modifiers == "shift + control" ) then
    if ( key.name == "1" ) then if not ( key.repeated ) then pht_kh_base_note( 1, 1 )  else pht_kh_base_note( 1, 1 ) end end
    if ( key.name == "2" ) then if not ( key.repeated ) then pht_kh_base_note( 2, 1 )  else pht_kh_base_note( 2, 1 ) end end
    if ( key.name == "3" ) then if not ( key.repeated ) then pht_kh_base_note( 3, 1 )  else pht_kh_base_note( 3, 1 ) end end
    if ( key.name == "4" ) then if not ( key.repeated ) then pht_kh_base_note( 4, 1 )  else pht_kh_base_note( 4, 1 ) end end
    if ( key.name == "5" ) then if not ( key.repeated ) then pht_kh_base_note( 5, 1 )  else pht_kh_base_note( 5, 1 ) end end
    if ( key.name == "6" ) then if not ( key.repeated ) then pht_kh_base_note( 6, 1 )  else pht_kh_base_note( 6, 1 ) end end
    if ( key.name == "7" ) then if not ( key.repeated ) then pht_kh_base_note( 7, 1 )  else pht_kh_base_note( 7, 1 ) end end
    if ( key.name == "8" ) then if not ( key.repeated ) then pht_kh_base_note( 8, 1 )  else pht_kh_base_note( 8, 1 ) end end
    if ( key.name == "9" ) then if not ( key.repeated ) then pht_kh_base_note( 9, 1 )  else pht_kh_base_note( 9, 1 ) end end
    if ( key.name == "0" ) then if not ( key.repeated ) then pht_kh_base_note( 10, 1 ) else pht_kh_base_note( 10, 1 ) end end
    if ( key.name == "'" ) then if not ( key.repeated ) then pht_kh_base_note( 11, 1 ) else pht_kh_base_note( 11, 1 ) end end
    if ( key.name == "¡" ) then if not ( key.repeated ) then pht_kh_base_note( 12, 1 ) else pht_kh_base_note( 12, 1 ) end end
  end
  
  --main panic for all panels
  if ( key.name == "º" ) and not ( key.repeated ) then pht_panic_main( 0, 119 ) end

  --play/stop pattern
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "space" ) and not ( key.repeated ) then pht_kh_play_stop_pattern( 1 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "ralt" ) and not ( key.repeated ) then pht_kh_play_stop_pattern( 2 ) end

  --play/stop step sequencer
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "return" ) and not ( key.repeated ) then pht_kh_play_stop_seq() end
  if not ( key.modifiers == "alt" ) and ( key.modifiers == "control" ) and ( key.name == "return" ) and not ( key.repeated ) then pht_seq_play() end


  --play/stop pattern & step sequencer
  if ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "space" ) and not ( key.repeated ) then pht_kh_play_stop_pattern_seq( 1 ) end
  if not ( key.modifiers == "control" ) and ( key.modifiers == "alt" ) and ( key.name == "space" ) and not ( key.repeated ) then pht_kh_play_stop_pattern_seq( 2 ) end

  --edit mode, undo & redo
  if ( key.name == "esc" ) and not ( key.repeated ) then pht_kh_edit_mode() end
  
  --import row / insert row
  if ( key.name == "apps" ) and not ( key.repeated ) then pht_kh_import_row() end
  if ( key.name == "rcontrol" ) and not ( key.repeated ) then pht_kh_insert_row() end
  
  --note off & note empty, clear multiple values (advanced editor panel)
  if ( key.name == "a" ) and not ( key.repeated ) then pht_kh_note_off() end
  if ( key.name == "capital" ) and not ( key.repeated ) then pht_kh_note_empty() end
  if ( key.name == "del" ) and not ( key.repeated ) then pht_msc3_clear_data() end
  
  --undo/redo
  if ( key.modifiers == "control" ) and ( key.name == "z" ) then if not ( key.repeated ) then pht_kh_undo() else pht_kh_undo() end end
  if ( key.modifiers == "control" ) and ( key.name == "y" ) then if not ( key.repeated ) then pht_kh_redo() else pht_kh_redo() end end

  --left/right note/effect column
  if not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "left" ) then
    if not ( key.repeated ) then pht_kh_nav_note_columns( -1 ) else pht_kh_nav_note_columns( -1 ) end   
  end
  ---
  if not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "right" ) then
    if not ( key.repeated ) then pht_kh_nav_note_columns( 1 ) else pht_kh_nav_note_columns( 1 ) end   
  end
  
  --swap row left/right between note columns
  if not ( key.modifiers == "control" ) and ( key.modifiers == "alt" ) and ( key.name == "left" ) then
    if not ( key.repeated ) then pht_msc3_move_note_l() else pht_msc3_move_note_l() end   
  end
  ---
  if not ( key.modifiers == "control" ) and ( key.modifiers == "alt" ) and ( key.name == "right" ) then
    if not ( key.repeated ) then pht_msc3_move_note_r() else pht_msc3_move_note_r() end   
  end
  
  --swap row up/down between note columns
  if not ( key.modifiers == "shift + control") and not ( key.modifiers == "control" ) and ( key.modifiers == "alt" ) and ( key.name == "up" ) then
    if not ( key.repeated ) then pht_msc3_move_note_u() else pht_msc3_move_note_u() end   
  end
  ---
  if not ( key.modifiers == "shift + control") and not ( key.modifiers == "control" ) and ( key.modifiers == "alt" ) and ( key.name == "down" ) then
    if not ( key.repeated ) then pht_msc3_move_note_d() else pht_msc3_move_note_d() end   
  end
  
  --left/right track  
  if ( key.modifiers == "shift" ) and ( key.name == "tab" ) then
   if not ( key.repeated ) then pht_kh_nav_tracks( -1 ) else pht_kh_nav_tracks( -1 ) end
  end
  ---
  if not ( key.modifiers == "shift" ) and ( key.name == "tab" ) then
   if not ( key.repeated ) then pht_kh_nav_tracks( 1 ) else pht_kh_nav_tracks( 1 ) end
  end

  --up/down line
  if not ( key.modifiers == "shift + control") and not ( key.modifiers == "shift" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "up" ) then
    if not ( key.repeated ) then pht_kh_nav_lines( -1 ) else pht_kh_nav_lines( -1 )end
  end
  ---
  if not ( key.modifiers == "shift + control") and not ( key.modifiers == "shift" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "down" ) then
    if not ( key.repeated ) then pht_kh_nav_lines( 1 ) else pht_kh_nav_lines( 1 )end
  end

  --up/down edit_step
  if ( key.modifiers == "shift + control") and not ( key.modifiers == "shift" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "up" ) then
    if not ( key.repeated ) then pht_kh_nav_edit_step( -1 ) else pht_kh_nav_edit_step( -1 )end
  end
  ---
  if ( key.modifiers == "shift + control") and not ( key.modifiers == "shift" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "alt" ) and ( key.name == "down" ) then
    if not ( key.repeated ) then pht_kh_nav_edit_step( 1 ) else pht_kh_nav_edit_step( 1 )end
  end

  --up/down sequence
  if not ( key.modifiers == "shift + control") and ( key.modifiers == "control" ) and ( key.name == "up" ) then
    if not ( key.repeated ) then pht_kh_nav_sequence( -1 ) else pht_kh_nav_sequence( -1 ) end
  end
  ---
  if not ( key.modifiers == "shift + control") and ( key.modifiers == "control" ) and ( key.name == "down" ) then
    if not ( key.repeated ) then pht_kh_nav_sequence( 1 ) else pht_kh_nav_sequence( 1 ) end
  end
  
  --up/down instrument
  if not ( key.modifiers == "control" ) and not ( key.modifiers == "alt + control" ) and ( key.name == "numpad -" ) then
    if not ( key.repeated ) then pht_kh_nav_instrument( -1 ) else pht_kh_nav_instrument( -1 ) end
  end
  ---
  if not ( key.modifiers == "control" ) and not ( key.modifiers == "alt + control" ) and ( key.name == "numpad +" ) then
    if not ( key.repeated ) then pht_kh_nav_instrument( 1 ) else pht_kh_nav_instrument( 1 ) end
  end

  --previous/next phrase
  if ( key.modifiers == "control" ) and ( key.name == "numpad -" ) then
    if not ( key.repeated ) then pht_kh_nav_phrase( -1 ) else pht_kh_nav_phrase( -1 ) end
  end
  ---
  if ( key.modifiers == "control" ) and ( key.name == "numpad +" ) then
    if not ( key.repeated ) then pht_kh_nav_phrase( 1 ) else pht_kh_nav_phrase( 1 ) end
  end

  --previous/next plugin preset
  if ( key.modifiers == "alt + control" ) and ( key.name == "numpad -" ) then
    if not ( key.repeated ) then pht_prev_plug_pres() else pht_prev_plug_pres() end
  end
  ---
  if ( key.modifiers == "alt + control" ) and ( key.name == "numpad +" ) then
    if not ( key.repeated ) then pht_next_plug_pres() else pht_next_plug_pres() end
  end
  
  --panels navigation
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f1" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_gr( 1 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f2" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_gr( 2 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f3" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_gr( 3 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f4" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_gr( 4 ) end
  ---  
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f5" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_mn( 1 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f6" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_mn( 2 ) end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f7" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_mn( 3 ) end
  ---
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f8" ) and not ( key.repeated ) then pht_kh_panel_nav() pht_sel_pnl_gr( 1 ) pht_sel_pnl_mn( 1 ) end
  ---
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f9"  ) and not ( key.repeated ) then pht_jump_pattern_editor() end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f10" ) and not ( key.repeated ) then pht_jump_phrase_editor() end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f11" ) and not ( key.repeated ) then pht_show_plugin() end
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "f12" ) and not ( key.repeated ) then pht_show_midi() end

  --multitouch for each panel, 1 to 12
  if ( key.modifiers == "alt" ) and ( key.name == "f1" ) and not ( key.repeated ) then pht_pln_name_multi( "_1" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f2" ) and not ( key.repeated ) then pht_pln_name_multi( "_2" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f3" ) and not ( key.repeated ) then pht_pln_name_multi( "_3" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f4" ) and not ( key.repeated ) then pht_pln_name_multi( "_4" ) end
  ---  
  if ( key.modifiers == "alt" ) and ( key.name == "f5" ) and not ( key.repeated ) then pht_pln_name_multi( "_5" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f6" ) and not ( key.repeated ) then pht_pln_name_multi( "_6" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f7" ) and not ( key.repeated ) then pht_pln_name_multi( "_7" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f8" ) and not ( key.repeated ) then pht_pln_name_multi( "_8" ) end
  ---
  if ( key.modifiers == "alt" ) and ( key.name == "f9"  ) and not ( key.repeated ) then pht_pln_name_multi( "_9" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f10" ) and not ( key.repeated ) then pht_pln_name_multi( "_10" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f11" ) and not ( key.repeated ) then pht_pln_name_multi( "_11" ) end
  if ( key.modifiers == "alt" ) and ( key.name == "f12" ) and not ( key.repeated ) then pht_pln_name_multi( "_12" ) end

  --panic for each panel, 1 to 12
  if ( key.modifiers == "control" ) and ( key.name == "f1" ) and not ( key.repeated ) then pht_panic_1( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f2" ) and not ( key.repeated ) then pht_panic_2( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f3" ) and not ( key.repeated ) then pht_panic_3( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f4" ) and not ( key.repeated ) then pht_panic_4( 0, 119 ) end
  ---  
  if ( key.modifiers == "control" ) and ( key.name == "f5" ) and not ( key.repeated ) then pht_panic_5( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f6" ) and not ( key.repeated ) then pht_panic_6( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f7" ) and not ( key.repeated ) then pht_panic_7( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f8" ) and not ( key.repeated ) then pht_panic_8( 0, 119 ) end
  ---
  if ( key.modifiers == "control" ) and ( key.name == "f9"  ) and not ( key.repeated ) then pht_panic_9( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f10" ) and not ( key.repeated ) then pht_panic_10( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f11" ) and not ( key.repeated ) then pht_panic_11( 0, 119 ) end
  if ( key.modifiers == "control" ) and ( key.name == "f12" ) and not ( key.repeated ) then pht_panic_12( 0, 119 ) end
  
  --compact mode view
  if not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.name == "back" ) and not ( key.repeated ) then pht_compact_mode() end

  --show & close favtouch
  if ( key.modifiers == "control" ) and ( key.name == "f" ) and not ( key.repeated ) then show_tool_dialog_fav() end
  if ( key.modifiers == "alt + control" ) and ( key.name == "f" ) and not ( key.repeated ) then
    if ( dialog_fav and dialog_fav.visible ) then dialog_fav:close() show_tool_dialog() end
  end
  
  --show & close keyboard commands
  if ( key.modifiers == "control" ) and ( key.name == "k" ) and not ( key.repeated ) then show_tool_dialog_keyboard() end
  if ( key.modifiers == "alt + control" ) and ( key.name == "k" ) and not ( key.repeated ) then
    if ( dialog_keyboard and dialog_keyboard.visible ) then dialog_keyboard:close() show_tool_dialog() end
  end
  
  --show & close step sequencer
  if ( key.modifiers == "control" ) and ( key.name == "q" ) and not ( key.repeated ) then show_tool_dialog_sequencer() end
  if ( key.modifiers == "alt + control" ) and ( key.name == "q" ) and not ( key.repeated ) then
    if ( dialog_sequencer and dialog_sequencer.visible ) then dialog_sequencer:close() show_tool_dialog() end
  end

  --show & close color settings
  if ( key.modifiers == "control" ) and ( key.name == "w" ) and not ( key.repeated ) then show_tool_dialog_colors() end
  if ( key.modifiers == "alt + control" ) and ( key.name == "w" ) and not ( key.repeated ) then
    if ( dialog_colors and dialog_colors.visible ) then dialog_colors:close() show_tool_dialog() end
  end
  
  
  --close dialog
  if ( key.modifiers == "alt + control" ) and ( key.name == "p" ) and not ( key.repeated ) then if ( dialog and dialog.visible ) then dialog:close() end end  
end
