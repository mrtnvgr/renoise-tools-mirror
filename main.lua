--[[============================================================================
main.lua
============================================================================]]--

--[[

EditStepTweaks for renoise

Put together by KMaki

Thanks to:
joule (original movement code)


V 1.4
-renamed Fix EditStep wrapping behavior option more appropriately
-added tweaked shortcuts for "Pattern Editor:Navigation:Jump 1 Row Up / Down" (or: normal movement)
-GUI optimization: So many options that needs dynamic GUI.

V 1.3
-rewrote movement code, should be faster in projects with lots of patterns
-fixed last nonzero edit step not being catched when first loading tool
-added option to ignore pattern follow state
-added tweaked shortcuts for "Pattern Editor:Navigation:Jump 16 Rows Up / Down"
-added option to wrap song

V 1.1
-added 2 options for choosing what editstep to use for
 moving and aligning the cursor, if user changes the
 editstep into zero
-added keyboard shortcut for aligning into editstep grid

--]]




-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

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



--------------------------------------------------------------------------------
-- Tool Options
--------------------------------------------------------------------------------
-- Setup the preferences Document
local preferences = renoise.Document.create("ScriptingToolPreferences"){

    --Zero Tweak: move with editstep 1 or custom editstep even if editstep is 0
    zero_tweak = false,
    zero_tweak_method = 1,

    --No Ram settings: Do not move if step would take cursor out of bounds.
    --(normal behaviour would step into last available line)
    noram_bottom = false,
    noram_top = false,

    --Playback Tweak: when stopped, get into the edit step grid
    playback_tweak = false,
    playback_tweak_method = 1,
    playback_tweak_ignore_follow = false,

    --Extra wrap options
    wrap_song = false,
    wrap_fix = true,

    --Note tweak (Experimental)
    --To not de-grid when placing note near the pattern end
    note_tweak = false
}
-- The names for the chooser options are stored within this global table
local optionlists = {
    --Zero Tweak: move with editstep 1 even if editstep is 0
    zero_tweak_methodtitle = "Method",
    zero_tweak_methodnames = {
        "Use step 1",
        "Use previous non-0 ES",
    },

    --Playback Tweak: when stopped, get into the edit step grid
    playback_tweak_methodtitle = "When ES=0",
    playback_tweak_methodnames = {
        "Use step 1",
        "Use previous non-0 ES",
    },
}

--------------------------------------------------------------------------------
-- Global vars
--------------------------------------------------------------------------------
--Placeholder for renoise.song()
local s = nil

--This will hold the last nonzero edit step
local last_nonzero_edit_step = 1

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

--------------------Get seq, line x lines from here functions
local function will_cross_pattern_boundary(step)
    --[[
    step = nil -> Returns the number of lines that will make cursor jump out of the current pattern
    step = number > Fast check to see if the step will take cursor out of the current pattern (boolean)
    --]] 
    if step then
        local s = renoise.song()
        local sli = s.selected_line_index
        local nol = s.selected_pattern.number_of_lines
        local will_cross = ((sli + step) > nol) or ((sli + step) < 1)
        local dir = (step > 0)
        --boolean for "will cross", boolean for "direction forward", boolean for "direction backward"
        return will_cross, dir, not dir
    else
        local s = renoise.song()
        local sli = s.selected_line_index
        local nol = s.selected_pattern.number_of_lines
        local cross_fwd = nol - sli + 1
        local cross_back = -1 * sli
        --step that will make cursor jump out of pattern forward, -"- backward (negative number)
        --TODO:Not actually tested...
        return cross_fwd, cross_back
    end
end

