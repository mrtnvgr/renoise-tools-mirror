-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: PhraseTouch
-- Version: 1.3 build 089
-- Compatibility: Renoise v3.1.1
-- Development date: February to May 2018
-- Published: June 2018
-- Locate: Spain
-- Programmer: ulneiz
--
-- Font: "Century Gotic"
--
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


_AUTO_RELOAD_DEBUG = function() show_tool_dialog() end


-----------------------------------------------------------------------------------------------
--local, global variables/tables
dialog = nil
local pht_title = " PhraseTouch"
pht_version = "1.3 build 089"
rns_version = renoise.RENOISE_VERSION
api_version = renoise.API_VERSION
---
vb = renoise.ViewBuilder()
vws = vb.views
rna = renoise.app()
rnt = renoise.tool()

--global song
song = nil
  function pht_sng() song = renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier( pht_sng ) --catching start renoise or new song
  pcall( pht_sng ) --catching installation
  


pht_height_bt_on = 28
pht_width_bt_on = 48

pht_height_bt_off = 28
pht_width_bt_off = 20

pht_height_bt_sel = 28 
pht_width_bt_sel = 14

pht_height_bt_pnl = 37
pht_width_bt_pnl = 34

pht_height_bar_vol = 136
pht_width_bar_vol = 24

pht_height_bar_db = 131
pht_width_bar_db = 24

--convert number (0-119) to string (C-0 to B-9) -- tostring, tonumber
function pht_note_tostring( number ) --return a string, Range number: 0 to 119)
  local note_name = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
  return ("%s%s"):format( note_name[ number % 12 + 1 ], math.floor( number/12 )  )
end
---
function pht_note_tonumber( string ) --return a number
  local note_name_1 = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
  local note_name_2 = { "c-", "c#", "d-", "d#", "e-", "f-", "f#", "g-", "g#", "a-", "a#", "b-" }
  local note_name_3 = { "C",  "C#", "D",  "D#", "E",  "F" , "F#", "G",  "G#", "A",  "A#", "B"  }
  local note_name_4 = { "c",  "c#", "d",  "d#", "e",  "f",  "f#", "g",  "g#", "a",  "a#", "b"  }
  for i = 1, 12 do
    for octave = 0, 9 do
      if ( string == ("%s%s"):format( note_name_1[i], octave ) ) or
         ( string == ("%s%s"):format( note_name_2[i], octave ) ) or
         ( string == ("%s%s"):format( note_name_3[i], octave ) ) or
         ( string == ("%s%s"):format( note_name_4[i], octave ) ) then
        return i + ( octave * 12 ) - 1
      end
    end
  end
end



-----------------------------------------------------------------------------------------------
--default colors
PHT_MAIN_COLOR_DEF = {
  GOLD_ON_DEF   = { 229,160,032 },
  GOLD_OFF1_DEF = { 076,053,010 },
  GOLD_OFF2_DEF = { 102,079,036 }, -- +26
  RED_ON_DEF    = { 170,000,000 },
  RED_OFF_DEF   = { 126,000,000 },
  GREY_ON_DEF   = { 170,160,150 },
  GREY_OFF_DEF  = { 070,060,050 },
  SKY_BLUE_DEF  = { 018,083,149 },
  DEFAULT_DEF   = { 000,000,000 },
  ---
  RED_OFF_DEF_1  = { 096,000,000 },
  RED_OFF_DEF_2  = { 000,076,000 },
  RED_OFF_DEF_3  = { 030,030,096 },
  RED_OFF_DEF_4  = { 086,000,086 },
  RED_OFF_DEF_5  = { 028,093,159 },
  RED_OFF_DEF_6  = { 135,000,086 },
  RED_OFF_DEF_7  = { 165,066,000 },
  RED_OFF_DEF_8  = { 096,086,000 },
  RED_OFF_DEF_9  = { 076,050,160 },
  RED_OFF_DEF_10 = { 119,060,000 },
  RED_OFF_DEF_11 = { 030,096,060 },
  RED_OFF_DEF_12 = { 159,020,040 },
  RED_OFF_DEF_13 = { 110,110,110 },
  RED_OFF_DEF_14 = { 079,020,050 },
  RED_OFF_DEF_15 = { 130,116,080 },
  RED_OFF_DEF_16 = { 099,140,110 }
}
--preferences
pht_pref = renoise.Document.create("ScriptingToolPreferences") {  --pht.pht_red_off_1.value
  --note_on_marked
  pht_gold_on =   PHT_MAIN_COLOR_DEF.GOLD_ON_DEF,

  --note_on_back
  pht_gold_off1 = PHT_MAIN_COLOR_DEF.GOLD_OFF1_DEF,
  pht_gold_off2 = PHT_MAIN_COLOR_DEF.GOLD_OFF2_DEF,

  --note_sel_marked
  pht_grey_on =   PHT_MAIN_COLOR_DEF.GREY_ON_DEF,

  --note_sel_back
  pht_grey_off =  PHT_MAIN_COLOR_DEF.GREY_OFF_DEF,

  --note_off
  pht_red_off    = PHT_MAIN_COLOR_DEF.RED_OFF_DEF,
  pht_red_off_1  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_1,
  pht_red_off_2  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_2,
  pht_red_off_3  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_3,
  pht_red_off_4  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_4,
  pht_red_off_5  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_5,
  pht_red_off_6  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_6,
  pht_red_off_7  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_7,
  pht_red_off_8  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_8,
  pht_red_off_9  = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_9,
  pht_red_off_10 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_10,
  pht_red_off_11 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_11,
  pht_red_off_12 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_12,
  pht_red_off_13 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_13,
  pht_red_off_14 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_14,
  pht_red_off_15 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_15,
  pht_red_off_16 = PHT_MAIN_COLOR_DEF.RED_OFF_DEF_16,

  --sky blue & default
  pht_sky_blue =  PHT_MAIN_COLOR_DEF.SKY_BLUE_DEF,
  pht_default =   PHT_MAIN_COLOR_DEF.DEFAULT_DEF
}
rnt.preferences = pht_pref

--print( renoise.tool().preferences.pht_gold_on[1].value )



-----------------------------------------------------------------------------------------------
--main colors
PHT_MAIN_COLOR = {
  --note_on_marked
  GOLD_ON   = { pht_pref.pht_gold_on[1].value, pht_pref.pht_gold_on[2].value, pht_pref.pht_gold_on[3].value },       --{ 229,160,032 },

  --note_on_back
  GOLD_OFF1 = { pht_pref.pht_gold_off1[1].value, pht_pref.pht_gold_off1[2].value, pht_pref.pht_gold_off1[3].value }, --{ 076,053,010 },
  GOLD_OFF2 = { pht_pref.pht_gold_off2[1].value, pht_pref.pht_gold_off2[2].value, pht_pref.pht_gold_off2[3].value }, --{ 096,073,030 },

  --note_sel_marked
  GREY_ON   = { pht_pref.pht_grey_on[1].value, pht_pref.pht_grey_on[2].value, pht_pref.pht_grey_on[3].value },       --{ 170,160,150 },

  --note_sel_back
  GREY_OFF  = { pht_pref.pht_grey_off[1].value, pht_pref.pht_grey_off[2].value, pht_pref.pht_grey_off[3].value },    --{ 070,060,050 },

  --note_off
  RED_OFF    = { pht_pref.pht_red_off[1].value,    pht_pref.pht_red_off[2].value,    pht_pref.pht_red_off[3].value },    --{ 126,000,000 },
  RED_OFF_1  = { pht_pref.pht_red_off_1[1].value,  pht_pref.pht_red_off_1[2].value,  pht_pref.pht_red_off_1[3].value },  --{ 096,000,000 },
  RED_OFF_2  = { pht_pref.pht_red_off_2[1].value,  pht_pref.pht_red_off_2[2].value,  pht_pref.pht_red_off_2[3].value },  --{ 000,076,000 },
  RED_OFF_3  = { pht_pref.pht_red_off_3[1].value,  pht_pref.pht_red_off_3[2].value,  pht_pref.pht_red_off_3[3].value },  --{ 030,030,096 },
  RED_OFF_4  = { pht_pref.pht_red_off_4[1].value,  pht_pref.pht_red_off_4[2].value,  pht_pref.pht_red_off_4[3].value },  --{ 086,000,086 },
  RED_OFF_5  = { pht_pref.pht_red_off_5[1].value,  pht_pref.pht_red_off_5[2].value,  pht_pref.pht_red_off_5[3].value },  --{ 028,093,159 },
  RED_OFF_6  = { pht_pref.pht_red_off_6[1].value,  pht_pref.pht_red_off_6[2].value,  pht_pref.pht_red_off_6[3].value },  --{ 135,000,086 },
  RED_OFF_7  = { pht_pref.pht_red_off_7[1].value,  pht_pref.pht_red_off_7[2].value,  pht_pref.pht_red_off_7[3].value },  --{ 165,066,000 },
  RED_OFF_8  = { pht_pref.pht_red_off_8[1].value,  pht_pref.pht_red_off_8[2].value,  pht_pref.pht_red_off_8[3].value },  --{ 096,086,000 },
  RED_OFF_9  = { pht_pref.pht_red_off_9[1].value,  pht_pref.pht_red_off_9[2].value,  pht_pref.pht_red_off_9[3].value },  --{ 076,050,160 },
  RED_OFF_10 = { pht_pref.pht_red_off_10[1].value, pht_pref.pht_red_off_10[2].value, pht_pref.pht_red_off_10[3].value }, --{ 119,060,000 },
  RED_OFF_11 = { pht_pref.pht_red_off_11[1].value, pht_pref.pht_red_off_11[2].value, pht_pref.pht_red_off_11[3].value }, --{ 030,096,060 },
  RED_OFF_12 = { pht_pref.pht_red_off_12[1].value, pht_pref.pht_red_off_12[2].value, pht_pref.pht_red_off_12[3].value }, --{ 159,020,040 },
  RED_OFF_13 = { pht_pref.pht_red_off_13[1].value, pht_pref.pht_red_off_13[2].value, pht_pref.pht_red_off_13[3].value }, --{ 110,110,110 },
  RED_OFF_14 = { pht_pref.pht_red_off_14[1].value, pht_pref.pht_red_off_14[2].value, pht_pref.pht_red_off_14[3].value }, --{ 079,020,050 },
  RED_OFF_15 = { pht_pref.pht_red_off_15[1].value, pht_pref.pht_red_off_15[2].value, pht_pref.pht_red_off_15[3].value }, --{ 130,116,080 },
  RED_OFF_16 = { pht_pref.pht_red_off_16[1].value, pht_pref.pht_red_off_16[2].value, pht_pref.pht_red_off_16[3].value }, --{ 099,140,110 },

  --sky blue & default
  SKY_BLUE  = { pht_pref.pht_sky_blue[1].value, pht_pref.pht_sky_blue[2].value, pht_pref.pht_sky_blue[3].value }, --{ 018,083,149 },
  DEFAULT   = { pht_pref.pht_default[1].value, pht_pref.pht_default[2].value, pht_pref.pht_default[3].value }     --{ 000,000,000 },
}



-----------------------------------------------------------------------------------------------
--panels name & colors & others
PHT_MAP_PNL_NAME_1  = "/ico/1_big_ico.png"
PHT_MAP_PNL_NAME_2  = "/ico/2_big_ico.png"
PHT_MAP_PNL_NAME_3  = "/ico/3_big_ico.png"
PHT_MAP_PNL_NAME_4  = "/ico/4_big_ico.png"
PHT_MAP_PNL_NAME_5  = "/ico/5_big_ico.png"
PHT_MAP_PNL_NAME_6  = "/ico/6_big_ico.png"
PHT_MAP_PNL_NAME_7  = "/ico/7_big_ico.png"
PHT_MAP_PNL_NAME_8  = "/ico/8_big_ico.png"
PHT_MAP_PNL_NAME_9  = "/ico/9_big_ico.png"
PHT_MAP_PNL_NAME_10 = "/ico/10_big_ico.png"
PHT_MAP_PNL_NAME_11 = "/ico/11_big_ico.png"
PHT_MAP_PNL_NAME_12 = "/ico/12_big_ico.png"
PHT_MAP_PNL_NAME_13 = "/ico/13_big_ico.png"
PHT_MAP_PNL_NAME_14 = "/ico/14_big_ico.png"
PHT_MAP_PNL_NAME_15 = "/ico/15_big_ico.png"
PHT_MAP_PNL_NAME_16 = "/ico/16_big_ico.png"
---
PHT_MAP_PNL_TOOLTIP = "Enable/disable MultiTouch for this panel\nChains each panel to control the notes buttons from the \"1 Mst\" panel\n"..
                      "  -Panel 1 = 1 Mst (use it to touch the other chained panels at the same time)\n"..
                      "  -Panel 2 to 16 = 2 to 16 chained (activate each panel to chain it)\n\n"..
                      "For quick selection for multiple panels, press and hold for more than 1 second to enable/disable at the same time the chain of:\n"..
                      "  -For button 1 pressed: all the 16 panels.\n"..
                      "  -For the rest of buttons (2 until 16) individually pressed: only the panels with lower number. For example, if you press 7, the range of 7 to 1 will be chained.\n\n"..
                      "Use up to a total of 12 chained panels (\"1 Mst\" included) to record notes in the Pattern Editor!\n[Alt + F1 to F12]"
