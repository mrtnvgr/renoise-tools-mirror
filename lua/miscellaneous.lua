--
-- MISDELLANEOUS
--



-------------------------------------------------------------------------------------------------
--miscellaneous 1
-------------------------------------------------------------------------------------------------

--duplicate instrument & duplicate phrase
function pht_duplicate_instrument()
  if ( rna.window.instrument_box_is_visible == false ) or ( rna.window.disk_browser_is_visible == false ) then
    rna.window.disk_browser_is_visible = true
    rna.window.instrument_box_is_visible = true
    pht_change_status( "Instrument box visible." )
    return
  else
    if ( #song.instruments < 255 ) then
      local sii = song.selected_instrument_index + 1
      song:insert_instrument_at( sii )
      song:instrument( sii ):copy_from( song.selected_instrument )
      song.selected_instrument_index = sii
      pht_change_status( "New instrument "..("%.2X"):format( sii - 1 ).." duplicated." )
      local raw = renoise.ApplicationWindow
      if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_PATTERN_EDITOR ) and ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_MIXER ) then
        rna.window.active_middle_frame = raw.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
      end
    else
      pht_change_status( "Impossible duplicate the selected instrument! (maximum instr. = 255 (FE)" )
    end
  end
end
---
function pht_duplicate_phrase()
  local ins = song.selected_instrument
  if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and
     ( rna.window.instrument_editor_is_detached == false ) or
     ( ins.phrase_editor_visible == false ) or
     ( ins.phrase_playback_mode ~= renoise.Instrument.PHRASES_PLAY_KEYMAP ) then
     pht_show_phrase_editor_keymap()
     show_tool_dialog()
     return
  else
    local sphi = song.selected_phrase_index
    if ( song.selected_phrase ~= nil ) then
      if ( #ins.phrases < 126 ) then
        local sphi_1 = sphi + 1
        ins:insert_phrase_at( sphi_1 )
        ins:phrase( sphi_1 ):copy_from( song.selected_phrase )
        song.selected_phrase_index = sphi_1
        pht_change_status( "New phrase "..("%.2X"):format( sphi_1 ).." duplicated." )
      else
        pht_change_status( "Impossible duplicate the selected phrase! (maximum phrases = 226 (7E)." )
      end
    else
      pht_change_status( "There is no phrase to duplicate. Create a phrase first or select an existing!" )
    end
  end
end
---
PHT_DUPLICATE_INS_PHR = vb:column { spacing = 4,
  vb:button {
    height = 25,
    width = 31,
    bitmap = "./ico/duplicate_instrument_ico.png",
    notifier = function() pht_duplicate_instrument() end,
    tooltip = "Duplicate selected instrument (always create a new instrument).\nBefore duplicating, show the Instrument Box if not visible"
  },
  vb:button {
    height = 25,
    width = 31,
    bitmap = "./ico/duplicate_phrase_ico.png",
    notifier = function() pht_duplicate_phrase()end,
    tooltip = "Duplicate selected phrase (always create a new phrase).\nBefore duplicating, show the Phrase Editor if not visible"
  }
}



-------------------------------------------------------------------------------------------------
--pattern & phrase export
function pht_patterns_track_to_phrases()
  local x = os.clock()
  local ssi = song.selected_sequence_index
  --sequence range selection
  local value_a = song.sequencer.selection_range[1]
  local value_b = song.sequencer.selection_range[2]
  local phra = #song.selected_instrument.phrases
  --print( "value_a:",value_a,"value_b:",value_b )
  local value_c = value_b - value_a
  local str = song.selected_track
  if ( #song.instruments <= 255 ) and ( value_a > 0 ) and ( value_c + phra <= 126 ) and ( str.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
    --locals for pattern properties
    local pt_vnc = str.visible_note_columns
    local pt_vec = str.visible_effect_columns
    local pt_vcv = str.volume_column_visible
    local pt_pcv = str.panning_column_visible
    local pt_dcv = str.delay_column_visible
    local pt_ecv = str.sample_effects_column_visible
    --select phrase editor
    local phrase_editor = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
    if ( rna.window.active_middle_frame ~= phrase_editor  ) then
      rna.window.active_middle_frame = phrase_editor
    end
    --iterate the range (1 until 126 phrases)
    local phri = phra + 1
    local pt_nol
    for i = 0, value_c do
      local idx = i + phri
      song.selected_sequence_index = value_a + i
      if ( PHT_PHRASES_NOL.value == 0 ) then
        pt_nol = song.selected_pattern.number_of_lines
      else
        pt_nol = PHT_PHRASES_NOL.value
      end
      --insert new phrase & clear first each phrase
      song.selected_instrument:insert_phrase_at( idx )
      song.selected_phrase_index = idx
      song.selected_phrase:clear()

      --phrases equal pattern-tracks
      local sph = song.selected_instrument:phrase( idx )
      local pt_tr = song.selected_pattern_track
      sph.number_of_lines = pt_nol
      sph.visible_note_columns = pt_vnc
      sph.visible_effect_columns = pt_vec

      sph.volume_column_visible = pt_vcv
      sph.panning_column_visible = pt_pcv
      sph.delay_column_visible = pt_dcv
      sph.sample_effects_column_visible = pt_ecv
      --lines
      for ln = 1, pt_nol do
        local ph_ln = sph:line( ln )
        local pt_ln = pt_tr:line( ln )
        if not ( pt_ln.is_empty ) then
          --for note columns
          for nc = 1, 12 do
            local pt_nc = pt_ln:note_column( nc )
            local ph_nc = ph_ln:note_column( nc )
            if not ( pt_nc.is_empty ) then
              ph_nc.note_value          = pt_nc.note_value
              ph_nc.volume_value        = pt_nc.volume_value
              ph_nc.panning_value       = pt_nc.panning_value
              ph_nc.delay_value         = pt_nc.delay_value
              ph_nc.effect_number_value = pt_nc.effect_number_value
              ph_nc.effect_amount_value = pt_nc.effect_amount_value
            end
          end
          --for effect columns
          for ec = 1, 8 do
            local pt_ec = pt_ln:effect_column( ec )
            local ph_ec = ph_ln:effect_column( ec )
            if not ( pt_ec.is_empty ) then
              ph_ec.number_value = pt_ec.number_value
              ph_ec.amount_value = pt_ec.amount_value
            end
          end
        end
      end
    end
    song.selected_sequence_index = value_b
    song.selected_phrase_index = 1
    song.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
    show_tool_dialog()
    local val_c = value_c + 1
    pht_change_status( "All the patterns-track "..("(%.3d)"):format( val_c ).." of sequence range are exported into "..("%.2X (%.3d)"):format( val_c, val_c ).." phrases of selected instrument." )
  end
  if ( value_a == 0 ) then
    song.selected_sequence_index = ssi
    pht_pattern_track_to_phrase()
  end
  if ( value_c + phra > 126 ) then
    pht_change_status( "Impossible export. Select first a sequence range (until "..("%s"):format( 126 - #song.selected_instrument.phrases )..") and a track or select another instrument!" )
  end
  if ( str.type ~= renoise.Track.TRACK_TYPE_SEQUENCER ) then
    pht_change_status( "Impossible export. Select first a track!" )
  end
  --print( string.format("elapsed time: %.4f ms", ( os.clock() - x ) * 1000) )
end
---
function pht_pattern_track_to_phrase()
  local pattern = song:pattern( song.selected_pattern_index )
  local pt_nol
  if ( PHT_PHRASES_NOL.value == 0 ) then
    pt_nol = pattern.number_of_lines
  else
    pt_nol = PHT_PHRASES_NOL.value
  end
  local str = song.selected_track
  local pt_vnc = str.visible_note_columns
  local pt_vec = str.visible_effect_columns

  local pt_vcv = str.volume_column_visible
  local pt_pcv = str.panning_column_visible
  local pt_dcv = str.delay_column_visible
  local pt_ecv = str.sample_effects_column_visible
  --if not phrase, create a phrase and select it
  if ( song.selected_phrase == nil ) then
    song.selected_instrument:insert_phrase_at( 1 )
    song.selected_phrase_index = 1
  end
  song.selected_phrase:clear()
  --show phrase editor and duplicate pattern-track to phrase
  if ( str.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
    local phrase_editor = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
    if ( rna.window.active_middle_frame ~= phrase_editor ) then
      rna.window.active_middle_frame = phrase_editor
    end
    local sph = song.selected_phrase
    local spt = song.selected_pattern_track
    sph.number_of_lines = pt_nol
    sph.visible_note_columns = pt_vnc
    sph.visible_effect_columns = pt_vec
    
    sph.volume_column_visible = pt_vcv
    sph.panning_column_visible = pt_pcv
    sph.delay_column_visible = pt_dcv
    sph.sample_effects_column_visible = pt_ecv
    
    for ln = 1, pt_nol do
      local ph_ln = sph:line( ln )
      local pt_ln = spt:line( ln )
      if not ( pt_ln.is_empty ) then
        --for note columns
        for nc = 1, 12 do
          local pt_nc = pt_ln:note_column( nc )
          local ph_nc = ph_ln:note_column( nc )
          if not ( pt_nc.is_empty ) then
            ph_nc.note_value          = pt_nc.note_value
            ph_nc.volume_value        = pt_nc.volume_value
            ph_nc.panning_value       = pt_nc.panning_value
            ph_nc.delay_value         = pt_nc.delay_value
            ph_nc.effect_number_value = pt_nc.effect_number_value
            ph_nc.effect_amount_value = pt_nc.effect_amount_value
          end
        end
      end
      --for effect columns
      for ec = 1, 8 do
        local pt_ec = pt_ln:effect_column( ec )
        local ph_ec = ph_ln:effect_column( ec )
        if not ( pt_ec.is_empty ) then
          ph_ec.number_value = pt_ec.number_value
          ph_ec.amount_value = pt_ec.amount_value
        end
      end
    end
  end
  song.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
  show_tool_dialog()
  local sphi = song.selected_phrase_index
  pht_change_status( "Selected pattern-track exported in the selected phrase "..("%.2X (%.3d)"):format( sphi, sphi ).."." )
end
---
function pht_phrase_to_pattern_track()
  local str = song.selected_track
  local sph = song.selected_phrase
  if sph == nil then
    rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
    pht_change_status( "The export operation is not possible. Create a phrase first or select an existing!" )
    return
  else
    local ph_nol = sph.number_of_lines
    local ph_vnc = sph.visible_note_columns
    local ph_vec = sph.visible_effect_columns
  
    local ph_vcv = sph.volume_column_visible
    local ph_pcv = sph.panning_column_visible
    local ph_dcv = sph.delay_column_visible
    local ph_ecv = sph.sample_effects_column_visible  
    if ( str.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
      rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR

      song.selected_pattern.number_of_lines = ph_nol
      str.visible_note_columns   = ph_vnc
      str.visible_effect_columns = ph_vec
      
      str.volume_column_visible  = ph_vcv
      str.panning_column_visible = ph_pcv
      str.delay_column_visible   = ph_dcv
      str.sample_effects_column_visible = ph_ecv

      local in_ph = song.selected_phrase
      local pt_tr = song.selected_pattern_track

      for ln = 1, ph_nol do
        local ph_ln = in_ph:line( ln )
        local pt_ln = pt_tr:line( ln )
        --for note columns
        for nc = 1, 12 do
          local pt_nc = pt_ln:note_column( nc )
          local ph_nc = ph_ln:note_column( nc )
          if not ph_nc.is_empty then
            pt_nc.note_value          = ph_nc.note_value
            if ( pt_nc.note_value < 120 ) then
              pt_nc.instrument_value  = song.selected_instrument_index - 1
            end
            pt_nc.volume_value        = ph_nc.volume_value
            pt_nc.panning_value       = ph_nc.panning_value
            pt_nc.delay_value         = ph_nc.delay_value
            pt_nc.effect_number_value = ph_nc.effect_number_value
            pt_nc.effect_amount_value = ph_nc.effect_amount_value
          end
        end
        --for effect columns
        for ec = 1, 8 do
          local pt_ec = pt_ln:effect_column( ec )
          local ph_ec = ph_ln:effect_column( ec )
          if not ph_ec.is_empty then
            pt_ec.number_value = ph_ec.number_value
            pt_ec.amount_value = ph_ec.amount_value
          end
        end
      end
    end
  end
  local sphi = song.selected_phrase_index
  local spi = song.selected_pattern_index -1
  local sti = song.selected_track_index
  pht_change_status( "Selected phrase "..("%.2X (%.3d)"):format( sphi, sphi ).." exported in the selected pattern-track "..("(pattern: %.3d - track: %.3d)"):format( spi, sti ).."." )
end
---
function pht_clear_phrase()
  local ins = song.selected_instrument
  if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and
     ( rna.window.instrument_editor_is_detached == false ) or
     ( ins.phrase_editor_visible == false ) or
     ( ins.phrase_playback_mode ~= renoise.Instrument.PHRASES_PLAY_KEYMAP ) then
     pht_show_phrase_editor_keymap()
     return
  else
    local sph = song.selected_phrase
    if sph ~= nil then
      sph:clear()
      pht_change_status( "Selected phrase cleaned." )
    end
  end
end
---
function pht_delete_all_phrases()
  local ins = song.selected_instrument
  if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and
     ( rna.window.instrument_editor_is_detached == false ) or
     ( ins.phrase_editor_visible == false ) or
     ( ins.phrase_playback_mode ~= renoise.Instrument.PHRASES_PLAY_KEYMAP ) then
     pht_show_phrase_editor_keymap()
     return
  else
    local all_phrases = #ins.phrases
    if ( all_phrases > 0 ) then
      for i = all_phrases, 1, -1 do
        ins:delete_phrase_at( i )
      end
      pht_change_status( "All the phrases have been deleted of the selected instrument ("..all_phrases.." phrases)." )
    else
      pht_change_status( "The selected instrument does not contain any phrase to delete!" )
    end
  end
end
---
function pht_clear_pattern_track()
  local pattern_editor = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  if ( rna.window.active_middle_frame ~= pattern_editor ) then 
    rna.window.active_middle_frame = pattern_editor
    pht_change_status( "Pattern editor visible." )
    return
  else
    local spttr = song.selected_pattern_track
    if spttr ~= nil then
      spttr:clear()
      pht_change_status( "Selected pattern-track cleaned." )
    end
  end
end
---
PHT_PATTERN_PHRASE = vb:column { spacing = 4,
  vb:row { spacing = -3,
    vb:button {
      height = 25,
      width = 52,
      bitmap = "./ico/pattern_to_phrase_ico.png",
      notifier = function() pht_patterns_track_to_phrases() end,
      tooltip = "Export patterns-track on the phrases. Two modes of selection:\n"..
                "A) Pattern-track: export it in specific phrase of selected instrument.\n"..
                "   Steps:\n"..
                "   1) Select first a pattern-track (do not select any sequence range).\n"..
                "   2) Select a instrument & a specific phrase.\n"..
                "   3) If desired, specify the number of lines (\"Lines\" valuebox).\n"..
                "   4) Press the button to individual export.\n"..
                "   This operation overwrite the selected phrase or insert a phrase if the instrument does not have any.\n\n"..
                "B) Sequence range: export multiple patterns-track in phrases of selected instrument.\n"..
                "   Steps:\n"..
                "   1) Select first a sequence range (maximum 126 patterns in the sequence).\n"..
                "   2) Select a track & a destination instrument.\n"..
                "   3) If desired, specify the number of lines (\"Lines\" valuebox).\n"..
                "   4) Press the button to multiple export.\n"..
                "   This operation does not overwrite the existing phrases, but accumulates new phrases, until 126.\n\n"..
                "The export patterns-track will copy all values, independently of the instrument."
    },
    vb:button {
      height = 25,
      width = 13,
      color = PHT_MAIN_COLOR.RED_OFF,
      notifier = function() pht_clear_phrase() end,
      tooltip = "Clear the selected phrase"
    }
  },
  vb:row { spacing = -3,
    vb:button {
      height = 25,
      width = 52,
      bitmap = "./ico/phrase_to_pattern_ico.png",
      notifier = function() pht_phrase_to_pattern_track() end,
      tooltip = "Export the selected phrase on the selected pattern-track"
    },
    vb:button {
      height = 25,
      width = 13,
      color = PHT_MAIN_COLOR.RED_OFF,
      notifier = function() pht_clear_pattern_track() end,
      tooltip = "Clear the selected pattern-track"
    }
  }
}



-------------------------------------------------------------------------------------------------
--phrase editor keymap
function pht_show_phrase_editor_keymap()
  --instrument editor window
  rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
  --phrase editor tab visible
  song.selected_instrument.phrase_editor_visible = true
  --select mode to phrase ("Keymap")
  song.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
  if ( song.selected_phrase_index > 0 ) then
    song.selected_phrase_index = 1
  end
  pht_change_status( "Phrase editor visible & keymap playback mode." )
end
---
function pht_auto_keymap()
  local ins = song.selected_instrument
  if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and
     ( rna.window.instrument_editor_is_detached == false ) or
     ( ins.phrase_editor_visible == false ) or
     ( ins.phrase_playback_mode ~= renoise.Instrument.PHRASES_PLAY_KEYMAP ) then
     pht_show_phrase_editor_keymap()
     return
  else
    local value_a = vws.PHT_VB_MAP_FIRST_NOTE.value - 1
    local value_b = vws.PHT_VB_MAP_RANGE_NOTE.value - 1
    --corrects redo (not select any phrase!)
    if ( song.selected_phrase_index == 0 ) and ( #ins.phrases > 0 ) then
      song.selected_phrase_index = 1
    end
    --initial phrase index
    local sphi = song.selected_phrase_index
    --delete all phrase mappings
    for i = #ins.phrase_mappings, 1, -1 do
      ins:delete_phrase_mapping_at( i )
    end
    --insert all phrase mappings
    for i = 1, #ins.phrases do
      local val_i = i + sphi - 1
      if ( value_a + i * vws.PHT_VB_MAP_RANGE_NOTE.value <= 119 ) and ( val_i <= #ins.phrases ) then
        if ( ins:can_insert_phrase_mapping_at( i ) ) then
          local ph = ins:phrase( val_i )
          ins:insert_phrase_mapping_at( i, ph )
          if ( i == 1 ) then
            ph.mapping.note_range = { i + value_a, i + value_a + value_b }
          else
            ph.mapping.note_range = { ph.mapping.note_range[1], ph.mapping.note_range[1] + value_b }
          end
          ph.mapping.key_tracking = renoise.InstrumentPhraseMapping.KEY_TRACKING_TRANSPOSE
          ph.mapping.base_note = ph.mapping.note_range[1]
          ph.shuffle = vws.PHT_PHRASE_SHUFFLE.value / 100
          ph.autoseek = PHT_PHRASE_BT_ASK
          ph.mapping.looping = PHT_PHRASE_BT_LP
          --number of lines to phrases
          if ( PHT_PHRASES_NOL.value > 0 ) then
            ph.number_of_lines = PHT_PHRASES_NOL.value
          end
        end
      end
    end
    --reconfigure phrase index and tracking
    if ( #ins.phrase_mappings > 0 ) then
      song.selected_phrase_index = sphi
      vws.PHT_KEY_TRACKING.value = 2
      pht_change_status( "AutoKeymap has been executed successfully." )
    else
      pht_change_status( "AutoKeymap is not possible. Reconfigure it!" )
    end
  end
end
---
function pht_clear_keymap()
  if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR ) and
     ( rna.window.instrument_editor_is_detached == false ) or
     ( song.selected_instrument.phrase_editor_visible == false ) or
     ( song.selected_instrument.phrase_playback_mode ~= renoise.Instrument.PHRASES_PLAY_KEYMAP ) then
     pht_show_phrase_editor_keymap()
     return
  else
    --delete all phrases
    if #song.selected_instrument.phrase_mappings > 0 then
      for i = #song.selected_instrument.phrase_mappings, 1, -1 do
        song.selected_instrument:delete_phrase_mapping_at( i )
        pht_change_status( "Keymap of selected instrument cleaned." )
      end
    else
      pht_change_status( "This instrument is not keymapped!" )
    end
  end
end
---
PHT_KEYMAP_AND_CLEAR = vb:row { spacing = 4,
  vb:row { spacing = -3,
    vb:button {
      height = 25,
      width = 82,
      notifier = function() pht_auto_keymap() end,
      text = "AutoKeymap",
      tooltip = "AutoKeymap (assign one or more notes for each phrase)\nConfigure automatically the \"Keymap\" for the selected instrument that contains phrases. "..
                "This operation assign continuously a \"range of notes\" and a \"base note\" for each available phrase. Steps:\n"..
                "  1) Select a note in the valuebox to start the keymapping (from left to right).\n"..
                "  2) Select a range of notes for each phrase. [Range = 1 to 120].\n"..
                "  3) Select a initial available phrase.\n"..
                "  4) If you wish, configure the Number of Lines, Shuffle, Autoseek & Loop controls.\n"..
                "  5) Finally, press \"AutoKeymap\".\n"..
                "It is possible to assign 120 notes to 120 phrases (a instrument can contain up to 126 phrases)"
    },
    vb:button {
      height = 25,
      width = 13,
      color = PHT_MAIN_COLOR.RED_OFF,
      notifier = function() pht_clear_keymap() end,
      tooltip = "Clear all associations of the \"Keymap\" mode. Leave the selected instrument without notes associated with the phrases"
    }
  }
}



-------------------------------------------------------------------------------------------------
--phrase editor keymap
PHT_FIRST_NOTE_RANGE_VALUE = vb:row {
  vb:bitmap {
    height = 25,
    width = 19,
    mode = "body_color",
    bitmap = "./ico/phrase_range_ico.png"
  },
  vb:row { spacing = -109,
    vb:button {
      height = 25,
      width = 109,
      active = false,
    },
    vb:row { spacing = -1, margin = 2,
      vb:row { margin = -2,
        vb:valuebox {
          id = "PHT_VB_MAP_FIRST_NOTE",
          height = 25,
          width = 59,
          min = 0,
          max = 119,
          value = 36,
          tostring = function( number ) return pht_note_tostring ( number ) end,
          tonumber = function( string ) return pht_note_tonumber ( string ) end,
          tooltip = "First note to AutoKeymap\nSelect the first note to start the keymap to a phrases group\n[ Range = C-0 to B-9 ]"
        }
      },
      vb:row { margin = -2,
        vb:valuebox {
          id = "PHT_VB_MAP_RANGE_NOTE",
          height = 25,
          width = 55,
          min = 1,
          max = 120,
          value = 2,
          tostring = function( value ) return ( "%.3d" ):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          tooltip = "Range of notes to AutoKeymap\nDensity of notes to keymap each phrase\n[ Range = 1 to 120 ]"
        }
      }
    }
  }
}



-------------------------------------------------------------------------------------------------
--first/left/right phrase selector
function pht_phrase_first()
  if ( song.selected_phrase_index > 0 ) then
    song.selected_phrase_index = 1
    vws.PHT_IDX_PHRASE.text = "01"
    pht_change_status( "First phrase selected." )
  else 
    vws.PHT_IDX_PHRASE.text = "--"
    pht_change_status( "The selected instrument does not contain any phrase!" )
  end
end
---
function pht_phrase_last()
  if ( song.selected_phrase_index > 0 ) then
    local last = #song.selected_instrument.phrases
    song.selected_phrase_index = last
    vws.PHT_IDX_PHRASE.text = ("%.2X"):format( last )
    pht_change_status( "Last phrase selected." )
  else 
    vws.PHT_IDX_PHRASE.text = "--"
    pht_change_status( "The selected instrument does not contain any phrase!" )
  end
end
---
function pht_phrase_prev()
  if ( song.selected_phrase_index - 1 >= 1 ) then
    song.selected_phrase_index = song.selected_phrase_index - 1
    vws.PHT_IDX_PHRASE.text = ( "%.2X" ):format( song.selected_phrase_index )
    pht_change_status( "Previous phrase "..( "%.2X" ):format( song.selected_phrase_index ).." selected." )
  else
    if ( song.selected_phrase_index == 0 ) then
      vws.PHT_IDX_PHRASE.text = "--"
      pht_change_status( "The selected instrument does not contain any phrase!" )
    end
  end  
end
---
function pht_phrase_prev_repeat( release )
  if not release then
    if rnt:has_timer( pht_phrase_prev_repeat ) then
      pht_phrase_prev()
      rnt:remove_timer( pht_phrase_prev_repeat )
      rnt:add_timer( pht_phrase_prev, 40 )
    else
      pht_phrase_prev()
      rnt:add_timer( pht_phrase_prev_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_phrase_prev_repeat ) then
      rnt:remove_timer( pht_phrase_prev_repeat )
    elseif rnt:has_timer( pht_phrase_prev ) then
      rnt:remove_timer( pht_phrase_prev )
    end
  end
end
---
function pht_phrase_next()
  if ( song.selected_phrase_index + 1 <= #song.selected_instrument.phrases ) then
    song.selected_phrase_index = song.selected_phrase_index + 1
    vws.PHT_IDX_PHRASE.text = ( "%.2X" ):format( song.selected_phrase_index )
    pht_change_status( "Next phrase "..( "%.2X" ):format( song.selected_phrase_index ).." selected." )
  else
    if ( song.selected_phrase_index == 0 ) then
      vws.PHT_IDX_PHRASE.text = "--"
      pht_change_status( "The selected instrument does not contain any phrase!" )
    end
  end
end
---
function pht_phrase_next_repeat( release )
  if not release then
    if rnt:has_timer( pht_phrase_next_repeat ) then
      pht_phrase_next()
      rnt:remove_timer( pht_phrase_next_repeat )
      rnt:add_timer( pht_phrase_next, 40 )
    else
      pht_phrase_next()
      rnt:add_timer( pht_phrase_next_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_phrase_next_repeat ) then
      rnt:remove_timer( pht_phrase_next_repeat )
    elseif rnt:has_timer( pht_phrase_next ) then
      rnt:remove_timer( pht_phrase_next )
    end
  end
end
---
PHT_L_R_PHRASE = vb:row { spacing = -3,
  vb:button {
    height = 25,
    width = 16,
    bitmap = "./ico/phrase_first_ico.png",
    notifier = function() pht_phrase_first() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:First Phrase Button",
    tooltip = "Select first phrase of the selected instrument, if it exist"
  },
  vb:button {
    height = 25,
    width = 35,
    bitmap = "./ico/phrase_left_ico.png",
    pressed = function() pht_phrase_prev_repeat() end,
    released = function() pht_phrase_prev_repeat( true ) end,
    --notifier = function() pht_phrase_prev() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Previous Phrase Button",
    tooltip = "Select previous phrase of the selected instrument, if it exist"
  },
  vb:button {
    height = 25,
    width = 35,
    bitmap = "./ico/phrase_right_ico.png",
    pressed = function() pht_phrase_next_repeat() end,
    released = function() pht_phrase_next_repeat( true ) end,
    --notifier = function() pht_phrase_next() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Next Phrase Button",
    tooltip = "Select next phrase of the selected instrument, if it exist"
  },
  vb:button {
    height = 25,
    width = 16,
    bitmap = "./ico/phrase_last_ico.png",
    notifier = function() pht_phrase_last() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Last Phrase Button",
    tooltip = "Select last phrase of the selected instrument, if it exist"
  },
  vb:space { width = 4 },
  vb:row { margin = 1,
    vb:row { style = "plain",
      tooltip = "Show the last selected phrase index",
      vb:text {
        id = "PHT_IDX_PHRASE",
        height = 23,
        width = 26,
        align = "center",
        text = "--"
      }
    }
  },
  vb:button {
    height = 25,
    height = 25,
    width = 13,
    color = PHT_MAIN_COLOR.RED_OFF,
    notifier = function() pht_delete_all_phrases() end,
    tooltip = "Delete all the phrases inside the selected instrument"
  },
}



-------------------------------------------------------------------------------------------------
--shuffle, autoseek, loop & index phrase
function pht_mapped_phrase_properties()
  local ins = song.selected_instrument
  if ( #ins.phrase_mappings > 0 ) then
    for i = 1, #ins.phrases do
      local ph = ins:phrase( i )
      if ( ph.mapping ~= nil ) then
        ph.shuffle = vws.PHT_PHRASE_SHUFFLE.value / 100
        ph.autoseek = PHT_PHRASE_BT_ASK 
        ph.mapping.looping = PHT_PHRASE_BT_LP
        ph.mapping.key_tracking = vws.PHT_KEY_TRACKING.value
        --number of lines to phrases
        if ( PHT_PHRASES_NOL.value > 0 ) then
          ph.number_of_lines = PHT_PHRASES_NOL.value
        end
      end
    end
    pht_change_status( "The properties of all the keymapped phrases have been modified." )
  else
    pht_change_status( "There is no keymapped phrase to modify. Keymap a phrase first!" )
  end
end
---
PHT_PHRASE_BT_ASK = true
function pht_phrase_bt_ask()
  if ( PHT_PHRASE_BT_ASK == true ) then
    PHT_PHRASE_BT_ASK = false
    vws.PHT_PHRASE_AUTOSEEK.color = PHT_MAIN_COLOR.DEFAULT
  else
    PHT_PHRASE_BT_ASK = true
    vws.PHT_PHRASE_AUTOSEEK.color = PHT_MAIN_COLOR.GOLD_ON
  end
end
---
PHT_PHRASE_BT_LP = true
function pht_phrase_bt_loop()
  if ( PHT_PHRASE_BT_LP == true ) then
    PHT_PHRASE_BT_LP = false
    vws.PHT_PHRASE_LOOP.color = PHT_MAIN_COLOR.DEFAULT
  else
    PHT_PHRASE_BT_LP = true
    vws.PHT_PHRASE_LOOP.color = PHT_MAIN_COLOR.GOLD_ON
  end
end
---
PHT_PHRASES_NOL = vb:valuebox {
  height = 19,
  width = 55,
  min = 0,
  max = 512,
  value = 0,
  tostring = function( value ) if ( value > 0 ) then return ("%.3d"):format( value ) else return "n/a" end end,
  tonumber = function( value ) return tonumber( value ) end,
  tooltip = "Number of lines to phrases\n"..
            "Use with the operations:\n  -Export patterns-track to phrases\n  -AutoKeymap\n  -Modiffy properties\n[n/a = do not modify. Range = 1 to 512]"
}
---
PHT_SHUFFLE_AUTOSEEK_LOOP = vb:row { style = "panel", spacing = 5, margin = 2,
  vb:row { 
    vb:text {
      height = 19,
      width = 33,
      align = "right",
      text = "Lines",
    },
  PHT_PHRASES_NOL
  },
  vb:row { 
    vb:text {
      height = 19,
      width = 24,
      align = "right",
      text = "Shfl",
    },
    vb:valuebox {
      id = "PHT_PHRASE_SHUFFLE",
      height = 19,
      width = 67,
      min = 0,
      max = 100,
      value = 0,
      tostring = function( value ) return ("%.3d%s"):format( value, " %" ) end,
      tonumber = function( value ) return tonumber( value ) end,
      tooltip = "Adjust the \"Shuffle\" value to the \"AutoKeymap\" operation. It applies to all phrases!"
    }
  },
  vb:row { spacing = -3,
    vb:button {
      id = "PHT_PHRASE_AUTOSEEK",
      height = 19,
      width = 32,
      text = "Ask",
      color = PHT_MAIN_COLOR.GOLD_ON,
      notifier = function() pht_phrase_bt_ask() end,
      tooltip = "Enable \"Autoseek\" to the \"AutoKeymap\" operation. It applies to all phrases!"
    },
    vb:button {
      id = "PHT_PHRASE_LOOP",
      height = 19,
      width = 32,
      text = "Lp",
      color = PHT_MAIN_COLOR.GOLD_ON,
      notifier = function() pht_phrase_bt_loop() end,
      tooltip = "Enable \"Loop\" to the \"AutoKeymap\" operation. It applies to all phrases!"
    }
  },
  vb:switch {
    id = "PHT_KEY_TRACKING",
    height = 19,
    width = 53,    
    items = { "N", "T", "O" },
    value = 2,
    tooltip = "Keytracking selector\nN = Note\nT = Transpose\nO = Offset"
  },
  vb:row {
    vb:button {
      height = 19,
      width = 39,
      text = "Mod",
      notifier = function() pht_mapped_phrase_properties() end,
      tooltip = "Apply to keymap playing mode\nModify all keymapped phrases with the properties:\n"..
                "  -Number of lines (Lines)\n  -Shuffle (Shfl)\n  -Autoseeck (Ask)\n  -Loop (Lp)\n  -Keytracking (Note / Transpose / Offset)"
    },
    vb:space { width = 5 }
  }
}



-------------------------------------------------------------------------------------------------
--off, program, & keymap
function pht_off_prog_map( value )
  local ins = song.selected_instrument
  if ( value == 1 ) then
    ins.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
    pht_change_status( "Keymap playback mode selected (multiple phrases)." )
  elseif ( value == 2 ) then
    ins.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_SELECTIVE
    pht_change_status( "Program playback mode selected (individual phrase)." )
  else 
    ins.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
    pht_change_status( "Off playback mode selected (without phrases)." )
  end
end
---
PHT_OFF_PROG_MAP = vb:column { spacing = -3,
  vb:button {
    height = 20,
    width = 61,
    notifier = function() pht_off_prog_map( 1 ) end,
    text = "Keymap",
    tooltip = "Keymap playback mode to phrases\nUse the left controls to easily configure the Keymap for the selected instrument"
  },
  vb:button {
    height = 20,
    width = 61,
    notifier = function() pht_off_prog_map( 2 ) end,
    text = "Program",
    tooltip = "Program playback mode to phrases"
  },
  vb:button {
    height = 20,
    width = 61,
    notifier = function() pht_off_prog_map( 3 ) end,
    text = "Off",
    tooltip = "Off playback mode to phrases"
  }
}
---
PHT_MISCELLANEOUS_1 = vb:row { margin = 1,
  visible = false,
  vb:row { style = "panel", margin = 5, spacing = 7,
    PHT_DUPLICATE_INS_PHR,
    PHT_PATTERN_PHRASE,
    vb:column { spacing = 5,
      vb:row { spacing = 7,
        PHT_KEYMAP_AND_CLEAR,
        PHT_FIRST_NOTE_RANGE_VALUE,
        PHT_L_R_PHRASE
      },
      vb:row {
        vb:row { spacing = 1 },
        PHT_SHUFFLE_AUTOSEEK_LOOP,
      }
    },
    PHT_OFF_PROG_MAP
  }
}


-------------------------------------------------------------------------------------------------
--miscellaneous 2
-------------------------------------------------------------------------------------------------

--to import files
function pht_open_default_folder()
  rna:open_path("library/theme/")
end
---
function pht_open_prompt_folder()
  local ins = song.selected_instrument
  local sii = song.selected_instrument_index
  --local filename = rna:prompt_for_filename_to_read( { "*.xrns", "*.xrni", "*.xrnz" }, "Load a song, a instrument or a phrase" )
  local filename = rna:prompt_for_multiple_filenames_to_read( { "*.xrns", "*.rns", "*.ptk", "*.ntk", "*.xm", "*.it", "*.mod", "*.xrni", "*.xrnz" }, "Load a song, instrument(s) or phrase(s)" )
  --check equal extensions, two characters
  local load = true
  for i = 1, #filename do
    if ( string.sub( filename[ i ], -2 ) ~= string.sub( filename[ #filename ], -2 ) ) then
      load = false
      return
      pht_change_status( "Please, select only a extension type to load multiple files!" )
    end
  end
  --print("#filename",#filename)
  if ( #filename == 0 ) then
    return
    pht_change_status( "No file(s) loaded. Please, select before a file or a few files to load!" )  
  else
    if ( load == true ) then
      for i = 1, #filename do
        local file = filename[i]
        local extension_x2, extension_x3, extension_x4 = string.sub( file, -2 ), string.sub( file, -3 ), string.sub( file, -4 )
        ---song
        if ( extension_x4 == "xrns" ) or
           ( extension_x3 == "rns" )  or
           ( extension_x3 == "ptk" )  or
           ( extension_x3 == "ntk" )  or
           ( extension_x2 == "xm" )   or
           ( extension_x2 == "it" )   or
           ( extension_x3 == "mod" ) then
          if ( #filename == 1 ) then
            rna:load_song( file )
          else
            pht_change_status( "Please, select only a song or other extensions type to load!" )
            return
          end
        end
        ---instruments
        if ( extension_x4 == "xrni" ) then
          rna:load_instrument( file )
          if ( #song.instruments < 255 ) then
            song.selected_instrument_index = song.selected_instrument_index + 1
          else
            return
          end
        end
        ---phrases
        if ( extension_x4 == "xrnz" ) then
          song.selected_instrument_index = sii
          local sphi = song.selected_phrase_index
          if ( #ins.phrases < 126 ) then
            ins:insert_phrase_at( sphi + 1 )
            song.selected_phrase_index = sphi + 1
            rna:load_instrument_phrase( file )
          else
            return
          end
        end
      end
      pht_change_status( "Selected file(s) loaded ("..#filename.." files)..." )
    end
  end
end
---
PHT_FOLDER = vb:row { spacing = 3,
  vb:row { spacing = -3,
    vb:button {
      active = true,
      height = 25,
      width = 31,
      bitmap = "./ico/brush_ico.png",
      notifier = function() show_tool_dialog_colors() end,
      tooltip = "Show Color Settings Window...\n[Ctrl + W]  [Ctrl + Alt + W, to close]"
    },
    vb:button {
      active = true,
      height = 25,
      width = 33,
      bitmap = "./ico/theme_ico.png",
      notifier = function() pht_open_default_folder() end,
      tooltip = "Open default tool folder for load themes..."
    }
  },
  vb:button {
    active = true,
    height = 25,
    width = 45,
    bitmap = "./ico/folder_ex_ico.png",
    notifier = function() pht_open_prompt_folder() end,
    tooltip = "Import/load files to Renoise...\nTo load different compatible files (song, instrument(s), phrase(s)...\n"..
              "For multiple files, select a moderate amount. The amount is limited to load!"
  }
}
---
function pht_patch_brorwse_folder()
  local search_path = rna:prompt_for_path( "Select a folder to save all the selected files type." )
  PHT_PATH_FOLDER.value = ""
  if ( search_path ~= "" ) then
    PHT_PATH_FOLDER.value = search_path
  else
    if ( string.sub( PHT_PATH_FOLDER.value, -1 ) ~= "\\" ) then
      pht_change_status( "Please, reselect before a valid & existent path to export!" )
    end
  end
end



--to export files
function pht_rename_path_directory( value )
  --rectifies the double bar ( \\ ) to path
  if ( string.sub( value, -1 ) ~= "\\" ) then
    value = ("%s\\"):format( value )
  elseif ( string.sub( value, -2 ) == ":\\" ) then
    value = string.gsub( value, "\\", "\\\\", 1 )
  end
  --only accept more than 3 characters to path
  if ( #value <= 3 ) then
    value = ""
  end
  PHT_PATH_FOLDER.value = value
  
  if ( value ~= "" ) then
    vws.PHT_PATH_EXPORT.active = true
  else
    vws.PHT_PATH_EXPORT.active = false
  end
end
---
PHT_PATH_EXP_TYPE = 1
function pht_path_exp_type()
  if ( PHT_PATH_EXP_TYPE == 1 ) then
    PHT_PATH_EXP_TYPE = 2
    vws.PHT_PATH_TYPE.bitmap = "./ico/folder_in_xrni_ico.png"
    pht_change_status( "To export the selected instrument only (xrni)" )
  elseif ( PHT_PATH_EXP_TYPE == 2 ) then
    PHT_PATH_EXP_TYPE = 3
    vws.PHT_PATH_TYPE.bitmap = "./ico/folder_in_xrnz_xrni_ico.png"
    pht_change_status( "To export the phrases & the selected instrument (xrnz + xrni)" )
  else
    PHT_PATH_EXP_TYPE = 1
    vws.PHT_PATH_TYPE.bitmap = "./ico/folder_in_xrnz_ico.png"
    pht_change_status( "To export all the phrases of the selected instrument (xrnz)" )
  end
end
---
function pht_patch_export()
  local ins = song.selected_instrument
  local function save_phrases()
    -------------------------------------------->>   \ / : * ? " < > |   ...prohibited symbols to windows)
    for i = 1, #ins.phrases do
      --local phrase_name = ins:phrase( i ).name:gsub( "%W"," " ):gsub( "  "," " ):gsub( "  "," " ) --only letters & numbers (%W alphanumeric characters)... & after without 2 or 3 spaces
      local phrase_name = ins:phrase( i ).name:gsub( "\\"," " ):gsub( "/"," " ):gsub( ":"," " ):gsub( "*"," " ):gsub( "?"," " ):gsub( "\""," " ):gsub( "<"," " ):gsub( ">"," " ):gsub( "|"," " ):gsub( "    "," " ):gsub( "   "," " ):gsub( "  "," " )
      local filename = ( "%s%s.xrnz" ):format( PHT_PATH_FOLDER.value, phrase_name )
      rna:save_instrument_phrase( filename )
      if ( song.selected_phrase_index + 1 <= #ins.phrases ) then
        song.selected_phrase_index = song.selected_phrase_index + 1
      end
    end
  end
  local function save_instrument()
    local instrument_name = ""
    if ( song.selected_instrument.name ~= "" ) then
      instrument_name = song.selected_instrument.name:gsub( "\\","" ):gsub( "/","" ):gsub( ":","" ):gsub( "*","" ):gsub( "?","" ):gsub( "\"","" ):gsub( "<","" ):gsub( ">","" ):gsub( "|","" ):gsub( "    ","" ):gsub( "   ","" ):gsub( "  ","" )
    else
      if ( #ins.phrases > 0 ) and ins:phrase( 1 ).name ~= "" then
        instrument_name = ins:phrase( 1 ).name:gsub( "\\"," " ):gsub( "/"," " ):gsub( ":"," " ):gsub( "*"," " ):gsub( "?"," " ):gsub( "\""," " ):gsub( "<"," " ):gsub( ">"," " ):gsub( "|"," " ):gsub( "    "," " ):gsub( "   "," " ):gsub( "  "," " ) 
      end
    end
    local filename = ( "%s%s.xrni" ):format( PHT_PATH_FOLDER.value, instrument_name )
    rna:save_instrument( filename )
  end
  if ( io.exists( PHT_PATH_FOLDER.value ) == true ) then
    if ( PHT_PATH_EXP_TYPE == 1 ) then
      save_phrases()
      pht_change_status( "All phrase presets have been exported correctly in the selected folder ("..#ins.phrases.." phrases)." )
    elseif ( PHT_PATH_EXP_TYPE == 2 ) then
      save_instrument()
      pht_change_status( "The selected instrument has been exported correctly in the selected folder." )
    else
      save_phrases()
      save_instrument()
      pht_change_status( "All phrases ("..#ins.phrases..") & the instrument have been exported correctly in the selected folder." )
    end
    local function open_path_folder()
      rna:open_path( PHT_PATH_FOLDER.value )
      PHT_PATH_FOLDER.value = ""
      if ( rnt:has_timer( open_path_folder ) ) then
        rnt:remove_timer( open_path_folder )
      end
    end
    if not ( rnt:has_timer( open_path_folder ) ) then
      rnt:add_timer( open_path_folder, 2000 )
    end
  else
    pht_change_status( "Please, select before a valid & existent path to export!" )
  end 
end
---
PHT_PATH_BROWSE = vb:row { spacing = -3,
  vb:button {
    id = "PHT_PATH_TYPE",
    height = 25,
    width = 33,
    bitmap = "./ico/folder_in_xrnz_ico.png",
    notifier = function() pht_path_exp_type() end,
    tooltip = "Select the file type to save:\n"..
              "   Z = all the phrases of the selected instrument (xrnz)\n"..
              "   I = the selected instrument (xrni *)\n"..
              "   Z+I = phrases of the selected instrument & the selected instrument (xrnz + xrni *)\n"..
              "* If the instrument name is empty then rename it with the first phrase name"
  },
  vb:button {
    height = 25,
    width = 45,
    bitmap = "./ico/folder_in_ico.png",
    notifier = function() pht_patch_brorwse_folder() end,
    tooltip = "Folder to export/save\n"..
              "Select a folder to save all the phrase presets of the selected instrument (xrnz) or the selected instrument (xrni) or all files (xrnz + xrni). After press \"Save\""
  }
}
---
PHT_PATH_FOLDER = vb:textfield {
  height = 25,
  width = 282,
  value = "",
  notifier = function( value ) pht_rename_path_directory( value ) end,
  tooltip = "Path to save the files"
}
---
PHT_PATH_EXPORT = vb:button {
  id = "PHT_PATH_EXPORT",
  active = false,
  height = 25,
  width = 48,
  text = "Save",
  notifier = function() pht_patch_export() end,
  tooltip = "Export/save the files\nExport all the files inside the selected folder"
}
---
PHT_MISCELLANEOUS_2 = vb:row { margin = 1,
  visible = false,
  vb:row { spacing = 6,
    vb:row { style = "panel", margin = 5, spacing = 7,
      PHT_FOLDER,
    },
    vb:row { style = "panel", margin = 5, spacing = 4,
      PHT_PATH_BROWSE,
      PHT_PATH_FOLDER,
      PHT_PATH_EXPORT
    }
  }
}


-------------------------------------------------------------------------------------------------
--miscellaneous 3
-------------------------------------------------------------------------------------------------
--data state
PHT_MSC3_MOD_DATA_STATE = 4
function pht_msc3_change_selector( value )
  for i = 1, 7 do
    if ( value == i ) then
      vws["PHT_MSC3_SEL_"..i].color = PHT_MAIN_COLOR.GOLD_ON
      PHT_MSC3_MOD_DATA_STATE = i
    else
      vws["PHT_MSC3_SEL_"..i].color = PHT_MAIN_COLOR.DEFAULT
    end
    if ( value == 6 ) or ( value == 7 ) then
      vws.PHT_MSC3_INS_DATA.active = false
      vws.PHT_MSC3_VB_NTE_DATA.active = false
      vws.PHT_MSC3_NTE_DATA.active = false
      vws.PHT_MSC3_VPD_DATA.active = false
      vws.PHT_MSC3_VPD_DATA_BT1.active = false
      vws.PHT_MSC3_VPD_DATA_BT2.active = false
      vws.PHT_MSC3_VOL_DATA.active = false
      vws.PHT_MSC3_PAN_DATA.active = false
      vws.PHT_MSC3_DLY_DATA.active = false
    else 
      vws.PHT_MSC3_INS_DATA.active = true
      vws.PHT_MSC3_VB_NTE_DATA.active = true
      vws.PHT_MSC3_NTE_DATA.active = true
      vws.PHT_MSC3_VPD_DATA.active = true
      vws.PHT_MSC3_VPD_DATA_BT1.active = true
      vws.PHT_MSC3_VPD_DATA_BT2.active = true
      vws.PHT_MSC3_VOL_DATA.active = true
      vws.PHT_MSC3_PAN_DATA.active = true
      vws.PHT_MSC3_DLY_DATA.active = true
    end    
  end
  if ( value == 1 ) then
    pht_change_status( "Row selector to clear or change values." )
  elseif ( value == 2 ) then
    pht_change_status( "Note column selector to clear or change values." )
  elseif ( value == 3 ) then
    pht_change_status( "Line selector to clear or change values." )
  elseif ( value == 4 ) then
    pht_change_status( "Pattern-track selector to clear or change values." )
  elseif ( value == 5 ) then
    pht_change_status( "Specific selection selector to clear or change values." )
  elseif ( value == 6 ) then
    pht_change_status( "Track selector to clean values." )
  else
    pht_change_status( "Pattern selector to clean values." )
  end
end



--clear data
function pht_msc3_clear_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index  
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
      --selected row in pattern-track
      if ( song.selected_note_column ~= nil ) then
        song.selected_note_column:clear()
      else
        song.selected_effect_column:clear()
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
      --selected note_column/effect_column in pattern-track
      if ( song.selected_note_column ~= nil ) then
        for l = 1, song.selected_pattern.number_of_lines do
          song.selected_pattern_track:line(l):note_column( snci ):clear()
        end
      else
        for l = 1, song.selected_pattern.number_of_lines do
          song.selected_pattern_track:line(l):effect_column( seci ):clear()
        end
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
      --selected line in pattern-track
      song.selected_line:clear()
    elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
      --selected pattern-track
      song.selected_pattern_track:clear()
    elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
      --the selection  
      if ( song.selection_in_pattern ~= nil ) then
        local iter = song.pattern_iterator
        for pos, line in iter:lines_in_pattern( spi ) do
          for _, column in pairs( line.note_columns ) do --note_column
            if ( column.is_selected ) then
              column:clear()
            end
          end
          for _, column in pairs( line.effect_columns ) do--effect_column
            if ( column.is_selected ) then
              column:clear()
            end
          end
        end
      else
        pht_change_status( "Please, select before an area inside the pattern editor!" )
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 6 ) then
      --selected track
      for p = 1, #song.sequencer.pattern_sequence do
        song:pattern( p ):track( sti ):clear()
      end
    else
      --selected pattern
      song.selected_pattern:clear()
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--instrument data (INS)
function pht_msc3_ins_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index  
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    local sii = song.selected_instrument_index -1
    if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
      --selected row in pattern-track
      if ( song.selected_note_column ~= nil ) then
        song.selected_note_column.instrument_value = sii
      else
        return
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
      --selected note_column in pattern-track
      if ( song.selected_note_column ~= nil ) then
        for l = 1, song.selected_pattern.number_of_lines do
          if ( song.selected_pattern_track:line( l ):note_column( snci ).instrument_value ~= 255 ) then
            song.selected_pattern_track:line( l ):note_column( snci ).instrument_value = sii
          end
        end
      else
        pht_change_status( "Please, select before an note column inside the pattern editor!" )
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
      --selected line in pattern-track
      if ( song.selected_note_column ~= nil ) then
        for c = 1, 12 do
          if ( song.selected_line:note_column( c ).instrument_value ~= 255 ) then
            song.selected_line:note_column( c ).instrument_value = sii
          end
        end
      else
        pht_change_status( "Please, select before an note column inside the pattern editor!" )
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
      --selected pattern-track
      for l = 1, song.selected_pattern.number_of_lines do
        local line = song.selected_pattern_track:line( l )
        if not line.is_empty then
          for c = 1, 12 do
            local column = line:note_column( c )
            if not column.is_empty then
              if ( column.instrument_value ~= 255 ) then
                column.instrument_value = sii
              end
            end
          end
        end
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
      --the selection  
      if ( song.selection_in_pattern ~= nil ) then
        local iter = song.pattern_iterator
        for pos, line in iter:lines_in_pattern( spi ) do
          for _, column in pairs( line.note_columns ) do --note_column
            if ( column.is_selected ) then
              if ( column.instrument_value ~= 255 ) then
                column.instrument_value = sii
              end
            end
          end
        end
      else
        pht_change_status( "Please, select before an area inside the pattern editor!" )
      end
    else
      return
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--note data (NTE)
function pht_msc3_nte_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    local nte = vws.PHT_MSC3_VB_NTE_DATA.value
    if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
      --selected row in pattern-track
      if ( song.selected_note_column ~= nil ) then
        song.selected_note_column.note_value = nte
      else
        return
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
      --selected note_column in pattern-track
      if ( song.selected_note_column ~= nil ) then
        for l = 1, song.selected_pattern.number_of_lines do
          if ( song.selected_pattern_track:line( l ):note_column( snci ).note_value < 120 ) then
            song.selected_pattern_track:line( l ):note_column( snci ).note_value = nte
          end
        end
      else
        pht_change_status( "Please, select before an note column inside the pattern editor!" )
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
      --selected line in pattern-track
      if ( song.selected_note_column ~= nil ) then
        for c = 1, 12 do
          if ( song.selected_line:note_column( c ).note_value < 120 ) then
            song.selected_line:note_column( c ).note_value = nte
          end
        end
      else
        pht_change_status( "Please, select before an note column inside the pattern editor!" )
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
      --selected pattern-track
      for l = 1, song.selected_pattern.number_of_lines do
        local line = song.selected_pattern_track:line( l )
        if not line.is_empty then
          for c = 1, 12 do
            local column = line:note_column( c )
            if not column.is_empty then
              if ( column.note_value < 120 ) then
                column.note_value = nte
              end
            end
          end
        end
      end
    elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
      --the selection  
      if ( song.selection_in_pattern ~= nil ) then
        local iter = song.pattern_iterator
        for pos, line in iter:lines_in_pattern( spi ) do
          for _, column in pairs( line.note_columns ) do --note_column
            if ( column.is_selected ) then
              if ( column.note_value < 120 ) then
                column.note_value = nte
              end
            end
          end
        end
      else
        pht_change_status( "Please, select before an area inside the pattern editor!" )
      end
    else
      return
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



local PHT_MSC3_VPD_DATA_STATE = 1
function pht_msc3_vpd_data_state( value )
  PHT_MSC3_VPD_DATA_STATE = value
  for i = 1, 2 do
    if ( i == value ) then
      vws["PHT_MSC3_VPD_DATA_BT"..i].color = PHT_MAIN_COLOR.GOLD_ON
    else
      vws["PHT_MSC3_VPD_DATA_BT"..i].color = PHT_MAIN_COLOR.DEFAULT
    end
  end
  if ( value == 1 ) then
    pht_change_status( "Note affinity selected." )
  else
    pht_change_status( "Value affinity selected." )
  end
end



--volume data (VOL)
function pht_msc3_vol_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index  
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    ---
    if ( vws.PHT_MSC3_VPD_DATA.value > 129 ) then
      vws.PHT_MSC3_VPD_DATA.value = 129
    end
    ---
    local vol = vws.PHT_MSC3_VPD_DATA.value -1
    ---
    if ( vol == -1 ) then
      vol = 255
    end
    ---
    if PHT_MSC3_VPD_DATA_STATE == 1 then
      --note affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.volume_value = vol
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).note_value < 120 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).volume_value = vol
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).note_value < 120 ) then
              song.selected_line:note_column( c ).volume_value = vol
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.note_value < 120 ) then
                  column.volume_value = vol
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.note_value < 120 ) then
                  column.volume_value = vol
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
      ---
    else
      --volume (value) affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.volume_value = vol
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).volume_value < 130 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).volume_value = vol
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).volume_value < 130 ) then
              song.selected_line:note_column( c ).volume_value = vol
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.volume_value < 130 ) then
                  column.volume_value = vol
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.volume_value < 130 ) then
                  column.volume_value = vol
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--panning data (PAN)
function pht_msc3_pan_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    ---
    if ( vws.PHT_MSC3_VPD_DATA.value > 129 ) then
      vws.PHT_MSC3_VPD_DATA.value = 129
    end
    ---
    local pan = vws.PHT_MSC3_VPD_DATA.value -1
    ---
    if ( pan == -1 ) then
      pan = 255
    end
    ---
    if PHT_MSC3_VPD_DATA_STATE == 1 then
      --note affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.panning_value = pan
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).note_value < 120 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).panning_value = pan
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).note_value < 120 ) then
              song.selected_line:note_column( c ).panning_value = pan
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.note_value < 120 ) then
                  column.panning_value = pan
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.note_value < 120 ) then
                  column.panning_value = pan
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
      ---
    else
      --panning (value) affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.panning_value = pan
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).panning_value < 130 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).panning_value = pan
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).panning_value < 130 ) then
              song.selected_line:note_column( c ).panning_value = pan
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.panning_value < 130 ) then
                  column.panning_value = pan
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.panning_value < 130 ) then
                  column.panning_value = pan
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--delay data (DLY)
function pht_msc3_dly_data()
  if ( song.transport.edit_mode == true ) then
    local sti = song.selected_track_index
    local spi = song.selected_pattern_index  
    local snci = song.selected_note_column_index
    local seci = song.selected_effect_column_index
    ---
    --if ( vws.PHT_MSC3_VPD_DATA.value > 129 ) then
    --  vws.PHT_MSC3_VPD_DATA.value = 129
    --end
    ---
    local dly = vws.PHT_MSC3_VPD_DATA.value -1
    ---
    if ( dly == -1 ) then
      dly = 0
    end
    ---
    if PHT_MSC3_VPD_DATA_STATE == 1 then
      --note affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.panning_value = pan
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).note_value < 120 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).delay_value = dly
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).note_value < 120 ) then
              song.selected_line:note_column( c ).delay_value = dly
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.note_value < 120 ) then
                  column.delay_value = dly
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.note_value < 120 ) then
                  column.delay_value = dly
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
      ---
    else
      --delay (value) affinity
      if ( PHT_MSC3_MOD_DATA_STATE == 1 ) then
        --selected row in pattern-track
        if ( song.selected_note_column ~= nil ) then
          song.selected_note_column.delay_value = dly
        else
          return
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 2 ) then
        --selected note_column in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for l = 1, song.selected_pattern.number_of_lines do
            if ( song.selected_pattern_track:line( l ):note_column( snci ).delay_value < 256 ) and ( song.selected_pattern_track:line( l ):note_column( snci ).delay_value > 0 ) then
              song.selected_pattern_track:line( l ):note_column( snci ).delay_value = dly
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 3 ) then
        --selected line in pattern-track
        if ( song.selected_note_column ~= nil ) then
          for c = 1, 12 do
            if ( song.selected_line:note_column( c ).delay_value < 256 ) and ( song.selected_line:note_column( c ).delay_value > 0 ) then
              song.selected_line:note_column( c ).delay_value = dly
            end
          end
        else
          pht_change_status( "Please, select before an note column inside the pattern editor!" )
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 4 ) then
        --selected pattern-track
        for l = 1, song.selected_pattern.number_of_lines do
          local line = song.selected_pattern_track:line( l )
          if not line.is_empty then
            for c = 1, 12 do
              local column = line:note_column( c )
              if not column.is_empty then
                if ( column.delay_value < 256 ) and ( column.delay_value > 0 ) then
                  column.delay_value = dly
                end
              end
            end
          end
        end
      elseif ( PHT_MSC3_MOD_DATA_STATE == 5 ) then
        --the selection  
        if ( song.selection_in_pattern ~= nil ) then
          local iter = song.pattern_iterator
          for pos, line in iter:lines_in_pattern( spi ) do
            for _, column in pairs( line.note_columns ) do --note_column
              if ( column.is_selected ) then
                if ( column.delay_value < 256 ) and ( column.delay_value > 0 ) then
                  column.delay_value = dly
                end
              end
            end
          end
        else
          pht_change_status( "Please, select before an area inside the pattern editor!" )
        end
      else
        return
      end
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end  
end



