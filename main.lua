-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: KangarooX120
-- Version: 1.1 build 030
-- Compatibility: Renoise v3.1.1
-- Development date: June to July 2018
-- Published: July 2018
-- Locate: Spain
-- Programmer: ulneiz
--
-- Font: "Century Gotic"
--
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


--**************************************
--collectgarbage (top)
  --collectgarbage( "stop" )
--**************************************



--**************************************
--auto reload debug 
_AUTO_RELOAD_DEBUG = function() kng_main_dialog() end
--**************************************


-------------------------------------------------------------------------------------------------
--local global variables/tables
KNG_MAIN_DIALOG = nil
KNG_MAIN_CONTENT = nil
KNG_INVOKE_STATUS = true
local kng_main_title = " KangarooX120"
local kng_version = "1.1"
local kng_build = "build 030"
local rns_version = renoise.RENOISE_VERSION
local api_version = renoise.API_VERSION
---
local vb = renoise.ViewBuilder()
vws = vb.views
rna = renoise.app()
rnt = renoise.tool()

--global song
song = nil
  function kng_sng() song = renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier( kng_sng ) --catching start renoise or new song
  pcall( kng_sng ) --catching installation

--colors
KNG_CLR = {
  RED_1    = { 249,000,000 }, RED_2    = { 150,000,000 }, RED_3    = { 249,125,125 }, RED_4    = { 150,097,097 }, RED_5 = { 090,000,000 },
  GREEN_1  = { 000,249,041 }, GREEN_2  = { 000,150,025 }, GREEN_3  = { 125,249,146 }, GREEN_4  = { 097,150,106 },
  BLUE_1   = { 000,083,249 }, BLUE_2   = { 000,050,150 }, BLUE_3   = { 125,166,249 }, BLUE_4   = { 097,115,150 },
  YELLOW_1 = { 249,249,000 }, YELLOW_2 = { 150,150,000 }, YELLOW_3 = { 250,250,126 }, YELLOW_4 = { 150,150,097 },
  PINK_1   = { 249,000,166 }, PINK_2   = { 150,000,100 }, PINK_3   = { 249,125,207 }, PINK_4   = { 150,097,132 },
  ORANGE_1 = { 249,125,000 }, ORANGE_2 = { 150,076,000 }, ORANGE_3 = { 249,187,125 }, ORANGE_4 = { 150,123,093 },
  VIOLET_1 = { 137,000,249 }, VIOLET_2 = { 082,000,150 }, VIOLET_3 = { 194,125,249 }, VIOLET_4 = { 126,097,150 },
  GRAY_1   = { 229,229,229 }, GRAY_2   = { 052,052,052 }, GRAY_3   = { 189,189,189 }, GRAY_4   = { 132,132,132 }, 
  BLACK    = { 001,000,000 }, WHITE    = { 235,235,235 }, DEFAULT  = { 000,000,000 }, MARKER   = { 235,235,235 }
}

-------------------------------------------------------------------------------------------------
--capture the native color of marker (for Windows: C:\Users\USER_NAME\AppData\Roaming\Renoise\V3.1.1\Config.xml)
local function kng_capture_clr_mrk()
  --print ( os.currentdir() )

  --Config.xml path:  
    --Windows: %appdata%\Renoise\V3.1.1\Config.xml
    --MacOS: ~/Library/Logs/, ~/Library/Preferences/Renoise/V3.1.1/Config.xml
    --Linux: ~/.renoise/V3.1.1/Config.xml

  local filename = ""
  if ( os.platform() == "WINDOWS" ) then
    filename = ("%s\\Renoise\\V%s\\Config.xml"):format( os.getenv("APPDATA"), rns_version )
    --print("Windows:", filename )
  elseif ( os.platform() == "MACINTOSH" ) then
    filename = ("%s/Library/Preferences/Renoise/V%s/Config.xml"):format( os.getenv("HOME"), rns_version )
    --print("MacOS:", filename )
  elseif ( os.platform() == "LINUX" ) then
    filename = ( "%s/.renoise/V%s/Config.xml"):format( os.getenv("HOME"), rns_version )
    --print("Linux:", filename )
  end
  --print( filename )
  
  --RenoisePrefs
    --SkinColors
      --Selected_Button_Back

  if ( io.exists( filename ) ) then
    local pref_data = renoise.Document.create("RenoisePrefs") { SkinColors = { Selected_Button_Back = "" } }
    pref_data:load_from( filename )
    --print( pref_data.SkinColors.Selected_Button_Back )
    local rgb = tostring(pref_data.SkinColors.Selected_Button_Back)
    local one, two, thr = rgb:match( "([^,]+),([^,]+),([^,]+)" )
    KNG_CLR.MARKER[1] = tonumber(one)
    KNG_CLR.MARKER[2] = tonumber(two)
    KNG_CLR.MARKER[3] = tonumber(thr)
  end
end
kng_capture_clr_mrk()

--input device
KNG_INPUT_DEVICE = { "", "", "", "" }



--about
local KNG_ABOUT_TTP = 
  "TOOL NAME: KangarooX120\n"..
  "VERSION: "..kng_version.." "..kng_build.." \n"..
  "COMPATIBILITY: Renoise "..rns_version.." (tested under Windows 10)\n"..
  "OPEN SOURCE: Yes\n"..
  "LICENCE: GNU General Public Licence. Prohibited any use of commercial ambit.\n"..
  "CODE: LUA 5.1 + API Renoise "..rns_version.."\n"..
  "DEVELOPMENT DATE: June to July 2018\n"..
  "PUBLISHED: July 2018\n"..
  "LOCATE: Spain\n"..
  "PROGRAMMER: ulneiz\n"..
  "CONTACT AUTHOR: go to \"http://forum.renoise.com/\" & search: \"ulneiz\" member"



-------------------------------------------------------------------------------------------------
--tostring / tonumber for valueboxes

--note convert number (0-119) to string (C-0 to B-9) -- tostring, tonumber
function kng_note_tostring( val ) --return a string, Range val: 0 to 119
  local note_name = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
  if val < 120 then
    return ("%s%s"):format( note_name[ math.floor(val) %12 +1 ], math.floor( val/12 )  )
  elseif ( val == 121 ) then
    return "---"
  end
end

--note: convert string to number
function kng_note_tonumber( val ) --return a number
  local note_name_1 = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
  local note_name_2 = { "c-", "c#", "d-", "d#", "e-", "f-", "f#", "g-", "g#", "a-", "a#", "b-" }
  local note_name_3 = { "C",  "C#", "D",  "D#", "E",  "F" , "F#", "G",  "G#", "A",  "A#", "B"  }
  local note_name_4 = { "c",  "c#", "d",  "d#", "e",  "f",  "f#", "g",  "g#", "a",  "a#", "b"  }
  for i = 1, 12 do
    for octave = 0, 9 do
      if ( val == ("%s%s"):format( note_name_1[i], octave ) ) or
         ( val == ("%s%s"):format( note_name_2[i], octave ) ) or
         ( val == ("%s%s"):format( note_name_3[i], octave ) ) or
         ( val == ("%s%s"):format( note_name_4[i], octave ) ) then
        return i + ( octave * 12 )
      end
    end
  end
  if ( val == "NTE" ) or ( val == "Nte" ) or ( val == "nte" ) or ( val == "N" ) or ( val == "n" ) then return 0 end
end

--instrument: convert string to number
function kng_ins_tonumber( val )
  vws.KNG_VB_INS_SEL.max = #song.instruments
  if ( val == "INS" ) or ( val == "Ins" ) or ( val == "ins" ) or ( val == "I" ) or ( val == "i" ) then
    return 0
  end
  for ins = 0, 255 do
    if ( val == ("%.2X"):format(ins) ) or ( val == ("%.X"):format(ins) ) or ( val == ("%.2x"):format(ins) ) or ( val == ("%.x"):format(ins) ) or ( val == "0" ) then
      return tonumber( ins +1 )
    end
  end
end

--track: convert string to number
function kng_trk_tonumber( val )
  vws.KNG_VB_TRK_SEL.max = song.sequencer_track_count
  if ( val == "TRK" ) or ( val == "Trk" ) or ( val == "trk" ) or ( val == "T" ) or ( val == "t" ) then
    return 0
  else
    return tonumber( val )
  end
end

--pad: convert string to number
function kng_pad_tonumber( val )
  if ( val == "PAD" ) or ( val == "Pad" ) or ( val == "pad" ) or ( val == "P" ) or ( val == "p" ) then
    return 0
  else
    return tonumber( val )
  end
end



