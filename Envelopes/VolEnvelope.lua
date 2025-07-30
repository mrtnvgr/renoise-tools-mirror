--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- VolEnvelope class
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
VolEnvelope class handles managing all volume parameters

VolEnvelope.ui                     -- viewbuilder user interface
VolEnvelope.ui_attack
VolEnvelope.ui_hold
VolEnvelope.ui_decay1
VolEnvelope.ui_break
VolEnvelope.ui_decay2
VolEnvelope.ui_sustain
VolEnvelope.ui_release
VolEnvelope.ui_tremelo_rate
VolEnvelope.ui_tremelo_depth
VolEnvelope:SetAttack()            -- sets the attack time     [0..24]
VolEnvelope:GetAttack()            -- returns the attack time
VolEnvelope:SetHold()              -- sets the hold time       [0..24]
VolEnvelope:GetHold()              -- returns the hold time
VolEnvelope:SetDecay1()            -- sets the decay1 time     [1..24]
VolEnvelope:GetDecay1()            -- returns the decay1 time
VolEnvelope:SetBreak()             -- sets the break level     [0..1]  (inverted)
VolEnvelope:GetBreak()             -- returns the break level
VolEnvelope:SetDecay2()            -- sets the decay2 time     [1..24]
VolEnvelope:GetDecay2()            -- returns the decay2 time
VolEnvelope:SetSustain()           -- sets the sustain level   [0..1]
VolEnvelope:GetSustain()           -- returns the sustain level
VolEnvelope:SetRelease()           -- sets the release time    [0..24]
VolEnvelope:GetRelease()           -- returns the release time
VolEnvelope:SetTremeloRate()
VolEnvelope:GetTremeloRate()
VolEnvelope:SetTremeloDepth()
VolEnvelope:GetTremeloDepth()
VolEnvelope:Reset()                -- resets the envelope
VolEnvelope:Apply()
VolEnvelope:ApplyTremelo()
VolEnvelope:GetUI()                -- returns the user interface view
]]--




--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'VolEnvelope'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function VolEnvelope:__init(vb, inst_index, sample_index, arp_object)
  -- VolEnvelope init

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
  self.tremelo_rate = 0
  self.tremelo_depth = 0


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
  
  self.ui_tremelo_rate = self.vb:rotary{
    min = 0,
    max = 64,
    value = 0,
    tooltip = 'Tremelo Rate',
    notifier = function(v)
      if math.floor(v) ~= self:GetTremeloRate() then
        self:SetTremeloRate(math.floor(v))
      end
    end
  } 
  
  self.ui_tremelo_depth = self.vb:rotary{
    min = 0,
    max = 32,
    value = 0,
    tooltip = 'Tremelo Depth',
    notifier = function(v)
      if math.floor(v) ~= self:GetTremeloDepth() then
        self:SetTremeloDepth(math.floor(v))
      end
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
      
      self.vb:vertical_aligner {
        spacing = 2,
        mode = 'center',
        self.ui_tremelo_rate,
        self.vb:text {
          text = ' Rate',
        },
        self.ui_tremelo_depth,
        self.vb:text {
          text = 'Depth',
        },
      },
    },
  }
  
  -- load settings
  if string.sub(self.sample.name, 1, 4) == "VE4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 10 then
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
      
      self.tremelo_rate = tonumber(settings[9])
      self.ui_tremelo_rate.value = self.tremelo_rate
      self.tremelo_depth = tonumber(settings[10])
      self.ui_tremelo_depth.value = self.tremelo_depth
    else
      -- Reset to defaults
      self:Reset()
    end
  else
    -- Reset to defaults
    self:Reset()
  end
end

function VolEnvelope:Reset()
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
  
  self.tremelo_rate = 0
  self.ui_tremelo_rate.value = self.tremelo_rate
  self.tremelo_depth = 0
  self.ui_tremelo_depth.value = self.tremelo_depth
  
  self:Apply()
  self:ApplyTremelo()
  
end


