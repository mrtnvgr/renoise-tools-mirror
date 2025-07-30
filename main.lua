
--viewbuilder object --global to all files
vb = renoise.ViewBuilder()

--dialog 
local my_dialog


------------------------------------------
--Set up Preferences file
------------------------------------------
--create preferences xml
options = renoise.Document.create {
  range = 1,
  include_subcolumns = true,
  include_fx = true,
  leave_one = false,
}

 --assign options-object to .preferences so renoise knows to load and update it with the tool
renoise.tool().preferences = options
------------------------------------------
--------------------------------------------

--------------------------------------------------------------
--Scanners by joule
--------------------------------------------------------------

function optimize_note_columns(track_index)

  if not (renoise.song():track(track_index).type == renoise.Track.TRACK_TYPE_SEQUENCER) then
    return
  end

  local rns = renoise.song()
  local sub = string.sub
  local reverse = string.reverse
  local match = string.match
  local find = string.find
  local max = math.max
  local floor = math.floor

  local found_vol = false
  local found_pan = false
  local found_dly = false
  
  local scan_subcolumns = options.include_subcolumns.value

  local max_note_column = 1

  for _, pattern in ipairs(rns.patterns) do
    local patterntrack = pattern:track(track_index)
    if not patterntrack.is_empty then
      local lines = patterntrack:lines_in_range(1, pattern.number_of_lines)
      for _, line in ipairs(lines) do
        if not line.is_empty then
          local line_str = sub(tostring(line), 0, 214)
          
            if scan_subcolumns then
              if (not found_vol) then
                for pos = 6, 204, 18 do
                  found_vol = found_vol or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
              
              if (not found_pan) then
                for pos = 8, 206, 18 do
                  found_pan = found_pan or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
              
              if (not found_dly) then
                for pos = 10, 208, 18 do
                  found_dly = found_dly or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
            end
          
          line_str = reverse(line_str)
          local first_match = match(line_str, "%d.[1-G]")
          max_note_column = (first_match and max(max_note_column,  12 - floor(find(line_str, first_match) / 18))) or max_note_column
        end
      end
    end
  end
  
  local track = rns:track(track_index)
  
  track.visible_note_columns = max_note_column
  if scan_subcolumns then
    track.volume_column_visible = not (not found_vol)
    track.panning_column_visible = not (not found_pan)
    track.delay_column_visible = not (not found_dly)
  end

end


function optimize_all_columns(track_index)

  local rns = renoise.song()
  local sub = string.sub
  local reverse = string.reverse
  local match = string.match
  local find = string.find
  local max = math.max
  local floor = math.floor

  local found_vol = false
  local found_pan = false
  local found_dly = false
  
  local scan_subcolumns = options.include_subcolumns.value

  local max_note_column = 1
  
  local has_note_columns = renoise.song():track(track_index).type == renoise.Track.TRACK_TYPE_SEQUENCER

  local max_effect_column = (options.leave_one.value and 1) or 0
  
  if renoise.song():track(track_index).type == renoise.Track.TRACK_TYPE_GROUP then
    max_effect_column = 1
  end

  for _, pattern in ipairs(rns.patterns) do
    local patterntrack = pattern:track(track_index)
    if not patterntrack.is_empty then
      local lines = patterntrack:lines_in_range(1, pattern.number_of_lines)
      for _, line in ipairs(lines) do
        if not line.is_empty then
          
          local line_str = tostring(line)

          if has_note_columns then
          
            -- searching for sub-columns in use
            if scan_subcolumns then
              if (not found_vol) then
                for pos = 6, 204, 18 do
                  found_vol = found_vol or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
              
              if (not found_pan) then
                for pos = 8, 206, 18 do
                  found_pan = found_pan or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
              
              if (not found_dly) then
                for pos = 10, 208, 18 do
                  found_dly = found_dly or match(sub(line_str, pos, pos+1), "[0-Z]")
                end
              end
            end
            --          
          
            local ncol_line_str = sub(line_str, 0, 214)
            ncol_line_str = reverse(ncol_line_str)
            local ncol_first_match = match(ncol_line_str, "%d.[1-G]")
            max_note_column = (ncol_first_match and math.max(max_note_column,  12 - floor(find(ncol_line_str, ncol_first_match) / 18))) or max_note_column
          end
            
          local ecol_line_str = reverse(line_str)
          local ecol_first_match = match(ecol_line_str, "[1-Z]")
          max_effect_column = (ecol_first_match and math.max(max_effect_column,  8 - floor(find(ecol_line_str, ecol_first_match) / 7))) or max_effect_column

        end
      end
    end
  end

  local track = rns:track(track_index)

  track.visible_effect_columns = max_effect_column

  if has_note_columns then
    track.visible_note_columns = max_note_column
    if scan_subcolumns then
      track.volume_column_visible = not (not found_vol)
      track.panning_column_visible = not (not found_pan)
      track.delay_column_visible = not (not found_dly)
    end
  end

