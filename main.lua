-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: Orchestral
-- Version: 1.1 build 002
-- License: Free
-- Distribution: Free Full Version
-- Compatibility: Renoise v3.1.1
-- Development date: December 2018
-- Published: December 2018
-- Locate: Spain
-- Programmer: ulneiz
--
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--initials
local title = "Orchestral"
local version = "v1.1"
local ORC_MAIN_CONTENT=nil
local orchestral_dialog = nil
local vb = renoise.ViewBuilder()
local vws = vb.views
local rnt = renoise.tool()
local rns_version=renoise.RENOISE_VERSION
local api_version=renoise.API_VERSION

--global song
song=nil
  local function pre_sng() song=renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier(pre_sng) --catching start renoise or new song
  pcall(pre_sng) --catching installation

--checkbox
local ORC_CB = { false, false, false, false, false, false, false, false, false }

--main colors
local ORC_CLR_CT = { 
  {000,000,000},{090,000,000},{000,090,000}, --grease, red, green
  {216,210,040},{076,080,010},{161,218,103},{021,078,003},{067,196,238},{027,056,098},{220,120,080},{100,050,000}, --yellow, green, blue, brown
  {255,181,035},{076,053,010},{084,000,108},{147,005,114}--gold, gold2, violet, pink
}

--colors table
local ORC_COLOR = {
  {004,148,122},{014,158,132},{024,168,142},{034,178,152},{044,188,162},{054,198,172},{064,198,182},{074,208,192},{084,218,202},{094,228,212}, --aqua      1 to 30
  {004,148,122},{014,158,132},{024,168,142},{034,178,152},{044,188,162},{054,198,172},{064,198,182},{074,208,192},{084,218,202},{094,228,212},
  {004,148,122},{014,158,132},{024,168,142},{034,178,152},{044,188,162},{054,198,172},{064,198,182},{074,208,192},{084,218,202},{094,228,212},
  
  {001,001,001},{010,010,010},{020,020,020},{030,030,030},{040,040,040},{050,050,050},{060,060,060},{070,070,070},{080,080,080},{090,090,090}, --black     31 to 60
  {001,001,001},{010,010,010},{020,020,020},{030,030,030},{040,040,040},{050,050,050},{060,060,060},{070,070,070},{080,080,080},{090,090,090},
  {001,001,001},{010,010,010},{020,020,020},{030,030,030},{040,040,040},{050,050,050},{060,060,060},{070,070,070},{080,080,080},{090,090,090},
    
  {000,056,185},{000,066,195},{000,076,205},{000,086,215},{000,096,225},{000,106,235},{000,116,245},{000,126,255},{000,136,255},{000,146,255}, --blue      61 to 90
  {000,056,185},{000,066,195},{000,076,205},{000,086,215},{000,096,225},{000,106,235},{000,116,245},{000,126,255},{000,136,255},{000,146,255},
  {000,056,185},{000,066,195},{000,076,205},{000,086,215},{000,096,225},{000,106,235},{000,116,245},{000,126,255},{000,136,255},{000,146,255},

  {133,042,000},{143,052,000},{153,062,000},{163,072,007},{173,082,017},{183,092,027},{193,102,037},{203,112,047},{213,122,057},{223,132,067}, --brown     91 to 120
  {133,042,000},{143,052,000},{153,062,000},{163,072,007},{173,082,017},{183,092,027},{193,102,037},{203,112,047},{213,122,057},{223,132,067},
  {133,042,000},{143,052,000},{153,062,000},{163,072,007},{173,082,017},{183,092,027},{193,102,037},{203,112,047},{213,122,057},{223,132,067},
    
  {175,141,000},{185,151,005},{195,161,015},{205,171,025},{215,181,035},{225,191,045},{235,201,055},{245,211,065},{255,221,075},{255,231,085}, --gold      121 to 150
  {175,141,000},{185,151,005},{195,161,015},{205,171,025},{215,181,035},{225,191,045},{235,201,055},{245,211,065},{255,221,075},{255,231,085},
  {175,141,000},{185,151,005},{195,161,015},{205,171,025},{215,181,035},{225,191,045},{235,201,055},{245,211,065},{255,221,075},{255,231,085},
  
  {110,110,110},{120,120,120},{130,130,130},{140,140,140},{150,150,150},{160,160,160},{170,170,170},{180,180,180},{190,190,190},{200,200,200}, --grey      151 to 180
  {110,110,110},{120,120,120},{130,130,130},{140,140,140},{150,150,150},{160,160,160},{170,170,170},{180,180,180},{190,190,190},{200,200,200},
  {110,110,110},{120,120,120},{130,130,130},{140,140,140},{150,150,150},{160,160,160},{170,170,170},{180,180,180},{190,190,190},{200,200,200},
  
  {000,155,000},{000,165,000},{000,175,000},{000,185,000},{000,195,000},{000,205,000},{000,215,000},{000,225,000},{000,235,000},{000,245,000}, --green     181 to 210
  {000,155,000},{000,165,000},{000,175,000},{000,185,000},{000,195,000},{000,205,000},{000,215,000},{000,225,000},{000,235,000},{000,245,000},
  {000,155,000},{000,165,000},{000,175,000},{000,185,000},{000,195,000},{000,205,000},{000,215,000},{000,225,000},{000,235,000},{000,245,000},
  
  {235,128,000},{245,138,010},{255,148,020},{255,158,030},{255,168,040},{255,178,050},{255,188,060},{255,198,070},{255,208,080},{255,218,090}, --orange    211 to 240
  {235,128,000},{245,138,010},{255,148,020},{255,158,030},{255,168,040},{255,178,050},{255,188,060},{255,198,070},{255,208,080},{255,218,090},
  {235,128,000},{245,138,010},{255,148,020},{255,158,030},{255,168,040},{255,178,050},{255,188,060},{255,198,070},{255,208,080},{255,218,090},
  
  {205,118,177},{215,128,187},{225,138,197},{235,148,207},{245,158,217},{255,168,227},{255,178,237},{255,188,247},{255,198,255},{255,208,255}, --palepink  241 to 270
  {205,118,177},{215,128,187},{225,138,197},{235,148,207},{245,158,217},{255,168,227},{255,178,237},{255,188,247},{255,198,255},{255,208,255},
  {205,118,177},{215,128,187},{225,138,197},{235,148,207},{245,158,217},{255,168,227},{255,178,237},{255,188,247},{255,198,255},{255,208,255},
    
  {195,000,120},{215,000,130},{225,000,140},{235,000,150},{245,000,160},{255,000,170},{255,010,180},{255,020,190},{255,030,200},{255,040,210}, --pink      271 to 300
  {195,000,120},{215,000,130},{225,000,140},{235,000,150},{245,000,160},{255,000,170},{255,010,180},{255,020,190},{255,030,200},{255,040,210},
  {195,000,120},{215,000,130},{225,000,140},{235,000,150},{245,000,160},{255,000,170},{255,010,180},{255,020,190},{255,030,200},{255,040,210},
  
  {138,185,049},{148,195,059},{158,205,069},{168,215,079},{178,225,089},{188,235,099},{198,245,109},{208,255,119},{218,255,129},{228,255,139}, --pistachio 301 to 330
  {138,185,049},{148,195,059},{158,205,069},{168,215,079},{178,225,089},{188,235,099},{198,245,109},{208,255,119},{218,255,129},{228,255,139},
  {138,185,049},{148,195,059},{158,205,069},{168,215,079},{178,225,089},{188,235,099},{198,245,109},{208,255,119},{218,255,129},{228,255,139},
  
  {185,000,000},{195,000,000},{205,000,000},{215,000,000},{225,000,000},{235,000,000},{245,000,000},{255,000,000},{255,010,010},{255,020,020}, --red       331 to 360
  {185,000,000},{195,000,000},{205,000,000},{215,000,000},{225,000,000},{235,000,000},{245,000,000},{255,000,000},{255,010,010},{255,020,020},
  {185,000,000},{195,000,000},{205,000,000},{215,000,000},{225,000,000},{235,000,000},{245,000,000},{255,000,000},{255,010,010},{255,020,020},
  
  {000,153,205},{000,163,215},{000,173,225},{000,183,235},{000,193,245},{000,203,255},{000,213,255},{010,223,255},{020,233,255},{030,243,255}, --skyblue   361 to 390
  {000,153,205},{000,163,215},{000,173,225},{000,183,235},{000,193,245},{000,203,255},{000,213,255},{010,223,255},{020,233,255},{030,243,255},
  {000,153,205},{000,163,215},{000,173,225},{000,183,235},{000,193,245},{000,203,255},{000,213,255},{010,223,255},{020,233,255},{030,243,255},
  
  {120,000,235},{130,000,245},{140,000,255},{150,010,255},{160,020,255},{160,030,255},{170,040,255},{180,050,255},{190,060,255},{200,070,255}, --violet    391 to 420
  {120,000,235},{130,000,245},{140,000,255},{150,010,255},{160,020,255},{160,030,255},{170,040,255},{180,050,255},{190,060,255},{200,070,255},
  {120,000,235},{130,000,245},{140,000,255},{150,010,255},{160,020,255},{160,030,255},{170,040,255},{180,050,255},{190,060,255},{200,070,255},
  
  {255,255,255},{245,245,245},{235,235,235},{225,225,225},{215,215,215},{205,205,205},{195,195,195},{185,185,185},{175,175,175},{165,165,165}, --white     421 to 450
  {255,255,255},{245,245,245},{235,235,235},{225,225,225},{215,215,215},{205,205,205},{195,195,195},{185,185,185},{175,175,175},{165,165,165},
  {255,255,255},{245,245,245},{235,235,235},{225,225,225},{215,215,215},{205,205,205},{195,195,195},{185,185,185},{175,175,175},{165,165,165},

  {195,195,000},{205,205,000},{215,215,000},{225,225,000},{235,235,000},{245,245,000},{255,255,000},{255,255,010},{255,255,020},{255,255,030}, --yellow    451 to 480
  {195,195,000},{205,205,000},{215,215,000},{225,225,000},{235,235,000},{245,245,000},{255,255,000},{255,255,010},{255,255,020},{255,255,030},
  {195,195,000},{205,205,000},{215,215,000},{225,225,000},{235,235,000},{245,245,000},{255,255,000},{255,255,010},{255,255,020},{255,255,030},
}

