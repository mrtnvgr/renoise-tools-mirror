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
  local sample_progress_slider = nil
  local frame_progress_slider = nil
  local dialog_content = nil
  
  local KEEP_LEFT = 1
  local KEEP_RIGHT = 2
  local MIX_CONTENT = 3  
  local copy_mode = KEEP_LEFT

  local proc = nil
  local sample_buffer = nil
  local target_buffer = nil
  local start_channel = nil
  local end_channel = nil
  
  local frames = 0
  local current_frame = 1
  local total_frames_to_process = 0
  local total_frames_processed = 0
  local source_instrument = nil
  local sampleslot = 1
  local max_samples = nil
  local last_sample = 1 
  local rate = 44100 --default!
  local bits = 16 --default!
  local channels = 2 --default!
  local ins_name = nil
  local is_sliced = false
  local finish_sample = false
  
  local LAYER_NOTE_ON = renoise.Instrument.LAYER_NOTE_ON
  local LAYER_NOTE_OFF = renoise.Instrument.LAYER_NOTE_OFF
  local last_idle_time = 0  
  local processing_maximum_instruments = 0
  local target_instrument = nil
  local ins = nil
  local quit_process = false
  local session_open = false
  local split_mode = false
    
for _,menu in pairs {"Instrument Box", "Sample List", "Sample Editor:Process"} do
  
  renoise.tool():add_menu_entry {
    name = menu .. ":" .. "Copy left channel to mono (new instrument)",
    invoke = function() 
      copy_mode = KEEP_LEFT
      main()
    end
  }    

  renoise.tool():add_menu_entry { 
    name = menu .. ":" .. "Copy right channel to mono (new instrument)",
    invoke = function() 
      copy_mode = KEEP_RIGHT
      main()
    end
  }    
  renoise.tool():add_menu_entry {
    name = menu .. ":" .."Mixdown stereo channel to mono (new instrument)",
    invoke = function() 
      copy_mode = MIX_CONTENT
      main()
    end
  }    
  renoise.tool():add_menu_entry {
    name = menu .. ":" .. "Split left and right channel to separate instruments",
    invoke = function()
      split_mode = true
      copy_mode = KEEP_LEFT
      main()
    end
  }    
  if menu == "Instrument Box" then
    menu = "Instrument Box:Edit"
  end
  if menu ~= "Sample List" then
    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Copy left channel to mono (new instrument)",
      invoke = function()
        copy_mode = KEEP_LEFT
        main()
      end
    }
    
    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Copy right channel to mono (new instrument)",
      invoke = function()
        copy_mode = KEEP_RIGHT
        main()
      end
    }

    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Mixdown stereo channel to mono (new instrument)",
      invoke = function()
        copy_mode = MIX_CONTENT
        main()
      end
    }
    renoise.tool():add_keybinding {
      name = menu .. ":" .. "Split left and right channel to separate instruments",
      invoke = function()
        split_mode = true
        copy_mode = KEEP_LEFT
        main()
      end
    }
  end
  
end


function reset_status ()
  sample_progress_slider = nil
  frame_progress_slider = nil
  dialog = nil
  sample_progress_slider = nil
  frame_progress_slider = nil
  dialog_content = nil
    
  proc = nil
  sample_buffer = nil
  target_buffer = nil
  start_channel = nil
  end_channel = nil
  
  frames = 0
  current_frame = 1
  total_frames_to_process = 0
  total_frames_processed = 0
  source_instrument = nil
  sampleslot = 1
  max_samples = nil
  last_sample = 1 
  rate = 44100 --default!
  bits = 16 --default!
  channels = 2 --default!
  ins_name = nil
  is_sliced = false
  finish_sample = false
  last_idle_time = 0  
  processing_maximum_instruments = 0
  target_instrument = nil
  ins = nil
  quit_process = false
  session_open = false
  split_mode = false
end


