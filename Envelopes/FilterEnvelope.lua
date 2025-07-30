--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- FilterEnvelope class
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
FilterEnvelope class handles all filter parameters

FilterEnvelope.ui                     -- viewbuilder user interface
FilterEnvelope.ui_attack
FilterEnvelope.ui_hold
FilterEnvelope.ui_decay1
FilterEnvelope.ui_break
FilterEnvelope.ui_decay2
FilterEnvelope.ui_sustain
FilterEnvelope.ui_release
FilterEnvelope.ui_cutoff_lfo_rate
FilterEnvelope.ui_cutoff_lfo_depth
FilterEnvelope.ui_resonance_lfo_rate
FilterEnvelope.ui_resonance_lfo_depth
FilterEnvelope.ui_filter_type
FilterEnvelope:SetAttack()            -- sets the attack time     [0..24]
FilterEnvelope:GetAttack()            -- returns the attack time
FilterEnvelope:SetHold()              -- sets the hold time       [0..24]
FilterEnvelope:GetHold()              -- returns the hold time
FilterEnvelope:SetDecay1()            -- sets the decay1 time     [1..24]
FilterEnvelope:GetDecay1()            -- returns the decay1 time
FilterEnvelope:SetBreak()             -- sets the break level     [0..1]  (inverted)
FilterEnvelope:GetBreak()             -- returns the break level
FilterEnvelope:SetDecay2()            -- sets the decay2 time     [1..24]
FilterEnvelope:GetDecay2()            -- returns the decay2 time
FilterEnvelope:SetSustain()           -- sets the sustain level   [0..1]
FilterEnvelope:GetSustain()           -- returns the sustain level
FilterEnvelope:SetRelease()           -- sets the release time    [0..24]
FilterEnvelope:GetRelease()           -- returns the release time
FilterEnvelope:SetCutoffLfoRate()
FilterEnvelope:GetCutoffLfoRate()
FilterEnvelope:SetCutoffLfoDepth()
FilterEnvelope:GetCutoffLfoDepth()
FilterEnvelope:SetResonanceLfoRate()
FilterEnvelope:GetResonanceLfoRate()
FilterEnvelope:SetResonanceLfoDepth()
FilterEnvelope:GetResonanceLfoDepth()
FilterEnvelope:SetFilterType(enum)
FilterEnvelope:GetFilterType()
FilterEnvelope:SetResonance()
FilterEnvelope:GetResonance()
FilterEnvelope:SetVelocityMod()
FilterEnvelope:Reset()                -- resets the envelope
FilterEnvelope:Apply()
FilterEnvelope:ApplyLfo()
FilterEnvelope:GetUI()                -- returns the user interface view
]]--