--default colors: red, white, gold, green, brown, blue, yellow, pink, violet
local ORC_COLOR_SELECT = { 331, 421, 211, 181, 91, 61, 451, 271, 391 } --9

local ORC_CLR = {
  DEFAULT = { 000,000,000 },
  MARKER = { 255,181,035 }
}

--color blend
local ORC_COLOR_BLEND = { 35, 20 } --35, 30



--capture the native color of marker(for Windows: C:\Users\USER_NAME\AppData\Roaming\Renoise\V3.1.1\Config.xml)
local function orc_capture_clr_mrk()
  --print(os.currentdir())

  --Config.xml path:  
    --Windows: %appdata%\Renoise\V3.1.1\Config.xml
    --MacOS: ~/Library/Logs/,~/Library/Preferences/Renoise/V3.1.1/Config.xml
    --Linux: ~/.renoise/V3.1.1/Config.xml

  local filename=""
  if (os.platform()=="WINDOWS") then
    filename=("%s\\Renoise\\V%s\\Config.xml"):format(os.getenv("APPDATA"),rns_version)
    --print("Windows:",filename)
  elseif (os.platform()=="MACINTOSH") then
    filename=("%s/Library/Preferences/Renoise/V%s/Config.xml"):format(os.getenv("HOME"),rns_version)
    --print("MacOS:",filename)
  elseif (os.platform()=="LINUX") then
    filename=("%s/.renoise/V%s/Config.xml"):format(os.getenv("HOME"),rns_version)
    --print("Linux:",filename)
  end
  --print(filename)
  
  --RenoisePrefs
    --SkinColors
      --Selected_Button_Back

  if (io.exists(filename)) then
    local pref_data=renoise.Document.create("RenoisePrefs"){SkinColors={Selected_Button_Back=""}}
    pref_data:load_from(filename)
    --print(pref_data.SkinColors.Selected_Button_Back)
    local rgb=tostring(pref_data.SkinColors.Selected_Button_Back)
    local one,two,thr=rgb:match("([^,]+),([^,]+),([^,]+)")
    ORC_CLR.MARKER[1]=tonumber(one)
    ORC_CLR.MARKER[2]=tonumber(two)
    ORC_CLR.MARKER[3]=tonumber(thr)
  end
end



--color selector panel
local function orc_bt_clr_select( value )
  for i = 1, 9 do
    if ( vws["ORC_PP_SELECT_COLOR"].value == i ) then
      ORC_COLOR_SELECT[i] = value
    end
    --print("ORC_COLOR_SELECT",i,ORC_COLOR_SELECT[i])
  end
  --print("--- ---")
end



--color mode
local ORC_SEL_CLR_C0MPACT = false
local function orc_color_compact()
  if ( ORC_SEL_CLR_C0MPACT == false ) then
    vws["ORC_BT_COL"].bitmap = "./icons/color_selector_off_ico.png"
    vws["ORC_BT_COL"].color = ORC_CLR.MARKER
    vws["ORC_BT_COL"].tooltip = "Hide color selector"
    ORC_SEL_CLR_C0MPACT = true
    vws["ORC_MAIN_SELECT_COLOR"].visible = true
  else
    vws["ORC_BT_COL"].bitmap = "./icons/color_selector_on_ico.png"
    vws["ORC_BT_COL"].color = ORC_CLR.DEFAULT
    vws["ORC_BT_COL"].tooltip = "Show color selector"
    ORC_SEL_CLR_C0MPACT = false
    vws["ORC_MAIN_SELECT_COLOR"].visible = false
  end
end



--view color selector directly
local function orc_bt_clr_direct( value )
  vws["ORC_PP_SELECT_COLOR"].value = value
  ORC_SEL_CLR_C0MPACT = false
  orc_color_compact()
end



--change frame popup
local function orc_pp_change_frame( value )
  for i = 1, 16 do
    if ( ORC_COLOR_SELECT[value] == i*30 -30 + 1 ) then
      vws["ORC_FRAME_"..i].color = ORC_CLR.MARKER
    else
      vws["ORC_FRAME_"..i].color = ORC_CLR.DEFAULT
    end
  end
end



--change frame button selector
local function orc_bt_change_frame( value )
  for i = 1, 16 do
    if ( i == value ) then
      vws["ORC_FRAME_"..i].color = ORC_CLR.MARKER
    else
      vws["ORC_FRAME_"..i].color = ORC_CLR.DEFAULT
    end
  end
  ---
  local pp = vws["ORC_PP_SELECT_COLOR"].value
  vws["ORC_BT_CLR_"..pp].color =  ORC_COLOR[ ORC_COLOR_SELECT[pp] + 2 ]
  vws["ORC_PANEL_"..pp*2].color = ORC_COLOR[ ORC_COLOR_SELECT[pp] + 2 ]
end



--search frame for insert group
local function orc_search_frame( value )
  if ( ORC_SEL_CLR_C0MPACT == true ) then
    vws["ORC_PP_SELECT_COLOR"].value = value
  end
end



--name track (and main group)
local ORC_NAME = {
  "STRINGS", "Solo Strings", "Violins", "1st Violins", "2st Violins", "Violas", "Cellos", "Double Basses", "Harp","",                   --1
  "WINDS","Solo Wind", "Alto Flute", "Bass Flute", "Piccolo", "Oboe", "English Horn", "Clarinet", "E-flat Clarinet", "Bass Clarinet",   --11
  "Basson", "Double Bassoon", "Flugelhorn", "Saxophone", "Bagpipe", "Shakuhachi", "Cornet", "Harmonica", "", "",                        --21*
  "BRASS", "Solo Brass", "Trumpets", "French Horn", "Trombones", "Tuba", "", "", "", "",                                                --31 
  "KEYBOARDS", "Piano", "Synthesizer", "Organ", "Celesta", "Clavichord", "Harpsichord", "Accordion", "", "",                            --41 
  "GUITARS", "Electric Guitar", "Electric Bass G", "Acoustic Guitar", "Mandolin", "Banjo", "Bandurria", "Lute", "", "",                 --51
  "PERCUSSION", "Tubular Bells", "Vibraphone", "Xylophone", "Glockenspiel", "Marimba", "Hammer", "Triangle", "Chimes", "Maracas",       --61
  "Castanets", "Wooden-block", "Claves", "Tambourine", "Cymbals", "Side Drum", "Gongs", "Timpani", "Congas", "Tenor Drum",              --71*
  "Bass Drum","", "", "", "", "", "", "", "", "",                                                                                       --81*
  "BATTERY", "Cymbal", "Hi-hat", "Snare Drum", "Toms", "Floor Tom", "Bass Drum", "", "", "",                                            --91
  "CHORUS", "Women Chorus", "Men Chorus", "Children Chorus", "Mixed Chorus", "", "", "", "", "",                                        --101
  "VOICES", "Singer", "Alto", "Soprano", "Mezzo-Sopra.", "Contralto", "Countertenor", "Tenor", "Baritone", "Bass Voice"                 --111
}

local ORC_TR_PROPERTIES = { true, false, false, false, 1, 0 }



