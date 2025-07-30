--[[============================================================================
com.duncanhemingway.LoopMarkerAutomation.xrnx (main.lua)
============================================================================]]--

--------------------------------------------------------------------------------
-- global declarations
--------------------------------------------------------------------------------

s = 0
si = 0
rxi = 0
rxs = 0
rxc1 = 0
rxc2 = 0
rxc3 = 0
rxc4 = 0
leftover = 0
snapback = 0
flip_snap = 0
flip_resize = 0
rxdata = {}
bypass = true
the_gui = nil
vb = renoise.ViewBuilder()

--------------------------------------------------------------------------------
-- menu entry
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Loop Marker Automation",
  invoke = function()
    s = renoise.song()
    si = s.selected_instrument_index
    vb.views.instr.value = si
    if vb.views.instr.value == 1 then change_gui_values() end -- need to trigger manually when the value hasn't been changed
    if not the_gui or not the_gui.visible then
      the_gui = renoise.app():show_custom_dialog("Loop Marker Automation", dialog_content)
    end
  end
}

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- rounding float values

function round(value)
  return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end

-- remove non-numbers from string (can't +1 them)

function remove_non_numbers(str)
  str = str:gsub('%D+','')
  if str == "" then return
  else return tonumber(str + 1) end
end

-- convert values to/from Hydra

function value_to_hydra(hydra, parameter, num)
  if parameter < 5 then num = num - 1 end
  num = tostring(num)
  while #num < 11 do num = "0" .. num end
  hydra:parameter(parameter * 5).value     = string.sub(num, 1, 6)  / 100000
  hydra:parameter(parameter * 5 + 1).value = string.sub(num, 7, 11) / 100000
end

function value_from_hydra(hydra, parameter)
  local num = round(hydra:parameter(parameter * 5).value * 100000) * 100000 + round(hydra:parameter(parameter * 5 + 1).value * 100000) -- needs to be '100000) * 100000' to prevent rounding errors
  if parameter < 5 then num = num + 1 end
  return num
end

-- adjust step values for slider buttons

function set_slider_steps(value, se)
  if value > 25 then vb.views["slider_" .. se].steps = {0.01, 0.1}
  else
    if value < 26 then vb.views["slider_" .. se].steps = {0.02, 0.1}  end
    if value < 13 then vb.views["slider_" .. se].steps = {0.04, 0.14} end
    if value < 7  then vb.views["slider_" .. se].steps = {0.12, 0.2}  end
    if value < 3  then vb.views["slider_" .. se].steps = {0.3, 0.3}   end
  end
end

-- get sample volume from channel at position

function sample_volume(rx, channel, position)
  position = math.max(1, position) -- protect against values out of bounds
  return rx.sample.sample_buffer:sample_data(channel, position) * 100
end

-- add and remove notifiers

function add_notifier(observable, notifier, object)
  if object == nil then
    if not observable:has_notifier(notifier) then observable:add_notifier(notifier) end
  else
    if not observable:has_notifier(notifier, object) then observable:add_notifier(notifier, object) end
  end
end

function remove_notifier(observable, notifier, object)
  if object == nil then
    if observable:has_notifier(notifier) then observable:remove_notifier(notifier) end
  else
    if observable:has_notifier(notifier, object) then observable:remove_notifier(notifier, object) end
  end
end

-- find an instrument's full rxdata

function find_rxdata(instrument)
  for _, rx in pairs(rxdata) do
    if rawequal(instrument, rx.instrument) then return rx end
  end
end

-- has the instrument been LMA-ed and if so what are the fx chain and devices

rxed_details = function(instrument)
  local xypad   = nil
  local doofer1 = nil
  local doofer2 = nil
  local hydra   = nil
  if instrument == nil then instrument = rxi end
  for _, fx_chain in pairs(instrument.sample_device_chains) do -- checking the current array of fx chains, since this may have changed after adding the no_delete_devices notifier
    if fx_chain.name == "Loop Marker Automation" and #instrument.samples == 3 and #instrument:sample(1).slice_markers == 2 then
      for _, device in pairs(fx_chain.devices) do -- checking the current array of devices, since this may have changed after adding the no_delete_devices notifier
        if device.display_name == "LMA Positions"         then xypad   = device end
        if device.display_name == "LMA Origins & Ranges"  then doofer1 = device end
        if device.display_name == "LMA Other Controls"    then doofer2 = device end
        if device.display_name == "DON'T CHANGE/AUTOMATE" then hydra   = device end
      end
      if xypad ~= nil and doofer1 ~= nil and doofer2 ~= nil and hydra ~= nil then return true, fx_chain, xypad, doofer1, doofer2, hydra end
    end
  end
end

-- change instrument name in GUI

change_display_name = function()
  if rxi.name ~= "" then vb.views.instr_name.text = rxi.name
  else                   vb.views.instr_name.text = "Untitled"
  end
end

-- work out what to do when changing slice size

function changing_ss(rx, value)
  local slice_size = value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1)
  value = math.max(value, value_from_hydra(rx.hydra, 7))
  if     rx.doofer2:parameter(3).value < 33 then move_markers("e_slice_size", value_from_hydra(rx.hydra, 1) + value, value_from_hydra(rx.hydra, 2), rxdata[rx.n])
  elseif rx.doofer2:parameter(3).value > 66 then move_markers("s_slice_size", value_from_hydra(rx.hydra, 2) - value, value_from_hydra(rx.hydra, 1), rxdata[rx.n])
  else
    if rx.doofer2:parameter(6).value > 0 then
      if flip_snap == 0 then move_markers("s_slice_size", value_from_hydra(rx.hydra, 2) - value, value_from_hydra(rx.hydra, 1), rxdata[rx.n])
      else                   move_markers("e_slice_size", value_from_hydra(rx.hydra, 1) + value, value_from_hydra(rx.hydra, 2), rxdata[rx.n])
      end
      return
    end
    local range_limit = "" -- detect if range is at limit to prevent flip_resize bug
    if value < slice_size and value_from_hydra(rx.hydra, 1) == value_from_hydra(rx.hydra, 3) + value_from_hydra(rx.hydra, 5) then range_limit = "left" end
    if value < slice_size and value_from_hydra(rx.hydra, 2) == value_from_hydra(rx.hydra, 4) - value_from_hydra(rx.hydra, 6) then
      if range_limit == "left" then
        rx.doofer2:parameter(4).value = slice_size / rx.sample.sample_buffer.number_of_frames * 100
        return
      else range_limit = "right"
      end
    end
    local change = value - slice_size
    local half = change / 2
    if range_limit == "" then
      if change % 2 > 0 then half = math.floor(change / 2) + flip_resize end
      move_markers("s_slice_size", value_from_hydra(rx.hydra, 1) - half, value_from_hydra(rx.hydra, 1), rxdata[rx.n])
      if change % 2 > 0 and range_limit ~= "left" then flip_resize = 1 - flip_resize end
      if change % 2 > 0 then half = math.floor(change / 2) + flip_resize end
      move_markers("e_slice_size", value_from_hydra(rx.hydra, 2) + half + leftover, value_from_hydra(rx.hydra, 2), rxdata[rx.n])
      if leftover > 0 then move_markers("s_slice_size", value_from_hydra(rx.hydra, 1) - leftover, value_from_hydra(rx.hydra, 1), rxdata[rx.n]) end
    elseif range_limit == "left"  then move_markers("e_slice_size", value_from_hydra(rx.hydra, 2) + change, value_from_hydra(rx.hydra, 2), rxdata[rx.n])
    elseif range_limit == "right" then move_markers("s_slice_size", value_from_hydra(rx.hydra, 1) - change, value_from_hydra(rx.hydra, 1), rxdata[rx.n])
    end
  end
end

-- change GUI values for parameters related to markers

