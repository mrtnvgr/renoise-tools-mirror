dialog_keyboard = nil
local title_keyboard = " PhraseTouch:  Keyboard Commands"

local PHT_HW = { 22, 151, 343, 155, 398 }

local PHT_COM_G1 = {
  "Numpad /",
  "Numpad *",
  "Ctrl + Numlock",
  "Ctrl + Numpad /",
  "Ctrl + Numpad *",
  "Space  |  Return",
  "R.Alt  |  Ctrl + Return",
  "Ctrl + Space",
  "Alt + Space",
  "Left  |  Shift + Tab",
  "Right  |  Tab",
  "Up  |  Ctrl + Shift + Up",
  "Down  |  Ctrl + Shift + Down",
  "Ctrl + Up",
  "Ctrl + Down",
  "Numpad -",
  "Numpad +",
  "Ctrl + Numpad -",
  "Ctrl + Numpad +",
  "Ctrl + Alt + Numpad -",
  "Ctrl + Alt + Numpad +"
}
---
local PHT_DES_G1 = {
  "Down octave  (until 0).",
  "Up octave  (until 8; 9 octaves).",
  "Enable/disable USB Keyboard for FavTouch; octaves (Oct) 0 & 1.",
  "Previous panel of notes  (until Panel 1).",
  "Next panel of notes  (until Panel 16 & FAV; 16 panels & FavTouch).",
  "Restart / stop pattern.  |  Restart / stop Step Sequencer.",
  "Continue play / stop pattern.  |  Restart Step Sequencer.",
  "Restart / stop pattern & Step Sequencer simultaneously!",
  "Continue / stop pattern & Step Sequencer simultaneously!",
  "Previous note/effect column.  |  track. Also, show the pattern editor.",
  "Next note/effect column.  |  track. Also, show the pattern editor.",
  "Previous line  (until 0)  |  Jump up the line with step lenght.",
  "Next line  (until 511)  |  Jump down the line with step lenght.",
  "Previous sequence  (until 0).",
  "Next sequence  (until 1000).",
  "Previous instrument  (until 0).",
  "Next instrument  (until FE; 255 instruments).",
  "Previous phrase  (until 1). Also, show the phrase editor.",
  "Next phrase  (until 126). Also, show the phrase editor.",
  "Previous plugin preset  (until 0), if the plugin is bridged.",
  "Next plugin preset  (>999), if the plugin is bridged."
}
---
local PHT_COM_G2 = {
  "Capital  |  A  |  Del",
  "Ctrl + Z",
  "Ctrl + Y",
  "Alt + Left / Right / Up / Down",
  "Esc  |  Apps  |  R.Ctrl",
  "Back  |  º",
  "Ctrl + F1 to F12",
  "Alt + F1 to F12",
  "F1 to F4, F8",
  "F5 to F7",
  "F9 to F12",
  "Shift + Ctrl + 1 to 9 .. 0 .. ' .. ¡",
  "Ctrl + 1 to 9 .. 0 .. ' .. ¡",
  "Ctrl + K",
  "Ctrl + Alt + K",
  "Ctrl + W",
  "Ctrl + Alt + W",
  "Ctrl + Q",
  "Ctrl + Alt + Q",
  "Ctrl + F",
  "Ctrl + Alt + F",
  "Ctrl + Alt + P"
}
---
local PHT_DES_G2 = {
  "Note Empty.  |  Note Off.  |  Clean multiple data (Advanced Editor Panel: AEP).",
  "Undo.",
  "Redo.",
  "Move/swap selected row inside note column to the left / right / up / down (AEP).",
  "Enable / disable edit mode.  |  Import row (AEP).  |  Insert row (AEP).",
  "Main Panic for all panels.  |  Compact Mode View.",
  "Panic for 1 to 12 panels.",
  "Enable/disable the MultiTouch capacity for 1 to 12 panels of notes.",
  "Selector of panels: 1 to 4, 5 to 8, 9 to 12 & 13 to 16. F8 show panel 1 only.",
  "Show various panels according the selection: 1 panel, 2 panels or 4 panels.",
  "Show certain editors of Renoise: pattern/phrase/plugin editor or MIDI monitor.",
  "Up base note of selected phrase in keymap mode, 1 to 12 panels of notes.",
  "Down base note of selected phrase in keymap mode, 1 to 12 panels of notes.",  
  "Show Keyboard Commands window.",
  "Close Keyboard Commands window & returns the PhraseTouch tool window.",
  "Show Color Settings window.",
  "Close Color Settings window & returns the PhraseTouch tool window.",
  "Show Step Sequencer window.",
  "Close Step Sequencer window & returns the PhraseTouch tool window.",
  "Show FavTouch window tool.",
  "Close FavTouch window tool & returns the PhraseTouch tool window.",
  "Close PhraseTouch window tool.  * Recommended to assign it to invoke the tool."
}


