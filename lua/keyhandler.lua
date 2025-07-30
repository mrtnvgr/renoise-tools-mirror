--
-- keyhandler
--


-----------------------------------------------------------------------------------------------
--play/stop pattern
local function kng_kh_play_stop_pattern( mode )
  if not ( song.transport.playing ) then
    if ( mode == 1 ) then
      song.transport:start( renoise.Transport.PLAYMODE_RESTART_PATTERN )
    else
      song.transport:start_at( song.selected_line_index )
    end
  else
    song.transport:stop()
  end
end



-----------------------------------------------------------------------------------------------
--edit mode, undo & redo
local function kng_kh_edit_mode()
  if ( song.transport.edit_mode == false ) then
    song.transport.edit_mode = true
  else
    song.transport.edit_mode = false
  end
end
---
function kng_kh_undo()
  if ( song:can_undo() ) then
    song:undo()
  end
end
---
function kng_kh_redo()
  if ( song:can_redo() ) then
    song:redo()
  end
end



-----------------------------------------------------------------------------------------------
--move/swap row left, rigt, up, down
local KNG_SWAP_NTE = true
local function kng_move_note_l()
  if ( song.transport.edit_mode == true ) then
    local snci = song.selected_note_column_index
    local clm = snci - 1
    if ( clm >= 1 ) and ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        if ( KNG_SWAP_NTE == true ) then
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
      end
    end
  end
end
---
local function kng_move_note_r()
  if ( song.transport.edit_mode == true ) then
    local snci = song.selected_note_column_index
    local clm = snci +1
    if ( clm <= 12 ) and ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        if ( song.selected_track.visible_note_columns < clm ) then
          song.selected_track.visible_note_columns = clm
        end
        if ( KNG_SWAP_NTE == true ) then
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
      end
    end
  end
end
---
local function kng_move_note_u()
  if ( song.transport.edit_mode == true ) then
    local sli = song.selected_line_index
    local lne = sli -1
    if ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        local snci = song.selected_note_column_index
        local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
        if ( lne >= 1 ) then
          if ( KNG_SWAP_NTE == true ) then
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
          local s_ssi = song.selected_sequence_index -1
          if ( s_ssi >= 1 ) then
            local sti = song.selected_track_index
            local s_nol = song:pattern( s_ssi ).number_of_lines
            if ( KNG_SWAP_NTE == true ) then
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
          end
        end
      end
    end
  end