--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'FilterEnvelope'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function FilterEnvelope:__init(vb, inst_index, sample_index, arp_object)
  -- FilterEnvelope init
  
  self.vb = vb
  self.instrument_index = inst_index
  self.sample_index = sample_index
  self.arp = arp_object
  self.sample = renoise.song().instruments[inst_index].samples[sample_index]

  self.attack = 0
  self.hold = 0
  self.decay1 = 0
  self.brck = 0
  self.decay2 = 0
  self.sustain = 1
  self.release = 0
  self.resonance = 0
  self.cutoff_lfo_rate = 0
  self.cutoff_lfo_depth = 0
  self.resonance_lfo_rate = 0
  self.resonance_lfo_depth = 0
  self.velocity_mod = 0

  -- create ui
  self.ui_attack = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 24,
    value = 0,
    tooltip = 'Attack Time',
    notifier = function(v)
      if math.floor(v) ~= self:GetAttack() then
        self:SetAttack(math.floor(v))
      end
    end
  }

  self.ui_hold = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 24,
    value = 0,
    tooltip = 'Hold Time',
    notifier = function(v)
      if math.floor(v) ~= self:GetHold() then
        self:SetHold(math.floor(v))
      end
    end
  }
  
  self.ui_decay1 = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 24,
    value = 0,
    tooltip = 'Decay Time to Break',
    notifier = function(v)
      if math.floor(v) ~= self:GetDecay1() then
        self:SetDecay1(math.floor(v))
      end
    end
  }
  
  self.ui_break = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 1,
    value = 0,
    tooltip = 'Break Level',
    notifier = function(v)
      self:SetBreak(v)
    end
  }
  
  self.ui_decay2 = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 24,
    value = 0,
    tooltip = 'Decay Time to Sustain',
    notifier = function(v)
      if math.floor(v) ~= self:GetDecay2() then
        self:SetDecay2(math.floor(v))
      end
    end
  }
  
  self.ui_sustain = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 1,
    value = 0,
    tooltip = 'Sustain Level',
    notifier = function(v)
      self:SetSustain(v)
    end
  }
  
  self.ui_release = self.vb:minislider{
    width = 18,
    height = 100,
    min = 0,
    max = 24,
    value = 0,
    tooltip = 'Release Time',
    notifier = function(v)
      if math.floor(v) ~= self:GetRelease() then
        self:SetRelease(math.floor(v))
      end
    end
  }
  
  self.ui_cutoff_lfo_rate = self.vb:rotary{
    min = 0,
    max = 64,
    value = 0,
    tooltip = 'Cutoff LFO Rate',
    notifier = function(v)
      if math.floor(v) ~= self:GetCutoffLfoRate() then
        self:SetCutoffLfoRate(math.floor(v))
      end
    end
  } 
  
  self.ui_cutoff_lfo_depth = self.vb:rotary{
    min = 0,
    max = 32,
    value = 0,
    tooltip = 'Cutoff LFO Depth',
    notifier = function(v)
      if math.floor(v) ~= self:GetCutoffLfoDepth() then
        self:SetCutoffLfoDepth(math.floor(v))
      end
    end
  } 
  
  self.ui_resonance_lfo_rate = self.vb:rotary{
    min = 0,
    max = 64,
    value = 0,
    tooltip = 'Resonance LFO Rate',
    notifier = function(v)
      if math.floor(v) ~= self:GetResonanceLfoRate() then
        self:SetResonanceLfoRate(math.floor(v))
      end
    end
  } 
  
  self.ui_resonance_lfo_depth = self.vb:rotary{
    min = 0,
    max = 32,
    value = 0,
    tooltip = 'Resonance LFO Depth',
    notifier = function(v)
      if math.floor(v) ~= self:GetResonanceLfoDepth() then
        self:SetResonanceLfoDepth(math.floor(v))
      end
    end
  }
  
  self.ui_filter_type = self.vb:popup{
    width = 70,
    items = FILTER_TYPES,
    tooltip = 'Filter Type',
    notifier = function(v)
      self:SetFilterType(v)
    end
  }
  
  self.ui_resonance = self.vb:rotary{
    min = 0,
    max = 1,
    value = 0,
    tooltip = 'Resonance',
    notifier = function(v)
      self:SetResonance(v)
    end
  }
  
  self.ui_velocity_mod = self.vb:rotary{
    min = -1,
    max = 1,
    value = 0,
    tooltip = 'Velocity Modifier',
    notifier = function(v)
      self:SetVelocityMod(v)
    end
  }
  
  self.ui = self.vb:column{
    spacing = 6,
    margin = 2,
    
    self.vb:horizontal_aligner{
      spacing = 3,
      mode = 'justify',
      
      self.vb:column{
        self.ui_attack,
        self.vb:text {
          text = ' A',
        },
      },
      self.vb:column{
        self.ui_hold,
        self.vb:text {
          text = ' H',
        },
      },
      self.vb:column{
        self.ui_decay1,
        self.vb:text {
          text = ' D',
        },
      },
      self.vb:column{
        self.ui_break,
        self.vb:text {
          text = ' B',
        },
      },
      self.vb:column{
        self.ui_decay2,
        self.vb:text {
          text = ' D',
        },
      },
      self.vb:column{
        self.ui_sustain,
        self.vb:text {
          text = ' S',
        },
      },
      self.vb:column{
        self.ui_release,
        self.vb:text {
          text = ' R',
        },
      },
      
      -- cutoff lfo
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_cutoff_lfo_rate,
        self.vb:text {
          text = ' Rate',
        },
        self.ui_cutoff_lfo_depth,
        self.vb:text {
          text = 'Depth',
        },
      },
      
      -- resonance lfo
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_resonance_lfo_rate,
        self.vb:text {
          text = ' Rate',
        },
        self.ui_resonance_lfo_depth,
        self.vb:text {
          text = 'Depth',
        },
      },
      
      self.vb:vertical_aligner {
        mode = 'justify',
        self.vb:horizontal_aligner {
          self.ui_filter_type,
        },
        self.vb:horizontal_aligner {
          self.vb:vertical_aligner {
            spacing = 2,
            mode = 'center',
            self.ui_resonance,
            self.vb:text {
              text = 'Reson',
            },
          },
          self.vb:vertical_aligner {
            spacing = 2,
            mode = 'center',
            self.ui_velocity_mod,
            self.vb:text {
              text = '  Vel',
            },
          },
        },
      },
    },
  }
  
  -- load settings
  if string.sub(self.sample.name, 1, 4) == "FE4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 13 then
      -- seems ok
      self.attack = tonumber(settings[2])
      self.ui_attack.value = self.attack
      self.hold = tonumber(settings[3])
      self.ui_hold.value = self.hold
      self.decay1 = tonumber(settings[4])
      self.ui_decay1.value = self.decay1
      self.brck = tonumber(settings[5])
      self.ui_break.value = self.brck
      self.decay2 = tonumber(settings[6])
      self.ui_decay2.value = self.decay2
      self.sustain = tonumber(settings[7])
      self.ui_sustain.value = self.sustain
      self.release = tonumber(settings[8])
      self.ui_release.value = self.release
      
      self.velocity_mod = tonumber(settings[9])
      self.ui_velocity_mod.value = -self.velocity_mod/127
      
      self.cutoff_lfo_depth = tonumber(settings[10])
      self.ui_cutoff_lfo_depth.value = self.cutoff_lfo_depth
      self.cutoff_lfo_rate = tonumber(settings[11])
      self.ui_cutoff_lfo_rate.value = self.cutoff_lfo_rate
          
      self.resonance_lfo_depth = tonumber(settings[12])
      self.ui_resonance_lfo_depth.value = self.resonance_lfo_depth
      self.resonance_lfo_rate = tonumber(settings[13])
      self.ui_resonance_lfo_rate.value = self.resonance_lfo_rate
      
      self.ui_filter_type.value = self:GetFilterType()
    else
      -- Reset to defaults
      self:Reset()
    end
  else
    -- Reset to defaults
    self:Reset()
  end
