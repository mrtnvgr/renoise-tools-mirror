--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- Programmable Arpeggiator class
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
Arpeggiator class handles all arp parameters

Arpeggiator.ui
Arpeggiator.ui_triggers[]
Arpeggiator.ui_array
Arpeggiator.ui_length
Arpeggiator.ui_rate
Arpeggiator.ui_current_note
Arpeggiator.ui_apply_vol
Arpeggiator.ui_apply_filter
Arpeggiator.ui_apply_pitch
Arpeggiator.selected_step_index
Arpeggiator.steps[] = {trigger, pitch}
Arpeggiator.length
Arpeggiator.apply_vol
Arpeggiator.apply_filter
Arpeggiator.apply_pitch
Arpeggiator:UpdateStepArray()
Arpeggiator:SetArpLength()
Arpeggiator:SetArpRate()
Arpeggiator:SetCurrentNote()
Arpeggiator:SelectStep()
Arpeggiator:GetStepLengths()
Arpeggiator:GetArpTickLength()
Arpeggiator:SetApplyVol()
Arpeggiator:GetApplyVol()
Arpeggiator:SetApplyFilter()
Arpeggiator:GetApplyFilter()
Arpeggiator:SetApplyPitch()
Arpeggiator:GetApplyPitch()
Arpeggiator:Apply()
]]--




--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'Arpeggiator'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function Arpeggiator:__init(vb, inst_index, sample_index, arp_object)

  self.vb = vb
  self.instrument_index = inst_index
  self.sample_index = sample_index
  self.arp = arp_object
  self.sample = renoise.song().instruments[inst_index].samples[sample_index]
  
  self.ui_array1 = self.vb:horizontal_aligner{
    mode = 'justify',
    spacing = 2,
  }
  
  self.ui_array2 = self.vb:horizontal_aligner{
    mode = 'justify',
    spacing = 2,
  }
  
  self.length = 16
  self.arp_rate = 6
  self.ui_triggers = {}
  self.steps = {{true, 0.5}, {false, 0.5}, {false, 0.5}, {false, 0.5},
                {false, 0.5}, {false, 0.5}, {false, 0.5}, {false, 0.5},
                {false, 0.5}, {false, 0.5}, {false, 0.5}, {false, 0.5}, 
                {false, 0.5}, {false, 0.5}, {false, 0.5}, {false, 0.5}}
  self.selected_step_index = 1
  self.apply_vol = false
  self.apply_filter = false
  self.apply_pitch = false
  
  for i = 1, 8 do
    table.insert(self.ui_triggers,
                 self.vb:button {
                   text = '',
                   color = COLOUR_BLACK,
                   tooltip = 'Arp Step '..tostring(i),
                   notifier = function()
                     self:SelectStep(i)
                   end
                 })
    self.ui_array1:add_child(self.ui_triggers[i])

  end
  
  for i = 9, 16 do
    table.insert(self.ui_triggers,
                 self.vb:button {
                   text = '',
                   color = COLOUR_BLACK,
                   tooltip = 'Arp Step '..tostring(i),
                   notifier = function()
                     self:SelectStep(i)
                   end
                 })
    self.ui_array2:add_child(self.ui_triggers[i])
  end
  
  self.steps[1][1] = true
  
  self.ui_length = self.vb:valuebox{
    min = 2,
    max = #self.ui_triggers,
    value = 16,
    width = 50,
    tooltip = 'Arp Length',
    notifier = function(v)
      self:SetArpLength(v)
    end
  }
  
  self.ui_rate = self.vb:valuebox{
    min = 2,
    max = 48,
    value = 6,
    width = 50,
    tooltip = 'Arp Rate',
    notifier = function(v)
      self:SetArpRate(v)
    end
  }
  
  self.ui_current_note = self.vb:valuebox{
    min = -12,
    max = 12,
    value = 0,
    width = 50,
    tooltip = 'Current Note Offset',
    notifier = function(v)
      self:SetCurrentNote(v)
    end
  }
  
  self.ui_apply_vol = self.vb:checkbox{
    value = false,
    tooltip = 'Apply Arp to Volume',
    notifier = function(v)
      self:SetApplyVol(v)
    end
  }
  
  self.ui_apply_pitch = self.vb:checkbox{
    value = false,
    tooltip = 'Apply Arp to Pitch',
    notifier = function(v)
      self:SetApplyPitch(v)
    end
  }
  
  self.ui_apply_filter = self.vb:checkbox{
    value = false,
    tooltip = 'Apply Arp to Filter',
    notifier = function(v)
      self:SetApplyFilter(v)
    end
  }

  self.ui = self.vb:column{
    spacing = 5,
    margin = 6,

    self.ui_array1,
    self.ui_array2,
      
    self.vb:horizontal_aligner{
      mode = 'justify',
      
      self.vb:text{
        text = 'Len:',
      }, 
      self.ui_length,

      self.vb:text{
        text = 'Rate:',
      },
      self.ui_rate,

    },
    
    self.vb:horizontal_aligner{
      mode = 'justify',
      self.vb:text{
        text = 'Selected Step Note:',
      },
      self.ui_current_note,
    },
    
    self.vb:horizontal_aligner{
      mode = 'justify',
      self.vb:text{
        text = 'Volume:',
      },
      self.ui_apply_vol,
      self.vb:text{
        text = 'Pitch:',
      },
      self.ui_apply_pitch,
      self.vb:text{
        text = 'Filter:',
      },
      self.ui_apply_filter,
    },
  }
  
  --
  -- Read parameters
  --

  -- load settings
  if string.sub(self.sample.name, 1, 4) == "AR4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 38 then
      -- seems ok
      self.arp_rate = tonumber(settings[2])
      self.ui_rate.value = self.arp_rate
      self.length = tonumber(settings[3])
      self.ui_length.value = self.length
      if settings[4] == 'true' then
        self.apply_vol = true
      else
        self.apply_vol = false
      end
      self.ui_apply_vol.value = self.apply_vol
      if settings[5] == 'true' then
        self.apply_pitch = true
      else
        self.apply_pitch = false
      end
      self.ui_apply_pitch.value = self.apply_pitch
      if settings[6] == 'true' then
        self.apply_filter = true
      else
        self.apply_filter = false
      end
      self.ui_apply_filter.value = self.apply_filter      
      -- parse table
      for i = 1, 16 do
        if settings[i+6] == 'L' then
          self.steps[i][1] = false
        else
          self.steps[i][1] = true
        end
      end
      for i = 1, 16 do
        self.steps[i][2] = tonumber(settings[i+6+16])
      end
    end
  end

  self:UpdateStepArray()
