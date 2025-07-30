-- scl to xrni v1.6 by Aftab Hussain aka afta8
-- Thanks and credits to dblue for the scl loading script - Source: http://forum.renoise.com/index.php?/topic/28495-snippet-load-scala-scl-tuning-file

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

-- For process slicing
require "process_slicer"


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Function to split a string.

-- Source: http://www.wellho.net/resources/ex.php4?item=u108/split

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

--------------------------------------------------------------------------------

-- Fucntion to extract a value from a string based on the given pattern.

function get_value(str, pattern)
  local first, last, value = string.find(str, pattern)
  return value
end

--------------------------------------------------------------------------------

-- Function to load a Scala .scl file and generate a table of note frequencies.
-- By Kieran Foster (aka dblue). January 26th, 2011.
-- Scala .scl file format: http://www.huygens-fokker.org/scala/scl_format.html

function scl_to_frequency_table(base_note, base_frequency, scl_filename)

  -- Table to hold converted tunings.
  local tunings = {}
  
  -- Counter to keep track of lines that actually have useful content.
  local lc = 0
  
  -- Attempt to open the .scl file for read access.
  local file = io.open(scl_filename, 'r')
  
  -- If we managed to open the file.
  if file then

    -- Iterate through each line.
    for line in file:lines() do
     
      -- If the current line is *not* a comment...
      if string.sub(line, 1, 1) ~= '!' then
      
        -- Increment line counter.
        lc = lc + 1
        
        -- According to the .scl file format, the first uncommented line we 
        -- encounter should be the description.
        if lc == 1 then
        
          -- You could store the description if you wanted to use it later.
          -- local scl_description = line
          
        -- The second uncommented line we encounter should be the note count.
        elseif lc == 2 then
          
          -- You could store the number of notes if you wanted to use it later.
          -- local scl_notes = tonumber(line)
          
        -- All other uncommented lines should be valid tunings. 
        else
                 
          -- If the tuning contains a period (.) then it's in cents. ex: 100.0
          if string.find(line, '.', 1, true) then
          
            -- Extract cents value from the line.
            local cents = tonumber(get_value(line, '(\-*%d+\.%d*)'))
          
            -- Convert.
            table.insert(tunings, math.pow(2, cents / 1200))
            
          -- If the tuning contains a forward slash (/) then it's a ratio. ex: 2/1
          elseif string.find(line, '/', 1, true) then
          
            -- Extract ratio value from the line.
            local ratio = get_value(line, '(\-*%d+/%d+)')
          
            -- Split the ratio into its component parts.
            local ratio_parts = string.split(line, '/')
            
            -- Convert.
            table.insert(tunings, tonumber(ratio_parts[1]) / tonumber(ratio_parts[2]))
            
          -- Otherwise, the tuning is probably a whole integer value. ex: 2
          else
          
            -- Extract value.
            local value = tonumber(get_value(line, '(\-*%d+)'))
          
            -- Convert.
            table.insert(tunings, value)
            
          end

        end
        
      end
      
    end
    
    -- Close the .scl file when we're finished with it.
    file:close()
    
  else
  
    -- If the .scl file could not be loaded for some reason
    -- then default to 12 tone equal temperament.
    for i = 1, 12, 1 do
      table.insert(tunings, math.pow(2, (i * 100) / 1200))
    end
  
  end
  
  -- Generate table containing all 128 MIDI note frequencies.

  local notes_per_octave = #tunings
  local note = 0
  local octave = 0
  local degree = 0
  local frequency = 0
  local frequencies = {}
  for midi_note = 0, 127, 1 do
    
    -- Calculate the shifted note index.
    note = midi_note - base_note
    
    -- Calculate the current degree.
    degree = note % notes_per_octave
    
    -- Calculate the current octave.
    octave = math.floor(note / notes_per_octave)
    
    -- Calculate the current octave's base frequency.
    frequency = base_frequency * math.pow(tunings[notes_per_octave], (octave * notes_per_octave) / notes_per_octave)
    
    -- Factor in the degree multiplier if necessary.
    if degree > 0 then
      frequency = frequency * tunings[degree]
    end
    
    -- Restrict frequency to some sensible limits.
    frequency = math.max(0.0, math.min(22050.0, frequency))  
    
    -- MIDI notes range from 0 to 127, so I prefer to index them in the same way. 
    -- If you prefer to index things LUA style, ie. from 1 to 128, then use:
    -- frequencies[midi_note + 1] = frequency
    frequencies[midi_note] = frequency
    
  end
  
  return frequencies
  
