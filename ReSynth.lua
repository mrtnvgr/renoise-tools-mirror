--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- ReSynth class
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
The main resynth class

ReSynth.ui_osc1_type
ReSynth.ui_osc2_type
ReSynth.ui_osc3_type
ReSynth.ui_nna
ReSynth.ui_dialog_instance
ReSynth.inst_index
ReSynth.osc1
ReSynth.osc2
ReSynth.osc3
ReSynth.vol_env
ReSynth.filter_env
ReSynth:ChangeOscType(osc_num, osc_type)
ReSynth:Display()
ReSynth:Close()
]]--




--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'ReSynth'



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function ReSynth:__init(inst_index, open_mode)
  -- Create the resynth class with the specified instrument and mode ('new'/'open')
  
  self.vb = renoise.ViewBuilder()
  
  self.instrument_index = inst_index
  self.ui_dialog_instance = false
  
  if open_mode == OPEN_MODE_NEW then
    -- new instrument
    local inst = renoise.song().instruments[inst_index]
    
    -- create ui
    self.ui_osc1_type = self.vb:switch{
      width = 160,
      items = {'VA', 'FM', 'User', 'Super'},
      value = 1,
      notifier = function(v)
        self:ChangeOscType(1, v)
      end
    }
    
    self.ui_osc2_type = self.vb:switch{
      width = 120,
      items = {'VA', 'FM', 'User'},
      value = 1,
      notifier = function(v)
        self:ChangeOscType(2, v)
      end
    }
    
    self.ui_osc3_type = self.vb:switch{
      width = 120,
      items = {'VA', 'FM', 'User'},
      value = 1,
      notifier = function(v)
        self:ChangeOscType(3, v)
      end
    }
    
    self.ui_osc4_type = self.vb:switch{
      width = 120,
      items = {'VA', 'FM', 'User'},
      value = 1,
      notifier = function(v)
        self:ChangeOscType(4, v)
      end
    }  
    
    -- clear inst
    inst:clear()
    
    -- add sample slots
    for i = 1, 15 do
      inst:insert_sample_at(i)
      inst.samples[i].sample_buffer:create_sample_data(44000, -- sample rate
                                                       32,    -- bit depth
                                                       1,     -- channels
                                                       1)     -- frames
    end
    
    -- set nna/volumes
    for i = 1, #inst.samples do
      inst.samples[i].new_note_action = renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF
      inst.samples[i].volume = 0
    end
    inst.samples[1].volume = math.db2lin(-6)
    
    -- default oscillators
    self.osc1 = VaOscillator(self.vb, inst_index, 1)
    self.osc2 = VaOscillator(self.vb, inst_index, 2)
    self.osc3 = VaOscillator(self.vb, inst_index, 3)
    self.osc4 = VaOscillator(self.vb, inst_index, 4)

    -- arp
    self.arp = Arpeggiator(self.vb, inst_index, 7)
    
    -- env
    self.vol_env = VolEnvelope(self.vb, inst_index, 5, self.arp)
    self.filter_env = FilterEnvelope(self.vb, inst_index, 6, self.arp)

    self.arp:AttachEnvelopes(self.vol_env, self.filter_env)

    -- set instrument name
    inst.name = 'New Resynth Instrument'          
    
  elseif open_mode == OPEN_MODE_OPEN then
    -- open existing sample
    local inst = renoise.song().instruments[inst_index]
    local sn = ''
    
    -- verify no of samples
    if (#inst.samples ~= 16) then    -- 15 was from a broken older version
      -- not a valid resynth4
      renoise.app():show_message('Not a valid ReSynth4 instrument.')
      return
    end
    
    -- create oscillator 1
    sn = string.sub(inst.samples[1].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.osc1 = VaOscillator(self.vb, inst_index, 1)
    elseif sn == 'FM4:' then
      -- fm 
      self.osc1 = FmOscillator(self.vb, inst_index, 1)
    elseif sn == 'US4:' then
      -- user 
      self.osc1 = UserOscillator(self.vb, inst_index, 1)
    elseif sn == 'SS4:' then
      -- supersaw 
      self.osc1 = SsawOscillator(self.vb, inst_index, 1)
    else
      -- not a valid resynth4
      renoise.app():show_message('Not a valid ReSynth4 instrument.')
      return
    end
      
    -- create oscillator 2
    sn = string.sub(inst.samples[2].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.osc2 = VaOscillator(self.vb, inst_index, 2)
    elseif sn == 'FM4:' then
      -- fm 
      self.osc2 = FmOscillator(self.vb, inst_index, 2)
    elseif sn == 'US4:' then
      -- user 
      self.osc2 = UserOscillator(self.vb, inst_index, 2)
    else
      -- not a valid resynth4
      renoise.app():show_message('Not a valid ReSynth4 instrument.')
      return
    end  
    
    -- create oscillator 3
    sn = string.sub(inst.samples[3].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.osc3 = VaOscillator(self.vb, inst_index, 3)
    elseif sn == 'FM4:' then
      -- fm 
      self.osc3 = FmOscillator(self.vb, inst_index, 3)
    elseif sn == 'US4:' then
      -- user 
      self.osc3 = UserOscillator(self.vb, inst_index, 3)
    else
      -- not a valid resynth4
      renoise.app():show_message('Not a valid ReSynth4 instrument.')
      return
    end
    
    -- create oscillator 4
    sn = string.sub(inst.samples[4].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.osc4 = VaOscillator(self.vb, inst_index, 4)
    elseif sn == 'FM4:' then
      -- fm 
      self.osc4 = FmOscillator(self.vb, inst_index, 4)
    elseif sn == 'US4:' then
      -- user 
      self.osc4 = UserOscillator(self.vb, inst_index, 4)
    else
      -- not a valid resynth4
      renoise.app():show_message('Not a valid ReSynth4 instrument.')
      return
    end 
      
    -- arp
    self.arp = Arpeggiator(self.vb, inst_index, 7)
      
    -- env
    self.vol_env = VolEnvelope(self.vb, inst_index, 5, self.arp)
    self.filter_env = FilterEnvelope(self.vb, inst_index, 6, self.arp)

    self.arp:AttachEnvelopes(self.vol_env, self.filter_env)

    -- create ui
    sn = string.sub(inst.samples[1].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.ui_osc1_type = self.vb:switch{
        width = 160,
        items = {'VA', 'FM', 'User', 'Super'},
        value = OSCILLATOR_VA,
        notifier = function(v)
          self:ChangeOscType(1, v)
        end
      }
    elseif sn == 'FM4:' then
      -- fm 
      self.ui_osc1_type = self.vb:switch{
        width = 160,
        items = {'VA', 'FM', 'User', 'Super'},
        value = OSCILLATOR_FM,
        notifier = function(v)
          self:ChangeOscType(1, v)
        end
      }
    elseif sn == 'US4:' then
      -- user 
      self.ui_osc1_type = self.vb:switch{
        width = 160,
        items = {'VA', 'FM', 'User', 'Super'},
        value = OSCILLATOR_USER,
        notifier = function(v)
          self:ChangeOscType(1, v)
        end
      }
    elseif sn == 'SS4:' then
      -- supersaw 
      self.ui_osc1_type = self.vb:switch{
        width = 160,
        items = {'VA', 'FM', 'User', 'Super'},
        value = OSCILLATOR_SSAW,
        notifier = function(v)
          self:ChangeOscType(1, v)
        end
      }
    end
      
    -- create oscillator 2
    sn = string.sub(inst.samples[2].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.ui_osc2_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_VA,
        notifier = function(v)
          self:ChangeOscType(2, v)
        end
      }
    elseif sn == 'FM4:' then
      -- fm 
      self.ui_osc2_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_FM,
        notifier = function(v)
          self:ChangeOscType(2, v)
        end
      }
    elseif sn == 'US4:' then
      -- user 
      self.ui_osc2_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_USER,
        notifier = function(v)
          self:ChangeOscType(2, v)
        end
      }
    end  
    
    -- create oscillator 3
    sn = string.sub(inst.samples[3].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.ui_osc3_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_VA,
        notifier = function(v)
          self:ChangeOscType(3, v)
        end
      }
    elseif sn == 'FM4:' then
      -- fm 
      self.ui_osc3_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_FM,
        notifier = function(v)
          self:ChangeOscType(3, v)
        end
      }
    elseif sn == 'US4:' then
      -- user 
      self.ui_osc3_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_USER,
        notifier = function(v)
          self:ChangeOscType(3, v)
        end
      }
    end
    
    -- create oscillator 4
    sn = string.sub(inst.samples[4].name, 1, 4)
    if sn == 'VA4:' then
      -- va
      self.ui_osc4_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_VA,
        notifier = function(v)
          self:ChangeOscType(4, v)
        end
      }
    elseif sn == 'FM4:' then
      -- fm 
      self.ui_osc4_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_FM,
        notifier = function(v)
          self:ChangeOscType(4, v)
        end
      }
    elseif sn == 'US4:' then
      -- user 
      self.ui_osc4_type = self.vb:switch{
        width = 120,
        items = {'VA', 'FM', 'User'},
        value = OSCILLATOR_USER,
        notifier = function(v)
          self:ChangeOscType(4, v)
        end
      }
    end 

  end
  
  -- display the gui
  self:Display()
