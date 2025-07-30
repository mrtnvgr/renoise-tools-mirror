--------------------------------------------------------------------------------
-- Insert Native DSP Context Menu
-- by ffx
-- Based on gova's insert_native_dsp tool
--------------------------------------------------------------------------------

TRACE = function () end
_trace_filters = nil
require ('lib/lib-configurator')


--------------------------------------------------------------------------------

local configurator = nil
local config = nil
local addedMenus = {}
local idleFunc = nil


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local defaultConfig = {
    showNewDevices = true, 
    showTwoMenues = false, 
}
local configDescription = {
    showNewDevices = {type = "boolean", txt = "Also show new devices."}, 
    showTwoMenues = {type = "boolean", txt = "Split legacy and recent devices in submenus."}, 
}


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

local tool_name
local t_devnames = {

    Meta = 
    {'*Hydra', '*Instr. Automation', '*Instr. Macros', '*Instr. MIDI Control', '*Key Tracker', '*LFO', '*Meta Mixer', '*Signal Follower', '*Velocity Tracker', '*XY Pad', '*Formula', 'Doofer', 
    }, 
    Delay_Reverb = 
    {'Delay', 'Multitap', 'Convolver', 'mpReverb 2', 'Reverb', 'mpReverb (dep.)', 
    }, 
    Distortion = 
    {'LofiMat 2', 'Cabinet Simulator', 'Distortion 2', 'Exciter', 'Distortion (dep.)', 'Shaper (dep.)', 'LofiMat (dep.)', 'Stutter (dep.)', 
    }, 

    Dynamics = 
    {'Bus Compressor', 'Compressor', 'Gainer', 'Gate 2', 'Maximizer', 'Gate (dep.)', 
    }, 
    EQ_Filter = 
    {'EQ 5', 'EQ 10', 'Mixer EQ', 'Analog Filter', 'Comb Filter 2', 'Digital Filter', 'Comb Filter (dep.)', 'Filter 3 (dep.)', 'Filter (dep.)', 'Filter 2 (dep.)', 'Scream Filter (dep.)', 
    }, 
    Modulation = 
    {'Chorus 2', 'Flanger 2', 'Phaser 2', 'Repeater', 'RingMod 2', 'Chorus (dep.)', 'Flanger (dep.)', 'Phaser (dep.)', 'RingMod (dep.)'
    }, 
    Routing = 
    {'#Line Input', '#Multiband Send', '#ReWire Input', '#Send', '#Sidechain', 
    }, 
    Tools = 
    {'DC Offset', 'Stereo Expander', 'PDC Test Delay', 
    }, 
}



local tll = renoise.tool()
local insertDevice = function(device_name)
    local sng = renoise.song()
    local is_sampleedit = renoise.app().window.active_middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
    
    device_name = string.gsub(string.gsub(device_name, "[()]+", ""), " (dep.)", "")
    
    if sng.selected_device and not is_sampleedit then
        sng.selected_track:insert_device_at('Audio/Effects/Native/'..device_name, sng.selected_device_index + 1)
    elseif not is_sampleedit then
        sng.selected_track:insert_device_at('Audio/Effects/Native/'..device_name, #sng.selected_track.devices + 1)
    elseif sng.selected_sample_device then
        sng.selected_sample_device_chain:insert_device_at('Audio/Effects/Native/'..device_name, sng.selected_sample_device_index + 1)
    else
        sng.selected_sample_device_chain:insert_device_at('Audio/Effects/Native/'..device_name, #sng.selected_sample_device_chain.devices + 1)
    end 
end

local buildMenu = function()
    for x = 1, #addedMenus do
        tll:remove_menu_entry(addedMenus[x])
    end
    addedMenus = {}

    for catname, loc_t_cat in pairs(t_devnames) do
        for x in ipairs(loc_t_cat) do
            local loc_t_devnames = loc_t_cat[x]
            tool_name = "Add Native"
            local devname = loc_t_devnames
            if (not config.showNewDevices) then 
                devname = string.gsub(string.gsub(loc_t_devnames, "[()]+", ""), " (dep.)", "")
                tool_name = "Add Legacy"
                if (devname == loc_t_devnames and config.showTwoMenues == true) then
                    tool_name = "Add Native"
                end
            end
            
            if (config.showNewDevices == true or (loc_t_devnames ~= string.gsub(string.gsub(loc_t_devnames, "[()]+", ""), " (dep.)", "")) or config.showTwoMenues == true) then
                
                tll:add_menu_entry
                {
                    name = "Mixer:"..tool_name..":"..catname..":"..devname, 
                    invoke = function() insertDevice(loc_t_devnames) end
                }
                tll:add_menu_entry
                {
                    name = "DSP Device:"..tool_name..":"..catname..":"..devname, 
                    invoke = function() insertDevice(loc_t_devnames) end
                }
                tll:add_menu_entry
                {
                    name = "Sample FX Mixer:"..tool_name..":"..catname..":"..devname, 
                    invoke = function() insertDevice(loc_t_devnames) end
                }
                addedMenus[#addedMenus + 1] = "Mixer:"..tool_name..":"..catname..":"..devname
                addedMenus[#addedMenus + 1] = "DSP Device:"..tool_name..":"..catname..":"..devname
                addedMenus[#addedMenus + 1] = "Sample FX Mixer:"..tool_name..":"..catname..":"..devname
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

configurator = LibConfigurator(LibConfigurator.SAVE_MODE.FILE, defaultConfig, "config.txt")
config = configurator:getConfig()
configurator:addMenu("ffx.tools.NativeDSPContextMenu", configDescription, function (newConfig)
    config = newConfig
    buildMenu()
end)
buildMenu()

idleFunc = function ()
  renoise.tool().app_idle_observable:remove_notifier(idleFunc)
  buildMenu()
end
renoise.tool().app_idle_observable:add_notifier(idleFunc)



