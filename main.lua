--[[============================================================================
main.lua
============================================================================]]--

  vb = renoise.ViewBuilder()
 
  local DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = 
    renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_DIALOG_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  local TEXT_ROW_WIDTH = 80
  local dialog = nil
  local progress_slider = nil
  local dialog_content = nil
  
  local proc = nil
  local frames = 0
  local sampleslot = 2
  local source_instrument = nil
  local sampleslot = 2
  local max_samples = nil
  local last_sample = 1 
  local rate = 44100 --default!
  local bits = 16 --default!
  local quit_process = false

  local channels = 2 --default!
  local LAYER_NOTE_ON = renoise.Instrument.LAYER_NOTE_ON
  local ins_name = nil
  local last_idle_time = 0  
  local multi = false


for _,menu in pairs {"Instrument Box", "Sample List", "Sample Editor:Slices"} do
  
  local function sliced_instrument_selected()
     return (#renoise.song().selected_instrument.samples[1].slice_markers > 0) 
  end
  
  renoise.tool():add_menu_entry {
    name = menu .. ":" .. "Copy All Slices to New Instrument",
    active = sliced_instrument_selected,
    invoke = function() 
      multi = false
      main(multi) 
    end
  }    

  renoise.tool():add_menu_entry {
    name = menu .. ":" .. "Copy Each Slice to New Instrument",
    active = sliced_instrument_selected,
    invoke = function() 
      multi = true
      main(true)
    end
  }    
  if menu == "Instrument Box" then
    menu = "Instrument Box:Edit"
  end
  if menu ~= "Sample List" then
    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Copy All Slices to New Instrument",
      invoke = function()
        multi = false
        main(multi)
      end
    }
    
    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Copy Each Slice to New Instrument",
      invoke = function()
        multi = true
        main(true)
      end
    }
  end
  
end


