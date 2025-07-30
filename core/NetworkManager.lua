--------------------------------------------------------------------------------
-- Cells!
--
-- Copyright 2012 Martin Bealby
--
-- Cells Network management Code
--------------------------------------------------------------------------------


--[[
NetworkManager()
NetworkManager.ui_node_status[]
NetworkManager.ui_slave_status
NetworkManager.ui_frame
NetworkManager.nodes[]
NetworkManager:__init()
NetworkManager:ConnectLocalhost()
NetworkManager:ConnectSlaves()
NetworkManager:GetUI()
NetworkManager:LocalSend()
NetworkManager:SlaveSend()
NetworkManager:AllSend()
NetworkManager:BindHooks()
NetworkManager:UnbindHooks()
NetworkManager:NodeTest(node_id)
NetworkManager:BPMHook()
NetworkManager:StartStopHook()
]]--



--------------------------------------------------------------------------------
-- Class Definition
--------------------------------------------------------------------------------
class "NetworkManager"



--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function NetworkManager:__init()
  -- Initialise and create the network connections
  
  local vb = renoise.ViewBuilder()
  
  --
  -- Reset variables
  --
  self.nodes = {}
  self.ui_node_status = {}
  self.ui_slave_status = nil
  self.ui_frame = nil
  
  --
  -- Create UI
  --
  self.ui_slave_status = vb:button{
    text = "Slave node",
    width = 100,
    color = COLOUR_BLACK,
  }
  
  for i = 1, 4 do
    table.insert(self.ui_node_status,
                 vb:button{
                   height = 18,
                   width = 18,
                   color = COLOUR_BLACK,
                   notifier = function()
                     if self.ui_node_status[i].color ~= COLOUR_BLACK then
                       self:NodeTest(i)
                     end
                   end
                 })
  end
  
  if preferences.lan_slave.value == true then
    -- slave ui
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
          self.ui_slave_status,
        }
      }
    }
  else
    -- master ui
    self.ui_frame = vb:row{
      style = "group",
      spacing = 10,
      margin = 7,
      self.ui_node_status[1],
      self.ui_node_status[2],
      self.ui_node_status[3],
      self.ui_node_status[4],
    }
  end
  
  self:Reset()
end


function NetworkManager:Reset()  
  -- Local loopback connection
  table.insert(self.nodes, OscClient(preferences.nodes.node1.ip.value,
                                     preferences.nodes.node1.port.value,
                                     preferences.nodes.node1.protocol.value))
                                     
  -- Update status colours
  if self.nodes[1]:IsConnected() then
    self.ui_slave_status.color = COLOUR_GREEN
    self.ui_node_status[1].color = COLOUR_GREEN
  else
    self.ui_slave_status.color = COLOUR_RED
    self.ui_node_status[1].color = COLOUR_RED
  end
  
  -- Connect to slave nodes if master
  if preferences.lan_slave.value == false then
    
    -- node 2
    if preferences.nodes.node2.enable.value == true then
      table.insert(self.nodes, 2, OscClient(preferences.nodes.node2.ip.value,
                                            preferences.nodes.node2.port.value,
                                            preferences.nodes.node2.protocol.value))
      -- Update status colours
      if self.nodes[2]:IsConnected() then
        self.ui_node_status[2].color = COLOUR_GREEN
      else
        self.ui_node_status[2].color = COLOUR_RED
      end
    end
    
    -- node 3
    if preferences.nodes.node3.enable.value == true then
      table.insert(self.nodes, 3, OscClient(preferences.nodes.node3.ip.value,
                                            preferences.nodes.node3.port.value,
                                            preferences.nodes.node3.protocol.value))
      -- Update status colours
      if self.nodes[3]:IsConnected() then
        self.ui_node_status[3].color = COLOUR_GREEN
      else
        self.ui_node_status[3].color = COLOUR_RED
      end
    end
    
    -- node 4
    if preferences.nodes.node4.enable.value == true then
      table.insert(self.nodes, 4, OscClient(preferences.nodes.node4.ip.value,
                                            preferences.nodes.node4.port.value,
                                            preferences.nodes.node4.protocol.value))
      -- Update status colours
      if self.nodes[4]:IsConnected() then
        self.ui_node_status[4].color = COLOUR_GREEN
      else
        self.ui_node_status[4].color = COLOUR_RED
      end
    end
  end
  
  -- attach hooks if master
  if preferences.lan_slave.value == false then
    self:BindHooks()
  end
end


function NetworkManager:GetUI()
  -- Return the UI
  
  return self.ui_frame
end


function NetworkManager:LocalSend(osc_message)
  -- Sends a message to the local osc server
  
  if self.nodes[1]:IsConnected() then
    self.nodes[1]:Send(osc_message)
  end
end


function NetworkManager:RemoteSend(osc_message)
  -- Sends a message to the remote osc servers
  
  for i = 2, 4 do
    if self.nodes[i] then
      if self.nodes[i]:IsConnected() then
        self.nodes[i]:Send(osc_message)
      end
    end
  end
end


function NetworkManager:AllSend(osc_message)
  -- Sends a message to all local and remote osc servers
  
  for i = 1, 4 do
    if self.nodes[i] then
      if self.nodes[i]:IsConnected() then
        self.nodes[i]:Send(osc_message)
      end
    end
  end
end


function NetworkManager:NodeTest(node_id)
  -- Sends a test lua message (displays a messagebox)

  -- 1 = localhost
  -- 2..4 = remote nodes
  local msg = renoise.Osc.Message
  
  if self.nodes[node_id] then
    if self.nodes[node_id]:IsConnected() then
      self.nodes[node_id]:Send(msg("/renoise/evaluate",
                                   {{tag="s",
                                     value='renoise.app():show_status("Cells! network test")'}}))
    else
      renoise.app().display_error("Node not connected.  Is this node enabled?")
    end
  end
end



--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
function NetworkManager:BindHooks()
  -- Bind the network manager hooks
  
  if not renoise.song().transport.playing_observable:has_notifier(self, self.StartStopHook) then
    renoise.song().transport.playing_observable:add_notifier(self, self.StartStopHook)
  end
  
  if not renoise.song().transport.bpm_observable:has_notifier(self, self.BpmChangeHook) then
    renoise.song().transport.playing_observable:add_notifier(self, self.BpmChangeHook)
  end
end


function NetworkManager:UnbindHooks()
  -- Unbind the network manager hooks
  
  if renoise.song().transport.playing_observable:has_notifier(self, self.StartStopHook) then
    renoise.song().transport.playing_observable:remove_notifier(self, self.StartStopHook)
  end
  
  if renoise.song().transport.bpm_observable:has_notifier(self, self.BpmChangeHook) then
    renoise.song().transport.playing_observable:remove_notifier(self, self.BpmChangeHook)
  end
  
end


function NetworkManager:BpmChangeHook()
  -- fires when master changes bpm 
  local msg = renoise.Osc.Message
  
  self:RemoteSend(msg("/renoise/song/bpm",
                      {{tag="f", value=renoise.song().transport.bpm}})) -- bpm
end


function NetworkManager:StartStopHook()
  -- fires when master changes bpm 
  local msg = renoise.Osc.Message
  
  if renoise.song().transport.playing then
    -- start
    self:RemoteSend(msg("/renoise/song/sequence/trigger",
                        {{tag="i", value=1}})) -- sequence index
  else
    -- stop
    self:RemoteSend(msg("/renoise/transport/panic"))
  end
  
end