--checkbox panels
local function orc_cb( cb, pn )
  if ( ORC_CB[cb] == false ) then
    vws["ORC_PANEL_"..pn+1].visible = false
    vws["ORC_PANEL_"..pn].visible = true
    vws["ORC_MAIN_VALUEBOX_"..cb].visible = true
    vws["ORC_CHECKBOX_"..cb].visible = true
    vws["ORC_BT_CLR_"..cb].visible = true
    vws["ORC_BUTTON_"..cb].tooltip = "Insert the group & the child tracks / Modify the selected group"
    if ( cb < 8 ) then
      vws["ORC_BUTTON_"..cb].width = 263
    else
      vws["ORC_BUTTON_"..cb].width = 95
    end
    ORC_CB[cb] = true
  else
    vws["ORC_PANEL_"..pn].visible = false
    vws["ORC_PANEL_"..pn+1].visible = true
    vws["ORC_MAIN_VALUEBOX_"..cb].visible = false
    vws["ORC_CHECKBOX_"..cb].visible = false
    vws["ORC_BT_CLR_"..cb].visible = false
    vws["ORC_BUTTON_"..cb].tooltip = "Insert only the group / Modify the selected group"
    if ( cb < 8 ) then
      vws["ORC_BUTTON_"..cb].width = 335
    else
      vws["ORC_BUTTON_"..cb].width = 167
    end
    ORC_CB[cb] = false
  end
end



--checkbox vol, pan, dly, sfx
local function orc_cb_tr_vol()
  if ORC_TR_PROPERTIES[1] == false then
    vws["ORC_BT_VOL"].color = ORC_CLR.MARKER
    ORC_TR_PROPERTIES[1] = true
  else
    vws["ORC_BT_VOL"].color = ORC_CLR.DEFAULT
    ORC_TR_PROPERTIES[1] = false
  end
end
---
local function orc_cb_tr_pan()
  if ORC_TR_PROPERTIES[2] == false then
    vws["ORC_BT_PAN"].color = ORC_CLR.MARKER
    ORC_TR_PROPERTIES[2] = true
  else
    vws["ORC_BT_PAN"].color = ORC_CLR.DEFAULT
    ORC_TR_PROPERTIES[2] = false
  end
end
---
local function orc_cb_tr_dly()
  if ORC_TR_PROPERTIES[3] == false then
    vws["ORC_BT_DLY"].color = ORC_CLR.MARKER
    ORC_TR_PROPERTIES[3] = true
  else
    vws["ORC_BT_DLY"].color = ORC_CLR.DEFAULT
    ORC_TR_PROPERTIES[3] = false
  end
end
---
local function orc_cb_tr_sfx()
  if ORC_TR_PROPERTIES[4] == false then
    vws["ORC_BT_SFX"].color = ORC_CLR.MARKER
    ORC_TR_PROPERTIES[4] = true
  else
    vws["ORC_BT_SFX"].color = ORC_CLR.DEFAULT
    ORC_TR_PROPERTIES[4] = false
  end
end



--rename track <--> instrument
local function orc_rename_ti()
  song.selected_instrument.name = song.selected_track.name
end
---
local function orc_rename_it()
  song.selected_track.name = song.selected_instrument.name
end



--modify selected track
local function orc_modify_tr( name, color, color_blend )
  local typ = song.selected_track.type
  local rtr = renoise.Track
  if ( typ == rtr.TRACK_TYPE_SEQUENCER ) then
    local st = song.selected_track
    st.name = ORC_NAME[name]
    st.color = ORC_COLOR[color + 1]
    st.color_blend = ORC_COLOR_BLEND[color_blend]
    st.volume_column_visible = ORC_TR_PROPERTIES[1]
    st.panning_column_visible = ORC_TR_PROPERTIES[2]
    st.delay_column_visible = ORC_TR_PROPERTIES[3]
    st.sample_effects_column_visible = ORC_TR_PROPERTIES[4]
    st.visible_note_columns = ORC_TR_PROPERTIES[5]
    st.visible_effect_columns = ORC_TR_PROPERTIES[6]
  end
end



--insert individual track
local function orc_insert_tr( name, color, color_blend )
  local typ = song.selected_track.type
  local rtr = renoise.Track
  if ( typ == rtr.TRACK_TYPE_SEQUENCER or typ == rtr.TRACK_TYPE_GROUP ) then
    local sti = song.selected_track_index + 1
    song:insert_track_at(sti)
    song.selected_track_index = sti
    local st = song.selected_track
    st.name = ORC_NAME[name]
    st.color = ORC_COLOR[color + 1]
    st.color_blend = ORC_COLOR_BLEND[color_blend]
    st.volume_column_visible = ORC_TR_PROPERTIES[1]
    st.panning_column_visible = ORC_TR_PROPERTIES[2]
    st.delay_column_visible = ORC_TR_PROPERTIES[3]
    st.sample_effects_column_visible = ORC_TR_PROPERTIES[4]
    st.visible_note_columns = ORC_TR_PROPERTIES[5]
    st.visible_effect_columns = ORC_TR_PROPERTIES[6]
  end
end



--rename numbered to insert
local function orc_rename_numbered( v )
  local trs = song.tracks
  local sti = song.selected_track_index
  local nam = trs[ sti ].name
  if ( v == 2 ) then
    trs[ sti - 1 ].name = nam.." 1"
    trs[ sti ].name = nam.." 2"
  end
  if ( v == 3 ) then
    trs[ sti - 2 ].name = nam.." 1"
    trs[ sti - 1 ].name = nam.." 2"
    trs[ sti ].name = nam.." 3"
  end
end



--insert or modify
local ORC_INS_MOD = false
local function orc_ins_mod()
  if ( ORC_INS_MOD == false ) then
    vws["ORC_BT_INS_MOD"].text = "MOD"
    vws["ORC_BT_INS_MOD"].color = ORC_CLR.MARKER
    vws["ORC_BT_INSERT"].active = false
    for i = 1, 1000 do
      if ( vws["ORC_VB_"..i] ~= nil ) then
        vws["ORC_VB_"..i].active = false
      end
    end
    for i = 1, 9 do
      vws["ORC_VALUEBOX_"..i].value = 3
      vws["ORC_VALUEBOX_"..i].value = 1
      vws["ORC_VALUEBOX_"..i].active = false
    end
    ORC_INS_MOD = true
  else
    vws["ORC_BT_INS_MOD"].text = "CRE"
    vws["ORC_BT_INS_MOD"].color = ORC_CLR.DEFAULT
    vws["ORC_BT_INSERT"].active = true
    for i = 1, 1000 do
      if ( vws["ORC_VB_"..i] ~= nil ) then
        vws["ORC_VB_"..i].active = true
      end
    end
    for i = 1, 9 do
      vws["ORC_VALUEBOX_"..i].active = true
    end
    ORC_INS_MOD = false
  end
end



--insert entire group
local function orc_bt_group( name, color, color_blend, v_1, v_2, num_1, num_2, val)
  local typ = song.selected_track.type
  local rtr = renoise.Track
  if ( ORC_INS_MOD == false ) then
    if ( ( typ == rtr.TRACK_TYPE_SEQUENCER or typ == rtr.TRACK_TYPE_GROUP ) and ( vws["ORC_VALUEBOX_"..val].value ~= -1 ) ) then
      local sti = song.selected_track_index + 1
      local num = 0
      if ( ORC_CB[val] == true ) then
        for b = v_1, v_2 do
          local v = vws["ORC_VB_"..b].value
          if ( v > 0 ) then
            for i = 1, v do
              orc_insert_tr(b+1-num_1, b-num_2 + ORC_COLOR_SELECT[val], 2)
            end
            orc_rename_numbered( v )
          end
          num = num + v
        end
      end
      ---
      song:insert_group_at(sti)
      song.selected_track_index = sti
      local sti, st = song.selected_track_index, song.selected_track
      st.name, st.color, st.color_blend = ORC_NAME[name], ORC_COLOR[color], ORC_COLOR_BLEND[color_blend]
      ---
      if ( ORC_CB[val] == true ) then
        for i = 1, num  do
          song:add_track_to_group( sti+i, sti+i-1 )
        end    
        local st = song.selected_track
        if (st.group_parent) then
          st.group_parent.collapsed = true
        end
      end
    end
  else
    if ( typ == rtr.TRACK_TYPE_GROUP ) then
      local st = song.selected_track
      st.name, st.color, st.color_blend = ORC_NAME[name], ORC_COLOR[color], ORC_COLOR_BLEND[color_blend]  
    end
  end
end



--global valuebox per section
local function orc_valuebox( v_main, v_1, v_2, value )
  if ( value ~= -1 ) then
    for i = v_1, v_2 do
      vws["ORC_VB_"..i].value = vws["ORC_VALUEBOX_"..v_main].value
    end
    vws["ORC_BUTTON_"..v_main].active = true
  else
    vws["ORC_BUTTON_"..v_main].active = false
  end
end



--insert individual instrument
local function orc_bt_instrument( v_1, v_2, v_3, num_1 )
  if ( ORC_INS_MOD == false ) then
    local v = vws["ORC_VB_"..v_1+num_1 - 1].value
    if ( v > 0 ) then
      for i = 1, v do
        orc_insert_tr(v_1, v_2, v_3)
      end
      orc_rename_numbered( v )
    end
  else
    orc_modify_tr(v_1, v_2, v_3)
  end
end


