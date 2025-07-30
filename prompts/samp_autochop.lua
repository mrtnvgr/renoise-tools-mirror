--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sample Autochop Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampAutoChopPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampAutoChopPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_AUTOCHOP
  
  -- display init
  self.slices = renoise.song().selected_sample.beat_sync_lines /
                renoise.song().transport.lpb

  set_lcd(string.format("%03d", self.slices))
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampAutoChopPrompt:encoder(delta)
  -- change slice count
  self.slices = clamp(self.slices + delta, 0, 64)
  set_lcd(string.format("%03d", self.slices))
end


function SampAutoChopPrompt:func_x()
  -- do it
  local samp = renoise.song().selected_sample
  local nf = samp.sample_buffer.number_of_frames
  
  
  if #samp.slice_markers > 0 then
    for i = #samp.slice_markers, 1, -1 do
      samp:delete_slice_marker(samp.slice_markers[i])
    end
  end
  
  if self.slices == 0 then
    return
  end
  
  local step = nf / self.slices
  
  for i = 0, self.slices - 1 do
    samp:insert_slice_marker(clamp(i * step, 1, nf))
  end
end


function SampAutoChopPrompt:func_y()
  -- n/a
end


function SampAutoChopPrompt:func_z()
  -- n/a
end