---                      
PHT_CHD_PNL_TOOLTIP = "Chords or phrases controls selector\nChange the controls between chords or phrases\n"..
                      "For quick selection for multiple ChordTouch controls, press and hold for more than 1 second to enable/disable all of them:\n"..
                      "  -For \"Treble Clef\" button pressed of panel 1: all the 16 \"Treble Clef\" buttons.\n"..
                      "  -For the rest of \"Treble Clef\" buttons (2 until 16) individually pressed: only the panels with lower number. For example, if you press 3, the range of 3 to 1 will be pressed."

---
PHT_EDIT_MODE_TOOLTIP = "Enable/disable Edit Mode\nTo live recording with OSC inside the pattern editor, if the instrument editor window is detached it will be reattached again!\n[Esc]"



--Chords
-----------------------------------------------------------------------------------------------
pht_chd_list = 
"  01 : 3                     0 , 4\n"..
"  02 : 5                     0 , 7\n"..
"  03 : 6                     0 , 4 , 7 , 9\n"..
"  04 : 6n5                   0 , 4 , 9\n"..

"  05 : 6/9                   0 , 4 , 9 , 14\n"..
"  06 : 6 add9                0 , 4 , 7 , 9 , 14\n"..
"  07 : 6 sus 4               0 , 5 , 7 , 9\n"..
"  08 : 6 sus 4 add 9         0 , 5 , 7 , 9 , 14\n"..
"\n"..
"  09 : 7                     0 , 4 , 7 , 10\n"..
"  10 : 7 add 6               0 , 4 , 7 , 9 , 10\n"..
"  11 : 7 add 9               0 , 4 , 7 , 10 , 14\n"..
"  12 : 7 add 13              0 , 4 , 7 , 10 , 21\n"..

"  13 : 7 sus 4               0 , 5 , 7 , 10\n"..
"  14 : 7#5                   0 , 4 , 8 , 10\n"..
"  15 : 7#9                   0 , 4 , 7 , 10 , 15\n"..
"  16 : 7b5                   0 , 4 , 6 , 10\n"..
"\n"..
"  17 : 7b9                   0 , 4 , 7 , 10 , 13\n"..
"  18 : 9                     0 , 4 , 11 , 14\n"..
"  19 : 9 add 6               0 , 4 , 7 , 9 , 10 , 14\n"..
"  20 : 9 sus 4               0 , 5 , 7 , 10 , 14\n"..

"  21 : 9#5                   0 , 4 , 8 , 10 , 14\n"..
"  22 : 9b5                   0 , 4 , 6 , 10 , 14\n"..
"  23 : 11                    0 , 4 , 7 , 10 , 14 , 17\n"..
"  24 : 11b9                  0 , 4 , 7 , 10 , 13 , 17\n"..
"\n"..
"  25 : 13                    0 , 4 , 7 , 10 , 14 , 17 , 21\n"..
"  26 : 13 aug 11             0 , 4 , 7 , 10 , 14 , 18 , 21\n"..
"  27 : 13 b9                 0 , 4 , 7 , 10 , 13 , 17 , 21\n"..
"  28 : 13 b9 #11             0 , 4 , 7 , 10 , 13 , 18 , 21\n"..

"  29 : 13 b9b5               0 , 4 , 6 , 10 , 13 , 17 , 21\n"..
"  30 : add 9                 0 , 4 , 7 , 14\n"..
"  31 : aug                   0 , 4 , 8\n"..
"  32 : aug 11                0 , 4 , 7 , 10 , 14 , 18\n"..
"\n"..
"  33 : b5                    0 , 4 , 6\n"..
"  34 : b9 b5                 0 , 4 , 6 , 10 , 13\n"..
"  35 : b9#5                  0 , 4 , 8 , 10 , 13\n"..
"  36 : b9#11                 0 , 4 , 7 , 10 , 13 , 18\n"..

"  37 : dim                   0 , 3 , 6\n"..
"  38 : dim 7                 0 , 3 , 6 , 9\n"..
"  39 : Maj                   0 , 4 , 7\n"..
"  40 : Maj 7                 0 , 4 , 7 , 11\n"..
"\n"..
"  41 : Maj 7 sus4            0 , 5 , 7 , 11\n"..
"  42 : Maj 7#5               0 , 4 , 8 , 11\n"..
"  43 : Maj 7add 9            0 , 4 , 7 , 11 , 14\n"..
"  44 : Maj 9 sus4            0 , 5 , 7 , 11 , 14\n"..

"  45 : Maj 11                0 , 4 , 7 , 11 , 14 , 17\n"..
"  46 : Maj 13                0 , 4 , 7 , 11 , 14 , 17 , 21\n"..
"  47 : min                   0 , 3 , 7\n"..
"  48 : min 6                 0 , 3 , 7 , 9\n"..
"\n"..
"  49 : min 6 add 9           0 , 3 , 7 , 9 , 14\n"..
"  50 : min 7                 0 , 3 , 7 , 10\n"..
"  51 : min 7b5               0 , 3 , 6 , 10\n"..
"  52 : min 9                 0 , 3 , 7 , 10 , 14\n"..

"  53 : min add 9             0 , 3 , 7 , 14\n"..
"  54 : min Maj7              0 , 3 , 7 , 11\n"..
"  55 : min Maj9              0 , 3 , 7 , 11 , 14\n"..
"  56 : min 11                0 , 3 , 7 , 10 , 14 , 17\n"..

"  57 : min 13                0 , 3 , 7 , 10 , 14 , 17 , 21\n"..
"  58 : sus2                  0 , 2 , 7\n"..
"  59 : sus4                  0 , 5 , 7"
---
pht_chd_chords = {
  chd1  = nil,
  ---
  chd2  = { 0, 4 },
  chd3  = { 0, 7 },
  chd4  = { 0, 4, 7, 9 },
  chd5  = { 0, 4, 9 },
  ---
  chd6  = { 0, 4, 9, 14 },
  chd7  = { 0, 4, 7, 9, 14 },
  chd8  = { 0, 5, 7, 9 },
  chd9  = { 0, 5, 7, 9, 14 },
  ---
  chd10 = { 0, 4, 7, 10 },
  chd11 = { 0, 4, 7, 9, 10 },
  chd12 = { 0, 4, 7, 10, 14 },
  chd13 = { 0, 4, 7, 10, 21 },
  ---
  chd14 = { 0, 5, 7, 10 },
  chd15 = { 0, 4, 8, 10 },
  chd16 = { 0, 4, 7, 10, 15 },
  chd17 = { 0, 4, 6, 10 },
  ---
  chd18 = { 0, 4, 7, 10, 13 },
  chd19 = { 0, 4, 11, 14 },
  chd20 = { 0, 4, 7, 9, 10, 14 },
  chd21 = { 0, 5, 7, 10, 14 },
  ---
  chd22 = { 0, 4, 8, 10, 14 },
  chd23 = { 0, 4, 6, 10, 14 },
  chd24 = { 0, 4, 7, 10, 14, 17 },
  chd25 = { 0, 4, 7, 10, 13, 17 },
  ---
  chd26 = { 0, 4, 7, 10, 14, 17, 21 },
  chd27 = { 0, 4, 7, 10, 14, 18, 21 },
  chd28 = { 0, 4, 7, 10, 13, 17, 21 },
  chd29 = { 0, 4, 7, 10, 13, 18, 21 },
  ---
  chd30 = { 0, 4, 6, 10, 13, 17, 21 },
  chd31 = { 0, 4, 7, 14 },
  chd32 = { 0, 4, 8 },
  chd33 = { 0, 4, 7, 10, 14, 18 },
  ---
  chd34 = { 0, 4, 6 },
  chd35 = { 0, 4, 6, 10, 13 },
  chd36 = { 0, 4, 8, 10, 13 },
  chd37 = { 0, 4, 7, 10, 13, 18 },
  ---
  chd38 = { 0, 3, 6 },
  chd39 = { 0, 3, 6, 9 },
  chd40 = { 0, 4, 7 },
  chd41 = { 0, 4, 7, 11 },
  ---
  chd42 = { 0, 5, 7, 11 },
  chd43 = { 0, 4, 8, 11 },
  chd44 = { 0, 4, 7, 11, 14 },
  chd45 = { 0, 5, 7, 11, 14 },
  ---
  chd46 = { 0, 4, 7, 11, 14, 17 },
  chd47 = { 0, 4, 7, 11, 14, 17, 21 },
  chd48 = { 0, 3, 7 },
  chd49 = { 0, 3, 7, 9 },
  ---
  chd50 = { 0, 3, 7, 9, 14 },
  chd51 = { 0, 3, 7, 10 },
  chd52 = { 0, 3, 6, 10 },
  chd53 = { 0, 3, 7, 10, 14 },
  ---
  chd54 = { 0, 3, 7, 14 },
  chd55 = { 0, 3, 7, 11 },
  chd56 = { 0, 3, 7, 11, 14 },
  chd57 = { 0, 3, 7, 10, 14, 17 },
  ---
  chd58 = { 0, 3, 7, 10, 14, 17, 21 },
  chd59 = { 0, 2, 7 },
  chd60 = { 0, 5, 7 }
}
---
pht_chd_names = { --1 + 59 = 60
  " No Chord!",
  " 3", " 5", " 6", " 6n5",
  " 6/9", " 6 add9", " 6 sus 4", " 6 sus 4 add 9",
  " 7", " 7 add 6", " 7 add 9", " 7 add 13",
  " 7 sus 4", " 7#5", " 7#9", " 7b5",
  " 7b9", " 9", " 9 add 6", " 9 sus 4",
  " 9#5", " 9b5", " 11", " 11b9",
  " 13", " 13 aug 11", " 13 b9", " 13 b9 #11",
  " 13 b9b5", " add 9", " aug", " aug 11",
  " b5", " b9 b5", " b9#5", " b9#11",
  " dim", " dim 7", " Maj", " Maj 7",
  " Maj 7 sus4", " Maj 7#5", " Maj 7 add 9", " Maj 9 sus4",
  " Maj 11", " Maj 13", " min", " min 6",
  " min 6 add 9", " min 7", " min 7b5", " min 9",
  " min add 9", " min Maj7", " min Maj9", " min 11",
  " min 13", " sus2", " sus4"
}
---
--[[
pht_chd_root = { --99
  " C-0"," C#0"," D-0"," D#0"," E-0"," F-0"," F#0"," G-0"," G#0"," A-0"," A#0"," B-0",
  " C-1"," C#1"," D-1"," D#1"," E-1"," F-1"," F#1"," G-1"," G#1"," A-1"," A#1"," B-1",
  " C-2"," C#2"," D-2"," D#2"," E-2"," F-2"," F#2"," G-2"," G#2"," A-2"," A#2"," B-2",
  " C-3"," C#3"," D-3"," D#3"," E-3"," F-3"," F#3"," G-3"," G#3"," A-3"," A#3"," B-3",
  " C-4"," C#4"," D-4"," D#4"," E-4"," F-4"," F#4"," G-4"," G#4"," A-4"," A#4"," B-4",
  " C-5"," C#5"," D-5"," D#5"," E-5"," F-5"," F#5"," G-5"," G#5"," A-5"," A#5"," B-5",
  " C-6"," C#6"," D-6"," D#6"," E-6"," F-6"," F#6"," G-6"," G#6"," A-6"," A#6"," B-6",
  " C-7"," C#7"," D-7"," D#7"," E-7"," F-7"," F#7"," G-7"," G#7"," A-7"," A#7"," B-7",
  " C-8"," C#8"," D-8"
}
]]
pht_chd_root = { --99 reversed
                                                                 " D-8"," C#8"," C-8",
  " B-7"," A#7"," A-7"," G#7"," G-7"," F#7"," F-7"," E-7"," D#7"," D-7"," C#7"," C-7",
  " B-6"," A#6"," A-6"," G#6"," G-6"," F#6"," F-6"," E-6"," D#6"," D-6"," C#6"," C-6",
  " B-5"," A#5"," A-5"," G#5"," G-5"," F#5"," F-5"," E-5"," D#5"," D-5"," C#5"," C-5",
  " B-4"," A#4"," A-4"," G#4"," G-4"," F#4"," F-4"," E-4"," D#4"," D-4"," C#4"," C-4",
  " B-3"," A#3"," A-3"," G#3"," G-3"," F#3"," F-3"," E-3"," D#3"," D-3"," C#3"," C-3",
  " B-2"," A#2"," A-2"," G#2"," G-2"," F#2"," F-2"," E-2"," D#2"," D-2"," C#2"," C-2",
  " B-1"," A#1"," A-1"," G#1"," G-1"," F#1"," F-1"," E-1"," D#1"," D-1"," C#1"," C-1",
  " B-0"," A#0"," A-0"," G#0"," G-0"," F#0"," F-0"," E-0"," D#0"," D-0"," C#0"," C-0"
}
--multi chordtouch chain all pannels with timer
PHT_MUL_CHD = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } --16
PHT_MUL_CHD_PNL = { _1 = 1, _2 = 2, _3 = 3, _4 = 4, _5 = 5, _6 = 6, _7 = 7, _8 = 8, _9 = 9, _10 = 10, _11 = 11, _12 = 12, _13 = 13, _14 = 14, _15 = 15, _16 = 16 }
PHT_MUL_CHD_NUM = 0
--chordtouch add timer selector
function pht_cht_pnls_add_timer( value )
  if ( value ~= nil ) then
    PHT_MUL_CHD_NUM = PHT_MUL_CHD_PNL[value]
  end
  if not rnt:has_timer( pht_cht_pnls_add_timer ) then
    rnt:add_timer( pht_cht_pnls_add_timer, 1200 )
  else
    if ( PHT_MUL_CHD_NUM ~= 1 ) then
      for i = PHT_MUL_CHD_NUM, 1, -1 do
        PHT_MUL_CHD[ i ] = not PHT_MUL_CHD[ PHT_MUL_CHD_NUM ]
        pht_cht_pnls_name_multi( "_"..i )
      end
    else
      for i = 16, 2, -1 do
        PHT_MUL_CHD[ i ] = not PHT_MUL_CHD[ 1 ]
        pht_cht_pnls_name_multi( "_"..i )
      end
    end
  end
