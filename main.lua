-- Simple slicer, renoise 2.8 script
--
-- Create evenly spaced sample slices based on a given alignment and frequency/period via
-- a small GUI dialog
--
-- e.g. use to slice a big slab sample into chunks that you can trigger nicely at the
-- start of each pattern
--
-- History
-- 26/06/2012: darrell.barrell@gmail.com - version 1
--

---------------------------------------------------------------------------------------------------
-- test(x): similar to default boolean test in other languages
function test(x) return x ~= "" and x ~= 0 and x end

---------------------------------------------------------------------------------------------------
function limit_rng(v, min_v, max_v)
-- clip v to between min_v & max_v
  return v < min_v and min_v or v < max_v and v or max_v
end

---------------------------------------------------------------------------------------------------
function binary_search(array, cmp_fn)
-- perform forward binary search calling "cmp_fn" on the mid element of each search segment
--
-- return the index of the lowest-indexed element satisfying the cmp_fn
--
-- notes:
--   cmp_fn must be > or >= for a increasing-order sorted array
--
--   the return index will be 1 past the end of the array if
-- all elements in the array fail the compare function or the array is empty
--
-- e.g. find lowest "idx" such that my_array[idx] >= some_number:
--     my_array = { sorted numbers }
--     idx = binary_search(my_array, function(el) return el >= some_number end)
--     
  local lower_idx = 1
  local upper_idx = #array+1
  while true do
    -- done when we've got nothing more to check
    if lower_idx >= upper_idx then
      return lower_idx
    end

    local mid_idx = math.floor((lower_idx+upper_idx)/2)
    
    if cmp_fn(array[mid_idx], mid_idx) then
      -- exclude all above mid point (but keep the mid point)
      upper_idx = mid_idx
    else
      -- exclude all below including the mid point
      lower_idx = mid_idx+1
    end
  end
end

---------------------------------------------------------------------------------------------------
function flash_msg(msg)
-- flash "msg" in the renoise status bar
--
  renoise.app():show_status(msg)
  local n = 0
  local function fn()    
    if n > 5 then
      renoise.tool():remove_timer(fn)
      return
    end
    
    renoise.app():show_status(test(n%2) and msg or "")
    n = n+1
  end
  renoise.tool():add_timer(fn, 100)
end

---------------------------------------------------------------------------------------------------
function eval_str(s)
-- evaluate a string as a LUA expression
--
-- return nil on error otherwise the evaluated expression
--
-- prints to renoise status bar on error
--
    local fn, err = loadstring('return ' .. s)
    if fn then
      local ok, result = pcall(fn)
      if ok then return result end
      err = result
    end
    flash_msg(err)
    return nil
end

---------------------------------------------------------------------------------------------------
function eval_tonumber_str(s) return eval_str("tonumber(" .. s .. ")") end

---------------------------------------------------------------------------------------------------
function set_valuebox(vb, v) vb.value = limit_rng(v, vb.min, vb.max) end

---------------------------------------------------------------------------------------------------
function add_notifier(observable, notfier)
  if observable:has_notifier(notfier) then return end
  observable:add_notifier(notfier)
end
---------------------------------------------------------------------------------------------------
function remove_notifier(observable, notfier)
  if not observable:has_notifier(notfier) then return end
  observable:remove_notifier(notfier)
end

---------------------------------------------------------------------------------------------------
function remove_timer(fn)
  if not renoise.tool():has_timer(fn) then return end
  renoise.tool():remove_timer(fn)
end

---------------------------------------------------------------------------------------------------
function add_timer(fn, msec)
  remove_timer(fn)
  renoise.tool():add_timer(fn, msec)
end

---------------------------------------------------------------------------------------------------
function add_timer_one_shot(fn, msec)
-- generate wrapper function in "timer_fn" that removes the timer once it has run & schedule
--
-- return the wrapper function (so that "remove_timer" can be called on it if need be)
--
  local function timer_fn()
    fn()
    renoise.tool():remove_timer(timer_fn)
  end
  renoise.tool():add_timer(timer_fn, msec)
  return timer_fn
end


--=================================================================================================
-- current auto-repeat button function
RPT_BUTTON_FN = nil

-------------------------------------------------------------------------------------------------
function button_rpt1_timer_fn()
  remove_timer(button_rpt1_timer_fn)
  if not RPT_BUTTON_FN then return end
  -- repeat at 20 times/second
  add_timer(button_rpt2_timer_fn, 50)
  RPT_BUTTON_FN()
