--------------------------------------------------------------------------------
-- Tuned Version of Joule's JumpToFromSend
-- v1.3b by J.R. with multiple jumps and support for multiband send
--------------------------------------------------------------------------------

class "JFTS"

JFTS.last_sendnum = nil
JFTS.last_track = nil
JFTS.last_send = nil
JFTS.pos_source = nil
JFTS.blinkTimerFunc = {}
JFTS.statusTimerFunc = nil
JFTS.origColor = {}
JFTS.origBlend = {}
JFTS.isScriptTriggered = false

require "color"

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

JFTS.useFlash = false
JFTS.statusDelay = 1

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function JFTS:pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0 
  local iter = function () 
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end


function JFTS:clearTimerFunc(last_track)
  if (self.blinkTimerFunc[last_track] ~= nil and renoise.tool():has_timer(self.blinkTimerFunc[last_track])) then
    renoise.tool():remove_timer(self.blinkTimerFunc[last_track])
    self.blinkTimerFunc[last_track] = nil
  end
end 

function JFTS:resetTrackColor(last_track)
  if (not self.useFlash) then return end 
  local trPt = renoise.song():track(last_track)
  if (trPt == nil) then return end
  self:clearTimerFunc(last_track)
  trPt.color_blend = self.origBlend[last_track]
  trPt.color = {self.origColor[last_track].r,self.origColor[last_track].g, self.origColor[last_track].b};
end

function JFTS:flashTrack(last_track)
  if (not last_track) then return end
  if (not self.useFlash) then return end 
  local trPt = renoise.song():track(last_track)
  if (self.blinkTimerFunc[last_track] ~= nil) then
    self:resetTrackColor(last_track)
  end

  self.origColor[last_track] = Color(255, trPt.color[1], trPt.color[2], trPt.color[3])
  self.origBlend[last_track] = trPt.color_blend
  local hlColor = Color(255,255,255,255)
  local transStep = 0
  self.blinkTimerFunc[last_track] = function () 
    if (transStep >= 1) then
      self:resetTrackColor(last_track)
    else
      local curColor = Color.Transition(hlColor, self.origColor[last_track], transStep)
      trPt.color = {curColor.r, curColor.g, curColor.b};
      trPt.color_blend = (1 - transStep) * 100
      transStep = transStep + 0.15
    end
  end
  renoise.tool():add_timer(self.blinkTimerFunc[last_track], 1000/60)
end

function JFTS:clearStatusFunc()
  if (self.statusTimerFunc ~= nil and renoise.tool():has_timer(self.statusTimerFunc)) then
    renoise.tool():remove_timer(self.statusTimerFunc)
    self.statusTimerFunc = nil
  end
end 

function JFTS:showStatusDelayed(message)
  self:clearStatusFunc()
  self.statusTimerFunc = function () 
    self:clearStatusFunc()
    renoise.app():show_status(message)
  end
  if self.statusDelay == 0 then
    self.statusTimerFunc()
  else
    renoise.tool():add_timer(self.statusTimerFunc, self.statusDelay)
  end

end

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function JFTS:reset()
  if (self.last_track) then
    self:resetTrackColor(self.last_track)
    self:clearStatusFunc()
  end
  self:clearStatusFunc()
  for n in pairs(self.blinkTimerFunc) do self:clearTimerFunc(n) end
  self.last_sendnum = nil
  self.last_track = nil
  self.last_send = nil
  self.pos_source = nil
  self.blinkTimerFunc = {}
  self.statusTimerFunc = nil
end

function JFTS:jump_to_send()
  local s = renoise.song()
  local pos
  local sum
  
  --if (self.last_track == nil) then return end
  
  self.isScriptTriggered = true
  -- from track
  if s.selected_track_index < s.sequencer_track_count + 1 then
    self.last_sendnum = nil
    local oldTrack = s.selected_track_index
    s.selected_track_index, pos, sum = self:find_send(oldTrack)
    if oldTrack ~= s.selected_track_index then
      self:flashTrack(oldTrack)
      self:showStatusDelayed("Routing:  " .. s:track(oldTrack).name .. " -> " .. s:track(s.selected_track_index).name .. " (" .. pos .. "/" .. sum .. ")")
    end
  -- from send
  elseif s.selected_track_index > s.sequencer_track_count + 1 and self.last_sendnum then
    s.selected_track_index, pos, sum = self:find_send(self.last_track) 
    if (sum == nil) then return end
    self:flashTrack(self.last_track)
      self:showStatusDelayed("Routing:  " .. s:track(self.last_track).name .. " -> " .. s:track(s.selected_track_index).name .. " (" .. pos .. "/" .. sum .. ")")
  end
end

function JFTS:jump_from_send()
  local s = renoise.song()
  local num_sources
  local sum
  self.isScriptTriggered = true
  
  --if (self.last_send == nil) then return end
  
  -- from track
  if s.selected_track_index < s.sequencer_track_count + 1 and self.last_send ~= nil then
    self.pos_source = self.pos_source + 1
    s.selected_track_index, num_sources = self:find_track(self.last_send)
    if (num_sources == nil) then return end
    
    self:flashTrack(self.last_send)
    self:showStatusDelayed("Routing:  " .. s:track(s.selected_track_index).name .. " (" .. self.pos_source .. "/".. num_sources .. ") -> " .. s:track(self.last_send).name)
  -- from send
  elseif s.selected_track_index > s.sequencer_track_count + 1 then
    self.last_track = nil
    self.last_send = s.selected_track_index
    s.selected_track_index, num_sources = self:find_track(s.selected_track_index) 
    if (num_sources == nil) then return end
    if self.last_send ~= s.selected_track_index then
      self:flashTrack(self.last_send)
      self:showStatusDelayed("Routing:  " .. s:track(s.selected_track_index).name .. " (" .. self.pos_source .. "/".. num_sources .. ") -> " .. s:track(self.last_send).name)
    end
  end
