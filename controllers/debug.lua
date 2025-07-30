--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Controller Debug Class [for testing only]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "CellsControllerDebug"

--[[
Variables:
  self.midi_in_device
  self.midi_out_device

Functions:
  __init(midi_in, midi_out)
  MidiHandler(message)
  SysexHandler(message)

API:
  Reset()
  Tick()
  SetPlayState(state)
  SetCellState(channel, cell, state)
  SetStopState(channel, state)
  SetMute(channel, state)
  SetCue(channel, state)
  SetJam(channel, state)
  SetSelected(channel)
  SetRouting(channel, routing)
  SetBasskill(channel, state)
  SetFilter(channel, position)
  SetTranspose(channel, position)
  SetPanning(channel, position)
  SetVolume(channel, position)
  SetCrossfader(position)
  SetCrossfaderCut(ab, state)
  SetFXRate(rate)
  SetFXAmount(amount)
  SetFXType(type_id)
  SetFXState(state)
  SetMasterVolume(value)
  SetCueVolume(value)
]]--


function CellsControllerDebug:__init(midi_in, midi_out)
  -- Initialise the controller and bind to Renoise
  
  -- Check for valid ports
  if table.find(renoise.Midi.available_output_devices(), midi_out) then
    if table.find(renoise.Midi.available_input_devices(), midi_in) then
      -- Seems ok attach to ports
      print("CellsControllerDebug -> __init -> Attaching midi")
      
      self.midi_in_device = renoise.Midi.create_input_device(
        midi_in,
        {self, self.MidiHandler},
        {self, self.SysexHandler})
        
      self.midi_out_device = renoise.Midi.create_output_device(midi_out)
         
    end
  end
end


function CellsControllerDebug:MidiHandler(midi_message)
  -- Controller specific midi handler
  print(string.format("CellsControllerDebug -> Midi Handler -> Message [%x, %x, %x]", midi_message[1], midi_message[2], midi_message[3]))
end


function CellsControllerDebug:SysexHandler(midi_message)
  -- Controller specific sysex handler
  print("CellsControllerDebug -> SysEx Handler -> Message")
  for i = 1, #message do
    print(string.format(" %x", message[i]))
  end
end


function CellsControllerDebug:Reset()
  -- Reset to the defaults to match the gui on startup
  print("CellsControllerDebug -> Reset()")
end


function CellsControllerDebug:Tick(line)
  -- New renoise play line 
  print("CellsControllerDebug -> Tick(); line=",line)
end


function CellsControllerDebug:SetCellState(channel, cell, state)
  print(string.format("CellsControllerDebug -> set cell %u on channel %u to state %u",
                      cell, channel, state))
end


function CellsControllerDebug:SetStopState(channel, state)
  print(string.format("CellsControllerDebug -> set stop state on channel %u to state %u",
                      channel, state))
end


function CellsControllerDebug:SetMute(channel, state)

  if state then
    print(string.format("CellsControllerDebug -> set channel %u mute state to true",
                        channel))
  else
    print(string.format("CellsControllerDebug -> set channel %u mute state to false",
                        channel))
  end
end


function CellsControllerDebug:SetSelected(channel)

  print(string.format("CellsControllerDebug -> seleected channel %u",
                      channel))
end


function CellsControllerDebug:SetBasskill(channel, state)

  if state then
    print(string.format("CellsControllerDebug -> set channel %u bass kill state to true",
                        channel))
  else
    print(string.format("CellsControllerDebug -> set channel %u bass kill state to false",
                        channel))
  end
end


function CellsControllerDebug:SetCue(channel, state)

  if state then
    print(string.format("CellsControllerDebug -> set channel %u cue state to true",
                        channel))
  else
    print(string.format("CellsControllerDebug -> set channel %u cue state to false",
                        channel))
  end
end


function CellsControllerDebug:SetJam(channel, state)

  if state then
    print(string.format("CellsControllerDebug -> set channel %u jam mode state to true",
                        channel))
  else
    print(string.format("CellsControllerDebug -> set channel %u jam mode state to false",
                        channel))
  end
end


function CellsControllerDebug:SetRouting(channel, state)
  -- state = 1 for A, 2 for M, 3 for B
  print(string.format("CellsControllerDebug -> set channel %u routing state to %u",
                      channel, state))
end


function CellsControllerDebug:SetFilter(channel, value)
  print(string.format("CellsControllerDebug -> set channel %u filter to %f",
                      channel, value))
end


function CellsControllerDebug:SetTranspose(channel, value)
  print(string.format("CellsControllerDebug -> set channel %u transpose to %f",
                      channel, value))
end


function CellsControllerDebug:SetPanning(channel, value)
  print(string.format("CellsControllerDebug -> set channel %u panning to %f",
                      channel, value))
end


function CellsControllerDebug:SetVolume(channel, volume)
  print(string.format("CellsControllerDebug -> set volume on channel %u to %f",
                      channel, volume))
end


function CellsControllerDebug:SetCrossfader(position)
  -- 0 <= position <= 1
  print(string.format("CellsControllerDebug -> set crossfader to %f", position))
end


function CellsControllerDebug:SetCrossfaderCut(group, state)
  -- group: 0 = A, 1 = B
  
  if group == 0 then
    if state then
      print("CellsControllerDebug -> set crossfader cut A to on")
    else
      print("CellsControllerDebug -> set crossfader cut A to off")
    end
  else
    if state then
      print("CellsControllerDebug -> set crossfader cut B to on")
    else
      print("CellsControllerDebug -> set crossfader cut B to off")
    end
  end
end


function CellsControllerDebug:SetFXAmount(value)
  print(string.format("CellsControllerDebug -> set FX amount to %u", value))
end


function CellsControllerDebug:SetFXRate(value)
  print(string.format("CellsControllerDebug -> set FX rate to %f", value))
end


function CellsControllerDebug:SetFXType(type_id)
  print(string.format("CellsControllerDebug -> set FX type to %u", type_id))
end


function CellsControllerDebug:SetFXTarget(type_id)
  -- 1 = A, 2 = M, 3 = B
  print(string.format("CellsControllerDebug -> set FX target to %u", type_id))
end


function CellsControllerDebug:SetFXState(state)

  if state then
    print("CellsControllerDebug -> set FX state to on")
  else
    print("CellsControllerDebug -> set FX state to off")
  end
end


function CellsControllerDebug:SetMasterVolume(value)
  print(string.format("CellsControllerDebug -> set main volume to %f", value))
end


function CellsControllerDebug:SetCueVolume(value)
  print(string.format("CellsControllerDebug -> set cue volume to %f", value))
end


function CellsControllerDebug:SetPlayState(state)

  if state then
    print("CellsControllerDebug -> set play state to playing")
  else
    print("CellsControllerDebug -> set play state to stopped")
  end
end



--------------------------------------------------------------------------------
-- Register Class
--------------------------------------------------------------------------------
cf:Register("Debug", CellsControllerDebug)