end
--chordtouch remove timer selector
function pht_cht_pnls_remove_timer()
  if rnt:has_timer( pht_cht_pnls_add_timer ) then
    rnt:remove_timer( pht_cht_pnls_add_timer )
  end
end
---
function pht_cht_pnls_name_multi( value )
  if ( PHT_MUL_CHD[ PHT_MUL_CHD_PNL[value] ] == false ) then
    PHT_MUL_CHD[ PHT_MUL_CHD_PNL[value] ] = true
    vws[ "PHT_PHR_PHRASES_"..PHT_MUL_CHD_PNL[value] ].visible = false
    vws[ "PHT_CHD_CHORDS_"..PHT_MUL_CHD_PNL[value] ].visible = true
    vws[ "PHT_CHD_PHR_BT_"..PHT_MUL_CHD_PNL[value] ].color = PHT_MAIN_COLOR.GOLD_ON
  else
    PHT_MUL_CHD[ PHT_MUL_CHD_PNL[value] ] = false
    vws[ "PHT_CHD_CHORDS_"..PHT_MUL_CHD_PNL[value] ].visible = false
    vws[ "PHT_PHR_PHRASES_"..PHT_MUL_CHD_PNL[value] ].visible = true
    vws[ "PHT_CHD_PHR_BT_"..PHT_MUL_CHD_PNL[value] ].color = PHT_MAIN_COLOR.DEFAULT
  end
end



-----------------------------------------------------------------------------------------------
--require files
require ("lua/midi_in/midi_in_main")
---
require ("lua/midi_in/midi_in_panel_1")
require ("lua/midi_in/midi_in_panel_2")
require ("lua/midi_in/midi_in_panel_3")
require ("lua/midi_in/midi_in_panel_4")
---
require ("lua/midi_in/midi_in_panel_5")
require ("lua/midi_in/midi_in_panel_6")
require ("lua/midi_in/midi_in_panel_7")
require ("lua/midi_in/midi_in_panel_8")
---
require ("lua/midi_in/midi_in_panel_9")
require ("lua/midi_in/midi_in_panel_10")
require ("lua/midi_in/midi_in_panel_11")
require ("lua/midi_in/midi_in_panel_12")
require ("lua/midi_in/midi_in_panel_13")
require ("lua/midi_in/midi_in_panel_14")
require ("lua/midi_in/midi_in_panel_15")
require ("lua/midi_in/midi_in_panel_16")
---
require ("lua/midi_in/midi_in_panel_fav")
require ("lua/midi_in/midi_in_sequencer")
---
require ("lua/panel/pad_panel_1")
require ("lua/panel/pad_panel_2")
require ("lua/panel/pad_panel_3")
require ("lua/panel/pad_panel_4")
---
require ("lua/panel/pad_panel_5")
require ("lua/panel/pad_panel_6")
require ("lua/panel/pad_panel_7")
require ("lua/panel/pad_panel_8")
---
require ("lua/panel/pad_panel_9")
require ("lua/panel/pad_panel_10")
require ("lua/panel/pad_panel_11")
require ("lua/panel/pad_panel_12")
---
require ("lua/panel/pad_panel_13")
require ("lua/panel/pad_panel_14")
require ("lua/panel/pad_panel_15")
require ("lua/panel/pad_panel_16")
---
require ("lua/panel/pad_panel_fav")
require ("lua/sequencer")
---

require ("lua/miscellaneous")
require ("lua/colors")
require ("lua/commands")
require ("lua/about")
---
require ("lua/keyhandler")

---test
require ("test")



-------------------------------------------------------------------------------------------------
--timer restore & change state text - intermittent marker
local pht_clock_marker = os.clock()
function pht_intermittent_marker()
  local BTT = vws.PHT_STATUS_BTT
  --print("pht_clock_marker",pht_clock_marker)
  --print("os.clock()",os.clock())
  if ( os.clock() > pht_clock_marker + 0.25 ) then
    if ( BTT.color ~= PHT_MAIN_COLOR.GOLD_ON ) then
      BTT.color = PHT_MAIN_COLOR.GOLD_ON
      BTT.bitmap = "./ico/exclamation_ico.png"
    end
  end
  if ( os.clock() > pht_clock_marker + 0.90 ) then
    if ( BTT.color ~= PHT_MAIN_COLOR.GOLD_OFF1 ) then  
      BTT.color = PHT_MAIN_COLOR.GOLD_OFF1
      BTT.bitmap = "./ico/empty_ico.png"
    end
    pht_clock_marker = os.clock()
  end
end
---
function pht_timer_restore_status()
  PHT_STATUS_BAR.visible = true
  if ( rnt:has_timer( pht_timer_restore_status ) ) then
    vws.PHT_STATUS_TEXT.text = ""
    if ( PHT_COMPACT_MODE_STATUS == false ) then
      PHT_STATUS_BAR.visible = false      
    end
    rnt:remove_timer( pht_timer_restore_status )
  else    
    rnt:add_timer( pht_timer_restore_status, 7000 ) --timer = 5000 (5 sec)
  end
  ---
  if ( rnt:has_timer( pht_intermittent_marker ) ) then
    rnt:remove_timer( pht_intermittent_marker )
    vws.PHT_STATUS_BTT.visible = false
  else
    rnt:add_timer( pht_intermittent_marker, 100 )
    vws.PHT_STATUS_BTT.visible = true
  end  
end
---
function pht_change_status( text )
  local status = text
  --before remove timer
  if ( rnt:has_timer( pht_timer_restore_status ) ) then
    rnt:remove_timer( pht_timer_restore_status )
  end
  if ( rnt:has_timer( pht_intermittent_marker ) ) then
    rnt:remove_timer( pht_intermittent_marker )
  end
  --after active timer
  pht_timer_restore_status()
  pht_intermittent_marker()
  vws.PHT_STATUS_TEXT.text = status
end
---
PHT_MAIN_LOGO = vb:row {
  visible = false,
  vb:horizontal_aligner {
    id = "PHT_MAIN_LOGO_WIDTH",
    width = 935, ------------<<
    mode = "right",
    vb:bitmap {
      height = 24,
      width = 116,
      mode = "body_color",
      bitmap = "./ico/phrasetouch_ico.png",
    }
  }
}
---
PHT_STATUS_BAR = vb:column { spacing = -24,
  visible = false,
  vb:row {
    id = "PHT_STATUS_BAR",
    spacing = 3,
    height = 21,
    vb:button {
      id = "PHT_STATUS_BTT",
      visible = false,
      active = false,
      height = 21,
      width = 21,
      bitmap = "./ico/empty_ico.png",
      color = PHT_MAIN_COLOR.GOLD_OFF1
    },
    vb:text {
      id = "PHT_STATUS_TEXT",
      height = 21,
      text = ""
    }
  },
  PHT_MAIN_LOGO
}



-----------------------------------------------------------------------------------------------
--osc server
class "PHT_OscClient"
     
function PHT_OscClient:__init( osc_host, osc_port, protocol )
  self._connection = nil
  local client, socket_error = renoise.Socket.create_client( osc_host, osc_port, protocol )
  if ( socket_error ) then 
    rna:show_warning( "Warning: Failed to start the internal OSC client" )
    self._connection = nil
  else
    self._connection = client
  end
end

-- Trigger instrument-note
  --- note_on (bool), true when note-on and false when note-off
  --- instr    (int), the Renoise instrument index 1-254
  --- track    (int), the Renoise track index 
  --- note     (int), the desired pitch, 0-119
  --- velocity (int), the desired velocity, 0-127
function PHT_OscClient:trigger_instrument( note_on, instr, track, note, velocity )
  if not self._connection then
    return false
  end
  local osc_vars = { }
        osc_vars[1] = { tag = "i", value = instr }
        osc_vars[2] = { tag = "i", value = track }
        osc_vars[3] = { tag = "i", value = note  }
        
  local header = nil
  if ( note_on ) then
    header = "/renoise/trigger/note_on"
      osc_vars[4] = { tag = "i", value = velocity }    
  else
    header = "/renoise/trigger/note_off"
  end
  self._connection:send( renoise.Osc.Message( header, osc_vars ) )
  return true
end
pht_osc_client = PHT_OscClient( "127.0.0.1", 8000, 2 )