end

function FilterEnvelope:Reset()
  -- reset

  self.attack = 0
  self.ui_attack.value = self.attack
  self.hold = 0
  self.ui_hold.value = self.hold
  self.decay1 = 0
  self.ui_decay1.value = self.decay1
  self.brck = 0
  self.ui_break.value = self.brck
  self.decay2 = 0
  self.ui_decay2.value = self.decay2
  self.sustain = 1
  self.ui_sustain.value = self.sustain
  self.release = 0
  self.ui_release.value = self.release
  
  self.cutoff_lfo_rate = 0
  self.ui_cutoff_lfo_rate.value = self.cutoff_lfo_rate
  self.cutoff_lfo_depth = 0
  self.ui_cutoff_lfo_depth.value = self.cutoff_lfo_depth

  self.resonance_lfo_rate = 0
  self.ui_resonance_lfo_rate.value = self.resonance_lfo_rate
  self.resonance_lfo_depth = 0
  self.ui_resonance_lfo_depth.value = self.resonance_lfo_depth
  
  self.ui_filter_type.value = 1
  self:SetFilterType(1)
  
  self.ui_resonance.value = 0
  self:SetResonance(0)
  
  self.velocity_mod = 0
  
  self:Apply()
  self:ApplyLfo()
  
end


function FilterEnvelope:SetAttack(v)
  -- sets the envelope attack
  
  self.attack = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope attack time set to to %d ticks', v))
  self:Apply()
end


function FilterEnvelope:GetAttack()
  -- Returns the envelope attack
  
  return self.attack
end


function FilterEnvelope:SetHold(v)
  -- sets the envelope hold
  
  self.hold = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope hold time set to to %d ticks', v))
  self:Apply()
end


function FilterEnvelope:GetHold()
  -- Returns the envelope hold
  
  return self.hold
end


function FilterEnvelope:SetDecay1(v)
  -- sets the envelope Decay1
  
  self.decay1 = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope decay 1 time set to to %d ticks', v))
  self:Apply()
end


function FilterEnvelope:GetDecay1()
  -- Returns the envelope Decay1
  
  return self.decay1
end


function FilterEnvelope:SetBreak(v)
  -- sets the envelope break
  
  self.brck = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope break level set to to %d', v*100))
  self:Apply()
end


function FilterEnvelope:GetBreak()
  -- Returns the envelope break
  
  return self.brck
end


function FilterEnvelope:SetDecay2(v)
  -- sets the envelope Decay2
  
  self.decay2 = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope decay 2 time set to to %d ticks', v))
  self:Apply()
end


function FilterEnvelope:GetDecay2()
  -- Returns the envelope Decay2
  
  return self.decay2
end


function FilterEnvelope:SetSustain(v)
  -- sets the envelope sustain
  
  self.sustain = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope break level set to to %d', v*100))
  self:Apply()
end


function FilterEnvelope:GetSustain()
  -- Returns the envelope sustain
  
  return self.sustain
end


