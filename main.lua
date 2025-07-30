----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: Playback Loop Selection or PLS
-- Version: 1.3 build 004
-- License: Free
-- Compatibility: Renoise v3.2.2
-- Published: August 2020
-- Locate: Spain
-- Programmer: ulneiz
--
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------
--define local/global
-----------------------------------------------------------------------------------------------
local PLS_NAME="Playback Loop Selection"
local rna=renoise.app()
local rnt=renoise.tool()

--global song
song=nil
  local function pls_sng() song=renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier(pls_sng) --catching start renoise or new song
  pcall(pls_sng) --catching installation

--preferences xml
local pls_options = renoise.Document.create("PLS_Preferences") {
  jump_first_line=true,
  stop_play=true,
  disable_pls=false,
  turn_off_trk=false,
  auto_select=true,
  select_all_trk=false,
  time=10,
  line=16,
  lines_02=false,
  lines_03=false,
  lines_04=false,
  lines_05=false,
  lines_06=false,
  lines_07=false,
  lines_08=false,
  lines_09=false,
  lines_10=false,
  lines_11=false,
  lines_12=false,
  lines_13=false,
  lines_14=false,
  lines_15=false,
  lines_16=true,
  lines_17=false,
  lines_18=false,
  lines_19=false,
  lines_20=false,
  lines_21=false,
  lines_22=false,
  lines_23=false,
  lines_24=false,
  lines_25=false,
  lines_26=false,
  lines_27=false,
  lines_28=false,
  lines_29=false,
  lines_30=false,
  lines_31=false,
  lines_32=false,
  ms_005=false,
  ms_010=true,
  ms_015=false,
  ms_020=false,
  ms_025=false,
  ms_030=false,
  ms_035=false,
  ms_040=false,
  ms_045=false,
  ms_050=false,
  ms_055=false,
  ms_060=false,
  ms_065=false,
  ms_070=false,
  ms_075=false,
  ms_080=false,
  ms_085=false,
  ms_090=false,
  ms_095=false,
  ms_100=false,
  ms_105=false,
  ms_110=false,
  ms_115=false,
  ms_120=false,
  ms_125=false,
  ms_130=false,
  ms_135=false,
  ms_140=false,
  ms_145=false,
  ms_150=false,
}
rnt.preferences=pls_options

--buffer selection_in_pattern & sequence index
local pls_sel_pat={
  start_line=1,
  end_line=1,
  start_track=1,
  end_track=1
}
local pls_seq=0

local pls_trk={
  active=false,
  start_trk=1,
  end_trk=1,
  max=1,
  mute={}
}



-----------------------------------------------------------------------------------------------
--define functions
-----------------------------------------------------------------------------------------------
--functions to silence tracks
local function pls_turn_off_tracks_state()
  if (pls_options.turn_off_trk.value) then
    pls_trk.active=true
    local sel=song.selection_in_pattern
    if (sel) then
      pls_trk.max=song.sequencer_track_count --#song.tracks
      pls_trk.start_trk=sel.start_track
      pls_trk.end_trk=sel.end_track
      --track mute_state:
        --active=1
        --off=2
        --muted=3
      for t=1,pls_trk.max do
        local trk=song:track(t)
        pls_trk.mute[t]=trk.mute_state
        if (trk.type~=renoise.Track.TRACK_TYPE_GROUP) then
          if (trk.mute_state==1) and (t<pls_trk.start_trk) or
             (trk.mute_state==1) and (t>pls_trk.end_trk) then
            trk.mute_state=2
          end
        end
      end
      --rprint(pls_trk)
    end
  end
end

local function pls_restart_tracks_state()
  if (pls_trk.active) then
    if (pls_trk.max==song.sequencer_track_count) then
      --print("restart")
      for t=1,pls_trk.max do
        if (song:track(t).type~=renoise.Track.TRACK_TYPE_GROUP) then
          if (pls_trk.mute[t]==1) and (t<pls_trk.start_trk) or
             (pls_trk.mute[t]==1) and (t>pls_trk.end_trk) then
            song:track(t).mute_state=1
          end
        end
      end
    else
      for t=1,song.sequencer_track_count do
        if (song:track(t).type~=renoise.Track.TRACK_TYPE_GROUP) then
          if (song:track(t).mute_state~=1) then
            song:track(t).mute_state=1
          end
        end
      end
    end
    pls_trk.active=false
  end
end



