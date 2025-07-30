require "misc"

--=================================================================================================
--=================================================================================================
-- globals
--=================================================================================================
--=================================================================================================

-------------------------------------------------------------------------------------------------
RS = nil

-- view builder
VB = renoise.ViewBuilder()

-- our dialog window
DIALOG = nil

-- quantizing and stepping values
STEP_VALUE = 1

-- whether we are quantizing or stepping (nil for stepping)
QUAN_OFFSET_VALUE = nil

-- nonzero(STEP_VALUE) or 1
STEP_VALUE1 = 1

--
SKIP_QUAN_LINE_POS = 1

-- current line position that will be used when adding the next point, may be fractional (note, starts from 1)
LINE_POS = 1

-- this is the most recent line position that was not a result from messing with quantization controls
NON_QUAN_LINE_POS = 1

-- selected line as reported by renoise (use this for polling selected line)
RS_SELECTED_LINE = -1

-- need to skip polling of selected line for 1 period because renoise.song().selected_line_index
-- seems to have a delay after writing a new value to when it returns the new value when read back
SKIP_RENOISE_LINE_POLL = false

-- last user selected rng mode (as opposed to auto mode based on track param name)
LAST_SELECTED_RNG_MODE = 1
AUTO_SELECTED_RNG_MODE = nil

--
COPY_VALUE = 0
COPY_NOTE = nil

-- whether we're editing or not
EDIT_MODE = true


--=================================================================================================
--=================================================================================================
-- value mapping mode stuff
--=================================================================================================
--=================================================================================================

---------------------------------------------------------------------------------------------------
-- helpers for VALUE_MODES
function _value_mode_value_text(me, param) 
  return param.value_string .. ' / ' .. string.format('%.1f', param_to_value01(param)*100)
end

function _value_mode_value_text_note(me, param)
  return param.value_string .. ' / ' .. string.format('%.1f', param_to_value01(param)*100) ..
    ' / ' .. note_to_text(me:value_to_note(param_to_value01(param)))
end

function _value_mode_get_note_to_value_abs(me, note)
-- absolute mode, convert to a note relative c0, input note=0 corresponds to GUI octave-1
  return me:note_to_value(note + VB.views.octave.value*12 - 48 - 12)
end

function _value_mode_get_note_to_value_relative(me, note)
-- relative to whatever is playing, input note=0 corresponds to GUI octave_offs-1
  return me:note_to_value(note + VB.views.octave_offs.value*12 - 12)
end

---------------------------------------------------------------------------------------------------
-- param mode functions for each mode
VALUE_MODES = {
  -- "note" is either relative to current pitch (in the case of a pitch shift) or relative to c-4
  -- for absolute freqs
  
  -- name=string that appears in popup
  -- tooltip=string addes to tooltip
  -- note_to_value=function(me, n) to map a note (-48..48, relative c4) to a value (return nil for not possible)
  -- value_to_note=function(me, v) to map a value to a note (-48..48, relative c4) (return nil for not possible)
  -- param_value_text=function(me, param) to return param value text as a string
  -- get_note_to_value=function(me, note) given a keyboard note (0=low C..24=high C), return value
  -- show_controls=function(me) show sub control row when selected
  {
    name='Linear',
    tooltip='Linear: Simple linear scaling between L & H values',
    note_to_value=function(me, n) end,
    value_to_note=function(me, v) end,
    param_value_text=_value_mode_value_text,
    get_note_to_value=function(me, note) return lin_interp(note/24, VB.views.a.value*0.01, VB.views.b.value*0.01) end,
    show_controls=function(me) VB.views.linear_mode_row.visible = true end
  },
  {
    name='Renoise Freq 22050',
    tooltip='Renoise Freq 22050: Select for freq control of native Filter, RingMod, Scream Filter',
    note_to_value=function(me, n) return math.log(limit_rng(261.6256 * 2^(n/12), 0, 22050)*99/22050+1)/math.log(100) end,
    value_to_note=function(me, v) return 12*math.log((100^v-1)*(22050/99/261.6256))/math.log(2) end,
    param_value_text=_value_mode_value_text_note,
    get_note_to_value=_value_mode_get_note_to_value_abs,
    show_controls=function(me) VB.views.octave_row.visible = true end
  },
  {
    name='Renoise Freq 11020',
    tooltip='Renoise Freq 11020: Select for freq control of native Comb Filter',
    note_to_value=function(me, n) return math.log((limit_rng(261.6256 * 2^(n/12), 20, 11020)-20)*99/11000+1)/math.log(100) end,
    value_to_note=function(me, v) return 12*math.log(((100^v-1)*11000/99+20)/261.6256)/math.log(2) end,
    param_value_text=_value_mode_value_text_note,
    get_note_to_value=_value_mode_get_note_to_value_abs,
    show_controls=function(me) VB.views.octave_row.visible = true end
  },
  {
    name='DtBlkFx Freq',
    tooltip='DtBlkFx Freq: Auto-selected for DtBlkFx FreqA/FreqB params, HarmRepitch',
    note_to_value=function(me, n) return math.max(n+48, 1e-6)/127.5 end,     -- min value 1e-6 stops blkfx from rounding 0 to 0 Hz 
    value_to_note=function(me, v) return v*127.5-48  end,
    param_value_text=_value_mode_value_text_note,
    get_note_to_value=_value_mode_get_note_to_value_abs,
    show_controls=function(me) VB.views.octave_row.visible = true end
  },
  {
    name='+/- 3 octaves relative',
    tooltip='+/- 3 octaves relative: Auto-selected for DtBlkFx Resample/Shift/HarmShift value',
    -- shift by +/- 3 octaves (c-4 is considered shift by 0)
    note_to_value=function(me, n) return n/72+0.5 end,
    value_to_note=function(me, v) return (v-0.5)*72 end,
    param_value_text=_value_mode_value_text,
    get_note_to_value=_value_mode_get_note_to_value_relative,
    show_controls=function(me) VB.views.octave_offs_row.visible = true end
  },
  {
    name='+/- 2 octaves relative',
    tooltip='+/- 2 octaves relative: this matched something I forget...',
    -- shift by +/- 2 octaves (c-4 is considered shift by 0)
    note_to_value=function(me, n) return n/48+0.5 end,
    value_to_note=function(me, v) return (v-0.5)*48 end,
    param_value_text=_value_mode_value_text,
    get_note_to_value=_value_mode_get_note_to_value_relative,
    show_controls=function(me) VB.views.octave_offs_row.visible = true end
  },
  {
    name='DtBlkFx Fx parameter',
    tooltip='DtBlkFx Fx: Auto-selected, Low-C=filter, C#=contrast, D=smear, D#=threshold, etc',
    note_to_value=function(me, n) end,
    value_to_note=function(me, v) end,
    param_value_text=_value_mode_value_text,
    get_note_to_value=function(me, note) return (note*8+4)/255 end,
    show_controls=function(me) end
  },
}
-- access function (using GUI)
function get_curr_value_mode() return VALUE_MODES[VB.views.range_mode.value] end

