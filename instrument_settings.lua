require "ini_handler"
require "instrument_settings_gui"

MIN_SAMPLE_RATE = 8363
MAX_SAMPLE_RATE = 96000
DEFAULT_VOLUME = 64
DEFAULT_FREQUENCY = 'Low'
DEFAULT_SINC = 2

SAMPLE_FREQUENCY_LOW = 1
SAMPLE_FREQUENCY_HIGH = 2
SAMPLE_FREQUENCY_MAXIMUM = 3
SAMPLE_FREQUENCY_ORIGINAL = 4
SAMPLE_FREQUENCY_CUSTOM = 5
SAMPLE_FREQUENCY_BASENOTE = 6

instrument_settings = {}

base_notes = {}

frequency_settings_alias = {"Low", "High", "Maximum", "Original", "Custom", "Base note"}

local function get_ini_filename()

  local output = ''
  
  if renoise.song().file_name ~= '' then
  
    local separator = get_separator()
  
    local app_path_folder = get_path(app_path)
    
    local song_filename = string.match(renoise.song().file_name, "[^".. separator .. "]*$")
    
    local ini_file = string.gsub(song_filename, ".xrns", ".ini")
    
    local arr_path = {app_path_folder, 'ini', ini_file}
    
    output = concatenate_path(arr_path)
  
  end  
  
  return output
  
end

function open_settings_folder()

  local ini_file = get_ini_filename()

  if io.exists(ini_file) then
    renoise.app():open_path(ini_file);
  else
  
    local app_path = get_path(app_path)
    
    local ini_folder = concatenate_path({app_path, 'ini'})
    
    renoise.app():open_path(ini_file);    
    
  end

end




function set_instrument_volume(ki, ks, value)

  if instrument_settings[ki][ks] ~= nil then
    instrument_settings[ki][ks]['default_volume'] = value
  end 

end

function set_instrument_sinc(ki, ks, value)

  if instrument_settings[ki][ks] ~= nil then
    instrument_settings[ki][ks]['sinc'] = (value-1)
  end 

end

function set_instrument_basenote(ki, ks, index)

  if instrument_settings[ki][ks] ~= nil then      
    print('set_instrument_basenote: ' .. base_notes[index])    
    instrument_settings[ki][ks]['frequency'] = base_notes[index]
    print ('instrument settings saved: ' .. instrument_settings[ki][ks]['frequency'])
  end

end

function set_instrument_frequency_alias(ki, ks, index)

  if instrument_settings[ki][ks] ~= nil then      
    print('set_instrument_frequency_alias: ' .. frequency_settings_alias[index])
    instrument_settings[ki][ks]['frequency'] = frequency_settings_alias[index]
    print ('instrument settings saved: ' .. instrument_settings[ki][ks]['frequency'])
  end

end

function set_instrument_frequency(ki, ks, value)

  if instrument_settings[ki][ks] ~= nil then  
    print('set_instrument_frequency: ' .. value)
    instrument_settings[ki][ks]['frequency'] = value            
    print ('instrument settings saved: ' .. instrument_settings[ki][ks]['frequency'])
  end

end





function save_ini_settings()
  
  local conf = { }
  conf['volume'] = { }
  conf['frequency'] = { }
  conf['sinc'] = { }
  
  for ki, vi in ipairs(renoise.song().instruments) do
  
    for ks, vs in ipairs(renoise.song().instruments[ki].samples) do
    
      if renoise.song().instruments[ki].samples[ks].sample_buffer.has_sample_data then
        
        local vol = instrument_settings[ki][ks]['default_volume']
        local freq = instrument_settings[ki][ks]['frequency']
        local sinc = instrument_settings[ki][ks]['sinc']
        
        local key = tostring( (ki - 1) .. '/' .. (ks - 1))
        
        if vol ~= DEFAULT_VOLUME then          
            conf['volume'][key] = vol
        end
        
        if freq ~= DEFAULT_FREQUENCY then
            conf['frequency'][key] = freq
        end     
        
        if sinc ~= DEFAULT_SINC then
            conf['sinc'][key] = sinc
        end     
        
      end
      
    end
    
  end
  
  rprint(conf)
  
  local ini_file = get_ini_filename()
  
  if ( (table.is_empty( conf['volume']) and 
        table.is_empty(conf['frequency']) and
        table.is_empty(conf['sinc']))  == false ) then
    
    renoise.app():show_status('Settings saved to ' .. ini_file)
    save_configuration(ini_file, conf)
    
  else
    
    os.remove(ini_file)
    renoise.app():show_status("No settings to save, file " .. ini_file .. " was removed")
    
  end
  
