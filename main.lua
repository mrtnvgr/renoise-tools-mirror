-- Sample modulation device preset handler, save and load modulation device presets individually.

local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

local user_library --Path to user library for saving / loading presets.

local function load_settings_file()
  local settings_path = renoise.tool().bundle_path.."preferences.xml"
  local settings = renoise.Document.create("Preferences"){
    UserLibrary = renoise.Document.ObservableString()
  }
  settings:load_from(settings_path)
  user_library = settings.UserLibrary.value
  return settings, settings_path
end

--Check if directory exsits
function directory_exists(path) 
  if os.getenv("OS") == "Windows_NT" then
      return os.execute('cd "' .. path .. '"') == true
  else
      return os.execute('[ -d "' .. path .. '" ]') == true
  end
end

function make_new_folder(path)
  if os.getenv("OS") == "Windows_NT" then
    return os.execute('mkdir "' .. path .. '"')
  else
    return os.execute('mkdir -p "' .. path .. '"')
  end
end

function list_files(dir)
  local i, t, popen = 0, {}, io.popen
  local pfile

  if os.getenv("OS") == "Windows_NT" then
      pfile = popen('dir "' .. dir .. '\\*" /b /s /a-d')
  else
      pfile = popen('find "' .. dir .. '" -type f')
  end

  for filename in pfile:lines() do
      i = i + 1
      t[i] = filename
  end

  pfile:close()
  return t
end

--Make first characters of each word upper case
--and subsequent letters lower case
function capitalise_first_letters(str)          
  local space = true                
  return (str:gsub(".", function(c)
    if c == " " then
      space = true
      return c
    elseif space then
      space = false
      return c:upper()
    else
      return c:lower()
    end
  end))
end

--Remove file extension from string
function subtract_extension(filename)
  local idx = filename:match(".+()%.%w+$")
  if idx then
    return filename:sub(1, idx - 1)
  else
    return filename
  end
end

--Subtract / return first word before a space
function process_first_word(str) 
  --Find the first space
  local space = str:find(" ")    
  if space then
    --Remove first word and return srting
    return str:sub(space + 1),
    --Return first word in string
      str:sub(1, space - 1)      
  else                                             
    return str
  end
end

 --Remove spaces from string
function subtract_spaces(str) 
  return str:gsub("%s+", "")
end

--Prcoess string for preset title
function format_device_name(name) 
  name = process_first_word(name)
  local device_name = capitalise_first_letters(name)
  return subtract_spaces(device_name)
end 

--format number by digits after point
function format_number(num, digits) 
  digits = digits or 2 
  local format_string = string.format("%%.%df", digits)
  if num == math.floor(num) then --if whole number format as integer
    return string.format("%.0f", num)
  else
    return string.format(format_string, num)
  end
end

 --Match and return extension from full path
function get_file_extension(path)
  return path:match("^.+(%..+)$")
end

--Match and return filename from full path
function extract_filename(path)
  return path:match("([^/\\]+)$")
end

--Prepend value to strings in a list
function prepend_value_to_strings(list, value)
  local new_list = {}
  for i, string in ipairs(list) do
    new_list[i] = value .. string
  end
  return new_list
end

--Return the table key for existing values
function get_key_by_value(table, value)
  for key, val in pairs(table) do
    if val == value then
      return key
    end
  end
  return nil 
end

--Return string version of value from value index,
--used for preset file consistancy and readability
function get_string_by_index(title, index, table)
  local str_table = table[title]
  return str_table[math.abs(index)]
end

--Match nodes in filepath string and return table of strings 
function separate_path(filepath) 
  local path_separator = package.config:sub(1,1)
  local segments = {}
  for segment in string.gmatch(filepath, "[^" .. path_separator .. "]+") do
      table.insert(segments, segment)
  end
  return segments
end

