local vb = renoise.ViewBuilder()
local dialog
local checkboxes = {}
local retrig_checkboxes = {}
local playback_checkboxes = {}
local num_checkboxes = 16
local max_rows = 64
local column_choice = "FX Column"
local retrig_value = 4
local retrig_column_choice = "FX Column"
local active_steps_volume = num_checkboxes
local active_steps_retrig = num_checkboxes
local active_steps_playback = num_checkboxes
local panning_left_checkboxes = {}
local panning_center_checkboxes = {}
local panning_right_checkboxes = {}
local panning_buttons = {}
local active_steps_panning = num_checkboxes
local panning_column_choice = "FX Column"
local initializing = false -- Flag to control printing during initialization or fetching

local auto_grab = false
local previous_track_index = nil
local track_notifier = nil
local solo_mode = false
local selection_only = false
local print_once = false

-- Colors for buttons
local normal_color = nil
local highlight_color = {0x22, 0xaa, 0xff}

-- Helper function to safely switch to pattern editor only if not in sample/phrase editor
local function safe_switch_to_pattern_editor()
  local current_frame = renoise.app().window.active_middle_frame
  if current_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR and
     current_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR then
    renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  end
end

-- Initialize buttons and checkboxes
local buttons = {}
local retrig_buttons = {}
local playback_buttons = {}

-- Paketti Gater Device Script

local function initialize_checkboxes(count)
  checkboxes = {}
  retrig_checkboxes = {}
  playback_checkboxes = {}
  buttons = {}
  retrig_buttons = {}
  playback_buttons = {}
  panning_left_checkboxes = {}
  panning_center_checkboxes = {}
  panning_right_checkboxes = {}
  panning_buttons = {}

  for i = 1, count do
    local is_highlight = (i == 1 or i == 5 or i == 9 or i == 13)
    buttons[i] = vb:button{
      text = string.format("%02d", i),
      width=30,
      color = is_highlight and highlight_color or normal_color
    }
    retrig_buttons[i] = vb:button{
      text = string.format("%02d", i),
      width=30,
      color = is_highlight and highlight_color or normal_color
    }
    playback_buttons[i] = vb:button{
      text = string.format("%02d", i),
      width=30,
      color = is_highlight and highlight_color or normal_color
    }
    checkboxes[i] = vb:checkbox{
      value = false,
      width=30,
      notifier=function()
        if not initializing then
          insert_commands()
        end
      end
    }
    retrig_checkboxes[i] = vb:checkbox{
      value = false,
      width=30,
      notifier=function()
        if not initializing then
          insert_commands()
        end
      end
    }
    playback_checkboxes[i] = vb:checkbox{
      value = false,
      width=30,
      notifier=function()
        if not initializing then
          insert_commands()
        end
      end
    }
  end

  for i = 1, count do
    panning_left_checkboxes[i] = vb:checkbox{
      value = false,
      width=30,
      notifier=function()
        if panning_left_checkboxes[i].value then
          panning_center_checkboxes[i].value = false
          panning_right_checkboxes[i].value = false
        end
        if not initializing then
          insert_commands()
        end
      end
    }
    panning_center_checkboxes[i] = vb:checkbox{
      value = true,
      width=30,
      notifier=function()
        if panning_center_checkboxes[i].value then
          panning_left_checkboxes[i].value = false
          panning_right_checkboxes[i].value = false
        end
        if not initializing then
          insert_commands()
        end
      end
    }
    panning_right_checkboxes[i] = vb:checkbox{
      value = false,
      width=30,
      notifier=function()
        if panning_right_checkboxes[i].value then
          panning_left_checkboxes[i].value = false
          panning_center_checkboxes[i].value = false
        end
        if not initializing then
          insert_commands()
        end
      end
    }
    panning_buttons[i] = vb:button{
      text = string.format("%02d", i),
      width=30,
      color = (i == 1 or i == 5 or i == 9 or i == 13) and highlight_color or normal_color
    }
  end
end

initialize_checkboxes(num_checkboxes)

-- Set active steps based on the valuebox
local function set_active_steps_volume(value)
  active_steps_volume = value
  renoise.app():show_status("Volume Gater: Step count set to " .. value)
  if not initializing then
    insert_commands()
  end
end

local function set_active_steps_retrig(value)
  active_steps_retrig = value
  if not initializing then
    insert_commands()
  end
end

local function set_active_steps_playback(value)
  active_steps_playback = value
  if not initializing then
    insert_commands()
  end
end

local function set_active_steps_panning(value)
  active_steps_panning = value
  if not initializing then
    insert_commands()
  end
end

-- Receive Volume checkboxes state
local function receive_volume_checkboxes()
  if not renoise.song() then return end

  initializing = true -- Halt printing during fetching

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track
  local visible_note_columns = track.visible_note_columns

  for i = 1, num_checkboxes do
    local line_index = 1 + i -1
    if line_index <= max_rows then
      local line = pattern:track(track_index):line(line_index)
      if column_choice == "FX Column" then
        checkboxes[i].value = (line.effect_columns[1].number_string == "0C" and line.effect_columns[1].amount_string == "0F")
      elseif column_choice == "Volume Column" then
        checkboxes[i].value = false
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          if note_column.volume_string == "80" then
            checkboxes[i].value = true
            break
          end
        end
      elseif column_choice == "FX Column (L00)" then
        checkboxes[i].value = (line.effect_columns[1].number_string == "0L" and line.effect_columns[1].amount_string == "C0")
      end
    end
  end
  
  -- IMPORTANT: Don't call insert_commands() here as it would overwrite other effects
  -- Instead, only write the volume pattern to the first active_steps_volume rows
  
  local pattern_length = pattern.number_of_lines
  
  -- Only write volume effects, don't clear other effects
  local any_checkbox_checked = false
  for i = 1, num_checkboxes do
    if checkboxes[i].value then
      any_checkbox_checked = true
      break
    end
  end

  if any_checkbox_checked then
    -- Only write up to active_steps_volume
    for i = 1, active_steps_volume do
      local line = pattern:track(track_index):line(i)
      -- Get the actual checkbox index, looping if needed
      local checkbox_idx = ((i - 1) % active_steps_volume) + 1
      
      if column_choice == "FX Column" then
        if checkboxes[checkbox_idx].value then
          line.effect_columns[1].number_string = "0C"
          line.effect_columns[1].amount_string = "0F"
        else
          line.effect_columns[1].number_string = "0C"
          line.effect_columns[1].amount_string = "00"
        end
      elseif column_choice == "Volume Column" then
        track.volume_column_visible = true
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          -- Only update if not used by retrig
          if retrig_column_choice ~= "Volume Column" or 
             string.sub(note_column.volume_string, 1, 1) ~= "R" then
            if checkboxes[checkbox_idx].value then
              note_column.volume_string = "80"
            else
              note_column.volume_string = "00"
            end
          end
        end
      elseif column_choice == "FX Column (L00)" then
        if checkboxes[checkbox_idx].value then
          line.effect_columns[1].number_string = "0L"
          line.effect_columns[1].amount_string = "C0"
        else
          line.effect_columns[1].number_string = "0L"
          line.effect_columns[1].amount_string = "00"
        end
      end
    end
    
    -- Replicate the volume pattern to the rest of the pattern
    for row = active_steps_volume + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_volume) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
        dest_line.effect_columns[1]:copy_from(source_line.effect_columns[1])
      elseif column_choice == "Volume Column" then
        for col = 1, visible_note_columns do
          -- Only copy if not a retrig value
          if retrig_column_choice ~= "Volume Column" or 
             string.sub(source_line:note_column(col).volume_string, 1, 1) ~= "R" then
            dest_line:note_column(col).volume_string = source_line:note_column(col).volume_string
          end
        end
      end
    end
  end
  
  initializing = false
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Received Volume Gater pattern")
end

-- Receive Retrig checkboxes state
local function receive_retrig_checkboxes()
  if not renoise.song() then return end

  initializing = true

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track
  local visible_note_columns = track.visible_note_columns
  local pattern_length = pattern.number_of_lines

  -- First, read the current pattern to set checkbox states
  for i = 1, num_checkboxes do
    local line_index = 1 + i - 1
    if line_index <= max_rows then
      local line = pattern:track(track_index):line(line_index)
      if retrig_column_choice == "FX Column" then
        retrig_checkboxes[i].value = (line.effect_columns[2].number_string == "0R")
      elseif retrig_column_choice == "Volume Column" then
        retrig_checkboxes[i].value = false
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          if string.sub(note_column.volume_string, 1, 1) == "R" then
            retrig_checkboxes[i].value = true
            break
          end
        end
      elseif retrig_column_choice == "Panning Column" then
        renoise.song().selected_track.panning_column_visible = true
        retrig_checkboxes[i].value = false
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          if string.sub(note_column.panning_string, 1, 1) == "R" then
            retrig_checkboxes[i].value = true
            break
          end
        end
      end
    end
  end
  
  -- Now write the retrig pattern based on checkboxes, but don't call insert_commands()
  -- Clear the retrig columns first
  if retrig_column_choice == "FX Column" then
    clear_retrig()
  elseif retrig_column_choice == "Volume Column" then
    -- Only clear volume column if not used by volume gater
    if column_choice ~= "Volume Column" then
      clear_volume_column()
    end
  elseif retrig_column_choice == "Panning Column" then
    -- Only clear panning column if not used by panning gater
    if panning_column_choice ~= "Panning Column" then
      clear_panning_column()
    end
  end
  
  -- Write retrig pattern based on checkboxes
  local retrig_is_empty = true
  for i = 1, num_checkboxes do
    if retrig_checkboxes[i].value then
      retrig_is_empty = false
      break
    end
  end

  if not retrig_is_empty then
    -- Only write up to active_steps_retrig
    for i = 1, active_steps_retrig do
      local line = pattern:track(track_index):line(i)
      -- Get the actual checkbox index, looping if needed
      local checkbox_idx = ((i - 1) % active_steps_retrig) + 1

      if retrig_checkboxes[checkbox_idx].value then
        if retrig_column_choice == "FX Column" then
          line.effect_columns[2].number_string = "0R"
          line.effect_columns[2].amount_string = string.format("%02X", retrig_value)
        elseif retrig_column_choice == "Volume Column" then
          track.volume_column_visible = true
          for j = 1, visible_note_columns do
            local note_column = line:note_column(j)
            -- Only update if not used by volume gater
            if column_choice ~= "Volume Column" or 
               note_column.volume_string == "" or 
               note_column.volume_string == "00" or 
               note_column.volume_string == "80" then
              note_column.volume_string = string.format("R%X", retrig_value)
            end
          end
        elseif retrig_column_choice == "Panning Column" then
          renoise.song().selected_track.panning_column_visible = true
          for j = 1, visible_note_columns do
            local note_column = line:note_column(j)
            -- Only update if not used by panning gater
            if panning_column_choice ~= "Panning Column" or 
               note_column.panning_string == "" or 
               note_column.panning_string == "40" or 
               note_column.panning_string == "00" or 
               note_column.panning_string == "80" then
              note_column.panning_string = string.format("R%X", retrig_value)
            end
          end
        end
      end
    end
    
    -- Replicate the retrig pattern to the rest of the pattern
    for row = active_steps_retrig + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_retrig) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if retrig_column_choice == "FX Column" then
        dest_line.effect_columns[2]:copy_from(source_line.effect_columns[2])
      elseif retrig_column_choice == "Volume Column" then
        for col = 1, visible_note_columns do
          if string.sub(source_line:note_column(col).volume_string, 1, 1) == "R" then
            dest_line:note_column(col).volume_string = source_line:note_column(col).volume_string
          end
        end
      elseif retrig_column_choice == "Panning Column" then
        for col = 1, visible_note_columns do
          if string.sub(source_line:note_column(col).panning_string, 1, 1) == "R" then
            dest_line:note_column(col).panning_string = source_line:note_column(col).panning_string
          end
        end
      end
    end
  end
  
  initializing = false
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Received Retrig Gater pattern")
end