--active buttons > 0
function orc_vb_active( value, v )
  if ( value > 0 ) then
    vws["ORC_BT_"..v].active = true
  else
    vws["ORC_BT_"..v].active = false
  end
end



--jump to group
local function orc_jump_gr()
  local parent_index
  local type = song.selected_track.type
  local sti = song.selected_track_index
  if ( song.selected_track.group_parent ) then --if exist group parent
    for i, track in ripairs ( song.tracks ) do
      if ( track.type == renoise.Track.TRACK_TYPE_GROUP ) then
        if ( i - #track.members <= sti and sti < i ) then
          parent_index = i
          --print("i: ",i)
        end
      end
    end
    song.selected_track_index = parent_index
  else
    return
  end
end



--insert all groups
local function orc_insert_all()
  orc_bt_group(001,ORC_COLOR_SELECT[1],1, 001,008, 000,000,1) orc_jump_gr()
  orc_bt_group(011,ORC_COLOR_SELECT[2],1, 101,117, 090,101,2) orc_jump_gr()
  orc_bt_group(031,ORC_COLOR_SELECT[3],1, 201,205, 170,201,3) orc_jump_gr()
  orc_bt_group(041,ORC_COLOR_SELECT[4],1, 301,307, 260,301,4) orc_jump_gr()
  orc_bt_group(051,ORC_COLOR_SELECT[5],1, 401,406, 350,401,5) orc_jump_gr()
  orc_bt_group(061,ORC_COLOR_SELECT[6],1, 501,520, 440,501,6) orc_jump_gr()
  orc_bt_group(091,ORC_COLOR_SELECT[7],1, 601,606, 510,601,7) orc_jump_gr()
  orc_bt_group(101,ORC_COLOR_SELECT[8],1, 701,704, 600,701,8) orc_jump_gr()
  orc_bt_group(111,ORC_COLOR_SELECT[9],1, 801,809, 690,801,9) orc_jump_gr()
end



--delete selected track
local function orc_del_tr()
  local typ = song.selected_track.type
  local rtr = renoise.Track
  local sti = song.selected_track_index
  if ( ( song.sequencer_track_count > 1 and typ ~= rtr.TRACK_TYPE_MASTER ) or ( typ == rtr.TRACK_TYPE_SEND ) ) then
    song:delete_track_at(sti)
  end
end



--rename note columns
-----------------------------------------------------------
local function orc_bt_rename_note_columns()
  if vws['ORC_PP_RENAME_NC'].value == 1 then
    vws['ORC_BT_RENAME_NC'].active = false
  else
    vws['ORC_BT_RENAME_NC'].active = true
  end
end
---
local function orc_rename_note_columns()
  local val = vws["ORC_PP_RENAME_NC"].value
  local column_names
  if ( val == 1 ) then return end
  if ( val == 2 ) then column_names = { "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" } end
  if ( val == 3 ) then column_names = { "Note 01", "Note 02", "Note 03", "Note 04", "Note 05", "Note 06", "Note 07", "Note 08", "Note 09", "Note 10", "Note 11", "Note 12" } end
  if ( val == 4 ) then column_names = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" } end
  if ( val == 5 ) then column_names = { "Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si" } end
  if ( val == 6 ) then column_names = { "C  [Do]", "C#", "D  [Re]", "D#", "E  [Mi]", "F  [Fa]", "F#", "G  [Sol]", "G#", "A  [La]", "A#", "B  [Si]" } end
  if ( val == 7 ) then column_names = { "C  [Do] 01", "C#  02", "D  [Re] 03 ", "D#  04", "E  [Mi] 05", "F  [Fa] 06", "F#  07", "G  [Sol] 08", "G#  09", "A  [La] 10", "A#  11", "B  [Si] 12" } end
  if ( val == 8 ) then column_names = { "01 C  [Do]", "02 C#", "03 D  [Re]", "04 D#", "05 E  [Mi]", "06 F  [Fa]", "07 F#", "08 G  [Sol]", "09 G#", "10 A  [La]", "11 A#", "12 B  [Si]" } end
  if ( val == 9 ) then column_names = { "C", "D", "E", "F", "G", "A", "B", "===", "===", "===", "===", "===" } end
  if ( val ==10 ) then column_names = { "Ch1", "Ch2", "Ch3", "Ch4", "Ch5", "Ch6", "Ch7", "===", "===", "===", "===", "===" } end
  if ( val ==11 ) then column_names = { "", "", "", "", "", "", "", "", "", "", "", "" } end --default (Note)
  ---
  if ( song.selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER ) then
    for note_column = 1, 12 do
      song.selected_track:set_column_name( note_column , column_names[ note_column ] )
    end
  end
end
---
local ORC_RENAME_NOTE_COLUMNS = vb:row { spacing = -3,
  vb:popup { id = "ORC_PP_RENAME_NC", height = 21, width = 184, value = 1, notifier = function() orc_bt_rename_note_columns() end, tooltip = "Rename note columns selector",
    items = { " Nothing"," 01 until 12"," Note 01 until Note 12"," C until B"," Do until Si"," C [Do] until B [Si]", " C [Do] 01 until B [Si] 12",
              " 01 C [Do] until 12 B [Si]"," C until B (without #)"," Chord up to 7 notes"," Default (Note)"
    }
  },
  vb:button { id = "ORC_BT_RENAME_NC", height = 21, width = 31, active = false, text = "Rn", notifier = function() orc_rename_note_columns() end,
    tooltip = "Rename note columns in selected track according to the choice"
  }
}



--compact mode
local ORC_COMPACT = true
local function orc_compact()
  if ( ORC_COMPACT == true ) then
    vws["ORC_BT_COMPACT"].bitmap = "./icons/compact_off_ico.png"
    vws["ORC_BT_COMPACT"].tooltip = "Expand Orchestral"
    vws["ORC_MAIN_PANEL_1"].visible = false
    vws["ORC_MAIN_PANEL_2"].visible = false
    vws["ORC_RW_INS"].visible = false
    vws["ORC_SPC_TOP"].visible = false
    ORC_COMPACT = false
  else
    vws["ORC_BT_COMPACT"].bitmap = "./icons/compact_on_ico.png"
    vws["ORC_BT_COMPACT"].tooltip = "Compact Orchestral"
    vws["ORC_MAIN_PANEL_1"].visible = true
    vws["ORC_MAIN_PANEL_2"].visible = true
    vws["ORC_RW_INS"].visible = true
    vws["ORC_SPC_TOP"].visible = true
    ORC_COMPACT = true
  end
end



--color selector
local ORC_MAIN_SELECT_COLOR = vb:column { id = "ORC_MAIN_SELECT_COLOR", visible = false,
  vb:row { spacing = 1,
    vb:popup { id = "ORC_PP_SELECT_COLOR", height = 27, width = 124, value = 1, notifier = function(v) orc_bt_rename_note_columns() orc_pp_change_frame(v) end, tooltip = "Group selector",
      items = { " Strings", " Winds", " Brass", " Keyboards", " Guitars", " Percussion", " Battery", " Chorus", " Voices", 
      }
    },
    vb:row { spacing = -1059, 
      vb:row { spacing = -3,
        vb:button { id = "ORC_FRAME_1",  height = 27, width = 69, active = false }, -- 1
        vb:button { id = "ORC_FRAME_2",  height = 27, width = 69, active = false }, -- 2
        vb:button { id = "ORC_FRAME_3",  height = 27, width = 69, active = false }, -- 3
        vb:button { id = "ORC_FRAME_4",  height = 27, width = 69, active = false }, -- 4
        vb:button { id = "ORC_FRAME_5",  height = 27, width = 69, active = false }, -- 5
        vb:button { id = "ORC_FRAME_6",  height = 27, width = 69, active = false }, -- 6
        vb:button { id = "ORC_FRAME_7",  height = 27, width = 69, active = false }, -- 7
        vb:button { id = "ORC_FRAME_8",  height = 27, width = 69, active = false }, -- 8
        vb:button { id = "ORC_FRAME_9",  height = 27, width = 69, active = false }, -- 9
        vb:button { id = "ORC_FRAME_10", height = 27, width = 69, active = false }, --10
        vb:button { id = "ORC_FRAME_11", height = 27, width = 69, active = false }, --11
        vb:button { id = "ORC_FRAME_12", height = 27, width = 69, active = false, color = ORC_CLR.MARKER }, --12
        vb:button { id = "ORC_FRAME_13", height = 27, width = 69, active = false }, --13
        vb:button { id = "ORC_FRAME_14", height = 27, width = 69, active = false }, --14
        vb:button { id = "ORC_FRAME_15", height = 27, width = 69, active = false }, --15
        vb:button { id = "ORC_FRAME_16", height = 27, width = 69, active = false }, --16
      },
      vb:row { margin = 5, spacing = 7, --AQ , BK , BL , BR , GL , GY , GR , OR , PL , PN , PS , RD , SK , VL , WH , YL
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[003], text =  "1", notifier = function() orc_bt_clr_select(1)   orc_bt_change_frame(1) end, tooltip = "Aqua color" } },       -- 1
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[033], text =  "2", notifier = function() orc_bt_clr_select(31)  orc_bt_change_frame(2) end, tooltip = "Black color" } },      -- 2
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[063], text =  "3", notifier = function() orc_bt_clr_select(61)  orc_bt_change_frame(3) end, tooltip = "Blue color" } },       -- 3
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[093], text =  "4", notifier = function() orc_bt_clr_select(91)  orc_bt_change_frame(4) end, tooltip = "Brown color" } },      -- 4
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[123], text =  "5", notifier = function() orc_bt_clr_select(121) orc_bt_change_frame(5) end, tooltip = "Gold color" } },       -- 5
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[153], text =  "6", notifier = function() orc_bt_clr_select(151) orc_bt_change_frame(6) end, tooltip = "Grey color" } },       -- 6
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[183], text =  "7", notifier = function() orc_bt_clr_select(181) orc_bt_change_frame(7) end, tooltip = "Green color" } },      -- 7
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[213], text =  "8", notifier = function() orc_bt_clr_select(211) orc_bt_change_frame(8) end, tooltip = "Orange color" } },     -- 8
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[243], text =  "9", notifier = function() orc_bt_clr_select(241) orc_bt_change_frame(9) end, tooltip = "Pale Pink color" } },  -- 9
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[273], text = "10", notifier = function() orc_bt_clr_select(271) orc_bt_change_frame(10) end, tooltip = "Pink color" } },      --10
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[303], text = "11", notifier = function() orc_bt_clr_select(301) orc_bt_change_frame(11) end, tooltip = "Pistachio color" } }, --11
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[333], text = "12", notifier = function() orc_bt_clr_select(331) orc_bt_change_frame(12) end, tooltip = "Red color" } },       --12
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[363], text = "13", notifier = function() orc_bt_clr_select(361) orc_bt_change_frame(13) end, tooltip = "Sky Blue color" } },  --13
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[393], text = "14", notifier = function() orc_bt_clr_select(391) orc_bt_change_frame(14) end, tooltip = "Violet color" } },    --14
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[423], text = "15", notifier = function() orc_bt_clr_select(421) orc_bt_change_frame(15) end, tooltip = "White color" } },     --15
        vb:row { margin = -2, vb:button { height = 21, width = 63, color = ORC_COLOR[453], text = "16", notifier = function() orc_bt_clr_select(451) orc_bt_change_frame(16) end, tooltip = "Yellow color" } },    --16
      }
    }
  },
  vb:space { height = 3 }
}



