--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- BaseOscillator class
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
BaseOscillator is a base class and is not used directly.

It's only purpose is to establish a common API for oscillators

BaseOscillator.instrument_index
BaseOscillator.sample_index
BaseOscillator.sample               -- bound sample object
BaseOscillator.ui_transpose         
BaseOscillator.ui_finetune
BaseOscillator.ui_volume
BaseOscillator.ui_panning
BaseOscillator.wavedata             -- the generated wavedata
BaseOscillator:__init(sample)       -- creates and binds to sample object
BaseOscillator:Render()             -- creates the wavedata
BaseOscillator:Reset()              -- resets the oscillator
BaseOscillator:SetTranspose()       -- sets the oscillator transpose    [-24..+24]
BaseOscillator:GetTranspose()       -- returns the oscillator tranpose
BaseOscillator:SetFinetune()        -- sets the oscillator fine tuning  [-127..+127]
BaseOscillator:GetFinetune()        -- returns the oscillator fine tuning
BaseOscillator:SetVolume()          -- sets the oscillator volume       [-37..0]
BaseOscillator:GetVolume()          -- returns the oscillator volume
BaseOscillator:SetPanning()         -- sets the oscillator panning      [0..1]
BaseOscillator:GetPanning()         -- returns the oscillator panning
BaseOscillator:GetUI()              -- return the user interface
BaseOscillator:SetLoopMode()        -- sets the loop mode
BaseOscillator:GetLoopMode()        -- returns the loop mode
BaseOscillator:GetInstrumentIndex() -- returns the instrument index
BaseOscillator:GetSampleIndex()     -- returns the sample index
BaseOscillator:HasSampleMapping()   -- returns boolean if this sample is mapped
BaseOscillator:DeleteSampleMapping()-- removes sample mappings for this sample
BaseOscillator:AddSampleMapping(base_note) -- adds a sample mapping for itself
]]--


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'BaseOscillator'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function BaseOscillator:__init(vb, inst_index, sample_index)
  -- Base class initialisation
  
  self.vb = vb
  self.wavedata = {}
  self.instrument_index = inst_index
  self.sample_index = sample_index
  self.sample = renoise.song().instruments[inst_index].samples[sample_index]

  -- create ui
  self.ui_transpose = self.vb:rotary{
    min = -24,
    max =  24,
    value = self:GetTranspose(),
    tooltip = 'Oscillator Transpose',
    notifier = function(v)
      if v ~= self:GetTranspose() then
        self:SetTranspose(v)
        if self:SetView() then
          self:SetView()
        end
      end
    end
  }
  
  self.ui_finetune = self.vb:rotary{
    min = -127,
    max =  127,
    value = self:GetFinetune(),
    tooltip = 'Oscillator Fine Tuning',
    notifier = function(v)
      if v ~= self:GetFinetune() then
        self:SetFinetune(v)
        if self:SetView() then
          self:SetView()
        end
      end
    end
  }
  
  self.ui_volume = self.vb:rotary{
    min = -37,
    max =  0,
    value = self:GetVolume(),
    tooltip = 'Oscillator Volume',
    notifier = function(v)
      if v ~= self:GetVolume() then
        self:SetVolume(v)
        if self:SetView() then
          self:SetView()
        end
      end
    end
  }
  
  self.ui_panning = self.vb:rotary{
    min = 0,
    max = 1,
    value = self:GetPanning(),
    tooltip = 'Oscillator Panning',
    notifier = function(v)
      if v ~= self:GetPanning() then
        self:SetPanning(v)
        if self:SetView() then
          self:SetView()
        end
      end
    end
  }
  
  -- remove any supersaw sample mappings
  if self:GetSampleIndex() == 1 then
    for i = (self:GetSampleIndex() * 9) - 1, (self:GetSampleIndex() * 9) + 8 do
      self:DeleteSampleMapping(i)
    end
  end

end


