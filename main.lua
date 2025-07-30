-- OP-1 export tool v1 - by afta8 (Aftab Hussain) - 20th Jan 2017
-- With help and additional code from 4Tey (Renoise Forum)
-- Aiff generating code from 'Additional File Formats' tool by mxb (Martin Bealby) - https://www.renoise.com/tools/additional-file-format-import-support
-- JSON library from http://dkolf.de/src/dkjson-lua.fsl/home

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
-- Includes
--------------------------------------------------------------------------------

-- JSON library taken from: http://dkolf.de/src/dkjson-lua.fsl/home
local json = require ("dkjson")


--------------------------------------------------------------------------------
-- mxb functions - Copyright 2011 Martin Bealby (mbealby@gmail.com)
--------------------------------------------------------------------------------

function hex_pack(string)
  local raw_string = string.char(tonumber(string:sub(1,2), 16))                    
  for i = 3, (string:len()-1), 2 do
    raw_string = raw_string .. string.char(tonumber(string:sub(i,i+1), 16))
  end
  return raw_string
end


function generate_aiff(channels, samplerate, bit_depth, audiodata, op1)
  -- writes a aiff file to a  user specified location with the supplied data
  local aiff_file = renoise.app():prompt_for_filename_to_write("aif", "Save file")
  local frames = audiodata:len() / (channels * (bit_depth / 8))
  local length = audiodata:len() + 27
    
  local f = io.open(aiff_file, "wb")
  
  -- Did we open the file successfully
  if f == nil then
    return false
  end

  -- main header
  f:write("FORM")
  f:write(hex_pack(string.format("%08X", length))) -- chunk size = file length - 8 
  f:write("AIFF")
  
  -- common chunk
  f:write("COMM") -- (4 bytes)
  f:write(hex_pack("00000012")) -- chunk size = 18 bytes
  f:write(string.char(00, channels))   -- channel count
  f:write(hex_pack(string.format("%08X", frames))) -- sample frames
  f:write(hex_pack(string.format("%04X", bit_depth))) -- bit depth)
  f:write(hex_pack("400E" .. string.format("%04X", samplerate) .. "000000000000"))  -- sample rate as 10 bit float hack


  -- Application chunk, section added by afta8 for OP1 metadata
  local appSig = "op-1" -- OP1 Application Signature
  local eol = hex_pack("0A") -- End of line terminator
  local chkLength = appSig:len()+op1:len()+eol:len()
  
  if (chkLength%2 ~= 0) then -- Check if length is an even number
     eol = hex_pack("000A") -- If not add an extra byte
     chkLength = appSig:len()+op1:len()+eol:len()
  end
  
  local ckSize = hex_pack(string.format("%08X", chkLength)) -- Size of data string in bytes
  
  f:write("APPL")  
  f:write(ckSize) 
  f:write(appSig) 
  f:write(op1) -- OP1 meta data 
  f:write(eol) 
  -- End of Application chunk for OP1


  -- sound data chunk
  f:write("SSND") -- (4 bytes)
  f:write(hex_pack(string.format("%08X", audiodata:len() + 16))) -- chunk size
  f:write(hex_pack("00000000"))   -- offset
  f:write(hex_pack("00000000"))   -- blocksize
  if channels == 1 then
    f:write(audiodata)
  elseif channels == 2 then
    local right_offset = frames * (bit_depth/8)
    for i = 1, frames, (bit_depth / 8) do  -- interleaved audio
      f:write(audiodata:sub(i, i + (bit_depth/8)))                               --left
      f:write(audiodata:sub(right_offset + i, right_offset + i + (bit_depth/8))) --right
    end
  end 
  
  f:flush()
  f:close()
  
   
  -- Status message
  renoise.app():show_status("Sample saved to: "..aiff_file)
   
end



--------------------------------------------------------------------------------
-- Slicing functions
--------------------------------------------------------------------------------