-- Receive Playback checkboxes state
local function receive_playback_checkboxes()
  if not renoise.song() then return end

  initializing = true

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track
  local pattern_length = pattern.number_of_lines

  -- First, read the current pattern to set checkbox states
  for i = 1, num_checkboxes do
    local line_index = 1 + i - 1
    if line_index <= max_rows then
      local line = pattern:track(track_index):line(line_index)
      playback_checkboxes[i].value = (line.effect_columns[3].number_string == "0B" and line.effect_columns[3].amount_string == "00")
    end
  end
  
  -- IMPORTANT: Don't call clear_playback_effect() as it would wipe the content
  -- Instead, only update the existing pattern without clearing
  
  -- Write playback pattern based on checkboxes
  local any_playback_checked = false
  for i = 1, num_checkboxes do
    if playback_checkboxes[i].value then
      any_playback_checked = true
      break
    end
  end

  if any_playback_checked then
    -- Only write up to active_steps_playback
    for i = 1, active_steps_playback do
      local line = pattern:track(track_index):line(i)
      -- Get the actual checkbox index, looping if needed
      local checkbox_idx = ((i - 1) % active_steps_playback) + 1
      
      -- Ensure the third effect column is visible
      if track.visible_effect_columns < 3 then
        track.visible_effect_columns = 4
      end

      if playback_checkboxes[checkbox_idx].value then
        line.effect_columns[3].number_string = "0B"
        line.effect_columns[3].amount_string = "00"
      else
        line.effect_columns[3].number_string = "0B"
        line.effect_columns[3].amount_string = "01"
      end
    end
    
    -- Replicate the playback pattern to the rest of the pattern
    for row = active_steps_playback + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_playback) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      dest_line.effect_columns[3]:copy_from(source_line.effect_columns[3])
    end
  end
  
  initializing = false
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Received Playback Gater pattern")
end

-- Receive Panning checkboxes state
local function receive_panning_checkboxes()
  if not renoise.song() then return end

  initializing = true

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track
  local pattern_length = pattern.number_of_lines

  -- First, read the current pattern to set checkbox states
  for i = 1, num_checkboxes do
    local line = pattern:track(track_index):line(i)

    if panning_column_choice == "Panning Column" then
      renoise.song().selected_track.panning_column_visible = true
      if line:note_column(1).panning_string == "00" then
        panning_left_checkboxes[i].value = true
        panning_center_checkboxes[i].value = false
        panning_right_checkboxes[i].value = false
      elseif line:note_column(1).panning_string == "80" then
        panning_left_checkboxes[i].value = false
        panning_center_checkboxes[i].value = false
        panning_right_checkboxes[i].value = true
      elseif line:note_column(1).panning_string == "40" then
        panning_left_checkboxes[i].value = false
        panning_center_checkboxes[i].value = true
        panning_right_checkboxes[i].value = false
      end
    elseif panning_column_choice == "FX Column" then
      if line.effect_columns[4].number_string == "0P" then
        if line.effect_columns[4].amount_string == "00" then
          panning_left_checkboxes[i].value = true
          panning_center_checkboxes[i].value = false
          panning_right_checkboxes[i].value = false
        elseif line.effect_columns[4].amount_string == "FF" then
          panning_left_checkboxes[i].value = false
          panning_center_checkboxes[i].value = false
          panning_right_checkboxes[i].value = true
        elseif line.effect_columns[4].amount_string == "7F" then
          panning_left_checkboxes[i].value = false
          panning_center_checkboxes[i].value = true
          panning_right_checkboxes[i].value = false
        end
      end
    end
  end

  -- Now write the panning pattern based on checkboxes, but don't call insert_commands()
  -- Clear the panning columns first
  if panning_column_choice == "FX Column" then
    clear_effect_column_4()
  elseif panning_column_choice == "Panning Column" then
    -- Only clear if not used by retrig
    if retrig_column_choice ~= "Panning Column" then
      clear_panning_column()
    end
  end
  
  -- Write panning pattern based on checkboxes
  local all_panning_center = true
  for i = 1, num_checkboxes do
    if panning_left_checkboxes[i].value or panning_right_checkboxes[i].value then
      all_panning_center = false
      break
    end
  end

  if not all_panning_center then
    -- Only write up to active_steps_panning
    for i = 1, active_steps_panning do
      local line = pattern:track(track_index):line(i)
      -- Get the actual checkbox index, looping if needed
      local checkbox_idx = ((i - 1) % active_steps_panning) + 1
      
      if panning_column_choice == "Panning Column" then
        renoise.song().selected_track.panning_column_visible = true
        if panning_left_checkboxes[checkbox_idx].value then
          line:note_column(1).panning_string = "00"
        elseif panning_right_checkboxes[checkbox_idx].value then
          line:note_column(1).panning_string = "80"
        else
          line:note_column(1).panning_string = "40"
        end
      elseif panning_column_choice == "FX Column" then
        if panning_left_checkboxes[checkbox_idx].value then
          line.effect_columns[4].number_string = "0P"
          line.effect_columns[4].amount_string = "00"
        elseif panning_right_checkboxes[checkbox_idx].value then
          line.effect_columns[4].number_string = "0P"
          line.effect_columns[4].amount_string = "FF"
        else
          line.effect_columns[4].number_string = "0P"
          line.effect_columns[4].amount_string = "7F"
        end
      end
    end
    
    -- Replicate the panning pattern to the rest of the pattern
    for row = active_steps_panning + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_panning) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if panning_column_choice == "FX Column" then
        dest_line.effect_columns[4]:copy_from(source_line.effect_columns[4])
      elseif panning_column_choice == "Panning Column" then
        for col = 1, #source_line.note_columns do
          -- Only copy panning values, not retrig values
          if string.sub(source_line.note_columns[col].panning_string, 1, 1) ~= "R" then
            dest_line.note_columns[col].panning_string = source_line.note_columns[col].panning_string
          end
        end
      end
    end
  end
  
  initializing = false
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Received Panning Gater pattern")
end

local function rand_volume_checkboxes()
  if not renoise.song() then return end

  -- Initialize random seed for true randomness
  math.randomseed(os.time())

  initializing = true  -- Prevent updates while setting values
  for i = 1, num_checkboxes do
    checkboxes[i].value = (math.random() > 0.5)
  end
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Randomize Retrig checkboxes
local function rand_retrig_checkboxes()
  if not renoise.song() then return end

  -- Initialize random seed for true randomness
  math.randomseed(os.time())

  initializing = true  -- Prevent updates while setting values
  for i = 1, num_checkboxes do
    retrig_checkboxes[i].value = (math.random() > 0.5)
  end
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Randomize Playback checkboxes
local function rand_playback_checkboxes()
  if not renoise.song() then return end

  -- Initialize random seed for true randomness
  math.randomseed(os.time())

  initializing = true  -- Prevent updates while setting values
  for i = 1, num_checkboxes do
    playback_checkboxes[i].value = (math.random() > 0.5)
  end
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Randomize Panning checkboxes
local function rand_panning_checkboxes()
  if not renoise.song() then return end

  -- Initialize random seed for true randomness
  math.randomseed(os.time())

  initializing = true  -- Prevent updates while setting values
  for i = 1, num_checkboxes do
    local rand_choice = math.random(1, 3)
    panning_left_checkboxes[i].value = (rand_choice == 1)
    panning_center_checkboxes[i].value = (rand_choice == 2)
    panning_right_checkboxes[i].value = (rand_choice == 3)
  end
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Clear Volume Gater
local function clear_volume_gater()
  if not renoise.song() then return end

  initializing = true  -- Prevent updates while clearing checkboxes
  -- Clear checkboxes
  for i = 1, num_checkboxes do
    checkboxes[i].value = false
  end
  
  -- Clear the actual pattern content
  if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
    clear_effect_columns()
  elseif column_choice == "Volume Column" then
    clear_volume_column()
  end
  
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Clear Retrig checkboxes
local function clear_retrig_checkboxes()
  if not renoise.song() then return end

  initializing = true  -- Prevent updates while clearing checkboxes
  -- Clear checkboxes
  for i = 1, num_checkboxes do
    retrig_checkboxes[i].value = false
  end
  
  -- Clear the actual pattern content
  if retrig_column_choice == "FX Column" then
    clear_retrig()
  elseif retrig_column_choice == "Volume Column" then
    if column_choice ~= "Volume Column" then  -- Only if not used by volume gater
      clear_volume_column()
    end
  elseif retrig_column_choice == "Panning Column" then
    if panning_column_choice ~= "Panning Column" then  -- Only if not used by panning gater
      clear_panning_column()
    end
  end
  
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Clear Playback checkboxes
local function clear_playback_checkboxes()
  if not renoise.song() then return end

  initializing = true  -- Prevent updates while clearing checkboxes
  -- Clear checkboxes
  for i = 1, num_checkboxes do
    playback_checkboxes[i].value = false
  end
  
  -- Clear the actual pattern content
  clear_playback_effect()
  
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Clear Panning checkboxes
local function clear_panning_checkboxes()
  if not renoise.song() then return end

  initializing = true  -- Prevent updates while clearing checkboxes
  -- Clear checkboxes
  for i = 1, num_checkboxes do
    panning_left_checkboxes[i].value = false
    panning_center_checkboxes[i].value = true
    panning_right_checkboxes[i].value = false
  end
  
  -- Clear the actual pattern content
  if panning_column_choice == "FX Column" then
    clear_effect_column_4()
  elseif panning_column_choice == "Panning Column" then
    if retrig_column_choice ~= "Panning Column" then  -- Only if not used by retrig
      clear_panning_column()
    end
  end
  
  initializing = false
  insert_commands()  -- Single update at the end