end


function exists_sample_frequency_key( instr_index, sample_index)

  return instrument_settings[instr_index] ~= nil and instrument_settings[instr_index][sample_index] ~= nil  
  
end


function exists_sample_frequency_key( instr_index, sample_index)
  return instrument_settings[instr_index] ~= nil and instrument_settings[instr_index][sample_index] ~= nil
  
end


function load_instrument_sinc( instr_index, sample_index)  

  local default_value = DEFAULT_SINC-1

  if instrument_settings[instr_index][sample_index] == nil then
    return DEFAULT_SINC
  end  
  
  local value = instrument_settings[instr_index][sample_index]['sinc']
  
  return (tonumber( value ) + 1)
  
end

function load_instrument_volume( instr_index, sample_index)  

  if instrument_settings[instr_index][sample_index] == nil then
    return DEFAULT_VOLUME
  end  
  
  local value = instrument_settings[instr_index][sample_index]['default_volume']
    
  return tonumber( value )

end


function load_instrument_basenote( instr_index, sample_index)  

  print('load_instrument_basenote')

  local default_value = table.find(base_notes, 'C-2')

  if instrument_settings[instr_index][sample_index] == nil then
    return default_value
  end  

  local value = instrument_settings[instr_index][sample_index]['frequency']

  local strvalue = tostring( value )
  
  print('cur_val:' .. strvalue)

  if strvalue ~= nil and strvalue:match('^[A-Ga-g][-#][2-3]$') then  
    return table.find(base_notes, strvalue)
  elseif strvalue == 'Low' then
    return default_value
  elseif strvalue == 'High' then
    return table.find(base_notes, 'C-3')
  elseif strvalue == 'Maximum' then
    return table.find(base_notes, 'B-3')
  end

  return default_value

end



function load_instrument_frequency( instr_index, sample_index)

  print('load_instrument_frequency')

  local default_value = SAMPLE_FREQUENCY_LOW

  if instrument_settings[instr_index][sample_index] == nil then
    return default_value
  end  
  
  local value = instrument_settings[instr_index][sample_index]['frequency']
  
  local strvalue = tostring(value)
  
  print("cur value: " .. strvalue)
  
  if strvalue:match('^[0-9]') then  
    return SAMPLE_FREQUENCY_CUSTOM
  elseif strvalue:match('^[A-Ga-g][-#][2-5]$') then  
    return SAMPLE_FREQUENCY_BASENOTE   
  elseif strvalue == 'Low' then  
    return SAMPLE_FREQUENCY_LOW
  elseif strvalue == 'High' then  
    return SAMPLE_FREQUENCY_HIGH
  elseif strvalue == 'Maximum' then
    return SAMPLE_FREQUENCY_MAXIMUM
  elseif strvalue == 'Original' then  
    return SAMPLE_FREQUENCY_ORIGINAL
  end
  
  return default_value

end


function load_instrument_frequency_rate( instr_index, sample_index)  

  print('load_instrument_frequency_rate')

  if instrument_settings[instr_index][sample_index] == nil then
    return MIN_SAMPLE_RATE
  end  
  
  local default_value = renoise.song().instruments[instr_index].samples[sample_index].sample_buffer.sample_rate

  local value = instrument_settings[instr_index][sample_index]['frequency']
  
  local output = tonumber(value)

  print("cur value: " .. value)
  
  if output ~= nil then  
    return output
  else   -- not a number
    return default_value
  end

end



function get_samples(instr_index)

  local output = { }

  for k, v in ipairs(renoise.song().instruments[instr_index].samples) do
    output[k] = v.name
  end
  
  return output

end



function get_sample_frequency_settings()
  
  return frequency_settings_alias
  
