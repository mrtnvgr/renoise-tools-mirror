--------------------------------------------------------------------------------
-- ReSynth4
--
-- Copyright 2012 Martin Bealby
--
-- User waveform oscillator
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Documentation
--------------------------------------------------------------------------------
--[[
UserOscillator inherits from BaseOscillator class and generates virtual analog
oscillator waveforms.


UserOscillator.ui_wavename         -- viewbuilder user interface
UserOscillator.ui_loop_toggle
UserOscillator.ui_load_button
UserOscillator.ui_clear_button
BaseOscillator:GetUI()             -- return the user interface
UserOscillator:Render()            -- tiny wrapper
UserOscillator:Load()              -- loads the sample
BaseOscillator:Reset()             -- resets the oscillator
BaseOscillator:SetLoopMode()       -- sets the loop mode
BaseOscillator:GetLoopMode()       -- returns the loop mode
]]--


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class 'UserOscillator' (BaseOscillator)



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function UserOscillator:__init(vb, inst_index, sample_index)
  -- VA Generator init
  local loaded_sample = false
    
  -- call base class init
  BaseOscillator.__init(self, vb, inst_index, sample_index)
  
  -- create ui
  self.ui_wavename = self.vb:text{
    text = '',
    width = 120,
    tooltip = 'User loaded sample',
  }
  
  self.ui_loop_toggle = self.vb:checkbox{
    value = false,
    tooltip = 'Sample looping',
    notifier = function (v)
      if v then
        self:SetLoopMode(renoise.Sample.LOOP_MODE_FORWARD)
      else
        self:SetLoopMode(renoise.Sample.LOOP_MODE_OFF)
      end
    end
  }
  
  self.ui_load_button = self.vb:button {
    text = 'Load',
    width = 54,
    notifier = function()
      local filename = renoise.app():prompt_for_filename_to_read({'*.wav', '*.aiff', '*.flac'},
                                                                 'Load ReSynth4 user waveform')
                                                                 
      if filename ~= "" then
        self:Load(filename)
      end
    end
  }
  
  self.ui_clear_button = self.vb:button {
    text = 'Clear',
    width = 54,
    notifier = function()
      self:Reset()
    end
  }
  
  self.ui = self.vb:column{
    spacing = 13,
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
      
      self.vb:text {
        text = 'Name:',
      },
      
      self.ui_wavename,
    },
     
    self.vb:horizontal_aligner{
      self.vb:text {
        text = 'Loop:',
      },
      
      self.ui_loop_toggle,
      self.ui_load_button,
      self.ui_clear_button,
    },
  }

  
  if string.sub(self.sample.name, 1, 4) == "US4:" then
    -- load settings
    local settings = string_to_table(self.sample.name)
    
    if #settings == 2 then
      if string.sub(tostring(settings[2]), 1, 20) ~= '' then
        -- seems ok
        self.ui_wavename.text = string.sub(tostring(settings[2]), 1, 20)
        
        -- add sample map
        if not self:HasSampleMapping() then
          self:AddSampleMapping(48)
        end
        loaded_sample = true
      end
    end
  else  
    -- reset to defaults
    self:Reset()
  end
end


function UserOscillator:Reset()
  -- Reset to defaults
  
  
  -- interpolation
  self.sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
  
  -- set default loop mode (off)
  self:SetLoopMode(renoise.Sample.LOOP_MODE_OFF)

  self.ui_wavename.text = ''
  self.ui_loop_toggle.value = false

  if self.sample.sample_buffer.has_sample_data then
    self.sample.sample_buffer:delete_sample_data()
    self.sample.sample_buffer:create_sample_data(44000, -- sample rate
                                                 32,    -- bit depth
                                                 1,     -- channels
                                                 1)     -- frames
  end
  
  self:Render()
end


function UserOscillator:Load(filename)
  -- Loads the specified waveform
  
  -- remove old data
  if self.sample.sample_buffer.has_sample_data then
    self.sample.sample_buffer:delete_sample_data()
  end

  -- load new data
  self.sample.sample_buffer:load_from(filename)
  
  -- set name
  self.ui_wavename.text = string.sub(basename(filename), 1, 20)

  self:Render()
end


function UserOscillator:Render()
  -- UserOscillator rendering function callthrough
  
  -- update sample maps
  if self.ui_wavename.text == '' then
    if self:HasSampleMapping() then
      self:DeleteSampleMapping()
    end
  else
    if not self:HasSampleMapping() then
      self:AddSampleMapping(48)
    end
  end

  -- calculate settings string
  self.sample.name = table_to_string({'US4',
                                      self.ui_wavename.text })

  self:SetView()
end

function UserOscillator:SetView()
  -- maybe set view
  if renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR then
    renoise.song().selected_instrument_index = self.instrument_index
    renoise.song().selected_sample_index = self.sample_index
    if renoise.song().selected_sample.sample_buffer.has_sample_data then
      if renoise.song().selected_sample.sample_buffer.number_of_frames > 1 then
        renoise.song().selected_sample.sample_buffer.display_range = {1, renoise.song().selected_sample.sample_buffer.number_of_frames}
      end
    end
  end
end


function UserOscillator:SetVolume(v)
  -- Sets the oscillator volume (overrides BaseOscillator)
  
  if self.sample then
    if v < -36 then
      --off
      self.sample.volume = 0
      if self:HasSampleMapping() then
        self:DeleteSampleMapping()
      end
    else
      -- on
      self.sample.volume = math.db2lin(v)
      if not self:HasSampleMapping() then
        self:AddSampleMapping(48)
      end
    end
  end
end