end

-- Shift checkboxes left or right
local function shift_checkboxes(direction)
  if not renoise.song() then return end

  local shifted = {}
  if direction == "left" then
    for i = 1, num_checkboxes do
      shifted[i] = checkboxes[(i % num_checkboxes) + 1].value
    end
  elseif direction == "right" then
    for i = 1, num_checkboxes do
      shifted[i] = checkboxes[((i - 2) % num_checkboxes) + 1].value
    end
  end
  for i = 1, num_checkboxes do
    checkboxes[i].value = shifted[i]
  end
  safe_switch_to_pattern_editor()

  if not initializing then
    insert_commands()
  end
end

-- Shift retrig checkboxes left or right
local function shift_retrig_checkboxes(direction)
  if not renoise.song() then return end

  local shifted = {}
  if direction == "left" then
    for i = 1, num_checkboxes do
      shifted[i] = retrig_checkboxes[(i % num_checkboxes) + 1].value
    end
  elseif direction == "right" then
    for i = 1, num_checkboxes do
      shifted[i] = retrig_checkboxes[((i - 2) % num_checkboxes) + 1].value
    end
  end
  for i = 1, num_checkboxes do
    retrig_checkboxes[i].value = shifted[i]
  end
  safe_switch_to_pattern_editor()

  if not initializing then
    insert_commands()
  end
end

-- Shift playback checkboxes left or right
local function shift_playback_checkboxes(direction)
  if not renoise.song() then return end

  local shifted = {}
  if direction == "left" then
    for i = 1, num_checkboxes do
      shifted[i] = playback_checkboxes[(i % num_checkboxes) + 1].value
    end
  elseif direction == "right" then
    for i = 1, num_checkboxes do
      shifted[i] = playback_checkboxes[((i - 2) % num_checkboxes) + 1].value
    end
  end
  for i = 1, num_checkboxes do
    playback_checkboxes[i].value = shifted[i]
  end
  safe_switch_to_pattern_editor()

  if not initializing then
    insert_commands()
  end
end

-- Shift panning checkboxes left or right
local function shift_panning_checkboxes(direction)
  if not renoise.song() then return end

  local shifted_left = {}
  local shifted_center = {}
  local shifted_right = {}

  if direction == "left" then
    for i = 1, num_checkboxes do
      shifted_left[i] = panning_left_checkboxes[(i % num_checkboxes) + 1].value
      shifted_center[i] = panning_center_checkboxes[(i % num_checkboxes) + 1].value
      shifted_right[i] = panning_right_checkboxes[(i % num_checkboxes) + 1].value
    end
  elseif direction == "right" then
    for i = 1, num_checkboxes do
      shifted_left[i] = panning_left_checkboxes[((i - 2) % num_checkboxes) + 1].value
      shifted_center[i] = panning_center_checkboxes[((i - 2) % num_checkboxes) + 1].value
      shifted_right[i] = panning_right_checkboxes[((i - 2) % num_checkboxes) + 1].value
    end
  end

  for i = 1, num_checkboxes do
    panning_left_checkboxes[i].value = shifted_left[i]
    panning_center_checkboxes[i].value = shifted_center[i]
    panning_right_checkboxes[i].value = shifted_right[i]
  end

  if not initializing then
    insert_commands()
  end
end

-- Clear Effect Columns
function clear_effect_columns()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    for j = 1, #line.effect_columns do
      if line.effect_columns[j].number_string == "0C" or line.effect_columns[j].number_string == "0L" then
        line.effect_columns[j].number_string = ""
        line.effect_columns[j].amount_string = ""
      end
    end
  end
  renoise.app():show_status("Cleared FX Column")
end

-- Add this at the top of the file with other globals
local suppress_status_messages = false

-- Modify the clear_retrig function to respect the suppress flag
function clear_retrig()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    line.effect_columns[2].number_string = ""
    line.effect_columns[2].amount_string = ""
  end
  
  if not suppress_status_messages then
    renoise.app():show_status("Cleared Retrig Effect")
  end
end

-- Similarly modify other clear functions to respect the suppress flag
function clear_volume_column()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    for j = 1, track.visible_note_columns do
      line:note_column(j).volume_string = ""
    end
  end
  
  if not suppress_status_messages then
    renoise.app():show_status("Cleared Volume Column")
  end
end

function clear_panning_column()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index
  local track = renoise.song().selected_track

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    for j = 1, track.visible_note_columns do
      line:note_column(j).panning_string = ""
    end
  end
  
  if not suppress_status_messages then
    renoise.app():show_status("Cleared Panning Column")
  end
end


-- Clear Playback Effect
function clear_playback_effect()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    line.effect_columns[3].number_string = ""
    line.effect_columns[3].amount_string = ""
  end
  
  if not suppress_status_messages then
    renoise.app():show_status("Cleared Playback Effect")
  end
end

-- Clear Effect Column 4
function clear_effect_column_4()
  if not renoise.song() then return end

  local pattern = renoise.song().selected_pattern
  local track_index = renoise.song().selected_track_index

  for i = 1, max_rows do
    local line = pattern:track(track_index):line(i)
    if line.effect_columns[4] then
      if line.effect_columns[4].number_string == "0P" then
        line.effect_columns[4].number_string = ""
        line.effect_columns[4].amount_string = ""
      end
    end
  end
  renoise.app():show_status("Cleared Effect Column 4")
end

-- Wipe gating effects from a specific track
local function wipe_gating_effects_from_track(track_index)
  local pattern = renoise.song().selected_pattern
  local selected_pattern = pattern:track(track_index)
  local track = renoise.song().tracks[track_index]
  local visible_note_columns = track.visible_note_columns
  
  -- Clear volume gating effects based on column choice
  if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      for j = 1, #line.effect_columns do
        if line.effect_columns[j].number_string == "0C" or line.effect_columns[j].number_string == "0L" then
          line.effect_columns[j].number_string = ""
          line.effect_columns[j].amount_string = ""
        end
      end
    end
  elseif column_choice == "Volume Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      for j = 1, visible_note_columns do
        -- Only clear volume values, not retrig values
        local vol_string = line:note_column(j).volume_string
        if vol_string == "80" or vol_string == "00" then
          line:note_column(j).volume_string = ""
        end
      end
    end
  end
  
  -- Clear retrig effects based on retrig column choice
  if retrig_column_choice == "FX Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      line.effect_columns[2].number_string = ""
      line.effect_columns[2].amount_string = ""
    end
  elseif retrig_column_choice == "Volume Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      for j = 1, visible_note_columns do
        local vol_string = line:note_column(j).volume_string
        if string.sub(vol_string, 1, 1) == "R" then
          line:note_column(j).volume_string = ""
        end
      end
    end
  elseif retrig_column_choice == "Panning Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      for j = 1, visible_note_columns do
        local pan_string = line:note_column(j).panning_string
        if string.sub(pan_string, 1, 1) == "R" then
          line:note_column(j).panning_string = ""
        end
      end
    end
  end
  
  -- Clear playback effects
  for i = 1, max_rows do
    local line = selected_pattern:line(i)
    if line.effect_columns[3].number_string == "0B" then
      line.effect_columns[3].number_string = ""
      line.effect_columns[3].amount_string = ""
    end
  end
  
  -- Clear panning effects based on panning column choice
  if panning_column_choice == "FX Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      if line.effect_columns[4] and line.effect_columns[4].number_string == "0P" then
        line.effect_columns[4].number_string = ""
        line.effect_columns[4].amount_string = ""
      end
    end
  elseif panning_column_choice == "Panning Column" then
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      for j = 1, visible_note_columns do
        local pan_string = line:note_column(j).panning_string
        -- Only clear panning values (00, 40, 80), not retrig values
        if pan_string == "00" or pan_string == "40" or pan_string == "80" then
          line:note_column(j).panning_string = ""
        end
      end
    end
  end
end

-- Wipe gating effects based on solo mode
local function wipe_gating_effects()
  if not renoise.song() then return end
  
  local pattern = renoise.song().selected_pattern
  local selected_track_index = renoise.song().selected_track_index
  
  if solo_mode then
    -- Wipe from ALL tracks EXCEPT the selected one
    for track_index = 1, #pattern.tracks do
      if track_index ~= selected_track_index then
        wipe_gating_effects_from_track(track_index)
      end
    end
    renoise.app():show_status("Wiped gating effects from all tracks except selected (Solo mode)")
  else
    -- Wipe from selected track only
    wipe_gating_effects_from_track(selected_track_index)
    renoise.app():show_status("Wiped gating effects from selected track")
  end
end

