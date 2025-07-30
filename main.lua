-- Tool name: Paste Sample Selection or PSS
-- Version: 1.0 build 002
-- Code Type: LUA 5.1 + API 6.1 (Renoise 3.4.2)
-- Compatibility: Renoise v3.4.2 (tested under Windows 10/11)
-- Publication Date: October 2023
-- Development Time: October 2023
-- Licence: Free
-- Distribution: Full version
-- Programmer: ulneiz (Spain)
-- Contact Author: Go to https://forum.renoise.com/ & search "ulneiz" user (to contact you must be registered)



--- ---global variables--- ---
local PSS={
  VERSION="1.0",
  BUILD="build 002",
  MAIN_TITLE="Paste Sample Selection",
  SHORT_TITLE="PSS",
}
local pss={
  rna=renoise.app(),
  rnt=renoise.tool()
}

--- ---redefine renoise.song--- ---
pss.sng=function()
  pss.song=renoise.song()
end
pss.rnt.app_new_document_observable:add_notifier(pss.sng)
pcall(pss.sng)




--- ---functions--- ---
local pss_fun={}

--clone selection after end
pss_fun.clone_selection_after_end=function()
  local sam=pss.song.selected_sample
  --check if sample editor is in the foreground
  if (pss.rna.window.active_middle_frame~=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR) then
    pss.rna.window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  end    
  --check if exist sample
  if (sam) then
    --chec if exist sample buffer
    local buf=sam.sample_buffer
    if (buf) then
      --oprint(buf)
      --check if sample buffer has sample data
      if (buf.has_sample_data) then
        local sample_rate,bit_depth,num_channels,num_frames=buf.sample_rate,buf.bit_depth,buf.number_of_channels,buf.number_of_frames
        local sel_start,sel_end=buf.selection_start,buf.selection_end
        local all_frames=sel_end-sel_start+1
        local SAMPLE_DATA_L,SAMPLE_DATA_R={},{}
        --save buffer channels inside tables
        local buf_sdt=buf.sample_data
        if (num_channels==1) then
          for s=1,num_frames do
            SAMPLE_DATA_L[s]=buf_sdt(buf,1,s)
          end
        elseif (num_channels==2) then
          for s=1,num_frames do
            SAMPLE_DATA_L[s]=buf_sdt(buf,1,s)
            SAMPLE_DATA_R[s]=buf_sdt(buf,2,s)
          end
        end
        --create equal & empty buffer with new frames
        buf:create_sample_data(sample_rate,bit_depth,num_channels,num_frames+all_frames)
        --modify buffer data
        --- ---
        buf:prepare_sample_data_changes()
        --restore all old buffer
        local buf_ssd=buf.set_sample_data
        if (num_channels==1) then
          for s=1,num_frames do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
          end
        elseif (num_channels==2) then
          for s=1,num_frames do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
            buf_ssd(buf,2,s,SAMPLE_DATA_R[s])
          end
        end
        --copy new buffer selection at the end
        local n=-num_frames-1+sel_start
        if (num_channels==1) then
          for s=num_frames+1,num_frames+all_frames do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s+n])
          end
        elseif (num_channels==2) then
          for s=num_frames+1,num_frames+all_frames do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s+n])
            buf_ssd(buf,2,s,SAMPLE_DATA_R[s+n])
          end
        end
        buf:finalize_sample_data_changes()
        --- ---
        --restore selection from end
        buf.selection_start=num_frames+1
        buf.selection_end=num_frames+all_frames --buf.number_of_frames
        local message=("%s → Cloned selection after end."):format(PSS.MAIN_TITLE)
        pss.rna:show_status(message)
      end
    end
  end
end



