--[[============================================================================
main.lua
============================================================================]]--


-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.


_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value

require "variables"
require "gui"


--------------------------------------------------------------------------------
-- Main functions

function main(dialog_was_open)
  preferences = renoise.Document.create("preferences") {
    master_device = 2,
    master_channel = 0,
    midi_in = false,
    midi_out = false,
    visible_range = 10
  }
  renoise.tool().preferences = preferences
  visible_range = tonumber(preferences.visible_range.value)
  if visible_range < 5 then
    visible_range = 5
  end
  if visible_range > 50 then
    visible_range = 50
  end
  
  instrument = renoise.song().instruments
  instrument_amount = #instrument
  get_device_index()
  get_track_index()
  midi_in_gui = preferences.midi_in.value
  midi_out_gui = preferences.midi_out.value

  if tonumber(preferences.master_device.value) <= #indevices then
  
    if master.device ~= indevices[tonumber(preferences.master_device.value)] then
      master.device = indevices[tonumber(preferences.master_device.value)]
    end
  else
    if master.device ~= indevices[1] then
      master.device = indevices[1]
    end
  end

  if tonumber(preferences.master_channel.value) <= 16 and tonumber(preferences.master_channel.value) >= 0 then
    if master.channel ~= tonumber(preferences.master_channel.value) then
      master.channel = tonumber(preferences.master_channel.value)
    end
  else
    if master.channel ~= 0 then
      master.channel = 0
    end
  end

  enumerate_instruments()
  if dialog_was_open == nil then
    dialog_was_open = true
  end
  
  if (not selector_dialog or not selector_dialog.visible) and dialog_was_open then
    show_dialog(tool_name)
  end
  set_observables()
  --change_from_console = nil
  update_instrument_list()
  toggle_midi_in()
  toggle_midi_out() 
  current_selected_instrument()  


end

--------------------------------------------------------------------------------
function change_from_renoise()
--  change_from_console = nil
  changed_from_renoise = true
  update_changes()
end

function new_document()
  clock = os.clock()
  instrument = renoise.song().instruments
  start_instrument = 1
  if solo_instrument ~= nil then
    solo_instrument = 1
  end
  renoise.song().selected_instrument_index = start_instrument
  --Clear the chain states because this isn't done when loading or creating a new song
  multi_track = false
  local restart_main = true
  if not selector_dialog and not selector_dialog.visible then
    selector_dialog:close()
    restart_main = true
  end
  selector.instrument.chain = {}
  selector.instrument.name = {}
  selector.instrument.track = {}
  selector.instrument.indevice = {}
  selector.instrument.inchannel = {}
  selector.instrument.outdevice = {}
  selector.instrument.outchannel = {}
  instrument_amount = 0
  solo_instrument = nil
  if restart_main then
    main(selector_dialog.visible)
  end
end


function idle_handler()

  local song = renoise.song()
--The pattern line notifer can change when the current selected pattern is changed
--therefore, it is polled for every 10 msecs and existing notifiers are removed as soon
--as the pattern is no longer currently selected.
  for _ = 1, #song.patterns do
    if song.patterns[_]:has_line_notifier(pattern_line_notifier) and 
       _ ~= song.selected_pattern_index then
      song.patterns[_]:remove_line_notifier(pattern_line_notifier) 
    end
  end

--Always set the current pattern in the notify list.    
  if not song.patterns[song.selected_pattern_index]:has_line_notifier(pattern_line_notifier) then
    song.patterns[song.selected_pattern_index]:add_line_notifier(pattern_line_notifier) 
  end
  
  if #change_queue.track > 0 then
    local start_track = change_queue.track[1]
    for x = 1,#change_queue.track do
      if change_queue.track[x] ~= start_track then
        --if more than one track is processed, user probably did a pattern clean or copy or undo
        --in all these cases this trick works fine!
        change_queue.pattern = {}
        change_queue.track = {}
        change_queue.line = {}      
        return
      end 
    end
-- Here we process and empty the change queue (which has been build in the pattern line notifier) 
-- every 10msecs, to prevent overloading, we remove the notifiers before processing the changes
-- as processing the changes would then fire the notifier again!
    if song.patterns[song.selected_pattern_index]:has_line_notifier(pattern_line_notifier) then
      song.patterns[song.selected_pattern_index]:remove_line_notifier(pattern_line_notifier) 
    end
    if renoise.tool().app_idle_observable:has_notifier(idle_handler) then
      renoise.tool().app_idle_observable:remove_notifier(idle_handler)
    end
    for q = 1,#change_queue.track do
      for c = 1, #selector.instrument.chain do
        if selector.instrument.chain[c] == true and 
           change_queue.track[q] == (selector.instrument.track[c]-1) and
           multi_track == true and renoise.song().transport.playing == false then
           duplicate_track_actions(change_queue.pattern[q], change_queue.track[q], change_queue.line[q])
        end
      end
    end
    change_queue.pattern = {}
    change_queue.track = {}
    change_queue.line = {}

