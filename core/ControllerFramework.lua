--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Controller Framework Code
--------------------------------------------------------------------------------


--[[
ControllerFramework.controller_list
ControllerFramework:__init()
ControllerFramework:Register(name, classname)
ControllerFramework:ListControllers()
ControllerFramework:LoadAllControllers()
ControllerFramework:StartController(controller, midi_in, midi_out)
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "ControllerFramework"


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function ControllerFramework:__init()
  -- Initialise the controller framework
  
  self.controller_list = {}
  self.running_controllers = {}
end


function ControllerFramework:Register(name, classname)
  -- Registers a controller class with Cells!
  table.insert(self.controller_list, {name, classname})
end


function ControllerFramework:Reset()
  -- Resets all running controllers

  for i = 1, #self.running_controllers do
    self.running_controllers[i] = nil
  end

  self.running_controllers = {}
end


function ControllerFramework:ListControllers()
  -- Returns a list of controllers by name
  local t = {"None"}
  for i = 1, #self.controller_list do
    table.insert(t, self.controller_list[i][1])
  end
  
  return t
end


function ControllerFramework:StartController(name, midi_in, midi_out)
  -- Starts a controller
  
  -- create name cache
  local t = {}
  for i = 1, #self.controller_list do
    table.insert(t, self.controller_list[i][1])
  end
  
  -- Check 
  local index = table.find(t, name)
  
  -- Found?
  if not index then
    renoise.app():show_error("Couldn't find controller of type:" .. name)
    return false
  end
  
  -- Initialise
  local controller = self.controller_list[index][2](midi_in, midi_out)

  -- Initialised ok?
  if not controller then
    return false
  end
  
  table.insert(self.running_controllers, controller)
  
  -- everything ok
  return true
end


function ControllerFramework:LoadAllControllers()
  -- Iterate over the preferences and attempt to load all controllers
  
  if preferences.controllers.controller1.type.value ~= "None" then
    self:StartController(preferences.controllers.controller1.type.value,
                         preferences.controllers.controller1.in_port.value,
                         preferences.controllers.controller1.out_port.value)
  end
  
  if preferences.controllers.controller2.type.value ~= "None" then
    self:StartController(preferences.controllers.controller2.type.value,
                         preferences.controllers.controller2.in_port.value,
                         preferences.controllers.controller2.out_port.value)
  end
end



--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------
function ControllerFramework:SetPlayState(state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetPlayState(state)
  end
end


function ControllerFramework:SetMasterVolume(vol)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetMasterVolume(vol)
  end
end


function ControllerFramework:SetCueVolume(vol)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCueVolume(vol)
  end
end


function ControllerFramework:SetCrossfader(val)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCrossfader(val)
  end
end


function ControllerFramework:SetCrossfaderCut(group, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCrossfaderCut(group, state)
  end
end


function ControllerFramework:SetFXRate(rate)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFXRate(rate)
  end
end


function ControllerFramework:SetFXAmount(amount)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFXAmount(amount)
  end
end


function ControllerFramework:SetFXType(id)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFXType(id)
  end
end


function ControllerFramework:SetFXTarget(id)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFXTarget(id)
  end
end


function ControllerFramework:SetFXState(state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFXState(state)
  end
end


function ControllerFramework:SetCellState(channel, cell, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCellState(channel, cell, state)
  end
end


function ControllerFramework:SetPanning(channel, value)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetPanning(channel, value)
  end
end


function ControllerFramework:SetVolume(channel, value)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetVolume(channel, value)
  end
end


function ControllerFramework:SetTranspose(channel, value)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetTranspose(channel, value)
  end
end


function ControllerFramework:SetFilter(channel, value)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetFilter(channel, value)
  end
end


function ControllerFramework:SetMute(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetMute(channel, state)
  end
end


function ControllerFramework:SetBasskill(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetBasskill(channel, state)
  end
end


function ControllerFramework:SetCue(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCue(channel, state)
  end
end


function ControllerFramework:SetJam(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetJam(channel, state)
  end
end


function ControllerFramework:SetRouting(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetRouting(channel, state)
  end
end


function ControllerFramework:SetSelected(channel)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetSelected(channel)
  end
end


function ControllerFramework:SetCellState(channel, cell, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetCellState(channel, cell, state)
  end
end


function ControllerFramework:SetStopState(channel, state)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:SetStopState(channel, state)
  end
end


function ControllerFramework:Tick(line)
  -- Send a message to all running controllers
  
  for i = 1, #self.running_controllers do
    self.running_controllers[i]:Tick(line)
  end
end

