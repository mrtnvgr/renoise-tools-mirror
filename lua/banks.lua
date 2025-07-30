--
-- banks panel
--


--banks selector
function kng_banks_sel( val )
  if ( val == 1 ) then
    vws.KNG_BANKS_1.visible = true
    vws.KNG_BANKS_2.visible = false
    vws.KNG_BANKS_3.visible = false
    vws.KNG_BANKS_4.visible = false
    vws.KNG_BANKS_SEL_1.color = KNG_CLR.MARKER
    vws.KNG_BANKS_SEL_2.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_3.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_4.color = KNG_CLR.DEFAULT
  elseif ( val == 2 ) then
    vws.KNG_BANKS_1.visible = false
    vws.KNG_BANKS_2.visible = true
    vws.KNG_BANKS_3.visible = false
    vws.KNG_BANKS_4.visible = false
    vws.KNG_BANKS_SEL_1.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_2.color = KNG_CLR.MARKER
    vws.KNG_BANKS_SEL_3.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_4.color = KNG_CLR.DEFAULT
  elseif ( val == 3 ) then
    vws.KNG_BANKS_1.visible = false
    vws.KNG_BANKS_2.visible = false
    vws.KNG_BANKS_3.visible = true
    vws.KNG_BANKS_4.visible = false
    vws.KNG_BANKS_SEL_1.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_2.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_3.color = KNG_CLR.MARKER
    vws.KNG_BANKS_SEL_4.color = KNG_CLR.DEFAULT
  else
    vws.KNG_BANKS_1.visible = false
    vws.KNG_BANKS_2.visible = false
    vws.KNG_BANKS_3.visible = false
    vws.KNG_BANKS_4.visible = true
    vws.KNG_BANKS_SEL_1.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_2.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_3.color = KNG_CLR.DEFAULT
    vws.KNG_BANKS_SEL_4.color = KNG_CLR.MARKER
  end
end



--lock save bank
local KNG_BANK_LOCK_SAVE = { --96
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true,
  true, true, true, true, true, true, true, true
} 
function kng_lock_save_bank( val )
  if ( KNG_BANK_LOCK_SAVE[val] == true ) then
    vws["KNG_BANK_BT_SAVE_"..val].active = true
    vws["KNG_BANK_BT_LOCK_SAVE_"..val].bitmap = "/ico/mini_padlock_open_ico.png"
    KNG_BANK_LOCK_SAVE[val] = false
  else
    vws["KNG_BANK_BT_SAVE_"..val].active = false
    vws["KNG_BANK_BT_LOCK_SAVE_"..val].bitmap = "/ico/mini_padlock_close_ico.png"
    KNG_BANK_LOCK_SAVE[val] = true
  end
end



--lock save all banks
local KNG_SAVE_BANKS_SEL = true
function kng_lock_save_all_banks( val )
  if ( val == 1 ) then
    for bank = 1, 96 do
      vws["KNG_BANK_BT_SAVE_"..bank].active = true
      vws["KNG_BANK_BT_LOCK_SAVE_"..bank].bitmap = "/ico/mini_padlock_open_ico.png"
      KNG_BANK_LOCK_SAVE[bank] = false
    end
    vws.KNG_LOCK_SAVE_BANKS_1.color = KNG_CLR.MARKER
    vws.KNG_LOCK_SAVE_BANKS_2.color = KNG_CLR.DEFAULT
    KNG_SAVE_BANKS_SEL = true
  else
    for bank = 1, 96 do
      vws["KNG_BANK_BT_SAVE_"..bank].active = false
      vws["KNG_BANK_BT_LOCK_SAVE_"..bank].bitmap = "/ico/mini_padlock_close_ico.png"
      KNG_BANK_LOCK_SAVE[bank] = true
    end
    vws.KNG_LOCK_SAVE_BANKS_1.color = KNG_CLR.DEFAULT
    vws.KNG_LOCK_SAVE_BANKS_2.color = KNG_CLR.MARKER
    KNG_SAVE_BANKS_SEL = false
  end
end