-- Slice selected sample or selected range into n number of equally spaced slices
local function create_slices(num_slices, slice_at_zero)

  -- Assign name to sample buffer
  local selected_sample = renoise.song().selected_sample
  local smp_buffer = selected_sample.sample_buffer

  -- Delete any existing slices  
  local existing_slices = #selected_sample.slice_markers 
  for n = existing_slices, 1, -1 do
    selected_sample:delete_slice_marker(selected_sample.slice_markers[n])
  end 

  -- Get the size of the sample
  local sample_size = smp_buffer.number_of_frames 
  
  -- Calculate size of each slice
  local slice_size = round(sample_size/num_slices)
  local slice_pos = 1 -- Sets position of first slice
  local fwd_zero_pos = 0 -- Stores nearest forward zero pos
  local bwd_zero_pos = 0 -- Stores nearest backward zero pos
  local closest_zero_pos = 0 -- Stores the closet zero pos


  -- Create slices
  if slice_at_zero == true then -- Check if zero crossing is selected
    
    --[[ Do slices at zero crossings ]]--

    -- Create slices on nearest zero crossing
    for n = 1, num_slices, 1 do   
        -- Find nearest zero crossing going forward on channel 1
        for z = slice_pos, (slice_pos + slice_size), 1 do
          if z <= (slice_pos + slice_size - 1) then
            if ((smp_buffer:sample_data(1, z) >= 0) and (smp_buffer:sample_data(1, z+1) <= 0)) or 
               ((smp_buffer:sample_data(1, z) <= 0) and (smp_buffer:sample_data(1, z+1) >= 0)) then 
               fwd_zero_pos = z+1
               break
            end            
          else         
            fwd_zero_pos = slice_pos -- If no zero crossing is found revert to original slice position            
          end                        
        end   
              
        -- Find nearest zero crossing going backward on channel 1
        for z = slice_pos, (slice_pos - slice_size + 1), -1 do        
          if z >= (slice_pos - slice_size + 1) and n > 1 then        
            if ((smp_buffer:sample_data(1, z) >= 0) and (smp_buffer:sample_data(1, z+1) <= 0)) or
               ((smp_buffer:sample_data(1, z) <= 0) and (smp_buffer:sample_data(1, z+1) >= 0)) then
               bwd_zero_pos = z+1
               break
            end            
          else            
            bwd_zero_pos = slice_pos -- If no zero crossing is found revert to original slice position            
          end            
        end
      
        -- Check which zero crossing is closest to starting position
        if (fwd_zero_pos - slice_pos) < (slice_pos - bwd_zero_pos) then
          closest_zero_pos = fwd_zero_pos
        else
          closest_zero_pos = bwd_zero_pos
        end
        
        -- Create slice at nearest zero crossing
        selected_sample:insert_slice_marker(closest_zero_pos)
        slice_pos = slice_size*n
        if slice_pos > sample_size then break end -- Relevant for small samples where rounding errors cause out of bounds
    end
  else
    --[[ Do slices not on zero crossings ]]-- 
    -- Create evenly spaced slices
    for n = 1, num_slices, 1 do 
        selected_sample:insert_slice_marker(slice_pos)
        slice_pos = slice_size*n
        if slice_pos > sample_size then break end -- For small samples where rounding errors cause out of bounds
    end
  end

end



--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

-- Clamp values
function clamp(input, min_val, max_val)
  return math.min(math.max(input, min_val), max_val)
end

-- Round to nearest integer
function round(x)
  return math.floor(x+0.5)
end


-- OP1 constants
local drumkit_end = 0x7FFFFFFE
local bytes_in_12secs = 44100*2*12
local sizeof_uint16_t = 2
local max_frames = 44100*12
local max_slices = 24

-- Get the OP1 sample positions based on provided table of sample frames, formula from: https://github.com/padenot/libop1/blob/master/src/op1_drum_impl.cpp
local function frame_to_op1(frame)
  local op1_pos = drumkit_end / bytes_in_12secs * frame * sizeof_uint16_t
  return round(op1_pos)
end


-- Get start positions for meta data
local function get_starts()
  local slices = renoise.song().selected_sample.slice_markers
  local num_slices = #slices
  local start_table = {}
  
  for n = 1, max_slices do
    if n > num_slices then -- If going past last slice 
      start_table[n] = frame_to_op1( clamp( slices[num_slices]-1, 0, max_frames ) )
    else  
      start_table[n] = frame_to_op1( clamp( slices[n]-1, 0, max_frames ) )
    end   
  end
  return start_table
end


-- Get end positions for meta data
local function get_ends()
  local slices = renoise.song().selected_sample.slice_markers
  local smp_size = renoise.song().selected_sample.sample_buffer.number_of_frames
  local num_slices = #slices
  local end_table = {}
  
  for n = 1, max_slices do
    if n < num_slices then 
      end_table[n] = frame_to_op1( clamp( slices[n+1]-2, 0, max_frames ) )
    else  
      end_table[n] = frame_to_op1( clamp( smp_size, 0, max_frames ) )  
    end        
  end
  return end_table
end


-- Create OP-1 meta data in JSON format
local function create_op1_metadata()

  local metadata = {}
    metadata["drum_version"] = 1
    metadata["type"] = "drum"
    metadata["name"] = "user"
    metadata["octave"] = 0
    metadata["pitch"] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    metadata["start"] = get_starts()
    metadata["end"] = get_ends()
    metadata["playmode"] = {8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192}
    metadata["reverse"] = {8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192}
    metadata["volume"] = {8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192,8192}
    metadata["dyna_env"] = {0,8192,0,8192,0,0,0,0}
    metadata["fx_active"] = false
    metadata["fx_type"] = "delay"
    metadata["fx_params"] = {8000,8000,8000,8000,8000,8000,8000,8000}
    metadata["lfo_active"] = false
    metadata["lfo_type"] = "tremolo"
    metadata["lfo_params"] = {16000,16000,16000,16000,0,0,0,0}  
  
  return json.encode(metadata)
