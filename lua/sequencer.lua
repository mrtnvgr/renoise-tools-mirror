--
-- STEP SEQUENCER
--



dialog_sequencer = nil
local title_sequencer = " PhraseTouch:  Step Sequencer"



------------------------------------------------------------------------------------------------
--enable/disable panels

PHT_SEQ_ON_OFF_PNL = { true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,  --16
                       true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true } --32
function pht_seq_on_off_pnl( panel )
  if ( PHT_SEQ_ON_OFF_PNL[panel] == true ) then
    vws["PHT_SEQ_ON_OFF_"..panel].color = PHT_MAIN_COLOR.GREY_OFF
    PHT_SEQ_ON_OFF_PNL[panel] = false
  else
    vws["PHT_SEQ_ON_OFF_"..panel].color = PHT_MAIN_COLOR.GREY_ON
    PHT_SEQ_ON_OFF_PNL[panel] = true
  end
end
---
class "Pht_Seq_On_Off_Panel"
function Pht_Seq_On_Off_Panel:__init( panel )
  self.cnt = vb:button {
    id = "PHT_SEQ_ON_OFF_"..panel,
    height = 11,
    width = 48,
    color = PHT_MAIN_COLOR.GREY_ON,
    notifier = function() pht_seq_on_off_pnl( panel ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Skip Steps:"..( "Skip Step %.2d Checkbox" ):format( panel ),
    tooltip = ("Skip the step %.2d"):format( panel )
  }  
end
---
function pht_seq_bt_on_off_pnl_x16()
  local button = vb:row { spacing = 2 }
  for panel = 1, 16 do
    button:add_child (
      Pht_Seq_On_Off_Panel( panel ).cnt
    )
  end
  return button
end
---
function pht_seq_bt_on_off_pnl_x32()
  local button = vb:row { spacing = 2,
  }
  for panel = 17, 32 do
    button:add_child (
      Pht_Seq_On_Off_Panel( panel ).cnt
    )
  end
  return button
end



------------------------------------------------------------------------------------------------
--valuebox panel & reset button
class "Pht_Seq_Sel_Pnl"
function Pht_Seq_Sel_Pnl:__init( panel )
  self.cnt = vb:valuebox {
    id = "PHT_SEQ_VBX_SEL_PNL_"..panel,
    height = 21,
    width = 48,
    min = 0,
    max = 16,
    value = 1,
    tostring = function( value ) if ( value == 0 ) then return "--" else return ("%1d"):format( value ) end end,
    tonumber = function( value ) if ( string == "--" ) or ( string == "-" ) then return 0 else return tonumber( value ) end end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:"..( "Panel %.2d Valuebox" ):format( panel ),
    tooltip = ("Select the panel of notes for step %.2d\n[ Panel of notes: --, 1 to 16. Insert \"-\", \"--\" or 0 to mute ]"):format( panel )
  }
end
---
function pht_seq_vbx_sel_pnl_x16()
  local valuebox = vb:row { spacing = 2 }
  for panel = 1, 16 do
    valuebox:add_child (
      Pht_Seq_Sel_Pnl( panel ).cnt
    )
  end
  return valuebox
end
---
function pht_seq_vbx_sel_pnl_x32()
  local valuebox = vb:row { spacing = 2 }
  for panel = 17, 32 do
    valuebox:add_child (
      Pht_Seq_Sel_Pnl( panel ).cnt
    )
  end
  return valuebox
end
---
function pht_seq_reset()
  vws.PHT_SEQ_VBX_SEL_PNL_0.value = 1
  vws.PHT_SEQ_OCT_ALL.value = 10
  for i = 1, 32 do
    vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = 1
    vws["PHT_SEQ_BT_MARK_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1
  end
    vws.PHT_SEQ_BT_MARK_33.color = PHT_MAIN_COLOR.GOLD_OFF1
  for i = 1, 16 do
    vws["PHT_SEQ_VFD_STEP_TIMER_"..i].value = 200
  end
  for i = 17, 32 do
    vws["PHT_SEQ_VFD_STEP_TIMER_"..i].value = 100
  end
  for i = 33, 48 do
    vws["PHT_SEQ_VFD_STEP_TIMER_"..i].value = 200
  end
  for i = 49, 65 do
    vws["PHT_SEQ_VFD_STEP_TIMER_"..i].value = 100
  end
  vws.PHT_SEQ_RDM_VAL_1.value = 100
  vws.PHT_SEQ_RDM_VAL_2.value = 300
  vws.PHT_SEQ_RDM_VAL_3.value = 50
  vws.PHT_SEQ_RDM_VAL_4.value = 150
end



------------------------------------------------------------------------------------------------
--octaves valueboxes
--oct 0   1   2   3   4   5   6   7   8    9    All
    --0 , 12, 24, 36, 48, 60, 72, 84, 96,  108, 0
    --11, 23, 35, 47, 59, 71, 83, 95, 107, 119, 119

PHT_SEQ_OCT_A = { 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 }   --32
PHT_SEQ_OCT_B = { 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119, 119 } --32
---
function pht_seq_change_oct( value, pnl )
  if ( value == 0 ) then
    PHT_SEQ_OCT_A[ pnl ] = 0
    PHT_SEQ_OCT_B[ pnl ] = 11
  end
  if ( value == 1 ) then
    PHT_SEQ_OCT_A[ pnl ] = 12
    PHT_SEQ_OCT_B[ pnl ] = 23
  end
  if ( value == 2 ) then
    PHT_SEQ_OCT_A[ pnl ] = 24
    PHT_SEQ_OCT_B[ pnl ] = 35
  end
  if ( value == 3 ) then
    PHT_SEQ_OCT_A[ pnl ] = 36
    PHT_SEQ_OCT_B[ pnl ] = 47
  end
  if ( value == 4 ) then
    PHT_SEQ_OCT_A[ pnl ] = 48
    PHT_SEQ_OCT_B[ pnl ] = 59
  end
  if ( value == 5 ) then
    PHT_SEQ_OCT_A[ pnl ] = 60
    PHT_SEQ_OCT_B[ pnl ] = 71
  end
  if ( value == 6 ) then
    PHT_SEQ_OCT_A[ pnl ] = 72
    PHT_SEQ_OCT_B[ pnl ] = 83
  end
  if ( value == 7 ) then
    PHT_SEQ_OCT_A[ pnl ] = 84
    PHT_SEQ_OCT_B[ pnl ] = 95
  end
  if ( value == 8 ) then
    PHT_SEQ_OCT_A[ pnl ] = 96
    PHT_SEQ_OCT_B[ pnl ] = 107
  end
  if ( value == 9 ) then
    PHT_SEQ_OCT_A[ pnl ] = 108
    PHT_SEQ_OCT_B[ pnl ] = 119
  end
  if ( value == 10 ) then
    PHT_SEQ_OCT_A[ pnl ] = 0
    PHT_SEQ_OCT_B[ pnl ] = 119
  end
  --print(PHT_SEQ_OCT_A[ pnl ])
  --print(PHT_SEQ_OCT_B[ pnl ])
end
---
function pht_seq_change_oct_all( value )
  for pnl = 1, 32 do
    vws["PHT_SEQ_OCT_"..pnl].value = value
  end
end
---
class "Pht_Seq_Oct"
function Pht_Seq_Oct:__init( pnl )
  self.cnt = vb:row { margin = 1,
    vb:row { style = "plain",
      vb:valuefield {
        id = "PHT_SEQ_OCT_"..pnl,
        height = 18,
        width = 46,
        min = 0,
        max = 10,
        value = 10,
        align = "center",
        tostring = function( value ) if ( value <= 9 ) then return ("Oct %1d"):format( value ) else return ("All"):format( value ) end end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) pht_seq_change_oct( value, pnl ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:"..("Octave Step %.2d Valuefield"):format( pnl ),
        tooltip = ("Change the octaves for step %.2d\n[ Octaves: 0 to 9. Insert 10 to\"All\" the octaves (120 notes) ]"):format( pnl )
      }
    }
  }
end
---
function pht_seq_vbx_oct_x16()
  local valuebox = vb:row { spacing = 2 }
  for pnl = 1, 16 do
    valuebox:add_child (
      Pht_Seq_Oct( pnl ).cnt
    )
  end
  return valuebox
end
---
function pht_seq_vbx_oct_x32()
  local valuebox = vb:row { spacing = 2 }
  for pnl = 17, 32 do
    valuebox:add_child (
      Pht_Seq_Oct( pnl ).cnt
    )
  end
  return valuebox
end


------------------------------------------------------------------------------------------------
--step time valuefield and mark button
class "Pht_Seq_Step_Time"
function Pht_Seq_Step_Time:__init( step )
  self.cnt = vb:row { margin = 1,
    vb:row { style = "plain",
      vb:valuefield {
        id = "PHT_SEQ_VFD_STEP_TIMER_"..step,
        height = 18,
        width = 46,
        align = "center",
        min = 0,
        max = 9999, --10 seconds
        value = 200,
        tostring = function( value ) return ("%2d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:"..("Step Time %.2d Valuefield"):format( step ),
        tooltip = "Step time (Play + Wait). Change the value in miliseconds\nInsert \"Wait = 0\" to jump to the first step\n[ Range: 0 to 9999 ms ]"
      }
    }
  }
end
---
class "Pht_Seq_Mark"
function Pht_Seq_Mark:__init( mark )
  self.cnt = vb:button {
    id = "PHT_SEQ_BT_MARK_"..mark,
    height = 11,
    width = 48,
    color = PHT_MAIN_COLOR.GOLD_OFF1,
    notifier = function() pht_seq_vfd_zero ( mark ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Marker:"..( "Step Marker %.2d Checkbox" ):format( mark ),
    tooltip = ("Step marker %.2d\n(the total time of the step = Play + Wait (ms))\nPress to change \"Wait = 0\" or return to initial value"):format( mark )
  }
end
---
function pht_seq_vfd_step_time_x16()
  local valuefield_01_16 = vb:row { spacing = 2 }
  local valuefield_17_32 = vb:row { spacing = 2 }
  local marked = vb:row { spacing = 2 }
  for step = 1, 16 do
    valuefield_01_16:add_child (
      Pht_Seq_Step_Time( step ).cnt
    )
  end
  for step = 17, 32 do
    valuefield_17_32:add_child (
      Pht_Seq_Step_Time( step ).cnt
    )
    vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value = 100
  end
  for mark = 1, 16 do
    marked:add_child (
      Pht_Seq_Mark( mark ).cnt
    )
  end
  local vfd = vb:column {
    valuefield_01_16,
    valuefield_17_32,
    marked
  }
  return vfd
end
---
function pht_seq_vfd_step_time_x32()
  local valuefield_33_48 = vb:row { spacing = 2 }
  local valuefield_49_64 = vb:row { spacing = 2 }
  local marked = vb:row { spacing = 2 }
  for step = 33, 48 do
    valuefield_33_48:add_child (
      Pht_Seq_Step_Time( step ).cnt
    )
  end
  for step = 49, 64 do
    valuefield_49_64:add_child (
      Pht_Seq_Step_Time( step ).cnt
    )
    vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value = 100
  end
  for mark = 17, 32 do
    marked:add_child (
      Pht_Seq_Mark( mark ).cnt
    )
  end
  local vfd = vb:column {
    valuefield_33_48,
    valuefield_49_64,
    marked
  }
  return vfd
end



--mark panel sequence
function pht_seq_sel_mark( mark )
  for i = 1, 33 do
    if ( mark ==  i ) then
      vws["PHT_SEQ_BT_MARK_"..i].color = PHT_MAIN_COLOR.GOLD_ON
    else
      vws["PHT_SEQ_BT_MARK_"..i].color = PHT_MAIN_COLOR.GOLD_OFF1
    end
  end
end


PHT_SEQ_VFD_ZERO = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     --16
                     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } --33
function pht_seq_vfd_zero ( mark )
  if ( mark < 17 ) then
    if ( vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].value > vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].min ) then
      PHT_SEQ_VFD_ZERO[mark] = vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].value
      vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].value = vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].min
    else
      vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 16].value = PHT_SEQ_VFD_ZERO[mark]
    end
  else
    if ( vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].value > vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].min ) then
      PHT_SEQ_VFD_ZERO[mark] = vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].value
      vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].value = vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].min
    else
      vws["PHT_SEQ_VFD_STEP_TIMER_"..mark + 32].value = PHT_SEQ_VFD_ZERO[mark]
    end
  end
