----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: Start Recording On Note Input or STN
-- Version: 1.0 build 001
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
local STN_NAME="Start Recording On Note Input"
local rna=renoise.app()
local rnt=renoise.tool()

--global song
song=nil
  local function stn_sng() song=renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier(stn_sng) --catching start renoise or new song
  pcall(stn_sng) --catching installation

local stn_start_rec_value=false



-----------------------------------------------------------------------------------------------
--define functions
-----------------------------------------------------------------------------------------------

--function to start recording with observable and notifier
local function stn_start_rec()
  local tra=song.transport
  if (not tra.playing) then
    if (song.selected_sub_column_type==renoise.Song.SUB_COLUMN_NOTE) then
      --when a note is inserted
      if (song.selected_note_column.note_value<=120) then
        --enable follow player
        if (not tra.follow_player) then
          tra.follow_player=true
        end
        --disable metronome precount
        if (tra.metronome_precount_enabled) then
          tra.metronome_precount_enabled=false
        end
        --start playing the song
        tra:start_at(song.selected_line_index)
      end
    end
  end
end



--function to follow the pattern
local function stn_follow_patt()
  --remove line_edited_notifier to all patterns
  for p=1,#song.patterns do
    if song:pattern(p):has_line_edited_notifier(stn_start_rec) then
      song:pattern(p):remove_line_edited_notifier(stn_start_rec)
    end
  end
  --add line_edited_notifier to selected pattern
  if not song.selected_pattern:has_line_edited_notifier(stn_start_rec) then
    song.selected_pattern:add_line_edited_notifier(stn_start_rec)
  end
end



--function to enable/disable start recording 
local function stn_start_rec_bang()
  if (stn_start_rec_value) then
    --add line_edited_notifier
    if not song.selected_pattern:has_line_edited_notifier(stn_start_rec) then
      song.selected_pattern:add_line_edited_notifier(stn_start_rec)
    end
    --add selected_pattern_index_observable
    if not song.selected_pattern_index_observable:has_notifier(stn_follow_patt) then
      song.selected_pattern_index_observable:add_notifier(stn_follow_patt)
    end
    rna:show_status(("%s Enabled!"):format(STN_NAME))
  else
    --remove line_edited_notifier
    if song.selected_pattern:has_line_edited_notifier(stn_start_rec) then
      song.selected_pattern:remove_line_edited_notifier(stn_start_rec)
      
    end
    --remove selected_pattern_index_observable
    if song.selected_pattern_index_observable:has_notifier(stn_follow_patt) then
      song.selected_pattern_index_observable:remove_notifier(stn_follow_patt)
    end
    rna:show_status(("%s Disabled!"):format(STN_NAME))
  end
end



--function to initialize in new song
if not rnt.app_new_document_observable:has_notifier(stn_start_rec_bang) then
  rnt.app_new_document_observable:add_notifier(stn_start_rec_bang)
end



-----------------------------------------------------------------------------------------------
--register menu_entry
-----------------------------------------------------------------------------------------------
--menu options
rnt:add_menu_entry{
  name=("Main Menu:Options:%s"):format(STN_NAME),
  invoke=function() stn_start_rec_value=not stn_start_rec_value stn_start_rec_bang() end,
  selected=function() return stn_start_rec_value end,
}