-------------------------------------------------------------------------------------------------
--define pad
local function kng_pad( oct )
  class "Kng_Pad"
  function Kng_Pad:__init( nte_1, nte_2 )
    self.cnt = vb:column { spacing = -60,
      vb:button {
        active = false,
        id = "KNG_PAD_BACKGROUND_"..nte_2,
        height = 58,
        width = 73,
        color = KNG_CLR.GRAY_2
      },
      vb:row { margin = 2, spacing = -2,
        vb:row { margin = 4,
          vb:row { margin = -2,
            vb:button {
              id = "KNG_PAD_"..nte_2,
              height = 45,
              width = 65,
              color = KNG_CLR.DEFAULT,
              text = ("%.2d\n%s  00\nTr01"):format( nte_2 + 1, kng_note_tostring( nte_2 ) ),
              pressed = function() kng_osc_bt_pad_pres( nte_2 ) end,
              released = function() kng_osc_bt_pad_rel( nte_2 ) end,
              midi_mapping = ("Tools:KangarooX120:Pads:Pad %.3d"):format( nte_2 +1 )
            }
          }
        },    
        vb:column { spacing = -7,
          id = "KNG_PAD_ROT_"..nte_2,
          visible = false,
          vb:column { 
            vb:space { height = 4 },
            vb:column { spacing = -33,
              vb:rotary {
                id = "KNG_PAD_ROT_VEL_"..nte_2,
                height = 45,
                width = 45,
                min = 0,
                max = 127,
                value = 95,
                notifier = function( value ) KNG_PAD_VEL[ nte_2 + 1 ] = value vws["KNG_PAD_ROT_VEL_TXT"..nte_2].text = ("%.2X"):format( value ) end,
                midi_mapping = ("Tools:KangarooX120:Pads:Velocity Knob %.3d"):format( nte_2 +1 )
              },
              vb:row {
                vb:space { width = 12 },
                vb:text {
                  id = "KNG_PAD_ROT_VEL_TXT"..nte_2,
                  font = "bold",
                  text = "5F"
                }
              }
            }
          },
          vb:row { margin = 1,
            vb:space { width = 32 },
            vb:row {
              vb:button {
                id = "KNG_PAD_SEL_"..nte_2, 
                height = 12,
                width = 12,
                notifier = function() vws.KNG_VB_PAD_SEL.value = nte_2 + 1 end
              }
            }
          }
        }
      }
    }
  end
  --
  local octave = vb:row { spacing = 2 }
  for i = oct * 8, oct * 8 +7 do
    octave:add_child (
      Kng_Pad( oct * 8, i ).cnt
    )
  end
  return octave
end



-------------------------------------------------------------------------------------------------
--all pads
local function kng_all_pads()
  local KNG_PAD_14_08 = vb:column { spacing = 0, visible = false,
    id = "KNG_PAD_14_08",
    --kng_pad(15),
    kng_pad(14),
    kng_pad(13),
    kng_pad(12),
    kng_pad(11),
    kng_pad(10),
    kng_pad(9),
    kng_pad(8)
  }
  ---
  local KNG_PAD_07_00 = vb:column { spacing = 0,
    id = "KNG_PAD_07_00",
    kng_pad(7),
    kng_pad(6),
    kng_pad(5),
    kng_pad(4),
    kng_pad(3),
    kng_pad(2),
    kng_pad(1),
    kng_pad(0)
  }
  ---
  local KNG_PAD_RW_PANIC = vb:row { margin = 1, style = "plain",
    vb:button {
      height = 27,
      width = 15,
      bitmap = "/ico/pad_panic_ico.png",
      color = KNG_CLR.RED_2,
      pressed = function() kng_pad_bt_panic() end,
      midi_mapping = "Tools:KangarooX120:Panic Pad",
      tooltip = "Panic pads panel\n[º]"
    }
  }
  ---
  local KNG_PAD_RW_SUS_MODE = vb:row { margin = 1, style = "plain",
    vb:button {
      id = "KNG_PAD_BT_SUS_MODE",
      height = 27,
      width = 15,
      bitmap = "/ico/pad_hld_ico.png",
      pressed = function() kng_pad_bt_sus_mode() end,
      midi_mapping = "Tools:KangarooX120:Mode Hold Pad",
      tooltip = "Hold the pressed notes of the pads panel\n[Back]"
    }
  }
  ---  
  local KNG_PAD_RW_SUS_CHAIN_MODE = vb:row { margin = 1, style = "plain",
    id = "KNG_PAD_RW_SUS_CHAIN_MODE",
    visible = false,
    vb:button {
      id = "KNG_PAD_BT_SUS_CHAIN_MODE",
      height = 27,
      width = 15,
      bitmap = "/ico/pad_sus_chain_ico.png",
      pressed = function() kng_pad_bt_sus_chain_mode() end,
      midi_mapping = "Tools:KangarooX120:Mode Hold Chain Pad",
      tooltip = "Hold in chain the pressed notes of the pads panel\n[CTRL + Back]"
    }
  }
  ---  
  local KNG_PAD = vb:row { spacing = -17,
    id = "KNG_PAD",
    vb:column { spacing = -31,
      vb:column { spacing = 0,
        KNG_PAD_14_08,
        KNG_PAD_07_00
      },
      KNG_PAD_RW_PANIC
    },
    vb:column { spacing = 31,
      KNG_PAD_RW_SUS_MODE,
      KNG_PAD_RW_SUS_CHAIN_MODE
    }
  }
  return KNG_PAD
end



