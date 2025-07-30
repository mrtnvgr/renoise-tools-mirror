
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Iterative Quantize...",
  invoke = function()
    quantizer()
  end
}

---------------------------------------------------------
---------------------------------------------------------
local IQ_dialog = nil

local options = renoise.Document.create("ScriptingToolPreferences"){
      shift_value = 0,
      quant_value = 0,
      which_columns = 1,
      delete_note_off = true,
      quant_lines = 1,
      keep_columns = false,
      close_dialog = false,
  }
  
renoise.tool().preferences = options

function quantizer()

  if IQ_dialog and IQ_dialog.visible then
    if q_debug == 1 then print("dialog is already open!") 
    end
    IQ_dialog:show()
    return
  end
  
  ---------------------------------------------------------
  ---------------- Variables ------------------------------
  ---------------------------------------------------------

  local q_debug = 0
  
  
  local shift_value = options.shift_value.value
  local quant_value = options.quant_value.value 
  local which_columns = options.which_columns.value -- 1 = all columns; 2 = current column
  local delete_note_off = options.delete_note_off.value
  local quant_lines = options.quant_lines.value
  local keep_columns = options.keep_columns.value
  local close_dialog = options.close_dialog.value

  local IQ_dialog
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

  
  
  ---------------------------------------------------------
  ---------------- Functions ------------------------------
  ---------------------------------------------------------
  
  --determine whether all columns are affected, or only the selected one
  
  local function choose_columns()
  
    if q_debug == 1 then print("--choose_columns:") 
    end
    
    if which_columns == 1 then
    
      for i = 1, song.tracks[track_index].visible_note_columns do
        write_columns[i] = i
        
        if q_debug == 1 then rprint(column_data) 
        end
      end
    else 
      write_columns[1] = renoise.song().selected_note_column_index
    end
    
    if q_debug == 1 then rprint(write_columns) 
    end
  end
  
  ---------------------------------------------------------
  ---------------------------------------------------------
  --calculate and write the new data
  
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


          --place the note in the next column if the current one is not empty
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
  
  ------------------------------------------------------
  ------------------------------------------------------
  --write new notes (apply calculated times)
  
  local function calculate()
    local line_iter =  song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    local delay
    local line_index
    local target_line
    local new_time
    local new_line
    local new_delay
    local new_line
    local new_delay
    local offset
    local current_data_column
    local note_column_index
    
    local quant_time = ms_per_line * quant_lines
      
      --for each column
      for _,note_column_index in pairs(write_columns) do
      
         if q_debug == 1 then print("note_column_index..."..note_column_index.."...contents:") 
         end
        
        --choose the data column
        current_data_column = column_data[note_column_index]
        
        if q_debug == 1 then rprint(current_data_column) 
        end
        
         --clear all notes
        for _,line in line_iter do line.note_columns[note_column_index]:clear()
        end
        
        --calculate new values and apply
      
        --for each line...
        for i,line in pairs(current_data_column.lines) do
          
          --apply shift
          new_time = current_data_column.time[line] + shift_value
          
          
          --apply quantize
          offset = new_time%quant_time
          
          -- notes that are closer to the next line than to the previous are quantized with respect to the next line
          if offset > (quant_time/2) and quant_time ~= 0 then offset = (offset - quant_time) 
          end
          
          new_time = new_time - (offset*(quant_value/100))
          new_line = math.floor(new_time/ms_per_line) + 1
          new_delay = math.floor((new_time%ms_per_line)/ms_per_hexunit)
          
          --due to rounding errors, delay can have a negative value in some cases, so...
          if new_delay < 0 then new_delay = 0 
          end
          
          --prevent delay values greater than 255
          if new_delay > 255 then
            new_line = new_line+1
            new_delay = 0            
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
    local shift_slider
    local shift_vb
    local quant_slider
    local quant_vb
    local reset_button
    local quant_lines_vb
    local row_apply_to

    
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
      if not IQ_dialog.visible then 
        renoise.tool().app_idle_observable:remove_notifier(timer)
        song.selected_sequence_index_observable:remove_notifier(reload)
        if q_debug == 1 then print("notifiers_removed") 
        end
        IQ_dialog = nil
        if q_debug == 1 then print(IQ_dialog) 
        end
      end
    end
    
    renoise.tool().app_idle_observable:add_notifier(timer)
    
    local function show_status(message)
      renoise.app():show_status(message); print(message)
    end 
    


    ----- Controls -------

    shift_slider = vb:slider {
      min = -200,
      max = 200,
      bind = options.shift_value,
      notifier = function(value)
         shift_value = value
         shift_vb.value = value
         --retrigger the timer
         counter = 1
      end
    }
    
    shift_vb = vb:valuebox {
      min = -200,
      max = 200,
      bind = options.shift_value,
      notifier = function(value)
       shift_value = value
       shift_slider.value = value
        --retrigger the timer
       counter = 1
      end
    }
    
    quant_slider = vb:slider {
      min = 0,
      max = 100,
      bind = options.quant_value,
      notifier = function(value)
        quant_value = value
        quant_vb.value = value
        --retrigger the timer
        counter = 1
      end
    }
    
    quant_vb =vb:valuebox {
      min = 0,
      max = 100,
      bind = options.quant_value,
      notifier = function(value)
        quant_value = value
        quant_slider.value = value
        --retrigger the timer
        counter = 1
      end
    }
      
    quant_lines_vb = vb:valuebox {
      min = 1,
      max = 24,
      bind = options.quant_lines,
      notifier = function(value)
        quant_lines = value
        --retrigger the timer
        counter = 1
      end
    }
      
   ok_button = vb:button {
    text = "OK",
    width = 60,
    notifier = function()
        if close_dialog == true then
          IQ_dialog:close()
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
      IQ_dialog:close()
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
          IQ_dialog:close()
      else
          pattern_index = song.selected_pattern_index
          read_values()
      end
    end,
    }
    
    reset_button = vb:button {
    text = "reset sliders",
    width = 60,
    notifier = function()
      for i = 1, 32 do
      sliders[i].value = 1
      offsets[i] = 0
      end
      counter = 1
    end,
    }
    
   column_chooser = vb:popup {
    width = 150,
    value = options.which_columns.value,
    bind = options.which_columns,
    items = {"All columns", "Current column"},
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
    end
    }
    ------ Rows -----
    
    local row_shift = vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "Shift"
      },
      shift_slider,
      shift_vb,
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "ms"
      }
    }
  
    local row_quant = vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "Quantize"
      },
      quant_slider,
      quant_vb,
      vb:text {
        width = 30,
        text = "%"
      },
    }
     
           
    local row_lines = vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "Quantize to"
      },
      quant_lines_vb,
      vb:text {text = " lines"},
    }
 
        
  local row_buttons = vb:horizontal_aligner {
    mode = "center",
    ok_button,
    cancel_button,
    reload_button,
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
          
    ------- Columns ------
    
    local dialog_content = vb:column {
      vb:row{
        vb:column{

          margin = DIALOG_MARGIN,
          spacing = CONTENT_SPACING,
          vb:text {text = "" },
          vb:text {text = "" },
          row_shift,
          row_quant, 
          row_lines,
        },
        vb:column{
          margin = DIALOG_MARGIN,
          spacing = CONTENT_SPACING,          

          vb:text { text = "apply to:"},
          column_chooser,
          row_delete_note_off,
          row_keep_columns,
          row_close_dialog,
          
        },
      },
      
     --vb:space { height = 50 },
      vb:text {text = "" },
      row_buttons,
      vb:text {text = "" },
    }
    
    -- DIALOG
    
    IQ_dialog = renoise.app():show_custom_dialog("Iterative Quantize", dialog_content)

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
   show_gui()
end

  