--function to playback loop selection with timer
local function pls_play_loop_sel()
  local tra=song.transport
  local sel=song.selection_in_pattern
  local function rearm_buf_pls_sel_pat()
    if (tra.playback_pos.line==song.selected_pattern.number_of_lines and sel) then
      pls_sel_pat.start_line=sel.start_line
      pls_sel_pat.end_line=sel.end_line
      pls_sel_pat.start_track=sel.start_track
      pls_sel_pat.end_track=sel.end_track
    end
  end
  local function rearm_sel_in_patt()
    local nol=song.selected_pattern.number_of_lines
    if (pls_sel_pat.start_line>nol) then
      pls_sel_pat.start_line=nol
    end
    if (pls_sel_pat.end_line>nol) then
      pls_sel_pat.end_line=nol
    end
    song.selection_in_pattern={
      start_line=pls_sel_pat.start_line,
      end_line=pls_sel_pat.end_line,
      start_track=pls_sel_pat.start_track,
      end_track=pls_sel_pat.end_track
    }
  end  
  if (tra.playing) then
    --restore sequence index from last pattern line
    if (not tra.follow_player) then
      if (tra.playback_pos.sequence==pls_seq) then
        rearm_buf_pls_sel_pat()
      else
        if (sel) then
          song.selected_sequence_index=pls_seq
          rearm_sel_in_patt()
          song.selected_line_index=pls_sel_pat.start_line
          tra:start_at(pls_sel_pat.start_line)
        else
          if (pls_seq~=song.selected_sequence_index) then
            pls_seq=song.selected_sequence_index
          end
        end
        --print("not_follow")
      end
    else
      if (song.selected_sequence_index==pls_seq) then
        rearm_buf_pls_sel_pat()
      else
        if (sel) then
          song.selected_sequence_index=pls_seq
          rearm_sel_in_patt()
          tra:start_at(pls_sel_pat.start_line)
        else
          if (pls_seq~=song.selected_sequence_index) then
            pls_seq=song.selected_sequence_index
          end
        end
        --print("follow")
      end
    end
    if (sel) then
      --restores start line
      if (sel.end_line<tra.playback_pos.line) then
        tra:start_at(sel.start_line)
      end
      --turn off tracks
      if (pls_options.turn_off_trk.value) then
        if (sel.start_track~=pls_trk.start_trk) or (sel.end_track~=pls_trk.end_trk) then
          pls_restart_tracks_state()
          pls_turn_off_tracks_state()
        end
      end
    end
  end
  if (pls_options.disable_pls.value) then
    if (not tra.playing) then
      if rnt:has_timer(pls_play_loop_sel) then
        rnt:remove_timer(pls_play_loop_sel)
        rna:show_status(("%s Disabled!"):format(PLS_NAME))
        pls_restart_tracks_state()
      end
    end
  end
end



--function to disable timer in new song
local function pls_off_timer()
  if rnt:has_timer(pls_play_loop_sel) then
    rnt:remove_timer(pls_play_loop_sel)
    rna:show_status(("%s Disabled!"):format(PLS_NAME))
    pls_restart_tracks_state()
  end
end



--function to timer for start/stop from keybinding
local function pls_play_loop_sel_bang()
  pls_seq=song.selected_sequence_index
  if not rnt:has_timer(pls_play_loop_sel) then
    if (pls_options.auto_select.value) then
      if (not song.selection_in_pattern) then
        --auto selection
        local end_lne=song.selected_line_index+pls_options.line.value-1
        if (end_lne>song.selected_pattern.number_of_lines) then
          end_lne=song.selected_pattern.number_of_lines
        end
        if (pls_options.select_all_trk.value) then
          song.selection_in_pattern={
            start_line=song.selected_line_index,
            end_line=end_lne,
            start_track=1,
            end_track=#song.tracks
          }
        else
          song.selection_in_pattern={
            start_line=song.selected_line_index,
            end_line=end_lne,
            start_track=song.selected_track_index,
            end_track=song.selected_track_index
          }
        end
        --rprint(song.selection_in_pattern)
        --print("all visible columns:",song.selected_track.visible_note_columns+song.selected_track.visible_effect_columns)
      end
    end
    if (song.selection_in_pattern) then
      if (pls_options.jump_first_line.value) then
        song.transport:start_at(song.selection_in_pattern.start_line)
      else
        if (song.selected_line_index<song.selection_in_pattern.start_line or song.selected_line_index>song.selection_in_pattern.end_line) then
          song.transport:start_at(song.selection_in_pattern.start_line)
        else
          song.transport:start_at(song.selected_line_index)
        end
      end
      rnt:add_timer(pls_play_loop_sel,pls_options.time.value)
      rna:show_status(("%s Enabled!"):format(PLS_NAME))
      pls_turn_off_tracks_state()
      --disable timer in new song
      if not rnt.app_new_document_observable:has_notifier(pls_off_timer) then
        rnt.app_new_document_observable:add_notifier(pls_off_timer)
      end
    else
      --manual selection
      rna:show_status("First make a selection in the pattern editor to play it as a block loop!")
    end
  else
    rnt:remove_timer(pls_play_loop_sel)
    if (pls_options.stop_play.value) then
      song.transport:stop()
    end
    rna:show_status(("%s Disabled!"):format(PLS_NAME))
    pls_restart_tracks_state()
  end
