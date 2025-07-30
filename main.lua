--[[------------------------------------------------------------------------------------

  Full Stop
  
  provides a simple new play/stop command "play/panic stop = full sound stop",
  Technically simply combines "play / panic stop" into a new command.
  The command can be used as an alternative to the Renoise default "play/stop"
  command, which doesn't stop DSP output like reverb/delay tails.
  
  This command can be assigned to any key (e.g. space) or midi controller. 
  
  Hint:
  this command can cause crackling etc.

  Copyright 2011 Matthias Ehrmann, 
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License. 
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 
  
  Unless required by applicable law or agreed to in writing, software distributed 
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
  CONDITIONS OF ANY KIND, either express or implied. See the License for the specific 
  language governing permissions and limitations under the License. 
  
-------------------------------------------------------------------------------------]]--


--[[ initialize ]] --------------------------------------------------------------


renoise.tool():add_keybinding {
  name = "Global:Transport:Play/Full Stop",
  invoke = function() play_full_stop_hard() end
}
 
renoise.tool():add_midi_mapping {
  name = "Global:Transport:Play/Full Stop [Trigger]",
  invoke =  function(message) 
              if (message:is_trigger()) then
                play_full_stop_hard() 
              end
            end
}

function play_full_stop_hard()

  if (renoise.song().transport.playing) then
    renoise.song().transport:panic()
  else
    local start_mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
    renoise.song().transport:start(start_mode)  
  end
end

--[[ debug ]]--------------------------------------------------------------]]--

_AUTO_RELOAD_DEBUG = true
