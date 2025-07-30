--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Manual Midi Map Code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Midi maps
--------------------------------------------------------------------------------

function add_midi_maps()
  -- CellsChannel Maps for individual Channels
  for tr = 1, preferences.channel_count.value do
    
    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Select Channel") then 
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Select Channel",
        invoke = function(message)
          if cells_running then
            cc[tr]:SelectTrack()
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Toggle Cue") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Toggle Cue",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:ToggleCue()
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Toggle Mute") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Toggle Mute",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:ToggleMute()
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Toggle Live Jam Mode") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Toggle Live Jam Mode",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:ToggleLiveJamMode()
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Set to A") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Set to A",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:MoveRouting(1)
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Set to M") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Set to M",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:MoveRouting(2)
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Set to B") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Set to B",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:MoveRouting(3)
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Toggle Bass Kill") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Toggle Bass Kill",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:ToggleBassKill()
            end
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Volume") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Volume",
        invoke = function(message)
          if cells_running then
            cc[tr]:MoveVolume(message.int_value / 127)
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Panning") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Panning",
        invoke = function(message)
          if cells_running then
            cc[tr]:MovePanning(message.int_value / 127)
          end
        end
      }
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Transpose") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Transpose",
        invoke = function(message)
          if cells_running then
            cc[tr]:MoveTranspose(message.int_value / 127)
          end
        end
      }  
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Filter") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Filter",
        invoke = function(message)
          if cells_running then
            cc[tr]:MoveFilter(message.int_value / 127)
          end
        end
      }
    end
    
    for c = 1, preferences.cells_count.value do
      if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Cue Cell "..c) then   
        renoise.tool():add_midi_mapping{
          name = "Cells!:Channel "..tr..":Cue Cell "..c,
          invoke = function(message)
            if cells_running then
              if message:is_trigger() then
                cc[tr]:CueCell(c)
              end
            end
          end
        }
      end
    end

    if not renoise.tool():has_midi_mapping("Cells!:Channel "..tr..":Cue Stop") then     
      renoise.tool():add_midi_mapping{
        name = "Cells!:Channel "..tr..":Cue Stop",
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:CueStop()
            end
          end
        end
      }
    end
  end
  
  
  -- PlayChannel Maps for current Channel
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Toggle Cue") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Toggle Cue",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:ToggleCue()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Toggle Mute") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Toggle Mute",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:ToggleMute()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Toggle Live Jam Mode") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Toggle Live Jam Mode",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:ToggleLiveJamMode()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Set to A") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Set to A",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:MoveRouting(1)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Set to M") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Set to M",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:MoveRouting(2)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Set to B") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Set to B",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:MoveRouting(3)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Toggle Bass Kill") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Toggle Bass Kill",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:ToggleBassKill()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Volume") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Volume",
      invoke = function(message)
        if cells_running then
          local tr = cm:GetCellsChannel()
          if tr > 0 then
            cc[tr]:MoveVolume(message.int_value / 127)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Panning") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Panning",
      invoke = function(message)
        if cells_running then
          local tr = cm:GetCellsChannel()
          if tr > 0 then
            cc[tr]:MovePanning(message.int_value / 127)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Transpose") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Transpose",
      invoke = function(message)
        if cells_running then
          local tr = cm:GetCellsChannel()
          if tr > 0 then
            cc[tr]:MoveTranspose(message.int_value / 127)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Filter") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Filter",
      invoke = function(message)
        if cells_running then
          local tr = cm:GetCellsChannel()
          if tr > 0 then
            cc[tr]:MoveFilter(message.int_value / 127)
          end
        end
      end
    }
  end
    
  for c = 1, preferences.cells_count.value do
    if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Cue Cell "..c) then
      renoise.tool():add_midi_mapping{
        name = "Cells!:Current Channel:Cue Cell "..c,
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              local tr = cm:GetCellsChannel()
              if tr > 0 then
                cc[tr]:CueCell(c)
              end
            end
          end
        end
      }
    end
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Current Channel:Cue Stop") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Current Channel:Cue Stop",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local tr = cm:GetCellsChannel()
            if tr > 0 then
              cc[tr]:CueStop()
            end
          end
        end
      end
    }
  end
  
  -- Channel Selection
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Select Previous Cells! Channel") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Select Previous Cells! Channel",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local chan = cm:GetCellsChannel()
            if chan > 2 then
              cc[chan-1]:SelectTrack()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Select Next Cells! Channel") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Select Next Cells! Channel",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            local chan = cm:GetCellsChannel()
            if chan < (#cc - 1) then
              cc[chan+1]:SelectTrack()
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Select Cells! Channel [rotary / fader]") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Select Cells! Channel [rotary / fader]",
      invoke = function(message)
        if cells_running then
          cc[math.floor(((message.int_value+1) / 128)*(preferences.channel_count.value-1))+1]:select_Channel()
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Select Cells! Channel [encoder]") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Select Cells! Channel [encoder]",
      invoke = function(message)
        if cells_running then
          if message.int_value > 63 then
            -- backwards
            local chan = cm:GetCellsChannel()
            if chan > 2 then
              cc[chantr-1]:select_Channel()
            end
          else
            -- forwards
            local chan = cm:GetCellsChannel()
            if chan < (#cc - 1) then
              cc[chan+1]:select_Channel()
            end
          end
        end
      end
    }
  end
  
  for tr = 1, preferences.channel_count.value do
    if not renoise.tool():has_midi_mapping("Cells!:Transport:Select Cells! Channel "..tr) then
      renoise.tool():add_midi_mapping{
        name = "Cells!:Transport:Select Cells! Channel "..tr,
        invoke = function(message)
          if cells_running then
            if message:is_trigger() then
              cc[tr]:select_Channel()
            end
          end
        end
      }
    end
  end
  
  
  -- FX Maps
  if not renoise.tool():has_midi_mapping("Cells!:MultiFX:Effect Rate") then
    renoise.tool():add_midi_mapping{
      name = "Cells!:MultiFX:Effect Rate",
      invoke = function(message)
        if cells_running then
          cm:MoveEffectRate(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:MultiFX:Effect Amount") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:MultiFX:Effect Amount",
      invoke = function(message)
        if cells_running then
          cm:MoveEffectAmount(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:MultiFX:Effect Type") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:MultiFX:Effect Type",
      invoke = function(message)
        if cells_running then
          cm:MoveEffectType(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:MultiFX:Effect Target") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:MultiFX:Effect Target",
      invoke = function(message)
        if cells_running then
          cm:MoveEffectTarget(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:MultiFX:Effect On/Off Toggle") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:MultiFX:Effect On/Off Toggle",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            cm:ToggleEffectState()
          end
        end
      end
    }
  end
  
  
  -- Transport maps
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Tempo Nudge Up [gate]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Tempo Nudge Up [gate]",
      invoke = function(message)
        if cells_running then
          if message:is_switch() then
            if message.int_value ~= 0 then
              ct:NudgeBpm(1, true)
            else
              ct:NudgeBpm(1, false)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Tempo Nudge Down [gate]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Tempo Nudge Down [gate]",
      invoke = function(message)
        if cells_running then
          if message:is_switch() then
            if message.int_value ~= 0 then
              ct:NudgeBpm(-1, true)
            else
              ct:NudgeBpm(-1, false)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Increase BPM") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Increase BPM",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            renoise.song().transport.bpm = renoise.song().transport.bpm+1
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Decrease BPM") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Decrease BPM",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            renoise.song().transport.bpm = renoise.song().transport.bpm-1
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Set Quantize to 4 beats") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Set Quantize to 4 beats",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            ct:MoveQuantizeValue(1)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Set Quantize to 2 beats") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Set Quantize to 2 beats",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            ct:MoveQuantizeValue(0.75)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Set Quantize to 1 beat") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Set Quantize to 1 beat",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            ct:MoveQuantizeValue(0.5)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Set Quantize to 1/2 beat") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Set Quantize to 1/2 beat",
      invoke = function(message)
        if cells_running then
          if message:is_trigger() then
            ct:MoveQuantizeValue(0.1)
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Set Quantize [rotary / fader]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Set Quantize [rotary / fader]",
      invoke = function(message)
        if cells_running then
          ct:MoveQuantizeValue(message.int_value / 127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Crossfader [rotary / fader]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Crossfader [rotary / fader]",
      invoke = function(message)
        if cells_running then
          cm:MoveCrossfader(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Crossfader A Cut [gate]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Crossfader A Cut [gate]",
      invoke = function(message)
        if cells_running then
          if message:is_switch() then
            if message.int_value ~= 0 then
              cm:SetCutState(0, true)
            else
              cm:SetCutState(0, false)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Crossfader B Cut [gate]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Crossfader B Cut [gate]",
      invoke = function(message)
        if cells_running then
          if message:is_switch() then
            if message.int_value ~= 0 then
              cm:SetCutState(1, true)
            else
              cm:SetCutState(1, false)
            end
          end
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Cue volume [rotary / fader]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Cue volume [rotary / fader]",
      invoke = function(message)
        if cells_running then
          cm:MoveCueVolume(message.int_value/127)
        end
      end
    }
  end
  
  if not renoise.tool():has_midi_mapping("Cells!:Transport:Master volume [rotary / fader]") then 
    renoise.tool():add_midi_mapping{
      name = "Cells!:Transport:Master volume [rotary / fader]",
      invoke = function(message)
        if cells_running then
          cm:MoveMasterVolume(message.int_value/127)
        end
      end
    }
  end
end

