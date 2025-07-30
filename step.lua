local sub_column_names = {
  "note_value",
  "instrument_value",

  "volume_value",
  "panning_value",
  "delay_value",

  "effect_number_value",
  "effect_amount_value",

  "number_value",
  "amount_value",
}

---@type fun(s: renoise.Song, sub: renoise.Song.SubColumnType, v: any)
local function display_value(s, sub, v)
  local displayers = {
    function(x)
      return x / 128
    end,
    function(x)
      return x / #s.instruments
    end,
    function(x)
      local vol = 1
      if x < 128 then
        vol =  x / 128
      end
      local n = math.floor(vol * 128)
      local i = math.floor(n / 2)
      local r = math.floor(n / 2 - i + 0.5)
      local e = "-"
      if r > 0.5 then e = "|" end
      return "[" .. string.rep("|",i,"") .. e .. string.rep("-", 64 - i, "").."]"
    end,
    function(x)
      if x < 128 then
        return x / 128
      else
        return 0.5
      end
    end,
    function(x)
      return x / 256
    end,
    function(x)
      return "n effect number"
    end,
    function(x)
      return "effect amount"
    end,
    function(x)
      return "effect number"
    end,
    function(x)
      return "effect amount"
    end,
  }
  local m = displayers[sub](v)
  renoise.app():show_status(m) -- string.rep("⡇⣿",80,""))
end


local function has_short_fx(v)
  return v > 0x80 and v ~= 0xFF
end

local function step_byte(v, x)
  return clamp(v + x, 0, 255)
end

local function step_volume(v, x, blanks)
  if v == 0xFF then
    v = 0x80
  end

  if v <= 0x80 then
    local r = clamp(v + x, 0, 0x80)
    if r == 0x80 and blanks then
      return 0xFF
    else
      return r
    end
  else
    return v
  end
end

local function step_panning(v, x, blanks)
  if v == 0xFF then
    return clamp(0x40 + x, 0, 0x80)
  elseif v <= 0x80 then
    v = clamp(v + x, 0, 0x80)
    if v == 0x40 and blanks then
      return 0xFF
    else
      return v
    end
  end
  return v
end

local function step_note(v, x)
  if v == 0x79 then
    return 0x24
    -- return clamp(48 + x, 0, 119)
    -- return v
  elseif v < 120 then
    return clamp(v + x, 0, 119)
  end
  return v
end

local function step_instrument(v, x, current, max)
  -- if(v == 0xFF) then
  --   return current
  -- else
  local i = clamp(v + x, 0, max)
  -- if(v == 0 and x == -1) then
  --   i = 0xFF
  -- end

  return i
  -- end
end

local function step_sample(v, x, max)
  if v == renoise.PatternLine.EMPTY_INSTRUMENT then
    if max > 0 then return 0 else return v end
  else
    local i = v + x
    if i < 0 or max == 0 then
      return renoise.PatternLine.EMPTY_INSTRUMENT
    else
      return clamp(i, 0, max - 1)
    end
  end
end

local function step_short_fx(value_string, x)
  local v = tonumber(value_string:sub(2, 2), 16)
  if v ~= nil then
    return value_string:sub(1, 1) .. ("%X"):format(clamp(v + x, 0, 15))
  else
    return value_string
  end
end