-- Function to apply gating only to the selected range
function apply_gating_to_selection(selection_info)
  if not selection_info or #selection_info == 0 then return end
  
  local song = renoise.song()
  local pattern = song.selected_pattern
  local selection = song.selection_in_pattern
  
  -- Get selection boundaries
  local start_line = selection.start_line
  local end_line = selection.end_line
  
  -- Process each selected track
  for _, track_info in ipairs(selection_info) do
    local track_index = track_info.track_index
    local track = pattern:track(track_index)
    local visible_note_columns = song.tracks[track_index].visible_note_columns
    
    -- Ensure effect columns are visible
    if song.tracks[track_index].visible_effect_columns < 4 then
      song.tracks[track_index].visible_effect_columns = 4
    end
    
    -- Apply gating effects only within the selected line range
    for line_idx = start_line, end_line do
      local line = track:line(line_idx)
      
      -- Calculate which step we're on (for pattern cycling)
      local step_in_pattern = ((line_idx - start_line) % math.max(active_steps_volume, active_steps_retrig, active_steps_playback, active_steps_panning)) + 1
      
      -- Volume gating
      local any_volume_checked = false
      for i = 1, num_checkboxes do
        if checkboxes[i].value then
          any_volume_checked = true
          break
        end
      end
      
      if any_volume_checked then
        local vol_step = ((step_in_pattern - 1) % active_steps_volume) + 1
        local checkbox_idx, is_silence = nil, false
        
        if vol_step <= 16 then
          checkbox_idx = ((vol_step - 1) % 16) + 1
        else
          is_silence = true
        end
        
        -- Apply volume effects to selected columns
        if #track_info.effect_columns > 0 and (column_choice == "FX Column" or column_choice == "FX Column (L00)") then
          if column_choice == "FX Column" then
            if is_silence then
              line.effect_columns[1].number_string = "0C"
              line.effect_columns[1].amount_string = "00"
            else
              if checkboxes[checkbox_idx].value then
                line.effect_columns[1].number_string = "0C"
                line.effect_columns[1].amount_string = "0F"
              else
                line.effect_columns[1].number_string = "0C"
                line.effect_columns[1].amount_string = "00"
              end
            end
          elseif column_choice == "FX Column (L00)" then
            if is_silence then
              line.effect_columns[1].number_string = "0L"
              line.effect_columns[1].amount_string = "00"
            else
              if checkboxes[checkbox_idx].value then
                line.effect_columns[1].number_string = "0L"
                line.effect_columns[1].amount_string = "C0"
              else
                line.effect_columns[1].number_string = "0L"
                line.effect_columns[1].amount_string = "00"
              end
            end
          end
        elseif #track_info.note_columns > 0 and column_choice == "Volume Column" then
          song.tracks[track_index].volume_column_visible = true
          for _, col in ipairs(track_info.note_columns) do
            local note_column = line:note_column(col)
            if is_silence then
              note_column.volume_string = "00"
            else
              if checkboxes[checkbox_idx].value then
                note_column.volume_string = "80"
              else
                note_column.volume_string = "00"
              end
            end
          end
        end
      end
      
      -- Retrig gating
      local any_retrig_checked = false
      for i = 1, num_checkboxes do
        if retrig_checkboxes[i].value then
          any_retrig_checked = true
          break
        end
      end
      
      if any_retrig_checked then
        local retrig_step = ((step_in_pattern - 1) % active_steps_retrig) + 1
        local checkbox_idx, is_silence = nil, false
        
        if retrig_step <= 16 then
          checkbox_idx = ((retrig_step - 1) % 16) + 1
        else
          is_silence = true
        end
        
        if not is_silence and retrig_checkboxes[checkbox_idx].value then
          if retrig_column_choice == "FX Column" and #track_info.effect_columns > 0 then
            line.effect_columns[2].number_string = "0R"
            line.effect_columns[2].amount_string = string.format("%02X", retrig_value)
          elseif retrig_column_choice == "Volume Column" and #track_info.note_columns > 0 then
            song.tracks[track_index].volume_column_visible = true
            for _, col in ipairs(track_info.note_columns) do
              local note_column = line:note_column(col)
              note_column.volume_string = string.format("R%X", retrig_value)
            end
          elseif retrig_column_choice == "Panning Column" and #track_info.note_columns > 0 then
            song.tracks[track_index].panning_column_visible = true
            for _, col in ipairs(track_info.note_columns) do
              local note_column = line:note_column(col)
              note_column.panning_string = string.format("R%X", retrig_value)
            end
          end
        end
      end
      
      -- Playback gating
      local any_playback_checked = false
      for i = 1, num_checkboxes do
        if playback_checkboxes[i].value then
          any_playback_checked = true
          break
        end
      end
      
      if any_playback_checked then
        local playback_step = ((step_in_pattern - 1) % active_steps_playback) + 1
        local checkbox_idx, is_silence = nil, false
        
        if playback_step <= 16 then
          checkbox_idx = ((playback_step - 1) % 16) + 1
        else
          is_silence = true
        end
        
        if #track_info.effect_columns > 0 then
          if is_silence then
            line.effect_columns[3].number_string = "0B"
            line.effect_columns[3].amount_string = "01"
          else
            if playback_checkboxes[checkbox_idx].value then
              line.effect_columns[3].number_string = "0B"
              line.effect_columns[3].amount_string = "00"
            else
              line.effect_columns[3].number_string = "0B"
              line.effect_columns[3].amount_string = "01"
            end
          end
        end
      end
      
      -- Panning gating
      local any_panning_not_center = false
      for i = 1, num_checkboxes do
        if panning_left_checkboxes[i].value or panning_right_checkboxes[i].value then
          any_panning_not_center = true
          break
        end
      end
      
      if any_panning_not_center then
        local panning_step = ((step_in_pattern - 1) % active_steps_panning) + 1
        local checkbox_idx, is_silence = nil, false
        
        if panning_step <= 16 then
          checkbox_idx = ((panning_step - 1) % 16) + 1
        else
          is_silence = true
        end
        
        if panning_column_choice == "FX Column" and #track_info.effect_columns > 0 then
          if is_silence then
            line.effect_columns[4].number_string = "0P"
            line.effect_columns[4].amount_string = "7F"
          else
            if panning_left_checkboxes[checkbox_idx].value then
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "00"
            elseif panning_right_checkboxes[checkbox_idx].value then
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "FF"
            else
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "7F"
            end
          end
        elseif panning_column_choice == "Panning Column" and #track_info.note_columns > 0 then
          song.tracks[track_index].panning_column_visible = true
          for _, col in ipairs(track_info.note_columns) do
            local note_column = line:note_column(col)
            if is_silence then
              note_column.panning_string = "40"
            else
              if panning_left_checkboxes[checkbox_idx].value then
                note_column.panning_string = "00"
              elseif panning_right_checkboxes[checkbox_idx].value then
                note_column.panning_string = "80"
              else
                note_column.panning_string = "40"
              end
            end
          end
        end
      end
    end
  end
  
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Applied gating to selection only")
end

-- Function to apply gating pattern once starting from current line position
function apply_gating_print_once()
  local song = renoise.song()
  local pattern = song.selected_pattern
  local start_line = song.selected_line_index
  local track_index = song.selected_track_index
  local track = pattern:track(track_index)
  local visible_note_columns = song.tracks[track_index].visible_note_columns
  
  -- Ensure effect columns are visible
  if song.tracks[track_index].visible_effect_columns < 4 then
    song.tracks[track_index].visible_effect_columns = 4
  end
  
  -- Determine the maximum step count we need to apply
  local max_steps = math.max(active_steps_volume, active_steps_retrig, active_steps_playback, active_steps_panning)
  
  -- Apply gating effects for the pattern length starting from current position
  for i = 1, max_steps do
    local line_idx = start_line + i - 1
    
    -- Make sure we don't go beyond the pattern length
    if line_idx > pattern.number_of_lines then
      break
    end
    
    local line = track:line(line_idx)
    
    -- Volume gating
    local any_volume_checked = false
    for j = 1, num_checkboxes do
      if checkboxes[j].value then
        any_volume_checked = true
        break
      end
    end
    
    if any_volume_checked and i <= active_steps_volume then
      local checkbox_idx, is_silence = nil, false
      
      if i <= 16 then
        checkbox_idx = ((i - 1) % 16) + 1
      else
        is_silence = true
      end
      
      if column_choice == "FX Column" then
        if is_silence then
          line.effect_columns[1].number_string = "0C"
          line.effect_columns[1].amount_string = "00"
        else
          if checkboxes[checkbox_idx].value then
            line.effect_columns[1].number_string = "0C"
            line.effect_columns[1].amount_string = "0F"
          else
            line.effect_columns[1].number_string = "0C"
            line.effect_columns[1].amount_string = "00"
          end
        end
      elseif column_choice == "Volume Column" then
        song.tracks[track_index].volume_column_visible = true
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          if is_silence then
            note_column.volume_string = "00"
          else
            if checkboxes[checkbox_idx].value then
              note_column.volume_string = "80"
            else
              note_column.volume_string = "00"
            end
          end
        end
      elseif column_choice == "FX Column (L00)" then
        if is_silence then
          line.effect_columns[1].number_string = "0L"
          line.effect_columns[1].amount_string = "00"
        else
          if checkboxes[checkbox_idx].value then
            line.effect_columns[1].number_string = "0L"
            line.effect_columns[1].amount_string = "C0"
          else
            line.effect_columns[1].number_string = "0L"
            line.effect_columns[1].amount_string = "00"
          end
        end
      end
    end
    
    -- Retrig gating
    local any_retrig_checked = false
    for j = 1, num_checkboxes do
      if retrig_checkboxes[j].value then
        any_retrig_checked = true
        break
      end
    end
    
    if any_retrig_checked and i <= active_steps_retrig then
      local checkbox_idx, is_silence = nil, false
      
      if i <= 16 then
        checkbox_idx = ((i - 1) % 16) + 1
      else
        is_silence = true
      end
      
      if not is_silence and retrig_checkboxes[checkbox_idx].value then
        if retrig_column_choice == "FX Column" then
          line.effect_columns[2].number_string = "0R"
          line.effect_columns[2].amount_string = string.format("%02X", retrig_value)
        elseif retrig_column_choice == "Volume Column" then
          song.tracks[track_index].volume_column_visible = true
          for j = 1, visible_note_columns do
            local note_column = line:note_column(j)
            note_column.volume_string = string.format("R%X", retrig_value)
          end
        elseif retrig_column_choice == "Panning Column" then
          song.tracks[track_index].panning_column_visible = true
          for j = 1, visible_note_columns do
            local note_column = line:note_column(j)
            note_column.panning_string = string.format("R%X", retrig_value)
          end
        end
      end
    end
    
    -- Playback gating
    local any_playback_checked = false
    for j = 1, num_checkboxes do
      if playback_checkboxes[j].value then
        any_playback_checked = true
        break
      end
    end
    
    if any_playback_checked and i <= active_steps_playback then
      local checkbox_idx, is_silence = nil, false
      
      if i <= 16 then
        checkbox_idx = ((i - 1) % 16) + 1
      else
        is_silence = true
      end
      
      if is_silence then
        line.effect_columns[3].number_string = "0B"
        line.effect_columns[3].amount_string = "01"
      else
        if playback_checkboxes[checkbox_idx].value then
          line.effect_columns[3].number_string = "0B"
          line.effect_columns[3].amount_string = "00"
        else
          line.effect_columns[3].number_string = "0B"
          line.effect_columns[3].amount_string = "01"
        end
      end
    end
    
    -- Panning gating
    local any_panning_not_center = false
    for j = 1, num_checkboxes do
      if panning_left_checkboxes[j].value or panning_right_checkboxes[j].value then
        any_panning_not_center = true
        break
      end
    end
    
    if any_panning_not_center and i <= active_steps_panning then
      local checkbox_idx, is_silence = nil, false
      
      if i <= 16 then
        checkbox_idx = ((i - 1) % 16) + 1
      else
        is_silence = true
      end
      
      if panning_column_choice == "FX Column" then
        if is_silence then
          line.effect_columns[4].number_string = "0P"
          line.effect_columns[4].amount_string = "7F"
        else
          if panning_left_checkboxes[checkbox_idx].value then
            line.effect_columns[4].number_string = "0P"
            line.effect_columns[4].amount_string = "00"
          elseif panning_right_checkboxes[checkbox_idx].value then
            line.effect_columns[4].number_string = "0P"
            line.effect_columns[4].amount_string = "FF"
          else
            line.effect_columns[4].number_string = "0P"
            line.effect_columns[4].amount_string = "7F"
          end
        end
      elseif panning_column_choice == "Panning Column" then
        song.tracks[track_index].panning_column_visible = true
        for j = 1, visible_note_columns do
          local note_column = line:note_column(j)
          if is_silence then
            note_column.panning_string = "40"
          else
            if panning_left_checkboxes[checkbox_idx].value then
              note_column.panning_string = "00"
            elseif panning_right_checkboxes[checkbox_idx].value then
              note_column.panning_string = "80"
            else
              note_column.panning_string = "40"
            end
          end
        end
      end
    end
  end
  
  safe_switch_to_pattern_editor()
  renoise.app():show_status("Applied gating pattern once from line " .. start_line)