local function get_next_line_pos(current_pos)
    --[[
    This will return a song position 1 line forward from 'current_pos'
    current_pos format can be a renoise.SongPos object or a table
    that has two entries, first one for sequence, second one for line
    This function has a twin get_prev_line_pos(current_pos) that works
    in backward direction. TODO: maybe combine these? Or at least remove
    most double code.
    --]]
    local old_line = nil
    local old_seq = nil
    if type(current_pos) == "SongPos" then
        old_seq = current_pos.sequence
        old_line = current_pos.line
    elseif type(current_pos) == "table" then
        old_seq = current_pos[1]
        old_line = current_pos[2]
    else
        error("Invalid current_pos type: "..type(current_pos)..", expected a renoise.SongPos object or a table {sequence, line}")
    end

    local s = renoise.song()

    --Try this hop
    local new_line = old_line + 1

    --Set these later
    local new_seq = nil
    local is_out_of_bounds = nil
    local ram_pos = nil

    --Get current pattern for reference
    local old_pat = s:pattern(s.sequencer:pattern(old_seq))

    --Cases
    if new_line > old_pat.number_of_lines then
        --Will cross pattern boundary

        --Sub-Cases
        if not s.transport.wrapped_pattern_edit then
            
            --Sub-Cases
            if preferences.wrap_fix.value == true then
                --Enable wrapping behaviour for edit step
                --Back to pattern top

                is_out_of_bounds = false
                new_seq = old_seq
                new_line = 1
            else
                --EditStep won't wrap!
                is_out_of_bounds = true
                new_line = old_line
                new_seq = old_seq
            end
        else
            --Next sequence
            new_seq = old_seq + 1

            --Sub-cases
            if new_seq > #s.sequencer.pattern_sequence then
                --at last pattern

                --Sub cases
                if preferences.wrap_song.value == true then
                    --wrap song
                    is_out_of_bounds = false
                    new_line = 1
                    new_seq = 1
                else
                    --no wrap, at last pattern -> step out of bounds
                    is_out_of_bounds = true
                    new_line = old_line
                    new_seq = old_seq
                end
            else
                --Normal case, Won't be out of bounds
                
                is_out_of_bounds = false
                new_line = 1
            end
        end


    else

        --Will not cross pattern boundary
        is_out_of_bounds = false
        new_seq = old_seq

    end

    local new_pos = renoise.SongPos()
    new_pos.sequence = new_seq
    new_pos.line = new_line

    return is_out_of_bounds, new_pos
end

local function get_prev_line_pos(current_pos)
    local old_line = nil
    local old_seq = nil
    if type(current_pos) == "SongPos" then
        old_seq = current_pos.sequence
        old_line = current_pos.line
    elseif type(current_pos) == "table" then
        old_seq = current_pos[1]
        old_line = current_pos[2]
    else
        error("Invalid current_pos type: "..type(current_pos)..", expected a renoise.SongPos object or a table {sequence, line}")
    end

    local s = renoise.song()

    --Try this hop
    local new_line = old_line - 1

    --Set these later
    local new_seq = nil
    local is_out_of_bounds = nil

    --Cases
    if new_line < 1 then

        --Will cross pattern boundary
        if not s.transport.wrapped_pattern_edit then
            --Sub-Cases
            if preferences.wrap_fix.value == true then
                --Enable wrapping behaviour for edit step
                --Back to pattern bottom
                is_out_of_bounds = false
                new_seq = old_seq
                new_line = s.selected_pattern.number_of_lines
            else
                --EditStep won't wrap!
                is_out_of_bounds = true
                new_line = old_line
                new_seq = old_seq
            end

        else
            --Next sequence
            new_seq = old_seq - 1

            --Sub-cases
            if new_seq == 0 then
                --at first pattern

                --Sub cases
                if preferences.wrap_song.value == true then
                    --wrap song
                    is_out_of_bounds = false
                    new_seq = #s.sequencer.pattern_sequence
                    local new_pattern = s:pattern(s.sequencer:pattern(new_seq))
                    new_line = new_pattern.number_of_lines
                else
                    --at first pattern -> step out of bounds
                    is_out_of_bounds = true
                    new_line = old_line
                    new_seq = old_seq
                end
            else
                --Not at first pattern, Won't be out of bounds
                is_out_of_bounds = false
                --Get new pattern for reference
                local new_pattern = s:pattern(s.sequencer:pattern(new_seq))
                new_line = new_pattern.number_of_lines
            end
        end


    else

        --Won't cross pattern boundary
        is_out_of_bounds = false
        new_seq = old_seq

    end

    local new_pos = renoise.SongPos()
    new_pos.sequence = new_seq
    new_pos.line = new_line

    return is_out_of_bounds, new_pos
end




