--
-- Menu Tool: "Slice Importer"
-- Version: 1.1 build 002
-- Release Date: February 2019
-- Compatibility: Renoise 3.1.1
-- Programmer: ulneiz
--
-- Description: This double function allows copying or pasting the slice markers of the first sample between instruments.
--              Remember that it is necessary to always work on the first sample! If you copy more slice markers
--              than those allowed by the target sample, they will only be pasted until the last allowed marker.
--
--              Access: "Sample Editor/Slices/~Copy Markers... (or ~Paste Markers)".
--
-- Update History:
-- v1.1
-- *Small code bug fixed and the logo reviewed.
--
-- v1.0
-- *First Release
--



--main locals
local tool_name="Slice Importer"
local rna=renoise.app()
local SLC_MAIN_TBL={}



--copy slice markers
local function slc_copy_slice_table()
  local song=renoise.song()
  if (song.selected_sample_index==1) then
    local smp=song.selected_sample
    local max=#smp.slice_markers
    --clear first the table
    table.clear(SLC_MAIN_TBL)
    --rearm the table
    for slc_pos=1,max do
      SLC_MAIN_TBL[slc_pos]=smp.slice_markers[slc_pos]
    end
    --print("copy: ------------------------------")
    --rprint(SLC_MAIN_TBL)
    if (max==0) then
      rna:show_status(("%s:  This sample does not contain slice markers!"):format(tool_name))
    else
      rna:show_status(("%s:  %.2d slice markers have been copied, up to the marker %.2X."):format(tool_name,max,max))
    end
  else
    rna:show_status(("%s:  This sample can not contain slice markers. Select the first sample!"):format(tool_name))
  end
end



--paste slice markers
local function slc_paste_slice_table()
  local song=renoise.song()
  if (#SLC_MAIN_TBL==0) then
    rna:show_status(("%s:  There are no slice markers copied. Copy a slice marker first!"):format(tool_name))
  else
    if (song.selected_sample_index==1) then
      local function paste()
        local smp=song.selected_sample
        local max=smp.sample_buffer.number_of_frames
        local last_pos=0
        for slc_pos=1,#SLC_MAIN_TBL do
          if (SLC_MAIN_TBL[slc_pos]<=max) then
            smp:insert_slice_marker(SLC_MAIN_TBL[slc_pos])
            last_pos=slc_pos
          end
        end
        --print("paste: ------------------------------")
        --rprint(smp.slice_markers)
        if (last_pos==0) then
          rna:show_status(("%s:  neither slice markers have been pasted. The sample does not have enough duration!"):format(tool_name))
        else
          rna:show_status(("%s:  %.2d slice markers have been pasted, up to the marker %.2X."):format(tool_name,last_pos,last_pos))
        end
      end
      if (#song.selected_instrument.samples>=2) then
        local message="This will delete all sample slots apart from this one. Click \"Ok\" if you want to go ahead and create a slice sample."
        local my_prompt=rna:show_prompt(("%s: clear Samples?"):format(tool_name),message,{"Ok","Cancel"})
        if (my_prompt=="Cancel") then
          return
        elseif (my_prompt=="Ok") then
          paste()
        end
      else
        paste()
      end
    else
      rna:show_status(("%s:  This sample can not contain slice markers. Select the first sample!"):format(tool_name))
    end
  end
end



--menu entry
renoise.tool():add_menu_entry{
  name=(("Sample Editor:Slices:Copy Markers (%s)"):format(tool_name)),
  invoke=function() slc_copy_slice_table() end
}
renoise.tool():add_menu_entry{
  name=(("Sample Editor:Slices:Paste Markers (%s)"):format(tool_name)),
  invoke=function() slc_paste_slice_table() end
}
