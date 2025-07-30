--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Cells Channel Code
--------------------------------------------------------------------------------


--[[
CellsChannel()
CellsChannel.ui_instrument_popup
CellsChannel.ui_volume
CellsChannel.ui_panning
CellsChannel.ui_transpose
CellsChannel.ui_bass_kill
CellsChannel.ui_filter
CellsChannel.ui_mute
CellsChannel.ui_stop
CellsChannel.ui_cue
CellsChannel.ui_jam
CellsChannel.ui_select
CellsChannel.ui_cells[]
CellsChannel.ui_cell_position
CellsChannel.ui_frame
CellsChannel.ui_cell_offset
CellsChannel.track
CellsChannel.pattern_track
CellsChannel.channel_index
CellsChannel.current_instrument_name
CellsChannel.current_instrument_info
CellsChannel.play_cell_index          -1 = invalid, 0 = cue stop
CellsChannel.play_cell_playmode
CellsChannel.play_trigger_line
CellsChannel.play_trigger_note
CellsChannel.play_trigger_instrument
CellsChannel.play_granular_step
CellsChannel.play_writing_stream
CellsChannel.play_is_loop
CellsChannel.play_length_lines
CellsChannel.play_note_table
CellsChannel.cued_length_lines
CellsChannel.cued_writing_stream
CellsChannel.cued_cell_index          -1 = invalid, 0 = cue stop
CellsChannel.cued_cell_playmode
CellsChannel.cued_trigger_line
CellsChannel.cued_trigger_note
CellsChannel.cued_trigger_instrument
CellsChannel.cued_granular_step
CellsChannel.cued_is_loop
CellsChannel.cued_note_table
CellsChannel.can_live_jam
CellsChannel.live_jam_mode
CellsChannel.osc_last_note_off
CellsChannel:LoadInstrument(index)
CellsChannel:GetInstrument()
CellsChannel:IsSelectedTrack()
CellsChannel:SelectTrack()
CellsChannel:CueStop()
CellsChannel:CueCell(index)
CellsChannel:ToggleMute()
CellsChannel:GetMute()
CellsChannel:ToggleBassKill()
CellsChannel:GetBassKill()
CellsChannel:ToggleLiveJamMode()
CellsChannel:GetLiveJamMode()
CellsChannel:CanLiveJamMode()
CellsChannel:ToggleCue()
CellsChannel:GetCue()
CellsChannel:SetPanning(value)
CellsChannel:GetPanning()
CellsChannel:SetVolume(value)
CellsChannel:GetVolume()
CellsChannel:SetRouting(index)
CellsChannel:GetRouting()
CellsChannel:GetFilter()
CellsChannel:MoveFilter(0..1)
CellsChannel:GetTranspose()
CellsChannel:MoveTranspose(0..1)
CellsChannel:GetUI()
CellsChannel:Tick(line)
CellsChannel:NewInstrumentList()
CellsChannel:SetOffset() -- for scroll through cells
CellsChannel:ResetCellColour(cell_index)
CellsChannel:UpdateTrackSelection()
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "CellsChannel"



--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function CellsChannel:__init(index)
  -- Initialise

  local vb = renoise.ViewBuilder()
  local rs = renoise.song()

  --
  -- Class variables
  --
  self.ui_instrument_popup = nil
  self.ui_volume = nil
  self.ui_panning = nil
  self.ui_filter = nil
  self.ui_transpose = nil
  self.ui_bass_kill = nil
  self.ui_mute = nil
  self.ui_stop = nil
  self.ui_cue = nil
  self.ui_jam = nil
  self.ui_select = nil
  self.ui_cells = {}
  self.ui_cell_position = nil
  self.ui_frame = nil
  self.ui_cell_offset = 0
  
  self.channel_index = index
  self.track = nil
  self.pattern_track = nil
  
  self.current_instrument_name = ""
  self.current_instrument_info = nil
  
  self.live_jam_mode = false
  self.can_live_jam = false
  self.osc_last_note_off = nil
  
  self.cued_cell_index = -1
  self.cued_cell_playmode = -1
  self.cued_trigger_line = nil 
  self.cued_trigger_note = nil
  self.cued_trigger_instrument = nil
  self.cued_granular_step = 0
  self.cued_writing_stream = false
  self.cued_length_lines = -1
  self.cued_is_loop = false
  self.cued_note_table = {}
  
  self.play_is_loop = false
  self.play_length_lines = -1
  self.play_cell_index = -1
  self.play_cell_playmode = -1
  self.play_trigger_note = nil
  self.play_trigger_instrument = nil
  self.play_trigger_line = -1
  self.play_writing_stream = false
  self.play_granular_step = 0
  self.play_note_table = {}

  --
  -- UI Elements
  --
  
  -- Popups
  self.ui_instrument_popup = vb:popup{
    items = im:GetInstrumentNames(),
    value = 1,
    width = preferences.cell_width.value,
    notifier = function(index)
      self:LoadInstrument(index)
    end
  }
  
  -- Buttons
  self.ui_stop = vb:button{
    text = "Stop",
    tooltip = "Quantized stop",
    width = 38,
    color = COLOUR_GREY,
    notifier = function()
      self:CueStop()
    end
  }
  
  self.ui_mute = vb:button{
    text = "Mute",
    tooltip = "Channel mute toggle",
    width = 38,
    color = COLOUR_GREY,
    notifier = function()
      self:ToggleMute()
    end
  }
  
  self.ui_bass_kill = vb:button{
    text = "Kill",
    tooltip = "Bass kill toggle",
    width = 38,
    color = COLOUR_GREY,
    notifier = function()
      self:ToggleBassKill()
    end
  }
  
  self.ui_cue = vb:button{
    text = "Cue",
    tooltip = "Cue toggle",
    width = 38,
    color = COLOUR_GREY,
    notifier = function()
      self:ToggleCue()
    end
  }
  
  self.ui_jam = vb:button{
    text = "Jam",
    tooltip = "Live jamming mode toggle",
    width = 38,
    color = COLOUR_BLACK,
    notifier = function()
      self:ToggleLiveJamMode()
    end
  }
  
  self.ui_select = vb:button{
    text = "Sel",
    tooltip = "Select this track",
    width = 38,
    color = COLOUR_GREY,
    notifier = function()
      self:SelectTrack()
    end
  }
  
  -- Cells
  self.ui_cells = {}
  for i = 1, preferences.cells_count.value do
    table.insert(self.ui_cells, vb:button{
      text = "",
      tooltip = "",
      width = preferences.cell_width.value,
      height = preferences.cell_height.value,
      color = COLOUR_BLACK,
      pressed = function()
        self:CueCell(i)
      end
    })
  end
  
  
  -- Rotaries
  self.ui_panning = vb:rotary{
    min = 0,
    max = 1,
    value = 0.5,
    tooltip = "00 L",
    notifier = function(v)
      self:SetPanning(v)
    end
  }
  
  self.ui_transpose = vb:rotary{
    min = -12,
    max = 12.1,
    value = 0,
    tooltip = "Transpose: 0",
    notifier = function(v)
      self:SetTranspose(v)
    end
  }
  
  self.ui_filter = vb:rotary{
    min = 0,
    max = 1,
    value = 1,
    tooltip = "100%",
    notifier = function(v)
      self:SetFilter(v)
    end
  }
  
  -- Sliders
  self.ui_volume = vb:minislider{
    height = 128,
    width = 34,
    min = 0,
    max = math.db2lin(3),
    value = math.db2lin(0),
    notifier = function(v)
      self:SetVolume(v)
    end
  }
  
  self.ui_cell_position = vb:minislider{
    width = preferences.cell_width.value,
    min = 1,
    max = 1,
    value = 1,
  }
  
  -- Switches
  self.ui_routing = vb:switch{
    items = {"A", "M", "B"},
    width = 76,
    value = 1,
    notifier = function(index)
      self:SetRouting(index)
    end
  }
  
  -- Cell frame
  self.ui_cell_frame = vb:column{
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = 0,
    
    -- instrument
    self.ui_instrument_popup,
  }
  
  -- add cells
  for i = 1, preferences.cells_count.value do
    self.ui_cell_frame:add_child(self.ui_cells[i])
  end
  
  -- add indicator
  self.ui_cell_frame:add_child(self.ui_cell_position)
  
  -- UI Frame
  self.ui_frame = vb:column{
    style = "group",
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    
    -- cells
    self.ui_cell_frame,
    
    -- below cells
    vb:horizontal_aligner{
      mode = "justify",

      -- volumn column
      vb:vertical_aligner {
        mode = "justify",
        self.ui_panning,
        self.ui_volume,
        self.ui_mute,
      },
      
      -- control column
      vb:vertical_aligner { 
        spacing = 4,    
        self.ui_stop,
        self.ui_transpose,
        self.ui_filter,
        self.ui_bass_kill,
        self.ui_cue,
        self.ui_jam,
        self.ui_select,
      },
    },
    
    -- bottom routing selector
    vb:horizontal_aligner{
      mode = "justify",  
      self.ui_routing
    },
  }
  
  --
  -- Setup track
  --
  
  -- remove any existing tracks with this channel number
  for t = #rs.tracks, 1, -1 do
    if rs.tracks[t].name == string.format("Cells! %d", self.channel_index) then
      rs:delete_track_at(t)
    end
  end
  
  -- add a new track
  self.track = rs:insert_track_at(self.channel_index)
  
  -- set track settings
  self.track.name = string.format("Cells! %d", self.channel_index)
  self.track.visible_note_columns = 4
  self.track.visible_effect_columns = 1
  self.track.panning_column_visible = false
  self.track.delay_column_visible = true
  self.track.volume_column_visible = true
  self.track.collapsed = true
  
  -- add track devices
  self.track:insert_device_at(FILTER_DEVICE_ID, 2)
  self.track.devices[2].display_name = "Cells! Bass Kill"
  self.track.devices[2].is_active = false
  self.track.devices[2].is_maximized = false
  self.track.devices[2].parameters[1].value = 4     -- type
  self.track.devices[2].parameters[2].value = 0.05  -- cutoff  
  self.track:insert_device_at(FILTER_DEVICE_ID, 3)
  self.track.devices[3].display_name = "Cells! Channel Filter"
  self.track.devices[3].is_active = false
  self.track.devices[3].is_maximized = false
  self.track.devices[3].parameters[1].value = 1 -- HS
  self.track.devices[3].parameters[2].value = 1 -- cutoff (0 -- 1)
  self.track.devices[3].parameters[3].value = 2 -- resonance
  self.track:insert_device_at(SEND_DEVICE_ID, 4)
  self.track.devices[4].display_name = "Cells! Cue send"
  self.track.devices[4].active_preset_data = ([[
    <?xml version="1.0" encoding="UTF-8"?>
    <FilterDevicePreset doc_version="9">
      <DeviceSlot type="SendDevice">
        <DestSendTrack>
          <Value>%d</Value>
        </DestSendTrack>
        <MuteSource>%s</MuteSource>
      </DeviceSlot>
    </FilterDevicePreset>
    ]]):format(3, "false")  -- taktik's madness
  self.track.devices[4].is_active = false
  self.track.devices[4].is_maximized = false
  self.track:insert_device_at(SEND_DEVICE_ID, 5)
  self.track.devices[5].display_name = "Cells! A only send"
  self.track.devices[5].active_preset_data = ([[
    <?xml version="1.0" encoding="UTF-8"?>
    <FilterDevicePreset doc_version="9">
      <DeviceSlot type="SendDevice">
        <DestSendTrack>
          <Value>%d</Value>
        </DestSendTrack>
        <MuteSource>%s</MuteSource>
      </DeviceSlot>
    </FilterDevicePreset>
    ]]):format(0, "true")
  self.track.devices[5].is_active = false
  self.track.devices[5].is_maximized = false
  self.track:insert_device_at(SEND_DEVICE_ID, 6)
  self.track.devices[6].display_name = "Cells! A/B send"
  self.track.devices[6].active_preset_data = ([[
    <?xml version="1.0" encoding="UTF-8"?>
    <FilterDevicePreset doc_version="9">
      <DeviceSlot type="SendDevice">
        <DestSendTrack>
          <Value>%d</Value>
        </DestSendTrack>
        <MuteSource>%s</MuteSource>
      </DeviceSlot>
    </FilterDevicePreset>
    ]]):format(0, "false")
  self.track.devices[6].is_active = false
  self.track.devices[6].is_maximized = false
  
  self.track:insert_device_at(SEND_DEVICE_ID, 7)
  self.track.devices[7].display_name = "Cells! B send"
  self.track.devices[7].active_preset_data = ([[
    <?xml version="1.0" encoding="UTF-8"?>
    <FilterDevicePreset doc_version="9">
      <DeviceSlot type="SendDevice">
        <DestSendTrack>
          <Value>%d</Value>
        </DestSendTrack>
        <MuteSource>%s</MuteSource>
      </DeviceSlot>
    </FilterDevicePreset>
    ]]):format(1, "true")

  self.track.devices[7].is_active = true
  self.track.devices[7].is_maximized = false
  
  -- get pattern track reference
  self.pattern_track = rs.patterns[1].tracks[self.channel_index]
  
  -- defaults
  self:SetPanning(0.5)
  self:SetVolume(math.db2lin(0))
  self:SetFilter(1)
  self:SetRouting(1)
  self.track:unmute()
  
  -- reset
  self:ClearChannel()
  self.ui_instrument_popup.value = 1
  self.current_instrument_name = "None"
end


function CellsChannel:GetUI()
  -- Returns the interface
  return self.ui_frame
end


function CellsChannel:SetVolume(value)
  -- Set track volume

  self.track.prefx_volume.value = value
  
  -- update tooltip
  self.ui_volume.tooltip = string.format("%+6.2f dB", math.lin2db(value))
  
  cf:SetVolume(self.channel_index, value)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:MoveVolume(value)
  -- Updates the UI control which called SetVolume
  
  self.ui_volume.value = value*1.4125
end


function CellsChannel:GetVolume()
  -- Returns the volume value
  return math.min(1,
                  math.max(0,
                           self.ui_volume.value / 1.4125))
end 


function CellsChannel:SetPanning(value)
  -- Set track panning

  self.track.prefx_panning.value = value
  
  -- update tooltip
  if value < 0.495 then
    self.ui_panning.tooltip = string.format("%02u L", (0.505-value)*100)
  elseif value > 0.505 then
    self.ui_panning.tooltip = string.format("%02u R", (value-0.495)*100)
  end
  
  cf:SetPanning(self.channel_index, value)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetPanning()
  -- Returns the panning value (0..1)
  return self.ui_panning.value
end


function CellsChannel:MovePanning(value)
  -- Updates the UI control which calls SetPanning
  
  self.ui_panning.value = value
end


function CellsChannel:SetTranspose(value)
  -- Set the transpose for the entire instrument
  
  -- ignore none
  if self.current_instrument_name == "None" then
    return
  end
  
  -- send to instrument manager
  im:SetTranspose(self.current_instrument_name, value)
  
  -- update tooltip
  self.ui_transpose.tooltip = string.format("Transpose: %d", math.floor(self.ui_transpose.value))
  
  cf:SetTranspose(self.channel_index, value/12)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetTranspose()
  -- Returns the transpose value (0..1)
  return ((self.ui_transpose.value / 24) + 0.5)
end


function CellsChannel:MoveTranspose(value)
  -- Moves the Transpose UI which calls SetTranspose
    
  self.ui_transpose.value = (value - 0.5)*24 -- scale 0..1 to -12..12
end


function CellsChannel:ToggleMute()
  -- Toggle mute state and update the UI

  if self.track.mute_state == renoise.Track.MUTE_STATE_ACTIVE then
    -- mute
    self.track.mute_state = renoise.Track.MUTE_STATE_OFF
    self.ui_mute.color = COLOUR_RED
    cf:SetMute(self.channel_index, true)
  else
    -- unmute
    self.track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
    self.ui_mute.color = COLOUR_GREY
    cf:SetMute(self.channel_index, false)
  end
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetMute()
  -- Returns the channels mute state (boolean)
  if self.track.mute_state == renoise.Track.MUTE_STATE_ACTIVE then
    return false
  else
    return true
  end
end


function CellsChannel:ToggleBassKill()
  -- Toggle the bass kill state and update the UI
  
  if self.track.devices[2].is_active then
    -- disable
    self.track.devices[2].is_active = false
    self.ui_bass_kill.color = COLOUR_GREY
    cf:SetBasskill(self.channel_index, false)
  else
    -- enable
    self.track.devices[2].is_active = true
    self.ui_bass_kill.color = COLOUR_RED
    cf:SetBasskill(self.channel_index, true)
  end
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetBassKill()
  -- Returns the bass kill state (boolean)
  if self.track.devices[2].is_active then
    return true
  else
    return false
  end
end


function CellsChannel:SetFilter(value)
  -- Sets the channel filter
  
  -- set cutoff
  self.track.devices[3].parameters[2].value = value
  
  -- enable/disable
  if value == 1 then
    self.track.devices[3].is_active = false
  else
    self.track.devices[3].is_active = true
  end
  
  self.ui_filter.tooltip = string.format("%u%%", math.floor(value*100))
  
  cf:SetFilter(self.channel_index, value)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:MoveFilter(value)
  -- Move the filter UI which calls SetFilter
  self.ui_filter.value = value
end


function CellsChannel:GetFilter()
  -- Returns the filter value (0..1)
  return self.ui_filter.value
end


function CellsChannel:ToggleCue()
  -- Toggle the channels cue status and update the UI
  
  if self.track.devices[4].is_active then
    -- disable
    self.track.devices[4].is_active = false
    self.ui_cue.color = COLOUR_GREY
    cf:SetCue(self.channel_index, false)
  else
    -- enable
    self.track.devices[4].is_active = true
    self.ui_cue.color = COLOUR_GREEN
    cf:SetCue(self.channel_index, true)
  end
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetCue()
  -- Returns the cue state (boolean)
  if self.track.devices[4].is_active then
    return true
  else
    return false
  end
end


function CellsChannel:SelectTrack()
  -- Select this track

  renoise.song().selected_track_index = self.channel_index
end


function CellsChannel:IsSelectedTrack()
  -- Returns if the current renoise selected track is the same as this cells channel track
  
  if renoise.song().selected_track_index == self.channel_index then
    return true
  else
    return false
  end
end


function CellsChannel:ToggleLiveJamMode()
  -- Toggles live jam mode if available
  
  -- ignore if not possible
  if not self.can_live_jam then
    return
  end
  
  -- reset
  if self.play_cell_index ~= -1 then
    self:ResetCellColour(self.play_cell_index)
    self.play_cell_index = -1
  end
  if self.cued_cell_index ~= -1 then
    -- cancel cue
    self:ResetCellColour(self.cued_cell_index)
    self.cued_cell_index = -1
  end
  
  if self.live_jam_mode then
    -- disable
    if self.osc_last_note_off then
      nm:LocalSend(self.osc_last_note_off)
      self.osc_last_note_off = nil
    end
    self.ui_jam.color = COLOUR_YELLOW
    self.live_jam_mode = false
    cf:SetJam(self.channel_index, false)
  else
    -- enable
    self.ui_cell_position.value = self.ui_cell_position.min
    self.cued_writing_stream = false
    self.play_writing_stream = false
    self:WriteNoteOffs()
    self.ui_jam.color = COLOUR_GREEN
    self.live_jam_mode = true
    cf:SetJam(self.channel_index, true)
  end
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetLiveJamMode()
  -- Returns if live jam mode is enabled (boolean)
  
  return self.live_jam_mode
end


function CellsChannel:CanLiveJamMode()
  -- Returns if live jam mode is possible
  
  return self.can_live_jam
end


function CellsChannel:UpdateTrackSelection()
  -- Update the track selection indicator button as required
  
  if renoise.song().selected_track_index == self.channel_index then
    self.ui_select.color = COLOUR_GREEN
    cf:SetSelected(self.channel_index)
  else
    self.ui_select.color = COLOUR_GREY
  end
end


function CellsChannel:SetRouting(index)
  -- Sets the channel routing based
  
  if index == 1 then
    -- A only
    self.track.devices[5].is_active = true
    self.track.devices[6].is_active = false
    self.track.devices[7].is_active = false
  elseif index == 2 then
    -- M = A&B
    self.track.devices[5].is_active = false 
    self.track.devices[6].is_active = true
    self.track.devices[7].is_active = true
  elseif index == 3 then
    -- B only
    self.track.devices[5].is_active = false 
    self.track.devices[6].is_active = false 
    self.track.devices[7].is_active = true
  end
  
  cf:SetRouting(self.channel_index, index)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:GetRouting()
  -- Returns the routing (0..1)
  return self.ui_routing.value
end


function CellsChannel:MoveRouting(enum)
  -- Updates the UI routing switch which calls SetRouting
  
  self.ui_routing.value = enum
end


function CellsChannel:LoadInstrument(index)
  -- Load a new instrument
  
  local reload_playing_instrument = true
  
  -- reload check (for reordering instruments)
  if self.current_instrument_name ~= self.ui_instrument_popup.items[self.ui_instrument_popup.value] then
    self:ClearChannel()
    reload_playing_instrument = false
  end
  
  self.current_instrument_name = self.ui_instrument_popup.items[self.ui_instrument_popup.value]
  
  -- none exits
  if self.current_instrument_name == "None" then
    self.ui_transpose.value = 0
    self.can_live_jam = false
    self.ui_jam.color = COLOUR_BLACK
    self:ClearChannel()
    return
  end
  
  -- get cell information from InstrumentManager
  self.current_instrument_info = im:GetInstrumentInfo(self.current_instrument_name)
  
  -- update controls
  self.ui_transpose.value = self.current_instrument_info[3] -- transpose
  
  -- jam mode
  local jam = false
  
  for i = 1, self.current_instrument_info[4] do
    if (self.current_instrument_info[4+i][9] == PLAYMODE_SLICES) or (self.current_instrument_info[4+i][9] == PLAYMODE_ONESHOT) then
      jam = true
    end
  end
  
  -- found an appropriate sample
  if jam then
    self.can_live_jam = true
    self.ui_jam.color = COLOUR_YELLOW
  else
    self.can_live_jam = false
    self.ui_jam.color = COLOUR_BLACK
  end
  
  if not reload_playing_instrument then
    -- defaults
    self.live_jam_mode = false --off by default
  end

  -- TODO Cell paging
  
  -- update cells
  for i = 1, math.min(self.current_instrument_info[4], #self.ui_cells) do
  
    -- cell name
    self.ui_cells[i].text = string.sub(self.current_instrument_info[4+i][1], 1, 9)
    if self.current_instrument_info[4+i][9] == PLAYMODE_SLICES then
      self.ui_cells[i].tooltip = self.current_instrument_info[4+i][1]
    elseif self.current_instrument_info[4+i][9] == PLAYMODE_ONESHOT then
      self.ui_cells[i].tooltip = self.current_instrument_info[4+i][1]
    else
      self.ui_cells[i].tooltip = self.current_instrument_info[4+i][1] ..
                                 string.format("\nBeats:%d", math.floor(self.current_instrument_info[4+i][5]/4))
    end
    
    -- cell colour
    self:ResetCellColour(i)
  end
  
  -- reset playing colour if applicable
  if reload_playing_instrument then
    if self.play_cell_index > 0 then
      self.ui_cells[self.play_cell_index].color = COLOUR_GREEN
      cf:SetCellState(self.channel_index, self.play_cell_index, CELLSTATE_PLAYING)
    end
  end
  
  -- update stream writing cache  (renoise numbers, not lua)
  self.play_trigger_instrument = self.current_instrument_info[2] - 1
  self.cued_trigger_instrument = self.current_instrument_info[2] - 1
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:MoveInstrument(value)
  -- Updates the UI instrument popup which calls LoadInstrument
  
  self.ui_instrument_popup.value = math.floor(1 + (value * (#self.ui_instrument_popup.items - 0.1)))
end


function CellsChannel:GetInstrument()
  -- Returns the instrument index as a scaled value from 0 to 1
  returns ((self.ui_instrument_popup.value - 1)/(#self.ui_instrument_popup.items - 1))
end


function CellsChannel:ResetCellColour(cell_index)
  -- Reset a cells colour
  
  -- ignore invalid cells
  if cell_index < 1 then
    return
  end
  
  if self.current_instrument_info[4+cell_index][9] == PLAYMODE_ONESHOT then
    self.ui_cells[cell_index].color = COLOUR_OFFWHITE
  elseif self.current_instrument_info[4+cell_index][9] == PLAYMODE_REPITCH then
    if self.current_instrument_info[4+cell_index][6] then
      self.ui_cells[cell_index].color = COLOUR_DBLUE
    else
      self.ui_cells[cell_index].color = COLOUR_LBLUE
    end
  elseif self.current_instrument_info[4+cell_index][9] == PLAYMODE_GRANULAR then
    self.ui_cells[cell_index].color = COLOUR_PURPLE
  elseif self.current_instrument_info[4+cell_index][9] == PLAYMODE_SLICES then
    self.ui_cells[cell_index].color = COLOUR_CYAN
  elseif self.current_instrument_info[4+cell_index][9] == PLAYMODE_NOTES then
    if self.current_instrument_info[4+cell_index][6] then
      self.ui_cells[cell_index].color = COLOUR_ORANGE
    else
      self.ui_cells[cell_index].color = COLOUR_LORANGE
    end
  end
  
  cf:SetCellState(self.channel_index, cell_index, CELLSTATE_VALID)
end


function CellsChannel:NewInstrumentList(list)
  -- A new instrument list is being pushed from InstrumentManager
   
  if self.current_instrument_name ~= "None" then
    -- we have an instrument loaded, does it still exist in the new list?
        
    local new_info = im:GetInstrumentInfo(self.current_instrument_name)
    
    if new_info ~= "Removed" then
      -- yes, update info
      self.current_instrument_info = new_info
      self.ui_instrument_popup.items = list
      
      
      self.ui_instrument_popup.value = table.find(list, self.current_instrument_name)
      
      -- stream writing cache update
      self.play_trigger_instrument = self.current_instrument_info[2] - 1
      self.cued_trigger_instrument = self.current_instrument_info[2] - 1
    else
      -- no, clear and discard channel
      self:ClearChannel()
      self.ui_instrument_popup.value = 1
      self.current_instrument_name = "None"
      self.ui_instrument_popup.items = list
    end
  else
    -- no instrument selected just update ui
    self.ui_instrument_popup.items = list
  end
end


function CellsChannel:ClearChannel()
  -- Clear all cells and fill track with note offs
  
  -- stop playback flag
  self.play_cell_index = -1
  self.cued_cell_index = -1
  self.play_writing_stream = false
  
  local rs = renoise.song()
  self.current_instrument_info = nil
  
  -- send any note offs
  self:WriteNoteOffs()
  
  if self.osc_last_note_off then
    nm:LocalSend(self.osc_last_note_off)
    self.osc_last_note_off = nil
  end
  
  -- clear cells
  for i = 1, #self.ui_cells do
    self.ui_cells[i].color = COLOUR_BLACK
    self.ui_cells[i].text = ""
    cf:SetCellState(self.channel_index, i, CELLSTATE_INVALID)
  end
  
  -- reset position
  self.ui_cell_position.max = self.ui_cell_position.min + 1
  self.ui_cell_position.value = self.ui_cell_position.min
end


function CellsChannel:WriteNoteOffs()
  -- place note off
  
  local next_line = (renoise.song().transport.playback_pos.line % 16) + 1
  for i = 1, 4 do
    self.pattern_track:line(next_line):note_column(i).note_value = renoise.PatternTrackLine.NOTE_OFF
    self.pattern_track:line(next_line+1):note_column(i).note_value = renoise.PatternTrackLine.NOTE_OFF
    self.pattern_track:line(next_line+2):note_column(i).note_value = renoise.PatternTrackLine.NOTE_OFF
  end
end


function CellsChannel:CueCell(cell_index)
  -- Cue / Play a cell
  
  -- quietly drop invalid cell references (from controllers)
  if cell_index > preferences.cells_count.value then
    return
  end
  
  -- is an invalid cell?
  if self.ui_cells[cell_index].color[1] == 1 then
    -- invalid = stop?
    if preferences.blank_is_stop.value then
      self:CueStop()
    end
    
    return
  end
  
  -- already qued?
  if self.cued_cell_index > 0 then
    if (self.cued_trigger_line - ct:GetLine()) < 2 then
      if (self.cued_cell_playmode == PLAYMODE_GRANULAR) or (self.cued_cell_playmode == PLAYMODE_NOTES) then
        -- stream writing has started so ignore abort as too late!
        return
      end
    end
    
    -- reset cell and continue
    self:ResetCellColour(self.cued_cell_index)
  end
  
  -- TODO cell paging

  local inst_number = self.current_instrument_info[2]
  local cell_info = self.current_instrument_info[4+cell_index]
  self.cued_cell_playmode = cell_info[9]
  
  if self.live_jam_mode then
    -- live playing of slices
    
    -- silently ignore note based cell (1st cell in sliced samples)
    if self.cued_cell_playmode == PLAYMODE_NOTES then
      return
    end
 
    local msg = renoise.Osc.Message
    
    -- reset last note
    if self.osc_last_note_off then
      nm:LocalSend(self.osc_last_note_off)
      self.osc_last_note_off = nil
      self:ResetCellColour(self.play_cell_index)
    end
        
    nm:LocalSend(msg("/renoise/trigger/note_on",
                     {{tag="i", value=inst_number-1},       -- instrument
                     {tag="i", value=self.channel_index-1}, -- track
                     {tag="i", value=cell_info[3]},       -- note
                     {tag="i", value=127}}))              -- velocity
                       
    self.osc_last_note_off = msg("/renoise/trigger/note_off",
                       {{tag="i", value=inst_number-1},
                       {tag="i", value=self.channel_index-1},
                       {tag="i", value=cell_info[3]}})
                       
    -- set cell colour
    self.ui_cells[cell_index].color = COLOUR_GREEN
    self.play_cell_playmode = self.cued_cell_playmode
    self.cued_cell_index = -1
    self.play_cell_index = cell_index
    cf:SetCellState(self.channel_index, cell_index, CELLSTATE_PLAYING)
    
  else
    -- normal quantized playback
    
    -- set cell colour
    self.ui_cells[cell_index].color = COLOUR_YELLOW
    
    cf:SetCellState(self.channel_index, cell_index, CELLSTATE_CUED)
  
    -- set cue info
    self.cued_trigger_line = ct:GetNextQuantizeLine()
    self.cued_trigger_note = cell_info[3]
    self.cued_trigger_instrument = inst_number - 1        -- -1 as this is the Renoise numbering
    self.cued_cell_index = cell_index
    self.cued_is_loop = cell_info[6]
    self.cued_length_lines = cell_info[5]
     
    -- extra stuff for granular stretch
    if self.cued_cell_playmode == PLAYMODE_GRANULAR then
      self.cued_granular_step = 256/cell_info[5]
    end
    
    -- extra stuff for sliced stretch
    if self.cued_cell_playmode == PLAYMODE_NOTES then
      self.cued_note_table = im:GetSlicedNotes(self.current_instrument_info[1], self.cued_cell_index)
    end
  end
  
  -- Automatic sample selection if enabled
  if preferences.auto_select_sample.value then
    renoise.song().selected_instrument_index = inst_number
    renoise.song().selected_sample_index = cell_info[2]
  end
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:CueStop()
  -- Cue stop
  self.cued_cell_index = 0
  self.cued_trigger_line = ct:GetNextQuantizeLine()
  self.ui_stop.color = COLOUR_RED
  cf:SetStopState(self.channel_index, CELLSTATE_CUED)
  
  -- Maybe automatically select track
  if preferences.auto_select_track.value then
    self:SelectTrack()
  end
end


function CellsChannel:Tick(line)
  -- Main event loop triggered once per line
  
  local rs = renoise.song()
  local nc -- note column
  local ec -- effect column
  local wl -- working line
  local write_line = ((line+2) % 16)+1
  


  --
  -- WRITE HEAD
  --
  self.pattern_track:line(write_line):clear()
  
  -- PLAYING STREAM WRITE AHEAD
  
  if self.play_writing_stream then
    if self.play_cell_playmode == PLAYMODE_GRANULAR then         
      -- granular stream
      if ((line + 2 - self.play_trigger_line) * self.play_granular_step) % 1 == 0 then
        
        nc = self.pattern_track:line(write_line).note_columns[1]
        nc.note_value = self.play_trigger_note
        nc.instrument_value = self.play_trigger_instrument
        nc.delay_value = 0
                  
        ec = self.pattern_track:line(write_line).effect_columns[1]
        ec.amount_value = math.mod((line + 2 - self.play_trigger_line) * self.play_granular_step, 256)    
        ec.number_value = 28
      end
            
    elseif self.play_cell_playmode == PLAYMODE_NOTES then
      -- sliced loop stream
      local note_index = ((line - self.play_trigger_line + 2) % self.play_length_lines) + 1
      local row_note_count = #self.play_note_table[note_index]

      if row_note_count > 0 then
        for i = 1, math.min(4, row_note_count) do
          
          nc = self.pattern_track:line(write_line).note_columns[i]
          nc.note_value = self.play_note_table[note_index][i][1]
          nc.volume_value = self.play_note_table[note_index][i][2]
          nc.instrument_value = self.play_trigger_instrument
          nc.delay_value = self.play_note_table[note_index][i][3]
        end
      end
    end
  end
  
  
  -- MAIN WRITE
  
  if self.cued_cell_index > 0 then  -- not invalid or stop
    if self.cued_cell_playmode == PLAYMODE_GRANULAR then
      -- granular write    
      if self.cued_writing_stream then         
        if ((line + 2 - self.cued_trigger_line) * self.cued_granular_step) % 1 == 0 then
          nc = self.pattern_track:line(write_line).note_columns[1]
          nc.note_value = self.cued_trigger_note
          nc.instrument_value = self.cued_trigger_instrument
          nc.delay_value = 0
            
          ec = self.pattern_track:line(write_line).effect_columns[1]
          ec.amount_value = math.mod((line + 2 - self.cued_trigger_line) * self.cued_granular_step, 256)
          ec.number_value = 28
        end
      else
        if write_line == (self.cued_trigger_line % 16) + 1 then
          nc = self.pattern_track:line(write_line).note_columns[1]
          nc.note_value = self.cued_trigger_note
          nc.instrument_value = self.cued_trigger_instrument
          
          ec = self.pattern_track:line(write_line).effect_columns[1]
          ec.amount_value = 0
          ec.number_value = 28
          self.cued_writing_stream = true
        end
      end

    elseif self.cued_cell_playmode == PLAYMODE_NOTES then
      -- slice write
  
      if self.cued_writing_stream then
        local note_index = ((line - self.cued_trigger_line + 2) % self.cued_length_lines) + 1
        local row_note_count = #self.cued_note_table[note_index]
        
        if row_note_count > 0 then
          for i = 1, math.min(4, row_note_count) do
            nc = self.pattern_track:line(write_line).note_columns[i]
            nc.note_value = self.cued_note_table[note_index][i][1]
            nc.volume_value = self.cued_note_table[note_index][i][2]
            nc.instrument_value = self.cued_trigger_instrument
            nc.delay_value = self.cued_note_table[note_index][i][3]
          end
        end
      else
        if write_line == (self.cued_trigger_line % 16) + 1 then
        
          local row_note_count = #self.cued_note_table[1]
          for i = 1, math.min(4, row_note_count) do
            nc = self.pattern_track:line(write_line).note_columns[i]
            nc.note_value = self.cued_note_table[1][i][1]
            nc.volume_value = self.cued_note_table[1][i][2]
            nc.instrument_value = self.cued_trigger_instrument
            nc.delay_value = self.cued_note_table[1][i][3]
          end
          self.cued_writing_stream = true
        end
      end
      
    else
      -- all other play modes
      if write_line == (self.cued_trigger_line % 16) + 1 then
        -- write note
        
        self.cued_writing_stream = false
        nc = self.pattern_track:line(write_line).note_columns[1]
        nc.note_value = self.cued_trigger_note
        nc.instrument_value = self.cued_trigger_instrument
      end
    end
  end
  
  --
  -- PLAY HEAD
  --
  if self.cued_cell_index ~= -1 then
    if line ==  self.cued_trigger_line then

      -- cue stop special case
      if self.cued_cell_index == 0 then
        self:WriteNoteOffs()
        self.ui_stop.color = COLOUR_GREY
        cf:SetStopState(self.channel_index, CELLSTATE_VALID)
      end

      -- playing -> reset
      self:ResetCellColour(self.play_cell_index)
      
      -- cued -> playing
      if self.cued_cell_index > 0 then
        self.ui_cells[self.cued_cell_index].color = COLOUR_GREEN
        cf:SetCellState(self.channel_index, self.cued_cell_index, CELLSTATE_PLAYING)
      end
      self.play_cell_index = self.cued_cell_index
      self.cued_cell_index = -1
      self.play_cell_playmode = self.cued_cell_playmode
      self.cued_cell_playmode = -1
      self.play_writing_stream = self.cued_writing_stream
      self.cued_writing_stream = false
      self.play_granular_step = self.cued_granular_step
      self.cued_granular_step = -1
      self.play_trigger_note = self.cued_trigger_note
      self.cued_trigger_note = -1
      self.play_trigger_instrument = self.cued_trigger_instrument
      self.cued_trigger_instrument = -1
      self.play_trigger_line = self.cued_trigger_line
      self.cued_trigger_line = -1
      self.play_is_loop = self.cued_is_loop
      self.cued_is_loop = false
      self.play_length_lines = self.cued_length_lines
      self.ui_cell_position.min = line
      self.ui_cell_position.max = line + self.cued_length_lines
      self.cued_length_lines = -1
      self.play_note_table = self.cued_note_table
      self.cued_note_table = {}
    end
  end


  --
  -- POSITION UPDATE
  --
  if self.play_cell_index > 0 then

    -- handle stream write ahead
    if (((line + 2) >= self.ui_cell_position.max) and (self.play_is_loop == false)) or
       (((line + 2) >= self.cued_trigger_line) and (self.cued_cell_index ~= -1)) then
      if (self.play_cell_playmode == PLAYMODE_GRANULAR) or (self.play_cell_playmode == PLAYMODE_NOTES) then
        self.play_writing_stream = false
      end
    end
    
    -- handle end of cell
    if line >= self.ui_cell_position.max then
      -- end of sample
      if self.play_is_loop then
        -- reset slider
        self.ui_cell_position.max = self.ui_cell_position.max + self.play_length_lines
        self.ui_cell_position.min = self.ui_cell_position.min + self.play_length_lines
        self.ui_cell_position.value = self.ui_cell_position.min
      else
        -- stopped
        self:ResetCellColour(self.play_cell_index)
        self.play_cell_index = -1
        self.ui_cell_position.value = self.ui_cell_position.min
        if self.cued_cell_index < 1 then
          self:WriteNoteOffs()
        end
      end
    else
      -- move slider
      self.ui_cell_position.value = line
    end
  end

end