-------------------------------------------------------------------------------------------------
--controls
local function kng_controls()
  local KNG_CONTROLS = vb:row {
    vb:row { spacing = -2,
      vb:button {
        id = "KNG_PAD_SHOW",
        height = 23,
        width = 37,
        bitmap = "/ico/pad_ico.png",
        color = KNG_CLR.MARKER,
        notifier = function() kng_pad_show() end,
        midi_mapping = "Tools:KangarooX120:Show Pads Panel",
        tooltip = "Show pads panel\n[F1]"
      },
      vb:row { spacing = -3,
        vb:button {
          id = "KNG_PAD_VISIBLE_1",
          height = 23,
          width = 25,
          bitmap = "/ico/panel_1_ico.png",
          color = KNG_CLR.MARKER,
          notifier = function() kng_pad_visible( 1 ) end,
          midi_mapping = "Tools:KangarooX120:Change Pad Area",
          tooltip = "Show pads: 1 to 64\n[F2]"
          
        },
        vb:button {
          id = "KNG_PAD_VISIBLE_2",
          height = 23,
          width = 25,
          bitmap = "/ico/panel_2_ico.png",
          notifier = function() kng_pad_visible( 2 ) end,
          --midi_mapping = "Tools:KangarooX120:Change Pad Area",
          tooltip = "Show pads: 65 to 120\n[F3]"
        },
        vb:button {
          id = "KNG_PAD_VISIBLE_3",
          height = 23,
          width = 25,
          bitmap = "/ico/panel_3_ico.png",
          notifier = function() kng_pad_visible( 3 ) end,
          --midi_mapping = "Tools:KangarooX120:Change Pad Area",
          tooltip = "Show all the pads\n[F4]"
        }
      }
    },
    vb:space { width = 5 },
    vb:row { spacing = -2,
      vb:button {
        id = "KNG_ALL_PIANO_SHOW",
        height = 23,
        width = 37,
        bitmap = "/ico/piano_ico.png",
        color = KNG_CLR.MARKER,
        notifier = function() kng_piano_show() end,
        midi_mapping = "Tools:KangarooX120:Show Piano Panel",
        tooltip = "Show virtual piano\n[F5]"
      },
      vb:button {
        id = "KNG_BT_ROT",
        height = 23,
        width = 31, 
        bitmap = "/ico/rot_ico.png",
        notifier = function() kng_vel_rotary_show( 0, 119 ) end,
        midi_mapping = "Tools:KangarooX120:Show Velocity Knobs",
        tooltip = "Show velocity knobs\nExpand horizontally the window showing the velocity knobs of the pads panel & 5 octaves of the virtual piano.\n[F6]"
      },
      vb:button {
        id = "KNG_BT_JUMP",
        height = 23,
        width = 31, 
        bitmap = "/ico/sel_jump_ico.png",
        notifier = function() kng_pad_note_sel_jump() end,
        midi_mapping = "Tools:KangarooX120:Continuous Pad Selector",
        tooltip = "Automatic pad selector\nEnable it to continuous select the pads automatically when importing\n"..
                  "notes from the virtual piano.\n[F7]"
      },
      vb:valuebox {
        id = "KNG_VB_PAD_SEL",
        width = 53,
        height = 23,
        min = 0,
        max = 120,
        value = 0,
        tostring = function( value ) if ( value < 1 ) then return "PAD" else return ("%.2d"):format( value ) end end,
        tonumber = function( value ) return kng_pad_tonumber( value ) end,
        notifier = function( value ) kng_pad_sel( value ) end,
        midi_mapping = "Tools:KangarooX120:Select Number Pad",
        tooltip = "Pad selector\nSelect any pad to import notes from the virtual piano. Use the \"NTE\", \"INS\" & \"TRK\"\n"..
                  "valueboxes to especific routing for each pad."
      },
      vb:button {
        id = "KNG_BANKS_SHOW",
        height = 23,
        width = 37,
        bitmap = "/ico/bank_ico.png",
        notifier = function() kng_bank_show() end,
        midi_mapping = "Tools:KangarooX120:Show Banks Panel",
        tooltip = "Show banks panel\nSave or load up to 96 banks. Each bank saves the configuration of all the pads, "..
                  "including the note, instrument, track, velocity & color configuration.\n"..
                  ("Every time that%s shows the banks panel, all the banks are revised again.\n[F8]\n\n"):format( kng_main_title )..
                  "To keep your banks before uninstalling the tool, make a backup of the \"banks\" folder located inside "..
                  "the tool folder. Then you can restore this \"banks\" folder manually. Each bank is an XML file that "..
                  "you can also make backup copies individually."
      }
    },
    vb:space { width = 5 },
    vb:bitmap {
      height = 23,
      width = 18,
      mode = "body_color",
      bitmap = "/ico/color_ico.png",
    },
    vb:popup {
      id = "KNG_PAD_CLR",
      height = 23,
      width = 55,
      value = 14,
      items = {" 1x2", " 1x4", " 1x8", " 2x2", " 2x4", " 2x8", " 3x2", " 3x4", " 3x8", " 4x2", " 4x4", " 4x8", " 8+4", " Drk", " Clr" },
      notifier = function( value ) kng_pad_clr( value ) end,
      midi_mapping = "Tools:KangarooX120:Select Color Pad",
      tooltip = "Pad color configuration selector\nChoose the most appropriate color configuration for the specified note distribution."
    },
    vb:space { width = 5 },
    vb:bitmap {
      height = 23,
      width = 18,
      mode = "body_color",
      bitmap = "/ico/instrument_ico.png",
    },
    vb:row { spacing = -3,
      vb:button {
        id = "KNG_INS_SEL_PAD_1",
        height = 23,
        width = 23,
        bitmap ="/ico/mini_pad_ins_ico.png",
        color = KNG_CLR.MARKER,
        notifier = function() kng_ins_sel_pad( true ) end,
        midi_mapping = "Tools:KangarooX120:Pad Instrument Mode",
        tooltip = "Pad / Selection to instrument routing\n[F9]"
      },
      vb:button {
        id = "KNG_INS_SEL_PAD_2",
        height = 23,
        width = 23,
        bitmap ="/ico/pad_sel_ins_ico.png",
        notifier = function() kng_ins_sel_pad( false ) end,
        --midi_mapping = "Tools:KangarooX120:Pad Instrument Mode",
        tooltip = "Pad / Selection to instrument routing\n[F9]"
      }
    },
    vb:space { width = 5 },
    vb:bitmap {
      height = 23,
      width = 18,
      mode = "body_color",
      bitmap = "/ico/track_ico.png",
    },
    vb:row { spacing = -3,
      vb:button {
        id = "KNG_TRK_SEL_PAD_1",
        height = 23,
        width = 23,
        bitmap ="/ico/mini_pad_trk_ico.png",
        color = KNG_CLR.MARKER,
        notifier = function() kng_trk_sel_pad( true ) end,
        midi_mapping = "Tools:KangarooX120:Pad Track Mode",
        tooltip = "Pad / Selection to track routing\n[F10]"
      },
      vb:button {
        id = "KNG_TRK_SEL_PAD_2",
        height = 23,
        width = 23,
        bitmap ="/ico/pad_sel_trk_ico.png",
        notifier = function() kng_trk_sel_pad( false ) end,
        --midi_mapping = "Tools:KangarooX120:Pad Track Mode",
        tooltip = "Pad / Selection to track routing\n[F10]"
      }
    },
    vb:button {
      id = "KNG_BT_MIDI_IN_PAD_MODE",
      height = 23,
      width = 31,
      color = KNG_CLR.MARKER,
      bitmap = "/ico/midi_in_vol_ico.png",
      notifier = function() kng_midi_in_pad_mode() end,
      midi_mapping = "Tools:KangarooX120:Velocity MIDI In Mode for Pads Panel",
      tooltip = "Velocity MIDI In mode for pads panel\nDisable it to control the velocity of each pad with the mouse.\n[F11]"
    },
    vb:row {
      id = "KNG_SPLIT_PIANO_CONTROLS",
      visible = false,
      vb:space { width = 5 },
      vb:row { spacing = -2,
        vb:button {
          id = "KNG_BT_SPLIT_PIANO",
          height = 23,
          width = 41,
          bitmap = "/ico/split_piano_ico.png",
          notifier = function() kng_bt_split_piano() end,
          midi_mapping = "Tools:KangarooX120:Split Piano Mode",
          tooltip = "Split mode for virtual piano\nSplit the virtual piano between the selected notes, with \"TRK\" valuebox selected. "..
                    "Use it to separe the low notes of the high notes [ Tr1 | Tr2* ] or low/medium/high notes into three contiguous "..
                    "tracks to write [ Tr1 | Tr2* | Tr3 ].\n*Select the track Tr2 inside the pattern editor to start.\n[F12]"
        },
        vb:valuebox {
          id = "KNG_VB_SPLIT_PIANO_1",
          active = false,
          height = 23,
          width = 53,
          min = 2,
          max = 119,
          value = 49,
          tostring = function( value ) return kng_note_tostring( value -1 ) end,
          tonumber = function( value ) return kng_note_tonumber( value ) end,
          notifier = function( value ) if ( vws.KNG_VB_SPLIT_PIANO_2.value < value +1 ) then vws.KNG_VB_SPLIT_PIANO_2.value = value +1 end end,
          midi_mapping = "Tools:KangarooX120:Split Note Selector to Piano to the Left",
          tooltip = "Left split note selector\nSelect the note to split the virtual piano to the left."
        },
        vb:valuebox {
          id = "KNG_VB_SPLIT_PIANO_2",
          active = false,
          height = 23,
          width = 53,
          min = 3,
          max = 120,
          value = 120,
          tostring = function( value ) return kng_note_tostring( value -1 ) end,
          tonumber = function( value ) return kng_note_tonumber( value ) end,
          notifier = function( value ) if ( vws.KNG_VB_SPLIT_PIANO_1.value > value -1 ) then vws.KNG_VB_SPLIT_PIANO_1.value = value -1 end end,
          midi_mapping = "Tools:KangarooX120:Split Note Selector to Piano to the Right",
          tooltip = "Right split note selector\nSelect the note to split the virtual piano to the right."
        }
      }
    },
    vb:space { width = 5 },
    vb:row { spacing = -2,
      vb:button {
        id = "KNG_BT_JUMP_LINES",
        height = 23,
        width = 31,
        bitmap = "/ico/step_length_ico.png",
        notifier = function() kng_bt_jump_lines() end,
        midi_mapping = "Tools:KangarooX120:Jump Lines Step Length",
        tooltip = "Jump lines to step length\nUse the \"step length\" valuebox of Renose to change it.\n[Apps]"
      },
      vb:button {
        id = "KNG_OPERATIONS_SHOW",
        visible = false,
        height = 23,
        width = 31,
        bitmap = "/ico/briefcase_ico.png",
        notifier = function() kng_operations_show() end,
        midi_mapping = "Tools:KangarooX120:Show Advanced Operations Panel",
        tooltip = "Show advanced operations panel\n[R.CTRL]"
      },
      vb:button {
        id = "KNG_PREFERENCES_SHOW",
        height = 23,
        width = 31,
        bitmap = "/ico/preferences_ico.png",
        notifier = function() kng_preferences_show() end,
        midi_mapping = "Tools:KangarooX120:Show Preferences Panel",
        tooltip = "Show preferences panel\n[Return]"
      }
    },
    vb:row {
      id = "KNG_LOGO",
      visible = false,
      vb:space { width = 5 },
      vb:bitmap {
        height = 23,
        width = 170,
        mode = "body_color",
        bitmap = "/ico/kangaroox120_ico.png",
        tooltip = KNG_ABOUT_TTP
      }
    }
  }
  return KNG_CONTROLS
end



-------------------------------------------------------------------------------------------------
--define bank
local function kng_bank( val_1, val_2 )
  class "Kng_Bank"
  function Kng_Bank:__init( val )
    self.cnt = vb:row { spacing = 3,
      vb:text {
        height = 21,
        width = 21,
        align = "right",
        text = ("%.2d"):format( val )
      },
      vb:textfield {
        id = "KNG_BANK_TXF_"..val,
        height = 21,
        width = 137,
        text = ("Bank %.2d"):format( val ),
        tooltip = ("Rename the bank %.2d"):format( val )
      },
      vb:row {
        vb:row { spacing = -3,
          vb:button {
            id = "KNG_BANK_BT_LOCK_SAVE_"..val,
            height = 21,
            width = 25,
            bitmap = "/ico/mini_padlock_close_ico.png",
            notifier = function() kng_lock_save_bank( val ) end,
            tooltip = ("Lock save the bank %.2d"):format( val )
          },        
          vb:button {
            active = false,
            id = "KNG_BANK_BT_SAVE_"..val,
            height = 21,
            width = 35,
            bitmap = "/ico/save_ico.png",
            notifier = function() kng_save_bank( val ) end,
            tooltip = ("Save the bank %.2d. Unlock before!"):format( val )
          }
        },
        vb:button {
          id = "KNG_BANK_BT_LOAD_"..val,
          active = false,
          height = 21,
          width = 65,
          text = ("Load %.2d"):format( val ),
          notifier = function() kng_load_bank( val ) end,
          midi_mapping = ("Tools:KangarooX120:Banks:Load %.2d"):format( val )
        }
      }
    }
  end
  ---
  local tbl = { 4,12,20,28,36,44,52,60,68,76,84,92 }
  local bank = vb:column {}
  for num = val_1, val_2 do
    bank:add_child (
      Kng_Bank( num ).cnt
    )
    if table.find( tbl, num, 1 ) ~= nil then
      bank:add_child (
        vb:space { height = 5 }
      )
    end
    if ( num < 13 ) then
      vws["KNG_BANK_BT_LOAD_"..num].tooltip = ("Load the bank %.2d\n[CTRL + F%s]"):format( num, num )
    else
      vws["KNG_BANK_BT_LOAD_"..num].tooltip = ("Load the bank %.2d"):format( num )
    end
  end
  return bank
