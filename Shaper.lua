class "Shaper"

require "ShaperWindow"

----------------------------------------------------------------------------------------------------

class "RenoiseScriptingTool" (renoise.Document.DocumentNode)


function RenoiseScriptingTool:__init()

    renoise.Document.DocumentNode.__init(self)
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")

end


----------------------------------------------------------------------------------------------------


function Shaper:__init ()

    local m = RenoiseScriptingTool()
    m:load_from("manifest.xml")
    self.tool_name = m:property("Name").value
    self.tool_id = m:property("Id").value

    self.window = ShaperWindow (self)

end


----------------------------------------------------------------------------------------------------


local function random_in_range (a, b)
    if a < b then
        return math.random (a * 1000, b * 1000) / 1000
    else
        return math.random (b * 1000, a * 1000) / 1000
    end
end


----------------------------------------------------------------------------------------------------


function Shaper:write_fixed_waves_on_notes (track_index, parameter, sequence_index, start_line, length,
                                            shapes, resolution,
                                            attack, attack_mode, release,
                                            origin, origin_mode, origin_dest,
                                            peak, peak_mode, peak_dest )

    local attack_function = Shaper.shape_functions[shapes[1]]
    local release_function = nil
    if shapes[2] then
        release_function = Shaper.shape_functions[shapes[2]]
    end

    local notes = self:scan_notes (track_index, parameter, sequence_index, start_line, length, attack, attack_mode)

    self:remove_points (track_index, parameter, sequence_index, start_line, length)

    local origin_step = 0
    if origin_mode == 2 and notes.nb_real_notes > 1 then origin_step = (origin_dest - origin) / (notes.nb_real_notes - 1) end

    local peak_step = 0
    if peak_mode == 2 and notes.nb_real_notes > 1 then peak_step = (peak_dest - peak) / (notes.nb_real_notes - 1) end

    local o = origin
    local p = peak
    local j = 0 -- to count real note-on, without note-off
    for i = 1, #notes do

        if notes[i].note < 120 then

            if origin_mode == 3 then o = random_in_range (origin, origin_dest) end
            if peak_mode == 3 then p = random_in_range (peak, peak_dest) end

            if not notes[i].no_attack then
                self:remove_points (track_index, parameter, notes[i].sequence_index, notes[i].position, attack)
                self:write_wave (track_index, parameter, notes[i].sequence_index,
                                 notes[i].position, attack,
                                 attack_function,
                                 0, attack,
                                 resolution,
                                 o + j * origin_step,
                                 p + j * peak_step )
            end

            if release_function then
                self:remove_points (track_index, parameter, notes[i].sequence_index, notes[i].position + attack, release)
                self:write_wave (track_index, parameter, notes[i].sequence_index,
                                 notes[i].position + attack, release,
                                 release_function,
                                 0, release,
                                 resolution,
                                 o + j * origin_step,
                                 p + j * peak_step )
            else
                if notes[i].position - 1/256 >= 1 then
                    self:add_point (track_index, parameter, notes[i].sequence_index, notes[i].position - 1/256, o)
                else
                    -- Since there's no interpolation between patterns, no need to insert a point
                    --~ p = renoise.song().sequencer:pattern (notes[i].sequence_index - 1)
                    --~ self:add_point (track_index, parameter, notes[i].sequence_index - 1, #renoise.song().patterns[p].tracks[track_index].lines - 1/256, origin)
                end
                self:add_point (track_index, parameter, notes[i].sequence_index, notes[i].position + attack, o)
            end

        j = j + 1
        end

    end

end


----------------------------------------------------------------------------------------------------


function Shaper:write_scaled_waves_on_notes (track_index, parameter, sequence_index, start_line, length,
                                             shapes, resolution,
                                             attack, attack_mode,
                                             origin, origin_mode, origin_dest,
                                             peak, peak_mode, peak_dest )

    local attack_function = Shaper.shape_functions[shapes[1]]
    local release_function = nil
    if shapes[2] then
        release_function = Shaper.shape_functions[shapes[2]]
    end
    if not release_function and not attack_mode then
        release_function = attack_function
        attack_function = nil
        attack = 0
    end

    local notes = self:scan_notes (track_index, parameter, sequence_index, start_line, length, attack, attack_mode)

    self:remove_points (track_index, parameter, sequence_index, start_line, length)

    local origin_step = 0
    if origin_mode == 2 and notes.nb_real_notes > 1 then origin_step = (origin_dest - origin) / (notes.nb_real_notes - 1) end

    local peak_step = 0
    if peak_mode == 2 and notes.nb_real_notes > 1 then peak_step = (peak_dest - peak) / (notes.nb_real_notes - 1) end

    local o = origin
    local p = peak
    local j = 0
    for i = 1, #notes do

        if notes[i].note < 120 then

            if origin_mode == 3 then o = random_in_range (origin, origin_dest) end
            if peak_mode == 3 then p = random_in_range (peak, peak_dest) end

            if attack_function and not notes[i].no_attack then
                self:remove_points (track_index, parameter, notes[i].sequence_index, notes[i].position, attack)
                self:write_wave (track_index, parameter, notes[i].sequence_index,
                                 notes[i].position, attack,
                                 attack_function,
                                 0, attack,
                                 resolution,
                                 o + j * origin_step,
                                 p + j * peak_step )
            end

            if release_function and notes[i].length - attack > 0 then
                self:remove_points (track_index, parameter, notes[i].sequence_index, notes[i].position + attack, notes[i].length - attack)
                self:write_wave (track_index, parameter, notes[i].sequence_index,
                                 notes[i].position + attack, notes[i].length - attack,
                                 release_function,
                                 0, notes[i].length - attack,
                                 resolution,
                                 o + j * origin_step,
                                 p + j * peak_step )
            end

            if notes[i].position - 1/256 >= 1 then
                self:add_point (track_index, parameter, notes[i].sequence_index, notes[i].position - 1/256, o)
            else
                -- Since there's no interpolation between patterns, no need to insert a point
                --~ p = renoise.song().sequencer:pattern (notes[i].sequence_index - 1)
                --~ self:add_point (track_index, parameter, notes[i].sequence_index - 1, #renoise.song().patterns[p].tracks[track_index].lines - 1/256, origin)
            end

            if attack_mode and not release_function then
                if notes[i].position + attack + 1/256 > 1 then
                    self:add_point (track_index, parameter, notes[i].sequence_index, notes[i].position + attack + 1/256, o)
                end
            else
                if notes[i].position + notes[i].length + 1/256 > 1 then
                    self:add_point (track_index, parameter, notes[i].sequence_index, notes[i].position + notes[i].length + 1/256, o)
                end
            end

        j = j + 1
        end

    end

end


----------------------------------------------------------------------------------------------------


function Shaper:scan_notes (track_index, parameter, sequence_index, start_line, length, attack, attack_mode)


    local p = renoise.song().sequencer:pattern (sequence_index)

    local notes = {}

    local si = sequence_index
    local sl = start_line
    local dl = 0
    local note_length = 0
    notes.nb_real_notes = 0
    for i = 1, length do
        if sl + dl > #renoise.song().patterns[p].tracks[track_index].lines then
            si = si + 1
            p = renoise.song().sequencer:pattern (si)
            sl = 1
            dl = 0
        end
        local note = renoise.song().patterns[p].tracks[track_index]:line(sl + dl):note_column (1)
        if note.note_value < 121 then
            if #notes > 0 then
                notes[#notes].length = note_length
            end
            notes[#notes + 1] = { sequence_index = si, position = sl + dl, note = note.note_value, }
            note_length = 0
            if note.note_value < 120 then
                notes.nb_real_notes = notes.nb_real_notes + 1
            end
        end
        dl = dl + 1
        note_length = note_length + 1
    end
    if #notes > 0 then
        notes[#notes].length = note_length
    end

    if attack_mode then
        for i = 1, #notes do
            notes[i].position = notes[i].position - attack
            if notes[i].position < 1 then
                if notes[i].sequence_index > 1 then
                    notes[i].sequence_index = notes[i].sequence_index - 1
                    p = renoise.song().sequencer:pattern (notes[i].sequence_index)
                    notes[i].position = #renoise.song().patterns[p].tracks[track_index].lines + notes[i].position
                else
                    notes[i].no_attack = true
                end
            end
        end
    end

    return notes

end


----------------------------------------------------------------------------------------------------


function Shaper:write_multiple_waves (track_index, parameter, sequence_index, start_line, length,
                                      shapes, alt_shapes, nb_waves, phase, resolution,
                                      origin, origin_mode, origin_dest,
                                      peak, peak_mode, peak_dest,
                                      alt_peak, alt_peak_mode, alt_peak_dest )

    self:remove_points (track_index, parameter, sequence_index, start_line, length)

    local wave_length = length / nb_waves

    local o = origin
    local origin_step = 0
    if origin_mode == 2 and nb_waves > 1 then origin_step = (origin_dest - origin) / (nb_waves - 1) end

    local p = peak
    local peak_step = 0
    if peak_mode == 2 and nb_waves > 1 then peak_step = (peak_dest - peak) / (nb_waves - 1) end

    local ap = alt_peak
    local alt_peak_step = 0
    if alt_peak_mode == 2 and nb_waves > 1 then alt_peak_step = (alt_peak_dest - alt_peak) / (nb_waves - 1) end

    local wave_function = Shaper.shape_functions[shapes[1]]
    if shapes[2] then
        wave_function = function (x)
            if x < 0.5 then
                return Shaper.shape_functions[shapes[1]] (x * 2)
            else
                return Shaper.shape_functions[shapes[2]] ((x - 0.5) * 2)
            end
        end
    end

    local alt_wave_function = Shaper.shape_functions[alt_shapes[1]]
    if alt_shapes[2] then
        alt_wave_function = function (x)
            if x < 0.5 then
                return Shaper.shape_functions[alt_shapes[1]] (x * 2)
            else
                return Shaper.shape_functions[alt_shapes[2]] ((x - 0.5) * 2)
            end
        end
    end

    local start = phase * wave_length
    local stop = length + start
    local x = start_line - start
    for i = 0, nb_waves do

        if origin_mode == 3 then o = random_in_range (origin, origin_dest) end
        if peak_mode == 3 then p = random_in_range (peak, peak_dest) end
        if alt_peak_mode == 3 then ap = random_in_range (alt_peak, alt_peak_dest) end

        if i % 2 == 0 then
            self:write_wave (track_index, parameter, sequence_index,
                             x, wave_length,
                             wave_function,
                             start, stop,
                             resolution,
                             o + i * origin_step,
                             p + i * peak_step )
        else
            self:write_wave (track_index, parameter, sequence_index,
                             x, wave_length,
                             alt_wave_function,
                             start, stop,
                             resolution,
                             o + i * origin_step,
                             ap + i * alt_peak_step )
        end

        x = x + wave_length
        start = 0
        stop = stop - wave_length

    end

end


----------------------------------------------------------------------------------------------------


function Shaper:write_wave (track_index, parameter, sequence_index, start_line, wave_length, wave_function, start, stop, resolution, origin, peak)

    local scale = peak - origin

    -- Special case needed for first wave of curve when phase is not 0
    self:add_point (track_index, parameter, sequence_index, start_line + start, origin  + scale * wave_function (start / wave_length))

    for position = 0, wave_length - 1/256, resolution do
        if position >= start and position <= stop then
            local x = position / wave_length
            self:add_point (track_index, parameter, sequence_index, start_line + position, origin  + scale * wave_function (x))
        end
    end

    local p = wave_length / 2 - 1/256
    if p >= start and p <= stop then
        self:add_point (track_index, parameter, sequence_index, start_line + p, origin  + scale * wave_function (0.49999))
    end

    p = wave_length / 2
    if p >= start and p <= stop then
        self:add_point (track_index, parameter, sequence_index, start_line + p, origin  + scale * wave_function (0.5))
    end

    p = wave_length - 1/256
    if p >= start and p <= stop then
        self:add_point (track_index, parameter, sequence_index, start_line + p, origin  + scale * wave_function (1))
    end

    -- Special case needed for last wave of curve when phase is not 0
    if stop > start and stop < wave_length then
        self:add_point (track_index, parameter, sequence_index, start_line + stop - 1/256, origin  + scale * wave_function (stop / wave_length))
    end

end


----------------------------------------------------------------------------------------------------


function Shaper:remove_points (track_index, parameter, sequence_index, start_line, length)

    local pattern_index = renoise.song().sequencer:pattern (sequence_index)
    local nl = renoise.song().patterns[pattern_index].number_of_lines
    local a = renoise.song().patterns[pattern_index].tracks[track_index]:find_automation (parameter)

    local dl = 0
    for i = 0, length - 1/256, 1/256 do

        dl = dl + 1/256
        while start_line + dl > nl + 1 do
            sequence_index = sequence_index + 1
            if sequence_index > #renoise.song().sequencer.pattern_sequence then return end
            pattern_index = renoise.song().sequencer:pattern (sequence_index)
            if not pattern_index then return end
            nl = renoise.song().patterns[pattern_index].number_of_lines
            a = renoise.song().patterns[pattern_index].tracks[track_index]:find_automation (parameter)
            start_line = 1
            dl = 0
        end

        if a then
            if a:has_point_at (start_line + dl) then
                a:remove_point_at (start_line + dl)
            end
        end

    end

end


----------------------------------------------------------------------------------------------------


local function clamp (v)
    if v < 0 then v = 0
    elseif v > 1 then v = 1
    end
    return v
end


function Shaper:add_point (track_index, parameter, sequence_index, position, value)

    local pattern_index = renoise.song().sequencer:pattern (sequence_index)
    local nl = renoise.song().patterns[pattern_index].number_of_lines

    while position > nl + 1 do
        sequence_index = sequence_index + 1
        if sequence_index > #renoise.song().sequencer.pattern_sequence then return end
        pattern_index = renoise.song().sequencer.pattern_sequence[sequence_index]
        if not pattern_index then return end
        position = position - nl
        nl = renoise.song().patterns[pattern_index].number_of_lines
    end

    local a = renoise.song().patterns[pattern_index].tracks[track_index]:find_automation(parameter)
    if not a then
        a = renoise.song().patterns[pattern_index].tracks[track_index]:create_automation (parameter)
    end

    a:add_point_at (position, clamp (value))

end


----------------------------------------------------------------------------------------------------


-- All shape functions map from [0, 1] to [0, 1]
Shaper.shape_functions =
{
    square_down = function (x) return 0 end,
    square_up = function (x) return 1 end,

    linear_up =  function (x) return x end,
    linear_down = function (x) return 1 - x end,

    step_up = function (x)
        local st = math.floor (x / 0.5)
        return st * 0.5
    end,
    step_down = function (x)
        local st = math.floor ((1 - x) / 0.5)
        if x < 0.996 then
            return st * 0.5 + 0.5
        else
            return 0
        end
    end,

    wave_up = function (x) return (1 - math.cos (x * math.pi)) / 2 end,
    wave_down = function (x) return math.cos (x * math.pi) / 2 + 0.5 end,

    concave_up = function (x) return 1 - math.sin (math.acos (x)) end,
    concave_down = function (x) return 1 - math.sin (math.acos (1 - x)) end,

    convex_up = function (x) return math.sin (math.acos (1 - x)) end,
    convex_down = function (x) return math.sin (math.acos (x)) end,

    halfsine_up = function (x) return 0.5 + math.sin (x * math.pi) / 2 end,
    halfsine_down = function (x) return 0.5 - math.sin(x * math.pi) / 2 end,

    convex_sin_up = function (x) return math.sin(x * math.pi / 2) end,
    convex_sin_down = function (x) return math.cos(x * math.pi / 2) end,

    concave_sin_up = function (x) return 1 - math.cos(x * math.pi / 2) end,
    concave_sin_down = function (x) return 1 - math.sin(x * math.pi / 2) end,
}


----------------------------------------------------------------------------------------------------