end


function Arpeggiator:AttachEnvelopes(vol_env, filter_env)
  -- Attach the envelopes to call updates
  
  self.vol_env = vol_env
  self.filter_env = filter_env
  
  self:Apply()
end


function Arpeggiator:SetCurrentNote(pitch)
  -- Sets the current steps pitch
  
  self.steps[self.selected_step_index][2] = (pitch / 24) + 0.5
  
  self:Apply()
end


function Arpeggiator:GetCurrentNote()
  -- Returns the current note as a vb scaled value
  
  return ((self.steps[self.selected_step_index][2] - 0.5) * 24)
end


function Arpeggiator:UpdateStepArray()
  for i = 1, self:GetArpLength() do
    if self.steps[i][1] == true then
      self.ui_triggers[i].color = COLOUR_GREEN
    else
      self.ui_triggers[i].color = COLOUR_YELLOW
    end
  end
  
  if self:GetArpLength() < 16 then
    for i = self:GetArpLength()+1, 16 do
      self.ui_triggers[i].color = COLOUR_BLACK
    end
  end
  
  if self.steps[self.selected_step_index][1] == true then
    self.ui_triggers[self.selected_step_index].color = COLOUR_DBLUE
  else
    self.ui_triggers[self.selected_step_index].color = COLOUR_LBLUE
  end
end

function Arpeggiator:SetArpRate(v)

  self.arp_rate = v
  self:Apply()
end


function Arpeggiator:GetArpRate()

  return self.arp_rate
end



function Arpeggiator:SetArpLength(v)

  self.length = v
  
  -- move selected step if required
  if self.selected_step_index > self.length then
    self:SelectStep(self.length)
  end
  
  self:UpdateStepArray()
  self:Apply()
end


function Arpeggiator:GetArpLength()

  return self.length
end


function Arpeggiator:SetApplyVol(state)

  self.apply_vol = state
  
  self:Apply()
end


function Arpeggiator:GetApplyVol()

  return self.apply_vol
end


function Arpeggiator:SetApplyPitch(state)

  self.apply_pitch = state
  
  self:Apply()
end


function Arpeggiator:GetApplyPitch()

  return self.apply_pitch
end


function Arpeggiator:SetApplyFilter(state)

  self.apply_filter = state
  
  self:Apply()
