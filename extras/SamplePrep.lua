--------------------------------------------------------------------------------
-- Cells! Tool
--
-- Copyright 2012 Martin Bealby
--
-- Sample preppation code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function prepare_sample(sample_object, play_mode, beat_count, is_loop)
  -- Setup a sample for Cells!
  
  if sample_object.is_slice_alias then
    return false
  end
  
  if play_mode == PLAYMODE_ONESHOT then
    -- simple one-shot
    sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
    sample_object.beat_sync_enabled = false
    sample_object.autoseek = false
    sample_object.autofade = false
    
  elseif play_mode == PLAYMODE_REPITCH then
    -- repitch
    if is_loop then
      sample_object.loop_start = 1
      sample_object.loop_end = sample_object.sample_buffer.number_of_frames
      sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD    
    else
      sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
    end
    sample_object.beat_sync_lines = beat_count * 4
    sample_object.beat_sync_enabled = true
    sample_object.autoseek = false
    sample_object.autofade = false
    
  elseif play_mode == PLAYMODE_GRANULAR then
    -- granular stretch
    if is_loop then
      sample_object.loop_start = 1
      sample_object.loop_end = sample_object.sample_buffer.number_of_frames
      sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD    
    else
      sample_object.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_OFF
    end
    sample_object.beat_sync_lines = beat_count * 4
    sample_object.beat_sync_enabled = false
    sample_object.autoseek = true
    sample_object.autofade = false
  end
end



function hide_sample(sample_object, state)
  -- Simple set autofade
  
  sample_object.autofade = state
end
  


function sample_report(sample_object)
  -- Display a sample report for the passed sample object
  
  local str

  if sample_object.autofade then
    str = "This sample will be hidden from Cells!"
          
  elseif sample_object.beat_sync_enabled then
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot repitched sample."
    else
      str = "This sample will be played as a repitched sample loop."
    end
            
  elseif string.sub(sample_object.name, 1, 3) == "NT1" then    -- magic note clip header
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot note pattern."
    else
      str = "This sample will be played as a note pattern loop."
    end
              
  elseif #sample_object.slice_markers ~= 0 then
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot note pattern."
    else
      str = "This sample will be played as a note pattern loop."
    end
             
  elseif sample_object.autoseek then
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot granular timestretched sample."
    else
      str = "This sample will be played as a granular timestretched loop."
    end
          
  elseif sample_object.is_slice_alias then
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot sample."
    else
      str = "This sample will be played as a sample loop."
    end
            
  else
    if sample_object.loop_mode == renoise.InstrumentEnvelope.LOOP_MODE_OFF then
      str = "This sample will be played as a one-shot sample."
    else
      str = "This sample will be played as a sample loop."
    end
  end

  renoise.app():show_message(str)
end



--------------------------------------------------------------------------------
-- Menu Integration
--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Sample Editor:Cells!:Prepare as unpitched one-shot",
  invoke = function()
    prepare_sample(renoise.song().selected_sample, PLAYMODE_ONESHOT, false)
  end
}

renoise.tool():add_menu_entry {
  name = "Sample List:Cells!:Prepare as unpitched one-shot",
  invoke = function()
    prepare_sample(renoise.song().selected_sample, PLAYMODE_ONESHOT, false)
  end
}


for i = 2, 7 do 
  renoise.tool():add_menu_entry {
    name = string.format("Sample Editor:Cells!:Prepare as re-pitched one-shot:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_REPITCH, math.pow(2, i), false)
    end
  }

  renoise.tool():add_menu_entry {
    name = string.format("Sample Editor:Cells!:Prepare as re-pitched loop:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_REPITCH, math.pow(2, i), true)
    end
  }

  renoise.tool():add_menu_entry {
    name = string.format("Sample Editor:Cells!:Prepare as granular stretched loop:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_GRANULAR, math.pow(2, i), true)
    end
  }
  
  renoise.tool():add_menu_entry {
    name = string.format("Sample List:Cells!:Prepare as re-pitched one-shot:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_REPITCH, math.pow(2, i), false)
    end
  }

  renoise.tool():add_menu_entry {
    name = string.format("Sample List:Cells!:Prepare as re-pitched loop:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_REPITCH, math.pow(2, i), true)
    end
  }

  renoise.tool():add_menu_entry {
    name = string.format("Sample List:Cells!:Prepare as granular stretched loop:%d beats",
                         math.pow(2, i)),
    invoke = function()
      prepare_sample(renoise.song().selected_sample, PLAYMODE_GRANULAR, math.pow(2, i), true)
    end
  }
end


renoise.tool():add_menu_entry {
  name = "Sample Editor:Cells!:Sample report",
  invoke = function()
    sample_report(renoise.song().selected_sample)
  end
}


renoise.tool():add_menu_entry {
  name = "Sample List:Cells!:Sample report",
  invoke = function()
    sample_report(renoise.song().selected_sample)
  end
}


renoise.tool():add_menu_entry {
  name = "Sample List:Cells!:Hide sample from Cells!",
  invoke = function()
    hide_sample(renoise.song().selected_sample, true)
  end
}


renoise.tool():add_menu_entry {
  name = "Sample List:Cells!:Unhide sample from Cells!",
  invoke = function()
    hide_sample(renoise.song().selected_sample, false)
  end
}


renoise.tool():add_menu_entry {
  name = "Sample Editor:Cells!:Hide sample from Cells!",
  invoke = function()
    hide_sample(renoise.song().selected_sample, true)
  end
}


renoise.tool():add_menu_entry {
  name = "Sample Editor:Cells!:Unhide sample from Cells!",
  invoke = function()
    hide_sample(renoise.song().selected_sample, false)
  end
}
