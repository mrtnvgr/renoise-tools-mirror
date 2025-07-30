--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Livid Instruments Ohm64 Controller Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Description
--------------------------------------------------------------------------------
--[[
This is native controller support for Livid Instrument's Ohm64 controller.

The controller works as follows:

  - The eight channel strips modify the first eight channels in Cells!
  - The main slider affects the channels volume
  - The rotary above the slider affects the channels filter, instrument selection,
    or transpose depending upon shift key states.
  - The button below the slider either toggles channel bass kill, channel cueing,
    channel jam mode or channel mute depending upon the shift key states
  - The crossfader affects the crossfader
  - The transform buttons adjacent to the crossfader are for non-latching
    crossfader cuts
  - The 8x8 main grid triggers the first eight cells in the first eight channels
    - An illuminated grid cell is a valid cell
    - An unilluminated grid cell is an invalid cell
    - A flashing cell is either playing or cued to play

]]--

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local OHM64_SHIFT_UNSHIFTED       = 1   -- bass kill / filter
local OHM64_SHIFT_INSTRUMENT_CUE  = 2
local OHM64_SHIFT_TRANSPOSE_JAM   = 3
local OHM64_SHIFT_OFF_MUTE    = 4
local OHM64_CHANNEL_BUTTONS = {65, 73, 66, 74, 67, 75, 68, 76}
local OHM64_CHANNEL_STOPS   = { 7, 15, 23, 31, 39, 47, 55, 63}


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "ControllerOhm64"

--[[
Variables:
  self.midi_in_device
  self.midi_out_device
  self.shift_state
  self.flash_list       -- list of button id's that need to flash
  self.mute_cache[]     -- array of 8 led states (bool)
  self.cue_cache[]      -- as above
  self.jam_cache[]      -- as above
  self.basskill_cache[] -- as above
  
Functions:
  SetLed(led_number, state)
  CellId(x, y)
  CellXY(id)
  ChannelButton(channel)
  UpdateChannelLeds()
]]--


function ControllerOhm64:__init(midi_in, midi_out)
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
  
  -- Reset to defaults
  self:Reset()
end