end



-------------------------------------------------------------------------------------------------
--all banks
local function kng_all_banks()
  local KNG_BANKS_1 = vb:row {
    id = "KNG_BANKS_1",
    kng_bank(  1,  8 ),
    vb:space { width = 6 },
    kng_bank(  9, 16 ),
    vb:space { width = 6 },
    kng_bank( 17, 24 )
  }
  ---
  local KNG_BANKS_2 = vb:row {
    id = "KNG_BANKS_2",
    visible = false,
    kng_bank( 25, 32 ),
    vb:space { width = 6 },
    kng_bank( 33, 40 ),
    vb:space { width = 6 },
    kng_bank( 41, 48 )
  }
  ---
  local KNG_BANKS_3 = vb:row {
    id = "KNG_BANKS_3",
    visible = false,
    kng_bank( 49, 56 ),
    vb:space { width = 6 },
    kng_bank( 57, 64 ),
    vb:space { width = 6 },
    kng_bank( 65, 72 )
  }
  ---
  local KNG_BANKS_4 = vb:row {
    id = "KNG_BANKS_4",
    visible = false,
    kng_bank( 73, 80 ),
    vb:space { width = 6 },
    kng_bank( 81, 88 ),
    vb:space { width = 6 },
    kng_bank( 89, 96 )
  }
  ---
  local KNG_BANKS_SEL = vb:column { spacing = -3,
    vb:space { height = 5 },
    vb:bitmap {
      height = 27,
      width = 56,
      mode = "body_color",
      bitmap = "/ico/bank_ico.png"
    },
    vb:text {
      height = 19,
      width = 56,
      align = "center",
      font = "big",
      text = "Banks"
    },
    vb:space { height = 7 },
    vb:button {
      id = "KNG_BANKS_SEL_1",
      height = 34,
      width = 56,
      color = KNG_CLR.MARKER,
      text = "01 - 24",
      notifier = function() kng_banks_sel( 1 ) end,
      midi_mapping = "Tools:KangarooX120:Banks:Show Banks 01-24"
    },
    vb:button {
      id = "KNG_BANKS_SEL_2",
      height = 34,
      width = 56,
      text = "25 - 48",
      notifier = function() kng_banks_sel( 2 ) end,
      midi_mapping = "Tools:KangarooX120:Banks:Show Banks 25-48"
    },
    vb:button {
      id = "KNG_BANKS_SEL_3",
      height = 34,
      width = 56,
      text = "49 - 72",
      notifier = function() kng_banks_sel( 3 ) end,
      midi_mapping = "Tools:KangarooX120:Banks:Show Banks 49-72"
    },
    vb:button {
      id = "KNG_BANKS_SEL_4",
      height = 34,
      width = 56,
      text = "73 - 96",
      notifier = function() kng_banks_sel( 4 ) end,
      midi_mapping = "Tools:KangarooX120:Banks:Show Banks 73-96"
    }
  }
  ---
  local KNG_BANKS = vb:row { margin = 1,
    id = "KNG_BANKS",
    visible = false,
    vb:row { margin = 5, style = "panel",
      vb:column {
        KNG_BANKS_1,
        KNG_BANKS_2,
        KNG_BANKS_3,
        KNG_BANKS_4
      },
      vb:space { width = 12 },
      KNG_BANKS_SEL
    }
  }
  return KNG_BANKS
end



-------------------------------------------------------------------------------------------------
--define piano
local function kng_piano( oct )
  class "Kng_Piano_W"
  function Kng_Piano_W:__init( nte )
    self.cnt = vb:button {
      id = "KNG_PNO_"..nte,
      height = 100,
      width = 27,
      color = KNG_CLR.WHITE,
      --bitmap = "/ico/piano_c-0_ico.png",
      pressed = function() kng_osc_bt_pno_pres( nte ) end,
      released = function() kng_osc_bt_pno_rel( nte ) kng_pad_note_sel( nte ) end,
      midi_mapping = ("Tools:KangarooX120:Piano Keys:Key %.3d  (%s)"):format( nte , kng_note_tostring( nte ) ),
      tooltip = ("%s  (%.2d)"):format( kng_note_tostring( nte ), nte )
    }
  end
  ---
  class "Kng_Piano_B"
  function Kng_Piano_B:__init( nte )
    self.cnt = vb:button {
      id = "KNG_PNO_"..nte,
      height = 60,
      width = 19,
      color = KNG_CLR.BLACK,
      bitmap = "/ico/piano_key_black_ico.png",
      pressed = function() kng_osc_bt_pno_pres( nte ) end,
      released = function() kng_osc_bt_pno_rel( nte ) kng_pad_note_sel( nte ) end,
      midi_mapping = ("Tools:KangarooX120:Piano Keys:Key %.3d  (%s)"):format( nte , kng_note_tostring( nte ) ),
      tooltip = ("%s  (%.2d)"):format( kng_note_tostring( nte ), nte )
    }
  end
  local white = vb:row { spacing = -3 }
  local black = vb:row { spacing = -3 }
  local t_white = { 1, 3, 5, 6, 8, 10, 12 }
  local t_black = { 2, 4, 7, 9, 11 }
  for i = 1, 7 do
    white:add_child (
      Kng_Piano_W( (12*oct) + t_white[i] -1 ).cnt
    )
    local nte = (12*oct) + (t_white[i] -1 )
    if ( t_white[i] ~= 1 ) then
      vws["KNG_PNO_"..nte].bitmap = "/ico/piano_"..i.."_ico.png"
    else
      vws["KNG_PNO_"..nte].bitmap = "/ico/piano_c-"..oct.."_ico.png"
    end
  end
  for i = 1, 5 do
    black:add_child (
      Kng_Piano_B( (12*oct) + t_black[i] -1 ).cnt
    )
    if ( i == 1 ) or ( i == 3 ) or ( i == 4 ) then
      black:add_child (
        vb:space { width = 15 }
      )
    end
    if ( i == 2 ) then
      black:add_child (
        vb:space { width = 29 }
      )    
    end
  end
  local piano = vb:row { spacing = -157,
    white,
    black
  }
  return piano
end



