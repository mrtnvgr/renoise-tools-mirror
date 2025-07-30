
local rns = nil

function selected_slots() --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=]

  local range, added_patterns = { }, { }

  for track_i in ipairs(rns.tracks) do
    for seq, pattern_i in ipairs(rns.sequencer.pattern_sequence) do
      if rns.sequencer:track_sequence_slot_is_selected(track_i, seq)
      and not rns:pattern(pattern_i):track(track_i).is_empty then
        if not added_patterns[pattern_i] then
          added_patterns[pattern_i] = track_i
          table.insert(range, {
            pattern = pattern_i,
            track = track_i,
            sequence = seq
          })
        end
      end
    end
    added_patterns = { }
  end

  return range
end                                            --=-=-=-=- ( 16/o8/22 ) -=-=-=-=]



function hash(str) ---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=]
  local cnt = 1
  local len = string.len(str)
  for i = 1, len, 3 do
    cnt = math.fmod(cnt*8161, 4294967279) +
    (string.byte(str,i)*16776193) +
    ((string.byte(str,i+1) or (len-i+256))*8372226) +
    ((string.byte(str,i+2) or (len-i+256))*3932164)
  end
  return math.fmod(cnt, 4294967291)
end                                            --=-=-=-=- ( 16/o8/22 ) -=-=-=-=]



function hash_patterntrack(pattern_i, track_i) ---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=]

  local str = ""
  local track = rns:pattern(pattern_i):track(
    track_i):lines_in_range(1, rns:pattern(pattern_i).number_of_lines)

  for line_index, line in ipairs(track) do
    if not line.is_empty then
      str = str .. "**" .. line_index .. tostring(line)
    end
  end

  return hash(str) .. track_i
end                                            --=-=-=-=- ( 16/o8/22 ) -=-=-=-=]



function alias_identical() ---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=]

  rns = renoise.song()
  local t_hash = { }

  renoise.app():show_status("Aliasing identical tracks...")

  for i, slot in ipairs(selected_slots()) do
    local patterntrack = rns:pattern(slot.pattern):track(slot.track)
    if not patterntrack.is_alias then
      local pt_hash = hash_patterntrack(slot.pattern, slot.track)
      if not t_hash[pt_hash] then
        t_hash[pt_hash] = {
          pattern = slot.pattern,
          track = slot.track
        }
      elseif t_hash[pt_hash].track == slot.track then
        patterntrack.alias_pattern_index = t_hash[pt_hash].pattern
      end
    end
  end

  renoise.app():show_status("Identical tracks aliased")
end                                            --=-=-=-=- ( 16/o8/22 ) -=-=-=-=]



renoise.tool():add_menu_entry {
  name = "Pattern Matrix:Alias Identical Tracks",
  invoke = alias_identical
}
