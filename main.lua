--[[============================================================================
main.lua
============================================================================]]--
--[[
Colormate tool

for changing track colors with keyboard

0.5
initial release

0.51
fixed a stupid bug

0.6
hsv color select mode
autoclose when middle frame with no tracks visible

0.7
paste + next track function
insert value functionality
general fixes

1.0
nothing

1.1
group color management shortcuts
fixed tool crash when entering non-number values in the value textfields

1.2
light clarifications/corrections on statusbar feedback
insert relative color values
updated for api 4.0 (renoise 3.0)
keyboard logic change: spacebar switches the color system, enter enters the values (was the other way round)

TODO:adjust matrix slot colors
TODO:apply relative values PER value type, leave other values intact

TODO:reapply latest relative color change
TODO:random color value


--]]

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()

end

-- RGB - HSV Conversion functions
require "rgbhsv"

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value

local guivals = renoise.Document.create("guivals") {
    ---Current slider values
    --rgb
    ["red"] = 0,
    ["green"] = 0,
    ["blue"] = 0,
    --hsv
    ["hue"] = 0,
    ["saturation"] = 0,
    ["value"] = 0,
    --alpha
    ["alpha"] = 0,
    ---Selected slider index
    ["selected_slider"] = 1,
    ["selected_slider_name"] = "red",
    ---Copy color values
    ["is_stored"] = false,
    ["stored_red"] = 0,
    ["stored_green"] = 0,
    ["stored_blue"] = 0,
    ["stored_alpha"] = 0,
}

local VALUE_BOUNDARIES = {
    ["red"] =           {0, 255},
    ["green"] =         {0, 255},
    ["blue"] =          {0, 255},

    ["hue"] =           {0, 360},
    ["saturation"] =    {0, 100},
    ["value"] =         {0, 100},

    ["alpha"] =         {0, 100},
}


