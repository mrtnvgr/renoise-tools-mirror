--------------------------------------------------------------------------------
-- Tuned Shortcuts for Renoise
-- by ffx a.k.a. J. Raben
-- v1.0
--------------------------------------------------------------------------------

TRACE = function () end
_trace_filters = nil
_xlibroot = "lib/xLib/classes/"

require (_xlibroot.."xLib")
require (_xlibroot..'xScale')

rns = nil 


--------------------------------------------------------------------------------

class "TunedShortcuts"

TunedShortcuts.playOnEdit = true
TunedShortcuts.isPlayOnEdit = false
TunedShortcuts.playLineFunc = nil
TunedShortcuts.editPosFunc = nil
TunedShortcuts.lastPos = nil
TunedShortcuts.followTimerFunc = nil
TunedShortcuts.curFollow = nil
TunedShortcuts.playposFract = nil
TunedShortcuts.writeahead = nil
TunedShortcuts.shiftOptions = nil
TunedShortcuts.statusDelay = 1


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

TunedShortcuts.expandMinimumLPB = 32


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function TunedShortcuts:clearStatusFunc()
    if (self.statusTimerFunc ~= nil and renoise.tool():has_timer(self.statusTimerFunc)) then
        renoise.tool():remove_timer(self.statusTimerFunc)
        self.statusTimerFunc = nil
    end
end 

function TunedShortcuts:showStatusDelayed(message)
    self:clearStatusFunc()
    self.statusTimerFunc = function () 
        self:clearStatusFunc()
        renoise.app():show_status(message)
    end
    if self.statusDelay == 0 then
        self.statusTimerFunc()
    else
        renoise.tool():add_timer(self.statusTimerFunc, self.statusDelay)
    end

end
function TunedShortcuts:clearFollowFunc()
    if (self.followTimerFunc ~= nil and renoise.tool():has_timer(self.followTimerFunc)) then
        renoise.tool():remove_timer(self.followTimerFunc)
        self.followTimerFunc = nil
    end
end 

function TunedShortcuts:setFollowDelayed()
    self:clearFollowFunc()
    if (self.curFollow == nil) then return end
    self.followTimerFunc = function () 
        self:clearFollowFunc()
        renoise.song().transport.follow_player = self.curFollow
        self.curFollow = nil
    end
    renoise.tool():add_timer(self.followTimerFunc, 500)

end


-- Pattern resize code, borrowed from dblue's pattern resize tool

-- Constants.
local MAX_PATTERN_LINES = renoise.Pattern.MAX_NUMBER_OF_LINES
local NOTE_OFF = (renoise.API_VERSION == 4) and renoise.PatternLine.NOTE_OFF or renoise.PatternTrackLine.NOTE_OFF
local TRACK_TYPE_SEQUENCER = renoise.Track.TRACK_TYPE_SEQUENCER

-- Functions.
local function round(value)
    return math.floor(value + 0.5)
end

function safe_pattern_length(value)
    return math.min(MAX_PATTERN_LINES, math.max(1, value))
end

function adjust_pattern_length(factor)
    return safe_pattern_length(round(renoise.song().selected_pattern.number_of_lines * factor))
end

