--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- File operations interface support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function attach_tool_hooks()
  -- Attach general tool hooks
  if renoise.tool().app_new_document_observable:has_notifier(new_file_hook) == false then
    renoise.tool().app_new_document_observable:add_notifier(new_file_hook)
  end
  if renoise.tool().app_release_document_observable:has_notifier(close_file_hook) == false then
    renoise.tool().app_release_document_observable:add_notifier(close_file_hook)
  end
end


--------------------------------------------------------------------------------
-- Hook Functions
--------------------------------------------------------------------------------
function new_file_hook()
  -- Called when changing the song
  if connected == true then
    if current_mode == MODE_MIX then
      mix_init()
    elseif current_mode == MODE_EDIT then
      edit_init()
    elseif current_mode == MODE_DSP then
      dsp_init()
    elseif current_mode == MODE_VST then
      return -- do nothing
    elseif current_mode == MODE_INST then
      return -- do nothing
    end
  end
end


function close_file_hook()
  -- Called on closing a file
  if connected == true then
    clear_display()
    all_leds_off()
    move_fader_to(0)
  end
end