--GUI
-------------------------------------------------------------------------------
local ORC_STRINGS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_1", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[1] + 2 ], notifier = function() orc_bt_clr_direct(1) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_1", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_1", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(1,1,8, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_1", height = 32, width = 335, color = ORC_CLR_CT[1], text = "STRINGS", notifier = function() orc_bt_group(1,ORC_COLOR_SELECT[1],1, 1,8, 0,0,1) orc_search_frame(1) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_1", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(1,1) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_1", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_1", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,1) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_1", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Solo String",
          notifier = function() orc_bt_instrument(2,ORC_COLOR_SELECT[1]+1,2,0) end,
          tooltip = "Insert track 'Solo String' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_2", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,2) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_2", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Violins",
          notifier = function() orc_bt_instrument(3,ORC_COLOR_SELECT[1]+2,2,0) end,
          tooltip = "Insert track 'Violins' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_3", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,3) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_3", height = 23, width = 123, color = ORC_CLR_CT[1], text = "1st Violins",
          notifier = function() orc_bt_instrument(4,ORC_COLOR_SELECT[1]+3,2,0) end,
          tooltip = "Insert track '1st Violins' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_4", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,4) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_4", height = 23, width = 123, color = ORC_CLR_CT[1], text = "2st Violins",
          notifier = function() orc_bt_instrument(5,ORC_COLOR_SELECT[1]+4,2,0) end,
          tooltip = "Insert track '2st Violins' / Modify the selected track"
        } },
      }
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_5", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,5) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_5", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Violas",
          notifier = function() orc_bt_instrument(6,ORC_COLOR_SELECT[1]+5,2,0) end,
          tooltip = "Insert track 'Violas' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_6", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,6) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_6", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Cellos",
          notifier = function() orc_bt_instrument(7,ORC_COLOR_SELECT[1]+6,2,0) end,
          tooltip = "Insert track 'Cellos' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_7", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,7) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_7", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Double Basses",
          notifier = function() orc_bt_instrument(8,ORC_COLOR_SELECT[1]+7,2,0) end,
          tooltip = "Insert track 'Double Basses' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_8", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,8) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_8", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Harp",
          notifier = function() orc_bt_instrument(9,ORC_COLOR_SELECT[1]+8,2,0) end,
          tooltip = "Insert track 'Harp' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_2", visible = true, active = true,
    height = 86, width = 335, bitmap = "./icons/strings_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[1] + 2 ], notifier = function() orc_cb(1,1) end,
    tooltip = "Show instruments of strings "
  }
  ---
}



local ORC_WINDS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_2", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[2] + 2 ], notifier = function() orc_bt_clr_direct(2) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_2", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_2", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(2,101,117, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_2", height = 32, width = 335, color = ORC_CLR_CT[1], text = "WINDS", notifier = function() orc_bt_group(11,ORC_COLOR_SELECT[2],1, 101,117, 90,101,2 ) orc_search_frame(2) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_2", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(2,3) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_3", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_101", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,101) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_101", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Solo Wind",
          notifier = function() orc_bt_instrument(12,ORC_COLOR_SELECT[2]+1,2,90) end,
          tooltip = "Insert track 'Solo Wind' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_102", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,102) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_102", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Alto Flute",
          notifier = function() orc_bt_instrument(13,ORC_COLOR_SELECT[2]+2,2,90) end,
          tooltip = "Insert track 'Alto Flute' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_103", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,103) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_103", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bass Flute",
          notifier = function() orc_bt_instrument(14,ORC_COLOR_SELECT[2]+3,2,90) end,
          tooltip = "Insert track 'Bass Flute' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_104", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,104) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_104", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Piccolo",
          notifier = function() orc_bt_instrument(15,ORC_COLOR_SELECT[2]+4,2,90) end,
          tooltip = "Insert track 'Piccolo' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_105", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,105) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_105", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Oboe",
          notifier = function() orc_bt_instrument(16,ORC_COLOR_SELECT[2]+5,2,90) end,
          tooltip = "Insert track 'Oboe' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_106", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,106) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_106", height = 23, width = 123, color = ORC_CLR_CT[1], text = "English Horn",
          notifier = function() orc_bt_instrument(17,ORC_COLOR_SELECT[2]+6,2,90) end,
          tooltip = "Insert track 'English Horn' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_107", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,107) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_107", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Clarinet",
          notifier = function() orc_bt_instrument(18,ORC_COLOR_SELECT[2]+7,2,90) end,
          tooltip = "Insert track 'Clarinet' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_108", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,108) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_108", height = 23, width = 123, color = ORC_CLR_CT[1], text = "E-flat Clarinet",
          notifier = function() orc_bt_instrument(19,ORC_COLOR_SELECT[2]+8,2,90) end,
          tooltip = "Insert track 'E-flat Clarinet' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_109", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,109) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_109", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bass Clarinet",
          notifier = function() orc_bt_instrument(20,ORC_COLOR_SELECT[2]+9,2,90) end,
          tooltip = "Insert track 'Bass Clarinet' / Modify the selected track"
        } },
      },
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_110", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,110) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_110", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bassoon",
          notifier = function() orc_bt_instrument(21,ORC_COLOR_SELECT[2]+10,2,90) end,
          tooltip = "Insert track 'Bassoon' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_111", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,111) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_111", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Double Bassoon",
          notifier = function() orc_bt_instrument(22,ORC_COLOR_SELECT[2]+11,2,90) end,
          tooltip = "Insert track 'Double Bassoon' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_112", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,112) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_112", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Flugelhorn",
          notifier = function() orc_bt_instrument(23,ORC_COLOR_SELECT[2]+12,2,90) end,
          tooltip = "Insert track 'Flugelhorn' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_113", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,113) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_113", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Saxophone",
          notifier = function() orc_bt_instrument(24,ORC_COLOR_SELECT[2]+13,2,90) end,
          tooltip = "Insert track 'Saxophone' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_114", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,114) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_114", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bagpipe",
          notifier = function() orc_bt_instrument(25,ORC_COLOR_SELECT[2]+14,2,90) end,
          tooltip = "Insert track 'Bagpipe' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_115", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,115) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_115", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Shakuhachi",
          notifier = function() orc_bt_instrument(26,ORC_COLOR_SELECT[2]+15,2,90) end,
          tooltip = "Insert track 'Shakuhachi' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_116", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,116) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_116", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Cornet",
          notifier = function() orc_bt_instrument(27,ORC_COLOR_SELECT[2]+16,2,90) end,
          tooltip = "Insert track 'Cornet' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_117", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,117) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_117", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Harmonica",
          notifier = function() orc_bt_instrument(28,ORC_COLOR_SELECT[2]+17,2,90) end,
          tooltip = "Insert track 'Harmonica' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_4", visible = true, active = true, 
    height = 191, width = 335, bitmap = "./icons/winds_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[2] + 2 ], notifier = function() orc_cb(2,3) end,
     tooltip = "Show instruments of winds"
  }
  ---
}