local function sliced_instrument_selected()
  return (#renoise.song().selected_instrument.samples[1].slice_markers > 0) 
end
  
function main()
  --Don't allow for more than one session open at a time!
  if session_open then
    renoise.app():show_status('Sorry, can only process one instrument at a time!')
    return
  else
    session_open = true
  end

  vb = renoise.ViewBuilder()
  
  proc = renoise.song()
  source_instrument = proc.selected_instrument_index 
 
  local source = proc.instruments[source_instrument]
  local target = proc.instruments[target_instrument]
  local stereo_present = false
  
  is_sliced = sliced_instrument_selected()
  processing_maximum_instruments = 0
  quit_process = false
  last_idle_time = 0  

  ins_name = source.name

  max_samples = #source.samples
  if is_sliced then
    max_samples = 1
  end

  local current_sample_progress = (1/max_samples)
  
  sampleslot = 1
  finish_sample = false
  current_frame = 1
  total_frames_processed  = 0
  total_frames_to_process = 0
  
  frames = 0
  rate = 44100 --default!
  bits = 16 --default!
  quit_process = false
  channels = 2 --default!

  LAYER_NOTE_ON = renoise.Instrument.LAYER_NOTE_ON
  
 
  if not source.samples[1].sample_buffer.has_sample_data then
    --current selected instrument has no sample.
    --Don't provide errordialogs on shortcuts
    finish_sample = true
    return
  end

  local current_frame_progress = (1 / source.samples[1].sample_buffer.number_of_frames)

  for j = 1, max_samples do
    if source.samples[j].sample_buffer.has_sample_data then 
      if source.samples[j].sample_buffer.number_of_channels > 1 then
        stereo_present = true
        total_frames_to_process = total_frames_to_process + source.samples[j].sample_buffer.number_of_frames
      end
    end
  end

  if not stereo_present then
    renoise.app():show_status('Instrument only contains mono samples!')
    finish_sample = true
    session_open = false
    sampleslot = 1
    return
  end
  
  proc.selected_sample_index = 1
  frames = source.samples[1].sample_buffer.number_of_frames

  progress_meter('Conversion Progress',current_sample_progress, current_frame_progress)
  vb.views.sample_meter.value = 0
  vb.views.frame_meter.value = 0

  proc:insert_instrument_at(source_instrument+1)
  target_instrument = source_instrument+1
  target = proc.instruments[target_instrument]
  
  target:copy_from(source)

  if is_sliced then
  --Remove slice markers:start from the last marker to the first because 
  --the marker table gets updated on the fly 
  --If you start from the first marker, you get into troubles!!
    for j = #target.samples[1].slice_markers,1, -1 do
      target.samples[1]:delete_slice_marker(target.samples[1].slice_markers[j])
    end
  end

  processing_maximum_instruments = #proc.instruments
  
  if not target.samples_observable:has_notifier(terminate_process) then
    target.samples_observable:add_notifier(terminate_process)
  end

  if not source.samples_observable:has_notifier(terminate_process) then
    source.samples_observable:add_notifier(terminate_process)
  end
  
  source.samples[1].sample_buffer.selection_start = 1
  source.samples[1].sample_buffer.selection_end = frames
  if not (renoise.tool().app_idle_observable:has_notifier(copy_samples)) then
    renoise.tool().app_idle_observable:add_notifier(copy_samples)
  end

end


function copy_samples()
  --In here we duplicate all the samples
  if not dialog or not dialog.visible then
    terminate_process()
    return
  end
  if (os.clock() - last_idle_time < 0.1) then
    return
  end
  local source = proc.instruments[source_instrument]
  local target = proc.instruments[target_instrument]
  local source_sample = source.samples[sampleslot]
  local target_sample = target.samples[sampleslot]
  local current_maximum_instruments = #proc.instruments

  if current_maximum_instruments ~= processing_maximum_instruments then
    --Someone erased or added an instrument ->  terminate for safety
    terminate_process()
    return
  end

  target_buffer = target_sample.sample_buffer
  sample_buffer = source_sample.sample_buffer
  local dont_process = 0
  local cur_frame_progress = 0
  if source_sample.sample_buffer.has_sample_data then
    cur_frame_progress = (current_frame / source_sample.sample_buffer.number_of_frames)
  end

  if cur_frame_progress <= 1 then
    vb.views.frame_meter.value = cur_frame_progress
  end
  
  local starttime = os.clock()

  if (sample_buffer == nil or not sample_buffer.has_sample_data) then
--  empty sample slot, do not process!
    finish_sample = true
    dont_process = 1
  end  

  local type_text = "[Mono] "

    if copy_mode == KEEP_LEFT then
      start_channel = 1
      end_channel = 1
      type_text = "[Mono L] "
    end
      
    if copy_mode == KEEP_RIGHT then
      start_channel = 2
      end_channel = 2
      type_text = "[Mono R] "
    end
      
    if copy_mode == MIX_CONTENT then
      start_channel = 1
      end_channel = 2
      type_text = "[Mono Mix] "
    end

  --We have to determine here if this routine has been called before the last frame
  --has been processed or after the last frame has been processed.
  --If the last frame has been processed, we need to finalize the sample
  --We simply don't know unless the "copy_frame"routine explicitly tells us so.
  --Hence the "finish_sample" value which state is set in the copy_frame() function
  if not finish_sample then
    --Don't process means that we encountered an empty sampleslot (notfor sliced samples)
    --We don't need to copy or process anything of this slot so simply skip it.
    if dont_process == 0 then
      rate = source_sample.sample_buffer.sample_rate
      bits = source_sample.sample_buffer.bit_depth
      frames = source_sample.sample_buffer.number_of_frames
      channels = source_sample.sample_buffer.number_of_channels
    end     
      
    if dont_process == 0 then
  
      local success = target_buffer:create_sample_data(rate, bits, 1, frames)
  
      target_buffer:prepare_sample_data_changes()
  
              
      if channels < 2 then
      --Sample is already mono, why convert it?
        if sampleslot < max_samples then
          target.samples[sampleslot].name = type_text..source_sample.name
          sampleslot = sampleslot +1
        end
        return
      end
  
      if current_frame < frames then
        --Here we do switch voodoo magic
        --We remove the notifier to call this function (copy_samples()!)
        --And add one to call copy_frame() which does the frame copy until
        --it is done, then this routine gets the idle notifier again.
        if not (renoise.tool().app_idle_observable:has_notifier(copy_frame)) then
          if renoise.tool().app_idle_observable:has_notifier(copy_samples) then
            renoise.tool().app_idle_observable:remove_notifier(copy_samples)
          end
          renoise.tool().app_idle_observable:add_notifier(copy_frame)
        end
        return
      end
  
    end
  else
    if dont_process == 0 then  
      target_buffer:finalize_sample_data_changes()
  
      local target_slot = sampleslot
  
  ---------------------------------------------------------------------------------------
  --
  --Note that the below copy routines are redundant due to the fact that i 
  --decided to copy the instrument from the start and then convert the samples to
  --the new target. Reason for copying the instrument is to be able to copy envelopes
  --as well.
  --I however left these routines standing as they work and serve for learning purposes.
  --
  ---------------------------------------------------------------------------------------
  
  --Copy source sample properties of the current processed sample
      target.samples[target_slot].loop_mode = source_sample.loop_mode
      target.samples[target_slot].loop_start = source_sample.loop_start 
      target.samples[target_slot].loop_end = source_sample.loop_end 
      target.samples[target_slot].name = type_text..source_sample.name
      target.samples[target_slot].panning = source_sample.panning 
      target.samples[target_slot].volume = source_sample.volume 
--      target.samples[target_slot].base_note = source_sample.base_note 
      target.samples[target_slot].fine_tune = source_sample.fine_tune 
      target.samples[target_slot].beat_sync_enabled = source_sample.beat_sync_enabled
      target.samples[target_slot].beat_sync_lines = source_sample.beat_sync_lines
      target.samples[target_slot].interpolation_mode = source_sample.interpolation_mode
      target.samples[target_slot].new_note_action = source_sample.new_note_action
      target.samples[target_slot].autoseek = source_sample.autoseek 
    else
      finish_sample = true
    end
   
  --If you decided *not* to copy the instrument in your own fork of this routine,
  --be sure to uncomment the below line!:
  --  target:insert_sample_at(sampleslot+1)
  
    if sampleslot < max_samples then
      sampleslot = sampleslot +1
      current_frame = 1
      finish_sample = false
    else
      target.name = type_text..ins_name
      target_instrument = target_instrument + 1      
  
      if is_sliced then  
        --Recovering the slice markers on their target positions
        for j = 1,#source.samples[1].slice_markers do
          target.samples[1]:insert_slice_marker(source.samples[1].slice_markers[j])
        end 
      end

  --remove sampleslot notifiers
      target.samples_observable:remove_notifier(terminate_process)
      source.samples_observable:remove_notifier(terminate_process)
      renoise.app():show_status('Samples successfully converted')
      session_open = false
      sampleslot = 1
      if dialog ~= nil then
        if dialog.visible then
          dialog:close()
        end
      end
      vb = nil
  --Remove frame copy caller
      if renoise.tool().app_idle_observable:has_notifier(copy_samples) then
        renoise.tool().app_idle_observable:remove_notifier(copy_samples)
      end
      --Redundant but just in case:
      if renoise.tool().app_idle_observable:has_notifier(copy_frame) then
        renoise.tool().app_idle_observable:remove_notifier(copy_frame)
      end
      if split_mode then
        reset_status ()
        copy_mode = KEEP_RIGHT
        main()
      end      
    end
      
    last_idle_time = os.clock()
  end
end

function copy_frame()
--And here we do all the frame magic.
  if not dialog or not dialog.visible then
    terminate_process()
    return
  end
  
  if (os.clock() - last_idle_time < 0.1) then
    return
  end

  --If you want to let your routine process more frames in this idle turn
  --simply raise the last_frame value. 
  --Though be carefull not to go too high or the Lua process cop is yelling 
  --for hanging processes.
  --My PC is pretty fast, but perhaps this value needs to be lowered
  --on slower pc's
  local last_frame = 20000

  if (sample_buffer.number_of_frames - current_frame) < last_frame then
    last_frame = sample_buffer.number_of_frames - current_frame
  end

  for _ = 1,last_frame do
    local frame = current_frame

    local frame_data = nil
    total_frames_processed = total_frames_processed + 1
    for channel = start_channel, end_channel do
      if frame_data == nil then
        frame_data = sample_buffer:sample_data(channel, frame)
      else
        frame_data = frame_data + sample_buffer:sample_data(channel, frame)
      end
    end 

    if copy_mode == MIX_CONTENT then
      frame_data = (frame_data / 2)
    end
    target_buffer:set_sample_data(1, frame, frame_data)
    current_frame = current_frame+1
    if current_frame > sample_buffer.number_of_frames then
      break
    end
  end

  local cur_frame_value = (current_frame / sample_buffer.number_of_frames)
  local cur_sample_value = (total_frames_processed / total_frames_to_process)

  if cur_frame_value <= 1 then
    vb.views.frame_meter.value = cur_frame_value
  end
  if cur_sample_value <= 1 then
    vb.views.sample_meter.value = cur_sample_value
  end
  
  
  if current_frame >= sample_buffer.number_of_frames then
    if (renoise.tool().app_idle_observable:has_notifier(copy_frame)) then
      renoise.tool().app_idle_observable:remove_notifier(copy_frame)
    end      

    finish_sample = true

    if not (renoise.tool().app_idle_observable:has_notifier(copy_samples)) then
     renoise.tool().app_idle_observable:add_notifier(copy_samples)
    end
  end

  last_idle_time = os.clock()
end 
  
function progress_meter(title, psvalue, pfvalue)
      local tsvalue = math.floor(psvalue*100)
      local tfvalue = math.floor(pfvalue*100)
      
      sample_progress_slider = vb:row {
        vb:text {
          id="sample_meter_text",
          width = 20,
          text = "Samples:"..tostring(tsvalue.."%")
        },
        vb:minislider {
          id="sample_meter",
          value = psvalue,
          active = false,
          notifier = function(value)
            vb.views.sample_meter_text.text = "Samples:"..(math.floor(value*100)).."%"
          end
        }
      }
      frame_progress_slider = vb:row {
        vb:text {
          id="frame_meter_text",
          width = 20,
          text = "Frames:"..tostring(tfvalue.."%")
        },
        vb:minislider {
          id="frame_meter",
          value = pfvalue,
          active = false,
          notifier = function(value)
            vb.views.frame_meter_text.text = "Frames:"..(math.floor(value*100)).."%"
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
          
            sample_progress_slider, 
            frame_progress_slider,
            
          },
        },
      }

    if not dialog or not dialog.visible then
      dialog = renoise.app():show_custom_dialog(title, dialog_content)
    end    
end

function terminate_process()
  if renoise.tool().app_idle_observable:has_notifier(copy_samples) then
    renoise.tool().app_idle_observable:remove_notifier(copy_samples)
  end
  if renoise.tool().app_idle_observable:has_notifier(copy_frame) then
    renoise.tool().app_idle_observable:remove_notifier(copy_frame)
  end
  if target.samples_observable:has_notifier(terminate_process) then
    target.samples_observable:remove_notifier(terminate_process)
  end
  if source.samples_observable:has_notifier(terminate_process) then
    source.samples_observable:remove_notifier(terminate_process)  
  end
  
  renoise.app():show_status('Conversion aborted')
  session_open = false
  if dialog ~= nil then
    if dialog.visible then
      dialog:close()
    end
  end
end
