
require "helper_gui"


--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------

local NOTE_VOLUME_COMMAND = '0M'
local TEMPO_EFFECT_COMMAND = 'ZT'
local MSG_VOLUME_ALREADY_EXISTS = "Warning: volume command already detected"

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

function default_volume()

  local selected_line = renoise.song().selected_line
  local selected_track = renoise.song().selected_track
  local val = g_default_volume
  local existing_value = 64
    
  if selected_track.visible_effect_columns < 2 then
    selected_track.visible_effect_columns = 2
  end  
  
  -- take the existing value - if exists
  if selected_line.effect_columns[2].number_string == NOTE_VOLUME_COMMAND then  
    existing_value = bit.rshift( selected_line.effect_columns[2].amount_value, 2 )      
  end
  
  -- if value < 64 and doesn't exists then proceed to write default volume value
  if val < 64 and existing_value ~= val then
  
    -- if a volume command is detected on that line then show a warning message
    if selected_line.effect_columns[1].number_string == NOTE_VOLUME_COMMAND or
      (selected_track.volume_column_visible == true 
      and selected_line.note_columns[1].volume_value <= 128) then
      
      renoise.app():show_status(MSG_VOLUME_ALREADY_EXISTS)
      
    end
    
    -- write volume on the second effect column     
    selected_line.effect_columns[2].number_string = NOTE_VOLUME_COMMAND
    selected_line.effect_columns[2].amount_value = bit.lshift( val, 2 )
      
  else
    
    -- clear the second effect column
    selected_line.effect_columns[2]:clear()
  
  end
  
  
end


function match_tempo_with_ticks(tempo)

  local selected_pattern = renoise.song().selected_pattern
  local selected_line_index = renoise.song().selected_line_index
  
  local master_track_index = nil
  local master_track = nil
  
  for k, v in ipairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      master_track = v
      master_track_index = k
    end
  end
  
  if master_track.visible_effect_columns < 2 then
    master_track.visible_effect_columns = 2
  end  
  
  local current_ticks = renoise.song().transport.tpl
  
  local value = tempo * 6 / current_ticks
  
  if value >= 0x20 and value <= 0xFF then
    selected_pattern.tracks[master_track_index].lines[selected_line_index].effect_columns[2].number_string = TEMPO_EFFECT_COMMAND
    selected_pattern.tracks[master_track_index].lines[selected_line_index].effect_columns[2].amount_value = value
    
    renoise.app():show_status(string.format('Song bpm set to %d (mod bpm: %d ticks: %d)', value, tempo, current_ticks))
    
  else
    renoise.app():show_warning(string.format('Renoise tempo value is out of range: %d', value))
  end
  
end



local function convert_note_to_string(note)
  
  local str_note = NOTES_TABLE[(note % 12) + 1];
  
  str_note = str_note .. math.floor(note / 12);
  
  return str_note;
  
end


local function get_relative_note(renBaseNote, renFineTuning, sampleRate)  
  
  local defaultNote = 48; -- C-4 for Renoise

  local relativeTone = 0;
  local fineTune = 0;

  local renoiseValue2Add = defaultNote - renBaseNote;

  local f2t = (1536.0 * (math.log(sampleRate / 8363.0) / math.log(2.0)));
  local transp = bit.rshift( f2t , 7 );
  local ftune = bit.band(f2t, 0x7F); --0x7F == 111 1111 

  ftune = ftune + renFineTuning;
  if (ftune > 80) then  
      transp = transp + 1;
      ftune = ftune - 128;
  end
  if (transp > 127) then transp = 127; end
  if (transp < -127) then transp = -127; end

  relativeTone = transp;
  fineTune = ftune;

  relativeTone = relativeTone + renoiseValue2Add;

  return relativeTone;
  
end

function set_portamento(value)

  local reached_limit = false
  
  local tpl = renoise.song().transport.tpl
  
  local ret = value * (tpl - 1) 
  
  local command = nil
  
  if (ret >= 0) then
    command = "0U"
  else
    command = "0D"
  end
  
  ret = math.abs (ret)
  
  if ret > 0xff then
    ret = bit.lshift( (ret / ret), 8) - 1    
    show_message_inaccurate_value()
    reached_limit = true
  end
  
  assign_effect(command, ret)
  
  return (reached_limit == false)

end



