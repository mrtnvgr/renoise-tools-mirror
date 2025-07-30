--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Cells Transport Code
--------------------------------------------------------------------------------


--[[
CellsTransport()
CellsTransport.ui_beat_indicators[]
CellsTransport.ui_start_stop
CellsTransport.ui_bpm_value
CellsTransport.ui_bpm_nudge_up
CellsTransport.ui_bpm_nudge_down
CellsTransport.ui_quantize_selector
CellsTransport.ui_frame
CellsTransport.line_cache
CellsTransport.bar_count_line
CellsTransport:__init()
CellsTransport:GetUI()
CellsTransport:BindHooks()
CellsTransport:UnbindHooks()
CellsTransport:PreparePatterns())
CellsTransport:TogglePlayState()
CellsTransport:SetBpm(bpm)
CellsTransport:NudgeBpm(delta, state)
CellsTranspoer:UpdateBpmDisplay(bpm)
CellsTransport:SetQuantizeValue(index)
CellsTransport:GetNextQuantizeLine()
CellsTransport:IdleHook()
CellsTransport:TrackChangeHook()
CellsTransport:LineTick(line)
CellsTransport:GetLine()
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "CellsTransport"



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function CellsTransport:__init()
  -- Initialise
  
  local vb = renoise.ViewBuilder()
  
  --
  -- Initialise class variables
  --
  self.ui_beat_indicators = {}
  self.ui_start_stop = nil
  self.ui_bpm_value = nil
  self.ui_bpm_nudge_up = nil
  self.ui_bpm_nudge_down = nil
  self.ui_quantize_selector = nil
  self.ui_frame = nil
  self.line_cache = 0
  self.bar_count_line = 0
  self.selected_track_index_cache = 1

  --
  -- Create GUI elements
  --
  self.ui_start_stop = vb:button{
    text = "Stopped",
    width = 100,
    color = COLOUR_YELLOW,
    notifier = function()
      self:TogglePlayState()
    end
  }

  self.ui_bpm_value = vb:valuebox{
    min=32,
    max=999,
    value = preferences.base_bpm.value,
    notifier = function(v)
      self:SetBpm(v)
    end
  }
  
  self.ui_bpm_nudge_up = vb:button{
    text="+",
    color = COLOUR_GREY,
    pressed = function()
      self:NudgeBpm(1, true)
    end,
    released = function()
      self:NudgeBpm(1, false)
    end,
  }
  
  self.ui_bpm_nudge_down = vb:button{
    text="-",
    color = COLOUR_GREY,
    pressed = function()
      self:NudgeBpm(-1, true)
    end,
    released = function()
      self:NudgeBpm(-1, false)
    end,
  }

  for i = 1, 4 do
    table.insert(self.ui_beat_indicators,
                 vb:button{
                   height = 18,
                   width = 18,
                   color = COLOUR_BLACK,
                 })
  end
  
  self.ui_quantize_selector = vb:switch{
    items = {"1/2", "1", "2", "4"},
    value = 4,
    width = 100,
    notifier = function(index)
      self:SetQuantizeValue(index)
    end
  }
  
  -- main frame
  self.ui_frame = vb:row{
    style = "group",
    spacing = 0,
    margin = 0,
      vb:vertical_aligner{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
            
      vb:horizontal_aligner{
        mode = "justify",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        self.ui_start_stop,
      },
      
      vb:horizontal_aligner{
        mode = "justify",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        self.ui_beat_indicators[1],
        self.ui_beat_indicators[2],
        self.ui_beat_indicators[3],
        self.ui_beat_indicators[4],
      },
      
      vb:horizontal_aligner{
        mode = "justify",
        self.ui_bpm_nudge_down,
        self.ui_bpm_value,
        self.ui_bpm_nudge_up,
      },
      
      vb:horizontal_aligner{
        mode = "justify",
        self.ui_quantize_selector
      }
    }
  }
  
  --
  -- Setup renoise transport
  --  
  local rst = renoise.song().transport
  rst:panic()
  rst.bpm = preferences.base_bpm.value
  rst.lpb = 4
  rst.metronome_enabled = false
  rst.edit_mode = false
  
  local sp = renoise.SongPos()
  sp.sequence = 1
  sp.line = 1
  rst.playback_pos = sp
  rst.edit_pos = sp
  
  -- 
  -- Setup patterns
  --
  self:PreparePatterns()
  
  --
  -- Attach hooks
  --
  self:BindHooks()
end


function CellsTransport:PreparePatterns()
  -- Remove existing pattern sequence, create patterns and setup known state
  local rs = renoise.song() 
  local patt
  
  -- Reset existing pattern sequence
  rs.sequencer.pattern_sequence = {1}
  patt = rs:pattern(1)
  patt.number_of_lines=16
  patt:clear()
end


function CellsTransport:GetUI()
  -- Returns the Transport UI

  return self.ui_frame
end


function CellsTransport:TogglePlayState()
  -- Toggle the playback state if not a slave node
  -- Updating of ui / controller is handled by a playing_observable hook

  local rst = renoise.song().transport
  
  if preferences.lan_slave.value == false then
    if rst.playing then
      rst:panic()
      cf:SetPlayState(false)
    else
      rst:trigger_sequence(1)
      cf:SetPlayState(true)
      -- TODO networking
    end
  end
end


function CellsTransport:SetBpm(value, is_midi)
  -- Set Renoise's BPM
  
  -- Quick exit in slave mode
  if preferences.lan_slave.value then
    return
  end
  
  if renoise.song().transport.bpm ~= value then
    renoise.song().transport.bpm = value
  end
  
  -- From a controller?
  if is_midi then
    self.ui_bpm_value.value = value
  end
end


function CellsTransport:NudgeBpm(delta, state)
  -- Temporary Bpm nudge
  
  -- Quick exit in slave mode
  if preferences.lan_slave.value then
    return
  end
  
  local rst = renoise.song().transport
  
  -- Update Bpm & UI
  if state == true then
    rst.bpm = rst.bpm + delta
    if delta > 0 then
      -- up
      self.ui_bpm_nudge_up.color = COLOUR_GREEN
    else
      -- down
      self.ui_bpm_nudge_down.color = COLOUR_GREEN
    end
  else
    rst.bpm = rst.bpm - delta
    if delta > 0 then
      -- up
      self.ui_bpm_nudge_up.color = COLOUR_GREY
    else
      -- down
      self.ui_bpm_nudge_down.color = COLOUR_GREY
    end
  end
end



function CellsTransport:UpdateBpmDisplay(value)
  -- Update BPM display
  
  self.ui_bpm_value.value = value
end



function CellsTransport:SetQuantizeValue(index)
  -- Set the global quantize_lines variable
  
  if index == 1 then
    quantize_lines = 2
  elseif index == 2 then
    quantize_lines = 4
  elseif index == 3 then
    quantize_lines = 8
  elseif index == 4 then
    quantize_lines = 16
  end
end


function CellsTransport:MoveQuantizeValue(enum)
  -- Update the UI control which calls SetQuantizeValue
  
  self.ui_quantize_selector.value = enum
end


function CellsTransport:GetQuantizeValue()
  -- Returns the current quantize value
  return self.ui_quantize_selector.value
end


function CellsTransport:GetNextQuantizeLine()
  -- Returns the next line for quantize trigger
  
  return (math.floor((self.bar_count_line + self.line_cache + 1) / quantize_lines) + 1) * quantize_lines
end


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function CellsTransport:BindHooks()
  -- Add hooks
  local rs = renoise.song()

  if not rs.transport.playing_observable:has_notifier(self, self.StartStopHook) then
    rs.transport.playing_observable:add_notifier(self, self.StartStopHook)
  end
  
  if not rs.selected_track_index_observable:has_notifier(self, self.TrackChangeHook) then
    rs.selected_track_index_observable:add_notifier(self, self.TrackChangeHook)
  end
  
  if not renoise.tool().app_idle_observable:has_notifier(self, self.IdleHook) then
    renoise.tool().app_idle_observable:add_notifier(self, self.IdleHook)
  end
  
  if not renoise.tool().app_release_document_observable:has_notifier(self, self.CloseSongHook) then
    renoise.tool().app_release_document_observable:add_notifier(self, self.CloseSongHook)
  end
end


function CellsTransport:UnbindHooks()
  -- Remove hooks
  local rs = renoise.song()

  if rs.transport.playing_observable:has_notifier(self, self.StartStopHook) then
    rs.transport.playing_observable:remove_notifier(self, self.StartStopHook)
  end
  
  if rs.selected_track_index_observable:has_notifier(self, self.TrackChangeHook) then
    rs.selected_track_index_observable:remove_notifier(self, self.TrackChangeHook)
  end
  
  if renoise.tool().app_idle_observable:has_notifier(self, self.IdleHook) then
    renoise.tool().app_idle_observable:remove_notifier(self, self.IdleHook)
  end
  
  if renoise.tool().app_release_document_observable:has_notifier(self, self.CloseSongHook) then
    renoise.tool().app_release_document_observable:remove_notifier(self, self.CloseSongHook)
  end
end


function CellsTransport:CloseSongHook()
  -- Just in case people try closing the song while Cells! is running
  
  -- force close
  cells_dialog:close()
  cells_dialog = nil
  cells_running_hook(true)
  
  -- inform user
  renoise.app():show_error("Renoise used 'Close Song' on Cells!  Cells! fainted")
  
end


function CellsTransport:StartStopHook()
  -- The playback state has changed
  if renoise.song().transport.playing then
    if not preferences.lan_slave.value then 
      self.ui_start_stop.text = "Playing"
    end
    self.ui_start_stop.color = COLOUR_GREEN
    self.ui_beat_indicators[1].color = COLOUR_GREEN
    cf:SetPlayState(true)
  else
    if not preferences.lan_slave.value then 
      self.ui_start_stop.text = "Stopped"
    end
    self.ui_start_stop.color = COLOUR_YELLOW
    for i = 1, 4 do
      self.ui_beat_indicators[i].color = COLOUR_BLACK
    end
    cf:SetPlayState(false)
  end
end


function CellsTransport:IdleHook()
  -- Idle spin loop
  
  local new_line = renoise.song().transport.playback_pos.line
  
  if self.line_cache == new_line then
    -- quick exit
    return
  end
  
  -- bar count
  if new_line < self.line_cache then
    self.bar_count_line = self.bar_count_line + 16
  end
  
  -- new line
  self.line_cache = new_line
  self:LineTick(self.bar_count_line + self.line_cache)
end


function CellsTransport:TrackChangeHook()
  -- Called on track selection change
  
  local new_index = renoise.song().selected_track_index
  
  if cc[new_index] then
    cc[new_index]:UpdateTrackSelection()
  end
  
  if cc[self.selected_track_index_cache] then
    cc[self.selected_track_index_cache]:UpdateTrackSelection()
  end
  
  self.selected_track_index_cache = new_index
end


function CellsTransport:LineTick(line)
  -- The playback line has changed
  
  -- Update CellsChannels
  for i = 1, #cc do
    cc[i]:Tick(line)
  end
  
  -- New beat test
  if line % 4 == 1 then
    
    local beat = (math.floor(line/4) % 4) + 1
    local old_beat = beat - 1
    
    if beat == 1 then
      old_beat = 4
    end
    
    self.ui_beat_indicators[beat].color = COLOUR_GREEN
    self.ui_beat_indicators[old_beat].color = COLOUR_BLACK
  end
  
  cf:Tick(line)
end


function CellsTransport:GetLine()
  -- quick return of current line number
  return self.bar_count_line + self.line_cache
end
