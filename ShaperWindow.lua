class "ShaperWindow"


----------------------------------------------------------------------------------------------------


function ShaperWindow:__init (shaper)

    self.shaper = shaper
    self.vb = renoise.ViewBuilder ()

    self.shapes = { "1_off", "2_off", "3_off", "4_off" }

    renoise.tool():add_menu_entry {
        name = "Main Menu:Tools:Automasher...",
        invoke = function () self:show_dialog () end
    }

    renoise.tool():add_menu_entry {
        name = "Track Automation:Automasher...",
        invoke = function () self:show_dialog () end
    }

    renoise.tool():add_keybinding {
        name = "Global:Tools:Automasher...",
        invoke = function () self:show_dialog () end
    }

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:show_dialog ()

    if self.dialog and self.dialog.visible then
        self.dialog:show ()
        return
    end

    if not self.dialog_content then
        self.dialog_content = self:gui ()
    end

    local kh = function (d, k) return self:key_handler (d, k) end
    self.dialog = renoise.app():show_custom_dialog ("Automation Shaper", self.dialog_content, kh)

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:key_handler (dialog, key)

    local p = renoise.song().selected_pattern_index
    local t = renoise.song().selected_track_index
    local l = renoise.song().selected_line_index
    local nl = renoise.song().patterns[p].number_of_lines

    -- close on escape...
    if key.modifiers == "" and key.name == "esc" then
        dialog:close()


    elseif key.name == "up" then
        local s = renoise.song().selected_sequence_index
        if l > 1 then
            l = l - 1
        elseif s > 1 then
            s = s - 1
            renoise.song().selected_sequence_index = s
            l = renoise.song().selected_pattern.number_of_lines
        end
        renoise.song().selected_line_index = l

    elseif key.name == "down" then
        if l + 1 <= nl then
            l = l + 1
        else
            local s = renoise.song().selected_sequence_index
            s = s + 1
            if renoise.song().sequencer.pattern_sequence[s] then
                renoise.song().selected_sequence_index = s
                l = 1
            end
        end
        renoise.song().selected_line_index = l

    elseif key.name == "space" then
        if renoise.song().transport.playing then
            renoise.song().transport:stop()
        else
            renoise.song().transport:start_at(1)
        end

    else
        return key

    end

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:on_shape_selected (part, id)

        self.vb.views[self.shapes[part]].bitmap = "Icons/" .. string.sub (self.shapes[part], 3) .. ".png"

        self.vb.views[id].bitmap = "Icons/" .. string.sub (id, 3) .. "_selected.png"
        self.shapes[part] = id

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:auto_update ()

    if self.vb.views.auto_update.value then
        self:on_write_pressed ()
    end

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:on_write_pressed ()

    if renoise.app().window.active_lower_frame ~= renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION then
        renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
    end

    local nb_shapes = self.vb.views.number_of_shapes.value

    local phase = self.vb.views.phase.value
    local resolution = 1 / self.vb.views.resolution.value

    local origin = self.vb.views.origin.value
    local origin_dest = self.vb.views.origin_dest.value
    local origin_mode = self.vb.views.step_origin.value

    local peak = self.vb.views.peak.value
    local peak_mode = self.vb.views.step_peak.value
    local peak_dest = self.vb.views.peak_dest.value

    local alt_peak = self.vb.views.alt_peak.value
    local alt_peak_mode = self.vb.views.step_alt_peak.value
    local alt_peak_dest = self.vb.views.alt_peak_dest.value

    local attack = self.vb.views.attack.value
    local attack_mode = self.vb.views.attack_mode.value
    local release = self.vb.views.release.value
    if self.shapes[1] == "1_off" then
        attack = release
    end

    local shapes = {}
    if self.shapes[1] ~= "1_off" then
        shapes[#shapes + 1] = string.sub (self.shapes[1], 3)
    end
    if self.shapes[2] ~= "2_off" then
        shapes[#shapes + 1] = string.sub (self.shapes[2], 3)
    end

    local alt_shapes = {}
    if self.vb.views.mode.value == 2 and self.shapes[3] ~= "3_off" then
        alt_shapes[#alt_shapes + 1] = string.sub (self.shapes[3], 3)
    end
    if self.vb.views.mode.value == 2 and self.shapes[4] ~= "4_off" then
        alt_shapes[#alt_shapes + 1] = string.sub (self.shapes[4], 3)
    end

    if not shapes[1] then
        if not alt_shapes[1] then
            return
        else
            shapes = alt_shapes
        end
    end

    if not alt_shapes[1] then
        alt_shapes = shapes
    end

    local track_index = renoise.song().selected_track_index
    local parameter = renoise.song().selected_parameter
    if not parameter then
        renoise.app():show_status ("Shaper Error: No parameter selected")
        return
    end

    local sequence_index
    local start_line
    local length
    if self.vb.views.selection_mode.value == 1 then

        sequence_index = renoise.song().selected_sequence_index
        start_line = renoise.song().selected_line_index
        length = self.vb.views.length.value

    elseif self.vb.views.selection_mode.value == 2 then

        sequence_index = renoise.song().selected_sequence_index
        local s = sequence_index
        start_line = 1
        length = 0
        local p
        for i = 1, self.vb.views.patterns.value do
            if s <= #renoise.song().sequencer.pattern_sequence then
                p = renoise.song().sequencer:pattern (s)
                length = length + renoise.song().patterns[p].number_of_lines
                s = s + 1
            end
        end

    elseif self.vb.views.selection_mode.value == 3 then

        sequence_index = 1
        local s = sequence_index
        start_line = 1
        length = 0
        local p
        for i = 1, #renoise.song().sequencer.pattern_sequence do
            p = renoise.song().sequencer:pattern (s)
            length = length + renoise.song().patterns[p].number_of_lines
            s = s + 1
        end

    end

    local offset = self.vb.views.offset.value
    if self.vb.views.mode.value < 3 then
        start_line = start_line + offset
        if start_line < 1 then
            if sequence_index > 1 then
                sequence_index = sequence_index - 1
                local pattern_index = renoise.song().sequencer:pattern (sequence_index)
                if pattern_index then
                    -- It should be ok, since offset can only be negative here
                    offset = 1 + offset
                    start_line = renoise.song().patterns[pattern_index].number_of_lines + offset
                else
                    start_line = 1
                    phase = (phase - offset) % 1
                end
            else
                start_line = 1
                phase = (phase - offset) % 1
            end
        end
    end

    if self.vb.views.mode.value == 1 then
        self.shaper:write_multiple_waves (track_index, parameter, sequence_index, start_line, length, shapes, shapes, nb_shapes, phase, resolution, origin, origin_mode, origin_dest, peak, peak_mode, peak_dest, peak, peak_mode, peak_dest)
    elseif self.vb.views.mode.value == 2 then
        self.shaper:write_multiple_waves (track_index, parameter, sequence_index, start_line, length, shapes, alt_shapes, nb_shapes, phase, resolution, origin, origin_mode, origin_dest, peak, peak_mode, peak_dest, alt_peak, alt_peak_mode, alt_peak_dest)
    elseif self.vb.views.mode.value == 3 then
        self.shaper:write_fixed_waves_on_notes (track_index, parameter, sequence_index, start_line, length, shapes, resolution, attack, attack_mode, release, origin, origin_mode, origin_dest, peak, peak_mode, peak_dest)
    elseif self.vb.views.mode.value == 4 then
        self.shaper:write_scaled_waves_on_notes (track_index, parameter, sequence_index, start_line, length, shapes, resolution, attack, attack_mode, origin, origin_mode, origin_dest, peak, peak_mode, peak_dest)
    end

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:percent_value_tonumber (v)

    local number_part = string.match (v, "%s*%+?%-?%s*%d*%.?%,?%d*")

    local v2 = tonumber(number_part)
    if not v2 then
        return
    end
    v2 = v2 / 100

    if v2 < 0 then
        v2 = 0
    elseif v2 > 1 then
        v2 = 1
    end

    return v2

end


function ShaperWindow:percent_value_tostring (v)

    return string.format("%.3f %%", v * 100)

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:phase_value_tonumber (v)

    local number_part = string.match (v, "%s*%+?%-?%s*%d*%.?%,?%d*")

    local v2 = tonumber(number_part)
    if not v2 then
        return
    end
    v2 = (v2  / 360) % 1

    return v2

end


function ShaperWindow:phase_value_tostring (v)

    return string.format("%.3f °", v * 360)

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:offset_value_tonumber (v)

    local number_part = string.match (v, "%s*%+?%-?%s*%d*%.?%,?%d*")

    local v2 = tonumber(number_part)
    if not v2 then
        return
    end

    if v2 < -1 then
        v2 = -1
    elseif v2 > 1 then
        v2 = 1
    end

    return v2

end


function ShaperWindow:offset_value_tostring (v)

    return string.format("%+.3f", v)

end


----------------------------------------------------------------------------------------------------


function ShaperWindow:gui ()

    local dialog_margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local control_margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

    local vb = self.vb

    local result = vb:column
    {
        style = "body",
        margin = dialog_margin,
        spacing = dialog_spacing,
        uniform = true,



        vb:popup
        {
            id = "mode",
            items =   { "Simple Waves", "Alternating Waves", "Trigger on Note (Constant Length)", "Trigger on Note (Scale with Note Duration)", }, --- "Trigger on Note (Multiple Waves)" },
            notifier = function ()
                local a = self.vb.views.mode.value
                self.vb.views.alt_peak_group.visible = (a == 2)
                self.vb.views.attack_release_group.visible = (a > 2)
                self.vb.views.release_group.visible = (a < 4)
                self.vb.views.attack_mode_group.visible = (a > 2)
                self.vb.views.offset_group.visible = (a < 3)
                self.vb.views.phase_group.visible = (a < 3)
                self.vb.views.number_of_shapes_group.visible = (a < 3)
                --~ self.vb.views.step_origin_group.visible = (a < 3) ---TODO: implement for trigger on notes
                --~ self.vb.views.step_peak_group.visible = (a < 3) ---TODO: implement for trigger on notes
                self:auto_update()
            end
        },

        vb:column
        {
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:horizontal_aligner
            {
                mode = "justify",
                vb:chooser
                {
                    id = "selection_mode",
                    items = { "Start at Cursor", "Whole Pattern(s)", "Whole Song", },
                    notifier = function ()
                        self.vb.views.length_group.visible = (self.vb.views.selection_mode.value == 1)
                        self.vb.views.patterns_group.visible = (self.vb.views.selection_mode.value == 2)
                    end,
                },

                vb:column -- Necessary for jusitfied layout, because "length_group" might be invisible
                {
                    vb:row
                    {
                        id = "length_group",
                        visible = true,
                        vb:text { text = "Length", width = 55, },
                        vb:valuebox { id = "length", value = 1, min = 1, max = 9999, notifier = function () self:auto_update () end, tooltip = "Total length of the curve, in lines" },
                    },


                    vb:row
                    {
                        id = "patterns_group",
                        visible = false,
                        vb:text { text = "Patterns", width = 55, },
                        vb:valuebox { id = "patterns", value = 1, min = 1, max = 9999, notifier = function () self:auto_update () end, tooltip = "Total length of the curve, in lines" },
                    },
                },
            },
        },


        vb:column
        {
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:row
            {
                id = "number_of_shapes_group",
                vb:text { text = "Shapes", width = 70 },
                vb:valuebox { id = "number_of_shapes", value = 1, min = 1, max = 9999, notifier = function () self:auto_update () end, tooltip = "Number of shapes in the curve" },
            },

            vb:horizontal_aligner
            {
                id = "attack_release_group",
                visible = false,
                mode = "justify",

                vb:row
                {
                    vb:text { text = "Attack", width = 70, },
                    vb:valuebox { id = "attack", value = 1, min = 1, notifier = function () self:auto_update () end, },
                },

                vb:row { width = 1 },

                vb:row
                {
                    id = "release_group",
                    vb:text { text = "Release", width = 70, },
                    vb:valuebox { id = "release", value = 1, min = 1, notifier = function () self:auto_update () end, },
                },

            },

            vb:row
            {
                id = "attack_mode_group",
                visible = false,

                vb:row { width = 70 },

                vb:checkbox { id = "attack_mode", notifier = function () self:auto_update () end, },
                vb:text { text = "Attack before notes" },
            },


            vb:row
            {
                id = "offset_group",
                vb:text { text = "Offset", width=70 },
                vb:slider
                {
                    id = "offset_slider",
                    value = 0, min = -1, max = 1,
                    notifier = function (v) self.vb.views.offset.value = v ; self:auto_update()  end,
                    width=150,
                },
                vb:valuefield
                {
                    id = "offset",
                    value = 0, min = -1, max = 1,
                    tonumber = function (v) return self:offset_value_tonumber (v) end,
                    tostring = function (v) return self:offset_value_tostring (v) end,
                    notifier = function (v) self.vb.views.offset_slider.value = v ; self:auto_update()  end,
                },
                tooltip = "Offset the whole curve by a fraction of a line",
            },

            vb:row
            {
                id = "phase_group",
                vb:text { text = "Phase", width=70 },
                vb:slider
                {
                    id = "phase_slider",
                    value = 0, min = 0, max = 1,
                    notifier = function (v) self.vb.views.phase.value = v ; self:auto_update() end,
                    width=150,
                },
                vb:valuefield
                {
                    id = "phase",
                    value = 0, min = 0, max = 1,
                    tonumber = function (v) return self:phase_value_tonumber (v) end,
                    tostring = function (v) return self:phase_value_tostring (v) end,
                    notifier = function (v) self.vb.views.phase_slider.value = v ; self:auto_update() end,
                },
            },


            vb:row
            {
                vb:text { text = "Points / Line", width = 70 },
                vb:valuebox { id = "resolution", value = 8, min = 1, max = 256, notifier = function () self:auto_update () end, tooltip = "Number of automation points per line" },

                vb:row { width = 45 },
            },
        },

        vb:column
        {
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:row
            {
                vb:text { text = "Base", width=70 },
                vb:slider
                {
                    id = "origin_slider",
                    value = 0, min = 0, max = 1,
                    notifier = function (v) self.vb.views.origin.value = v ; self:auto_update() end,
                    width=150,
                },
                vb:valuefield
                {
                    id = "origin",
                    value = 0, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.origin_slider.value = v ; self:auto_update() end,
                },
            },

            vb:row
            {
                id = "step_origin_group",
                vb:popup
                {
                    id = "step_origin",
                    items = { "Constant", "Step to", "Random" },
                    notifier = function ()
                        local a = self.vb.views.step_origin.value > 1
                        self.vb.views.origin_dest_slider.visible = a
                        self.vb.views.origin_dest.visible = a
                        self:auto_update()
                    end,
                    width = 70,
                },
                vb:slider
                {
                    id = "origin_dest_slider",
                    value = 0, min = 0, max = 1,
                    notifier = function (v) self.vb.views.origin_dest.value = v ; self:auto_update() end,
                    width = 150,
                    visible = false,
                },
                vb:valuefield
                {
                    id = "origin_dest",
                    value = 0, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.origin_dest_slider.value = v ; self:auto_update() end,
                    visible = false,
                },
            },

        },

        vb:column
        {
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:row
            {
                vb:text { text = "Peak", width=70 },
                vb:slider
                {
                    id = "peak_slider",
                    value = 1, min = 0, max = 1,
                    notifier = function (v) self.vb.views.peak.value = v ; self:auto_update() end,
                    width=150,
                },
                vb:valuefield
                {
                    id = "peak",
                    value = 1, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.peak_slider.value = v ; self:auto_update() end,
                },
            },

            vb:row
            {
                id = "step_peak_group",
                vb:popup
                {
                    id = "step_peak",
                    items = { "Constant", "Step to", "Random" },
                    notifier = function ()
                        local a = self.vb.views.step_peak.value > 1
                        self.vb.views.peak_dest_slider.visible = a
                        self.vb.views.peak_dest.visible = a
                        self:auto_update()
                    end,
                    width = 70,
                },
                vb:slider
                {
                    id = "peak_dest_slider",
                    value = 1, min = 0, max = 1,
                    notifier = function (v) self.vb.views.peak_dest.value = v ; self:auto_update() end,
                    width = 150,
                    visible = false,
                },
                vb:valuefield
                {
                    id = "peak_dest",
                    value = 1, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.peak_dest_slider.value = v ; self:auto_update() end,
                    visible = false,
                },
            },


            vb:horizontal_aligner
            {
                spacing = 16,
                mode = "distribute",

                vb:column
                {
                    margin = control_margin,
                    spacing = control_spacing,

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "1_off", bitmap = "Icons/off_selected.png", notifier = function () self:on_shape_selected (1, "1_off") ; self:auto_update() end, },
                        vb:bitmap { id = "1_square_up", bitmap = "Icons/square_up.png", notifier = function () self:on_shape_selected (1, "1_square_up") ; self:auto_update() end, },
                        vb:bitmap { id = "1_step_up", bitmap = "Icons/step_up.png", notifier = function () self:on_shape_selected (1, "1_step_up") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "1_convex_sin_up", bitmap = "Icons/convex_sin_up.png", notifier = function () self:on_shape_selected (1, "1_convex_sin_up") ; self:auto_update() end, },
                        vb:bitmap { id = "1_wave_up", bitmap = "Icons/wave_up.png", notifier = function () self:on_shape_selected (1, "1_wave_up") ; self:auto_update() end, },
                        vb:bitmap { id = "1_concave_sin_up", bitmap = "Icons/concave_sin_up.png", notifier = function () self:on_shape_selected (1, "1_concave_sin_up") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "1_convex_up", bitmap = "Icons/convex_up.png", notifier = function () self:on_shape_selected (1, "1_convex_up") ; self:auto_update() end, },
                        vb:bitmap { id = "1_linear_up", bitmap = "Icons/linear_up.png", notifier = function () self:on_shape_selected (1, "1_linear_up") ; self:auto_update() end, },
                        vb:bitmap { id = "1_concave_up", bitmap = "Icons/concave_up.png", notifier = function () self:on_shape_selected (1, "1_concave_up") ; self:auto_update() end, },
                    },

                },


                vb:column
                {
                    margin = control_margin,
                    spacing = control_spacing,

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "2_off", bitmap = "Icons/off_selected.png", notifier = function () self:on_shape_selected (2, "2_off") ; self:auto_update() end, },
                        vb:bitmap { id = "2_square_down", bitmap = "Icons/square_down.png", notifier = function () self:on_shape_selected (2, "2_square_down") ; self:auto_update() end, },
                        vb:bitmap { id = "2_step_down", bitmap = "Icons/step_down.png", notifier = function () self:on_shape_selected (2, "2_step_down") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "2_convex_sin_down", bitmap = "Icons/convex_sin_down.png", notifier = function () self:on_shape_selected (2, "2_convex_sin_down") ; self:auto_update() end, },
                        vb:bitmap { id = "2_wave_down", bitmap = "Icons/wave_down.png", notifier = function () self:on_shape_selected (2, "2_wave_down") ; self:auto_update() end, },
                        vb:bitmap { id = "2_concave_sin_down", bitmap = "Icons/concave_sin_down.png", notifier = function () self:on_shape_selected (2, "2_concave_sin_down") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "2_convex_down", bitmap = "Icons/convex_down.png", notifier = function () self:on_shape_selected (2, "2_convex_down") ; self:auto_update() end, },
                        vb:bitmap { id = "2_linear_down", bitmap = "Icons/linear_down.png", notifier = function () self:on_shape_selected (2, "2_linear_down") ; self:auto_update() end, },
                        vb:bitmap { id = "2_concave_down", bitmap = "Icons/concave_down.png", notifier = function () self:on_shape_selected (2, "2_concave_down") ; self:auto_update() end, },
                    },

                },

            },

        },





        vb:column
        {
            id = "alt_peak_group",
            visible = false,
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:row
            {
                vb:text { text = "Alt. Peak", width = 70 },
                vb:slider
                {
                    id = "alt_peak_slider",
                    value = 1, min = 0, max = 1,
                    notifier = function (v) self.vb.views.alt_peak.value = v ; self:auto_update() end,
                    width=150,
                },
                vb:valuefield
                {
                    id = "alt_peak",
                    value = 1, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.alt_peak_slider.value = v ; self:auto_update() end,
                },
            },

            vb:row
            {
                vb:popup
                {
                    id = "step_alt_peak",
                    items = { "Constant", "Step to", "Random" },
                    notifier = function ()
                        local a = self.vb.views.step_alt_peak.value > 1
                        self.vb.views.alt_peak_dest_slider.visible = a
                        self.vb.views.alt_peak_dest.visible = a
                        self:auto_update()
                    end,
                    width = 70,
                },
                vb:slider
                {
                    id = "alt_peak_dest_slider",
                    value = 1, min = 0, max = 1,
                    notifier = function (v) self.vb.views.alt_peak_dest.value = v ; self:auto_update() end,
                    width=150,
                    visible = false,
                },
                vb:valuefield
                {
                    id = "alt_peak_dest",
                    value = 1, min = 0, max = 1,
                    tonumber = function (v) return self:percent_value_tonumber (v) end,
                    tostring = function (v) return self:percent_value_tostring (v) end,
                    notifier = function (v) self.vb.views.alt_peak_dest_slider.value = v ; self:auto_update() end,
                    visible = false,
                },
            },


            vb:horizontal_aligner
            {
                spacing = 16,
                mode = "distribute",

                vb:column
                {
                    margin = control_margin,
                    spacing = control_spacing,

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "3_off", bitmap = "Icons/off_selected.png", notifier = function () self:on_shape_selected (3, "3_off") ; self:auto_update() end, },
                        vb:bitmap { id = "3_square_up", bitmap = "Icons/square_up.png", notifier = function () self:on_shape_selected (3, "3_square_up") ; self:auto_update() end, },
                        vb:bitmap { id = "3_step_up", bitmap = "Icons/step_up.png", notifier = function () self:on_shape_selected (3, "3_step_up") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "3_convex_sin_up", bitmap = "Icons/convex_sin_up.png", notifier = function () self:on_shape_selected (3, "3_convex_sin_up") ; self:auto_update() end, },
                        vb:bitmap { id = "3_wave_up", bitmap = "Icons/wave_up.png", notifier = function () self:on_shape_selected (3, "3_wave_up") ; self:auto_update() end, },
                        vb:bitmap { id = "3_concave_sin_up", bitmap = "Icons/concave_sin_up.png", notifier = function () self:on_shape_selected (3, "3_concave_sin_up") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "3_convex_up", bitmap = "Icons/convex_up.png", notifier = function () self:on_shape_selected (3, "3_convex_up") ; self:auto_update() end, },
                        vb:bitmap { id = "3_linear_up", bitmap = "Icons/linear_up.png", notifier = function () self:on_shape_selected (3, "3_linear_up") ; self:auto_update() end, },
                        vb:bitmap { id = "3_concave_up", bitmap = "Icons/concave_up.png", notifier = function () self:on_shape_selected (3, "3_concave_up") ; self:auto_update() end, },
                    },

                },


                vb:column
                {
                    margin = control_margin,
                    spacing = control_spacing,

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "4_off", bitmap = "Icons/off_selected.png", notifier = function () self:on_shape_selected (4, "4_off") ; self:auto_update() end, },
                        vb:bitmap { id = "4_square_down", bitmap = "Icons/square_down.png", notifier = function () self:on_shape_selected (4, "4_square_down") ; self:auto_update() end, },
                        vb:bitmap { id = "4_step_down", bitmap = "Icons/step_down.png", notifier = function () self:on_shape_selected (4, "4_step_down") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "4_convex_sin_down", bitmap = "Icons/convex_sin_down.png", notifier = function () self:on_shape_selected (4, "4_convex_sin_down") ; self:auto_update() end, },
                        vb:bitmap { id = "4_wave_down", bitmap = "Icons/wave_down.png", notifier = function () self:on_shape_selected (4, "4_wave_down") ; self:auto_update() end, },
                        vb:bitmap { id = "4_concave_sin_down", bitmap = "Icons/concave_sin_down.png", notifier = function () self:on_shape_selected (4, "4_concave_sin_down") ; self:auto_update() end, },
                    },

                    vb:row
                    {
                        spacing = control_spacing,
                        vb:bitmap { id = "4_convex_down", bitmap = "Icons/convex_down.png", notifier = function () self:on_shape_selected (4, "4_convex_down") ; self:auto_update() end, },
                        vb:bitmap { id = "4_linear_down", bitmap = "Icons/linear_down.png", notifier = function () self:on_shape_selected (4, "4_linear_down") ; self:auto_update() end, },
                        vb:bitmap { id = "4_concave_down", bitmap = "Icons/concave_down.png", notifier = function () self:on_shape_selected (4, "4_concave_down") ; self:auto_update() end, },
                    },

                },


            },

        },




        vb:column
        {
            id = "trigger_on_note_group",
            visible = false,
            style = "group",
            margin = control_margin,
            spacing = control_spacing,



        },



        vb:horizontal_aligner
        {
            mode = "distribute",
            spacing = dialog_spacing,

            vb:button { id = "write", notifier = function () self:on_write_pressed () end, text = "Write Curve", width = 150, height = 32 },

            vb:vertical_aligner
            {
                mode = "center",
                vb:row
                {
                    vb:checkbox { id = "auto_update", notifier = function () self:auto_update () end, },
                    vb:text { text = "Auto-update" },
                    tooltip = "Write the curve to automation each time\na setting is changed.\n*WARNING*: use only with short length\nand/or low points per line, or this will make\nyour interface lag.",
                },
            },
        },

    }

    return result
end
