--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- Frequency Modulation waveform oscillator
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
FmOscillator inherits from BaseOscillator class and generates virtual analog
oscillator waveforms.


FmOscillator.ui
FmOscillator.op_switch
FmOscillator.render_button
FmOscillator.ui_opX_multiplier
FmOscillator.ui_opX_start
FmOscillator.ui_opX_attack
FmOscillator.ui_opX_peak
FmOscillator.ui_opX_decay
FmOscillator.ui_opX_hold
FmOscillator.ui_opX_row1
FmOscillator.ui_opX_row2
FmOscillator.multipliers[]
FmOscillator.start_values[]
FmOscillator.attack_values[]
FmOscillator.peak_values[]
FmOscillator.decay_values[]
FmOscillator.hold_values[]
BaseOscillator.wavedata          -- the generated wavedata
FmOscillotor:ViewOperator(id)
BaseOscillator:GetUI()           -- return the user interface
FmOscillator:Render()            -- creates the wavedata
]]--


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'FmOscillator' (BaseOscillator)



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function FmOscillator:__init(vb, inst_index, sample_index)
  -- FM Generator init

  -- call base class init
  BaseOscillator.__init(self, vb, inst_index, sample_index)
  
  self.multipliers    = {  1,   1,   1}
  self.start_values   = {127,   0,   0}
  self.attack_values  = {  0,   0,   0}
  self.peak_values    = {127,   0,   0}
  self.decay_values   = { 31,   0,   0}
  self.hold_values    = { 63,   0,   0}
  
  local loaded_sample = false
  
  
  if string.sub(self.sample.name, 1, 4) == "FM4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)

    if #settings == 19 then
      -- seems ok
      self.multipliers[1] = tonumber(settings[2])
      self.start_values[1] = tonumber(settings[3])
      self.attack_values[1] = tonumber(settings[4])
      self.peak_values[1] = tonumber(settings[5])
      self.decay_values[1] = tonumber(settings[6])
      self.hold_values[1] = tonumber(settings[7])
      self.multipliers[2] = tonumber(settings[8])
      self.start_values[2] = tonumber(settings[9])
      self.attack_values[2] = tonumber(settings[10])
      self.peak_values[2] = tonumber(settings[11])
      self.decay_values[2] = tonumber(settings[12])
      self.hold_values[2] = tonumber(settings[13])
      self.multipliers[3] = tonumber(settings[14])
      self.start_values[3] = tonumber(settings[15])
      self.attack_values[3] = tonumber(settings[16])
      self.peak_values[3] = tonumber(settings[17])
      self.decay_values[3] = tonumber(settings[18])
      self.hold_values[3] = tonumber(settings[19]) 
         
      loaded_sample = true
    end
  end
  
  
  -- create ui
  self.ui_op_switch = self.vb:switch{
    height = 20,
    width = 105,
    items = {'Op1', 'Op2', 'Op3'},
    value = 1,
    notifier = function(v)
      self:ViewOperator(v)
    end
  }
  
  self.ui_render_button = self.vb:button{
    height = 20,
    width = 50,
    text = 'Render',
    notifier = function(v)
      self:Render()
    end
  }
  
  self.ui_op1_multiplier = self.vb:valuebox{
    min = 1,
    max = 8,
    value = self.multipliers[1],
    width = 50,
    tooltip = 'Operator 1 Multiplier',
    notifier = function(v)
      self:SetMultiplier(1, v)
    end
  }
  
  self.ui_op1_start = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.start_values[1],
    width = 50,
    tooltip = 'Operator 1 Start Level',
    notifier = function(v)
      self:SetStart(1, v)
    end
  }

  self.ui_op1_attack = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.attack_values[1],
    width = 50,
    tooltip = 'Operator 1 Attack Time',
    notifier = function(v)
      self:SetAttack(1, v)
    end
  }

  self.ui_op1_peak = self.vb:valuebox{
    min = 1,
    max = 127,
    value = self.peak_values[1],
    width = 50,
    tooltip = 'Operator 1 Peak Level',
    notifier = function(v)
      self:SetPeak(1, v)
    end
  }

  self.ui_op1_decay = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.decay_values[1],
    width = 50,
    tooltip = 'Operator 1 Decay Time',
    notifier = function(v)
      self:SetDecay(1, v)
    end
  }
  
  self.ui_op1_hold = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.hold_values[1],
    width = 50,
    tooltip = 'Operator 1 Hold Level',
    notifier = function(v)
      self:SetHold(1, v)
    end
  }
  
  self.ui_op1_row1 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
      
    self.ui_op1_multiplier,
    self.ui_op1_attack,
    self.ui_op1_decay,
  }
    
  self.ui_op1_row2 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
      
    self.ui_op1_start,
    self.ui_op1_peak,
    self.ui_op1_hold,
  }

  self.ui_op2_multiplier = self.vb:valuebox{
    min = 1,
    max = 8,
    value = self.multipliers[2],
    width = 50,
    tooltip = 'Operator 2 Multiplier',
    notifier = function(v)
      self:SetMultiplier(2, v)
    end
  }
  
  self.ui_op2_start = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.start_values[2],
    width = 50,
    tooltip = 'Operator 2 Start Level',
    notifier = function(v)
      self:SetStart(2, v)
    end
  }

  self.ui_op2_attack = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.attack_values[2],
    width = 50,
    tooltip = 'Operator 2 Attack Time',
    notifier = function(v)
      self:SetAttack(2, v)
    end
  }

  self.ui_op2_peak = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.peak_values[2],
    width = 50,
    tooltip = 'Operator 2 Peak Level',
    notifier = function(v)
      self:SetPeak(2, v)
    end
  }

  self.ui_op2_decay = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.decay_values[2],
    width = 50,
    tooltip = 'Operator 2 Decay Time',
    notifier = function(v)
      self:SetDecay(2, v)
    end
  }
  
  self.ui_op2_hold = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.hold_values[2],
    width = 50,
    tooltip = 'Operator 2 Hold Level',
    notifier = function(v)
      self:SetHold(2, v)
    end
  }
  
  self.ui_op2_row1 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
    visible = false,
    self.ui_op2_multiplier,
    self.ui_op2_attack,
    self.ui_op2_decay,
  }
    
  self.ui_op2_row2 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
    visible = false,
    self.ui_op2_start,
    self.ui_op2_peak,
    self.ui_op2_hold,
  }
  
  self.ui_op3_multiplier = self.vb:valuebox{
    min = 1,
    max = 8,
    value = self.multipliers[3],
    width = 50,
    tooltip = 'Operator 3 Multiplier',
    notifier = function(v)
      self:SetMultiplier(3, v)
    end
  }
  
  self.ui_op3_start = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.start_values[3],
    width = 50,
    tooltip = 'Operator 3 Start Level',
    notifier = function(v)
      self:SetStart(3, v)
    end
  }

  self.ui_op3_attack = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.attack_values[3],
    width = 50,
    tooltip = 'Operator 3 Attack Time',
    notifier = function(v)
      self:SetAttack(3, v)
    end
  }

  self.ui_op3_peak = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.peak_values[3],
    width = 50,
    tooltip = 'Operator 3 Peak Level',
    notifier = function(v)
      self:SetPeak(3, v)
    end
  }

  self.ui_op3_decay = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.decay_values[3],
    width = 50,
    tooltip = 'Operator 3 Decay Time',
    notifier = function(v)
      self:SetDecay(3, v)
    end
  }
  
  self.ui_op3_hold = self.vb:valuebox{
    min = 0,
    max = 127,
    value = self.hold_values[3],
    width = 50,
    tooltip = 'Operator 3 Hold Level',
    notifier = function(v)
      self:SetHold(3, v)
    end
  }
  
  self.ui_op3_row1 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
    visible = false,
    self.ui_op3_multiplier,
    self.ui_op3_attack,
    self.ui_op3_decay,
  }
    
  self.ui_op3_row2 = self.vb:horizontal_aligner{
    spacing = 2,
    mode = 'justify',
    visible = false,
    self.ui_op3_start,
    self.ui_op3_peak,
    self.ui_op3_hold,
  }
  
  
    
  self.ui = self.vb:column{
    spacing = 2,
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
      self.ui_op_switch,
      self.ui_render_button,
    },
    
    self.ui_op1_row1,
    self.ui_op1_row2,
    self.ui_op2_row1,
    self.ui_op2_row2,
    self.ui_op3_row1,
    self.ui_op3_row2,
  }
  
  -- set loop mode (always forwards)
  self:SetLoopMode(renoise.Sample.LOOP_MODE_FORWARD)
  
  -- reset to defaults
  self.sample.sample_buffer:create_sample_data(44000, -- sample rate
                                               32,    -- bit depth
                                               1,     -- channels
                                               VA_CYCLE_LEN * 514)-- frames

  -- check for sample mapping
  if not self:HasSampleMapping() then
    if self:GetVolume() > -37 then
      self:AddSampleMapping(45)
    end
  end  

  -- render
  if loaded_sample then
    self.sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
    self.sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
    self:Render()
  else
    self:Reset()
  end
