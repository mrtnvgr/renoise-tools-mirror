class "ModifierWindow"

----------------------------------------------------------------------------------------------------


function ModifierWindow:__init (modifier)

    self.modifier = modifier
    self.vb = renoise.ViewBuilder ()

    renoise.tool():add_menu_entry {
        name = "Main Menu:Tools:Automasher:Modifier",
        invoke = function () self:show_dialog () end
    }

    renoise.tool():add_menu_entry {
        name = "Track Automation:Automasher Modifier...",
        invoke = function () self:show_dialog () end
    }

    renoise.tool():add_keybinding {
        name = "Global:Tools:Automasher Modifier...",
        invoke = function () self:show_dialog () end
    }

end

----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------


function ModifierWindow:show_dialog ()

    if self.dialog and self.dialog.visible then
        self.dialog:show ()
        return
    end

    if not self.dialog_content then
        self.dialog_content = self:gui ()
    end

    local kh = function (d, k) self:key_handler (d, k) end
    self.dialog = renoise.app():show_custom_dialog ("Automation Modifier", self.dialog_content, kh)

end


----------------------------------------------------------------------------------------------------

---TODO: move into a superclass

function ModifierWindow:key_handler (dialog, key)

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

    elseif key.modifiers == "control" and key.name == "z" then
        renoise.song():undo ()
    elseif key.modifiers == "shift + control" and key.name == "z" then
        renoise.song():redo ()
    elseif key.modifiers == "control" and key.name == "y" then
        renoise.song():redo ()

    end

end


----------------------------------------------------------------------------------------------------


function ModifierWindow:gui ()

    local vb = self.vb

    local result = vb:column
    {
        style = "body",
        margin = 8,
        spacing = 8,
        uniform = true,

        vb:column
        {
            style = "group",
            margin = 4,
            vb:horizontal_aligner
            {
                mode = "justify",
                vb:chooser
                {
                    id = "mode",
                    items = { "Start at Cursor", "Envelope in Pattern", "Envelope in Song", },
                    notifier = function ()
                        self.vb.views.length_group.visible = (self.vb.views.mode.value == 1)
                    end,
                },

                vb:row -- Necessary for jusitfied layout, because "length_group" might be invisible
                {
                    vb:row
                    {
                        id = "length_group",
                        visible = true,
                        vb:text { text = "Length" },
                        vb:valuebox { },
                    },
                },
            },
        },

        vb:column
        {
            style = "group",
            margin = 4,
            spacing = 4,
            vb:row
            {
                vb:horizontal_aligner
                {
                    mode = "justify",
                    vb:button { text = "Add" },
                    vb:button { text = "Sub" },
                    width = 70,
                },
                vb:slider { width = 150, },
                vb:valuefield { },
            },

            vb:row
            {
                vb:horizontal_aligner
                {
                    mode = "justify",
                    vb:button { text = "Mul" },
                    vb:button { text = "Div" },
                    width = 70,
                },
                vb:slider { width = 150, },
                vb:valuefield { },
            },

            vb:row
            {
                vb:horizontal_aligner
                {
                    mode = "left",
                    vb:button { text = "Humanize" },
                    width = 70,
                },
                vb:slider { width = 150, },
                vb:valuefield { },
            },
        },


        vb:column
        {
            style = "group",
            margin = 4,
            spacing = 4,
            vb:row
            {
                vb:text { text = "Start", width = 70, },
                vb:slider { width = 150, },
                vb:valuefield { },
            },

            vb:row
            {
                vb:text { text = "Destination", width = 70, },
                vb:slider { width = 150, },
                vb:valuefield { },
            },

            vb:row
            {
                vb:horizontal_aligner { width = 70 },
                vb:button { text = "Apply Ramp" },
            },
        }

    }

    return result

end

----------------------------------------------------------------------------------------------------
