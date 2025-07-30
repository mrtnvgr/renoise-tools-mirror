--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- LED support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
LED_ANYSOLO = 0x73
LED_AUTOWRITE = 0x4B
LED_AUTOREAD = 0x4E
LED_RECARM = 0x00
LED_SOLO = 0x08
LED_MUTE = 0x10
LED_SHIFT = 0x46
LED_PAN = 0x2A
LED_SEND = 0x29
LED_EQ = 0x2C
LED_PLUGIN = 0x2B
LED_AUTO = 0x4A
LED_F1 = 0x36
LED_F2 = 0x37
LED_F3 = 0x38
LED_F4 = 0x39
LED_TRACKL = 0x57
LED_TRACKR = 0x58
LED_LOOP = 0x56
LED_FLIP = 0x32
LED_RECORD = 0x5F


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function all_leds_off()
  -- turns off all LEDs for known state
  led_off(LED_ANYSOLO)
  led_off(LED_AUTOWRITE)
  led_off(LED_AUTOREAD)
  led_off(LED_RECARM)
  led_off(LED_SOLO)
  led_off(LED_MUTE)
  led_off(LED_SHIFT)
  led_off(LED_PAN)
  led_off(LED_SEND)
  led_off(LED_EQ)
  led_off(LED_PLUGIN)
  led_off(LED_AUTO)
  led_off(LED_F1)
  led_off(LED_F2)
  led_off(LED_F3)
  led_off(LED_F4)
  led_off(LED_TRACKL)
  led_off(LED_TRACKR)
  led_off(LED_LOOP)
  led_off(LED_FLIP)
  led_off(LED_RECORD)
end


function led_on(led_name)
  -- Turns the specified LED on
  if connected == true then
    midi_out_device:send({0x90, led_name, 0x7F})
  end
end


function led_off(led_name)
  -- Turns the specified LED off
  if connected == true then
    midi_out_device:send({0x90, led_name, 0x00})
  end
end