local ORC_BRASS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_3", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[3] + 2 ], notifier = function() orc_bt_clr_direct(3) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_3", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_3", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(3,201,205, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_3", height = 32, width = 335, color = ORC_CLR_CT[1], text = "BRASS", notifier = function() orc_bt_group(31,ORC_COLOR_SELECT[3],1, 201,205, 170,201,3) orc_search_frame(3) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_3", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(3,5) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_5", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_201", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,201) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_201", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Solo Brass",
          notifier = function() orc_bt_instrument(32,ORC_COLOR_SELECT[3]+1,2,170) end,
          tooltip = "Insert track 'Solo Brass' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_202", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,202) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_202", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Trumpets",
          notifier = function() orc_bt_instrument(33,ORC_COLOR_SELECT[3]+2,2,170) end,
          tooltip = "Insert track 'Trumpets' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_203", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,203) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_203", height = 23, width = 123, color = ORC_CLR_CT[1], text = "French Horn",
          notifier = function() orc_bt_instrument(34,ORC_COLOR_SELECT[3]+3,2,170) end,
          tooltip = "Insert track 'French Horn' / Modify the selected track"
        } },
      }
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_204", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,204) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_204", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Trombones",
          notifier = function() orc_bt_instrument(35,ORC_COLOR_SELECT[3]+4,2,170) end,
          tooltip = "Insert track 'Trombones' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_205", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,205) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_205", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Tuba",
          notifier = function() orc_bt_instrument(36,ORC_COLOR_SELECT[3]+5,2,170) end,
          tooltip = "Insert track 'Tuba' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_6", visible = true, active = true,
    height = 65, width = 335, bitmap = "./icons/brass_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[3] + 2 ], notifier = function() orc_cb(3,5) end,
    tooltip = "Show instruments of brass"
  }
  ---
}



local ORC_KEYBOARDS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_4", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[4] + 2 ], notifier = function() orc_bt_clr_direct(4) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_4", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_4", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(4,301,307, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_4", height = 32, width = 335, color = ORC_CLR_CT[1], text = "KEYBOARDS", notifier = function() orc_bt_group(41,ORC_COLOR_SELECT[4],1, 301,307, 260,301,4) orc_search_frame(4) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_4", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(4,7) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_7", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_301", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,301) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_301", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Piano",
          notifier = function() orc_bt_instrument(42,ORC_COLOR_SELECT[4]+1,2,260) end,
          tooltip = "Insert track 'Piano' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_302", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,302) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_302", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Synthesizer",
          notifier = function() orc_bt_instrument(43,ORC_COLOR_SELECT[4]+2,2,260) end,
          tooltip = "Insert track 'Synthesizer' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_303", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,303) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_303", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Organ",
          notifier = function() orc_bt_instrument(44,ORC_COLOR_SELECT[4]+3,2,260) end,
          tooltip = "Insert track 'Organ' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_304", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,304) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_304", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Celesta",
          notifier = function() orc_bt_instrument(45,ORC_COLOR_SELECT[4]+4,2,260) end,
          tooltip = "Insert track 'Celesta' / Modify the selected track"
        } },
      }
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_305", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,305) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_305", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Clavichord",
          notifier = function() orc_bt_instrument(46,ORC_COLOR_SELECT[4]+5,2,260) end,
          tooltip = "Insert track 'Clavichord' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_306", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,306) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_306", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Harpsichord",
          notifier = function() orc_bt_instrument(47,ORC_COLOR_SELECT[4]+6,2,260) end,
          tooltip = "Insert track 'Harpsichord' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_307", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,307) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_307", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Accordion",
          notifier = function() orc_bt_instrument(48,ORC_COLOR_SELECT[4]+7,2,260) end,
          tooltip = "Insert track 'Accordion' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_8", visible = true, active = true,
    height = 86, width = 335, bitmap = "./icons/keyboards_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[4] + 2 ], notifier = function() orc_cb(4,7) end,
    tooltip = "Show instruments of keyboards"
  }
  ---
}


local ORC_GUITARS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_5", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[5] + 2 ], notifier = function() orc_bt_clr_direct(5) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_5", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_5", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(5,401,407, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_5", height = 32, width = 335, color = ORC_CLR_CT[1], text = "GUITARS", notifier = function() orc_bt_group(51,ORC_COLOR_SELECT[5],1, 401,407, 350,401,5) orc_search_frame(5) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_5", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(5,9) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_9", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_401", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,401) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_401", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Electric Guitar",
          notifier = function() orc_bt_instrument(52,ORC_COLOR_SELECT[5]+1,2,350) end,
          tooltip = "Insert track 'Electric Guitar' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_402", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,402) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_402", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Electric Bass Gu.",
        notifier = function() orc_bt_instrument(53,ORC_COLOR_SELECT[5]+2,2,350) end,
          tooltip = "Insert track 'Electric Bass Guitar' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_403", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,403) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_403", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Acoustic Guitar",
        notifier = function() orc_bt_instrument(54,ORC_COLOR_SELECT[5]+3,2,350) end,
          tooltip = "Insert track 'Acoustic Guitar' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_404", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,404) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_404", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Mandolin",
        notifier = function() orc_bt_instrument(55,ORC_COLOR_SELECT[5]+4,2,350) end,
          tooltip = "Insert track 'Mandolin' / Modify the selected track"
        } },
      },
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_405", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,405) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_405", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Banjo",
        notifier = function() orc_bt_instrument(56,ORC_COLOR_SELECT[5]+5,2,350) end,
          tooltip = "Insert track 'Banjo' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_406", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,406) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_406", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bandurria",
        notifier = function() orc_bt_instrument(57,ORC_COLOR_SELECT[5]+6,2,350) end,
          tooltip = "Insert track 'Bandurria' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_407", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,407) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_407", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Lute",
        notifier = function() orc_bt_instrument(58,ORC_COLOR_SELECT[5]+7,2,350) end,
          tooltip = "Insert track 'Lute' / Modify the selected track"
        } },
      }
    },
  },
  ---
  vb:button { id = "ORC_PANEL_10", visible = true, active = true,
    height = 91, width = 335, bitmap = "./icons/guitars_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[5] + 2 ], notifier = function() orc_cb(5,9) end,
    tooltip = "Show instruments of guitars"
  }
  ---
}