end

--------------------------------------------------------------------------------

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

-- Main function that loads a scl file and applies the relevant transpose and finetune values to currently selected instrument
local function apply_tunings()

  -- Instrument variables / setup   
  local ins = renoise.song().selected_instrument_index

  if renoise.song().instruments[ins].samples[1].sample_buffer.has_sample_data == true then -- Check if a sample is present
  
    local max_note = 119
    local existing_slices = #renoise.song().instruments[ins].samples[1].slice_markers
    local base_note = 48 -- Set the base note (tonic) of the scale to C-4 (passed to Scl Loader), change this to traspose the scale
    renoise.song().instruments[ins].samples[1].beat_sync_enabled = false -- Ensure beat sync is set to off


    -- Read the instruments basenote
    local instr_basenote = 48 -- Default value
    if existing_slices == 0 then -- If the instrument is not sliced then read its basenote 
      instr_basenote = renoise.song().instruments[ins].sample_mappings[renoise.Instrument.LAYER_NOTE_ON][1].base_note 
    end
    
  
    -- Check if tuning has already been run before, if 119 slices exist it assumes the tool has already been used
    local is_tuned = false -- Default value
    if existing_slices == max_note then
      is_tuned = true
      instr_basenote = renoise.song().instruments[ins].samples[1].beat_sync_lines -- If it has been tuned before then the basenote will have been stored already  
    end


    -- Set the transpose offset if the instr_base_note is not 48 (C-4)
    local transpose_offset = base_note - instr_basenote


    -- Select Scala file and generate table of frequencies
  
    -- Set the base frequency to Middle C
    local base_frequency = 261.625565300598623000

    -- Set the Scala .scl filename path
    local scl_filename = renoise.app():prompt_for_filename_to_read({"*.scl"}, "Select Scala File")

 
  
    if #scl_filename ~= 0 then -- Check if a file was selected
      
      -- Generate frequencies
      local frequencies = scl_to_frequency_table(base_note, base_frequency, scl_filename)


      -- Calculate equivalent Transpose and Finetune values from frequency table produced scl loader
      local transpose = {}
      local finetune = {}

      for n = 0, #frequencies, 1 do 
        transpose[n], finetune[n] = math.modf(12*(math.log10((frequencies[n]/base_frequency))/math.log10(2)))
        finetune[n] = math.floor(finetune[n]*128 + 0.5)
          if finetune[n] == 128 then -- If its 128 its the next note
            transpose[n] = transpose[n]+1
            finetune[n] = 0
          elseif finetune[n] == -128 then -- If its -128 its the next note
            transpose[n] = transpose[n]-1
            finetune[n] = 0
          end
        transpose[n] = transpose[n] + transpose_offset -- Adjust for instrument basenote
        transpose[n] = clamp_value(transpose[n], -120, 120)
      end



      -- Set up slice markers and apply tunings. Each slice has a unique frequency and finetune value
    
      if is_tuned == false then 

        renoise.song().instruments[ins].samples[1].beat_sync_lines = instr_basenote -- Stores the instruments basenote in beatsync lines

        renoise.app().window.active_middle_frame=3 -- Switch to keyzone view

        -- Delete any existing slices     
        for n = existing_slices, 1, -1 do
          renoise.song().instruments[ins].samples[1]:delete_slice_marker(renoise.song().instruments[ins].samples[1].slice_markers[n])
          renoise.app():show_status("Deleting slice "..n)
          coroutine.yield() -- Process slicing stuff
        end 

        -- Create new slices
        for n = 1, max_note, 1 do 
          renoise.song().instruments[ins].samples[1]:insert_slice_marker(1)
          renoise.app():show_status("Creating slice "..n)
          coroutine.yield() -- Process slicing stuff
        end
      
      end
  
  
  
      -- Apply calculated tunings to slices
      for n = 1, max_note+1, 1 do 
        renoise.song().instruments[ins].samples[n].transpose = transpose[n-1]
        renoise.song().instruments[ins].samples[n].fine_tune = finetune[n-1]
        renoise.app():show_status("Tuning slice "..n)
      end



      -- Append scl filename to Instrument name --
    
      -- Convert Windows path format  
      scl_filename = string.gsub(scl_filename, "\\", "/")
    
      -- Find position of first / from the end of the file path
      local slash_pos 

      for n = #scl_filename, 1, -1 do 
        if string.sub(scl_filename, n, n) == "/" then
          slash_pos = n
          break
        end
      end  

      -- Extract filename from the path
      local filename = (string.sub(scl_filename, slash_pos+1, #scl_filename))

      -- Get current instrument name
      local ins_name = renoise.song().instruments[ins].name

      -- Check for and remove any existing appended scl filenames
      local dot_pos = string.find(ins_name, ".scl")

      if dot_pos ~= nil then 

        local brace_pos

        -- Find position of first brace from dot_pos
        for n = dot_pos, 1, -1 do 
          if string.sub(ins_name, n, n) == "(" then
            brace_pos = n
            break
          end
        end  

        ins_name = (string.sub(ins_name, 1, brace_pos-2))

      end

      -- Append scl filename to instrument name
      renoise.song().instruments[ins].name = ins_name.." ("..filename..")"



      -- Update status bar with finishing message
      if is_tuned == false then
        renoise.app().window.active_middle_frame=4
        renoise.app():show_status(filename.." has been applied - Now go and disable the 'stop playing at start of next slice' option in the Sample Editor (cmd shift H)")
      else
        renoise.app():show_status(filename.." has been applied")
      end

              
    else
      renoise.app():show_status("No file selected")
    end

  
  else
  renoise.app():show_status("No sample data present - Load a sample first")
  end  

end


-- Function to preserve loop points
local function preserve_loops()

  local ins = renoise.song().selected_instrument_index

  if renoise.song().instruments[ins].samples[1].sample_buffer.has_sample_data == true then -- Check if a sample is present
  
    if #renoise.song().instruments[ins].samples ~= 1 then -- Check if tuning has been applied
  
      if renoise.song().instruments[ins].samples[2].sample_buffer.has_sample_data == true then -- Check if a sample in slot 2 is present
  
        local loop_mode = renoise.song().instruments[ins].samples[1].loop_mode
        local loop_start = renoise.song().instruments[ins].samples[1].loop_start
        local loop_end = renoise.song().instruments[ins].samples[1].loop_end
      
        if loop_mode ~= 1 then 
        
          for n = 2, (#renoise.song().instruments[ins].samples[1].slice_markers + 1), 1 do
            renoise.song().instruments[ins].samples[n].loop_mode = loop_mode
            renoise.song().instruments[ins].samples[n].loop_end = loop_end
            renoise.song().instruments[ins].samples[n].loop_start = loop_start
          end
      
          renoise.app():show_status("Loop points have been set on all slices")
      
        end

      else
        renoise.app().window.active_middle_frame=4
        renoise.app():show_status(" Loops cannot be set - You need to disable the 'stop playing at start of next slice' option in the Sample Editor first (cmd shift H)")
      end  

    else
    renoise.app():show_status("There is only one sample slice - Apply a tuning first")
    end  

  else
  renoise.app():show_status("No sample data present - Load a sample and apply a tuning first")
  end  

end


-- Wraps the main function into a process slicer
local function start()
  ProcessSlicer(apply_tunings):start()
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:scl to xrni:Apply Scala tuning...",
  invoke = start  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:scl to xrni:Preserve Loop Points...",
  invoke = preserve_loops  
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

if os.platform() ~= "MACINTOSH" then -- Running from keybinding in OSX crashes renoise

  renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.."...",
    invoke = start
  }

end

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.." - Preserve Loop Points...",
  invoke = preserve_loops
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