-------------------------------------------------------------------------------------------------
function determine_auto_value_mode(param)
  local name = param.name
  local value_string = param.value_string

  -- we can auto-determine param value mode for DtBlkFx since the string is distinctive
  --
  
  if string.find(name, '^%d\.Frq[AB]$') then
    -- assume blkfx frequency
    return 4
    
  elseif string.find(name, '^%d\.Val$') then
    -- assume blkfx value
    if string.find(value_string, '^[\-\+]%d?%d\.%d%d notes?') then
      -- assume blkfx shift/harmshift/resample
      return 5
    elseif string.find(value_string, '^[abcdefg][\-#]1?%d:[\+\-]%d%d') then
      -- assume blkfx repitch
      return 4
    else
      -- normal linear
      return 1
    end
    
  elseif string.find(name, '^%d\.Fx$') then
    return 7
  end
end


--=================================================================================================
-- renoise helpers

-------------------------------------------------------------------------------------------------
function get_sequence_pattern(seq_idx)
-- return the pattern for "seq_idx"
  return RS.patterns[RS.sequencer.pattern_sequence[seq_idx]]
end

-------------------------------------------------------------------------------------------------
function get_sequence_number_of_lines(seq_idx)
-- return the number of lines for sequence pattern "seq_idx"
  return get_sequence_pattern(seq_idx).number_of_lines
end

-------------------------------------------------------------------------------------------------
function get_sequence_pattern_track(seq_idx, track_idx)
-- return pattern track for given sequence index
  return get_sequence_pattern(seq_idx).tracks[track_idx]
end