end



------------------------------------------------------------------------------------------------
--block 1
function pht_seq_skip_even()
  for i = 1, 32 do
    if ( i % 2 ~= 0 ) then
      PHT_SEQ_ON_OFF_PNL[i] = false
    else
      PHT_SEQ_ON_OFF_PNL[i] = true
    end
    pht_seq_on_off_pnl( i )
  end
end
---
function pht_seq_skip_old()
  for i = 1, 32 do
    if ( i % 2 == 0 ) then
      PHT_SEQ_ON_OFF_PNL[i] = false
    else
      PHT_SEQ_ON_OFF_PNL[i] = true
    end
    pht_seq_on_off_pnl( i )
  end
end
---
PHT_SEQ_BLOCK_X1 = vb:column {
  vb:row { spacing = -3,
    vb:button {
      height = 11,
      width = 27,
      color = PHT_MAIN_COLOR.GREY_OFF,
      notifier = function() pht_seq_skip_even() end,
      midi_mapping = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip Even Steps Checkbox",
      tooltip = "Skip the even steps (2,4,6...)"
    },
    vb:button {
      height = 11,
      width = 27,
      color = PHT_MAIN_COLOR.GREY_OFF,
      notifier = function() pht_seq_skip_old() end,
      midi_mapping = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip Old Steps Checkbox",
      tooltip = "Skip the odd steps (1,3,5...)"
    }
  },
  vb:valuebox {
    id = "PHT_SEQ_VBX_SEL_PNL_0",
    height = 21,
    width = 51,
    min = 1,
    max = 16,
    value = 1,
    notifier = function( value ) for i = 1, 32 do vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = value end end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:General Panels Valuebox",
    tooltip = "General distribution of the panels of notes\n[ Panel of notes: 1 to 16 ]"
  },
  vb:valuebox {
    id = "PHT_SEQ_OCT_ALL",
    height = 20,
    width = 51,
    min = 0,
    max = 10,
    value = 10,
    tostring = function( value ) if ( value <= 9 ) then return ("%2d"):format( value ) else return ("All"):format( value ) end end,
    tonumber = function( value ) return tonumber( value ) end,
    notifier = function( value ) pht_seq_change_oct_all( value ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:General Octaves Valuebox",
    tooltip = "General change of the octaves for all steps\n[ Octaves: 0 to 9. Select \"All\" for all the octaves (120 notes) ]"
  },
  vb:text {
    height = 19,
    width = 51,
    align = "center",
    text = "Play (ms)"
  },
  vb:text {
    height = 18,
    width = 51,
    align = "center",
    text = "Wait (ms)"
  },
  vb:column { spacing = -5,
    vb:space { width = 51 },
    vb:text {
      height = 18,
      width = 51,
      align = "center",
      text = "Steps"
    }
  }
}



------------------------------------------------------------------------------------------------
--block 2
PHT_SEQ_BLOCK_X2 = vb:column {
  pht_seq_bt_on_off_pnl_x16(),
  pht_seq_vbx_sel_pnl_x16(),
  pht_seq_vbx_oct_x16(),
  pht_seq_vfd_step_time_x16()
}



------------------------------------------------------------------------------------------------
--block 3
PHT_SEQ_BLOCK_X3 = vb:column {
  pht_seq_bt_on_off_pnl_x32(),
  pht_seq_vbx_sel_pnl_x32(),
  pht_seq_vbx_oct_x32(),
  pht_seq_vfd_step_time_x32()
}



------------------------------------------------------------------------------------------------
--block 4
function pht_seq_skip_all()
  for i = 1, 32 do
    PHT_SEQ_ON_OFF_PNL[i] = true
    pht_seq_on_off_pnl( i )
  end
end
---
function pht_seq_skip_any()
  for i = 1, 32 do
    PHT_SEQ_ON_OFF_PNL[i] = false
    pht_seq_on_off_pnl( i )
  end
end
---
function pht_seq_oct_0_9()
  for pnl = 1, 10 do  vws["PHT_SEQ_OCT_"..pnl].value = pnl -1 end
  for pnl = 11, 16 do vws["PHT_SEQ_OCT_"..pnl].value = 10 end
end
---
function pht_seq_oct_9_0()
  for pnl = 10, 1, -1 do vws["PHT_SEQ_OCT_"..pnl].value = 10 -pnl end
  for pnl = 11, 16 do    vws["PHT_SEQ_OCT_"..pnl].value = 10 end
end
---
function pht_seq_oct_0_3()
  for pnl = 1, 4  do vws["PHT_SEQ_OCT_"..pnl].value = pnl -1 end
  for pnl = 5, 8  do vws["PHT_SEQ_OCT_"..pnl].value = pnl -5 end
  for pnl = 9, 12 do vws["PHT_SEQ_OCT_"..pnl].value = pnl -9 end
  for pnl = 13,16 do vws["PHT_SEQ_OCT_"..pnl].value = pnl -13 end
end
---
function pht_seq_oct_4_7()
  for pnl = 1, 4  do vws["PHT_SEQ_OCT_"..pnl].value = pnl +3 end
  for pnl = 5, 8  do vws["PHT_SEQ_OCT_"..pnl].value = pnl -1 end
  for pnl = 9, 12 do vws["PHT_SEQ_OCT_"..pnl].value = pnl -5 end
  for pnl = 13,16 do vws["PHT_SEQ_OCT_"..pnl].value = pnl -9 end
end
---
PHT_SEQ_BLOCK_X4 = vb:column {
  vb:row { spacing = -3,
    vb:button {
      height = 11,
      width = 27,
      color = PHT_MAIN_COLOR.GREY_OFF,
      notifier = function() pht_seq_skip_all() end,
      midi_mapping = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip All Steps Checkbox",
      tooltip = "Skip all the steps"
    },
    vb:button {
      height = 11,
      width = 27,
      color = PHT_MAIN_COLOR.GREY_OFF,
      notifier = function() pht_seq_skip_any() end,
      midi_mapping = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Not Skip Any Step Checkbox",
      tooltip = "No skip any step toplay"
    }
  },
  vb:button {
    height = 21,
    width = 51,
    text = "Reset",
    notifier = function() pht_seq_reset() end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Main Controls:Reset All Button",
    tooltip = "Reset general configuration of the Step Sequencer"
  },
  vb:column { spacing = -2,
    vb:row { spacing = -3,
      vb:button {
        height = 11,
        width = 27,
        notifier = function() pht_seq_oct_0_9() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 0 to 9 Button",
        tooltip = "Distribute octaves 0 to 9 (increasing)"
      },
      vb:button {
        height = 11,
        width = 27,
        notifier = function() pht_seq_oct_9_0() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 9 to 0 Button",
        tooltip = "Distribute octaves 9 to 0 (decreasing)"
      }
    },
    vb:row { spacing = -3,
      vb:button {
        height = 11,
        width = 27,
        notifier = function() pht_seq_oct_0_3() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 0-1-2-3 Button",
        tooltip = "Distribute octaves 0-1-2-3 & repeat this range"
      },
      vb:button {
        height = 11,
        width = 27,
        notifier = function() pht_seq_oct_4_7() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 4-5-6-7 Button",
        tooltip = "Distribute octaves 4-5-6-7 & repeat this range"
      }
    }
  },
  vb:row { margin = 1,
    vb:column { style = "plain",
      vb:bitmap {
        height = 19,
        width = 49,
        bitmap = "./ico/mini_return_ico.png",
        mode = "main_color",
        tooltip = "Bridge wait for first step"
      },
      vb:valuefield {
        id = "PHT_SEQ_VFD_STEP_TIMER_65",
        height = 19,
        width = 49,
        align = "center",
        min = 1,
        max = 9999, --10 seconds
        value = 100,
        tostring = function( value ) return ("%2d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Bridge Time Valuefield",
        tooltip = "Change the \"bridge wait\" in miliseconds\nInsert \"Wait = 1\" in any step to jump to the first step\n[ Range: 1 to 9999 ms ]"
      }
    }
  },
  vb:button {
    id = "PHT_SEQ_BT_MARK_33",
    height = 11,
    width = 51,
    color = PHT_MAIN_COLOR.GOLD_OFF1,
    notifier = function() pht_seq_vfd_zero ( 33 ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Marker:Bridge Marker Checkbox",
    tooltip = "Bridge marker\nPress to change \"Wait = 1\" or return to initial value"
  }
}



------------------------------------------------------------------------------------------------
--control play
PHT_SEQ_CTRL = vb:row { spacing = -3,
  vb:button {
    id = "PHT_SEQ_BT_PLAY_STOP",
    height = 27,
    width = 34,
    bitmap = "./ico/play_ico.png",
    pressed = function() pht_seq_play() end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Main Controls:Play or Replay Button",
    tooltip = "Play/return Step Sequencer\n[Return]  [Ctrl + Return]\n\n"..
              "[Ctrl + Space]  [Alt + Space] both to synchronize the reproduction of the pattern with the Step Sequencer"
  },
  vb:button {
    id = "PHT_SEQ_BT_STOP",
    height = 27,
    width = 34,
    bitmap = "./ico/stop_ico.png",
    pressed = function() pht_seq_stop() end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Main Controls:Stop Button",
    tooltip = "Stop Step Sequencer\n[Return]  [Ctrl + Return]\n\n"..
              "[Ctrl + Space]  [Alt + Space] both to synchronize the reproduction of the pattern with the Step Sequencer"
  },
  vb:button {
    id = "PHT_SEQ_BT_EDIT_MODE",
    height = 27,
    width = 34,
    bitmap = "./ico/rec_on_ico.png",
    pressed = function() pht_edit_mode() end,
    midi_mapping = "Tools:PhraseTouch:Main Controls:Edit Mode Button",
    tooltip = PHT_EDIT_MODE_TOOLTIP
  },
  vb:space { width = 5 },
  vb:button {
    height = 27,
    width = 34,
    bitmap = "./ico/phr_ico.png",
    notifier = function() show_tool_dialog() end,
    midi_mapping = "Tools:PhraseTouch:FavTouch:Show PhraseTouch Window Button",
    tooltip = "Show PhraseTouch window...[Ctrl + Alt + P, assignable by the user!]"
  }
}



------------------------------------------------------------------------------------------------
--distribution section
function pht_seq_distrib( dis )
  if ( dis == 1 ) then
    local tb_x4 = { 1, 5, 9, 13, 17, 21, 25, 29,   2, 6, 10, 14, 18, 22, 26, 30,   3, 7, 11, 15, 19, 23, 27, 31,   4, 8, 12, 16, 20, 24, 28, 32  }
    for i = 1, 32 do
      if ( i <= 8 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 1
      end
      if ( i > 8 ) and ( i < 17 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 5
      end
      if ( i >= 17 ) and ( i < 25 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 9
      end
      if ( i >= 25 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 13
      end
    end
  end
  ---
  if ( dis == 2 ) then
    for i = 1, 32 do
      if ( i % 2 ~= 0 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = 1
      else
        vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = 2
      end
    end
  end
  ---
  if ( dis == 3 ) then
    local tb_x3 = { 1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31,   2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32,   3, 6, 9, 12, 15, 18, 21, 24, 27, 30 }
    for i = 1, 32 do
      if ( i <= 11 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x3[i]].value = 1
      end
      if ( i > 11 ) and ( i < 23 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x3[i]].value = 2
      end
      if ( i >= 23 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x3[i]].value = 3
      end
      vws.PHT_SEQ_VBX_SEL_PNL_31.value = 0
      vws.PHT_SEQ_VBX_SEL_PNL_32.value = 0      
    end
  end
  ---
  if ( dis == 4 ) then
    local tb_x4 = { 1, 5, 9, 13, 17, 21, 25, 29,   2, 6, 10, 14, 18, 22, 26, 30,   3, 7, 11, 15, 19, 23, 27, 31,   4, 8, 12, 16, 20, 24, 28, 32  }
    for i = 1, 32 do
      if ( i <= 8 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 1
      end
      if ( i > 8 ) and ( i < 17 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 2
      end
      if ( i >= 17 ) and ( i < 25 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 3
      end
      if ( i >= 25 ) then
        vws["PHT_SEQ_VBX_SEL_PNL_"..tb_x4[i]].value = 4
      end
    end
  end
  ---
  if ( dis == 5 ) then
    for i = 1, 5 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i
    end
    for i = 6, 10 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 5
    end
    for i = 11, 15 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 10
    end
    ---
    for i = 16, 20 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 15
    end
    for i = 21, 25 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 20
    end
    for i = 26, 30 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 25
    end
    vws.PHT_SEQ_VBX_SEL_PNL_31.value = 0
    vws.PHT_SEQ_VBX_SEL_PNL_32.value = 0
  end
  ---
  if ( dis == 8 ) then
    for i = 1, 8 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i
    end
    for i = 9, 16 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 8
    end
    ---
    for i = 17, 24 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 16
    end
    for i = 25, 32 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 24
    end
  end
  ---
  if ( dis == 16 ) then
    for i = 1, 16 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i
    end
    for i = 17, 32 do
      vws["PHT_SEQ_VBX_SEL_PNL_"..i].value = i - 16
    end
  end
end
---
PHT_SEQ_DST_PNL = vb:row { margin = 1,
  vb:row { style = "panel", margin = 3, spacing = 3,
    vb:text {
      height = 19,
      width = 23,
      text = "DTR",
      align = "right"
    },
    vb:row { spacing = -3,
      vb:button {
        height = 19,
        width = 29,
        text = "1...",
        notifier = function() pht_seq_distrib( 1 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1-5-9-13 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-5-9-13 & repeat"
      },
      vb:button {
        height = 19,
        width = 25,
        text = "2",
        notifier = function() pht_seq_distrib( 2 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1-2 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-2 & repeat"
      },
      vb:button {
        height = 19,
        width = 25,
        text = "3",
        notifier = function() pht_seq_distrib( 3 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 3 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-2-3 & repeat"
      },
      vb:button {
        height = 19,
        width = 25,
        text = "4",
        notifier = function() pht_seq_distrib( 4 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 4 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-2-3-4 & repeat"
      },
      vb:button {
        height = 19,
        width = 25,
        text = "5",
        notifier = function() pht_seq_distrib( 5 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 5 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-2-3-4-5 & repeat"
      },
      vb:button {
        height = 19,
        width = 25,
        text = "8",
        notifier = function() pht_seq_distrib( 8 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 8 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1-2-3-4-5-6-7-8 & repeat"
      },
      vb:button {
        height = 19,
        width = 29,
        text = "16",
        notifier = function() pht_seq_distrib( 16 ) end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 16 & Repeat Button",
        tooltip = "Distribute the panels of notes in 1 to 16 & repeat"
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--random section
function pht_seq_random( val_1, val_2, rdm_1, rdm_2 )
  for i = val_1, val_2 do
    vws["PHT_SEQ_VFD_STEP_TIMER_"..i].value = math.random( rdm_1, rdm_2 )
  end
end
---
function pht_seq_random_play()
  pht_seq_random(  1, 16, vws.PHT_SEQ_RDM_VAL_1.value, vws.PHT_SEQ_RDM_VAL_2.value )
  pht_seq_random( 33, 48, vws.PHT_SEQ_RDM_VAL_1.value, vws.PHT_SEQ_RDM_VAL_2.value )
end
---
function pht_seq_random_wait()
  pht_seq_random( 17, 32, vws.PHT_SEQ_RDM_VAL_3.value, vws.PHT_SEQ_RDM_VAL_4.value )
  pht_seq_random( 49, 65, vws.PHT_SEQ_RDM_VAL_3.value, vws.PHT_SEQ_RDM_VAL_4.value )
end
---
function pht_seq_rdm_val_1()
  if ( vws.PHT_SEQ_RDM_VAL_2.value < vws.PHT_SEQ_RDM_VAL_1.value ) then
    vws.PHT_SEQ_RDM_VAL_2.value = vws.PHT_SEQ_RDM_VAL_1.value
  end
end
---
function pht_seq_rdm_val_2()
  if ( vws.PHT_SEQ_RDM_VAL_1.value > vws.PHT_SEQ_RDM_VAL_2.value ) then
    vws.PHT_SEQ_RDM_VAL_1.value = vws.PHT_SEQ_RDM_VAL_2.value
  end
end
---
function pht_seq_rdm_val_3()
  if ( vws.PHT_SEQ_RDM_VAL_4.value < vws.PHT_SEQ_RDM_VAL_3.value ) then
    vws.PHT_SEQ_RDM_VAL_4.value = vws.PHT_SEQ_RDM_VAL_3.value
  end
end
---
function pht_seq_rdm_val_4()
  if ( vws.PHT_SEQ_RDM_VAL_3.value > vws.PHT_SEQ_RDM_VAL_4.value ) then
    vws.PHT_SEQ_RDM_VAL_3.value = vws.PHT_SEQ_RDM_VAL_4.value
  end

end
---
PHT_SEQ_RDM_PNL = vb:row { margin = 1,
  vb:row { style = "panel", margin = 3, --spacing = 3,
    vb:text {
      height = 19,
      width = 25,
      text = "RDM",
      align = "right"
    },
    vb:row { spacing = -3,
      vb:button {
        height = 19,
        width = 25,
        text = "P",
        notifier = function() pht_seq_random_play() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Button",
        tooltip = "Apply random to \"Play\" time\n[ Range: 10 to 9999 ms ]"
      },
      vb:row { spacing = -118,
        vb:button {
          active = false,
          height = 19,
          width = 119,
        },
        vb:row { margin = 2,
          vb:row { margin = -2,
            vb:valuebox {
              id = "PHT_SEQ_RDM_VAL_1",
              height = 19,
              width = 61,
              min = 10,
              max = 9999,
              value = 100,
              notifier = function() pht_seq_rdm_val_1() end,
              midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Min Valuebox",
              tooltip = "Minimum random to \"Play\" time\n[ Range: 10 to 9999 ms ]"
            }
          },
          vb:row { margin = -2,
            vb:valuebox {
              id = "PHT_SEQ_RDM_VAL_2",
              height = 19,
              width = 61,
              min = 10,
              max = 9999,
              value = 300,
              notifier = function() pht_seq_rdm_val_2() end,
              midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Max Valuebox",
              tooltip = "Maximum random to \"Play\" time\n[ Range: 10 to 9999 ms ]"
              
            }
          }
        }
      }
    },
    vb:space { width = 3 },
    vb:row { spacing = -3,
      vb:button {
        height = 19,
        width = 25,
        text = "W",
        notifier = function() pht_seq_random_wait() end,
        midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Button",
        tooltip = "Apply random to \"Wait\" time\n[ Range: 10 to 9999 ms ]"
      },
      vb:row { spacing = -118,
        vb:button {
          active = false,
          height = 19,
          width = 119,
        },
        vb:row { margin = 2,
          vb:row { margin = -2,
            vb:valuebox {
              id = "PHT_SEQ_RDM_VAL_3",
              height = 19,
              width = 61,
              min = 10,
              max = 9999,
              value = 50,
              notifier = function() pht_seq_rdm_val_3() end,
              midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Min Valuebox",
              tooltip = "Minimum random to \"Wait\" time\n[ Range: 10 to 9999 ms ]"
            }
          },
          vb:row { margin = -2,
            vb:valuebox {
              id = "PHT_SEQ_RDM_VAL_4",
              height = 19,
              width = 61,
              min = 10,
              max = 9999,
              value = 150,
              notifier = function() pht_seq_rdm_val_4() end,
              midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Max Valuebox",
              tooltip = "Maximum random to \"Wait\" time\n[ Range: 10 to 9999 ms ]"
            }
          }
        }
      }
    }
  }
}



------------------------------------------------------------------------------------------------
--time calculator
function pht_seq_time_calculator()
  local val = ( vws.PHT_SEC_TIME_CAL_BPM.value * vws.PHT_SEC_TIME_CAL_LPB.value ) / 60
  local lns = vws.PHT_SEC_TIME_CAL_LNS.value * 1000 / val
  vws.PHT_SEC_TIME_CAL_TF.value = lns
end
---
PHT_SEC_TIME_CAL = vb:row { margin = 1,
  visible = false,
  vb:row { style = "panel", margin = 3,
    vb:text {
      height = 19,
      width = 28,
      align = "right",
      text = "BPM"
    },
    vb:valuebox {
      id = "PHT_SEC_TIME_CAL_BPM",
      height = 19,
      width = 54,
      min = 32,
      max = 999,
      value = 150,
      notifier = function() pht_seq_time_calculator() end,
      tooltip = "Beats Per Minute\n[ Range: 32 to 999 ]"
    },
    vb:text {
      height = 19,
      width = 28,
      align = "right",
      text = "LPB"
    },  
    vb:valuebox {
      id = "PHT_SEC_TIME_CAL_LPB",
      height = 19,
      width = 54,
      min = 1,
      max = 256,
      value = 4,
      tostring = function( value ) return ("%2d"):format( value ) end,
      tonumber = function( value ) return tonumber( value ) end,
      notifier = function() pht_seq_time_calculator() end,
      tooltip = "Lines Per Beat\n[ Range: 1 to 256 ]"
    },
    vb:text {
      height = 19,
      width = 29,
      align = "right",
      text = "LNS"
    },  
    vb:valuebox {
      id = "PHT_SEC_TIME_CAL_LNS",
      height = 19,
      width = 49,
      min = 1,
      max = 99,
      value = 1,
      tostring = function( value ) return ("%2d"):format( value ) end,
      tonumber = function( value ) return tonumber( value ) end,
      notifier = function() pht_seq_time_calculator() end,
      tooltip = "Lines for time\n[ Range: 1 to 99 ]"
    },
    vb:space { width = 5 },
    vb:row { margin = 1,
      vb:row { style = "plain",
        vb:valuefield {
        id = "PHT_SEC_TIME_CAL_TF",
        active = false,
        height = 17,
        width = 64,
        min = 0,
        max = 999999,
        value = 100, --("%.2f"):format(100)
        tostring = function( value ) return (" %.2f ms"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        tooltip = "Total Time in miliseconds (ms) according to lines\nAdjust manually the \"Play + Wait\" time for each step to approximately match with this \"Total Time\". "..
                  "This will approximately synchronize the playback of the pattern with the Step Sequencer for live recording. "..
                  "Each step has two timers. Each timer can carry an error of approximately up to ±5 ms when the speed is very fast, less than 20 ms.\n"..
                  "[ Step = \"Play + Wait\" = \"Total Time\" ]\n\n"..
                  "In Renoise, use the \"quantization amount\" = 1 to fit the notes in each line without delays..."
                  
        }
      }
    }
  }
}
---
PHT_SEC_RDM_TME_STATE = false
function pht_sec_rdm_tme()
  if ( PHT_SEC_RDM_TME_STATE == false ) then
    PHT_SEC_RDM_TME_STATE = true
    PHT_SEQ_RDM_PNL.visible = false
    PHT_SEC_TIME_CAL.visible = true
    vws.PHT_SEC_RDM_TME.color = PHT_MAIN_COLOR.GOLD_ON
  else
    PHT_SEC_RDM_TME_STATE = false
    PHT_SEC_TIME_CAL.visible = false
    PHT_SEQ_RDM_PNL.visible = true
    vws.PHT_SEC_RDM_TME.color = PHT_MAIN_COLOR.DEFAULT
  end
end
---
PHT_SEC_RDM_TME = vb:row { spacing = -1,

  vb:button {
    id = "PHT_SEC_RDM_TME",
    height = 27,
    width = 27,
    bitmap = "./ico/chrono_ico.png", --hourglass_ico.png",
    notifier = function() pht_sec_rdm_tme() end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Time Calculator Checkbox",
    tooltip = "Steps Random Time or Time Calculator control selector\nChange between Steps Random Time or Time Calculator"
  },
  vb:column {
    PHT_SEQ_RDM_PNL,
    PHT_SEC_TIME_CAL
  }
}



------------------------------------------------------------------------------------------------
--up/down play & wait
local pht_seq_up_down_ms_bol
function pht_seq_up_down_ms()
  if ( pht_seq_up_down_ms_bol == true ) then
    for step = 1, 65 do
      local val = vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value
      if ( val + 1 <= 9999 ) and ( val > 0 ) then
        vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value = val + 1
      end
    end
  else
    for step = 1, 65 do
      local val = vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value
      if ( val - 1 >= 20 ) then --limit == 20 ms
        vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value = val - 1
      end
    end
  end
end
---
function pht_seq_up_down_ms_repeat( release )
  if not release then
    if rnt:has_timer( pht_seq_up_down_ms_repeat ) then
      pht_seq_up_down_ms()
      rnt:remove_timer( pht_seq_up_down_ms_repeat )
      if not rnt:has_timer( pht_seq_up_down_ms ) then
        rnt:add_timer( pht_seq_up_down_ms, 15 )
      end
    else
      pht_seq_up_down_ms()
      if not rnt:has_timer( pht_seq_up_down_ms_repeat ) then
        rnt:add_timer( pht_seq_up_down_ms_repeat, 300 )
      end
    end
  else
    if rnt:has_timer( pht_seq_up_down_ms_repeat ) then
      rnt:remove_timer( pht_seq_up_down_ms_repeat )
    elseif rnt:has_timer( pht_seq_up_down_ms ) then
      rnt:remove_timer( pht_seq_up_down_ms )
    end
  end
end
---
function pht_seq_up_down( bol )
  if ( pht_seq_up_down_ms_bol ~= bol ) then
    pht_seq_up_down_ms_bol = bol
  end
  pht_seq_up_down_ms_repeat()
end
---
PHT_SEQ_UP_DOWN_MS = vb:column { spacing = -3,
  vb:button {
    height = 15,
    width = 27,
    bitmap = "./ico/up_ico.png",
    pressed = function() pht_seq_up_down( true ) end,
    released = function() pht_seq_up_down_ms_repeat( true ) end,
    --notifier = function() pht_seq_up_down_ms( true ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Decelerate All Times Button",
    tooltip = "Decelerate Steps Sequencer\nIncrease together the time of \"Play + Wait\" for each step"
  },
  vb:button {
    height = 15,
    width = 27,
    bitmap = "./ico/down_ico.png",
    pressed = function() pht_seq_up_down( false ) end,
    released = function() pht_seq_up_down_ms_repeat( true ) end,
    --notifier = function() pht_seq_up_down_ms( false ) end,
    midi_mapping = "Tools:PhraseTouch:Step Sequencer:Step Times:Accelerate All Times Button",
    tooltip = "Accelerate Steps Sequencer\nDecrease together the time of \"Play + Wait\" for each step"
  }
}



--logo
PHT_SEQ_LOGO_CMP = vb:horizontal_aligner {
  width = 100,
  mode = "right",
  visible = true,
  vb:bitmap {
    height = 27,
    width = 80,
    mode = "body_color",
    bitmap = "./ico/step_sequencer_compact_ico.png",
  }
}
---
PHT_SEQ_LOGO = vb:horizontal_aligner {
  width = 154,
  mode = "right",
  visible = true,
  vb:bitmap {
    height = 27,
    width = 149,
    mode = "body_color",
    bitmap = "./ico/step_sequencer_ico.png",
  }
}


------------------------------------------------------------------------------------------------
--steps all panel
PHT_SEQ_MASTER = {
  pht_master_1,
  pht_master_2,
  pht_master_3,
  pht_master_4,
  pht_master_5,
  pht_master_6,
  pht_master_7,
  pht_master_8,
  pht_master_9,
  pht_master_10,
  pht_master_11,
  pht_master_12,
  pht_master_13,
  pht_master_14,
  pht_master_15,
  pht_master_16
}



--64
function pht_seq_step_pnl_64()
  rnt:remove_timer( pht_seq_step_pnl_64 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_32.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_32.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[32], PHT_SEQ_OCT_B[32] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_64.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 1, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 64")
end
--63
function pht_seq_step_pnl_63()
  if rnt:has_timer( pht_seq_step_pnl_63 ) then
    rnt:remove_timer( pht_seq_step_pnl_63 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_32.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_32.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[32], PHT_SEQ_OCT_B[32] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_48.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_64, time )
    pht_seq_sel_mark( 32 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 63")
end



--62
function pht_seq_step_pnl_62()
  rnt:remove_timer( pht_seq_step_pnl_62 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_31.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_31.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[31], PHT_SEQ_OCT_B[31] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_63.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 32, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 62")
end
--61
function pht_seq_step_pnl_61()
  if rnt:has_timer( pht_seq_step_pnl_61 ) then
    rnt:remove_timer( pht_seq_step_pnl_61 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_31.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_31.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[31], PHT_SEQ_OCT_B[31] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_47.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_62, time )
    pht_seq_sel_mark( 31 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 61")
end



--60
function pht_seq_step_pnl_60()
  rnt:remove_timer( pht_seq_step_pnl_60 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_30.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_30.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[30], PHT_SEQ_OCT_B[30] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_62.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 31, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 60")
end
--59
function pht_seq_step_pnl_59()
  if rnt:has_timer( pht_seq_step_pnl_59 ) then
    rnt:remove_timer( pht_seq_step_pnl_59 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_30.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_30.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[30], PHT_SEQ_OCT_B[30] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_46.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_60, time )
    pht_seq_sel_mark( 30 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 59")
end



--58
function pht_seq_step_pnl_58()
  rnt:remove_timer( pht_seq_step_pnl_58 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_29.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_29.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[29], PHT_SEQ_OCT_B[29] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_61.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 30, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 58")
end
--57
function pht_seq_step_pnl_57()
  if rnt:has_timer( pht_seq_step_pnl_57 ) then
    rnt:remove_timer( pht_seq_step_pnl_57 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_29.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_29.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[29], PHT_SEQ_OCT_B[29] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_45.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_58, time )
    pht_seq_sel_mark( 29 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 57")
end



--56
function pht_seq_step_pnl_56()
  rnt:remove_timer( pht_seq_step_pnl_56 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_28.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_28.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[28], PHT_SEQ_OCT_B[28] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_60.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 29, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 56")
end
--55
function pht_seq_step_pnl_55()
  if rnt:has_timer( pht_seq_step_pnl_55 ) then
    rnt:remove_timer( pht_seq_step_pnl_55 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_28.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_28.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[28], PHT_SEQ_OCT_B[28] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_44.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_56, time )
    pht_seq_sel_mark( 28 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 55")
end



--54
function pht_seq_step_pnl_54()
  rnt:remove_timer( pht_seq_step_pnl_54 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_27.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_27.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[27], PHT_SEQ_OCT_B[27] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_59.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 28, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 54")
end
--53
function pht_seq_step_pnl_53()
  if rnt:has_timer( pht_seq_step_pnl_53 ) then
    rnt:remove_timer( pht_seq_step_pnl_53 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_27.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_27.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[27], PHT_SEQ_OCT_B[27] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_43.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_54, time )
    pht_seq_sel_mark( 27 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 53")
end



--52
function pht_seq_step_pnl_52()
  rnt:remove_timer( pht_seq_step_pnl_52 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_26.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_26.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[26], PHT_SEQ_OCT_B[26] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_58.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 27, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 52")
end
--51
function pht_seq_step_pnl_51()
  if rnt:has_timer( pht_seq_step_pnl_51 ) then
    rnt:remove_timer( pht_seq_step_pnl_51 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_26.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_26.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[26], PHT_SEQ_OCT_B[26] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_42.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_52, time )
    pht_seq_sel_mark( 26 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 51")
end



--50
function pht_seq_step_pnl_50()
  rnt:remove_timer( pht_seq_step_pnl_50 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_25.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_25.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[25], PHT_SEQ_OCT_B[25] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_57.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 26, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 50")
end
--49
function pht_seq_step_pnl_49()
  if rnt:has_timer( pht_seq_step_pnl_49 ) then
    rnt:remove_timer( pht_seq_step_pnl_49 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_25.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_25.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[25], PHT_SEQ_OCT_B[25] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_41.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_50, time )
    pht_seq_sel_mark( 25 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 49")
end



--48
function pht_seq_step_pnl_48()
  rnt:remove_timer( pht_seq_step_pnl_48 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_24.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_24.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[24], PHT_SEQ_OCT_B[24] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_56.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 25, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 48")
end
--47
function pht_seq_step_pnl_47()
  if rnt:has_timer( pht_seq_step_pnl_47 ) then
    rnt:remove_timer( pht_seq_step_pnl_47 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_24.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_24.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[24], PHT_SEQ_OCT_B[24] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_40.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_48, time )
    pht_seq_sel_mark( 24 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 47")
end



--46
function pht_seq_step_pnl_46()
  rnt:remove_timer( pht_seq_step_pnl_46 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_23.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_23.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[23], PHT_SEQ_OCT_B[23] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_55.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 24, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 46")
end
--45
function pht_seq_step_pnl_45()
  if rnt:has_timer( pht_seq_step_pnl_45 ) then
    rnt:remove_timer( pht_seq_step_pnl_45 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_23.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_23.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[23], PHT_SEQ_OCT_B[23] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_39.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_46, time )
    pht_seq_sel_mark( 23 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 45")
end



--44
function pht_seq_step_pnl_44()
  rnt:remove_timer( pht_seq_step_pnl_44 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_22.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_22.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[22], PHT_SEQ_OCT_B[22] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_54.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 23, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 44")
end
--43
function pht_seq_step_pnl_43()
  if rnt:has_timer( pht_seq_step_pnl_43 ) then
    rnt:remove_timer( pht_seq_step_pnl_43 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_22.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_22.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[22], PHT_SEQ_OCT_B[22] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_38.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_44, time )
    pht_seq_sel_mark( 22 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 43")
end



--42
function pht_seq_step_pnl_42()
  rnt:remove_timer( pht_seq_step_pnl_42 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_21.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_21.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[21], PHT_SEQ_OCT_B[21] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_53.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 22, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 42")
end
--41
function pht_seq_step_pnl_41()
  if rnt:has_timer( pht_seq_step_pnl_41 ) then
    rnt:remove_timer( pht_seq_step_pnl_41 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_21.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_21.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[21], PHT_SEQ_OCT_B[21] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_37.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_42, time )
    pht_seq_sel_mark( 21 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 41")
end



--40
function pht_seq_step_pnl_40()
  rnt:remove_timer( pht_seq_step_pnl_40 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_20.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_20.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[20], PHT_SEQ_OCT_B[20] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_52.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 21, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 40")
end
--39
function pht_seq_step_pnl_39()
  if rnt:has_timer( pht_seq_step_pnl_39 ) then
    rnt:remove_timer( pht_seq_step_pnl_39 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_20.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_20.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[20], PHT_SEQ_OCT_B[20] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_36.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_40, time )
    pht_seq_sel_mark( 20 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 39")
end



--38
function pht_seq_step_pnl_38()
  rnt:remove_timer( pht_seq_step_pnl_38 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_19.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_19.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[19], PHT_SEQ_OCT_B[19] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_51.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 20, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 38")
end
--37
function pht_seq_step_pnl_37()
  if rnt:has_timer( pht_seq_step_pnl_37 ) then
    rnt:remove_timer( pht_seq_step_pnl_37 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_19.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_19.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[19], PHT_SEQ_OCT_B[19] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_35.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_38, time )
    pht_seq_sel_mark( 19 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 37")
end



--36
function pht_seq_step_pnl_36()
  rnt:remove_timer( pht_seq_step_pnl_36 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_18.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_18.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[18], PHT_SEQ_OCT_B[18] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_50.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 19, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 36")
end
--35
function pht_seq_step_pnl_35()
  if rnt:has_timer( pht_seq_step_pnl_35 ) then
    rnt:remove_timer( pht_seq_step_pnl_35 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_18.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_18.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[18], PHT_SEQ_OCT_B[18] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_34.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_36, time )
    pht_seq_sel_mark( 18 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 35")
end



--34
function pht_seq_step_pnl_34()
  rnt:remove_timer( pht_seq_step_pnl_34 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_17.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_17.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[17], PHT_SEQ_OCT_B[17] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_49.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 18, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 34")
end
--33
function pht_seq_step_pnl_33()
  if rnt:has_timer( pht_seq_step_pnl_33 ) then
    rnt:remove_timer( pht_seq_step_pnl_33 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_17.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_17.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[17], PHT_SEQ_OCT_B[17] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_33.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_34, time )
    pht_seq_sel_mark( 17 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 33")
end

-------------------------------------------------------------------------------------------------

--32
function pht_seq_step_pnl_32()
  rnt:remove_timer( pht_seq_step_pnl_32 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_16.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_16.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[16], PHT_SEQ_OCT_B[16] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_32.value  --wait
  if ( time > 0 ) then
    if ( PHT_SEQ_CTRL_BKS == 1 ) then --x16 or x32
      pht_seq_skip_pnl( 1, time )
    else
      pht_seq_skip_pnl( 17, time )
    end
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 32")
end
--31
function pht_seq_step_pnl_31()
  if rnt:has_timer( pht_seq_step_pnl_31 ) then
    rnt:remove_timer( pht_seq_step_pnl_31 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_16.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_16.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[16], PHT_SEQ_OCT_B[16] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_16.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_32, time )
    pht_seq_sel_mark( 16 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 31")
end



--30
function pht_seq_step_pnl_30()
  rnt:remove_timer( pht_seq_step_pnl_30 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_15.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_15.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[15], PHT_SEQ_OCT_B[15] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_31.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 16, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 30")
end
--29
function pht_seq_step_pnl_29()
  if rnt:has_timer( pht_seq_step_pnl_29 ) then
    rnt:remove_timer( pht_seq_step_pnl_29 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_15.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_15.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[15], PHT_SEQ_OCT_B[15] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_15.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_30, time )
    pht_seq_sel_mark( 15 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 29")
end



--28
function pht_seq_step_pnl_28()
  rnt:remove_timer( pht_seq_step_pnl_28 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_14.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_14.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[14], PHT_SEQ_OCT_B[14] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_30.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 15, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 28")
end
--27
function pht_seq_step_pnl_27()
  if rnt:has_timer( pht_seq_step_pnl_27 ) then
    rnt:remove_timer( pht_seq_step_pnl_27 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_14.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_14.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[14], PHT_SEQ_OCT_B[14] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_14.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_28, time )
    pht_seq_sel_mark( 14 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 27")
end



--26
function pht_seq_step_pnl_26()
  rnt:remove_timer( pht_seq_step_pnl_26 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_13.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_13.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[13], PHT_SEQ_OCT_B[13] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_29.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 14, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 26")
end
--25
function pht_seq_step_pnl_25()
  if rnt:has_timer( pht_seq_step_pnl_25 ) then
    rnt:remove_timer( pht_seq_step_pnl_25 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_13.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_13.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[13], PHT_SEQ_OCT_B[13] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_13.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_26, time )
    pht_seq_sel_mark( 13 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 25")
end



--24
function pht_seq_step_pnl_24()
  rnt:remove_timer( pht_seq_step_pnl_24 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_12.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_12.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[12], PHT_SEQ_OCT_B[12] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_28.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 13, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 24")
end
--23
function pht_seq_step_pnl_23()
  if rnt:has_timer( pht_seq_step_pnl_23 ) then
    rnt:remove_timer( pht_seq_step_pnl_23 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_12.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_12.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[12], PHT_SEQ_OCT_B[12] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_12.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_24, time )
    pht_seq_sel_mark( 12 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 23")
end



--22
function pht_seq_step_pnl_22()
  rnt:remove_timer( pht_seq_step_pnl_22 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_11.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_11.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[11], PHT_SEQ_OCT_B[11] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_27.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 12, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 22")
end
--21
function pht_seq_step_pnl_21()
  if rnt:has_timer( pht_seq_step_pnl_21 ) then
    rnt:remove_timer( pht_seq_step_pnl_21 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_11.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_11.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[11], PHT_SEQ_OCT_B[11] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_11.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_22, time )
    pht_seq_sel_mark( 11 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 21")
end



--20
function pht_seq_step_pnl_20()
  rnt:remove_timer( pht_seq_step_pnl_20 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_10.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_10.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[10], PHT_SEQ_OCT_B[10] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_26.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 11, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 20")
end
--19
function pht_seq_step_pnl_19()
  if rnt:has_timer( pht_seq_step_pnl_19 ) then
    rnt:remove_timer( pht_seq_step_pnl_19 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_10.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_10.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[10], PHT_SEQ_OCT_B[10] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_10.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_20, time )
    pht_seq_sel_mark( 10 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 19")
end



--18
function pht_seq_step_pnl_18()
  rnt:remove_timer( pht_seq_step_pnl_18 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_9.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_9.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[9], PHT_SEQ_OCT_B[9] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_25.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 10, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 18")
end
--17
function pht_seq_step_pnl_17()
  if rnt:has_timer( pht_seq_step_pnl_17 ) then
    rnt:remove_timer( pht_seq_step_pnl_17 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_9.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_9.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[9], PHT_SEQ_OCT_B[9] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_9.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_18, time )
    pht_seq_sel_mark( 9 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 17")
end



--16
function pht_seq_step_pnl_16()
  rnt:remove_timer( pht_seq_step_pnl_16 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_8.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_8.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[8], PHT_SEQ_OCT_B[8] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_24.value --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 9, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 16")
end
--15
function pht_seq_step_pnl_15()
  if rnt:has_timer( pht_seq_step_pnl_15 ) then
    rnt:remove_timer( pht_seq_step_pnl_15 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_8.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_8.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[8], PHT_SEQ_OCT_B[8] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_8.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_16, time )
    pht_seq_sel_mark( 8 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 15")
end



--14
function pht_seq_step_pnl_14()
  rnt:remove_timer( pht_seq_step_pnl_14 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_7.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_7.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[7], PHT_SEQ_OCT_B[7] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_23.value --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 8, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 14")
end
--13
function pht_seq_step_pnl_13()
  if rnt:has_timer( pht_seq_step_pnl_13 ) then
    rnt:remove_timer( pht_seq_step_pnl_13 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_7.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_7.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[7], PHT_SEQ_OCT_B[7] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_7.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_14, time )
    pht_seq_sel_mark( 7 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 13")
end



--12
function pht_seq_step_pnl_12()
  rnt:remove_timer( pht_seq_step_pnl_12 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_6.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_6.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[6], PHT_SEQ_OCT_B[6] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_22.value --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 7, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 12")
end
--11
function pht_seq_step_pnl_11()
  if rnt:has_timer( pht_seq_step_pnl_11 ) then
    rnt:remove_timer( pht_seq_step_pnl_11 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_6.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_6.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[6], PHT_SEQ_OCT_B[6] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_6.value  --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_12, time )
    pht_seq_sel_mark( 6 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 11")
end



--10
function pht_seq_step_pnl_10()
  rnt:remove_timer( pht_seq_step_pnl_10 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_5.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_5.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[5], PHT_SEQ_OCT_B[5] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_21.value --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 6, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 10")
end
--09
function pht_seq_step_pnl_9()
  if rnt:has_timer( pht_seq_step_pnl_9 ) then
    rnt:remove_timer( pht_seq_step_pnl_9 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_5.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_5.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[5], PHT_SEQ_OCT_B[5] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_5.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_10, time )
    pht_seq_sel_mark( 5 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 9")
end



--08
function pht_seq_step_pnl_8()
  rnt:remove_timer( pht_seq_step_pnl_8 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_4.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_4.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[4], PHT_SEQ_OCT_B[4] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_20.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 5, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 8")
end
--07
function pht_seq_step_pnl_7()
  if rnt:has_timer( pht_seq_step_pnl_7 ) then
    rnt:remove_timer( pht_seq_step_pnl_7 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_4.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_4.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[4], PHT_SEQ_OCT_B[4] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_4.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_8, time )
    pht_seq_sel_mark( 4 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 7")
end



--06
function pht_seq_step_pnl_6()
  rnt:remove_timer( pht_seq_step_pnl_6 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_3.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_3.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[3], PHT_SEQ_OCT_B[3] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_19.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 4, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 6")
end
--05
function pht_seq_step_pnl_5()
  if rnt:has_timer( pht_seq_step_pnl_5 ) then
    rnt:remove_timer( pht_seq_step_pnl_5 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_3.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_3.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[3], PHT_SEQ_OCT_B[3] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_3.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_6, time )
    pht_seq_sel_mark( 3 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 5")
end



--04
function pht_seq_step_pnl_4()
  rnt:remove_timer( pht_seq_step_pnl_4 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_2.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_2.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[2], PHT_SEQ_OCT_B[2] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_18.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 3, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 4")
end
--03
function pht_seq_step_pnl_3()
  if rnt:has_timer( pht_seq_step_pnl_3 ) then
    rnt:remove_timer( pht_seq_step_pnl_3 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_2.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_2.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[2], PHT_SEQ_OCT_B[2] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_2.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_4, time )
    pht_seq_sel_mark( 2 )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 3")
end



--02
function pht_seq_step_pnl_2()
  rnt:remove_timer( pht_seq_step_pnl_2 )
  if ( vws.PHT_SEQ_VBX_SEL_PNL_1.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_1.value ]( false, "GOLD_OFF1", PHT_SEQ_OCT_A[1], PHT_SEQ_OCT_B[1] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_17.value  --wait
  if ( time > 0 ) then
    pht_seq_skip_pnl( 2, time )
  else
    pht_seq_skip_pnl( 1, vws.PHT_SEQ_VFD_STEP_TIMER_65.value )
    pht_seq_sel_mark( 33 )
  end
  --print("step 2")
end
--01
function pht_seq_step_pnl_1()
  if rnt:has_timer( pht_seq_step_pnl_1 ) then
    rnt:remove_timer( pht_seq_step_pnl_1 )
  end
  if ( vws.PHT_SEQ_VBX_SEL_PNL_1.value > 0 ) then
    PHT_SEQ_MASTER[ vws.PHT_SEQ_VBX_SEL_PNL_1.value ]( true, "GOLD_ON", PHT_SEQ_OCT_A[1], PHT_SEQ_OCT_B[1] )
  end
  local time = vws.PHT_SEQ_VFD_STEP_TIMER_1.value   --play
  if ( time > 0 ) then
    rnt:add_timer( pht_seq_step_pnl_2, time )
    pht_seq_sel_mark( 1 )
  end
  --print("step 1")
end



--skip panel
function pht_seq_skip_pnl( pnl, time )
  if ( PHT_SEQ_CTRL_BKS == 1 ) then --x16 or x32
    for i = pnl, 33 do
      if ( PHT_SEQ_ON_OFF_PNL[i] == true ) then
        return rnt:add_timer( PHT_SEQ_STEP_PNL[2*i-1], time )
      elseif ( i >= 16 ) then
        return rnt:add_timer( PHT_SEQ_STEP_PNL[1], time )
      end
    end  
  else
    for i = pnl, 33 do
      if ( PHT_SEQ_ON_OFF_PNL[i] == true ) then
        return rnt:add_timer( PHT_SEQ_STEP_PNL[2*i-1], time )
      elseif ( i == 33 ) then
        return rnt:add_timer( PHT_SEQ_STEP_PNL[1], time )
      end
    end
  end
end



------------------------------------------------------------------------------------------------
--play & stop
PHT_SEQ_STEP_PNL = {
  pht_seq_step_pnl_1,
  pht_seq_step_pnl_2,
  pht_seq_step_pnl_3,
  pht_seq_step_pnl_4,
  pht_seq_step_pnl_5,
  pht_seq_step_pnl_6,
  pht_seq_step_pnl_7,
  pht_seq_step_pnl_8,
  pht_seq_step_pnl_9,
  pht_seq_step_pnl_10,
  pht_seq_step_pnl_11,
  pht_seq_step_pnl_12,
  pht_seq_step_pnl_13,
  pht_seq_step_pnl_14,
  pht_seq_step_pnl_15,
  pht_seq_step_pnl_16,
  pht_seq_step_pnl_17,
  pht_seq_step_pnl_18,
  pht_seq_step_pnl_19,
  pht_seq_step_pnl_20,
  pht_seq_step_pnl_21,
  pht_seq_step_pnl_22,
  pht_seq_step_pnl_23,
  pht_seq_step_pnl_24,
  pht_seq_step_pnl_25,
  pht_seq_step_pnl_26,
  pht_seq_step_pnl_27,
  pht_seq_step_pnl_28,
  pht_seq_step_pnl_29,
  pht_seq_step_pnl_30,
  pht_seq_step_pnl_31,
  pht_seq_step_pnl_32,
  pht_seq_step_pnl_33,
  pht_seq_step_pnl_34,
  pht_seq_step_pnl_35,
  pht_seq_step_pnl_36,
  pht_seq_step_pnl_37,
  pht_seq_step_pnl_38,
  pht_seq_step_pnl_39,
  pht_seq_step_pnl_40,
  pht_seq_step_pnl_41,
  pht_seq_step_pnl_42,
  pht_seq_step_pnl_43,
  pht_seq_step_pnl_44,
  pht_seq_step_pnl_45,
  pht_seq_step_pnl_46,
  pht_seq_step_pnl_47,
  pht_seq_step_pnl_48,
  pht_seq_step_pnl_49,
  pht_seq_step_pnl_50,
  pht_seq_step_pnl_51,
  pht_seq_step_pnl_52,
  pht_seq_step_pnl_53,
  pht_seq_step_pnl_54,
  pht_seq_step_pnl_55,
  pht_seq_step_pnl_56,
  pht_seq_step_pnl_57,
  pht_seq_step_pnl_58,
  pht_seq_step_pnl_59,
  pht_seq_step_pnl_50,
  pht_seq_step_pnl_61,
  pht_seq_step_pnl_62,
  pht_seq_step_pnl_63,
  pht_seq_step_pnl_64
}
---
function pht_seq_time_play_stop()
  for i = 1, 64 do
    if rnt:has_timer( PHT_SEQ_STEP_PNL[i] ) then  rnt:remove_timer( PHT_SEQ_STEP_PNL[i] ) end
  end
  for pnl = 1, 16 do
    PHT_SEQ_MASTER[ pnl ]( false, "GOLD_OFF1", 0,119 )
  end
end
---
PHT_SEQ_PLAY_STOP = true
function pht_seq_stop()
  local sti = song.selected_track_index
  local sii = song.selected_instrument_index
  pht_seq_time_play_stop()
  vws.PHT_SEQ_BT_PLAY_STOP.bitmap = "./ico/play_ico.png"
  vws.PHT_SEQ_BT_PLAY_STOP.color = PHT_MAIN_COLOR.DEFAULT
  song.selected_track_index = sti
  song.selected_instrument_index = sii
  PHT_SEQ_PLAY_STOP = true
end
---
function pht_seq_play()
  if ( PHT_SEQ_PLAY_STOP == true ) then
    vws.PHT_SEQ_BT_PLAY_STOP.bitmap = "./ico/play_return_ico.png"
    vws.PHT_SEQ_BT_PLAY_STOP.color = PHT_MAIN_COLOR.GOLD_ON
    PHT_SEQ_PLAY_STOP = false
  else
    pht_seq_time_play_stop()
  end
  for i = 1, 32 do
    if ( PHT_SEQ_ON_OFF_PNL[i] == true ) then
      return PHT_SEQ_STEP_PNL[2*i-1]()
    end
  end
end



------------------------------------------------------------------------------------------------
--control blocks
PHT_SEQ_CTRL_BKS = 1
function pht_seq_ctrl_bks()
  if ( PHT_SEQ_CTRL_BKS == 1 ) then
    PHT_SEQ_CTRL_BKS = 2
    ---
    vws.PHT_SEQ_MODE_1:remove_child ( PHT_SEQ_BLOCK_X4 )
    vws.PHT_SEQ_MODE_1:remove_child ( PHT_SEQ_BLOCK_X1 )
    vws.PHT_SEQ_MODE_1:remove_child ( PHT_SEQ_BLOCK_X2 )
    vws.PHT_SEQ_MODE_1.visible = false
    vws.PHT_SEQ_MODE_2.visible = true
    vws.PHT_SEQ_MODE_2_X1:add_child ( PHT_SEQ_BLOCK_X2 )
    vws.PHT_SEQ_MODE_2_X1:add_child ( PHT_SEQ_BLOCK_X1 )
    vws.PHT_SEQ_MODE_2_X2:add_child ( PHT_SEQ_BLOCK_X3 )
    vws.PHT_SEQ_MODE_2_X2:add_child ( PHT_SEQ_BLOCK_X4 )
    vws.PHT_SEQ_BLOCK_X5:remove_child ( PHT_SEQ_LOGO )
    vws.PHT_SEQ_BLOCK_X5:add_child ( PHT_SEQ_LOGO_CMP )
    vws.PHT_SEQ.width = 875
    PHT_SEQ_CTRL_BLOCKS.bitmap = "./ico/panel_2_ico.png"
    ---
  elseif ( PHT_SEQ_CTRL_BKS == 2 ) then
    PHT_SEQ_CTRL_BKS = 3
    ---
    vws.PHT_SEQ_BLOCK_X5:remove_child ( PHT_SEQ_LOGO_CMP )
    vws.PHT_SEQ_BLOCK_X5:add_child ( PHT_SEQ_LOGO )
    vws.PHT_SEQ_MODE_2_X1:remove_child ( PHT_SEQ_BLOCK_X2 )
    vws.PHT_SEQ_MODE_2_X1:remove_child ( PHT_SEQ_BLOCK_X1 )
    vws.PHT_SEQ_MODE_2_X2:remove_child ( PHT_SEQ_BLOCK_X3 )
    vws.PHT_SEQ_MODE_2_X2:remove_child ( PHT_SEQ_BLOCK_X4 )
    vws.PHT_SEQ_MODE_2.visible = false
    vws.PHT_SEQ_MODE_1.visible = true
    vws.PHT_SEQ_MODE_1:add_child ( PHT_SEQ_BLOCK_X1 )
    vws.PHT_SEQ_MODE_1:add_child ( PHT_SEQ_BLOCK_X2 )
    vws.PHT_SEQ_MODE_1:add_child ( PHT_SEQ_BLOCK_X3 )
    vws.PHT_SEQ_MODE_1:add_child ( PHT_SEQ_BLOCK_X4 )
    PHT_SEQ_LOGO.width = 954
    PHT_SEQ_CTRL_BLOCKS.bitmap = "./ico/panel_2h_ico.png"
    ---
  else
    PHT_SEQ_CTRL_BKS = 1
    ---
    PHT_SEQ_LOGO.width = 154
    vws.PHT_SEQ_MODE_1:remove_child ( PHT_SEQ_BLOCK_X3 )
    PHT_SEQ_CTRL_BLOCKS.bitmap = "./ico/panel_1_ico.png"
    ---
  end
  --print( PHT_SEQ_CTRL_BKS )
end
---
PHT_SEQ_CTRL_BLOCKS = vb:button {
  height = 27,
  width = 34,
  bitmap = "./ico/panel_1_ico.png",
  color = PHT_MAIN_COLOR.SKY_BLUE,
  pressed = function() pht_seq_ctrl_bks() end,
  midi_mapping = "Tools:PhraseTouch:Step Sequencer:Main Controls:Window Modes Checkbox",
  tooltip = "Window modes for 16 or 32 steps"
}



------------------------------------------------------------------------------------------------
--gui
content_sequencer = vb:column { margin = 5, spacing = 5,
  id = "PHT_SEQ",
  vb: row { margin = 1,
    vb:row {
      id = "PHT_SEQ_MODE_1",
      visible = true,
      style = "panel",
      margin = 6,
      spacing = 2,
      PHT_SEQ_BLOCK_X1,
      PHT_SEQ_BLOCK_X2,
      --PHT_SEQ_BLOCK_X3,
      PHT_SEQ_BLOCK_X4,
    },
    vb:column {
      id = "PHT_SEQ_MODE_2",
      visible = false,
      style = "panel",
      margin = 6,
      spacing = 6,
      vb:row {
        id = "PHT_SEQ_MODE_2_X1",
        spacing = 2,
      },
      vb:row {
        id = "PHT_SEQ_MODE_2_X2",
        spacing = 2,
      }
    }
  },
  vb:row { spacing = 5,
    id = "PHT_SEQ_BLOCK_X5",
    PHT_SEQ_CTRL_BLOCKS,
    PHT_SEQ_CTRL,
    PHT_SEQ_DST_PNL,
    PHT_SEQ_UP_DOWN_MS,
    PHT_SEC_RDM_TME,
    PHT_SEQ_LOGO
  }
}



------------------------------------------------------------------------------------------------
--show dialog_about
function show_tool_dialog_sequencer()
  --Avoid showing the same window several times!
  if ( dialog_sequencer and dialog_sequencer.visible ) then dialog_sequencer:show() return end
  dialog_sequencer = rna:show_custom_dialog( title_sequencer, content_sequencer, pht_keyhandler )
end
