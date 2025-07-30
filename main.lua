--------------------------------------------------------------------------------
-- GUI Automation Recorder
-- by J. Raben a.k.a. ffx
-- v1.18
--------------------------------------------------------------------------------

TRACE = function () end
_trace_filters = nil
_clibroot = 'lib/cLib/classes/'
require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require ('lib/lib-configurator')


--------------------------------------------------------------------------------

class "GUIAutomationRecorder"

GUIAutomationRecorder.statusDelay = 1
GUIAutomationRecorder.configurator = nil
GUIAutomationRecorder.configuratorC = nil
GUIAutomationRecorder.config = nil
GUIAutomationRecorder.configC = nil
GUIAutomationRecorder.toggle = false
GUIAutomationRecorder.commandQueue = {}
GUIAutomationRecorder.commandQueueSize = 0
GUIAutomationRecorder.idleCounter = 0
GUIAutomationRecorder.idleFunc = nil
GUIAutomationRecorder.menuFunc = nil
GUIAutomationRecorder.instrumentsFunc = nil
GUIAutomationRecorder.dspDeviceSelectObserver = nil

GUIAutomationRecorder.defaultConfigC = {
    instrument_used_indexes = {}, 
    instrument_used_index = {}, 
}

--------------------------------------------------------------------------------
-- Default Config
--------------------------------------------------------------------------------

GUIAutomationRecorder.defaultConfig = {
    timeoutListening = 5, 
    maxParameters = 0, 
    autoEdit = true, 
    autoAutomationView = true, 
    theOneAndOnlyMode = true, 
    requiredDeltaToActivate = 0.2, 
    doTempTPL1 = false, 
    addContextMenus = true, 
    findAutomDeviceInTracks = true, 
}
GUIAutomationRecorder.configDescription = {
    timeoutListening = {type = "number", txt = "Timeout for “setup automation device”. Default is 5."}, 
    maxParameters = {type = "number", txt = "Maximum observed vst parameters. Set to 0 to disable limitation."}, 
    autoEdit = {type = "boolean", txt = "Auto-enables edit mode while invoking shortcut"}, 
    autoAutomationView = {type = "boolean", txt = "Auto-enables automation view for the specific parameter"}, 
    theOneAndOnlyMode = {type = "boolean", txt = "Recommended mode for recording only one parameter per time."}, 
    requiredDeltaToActivate = {type = "number", txt = "number (0…1) - Activation delta for theOneAndOnlyMode, if there already is automation, e.g. how strong to move the handle for activation"}, 
    doTempTPL1 = {type = "boolean", txt = "Workaround to improve recording precision. Usually not required anymore. Default is false."}, 
    addContextMenus = {type = "boolean", txt = " Can slowdown the GUI on macOS. Set to false, if you anyway use shortcuts."}, 
    findAutomDeviceInTracks = {type = "boolean", txt = "Auto-selects track with existing automation device"}, 
}


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function GUIAutomationRecorder:clearStatusFunc()
    if (self.statusTimerFunc ~= nil and renoise.tool():has_timer(self.statusTimerFunc)) then
        renoise.tool():remove_timer(self.statusTimerFunc)
        self.statusTimerFunc = nil
    end
end 

function GUIAutomationRecorder:showStatusDelayed(message)
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

function GUIAutomationRecorder:get_fractional_line_pos()
    local rns = renoise.song()
    
    --xlib way raw
    local beats, line
    if (rns.transport.playing) then
        beats = cLib.fraction(rns.transport.playback_pos_beats)
        line = rns.transport.playback_pos.line
    else 
        beats = cLib.fraction(rns.transport.edit_pos_beats)
        line = rns.transport.edit_pos.line
    end
    local beats_scaled = beats * rns.transport.lpb
    local line_in_beat = math.floor(beats_scaled)
    local fraction = cLib.scale_value(beats_scaled, line_in_beat, line_in_beat + 1, 0, 1)
    
    --local sequence = rns.transport.playback_pos.sequence
    local line_fract = line + fraction
    
    return line_fract 
end


