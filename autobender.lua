class "Autobender"

require "autobenderwindow"
require "utils"

    ----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:__init()

    self.in_ui_update = false -- is the value change originated by the program (instead of the user)?
    self.in_automation_update = false
    self.selection_is_locked = false

    self.window = AutobenderWindow(self)
    self.window:show_dialog()

    renoise.song().selected_pattern_track_observable:add_notifier(
        function()
            self:handle_pattern_track_change()
        end
    )
    self:handle_pattern_track_change()

    self.need_update = false
    renoise.tool().app_idle_observable:add_notifier(
        function()
            if self.need_update then
                self:update_automation()
                self.need_update = false
            end
        end
    )

end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:handle_pattern_track_change()
    if self.window.dialog.visible and not self.selection_is_locked then
        if self.window.dialog.visible then
            renoise.song().selected_automation_parameter_observable:add_notifier(
                function()
                    self:handle_parameter_change()
                end
            )
            renoise.song().selected_pattern_track.automation_observable:add_notifier(
                function()
                    self:handle_parameter_change()
                end
            )
        end
        self:handle_parameter_change()
    end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:handle_parameter_change()
    if self.window.dialog.visible and not self.selection_is_locked then
        local pattern_track = renoise.song().selected_pattern_track
        local parameter = renoise.song().selected_automation_parameter
        if parameter then
            self.automation = pattern_track:find_automation(parameter)
        else
            self.automation = nil
        end
        if self.automation then
            self.automation.selection_range_observable:add_notifier(
                function()
                    self:handle_selection_range_change()
                end
            )
            self.automation.points_observable:add_notifier(
                function()
                    if not self.in_automation_update then
                        self:handle_selection_range_change()
                    end
                end
            )
        end
        self:handle_selection_range_change()
    end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:handle_selection_range_change()
    if self.window.dialog.visible and not self.selection_is_locked then
        local pattern_track = renoise.song().selected_pattern_track
        local parameter = renoise.song().selected_automation_parameter
        if parameter then
            self.automation = pattern_track:find_automation(parameter)
        else
            self.automation = nil
        end
        if
            self.automation
            and self.automation.selection_start < self.automation.selection_end
            and self.automation.selection_end < self.automation.length + 1
        then
            self.selection_start = self.automation.selection_start
            self.selection_end = self.automation.selection_end

            -- Compute automation values at start and end of selection
            local start_prec, start_next, end_prec, end_next = nil, nil, nil, nil
            local points = self.automation.points
            for _,point in pairs(points) do
                if point.time < self.selection_start then
                    start_prec = point
                elseif not start_next then
                    start_next = point
                end
                if point.time < self.selection_end then
                    end_prec = point
                elseif not end_next then
                    end_next = point
                end
            end
            local start_value = 0
            if start_prec and start_next then
                start_value = self:point_on_line(
                    self.selection_start,
                    start_prec.time,
                    start_prec.value,
                    start_next.time,
                    start_next.value
                )
            elseif start_prec then
                start_value = start_prec.value
            elseif start_next then
                start_value = start_next.value
            end
            if start_value > 1.0 then start_value = 1.0 elseif start_value < 0.0 then start_value = 0.0 end
            local end_value = 0
            if end_prec and end_next then
            end_value = self:point_on_line(
                self.selection_end,
                end_prec.time,
                end_prec.value,
                end_next.time,
                end_next.value
            )
            elseif end_next then
                end_value = end_next.value
            elseif end_prec then
                end_value = end_prec.value
            end
            if end_value > 1.0 then end_value = 1.0 elseif end_value < 0.0 then end_value = 0.0 end

            self.in_ui_update = true
            local views = self.window.vb.views
            local track_string = renoise.song().selected_track.name
            -- local device_string = renoise.song().selected_automation_device.name
            local parameter_string = renoise.song().selected_automation_parameter.name
            local start_string = "" .. math.floor(self.selection_start) - 1
            if self.selection_start - math.floor(self.selection_start) ~= 0 then
                start_string = start_string .. "." .. (self.selection_start - math.floor(self.selection_start)) / (1.0 / 256.0)
            end
            local end_string = "" .. math.floor(self.selection_end) - 1
            if self.selection_end - math.floor(self.selection_end) ~= 0 then
                end_string = end_string .. "." .. (self.selection_end - math.floor(self.selection_end)) / (1.0 / 256.0)
            end
            views["range"].text = track_string .. ", " .. parameter_string .. ": " .. start_string .. " - " .. end_string
            views["status"].text = "Selection: " .. start_string .. " - " .. end_string
            views["start"].value = start_value
            views["start"].active = true
            views["end"].value = end_value
            views["end"].active = true
            self.in_ui_update = false
        else
            self.in_ui_update = true
            local views = self.window.vb.views
            views["status"].text = "(No selection)"
            views["range"].text = "-"
            views["start"].value = 0.0
            views["start"].active = false
            views["end"].value = 0.0
            views["end"].active = false
            self.in_ui_update = false
        end
    end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:point_on_line(x, x1, y1, x2, y2)
    local a = (y1 - y2) / (x1 - x2)
    local b = y1 - a * x1
    return a * x + b
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:update_automation()
    if self.automation and not pcall(function() if self.automation.length then end end) then
        -- This is a hack to test if the automation has been deleted
        return
    end
    if
        self.automation
        and self.selection_start < self.selection_end
        and self.selection_end < self.automation.length + 1
    then
        local views = self.window.vb.views

        local start_value = views["start"].value
        local end_value = views["end"].value

        local shape = views["shape"].value
        local torsion = views["curve"].value.x
        local curvature = views["curve"].value.y
        if start_value > end_value then
            curvature =  - curvature
        end
        -- local torsion_scale = 1.0
        -- torsion = (math.exp(torsion_scale * math.abs(torsion)) - 1.0) / (math.exp(torsion_scale) - 1.0)

        local step = views["step"].value
        if step == 0 then
            step = 1.0 / 8.0
        elseif step == 1 then
            step = 1.0 / 4.0
        elseif step == 2 then
            step = 1.0 / 2.0
        else
            step = step - 2
        end

        self.in_automation_update = true
        self.automation:clear_range(self.selection_start, self.selection_end)
        self.automation:add_point_at(self.selection_start, start_value)
        self.automation:add_point_at(self.selection_end, end_value)
        for p = self.selection_start + step, self.selection_end, step do
            local v = self:point_on_curve(
                p,
                self.selection_start,
                start_value,
                self.selection_end,
                end_value,
                shape,
                torsion,
                curvature
            )
            if v < 0.0 then v = 0.0 end
            if v > 1.0 then v = 1.0 end
            self.automation:add_point_at(p, v)
        end
        self.in_automation_update = false
    end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Autobender:point_on_curve(x, x1, y1, x2, y2, shape, torsion, curvature)
    local x_normalised = (x - x1) / (x2 - x1)
    local value = self:curve(x_normalised, shape, torsion, curvature)
    return y1 + value * (y2 - y1)
