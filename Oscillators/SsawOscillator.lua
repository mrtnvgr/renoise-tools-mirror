--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- Supersaw waveform oscillator
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
SsawOscillator inherits from BaseOscillator class and generates supersaw
oscillator waveforms.


SsawOscillator.ui_count            -- viewbuider ui
SsawOscillator.ui_detuning
SsawOscillator.ui_width
SsawOscillator.count               -- number of saws   [0..4]  (actual number is 1+2*this_val)
SsawOscillator.detuning            -- maximum detuning [1..16] (multiplied by 2 in use)
SsawOscillator.width               -- maximum panning  [0..0.5]
SsawOscillator.rendering           -- rendering flag
SsawOscillator:GetSawCount()       -- returns #.sample_slots
SsawOscillator:SetSawCount()       -- updates sample_slots and creates/destroys
                                      mirrored samples as needed
SsawOscillator:GetDetuning()       -- returns maximum detuning value
SsawOscillator:SetDetuning()       -- sets maximum detuning value
SsawOscillator:GetWidth()          -- returns maximum panning value
SsawOscillator:SetWidth()          -- sets panning detuning value
BaseOscillator:GetUI()             -- return the user interface
SsawOscillator:Render()            -- tiny wrapper
SsawOscillator:Load()              -- loads the sample
BaseOscillator:Reset()             -- resets the oscillator
BaseOscillator:SetLoopMode()       -- sets the loop mode
BaseOscillator:GetLoopMode()       -- returns the loop mode
]]--


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'SsawOscillator' (BaseOscillator)



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function SsawOscillator:__init(vb, inst_index, sample_index)
  -- VA Generator init
  local loaded_sample = false
    
  -- call base class init
  BaseOscillator.__init(self, vb, inst_index, sample_index)
  
  -- load settings
  if string.sub(self.sample.name, 1, 4) == "SS4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 4 then
      -- seems ok
      self:SetSawCount(tonumber(settings[2]))
      self.detuning = tonumber(settings[3])
      self.width = tonumber(settings[4])
      loaded_sample = true
    end
  end
  
  -- check for sample mapping
  if not self:HasSampleMapping() then
    if self:GetVolume() > -37 then
      self:AddSampleMapping(45)
    end
  end  
  
  -- create ui
  self.ui_count = self.vb:rotary{
    min = 0,
    max =  4,
    value = self:GetSawCount(),
    tooltip = 'SuperSaw wave count',
    notifier = function(v)
      if math.floor(v) ~= self:GetSawCount() then
        self:SetSawCount(math.floor(v))
      end
    end
  }
  
  self.ui_detuning = self.vb:rotary{
    min = 0,
    max =  32,
    value = self:GetDetuning(),
    tooltip = 'SuperSaw  detune amount',
    notifier = function(v)
      if math.floor(v) ~= self:GetDetuning() then
        self:SetDetuning(math.floor(v))
      end
    end
  }
  
  self.ui_width = self.vb:rotary{
    min = 0,
    max =  50,
    value = self:GetWidth(),
    tooltip = 'SuperSaw width',
    notifier = function(v)
      if math.floor(v) ~= self:GetWidth()*100 then
        self:SetWidth(math.floor(v)/100)
      end
    end
  }
  
  self.ui = self.vb:column{
    spacing = 6,
    margin = 2,
    id = 'osc'..tostring(sample_index),
    
    self.vb:horizontal_aligner{
      spacing = 5,
      mode = 'justify',

      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_transpose,
        self.vb:text {
          text = ' Trans',
        },
      },
        
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_finetune,
        self.vb:text {
          text = ' Fine',
        },
      },
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_volume,
        self.vb:text {
          text = '  Vol',
        },
      },

      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_panning,
        self.vb:text {
          text = '  Pan',
        },
      },
    },
     
    self.vb:horizontal_aligner{
      mode = 'justify',

      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_count,
        self.vb:text {
          text = 'Count',
        },
      },
        
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_detuning,
        self.vb:text {
          text = 'Detune',
        },
      },
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_width,
        self.vb:text {
          text = 'Width',
        },
      },
    },
  }

  if not loaded_sample then 
    self:Reset()
  end
  
  self.rendering = false
  
  self:Render()
end


function SsawOscillator:Reset()
  -- Reset to defaults
  
  -- interpolation
  self.sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
  
  -- set default loop mode (off)
  self:SetLoopMode(renoise.Sample.LOOP_MODE_FORWARD)
  
  local sb = self.sample.sample_buffer
  
  -- load in sawtooth in control (self.sample)
  sb:create_sample_data(44000, -- sample rate
                        32,    -- bit depth
                        1,     -- channels
                        216)   -- frames
                        
  -- add data
  sb:prepare_sample_data_changes()
  for i = 1, #SAW_TABLE do
    sb:set_sample_data(1, i, SAW_TABLE[i])
  end
  
  for i = 1, 16 do
    sb:set_sample_data(1, 200+i, SAW_TABLE[i])
  end
  sb:finalize_sample_data_changes()
  
  -- set loop points
  self.sample.loop_start = 8
  self.sample.loop_end = 207

  -- duplicate to mirrors
  local start_index = 8
  local limit_index = start_index + 8
  local inst = renoise.song().instruments[self:GetInstrumentIndex()]
  
  for i = start_index, limit_index do
    inst.samples[i]:copy_from(self.sample)
    inst.samples[i].name = 'SuperSaw Slave Oscillator'
  end

  -- ui init
  self.ui_count.value = 0
  self.ui_detuning.value = 0.5
  self.ui_width.value = 0
  
  self:Render()
