require("config")

function note_transform(alias, transform)
  return { alias = alias, transform = transform }
end
function clamp_note(dir)
  return function(nc, value)
    nc.note_value = clamp(nc.note_value + value * dir, 0, 119)
  end
end
function clamp_instrument(dir)
  return function(nc, value)
    nc.instrument_value = clamp(nc.instrument_value + dir * value, 0, 254)
  end
end

NoteTransformList = {
  note_transform(
    EffectType.up_note,
    clamp_note(1)
  ),
  note_transform(
    EffectType.down_note,
    clamp_note(-1)
  ),
  note_transform(
    EffectType.up_octave,
    clamp_note(12)
  ),

  note_transform(
    EffectType.down_octave,
    clamp_note(-12)
  ),

  note_transform(
    EffectType.up_instrument,
    clamp_instrument(1)
  ),

  note_transform(
    EffectType.down_instrument,
    clamp_instrument(-1)
  ),
}
NoteTransforms = command_lookup(NoteTransformList)

PatternTargetType = {
  pattern = 0,
  sequence = 1,
}

function pattern_target(i)
  return { type = PatternTargetType.pattern, index = i}
end
function sequence_target(i)
  return { type = PatternTargetType.sequence, index = i}
end

function pattern_transform(alias, get_pattern)
  return { alias = alias, get_pattern = get_pattern}
end

PatternTransformList = {
  pattern_transform(
    PatternType.absolute,
    function(s, d)
      return pattern_target(d.value + 1)
    end
  ),
  pattern_transform(
    PatternType.sequence,
    function(s, d)
      return sequence_target(d.value + 1)
    end
  ),
  pattern_transform(
    PatternType.down,
    function(s, d)
      return sequence_target(s.sequence + d.value)
    end
  ),
  pattern_transform(
    PatternType.up,
    function(s, d)
      return sequence_target(s.sequence - d.value)
    end
  ),
  pattern_transform(
    PatternType.random,
    function(s, d, line_seed)
      math.randomseed(s.seed + s.sequence + line_seed + d.value)
      return sequence_target(random_from(s.sequences, s.sequence))
    end
  ),
  pattern_transform(
    PatternType.random_patterns,
    function(s, d, line_seed)
      math.randomseed(s.seed + s.sequence + line_seed + d.value)
      return sequence_target(random_from(s.sequences, s.sequence))
    end
  ),
  pattern_transform(
    PatternType.off,
    function(s, d, line_seed)
      return 0
    end
  ),
}
PatternTransforms = command_lookup(PatternTransformList)


function line_transform(alias, get_line)
  return { alias = alias, get_line = get_line}
end
LineTransformList = {
  line_transform(
    LineType.empty,
    function(s, ld)
      if ld.mode == LineMode.down then
        return s.line + ld.value
      elseif ld.mode == LineMode.up then
        return s.line - ld.value
      elseif ld.mode == LineMode.random then
        math.randomseed(s.seed + s.sequence + ld.value)
        return random_from(512, 0)
      else
        return s.line + ld.value
      end
    end
  ),
  line_transform(
    LineType.absolute,
    function(s, ld)
      return ld.value + 1
    end
  ),
  line_transform(
    LineType.beat,
    function(s, ld)
      if ld.mode == LineMode.down then
        return s.line + ld.value * s.lpb
      elseif ld.mode == LineMode.up then
        return s.line - ld.value * s.lpb
      elseif ld.mode == LineMode.random then
        local bp = ((s.line - 1) % s.lpb) 
        math.randomseed(s.seed + s.sequence + ld.value)
        local rb = random_from(math.floor(s.lines / s.lpb), 0)
        return line_wrap(rb * s.lpb + bp + 1, s.lines)
      else
        return s.lpb * ld.value
      end
    end
  ),
  line_transform(
    LineType.random,
    function(s, ld)
      math.randomseed(s.seed + s.sequence + ld.value + s.line)
      return random_from(512, 0)
    end
  ),
}
LineTransforms = command_lookup(LineTransformList)

function parse_number(string, hex, default)
  local base = 10
  if hex then 
    base = 16
  end
  return with_default(tonumber(string, base), with_default(tonumber(string, 16), default))
end
function parse_pattern_value(string, default)
  return parse_number(string, prefs.hex_pattern.value == 2, default)
end
function parse_line_value(string, default)
  return parse_number(string, prefs.hex_line.value == 2, default)
end

function pattern_tokens(e)
  return {
    flag = e.number_string:sub(1,1),
    type = e.number_string:sub(2,2),
    value = e.amount_string,
  }
end

function line_tokens(e)
  return {
    type = e.number_string:sub(1,1),
    mode = e.number_string:sub(2,2),
    value = e.amount_string,
  }
end