PHT_MSC3_MOD_DATA = vb:row {
  vb:row { spacing = -3,
    vb:button {
      id = "PHT_MSC3_SEL_1",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_row_ico.png",
      notifier = function() pht_msc3_change_selector( 1 ) end,
      tooltip = "Row selector in pattern-track"
    },
    vb:button {
      id = "PHT_MSC3_SEL_2",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_note_column_ico.png",
      notifier = function() pht_msc3_change_selector( 2 ) end,
      tooltip = "Note column selector in pattern-track"
    },
    vb:button {
      id = "PHT_MSC3_SEL_3",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_line_ico.png",
      notifier = function() pht_msc3_change_selector( 3 ) end,
      tooltip = "Line selector in pattern-track"
    },
    vb:button {
      id = "PHT_MSC3_SEL_4",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_pattern_track_ico.png",
      color = PHT_MAIN_COLOR.GOLD_ON,
      notifier = function() pht_msc3_change_selector( 4 ) end,
      tooltip = "Pattern-track selector"
    },
    vb:button {
      id = "PHT_MSC3_SEL_5",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_selection_ico.png",
      notifier = function() pht_msc3_change_selector( 5 ) end,
      tooltip = "The specific selection selector"
    },
    vb:button {
      id = "PHT_MSC3_SEL_6",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_track_ico.png",
      notifier = function() pht_msc3_change_selector( 6 ) end,
      tooltip = "Track selector"
    },
    vb:button {
      id = "PHT_MSC3_SEL_7",
      height = 25,
      width = 31,
      bitmap = "./ico/clear_pattern_ico.png",
      notifier = function() pht_msc3_change_selector( 7 ) end,
      tooltip = "Pattern selector"
    }
  },
  vb:space { width = 5 },
  vb:row {
    vb:button {
      id = "PHT_MSC3_CLEAR_DATA",
      height = 25,
      width = 36,
      color = PHT_MAIN_COLOR.RED_OFF,
      bitmap = "./ico/clear_data_ico.png",
      notifier = function() pht_msc3_clear_data() end,
      tooltip = "Clear data\nFirst use a selection to clean data. This operation ignores the hidden note columns (line, pattern-track, track, pattern), except the specific selection\n[Del]"
    }
  }
}