function search_empty_instrument()

    for empty_instrument = 1, #proc.instruments do
      local samples = false
      for i = 1,#proc.instruments[empty_instrument].samples do
        local temp_buffer = proc.instruments[empty_instrument].samples[i].sample_buffer
        if temp_buffer.has_sample_data then
          samples = true
          break
        end
      end
      local plugin = proc.instruments[empty_instrument].plugin_properties.plugin_loaded
      local midi_device = proc.instruments[empty_instrument].midi_output_properties.device_name
      if ((samples == false) and (plugin == false) and 
      (midi_device == nil or midi_device == "")) then
        return empty_instrument
      end
      
    end
    
    proc:insert_instrument_at(#proc.instruments+1)

    return #proc.instruments
end

  local target_instrument = nil
  local ins = nil


function main(go_multi)
  proc = renoise.song()
  source_instrument = proc.selected_instrument_index
  
  local source = proc.instruments[source_instrument]
  local target = proc.instruments[target_instrument]

  multi = go_multi
  last_idle_time = 0  

  ins_name = source.name

  max_samples = #source.samples
  last_sample = max_samples + 1 
  sampleslot = 2

  frames = 0
  rate = 44100 --default!
  bits = 16 --default!
  quit_process = false
  channels = 2 --default!

  LAYER_NOTE_ON = renoise.Instrument.LAYER_NOTE_ON
  local max_meter_value = (1/(max_samples - 1))
  
  if #proc.selected_instrument.samples[1].slice_markers == 0 then
    --current selected instrument has no sample.
    --Don't provide errordialogs on shortcuts
    return
  end
  
  proc.selected_sample_index = 1
  frames = source.samples[1].sample_buffer.number_of_frames

  progress_meter('Current Progress',0,1,max_meter_value)

  if multi == true then
    for t = 1, max_samples - 1 do
      proc:insert_instrument_at(source_instrument+1)
      --You want to have the C-4 one note assigned to each sample? remove below quotes
--      while (#proc.instruments[source_instrument+1].sample_mappings[LAYER_NOTE_ON] > 0) do
--        proc.instruments[source_instrument+1]:delete_sample_mapping_at(LAYER_NOTE_ON, 
--        #proc.instruments[source_instrument+1].sample_mappings[LAYER_NOTE_ON])
--      end

    end
    target_instrument = source_instrument+1
  else
    target_instrument = search_empty_instrument()

    while (#proc.instruments[target_instrument].sample_mappings[LAYER_NOTE_ON] > 0) do
      proc.instruments[target_instrument]:delete_sample_mapping_at(LAYER_NOTE_ON, 
        #proc.instruments[target_instrument].sample_mappings[LAYER_NOTE_ON])
    end
  end
  
  source.samples[1].sample_buffer.selection_start = 1
  source.samples[1].sample_buffer.selection_end = frames

  if not (renoise.tool().app_idle_observable:has_notifier(copy_frames)) then
    renoise.tool().app_idle_observable:add_notifier(copy_frames)
  end

end


function copy_frames()

  if not dialog or not dialog.visible then
    terminate_process()
    return
  end
    
  if (os.clock() - last_idle_time < 0.1) then
    return
  end
  local target_buffer = nil
  local source = proc.instruments[source_instrument]
  local target = proc.instruments[target_instrument]
  local source_sample = source.samples[sampleslot]
  local target_sample = target.samples[sampleslot-1]
  
    if multi == false then
      local dumbo_check = #proc.instruments
      local dumbo_checkb = nil
      if dumbo_check >= target_instrument then
        dumbo_checkb = #target.samples
        if dumbo_checkb < sampleslot-1 then
          --Someone erased a sample in the target instrument
          terminate_process()
          return
        end  
      else
        --Someone erased the target instrument
        terminate_process()
        return
      end
      
      target_buffer = target_sample.sample_buffer
      
    else
      local dumbo_check = #proc.instruments
      if dumbo_check < target_instrument then
        --Someone erased the target instrument
        terminate_process()
        return
      end
      target_buffer = target.samples[1].sample_buffer

    end
    

    if multi == true then
      target_buffer = target.samples[1].sample_buffer
    end
    
    local sample_buffer = source_sample.sample_buffer
    local dont_process = 0
    local cur_meter_value = ((sampleslot - 1) / (max_samples-1))
    vb.views.meter.value = cur_meter_value
    local starttime = os.clock()

    if (sample_buffer == nil or not sample_buffer.has_sample_data) then
--      local message = "sample "..sampleslot.." was empty"
--      print (message)
      dont_process = 1
    end  
    
    if dont_process == 0 then
      rate = source_sample.sample_buffer.sample_rate
      bits = source_sample.sample_buffer.bit_depth
      frames = source_sample.sample_buffer.number_of_frames
      channels = source_sample.sample_buffer.number_of_channels
    end     

    local success = target_buffer:create_sample_data(rate, bits, channels, frames)

    if dont_process == 0 then
      target_buffer:prepare_sample_data_changes()
      for channel = 1, channels do
        for frame = 1, frames do
          target_buffer:set_sample_data(channel, frame, sample_buffer:sample_data(channel, frame))
        end 
 
      end

      target_buffer:finalize_sample_data_changes()

      local target_slot = sampleslot - 1

      if multi == true then
        target_slot = 1
      end
      
      target.samples[target_slot].loop_mode = source_sample.loop_mode
      target.samples[target_slot].loop_start = source_sample.loop_start 
      target.samples[target_slot].loop_end = source_sample.loop_end 
      local name = source_sample.name
      name = string.sub(name,1,string.len(name)-5)
      target.samples[target_slot].name = name
      target.samples[target_slot].panning = source_sample.panning 
      target.samples[target_slot].volume = source_sample.volume 
      target.samples[target_slot].base_note = source_sample.base_note 
      target.samples[target_slot].fine_tune = source_sample.fine_tune 
      target.samples[target_slot].beat_sync_enabled = source_sample.beat_sync_enabled
      target.samples[target_slot].beat_sync_lines = source_sample.beat_sync_lines
      target.samples[target_slot].interpolation_mode = source_sample.interpolation_mode
      target.samples[target_slot].new_note_action = source_sample.new_note_action
      target.samples[target_slot].autoseek = source_sample.autoseek 

      if multi == false then
        target:insert_sample_at(sampleslot)
        local sample_index = target_slot
        local basenote = 47+sample_index
        local new_mapping = target:insert_sample_mapping(LAYER_NOTE_ON, 
        (sample_index), basenote, {basenote,basenote}, {0,127})
      end
           
    end

    if sampleslot < max_samples then
      sampleslot = sampleslot +1
      if multi == true then
        target.name = "[Slice] "..ins_name
        target_instrument = target_instrument + 1      
      end
    else
      if multi == false then
        target:delete_sample_at(#target.samples)
        target.name = "[Sliced] "..ins_name
        proc.selected_instrument_index = target_instrument
      else
        target.name = "[Slice] "..ins_name
        target_instrument = target_instrument + 1      
      end
      renoise.app():show_status('Slices successfully copied')
      sampleslot = 2
      if dialog ~= nil then
        if dialog.visible then
          dialog:close()
        end
      end
      renoise.tool().app_idle_observable:remove_notifier(copy_frames)
    end
    
    last_idle_time = os.clock()
end
  
function progress_meter(title, pmin, pmax, pvalue)
    if dialog == nil then
      progress_slider = vb:row {
        vb:text {
          id="meter_text",
          width = 20,
          text = (pvalue*100).."%"
        },
        vb:minislider {
          id="meter",
          min = pmin,
          max = pmax,
          value = pvalue,
          active = false,
          notifier = function(value)
            vb.views.meter_text.text = (value*100).."%"
          end
        }
      }
      dialog_content = vb:column {
        margin = DIALOG_MARGIN,
        spacing = CONTENT_SPACING,
        vb:row{
          spacing = 4*CONTENT_SPACING,
  
          vb:column {
            spacing = CONTENT_SPACING,
          
            progress_slider, 
          },
        },
      }
    else
      if vb.views.meter.value > 0 then
        vb.views.meter.value = 0
      end
    end
    if not dialog or not dialog.visible then
      dialog = renoise.app():show_custom_dialog(title, dialog_content)
    end    
end

function terminate_process()
  renoise.tool().app_idle_observable:remove_notifier(copy_frames)
  renoise.app():show_status('Slicing aborted')
  if dialog ~= nil then
    if dialog.visible then
      dialog:close()
    end
  end
end