end


function FmOscillator:SetStart(operator, value)
  self.start_values[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d start level set to %d', operator, value))
end


function FmOscillator:SetAttack(operator, value)
  self.attack_values[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d attack time set to %d', operator, value))
end


function FmOscillator:SetPeak(operator, value)
  self.peak_values[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d peak level set to %d', operator, value))
end


function FmOscillator:SetDecay(operator, value)
  self.decay_values[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d decay time set to %d', operator, value))
end


function FmOscillator:SetHold(operator, value)
  self.hold_values[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d hold level set to %d', operator, value))
end


function FmOscillator:SetMultiplier(operator, value)
  self.multipliers[operator] = value
  renoise.app():show_status(string.format('ReSynth: Operator %d frequency multiplier set to %d', operator, value))
end


function FmOscillator:CalculateSampleLength(operator)
  -- Calculates the sample length in cycles
  
  -- limit to first operator as that is what we hear
  return ((self.attack_values[operator] + self.decay_values[operator] + 1) * 2) * VA_CYCLE_LEN
end


function FmOscillator:Reset()
  -- Reset to defaults
  
  
  -- interpolation
  self.sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
  -- set loop mode
  self.sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD

  -- reset operators
  self.multipliers    = {  1,   1,   1}
  self.ui_op1_multiplier.value = 1
  self.ui_op2_multiplier.value = 1
  self.ui_op3_multiplier.value = 1
  self.start_values   = {127,   0,   0}
  self.ui_op1_start.value = 127
  self.ui_op2_start.value = 0
  self.ui_op3_start.value = 0
  self.attack_values  = {  0,   0,   0}
  self.ui_op1_attack.value = 0
  self.ui_op2_attack.value = 0
  self.ui_op3_attack.value = 0
  self.peak_values    = {127,   0,   0}
  self.ui_op1_peak.value = 127
  self.ui_op2_peak.value = 0
  self.ui_op3_peak.value = 0
  self.decay_values   = { 31,   0,   0}
  self.ui_op1_decay.value = 31
  self.ui_op2_decay.value = 0
  self.ui_op3_decay.value = 0
  self.hold_values    = { 63,   0,   0}
  self.ui_op1_hold.value = 63
  self.ui_op2_hold.value = 0
  self.ui_op3_hold.value = 0

  self:Render()
end


function FmOscillator:ViewOperator(index)
  -- View the specified operator
  
  -- view
  if index == 1 then
    self.ui_op1_row1.visible = true
    self.ui_op1_row2.visible = true
    self.ui_op2_row1.visible = false
    self.ui_op2_row2.visible = false
    self.ui_op3_row1.visible = false
    self.ui_op3_row2.visible = false
  elseif index == 2 then
    self.ui_op1_row1.visible = false
    self.ui_op1_row2.visible = false
    self.ui_op2_row1.visible = true
    self.ui_op2_row2.visible = true
    self.ui_op3_row1.visible = false
    self.ui_op3_row2.visible = false
  elseif index == 3 then
    self.ui_op1_row1.visible = false
    self.ui_op1_row2.visible = false
    self.ui_op2_row1.visible = false
    self.ui_op2_row2.visible = false
    self.ui_op3_row1.visible = true
    self.ui_op3_row2.visible = true
  end
end


function FmOscillator:Render()
  -- FmOscillator rendering function callthrough
  
 
  local op3_data = {}
  local op2_data = {}
  local op1_data = {}
  local sin = math.sin
  local sinstep = ((2 * math.pi) / VA_CYCLE_LEN) * self.multipliers[3]
  local length = self:CalculateSampleLength(3)
  local ramp_step
  local ramp_time
  local offset
  local time_offset
  
  --
  -- operator 3
  --
  -- populate cycles
  for i = 0, length-1 do
    table.insert(op3_data, sin(i*sinstep))
  end
    
  
  -- ramp from start to peak over attack time
  if self.attack_values[3] > 0 then
    ramp_time = length, self.attack_values[3] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.peak_values[3] - self.start_values[3]) / 127)/ ramp_time
    offset = self.start_values[3] / 127
      
    for i = 1, ramp_time do
      if op3_data[i] then
        op3_data[i] = op3_data[i] * ((ramp_step * i) + offset)
      end
    end
  end
    
  -- ramp from peak to hold over decay time
  if self.decay_values[3] > 0 then
    ramp_time = self.decay_values[3] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.hold_values[3] - self.peak_values[3]) / 127)/ ramp_time
    offset = self.peak_values[3] / 127
    time_offset = 1 + (self.attack_values[3] * 2 * VA_CYCLE_LEN)
      
    for i = time_offset, time_offset+ramp_time do
      if op3_data[i] then
        op3_data[i] = op3_data[i] * ((ramp_step * i) + offset)
      end
    end
  end
    
    
  -- hold scaling
  time_offset = 1 + ((self.attack_values[3] + self.decay_values[3]) * 2 * VA_CYCLE_LEN)
  offset = self.hold_values[3] / 127
    
  for i = time_offset, #op3_data do
    if op3_data[i] then
      op3_data[i] = op3_data[i] * offset
    end
  end
  
  --
  -- operator 2
  --
  length = self:CalculateSampleLength(1)
  sinstep = ((2 * math.pi) / VA_CYCLE_LEN) * self.multipliers[2]
  
  -- populate cycles
  if length > #op3_data then
  
    -- mod part
    for i = 0, #op3_data-1 do
      table.insert(op2_data, sin((i*sinstep) +op3_data[i+1]))
    end
    
    -- unmod part
    for i = 0, length-#op3_data-1 do
      table.insert(op2_data, sin(i*sinstep))
    end
    
  else
    -- all mod
    for i = 0, length-1 do
      table.insert(op2_data, sin((i*sinstep) + op3_data[i+1]))
    end
  end

  -- ramp from start to peak over attack time
  if self.attack_values[2] > 0 then
    ramp_time = self.attack_values[2] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.peak_values[2] - self.start_values[2]) / 127)/ ramp_time
    offset = self.start_values[2] / 127
      
    for i = 1, ramp_time do
      if op2_data[i] then
        op2_data[i] = op2_data[i] * ((ramp_step * i) + offset)
      end
    end
  end
    
  -- ramp from peak to hold over decay time
  if self.decay_values[2] > 0 then
    ramp_time = self.decay_values[2] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.hold_values[2] - self.peak_values[2]) / 127)/ ramp_time
    offset = self.peak_values[2] / 127
    time_offset = 1 + (self.attack_values[2] * 2 * VA_CYCLE_LEN)
      
    for i = time_offset, time_offset+ramp_time do
      if op2_data[i] then
        op2_data[i] = op2_data[i] * ((ramp_step * (i-time_offset)) + offset)
      end
    end
  end
    
    
  -- hold scaling
  time_offset = 1 + ((self.attack_values[2] + self.decay_values[2]) * 2 * VA_CYCLE_LEN)
  offset = self.hold_values[2] / 127
    
  for i = time_offset, #op2_data do
    if op2_data[i] then
      op2_data[i] = op2_data[i] * offset
    end
  end

  
  --
  -- operator 1
  --
  length = self:CalculateSampleLength(1)
  sinstep = ((2 * math.pi) / VA_CYCLE_LEN) * self.multipliers[1]
  
  -- populate cycles
  if length > #op2_data then
  
    -- mod part
    for i = 0, #op2_data-1 do
      table.insert(op1_data, sin((i*sinstep) +op2_data[i+1]))
    end
    
    -- unmod part
    for i = 0, length-#op2_data-1 do
      table.insert(op1_data, sin(i*sinstep))
    end
    
  else
    -- all mod
    for i = 0, length-1 do
      table.insert(op1_data, sin((i*sinstep) +op2_data[i+1]))
    end
  end

  -- ramp from start to peak over attack time
  if self.attack_values[1] > 0 then
    ramp_time = self.attack_values[1] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.peak_values[1] - self.start_values[1]) / 127)/ ramp_time
    offset = self.start_values[1] / 127
    
    for i = 1, ramp_time do
      op1_data[i] = op1_data[i] * ((ramp_step * i) + offset)
    end
  end

  -- ramp from peak to hold over decay time
  if self.decay_values[1] > 0 then
    ramp_time = self.decay_values[1] * 2 * VA_CYCLE_LEN
    ramp_step = ((self.hold_values[1] - self.peak_values[1]) / 127)/ ramp_time
    offset = self.peak_values[1] / 127
    time_offset = (self.attack_values[1] * 2 * VA_CYCLE_LEN) + 1
    
    for i = time_offset, time_offset+ramp_time do
      op1_data[i] = op1_data[i] * ((ramp_step * (i-time_offset)) + offset)
    end
  end

  
  -- hold scaling
  time_offset = 1 + ((self.attack_values[1] + self.decay_values[1]) * 2 * VA_CYCLE_LEN)
  offset = self.hold_values[1] / 127
  
  for i = time_offset, time_offset + (2 * VA_CYCLE_LEN) - 1 do
    op1_data[i] = op1_data[i] * offset
  end

  -- transfer
  local sb = self.sample.sample_buffer
  
  sb:create_sample_data(44000, 32, 1, #op1_data)
  
  -- transfer samples
  sb:prepare_sample_data_changes()
  for i = 1, #op1_data do
    sb:set_sample_data(1, i, op1_data[i])
  end
  sb:finalize_sample_data_changes()
  
  -- set looping

  self.sample.loop_start = ((self.attack_values[1] + self.decay_values[1] + 1) * 2 * VA_CYCLE_LEN) - 8 - VA_CYCLE_LEN
  self.sample.loop_end = ((self.attack_values[1] + self.decay_values[1]  + 1) * 2 * VA_CYCLE_LEN)- 9
  
  -- store parameters
  self.sample.name = table_to_string({'FM4',
                                      self.multipliers[1],
                                      self.start_values[1],
                                      self.attack_values[1],
                                      self.peak_values[1],
                                      self.decay_values[1],
                                      self.hold_values[1],
                                      self.multipliers[2],
                                      self.start_values[2],
                                      self.attack_values[2],
                                      self.peak_values[2],
                                      self.decay_values[2],
                                      self.hold_values[2],
                                      self.multipliers[3],
                                      self.start_values[3],
                                      self.attack_values[3],
                                      self.peak_values[3],
                                      self.decay_values[3],
                                      self.hold_values[3]})
                                      
  self:SetView()
end


function FmOscillator:SetView()
  -- maybe set view
  if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR then
    renoise.song().selected_instrument_index = self.instrument_index
    renoise.song().selected_sample_index = self.sample_index
    if renoise.song().selected_sample.sample_buffer.has_sample_data then
      renoise.song().selected_sample.sample_buffer.display_range = {1, renoise.song().selected_sample.sample_buffer.number_of_frames}
    end
  end
end