end
function button_rpt2_timer_fn()
  if not RPT_BUTTON_FN then
    remove_timer(button_rpt2_timer_fn)
    return
  end
  RPT_BUTTON_FN()
end
function set_button_rpt_fn(fn)
  RPT_BUTTON_FN = fn
  -- initial delay of 0.4 seconds
  add_timer(button_rpt1_timer_fn, 400)
  fn()
end
function clr_button_rpt_fn()
  RPT_BUTTON_FN = nil
  remove_timer(button_rpt1_timer_fn)
  remove_timer(button_rpt2_timer_fn)
end


-------------------------------------------------------------------------------------------------
function vb_button_rpt(args)
-- create a button with auto-repeat on the notifier
-- expect
--   args.vb: the viewbuilder to use
--   args.notifier: function to call with auto-repeat
--
--   plus stuff passed to the button constructor
--     args.text, args.color, args.bitmap, args.tooltip
--
  local vb = args.vb
  local fn = args.notifier
  args.notifier = nil
  args.vb = nil
  args.pressed = function() set_button_rpt_fn(fn) end
  args.released = function() clr_button_rpt_fn() end
  return vb:button(args)
end


--==================================================================================================
-- stuff to do with our GUI
--

local slicer_dialog

-- view builder
local vb

-- current instrument
local instrument

-- alignment units menu selection (1=samples, 2=seconds, 3=slice periods)
local align_type = 1

-- bpm type menu selection (1=slices/minute, 2=seconds/slice, 3=samples/slice)
local slice_units = 1

---------------------------------------------------------------------------------------------------
local function instrument_chg_fn()
  instrument = renoise.song().selected_instrument
end

---------------------------------------------------------------------------------------------------
local function get_sample_buf()
  local buf = instrument.samples[1].sample_buffer
  if not buf.has_sample_data then
    flash_msg("No sample data in ".. (test(instrument.name) or "unnamed") .."/" .. (test(instrument.samples[1].name) or "Sample 00"))
    return nil
  end
  return buf
end

---------------------------------------------------------------------------------------------------
local function get_effective_sample_rate()
  -- effective sample rate taking into account instrument tuning
  local buf = get_sample_buf()
  if not buf then return end
  local samp = instrument.samples[1]
  return buf.sample_rate * 2^((samp.transpose+samp.fine_tune/128)/12)
end

---------------------------------------------------------------------------------------------------
local function get_samples_per_slice()
  local v = vb.views.slice_value.value
  local t = vb.views.slice_units.value

  -- v is 1/100 slices per minute
  if slice_units == 1 then  return 60.0*get_effective_sample_rate()/(v*.01)
  -- v is 1/100 seconds/slice
  elseif slice_units == 2 then return get_effective_sample_rate()*(v*.01)
  -- v is samples/slice
  else return v
  end
end

---------------------------------------------------------------------------------------------------
local function get_align_samples()
  local v = vb.views.align_value.value
  
  -- start samples
  if align_type == 1 then return v

  -- start value is in 1/100 seconds
  elseif align_type == 2 then return 0.01*v*get_effective_sample_rate()
    
  -- start is in 1/100 slices
  else return 0.01*v*get_samples_per_slice()
  end
end

---------------------------------------------------------------------------------------------------
local function update_align_type()
  local s = get_align_samples()
  
  -- new align_type
  local t = vb.views.align_type.value
  align_type = t
  
  local v
  -- convert from samples to...
  -- samples
  if t == 1 then v = s
  -- 1/100 seconds
  elseif t == 2 then v = s/get_effective_sample_rate()*100     
  -- 1/100 slice
  else v = s/get_samples_per_slice()*100
  end
  set_valuebox(vb.views.align_value, v)
end

---------------------------------------------------------------------------------------------------
local function update_slice_units()
  local s = get_samples_per_slice()
  
  -- new slice_units
  local t = vb.views.slice_units.value
  slice_units = t
  
  local v
  
  -- convert from samples/slice to...
  -- 1/100 slices/minute
  if t == 1 then v = 100*get_effective_sample_rate()*60/s

  -- 1/100 seconds/slice
  elseif t == 2 then v = 100*s/get_effective_sample_rate()

  -- samples/slice
  else v = s
  end
  set_valuebox(vb.views.slice_value, v)  
