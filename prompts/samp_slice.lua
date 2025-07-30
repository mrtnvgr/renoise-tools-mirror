--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Sample Slice Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'SampSlicePrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SampSlicePrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_SAMP_SLICE
  
  self.mode = 1
  self.marker = 0
  
  -- display init
  set_lcd("   ")
  
  local samp = renoise.song().selected_sample
  local nf = samp.sample_buffer.number_of_frames
  local sstart = 1
  local ssend = samp.sample_buffer.number_of_frames
  
  if #samp.slice_markers > 0 then
    self.marker = 1
  end
  
  self:select_slice()
  samp.sample_buffer.display_range = {1, nf}

end



--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
function SampSlicePrompt:encoder(delta)
  -- move
  local samp = renoise.song().selected_sample
  local sb = samp.sample_buffer
  
  if sb.has_sample_data then
    if self.mode == 1 then
      -- move selection end / next marker
      local dr = sb.display_range
      local sr = sb.selection_range
      local step = (dr[2]-dr[1])/512
      sb.selection_range = {sr[1], clamp(sr[2]+(delta*step), dr[1], dr[2])}

      if #samp.slice_markers > self.marker then
        samp:move_slice_marker(samp.slice_markers[self.marker+1], sb.selection_range[2])
      end
    elseif self.mode == 2 then
      -- select marker
      if #samp.slice_markers == 0 then
        return
      end
      self.marker = clamp(self.marker + delta, 1, #samp.slice_markers)
      self:select_slice()               
    end
  end
end


function SampSlicePrompt:func_x()
  -- add marker
  local samp = renoise.song().selected_sample
  local frame = samp.sample_buffer.selection_range[1]
  samp:insert_slice_marker(frame+1)
  
  for i = 1, #samp.slice_markers do
    if samp.slice_markers[i] == frame then
      self.marker = i
    end
  end
  
  self:select_slice()
end


function SampSlicePrompt:func_y()
  -- delete
  local samp = renoise.song().selected_sample
  local frame = samp.sample_buffer.selection_range[1]
  samp:delete_slice_marker(frame)
  
  for i = 1, #samp.slice_markers do
    if samp.slice_markers[i] == frame then
      self.marker = i
    end
  end
  
  self:select_slice()
end


function SampSlicePrompt:func_z()
  -- toggle mode
  if self.mode == 1 then
    self.mode = 2
    set_led(LED_PEDAL, LED_ON)
  elseif self.mode == 2 then
    self.mode = 1
    set_led(LED_PEDAL, LED_OFF)
  end
end



function SampSlicePrompt:select_slice()
  local samp = renoise.song().selected_sample
  local sb = samp.sample_buffer
  local sstart = 1
  local ssend = sb.number_of_frames
  if #samp.slice_markers >= self.marker then
    sstart = samp.slice_markers[self.marker]
    if #samp.slice_markers > self.marker then
      ssend = samp.slice_markers[self.marker+1]
    end
  end
  sb.selection_range = {clamp(sstart, 1, sb.number_of_frames),
                        clamp(ssend, 1, sb.number_of_frames)}
end
