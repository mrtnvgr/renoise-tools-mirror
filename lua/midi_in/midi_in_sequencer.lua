--
-- MIDI_IN PANEL_SEQ
--



-----------------------------------------------------------------------------------------------
--skip steps
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip Even Steps Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_skip_even()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip Old Steps Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_skip_old()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Skip All Steps Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_skip_all()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Skip Steps:Not Skip Any Step Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_skip_any()
    else
      return
    end
  end
}
---
for panel = 1, 32 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Step Sequencer:Skip Steps:"..( "Skip Step %.2d Checkbox" ):format( panel ),
    invoke = function( message )
      if message:is_trigger() then
        return pht_seq_on_off_pnl( panel )
      else
        return
      end
    end
  }
end



-----------------------------------------------------------------------------------------------
--panels of notes
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:General Panels Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_VBX_SEL_PNL_0.value = math.floor( message.int_value * 16/128 + 1 )
    else
      return
    end
  end
}
---
for panel = 1, 32 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:"..( "Panel %.2d Valuebox" ):format( panel ),
    invoke = function( message )
      if message:is_abs_value() then
        vws["PHT_SEQ_VBX_SEL_PNL_"..panel].value = math.floor( message.int_value * 17/128 )
      else
        return
      end
    end
  }
end



-----------------------------------------------------------------------------------------------
--step marker
for mark = 1, 32 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Step Sequencer:Step Marker:"..( "Step Marker %.2d Checkbox" ):format( mark ),
    invoke = function( message )
      if message:is_trigger() then
        return pht_seq_vfd_zero ( mark )
      else
        return
      end
    end
  }
end
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Marker:Bridge Marker Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_vfd_zero ( 33 )
    else
      return
    end
  end
}



-----------------------------------------------------------------------------------------------
--octaves
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Octaves:General Octaves Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_OCT_ALL.value = math.floor( message.int_value * 11/128 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 0 to 9 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_oct_0_9()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 9 to 0 Button",
  invoke = function( message )
    if message:is_trigger()  then
      return pht_seq_oct_9_0()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 0-1-2-3 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_oct_0_3()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Octaves:Distribute Octaves:Distribute Octaves 4-5-6-7 Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_oct_4_7()
    else
      return
    end
  end
}
for pnl = 1, 32 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Step Sequencer:Octaves:"..("Octave Step %.2d Valuefield"):format( pnl ),
    invoke = function( message )
      if message:is_abs_value() then
        vws["PHT_SEQ_OCT_"..pnl].value = math.floor( message.int_value * 11/128 )
      else
        return
      end
    end
  }
end



-----------------------------------------------------------------------------------------------
--step time
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Time Calculator Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_sec_rdm_tme()
    else
      return
    end
  end
}
---
for step = 1, 64 do
  rnt:add_midi_mapping {
    name = "Tools:PhraseTouch:Step Sequencer:Step Times:"..("Step Time %.2d Valuefield"):format( step ),
    invoke = function( message )
      if message:is_abs_value() then
        vws["PHT_SEQ_VFD_STEP_TIMER_"..step].value = math.floor( message.int_value * 1008/128 )
      else
        return
      end
    end
  }
end
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Bridge Time Valuefield",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_VFD_STEP_TIMER_65.value = math.floor( message.int_value * 1007/128 + 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Decelerate All Times Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_up_down( true )
    else
      return pht_seq_up_down_ms_repeat( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Accelerate All Times Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_up_down( false )
    else
      return pht_seq_up_down_ms_repeat( true )
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_random_play()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_random_wait()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Min Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_RDM_VAL_1.value = math.floor( message.int_value * 998/128 + 10 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Play Times Max Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_RDM_VAL_2.value = math.floor( message.int_value * 998/128 + 10 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Min Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_RDM_VAL_3.value = math.floor( message.int_value * 998/128 + 10 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Step Times:Random Wait Times Max Valuebox",
  invoke = function( message )
    if message:is_abs_value() then
      vws.PHT_SEQ_RDM_VAL_4.value = math.floor( message.int_value * 998/128 + 10 )
    else
      return
    end
  end
}



------------------------------------------------------------------------------------------------
--main controls
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Main Controls:Window Modes Checkbox",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_ctrl_bks()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Main Controls:Play or Replay Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_play()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Main Controls:Stop Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_stop()
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Main Controls:Reset All Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_reset()
    else
      return
    end
  end
}



------------------------------------------------------------------------------------------------
--distribute panels of notes
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1-5-9-13 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 1 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1-2 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 2 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 3 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 3 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 4 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 4 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 5 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 5 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 8 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 8 )
    else
      return
    end
  end
}
---
rnt:add_midi_mapping {
  name = "Tools:PhraseTouch:Step Sequencer:Panel of Notes:Distribute Panels:Distribute Panel 1 to 16 & Repeat Button",
  invoke = function( message )
    if message:is_trigger() then
      return pht_seq_distrib( 16 )
    else
      return
    end
  end
}