function parse_pattern_tokens(tokens)
  if PatternTypes[tokens.type] then 
    return {
      type = tokens.type,
      flag = with_default(tokens.flag, PatternFlag.empty),
      value = parse_pattern_value(tokens.value, 0),
    }
  else 
    return nil 
  end
end

function parse_line_tokens(tokens)
  if LineModes[tokens.mode] then
    return {
      mode = tokens.mode,
      type = with_default(tokens.type, LineType.empty),
      value = parse_line_value(tokens.value, 0)
    }
  else
    local v = parse_line_value(tokens.mode, nil)  
    if v ~= nil and v <= 5 then
    -- there is no type present but there is a valid value in the last 3 digits
      v = parse_line_value(tokens.mode..tokens.value, 0)
    else
      v = parse_line_value(tokens.value, 0)
    end

    if LineTypes[tokens.type] and tokens.type ~= LineType.empty then
      return {
        type = with_default(tokens.type, LineType.empty),
        mode = LineMode.down,
        value = v,
      }
    else
      return nil
    end
  end
end   

function effect_tokens(e)
  return { type = e:sub(1,1), value = e:sub(2,2) }
end

function note_tokens(n, vol_visible, pan_visible, fx_visible)
  if n.is_empty then return nil end

  local vol_effect = nil
  local pan_effect = nil

  if vol_visible and n.volume_value ~= 0xFF then
    vol_effect = effect_tokens(n.volume_string)
  end

  if pan_visible and n.panning_value ~= 0xFF then
    pan_effect = effect_tokens(n.panning_string)
  end

  return {
    note = n.note_value,
    instrument = n.instrument_value,
    vol_effect = vol_effect,
    pan_effect = pan_effect,
  }
end

function parse_effect(e)
  if e == nil then return nil end
  if EffectTypes[e.type] then
    e.value = parse_number(e.value, true, 0)
    return e
  else
    return nil
  end
end  

function parse_note_tokens(tokens)
  if tokens == nil then return nil end
  local effects = {}

  tokens.vol_effect = parse_effect(tokens.vol_effect)
  tokens.pan_effect = parse_effect(tokens.pan_effect)

  return tokens
end

function print_status(parsed)
  return ""
end


function get_state(s, l)
  return {
    sequence = s.selected_sequence_index,
    sequences = #s.sequencer.pattern_sequence,
    pattern = s.selected_pattern_index,
    patterns = #s.patterns,
    lpb = s.transport.lpb,

    seed = prefs.seed.value,

    line = l,
    lines = nil,
  }
end