local ORC_PERCUSSION = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_6", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[6] + 2 ], notifier = function() orc_bt_clr_direct(6) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_6", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_6", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(6,501,520, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_6", height = 32, width = 335, color = ORC_CLR_CT[1], text = "PERCUSSION", notifier = function() orc_bt_group(61,ORC_COLOR_SELECT[6],1, 501,520, 440,501,6) orc_search_frame(6) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_6", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(6,11) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_11", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_501", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,501) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_501", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Tubular Bells",
          notifier = function() orc_bt_instrument(62,ORC_COLOR_SELECT[6]+1,2,440) end,
          tooltip = "Insert track 'Tubular Bells' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_502", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,502) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_502", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Vibraphone",
          notifier = function() orc_bt_instrument(63,ORC_COLOR_SELECT[6]+2,2,440) end,
          tooltip = "Insert track 'Vibraphone' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_503", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,503) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_503", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Xylophone",
          notifier = function() orc_bt_instrument(64,ORC_COLOR_SELECT[6]+3,2,440) end,
          tooltip = "Insert track 'Xylophone' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_504", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,504) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_504", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Glockenspiel",
          notifier = function() orc_bt_instrument(65,ORC_COLOR_SELECT[6]+4,2,440) end,
          tooltip = "Insert track 'Glockenspiel' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_505", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,505) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_505", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Marimba",
          notifier = function() orc_bt_instrument(66,ORC_COLOR_SELECT[6]+5,2,440) end,
          tooltip = "Insert track 'Marimba' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_506", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,506) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_506", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Hammer",
          notifier = function() orc_bt_instrument(67,ORC_COLOR_SELECT[6]+6,2,440) end,
          tooltip = "Insert track 'Hammer' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_507", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,507) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_507", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Triangle",
          notifier = function() orc_bt_instrument(68,ORC_COLOR_SELECT[6]+7,2,440) end,
          tooltip = "Insert track 'Triangle' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_508", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,508) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_508", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Chimes",
          notifier = function() orc_bt_instrument(69,ORC_COLOR_SELECT[6]+8,2,440) end,
          tooltip = "Insert track 'Chimes' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_509", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,509) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_509", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Maracas",
          notifier = function() orc_bt_instrument(70,ORC_COLOR_SELECT[6]+9,2,440) end,
          tooltip = "Insert track 'Maracas' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_510", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,510) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_510", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Castanets",
          notifier = function() orc_bt_instrument(71,ORC_COLOR_SELECT[6]+10,2,440) end,
          tooltip = "Insert track 'Castanets' / Modify the selected track"
        } },
      }
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_511", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,511) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_511", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Wooden-block",
          notifier = function() orc_bt_instrument(72,ORC_COLOR_SELECT[6]+11,2,440) end,
          tooltip = "Insert track 'Wooden-block' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_512", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,512) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_512", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Claves",
          notifier = function() orc_bt_instrument(73,ORC_COLOR_SELECT[6]+12,2,440) end,
          tooltip = "Insert track 'Claves' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_513", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,513) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_513", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Tambourine",
          notifier = function() orc_bt_instrument(74,ORC_COLOR_SELECT[6]+13,2,440) end,
          tooltip = "Insert track 'Tambourine' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_514", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,514) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_514", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Cymbals",
          notifier = function() orc_bt_instrument(75,ORC_COLOR_SELECT[6]+14,2,440) end,
          tooltip = "Insert track 'Cymbals' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_515", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,515) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_515", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Side Drum",
          notifier = function() orc_bt_instrument(76,ORC_COLOR_SELECT[6]+15,2,440) end,
          tooltip = "Insert track 'Side Drum' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_516", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,516) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_516", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Gongs",
          notifier = function() orc_bt_instrument(77,ORC_COLOR_SELECT[6]+16,2,440) end,
          tooltip = "Insert track 'Gongs' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_517", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,517) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_517", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Timpani",
          notifier = function() orc_bt_instrument(78,ORC_COLOR_SELECT[6]+17,2,440) end,
          tooltip = "Insert track 'Timpani' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_518", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,518) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_518", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Congas",
          notifier = function() orc_bt_instrument(79,ORC_COLOR_SELECT[6]+18,2,440) end,
          tooltip = "Insert track 'Congas' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_519", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,519) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_519", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Tenor Drum",
          notifier = function() orc_bt_instrument(80,ORC_COLOR_SELECT[6]+19,2,440) end,
          tooltip = "Insert track 'Tenor Drum' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_520", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,520) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_520", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bass Drum",
          notifier = function() orc_bt_instrument(81,ORC_COLOR_SELECT[6]+20,2,440) end,
          tooltip = "Insert track 'Bass Drum' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_12", visible = true, active = true,
    height = 212, width = 335, bitmap = "./icons/percussion_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[6] + 2 ], notifier = function() orc_cb(6,11) end,
    tooltip = "Show instruments of percussion"
  }
  ---
}



local ORC_BATTERY = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_7", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[7] + 2 ], notifier = function() orc_bt_clr_direct(7) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_7", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_7", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(7,601,606, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_7", height = 32, width = 335, color = ORC_CLR_CT[1], text = "BATTERY", notifier = function() orc_bt_group(91,ORC_COLOR_SELECT[7],1, 601,606, 510,601,7) orc_search_frame(7) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_7", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(7,13) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_13", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_601", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,601) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_601", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Cymbal",
          notifier = function() orc_bt_instrument(92,ORC_COLOR_SELECT[7]+1,2,510) end,
          tooltip = "Insert track 'Cymbal' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_602", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,602) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_602", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Hi-hat",
          notifier = function() orc_bt_instrument(93,ORC_COLOR_SELECT[7]+2,2,510) end,
          tooltip = "Insert track 'Hi-hat' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_603", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,603) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_603", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Snare Drum",
          notifier = function() orc_bt_instrument(94,ORC_COLOR_SELECT[7]+3,2,510) end,
          tooltip = "Insert track 'Snare Drum' / Modify the selected track"
        } },
      }
    },
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_604", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,604) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_604", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Toms",
          notifier = function() orc_bt_instrument(95,ORC_COLOR_SELECT[7]+4,2,510) end,
          tooltip = "Insert track 'Toms' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_605", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,605) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_605", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Floor Tom",
          notifier = function() orc_bt_instrument(96,ORC_COLOR_SELECT[7]+5,2,510) end,
          tooltip = "Insert track 'Floor Tom' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_606", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,606) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_606", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bass Drum",
          notifier = function() orc_bt_instrument(97,ORC_COLOR_SELECT[7]+6,2,510) end,
          tooltip = "Insert track 'Bass Drum' / Modify the selected track"
        } },
      },
    }
  },
  ---
  vb:button { id = "ORC_PANEL_14", visible = true, active = true,
    height = 65, width = 335, bitmap = "./icons/battery_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[7] + 2 ], notifier = function() orc_cb(7,13) end,
    tooltip = "Show instruments of battery"
  }
  ---
}



local ORC_CHORUS = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_8", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[8] + 2 ], notifier = function() orc_bt_clr_direct(8) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_8", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_8", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(8,701,704, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_8", height = 32, width = 167, color = ORC_CLR_CT[1], text = "CHORUS", notifier = function() orc_bt_group(101,ORC_COLOR_SELECT[8],1, 701,704, 600,701,8) orc_search_frame(8) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_8", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(8,15) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row {  id = "ORC_PANEL_15", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_701", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,701) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_701", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Women Chorus",
          notifier = function() orc_bt_instrument(102,ORC_COLOR_SELECT[8]+1,2,600) end,
          tooltip = "Insert track 'Women Chorus' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_702", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,702) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_702", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Men Chorus",
          notifier = function() orc_bt_instrument(103,ORC_COLOR_SELECT[8]+2,2,600) end,
          tooltip = "Insert track 'Men Chorus' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_703", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,703) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_703", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Children Chorus",
          notifier = function() orc_bt_instrument(104,ORC_COLOR_SELECT[8]+3,2,600) end,
          tooltip = "Insert track 'Children Chorus' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_704", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,704) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_704", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Mixed Chorus",
          notifier = function() orc_bt_instrument(105,ORC_COLOR_SELECT[8]+4,2,600) end,
          tooltip = "Insert track 'Mixed Chorus' / Modify the selected track"
        } },
      }
    },
  },
  ---
  vb:button { id = "ORC_PANEL_16", visible = true, active = true,
    height = 86, width = 167, bitmap = "./icons/chorus_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[8] + 2 ], notifier = function() orc_cb(8,15) end,
    tooltip = "Show instruments of chorus"
  }
  ---
}



local ORC_VOICES = vb:column { spacing = -3,
  vb:row { spacing = -3,
    vb:button { id = "ORC_BT_CLR_9", visible = false, height = 32, width = 19, color = ORC_COLOR[ ORC_COLOR_SELECT[9] + 2 ], notifier = function() orc_bt_clr_direct(9) end,
      tooltip = "Show color selector to change the main color to entire group"
    },
    vb:row { id = "ORC_MAIN_VALUEBOX_9", visible = false, margin = 2,
      vb:row { margin = -2, vb:valuebox { id = "ORC_VALUEBOX_9", height = 32, width = 31, min = -1, max = 3, value = 1, 
        tostring = function( value ) if ( value == -1 ) then return "n/a" end return (" %.1d"):format( value ) end,
        tonumber = function( value ) return tonumber( value ) end,
        notifier = function( value ) orc_valuebox(9,801,809, value) end,
      } }
    },
    vb:button { id = "ORC_BUTTON_9", height = 32, width = 167, color = ORC_CLR_CT[1], text = "VOICES", notifier = function() orc_bt_group(111,ORC_COLOR_SELECT[9],1, 801,809, 690,801,9) orc_search_frame(9) end,
      tooltip = "Insert only the group / Modify the selected group"
    },
    vb:button { id = "ORC_CHECKBOX_9", visible = false, height = 32, width = 31, bitmap = "./icons/close_ico.png", notifier = function() orc_cb(9,17) end, tooltip = "Close the instruments panel" },
  },
  vb:space { height = 5 },
  vb:row { id = "ORC_PANEL_17", visible = false, margin = 2, spacing = 5,
    vb:column { spacing = 2,
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_801", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,801) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_801", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Singer",
          notifier = function() orc_bt_instrument(112,ORC_COLOR_SELECT[9]+1,2,690) end,
          tooltip = "Insert track 'Singer' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_802", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,802) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_802", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Alto",
          notifier = function() orc_bt_instrument(113,ORC_COLOR_SELECT[9]+2,2,690) end,
          tooltip = "Insert track 'Alto' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_803", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,803) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_803", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Soprano",
          notifier = function() orc_bt_instrument(114,ORC_COLOR_SELECT[9]+3,2,690) end,
          tooltip = "Insert track 'Soprano' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_804", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,804) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_804", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Mezzo-Soprano",
          notifier = function() orc_bt_instrument(115,ORC_COLOR_SELECT[9]+4,2,690) end,
          tooltip = "Insert track 'Mezzo-Soprano' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_805", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,805) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_805", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Contralto",
          notifier = function() orc_bt_instrument(116,ORC_COLOR_SELECT[9]+5,2,690) end,
          tooltip = "Insert track 'Contralto' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_806", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,806) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_806", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Countertenor",
          notifier = function() orc_bt_instrument(117,ORC_COLOR_SELECT[9]+6,2,690) end,
          tooltip = "Insert track 'Countertenor' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_807", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,807) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_807", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Tenor",
          notifier = function() orc_bt_instrument(118,ORC_COLOR_SELECT[9]+7,2,690) end,
          tooltip = "Insert track 'Tenor' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_808", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,808) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_808", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Baritone",
          notifier = function() orc_bt_instrument(119,ORC_COLOR_SELECT[9]+8,2,690) end,
          tooltip = "Insert track 'Baritone' / Modify the selected track"
        } },
      },
      vb:row { spacing = -1,
        vb:row { margin = -2, vb:valuebox { id = "ORC_VB_809", height = 23, width = 49, min = 0, max = 3, value = 1,
          tostring = function( value ) return ("%.1d"):format( value ) end,
          tonumber = function( value ) return tonumber( value ) end,
          notifier = function( value ) orc_vb_active(value,809) end,
        } },
        vb:row { margin = -2, vb:button { id = "ORC_BT_809", height = 23, width = 123, color = ORC_CLR_CT[1], text = "Bass Voice",
          notifier = function() orc_bt_instrument(120,ORC_COLOR_SELECT[9]+9,2,690) end,
          tooltip = "Insert track 'Bass Voice' / Modify the selected track"
        } },
      },
    },
  },
  ---
  vb:button { id = "ORC_PANEL_18", visible = true, active = true,
    height = 191, width = 167, bitmap = "./icons/voices_ico.png", color = ORC_COLOR[ ORC_COLOR_SELECT[9] + 2 ], notifier = function() orc_cb(9,17) end,
    tooltip = "Show instruments of voices"
  }
  --- 
}



