-- Slice My Pitch Up v0.6 - by Aftab Hussain aka afta8 - fathand@gmail.com

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

--------------
--NEW SLICES--
--------------

-- Function to slice a sample or selected range into n number of equally spaced slices
local function create_slices(ins, num_slices, slice_at_zero)

  -- Assign name to sample buffer
  local smp_buffer = renoise.song().instruments[ins].samples[1].sample_buffer

  -- Delete any existing slices  
  local existing_slices = #renoise.song().instruments[ins].samples[1].slice_markers 
  for n = existing_slices, 1, -1 do
      renoise.song().instruments[ins].samples[1]:delete_slice_marker(renoise.song().instruments[ins].samples[1].slice_markers[n])
  end 

  -- Get the size of the sample
  local sample_size = smp_buffer.number_of_frames 
  
  -- Calculate size of each slice
  local slice_size = math.floor(sample_size/num_slices)
  local slice_pos = slice_size -- Sets position of first slice
  local fwd_zero_pos = 0 -- Stores nearest forward zero pos
  local bwd_zero_pos = 0 -- Stores nearest backward zero pos
  local closest_zero_pos = 0 -- Stores the closet zero pos


  -- Create slices
  if slice_at_zero == true then -- Check if zero crossing is selected
    
    --[[ Do slices at zero crossings ]]--

    -- Create slices on nearest zero crossing
    for n = 1, (num_slices-1), 1 do   
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
          if z >= (slice_pos - slice_size + 1) then        
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
        renoise.song().instruments[ins].samples[1]:insert_slice_marker(closest_zero_pos)
        slice_pos = slice_size*(n+1)
        if slice_pos > sample_size then break end -- Relevant for small samples where rounding errors cause out of bounds
    end
  else
    --[[ Do slices not on zero crossings ]]-- 
    -- Create evenly spaced slices
    for n = 1, (num_slices-1), 1 do 
        renoise.song().instruments[ins].samples[1]:insert_slice_marker(slice_pos)
        slice_pos = slice_size*(n+1)
        if slice_pos > sample_size then break end -- For small samples where rounding errors cause out of bounds
    end
  end

  -- Set loop start & end point for first sample
  renoise.song().instruments[ins].samples[1].loop_start = 1
  renoise.song().instruments[ins].samples[1].loop_end = renoise.song().instruments[ins].samples[1].slice_markers[1] - 1

end



-----------
--TUNINGS--
-----------

-- Function to do tunings 
local function do_tunings(ins, init_tr, step_tr, reset_tr)

  -- Get number of slices
  local num_slices = #renoise.song().instruments[ins].samples[1].slice_markers + 1

  -- Set up tuning table
  local tuning_table = { } -- Stores the transpose values for all slices
  local tr_val = init_tr

  for s = 1, num_slices, reset_tr do
    for n = 1, reset_tr, 1 do
      tuning_table[n+s-1] = tr_val
      tr_val = tr_val + step_tr
    end
  tr_val = init_tr
  end

  -- Clamp tuning value to -120 to 120
  for n = 1, num_slices, 1 do
    if tuning_table[n] > 120 then
      tuning_table[n] = 120
    elseif tuning_table[n] < -120 then
      tuning_table[n] = -120
    end
  end

  -- Set slice tunings
  for n = 1, num_slices, 1 do
    renoise.song().instruments[ins].samples[n].transpose = tuning_table[n]
  end  

end



-------------
--CROSSFADE--
-------------

