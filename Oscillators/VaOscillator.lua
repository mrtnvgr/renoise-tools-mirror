--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- Virtual analog waveform oscillator
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
VaOscillator inherits from BaseOscillator class and generates virtual analog
oscillator waveforms.


VaOscillator.ui
VaOscillator.ui_waveform         -- viewbuilder user interface
VaOscillator.ui_pw
VaOscillator.ui_pwm_speed
VaOscillator.ui_pwm_depth
BaseOscillator.wavedata          -- the generated wavedata
VaOscillator.waveform            -- enum { VA_WAVEFORM_* }
VaOscillator.shape               -- shape modifier                     [0..1]
VaOscillator.pwm_speed           -- shape modifier lfo speed (cycles)  [0..256]
VaOscillator.pwm_depth           -- shape modifier lfo depth           [0..0.5]
BaseOscillator:GetUI()           -- return the user interface
VaOscillator:Render()            -- creates the wavedata
VaOscillator:SetWaveform()       -- sets the waveform
VaOscillator:GetWaveform()       -- returns the enum of the waveform
VaOscillator:SetShape()          -- sets the shape modifier
VaOscillator:GetShape()          -- returns the shape modifier
VaOscillator:SetPwmSpeed()       -- sets the lfo speed
VaOscillator:GetPwmSpeed()       -- returns the lfo speed
VaOscillator:SetPwmDepth()       -- sets the lfo depth
VaOscillator:GetPwmDepth()       -- returns the lfo depth
BaseOscillator:Reset()           -- resets the generator
BaseOscillator:SetLoopMode()     -- sets the loop mode
BaseOscillator:GetLoopMode()     -- returns the loop mode
]]--


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'VaOscillator' (BaseOscillator)



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function VaOscillator:__init(vb, inst_index, sample_index)
  -- VA Generator init
  local loaded_sample = false

  -- call base class init
  BaseOscillator.__init(self, vb, inst_index, sample_index)
   
  if string.sub(self.sample.name, 1, 4) == "VA4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 5 then
      -- seems ok
      self.waveform = tonumber(settings[2])
      self.shape = tonumber(settings[3])
      self.pwm_speed = tonumber(settings[4])
      self.pwm_depth = tonumber(settings[5])
    
      -- add sample map
      if not self:HasSampleMapping() then
        self:AddSampleMapping(45)
      end
    
      loaded_sample = true
    end
  end

  -- create ui
  self.ui_waveform = self.vb:chooser{
    items = { 'Sin', 'Tri', 'Saw', 'Pulse' },
    value = self:GetWaveform(),
    tooltip = 'VA Waveform',
    notifier = function (v)
      if v ~= self:GetWaveform() then
        self:SetWaveform(v)
      end
    end
  }
  
  self.ui_pw = self.vb:rotary{
    min = 0,
    max =  1,
    value = self:GetShape(),
    tooltip = 'VA Pulse Width',
    notifier = function(v)
      if v ~= self:GetShape() then
        self:SetShape(v)
      end
    end
  }
  
  self.ui_pwm_speed = self.vb:rotary{
    min = 0,
    max =  64,
    value = self:GetPwmSpeed()/4,
    tooltip = 'VA PWM Speed',
    notifier = function(v)
      if math.floor(v*4) ~= self:GetPwmSpeed() then
        self:SetPwmSpeed(math.floor(v*4))
      end
    end
  }
  
  self.ui_pwm_depth = self.vb:rotary{
    min = 0,
    max =  25,
    value = self:GetPwmDepth()*50,
    tooltip = 'VA PWM Depth',
    notifier = function(v)
      if math.floor(v) ~= self:GetPwmDepth()*50 then
        self:SetPwmDepth(math.floor(v)/50)
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
      spacing = 2,
      mode = 'justify',
      
      self.ui_waveform,
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_pw,
        self.vb:text {
          text = '  PW',
        },
      },
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_pwm_speed,
        self.vb:text {
          text = 'Speed',
        },
      },
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_pwm_depth,
        self.vb:text {
          text = 'Depth',
        },
      },
    },
  }
  
  -- set loop mode (always forwards)
  self:SetLoopMode(renoise.Sample.LOOP_MODE_FORWARD)

  -- check for sample mapping
  if not self:HasSampleMapping() then
    if self:GetVolume() > -37 then
      self:AddSampleMapping(45)
    end
  end  


  -- reset to defaults
  if not loaded_sample then
    if self.sample.sample_buffer.has_sample_data then
      self.sample.sample_buffer:delete_sample_data()
    end
    self:Reset()
  end
end


