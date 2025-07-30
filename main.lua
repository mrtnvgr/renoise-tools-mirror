-- Slices to Midi v0.21 by Aftab Hussain aka afta8 | fathand@gmail.com

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



-----------------------------------------------------------------------------------------------
-- Code from Easy Tune - http://forum.renoise.com/index.php?/topic/37402-new-tool-28-easy-tune/
-----------------------------------------------------------------------------------------------

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


-- Useful Math functions

-- Rounding to a step value
function round_step(n, step)
  return math.floor((n/step) + 0.5)*step
end

-- Decimal rounding
function round(num) 
  if num >= 0 then return math.floor(num+0.5) 
  else return math.ceil(num-0.5) end
end

-- log2(x)
function log2(x) 
  return math.log(x) / math.log(2) 
end

-- Frequency to MIDI
function freq2midi(x)
  return 69+(12*log2(x/440))
end

-- Function to clamp values
function clamp_value(input, min_val, max_val)
  if input < min_val then
    input = min_val
  elseif input > max_val then
    input = max_val
  end
  return input
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


-- Function to return RMS volume
local function rms_volume(sample_data)

  local x = 0

  for n = 1, #sample_data do
    x = x + sample_data[n]^2
  end
  
  return math.sqrt(x/#sample_data)
  
end


-- Function to return Peak volume
local function peak_volume(sample_data)

  local peak = 0

  for k,v in pairs(sample_data) do
      peak = math.max( peak, math.abs(v) ) 
  end

  return peak
  
end



--------------------------------------------------------------------------------

-- Main tuning function
local function easy_tune(filter, volume_mode)

  local ins = renoise.song().selected_instrument_index
  local note_values = {}
  local note_volumes = {}
  
  -- Loop through all samples in instrument
  for s = 1, #renoise.song().instruments[ins].samples do

    local sample = renoise.song().instruments[ins].samples[s]
    local smp_buffer = sample.sample_buffer
    local channel = 1
    
    if smp_buffer.has_sample_data == false then
      break
    end

    local size = smp_buffer.number_of_frames 
    local sample_rate = smp_buffer.sample_rate
    local smp_data = {}
    

    -- Read sample data into buffer
    for n = 1, size do
      smp_data[n] = smp_buffer:sample_data(channel, n)
    end

    -- Correct DC Offset
    smp_data = dc_correct(smp_data)

    -- Store note volume
    if s > 1 then -- If its not the first sample 
      if volume_mode == 1 then 
        table.insert(note_volumes, rms_volume(smp_data))
      elseif volume_mode == 2 then
        table.insert(note_volumes, peak_volume(smp_data))
      end
    end
 
    -- Apply a low pass filter
    smp_data = simple_lp(smp_data, filter)
    smp_data = simple_lp(smp_data, filter)
    
    -- Correct DC Offset
    smp_data = dc_correct(smp_data)    

    -- Store the positions of zero crossings
    local zero_positions = {}
    for n = 1, size-1 do
      if ((smp_data[n] >= 0) and (smp_data[n+1] <= 0)) or 
         ((smp_data[n] <= 0) and (smp_data[n+1] >= 0)) then 
         table.insert(zero_positions, n)
      end            
    end   

    -- Variables for pitch detection
    local period_size = 16 -- The number of zero crossing in a period
    local roundings = 4 -- The max rounding value intervals are rounded to  
    local transpose, finetune
    local transposings = {} -- Table to store possible transpose values
    local finetunings = {} -- Table to store possible finetune values

    -- Variables for final tuning settings
    local mode_transpose = {}
    local mode_finetune = {}


    -- Do the pitch detection
    if #zero_positions == 1 then -- If it is a single cycle waveform

      local frequency = sample_rate / size
      transpose, finetune = math.modf(freq2midi(frequency))
      mode_transpose[1] = transpose%12
      mode_finetune[1] = math.floor(finetune*128 + 0.5)

    else

      if #zero_positions < period_size then -- If it is a very short sample then get period size from the sample
        period_size = #zero_positions - 1 
      end -- Otherwise it is a long sample
    
      -- Step through all the different rounding settings
      for r = 1, roundings do

        local interval_sizes = {}

        -- Get all interval sizes between zero crossings
        for n = 1, #zero_positions-period_size, 1 do
          local interval_size = zero_positions[n+period_size] - zero_positions[n]
          interval_size = round_step(interval_size, r) -- Round it to the current rounding value
          table.insert(interval_sizes, interval_size)
        end  

        -- Get the mode of intervals (most common interval size)
        local mode_interval = stats.mode(interval_sizes)
        if mode_interval[1] == nil then -- If mode is not found, usually if sample is noise
          mode_interval[1] = 100
        end
      
        -- Calculate the frequency of the mode interval
        local frequency = sample_rate / mode_interval[1]
        
  
        -- Calculate relevant transpose and finetune values
        transpose, finetune = math.modf(freq2midi(frequency))
        --transpose = transpose%12
        finetune = math.floor(finetune*128 + 0.5)

        -- Store them in a table
        transposings[r] = transpose
        finetunings[r] = finetune 

      end

      -- Get mode of all possible transpose and finetune settings
      mode_transpose = stats.mode(transposings)
      mode_finetune = stats.mode(finetunings)
      if mode_finetune[1] > 100 then 
        mode_transpose[1] = mode_transpose[1] + 1
      elseif mode_finetune[1] < -100 then
        mode_transpose[1] = mode_transpose[1] - 1
      end
  
    end  
    
    -- Store the note value
    table.insert(note_values, mode_transpose[1]+36)
  
  end

  return note_values, note_volumes

end



--------------------------------------------------------------------------------------------------------------------------
-- Code from dblue's Slices to Pattern - http://forum.renoise.com/index.php?/topic/29145-new-tool-27-28-slices-to-pattern/
--------------------------------------------------------------------------------------------------------------------------

--[[function round(value)
  return math.floor(value + 0.5)
end --]]

local function clear_lines(pattern_track, from, to)
  for i = from, to, 1 do
    pattern_track:line(i):clear()
  end
end

local function process(filter, dest_ins, volume_detect, volume_mode) -- Args added for Slices to MIDI GUI

  local rs = renoise.song()
  
  
  -- ADDED FOR SLICES TO MIDI 
  local note_values, note_volumes = easy_tune(filter, volume_mode)
  -- ADDED FOR SLICES TO MIDI 

  
  
  if (rs.tracks[rs.selected_track_index].type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then
    -- Track isn't a sequencer track
    renoise.app():show_status(tool_name .. ': Selected track is not a sequencer track. Cannot insert slices.')
    return false
  end
  
  local instrument = rs.selected_instrument
  local samples = instrument.samples
  local num_samples = #samples
  
  if (num_samples < 2) then
    -- Nothing to do!
    renoise.app():show_status(tool_name .. ': Selected instrument does not contain any slices.')
    return false
  end
  
  local num_slices = #samples[1].slice_markers

  if (num_slices < 1) then
    -- Nothing to do!
    renoise.app():show_status(tool_name .. ': Selected instrument does not contain any slices.')
    return false
  end
  
  local sample_frames = samples[1].sample_buffer.number_of_frames
  local sample_lines = samples[1].beat_sync_lines
  local frames_per_line = sample_frames / sample_lines
  
  local track = rs.selected_track
  local pattern = rs.selected_pattern
  local pattern_track = rs.selected_pattern_track
  local pattern_lines = pattern.number_of_lines
  
  local first_line = rs.transport.edit_pos.line
  local last_line = math.min((first_line + sample_lines) - 1, pattern_lines)
  
  -- Clear old note data
  clear_lines(pattern_track, first_line, last_line)
  
  -- Show the delay column
  track.delay_column_visible = true
  
  -- Process slices    
  local note_instrument = rs.selected_instrument_index - 1
  local note_panning = 255
  --local note_volume = 255
        
   
  -- Generate notes
  local line = 0
  local frame = 0

  for i = 1, num_slices, 1 do
  
    local slice_frames = samples[i+1].sample_buffer.number_of_frames
    local slice_lines = slice_frames / frames_per_line
    
    -- Generate note
    local offset = math.floor(line)
    local delay = math.floor((line - offset) * 256)
    local pattern_line = first_line + offset
    
    if (pattern_line > pattern_lines) then
      -- Exceeded pattern length
      renoise.app():show_status(tool_name .. ': Reached end of pattern. Cannot insert any more slices.')
      break
    end
    
    local column = 1
    local note = pattern_track:line(pattern_line).note_columns[column]
    while (not note.is_empty) and (note.note_value < 120) and (column < 13) do
      column = column + 1
      if (column > 12) then
        renoise.app():show_status(tool_name .. ': Reached maximum number of note columns. Some slices could not be inserted.')
      else
        note = pattern_track:line(pattern_line).note_columns[column]
      end
    end

    --note.instrument_value = note_instrument dest_ins
    --note.note_value = instrument:sample_mapping(1, i+1).note_range[1]
    
    

    
    -- ADDED FOR SLICES TO MIDI 
    note.instrument_value = dest_ins
    note.note_value = clamp_value(note_values[i+1], 0, 119)
    
    
    if volume_detect == true then
      local max_volume = stats.maxmin(note_volumes)
      note.volume_value = (note_volumes[i]/max_volume)*128     
    else
      note.volume_value = 255
    end
    -- ADDED FOR SLICES TO MIDI 




    -- note.volume_value = note_volume
    note.panning_value = note_panning
    note.delay_value = delay
    
    if (track.visible_note_columns < column) then
      track.visible_note_columns = math.min(12, column)
    end
    
    -- Increment
    line = line + slice_lines    
  end

end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  
  
  -- Declare variables
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  
  local filter_cutoff = 0.01
  local selected_ins = 1
  local volume = true
  local volume_mode = 1
  
  -- Populate instrument list drop down list
  local ins_list = {}
  for n = 1, #renoise.song().instruments do
      ins_list[n] = string.upper(string.format("%02x", (n-1)))
  end
 
  -- Filter row
  local filter_row = vb:row {
    vb:text {
      width = 105,
      text = "Filter (0.001 to 0.5):"
      },
    
    vb:valuebox {
      id = "filter", -- Sets the ID
        min = 1,
        max = 500,
        value = filter_cutoff*1000,
        width = 65,
        
        tostring = function(value) 
          return (tostring(tonumber(value)/1000))
        end,
        tonumber = function(str) 
          return tonumber(str)*1000
        end,        
        
        notifier = function(value)
          filter_cutoff = value / 1000
        end
        }
   }


  -- Destination Instrument Row
  local dest_ins_row = vb:row {
    vb:text {
      width = 125,
      text = "Destination Instrument:"
      },
    
    vb:popup {
      id = "dest_ins", -- Sets the ID
        width = 45,
        value = 1,
        items = ins_list, -- Populates the drop down list
        notifier = function(popup_value)
          selected_ins = popup_value - 1 -- Updates selected instrument
          end
        }
   }


  -- Volume Row
  local volume_row = vb:row {
    vb:text {
      text = "Volume:"
      },
    
    vb:checkbox {
      id = "volume", -- Sets the ID
      value = true,
      notifier = function(value)
        volume = value
        vb.views["volume_mode"].active = value
      end
      },
    
    vb:space { width = 4 },
    
    vb:text {
      text = "Detection:"
      },
          
    vb:popup {
      id = "volume_mode", -- Sets the ID
      width = 50,
      value = 1,
      items = {"RMS", "Peak"},
      notifier = function(popup_value)
        volume_mode = popup_value
      end
      }  
            
   }


  -- Process button
  local process_row = vb:horizontal_aligner {
    mode = "center",
    
    vb:button {
      text = "Process",
      height = 1.2*DEFAULT_DIALOG_BUTTON_HEIGHT,
      
      notifier = function()
          process(filter_cutoff, selected_ins, volume, volume_mode)          
      end
    }        
  } 
 
  -- Setting up the GUI layout
  local content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:row{
      spacing = 4*CONTENT_SPACING,

      vb:column {
        spacing = CONTENT_SPACING,
        
        filter_row,
        dest_ins_row,
        volume_row,
        
        vb:space { height = 6 },
        
        process_row        
      }
    }
  } 

  -- Key passthrough function
  local function keyhandler(dialog, key)
    return key
  end

  -- Displays a custom dialog, user designed layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content, keyhandler)  
 
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Slices To Midi...",
  invoke = function()
    show_dialog()
  end
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Pattern:Slices To Midi",
  invoke = function()
    show_dialog()
  end
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern:Slices To Midi",
  invoke = function()
    show_dialog()
  end
}