end

function JFTS:set_source()
  if (self.isScriptTriggered) then
    self.isScriptTriggered = false
  else
    local s = renoise.song()
    --print("selected track by user, num: "..s.selected_track_index)
    -- from track
    if s.selected_track_index < s.sequencer_track_count + 1 then
      self.last_sendnum = nil
      self.last_track = nil
      self.last_send = nil
    -- from send
    elseif s.selected_track_index > s.sequencer_track_count + 1 then
      self.last_track = s.selected_track_index
      self.last_sendnum =  s.selected_track_index
      self.last_send = s.selected_track_index
    end
  end
end



function JFTS:find_send(track)
  local s = renoise.song()
  if (track == nil) then return s.selected_track_index; end
  local map = {}
  for device in ipairs(s:track(track).devices) do
    if s:track(track).devices[device].name == "#Send" then
      map[s:track(track).devices[device].parameters[3].value] = device
    elseif s:track(track).devices[device].name == "#Multiband Send" then
      map[s:track(track).devices[device].parameters[2].value] = device
      map[s:track(track).devices[device].parameters[4].value] = device
      map[s:track(track).devices[device].parameters[6].value] = device
    end
  end
  -- count num sends + position
  local i = 1
  local countermap = {}
  for sendnum, device in self:pairsByKeys(map) do
    countermap[sendnum] = i
    i = i + 1
  end
  i = i - 1
  for sendnum, device in self:pairsByKeys(map) do
    -- first return from normal track
    if self.last_sendnum == nil then
      self.last_track = track
      self.last_sendnum = sendnum
      return s.sequencer_track_count + 2 + sendnum, countermap[sendnum], i
    -- any further return from send track
    elseif self.last_sendnum ~= nil and sendnum > self.last_sendnum then
      self.last_sendnum = sendnum
      return s.sequencer_track_count + 2 + sendnum, countermap[sendnum], i
    end
  end
  if self.last_sendnum then
    self.last_sendnum = nil
    return self:find_send(track)
  else return s.selected_track_index
  end
end

function JFTS:find_track(send)
  local s = renoise.song()
  local i2 = 1
  local send_val = send - 2 - s.sequencer_track_count
  
  -- count send sources
  local map = {}
  local num_sources = 0
  local num_sources_map = {}
  for track in ipairs(s.tracks) do
    if (i2 > send) then
      break
    end
    i2 = i2 + 1

    map[track] = {}
    for device in ipairs(s:track(track).devices) do
      local temp_dev = s:track(track).devices[device]
      if temp_dev.name == "#Send" then
        map[track][temp_dev.parameters[3].value] = device
        if ((num_sources_map[track] == nil) and (temp_dev.parameters[3].value == send_val)) then
          num_sources = num_sources + 1
          num_sources_map[track] = true
        end
      elseif temp_dev.name == "#Multiband Send" then
        map[track][temp_dev.parameters[2].value] = device
        map[track][temp_dev.parameters[4].value] = device
        map[track][temp_dev.parameters[6].value] = device
        if ((num_sources_map[track] == nil) and (
          temp_dev.parameters[2].value == send_val or
          temp_dev.parameters[4].value == send_val or
          temp_dev.parameters[6].value == send_val
        )) then
          num_sources = num_sources + 1
          num_sources_map[track] = true
        end
     end
    end
  end
    
  i2 = 1
  -- logic
  for track in ipairs(s.tracks) do
  
    if (i2 > send) then
      break
    end
    i2 = i2 + 1
    
    for sendnum, device in self:pairsByKeys(map[track]) do
      if self.last_track == nil and sendnum == self.last_send - 2 - s.sequencer_track_count then
        self.last_track = track
        self.pos_source = 1
        return track, num_sources
      elseif self.last_track ~= nil and track > self.last_track and sendnum == self.last_send - 2 - s.sequencer_track_count then
        self.last_track = nil
        self.last_track = track
        return track, num_sources
      end
    end
  end
  if self.last_track then
    self.last_track = nil
    return self:find_track(send)
  else return s.selected_track_index
  end
end

function JFTS:register_keys()

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

  renoise.tool():add_keybinding {
    name = "Global:Tools:Jump to send",
    invoke = function() self:jump_to_send() end
  }
  renoise.tool():add_menu_entry {
    name = "Mixer:Track:Jump to send",
    invoke = function()self:jump_to_send() end
  }
  renoise.tool():add_menu_entry {
    name = "Pattern Editor:Track:Jump to send",
    invoke = function() self:jump_to_send() end
  }
  renoise.tool():add_keybinding {
    name = "Global:Tools:Jump from send",
    invoke = function() self:jump_from_send() end
  }
  renoise.tool():add_menu_entry {
    name = "Mixer:Track:Jump from send",
    invoke = function() self:jump_from_send() end
  }
  renoise.tool():add_menu_entry {
    name = "Pattern Editor:Track:Jump from send",
    invoke = function() self:jump_from_send() end
  }
end


function JFTS:__init()
  local selectFunc = function()
    self:set_source()
  end
  
  local resetFunc = function() 
    if (not renoise.song().selected_track_index_observable:has_notifier(selectFunc)) then
      renoise.song().selected_track_index_observable:add_notifier(selectFunc)
    end
    
    self:reset()
  end
  
  if (not renoise.tool().app_new_document_observable:has_notifier(resetFunc)) then
    renoise.tool().app_new_document_observable:add_notifier(resetFunc)
  end
  
end