function VolEnvelope:SetAttack(v)
  -- sets the envelope attack
  
  self.attack = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope attack time set to to %d ticks', v))
  self:Apply()
end


function VolEnvelope:GetAttack()
  -- Returns the envelope attack
  
  return self.attack
end


function VolEnvelope:SetHold(v)
  -- sets the envelope hold
  
  self.hold = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope hold time set to to %d ticks', v))
  self:Apply()
end


function VolEnvelope:GetHold()
  -- Returns the envelope hold
  
  return self.hold
end


function VolEnvelope:SetDecay1(v)
  -- sets the envelope Decay1
  
  self.decay1 = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope decay 1 time set to to %d ticks', v))
  self:Apply()
end


function VolEnvelope:GetDecay1()
  -- Returns the envelope Decay1
  
  return self.decay1
end


function VolEnvelope:SetBreak(v)
  -- sets the envelope break
  
  self.brck = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope break level set to to %d', v*100))
  self:Apply()
end


function VolEnvelope:GetBreak()
  -- Returns the envelope break
  
  return self.brck
end


function VolEnvelope:SetDecay2(v)
  -- sets the envelope Decay2
  
  self.decay2 = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope decay 2 time set to to %d ticks', v))
  self:Apply()
end


function VolEnvelope:GetDecay2()
  -- Returns the envelope Decay2
  
  return self.decay2
end


function VolEnvelope:SetSustain(v)
  -- sets the envelope sustain
  
  self.sustain = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope sustain level set to to %d', v*100))
  self:Apply()
end


function VolEnvelope:GetSustain()
  -- Returns the envelope sustain
  
  return self.sustain
end


function VolEnvelope:SetRelease(v)
  -- sets the envelope release
  
  self.release = v
  renoise.app():show_status(string.format('ReSynth: Volume envelope release time set to to %d ticks', v))
  self:Apply()
end


function VolEnvelope:GetRelease()
  -- Returns the envelope release
  
  return self.release
end


function VolEnvelope:SetTremeloRate(v)
  -- Sets the tremelo rate

  self.tremelo_rate = v
  renoise.app():show_status(string.format('ReSynth: Volume LFO rate set to to %d ticks', v))
  self:ApplyTremelo()
end


function VolEnvelope:GetTremeloRate()
  -- returns the tremelo rate

  return self.tremelo_rate
end


function VolEnvelope:SetTremeloDepth(v)
  -- Sets the tremelo depth

  self.tremelo_depth = v
  renoise.app():show_status(string.format('ReSynth: Volume LFO depth set to to %d ticks', v))
  self:ApplyTremelo()
end


function VolEnvelope:GetTremeloDepth()
  -- returns the tremelo depth

  return self.tremelo_depth
end


function VolEnvelope:Apply()
  -- Applies the envelope
  
  local env = renoise.song().instruments[self.instrument_index].sample_envelopes.volume

  -- consider the arp, for it is confusing
  if self.arp:GetApplyVol() then
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
  
  self:ApplyTremelo()
  

end


function VolEnvelope:ApplyTremelo()
  -- Apples the tremelo effect

  local lfo = renoise.song().instruments[self.instrument_index].sample_envelopes.volume.lfo1

  lfo:init()
  
  if self.tremelo_depth > 0 then  
    lfo.amount = self.tremelo_depth
    lfo.frequency = self.tremelo_rate
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_SIN
  else
    lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_OFF
  end
  
  -- dump parameters
  self.sample.name = table_to_string({'VE4',
                                      tostring(self.attack),
                                      tostring(self.hold),
                                      tostring(self.decay1),
                                      tostring(self.brck),
                                      tostring(self.decay2),
                                      tostring(self.sustain),
                                      tostring(self.release),
                                      tostring(self.tremelo_depth),
                                      tostring(self.tremelo_rate),
                                      })
end

function VolEnvelope:GetUI()
  -- Returns the VolEnvelope UI
  
  return self.ui
end