end

-- Now modify the insert_commands function to be more efficient
function insert_commands()
  max_rows = renoise.song().selected_pattern.number_of_lines

  if not renoise.song() then return end

  -- Check if we're in selection_only mode
  if selection_only then
    local selection_info = selection_in_pattern_pro()
    if not selection_info then
      renoise.app():show_status("No selection found for Selection Only mode")
      return
    end
    
    -- Apply gating only to the selected range
    apply_gating_to_selection(selection_info)
    return
  end

  -- Check if we're in print_once mode
  if print_once then
    apply_gating_print_once()
    return
  end

  -- Suppress status messages during batch operations
  suppress_status_messages = true
  
  local pattern = renoise.song().selected_pattern
  local selected_track_index = renoise.song().selected_track_index
  
  -- Function to apply gating to a specific track
  local function apply_gating_to_track(track_index)
    local track = pattern:track(track_index)
    local visible_note_columns = renoise.song().tracks[track_index].visible_note_columns

    -- IMPORTANT: Only clear retrig columns if we're actually writing to them
    local retrig_is_empty = true
    for i = 1, num_checkboxes do
      if retrig_checkboxes[i].value then
        retrig_is_empty = false
        break
      end
    end
    
    -- Only clear retrig columns if we're actually writing retrig values
    if not retrig_is_empty then
      if retrig_column_choice == "FX Column" then
        for i = 1, max_rows do
          local line = pattern:track(track_index):line(i)
          line.effect_columns[2].number_string = ""
          line.effect_columns[2].amount_string = ""
        end
      elseif retrig_column_choice == "Volume Column" then
        -- Only clear if not used by volume gater
        if column_choice ~= "Volume Column" then
          for i = 1, max_rows do
            local line = pattern:track(track_index):line(i)
            for j = 1, visible_note_columns do
              line:note_column(j).volume_string = ""
            end
          end
        end
      elseif retrig_column_choice == "Panning Column" then
        -- Only clear if not used by panning gater
        if panning_column_choice ~= "Panning Column" then
          for i = 1, max_rows do
            local line = pattern:track(track_index):line(i)
            for j = 1, visible_note_columns do
              line:note_column(j).panning_string = ""
            end
          end
        end
      end
    end

    -- Ensure effect columns are visible
    if renoise.song().tracks[track_index].visible_effect_columns < 4 then
      renoise.song().tracks[track_index].visible_effect_columns = 4
    end

    -- Volume handling
    local any_checkbox_checked = false
    for i = 1, num_checkboxes do
      if checkboxes[i].value then
        any_checkbox_checked = true
        break
      end
    end

    if any_checkbox_checked then
      -- Only write up to active_steps_volume
      for i = 1, active_steps_volume do
        local line = pattern:track(track_index):line(i)
        -- Get the actual checkbox index, handling extended range
        local checkbox_idx
        local is_silence = false
        
        if i <= 16 then
          -- Steps 1-16: use checkbox pattern
          checkbox_idx = ((i - 1) % 16) + 1
        else
          -- Steps 17-32: silence
          is_silence = true  
        end
        
        if column_choice == "FX Column" then
          if is_silence then
            line.effect_columns[1].number_string = "0C"
            line.effect_columns[1].amount_string = "00"
          else
            if checkboxes[checkbox_idx].value then
              line.effect_columns[1].number_string = "0C"
              line.effect_columns[1].amount_string = "0F"
            else
              line.effect_columns[1].number_string = "0C"
              line.effect_columns[1].amount_string = "00"
            end
          end
        elseif column_choice == "Volume Column" then
          renoise.song().tracks[track_index].volume_column_visible = true
          for j = 1, visible_note_columns do
            local note_column = line:note_column(j)
            if is_silence then
              note_column.volume_string = "00"
            else
              if checkboxes[checkbox_idx].value then
                note_column.volume_string = "80"
              else
                note_column.volume_string = "00"
              end
            end
          end
        elseif column_choice == "FX Column (L00)" then
          if is_silence then
            line.effect_columns[1].number_string = "0L"
            line.effect_columns[1].amount_string = "00"
          else
            if checkboxes[checkbox_idx].value then
              line.effect_columns[1].number_string = "0L"
              line.effect_columns[1].amount_string = "C0"
            else
              line.effect_columns[1].number_string = "0L"
              line.effect_columns[1].amount_string = "00"
            end
          end
        end
      end
    end

    -- Panning handling
    local all_panning_center = true
    for i = 1, num_checkboxes do
      if panning_left_checkboxes[i].value or panning_right_checkboxes[i].value then
        all_panning_center = false
        break
      end
    end

    if not all_panning_center then
      -- Only write up to active_steps_panning
      for i = 1, active_steps_panning do
        local line = pattern:track(track_index):line(i)
        -- Get the actual checkbox index, handling extended range
        local checkbox_idx
        local is_silence = false
        
        if i <= 16 then
          -- Steps 1-16: use checkbox pattern
          checkbox_idx = ((i - 1) % 16) + 1
        else
          -- Steps 17-32: center (silence)
          is_silence = true
        end
        
        if panning_column_choice == "Panning Column" then
          renoise.song().tracks[track_index].panning_column_visible = true
          if is_silence then
            line:note_column(1).panning_string = "40"
          else
            if panning_left_checkboxes[checkbox_idx].value then
              line:note_column(1).panning_string = "00"
            elseif panning_right_checkboxes[checkbox_idx].value then
              line:note_column(1).panning_string = "80"
            else
              line:note_column(1).panning_string = "40"
            end
          end
        elseif panning_column_choice == "FX Column" then
          if is_silence then
            line.effect_columns[4].number_string = "0P"
            line.effect_columns[4].amount_string = "7F"
          else
            if panning_left_checkboxes[checkbox_idx].value then
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "00"
            elseif panning_right_checkboxes[checkbox_idx].value then
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "FF"
            else
              line.effect_columns[4].number_string = "0P"
              line.effect_columns[4].amount_string = "7F"
            end
          end
        end
      end
    end

    -- Retrig handling - only write if we have retrig values
    if not retrig_is_empty then
      -- Only write up to active_steps_retrig
      for i = 1, active_steps_retrig do
        local line = pattern:track(track_index):line(i)
        -- Get the actual checkbox index, handling extended range
        local checkbox_idx
        local is_silence = false
        
        if i <= 16 then
          -- Steps 1-16: use checkbox pattern
          checkbox_idx = ((i - 1) % 16) + 1
        else
          -- Steps 17-32: no retrig (silence)
          is_silence = true
        end

        if not is_silence and retrig_checkboxes[checkbox_idx].value then
          if retrig_column_choice == "FX Column" then
            line.effect_columns[2].number_string = "0R"
            line.effect_columns[2].amount_string = string.format("%02X", retrig_value)
          elseif retrig_column_choice == "Volume Column" then
            renoise.song().tracks[track_index].volume_column_visible = true
            for j = 1, visible_note_columns do
              local note_column = line:note_column(j)
              note_column.volume_string = string.format("R%X", retrig_value)
            end
          elseif retrig_column_choice == "Panning Column" then
            renoise.song().tracks[track_index].panning_column_visible = true
            for j = 1, visible_note_columns do
              local note_column = line:note_column(j)
              note_column.panning_string = string.format("R%X", retrig_value)
            end
          end
        end
      end
    end

    -- Playback handling
    local any_playback_checked = false
    for i = 1, num_checkboxes do
      if playback_checkboxes[i].value then
        any_playback_checked = true
        break
      end
    end

    if any_playback_checked then
      -- Only write up to active_steps_playback
      for i = 1, active_steps_playback do
        local line = pattern:track(track_index):line(i)
        -- Get the actual checkbox index, handling extended range
        local checkbox_idx
        local is_silence = false
        
        if i <= 16 then
          -- Steps 1-16: use checkbox pattern
          checkbox_idx = ((i - 1) % 16) + 1
        else
          -- Steps 17-32: normal playback (silence)
          is_silence = true
        end
        
        -- Ensure the third effect column is visible
        if renoise.song().tracks[track_index].visible_effect_columns < 3 then
          renoise.song().tracks[track_index].visible_effect_columns = 4
        end

        if is_silence then
          line.effect_columns[3].number_string = "0B"
          line.effect_columns[3].amount_string = "01"
        else
          if playback_checkboxes[checkbox_idx].value then
            line.effect_columns[3].number_string = "0B"
            line.effect_columns[3].amount_string = "00"
          else
            line.effect_columns[3].number_string = "0B"
            line.effect_columns[3].amount_string = "01"
          end
        end
      end
    end
  end
  
  -- Apply gating based on solo mode
  if solo_mode then
    -- Apply to all tracks EXCEPT the selected one
    for track_index = 1, #pattern.tracks do
      if track_index ~= selected_track_index then
        apply_gating_to_track(track_index)
      end
    end
    -- After writing the pattern based on active steps, replicate to fill the rest for all tracks except selected
    for track_index = 1, #pattern.tracks do
      if track_index ~= selected_track_index then
        PakettiReplicateAtCursorGaterForTrack(track_index)
      end
    end
    
    -- Clear all gating effects from the selected track when in solo mode
    local selected_pattern = pattern:track(selected_track_index)
    local selected_track = renoise.song().tracks[selected_track_index]
    local visible_note_columns = selected_track.visible_note_columns
    
    -- Clear volume gating effects based on column choice
    if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        for j = 1, #line.effect_columns do
          if line.effect_columns[j].number_string == "0C" or line.effect_columns[j].number_string == "0L" then
            line.effect_columns[j].number_string = ""
            line.effect_columns[j].amount_string = ""
          end
        end
      end
    elseif column_choice == "Volume Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        for j = 1, visible_note_columns do
          -- Only clear volume values, not retrig values
          local vol_string = line:note_column(j).volume_string
          if vol_string == "80" or vol_string == "00" then
            line:note_column(j).volume_string = ""
          end
        end
      end
    end
    
    -- Clear retrig effects based on retrig column choice
    if retrig_column_choice == "FX Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        line.effect_columns[2].number_string = ""
        line.effect_columns[2].amount_string = ""
      end
    elseif retrig_column_choice == "Volume Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        for j = 1, visible_note_columns do
          local vol_string = line:note_column(j).volume_string
          if string.sub(vol_string, 1, 1) == "R" then
            line:note_column(j).volume_string = ""
          end
        end
      end
    elseif retrig_column_choice == "Panning Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        for j = 1, visible_note_columns do
          local pan_string = line:note_column(j).panning_string
          if string.sub(pan_string, 1, 1) == "R" then
            line:note_column(j).panning_string = ""
          end
        end
      end
    end
    
    -- Clear playback effects
    for i = 1, max_rows do
      local line = selected_pattern:line(i)
      if line.effect_columns[3].number_string == "0B" then
        line.effect_columns[3].number_string = ""
        line.effect_columns[3].amount_string = ""
      end
    end
    
    -- Clear panning effects based on panning column choice
    if panning_column_choice == "FX Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        if line.effect_columns[4] and line.effect_columns[4].number_string == "0P" then
          line.effect_columns[4].number_string = ""
          line.effect_columns[4].amount_string = ""
        end
      end
    elseif panning_column_choice == "Panning Column" then
      for i = 1, max_rows do
        local line = selected_pattern:line(i)
        for j = 1, visible_note_columns do
          local pan_string = line:note_column(j).panning_string
          -- Only clear panning values (00, 40, 80), not retrig values
          if pan_string == "00" or pan_string == "40" or pan_string == "80" then
            line:note_column(j).panning_string = ""
          end
        end
      end
    end
    
  else
    -- Apply only to selected track (original behavior)
    apply_gating_to_track(selected_track_index)
    -- After writing the pattern based on active steps, replicate to fill the rest
    PakettiReplicateAtCursorGater(0, "selected_track", "above_and_current")
  end

  -- Re-enable status messages and show a single message
  suppress_status_messages = false
  safe_switch_to_pattern_editor()
  if solo_mode then
    renoise.app():show_status("Gater pattern updated (SOLO mode - all tracks except selected)")
  else
    renoise.app():show_status("Gater pattern updated")
  end
