  local DEBUG = false
  local Song = nil
  local Tool = nil
  local Vb = nil
  local App = nil

  -- some less but still very important and useful global variables
  local version = "v1"
  local playbackPos = nil
  local currentPattern = nil
  local currentTrack = nil
  local selectedTrack = true
  local deviceList_t = {}
  local isRunning = false
  local timerValue = 4
  local timerModifier = 0
  local selectedDevice = 1
  local lastSelectedDevice = nil
  local thesez = nil
  local currentDialog = nil
  local dialogContent = nil
  local buttonStatus = false
  local tracksTable = nil
  local randomMode = false
  local randomDevice = 1
  local dialogHelpContent = nil
  local dialogHelp = nil
  local buttonReleased = {0x55,0x55,0x55}
  local buttonPressed = {0xFF,0x00,0xFF}
  local buttonOFF = {0x33,0x30,0x33}
  local checkPatternSelection = false
  local mrbaguettesez = {
    "A baguette a day keeps the doctor away",
    "I heard you like my baguette",
    "Are you ready to fünky blëëpblôôp?",
    "Venerian Snails?",
    "Meat is... quite good murder on a bbq grill",
    "Coucou, tu veux voir ma baguette ?",
    "It's baguette jambon beurre time!",
    "Error: baguette overflow",
    "Ranose: only for kore people",
    "Works better around bpm 2000",
    "Use with caution when hammond breaks are involved"
  }

function simpleTOHEX(num)
  local hex
  if num==10 then
    hex = "A"
  elseif num==11 then
    hex = "B"
  elseif num==12 then
    hex = "C"
  elseif num==13 then
    hex = "D"
  elseif num==14 then
    hex = "E"
  elseif num==15 then
    hex = "F"
  else hex = tostring(num)
  end
  
  return hex
end

function safeDeviceSwap(device,state)
  if deviceList_t[device] ~= nil then  
    deviceList_t[device].devices.is_active = state
  end
end

