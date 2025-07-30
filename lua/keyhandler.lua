-----------------------------------------------------------------------------------------------
--f1 to f12, note column nav 1-12
local ASC_SEL_NCOL={false,1}
function asc_sel_ncol_add_timer(ncol)
  if (ncol~=nil) then
    ASC_SEL_NCOL[2]=ncol
  end
  if not rnt:has_timer(asc_sel_ncol_add_timer) then
    rnt:add_timer(asc_sel_ncol_add_timer,700)
  else
    local trk=song.selected_track
    if (trk.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      trk.visible_note_columns=ASC_SEL_NCOL[2]
      song.selected_note_column_index=ASC_SEL_NCOL[2]
    end
    
    if rnt:has_timer(asc_sel_ncol_add_timer) then
      rnt:remove_timer(asc_sel_ncol_add_timer)
    end
    ASC_SEL_NCOL[1]=true
  end
end

function asc_sel_ncol_remove_timer(ncol)
  if not (ASC_SEL_NCOL[1]) then
    local trk=song.selected_track
    if (trk.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      if (trk.visible_note_columns~=0) then
        if (ncol>trk.visible_note_columns) then
          trk.visible_note_columns=ncol
        end
        song.selected_note_column_index=ncol
      end
    end
  end
  if rnt:has_timer(asc_sel_ncol_add_timer) then
    rnt:remove_timer(asc_sel_ncol_add_timer)
  end
  ASC_SEL_NCOL[1]=false
end









-----------------------------------------------------------------------------------------------
--left/right track | left/right note column
ASC_TRK_BRAKE={true,true}
function asc_kh_nav_tracks(value)
  local raw=renoise.ApplicationWindow
  if (rna.window.active_middle_frame~=raw.MIDDLE_FRAME_PATTERN_EDITOR) then
    rna.window.active_middle_frame=raw.MIDDLE_FRAME_PATTERN_EDITOR
  end
  if (value<0) then
    if (ASC_TRK_BRAKE[1]) then
      song:select_previous_track()
    end
    if (song.selected_track_index==1) then
      ASC_TRK_BRAKE[1]=false
    end
  else
    if (ASC_TRK_BRAKE[2]) then
      song:select_next_track()
    end
    if (song.selected_track_index==#song.tracks) then
      ASC_TRK_BRAKE[2]=false
    end
  end
end



local function asc_kh_nav_note_columns(value)
  local raw=renoise.ApplicationWindow
  if (rna.window.active_middle_frame~=raw.MIDDLE_FRAME_PATTERN_EDITOR) then
    rna.window.active_middle_frame=raw.MIDDLE_FRAME_PATTERN_EDITOR
  end
  if (song.selected_note_column~=nil) then
    if (value>0) then
      if (song.selected_note_column_index<12) and (song.selected_track.visible_note_columns>song.selected_note_column_index) then
        song.selected_note_column_index=song.selected_note_column_index+1
      else
        if (song.selected_track.visible_effect_columns>0) then
          song.selected_effect_column_index=1
        end
      end
    else
      if (song.selected_note_column_index>1) then
        song.selected_note_column_index=song.selected_note_column_index-1
      end
    end
  else
    if (value>0) then
      if (song.selected_effect_column_index<8) and (song.selected_track.visible_effect_columns>song.selected_effect_column_index) then
        song.selected_effect_column_index=song.selected_effect_column_index+1
      end
    else
      if (song.selected_effect_column_index>1) then
        song.selected_effect_column_index=song.selected_effect_column_index-1
      else
        if (song.selected_track.visible_note_columns>0) then
          song.selected_note_column_index=song.selected_track.visible_note_columns
        end
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down line
function asc_kh_nav_lines(value)
  local sli=song.selected_line_index
  local nol=song.selected_pattern.number_of_lines
  if (value>0) then
    if (nol>=sli+value) then
      song.selected_line_index=sli+value
    else
      if (song.selected_sequence_index+1<=#song.sequencer.pattern_sequence) then
        song.selected_sequence_index=song.selected_sequence_index+1
        song.selected_line_index=1
      end
    end
  else
    if (1<=sli+value) then
      song.selected_line_index=sli+value
    else
      if (song.selected_sequence_index-1>=1) then
        song.selected_sequence_index=song.selected_sequence_index-1
        song.selected_line_index=song.selected_pattern.number_of_lines
      end
    end
  end
end

--up/down first or last line
local function asc_kh_nav_line_first(bol)
  if (bol) then
    song.selected_sequence_index=1
  end
  song.selected_line_index=1
end

local function asc_kh_nav_line_last(bol)
  if (bol) then
    song.selected_sequence_index=#song.sequencer.pattern_sequence
    song.selected_line_index=1
  else
    song.selected_line_index=song.selected_pattern.number_of_lines
  end
end



-----------------------------------------------------------------------------------------------
--up/down pattern sequence
ASC_SEQ_BRAKE={true,true}
function asc_kh_nav_sequence(value)
  local ssi=song.selected_sequence_index
  local sps=#song.sequencer.pattern_sequence
  if (value<0) then
    if (ASC_SEQ_BRAKE[1]) then
      if (ssi>1) then
        song.selected_sequence_index=ssi-1
      else
        song.selected_sequence_index=sps
      end
    end
    if (song.selected_sequence_index==1) then
      ASC_SEQ_BRAKE[1]=false
    end
  else
    if (ASC_SEQ_BRAKE[2]) then
      if (ssi<sps) then
        song.selected_sequence_index=ssi+1
      else
        song.selected_sequence_index=1
      end
    end
    if (song.selected_sequence_index==sps) then
      ASC_SEQ_BRAKE[2]=false
    end
  end
end



local ASC_NAV_SEQ=1
local function asc_kh_nav_seq_rep()
  return asc_kh_nav_sequence(ASC_NAV_SEQ)
end
function asc_kh_nav_sequence_repeat(release,val)
  if not release then
    if rnt:has_timer(asc_kh_nav_sequence_repeat) then
      rnt:remove_timer(asc_kh_nav_sequence_repeat)
      rnt:add_timer(asc_kh_nav_seq_rep,55)
    else
      ASC_NAV_SEQ=val
      --print(val)
      asc_kh_nav_sequence(ASC_NAV_SEQ)
      rnt:add_timer(asc_kh_nav_sequence_repeat,300)
    end
  else
    if rnt:has_timer(asc_kh_nav_sequence_repeat) then
      rnt:remove_timer(asc_kh_nav_sequence_repeat)
    elseif rnt:has_timer(asc_kh_nav_seq_rep) then
      rnt:remove_timer(asc_kh_nav_seq_rep)
    end
  end
end



-----------------------------------------------------------------------------------------------
--up/down instrument
ASC_INS_BRAKE={true,true}
function asc_kh_nav_instrument(value)
  local sii=song.selected_instrument_index
  local sin=#song.instruments
  if (value<0) then
    if (ASC_INS_BRAKE[1]) then
      if (sii>1) then
        song.selected_instrument_index=sii-1
      else
        song.selected_instrument_index=sin
      end
    end
    if (song.selected_instrument_index==1) then
      ASC_INS_BRAKE[1]=false
    end
  else
    if (ASC_INS_BRAKE[2]) then
      if (sii<sin) then
        song.selected_instrument_index=sii+1
      else
        song.selected_instrument_index=1
      end
    end
    if (song.selected_instrument_index==sin) then
      ASC_INS_BRAKE[2]=false
    end
  end
end



-----------------------------------------------------------------------------------------------
--previous/next plugin preset
local function asc_kh_prev_plug_pres()
  local plug=song.selected_instrument.plugin_properties.plugin_device
  if (plug~=nil) then
    if (plug.active_preset-1>0) then
      plug.active_preset=plug.active_preset-1
    else
    end
  else
  end
end
---
local function asc_kh_next_plug_pres()
  local plug=song.selected_instrument.plugin_properties.plugin_device
  if (plug~=nil) then
    if (plug.active_preset+1<=#plug.presets) then
      plug.active_preset=plug.active_preset+1
    else
    end
  else
  end
end



-----------------------------------------------------------------------------------------------
function asc_keyhandler(dialog,key)
  --print("name:",key.name,"|   state:",key.state,"|   modifiers:",key.modifiers,"|   character:",key.character,"|   note:",key.note,"|   repeated:",key.repeated)

  --close window
  if not (key.modifiers=="shift + alt") and (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="a") and (key.state=="pressed") and not (key.repeated) then
      if (ASC_MAIN_DIALOG and ASC_MAIN_DIALOG.visible) then ASC_MAIN_DIALOG:close() end
    end
  end
  
  --undo/redo
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="z" and key.state=="pressed") then if not (key.repeated) then asc_undo() else asc_undo() end end
    if (key.name=="y" and key.state=="pressed") then if not (key.repeated) then asc_redo() else asc_redo() end end
  end

  --play restore/stop
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="space" and key.state=="pressed") and not (key.repeated) then asc_play_stop(1) end
  end

  --play continue/stop
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="space" and key.state=="pressed") and not (key.repeated) then asc_play_stop(2) end
  end

  --edit mode
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="esc" and key.state=="pressed") and not (key.repeated) then asc_edit_mode() end
  end

  --steps navigation
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="return" and key.state=="pressed") then if not (key.repeated) then asc_key_return() else asc_key_return() end end
  end

  --controls (f1 to f12) & others
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.repeated) then
    for ncol=1,12 do
      if (key.name==("f%s"):format(ncol)) then
        if (key.state=="pressed") then asc_sel_ncol_add_timer(ncol) end
        if (key.state=="released") then asc_sel_ncol_remove_timer(ncol) end
      end
    end
  end

  --left/right note/effect column
  if (key.name=="left" and key.state=="pressed") and not (key.modifiers=="shift") and not (key.modifiers=="alt") then
    if not (key.repeated) then asc_kh_nav_note_columns(-1) else asc_kh_nav_note_columns(-1) end
  end
  
  if (key.name=="right" and key.state=="pressed") and not (key.modifiers=="shift") and not (key.modifiers=="alt") then
    if not (key.repeated) then asc_kh_nav_note_columns(1) else asc_kh_nav_note_columns(1) end
  end



  --up/down line (any)
  if (key.name=="up" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_lines(-1) else asc_kh_nav_lines(-1) end
  end
  
  if (key.name=="down" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_lines(1) else asc_kh_nav_lines(1) end
  end

  if (key.name=="up" and key.state=="pressed") and (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_nav_step_first_lne() end
  end
  
  if (key.name=="down" and key.state=="pressed") and (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_nav_step_last_lne() end
  end
  
  if (key.name=="up" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and (key.modifiers=="alt + control")
  or (key.name=="home" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_line_first(false) end
  end

  if (key.name=="home" and key.state=="pressed") and not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_line_first(true) end
  end
  
  if (key.name=="down" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and (key.modifiers=="alt + control")
  or (key.name=="end" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_line_last(false) end
  end

  if (key.name=="end" and key.state=="pressed") and not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") and not (key.modifiers=="alt + control") then
    if not (key.repeated) then asc_kh_nav_line_last(true) end
  end



  --up/down sequence (ctrl)
  if (key.name=="up" and key.state=="pressed") and not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then ASC_SEQ_BRAKE[1]=true asc_kh_nav_sequence(-1) else asc_kh_nav_sequence(-1) end
  end
  
  if (key.name=="down" and key.state=="pressed") and not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then ASC_SEQ_BRAKE[2]=true asc_kh_nav_sequence(1) else asc_kh_nav_sequence(1) end
  end

  --left/right track  
  if (key.name=="tab" and key.state=="pressed") and (key.modifiers=="shift") then
   if not (key.repeated) then ASC_TRK_BRAKE[1]=true asc_kh_nav_tracks(-1) else asc_kh_nav_tracks(-1) end
  end
  
  if (key.name=="tab" and key.state=="pressed") and not (key.modifiers=="shift") then
   if not (key.repeated) then ASC_TRK_BRAKE[2]=true asc_kh_nav_tracks(1) else asc_kh_nav_tracks(1) end
  end
  
  --up/down instrument
  if (key.name=="numpad -" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then ASC_INS_BRAKE[1]=true asc_kh_nav_instrument(-1) else asc_kh_nav_instrument(-1) end
  end
  
  if (key.name=="numpad +" and key.state=="pressed") and not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then ASC_INS_BRAKE[2]=true asc_kh_nav_instrument(1) else asc_kh_nav_instrument(1) end
  end

  --up/down preset plugin
  if (key.name=="numpad -" and key.state=="pressed") and (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then asc_kh_prev_plug_pres() else asc_kh_prev_plug_pres() end
  end
  
  if (key.name=="numpad +" and key.state=="pressed") and (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if not (key.repeated) then asc_kh_next_plug_pres() else asc_kh_next_plug_pres() end
  end


  --import data
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and (key.modifiers=="shift") then
    if (key.name=="back" and key.state=="pressed") and not (key.repeated) then asc_key_back() end
  end


  --insert steps
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or
  
  not (key.modifiers=="shift + alt") and (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="ins" and key.state=="pressed") and not (key.repeated) then asc_key_ins() end
  end


  --clear steps
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and (key.modifiers=="control") and not (key.modifiers=="shift") or

  not (key.modifiers=="shift + alt") and (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="del" and key.state=="pressed") and not (key.repeated) then asc_key_del() end
  end


  --transpose up
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="prior") and not (key.repeated) then
      if (key.state=="pressed") then
        asc_transpose_up_repeat(false)
      else
        asc_transpose_up_repeat(true)
      end
    end
  end

  --transpose down
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="next") and not (key.repeated) then
      if (key.state=="pressed") then
        asc_transpose_down_repeat(false)
      else
        asc_transpose_down_repeat(true)
      end
    end
  end

  --on/off steps marker
  if not (key.modifiers=="shift + alt") and not (key.modifiers=="shift + control") and not (key.modifiers=="alt + control") and
  not (key.modifiers=="alt") and not (key.modifiers=="control") and not (key.modifiers=="shift") then
    if (key.name=="rcontrol" and key.state=="pressed") and not (key.repeated) then asc_key_rctrl() end
  end
  
  --return key  --reinvoke the keybinding
end