local function step_device_fx(song, effect_number_string, offset, large_step)
  local device_id = from_char(tostring(effect_number_string):sub(1, 1))
  local param_id = from_char(tostring(effect_number_string):sub(2, 2))
  local s = song
  local devices = #s.selected_track.devices

  -- no dsp effect on track
  if devices == 1 then
    return effect_number_string
  end

  device_id = clamp(device_id, 1, devices - 1)

  local params = #s.selected_track.devices[device_id + 1].parameters

  param_id = clamp(param_id, 0, params)

  if large_step then -- step controlled dsp device
    device_id = clamp(device_id + sign(offset), 1, devices - 1)
    param_id = clamp(param_id, 0, #s.selected_track.devices[device_id + 1].parameters)
  else -- step controlled dsp device parameter
    param_id = param_id + offset
    if param_id < 0 then
      local di = clamp(device_id - 1, 1, devices)
      if di >= 1 and di ~= device_id then
        device_id = di
        param_id = #s.selected_track.devices[device_id + 1].parameters - 1
      else
        param_id = clamp(param_id, 0, params)
      end
    elseif param_id > params then
      local di = clamp(device_id + 1, 1, devices - 1)
      if di ~= device_id then
        device_id = di
        param_id = 0
      else
        param_id = clamp(param_id, 0, params)
      end
    end
  end
  return to_char(device_id) .. to_char(param_id)
end

---@alias ColumnOperation fun(is_phrase: boolean, song: renoise.Song, column: any, offset: integer, large_step: boolean, prefs: ValueStepperSettings)

---@type ColumnOperation
local function modify_note(is_phrase, song, column, offset, large_step, prefs)
  if large_step then
    offset = sign(offset) * 12
  end

  column.note_value = step_note(column.note_value, offset)

  -- TODO how should phrase note stepping behave here?
  if column.instrument_value == 0xFF and column.note_value < 120 and not is_phrase then
    column.instrument_value = song.selected_instrument_index - 1
  end
end

---@type ColumnOperation
local function modify_instrument(is_phrase, song, column, offset, large_step, prefs)
  if is_phrase then
    column.instrument_value = step_sample(column.instrument_value, offset, #song.selected_instrument.samples)
    if column.instrument_value < renoise.PatternLine.EMPTY_INSTRUMENT and prefs.select_instrument_on_step.value then
      song.selected_sample_index = column.instrument_value + 1
    end
  else
    column.instrument_value =
      step_instrument(column.instrument_value, offset, song.selected_instrument_index - 1, #song.instruments - 1)
    if prefs.select_instrument_on_step.value then
      song.selected_instrument_index = column.instrument_value + 1
    end
  end
end

---@type ColumnOperation
local function modify_volume(is_phrase, song, column, offset, large_step, prefs)
  if column ~= nil then
    if has_short_fx(column.volume_value) then
      column.volume_string = step_short_fx(column.volume_string, offset)
    else
      column.volume_value = step_volume(column.volume_value, offset, prefs.use_empty_on_vol_pan.value)
    end
  end
end

---@type ColumnOperation
local function modify_panning(is_phrase, song, column, offset, large_step, prefs)
  if has_short_fx(column.panning_value) then
    column.panning_string = step_short_fx(column.panning_string, offset)
  else
    column.panning_value = step_panning(column.panning_value, offset, prefs.use_empty_on_vol_pan.value)
  end
end

---@type ColumnOperation
local function modify_delay(is_phrase, song, column, offset, large_step, prefs)
  column.delay_value = step_byte(column.delay_value, offset)
end

---@type ColumnOperation
local function modify_effect_number(is_phrase, song, column, offset, large_step, prefs)
  local fx1 = tonumber(column.number_string:sub(1, 1), 36)

  if prefs.step_fx_commands.value and (fx1 == 0 or fx1 == 35) then
    local fx = tostring(column.number_string):sub(1, 2)
    local i = table:index_of(prefs.fx_array, fx)
    local next = clamp(i + offset, 1, #prefs.fx_array)
    column.number_string = prefs.fx_array[next]
  else
    local fx2 = tonumber(column.number_string:sub(2, 2), 36)
    if fx1 == 0 and fx2 ~= 0 then
      column.amount_value = step_byte(column.amount_value, offset)
    elseif fx1 >= 1 then
      column.number_string = step_device_fx(song, column.number_string, offset, large_step)
    end
  end
end

---@type ColumnOperation
local function modify_effect_amount(is_phrase, song, column, offset, large_step, prefs)
  if column.number_value > 0 then
    column.amount_value = step_byte(column.amount_value, offset)
  end
end

---@type ColumnOperation
local function modify_sample_effect_amount(is_phrase, song, column, offset, large_step, prefs)
  if column.effect_number_value > 0 then
    column.effect_amount_value = step_byte(column.effect_amount_value, offset)
  end
end

---@type ColumnOperation
local function modify_sample_effect_number(is_phrase, song, column, offset, large_step, prefs)
  if prefs.step_fx_commands.value then
    print("TODO step sample effect number")
  else
    modify_sample_effect_amount(is_phrase, song, column, offset, large_step, prefs)
  end
end

---@type ColumnOperation[]
local column_operations = {
  modify_note,
  modify_instrument,

  modify_volume,
  modify_panning,
  modify_delay,

  modify_sample_effect_number,
  modify_sample_effect_amount,

  modify_effect_number,
  modify_effect_amount,
}

---@type integer[]
local empty_line = {
  -- NOTE INSTRUMENT
  renoise.PatternLine.EMPTY_NOTE,
  renoise.PatternLine.EMPTY_INSTRUMENT,
  -- VOL PAN DELAY
  renoise.PatternLine.EMPTY_VOLUME,
  renoise.PatternLine.EMPTY_PANNING,
  renoise.PatternLine.EMPTY_DELAY,
  -- SAMPLE FX
  renoise.PatternLine.EMPTY_EFFECT_NUMBER,
  renoise.PatternLine.EMPTY_EFFECT_AMOUNT,
  -- FX
  renoise.PatternLine.EMPTY_EFFECT_NUMBER,
  renoise.PatternLine.EMPTY_EFFECT_AMOUNT,
}

---@type integer[]
local last_line = {
  -- NOTE INSTRUMENT
  0x24,
  0x00,
  -- VOL PAN DELAY
  0x80,
  0x40,
  0x01,
  -- SAMPLE FX
  0x00,
  0x00,
  -- FX
  0x00,
  0x00,
}

-- local function copy_line_to_buffer(line, buffer)
--   for i = 1, #buffer do
--     buffer[i] = line[sub_column_names[i]]
--   end
-- end

---@type fun(song: renoise.Song, s: PatternSelection) : boolean
local function inside_selection(song, s)
  local l = song.selected_line_index
  local t = song.selected_track_index
  local inside_track_and_line = l >= s.start_line and l <= s.end_line and t >= s.start_track and t <= s.end_track

  local nc = song.selected_note_column_index
  local ec = song.selected_effect_column_index
  local ns = song.selected_track.visible_note_columns
  -- local es = song.selected_track.visible_effect_columns
  local inside_columns = (nc > 0 and nc >= s.start_column and nc <= s.end_column)
    or (ec > 0 and ec + ns >= s.start_column and ec + ns <= s.end_column)

  return inside_track_and_line and inside_columns
end

---@type fun(song: renoise.Song, s: PhraseSelection) : boolean
local function inside_phrase_selection(song, s)
  local l = song.selected_phrase_line_index
  local inside_lines = l >= s.start_line and l <= s.end_line

  local nc = song.selected_phrase_note_column_index
  local ec = song.selected_phrase_effect_column_index
  local ns = song.selected_phrase.visible_note_columns
  -- local es = song.selected_track.visible_effect_columns
  local inside_columns = (nc > 0 and nc >= s.start_column and nc <= s.end_column)
    or (ec > 0 and ec + ns >= s.start_column and ec + ns <= s.end_column)

  return inside_lines and inside_columns
end

---@type fun(song: renoise.Song) : PatternSelection
local function cursor_to_selection(song)
  local note_column = song.selected_note_column_index
  local effect_column = song.selected_effect_column_index
  local column = note_column

  if note_column == 0 then
    column = song.selected_track.visible_note_columns + effect_column
  end

  return {
    start_track = song.selected_track_index,
    end_track = song.selected_track_index,
    start_column = column,
    end_column = column,
    start_line = song.selected_line_index,
    end_line = song.selected_line_index,
  }
end

---@type fun(song: renoise.Song) : PhraseSelection
local function cursor_to_phrase_selection(song)
  local note_column = song.selected_phrase_note_column_index
  local effect_column = song.selected_phrase_effect_column_index
  local column = note_column

  if note_column == 0 then
    column = song.selected_phrase.visible_note_columns + effect_column
  end

  return {
    start_column = column,
    end_column = column,
    start_line = song.selected_phrase_line_index,
    end_line = song.selected_phrase_line_index,
  }
end

local function empty_by_value(column, sub)
  -- sample effect value is only counted as empty if no commands are present
  if sub == 7 then
    return column.effect_number_value == 0x00
  else
    return column[sub_column_names[sub]] == empty_line[sub]
  end
end

local function empty_by_note(column, sub)
  return column.note_value >= 120 -- or empty_by_value(column, sub)
end

local function empty_never(column, sub)
  return false
end

local empty_functions = {
  empty_by_value,
  empty_by_note,
  empty_never,
}

local function empty_note_target(column, sub, mode)
  return empty_functions[mode](column, sub)
end

---@type fun(s: PatternSelection) : boolean
local function singular_selection(s)
  return s.start_track == s.end_track and s.start_line == s.end_line and s.start_column == s.end_column
end

---@type fun(s: PhraseSelection) : boolean
local function singular_phrase_selection(s)
  return s.start_line == s.end_line and s.start_column == s.end_column
end

-- returns a table of every effect column to be modified inside a selection
---@type fun(song: renoise.Song, selection: PatternSelection, sub: integer, prefs: ValueStepperSettings): renoise.EffectColumn[]
local function get_effect_columns(song, selection, sub, prefs)
  local columns = {}

  local pattern = song:pattern(song.selected_pattern_index)

  local target = pattern
    :track(song.selected_track_index)
    :line(song.selected_line_index)
    :effect_column(song.selected_effect_column_index)
  local single = singular_selection(selection)
  local t = maybe_or(selection.start_track, 1)
  while t <= selection.end_track do
    local track = song:track(t)
    local c = 1
    local e = nil

    if t == selection.end_track then
      e = selection.end_column - track.visible_note_columns
    else
      e = track.visible_effect_columns
    end

    if t == selection.start_track then
      if selection.start_column > track.visible_note_columns then
        c = selection.start_column - track.visible_note_columns
      else
        c = 1
      end
    end

    local pattern_track = pattern:track(t)

    while c <= e do
      for i = selection.start_line, selection.end_line do
        local column = pattern_track:line(i):effect_column(c)
        local empty = column.is_empty
        if single or (not empty and target.number_string == column.number_string) then
          table.insert(columns, #columns + 1, column)
        end
      end
      c = c + 1
    end
    t = t + 1
  end
  return columns
end

-- returns a table of every effect column to be modified inside a selection
---@type fun(song: renoise.Song, selection: PhraseSelection, sub: integer, prefs: ValueStepperSettings): renoise.EffectColumn[]
local function get_phrase_effect_columns(song, selection, sub, prefs)
  local columns = {}

  local phrase = song.selected_phrase

  if phrase == nil then return {} end

  local effect_column = song.selected_phrase_effect_column

  if effect_column == nil then return {} end

  local single = singular_phrase_selection(selection)
  local c = 1
  if selection.start_column > phrase.visible_note_columns then
    c = selection.start_column - phrase.visible_note_columns
  end

  local e = selection.end_column - phrase.visible_note_columns

  while c <= e do
    for i = selection.start_line, selection.end_line do
      local column = phrase:line(i):effect_column(c)
      local empty = column.is_empty
      if single or (not empty and effect_column.number_string == column.number_string) then
        table.insert(columns, #columns + 1, column)
      end
    end
    c = c + 1
  end
  return columns
end

-- returns a table of every note column to be modified inside the selection
---@type fun(song: renoise.Song, selection: PhraseSelection, sub: integer, prefs: ValueStepperSettings): renoise.NoteColumn[]
local function get_phrase_note_columns(song, selection, sub, prefs)
  local columns = {}
  local single = singular_phrase_selection(selection)

  local phrase = song.selected_phrase

  if phrase == nil then return {} end

  local target =
    phrase:line(song.selected_phrase_line_index):note_column(song.selected_phrase_note_column_index)

  local c = maybe_or(selection.start_column, 1)
  local e = math.min(phrase.visible_note_columns, selection.end_column)

  while c <= e do
    for i = selection.start_line, selection.end_line do
      local column = phrase:line(i):note_column(c)
      local empty = empty_note_target(column, sub, prefs.block_step_mode.value)
      if
        not empty
        and sub >= renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_NUMBER
        and target.effect_number_value ~= column.effect_number_value
      then
        empty = true
      end
      if single or not empty then
        table.insert(columns, #columns + 1, column)
      end
    end
    c = c + 1
  end

  -- always step sub-column under cursor even if it's empty
  if not single and empty_note_target(target, sub, prefs.block_step_mode.value) then
    table.insert(columns, #columns + 1, target)
  end

  return columns
end

-- returns a table of every note column to be modified inside the selection
---@type fun(song: renoise.Song, selection: PatternSelection, sub: integer, prefs: ValueStepperSettings): renoise.NoteColumn[]
local function get_note_columns(song, selection, sub, prefs)
  local columns = {}
  local single = singular_selection(selection)

  local pattern = song:pattern(song.selected_pattern_index)

  local t = maybe_or(selection.start_track, 1)

  local target =
    pattern:track(song.selected_track_index):line(song.selected_line_index):note_column(song.selected_note_column_index)

  while t <= selection.end_track do
    local track = song:track(t)
    local c = 1
    local e = nil

    if t == selection.end_track then
      e = math.min(selection.end_column, track.visible_note_columns)
    else
      e = track.visible_note_columns
    end

    if t == selection.start_track then
      if selection.start_column > track.visible_note_columns then
        t = t + 1
        track = song:track(t)
      end
      c = maybe_or(selection.start_column, 1)
    end

    local pattern_track = pattern:track(t)

    while c <= e do
      for i = selection.start_line, selection.end_line do
        local column = pattern_track:line(i):note_column(c)
        local empty = empty_note_target(column, sub, prefs.block_step_mode.value)
        if
          not empty
          and sub >= renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_NUMBER
          and target.effect_number_value ~= column.effect_number_value
        then
          empty = true
        end
        if single or not empty then
          table.insert(columns, #columns + 1, column)
        end
      end
      c = c + 1
    end
    t = t + 1
  end

  -- always step sub-column under cursor even if it's empty
  if not single and empty_note_target(target, sub, prefs.block_step_mode.value) then
    table.insert(columns, #columns + 1, target)
  end

  return columns
end

local function default_empty_sub(column, sub)
  if column ~= nil then
    return empty_line[sub] == column[sub_column_names[sub]]
  else
    return false
  end
end

local function empty_effect_number(column, sub)
  return empty_line[sub] == column[sub_column_names[sub]] and empty_line[sub + 1] == column[sub_column_names[sub + 1]]
end

local function empty_effect_value(column, sub)
  return empty_line[sub - 1] == column[sub_column_names[sub - 1]] and empty_line[sub] == column[sub_column_names[sub]]
end

local empty_checks = {
  default_empty_sub,
  default_empty_sub,

  default_empty_sub,
  default_empty_sub,
  default_empty_sub,

  empty_effect_number,
  empty_effect_value,

  empty_effect_number,
  empty_effect_value,
}

local function empty_column(column, sub)
  return empty_checks[sub](column, sub)
end

-- local function array_string(a)
--   local s = ""
--   for _, i in pairs(a) do
--     s = s .. i .. " "
--   end
--   return s
-- end

local function save_to_last_line_raw(column, sub)
  if not empty_column(column, sub) and (sub ~= 1 or column.note_value ~= 0x78) then
    last_line[sub] = column[sub_column_names[sub]]
  end
end

local function save_to_last_line_tupled(column, sub)
  if not empty_column(column, sub) and (sub ~= 1 or column.note_value ~= 0x78) then
    if sub >= 6 then
      local _sub = 6
      if sub >= 8 then
        _sub = 8
      end
      last_line[_sub] = column[sub_column_names[_sub]]
      last_line[_sub + 1] = column[sub_column_names[_sub + 1]]
    elseif sub == 1 then
      last_line[sub] = column[sub_column_names[sub]]
      local instrument = column[sub_column_names[sub + 1]]
      if instrument ~= 0xFF then
        last_line[sub + 1] = column[sub_column_names[sub + 1]]
      else
        -- print("setting based on selected instrument")
        -- last_line[sub + 1] = renoise.song().selected_instrument_index - 1
      end
    else
      last_line[sub] = column[sub_column_names[sub]]
    end
    -- renoise.app():show_status(array_string(last_line))

    return true
  else
    return false
  end
end

local function save_last_column_from_cursor(song, sub)
  local t = song.selected_pattern.tracks[song.selected_track_index]
  local note_column = song.selected_note_column_index
  local effect_column = song.selected_effect_column_index

  if note_column > 0 then
    for i = song.selected_line_index, 1, -1 do
      local column = t:line(i):note_column(note_column)
      if save_to_last_line_tupled(column, sub) then
        return true
      end
    end
  else
    for i = song.selected_line_index, 1, -1 do
      local column = t:line(i):effect_column(effect_column)
      if save_to_last_line_tupled(column, sub) then
        return true
      end
    end
  end
  return false
end

---@type fun(is_phrase: boolean, song: renoise.Song, selection: PatternSelection | PhraseSelection, is_note_column: boolean, sub: integer, offset: integer, large_step: boolean, prefs: ValueStepperSettings)
local function step(is_phrase, song, selection, is_note_column, sub, offset, large_step, prefs)
  local columns = {}

  local single = false

  if is_phrase then
    ---@cast selection PhraseSelection
    single = singular_phrase_selection(selection)
    if is_note_column then
      ---@cast selection PhraseSelection
      columns = get_phrase_note_columns(song, selection, sub, prefs)
    else
      ---@cast selection PhraseSelection
      columns = get_phrase_effect_columns(song, selection, sub, prefs)
    end
  else
    ---@cast selection PatternSelection
    single = singular_selection(selection)
    if is_note_column then
      ---@cast selection PatternSelection
      columns = get_note_columns(song, selection, sub, prefs)
    else
      ---@cast selection PatternSelection
      columns = get_effect_columns(song, selection, sub, prefs)
    end
  end

  if single then
    -- TODO test relative in phrase
    -- start from last used value when relative
    if prefs.relative.value and empty_column(columns[1], sub) then
      -- print("start from last used value when relative")
      local found_last_value = false
      if save_last_column_from_cursor(song, sub) then
        found_last_value = true
        if sub >= 6 then
          local _sub = 6
          if sub >= 8 then
            _sub = 8
          end

          -- if(last_line[_sub] ~= empty_line[_sub] and last_line[_sub + 1] ~= empty_line[_sub + 1]) then
          columns[1][sub_column_names[_sub]] = last_line[_sub]
          columns[1][sub_column_names[_sub + 1]] = last_line[_sub + 1]
          -- end

          -- column_operations[sub](song, columns[1], 0, false, prefs)
        elseif sub == 1 then
          columns[1][sub_column_names[sub]] = last_line[sub]
          columns[1][sub_column_names[sub + 1]] = last_line[sub + 1]
        else
          columns[1][sub_column_names[sub]] = last_line[sub]
          -- column_operations[sub](song, columns[1], 0, false, prefs)
        end
      end

      -- actual stepping if not starting with last
      if not found_last_value or not prefs.start_relative_with_last.value then
        column_operations[sub](is_phrase, song, columns[1], offset, large_step, prefs)
      end
    else
      -- regular single stepping
      column_operations[sub](is_phrase, song, columns[1], offset, large_step, prefs)
    end
    if not is_phrase then
      if prefs.trigger_line_on_step.value then
        if not song.transport.playing then
          song:trigger_pattern_line(song.selected_line_index)
        end
      end
    end

    -- save_to_last_line_tupled(columns[1], sub)
  else
    for _, c in pairs(columns) do
      column_operations[sub](is_phrase, song, c, offset, large_step, prefs)
    end
  end

  -- display_value(song, sub, columns[1][sub_column_names[sub]])
end


---@type fun(offset: integer, large_step: boolean, prefs: ValueStepperSettings)
function Step_values_in_selection(offset, large_step, prefs)
  local song = renoise.song()

  if song == nil or (not song.transport.edit_mode and not prefs.ignore_edit_mode.value) then
    return
  end

  local sub = song.selected_sub_column_type

  local is_note_column = sub <= renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_AMOUNT

  local selection = song.selection_in_pattern

  if selection == nil or not inside_selection(song, selection) then
    selection = cursor_to_selection(song)
  end

  step(false, song, selection, is_note_column, sub, offset, large_step, prefs)
end

---@type fun(offset: integer, large_step: boolean, prefs: ValueStepperSettings)
function Step_values_in_phrase_selection(offset, large_step, prefs)
  local song = renoise.song()

  if song == nil or (not song.transport.edit_mode and not prefs.ignore_edit_mode.value) then
    return
  end

  local sub = song.selected_phrase_sub_column_type

  local is_note_column = sub <= renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_AMOUNT

  local selection = song.selection_in_phrase

  if selection == nil or not inside_phrase_selection(song, selection) then
    selection = cursor_to_phrase_selection(song)
  end

  step(true, song, selection, is_note_column, sub, offset, large_step, prefs)
end

-- local function listen_to_edit(pos)
--   -- rprint(pos)
--   local song = renoise.song()
--   if song == nil then return end
--   local selection = song.selection_in_pattern

--   -- TODO ignore block operation
--   -- if(selection ~= nil and not singular_selection(selection)) then
--   --   return
--   -- end

--   local line = song.patterns[pos.pattern].tracks[pos.track].lines[pos.line]
--   local column = nil
--   local note_column_index = song.selected_note_column_index

--   if note_column_index > 0 then
--     column = line:note_column(note_column_index)
--   else
--     column = line:effect_column(song.selected_effect_column_index)
--   end
--   -- TODO ignore step but save on type edit
--   save_to_last_line_raw(column, song.selected_sub_column_type)
-- end
-- local last_pattern = nil

-- local function change_edit_listener()
--   if last_pattern ~= nil and last_pattern:has_line_notifier(listen_to_edit) then
--     last_pattern:remove_line_notifier(listen_to_edit)
--   end
--   -- renoise.song().selected_pattern_observable:remove_line_notifier()
--   renoise.song().selected_pattern:add_line_notifier(listen_to_edit)

--   last_pattern = renoise.song().selected_pattern
-- end

-- function Init_edit_listener()
--   if renoise.song() ~= nil then
--     renoise.song().selected_pattern_observable:add_notifier(change_edit_listener)
--     change_edit_listener()
--   end
-- end