end



-----------------------------------------------------------------------------------------------
--register keybinding to bang/unmark
-----------------------------------------------------------------------------------------------
rnt:add_keybinding{
  --name=("Global:Tools:%s"):format("Playback Loop Selection"),
  name=("Pattern Editor:Selection:%s"):format(PLS_NAME),
  invoke=function() pls_play_loop_sel_bang() end
}



rnt:add_keybinding{
  --name=("Global:Tools:%s"):format("Playback Loop Selection"),
  name=("Pattern Editor:Selection:%s"):format("Unmark Selection"),
  invoke=function()
    song.selection_in_pattern=nil
    rna:show_status("Selection Unmarked!")
  end
}



-----------------------------------------------------------------------------------------------
--register menu_entry
-----------------------------------------------------------------------------------------------
--menu options
rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Jump First Line When Starting"):format(PLS_NAME),
  invoke=function() pls_options.jump_first_line.value=not pls_options.jump_first_line.value end,
  selected=function() return pls_options.jump_first_line.value end,
}



rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Stop Playing Song When Stopping"):format(PLS_NAME),
  invoke=function() pls_options.stop_play.value=not pls_options.stop_play.value end,
  selected=function() return pls_options.stop_play.value end,
}



rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Disable PLS When Stop Song"):format(PLS_NAME),
  invoke=function() pls_options.disable_pls.value=not pls_options.disable_pls.value end,
  selected=function() return pls_options.disable_pls.value end,
}



rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Turn OFF/PLAY All Other Tracks"):format(PLS_NAME),
  invoke=function() pls_options.turn_off_trk.value=not pls_options.turn_off_trk.value end,
  selected=function() return pls_options.turn_off_trk.value end,
}



rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Auto Select:Enable Auto Lines Selection"):format(PLS_NAME),
  invoke=function() pls_options.auto_select.value=not pls_options.auto_select.value end,
  selected=function() return pls_options.auto_select.value end,
}



rnt:add_menu_entry{
  name=("Main Menu:Tools:%s:Auto Select:Enable Select All Tracks"):format(PLS_NAME),
  invoke=function() pls_options.select_all_trk.value=not pls_options.select_all_trk.value end,
  active=function() return pls_options.auto_select.value end,
  selected=function() return pls_options.select_all_trk.value end,
}



--menu select lines
for i=2,32 do
  rnt:add_menu_entry{
    name=("Main Menu:Tools:%s:Auto Select:%.2d lines"):format(PLS_NAME,i),
    selected=function() return pls_options[("lines_%.2d"):format(i)].value end,
    active=function() return pls_options.auto_select.value end,
    invoke=function()
      for m=2,32 do
        pls_options[("lines_%.2d"):format(m)].value=false
      end
      pls_options[("lines_%.2d"):format(i)].value=true
      pls_options.line.value=i --print("line",pls_options.line.value)
    end
  }
end



--menu select miliseconds
for i=5,150,5 do
  rnt:add_menu_entry{
    name=("Main Menu:Tools:%s:Response Time:%.3d ms"):format(PLS_NAME,i),
    selected=function() return pls_options[("ms_%.3d"):format(i)].value end,
    invoke=function()
      for m=5,150,5 do
        pls_options[("ms_%.3d"):format(m)].value=false
      end
      pls_options[("ms_%.3d"):format(i)].value=true
      pls_options.time.value=i --print("ms",pls_options.time.value)
      --restart timer
      if rnt:has_timer(pls_play_loop_sel) then
        rnt:remove_timer(pls_play_loop_sel)
        rnt:add_timer(pls_play_loop_sel,pls_options.time.value)
        rna:show_status(("Restart %s with Response Time: %.2d ms!"):format(PLS_NAME,pls_options.time.value))
      end
    end
  }
end