local function get_new_pos(step)
    --[[
    returns SongPos step lines away from current pos 
    step can be positive or negative
    --]]
    local s = renoise.song()

    --get data, init seq, line locals
    local old_seq = s.selected_sequence_index
    local old_line = s.selected_line_index
    local old_pos = renoise.SongPos()
    old_pos.line = old_line
    old_pos.sequence = old_seq

    local new_seq
    local new_line
    local new_pos = nil

    --will cross pattern boundary?
    local wcpb, wc_fwd, wc_back = will_cross_pattern_boundary(step)

    --cases
    if not wcpb then
        --simple case, stays within pattern
        new_seq = old_seq
        new_line = old_line + step
        --build pos
        new_pos = renoise.SongPos()
        new_pos.line = new_line
        new_pos.sequence = new_seq
        --exit cases
    else
        --not simple case, leaves current pattern
        local oob --boolean, "is out of bounds?"
        local ram_pos
        if step > 0 then
            --moving forward
            for i = 1, step, 1 do
                oob, new_pos = get_next_line_pos(new_pos or {old_seq, old_line})
                ram_pos = new_pos
                if oob then
                    break
                end
            end
        else
            --moving backward
            for i = -1, step, -1 do
                oob, new_pos = get_prev_line_pos(new_pos or old_pos)
                ram_pos = new_pos
                if oob then
                    break
                end
            end
        end
        if oob then
            --Is out of bounds - Check ramming prefs
            if wc_fwd then
                if preferences.noram_bottom.value == true then
                    --No ramming in bottom - Don't move
                    new_pos = old_pos
                else
                    --ram to bottom
                    --local ram_pattern = s:pattern(s.sequencer:pattern(ram_pos.sequence))
                    new_pos.sequence = ram_pos.sequence
                    new_pos.line = ram_pos.line
                end
            else
                if preferences.noram_top.value == true then
                    --No ramming in bottom - Don't move
                    new_pos = old_pos
                else
                    --ram to top
                    new_pos.sequence = ram_pos.sequence
                    new_pos.line = ram_pos.line
                end
            end
        end
    end

    --return
    return new_pos
end


local function move_cursor(step)
    s = renoise.song()
    step = step or s.transport.edit_step  --default value for no args call=current edit_step

    if step == 0 then
        --no movement
    else
        s.transport.edit_pos = get_new_pos(step)
    end 

end

-- main editstep move function. keybinds call this.
local function move_edit_step_tweak(dir, explicit_step)
    --[[
    up:dir = -1
    dn:dir = 1
    explicit_step = Set this (number) to explicitly set jump length
    --]]
    s = renoise.song()
    local e_step = explicit_step or s.transport.edit_step
    if e_step == 0 then
        if preferences.zero_tweak.value == true then
            if preferences.zero_tweak_method == 1 then
                --move one even if edit step IS 0)
                move_cursor(1 * dir)   
            else
                --move last_nonzero_edit_step even if edit step IS 0)
                move_cursor(last_nonzero_edit_step * dir)   
            end
        else
            --Zero tweak is not active
            --nothing
        end
    else
        --move with edit step
        move_cursor(e_step * dir)
    end
end

--------------------Zeroedit specific functions
--this is run after each edit step change
local function edit_step_was_changed()
    s = renoise.song()
    --zero tweak: store_nonzero_edit_step
    if s.transport.edit_step > 0 then
        last_nonzero_edit_step = s.transport.edit_step
    end
end


--------------------Playback behaviour functions

--For playback tweak
local function get_best_line(edit_step, cur_lin)
    s = renoise.song()
    --get info
    local pat_len = s.selected_pattern.number_of_lines
    --deduce best line
    local best_line
    if pat_len < edit_step then
        --pattern length smaller than edit_step
        --no need to calc best_line
        best_line = 1
    else
        --calc best line
        --normal case
        best_line = math.floor(cur_lin/edit_step)*edit_step + 1
        --test special cases
        if best_line >= pat_len then
            --slipped into next sequence? guard
            best_line = 1
        end
    end
    --return best line
    return best_line or 1 --the 1 is just a safequard for possible nil
end

--General set line function
local function set_line()
    s = renoise.song()
    local e_step = s.transport.edit_step
    if e_step == 0 then
        if preferences.playback_tweak_method.value == 2 then
            e_step = last_nonzero_edit_step
        end
    end
    --if edit_step is something other than 0 or 1, act!
    if e_step > 1 then
        local good_pos = s.transport.edit_pos
        good_pos.line = get_best_line(e_step, good_pos.line)
        s.transport.edit_pos = good_pos
    end
end