end

function PakettiReplicateAtCursorGaterForTrack(track_index)
  local song=renoise.song()
  local pattern = song.selected_pattern
  local pattern_length = pattern.number_of_lines
  
  -- IMPORTANT: We'll handle each effect type completely independently
  
  -- 1. Volume effects replication
  if active_steps_volume > 0 then
    
    -- Clear the rest of the pattern first to avoid interference
    for row = active_steps_volume + 1, pattern_length do
      local line = pattern:track(track_index):line(row)
      if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
        line.effect_columns[1].number_string = ""
        line.effect_columns[1].amount_string = ""
      elseif column_choice == "Volume Column" then
        for col = 1, #line.note_columns do
          line:note_column(col).volume_string = ""
        end
      end
    end
    
    -- Now replicate the pattern
    for row = active_steps_volume + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_volume) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
        dest_line.effect_columns[1]:copy_from(source_line.effect_columns[1])
      elseif column_choice == "Volume Column" then
        for col = 1, #source_line.note_columns do
          dest_line.note_columns[col].volume_string = source_line.note_columns[col].volume_string
        end
      end
    end
  end
  
  -- 2. Retrig effects replication
  if active_steps_retrig > 0 then
    
    -- Clear the rest of the pattern first
    for row = active_steps_retrig + 1, pattern_length do
      local line = pattern:track(track_index):line(row)
      if retrig_column_choice == "FX Column" then
        line.effect_columns[2].number_string = ""
        line.effect_columns[2].amount_string = ""
      elseif retrig_column_choice == "Volume Column" then
        -- Don't clear if we're also using volume column for volume gater
        if column_choice ~= "Volume Column" then
          for col = 1, #line.note_columns do
            line:note_column(col).volume_string = ""
          end
        end
      elseif retrig_column_choice == "Panning Column" then
        -- Don't clear if we're also using panning column for panning gater
        if panning_column_choice ~= "Panning Column" then
          for col = 1, #line.note_columns do
            line:note_column(col).panning_string = ""
          end
        end
      end
    end
    
    -- Now replicate the pattern
    for row = active_steps_retrig + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_retrig) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if retrig_column_choice == "FX Column" then
        dest_line.effect_columns[2]:copy_from(source_line.effect_columns[2])
      elseif retrig_column_choice == "Volume Column" then
        for col = 1, #source_line.note_columns do
          if string.sub(source_line.note_columns[col].volume_string, 1, 1) == "R" then
            dest_line.note_columns[col].volume_string = source_line.note_columns[col].volume_string
          end
        end
      elseif retrig_column_choice == "Panning Column" then
        for col = 1, #source_line.note_columns do
          if string.sub(source_line.note_columns[col].panning_string, 1, 1) == "R" then
            dest_line.note_columns[col].panning_string = source_line.note_columns[col].panning_string
          end
        end
      end
    end
  end
  
  -- 3. Playback effects replication
  if active_steps_playback > 0 then
    
    -- Clear the rest of the pattern first
    for row = active_steps_playback + 1, pattern_length do
      local line = pattern:track(track_index):line(row)
      line.effect_columns[3].number_string = ""
      line.effect_columns[3].amount_string = ""
    end
    
    -- Now replicate the pattern
    for row = active_steps_playback + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_playback) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      dest_line.effect_columns[3]:copy_from(source_line.effect_columns[3])
    end
  end
  
  -- 4. Panning effects replication
  if active_steps_panning > 0 then
    
    -- Clear the rest of the pattern first
    for row = active_steps_panning + 1, pattern_length do
      local line = pattern:track(track_index):line(row)
      if panning_column_choice == "FX Column" then
        line.effect_columns[4].number_string = ""
        line.effect_columns[4].amount_string = ""
      elseif panning_column_choice == "Panning Column" then
        -- Don't clear if we're also using panning column for retrig
        if retrig_column_choice ~= "Panning Column" then
          for col = 1, #line.note_columns do
            line:note_column(col).panning_string = ""
          end
        end
      end
    end
    
    -- Now replicate the pattern
    for row = active_steps_panning + 1, pattern_length do
      local dest_line = pattern:track(track_index):line(row)
      local source_row = ((row - 1) % active_steps_panning) + 1
      local source_line = pattern:track(track_index):line(source_row)
      
      if panning_column_choice == "FX Column" then
        dest_line.effect_columns[4]:copy_from(source_line.effect_columns[4])
      elseif panning_column_choice == "Panning Column" then
        for col = 1, #source_line.note_columns do
          -- Only copy panning values, not retrig values
          if string.sub(source_line.note_columns[col].panning_string, 1, 1) ~= "R" then
            dest_line.note_columns[col].panning_string = source_line.note_columns[col].panning_string
          end
        end
      end
    end
  end
end