-------------------------------------------------------------------------------------------------
--all piano
local function kng_all_piano()
  local KNG_PIANO =  vb:horizontal_aligner { spacing = -2,
    id = "KNG_PIANO",
    vb:column { spacing = 2,
      vb:column { spacing = -3,
        vb:valuebox {
          id = "KNG_VB_NTE_SEL",
          height = 20,
          width = 54,
          min = 0,
          max = 120,
          value = 0,
          tostring = function( value ) if ( value < 1 ) then return "NTE" else return kng_note_tostring( value -1 ) end end,
          tonumber = function( value ) return kng_note_tonumber( value ) end,
          notifier = function( value ) kng_nte_ini( value ) end,
          midi_mapping = "Tools:KangarooX120:Transpose Notes Pad",
          tooltip = "Transpose notes selector for entire pads panel\nAlso use before the \"INS\" and \"TRK\" valueboxes to routing each pad.\n\n"..
                    "If necessary, try to save a Bank beforehand so as not to lose the\nconfiguration of the pads."
        },
        vb:valuebox {
          id = "KNG_VB_INS_SEL",
          width = 54,
          height = 20,
          min = 0,
          max = 255,
          value = 0,
          tostring = function( value ) if ( value < 1 ) then return "INS" else return ("%.2X"):format( value -1 ) end end,
          tonumber = function( value ) return kng_ins_tonumber( value ) end,
          notifier = function( value ) kng_ins_sel( value ) end,
          midi_mapping = "Tools:KangarooX120:Select Instrument",
          tooltip = "Instrument selector for virtual piano\nAlso use it before to routing each pad.\n\n"..
                    "MIDI Input Map Mode:\n  1- Absolute 7 bit: return 0 to 127\n  2- Relative...(any): return ±1"
        },
        vb:valuebox {
          id = "KNG_VB_TRK_SEL",
          width = 54,
          height = 20,
          min = 0,
          max = 255,
          value = 0,
          tostring = function( value ) if ( value < 1 ) then return "TRK" else return ("%.2d"):format( value ) end end,
          tonumber = function( value ) return kng_trk_tonumber( value ) end,
          notifier = function( value ) kng_trk_sel( value ) end,
          midi_mapping = "Tools:KangarooX120:Select Track",
          tooltip = "Track selector for virtual piano\nUse the \"TRK\" value to be able to split the virtual piano.\nAlso use it before to routing each pad.\n\n"..
                    "MIDI Input Map Mode:\n  1- Absolute 7 bit: return 0 to 127\n  2- Relative...(any): return ±1"
        }
      },
      vb:column { spacing = -46,
        vb:column { spacing = -33,
          vb:rotary {
            id = "KNG_PNO_ROT_VEL",
            height = 45,
            width = 45,
            min = 0,
            max = 127,
            value = 95,
            notifier = function( value ) vws["KNG_PNO_ROT_VEL_TXT"].text = ("%.2X"):format( value ) end,
            midi_mapping = "Tools:KangarooX120:Piano Velocity Knob",
            tooltip = "Velocity knob for virtual piano\nLock it to control all the pads panel also.\n(Range = 00 to 7F)"
          },
          vb:row {
            vb:space { width = 12 },
            vb:text {
              id = "KNG_PNO_ROT_VEL_TXT",
              font = "bold",
              text = "5F"
            }
          }
        },
        vb:row {
          vb:space { width = 40 },
          vb:column {
            vb:button {
              id = "KNG_BT_MIDI_VEL_PAD_CTRL",
              height = 14,
              width = 14,
              bitmap = "/ico/mini_pad_ico.png",
              notifier = function() kng_midi_pad_ctrl() end,
              midi_mapping = "Tools:KangarooX120:Piano Velocity Knob for Pads Panel Control",
              tooltip = "Velocity knob for pads panel control\nEnable it so that this velocity knob controls the entire pads panel."
            },
            vb:space { height = 17 },
            vb:button {
              id = "KNG_BT_MIDI_IN_PNO_MODE",
              height = 14,
              width = 14,
              bitmap = "/ico/mini_plug_ico.png",
              color = KNG_CLR.MARKER,
              notifier = function() kng_midi_in_pno_mode() end,
              midi_mapping = "Tools:KangarooX120:Piano Velocity MIDI In Mode",
              tooltip = "Velocity MIDI In mode for virtual piano\nDisable it to control the velocity of the piano with the mouse."
            },            
          }
        }
      }
    },
    vb:space { width = 5 },
    vb:column { spacing = -3,
      vb:button {
        height = 20,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_jump-0_ico.png",
        notifier = function() kng_piano_jump_0() end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Jump to Octave 0",
        tooltip = "Start in octave 0"
      },
      vb:button {
        height = 56,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_jump-l_ico.png",
        pressed = function() kng_piano_jump_l_repeat() end,
        released = function() kng_piano_jump_l_repeat( true ) end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Jump Octave to Left",
        tooltip = "Preview octave\n(press and hold for repeat the action)"
      },
      vb:button {
        height = 30,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_note-off_ico.png",
        pressed = function() kng_note_off_empty( 120 ) end,
        released = function() kng_jump_lines() end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Key 120  (Note OFF)",
        tooltip = "Insert \"Note OFF\"\n[A]"
      }
    },
    vb:space { width = 5 },
    vb:horizontal_aligner { spacing = -341,
      id = "KNG_PIANO_WIDTH",
      width = 505,
      vb:row{},
      vb:row { spacing = -2,
        kng_piano(0),
        kng_piano(1),
        kng_piano(2),
        kng_piano(3),
        kng_piano(4),
        kng_piano(5),
        kng_piano(6),
        kng_piano(7),
        kng_piano(8),
        kng_piano(9)
      }
    },
    vb:space { width = 5 },
    vb:column { spacing = -3,
      vb:button {
        height = 20,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_jump-9_ico.png",
        notifier = function() kng_piano_jump_9() end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Jump to Octave 9",
        tooltip = "End in octave 9"
      },
      vb:button {
        height = 56,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_jump-r_ico.png",
        pressed = function() kng_piano_jump_r_repeat() end,
        released = function() kng_piano_jump_r_repeat( true ) end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Jump Octave to Right",
        tooltip = "Next octave\n(press and hold for repeat the action)"
      },
      vb:button {
        height = 30,
        width = 18,
        color = KNG_CLR.WHITE,
        bitmap = "/ico/piano_note-empty_ico.png",
        pressed = function() kng_note_off_empty( 121 ) end,
        released = function() kng_pad_note_sel( 121 ) kng_jump_lines() end,
        midi_mapping = "Tools:KangarooX120:Piano Keys:Key 121  (Note Empty)",
        tooltip = "Insert \"Note Empty\"\nAlso use it to empty the note of the selected pad.\n[DEL]"
      }
    }
  }
  
  local KNG_ALL_PIANO = vb:column { spacing = -102,
    id = "KNG_ALL_PIANO",
    KNG_PIANO,
    vb:row {
      vb:space { width = 290 },
      vb:row { margin = 1, style = "plain",
        vb:button {
          id = "KNG_PNO_BT_SUS_MODE",
          height = 15,
          width = 31,
          bitmap = "ico/pno_hld_ico.png",
          notifier = function() kng_pno_bt_sus_mode() end,
          midi_mapping = "Tools:KangarooX120:Mode Hold Piano",
          tooltip = "Hold the pressed notes of the virtual piano\n[<]"
        }
      },
      vb:row {
        id = "KNG_PNO_RW_SUS_CHAIN_MODE",
        visible = false,
        vb:space { width = 2 },
        vb:row { margin = 1, style = "plain",
          vb:button {
            id = "KNG_PNO_BT_SUS_CHAIN_MODE",
            height = 15,
            width = 31,
            bitmap = "/ico/pno_sus_chain_ico.png",
            pressed = function() kng_pno_bt_sus_chain_mode() end,
            midi_mapping = "Tools:KangarooX120:Mode Hold Chain Piano",
            tooltip = "Hold in chain the pressed notes of the virtual piano\n[CTRL + <]"
          }
        }
      },
      vb:row {
        vb:space { width = 2 },
        vb:row { margin = 1, style = "plain",
          vb:button {
            height = 15,
            width = 31,
            bitmap = "/ico/pno_panic_ico.png",
            color = KNG_CLR.RED_2,
            pressed = function() kng_pno_bt_panic() end,
            midi_mapping = "Tools:KangarooX120:Panic Piano",
            tooltip = "Panic virtual piano\n[1]"
          }
        }
      }
    }
  }
  
  return KNG_ALL_PIANO
end



