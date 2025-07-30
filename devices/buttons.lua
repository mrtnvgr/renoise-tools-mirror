--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- Button support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
BUTTON_REW = 0x5B
BUTTON_FFWD = 0x5C
BUTTON_STOP = 0x5D
BUTTON_PLAY = 0x5E
BUTTON_RECORD = 0x5F
BUTTON_TRACKL = 0x57
BUTTON_TRACKR = 0x58
BUTTON_LOOP = 0x56
BUTTON_FLIP = 0x32
BUTTON_F1 = 0x36
BUTTON_F2 = 0x37
BUTTON_F3 = 0x38
BUTTON_F4 = 0x39
BUTTON_PAN = 0x2A
BUTTON_SEND = 0x29
BUTTON_EQ = 0x2C
BUTTON_PLUGIN = 0x2B
BUTTON_AUTO = 0x4A
BUTTON_SHIFT = 0x46
BUTTON_MUTE = 0x10
BUTTON_SOLO = 0x08
BUTTON_RECARM = 0x00
BUTTON_ENC1TOUCH = 0x78
BUTTON_ENC1PUSH = 0x20
BUTTON_ENC2TOUCH = 0x79
BUTTON_ENC2PUSH = 0x21
BUTTON_ENC3TOUCH = 0x7A
BUTTON_ENC3PUSH = 0x22
BUTTON_FOOTSWITCH = 0x67
BUTTON_STRIP1 = 0x74 -- 1 finger touch
BUTTON_STRIP2 = 0x7B -- 2 finger touch

SHIFT_OFF  = 0
SHIFT_ON   = 1
SHIFT_VIEW = 2


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
shifted = SHIFT_OFF
