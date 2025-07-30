--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Cells Mixer/FX Code
--------------------------------------------------------------------------------


--[[
CellsMixerFx()
CellsMixerFx.ui_crossfader
CellsMixerFx.ui_master_volume
CellsMixerFx.ui_cue_volume
CellsMixerFx.ui_cut_a
CellsMixerFx.ui_cut_b
CellsMixerFx.ui_filter_cutoff_a
CellsMixerFx.ui_filter_cutoff_b
CellsMixerFx.ui_effect_rate
CellsMixerFx.ui_effect_amount
CellsMixerFx.ui_effect_state
CellsMixerFx.ui_effect_selector
CellsMixerFx.ui_frame_fx
CellsMixerFx.ui_frame_volume
CellsMixerFx.ui_frame_crossfader
CellsMixerFx.effect_rate_int
CellsMixerFx.track_a
CellsMixerFx.track_b
CellsMixerFx.track_fx
CellsMixerFx.track_cue
CellsMixerFx.track_master
CellsMixerFx.target_effect_id
CellsMixerFx:SetCrossfader(0..1)
CellsMixerFx:MoveCrossfader(0..1)
CellsMixerFx:GetCrossfader()
CellsMixerFx:SetMasterVolume(0..1)
CellsMixerFx:GetMasterVolume()
CellsMixerFx:SetCueVolume(0..1)
CellsMixerFx:GetCueVolume()
CellsMixerFx:GetCutState(group)
CellsMixerFx:SetCutState(group, bool)
CellsMixerFx:SetEffectRate(0..1)
CellsMixerFx:GetEffectRate()
CellsMixerFx:SetEffectAmount(0..1)
CellsMixerFx:GetEffectAmount()
CellsMixerFx:SetEffectState(bool)
CellsMixerFx:GetEffectState()
CellsMixerFx:SetEffectType(index)
CellsMixerFx:GetEffectType()
CellsMixerFx:SetEffectTarget(index)
CellsMixerFx:GetEffectTarget()
CellsMixerFx:CreateTracks()
CellsMixerFx:RemoveTracks()
CellsMixerFx:GetFxUI()
CellsMixerFx:GetVolumeUI()
CellsMixerFx:GetCrossFaderUI()
CellsMixerFx:AssignChannelGroups()
CellsMixerFx:GetCellsChannel()

]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "CellsMixerFx"



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function CellsMixerFx:__init()
  -- Initialise
  
  local vb = renoise.ViewBuilder()
  
  --
  -- Initialise class variables
  --
  self.ui_crossfader = nil
  self.ui_master_volume = nil
  self.ui_cue_volume = nil
  self.ui_cut_a = nil
  self.ui_cut_b = nil
  self.ui_effect_rate = nil
  self.ui_effect_amount = nil
  self.ui_effect_state = nil
  self.ui_effect_selector = nil
  self.ui_effect_target = nil
  self.ui_frame_fx = nil
  self.ui_frame_volume = nil
  self.ui_frame_crossfader = nil
  self.effect_rate_int = 0
  self.track_a = nil
  self.track_b = nil
  self.track_fx = nil
  self.track_cue = nil
  self.track_master = nil
  self.target_effect_id = 3 -- filter
  
  --
  -- Create GUI elements
  --
  self.ui_crossfader = vb:minislider{
    height = 32,
    width = 128,
    min = 0,
    max = 1,
    value = 0,
    notifier = function(v)
      self:SetCrossfader(v)
    end
  }
  
  self.ui_cut_a = vb:button{
    text = " ",
    width = 32,
    height = 32,
    color = COLOUR_GREY,
    pressed = function()
      self:SetCutState(0, true)
    end,
    released = function()
      self:SetCutState(0, false)
    end,
  }
  
  self.ui_cut_b = vb:button{
    text = " ",
    width = 32,
    height = 32,
    color = COLOUR_GREY,
    pressed = function()
      self:SetCutState(1, true)
    end,
    released = function()
      self:SetCutState(1, false)
    end,
  }
  
  self.ui_master_volume = vb:rotary{
    min = 0,
    max = math.db2lin(3),
    value = math.db2lin(0),
    notifier = function(v)
      self:SetMasterVolume(v)
    end
  }
  
  self.ui_cue_volume = vb:rotary{
    min = 0,
    max = math.db2lin(3),
    value = math.db2lin(0),
    notifier = function(v)
      self:SetCueVolume(v)
    end
  }
  
  self.ui_frame_volume = vb:row{
    style = "group",
    spacing = 0,
    margin = 0,
    
    vb:vertical_aligner{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
        
      vb:horizontal_aligner{
        mode = "justify",
        spacing = 26,
        vb:column{
          self.ui_cue_volume,
          vb:text{
            text=" Cue"
          },
        },
        vb:column{
          self.ui_master_volume,
          vb:text{
            text="Master"
          }
        }
      }
    }
  }
  
  self.ui_effect_state = vb:button{
    text = "Off",
    width = 43,
    height = 55,
    color = COLOUR_YELLOW,
    notifier = function()
      self:ToggleEffectState()
    end
  }
  
  self.ui_effect_rate = vb:rotary{
    min = 0,
    max = 4.9,
    value = 0,
    tooltip = "4 beats",
    notifier = function(v)
      self:SetEffectRate(math.floor(v))
    end
  }
  
  self.ui_effect_amount = vb:rotary{
    min = 0,
    max = 1,
    value = 0,
    tooltip = "0%",
    notifier = function(v)
      self:SetEffectAmount(v)
    end
  }
  
  self.ui_effect_selector = vb:chooser{
    items = {"Filter", "Repeat", "Delay", "Flanger"},
    value = 1,
    notifier = function(v)
      self:SetEffectType(v)
    end
  }
  
  self.ui_effect_target = vb:switch{
    items = {"A", "M", "B"},
    value = 2,
    width = 100,
    notifier = function(index)
      self:SetEffectTarget(index)
    end
  }
  
  self.ui_frame_fx = vb:row{
    style = "group",
    spacing = 0,
    margin = 0,
    
    vb:vertical_aligner{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,

      vb:horizontal_aligner{
        mode = "justify",
        spacing = 27,
        vb:column{
          self.ui_effect_rate,
          vb:text{
            text=" Rate"
          },
        },
        vb:column{
          self.ui_effect_amount,
          vb:text{
            text=" Amt"
          },
        },
      },
    
      vb:horizontal_aligner{
        mode = "justify",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        self.ui_effect_target,
      },
    
      vb:horizontal_aligner{
        mode = "justify",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        self.ui_effect_selector,
        self.ui_effect_state,
      }
    }
  }
  
  self.ui_frame_crossfader = vb:row{
    style = "group",
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    
    self.ui_cut_a,
    self.ui_crossfader,
    self.ui_cut_b,
  }
  
  --
  -- Prepare tracks
  --
  self:PrepareTracks()
  
  --
  -- Init Effects
  --
  self:SetEffectRate(0)
  self:SetEffectAmount(0)
  
  --
  -- Init volume controls
  --
  self:SetMasterVolume(math.db2lin(0))
  self:SetCueVolume(math.db2lin(0))
  self:SetCrossfader(0)
end


function CellsMixerFx:PrepareTracks()
  -- Removes any existing Cells Bus tracks and re-adds them
  
  local rs = renoise.song()

  -- Remove all sends
  for i = #rs.tracks, 1, -1 do
    if rs.tracks[i].type == renoise.Track.TRACK_TYPE_SEND then
      rs:delete_track_at(i)
    elseif rs.tracks[i].type == renoise.Track.TRACK_TYPE_MASTER then
      self.track_master = rs.tracks[i]
    end
  end
  
  --
  -- Prepare master track
  --
  
  -- Remove devices on master track
  if #self.track_master.devices > 1 then
    for i = #self.track_master.devices, 2, -1 do
      self.track_master:delete_device_at(i)
    end
  end
  
  -- Add limiter
  self.track_master:insert_device_at(LIMITER_DEVICE_ID, 2)
  self.track_master.devices[2].display_name = "Cells! Brick Limiter"
  self.track_master.devices[2].is_active = true
  self.track_master.devices[2].is_maximized = false
  self.track_master.devices[2].parameters[1].value = 14.83 -- Threshold
  self.track_master.devices[2].parameters[2].value = 16    -- ratio
  self.track_master.devices[2].parameters[3].value = 0.01  -- attack
  self.track_master.devices[2].parameters[4].value = 20    -- release
  self.track_master.devices[2].parameters[5].value = 1     -- makeup
  
  --
  -- Add new sends
  --
  
  -- A
  self.track_a = rs:insert_track_at(#rs.tracks+1)
  self.track_a.name = "Cells! A"
  self.track_a.collapsed = true
  self.track_a:insert_device_at(GAIN_DEVICE_ID, 2)
  self.track_a.devices[2].display_name = "Cells! Cut mute"
  self.track_a.devices[2].is_active = false
  self.track_a.devices[2].is_maximized = false
  self.track_a.devices[2].parameters[1].value = 0   -- -INF
  self.track_a:insert_device_at(SEND_DEVICE_ID, 3)
  self.track_a.devices[3].display_name = "Cells! FX Routing"
  self.track_a.devices[3].is_active = true
  self.track_a.devices[3].is_maximized = false
  self.track_a.devices[3].parameters[1].value = 1   -- amount
  self.track_a.devices[3].parameters[2].value = 0.5 -- panning

  -- B
  self.track_b = rs:insert_track_at(#rs.tracks+1)
  self.track_b.name = "Cells! B"
  self.track_b.collapsed = true
  self.track_b:insert_device_at(GAIN_DEVICE_ID, 2)
  self.track_b.devices[2].display_name = "Cells! Cut mute"
  self.track_b.devices[2].is_active = false
  self.track_b.devices[2].is_maximized = false
  self.track_b.devices[2].parameters[1].value = 0   -- -INF
  self.track_b:insert_device_at(SEND_DEVICE_ID, 3)
  self.track_b.devices[3].display_name = "Cells! FX Routing"
  self.track_b.devices[3].is_active = true
  self.track_b.devices[3].is_maximized = false
  self.track_b.devices[3].parameters[1].value = 1   -- amount
  self.track_b.devices[3].parameters[2].value = 0.5 -- panning
  
  -- FX
  self.track_fx = rs:insert_track_at(#rs.tracks+1)
  self.track_fx.name = "Cells! FX"
  self.track_fx.collapsed = true
  self.track_fx:insert_device_at(REPEATER_DEVICE_ID, 2)
  self.track_fx.devices[2].display_name = "Cells! FX Repeat"
  self.track_fx.devices[2].is_active = true
  self.track_fx.devices[2].is_maximized = false
  self.track_fx.devices[2].parameters[1].value = 0   -- Mode = off
  self.track_fx.devices[2].parameters[2].value = 0.5 -- Rate = 1/16         [rate]
  self.track_fx:insert_device_at(FILTER_DEVICE_ID, 3)
  self.track_fx.devices[3].display_name = "Cells! FX Filter"
  self.track_fx.devices[3].is_active = false
  self.track_fx.devices[3].is_maximized = false
  self.track_fx.devices[3].parameters[1].value = 1   -- Mode = high shelf
  self.track_fx.devices[3].parameters[2].value = 1   -- Cutoff = max        [amt]
  self.track_fx.devices[3].parameters[3].value = 2   -- resonance           [rate]
  self.track_fx:insert_device_at(FLANGER_DEVICE_ID, 4)
  self.track_fx.devices[4].display_name = "Cells! FX Flanger"
  self.track_fx.devices[4].is_active = false
  self.track_fx.devices[4].is_maximized = false
  self.track_fx.devices[4].parameters[1].value = 0   -- Amount = 0 (0..1)   [amt]
  self.track_fx.devices[4].parameters[2].value = 0.5 -- Rate = 0.5 (0..1)   [rate]
  self.track_fx.devices[4].parameters[3].value = 0.039999 -- Amplitude
  self.track_fx.devices[4].parameters[4].value = -0.85 -- Feedback
  self.track_fx.devices[4].parameters[5].value = 5   -- Delay
  self.track_fx.devices[4].parameters[6].value = 0   -- Phase
  self.track_fx.devices[4].parameters[7].value = 3   -- Filter type
  self.track_fx.devices[4].parameters[8].value = 127 -- Cutoff
  self.track_fx.devices[4].parameters[9].value = 0   -- Resonance
  self.track_fx:insert_device_at(DELAY_DEVICE_ID, 5)
  self.track_fx.devices[5].display_name = "Cells! FX Delay"
  self.track_fx.devices[5].is_active = false
  self.track_fx.devices[5].is_maximized = false  
  self.track_fx.devices[5].parameters[1].value = 16  -- LDelay (1..256)     [rate]
  self.track_fx.devices[5].parameters[2].value = 16  -- RDelay (1..256)     [rate]
  self.track_fx.devices[5].parameters[3].value = 0.5 -- LFeedback (0..1)    [amt]
  self.track_fx.devices[5].parameters[4].value = 0.5 -- RFeedback (0..1)    [amt]
  self.track_fx.devices[5].parameters[5].value = 32  -- Send
  self.track_fx.devices[5].parameters[6].value = 0   -- Line sync off
  self.track_fx.devices[5].parameters[9].value = 0.46 -- LPan
  self.track_fx.devices[5].parameters[10].value = 0.54 -- RPan
  self.track_fx.devices[5].parameters[11].value = 0  -- Source mute off
  
  -- Cue output
  self.track_cue = rs:insert_track_at(#rs.tracks+1)
  self.track_cue.name = "Cells! Cue"
  self.track_cue.collapsed = true
  self.track_cue:insert_device_at(GAIN_DEVICE_ID, 2)
  self.track_cue.devices[2].display_name = "Cells! Cue mute"
  self.track_cue.devices[2].is_active = false
  self.track_cue.devices[2].is_maximized = false
  self.track_cue.devices[2].parameters[1].value = 0   -- -INF
  
  -- auto mute cue output if required
  if preferences.single_output_mode.value ~= true then
    if preferences.automatic_cue_mute.value == true then
      if preferences.master_output_device.value == preferences.cue_output_device.value then
        self.track_cue.devices[2].is_active = true
      end
    end
  end
  
  -- assign output devices
  
  -- master
  if table.find(self.track_master.available_output_routings, preferences.master_output_device.value) then
    self.track_master.output_routing = preferences.master_output_device.value
  else
    renoise.app():show_warning("Master output device not assigned as output device selected in preferences doesn't exist.")
  end
  
  -- cue
  if table.find(self.track_cue.available_output_routings, preferences.cue_output_device.value) then
    self.track_cue.output_routing = preferences.cue_output_device.value
  else
    renoise.app():show_warning("Cue output device not assigned as output device selected in preferences doesn't exist.")
  end
   
  -- Fix inter-send routing
  self.track_a.devices[3].parameters[3].value = 2   -- destination (Cells! FX)
  self.track_b.devices[3].parameters[3].value = 2   -- destination (Cells! FX)
end


function CellsMixerFx:GetFxUI() 
  return self.ui_frame_fx
end


function CellsMixerFx:GetVolumeUI() 
  return self.ui_frame_volume
end


function CellsMixerFx:GetCrossFaderUI()
  return self.ui_frame_crossfader
end


function CellsMixerFx:ToggleEffectState()
  -- Toggle the state of the selected effect

  if self.target_effect_id == 2 then
    -- repeater is a special case
    if self.track_fx.devices[2].parameters[1].value == 0 then
      -- turn on
      self.track_fx.devices[2].parameters[1].value = 2
    else
      -- turn off
      self.track_fx.devices[2].parameters[1].value = 0
    end
  else
    -- all other device
    if self.track_fx.devices[self.target_effect_id].is_active then
      -- turn off
      self.track_fx.devices[self.target_effect_id].is_active = false
    else
      -- turn on
      self.track_fx.devices[self.target_effect_id].is_active = true
    end
  end
  
  -- UI Update
  self:UpdateEffectButton()
end

function CellsMixerFx:GetEffectState()
  -- Returns effect on/off state
  if self.target_effect_id == 2 then
    if self.track_fx.devices[2].parameters[1].value == 0 then
      return false
    else
      return true
    end
  else
    return self.track_fx.devices[self.target_effect_id].is_active
  end
end


function CellsMixerFx:SetEffectType(index)
  -- Sets the target_effect_id from the gui index value and updates the button state
  
  -- Turn off the current effect
  local effect_was_on
  
  if self.target_effect_id == 2 then
    effect_was_on = (self.track_fx.devices[2].parameters[1].value ~= 0)
    self.track_fx.devices[2].parameters[1].value = 0
  else
    effect_was_on = self.track_fx.devices[self.target_effect_id].is_active
    self.track_fx.devices[self.target_effect_id].is_active = false
  end
  
  -- Change effect reference
  if index == 1 then
    self.target_effect_id = 3   -- filter
  elseif index == 2 then
    self.target_effect_id = 2   -- repeat
  elseif index == 3 then
    self.target_effect_id = 5   -- delay
  elseif index == 4 then
    self.target_effect_id = 4   -- flange
  end

  -- Reenable effect
  if effect_was_on then
    self:ToggleEffectState()
  end
  
  -- UI Update
  self:UpdateEffectButton()
  
  cf:SetFXType(index)
end


function CellsMixerFx:MoveEffectType(value)
  -- Update the UI control which calls SetEffectType
  
  self.ui_effect_selector.value = value
end


function CellsMixerFx:GetEffectType()
  -- Returns the effect type
  return self.ui_effect_selector.value
end


function CellsMixerFx:UpdateEffectButton()
  if self.target_effect_id == 2 then
    -- repeater is a special case
    if self.track_fx.devices[2].parameters[1].value == 0 then
      self.ui_effect_state.color = COLOUR_YELLOW
      self.ui_effect_state.text  = "Off"
      cf:SetFXState(false)
    else
      self.ui_effect_state.color = COLOUR_GREEN
      self.ui_effect_state.text  = "On"
      cf:SetFXState(true)
    end
  else
    -- all other device
    if self.track_fx.devices[self.target_effect_id].is_active then
      self.ui_effect_state.color = COLOUR_GREEN
      self.ui_effect_state.text  = "On"
      cf:SetFXState(true)
    else
      self.ui_effect_state.color = COLOUR_YELLOW
      self.ui_effect_state.text  = "Off"
      cf:SetFXState(false)
    end
  end
end


function CellsMixerFx:SetEffectRate(value)
  -- Set the effect rate (value = 0..4)

  -- fire once per 'segment' of the rotary
  if self.effect_rate_int == math.floor(value) then
    return
  end
  
  -- cache value
  self.effect_rate_int = math.floor(value)
  
  -- We do all DSP effects to keep in sync
  self.track_fx.devices[2].parameters[2].value = self.effect_rate_int * 0.125
  self.track_fx.devices[3].parameters[3].value = self.effect_rate_int
  
  if value == 0 then
    self.track_fx.devices[5].parameters[7].value = 16
    self.track_fx.devices[5].parameters[8].value = 16
  else
    self.track_fx.devices[5].parameters[7].value = 8/self.effect_rate_int
    self.track_fx.devices[5].parameters[8].value = 8/self.effect_rate_int
  end

  -- abuse delay to calculate phaser
  self.track_fx.devices[4].parameters[2].value = (16/self.track_fx.devices[5].parameters[1].value)
  
  -- tooltip
  if self.effect_rate_int == 0 then
    self.ui_effect_rate.tooltip = "4 beats"
  elseif self.effect_rate_int == 1 then
    self.ui_effect_rate.tooltip = "2 beats"
  elseif self.effect_rate_int == 2 then
    self.ui_effect_rate.tooltip = "1 beat"
  elseif self.effect_rate_int == 3 then
    self.ui_effect_rate.tooltip = "1/2 beat"
  elseif self.effect_rate_int == 4 then
    self.ui_effect_rate.tooltip = "1/4 beat"
  end
  
  cf:SetFXRate(self.effect_rate_int)
end


function CellsMixerFx:MoveEffectRate(value)
  -- Update the UI control which calls SetEffectRate
  
  self.ui_effect_rate.value = value * 4.9
end


function CellsMixerFx:GetEffectRate()
  -- Returns the effect rate (0..1)
  return (self.effect_rate_int / 4)
end


function CellsMixerFx:SetEffectAmount(value)
  -- Set the effect amount
  
  -- We do all DSP effects to keep in sync
  self.track_fx.devices[3].parameters[2].value = value
  self.track_fx.devices[4].parameters[1].value = value
  self.track_fx.devices[5].parameters[3].value = value
  self.track_fx.devices[5].parameters[4].value = value
  
  -- Tooltip
  self.ui_effect_amount.tooltip = string.format("%d%%", math.floor(value*100))
  
  cf:SetFXAmount(value)
end


function CellsMixerFx:MoveEffectAmount(value)
  -- Update the UI control which calls SetEffectAmount
  
  self.ui_effect_amount.value = value
end


function CellsMixerFx:GetEffectAmount()
  -- Returns the effect amount
  return self.ui_effect_amount.value
end


function CellsMixerFx:SetEffectTarget(index)
  -- Sets the target of the effects section
  
  if index == 1 then
    self.track_a.devices[3].is_active = true
    self.track_b.devices[3].is_active = false
  elseif index == 2 then
    self.track_a.devices[3].is_active = true
    self.track_b.devices[3].is_active = true
  elseif index == 3 then
    self.track_a.devices[3].is_active = false
    self.track_b.devices[3].is_active = true
  end
  
  cf:SetFXTarget(index)
end


function CellsMixerFx:MoveEffectTarget(value)
  -- Update the UI control which calls SetEffectTarget
  
  self.ui_effect_target.value = value
end


function CellsMixerFx:GetEffectTarget()
  -- Returns the effect target
  return self.ui_effect_target.value
end


function CellsMixerFx:SetMasterVolume(lin)
  -- Sets the master channel volume
  self.track_master.prefx_volume.value = lin  
  self.ui_master_volume.tooltip = string.format("%+6.2f dB", math.lin2db(lin))
  cf:SetMasterVolume(lin / 1.4125376) -- x / math.db2lin(3)
end


function CellsMixerFx:MoveMasterVolume(value)
  -- Update the UI control which calls SetMasterVolume
  
  self.ui_master_volume.value = value * self.ui_master_volume.max
end


function CellsMixerFx:GetMasterVolume()
  -- Returns the master volume
  return (self.ui_master_volume.value / self.ui_master_volume.max)
end


function CellsMixerFx:SetCueVolume(lin)
  -- Sets the master channel volume
  self.track_cue.prefx_volume.value = lin
  self.ui_cue_volume.tooltip = string.format("%+6.2f dB", math.lin2db(lin))
  cf:SetCueVolume(lin / 1.4125376) -- x / math.db2lin(3)
end


function CellsMixerFx:MoveCueVolume(value)
  -- Update the UI control which calls SetCueVolume
  
  self.ui_cue_volume.value = value * self.ui_cue_volume.max
end


function CellsMixerFx:GetCueVolume()
  -- Returns the cue volume
  return (self.ui_cue_volume.value / self.ui_cue_volume.max)
end


function CellsMixerFx:SetCrossfader(val)
  -- Updates the A/B send volumes from the crossfader position
  
  self.track_a.prefx_volume.value = math.min(2-(2*val), 1)
  self.track_b.prefx_volume.value = math.min(val*2, 1)
  cf:SetCrossfader(val)
end


function CellsMixerFx:MoveCrossfader(val)
  -- Updates the UI control which calls SetCrossfader
  
  self.ui_crossfader.value = val
end


function CellsMixerFx:GetCrossfader()
  -- Returns the crossfader position
  return self.ui_crossfader.value
end


function CellsMixerFx:SetCutState(group, state)
  -- Sets the cut status and updates the ui
  
  if group == 0 then
    -- a
    if state then
      -- on
      self.ui_cut_a.color = COLOUR_GREEN
      self.track_a.devices[2].is_active = true
    else
      -- off
      self.ui_cut_a.color = COLOUR_GREY
      self.track_a.devices[2].is_active = false
    end   
  else
    -- b
    if state then
      -- on
      self.ui_cut_b.color = COLOUR_GREEN
      self.track_b.devices[2].is_active = true
    else
      -- off
      self.ui_cut_b.color = COLOUR_GREY
      self.track_b.devices[2].is_active = false
    end   
  end
  
  cf:SetCrossfaderCut(group, state)
end


function CellsMixerFx:GetCutState(group)
  -- Returns the cut state for the specified group
  if group == 0 then
    -- a
    return self.track_a.devices[2].is_active
  else
    -- b
    return self.track_b.devices[2].is_active
  end
end    


function CellsMixerFx:AssignChannelGroups()
  -- Equally distributed the channels across the A/B groups
  
  for i = 1, math.floor(preferences.channel_count.value / 2) do
    cc[i]:MoveRouting(CELLS_ROUTING_A)
  end
  
  for i = math.floor(preferences.channel_count.value / 2) + 1, preferences.channel_count.value do
    cc[i]:MoveRouting(CELLS_ROUTING_B)
  end
end


function CellsMixerFx:GetCellsChannel()
  -- Return the Cells! channel index or 0 if selected track is not a cells channel
  
  local tn = renoise.song().selected_track.name
  
  if string.sub(tn, 1, 7) == "Cells! " then
    -- cells track
    if string.sub(tn, 8, 9) == "F" then
      -- FX
      return 0
    elseif string.sub(tn, 8, 9) == "A" then
      -- A group
      return 0
    elseif string.sub(tn, 8, 9) == "B" then
      -- B group
      return 0
    elseif string.sub(tn, 8, 9) == "C" then
      -- Cue
      return 0
    else
      -- Channel
      return tonumber(string.sub(tn, 8, string.len(tn)))
    end
  end
end