local function check_note_validation(pos)

  local selected_column_index = renoise.song().selected_note_column_index;
  
  local track_count = renoise.song().sequencer_track_count    
  
  local line_count = renoise.song().patterns[pos.pattern].number_of_lines;
  
  --local sample_index = renoise.song().selected_sample_index
  
  -- set sample_index to first sample available for selected instrument
  local sample_index = 1
  
  if selected_column_index > 0 and pos.track <= track_count then
      
    if pos.line <= line_count then
    
      local ren_note = renoise.song().patterns[pos.pattern].tracks[pos.track].lines[pos.line].note_columns[selected_column_index].note_value;
      
      -- get instrument index from note
      local instr_index = renoise.song().patterns[pos.pattern].tracks[pos.track].lines[pos.line].note_columns[selected_column_index].instrument_value + 1;

      if instr_index < 0xFF and ren_note ~= 121 and renoise.song().instruments[instr_index].samples[1] ~= nil then 
      
        local instr = renoise.song():instrument(instr_index);
        
        local sample = instr:sample(sample_index);
        
        if (sample.sample_buffer.has_sample_data) then
        
          local sample_rate = sample.sample_buffer.sample_rate;
          local sample_rate_settings = nil          
          local source = 'sample'
          
          if exists_sample_frequency_key(instr_index, sample_index) then
            sample_rate_settings = load_instrument_frequency(instr_index, sample_index)
          end
          
          --print('freq: ' .. sample_rate)              
          if sample_rate_settings ~= nil then
            --print('freq settings: ' .. sample_rate_settings)
            if sample_rate_settings ~= sample_rate then
              source = 'settings'
            end
          end
                    
          sample_rate = sample_rate_settings or sample_rate
          
          local fine_tune = sample.fine_tune;
          
          local base_note = instr:sample_mapping(renoise.Instrument.LAYER_NOTE_ON, 1).base_note;
          
          local modAmigaNoteRange = 36;
          local modExtNoteRange = 72;
          local xmNoteRange = 96;
          
          local note = get_relative_note(base_note, fine_tune, sample_rate);
          
          local minNote;
          local maxNote;
          
          if fmt_note_validation == VALIDATION_MOD_AMIGA then
            minNote = 36 - note;
            maxNote = minNote + modAmigaNoteRange - 1;
          elseif fmt_note_validation == VALIDATION_MOD_EXT then
            minNote = 24 - note;
            maxNote = minNote + modExtNoteRange - 1;
          elseif fmt_note_validation == VALIDATION_XM then
            minNote = 12;
            maxNote = xmNoteRange - 1;
          end
          
          if (minNote < 0) then minNote = 0; end
          if (maxNote > 120) then maxNote = 120; end
        
          local is_valid = true;
          
          local string_ren_note = convert_note_to_string(ren_note);
          
          local string_min_note = convert_note_to_string(minNote);
          
          local string_max_note = convert_note_to_string(maxNote);
          
          if (ren_note < minNote or ren_note > maxNote) then
            local message = string.format(MSG_NOTE_RANGE_WARNING, string_ren_note, source, sample_rate, string_min_note, string_max_note);
            renoise.app():show_warning(message)    
            is_valid = false;
          end
          
          if is_valid == false then      
            --renoise.song().patterns[pos.pattern].tracks[pos.track].lines[pos.line].note_columns[selected_column_index]:clear()
          end
          
        end    
        
      end 
      
    end
     
  end
  
  
  
end

-- line_changes_notifier function
function line_changes_notifier(pos)
  
  local selected_column_index = renoise.song().selected_note_column_index;
  
  local selected_effect_index = renoise.song().selected_effect_column_index;
  
  local instrument_index = renoise.song().selected_instrument_index
  
  local sample_index = renoise.song().selected_sample_index

  if selected_column_index > 0 then
    
    if fmt_note_validation ~= VALIDATION_NONE then      
    
      check_note_validation(pos)
    
    end
        
  end    
  
end

function attach_pattern_changes(edit)
  
  local ret = renoise.song().patterns[renoise.song().selected_pattern_index]:has_line_notifier(line_changes_notifier);
  if ret == false then
    renoise.song().patterns[renoise.song().selected_pattern_index]:add_line_notifier(line_changes_notifier);
  end
  
end

function update_tpl()  
  if helper_dialog and helper_dialog.visible then
    vb.views.tpl_valuebox.text = tostring(renoise.song().transport.tpl)
  end
end

function init_helper_dialog()

  show_helper_dialog();
  
  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel_dialog:close()
  end
  
  if converter_dialog and converter_dialog.visible then
    converter_dialog:close()
  end
  
  if downgrade_dialog and downgrade_dialog.visible then
    downgrade_dialog:close()
  end
  
  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:close()
  end

end

function show_portamento_status_message(value)
  local portamento_type = "Up"
  if value < 0 then portamento_type = "Down" end
  renoise.app():show_status(string.format("Portamento %s x%X", portamento_type, math.abs(value)))
end

function show_message_inaccurate_value()
  renoise.app():show_status("warning: value might be inaccurate")
end

function assign_effect(command, value)

  local selected_line_index = renoise.song().selected_line_index;
  
  local selected_pattern_index = renoise.song().selected_pattern_index
  
  local selected_track_index = renoise.song().selected_track_index
    
  if value > 0 then    
    renoise.song().patterns[selected_pattern_index].tracks[selected_track_index].lines[selected_line_index].effect_columns[1].number_string=command
    renoise.song().patterns[selected_pattern_index].tracks[selected_track_index].lines[selected_line_index].effect_columns[1].amount_value = value
  else
    renoise.song().patterns[selected_pattern_index].tracks[selected_track_index].lines[selected_line_index].effect_columns[1]:clear()
  end