-------------------------------------------------------------------------------------------------
--advanced operations
local function kng_operations()
  local KNG_OPERATIONS = vb:row { spacing = 3,
    id = "KNG_OPERATIONS",
    visible = false,
    vb:column { style = "panel", margin = 4,
      vb:row {
        vb:button {
          id = "KNG_BT_AUTO_SEQUENCE",
          height = 19,
          width = 39,
          text = "Auto",
          notifier = function() kng_auto_sequence_obs() end,
          tooltip = "Auto grown sequence\nAlways include automatically a new pattern at the end of the sequence"
        },
        vb:text {
          height = 19,
          width = 82,
          align = "center",
          font = "bold",
          text = "Sequence"
        }
      },
      vb:row { spacing = -3,
        vb:button {
          height = 21,
          width = 19,
          text = "4",
          notifier = function() vws.KNG_VB_SELECT_SEQUENCE.value = 0 vws.KNG_VB_SELECT_SEQUENCE.value = 4 end,
          tooltip = "Select sequence x4 to clone"
        },
        vb:valuebox {
          id = "KNG_VB_SELECT_SEQUENCE",
          height = 21,
          width = 50,
          min = 0,
          max = 32,
          value = 0,
          tostring = function( value ) if ( value == 0 ) then return "Sq" else return ("%.2d"):format( value ) end end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) kng_select_sequence( value ) end,
          tooltip = "Sequence selector\n(Range: 01 to 32)"
        },
        vb:space { width = 5 },
        vb:button {
          id = "KNG_BT_COPY_SEQUENCE",
          active = false,
          height = 21,
          width = 27,
          bitmap = "/ico/mini_arrow_down_clone_ico.png",
          notifier = function() kng_copy_sequence() end,
          tooltip = "Clone selected sequence below. Always include new sequence & the name of section!"
        },
        vb:space { width = 8 },
        vb:button {
          id = "KNG_BT_CLEAR_SEQUENCE",
          active = false,
          height = 21,
          width = 27,
          bitmap = "/ico/clear_data_ico.png",
          color = KNG_CLR.RED_5,
          notifier = function() kng_clear_sequence() end,
          tooltip = "Clear selected sequence"
        }
      }
    },
    vb:column { style = "panel", margin = 4,
      vb:button {
        id = "KNG_BT_COPY_PTT_TRACK",
        height = 19,
        width = 80,
        text = "Pattern-Track",
        notifier = function() kng_bt_copy_ptt_track() end,
        tooltip = "Pattern-Track or Track panel"
      },
      vb:row { spacing = -3,
        vb:button {
          id = "KNG_BT_COPY_PTT_TRACK_1",
          height = 21,
          width = 27,
          bitmap = "/ico/mini_arrow_left_ico.png",
          notifier = function() kng_copy_ptt_track( -1 ) end,
          tooltip = "Copy the values of the selected pattern-track to left. Never include a new pattern-track & overwrite the values!"
        },
        vb:button {
          id = "KNG_BT_COPY_PTT_TRACK_2",
          visible = false,
          height = 21,
          width = 27,
          text = "Val",
          color = KNG_CLR.MARKER,
          notifier = function() kng_copy_track_values() end,
          tooltip = "Include the copy of values"
        },
        vb:button {
          id = "KNG_BT_COPY_PTT_TRACK_3",
          height = 21,
          width = 27,
          bitmap = "/ico/mini_arrow_right_ico.png",
          notifier = function() kng_copy_track_ptt_track( 1 ) end, --kng_copy_ptt_track( 1 ) end,
          tooltip = "Copy the values of the selected pattern-track to right. Never include a new pattern-track & overwrite the values!"
        },
        vb:space { width = 8 },
        vb:button {
          id = "KNG_BT_CLEAR_PTT_TRACK",
          height = 21,
          width = 27,
          bitmap = "/ico/clear_data_ico.png",
          color = KNG_CLR.RED_5,
          notifier = function() kng_clear_track_ptt_track() end,
          tooltip = "Clear selected pattern-track"
        }
      }
    },
    vb:column { style = "panel", margin = 4,
      vb:text {
        height = 19,
        width = 80,
        align = "center",
        font = "bold",
        text = "Note Column"
      },
      vb:row { spacing = -3,
        vb:button {
          id = "KNG_BT_COPY_NOTE_COLUMN_1",
          height = 21,
          width = 27,
          bitmap = "/ico/mini_arrow_left_ico.png",
          notifier = function() kng_copy_note_column( 1 ) end,
          tooltip = "Copy the selected note column to left (overwrite the values)"
        },
        vb:button {
          id = "KNG_BT_COPY_NOTE_COLUMN_2",
          height = 21,
          width = 27,
          bitmap = "/ico/mini_arrow_right_ico.png",
          notifier = function() kng_copy_note_column( 2 ) end,
          tooltip = "Copy the selected note column to right (overwrite the values)"
        },
        vb:space { width = 8 },
        vb:button {
          id = "KNG_BT_CLEAR_NOTE_COLUMN",
          height = 21,
          width = 27,
          bitmap = "/ico/clear_data_ico.png",
          color = KNG_CLR.RED_5,
          notifier = function() kng_clear_note_column() end,
          tooltip = "Clear selected note column"
        }
      }
    },
    vb:column { style = "panel", margin = 4,
      vb:row {
        vb:button {
          id = "KNG_BT_CHANGE_INS",
          height = 19,
          width = 69,
          text = "Instrument",
          notifier = function() kng_change_instrument_value() end,
          tooltip = "Change instrument value\nSelect a instrument inside the instrument box and select an area bellow to change it."
        },
        vb:text {
          height = 19,
          width = 111,
          align = "right",
          font = "bold",
          text = "Transpose Notes"
        },
        vb:text {
          height = 19,
          width = 123,
          align = "center",
          font = "bold",
          text = "Moddify Values"
        }, 
        vb:row { spacing = -3,     
          vb:button {
            height = 17,
            width = 27,
            bitmap = "/ico/undo_ico.png",
            notifier = function() kng_kh_undo() end,
            tooltip = "Undo\n[CTRL+Z]"
          },
          vb:button {
            height = 17,
            width = 27,
            bitmap = "/ico/redo_ico.png",
            notifier = function() kng_kh_redo() end,
            tooltip = "Redo\n[CTRL+Y]"
          }
        }
      },
      vb:row { spacing = -3,
        vb:popup {
          id = "KNG_PP_SEL_AREA",
          height = 21,
          width = 99,
          items = { " Line", " Note Column", " Pattern-Track", " Selection" },
          value = 2,
          tooltip = "Area selector\nSelect an area to transpose the notes or moddify the values or change the instrument value."
        },
        vb:space { width = 8 },
        vb:valuebox {
          id = "KNG_VB_TRANSPOSE_NOTES",
          height = 21,
          width = 53,
          min = -24,
          max = 24,
          value = 0,
          tostring = function( value ) if ( value == 0 ) then return "TrN" elseif ( value > 0 ) then return ("+%.2d"):format( value ) else return ("%.2d"):format( value ) end end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) if ( value ~= 0 ) then vws.KNG_BT_TRANSPOSE_NOTES.active = true else vws.KNG_BT_TRANSPOSE_NOTES.active = false end end,
          tooltip = "Select the increment/decrement value to transpose\n(Range -24 to +24; ±2 octaves)"
          
        },
        vb:space { width = 5 },
        vb:button {
          id = "KNG_BT_TRANSPOSE_NOTES",
          active = false,
          height = 21,
          width = 27,
          bitmap = "/ico/apply_ico.png",
          notifier = function() kng_transpose_notes() end,
          tooltip = "Transpose the notes"
        },
        vb:space { width = 8 },
        vb:popup {
          id = "KNG_PP_MOD_VALUES",
          height = 21,
          width = 73,
          items = { " Volume", " Panning", " Delay" },
          value = 1,
          notifier = function( value ) if ( value < 3 ) and ( vws.KNG_VB_MOD_VALUES.value >= 128 ) then vws.KNG_BT_MOD_VALUES.active = false else vws.KNG_BT_MOD_VALUES.active = true end end,
          tooltip = "Select the value type sub-column to moddify values according to the selected area"
        },
        vb:valuebox {
          id = "KNG_VB_MOD_VALUES",
          height = 21,
          width = 47,
          min = 0,
          max = 255,
          value = 127,
          tostring = function( value ) return ("%.2X"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) if ( vws.KNG_PP_MOD_VALUES.value < 3 ) and ( value >= 128 ) then vws.KNG_BT_MOD_VALUES.active = false else vws.KNG_BT_MOD_VALUES.active = true end end,
          tooltip = "Select the value to moddify (00 to 7F | 00 or FF)\nThe range 00 to FF is only valid for Delay."
        },
        vb:space { width = 5 },
        vb:button {
          id = "KNG_BT_MOD_VALUES",
          height = 21,
          width = 27,
          bitmap = "/ico/apply_ico.png",
          notifier = function() kng_mod_values() end,
          tooltip = "Moddify the values (only for notes)"
        },
        vb:space { width = 8 },
        vb:button {
          id = "KNG_BT_CLEAR_VALUES",
          height = 21,
          width = 27,
          bitmap = "/ico/clear_data_ico.png",
          color = KNG_CLR.RED_5,
          notifier = function() kng_clear_values() end,
          tooltip = "Clear selected value type sub-column according to the selected area"
        }
      }
    },
    vb:row { style = "panel", margin = 4, spacing = 2,
      vb:column {
        vb:row { spacing = -3,
          vb:button {
            height = 17,
            width = 15,
            bitmap = "/ico/mini_first_ico.png",
            pressed = function() kng_first_seq_aut() end,
            tooltip = "First pattern sequence"
          },
          vb:button {
            height = 17,
            width = 22,
            bitmap = "/ico/mini_left_ico.png",
            pressed = function() kng_previous_seq_aut_repeat() end,
            released = function() kng_previous_seq_aut_repeat( true ) end,
            --notifier = function() kng_previous_seq_aut() end,
            tooltip = "Previous pattern sequence"
          },
          vb:button {
            height = 17,
            width = 22,
            bitmap = "/ico/mini_right_ico.png",
            pressed = function() kng_next_seq_aut_repeat() end,
            released = function() kng_next_seq_aut_repeat( true ) end,
            --notifier = function() kng_next_seq_aut_repeat() end,
            tooltip = "Next pattern sequence"
          },
          vb:text {
            height = 19,
            width = 123,
            align = "center",
            font = "bold",
            text = "Automation Slopes",
          },
          vb:button {
            id = "KNG_BT_AUTOMATION_INVERSE_POINTS",
            active = false,
            height = 17,
            width = 21,
            bitmap = "/ico/mini_i_ico.png",
            notifier = function() kng_automation_inverse_points() end,
            tooltip = "Inverse the selected existent points"
          },
          vb:button {
            id = "KNG_BT_AUTOMATION_SLOPES_DOWN",
            active = false,
            height = 17,
            width = 21,
            bitmap = "/ico/mini_minus_ico.png",
            pressed = function() kng_down_automation_repeat() end,
            released = function() kng_down_automation_repeat( true ) end,
            --notifier = function() kng_down_automation() end,
            tooltip = "Decrease the selected existent points"
          },
          vb:button {
            id = "KNG_BT_AUTOMATION_SLOPES_UP",
            active = false,
            height = 17,
            width = 21,
            bitmap = "/ico/mini_plus_ico.png",
            pressed = function() kng_up_automation_repeat() end,
            released = function() kng_up_automation_repeat( true ) end,
            --notifier = function() kng_up_automation() end,
            tooltip = "Increase the selected existent points"
          },
          vb:button {
            id = "KNG_BT_AUTOMATION_SLOPES_L_R",
            active = false,
            height = 17,
            width = 21,
            bitmap = "/ico/mini_arrow_right_p_ico.png",
            notifier = function() kng_l_r_automation() end,
            tooltip = "Sense of the modification"
          }
        },
        vb:row { spacing = -3,
          vb:valuebox {
            id = "KNG_VB_AUTOMATION_SLOPES",
            height = 21,
            width = 51,
            min = 0,
            max = 65,
            value = 0,
            tostring = function( value ) if ( value == 0 ) then return "Sq" elseif ( value == 65 ) then return "All" else return ("%.2d"):format( value ) end end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) kng_select_automation( value ) end,
            tooltip = "Sequence selector\n(Range: 01 to 64)"
          },
          vb:space { width = 5 },
          vb:button {
            id = "KNG_BT_INVERSE_AUTOMATION_SLOPES",
            height = 21,
            width = 18,
            bitmap = "/ico/mini_i_ico.png",
            notifier = function() kng_inverse_automation() end,
            tooltip = "Inverse the first and last point values to selected sequence"
          },
          vb:valuebox {
            id = "KNG_VB_AUTOMATION_SLOPES_MAX",
            height = 21,
            width = 64,
            min = 0,
            max = 1000,
            value = 1000,
            tostring = function( value ) return ("%.3f"):format( value/1000 ) end,
            tonumber = function( value ) return tonumber( value*1000 ) end,
            notifier = function() kng_insert_automation() end,
            tooltip = "First point value ( 0.000 to 1.000 )"
            
          },
          vb:valuebox {
            id = "KNG_VB_AUTOMATION_SLOPES_MIN",
            height = 21,
            width = 64,
            min = 0,
            max = 1000,
            value = 0,
            tostring = function( value ) return ("%.3f"):format( value/1000 ) end,
            tonumber = function( value ) return tonumber( value*1000 ) end,
            notifier = function() kng_insert_automation() end,
            tooltip = "Last point value ( 0.000 to 1.000 )"
          },
          vb:space { width = 5 },
          vb:button {
            id = "KNG_BT_AUTOMATION_SLOPES_INSERT",
            active = false,
            height = 21,
            width = 27,
            bitmap = "/ico/apply_ico.png",
            notifier = function() kng_insert_automation() end,
            tooltip = "Insert automation in the selected sequence"
          },
          vb:space { width = 8 },
          vb:button {
            id = "KNG_BT_AUTOMATION_SLOPES_CLEAR",
            active = false,
            height = 21,
            width = 27,
            bitmap = "/ico/clear_data_ico.png",
            color = KNG_CLR.RED_5,
            notifier = function() kng_clear_automation() end,
            tooltip = "Clear automation in the selected sequence",
          }
        }
      },
      vb:column { spacing = -4,
        vb:row {},
        vb:column { spacing = -3,
          vb:minislider {
            id = "KNG_VB_AUTOMATION_SLOPES_SQU",
            active = false,
            height = 37,
            width = 15,
            min = 0.1,
            max = 10.0,
            value = 1,
            notifier = function() kng_insert_automation() end,
            tooltip = "Exponent of the envelope\n(Range 0.1 to 10.0 ... 1.0 = straight slope)"
          },
          vb:row {
            vb:space { width = 2 },
            vb:button {
              id = "KNG_VB_AUTOMATION_SLOPES_SQU_1",
              active = false,
              height = 9,
              width = 11,
              notifier = function() vws.KNG_VB_AUTOMATION_SLOPES_SQU.value = 1 end,
              tooltip = "Reset value = 1.0 (straight slope)"
            }
          }
        }
      }
    }
  }
  return KNG_OPERATIONS