--[[
    Major love to conner and danoise for telling me about app_idle:
    
    It actually makes you able to have it working live for "testing" before writing
    values on the columns.
--]]
function updatePlaybackPos()
  local timerModifierValue = 0
  
  if (not currentDialog or not currentDialog.visible) then
    stopUpdating()
  end
  
  --[[
     this is a bit lame.
     We have to make sure the value stored in playbackPos is not the same as the line still "being played"
     as app_idle refresh approx. 10 times a second. 
     Also, we make sure there's more than two device as track/vol/pan is a device and counts as one. 
  --]]
  if playbackPos ~= (Song.transport.playback_pos.line - 1) and table.count(deviceList_t) > 1 then
    playbackPos = Song.transport.playback_pos.line - 1
    
    if timerModifier>0 then
      timerModifierValue = math.random(0,timerModifier)
    end
    
    if DEBUG then print("seed :"..timerModifierValue) end
    
    -- your favourite modulo trick
    if playbackPos % (timerValue+timerModifierValue) == 0 then
      
      if (selectedDevice>0) then
        safeDeviceSwap(selectedDevice,false)
      else
        -- bypass last device in the list (in case we have to enable the "first" one
        safeDeviceSwap(table.count(deviceList_t),false)
      end
      
      if randomMode then
        randomDevice = math.random(table.count(deviceList_t))
        selectedDevice = (selectedDevice + randomDevice) % (table.count(deviceList_t))
      else
         selectedDevice = selectedDevice % (table.count(deviceList_t))
      end
      
      selectedDevice = selectedDevice + 1
      
      if DEBUG then print(selectedDevice) end
      safeDeviceSwap(selectedDevice,true)
    end
  end
end 


function stopUpdating()
  isRunning = false
  local selectedDevice = 1
  -- we unbind the function so it stops doing nasty things to your devices
  if (Tool.app_idle_observable:has_notifier(updatePlaybackPos)) then
    Tool.app_idle_observable:remove_notifier(updatePlaybackPos)
  end
  if DEBUG then print("stop updating playback position") end
end

function startUpdating()
  -- we disabled all devices on the current track
  for i=2,(table.count(deviceList_t)) do
    if DEBUG then rprint(deviceList_t[i]) end
    deviceList_t[i].devices.is_active = false
  end
  isRunning = true
  -- then we bind our update playbackPOS function on... app idle (yes :D)
  if not (Tool.app_idle_observable:has_notifier(updatePlaybackPos)) then
    Tool.app_idle_observable:add_notifier(updatePlaybackPos)
  end
  if DEBUG then print("start updating playback position") end
end


--[[
  writeCommand: well, it writes on the pattern?.
]]--
function writeCommand()
  local selectedDevice = 0
  local timerModifierValue = 0
  local moduloMax = 0
  local canWrite = false
  local firstSelected = false
  local selectedLines = {}
  local lineStart = nil
  local lineEnd = Song.patterns[currentPattern].number_of_lines-1
  
  -- if the option isnt checked, then CAN HAZ SUM WRITING :)
  if checkPatternSelection == false then
    canWrite = true
  end
  
  -- for effect column 2 visibility
  Song.tracks[currentTrack].visible_effect_columns = 2
  
  -- if pattern selection is enabled, will get the first and last line 
  -- and update lineStart and lineEnd
  if checkPatternSelection then
    if DEBUG then print("check pattern selection") end
    for j=0,Song.patterns[currentPattern].number_of_lines-1 do
      if (Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[1].is_selected or
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].is_selected) then
        if lineStart == nil then 
          lineStart = j
          firstSelected = true
        end
      else
        if firstSelected then
          lineEnd = j - 1
          firstSelected = false
        end
      end
    end
  end
  
  if DEBUG then print("start: "..(lineStart or 0).." and end: "..lineEnd) end
  
  -- if lineStart has not been set, set it to 0
  if lineStart == nil then lineStart = 0 end
  
  if table.count(deviceList_t) > 15 then
    moduloMax = 15
  else
    moduloMax = table.count(deviceList_t)
  end
  
  -- if lastSelectedDevice has been set and checkPatternSelection is enabled, 
  -- then this is the first device to bypass.
  if (lastSelectedDevice ~= nil and checkPatternSelection) then selectedDevice = lastSelectedDevice end
  
  for j=lineStart,lineEnd do
      -- clear    
      Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[1]:clear()
      Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2]:clear()
      
      if timerModifier>0 then
        timerModifierValue = math.random(0,timerModifier)
      end
      
      if DEBUG then print(timerModifierValue) end
      
      if ((j - lineStart)%(timerValue+timerModifierValue))==0 and 
         (j+1) < Song.patterns[currentPattern].number_of_lines+1 then
        -- disable first ($ling yodawg)
        if (selectedDevice == 0 and deviceList_t[table.count(deviceList_t)].n - 1 < 16) then
          -- bypass last device in the list
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].number_string = (simpleTOHEX(deviceList_t[table.count(deviceList_t)].n - 1)).."0"
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].amount_string = "00"
        elseif(selectedDevice ~= 0 and deviceList_t[selectedDevice].n - 1 < 16) then
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].number_string = (simpleTOHEX(deviceList_t[selectedDevice].n - 1)).."0"
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].amount_string = "00"
        else
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].number_string = "F0"
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[2].amount_string = "00"
        end
      
        if DEBUG then 
          print("DISBAAAAABLING// device n "..selectedDevice.." on pattern "..currentPattern.." and track "..currentTrack.." and line "..(j+1))
        end
        
         if randomMode then
          randomDevice = math.random(moduloMax)
          selectedDevice = (selectedDevice + randomDevice) % moduloMax
        else
          selectedDevice = selectedDevice % moduloMax
        end
        
        selectedDevice = selectedDevice + 1
        print(selectedDevice)
        -- safe dump... no more than 15 devices
        -- 1 -> F == 15.
        if (deviceList_t[selectedDevice].n - 1 < 16) then
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[1].number_string = simpleTOHEX(deviceList_t[selectedDevice].n - 1).."0"
          Song.patterns[currentPattern].tracks[currentTrack].lines[j+1].effect_columns[1].amount_string = "01"
        end
        
        if DEBUG then 
          print("ENABLE// device n "..selectedDevice.." on pattern "..currentPattern.." and track "..currentTrack.." and line "..(j+1))
        end
    end
    
    -- the last selectedDevice is lastSelectedDevice (SHERLOCK)
    lastSelectedDevice = selectedDevice
  end
  
end