local function prompt_load_path()
  local path = renoise.app():prompt_for_filename_to_read(
    {"*.xrmd", "*.xrmc", "*.xrmf"}, "Open Modulation Device Preset")
  if path and path ~= "" then
    load_preset(path)
  end
  return path
end

--initialise preset entries for device context menu 
local function init_presets_menu(path)
  if path then
    local files = list_files(path)
    for _, file in ipairs(files) do
      local segments = separate_path(file)
      local preset_name
      local sub_menu
      if segments[#segments - 3] == "Modulation Devices" then 
        preset_name = segments[#segments - 2].."/ "..segments[#segments - 1].."/ "..segments[#segments]
        sub_menu = "Device Presets "
      elseif segments[#segments - 2] == "Modulation Chains" then
        preset_name = segments[#segments - 1].."/ "..segments[#segments]
        sub_menu = "Device Chains"
      elseif segments[#segments - 1] == "Modulation Filters" then
        preset_name = segments[#segments]
        sub_menu = "Filter Presets"
      end
      if preset_name then
        preset_name = subtract_extension(preset_name)
        local entry = "Modulation Set List:"..sub_menu..":"..preset_name
        if not renoise.tool():has_menu_entry(entry) then
          renoise.tool():add_menu_entry {
            name = entry,
            invoke = function()
              load_preset(file)
            end
          }
        end
      end
    end
  end
end

local function prompt_to_set_library()
  renoise.app():show_message("Set directory for User Library, Modulation Device presets will be saved and loaded from here unless specified on save. If not set, default directory is the tool bundle directory.")
  local dir = renoise.app():prompt_for_path("Set User Library Directory")
  if not dir or dir == "" then
    renoise.app():show_message("User Library not set.")
    return ""
  end
  return dir
end


--Check if library set in settings.xml
local function check_if_library_set()
  local settings = load_settings_file()
  if settings.UserLibrary.value == nil or settings.UserLibrary.value == "" then
    return false
  else
    return true
  end
end

--Set directory for user library.
local function set_library_dir()

  local settings, settings_path = load_settings_file()

  user_library = prompt_to_set_library()

  if user_library and user_library ~= "" then
    settings.UserLibrary.value = user_library
    init_presets_menu(user_library)
    settings:save_as(settings_path)
  end

end

--Readable strings for preset value numbers.
local preset_value_strings = {
  ["PlayMode"] = {
    "Points",
    "Lines", 
    "Curves"
  },
  ["Operator"] = {
    "+",
    "-", 
    "*",
    "/"
  },
  ["LoopMode"] = {
    "Off",
    "Forward",
    "Backward",
    "PingPong"
  },
  ["Scaling"] = {
    "Log Fast",
    "Log Slow",
    "Linear",
    "Exp Slow",
    "Exp Fast"
  },
  ["Mode"] = {
    "Sin",
    "Saw",
    "Pulse",
    "Random"
  },
  ["Target"] = {
    "Volume",
    "Panning",
    "Pitch",
    "Cutoff",
    "Resonance",
    "Drive"
  }
}

local primary_attributes = {
  ["IsMaximized"] = "is_maximized",
  ["IsActive"] = "is_active",
  ["Target"] =  "target",
  ["Operator"] = "operator",
  ["Bipolar"] =  "bipolar",
  ["Name"] = "name",
  ["DisplayName"] = "display_name"
 }

local secondary_attributes = {
  ["Fader"] = {
    ["Scaling"] = "scaling"
  },
  --["VelocityTracking"] = {  --unknown property or function 'mode' for an object 
  --  ["Mode"] = "mode"       --of type 'SampleVelocityTrackingModulationDevice'
  --}
  ["Envelope"] = {
    ["SustainIsActive"] = "sustain_enabled",
    ["SustainPos"] = "sustain_position",
    ["LoopStart"] = "loop_start",
    ["LoopEnd"] = "loop_end",
    ["LoopMode"] = "loop_mode",
    ["PlayMode"] = "play_mode",
    ["Length"] = "length", --max value = 6144 (6.143s) but 16.38s in GUI??
    ["FadeAmount"] = "fade_amount"
  },
  ["LFO"] = {
    ["Mode"] = "mode"
  },
  ["Stepper"] = {
    ["PlayMode"] = "play_mode",
    ["StepAmount"] = "play_step",
    ["Length"] = "length"
  }
}


local preset_types = {
  "Device",
  "Chain",
  "Filter"
}

local preset_extensions = {
  ["Device"] = ".xrmd",
  ["Chain"] = ".xrmc",
  ["Filter"] = ".xrmf"
}


--create modulation devices list from available devices
function create_mod_device_list()
  local modset = renoise.song().selected_sample_modulation_set
  local available_devices = modset.available_devices
  for i, device in ipairs(available_devices) do
    available_devices[i] = device:gsub("Modulation/", "")
  end
  return available_devices
end

local targets = preset_value_strings["Target"]

-- encapsulated GUI function
local function gui_window(mode)
  local vb = renoise.ViewBuilder()
  local views = vb.views
  local song = renoise.song()
  local instruments = song.instruments
  local instrument = song.selected_instrument
  local modset = song.selected_sample_modulation_set
  local device
  local target = 1
  local preset_name = ""
  local device_visible = true
  local target_visible = false
  local mode_list = prepend_value_to_strings(preset_types, "Modulation ")
  local targets_list = preset_value_strings["Target"]
  local menu_width = 120

  if not mode then
    mode = "Device"--default to "device" mode
  end

  local available_devices = create_mod_device_list()

  local function get_current_instruments()
    local instrument_list = {}
    for i, instrument in ipairs(instruments) do
      local hex = string.format("%02X", (i - 1))
      local name = hex..": "..instrument.name
      if instrument.name == "" then
        name = hex..": (Untitled)"
      end
      table.insert(instrument_list, name)
    end
    return instrument_list
  end

  local function get_current_devices(modset)
    local device_list = {}
    local sorted_devices = {}
    if modset.devices then
      local targets = {}
      for i, device in ipairs(modset.devices) do

        if not targets[device.target] then
          targets[device.target] = {}
        end
        table.insert(targets[device.target], device)
      end
      for _, target in pairs(targets) do
        for v, dev in ipairs(target) do
          local _, target_string = process_first_word(dev.name)
          local idx = string.format("%02d", v)
          local title = target_string.." "..idx..": "..dev.display_name
            table.insert(device_list, title)
            table.insert(sorted_devices, dev)
        end
      end
    else
      device_list  = {"No Devices"}
    end
    return device_list, sorted_devices
  end
  

  local function get_current_modsets(instrument)
    local modset_list = {}
    local index
    if instrument.sample_modulation_sets then
      for i, set in ipairs(instrument.sample_modulation_sets) do
        index = string.format("%02d", i)
        modset_list[i] = index..": "..set.name
      end
    else
      modset_list[i]  = index..": No Modulation Sets"
    end
    return modset_list
  end

  local instrument_list = get_current_instruments()
  local modset_list = get_current_modsets(instrument)
  local device_list, sorted_devices = get_current_devices(modset)
  if #sorted_devices > 0 then
    device = sorted_devices[1]
  end


  local content = vb:column{
    margin = CONTROL_MARGIN,
    spacing = CONTROL_SPACING,

    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      vb:text{
        text = "Preset Type",
        style = "strong"
      },

      vb:popup{
        id = "preset_mode_menu",
        width = menu_width,
        value = 1,
        items = mode_list
      },
    },
    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      vb:text{
        text = "Preset Name",
        style = "strong"
      },

      vb:textfield{
        id = "preset_name_field",
        width = menu_width,
        notifier = function(str)
          preset_name = str
        end
      },
    },
          
    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      vb:text{
        style = "strong",
        text = "Instrument"
      },
      vb:popup{
        id = "instrument_menu",
        items = instrument_list,
        width = menu_width
      }
    },
    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      vb:text{
        style = "strong",
        text = "Modulation Set"
      },
      vb:popup{
        id = "modset_menu",
        items = modset_list,
        width = menu_width
      }
    },
    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      id = "device_aligner",
      visible = device_visible,
      vb:text{
        style = "strong",
        text = "Device"
      },
      vb:popup{
        width = menu_width,
        items = device_list,
        id = "device_menu"
      }
    },
    vb:horizontal_aligner{
      spacing = CONTROL_SPACING,
      mode = "justify",
      id = "target_aligner",
      visible = target_visible,
      vb:text{
        style = "strong",
        text = "Target"
      },
      vb:popup{
        id = "target_menu",
        items = targets_list,
        width = menu_width
      }
    },
    vb:horizontal_aligner{
      margin = CONTROL_MARGIN,
      spacing = CONTROL_SPACING,
      mode = "center",
      vb:button{
        id = "save_button",
        text = "Save Preset"
      },
      vb:button{
        id = "save_as_button",
        text = "Save Preset As..."
      }
    }
  }

  local dialog = renoise.app():show_custom_dialog(
    "Modulation Device Presets", content
  )


  local function update_name(mode, device, target)
    local name = ""
    if mode == "Device" and device then
      name = device.display_name
    elseif mode == "Chain" then
      local target_table = preset_value_strings["Target"]
      local target_string = target_table[math.abs(target)]
      name = target_string.." "..mode
    elseif mode == "Filter" then
      name = "Modulation Filter"
    end
    preset_name = name
    views.preset_name_field.value = name
  end

  local function update_instrument_list()
    instrument_list = get_current_instruments()
    views.instrument_menu.items = instrument_list
  end
  
  local function update_instrument(ins_idx)
    if not ins_idx then
      ins_inx = song.selected_instrument_index
    end
    instrument = instruments[ins_idx]
  end

    
  local function update_device_list()
    device_list, sorted_devices = get_current_devices(modset)
    views.device_menu.items = device_list
    return sorted_devices
  end

  local function update_device(dev_idx)
    if modset.devices then
      device = sorted_devices[dev_idx]
    end
    update_name(mode, device, target)
  end

  local function device_listener()
    sorted_devices = update_device_list()
    update_device(views.device_menu.value)
  end

  local function update_modset_list()
    modset_list = get_current_modsets(instrument)
    views.modset_menu.items = modset_list
  end

  local function update_modset(sms_idx)
    if not sms_idx then
      sms_idx = song.selected_sample_modulation_set_index
    end
    modset = instrument.sample_modulation_sets[sms_idx]
  end

  local function initiate_save(save_method)
    local path
    if save_method == "Library" then
      path = user_library
    end

    if not device and mode == "Device" then
      renoise.app():show_message("Select Device...")
      return
    else
      if not preset_name or preset_name == "" then
        renoise.app():show_message("Enter Preset Name...")
      else
        if mode == "Device" then
          save_preset(mode, modset, device, preset_name, path)
        elseif mode == "Chain" then
          save_preset(mode, modset, {target}, preset_name, path)
        elseif mode == "Filter" then
          save_preset(mode, modset, {4,5,6}, preset_name, path)
        end
      end
    end
  end

  song.instruments_observable:add_notifier(function()
    update_instrument_list()
    update_instrument()
    update_modset_list(instrument)
    update_modset()
    sorted_devices = update_device_list(modset)
    update_device(views.device_menu.value )
  end)


  song.selected_instrument_index_observable:add_notifier(function()
    local ins_idx = song.selected_instrument_index
    local sms_idx = song.selected_sample_modulation_set_index
    instrument = instruments[ins_idx]
    views.instrument_menu.value = ins_idx
    update_modset_list(instrument)
    views.modset_menu.value = sms_idx
    update_modset(sms_idx)
    if not modset.devices_observable:has_notifier(device_listener) then
      modset.devices_observable:add_notifier(device_listener)
    end
    sorted_devices = update_device_list(modset)
    update_device(views.device_menu.value)
  end)

  song.selected_sample_modulation_set_observable:add_notifier(function()
    local sms_idx = song.selected_sample_modulation_set_index
    local ins_idx = song.selected_instrument_index
    instrument = instruments[ins_idx]
    update_modset_list(instrument)
    modset = instrument.sample_modulation_sets[sms_idx]
    views.modset_menu.value = sms_idx
    sorted_devices = update_device_list(modset)
    update_device(views.device_menu.value)
  end)

  views.instrument_menu:add_notifier(function(ins_idx)
    instrument = instruments[ins_idx]
    song.selected_instrument_index = ins_idx
    update_modset_list(instrument)
    update_modset()
    sorted_devices = update_device_list(modset)
    update_device(views.device_menu.value)
  end)

  views.modset_menu:add_notifier(function(sms_idx)
    modset = instrument.sample_modulation_sets[sms_idx]
    song.selected_sample_modulation_set_index = sms_idx
    sorted_devices = update_device_list(modset)
    update_device(views.device_menu.value)
  end)

  views.device_menu:add_notifier(function(dev_idx)
    if modset.devices then
      device = sorted_devices[dev_idx]
    end
    update_name(mode, device, target)
  end)


  local function toggle_mode(mode)
    if mode == "Device" then
      device_visible = true
      target_visible = false
      views.device_aligner.visible = device_visible
      views.target_aligner.visible = target_visible
    elseif mode == "Chain" then
      device_visible = false
      target_visible = true
      views.device_aligner.visible = device_visible
      views.target_aligner.visible = target_visible
    elseif mode == "Filter" then
      device_visible = false
      target_visible = false
      views.device_aligner.visible = device_visible
      views.target_aligner.visible = target_visible
    end
  end

  views.preset_mode_menu:add_notifier(function(value)
    mode = preset_types[value]
    toggle_mode(mode)
    update_name(mode, device, target)
  end)

  views.target_menu:add_notifier(function(val)
    target = val
    update_name(mode, device, target)
  end)

  views.save_button:add_released_notifier(function()
    initiate_save("Library")
  end)

  views.save_as_button:add_released_notifier(function()
    initiate_save("Save As")
  end)

  toggle_mode(mode)
  local mode_int = get_key_by_value(preset_types, mode)
  views.preset_mode_menu.value = mode_int
  update_name(mode, device, target)

end

-- Add generic device properties to document
function add_properties(device, doc, properties)
  for title, property in pairs(properties) do
    if preset_value_strings[title] then
      local value = device[property]
      local string_table = preset_value_strings[title]
      local value_string = string_table[math.abs(value)]
      doc:add_property(title, value_string)
    else
      doc:add_property(title, device[property])
    end
  end
  return doc
end

-- Add point to Envelope and Stepper points
function add_points(points, doc)
  for i, point in ipairs(points) do
    local point_strings = {
      tostring(point.time),
      tostring(point.value),
      tostring(point.scaling)
    }
    doc:add_property("Point"..i, table.concat(point_strings, ","))
  end
  return doc
end

-- Add properties that are unique to device
function add_secondary_attributes(device, doc)
  local device_name = process_first_word(device.name)
  if secondary_attributes[device_name] then
    add_properties(device, doc, secondary_attributes[device_name])
  end
  return doc
end

-- Add parameters to document
function add_parameters(device, doc)
  local parameters = device.parameters
  for i = 1, #parameters do
      local name = parameters[i].name:gsub("%s+", "")
      doc:add_property(name, parameters[i].value)
  end
  return doc
end

-- Individual device node for preset document
class "Device"(renoise.Document.DocumentNode)
  function Device:__init(device)
    renoise.Document.DocumentNode.__init(self)
    local device_name = format_device_name(device.name)
    add_properties(device, self, primary_attributes)
    if device.tempo_sync_switching_allowed then
      self:add_property("TempoSynced", device.tempo_synced) 
    end
    add_secondary_attributes(device, self)
    add_parameters(device, self)
    if device_name == "Envelope" or device_name == "Stepper" then
      self:add_property("Points", #device.points)
      add_points(device.points, self)
    end
  end

-- Return devices for specicfied target
function get_target_devices(mod_set, targets)
  local devices = {}
  if mod_set.devices then
    for _, device in ipairs(mod_set.devices) do
      for _, target in ipairs(targets) do
        if device.target == target then
          table.insert(devices, device)
        end
      end
    end
  end
  return devices
end
    
-- Return devices from target
function get_devices(mode, mod_set, target)
  local devices = {}
  if mode == "Device" then
    table.insert(devices, target)
  else
    devices = get_target_devices(mod_set, target)
  end
  return devices
end

-- Add device nodes to preset document 
function add_devices(preset, devs_node, devices)
  for i, device in ipairs(devices) do
    local device_name = format_device_name(device.name)
    local node_title = "Sample"..device_name.."ModulationDevice"
    local device_node = Device(device)
    devs_node:add_property(node_title..i, device_node)
  end
  preset:add_property("Devices", devs_node)
  return preset
end

function add_filter(mod_set, devs_node, preset)
  local pre_title = "SampleModulation"
  local mixer = renoise.Document.create(pre_title.."MixerDevice"){
    Cutoff = mod_set.cutoff_input.value,
    Resonance = mod_set.resonance_input.value,
    Drive = mod_set.drive_input.value
  }
  devs_node:add_property(pre_title.."MixerDevice", mixer)
  preset:add_property("FilterBankVersion", mod_set.filter_version)
  preset:add_property("FilterType", mod_set.filter_type)
  return preset
end

function create_preset(mode, devices, mod_set, name)
  local pre_title = "SampleModulation"
  local preset_title = pre_title..mode.."Preset"
  local preset = renoise.Document.create(preset_title){}
  local devs_node = renoise.Document.create("Devices"){}

  if not name then
    if devices and mode == "Device" then
      name = devices[1].display_name
    elseif devices and mode == "Chain" then
      local targets_table = preset_value_strings["Target"] 
      local target_string = targets_table[devices[1].target]
      name = "Sample Modulation "..target_string.." Chain"
    elseif mode == "Filter" then
      name = "Sample Modulation Filter Preset"
    end
  end

  preset:add_property("PresetName", name)

  if mode == "Filter" then
    preset = add_filter(mod_set, devs_node, preset)
  end

  if devices then
    preset = add_devices(preset, devs_node, devices)
  end

  return preset
end

function save_preset(mode, mod_set, target, name, dir)
  local ext = preset_extensions[mode]
  local devices = get_devices(mode, mod_set, target)
  local preset = create_preset(mode, devices, mod_set, name)
  local dest_path, success

  if #devices == 0 and mode == "Chain" then
    renoise.app():show_message("No devices to save chain.")
  else

    if dir then
      local folder = "Modulation "..mode.."s"
      local targets_table = preset_value_strings["Target"]
      local target_string = targets_table[devices[1].target]
      if #devices > 0 and mode == "Device" then
        local device_type = process_first_word(devices[1].name)
        folder = folder.."/"..target_string.."/"..device_type
      elseif #devices > 0 and mode == "Chain" then
        folder = folder.."/"..target_string
      elseif mode == "Filter" then
      else
        renoise.app():show_message("No present devices.")
        return false
      end
      local dest_dir = dir..folder
      --local dir_exsists = dir_exsists(dest_dir)
      if not directory_exists(dest_dir) then
        make_new_folder(dest_dir)
      end
      dest_path = dest_dir.."/"..name..ext
    else
      dest_path = renoise.app():prompt_for_filename_to_write(
      ext, "Save "..mode.." Preset As")
    end

    if dest_path and dest_path ~= "" then
      success = preset:save_as(dest_path)
      renoise.app():show_status(
        "Modulation "..mode.." Preset successfully saved.")
    end

  end

  return success
end

-- Return device index from device type 
function get_device_ref(device_type)
  local available_devices = create_mod_device_list()
  local device_num
  for i = 1, #available_devices do
    if string.match(available_devices[i], device_type) then
      device_num = i --index for "available devices"
    end
  end
  return device_num
end


-- Add device to mod set target
function insert_device(mod_set, device_ref, target)
  local new_device = mod_set:insert_device_at(
    mod_set.available_devices[device_ref], 
    target, #mod_set.devices + 1
  )
  return new_device
end

-- Set filter values from preset
function apply_filter(preset, mod_set)
  local mixer = preset.Devices.SampleModulationMixerDevice
  mod_set.filter_type = preset.FilterType.value
  mod_set.cutoff_input.value = mixer.Cutoff.value
  mod_set.resonance_input.value = mixer.Resonance.value
  mod_set.drive_input.value = mixer.Drive.value
end 

-- Load and initialize device before applying preset
function init_new_devices(mod_set, devices_info)
  local devices = {}
  for i = 1, #devices_info do
    local device = devices_info[i]
    local device_type = device.device_type
    local target = device.target
    local num_points = device.num_points
    local device_ref = get_device_ref(device_type)
    local new_device = insert_device(mod_set, device_ref, target)
    table.insert(devices, new_device)
  end
  return devices
end

-- Apply preset properties after device initialized
function apply_attr(device, node, properties)
  for title, property in pairs(properties) do
    if title ~= "Name" and title ~= "Target" then
      if preset_value_strings[title] then
        local targets_table = preset_value_strings[title]
        local target_index = get_key_by_value(targets_table, node[title].value)
        device[property] = target_index
      else
        device[property] = node[title].value
      end
    end
  end
end

-- Apply unqiue device preset properties
function apply_specifics(device, node, device_name)
  if node.Points then
    device.length = node.Length.value
    set_points(device, node)
  end
  if secondary_attributes[device_name] then
    apply_attr(device, node, secondary_attributes[device_name])
  end
end

--Apply preset paramter values to device
function apply_parameter_values(device, node)
  for i = 1, #device.parameters do
    local name = device.parameters[i].name:gsub("%s+", "")
    device.parameters[i].value = node[name].value
  end
end

--Apply the full preset
function apply_preset(devices, preset)
  for i, device in ipairs(devices) do
    local device_name = format_device_name(device.name)
    local device_type = process_first_word(device.name)
    local device_title = "Sample"..device_name.."ModulationDevice"..i
    local node = preset.Devices[device_title]
    apply_attr(device, node, primary_attributes)
    if device.tempo_sync_switching_allowed then
      device.tempo_synced = node.TempoSynced.value
    end
    apply_specifics(device, node, device_type)
    apply_parameter_values(device, node)
  end
end

-- Add points to Envelope / Stepper before setting preset values
function init_points(devices, preset, devices_info)
  for i = 1, #devices do
    local device_name = format_device_name(devices[i].name)
    local device_type = process_first_word(devices[i].name)
    local device_title = "Sample"..device_name.."ModulationDevice"..i
    if device_type == "Envelope" or device_name == "Stepper" then
      local device_node = preset.Devices[device_title]
      device_node.Points.value = devices_info[i].num_points
      for p = 1, devices_info[i].num_points do
        device_node:add_property("Point"..p, "0, 0, 0")
      end
    end
  end
end

-- Apply preset values to points
function set_points(device, doc)
  device:clear_points()
  local arg = "([%d%.]+),([%d%.]+),(-?[%d%.]+)"
  for i = 1, doc.Points.value do
    local point = doc["Point"..i].value
    local time, value, scaling = string.match(point, arg)
    device:add_point_at(tonumber(time), tonumber(value), tonumber(scaling))
  end
end



function get_device_info(file)
  local devices = {}
  local index = 0

  for line in file:lines() do
    if string.match(line, "<Name>(.-)</Name>") then
      index = index + 1
      devices[index] = {}
      local device_type = string.match(line, "<Name>(.-)</Name>")
      device_type = process_first_word(device_type)
      devices[index].device_type = device_type
    end
    if string.match(line, "<Target>(.-)</Target>") then
      local target = string.match(line, "<Target>(.-)</Target>")
      local targets_table = preset_value_strings["Target"]
      local target_index = get_key_by_value(targets_table, target)
      devices[index].target = target_index
    end
    if string.match(line, "<Points>(.-)</Points>") then
      local num_points = tonumber(string.match(line, "<Points>(.-)</Points>"))
      devices[index].num_points = tonumber(num_points)
    end
  end
  file:close()
  return devices
end

function load_preset(path)

  local mod_set = renoise.song().selected_sample_modulation_set
 
  if not path then
    path = renoise.app():prompt_for_filename_to_read(
      {"*.xrmd", "*.xrmc", "*.xrmf"}, "Open Modulation Preset File")

      if path == "" then
        renoise.app():show_message("Preset not loaded as path not set.")
      end
  end

  local ext = get_file_extension(path)
  local mode = get_key_by_value(preset_extensions, ext)
  
  local file = io.open(path, 'r')

  local devices_info = get_device_info(file)
  local new_devices = init_new_devices(mod_set, devices_info)
  local preset = create_preset(mode, new_devices, mod_set)

  init_points(new_devices, preset, devices_info)
  local success 
  if preset then
    success = preset:load_from(path)
    if success then
      apply_preset(new_devices, preset)
      if mode == "Filter" then
        apply_filter(preset, mod_set)
      end
    end
  end
  return success
end


renoise.tool():add_menu_entry{name="Sample Modulation Matrix:Load Device/Filter Preset...",invoke=prompt_load_path}
renoise.tool():add_menu_entry{name="Sample Modulation Matrix:Save Device...",invoke=function() gui_window("Device") end}
renoise.tool():add_menu_entry{name="Sample Modulation Matrix:Save Filter As...",
  invoke=function()
    local modset = renoise.song().selected_sample_modulation_set
    save_preset("Filter", modset, {4,5,6}) end}

renoise.tool():add_menu_entry{name="Modulation Set:Load Device/Filter Preset...",invoke=prompt_load_path}
renoise.tool():add_menu_entry{name="Modulation Set:Save Device...",invoke=function() gui_window("Device") end}
renoise.tool():add_menu_entry{name="Modulation Set:Save Filter As...",invoke=function()
    local modset = renoise.song().selected_sample_modulation_set
    save_preset("Filter", modset, {4,5,6}) end}

renoise.tool():add_menu_entry{name="Modulation Set List:Load Preset...",invoke=prompt_load_path}
renoise.tool():add_menu_entry{name="Main Menu:Tools:Modulation Device Presets:Save Preset...",invoke=function() gui_window() end}

renoise.tool():add_menu_entry{name="Main Menu:Tools:Modulation Device Presets:Set User Library Directory",invoke=function() set_library_dir() end}

renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Load Device/Filter Preset",invoke=prompt_load_path}
renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Save Device",invoke=function() gui_window("Device") end}
renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Save Filter As",invoke=function()
  local modset=renoise.song().selected_sample_modulation_set
  save_preset("Filter",modset,{4,5,6}) end}

renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Load Preset",invoke=prompt_load_path}
renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Save Preset",invoke=function() gui_window() end}

renoise.tool():add_keybinding{name="Global:Modulation Device Presets:Set User Library Directory",invoke=function() set_library_dir() end}




renoise.tool():add_file_import_hook {
  category = "modulation set",
  extensions = {"xrmd", "xrmc", "xrmf"},
  invoke = load_preset
}

local library_exists = check_if_library_set()

if library_exists then
  init_presets_menu(user_library)
end