--save bank
function kng_save_bank( val )
  --print (io.exists("banks"))

  --check folder "banks", if it does not exist, create it
  if ( io.exists("banks") == false ) then
    --create new directory "banks"
    os.mkdir("banks")
    rna:show_status( "KangarooX120:  The \"banks\" folder has been restored!" )
  end

  --create doc with pad data
  local doc = renoise.Document.create("Kng_Bank_"..val.."") {
    state = true,
    nme = vws["KNG_BANK_TXF_"..val].text,
    nte = KNG_PAD_NTE,
    ins = KNG_PAD_INS,
    trk = KNG_PAD_TRK,
    vel = KNG_PAD_VEL,
    clr = vws.KNG_PAD_CLR.value
  }

  --save the doc in xml
  doc:save_as("banks/bank_"..val..".xml")
  kng_revise_bank( 1, 96 )
  rna:show_status( ("KangarooX120:  Bank %.2d saved! The 96 Banks have been revised again!"):format(val) )
  
  --lock
  vws["KNG_BANK_BT_SAVE_"..val].active = false
  vws["KNG_BANK_BT_LOCK_SAVE_"..val].bitmap = "/ico/mini_padlock_close_ico.png"
  KNG_BANK_LOCK_SAVE[val] = true
end



--load bank
function kng_load_bank( val )
  --check folder "banks"
  if ( io.exists("banks") == true ) then
    --create neutral doc ( it is necessary for invoke after the doc:load_from() ), and not save!
    local doc = renoise.Document.create("Kng_Bank_"..val.."") {
      state = false,
      nme = "",
      nte = { 0 },
      ins = { 0 },
      trk = { 0 },
      vel = { 0 },
      clr = 1
    }
    --load doc to restore
    doc:load_from("banks/bank_"..val..".xml")
    --oprint(doc:property("state").value)
    
    --import data to pad from xml
    if ( doc:property("state").value == true ) then
      for i = 1, 120 do
        KNG_PAD_NTE[i] = doc:property("nte")[i].value
        KNG_PAD_INS[i] = doc:property("ins")[i].value
        KNG_PAD_TRK[i] = doc:property("trk")[i].value
        KNG_PAD_VEL[i] = doc:property("vel")[i].value
        vws["KNG_PAD_"..i - 1 ].text = ("%.2d\n%s  %.2X\nTr%.2d"):format( i, kng_note_tostring( KNG_PAD_NTE[i] ), KNG_PAD_INS[i], KNG_PAD_TRK[i] )
        vws["KNG_PAD_ROT_VEL_"..i - 1 ].value = KNG_PAD_VEL[i]
      end
      vws.KNG_PAD_CLR.value = doc:property("clr").value
      rna:show_status( ("KangarooX120:  Bank %.2d loaded!"):format(val) )
    else
      rna:show_status( ("KangarooX120:  Bank %.2d is empty. Please, save before a Bank!"):format(val) )
    end
  else
    rna:show_status( "KangarooX120:  The \"banks\" folder does not exist! Save a bank first!" )
  end
end



--revise bank
local KNG_REVISE_BANK_STATE = true
function kng_revise_bank( bank_1, bank_2 )
  --check folder "banks"
  if ( io.exists("banks") == true ) then
    for i = bank_1, bank_2 do
      --create neutral doc ( it is necessary for invoke after the doc:load_from() ), and not save!
      local doc = renoise.Document.create("Kng_Bank_"..i.."") {
        state = false,
        nme = "",
        nte = { 0 },
        ins = { 0 },
        trk = { 0 },
        vel = { 0 },
        clr = 1
      }
      --load doc to restore
      doc:load_from("banks/bank_"..i..".xml")
      --check state, and change "active" of load button and "name" of textfild
      if ( doc:property("state").value == true ) then
        vws["KNG_BANK_BT_LOAD_"..i].active = true
        vws["KNG_BANK_TXF_"..i].text = doc:property("nme").value
      else
        vws["KNG_BANK_BT_LOAD_"..i].active = false
        vws["KNG_BANK_TXF_"..i].text = ("Bank %.2d"):format( i )
      end
    end
    if ( KNG_REVISE_BANK_STATE == false ) then
      return
    else
      rna:show_status ("KangarooX120:  96 banks have been revised!" )
      KNG_REVISE_BANK_STATE = false
    end
  else
    rna:show_status( "KangarooX120:  The \"banks\" folder does not exist! No banks!" )
  end
end
