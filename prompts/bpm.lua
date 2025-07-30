--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- BPM Prompt Class
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Class
--------------------------------------------------------------------------------
class 'BpmPrompt' (BasePrompt)


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function BpmPrompt:__init()
  -- call base class init
  BasePrompt.__init(self)
  
  self.prompt = PROMPT_BPM
  
  -- display index
  set_lcd(string.format("%03d", renoise.song().transport.bpm), true)
end


--------------------------------------------------------------------------------
-- Event Handling Functions
--------------------------------------------------------------------------------
local counter = 1
local timetable = {}
local timetable_filled = false


function BpmPrompt:encoder(delta)
  -- encoder change
  local rst = renoise.song().transport
  rst.bpm = clamp(rst.bpm + delta, 32, 999)
end


function BpmPrompt:func_x()
  -- tap tempo code shamelessly stolen from TapTempo tool
  -- then it was hacked to pieces to fit pking :P
  
  local function get_average(tb)
    return (tb[#tb] - tb[1]) / (#tb - 1)
  end
  
  local function get_bpm(dt)
    -- 60 BPM => 1 beat per sec         
    return (60 / dt)
  end
  
  local function increase_counter()  
    counter = counter + 1
    if counter == 2 then
      set_led(LED_X, LED_ON)
    elseif counter == 5 then
      timetable_filled = true
      counter = 1
      set_led(LED_X, LED_OFF)
    end  
  end
  
  increase_counter()
  
  local clock = os.clock()
  table.insert(timetable, clock) 
    
  if (#timetable > 4) then
    timetable:remove(1)
  end
  
  if (timetable_filled) then
    local tempo = math.floor(get_bpm(get_average(timetable)))
    
    renoise.song().transport.bpm = clamp(tempo, 32, 999)
    
    timetable_filled = false
    timetable = {}
  end
end


function BpmPrompt:func_y()
  -- n/a
end


function BpmPrompt:func_z()
  -- n/a
end