end


function Autobender:curve(x, shape, torsion, curvature)

    local result

    local curve_a
    local curve_b
    if shape < 0.0 then
        shape = shape + 1.0
        curve_a = curve_logarithmic
        curve_b = curve_exponential
    else
        curve_a = curve_exponential
        curve_b = curve_half_sinusoidal
    end

    if torsion < 1.0 then
        local total_length = 1.0 + torsion
        local orig_a = curve_a(torsion, curvature)
        local height_a = 1.0 + orig_a
        local orig_b = curve_b(torsion, curvature)
        local height_b = 1.0 + orig_b
        if x > torsion / total_length then
            result = mix(
                orig_a/height_a + curve_a((x - torsion / total_length) * total_length, curvature) / height_a,
                orig_b/height_b + curve_b((x - torsion / total_length) * total_length, curvature) / height_b,
                shape
            )
        else
            result = mix(
                orig_a/height_a - curve_a(torsion - x * total_length, curvature) / height_a,
                orig_b/height_b - curve_b(torsion - x * total_length, curvature) / height_b,
                shape
            )
        end
    else
        torsion = 2.0 - torsion
        curvature = - curvature
        local total_length = 1.0 + torsion
        local extra_a = 1.0 - curve_a(1.0 - torsion, curvature)
        local height_a = (1.0 + extra_a)
        local extra_b = 1.0 - curve_b(1.0 - torsion, curvature)
        local height_b = (1.0 + extra_b)
        if x < 1.0 - torsion / total_length then
            result = mix(
                curve_a(x * total_length, curvature) / height_a,
                curve_b(x * total_length, curvature) / height_b,
                shape
            )
        else
            result = mix(
                (2.0 - curve_a(1.0 - (x * total_length - 1.0), curvature)) / height_a,
                (2.0 - curve_b(1.0 - (x * total_length - 1.0), curvature)) / height_b,
                shape
            )
        end
    end

    return result

end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
