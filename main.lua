--[[============================================================================
main.lua
============================================================================]]--
--[[
1.2
-bugfix, was testing "read_only" before "has_sample_data" -> error when no sample data. (thanks, cocoa!)

1.1
-speed optimization: process meter resource hogging rectified.
-more status messages, user friendliness+

1.0
-process meter
-handles selections like other 'process'-menu items


prev versions
0.5
first version

--]]


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function phase_invert()
  local this_instrument = renoise.song().selected_instrument
  local this_sample = renoise.song().selected_sample
  local this_sambuffer = this_sample.sample_buffer

  if not this_sambuffer.has_sample_data then
    return false
  end
  
  if this_sambuffer.read_only then
    return false
  end

  local selection_is_made = (this_sambuffer.selection_start and this_sambuffer.selection_end)
  
  --prepare
  renoise.app():show_status(string.format("Phase inverting '%s' (Preparing...)" , this_sample.name))
  this_sambuffer:prepare_sample_data_changes()

  --go

  local ch_count = this_sambuffer.number_of_channels
  local fr_count = this_sambuffer.number_of_frames  
  local frame_start
  local frame_end
  local fr_count_process

  if selection_is_made then
    frame_start = this_sambuffer.selection_start
    frame_end = this_sambuffer.selection_end
    fr_count_process = frame_end - frame_start
  else
    frame_start = 1
    frame_end = fr_count
    fr_count_process = fr_count
  end

  local stat_update_interval = 1000
  local stat_update_counter = 0
 
  for channel_i = 1, ch_count do

    for frame_i = frame_start, frame_end do
  
      local original_data = this_sambuffer:sample_data(channel_i, frame_i)
      local inverted_data = original_data * -1         

      this_sambuffer:set_sample_data(channel_i, frame_i, inverted_data)
      
      stat_update_counter = stat_update_counter + 1

      if stat_update_counter == stat_update_interval then
        --process meter
        renoise.app():show_status(string.format("Phase inverting '%s' (%i%%)" ,
            this_sample.name,
            ((((channel_i-1)*fr_count_process)+(frame_i-(frame_start-1)))/(fr_count_process*ch_count)*100))
          )
        stat_update_counter = 0
      end

    end 
  
  end
  
  --finalize
  renoise.app():show_status(string.format("Phase inverting '%s' (Finalizing...)" , this_sample.name))
  this_sambuffer:finalize_sample_data_changes()

  --done
  renoise.app():show_status(string.format("Phase inverted '%s'", this_sample.name))

end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Phase Invert",
  invoke = phase_invert
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------


renoise.tool():add_keybinding {
  name = "Sample Editor:Process:Phase Invert",
  invoke = phase_invert
}