function pht_msc3_tostring_vpd( number )
  if ( number == 0 ) then
    return "--"
  else
    return ( "%.02X" ):format( number - 1 )
  end
end
---
function pht_msc3_tonumber_vpd( string )
  if ( string == "--" ) or ( string == "-" ) then
    return 0
  else
    return tonumber( string, 16 ) + 1
  end
end



PHT_MSC3_NVPD_DATA = vb:row {
  vb:row { spacing = -3,
    vb:button {
      id = "PHT_MSC3_INS_DATA",
      height = 25,
      width = 37,
      text = "INS",
      notifier = function() pht_msc3_ins_data() end,
      tooltip = "Change the instrument values\nTo choose a value, first select a instrument inside the instrument box to change\n[ Range: 00 to FE ]"
    },
    vb:space { width = 5 },
    vb:valuebox {
      id = "PHT_MSC3_VB_NTE_DATA",
      height = 25,
      width = 55,
      min = 0,
      max = 119,
      value = 36,
      tostring = function( number ) return pht_note_tostring ( number ) end,
      tonumber = function( string ) return pht_note_tonumber ( string ) end,
      tooltip = "Note selector\n[ Range: C-0 to B-9 ]"
    },
    vb:button {
      id = "PHT_MSC3_NTE_DATA",
      height = 25,
      width = 37,
      text = "NTE",
      notifier = function() pht_msc3_nte_data() end,
      tooltip = "Change the note values\n[ Range: C-0 to B-9 ]"
    },
    vb:space { width = 5 },
    vb:valuebox {
      id = "PHT_MSC3_VPD_DATA",
      height = 25,
      width = 49,
      min = 0,
      max = 256,
      value = 0,
      tostring = function( number ) return pht_msc3_tostring_vpd( number ) end,
      tonumber = function( string ) return pht_msc3_tonumber_vpd( string ) end,
      tooltip = "Hexadecimal value selector\nValid ranges:\n"..
      "  For volume: --, 00 to 80 *\n"..
      "  For panning: --, 00 to 80 *\n"..
      "  For delay: -- to FF\n"..
      "* If the value is too high, it will take the maximum valid value!"
    },
    vb:column { spacing = -3,
      vb:button {
        id = "PHT_MSC3_VPD_DATA_BT1",
        height = 14,
        width = 21,
        bitmap = "./ico/affinity_note_ico.png",
        color = PHT_MAIN_COLOR.GOLD_ON,
        notifier = function() pht_msc3_vpd_data_state( 1 ) end,
        tooltip = "Note affinity"
      },
      vb:button {
        id = "PHT_MSC3_VPD_DATA_BT2",
        height = 14,
        width = 21,
        bitmap = "./ico/affinity_value_ico.png",
        notifier = function() pht_msc3_vpd_data_state( 2 ) end,
        tooltip = "Value affinity"
      }
    },
    vb:button {
      id = "PHT_MSC3_VOL_DATA",
      height = 25,
      width = 37,
      text = "VOL",
      notifier = function() pht_msc3_vol_data() end,
      tooltip = "Change the volume values\n[ Range: --, 00 to 80 ]"
    },
    vb:button {
      id = "PHT_MSC3_PAN_DATA",
      height = 25,
      width = 37,
      text = "PAN",
      notifier = function() pht_msc3_pan_data() end,
      tooltip = "Change the panning values\n[ Range: --, 00 to 80 ]"
    },
    vb:button {
      id = "PHT_MSC3_DLY_DATA",
      height = 25,
      width = 37,
      text = "DLY",
      notifier = function() pht_msc3_dly_data() end,
      tooltip = "Change the delay values\n[ Range: -- to FF ]"
    }
  }
}



