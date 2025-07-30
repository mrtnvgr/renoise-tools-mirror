require "math"
require "table"
require "string"

---------------------------------------------------------------------------------------------------
-- test(x): similar to default boolean test in other languages
function test(x) return x ~= "" and x ~= 0 and x end

-- numeric only version of "test"
function nonzero(x) return x ~= 0 and x end

---------------------------------------------------------------------------------------------------
-- some rounding
function round_1_256(v) return math.floor(256*v+0.5)/256 end  -- round to 1/256
function round(v) return math.floor(v+0.5) end                -- round to integer

---------------------------------------------------------------------------------------------------
function limit_rng(v, min_v, max_v)
-- clip v to between min_v & max_v
  return v < min_v and min_v or v < max_v and v or max_v
end

---------------------------------------------------------------------------------------------------
function lin_interp(
  frac,           -- fraction between 0..1
  min_v, max_v    -- edge points
)
-- interpolate between min_v to max_v using frac
  return (1-frac)*min_v+frac*max_v
end

---------------------------------------------------------------------------------------------------
function lin_frac(
  v,              -- value
  min_v, max_v    -- edge points
)
-- determine frac for v between min_v & max_v
  return (v-min_v)/(max_v-min_v)
end

---------------------------------------------------------------------------------------------------
function binary_search(array, cmp_fn, lower_idx, upper_idx)
-- perform forward binary search calling "cmp_fn" on the mid element of each search segment
-- lower_idx and upper_idx are optional
-- return the index of the lowest-indexed element satisfying the cmp_fn
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
  if not lower_idx then lower_idx = 1 end
  if not upper_idx then upper_idx = #array+1 end
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
function map(func, array)
-- apply "func" to each element that can be indexed as an integer in "array" and return as an array
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

function apply(func, array)
-- apply "func" to each element that can be indexed as an integer in "array" and return as an array
  for i,v in ipairs(array) do func(v) end
end

---------------------------------------------------------------------------------------------------
-- renoise device parameter to/from a value between 0 & 1 scaling
function param_to_value01(param) return lin_frac(param.value, param.value_min, param.value_max) end
function set_param_from_value01(param, v) param.value = lin_interp(v, param.value_min, param.value_max) end

---------------------------------------------------------------------------------------------------
-- set a value box with limits on the value
function set_valuebox(vb, v) vb.value = limit_rng(v, vb.min, vb.max) end

---------------------------------------------------------------------------------------------------
-- change value box by calling function "fn" with limits on value
function chg_valuebox(vb, fn) vb.value = limit_rng(fn(vb.value), vb.min, vb.max) end

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



---------------------------------------------------------------------------------------------------
FLASH_MSG_TXT = ""
FLASH_MSG_N = 0
function _flash_msg_timer_fn()
-- timer callback for flash_msg
    if FLASH_MSG_N > 5 then
      remove_timer(_flash_msg_timer_fn)
      return
    end
    
    renoise.app():show_status(FLASH_MSG_N%2==1 and FLASH_MSG_TXT or "")
    FLASH_MSG_N = FLASH_MSG_N+1
end

---------------------------------------------------------------------------------------------------
function flash_msg(msg)
-- flash "msg" in the renoise status bar
--
  FLASH_MSG_TXT = msg 
  renoise.app():show_status(FLASH_MSG_TXT)
  FLASH_MSG_N = 0  
  add_timer(_flash_msg_timer_fn, 100)
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
    print(err)
    flash_msg(err)
    return nil
end

---------------------------------------------------------------------------------------------------
function eval_tonumber_str(s) return eval_str("tonumber(" .. s .. ")") end


local NOTE_NAMES = {'c-', 'c#', 'd-', 'd#', 'e-', 'f-', 'f#', 'g-', 'g#', 'a-', 'a#', 'b-'}

---------------------------------------------------------------------------------------------------
function note_to_text(n)
-- convert note to text when n=0 is c-4, n=12 c-1, n=24 c2, etc
  local nr = math.floor(n+0.5)
  local cents = (n-nr)*100
  local octave = math.floor(nr/12)+4
  return string.format('%s%d:%+03d', NOTE_NAMES[nr%12+1], octave, cents)
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