end


function Arpeggiator:GetApplyFilter()

  return self.apply_filter
end


function Arpeggiator:SelectStep(index)

  -- ignore unused cells
  if index > self.length then
    return
  end

  if self.selected_step_index == index then
    -- second click changes playmode
    self.steps[index][1] = not self.steps[index][1]
  else
    -- select
    self.selected_step_index = index
    self.ui_current_note.value = self:GetCurrentNote()
  end
  
  self:UpdateStepArray()
  self:Apply()
end


function Arpeggiator:GetUI()
  
  return self.ui
end


function Arpeggiator:GetStepLengths()
  -- Returns a table of step lengths in ticks
  
  local step_table = {}
  local start_index = 1
  local end_index = self.length
  
  -- find distance from start_pointer to next trigger
  for i = 2, self.length do
    if (self.steps[i][1] == true) then
      end_index = i
      table.insert(step_table, (end_index - start_index) * self.arp_rate)
      start_index = end_index
      end_index = self.length
    end
  end
  
  -- final step
  table.insert(step_table, (end_index - start_index + 1) * self.arp_rate)
  
  return step_table
end


function Arpeggiator:GetArpTickLength()
  -- Returns the arp length in ticks
  
  return (self.arp_rate * self.length)
end
  


function Arpeggiator:Apply()
  -- Apply the arp to the required envelopes
  
  local env
  local env_len = math.max(6, (self.arp_rate * self.length) + 1)
  local step = self.arp_rate

  -- pitch
  if self.apply_pitch then

    --
    -- pitch envelope
    --
    env = renoise.song().instruments[self.instrument_index].sample_envelopes.pitch
    
    -- clear existing points
    env:clear_points()
    
    -- set length & loop points
    env.length = env_len
    env.loop_start = 1
    env.loop_end = (self.arp_rate * self.length)
    env.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
    
    -- set mode
    env.play_mode = renoise.InstrumentEnvelope.PLAYMODE_POINTS
    
    -- add points
    for i = 0, self.length - 1 do
      --if self.steps[i+1][1] then
        env:add_point_at(1 + (i*step), self.steps[i+1][2])
      --end
    end
    
    -- enable
    env.enabled = true
  else
    --
    -- pitch envelope
    --
    env = renoise.song().instruments[self.instrument_index].sample_envelopes.pitch
    
    -- clear existing points
    env:clear_points()
    env.enabled = false
  end
 
  -- Update volume envelope
  if self.vol_env then
    self.vol_env:Apply()
  end
  
  -- filter env
  if self.filter_env then
    self.filter_env:Apply()
  end
  
   
  -- dump parameters
  local p_table = {}
  for i = 1, 16 do
    if self.steps[i][1] then
      table.insert(p_table, 'T')
    else
      table.insert(p_table, 'L') -- not played - legato
    end
  end
  

  self.sample.name = table_to_string({'AR4',
                                      tostring(self.arp_rate),
                                      tostring(self.length),
                                      tostring(self.apply_vol),
                                      tostring(self.apply_pitch),
                                      tostring(self.apply_filter),
                                      tostring(p_table[1]),
                                      tostring(p_table[2]),
                                      tostring(p_table[3]),
                                      tostring(p_table[4]),
                                      tostring(p_table[5]),
                                      tostring(p_table[6]),
                                      tostring(p_table[7]),
                                      tostring(p_table[8]),
                                      tostring(p_table[9]),
                                      tostring(p_table[10]),
                                      tostring(p_table[11]),
                                      tostring(p_table[12]),
                                      tostring(p_table[13]),
                                      tostring(p_table[14]),
                                      tostring(p_table[15]),
                                      tostring(p_table[16]),
                                      tostring(self.steps[1][2]),
                                      tostring(self.steps[2][2]),
                                      tostring(self.steps[3][2]),
                                      tostring(self.steps[4][2]),
                                      tostring(self.steps[5][2]),
                                      tostring(self.steps[6][2]),
                                      tostring(self.steps[7][2]),
                                      tostring(self.steps[8][2]),
                                      tostring(self.steps[9][2]),
                                      tostring(self.steps[10][2]),
                                      tostring(self.steps[11][2]),
                                      tostring(self.steps[12][2]),
                                      tostring(self.steps[13][2]),
                                      tostring(self.steps[14][2]),
                                      tostring(self.steps[15][2]),
                                      tostring(self.steps[16][2])
                                      })
end