-------------------------------------------------------------------------------------------------
--panic and unmark main button
function pht_panic_main( val_1, val_2 )  
  local sti = song.selected_track_index
  local sii = song.selected_instrument_index
  local vel_1 = vws.PHT_SLIDER_VOL_1.value
  local vel_2 = vws.PHT_SLIDER_VOL_2.value
  local vel_3 = vws.PHT_SLIDER_VOL_3.value
  local vel_4 = vws.PHT_SLIDER_VOL_4.value
  local vel_5 = vws.PHT_SLIDER_VOL_5.value
  local vel_6 = vws.PHT_SLIDER_VOL_6.value
  local vel_7 = vws.PHT_SLIDER_VOL_7.value
  local vel_8 = vws.PHT_SLIDER_VOL_8.value
  local vel_9 = vws.PHT_SLIDER_VOL_9.value
  local vel_10 = vws.PHT_SLIDER_VOL_10.value
  local vel_11 = vws.PHT_SLIDER_VOL_11.value
  local vel_12 = vws.PHT_SLIDER_VOL_12.value
  local vel_13 = vws.PHT_SLIDER_VOL_13.value
  local vel_14 = vws.PHT_SLIDER_VOL_14.value
  local vel_15 = vws.PHT_SLIDER_VOL_15.value
  local vel_16 = vws.PHT_SLIDER_VOL_16.value
  local clr = PHT_MAIN_COLOR.GOLD_OFF1
  
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_1(), pht_sel_trk_1(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_2(), pht_sel_trk_2(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_3(), pht_sel_trk_3(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_4(), pht_sel_trk_4(), i )
  end
  ---
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_5(), pht_sel_trk_5(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_6(), pht_sel_trk_6(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_7(), pht_sel_trk_7(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_8(), pht_sel_trk_8(), i )
  end
  ---  
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_9(), pht_sel_trk_9(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_10(), pht_sel_trk_10(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_11(), pht_sel_trk_11(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_12(), pht_sel_trk_12(), i )
  end
  ---
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_13(), pht_sel_trk_13(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_14(), pht_sel_trk_14(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_15(), pht_sel_trk_15(), i )
  end
  for i = val_1, val_2 do
    pht_osc_client:trigger_instrument( false, pht_sel_ins_16(), pht_sel_trk_16(), i )
  end
  ---
  for i = val_1, val_2 do  
    vws["PHT_NTE_ON_BTT_1_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_2_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_3_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_4_"..i].color = clr
  end
  ---
  for i = val_1, val_2 do  
    vws["PHT_NTE_ON_BTT_5_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_6_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_7_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_8_"..i].color = clr
  end
  ---
  for i = val_1, val_2 do  
    vws["PHT_NTE_ON_BTT_9_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_10_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_11_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_12_"..i].color = clr
  end
  ---
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_13_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_14_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_15_"..i].color = clr
  end
  for i = val_1, val_2 do
    vws["PHT_NTE_ON_BTT_16_"..i].color = clr
  end
  ---
  pht_table_rel_restore_1( val_1, val_2 )
  pht_table_rel_restore_2( val_1, val_2 )
  pht_table_rel_restore_3( val_1, val_2 )
  pht_table_rel_restore_4( val_1, val_2 )
  ---
  pht_table_rel_restore_5( val_1, val_2 )
  pht_table_rel_restore_6( val_1, val_2 )
  pht_table_rel_restore_7( val_1, val_2 )
  pht_table_rel_restore_8( val_1, val_2 )
  ---
  pht_table_rel_restore_9( val_1, val_2 )
  pht_table_rel_restore_10( val_1, val_2 )
  pht_table_rel_restore_11( val_1, val_2 )
  pht_table_rel_restore_12( val_1, val_2 )
  ---
  pht_table_rel_restore_13( val_1, val_2 )
  pht_table_rel_restore_14( val_1, val_2 )
  pht_table_rel_restore_15( val_1, val_2 )
  pht_table_rel_restore_16( val_1, val_2 )
  --restore tr & ins idex
  song.selected_track_index = sti
  song.selected_instrument_index = sii
end
---
function pht_unmark_main( val_1, val_2 )
  pht_unmark_1( val_1, val_2 )
  pht_unmark_2( val_1, val_2 )
  pht_unmark_3( val_1, val_2 )
  pht_unmark_4( val_1, val_2 )
  ---
  pht_unmark_5( val_1, val_2 )
  pht_unmark_6( val_1, val_2 )
  pht_unmark_7( val_1, val_2 )
  pht_unmark_8( val_1, val_2 )
  ---
  pht_unmark_9( val_1, val_2 )
  pht_unmark_10( val_1, val_2 )
  pht_unmark_11( val_1, val_2 )
  pht_unmark_12( val_1, val_2 )
  ---
  pht_unmark_13( val_1, val_2 )
  pht_unmark_14( val_1, val_2 )
  pht_unmark_15( val_1, val_2 )
  pht_unmark_16( val_1, val_2 )
end
---
PHT_PANIC_UNMARK = vb:row {  spacing = -2,
  vb:button {
    id = "PHT_M_PANIC",
    height = 29,
    width = 39,
    color = PHT_MAIN_COLOR.RED_OFF_1,
    text = "PANIC",
    notifier = function() pht_panic_main( 0, 119 ) end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Main Panic Button",
    tooltip = "Main panic for all the panels\nStop all the sound triggered from the tool, but does not stop the song playback!\n[º]"
  },
  vb:button {
    id = "PHT_M_UNMARK",
    height = 29,
    width = 14,
    color = PHT_MAIN_COLOR.GREY_OFF,
    pressed = function() pht_unmark_main( 0, 119 ) end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Main Unmark Button",
    tooltip = "Main unmark for all the panels"
  }
}



-------------------------------------------------------------------------------------------------
--play, stop, edit_mode, undo, redo, jump pattern editor, jump phrase editor
function pht_play_pattern()
  local play_mode_1 = renoise.Transport.PLAYMODE_RESTART_PATTERN
  local play_mode_2 = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  if ( song.transport.playing == true ) then
    song.transport:start( play_mode_1 )
    pht_change_status( "Restart the current pattern." )
  else
    song.transport:start( play_mode_2 )
    pht_change_status( "Start & continue the current pattern." )
  end
end
---
function pht_stop_pattern()
  if ( song.transport.playing == true ) then
    song.transport:stop()
    pht_change_status( "Stop the current pattern & Panic the sound." )
  else
    song.transport.playback_pos = renoise.SongPos( song.selected_sequence_index, 1 )
    song.selected_line_index = 1
    pht_change_status( "First line selected & Panic the sound." )
  end
  song.transport:panic()
end
---
function pht_edit_mode()
  if ( song.transport.edit_mode == false ) then
    song.transport.edit_mode = true
    local detached = ""
    if ( rna.window.instrument_editor_is_detached == true ) then
      rna.window.instrument_editor_is_detached = false
      detached = "Instrument editor window reattached!!! "
    else
      detached = ""
    end
    if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR ) then
      rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
      pht_change_status( detached.."Edit Mode enabled & pattern editor selected." )
    else
      pht_change_status( detached.."Edit Mode enabled." )
    end    
  else
    song.transport.edit_mode = false
    pht_change_status( "Edit Mode disabled." )
  end
end
---
function pht_undo()
  if ( song:can_undo() ) then
    song:undo()
    pht_change_status( "Undo." )
  else
    pht_change_status( "No Undo!" )
  end
end
---
function pht_redo()
  if ( song:can_redo() ) then
    song:redo()
    pht_change_status( "Redo." )
  else
    pht_change_status( "No Redo!" )
  end
end
---
function pht_jump_pattern_editor()
  rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  pht_change_status( "Pattern editor selected." )
end
---
function pht_jump_phrase_editor()
  rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
  song.selected_instrument.phrase_editor_visible = true
  song.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
  show_tool_dialog()
  pht_change_status( "Phrase editor & keymap playback mode selected." )
end
---
function pht_show_plugin()
 local plp = song.selected_instrument.plugin_properties.plugin_device
  if ( plp ~= nil ) then
    if ( plp.external_editor_visible == false ) then
      plp.external_editor_visible = true
    else
      plp.external_editor_visible = false
    end
  else
    if ( rna.window.active_middle_frame ~= renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR ) then
      rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR
      show_tool_dialog()
      pht_change_status( "Plugin editor selected." )
    end
  end
end
---
function pht_prev_plug_pres()
  local plug = song.selected_instrument.plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset - 1 > 0 ) then
      plug.active_preset = plug.active_preset - 1
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    else
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    end
  else
    pht_change_status( "No plugin loaded / No programs available!" )
  end
end
---
function pht_next_plug_pres()
  local plug = song.selected_instrument.plugin_properties.plugin_device
  if ( plug ~= nil ) then
    if ( plug.active_preset + 1 <= #plug.presets ) then
      plug.active_preset = plug.active_preset + 1
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    else
      pht_change_status( ("%s: %s"):format(plug.name, plug:preset(plug.active_preset)) )
    end
  else
    pht_change_status( "No plugin loaded / No programs available!" )
  end
end
---
function pht_show_midi()
  rna.window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR
  show_tool_dialog()
  pht_change_status( "MIDI monitor selected." )
end
---
PHT_BASIC_CONTROLS = vb:row { spacing = -1,
  vb:row { spacing = -3,
    vb:button {
      id = "PHT_BASIC_PLAY",
      height = 29,
      width = 34,
      bitmap = "./ico/play_ico.png",
      notifier = function() pht_play_pattern() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Play Pattern Button",
      tooltip = "Play the selected pattern\nWith active playback: restore the pattern\nWith inactive playback: continue the pattern\n[Space]  [R.Alt]"
    },
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/stop_first_ico.png",
      notifier = function() pht_stop_pattern() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Stop Pattern Button",
      tooltip = "Stop & jump first line\nStop the selected pattern & jump first line to restore the pattern in two steps\n"..
                "This operation include Panic the sound!\n[Space]  [R.Alt]"
    },
    vb:button {
      id = "PHT_BASIC_EDIT_MODE",
      height = 29,
      width = 34,
      bitmap = "./ico/rec_on_ico.png",
      notifier = function() pht_edit_mode() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Edit Mode Button",
      tooltip = PHT_EDIT_MODE_TOOLTIP
    }
  },
  vb:row { spacing = -3,
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/undo_ico.png",
      notifier = function() pht_undo() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Undo Button",
      tooltip = "Undo\n[Ctrl + Z]"
    },
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/redo_ico.png",
      notifier = function() pht_redo() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Redo Button",
      tooltip = "Redo\n[Ctrl + Y]"
    }
  },
  vb:row { width = 11 },
  vb:row { spacing = -3,
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/pattern_editor_ico.png",
      notifier = function() pht_jump_pattern_editor() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show Pattern Editor Button",
      tooltip = "Show Pattern Editor\n[F9]"
    },
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/phrase_editor_ico.png",
      notifier = function() pht_jump_phrase_editor() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show Phrase Editor Button",
      tooltip = "Show Phrase Editor of the selected instrument, with \"Keymap\" mode\n[F10]"
    },
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/plugin_ico.png",
      notifier = function() pht_show_plugin() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show/Hide Plugin External Editor Button",
      tooltip = "Show/Hide the Plugin External Editor of the selected instrument. If the plugin not exist, show the Plugin Editor\n[F11]"
    },
    vb:button {
      height = 29,
      width = 34,
      bitmap = "./ico/midi_ico.png",
      notifier = function() pht_show_midi() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show MIDI Monitor Button",
      tooltip = "Show the MIDI monitor of the selected instrument\n[F12]"
    },
    vb:row { width = 5 },
    vb:button {
      id = "PHT_BT_SEQ",
      height = 29,
      width = 34,
      bitmap = "./ico/seq_ico.png",
      notifier = function() show_tool_dialog_sequencer() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show Step Sequencer Window Button",
      tooltip = "Show Step Sequencer window...\n[Ctrl + Q]  [Ctrl + Alt + Q, to close]"
    },
    vb:button {
      id = "PHT_BT_FAV",
      height = 29,
      width = 34,
      bitmap = "./ico/fav_ico.png",
      notifier = function() show_tool_dialog_fav() end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:Show FavTouch Window Button",
      tooltip = "Show FavTouch window...\n[Ctrl + F]  [Ctrl + Alt + F, to close]"
    }
  }
}


-------------------------------------------------------------------------------------------------
--panels. 1 to 16
local PHT_MAIN_P01_P02 = vb:column { spacing = 5, PHT_PAD_PANEL_1, PHT_PAD_PANEL_2 }
local PHT_MAIN_P03_P04 = vb:column { spacing = 5, PHT_PAD_PANEL_3, PHT_PAD_PANEL_4 }
local PHT_MAIN_P01_P04 = vb:row { spacing = 5, PHT_MAIN_P01_P02, PHT_MAIN_P03_P04 }
---
local PHT_MAIN_P05_P06 = vb:column { spacing = 5, PHT_PAD_PANEL_5, PHT_PAD_PANEL_6 }
local PHT_MAIN_P07_P08 = vb:column { spacing = 5, PHT_PAD_PANEL_7, PHT_PAD_PANEL_8 }
local PHT_MAIN_P05_P08 = vb:row { spacing = 5, PHT_MAIN_P05_P06, PHT_MAIN_P07_P08 }
---
local PHT_MAIN_P09_P10 = vb:column { spacing = 5, PHT_PAD_PANEL_9, PHT_PAD_PANEL_10 }
local PHT_MAIN_P11_P12 = vb:column { spacing = 5, PHT_PAD_PANEL_11, PHT_PAD_PANEL_12 }
local PHT_MAIN_P09_P12 = vb:row { spacing = 5, PHT_MAIN_P09_P10, PHT_MAIN_P11_P12 }
---
local PHT_MAIN_P13_P14 = vb:column { spacing = 5, PHT_PAD_PANEL_13, PHT_PAD_PANEL_14 }
local PHT_MAIN_P15_P16 = vb:column { spacing = 5, PHT_PAD_PANEL_15, PHT_PAD_PANEL_16 }
local PHT_MAIN_P13_P16 = vb:row { spacing = 5, PHT_MAIN_P13_P14, PHT_MAIN_P15_P16 }
---
function pht_main_p01_p04()
  PHT_PAD_PANEL_2.visible = false
  PHT_MAIN_P03_P04.visible = false
  PHT_MAIN_P05_P08.visible = false
  PHT_MAIN_P09_P12.visible = false
  PHT_MAIN_P13_P16.visible = false
  return PHT_MAIN_P01_P04, PHT_MAIN_P05_P08, PHT_MAIN_P09_P12, PHT_MAIN_P13_P16
