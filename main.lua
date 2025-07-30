require "globals"
require "settings"
require "control_panel"
require "downgrade"
require "helper"
require "converter"
require "instrument_settings"
require "check_latest_version"
require "key_bindings"

--[[============================================================================
main.lua
============================================================================]]--

-- XRNX Bundle Layout:

-- Tool scripts must describe themself through a manifest XML, to let Renoise
-- know which API version it relies on, what "it can do" and so on, without 
-- actually loading it. See "manifest.xml" in this exampel tool for more info 
-- please
--
-- When the manifest loads and looks OK, the main file of the tool will be 
-- loaded. This  is this file -> "main.lua".
--
-- You can load other files from here via LUAs 'require', or simply put
-- all the code in here. This file simply is the main entry point of your tool. 
-- While initializing, you can register your tool with Renoise, by creating 
-- keybindings, menu entries or listening to events from the application. 
-- We will describe all this below now:


--------------------------------------------------------------------------------
-- preferences notifiers and attachments
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

-- you can add new menu entries into any existing context menues or the global 
-- menu in Renoise. to do so, we are using the tool's add_menu_entry function.
-- Please have a look at "Renoise.ScriptingTool.API.txt" i nthe documentation 
-- folder for a complete reference.
--
-- Note: all "invoke" functions here are wrapped into a local function(), 
-- because the functions, variables that are used are not yet know here. 
-- They are defined below, later in this file...

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Convert",  
  active = function() return is_app_located end,
  invoke = function() 
    init_converter_dialog();    
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Helper",
  invoke = function() 
    init_helper_dialog();
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Revert to compatibility mode",
  active = function() 
    return is_not_new_song() 
    and is_app_located    
    and renoise.song().transport.timing_model == renoise.Transport.TIMING_MODEL_LPB 
  end,
  invoke = function()
    -- init_downgrade_dialog();
    renoise.app():show_warning('Due to a bugged portamento behaviour found on the Renoise compatible playback engine, this feature is currently disabled')    
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Instrument Settings",  
  active = function() return enable_instrument_settings and is_app_located end,
  invoke = function()     
    init_instrument_settings_dialog();    
  end
}

renoise.tool():add_menu_entry {
  name = "-- Main Menu:Tools:Xrns2XMod:Control Panel",  
  invoke = function() 
    init_controlpanel_dialog();    
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Help:Documentation",  
  invoke = function() 
    renoise.app():open_url(XRNS2XMOD_DOC_URL);
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Help:Video",  
  invoke = function() 
    renoise.app():open_url(XRNS2XMOD_TUTORIAL_VIDEO_URL);      
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Help:Check latest version",  
  invoke = function() 
    check_latest_version()
  end
}

renoise.tool():add_menu_entry {
  
  name = "Main Menu:Tools:Xrns2XMod:Create new:MOD",  
  active = function() return is_app_located end,
  invoke = function() 
  
    local arr_path = {get_resource_path(), 'templates', 'empty_mod.xrns'}
    
    local filename = concatenate_path(arr_path)
    
    if io.exists(filename) then    
      renoise.app():load_song(filename)
    else
      renoise.app():show_error(MSG_RESOURCE_NOT_FOUND)
    end
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Create new:XM",  
  active = function() return is_app_located end,
  invoke = function() 
  
    local arr_path = {get_resource_path(), 'templates', 'empty_xm.xrns'}
    
    local filename = concatenate_path(arr_path)
  
    if io.exists(filename) then
      renoise.app():load_song(filename)
    else
      renoise.app():show_error(MSG_RESOURCE_NOT_FOUND)
    end
    
  end
}

--[[
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Examples:XM Test",  
  active = function() return is_app_located end,
  invoke = function() 
  
    local filename = get_resource_path( 'test_xm.xrns' )
  
    if io.exists(filename) then
      renoise.app():load_song(filename)
    else
      renoise.app():show_error(MSG_RESOURCE_NOT_FOUND)
    end
    
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Xrns2XMod:Examples:MOD Test",  
  active = function() return is_app_located end,
  invoke = function() 
  
    local filename = get_resource_path( 'test_mod.xrns' )
  
    if io.exists(filename) then
      renoise.app():load_song(filename)
    else
      renoise.app():show_error(MSG_RESOURCE_NOT_FOUND)
    end
    
  end
}
]]

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------  

