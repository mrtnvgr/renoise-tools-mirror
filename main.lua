--Easy Tune v1.5 by Aftab Hussain aka afta8 - fathand@gmail.com - 6th April 2014

--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Stats functions from: http://lua-users.org/wiki/SimpleStats

-- Table to hold statistical functions
local stats={}

-- Get the mean value of a table
function stats.mean( t )
  local sum = 0
  local count= 0

  for k,v in pairs(t) do
    if type(v) == 'number' then
      sum = sum + v
      count = count + 1
    end
  end

  return (sum / count)
end

-- Get the mode of a table.  Returns a table of values.
-- Works on anything (not just numbers).
function stats.mode( t )
  local counts={}

  for k, v in pairs( t ) do
    if counts[v] == nil then
      counts[v] = 1
    else
      counts[v] = counts[v] + 1
    end
  end

  local biggestCount = 0

  for k, v  in pairs( counts ) do
    if v > biggestCount then
      biggestCount = v
    end
  end

  local temp={}

  for k,v in pairs( counts ) do
    if v == biggestCount then
      table.insert( temp, k )
    end
  end

  return temp
end

-- Get the median of a table.
function stats.median( t )
  local temp={}

  -- deep copy table so that when we sort it, the original is unchanged
  -- also weed out any non numbers
  for k,v in pairs(t) do
    if type(v) == 'number' then
      table.insert( temp, v )
    end
  end

  table.sort( temp )

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp,2) == 0 then
    -- return mean value of middle two elements
    return ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
  else
    -- return middle element
    return temp[math.ceil(#temp/2)]
  end
end
    
-- Get the standard deviation of a table
function stats.standardDeviation( t )
  local m
  local vm
  local sum = 0
  local count = 0
  local result

  m = stats.mean( t )

  for k,v in pairs(t) do
    if type(v) == 'number' then
      vm = v - m
      sum = sum + (vm * vm)
      count = count + 1
    end
  end

  result = math.sqrt(sum / (count-1))

  return result
end

-- Get the max and min for a table
function stats.maxmin( t )
  local max = -math.huge
  local min = math.huge

  for k,v in pairs( t ) do
    if type(v) == 'number' then
      max = math.max( max, v )
      min = math.min( min, v )
    end
  end

  return max, min
end


--------------------------------------------------------------------------------
-- Useful Math functions

-- Rounding to a step value
function round_step(n, step)
  return math.floor((n/step) + 0.5)*step
end

-- Decimal rounding
function round(num) 
  if num >= 0 then return math.floor(num+.5) 
  else return math.ceil(num-.5) end
end

-- log2(x)
function log2(x) 
  return math.log(x) / math.log(2) 
end

-- Frequency to MIDI
function freq2midi(x)
  return 69+(12*log2(x/440))
end


--------------------------------------------------------------------------------
-- DSP Functions

-- Simple low pass filter
local function simple_lp(sample_data, cutoff)

  -- Function to mix two values a & b with a % weighting w (0-1, 0.5 is an equal mix)
  local function mix(a, b, w) 
    return (a*w)+(b*(1-w))
  end

  -- Filter the first sample position
  sample_data[1] = mix(sample_data[1], sample_data[#sample_data], cutoff) 

  -- Loop through remaining sample points and apply filter
  for n = 2, #sample_data do 
    sample_data[n] = mix(sample_data[n], sample_data[n-1], cutoff)
  end

  -- Return filtered data
  return sample_data

end

-- Correct DC Offset
local function dc_correct(sample_data)

  local xm1, ym1 = 0, 0
  local dc_sample_data = {}

  for n = 1, #sample_data do
    dc_sample_data[n] = sample_data[n] - xm1 + 0.995 * ym1
    xm1 = sample_data[n]
    ym1 = dc_sample_data[n]
  end
  
  return dc_sample_data

end

-- Pitch Detection - Return estimated frequency of sample data by counting
-- zero crossings and finding the most common (mode) or average (mean) period size
-- Takes the following arguments: sample_data, sample_rate, 
-- period_size (The number of zero crossing in a period), 
-- rounding (The number interval sizes are rounded to), method ("mode" or "mean")
local function wave_frequency(sample_data, sample_rate, period_size, rounding, method)

  local frequency = nil
          
  -- Store the positions of zero crossings
  local zero_positions = {}
  for n = 1, #sample_data-1 do
    if ((sample_data[n] >= 0) and (sample_data[n+1] <= 0)) or 
       ((sample_data[n] <= 0) and (sample_data[n+1] >= 0)) then 
       table.insert(zero_positions, n)
    end            
  end   

  -- Do the pitch detection
  if #zero_positions <= 1 then -- If it is a single cycle waveform or no zero crossings found

    period_size = 1
    frequency = sample_rate / #sample_data
    
  else

    if #zero_positions < period_size then -- If it is a very short sample then get period size from the sample
      period_size = #zero_positions - 1 
    end -- Otherwise it is a long sample
    
    local interval_sizes = {}

    -- Get all interval sizes between zero crossings
    for n = 1, #zero_positions-period_size do
      local interval_size = zero_positions[n+period_size] - zero_positions[n]
      interval_size = round_step(interval_size, rounding) -- Round it to the current rounding value
      table.insert(interval_sizes, interval_size)
    end  

    -- Choose an interval size
    local interval

    if method == "mode" then
      interval = stats.mode(interval_sizes)[1] -- Get the most common interval size
    elseif method == "mean" then
      interval = stats.mean(interval_sizes) -- Get the average interval size      
    end  

    frequency = sample_rate / interval

  end
  
  return frequency * (period_size/2) 

end


--------------------------------------------------------------------------------
-- Main tuning function called by tool menu/keybindings
local function easy_tune(mode)

  local ins = renoise.song().selected_instrument_index
  
  local start_sample = 1
  local end_sample = #renoise.song().instruments[ins].samples
  local completion_msg = "All samples in selected instrument have been tuned to C"

  if mode == "single" then 
    start_sample = renoise.song().selected_sample_index
    end_sample = start_sample   
    completion_msg = "Sample: "..renoise.song().instruments[ins].samples[start_sample].name.." has been tuned to C" 
  end
        
  -- Loop through all samples in instrument
  for s = start_sample, end_sample do

    -- Initialise variables
    local sample = renoise.song().instruments[ins].samples[s]
    local smp_buffer = sample.sample_buffer
    local channel = 1
    
    if smp_buffer.has_sample_data == false then
      renoise.app():show_status("No sample data found")
      break
    end

    local sel_start = smp_buffer.selection_start - 1
    local sel_end = smp_buffer.selection_end
    local size = sel_end - sel_start -- smp_buffer.number_of_frames 

    local sample_rate = smp_buffer.sample_rate
    local smp_data = {}
    
    local filter_poles = 2
    local filter_cutoff = 0.01
    
    local roundings = 4 -- The number of rounding values the pitch detect is tried with  
    local transposings = {} -- Table to store possible transpose values
    local finetunings = {} -- Table to store possible finetune values
    
        
    -- Read sample data into buffer
    for n = 1, size do
      smp_data[n] = smp_buffer:sample_data(channel, (sel_start+n))
    end

    -- Pre process sample to help frequency detection
    smp_data = dc_correct(smp_data)    
    for n = 1, filter_poles do
      smp_data = simple_lp(smp_data, filter_cutoff)
    end    
    smp_data = dc_correct(smp_data)    

    
    -- Step through the different rounding settings
    for r = 1, roundings do

      -- Do the frequency detection
      local frequency = wave_frequency(smp_data, sample_rate, 16, r, "mode")

      -- Calculate relevant transpose and finetune values
      local transpose, finetune = math.modf(freq2midi(frequency))

      -- Store them in a table
      transposings[r] = transpose%12
      finetunings[r] = math.floor(finetune*128 + 0.5)

    end
    
    -- Set the sample tunings
    sample.transpose = stats.mode(transposings)[1]*-1
    sample.fine_tune = stats.mode(finetunings)[1]*-1
    renoise.app():show_status(completion_msg)
  end

end


local function tune_all()
  easy_tune()
end

local function tune_selected()
  easy_tune("single")
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

--[[
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name,
  invoke = easy_tune  
}
--]]

renoise.tool():add_menu_entry {
  name = "Instrument Box:"..tool_name.." (All Samples)",
  invoke = tune_all
}

renoise.tool():add_menu_entry {
  name = "Sample Editor:"..tool_name.." (Selected Sample)",
  invoke = tune_selected
}

renoise.tool():add_menu_entry {
  name = "Sample Navigator:"..tool_name..":Selected Sample",
  invoke = tune_selected
}

renoise.tool():add_menu_entry {
  name = "Sample Navigator:"..tool_name..":All Samples",
  invoke = tune_all
}

--[[
renoise.tool():add_menu_entry {
  name = "Sample List:"..tool_name,
  invoke = easy_tune
}
--]]

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name,
  invoke = easy_tune
}

--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