-- Function to do a crossfade on a selected sample 
local function do_crossfade(ins, sample, smp_start, loop_start, loop_end, xfade_mode) -- smp_start may need to be called with a +1

  -- Assign name to sample buffer
  local smp_buffer = renoise.song().instruments[ins].samples[sample].sample_buffer

  -- Get number of channels
  local num_channels = smp_buffer.number_of_channels 

  -- Calculate sample size
  --local sample_size = smp_end - smp_start
  local sample_size = loop_end - smp_start
   
  -- Calculate loop size as a percentage of sample size
  local crossfade_loop_size = ((loop_end - loop_start)/sample_size)*100

  -- Set up variables to track fade in and fade out start positions (frames)
  local fade_in_start_pos = nil
  local fade_out_start_pos = nil

  -- Set up variable to store size of area being processed (frames
  local process_area_size = nil
  
    
  -- Functions for doing the fades  
  -- Fade in function - Returns faded value for a given frame
  local function fade_in(frm, val, multiplier)    
    -- Equal power fade
    local pos = ((frm*multiplier)/100)
    local angle = 2*pos*(0.25*math.pi)    
    --[[ Equal power xfade
    val = math.sin(angle)*val --]]   
    -- Linear xfade
    val = val * ((frm*multiplier)/100)    
    return val
  end
  
  -- Fade out function - Returns faded value for a given frame  
  local function fade_out(frm, val, multiplier)
    -- Equal power fade
    local pos = ((frm*multiplier)/100)
    local angle = 2*pos*(0.25*math.pi)
    --[[ Equal power xfade
    val = math.cos(angle)*val --]]   
    -- Linear fade
    val = val * ((100-(frm*multiplier))/100)
    return val
  end  


  --[[ Sample processing ]]--
  local function process (channel)

    -- Sample data buffers
    local sample_data = { }
    local fade_in_sample_data = { }

    
    -- Set up buffers for relevant xfade mode
    if xfade_mode == 1 then -- If xfade loop mode is set to normal

      -- Set up fade in and out start positions and also size of processed area  
      if crossfade_loop_size <= 50 then
        -- Set fade in out positions if loop point is 50% or less of sample size
        process_area_size = loop_end - loop_start
        fade_in_start_pos = loop_start - process_area_size + 1
        fade_out_start_pos = loop_start                
      else
        -- Fade in out positions if loop point is more than 50% of sample size
        process_area_size = loop_start - smp_start
        fade_in_start_pos = smp_start
        fade_out_start_pos = loop_end - process_area_size                  
      end
    
      -- Read channel into buffers
      for n = smp_start, loop_end, 1 do
        sample_data[n] = smp_buffer:sample_data(channel, n)
      end

      for n = smp_start, loop_end, 1 do
        fade_in_sample_data[n] = smp_buffer:sample_data(channel, n)
      end

    elseif xfade_mode == 2 then -- If xfade loop mode is set to backward

      -- Set up fade in and out start positions and also size of processed area  
      process_area_size = loop_end - loop_start
      fade_in_start_pos = loop_start
      fade_out_start_pos = loop_start                    
    
      -- Read channel into buffers
      for n = smp_start, loop_end, 1 do
        sample_data[n] = smp_buffer:sample_data(channel, n)
      end

      local z = loop_start
      for n = loop_end, loop_start, -1 do
        fade_in_sample_data[z] = smp_buffer:sample_data(channel, n)
        z = z + 1
      end

    end

    -- % volume scale 
    local multiplier = 100/process_area_size -- Sets the multiplier for the fade rate

          
    -- Set up process counter
    local proc_count = nil


    if xfade_mode == 1 then
      -- Do fade in processing
      proc_count = 1
      for n = fade_in_start_pos, loop_start, 1 do
        fade_in_sample_data[n] = fade_in(proc_count, fade_in_sample_data[n], multiplier)
        proc_count = proc_count + 1
      end
    elseif xfade_mode == 2 then
      -- Do fade in processing
      proc_count = 1
      for n = fade_in_start_pos, loop_end, 1 do
        fade_in_sample_data[n] = fade_in(proc_count, fade_in_sample_data[n], multiplier)
        proc_count = proc_count + 1
      end
    end

    -- Do fade out processing 
    proc_count = 1
    for n = fade_out_start_pos, loop_end, 1 do
      sample_data[n] = fade_out(proc_count, sample_data[n], multiplier)
      proc_count = proc_count + 1
    end
    
    -- Create crossfaded sample data
    local a = nil
    local b = nil
    proc_count = fade_in_start_pos
    for n = fade_out_start_pos, loop_end, 1 do
      a = sample_data[n]
      b = fade_in_sample_data[proc_count]
      sample_data[n] = a + b
      proc_count = proc_count + 1
    end
  
    -- Writing to sample buffer
    for n = fade_out_start_pos, loop_end, 1 do
      smp_buffer:set_sample_data(channel, n, sample_data[n])
    end
    
  end

  -- Process audio channels
  if num_channels > 1 then
    process(1)
    process(2)
  else
    process(1)  
  end

end



-----------
--LOOPING--
-----------

-- Function to do loopings on all slices 
local function do_looping(ins, loop_size, loop_mode, crossfade_loop, xfade_type)

  -- Assign name to sample buffer
  local smp_buffer = renoise.song().instruments[ins].samples[1].sample_buffer

   -- Get the size of the sample
  local sample_size = smp_buffer.number_of_frames 

  -- Get number of slices
  local existing_slices = #renoise.song().instruments[ins].samples[1].slice_markers 

  -- Cross fade slider input from GUI
  local loop_start = loop_size/100 -- Percentage of sample used for loop start position


  -- Set up table of slice markers
  local slice_markers_table = { }

  for n = 1, existing_slices, 1 do
    slice_markers_table[n] = renoise.song().instruments[ins].samples[1].slice_markers[n] - 1  
  end
  table.insert(slice_markers_table,1,1) -- Set sample start for first slice
  table.insert(slice_markers_table,(#slice_markers_table+1),sample_size) -- Sets frame number for end of last slice


  -- Prepare sample for maniuplations
  smp_buffer:prepare_sample_data_changes()
  
  -- For loop to step through slices
  for slice = 1, (existing_slices + 1), 1 do
  
    -- Get the size of the current slice (frames)
    local current_slice_size = slice_markers_table[slice+1] - slice_markers_table[slice]
  
    -- Get absolute loop start position (frames)
    local loop_start_position = (math.floor((current_slice_size*loop_start)+0.5)) + slice_markers_table[slice]

    -- Get absolute segment end position (frames)
    local slice_end_pos = slice_markers_table[slice+1]

    -- Set sample loop points
    renoise.song().instruments[ins].samples[slice].loop_start = (math.floor((current_slice_size*loop_start)+0.5)) --+1
    if current_slice_size ~= 0 then
      renoise.song().instruments[ins].samples[slice].loop_end = current_slice_size  
    end
    
    -- Set loop mode  
    renoise.song().instruments[ins].samples[slice].loop_mode = loop_mode

    --Do crossfade
    if crossfade_loop == true then
      do_crossfade(ins, 1, slice_markers_table[slice], loop_start_position, slice_end_pos, xfade_type)    
    end
       
  end

  -- Finalise sample data
  smp_buffer:finalize_sample_data_changes()

end


--------
--MAIN--
--------

local function slicemypitchup(num_slices, slice_at_zero, crossfade_loop, crossfade_loop_size, init_tr, step_tr, reset_tr, loop_state, xfade_type, slice_on, pitch_on, loop_on)

  -- Identify currenty selected sample
  local ins = renoise.song().selected_instrument_index

  if slice_on == true then 
    create_slices(ins, num_slices, slice_at_zero)
  end
  
  if pitch_on == true then 
    do_tunings(ins, init_tr, step_tr, reset_tr)
  end
  
  if loop_on == true then 
    do_looping(ins, crossfade_loop_size, loop_state, crossfade_loop, xfade_type)
  end
  
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
  

  -- Declare variables
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN

  -- Default settings
  local num_slices = 24 -- The total number of slices (1 to 120) to make in the sample range
  local slice_at_zero = true -- If it should slice at the nearest zero crossing
  local crossfade_loop = false
  local crossfade_loop_size = 50
  local xfade_type = 1

  local init_tr = 0 -- The starting transpose value (Range is -120 to 120)
  local step_tr = 1 -- The number of steps the transpose value should increment for each slice (Range is 1 to 12)
  local reset_tr = 12 -- The number of slices after which the transpose resets back to the init_tr (use multiples of 12 to remain musical)

  local loop_state = 4 -- The loop mode
  
  -- Module on/off switches
  local slice_on = true
  local pitch_on = true
  local loop_on = true
  
  
  -- Slice on/off row
  local slice_toggle_row = vb:row {

    vb:text {
      width = 162,
      font = "big",
      text = "Slice"
      },

    vb:checkbox { 
      id = "sliceonoff", 
      value = true,
      tooltip = "Activate or Bypass Slicing",
      notifier = function(value)
        vb.views.slicepanel.visible = not vb.views.slicepanel.visible
        slice_on = value
      end
    }
            
  }    
    
  -- Number of slices row
  local num_slices_row = vb:row {
    vb:text {
      width = 110,
      text = "Number of Slices"
      },
        
    vb:valuebox { 
      id = "numslices", 
      min = 2,
      max = 120,
      value = num_slices,
      tooltip = "Number of slices to be created (Range = 2 to 120)",
      notifier = function(value)
          num_slices = value
      end
    }
  }    

  -- Slice at nearest zero crossing row
  local slice_at_zero_row = vb:row {
    vb:text {
      width = 151,
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


  -- Pitch on/off row
  local pitch_toggle_row = vb:row {

    vb:text {
      width = 162,
      font = "big",
      text = "Pitch"
      },

    vb:checkbox { 
      id = "pitchonoff", 
      value = true,
      tooltip = "Activate or Bypass Transposing",
      notifier = function(value)
        vb.views.pitchpanel.visible = not vb.views.pitchpanel.visible
        pitch_on = value
      end
    }
            
  }    


  -- Initial transpose row
  local initial_transpose_row = vb:row {
    vb:text {
      width = 110,
      text = "Initial Transpose"
      },
        
    vb:valuebox { 
      id = "inittranspose", 
      min = -120,
      max = 120,
      value = init_tr,
      tooltip = "The transpose value of the first slice, subsequent slices are offset from this (Range = -120 to +120)",
      notifier = function(value)
          init_tr = value
      end
    }
  } 


  -- Transpose increment Row
  local transpose_increment_row = vb:row {
    vb:text {
      width = 110,
      text = "Transpose Increment"
      },
    
    vb:valuebox {
      id = "transposeincrement",
        min = -12,
        max = 12,
        value = step_tr,
        tooltip = "The amount each slice is incremented from the initial transpose value (Range = -12 to +12)",
        notifier = function(value)
            step_tr = value  
        end
        }
   }


  -- Transpose reset Row
  local transpose_reset_row = vb:row {
    vb:text {
      width = 110,
      text = "Transpose Reset"
      },
    
    vb:valuebox {
      id = "transposereset",
        min = 2,
        max = 120,
        value = reset_tr,
        tooltip = "The number of slices after which the transpose is reset to the initial transpose value (Range = 2 to 120)",
        notifier = function(value)
            reset_tr = value    
        end
        }
   }
   


  -- Loop on/off row
  local loop_toggle_row = vb:row {

    vb:text {
      width = 162,
      font = "big",
      text = "Loop"
      },

    vb:checkbox { 
      id = "looponoff", 
      value = true,
      tooltip = "Activate or Bypass Looping",
      notifier = function(value)
        vb.views.looppanel.visible = not vb.views.looppanel.visible
        loop_on = value
      end
    }
            
  }    

   
  -- Crossfade loop size
  local crossfade_loop_size_row = vb:row {
    
    vb:minislider {
      id = "crossfadeloopsize",
      active = true,
      width = 170,
      height = 20,
      min = 1,
      max = 100,
      value = 50,
      tooltip = "The start position of the loop",
      notifier = function(value)
        crossfade_loop_size = value
      end
    }
  }


  -- Loop mode row
  local loop_mode_row = vb:row {
    vb:text {
      width = 100,
      text = "Loop Mode"
      },
    
    vb:popup {
      id = "loopmode", 
        width = 70,
        value = loop_state,
        items = {"Off", "Forward", "Backward", "PingPong"}, 
        tooltip = "The loop mode for each slice",
        notifier = function(value)
          loop_state = value
        end
        }
   }


  -- Crossfade loop is on
  local crossfade_loop_row = vb:row {
    vb:text {
      width = 151,
      text = "Crossfade Loop all Slices"
    },
    
    vb:checkbox {
      id = "crossfadeloop",
      value = false,
      tooltip = "If selected, slices are crossfade looped",
      notifier = function(value)
        crossfade_loop = value
        
        -- Set the loop mode
        if crossfade_loop == true then
          vb.views["loopmode"].value = 2 -- Sets loop to forward
        end
        
        vb.views["xfadetype"].active = value
                  
      end
    }
  }


  -- Xfade type row
  local xfade_type_row = vb:row {
    vb:text {
      width = 100,
      text = "Crossfade Type"
      },
    
    vb:popup {
      id = "xfadetype", 
        active = false,
        width = 70, 
        value = 1,
        items = {"Normal", "Reverse"}, 
        tooltip = "The type of crossfade",
        notifier = function(value)
          xfade_type = value
        end
        }
   }


  -- Slice it button
  local slice_it_button_row = vb:horizontal_aligner {
    mode = "center",
    
    vb:button {
      text = "Process",
      height = 25,
      width = 55,
      
      notifier = function()
          slicemypitchup(num_slices, slice_at_zero, crossfade_loop, crossfade_loop_size, init_tr, step_tr, reset_tr, loop_state, xfade_type, slice_on, pitch_on, loop_on)
      end
    }        
  } 


-- Setting up the GUI layout
  local content = vb:column {
    margin = DIALOG_MARGIN/1.5,
    spacing = CONTENT_SPACING,
    
    vb:column{
      spacing = 2*CONTENT_SPACING,

      vb:column {
        spacing = CONTENT_SPACING,
        style = "group",
        margin = DIALOG_MARGIN/1.5,
        
        slice_toggle_row,
        --vb:space { height = 1 },


        vb:column {
          id = "slicepanel",
          margin = DIALOG_MARGIN/1.5,
          spacing = CONTENT_SPACING,
          style = "border",

          num_slices_row,
          slice_at_zero_row,
        }       

      },

        
      vb:column {
        spacing = CONTENT_SPACING,
        style = "group",
        margin = DIALOG_MARGIN/1.5,  
        
        pitch_toggle_row,
        --vb:space { height = 1 },
        
        vb:column {
          id = "pitchpanel",
          margin = DIALOG_MARGIN/1.5,
          spacing = CONTENT_SPACING,
          style = "border",

          initial_transpose_row,
          transpose_increment_row,
          transpose_reset_row 
        }  
           
      },

      
      vb:column {
        spacing = CONTENT_SPACING,
        style = "group",
        margin = DIALOG_MARGIN/1.5,
        
        loop_toggle_row,
        --vb:space { height = 1 },
        
 
        vb:column {
          id = "looppanel",
          margin = DIALOG_MARGIN/1.5,
          spacing = CONTENT_SPACING,
          style = "border",

          crossfade_loop_size_row,
          loop_mode_row,
          crossfade_loop_row,
          xfade_type_row
        }
        
      },
        
      slice_it_button_row
      
    }  
  }    


  -- Key passthrough function
  local function keyhandler(dialog, key)
    return key
  end

      
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content, keyhandler)  
  
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

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
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
