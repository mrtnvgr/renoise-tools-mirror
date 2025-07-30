--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- LCD Display support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
upper_display_held = false
upper_display_held_start_time = 0
lower_display_held = false
lower_display_held_start_time = 0


--------------------------------------------------------------------------------
-- LCD Display functions
--------------------------------------------------------------------------------
function display_message(msg, start_pos)
  -- Displays a message on the display at the specified starting position
  
  -- check to see if we are trying to write to a 'held' display
  if start_pos < 16 then
    if upper_display_held == true then
      return
    end
  else
    if lower_display_held == true then
      return
    end
  end

  -- calc message length
  local msg_len = string.len(msg)

  -- validate the message length
  if msg_len == 0 then
    -- do nothing
    return
  elseif (msg_len + start_pos) > 32 then
    print("Message string will not fit on LCD display:", msg)
    return
  end

  if connected == true then
    -- Create our midi message
    
    -- Display command
    local midi_msg = {0xF0, 0x00, 0x01, 0x40, 0x20, 0x00}
    
    -- Append the starting position
    table.insert(midi_msg, start_pos)
    
    -- Append our string
    for i = 1, msg_len do
      table.insert(midi_msg, string.byte(msg,i))
    end
    
    -- Append our termination command
    table.insert(midi_msg, 0xF7)
    
    -- Send the command
    midi_out_device:send(midi_msg)
    
    -- Clear the midi message in memory
    midi_msg = {}
  end
end


function clear_display()
  -- This function clears both the upper and lower row of the LCD display
  -- The following is quicker than calling ClearUpperDisplay and
  -- ClearLowerDisplay and sending two midi messages
  display_message("                                ",0)
end


function clear_upper_display()
  -- This function clears the upper row of the LCD display
  display_message("                ", 0)
end


function clear_lower_display()
  -- This function clears the lower row of the LCD display
  display_message("                ", 16)
end


function upper_display_hold()
  -- Start the upper display hold timer
  upper_display_held = true
  upper_display_held_start_time = os.clock()
end


function upper_display_hold_cancel()
  -- Cancels holding the display
  upper_display_held = false
end


function upper_display_tick()
  -- Update function that updates the display hold timer and
  -- releases the display if it has been reached
  if upper_display_held == true then
    if (upper_display_held_start_time + parameters.display_hold_time)
    < os.clock() then
      upper_display_held = false
      if mode == MODE_MIX then
        mix_upper_display_release()
      elseif mode == MODE_EDIT then
        edit_upper_display_release()
      elseif mode == MODE_DSP then
        dsp_upper_display_release()
      elseif mode == MODE_SAMP then
        samp_upper_display_release()
      elseif mode == MODE_SMP then
        --smp_upper_display_release()
      end
    end
  end
end


function lower_display_hold()
  -- Start the lower display hold timer
  lower_display_held = true
  lower_display_held_start_time = os.clock()
end


function lower_display_hold_cancel()
  -- Cancels holding the display
  lower_display_held = false
end


function lower_display_tick()
  -- Update function that updates the display hold timer and
  -- releases the display if it has been reached
  if lower_display_held == true then
    if (lower_display_held_start_time + parameters.display_hold_time)
    < os.clock() then
      lower_display_held = false
      if current_mode == MODE_MIX then
        mix_lower_display_release()
      elseif current_mode == MODE_EDIT then
        edit_lower_display_release()
      elseif current_mode == MODE_DSP then
        dsp_lower_display_release()
      elseif current_mode == MODE_SAMP then
        samp_lower_display_release()
      elseif current_modeode == MODE_SMP then
        --smp_lower_display_release()
      end
    end
  end
end


--------------------------------------------------------------------------------
-- LCD Display hooks
--------------------------------------------------------------------------------
function lcd_attach_hooks()
  if renoise.tool().app_idle_observable:has_notifier(lcd_timer_hook) == false then
    renoise.tool().app_idle_observable:add_notifier(lcd_timer_hook)
  end
end


function lcd_detach_hooks()
  if renoise.tool().app_idle_observable:has_notifier(lcd_timer_hook) == true then
    renoise.tool().app_idle_observable:remove_notifier(lcd_timer_hook)
  end
end


function lcd_timer_hook()
  -- LCD hold timer ticks are called from the this function from the idle loop
  upper_display_tick()
  lower_display_tick()
end
