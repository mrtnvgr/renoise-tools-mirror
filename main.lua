--
-- Menu Tool: "Random Range Track"
-- Version: 2.0 build 002
-- Release Date: January 2019
-- Compatibility: Renoise 3.1.1
-- Programmer: ulneiz
--
-- Description: This double function randomizes the notes or values of the selected range within the selected track.
--              First it is necessary to select an area in the pattern editor.
--              The first line and the last line selected must have different notes/values, which define the
--              minimum and maximum notes/values of the range to randomize.
--              Use "ALT + mouse select" to the precise selection.
--
--              Access: "Pattern Editor/Selection/Randomize Notes... (or Randomize Effects...)".
--
--
-- Update History:
-- V2.0
-- *Correction of the declaration of the "locals" to determine the minimum and maximum values for each sub-column.
--
-- v1.0
-- *First Release
--


--randomize notes (C-0 to B-9)
local function random_range_track_notes()
  local song=renoise.song()
  local spt=song.selected_pattern_track
  local sel=song.selection_in_pattern
  local range={sel.start_line,sel.end_line}
  --rprint(range)
  if (sel~=nil) and not song.selected_effect_column then
    local val_1={}
    local val_2={}
    for ncl=1,12 do
      val_1[ncl]=spt:line(range[1]):note_column(ncl).note_value
      val_2[ncl]=spt:line(range[2]):note_column(ncl).note_value
    end
    --rprint(val_1)
    --print("-------------------------")
    --rprint(val_2)
    for lne=range[1],range[2] do
      --note columns (notes only)
      for ncl=1,12 do
        local nte_col=spt:line(lne):note_column(ncl)
        if (nte_col.is_selected) then
          --note
          if (nte_col.note_value<120) then
            --print(val_1[ncl],val_2[ncl])
            if (val_1[ncl]<120) and (val_2[ncl]<120) then
              if (val_1[ncl]<val_2[ncl]) then
                nte_col.note_value=math.random(val_1[ncl],val_2[ncl])
              elseif (val_1[ncl]>val_2[ncl]) then
                nte_col.note_value=math.random(val_2[ncl],val_1[ncl])
              end
            end
          end
        end
      end
    end
  else
    renoise.app():show_status("Random Range Track: first select an area whitin the note columns for randomize the notes!")
  end
end



--randomize effect values (volume, panning, delay, sample effects & effect columns)
local function random_range_track_effect()
  local song=renoise.song()
  local spt=song.selected_pattern_track
  local sel=song.selection_in_pattern
  local range={sel.start_line,sel.end_line}
  --rprint(range)
  if (sel~=nil) then
    --note columns (vol,pan,dly,sfx)
    if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      local vol_1={}
      local vol_2={}
      local pan_1={}
      local pan_2={}
      local dly_1={}
      local dly_2={}
      local sfx_1={}
      local sfx_2={}
      for ncl=1,12 do
        vol_1[ncl]=spt:line(range[1]):note_column(ncl).volume_value
        vol_2[ncl]=spt:line(range[2]):note_column(ncl).volume_value
        pan_1[ncl]=spt:line(range[1]):note_column(ncl).panning_value
        pan_2[ncl]=spt:line(range[2]):note_column(ncl).panning_value
        dly_1[ncl]=spt:line(range[1]):note_column(ncl).delay_value
        dly_2[ncl]=spt:line(range[2]):note_column(ncl).delay_value
        sfx_1[ncl]=spt:line(range[1]):note_column(ncl).effect_amount_value
        sfx_2[ncl]=spt:line(range[2]):note_column(ncl).effect_amount_value
      end
      ---
      for lne=range[1],range[2] do
        for ncl=1,12 do
          local nte_col=spt:line(lne):note_column(ncl)
          if (nte_col.is_selected) then
            --volume
            if (nte_col.volume_string~="..") then
              if (vol_1[ncl]<=127) and (vol_2[ncl]<=127) then
                if (vol_1[ncl]<vol_2[ncl]) then
                  nte_col.volume_value=math.random(vol_1[ncl],vol_2[ncl])
                elseif (vol_1[ncl]>vol_2[ncl]) then
                  nte_col.volume_value=math.random(vol_2[ncl],vol_1[ncl])
                end
              end
            end
            --panning
            if (nte_col.panning_string~="..") then
              if (pan_1[ncl]<=127) and (pan_2[ncl]<=127) then
                if (pan_1[ncl]<pan_2[ncl]) then
                  nte_col.panning_value=math.random(pan_1[ncl],pan_2[ncl])
                elseif (pan_1[ncl]>pan_2[ncl]) then
                  nte_col.panning_value=math.random(pan_2[ncl],pan_1[ncl])
                end
              end
            end
            --delay
            if (nte_col.delay_string~="..") then
              if (dly_1[ncl]<=256) and (dly_1[ncl]>0) and (dly_2[ncl]<=256) and (dly_2[ncl]>0) then            
                if (dly_1[ncl]<dly_2[ncl]) then
                  nte_col.delay_value=math.random(dly_1[ncl],dly_2[ncl])
                elseif (val_1>val_2) then
                  nte_col.delay_value=math.random(dly_2[ncl],dly_1[ncl])
                end
              end
            end
            --sample effects
            if (nte_col.effect_number_string==spt:line(range[1]):note_column(ncl).effect_number_string) then
              if (sfx_1[ncl]<sfx_2[ncl]) then
                nte_col.effect_amount_value=math.random(sfx_1[ncl],sfx_2[ncl])
              elseif (sfx_1[ncl]>sfx_2[ncl]) then
                nte_col.effect_amount_value=math.random(sfx_2[ncl],sfx_1[ncl])
              end
            end
          end
        end
      end
    end
    --effect columns
    local eff_1={}
    local eff_2={}
    for ecl=1,8 do
      eff_1[ecl]=spt:line(range[1]):effect_column(ecl).amount_value
      eff_2[ecl]=spt:line(range[2]):effect_column(ecl).amount_value
    end
    ---
    for lne=range[1],range[2] do      
      for ecl=1,8 do
        local eff_col=spt:line(lne):effect_column(ecl)
        if (eff_col.is_selected) then
          if (eff_col.number_string==spt:line(range[1]):effect_column(ecl).number_string) then
            if (eff_1[ecl]<eff_2[ecl]) then
              eff_col.amount_value=math.random(eff_1[ecl],eff_2[ecl])
            elseif (eff_1[ecl]>eff_2[ecl]) then
              eff_col.amount_value=math.random(eff_2[ecl],eff_1[ecl])
            end
          end
        end
      end
    end
  end
end



--menu entry
renoise.tool():add_menu_entry{
  name=("Pattern Editor:Selection:Randomize Notes (Range Track)"),
  invoke=function() random_range_track_notes() end
}
renoise.tool():add_menu_entry{
  name=("Pattern Editor:Selection:Randomize Effects (Range Track)"),
  invoke=function() random_range_track_effect() end
}