--------------------------------------------------------------------------------
-- startup functions
--------------------------------------------------------------------------------  

function add_examples_menu_entries()

  if is_app_located then
  
    local arr_path = {get_resource_path(), 'examples'}
    
    local examples_path = concatenate_path(arr_path)
    
    -- check examples directory exists
    if io.exists(examples_path) then
    
      local files = os.filenames(examples_path, '*.xrns');      
      
      for index, filename in ipairs(files) do   
        
        local entry_name = ("Main Menu:Tools:Xrns2XMod:Examples:%s"):format(filename)
         
        renoise.tool():add_menu_entry {
          name = entry_name,
          active = function() return is_app_located end,
          invoke = function() 
            
            local complete_filename = concatenate_path( {examples_path, filename} )
            
            if io.exists(complete_filename) then
              renoise.app():load_song(complete_filename)
            else
              renoise.app():show_error(MSG_RESOURCE_NOT_FOUND)
            end
            
          end
        }                
      end    
      
    end
    
  end

end

local function startup()

  check_app_location()
  
  add_examples_menu_entries()
    
end

startup()

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

-- You can attach and detach from a set of script related notifications at any 
-- time. Please see renoise.Document.API.txt -> Observable for more info

-- Invoked, as soon as the application became the foreground window,
-- for example when you alt-tab'ed to it, or switched with the mouse
-- from another app to Renoise.


my_options.convfreq:add_notifier(function() convfreq = my_options.convfreq.value end)

my_options.initial_tempo:add_notifier(function() initial_tempo = my_options.initial_tempo.value end)

my_options.initial_ticks:add_notifier(function() initial_ticks = my_options.initial_ticks.value end)

my_options.conv_type_value:add_notifier(function() conv_type_value = my_options.conv_type_value.value end)

--my_options.ptmode:add_notifier(function() ptmode = my_options.ptmode.value end)

my_options.portamento_accuracy_threshold:add_notifier(function() portamento_accuracy_threshold = my_options.portamento_accuracy_threshold.value end)

my_options.modvol:add_notifier(function() modvol = my_options.modvol.value end)

my_options.bass_email:add_notifier(function() bass_email = my_options.bass_email.value; end)

my_options.bass_code:add_notifier(function() bass_code = my_options.bass_code.value end)

my_options.fmt_note_validation:add_notifier(function() fmt_note_validation = my_options.fmt_note_validation.value end)

my_options.enable_note_validation:add_notifier(function() enable_note_validation = my_options.enable_note_validation.value end)

my_options.enable_instrument_settings:add_notifier(function() enable_instrument_settings = my_options.enable_instrument_settings.value end)
my_options.app_path:add_notifier(function() 

  app_path = my_options.app_path.value 
  
  check_app_location()
  
  add_examples_menu_entries()
  
end)

-- Invoked as soon as the application becomes the foreground window.
-- For example, when you ATL-TAB to it, or activate it with the mouse
-- from another app to Renoise.
renoise.tool().app_became_active_observable:add_notifier(function()
 
end)
  
-- Invoked, as soon as the application looses focus, another app
-- became the foreground window.
renoise.tool().app_resigned_active_observable:add_notifier(function()
 
end)
  
-- Invoked periodically in the background, more often when the work load
-- is low. less often when Renoises work load is high.
-- The exact interval is not defined and can not be relied on, but will be
-- around 10 times per sec.
-- You can do stuff in the background without blocking the application here.
-- Be gentle and don't do CPU heavy stuff in your notifier!
renoise.tool().app_idle_observable:add_notifier(function()
  
end)
  
-- Invoked right before a document (song) gets replaced with a new one. The old 
-- document is still valid here.
renoise.tool().app_release_document_observable:add_notifier(function()
  
end)