------------------------------------------------------------------------------------------------
--titles
local PHT_TITLES_G1 = vb:row {
  vb:text {
    height = PHT_HW[ 1 ],
    width = PHT_HW[ 2 ],
    align = "left",
    font = "big",
    text = "Command",
  },
  vb:text {
    height = PHT_HW[ 1 ],
    width = PHT_HW[ 3 ],
    align = "left",
    font = "big",
    text = "Description",
  }
}
local PHT_TITLES_G2 = vb:row {
  vb:text {
    height = PHT_HW[ 1 ],
    width = PHT_HW[ 4 ],
    align = "left",
    font = "big",
    text = "Command",
  },
  vb:text {
    height = PHT_HW[ 1 ],
    width = PHT_HW[ 5 ],
    align = "left",
    font = "big",
    text = "Description",
  }
}
---
local PHT_BOTTOM_LOGO = vb:horizontal_aligner {
  height = 25,
  width = "100%",
  mode = "right",
  vb:text {
    height = 25,
    width = 379,
    font = "italic",
    text = "* ASSIGNABLE:  Edit / Preferences / Keys →  Global / Tools / PhraseTouch"
  },
  vb:bitmap {
    height = 25,
    width = 116,
    mode = "body_color",
    bitmap = "./ico/commands_ico.png",
  }
}
---
PHT_VB_KB_NOTES = vb:valuebox {
  height = 33,
  width = 37,
  min = 1,
  max = 17,
  value = 1,
  tostring = function( value ) return (" %s"):format( pht_vb_notes_tostring( value ) ) end,
  tonumber = function( value ) return pht_vb_notes_tonumber( value ) end,
  notifier = function( value ) PHT_VB_NOTES.value = value end,
  tooltip = "Panel selector\n[Range: 1 to 16 & FAV]"
}
---
local function pht_comm_desc_g1()
  local comm_desc = vb:column { spacing = -2  }
  comm_desc:add_child (
    vb:column { style = "panel", margin = 2, 
      vb:column { style = "plain", margin = 2, 
        vb:space { height = 8 },
        vb:row { height = 42,
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 2 ],
            text = "Z, S, X, D, C, V...\n...I, 9, O, 0, P..."
          },
          PHT_VB_KB_NOTES,
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 3 ] - PHT_VB_KB_NOTES.width,
            text = "Control the notes with P/R mode enabled (until 32 notes).\nSelect a specific panel & octave into Renoise valuebox (Oct)."
          }
        }
      }
    }
  )
  for i = 1, 21 do
    comm_desc:add_child (
      vb:row { style = "panel", margin = 2,
        vb:row { style = "plain", margin = 2,
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 2 ],
            text = PHT_COM_G1[ i ]
          },
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 3 ],
            text = PHT_DES_G1[ i ]
          }
        }
      }
    )
  end
  return comm_desc
end
---
local function pht_comm_desc_g2()
  local comm_desc = vb:column { spacing = -2  }
  for i = 1, 22 do
    comm_desc:add_child (
      vb:row { style = "panel", margin = 2,
        vb:row { style = "plain", margin = 2,
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 4 ],
            text = PHT_COM_G2[ i ]
          },
          vb:text {
            height = PHT_HW[ 1 ],
            width = PHT_HW[ 5 ],
            text = PHT_DES_G2[ i ]
          }
        }
      }
    )
  end
  return comm_desc
end
---
local content_keyboard = vb:row { margin = 5, spacing = 1,
  vb:column { style = "plain", margin = 7, spacing = 3,
    PHT_TITLES_G1,
    pht_comm_desc_g1(),
    --PHT_BOTTOM_LOGO
  },
  vb:column { style = "plain", margin = 7, spacing = 3,
    PHT_TITLES_G2,
    pht_comm_desc_g2(),
    PHT_BOTTOM_LOGO
  }
}



------------------------------------------------------------------------------------------------
--show dialog_keyboard
function show_tool_dialog_keyboard()
  --Avoid showing the same window several times!
  if ( dialog_keyboard and dialog_keyboard.visible ) then dialog_keyboard:show() return end
  dialog_keyboard = rna:show_custom_dialog( title_keyboard, content_keyboard, pht_keyhandler )
end
