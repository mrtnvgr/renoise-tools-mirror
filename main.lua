--[[============================================================================
com.duncanhemingway.zeropointstereo.xrnx (main.lua)
============================================================================]]--

--------------------------------------------------------------------------------
-- global declarations
--------------------------------------------------------------------------------

s = 0
sb = nil
sbo = nil
the_gui = nil
vb = renoise.ViewBuilder()

--------------------------------------------------------------------------------
-- menu entry
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Zero Point Stereo",
  invoke = function()
    s = renoise.song()
    add_notifier(renoise.tool().app_new_document_observable, function() sbo = nil end)
    add_notifier(s.selected_instrument_observable, sample_changed)
    add_notifier(s.selected_sample_observable, sample_changed)
    sample_changed()
    if not the_gui or not the_gui.visible then
      the_gui = renoise.app():show_custom_dialog("Zero Point Stereo", dialog_content)
    end
  end
}

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

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

-- handle selected sample changing

function sample_changed()
  if sbo ~= nil then
    remove_notifier(sbo, sample_changed)
    sbo = nil
  end

  vb.views.cdindex.active = false
  if #s.selected_instrument.samples ~= 0 then
    sb  = s.selected_sample.sample_buffer
    sbo = s.selected_sample.sample_buffer_observable
    add_notifier(sbo, sample_changed)
    if sb.has_sample_data == true and sb.sample_rate == 44100 then vb.views.cdindex.active = true end -- allow CD index for 44.1KHz samples
  end
end

-- get overall sample volume at current and previous frames

function sample_volume(frame)
  if sb.number_of_channels == 1 then
    return math.abs(sb:sample_data(1, frame)) + math.abs(sb:sample_data(1, frame - 1))
  else 
    return math.abs(sb:sample_data(1, frame)) + math.abs(sb:sample_data(1, frame - 1)) + math.abs(sb:sample_data(2, frame)) + math.abs(sb:sample_data(2, frame - 1))
  end
end

-- find best zero point within selection

function find_best()
  local ss = s.selected_sample
  local bestf = 0
  local bestv = 4
  local frame_skip = 1
  local selection_start = sb.selection_start
  
  if vb.views.cdindex.value == true and vb.views.cdindex.active == true then
    frame_skip = 588 
    selection_start = math.max(589, (math.ceil((sb.selection_start - 1) / 588) * 588) + 1) -- -1 for calculation then +1 to compensate for +/-1 discrepancy between Lua and Renoise
  else
    selection_start = math.max(2, sb.selection_start) -- marker at start of waveform is useless
  end
  for frame = selection_start, sb.selection_end, frame_skip do
    if sample_volume(frame) <= bestv then
      if #ss.slice_markers == 0 then
        bestf = frame
        bestv = sample_volume(frame)
      else
        local exists = false
        for m = 1, #ss.slice_markers do
          if frame == ss.slice_markers[m] then
            exists = true
            break
          end
        end
        if exists == false then
          bestf = frame
          bestv = sample_volume(frame)
        end
      end
    end
  end
  return bestf
end

-- place slice marker on best zero point within selection

function place_marker()
  if #s.selected_instrument.samples > 1 and #s.selected_sample.slice_markers == 0 then
    if renoise.app():show_prompt("Clear Samples!", "This will delete all sample slots apart from this one. Click OK if you want to go ahead and create a sliced sample.", {"OK", "Cancel"}) == "OK" then
      s.selected_instrument:swap_samples_at(s.selected_sample_index, 1)
      for index = 2, #s.selected_instrument.samples do
        s.selected_instrument:delete_sample_at(2)
      end
    else return
    end
  end
  local bestf = find_best()
  if bestf ~= 0 then s.selected_sample:insert_slice_marker(bestf) end -- detect if all frames are occupied by markers
end

-- move existing slice marker to best zero point within selection

function move_marker()
  local markerf = 0
  local markers = 0
  for _, m in pairs(s.selected_sample.slice_markers) do
    if m > sb.selection_end then break end
    if m >= sb.selection_start and m <= sb.selection_end then markers = markers + 1 end
    if markers > 1 then
      renoise.app():show_warning("The selection contains more than one marker.")
      return
    end
    markerf = m
  end
  if markers == 0 then renoise.app():show_warning("There is no marker in the selection.")
  else
    local bestf = find_best()
    if bestf ~=0 then s.selected_sample:move_slice_marker(markerf, bestf) end
  end
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

gui_place = vb:button {
  text = "Place Marker",
  tooltip = "Place a slice marker on the best zero point within the selection.",
  pressed = function()
    if     #s.selected_instrument.samples == 0     then renoise.app():show_warning("The selected instrument needs to contain a sample.")
    elseif sb.has_sample_data             == false then renoise.app():show_warning("The selected sample must contain sample data.")
    elseif sb.number_of_frames            == 1     then renoise.app():show_warning("The selected sample must be at least 2 samples in length.")
    else   place_marker()
    end
  end
}

gui_move = vb:button {
  text = "Move Marker",
  tooltip = "Move an existing slice marker to the best zero point within the selection.",
  pressed = function()
    if     #s.selected_instrument.samples == 0     then renoise.app():show_warning("The selected instrument needs to contain a sample.")
    elseif sb.has_sample_data             == false then renoise.app():show_warning("The selected sample must contain sample data.")
    elseif sb.number_of_frames            == 1     then renoise.app():show_warning("The selected sample must be at least 2 samples in length.")
    else   move_marker()
    end
  end
}

gui_cdindex = vb:checkbox {
  id = "cdindex",
  tooltip = "Restrict this tool to placing/moving markers on CD frames of 588 samples in length. Only works with waveforms of 44.1KHz.",
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
      
      vb:column{
        vb:horizontal_aligner {
          width = "100%",
          gui_place, vb:space { width = 10 },
          gui_move, vb:space { width = 10 },
          vb:text { text = "CD Index", }, gui_cdindex
        },
      },
    },
  },
}