-- Invoked each time a new document (song) was created or loaded.
renoise.tool().app_new_document_observable:add_notifier(function()
  
  -- attach notifier for tpl changes
  notifier.add(renoise.song().transport.tpl_observable, update_tpl)  
  
  -- attach notifier for note validation
  toggle_notifier_for_note_validation(enable_note_validation)
  
  -- attach notifier for instrument settings
  toggle_notifier_for_instrument_settings(enable_instrument_settings)
    
  -- load initial bpm and tpl
  initial_tempo = renoise.song().transport.bpm <= MAX_BPM and renoise.song().transport.bpm or MAX_BPM
  
  initial_ticks = renoise.song().transport.tpl
  
  if converter_dialog and converter_dialog.visible then
    converter_dialog:close()
  end
  
  if helper_dialog and helper_dialog.visible then
    helper_dialog:close()
  end
  
  if downgrade_dialog and downgrade_dialog.visible then
    downgrade_dialog:close()
  end
  
  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel_dialog:close()
  end  
  
  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:close()
  end  
    
  load_ini_settings()  
  
  output_file = ''
  
  --[[
  
  local function progress(progress_obj)
    print('inside progress')
    --oprint(progress_obj)
  end
  
  local function success(data, text_status, xml_http_request)    
    print('inside success')
    print('data..')
    rprint(data)
    print('text_status..')
    rprint(text_status)    
    print('xml_http_request..')
    rprint(xml_http_request)
    
    print('XmlParser..')
    local obj = XmlParser:ParseXmlText(data)
    rprint(obj)
    print('yes')
    for k, v in ipairs(obj['ChildNodes']) do
      print('key' .. k)
      print('value' .. v)
    end
  end
  
  local function complete(xml_http_request, text_status)   
    print('inside complete')
  end
  
  local function error(xml_http_request, text_status, error_thrown)   
    print('inside error')
  end
  
  local data = {}
  
  --local a = HTTP:get('http://windowsloganalyzer.com/downloads/xrns2xmod_updater.xml', data, success)
  
  --local a = HTTP:download_file('http://windowsloganalyzer.com/downloads/xrns2xmod_updater.xml', data, success, complete, error)
  
  local text = '<versioninformation>'..'<latestversion>4.0.0.0</latestversion>'..
  '<latestversionurl>http://xrns2xmod.codeplex.com</latestversionurl>'..
  '<latestversiondate>25-03-2016</latestversiondate>'..
  '</versioninformation>'
  
  local obj = XmlParser:ParseXmlText(text)
  rprint(obj)
  for k, v in ipairs(obj['ChildNodes']) do
    if v['Name'] ~= nil and v['Name'] == 'latestversion' then
      print(v['Value'])
    end
  end
  
  ]]
end)

-- Invoked each time the apps document (song) was successfully saved.
renoise.tool().app_saved_document_observable:add_notifier(function()
  
end)

--------------------------------------------------------------------------------
-- debug hook
--------------------------------------------------------------------------------

-- This hook helps you testing & debugging your script while editing
-- it with an external editor or with Renoises built in script editor:
--
-- As soon as you save your script outside of the application, and then
-- focus the app (alt-tab to it for example), your script will get instantly
-- reloaded and your notifier is called.
-- You can put a test function into this notifier, or attach to a remote
-- debugger like RemDebug or simply nothing, just enable the auto-reload
-- functionality by setting _AUTO_RELOAD_DEBUG = true .
--
-- When editing script with Renoises built in editor, tools will automatically
-- reload as soon as you hit "Run Script", even if you don't have this notifier
-- set, but you nevertheless can use this to automatically invoke a test
-- function.
---
-- Note: When reloading the script causes an error, the old, last running
-- script instance will continue to run.
--
-- Finally: Changes in the actions menu may not be updated for new tools, 
-- unless you reload all tools manually with 'Reload Tools' in the menu.

_AUTO_RELOAD_DEBUG = function()
  
end
-- or _AUTO_RELOAD_DEBUG = true