--tostring/tonumber of valueboxes for note columns
function pht_msc3_tostring_nte( number )
  if ( number <= 119 ) then
    return pht_note_tostring( number )
  elseif ( number == 120 ) then
    return "OFF"
  else  
    return "---"
  end
end
---
function pht_msc3_tonumber_nte( string )
  if ( string == "o" ) or ( string == "O" ) or ( string == "of" ) or ( string == "OF" ) or ( string == "off" ) or ( string == "OFF" ) then
    return 120
  elseif ( string == "-" ) or ( string == "--" ) or ( string == "---" ) then
    return 121
  else
    return pht_note_tonumber( string )
  end
end
---



function pht_msc3_tostring_ins( number )
  if ( number == 0 ) then
    return "SE"
  elseif ( number == 256 ) then
    return "--"
  else
    return ( "%.02X" ):format( number - 1 )
  end
end
---
function pht_msc3_tonumber_ins( string )
  if ( string == "s" ) or ( string == "S" ) or ( string == "se" ) or ( string == "SE" ) then
    return 0
  elseif ( string == "-" ) or ( string == "--" ) then
    return 256
  else
    return tonumber( string, 16 ) + 1
  end
end
---


function pht_msc3_tostring_dly( number )
  if ( number == 0 ) then
    return "--"
  else
    return ( "%.02X" ):format( number )
  end
