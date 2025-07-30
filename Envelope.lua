---------------------------------------------------------------------------------------------------------------
-- Class: Envelope --------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

class 'Envelope'

-- Initilisation function
function Envelope:__init(x_size, y_size)

  self.bg_colour = {1,1,1}
  self.point_size = 14
  self.point_color = {50, 90, 140}
  self.point_active = {80, 220, 240}  
  self.line_point_size = 6 
  self.line_color = self.point_color
  self.line_point_density = 0.018

  self.x_size = x_size
  self.y_size = y_size
  self.points = {}
  self.line_points = {}
  self.selected_point = nil
  
  self.Math = MathFunctions()
    
  self.notifier = function() end
     
  -- GUI states
  self.y_ratio = self.y_size/self.x_size 
  self.vb = renoise.ViewBuilder()
  self.GUI = self:CreateGUI()
  self.GUI_ADD = self:CreateAddButton()
  self.GUI_REMOVE = self:CreateRemoveButton()
  self.GUI_INIT = self:CreateInitButton() 
  
  -- Init points
  local num_points = 1
  for n = 1, num_points do
    self:AddPoint((n-1)/num_points, 0.5)
  end
  self:SetSelected(self.points[1])
  self:DrawAllLines()

end

---------------------------------------------------------------------------------------------------------------

-- Add point
function Envelope:AddPoint(x,y)
  local table_pos = #self.points+1
  self.points[table_pos] = Point(self, x, y)
  self.GUI:add_child(self.points[table_pos].GUI)
  self:SetSelected(self.points[table_pos]) 
end