function to_pattern_index(s, pt)
  if pt.type == PatternTargetType.pattern then 
    return wrapi(pt.index, #s.patterns)
  else
    return s.sequencer.pattern_sequence[wrapi(pt.index, #s.sequencer.pattern_sequence)]
  end
end

function to_line_index(s, p, i)
  return wrapi(i, s:pattern(p).number_of_lines)
end

function apply_effect(nc, e)
  if e ~= nil then
    local ef = NoteTransforms[e.type]
    if ef then ef.transform(nc, e.value) end
  end
end
function apply_note_transform(target_line, track, nt)
  for n = 1, track.visible_note_columns do
    local nc = target_line:note_column(n)
    if nt.note == renoise.PatternLine.NOTE_OFF then
      nc.note_value = nt.note
      nc.instrument_value = 0xFF
    else  
      if nc.note_value < renoise.PatternLine.NOTE_OFF then
        apply_effect(nc, nt.vol_effect)
        apply_effect(nc, nt.pan_effect)
      end
    end
  end
end


-- todo faster search
function find_automation_point(a, time)
  for i = 1, #a.points do
    local p = a.points[i]
    if p.time == time then return p end
  end
end

function copy_automation(a, source_track, source_line, target_track, target_line)
  local sa = source_track.automation[a]
  local dp = sa.dest_parameter
  local ta = target_track:find_automation(dp)
  if ta == nil then
    ta = target_track:create_automation(dp)
  end
  if sa:has_point_at(source_line) then
    local p = find_automation_point(sa, source_line)
    ta:add_point_at(target_line, p.value, p.scaling)
  end
end

function render_line(s, pattern, tracks, line, chunk, note_trans)
  local source_pattern = s:pattern(chunk.pattern)
  local target_pattern = s:pattern(pattern)
  local source_line_index = wrapi(chunk.start + chunk.line, source_pattern.number_of_lines)

  for i = 1, #tracks do
    local t = tracks[i]
    -- if t ~= prefs.track.value then 
    local target_track = target_pattern:track(t)
    local target = target_track:line(line)
    local source_track = source_pattern:track(t)
    local source = source_track:line(source_line_index)

    -- copy line contents
    if source.is_empty then
      target:clear()
    else
      target:copy_from(source)
    end
    
    -- apply transformations from note columns
    if note_trans and (not target.is_empty or note_trans.note == renoise.PatternLine.NOTE_OFF) then
      apply_note_transform(target, s:track(t), note_trans)
    end

    if prefs.automation.value then
      -- clear previous automation
      for a in ipairs(target_track.automation) do
        local auto = target_track.automation[a]
        if auto:has_point_at(line) then
          auto:remove_point_at(line)
        end
        if #auto.points == 0 then
          target_track:delete_automation(auto.dest_parameter)
        end
      end
      -- copy new automation
      for a in ipairs(source_track.automation) do
        copy_automation(a, source_track, source_line_index, target_track, line)
      end
    end
  end
end

function effect_is(e, t)
  return e ~= nil and e.type == t
end
function same_effect(a, b)
  return a ~= nil and b ~= nil and a.type == b.type
end

function has_effect(tokens, effect)
  if tokens == nil then return false
  else
    if effect_is(tokens.vol_effect, effect) then return true end
    if effect_is(tokens.pan_effect, effect) then return true end
    return false
  end
end
function repeat_effect_value(prev, next)
  if same_effect(prev, next) then
    if next.value == 0 then 
      next.value = prev.value
    end
  end
end

function merge_note_trans(prev, next)
  if prev == nil or next == nil then return next end

  repeat_effect_value(prev.vol_effect, next.vol_effect)
  repeat_effect_value(prev.pan_effect, next.pan_effect)

  return next
end

function render_chunks(s, pattern, track, tracks)
  local state = get_state(s, 0)
  local chunk = nil
  local chunk_pattern_track = s:pattern(pattern):track(track)
  local chunk_track = s:track(track)
  local note_trans = nil
  local skip = false

  local step_chunk = function()
    if chunk then chunk.line = chunk.line + 1 end
  end

  for i, l in s.pattern_iterator:lines_in_pattern_track(pattern, track) do
    -- local l = chunk_pattern_track:line(i.line)
    state.line = i.line

    local pattern_tokens = parse_pattern_tokens(pattern_tokens(l:effect_column(1)))
    local line_tokens = parse_line_tokens(line_tokens(l:effect_column(2)))

    local nt = parse_note_tokens(note_tokens(l:note_column(1), chunk_track.volume_column_visible, chunk_track.panning_column_visible, chunk_track.sample_effects_column_visible))
    note_trans = merge_note_trans(note_trans, nt)

  -- toggle skipping
    if has_effect(note_trans, EffectType.no) then
      skip = true
    elseif has_effect(note_trans, EffectType.yes) then
      skip = false
    end

  -- keep (K0) and skip (N0) will simply step the chunk (if any) and return
    if skip or has_effect(note_trans, EffectType.keep) then
      step_chunk()
  -- clear (C0) steps the chunk and clears the line
    elseif has_effect(note_trans, EffectType.clear) then
      step_chunk()
      clear_line(s, track, pattern, i.line)
    else
      if pattern_tokens then
        -- apply Off command
        if pattern_tokens.type == PatternType.off then
          l:effect_column(1).number_string = "0O"
          l:effect_column(1).amount_value = 0xFF
          chunk = nil
          if note_trans and note_trans.note == renoise.PatternLine.NOTE_OFF then
            off_line(s, track, pattern, i.line)
          else
            clear_line(s, track, pattern, i.line)
          end
        else
        -- start a new chunk
          chunk = {
            pattern_tokens = pattern_tokens,
            pattern = to_pattern_index(s, PatternTransforms[pattern_tokens.type].get_pattern(state, pattern_tokens, 0)),
            line = 0,
            start = i.line
          }
          state.lines = s:pattern(chunk.pattern).number_of_lines

        -- apply offset from line command
          if line_tokens then
            chunk.line_tokens = line_tokens
            chunk.start = to_line_index(s, chunk.pattern, LineTransforms[line_tokens.type].get_line(state, line_tokens))
          end

          render_line(s, pattern, tracks, state.line, chunk, note_trans)

        -- stop chunk after single line
          if pattern_tokens.flag == PatternFlag.single_line then 
            chunk = nil
          end
        end
      else
      -- inside previous chunk        
        if chunk then
          step_chunk()
          if chunk.line_tokens then
          -- pick new lines if random line mode
            if chunk.line_tokens.mode == LineMode.random then
              if chunk.line_tokens.type ~= LineType.beat then
                chunk.start = to_line_index(s, chunk.pattern, LineTransforms[LineType.random].get_line(state, chunk.line_tokens))
              end
            end
          end

        -- pick new pattern if E pattern command
          if chunk.pattern_tokens.type == PatternType.random_patterns then
            chunk.pattern = to_pattern_index(s, PatternTransforms[PatternType.random].get_pattern(state, chunk.pattern_tokens, chunk.line))
          end

          render_line(s, pattern, tracks, state.line, chunk, note_trans)
        else

        -- outside chunk
          clear_line(s, track, pattern, i.line)
        end
      end
    end
  end
end
