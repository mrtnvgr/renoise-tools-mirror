--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sample Record Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampRecPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampRecPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_REC
  
  -- display init
  set_lcd('rec')
  
  renoise.app().window.sample_record_dialog_is_visible = true
end


function SampRecPrompt:ok()
  renoise.app().window.sample_record_dialog_is_visible = false
  BasePrompt.ok(self)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampRecPrompt:encoder(delta)
  -- n/a
end


function SampRecPrompt:func_x()
  renoise.song().transport:start_stop_sample_recording()
end


function SampRecPrompt:func_y()
  renoise.song().transport:cancel_sample_recording()
end


function SampRecPrompt:func_z()
  -- n/a
end
