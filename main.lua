--------------------------------------------------------------------------------
-- EQ Helper
-- by J. Raben / ffx
-- v1.0
--------------------------------------------------------------------------------

require ('lib/lib-configurator')

sng = nil
tool = renoise.tool()

--------------------------------------------------------------------------------

class "EQHelper"

EQHelper.configurator = nil
EQHelper.config = nil


--------------------------------------------------------------------------------
-- Default Config
--------------------------------------------------------------------------------

EQHelper.defaultConfig = {
  excludedDevicesNameStart = "!",
  showReport = true, 
}

EQHelper.configDescription = {
  excludedDevicesNameStart = {type = "string", txt = "EQs/filters' names starting with this string will be excluded from transposing"}, 
  showReport = {type = "boolean", txt = "Shows a report with all devices affected"}, 
}

EQHelper.pluginRegistry = {
  { 
    enabled = true,
    paths = {"Audio/Effects/Native/EQ 5"},
    parameterNamePattern = "Frequency ?",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(semitones * math.log(2)/12) * value
      return math.max(20, math.min(20000, value))
    end      
  },
  { 
    enabled = true,
    paths = {"Audio/Effects/Native/EQ 10"},
    parameterNamePattern = "Frequency ?",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(semitones * math.log(2)/12) * value
      return math.max(20, math.min(20000, value))
    end      
  },
  { 
    enabled = true,
    paths = {"Audio/Effects/Native/Digital Filter"},
    parameterNamePattern = "Cutoff",
    transpose = function (value, parameterName, semitones) 
      value = (math.exp(value / 0.217147) - 0.9009) / 0.00495495
      value = math.exp(semitones * math.log(2)/12) * value
      value = 0.217147 * math.log(0.00045045 * (11 * value + 2000)) 
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    enabled = true,
    paths = {"Audio/Effects/Native/Analog Filter"},
    parameterNamePattern = "Cutoff",
    transpose = function (value, parameterName, semitones) 
      value = (math.exp(value / 0.217147) - 0.7795102) / 0.0055122507
      value = math.exp(semitones * math.log(2)/12) * value
      value = 0.217147 * math.log(0.0000556793 * (99 * value + 14000))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    enabled = true,
    paths = {"Audio/Effects/Native/Filter 3"},
    parameterNamePattern = {"Cutoff", "Freq."},
    transpose = function (value, parameterName, semitones) 
      value = (math.exp(value / 0.217147) - 0.99999935) / 0.004489793
      value = math.exp(semitones * math.log(2)/12) * value
      value = 0.217147 * math.log(0.000408163 * (11 * value + 2450))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- MDynamicEq
    enabled = true,
    paths = {"Audio/Effects/VST/MDynamicEq.bin","Audio/Effects/VST/MDynamicEq","Audio/Effects/VST3/4D656C646170726F4D6479514D647951"},
    parameterNamePattern = "Frequency ? (EQ ?)",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(20) + (math.log(20000) - math.log(20)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(20)) / (math.log(20000) - math.log(20))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- MAutoDynamicEq
    enabled = true,
    paths = {"Audio/Effects/VST/MAutoDynamicEq.bin","Audio/Effects/VST/MAutoDynamicEq","Audio/Effects/VST3/4D656C646170726F4D6479414D647941"},
    parameterNamePattern = "Frequency ? (EQ ?)",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(20) + (math.log(20000) - math.log(20)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(20)) / (math.log(20000) - math.log(20))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- MEq
    enabled = true,
    paths = {"Audio/Effects/VST/MEqualizer.bin","Audio/Effects/VST/MEqualizer","Audio/Effects/VST3/4D656C646170726F4D4165334D416533"},
    parameterNamePattern = "Frequency ? (EQ ?)",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(20) + (math.log(20000) - math.log(20)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(20)) / (math.log(20000) - math.log(20))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- MAutoEq
    enabled = true,
    paths = {"Audio/Effects/VST/MAutoEqualizer.bin","Audio/Effects/VST/MAutoEqualizer","Audio/Effects/VST3/4D656C646170726F4D41657E4D41657E"},
    parameterNamePattern = "Frequency ? (EQ ?)",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(20) + (math.log(20000) - math.log(20)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(20)) / (math.log(20000) - math.log(20))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- Pro Q 1/2/3
    enabled = true,
    paths = {"Audio/Effects/VST/FabFilter Pro-Q 3","Audio/Effects/VST3/72C4DB717A4D459AB97E51745D84B39D","Audio/Effects/VST/FabFilter Pro-Q 2","Audio/Effects/VST3/55FD08E6C00B44A697DA68F61C6FD576","Audio/Effects/VST/FabFilter Pro-Q"},
    parameterNamePattern = "Band ? Frequency",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(10) + (math.log(30000) - math.log(10)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(10)) / (math.log(30000) - math.log(10))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- apQualizr2
    enabled = true,
    paths = {"Audio/Effects/VST/apQualizr2","Audio/Effects/VST3/5653546170513261707175616C697A72"},
    parameterNamePattern = "F? Freq",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(10) + (math.log(30000) - math.log(10)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(10)) / (math.log(30000) - math.log(10))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- TDR Nova
    enabled = true,
    paths = {"Audio/Effects/VST/TDR Nova","Audio/Effects/VST/TDR Nova GE","Audio/Effects/VST3/56535454643561746472206E6F766100","Audio/Effects/VST3/56535454643531746472206E6F766120"},
    parameterNamePattern = {"Band ? Frequenc","Band ? Frequency"},
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(10) + (math.log(40000) - math.log(10)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(10)) / (math.log(40000) - math.log(10))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- TBProAudio DSEQ3
    enabled = true,
    paths = {"Audio/Effects/VST3/F2AEE70D00DE4F4E5442504154423637"},
    parameterNamePattern = {"Freq ?"},
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(50) + (math.log(20000) - math.log(50)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(50)) / (math.log(20000) - math.log(50))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- TB Eq4
    enabled = true,
    paths = {"Audio/Effects/VST3/5653545434455174625F657175616C69","Audio/Effects/VST/TB_Equalizer_v4"},
    parameterNamePattern = {"Freq?"},
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(23) + (math.log(17000) - math.log(23)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(23)) / (math.log(17000) - math.log(23))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- Ozone EQ
    enabled = true,
    paths = {"Audio/Effects/VST3/5653545A4F39554F7A6F6E6520392045","Audio/Effects/VST3/5653545A6E45384F7A6F6E6520382045","Audio/Effects/VST3/5653545A6E4537695A6F746F7065204F","Audio/Effects/VST3/5653545A6E4F51695A6F746F7065204F","Audio/Effects/VST3/5653545A6E4536695A6F746F7065204F","Audio/Effects/VST/Ozone 9 Equalizer","Audio/Effects/VST/Ozone 8 Equalizer","Audio/Effects/VST/iZotope Ozone 5 Equalizer","Audio/Effects/VST/iZotope Ozone 6 Equalizer","Audio/Effects/VST/iZotope Ozone 7 Equalizer","Audio/Effects/VST3/5653545A4F5A554F7A6F6E652050726F"},
    parameterNamePattern = {"EQ: St/M/L Frequency ?"},
    transpose = function (value, parameterName, semitones) 
      value = 20 + (20000 - 20) * value
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (value - 20) / (20000 - 20)
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- UVI Shade
    enabled = true,
    paths = {"Audio/Effects/VST3/5653544372466C736861646500000000","Audio/Effects/VST/Shade"},
    parameterNamePattern = {"Frequency"},
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(10) + (math.log(30000) - math.log(10)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(10)) / (math.log(30000) - math.log(10))
      return math.max(0, math.min(1, value))
    end      
  },
  { 
    -- SmartEQ3
    enabled = true,
    paths = {"Audio/Effects/VST3/565354736D4533736D61727465713300"},
    parameterNamePattern = "Band ? | Frequency",
    transpose = function (value, parameterName, semitones) 
      value = math.exp(math.log(20) + (math.log(20000) - math.log(20)) * value)
      value =  math.exp(semitones * math.log(2)/12) * value
      value = (math.log(value) - math.log(20)) / (math.log(20000) - math.log(20))
      return math.max(0, math.min(1, value))
    end      
  }
}


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function EQHelper:tableContains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function EQHelper:tableContainsRawEqual(table, element)
  for _, value in pairs(table) do
    if (rawequal(value, element)) then
      return true
    end
  end
  return false