end
---
function pht_msc3_tonumber_dly( string )
  if ( string == "--" ) or ( string == "-" ) then
    return 0
  else
    return tonumber( string, 16 )-- + 1
  end
end



--tostring/tonumber of valueboxes for effect columns
local PHT_MSC3_EN_SFX_VAL = { "--", "G", "U", "D", "A", "V", "N", "I", "O", "C", "M", "T", "S", "Q", "R", "Y", "B", "E", "Z" } --19
local PHT_MSC3_EN_SFX_VAL_ = { "-", "g", "u", "d", "a", "v", "n", "i", "o", "c", "m", "t", "s", "q", "r", "y", "b", "e", "z" } --19
---
function pht_msc3_tostring_sfx_val( number )
  if ( number <= 19 ) then
    return PHT_MSC3_EN_SFX_VAL[ number ]
  else
    return ("%.02X"):format ( number - 19 )
  end
end
---
function pht_msc3_tonumber_sfx_val( string )
  for i = 1, 19 do
    if ( string == PHT_MSC3_EN_SFX_VAL[ i ] ) or ( string == PHT_MSC3_EN_SFX_VAL_[ i ] ) then
      return i
    end
  end
  for i = 20, 274 do
    if ( string == ( "%.X" ):format( i - 19 ) ) or ( string == ( "%.02X" ):format( i - 19 ) ) then
      return i
    end
  end