end
---
local function kng_move_note_d()
  if ( song.transport.edit_mode == true ) then
    local sli = song.selected_line_index
    local lne = sli +1
    if ( song.selected_effect_column == nil ) then
      if not ( song.selected_note_column.is_empty ) then
        local snci = song.selected_note_column_index
        local id = { "note", "instrument", "volume", "panning", "delay", "effect_number", "effect_amount" }
        if ( lne <= song.selected_pattern.number_of_lines ) then
          if ( KNG_SWAP_NTE == true ) then
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
          local s_ssi = song.selected_sequence_index +1
          if ( s_ssi <= #song.sequencer.pattern_sequence ) then
            local sti = song.selected_track_index
            if ( KNG_SWAP_NTE == true ) then
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
          end
        end
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--left/right track | left/right note column
local function kng_kh_nav_tracks( value )
  local raw = renoise.ApplicationWindow
  if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_PATTERN_EDITOR ) then
    rna.window.active_middle_frame = raw.MIDDLE_FRAME_PATTERN_EDITOR
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
local function kng_kh_nav_note_columns( value )
  local raw = renoise.ApplicationWindow
  if ( rna.window.active_middle_frame ~= raw.MIDDLE_FRAME_PATTERN_EDITOR ) then
    rna.window.active_middle_frame = raw.MIDDLE_FRAME_PATTERN_EDITOR
  end
  if ( song.selected_note_column ~= nil ) then
    if ( value > 0 ) then
      if ( song.selected_note_column_index < 12 ) and ( song.selected_track.visible_note_columns > song.selected_note_column_index ) then
        song.selected_note_column_index = song.selected_note_column_index +1
      else
        if ( song.selected_track.visible_effect_columns > 0 ) then
          song.selected_effect_column_index = 1 --jump note column to effect column
        end
      end
    else
      if ( song.selected_note_column_index > 1 ) then
        song.selected_note_column_index = song.selected_note_column_index -1
      end
    end
  else
    if ( value > 0 ) then
      if ( song.selected_effect_column_index < 8 ) and ( song.selected_track.visible_effect_columns > song.selected_effect_column_index ) then
        song.selected_effect_column_index = song.selected_effect_column_index +1
      end
    else
      if ( song.selected_effect_column_index > 1 ) then
        song.selected_effect_column_index = song.selected_effect_column_index -1
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
local function kng_kh_nav_lines( value )
  local sli = song.selected_line_index
  local nol = song.selected_pattern.number_of_lines
  if ( value > 0 ) then
    if ( nol >= sli + value ) then
      song.selected_line_index = sli + value
    else
      if ( song.selected_sequence_index +1 <= #song.sequencer.pattern_sequence ) then
        song.selected_sequence_index = song.selected_sequence_index +1
        song.selected_line_index = 1
      end
    end
  else
    if ( 1 <= sli + value ) then
      song.selected_line_index = sli + value
    else
      if ( song.selected_sequence_index -1 >= 1 ) then
        song.selected_sequence_index = song.selected_sequence_index -1
        song.selected_line_index = song.selected_pattern.number_of_lines
      end
    end
  end
end
---
local function kng_kh_nav_line_first()
  song.selected_line_index = 1
end
---
local function kng_kh_nav_line_last()
  song.selected_line_index = song.selected_pattern.number_of_lines
end



-----------------------------------------------------------------------------------------------
--up/down edit_step
local function kng_kh_nav_edit_step( value )
  local sli = song.selected_line_index
  local nol = song.selected_pattern.number_of_lines
  local edit_step = song.transport.edit_step
  if ( value > 0 ) then
    if ( nol >= sli + edit_step ) then
      song.selected_line_index = sli + edit_step
    else
      local difference = edit_step - ( nol - sli )
      --print(difference)
      if ( song.selected_sequence_index +1 <= #song.sequencer.pattern_sequence ) then
        song.selected_sequence_index = song.selected_sequence_index +1
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
      if ( song.selected_sequence_index -1 >= 1 ) then
        song.selected_sequence_index = song.selected_sequence_index -1
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
function kng_kh_nav_sequence( value )
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
      --song.selected_sequence_index = sps
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down instrument
local function kng_kh_nav_instrument( value )
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
      --song.selected_instrument_index = sin
    end
  end
end



-----------------------------------------------------------------------------------------------
--previous/next plugin preset
local function kng_prev_plug_pres()
  local plug = song.selected_instrument.plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset -1 > 0 ) then
      plug.active_preset = plug.active_preset -1
    else
    end
  else
  end
end
---
local function kng_next_plug_pres()
  local plug = song.selected_instrument.plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset +1 <= #plug.presets ) then
      plug.active_preset = plug.active_preset +1
    else
    end
  else
  end
end



-----------------------------------------------------------------------------------------------
--keyhandler
function kng_keyhandler( dialog, key )

  print("name:", key.name, "|   modifiers:", key.modifiers, "|   character:", key.character, "|   note:", key.note, "|   repeated:", key.repeated )

  --hold/hold+chain notes pads panel / virtual piano
  if ( key.name == "back" ) and not ( key.modifiers == "shift + alt" ) and not ( key.modifiers == "shift + control") and not ( key.modifiers == "alt + control") and
  not ( key.repeated ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "shift" ) then
    if not ( key.modifiers == "control" ) then kng_pad_bt_sus_mode() else kng_pad_bt_sus_chain_mode() end
  end
  ---
  if ( key.name == "<" ) and not ( key.modifiers == "shift + alt" ) and not ( key.modifiers == "shift + control") and not ( key.modifiers == "alt + control") and
  not ( key.repeated ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "shift" ) then
    if not ( key.modifiers == "control" ) then kng_pno_bt_sus_mode() else kng_pno_bt_sus_chain_mode() end
  end
  
  --main panic for pads panel / virtual piano
  if ( key.name == "º" ) and not ( key.repeated ) then kng_pad_bt_panic() end
  if ( key.name == "1" ) and not ( key.repeated ) then kng_pno_bt_panic() end
  
  --jump lines
  if ( key.name == "apps" ) and not ( key.repeated ) then kng_bt_jump_lines() end
  
  --play/stop pattern
  if ( key.name == "space" ) and not ( key.repeated ) then kng_kh_play_stop_pattern( 1 ) end
  if ( key.name == "ralt" ) and not ( key.repeated ) then kng_kh_play_stop_pattern( 2 ) end

  --edit mode, undo & redo
  if ( key.name == "esc" ) and not ( key.repeated ) then kng_kh_edit_mode() end
  
  --note off & note empty, clear multiple values (advanced editor panel)
  if ( key.name == "a" ) and not ( key.repeated ) then kng_note_off_empty( 120 ) end
  if ( key.name == "del" ) then if not ( key.repeated ) then kng_note_off_empty( 121 ) else kng_note_off_empty( 121 ) kng_jump_lines() end end
  
  --undo/redo
  if ( key.name == "z" ) and ( key.modifiers == "control" ) then if not ( key.repeated ) then kng_kh_undo() else kng_kh_undo() end end
  if ( key.name == "y" ) and ( key.modifiers == "control" ) then if not ( key.repeated ) then kng_kh_redo() else kng_kh_redo() end end

  --left/right note/effect column
  if ( key.name == "left" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_note_columns( -1 ) else kng_kh_nav_note_columns( -1 ) end   
  end
  ---
  if ( key.name == "right" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_note_columns( 1 ) else kng_kh_nav_note_columns( 1 ) end   
  end

  --swap row left/right between note columns
  if ( key.name == "left" ) and ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_move_note_l() else kng_move_note_l() end   
  end
  ---
  if ( key.name == "right" ) and ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_move_note_r() else kng_move_note_r() end   
  end
  
  --swap row up/down between note columns (alt)
  if ( key.name == "up" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_move_note_u() else kng_move_note_u() end   
  end
  ---
  if ( key.name == "down" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_move_note_d() else kng_move_note_d() end   
  end

  --up/down line (any)
  if ( key.name == "up" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and not ( key.modifiers == "alt + control" ) then
    if not ( key.repeated ) then kng_kh_nav_lines( -1 ) else kng_kh_nav_lines( -1 )end
  end
  ---
  if ( key.name == "down" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and not ( key.modifiers == "alt + control" ) then
    if not ( key.repeated ) then kng_kh_nav_lines( 1 ) else kng_kh_nav_lines( 1 )end
  end
  ---
  if ( key.name == "up" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and ( key.modifiers == "alt + control" )
  or ( key.name == "home" ) then
    if not ( key.repeated ) then kng_kh_nav_line_first() end
  end
  ---
  if ( key.name == "down" ) and not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and ( key.modifiers == "alt + control" )
  or ( key.name == "end" ) then
    if not ( key.repeated ) then kng_kh_nav_line_last() end
  end

  --up/down edit_step (shift)
  if ( key.name == "up" ) and ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_edit_step( -1 ) else kng_kh_nav_edit_step( -1 ) end
  end
  ---
  if ( key.name == "down" ) and ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_edit_step( 1 ) else kng_kh_nav_edit_step( 1 ) end
  end

  --up/down sequence (ctrl)
  if ( key.name == "up" ) and not ( key.modifiers == "alt" ) and ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_sequence( -1 ) else kng_kh_nav_sequence( -1 ) end
  end
  ---
  if ( key.name == "down" ) and not ( key.modifiers == "alt" ) and ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) then
    if not ( key.repeated ) then kng_kh_nav_sequence( 1 ) else kng_kh_nav_sequence( 1 ) end
  end

  --left/right track  
  if ( key.name == "tab" ) and ( key.modifiers == "shift" ) then
   if not ( key.repeated ) then kng_kh_nav_tracks( -1 ) else kng_kh_nav_tracks( -1 ) end
  end
  ---
  if ( key.name == "tab" ) and not ( key.modifiers == "shift" ) then
   if not ( key.repeated ) then kng_kh_nav_tracks( 1 ) else kng_kh_nav_tracks( 1 ) end
  end
  
  --up/down instrument
  if ( key.name == "numpad -" ) and not ( key.modifiers == "alt" ) then
    if not ( key.repeated ) then kng_kh_nav_instrument( -1 ) else kng_kh_nav_instrument( -1 ) end
  end
  ---
  if ( key.name == "numpad +" ) and not ( key.modifiers == "alt" ) then
    if not ( key.repeated ) then kng_kh_nav_instrument( 1 ) else kng_kh_nav_instrument( 1 ) end
  end

  --previous/next plugin preset
  if ( key.name == "numpad -" ) and ( key.modifiers == "alt" ) then
    if not ( key.repeated ) then kng_prev_plug_pres() else kng_prev_plug_pres() end
  end
  ---
  if ( key.name == "numpad +" ) and ( key.modifiers == "alt" ) then
    if not ( key.repeated ) then kng_next_plug_pres() else kng_next_plug_pres() end
  end

  --controls (f1 to f12)
  if not ( key.modifiers == "shift + alt" ) and not ( key.modifiers == "shift + control") and not ( key.modifiers == "alt + control") and
  not ( key.modifiers == "alt" ) and not ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and not ( key.repeated ) then
    if ( key.name == "f1"  ) then kng_pad_show() end
    if ( key.name == "f2"  ) then kng_pad_visible( 1 ) end
    if ( key.name == "f3"  ) then kng_pad_visible( 2 ) end
    if ( key.name == "f4"  ) then kng_pad_visible( 3 ) end
    ---  
    if ( key.name == "f5"  ) then kng_piano_show() end
    if ( key.name == "f6"  ) then kng_vel_rotary_show( 0, 119 ) end
    if ( key.name == "f7"  ) then kng_pad_note_sel_jump() end
    if ( key.name == "f8"  ) then kng_bank_show() end
    ---
    if ( key.name == "f9"  ) then kng_ins_sel_pad_loop() end
    if ( key.name == "f10" ) then kng_trk_sel_pad_loop() end
    if ( key.name == "f11" ) then kng_midi_in_pad_mode() end
    if ( key.name == "f12" ) then kng_bt_split_piano() end
    if ( key.name == "return" ) then kng_preferences_show() end
    if ( key.name == "rcontrol" ) then kng_operations_show() end
  end
  
  --load banks (1 to 12)
  if not ( key.modifiers == "shift + alt" ) and not ( key.modifiers == "shift + control") and not ( key.modifiers == "alt + control") and
  not ( key.modifiers == "alt" ) and ( key.modifiers == "control" ) and not ( key.modifiers == "shift" ) and not ( key.repeated ) then
    if ( key.name == "f1"  ) then kng_load_bank( 1 ) end
    if ( key.name == "f2"  ) then kng_load_bank( 2 ) end
    if ( key.name == "f3"  ) then kng_load_bank( 3 ) end
    if ( key.name == "f4"  ) then kng_load_bank( 4 ) end
    if ( key.name == "f5"  ) then kng_load_bank( 5 ) end
    if ( key.name == "f6"  ) then kng_load_bank( 6 ) end
    if ( key.name == "f7"  ) then kng_load_bank( 7 ) end
    if ( key.name == "f8"  ) then kng_load_bank( 8 ) end
    if ( key.name == "f9"  ) then kng_load_bank( 9 ) end
    if ( key.name == "f10" ) then kng_load_bank( 10 ) end
    if ( key.name == "f11" ) then kng_load_bank( 11 ) end
    if ( key.name == "f12" ) then kng_load_bank( 12 ) end
  end

  --close dialog
  if ( key.name == "k" ) and not ( key.repeated ) then KNG_MAIN_DIALOG:close() end
end