--[[
  getDevices: will get devices from the selected track, exclude track/vol/pan and safe/mchammer 
]]--
function getDevices()
  local device
  local count = 1
  deviceList_t = {}
  
  -- will check all devices
  for i=2, table.count(Song.tracks[currentTrack].devices) do
    device = Song.tracks[currentTrack].devices[i]
    if (string.find(string.upper(device.display_name),"MCHAMMER") == nil and
      string.find(string.upper(device.display_name),"SAFE")) == nil  then
      deviceList_t[count] = {
        n=i,
        name = device.display_name,
        devices=device
      }
      count = count + 1
    end
    
    if lastSelectedDevice ~=nil and table.count(deviceList_t) < lastSelectedDevice then
      lastSelectedDevice = nil
    end 
    
    if not Song.tracks[currentTrack].devices[i].display_name_observable:has_notifier(getDevices) then
      Song.tracks[currentTrack].devices[i].display_name_observable:add_notifier(getDevices)
    end
  end

  if (Vb.views.currentDevices ~=nil) then
    Vb.views.currentDevices.text = "It contains "..(table.count(deviceList_t) or "no").." device(s)"
  end
  
  if Vb.views.liveButton ~= nil then
    if table.count(deviceList_t) > 1 then
      Vb.views.liveButton.active = true
      if (buttonStatus == false) then
        Vb.views.liveButton.color = buttonReleased
        Vb.views.liveButton.text = "Enable live mode!"
      end
      Vb.views.writeButton.active = true
      Vb.views.writeButton.color = buttonReleased
      
    else
      Vb.views.liveButton.active = false
      Vb.views.liveButton.color = buttonOFF
      Vb.views.liveButton.text = "HOFF"
      Vb.views.writeButton.active = false
      Vb.views.writeButton.color = buttonOFF
      buttonStatus = false
    end
  end
  
  if DEBUG then
    print("devices ")
    rprint(deviceList_t)
  end
end

--[[
  getTrackInfos: will get track index + devices from the selected track
]]--
function getTrackInfos()
  -- we change currentTrack value
  currentPattern = Song.selected_pattern_index
  
  if (selectedTrack == true) then
    currentTrack =  Song.selected_track_index
  end
  
  if not Song.tracks[currentTrack].devices_observable:has_notifier(getDevices) then
   Song.tracks[currentTrack].devices_observable:add_notifier(getDevices)
  end
  
  if Vb.views.currentTrack ~= nil then
    Vb.views.currentTrack.text = "Apparently, you're on track "..currentTrack
    Vb.views.currentTrack.tooltip = "and its name is \""..Song.tracks[currentTrack].name.."\""
  end
  -- we get all devices bound to one track
  getDevices()

  -- and we print infos (debug mode)
  if DEBUG then 
    print("current track "..currentTrack) 
  end
end

--[[
  getTracks: get tracks info if any is added during the process.
]]--
function getTracks()
  tracksTable = {"Selected track"}
  
  -- track selector loop
  for i=1,table.count(Song.tracks) do
    table.insert(tracksTable,Song.tracks[i].name)
  end
  
  if Vb.views.trackSelecter then
    Vb.views.trackSelecter.items = tracksTable
  end
end

--[[
  gui: do everything related to the gui
]]--
function openGui()
  if (not currentDialog or not currentDialog.visible) then
    -- fun
    thesez = mrbaguettesez[math.random(table.count(mrbaguettesez))]
    currentDialog = App:show_custom_dialog("BAGUETT'R US "..version.."!", dialogContent)
    Vb.views.thesez.text = "\""..thesez.."\""
  end
end