function resize_pattern(pattern, new_length)

    -- We need a valid pattern object.
    if (pattern == nil) then
        renoise.app():show_status('Need a valid pattern object!')
        return
    end

    -- Shortcut to the song object.
    local rs = renoise.song()

    -- Get the current pattern length.
    local src_length = pattern.number_of_lines 

    -- Make sure new_length is within valid limits.
    local dst_length = math.min(MAX_PATTERN_LINES, math.max(1, new_length))

    -- If the new length is the same as the old length, then we have nothing to do.
    if (dst_length == src_length) then
        return
    end

    -- Set conversion ratio.
    local ratio = dst_length / src_length

    -- Change pattern length.
    pattern.number_of_lines = dst_length

    -- Source.
    local src_track = nil
    local src_line = nil
    local src_note_column = nil
    local src_effect_column = nil

    -- Insert a new track as a temporary work area.
    rs:insert_track_at(1)

    -- Destination.
    local dst_track = pattern:track(1)
    local dst_line_index = 0
    local dst_delay = 0
    local dst_line = nil
    local dst_note_column = nil
    local dst_effect_column = nil

    -- Misc.
    local tmp_line_index = 0
    local tmp_line_delay = 0
    local delay_column_used = false 
    local track = nil

    -- Iterate through each track.
    for src_track_index = 2, #rs.tracks, 1 do

        track = rs:track(src_track_index)

        -- Set source track.
        src_track = pattern:track(src_track_index)

        -- Reset delay check.
        delay_column_used = false

        -- Iterate through source lines.
        for src_line_index = 0, src_length - 1, 1 do

            -- Set source line.
            src_line = src_track:line(src_line_index + 1)

            -- Only process source line if it contains data.
            if (not src_line.is_empty) then

                -- Store temporary line index and delay.
                tmp_line_index = math.floor(src_line_index * ratio)
                tmp_line_delay = math.floor(((src_line_index * ratio) - tmp_line_index) * 256)

                -- Process note columns.
                for note_column_index = 1, track.visible_note_columns, 1 do

                    -- Set source note column.
                    src_note_column = src_line:note_column(note_column_index)

                    -- Only process note column if it contains data.
                    if (not src_note_column.is_empty) then

                        -- Calculate destination line and delay.
                        dst_line_index = tmp_line_index
                        dst_delay = math.ceil(tmp_line_delay + (src_note_column.delay_value * ratio))

                        -- Wrap note to next line if necessary.
                        while (dst_delay >= 256) do
                            dst_delay = dst_delay - 256
                            dst_line_index = dst_line_index + 1
                        end

                        -- Keep track of whether the delay column is used
                        -- so that we can make it visible later if necessary.
                        if (dst_delay > 0) then
                            delay_column_used = true
                        end
                        dst_line = dst_track:line(dst_line_index + 1)
                        dst_note_column = dst_line:note_column(note_column_index)

                        -- Note prioritisation.
                        if (dst_note_column.is_empty) then

                            -- Destination is empty. Safe to copy.
                            dst_note_column:copy_from(src_note_column)
                            dst_note_column.delay_value = dst_delay 

                        else
                            -- Destination contains data. 
                            -- Try to prioritise which note to keep...

                            -- If destination contains a note-off...
                            if (dst_note_column.note_value == NOTE_OFF) then

                                -- Source note takes priority.
                                dst_note_column:copy_from(src_note_column)
                                dst_note_column.delay_value = dst_delay

                            else

                                -- If the source note is less delayed, or louder, than the
                                -- destination note...
                                if (src_note_column.delay_value < dst_note_column.delay_value) 
                                    or (src_note_column.volume_value > dst_note_column.volume_value) then

                                    -- Source note takes priority.
                                    dst_note_column:copy_from(src_note_column)
                                    dst_note_column.delay_value = dst_delay

                                end

                            end 

                        end -- End: Note prioritisation.

                    end -- End: Only process note column if it contains data.

                end -- End: Process note columns.

                -- Process effect columns.
                for effect_column_index = 1, track.visible_effect_columns, 1 do
                    src_effect_column = src_line:effect_column(effect_column_index)
                    if (not src_effect_column.is_empty) then
                        dst_effect_column = dst_track:line(round(src_line_index * ratio) + 1):effect_column(effect_column_index)
                        if (dst_effect_column.is_empty) then
                            dst_effect_column:copy_from(src_effect_column)
                        end
                    end
                end

            end -- End: Only process source line if it contains data.

        end -- End: Iterate through source lines.

        -- If there is automation to process...
        if (#src_track.automation > 0) then

            -- Copy processed lines from temporary track back to original track.
            -- We can't simply use dst_track:copy_from(src_track) here, since 
            -- it will erase the automation.
            for line_index = 1, dst_length, 1 do
                dst_line = dst_track:line(line_index)
                src_line = src_track:line(line_index)
                src_line:copy_from(dst_line)
            end

            -- Process automations.
            for _, automation in ipairs(src_track.automation) do

                -- Calculate scaled points.
                local points = {}
                local max_time = dst_length + 1
                for _, point in ipairs(automation.points) do
                    local new_time = 1 + ((point.time - 1) * ratio)
                    if (new_time < max_time) then
                        table.insert(points, {
                            time = new_time, 
                            value = point.value 
                        })
                    end
                end
                local num_points = #points

                -- Clear old automation.
                automation:clear()

                -- Ensure the first and last points always get added.
                automation:add_point_at(points[1].time, points[1].value)
                if (num_points > 1) then
                    automation:add_point_at(
                        points[num_points].time, 
                        points[num_points].value
                    )
                end

                -- Add the in-between points.
                if (num_points > 2) then
                    for i = 2, num_points - 1 do
                        local point = points[i]
                        if (not automation:has_point_at(point.time)) then
                            automation:add_point_at(point.time, point.value)
                        end
                    end
                end

            end

            -- Else, we have no automation to process. 
            -- We can save time and just use copy_from()
        else

            src_track:copy_from(dst_track)

        end

        -- Clear temporary track for re-use.
        dst_track:clear()

        -- Show the delay column if any note delays have been used.
        if (rs:track(src_track_index).type == TRACK_TYPE_SEQUENCER) then
            if (delay_column_used) then
                rs:track(src_track_index).delay_column_visible = true
            end
        end

    end -- End: Iterate through each track.

    -- Remove temporary track.
    rs:delete_track_at(1)

end


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function TunedShortcuts:register_keys()
    local expandFactor = 1
    local isExpanded = false
    local lastQuantState = false
    local checkExpand = function(doFixQuant)
        local t = renoise.song().transport
        if (expandFactor > 1 and isExpanded) then
            isExpanded = false
            local selTr = renoise.song().selected_track_index

            -- Adjust selected line index
            local sli = renoise.song().selected_line_index
            local max_lines = renoise.song().selected_pattern.number_of_lines
            local new_sli = math.max(1, math.min(max_lines, ((sli - 1) * 1 / expandFactor) + 1))
            renoise.song().selected_line_index = new_sli

            -- Adjust LPB
            local t = renoise.song().transport 
            t.lpb = math.max(1, math.min(256, t.lpb / expandFactor))

            -- Move transport to the new position and resume/stop playback
            local playing = t.playing
            t:start_at(new_sli)
            if (not playing) then t:stop() end

            -- Resize pattern
            resize_pattern(renoise.song().selected_pattern, adjust_pattern_length(1 / expandFactor))

            renoise.song().selected_track_index = selTr
            if (doFixQuant) then t.edit_step = t.edit_step / expandFactor end
            expandFactor = 1
        end
        if (t.edit_step <= 32 and t.edit_step > 0) then
            t.record_quantize_lines = t.edit_step
        end
    end

    local doExpand = function(doFixQuant)
        local rs = renoise.song()
        local t = rs.transport
        
        -- calc most usable expandfactor without breaking renoise limitations
        expandFactor = 1
        while (expandFactor * t.lpb < self.expandMinimumLPB) do
            expandFactor = expandFactor + 1
        end
        while (expandFactor * t.lpb > 256) do
            expandFactor = expandFactor - 1
        end
        while (round(rs.selected_pattern.number_of_lines * expandFactor) > 512) do
            expandFactor = expandFactor - 1
        end
        
        if (t.edit_mode and expandFactor > 1) then 
            isExpanded = true
            local selTr = renoise.song().selected_track_index

            -- Resize pattern
            resize_pattern(renoise.song().selected_pattern, adjust_pattern_length(expandFactor))

            -- Adjust selected line index
            local sli = renoise.song().selected_line_index
            local max_lines = renoise.song().selected_pattern.number_of_lines
            local new_sli = math.max(1, math.min(max_lines, ((sli - 1) * expandFactor) + 1))
            renoise.song().selected_line_index = new_sli

            -- Adjust LPB
            local t = renoise.song().transport
            t.lpb = math.max(1, math.min(256, expandFactor * t.lpb))

            -- Move transport to the new position and resume/stop playback
            local playing = t.playing
            t:start_at(new_sli)
            if (not playing) then t:stop() end

            renoise.song().selected_track_index = selTr


            if (doFixQuant) then t.edit_step = t.edit_step * expandFactor end
            if (t.edit_step <= 32 and t.edit_step > 0) then
                t.record_quantize_lines = t.edit_step
            end
        else 
            checkExpand(doFixQuant)
        end
    end 

    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Metronome", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            checkExpand(false)
        end 
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Metronome & Precount", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            t.metronome_precount_enabled = t.edit_mode
            checkExpand(false)
        end
    }


    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Mt. & Expand", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            doExpand(true)

        end 
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Mt. & Precount & Expand", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            t.metronome_precount_enabled = t.edit_mode
            doExpand(true)
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit Mode & Mt. & Expand & No Quant", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            doExpand(false)
            if (t.edit_mode) then
                lastQuantState = t.record_quantize_enabled
                t.record_quantize_enabled = false
            else
                t.record_quantize_enabled = lastQuantState
            end
        end 
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Mt. & Precount & Expand & No Quant", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_enabled = t.edit_mode
            t.metronome_precount_enabled = t.edit_mode
            doExpand(false)
            if (t.edit_mode) then
                lastQuantState = t.record_quantize_enabled
                t.record_quantize_enabled = false
            else
                t.record_quantize_enabled = lastQuantState
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit Mode & Expand & No Quant", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            doExpand(false)
            if (t.edit_mode) then
                lastQuantState = t.record_quantize_enabled
                t.record_quantize_enabled = false
            else
                t.record_quantize_enabled = lastQuantState
            end
        end 
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Toggle Edit & Precount & Expand & No Quant", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_mode = not t.edit_mode
            t.metronome_precount_enabled = t.edit_mode
            doExpand(false)
            if (t.edit_mode) then
                lastQuantState = t.record_quantize_enabled
                t.record_quantize_enabled = false
            else
                t.record_quantize_enabled = lastQuantState
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Decrease edit & quantization step", 
        invoke = function()
            local t = renoise.song().transport
            if (t.edit_step > 0) then
                t.edit_step = t.edit_step / expandFactor
                if (t.edit_step > 16) then
                    t.edit_step = t.edit_step - 4
                elseif (t.edit_step > 8) then
                    t.edit_step = t.edit_step - 2
                elseif (t.edit_step > 0) then
                    t.edit_step = t.edit_step - 1
                end
            end
            if (t.edit_step > 0) then
                if (t.edit_step * expandFactor <= 32) then
                    t.edit_step = t.edit_step * expandFactor
                end
                if (t.edit_step <= 32) then
                    t.record_quantize_lines = t.edit_step
                end
                t.record_quantize_enabled = true
            end
            if (t.edit_step == 0 and t.record_quantize_enabled) then
                t.edit_step = 1
                t.record_quantize_lines = 1
                t.record_quantize_enabled = false
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Decrease edit & quantization step (never reach 0)", 
        invoke = function()
            local t = renoise.song().transport
            if (t.edit_step > 0) then
                t.edit_step = t.edit_step / expandFactor
                if (t.edit_step > 16) then
                    t.edit_step = t.edit_step - 4
                elseif (t.edit_step > 8) then
                    t.edit_step = t.edit_step - 2
                elseif (t.edit_step > 0) then
                    t.edit_step = t.edit_step - 1
                end
            end
            if (t.edit_step > 0) then
                if (t.edit_step * expandFactor <= 32) then
                    t.edit_step = t.edit_step * expandFactor
                end
                if (t.edit_step <= 32) then
                    t.record_quantize_lines = t.edit_step
                end
                t.record_quantize_enabled = true
            end
            if (t.edit_step == 0) then
                t.edit_step = 1
                t.record_quantize_lines = 1
                t.record_quantize_enabled = false
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Increase edit & quantization step", 
        invoke = function()
            local t = renoise.song().transport
            t.edit_step = t.edit_step / expandFactor
            if (t.edit_step < 64) then
                if (t.edit_step >= 16) then
                    t.edit_step = t.edit_step + 4
                elseif (t.edit_step >= 8) then
                    t.edit_step = t.edit_step + 2
                elseif (t.record_quantize_enabled) then
                    t.edit_step = t.edit_step + 1
                end
            end
            if (t.edit_step * expandFactor <= 32) then
                t.edit_step = t.edit_step * expandFactor
            end
            if (t.edit_step <= 32 and t.edit_step > 0) then
                t.record_quantize_lines = t.edit_step
            end
            t.record_quantize_enabled = true
            if (t.edit_step == 0) then
                t.edit_step = 1
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Alternative Block Playing", 
        invoke = function()
            local t = renoise.song().transport
            if (t.loop_block_enabled == false) then
                if (t.playing == false) then
                    t:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
                end
            else
                t:stop()
            end
            t.loop_block_enabled = not t.loop_block_enabled
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Alternative Pattern Playing", 
        invoke = function()
            local t = renoise.song().transport
            if (t.loop_pattern == false) then
                if (t.playing == false) then
                    t:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
                end
            else
                t:stop()
            end
            t.loop_pattern = not t.loop_pattern
            if (t.loop_pattern) then
                t.loop_block_enabled = false
            end
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Alternative Block Playing (No stop)", 
        invoke = function()
            local t = renoise.song().transport
            if (t.loop_block_enabled == false) then
                if (t.playing == false) then
                    t:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
                end
            end
            t.loop_block_enabled = not t.loop_block_enabled
        end
    }
    renoise.tool():add_keybinding {
        name = "Global:Transport:Alternative Pattern Playing (No stop)", 
        invoke = function()
            local t = renoise.song().transport
            if (t.loop_pattern == false) then
                if (t.playing == false) then
                    t:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
                end
            end
            t.loop_pattern = not t.loop_pattern
            if (t.loop_pattern) then
                t.loop_block_enabled = false
            end
        end
    }

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Navigation:Toggle Play On Edit", 
        invoke = function()
            local s = renoise.song()
            if (s == nil) then return end

            local t = s.transport
            self.isPlayOnEdit = not self.isPlayOnEdit

            if (self.isPlayOnEdit) then -- on
                self:showStatusDelayed("Toggle Play On Edit ACTIVATED")
                self.lastPos = s.selected_line_index

                self.editPosFunc = function()
                    local curPos = t.edit_pos.line -- s.selected_line_index
                    local ms_per_line = 1000 / t.bpm * 60 / t.lpb
                    local posDirectionDown = (self.lastPos - curPos) < 0

                    -- editing pos change
                    if (not t.playing and t.edit_mode and self.lastPos ~= curPos) then

                        -- remember metronome etc settings, switch to no follow :(
                        local curMetroPreValue = t.metronome_precount_enabled
                        local curMetroValue = t.metronome_enabled
                        local curBpm = t.bpm
                        if (self.curFollow == nil) then
                            self.curFollow = t.follow_player
                        end
                        t.metronome_precount_enabled = false
                        t.metronome_enabled = false
                        t.follow_player = false
                        --t.bpm = 32 

                        -- kill timer func
                        local clearFunc = function ()
                            if (self.playLineFunc ~= nil and renoise.tool():has_timer(self.playLineFunc)) then
                                renoise.tool():remove_timer(self.playLineFunc)
                                self.playLineFunc = nil
                            end 
                        end

                        self.playLineFunc = function () 
                            if (posDirectionDown and (t.edit_pos.line >= curPos or t.edit_pos.line <= 2 and curPos >= s.selected_pattern.number_of_lines - 1) or not posDirectionDown) then
                                -- stop preview play
                                clearFunc()
                                t:stop()
                                -- sets  t.follow_player = self.curFollow   500ms later
                                self:setFollowDelayed()
                                t.metronome_precount_enabled = curMetroPreValue
                                t.metronome_enabled = curMetroValue
                                --t.bpm = curBpm
                            end

                        end

                        -- register timeout for stop
                        clearFunc() 

                        -- preview play the current pos
                        if (posDirectionDown) then
                            renoise.tool():add_timer(self.playLineFunc, ms_per_line * 1.9)
                            t:start_at(curPos)--self.lastPos
                        else
                            -- The value "1.5" is a delicate one, try between 1.2 - 2 to feel the change!!!!
                            renoise.tool():add_timer(self.playLineFunc, ms_per_line * 1.9)
                            t:start_at(curPos) 
                        end
                        self.lastPos = curPos
                        --print("playing at "..curPos)
                    end
                end

                renoise.tool():add_timer(self.editPosFunc, 15)
            else -- off
                if (self.editPosFunc ~= nil) then
                    self:showStatusDelayed("Toggle Play On Edit DISABLED")
                    renoise.tool():remove_timer(self.editPosFunc)
                    self.editPosFunc = nil
                end
            end
        end
    }




    -- scale render
    local render_scale = function()
        local song = renoise.song()
        rns = renoise.song()
        if (song == nil) then return end
        local sli = song.selected_line_index
        local sei = song.selected_effect_column_index
        local spi = song.selected_pattern_index
        local sct = song.selected_sub_column_type

        -- cursor selection
        local line_start = 1
        local line_end = song.selected_pattern.number_of_lines
        local sci_start = song.selected_note_column_index
        local sci_end = song.selected_track.visible_note_columns
        local sti_start = song.selected_track_index
        local sti_end = sti_start

        -- check for multiple line selection
        if (song.selection_in_pattern ~= nil) then
            line_start = song.selection_in_pattern.start_line
            line_end = song.selection_in_pattern.end_line
            sci_start = song.selection_in_pattern.start_column
            sci_end = song.selection_in_pattern.end_column
            sti_start = song.selection_in_pattern.start_track
            sti_end = song.selection_in_pattern.end_track
        end
        
        
        local sli = song.selected_line_index
        local spi = song.selected_pattern_index
        local nv, iv, line, currentScale, currentScaleKey
        
        local cur_track = song:pattern(spi):track(sti_start)
        -- fx column
        if (song.selected_note_column_index == 0) then
            return
        end
        local initial_nv = cur_track:line(sli):note_column(song.selected_note_column_index).note_value
        iv = 0
        for line_num = line_start, line_end, 1 do
            local resultTable = {}
            for sti = sti_start, sti_end, 1 do
                cur_track = song:pattern(spi):track(sti)
                line = cur_track:line(line_num)
                local note_num = 1
                for sci = 1, #line.note_columns, 1 do
                    
                    -- check column selection boundaries
                    local do_process = true
                    if (sti == sti_start and sci < sci_start or sti == sti_end and sci > sci_end) then
                        do_process = false
                    end
                    
                    if (do_process and song:track(sti).type == renoise.Track.TRACK_TYPE_SEQUENCER) then
                        
                        nv = line:note_column(sci).note_value
                        if (line:note_column(sci).instrument_value ~= 255) then
                            iv = line:note_column(sci).instrument_value
                        end

                        table.insert(resultTable, {nv = nv, col = sci, tr = cur_track, line = line, iv = iv})
                        note_num = note_num + 1
                        
                    end
                    
                    
                end
                
                for index, targetNote in pairs(resultTable) do
                    currentScale = rns.instruments[targetNote.iv + 1].trigger_options.scale_mode
                    currentScaleKey = rns.instruments[targetNote.iv + 1].trigger_options.scale_key
                    -- oprint(targetNote.iv .. currentScale)
                    if (targetNote.nv < 120 and currentScaleKey > 0 and currentScale ~= "None") then
                        targetNote.line:note_column(targetNote.col).note_value = xScale.restrict_to_scale(targetNote.nv, currentScale, currentScaleKey)
                    end
                end
                
            end
        end
    end

    local insert_fakec4_phrase = function()
        rns = renoise.song()
        if (rns == nil) then return end
        local cur_ins = rns.selected_instrument_index
        local cur_ins_name = rns.selected_instrument.name
        
        if (#rns.instruments[cur_ins].phrases == 0) then
            local phrase = rns.instruments[cur_ins]:insert_phrase_at(1)
            phrase.looping = false
            self:showStatusDelayed("Inserted fake C4 phrase for instrument #"..tostring(cur_ins - 1) .. " ("..cur_ins_name..")")
        end
        
    end 

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Render Scale", 
        invoke = function()
            render_scale()
            self:showStatusDelayed("Rendered scale")
        end 
    }
    renoise.tool():add_keybinding {
        name = "Instrument Box:Tools:Insert Fake C4 Phrase", 
        invoke = function()
            insert_fakec4_phrase()
            
        end 
    }
    renoise.tool():add_keybinding {
        name = "Global:Tools:Insert Fake C4 Phrase", 
        invoke = function()
            insert_fakec4_phrase()
        end 
    }

    renoise.tool():add_menu_entry {
        name = "Instrument Box:Insert Fake C4 Phrase", 
        invoke = function () 
            insert_fakec4_phrase()
        end
    }


    -- mono check
    renoise.tool():add_keybinding {
        name = "Global:Tools:Mono check", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end

            local devicename = "Mono Check"; 
            local master_offset = song.sequencer_track_count + 1
            local last_offset = #renoise.song():track(master_offset).devices + 1
            -- insert new device
            if (song.tracks[master_offset].devices[last_offset - 1].display_name ~= devicename) then 
                song:track(master_offset):insert_device_at('Audio/Effects/Native/Stereo Expander', last_offset) 
                local device = song.tracks[master_offset].devices[last_offset]
                device.display_name = devicename
                device.is_maximized = false
                device.parameters[1].value = 0
                device.parameters[2].value = 0
                --for index, val in pairs(device.parameters) do
                --  oprint(val.name)
                --end

                -- remove device
            else
                song:track(master_offset):delete_device_at(last_offset - 1) 
                devicename = "Side Check"; 
                master_offset = song.sequencer_track_count + 1
                last_offset = #renoise.song():track(master_offset).devices + 1
                -- remove side
                if (song.tracks[master_offset].devices[last_offset - 1].display_name == devicename) then
                    song:track(master_offset):delete_device_at(last_offset - 1)
                end
            end
        end
    }


    -- side check
    renoise.tool():add_keybinding {
        name = "Global:Tools:Side check", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end

            local devicename = "Mono Check"; 
            local devicename2 = "Side Check"; 
            local master_offset = song.sequencer_track_count + 1
            local last_offset = #renoise.song():track(master_offset).devices + 1

            -- insert new device
            if (song.tracks[master_offset].devices[last_offset - 1].display_name ~= devicename and song.tracks[master_offset].devices[last_offset - 1].display_name ~= devicename2) then 
                song:track(master_offset):insert_device_at('Audio/Effects/Native/Stereo Expander', last_offset) 
                local device = song.tracks[master_offset].devices[last_offset]
                device.display_name = devicename
                device.is_maximized = false
                device.parameters[1].value = 0
                device.parameters[2].value = 1
                --for index, val in pairs(device.parameters) do
                --  oprint(val.name)
                --end

                devicename = "Side Check"; 
                master_offset = song.sequencer_track_count + 1
                last_offset = #renoise.song():track(master_offset).devices
                -- insert new device
                if (song.tracks[master_offset].devices[last_offset - 1].display_name ~= devicename) then 
                    song:track(master_offset):insert_device_at('Audio/Effects/Native/Gainer', last_offset) 
                    local device = song.tracks[master_offset].devices[last_offset]
                    device.display_name = devicename
                    device.is_maximized = false
                    device.active_preset_data = '<?xml version="1.0" encoding="UTF-8"?><FilterDevicePreset doc_version="11"><DeviceSlot type="GainerDevice"><IsMaximized>false</IsMaximized><Volume><Value>1.0</Value></Volume><Panning><Value>0.5</Value></Panning><LPhaseInvert>false</LPhaseInvert><RPhaseInvert>true</RPhaseInvert><SmoothParameterChanges>true</SmoothParameterChanges></DeviceSlot></FilterDevicePreset>'
                    
                    -- using stereo expander (seems to be buggy)
                    --song:track(master_offset):insert_device_at('Audio/Effects/Native/Stereo Expander', last_offset)  
                    --local device = song.tracks[master_offset].devices[last_offset]
                    --device.display_name = devicename
                    --device.is_maximized = false
                    --device.parameters[1].value = 0.5
                    --device.parameters[2].value = 1
                    
                    --for index, val in pairs(device.parameters) do
                    --  oprint(val.name)
                    --end
                    
                    -- remove device
                else
                    song:track(master_offset):delete_device_at(last_offset - 1) 
                end
                

                -- remove device
            else
                song:track(master_offset):delete_device_at(last_offset - 1) 
                devicename = "Side Check"; 
                master_offset = song.sequencer_track_count + 1
                last_offset = #renoise.song():track(master_offset).devices + 1
                -- remove side
                if (song.tracks[master_offset].devices[last_offset - 1].display_name == devicename) then
                    song:track(master_offset):delete_device_at(last_offset - 1)
                end
            end

        end
    }


    -- Unmute/mute + all subtracks (for mute mode in options)
    local keyfunc_mute1 = function()
        local s = renoise.song()
        local selTrack = s.tracks[s.selected_track_index]
        local targetState

        if (selTrack.mute_state == renoise.Track.MUTE_STATE_ACTIVE) then
            targetState = renoise.Track.MUTE_STATE_OFF
        else
            targetState = renoise.Track.MUTE_STATE_ACTIVE
        end

        if (selTrack.type == renoise.Track.TRACK_TYPE_GROUP) then
            selTrack.mute_state = targetState

            for trackNum in ipairs(selTrack.members) do
                local track = s.tracks[trackNum]
                track.mute_state = targetState
            end
        elseif (selTrack.type == renoise.Track.TRACK_TYPE_SEQUENCER or selTrack.type == renoise.Track.TRACK_TYPE_SEND) then
            selTrack.mute_state = targetState
        end

    end

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Track:Unmute/mute group/track and children", 
        invoke = keyfunc_mute1
    }
    renoise.tool():add_keybinding {
        name = "Mixer:Track Control:Unmute/mute group/track and children", 
        invoke = keyfunc_mute1
    }

    -- Unsolo/solo track + all subtracks  (for solo mode in options)
    local keyfunc_mute2 = function()
        local s = renoise.song()
        local selTrack = s.tracks[s.selected_track_index]
        local targetState

        if (selTrack.solo_state == true) then
            targetState = false
        else
            targetState = true
        end

        if (selTrack.type == renoise.Track.TRACK_TYPE_GROUP) then
            selTrack.solo_state = targetState

            for trackNum in ipairs(selTrack.members) do
                local track = s.tracks[trackNum]
                track.solo_state = targetState
            end
        elseif (selTrack.type == renoise.Track.TRACK_TYPE_SEQUENCER or selTrack.type == renoise.Track.TRACK_TYPE_SEND) then
            selTrack.solo_state = targetState
        end

    end

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Track:Unsolo/solo group/track and children", 
        invoke = keyfunc_mute2
    }
    renoise.tool():add_keybinding {
        name = "Mixer:Track Control:Unsolo/solo group/track and children", 
        invoke = keyfunc_mute2
    }

    -- Unsolo all tracks
    local keyfunc_mute3 = function()
        local s = renoise.song()
        for i = 1, #s.tracks do
            s.tracks[i].solo_state = false
        end

    end

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Track:Unsolo all tracks", 
        invoke = keyfunc_mute3
    }
    renoise.tool():add_keybinding {
        name = "Mixer:Track Control:Unsolo all tracks", 
        invoke = keyfunc_mute3
    }


    -- Unsolo/solo track + all subtracks  (for solo mode in options)
    local keyfunc_mute4 = function()
        local s = renoise.song()
        local selTrack = s.tracks[s.selected_track_index]
        local targetState

        if (selTrack.solo_state == true) then
            local s = renoise.song()
            for i = 1, #s.tracks do
                s.tracks[i].solo_state = false
            end

        else
            targetState = true
            if (selTrack.type == renoise.Track.TRACK_TYPE_GROUP) then
                selTrack.solo_state = targetState

                for trackNum in ipairs(selTrack.members) do
                    local track = s.tracks[trackNum]
                    track.solo_state = targetState
                end
            elseif (selTrack.type == renoise.Track.TRACK_TYPE_SEQUENCER or selTrack.type == renoise.Track.TRACK_TYPE_SEND) then
                selTrack.solo_state = targetState
            end
        end


    end


    renoise.tool():add_keybinding {
        name = "Pattern Editor:Track:Solo group,track and children/Unsolo all tracks", 
        invoke = keyfunc_mute4
    }
    renoise.tool():add_keybinding {
        name = "Mixer:Track Control:Solo group,track and children/Unsolo all tracks", 
        invoke = keyfunc_mute4
    }


end


function TunedShortcuts:__init()
    -- transport playing
    local isPlayingFunc = function()
    end
    local isEditingFunc = function()
    end

    -- new doc 
    local newDocFunc = function() 
        -- song playing
        if (not renoise.song().transport.playing_observable:has_notifier(isPlayingFunc)) then
            renoise.song().transport.playing_observable:add_notifier(isPlayingFunc)
        end
        if (not renoise.song().transport.edit_mode_observable:has_notifier(isEditingFunc)) then
            renoise.song().transport.edit_mode_observable:add_notifier(isEditingFunc)
        end

    end

    if (not renoise.tool().app_new_document_observable:has_notifier(newDocFunc)) then
        --renoise.tool().app_new_document_observable:add_notifier(newDocFunc)
        --rns = renoise.song()
        --playpos = xPlayPos()
        renoise.tool().app_idle_observable:add_notifier(function()
            --self:updatePlayPos()
            
            -- xLib
            --playpos:update()
        end)
    end
end


--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

tsInst = TunedShortcuts()
tsInst:register_keys()