end
---
function pht_msc3_tostring_sfx_amo( number )
  if ( number == 0 ) then
    return "--"
  else
    return ( "%.02X" ):format( number - 1)
  end
end
---
function pht_msc3_tonumber_sfx_amo( string )
  if ( string == "--" ) or ( string == "-" ) then
    return 0
  else
    return tonumber( string, 16 ) + 1
  end
end



local PHT_MSC3_EN_TFX_VAL = { "--", "G", "U", "D", "A", "V", "N", "I", "O", "C", "M", "T", "S", "Q", "R", "Y", "B", "E", "Z", "L", "P", "W", "J", "X", "ZT", "ZL", "ZK", "ZG", "ZD", "ZB" } --30
local PHT_MSC3_EN_TFX_VAL_ = { "-", "g", "u", "d", "a", "v", "n", "i", "o", "c", "m", "t", "s", "q", "r", "y", "b", "e", "z", "l", "p", "w", "j", "x", "zt", "zl", "zk", "zg", "zd", "zb" } --30
---
function pht_msc3_tostring_tfx_val( number )
  if ( number <= 30 ) then
    return PHT_MSC3_EN_TFX_VAL[ number ]
  else
    return ("%.02X"):format ( number - 30 )
  end
end
---
function pht_msc3_tonumber_tfx_val( string )
  for i = 1, 30 do
    if ( string == PHT_MSC3_EN_TFX_VAL[ i ] ) or ( string == PHT_MSC3_EN_TFX_VAL_[ i ] ) then
      return i
    end
  end
  for i = 30, 285 do
    if ( string == ( "%.X" ):format( i - 30 ) ) or ( string == ( "%.02X" ):format( i - 30 ) ) then
      return i
    end
  end
end
---
function pht_msc3_tostring_tfx_amo( number )
  if ( number == 0 ) then
    return "--"
  else
    return ( "%.02X" ):format( number - 1)
  end
end
---
function pht_msc3_tonumber_tfx_amo( string )
  if ( string == "--" ) or ( string == "-" ) then
    return 0
  else
    return tonumber( string, 16 ) + 1
  end
end


--import row
function pht_msc3_import_row()
  if ( song.selected_note_column ~= nil ) then
    pht_msc3_edit_notes_state( true )
    local ssnc = song.selected_note_column
    --note
    vws.PHT_MSC3_EDIT_NOTES_NTE.value = ssnc.note_value
    --ins
    vws.PHT_MSC3_EDIT_NOTES_INS.value = ssnc.instrument_value + 1
    --vol
    if ( ssnc.volume_value + 1 >= 256 ) then
      vws.PHT_MSC3_EDIT_NOTES_VOL.value = 0
    else
      vws.PHT_MSC3_EDIT_NOTES_VOL.value = ssnc.volume_value + 1
    end
    --pan
    if ( ssnc.panning_value + 1 >= 256 ) then
      vws.PHT_MSC3_EDIT_NOTES_PAN.value = 0
    else
      vws.PHT_MSC3_EDIT_NOTES_PAN.value = ssnc.panning_value + 1
    end
    --dly
    vws.PHT_MSC3_EDIT_NOTES_DLY.value = ssnc.delay_value
    --sfx amo
    vws.PHT_MSC3_EDIT_NOTES_SFX_AMO.value = ssnc.effect_amount_value + 1    
    --sfx val
    for i = 1, 274 do
      if ( i <= 19 ) then
        if ( ("0%s"):format( PHT_MSC3_EN_SFX_VAL[i] ) == ssnc.effect_number_string ) then
          vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value = i
          return
        else
          vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value = 1
        end
      else
        if ( ("%.02X"):format( i - 19 ) == ssnc.effect_number_string ) then
          vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value = i
          return
        end
      end
    end
  else
    pht_msc3_edit_notes_state( false )
    local ssec = song.selected_effect_column
    --tfx amo
    vws.PHT_MSC3_EDIT_NOTES_TFX_AMO.value = ssec.amount_value + 1
    --print(ssec.amount_value + 1)
    --tfx val
    for i = 1, 285 do
      if ( i <= 30 ) then
        if ( ("0%s"):format( PHT_MSC3_EN_TFX_VAL[i] ) == ssec.number_string ) or ( ("%s"):format( PHT_MSC3_EN_TFX_VAL[i] ) == ssec.number_string ) then
          vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value = i
          return
        else
          vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value = 1
        end
      else
        if ( ("%.02X"):format( i - 30 ) == ssec.number_string ) then
          vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value = i
          return
        end
      end
    end
  end
end



--insert row
function pht_msc3_insert_row()
  if ( song.transport.edit_mode == true ) then
    if ( song.selected_note_column ~= nil ) then
      pht_msc3_edit_notes_state( true )
      local ssnc = song.selected_note_column
      --note
      ssnc.note_value = vws.PHT_MSC3_EDIT_NOTES_NTE.value
      --ins
      if ( vws.PHT_MSC3_EDIT_NOTES_INS.value ~= 0 ) then
        ssnc.instrument_value = vws.PHT_MSC3_EDIT_NOTES_INS.value -1
      else
        ssnc.instrument_value = song.selected_instrument_index -1
      end
      --vol
      if ( vws.PHT_MSC3_EDIT_NOTES_VOL.value ~= 0 ) then
        ssnc.volume_value = vws.PHT_MSC3_EDIT_NOTES_VOL.value -1
      else
        ssnc.volume_value = 255
      end
      --pan
      if ( vws.PHT_MSC3_EDIT_NOTES_PAN.value ~= 0 ) then
        ssnc.panning_value = vws.PHT_MSC3_EDIT_NOTES_PAN.value -1
      else
        ssnc.panning_value = 255
      end
      --dly
      if ( song.transport.follow_player == false ) and ( song.transport.playing == true ) or ( song.transport.playing == false ) then
        if ( vws.PHT_MSC3_EDIT_NOTES_DLY.value >= 1 ) then
          ssnc.delay_value = vws.PHT_MSC3_EDIT_NOTES_DLY.value
        else
          ssnc.delay_value = 0
        end
      end
      --sfx val
      if ( vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value > 1 ) and ( vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value < 20 ) then
        ssnc.effect_number_string = ( "0%s" ):format( pht_msc3_tostring_sfx_val( vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value ) )
      elseif ( vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value == 1 ) then
        ssnc.effect_number_string = ".."
      else
        ssnc.effect_number_string = ("%.2X"):format( vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.value - 19 )
      end
      --sfx amo
      if ( vws.PHT_MSC3_EDIT_NOTES_SFX_AMO.value ~= 0 ) then
        ssnc.effect_amount_value = vws.PHT_MSC3_EDIT_NOTES_SFX_AMO.value - 1
      else
        ssnc.effect_amount_value = 0
      end

    else
      pht_msc3_edit_notes_state( false )
      local ssec = song.selected_effect_column
      --tfx val
      if ( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value > 1 ) and ( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value <= 24 ) then
        ssec.number_string = ( "0%s" ):format( pht_msc3_tostring_tfx_val( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value ) )
      elseif ( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value == 1 ) then
        ssec.number_string = ".."      
      elseif ( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value <= 30 ) then
        ssec.number_string = ( "%s" ):format( pht_msc3_tostring_tfx_val( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value ) )
      else
        ssec.number_string = ("%.2X"):format( vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.value - 30 )
      end
      --tfx amo
      if ( vws.PHT_MSC3_EDIT_NOTES_TFX_AMO.value ~= 0 ) then
        ssec.amount_value = vws.PHT_MSC3_EDIT_NOTES_TFX_AMO.value - 1
      else
        ssec.amount_value = 0
      end
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end
---
function pht_msc3_insert_row_pres()
  pht_msc3_insert_row()
  if ( song.selected_note_column ~= nil ) then
    local ins = vws.PHT_MSC3_EDIT_NOTES_INS.value
    local trk = song.selected_track_index 
    local nte = vws.PHT_MSC3_EDIT_NOTES_NTE.value
    local vel = vws.PHT_MSC3_EDIT_NOTES_VOL.value - 1
    pht_osc_client:trigger_instrument( true, ins, trk, nte, vel )
  end
