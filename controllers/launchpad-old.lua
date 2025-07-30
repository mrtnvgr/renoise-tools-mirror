--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2011 Martin Bealby
--
-- Novation Launchpad Controller Class [in progress]
--------------------------------------------------------------------------------


-- !!!! THIS IS A WORK IN PROGRESS !!!!

--[[

  mxb: Updated with Beta 2 to new API.
       Commented out print statements this thing (oops!)
       I've also precalculated some CellId values for things that never change
]]--



--------------------------------------------------------------------------------
-- Description
--------------------------------------------------------------------------------
--[[
This is native controller support for the Novation Launchpad controller.
For this to work, Automap must be disabled.

Many thanks to 'danoise' for assisting with the development of this code.

The controller works as follows:

  - The 8x8 main grid triggers the first eight cells in the first eight channels
    - An unilluminated grid cell is an invalid cell
    - A red grid cell is a valid cell
    - A yellow grid cell is cued to play
    - A green grid cell is playing
    - The bottom row of cells is always stop
  - The top row of circular buttons selects the current channel (channel 1-8)
  - The buttons down the right are the following (in order:
    - Set FX to repeat and toggle on/off
    - Set FX to delay and toggle on/off
    - Cut group A (non-latching)
    - Cut group B (non-latching)
    - Current channel jam toggle (green = enabled, red = off, off = not possible)
    - Current channel mute toggle (green = playing, red = muted)
    - Current channel bass kill toggle (green = bass killed, off = normal)
    - Current channel cue toggle       (green = cue enabled, off = cue disabled)
]]--

-- BNN: added these constants
local CELL_STATE_INVALID = 1
local CELL_STATE_VALID = 2
local CELL_STATE_PLAYING = 3
local CELL_STATE_CUED = 4

--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "ControllerLaunchpad"

--[[
Variables:
  self.midi_in_device
  self.midi_out_device
  self.physical_channel_count
  self.physical_cells_per_channel_count
  
Device Specific Variables/Functions:
  self.current_channel
  self:CellId(x, y)
  self:CellXy(id)
  self:UpdateChannelLeds(channel_index)
  self:LedRed(led_number)
  self:LedYellow(led_number)
  self:LedGreen(led_number)
  self:LedOff(led_number)
]]--


function ControllerLaunchpad:__init(midi_in, midi_out)
  -- Initialise the controller and bind to Renoise
  
  -- Check for valid ports
  if table.find(renoise.Midi.available_output_devices(), midi_out) then
    if table.find(renoise.Midi.available_input_devices(), midi_in) then
      -- Seems ok attach to ports
           
      self.midi_in_device = renoise.Midi.create_input_device(
        midi_in,
        {self, self.MidiHandler},
        {self, self.SysexHandler})
        
      self.midi_out_device = renoise.Midi.create_output_device(midi_out)
    end
  end
  
  -- reassign channels 1-8 to A
  --[[
  if #cc < 16 then
    set_ab_equally(16)
  end
  ]]
  
  -- Reset
  self:Reset()
  
end


function ControllerLaunchpad:MidiHandler(midi_message)
  -- Controller specific midi handler 
  
  -- Do nothing unless Cells! is visible and running
  if (not cells_running) then
    return
  end
  
  if midi_message[1] == 0x90 then
    -- buttons
    
    local xy = self:CellXy(midi_message[2])
    local row = xy[1]
    local channel = xy[2]
    --print("channel",channel)
    --print("row",row)
    --print("midi_message[3]",midi_message[3])
    --print("cc[self.current_channel]",cc[self.current_channel])
    if channel == 9 then
      -- right side buttons
      if row == 1 then
        -- BNN added: Set FX to repeat and toggle on/off
        if midi_message[3] ~= 0 then
        
          
          --[[
          local fx_idx = 2
          local active = (cm.track_fx.devices[2].parameters[1].value ~= 0) -- need proper method for this, e.g. EffectIsActive
          cm:MoveEffectType((fx_idx-1)/3.9) -- ??
          cm:ToggleEffectState(fx_idx,not active)
          ]]--
          
          -- mxb: updated for 1.2 api:
          
          cm:MoveEffectType(CELLS_FX_REPEAT)
          
          if not cm:GetEffectState() then
            cm:ToggleEffectState()
          end
            
        end

      elseif row == 2 then
        -- BNN added: Set FX to delay and toggle on/off
        if midi_message[3] ~= 0 then
          --[[
          local fx_idx = 3
          local active = cm.track_fx.devices[5].is_active  -- need proper method for this
          cm:MoveEffectType((fx_idx-1)/3.9) -- ??
          cm:ToggleEffectState(fx_idx,not active)
          ]]--
          
          -- mxb: updated for 1.2 api:
          
          cm:MoveEffectType(CELLS_FX_DELAY)
          
          if not cm:GetEffectState() then
            cm:ToggleEffectState()
          end
        end
            
      elseif row == 3 then
        -- Cut group A (non-latching)
        --local state = (midi_message[3]~=0)   mxb:moved inline to avoid creating new references for GC
        cm:SetCutState(0, midi_message[3]~=0)

      elseif row == 4 then
        -- Cut group B (non-latching)
        --local state = (midi_message[3]~=0)   mxb:moved inline to avoid creating new references for GC
        cm:SetCutState(1, midi_message[3]~=0)
   
      elseif row == 5 then
        -- Current channel jam toggle (green = enabled, red = off, off = not possible)
        if midi_message[3] ~= 0 then
          if cc[self.current_channel] then        -- mxb: added safety check for cc[]
            cc[self.current_channel]:ToggleLiveJamMode()
          end
        end
        
      elseif row == 6 then
        -- Current channel mute toggle (green = playing, red = muted)
        if midi_message[3] ~= 0 then
          -- pressed
          if cc[self.current_channel] then
            cc[self.current_channel]:ToggleMute()
          end
        end 

      elseif row == 7 then
        -- Current channel bass kill toggle
        if midi_message[3] ~= 0 then
          -- pressed
          if cc[self.current_channel] then
            cc[self.current_channel]:ToggleBassKill()
          end
        end

      elseif row == 8 then
        -- Current channel cue toggle
        if midi_message[3] ~= 0 then
          -- pressed
          if cc[self.current_channel] then
            cc[self.current_channel]:ToggleCue()
          end
        end         
      end  
      
      -- handled, exit here
      return
    end
      
    -- channel ok?
    if channel > preferences.channel_count.value then
      return
    end
        
      -- cell?
    if midi_message[3] ~= 0 then
      -- pressed, not released
    
      if row ~= 8 then
        if row > preferences.cells_count.value then
          -- do nothing
        else
          -- valid cell
          if cc[channel] then
            cc[channel]:CueCell(row)
          end
        end
      elseif row == 8 then
        -- bottom row = stop
        if cc[channel] then
          cc[channel]:CueStop()
        end
      end 
    end
    
  elseif midi_message[1] == 0xB0 then
    -- cc channel 1
    
    if midi_message[2] > 103 then
      if midi_message[3] < 112 then
        -- acceptable range, select channel if available
        local channel = midi_message[2] - 103
        if cc[channel] then
          cc[channel]:SelectTrack()
          self:SetSelected(channel,true)
        end
      end
    end
  end
end


function ControllerLaunchpad:SysexHandler(midi_message)
  -- no actions to handle, yay!
end


function ControllerLaunchpad:Reset()
  -- Reset to the defaults to match the gui on startup

  -- cell state buttons
  for x = 1, 8 do
    for y = 1, 7 do
      self:LedOff(self:CellId(x,y))
    end
    self:LedRed(self:CellId(x,8))
  end
  
  -- Force current channel to Cells! channel 1
  cc[1]:SelectTrack()
  
  -- Set channel selection lights
  self:CcGreen(104)
  self:CcOff(105)
  self:CcOff(106)
  self:CcOff(107)
  self:CcOff(108)
  self:CcOff(109)
  self:CcOff(110)
  self:CcOff(11)
  
  -- Repeat rate = 1/8, repeat off
  self:LedOff(self:CellId(9, 1))
  self:LedOff(self:CellId(9, 2))
  self:LedOff(self:CellId(9, 3))
  self:LedOff(self:CellId(9, 4))
  self:LedOff(self:CellId(9, 5))
  self:LedOff(self:CellId(9, 6))
  self:LedOff(self:CellId(9, 7))
  self:LedOff(self:CellId(9, 8))
   
  -- Update channel mode buttons
  self:UpdateChannelLeds(1)
end


function ControllerLaunchpad:Tick(line)
  -- no action
end


function ControllerLaunchpad:SetCellState(channel, cell, state)
  --print("ControllerLaunchpad:SetCellState()",channel, cell, state)
  -- Set a cells state

  -- restrict to 8x8 for now
  if channel > 8 then
    return 
  elseif cell > 7 then  -- row 8 = stop
    return 
  end
  
  local CellId = self:CellId(channel,cell)

  -- switch on cell states
  if state == CELL_STATE_INVALID then
    -- invalid cell
        
    -- turn off  
    self:LedOff(CellId)
    
  elseif state == CELL_STATE_VALID then
    -- valid cell
    
    -- turn on
    self:LedRed(CellId)
    
  elseif state == CELL_STATE_PLAYING then
    -- playing cell
    
    -- turn on
    self:LedGreen(CellId)
    
  elseif state == CELL_STATE_CUED then
    -- cued cell
       
    -- turn on
    self:LedYellow(CellId)
  end
end


function ControllerLaunchpad:SetStopState(channel, state)
  --print("ControllerLaunchpad:SetStopState()",channel, state)
  -- ignore channels > 8
  if channel > 8 then
    return
  end
  
  if state == CELL_STATE_VALID then
    -- default
    --self:LedOff(self:CellId(channel,8))
    self:LedRed(self:CellId(channel,8))
    
  else
    -- cued
    self:LedYellow(self:CellId(channel,8))
    
  end
end


function ControllerLaunchpad:SetMute(channel, state)
  --print("ControllerLaunchpad:SetMute()",channel, state)
  -- update mute led if current channel

  if channel == self.current_channel then
    if state then
      self:LedRed(self:CellId(9, 6))
    else
      self:LedGreen(self:CellId(9, 6))
    end
  end
end


function ControllerLaunchpad:SetSelected(channel)
  --print("ControllerLaunchpad:SetSelected()",channel, state)
  -- cache locally and compare with basskill/cue etc

  -- BNN note: checking for state will cause LEDs not
  -- to update when switching track from main UI
  
  -- mxb note: Agreed, second parameter (state) was removed
  --           Removed from below code

  --[[
  if channel < 9 then
    self.current_channel = channel
  end
  ]]--
  
  -- mxb: Flipped the above test to make it more reliable
  
  if channel > 8 then
    return    -- ignored
  end
  -- update cache
  self.current_channel = channel
    
  -- update channel selection leds
  for c = 104, 111 do
    self:CcOff(c)
  end
  self:CcGreen(103+channel)
    
  -- channel status leds
  self:UpdateChannelLeds(self.current_channel)
end


function ControllerLaunchpad:SetBasskill(channel, state)
  -- update basskill led if current channel
  if channel == self.current_channel then
    if state then
      self:LedGreen(self:CellId(9, 7))
    else
      self:LedOff(self:CellId(9, 7))
    end
  end
end


function ControllerLaunchpad:SetCue(channel, state)
  --print("ControllerLaunchpad:SetCellState()",channel, state)
  -- update cue led if current channel
  if channel == self.current_channel then
    if state then
      --self:LedGreen(self:CellId(9, 8))
      self:LedGreen(120)                    -- mxb: precalculated to 120
    else
      --self:LedOff(self:CellId(9, 8))
      self:LedOff(120)                      -- mxb: precalculated to 120
    end
  end
end


function ControllerLaunchpad:SetJam(channel, state)
  --print("ControllerLaunchpad:SetJam()",channel, state)
  -- update jam led if current channel

  --local cell = self:CellId(9,5)           -- mxb: precalculated to 72
  
  if cc[channel] then                       -- mxb: extra safety check
  
  --if (cc[channel].can_live_jam) then
    if cc[channel]:CanLiveJamMode() then    -- mxb: updated for 1.2 api
  
      --if (cc[channel].live_jam_mode) then
      if state then
        self:LedGreen(72)
      else
        self:LedRed(72)
      end
    else
      self:LedOff(72)
    end
  end
end


function ControllerLaunchpad:SetRouting(channel, routing)
  -- no feedback possible
end


function ControllerLaunchpad:SetFilter(channel, position)
  -- no feedback possible
end


function ControllerLaunchpad:SetTranspose(channel, position)
  -- no feedback possible
end


function ControllerLaunchpad:SetPanning(channel, position)
  -- no feedback possible
end


function ControllerLaunchpad:SetVolume(channel, position)
  -- no feedback possible
end


function ControllerLaunchpad:SetCrossfader(position)
  -- no feedback possible
end


function ControllerLaunchpad:SetCrossfaderCut(ab, state)
  --print("ControllerLaunchpad:SetCrossfaderCut()",ab, state)

  local row = (ab == 0) and 3 or 4    -- mxb: crazy cool! but could we
                                      --      switch on ab and precalculate
                                      --      rather than call CellId?

  if state then
    self:LedGreen(self:CellId(9, row))
  else
    self:LedOff(self:CellId(9, row))
  end
end


function ControllerLaunchpad:SetFXRate(rate)
  -- no feedback possible
end


function ControllerLaunchpad:SetFXAmount(amount)
  -- no feedback possible
end


function ControllerLaunchpad:SetFXType(type_id)
  --print("ControllerLaunchpad:SetFXType()",type_id)

  --self:LedOff(self:CellId(9,1))
  --self:LedOff(self:CellId(9,2))
  self:LedOff(8)                      -- mxb: precalculated values
  self:LedOff(24)

  -- SetFXState will light up the button...

end


function ControllerLaunchpad:SetFXState(state)
  --print("ControllerLaunchpad:SetFXState()",state)

  -- mxb: updated for new API, needs testing
  
  local type_id = cm:GetEffectType()

  if (type_id == CELLS_FX_REPEAT) then -- repeat
    if state then
      self:LedYellow(self:CellId(9,1))
    else
      self:LedOff(self:CellId(9,1))
    end
  elseif (type_id == CELLS_FX_DELAY) then -- delay
    if state then
      self:LedYellow(self:CellId(9,2))
    else
      self:LedOff(self:CellId(9,2))
    end
  end

end


function ControllerLaunchpad:SetMasterVolume(value)
  -- no feedback possible
end


function ControllerLaunchpad:SetCueVolume(value)
  -- no feedback possible
end

-- BNN: added this method
function ControllerLaunchpad:SetPlayState(state)
  -- no feedback possible
end


--------------------------------------------------------------------------------
-- Class Support Functions
--------------------------------------------------------------------------------
function ControllerLaunchpad:UpdateChannelLeds(channel)
  --print("ControllerLaunchpad:UpdateChannelLeds()",channel)
  -- Update status led down right hand side

  -- BNN added, the following needs proper inquery methods...
  -- mxb: done for beta 2
  
  if cc[channel] then                           -- mxb safety check
    
    self:SetJam(channel,cc[channel]:GetLiveJamMode())     --mxb updated
  
    --local muted = (cc[channel].track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE)
    
    self:SetMute(channel,cc[channel]:GetMute())
  
    --local bass_killed = cc[channel].track.devices[2].is_active
    self:SetBasskill(channel,cc[channel]:GetBassKill())
  
    --local cue_active = cc[channel].track.devices[4].is_active
    
    self:SetCue(channel,cc[channel]:GetCue())
  end
end

function ControllerLaunchpad:LedRed(led_number)
  -- enable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x0f})
