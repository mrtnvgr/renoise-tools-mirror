--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Common mode support
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
MODE_PATT = 1
MODE_SONG = 2
MODE_INST = 3
MODE_SAMP = 4
MODE_WAIT = 5


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function center_frame_change()
  -- todo: renoise bug?
  local mf = renoise.app().window.active_middle_frame
  
  print(mf)
  
  if mf == renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR then
    -- patt mode
    set_mode(MODE_PATT)
    
  elseif mf == renoise.ApplicationWindow.MIDDLE_FRAME_MIXER then
    -- song mode
    set_mode(MODE_SONG)
  
  elseif mf == renoise.ApplicationWindow.MIDDLE_FRAME_KEYZONE_EDITOR then
    -- inst mode
    set_mode(MODE_INST)
    
  elseif mf == renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR then
    -- samp mode
    set_mode(MODE_SAMP)
  end
end


function song_close_hook()
  stop_pking()
end

  
function song_open_hook()
  start_pking()
end


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function set_mode(mode_id)
  -- clear existing
  if prompt then
    prompt:ok()
  end
  if mode then
    mode:exit()
  end
  
  -- start new mode
  if mode_id == MODE_PATT then
    mode = PattEditMode()
  elseif mode_id == MODE_SONG then
    mode = SongEditMode()
  elseif mode_id == MODE_INST then
    mode = InstEditMode()
  elseif mode_id == MODE_SAMP then
    -- todo
    mode = SampEditMode()
  elseif mode_id == MODE_WAIT then
    mode = WaitingMode()
  end
end



function attach_common_mode_hooks()
  --[[
  if not renoise.app().window.active_middle_frame_observable:has_notifier(center_frame_change) then
    renoise.app().window.active_middle_frame_observable:add_notifier(center_frame_change)
  end
  ]]--
  if not renoise.tool().app_release_document_observable:has_notifier(song_close_hook) then
    renoise.tool().app_release_document_observable:add_notifier(song_close_hook)
  end
  if not renoise.tool().app_new_document_observable:has_notifier(song_open_hook) then
    renoise.tool().app_new_document_observable:add_notifier(song_open_hook)
  end
end


