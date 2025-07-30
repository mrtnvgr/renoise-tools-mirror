--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Local OSC Code
--------------------------------------------------------------------------------


--[[
OscClient.client
OscClient:__init(ip, port, protocol)
OscClient:Send(osc_message)
OscClient:IsConnected()
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "OscClient"


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function OscClient:__init(ip, port, protocol)
  -- Create a new osc client and connect to the specified server  
  self.client = nil
  local error

  self.client, error = renoise.Socket.create_client(ip, port, protocol)
  
  if error then
    self.client = nil    
    return false
  end
end


function OscClient:IsConnected()
  -- Returns the socket state
  
  if self.client then
    return self.client.is_open
  else
    return false
  end
end


function OscClient:Send(osc_message)
  -- Send an osc message
  
  -- silently drop if not connected
  if self.client.is_open then
    self.client:send(osc_message)
  end
end


function OscClient:Disconnect()
  -- Disconnects the socket
  
  if self.client.is_open then
    self.client:Close()
  end
end