end


function SsawOscillator:GetSawCount()
  -- Returns the number of additional saws
  
  if self.count then
    return self.count
  else
    return 0
  end
end


function SsawOscillator:SetSawCount(count)
  -- Sets the number of additional saws
  
  self.count = count
  
  -- update sample mapps
  local start_index = 8
  local end_index   = start_index + (self:GetSawCount()*2)
  local limit_index = start_index + 8
  
  -- add required
  for i = start_index, end_index do
    if not self:HasSampleMapping(i) then
      self:AddSampleMapping(45, i)
    end
  end
  
  -- remove unneeded
  if end_index < limit_index then
    for i = end_index, limit_index do
      if self:HasSampleMapping(i) then
        self:DeleteSampleMapping(i)
      end
    end
  end
  
  renoise.app():show_status(string.format('ReSynth: SuperSaw wave count set to %d', (count*2)+1))
  
  self:Render()
end


function SsawOscillator:GetDetuning()
  -- Returns the detuning
  
  if self.detuning then
    return self.detuning
  else
    return 0
  end
end


function SsawOscillator:SetDetuning(detuning)
  -- Sets the detuning

  self.detuning = detuning
  
  renoise.app():show_status(string.format('ReSynth: SuperSaw wave detuning set to %d', detuning))
  
  self:Render()
end


function SsawOscillator:GetWidth()
  -- Returns the width
  
  if self.width then
    return self.width
  else
    return 0
  end
end


function SsawOscillator:SetWidth(width)
  -- Sets the width

  self.width = width
  
  renoise.app():show_status(string.format('ReSynth: SuperSaw width set to %d', width*200))
  
  self:Render()
end


function SsawOscillator:SetVolume(v)
  -- BaseOscillator override
  
  BaseOscillator.SetVolume(self, v)
  self:Render()
end


function SsawOscillator:SetPanning(v)
  -- BaseOscillator override
  
  BaseOscillator.SetPanning(self, v)
  self:Render()
end


function SsawOscillator:SetFinetune(v)
  -- BaseOscillator override
  
  BaseOscillator.SetFinetune(self, v)
  self:Render()
end


function SsawOscillator:SetTranspose(v)
  -- BaseOscillator override
  
  BaseOscillator.SetTranspose(self, v)
  self:Render()
end


function SsawOscillator:Render()
  -- SsawOscillator rendering function override
  
  -- avoid overlapping renders
  if self.rendering then
    return
  end
  
  self.rendering = true
  
  local start_index = (self:GetSampleIndex() * 9) - 1
  local end_index   = start_index + (self:GetSawCount()*2)
  local limit_index = start_index + 7
  local inst = renoise.song().instruments[self:GetInstrumentIndex()]
  local detune_step = self:GetDetuning() * 2
  local panning_step = self:GetWidth()
  local working_sample
  
  if self:GetSawCount() > 0 then
    -- no dividing by zero
    detune_step = detune_step / (self:GetSawCount()*2)
    panning_step = panning_step / (self:GetSawCount()*2)
  end
  
  if end_index > start_index then
    for i = start_index, end_index do
    
      working_sample = inst.samples[i]
    
      -- set volume / transpose
      working_sample.volume = self.sample.volume
      working_sample.transpose = self.sample.transpose
      
      if math.mod(i, 2) == 0 then
        -- detune down
        working_sample.fine_tune = clamp(self.sample.fine_tune -
                                          (math.floor((i+1)/2) * detune_step),
                                          -127,
                                          127)
                                          
        -- pan left
        working_sample.panning = clamp(self.sample.panning -
                                        (math.floor((i+1)/2) * panning_step),
                                        0,
                                        1)
      else
        -- detune up
        working_sample.fine_tune = clamp(self.sample.fine_tune +
                                          (math.floor((i+1)/2) * detune_step),
                                          -127,
                                          127)
                                          
        -- pan right
        working_sample.panning = clamp(self.sample.panning +
                                        (math.floor((i+1)/2) * panning_step),
                                        0,
                                        1)
      end
    end
  end
  
  for i = end_index, limit_index do
    inst.samples[i].volume = 0
  end
    
  -- calculate settings string
  self.sample.name = table_to_string({'SS4',
                                      self:GetSawCount(),
                                      self:GetDetuning(),
                                      self:GetWidth(),
                                      })
                                      
  self.rendering = false

  self:SetView()
end
  
  
function SsawOscillator:SetView()
  -- maybe set view
  if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR then
    renoise.song().selected_instrument_index = self.instrument_index
    renoise.song().selected_sample_index = self.sample_index
    if renoise.song().selected_sample.sample_buffer.has_sample_data then
      renoise.song().selected_sample.sample_buffer.display_range = {1, renoise.song().selected_sample.sample_buffer.number_of_frames}
    end
  end
end