end

function EQHelper:mergeTablesUnique(table1, table2)
  for _, value in pairs(table2) do 
    if (not EQHelper:tableContainsRawEqual(table1, value)) then
      table1[#table1 + 1] = value
    end
  end
  return table1
end

function EQHelper:getParentTracksRecursive(members, track, options)
  local tracks = {}
  if (options.context == "track") then
    if (track.type == renoise.Track.TRACK_TYPE_SEND) then
      tracks = EQHelper:getSendingTracks(track)
    elseif (options.includeInstruments and track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      local instrument = EQHelper:getInstrumentOfTrack(track)
      if (instrument) then
        local trackIndex = string.format("%02d", EQHelper:getTrackIndex(track))
        for chainIndex = 1, #instrument.sample_device_chains do
          local _chain = instrument:sample_device_chain(chainIndex)
          if (_chain.output_routing == "Current Track" or _chain.output_routing == trackIndex .. ": " .. track.name) then
            tracks[#tracks + 1] = _chain
            tracks = EQHelper:mergeTablesUnique(tracks, EQHelper:getSendingChains(_chain, instrument))
          end
        end
      end
    elseif (track.type == renoise.Track.TRACK_TYPE_GROUP) then
      tracks = track.members
    end
  elseif (options.context == "instrument") then
    tracks = EQHelper:getSendingChains(track, EQHelper:getInstrumentOfChain(track))
  end

  for index, memberTrack in pairs(tracks) do
    if (not EQHelper:tableContainsRawEqual(members, memberTrack)) then
      members[#members + 1] = memberTrack
      if (options.context == "instrument" or options.context == "track" and track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then
        members = EQHelper:getParentTracksRecursive(members, memberTrack, options)
      end
    end
  end

  return members
end

function EQHelper:getParentTracks(track, options)
  return EQHelper:getParentTracksRecursive({}, track, options)
end

function EQHelper:getSendingTracks(object)
  local returnedObjects = {}
  local objectIndex,  numObjects, _object
  
  objectIndex = EQHelper:getTrackIndex(object)
  numObjects = #sng.tracks
  
  for _objectIndex = 1, numObjects do
    _object = sng:track(_objectIndex)
    
    if (_objectIndex >= objectIndex) then
      break
    end

    local numDevices = #_object.devices
    for deviceIndex = 1, numDevices do
      local device = _object:device(deviceIndex)
      oprint(device)
      if (device.device_path == "Audio/Effects/Native/#Send") then
        if (device:parameter(3).value + sng.sequencer_track_count + 2 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        end
      elseif (device.device_path == "Audio/Effects/Native/#Multiband Send") then
        if (device:parameter(2).value + sng.sequencer_track_count + 2 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        elseif (device:parameter(4).value + sng.sequencer_track_count + 2 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        elseif (device:parameter(6).value + sng.sequencer_track_count + 2 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        end
      end
    end

  end
  return returnedObjects
end

function EQHelper:getSendingChains(object, instrument)
  local returnedObjects = {}
  local objectIndex,  numObjects, _object
  
  objectIndex = EQHelper:getChainIndex(object, instrument)
  numObjects = #instrument.sample_device_chains
  
  for _objectIndex = 1, numObjects do
    _object = instrument:sample_device_chain(_objectIndex)
    
    if (_objectIndex >= objectIndex) then
      break
    end

    local numDevices = #_object.devices
    for deviceIndex = 1, numDevices do
      local device = _object:device(deviceIndex)
      if (device.device_path == "Audio/Effects/Native/#Send") then
        if (device:parameter(3).value + 1 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        end
      elseif (device.device_path == "Audio/Effects/Native/#Multiband Send") then
        if (device:parameter(2).value + 1 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        elseif (device:parameter(4).value + 1 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        elseif (device:parameter(6).value + 1 == objectIndex) then
          returnedObjects[#returnedObjects + 1] = _object
          break
        end
      end
    end

  end
  return returnedObjects
end

function EQHelper:getTrackIndex(track)
  local numTracks = #sng.tracks
  for index = 1, numTracks do
    local _track = sng:track(index)  
    if (rawequal(_track, track)) then
      return index 
    end
  end

  return nil
end

function EQHelper:getChainIndex(chain, instrument)
  local numChains = #instrument.sample_device_chains
  for index = 1, numChains do
    local _chain = instrument:sample_device_chain(index)  
    if (rawequal(_chain, chain)) then
      return index 
    end
  end

  return nil
end

function EQHelper:getTrackOfDevice(device) 
  local numTracks = #sng.tracks
  for trackIndex = 1, numTracks do
    local track = sng:track(trackIndex)  
    for _, trackDevice in pairs(track.devices) do
      if (rawequal(device, trackDevice)) then
        return track
      end
    end
  end

  return nil
end

function EQHelper:getInstrumentOfChain(chain)
  local numInstrs = #sng.instruments
  for instrIndex = 1, numInstrs do
    local instrument = sng:instrument(instrIndex)  
    local numChains = #instrument.sample_device_chains
    for chainIndex = 1, numChains do
      local _chain = instrument:sample_device_chain(chainIndex)  
      if (rawequal(chain, _chain)) then
        return instrument
      end
    end
  end

  return nil
end

function EQHelper:getHighestPatternIndex()
  local maxIndex = 0;
  for pos = 1,#sng.sequencer.pattern_sequence do 
    maxIndex = math.max(maxIndex,  sng.sequencer:pattern(pos))
  end
  return maxIndex
end

function EQHelper:getInstrumentOfTrack(track)
  local trackIndex = EQHelper:getTrackIndex(track)
  local pattern, _track, patternLine, noteColumn
  for patternIndex = 1, EQHelper:getHighestPatternIndex() do
    pattern = sng:pattern(patternIndex)
    if (not pattern.is_empty) then
      _track = pattern:track(trackIndex)
      if (not _track.is_empty) then
        for lineIndex = 1, pattern.number_of_lines do
          patternLine = _track:line(lineIndex)
          if (not patternLine.is_empty) then
            for colIndex = 1, track.visible_note_columns do
              noteColumn = patternLine:note_column(colIndex)
              if (noteColumn.instrument_value ~= 255) then
               return sng:instrument(noteColumn.instrument_value + 1)
              end
            end
            
          end
        end
      end
    end
  end
  
  return nil
end

function EQHelper:getChainOfDevice(device) 
  local numInstrs = #sng.instruments
  for instrIndex = 1, numInstrs do
    local instrument = sng:instrument(instrIndex)  
    local numChains = #instrument.sample_device_chains
    for chainIndex = 1, numChains do
      local chain = instrument:sample_device_chain(chainIndex)  
      local numDevices = #chain.devices
      for deviceIndex = 1, numDevices do
        local chainDevice = chain:device(deviceIndex)  
        if (rawequal(device, chainDevice)) then
          return chain
        end
      end
    end
  end

  return nil
end

function EQHelper:getTrackOrChainOfDevice(device) 
  local returnedChain = EQHelper:getTrackOfDevice(device) 
  if (returnedChain == nil) then
    returnedChain = EQHelper:getChainOfDevice(device) 
  end
  return returnedChain
end

EQHelper.addedMenus = {}

function EQHelper:addContextMenuEntry(path, func, remember)
  local entry =  {
    name = path, 
    invoke = func
  }
  if (remember) then
    self.addedMenus[#self.addedMenus + 1] = path
  end
  tool:add_menu_entry(entry)
end

function EQHelper:removeContextMenu()
  for x = 1, #self.addedMenus do
    tool:remove_menu_entry(self.addedMenus[x])
  end
  self.addedMenus = {}
end


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function EQHelper:addDeviceContextMenu(selectedDevice, menuContext)
  self:addContextMenuEntry("DSP Device:Transpose...", function() self:openTransposeSliderDialogue(function(val) self:transpose(val, selectedDevice) end, {context = "device"}) end, true)
  self:addContextMenuEntry("DSP Device:Transpose +1", function() self:transpose(1, selectedDevice) end, true)
  self:addContextMenuEntry("DSP Device:Transpose -1", function() self:transpose(-1, selectedDevice) end, true)
  self:addContextMenuEntry("DSP Device:Transpose +12", function() self:transpose(12, selectedDevice) end, true)
  self:addContextMenuEntry("DSP Device:Transpose -12", function() self:transpose(-12, selectedDevice) end, true)
  if (menuContext == "track") then
    self:addContextMenuEntry("Mixer:Transpose...", function() self:openTransposeSliderDialogue(function(val) self:transpose(val, selectedDevice) end, {context = "device"}) end, true)
    self:addContextMenuEntry("Mixer:Transpose +1", function() self:transpose(1, selectedDevice) end, true)
    self:addContextMenuEntry("Mixer:Transpose -1", function() self:transpose(-1, selectedDevice) end, true)
    self:addContextMenuEntry("Mixer:Transpose +12", function() self:transpose(12, selectedDevice) end, true)
    self:addContextMenuEntry("Mixer:Transpose -12", function() self:transpose(-12, selectedDevice) end, true)
  else 
    self:addContextMenuEntry("Sample FX Mixer:Transpose...", function() self:openTransposeSliderDialogue(function(val) self:transpose(val, selectedDevice) end, {context = "device"}) end, true)
    self:addContextMenuEntry("Sample FX Mixer:Transpose +1", function() self:transpose(1, selectedDevice) end, true)
    self:addContextMenuEntry("Sample FX Mixer:Transpose -1", function() self:transpose(-1, selectedDevice) end, true)
    self:addContextMenuEntry("Sample FX Mixer:Transpose +12", function() self:transpose(12, selectedDevice) end, true)
    self:addContextMenuEntry("Sample FX Mixer:Transpose -12", function() self:transpose(-12, selectedDevice) end, true)
  end
end

function EQHelper:findPluginConfig(path)
  for _, pluginConfig in pairs(EQHelper.pluginRegistry) do
    if ( pluginConfig.enabled == true and EQHelper:tableContains(pluginConfig.paths, path)) then
      return pluginConfig
    end
  end
  return nil
end

function EQHelper:transposeAllAndReport(semitones) 
  local affectedDevices = self:transposeAll(semitones, { includeGroups = true, includeTracks = true, includeInstruments = false })
  if (self.config.showReport == true) then
    local output = ""
    for _, affectedDevice in pairs(affectedDevices) do
      local chain = EQHelper:getTrackOrChainOfDevice(affectedDevice)
      output = output .. chain.name .. " / "
      output = output .. affectedDevice.display_name .. "\n"
    end
    renoise.app():show_prompt("EQHelper Global Transpose", "The following devices were transposed by " .. semitones .. ":\n\n" .. output, {"Ok"})
  end

end

function EQHelper:transposeAllInSignalFlow(semitones, options) 
  local tracks
  if (options.context == "track") then 
    tracks = EQHelper:getParentTracks(sng.selected_track, options)
    table.insert(tracks, sng.selected_track)
  elseif (options.context == "instrument") then 
    tracks = EQHelper:getParentTracks(sng.selected_sample_device_chain, options)
    table.insert(tracks, sng.selected_sample_device_chain)
  end
  
  local affectedDevices = {}
  
  for _, track in pairs(tracks) do
    if (
    options.context == "instrument"
    or type(track) == "SampleDeviceChain"
    or track.type ~= nil
    ) then
      local numDevices = #track.devices
      for deviceIndex = 1, numDevices do
        local device = track:device(deviceIndex)
        local returnedDevice = self:transpose(semitones, device)
        if (returnedDevice ~= nil) then
          table.insert(affectedDevices, returnedDevice)
        end
      end
    end
  end

  return affectedDevices
end

function EQHelper:transposeAll(semitones, options) 
  local returnedDevice
  local affectedDevices = {}

  local numTracks = #sng.tracks
  for trackIndex = 1, numTracks do
    local track = sng:track(trackIndex)  
    if (
      track.type == renoise.Track.TRACK_TYPE_GROUP and options.includeGroups or
      track.type == renoise.Track.TRACK_TYPE_SEQUENCER and options.includeTracks or 
      track.type == renoise.Track.TRACK_TYPE_MASTER or
      track.type == renoise.Track.TRACK_TYPE_SEND
    ) then
      local numDevices = #track.devices
      for deviceIndex = 1, numDevices do
        local device = track:device(deviceIndex)
        returnedDevice = self:transpose(semitones, device)
        if (returnedDevice ~= nil) then
          table.insert(affectedDevices, returnedDevice)
        end
      end
    end
  end

  if (options.includeInstruments) then
    local numInstrs = #sng.instruments
    for instrIndex = 1, numInstrs do
      local instrument = sng:instrument(instrIndex)  
      local numChains = #instrument.sample_device_chains
      for chainIndex = 1, numChains do
        local chain = instrument:sample_device_chain(chainIndex)  
        local numDevices = #chain.devices
        for deviceIndex = 1, numDevices do
          local device = chain:device(deviceIndex)  
          returnedDevice = self:transpose(semitones, device)
          if (returnedDevice ~= nil) then
            table.insert(affectedDevices, returnedDevice)
          end
        end
      end
    end
  end

  return affectedDevices
end

function EQHelper:transposeAllInCurrentTrack(semitones) 
  local returnedDevice
  local affectedDevices = {}

  local track = sng.selected_track
  local numDevices = #track.devices
  for deviceIndex = 1, numDevices do
    local device = track:device(deviceIndex)
    returnedDevice = self:transpose(semitones, device)
    if (returnedDevice ~= nil) then
      table.insert(affectedDevices, returnedDevice)
    end
  end

  return affectedDevices
end

function EQHelper:transpose(semitones, devicePointer)
  local pluginConfig = self:findPluginConfig(devicePointer.device_path)
  if (pluginConfig == nil or string.match(devicePointer.display_name, "^" .. self.config.excludedDevicesNameStart .. ".*")) then
    return nil
  end

  local parameterNamePatterns = {}
  local lastIndex = 1

  if (type(pluginConfig.parameterNamePattern) == 'string') then
    parameterNamePatterns[1] = pluginConfig.parameterNamePattern
  else
    parameterNamePatterns = pluginConfig.parameterNamePattern
  end

  for _, parameterNamePattern in pairs(parameterNamePatterns) do

    local searchPattern = parameterNamePattern
    searchPattern = string.gsub(searchPattern, "%(", "%%(")
    searchPattern = string.gsub(searchPattern, "%)", "%%)")
    searchPattern = string.gsub(searchPattern, "%[", "%%[")
    searchPattern = string.gsub(searchPattern, "%]", "%%]")
    searchPattern = string.gsub(searchPattern, "?", "[%%d]+")

    local numParameters = #devicePointer.parameters
    for x = lastIndex, numParameters do
      local parameter = devicePointer:parameter(x)
      if (parameter.value ~= nil) then
        if (string.match(parameter.name, searchPattern) and parameter.is_automated == false) then
          parameter.value = pluginConfig.transpose(parameter.value, parameter.name, semitones)
          lastIndex = x + 1
        end
      end
    end

  end

  return devicePointer
end

function EQHelper:openTransposeSliderDialogue(callbackFunction, options)
  local vb = renoise.ViewBuilder()
  local dialogPtr
  local lastSemitonesValue = 0
  local semitones = renoise.Document.ObservableNumber()
  semitones.value = 0
  local sliderRange = 24
  
  local dialogKeyHander = function(dialog, key)
    if key.name == "esc" then
      dialogPtr:close()
    else
      return key
    end
  end
  
  options.includeInstruments = false
  options.includeTracks = true
  options.includeGroups = true
  
  local lines = vb:vertical_aligner({})
  
  lines:add_child(vb:horizontal_aligner {
      mode = "justify", 
      vb:slider {
        id = "slider",
        width = 400,
        steps = {1/(sliderRange * 10), 1/sliderRange},
        value = 0.5,
        default = 0.5,
        min = 0,
        max = 1,
        tooltip = "Transpose",
        notifier = function(newValue)
          local mySemitones = math.floor((newValue - 0.5) * sliderRange * 10 ) / 10
          local relativeSemitones = mySemitones - lastSemitonesValue
          sng:describe_undo("Transpose EQs/filters with slider")
          callbackFunction(relativeSemitones, options)
          lastSemitonesValue = mySemitones
          semitones.value = mySemitones
        end,
      },
      vb:value {
        width = 30, 
        tooltip = 'Current transpose value', 
        bind = semitones,
        tostring = function(value)
          return string.format("%.1f", value)
        end
      }
    })
  
  if (options.context == "track" or options.context == "song") then
    lines:add_child(vb:horizontal_aligner {
        mode = "justify", 
        vb:text {
          width = 160, 
          text = "Include sending instrument chains"
        }, 
        vb:checkbox {
          width = 80, 
          value = options.includeInstruments, 
          tooltip = "Sending instrument dsp chains are affected or not", 
          notifier = function(newValue)
            options.includeInstruments = newValue
          end, 
        }, 
      })
    lines:add_child(vb:horizontal_aligner {
        mode = "justify", 
        vb:text {
          width = 160, 
          text = "Include groups"
        }, 
        vb:checkbox {
          width = 80, 
          value = options.includeGroups, 
          tooltip = "Devices on groups are affected or not", 
          notifier = function(newValue)
            options.includeGroups = newValue
          end, 
        }, 
      })
    lines:add_child(vb:horizontal_aligner {
        mode = "justify", 
        vb:text {
          width = 160, 
          text = "Include tracks"
        }, 
        vb:checkbox {
          width = 80, 
          value = options.includeTracks, 
          tooltip = "Devices on tracks are affected or not", 
          notifier = function(newValue)
            options.includeTracks = newValue
          end, 
        }, 
      })
  end
  
  local dialogView = vb:column {
    id = "container",
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    lines 
  }

  dialogPtr = renoise.app():show_custom_dialog("Transpose EQs/filters in semitones", dialogView, dialogKeyHander)    
end

EQHelper.activateMiddleFrameListener = nil

function EQHelper:setupMenuListeners()
  -- add dsp device context menu entry dependent on device type
  local dspDeviceSelect = function(selectedDevice, menuContext)
    if(type(selectedDevice) ~= "AudioDevice") then
      return
    end

    rprint(selectedDevice.device_path)
    self:removeContextMenu()
    
    for _, pluginConfig in pairs(EQHelper.pluginRegistry) do
      if (EQHelper:tableContains(pluginConfig.paths, selectedDevice.device_path)) then
        self:addDeviceContextMenu(selectedDevice, menuContext)
        return
      end
    end

  end

  local selectedTrackDeviceListener = function()
    return dspDeviceSelect(sng.selected_track_device, "track")
  end

  local selectedSampleDeviceListener = function()
    return dspDeviceSelect(sng.selected_sample_device, "sampler")
  end

  -- fix missing re-bang of selected_track_device_observable on context change
  self.activateMiddleFrameListener = function()
    if (type(renoise.song) ~= "function" or type(renoise.app) ~= "function" ) then
      return
    end
    if (renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS) then
      selectedSampleDeviceListener()
    elseif (renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR or 
            renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_MIXER) then
      selectedTrackDeviceListener()
    end
    
  end

  if (not sng.selected_track_device_observable:has_notifier(selectedTrackDeviceListener)) then
    sng.selected_track_device_observable:add_notifier(selectedTrackDeviceListener)
  end

  if (not sng.selected_sample_device_observable:has_notifier(selectedSampleDeviceListener)) then
    sng.selected_sample_device_observable:add_notifier(selectedSampleDeviceListener) 
  end

  if (not renoise.app().window.active_middle_frame_observable:has_notifier(self.activateMiddleFrameListener)) then
    renoise.app().window.active_middle_frame_observable:add_notifier(self.activateMiddleFrameListener)
  end

end

function EQHelper:setupGlobalListeners()
  self:addContextMenuEntry("Main Menu:Tools:ffx.tools.EQHelper:Transpose song EQs/filters...", function() self:openTransposeSliderDialogue(function(val, options) self:transposeAll(val, options) end, {context = "song"}) end, false)
  self:addContextMenuEntry("Main Menu:Tools:ffx.tools.EQHelper:Transpose song EQs/filters +1", function() self:transposeAllAndReport(1) end, false)
  self:addContextMenuEntry("Main Menu:Tools:ffx.tools.EQHelper:Transpose song EQs/filters -1", function() self:transposeAllAndReport(-1) end, false)
  self:addContextMenuEntry("Main Menu:Tools:ffx.tools.EQHelper:Transpose song EQs/filters +12", function() self:transposeAllAndReport(12) end, false)
  self:addContextMenuEntry("Main Menu:Tools:ffx.tools.EQHelper:Transpose song EQs/filters -12", function() self:transposeAllAndReport(-12) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters in signal flow...", function()  self:openTransposeSliderDialogue(function(val, options) self:transposeAllInSignalFlow(val, options) end, {context = "track"}) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters...", function()  self:openTransposeSliderDialogue(function(val) self:transposeAllInCurrentTrack(val) end, {context = "single_track"}) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters +1", function() self:transposeAllInCurrentTrack(1) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters -1", function() self:transposeAllInCurrentTrack(-1) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters +12", function() self:transposeAllInCurrentTrack(12) end, false)
  self:addContextMenuEntry("Mixer:Track:Transpose EQs/filters -12", function() self:transposeAllInCurrentTrack(-12) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters in signal flow...", function()  self:openTransposeSliderDialogue(function(val, options) self:transposeAllInSignalFlow(val, options) end, {context = "track"}) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters...", function() self:openTransposeSliderDialogue(function(val) self:transposeAllInCurrentTrack(val) end, {context = "single_track"}) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters +1", function() self:transposeAllInCurrentTrack(1) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters -1", function() self:transposeAllInCurrentTrack(-1) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters +12", function() self:transposeAllInCurrentTrack(12) end, false)
  self:addContextMenuEntry("Pattern Editor:Track:Transpose EQs/filters -12", function() self:transposeAllInCurrentTrack(-12) end, false)
  self:addContextMenuEntry("Sample FX Mixer:Transpose EQs/filters in signal flow...", function()  self:openTransposeSliderDialogue(function(val, options) self:transposeAllInSignalFlow(val, options) end, {context = "instrument"}) end, false)

  local newDocumentListener = function()
    sng = renoise.song()
    self:setupMenuListeners()
  end

  local releaseDocumentListener = function()
    if (renoise.app().window.active_middle_frame_observable:has_notifier(self.activateMiddleFrameListener)) then
      renoise.app().window.active_middle_frame_observable:remove_notifier(self.activateMiddleFrameListener)
    end
  end

  if (not tool.app_new_document_observable:has_notifier(newDocumentListener)) then
    tool.app_new_document_observable:add_notifier(newDocumentListener)
  end

  if (not tool.app_release_document_observable:has_notifier(releaseDocumentListener)) then
    tool.app_release_document_observable:add_notifier(releaseDocumentListener)
  end
  
  if (type(renoise.song) == "function") then
    newDocumentListener()
  end

end


function EQHelper:__init()
  self.configurator = LibConfigurator(LibConfigurator.SAVE_MODE.FILE, self.defaultConfig, "config.json")
  self.config = self.configurator:getConfig()
  self.configurator:addMenu("ffx.tools.EQHelper", self.configDescription, 
    function (newConfig)
      self.config = newConfig
    end
  )

  tool:add_keybinding {
    name = "Global:Tools:Transpose song EQs/filters...", 
    invoke =  function() self:openTransposeSliderDialogue(function(val, options) self:transposeAll(val, options) end, {context = "song"}) end
  }
  tool:add_keybinding {
    name = "Global:Tools:Transpose song EQs/filters +1", 
    invoke = function() self:transposeAllAndReport(1) end
  }
  tool:add_keybinding {
    name = "Global:Tools:Transpose song EQs/filters -1", 
    invoke = function() self:transposeAllAndReport(-1) end
  }
  tool:add_keybinding {
    name = "Global:Tools:Transpose EQs/filters in song signal flow...", 
    invoke = function()  self:openTransposeSliderDialogue(function(val, options) self:transposeAllInSignalFlow(val, options) end, {context = "track"}) end
  }
  tool:add_keybinding {
    name = "Global:Tools:Transpose track EQs/filters +1", 
    invoke = function() self:transposeAllInCurrentTrack(1) end
  }
  tool:add_keybinding {
    name = "Global:Tools:Transpose track EQs/filters -1", 
    invoke = function() self:transposeAllInCurrentTrack(-1) end
  }

end


--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

eqHelperInst = EQHelper()


idleListener = function ()
  tool.app_idle_observable:remove_notifier(idleListener)
  eqHelperInst:setupGlobalListeners()
end
tool.app_idle_observable:add_notifier(idleListener)