change_gui_values = function()
  bypass = true
  if rxi ~= 0 then remove_notifier(rxi.name_observable, change_display_name) end
  s = renoise.song() -- needed due to raw renoise.song().instruments_observable:add_notifier ?
  si = s.selected_instrument_index
  rxi = s:instrument(vb.views.instr.value)
  add_notifier(rxi.name_observable, change_display_name)
  change_display_name()
  local rxed = 0
  local rxc = 0
  rxed, rxc, rxc1, rxc2, rxc3, rxc4 = rxed_details()
  if rxed then rxs = rxi:sample(1)
  else
    find_rxs(vb.views.instr.value)
    rxc1 = 0
    rxc2 = 0
    rxc3 = 0
    rxc4 = 0
  end
  if #rxi.samples > 0 and rxs.sample_buffer.has_sample_data then
    vb.views.range_s.max    =  rxs.sample_buffer.number_of_frames
    vb.views.range_e.max    =  rxs.sample_buffer.number_of_frames
    vb.views.origin_s.max   =  rxs.sample_buffer.number_of_frames
    vb.views.origin_e.max   =  rxs.sample_buffer.number_of_frames + 1
    vb.views.offset_s.min   = -rxs.sample_buffer.number_of_frames
    vb.views.offset_s.max   =  rxs.sample_buffer.number_of_frames
    vb.views.offset_e.min   = -rxs.sample_buffer.number_of_frames
    vb.views.offset_e.max   =  rxs.sample_buffer.number_of_frames
    vb.views.position_s.max =  rxs.sample_buffer.number_of_frames
    vb.views.position_e.max =  rxs.sample_buffer.number_of_frames + 1
    vb.views.slice_size.max =  rxs.sample_buffer.number_of_frames
    vb.views.min_ss.max     =  rxs.sample_buffer.number_of_frames
  else
    vb.views.range_s.max    = 1
    vb.views.range_e.max    = 1
    vb.views.origin_s.max   = 1
    vb.views.origin_e.max   = 2
    vb.views.offset_s.min   = 0
    vb.views.offset_s.max   = 0
    vb.views.offset_e.min   = 0
    vb.views.offset_e.max   = 0
    vb.views.position_s.max = 1
    vb.views.position_e.max = 1
    vb.views.slice_size.max = 1
    vb.views.min_ss.max     = 1
  end
  if rxed then
    vb.views.slider_s.active   = true
    vb.views.slider_e.active   = true
    vb.views.offset_s.active   = true
    vb.views.offset_e.active   = true
    vb.views.position_s.active = true
    vb.views.position_e.active = true
    vb.views.slice_size.active = true
    vb.views.min_ss.active     = true
    vb.views.origin_s.value    = value_from_hydra(rxc4, 3)
    vb.views.origin_e.value    = value_from_hydra(rxc4, 4)
    vb.views.range_s.value     = value_from_hydra(rxc4, 5)
    set_slider_steps(vb.views.range_s.value, "s")
    vb.views.range_e.value     = value_from_hydra(rxc4, 6)
    set_slider_steps(vb.views.range_e.value, "e")
    vb.views.slider_s.value    = rxc1:parameter(6).value
    vb.views.slider_e.value    = rxc1:parameter(7).value
    vb.views.xypad.value       = { x=vb.views.slider_s.value, y=vb.views.slider_e.value }
    vb.views.position_s.value  = rxs.slice_markers[1]
    vb.views.position_e.value  = rxs.slice_markers[2]
    vb.views.offset_s.value    = vb.views.position_s.value - vb.views.origin_s.value
    vb.views.offset_e.value    = vb.views.position_e.value - vb.views.origin_e.value
    vb.views.slice_size.value  = vb.views.position_e.value - vb.views.position_s.value
    vb.views.min_ss.value      = value_from_hydra(rxc4, 7)
    vb.views.snap.value        = math.min(13, round(rxc3:parameter(6).value) + 1)
    vb.views.tolerance.value   = round(rxc3:parameter(7).value)
    if     rxc3:parameter(2).value < 25 then vb.views.interaction.value = 1
    elseif rxc3:parameter(2).value < 50 then vb.views.interaction.value = 2
    elseif rxc3:parameter(2).value < 75 then vb.views.interaction.value = 3
    else                                     vb.views.interaction.value = 4
    end
    if     rxc3:parameter(3).value < 33 then vb.views.slice_anchor.value = 1
    elseif rxc3:parameter(3).value < 67 then vb.views.slice_anchor.value = 2
    else                                     vb.views.slice_anchor.value = 3
    end
    vb.views.set_markers.tooltip = "Set Origin values to marker postions."
  else
    vb.views.slider_s.active    = false
    vb.views.slider_e.active    = false
    vb.views.offset_s.active    = false
    vb.views.offset_e.active    = false
    vb.views.position_s.active  = false
    vb.views.position_e.active  = false
    vb.views.slice_size.active  = false
    vb.views.min_ss.active      = false
    vb.views.xypad.value        = { x=0.5, y=0.5 }
    vb.views.slider_s.value     = 0.5
    vb.views.slider_e.value     = 0.5
    vb.views.offset_s.value     = 0
    vb.views.offset_e.value     = 0
    vb.views.position_s.value   = 1
    vb.views.position_e.value   = 1
    vb.views.interaction.value  = 1
    vb.views.slice_anchor.value = 2
    vb.views.slice_size.value   = 1
    vb.views.min_ss.value       = 1
    vb.views.snap.value         = 1
    vb.views.tolerance.value    = 5
    if #rxi.samples > 0 and rxs.sample_buffer.has_sample_data then
      vb.views.range_s.value  = math.max(1, round(rxs.sample_buffer.number_of_frames / 10))
      vb.views.range_e.value  = math.max(1, round(rxs.sample_buffer.number_of_frames / 10))
      vb.views.origin_s.value = math.max(1, round(rxs.sample_buffer.number_of_frames / 2))
      vb.views.origin_e.value = math.max(2, round(rxs.sample_buffer.number_of_frames / 2 + 1))
    else
      vb.views.range_s.value  = 1
      vb.views.range_e.value  = 1
      vb.views.origin_s.value = 1
      vb.views.origin_e.value = 2
    end
    vb.views.set_markers.tooltip = "Set up instrument for use by this tool. Slice markers will be placed on the Origin points."
  end
  bypass = false
end

-- set the appropriate rxs value and add/remove notifiers

function find_rxs()
  if #rxi.samples > 0 then
    if rxs ~= 0 then remove_notifier(rxs.sample_buffer_observable, change_gui_values) end -- remove notifier from rxs before it's potentially changed
    rxs = rxi:sample(1)
    add_notifier(rxs.sample_buffer_observable, change_gui_values) -- detects if sample has been edited before LMA-ing
  else
    rxs = 0
    add_notifier(rxi.samples_observable, change_gui_values) -- detects if a sample is loaded into an instrument that contains no samples
  end
end

-- find fx chain / devices

find_fxchain = function(instrument)
  for _, fx_chain in pairs(instrument.sample_device_chains) do -- checking the current array of fx chains, since this may have changed after adding the no_delete_devices notifier
    if fx_chain.name == "Loop Marker Automation" then return fx_chain end
  end
end

find_devices = function(fx_chain)
  local xypad   = nil
  local doofer1 = nil
  local doofer2 = nil
  local hydra   = nil
  for _, device in pairs(fx_chain.devices) do -- checking the current array of devices, since this may have changed after adding the no_delete_devices notifier
    if device.display_name == "LMA Positions"         then xypad   = device end
    if device.display_name == "LMA Origins & Ranges"  then doofer1 = device end
    if device.display_name == "LMA Other Controls"    then doofer2 = device end
    if device.display_name == "DON'T CHANGE/AUTOMATE" then hydra   = device end
  end
  if xypad ~= nil and doofer1 ~= nil and doofer2 ~= nil and hydra ~= nil then return xypad, doofer1, doofer2, hydra end
end

-- deal with stuff being disabled, renamed & deleted

no_disable_devices = function(rx)
  local disabled = false
  if not rx.xypad.is_active   then rx.xypad.is_active   = true disabled = true end
  if not rx.doofer1.is_active then rx.doofer1.is_active = true disabled = true end
  if not rx.doofer2.is_active then rx.doofer2.is_active = true disabled = true end
  if not rx.hydra.is_active   then rx.hydra.is_active   = true disabled = true end
  if disabled then renoise.app():show_warning("This device cannot be disabled. It is required to be active by the Loop Marker Automation tool.") end
end

no_rename_fxchain = function(rx)
  if rx.fx_chain.name ~= "Loop Marker Automation" then
    renoise.app():show_warning("This FX Chain cannot be renamed. It is used to identify LMA-sliced instruments in your song.")
    rx.fx_chain.name = "Loop Marker Automation"
  end
end

no_rename_xypad = function(rx)
  if rx.xypad.display_name ~= "LMA Positions" then
    renoise.app():show_warning("This device cannot be renamed. It is used to identify itself in your song.")
    rx.xypad.display_name = "LMA Positions"
  end
end

no_rename_doofer1 = function(rx)
  if rx.doofer1.display_name ~= "LMA Origins & Ranges" then
    renoise.app():show_warning("This device cannot be renamed. It is used to identify itself in your song.")
    rx.doofer1.display_name = "LMA Origins & Ranges"
  end
end

no_rename_doofer2 = function(rx)
  if rx.doofer2.display_name ~= "LMA Other Controls" then
    renoise.app():show_warning("This device cannot be renamed. It is used to identify itself in your song.")
    rx.doofer2.display_name = "LMA Other Controls"
  end
end

no_rename_hydra = function(rx)
  if rx.hydra.display_name ~= "DON'T CHANGE/AUTOMATE" then
    renoise.app():show_warning("This device cannot be renamed. It is used to identify itself in your song.")
    rx.hydra.display_name = "DON'T CHANGE/AUTOMATE"
  end
end

no_delete_fxchain = function(rx)
  if not rxed_details() then
    renoise.app():show_warning("The FX Chain for an LMA-ed instrument has been deleted. Please undo this action immediately. Failure to do so will prevent the Loop Marker Automation tool from working and may cause errors.")
    remove_rx_notifiers(rxdata[rx.n])
    add_notifier(rx.instrument.sample_device_chains_observable, undo_delete_fxchain, rxdata[rx.n])
  end
end