end
---
PHT_SEL_PNL_GR = { true, false, false, false }
PHT_SEL_PNL_MN = { true, false, false }
---


--logo in panels
function pht_logo_width( w )
  local logo = vws.PHT_MAIN_LOGO_WIDTH
  if ( logo.width ~= w ) then logo.width = w end
end

--panels in x4
function pht_panels_p01_p04( b ) if ( PHT_MAIN_P01_P04.visible ~= b ) then PHT_MAIN_P01_P04.visible = b end end
---
function pht_panels_p05_p08( b ) if ( PHT_MAIN_P05_P08.visible ~= b ) then PHT_MAIN_P05_P08.visible = b end end
---
function pht_panels_p09_p12( b ) if ( PHT_MAIN_P09_P12.visible ~= b ) then PHT_MAIN_P09_P12.visible = b end end
---
function pht_panels_p13_p16( b ) if ( PHT_MAIN_P13_P16.visible ~= b ) then PHT_MAIN_P13_P16.visible = b end end

--panels in x2
function pht_panels_p03_p04( b ) if ( PHT_MAIN_P03_P04.visible ~= b ) then PHT_MAIN_P03_P04.visible = b end end
---
function pht_panels_p07_p08( b ) if ( PHT_MAIN_P07_P08.visible ~= b ) then PHT_MAIN_P07_P08.visible = b end end
---
function pht_panels_p11_p12( b ) if ( PHT_MAIN_P11_P12.visible ~= b ) then PHT_MAIN_P11_P12.visible = b end end
---
function pht_panels_p15_p16( b ) if ( PHT_MAIN_P15_P16.visible ~= b ) then PHT_MAIN_P15_P16.visible = b end end

--panels in x1
function pht_panels_p02( b ) if ( PHT_PAD_PANEL_2.visible ~= b )  then PHT_PAD_PANEL_2.visible = b end end
---
function pht_panels_p06( b ) if ( PHT_PAD_PANEL_6.visible ~= b )  then PHT_PAD_PANEL_6.visible = b end end
---
function pht_panels_p10( b ) if ( PHT_PAD_PANEL_10.visible ~= b ) then PHT_PAD_PANEL_10.visible = b end end
---
function pht_panels_p14( b ) if ( PHT_PAD_PANEL_14.visible ~= b ) then PHT_PAD_PANEL_14.visible = b end end



function pht_sel_pnl_mn_all()
  --- ---panels 01 to 04
  if ( PHT_SEL_PNL_GR[1] == true ) then
    pht_panels_p05_p08( false )
    pht_panels_p09_p12( false )
    pht_panels_p13_p16( false )
    pht_panels_p01_p04( true )
    ---
    if ( PHT_SEL_PNL_MN[1] == true ) then
      pht_logo_width( 935 )
      pht_panels_p03_p04( false )
      pht_panels_p02( false )
    --end
    ---
    elseif ( PHT_SEL_PNL_MN[2] == true ) then
      pht_logo_width( 935 )
      pht_panels_p03_p04( false )
      pht_panels_p02( true )
    --end
    ---
    else --( PHT_SEL_PNL_MN[3] == true ) then
      pht_logo_width( 1878 )
      pht_panels_p03_p04( true )
      pht_panels_p02( true )
    end
  --end
  --- ---panels 05 to 08
  elseif ( PHT_SEL_PNL_GR[2] == true ) then
    pht_panels_p01_p04( false )
    pht_panels_p09_p12( false )
    pht_panels_p13_p16( false )
    pht_panels_p05_p08( true )
    ---
    if ( PHT_SEL_PNL_MN[1] == true ) then
      pht_logo_width( 935 )
      pht_panels_p07_p08( false )
      pht_panels_p06( false )
    --nd
    ---
    elseif ( PHT_SEL_PNL_MN[2] == true ) then
      pht_logo_width( 935 )
      pht_panels_p07_p08( false )
      pht_panels_p06( true )
    --end
    ---
    else --( PHT_SEL_PNL_MN[3] == true ) then
      pht_logo_width( 1878 )
      pht_panels_p07_p08( true )
      pht_panels_p06( true )
    end
  --end
  --- ---panels 09 to 12
  elseif ( PHT_SEL_PNL_GR[3] == true ) then
    pht_panels_p01_p04( false )
    pht_panels_p05_p08( false )
    pht_panels_p13_p16( false )
    pht_panels_p09_p12( true )
    ---
    if ( PHT_SEL_PNL_MN[1] == true ) then
      pht_logo_width( 935 )
      pht_panels_p11_p12( false )
      pht_panels_p10( false )
    --end
    ---
    elseif ( PHT_SEL_PNL_MN[2] == true ) then
      pht_logo_width( 935 )
      pht_panels_p11_p12( false )
      pht_panels_p10( true )
    --end
    ---
    else --( PHT_SEL_PNL_MN[3] == true ) then
      pht_logo_width( 1878 )
      pht_panels_p11_p12( true )
      pht_panels_p10( true )
    end
  --end
  --- ---panels 13 to 16
  else --( PHT_SEL_PNL_GR[4] == true ) then
    pht_panels_p01_p04( false )
    pht_panels_p05_p08( false )
    pht_panels_p09_p12( false )
    pht_panels_p13_p16( true )
    ---
    if ( PHT_SEL_PNL_MN[1] == true ) then
      pht_logo_width( 935 )
      pht_panels_p15_p16( false )
      pht_panels_p14( false )
    --end
    ---
    elseif ( PHT_SEL_PNL_MN[2] == true ) then
      pht_logo_width( 935 )
      pht_panels_p15_p16( false )
      pht_panels_p14( true )
    --end
    ---
    else --( PHT_SEL_PNL_MN[3] == true ) then
      pht_logo_width( 1878 )
      pht_panels_p15_p16( true )
      pht_panels_p14( true )
    end
  end
end
---
function pht_sel_pnl_gr( value )
  for i = 1, 4 do
    if ( value == i ) then
      vws["PHT_BT_PNL_GR_X"..i].color = PHT_MAIN_COLOR.SKY_BLUE
      PHT_SEL_PNL_GR[ i ] = true
    else
      vws["PHT_BT_PNL_GR_X"..i].color = PHT_MAIN_COLOR.DEFAULT
      PHT_SEL_PNL_GR[ i ] = false
    end
  end
  pht_sel_pnl_mn_all()
  --print( "PHT_SEL_PNL_GR------------" ) rprint( PHT_SEL_PNL_GR )
  --print( "PHT_SEL_PNL_MN------------" ) rprint( PHT_SEL_PNL_MN )
end
---
function pht_sel_pnl_mn( value )
  for i = 1, 3 do
    if ( value == i ) then
      vws["PHT_BT_PNL_MN_X"..i].color = PHT_MAIN_COLOR.SKY_BLUE
      PHT_SEL_PNL_MN[ i ] = true
    else
      vws["PHT_BT_PNL_MN_X"..i].color = PHT_MAIN_COLOR.DEFAULT
      PHT_SEL_PNL_MN[ i ] = false      
    end
  end
  pht_sel_pnl_mn_all()
  --print( "PHT_SEL_PNL_GR------------" ) rprint( PHT_SEL_PNL_GR )
  --print( "PHT_SEL_PNL_MN------------" ) rprint( PHT_SEL_PNL_MN )