function VaOscillator:Reset()
  -- Reset to defaults
  
  
  -- interpolation
  self.sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
  -- set loop mode
  self.sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
  
  self.ui_waveform.value = VA_WAVEFORM_SIN
  self.waveform = VA_WAVEFORM_SIN
  self.ui_pw.value = 0
  self.shape = 0
  self.ui_pwm_speed.value = 0
  self.pwm_speed = 0
  self.ui_pwm_depth.value = 0
  self.pwm_depth = 0
  
  self:Render()
end


function VaOscillator:SetWaveform(wave)
  -- Sets the VA base waveform
  
  self.waveform = wave
  self:Render()
end


function VaOscillator:GetWaveform()
  -- Returns the base waveform
  
  return self.waveform
end


function VaOscillator:SetShape(shape)
  -- Sets the shape modifier
  
  self.shape = shape
  self:Render()
end


function VaOscillator:GetShape()
  -- Returns the base waveform
  
  return self.shape
end


function VaOscillator:SetPwmSpeed(speed)
  -- Sets the lfo speed
 
  self.pwm_speed = speed
  self:Render()
end


function VaOscillator:GetPwmSpeed()
  -- Returns the lfo speed
  
  if self.pwm_speed then
    return self.pwm_speed
  else
    return 0
  end
end


function VaOscillator:SetPwmDepth(depth)
  -- Sets the lfo depth
 
  self.pwm_depth = depth
  self:Render()
end


function VaOscillator:GetPwmDepth()
  -- Returns the lfo depth
  
  if self.pwm_depth then
    return self.pwm_depth
  else
    return 0
  end
end


function VaOscillator:Render()
  -- VaOscillator rendering function callthrough
  
  self.wavedata = {}

  if self.waveform == VA_WAVEFORM_SIN then
    for i = 1, VA_CYCLE_LEN do
      table.insert(self.wavedata, SIN_TABLE[i])
    end
    
  elseif self.waveform == VA_WAVEFORM_TRI then
    -- rise to 1
    for i = 1, VA_QUARTERCYCLE_LEN do
      table.insert(self.wavedata, i*VA_TRI_GRADIENT)
    end
    
    -- drop from 1 to -1
    for i = 1, VA_HALFCYCLE_LEN do
      table.insert(self.wavedata, 1-(i*VA_TRI_GRADIENT))
    end
    
    -- rise to zero
    for i = 1, VA_QUARTERCYCLE_LEN do
      table.insert(self.wavedata, (i*VA_TRI_GRADIENT)-1)
    end
  
  elseif self.waveform == VA_WAVEFORM_SAW then
  
    for i = 1, VA_CYCLE_LEN do
      table.insert(self.wavedata, SAW_TABLE[i])
    end
    
  elseif self.waveform == VA_WAVEFORM_PULSE then
  
    if self.pwm_speed == 0 or self.pwm_depth == 0 then
      -- simple case, single cycle
      
      -- 1
      for i = 1, VA_HALFCYCLE_LEN + math.floor((VA_HALFCYCLE_LEN-1)*self.shape) do
        table.insert(self.wavedata, 1)
      end
      
      -- -1
      for i = #self.wavedata, VA_CYCLE_LEN do
        table.insert(self.wavedata, -1)
      end
      
    else
      -- complicated case - PWM
      
      local shape_table = {}
      local sin_step = 256 / self.pwm_speed
      local this_cycle_length
      
      for i = 1, self.pwm_speed do
        this_cycle_length = VA_HALFCYCLE_LEN + 
                     math.floor((VA_HALFCYCLE_LEN-1)
                                * clamp(self.shape +
                                        (SIN_TABLE[math.floor(i*sin_step)]
                                         * self.pwm_depth),
                                        0,
                                        1))

        for i = 1, this_cycle_length do
          table.insert(self.wavedata, 1)
        end
        
        for i = 1, VA_CYCLE_LEN - this_cycle_length do
          table.insert(self.wavedata, -1)
        end
      end
    end
  end
  
  BaseOscillator.Render(self)
  
  -- calculate settings string
  self.sample.name = table_to_string({'VA4',
                                      self.waveform,
                                      self.shape,
                                      self.pwm_speed,
                                      self.pwm_depth })
  self:SetView()
end       
   
                                      
function VaOscillator:SetView()
  -- maybe set view
  if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR then
    renoise.song().selected_instrument_index = self.instrument_index
    renoise.song().selected_sample_index = self.sample_index
    renoise.song().selected_sample.sample_buffer.display_range = {renoise.song().selected_sample.loop_start, renoise.song().selected_sample.loop_end}
  end
end
