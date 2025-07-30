
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Groove Tool...",
  invoke = function()
    GrooveTool()
      
  end
}
    

---------------------------------------------------------
---------------------------------------------------------

local q_debug = 0
local GrooveTool_dialog = nil

local options = renoise.Document.create("ScriptingToolPreferences") {
      cycle_length = 8,
      range = 1,
      which_columns = 1,
      keep_columns = false,
      delete_note_off = true,
      close_dialog = true,
      slider1_value = 0,
      slider2_value = 0,
      slider3_value = 0,
      slider4_value = 0,
      slider5_value = 0,
      slider6_value = 0,
      slider7_value = 0,
      slider8_value = 0,
      slider9_value = 0,
      slider10_value = 0,
      slider11_value = 0,
      slider12_value = 0,
      slider13_value = 0,
      slider14_value = 0,
      slider15_value = 0,
      slider16_value = 0,
      slider17_value = 0,
      slider18_value = 0,
      slider19_value = 0,
      slider20_value = 0,
      slider21_value = 0,
      slider22_value = 0,
      slider23_value = 0,
      slider24_value = 0,
      slider25_value = 0,
      slider26_value = 0,
      slider27_value = 0,
      slider28_value = 0,
      slider29_value = 0,
      slider30_value = 0,
      slider31_value = 0,
      slider32_value = 0,
  }
  
renoise.tool().preferences = options