end
---
PHT_MAIN_PANELS_CONTROL_X16 = vb:row { spacing = -3,
  vb:row { spacing = -3,
    vb:column { spacing = -3,
      vb:button {
        id = "PHT_BT_PNL_GR_X1",
        height = 16,
        width = 34,
        color = PHT_MAIN_COLOR.SKY_BLUE,
        bitmap = "/ico/1_ico.png",
        pressed = function() pht_sel_pnl_gr( 1 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Panel Selector Group 1 Button",
        tooltip = "Selector for panels of notes 1 to 4\n[F1]"
      },
      vb:button {
        id = "PHT_BT_PNL_GR_X2",
        height = 16,
        width = 34,
        bitmap = "/ico/5_ico.png",
        pressed = function() pht_sel_pnl_gr( 2 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Panel Selector Group 5 Button",
        tooltip = "Selector for panels of notes 5 to 8\n[F2]"    
      }
    },
    vb:column { spacing = -3,
      vb:button {
        id = "PHT_BT_PNL_GR_X3",
        height = 16,
        width = 34,
        bitmap = "/ico/9_ico.png",
        pressed = function() pht_sel_pnl_gr( 3 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Panel Selector Group 9 Button",
        tooltip = "Selector for panels of notes 9 to 12\n[F3]"    
      },
      vb:button {
        id = "PHT_BT_PNL_GR_X4",
        height = 16,
        width = 34,
        bitmap = "/ico/13_ico.png",
        pressed = function() pht_sel_pnl_gr( 4 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Panel Selector Group 13 Button",
        tooltip = "Selector for panels of notes 13 to 16\n[F4]"    
      }
    }
  },
  vb:row { margin = 1,
    vb:row { style = "panel", margin = 3, spacing = -3,
      vb:button {
        id = "PHT_BT_PNL_MN_X1",
        height = 21,
        width = 34,
        color = PHT_MAIN_COLOR.SKY_BLUE,
        bitmap = "./ico/panel_1_ico.png",
        pressed = function() pht_sel_pnl_mn( 1 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show A Note Panel Button",
        tooltip = "Show only a panel of notes\n[F5]  [F8, show only the panel 1]"
      },
      vb:button {
        id = "PHT_BT_PNL_MN_X2",
        height = 21,
        width = 34,
        bitmap = "./ico/panel_2_ico.png",
        pressed = function() pht_sel_pnl_mn( 2 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Two Note Panels Button",
        tooltip = "Show only two panels of notes\n[F6]"
      },
      vb:button {
        id = "PHT_BT_PNL_MN_X3",
        height = 21,
        width = 34,
        bitmap = "./ico/panel_3_ico.png",
        pressed = function() pht_sel_pnl_mn( 3 ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Four Note Panels Button",
        tooltip = "Show four panels of notes\n[F7]"
      }
    }
  }
}



-------------------------------------------------------------------------------------------------
--main controls
local pht_misce = { false, false, false, false, true } --3 & 4 is for misccellaneous_3... 5 is for gem!
--miscellaneous 3 add timer
function pht_misc_mode_1_add_timer()
  if not rnt:has_timer( pht_misc_mode_1_add_timer ) then
    rnt:add_timer( pht_misc_mode_1_add_timer, 1200 )
  else
    if ( PHT_MISCELLANEOUS_3.visible == true ) then
      PHT_MISCELLANEOUS_3.visible = false
      if ( pht_misce[3] == false ) then
        vws.PHT_BT_MISCELLANEOUS_1.color = PHT_MAIN_COLOR.DEFAULT
      end
      pht_misce[4] = false
    else
      PHT_MISCELLANEOUS_3.visible = true
      vws.PHT_BT_MISCELLANEOUS_1.color = PHT_MAIN_COLOR.GOLD_ON
      pht_misce[4] = true
      ---gem
      if ( pht_misce[5] == true ) then
        pht_change_status( " YOU HAVE FOUND A GEM !!!  ENJOY IT  :)" )
        pht_misce[5] = false
      end
      ---
    end
    pht_misce[3] = true
  end
end
--miscellaneous 3 remove timer
function pht_misc_mode_1_remove_timer()
  if rnt:has_timer( pht_misc_mode_1_add_timer ) then
    rnt:remove_timer( pht_misc_mode_1_add_timer )
  end
  if ( pht_misce[3] == false ) then
    pht_miscellaneous_mode_1()
  end
  pht_misce[3] = false
end
---
function pht_miscellaneous_mode_1()
  if ( PHT_MISCELLANEOUS_1.visible == true ) then
    PHT_MISCELLANEOUS_1.visible = false
    if ( pht_misce[4] == false ) then 
      vws.PHT_BT_MISCELLANEOUS_1.color = PHT_MAIN_COLOR.DEFAULT
    end
    pht_misce[1] = false
  else
    PHT_MISCELLANEOUS_1.visible = true
    vws.PHT_BT_MISCELLANEOUS_1.color = PHT_MAIN_COLOR.GOLD_ON
    pht_misce[1] = true
  end
end
function pht_miscellaneous_mode_2()
  if ( PHT_MISCELLANEOUS_2.visible == true ) then
    PHT_MISCELLANEOUS_2.visible = false
    vws.PHT_BT_MISCELLANEOUS_2.color = PHT_MAIN_COLOR.DEFAULT
    pht_misce[2] = false
  else
    PHT_MISCELLANEOUS_2.visible = true
    vws.PHT_BT_MISCELLANEOUS_2.color = PHT_MAIN_COLOR.GOLD_ON
    pht_misce[2] = true
  end
end
---
PHT_COMPACT_MODE_STATUS = false
function pht_compact_mode()
  if ( PHT_COMPACT_MODE_STATUS == false ) then
    PHT_MAIN_LOGO.visible = true
    vws.PHT_PANIC_UNMARK.visible = true
    vws.PHT_COMPACT.bitmap = "./ico/compact_on_ico.png"
    PHT_MISCELLANEOUS_1.visible = false
    PHT_MISCELLANEOUS_2.visible = false
    PHT_MISCELLANEOUS_3.visible = false
    PHT_COMPACT_MODE_STATUS = true
    PHT_STATUS_BAR.visible = true
  else
    PHT_MAIN_LOGO.visible = false
    PHT_STATUS_BAR.visible = false
    vws.PHT_PANIC_UNMARK.visible = false
    vws.PHT_COMPACT.bitmap = "./ico/compact_off_ico.png"
    if ( pht_misce[1] == true ) then
      PHT_MISCELLANEOUS_1.visible = true
    end
    if ( pht_misce[2] == true ) then
      PHT_MISCELLANEOUS_2.visible = true
    end
    if ( pht_misce[4] == true ) then ---
      PHT_MISCELLANEOUS_3.visible = true
    end
    PHT_COMPACT_MODE_STATUS = false
  end
  ---
  if ( vws.PHT_MAIN_PANELS_CONTROL_ALL.visible == false ) then
    vws.PHT_MAIN_PANELS_CONTROL_ALL.visible = true
  else
    vws.PHT_MAIN_PANELS_CONTROL_ALL.visible = false
  end
  ---
  if ( vws.PHT_MAIN_PANELS_ALL.visible == false ) then
    vws.PHT_MAIN_PANELS_ALL.visible = true
  else
    vws.PHT_MAIN_PANELS_ALL.visible = false
  end
  ---
  if ( vws.PHT_MINI_MENU.visible == true ) then
    vws.PHT_MINI_MENU.visible = false
  else
    vws.PHT_MINI_MENU.visible = true
  end
end
---
function pht_vb_notes_tostring( value )
  local string = { "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11", "P12", "P13", "P14", "P15", "P16", "FAV" }
  return string[ value ]
end
---
function pht_vb_notes_tonumber( value )
  local string_1 = { "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11", "P12", "P13", "P14", "P15", "P16", "FAV" }
  local string_2 = { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12", "p13", "p14", "p15", "p16", "Fav" }
  local string_3 = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "fav" }
  local number = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
  for i = 1, 17 do
    if ( value == string_1[ i ] ) or ( value == string_2[ i ] ) or ( value == string_3[ i ] ) then
      return number[ i ]
    end
  end
end
function pht_vb_notes_notifier( value )
  PHT_VB_KB_NOTES.value = value
  if ( value == 17 ) then
    vws.PHT_FAV_KEYBOARD.color = PHT_MAIN_COLOR.GOLD_ON
  else
    vws.PHT_FAV_KEYBOARD.color = PHT_MAIN_COLOR.DEFAULT
  end
end
---
PHT_VB_NOTES = vb:valuebox {
  height = 18,
  width = 53,
  min = 1,
  max = 17,
  value = 1,
  tostring = function( value ) return pht_vb_notes_tostring( value ) end,
  tonumber = function( value ) return pht_vb_notes_tonumber( value ) end,
  notifier = function( value ) pht_vb_notes_notifier( value ) end,
  midi_mapping = "Tools:PhraseTouch:Main Controls:General:USB Keyboard Panel Selector Valuebox",
  tooltip = "Panel selector to control the notes with USB keyboard\n[Range: 1 to 16 & FAV]\n"..
            "Control the notes with P/R mode enabled (until 32 notes).\nSelect a specific panel & octave into Renoise valuebox (Oct).\n↓[Ctrl + Numpad /]  ↑[Ctrl + Numpad *]  [Ctrl + Numlock, to FAV]"
}



------------------------------------------------------------------------------------------------
--multi-phrases
--lock, unlock
local PHT_LOCK_TR_INS_MLT = false
function pht_lock_tr_ins_multi()
  if ( PHT_LOCK_TR_INS_MLT == false ) then
    PHT_LOCK_TR_INS_MLT = true
    vws.PHT_DISTRIB_TRK_MULTI.active = false
    vws.PHT_DISTRIB_INS_MULTI.active = false
    vws.PHT_LOCK_TR_INS_MULTI.bitmap = "./ico/padlock_close_ico.png"
    vws.PHT_LOCK_TR_INS_MULTI.color = PHT_MAIN_COLOR.GOLD_ON
    for i = 1, 16 do
      if ( vws["PHT_VB_SEL_TRK_"..i].active == true ) then
        vws["PHT_VB_SEL_TRK_"..i].active = false
        vws["PHT_VB_SEL_INS_"..i].active = false
        vws["PHT_LOCK_TR_INS_"..i].bitmap = "./ico/padlock_close_ico.png"
        vws["PHT_LOCK_TR_INS_"..i].color = PHT_MAIN_COLOR.GOLD_ON
      end
    end
  else
    PHT_LOCK_TR_INS_MLT = false
    vws.PHT_DISTRIB_TRK_MULTI.active = true
    vws.PHT_DISTRIB_INS_MULTI.active = true
    vws.PHT_LOCK_TR_INS_MULTI.bitmap = "./ico/padlock_open_ico.png"
    vws.PHT_LOCK_TR_INS_MULTI.color = PHT_MAIN_COLOR.DEFAULT
    for i = 1, 16 do
      if ( vws["PHT_VB_SEL_TRK_"..i].active == false ) then
        vws["PHT_VB_SEL_TRK_"..i].active = true
        vws["PHT_VB_SEL_INS_"..i].active = true
        vws["PHT_LOCK_TR_INS_"..i].bitmap = "./ico/padlock_open_ico.png"
        vws["PHT_LOCK_TR_INS_"..i].color = PHT_MAIN_COLOR.DEFAULT
      end
    end
  end
end
---
PHT_LOCK_TR_INS_MULTI = vb:button {
  id = "PHT_LOCK_TR_INS_MULTI",
  height = 21,
  width = 29,
  bitmap = "./ico/padlock_open_ico.png",
  notifier = function() pht_lock_tr_ins_multi() end,
  midi_mapping = "Tools:PhraseTouch:Main Controls:General:Main Lock/Unlock Checkbox",
  tooltip = "General Lock/Unlock\nLock/Unlock the valueboxes for the track and instrument selectors for chosen panels\n"..
            "Lock it for greater security when playing!"
}
--anchor
local PHT_ANCHOR_TR_INS_MLT = false
function  pht_anchor_tr_ins_multi_bol( bol )
  PHT_ANCHOR_1 = bol pht_anchor_tr_ins_1()
  PHT_ANCHOR_2 = bol pht_anchor_tr_ins_2()
  PHT_ANCHOR_3 = bol pht_anchor_tr_ins_3()
  PHT_ANCHOR_4 = bol pht_anchor_tr_ins_4()
  PHT_ANCHOR_5 = bol pht_anchor_tr_ins_5()
  PHT_ANCHOR_6 = bol pht_anchor_tr_ins_6()
  PHT_ANCHOR_7 = bol pht_anchor_tr_ins_7()
  PHT_ANCHOR_8 = bol pht_anchor_tr_ins_8()
  PHT_ANCHOR_9 = bol pht_anchor_tr_ins_9()
  PHT_ANCHOR_10 = bol pht_anchor_tr_ins_10()
  PHT_ANCHOR_11 = bol pht_anchor_tr_ins_11()
  PHT_ANCHOR_12 = bol pht_anchor_tr_ins_12()
  PHT_ANCHOR_13 = bol pht_anchor_tr_ins_13()
  PHT_ANCHOR_14 = bol pht_anchor_tr_ins_14()
  PHT_ANCHOR_15 = bol pht_anchor_tr_ins_15()
  PHT_ANCHOR_16 = bol pht_anchor_tr_ins_16()
end
---
function pht_anchor_tr_ins_multi()
  if ( PHT_ANCHOR_TR_INS_MLT == false ) then
    PHT_ANCHOR_TR_INS_MLT = true
    vws.PHT_ANCHOR_TR_INS_MULTI.bitmap = "./ico/anchor_true_ico.png"
    vws.PHT_ANCHOR_TR_INS_MULTI.color = PHT_MAIN_COLOR.GOLD_ON
    pht_anchor_tr_ins_multi_bol( false )
    for i = 1, 16 do
      --PHT_ANCHOR_TBL[i] = true
      vws["PHT_ANCHOR_TR_INS_"..i].bitmap = "./ico/anchor_true_ico.png"
      vws["PHT_ANCHOR_TR_INS_"..i].color = PHT_MAIN_COLOR.GOLD_ON
    end
  else
    PHT_ANCHOR_TR_INS_MLT = false
    vws.PHT_ANCHOR_TR_INS_MULTI.bitmap = "./ico/anchor_false_ico.png"
    vws.PHT_ANCHOR_TR_INS_MULTI.color = PHT_MAIN_COLOR.DEFAULT
    pht_anchor_tr_ins_multi_bol( true )
    for i = 1, 16 do
      --PHT_ANCHOR_TBL[i] = false
      vws["PHT_ANCHOR_TR_INS_"..i].bitmap = "./ico/anchor_false_ico.png"
      vws["PHT_ANCHOR_TR_INS_"..i].color = PHT_MAIN_COLOR.DEFAULT
    end
  end
end
---
PHT_ANCHOR_TR_INS_MULTI = vb:button {
  id = "PHT_ANCHOR_TR_INS_MULTI",
  height = 21,
  width = 29,
  bitmap = "./ico/anchor_false_ico.png",
  notifier = function() pht_anchor_tr_ins_multi() end,
  midi_mapping = "Tools:PhraseTouch:Main Controls:General:Main Anchor Checkbox",
  tooltip = "General Anchor\nAnchor the valueboxes for the track & the instrument for chosen panels\n"..
            "Prevents the automatic selection of track and instrument"
}
---
--distribute track per panel
function pht_distrib_track()
  local stc = song.sequencer_track_count
  local sti = song.selected_track_index
  for i = 1, 16 do
    local idx = i + sti - 1
    if ( idx <= stc ) then
      vws["PHT_VB_SEL_TRK_"..i].max = stc
      vws["PHT_VB_SEL_TRK_"..i].value = idx
    end
  end
  song.selected_track_index = sti
  if ( sti <= stc ) then
    pht_change_status( "The tracks have been distributed for each panel starting from track "..("%.3d"):format(sti).."." )
  else
    pht_change_status( "Select before a track to start the distribution!" )
  end
end
---
--distribute instrument per panel
function pht_distrib_instr()
  local ins = #song.instruments
  local sii = song.selected_instrument_index
  for i = 1, 16 do
    local idx = i + sii - 1
    if ( idx <= ins ) then
      vws["PHT_VB_SEL_INS_"..i].max = ins
      vws["PHT_VB_SEL_INS_"..i].value = idx
    end
  end
  song.selected_instrument_index = sii
  pht_change_status( "The instruments have been distributed for each panel starting from instrument "..("%.2X"):format(sii - 1).."." )
end
---
PHT_DISTRIB_TRK_INS_PNL = vb:row { spacing = -3,
  vb:button {
    id = "PHT_DISTRIB_TRK_MULTI",
    height = 21,
    width = 34,
    bitmap = "./ico/track_distribute_ico.png",
    notifier = function() pht_distrib_track() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:General:Auto Distribute Tracks Button",
    tooltip = "Auto distributes the tracks for each panel\nFirst select a track in the pattern editor to start. Use consecutive tracks, not groups!"
  },
  vb:button {
    id = "PHT_DISTRIB_INS_MULTI",
    height = 21,
    width = 34,
    bitmap = "./ico/instr_distribute_ico.png",
    notifier = function() pht_distrib_instr() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:General:Auto Distribute Instruments Button",
    tooltip = "Auto distributes the instruments for each panel\nFirst select a instrument in the instrument box to start"
  }
}
---
--multitouch chain all pannels with timer
PHT_MUL_PHR = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } --16
PHT_MUL_PNL = { _1 = 1, _2 = 2, _3 = 3, _4 = 4, _5 = 5, _6 = 6, _7 = 7, _8 = 8, _9 = 9, _10 = 10, _11 = 11, _12 = 12, _13 = 13, _14 = 14, _15 = 15, _16 = 16 }
PHT_MUL_TMR = 0
--multitouch add timer selector
function pht_mc_pnls_add_timer( value )
  if ( value ~= nil ) then
    PHT_MUL_TMR = PHT_MUL_PNL[value]
  end
  if not rnt:has_timer( pht_mc_pnls_add_timer ) then
    rnt:add_timer( pht_mc_pnls_add_timer, 1200 )
  else
    if PHT_MUL_TMR ~= 1 then
      for i = PHT_MUL_TMR, 1, -1 do
        PHT_MUL_PHR[ i ] = not PHT_MUL_PHR[ PHT_MUL_TMR ]
        pht_pln_name_multi( "_"..i )
      end
    else
      for i = 16, 2, -1 do
        PHT_MUL_PHR[ i ] = not PHT_MUL_PHR[ 1 ]
        pht_pln_name_multi( "_"..i )
      end
    end
  end
end
--multitouch remove timer selector
function pht_mc_pnls_remove_timer()
  if rnt:has_timer( pht_mc_pnls_add_timer ) then
    rnt:remove_timer( pht_mc_pnls_add_timer )
  end
end
---
--multitouch
function pht_pln_name_multi( value )
  if ( PHT_MUL_PHR[ PHT_MUL_PNL[value] ] == false ) then
    PHT_MUL_PHR[ PHT_MUL_PNL[value] ] = true
    vws["PHT_PNL_NAME_"..PHT_MUL_PNL[value]].bitmap = "/ico/"..PHT_MUL_PNL[value].."_big_chain_ico.png"
  else
    PHT_MUL_PHR[ PHT_MUL_PNL[value] ] = false
    vws["PHT_PNL_NAME_"..PHT_MUL_PNL[value]].bitmap = "/ico/"..PHT_MUL_PNL[value].."_big_ico.png"
  end
end
---
function pht_multi_restore_panel_1( ins_1, tr_1 )
  if ( song.selected_instrument_index ~= ins_1 ) then
    song.selected_instrument_index = ins_1
  end
  if ( song.selected_track_index ~= tr_1 ) then
    song.selected_track_index = tr_1
  end
end
---
function pht_multi_pressed( nte_1, ins_1, tr_1 )
  if ( PHT_MUL_PHR[ 1 ] == true ) then
    if ( PHT_MUL_PHR[ 2 ] == true ) then pht_osc_bt_pres_2( nte_1 ) end
    if ( PHT_MUL_PHR[ 3 ] == true ) then pht_osc_bt_pres_3( nte_1 ) end
    if ( PHT_MUL_PHR[ 4 ] == true ) then pht_osc_bt_pres_4( nte_1 ) end
    if ( PHT_MUL_PHR[ 5 ] == true ) then pht_osc_bt_pres_5( nte_1 ) end
    if ( PHT_MUL_PHR[ 6 ] == true ) then pht_osc_bt_pres_6( nte_1 ) end
    if ( PHT_MUL_PHR[ 7 ] == true ) then pht_osc_bt_pres_7( nte_1 ) end
    if ( PHT_MUL_PHR[ 8 ] == true ) then pht_osc_bt_pres_8( nte_1 ) end
    if ( PHT_MUL_PHR[ 9 ] == true ) then pht_osc_bt_pres_9( nte_1 ) end
    if ( PHT_MUL_PHR[ 10 ] == true ) then pht_osc_bt_pres_10( nte_1 ) end
    if ( PHT_MUL_PHR[ 11 ] == true ) then pht_osc_bt_pres_11( nte_1 ) end
    if ( PHT_MUL_PHR[ 12 ] == true ) then pht_osc_bt_pres_12( nte_1 ) end
    if ( PHT_MUL_PHR[ 13 ] == true ) then pht_osc_bt_pres_13( nte_1 ) end
    if ( PHT_MUL_PHR[ 14 ] == true ) then pht_osc_bt_pres_14( nte_1 ) end
    if ( PHT_MUL_PHR[ 15 ] == true ) then pht_osc_bt_pres_15( nte_1 ) end
    if ( PHT_MUL_PHR[ 16 ] == true ) then pht_osc_bt_pres_16( nte_1 ) end
    pht_multi_restore_panel_1( ins_1, tr_1 ) --restore panel 1
  end
end
---
function pht_multi_released( nte_1, ins_1, tr_1 )
  if ( PHT_MUL_PHR[ 1 ] == true ) then
    if ( PHT_MUL_PHR[ 2 ] == true ) then pht_osc_bt_rel_2( nte_1 ) end
    if ( PHT_MUL_PHR[ 3 ] == true ) then pht_osc_bt_rel_3( nte_1 ) end
    if ( PHT_MUL_PHR[ 4 ] == true ) then pht_osc_bt_rel_4( nte_1 ) end
    if ( PHT_MUL_PHR[ 5 ] == true ) then pht_osc_bt_rel_5( nte_1 ) end
    if ( PHT_MUL_PHR[ 6 ] == true ) then pht_osc_bt_rel_6( nte_1 ) end
    if ( PHT_MUL_PHR[ 7 ] == true ) then pht_osc_bt_rel_7( nte_1 ) end
    if ( PHT_MUL_PHR[ 8 ] == true ) then pht_osc_bt_rel_8( nte_1 ) end
    if ( PHT_MUL_PHR[ 9 ] == true ) then pht_osc_bt_rel_9( nte_1 ) end
    if ( PHT_MUL_PHR[ 10 ] == true ) then pht_osc_bt_rel_10( nte_1 ) end
    if ( PHT_MUL_PHR[ 11 ] == true ) then pht_osc_bt_rel_11( nte_1 ) end
    if ( PHT_MUL_PHR[ 12 ] == true ) then pht_osc_bt_rel_12( nte_1 ) end
    if ( PHT_MUL_PHR[ 13 ] == true ) then pht_osc_bt_rel_13( nte_1 ) end
    if ( PHT_MUL_PHR[ 14 ] == true ) then pht_osc_bt_rel_14( nte_1 ) end
    if ( PHT_MUL_PHR[ 15 ] == true ) then pht_osc_bt_rel_15( nte_1 ) end
    if ( PHT_MUL_PHR[ 16 ] == true ) then pht_osc_bt_rel_16( nte_1 ) end
    pht_multi_restore_panel_1( ins_1, tr_1 ) --restore panel 1
  end
end
---
function pht_multi_sustain( nte_1, ins_1, tr_1 )
  if ( PHT_MUL_PHR[ 1 ] == true ) then
    if ( PHT_MUL_PHR[ 2 ] == true ) then pht_osc_bt_sus_2( nte_1 ) end
    if ( PHT_MUL_PHR[ 3 ] == true ) then pht_osc_bt_sus_3( nte_1 ) end
    if ( PHT_MUL_PHR[ 4 ] == true ) then pht_osc_bt_sus_4( nte_1 ) end
    if ( PHT_MUL_PHR[ 5 ] == true ) then pht_osc_bt_sus_5( nte_1 ) end
    if ( PHT_MUL_PHR[ 6 ] == true ) then pht_osc_bt_sus_6( nte_1 ) end
    if ( PHT_MUL_PHR[ 7 ] == true ) then pht_osc_bt_sus_7( nte_1 ) end
    if ( PHT_MUL_PHR[ 8 ] == true ) then pht_osc_bt_sus_8( nte_1 ) end
    if ( PHT_MUL_PHR[ 9 ] == true ) then pht_osc_bt_sus_9( nte_1 ) end
    if ( PHT_MUL_PHR[ 10 ] == true ) then pht_osc_bt_sus_10( nte_1 ) end
    if ( PHT_MUL_PHR[ 11 ] == true ) then pht_osc_bt_sus_11( nte_1 ) end
    if ( PHT_MUL_PHR[ 12 ] == true ) then pht_osc_bt_sus_12( nte_1 ) end
    if ( PHT_MUL_PHR[ 13 ] == true ) then pht_osc_bt_sus_13( nte_1 ) end
    if ( PHT_MUL_PHR[ 14 ] == true ) then pht_osc_bt_sus_14( nte_1 ) end
    if ( PHT_MUL_PHR[ 15 ] == true ) then pht_osc_bt_sus_15( nte_1 ) end
    if ( PHT_MUL_PHR[ 16 ] == true ) then pht_osc_bt_sus_16( nte_1 ) end
    pht_multi_restore_panel_1( ins_1, tr_1 ) --restore panel 1
  end
end
---
function pht_asp_multi_modes( i, val, bol )
  if ( i == 1 ) then PHT_ASP_1[val] = bol pht_asp_1( val ) if ( val == 2 ) then pht_sustain_mode_1( PHT_ASP_1[val] ) end if ( val == 3 ) then pht_pres_rel_mode_1( PHT_ASP_1[val] ) end end
  if ( i == 2 ) then PHT_ASP_2[val] = bol pht_asp_2( val ) if ( val == 2 ) then pht_sustain_mode_2( PHT_ASP_2[val] ) end if ( val == 3 ) then pht_pres_rel_mode_2( PHT_ASP_2[val] ) end end
  if ( i == 3 ) then PHT_ASP_3[val] = bol pht_asp_3( val ) if ( val == 2 ) then pht_sustain_mode_3( PHT_ASP_3[val] ) end if ( val == 3 ) then pht_pres_rel_mode_3( PHT_ASP_3[val] ) end end
  if ( i == 4 ) then PHT_ASP_4[val] = bol pht_asp_4( val ) if ( val == 2 ) then pht_sustain_mode_4( PHT_ASP_4[val] ) end if ( val == 3 ) then pht_pres_rel_mode_4( PHT_ASP_4[val] ) end end
  if ( i == 5 ) then PHT_ASP_5[val] = bol pht_asp_5( val ) if ( val == 2 ) then pht_sustain_mode_5( PHT_ASP_5[val] ) end if ( val == 3 ) then pht_pres_rel_mode_5( PHT_ASP_5[val] ) end end
  if ( i == 6 ) then PHT_ASP_6[val] = bol pht_asp_6( val ) if ( val == 2 ) then pht_sustain_mode_6( PHT_ASP_6[val] ) end if ( val == 3 ) then pht_pres_rel_mode_6( PHT_ASP_6[val] ) end end
  if ( i == 7 ) then PHT_ASP_7[val] = bol pht_asp_7( val ) if ( val == 2 ) then pht_sustain_mode_7( PHT_ASP_7[val] ) end if ( val == 3 ) then pht_pres_rel_mode_7( PHT_ASP_7[val] ) end end
  if ( i == 8 ) then PHT_ASP_8[val] = bol pht_asp_8( val ) if ( val == 2 ) then pht_sustain_mode_8( PHT_ASP_8[val] ) end if ( val == 3 ) then pht_pres_rel_mode_8( PHT_ASP_8[val] ) end end
  if ( i == 9 ) then PHT_ASP_9[val] = bol pht_asp_9( val ) if ( val == 2 ) then pht_sustain_mode_9( PHT_ASP_9[val] ) end if ( val == 3 ) then pht_pres_rel_mode_9( PHT_ASP_9[val] ) end end
  if ( i == 10 ) then PHT_ASP_10[val] = bol pht_asp_10( val ) if ( val == 2 ) then pht_sustain_mode_10( PHT_ASP_10[val] ) end if ( val == 3 ) then pht_pres_rel_mode_10( PHT_ASP_10[val] ) end end
  if ( i == 11 ) then PHT_ASP_11[val] = bol pht_asp_11( val ) if ( val == 2 ) then pht_sustain_mode_11( PHT_ASP_11[val] ) end if ( val == 3 ) then pht_pres_rel_mode_11( PHT_ASP_11[val] ) end end
  if ( i == 12 ) then PHT_ASP_12[val] = bol pht_asp_12( val ) if ( val == 2 ) then pht_sustain_mode_12( PHT_ASP_12[val] ) end if ( val == 3 ) then pht_pres_rel_mode_12( PHT_ASP_12[val] ) end end
  if ( i == 13 ) then PHT_ASP_13[val] = bol pht_asp_13( val ) if ( val == 2 ) then pht_sustain_mode_13( PHT_ASP_13[val] ) end if ( val == 3 ) then pht_pres_rel_mode_13( PHT_ASP_13[val] ) end end
  if ( i == 14 ) then PHT_ASP_14[val] = bol pht_asp_14( val ) if ( val == 2 ) then pht_sustain_mode_14( PHT_ASP_14[val] ) end if ( val == 3 ) then pht_pres_rel_mode_14( PHT_ASP_14[val] ) end end
  if ( i == 15 ) then PHT_ASP_15[val] = bol pht_asp_15( val ) if ( val == 2 ) then pht_sustain_mode_15( PHT_ASP_15[val] ) end if ( val == 3 ) then pht_pres_rel_mode_15( PHT_ASP_15[val] ) end end
  if ( i == 16 ) then PHT_ASP_16[val] = bol pht_asp_16( val ) if ( val == 2 ) then pht_sustain_mode_16( PHT_ASP_16[val] ) end if ( val == 3 ) then pht_pres_rel_mode_16( PHT_ASP_16[val] ) end end
end
---
PHT_ASP_MULTI = { false, true, false }
function pht_asp_multi( value )
  if ( PHT_ASP_MULTI[value] == false ) then
    PHT_ASP_MULTI[value] = true
    vws["PHT_BT_ASP_MULTI_X"..value].color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_BT_ASP_MULTI_X1.active = true
  else
    PHT_ASP_MULTI[value] = false
    vws["PHT_BT_ASP_MULTI_X"..value].color = PHT_MAIN_COLOR.DEFAULT
  end
  if ( PHT_ASP_MULTI[2] == false ) and ( PHT_ASP_MULTI[3] == false ) then
    vws.PHT_BT_ASP_MULTI_X1.active = false
  end
end
---
function pht_touch_all_mode_multi( value )
  for i = 1, 16 do
    pht_asp_multi_modes( i, 1, value )
  end
end
---
function pht_sustain_mode_multi( value )
  for i = 1, 16 do
    pht_asp_multi_modes( i, 2, value )
  end
  if ( PHT_ASP_MULTI[3] == true ) then
    vws.PHT_BT_ASP_MULTI_X3.color = PHT_MAIN_COLOR.DEFAULT
    PHT_ASP_MULTI[3] = false
    vws.PHT_BT_ASP_MULTI_X1.active = false
  end
end
---
function pht_pres_rel_mode_multi( value )
  for i = 1, 16 do
    pht_asp_multi_modes( i, 3, value )
  end
  if ( PHT_ASP_MULTI[2] == false ) then
    vws.PHT_BT_ASP_MULTI_X2.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_ASP_MULTI[2] = true
  end
end
---
PHT_SUS_TOU_MULTI = vb:row { spacing = 8,
  vb:row { spacing = -1,
    vb:button {
      id = "PHT_BT_ASP_MULTI_X1",
      height = 21,
      width = 34,
      text = "ALL",
      pressed = function() pht_asp_multi( 1 ) pht_touch_all_mode_multi( not PHT_ASP_MULTI[1] ) end,
      midi_mapping = "Tools:PhraseTouch:Main Controls:General:Main Touch All Checkbox (ALL)",
      tooltip = "General All Mode\nTouch all the keys for all panels without stopping those already played.\nCombine it with the \"SUS\" &/or \"P/R\" checkbox"
    },
    vb:row { spacing = -3,
      vb:button {
        id = "PHT_BT_ASP_MULTI_X2",
        height = 21,
        width = 34,
        text = "SUS",
        color = PHT_MAIN_COLOR.GOLD_ON,
        pressed = function() pht_asp_multi( 2 ) pht_sustain_mode_multi( not PHT_ASP_MULTI[2] ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:General:Main Sustain Checkbox (SUS)",
        tooltip = "General Sustain Mode\nSustain the key recently pressed and stop the rest for all panels\nCombine it with the \"ALL\" &/or \"P/R\" checkbox"
      },    
      vb:button {
        id = "PHT_BT_ASP_MULTI_X3",
        height = 21,
        width = 34,
        text = "P/R",
        color = PHT_MAIN_COLOR.DEFAULT,
        pressed = function() pht_asp_multi( 3 ) pht_pres_rel_mode_multi( not PHT_ASP_MULTI[3] ) end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:General:Main Pressed & Released Checkbox (P/R)",
        tooltip = "General Pressed & Released Mode for Sustain Mode\nPress and release with the same key for all panels. Recommended for MIDI Pads!\n"..
                  "SUS checkbox must be activated! Combine it with the \"ALL\" checkbox"
      }
    }    
  }
}
---
PHT_MULTI_PHRASES = vb:row { margin = 1,
  vb:row { style = "panel", margin = 3, spacing = 3,
    PHT_SUS_TOU_MULTI,
    PHT_DISTRIB_TRK_INS_PNL,
    vb:row { spacing = -3,
      PHT_LOCK_TR_INS_MULTI,
      PHT_ANCHOR_TR_INS_MULTI
    }
  }
}
---
PHT_MAIN_CONTROLS = vb:row { spacing = 9,
  vb:row {
    id = "PHT_PANIC_UNMARK",
    visible = false,
    PHT_PANIC_UNMARK
  },
  PHT_BASIC_CONTROLS,
  vb:row { spacing = 3,
    id = "PHT_MAIN_PANELS_CONTROL_ALL",
    visible = false,
    PHT_MAIN_PANELS_CONTROL_X16,
    PHT_MULTI_PHRASES,
    vb:column { 
      vb:bitmap {
        height = 11,
        width = 53,
        mode =  "body_color",
        bitmap = "./ico/keyboard_mini_ico.png"
      },
      PHT_VB_NOTES,
    }
  },
  vb:row { spacing = 5,
    id = "PHT_MINI_MENU",
    vb:row { spacing = -3,
      vb:button {
        id = "PHT_BT_MISCELLANEOUS_1",
        height = 29,
        width = 34,
        bitmap = "./ico/miscellaneous_ico.png",
        pressed = function() pht_misc_mode_1_add_timer() end,
        released = function() pht_misc_mode_1_remove_timer() end,
        --notifier = function() pht_miscellaneous_mode_1() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Miscellaneous I Button",
        tooltip = "Show/Hide Miscellaneous I"
      },
      vb:button {
        id = "PHT_BT_MISCELLANEOUS_2",
        height = 29,
        width = 34,
        bitmap = "./ico/folder_ico.png",
        notifier = function() pht_miscellaneous_mode_2() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Miscellaneous II Button",
        tooltip = "Show/Hide Miscellaneous II"
      }
    },
    vb:row { spacing = -3,
      vb:button {
        height = 29,
        width = 34,
        bitmap = "./ico/keyboard_ico.png",
        notifier = function() show_tool_dialog_keyboard() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show Keyboard Commands Button",
        tooltip = "Show Keyboard Commands window...\n[Ctrl + K]  [Ctrl + Alt + K, to close]"
      },
      vb:button {
        height = 29,
        width = 34,
        bitmap = "./ico/question_ico.png",
        notifier = function() show_tool_dialog_about() end,
        midi_mapping = "Tools:PhraseTouch:Main Controls:Show About & User Guide Button",
        tooltip = "Show About PhraseTouch & User Guide window..."
      }
    }
  },
  vb:button {
    id = "PHT_COMPACT",
    height = 29,
    width = 37,
    color = PHT_MAIN_COLOR.SKY_BLUE,
    bitmap = "./ico/compact_off_ico.png",
    notifier = function() pht_compact_mode() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Compact Mode View Button",
    tooltip = "Compact Mode View\n[Back]"
  }
}



-------------------------------------------------------------------------------------------------
--main content gui
PHT_GEN_CONTENT = vb:row {
  vb:column { margin = 5, spacing = 4,
    id = "PHT_CONTENT",
    vb:row {
      PHT_MAIN_CONTROLS,
    },
    PHT_MISCELLANEOUS_1,
    PHT_MISCELLANEOUS_2,
    PHT_MISCELLANEOUS_3,
    vb:row {
      id = "PHT_MAIN_PANELS_ALL",
      visible = false,
      pht_main_p01_p04()
    },
    PHT_STATUS_BAR,
    --PHT_BUTTON_TEST,
    --vb:row { style = "plain", margin = 4, vb:text { text = " RNXZ  RNXI K P O " }}
  }
}



------------------------------------------------------------------------------------------------
-- playing observable (phrasetouch) | edit_mode observable (phrasetouch, step sequencer & favtouch)
function pht_play_obs()
  if ( song.transport.playing == true ) then
    vws.PHT_BASIC_PLAY.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_FAV_BT_PLAY.color = PHT_MAIN_COLOR.GOLD_ON
  else
    vws.PHT_BASIC_PLAY.color = PHT_MAIN_COLOR_DEF.DEFAULT_DEF
    vws.PHT_FAV_BT_PLAY.color = PHT_MAIN_COLOR_DEF.DEFAULT_DEF
  end
  if not ( song.transport.playing_observable:has_notifier( pht_play_obs ) ) then
    song.transport.playing_observable:add_notifier( pht_play_obs )
  end
end
---
function pht_edit_mode_obs()
  if ( song.transport.edit_mode == true ) then
    vws.PHT_BASIC_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.RED_ON_DEF
    vws.PHT_FAV_BT_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.RED_ON_DEF
    vws.PHT_SEQ_BT_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.RED_ON_DEF
  else
    vws.PHT_BASIC_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.DEFAULT_DEF
    vws.PHT_FAV_BT_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.DEFAULT_DEF
    vws.PHT_SEQ_BT_EDIT_MODE.color = PHT_MAIN_COLOR_DEF.DEFAULT_DEF
  end
  if not ( song.transport.edit_mode_observable:has_notifier( pht_edit_mode_obs ) ) then
    song.transport.edit_mode_observable:add_notifier( pht_edit_mode_obs )
  end
end



------------------------------------------------------------------------------------------------
--show dialog
local pht_status_welcome = true
function show_tool_dialog()
  --observables
  pht_play_obs()
  pht_edit_mode_obs()
  --avoid showing the same window several times!
  if ( dialog and dialog.visible ) then dialog:show() return end
  dialog = rna:show_custom_dialog( pht_title, PHT_GEN_CONTENT, pht_keyhandler )
  --welcome status
  if ( pht_status_welcome == true ) then
    pht_change_status( "Welcome to PhraseTouch  ...created by ulneiz" )
    pht_status_welcome = false
  end
  --reload show_tool_dialog() in new song
  if not rnt.app_new_document_observable:has_notifier( show_tool_dialog ) then
    rnt.app_new_document_observable:add_notifier( show_tool_dialog )
  end  
end



------------------------------------------------------------------------------------------------
-- register menu entry
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:PhraseTouch...",
  invoke = function() show_tool_dialog() end
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseTouch...",
  invoke = function() show_tool_dialog() end
}

renoise.tool():add_menu_entry {
  name = "Mixer:PhraseTouch...",
  invoke = function() show_tool_dialog() end
}

renoise.tool():add_menu_entry {
  name = "Phrase Editor:PhraseTouch...",
  invoke = function() show_tool_dialog() end
}



------------------------------------------------------------------------------------------------
-- register keybinding
renoise.tool():add_keybinding {
  name = "Global:Tools:PhraseTouch",
  invoke = function() if dialog.visible == false then show_tool_dialog() else dialog:close() end end
}
