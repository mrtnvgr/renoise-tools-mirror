--------------------------------------------------------------------------------
-- pKing
--
-- Copyright 2012 Martin Bealby
--
-- Communications Code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
LED_ON          = 0x20
LED_OFF         = 0x00
LED_BLINK       = 0x63
LED_FLASH       = 0x41
LED_PAD1        = 0x00
LED_PAD2        = 0x01
LED_PAD3        = 0x02
LED_PAD4        = 0x03
LED_PAD5        = 0x04
LED_PAD6        = 0x05
LED_PAD7        = 0x06
LED_PAD8        = 0x07
LED_PAD9        = 0x08
LED_PAD10       = 0x09
LED_PAD11       = 0x0A
LED_PAD12       = 0x0B
LED_PAD13       = 0x0C
LED_PAD14       = 0x0D
LED_PAD15       = 0x0E
LED_PAD16       = 0x0F
LED_SCENE       = 0x10
LED_MESSAGE     = 0x11
LED_SETTING     = 0x12
LED_NOTECC      = 0x13
LED_MIDICH      = 0x14
LED_SWTYPE      = 0x15
LED_RELVAL      = 0x16
LED_VELOCITY    = 0x17
LED_PORT        = 0x18
LED_FIXEDVEL    = 0x19
LED_PROGCHANGE  = 0x1A
LED_X           = 0x1B
LED_Y           = 0x1C
LED_KNOB1ASSIGN = 0x1D
LED_KNOB2ASSIGN = 0x1E
LED_PEDAL       = 0x1F
LED_ROLL        = 0x20
LED_FLAM        = 0x21
LED_HOLD        = 0x22
CMD_PAD         = 0x45
CMD_ENC         = 0x43
CMD_BTN         = 0x48
CMD_ROT         = 0x49
PAD_ON          = 0x9A
PAD_OFF         = 0x8A
BTN_SCENE       = 0x00
BTN_MESSAGE     = 0x01
BTN_SETTING     = 0x02
BTN_NOTECC      = 0x03
BTN_MIDICH      = 0x04
BTN_SWTYPE      = 0x05
BTN_RELVAL      = 0x06
BTN_VELOCITY    = 0x07
BTN_PORT        = 0x08
BTN_FIXEDVEL    = 0x09
BTN_PROGCHANGE  = 0x0A
BTN_X           = 0x0B
BTN_Y           = 0x0C
BTN_KNOB1ASSIGN = 0x0D
BTN_KNOB2ASSIGN = 0x0E
BTN_PEDAL       = 0x0F
BTN_ROLL        = 0x10
BTN_FLAM        = 0x11
BTN_HOLD        = 0x12
ROT_1           = 0x00
ROT_2           = 0x01


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
sysex_out = nil
sysex_in = nil
last_lcd_time = 0
pad_map = {}


--------------------------------------------------------------------------------
-- Main Functions
--------------------------------------------------------------------------------
function connect(in_device, out_device)
  -- Connect to the device and initialise native mode
  if not table.find(renoise.Midi.available_input_devices(), in_device) then
    renoise.app():show_error(string.format('Could not open midi input port: %s',
                                           in_device))
    return false
  end
  
  if not table.find(renoise.Midi.available_output_devices(), out_device) then
    renoise.app():show_error(string.format('Could not open midi output port: %s',
                                           out_device))
    return false
  end
  
  -- Attach our sysex command devices
  sysex_out = renoise.Midi.create_output_device(out_device)
  sysex_in  = renoise.Midi.create_input_device(in_device,
                                               midi_callback,
                                               sysex_callback)  

  -- Enter native mode
  sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x00, 0x00, 0x01, 0xF7})
  
  -- Set light status (all off)
  all_led_off()
                  
  -- Enable inputs
  set_pad_mapping({0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                   0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F})
  
  return true
end


function disconnect()
  -- Exit native mode and disconnect
  if sysex_out then
    -- exit native mode
    sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x00, 0x00, 0x00, 0xF7})
    sysex_out:close()
    sysex_out = nil
  end
  
  if sysex_in then
    sysex_in:close()
    sysex_in = nil
  end
end



function midi_callback(msg)
  -- do nothing
end


function sysex_callback(msg)
  if #msg == 9 then
    if msg[6] == CMD_ENC then
      -- encoder
      if msg[8] == 0x01 then
        mode:encoder(1)
      elseif msg[8] == 0x7F then
        mode:encoder(-1)
      end
    elseif msg[6] == CMD_BTN then
      -- button
      if msg[8] == 0x7F then
        mode:button(msg[7])
      end
    elseif msg[6] == CMD_ROT then
      -- rotary
      mode:rotary(msg[7], msg[8])
    elseif msg[6] == CMD_PAD then
      if msg[7] > 15 then
        mode:pad(msg[7]-63, msg[8])  -- 1 to 16
      end
    end
  end
end


--------------------------------------------------------------------------------
-- I/O Functions
--------------------------------------------------------------------------------
function all_led_off()
  if sysex_out then
    sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x3F, 0x0A, 0x01, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7})
  end
end


function set_led(led_id, state_id)
  -- Sets the state of an led
  if sysex_out then
    sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x01, led_id, state_id, 0xF7})
  end
end


function set_lcd(string, force)
  -- Sets the LCD 3 char display
  assert(string:len() == 3, "padKontrol LCD string must be 3 characters ")
  if sysex_out then
    if force then
      -- force update now
      sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x22, 0x04, 0x00,
                      string:byte(1), string:byte(2), string:byte(3), 0xF7})
      last_lcd_time = os.clock()
      
    elseif ((last_lcd_time + (options.lcd_hold_time.value/10)) < os.clock()) then
      -- slow update
      sysex_out:send({0xF0, 0x42, 0x40, 0x6E, 0x08, 0x22, 0x04, 0x00,
                      string:byte(1), string:byte(2), string:byte(3), 0xF7})
    end
  end
end 


function all_pad_led_off()
  -- Turns of the leds for all pads
  for i = 0, 15 do
    set_led(i, LED_OFF)
  end
end 


function set_pad_mapping(mapping_table)
  if #mapping_table ~= 16 then
    return
  end
  
  if sysex_out then
    local sysex = {0xF0, 0x42, 0x40, 0x6E, 0x08, 0x3F, 0x2A, 0x00, 0x00, 0x05,
                   0x05, 0x05, 0x7F, 0x7E, 0x7F, 0x7F, 0x03, 0x0A, 0x0A, 0x0A,
                   0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A,
                   0x0A, 0x0A, 0x0A, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36,
                   0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0xF7}
  
    if options.lcd_hold_time.value then
      -- reverse map
      local mi = 1
      
      for i = 3, 0, -1 do  -- row
        for j = 1, 4 do    -- col
          --print((4*i) + j, mi)
          sysex[33 + (4*i) + j] = mapping_table[mi]
          mi = mi + 1
        end
      end
      
    else
      -- default map
      for i = 1, 16 do
        sysex[33+i] = mapping_table[i]
      end
    end
    
    sysex_out:send(sysex)
    pad_map = mapping_table
  end
end