function PakettiReplicateAtCursorGater(transpose, tracks_option, row_option)
  local song=renoise.song()
  local pattern = song.selected_pattern
  local pattern_length = pattern.number_of_lines
  
  -- Function to replicate content on a track
  local function replicate_on_track(track_index)
    -- IMPORTANT: We'll handle each effect type completely independently
    
    -- 1. Volume effects replication
    if active_steps_volume > 0 then
      
      -- Clear the rest of the pattern first to avoid interference
      for row = active_steps_volume + 1, pattern_length do
        local line = pattern:track(track_index):line(row)
        if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
          line.effect_columns[1].number_string = ""
          line.effect_columns[1].amount_string = ""
        elseif column_choice == "Volume Column" then
          for col = 1, #line.note_columns do
            line:note_column(col).volume_string = ""
          end
        end
      end
      
      -- Now replicate the pattern
      for row = active_steps_volume + 1, pattern_length do
        local dest_line = pattern:track(track_index):line(row)
        local source_row = ((row - 1) % active_steps_volume) + 1
        local source_line = pattern:track(track_index):line(source_row)
        
        if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
          dest_line.effect_columns[1]:copy_from(source_line.effect_columns[1])
        elseif column_choice == "Volume Column" then
          for col = 1, #source_line.note_columns do
            dest_line.note_columns[col].volume_string = source_line.note_columns[col].volume_string
          end
        end
      end
    end
    
    -- 2. Retrig effects replication
    if active_steps_retrig > 0 then
      
      -- Clear the rest of the pattern first
      for row = active_steps_retrig + 1, pattern_length do
        local line = pattern:track(track_index):line(row)
        if retrig_column_choice == "FX Column" then
          line.effect_columns[2].number_string = ""
          line.effect_columns[2].amount_string = ""
        elseif retrig_column_choice == "Volume Column" then
          -- Don't clear if we're also using volume column for volume gater
          if column_choice ~= "Volume Column" then
            for col = 1, #line.note_columns do
              line:note_column(col).volume_string = ""
            end
          end
        elseif retrig_column_choice == "Panning Column" then
          -- Don't clear if we're also using panning column for panning gater
          if panning_column_choice ~= "Panning Column" then
            for col = 1, #line.note_columns do
              line:note_column(col).panning_string = ""
            end
          end
        end
      end
      
      -- Now replicate the pattern
      for row = active_steps_retrig + 1, pattern_length do
        local dest_line = pattern:track(track_index):line(row)
        local source_row = ((row - 1) % active_steps_retrig) + 1
        local source_line = pattern:track(track_index):line(source_row)
        
        if retrig_column_choice == "FX Column" then
          dest_line.effect_columns[2]:copy_from(source_line.effect_columns[2])
        elseif retrig_column_choice == "Volume Column" then
          for col = 1, #source_line.note_columns do
            if string.sub(source_line.note_columns[col].volume_string, 1, 1) == "R" then
              dest_line.note_columns[col].volume_string = source_line.note_columns[col].volume_string
            end
          end
        elseif retrig_column_choice == "Panning Column" then
          for col = 1, #source_line.note_columns do
            if string.sub(source_line.note_columns[col].panning_string, 1, 1) == "R" then
              dest_line.note_columns[col].panning_string = source_line.note_columns[col].panning_string
            end
          end
        end
      end
    end
    
    -- 3. Playback effects replication
    if active_steps_playback > 0 then
      
      -- Clear the rest of the pattern first
      for row = active_steps_playback + 1, pattern_length do
        local line = pattern:track(track_index):line(row)
        line.effect_columns[3].number_string = ""
        line.effect_columns[3].amount_string = ""
      end
      
      -- Now replicate the pattern
      for row = active_steps_playback + 1, pattern_length do
        local dest_line = pattern:track(track_index):line(row)
        local source_row = ((row - 1) % active_steps_playback) + 1
        local source_line = pattern:track(track_index):line(source_row)
        
        dest_line.effect_columns[3]:copy_from(source_line.effect_columns[3])
      end
    end
    
    -- 4. Panning effects replication
    if active_steps_panning > 0 then
      
      -- Clear the rest of the pattern first
      for row = active_steps_panning + 1, pattern_length do
        local line = pattern:track(track_index):line(row)
        if panning_column_choice == "FX Column" then
          line.effect_columns[4].number_string = ""
          line.effect_columns[4].amount_string = ""
        elseif panning_column_choice == "Panning Column" then
          -- Don't clear if we're also using panning column for retrig
          if retrig_column_choice ~= "Panning Column" then
            for col = 1, #line.note_columns do
              line:note_column(col).panning_string = ""
            end
          end
        end
      end
      
      -- Now replicate the pattern
      for row = active_steps_panning + 1, pattern_length do
        local dest_line = pattern:track(track_index):line(row)
        local source_row = ((row - 1) % active_steps_panning) + 1
        local source_line = pattern:track(track_index):line(source_row)
        
        if panning_column_choice == "FX Column" then
          dest_line.effect_columns[4]:copy_from(source_line.effect_columns[4])
        elseif panning_column_choice == "Panning Column" then
          for col = 1, #source_line.note_columns do
            -- Only copy panning values, not retrig values
            if string.sub(source_line.note_columns[col].panning_string, 1, 1) ~= "R" then
              dest_line.note_columns[col].panning_string = source_line.note_columns[col].panning_string
            end
          end
        end
      end
    end
  end

  if tracks_option == "all_tracks" then
    for track_index = 1, #pattern.tracks do
      replicate_on_track(track_index)
    end
  elseif tracks_option == "selected_track" then
    local selected_track_index = song.selected_track_index
    replicate_on_track(selected_track_index)
  else
    renoise.app():show_status("Invalid tracks option: " .. tostring(tracks_option))
    return
  end

  renoise.app():show_status("Replicated all Gater patterns")
end





-- Preset functionality
local function apply_preset(preset, is_retrig, is_playback)
  if not renoise.song() then return end

  initializing = true

  local preset_state = {}
  if preset == "all" then
    preset_state = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
  elseif preset == "every_2nd" then
    preset_state = {1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0}
  elseif preset == "every_third" then
    preset_state = {1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1}
  elseif preset == "every_fourth" then
    preset_state = {1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0}
  elseif preset == "jaguar" then
    preset_state = {1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0}
  elseif preset == "caapi" then
    preset_state = {1,0,1,0,1,0,1,0,1,1,1,0,1,1,1,0}
  elseif preset == "none" then
    preset_state = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
  end

  if is_retrig then
    for i = 1, num_checkboxes do
      retrig_checkboxes[i].value = preset_state[i] == 1
    end
  elseif is_playback then
    for i = 1, num_checkboxes do
      playback_checkboxes[i].value = preset_state[i] == 1
    end
  else
    for i = 1, num_checkboxes do
      checkboxes[i].value = preset_state[i] == 1
    end
  end

  initializing = false
  insert_commands()
  safe_switch_to_pattern_editor()
end