end


---------------------------------------------------------------------------------------------------
local function create()
  local buf = get_sample_buf()
  if not buf then return end

  local num_samps = buf.number_of_frames

  local samps_per_slice = get_samples_per_slice()
  
  -- start sample
  local samp = get_align_samples()%samps_per_slice
  
  -- skip the first slice if we start at sample 0
  if math.floor(samp) == 0 then samp = samp+samps_per_slice end
  
  -- can't have more than 255 slices
  local n = math.ceil(math.min((num_samps - samp) / samps_per_slice, 255))
  
  -- create slices
  local slices = {}
  if n > 0 then slices[n] = 0 end

  -- add 1 because LUA indexes from 1
  samp = samp+1
  
  for i = 1,n do
    slices[i] = math.floor(samp)
    samp = samp + samps_per_slice
  end
  -- set them...
  instrument.samples[1].slice_markers = slices
  
  flash_msg("Created "..tostring(n).." slices")
end

---------------------------------------------------------------------------------------------------
local function display_slice(move)
  local samp = instrument.samples[1]
  local buf = get_sample_buf()
  if not buf then return end
  
  -- get slices
  local slices = samp.slice_markers
  if #slices < 1 then return end
  
  -- number of samples
  local len = buf.number_of_frames

  -- 
  local disp_len = buf.display_length

  -- zoom if not zoomed
  if disp_len == len then
    if #slices == 1 then
      if slices[1] > 1 then buf.display_length = slices[1] end
    else
      buf.display_length = math.max(slices[2]-slices[1], 16)
    end
    return
  end

  -- first displayed sample
  local disp_start = buf.display_start
  local disp_end = disp_start + disp_len
  
  -- find slice after first displayed sample
  local i = binary_search(slices, function(v) return v >= disp_start end)
  
  -- determine how to shift the display
  if move < 0 then
    -- move to the left
    if i < 2 then
      disp_start = 1
    elseif i > #slices or slices[i] >= disp_end then
      disp_start = slices[i-1]-disp_len/2
    else
      disp_start = disp_start + slices[i-1] - slices[i]
    end    
  elseif i <= #slices then
    -- move to the right
    if i == #slices or slices[i] >= disp_end then
      disp_start = slices[i]-disp_len/2
    else
      disp_start = disp_start + slices[i+1] - slices[i]
    end
  end
    
  buf.display_start = limit_rng(disp_start, 1, len-disp_len)
end

---------------------------------------------------------------------------------------------------
local function key_handler(dialog, key)

  -- use left & right keys to move sample display to prv/next slice
  if key.name == 'left' then
    if key.modifiers == '' then
      display_slice(-1)
      return nil
    end
    
  elseif key.name == 'right' then
    if key.modifiers == '' then
      display_slice(1)
      return nil
    end

  elseif key.name == 'esc' and key.modifiers == '' then
    slicer_dialog:close()
  end
  
  -- pass all other keys back to renoise
  return key
end



---------------------------------------------------------------------------------------------------
local function get_sample_selection()
-- get sample selection range as a 2 element array containing start & end sample position numbers
-- or nil if full/nothing is selected (with an error)

  local buf = get_sample_buf()
  if not buf then return nil end
  
  local r = buf.selection_range
  
  -- check that the user has actually selected something
  if r[1] == 1 and r[2] == buf.number_of_frames then
    flash_msg("Make a selection in the sample editor first")
    return nil
  end
  
  return r
end

-------------------------------------------------------------------------------------------------
function timer_fn()
-- use the timer to poll for dialog close
  if slicer_dialog and slicer_dialog.visible then return end
  
  -- dialog closed... cleanup (is there a better way??)
  slicer_dialog = nil
  remove_notifier(renoise.song().selected_instrument_observable, instrument_chg_fn)
  renoise.tool():remove_timer(timer_fn)
end


