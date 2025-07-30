----------------------
-- COLOR SETTINGS   --
----------------------



dialog_colors = nil
local title_colors = " PhraseTouch:  Color Settings"



------------------------------------------------------------------------------------------------
--open config.xml
function pht_clr_open_config_xml()
  local appdata = os.getenv("APPDATA") --windows
  local renoise_version = renoise.RENOISE_VERSION
  --print(renoise_version)
  local config_xml_dir = appdata.."/Renoise/V"..renoise_version.."/Config.xml"
  if ( config_xml_dir ~= nil ) then
    renoise.app():open_path( config_xml_dir )
    --rprint ( io.stat( config_xml_dir ) )
  end
  --oprint (renoise.Document.DocumentList )
end



------------------------------------------------------------------------------------------------
--panels selector
function disable_anchor_sliders()
  if ( pht_clr_nte_off_anchor == false ) then
    pht_clr_nte_off_anchor = true
    pht_clr_nte_off_anchor_rgb()
  else
    pht_clr_nte_off_anchor_rgb()
  end
end



function pht_clr_pnl_sel( val_1, val_2, val_3 )
  pht_kh_panel_nav()
  pht_sel_pnl_gr( val_1 )
  pht_sel_pnl_mn( val_2 )
  disable_anchor_sliders()
  vws.PHT_CLR_NTE_OFF_VBX_SEL.value = val_3
  show_tool_dialog()
  dialog_colors:show()