--clone selection continuously after selection
pss_fun.clone_selection_continuously=function()
  local sam=pss.song.selected_sample
  --check if sample editor is in the foreground
  if (pss.rna.window.active_middle_frame~=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR) then
    pss.rna.window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  end
  --check if exist sample
  if (sam) then
    --chec if exist sample buffer
    local buf=sam.sample_buffer
    if (buf) then
      --oprint(buf)
      --check if sample buffer has sample data
      if (buf.has_sample_data) then
        local sample_rate,bit_depth,num_channels,num_frames=buf.sample_rate,buf.bit_depth,buf.number_of_channels,buf.number_of_frames
        local sel_start,sel_end=buf.selection_start,buf.selection_end
        local all_frames=sel_end-sel_start+1
        local SAMPLE_DATA_L,SAMPLE_DATA_R={},{}
        --save buffer channels inside tables
        local buf_sdt=buf.sample_data
        if (num_channels==1) then
          for s=1,num_frames do
            SAMPLE_DATA_L[s]=buf_sdt(buf,1,s)
          end
        elseif (num_channels==2) then
          for s=1,num_frames do
            SAMPLE_DATA_L[s]=buf_sdt(buf,1,s)
            SAMPLE_DATA_R[s]=buf_sdt(buf,2,s)
          end
        end
        --create equal & empty buffer with new frames
        buf:create_sample_data(sample_rate,bit_depth,num_channels,num_frames+all_frames)
        --modify buffer data
        --- ---
        buf:prepare_sample_data_changes()
        --restore all old buffer
        local buf_ssd=buf.set_sample_data
        if (sel_start>1) then
          if (num_channels==1) then
            for s=1,sel_start-1 do
              buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
            end
          elseif (num_channels==2) then
            for s=1,sel_start do
              buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
              buf_ssd(buf,2,s,SAMPLE_DATA_R[s])
            end
          end
        end
        if (num_channels==1) then
          for s=sel_start,num_frames do
            buf_ssd(buf,1,s+all_frames,SAMPLE_DATA_L[s])
          end
        elseif (num_channels==2) then
          for s=sel_start,num_frames do
            buf_ssd(buf,1,s+all_frames,SAMPLE_DATA_L[s])
            buf_ssd(buf,2,s+all_frames,SAMPLE_DATA_R[s])
          end
        end
        --copy new buffer selection before selection
        if (num_channels==1) then
          for s=sel_start,sel_end do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
          end
        elseif (num_channels==2) then
          for s=sel_start,sel_end do
            buf_ssd(buf,1,s,SAMPLE_DATA_L[s])
            buf_ssd(buf,2,s,SAMPLE_DATA_R[s])
          end
        end
        buf:finalize_sample_data_changes()
        --- ---
        --restore selection from end
        buf.selection_start=sel_end+1
        buf.selection_end=sel_end+all_frames --buf.number_of_frames
        local message=("%s → Cloned selection continuously."):format(PSS.MAIN_TITLE)
        pss.rna:show_status(message)
      end
    end
  end
end



--paste selection continuously after selection
pss_fun.paste_selection_continuously=function()
  local sam=pss.song.selected_sample
  --check if sample editor is in the foreground
  if (pss.rna.window.active_middle_frame~=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR) then
    pss.rna.window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  end
  --check if exist sample
  if (sam) then
    --chec if exist sample buffer
    local buf=sam.sample_buffer
    if (buf) then
      --oprint(buf)
      --check if sample buffer has sample data
      if (buf.has_sample_data) then
        local buf_sdt=buf.sample_data
        local num_channels,num_frames=buf.number_of_channels,buf.number_of_frames
        local sel_start,sel_end=buf.selection_start,buf.selection_end
        local all_frames=sel_end-sel_start+1
        --modify buffer data
        --- ---
        if (sel_end+all_frames<=num_frames) then
          buf:prepare_sample_data_changes()
          --paste overlapping the selection
          local buf_ssd=buf.set_sample_data
          if (num_channels==1) then
            for s=sel_end+1,sel_end+all_frames do
              buf_ssd(buf,1,s,buf_sdt(buf,1,s-all_frames))
            end
          elseif (num_channels==2) then
            for s=sel_end+1,sel_end+all_frames do
              buf_ssd(buf,1,s,buf_sdt(buf,1,s-all_frames))
              buf_ssd(buf,2,s,buf_sdt(buf,2,s-all_frames))
            end
          end
          buf:finalize_sample_data_changes()
          --- ---
          --restore selection from end
          buf.selection_start=sel_end+1
          buf.selection_end=sel_end+all_frames --buf.number_of_frames
          local message=("%s → Pasted selection continuously."):format(PSS.MAIN_TITLE)
          pss.rna:show_status(message)
        else
          return --nothing
        end
      end
    end
  end
end



--- ---keybinding--- ---
local PSS_KEYBINDING={
  NAME_1=("Global:Tools:%s → Clone Sample Selection After End"):format(PSS.SHORT_TITLE),
  NAME_2=("Global:Tools:%s → Clone Sample Selection Continuously"):format(PSS.SHORT_TITLE),
  NAME_3=("Global:Tools:%s → Paste Sample Selection Continuously"):format(PSS.SHORT_TITLE),
  FUNC_1=function() pss_fun.clone_selection_after_end() end,
  FUNC_2=function() pss_fun.clone_selection_continuously() end,
  FUNC_3=function() pss_fun.paste_selection_continuously() end
}

pss_fun.add_keybinding=function(k_1,k_2)
  for k=k_1,k_2 do
    --print("k",k)
    if not pss.rnt:has_keybinding(PSS_KEYBINDING["NAME_"..k]) then
      pss.rnt:add_keybinding{ name=PSS_KEYBINDING["NAME_"..k], invoke=PSS_KEYBINDING["FUNC_"..k] }
    end
  end
end
pss_fun.add_keybinding(1,3)