end


function ReSynth:ChangeOscType(osc_num, osc_type)
  -- change the oscillator type
  
  if osc_num == 1 then
    -- remove existing view
    self.vb.views.osc1outer:remove_child(self.vb.views.osc1)
    self.vb.views.osc1 = nil
  
    if osc_type == OSCILLATOR_VA then
      -- va
      self.osc1 = VaOscillator(self.vb, self.instrument_index, 1)
    elseif osc_type == OSCILLATOR_FM then
      -- fm
      self.osc1 = FmOscillator(self.vb, self.instrument_index, 1)
    elseif osc_type == OSCILLATOR_USER then
      -- user
      self.osc1 = UserOscillator(self.vb, self.instrument_index, 1)
    elseif osc_type == OSCILLATOR_SSAW then
      -- supersaw
      self.osc1 = SsawOscillator(self.vb, self.instrument_index, 1)
    end
    
    -- add new osc
    self.vb.views.osc1outer:add_child(self.vb.views.osc1)
    
  elseif osc_num == 2 then
    -- remove existing view
    self.vb.views.osc2outer:remove_child(self.vb.views.osc2)
    self.vb.views.osc2 = nil
  
    if osc_type == OSCILLATOR_VA then
      -- va
      self.osc2 = VaOscillator(self.vb, self.instrument_index, 2)
    elseif osc_type == OSCILLATOR_FM then
      -- fm
      self.osc2 = FmOscillator(self.vb, self.instrument_index, 2)
    elseif osc_type == OSCILLATOR_USER then
      -- user
      self.osc2 = UserOscillator(self.vb, self.instrument_index, 2)
    end
    
    -- add new osc
    self.vb.views.osc2outer:add_child(self.vb.views.osc2)
    
  elseif osc_num == 3 then
    -- remove existing view
    self.vb.views.osc3outer:remove_child(self.vb.views.osc3)
    self.vb.views.osc3 = nil
  
    if osc_type == OSCILLATOR_VA then
      -- va
      self.osc3 = VaOscillator(self.vb, self.instrument_index, 3)
    elseif osc_type == OSCILLATOR_FM then
      -- fm
      self.osc3 = FmOscillator(self.vb, self.instrument_index, 3)
    elseif osc_type == OSCILLATOR_USER then
      -- user
      self.osc3 = UserOscillator(self.vb, self.instrument_index, 3)
    end
    
    -- add new osc
    self.vb.views.osc3outer:add_child(self.vb.views.osc3)
    
  elseif osc_num == 4 then
    -- remove existing view
    self.vb.views.osc4outer:remove_child(self.vb.views.osc4)
    self.vb.views.osc4 = nil
  
    if osc_type == OSCILLATOR_VA then
      -- va
      self.osc4 = VaOscillator(self.vb, self.instrument_index, 4)
    elseif osc_type == OSCILLATOR_FM then
      -- fm
      self.osc4 = FmOscillator(self.vb, self.instrument_index, 4)
    elseif osc_type == OSCILLATOR_USER then
      -- user
      self.osc4 = UserOscillator(self.vb, self.instrument_index, 4)
    end
    
    -- add new osc
    self.vb.views.osc4outer:add_child(self.vb.views.osc4)
  end
