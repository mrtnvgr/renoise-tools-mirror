--[[============================================================================
Split into separate Tracks

Author: Florian Krause <siebenhundertzehn@gmail.com>
Added: Velocity/volume splitting (vV)
Version: 1.3
============================================================================]]--

column_split = 1
note_split = 2
instrument_split = 3
velocity_split = 4

-- Register the tool
renoise.tool():add_menu_entry{
  name = 'Pattern Editor:Track:Split into separate Tracks...',
  invoke = function() gui() end
}
  
-- Add key bindings
renoise.tool():add_keybinding{
  name = "Pattern Editor:Track Operations:Split into separate Tracks",
  invoke = function() gui() end
}

function split(what, implicit_off, copy_prefxvol, copy_prefxpan,
               copy_prefxwidth, copy_postfxvol, copy_postfxpan,
               copy_outputdelay, copy_outputrouting, copy_devices,
               copy_automation, copy_effects, group_tracks, selection_only,
               delete_original)
  
  renoise.app():show_status("Splitting...")
  
  -- Define some constants
  local EMPTY_PANNING = renoise.PatternTrackLine.EMPTY_PANNING
  local EMPTY_VOLUME = renoise.PatternTrackLine.EMPTY_VOLUME
  local EMPTY_NOTE = renoise.PatternTrackLine.EMPTY_NOTE
  local NOTE_OFF = renoise.PatternTrackLine.NOTE_OFF

  -- Define some locals
  local current_song = renoise.song()
  local track = current_song.selected_track_index
  local visible_note_columns = current_song.tracks[track].visible_note_columns
  local visible_effect_columns = current_song.tracks[track].visible_effect_columns
  local nr_lines = 0
  local nr_columns = 0
  local notes = table.create()
  local cache = table.create()

  current_song:describe_undo('Split into separate Tracks')
  
  -- Check how many lines and columns to process
  if selection_only == true then
    local line_start, line_end
    local iter = current_song.pattern_iterator:lines_in_pattern(current_song.selected_pattern_index)  
    for pos,line in iter do
      for _,note_column in ipairs(line.note_columns) do
        if note_column.is_selected then
          line_start = line_start or pos.line
          line_end = line_end and math.max(line_end, pos.line) or pos.line
          nr_columns = nr_columns + 1
        end
      end
    end
    nr_lines = line_end - line_start + 1
  
  else
    for p,_ in ipairs(current_song.patterns) do
      local lines = current_song.patterns[p].tracks[track].lines
      for l,_ in ipairs(lines) do
        nr_lines = nr_lines + 1
      end
    end
    nr_columns = nr_lines * visible_note_columns
  end
  
  local step = 1
  
  -- Loop over note columns
  for pos,column in current_song.pattern_iterator:note_columns_in_track(track, true) do

    -- Check what to process, whole track or just selection
    local process = false
    if selection_only == true and column.is_selected == true then
      process = true
    elseif selection_only == false then
      process = true
    end
    
    -- If note column should be processed
    if process == true then 
    
      -- Update status
      local full
      if copy_effects == true then
        full = 50
      else
        full = 100
      end
      renoise.app():show_status(string.format("Splitting... (%d%%)", 
                                (step/nr_columns)*full))
      step = step + 1
      
      local what_value, note_pos
      local off_pos, off_item, off_line

      -- If note column is not empty
      if column.is_empty == false then
      --if column.note_value ~= EMPTY_NOTE then
      
        -- If note value is not a note-off
        if column.note_value ~= NOTE_OFF and column.note_value ~= EMPTY_NOTE then
        
          -- Check what value to look at, note value or instrument value
          if what == note_split then
            what_value = column.note_value
          elseif what == instrument_split then
            what_value = column.instrument_value
          elseif what == velocity_split then
            what_value = column.volume_value
          elseif what == column_split then
            what_value = pos.column
          end
          
          note_pos = notes:find(what_value)
          
          -- Create a new track if necessary
          if not note_pos then
            notes:insert(what_value)
            current_song:insert_track_at(track+#notes)
            current_song.selected_track_index = track
            note_pos = #notes
            if what == column_split and current_song.tracks[track]:column_name(#notes) ~= "" then
              current_song.tracks[track+#notes].name = 
                current_song.tracks[track]:column_name(#notes)
            else
              current_song.tracks[track+#notes].name = 
                current_song.tracks[track].name.." - Split "..note_pos
            end
            -- Copy track colour and delay
            current_song.tracks[track+#notes].color =
              current_song.tracks[track].color
            if copy_outputdelay == true then
              current_song.tracks[track+#notes].output_delay = 
                current_song.tracks[track].output_delay
            end
            
            if group_tracks == false then
            
              -- Copy track volume, pan, width, delay, routing, devices and automation
              if copy_prefxvol == true then
                current_song.tracks[track+#notes].prefx_volume.value = 
                  current_song.tracks[track].prefx_volume.value
              end
              if copy_prefxpan == true then
                current_song.tracks[track+#notes].prefx_panning.value = 
                  current_song.tracks[track].prefx_panning.value
              end
              if copy_prefxwidth == true then
                current_song.tracks[track+#notes].prefx_width.value = 
                  current_song.tracks[track].prefx_width.value
              end
              if copy_postfxvol == true then
                current_song.tracks[track+#notes].postfx_volume.value = 
                  current_song.tracks[track].postfx_volume.value
              end
              if copy_postfxpan == true then
                current_song.tracks[track+#notes].postfx_panning.value = 
                  current_song.tracks[track].postfx_panning.value
              end
              if copy_outputrouting == true then
                current_song.tracks[track+#notes].output_routing = 
                  current_song.tracks[track].output_routing
              end
              if copy_devices == true then
                if #current_song.tracks[track].devices > 1 then
                  for d=2,#current_song.tracks[track].devices do
                    local device = current_song.tracks[track].devices[d]
                    current_song.tracks[track+#notes]:insert_device_at(
                      device.device_path, d)
                    local new_device = current_song.tracks[track+#notes].devices[d]
                    new_device.display_name = device.display_name
                    new_device.is_active = device.is_active
                    new_device.is_maximized = device.is_maximized
                    new_device.active_preset = device.active_preset
                    new_device.active_preset_data = device.active_preset_data
                  end
                end
              end
              if copy_automation == true then
                for _,p in ipairs(current_song.patterns) do
                  for idx,a in ipairs(p.tracks[track].automation) do
                    local aut =  p.tracks[track]:find_automation(a.dest_parameter)
                    if aut ~= nil then
                      local new_aut =
                        p.tracks[track+#notes]:create_automation(a.dest_parameter)
                      new_aut.playmode = aut.playmode
                      if selection_only == true then
                        local start_line = current_song.selection_in_pattern.start_line
                        local end_line = current_song.selection_in_pattern.end_line
                        local new_points = {}
                        for _, points in ipairs(aut.points) do
                          if points.time >= start_line and points.time <= end_line then
                            table.insert(new_points, points)
                          end
                        end
                        new_aut.points = new_points
                      else
                        new_aut.points = aut.points
                      end
                    end
                  end
                end
              end
            end
          end
          cache:insert({pos.column, column, note_pos})
          
          -- Check where to put the implicit note-off
          local second = false
          for _,item in ripairs(cache) do
            if item[1] == pos.column then
              if second == false then
                second = true
              else
                off_pos = item[3]
                off_item = item[2]
                break
              end
            end
          end
          
        -- If note value is not a note value (OFF or e.g. volume value)
        else
        
          -- Check where to put the value
          for _,item in ripairs(cache) do
            if item[1] == pos.column then
              note_pos = item[3]
              break
            end
          end
        end
        
        -- If note pos was found
        if note_pos ~= nil then
          local note_pos_track = 
            current_song.tracks[pos.track+note_pos]
          local note_pos_pattern_track = 
            current_song.patterns[pos.pattern].tracks[pos.track+note_pos]
          local note_pos_note_column
          if what == column_split then
            note_pos_note_column =  
              note_pos_pattern_track:line(pos.line).note_columns[1]
          else
            note_pos_note_column =  
              note_pos_pattern_track:line(pos.line).note_columns[pos.column]
          end

          -- Copy the note value from the original track to the splitted one
          note_pos_note_column:copy_from(column)
          
          -- Check how many note columns have to be visible in the splitted track
          if what == column_split then
            note_pos_track.visible_note_columns = 1
          else
            if pos.column > note_pos_track.visible_note_columns then
              note_pos_track.visible_note_columns = pos.column
            end
          end
          
          -- Check if to show the volume column in the splitted track
          if note_pos_track.volume_column_visible == false then
            if note_pos_note_column.volume_value ~= EMPTY_VOLUME then
              note_pos_track.volume_column_visible = true
            end
          end
          
          -- Check if to show the panning column in the splitted track
          if note_pos_track.panning_column_visible == false then
            if note_pos_note_column.panning_value ~= EMPTY_PANNING then
              note_pos_track.panning_column_visible = true
            end
          end
          
          -- Check if to show the delay column in the splitted track
          if note_pos_track.delay_column_visible == false then
            if note_pos_note_column.delay_value > 0 then
              note_pos_track.delay_column_visible = true
            end
          end
          
          -- Check if to show the FX column in the splitted track
          if note_pos_track.sample_effects_column_visible == false then
            if note_pos_note_column.effect_number_value > 0 then
              note_pos_track.sample_effects_column_visible = true
            end
          end
          
          -- Set implicit note-off, if enabled
          if implicit_off == true and off_pos ~= nil then
            local off_pos_track = 
              current_song.tracks[pos.track+off_pos]
            local off_pos_pattern_track = 
              current_song.patterns[pos.pattern].tracks[pos.track+off_pos]
            local off_pos_note_column = 
              off_pos_pattern_track:line(pos.line).note_columns[pos.column]
          
            if off_pos_note_column.note_value == EMPTY_NOTE then
              off_pos_note_column.note_value = NOTE_OFF
              
              -- Set possible delay value for implicit note-off
              if column.delay_value > 0 then
                off_pos_note_column.delay_value = column.delay_value
                if off_pos_note_column.delay_value > 0 then
                  off_pos_track.delay_column_visible = true
                end
              end
            end
          end
        end
      end
    end
  end

  -- Loop over all lines to copy effect columns, if enabled
  if copy_effects == true and group_tracks == false then
    
    step = 1
    
    for pos,line in current_song.pattern_iterator:lines_in_track(track, true) do
      
      -- Check what to process, whole track or just selection
      local process = false
      if selection_only == true then
        for _,note_column in ipairs(line.note_columns) do
          if note_column.is_selected == true then
            process = true
            break
          end
        end
      elseif selection_only == false then
        process = true
      end
      
      if process == true then
      
        -- Loop over effect columns
        for index,effect_column in ipairs(line.effect_columns) do
          
          if index <= visible_effect_columns then
            -- Update status
            renoise.app():show_status(string.format("Splitting... (%d%%)", 
                                      (step/(nr_lines*visible_effect_columns))*50+50))
            step =step + 1
          
            if effect_column.is_empty == false then
              local orig_number = effect_column.number_value
              local orig_amount = effect_column.amount_value
              
              -- Loop over new tracks and copy effect column
              for t,_ in ipairs(notes) do
                local other_track = 
                  current_song.tracks[pos.track+t]
                local other_pattern_track = 
                  current_song.patterns[pos.pattern].tracks[pos.track+t]
                local other_effect_column = 
                  other_pattern_track:line(pos.line).effect_columns[index]
                
                other_effect_column.number_value = orig_number
                other_effect_column.amount_value = orig_amount
                
                -- Check how many effect columns should be visible
                if index > other_track.visible_effect_columns then
                  other_track.visible_effect_columns = index
                end           
              end
            end
          end
        end
      end
    end
  end
  
  -- Check if tracks should be grouped
  if group_tracks == true then
  
    -- Create new group track
    local orig_name = current_song.tracks[track].name
    --current_song.tracks[track].name = orig_name.." - Orig"
    local orig_color = current_song.tracks[track].color
    local orig_routing = current_song.tracks[track].output_routing
    local group = current_song:insert_group_at(track+1)
    group.name = orig_name.." - Split Group"
    group.color = orig_color
    local group_track = track+1
    
    -- Put tracks into group
    for t=1,#notes do
      current_song:add_track_to_group(group_track+1, group_track)
      group_track = group_track+1
    end
    
    local orig_track = track
    
    -- Copy track volume, panning, width, routing and automation to group
    if copy_prefxvol == true then
      current_song.tracks[group_track].prefx_volume.value = 
        current_song.tracks[orig_track].prefx_volume.value
    end
    if copy_prefxpan == true then
      current_song.tracks[group_track].prefx_panning.value = 
        current_song.tracks[orig_track].prefx_panning.value
    end
    if copy_prefxwidth == true then
      current_song.tracks[group_track].prefx_width.value = 
        current_song.tracks[orig_track].prefx_width.value
    end
    if copy_postfxvol == true then
      current_song.tracks[group_track].postfx_volume.value = 
        current_song.tracks[orig_track].postfx_volume.value
    end
    if copy_postfxpan == true then
      current_song.tracks[group_track].postfx_panning.value = 
        current_song.tracks[orig_track].postfx_panning.value
    end
    if copy_outputrouting == true then
      current_song.tracks[group_track].output_routing = orig_routing
    end
    if copy_devices == true then
      if #current_song.tracks[orig_track].devices > 1 then
        for d=2,#current_song.tracks[orig_track].devices do
          local device = current_song.tracks[orig_track].devices[d]
          current_song.tracks[group_track]:insert_device_at(
            device.device_path, d)
          local new_device = current_song.tracks[group_track].devices[d]
          new_device.display_name = device.display_name
          new_device.is_active = device.is_active
          new_device.is_maximized = device.is_maximized
          new_device.active_preset = device.active_preset
          new_device.active_preset_data = device.active_preset_data
        end
      end
    end
    if copy_automation == true then
      for _,p in ipairs(current_song.patterns) do
        for idx,a in ipairs(p.tracks[orig_track].automation) do
          local aut =  p.tracks[orig_track]:find_automation(a.dest_parameter)
          if aut ~= nil then
            local new_aut =
              p.tracks[group_track]:create_automation(a.dest_parameter)
            new_aut.playmode = aut.playmode
            if selection_only == true then
              local start_line = current_song.selection_in_pattern.start_line
              local end_line = current_song.selection_in_pattern.end_line
              local new_points = {}
              for _, points in ipairs(aut.points) do
                if points.time >= start_line and points.time <= end_line then
                  table.insert(new_points, points)
                end
              end
              new_aut.points = new_points
            else
              new_aut.points = aut.points
            end
          end
        end
      end
    end
      
    -- Copy effects to group
    if copy_effects == true then
      
      step = 1
      
      -- Loop over all lines to copy effect columns, if enabled
      for pos,line in current_song.pattern_iterator:lines_in_track(orig_track, true) do
        
        -- Check what to process, whole track or just selection
        local process = false
        if selection_only == true then
          for _,note_column in ipairs(line.note_columns) do
            if note_column.is_selected == true then
              process = true
              break
            end
          end
        elseif selection_only == false then
          process = true
        end
        
        if process == true then
        
          -- Loop over effect columns
          for index,effect_column in ipairs(line.effect_columns) do
            
            if index <= visible_effect_columns then
              -- Update status
              renoise.app():show_status(string.format("Splitting... (%d%%)", 
                (step/(nr_lines*visible_effect_columns))*50+50))
              step =step + 1
            
              if effect_column.is_empty == false then
                local orig_number = effect_column.number_value
                local orig_amount = effect_column.amount_value
                
                -- Copy effect column
                local other_track = 
                  current_song.tracks[group_track]
                local other_pattern_track = 
                  current_song.patterns[pos.pattern].tracks[group_track]
                local other_effect_column = 
                  other_pattern_track:line(pos.line).effect_columns[index]
                
                other_effect_column.number_value = orig_number
                other_effect_column.amount_value = orig_amount
                
                -- Check how many effect columns should be visible
                if index > other_track.visible_effect_columns then
                  other_track.visible_effect_columns = index
                end           
              end
            end
          end
        end
      end
    end 
  end
  
  if delete_original == true then
    -- Delete original track
    current_song:delete_track_at(track)
  else
    -- Mute original track
    current_song.selected_track:mute()
  end
  
  renoise.app():show_status("'"..current_song.tracks[track].name..
    "' was split into "..#notes.." tracks")

end

-- Create GUI  
function gui()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local dialog
  local vb = renoise.ViewBuilder()
    
  local dialog_content = vb:horizontal_aligner{
    margin=DIALOG_MARGIN,
    spacing=DIALOG_SPACING,
    mode='center',
    
    vb:column{
      spacing = CONTROL_SPACING,
      vb:chooser{id='what', items={"Columns", "Notes", "Instruments", "Velocity"}, value=column_split},
      
      vb:space{ height=DIALOG_SPACING },

      vb:horizontal_aligner{
        vb:checkbox{id='implicit_off', value=true},
        vb:text{text="Set implicit Note-Offs"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_prefxvol', value=true},
        vb:text{text="Copy PreFX Volume"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_prefxpan', value=true},
        vb:text{text="Copy PreFX Panning"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_prefxwidth', value=true},
        vb:text{text="Copy PreFX Width"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_postfxvol', value=true},
        vb:text{text="Copy PostFX Volume"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_postfxpan', value=true},
        vb:text{text="Copy PostFX Panning"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_outputdelay', value=true},
        vb:text{text="Copy Output Delay"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_outputrouting', value=true},
        vb:text{text="Copy Output Routing"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_devices', value=true},
        vb:text{text="Copy Devices"}
      },      
      vb:horizontal_aligner{
        vb:checkbox{id='copy_automation', value=true},
        vb:text{text="Copy Automation"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='copy_effects', value=true},
        vb:text{text="Copy Pattern Effects"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='group_tracks', value=true},
        vb:text{text="Group Tracks"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='delete_original', value=true},
        vb:text{text="Delete Original Track"}
      },
      vb:horizontal_aligner{
        vb:checkbox{id='selection_only', value=false},
        vb:text{text="Selection only"}
      },
      
      vb:space{ height=DIALOG_SPACING },
      
      vb:horizontal_aligner{
        mode = 'center',
        vb:button{
          id='split_button',
          height=DIALOG_BUTTON_HEIGHT,
          width=80,
          text='Split',  
          notifier=function()
            dialog:close()
            split(vb.views.what.value, vb.views.implicit_off.value,
            vb.views.copy_prefxvol.value, vb.views.copy_prefxpan.value,
            vb.views.copy_prefxwidth.value, vb.views.copy_postfxvol.value,
            vb.views.copy_postfxpan.value, vb.views.copy_outputdelay.value,
            vb.views.copy_outputrouting.value, vb.views.copy_devices.value,
            vb.views.copy_automation.value, vb.views.copy_effects.value,
            vb.views.group_tracks.value, vb.views.selection_only.value,
            vb.views.delete_original.value)
          end
          },
        }
      }
    }
    
    local function keyhandler_func(dialog, key)
      if (key.modifiers == '' and key.name == 'return') then
        dialog:close()
        split(vb.views.what.value, vb.views.implicit_off.value,
        vb.views.copy_prefxvol.value, vb.views.copy_prefxpan.value,
        vb.views.copy_prefxwidth.value, vb.views.copy_postfxvol.value,
        vb.views.copy_postfxpan.value, vb.views.copy_outputdelay.value,
        vb.views.copy_outputrouting.value, vb.views.copy_devices.value,
        vb.views.copy_automation.value, vb.views.copy_effects.value,
        vb.views.group_tracks.value, vb.views.selection_only.value,
        vb.views.delete_original.value)
      elseif (key.modifiers == '' and key.name == 'esc') then
        dialog:close()
      end
    end
    
    dialog = renoise.app():show_custom_dialog('Split into separate Tracks', 
                                              dialog_content, keyhandler_func)
 end