no_delete_devices = function(rx)
  if not rxed_details() then
    renoise.app():show_warning("An effect device for an LMA-ed instrument has been deleted. Please undo this action immediately. Failure to do so will prevent the Loop Marker Automation tool from working and may cause errors.")
    remove_rx_notifiers(rxdata[rx.n])
    add_notifier(rx.fx_chain.devices_observable, undo_delete_devices, rxdata[rx.n])
    add_notifier(rx.instrument.sample_device_chains_observable, redo_rxing, rxdata[rx.n]) -- in case the user is undoing the LMA-ing of the instrument
  end
end

no_edit_sample = function() renoise.app():show_warning("Detected an edit to a sample used by the Loop Marker Automation tool. Please undo this action immediately. Failure to do so may cause errors.") end

undo_delete_fxchain = function(rx)
  local rxed, fx_chain, xypad, doofer1, doofer2, hydra = rxed_details(rx.instrument)
  if rxed then
    remove_notifier(rx.instrument.sample_device_chains_observable, undo_delete_fxchain, rxdata[rx.n])
    if si == vb.views.instr.value then
      rxc1 = xypad
      rxc2 = doofer1
      rxc3 = doofer2
      rxc4 = hydra
    end
    rx.fx_chain = fx_chain
    rx.xypad    = xypad
    rx.doofer1  = doofer1
    rx.doofer2  = doofer2
    rx.hydra    = hydra
    add_rx_notifiers(rxdata[rx.n])
  end
end

undo_delete_devices = function(rx)
  local rxed, fx_chain, xypad, doofer1, doofer2, hydra = rxed_details(rx.instrument)
  if rxed then
    remove_notifier(rx.instrument.sample_device_chains_observable, redo_rxing, rxdata[rx.n])
    remove_notifier(rx.fx_chain.devices_observable, undo_delete_devices, rxdata[rx.n])
    if si == vb.views.instr.value then
      rxc1 = xypad
      rxc2 = doofer1
      rxc3 = doofer2
      rxc4 = hydra
    end
    rx.xypad   = xypad
    rx.doofer1 = doofer1
    rx.doofer2 = doofer2
    rx.hydra   = hydra
    add_rx_notifiers(rxdata[rx.n])
  end
end

undo_delete_sample = function(rx)
  if #rx.instrument.samples == 3 then
    remove_notifier(rx.instrument.samples_observable, undo_delete_sample, rxdata[rx.n])
    if si == vb.views.instr.value then rxs = rx.instrument:sample(1) end
    rx.sample = rx.instrument:sample(1)
    add_rx_notifiers(rxdata[rx.n])
  end
end

redo_rxing = function(rx)
  local rxed, fx_chain, xypad, doofer1, doofer2, hydra = rxed_details(rx.instrument)
  if rxed then
    remove_notifier(rx.instrument.sample_device_chains_observable, redo_rxing, rxdata[rx.n])
    if si == vb.views.instr.value then
      rxc1 = xypad
      rxc2 = doofer1
      rxc3 = doofer2
      rxc4 = hydra
    end
    rx.fx_chain = fx_chain
    rx.xypad    = xypad
    rx.doofer1  = doofer1
    rx.doofer2  = doofer2
    rx.hydra    = hydra
    add_rx_notifiers(rxdata[rx.n])
  end
end

slices_change = function(rx) -- need to do this outside of slice_markers_observable to avoid Renoise detecting a loop (despite bypass) when deleting/inserting marker
  if bypass then return end
  if #rx.instrument.samples == 1 then
    renoise.app():show_warning("The sample of an LMA-ed instrument has been deleted or replaced. Please undo this action immediately. Failure to do so will prevent the Loop Marker Automation tool from working and may cause errors.")
    remove_rx_notifiers(rxdata[rx.n])
    add_notifier(rx.instrument.samples_observable, undo_delete_sample, rxdata[rx.n])
  else
    if #rx.sample.slice_markers ~= 2 then
      bypass = true
      renoise.app():show_warning("Detected an attempt to change the number of slice markers. This action has been automatically undone because the Loop Marker Automation tool requires 2 slice markers to work.")
      if #rx.sample.slice_markers > 2 then
        for a = 1, 3 do
          if rx.sample.slice_markers[a] ~= value_from_hydra(rx.hydra, 1) and rx.sample.slice_markers[a] ~= value_from_hydra(rx.hydra, 2) then
            rx.sample:delete_slice_marker(rx.sample.slice_markers[a])
            bypass = false
            return
          end
        end
        if rx.sample.slice_markers[1] == rx.sample.slice_markers[2] then rx.sample:delete_slice_marker(rx.sample.slice_markers[2]) -- if we're here then the marker was added on top of another
        else                                                             rx.sample:delete_slice_marker(rx.sample.slice_markers[3])
        end
      else
        if rx.sample.slice_markers[1] == value_from_hydra(rx.hydra, 1) then rx.sample:insert_slice_marker(value_from_hydra(rx.hydra, 2))
        else                                                                rx.sample:insert_slice_marker(value_from_hydra(rx.hydra, 1))
        end
      end
      bypass = false
    end
  end
end

-- marker, xypad, doofer and hydra changes

marker_change = function(rx)
  if bypass or #rx.sample.slice_markers ~= 2 then return end
  if rx.sample.slice_markers[1] ~= value_from_hydra(rx.hydra, 1) then move_markers("s_marker", rx.sample.slice_markers[1], value_from_hydra(rx.hydra, 1), rxdata[rx.n]) end
  if rx.sample.slice_markers[2] ~= value_from_hydra(rx.hydra, 2) then move_markers("e_marker", rx.sample.slice_markers[2], value_from_hydra(rx.hydra, 2), rxdata[rx.n]) end
end

xypad_change1 = function(rx)
  if not bypass then
    if rx.xypad:parameter(1).value == 0.5 then snapback = snapback + 1
    else                                       snapback = 0
    end
    move_markers("s_xypad", math.max(1, round((rx.xypad:parameter(1).value - 0.5) * 2 * value_from_hydra(rx.hydra, 5) + value_from_hydra(rx.hydra, 3))), rx.sample.slice_markers[1], rxdata[rx.n])
  end
end

xypad_change2 = function(rx)
  if not bypass then
    if snapback == 1 and rx.xypad:parameter(2).value == 0.5 then -- fixes: with snapback on, moving xypad to bottom-left makes x-axis stick in place
      snapback = -1
      move_markers("e_xypad", value_from_hydra(rx.hydra, 4), rx.sample.slice_markers[2], rxdata[rx.n])
      move_markers("s_xypad", value_from_hydra(rx.hydra, 3), rx.sample.slice_markers[1], rxdata[rx.n])
    else
      move_markers("e_xypad",  math.max(2, round((rx.xypad:parameter(2).value - 0.5) * 2 * value_from_hydra(rx.hydra, 6) + value_from_hydra(rx.hydra, 4))), rx.sample.slice_markers[2], rxdata[rx.n])
    end
  end
end

xypad_change6 = function(rx)
  if not bypass then move_markers("s_slider", math.max(1, round((rx.xypad:parameter(6).value - 0.5) * 2 * value_from_hydra(rx.hydra, 5) + value_from_hydra(rx.hydra, 3))), rx.sample.slice_markers[1], rxdata[rx.n]) end
end

xypad_change7 = function(rx)
  if not bypass then move_markers("e_slider", math.max(2, round((rx.xypad:parameter(7).value - 0.5) * 2 * value_from_hydra(rx.hydra, 6) + value_from_hydra(rx.hydra, 4))), rx.sample.slice_markers[2], rxdata[rx.n]) end
end

doofer1_change1 = function(rx)
  if not bypass then
    local origin = math.max(1, round(rx.doofer1:parameter(1).value * rx.sample.sample_buffer.number_of_frames / 100) + 1)
    if origin > value_from_hydra(rx.hydra, 4) - 1 then -- don't pass the end origin
      bypass = true
      rx.doofer1:parameter(1).value = math.max(1, round((value_from_hydra(rx.hydra, 4) - 2) / rx.sample.sample_buffer.number_of_frames * 100)) -- -1 - 1 (compensates for +/-1 discrepancy between Lua and Renoise)
      origin = value_from_hydra(rx.hydra, 4) - 1
      bypass = false
    end
    value_to_hydra(rx.hydra, 3, origin)
    move_markers("s_origin", rx.sample.slice_markers[1], rx.sample.slice_markers[1], rxdata[rx.n]) -- send position to see how it works with new origin
  end
end

doofer1_change2 = function(rx)
  if not bypass then
    local origin = math.max(2, round(rx.doofer1:parameter(2).value * rx.sample.sample_buffer.number_of_frames / 100) + 1)
    if origin < value_from_hydra(rx.hydra, 3) + 1 then -- don't pass the start origin
      bypass = true
      rx.doofer1:parameter(2).value = math.max(2, round(value_from_hydra(rx.hydra, 3) / rx.sample.sample_buffer.number_of_frames * 100)) -- -1 + 1 (compensates for +/-1 discrepancy between Lua and Renoise)
      origin = value_from_hydra(rx.hydra, 3) + 1
      bypass = false
    end
    value_to_hydra(rx.hydra, 4, origin)
    move_markers("e_origin", rx.sample.slice_markers[2], rx.sample.slice_markers[2], rxdata[rx.n]) -- send position to see how it works with new origin
  end