end



-------------------------------------------------------------------------------------------------
--preferences
local function kng_preferences()
  local KNG_PREFERENCES = vb:row {
    id = "KNG_PREFERENCES",
    visible = false,
    vb:column { margin = 5,
      width = 605,
      vb:row {
        vb:space { width = 207 },
        vb:bitmap {
          height = 19,
          width = 27,
          mode = "body_color",
          bitmap = "/ico/osc_ico.png"
        },
        vb:text {
          font = "bold",
          text = "Open Sound Control (OSC)"
        }
      },
      vb:text {
        font = "italic",
        text = "Please, go to \"Renoise: Preferences / OSC\" and enable the \"Enable Server\" checkbox. Configure the next controls equal\n"..
               "to this panel... OSC server is necessary to play (sound) and record (write) the notes inside the pattern editor."
      },
      vb:space { height = 3 },
      vb:row {
        vb:text {
          width = 55,
          align = "left",
          text = "IP Server:"
        },
        vb:valuebox {
          active = false,
          height = 19,
          width = 53,
          min = 1,
          max = 139,
          value = 127,
          --tostring = function( value ) return ("%d"):format( value ) end,
          --tonumber = function( value ) return tonumber( value ) end,
          --notifier = function( value ) KNG_OSC_IP_1 = value kng_osc_client_launch() end,
          tooltip = "Locked value, always 127. Valid localhost: 127.0.0.1 to 127.255.255.255"
        },
        vb:text {
          width = 9,
          align = "center",
          font = "bold",
          text = "."
        },
        vb:valuebox {
          height = 19,
          width = 53,
          min = 0,
          max = 255,
          value = 0,
          tostring = function( value ) return ("%d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) KNG_OSC_IP_2 = value kng_osc_client_launch() end,
          tooltip = "(0 to 255)"
        },
        vb:text {
          width = 9,
          align = "center",
          font = "bold",
          text = "."
        },
        vb:valuebox {
          height = 19,
          width = 53,
          min = 0,
          max = 255,
          value = 0,
          tostring = function( value ) return ("%d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) KNG_OSC_IP_3 = value kng_osc_client_launch() end,
          tooltip = "(0 to 255)"
        },
        vb:text {
          width = 9,
          align = "center",
          font = "bold",
          text = "."
        },
        vb:valuebox {
          height = 19,
          width = 53,
          min = 1,
          max = 255,
          value = 1,
          tostring = function( value ) return ("%d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) KNG_OSC_IP_4 = value kng_osc_client_launch() end,
          tooltip = "(1 to 255)"
        },
        vb:space { width = 21 },
        vb:text {
          width = 49,
          align = "left",
          text = "Protocol:"
        },
        vb:row { spacing = -3,
          vb:button {
            active = false,
            id = "KNG_PROT_2",
            height = 19,
            width = 43,
            text = "Udp",
            color = KNG_CLR.MARKER,
            --notifier = function() KNG_OSC_PROT = renoise.Socket.PROTOCOL_UDP vws.KNG_PROT_2.color = KNG_CLR.MARKER vws.KNG_PROT_1.color = KNG_CLR.DEFAULT kng_osc_client_launch() end,
            tooltip = "Locked protocol, always Udp."
          },
          vb:button {
            active = false,
            id = "KNG_PROT_1",
            height = 19,
            width = 43,
            text = "Tcp",
            --notifier = function() KNG_OSC_PROT = renoise.Socket.PROTOCOL_TCP vws.KNG_PROT_1.color = KNG_CLR.MARKER vws.KNG_PROT_2.color = KNG_CLR.DEFAULT kng_osc_client_launch() end,
            tooltip = "Locked protocol, always Udp."
          }
        },
        vb:space { width = 21 },
        vb:text {
          width = 31,
          align = "left",
          text = "Port:"
        },
        vb:valuebox {
          height = 19,
          width = 59,
          min = 1,
          max = 9999,
          value = 8000,
          tostring = function( value ) return ("%d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) KNG_OSC_P0RT = value kng_osc_client_launch() end,
          tooltip = "(1 to 9999)"
        }
      },
      vb:space { height = 11 },
      vb:row {
        vb:space { width = 197 },
        vb:bitmap {
          height = 19,
          width = 21,
          mode = "body_color",
          bitmap = "/ico/midi_ico.png"
        },
        vb:text {
          font = "bold",
          text = "MIDI In Velocity Control"
        },
        vb:space { width = 7 },
        vb:button {
          height = 19,
          width = 33,
          bitmap = "ico/folder_m_ico.png",
          notifier = function() rna:open_path( "xrnm" ) end,
          tooltip = "Open the default folder to XRNM files (MIDI MAP)\nIf you save your XRNM files inside this folder, "..
                    "be sure to make a backup before uninstalling the"..kng_main_title.." tool!"
        }
      },
      vb:text {
        font = "italic",
        text = "Please, go to \"Renoise: Preferences / MIDI / Record & Play Filters\" and check the \"Velocities\" checkbox and rest!"
      },
      vb:row {
        vb:text {
          height = 37,
          width = 67,
          align = "right",
          text = "Velocity of\nthe in device:"
        },
        vb:space { width = 11 },
        vb:column { spacing = -3,
          vb:row {
            vb:text {
              width = 33,
              align = "right",
              text = "Pads"
            },
            vb:valuebox {
              id = "KNG_VB_MIDI_DEVICE_1",
              height = 19,
              width = 193,
              min = 1,
              max = 8,
              value = 1,
              tostring = function( value ) return KNG_INPUT_DEVICE[value] end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) kng_midi_device_close_1( value ) end,
              tooltip = "MIDI In device selector for pads\nSelect a device name to control the velocity values (0-127 ~ 00-7F).\n\n"..
                        "For control the velocity,"..kng_main_title.." use the data \"message[1]\" to \"Note On\" type with range of 0x90 to 0x9F. "..
                        "The data values depends of the MIDI channel employed:\n"..
                        "(0x90 to channel 01 ... until 0x9F to channel 16)\n"..
                        "A MIDI device can have 16 or more MIDI channels. It must be velocity sensitive!"
            }
          },
          vb:row {
            vb:text {
              width = 33,
              align = "right",
              text = "Piano"
            },
            vb:valuebox {
              id = "KNG_VB_MIDI_DEVICE_2",
              height = 19,
              width = 193,
              min = 1,
              max = 8,
              value = 2,
              tostring = function( value ) return KNG_INPUT_DEVICE[value] end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) kng_midi_device_close_2( value ) end,
              tooltip = "MIDI In device selector for piano\nSelect a device name to control the velocity values (0-127 ~ 00-7F).\n\n"..
                        "For control the velocity,"..kng_main_title.." use the data \"message[1]\" to \"Note On\" type with range of 0x90 to 0x9F. "..
                        "The data values depends of the MIDI channel employed:\n"..
                        "(0x90 to channel 01 ... until 0x9F to channel 16)\n"..
                        "A MIDI device can have 16 or more MIDI channels. It must be velocity sensitive!"
            }
          }
        },
        vb:space { width = 21 },
        vb:text {
          height = 19,
          width = 80,
          align = "right",
          text = "Restart velocity\nof all the Pads:"
        },
        vb:space { width = 3 },
        vb:column {
          vb:space { height = 2 },
          vb:rotary {
            id = "KNG_ROT_VEL_RESTART_ALL",
            height = 32,
            width = 32,
            min = 0,
            max = 127,
            value = 96,
            notifier = function( val ) for pad = 0, 119 do vws["KNG_PAD_ROT_VEL_"..pad].value = val end end,
            midi_mapping = "Tools:KangarooX120:Pads:Velocity Knob Restart All",
            tooltip = "Restart velocity for all knobs of pads panel\nDefault velocity = 5F"
          }
        },
        vb:space { width = 21 },
        vb:text {
          height = 37,
          width = 81,
          align = "left",
          text = "Enable the next\ncheckboxes to work:"
        },
        vb:column { spacing = -3,
          vb:bitmap {
            height = 19,
            width = 27,
            mode = "transparent",
            bitmap = "/ico/midi_in_vol_ico.png",
            tooltip = "To pads panel"
          },
          vb:column {
            vb:bitmap {
              height = 19,
              width = 27,
              mode = "transparent",
              bitmap = "/ico/mini_plug_ico.png",
              tooltip = "To virtual piano"
            }
          }
        }
      },
      vb:space { height = 11 },
      vb:row {
        vb:space { width = 166 },
        vb:bitmap {
          height = 19,
          width = 21,
          mode = "body_color",
          bitmap = "/ico/pads_panel_ico.png"
        },
        vb:text {
          font = "bold",
          text = "Pads/Banks: Distribution & Control"
        },
        vb:space { width = 7 },
        vb:button {
          height = 19,
          width = 33,
          bitmap = "ico/folder_b_ico.png",
          notifier = function() rna:open_path( "banks" ) end,
          tooltip = "Open the default folder to XML files (Banks for pads panel)\nIf you save your Banks inside this folder, "..
                    "be sure to make a backup before uninstalling the"..kng_main_title.." tool!"
        }
      },
      vb:text {
        font = "italic",
        text = "Distribute the notes according to an octave grid using the \"NTE\" valuebox. \"8x4\" use a row and a half to distribute each\n"..
               "octave. \"3x4\" uses a grid of 3 rows by 4 columns to distribute each octave. \"WHITE\" only show white keys per octave."
      },
      vb:row {
        vb:text {
          width = 83,
          align = "left",
          text = "Grid to octaves:"
        },
        vb:row { spacing = -3,
          vb:button {
            id = "KNG_GRID_OCTAVES_1",
            height = 19,
            width = 43,
            text = "8 + 4",
            color = KNG_CLR.MARKER,
            notifier = function() kng_grid_octaves( 1 ) kng_nte_ini( vws.KNG_VB_NTE_SEL.value ) end,
            midi_mapping = "Tools:KangarooX120:Pads:Grill to Octaves 8+4 / 3x4 / WHITE",
            tooltip = "8+4 octave grid distribution"
          },
          vb:button {
            id = "KNG_GRID_OCTAVES_2",
            height = 19,
            width = 43,
            text = "3 x 4",
            notifier = function() kng_grid_octaves( 2 ) kng_nte_ini( vws.KNG_VB_NTE_SEL.value ) end,
            --midi_mapping = "Tools:KangarooX120:Pads:Grill to Octaves 8+4 or 3x4",
            tooltip = "3x4 octave grid distribution"
          },
          vb:button {
            id = "KNG_GRID_OCTAVES_3",
            height = 19,
            width = 43,
            text = "WHITE",
            notifier = function() kng_grid_octaves( 3 ) kng_nte_ini( vws.KNG_VB_NTE_SEL.value ) end,
            --midi_mapping = "Tools:KangarooX120:Pads:Grill to Octaves 8+4 or 3x4",
            tooltip = "WHITE octave grid distribution\nOnly change the octaves transposing with the \"C-\" notes."
          }
        },
        vb:space { width = 21 },
        vb:text {
          width = 110,
          align = "left",
          text = "Lock \"NTE\" valuebox:"
        }, 
        vb:row { spacing = -3,
          vb:button {
            id = "KNG_LOCK_NTE_1",
            height = 19,
            width = 32,
            color = KNG_CLR.MARKER,
            bitmap = "/ico/mini_padlock_open_ico.png",
            notifier = function() kng_lock_nte( 1 ) end,
            tooltip = ""
          },
          vb:button {
            id = "KNG_LOCK_NTE_2",
            height = 19,
            width = 32,
            bitmap = "/ico/mini_padlock_close_ico.png",
            notifier = function() kng_lock_nte( 2 ) end,
            tooltip = "Avoid accidentally changing/routing the notes of the pads!"
          }
        },
        vb:space { width = 21 },
        vb:text {
          width = 114,
          align = "left",
          text = "Lock all \"Save\" Banks:"
        }, 
        vb:row { spacing = -3,
          vb:button {
            id = "KNG_LOCK_SAVE_BANKS_1",
            height = 19,
            width = 32,
            bitmap = "/ico/mini_padlock_open_ico.png",
            notifier = function() kng_lock_save_all_banks( 1 ) end,
            tooltip = ""
          },
          vb:button {
            id = "KNG_LOCK_SAVE_BANKS_2",
            height = 19,
            width = 32,
            color = KNG_CLR.MARKER,
            bitmap = "/ico/mini_padlock_close_ico.png",
            notifier = function() kng_lock_save_all_banks( 2 ) end,
            tooltip = "Avoid accidentally overwriting all the banks!"
          }
        }
      }
    },
    vb:column { spacing = -45,
      id = "KNG_KANGAROO",
      visible = false,
      vb:bitmap {
        height = 250,
        width = 330,
        mode = "body_color",
        bitmap = "/ico/kangaroo_ico.png",
        tooltip = KNG_ABOUT_TTP
      },
      vb:row {
        vb:text {
          width = 302,
          align = "right",
          text = "ulneiz 2018. KangarooX120 v"..kng_version
        }
      }  
    }
  }
  return KNG_PREFERENCES
end

  

-------------------------------------------------------------------------------------------------
--main content gui
local function kng_main_content()
  KNG_MAIN_CONTENT = vb:column { margin = 3, style = "panel",
    vb:column { margin = 4, style = "plain", spacing = 1,
      kng_all_pads(),
      vb:column { spacing = 3,
        kng_controls(),
        kng_all_banks(),
        kng_all_piano(),
        kng_operations()
      }
    },
    kng_preferences()
  }
  return KNG_MAIN_CONTENT
end



-------------------------------------------------------------------------------------------------
--show main_dialog
function kng_main_dialog()
  --first invoke status
  if (KNG_INVOKE_STATUS == true ) then
    rna:show_status( ("%s: Preloading the window tool..."):format(kng_main_title) )
    KNG_INVOKE_STATUS = false
  end

  --main content gui
  if ( KNG_MAIN_CONTENT == nil ) then
    kng_main_content()
  end


  --require
  require ( "lua/colors" )
  require ( "lua/functions" )
  require ( "lua/banks" )
  require ( "lua/midi_input" )
  require ( "lua/keyhandler" )
  
  --check imput devices
  kng_check_input_devices( 1, 2 )


  --last invoke status
  rna:show_status( ("%s: pads & virtual piano sucesfully loaded."):format(kng_main_title) )

  --avoid showing the same window several times!
  if ( KNG_MAIN_DIALOG and KNG_MAIN_DIALOG.visible ) then KNG_MAIN_DIALOG:show() return end

  --custom dialog
  KNG_MAIN_DIALOG = rna:show_custom_dialog( kng_main_title, KNG_MAIN_CONTENT, kng_keyhandler )
end



-------------------------------------------------------------------------------------------------
--register menu entry
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:KangarooX120...",
  invoke = function() kng_main_dialog() end
}
---
rnt:add_menu_entry {
  name = "Pattern Editor:KangarooX120...",
  invoke = function() kng_main_dialog() end
}



-------------------------------------------------------------------------------------------------
--register keybinding
rnt:add_keybinding {
  name = "Global:Tools:KangarooX120",
  invoke = function() kng_main_dialog() end
}



--**************************************
--collectgarbage (bottom)
  --print( "collectgarbage:", collectgarbage("count"), "KBytes (KangarooX120)" )
  --collectgarbage( "restart" )
--**************************************