function ControllerOhm64:MidiHandler(midi_message)
  -- Controller specific midi handler
  
  -- do nothing if Cells! is not running
  if not cells_running then
    return
  end
  
  if midi_message[1] == 0x90 then
    -- Buttons
    
    --
    -- Cells
    --
    
    if midi_message[2] < 64 then
      -- cell pressed
      if midi_message[3] ~= 0 then
        local xy = self:CellXY(midi_message[2])  -- {channel, cell}
        
        -- track ok?
        if xy[1] > preferences.channel_count.value then
          return
        end
        
        -- stop cell (= 8)
        if xy[2] == 8 then
          cc[xy[1]]:CueStop()
          return
        end
        
        -- cell ok?
        if xy[2] > preferences.cells_count.value then
          return
        end
        
        -- cue cell
        cc[xy[1]]:CueCell(xy[2])
      end
    
    --
    -- Crossfader cut buttons
    --
    
    elseif midi_message[2] == 64 then
      -- crossfader transform left
      if midi_message[3] == 0 then
        -- released
        cm:SetCutState(0, false)
      else
        -- pressed
        cm:SetCutState(0, true)
      end
      
    elseif midi_message[2] == 72 then
      -- crossfader transform right
      if midi_message[3] == 0 then
        -- released
        cm:SetCutState(1, false)
      else
        -- pressed
        cm:SetCutState(1, true)
      end

    
    --
    -- channel buttons
    --
    
    elseif midi_message[2] == 65 then
      -- channel 1 button
      if cc[1] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[1]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[1]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[1]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[1]:ToggleMute()
          end
        end
      end
      
    elseif midi_message[2] == 73 then
      -- channel 2 button
      if cc[2] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[2]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[2]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[2]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[2]:ToggleMute()
          end
        end
      end
      
    elseif midi_message[2] == 66 then
      -- channel 3 button
      if cc[3] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[3]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[3]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[3]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[3]:ToggleMute()
          end
        end
      end
            
    elseif midi_message[2] == 74 then
      -- channel 4 button
      if cc[4] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[4]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[4]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[4]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[4]:ToggleMute()
          end
        end
      end
          
    elseif midi_message[2] == 67 then
      -- channel 5 button
      if cc[5] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[5]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[5]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[5]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[5]:ToggleMute()
          end
        end
      end
          
    elseif midi_message[2] == 75 then
      -- channel 6 button
      if cc[6] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[6]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[6]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[6]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[6]:ToggleMute()
          end
        end
      end
           
    elseif midi_message[2] == 68 then
      -- channel 7 button
      if cc[7] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[7]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[7]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[7]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[7]:ToggleMute()
          end
        end
      end
            
    elseif midi_message[2] == 76 then
      -- channel 8 button
      if cc[8] then
        if midi_message[3] ~= 0 then
          if self.shift_state == OHM64_SHIFT_UNSHIFTED then
            -- toggle channel bass kill
            cc[8]:ToggleBassKill()
            
          elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
            -- toggle channel cue
            cc[8]:ToggleCue()
            
          elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
            -- toggle channel jam
            cc[8]:ToggleLiveJamMode()
            
          elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
            -- toggle channel mute
            cc[8]:ToggleMute()
          end
        end
      end
          

      
    --
    --  Button array top right
    --

    elseif midi_message[2] == 87 then
      -- welder                           = start/stop
      if midi_message[3] ~= 0 then
        ct:TogglePlayState()
      end
      
    elseif midi_message[2] == 69 then
      -- top right array row 1, column 1  = FX toggle
      if midi_message[3] ~= 0 then
        cm:ToggleEffectState()
      end
        
    elseif midi_message[2] == 70 then
      -- top right array row 1, column 2  = BPM nudge down
      if midi_message[3] == 0 then
        -- released
        ct:NudgeBpm(-1, false)
      else
        -- pressed
        ct:NudgeBpm(-1, true)
      end
         
    elseif midi_message[2] == 71 then
      -- top right array row 1, column 3  = BPM nudge up
      if midi_message[3] == 0 then
        -- released
        ct:NudgeBpm(1, false)
      else
        -- pressed
        ct:NudgeBpm(1, true)
      end  
      
    elseif midi_message[2] == 77 then
      -- top right array row 2, column 1  = shift #1
      if midi_message[3] == 0 then
        -- released
        self.shift_state = OHM64_SHIFT_UNSHIFTED
      else
        -- pressed
        self.shift_state = OHM64_SHIFT_INSTRUMENT_CUE
      end
      self:UpdateChannelLeds()
      
    elseif midi_message[2] == 78 then
      -- top right array row 2, column 2  = shift #2
      if midi_message[3] == 0 then
        -- released
        self.shift_state = OHM64_SHIFT_UNSHIFTED
      else
        -- pressed
        self.shift_state = OHM64_SHIFT_TRANSPOSE_JAM
      end
      self:UpdateChannelLeds()
    
    elseif midi_message[2] == 79 then
      -- top right array row 2, column 3  = shift #3
      if midi_message[3] == 0 then
        -- released
        self.shift_state = OHM64_SHIFT_UNSHIFTED
      else
        -- pressed
        self.shift_state = OHM64_SHIFT_OFF_MUTE
      end
      self:UpdateChannelLeds()
    end


    
  elseif midi_message[1] == 0xB0 then
   
    local scaled_val = midi_message[3]/127
    
    --
    -- Faders
    --
    
    if midi_message[2] == 24 then
      -- crossfader
      cm:MoveCrossfader(1-scaled_val)
      
    elseif midi_message[2] == 23 then
      -- channel 1 fader
      if cc[1] then
        cc[1]:MoveVolume(scaled_val)
      end

    elseif midi_message[2] == 22 then
      -- channel 2 fader
      if cc[2] then
        cc[2]:MoveVolume(scaled_val)
      end
      
    elseif midi_message[2] == 15 then
      -- channel 3 fader
      if cc[3] then
        cc[3]:MoveVolume(scaled_val)
      end
            
    elseif midi_message[2] == 14 then
      -- channel 4 fader
      if cc[4] then
        cc[4]:MoveVolume(scaled_val)
      end
         
    elseif midi_message[2] == 5 then
      -- channel 5 fader
      if cc[5] then
        cc[5]:MoveVolume(scaled_val)
      end
               
    elseif midi_message[2] == 7 then
      -- channel 6 fader
      if cc[6] then
        cc[6]:MoveVolume(scaled_val)
      end
         
    elseif midi_message[2] == 6 then
      -- channel 7 fader
      if cc[7] then
        cc[7]:MoveVolume(scaled_val)
      end
      
    elseif midi_message[2] == 4 then
      -- channel 8 fader
      if cc[8] then
        cc[8]:MoveVolume(scaled_val)
      end


    --
    -- channel rotaries
    --

    elseif midi_message[2] == 21 then
      -- channel 1 rotary
      if cc[1] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[1]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[1]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[1]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end

    elseif midi_message[2] == 20 then
      -- channel 2 rotary
      if cc[2] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[2]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[2]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[2]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end

      
    elseif midi_message[2] == 13 then
      -- channel 3 rotary
      if cc[3] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[3]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[3]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[3]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end        
    elseif midi_message[2] == 12 then
      -- channel 4 rotary
      if cc[4] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[4]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[4]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[4]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end
            
    elseif midi_message[2] == 3 then
      -- channel 5 rotary
      if cc[5] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[5]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[5]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[5]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end   
        
    elseif midi_message[2] == 1 then
      -- channel 6 rotary
      if cc[6] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[6]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[6]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[6]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end  
      
    elseif midi_message[2] == 0 then
      -- channel 7 rotary
      if cc[7] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[7]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[7]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[7]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end   
    elseif midi_message[2] == 2 then
      -- channel 8 rotary
      if cc[8] then
        if self.shift_state == OHM64_SHIFT_UNSHIFTED then
          -- filter
          cc[8]:MoveFilter(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
          -- instrument
          cc[8]:MoveInstrument(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
          -- transpose
          cc[8]:MoveTranspose(scaled_val)
          
        elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
          -- ignored
        end
      end    
      
    --
    --  Array of rotaries top/left
    --

    elseif midi_message[2] == 17 then
      -- top row, first dial = FX Rate
      cm:MoveEffectRate(scaled_val)
      
    elseif midi_message[2] == 16 then
      -- top row, second dial = FX Amount
      cm:MoveEffectAmount(scaled_val)

    elseif midi_message[2] == 9 then
      -- top row, third dial = FX Type
      cm:MoveEffectType(1+math.floor(midi_message[3]/32))  --updated for new API
      
    elseif midi_message[2] == 8 then
      -- top row, fourth dial = FX Target
      cm:MoveEffectTarget(1+math.floor(midi_message[3]/43))  --updated for new API

    elseif midi_message[2] == 19 then
      -- second row, first dial = BPM
      ct:SetBpm(math.floor(preferences.base_bpm.value+(midi_message[3]/(128/(preferences.bpm_deviation.value*2))) - preferences.bpm_deviation.value), true)

    elseif midi_message[2] == 18 then
      -- second row, second dial = Quantize
      ct:MoveQuantizeValue(1+math.floor(midi_message[3]/32))  --updated for new API

    elseif midi_message[2] == 11 then
      -- second row, third dial = Cue volume
      cm:MoveCueVolume(scaled_val)
      
    elseif midi_message[2] == 10 then
      -- second row, fourth dial = Master volume
      cm:MoveMasterVolume(scaled_val)

    end
  end
end


function ControllerOhm64:SysexHandler(midi_message)
  -- Controller specific sysex handler

  -- basic midi only, nothing to do :)
end


function ControllerOhm64:Reset()
  -- Reset to the defaults to match the gui on startup
  
  -- shift state
  self.shift_state = OHM64_SHIFT_UNSHIFTED
  
  -- led flash list
  self.flash_list = {}
  
  -- turn off cell leds
  for i = 1, 64 do
    self:SetLed(i, false)
  end
  
  -- channel leds
  for i = 1, 8 do
    self:SetLed(OHM64_CHANNEL_BUTTONS[i], false)
  end
  
  -- stop leds = on
  for i = 1, 8 do
    self:SetLed(OHM64_CHANNEL_STOPS[i], true)
  end
  
  -- welder
  self:SetLed(87, false)
  
  -- clear caches
  self.mute_cache     = {false, false, false, false,
                         false, false, false, false}
  self.cue_cache      = {false, false, false, false,
                         false, false, false, false}
  self.basskill_cache = {false, false, false, false,
                         false, false, false, false}
  self.jam_cache      = {false, false, false, false,
                         false, false, false, false}
end


function ControllerOhm64:Tick(line)
  -- New renoise play line 

  local two_beats = math.mod(line-1, 8)  -- 0, 4
  local half_beat = math.mod(line-1, 4)  -- 0, 2
  
  -- flash welder on beats
  if two_beats == 0 then
    self:SetLed(87, true)
  elseif two_beats == 4 then
    self:SetLed(87, false)
  end
  
  -- flash other leds at 2 times per beat
  if half_beat == 0 then
    for i = 1, #self.flash_list do
      self:SetLed(self.flash_list[i], true)
    end
  elseif half_beat == 2 then
    for i = 1, #self.flash_list do
      self:SetLed(self.flash_list[i], false)
    end
  end
end


function ControllerOhm64:SetCellState(channel, cell, state)
  -- Cell state change
    
  -- ignore channel > 8                 
  if channel > 8 then
    return
  end
  
  -- ignore cell > 7
  if cell > 7 then
    return
  end
  
  local cell_number = self:CellId(channel, cell)
  local flash_index = table.find(self.flash_list, cell_number)
  
  -- handle different states
  if state == CELLSTATE_INVALID then
    -- invalid == unilluminated
    self:SetLed(cell_number, false)
    
    if flash_index then
      table.remove(self.flash_list, flash_index)
    end
  
  elseif state == CELLSTATE_VALID then
    -- valid = illuminated
    self:SetLed(cell_number, true)

    if flash_index then
      table.remove(self.flash_list, flash_index)
    end
    
  else
    -- cued = playing = flash
    self:SetLed(cell_number, true)
    
    if not flash_index then
      table.insert(self.flash_list, cell_number)
    end
  end
end


function ControllerOhm64:SetStopState(channel, state)
  -- Stop button state change

  -- ignore channels > 8
  if channel > 8 then
    return
  end
                      
  local flash_index = table.find(self.flash_list, OHM64_CHANNEL_STOPS[channel])

  if state == CELLSTATE_VALID then
    -- default
    
    -- remove from flash list
    if flash_index then
      table.remove(self.flash_list, flash_index)
    end
    
    -- turn on
    self:SetLed(OHM64_CHANNEL_STOPS[channel], true)
    
  else
    -- cued
    
    -- add to flash index if not there
    if not flash_index then
      table.insert(self.flash_list, OHM64_CHANNEL_STOPS[channel])
    end
    
  end
end


function ControllerOhm64:SetSelected(channel)
  -- No feedback
end


function ControllerOhm64:SetMute(channel, state)
  -- Mute state changed
  
  -- Update cache
  if channel < 9 then
    self.mute_cache[channel] = state
  end
  
  -- Update LEDs if in that mode
  if self.shift_state ==  OHM64_SHIFT_OFF_MUTE then
    self:UpdateChannelLeds()
  end
end

function ControllerOhm64:SetBasskill(channel, state)
  -- Bass kill state changed
  
  -- Update cache
  if channel < 9 then
    self.basskill_cache[channel] = state
  end
  
  -- Update LEDs if in that mode
  if self.shift_state ==  OHM64_SHIFT_UNSHIFTED then
    self:UpdateChannelLeds()
  end
end


function ControllerOhm64:SetCue(channel, state)
  -- Cue state changed
  
  -- Update cache
  if channel < 9 then
    self.cue_cache[channel] = state
  end
  
  -- Update LEDs if in that mode
  if self.shift_state ==  OHM64_SHIFT_INSTRUMENT_CUE then
    self:UpdateChannelLeds()
  end
end


function ControllerOhm64:SetJam(channel, state)
  -- Jam state changed
  
  -- Update cache
  if channel < 9 then
    self.jam_cache[channel] = state
  end
  
  -- Update LEDs if in that mode
  if self.shift_state ==  OHM64_SHIFT_TRANSPOSE_JAM then
    self:UpdateChannelLeds()
  end
end


function ControllerOhm64:SetRouting(channel, state)
  -- state = 1 for A, 2 for M, 3 for B

  -- no feedback possible
end


function ControllerOhm64:SetFilter(channel, value)
  -- no feedback possible
end


function ControllerOhm64:SetTranspose(channel, value)
  -- no feedback possible
end


function ControllerOhm64:SetPanning(channel, value)
  -- no feedback possible
end


function ControllerOhm64:SetVolume(channel, volume)
  -- no feedback possible
end


function ControllerOhm64:SetCrossfader(position)
  -- no feedback possible
end


function ControllerOhm64:SetCrossfaderCut(group, state)
  -- group: 0 = A, 1 = B
  
  if group == 0 then
    self:SetLed(64, state)
  else
    self:SetLed(72, state)
  end
end


function ControllerOhm64:SetFXAmount(value)
  -- no feedback possible
end


function ControllerOhm64:SetFXRate(value)
  -- no feedback possible
end


function ControllerOhm64:SetFXType(type_id)
  -- no feedback possible
end


function ControllerOhm64:SetFXTarget(type_id)
  -- 1 = A, 2 = M, 3 = B
  -- no feedback possible
end


function ControllerOhm64:SetFXState(state)
  -- no feedback possible
end


function ControllerOhm64:SetMasterVolume(value)
  -- no feedback possible
end


function ControllerOhm64:SetCueVolume(value)
  -- no feedback possible
end


function ControllerOhm64:SetPlayState(state)
  -- Illuminate welder on start, unilluminate on stop as this is consistent
  
  if state then
    -- started
    self:SetLed(87, true)
  else
    -- stopped
    self:SetLed(87, false)
  end
end


--------------------------------------------------------------------------------
-- Class Support Functions
--------------------------------------------------------------------------------
function ControllerOhm64:SetLed(led_number, state)
  -- sets the LED to the correct state

  if state then
    self.midi_out_device:send({0x90, led_number, 0x7F})
  else
    self.midi_out_device:send({0x90, led_number, 0x00})
  end
end


function ControllerOhm64:UpdateChannelLeds()
  -- Updates all channel button LEDS depending upon the current mode
  
  if self.shift_state == OHM64_SHIFT_UNSHIFTED then
    -- Bass kill
    for i = 1, 8 do
      self:SetLed(OHM64_CHANNEL_BUTTONS[i], self.basskill_cache[i])
    end
    
  elseif self.shift_state == OHM64_SHIFT_INSTRUMENT_CUE then
    -- cue toggle
    for i = 1, 8 do
      self:SetLed(OHM64_CHANNEL_BUTTONS[i], self.cue_cache[i])
    end
    
  elseif self.shift_state == OHM64_SHIFT_TRANSPOSE_JAM then
    -- jam mode
    for i = 1, 8 do
      self:SetLed(OHM64_CHANNEL_BUTTONS[i], self.jam_cache[i])
    end
    
  elseif self.shift_state == OHM64_SHIFT_OFF_MUTE then
    -- mute
    for i = 1, 8 do
      self:SetLed(OHM64_CHANNEL_BUTTONS[i], self.mute_cache[i])
    end
    
  end  
end


function ControllerOhm64:CellId(x, y)
  -- Returns the cell ID for the given x,y co-ordinate
  
  return (8*(x-1))+(y-1)
end


function ControllerOhm64:CellXY(id)
  -- Returns the cell {x,y} for the given cell ID
  
  return {math.floor(id/8)+1,  (id%8)+1}
end


function ControllerOhm64:ChannelButton(channel)
  -- Converts a channel index to a channel button id

  if channel == 1 then
    return 65
  elseif channel == 2 then
    return 73
  elseif channel == 3 then
    return 66
  elseif channel == 4 then
    return 74
  elseif channel == 5 then
    return 67
  elseif channel == 6 then
    return 75
  elseif channel == 7 then
    return 68
  elseif channel == 8 then
    return 76
  end
end



--------------------------------------------------------------------------------
-- Register Class
--------------------------------------------------------------------------------
cf:Register("Ohm64", ControllerOhm64)