function BaseOscillator:Render()
  -- Wave generation function (subclasses should make self.wavedata then call
  -- this function
  
  -- duplicate first 16 frames at the end for smooth looping if required
  if self:GetLoopMode() == renoise.InstrumentEnvelope.LOOP_MODE_FORWARD then
    if #self.wavedata > 16 then
      for i = 1, 16 do
        table.insert(self.wavedata, self.wavedata[i])
      end
    end
  end
  
  local sb = self.sample.sample_buffer
  
  -- too long?
  if (not sb.has_sample_data) then
    -- recreate sample buffer if none there
    sb:create_sample_data(44000, -- sample rate
                          32,    -- bit depth
                          1,     -- channels
                          VA_MAX_SAMPLE_LEN) -- frames
  end

  if (#self.wavedata > sb.number_of_frames) then
    -- recreate sample buffer
    sb:create_sample_data(44000, -- sample rate
                          32,    -- bit depth
                          1,     -- channels
                          math.max(#self.wavedata, VA_MAX_SAMPLE_LEN)) -- frames
  end
  
  -- transfer wavedata
  
  sb:prepare_sample_data_changes()
  for i = 1, #self.wavedata do
    sb:set_sample_data(1, i, self.wavedata[i])
  end
  sb:finalize_sample_data_changes()
  
  -- set loop points
  if #self.wavedata > 16 then
    self.sample.loop_start = 8
    self.sample.loop_end = #self.wavedata - 9
  end
end


function BaseOscillator:Reset()
  -- Oscillator reset
  
  -- reset osc settings
  self.ui_transpose.value = 0
  self:SetTranspose(0)
  self.ui_finetune.value = 0
  self:SetFinetune(0)
  self.ui_volume.value = -37
  self:SetVolume(-37)
  self.ui_panning.value = 0.5
  self:SetPanning(0.5)
  
end


function BaseOscillator:SetTranspose(v)
  -- Sets the oscillator transpose
  
  if self.sample then
    self.sample.transpose = v
    renoise.app():show_status(string.format('ReSynth: Oscillator transpose set to %d semitones', v))
  end
end


function BaseOscillator:GetTranspose()
  -- Returns the oscillator transpose
  
  if self.sample then
    return self.sample.transpose
  end
end


function BaseOscillator:SetFinetune(v)
  -- Sets the oscillator fine tune
  
  if self.sample then
    self.sample.fine_tune = v
    renoise.app():show_status(string.format('ReSynth: Oscillator finetune set to %d', v))
  end
end


function BaseOscillator:GetFinetune()
  -- Returns the oscillator fine tune
  
  if self.sample then
    return self.sample.fine_tune
  end
end


function BaseOscillator:SetVolume(v)
  -- Sets the oscillator volume (<-36 = off)
  
  if self.sample then
    if v < -36 then
      --off
      self.sample.volume = 0
      if self:HasSampleMapping() then
        self:DeleteSampleMapping()
      end
      renoise.app():show_status('ReSynth: Oscillator volume set to -INF dB')
    else
      -- on
      self.sample.volume = math.db2lin(v)
      if not self:HasSampleMapping() then
        self:AddSampleMapping(45)
      end
      renoise.app():show_status(string.format('ReSynth: Oscillator volume set to %2.1f dB', v))
    end
  end
end


function BaseOscillator:GetVolume()
  -- Returns the oscillator volume

  if self.sample then
    if self.sample.volume == 0 then
      return -37
    else
      return math.lin2db(self.sample.volume)
    end
  end
end


function BaseOscillator:SetPanning(v)
  -- Sets the oscillator panning
  
  if self.sample then
    self.sample.panning = v
    if v > 0 then
      renoise.app():show_status(string.format('ReSynth: Oscillator panning set to %d R', (v-0.5)*100))
    elseif v < 0 then
      renoise.app():show_status(string.format('ReSynth: Oscillator panning set to %d L', (0.5-v)*100))
    elseif v == 0 then
      renoise.app():show_status('ReSynth: Oscillator panning set to center')
    end
  end
end


function BaseOscillator:GetPanning()
  -- Returns the oscillator panning
  
  if self.sample then
    return self.sample.panning
  end
end


function BaseOscillator:GetUI()
  -- Return the user interface view
  
  -- nothing in base class
end


function BaseOscillator:SetLoopMode(mode)
  -- Sets the loop mode

  if self.sample then
    self.sample.loop_mode = mode
  end
end


function BaseOscillator:GetLoopMode()
  -- Returns the loop mode
  
  if self.sample then
    return self.sample.loop_mode
  end
end


function BaseOscillator:GetInstrumentIndex()
  -- Returns the instrument index
  
  return self.instrument_index
end


function BaseOscillator:GetSampleIndex()
  -- Returns the sample index
  
  return self.sample_index
end


function BaseOscillator:HasSampleMapping(index_override)
  -- checks to see if this sample is already mapped

  local sm = renoise.song().instruments[self.instrument_index].sample_mappings[renoise.Instrument.LAYER_NOTE_ON]
  
  if index_override then
    for i = 1, #sm do
      if sm[i].sample_index == index_override then
        -- found
        return true
      end
    end
    
    -- not found
    return false
  else
    -- check for bound sample
    for i = 1, #sm do
      if sm[i].sample_index == self.sample_index then
        -- found
        return true
      end
    end
    
    -- not found
    return false
  end
end


function BaseOscillator:DeleteSampleMapping(index_override)
  -- removes any samples mappings for this sample

  local inst = renoise.song().instruments[self.instrument_index]
  local sm = inst.sample_mappings[renoise.Instrument.LAYER_NOTE_ON]
  
  if index_override then
    -- remove 
    for i = #sm, 1, -1 do
      if sm[i].sample_index == index_override then
        -- found
        inst:delete_sample_mapping_at(renoise.Instrument.LAYER_NOTE_ON, i)    
      end
    end
  else
    -- remove 
    for i = #sm, 1, -1 do
      if sm[i].sample_index == self.sample_index then
        -- found
        inst:delete_sample_mapping_at(renoise.Instrument.LAYER_NOTE_ON, i)    
      end
    end
  end
end


function BaseOscillator:AddSampleMapping(base_note, index_override)
  -- add a sample mapping for this sample

  local inst = renoise.song().instruments[self.instrument_index]

  if index_override then
    inst:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                               index_override,
                               base_note)
  else
    inst:insert_sample_mapping(renoise.Instrument.LAYER_NOTE_ON,
                               self.sample_index,
                               base_note)
  end
end


function BaseOscillator:GetUI()
  -- Returns the UI
  
  return self.ui
end