end


function ReSynth:Display()
  -- Displays the resynth dialog

  -- close any existing windows for this class
  if self.ui_dialog_instance then
    if self.ui_dialog_instance.visible then
      self.ui_dialog_instance:close()
    end
    self.vb.views.osc1outer = nil
    self.vb.views.osc2outer = nil
    self.vb.views.osc3outer = nil
    self.vb.views.osc4outer = nil
    self.vb.views.resynth = nil
  end
  
  local view = self.vb:column {
    id = 'resynth',
    self.vb:column {
      margin = 2,
      style = 'body',
      self.vb:row {
        self.vb:row {
          self.vb:text {
            font = 'big',
            text = 'Oscillators',
            width = 586,
          },
          self.vb:button {
            text = 'Envelope help',
            notifier = function()
              show_env_diagram_popup()
            end,
          },
        },
      },
      self.vb:row {
        self.vb:column {
          margin = 2,
          id = 'osc1outer',
          style = 'body',
          self.ui_osc1_type,
          self.osc1:GetUI(),
        },
        self.vb:column {
          margin = 2,
          id = 'osc2outer',
          style = 'body',
          self.ui_osc2_type,
          self.osc2:GetUI(),
        },
        self.vb:column {
          margin = 2,
          id = 'osc3outer',
          style = 'body',
          self.ui_osc3_type,
          self.osc3:GetUI(),
        },
        self.vb:column {
          margin = 2,
          id = 'osc4outer',
          style = 'body',
          self.ui_osc4_type,
          self.osc4:GetUI(),
        },
      },
    },
    self.vb:row {
      self.vb:column {
        margin = 2,
        style = 'body',
        self.vb:text {
          font = 'big',
          text = 'Volume',
        },
        self.vol_env:GetUI(),
      },
      
      self.vb:column {
        margin = 2,
        style = 'body',
        self.vb:text {
          font = 'big',
          text = 'Filter',
        },
        self.filter_env:GetUI(),
      },
      self.vb:column {
        margin = 2,
        style = 'body',
        self.vb:text {
          font = 'big',
          text = 'Arpeggiator',
        },
        self.arp:GetUI(),
      },
    },
  }
  
  -- create a new dialog and display
  self.ui_dialog_instance = renoise.app():show_custom_dialog('ReSynth4 Beta 2 - ' ..
                                                             renoise.song().instruments[self.instrument_index].name,
                                                             view,
                                                             key_passthrough)
end