end

doofer1_change3 = function(rx)
  if not bypass then
    value_to_hydra(rx.hydra, 5, math.max(1, round(rx.doofer1:parameter(3).value * rx.sample.sample_buffer.number_of_frames / 100)))
    move_markers("s_range", rx.sample.slice_markers[1], rx.sample.slice_markers[1], rxdata[rx.n]) -- send position to adjust to new range
  end
end
  
doofer1_change4 = function(rx)
  if not bypass then
    value_to_hydra(rx.hydra, 6, math.max(1, round(rx.doofer1:parameter(4).value * rx.sample.sample_buffer.number_of_frames / 100)))
    move_markers("e_range", rx.sample.slice_markers[2], rx.sample.slice_markers[2], rxdata[rx.n]) -- send position to adjust to new range
  end
end

doofer2_change1 = function(rx)
  if not bypass and rx.doofer2:parameter(1).value == 100 then
    value_to_hydra(rx.hydra, 3, rx.sample.slice_markers[1])
    value_to_hydra(rx.hydra, 4, rx.sample.slice_markers[2])
    rx.doofer1:parameter(1).value = (rx.sample.slice_markers[1] - 1) / rx.sample.sample_buffer.number_of_frames * 100
    rx.doofer1:parameter(2).value = (rx.sample.slice_markers[2] - 1) / rx.sample.sample_buffer.number_of_frames * 100
    renoise.app():show_status("Loop Marker Automation: Origins set to " .. rx.sample.slice_markers[1] - 1 .. ", " .. rx.sample.slice_markers[2] - 1 .. ".")
  end
end

doofer2_change2 = function(rx)
  if not bypass and si == vb.views.instr.value then
    bypass = true
    if     rx.doofer2:parameter(2).value < 25 then vb.views.interaction.value = 1
    elseif rx.doofer2:parameter(2).value < 50 then vb.views.interaction.value = 2
    elseif rx.doofer2:parameter(2).value < 75 then vb.views.interaction.value = 3
    else                                           vb.views.interaction.value = 4
    end
    bypass = false
  end
end

doofer2_change3 = function(rx)
  if not bypass and si == vb.views.instr.value then
    bypass = true
    if     rx.doofer2:parameter(3).value < 33 then vb.views.slice_anchor.value = 1
    elseif rx.doofer2:parameter(3).value < 66 then vb.views.slice_anchor.value = 2
    else                                           vb.views.slice_anchor.value = 3
    end
    bypass = false
  end
end

doofer2_change4 = function(rx)
  if not bypass then changing_ss(rx, math.max(1, round(rx.doofer2:parameter(4).value * rx.sample.sample_buffer.number_of_frames / 100))) end
end

doofer2_change5 = function(rx)
  if not bypass then
    bypass = true
    local min_ss = round(rx.doofer2:parameter(5).value * rx.sample.sample_buffer.number_of_frames / 100)
    if min_ss == 0 then min_ss = 1
    elseif min_ss > value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1) then min_ss = value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1)      
    end
    rx.doofer2:parameter(5).value = min_ss / rx.sample.sample_buffer.number_of_frames * 100 -- in case it was changed above
    value_to_hydra(rx.hydra, 7, min_ss)
    if min_ss > 0 and si == vb.views.instr.value then print(rxed_details()) vb.views.min_ss.value = min_ss end -- min_ss > 0 to catch undoing LMA
    bypass = false
  end
end

doofer2_change6 = function(rx)
  if not bypass and si == vb.views.instr.value then
    bypass = true
    vb.views.snap.value = math.min(13, round(rx.doofer2:parameter(6).value) + 1)
    bypass = false
  end
end

doofer2_change7 = function(rx)
  if not bypass and si == vb.views.instr.value then
    bypass = true
    vb.views.tolerance.value = rx.doofer2:parameter(7).value
    bypass = false
  end
end

no_hydra_change_parameter = function(rx)
  if rx.hydra:parameter(4).value  ~= -1 then rx.hydra:parameter(4).value  = -1 end -- can't detect which was changed so just check them all
  if rx.hydra:parameter(9).value  ~= -1 then rx.hydra:parameter(9).value  = -1 end
  if rx.hydra:parameter(14).value ~= -1 then rx.hydra:parameter(14).value = -1 end
  if rx.hydra:parameter(19).value ~= -1 then rx.hydra:parameter(19).value = -1 end
  if rx.hydra:parameter(24).value ~= -1 then rx.hydra:parameter(24).value = -1 end
  if rx.hydra:parameter(29).value ~= -1 then rx.hydra:parameter(29).value = -1 end
  if rx.hydra:parameter(34).value ~= -1 then rx.hydra:parameter(34).value = -1 end
  -- renoise.app():show_warning("Loop Marker Automation: This parameter cannot be changed.") -- trying to use a warning fires it off twice cos of parameter's drop-down menu
end