end
---
function pht_msc3_insert_row_rel()
  if ( song.selected_note_column ~= nil ) then
    local ins = vws.PHT_MSC3_EDIT_NOTES_INS.value
    local trk = song.selected_track_index 
    local nte = vws.PHT_MSC3_EDIT_NOTES_NTE.value
    pht_osc_client:trigger_instrument( false, ins, trk, nte )
  end
end
---
local PHT_MSC3_EDIT_NOTES_STATE = false
function pht_msc3_edit_notes_state( value )
  if ( value == false ) then
    PHT_MSC3_EDIT_NOTES_STATE = true
    vws.PHT_MSC3_EDIT_NOTES_BT2.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_MSC3_EDIT_NOTES_BT1.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_MSC3_EDIT_NOTES_NTE.active = false
    vws.PHT_MSC3_EDIT_NOTES_INS.active = false
    vws.PHT_MSC3_EDIT_NOTES_VOL.active = false
    vws.PHT_MSC3_EDIT_NOTES_PAN.active = false
    vws.PHT_MSC3_EDIT_NOTES_DLY.active = false
    ---
    vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.visible = false
    vws.PHT_MSC3_EDIT_NOTES_SFX_AMO.visible = false
    vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.visible = true
    vws.PHT_MSC3_EDIT_NOTES_TFX_AMO.visible = true
  else
    PHT_MSC3_EDIT_NOTES_STATE = false
    vws.PHT_MSC3_EDIT_NOTES_BT1.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_MSC3_EDIT_NOTES_BT2.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_MSC3_EDIT_NOTES_NTE.active = true
    vws.PHT_MSC3_EDIT_NOTES_INS.active = true
    vws.PHT_MSC3_EDIT_NOTES_VOL.active = true
    vws.PHT_MSC3_EDIT_NOTES_PAN.active = true
    vws.PHT_MSC3_EDIT_NOTES_DLY.active = true
    ---
    vws.PHT_MSC3_EDIT_NOTES_TFX_VAL.visible = false
    vws.PHT_MSC3_EDIT_NOTES_TFX_AMO.visible = false
    vws.PHT_MSC3_EDIT_NOTES_SFX_VAL.visible = true
    vws.PHT_MSC3_EDIT_NOTES_SFX_AMO.visible = true
  end
end
---
PHT_MSC3_GUI_SFX_VB_TOOLTIP =
  "--     - No value\n"..
  "\n"..
  "*** SAMPLE EFFECTS ***\n"..
  "Gxx - Glide towards given note by xx 1/16ths of a semitone (10 = whole semitone).\n"..
  "Uxx - Slide pitch up by xx 1/16ths of a semitone (01 = 1/16th of a semitone...).\n"..
  "Dxx - Slide pitch down by xx 1/16ths of a semitone (08 = half a semitone...).\n"..
  "Axy - Set arpeggio, x/y = first/second note offset in semitones.\n"..  
  "Vxy - Set vibrato (regular pitch variation), x = speed, y = depth.\n"..
  "Nxy - Set auto pan (regular pan variation), x = speed, y = depth.\n"..
  "\n"..
  "Ixx  - Fade volume in by xx volume units (I01 inserted 256 times...).\n"..
  "Oxx - Fade volume out by xx volume units.\n"..
  "Cxy - Cut volume to x after y ticks (x = volume factor: 0=0%, F=100%).\n"..
  "Mxx - Set channel volume level, 00 = -60dB, FF = +3dB.\n"..  
  "Txy  - Set tremolo (regular volume variation), x = speed, y = depth.\n"..  
  "\n"..  
  "Sxx - Trigger sample slice number xx or offset xx.\n"..  
  "Qxx - Delay playback of the line by xx ticks (00 - TPL).\n"..
  "Rxy - Retrigger instruments that are currently playing...\n"..
  "Yxx - MaYbe trigger the line with probability xx. 00 = mutually exclusive mode...\n"..
  "Bxx - Play sample backwards (xx = 00) or forwards (xx = 01).\n"..
  "Exx - Set position all active Envelope, AHDSR & Fader Mod. devices to offset xx.\n"..
  "\n"..
  "Zxx - Trigger phrase number xx (01 - 7E, 00 = no phrase, 7F = keymap mode).\n"..
  "[ Range: 01 to FF ]"
---
PHT_MSC3_GUI_TFX_VB_TOOLTIP =
  "--     - No value\n"..
  "\n"..
  "*** SAMPLE EFFECTS ***\n"..
  "Gxx - Glide towards given note by xx 1/16ths of a semitone (10 = whole semitone).\n"..
  "Uxx - Slide pitch up by xx 1/16ths of a semitone (01 = 1/16th of a semitone...).\n"..
  "Dxx - Slide pitch down by xx 1/16ths of a semitone (08 = half a semitone...).\n"..
  "Axy - Set arpeggio, x/y = first/second note offset in semitones.\n"..  
  "Vxy - Set vibrato (regular pitch variation), x = speed, y = depth.\n"..
  "Nxy - Set auto pan (regular pan variation), x = speed, y = depth.\n"..
  "\n"..
  "Ixx  - Fade volume in by xx volume units (I01 inserted 256 times...).\n"..
  "Oxx - Fade volume out by xx volume units.\n"..
  "Cxy - Cut volume to x after y ticks (x = volume factor: 0=0%, F=100%).\n"..
  "Mxx - Set channel volume level, 00 = -60dB, FF = +3dB.\n"..  
  "Txy  - Set tremolo (regular volume variation), x = speed, y = depth.\n"..  
  "\n"..  
  "Sxx - Trigger sample slice number xx or offset xx.\n"..  
  "Qxx - Delay playback of the line by xx ticks (00 - TPL).\n"..
  "Rxy - Retrigger instruments that are currently playing...\n"..
  "Yxx - MaYbe trigger the line with probability xx. 00 = mutually exclusive mode...\n"..
  "Bxx - Play sample backwards (xx = 00) or forwards (xx = 01).\n"..
  "Exx - Set position all active Envelope, AHDSR & Fader Mod. devices to offset xx.\n"..
  "\n"..
  "Zxx - Trigger phrase number xx (01 - 7E, 00 = no phrase, 7F = keymap mode).\n"..
  "\n"..
  "*** TRACK EFFECT DEVICES ***\n"..
  "Lxx - Set track pre-mixer's volume level, 00 = -INF, FF = +3dB.\n"..
  "\n"..
  "Pxx - Set track pre-mixer's panning, 00 = full left, 80 = center, FF = full right.\n"..
  "Wxx - Set track pre-mixer's surround width, 00 = off, FF = max.\n"..
  "\n"..
  "Jxx   - Set track's output routing to channel xx...\n"..
  "Xxx  - Stop all notes & FX (-X00), or a specific effect (-Xxx, where xx > 00).\n"..
  "\n"..
  "*** GLOBAL EFFECTS ***\n"..
  "ZTxx - Set tempo (BPM) (20 - FF, 00 = stop song).\n"..
  "ZLxx - Set Lines Per Beat (LPB) (01 - FF, 00 = stop song).\n"..
  "ZKxx - Set Ticks Per Line (TPL) (01 - 10).\n"..
  "ZGxx - Toggle song Groove on/off (00 = turn off, 01 or higher = turn on).\n"..
  "ZDxx - Delay (pause) pattern playback by xx lines.\n"..
  "ZBxx - Break pattern, that finishes immediately & jumps to next ptt. at line xx.\n"..
  "[ Range: 01 to FF ]"