--Engaging the notifiers again
    song.patterns[song.selected_pattern_index]:add_line_notifier(pattern_line_notifier) 
    renoise.tool().app_idle_observable:add_notifier(idle_handler)
  end
end

function pattern_line_notifier(pos)

  if pos.pattern ~= renoise.song().selected_pattern_index or renoise.song().transport.playing == true or 
     solo_instrument ~= nil then
    return
  end

  local chained_track = false
  
--Check if tracks are chained at all  
  for _ = 1, #selector.instrument.chain do
    if selector.instrument.chain[_] == true then
      if selector.instrument.track[_]-1 == (pos.track) then
        chained_track = true
        break
      end
    end
  end

--Because if not, we don't need to queue anything here.
  if chained_track then
  --If a pattern change is performed, add the track and line info.
  --Only add tracks that are relevant to us!  
    change_queue.pattern[#change_queue.pattern+1] = pos.pattern
    change_queue.track[#change_queue.track+1] = pos.track
    change_queue.line [#change_queue.line+1] = pos.line
  end
end


function timer()
--  if os.clock()- clock <  1 then
--    print (tostring(os.clock() - clock))
--    return
--  end
--  selector_dialog:close()
  if renoise.tool().app_idle_observable:has_notifier(timer) then
    renoise.tool().app_idle_observable:remove_notifier(timer)
  end
  update_changes()
  
end

function update_changes()
  if (not selector_dialog or not selector_dialog.visible) then
    return
  end
 
  enumerate_instruments()
  get_device_index()
  get_track_index()
  update_instrument_list()
end

function track_alteration()
  if (not selector_dialog or not selector_dialog.visible) then
    return
  end
  
  selector_dialog:close()
  main()
end

function current_selected_instrument()
  if instrument_amount ~= #renoise.song().instruments then
    instrument_amount = #renoise.song().instruments
    start_instrument = 1
    update_range()
    update_instrument_list()
  end
  if solo_instrument ~= nil then    
    solo_instrument = renoise.song().selected_instrument_index
    if solo_instrument > (start_instrument + visible_range-1) then
      start_instrument = solo_instrument - visible_range +1
    end
    if solo_instrument < start_instrument then
      start_instrument = solo_instrument
    end
    master.change = true
    changed_from_renoise = true
    set_solo_instrument()
    changed_from_renoise = true
    
    scrolled = 1
    update_instrument_list()
    scrolled = nil
    master.change = false
    changed_from_renoise = false
  end
  
end

function enumerate_instruments()
  instrument = renoise.song().instruments 

  local device_mark = 0

  for _ = 1, #renoise.song().instruments do
    selector.instrument.name[_] = renoise.song().instruments[_].name
    selector.instrument.track[_] = renoise.song().instruments[_].midi_input_properties.assigned_track
    selector.instrument.inchannel[_] = renoise.song().instruments[_].midi_input_properties.channel
    selector.instrument.outchannel[_] = renoise.song().instruments[_].midi_output_properties.channel
    selector.instrument.indevice[_] = renoise.song().instruments[_].midi_input_properties.device_name
    selector.instrument.outdevice[_] = renoise.song().instruments[_].midi_output_properties.device_name
--checking for midi devices that don't exist in active setup
    local valid_device = false

    for _ = 1, #indevices do
      if indevices[_] ==  selector.instrument.indevice[_] then
        valid_device = true
         break
      end
    end
    if valid_device == false and 
       renoise.song().instruments[_].midi_input_properties.device_name ~= "" then
      selector.instrument.indevice[_] = indevices[1]
    end

    local valid_device = false

    for _ = 1, #outdevices do
      if outdevices[_] ==  selector.instrument.outdevice[_] then
        valid_device = true
         break
      end
    end
    if valid_device == false and 
       renoise.song().instruments[_].midi_output_properties.device_name ~= "" then
      selector.instrument.outdevice[_] = outdevices[1]
    end
    
--Try to set the solo or chain devices if the device-in settings match the solo/chain device
    if selector.instrument.indevice[_] == master.device then
      device_mark = device_mark + 1
      selector.instrument.chain[_] = true
      solo_instrument = _

      if device_mark >1 then
        solo_instrument = nil
      end

    end
    

    if selector.instrument.chain[_] == nil then
      selector.instrument.chain[_] = false
    end

  end

  if device_mark == 1 then
    selector.instrument.chain[solo_instrument] = false
  end
  
end

function set_solo_instrument()
  instrument = renoise.song().instruments 
  
  if solo_instrument == nil then
    return
  end

  for t = 1, #instrument do
    local xins_device = renoise.song().instruments[t].midi_input_properties

    if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
      xins_device.device_name_observable:remove_notifier(change_from_renoise)
    end

    if t==solo_instrument then
      instrument[solo_instrument].midi_input_properties.device_name = master.device
      instrument[solo_instrument].midi_input_properties.channel = master.channel
    else
      instrument[t].midi_input_properties.device_name = "Master"
    end

    if not xins_device.device_name_observable:has_notifier(change_from_renoise) then
      xins_device.device_name_observable:add_notifier(change_from_renoise)
    end

  end

end

function set_chain_instrument(range, value)
  instrument = renoise.song().instruments 
  
  if solo_instrument ~= nil then
    return
  end

  for t = 1, #instrument do
    local xins_device = renoise.song().instruments[t].midi_input_properties

    if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
      xins_device.device_name_observable:remove_notifier(change_from_renoise)
    end
    if (xins_device.channel_observable:has_notifier(change_from_renoise)) then
      xins_device.channel_observable:remove_notifier(change_from_renoise)
    end

    if t== range+start_instrument-1 then
      if value == true then
        xins_device.device_name = master.device
        xins_device.channel = master.channel
      else
        xins_device.device_name = selector.instrument.indevice[t]
        xins_device.channel = selector.instrument.inchannel[t]      
      end

    end


    if not xins_device.device_name_observable:has_notifier(change_from_renoise) then
      xins_device.device_name_observable:add_notifier(change_from_renoise)
    end
    if not xins_device.channel_observable:has_notifier(change_from_renoise) then
      xins_device.channel_observable:add_notifier(change_from_renoise)
    end

  end

end


function spawn_midi_in_properties()
  instrument = renoise.song().instruments 
  get_device_index()
    
  for t = 1,#instrument do
    local xins_device = renoise.song().instruments[t].midi_input_properties
    local device_valid = false
     

    if (xins_device.device_name_observable:has_notifier(change_from_renoise)) then
      xins_device.device_name_observable:remove_notifier(change_from_renoise)
    end
    
    if selector.instrument.indevice[t] ~= nil then    
      xins_device.device_name = selector.instrument.indevice[t]
      xins_device.channel = selector.instrument.inchannel[t]
    end
    
    if not xins_device.device_name_observable:has_notifier(change_from_renoise) then
      xins_device.device_name_observable:add_notifier(change_from_renoise)
    end
    
  end
  
end

function set_observables()
  local song = renoise.song()
  instrument = renoise.song().instruments
  local sel_ins = renoise.song().selected_instrument

--App idle notifier, a function called every 10msecs.
--Perform actions or checks here that require frequent polling but not overloading
--the script-engine.
  if not renoise.tool().app_idle_observable:has_notifier(idle_handler) then
    renoise.tool().app_idle_observable:add_notifier(idle_handler)
  end

--generic instrument change (removed or added instruments)  
  if not (song.instruments_observable:has_notifier(change_from_renoise)) then
    song.instruments_observable:add_notifier(change_from_renoise)
  end

--Fired when the instrument selection in the list changes
  if not (renoise.song().selected_instrument_observable:has_notifier(current_selected_instrument)) then
    renoise.song().selected_instrument_observable:add_notifier(current_selected_instrument)
  end

--Fired if the song is being changed for a loaded one or a new document
  if not (renoise.tool().app_new_document_observable:has_notifier(new_document)) then
    renoise.tool().app_new_document_observable:add_notifier(new_document)
  end
  
--track deletion or insertion
  if not song.tracks_observable:has_notifier(update_changes) then
    song.tracks_observable:add_notifier(update_changes)
  end

--Instrument midi in and midi output proprty monitor
  for t = 1,#song.instruments do

    if not (instrument[t].name_observable:has_notifier(change_from_renoise)) then
      instrument[t].name_observable:add_notifier(change_from_renoise)
    end

    if not (instrument[t].midi_input_properties.assigned_track_observable:has_notifier(change_from_renoise)) then
      instrument[t].midi_input_properties.assigned_track_observable:add_notifier(change_from_renoise)
    end
    
    if not (instrument[t].midi_input_properties.channel_observable:has_notifier(change_from_renoise)) then
      instrument[t].midi_input_properties.channel_observable:add_notifier(change_from_renoise)
    end
    
    if not (instrument[t].midi_input_properties.device_name_observable:has_notifier(change_from_renoise)) then
      instrument[t].midi_input_properties.device_name_observable:add_notifier(change_from_renoise)
    end
    
    if not (instrument[t].midi_output_properties.channel_observable:has_notifier(change_from_renoise)) then
      instrument[t].midi_output_properties.channel_observable:add_notifier(change_from_renoise)
    end
    
    if not (instrument[t].midi_output_properties.device_name_observable:has_notifier(change_from_renoise)) then
      instrument[t].midi_output_properties.device_name_observable:add_notifier(change_from_renoise)
    end
  end

end
--------------------------------------------------------------------------------

function get_device_index()
  local inputs = renoise.Midi.available_input_devices()
  local device_table = {}

  if not selector_dialog or not selector_dialog.visible then  
--    renoise.Midi.devices_changed_observable():remove_notifier(get_device_index)
    --return
  end
  
  for t=1,#inputs+1 do
     master.devices[t] = inputs[t]
    if t==1 then
      device_table[t] = "Master"
      indevices[t] = "Master"
      outdevices[t] = "None"
      master.device = inputs[1]
    else
      device_table[t] = inputs[(t-1)]      
      indevices[t] = device_table[t]
      outdevices[t] = device_table[t]
    end
    
  end
--  devices[#devices+1] = "Renoise OSC Device"  --Doesn't work yet
  
  if (#device_table>1) then
  end

end

function get_track_index()
  tracks = {}
  tracks[1] = "Current"

  for _ = 1, #renoise.song().tracks do

    if renoise.song().tracks[_].type ~= renoise.Track.TRACK_TYPE_MASTER and
       renoise.song().tracks[_].type ~= renoise.Track.TRACK_TYPE_SEND and
       renoise.song().tracks[_].type ~= renoise.Track.TRACK_TYPE_GROUP then
      tracks[_+1] = renoise.song().tracks[_].name
    end

  end

end


function duplicate_track_actions(pattern,track,line)
  --Function to propagate changes to other tracks.
  local song = renoise.song()
  local source_position = song.patterns[pattern].tracks[track]
  
  local chained_instrument = {}
  local chain_number = 0
  
  for _ = 1, #selector.instrument.chain do
    if selector.instrument.chain[_] == true then
      chain_number = chain_number + 1
      chained_instrument[chain_number] = _ -1
    end
  end
  for _ = 1, #chained_instrument do
    local ins_track_index = selector.instrument.track[chained_instrument[_]+1]-1
    local instrument_number = chained_instrument[_]
    
    if ins_track_index > 0 and ins_track_index ~= track then
      for t = 1, song.tracks[track].visible_note_columns do
        local source_line = source_position.lines[line].note_columns[t]
        local target_position = song.patterns[pattern].tracks[ins_track_index].lines[line].note_columns[t]
        target_position.note_value = source_line.note_value
        target_position.volume_value = source_line.volume_value
        target_position.panning_value = source_line.panning_value
        target_position.delay_value = source_line.delay_value
        if source_line.instrument_value == 255 then
          target_position.instrument_value = 255
        else
          target_position.instrument_value = instrument_number
        end
        for d = 1, #chained_instrument do
          if track == chained_instrument[d] then
            if source_line.instrument_value ~= chained_instrument[d] and 
              source_line.note_value < 120 then
                source_line.instrument_value = chained_instrument[d] -1
            end
          end
        end
      end
      for t = 1, song.tracks[track].visible_effect_columns do
        local source_fx_column = song.patterns[pattern].tracks[track].lines[line].effect_columns[t]
        local target_fx_column = song.patterns[pattern].tracks[ins_track_index].lines[line].effect_columns[t]
        target_fx_column:copy_from(source_fx_column)
      end
    else 
      for t = 1, song.tracks[track].visible_note_columns do
        if ins_track_index == track then
          for x = 1,#selector.instrument.track do
            if selector.instrument.track[x]-1 == track and selector.instrument.chain[x] == true then
              if source_position.lines[line].note_columns[t].note_value < 120 then
                source_position.lines[line].note_columns[t].instrument_value = x - 1
              end
              break
            end
          end
        end
      end
    end

  end
end

function key_toggle()
  if (not selector_dialog or not selector_dialog.visible) then
    main()
  else
    selector_dialog:close()
  end
end

function multitrack_toggle()
  multi_track = not multi_track
  local button_multi_track_color = {}
  if multi_track == true then
    button_multi_track_color = {0xff, 0xb6, 0x00}
  else
    button_multi_track_color = {0x2d, 0x11, 0xff}
  end
  if vb ~= nil then
    vb.views['button_multi_track'].color = button_multi_track_color
  end

end
--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Instrument Box:"..tool_name.."...",
  invoke = main  
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = key_toggle
}
renoise.tool():add_keybinding {
  name = "Global:Tools:MMC multitrack edit",
  invoke = multitrack_toggle
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