end


function get_sinc_values()

  return { 'Linear', '8 pt sinc', '16 pt sinc', '32 pt sinc' }

end

function get_base_note()
  
  local output_notes = {}

  for i=2,3 do 
    for k, v in ipairs(NOTES_TABLE) do
      table.insert(output_notes, ("%s%s"):format(v,i))
    end 
  end

  base_notes = output_notes
  
  return output_notes

end

function get_instrument_names()
  
  local output = { }
    
  for k, v in ipairs(renoise.song().instruments) do
    output[k] = v.name
  end
  
  return output  

end


local function init_instrument_settings(conf)
  
  
  if conf['volume'] == nil then
    conf['volume'] = { }
  end
   
  if conf['frequency'] == nil then
    conf['frequency'] = { }
  end   
  
  if conf['sinc'] == nil then
    conf['sinc'] = { }
  end
  
  for ki, vi in ipairs(renoise.song().instruments) do
  
    instrument_settings[ki] = { }
  
    for ks, vs in ipairs(renoise.song().instruments[ki].samples) do    
    
      if renoise.song().instruments[ki].samples[ks].sample_buffer.has_sample_data then
        
        instrument_settings[ki][ks] = { }
      
        instrument_settings[ki][ks]['default_volume'] = DEFAULT_VOLUME      
        --instrument_settings[ki][ks]['frequency'] = renoise.song().instruments[ki].samples[ks].sample_buffer.sample_rate
        instrument_settings[ki][ks]['frequency'] = DEFAULT_FREQUENCY
        instrument_settings[ki][ks]['sinc'] = DEFAULT_SINC 
        
        local c_vol = conf['volume']
        local c_freq = conf['frequency']
        local c_sinc = conf['sinc']
        
        local key = tostring( (ki - 1) .. '/' .. (ks - 1))
        
        if c_vol[key] ~= nil then
          instrument_settings[ki][ks]['default_volume'] = c_vol[key]        
        end
        
        if c_freq[key] ~= nil then
          instrument_settings[ki][ks]['frequency'] = c_freq[key]        
        end
        
        if c_sinc[key] ~= nil then
          instrument_settings[ki][ks]['sinc'] = c_sinc[key]        
        end
        
      end
          
    end
    
  end
  
  --rprint(instrument_settings)
  
end

function reset_instrument_values(ki, ks)

  if instrument_settings[ki][ks] ~= nil then
    instrument_settings[ki][ks]['default_volume'] = DEFAULT_VOLUME      
    instrument_settings[ki][ks]['frequency'] = DEFAULT_FREQUENCY
    instrument_settings[ki][ks]['sinc'] = DEFAULT_SINC
  end
  
  renoise.app():show_status('Sample settings reset to its default value ')

end

function reset_instrument_settings()

  local conf = { }

  init_instrument_settings(conf)
  
  renoise.app():show_status('All Samples were reset to default values')

end

function load_ini_settings(show_warn)
  
  local ini_file = get_ini_filename()
  
  local conf = { }
  
  if (io.exists(ini_file)) then
     
     conf = load_configuration(ini_file)
     
     renoise.app():show_status('Settings loaded from ' .. ini_file)
     
  else
    if show_warn then
      renoise.app():show_status("Warning: settings not found")
    end
  end  
  
  init_instrument_settings(conf)
  
end


function init_instrument_settings_dialog()
    
  if converter_dialog and converter_dialog.visible then
    converter_dialog:close()
  end
  
  if helper_dialog and helper_dialog.visible then
    helper_dialog:close()
  end
  
  if downgrade_dialog and downgrade_dialog.visible then
    downgrade_dialog:close()
  end
  
  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel_dialog:close()
  end  
  
  if renoise.song().file_name ~= '' then
    local ini_file = get_ini_filename()
  
    local conf = { }
    
    if (io.exists(ini_file)) then
       
       conf = load_configuration(ini_file)
       
    end  
    
    init_instrument_settings(conf)
    
    show_instrument_settings_dialog()
    
  else    
    renoise.app():show_error(MSG_SONG_NOT_SAVED);
    return  
  end
  
end