---------------------------------------------------------------------------------------------------
local function show_slicer_dialog()
  if slicer_dialog and slicer_dialog.visible then
    slicer_dialog:show()
    return
  end

  vb = renoise.ViewBuilder()    -- create a new ViewBuilder
  
  local view = vb:column {
    margin = 4, spacing = 4, style='invisible',
    vb:row {
      style='group', spacing=1, margin=1,
      vb:vertical_aligner {
        width=120,
        vb:popup {
          id = "align_type", items = { "Align sample", "Align second", "Align slice" }, width="100%",
          tooltip = "Alignment Position Units",
          notifier = update_align_type
        },
        vb:valuebox {
          id = "align_value", min = -1e9, max = 1e9, value = 0, width="100%",
          tooltip = "Alignment position\nNote that this may be an expression such as '123*456'",
          -- note that v is in samples, 1/100 seconds or 1/100 slices
          tostring = function(v) return tostring(align_type==1 and v or v*0.01) end,
          tonumber = function(s)
            local v = eval_tonumber_str(s)
            if v==nil then return nil end
            return align_type==1 and v or v*100
          end
        },
      },
      vb:button {
        text = "From start\nof selection", width=80,
        tooltip = "Create slices aligned to the\nstart of sample selection",
        notifier = function()
          -- adjust start sample to align with selection
          local sel = get_sample_selection()
          if not sel then return end
          
          align_type = 1
          set_valuebox(vb.views.align_value, sel[1] - 1)
          update_align_type()
          
          create()
        end
      },
    },
    vb:row {
      style='group', spacing=1, margin=1,
      vb:vertical_aligner {
        width=120,
        vb:popup {
          id = "slice_units", items = { "slices/minute", "seconds/slice", "samples/slice" }, width="100%",
          tooltip = "Slice period/frequency units",
          notifier = update_slice_units
        },
        vb:valuebox {
          id = "slice_value", min = 1, max = 1e9, value = renoise.song().transport.bpm/16*100, width="100%",
          tooltip = "Slice period/frequency\nNote that this may be an expression such as '150/16'",
          tostring = function(v) return tostring(slice_units==3 and v or v*0.01) end,
          tonumber = function(s)
            local v = eval_tonumber_str(s)
            if v==nil then return nil end
            return slice_units==3 and v or v*100
          end
        },
      },
      vb:button {
        text = "Sync start\nof selection", width=80,
        tooltip = "Nudge slice period to be synchronized\nwith start of sample selection",
        notifier = function()
          local sel = get_sample_selection()
          if not sel then return end

          local dist = sel[1]-get_align_samples()
          local n_slices = math.floor(0.5 + dist / get_samples_per_slice())
          if n_slices == 0 then
            flash_msg("Selection too close to alignment position")
            return
          end
          
          -- set measure in samples per slice
          
          set_valuebox(vb.views.slice_value, dist/n_slices)
          slice_units = 3
          update_slice_units()
          create()
        end
      },
    },
    vb:horizontal_aligner {
      mode = "justify",
      vb:button {
        text = "Create from\nselection",
        tooltip = "Create evenly spaced slices\nsynchronized with selected sample range",
        notifier = function()
          local sel = get_sample_selection()
          if not sel then return end
          
          -- samples per slice (entire selection)
          local samps_per_slice = sel[2]-sel[1]+1
          slice_units = 3
          set_valuebox(vb.views.slice_value, samps_per_slice)

          -- start sample
          align_type = 1
          set_valuebox(vb.views.align_value, sel[1]%samps_per_slice-1)
          
          -- update...
          update_align_type()
          update_slice_units()
          create()
        end
      },
      vb:column {
        style='group',
        vb:text { text = "Display slice", tooltip = "Bring previous/next slice into view (on sample 00 of instrument)" },
        vb:horizontal_aligner {
          vb_button_rpt { vb=vb, text = "<", notifier = function() display_slice(-1) end, width="50%" },
          vb_button_rpt { vb=vb, text = ">", notifier = function() display_slice(1) end, width="50%" },
        },
      },
      vb:button {
        text = "Create\n",
        tooltip = "Create evenly spaced slices according to\n'Slice period/frequency' and 'Alignment Position'",
        notifier = create
      }
    }
  }

  
  -------------------------------------------------------------------------------------------------
  instrument_chg_fn()
  add_notifier(renoise.song().selected_instrument_observable, instrument_chg_fn)
  add_timer(timer_fn, 2000)
  slicer_dialog = renoise.app():show_custom_dialog('Simple Slicer', view, key_handler)

end



renoise.tool():add_menu_entry {
  name = "Sample Editor:Simple Slicer...",
  invoke = show_slicer_dialog
}

--_AUTO_RELOAD_DEBUG = function()
  -- do tests like showing a dialog, prompts whatever, or simply do nothing
  --show_slicer_dialog()
--end