function gui()

  -- main box is 300
  local boxWidth = 300
  local margin = 10
  local spacing = 10
  -- main panels is 280 
  local mainPanel = 280
  local buttonsWidth = 260
  
  -- text stuff
  local selectedTrackValue = Vb:text {
    align = "center",
    font = "bold",
    text = "Apparently, you're on track "..currentTrack,
    tooltip = "and its name is \""..Song.tracks[currentTrack].name.."\"",
    id = "currentTrack"
  }
  
  local selectedDevicesNumber = Vb:text {
    align = "center",
    font = "bold",
    text = "It contains "..(table.count(deviceList_t) or "no").." device(s)",
    id = "currentDevices"
  }
  
  -- valuebox
  local timerValueBox = Vb:valuebox {
    id = "timerValue",
    width = 115,
    value = timerValue,
    min = 1,
    max = 128,
    notifier = function(value)
      timerValue = value
      if DEBUG then print("timer value :"..timerValue) end
    end
  }
  
  local randomTimerModifierBox = Vb:valuebox {
    id = "randomTimerModifier",
    width = 115,
    value = timerModifier,
    min = 0,
    max = 128,
    notifier = function(value)
      timerModifier = value
      if DEBUG then print("random timer modifier :"..timerModifier) end
    end
  }
  
  -- checkboxes
  local patternSelectionCheckbox = Vb:checkbox {
    id = "patternSelectionCheckbox",
    width = 20,
    height = 20,
    value = checkPatternSelection,
    notifier = function(value)
      checkPatternSelection = value
    end
  }
  
  local randomCheckbox = Vb:checkbox {
    id = "randomCheckbox",
    width = 115,
    height = 20,
    value = randomMode,
    notifier = function(value)
      randomMode = value
    end
  }
  
  -- calling the function that retrieve tracks
  getTracks()
  
  -- popup
  local currentTrackSelecter = Vb:popup {
    id = "trackSelecter",
    width = 115,
    value = 1,
    items = tracksTable,
    notifier = function(new_index)
      Vb.views.trackSelecter.value = new_index
      if (new_index == 1) then
        
        if DEBUG then print("removing notifier on track "..currentTrack) end
        
        if (Song.tracks[currentTrack].devices_observable:has_notifier(getDevices)) then
          Song.tracks[currentTrack].devices_observable:remove_notifier(getDevices)
        end
        
        selectedTrack = true
        
        getTrackInfos()
      else
        if (Song.tracks[currentTrack].devices_observable:has_notifier(getDevices)) then
          Song.tracks[currentTrack].devices_observable:remove_notifier(getDevices)
        end
    
        currentTrack = new_index - 1
        selectedTrack = false
        stopUpdating()
        getTrackInfos()
      end
    end
  }
  
  -- buttons
  local liveModeButton = Vb:button {
    width = buttonsWidth,
    height = 40,
    text = "Enable live mode!",
    color = buttonOFF,
    id = "liveButton",
    tooltip ="Activate teh mayhem hem hem",
    active = false,
    released = function() 
      if (not buttonStatus) then
        selectedDevice = 1
        Vb.views.liveButton.color = buttonPressed
        Vb.views.liveButton.text = "HON"
        startUpdating()
        buttonStatus = true
      else
        Vb.views.liveButton.color = buttonReleased
        Vb.views.liveButton.text = "H0FF"
        stopUpdating()
        buttonStatus = false
      end
    end 
  }
  
  local helpButton = Vb:button {
    width = 20,
    text = "?",
    id = "helpButton",
    tooltip ="If you need a fix",
    active = true,
    released = function() 
      --open a help dialog
      if (dialogHelp == nil or not dialogHelp.visible) then
        dialogHelp = App:show_custom_dialog("Help!",dialogHelpContent)
      end
    end 
  }
  
  local writeButton = Vb:button{
    width = buttonsWidth,
    height = 40,
    text = "PATTERN\nDUMP",
    tooltip = "will write commands on the pattern",
    id = "writeButton",
    notifier = writeCommand,
    active = false,
    color = buttonOFF
  }
  
  -- blocks/aligners/rows/columns
  local guiHeader = Vb:column {
    margin = 10,
    spacing = 10, 
    style = "border",
    Vb:horizontal_aligner {
      mode = "center",
      selectedTrackValue
    },
    Vb:horizontal_aligner {
      mode = "center",
      selectedDevicesNumber
    }
  }
  
  local guiMainPanel = Vb:column {
    style = "group",
    margin = 10,
    spacing = 10,   
    Vb:horizontal_aligner {
      mode = "center",
      Vb:vertical_aligner {      
        Vb:text {
          width = 115,
          align = "center",
          font = "bold",
          text = "Track selector",
          tooltip = "(The track to tickle tickle tickle)"
        },
        currentTrackSelecter
      }
    },
    Vb:horizontal_aligner { 
      mode = "center",
      Vb:vertical_aligner {      
        Vb:text {
          width = 115,
          align = "center",
          text = "Row count",
          font = "bold",
          tooltip = "(A count before instrument swap)"
        },    
        timerValueBox     
      }
    },
  }
  
  local guiRandomPanel = Vb:column {
    style = "group",
    margin = 10,
    spacing = 10,
    width = 135,
    Vb:horizontal_aligner { 
      mode = "center",
      Vb:vertical_aligner {      
        Vb:text {
          width = 115,
          align = "center",
          text = "Row modifier",
          font = "bold",
          tooltip = "(Add some random)"
        },     
        randomTimerModifierBox     
      }
    },
    Vb:horizontal_aligner { 
      mode = "center",
      Vb:vertical_aligner { 
        mode = "center",     
        Vb:text {
          align = "center",
          font = "bold",
          text = "Random sequence"
        },
        randomCheckbox
      }
    }
  }
  
  local guiLivePanel = Vb:column {
    style = "group",
    margin = 10,
    spacing = 10,
    Vb:horizontal_aligner { 
      mode = "center",
      liveModeButton,
    }
  }
  
  local guiWritePanel = Vb:column {
    style = "group",
    margin = 10,
    spacing = 10,
    Vb:horizontal_aligner {
      mode = "center",
      writeButton
    },
    Vb:horizontal_aligner { 
      mode = "right",
      spacing = 10,
      Vb:text {
        align = "center",
        font = "bold",
        text = "Dump on selection"
      },
      patternSelectionCheckbox
  
    }
  }
  
  local guiFooter = Vb:horizontal_aligner {
    mode = "justify",
    helpButton,
    Vb:text{
      width = 250,
      align = "right",
      font = "italic",
      id = "thesez"
    }
  }
  
  -- dialogs
  dialogHelpContent = Vb:column {
    uniform = true,
    margin = 10,
    spacing = 10,
    Vb:text {
      align = "left",
      text = [[
      Device "step by step (oh baby) simple sequencer" (or swapper...) 
      With both a live and a write mode.
      
      HOWTO:
      - select a track or the "selected tracks" option, insert devices.
      
      - set a timer, the tool is actually counting till "timer value" and then
        it enables the next device, disa[b]$[/b]ling the previous one.
        
      - Live button: This is for swapping on playback..
      
      - The write button: This is for writing the commands on the pattern
        Enabling "Pattern selection" will constrain the dump to a selection.
        
      - if you want the script to avoid "touching" some plugs, add "MCHAMMER", 
        "mchammer", "SAFE" or "safe" to the name of the plug (yes, just rename 
        to MCHAMMER, because he can't touch this... device).
      
      - Random options do what random options do what raopdomwhatranoptdo.
      
      Scripted by kaneel of TPOLM.
      With love, and bread.
      
      http://mynameiskaneel.com
      http://tpolm.com
      ]]
    }
  }
  
  dialogContent = Vb:column {
    uniform = true, 
    margin = 10,
    spacing = 10,
    guiHeader,
    Vb:horizontal_aligner {
      mode = "justify",
      spacing = 10,
      guiMainPanel,
      guiRandomPanel
    },
    guiLivePanel,
    guiWritePanel,
    guiFooter
  }
  
  openGui()
  
  if DEBUG then print("gui's been opened proudly") end
   
  -- check if buttons can be enabled.
  if table.count(deviceList_t) > 1 then
    Vb.views.liveButton.active = true
    Vb.views.liveButton.color = buttonReleased
    Vb.views.writeButton.active = true
    Vb.views.writeButton.color = buttonReleased
  else
    Vb.views.liveButton.active = false
    Vb.views.liveButton.color = buttonOFF
    Vb.views.writeButton.active = false
    Vb.views.writeButton.color = buttonOFF
  end

end

function newDoc()
  if (currentDialog and currentDialog.visible) then
    currentDialog:close() 
    currentDialog = nil
    Song = nil
    Tool = nil
    Vb = nil
    App = nil
  end
end

--[[
  init: ahem, come on...
]]--
function init()
  -- some important global business
  Song = renoise.song()
  Tool = renoise.tool()
  Vb = renoise.ViewBuilder()
  App = renoise.app()
  
  playbackPos = nil
  currentPattern = nil
  currentTrack = nil
  deviceList_t = {}
  isRunning = false
  timerValue = 4
  timerModifier = 0
  randomMode = false
  selectedDevice = 1
  thesez = nil
  
  -- Initialize the pseudo random number generator
  math.randomseed( os.time() )
  math.random(); math.random(); math.random()
  -- done. EEEEWWWWWW ITS DIRTY THINGS REBOOTING THE INTERWABZ
  
  -- this is important thing.
  if DEBUG then print("start debuggin' smoothly") end
  -- on every track change
  Song.selected_track_index_observable:add_notifier(getTrackInfos)
  -- still, we have to do that...
  if currentTrack == nil then 
    getTrackInfos()
  end
  
  -- on every device addition/removal(???)
  if deviceList_t == nil then 
    getDevices()
  end  
  
  -- your favourite LAUNCHER
  gui()
  
  if not (Song.tracks_observable:has_notifier(getTracks)) then
    Song.tracks_observable:add_notifier(getTracks)
  end
  
  -- mandatory check when creating new song.
  if not (Tool.app_new_document_observable:has_notifier(init)) then
    Tool.app_new_document_observable:add_notifier(init)
  end
end 

--[[
  your favourite menu & shorcut entries!
]]--
function checkGui()
  if (not dialogContent) then
    init()
  else
    openGui()
  end
end

renoise.tool():add_keybinding {
  name = "Global:BAGUETTEEEEER:Herduliekit",
  invoke = checkGui
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Baguetter "..version,
  invoke = checkGui
}