-- setup when loading a new song (must be raw, can't be activated by menu)

renoise.tool().app_new_document_observable:add_notifier(function()
  s = renoise.song()
  si = s.selected_instrument_index
  rxi = 0
  rxs = 0
  rxc1 = 0
  rxc2 = 0
  rxc3 = 0
  rxc4 = 0
  
  renoise.song().selected_instrument_observable:add_notifier(function()
    si = renoise.song().selected_instrument_index
    if vb.views.instr_link.value then vb.views.instr.value = si end
  end)
  
  renoise.song().instruments_observable:add_notifier(function(change)
    if change.type == "remove" then
      for index, rx in pairs(rxdata) do
        local removed = true
        for _, instrument in pairs(renoise.song().instruments) do -- check if this instrument was removed
          if rawequal(instrument, rx.instrument) then removed = false end
        end
        if removed == true then rxdata[index] = nil end
      end
      if vb.views.instr.value > #s.instruments then vb.views.instr.value = #s.instruments end
    end
    
    if change.type == "insert" then
      for index, instrument in pairs(renoise.song().instruments) do
        local rxed, rxc, xypad, doofer1, doofer2, hydra = rxed_details(instrument)
        if rxed then
          local done = false
          for _, rx in pairs(rxdata) do -- check if this instrument has already been logged
            if rawequal(instrument, rx.instrument) then done = true end
          end
          if not done then
            local n = #rxdata + 1
            rxdata[n] = { n=n, instrument=instrument, sample=instrument:sample(1), fx_chain=rxc, xypad=xypad, doofer1=doofer1, doofer2=doofer2, hydra=hydra }
            add_rx_notifiers(rxdata[n])
            if index == si then
              rxi  = instrument
              rxs  = instrument:sample(1)
              rxc1 = xypad
              rxc2 = doofer1
              rxc3 = doofer2
              rxc4 = hydra
            end
          end
        end
      end
    end
    bypass = true
    change_gui_values() -- need to trigger manually since the value may not have changed
    bypass = false
  end)

  for index, instrument in pairs(renoise.song().instruments) do
    local rxed, rxc, xypad, doofer1, doofer2, hydra = rxed_details(instrument)
    if rxed then
      local n = #rxdata + 1
      rxdata[n] = { n=n, instrument=instrument, sample=instrument:sample(1), fx_chain=rxc, xypad=xypad, doofer1=doofer1, doofer2=doofer2, hydra=hydra }
      add_rx_notifiers(rxdata[n])
      bypass = false
    end
  end
  if vb.views.instr_link.value then vb.views.instr.value = si end
  change_gui_values() -- need to trigger manually since the value may not have changed
end)

function add_rx_notifiers(rx)
  add_notifier(rx.xypad.is_active_observable,          no_disable_devices, rx)
  add_notifier(rx.xypad.display_name_observable,       no_rename_xypad, rx)
  add_notifier(rx.xypad:parameter(1).value_observable, xypad_change1, rx)
  add_notifier(rx.xypad:parameter(2).value_observable, xypad_change2, rx)
  add_notifier(rx.xypad:parameter(6).value_observable, xypad_change6, rx)
  add_notifier(rx.xypad:parameter(7).value_observable, xypad_change7, rx)

  add_notifier(rx.doofer1.is_active_observable,          no_disable_devices, rx)
  add_notifier(rx.doofer1.display_name_observable,       no_rename_doofer1, rx)
  add_notifier(rx.doofer1:parameter(1).value_observable, doofer1_change1, rx)
  add_notifier(rx.doofer1:parameter(2).value_observable, doofer1_change2, rx)
  add_notifier(rx.doofer1:parameter(3).value_observable, doofer1_change3, rx)
  add_notifier(rx.doofer1:parameter(4).value_observable, doofer1_change4, rx)
  
  add_notifier(rx.doofer2.is_active_observable,          no_disable_devices, rx)
  add_notifier(rx.doofer2.display_name_observable,       no_rename_doofer2, rx)
  add_notifier(rx.doofer2:parameter(1).value_observable, doofer2_change1, rx)
  add_notifier(rx.doofer2:parameter(2).value_observable, doofer2_change2, rx)
  add_notifier(rx.doofer2:parameter(3).value_observable, doofer2_change3, rx)
  add_notifier(rx.doofer2:parameter(4).value_observable, doofer2_change4, rx)
  add_notifier(rx.doofer2:parameter(5).value_observable, doofer2_change5, rx)
  add_notifier(rx.doofer2:parameter(6).value_observable, doofer2_change6, rx)
  add_notifier(rx.doofer2:parameter(7).value_observable, doofer2_change7, rx)
  
  add_notifier(rx.hydra.is_active_observable,           no_disable_devices, rx)
  add_notifier(rx.hydra.display_name_observable,        no_rename_hydra, rx)
  add_notifier(rx.hydra:parameter(4).value_observable,  no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(9).value_observable,  no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(14).value_observable, no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(19).value_observable, no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(24).value_observable, no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(29).value_observable, no_hydra_change_parameter, rx)
  add_notifier(rx.hydra:parameter(34).value_observable, no_hydra_change_parameter, rx)

  add_notifier(rx.fx_chain.name_observable,                   no_rename_fxchain, rx)
  add_notifier(rx.fx_chain.devices_observable,                no_delete_devices, rx)
  add_notifier(rx.instrument.samples_observable,              slices_change, rx)
  add_notifier(rx.sample.slice_markers_observable,            marker_change, rx)
  add_notifier(rx.sample.sample_buffer_observable,            no_edit_sample)
  add_notifier(rx.instrument.sample_device_chains_observable, no_delete_fxchain, rx)
end

function remove_rx_notifiers(rx)
  remove_notifier(rx.xypad.is_active_observable,          no_disable_devices, rx)
  remove_notifier(rx.xypad.display_name_observable,       no_rename_xypad, rx)
  remove_notifier(rx.xypad:parameter(1).value_observable, xypad_change1, rx)
  remove_notifier(rx.xypad:parameter(2).value_observable, xypad_change2, rx)
  remove_notifier(rx.xypad:parameter(6).value_observable, xypad_change6, rx)
  remove_notifier(rx.xypad:parameter(7).value_observable, xypad_change7, rx)

  remove_notifier(rx.doofer1.is_active_observable,          no_disable_devices, rx)
  remove_notifier(rx.doofer1.display_name_observable,       no_rename_doofer1, rx)
  remove_notifier(rx.doofer1:parameter(1).value_observable, doofer1_change1, rx)
  remove_notifier(rx.doofer1:parameter(2).value_observable, doofer1_change2, rx)
  remove_notifier(rx.doofer1:parameter(3).value_observable, doofer1_change3, rx)
  remove_notifier(rx.doofer1:parameter(4).value_observable, doofer1_change4, rx)
  
  remove_notifier(rx.doofer2.is_active_observable,          no_disable_devices, rx)
  remove_notifier(rx.doofer2.display_name_observable,       no_rename_doofer2, rx)
  remove_notifier(rx.doofer2:parameter(1).value_observable, doofer2_change1, rx)
  remove_notifier(rx.doofer2:parameter(2).value_observable, doofer2_change2, rx)
  remove_notifier(rx.doofer2:parameter(3).value_observable, doofer2_change3, rx)
  remove_notifier(rx.doofer2:parameter(4).value_observable, doofer2_change4, rx)
  remove_notifier(rx.doofer2:parameter(5).value_observable, doofer2_change5, rx)
  remove_notifier(rx.doofer2:parameter(6).value_observable, doofer2_change6, rx)
  remove_notifier(rx.doofer2:parameter(7).value_observable, doofer2_change7, rx)
  
  remove_notifier(rx.hydra.is_active_observable,           no_disable_devices, rx)
  remove_notifier(rx.hydra.display_name_observable,        no_rename_hydra, rx)
  remove_notifier(rx.hydra:parameter(4).value_observable,  no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(9).value_observable,  no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(14).value_observable, no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(19).value_observable, no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(24).value_observable, no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(29).value_observable, no_hydra_change_parameter, rx)
  remove_notifier(rx.hydra:parameter(34).value_observable, no_hydra_change_parameter, rx)
  
  remove_notifier(rx.fx_chain.name_observable,                   no_rename_fxchain, rx)
  remove_notifier(rx.fx_chain.devices_observable,                no_delete_devices, rx)
  remove_notifier(rx.instrument.samples_observable,              slices_change, rx)
  remove_notifier(rx.sample.slice_markers_observable,            marker_change, rx)
  remove_notifier(rx.sample.sample_buffer_observable,            no_edit_sample)
  remove_notifier(rx.instrument.sample_device_chains_observable, no_delete_fxchain, rx)
end

-- prepare the sample for slicing

function prepare_instrument()

  -- create phrases

  for p = 9, 1, -1 do
    rxi:insert_phrase_at(1)
    s.selected_phrase_index = 1
    renoise.app():load_instrument_phrase("phrases/lma" .. p .. ".xrnz")
  end

  -- set loop and add markers

  rxs.loop_mode = 2
  rxs:insert_slice_marker(vb.views.origin_s.value)
  rxs:insert_slice_marker(vb.views.origin_e.value)

  -- add fx chain & devices and set parameters

  rxi:insert_sample_device_chain_at(#rxi.sample_device_chains + 1)
  local rxc = rxi:sample_device_chain(#rxi.sample_device_chains)
  rxc.name = "Loop Marker Automation"
  if rxs.device_chain_index == 0 then -- may as well assign fx chain to sample and slices if they aren't already assigned to one, so the LMA chain will be in focus when the user switches instruments
    rxs.device_chain_index = #rxi.sample_device_chains
    rxi:sample(2).device_chain_index = #rxi.sample_device_chains
    rxi:sample(3).device_chain_index = #rxi.sample_device_chains
  end
  rxc1 = rxc:insert_device_at("Audio/Effects/Native/*XY Pad", #rxc.devices + 1)
  rxc2 = rxc:insert_device_at("Audio/Effects/Native/Doofer",  #rxc.devices + 1)
  rxc3 = rxc:insert_device_at("Audio/Effects/Native/Doofer",  #rxc.devices + 1)
  rxc4 = rxc:insert_device_at("Audio/Effects/Native/*Hydra",  #rxc.devices + 1)
  rxc1.display_name = "LMA Positions"
  rxc2.display_name = "LMA Origins & Ranges"
  rxc3.display_name = "LMA Other Controls"
  rxc4.display_name = "DON'T CHANGE/AUTOMATE"
  rxc4.is_maximized = false
  rxc1:parameter(6).value = 0.5
  rxc1:parameter(7).value = 0.5
  rxc2.active_preset_data = io.open("lmadoofer1.xrdp", "rb"):read("*all")
  rxc2:parameter(1).value = (vb.views.origin_s.value - 1) / rxs.sample_buffer.number_of_frames * 100
  rxc2:parameter(2).value = (vb.views.origin_e.value - 1) / rxs.sample_buffer.number_of_frames * 100
  rxc2:parameter(3).value = vb.views.range_s.value / rxs.sample_buffer.number_of_frames * 100
  rxc2:parameter(4).value = vb.views.range_e.value / rxs.sample_buffer.number_of_frames * 100
  rxc3.active_preset_data = io.open("lmadoofer2.xrdp", "rb"):read("*all")
  if     vb.views.interaction.value == 2 then rxc3:parameter(2).value = 25
  elseif vb.views.interaction.value == 3 then rxc3:parameter(2).value = 50
  elseif vb.views.interaction.value == 4 then rxc3:parameter(2).value = 75
  end
  if     vb.views.slice_anchor.value == 1 then rxc3:parameter(3).value = 0
  elseif vb.views.slice_anchor.value == 3 then rxc3:parameter(3).value = 100
  end
  rxc3:parameter(4).value = (vb.views.origin_e.value - vb.views.origin_s.value) / rxs.sample_buffer.number_of_frames * 100
  rxc3:parameter(5).value = 1 / rxs.sample_buffer.number_of_frames * 100
  rxc3:parameter(6).value = vb.views.snap.value - 1
  rxc3:parameter(7).value = vb.views.tolerance.value
  value_to_hydra(rxc4, 1, vb.views.origin_s.value)
  value_to_hydra(rxc4, 2, vb.views.origin_e.value)
  value_to_hydra(rxc4, 3, vb.views.origin_s.value)
  value_to_hydra(rxc4, 4, vb.views.origin_e.value)
  value_to_hydra(rxc4, 5, vb.views.range_s.value)
  value_to_hydra(rxc4, 6, vb.views.range_e.value)
  value_to_hydra(rxc4, 7, vb.views.min_ss.value)
  renoise.app():show_status("Loop Marker Automation: Instrument created, markers set to " .. vb.views.origin_s.value - 1 .. ", " .. vb.views.origin_e.value - 1 .. ".")
  
  -- set device notifiers
  
  remove_notifier(rxs.sample_buffer_observable, change_gui_values)
  local n = #rxdata + 1
  rxdata[n] = { n=n, instrument=rxi, sample=rxs, fx_chain=rxc, xypad=rxc1, doofer1=rxc2, doofer2=rxc3, hydra=rxc4 }
  add_rx_notifiers(rxdata[n])
  change_gui_values()
  bypass = false
end

-- move the slice markers

function move_markers(source, position, old_position, rx)
  --print(source, position, old_position, rx) -- debug
  local se = "s"
  if source:sub(1,1) == "e" then se = "e" end
  local diff = position - old_position
  local at_sample_start   = value_from_hydra(rx.hydra, 1) == 1
  local at_sample_end     = value_from_hydra(rx.hydra, 2) == rx.sample.sample_buffer.number_of_frames + 1
  local at_s_upper_limit  = value_from_hydra(rx.hydra, 1) == value_from_hydra(rx.hydra, 3) + value_from_hydra(rx.hydra, 5)
  local at_e_upper_limit  = value_from_hydra(rx.hydra, 2) == value_from_hydra(rx.hydra, 4) + value_from_hydra(rx.hydra, 6)
  local at_s_lower_limit  = value_from_hydra(rx.hydra, 1) == value_from_hydra(rx.hydra, 3) - value_from_hydra(rx.hydra, 5)
  local at_e_lower_limit  = value_from_hydra(rx.hydra, 2) == value_from_hydra(rx.hydra, 4) - value_from_hydra(rx.hydra, 6)
  local at_min_slice_size = value_from_hydra(rx.hydra, 7) == value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1)
  
  if source:sub(3,7) ~= "slice" and source:sub(3,8) ~= "origin" and source:sub(3,7) ~= "range" and rx.doofer2:parameter(6).value == 0 then -- Interaction only if intending to change position and not Snapping
    if rx.doofer2:parameter(2).value >= 25 and rx.doofer2:parameter(2).value < 50 then
      if diff > 0 then
        if se == "s" and at_min_slice_size and not at_sample_end   and not at_e_upper_limit then update(source, value_from_hydra(rx.hydra, 2) + diff, value_from_hydra(rx.hydra, 2), rx, "e", true) end
      else
        if se == "e" and at_min_slice_size and not at_sample_start and not at_s_lower_limit then update(source, value_from_hydra(rx.hydra, 1) + diff, value_from_hydra(rx.hydra, 1), rx, "s", true) end
      end
      
    elseif rx.doofer2:parameter(2).value >= 50 then
      local slice_size = value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1)
      if diff > 0 then
        if rx.doofer2:parameter(2).value >= 75 and se == "s" and (at_sample_end or at_e_upper_limit) then -- if end marker is at sample end or upper limit in Follow + Shrink mode then move toward it
          update(source, position, old_position, rx, se, true)
          return
        end
        if at_sample_end or at_s_upper_limit or at_e_upper_limit then -- if either marker is at upper limit then don't move (especially needed when moving marker by hand)
          update(source, old_position, old_position, rx, se, true)
          return
        end
        if se == "s" then position = position + slice_size end
        update(source, position, old_position, rx, "e", false)
        update(source, value_from_hydra(rx.hydra, 2) - slice_size, old_position, rx, "s", true)
        return
      else
        if rx.doofer2:parameter(2).value >= 75 and se == "e" and (at_sample_start or at_s_lower_limit) then -- if start marker is at sample start or lower limit in Follow + Shrink mode then move toward it
          update(source, position, old_position, rx, se, true)
          return
        end
        if at_sample_start or at_s_lower_limit or at_e_lower_limit then -- if either marker is at lower limit then don't move (especially needed when moving marker by hand)
          update(source, old_position, old_position, rx, se, true)
          return
        end
        if se == "e" then position = position - slice_size end
        update(source, position, old_position, rx, "s", false)
        update(source, value_from_hydra(rx.hydra, 1) + slice_size, old_position, rx, "e", true)
        return
      end
    end
  end
  update(source, position, old_position, rx, se, true)
end

function snap(source, position, old_position, rx, se, origin, range)
  if (se == "s" and position < origin - range) or (se == "e" and position > origin + range) then return old_position end

  if rx.doofer2:parameter(6).value <= 2 then
    local p = math.min(rx.sample.sample_buffer.number_of_frames, position)                       -- math.min cos there's no data to read at sample end
    local m = math.min(rx.sample.sample_buffer.number_of_frames, rx.sample.slice_markers[2] - 1) -- -1 cos for end marker of a loop we're interested in the value that just played
    if se == "e" then
      p = math.min(rx.sample.sample_buffer.number_of_frames, position - 1)
      m = math.min(rx.sample.sample_buffer.number_of_frames, rx.sample.slice_markers[1])
    end

    if rx.doofer2:parameter(6).value == 1 then
      local left = math.abs(sample_volume(rx, 1, m) - sample_volume(rx, 1, p))                                                         -- subtract lowest from highest to get difference
      if sample_volume(rx, 1, m) < sample_volume(rx, 1, p) then left = math.abs(sample_volume(rx, 1, p) - sample_volume(rx, 1, m)) end -- swap subtraction depending on which is lower
      if rx.sample.sample_buffer.number_of_channels == 1 then
        if left > rx.doofer2:parameter(7).value then position = old_position end
      else
        local right = math.abs(sample_volume(rx, 2, m) - sample_volume(rx, 2, p))
        if sample_volume(rx, 2, m) < sample_volume(rx, 2, p) then right = math.abs(sample_volume(rx, 2, p) - sample_volume(rx, 2, m)) end
        if left > rx.doofer2:parameter(7).value or right > rx.doofer2:parameter(7).value then position = old_position end
      end
    else
      if rx.sample.sample_buffer.number_of_channels == 1 then
        if math.abs(sample_volume(rx, 1, p)) > rx.doofer2:parameter(7).value then position = old_position end
      else
        if math.abs(sample_volume(rx, 1, p)) > rx.doofer2:parameter(7).value or math.abs(sample_volume(rx, 2, p)) > rx.doofer2:parameter(7).value then position = old_position
        end
      end
    end
  else
    local b = 0
    local diff = position - old_position
    local spb = round(rx.sample.sample_buffer.sample_rate * (1 / (s.transport.bpm / 60)))                                           -- samples per beat
    local sps = rx.sample.sample_buffer.number_of_frames / 256                                                                      -- samples per snap = sample length / snap division (no round, so it matches Renoise)
    if rx.doofer2:parameter(6).value >= 4 then sps = round(spb / 2 ^ math.min(8, math.ceil(rx.doofer2:parameter(6).value - 4))) end -- samples per snap = spb / snap division

    while position > round(sps * b) do b = b + 1 end
    local fallback = math.max(old_position, round(sps * (b - 1)) + 1) -- fallback is nearest previous snap division (or original point)
    if diff <= 0 then -- adjust when static or moving left
      fallback = math.min(old_position, round(sps * b) + 1)
      b = b - 1
    end
    if (diff < 0 and position > round(sps * b) + round(sps * 0.25)) or (diff > 0 and position < round(sps * b) - round(sps * 0.25)) then position = fallback
    else position = round(sps * b) + 1
    end
  end
  if source:sub(3,7) == "slice" and position ~= old_position and rx.doofer2:parameter(3).value >= 33 and rx.doofer2:parameter(3).value < 66 then
    if flip_snap == 0 then flip_snap = 1
    else                   flip_snap = 0
    end
  end
  return position
end

function update(source, position, old_position, rx, se, done)
  bypass = true
  leftover = position
  local u = 0
  if se == "e" then u = 1 end -- target different devices depending on type of update
  local origin = value_from_hydra(rx.hydra, 3 + u)
  local range  = value_from_hydra(rx.hydra, 5 + u)
  local min_ss = value_from_hydra(rx.hydra, 7)

  if rx.doofer2:parameter(6).value > 0 and source:sub(3,8) ~= "origin" and source:sub(3,7) ~= "range" then position = snap(source, position, old_position, rx, se, origin, range) end -- only Snap if intending to change position

  local constrained = false
  if se == "s" then
    if position > value_from_hydra(rx.hydra, 2) - min_ss then       -- stop at min slice size distance from end marker
      position = value_from_hydra(rx.hydra, 2) - min_ss
      constrained = true
    end
    if position < 1 then                                            -- stop at start of sample (must come after 'stop at min slice size distance' for Push)
      position = 1
      constrained = true
    end
    if source:sub(3,7) == "range" and math.abs(position - origin) >= range and origin - range > value_from_hydra(rx.hydra, 2) - min_ss then range = origin - (value_from_hydra(rx.hydra, 2) - min_ss) end -- limit range reduction to min slice size
  else
    if position < value_from_hydra(rx.hydra, 1) + min_ss then       -- stop at min slice size distance from start marker
      position = value_from_hydra(rx.hydra, 1) + min_ss
      constrained = true
    end
    if position > rx.sample.sample_buffer.number_of_frames + 1 then -- stop at end of sample (must come after 'stop at min slice size distance' for Push)
      position = rx.sample.sample_buffer.number_of_frames + 1
      constrained = true
    end
    if source:sub(3,7) == "range" and math.abs(position - origin) >= range and origin + range < value_from_hydra(rx.hydra, 1) + min_ss then range = (value_from_hydra(rx.hydra, 1) + min_ss) - origin end -- limit range reduction to min slice size
  end

  local offset = position - origin
  if math.abs(offset) > range then -- stop at limit of range
    constrained = true
    if offset < 0 then offset = -range
    else               offset =  range
    end
    if source == "s_origin" and offset + origin > value_from_hydra(rx.hydra, 2) - min_ss then origin = value_from_hydra(rx.hydra, 2) - min_ss - offset end -- origin change can move position past min slice size, so rein it in
    if source == "e_origin" and offset + origin < value_from_hydra(rx.hydra, 1) + min_ss then origin = value_from_hydra(rx.hydra, 1) + min_ss - offset end
  end
  if rx.doofer2:parameter(6).value > 0 and source:sub(3,8) ~= "origin" and source:sub(3,7) ~= "range" and constrained then
    position = old_position
    offset = position - origin
  else position = offset + origin
  end
  leftover = math.abs(leftover - position)

  if rawequal(rx.instrument, rxi) then
    vb.views["offset_" .. se].value = offset
    vb.views["slider_" .. se].value = offset / (2 * range) + 0.5
    vb.views.xypad.value = { x=vb.views.slider_s.value, y=vb.views.slider_e.value }
    if (source:sub(3,8) ~= "origin" and source:sub(3,7) ~= "range") or position ~= old_position then vb.views["position_" .. se].value = position end -- if intending to change position or if position was changed by origin/range
    if source:sub(3,8) == "origin" then vb.views["origin_" .. se].value = origin end
    if source:sub(3,7) == "range"  then vb.views["range_" .. se].value = range end
  end

  if source:sub(3,8) == "origin" then
    value_to_hydra(rx.hydra, 3 + u, origin)
    rx.doofer1:parameter(1 + u).value = (origin - 1) / rx.sample.sample_buffer.number_of_frames * 100 -- compensates for +/-1 discrepancy between Lua and Renoise
  end
  if source:sub(3,7) == "range" then
    value_to_hydra(rx.hydra, 5 + u, range)
    rx.doofer1:parameter(3 + u).value = range / rx.sample.sample_buffer.number_of_frames * 100
    set_slider_steps(range, se)
  end

  rx.xypad:parameter(1 + u).value = offset / (2 * range) + 0.5
  rx.xypad:parameter(6 + u).value = offset / (2 * range) + 0.5
  if (source:sub(3,8) ~= "origin" and source:sub(3,7) ~= "range") or position ~= old_position then
    value_to_hydra(rx.hydra, 1 + u, position)
    if se == "s" then rx.sample:move_slice_marker(rx.sample.slice_markers[1], position)
    else
      -- this code is needed because when the user manually moves e_marker to the same position as s_marker it causes issues, since both now have the same value
      -- so when the value is sent via sample.slice_markers[x], x doesn't matter since the first match in the marker list will be selected, which is always marker1
      if rx.sample.slice_markers[1] == rx.sample.slice_markers[2] then                   -- has the user moved e_marker to the same position as s_marker?
        local proper = min_ss
        if rx.doofer2:parameter(2).value >= 50 and rx.doofer2:parameter(2).value < 75 then proper = value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1) end
        if rx.sample.slice_markers[1] == 1 then                                          -- is s_marker at the start of the sample?
          rx.sample:move_slice_marker(rx.sample.slice_markers[1], proper + 2)            -- move s_marker beyond e_marker position - marker number doesn't matter here
          rx.sample:move_slice_marker(rx.sample.slice_markers[1], proper + 1)            -- move e_marker to proper position
          rx.sample:move_slice_marker(rx.sample.slice_markers[2], 1)                     -- move s_marker back to sample start (must be [2] to maintain mouse control when moving manually)
        else
          rx.sample:move_slice_marker(rx.sample.slice_markers[1], position - proper - 1) -- move s_marker backward - marker number doesn't matter here
          rx.sample:move_slice_marker(rx.sample.slice_markers[2], position)              -- move e_marker to proper position
          rx.sample:move_slice_marker(rx.sample.slice_markers[1], position - proper)     -- move s_marker back to proper position
        end
      else rx.sample:move_slice_marker(rx.sample.slice_markers[2], position)
      end
    end
    if done then
      if rawequal(rx.instrument, rxi) then vb.views.slice_size.value = vb.views.position_e.value - vb.views.position_s.value end
      rx.doofer2:parameter(4).value = (value_from_hydra(rx.hydra, 2) - value_from_hydra(rx.hydra, 1)) / rx.sample.sample_buffer.number_of_frames * 100
    end
  end
  if done then bypass = false end
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

gui_xypad = vb:xypad {
  id = "xypad",
  value = { x=0.5, y=0.5 },
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.xypad.value = { x=0.5, y=0.5 }
      else
        rxc1:parameter(1).value = value.x
        rxc1:parameter(2).value = value.y
      end
    end
  end
}

gui_set_markers = vb:button {
  id = "set_markers",
  text = "Set Markers",
  tooltip = "Set up instrument for use by this tool. Slice markers will be placed on the Origin points.",
  width = 108,
  pressed = function()
    if rxed_details() then
      rxc3:parameter(1).value = 0 -- in case it's already at 100
      rxc3:parameter(1).value = 100
    else
      if     #rxi.samples == 0 then renoise.app():show_warning("The selected instrument needs to contain a sample.")
      elseif rxs.sample_buffer.has_sample_data == false then renoise.app():show_warning("The selected sample must contain sample data.")
      elseif rxs.sample_buffer.number_of_frames == 1 then renoise.app():show_warning("The selected sample must be at least 2 samples in length.")
      elseif rxs.sample_buffer.number_of_frames > 10000000000 then renoise.app():show_warning("The selected sample must be 10,000,000,000 samples or less in length.")
      elseif #rxs.slice_markers >= 1 then renoise.app():show_warning("This tool is intended to be used on unsliced samples only.")
      elseif #rxi.phrases >= 118 then renoise.app():show_warning("This tool inserts 9 phrases into the instrument. Please remove some to make room.")
      else   prepare_instrument()
      end
    end
  end
}

gui_auto_reset = vb:checkbox {
  tooltip = "The XY Pad will automatically return to the center when the mouse button is released.",
  notifier = function(value)
    if value then vb.views.xypad.snapback = { x=0.5, y=0.5 }
    else          vb.views.xypad.snapback = nil
    end
  end
}

gui_interaction = vb:popup {
  id = "interaction",
  tooltip = "Changes how the markers can interact when moved. These effects do not apply when changing Origin, Range or Slice Size.\n\nNormal: No special marker interactions.\nPush: At Min Slice Size, moving a marker toward the other will push it.\nFollow: Moving a marker will cause the other to follow.\nFollow & Shrink: As Follow, but with a marker at Range limit or sample edge, moving the other toward it will shrink Slice Size.",
  items = { "Normal", "Push", "Follow", "Follow & Shrink" },
  width = 100,
  notifier = function(value)
    if not bypass and rxed_details() then
      bypass = true
      rxc3:parameter(2).value = (value - 1) * 25
      bypass = false
    end
  end
}

gui_snap = vb:popup {
  id = "snap",
  tooltip = "Snaps marker movement to selected points on the waveform. Does not apply when changing Origin or Range. Disables 'Interaction'.\n\nSimilar Value: Volume level matching other marker, within Tolerance. Applies to both stereo channels.\n0 Crossing: Volume level of 0, within Tolerance. Applies to both stereo channels.\nHex Point: Nearest 256th fraction of the waveform.\nBeat: Selected beat fraction, according to current BPM.",
  items = { "Off", "Similar Value", "0 Crossing", "Hex Point", "Beat: Whole", "Beat: Half", "Beat: Quarter", "Beat: 8th", "Beat: 16th", "Beat: 32nd", "Beat: 64th", "Beat: 128th", "Beat: 256th" },
  width = 92,
  notifier = function(value)
    if value == 1 then vb.views.interaction.active = true
    else               vb.views.interaction.active = false
    end
    if value == 2 or value == 3 then vb.views.tolerance.active = true
    else                             vb.views.tolerance.active = false
    end
    if not bypass and rxed_details() then
      bypass = true
      rxc3:parameter(6).value = value - 1
      bypass = false
    end
  end
}

gui_tolerance = vb:valuebox {
  id = "tolerance",
  tooltip = "Tolerance level for 'Similar Value' and '0 Crossing' Snap modes.",
  width = 79,
  value = 5,
  active = false,
  tostring = function(value) return tostring(("%.3f"):format(value) .. "%") end,
  tonumber = function(str)   return tonumber((str:gsub('%%',''))) end, -- double parentheses to exclude second return value
  notifier = function(value)
    if not bypass and rxed_details() then
      bypass = true
      rxc3:parameter(7).value = value
      bypass = false
    end
  end
}

gui_origin_s = vb:valuebox {
  id = "origin_s",
  width = 88,
  value = 1,
  min = 1,
  max = 1,
  tostring = function(value) return tostring(value - 1) end,
  tonumber = function(str)   return remove_non_numbers(str) end,
  notifier = function(value)
    if not bypass then
      value = round(value)
      if value > vb.views.origin_e.value - 1 then  -- don't pass the end origin
        value = vb.views.origin_e.value - 1
        bypass = true
        vb.views.origin_s.value = value
        bypass = false
      end
      if rxed_details() then 
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        value_to_hydra(rx.hydra, 3, value)
        move_markers("s_origin", rx.sample.slice_markers[1], rx.sample.slice_markers[1], rx) -- send position to see how it works with new origin
      end
    end
  end
}

gui_range_s = vb:valuebox {
  id = "range_s",
  width = 88,
  value = 1,
  min = 1,
  max = 1,
  tostring = function(value) return tostring(value) end, -- to allow single digit minumum instead of two
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass and rxed_details() then
      local rx = find_rxdata(s:instrument(vb.views.instr.value))
      value_to_hydra(rx.hydra, 5, round(value))
      move_markers("s_range", rx.sample.slice_markers[1], rx.sample.slice_markers[1], rx) -- send position to adjust to new range
    end
  end
}

gui_origin_e = vb:valuebox {
  id = "origin_e",
  width = 88,
  value = 2,
  min = 2,
  max = 2,
  tostring = function(value) return tostring(value - 1) end,
  tonumber = function(str)   return remove_non_numbers(str) end,
  notifier = function(value)
    if not bypass then
      value = round(value)
      if value < vb.views.origin_s.value + 1 then -- don't pass the start origin
        value = vb.views.origin_s.value + 1
        bypass = true
        vb.views.origin_e.value = value
        bypass = false
      end
      if rxed_details() then
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        value_to_hydra(rx.hydra, 4, value)
        move_markers("e_origin", rx.sample.slice_markers[2], rx.sample.slice_markers[2], rx) -- send position to see how it works with new origin
      end
    end
  end
}

gui_range_e = vb:valuebox {
  id = "range_e",
  width = 88,
  value = 1,
  min = 1,
  max = 1,
  tostring = function(value) return tostring(value) end, -- to allow single digit minumum instead of two
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass and rxed_details() then
      local rx = find_rxdata(s:instrument(vb.views.instr.value))
      value_to_hydra(rx.hydra, 6, round(value))
      move_markers("e_range", rx.sample.slice_markers[2], rx.sample.slice_markers[2], rx) -- send position to adjust to new range
    end
  end
}

gui_slider_s = vb:slider {
  id = "slider_s",
  value = 0.5,
  active = false,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.slider_s.value = 0.5
      else rxc1:parameter(6).value = value
      end
    end
  end
}

gui_offset_s = vb:valuebox {
  id = "offset_s",
  width = 94,
  min = 0,
  max = 0,
  value = 0,  
  active = false,
  tostring = function(value) return ("%+.0f"):format(tostring(value)) end,
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.offset_s.value = 0
      else
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        move_markers("s_offset", vb.views.origin_s.value + round(value), rx.sample.slice_markers[1], rx)
      end
    end
  end
}

gui_position_s = vb:valuebox {
  id = "position_s",
  width = 88,
  max = 1,
  value = 1,
  active = false,
  tostring = function(value) return ("%.0f"):format(tostring(value - 1)) end,
  tonumber = function(str)   return remove_non_numbers(str) end,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.position_s.value = 1
      else
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        move_markers("s_position", round(value), rx.sample.slice_markers[1], rx)
      end
    end
  end
}

gui_slider_e = vb:slider {
  id = "slider_e",
  value = 0.5,
  active = false,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.slider_e.value = 0.5
      else rxc1:parameter(7).value = value
      end
    end
  end
}

gui_offset_e = vb:valuebox {
  id = "offset_e",
  width = 94,
  min = 0,
  max = 0,
  value = 0,
  active = false,
  tostring = function(value) return ("%+.0f"):format(tostring(value)) end,
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.offset_e.value = 0
      else
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        move_markers("e_offset", vb.views.origin_e.value + round(value), rx.sample.slice_markers[2], rx)
      end
    end
  end
}

gui_position_e = vb:valuebox {
  id = "position_e",
  width = 88,
  max = 1,
  value = 1,
  active = false,
  tostring = function(value) return ("%.0f"):format(tostring(value - 1)) end,
  tonumber = function(str)   return remove_non_numbers(str) end,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.position_e.value = 1
      else
        local rx = find_rxdata(s:instrument(vb.views.instr.value))
        move_markers("e_position", round(value), rx.sample.slice_markers[2], rx)
      end
    end
  end
}

gui_slice_size = vb:valuebox {
  id = "slice_size",
  width = 88,
  min = 1,
  max = 1,
  value = 1,
  active = false,
  tostring = function(value) return ("%.0f"):format(tostring(value)) end,
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass then
      if not rxed_details() then vb.views.slice_size.value = vb.views.origin_e.value - vb.views.origin_s.value
      else changing_ss(find_rxdata(s:instrument(vb.views.instr.value)), round(value))
      end
    end
  end
}

gui_min_ss = vb:valuebox {
  id = "min_ss",
  width = 88,
  min = 1,
  max = 1,
  value = 1,
  active = false,
  tostring = function(value) return ("%.0f"):format(tostring(value)) end,
  tonumber = function(str)   return tonumber(str) end,
  notifier = function(value)
    if not bypass then
      value = round(value)
      if not rxed_details() then vb.views.min_ss.value = 1
      else
        bypass = true
        if value > vb.views.slice_size.value then
          value = vb.views.slice_size.value
          vb.views.min_ss.value = value
        end
        rxc3:parameter(5).value = value / rxi:sample(1).sample_buffer.number_of_frames * 100
        value_to_hydra(rxc4, 7, value)
        bypass = false
      end
    end
  end
}

gui_slice_anchor = vb:switch {
  id = "slice_anchor",
  tooltip = "The anchor point used when changing the Slice Size value.",
  items = { "Left", "Center", "Right" },
  width = 127,
  value = 2,
  notifier = function(value)
    if not bypass and rxed_details() then
      bypass = true
      if     value == 1 then rxc3:parameter(3).value = 0
      elseif value == 2 then rxc3:parameter(3).value = 50
      else                   rxc3:parameter(3).value = 100
      end
      bypass = false
    end
  end
}

gui_instr_link = vb:checkbox {
  id = "instr_link",
  tooltip = "Changing the selected instrument in Renoise will change the instrument in the tool GUI and vice versa.",
  value = true,
  notifier = function(value)
    if value then vb.views.instr.value = s.selected_instrument_index end
  end
}

gui_instr = vb:valuebox {
  id = "instr",
  min = 1,
  max = 256,
  value = 1,
  tostring = function(value) return tostring(("%02X"):format(value - 1)) end,
  tonumber = function(str)   return remove_non_numbers(str) end,
  notifier = function(value)
    if value > #s.instruments then vb.views.instr.value = #s.instruments
    else
      if vb.views.instr_link.value == true then s.selected_instrument_index = value end
      change_gui_values()
    end
  end
}

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
dialog_content = vb:column {
  margin = DEFAULT_MARGIN,
  
  vb:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    
    vb:horizontal_aligner {
      width = "100%",
      margin = 10,
      
      vb:vertical_aligner {
        gui_xypad,
        vb:space { height = 9 },
        gui_set_markers,
      },
      
      vb:column{
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "Pad Reset",   width = 54 }, gui_auto_reset,
          vb:space { width = 10 }, vb:text { text = "Interaction", width = 56 }, gui_interaction,
          vb:space { width = 10 }, vb:text { text = "Snap",        width = 29 }, gui_snap, gui_tolerance
        },
        
        vb:space { height = 9 },
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "Start Origin", width = 61 }, gui_origin_s,
          vb:space { width = 10 }, vb:text { text = "Start Range",  width = 64 }, gui_range_s
        },
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "End Origin", width = 61 }, gui_origin_e,
          vb:space { width = 10 }, vb:text { text = "End Range",  width = 64 }, gui_range_e
        },
        
        vb:space { height = 9 },
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "Start",    width = 30 }, gui_slider_s,
          vb:space { width =  9 }, vb:text { text = "Offset",   width = 35 }, gui_offset_s,
          vb:space { width = 10 }, vb:text { text = "Position", width = 42 }, gui_position_s
        },
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "End",      width = 30 }, gui_slider_e,
          vb:space { width =  9 }, vb:text { text = "Offset",   width = 35 }, gui_offset_e,
          vb:space { width = 10 }, vb:text { text = "Position", width = 42 }, gui_position_e
        },
        
        vb:space { height = 9 },
        vb:horizontal_aligner {
          width = "100%",
          vb:space { width = 10 }, vb:text { text = "Slice Size",     width = 61 }, gui_slice_size,
          vb:space { width = 10 }, vb:text { text = "Min Slice Size", width = 64 }, gui_min_ss,
          vb:space { width = 10 }, gui_slice_anchor
        },
      },
    },
  },
  vb:space { height = 5 },
  vb:row {
    style = "panel",
    width = "100%",
    margin = 3,
    
    vb:space { height = 8 },
    vb:horizontal_aligner {
      width = "100%",
      vb:space { width = 5 }, gui_instr_link,
      vb:space { width = 5 }, vb:text { text = "Instr.", width = 28 }, gui_instr,
      vb:space { width = 5 }, vb:text { id = "instr_name", text = "Untitled" },
    },
  },
}