end


--------------------------------------------------------------
--GUI
--------------------------------------------------------------
function invoke_gui()
  
  --1 dialog at a time
  if (my_dialog and my_dialog.visible) then -- only allows one dialog instance
    my_dialog:close()
    return
  end

  --dialog content
  
  vb.views.popup = nil
  vb.views.min = nil
  vb.views.button = nil

  local ITEM_HEIGHT = 22
  
  local dialog_content = vb:column {
   
      margin = 3,
      spacing = 0,
      
      vb:vertical_aligner {
       mode = "center",
       spacing = 4,
      
      vb:column {
       style = "group",
       margin = 7,
       spacing = 3,
       
      vb:row {
       margin = 0,
       spacing = 0,

        height = "100%",
       
        vb:text {
         text = "Range",
         width = 70,
         height = ITEM_HEIGHT,
        },
        
        vb:popup {
         id = "popup",
         width = 140,
         height = ITEM_HEIGHT,
         bind = options.range,
         items = {
           "All tracks in song",
           "Selected track in song",
          }           
        }
      },
      
      vb:row {

        vb:text {
          text = "Include vol/pan/dly/fx columns",
          height = ITEM_HEIGHT,
          width = 150
        },
       
        vb:space { width = 7 },

        vb:vertical_aligner {
          mode = "center",
                  
          vb:checkbox{
            active = true,
            bind = options.include_subcolumns
          }
        }
      },
      
      vb:row {

        vb:text {
          text = "Include effects columns",
          height = ITEM_HEIGHT,
          width = 150,
        },
       
        vb:space { width = 7 },

        vb:vertical_aligner {
          mode = "center",
                  
          vb:checkbox{
            active = true,
            bind = options.include_fx,
            notifier = function()
                       --set `Min of 1 Effects Column:` checkbox to be active or not
                       vb.views["min"].active = options.include_fx.value
                       end
          }
        }
      },

      vb:row { 
      
        vb:text {
         text = "Min of 1 effects column",
         height = ITEM_HEIGHT,
         width = 150
        },
        
        vb:space { width = 7 },

        vb:vertical_aligner {
          mode = "center",

          vb:checkbox{
          id = "min",
          active = options.include_fx.value,
          bind = options.leave_one
          },
        }
      }
       
      },--column
      
      vb:horizontal_aligner {
       mode = "center",
       margin = 0,
      
        vb:button {
         text = "Apply",
         id = "button",
         height = 24,
         width = 90,
         notifier = function()
                     
          --process Single Track note columns only
          if vb.views["popup"].value == 2 then
          
            local track_index = renoise.song().selected_track_index
            
              if options.include_fx.value then
                optimize_all_columns(track_index)
              else
                optimize_note_columns(track_index)
              end
           
          end 
          
          --process All Tracks
          if vb.views["popup"].value == 1 then
          
            for track_index = 1, renoise.song().sequencer_track_count do
          
              if options.include_fx.value then
                optimize_all_columns(track_index)
              else
                optimize_note_columns(track_index)
              end
            
            end

          end
          
            renoise.app():show_status("Optimized columns.")          
        end }           
      }
    }
  }
  ------------------------------------------------------      
  --key Handler
  ------------------------------------------------------      

  local function my_keyhandler_func(dialog, key)
   --closing the dialog with escape
   if not (key.modifiers == "" and key.name == "esc") then
      return key
   else
     dialog:close()
   end
  end
  
  my_dialog = renoise.app():show_custom_dialog("To Active Columns", dialog_content, my_keyhandler_func)
end


--------------------------------
--Keybindings
--------------------------------
renoise.tool():add_keybinding {
  name = "Global:Tools:Set Track Widths To Active Columns",
  invoke = function() invoke_gui()
  end  
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Ledger`s Scripts:Set Track Widths To Active Columns",
  invoke = function() invoke_gui()
  end
}