end


function ControllerLaunchpad:LedYellow(led_number)
  -- enable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x3f})
end


function ControllerLaunchpad:LedGreen(led_number)
  -- enable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x3c})
end


function ControllerLaunchpad:LedOff(led_number)
  -- disable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x0c})
end


function ControllerLaunchpad:CcRed(cc_number)
  -- enable an LED on the controller 
  self:SendMidi({0xB0, cc_number, 0x0f})
end


function ControllerLaunchpad:CcYellow(cc_number)
  -- enable an LED on the controller 
  self:SendMidi({0xB0, cc_number, 0x3f})
end


function ControllerLaunchpad:CcGreen(cc_number)
  -- enable an LED on the controller 
  self:SendMidi({0xB0, cc_number, 0x3c})
end


function ControllerLaunchpad:CcOff(cc_number)
  -- disable an LED on the controller 
  self:SendMidi({0xB0, cc_number, 0x0c})
end


function ControllerLaunchpad:CellId(x, y)
  -- Returns the cell ID for the given x,y co-ordinate
  return (x-1)+(16*(y-1))
end


function ControllerLaunchpad:CellXy(id)
  -- Returns the cell {x,y} for the given cell ID
  return {math.floor(id/16)+1,  (id%16)+1}
end


function ControllerLaunchpad:SendMidi(msg)
  -- Check if device is connected before sending

  if self.midi_out_device then
    self.midi_out_device:send(msg)
  end

end



--------------------------------------------------------------------------------
-- Register Class
--------------------------------------------------------------------------------
cf:Register("Launchpad [beta]", ControllerLaunchpad)