local function orc_main_content()
  ORC_MAIN_CONTENT = vb:column { style = "plain", margin = 3, spacing = 3,
    vb:row { spacing = 8,
      vb:row { spacing = 1,
        vb:row { spacing = -3,
          vb:button { height = 21, width = 42, bitmap = "./icons/left_ico.png", notifier = function() renoise.song():select_previous_track() end, tooltip = "Previous track\n[SHIFT+TAB]" },
          vb:button { height = 21, width = 42, bitmap = "./icons/right_ico.png", notifier = function() renoise.song():select_next_track() end, tooltip = "Next track\n[TAB]" }
        },
        vb:button { height = 21, width = 42, bitmap = "./icons/jump_gr_ico.png", notifier = function() orc_jump_gr() end, tooltip = "Jump to group parent" },
      },
      vb:row { id = "ORC_MAIN_PANEL_1", spacing = 8, visible = true,
        vb:row { spacing = -3,
          vb:valuebox { height = 21, width = 71, min = 1, max = 12, value = 1,
            tostring = function( value ) return ("%.2d NC"):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function(value) ORC_TR_PROPERTIES[5] = value end, tooltip = "Note columns for tracks to insert ( 01 to 12 )"
          },
          vb:space { width = 7 },
          vb:button { id = "ORC_BT_VOL", height = 21, width = 41, text = "VOL", color = ORC_CLR.MARKER, notifier = function() orc_cb_tr_vol() end, tooltip = "Show/hide the volume column to insert" },
          vb:button { id = "ORC_BT_PAN", height = 21, width = 41, text = "PAN", notifier = function() orc_cb_tr_pan() end, tooltip = "Show/hide the panning column to insert" },
          vb:button { id = "ORC_BT_DLY", height = 21, width = 41, text = "DLY", notifier = function() orc_cb_tr_dly() end, tooltip = "Show/hide the delay column to insert" },
          vb:button { id = "ORC_BT_SFX", height = 21, width = 41, text = "SFX", notifier = function() orc_cb_tr_sfx() end, tooltip = "Show/hide the sample effects column to insert" },
          vb:space { width = 7 },
          vb:valuebox { height = 21, width = 63, min = 0, max = 8, value = 0,
            tostring = function( value ) return ("%.1d FX"):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) ORC_TR_PROPERTIES[6] = value end, tooltip = "FX columns for tracks to insert ( 0 to 8 )"
          }
        },
        vb:row { spacing = 1,
          vb:button { id = "ORC_BT_COL", height = 21, width = 31, bitmap = "./icons/color_selector_on_ico.png", notifier = function() orc_color_compact() end,
            tooltip = "Show color selector"
          },
          vb:valuebox { height = 21, width = 71, min = 0, max = 99, value = ORC_COLOR_BLEND[1],
            tostring = function( value ) return ("%.2d Gr"):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) if ( value > 50 ) then value = value + 1 end ORC_COLOR_BLEND[1] = value end, tooltip = "Color blend for groups to insert ( 00 to 99, default = 35 )"
          },
          vb:valuebox { height = 21, width = 71, min = 0, max = 99, value = ORC_COLOR_BLEND[2],
            tostring = function( value ) return ("%.2d Tr"):format( value ) end,
            tonumber = function( value ) return tonumber( value ) end,
            notifier = function( value ) if ( value > 50 ) then value = value + 1 end ORC_COLOR_BLEND[2] = value end, tooltip = "Color blend for tracks to insert ( 00 to 99, default = 20 )"
          }
        }
      },
      ORC_RENAME_NOTE_COLUMNS,
      vb:row { spacing = -1,
        vb:button { height = 21, width = 69, bitmap = "./icons/tr_ins_ico.png", notifier = function() orc_rename_ti() end, tooltip = "Rename the selected instrument by the name of the selected track." },
        vb:button { height = 21, width = 69, bitmap = "./icons/ins_tr_ico.png", notifier = function() orc_rename_it() end, tooltip = "Rename the selected track by the name of the selected instrument." }
      },
      vb:row { spacing = 1,
        vb:row { spacing = -3,
          vb:button { height = 21, width = 42, bitmap = "./icons/undo_ico.png", notifier = function() song:undo() end, tooltip = "Undo\n[CTRL+Z]" },
          vb:button { height = 21, width = 42, bitmap = "./icons/redo_ico.png", notifier = function() song:redo() end, tooltip = "Redo\n[CTRL+Y]" }
 
        },
        vb:button { height = 21, width = 42, text = "DEL", notifier = function() orc_del_tr() end, tooltip = "Delete the selected track/group/send" },
      },
      vb:row {
        id="ORC_SPC_TOP",
        vb:space { width = 34 }
      },
      vb:button { id = "ORC_BT_COMPACT", height = 21, width = 31, bitmap = "./icons/compact_on_ico.png", notifier = function() orc_compact() end, tooltip = "Compact Orchestral" }
    },
    vb:column { id = "ORC_MAIN_PANEL_2", visible = true,
      ORC_MAIN_SELECT_COLOR,
      vb:row {
        spacing = 4,
        vb:column {
          spacing = 4,
          ORC_STRINGS,
          ORC_WINDS
        },
        vb:column {
          spacing = 4,
          ORC_BRASS,
          ORC_KEYBOARDS,
          ORC_GUITARS      
        },
        vb:column {
          spacing = 4,
          ORC_PERCUSSION,
          ORC_BATTERY,
        },
        vb:column {
          spacing = 4,
          ORC_CHORUS,
          ORC_VOICES,
        }
      }
    },
    vb:horizontal_aligner { id = "ORC_RW_INS", spacing = -3, mode="right", width= 1184,
      vb:text { width = 49, text = version },
      vb:button { id = "ORC_BT_INS_MOD", height = 21, width = 45, text = "CRE", notifier = function() orc_ins_mod() end,
        tooltip = "Create/Modify modes\n  'CRE, Create Mode' = insert groups, tracks or groups & tracks\n  'MOD, Modify Mode' = modify the existents groups or tracks"
      },
      vb:button { id = "ORC_BT_INSERT", height = 21, width = 150, text = "INSERT", notifier = function() orc_insert_all() end,
        tooltip = "Insert all groups and children tracks according to the chosen configuration"
      }
    }
  }
  return ORC_MAIN_CONTENT
end



--dialog orchestral
local function dialog_orchestral()
  if (ORC_MAIN_CONTENT==nil) then
    orc_capture_clr_mrk()
    require("keyhandler")
    orc_main_content()
  end
  --avoid showing the same window several times!
  if ( orchestral_dialog and orchestral_dialog.visible ) then orchestral_dialog:show() return end
  orchestral_dialog = renoise.app():show_custom_dialog( " "..title, ORC_MAIN_CONTENT, key_handler )
end

_AUTO_RELOAD_DEBUG=function() dialog_orchestral() end



--register menu entry
rnt:add_menu_entry{
  name=("Main Menu:Tools:%s..."):format(title),
  invoke=function() dialog_orchestral() end
}
