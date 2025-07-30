--------------------------------------------------------------------------------
-- Unified Value Shift And Transpose
-- by ffx a.k.a. J. Raben
-- v1.0
--------------------------------------------------------------------------------

class "UnifiedValueShiftAndTranspose"

UnifiedValueShiftAndTranspose.shiftOptions = nil
UnifiedValueShiftAndTranspose.statusDelay = 1


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function UnifiedValueShiftAndTranspose:clearStatusFunc()
    if (self.statusTimerFunc ~= nil and renoise.tool():has_timer(self.statusTimerFunc)) then
        renoise.tool():remove_timer(self.statusTimerFunc)
        self.statusTimerFunc = nil
    end
end 

function UnifiedValueShiftAndTranspose:showStatusDelayed(message)
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


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function UnifiedValueShiftAndTranspose:register_keys()


    --  transpose by inversion
    local inversion_transpose = function(is_direction_up)
        local song = renoise.song()
        if (song == nil) then return end
        local sli = song.selected_line_index
        local sei = song.selected_effect_column_index
        local spi = song.selected_pattern_index
        local sct = song.selected_sub_column_type

        -- cursor selection
        local line_start = sli
        local line_end = line_start
        local sci_start = song.selected_note_column_index
        local sci_end = sci_start
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
        local nv, line
        
        for line_num = line_start, line_end, 1 do
            local resultTable = {}
            for sti = sti_start, sti_end, 1 do
                local cur_track = song:pattern(spi):track(sti)
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
                        -- check for note existence
                        
                        -- TODO: make multitrack compatible by adding track number to table and do for ech track indiv. transpose
                        if (nv < 120) then
                            table.insert(resultTable, {nv = nv, col = sci, tr = cur_track, line = line})
                            note_num = note_num + 1
                        end
                        
                    end
                    
                    
                end
                if (is_direction_up) then
                    table.sort(resultTable, function(a, b) return a.nv < b.nv end)
                else
                    table.sort(resultTable, function(a, b) return a.nv > b.nv end)
                end
                
                for index, targetNote in pairs(resultTable) do
                    --local targetNote = resultTable[1]
                    if (is_direction_up and targetNote.nv < 108) then
                        targetNote.line:note_column(targetNote.col).note_value = targetNote.nv + 12
                    elseif (not is_direction_up and targetNote.nv > 11) then
                        targetNote.line:note_column(targetNote.col).note_value = targetNote.nv - 12
                    end
                    break
                end
                
            end
        end
        
    end

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Transpose up by inversion", 
        invoke = function()
            inversion_transpose(true)
            self:showStatusDelayed("Transpose up by inversion")
        end
    } 

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Transpose down by inversion", 
        invoke = function()
            inversion_transpose(false)
            self:showStatusDelayed("Transpose down by inversion")
        end
    } 



    -- note occurrencies
    local NOTEOCC_OPS = {
        UP = {}, 
        DOWN = {}, 
        DELETE = {}, 
    SET_OFF = {}}

    local op_on_note_occurrencies = function(op)
        local song = renoise.song()
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
        local nv, line
        
        local cur_track = song:pattern(spi):track(sti_start)
        local initial_nv = cur_track:line(sli):note_column(song.selected_note_column_index).note_value
        
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
                        -- check for note existence
                        
                        -- TODO: fix for octave blocking
                        if (initial_nv ~= 120 and nv % 12 == initial_nv % 12 or initial_nv == 120 and nv == 120) then
                            table.insert(resultTable, {nv = nv, col = sci, tr = cur_track, line = line})
                            note_num = note_num + 1
                        end
                        
                    end
                    
                    
                end
                
                for index, targetNote in pairs(resultTable) do
                    if (op == NOTEOCC_OPS.UP and targetNote.nv < 119) then
                        targetNote.line:note_column(targetNote.col).note_value = targetNote.nv + 1
                    elseif (op == NOTEOCC_OPS.DOWN and targetNote.nv > 0 and targetNote.nv < 120) then
                        targetNote.line:note_column(targetNote.col).note_value = targetNote.nv - 1
                    elseif (op == NOTEOCC_OPS.DELETE and targetNote.nv > 0 and targetNote.nv < 121) then
                        targetNote.line:note_column(targetNote.col):clear()
                    elseif (op == NOTEOCC_OPS.SET_OFF and targetNote.nv > 0 and targetNote.nv < 120) then
                        targetNote.line:note_column(targetNote.col).note_value = 120
                    end
                end
                
            end
        end
    end

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Transpose Note Occurrences +1", 
        invoke = function()
            op_on_note_occurrencies(NOTEOCC_OPS.UP)
            self:showStatusDelayed("Transpose Note Occurrences +1")
        end
    } 

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Transpose Note Occurrences -1", 
        invoke = function()
            op_on_note_occurrencies(NOTEOCC_OPS.DOWN)
            self:showStatusDelayed("Transpose Note Occurrences -1")
        end
    } 


    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Delete Note Occurrences", 
        invoke = function()
            op_on_note_occurrencies(NOTEOCC_OPS.DELETE)
            self:showStatusDelayed("Delete Note Occurrences")
        end 
    }

    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Set Note Occurrences to OFF", 
        invoke = function()
            op_on_note_occurrencies(NOTEOCC_OPS.SET_OFF)
            self:showStatusDelayed("Set Note Occurrences to OFF")
        end 
    }


    -- decrease/  increase value functions
    local OPTION_ONLY_NOTE_OFF = 1
    local universal_increase = function(add_value, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom, song)
        local options = self.shiftOptions
        local song = renoise.song()
        if (song == nil) then return end
        local sli = song.selected_line_index
        local sei = song.selected_effect_column_index
        local spi = song.selected_pattern_index
        local sct = song.selected_sub_column_type

        local x
        local t_sli
        local sel_offset_top = 0
        local sel_offset_bottom = 0
        for sti = sti_start, sti_end, 1 do
            local cur_track = song:pattern(spi):track(sti)
            if (song:track(sti).type == renoise.Track.TRACK_TYPE_SEQUENCER) then
                for sci = sci_start, sci_end, 1 do
                    for line_num = line_end, line_start, -1 do
                        -- check for stepwidth
                        if ((line_num - 1 - (line_start - 1)) % (step_width) == 0) then
                            x = 0
                            t_sli = 0
                            local line = cur_track:line(line_num)
                            if (sci ~= nil and sct == renoise.Song.SUB_COLUMN_NOTE) then
                                local nv = line:note_column(sci).note_value
                                -- check for note existence
                                if (nv < 120) then
                                    line:note_column(sci).note_value = math.min(nv + 1, 120)
                                end
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_INSTRUMENT) then
                                local nv = line:note_column(sci).note_value
                                -- check for note existence
                                if (line:note_column(sci).instrument_value ~= 255) then
                                    line:note_column(sci).instrument_value = math.min(line:note_column(sci).instrument_value + 1, 254)
                                end
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_VOLUME) then
                                -- check for volume existence
                                local nv = line:note_column(sci).note_value
                                local t_val = line:note_column(sci).volume_value
                                if (nv < 120) then
                                    if (t_val == 255) then
                                        line:note_column(sci).volume_value = 127
                                    else
                                        line:note_column(sci).volume_value = math.min(t_val + add_value, 127)
                                    end
                                end
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_PANNING) then
                                -- check for pan existence
                                local nv = line:note_column(sci).note_value
                                local t_val = line:note_column(sci).panning_value
                                if (nv < 120) then
                                    if (t_val == 255) then
                                        line:note_column(sci).panning_value = 64
                                    else
                                        line:note_column(sci).panning_value = math.min(t_val + add_value, 127)
                                    end
                                end
                                -- increase delay, but only if there is a volume or an instrument value or a note-off
                            elseif (sct == renoise.Song.SUB_COLUMN_DELAY and sci ~= nil and line:note_column(sci) and (line:note_column(sci).volume_value ~= 255 or line:note_column(sci).instrument_value ~= 255 or line:note_column(sci).note_value == 120)) then -- 
                                local val = line:note_column(sci).delay_value


                                -- only note-off
                                if (not (options == OPTION_ONLY_NOTE_OFF and line:note_column(sci).note_value ~= 120)) then
                                    
                                    -- check if note needs to be moved
                                    if (val >= (val + add_value) % 256) then -- and line.note_columns[sci].note_value ~= 121
                                        -- move cursor if no selection mode
                                        if (song.selection_in_pattern == nil) then
                                            move_sel_offset_top = true
                                            --sel_offset_top = 1
                                            -- move cursor if selection mode and first line moves
                                        elseif (line_num == line_end) then -- and line.note_columns[sci].note_value ~= 121
                                            move_sel_offset_bottom = true
                                            sel_offset_bottom = 1
                                        end
                                        
                                        x = sci
                                        t_sli = 0
                                        -- check pattern boundaries
                                        if (line_num == song.selected_pattern.number_of_lines) then
                                            t_sli = 1
                                        else
                                            t_sli = line_num + 1
                                        end
                                        
                                        -- check for any midi commands
                                        local midi_exists = false
                                        --for col_num = sci_start,sci_end,1 do
                                        for col_num = 1, #line.note_columns, 1 do
                                            if (line:note_column(col_num).panning_value > 127 and line:note_column(col_num).panning_value ~= 255) then
                                                midi_exists = true
                                                break
                                            end
                                        end
                                        
                                        -- copy note
                                        local t_line = song:pattern(spi):track(sti):line(t_sli)
                                        -- only move if there is no note in the way, lame workaround to prevent note column creation
                                        -- TODO: note column creation
                                        if (t_line:note_column(x).note_value == 121) then 
                                            t_line:note_column(x):copy_from(line:note_column(x))
                                            t_line:note_column(x).delay_value = (val + add_value) % 256
                                            -- copy fx columns, only if there is a fx value in current note column
                                            -- FIXME: also move normal fx
                                            if (sei ~= nil and(line:note_column(sci).effect_number_value > 0 or line:note_column(sci).effect_amount_value)) then
                                                for fx_line_num = 1, #line.effect_columns, 1 do
                                                    if (line:effect_column(fx_line_num)
                                                        -- only if there is a panning fx command
                                                        and ((line:effect_column(fx_line_num).number_value > 0 and line:note_column(sci).panning_value > 127 and line:note_column(sci).panning_value ~= 255)
                                                            -- only if source has a value
                                                        or (line:effect_column(fx_line_num).number_value > 0 and not midi_exists))) then
                                                        t_line:effect_column(fx_line_num):copy_from(line:effect_column(fx_line_num))
                                                        line:effect_column(fx_line_num):clear()
                                                    end
                                                end
                                            end
                                            line:note_column(x):clear()
                                            -- if not moved because of other note, at least write delay FF
                                        else
                                            line:note_column(x).delay_value = 255
                                        end
                                        
                                        -- repos selection
                                        if (line_num == line_start) then
                                            sel_offset_top = 1
                                        end
                                        if (line_num == line_end) then
                                            sel_offset_bottom = 1
                                        end
                                        
                                        
                                        
                                        --song.selected_line_index = t_sli
                                    else -- if (line.note_columns[sci].note_value ~= 121) then
                                        line:note_column(sci).delay_value = (val + add_value) % 256
                                    end
                                    
                                end -- note-off option

                                -- increase fx
                                -- FIXME: Needs to be improved, differentiation of fx columns!
                            elseif (sei ~= nil and sei > 0 and line:note_column(sci) and line:effect_column(sei) and (line:note_column(sci).instrument_value ~= 255) and (line:note_column(sci).panning_value > 127 and line:note_column(sci).panning_value ~= 255)) then
                                line:effect_column(sei).amount_value = math.min(line:effect_column(sei).amount_value + add_value, 255)
                            end
                        end
                    end
                    -- repos selection, check for empty lines
                    -- FIXME currently only fixes one line which is not nice in cosmetical way
                    for line_num = line_start, line_end, 1 do
                        local line = song:pattern(spi):track(sti):line(line_num)
                        -- repos selection start, only if there is no data at all
                        if (sci ~= nil and sct == renoise.Song.SUB_COLUMN_DELAY and line:note_column(sci) and (line:note_column(sci).volume_value == 255 and line:note_column(sci).instrument_value == 255 and line:note_column(sci).note_value == 121)) then
                            --local val = line.note_columns[sci].delay_value
                            --if (val >= (val+add_value)%256) then
                            -- repos selection
                            --if (move_sel_offset_top and line_num == line_start) then
                            --sel_offset_top = -1
                            --end
                            -- check last line entries all have delay 0
                            if (move_sel_offset_top and line_num == line_start and sci == sci_end and sti == sti_end) then
                                sel_offset_top = 1
                                break
                            end
                            --end
                        end
                    end
                end
            end
        end

        return move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom

    end


    local universal_decrease = function(add_value, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom, song)
        local options = self.shiftOptions
        local song = renoise.song()
        if (song == nil) then return end
        local sli = song.selected_line_index
        local sei = song.selected_effect_column_index
        local spi = song.selected_pattern_index
        local sct = song.selected_sub_column_type

        local t_sli
        local x
        local sel_offset_top = 0
        local sel_offset_bottom = 0
        for sti = sti_start, sti_end, 1 do
            local cur_track = song:pattern(spi):track(sti)
            if (song:track(sti).type == renoise.Track.TRACK_TYPE_SEQUENCER) then
                for sci = sci_start, sci_end, 1 do
                    for line_num = line_start, line_end, 1 do
                        -- check for stepwidth
                        if ((line_num - 1 - (line_start - 1)) % (step_width) == 0) then
                            x = 0
                            t_sli = 0
                            local line = cur_track:line(line_num)

                            if (sci ~= nil and sct == renoise.Song.SUB_COLUMN_NOTE) then
                                local nv = line:note_column(sci).note_value
                                -- check for note existence
                                if (nv < 120) then
                                    line:note_column(sci).note_value = math.max(nv - 1, 0)
                                end
                                -- decrease instr num
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_INSTRUMENT) then
                                local nv = line:note_column(sci).note_value
                                -- check for note existence
                                if (line:note_column(sci).instrument_value ~= 255) then
                                    line:note_column(sci).instrument_value = math.max(line:note_column(sci).instrument_value - 1, 0)
                                end
                                -- decrease vol
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_VOLUME) then
                                -- check for volume existence
                                local nv = line:note_column(sci).note_value
                                local t_val = line:note_column(sci).volume_value
                                if (nv < 120) then
                                    if (t_val == 255) then
                                        line:note_column(sci).volume_value = 126
                                    else
                                        line:note_column(sci).volume_value = math.max(t_val + add_value, 0)
                                    end
                                end
                                -- decrease pan
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_PANNING) then
                                -- check for pan existence
                                local nv = line:note_column(sci).note_value
                                local t_val = line:note_column(sci).panning_value
                                if (nv < 120) then
                                    if (t_val == 255) then
                                        line:note_column(sci).panning_value = 63
                                    else
                                        line:note_column(sci).panning_value = math.max(t_val + add_value, 0)
                                    end
                                end
                                -- decrease delay, but only if there is a volume or an instrument value or a note-off
                            elseif (sci ~= nil and sct == renoise.Song.SUB_COLUMN_DELAY and line:note_column(sci) and (line:note_column(sci).volume_value ~= 255 or line:note_column(sci).instrument_value ~= 255 or line:note_column(sci).note_value == 120)) then


                                -- only note-off
                                if (not (options == OPTION_ONLY_NOTE_OFF and line:note_column(sci).note_value ~= 120)) then

                                    local val = line:note_column(sci).delay_value
                                    -- check if note needs to be moved
                                    if (val >= (val + add_value) % 256) then
                                        -- check last line entries all have delay 0
                                        if (line_num == line_end) then
                                            move_sel_offset_bottom = false
                                        end
                                    end
                                    -- check if note needs to be moved
                                    if (val < (val + add_value) % 256) then
                                        -- move cursor if no selection mode
                                        if (song.selection_in_pattern == nil) then
                                            move_sel_offset_bottom = true
                                            -- move cursor if selection mode and first line moves
                                        elseif (line_num == line_start) then -- and line.note_columns[sci].note_value ~= 121
                                            move_sel_offset_top = true
                                            sel_offset_top = -1
                                        end
                                        x = sci
                                        t_sli = 0
                                        -- check pattern boundaries
                                        if (line_num == 1) then
                                            t_sli = song.selected_pattern.number_of_lines
                                        else
                                            t_sli = line_num - 1
                                        end
                                        
                                        -- check for any midi commands
                                        local midi_exists = false
                                        for col_num = 1, #line.note_columns, 1 do
                                            if (line:note_column(col_num).panning_value > 127 and line:note_column(col_num).panning_value ~= 255) then
                                                midi_exists = true
                                                break
                                            end
                                        end
                                        
                                        
                                        -- copy note
                                        local t_line = song:pattern(spi):track(sti):line(t_sli)
                                        -- only move if there is no note in the way, lame workaround to prevent note column creation
                                        -- TODO: note column creation
                                        if (t_line:note_column(x).note_value == 121) then 
                                            t_line:note_column(x):copy_from(line:note_column(x))
                                            t_line:note_column(x).delay_value = (val + add_value) % 256
                                            -- copy fx columns, only if there is a fx value in current note column
                                            -- FIXME: also move normal fx
                                            if (sei ~= nil and(line:note_column(sci).effect_number_value > 0 or line:note_column(sci).effect_amount_value)) then
                                                for fx_line_num = 1, #line.effect_columns, 1 do
                                                    if (line:effect_column(fx_line_num)
                                                        -- only if there is a panning fx command
                                                        and ((line:effect_column(fx_line_num).number_value > 0 and line:note_column(sci).panning_value > 127 and line:note_column(sci).panning_value ~= 255)
                                                            -- only if source has a value
                                                        or (line:effect_column(fx_line_num).number_value > 0 and not midi_exists))) then
                                                        t_line:effect_column(fx_line_num):copy_from(line:effect_column(fx_line_num))
                                                        line:effect_column(fx_line_num):clear()
                                                    end
                                                end
                                            end
                                            line.note_columns[x]:clear()
                                            -- if not moved because of other note, at least write delay 00
                                        else
                                            line:note_column(x).delay_value = 00
                                        end
                                        
                                    else --if (line.note_columns[sci].note_value ~= 121) then
                                        line:note_column(sci).delay_value = (val + add_value) % 256
                                    end
                                    
                                end -- note-off option
                                
                                -- decrease fx
                                -- FIXME: Needs to be improved, differentiation of fx columns!
                            elseif (sei ~= nil and sei > 0 and line:note_column(sci) and line:effect_column(sei) and (line:note_column(sci).instrument_value ~= 255) and (line:note_column(sci).panning_value > 127 and line:note_column(sci).panning_value ~= 255)) then
                                line:effect_column(sei).amount_value = math.max(line:effect_column(sei).amount_value + add_value, 0)
                            end
                        end
                    end
                    -- repos selection, check for empty lines
                    -- FIXME currently only fixes one line which is not nice in cosmetical way
                    for line_num = line_end, line_start, -1 do
                        local line = song:pattern(spi):track(sti):line(line_num)
                        -- repos selection end, only if there is no data at all
                        if (sci ~= nil and sct == renoise.Song.SUB_COLUMN_DELAY and line:note_column(sci) and (line:note_column(sci).volume_value == 255 and line:note_column(sci).instrument_value == 255 and line:note_column(sci).note_value == 121)) then
                            --if (sci ~= nil and sct == renoise.Song.SUB_COLUMN_DELAY) then
                            -- local val = line.note_columns[sci].delay_value
                            --if (val == 0) then
                            -- repos selection
                            --if (move_sel_offset_top and line_num == line_start) then
                            --sel_offset_top = -1
                            --end
                            -- check last line entries all have delay 0
                            if (move_sel_offset_bottom and line_num == line_end and sci == sci_end and sti == sti_end) then
                                sel_offset_bottom = -1
                                break
                            end
                            -- end
                        end
                    end
                end
            end
        end
        return move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom

    end





    --set shift option only note-off movement
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Toggle Only Note-Off", 
        invoke = function()
            if (self.shiftOptions == nil) then
                self.shiftOptions = OPTION_ONLY_NOTE_OFF 
                self:showStatusDelayed("Set Shift-Option to Note-Off only.")
            else
                self.shiftOptions = nil
                self:showStatusDelayed("Removed Shift-Option Note-Off only.")
            end
        end 
    }





    --  increase value
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Increase value under cursor by 1", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = 1
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_increase(1, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)


            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli + 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end


        end
    }

    -- decrease value
    -- FIXME: start selection move up buggy?
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Decrease value under cursor by 1", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = 1
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_decrease(-1, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)

            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli - 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end

        end
    }

    --  increase value by custom amount
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Increase value under cursor by 128", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = 1
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_increase(128, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)


            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli + 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end


        end
    }

    -- decrease value by custom amount
    -- FIXME: start selection move up buggy?
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Decrease value under cursor by 128", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = 1
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_decrease(-128, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)

            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli - 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end

        end
    }


    --  increase value w/ shuffle
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Increase value under cursor by 1 w/ shuffle", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = song.transport.edit_step
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_increase(1, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)


            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli + 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end


        end
    }


    -- decrease value w/ shuffle
    -- FIXME: start selection move up buggy?
    renoise.tool():add_keybinding {
        name = "Pattern Editor:Tools:Decrease value under cursor by 1 w/ shuffle", 
        invoke = function()
            local song = renoise.song()
            if (song == nil) then return end
            local sli = song.selected_line_index
            local sei = song.selected_effect_column_index
            local spi = song.selected_pattern_index
            local sct = song.selected_sub_column_type

            -- cursor selection
            local line_start = sli
            local line_end = line_start
            local sci_start = song.selected_note_column_index
            local sci_end = sci_start
            local sti_start = song.selected_track_index
            local sti_end = sti_start
            local move_sel_offset_bottom = false
            local move_sel_offset_top = false

            -- check for multiple line selection
            if (song.selection_in_pattern ~= nil) then
                move_sel_offset_bottom = true
                line_start = song.selection_in_pattern.start_line
                line_end = song.selection_in_pattern.end_line
                sci_start = song.selection_in_pattern.start_column
                sci_end = song.selection_in_pattern.end_column
                sti_start = song.selection_in_pattern.start_track
                sti_end = song.selection_in_pattern.end_track
            end

            -- stepwidth for shuffle etc.
            local step_width = song.transport.edit_step
            local sel_offset_top
            local sel_offset_bottom

            move_sel_offset_top, move_sel_offset_bottom, sel_offset_top, sel_offset_bottom = universal_decrease(-1, step_width, line_start, line_end, sci_start, sci_end, sti_start, sti_end, move_sel_offset_top, move_sel_offset_bottom)

            if (move_sel_offset_bottom or move_sel_offset_top) then
                -- fix cursor for no selection mode
                if (song.selection_in_pattern == nil) then
                    song.selected_line_index = math.max(1, sli - 1)
                end
                -- fix selection
                if (song.selection_in_pattern ~= nil) then
                    song.selection_in_pattern = {
                        start_line = math.max(1, song.selection_in_pattern.start_line + sel_offset_top), end_line = math.max(1, math.min(song.selected_pattern.number_of_lines, song.selection_in_pattern.end_line + sel_offset_bottom)), start_track = song.selection_in_pattern.start_track, end_track = song.selection_in_pattern.end_track, start_column = song.selection_in_pattern.start_column, end_column = song.selection_in_pattern.end_column
                    }
                end

            end

        end
    }
end


function UnifiedValueShiftAndTranspose:__init()
end


--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

vsInst = UnifiedValueShiftAndTranspose()
vsInst:register_keys()