end

function set_fine_volumeslide(value)

  local command = nil
  
  local ret = nil
  
  if (value >= 0) then
    command = "0I"
  else
    command = "0O"
  end
  
  ret = bit.lshift( math.abs(value), 2)
  
  assign_effect(command, ret)

end

function set_fine_portamento(value)

  local command = nil
  
  local ret = nil
  
  if (value >= 0) then
    command = "0U"
  else
    command = "0D"
  end
  
  ret = math.abs(value)
  
  assign_effect(command, ret)

end

function show_volumeslide_status_message(value)
  local portamento_type = "Up"
  if value < 0 then portamento_type = "Down" end
  renoise.app():show_status(string.format("Volume Slide %s x%X", portamento_type, math.abs(value)))
end

function set_volumeslide(value)

  local reached_limit = false

  local tpl = renoise.song().transport.tpl
  
  local command = nil
  
  if (value >= 0) then
    command = "0I"
  else
    command = "0O"
  end
  
  local ret = bit.lshift ( (math.abs( value ) * (tpl - 1)), 2 )
  
  ret = math.abs (ret)
  
  if ret > 0xff then
    ret = bit.lshift( (ret / ret), 8) - 1    
    reached_limit = true
    show_message_inaccurate_value()    
  end
  
  assign_effect(command, ret)
  
  return (reached_limit == false)

end



function portamento_changed(value)

  value = math.floor(value)
    
  show_portamento_status_message(value)
  
  set_portamento(value)

end

function tempo_changed(value)

  renoise.app():show_status(string.format("Module tempo: %d", value))

end

function volume_changed(value)

  value = math.floor(value)
    
  show_volumeslide_status_message(value)
      
  set_volumeslide(value)
  
end

function fine_portamento_changed(value)

  value = math.floor(value)
    
  local message = 'Fine portamento '
  if value >= 0 then
    message = message .. 'Up '
  else
    message = message .. 'Down '
  end
  
  message = message .. string.format("x%X", math.abs(value))
  
  renoise.app():show_status(message)
  
  set_fine_portamento(value)
  
end

function fine_volumeslide_changed(value)

  value = math.floor(value)
    
  local message = 'Fine volume slide '
  if value >= 0 then
    message = message .. 'Up '
  else
    message = message .. 'Down '
  end
  
  message = message .. string.format("x%X", math.abs(value))
  
  renoise.app():show_status(message)
  
  set_fine_volumeslide(value)
  
end


local function get_effect_from_current_linecolumn()
  local selected_line_index = renoise.song().selected_line_index;
  
  local selected_pattern_index = renoise.song().selected_pattern_index
  
  local selected_track_index = renoise.song().selected_track_index

  local command = renoise.song().patterns[selected_pattern_index].tracks[selected_track_index].lines[selected_line_index].effect_columns[1].number_string
  
  local value = 
  renoise.song().patterns[selected_pattern_index].tracks[selected_track_index].lines[selected_line_index].effect_columns[1].amount_value
  
  local table = {command=command, value=value}
  
  return table;
  
end

local function get_portamento_value_from_current_linecolumn()
  
  local ret_table = get_effect_from_current_linecolumn()  
  
  local ret = 0;
  
  if ret_table['command'] == '0U' or ret_table['command'] == '0D' then
    
    local val = ret_table['value']
            
    local tpl = renoise.song().transport.tpl
    
    ret = math.floor( val / (tpl - 1) )
    
    if (ret_table['command'] == '0D') then
      ret = -ret
    end
            
  end
  
  return ret;
end

function portamento_up()
  local ret = get_portamento_value_from_current_linecolumn()
  ret = ret + 1
  local success = set_portamento(ret)  
  if success then
    show_portamento_status_message(ret)
  end
end

function portamento_down()
  local ret = get_portamento_value_from_current_linecolumn()
  ret = ret - 1
  local success = set_portamento(ret)
  if success then
    show_portamento_status_message(ret)
  end
end

local function get_volume_value_from_current_linecolumn()

  local ret_table = get_effect_from_current_linecolumn()  
  
  local ret = 0;
  
  if ret_table['command'] == '0I' or ret_table['command'] == '0O' then
    
    local val = ret_table['value']
            
    local tpl = renoise.song().transport.tpl
    
    ret = math.floor( bit.rshift(val / (tpl - 1), 2) )
    
    if (ret_table['command'] == '0O') then
      ret = -ret
    end
            
  end
  
  return ret;
  
end

function volume_down()
  local ret = get_volume_value_from_current_linecolumn()
  ret = ret - 1
  local success = set_volumeslide(ret)
  if success then
    show_volumeslide_status_message(ret)
  end
end

function volume_up()  
  local ret = get_volume_value_from_current_linecolumn()
  ret = ret + 1
  local success = set_volumeslide(ret)  
  if success then
    show_volumeslide_status_message(ret)
  end
end