function FilterEnvelope:SetRelease(v)
  -- sets the envelope release
  
  self.release = v
  renoise.app():show_status(string.format('ReSynth: Filter envelope release time set to to %d ticks', v))
  self:Apply()
end


function FilterEnvelope:GetRelease()
  -- Returns the envelope release
  
  return self.release
end


function FilterEnvelope:SetCutoffLfoRate(v)
  -- Sets the lfo rate

  self.cutoff_lfo_rate = v
  renoise.app():show_status(string.format('ReSynth: Filter cutoff LFO rate set to to %d ticks', v))
  self:ApplyLfo()
end


function FilterEnvelope:GetCutoffLfoRate()
  -- returns the lfo rate

  return self.cutoff_lfo_rate
end


function FilterEnvelope:SetCutoffLfoDepth(v)
  -- Sets the lfo depth

  self.cutoff_lfo_depth = v
  renoise.app():show_status(string.format('ReSynth: Filter cutoff LFO depth set to to %d', v))
  self:ApplyLfo()
end


function FilterEnvelope:GetCutoffLfoDepth()
  -- returns the lfo depth

  return self.cutoff_lfo_depth
end


function FilterEnvelope:SetResonanceLfoRate(v)
  -- Sets the lfo rate

  self.resonance_lfo_rate = v
  renoise.app():show_status(string.format('ReSynth: Filter resonance LFO rate set to to %d ticks', v))
  self:ApplyLfo()
end


function FilterEnvelope:GetResonanceLfoRate()
  -- returns the lfo rate

  return self.resonance_lfo_rate
end


function FilterEnvelope:SetResonanceLfoDepth(v)
  -- Sets the lfo depth

  self.resonance_lfo_depth = v
  renoise.app():show_status(string.format('ReSynth: Filter resonance LFO depth set to to %d', v))
  self:ApplyLfo()
end


function FilterEnvelope:GetResonanceLfoDepth()
  -- returns the lfo depth

  return self.resonance_lfo_depth
end


function FilterEnvelope:SetVelocityMod(v)

  self.velocity_mod = math.floor((-v*127)+0.5)
  renoise.app():show_status(string.format('ReSynth: Filter cutoff velocity mod set to to %d', math.floor((v*127)+0.5)))
  self:Apply()
end


function FilterEnvelope:Apply()
  -- Applies the envelope
  
  local env = renoise.song().instruments[self.instrument_index].sample_envelopes.cutoff

  -- consider the arp
  if self.arp:GetApplyFilter() then
    local arp_step_lengths = self.arp:GetStepLengths()

    -- init envelope parameters
    env:clear_points()
    env.enabled = true
    env.length = clamp(self.arp:GetArpTickLength(), 6, 1000)
    env.sustain_enabled = false
    
    -- loop through arp steps, drawing in the envelope each time
    local offset = 0
    
    for i = 1, #arp_step_lengths do

      -- start of attack ramp
      if self.attack > 0 then
        env:add_point_at(offset+1, 0)
      end
      
      -- end of attack ramp
      if self.attack < arp_step_lengths[i] then
        env:add_point_at(offset+1+self.attack, 1)
      else
        -- average point here at length - 1
        env:add_point_at(offset+1+arp_step_lengths[i]-1, (arp_step_lengths[i]-1)*((1-0)/self.attack))
      end
      
      -- end of hold period
      if self.hold > 0 then
        if self.attack + self.hold < arp_step_lengths[i] then
          env:add_point_at(offset+1+self.attack+self.hold, 1)
        else
          -- only add an average point if not one already present
          if not env:has_point_at(offset+1+arp_step_lengths[i]-1) then
            env:add_point_at(offset+1+arp_step_lengths[i]-1, 1)
          end
        end
      end
      
      -- decay1 to break level
      if self.brck > 0 then
        if self.decay1 > 0 then
          if self.attack + self.hold + self.decay1 < arp_step_lengths[i] then
            env:add_point_at(offset+1+self.attack+self.hold+self.decay1, 1-self.brck)
          else
            -- only add an average point if not one already present
            if not env:has_point_at(offset+1+arp_step_lengths[i]-1) then
              env:add_point_at(offset+1+arp_step_lengths[i]-1,
                               1+((arp_step_lengths[i]-1 - self.attack - self.hold)*
                               (((1-self.brck)-1)/self.decay1)))
            end
          end
        end
      end
      
      -- decay2 to sustain
      if self.attack + self.hold + self.decay1 + self.decay2 < arp_step_lengths[i] then
        env:add_point_at(offset+1+self.attack+self.hold+self.decay1+self.decay2, self.sustain)
        env:add_point_at(offset+1+arp_step_lengths[i]-1, self.sustain)
      else
        -- only add an average point if not one already present
        if not env:has_point_at(offset+1+arp_step_lengths[i]-1) then
          
          env:add_point_at(offset+1+arp_step_lengths[i]-1,
                           1-self.brck+(((arp_step_lengths[i]-1 - self.attack - self.hold - self.decay1)*
                           ((self.sustain - (1-self.brck))/self.decay2))))
        end
      end        
            
      offset = offset + arp_step_lengths[i]
    end
    
    -- set arp loop
    env.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
    env.loop_start = 1
    env.loop_end = clamp(self.arp:GetArpTickLength(), 6, 1000)
    
  else
    env:clear_points()
    env.enabled = true
    env.length = clamp(1+self.attack+self.hold+self.decay1+self.decay2+self.release, 6, 1000)
    env.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
    
    -- start of attack ramp
    if self.attack > 0 then
      env:add_point_at(1, 0)
    end
    
    -- end of attack ramp
    env:add_point_at(1+self.attack, 1)
    
    -- end of hold period
    if self.hold > 0 then
      env:add_point_at(1+self.attack+self.hold, 1)
    end
    
    -- decay1 to break level
    if self.brck > 0 then
      if self.decay1 > 0 then
        env:add_point_at(1+self.attack+self.hold+self.decay1, 1-self.brck)
      end
    end
    
    -- decay2 to sustain
    env:add_point_at(1+self.attack+self.hold+self.decay1+self.decay2, self.sustain)
    env.sustain_position = 1+self.attack+self.hold+self.decay1+self.decay2
    env.sustain_enabled = true
    
    -- release
    if self.release > 0 then
      env:add_point_at(1+self.attack+self.hold+self.decay1+self.decay2+self.release, 0)
    end
  end
  
  -- calculated scale fade amount from release value
  env.fade_amount = clamp(4096 - (math.floor(self.release * 165)), 0, 4095)
  
  -- velocity mod
  if self.velocity_mod == 0 then
    env.follower.enabled = false
  else
    env.follower.enabled = true
    env.follower.amount = self.velocity_mod
    env.follower.attack = 3
    env.follower.release = 127
  end
  
  -- do lfos
  self:ApplyLfo()
