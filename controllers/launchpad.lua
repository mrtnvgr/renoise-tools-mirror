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

  -- Compute certain button-indices
  self.bt_effect_increase = self:CellId(9,1)
  self.bt_effect_decrease = self:CellId(9,2)
  self.bt_effect_toggle = self:CellId(9,3)
  self.bt_effect_type = self:CellId(9,4)
  self.bt_channel_jam = self:CellId(9,5)
  self.bt_channel_mute = self:CellId(9,6)
  self.bt_channel_basskill = self:CellId(9,7)
  self.bt_channel_cue = self:CellId(9,8)
  
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

        -- increase fx amount
        if midi_message[3] ~= 0 then
          cm:IncreaseEffectRate()
          self:LedOrange(self.bt_effect_increase)
          self:UpdateFXRateDecrease()
        else
          self:UpdateFXRateIncrease()
        end

      elseif row == 2 then

        -- decrease fx amount
        if midi_message[3] ~= 0 then
          cm:DecreaseEffectRate()
          self:LedOrange(self.bt_effect_decrease)
          self:UpdateFXRateIncrease()
        else
          self:UpdateFXRateDecrease()
        end

      elseif row == 3 then

        -- when pressed, toggle effect state
        if midi_message[3] ~= 0 then
          cm:ToggleEffectState()
        end

      elseif row == 4 then

        -- when pressed, cycle through effects...
        if midi_message[3] ~= 0 then
          local fx_type = cm:GetEffectType()
          if (fx_type==CELLS_FX_FILTER) then
            fx_type = CELLS_FX_REPEAT
          elseif (fx_type==CELLS_FX_REPEAT) then
            fx_type = CELLS_FX_DELAY
          elseif (fx_type==CELLS_FX_DELAY) then
            fx_type = CELLS_FX_FLANGER
          elseif (fx_type==CELLS_FX_FLANGER) then
            fx_type = CELLS_FX_FILTER
          end
          cm:MoveEffectType(fx_type)
          
        end

      elseif row == 5 then
        -- Current channel jam toggle (green = enabled, red = off, off = not possible)
        if cc[self.current_channel] then
          cc[self.current_channel]:ToggleLiveJamMode()
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
  --cc[1]:SelectTrack()               mxb: commented out for beta3
  
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
      self:LedRed(self.bt_channel_mute)
    else
      self:LedGreen(self.bt_channel_mute)
    end
  end
end


function ControllerLaunchpad:SetSelected(channel)
  --print("ControllerLaunchpad:SetSelected()",channel)
  -- cache locally and compare with basskill/cue etc

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
      self:LedGreen(self.bt_channel_basskill)
    else
      self:LedOff(self.bt_channel_basskill)
    end
  end
end


function ControllerLaunchpad:SetCue(channel, state)
  --print("ControllerLaunchpad:SetCue()",channel, state)
  -- update cue led if current channel
  if channel == self.current_channel then
    if state then
      self:LedGreen(self.bt_channel_cue)
    else
      self:LedOff(self.bt_channel_cue)
    end
  end
end


function ControllerLaunchpad:SetJam(channel, state)
  --print("ControllerLaunchpad:SetJam()",channel, state)
  -- update jam led if current channel

  if cc[channel] then
    if cc[channel]:CanLiveJamMode() then
      if state then
        self:LedGreen(self.bt_channel_jam)
      else
        self:LedRed(self.bt_channel_jam)
      end
    else
      self:LedOff(self.bt_channel_jam)
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

  --[[
  local row = (ab == 0) and 3 or 4    -- mxb: crazy cool! but could we
                                      --      switch on ab and precalculate
                                      --      rather than call CellId?

  if state then
    self:LedGreen(self:CellId(9, row))
  else
    self:LedOff(self:CellId(9, row))
  end
  ]]

end


function ControllerLaunchpad:SetFXRate(rate)
  -- no feedback possible
end

function ControllerLaunchpad:SetFXAmount(amount)
  -- no feedback possible
end


function ControllerLaunchpad:SetFXType(type_id)
  --print("ControllerLaunchpad:SetFXType()",type_id)

  -- SetFXState will light up the button...
  --local fx_state = cm:GetEffectState()
  --self:SetFXState(fx_state)
  if (type_id==CELLS_FX_FILTER) then
    self:LedRed(self.bt_effect_type)
  elseif (type_id==CELLS_FX_REPEAT) then
    self:LedYellow(self.bt_effect_type)
  elseif (type_id==CELLS_FX_DELAY) then
    self:LedGreen(self.bt_effect_type)
  elseif (type_id==CELLS_FX_FLANGER) then
    self:LedOrange(self.bt_effect_type)
  end

end

function ControllerLaunchpad:SetFXTarget(type_id)
  -- 1 = A, 2 = M, 3 = B
  -- no feedback possible
end

function ControllerLaunchpad:SetFXState(state)
  --print("ControllerLaunchpad:SetFXState()",state)

  if state then
    self:LedGreen(self.bt_effect_toggle)
  else
    self:LedOff(self.bt_effect_toggle)
    --self:LedOff(self.bt_effect_type)
  end

  --self:SetFXType(cm:GetEffectType())

end


function ControllerLaunchpad:SetPlayState(state)
  -- no feedback possible
end

function ControllerLaunchpad:SetMasterVolume(value)
  -- no feedback possible
end

function ControllerLaunchpad:SetCueVolume(value)
  -- no feedback possible
end



--------------------------------------------------------------------------------
-- Class Support Functions
--------------------------------------------------------------------------------
function ControllerLaunchpad:UpdateChannelLeds(channel)
  --print("ControllerLaunchpad:UpdateChannelLeds()",channel)
  -- Update status led down right hand side

  -- effect rate inc/decrease
  self:UpdateFXRateIncrease()
  self:UpdateFXRateDecrease()

  -- effect select & toggle
  local fx_type = cm:GetEffectType()
  self:SetFXType(fx_type)

  if cc[channel] then
    self:SetJam(channel,cc[channel]:GetLiveJamMode())
    self:SetMute(channel,cc[channel]:GetMute())
    self:SetBasskill(channel,cc[channel]:GetBassKill())
    self:SetCue(channel,cc[channel]:GetCue())
  end
end

-- BNN: added this method
function ControllerLaunchpad:UpdateFXRateIncrease()

  local fx_rate = cm:GetEffectRate()
  if (fx_rate<1) then
    self:LedOrangeDimmed(self.bt_effect_increase)
  else
    self:LedOff(self.bt_effect_increase)
  end

end

-- BNN: added this method
function ControllerLaunchpad:UpdateFXRateDecrease()

  local fx_rate = cm:GetEffectRate()
  if (fx_rate>0) then
    self:LedOrangeDimmed(self.bt_effect_decrease)
  else
    self:LedOff(self.bt_effect_decrease)
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

function ControllerLaunchpad:LedOrange(led_number)
  -- enable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x2f})
end

function ControllerLaunchpad:LedOrangeDimmed(led_number)
  -- enable an LED on the controller 
  self:SendMidi({0x90, led_number, 0x1e})
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
cf:Register("Launchpad", ControllerLaunchpad)