-- Create the dialog
function pakettiGaterDialog()
    if dialog and dialog.visible then
      -- Add cleanup code here before closing
      if track_notifier and renoise.song().selected_track_index_observable:has_notifier(track_notifier) then
        renoise.song().selected_track_index_observable:remove_notifier(track_notifier)
      end
      dialog:close()
      dialog = nil
      return
    end
  initializing = true -- Start initialization

  initialize_checkboxes(num_checkboxes)
  local content = vb:column{
    vb:text{text="Volume Gater", font = "bold", style="strong" },
    vb:switch {
      items = { "FX Column (C00)", "Volume Column", "FX Column (L00)" },
      value = 1,
      width=300,
      notifier=function(index)
        local previous_choice = column_choice
        column_choice = (index == 1) and "FX Column" or (index == 2) and "Volume Column" or "FX Column (L00)"
        
        -- If switching from L00 to C00, reset the first device's parameter to 1 (regular volume)
        if previous_choice == "FX Column (L00)" and column_choice == "FX Column" then
          renoise.song().selected_track.devices[1].parameters[2].value = 1
        end
        
        if not initializing then
          insert_commands()
        end
      end
        },
   vb:row{
      buttons[1], buttons[2], buttons[3], buttons[4], buttons[5], buttons[6], buttons[7], buttons[8],
      buttons[9], buttons[10], buttons[11], buttons[12], buttons[13], buttons[14], buttons[15], buttons[16],
      vb:valuebox{
        min = 1,
        max = 32,
        value = active_steps_volume,
        width=50,
        notifier=function(value)
          set_active_steps_volume(value)
        end
      }
    },
    vb:row(checkboxes),
    vb:row{
      vb:button{ text="Clear", pressed = clear_volume_gater },
      vb:button{ text="Random", pressed = rand_volume_checkboxes },
      vb:button{ text="<", pressed = function() 
        initializing = true
        shift_checkboxes("left")
        initializing = false
        insert_commands()
      end},
      vb:button{ text=">", pressed = function() 
        initializing = true
        shift_checkboxes("right")
        initializing = false
        insert_commands()
      end},
      vb:button{ text="Clear FX Column", pressed = clear_effect_columns },
      vb:button{ text="Clear Volume Column", pressed = clear_volume_column },
      vb:button{ text="Receive", pressed = receive_volume_checkboxes }
    },
    vb:row{
      vb:button{ text="All", pressed = function() apply_preset("all", false, false) end},
      vb:button{ text="Every 2nd", pressed = function() apply_preset("every_2nd", false, false) end},
      vb:button{ text="Every 3rd", pressed = function() apply_preset("every_third", false, false) end},
      vb:button{ text="Every 4th", pressed = function() apply_preset("every_fourth", false, false) end},
      vb:button{ text="Jaguar", pressed = function() apply_preset("jaguar", false, false) end},
      vb:button{ text="Caapi", pressed = function() apply_preset("caapi", false, false) end} 
    },
    vb:text{text="Retrig Gater", font = "bold", style="strong"},
    vb:row{
      vb:valuebox{
        min = 1,
        max = 15,
        value = retrig_value,
        width=50,
        tooltip = "Retrig Speed",
        notifier=function(value)
          retrig_value = value
          if not initializing then
            insert_commands()
          end
        end
      },
      vb:text{text="Retrig Speed" }
    },
    vb:switch {
      items = { "FX Column", "Volume Column", "Panning Column" },
      value = 1,
      width=300,
      notifier=function(index)
        retrig_column_choice = (index == 1) and "FX Column" or (index == 2) and "Volume Column" or "Panning Column"
        if not initializing then
          insert_commands()
        end
      end
    },
    vb:row{
      retrig_buttons[1], retrig_buttons[2], retrig_buttons[3], retrig_buttons[4], retrig_buttons[5], retrig_buttons[6], retrig_buttons[7], retrig_buttons[8],
      retrig_buttons[9], retrig_buttons[10], retrig_buttons[11], retrig_buttons[12], retrig_buttons[13], retrig_buttons[14], retrig_buttons[15], retrig_buttons[16],
      vb:valuebox{
        min = 1,
        max = 32,
        value = active_steps_retrig,
        width=50,
        notifier = set_active_steps_retrig
      }
    },
    vb:row(retrig_checkboxes),
    vb:row{
      vb:button{ text="Clear", pressed = clear_retrig_checkboxes },
      vb:button{ text="Random", pressed = rand_retrig_checkboxes },
      vb:button{ text="<", pressed = function() 
        initializing = true
        shift_retrig_checkboxes("left")
        initializing = false
        insert_commands()
      end},
      vb:button{ text=">", pressed = function() 
        initializing = true
        shift_retrig_checkboxes("right")
        initializing = false
        insert_commands()
      end},
            vb:button{ text="Receive", pressed = receive_retrig_checkboxes }
    },
    vb:text{text="Playback Direction Gater", font = "bold", style="strong" },
    vb:row{
      playback_buttons[1], playback_buttons[2], playback_buttons[3], playback_buttons[4], playback_buttons[5], playback_buttons[6], playback_buttons[7], playback_buttons[8],
      playback_buttons[9], playback_buttons[10], playback_buttons[11], playback_buttons[12], playback_buttons[13], playback_buttons[14], playback_buttons[15], playback_buttons[16],
      vb:valuebox{
        min = 1,
        max = num_checkboxes,
        value = active_steps_playback,
        width=50,
        notifier = set_active_steps_playback
      }
    },
    vb:row(playback_checkboxes),
    vb:row{
      vb:button{ text="Clear", pressed = clear_playback_checkboxes },
      vb:button{ text="Random", pressed = rand_playback_checkboxes },
      vb:button{ text="<", pressed = function() 
        initializing = true
        shift_playback_checkboxes("left")
        initializing = false
        insert_commands()
      end},
      vb:button{ text=">", pressed = function() 
        initializing = true
        shift_playback_checkboxes("right")
        initializing = false
        insert_commands()
      end},
            vb:button{ text="Receive", pressed = receive_playback_checkboxes }
    },
    vb:text{text="Panning Gater", font = "bold", style="strong" },
    vb:switch {
      items = { "FX Column", "Panning Column" },
      value = 1,
      width=300,
      notifier=function(index)
        panning_column_choice = (index == 1) and "FX Column" or "Panning Column"
        if not initializing then
          insert_commands()
        end
      end
    },
    vb:row{
      panning_buttons[1], panning_buttons[2], panning_buttons[3], panning_buttons[4], panning_buttons[5], 
      panning_buttons[6], panning_buttons[7], panning_buttons[8], panning_buttons[9], 
      panning_buttons[10], panning_buttons[11], panning_buttons[12], panning_buttons[13], 
      panning_buttons[14], panning_buttons[15], panning_buttons[16],
      vb:valuebox{
        min = 1,
        max = 32,
        value = active_steps_panning,
        width=50,
        notifier = set_active_steps_panning
      }
    },
    vb:row(panning_left_checkboxes),
    vb:row(panning_center_checkboxes),
    vb:row(panning_right_checkboxes),
    vb:row{
      vb:button{ text="Clear", pressed = clear_panning_checkboxes },
      vb:button{ text="Random", pressed = rand_panning_checkboxes },
      vb:button{ text="<", pressed = function() 
        initializing = true
        shift_panning_checkboxes("left")
        initializing = false
        insert_commands()
      end},
      vb:button{ text=">", pressed = function() 
        initializing = true
        shift_panning_checkboxes("right")
        initializing = false
        insert_commands()
      end},
            vb:button{ text="Receive", pressed = receive_panning_checkboxes },
    },
    vb:row{
      --vb:text{text="Global", font="bold", style="strong"},
      vb:checkbox{
        value = auto_grab,
        notifier=function(value)
          auto_grab = value
          if value then
            previous_track_index = renoise.song().selected_track_index
            -- Remove existing notifier if it exists
            if track_notifier and renoise.song().selected_track_index_observable:has_notifier(track_notifier) then
              renoise.song().selected_track_index_observable:remove_notifier(track_notifier)
            end
            -- Add new notifier
            track_notifier = auto_grab_handler
            renoise.song().selected_track_index_observable:add_notifier(track_notifier)
          else
            -- Remove notifier when auto-grab is disabled
            if track_notifier and renoise.song().selected_track_index_observable:has_notifier(track_notifier) then
              renoise.song().selected_track_index_observable:remove_notifier(track_notifier)
            end
          end
        end
      },
      vb:text{text="Auto-Grab", style="strong", font="bold" },
      vb:checkbox{
        value = solo_mode,
        notifier=function(value)
          solo_mode = value
          if not initializing then
            insert_commands()
          end
        end
      },
      vb:text{text="Solo", style="strong", font="bold", tooltip="When enabled, applies gating to ALL tracks EXCEPT the selected one" },
      vb:checkbox{
        value = selection_only,
        notifier=function(value)
          selection_only = value
          if not initializing then
            insert_commands()
          end
        end
      },
      vb:text{text="Selection Only", style="strong", font="bold", tooltip="When enabled, only applies gating to the selected range in pattern" },
      vb:checkbox{
        value = print_once,
        notifier=function(value)
          print_once = value
          if not initializing then
            insert_commands()
          end
        end
      },
      vb:text{text="Print Once", style="strong", font="bold", tooltip="When enabled, applies gating pattern once starting from current line position" },
      
      vb:button{ text="<<", pressed = function()
        initializing = true  -- Prevent multiple updates
        shift_checkboxes("left")
        shift_retrig_checkboxes("left")
        shift_playback_checkboxes("left")
        shift_panning_checkboxes("left")
        initializing = false
        insert_commands()  -- Single update at the end
      end},
      vb:button{ text=">>", pressed = function()
        initializing = true  -- Prevent multiple updates
        shift_checkboxes("right")
        shift_retrig_checkboxes("right")
        shift_playback_checkboxes("right")
        shift_panning_checkboxes("right")
        initializing = false
        insert_commands()  -- Single update at the end
      end},
      vb:button{ text="Wipe", pressed = wipe_gating_effects, tooltip="Wipe gating effects: from other tracks when Solo is on, from selected track when Solo is off" },
      vb:button{ text="Global Clear", pressed = function()
        initializing = true
        -- Clear volume
        for i = 1, num_checkboxes do
          checkboxes[i].value = false
        end
        -- Clear retrig
        for i = 1, num_checkboxes do
          retrig_checkboxes[i].value = false
        end
        -- Clear playback
        for i = 1, num_checkboxes do
          playback_checkboxes[i].value = false
        end
        -- Clear panning (set all to center)
        for i = 1, num_checkboxes do
          panning_left_checkboxes[i].value = false
          panning_center_checkboxes[i].value = true
          panning_right_checkboxes[i].value = false
        end

        -- Clear all pattern content
        suppress_status_messages = true  -- Prevent multiple status messages
        
        -- Clear volume content based on column choice
        if column_choice == "FX Column" or column_choice == "FX Column (L00)" then
          clear_effect_columns()
        elseif column_choice == "Volume Column" then
          clear_volume_column()
        end
        
        -- Clear retrig content based on column choice
        if retrig_column_choice == "FX Column" then
          clear_retrig()
        elseif retrig_column_choice == "Volume Column" then
          if column_choice ~= "Volume Column" then  -- Only if not used by volume gater
            clear_volume_column()
          end
        elseif retrig_column_choice == "Panning Column" then
          if panning_column_choice ~= "Panning Column" then  -- Only if not used by panning gater
            clear_panning_column()
          end
        end
        
        -- Clear playback content
        clear_playback_effect()
        
        -- Clear panning content based on column choice
        if panning_column_choice == "FX Column" then
          clear_effect_column_4()
        elseif panning_column_choice == "Panning Column" then
          if retrig_column_choice ~= "Panning Column" then  -- Only if not used by retrig
            clear_panning_column()
          end
        end

        suppress_status_messages = false
        initializing = false
        insert_commands()  -- Single update at the end
      end},

      vb:button{ text="Global Random", pressed = function()
        -- Initialize random seed for true randomness
        math.randomseed(os.time())
        
        initializing = true
        -- Randomize volume
        for i = 1, num_checkboxes do
          checkboxes[i].value = math.random() > 0.5
        end
        -- Randomize retrig
        for i = 1, num_checkboxes do
          retrig_checkboxes[i].value = math.random() > 0.5
        end
        -- Randomize playback
        for i = 1, num_checkboxes do
          playback_checkboxes[i].value = math.random() > 0.5
        end
        -- Randomize panning
        for i = 1, num_checkboxes do
          local rand_choice = math.random(1, 3)
          if rand_choice == 1 then
            panning_left_checkboxes[i].value = true
            panning_center_checkboxes[i].value = false
            panning_right_checkboxes[i].value = false
          elseif rand_choice == 2 then
            panning_left_checkboxes[i].value = false
            panning_center_checkboxes[i].value = true
            panning_right_checkboxes[i].value = false
          else
            panning_left_checkboxes[i].value = false
            panning_center_checkboxes[i].value = false
            panning_right_checkboxes[i].value = true
          end
        end
        initializing = false
        insert_commands()  -- Single update at the end
      end},

        vb:button{ text="Global Receive", pressed = function()
        initializing = true
        receive_volume_checkboxes()
        receive_retrig_checkboxes()
        receive_playback_checkboxes()
        receive_panning_checkboxes()
        initializing = false
        insert_commands()
      end}
    }
  }

  -- Create keyhandler that can manage dialog variable
  local keyhandler = create_keyhandler_for_dialog(
    function() return dialog end,
    function(value) dialog = value end
  )
  dialog = renoise.app():show_custom_dialog("Paketti Volume/Retrig/Playback/Panning Gater", content, keyhandler)
  safe_switch_to_pattern_editor()

  -- Automatically receive the current pattern state when opening the dialog
  receive_volume_checkboxes()
  receive_retrig_checkboxes()
  receive_playback_checkboxes()
  receive_panning_checkboxes()
  
  initializing = false -- End initialization
end

-- Handle scenario when the dialog is closed by other means
renoise.app().window.active_middle_frame_observable:add_notifier(function()
  if dialog and not dialog.visible then
    dialog = nil
  end
end)

-- Keybinding function
renoise.tool():add_keybinding{name="Global:Paketti:Paketti Gater Dialog...",invoke=function()
  if dialog and dialog.visible then
    -- Add cleanup code here before closing
    if track_notifier and renoise.song().selected_track_index_observable:has_notifier(track_notifier) then
      renoise.song().selected_track_index_observable:remove_notifier(track_notifier)
    end
    dialog:close()
    dialog = nil
    return
  end
  
  max_rows = renoise.song().selected_pattern.number_of_lines
  if renoise.song() then
    pakettiGaterDialog()
    safe_switch_to_pattern_editor()
  end
end}

renoise.tool():add_midi_mapping{name="Paketti:Paketti Gater Dialog...",invoke=function(message)
  if message:is_trigger() then
  if dialog and dialog.visible then
    -- Add cleanup code here before closing
    if track_notifier and renoise.song().selected_track_index_observable:has_notifier(track_notifier) then
      renoise.song().selected_track_index_observable:remove_notifier(track_notifier)
    end
    dialog:close()
    dialog = nil
    return
  end
  
  max_rows = renoise.song().selected_pattern.number_of_lines
  if renoise.song() then
    pakettiGaterDialog()
    safe_switch_to_pattern_editor()
  end end
end}

function auto_grab_handler()
  if not auto_grab then return end
  
  local current_track_index = renoise.song().selected_track_index
  if current_track_index ~= previous_track_index then
    previous_track_index = current_track_index
    initializing = true
    receive_volume_checkboxes()
    receive_retrig_checkboxes()
    receive_playback_checkboxes()
    receive_panning_checkboxes()
    initializing = false
    insert_commands()
  end
end