--This is run after each change in playback status (start or stop)
local function evaluate_pbt_trigger()
    s = renoise.song()
    if preferences.playback_tweak.value == true then
        --Option is set. Check need to check 
        if s.transport.follow_player == true or preferences.playback_tweak_ignore_follow.value == true then
            --Need to check. Check! Check playback status
            local is_stopped = s.transport.playing == false
            if is_stopped then
                --Do the thing
                set_line()
            end
        end
    else
        --Option is not set. Do nothing
    end
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

    -- This block makes sure a non-modal dialog is shown once.
    -- If the dialog is already opened, it will be focused.
    if dialog and dialog.visible then
        dialog:show()
        return
    end

    -- The ViewBuilder is the basis
    vb = renoise.ViewBuilder()


    -- GUI layout values
    local gui_main_spacing = 8
    local gui_main_margin = 6

    local gui_optcol_w = 200
    local gui_ctrlcol_w = 20 
    local gui_optmargin = 2

    local gui_optcol_w_chooser = 80
    local gui_ctrlcol_w_chooser = gui_optcol_w + gui_ctrlcol_w - gui_optcol_w_chooser

    local gui_group_margin = 4
    local gui_group_spacing = 2
    local gui_group_w = gui_optcol_w + gui_ctrlcol_w + 2*gui_group_margin + 2*gui_optmargin


    --GUI option table for dynamic hiding/showing
    local option_groups = table.create()

    --GUI interact functions
    local function show_option_group(group_name)
        --[[
        Shows a selected option_group, hides others
        --]]
        for option_group, _ in pairs(option_groups) do
            vb.views[option_group.."_option_group"].visible = (option_group == group_name and not vb.views[option_group.."_option_group"].visible)
        end
    end

    -----GUI CREATOR FUNCTIONS
    -- Checkbox option creator
    local function option_checkbox(title_string, bind_node_name_string, tooltip_string)
        local bind_node_full = preferences[bind_node_name_string]
        local option = vb:row{
            margin = gui_optmargin,
            --Option name
            vb:column{
                width = gui_optcol_w,
                vb:text{
                    text = title_string,
                }
            },
            --Option control
            vb:column{
                width = gui_ctrlcol_w,
                vb:checkbox{
                    bind = bind_node_full,
                    tooltip = tooltip_string,
                }
            },
        }
        return option
    end
    local function option_chooser(title_string, bind_node_name_string, tooltip_string)
        local bind_node_full = preferences[bind_node_name_string]
        local title_string = title_string or optionlists[bind_node_name_string.."title"]
        local values_node_full = optionlists[bind_node_name_string.."names"]
        --[[
        --create values table
        local values_table = table.create()
        for i = 1, #values_node_full do
            table.insert(values_table, values_node_full[i].value)
        end
        --]]
        local values_table = values_node_full
        if tooltip_string == nil then
            --create tooltip
            tooltip_string = ""
            for i = 1, #values_table do
                if i > 1 then
                    tooltip_string = tooltip_string.."\n"
                end
                tooltip_string = tooltip_string..values_table[i]
            end
        end
        local option = vb:row{
            margin = gui_optmargin,
            --Option name
            vb:column{
                width = gui_optcol_w_chooser,
                vb:text{
                    text = title_string,
                }
            },
            --Option control
            vb:column{
                width = gui_ctrlcol_w_chooser,
                vb:chooser{
                    items = values_table,
                    bind = bind_node_full,
                    tooltip = tooltip_string,
                }
            },
        }
        return option
    end
    -- Option group creator
    local function option_group(title_string, options_table)
        option_groups[title_string] = true
        local group = vb:row{
            vb:column{
                style = "border",
                margin = gui_group_margin,
                spacing = gui_group_spacing,
                width = gui_group_w,
                --Group title row
                vb:row{
                    --[[
                    --V1.3 title
                    vb:text{
                        font = "bold",
                        text = title_string
                    }
                    --]]
                    vb:button{
                        id = title_string.."_button",    
                        visible = true,
                        width = gui_group_w - (2 * gui_group_margin),
                        height = 10,
                        active = true,
                        text = title_string,
                        notifier = function()
                            show_option_group(title_string)
                        end,
                    }
                },
                --Group options
                vb:row{
                    style = "group",
                    id = title_string.."_option_group",
                    visible = false,
                    vb:column{
                        unpack(options_table)
                    }
                }
            }
        }
        return group
    end

    -----CREATE GUI ELEMENTS FOR OPTIONS
    -- Zero Tweak option
    local opt_zerotweak = option_checkbox(
        "Enable moving with up/dn when ES=0",
        "zero_tweak",
[[Allow EditStep navigation when ES=0.
NOTE: Ensure you've rebound ES Navigation keys.]]
        )
    local opt_zerotweak_method = option_chooser(
        nil,
        "zero_tweak_method"
        )

    -- No Ram options
    local opt_noram_top = option_checkbox(
        "No ramming in top",
        "noram_top",
[[Don't move cursor if ES navigation would ram
pattern sequence TOP in continuous mode.
NOTE: Ensure you've rebound ES Navigation keys.]]
        )
    local opt_noram_bottom = option_checkbox(
        "No ramming in bottom",
        "noram_bottom",
[[Don't move cursor if ES navigation would ram
pattern sequence BOTTOM in continuous mode.
NOTE: Ensure you've rebound ES Navigation keys.]]
        )

    -- Playback Tweak options
    local opt_playbacktweak = option_checkbox(
        "Align to grid when stopping playback",
        "playback_tweak",
[[When you stop playback, let tool align the
cursor automatically to the editstep grid.]]
        )
    local opt_playbacktweak_method = option_chooser(
        nil,
        "playback_tweak_method"
        )
    local opt_playbacktweak_ignore_follow = option_checkbox(
        "Ignore follow playback state",
        "playback_tweak_ignore_follow",
[[Enable this if you want this tweak to activate
even when pattern follow is turned off]]
        )

    -- Extra wrapping options
    local opt_wrap_song = option_checkbox(
        "Wrap song in continuous edit mode",
        "wrap_song",
[[Enable this to wrap around entire song when
pattern edit mode is set to continuous.]]
        )

    local opt_wrap_fix = option_checkbox(
        "Wrap pattern in non-cont mode",
        "wrap_fix",
[[Enable this to make EditStep movement 
respect the wrapping setting like normal
movement keys do.]]
        )

    -----CREATE THE GUI
    -- The content of the dialog, built with the ViewBuilder.
    local content = vb:column {
        id = "main_content",
        margin = gui_main_margin,
        spacing = gui_main_spacing,
        option_group("ZEROEDIT", {opt_zerotweak, opt_zerotweak_method}),
        option_group("NO RAMS", {opt_noram_top, opt_noram_bottom}),
        option_group("PLAYBACK", {opt_playbacktweak, opt_playbacktweak_ignore_follow, opt_playbacktweak_method}),
        option_group("WRAPPING", {opt_wrap_song, opt_wrap_fix}),
    } 

    -- A custom dialog is non-modal and displays a user designed
    -- layout built with the ViewBuilder.   
    dialog = renoise.app():show_custom_dialog(tool_name, content)  

end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:"..tool_name.."...",
    invoke = show_dialog  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Move to Prev.Row w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(-1)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Move to Next Row w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(1)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Jump 16 Rows Up w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(-1, 16)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Jump 16 Rows Dn w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(1, 16)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Jump 1 Row Up w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(-1, 1)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Jump 1 Row Dn w/ EditStepTweak",
    invoke = function()
        move_edit_step_tweak(1, 1)
    end
}
renoise.tool():add_keybinding {
    name = "Pattern Editor:Navigation:Align cursor to EditStep grid",
    invoke = function()
        set_line()
    end
}



--------------------------------------------------------------------------------
-- Setup notifier handling
--------------------------------------------------------------------------------
--- Playback tweak, zeroedit notifiers (always present)
local function boot()
    s = renoise.song()
    --playback tweak trigger: watch playback state
    if not s.transport.playing_observable:has_notifier(evaluate_pbt_trigger) then
        s.transport.playing_observable:add_notifier(evaluate_pbt_trigger)
    end
    --zeroedit: watch edit step value
    if not s.transport.edit_step_observable:has_notifier(edit_step_was_changed) then
        s.transport.edit_step_observable:add_notifier(edit_step_was_changed)
    end
    --When first booting, update this:
    edit_step_was_changed()
end

if not renoise.tool().app_new_document_observable:has_notifier(boot) then
    renoise.tool().app_new_document_observable:add_notifier(boot)
end


local function shutdown()
    --playback tweak
    if s.transport.playing_observable:has_notifier(evaluate_pbt_trigger) then
        s.transport.playing_observable:remove_notifier(evaluate_pbt_trigger)
    end
    --zeroedit
    if s.transport.edit_step_observable:has_notifier(edit_step_was_changed) then
        s.transport.edit_step_observable:remove_notifier(edit_step_was_changed)
    end

    s = nil
end

if not renoise.tool().app_release_document_observable:has_notifier(shutdown) then
    renoise.tool().app_release_document_observable:add_notifier(shutdown)
end



--------------------------------------------------------------------------------
-- Preferences handling
--------------------------------------------------------------------------------

renoise.tool().preferences = preferences




--------------------------------------------------------------------------------
-- Reloading for debug
--------------------------------------------------------------------------------

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
    boot()
end