function GUIAutomationRecorder:register_keys()

    local toolName = "Autom. Tool"
    local instrument_notifiers = {}
    local global_instrument = nil
    local global_instrument_name = nil
    local global_instrument_num = nil
    local automation_timer_func = nil
    local aut_pointer = {}
    local last_automation_value = {}
    local first_automation_value = {}
    local backup_tpl = nil
    local tpl_back_func
    local modeDoRecord = nil
    local modeIsInstrument = nil
    local savedEditMode = nil
    local last_index = -1
    local instrDevPath = "Audio/Effects/Native/*Instr. Automation"


    tpl_back_func = function()
        local sng = renoise.song()
        if (backup_tpl ~= nil) then
            sng.transport.tpl = backup_tpl
        end
        if (renoise.tool():has_timer(tpl_back_func)) then
            renoise.tool():remove_timer(tpl_back_func)
        end
    end

    local clear_automation_timer = function()
        if (automation_timer_func ~= nil and renoise.tool():has_timer(automation_timer_func)) then
            renoise.tool():remove_timer(automation_timer_func)
        end
    end 

    local add_automation_timer = function()
        clear_automation_timer()
        local timeoutVal = 1
        if (not self.config.autoEdit or not modeDoRecord) then
            timeoutVal = 1000 * self.config.timeoutListening
        end
        renoise.tool():add_timer(automation_timer_func, timeoutVal)
    end 

    -- edit mode observation
    local editModeObserver = function()
        local sng = renoise.song()
        -- start timeout
        if (sng.transport.edit_mode == false) then
            add_automation_timer()
        else
            clear_automation_timer()
        end
    end

    -- clear
    local remove_param_notifiers = function()
        local sng = renoise.song()

        --Clear instrument plugin notifiers if they are already filled
        if (global_instrument ~= nil and #global_instrument.parameters > 0) then
            local vst_parameters = global_instrument.parameters

            local maxParameters = #vst_parameters
            if (type(self.config.maxParameters) == "number" and maxParameters > self.config.maxParameters and self.config.maxParameters > 0) then
                maxParameters = self.config.maxParameters
            end
            local found = false
            for x = 1, maxParameters do
                local func_ref = 'i'..tostring(global_instrument_name) .. 'p'..tostring(x)

                if instrument_notifiers[func_ref] ~= nil then
                    found = true
                    if vst_parameters[x].value_observable:has_notifier(instrument_notifiers[func_ref]) then
                        vst_parameters[x].value_observable:remove_notifier(instrument_notifiers[func_ref])
                    end
                    instrument_notifiers[func_ref] = nil

                end

            end
            -- save config to file comment
            if (found) then
                --print("saving comment")
                if (self.configuratorC ~= nil) then
                    self.configuratorC:setConfig(self.configC)
                end
            end
        end
        
        --if (backup_tpl ~= nil) then
        --  sng.transport.tpl = backup_tpl
        --  backup_tpl = nil
        --end
        --global_instrument = nil

        clear_automation_timer()
        instrument_notifiers = {}
        if (sng.transport.edit_mode_observable:has_notifier(editModeObserver)) then
            sng.transport.edit_mode_observable:remove_notifier(editModeObserver)
        end
    end

    automation_timer_func = function()
        remove_param_notifiers()
        self.toggle = false
        if (modeIsInstrument) then
            self:showStatusDelayed("Stopped listening for controls' movements of instr. #"..global_instrument_num.. ".")
        else
            self:showStatusDelayed("Stopped listening for controls' movements of effect " .. global_instrument_name .. ".")
        end

    end

    -- check for existing automation dev. made by this script
    local searchTrackForDevice = function (thisTrack, thisDevname) 
        --[[ TODO 
                    new way for Renoise 3.2++, if Taktik will make
                    <LinkedInstrument> available in active preset data

                    for y = 2, #thisTrack.devices do
                        -- found instr auto device
                        if (thisTrack.devices[y].device_path == instrDevPath) then 
                            -- analyze active-preset-data for the target instrument
                            target_string = thisTrack.devices[y].active_preset_data
                            --print(thisTrack.devices[y]:parameter(1).value)
                            --print(target_string)

                            -- replace parameter number
                            search_pattern = "<LinkedInstrument>"
                            
                            -- str_end == nil --> not found
                            str_start, str_end = string.find(target_string, search_pattern)
                            str_start2 = string.find(target_string, "<", str_end)
                            
                            target_string = string.sub(target_string, str_end + 1, str_start2 - 1)

                            if (target_string == cur_ins_num) then
                                return thisTrack.devices[y]
                            end

                        end
                    end
                    ]]--
        for y = 2, #thisTrack.devices do
            local thisDevice = thisTrack:device(y)
            if (thisDevice and thisDevice.display_name == thisDevname and thisDevice.device_path == instrDevPath) then
                return thisDevice
            end
        end
        return nil
    end

    -- start
    local get_active_instrument_parameters = function(params)
        local sng = renoise.song()
        local rna = renoise.app()
        local sc = self.configC

        local cur_ins, cur_ins_num, cur_ins_name
        local plugin_device, plugin_device_observable
        local match_str, match_str_vst
        local target_device = nil
        local theOneAndOnlys = {}
        local theOneAndOnlysSize = 0
        local theOneAndOnlyTimestamp = nil
        local setupAutoDeviceParam = {}
        local activeAutomationParam = {}

        local devname, current_index
        local target_string, str_start, str_end, str_start2, search_pattern, old_x, visible_pages, old_visible_pages
        local str_start3, txtMsg
        local MAXIMUM_AUTOMATION_DEVICE_SLOTS = 35
        local writeahead = nil
        local target_track
        local target_track_index
        local idleWindow = 2

        modeDoRecord = params.doRecord
        modeIsInstrument = params.isInstrument

        first_automation_value = {}
        last_automation_value = {}
        aut_pointer = {}
        savedEditMode = nil
        last_index = -1


        if (modeIsInstrument) then
            cur_ins = sng.selected_instrument
            cur_ins_num = sng.selected_instrument_index
            plugin_device_observable = sng.instruments_observable
            --cur_ins_name = cur_ins.name
            cur_ins_name = toolName
        else
            cur_ins = sng.selected_track_device
            if (cur_ins == nil) then
                return
            end
            cur_ins_num = sng.selected_track_device_index
            cur_ins_name = cur_ins.name
            plugin_device_observable = sng:track(sng.selected_track_index).devices_observable
            if (not cur_ins.external_editor_available) then

                -- take over instr device
                if (cur_ins.device_path == instrDevPath) then 
                    if (renoise.app():show_prompt(toolName.." - Device Take-Over", "Do you want to take over this Instrument Automation Device, so it will be used by GUI Automation Recorder?\n\nMake sure you have selected the fitting instrument right now!", {"Cancel", "Ok"}) == "Ok") then
                        -- remove (...) part
                        --str_start3 = string.find(cur_ins_name, " (", 1, true)
                        --if (str_start3 ~= nil) then 
                        --    cur_ins_name = string.sub(cur_ins_name, 1, str_start3 - 1)
                        --end
                        -- add instr num to name
                        cur_ins_name = toolName .. " (#" .. (string.format("%02X", sng.selected_instrument_index - 1)) .. ")" 
                        cur_ins.display_name = cur_ins_name.." automation"
                        match_str = cur_ins_name
                        --match_str = toolName --- for per instrument comments
                        sc.instrument_used_index[match_str] = 0
                        modeIsInstrument = true
                        for x = 1, #cur_ins.parameters do
                            -- take over automated parameters
                            if (cur_ins.parameters[x].is_automated) then
                                match_str_vst = match_str .. tostring(x)
                                sc.instrument_used_indexes[match_str_vst] = sc.instrument_used_index[match_str]
                                sc.instrument_used_index[match_str] = sc.instrument_used_index[match_str] + 1
                            end

                        end
                        cur_ins_name = toolName
                        cur_ins = sng.selected_instrument
                        cur_ins_num = sng.selected_instrument_index
                        plugin_device_observable = sng.instruments_observable
                        
                    else
                        return
                    end
                else
                    return
                end
            end
        end
        
        -- manual stop
        if (self.toggle == true) then

            self.toggle = false
            remove_param_notifiers()
            
            if (params.doRecord) then
                self:showStatusDelayed("Recording controls' movements stopped manually.")
                if (self.config.autoEdit and savedEditMode ~= nil) then
                    sng.transport.edit_mode = savedEditMode
                end
            else
                self:showStatusDelayed("Listening for controls' movements stopped manually.")
            end
            
            -- invoke 
        else 
            -- remove (...) part
            --str_start3 = string.find(cur_ins_name, " (", 1, true)
            --if (str_start3 ~= nil) then 
            --    cur_ins_name = string.sub(cur_ins_name, 1, str_start3 - 1)
            --end
            
            -- add instr num to name
            cur_ins_name = cur_ins_name .. " (#" .. (string.format("%02X", cur_ins_num - 1)) .. ")" 
            --cur_ins_name = string.gsub(cur_ins_name, "(.+) \((.*)\)$", "%1 (#"..cur_ins_num..")")
            
            backup_tpl = sng.transport.tpl
            
            
            global_instrument = cur_ins
            global_instrument_name = cur_ins_name
            global_instrument_num = string.format("%02X", cur_ins_num - 1)
            

            if (modeIsInstrument) then
                local plugin_properties = cur_ins.plugin_properties
                
                if plugin_properties == nil or plugin_properties.plugin_loaded == false then
                    global_instrument = nil
                    global_instrument_name = nil
                    global_instrument_num = nil
                    return
                end
                plugin_device = plugin_properties.plugin_device
                global_instrument = plugin_properties.plugin_device
            else
                plugin_device = cur_ins
            end

            
            if plugin_device.external_editor_available then
                plugin_device.external_editor_visible = true
            end
            
            remove_param_notifiers()

            local vst_parameters = plugin_device.parameters
            
            local maxParameters = #vst_parameters
            if (type(self.config.maxParameters) == "number" and maxParameters > self.config.maxParameters and self.config.maxParameters > 0) then
                maxParameters = self.config.maxParameters
            end

            

            self.toggle = true
            if (modeDoRecord) then
                if (modeIsInstrument) then
                    txtMsg = "Recording controls' movements of instr. #"..global_instrument_num.. ". Move all controls that you want to automate..."
                else
                    txtMsg = "Recording controls' movements of effect " .. global_instrument_name .. ". Move all controls that you want to automate..."
                end
                if (not self.config.autoEdit) then
                    txtMsg = txtMsg .. " Enable edit mode for write."
                else
                    txtMsg = txtMsg .. " Quit edit mode to stop."
                end

            else
                txtMsg = "Listening for controls' of instr. #"..global_instrument_num.. ". Move all controls that you want to be added within the next "..self.config.timeoutListening.." seconds..."
            end
            self:showStatusDelayed(txtMsg)
            

            target_track = sng.selected_track
            target_track_index = sng.selected_track_index
            
            -- determine target dsp / automation device
            if (modeIsInstrument) then -- instrument device

                -- setup automation instr device
                devname = cur_ins_name.." automation"
                
                if (self.config.findAutomDeviceInTracks) then
                    for i = 1, #sng.tracks do
                        target_device = searchTrackForDevice(sng:track(i), devname)
                        if (target_device ~= nil) then
                            target_track = sng:track(i)
                            sng.selected_track_index = i
                            -- switch view, if track was changed
                            if (target_track_index ~= i) then
                                rna.window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
                            end
                            target_track_index = i
                            break
                        end
                    end
                else
                    target_device = searchTrackForDevice(target_track, devname)
                end

                match_str = cur_ins_name -- only one automation device per instrument required
                
                -- create device, if none exists
                if (target_device == nil) then
                    target_track:insert_device_at(instrDevPath, 2)
                    target_device = target_track:device(2)
                    target_device.display_name = devname
                end

                --self.configC = self.configuratorC:getConfig()

                -- per instrument comment
                --[[
                match_str = toolName 
               self.configuratorC = LibConfigurator(LibConfigurator.SAVE_MODE.INSTR_COMMENT, self.defaultConfigC, "ffx.tools.GUIAutomationRecorder")
                self.configuratorC:setExtraData(cur_ins)
                self.configC = self.configuratorC:getConfig()
                sc = self.configC
                ]]--
                
            else -- effect device
                match_str = cur_ins_name .. "-" .. target_track_index -- fx can exist in multiple tracks
                target_device = plugin_device
                target_device.is_maximized = true
                --self.configuratorC = nil
            end

            --for y = 1, #target_device.parameters do
            --    print ("param "..y.." is automated: "..tostring(target_device.parameters[y].is_automated))
            --end

            -- plugin deletion notifier handling
            plugin_device_observable:add_notifier(function(event)
                if (event.type == "remove") then
                    self.toggle = false
                    if (modeIsInstrument) then
                        --global_instrument = sng.instruments[event.index]
                    else
                        --rprint(event)
                    end
                    global_instrument = nil
                    automation_timer_func()
                    if (self.config.autoEdit and savedEditMode ~= nil) then
                        sng.transport.edit_mode = savedEditMode
                    end

                    sc.instrument_used_index[match_str] = nil
                    for x = 1, maxParameters do
                        sc.instrument_used_indexes[match_str .. tostring(x)] = nil
                    end
                    self.configuratorC:setConfig(self.configC)
                end

            end)


            -- vst parameter notifiers

            for x = 1, maxParameters do
                local func_ref = 'i'..tostring(cur_ins_name) .. 'p'..tostring(x)
                
                if instrument_notifiers[func_ref] == nil then
                    instrument_notifiers[func_ref] = function()

                        -- disable event if it is not theOneAndOnly
                        if (self.config.theOneAndOnlyMode and theOneAndOnlys[x] == nil and theOneAndOnlyTimestamp ~= nil and theOneAndOnlyTimestamp + idleWindow < self.idleCounter) then
                            if vst_parameters[x].value_observable:has_notifier(instrument_notifiers[func_ref]) then
                                vst_parameters[x].value_observable:remove_notifier(instrument_notifiers[func_ref])
                                --print("exited vst param observation: "..tostring(x))
                            end
                            return
                        end

                        match_str_vst = match_str .. tostring(x)


                        if (modeIsInstrument) then -- instrument device

                            -- determine current index of selected instr. + track
                            if (sc.instrument_used_indexes[match_str_vst]) then
                                current_index = sc.instrument_used_indexes[match_str_vst]
                            else
                                if (sc.instrument_used_index[match_str] == nil) then
                                    sc.instrument_used_index[match_str] = 0
                                end
                                sc.instrument_used_indexes[match_str_vst] = sc.instrument_used_index[match_str]
                                current_index = sc.instrument_used_index[match_str]
                                if (current_index >= MAXIMUM_AUTOMATION_DEVICE_SLOTS - 1) then
                                    self:showStatusDelayed("Maximum number of slots in automation device are used.")
                                    return
                                end
                                sc.instrument_used_index[match_str] = sc.instrument_used_index[match_str] + 1
                            end 
                            
                            --for y = 0, MAXIMUM_AUTOMATION_DEVICE_SLOTS-1 do
                            
                            
                            -- manipulate active_preset_data for setting up vst parameter indexes
                            if (setupAutoDeviceParam[x] == nil) then
                                setupAutoDeviceParam[x] = true
                                target_string = target_device.active_preset_data
                                
                                -- replace parameter number
                                search_pattern = "<ParameterNumber"..current_index..">"
                                
                                -- str_end == nil --> not found
                                str_start, str_end = string.find(target_string, search_pattern)
                                str_start2 = string.find(target_string, "<", str_end)
                                
                                old_x = string.sub(target_string, str_end + 1, str_start2 - 1)
                                
                                target_string = string.gsub(target_string, string.sub(target_string, str_start, str_start2 - 1), "<ParameterNumber"..current_index..">" .. (x - 1))
                                
                                -- replace visible pages
                                visible_pages = math.floor((current_index + 1) / 5) + 1
                                search_pattern = "<VisiblePages>"
                                
                                str_start, str_end = string.find(target_string, search_pattern)
                                str_start2 = string.find(target_string, "<", str_end)
                                
                                old_visible_pages = tonumber(string.sub(target_string, str_end + 1, str_start2 - 1))
                                
                                if (old_visible_pages < visible_pages) then
                                    target_string = string.gsub(target_string, string.sub(target_string, str_start, str_start2 - 1), "<VisiblePages>"..visible_pages)
                                end
                                --oprint(target_string)
                                
                                -- write back active_preset_data
                                target_device.active_preset_data = target_string
                                --target_device:parameter(current_index+1).value = vst_parameters[x].value
                            end

                            
                        else -- effect device
                            current_index = x - 1
                        end
                        
                        
                        if (params.doRecord and sng.transport.edit_mode) then
                            local cur_value = vst_parameters[x].value
                            local sel_param = target_device:parameter(current_index + 1)


                            -- temporarily change TPL to 1 for less errors in graph
                            if (self.config.doTempTPL1) then
                                if (renoise.tool():has_timer(tpl_back_func)) then
                                    renoise.tool():remove_timer(tpl_back_func)
                                end
                                if (sng.transport.tpl > 1) then
                                    backup_tpl = sng.transport.tpl
                                end
                                sng.transport.tpl = 1
                                renoise.tool():add_timer(tpl_back_func, 500)
                            end
                            
                            -- get/create automation
                            local aut_pointer = sng.selected_pattern_track:find_automation(sel_param)
                            if (aut_pointer == nil) then
                                aut_pointer = sng.selected_pattern_track:create_automation(sel_param)
                                -- if there is no automation at all, this parameter will be theOneAndOnly
                                if (self.config.theOneAndOnlyMode) then
                                    if (theOneAndOnlys[x] == nil and (theOneAndOnlyTimestamp == nil or theOneAndOnlyTimestamp + idleWindow >= self.idleCounter)) then
                                        if (theOneAndOnlyTimestamp == nil) then
                                            theOneAndOnlyTimestamp = self.idleCounter
                                        end
                                        theOneAndOnlysSize = theOneAndOnlysSize + 1
                                        theOneAndOnlys[x] = true
                                        --print("added to oneAndOnly: " .. tostring(x))
                                        self:showStatusDelayed("Now writing "..theOneAndOnlysSize.." parameter(s) only.")
                                    end

                                end

                            else
                                if (self.config.theOneAndOnlyMode and theOneAndOnlys[x] == nil) then
                                    --print ("found point")
                                    -- delta only required while playing
                                    local delta
                                    if (sng.transport.playing) then
                                        delta = math.abs(sel_param.value - cur_value)
                                    else
                                        delta = 1
                                    end
                                    if (delta > self.config.requiredDeltaToActivate) then
                                        if (theOneAndOnlys[x] == nil and (theOneAndOnlyTimestamp == nil or theOneAndOnlyTimestamp + idleWindow >= self.idleCounter)) then
                                            if (theOneAndOnlyTimestamp == nil) then
                                                theOneAndOnlyTimestamp = self.idleCounter
                                            end
                                            theOneAndOnlysSize = theOneAndOnlysSize + 1
                                            theOneAndOnlys[x] = true
                                            --print("added to oneAndOnly: " .. tostring(x))
                                            self:showStatusDelayed("Now writing "..theOneAndOnlysSize.." parameter(s) only.")
                                        end
                                        return
                                    end
                                    
                                end

                            end
                            
                            
                            local start_pos = self.get_fractional_line_pos()
                            
                            -- write automation 
                            if (start_pos ~= nil and (not self.config.theOneAndOnlyMode or self.config.theOneAndOnlyMode and theOneAndOnlys[x] ~= nil)) then
                                
                                -- LAST VALUE CHECK
                                if ((last_automation_value[match_str_vst] == nil or last_automation_value[match_str_vst] ~= cur_value)) then --and (sel_param.value ~= cur_value) and (first_automation_value[match_str_vst] == nil or first_automation_value[match_str_vst] ~= cur_value)) then

                                    
                                    --self.commandQueueSize = self.commandQueueSize + 1
                                    --self.commandQueue[self.commandQueueSize] = function() 
                                    -- switch to automation view
                                    if (self.config.autoAutomationView and activeAutomationParam[x] == nil) then
                                        activeAutomationParam[x] = true
                                        if (self.config.theOneAndOnlyMode) then
                                            if (sng.selected_automation_parameter == nil or last_index ~= current_index and sng.selected_automation_parameter.name ~= sel_param.name) then
                                                sng.selected_automation_parameter = sel_param
                                                last_index = current_index
                                            end
                                        else
                                            if (sng.selected_automation_parameter == nil or last_index == -1 and sng.selected_automation_parameter.name ~= sel_param.name) then
                                                sng.selected_automation_parameter = sel_param
                                                last_index = 0
                                            end
                                        end
                                        if (rna.window.active_lower_frame ~= renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION) then
                                            rna.window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
                                        end
                                    end

                                    if (sng.transport.playing) then
                                        writeahead = (sng.transport.bpm * sng.transport.lpb / 200)
                                        aut_pointer:clear_range(start_pos, math.min(renoise.Pattern.MAX_NUMBER_OF_LINES, start_pos + writeahead))
                                    end

                                    aut_pointer:add_point_at(start_pos, cur_value)
                                    --end

                                    
                                end 
                                -- LAST VALUE CHECK END
                                last_automation_value[match_str_vst] = cur_value

                                --if (first_automation_value[match_str_vst] == nil) then
                                --    first_automation_value[match_str_vst] = cur_value
                                --end
                                --vst_parameters[x].value = cur_value
                            end
                            

                            
                        end
                        
                        if (not params.doRecord) then
                            add_automation_timer()
                        end
                        
                        
                    end
                end
                
                if not vst_parameters[x].value_observable:has_notifier(instrument_notifiers[func_ref]) then
                    vst_parameters[x].value_observable:add_notifier(instrument_notifiers[func_ref])
                end
                
            end
            
            if (not(sng.transport.edit_mode_observable:has_notifier(editModeObserver))) then
                sng.transport.edit_mode_observable:add_notifier(editModeObserver)
            end
            
            if (self.config.autoEdit and params.doRecord) then
                savedEditMode = sng.transport.edit_mode
                sng.transport.edit_mode = true
            end

            if (not params.doRecord) then
                add_automation_timer()
            end
            --add_automation_timer(params.doRecord)
            
        end
        
    end

    -- add menu and shortcut entries
    renoise.tool():add_keybinding {
        name = "Global:Tools:Setup automation device", 
        invoke = function()
            get_active_instrument_parameters({doRecord = false, isInstrument = true})
        end
    }
    renoise.tool():add_keybinding {
        name = "Instrument Box:Tools:Setup automation device", 
        invoke = function()
            get_active_instrument_parameters({doRecord = false, isInstrument = true})
        end
    }

    renoise.tool():add_keybinding {
        name = "DSP Chain:Tools:Record GUI controls", 
        invoke = function()
            get_active_instrument_parameters({doRecord = true, isInstrument = false})
        end
    }
    renoise.tool():add_keybinding {
        name = "Instrument Box:Tools:Record GUI controls", 
        invoke = function()
            get_active_instrument_parameters({doRecord = true, isInstrument = true})
        end
    }
    renoise.tool():add_keybinding {
        name = "Mixer:Tools:Record GUI controls", 
        invoke = function()
            get_active_instrument_parameters({doRecord = true, isInstrument = false})
        end
    }
    self.menuFunc = function ()
        --rprint(self.config)
        if (self.config.addContextMenus and not renoise.tool():has_menu_entry("Instrument Box:Setup automation device")) then
            renoise.tool():add_menu_entry ({
                name = "Instrument Box:Setup automation device", 
                invoke = function()
                    get_active_instrument_parameters({doRecord = false, isInstrument = true})
                end
            })
        elseif (not self.config.addContextMenus and renoise.tool():has_menu_entry("Instrument Box:Setup automation device")) then
            renoise.tool():remove_menu_entry("Instrument Box:Setup automation device")
        end

        if (self.config.addContextMenus and not renoise.tool():has_menu_entry("Instrument Box:Record GUI controls")) then
            renoise.tool():add_menu_entry ({
                name = "Instrument Box:Record GUI controls", 
                invoke = function()
                    get_active_instrument_parameters({doRecord = true, isInstrument = true})
                end
            })
        elseif (not self.config.addContextMenus and renoise.tool():has_menu_entry("Instrument Box:Record GUI controls")) then
            renoise.tool():remove_menu_entry("Instrument Box:Record GUI controls")
        end
    end
    self.menuFunc()

    self.idleFunc = function ()
        -- command queue, e.g. for drawing
        -- renoise seems to have a bug regarding automation drawing in app-idle, causing spikes in the automation.
        -- So the drawing is done in the vst-notifier instead.
        -- For reference read the faderport-driver thread.
        --[[
        if (self.commandQueueSize > 0) then
            for x = 1, self.commandQueueSize do
                self.commandQueue[x]()
            end
            self.commandQueue = {}
            self.commandQueueSize = 0
        end
        ]]--
        
        self.idleCounter = (self.idleCounter + 1) % 1000000
        --renoise.tool().app_idle_observable:remove_notifier(idleFunc)
    end

    renoise.tool().app_idle_observable:add_notifier(self.idleFunc)

    
    -- watch instrument name / order changes
    self.instrumentsFunc = function (event)

        
        local sng = renoise.song()
        local cur_ins_num = sng.selected_instrument_index
        local target_device, x, endx, oldI, newI, str_start, str_end
        local sc = self.configC

        local renameConfigCKeys = function (oldIndex, newIndex) 


            -- manipulate as string
            self.configuratorC:setConfig(self.configC)

            local configCStr = self.configuratorC:getConfigString()
            str_end = 1
            while (str_end ~= nil) do
                str_start, str_end = string.find(configCStr, "#"..string.format("%02X", oldIndex))
                if (str_end ~= nil) then
                    configCStr = string.sub(configCStr, 1, str_start) .. string.format("%02X", newIndex)..string.sub(configCStr, str_end + 1)
                    --print("replace "..configCStr)
                end
            end
            self.configuratorC:setConfigString(configCStr)
            self.configC = self.configuratorC:getConfig()
            

            --[[  complicated way on object
           if (sc.instrument_used_index[oldIndex]) then
                sc.instrument_used_index[newIndex] = sc.instrument_used_index[oldIndex]
                sc.instrument_used_index[oldIndex] = nil
                --rprint(sc.instrument_used_index)
                for ind, val in pairs(sc.instrument_used_indexes) do
                    if (string.sub(ind, 1, string.len(oldIndex)) == oldIndex) then
                        --print (newIndex .. string.sub(ind, string.len(oldIndex) + 1, string.len(ind)))
                        sc.instrument_used_indexes[newIndex .. string.sub(ind, string.len(oldIndex) + 1, string.len(ind))] = sc.instrument_used_indexes[oldIndex .. string.sub(ind, string.len(oldIndex) + 1, string.len(ind))]
                        sc.instrument_used_indexes[oldIndex .. string.sub(ind, string.len(oldIndex) + 1, string.len(ind))] = nil
                    end
                end
            end
            ]]--
        end
        
        -- FIXME while swapping configc is messed up
        if (event.type == "swap") then
            for i = 1, #sng.tracks do
                oldI = toolName.." (#" .. (string.format("%02X", event.index1 - 1)) .. ")"
                newI = toolName.." (#" .. (string.format("%02X", event.index2 - 1)) .. ")"
                target_device = searchTrackForDevice(sng:track(i), oldI .. " automation")
                if (target_device ~= nil) then
                    target_device.display_name = newI .. " automation"
                    renameConfigCKeys(event.index1 - 1, event.index2 - 1)
                    break
                end
            end
            
        elseif (event.type == "insert") then
            x = renoise.Song.MAX_NUMBER_OF_INSTRUMENTS - 1
            endx = event.index - 1
            while (x >= endx) do
                for i = 1, #sng.tracks do
                    oldI = toolName.." (#" .. (string.format("%02X", x)) .. ")"
                    newI = toolName.." (#" .. (string.format("%02X", x + 1)) .. ")"
                    target_device = searchTrackForDevice(sng:track(i), oldI .. " automation")
                    if (target_device ~= nil) then
                        target_device.display_name = newI .. " automation"
                        renameConfigCKeys(x, x + 1)
                        break
                    end
                end
                x = x - 1
            end
        elseif (event.type == "remove") then
            x = event.index - 1
            endx = renoise.Song.MAX_NUMBER_OF_INSTRUMENTS
            while (x < endx) do
                for i = 1, #sng.tracks do
                    oldI = toolName.." (#" .. (string.format("%02X", x)) .. ")"
                    newI = toolName.." (#" .. (string.format("%02X", x - 1)) .. ")"
                    target_device = searchTrackForDevice(sng:track(i), oldI .. " automation")
                    if (target_device ~= nil) then
                        target_device.display_name = newI .. " automation"
                        renameConfigCKeys(x, x - 1)
                        break
                    end
                end
                x = x + 1
            end
        end

    end



    -- clear restart on song release
    renoise.tool().app_release_document_observable:add_notifier(function()
        local sng = renoise.song()
        remove_param_notifiers()
        instrument_notifiers = {}
        self.configC.instrument_used_indexes = {}
        self.configC.instrument_used_index = {}
        global_instrument = nil
        global_instrument_name = nil
        global_instrument_num = nil
        self.toggle = false
        if (sng.instruments_observable:has_notifier(self.instrumentsFunc)) then
            sng.instruments_observable:remove_notifier(self.instrumentsFunc)
        end
    end)

    -- load data on song load
    renoise.tool().app_new_document_observable:add_notifier(function()
        local sng = renoise.song()
        local hasEntry

        self.configC = self.configuratorC:getConfig()

        -- add dsp device context menu entry dependent on device type
        self.dspDeviceSelectObserver = function()
            if(sng.selected_track_device_index > 0) then
                hasEntry = renoise.tool():has_menu_entry("DSP Device:Record GUI controls")
                if (sng.selected_track_device.external_editor_available) then
                    if (self.config.addContextMenus and not hasEntry) then
                        renoise.tool():add_menu_entry({
                            name = "DSP Device:Record GUI controls", 
                            invoke = function() get_active_instrument_parameters({doRecord = true, isInstrument = false}) end
                        })
                    end
                elseif (not self.config.addContextMenus and hasEntry or hasEntry) then
                    renoise.tool():remove_menu_entry("DSP Device:Record GUI controls")
                end
                hasEntry = renoise.tool():has_menu_entry("DSP Device:Take over device")
                if (sng.selected_track_device.device_path == instrDevPath) then
                    if (self.config.addContextMenus and not hasEntry) then
                        renoise.tool():add_menu_entry({
                            name = "DSP Device:Take over device", 
                            invoke = function() get_active_instrument_parameters({doRecord = true, isInstrument = false}) end
                        })
                    end
                elseif (not self.config.addContextMenus and hasEntry or hasEntry) then
                    renoise.tool():remove_menu_entry("DSP Device:Take over device")
                end
            end

        end

        if (self.config.addContextMenus and not sng.selected_track_device_observable:has_notifier(self.dspDeviceSelectObserver)) then
            sng.selected_track_device_observable:add_notifier(self.dspDeviceSelectObserver)
        end

        if (not sng.instruments_observable:has_notifier(self.instrumentsFunc)) then
            sng.instruments_observable:add_notifier(self.instrumentsFunc)
        end

    end)




end


function GUIAutomationRecorder:__init()
    self.configurator = LibConfigurator(LibConfigurator.SAVE_MODE.FILE, self.defaultConfig, "config.txt")
    self.config = self.configurator:getConfig()
    self.configurator:addMenu("ffx.tools.GUIAutomationRecorder", self.configDescription, function (newConfig)
        self.config = newConfig
        self.dspDeviceSelectObserver()
        self.menuFunc()
    end)
    self.configuratorC = LibConfigurator(LibConfigurator.SAVE_MODE.COMMENT, self.defaultConfigC, "ffx.tools.GUIAutomationRecorder")
    
end


--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

arInst = GUIAutomationRecorder()
arInst:register_keys()





