-- Remove selected point
function Envelope:RemovePoint()  
  if #self.points > 1 then  
    self.selected_point.x_pos = nil
    self.selected_point.y_pos = nil    
    local remove_points = {}
    -- Loop through points, remove from GUI and indentify any that should be flagged for removal
    for n = 1, #self.points do    
      self.GUI:remove_child(self.points[n].GUI) -- Remove point from vb
      -- Check if x/y coords have been set to 0   
      if self.points[n].x_pos == nil or self.points[n].y_pos == nil then 
        --self.points[n] = nil
        remove_points[#remove_points+1] = n -- Store table index to be removed
      end        
    end 
    -- Remove points if identified from table
    if #remove_points > 0 then 
      for n = 1, #remove_points do
        table.remove(self.points, remove_points[n])
      end
      remove_points = {}
    end
    -- Add points back to GUI
    for n = 1, #self.points do
      self.GUI:add_child(self.points[n].GUI)
    end          
  -- Set new selected point  
  self:SetSelected(self.points[1])
  end
end


-- Gets all points in time/value format
function Envelope:GetPoints()   
  local env_points = {}
  for n = 1, #self.points do
    env_points[n] = {}
    env_points[n].time = self.points[n].x_pos
    env_points[n].value = self.points[n].y_pos
  end
  return env_points
end


-- Sets points given in time/value format
function Envelope:SetPoints(env_points)   
  -- Remove existing
  for n = 1, #self.points do    
    self.GUI:remove_child(self.points[n].GUI)
    self.points[n] = nil 
  end
  self.points = {}
  -- Add points
  for n = 1, #env_points do    
    if env_points[n] then 
      if env_points[n].time and env_points[n].value then
        local time = self.Math:ClampValue(env_points[n].time, 0, 1)
        local value = self.Math:ClampValue(env_points[n].value, 0, 1)
        self:AddPoint(time, value)
      end
    end
  end  
  self:SetSelected(self.points[1])  
end


-- Initialise points
function Envelope:InitPoints()
  local env_points = {}
  env_points[1] = {time = 0, value = 0.5}
  self:SetPoints(env_points)
end


---------------------------------------------------------------------------------------------------------------
-- GUI drawing functions


-- Generate base GUI as vb:column, all objects inserted into this
function Envelope:CreateGUI()   
  -- Init variables
  local content = self.vb:column { style = "panel", spacing = -(self.y_size+3) }  
  local sort = table.sort
  local sort_function = function(a,b) return a.x_pos<b.x_pos end  
 
  
  -- Create and add xy_pad
  local xy_obj = self.vb:xypad {
    id = "xy_pad",
    width = self.x_size - self.point_size,
    height = self.y_size - self.point_size,
    value = {x=0.5, y=0.5},
    notifier = function(value)
      self.selected_point:SetPosition(value.x,value.y)
      self:RemoveLine()      
      sort( self.points, sort_function) -- Sort the table
      self:DrawAllLines()
      self.notifier()
    end
  }
  
  local xy_pad = CanvasObject(self, self.point_size/2, 1, xy_obj, self.point_size/2, 1 )
  content:add_child(xy_pad.GUI)
    
  -- Create and add background button to cover xy_pad gui
  local bg_obj = self.vb:button { 
    active = false,
    --bitmap = "bg1.bmp",
    color = self.bg_colour, 
    width = self.x_size - self.point_size,
    height = self.y_size - self.point_size
  }    
  
  local background = CanvasObject(self, self.point_size/2, 1, bg_obj, self.point_size/2, 1 )
  content:add_child(background.GUI) 
  
  return content
end


-- Create add point button
function Envelope:CreateAddButton() 
  local add_button = self.vb:button {
    id = "add_button", 
    height = 20,
    width = 20,
    color = {0,0,0},
    text = "+",
    notifier = function()
      self:AddPoint(0.5,0.5)            
    end       
  }
  return add_button
end


-- Create remove point button
function Envelope:CreateRemoveButton() 
  local remove_button = self.vb:button {
    id = "remove_button",
    height = 20,
    width = 20, 
    text = "-",
    notifier = function()
      self:RemovePoint()          
    end       
  }
  return remove_button
end


-- Create points init button
function Envelope:CreateInitButton() 
  local init_button = self.vb:button {
    id = "init_button",
    height = 20,
    --width = 20, 
    text = "Initialise",
    notifier = function()
      self:InitPoints()          
    end       
  }
  return init_button
end


-- Set xy_pad point position
function Envelope:SetXY_Pad(x,y)
  self.vb.views["xy_pad"].value = {x=x, y=y}
end


-- Make the given point the selected point
function Envelope:SetSelected(point_obj)
  -- Deselect previous point
  if self.selected_point then
    self.selected_point:SetColor(self.point_color)
  end  
  -- Make this point selected 
  self.selected_point = point_obj
  self.selected_point:SetColor(self.point_active)
  self:SetXY_Pad(self.selected_point.x_pos, self.selected_point.y_pos)
end


---------------------------------------------------------------------------------------------------------------
-- Dotted line drawing Functions


-- Draw a line between two points
function Envelope:DrawLine(start_pos, end_pos, extra_points) 
  if not extra_points then
    extra_points = 0
  end    
  
  local line_position = 0
  local line_inc = self.line_point_density / self.Math:Sqrt( self.Math:Abs(end_pos.x - start_pos.x)^2 + (self.Math:Abs(end_pos.y - start_pos.y)*self.y_ratio)^2 )
  local num_points = 1/line_inc + extra_points
  
  for n = 1, num_points do
      local x_pos = self.Math:Interpolate(line_position, start_pos.x, end_pos.x)
      local y_pos = self.Math:Interpolate(line_position, start_pos.y, end_pos.y) 
      self.line_points[#self.line_points+1] = LinePoint(self, x_pos, y_pos)
      self.GUI:add_child(self.line_points[#self.line_points].GUI)
      line_position = line_position + line_inc
  end
end


-- Draw line through all points
function Envelope:DrawAllLines()
  for n = 1, #self.points do    
    local start_pos = 0
    local end_pos = 0    
    if n == 1 then -- Edge case for first point   
      start_pos = {x=0,y=self.points[n].y_pos}
      end_pos = {x = self.points[n].x_pos, y = self.points[n].y_pos} 
      self:DrawLine(start_pos, end_pos)
      -- If last point draw future line
      if #self.points == 1 then
        start_pos = {x=self.points[n].x_pos, y=self.points[n].y_pos}
        end_pos = {x = 1, y = self.points[n].y_pos}
        self:DrawLine(start_pos, end_pos, 1)
      end
    elseif n == #self.points then -- Edge case for last point      
      -- Draw point line
      start_pos = {x=self.points[n-1].x_pos, y=self.points[n-1].y_pos}
      end_pos = {x=self.points[n].x_pos, y=self.points[n].y_pos}
      self:DrawLine(start_pos, end_pos)      
      -- Draw future line
      start_pos = {x=self.points[n].x_pos, y=self.points[n].y_pos}
      end_pos = {x = 1, y = self.points[n].y_pos}
      self:DrawLine(start_pos, end_pos, 1) 
    else -- All other points 
      start_pos = {x=self.points[n-1].x_pos, y=self.points[n-1].y_pos}
      end_pos = {x=self.points[n].x_pos, y=self.points[n].y_pos}   
      self:DrawLine(start_pos, end_pos)   
    end
  end
end


-- Remove all lines
function Envelope:RemoveLine()
  if #self.line_points > 0 then
    for n = 1, #self.line_points do
      self.GUI:remove_child(self.line_points[n].GUI)
      self.line_points[n] = nil
    end
    self.line_points = {}
  end
end


---------------------------------------------------------------------------------------------------------------
-- Class: Canvas object -----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

class 'CanvasObject'

-- Initilisation function
function CanvasObject:__init(Canvas, x, y, object, x_padding, y_padding)
  
  -- Parent states
  self.Canvas = Canvas
  self.x_size = Canvas.x_size
  self.y_size = Canvas.y_size
    
  -- GUI states
  self.y_size_o = self.y_size+3
  self.x_size_o = self.x_size+2
  
  if y_padding then 
    self.y_padding = y_padding
  else
    self.y_padding = 1
  end
  
  if x_padding then 
    self.x_padding = x_padding
  else
    self.x_padding = 1
  end
  
  self.y_pos = y
  self.x_pos = x
    
  self.vb = renoise.ViewBuilder()

  -- Create x/y object container     
  self.GUI = self.vb:row {
    self.vb:space { height = self.y_size_o, width = self.y_padding },    
    self.vb:column {  
      self.vb:space { width = self.x_size_o, height = self.x_padding },
      self.vb:space { id = "yspace", height = self.y_pos },
      self.vb:row {
        self.vb:space { id = "xspace", width = self.x_pos },        
        object                
      }
    }     
  }       
end


-- Set object position
function CanvasObject:SetPosition(x,y)
  self.x_pos = x
  self.y_pos = y
  self.vb.views["xspace"].width = x
  self.vb.views["yspace"].height = y
end


---------------------------------------------------------------------------------------------------------------
-- Class: Point -----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


class 'Point'

-- Initilisation function
function Point:__init(Canvas, x, y)
  
  -- Parent states
  self.Canvas = Canvas
  self.x_size = Canvas.x_size
  self.y_size = Canvas.y_size
  self.point_size = Canvas.point_size
  self.point_color = Canvas.point_color
  self.Math = Canvas.Math
  
  --Canvas.selected_point = self
  
  -- Object states
  self.x_pos = x
  self.y_pos = y
  
  -- GUI states
  self.vb = renoise.ViewBuilder()
  self.point = self:CreateObject(x,y)
  self.GUI = self.point.GUI
  
end


-- Create point GUI
function Point:CreateObject(x,y)        
  local point_obj = self.vb:button {
    id = "point", 
    color = self.point_color, 
    width = self.point_size, 
    height = self.point_size, 
    notifier = function()
      self.Canvas:SetSelected(self)            
    end       
  }        
  local point = CanvasObject(self.Canvas, self:X(x), self:Y(y), point_obj)
  return point  
end


-- Translate x position
function Point:X(x)
  return self.Math:Interpolate(x, 1, self.x_size-self.point_size) 
end

-- Translate y position
function Point:Y(y)
  return self.Math:Interpolate( (1-y), 1, self.y_size-self.point_size)
end

-- Set point position
function Point:SetPosition(x,y)
  self.x_pos = x
  self.y_pos = y
  self.point:SetPosition( self:X(x), self:Y(y) )
end


function Point:SetColor(rgb)
  self.vb.views["point"].color = rgb
end



---------------------------------------------------------------------------------------------------------------
-- Class: Line Point ------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


class 'LinePoint'

-- Initilisation function
function LinePoint:__init(Canvas, x, y)
  
  -- Parent states
  self.Canvas = Canvas
  self.x_size = Canvas.x_size
  self.y_size = Canvas.y_size
  self.CPoint_size = Canvas.point_size
  self.point_size = Canvas.line_point_size
  self.color = Canvas.line_color
  
  -- Local functions
  self.Math = Canvas.Math
  self.offset = self.Math:Floor((self.CPoint_size-self.point_size)/2+0.5)
    
  -- GUI states
  self.vb = renoise.ViewBuilder()
  self.point = self:CreateObject(x,y)
  self.GUI = self.point.GUI

end


-- Create point GUI
function LinePoint:CreateObject(x,y)        
  local point_obj = self.vb:button { 
    active = false,
    color = self.color, 
    width = self.point_size, 
    height = self.point_size,  
  }
  local point = CanvasObject(self.Canvas, self:X(x), self:Y(y), point_obj)
  return point  
end


-- Translate x position
function LinePoint:X(x)
  return self.Math:Interpolate(x, 1 + self.offset, self.x_size-self.point_size - self.offset)
end

-- Translate y position
function LinePoint:Y(y)
  return self.Math:Interpolate( (1-y), 1 + self.offset, self.y_size-self.point_size - self.offset)
end

-- Set point position
function LinePoint:SetPosition(x,y)
  self.point:SetPosition( self:X(x), self:Y(y) )
end



---------------------------------------------------------------------------------------------------------------
-- Class: Helper Math -----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

class 'MathFunctions'

-- Initilisation function
function MathFunctions:__init()
  self.floor = math.floor
  self.sqrt = math.sqrt
  self.abs = math.abs
end

-- Interpolate/Scale
function MathFunctions:Interpolate(pos, min, max) -- Input must be 0 to 1 
  return pos*(max-min)+min
end
  
-- Round to decimal places
function MathFunctions:Round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Clamp values
function MathFunctions:ClampValue(input, min_val, max_val)
  return math.min(math.max(input, min_val), max_val)
end

-- Floor
function MathFunctions:Floor(x)
  return self.floor(x)
end

-- Sqrt
function MathFunctions:Sqrt(x)
  return self.sqrt(x)
end

-- Abs
function MathFunctions:Abs(x)
  return self.abs(x)
end