function GrooveTool()

  --check if dialog is open
  if GrooveTool_dialog and GrooveTool_dialog.visible then
    if q_debug == 1 then print("dialog is already open!") 
    end
    GrooveTool_dialog:show()
    return
  end
  
  ---------------------------------------------------------
  ---------------- Variables ------------------------------
  ---------------------------------------------------------

  local which_columns = options.which_columns.value -- 1 = all columns; 2 = current column
  local delete_note_off = options.delete_note_off.value
  local keep_columns = options.keep_columns.value
  local close_dialog = options.close_dialog.value
  local song
  local pattern_index
  local track_index
  local selected_column_index = renoise.song().selected_note_column_index
  local bpm 
  local lpb
  local ms_per_line
  local ms_per_hexunit
  local nr_of_lines
  local column_data = {}
  local write_columns = {}
  local offsets = {}
  local cycle_length = options.cycle_length.value
  local range = options.range.value

  ---------------------------------------------------------
  ---------------- Functions ------------------------------
  ---------------------------------------------------------
  
  --determine whether all columns are affected, or only the selected one
  
  local function choose_columns()
  
    if q_debug == 1 then print("--choose_columns:") 
    end
    
    write_columns = {}
    
    if which_columns == 1 then
    
      for i = 1, song.tracks[track_index].visible_note_columns do
        write_columns[i] = i
        
        if q_debug == 1 then rprint(column_data) 
        end
      end
    else 
      write_columns[renoise.song().selected_note_column_index] = renoise.song().selected_note_column_index
    end
    
    if q_debug == 1 then rprint(write_columns) 
    end
  end
    ---------------------------------------------------------
  ---------------------------------------------------------
    
  local function write_original_data()
  
     if q_debug == 1 then print("--write_original_data")
     end
    
    --local variables
    local line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    local line_index
    local target_line
    local current_data_column
    local note_column_index
    
    --clear all note data
    for _,line in line_iter do
      for i = 1,12 do
        line.note_columns[i]:clear()
      end
    end
    
    for note_column_index,_ in pairs(column_data) do
    
      current_data_column = column_data[note_column_index]
      
      --for each line...
      for i,line in pairs(current_data_column.lines) do
        
        --write original values
        target_line = renoise.song().patterns[pattern_index].tracks[track_index].lines[line].note_columns[note_column_index]
          
        target_line.note_value = current_data_column.note[line]
        target_line.instrument_value = current_data_column.instrument[line]
        target_line.volume_value = current_data_column.volume[line]
        target_line.panning_value = current_data_column.panning[line]
        target_line.delay_value = current_data_column.delay[line] 
      end
    end
  end

  ---------------------------------------------------------
  ---------------------------------------------------------

  -- calculate new times, lines and delays
  
  local function calculate()
    if q_debug == 1 then print("--calculate:") 
    end
   
    --local variables
    local line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    local delay
    local line_index
    local new_time
    local new_line
    local new_delay
    local new_line
    local new_delay
    local offset
    local current_data_column
    local note_column_index
    local relative_time    
    local relative_line

    --for each column
    for note_column_index,_ in pairs(column_data) do
    
       if q_debug == 1 then print("note_column_index..."..note_column_index.."...contents:") 
       end
      
        if column_data[note_column_index] ~= nil then
        
        --choose the data column
        current_data_column = column_data[note_column_index]
        
        if q_debug == 1 then rprint(current_data_column) 
        end

    
        --for each line...
        for i,line in pairs(current_data_column.lines) do
          print(line)
        
          relative_line = line%cycle_length
          if relative_line == 0 then relative_line = cycle_length end
          
          if q_debug == 1 then rprint("relative line: "..tostring(relative_line)) 
          end
          
      --calculate new line and delay
          new_time = current_data_column.time[line] + (offsets[relative_line] * ms_per_hexunit * range)
          new_line = math.floor(new_time/ms_per_line) + 1
          new_delay = math.floor((new_time%ms_per_line)/ms_per_hexunit)
          
      --due to rounding errors, delay can have a negative value in some cases, so...
          if new_delay < 0 then new_delay = 0 
          end
          
          --handle notes that would have been moved beyond the edges of the pattern
          if new_line < 1 then 
            new_line = new_line + nr_of_lines
          elseif new_line > nr_of_lines then 
            new_line = new_line - nr_of_lines
          end

          current_data_column.new_time[line] = new_time
          current_data_column.new_line[line] = new_line
          current_data_column.new_delay[line] = new_delay
        end
      end
    end
  end
  
  ---------------------------------------------------------
  ---------------------------------------------------------
  --write new notes (apply calculated times)
  
  local function apply()
    if q_debug == 1 then print("--apply:") 
    end
     
    --local variables
    local line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    local delay
    local line_index
    local target_line
    local target_line_nr
    local pattern_columns
    local target_column_nr
    local current_data_column
    local note_column_index

      --for each column
    for _,note_column_index in pairs(write_columns) do
      if q_debug == 1 then print("note_column_index..."..note_column_index.."...contents:") 
      end
    
      --choose the data column
      current_data_column = column_data[note_column_index]
    
      if q_debug == 1 then rprint(current_data_column) 
      end
    
      --for each line...
      for i,line in pairs(current_data_column.lines) do
      
      
      --write notes
        if not (delete_note_off == true and current_data_column.note[line] == 120) then
          target_line_nr = current_data_column.new_line[line]
          
          pattern_columns = song.patterns[pattern_index].tracks[track_index].lines[target_line_nr].note_columns
          target_column_nr = note_column_index

          ----------experimental:
          --place the note in the next column if tthe current one is not empty
          if keep_columns == false then
            while pattern_columns[target_column_nr].is_empty == false do
              target_column_nr = target_column_nr + 1
              
              if target_column_nr == 12 then
                break
              end
              
              if q_debug == 1 then rprint("Column is not empty!")
              end
              
              if target_column_nr > song.tracks[track_index].visible_note_columns then
                 song.tracks[track_index].visible_note_columns = target_column_nr
              end
            end
          end
          ----------------------------------------------------
          
          if q_debug == 1 then rprint("target_column_nr: "..tostring(target_column_nr)) 
          end
          
          if q_debug == 1 then rprint(target_line_nr) 
          end
          
          if q_debug == 1 then rprint(target_line) 
          end
          
          target_line = song.patterns[pattern_index].tracks[track_index].lines[target_line_nr].note_columns[target_column_nr]
          target_line.note_value = current_data_column.note[line]
          target_line.instrument_value = current_data_column.instrument[line]
          target_line.volume_value = current_data_column.volume[line]
          target_line.panning_value = current_data_column.panning[line]
          target_line.delay_value = current_data_column.new_delay[line]    
          
          if q_debug == 1 then print("write note...") 
          end
        end
      end
    end
  end
  
  ---------------------------------------------------------
  ---------------------------------------------------------
  -- clear note columns, and write back notes from the columns that should not be affected
  
  local function clear_data()
    if q_debug == 1 then print("--clear data")
    end
    
    local line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    local line_index
    local target_line
    local current_data_column
    local note_column_index
    
    --clear all note data
    for _,line in line_iter do
      for i = 1,12 do
        line.note_columns[i]:clear()
      end
    end
    
    --write back the data that should not be affected
    for note_column_index = 1, 12 do
        if q_debug == 1 then rprint(write_columns[note_column_index])
        end
      --do this only for the columns that should NOT be affected
      if (write_columns[note_column_index] == nil) and not (column_data[note_column_index] == nil) then

        current_data_column = column_data[note_column_index]
        
        --for each line...
        for i,line in pairs(current_data_column.lines) do
          
          --write original values
          target_line = renoise.song().patterns[pattern_index].tracks[track_index].lines[line].note_columns[note_column_index]
            
          target_line.note_value = current_data_column.note[line]
          target_line.instrument_value = current_data_column.instrument[line]
          target_line.volume_value = current_data_column.volume[line]
          target_line.panning_value = current_data_column.panning[line]
          target_line.delay_value = current_data_column.delay[line]
        end
      end  
    end
  end
  ---------------------------------------------------------
  ---------------------------------------------------------
  --read the note values and put them in the table column_data
  local function read_values()
  
    if q_debug == 1 then print("--read_values") 
    end

    --local variables (note data)
    local delay
    local note
    local inst
    local vol
    local pan
    local time_in_ms
    local note_column_index
    local current_data_column
    local note_column
    local note_column_index
    local line_index
    local line_iter
  
    --clear all stored note data
    column_data = {}
    
    --get values
    
    track_index = song.selected_track_index
    selected_column_index = song.selected_note_column_index
    nr_of_lines = song.patterns[pattern_index].number_of_lines
    bpm = song.transport.bpm
    lpb = song.transport.lpb
    ms_per_line = 60000/(bpm*lpb)
    ms_per_hexunit = ms_per_line/256
    
    --This function converts line and delay column value to milliseconds(relative to the start of the pattern)
    local function convert_to_ms(in_line, in_delay)
      return((ms_per_line * (in_line-1)) + (ms_per_hexunit * in_delay))
    end
    
    --for each column...
    for note_column_index = 1, 12  do
    
      if q_debug == 1 then print("read column..."..tostring(note_column_index)) 
      end
  
    --build the data structure for this note column
      table.insert(column_data,note_column_index, {})
      current_data_column = column_data[note_column_index]
      current_data_column["lines"] = {}
      current_data_column["note"] = {}
      current_data_column["instrument"] = {}
      current_data_column["volume"] = {}
      current_data_column["panning"] = {}
      current_data_column["delay"] = {}
      current_data_column["time"] = {}
      current_data_column["new_time"] = {}
      current_data_column["new_line"] = {}
      current_data_column["new_delay"] = {}
  
      line_index = 1
      line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
      
      --for each line in the pattern...
      for _,line in line_iter do
        if line.note_columns[note_column_index].is_empty == false then
          note_column = line.note_columns[note_column_index]
          
          --get values
          note = note_column.note_value
          inst = note_column.instrument_value
          vol = note_column.volume_value
          pan = note_column.panning_value
          delay = note_column.delay_value
          time_in_ms = convert_to_ms(line_index, delay)
          
          --put them in the column_data table, indexed by line number
          table.insert(current_data_column.lines, line_index)
          table.insert(current_data_column.note, line_index, note)
          table.insert(current_data_column.instrument, line_index, inst)
          table.insert(current_data_column.volume, line_index, vol)
          table.insert(current_data_column.panning, line_index, pan)
          table.insert(current_data_column.delay, line_index, delay)
          table.insert(current_data_column.time, line_index, time_in_ms)
          
          if q_debug == 1 then print("read line..."..tostring(line_index)) 
          end
          
        end
      line_index = line_index + 1
      end
    end
    
    if q_debug == 1 then 
      print("column_data:")
      rprint(column_data) 
    end
    
  end
  
  ---------------------------------------------------------
  ---------------------------------------------------------
  --calulate and apply
  local function calc_and_apply()
    calculate()
    clear_data()
    apply()  
  end
  ---------------------------------------------------------
  ---------------------------------------------------------  
    ---------------------------------------------------------
  ---------------------------------------------------------
    --Choose whether to write to all pattern or only the selcted one
  
  local function apply_to_all_patterns()
  
    if q_debug == 1 then print("--apply_to_all_patterns") 
    end
    
    local pattern_sequence = renoise.song().sequencer.pattern_sequence
    local finished_patterns = {}
    
    if q_debug == 1 then rprint(pattern_sequence)
    end
    
    write_original_data()
    
    for i,j in pairs(pattern_sequence) do 
      if finished_patterns[j] == nil then
        
        pattern_index = pattern_sequence[i]
        finished_patterns[j] = true
        read_values()
        calc_and_apply()
        
        if q_debug == 1 then print("shift applied to pattern..."..(j-1)) 
        end
        
      end
    end
  end
  
  ---------------------------------------------------------
  ---------------------------------------------------------
  --build and show the gui
  
  local function show_gui()

  if q_debug == 1 then print("--show_gui")
  end
     
  local vb = renoise.ViewBuilder()
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  local TEXT_ROW_WIDTH = 80

  local ok_button
  local cancel_button
  local column_chooser
  local pattern_chooser
  local reload_button
  local apply_to_all_button
  local delete_note_off_checkbox
  local number_of_lines_vb
  local sliders = {} 
  local reset_button
  local range_vb
  
  local function reload()
    write_original_data()
    pattern_index = song.selected_pattern_index
    read_values()
    calc_and_apply()
  end
  
  --when the pattern number changes, cancel and load the new pattern data
  song.selected_sequence_index_observable:add_notifier(reload)
  
  --use a timer to make the tool more responsive
  local counter = 4
  
  local function timer()
    counter = counter + 1
    if counter == 3 then
     if q_debug == 1 then print("...triggered") 
     end
     calc_and_apply()
    end
    
    --remove the notifiers if the dialog is closed
    if not GrooveTool_dialog.visible then 
      renoise.tool().app_idle_observable:remove_notifier(timer)
      song.selected_sequence_index_observable:remove_notifier(reload)
      if q_debug == 1 then print("notifiers_removed") 
      end
      GrooveTool_dialog = nil
      if q_debug == 1 then print(GrooveTool_dialog) 
      end
    end
  end
  
  renoise.tool().app_idle_observable:add_notifier(timer)
  
  local function show_status(message)
    renoise.app():show_status(message); print(message)
  end 
  
  --reset values
  offsets = {}
  
  ----- Controls -------

  number_of_lines_vb = vb:valuebox {
    min = 1,
    max = 32,
    value = cycle_length,
    bind = options.cycle_length,
    notifier = function(value)
       cycle_length = value
       --retrigger the timer
       counter = 1
       for i = 1, 32 do
        if i <= value then sliders[i].visible = true
        else sliders[i].visible = false
        end
       end
       calc_and_apply()    
    end
    }
    
  range_vb = vb:valuebox {
    min = 1,
    max = 8,
    value = range,
    notifier = function(value)
       range = value   
       calc_and_apply()
    end
    }
  
  local row_sliders = vb:row {
    margin = 10,
    width = 800,
  }

  --create sliders
  for i = 1, 32 do
    sliders[i] = vb:minislider {
      id = string.format("slider%d", i),
      min = -255,
      max = 255,
      bind = options[string.format("slider%d_value", i)],
      width = 15,
      height = 120,
      notifier = function(value)
        offsets[i] = value
         --retrigger the timer
        counter = 1
    end
    }
    
    offsets[i] = 0
    if i <= cycle_length then sliders[i].visible = true
    else sliders[i].visible = false
    end
    row_sliders:add_child(sliders[i])
    row_sliders.width = 500
  end
  
    
    
  ok_button = vb:button {
    text = "OK",
    width = 60,
    notifier = function()
        if close_dialog == true then
          GrooveTool_dialog:close()
        else
          pattern_index = song.selected_pattern_index
          read_values()
        end
      end,
    }
  
    cancel_button = vb:button {
      text = "cancel",
      width = 60,
      notifier = function()
        write_original_data()
        GrooveTool_dialog:close()
      end
    }
  
    reload_button = vb:button {
      text = "reload",
      width = 60,
      notifier = function()
        write_original_data()
        choose_columns()
        pattern_index = song.selected_pattern_index
        read_values()
        counter = 1
      end
    }

    
    apply_to_all_button = vb:button {
      text = "OK + apply to all patterns",
      width = 60,
      notifier = function()
        apply_to_all_patterns()
        if close_dialog == true then
            GrooveTool_dialog:close()
        else
            pattern_index = song.selected_pattern_index
            read_values()
        end
      end,
    }
    
    reset_button = vb:button {
      text = "reset sliders",
      width = 200,
      notifier = function()
        for i = 1, 32 do
        sliders[i].value = 1
        offsets[i] = 0
        end
        counter = 1
      end,
    }
    
   column_chooser = vb:popup {
    width = 110,
    value = options.which_columns.value,
    bind = options.which_columns,
    items = {"all columns", "current column"},
    notifier = function(new_index)
    which_columns = new_index
      write_original_data()
      choose_columns()
      counter = 1
    end
    }
    
    delete_note_off_checkbox = vb:checkbox {
      bind = options.delete_note_off,
      notifier = function(value)
        delete_note_off = value
        counter = 1
      end
    }
    
    local keep_columns_checkbox = vb:checkbox {
      bind = options.keep_columns,
      notifier = function(value)
        keep_columns = value
        counter = 1
    end
    }
    
    local close_dialog_checkbox = vb:checkbox {
      bind = options.close_dialog,
      notifier = function(value)
        close_dialog = value
        counter = 1
      end
    }
    

  ------ Rows -----

  local row_buttons = vb:horizontal_aligner {
    mode = "center",
    ok_button,
    cancel_button,
    apply_to_all_button,
    
  }
  
   local row_delete_note_off = vb:row {
    delete_note_off_checkbox,
    vb:text {text = "delete note off events"},
   }   

   local row_keep_columns = vb:row {
    keep_columns_checkbox,
    vb:text {text = "don't move notes to other columns"},
   }   

   local row_close_dialog = vb:row {
    close_dialog_checkbox,
    vb:text {text = "close after clicking 'OK' "},
   }      
   
   local row_nr_of_lines = vb:row {
    vb:text {
      width = 80,
      text = "cycle length: ",
      tooltip = "the number of lines after which the pattern repeats itself \n (= the number of sliders)",
    },
    number_of_lines_vb,
    vb:text { text = " lines"},
    
   }  
   
   local row_range = vb:row {
    vb:text {
      width = 80,
      text = "range: ",
      tooltip = "the maximum number of lines that a note will be moved",
    },
    range_vb,
    vb:text {text = " lines"},
   
   }
   
   local row_apply_to = vb:row {
     vb:text {
      width = TEXT_ROW_WIDTH,
      text = "apply to:",
     },
     column_chooser
   }    


  ------- Columns ------
  
  local dialog_content = vb:column {
  height = 800,
  margin = 6,
  spacing = 10,
    vb:column{
      style = "panel",
      margin = 10,
      spacing = 2,
      vb:horizontal_aligner{
        margin = 2,
        mode = "center",
         vb:column{
          width = 600,
          style = "panel",       
          margin = 3,
          row_sliders,            
          vb:horizontal_aligner{
            margin = 2,
            mode = "center",
            reset_button, 
          }, 
        },
      },
      vb:horizontal_aligner{
      margin = 10,
      spacing = 80,
      mode = "center",
        vb:column {
          row_nr_of_lines,
          row_range,
          row_apply_to,
        },
        vb:column{
            row_delete_note_off,
            row_keep_columns,
            row_close_dialog,
        },
       },
      row_buttons,
    },
    
    
  }
  
  -- DIALOG
  
  GrooveTool_dialog = renoise.app():show_custom_dialog("GrooveTool", dialog_content)
  
  for i = 1, 32 do
    offsets[i]=sliders[i].value
  end
  
  --apply shift
   counter = 1

  end
  

  ---------------------------------------------------------
  ----------- Run the script ------------------------------
  ---------------------------------------------------------
      
   renoise.song().transport.loop_pattern = true
   song = renoise.song()  
   track_index = song.selected_track_index
   choose_columns()
   pattern_index = song.selected_pattern_index
   read_values()
   renoise.song().tracks[track_index].delay_column_visible = true

   show_gui()
end

  