end


function FilterEnvelope:ApplyLfo()
  -- Apples the lfo effect

  local lfo = renoise.song().instruments[self.instrument_index].sample_envelopes.cutoff.lfo

  lfo:init()
  
  if self.cutoff_lfo_depth > 0 then  
    lfo.amount = self.cutoff_lfo_depth
    lfo.frequency = self.cutoff_lfo_rate
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_SIN
  else
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_OFF
  end
  
  lfo = renoise.song().instruments[self.instrument_index].sample_envelopes.resonance.lfo

  lfo:init()
  
  if self.resonance_lfo_depth > 0 then  
    lfo.amount = self.resonance_lfo_depth
    lfo.frequency = self.resonance_lfo_rate
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_SIN
  else
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_OFF
  end

  
  -- dump parameters
  
  self.sample.name = table_to_string({'FE4',
                                      tostring(self.attack),
                                      tostring(self.hold),
                                      tostring(self.decay1),
                                      tostring(self.brck),
                                      tostring(self.decay2),
                                      tostring(self.sustain),
                                      tostring(self.release),
                                      tostring(self.velocity_mod),    
                                      tostring(self.cutoff_lfo_depth),
                                      tostring(self.cutoff_lfo_rate),
                                      tostring(self.resonance_lfo_depth),
                                      tostring(self.resonance_lfo_rate),
                                      })
end


function FilterEnvelope:SetFilterType(index)
  -- Sets the filter type

  renoise.song().instruments[self.instrument_index].sample_envelopes.filter_type = index
end


function FilterEnvelope:GetFilterType()
  -- Returns the filter type

  return renoise.song().instruments[self.instrument_index].sample_envelopes.filter_type
end


function FilterEnvelope:SetResonance(v)
  -- Sets the filter resonance
  
  local env = renoise.song().instruments[self.instrument_index].sample_envelopes.resonance
  
  env:init()
  env.enabled = true
  env:add_point_at(1, v)
  
  renoise.app():show_status(string.format('ReSynth: Filter resonance set to to %d', v*100))
  
  self:ApplyLfo()
end


function FilterEnvelope:GetResonance()
  -- Returns the resonance value
  
  local env = renoise.song().instruments[self.instrument_index].sample_envelopes.resonance
  
  if not env.enabled then
    return 0
  else
    return env.points[1].value
  end
end


function FilterEnvelope:GetUI()
  -- Returns the FilterEnvelope UI
  
  return self.ui
end
