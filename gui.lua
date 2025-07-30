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
      "Sample Modulation Presets", content
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