end


-- Generate PCM sample data from float sample data
local function save_aiff()
  
  local sample_error_text = renoise.ViewBuilder():text { text = "There must be a sample selected to work on - Select a sample" } 
  local length_error_text = renoise.ViewBuilder():text { text = "Sample length must not exceed 12 seconds - Trim your sample" }
  local slices_error_text = renoise.ViewBuilder():text { text = "Tool only works on sliced samples - Create some slices" }
  local num_slices_error_text = renoise.ViewBuilder():text { text = "Number of slices cannot exceed "..max_slices.." - Delete some slices" }
  
  -- Check for a selected sample
  if renoise.song().selected_sample == nil then
    renoise.app():show_custom_prompt("Error", sample_error_text , {"OK"})
    return
  end
  
  -- Setup references  
  local smp_buffer = renoise.song().selected_sample.sample_buffer
  local nf = smp_buffer.number_of_frames
  local num_slices = #renoise.song().selected_sample.slice_markers
  local smp = {} -- Memory buffer for sample data
  
  -- Out of bounds checks  
  if nf > max_frames then -- Check sample is 12 seconds or less
    renoise.app():show_custom_prompt("Error", length_error_text , {"OK"})
    return
  elseif num_slices == 0 then
    renoise.app():show_custom_prompt("Error", slices_error_text , {"OK"})
    return
  elseif num_slices > max_slices then
    renoise.app():show_custom_prompt("Error", num_slices_error_text , {"OK"}) 
    return 
  end
    
  -- Status message
  renoise.app():show_status("Processing sample frames")
   
  -- Code by 4Tey for generating PCM data from left/mono channel
  local data = {}  
  local dptr = 1
  local SampNumber = nil
  for n=1,nf do
    
    SampNumber = smp_buffer:sample_data(1,n) 
    
    if SampNumber < 0 then
      SampNumber = 65536 - (SampNumber * -1) * 32768               
    else
      SampNumber = SampNumber * 32768
    end

    data[dptr] = string.char(bit.band(bit.rshift(SampNumber,8),0xff))
    print(data[dptr])
    dptr = dptr + 1
    data[dptr] = string.char(bit.band(SampNumber,0xff))
    dptr = dptr + 1
   
  end  
  
  -- Status message
  renoise.app():show_status("Sample frames processed")
  
  -- Call mxb's AIFF generating function
  generate_aiff(1,44100,16,table.concat(data),create_op1_metadata())  
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  
  
  -- Bring sample editor into focus
  renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  
  
  -- Settings
  local num_slices = 16
  local slice_at_zero = true


  -- Number of slices row
  local num_slices_row = vb:row {
    vb:text {
      width = 90,
      text = "Number of Slices"
      },
        
    vb:valuebox { 
      id = "numslices", 
      min = 1,
      max = 24,
      value = num_slices,
      tooltip = "Number of slices to be created (Range = 1 to 24)",
      notifier = function(value)
          num_slices = value
      end
    }
  }


  -- Slice at nearest zero crossing row
  local slice_at_zero_row = vb:row {
    vb:text {
      width = 132,
      text = "Slice at Zero Crossings"
    },
    
    vb:checkbox {
      id = "sliceatzero",
      value = true,
      tooltip = "If selected, slices are created at the nearest zero crossing",
      notifier = function(value)
        slice_at_zero = value
      end
    }
  }
  
  
  -- Slice button
  local slice_button = vb:button {
    text = "Slice",
    height = 36,
    width = 36,
    tooltip = "Create evenly spaced slices",
    notifier = function()
      if renoise.song().selected_sample then
        create_slices(num_slices, slice_at_zero)
      end
    end
  }      

  -- Container for slice controls
  local slice_controls_col =  vb:column {
    num_slices_row,
    slice_at_zero_row,
  }
  
  
  -- Container for slicing section
  local slice_section_row = vb:row {
    margin = 8,
    style = "group",
    slice_controls_col,
    slice_button
  }
  
  
  -- The content of the dialog, built with the ViewBuilder.
  local content = vb:column {
    margin = 8,
    spacing = 8,
    
    slice_section_row,
    
    vb:button {
      text = "EXPORT  OP-1  AIF",
      color = {0,70,70},
      height = 45,
      width = 202,
      
      notifier = function()
        save_aiff()  
      end
    }      
  }   
  
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content)  
   
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = show_dialog  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