end
---
PHT_CLR_PNL_SEL = vb:column { spacing = 5,
  vb:button {
    height = 44,
    width = 61,
    bitmap = "./ico/theme_big_ico.png",
    notifier = function() pht_open_default_folder() end,
    tooltip = "Open default tool folder for load themes..."
  },
  vb:row { spacing = -3,
    vb:column { spacing = -3,
      vb:button {
        height = 19,
        width = 32,
        text = "1",
        notifier = function() pht_clr_pnl_sel( 1, 3, 1 ) end,
        tooltip = "Show the panels of notes 1 to 4"
      },
      vb:button {
        height = 19,
        width = 32,
        text = "5",
        notifier = function() pht_clr_pnl_sel( 2, 3, 5 ) end,
        tooltip = "Show the panels of notes 5 to 8"
      }
    },
    vb:column { spacing = -3,
      vb:button {
        height = 19,
        width = 32,
        text = "9",
        notifier = function() pht_clr_pnl_sel( 3, 3, 9 ) end,
        tooltip = "Show the panels of notes 9 to 12"
      },
      vb:button {
        height = 19,
        width = 32,
        text = "13",
        notifier = function() pht_clr_pnl_sel( 4, 3, 13 ) end,
        tooltip = "Show the panels of notes 13 to 16"
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--panel of colors, migrate
function pht_clr_migrate_out( val )
  local r, g, b = 0, 0, 0
  if ( val == 1 ) then
    r = vws.PHT_CLR_NTE_OFF_SLR_1.value
    g = vws.PHT_CLR_NTE_OFF_SLR_2.value
    b = vws.PHT_CLR_NTE_OFF_SLR_3.value
  elseif ( val == 2 ) then
    r = vws.PHT_CLR_NTE_ON_BACK_SLR_1.value
    g = vws.PHT_CLR_NTE_ON_BACK_SLR_2.value
    b = vws.PHT_CLR_NTE_ON_BACK_SLR_3.value
  elseif ( val == 3 ) then
    r = vws.PHT_CLR_NTE_ON_MARKED_SLR_1.value
    g = vws.PHT_CLR_NTE_ON_MARKED_SLR_2.value
    b = vws.PHT_CLR_NTE_ON_MARKED_SLR_3.value
  elseif ( val == 4 ) then
    r = vws.PHT_CLR_NTE_SEL_BACK_SLR_1.value
    g = vws.PHT_CLR_NTE_SEL_BACK_SLR_2.value
    b = vws.PHT_CLR_NTE_SEL_BACK_SLR_3.value
  elseif ( val == 5 ) then
    r = vws.PHT_CLR_NTE_SEL_MARKED_SLR_1.value
    g = vws.PHT_CLR_NTE_SEL_MARKED_SLR_2.value
    b = vws.PHT_CLR_NTE_SEL_MARKED_SLR_3.value
  else
    r = vws.PHT_CLR_WINDOW_MODES_SLR_1.value
    g = vws.PHT_CLR_WINDOW_MODES_SLR_2.value
    b = vws.PHT_CLR_WINDOW_MODES_SLR_3.value
  end
  vws.PHT_MAIN_CLR_MRG.color = { r, g, b }
end
---
function pht_clr_migrate_in( val )
  local r = vws.PHT_MAIN_CLR_MRG.color[1]
  local g = vws.PHT_MAIN_CLR_MRG.color[2]
  local b = vws.PHT_MAIN_CLR_MRG.color[3]
  if ( val == 1 ) then
    vws.PHT_CLR_NTE_OFF_SLR_1.value = r
    vws.PHT_CLR_NTE_OFF_SLR_2.value = g
    vws.PHT_CLR_NTE_OFF_SLR_3.value = b
  elseif ( val == 2 ) then
    vws.PHT_CLR_NTE_ON_BACK_SLR_1.value = r
    vws.PHT_CLR_NTE_ON_BACK_SLR_2.value = g
    vws.PHT_CLR_NTE_ON_BACK_SLR_3.value = b
  elseif ( val == 3 ) then
    vws.PHT_CLR_NTE_ON_MARKED_SLR_1.value = r
    vws.PHT_CLR_NTE_ON_MARKED_SLR_2.value = g
    vws.PHT_CLR_NTE_ON_MARKED_SLR_3.value = b
  elseif ( val == 4 ) then
    vws.PHT_CLR_NTE_SEL_BACK_SLR_1.value = r
    vws.PHT_CLR_NTE_SEL_BACK_SLR_2.value = g
    vws.PHT_CLR_NTE_SEL_BACK_SLR_3.value = b
  elseif ( val == 5 ) then
    vws.PHT_CLR_NTE_SEL_MARKED_SLR_1.value = r
    vws.PHT_CLR_NTE_SEL_MARKED_SLR_2.value = g
    vws.PHT_CLR_NTE_SEL_MARKED_SLR_3.value = b
  else
    vws.PHT_CLR_WINDOW_MODES_SLR_1.value = r
    vws.PHT_CLR_WINDOW_MODES_SLR_2.value = g
    vws.PHT_CLR_WINDOW_MODES_SLR_3.value = b
  end
end
---
PHT_CLR_TB_MGR = {
  { 166,041,041 }, { 166,080,041 }, { 166,119,041 }, { 166,144,041 }, { 161,166,041 }, { 119,166,047 }, { 072,166,047 }, { 063,166,106 },
  { 041,166,154 }, { 041,117,166 }, { 041,059,166 }, { 095,058,166 }, { 138,041,166 }, { 141,036,132 }, { 166,041,119 }, { 166,041,080 },
  { 249,000,000 }, { 249,125,000 }, { 249,249,000 }, { 000,249,041 }, { 000,083,249 }, { 137,000,249 }, { 249,000,166 }, { 001,000,000 },
  { 150,000,000 }, { 150,076,000 }, { 150,150,000 }, { 000,150,025 }, { 000,050,150 }, { 082,000,150 }, { 150,000,100 }, { 082,082,082 },
  { 150,097,097 }, { 150,123,093 }, { 150,150,097 }, { 097,150,106 }, { 097,115,150 }, { 126,097,150 }, { 150,097,132 }, { 164,164,164 },
  { 249,125,125 }, { 249,187,125 }, { 250,250,126 }, { 125,249,146 }, { 125,166,249 }, { 194,125,249 }, { 249,125,207 }, { 249,249,249 }
}
---
class "Pht_Clr_Btt"
function Pht_Clr_Btt:__init( i, val_1, val_2 )
  self.cnt = vb:button {
    id = "Pht_Clr_Btt"..i,
    height = 14,
    width = 31,
    color = PHT_CLR_TB_MGR[i],
    notifier = function() vws.PHT_MAIN_CLR_MRG.color = PHT_CLR_TB_MGR[i] end
   }
end
---
function pht_main_clr_btt( val_1, val_2 )
  local main_clr_btt = vb:row { spacing = -3 }
  for i = val_1, val_2 do
    main_clr_btt:add_child(
      Pht_Clr_Btt( i, val_1, val_2 ).cnt
    )
  end
  return main_clr_btt
end
---
PHT_CLR_SEL_PNL_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column { spacing = -3,
      pht_main_clr_btt( 1,  8 ),
      pht_main_clr_btt( 9, 16 ),
      vb:space { height = 6 },
      pht_main_clr_btt( 17,24 ),
      pht_main_clr_btt( 25,32 ),
      pht_main_clr_btt( 33,40 ),
      pht_main_clr_btt( 41,48 )
    },
    vb:bitmap {
      height = 72,
      width = 14,
      bitmap = "./ico/migrate_out_ico.png",
      mode = "body_color"
    },
    vb:column {
      vb:button {
        id = "PHT_MAIN_CLR_MRG",
        height = 53,
        width = 23,
        bitmap = "./ico/main_v_ico.png",
        color = PHT_CLR_TB_MGR[1],
        tooltip = "Main color\nShow the main color to import after the RGB colors from each panel of colors\n\n"..
                  "Additionally, also open the folder that contain the Config.xml file, where the configuration of the colors theme of Renoise is saved (Windows only!). You can steal from it values of specific colors.",
        notifier = function() pht_clr_open_config_xml() end
      },
      vb:button {
        height = 19,
        width = 23,
        text = "Tr",
        notifier = function() vws.PHT_MAIN_CLR_MRG.color = song.selected_track.color end,
        tooltip = "Import the color of the selected track"
      }      
    }
  }
}



--general anchor for sliders
function pht_anchor_sliders( input )
  return math.min( math.max( input, 0), 255 )
end



------------------------------------------------------------------------------------------------
--color for window modes

--color & panel
function pht_clr_window_modes_pnl_update( clr )
  --preferences
  pht_pref.pht_sky_blue[1].value = clr[1]
  pht_pref.pht_sky_blue[2].value = clr[2]
  pht_pref.pht_sky_blue[3].value = clr[3]
  --general button color
  vws.PHT_CLR_WINDOW_MODES_MIGRATE_OUT.color = clr
  ---
  vws.PHT_COMPACT.color = clr --expand phrasetouch
  --window modes buttons
  for i = 1, 4 do --1,5,9,13 phrasetouch
    if ( PHT_SEL_PNL_GR[i] == true ) then 
      vws["PHT_BT_PNL_GR_X"..i].color = clr
    end
  end
  for i = 1, 3 do --x1,x2,x4 phrasetouch
    if ( PHT_SEL_PNL_MN[i] == true ) then
      vws["PHT_BT_PNL_MN_X"..i].color = clr
    end
  end
  vws.PHT_FAV_BT_X64.color = clr --x2,x4 favtouch
  PHT_SEQ_CTRL_BLOCKS.color = clr --x1,x2v,x2h step sequencer
end


--random & default
function pht_clr_window_modes_random()
  vws.PHT_CLR_WINDOW_MODES_VFD_1.value = math.random( 0,255 )
  vws.PHT_CLR_WINDOW_MODES_VFD_2.value = math.random( 0,255 )
  vws.PHT_CLR_WINDOW_MODES_VFD_3.value = math.random( 0,255 )
end
---
function pht_clr_window_modes_default()
  vws.PHT_CLR_WINDOW_MODES_VFD_1.value = PHT_MAIN_COLOR_DEF.SKY_BLUE_DEF[1]
  vws.PHT_CLR_WINDOW_MODES_VFD_2.value = PHT_MAIN_COLOR_DEF.SKY_BLUE_DEF[2]
  vws.PHT_CLR_WINDOW_MODES_VFD_3.value = PHT_MAIN_COLOR_DEF.SKY_BLUE_DEF[3]
end



---anchor, update, start & end
local pht_clr_window_modes_anchor = false
function pht_clr_window_modes_anchor_rgb()
  if ( pht_clr_window_modes_anchor == false ) then
    pht_clr_window_modes_anchor = true
    vws.PHT_CLR_WINDOW_MODES_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_WINDOW_MODES_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_WINDOW_MODES_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_WINDOW_MODES_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_WINDOW_MODES_VFD_1.active = false
    vws.PHT_CLR_WINDOW_MODES_VFD_2.active = false
    vws.PHT_CLR_WINDOW_MODES_VFD_3.active = false
    vws.PHT_CLR_WINDOW_MODES_MIGRATE_IN.active = false
  else
    pht_clr_window_modes_anchor = false
    vws.PHT_CLR_WINDOW_MODES_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_WINDOW_MODES_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_WINDOW_MODES_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_WINDOW_MODES_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_WINDOW_MODES_VFD_1.active = true
    vws.PHT_CLR_WINDOW_MODES_VFD_2.active = true
    vws.PHT_CLR_WINDOW_MODES_VFD_3.active = true
    vws.PHT_CLR_WINDOW_MODES_MIGRATE_IN.active = true
  end
end



function pht_clr_window_modes_slr( num, val )
  local clr = PHT_MAIN_COLOR.SKY_BLUE
  if ( pht_clr_window_modes_anchor == true ) then
    local diff = val - clr[num]
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_WINDOW_MODES_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val  
  end
  --update colors
    pht_clr_window_modes_pnl_update( clr )
  --update valuefield
  vws["PHT_CLR_WINDOW_MODES_VFD_"..num].value = val
end
---
function pht_clr_window_modes_vfd( val, num )
  if ( pht_clr_window_modes_anchor == false ) then
    vws["PHT_CLR_WINDOW_MODES_SLR_"..num].value = val
  end
end



function pht_clr_window_modes_start_rgb()
  vws.PHT_CLR_WINDOW_MODES_SLR_1.value = 0
  vws.PHT_CLR_WINDOW_MODES_SLR_2.value = 0
  vws.PHT_CLR_WINDOW_MODES_SLR_3.value = 0
end
---
function pht_clr_window_modes_end_rgb()
  vws.PHT_CLR_WINDOW_MODES_SLR_1.value = 255
  vws.PHT_CLR_WINDOW_MODES_SLR_2.value = 255
  vws.PHT_CLR_WINDOW_MODES_SLR_3.value = 255
end



PHT_CLR_WINDOW_MODES_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5, spacing = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 150,
          text = "Window Modes",
        },
        vb:row { spacing = 6,
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_WINDOW_MODES_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_window_modes_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_WINDOW_MODES_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_window_modes_default() end,
              tooltip = "Default RGB color of the selected panel"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_WINDOW_MODES_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_window_modes_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_window_modes_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_window_modes_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_WINDOW_MODES_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[1],
              notifier = function( value ) pht_clr_window_modes_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_WINDOW_MODES_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_window_modes_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_WINDOW_MODES_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[2],
              notifier = function( value ) pht_clr_window_modes_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_WINDOW_MODES_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_window_modes_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_WINDOW_MODES_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[3],
              notifier = function( value ) pht_clr_window_modes_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_WINDOW_MODES_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.SKY_BLUE[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_window_modes_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_WINDOW_MODES_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.SKY_BLUE,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 6 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_WINDOW_MODES_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_WINDOW_MODES_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 6 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--color for note on back (all panels)

--color & panel
function pht_clr_nte_on_back_pnl_update( clr )
  local num, time, r, g, b = 26, 150

  --note on color for mst
  local clr_r, clr_g, clr_b = clr[1] + num, clr[2] + num, clr[3] + num
  local function nte_on_clr( clr )
    if ( clr[1] <= 1 ) then
      r = clr[1]
    else
      if ( clr_r <= 255 ) then
        r = clr_r
      else
        r = 255
      end
    end
    if ( clr[2] <= 1 ) then
      g = clr[2]
    else
      if ( clr_g <= 255 ) then
        g = clr_g
      else
        g = 255
      end
    end
    if ( clr[3] <= 1 ) then
      b = clr[3]
    else
      if ( clr_b <= 255 ) then
        b = clr_b
      else
        b = 255
      end
    end
    local clr = { r, g, b }
    --rprint(clr)
    return clr
  end

  --notes on back, mst on back, mst gnl back (with delay timers)
  local function pass_timer_17()
    rnt:remove_timer( pass_timer_17 )
    ---favtouch
    for i = 1, 64 do
      vws["PHT_FAV_BT_"..i].color = clr
      if ( pht_table_release_fav[i] ~= false ) then
        pht_table_release_fav[i] = false
      end
    end
  end
  ---
  local function pass_timer_16()
    rnt:remove_timer( pass_timer_16 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_16_"..i].color = clr
      if ( pht_table_release_16[i] ~= false ) then pht_table_release_16[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_16_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_16.color = clr
    vws.PHT_RTN_INS_VOL_16.color = clr
    vws.PHT_GNL_MST_16.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_17, time )
  end
  ---
  local function pass_timer_15()
    rnt:remove_timer( pass_timer_15 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_15_"..i].color = clr
      if ( pht_table_release_15[i] ~= false ) then pht_table_release_15[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_15_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_15.color = clr
    vws.PHT_RTN_INS_VOL_15.color = clr
    vws.PHT_GNL_MST_15.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_16, time )
  end
  ---
  local function pass_timer_14()
    rnt:remove_timer( pass_timer_14 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_14_"..i].color = clr
      if ( pht_table_release_14[i] ~= false ) then pht_table_release_14[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_14_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_14.color = clr
    vws.PHT_RTN_INS_VOL_14.color = clr
    vws.PHT_GNL_MST_14.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_15, time )
  end
  ---
  local function pass_timer_13()
    rnt:remove_timer( pass_timer_13 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_13_"..i].color = clr
      if ( pht_table_release_13[i] ~= false ) then pht_table_release_13[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_13_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_13.color = clr
    vws.PHT_RTN_INS_VOL_13.color = clr
    vws.PHT_GNL_MST_13.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_14, time )
  end
  ---
  local function pass_timer_12()
    rnt:remove_timer( pass_timer_12 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_12_"..i].color = clr
      if ( pht_table_release_12[i] ~= false ) then pht_table_release_12[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_12_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_12.color = clr
    vws.PHT_RTN_INS_VOL_12.color = clr
    vws.PHT_GNL_MST_12.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_13, time )
  end
  ---
  local function pass_timer_11()
    rnt:remove_timer( pass_timer_11 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_11_"..i].color = clr
      if ( pht_table_release_11[i] ~= false ) then pht_table_release_11[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_11_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_11.color = clr
    vws.PHT_RTN_INS_VOL_11.color = clr
    vws.PHT_GNL_MST_11.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_12, time )
  end
  ---
  local function pass_timer_10()
    rnt:remove_timer( pass_timer_10 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_10_"..i].color = clr
      if ( pht_table_release_10[i] ~= false ) then pht_table_release_10[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_10_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_10.color = clr
    vws.PHT_RTN_INS_VOL_10.color = clr
    vws.PHT_GNL_MST_10.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_11, time )
  end
  ---
  local function pass_timer_9()
    rnt:remove_timer( pass_timer_9 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_9_"..i].color =  clr
      if ( pht_table_release_9[i] ~= false ) then pht_table_release_9[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_9_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_9.color = clr
    vws.PHT_RTN_INS_VOL_9.color = clr
    vws.PHT_GNL_MST_9.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_10, time )
  end
  ---
  local function pass_timer_8()
    rnt:remove_timer( pass_timer_8 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_8_"..i].color =  clr
      if ( pht_table_release_8[i] ~= false ) then pht_table_release_8[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_8_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_8.color = clr
    vws.PHT_RTN_INS_VOL_8.color = clr
    vws.PHT_GNL_MST_8.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_9, time )
  end
  ---
  local function pass_timer_7()
    rnt:remove_timer( pass_timer_7 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_7_"..i].color =  clr
      if ( pht_table_release_7[i] ~= false ) then pht_table_release_7[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_7_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_7.color = clr
    vws.PHT_RTN_INS_VOL_7.color = clr
    vws.PHT_GNL_MST_7.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_8, time )
  end
  ---
  local function pass_timer_6()
    rnt:remove_timer( pass_timer_6 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_6_"..i].color =  clr
      if ( pht_table_release_6[i] ~= false ) then pht_table_release_6[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_6_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_6.color = clr
    vws.PHT_RTN_INS_VOL_6.color = clr
    vws.PHT_GNL_MST_6.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_7, time )
  end
  ---
  local function pass_timer_5()
    rnt:remove_timer( pass_timer_5 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_5_"..i].color =  clr
      if ( pht_table_release_5[i] ~= false ) then pht_table_release_5[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_5_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_5.color = clr
    vws.PHT_RTN_INS_VOL_5.color = clr
    vws.PHT_GNL_MST_5.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_6, time )
  end
  ---
  local function pass_timer_4()
    rnt:remove_timer( pass_timer_4 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_4_"..i].color =  clr
      if ( pht_table_release_4[i] ~= false ) then pht_table_release_4[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_4_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_4.color = clr
    vws.PHT_RTN_INS_VOL_4.color = clr
    vws.PHT_GNL_MST_4.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_5, time )
  end
  ---
  local function pass_timer_3()
    rnt:remove_timer( pass_timer_3 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_3_"..i].color =  clr
      if ( pht_table_release_3[i] ~= false ) then pht_table_release_3[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_3_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_3.color = clr
    vws.PHT_RTN_INS_VOL_3.color = clr
    vws.PHT_GNL_MST_3.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_4, time )
  end
  ---
  local function pass_timer_2()
    rnt:remove_timer( pass_timer_2 )
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_2_"..i].color =  clr
      if ( pht_table_release_2[i] ~= false ) then pht_table_release_2[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_2_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_2.color = clr
    vws.PHT_RTN_INS_VOL_2.color = clr
    vws.PHT_GNL_MST_2.color = nte_on_clr( clr )
    rnt:add_timer( pass_timer_3, time )
  end
  ---
  local function pass_timer_1()
    for i = 0, 119 do
      vws["PHT_NTE_ON_BTT_1_"..i].color =  clr
      if ( pht_table_release_1[i] ~= false ) then pht_table_release_1[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_ON_BTT_1_"..i].color = nte_on_clr( clr )
    end
    vws.PHT_RTN_VOL_1.color = clr
    vws.PHT_RTN_INS_VOL_1.color = clr
    vws.PHT_GNL_MST_1.color = nte_on_clr( clr )
    --general button color
    vws.PHT_CLR_NTE_ON_BACK_MIGRATE_OUT.color = clr
    rnt:add_timer( pass_timer_2, time )
  end
  pass_timer_1()
  
  ---preferences
  pht_pref.pht_gold_off2[1].value = nte_on_clr( clr )[1] --clr[1]
  pht_pref.pht_gold_off2[2].value = nte_on_clr( clr )[2] --clr[2]
  pht_pref.pht_gold_off2[3].value = nte_on_clr( clr )[3] --clr[3]

  pht_pref.pht_gold_off1[1].value = clr[1]
  pht_pref.pht_gold_off1[2].value = clr[2]
  pht_pref.pht_gold_off1[3].value = clr[3]
end



--random & default
function pht_clr_nte_on_back_random()
  vws.PHT_CLR_NTE_ON_BACK_VFD_1.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_ON_BACK_VFD_2.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_ON_BACK_VFD_3.value = math.random( 0,255 )
end
---
function pht_clr_nte_on_back_default()
  vws.PHT_CLR_NTE_ON_BACK_VFD_1.value = PHT_MAIN_COLOR_DEF.GOLD_OFF1_DEF[1]
  vws.PHT_CLR_NTE_ON_BACK_VFD_2.value = PHT_MAIN_COLOR_DEF.GOLD_OFF1_DEF[2]
  vws.PHT_CLR_NTE_ON_BACK_VFD_3.value = PHT_MAIN_COLOR_DEF.GOLD_OFF1_DEF[3]
end



---anchor, update, start & end
local pht_clr_nte_on_back_anchor = false
function pht_clr_nte_on_back_anchor_rgb()
  if ( pht_clr_nte_on_back_anchor == false ) then
    --pht_clr_nte_on_back_sel_last()
    pht_clr_nte_on_back_anchor = true
    vws.PHT_CLR_NTE_ON_BACK_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_NTE_ON_BACK_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_NTE_ON_BACK_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_NTE_ON_BACK_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_NTE_ON_BACK_VFD_1.active = false
    vws.PHT_CLR_NTE_ON_BACK_VFD_2.active = false
    vws.PHT_CLR_NTE_ON_BACK_VFD_3.active = false
    vws.PHT_CLR_NTE_ON_BACK_MIGRATE_IN.active = false
  else
    pht_clr_nte_on_back_anchor = false
    vws.PHT_CLR_NTE_ON_BACK_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_NTE_ON_BACK_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_NTE_ON_BACK_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_NTE_ON_BACK_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_NTE_ON_BACK_VFD_1.active = true
    vws.PHT_CLR_NTE_ON_BACK_VFD_2.active = true
    vws.PHT_CLR_NTE_ON_BACK_VFD_3.active = true
    vws.PHT_CLR_NTE_ON_BACK_MIGRATE_IN.active = true
  end
end



function pht_clr_nte_on_back_slr( num, val )
  local clr = PHT_MAIN_COLOR.GOLD_OFF1
  if ( pht_clr_nte_on_back_anchor == true ) then
    local diff = val - clr[num]
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_NTE_ON_BACK_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val
  end
  --update colors
    pht_clr_nte_on_back_pnl_update( clr )
  --update valuefield
  vws["PHT_CLR_NTE_ON_BACK_VFD_"..num].value = val
end



function pht_clr_nte_on_back_vfd( val, num )
  if ( pht_clr_nte_on_back_anchor == false ) then
    vws["PHT_CLR_NTE_ON_BACK_SLR_"..num].value = val
  end
end
---
function pht_clr_nte_on_back_start_rgb()
  vws.PHT_CLR_NTE_ON_BACK_SLR_1.value = 0
  vws.PHT_CLR_NTE_ON_BACK_SLR_2.value = 0
  vws.PHT_CLR_NTE_ON_BACK_SLR_3.value = 0
end
---
function pht_clr_nte_on_back_end_rgb()
  vws.PHT_CLR_NTE_ON_BACK_SLR_1.value = 255
  vws.PHT_CLR_NTE_ON_BACK_SLR_2.value = 255
  vws.PHT_CLR_NTE_ON_BACK_SLR_3.value = 255
end




PHT_CLR_NTE_ON_BACK_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 150,
          text = "Note On Back",
        },
        vb:row { spacing = 6,
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_BACK_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_nte_on_back_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_NTE_ON_BACK_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_nte_on_back_default() end,
              tooltip = "Default RGB color of the selected panel"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_BACK_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_nte_on_back_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_nte_on_back_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_nte_on_back_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_BACK_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[1],
              notifier = function( value ) pht_clr_nte_on_back_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_BACK_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_back_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_BACK_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[2],
              notifier = function( value ) pht_clr_nte_on_back_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_BACK_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_back_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_BACK_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[3],
              notifier = function( value ) pht_clr_nte_on_back_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_BACK_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_OFF1[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_back_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_BACK_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.GOLD_OFF1,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 2 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_NTE_ON_BACK_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_NTE_ON_BACK_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 2 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}


------------------------------------------------------------------------------------------------
--color for note on marked (individual panel)

--color & panel
---
function pht_clr_nte_on_marked_pnl_update( clr )
  ---preferences
  pht_pref.pht_gold_on[1].value = clr[1]
  pht_pref.pht_gold_on[2].value = clr[2]
  pht_pref.pht_gold_on[3].value = clr[3]
  --general button color
  vws.PHT_CLR_NTE_ON_MARKED_MIGRATE_OUT.color = clr
end


--random & default
function pht_clr_nte_on_marked_random()
  vws.PHT_CLR_NTE_ON_MARKED_VFD_1.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_ON_MARKED_VFD_2.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_ON_MARKED_VFD_3.value = math.random( 0,255 )
end
---
function pht_clr_nte_on_marked_default()
  vws.PHT_CLR_NTE_ON_MARKED_VFD_1.value = PHT_MAIN_COLOR_DEF.GOLD_ON_DEF[1]
  vws.PHT_CLR_NTE_ON_MARKED_VFD_2.value = PHT_MAIN_COLOR_DEF.GOLD_ON_DEF[2]
  vws.PHT_CLR_NTE_ON_MARKED_VFD_3.value = PHT_MAIN_COLOR_DEF.GOLD_ON_DEF[3]
end



---anchor, update, start & end
local pht_clr_nte_on_marked_anchor = false
function pht_clr_nte_on_marked_anchor_rgb()
  if ( pht_clr_nte_on_marked_anchor == false ) then
    pht_clr_nte_on_marked_anchor = true
    vws.PHT_CLR_NTE_ON_MARKED_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_NTE_ON_MARKED_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_NTE_ON_MARKED_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_NTE_ON_MARKED_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_NTE_ON_MARKED_VFD_1.active = false
    vws.PHT_CLR_NTE_ON_MARKED_VFD_2.active = false
    vws.PHT_CLR_NTE_ON_MARKED_VFD_3.active = false
    vws.PHT_CLR_NTE_ON_MARKED_MIGRATE_IN.active = false
  else
    pht_clr_nte_on_marked_anchor = false
    vws.PHT_CLR_NTE_ON_MARKED_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_NTE_ON_MARKED_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_NTE_ON_MARKED_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_NTE_ON_MARKED_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_NTE_ON_MARKED_VFD_1.active = true
    vws.PHT_CLR_NTE_ON_MARKED_VFD_2.active = true
    vws.PHT_CLR_NTE_ON_MARKED_VFD_3.active = true
    vws.PHT_CLR_NTE_ON_MARKED_MIGRATE_IN.active = true
  end
end



function pht_clr_nte_on_marked_slr( num, val )
  local clr = PHT_MAIN_COLOR.GOLD_ON
  if ( pht_clr_nte_on_marked_anchor == true ) then
    local diff = val - clr[num]
    --print("diff", diff)
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_NTE_ON_MARKED_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val
  end
  --update colors
    pht_clr_nte_on_marked_pnl_update( clr )
  --update valuefield
  vws["PHT_CLR_NTE_ON_MARKED_VFD_"..num].value = val
end
---
function pht_clr_nte_on_marked_vfd( val, num )
  if ( pht_clr_nte_on_marked_anchor == false ) then
    vws["PHT_CLR_NTE_ON_MARKED_SLR_"..num].value = val
  end
end



function pht_clr_nte_on_marked_start_rgb()
  vws.PHT_CLR_NTE_ON_MARKED_SLR_1.value = 0
  vws.PHT_CLR_NTE_ON_MARKED_SLR_2.value = 0
  vws.PHT_CLR_NTE_ON_MARKED_SLR_3.value = 0
end
---
function pht_clr_nte_on_marked_end_rgb()
  vws.PHT_CLR_NTE_ON_MARKED_SLR_1.value = 255
  vws.PHT_CLR_NTE_ON_MARKED_SLR_2.value = 255
  vws.PHT_CLR_NTE_ON_MARKED_SLR_3.value = 255
end




PHT_CLR_NTE_ON_MARKED_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 150,
          text = "Note On Marked (Sel)",
        },
        vb:row { spacing = 6,
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_MARKED_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_nte_on_marked_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_NTE_ON_MARKED_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_nte_on_marked_default() end,
              tooltip = "Default RGB color of the selected panel"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_MARKED_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_nte_on_marked_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_nte_on_marked_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_nte_on_marked_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_MARKED_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[1],
              notifier = function( value ) pht_clr_nte_on_marked_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_MARKED_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_marked_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_MARKED_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[2],
              notifier = function( value ) pht_clr_nte_on_marked_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_MARKED_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_marked_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_NTE_ON_MARKED_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[3],
              notifier = function( value ) pht_clr_nte_on_marked_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_ON_MARKED_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GOLD_ON[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_on_marked_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_ON_MARKED_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.GOLD_ON,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 3 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_NTE_ON_MARKED_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_NTE_ON_MARKED_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 3 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--color for note select back (individual panel)

--color & panel
function pht_clr_nte_sel_back_pnl_update( clr )
  local time = 150

  --note select back
  local function pass_timer_17()
    rnt:remove_timer( pass_timer_17 )
    ---favtouch
    for i = 1, 64 do
      vws["PHT_FAV_BT_SEL_"..i].color = clr
    end  
  end
  ---
  local function pass_timer_16()
    rnt:remove_timer( pass_timer_16 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_16_"..i].color = clr
      if ( pht_table_mark_16[i] ~= false ) then pht_table_mark_16[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_16_"..i].color = clr
    end
    vws.PHT_GNL_UMK_16.color = clr
    rnt:add_timer( pass_timer_17, time )
  end
  ---
  local function pass_timer_15()
    rnt:remove_timer( pass_timer_15 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_15_"..i].color = clr
      if ( pht_table_mark_15[i] ~= false ) then pht_table_mark_15[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_15_"..i].color = clr
    end
    vws.PHT_GNL_UMK_15.color = clr
    rnt:add_timer( pass_timer_16, time )
  end
  ---
  local function pass_timer_14()
    rnt:remove_timer( pass_timer_14 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_14_"..i].color = clr
      if ( pht_table_mark_14[i] ~= false ) then pht_table_mark_14[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_14_"..i].color = clr
    end
    vws.PHT_GNL_UMK_14.color = clr
    rnt:add_timer( pass_timer_15, time )
  end
  ---
  local function pass_timer_13()
    rnt:remove_timer( pass_timer_13 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_13_"..i].color = clr
      if ( pht_table_mark_13[i] ~= false ) then pht_table_mark_13[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_13_"..i].color = clr
    end
    vws.PHT_GNL_UMK_13.color = clr
    rnt:add_timer( pass_timer_14, time )
  end
  ---
  local function pass_timer_12()
    rnt:remove_timer( pass_timer_12 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_12_"..i].color = clr
      if ( pht_table_mark_12[i] ~= false ) then pht_table_mark_12[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_12_"..i].color = clr
    end
    vws.PHT_GNL_UMK_12.color = clr
    rnt:add_timer( pass_timer_13, time )
  end
  ---
  local function pass_timer_11()
    rnt:remove_timer( pass_timer_11 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_11_"..i].color = clr
      if ( pht_table_mark_11[i] ~= false ) then pht_table_mark_11[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_11_"..i].color = clr
    end
    vws.PHT_GNL_UMK_11.color = clr
    rnt:add_timer( pass_timer_12, time )
  end
  ---
  local function pass_timer_10()
    rnt:remove_timer( pass_timer_10 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_10_"..i].color = clr
      if ( pht_table_mark_10[i] ~= false ) then pht_table_mark_10[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_10_"..i].color = clr
    end
    vws.PHT_GNL_UMK_10.color = clr
    rnt:add_timer( pass_timer_11, time )
  end
  ---
  local function pass_timer_9()
    rnt:remove_timer( pass_timer_9 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_9_"..i].color = clr
      if ( pht_table_mark_9[i] ~= false ) then pht_table_mark_9[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_9_"..i].color = clr
    end
    vws.PHT_GNL_UMK_9.color = clr
    rnt:add_timer( pass_timer_10, time )
  end
  ---
  local function pass_timer_8()
    rnt:remove_timer( pass_timer_8 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_8_"..i].color = clr
      if ( pht_table_mark_8[i] ~= false ) then pht_table_mark_8[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_8_"..i].color = clr
    end
    vws.PHT_GNL_UMK_8.color = clr
    rnt:add_timer( pass_timer_9, time )
  end
  ---
  local function pass_timer_7()
    rnt:remove_timer( pass_timer_7 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_7_"..i].color = clr
      if ( pht_table_mark_7[i] ~= false ) then pht_table_mark_7[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_7_"..i].color = clr
    end
    vws.PHT_GNL_UMK_7.color = clr
    rnt:add_timer( pass_timer_8, time )
  end
  ---
  local function pass_timer_6()
    rnt:remove_timer( pass_timer_6 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_6_"..i].color = clr
      if ( pht_table_mark_6[i] ~= false ) then pht_table_mark_6[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_6_"..i].color = clr
    end
    vws.PHT_GNL_UMK_6.color = clr
    rnt:add_timer( pass_timer_7, time )
  end
  ---
  local function pass_timer_5()
    rnt:remove_timer( pass_timer_5 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_5_"..i].color = clr
      if ( pht_table_mark_5[i] ~= false ) then pht_table_mark_5[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_5_"..i].color = clr
    end
    vws.PHT_GNL_UMK_5.color = clr
    rnt:add_timer( pass_timer_6, time )
  end
  ---
  local function pass_timer_4()
    rnt:remove_timer( pass_timer_4 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_4_"..i].color = clr
      if ( pht_table_mark_4[i] ~= false ) then pht_table_mark_4[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_4_"..i].color = clr
    end
    vws.PHT_GNL_UMK_4.color = clr
    rnt:add_timer( pass_timer_5, time )
  end
  ---
  local function pass_timer_3()
    rnt:remove_timer( pass_timer_3 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_3_"..i].color = clr
      if ( pht_table_mark_3[i] ~= false ) then pht_table_mark_3[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_3_"..i].color = clr
    end
    vws.PHT_GNL_UMK_3.color = clr
    rnt:add_timer( pass_timer_4, time )
  end
  ---
  local function pass_timer_2()
    rnt:remove_timer( pass_timer_2 )
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_2_"..i].color = clr
      if ( pht_table_mark_2[i] ~= false ) then pht_table_mark_2[i] = false end
    end
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_2_"..i].color = clr
    end
    vws.PHT_GNL_UMK_2.color = clr
    rnt:add_timer( pass_timer_3, time )
  end
  ---
  local function pass_timer_1()
    for i = 0, 119 do
      vws["PHT_NTE_MRK_BTT_1_"..i].color = clr
      if ( pht_table_mark_1[i] ~= false ) then pht_table_mark_1[i] = false end
    end
    --general button color
    for i = 0, 9 do
      vws["PHT_MST_MRK_BTT_1_"..i].color = clr
    end
    vws.PHT_M_UNMARK.color = clr
    vws.PHT_GNL_UMK_1.color = clr
    vws.PHT_CLR_NTE_SEL_BACK_MIGRATE_OUT.color = clr
    rnt:add_timer( pass_timer_2, time )
  end
  pass_timer_1()
    
  --preferences
  pht_pref.pht_grey_off[1].value =clr[1]
  pht_pref.pht_grey_off[2].value =clr[2]
  pht_pref.pht_grey_off[3].value =clr[3]
end


--random & default
function pht_clr_nte_sel_back_random()
  vws.PHT_CLR_NTE_SEL_BACK_VFD_1.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_SEL_BACK_VFD_2.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_SEL_BACK_VFD_3.value = math.random( 0,255 )
end
---
function pht_clr_nte_sel_back_default()
  vws.PHT_CLR_NTE_SEL_BACK_VFD_1.value = PHT_MAIN_COLOR_DEF.GREY_OFF_DEF[1]
  vws.PHT_CLR_NTE_SEL_BACK_VFD_2.value = PHT_MAIN_COLOR_DEF.GREY_OFF_DEF[2]
  vws.PHT_CLR_NTE_SEL_BACK_VFD_3.value = PHT_MAIN_COLOR_DEF.GREY_OFF_DEF[3]
end



---anchor, update, start & end
local pht_clr_nte_sel_back_anchor = false
function pht_clr_nte_sel_back_anchor_rgb()
  if ( pht_clr_nte_sel_back_anchor == false ) then
    --pht_clr_nte_sel_back_sel_last()
    pht_clr_nte_sel_back_anchor = true
    vws.PHT_CLR_NTE_SEL_BACK_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_NTE_SEL_BACK_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_NTE_SEL_BACK_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_NTE_SEL_BACK_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_NTE_SEL_BACK_VFD_1.active = false
    vws.PHT_CLR_NTE_SEL_BACK_VFD_2.active = false
    vws.PHT_CLR_NTE_SEL_BACK_VFD_3.active = false
    vws.PHT_CLR_NTE_SEL_BACK_MIGRATE_IN.active = false
  else
    pht_clr_nte_sel_back_anchor = false
    vws.PHT_CLR_NTE_SEL_BACK_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_NTE_SEL_BACK_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_NTE_SEL_BACK_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_NTE_SEL_BACK_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_NTE_SEL_BACK_VFD_1.active = true
    vws.PHT_CLR_NTE_SEL_BACK_VFD_2.active = true
    vws.PHT_CLR_NTE_SEL_BACK_VFD_3.active = true
    vws.PHT_CLR_NTE_SEL_BACK_MIGRATE_IN.active = true
  end
end



function pht_clr_nte_sel_back_slr( num, val )
  local clr = PHT_MAIN_COLOR.GREY_OFF
  if ( pht_clr_nte_sel_back_anchor == true ) then
    local diff = val - clr[num]
    --print("diff", diff)
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_NTE_SEL_BACK_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val
  end
  --update colors
    pht_clr_nte_sel_back_pnl_update( clr )
  --update valuefield
  vws["PHT_CLR_NTE_SEL_BACK_VFD_"..num].value = val
end
---
function pht_clr_nte_sel_back_vfd( val, num )
  if ( pht_clr_nte_sel_back_anchor == false ) then
    vws["PHT_CLR_NTE_SEL_BACK_SLR_"..num].value = val
  end
end



function pht_clr_nte_sel_back_start_rgb()
  vws.PHT_CLR_NTE_SEL_BACK_SLR_1.value = 0
  vws.PHT_CLR_NTE_SEL_BACK_SLR_2.value = 0
  vws.PHT_CLR_NTE_SEL_BACK_SLR_3.value = 0
end
---
function pht_clr_nte_sel_back_end_rgb()
  vws.PHT_CLR_NTE_SEL_BACK_SLR_1.value = 255
  vws.PHT_CLR_NTE_SEL_BACK_SLR_2.value = 255
  vws.PHT_CLR_NTE_SEL_BACK_SLR_3.value = 255
end



PHT_CLR_NTE_SEL_BACK_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 150,
          text = "Note Select Back",
        },
        vb:row { spacing = 6,
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_BACK_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_nte_sel_back_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_NTE_SEL_BACK_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_nte_sel_back_default() end,
              tooltip = "Default RGB color of the selected panel"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_BACK_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_nte_sel_back_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_nte_sel_back_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_nte_sel_back_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_BACK_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[1],
              notifier = function( value ) pht_clr_nte_sel_back_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_BACK_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_back_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_BACK_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[2],
              notifier = function( value ) pht_clr_nte_sel_back_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_BACK_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_back_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_BACK_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[3],
              notifier = function( value ) pht_clr_nte_sel_back_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_BACK_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_OFF[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_back_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_BACK_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.GREY_OFF,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 4 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_NTE_SEL_BACK_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_NTE_SEL_BACK_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 4 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--color for note select marked (individual panel)

--color & panel
function pht_clr_nte_sel_marked_pnl_update( clr )
  --preferences
  pht_pref.pht_grey_on[1].value = clr[1]
  pht_pref.pht_grey_on[2].value = clr[2]
  pht_pref.pht_grey_on[3].value = clr[3]
  --general button color
  vws.PHT_CLR_NTE_SEL_MARKED_MIGRATE_OUT.color = clr
end


--random & default
function pht_clr_nte_sel_marked_random()
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_1.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_2.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_3.value = math.random( 0,255 )
end
---
function pht_clr_nte_sel_marked_default()
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_1.value = PHT_MAIN_COLOR_DEF.GREY_ON_DEF[1]
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_2.value = PHT_MAIN_COLOR_DEF.GREY_ON_DEF[2]
  vws.PHT_CLR_NTE_SEL_MARKED_VFD_3.value = PHT_MAIN_COLOR_DEF.GREY_ON_DEF[3]
end



---anchor, update, start & end
local pht_clr_nte_sel_marked_anchor = false
function pht_clr_nte_sel_marked_anchor_rgb()
  if ( pht_clr_nte_sel_marked_anchor == false ) then
    pht_clr_nte_sel_marked_anchor = true
    vws.PHT_CLR_NTE_SEL_MARKED_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_NTE_SEL_MARKED_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_NTE_SEL_MARKED_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_NTE_SEL_MARKED_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_1.active = false
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_2.active = false
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_3.active = false
    vws.PHT_CLR_NTE_SEL_MARKED_MIGRATE_IN.active = false
  else
    pht_clr_nte_sel_marked_anchor = false
    vws.PHT_CLR_NTE_SEL_MARKED_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_NTE_SEL_MARKED_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_NTE_SEL_MARKED_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_NTE_SEL_MARKED_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_1.active = true
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_2.active = true
    vws.PHT_CLR_NTE_SEL_MARKED_VFD_3.active = true
    vws.PHT_CLR_NTE_SEL_MARKED_MIGRATE_IN.active = true
  end
end



function pht_clr_nte_sel_marked_slr( num, val )
  local clr = PHT_MAIN_COLOR.GREY_ON
  if ( pht_clr_nte_sel_marked_anchor == true ) then
    local diff = val - clr[num]
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_NTE_SEL_MARKED_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val  
  end
  --update colors
    pht_clr_nte_sel_marked_pnl_update( clr )
  --update valuefield
  vws["PHT_CLR_NTE_SEL_MARKED_VFD_"..num].value = val
end
---
function pht_clr_nte_sel_marked_vfd( val, num )
  if ( pht_clr_nte_sel_marked_anchor == false ) then
    vws["PHT_CLR_NTE_SEL_MARKED_SLR_"..num].value = val
  end
end



function pht_clr_nte_sel_marked_start_rgb()
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_1.value = 0
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_2.value = 0
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_3.value = 0
end
---
function pht_clr_nte_sel_marked_end_rgb()
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_1.value = 255
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_2.value = 255
  vws.PHT_CLR_NTE_SEL_MARKED_SLR_3.value = 255
end



PHT_CLR_NTE_SEL_MARKED_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 150,
          text = "Note Select Marked",
        },
        vb:row { spacing = 6,
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_MARKED_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_nte_sel_marked_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_NTE_SEL_MARKED_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_nte_sel_marked_default() end,
              tooltip = "Default RGB color of the selected panel"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_MARKED_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_nte_sel_marked_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_nte_sel_marked_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_nte_sel_marked_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_MARKED_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[1],
              notifier = function( value ) pht_clr_nte_sel_marked_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_MARKED_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_marked_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_MARKED_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[2],
              notifier = function( value ) pht_clr_nte_sel_marked_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_MARKED_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_marked_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_NTE_SEL_MARKED_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[3],
              notifier = function( value ) pht_clr_nte_sel_marked_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_SEL_MARKED_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.GREY_ON[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_sel_marked_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_SEL_MARKED_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.GREY_ON,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 5 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_NTE_SEL_MARKED_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_NTE_SEL_MARKED_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 5 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--color for note off (individual panel)
function pht_clr_nte_off_pnl_update( pnl, clr )
  ---main panic, number name & volume return
  if ( pnl == 1 ) then
    --rprint(rgb)
    vws.PHT_M_PANIC.color = clr
    vws.PHT_FAV_PANIC.color = clr
  end
  vws["PHT_GNL_PNC_"..pnl].color = clr
  vws["PHT_PNL_NAME_"..pnl].color = clr
  vws["PHT_ZRO_INS_VOL_"..pnl].color = clr
  ---panic & notes
  for i = 0, 119 do 
    if ( i < 10 ) then
      vws["PHT_MST_OFF_BTT_"..pnl.."_"..i].color = clr
    end
    vws["PHT_NTE_OFF_BTT_"..pnl.."_"..i].color = clr
  end
  ---preferences  
  for i = 1, 3 do
    pht_pref["pht_red_off_"..pnl][i].value = clr[i]
  end
  --general button color
  vws.PHT_CLR_NTE_OFF_MIGRATE_OUT.color = clr
end


--panel selector, random, default & reset all
pht_clr_nte_off_sel_relay = false
function pht_clr_nte_off_vbx_sel( pnl )
  --button
  vws.PHT_CLR_NTE_OFF_MIGRATE_OUT.color = { pht_pref["pht_red_off_"..pnl][1].value, pht_pref["pht_red_off_"..pnl][2].value, pht_pref["pht_red_off_"..pnl][3].value }  
  --sliders
  pht_clr_nte_off_sel_relay = true --*
  vws.PHT_CLR_NTE_OFF_SLR_1.value = pht_pref["pht_red_off_"..pnl][1].value
  vws.PHT_CLR_NTE_OFF_SLR_2.value = pht_pref["pht_red_off_"..pnl][2].value
  vws.PHT_CLR_NTE_OFF_SLR_3.value = pht_pref["pht_red_off_"..pnl][3].value
  pht_clr_nte_off_sel_relay = false --*
end
---
function pht_clr_nte_off_random()
  vws.PHT_CLR_NTE_OFF_SLR_1.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_OFF_SLR_2.value = math.random( 0,255 )
  vws.PHT_CLR_NTE_OFF_SLR_3.value = math.random( 0,255 )
end
---
function pht_clr_nte_off_default( pnl )
  vws.PHT_CLR_NTE_OFF_SLR_1.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][1]
  vws.PHT_CLR_NTE_OFF_SLR_2.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][2]
  vws.PHT_CLR_NTE_OFF_SLR_3.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][3]
end
---
function pht_clr_nte_off_reset_all()
  vws.PHT_CLR_NTE_OFF_VBX_SEL.value = 16
  for pnl = 16, 1, -1 do
    vws.PHT_CLR_NTE_OFF_SLR_1.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][1]
    vws.PHT_CLR_NTE_OFF_SLR_2.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][2]
    vws.PHT_CLR_NTE_OFF_SLR_3.value = PHT_MAIN_COLOR_DEF["RED_OFF_DEF_"..pnl][3]
    if ( pnl > 1 ) then
      vws.PHT_CLR_NTE_OFF_VBX_SEL.value = pnl - 1
    end
  end
end



---anchor, update, start & end
pht_clr_nte_off_anchor = false
function pht_clr_nte_off_anchor_rgb()
  if ( pht_clr_nte_off_anchor == false ) then
    pht_clr_nte_off_anchor = true
    vws.PHT_CLR_NTE_OFF_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.GOLD_ON
    vws.PHT_CLR_NTE_OFF_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_close_ico.png"
    vws.PHT_CLR_NTE_OFF_VBX_SEL.active = false
    vws.PHT_CLR_NTE_OFF_RANDOM_SLIDERS.active = false
    vws.PHT_CLR_NTE_OFF_DEFAULT_SLIDERS.active = false
    vws.PHT_CLR_NTE_OFF_RESET_ALL_SLIDERS.active = false
    vws.PHT_CLR_NTE_OFF_VFD_1.active = false
    vws.PHT_CLR_NTE_OFF_VFD_2.active = false
    vws.PHT_CLR_NTE_OFF_VFD_3.active = false
    vws.PHT_CLR_NTE_OFF_MIGRATE_IN.active = false
  else
    pht_clr_nte_off_anchor = false
    vws.PHT_CLR_NTE_OFF_ANCHOR_SLIDERS.color = PHT_MAIN_COLOR.DEFAULT
    vws.PHT_CLR_NTE_OFF_ANCHOR_SLIDERS.bitmap = "./ico/mini_padlock_open_ico.png"
    vws.PHT_CLR_NTE_OFF_VBX_SEL.active = true
    vws.PHT_CLR_NTE_OFF_RANDOM_SLIDERS.active = true
    vws.PHT_CLR_NTE_OFF_DEFAULT_SLIDERS.active = true
    vws.PHT_CLR_NTE_OFF_RESET_ALL_SLIDERS.active = true
    vws.PHT_CLR_NTE_OFF_VFD_1.active = true
    vws.PHT_CLR_NTE_OFF_VFD_2.active = true
    vws.PHT_CLR_NTE_OFF_VFD_3.active = true
    vws.PHT_CLR_NTE_OFF_MIGRATE_IN.active = true
  end
end
---
function pht_clr_nte_off_slr( num, val )
  local clr = PHT_MAIN_COLOR.RED_OFF_1
  if ( pht_clr_nte_off_anchor == true ) then
    local diff = val - clr[num]
    --print("diff", diff)
    for i = 1, 3 do
      clr[i] = clr[i] + diff
      if ( clr[i] < 0 ) then
        clr[i] = 0
      elseif ( clr[i] > 255 ) then
        clr[i] = 255
      else
        if ( i ~= num ) then
          vws["PHT_CLR_NTE_OFF_SLR_"..i].value = pht_anchor_sliders( clr[i] )
        end
      end
    end
  else
    clr[ num ] = val
  end
  --update colors
  if ( pht_clr_nte_off_sel_relay == false ) then
    pht_clr_nte_off_pnl_update( vws.PHT_CLR_NTE_OFF_VBX_SEL.value, clr )
  end 
  --update valuefield
  vws["PHT_CLR_NTE_OFF_VFD_"..num].value = val
end
---
function pht_clr_nte_off_vfd( val, num )
  if ( pht_clr_nte_off_anchor == false ) then
    vws["PHT_CLR_NTE_OFF_SLR_"..num].value = val
  end
end
---
function pht_clr_nte_off_start_rgb()
  vws.PHT_CLR_NTE_OFF_SLR_1.value = 0
  vws.PHT_CLR_NTE_OFF_SLR_2.value = 0
  vws.PHT_CLR_NTE_OFF_SLR_3.value = 0
end
---
function pht_clr_nte_off_end_rgb()
  vws.PHT_CLR_NTE_OFF_SLR_1.value = 255
  vws.PHT_CLR_NTE_OFF_SLR_2.value = 255
  vws.PHT_CLR_NTE_OFF_SLR_3.value = 255
end
---
PHT_CLR_NTE_OFF_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row {
        vb:text {
          height = 18,
          width = 37,
          text = "Panel",
        },
        vb:row { spacing = 6,
          vb:valuebox {
            id = "PHT_CLR_NTE_OFF_VBX_SEL",
            height = 18,
            width = 49,
            min = 1,
            max = 16,
            value = 1,
            notifier = function(value) pht_clr_nte_off_vbx_sel( value ) end,
            tooltip = "Note Off Back\nSelect the number of panel to change the RGB color"
          },
          vb:row { spacing = -3,
            vb:space { width = 7 },
            vb:button {
              id = "PHT_CLR_NTE_OFF_RANDOM_SLIDERS",
              height = 18,
              width = 57,
              text= "Random",
              notifier = function() pht_clr_nte_off_random() end,
              tooltip = "Randomize the values to sliders"
            },
            vb:button {
              id = "PHT_CLR_NTE_OFF_DEFAULT_SLIDERS",
              height = 18,
              width = 57,
              text= "Default",
              notifier = function() pht_clr_nte_off_default( vws.PHT_CLR_NTE_OFF_VBX_SEL.value ) end,
              tooltip = "Default RGB color of the selected panel"
            },
            vb:button {
              id = "PHT_CLR_NTE_OFF_RESET_ALL_SLIDERS",
              height = 18,
              width = 57,
              text= "Reset All",
              notifier = function() pht_clr_nte_off_reset_all() end,
              tooltip = "Reset to default RGB colors of all the panels"
            }
          },
          vb:row { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_OFF_ANCHOR_SLIDERS",
              height = 18,
              width = 23,
              bitmap = "./ico/mini_padlock_open_ico.png",
              tooltip = "Anchor sliders to move simultaneously",
              notifier = function() pht_clr_nte_off_anchor_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_left_ico.png",
              tooltip = "Start RGB color",
              notifier = function() pht_clr_nte_off_start_rgb() end
            },
            vb:button {
              height = 18,
              width = 23,
              bitmap = "./ico/mini_right_ico.png",
              tooltip = "End RGB color",
              notifier = function() pht_clr_nte_off_end_rgb() end
            }
          }
        }
      },
      vb:row {
        vb:column {
          vb:row { 
            vb:text {
              height = 18,
              width = 37,
              text = "Red",
            },
            vb:slider {
              id = "PHT_CLR_NTE_OFF_SLR_1",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[1],
              notifier = function( value ) pht_clr_nte_off_slr( 1, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_OFF_VFD_1",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[1],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_off_vfd( value, 1 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Green",
            },
            vb:slider {
              id = "PHT_CLR_NTE_OFF_SLR_2",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[2],
              notifier = function( value ) pht_clr_nte_off_slr( 2, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_OFF_VFD_2",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[2],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_off_vfd( value, 2 ) end
            }
          },
          vb:row {
            vb:text {
              height = 18,
              width = 37,
              text = "Blue",
            },
            vb:slider {
              id = "PHT_CLR_NTE_OFF_SLR_3",
              height = 18,
              width = 241,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[3],
              notifier = function( value ) pht_clr_nte_off_slr( 3, math.floor( value ) ) end
            },
            vb:valuefield {
              id = "PHT_CLR_NTE_OFF_VFD_3",
              height = 18,
              width = 29,
              min = 0,
              max = 255,
              value = PHT_MAIN_COLOR.RED_OFF_1[3],
              tostring = function( value ) return ( "%.3d" ):format( value ) end,
              tonumber = function( value ) return tonumber( value ) end,
              notifier = function( value ) pht_clr_nte_off_vfd( value, 3 ) end
            }
          }
        },
        vb:column {
          vb:column { spacing = -3,
            vb:button {
              id = "PHT_CLR_NTE_OFF_MIGRATE_OUT",
              height = 19,
              width = 23,
              color = PHT_MAIN_COLOR.RED_OFF_1,
              bitmap = "./ico/migrate_out_ico.png",
              notifier = function() pht_clr_migrate_out( 1 ) end,
              tooltip = "Export the color to main color"
            },
            vb:button {
              height = 19,
              width = 23,
              text = "Tr",
              notifier = function() song.selected_track.color = vws.PHT_CLR_NTE_OFF_MIGRATE_OUT.color end,
              tooltip = "Export the color to selected track"
            }
          },
          vb:button {
            id = "PHT_CLR_NTE_OFF_MIGRATE_IN",
            height = 19,
            width = 23,
            bitmap = "./ico/migrate_in_ico.png",
            notifier = function() pht_clr_migrate_in( 1 ) end,
            tooltip = "Import the color from main color"
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--group + tracks control
function pht_clr_gr_trs_pp( val )
  if ( val == 3 ) then
    vws.PHT_CLR_GR_TRS_BT.text = "Modify"
  else
    vws.PHT_CLR_GR_TRS_BT.text = "Insert"
  end
  if ( val == 2 ) then
    vws.PHT_CLR_GR_TRS_SLR_1.active = true
    vws.PHT_CLR_GR_TRS_VFD_1.active = true
    
  else
    vws.PHT_CLR_GR_TRS_SLR_1.active = false
    vws.PHT_CLR_GR_TRS_VFD_1.active = false
  end
end
---
function pht_clr_gr_trs_bt( mode )
  if ( song.selected_track_index <= song.sequencer_track_count ) then
    if ( mode == 2 ) then
      song:insert_group_at( song.selected_track_index )
      song.selected_track.name = "PhraseTouch Group"
      song.selected_track.color = PHT_MAIN_COLOR["GOLD_ON"]
      song.selected_track.color_blend = vws.PHT_CLR_GR_TRS_VFD_1.value
    end
    for i = song.selected_track_index, song.selected_track_index + vws.PHT_CLR_GR_TRS_SW.value * 2 - 1 do
      if ( mode < 3 ) then
        song:insert_track_at( i )
      end
      if ( i <= song.sequencer_track_count ) and ( song:track( i ).type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
        local n = i - song.selected_track_index + 1
        song:track( i ).color = { pht_pref["pht_red_off_"..n][1].value, pht_pref["pht_red_off_"..n][2].value, pht_pref["pht_red_off_"..n][3].value }
        song:track( i ).color_blend = vws.PHT_CLR_GR_TRS_VFD_2.value
        song:track( i ).name = ("Panel %.2d"):format( n )
        song:track( i ).visible_effect_columns = 0
      end
      if ( mode == 2 ) then
        song:add_track_to_group( i, i + 1 )
      end
    end
    if ( mode == 2 ) then
      song.selected_track.group_parent.collapsed = true
    end
  end
end
---
---
function pht_clr_gr_trs_vfd( val, num )
  vws["PHT_CLR_GR_TRS_SLR_"..num].value = val
end
PHT_CLR_GR_TRS_CTRL = vb:row { margin = 1,
  vb:row { style = "group", margin = 5,
    vb:column {
      vb:row { spacing = 6,
        vb:text {
          height = 18,
          width = 94,
          text = "Group + Tracks",
        },
        vb:row { spacing = -3,
          vb:button {
            height = 18,
            width = 34,
            bitmap = "./ico/undo_ico.png",
            notifier = function() pht_undo() end,
            tooltip = "Undo"
          },
          vb:button {
            height = 18,
            width = 34,
            bitmap = "./ico/redo_ico.png",
            notifier = function() pht_redo() end,
            tooltip = "Redo"
          }
        },
        vb:row { spacing = -3,
          vb:popup {
            id = "PHT_CLR_GR_TRS_PP",
            height = 18,
            width = 105,
            items = { " Tracks", " Group + Tracks", " Existent" },
            notifier = function( value ) pht_clr_gr_trs_pp( value ) end,
            tooltip = "Insert/modify mode"
          },
          vb:button {
            id = "PHT_CLR_GR_TRS_BT",
            height = 18,
            width = 57,
            text = "Insert",
            notifier = function() pht_clr_gr_trs_bt( vws.PHT_CLR_GR_TRS_PP.value ) end,
            tooltip = "Insert/modify the tracks or group + tracks with the colors of the panels of the PhraseTouch"
          }
        }
      },
      vb:row { spacing = 3,
        vb:row { 
          vb:text {
            height = 18,
            width = 37,
            text = "Blend",
          },
          vb:text {
            height = 18,
            width = 19,
            text = "Gr",
          },
          vb:slider {
            id = "PHT_CLR_GR_TRS_SLR_1",
            active = false,
            height = 18,
            width = 105,
            min = 0,
            max = 99,
            value = 45,
            notifier = function( value ) vws.PHT_CLR_GR_TRS_VFD_1.value = value end,
            tooltip = "Background Blend for group"
          },
          vb:valuefield {
            id = "PHT_CLR_GR_TRS_VFD_1",
            active = false,
            height = 18,
            width = 21,
            min = 0,
            max = 99,
            value = 45,
            tostring = function( value ) return ( "%.2d" ):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) pht_clr_gr_trs_vfd( value, 1 ) end
          }
        },
        vb:row { 
          vb:text {
            height = 18,
            width = 19,
            text = "Tr",
          },
          vb:slider {
            id = "PHT_CLR_GR_TRS_SLR_2",
            height = 18,
            width = 105,
            min = 0,
            max = 99,
            value = 35,
            notifier = function( value ) vws.PHT_CLR_GR_TRS_VFD_2.value = value end,
            tooltip = "Background Blend for tracks"
          },
          vb:valuefield {
            id = "PHT_CLR_GR_TRS_VFD_2",
            height = 18,
            width = 21,
            min = 0,
            max = 99,
            value = 35,
            tostring = function( value ) return ( "%.2d" ):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) pht_clr_gr_trs_vfd( value, 2 ) end
          }
        }
      },
      vb:row {
        vb:text {
          height = 18,
          width = 93,
          text = "Number of Tracks",
        },
        vb:switch {
          id = "PHT_CLR_GR_TRS_SW",
          height = 18,
          width = 237,
          items = { "2", "4", "6", "8", "10", "12", "14", "16" },
          value = 2,
          tooltip = "Select the number of tracks to insert/modify"
        }
      }
    }
  }
}



--logo
PHT_CLR_LOGO_CMP = vb:horizontal_aligner {
  width = 706,
  mode = "right",
  vb:bitmap {
    height = 20,
    width = 149,
    mode = "body_color",
    bitmap = "./ico/color_settings_ico.png",
  }
}



------------------------------------------------------------------------------------------------
--main gui
local content_colors = vb:column { margin = 6, spacing = -22,
  vb:column { style = "panel", margin = 6, spacing = 5,
    vb:row { spacing = 5,
      PHT_CLR_PNL_SEL,
      PHT_CLR_WINDOW_MODES_CTRL,      
      PHT_CLR_SEL_PNL_CTRL
    },  
    vb:row { spacing = 5,
      PHT_CLR_NTE_ON_BACK_CTRL,
      PHT_CLR_NTE_ON_MARKED_CTRL
    },
    vb:row { spacing = 5,
      PHT_CLR_NTE_SEL_BACK_CTRL,
      PHT_CLR_NTE_SEL_MARKED_CTRL
    },
    vb:row { spacing = 5,
      PHT_CLR_NTE_OFF_CTRL,
      PHT_CLR_GR_TRS_CTRL
    }
  },
  PHT_CLR_LOGO_CMP
}



------------------------------------------------------------------------------------------------
--show dialog_colors
function show_tool_dialog_colors()
  --Avoid showing the same window several times!
  if ( dialog_colors and dialog_colors.visible ) then dialog_colors:show() return end
  dialog_colors = rna:show_custom_dialog( title_colors, content_colors, pht_keyhandler )
end