local preferences = renoise.Document.create("ScriptingToolPreferences") {
    ["mode"] = "rgb",
    ["my_color_1"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_2"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_3"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_4"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_5"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_6"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_7"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_8"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_9"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
    ["my_color_0"] = {
        red = -1,
        green = -1,
        blue = -1,
        alpha = -1,
    },
}

local OS_DEFAULT_MODIFIER = ({
    ["WINDOWS"] = "control",
    ["LINUX"] = "control",
    ["MACINTOSH"] = "command",
}) [os.platform()]

local UPDATE_FREQ = 0.3 --seconds between color updates minimum
local update_time = os.clock() --init first 'update' time

--Mode variable
local GUI_MODE = "track" --"track" or "slot"

--Global flags 
local need_update = false -- if this is up, update track colors => sliders or sliders => track colors
local update_direction = "update_target_colors" -- this decides which one


--Tostring, tonumber functions for values in textfields
--HEX
local conv_tostring_hex = function(number)
    return string.format("%02X", number)
end

local conv_tonumber = function(string, numberbase)
    --modified in v1.2 to accommodate relative value input
    --define if this is a relative value input
    local min = VALUE_BOUNDARIES[guivals.selected_slider_name.value][1]
    local max = VALUE_BOUNDARIES[guivals.selected_slider_name.value][2]

    local relative_tags = {
        "-",
        "+",
        "*",
        "/",
    }
    local tag_char = string.sub(string, -1,-1)
    local numberstring = string.sub(string, 1, -2)
    local is_relative = false
    if table.find(relative_tags, tag_char) then
        is_relative = true
        string = numberstring
    end
    print("is_relative ", is_relative)
    print("string ", numberstring)

    if not tonumber(string, numberbase) then
        return false
    else
        if is_relative then
            --relative set value
            --first get current value
            local current_value = guivals[guivals.selected_slider_name.value].value
            local new_value
            if tag_char == "-" then
                new_value = current_value - tonumber(string, numberbase) 
            elseif tag_char == "+" then
                new_value = current_value + tonumber(string, numberbase)
            elseif tag_char == "*" then
                new_value = current_value * tonumber(string, numberbase)
            elseif tag_char == "/" then
                new_value = current_value / tonumber(string, numberbase)
            else
                error("Colormate:unidentified tag_char:"..(tag_char or "nil/false"))
            end
            return math.max(math.min(new_value, max), min)
        else
            --normal set value
            return math.max(math.min(tonumber(string, numberbase), max), min)
        end
    end

end


local conv_tonumber_hex = function(string)
    return conv_tonumber(string, 16)
end

--DECIMAL
local conv_tostring_dec = function(number)
    return string.format("%03d", number)
end
local conv_tonumber_dec = function(string)
    return conv_tonumber(string, 10)
end

local conv_textfields = {
    ["red"] = {
        ["tostring"] = conv_tostring_hex,
        ["tonumber"] = conv_tonumber_hex,
    },
    ["green"] = {
        ["tostring"] = conv_tostring_hex,
        ["tonumber"] = conv_tonumber_hex,
    },
    ["blue"] = {
        ["tostring"] = conv_tostring_hex,
        ["tonumber"] = conv_tonumber_hex,
    },
    ["hue"] = {
        ["tostring"] = conv_tostring_dec,
        ["tonumber"] = conv_tonumber_dec,
    },
    ["saturation"] = {
        ["tostring"] = conv_tostring_dec,
        ["tonumber"] = conv_tonumber_dec,
    },
    ["value"] = {
        ["tostring"] = conv_tostring_dec,
        ["tonumber"] = conv_tonumber_dec,
    },
    ["alpha"] = {
        ["tostring"] = conv_tostring_dec,
        ["tonumber"] = conv_tonumber_dec,
    },
}


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------


local function show_status(message)
    --shortcut to show a statusbar message
    renoise.app():show_status(message)
end

local function get_selection_in_matrix(only_selected_slots)
    --returns a table containing matrix
    --selection in following format:
    --selection_in_matrix = {
    --    {
    --    track_index, sequence_index, is_selected
    --    },
    --    {
    --    track_index, sequence_index, is_selected
    --    },
    --    {
    --    track_index, sequence_index, is_selected
    --    },
    --    ...
    --}
    --track_index = number
    --sequence_index = number
    --is_selected = boolean
    --
    --function argument "only_selected_slots" will only
    --return slots where is_selected is true
    local selection_in_matrix = table.create()
    for track_index, track in pairs (renoise.song().tracks) do
        for sequence_index, sequence in pairs (renoise.song().sequencer.pattern_sequence) do
            local slot_is_selected = renoise.song().sequencer:track_sequence_slot_is_selected(track_index, sequence_index)
            if slot_is_selected or (not only_selected_slots) then
                table.insert(selection_in_matrix,
                {
                    track_index,
                    sequence_index,
                    slot_is_selected
                }
                )  
            end
        end
    end
    return selection_in_matrix
end

local function get_parent_group_color(track_index)
    --returns color and color_blend of mother group track, or nil if no mother
    local track = renoise.song():track(track_index)
    --if this track is a group track, then this track is
    --the parent in question
    local parent
    if track.type == renoise.Track.TRACK_TYPE_GROUP then
        parent = track
    else
        parent = track.group_parent
    end
    if parent then
        return parent.color, parent.color_blend
    end
end

local function get_group_sibling_tracks(track_index)
    --returns an array of track objects that
    --belong in the same group as track with index
    --track_index. if track is not part of a group, returns nil
    local track = renoise.song():track(track_index)
    local parent
    if track.type == renoise.Track.TRACK_TYPE_GROUP then
        --this is the parent track
        parent = track
    else
        parent = track.group_parent
    end

    if parent then
        local sibling_tracks = table.create()
        --
        local all_subtracks = parent.members
        --
        for _, track in pairs(all_subtracks) do
            if rawequal(track.group_parent,parent) then
               table.insert(sibling_tracks, track)
            end
        end
        --
        return sibling_tracks
    end
end

local function get_sliders_for_mode(mode_string)
    --returns slider (id) name table for selected
    --color mode.
    local sliders = table.create()
    if mode_string == "rgb" then
        table.insert(sliders, "red")
        table.insert(sliders, "green")
        table.insert(sliders, "blue")
    elseif mode_string == "hsv" then
        table.insert(sliders, "hue")
        table.insert(sliders, "saturation")
        table.insert(sliders, "value")
    else
        error("unexpected color mode in get_sliders_for_mode() "..(mode_string or "nil/false"))
    end
    if GUI_MODE == "track" then
        table.insert(sliders, "alpha")
    elseif GUI_MODE == "slot" then
        --all is ok
    else
        error("unexpected GUI_MODE: "..(GUI_MODE or "nil/false"))
    end
    return sliders
end

local function select_slider(dir)
    --changes selected slider index and slider name guivals
    --or updates it
    local sliders = get_sliders_for_mode(preferences.mode.value)
    local value
    if dir == "down" then
        value = guivals.selected_slider.value + 1
        if value > #sliders then value = 1 end
        guivals.selected_slider.value = value
    elseif dir == "up" then
        value = guivals.selected_slider.value - 1
        if value < 1 then value = #sliders end
        guivals.selected_slider.value = value
    elseif dir == "update" then
        value = guivals.selected_slider.value
    else
        error("unexpected dir argument in select_slider()")
    end
    --set 'current slider name' with sliders-table
    guivals.selected_slider_name.value = sliders[value] 
end

local function move_slider(slider_name, dir, step)
    --moves the selected slider left or right
    local min = vb.views[slider_name.value.."_slider"].min
    local max = vb.views[slider_name.value.."_slider"].max
    assert(min and max, "unexpected slider_name argument in move_slider()")
    if dir == "right" then
        guivals[slider_name.value].value = math.max( math.min(guivals[slider_name.value].value+step, max), min)
    elseif dir == "left" then
        guivals[slider_name.value].value = math.max( math.min(guivals[slider_name.value].value-step, max), min)
    else
        error("unexpected dir argument in move_slider()")
    end
end

local function update_sliders()
    --gets current track or slot colors to sliders

    --Get track color values
    local tc
    if GUI_MODE == "track" then
        tc = renoise.song().selected_track.color
    elseif GUI_MODE == "slot" then
        local sel_t_i = renoise.song().selected_track_index
        local sel_s_i = renoise.song().selected_sequence_index
        tc = renoise.song():pattern(sel_s_i):track(sel_t_i).color or renoise.song().selected_track.color
    else
        error("unexpected GUI_MODE: "..(GUI_MODE or "nil/false"))
    end
    --Set GUI RGB values
    guivals.red.value = tc[1]
    guivals.green.value = tc[2]
    guivals.blue.value = tc[3]

    --Calculate HSV values
    local tc_hsv = rgb_to_hsv(tc)
    --Set GUI HSV values
    guivals.hue.value = tc_hsv[1]
    guivals.saturation.value = tc_hsv[2]
    guivals.value.value = tc_hsv[3]

    --Get alpha value
    if GUI_MODE == "track" then
        local blend = renoise.song().selected_track.color_blend
        --Set GUI alpha value
        guivals.alpha.value = blend
    end
end

local function highlight_selected_slider()
    --adjusts slider row styles to highlight selected
    local sliders = get_sliders_for_mode(preferences.mode.value)
    for index, slider_name in pairs(sliders) do
        if guivals.selected_slider_name.value == slider_name then
            vb.views[slider_name].style = "border"
        else
            vb.views[slider_name].style = "body"
        end
    end
end

local function show_slider(id)
    --shows slider with id argument id
    vb.views[id].visible = true
end

local function hide_slider(id)
    --hides slider with id argument id
    vb.views[id].visible = false
end

local function adjust_mode_visibility()
    --Shows and hides sliders according to selected color mode
    if preferences.mode.value == "rgb" then 
        hide_slider("hue")
        hide_slider("saturation")
        hide_slider("value")
        show_slider("red")
        show_slider("green")
        show_slider("blue")
        if GUI_MODE == "track" then
            show_slider("alpha")
        elseif GUI_MODE == "slot" then
            hide_slider("alpha")
        end
    elseif preferences.mode.value == "hsv" then
        hide_slider("red")
        hide_slider("green")
        hide_slider("blue")
        show_slider("hue")
        show_slider("saturation")
        show_slider("value")
        if GUI_MODE == "track" then
            show_slider("alpha")
        elseif GUI_MODE == "slot" then
            hide_slider("alpha")
        end
    end
end

local function next_color_mode()
    --cycles through availlable modes
    -- = either rgb or hsv mode
    if preferences.mode.value == "rgb" then
        preferences.mode.value = "hsv"
    else
        preferences.mode.value = "rgb"
    end
    adjust_mode_visibility()
    update_sliders()
    select_slider("update")
    highlight_selected_slider()
end

local function update_text()
    --Writes titles to rows
    vb.views["red_text"].text = "R"
    vb.views["green_text"].text = "G"
    vb.views["blue_text"].text = "B"
    vb.views["hue_text"].text = "H"
    vb.views["saturation_text"].text = "S"
    vb.views["value_text"].text = "V"
    vb.views["alpha_text"].text = "A"
end

local function update_target_colors()
    --updates current track or slot colors to reflect slider values
    local colors = {}
    if preferences.mode.value == "rgb" then
        colors[1] = guivals.red.value
        colors[2] = guivals.green.value
        colors[3] = guivals.blue.value
    elseif preferences.mode.value == "hsv" then
        local hsv = {
            guivals.hue.value,
            guivals.saturation.value,
            guivals.value.value
        }
        colors = hsv_to_rgb(hsv)
    end
    if GUI_MODE == "track" then
        renoise.song().selected_track.color = colors
        renoise.song().selected_track.color_blend = guivals.alpha.value
    elseif GUI_MODE == "slot" then
        local selected_slots = get_selection_in_matrix(true)
        for index, slot_coordinates in  pairs(selected_slots) do
            renoise.song():pattern(slot_coordinates[2]):track(slot_coordinates[1]).color = colors
        end
    else
        error("Colormate:unidentified GUI_MODE:"..(GUI_MODE or "nil/false"))
    end
end

local function store_current_color()
    --stores current track color into stored_colors
    local tc
    if GUI_MODE == "track" then
        tc = renoise.song().selected_track.color
    elseif GUI_MODE == "slot" then
        local sel_t_i = renoise.song().selected_track_index
        local sel_s_i = renoise.song().selected_sequence_index
        tc = renoise.song():pattern(sel_s_i):track(sel_t_i).color or renoise.song().selected_track.color
    end
    local red_value = tc[1]
    local green_value = tc[2]
    local blue_value = tc[3]
    local alpha_value = renoise.song().selected_track.color_blend
    guivals.stored_red.value = red_value
    guivals.stored_green.value = green_value
    guivals.stored_blue.value = blue_value
    guivals.stored_alpha.value = alpha_value
    guivals.is_stored.value = true
    show_status("Current "..GUI_MODE.." color copied.")
end

local function apply_stored_color()
    --applies stored color to current track
    if guivals.is_stored.value == false then
        --nothing is stored
        show_status("Cannot apply "..GUI_MODE.." color, nothing is stored")
        return
    end
    local colors = {}
    colors[1] = guivals.stored_red.value
    colors[2] = guivals.stored_green.value
    colors[3] = guivals.stored_blue.value
    if GUI_MODE == "track" then
        renoise.song().selected_track.color = colors
        renoise.song().selected_track.color_blend = guivals.alpha.value
    elseif GUI_MODE == "slot" then
        local selected_slots = get_selection_in_matrix(true)
        for index, slot_coordinates in pairs(selected_slots) do
            renoise.song():pattern(slot_coordinates[2]):track(slot_coordinates[1]).color = colors
        end
    else
        error("Colormate:unidentified GUI_MODE:"..(GUI_MODE or "nil/false"))
    end
end

local function close_dialog()
    if dialog and dialog.visible then
        if GUI_MODE == "track" then
            update_target_colors()
            --"slot" mode won't work, because it'll try to
            --update the selection in matrix, which can be
            --something other than the slot your matrix cursor
            --is currently pointing at
        end
        --remove idle notifier
        if renoise.tool().app_idle_observable:has_notifier(idle_evaluator) then
            renoise.tool().app_idle_observable:remove_notifier(idle_evaluator) 
        end
        --remove release document notifier
        if renoise.tool().app_release_document_observable:has_notifier(close_dialog) then
            renoise.tool().app_release_document_observable:remove_notifier(close_dialog)
        end
        --remove track change notifier
        if renoise.song().selected_track_observable:has_notifier(sel_track_update) then
            renoise.song().selected_track_observable:remove_notifier(sel_track_update) 
        end
        dialog:close()
        vb = nil
    end
end

local function get_pref_color(id)
    --Returns {r,g,b},a of user preference colors indexed with id or
    --false if color is not yet initialized
    local color_table = preferences["my_color_"..id]
    if color_table.red.value == -1 then
        --not initialized yet
        return false
    else
        return {color_table.red.value, color_table.green.value, color_table.blue.value}, color_table.alpha.value
    end
end

local function apply_pref_color(id)
    --Applies an user pref color to current track
    local colors, alpha = get_pref_color(id)
    if colors then
        renoise.song().selected_track.color = colors
        renoise.song().selected_track.color_blend = alpha
        show_status("Applied user preference color "..id.." on track.")
    else
        show_status("Colormate preference "..id.." is empty.")
    end
end

local function apply_color_to_group_siblings(colors, alpha, track_index, exclude_group_tracks)
    --Applies color, alpha to tracks in this group
    --exclude_group_tracks = boolean, if true, group tracks inside
    --parent group will retain their color
    if colors then
        --If this is a group track, make it so that the group to
        --be colored is the one this selected track holds
        local tracks = get_group_sibling_tracks(track_index)
        if tracks then
            local include_counter = 0
            local exclude_group_counter = 0

            for _, track in pairs(tracks) do
                if exclude_group_tracks and track.type == renoise.Track.TRACK_TYPE_GROUP then
                    exclude_group_counter = exclude_group_counter + 1
                else
                    include_counter = include_counter + 1
                    track.color = colors
                    track.color_blend = alpha
                end
            end

            show_status("Applied color in ".. include_counter .." group sibling tracks. ("..exclude_group_counter.." group tracks excluded)")
        else
            show_status("Cannot apply color, no parent group!")
        end
    else
        show_status("Cannot apply color, no parent group!")
    end
end

local function apply_parent_color_to_group(track_index, exclude_group_tracks)
    --Gets group parent color, runs apply_color_to_group_siblings
    local colors, alpha = get_parent_group_color(track_index)
    if colors then
        apply_color_to_group_siblings(colors, alpha, track_index, exclude_group_tracks)
    else
        show_status("Cannot apply color, no parent group!")
    end
end

local function apply_selected_color_to_group(track_index, exclude_group_tracks)
    --Gets selected_track color, runs apply_color_to_group_siblings
    local colors, alpha = renoise.song().selected_track.color, renoise.song().selected_track.color_blend
    if colors then
        apply_color_to_group_siblings(colors, alpha, track_index, exclude_group_tracks)
    else
        error("something's wrong with track colors (Colormate)")
    end
end

local function store_pref_color(id)
    --Stores a preference color
    local tc = renoise.song().selected_track.color
    local red_value = tc[1]
    local green_value = tc[2]
    local blue_value = tc[3]
    local alpha_value = renoise.song().selected_track.color_blend
    preferences["my_color_"..id].red.value = red_value
    preferences["my_color_"..id].green.value = green_value
    preferences["my_color_"..id].blue.value = blue_value
    preferences["my_color_"..id].alpha.value = alpha_value
    show_status("Current track color stored as Colormate preference "..id..".")
end

local function next_track()
    --selects next track
    if GUI_MODE == "track" then
        update_target_colors()--before changing track
        --slot mode does not work (selection ~= your cursor)
    end
    need_update = false -- 'cause just updated
    local current_track = renoise.song().selected_track_index
    current_track = current_track + 1
    if current_track > #renoise.song().tracks then
        current_track = 1
    end
    renoise.song().selected_track_index = current_track
    update_sliders()
end

local function prev_track()
    --selects previous track
    if GUI_MODE == "track" then
        update_target_colors()--before changing track
        --slot mode does not work (selection ~= your cursor)
    end
    need_update = false -- 'cause just updated
    local current_track = renoise.song().selected_track_index
    current_track = current_track - 1
    if current_track < 1 then
        current_track = #renoise.song().tracks
    end
    renoise.song().selected_track_index = current_track
    update_sliders()
end

local function next_sequence()
    --selects next sequence slot
    local seq_len = #renoise.song().sequencer.pattern_sequence
    local current = renoise.song().selected_sequence_index
    renoise.song().selected_sequence_index = math.min(seq_len, current + 1 )
    if GUI_MODE == "slot" then
        update_sliders()
    end
end

local function prev_sequence()
    --selects next sequence slot
    local seq_len = #renoise.song().sequencer.pattern_sequence
    local current = renoise.song().selected_sequence_index
    renoise.song().selected_sequence_index = math.max(1, current - 1 )
    if GUI_MODE == "slot" then
        update_sliders()
    end
end
--------------------------------------------------------------------------------

function idle_evaluator()
    --runs in the background checking stuff
    --Check if active middle frame does not show tracks
    local valid_middle_frames = {
        renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR,
        renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
    }
    local is_valid_middle_frame = false
    for key, frame in pairs(valid_middle_frames) do
        if renoise.app().window.active_middle_frame == frame then
            --valid frame!
            is_valid_middle_frame = true
            break
        end
    end
    if not is_valid_middle_frame then
        close_dialog()
    end
    
    --Check if updates are queued (track color / sliders) 
    --updates are made with UPDATE_FREQ ms intervals
    if os.clock() - update_time > UPDATE_FREQ then
        if need_update then
            update_time = os.clock()
            if update_direction == "update_target_colors" then
                update_target_colors()
            elseif update_direction == "update_sliders" then
                update_sliders()
                --reset direction
                update_direction = "update_target_colors"
            end
            --reset flag
            need_update = false
        end
    end
end

function sel_track_update()
    --Notifier function for selected_track_observable
    update_direction = "update_sliders"
    need_update = "true" 
end
--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog(gui_mode)

    -- This block makes sure a non-modal dialog is shown once.
    -- If the dialog is already opened, it will be focused.
    if dialog and dialog.visible then
        dialog:show()
        return
    end

    -- The ViewBuilder is the basis
    vb = renoise.ViewBuilder()

    -- Set the global GUI_MODE variable
    GUI_MODE = gui_mode

    local function keyhandler(dialog, key)
        --debug
        --print(key.name, key.modifiers)
        local res_keys = {
            {"down", "",     "NEXT_SLIDER"},
            {"up", "",   "PREV_SLIDER"},

            {"left", "",   "DEC"},
            {"right", "",  "INC"},

            {"left", "shift",   "DEC_FAST"},
            {"right", "shift",  "INC_FAST"},

            {"left", OS_DEFAULT_MODIFIER,   "DEC_MAX"},
            {"right", OS_DEFAULT_MODIFIER,  "INC_MAX"},

            {"return", "", "ENTER_VALUE"},

            {"space", "", "NEXT_COLOR_MODE"},
            {"r", "", "ENTER_VALUE_red"},
            {"g", "", "ENTER_VALUE_green"},
            {"b", "", "ENTER_VALUE_blue"},
            {"h", "", "ENTER_VALUE_hue"},
            {"s", "", "ENTER_VALUE_saturation"},
            {"v", "", "ENTER_VALUE_value"},
            {"a", "", "ENTER_VALUE_alpha"},

            {"g", OS_DEFAULT_MODIFIER, "APPLY_PARENT_COLOR_TO_GROUP"},
            {"g", "shift + "..OS_DEFAULT_MODIFIER, "APPLY_SELECTED_COLOR_TO_GROUP"},

            {"c", OS_DEFAULT_MODIFIER, "STORE_COLOR"},
            {"v", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR"},
            {"v", "shift + "..OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_AND_NEXT_TRACK"},

            {"1", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_1"},
            {"1", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_1"},
            {"2", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_2"},
            {"2", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_2"},
            {"3", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_3"},
            {"3", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_3"},
            {"4", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_4"},
            {"4", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_4"},
            {"5", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_5"},
            {"5", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_5"},
            {"6", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_6"},
            {"6", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_6"},
            {"7", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_7"},
            {"7", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_7"},
            {"8", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_8"},
            {"8", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_8"},
            {"9", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_9"},
            {"9", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_9"},
            {"0", OS_DEFAULT_MODIFIER, "APPLY_STORED_COLOR_0"},
            {"0", "shift + "..OS_DEFAULT_MODIFIER, "STORE_COLOR_0"},

            {"tab", "",   "NEXT_TRACK"},
            {"tab", "shift",  "PREV_TRACK"},
            {"up", "shift",  "PREV_SEQUENCE"},
            {"down", "shift",  "NEXT_SEQUENCE"},

            {"z", OS_DEFAULT_MODIFIER,   "UNDO_REDO"},
            {"z", "shift + "..OS_DEFAULT_MODIFIER,   "UNDO_REDO"},

            {"esc", "",    "CLOSE"},
        }
        local action
        for index, res_key in pairs(res_keys) do
            if key.name == res_key[1] and key.modifiers == res_key[2] then
                action = res_key[3]
                break
            end
        end
        if not action then
            --Not reserved
            return key
        end
        --Handle actions
        if action == "NEXT_SLIDER" then
            select_slider("down")
            highlight_selected_slider()
        elseif action == "PREV_SLIDER" then
            select_slider("up")
            highlight_selected_slider()
        elseif action == "DEC" then
            move_slider(guivals.selected_slider_name, "left", 1)
            --update_target_colors()
            need_update = true
        elseif action == "INC" then
            move_slider(guivals.selected_slider_name, "right", 1)
            --update_target_colors()
            need_update = true
        elseif action == "DEC_FAST" then
            move_slider(guivals.selected_slider_name, "left", 10)
            --update_target_colors()
            need_update = true
        elseif action == "INC_FAST" then
            move_slider(guivals.selected_slider_name, "right", 10)
            --update_target_colors()
            need_update = true
        elseif action == "DEC_MAX" then
            move_slider(guivals.selected_slider_name, "left", vb.views[guivals.selected_slider_name.value.."_slider"].max)
            --update_target_colors()
            need_update = true
        elseif action == "INC_MAX" then
            move_slider(guivals.selected_slider_name, "right", vb.views[guivals.selected_slider_name.value.."_slider"].max)
            --update_target_colors()
            need_update = true
        elseif string.sub(action,1,11) == "ENTER_VALUE" then
            if #action > 11 then
                --select value row
                --get row name
                local row_name = string.sub(action, 13, #action)
                local mode = preferences.mode.value
                local sliders = get_sliders_for_mode(mode)
                local row_index = table.find(sliders, row_name)
                if not row_index then
                    next_color_mode()
                    mode = preferences.mode.value
                    sliders = get_sliders_for_mode(mode)
                    row_index = table.find(sliders, row_name)
                    if not row_index then
                        error("unexpected row_name")
                    end
                end
                guivals.selected_slider_name.value = row_name
                guivals.selected_slider.value = row_index
                highlight_selected_slider()
            end
            --Do a tricky value insertion
            local function update_according_to_textfield()
                --this function updates slider and color to match the textfield
                --it is called by app_idle_observable continuously, when a textfield is focused
                --it runs the update and detaches when focus is lost from currently focused textfield
                local slider_name = guivals.selected_slider_name.value
                local textfield_name = slider_name.."_textfield"
                local textfield = vb.views[textfield_name]
                if textfield.edit_mode == false then
                    local max = vb.views[slider_name.."_slider"].max
                    local min = vb.views[slider_name.."_slider"].min
                    guivals[slider_name].value = conv_textfields[slider_name].tonumber(vb.views[textfield_name].value, max, min) or guivals[slider_name].value
                    update_target_colors()
                    update_sliders()
                    --REMOVE idle notifier
                    if renoise.tool().app_idle_observable:has_notifier(update_according_to_textfield) then
                        renoise.tool().app_idle_observable:remove_notifier(update_according_to_textfield) 
                    end
                end
            end
            --focus
            vb.views[guivals.selected_slider_name.value.."_textfield"].edit_mode = true
            --spawn idle notifier to run update function above when unfocused
            if not renoise.tool().app_idle_observable:has_notifier(update_according_to_textfield) then
                renoise.tool().app_idle_observable:add_notifier(update_according_to_textfield) 
            end
        elseif action == "UNDO_REDO" then
            --jump through certain hoops
            update_direction = "update_sliders"
            need_update = true
            return key
        elseif action == "APPLY_PARENT_COLOR_TO_GROUP" then
            renoise.song():describe_undo("Colormate: Apply parent color to group")
            apply_parent_color_to_group(renoise.song().selected_track_index, true)
            update_sliders()
        elseif action == "APPLY_SELECTED_COLOR_TO_GROUP" then
            renoise.song():describe_undo("Colormate: Apply selected color to group")
            apply_selected_color_to_group(renoise.song().selected_track_index, true)
            update_sliders()
        elseif action == "STORE_COLOR" then
            store_current_color()
        elseif action == "APPLY_STORED_COLOR" then
            renoise.song():describe_undo("Colormate: Apply stored "..GUI_MODE.." color")
            apply_stored_color()
            update_sliders()
        elseif action == "APPLY_STORED_COLOR_AND_NEXT_TRACK" then
            renoise.song():describe_undo("Colormate: Apply stored "..GUI_MODE.." color")
            apply_stored_color()
            update_sliders()
            next_track()
        elseif action == "NEXT_TRACK" then
            next_track()
        elseif action == "PREV_TRACK" then
            prev_track()
        elseif action == "NEXT_SEQUENCE" then
            next_sequence()
        elseif action == "PREV_SEQUENCE" then
            prev_sequence()
        elseif action == "NEXT_COLOR_MODE" then
            next_color_mode()
        elseif action == "CLOSE" then
            close_dialog()
        elseif string.sub(action, 1, #action-1) == "STORE_COLOR_" then
            local id = string.sub(action, -1)
            store_pref_color(id)
        elseif string.sub(action, 1, #action-1) == "APPLY_STORED_COLOR_" then
            local id = string.sub(action, -1)
            renoise.song():describe_undo("Colormate: Apply preference track color")
            apply_pref_color(id)
            update_sliders()
        end
    end

    local function build_slider(target_name)
        --returns a slider for target_value
        local target_value = guivals[target_name]

        local function update_textfield()
            --updates the textfield to match slider
            vb.views[target_name.."_textfield"].value = conv_textfields[target_name].tostring(vb.views[target_name.."_slider"].value)
        end

        ----The ViewBuilder Row
        return vb:row {
            id = target_name,
            style = "plain",
            vb:text{
                id = target_name.."_text",
                text = "",
                font = "bold",
                width = 15,
            },
            vb:textfield{
                id = target_name.."_textfield",
                value = conv_textfields[target_name].tostring(target_value.value),
                width = 26,
            },
            vb:minislider {
                id = target_name.."_slider",
                bind = target_value,
                min = VALUE_BOUNDARIES[target_name][1],
                max = VALUE_BOUNDARIES[target_name][2],
                width = 80,
                notifier = update_textfield,
            }
        }
    end

    -- The content of the dialog, built with the ViewBuilder.
    local content = vb:column {
        margin = 0,
        --Red
        build_slider("red"),
        --Green
        build_slider("green"),
        --Blue
        build_slider("blue"),
        --Hue
        build_slider("hue"),
        --Saturation
        build_slider("saturation"),
        --Value
        build_slider("value"),
        --Alpha
        build_slider("alpha"),
    } 

    --Hide sliders not in displayed mode
    adjust_mode_visibility()

    --Get current values
    update_sliders()
    update_text()
    select_slider("update") --update slider selection
    highlight_selected_slider()

    --Run idle evaluator for changing track colors, watching middle frame
    if not renoise.tool().app_idle_observable:has_notifier(idle_evaluator) then
        renoise.tool().app_idle_observable:add_notifier(idle_evaluator) 
    end

    --Check for unloading song when tool open
    if not renoise.tool().app_release_document_observable:has_notifier(close_dialog) then
        renoise.tool().app_release_document_observable:add_notifier(close_dialog)
    end

    --Check for selected track: changed -> order an update for sliders
    if not renoise.song().selected_track_observable:has_notifier(sel_track_update) then
        renoise.song().selected_track_observable:add_notifier(sel_track_update) 
    end

    --TODO: The next/prev track checking should be done here!
    --method: have an observable attached to selected_track,
    --make it raise 'update' flag, and set direction to 'update_sliders'.
    --

    -- A custom dialog is non-modal and displays a user designed
    -- layout built with the ViewBuilder.   
    --
    local mode_appendix = ""
    if GUI_MODE == "track" then
        mode_appendix = "/track"
    elseif GUI_MODE == "slot" then
        mode_appendix = "/slot"
    else
        error("Colormate:unidentified GUI_MODE:"..(GUI_MODE or "nil/false"))
    end
    dialog = renoise.app():show_custom_dialog("Colormate"..mode_appendix, content, keyhandler)  

end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

--[[
renoise.tool():add_menu_entry {
name = "Main Menu:Tools:"..tool_name.."...",
invoke = show_dialog  
}
--]]


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
    name = "Pattern Editor:Track Control:Colormate...",
    invoke = function()
        show_dialog("track")
    end
}
renoise.tool():add_keybinding {
    name = "Mixer:Track Control:Colormate...",
    invoke = function()
        show_dialog("track")
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Matrix:Tracks:Colormate...",
    invoke = function()
        show_dialog("slot")
    end
}


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
name = tool_id..":Show Dialog...",
invoke = show_dialog
}
--]]

--Preferences
renoise.tool().preferences = preferences