---
PHT_MSC3_EDIT_NOTES = vb:row { spacing = -3,
  vb:column { spacing = -3,
    vb:button {
      id = "PHT_MSC3_EDIT_NOTES_BT1",
      height = 14,
      width = 27,
      bitmap = "./ico/nte_ico.png",
      color = PHT_MAIN_COLOR.GOLD_ON,
      notifier = function() pht_msc3_edit_notes_state( true ) end,
      tooltip = "Panel editor for note columns"
    },
    vb:button {
      id = "PHT_MSC3_EDIT_NOTES_BT2",
      height = 14,
      width = 27,
      bitmap = "./ico/fx_ico.png",
      notifier = function() pht_msc3_edit_notes_state( false ) end,
      tooltip = "Panel editor for effect columns"
    }
  },
  vb:space { width = 8 },
  vb:button {
    height = 25,
    width = 31,
    bitmap = "./ico/in_row_ico.png",
    notifier = function() pht_msc3_import_row() end,
    tooltip = "In Row\nImport the entire row inside selected note column/effect column\n[Apps]"
  },  
  vb:row { margin = 1,
    vb:row { style = "panel", margin = 2, spacing = -3,
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_NTE",
        height = 19,
        width = 55,
        min = 0,
        max = 121,
        value = 48,
        tostring = function( number ) return pht_msc3_tostring_nte ( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_nte ( string ) end,
        tooltip = "Note value selector\n[ Range: C-0 to B-9, OFF & --- ]"
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_INS",
        height = 19,
        width = 49,
        min = 0,
        max = 256, -- 0 until 255, 256 = empty
        value = 1,
        tostring = function( number ) return pht_msc3_tostring_ins( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_ins( string ) end,
        tooltip = "Instrument value selector\n[ Range: 00 to FE. \"SE\" = select in instrument box ]"
      },
      vb:space { width = 7 },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_VOL",
        height = 19,
        width = 49,
        min = 0,
        max = 128,
        value = 128,
        tostring = function( number ) return pht_msc3_tostring_vpd( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_vpd( string ) end,
        tooltip = "Volume value selector\n[ Range: --, 00 to 7F ]"
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_PAN",
        height = 19,
        width = 49,
        min = 0,
        max = 128,
        value = 0,
        tostring = function( number ) return pht_msc3_tostring_vpd( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_vpd( string ) end,
        tooltip = "Panning value selector\n[ Range: --, 00 to 7F. 40 = center ]"
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_DLY",
        height = 19,
        width = 49,
        min = 0,
        max = 255,
        value = 0,
        tostring = function( number ) return pht_msc3_tostring_dly( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_dly( string ) end,
        tooltip = "Delay value selector\n[ Range: --, 01 to FF ]"
      },
      vb:space { width = 7 },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_SFX_VAL",
        height = 19,
        width = 49,
        min = 1,
        max = 274,
        value = 1,
        tostring = function( number ) return pht_msc3_tostring_sfx_val( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_sfx_val( string ) end,
        tooltip = "Sample effect value selector\n"..PHT_MSC3_GUI_SFX_VB_TOOLTIP
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_SFX_AMO",
        height = 19,
        width = 49,
        min = 0,
        max = 256,
        value = 0,
        tostring = function( number ) return pht_msc3_tostring_sfx_amo( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_sfx_amo( string ) end,
        tooltip = "Sample effect amount selector\n[ Range: --, 00 to FF ]"
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_TFX_VAL",
        visible = false,
        height = 19,
        width = 49,
        min = 1,
        max = 285,
        value = 1,
        tostring = function( number ) return pht_msc3_tostring_tfx_val( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_tfx_val( string ) end,
        tooltip = "Track effect value selector\n"..PHT_MSC3_GUI_TFX_VB_TOOLTIP
      },
      vb:valuebox {
        id = "PHT_MSC3_EDIT_NOTES_TFX_AMO",
        visible = false,
        height = 19,
        width = 49,
        min = 0,
        max = 256,
        value = 0,
        tostring = function( number ) return pht_msc3_tostring_tfx_amo( number ) end,
        tonumber = function( string ) return pht_msc3_tonumber_tfx_amo( string ) end,
        tooltip = "Track effect value selector\n[ Range: --, 00 to FF ]"
      }
    }
  },
  vb:button {
    height = 25,
    width = 31,
    bitmap = "./ico/out_row_ico.png",
    pressed = function() pht_msc3_insert_row_pres() end,
    released = function() pht_msc3_insert_row_rel() end,
    tooltip = "Out Row\nInsert the entire row inside selected note column/effect column\n[R.Ctrl]"
  }
}


--move/swap row checkbox
local pht_msc3_swap_row_nc = true
function pht_msc3_swap_row_note_column()
  if ( pht_msc3_swap_row_nc == true ) then
    vws.PHT_MSC3_SWAP_ROW_NC.bitmap = "./ico/move_note_ico.png"
    vws.PHT_MSC3_SWAP_ROW_NC.color = PHT_MAIN_COLOR.DEFAULT
    pht_msc3_swap_row_nc = false
  else
    vws.PHT_MSC3_SWAP_ROW_NC.bitmap = "./ico/swap_note_ico.png"
    vws.PHT_MSC3_SWAP_ROW_NC.color = PHT_MAIN_COLOR.GOLD_ON
    pht_msc3_swap_row_nc = true
  end
end



--move/swap row left
function pht_msc3_move_note_l_repeat( release )
  if not release then
    if rnt:has_timer( pht_msc3_move_note_l_repeat ) then
      pht_msc3_move_note_l()
      rnt:remove_timer( pht_msc3_move_note_l_repeat )
      rnt:add_timer( pht_msc3_move_note_l, 80 )
    else
      pht_msc3_move_note_l()
      rnt:add_timer( pht_msc3_move_note_l_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_msc3_move_note_l_repeat ) then
      rnt:remove_timer( pht_msc3_move_note_l_repeat )
    elseif rnt:has_timer( pht_msc3_move_note_l ) then
      rnt:remove_timer( pht_msc3_move_note_l )
    end
  end
end
---
function pht_msc3_move_note_l()
  if ( song.transport.edit_mode == true ) then
    local snci = song.selected_note_column_index
    local clm = snci - 1
    if ( clm >= 1 ) and ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        if ( pht_msc3_swap_row_nc == true ) then
          local pos_1 = song.selected_note_column
          local pos_2 = song.selected_line:note_column( clm )
          local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
          for i, val in ipairs( id ) do
            pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
          end
        else
          song.selected_line:note_column( clm ):copy_from( song.selected_note_column )
          song.selected_note_column:clear()
        end
        song.selected_note_column_index = clm    
      else
        pht_change_status( "No data to move/swap!" )
      end
    else
      pht_change_status( "Select a valid note column (> 1) to move/swap data!" )
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--move/swap row right
function pht_msc3_move_note_r_repeat( release )
  if not release then
    if rnt:has_timer( pht_msc3_move_note_r_repeat ) then
      pht_msc3_move_note_r()
      rnt:remove_timer( pht_msc3_move_note_r_repeat )
      rnt:add_timer( pht_msc3_move_note_r, 80 )
    else
      pht_msc3_move_note_r()
      rnt:add_timer( pht_msc3_move_note_r_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_msc3_move_note_r_repeat ) then
      rnt:remove_timer( pht_msc3_move_note_r_repeat )
    elseif rnt:has_timer( pht_msc3_move_note_r ) then
      rnt:remove_timer( pht_msc3_move_note_r )
    end
  end
end
---
function pht_msc3_move_note_r()
  if ( song.transport.edit_mode == true ) then
    local snci = song.selected_note_column_index
    local clm = snci + 1
    if ( clm <= 12 ) and ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        if ( song.selected_track.visible_note_columns < clm ) then
          song.selected_track.visible_note_columns = clm
        end
        if ( pht_msc3_swap_row_nc == true ) then
          local pos_1 = song.selected_note_column
          local pos_2 = song.selected_line:note_column( clm )
          local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
          for i, val in ipairs( id ) do
            pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
          end
        else
          song.selected_line:note_column( clm ):copy_from( song.selected_note_column )
          song.selected_note_column:clear()
        end
        song.selected_note_column_index = clm
      else
        pht_change_status( "No data to move/swap!" )
      end
    else
      pht_change_status( "Select a valid note column (< 12) to move/swap data!" )
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--move/swap row up
function pht_msc3_move_note_u_repeat( release )
  if not release then
    if rnt:has_timer( pht_msc3_move_note_u_repeat ) then
      pht_msc3_move_note_u()
      rnt:remove_timer( pht_msc3_move_note_u_repeat )
      rnt:add_timer( pht_msc3_move_note_u, 50 )
    else
      pht_msc3_move_note_u()
      rnt:add_timer( pht_msc3_move_note_u_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_msc3_move_note_u_repeat ) then
      rnt:remove_timer( pht_msc3_move_note_u_repeat )
    elseif rnt:has_timer( pht_msc3_move_note_u ) then
      rnt:remove_timer( pht_msc3_move_note_u )
    end
  end
end
---
function pht_msc3_move_note_u()
  if ( song.transport.edit_mode == true ) then
    local sli = song.selected_line_index
    local lne = sli - 1
    if ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        local snci = song.selected_note_column_index
        local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
        if ( lne >= 1 ) then
          if ( pht_msc3_swap_row_nc == true ) then
            local pos_1 = song.selected_pattern_track:line( lne ):note_column( snci )
            local pos_2 = song.selected_pattern_track:line( sli ):note_column( snci )
            for i, val in ipairs( id ) do
              pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
            end
          else
            song.selected_pattern_track:line( lne ):note_column( song.selected_note_column_index ):copy_from( song.selected_note_column )
            song.selected_note_column:clear()
          end
          song.selected_line_index = lne
        else
          local s_ssi = song.selected_sequence_index - 1
          if ( s_ssi >= 1 ) then
            local sti = song.selected_track_index
            local s_nol = song:pattern( s_ssi ).number_of_lines
            if ( pht_msc3_swap_row_nc == true ) then
              local pos_1 = song:pattern( s_ssi ):track( sti ):line( s_nol ):note_column( snci )
              local pos_2 = song.selected_pattern_track:line( sli ):note_column( snci )
              for i, val in ipairs( id ) do
                pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
              end
            else
              song:pattern( s_ssi ):track( sti ):line( s_nol ):note_column( snci ):copy_from( song.selected_note_column )
              song.selected_note_column:clear()
            end
            song.selected_sequence_index = s_ssi
            song.selected_line_index = song.selected_pattern.number_of_lines
          else
            pht_change_status( "Select a valid line (> 1) to move/swap data!" )
          end
        end
      else
        pht_change_status( "No data to move/swap!" )
      end
    else
      pht_change_status( "Select a valid note column to move/swap data!" )
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end



--move/swap row down
function pht_msc3_move_note_d_repeat( release )
  if not release then
    if rnt:has_timer( pht_msc3_move_note_d_repeat ) then
      pht_msc3_move_note_d()
      rnt:remove_timer( pht_msc3_move_note_d_repeat )
      rnt:add_timer( pht_msc3_move_note_d, 50 )
    else
      pht_msc3_move_note_d()
      rnt:add_timer( pht_msc3_move_note_d_repeat, 300 )
    end
  else
    if rnt:has_timer( pht_msc3_move_note_d_repeat ) then
      rnt:remove_timer( pht_msc3_move_note_d_repeat )
    elseif rnt:has_timer( pht_msc3_move_note_d ) then
      rnt:remove_timer( pht_msc3_move_note_d )
    end
  end
end
---
function pht_msc3_move_note_d()
  if ( song.transport.edit_mode == true ) then
    local sli = song.selected_line_index
    local lne = sli + 1
    if ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        local snci = song.selected_note_column_index
        local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
        if ( lne <= song.selected_pattern.number_of_lines ) then
          if ( pht_msc3_swap_row_nc == true ) then
            local pos_1 = song.selected_pattern_track:line( sli ):note_column( snci )
            local pos_2 = song.selected_pattern_track:line( lne ):note_column( snci )
            for i, val in ipairs( id ) do
              pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
            end
          else
            song.selected_pattern_track:line( lne ):note_column( song.selected_note_column_index ):copy_from( song.selected_note_column )
            song.selected_note_column:clear()
          end
          song.selected_line_index = lne
        else
          local s_ssi = song.selected_sequence_index + 1
          if ( s_ssi <= #song.sequencer.pattern_sequence ) then
            local sti = song.selected_track_index
            if ( pht_msc3_swap_row_nc == true ) then
              local pos_1 = song.selected_pattern_track:line( sli ):note_column( snci )
              local pos_2 = song:pattern( s_ssi ):track( sti ):line( 1 ):note_column( snci )
              for i, val in ipairs( id ) do
                pos_1[val.."_value"], pos_2[val.."_value"] = pos_2[val.."_value"], pos_1[val.."_value"]
              end
            else
              song:pattern( s_ssi ):track( sti ):line( 1 ):note_column( snci ):copy_from( song.selected_note_column )
              song.selected_note_column:clear()
            end
            song.selected_sequence_index = s_ssi
            song.selected_line_index = 1
          else
            pht_change_status( "Select a valid line (< nol) to move/swap data!" )
          end
        end
      else
        pht_change_status( "No data to move/swap!" )
      end
    else
      pht_change_status( "Select a valid note column to move/swap data!" )
    end
  else
    pht_change_status( "Edit Mode is disabled!" )
  end
end
---



PHT_MSC3_NOTES_DATA = vb:row { spacing = -3,
  vb:button {
    id = "PHT_MSC3_SWAP_ROW_NC",
    height = 25,
    width = 27,
    color = PHT_MAIN_COLOR.GOLD_ON,
    bitmap = "./ico/swap_note_ico.png",
    notifier = function() pht_msc3_swap_row_note_column() end,
    tooltip = "Move/Swap row\n"..
              "  Disabled = move the selected row between contiguous note columns (overwrite!)\n"..
              "  Enabled = swap the selected row between contiguous note columns"
  },
  vb:button {
    id = "PHT_MSC3_MOVE_NTE_L",
    height = 25,
    width = 25,
    bitmap = "/ico/left_ico.png",
    pressed = function() pht_msc3_move_note_l_repeat() end,
    released = function() pht_msc3_move_note_l_repeat( true ) end,
    --notifier = function() pht_msc3_move_note_l() end,
    tooltip = "Move/swap the selected row in the left column\n[Alt + Left]"
  },
  vb:button {
    id = "PHT_MSC3_MOVE_NTE_R",
    height = 25,
    width = 25,
    bitmap = "/ico/right_ico.png",
    pressed = function() pht_msc3_move_note_r_repeat() end,
    released = function() pht_msc3_move_note_r_repeat( true ) end,
    --notifier = function() pht_msc3_move_note_r() end,
    tooltip = "Move/swap the selected row in the right column\n[Alt + Right]"
  },
  vb:column { spacing = -3,
    vb:button {
      height = 14,
      width = 25,
      bitmap = "/ico/up_ico.png",
      pressed = function() pht_msc3_move_note_u_repeat() end,
      released = function() pht_msc3_move_note_u_repeat( true ) end,
      --notifier = function() pht_msc3_move_note_u() end
      tooltip = "Move/swap the selected row in the previous line\n[Alt + Up]"
    },
    vb:button {
      height = 14,
      width = 25,
      bitmap = "/ico/down_ico.png",
      pressed = function() pht_msc3_move_note_d_repeat() end,
      released = function() pht_msc3_move_note_d_repeat( true ) end,
      --notifier = function() pht_msc3_move_note_d() end
      tooltip = "Move/swap the selected row in the nex line\n[Alt + Down]"
    }
  }
}



PHT_MISCELLANEOUS_3 = vb:column { margin = 1, spacing = 7, visible = false,
  vb:row { style = "panel", margin = 5, spacing = 5,
    PHT_MSC3_MOD_DATA,
    PHT_MSC3_NVPD_DATA
  },
  vb:row {  spacing = 5,
    vb:row { style = "panel", margin = 5,
      PHT_MSC3_EDIT_NOTES
    },
    vb:row { style = "panel", margin = 5,
      PHT_MSC3_NOTES_DATA
    }
  }
}