-------------------------------------------------------------------------------------------------
function get_sequence_track_automation(seq_idx, track_idx, param)
-- return automation for sequence/track/param (or nil if it doesn't exist)
  return get_sequence_pattern_track(seq_idx, track_idx):find_automation(param)
end

---------------------------------------------------------------------------------------------------
function ptrack_automation_create(ptrack, param)
  if not param then
    flash_msg("Invalid parameter")
    return nil
  end
  local a = ptrack:find_automation(param)
  if not a then
    a = ptrack:create_automation(param)
    if not a then flash_msg("Something bad... couldn't create automation") end
  end  
  return a
end

---------------------------------------------------------------------------------------------------
function get_selected_parameter()
-- get selected device parameter
  local param = RS.selected_parameter
  if not param then
    flash_msg('Select a parameter in the automation editor')
    return nil
  end
  return param
end

---------------------------------------------------------------------------------------------------
function set_selected_parameter_from_value01(v)
  local param = RS.selected_parameter
  if not param then return end
  set_param_from_value01(param, v)
end

---------------------------------------------------------------------------------------------------
function set_selected_parameter_from_value01_delayed(v)
  local param = RS.selected_parameter
  if not param then return end
  
  -- set the value using a timer because the param value seems to get changed back to the integer line position
  add_timer_one_shot(
    function()
      set_param_from_value01(param, v)
    end,
    200
  )
end

---------------------------------------------------------------------------------------------------
function get_selected_automation()  
-- return automation for select param on selected track (may be nil if selected param has no automation)
  local param = get_selected_parameter()
  if not param then return nil end
  local ptrack = RS.selected_pattern_track
  return ptrack:find_automation(param)
end

---------------------------------------------------------------------------------------------------
function selected_automation_create()
-- return selected automation, creating if possible
  return ptrack_automation_create(RS.selected_pattern_track, RS.selected_parameter)
end

-------------------------------------------------------------------------------------------------
function get_selected_parameter_value_text()
  local param = RS.selected_parameter
  if not param then return "-" end
  return get_curr_value_mode():param_value_text(param)
end

--=================================================================================================
-- quantization helpers
--=================================================================================================

-------------------------------------------------------------------------------------------------
-- line position starting at 1
function line_pos_to_quan(line_pos) return (line_pos-1-(QUAN_OFFSET_VALUE or 0)) / STEP_VALUE1 end
function quan_to_line_pos(quan) return quan*STEP_VALUE1 + (QUAN_OFFSET_VALUE or 0) + 1 end

-------------------------------------------------------------------------------------------------
function quan_pos(line_pos, quan_steps)
-- return quantized "line_pos" (in lines) + "quan_steps" (in quantized units) as lines
-- if "quan_chg" is 0 then the result is rounded down to closest quantized position
-- this may return out-of-range lines
-- 
  -- t is in quan/step units
  local t = line_pos_to_quan(line_pos) + quan_steps
  
  -- snap position to nearest integer in quantize mode
  if QUAN_OFFSET_VALUE  ~= nil then
    if quan_steps < 0 then t = math.floor(t+0.9999)
    else t = math.ceil(t-0.9999)
    end
  end
  
  return quan_to_line_pos(t)
end

--=================================================================================================
-- line position (cursor) stuff
--=================================================================================================

-------------------------------------------------------------------------------------------------
function update_renoise_line_pos()
-- copy current LINE_POS to renoise song
  RS_SELECTED_LINE = math.floor(LINE_POS)
  RS.selected_line_index = RS_SELECTED_LINE
  
  -- sometimes line skips around if we don't do this...
  SKIP_RENOISE_LINE_POLL = true
end


-------------------------------------------------------------------------------------------------
function update_dialog_line_pos()
-- copy current LINE_POS to GUI view

  -- allow control to go 1 full quan either side so that we cover start & end of pattern
  VB.views.line_pos.min = math.floor(line_pos_to_quan(1))
  VB.views.line_pos.max = math.ceil(line_pos_to_quan(RS.selected_pattern.number_of_lines+1))

  -- force line position to redraw
  VB.views.line_pos.visible = false
  set_valuebox(VB.views.line_pos, line_pos_to_quan(LINE_POS))
  VB.views.line_pos.visible = true
end

-------------------------------------------------------------------------------------------------
function limit_rng_line_pos(line_pos)
-- limit range of "line_pos" to be valid for the current pattern
  return limit_rng(line_pos, 1, RS.selected_pattern.number_of_lines+255/256)
end


-------------------------------------------------------------------------------------------------
function normalize_seq_line(seq_idx, line_pos)

-- normalize line_pos by moving to the previous/next pattern if need be

  -- note that we don't mess with selected_sequence_index until we've finished with line_pos because  
  -- selected_pattern_index_fn will run "in-line" if the pattern changes and it messes with the line_pos view
  -- which in turn messes with line_pos and it is all bad...

  -- normalize by moving sequencer back
  while line_pos < 1 do
    if seq_idx <= 1 then
      -- can't move sequencer back any more, go to the first line
      line_pos = 1
      break
    end

    -- move sequencer back 1
    seq_idx = seq_idx-1
    line_pos = line_pos + get_sequence_number_of_lines(seq_idx)
  end
  
  -- normalize by moving sequencer forwards
  while true do
    local lines = get_sequence_number_of_lines(seq_idx)
    if line_pos <= lines+255/256 then break end
    
    -- go to the very end of the pattern if we can't move sequencer forward any more
    if seq_idx >= #RS.sequencer.pattern_sequence then
      line_pos = lines+255/256
      break
    end
    
    -- move sequencer forward
    line_pos = line_pos - lines
    seq_idx = seq_idx+1
  end
  return seq_idx, line_pos
end

-------------------------------------------------------------------------------------------------
function normalize_line_pos()
  RS.selected_sequence_index, LINE_POS = normalize_seq_line(RS.selected_sequence_index, LINE_POS)
end

-------------------------------------------------------------------------------------------------
function set_line_pos(line_pos)
-- set line position (don't call from renoise line notifier or view line notifier)
  LINE_POS = line_pos
  NON_QUAN_LINE_POS = line_pos
  normalize_line_pos()
  update_dialog_line_pos()
  update_renoise_line_pos()
end


-------------------------------------------------------------------------------------------------
function update_quan_offs()
-- update quantization offset from GUI (which implicitly enables quantization)

  -- read from GUI
  QUAN_OFFSET_VALUE = (VB.views.offs.value/12) % STEP_VALUE1  

  -- round line position to closest
  LINE_POS = limit_rng_line_pos(quan_to_line_pos(round(line_pos_to_quan(NON_QUAN_LINE_POS))))
  update_dialog_line_pos()
  update_renoise_line_pos()  
end

--=================================================================================================
-- point data manipulation

-------------------------------------------------------------------------------------------------
function find_closest_point(line_pos, p)
  -- get the next point after LINE_POS
  local i = binary_search(p, function(a) return a.time >= LINE_POS end)
  if i == 1 then
    -- return first point?
    return (#p >= 1 and 1) or nil
  elseif i <= #p then
    -- return point found or previous point?
    return p[i].time-LINE_POS > LINE_POS-p[i-1].time and i-1 or i
  else
    -- return previous point
    return i-1
  end
end

-------------------------------------------------------------------------------------------------
function delete_points(start_pos, end_pos)
-- delete points between start_pos (included) & end_pos (not included) and slide all points to the
-- right
--
  local a = get_selected_automation()    
  if not a then return end
  local p = a.points
  local len_p = #p
  
  -- find the start position
  local i = binary_search(p, function(a) return a.time >= start_pos end)
  
  -- set points to nil (much faster than a table.delete and renoise is happy with it)
  while i <= len_p and p[i].time < end_pos do
    p[i] = nil
    i = i+1
  end
  
  -- shift time of remaining points by the amount of time deleted
  local time_shift = end_pos-start_pos
  while i <= len_p do
    p[i].time = p[i].time-time_shift
    i = i+1
  end

  -- update
  a.points = p
end

--=================================================================================================
-- actions
--

-------------------------------------------------------------------------------------------------
function toggle_edit_mode()
  EDIT_MODE = not EDIT_MODE
  VB.views.edit_mode.color = EDIT_MODE and { 255, 0, 0 } or { 0, 0, 0 }
end



-------------------------------------------------------------------------------------------------
function set_line_pos_to_next_point(dir, stay_on_pattern, p)
--
  if not p then
    local a = get_selected_automation()
    if a then p = a.points end
  end
  
  -- are there points?
  if p then
    
    -- get the next point after LINE_POS
    local i = binary_search(p, function(a) return a.time > LINE_POS end)
    
    --
    if dir < 0 then
      -- move backwards, prv point is <= LINE_POS
      i = i-1
      -- is prv point == LINE_POS? if so go to the point prv that
      if i >= 1 and p[i].time == LINE_POS then i = i-1 end
      -- p[i] must be < LINE_POS
    end

    -- if we have a point then we move to it
    if i >= 1 and i <= #p then
      set_line_pos(p[i].time)
      
      local param = get_selected_parameter()

      -- set the value using a timer because the param value seems to get changed back to the integer line position otherwise
      add_timer_one_shot(
        function() set_param_from_value01(param, p[i].value) end,
        200
      )
      return
    end
  end
  
  --
  if stay_on_pattern then return end
  
  -- move to the previous or next patterns...
  if dir < 0 then
    set_line_pos(0)
  else
    set_line_pos(RS.selected_pattern.number_of_lines+1)
  end
end




-------------------------------------------------------------------------------------------------
function snap_closest_point_to_line_pos()
--
  local a = get_selected_automation()    
  if not a then return end
  local p = a.points
  local i = find_closest_point(LINE_POS, p)
  if not i then return end
  flash_msg("Moved point at " .. string.format("%.3f", p[i].time-1) .. " to " .. string.format("%.3f", LINE_POS-1))
  p[i].time = LINE_POS
  a.points = p
end

-------------------------------------------------------------------------------------------------
function copy_prv_point(line_pos)
  local param = get_selected_parameter()
  if not param then return end

  local trk_idx = RS.selected_track_index

  local seq_idx
  seq_idx, line_pos = normalize_seq_line(RS.selected_sequence_index, line_pos)
  
  local ptrack = get_sequence_pattern_track(seq_idx, trk_idx)
  local a = ptrack_automation_create(ptrack, param)
  if not a then return end

  local p = a.points
  
  -- points in this pattern
  if #p >= 1 then
  
    -- get point < line_pos
    local i = binary_search(p, function(a) return a.time >= line_pos end)-1

    if i > 0 then
      -- copy point to line_pos
      a:add_point_at(line_pos, p[i].value)
      set_selected_parameter_from_value01_delayed(p[i].value)
      return
    end
  end
    
  -- no previous point, see if we can get it from the previous pattern (but only go 1 pattern back)
  if seq_idx <= 1 or not p then flash_msg("Nothing found") return end
  
  local a_prv = get_sequence_track_automation(seq_idx-1, trk_idx, param)
  if not a_prv then flash_msg("Automation is empty in previous pattern") return end

  local p = a_prv.points
  if #p < 1 then flash_msg("Automation is empty in previous pattern") return end
  
  a:add_point_at(line_pos, p[#p].value)
  set_selected_parameter_from_value01_delayed(p[#p].value)
end

-------------------------------------------------------------------------------------------------
function copy_current()
  local param = get_selected_parameter()
  if not param then return end
  
  flash_msg('Copied ' .. get_selected_parameter_value_text() .. ' from ' .. param.name)
  COPY_VALUE = param_to_value01(param)
  COPY_NOTE = get_curr_value_mode():value_to_note(param.value)
end

-------------------------------------------------------------------------------------------------
function paste_current()
  local param = get_selected_parameter()
  if not param then return end

  local a = selected_automation_create()
  if not a then return end

  local v = COPY_NOTE and get_curr_value_mode():note_to_value(COPY_NOTE) or COPY_VALUE
  a:add_point_at(LINE_POS, v)
  
  set_selected_parameter_from_value01(v)
  flash_msg('Pasted ' .. string.format("%.3f", v) .. " (" .. get_selected_parameter_value_text() .. ")")
end

-------------------------------------------------------------------------------------------------
function cut_or_delete_closest_point_to_line_pos(delete_only)
--
  local a = get_selected_automation()    
  if not a then return end
  local p = a.points
  local i = find_closest_point(LINE_POS, p)
  if not i then return end

  flash_msg("Removed point at " .. string.format("%.3f", p[i].time-1))
  local param = get_selected_parameter()
  
  if not delete_only then
    COPY_VALUE = p[i].value
    COPY_NOTE = get_curr_value_mode():value_to_note(p[i].value)
  end
  
  --p[i] = nil
  --a.points = p

  -- faster...
  if a:has_point_at(p[i].time) then a:remove_point_at(p[i].time) end
end

--=================================================================================================
--=================================================================================================
-- KEY HANDLERS
--=================================================================================================
--=================================================================================================

-------------------------------------------------------------------------------------------------
key_handler_fns = {
  -- move back/forwards by quan/step
  _left=function() set_line_pos(quan_pos(LINE_POS, -1)) end,
  _right=function() set_line_pos(quan_pos(LINE_POS, 1)) end,
  _up=function() set_line_pos(quan_pos(LINE_POS, -1)) end,
  _down=function() set_line_pos(quan_pos(LINE_POS, 1)) end,

  -- move back/forwards pattern
  control_left=function() RS.selected_sequence_index = math.max(RS.selected_sequence_index-1, 1) end,
  control_right=function() RS.selected_sequence_index = math.min(RS.selected_sequence_index+1, #RS.sequencer.pattern_sequence) end,
  control_up=function() RS.selected_sequence_index = math.max(RS.selected_sequence_index-1, 1) end,
  control_down=function() RS.selected_sequence_index = math.min(RS.selected_sequence_index+1, #RS.sequencer.pattern_sequence) end,

  -- move back/forwards to next point
  alt_left=function() set_line_pos_to_next_point(-1) end,
  alt_right=function() set_line_pos_to_next_point(1) end,
  alt_up=function() set_line_pos_to_next_point(-1) end,
  alt_down=function() set_line_pos_to_next_point(1) end,
  
  -- move back/forwards micro-step
  shift_left=function() set_line_pos(round_1_256(LINE_POS)-1/256) end,
  shift_right=function() set_line_pos(round_1_256(LINE_POS)+1/256) end,
  shift_up=function() set_line_pos(round_1_256(LINE_POS)-1/256) end,
  shift_down=function() set_line_pos(round_1_256(LINE_POS)+1/256) end,
  
  -- remove current point and move to the previous point
  alt_back=function()
    cut_or_delete_closest_point_to_line_pos()
    set_line_pos_to_next_point(-1, true)
  end,
  
  -- remove current point and move to the next point
  alt_del=function()
    cut_or_delete_closest_point_to_line_pos()
    set_line_pos_to_next_point(1, true)
  end,

  -- copy previous point to just before LINE_POS
  shift_return=function() copy_prv_point(round_1_256(LINE_POS)-1/256) end,

  -- copy previous point to LINE_POS
  alt_return=function() copy_prv_point(round_1_256(LINE_POS)) end,
  
  -- toggle edit mode...
  _return=function() toggle_edit_mode() end,
  
  -- backspace, behaves like backspace in most other programs - shift everything to the right of the cursor 1 quan unit
  -- to the left & delete stuff
  _back=function()
    local new_line_pos
    if LINE_POS <= 1 then
      -- go to the end of the previous pattern
      new_line_pos = 255/256
    else
      new_line_pos = quan_pos(LINE_POS, -1)
      delete_points(new_line_pos, LINE_POS)
    end    
    set_line_pos(new_line_pos)
  end,

  -- insert key
  _ins=function()
    local a = get_selected_automation()
    if not a then return end

    local p = a.points
    if #p < 1 then return end

    local time_shift = quan_pos(LINE_POS, 1)-LINE_POS

    -- where to start shifting points from
    local i = binary_search(p, function(a) return a.time >= LINE_POS end)

    -- all points from this point onwards will be out of range
    local stop_pos = RS.selected_pattern.number_of_lines+1-time_shift

    -- shift points forwards
    while i <= #p and p[i].time < stop_pos do
      p[i].time = p[i].time+time_shift
      i = i+1
    end
    
    -- delete out of range
    while i <= #p do
      p[i] = nil
      i = i+1
    end

    -- update
    a.points = p      
  end,
  
  _del=function()
    delete_points(LINE_POS, quan_pos(LINE_POS, 1))
  end,
  
  control_c=copy_current,  
  control_v=paste_current,
  control_x=cut_or_delete_closest_point_to_line_pos,
  
  ['_numpad /']=function()
    if VB.views.octave_row.visible then chg_valuebox(VB.views.octave, function(v) return v-1 end) end
    if VB.views.octave_offs_row.visible then chg_valuebox(VB.views.octave_offs, function(v) return v-1 end) end
  end,
  
  ['_numpad *']=function()
    if VB.views.octave_row.visible then chg_valuebox(VB.views.octave, function(v) return v+1 end) end
    if VB.views.octave_offs_row.visible then chg_valuebox(VB.views.octave_offs, function(v) return v+1 end) end
  end,
  
  ["control_-"]=function() chg_valuebox(VB.views.quan, function(v) return v-1 end) end,
  ["control_="]=function() chg_valuebox(VB.views.quan, function(v) return v+1 end) end,
  ["alt_-"]=function() chg_valuebox(VB.views.quan, function(v) return v/2 end) end,
  ["alt_="]=function() chg_valuebox(VB.views.quan, function(v) return v*2 end) end, 
  
  -- forward/back tracks
  _tab=function() RS.selected_track_index = RS.selected_track_index % #RS.tracks + 1 end,
  shift_tab=function() RS.selected_track_index = (RS.selected_track_index-2) % #RS.tracks + 1 end,
  
  -- close
  _esc=function() DIALOG:close() end,
}


-------------------------------------------------------------------------------------------------
function key_handler_fn(DIALOG, key)
  --rprint(key)

  
  -- do we have a key handler?
  local fn = key_handler_fns[key.modifiers .. "_" ..key.name]

  -- call handler if there's one
  if fn then return fn() end

  -- pass key back to main app if we don't like it
  if not key.note then return key
  elseif EDIT_MODE then
    if key.modifiers ~= '' and key.modifiers ~= 'shift' and key.modifiers ~= 'alt' then return key end
  elseif key.modifiers ~= '' then return key
  end
    
  local v = get_curr_value_mode():get_note_to_value(key.note)
  v = limit_rng(v, 0, 1)

  -- update param live
  set_selected_parameter_from_value01(v)
  
  -- nothing more to do?
  if not EDIT_MODE then return end
  
  local line_pos = round_1_256(LINE_POS) -- round to renoise resolution
  local prv_line_pos
  local prv_selected_sequence_index
  
  -- shift puts the point at the end of the previous quan slot
  if key.modifiers=='shift' then
    -- this may cause us to go to the previous pattern
    prv_line_pos = LINE_POS
    prv_selected_sequence_index = RS.selected_sequence_index
    
    set_line_pos(line_pos - 1/256)
    line_pos = LINE_POS
  end

  local a = selected_automation_create()

  if a then 
    a:add_point_at(line_pos, v)
  end
  
  if prv_line_pos then
    -- go back to where we were
    set_line_pos(prv_line_pos)
    RS.selected_sequence_index = prv_selected_sequence_index
    return
  end
  
  -- move forwards to the next point
  if key.modifiers=='alt' then
    set_line_pos_to_next_point(1)
    return
  end
  
  -- don't move?
  if STEP_VALUE < 1/256 then return end

  -- move forward one slot
  set_line_pos(quan_pos(LINE_POS, 1))

end


--=================================================================================================
--=================================================================================================
-- renoise callback functions
--=================================================================================================
--=================================================================================================

-------------------------------------------------------------------------------------------------
function selected_pattern_index_fn()
-- called by renoise when the selected pattern changes
  VB.views.pat_info.width = 10
  VB.views.pat_info.text =
    string.format('%d:%d%s',
      RS.selected_sequence_index-1,
      RS.selected_pattern_index-1,
      RS.selected_pattern.name and (' ' .. RS.selected_pattern.name) or ''
    )
  update_dialog_line_pos()
end

-------------------------------------------------------------------------------------------------
function selected_track_index_fn()
-- called by renoise when the selected track changes

  VB.views.trk_info.width = 10
  VB.views.trk_info.text = RS.tracks[RS.selected_track_index].name
end

-------------------------------------------------------------------------------------------------
function selected_parameter_index_fn()
-- called by renoise when the selected device parameter changes

  local param = RS.selected_parameter
  VB.views.param_info.width = 10
  VB.views.param_info.text = param and param.name or '-'

  -- nothing selected?
  if not param then return end

  local mode = determine_auto_value_mode(param) or LAST_SELECTED_RNG_MODE
  AUTO_SELECTED_RNG_MODE = mode
  VB.views.range_mode.value = mode
end

-------------------------------------------------------------------------------------------------
function timer_fn()
-- called by renoise 10 times per second so we can poll for line and value changes (we
-- could register a callback for value but I am worried it might use too much CPU)

  local selected_line = RS.selected_line_index  
  if SKIP_RENOISE_LINE_POLL then
    SKIP_RENOISE_LINE_POLL = false
  elseif selected_line ~= RS_SELECTED_LINE then
    RS_SELECTED_LINE = selected_line
    NON_QUAN_LINE_POS = selected_line
    LINE_POS = quan_pos(selected_line, 0)
    update_dialog_line_pos()
  end

  VB.views.value_info.text = get_selected_parameter_value_text()      
end


-------------------------------------------------------------------------------------------------
function app_new_document_fn()
-- called when renoise.song() changes & our window is open
  RS = renoise.song()
  add_notifier(RS.selected_pattern_index_observable, selected_pattern_index_fn)
  add_notifier(RS.selected_track_index_observable, selected_track_index_fn)
  add_notifier(RS.selected_parameter_index_observable, selected_parameter_index_fn)
  selected_pattern_index_fn()
  selected_track_index_fn()
  selected_parameter_index_fn()  
end

-------------------------------------------------------------------------------------------------
function cleanup_timer_fn()
-- called by renoise periodically so we can check whether we should cleanup all the notifiers

  if DIALOG and DIALOG.visible then return end
  
  -- dialog closed... cleanup (is there a better way??)
  DIALOG = nil
  remove_notifier(renoise.tool().app_new_document_observable, app_new_document_fn)
  remove_notifier(RS.selected_pattern_index_observable, selected_pattern_index_fn)
  remove_notifier(RS.selected_track_index_observable, selected_track_index_fn)
  remove_notifier(RS.selected_parameter_index_observable, selected_parameter_index_fn)    
  remove_timer(timer_fn)
  remove_timer(cleanup_timer_fn)
end

--=================================================================================================
--=================================================================================================
-- GUI stuff
--=================================================================================================
--=================================================================================================


QUAN_AND_OFFSET_VIEW = VB:row {
  style='group', margin=1,
  VB:button {
    text="Step\n", id="step_quan_mode",
    tooltip="Toggle between 'Step' and 'Quantization & Offset' modes\n"..
    "Step mode: line position is free but arrow keys move by given step\n"..
    "Quantization & Offset mode: line position will snap to quantization points",
    pressed=function()
      if not QUAN_OFFSET_VALUE then
        update_quan_offs()
        VB.views.offs.active = true
        VB.views.step_quan_mode.text = "     Quan\n& Offset"
      else
        QUAN_OFFSET_VALUE = nil
        VB.views.offs.active = false
        VB.views.step_quan_mode.width = 10
        VB.views.step_quan_mode.text = "Step\n"
      end
    end
  },
  VB:vertical_aligner {
    mode='right',
    VB:valuebox {
      min = 0, max = 12000, value = 12, id = 'quan', width=80,
      tooltip="Quantization/step in lines, may be an expression (e.g. 4/3)\n"..
      "keys:\nCtrl-Minus/Ctrl-Equals change by 1/12 line\nAlt-Minus/Alt-Equals halve/double value",
      tonumber=function(s) return eval_tonumber_str(s)*12 end,
      tostring=function(v) return string.format("%.3f", v/12) end,
      notifier=function(v)
        STEP_VALUE = v/12
        STEP_VALUE1 = nonzero(STEP_VALUE) or 1
        if QUAN_OFFSET_VALUE then
          update_quan_offs()
        else
          update_dialog_line_pos()
        end
      end
    },
    mode='right', id='offs_row',
    VB:valuebox {
      id='offs', min=0, max=10000, value=0, -- offset units are 1/12 lines
      active=false, width=80,
      tooltip='Quantization offset in lines, may be an expression (e.g. 1/2)\nEnabled in Quantize & Offset mode',
      tonumber=function(s) return eval_tonumber_str(s)*12 end,
      tostring=function(v) return string.format("%.3f", v/12) end,
      notifier=function(v) update_quan_offs() end
    }
  }
}

LINE_POS_VIEW = VB:row {
  style = 'group', margin=1,
  VB:text { text='  Line\npos', align='right' },
  VB:column {
    VB:horizontal_aligner {
      mode='justify',
      VB:valuebox {
        id='line_pos', width="80%",
        tooltip='Line position, may be an expression (e.g. 16/3)\nkeys:\nleft/right to change by 1 step/quantize unit',
        tonumber=function(s)
          local v = eval_tonumber_str(s) -- "v" starts at 0 (renoise line number)
          if not v then return nil end
          SKIP_QUAN_LINE_POS = true
          return line_pos_to_quan(v+1) -- add 1 to get LUA line pos
        end,
        
        tostring=function(v) return string.format("%.3f", limit_rng_line_pos(quan_to_line_pos(v))-1) end,
        
        notifier=function(v)
          local line_pos = limit_rng_line_pos(quan_to_line_pos(v))

          -- is this a new event?
          if round_1_256(line_pos-LINE_POS) == 0 then return end

          -- do we need to quantize???
          if SKIP_QUAN_LINE_POS then
            SKIP_QUAN_LINE_POS = false
          elseif QUAN_OFFSET_VALUE and v%1 ~= 0 then
            -- call via a timer to do quantizing (otherwise renoise complains about a cycle)
            add_timer_one_shot(function() set_valuebox(VB.views.line_pos, round(VB.views.line_pos.value)) end, 10)
          end
          
          LINE_POS = line_pos
          NON_QUAN_LINE_POS = LINE_POS
          update_renoise_line_pos()
        end
      },
      vb_button_rpt { vb=VB, text="Q", tooltip="Snap position to closest quantization", width="20%",
        notifier=function() set_line_pos(quan_to_line_pos(round(line_pos_to_quan(LINE_POS)))) end },
    },
    VB:horizontal_aligner {
      mode='justify',
      vb_button_rpt { vb=VB, text="o<", tooltip="Move to point left\nkey: Alt-Left", notifier=function() set_line_pos_to_next_point(-1) end },
      vb_button_rpt { vb=VB, text="<", tooltip="Microstep left", notifier=function() set_line_pos(round_1_256(LINE_POS)-1/256) end },
      vb_button_rpt { vb=VB, text=">", tooltip="Microstep right", notifier=function() set_line_pos(round_1_256(LINE_POS)+1/256) end },
      vb_button_rpt { vb=VB, text=">o", tooltip="Move to point right\nkey: Alt-Right", notifier=function() set_line_pos_to_next_point(1) end },
    }
  },
}

EDIT_VIEW = VB:row {
  style='group', margin=1,
  VB:text { text="Point", align='right' },
  VB:vertical_aligner {
    width=70,
    VB:horizontal_aligner {
        VB:button { text="Copy", width="50%", tooltip="Copy current value\nkey: Ctrl-c", notifier=copy_current },
        vb_button_rpt { vb=VB, text="Cut", width="50%", tooltip="Cut point closest to current position\nkey: Ctrl-x", notifier=cut_or_delete_closest_point_to_line_pos },
    },
    VB:horizontal_aligner {
        VB:button { text="Paste", width="50%", tooltip="Paste to current position\nkey: Ctrl-v", notifier=paste_current },
        VB:button { text="Snap", width="50%", tooltip="Snap closest point to current position", notifier=snap_closest_point_to_line_pos },
    }
  },
  VB:vertical_aligner {
    VB:button { text="o->o", tooltip="Copy previous point to current position\nkey: Alt-enter", notifier=function() copy_prv_point(round_1_256(LINE_POS)) end },
    VB:button { text="o->|", tooltip="Copy previous point to 1 micro-step before current position\nkey: Shift-enter", notifier=function() copy_prv_point(round_1_256(LINE_POS)-1/256) end },
  }
}

SCALING_VIEW = VB:row {
  style='group', margin=1,
  VB:text { text="Value", align='right' },
  VB:column {
    VB:popup {
      width = "100%",
      id = 'range_mode',
      items = map(function(t) return t.name end, VALUE_MODES),

      tooltip = '~~~ Key to parameter value mapping ~~~\n\n'..
        table.concat(map(function(t) return t.tooltip.."\n" end, VALUE_MODES)),
      
      notifier = function(idx)
        -- check whether we generated this event
        if idx == AUTO_SELECTED_RNG_MODE then
          AUTO_SELECTED_RNG_MODE = nil
        else
          LAST_SELECTED_RNG_MODE = idx
        end

        apply(function(row) VB.views[row].visible = false end, {'linear_mode_row', 'octave_row', 'octave_offs_row'})        
        get_curr_value_mode():show_controls()        
      end
    },
    VB:horizontal_aligner {
      id='linear_mode_row', mode='justify',
      VB:row {
        VB:button {
          text = 'L', tooltip='Use current value for low',
          released = function()
            local param = get_selected_parameter()
            if param then VB.views.a.value = param_to_value01(param)*100 end
          end
        },
        VB:valuebox {
          id = 'a', value=0, tooltip='Low value for low-C on keyboard (Z key)',
          tonumber=function(s) return eval_tonumber_str(s) end,
          tostring=function(v) return tostring(v) end
        },
      },
      VB:row {
        VB:button {
          text = 'H', tooltip='Use current value for high',
          released = function()
            local param = get_selected_parameter()
            if param then VB.views.b.value = param_to_value01(param)*100 end
          end
        },
        VB:valuebox {
          id = 'b', value=100, tooltip='High value for high-C on keyboard (I key)',
          tonumber=function(s) return eval_tonumber_str(s) end,
          tostring=function(v) return tostring(v) end
        }
      }
    },
    VB:horizontal_aligner {
      id='octave_row', mode='right',
      visible=false,
      VB:row {
        VB:text { text = 'Octave', align='right' },
        VB:valuebox {
          min = 0, max = 10,
          value = 4, id = 'octave', tooltip='Change octave of notes entered\nkey:Numeric-slash/Numeric-asterisk',
          tonumber=function(s) return eval_tonumber_str(s) end,
          tostring=function(v) return tostring(v) end
        }
      }
    },
    VB:horizontal_aligner {
      id='octave_offs_row', mode='right',
      visible=false,
      VB:row {
        VB:text { text = 'Octave offset', align='right' },
        VB:valuebox {
          min = -3, max = 3,
          value = 0, id = 'octave_offs', tooltip='Change octave of notes entered\nkey:Numeric-slash/Numeric-asterisk',
          tonumber=function(s) return eval_tonumber_str(s) end,
          tostring=function(v) return tostring(v) end
        }
      }
    }
  }
}



INFO_VIEW = VB:horizontal_aligner {
  id='info_aligner',
  width = '100%',
  mode = 'justify',
  VB:text { id='pat_info', tooltip="Sequencer position:Pattern"},
  VB:text { text='|', tooltip="a bar" },
  VB:text {id='trk_info', tooltip="Track"},
  VB:text { text='|' },
  VB:text {id='param_info', tooltip="Parameter" },
  VB:text { text='|' },
  VB:text { id = 'value_info', tooltip="Current parameter value" }
}
  
VIEW = VB:column {
  INFO_VIEW,
  VB:row {
    spacing=8, margin=2,
    QUAN_AND_OFFSET_VIEW,
    LINE_POS_VIEW,
    EDIT_VIEW,
    SCALING_VIEW,
    VB:row {
      style='group', margin=1,
      VB:button {
        id = 'edit_mode', text = 'Keys\n',
        tooltip='When enabled (red), keyboard note-keys will enter points into the automation\n'..
        'key: return\n\n'..
        '~~~ General Help ~~~\n'..
        'left/right: move cursor by 1 step/quantum\n'..
        'Control-left/right: move cursor by 1 pattern\n'..
        'Alt-left/right: move cursor to next point\n'..
        'Shift-left/right: move cursor by microstep\n'..
        'backspace/delete: delete points behind/forward of the cursor by 1 step/quantized position and slide remaining points\n'..
        'insert: slide points forward of the cursor by 1 step/quantized position\n'..
        'Alt-backspace/delete: erase point closest to cursor and move cursor to the next left/right point\n'..
        'Alt/Shift-return: copy point left of the cursor to cursor/1 microstep before cursor\n'..
        'Control-x/c/v: Cut/Copy/Paste point under cursor\n'..
        'Numpad-slash/asterisk: change octave for frequence value modes\n'..
        'Control-equals/minus: change step/quantize amount by +/- 1/12 lines\n'..
        'Alt-equals/minus: double/Halve step/quantize amount\n'..
        'tab/Shift-tab: change track\n'..
        'esc: close dialog\n\n'..
        'darrell.barrell@gmail.com\n\n'..
        'get DtBlkFx VST plugin from http://rekkerd.org/blkfx',
        color={255, 0, 0}, pressed = function() toggle_edit_mode() end
      }
    }
  }
}
  
-------------------------------------------------------------------------------------------------
function open_dialog()
  if DIALOG and DIALOG.visible then
    DIALOG:show()
    return
  end
    
  app_new_document_fn()

  -------------------------------------------------------------------------------------------------
  -- poll for update stuff (playback pos & param value), could use renoise.tool().app_idle_observable:add_notifier()
  -- but I think 10 times/second update is better
  add_timer(timer_fn, 100)
  add_timer(cleanup_timer_fn, 2000)
  add_notifier(renoise.tool().app_new_document_observable, app_new_document_fn)
  
  -------------------------------------------------------------------------------------------------
  DIALOG = renoise.app():show_custom_dialog('AutomationMate automation keyboard edtior', VIEW, key_handler_fn)
end


---------------------------------------------------------------------------------------------------
function toggle_dialog()
  if DIALOG and DIALOG.visible then
    DIALOG:close()
    return
  end
  open_dialog()
end

---------------------------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = 'Track Automation:AutomationMate...',
  invoke = open_dialog
}
renoise.tool():add_menu_entry {
  name = 'Track Automation List:AutomationMate...',
  invoke = open_dialog
}

renoise.tool():add_keybinding {
  name="Automation:AutomationMate:Open",
  invoke=open_dialog
}
renoise.tool():add_keybinding {
  name="Automation:AutomationMate:Toggle Open",
  invoke=toggle_dialog
}

renoise.tool():add_keybinding {
  name="Global:AutomationMate (automation keyboard editor):Open",
  invoke=open_dialog
}
renoise.tool():add_keybinding {
  name="Global:AutomationMate (automation keyboard editor):Toggle Open",
  invoke=toggle_dialog
}


_AUTO_RELOAD_DEBUG = function()
  open_dialog()
end

