--
-- Arturia KeyLab MkII (AKM)
--



----------------------------------------
--collectgarbage<top>
 --collectgarbage("stop")
----------------------------------------

--unicode url: https://unicode-table.com/es/



-------------------------------------------------------------------------------------------------
--local global variables/tables
-------------------------------------------------------------------------------------------------
AKM_MAIN_DIALOG=nil
AKM_MAIN_CONTENT=nil
akm_main_title="Arturia KeyLab mkII"
akm_version="1.3"
akm_build="build 023"
rns_version=string.sub(renoise.RENOISE_VERSION,1,5)
api_version=renoise.API_VERSION
vb=renoise.ViewBuilder()
vws=vb.views
rna=renoise.app()
rnt=renoise.tool()



--about
local AKM_ABOUT_TTP=
  "TOOL NAME: "..akm_main_title.."\n"..
  "VERSION: "..akm_version.." "..akm_build.." \n"..
  "COMPATIBILITY: Renoise 3.3.0 (tested under Windows 10, with "..akm_main_title.." 49)\n"..
  "OPEN SOURCE: Yes\n"..
  "LICENSE: GNU General Public Licence. Prohibited any use of commercial ambit.\n"..
  "CODE: LUA 5.1 + API 6.1 (Renoise 3.3.0)\n"..
  "DEVELOPMENT DATE: May 2019 to January 2021\n"..
  "PUBLISHED: January 2021\n"..
  "LOCATE: Spain\n"..
  "PROGRAMMER: ulneiz\n"..
  "CONTACT AUTHOR: go to \"http://forum.renoise.com/\" & search: \"ulneiz\" member"



--global song
song=nil
  local function akm_sng() song=renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier(akm_sng) --catching start renoise or new song
  pcall(akm_sng) --catching installation



--variables
local AKM_DEVICE_NAME={" Arturia KeyLab mkII 49"," Arturia KeyLab mkII 61"," Arturia KeyLab mkII 88"}
local AKM_INPUTS={}
local AKM_OUTPUTS={}
local AKM_LOCK_IO_DEVICES=false
local AKM_ACTIVATE=false
local AKM_STOP_STATUS=false
local AKM_TRK_REPEAT={70,300,true,true}
local AKM_SEQ_REPEAT={70,300,true,true}
local AKM_LNE_REPEAT={20,300}
local AKM_INS_REPEAT={30,300,true,true}
local AKM_VPD_VALUES={111, 127,64,0, 127}
local AKM_VAL_LOCK={true,true,true,true,true,true,true,true,true}
local AKM_BTT_SEL_RBG={1,{0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29}}


--colors
local AKM_CLR={
  BLACK={001,000,000},
  WHITE={235,235,235},
  DEFAULT={000,000,000},
  MARKER={235,235,235},
  RED={199,000,000}
}


  
--capture the native color of marker(for Windows: C:\Users\USER_NAME\AppData\Roaming\Renoise\V3.1.1\Config.xml)
local function akm_capture_clr_mrk()
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
    AKM_CLR.MARKER[1]=tonumber(one)
    AKM_CLR.MARKER[2]=tonumber(two)
    AKM_CLR.MARKER[3]=tonumber(thr)
  end
end



--preferences
AKM_PREF=renoise.Document.create("Preferences"){}
for p=1,16 do
  AKM_PREF:add_property("akm_pad_rgb_"..p,{0x7F,0x7F,0x7F})
end
rnt.preferences=AKM_PREF









-------------------------------------------------------------------------------------------------
--diginal monitor status
-------------------------------------------------------------------------------------------------
--monitor 1
local akm_tbl_dm1={
  --
  "Solo Off Current Track",
  "Solo On Current Track",

  "Off Current Track",
  "Mute Current Track",
  "On Current Track",

  "Hide Sample Recorder\n(mod insert sample)",
  "Show Sample Recorder\n(mod insert sample)",

  "Show Upper Track\nScopes",
  "Show Upper Spectrum",
  "Hide Upper Frame",

  "Show Lower Track DSP",
  "Show Lower Track\nAutomation Editor",
  "Hide Lower Frame",
  --
  "Show Save Song Window",
  "Song Not Saved!",
  "Song Saved!",
  
  "Undo",
  "Not Undo!",
  "Redo",
  "Not Redo!",
  
  "Disable Metronome",
  "Enable Metronome",
  
  "Disable Follow",
  "Enable Follow",

  "Previous Track",
  "Next Track",
  
  "Stop Song\n(mod play modes)",
  "Panic Sound!\n(mod play modes)",
  
  "Play From Playback\nPosition Of Song",
  "Replay Current\nPattern Sequence",
  
  "Off Edit Mode",
  "On Edit Mode",
  
  "Loop Off\nCurrent Pattern",
  "Loop On\nCurrent Pattern",
  
  "Previous Pattern\nSequence",
  "Next Pattern\nSequence",
  
  "Show Pattern Editor",
  "Show Mixer Editor",
  "Show Sampler Phrases",
  "Show Sampler Keyzones",
  "Show Sampler Waveform",
  "Show Sampler Modulation",
  "Show Sampler Effects", 
  "Show Plugin Editor",
  "Show MIDI Monitor",
  
  "Previous Line",
  "Next Line",
  
  "Previous Instrument",
  "Next Instrument"
}



-------------------------------------------------------------------------------------------------
--general functions
-------------------------------------------------------------------------------------------------

--- ---convert values
--note convert tostring
local function akm_note_tostring(val) --number return a string, range val: 0 to 119 & 120,121
  local note_name={"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
  if (val<120) then
    return ("%s%s"):format(note_name[math.floor(val) %12+1],math.floor(val/12))
  elseif (val==120) then
    return "OFF"
  elseif (val==121) then
    return "EMP"
  end
end

--note convert tonumber
local function akm_note_tonumber(val) --string return a number
  local nte_name_1={"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
  local nte_name_2={"c-","c#","d-","d#","e-","f-","f#","g-","g#","a-","a#","b-"}
  local nte_name_3={"C", "C#","D", "D#","E", "F" ,"F#","G", "G#","A", "A#","B" }
  local nte_name_4={"c", "c#","d", "d#","e", "f", "f#","g", "g#","a", "a#","b" }
  local nte_off   ={"o","O","of","oF","Of","OF","off","oFf","ofF","oFF","Off","OFf","OFF"}
  local nte_empty ={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  for i=1,#nte_name_1 do
    for octave = 0,9 do
      if (val==("%s%s"):format(nte_name_1[i],octave)) or
         (val==("%s%s"):format(nte_name_2[i],octave)) or
         (val==("%s%s"):format(nte_name_3[i],octave)) or
         (val==("%s%s"):format(nte_name_4[i],octave)) then
        return i+(octave*12)-1
      end
    end
  end
  for i=1,#nte_off do
    if (val==("%s"):format(nte_off[i])) then
      return 120
    end
  end
  for i=1,#nte_empty do
    if (val==("%s"):format(nte_empty[i])) then
      return 121
    end
  end
end



--instrument convert tostring
local function akm_instrument_tostring(val) --number return a string, range val: 0 to 254 & 255
  if (val<255) then
    return ("%.2X"):format(val)
  elseif (val==255) then
    return "EMP"
  end
end

--instrument convert tonumber
local function akm_instrument_tonumber(val) --string return a number
  local ins_empty ={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  for i=1,#ins_empty do
    if (val==("%s"):format(ins_empty[i])) then
      return 255
    else
      return tonumber(val,16)
    end
  end
end



--volume convert tostring
local function akm_volume_tostring(val) --number return a string, range val: 0 to 127 & 255
  if (val<=127) then
    return ("%.2X"):format(val)
  elseif (val>127) then
    return "EMP"
  end
end

--volume convert tonumber
local function akm_volume_tonumber(val) --string return a number
  local vol_empty ={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  for i=1,#vol_empty do
    if (val==("%s"):format(vol_empty[i])) then
      return 255
    else
      return tonumber(val,16)
    end
  end
end



--panning convert tostring
local function akm_panning_tostring(val) --number return a string, range val: 0 to 127 & 255
  if (val==128) then
    return ("%.2X R"):format(val) --right
  elseif (val<128 and val>64) then
    return ("%.2X ▶"):format(val)
  elseif (val==64) then
    return ("%.2X C"):format(val) --center
  elseif (val<64 and val>0) then
    return ("%.2X ◀"):format(val)
  elseif (val==0) then
    return ("%.2X L"):format(val) --left
  elseif (val>128) then
    return "EMP"
  end
end

--panning convert tonumber
local function akm_panning_tonumber(val) --string return a number
  local pan_empty ={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  local pan_left  ={"l","L","le","Le","LE","left","Left","LEFT"}
  local pan_center={"ce","Ce","CE","center","Center","CENTER"}
  local pan_right ={"r","R","ri","Ri","RI","right","Right","RIGHT"}
  for i=1,#pan_empty do
    if (val==("%s"):format(pan_empty[i])) then
      return 255
    end
  end
  for i=1,#pan_left do
    if (val==("%s"):format(pan_left[i])) then
      return 0
    end
  end
  for i=1,#pan_center do
    if (val==("%s"):format(pan_center[i])) then
      return 64
    end
  end
  for i=1,#pan_right do
    if (val==("%s"):format(pan_right[i])) then
      return 128
    end
  end
  return tonumber(val,16)
end



--delay convert tostring
local function akm_delay_tostring(val) --number return a string, range val: 1 to 255 & 0
  if (val<=255 and val>0) then
    return ("%.2X"):format(val)
  elseif (val==0) then
    return "EMP"
  end
end

--delay convert tonumber
local function akm_delay_tonumber(val) --string return a number
  local vol_empty={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  for i=1,#vol_empty do
    if (val==("%s"):format(vol_empty[i])) then
      return 0
    else
      return tonumber(val,16)
    end
  end
end



local AKM_SFX={"00","0A","0U","0D","0G","0V","0I","0O","0T","0C","0S","0B","0E","0N"}
local AKM_EFF={"00","0A","0U","0D","0G","0V","0I","0O","0T","0C","0S","0B","0E","0N", "0M","0Z","0Q","0Y","0R", "0L","0P","0W","0X","0J", "ZT","ZL","ZK","ZG","ZB","ZD"}

--sfx/fx value convert tostring
local function akm_sfx_fx_tostring(val) --number return a string
  local AKM_SFX_0={"EMP","A","U","D","G","V","I","O","T","C","S","B","E","N"}
  local AKM_EFF_0={"EMP","A","U","D","G","V","I","O","T","C","S","B","E","N", "M","Z","Q","Y","R", "L","P","W","X","J", "ZT","ZL","ZK","ZG","ZB","ZD"}
  local snc,sec=song.selected_note_column,song.selected_effect_column
  if (song.selected_track.type~=renoise.Track.TRACK_TYPE_MASTER) then
    if (snc) then
      return AKM_SFX_0[val]
    else
      return AKM_EFF_0[val]
    end
  else
    return AKM_EFF_0[val]
  end
end

--sfx/fx value convert tonumber
local function akm_sfx_fx_tonumber(val) --string return a number
  local snc,sec=song.selected_note_column,song.selected_effect_column
  local sfx_empty={"em","Em","eM","emp","eMp","emP","eMP","Emp","EMp","EMP","empty","Empty","EMPTY"}
  local akm_sfx_0={"0","a","u","d","g","v","i","o","t","c","s","b","e","n"}
  local AKM_SFX_0={"0","A","U","D","G","V","I","O","T","C","S","B","E","N"}
  local akm_eff_0={"0","a","u","d","g","v","i","o","t","c","s","b","e","n", "m","z","q","y","r", "l","p","w","x","j", "zt","zl","zk","zg","zb","zd"}
  local AKM_EFF_0={"0","A","U","D","G","V","I","O","T","C","S","B","E","N", "M","Z","Q","Y","R", "L","P","W","X","J", "ZT","ZL","ZK","ZG","ZB","ZD"}
  if (song.selected_track.type~=renoise.Track.TRACK_TYPE_MASTER) then
    if (snc) then
      for i=1,#akm_sfx_0 do
        if (val==("%s"):format(akm_sfx_0[i])) then
          return i
        end
      end
      for i=1,#AKM_SFX_0 do
        if (val==("%s"):format(AKM_SFX_0[i])) then
          return i
        end
      end
    else
      for i=1,#akm_eff_0 do
        if (val==("%s"):format(akm_eff_0[i])) then
          return i
        end
      end
      for i=1,#AKM_EFF_0 do
        if (val==("%s"):format(AKM_EFF_0[i])) then
          return i
        end
      end
    end
  else
    for i=1,#akm_eff_0 do
      if (val==("%s"):format(akm_eff_0[i])) then
        return i
      end
    end
    for i=1,#AKM_EFF_0 do
      if (val==("%s"):format(AKM_EFF_0[i])) then
        return i
      end
    end
  end
  for i=1,#sfx_empty do
    if (val==("%s"):format(sfx_empty[i])) then
      return 1
    end
  end
  return val
end



--amount effect convert tostring
local function akm_amount_tostring(val) --number return a string, range val: 0 to 255
  if (val<=255 and val>=0) then
    return ("%.2X"):format(val)
  end
end

--amount effect convert tonumber
local function akm_amount_tonumber(val) --string return a number
  return tonumber(val,16)
end



--note/effect column convert tostring
local function akm_nc_ec_tostring(val) --number return a string
  local NC_EC={"NC1","NC2","NC3","NC4","NC5","NC6","NC7","NC8","NC9","NC10","NC11","NC12","EC1","EC2","EC3","EC4","EC5","EC6","EC7","EC8"}
  return NC_EC[val]
end


--note/effect column convert tonumber
local function akm_nc_ec_tonumber(val) --string return a number
  local n_e=  {"n1","n2","n3","n4","n5","n6","n7","n8","n9","n10","n11","n12","e1","e2","e3","e4","e5","e6","e7","e8"}
  local nc_ec={"nc1","nc2","nc3","nc4","nc5","nc6","nc7","nc8","nc9","nc10","nc11","nc12","ec1","ec2","ec3","ec4","ec5","ec6","ec7","ec8"}
  local N_E=  {"N1","N2","N3","N4","N5","N6","N7","N8","N9","N10","N11","N12","E1","E2","E3","E4","E5","E6","E7","E8"}
  local NC_EC={"NC1","NC2","NC3","NC4","NC5","NC6","NC7","NC8","NC9","NC10","NC11","NC12","EC1","EC2","EC3","EC4","EC5","EC6","EC7","EC8"}
  for i=1,#n_e do
    if (val==("%s"):format(n_e[i])) then
      return i
    end
  end
  for i=1,#nc_ec do
    if (val==("%s"):format(nc_ec[i])) then
      return i
    end
  end
  for i=1,#N_E do
    if (val==("%s"):format(N_E[i])) then
      return i
    end
  end
  for i=1,#NC_EC do
    if (val==("%s"):format(NC_EC[i])) then
      return i
    end
  end
  return val
end


--step lenght convert tostring
local function akm_step_tostring(val) --number return a string, range val: 0 to 511
  return ("%.2d"):format(val)
end

--step lenght convert tonumber
local function akm_step_tonumber(val) --string return a number
  return tonumber(val)
end



--- ---pads (16 multicolor pads)
--n/a


--- ---track controls (1: solo, 2: mute, 3: record | 1:read, 2:write)
--1.1 solo (select 1) --> (on/off solo track)
local function akm_solo_1()
  if (song.selected_track.solo_state) then
    song.selected_track.solo_state=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[1]
  else
    song.selected_track.solo_state=true
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[2]
  end
end

--2.2 mute (select 1) --> (active-off-mute current track)
local function akm_mute_1()
  if (song.selected_track.type~=renoise.Track.TRACK_TYPE_MASTER) then
    local msa=renoise.Track.MUTE_STATE_ACTIVE
    local mso=renoise.Track.MUTE_STATE_OFF
    local msm=renoise.Track.MUTE_STATE_MUTED
    if (song.selected_track.mute_state==msa) then
      song.selected_track.mute_state=mso
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[3]
    elseif (song.selected_track.mute_state==mso) then
      song.selected_track.mute_state=msm
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[4]
    elseif (song.selected_track.mute_state==msm) then
      song.selected_track.mute_state=msa
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[5]
    end
  end
end

--3.3 record (select 1) --> (sample recording view)
local function akm_record_1()
  if (rna.window.sample_record_dialog_is_visible) then
    rna.window.sample_record_dialog_is_visible=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[6]
  else
    rna.window.sample_record_dialog_is_visible=true
    local mfi1=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
    if (rna.window.active_middle_frame~=mfi1) then
      rna.window.active_middle_frame=mfi1
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[7]
  end
end

local function akm_record_1_add_timer()
  if not rnt:has_timer(akm_record_1_add_timer) then
    rnt:add_timer(akm_record_1_add_timer,700)
  else
    song.selected_instrument:insert_sample_at(song.selected_sample_index+1)
    if (#song.selected_instrument.samples>=2) then
      song.selected_sample_index=song.selected_sample_index+1
    end
    vws.AKM_TXT_DIGITAL_1.text=("New sample %.2d inserted!"):format(song.selected_sample_index-1)
    if rnt:has_timer(akm_record_1_add_timer) then
      rnt:remove_timer(akm_record_1_add_timer)
    end
  end
end

local function akm_record_1_remove_timer()
  if rnt:has_timer(akm_record_1_add_timer) then
    akm_record_1()
    rnt:remove_timer(akm_record_1_add_timer)
  end
end



--1.2 solo (select 2) --> (clear row)
local function akm_solo_2()
  if (song.transport.edit_mode) then
    local snc,sec=song.selected_note_column,song.selected_effect_column
    if (snc) then
      snc:clear()
      vws.AKM_TXT_DIGITAL_1.text="Clear current row\nin note colum"
    else
      sec:clear()
      vws.AKM_TXT_DIGITAL_1.text="Clear current row\nin effect column"
    end
  end
end

--2.2 mute (select 2) --> (clear NC/EC)
local function akm_mute_2()
  if (song.transport.edit_mode) then
    local nol=song.selected_pattern.number_of_lines
    local snc,sec=song.selected_note_column,song.selected_effect_column
    local snci,seci=song.selected_note_column_index,song.selected_effect_column_index
    if (snc) then
      for lne=1,nol do
        song.selected_pattern_track:line(lne):note_column(snci):clear()
        vws.AKM_TXT_DIGITAL_1.text="Clear current\nnote colum"
      end
    else
      for lne=1,nol do
        song.selected_pattern_track:line(lne):effect_column(seci):clear()
        vws.AKM_TXT_DIGITAL_1.text="Clear current\neffect colum"
      end
    end
  end
end

--3.2 record (select 2) --> (clear Ptt-Tr)
local function akm_record_2()
  if (song.transport.edit_mode) then
    song.selected_pattern_track:clear()
    vws.AKM_TXT_DIGITAL_1.text="Clear current\npattern-track"
  end
end



--1.3 solo (select 3) --> ()
local function akm_solo_3()
end
--2.3 mute (select 3) --> ()
local function akm_mute_3()
end
--3.3 record (select 3) --> ()
local function akm_record_3()
end



--1.4 solo (select 4) --> ()
local function akm_solo_4()
end
--2.4 mute (select 4) --> ()
local function akm_mute_4()
end
--3.4 record (select 4) --> ()
local function akm_record_4()
end



--1.5 solo (select 5) --> ()
local function akm_solo_5()
end
--2.5 mute (select 5) --> ()
local function akm_mute_5()
end
--3.5 record (select 5) --> ()
local function akm_record_5()
end



--1.6 solo (select 6) --> ()
local function akm_solo_6()
end
--2.6 mute (select 6) --> ()
local function akm_mute_6()
end
--3.6 record (select 6) --> ()
local function akm_record_6()
end



--1.7 solo (select 7) --> ()
local function akm_solo_7()
end
--2.7 mute (select 7) --> ()
local function akm_mute_7()
end
--3.7 record (select 7) --> ()
local function akm_record_7()
end



--1.8 solo (select 8) --> ()
local function akm_solo_8()
end
--2.8 mute (select 8) --> ()
local function akm_mute_8()
end
--3.8 record (select 8) --> ()
local function akm_record_8()
end



--4 read --> (upper frame view)
local function akm_read()
  if (rna.window.sample_record_dialog_is_visible) then
    song.transport:start_stop_sample_recording()
    vws.AKM_TXT_DIGITAL_1.text="Start/stop recording\nthe selected sample."
  else
    local fts=renoise.ApplicationWindow.UPPER_FRAME_TRACK_SCOPES
    local fms=renoise.ApplicationWindow.UPPER_FRAME_MASTER_SPECTRUM
    if not (rna.window.mixer_view_is_detached) then
      if not (rna.window.upper_frame_is_visible) then
        rna.window.upper_frame_is_visible=true
        rna.window.active_upper_frame=fts
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[8]
      elseif (rna.window.active_upper_frame==fts) then
        rna.window.active_upper_frame=fms
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[9]
      elseif (rna.window.active_upper_frame==fms) then
        rna.window.upper_frame_is_visible=false
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[10]
      end
    else
      if not (rna.window.upper_frame_is_visible) then
        rna.window.upper_frame_is_visible=true
        rna.window.active_upper_frame=fts
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[8]
      elseif (rna.window.active_upper_frame==fts) then
        rna.window.upper_frame_is_visible=false
        
        -- --incomplete!!!
      
      end
    end
  end
end



local function akm_read_add_timer()
  if not rnt:has_timer(akm_read_add_timer) then
    rnt:add_timer(akm_read_add_timer,700)
  else
    if (rna.window.pattern_matrix_is_visible) then
      rna.window.pattern_matrix_is_visible=false
      vws.AKM_TXT_DIGITAL_1.text="Hide Pattern Seq.\nMatrix Panel"
    else
      rna.window.pattern_matrix_is_visible=true
      vws.AKM_TXT_DIGITAL_1.text="Show Pattern Seq.\nMatrix Panel"
    end
    if rnt:has_timer(akm_read_add_timer) then
      rnt:remove_timer(akm_read_add_timer)
    end
  end  
end

local function akm_read_remove_timer()
  if rnt:has_timer(akm_read_add_timer) then
    akm_read()
    rnt:remove_timer(akm_read_add_timer)
  end
end



--5 write --> (lower frame view)
local function akm_write()
  if (rna.window.sample_record_dialog_is_visible) then
    song.transport:cancel_sample_recording()
    vws.AKM_TXT_DIGITAL_1.text="Cancel recording\nthe selected sample."
  else
    local ftd=renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
    local fta=renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
    local fpe=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
    local fmx=renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
    if not (rna.window.lower_frame_is_visible) then
      rna.window.lower_frame_is_visible=true
      rna.window.active_lower_frame=ftd
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[11]
    elseif (rna.window.active_lower_frame==ftd) then
      rna.window.active_lower_frame=fta
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[12]
    elseif (rna.window.active_lower_frame==fta) then
      rna.window.lower_frame_is_visible=false
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[13]
    end
    if (rna.window.active_middle_frame~=fpe or rna.window.active_middle_frame~=fmx) then
      rna.window.active_middle_frame=fpe
    end
  end
end

local function akm_write_add_timer()
  if not rnt:has_timer(akm_write_add_timer) then
    rnt:add_timer(akm_write_add_timer,700)
  else
    if (rna.window.pattern_advanced_edit_is_visible) then
      rna.window.pattern_advanced_edit_is_visible=false
      vws.AKM_TXT_DIGITAL_1.text="Hide Advanced\nOperations Panel"
    else
      rna.window.pattern_advanced_edit_is_visible=true
      vws.AKM_TXT_DIGITAL_1.text="Show Advanced\nOperations Panel"
    end
    if rnt:has_timer(akm_write_add_timer) then
      rnt:remove_timer(akm_write_add_timer)
    end
  end  
end

local function akm_write_remove_timer()
  if rnt:has_timer(akm_write_add_timer) then
    akm_write()
    rnt:remove_timer(akm_write_add_timer)
  end
end



--- ---global controls (1:save, 2:in, 3:out, 4:metro, 5:undo)
--1 save
local function akm_save_on()
  vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[14]
end

local function akm_save_off()
  local filename=rna:prompt_for_filename_to_write("xrnx", "Save current Song as")
  if (filename=="") then
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[15]
    return
  else
    rna:save_song_as(filename)
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[16]
  end
end

--2 in  --> (undo)
local function akm_in()
  if (song:can_undo()) then
    song:undo()
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[17]
  else
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[18]
  end
end

--3 out --> (redo)
local function akm_out()
  if (song:can_redo()) then
    song:redo()
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[19]
  else
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[20]
  end
end

--4 metro
local function akm_metro()
  if (song.transport.metronome_enabled) then
    song.transport.metronome_enabled=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[21]
  else
    song.transport.metronome_enabled=true
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[22]
  end
end

--5 undo (follow the player's position)
local function akm_undo()
  if (song.transport.follow_player) then
    song.transport.follow_player=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[23]
  else
    song.transport.follow_player=true
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[24]
  end
end



--- ---transport controls (1:rewind, 2:fast_forward, 3:stop, 4:play/pause, 5:record, 6:loop)
--1 previous track
local function akm_rewind()
  if (AKM_TRK_REPEAT[3]) then
    song:select_previous_track()
  end
  if (song.selected_track_index==1) then
    AKM_TRK_REPEAT[3]=false
  end
end

local function akm_rewind_repeat(release)
  if not release then
    if rnt:has_timer(akm_rewind_repeat) then
      rnt:remove_timer(akm_rewind_repeat)
      if not (rnt:has_timer(akm_rewind)) then
        rnt:add_timer(akm_rewind,AKM_TRK_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_rewind_repeat) then
        rnt:remove_timer(akm_rewind_repeat)
      elseif rnt:has_timer(akm_rewind) then
        rnt:remove_timer(akm_rewind)
      end
      AKM_TRK_REPEAT[3]=true
      akm_rewind()
      rnt:add_timer(akm_rewind_repeat,AKM_TRK_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[25]
  else
    if rnt:has_timer(akm_rewind_repeat) then
      rnt:remove_timer(akm_rewind_repeat)
    elseif rnt:has_timer(akm_rewind) then
      rnt:remove_timer(akm_rewind)
    end
  end
end

--2 next track
local function akm_forward()
  if (AKM_TRK_REPEAT[4]) then
    song:select_next_track()
  end
  if (song.selected_track_index==#song.tracks) then
    AKM_TRK_REPEAT[4]=false
  end
end

local function akm_forward_repeat(release)
  if not release then
    if rnt:has_timer(akm_forward_repeat) then
      rnt:remove_timer(akm_forward_repeat)
      if not (rnt:has_timer(akm_forward)) then
        rnt:add_timer(akm_forward,AKM_TRK_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_forward_repeat) then
        rnt:remove_timer(akm_forward_repeat)
      elseif rnt:has_timer(akm_forward) then
        rnt:remove_timer(akm_forward)
      end
      AKM_TRK_REPEAT[4]=true
      akm_forward()
      rnt:add_timer(akm_forward_repeat,AKM_TRK_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[26]
  else
    if rnt:has_timer(akm_forward_repeat) then
      rnt:remove_timer(akm_forward_repeat)
    elseif rnt:has_timer(akm_forward) then
      rnt:remove_timer(akm_forward)
    end
  end
end

--3 stop song (& panic)
local function akm_stop()
  song.transport:stop()
  vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[27]
  if not (song.transport.playing) then
    song.transport:panic()
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[28]
    --print("panic")
  end
end


--4 play song
local function akm_play()
  local pcp=renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  local prp=renoise.Transport.PLAYMODE_RESTART_PATTERN
  if (AKM_STOP_STATUS) then
    song.transport:start(pcp)
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[29]
  else
    song.transport:start(prp)
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[30]
  end
end


--5 edit mode
local function akm_edit_mode()
  if (song.transport.edit_mode) then
    song.transport.edit_mode=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[31]
  else
    song.transport.edit_mode=true
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[32]
    local fpe=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
    if (rna.window.active_middle_frame~=fpe) then
      rna.window.active_middle_frame=fpe
    end
  end
end

--6 block loop
local function akm_loop()
  if (song.transport.loop_pattern) then
    song.transport.loop_pattern=false
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[33]
  else
    song.transport.loop_pattern=true
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[34]
  end
end


--- ---browses center controls (1:center knob left, 2:center knob right, 3:center knob button | 1:left arrow, 2:right arrow)
--1 left button --> (previous pattern sequence)
local function akm_left_button()
  if (AKM_SEQ_REPEAT[3]) then
    if (song.selected_sequence_index>1) then
      song.selected_sequence_index=song.selected_sequence_index-1
    else
      song.selected_sequence_index=#song.sequencer.pattern_sequence
    end
  end
  if (song.selected_sequence_index==1) then
    AKM_SEQ_REPEAT[3]=false
  end
end

local function akm_left_button_repeat(release)
  if not release then
    if rnt:has_timer(akm_left_button_repeat) then
      rnt:remove_timer(akm_left_button_repeat)
      if not (rnt:has_timer(akm_left_button)) then
        rnt:add_timer(akm_left_button,AKM_SEQ_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_left_button_repeat) then
        rnt:remove_timer(akm_left_button_repeat)
      elseif rnt:has_timer(akm_left_button) then
        rnt:remove_timer(akm_left_button)
      end
      AKM_SEQ_REPEAT[3]=true
      akm_left_button()
      rnt:add_timer(akm_left_button_repeat,AKM_SEQ_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[35]
  else
    if rnt:has_timer(akm_left_button_repeat) then
      rnt:remove_timer(akm_left_button_repeat)
    elseif rnt:has_timer(akm_left_button) then
      rnt:remove_timer(akm_left_button)
    end
  end
end



--2 right button --> (next pattern sequence)
local function akm_right_button()
  if (AKM_SEQ_REPEAT[4]) then
    if (song.selected_sequence_index<#song.sequencer.pattern_sequence) then
      song.selected_sequence_index=song.selected_sequence_index+1
    else
      song.selected_sequence_index=1
    end
  end
  if (song.selected_sequence_index==#song.sequencer.pattern_sequence) then
    AKM_SEQ_REPEAT[4]=false
  end
end

local function akm_right_button_repeat(release)
  if not release then
    if rnt:has_timer(akm_right_button_repeat) then
      rnt:remove_timer(akm_right_button_repeat)
      if not (rnt:has_timer(akm_right_button)) then
        rnt:add_timer(akm_right_button,AKM_SEQ_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_right_button_repeat) then
        rnt:remove_timer(akm_right_button_repeat)
      elseif rnt:has_timer(akm_right_button) then
        rnt:remove_timer(akm_right_button)
      end
      AKM_SEQ_REPEAT[4]=true
      akm_right_button()
      rnt:add_timer(akm_right_button_repeat,AKM_SEQ_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[36]
  else
    if rnt:has_timer(akm_right_button_repeat) then
      rnt:remove_timer(akm_right_button_repeat)
    elseif rnt:has_timer(akm_right_button) then
      rnt:remove_timer(akm_right_button)
    end
  end
end



--3 button dial --> (main tabs navigador)
local function akm_button_dial()
  local mfp=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  local mfm=renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
  local mfi=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR
  if not (rna.window.instrument_editor_is_detached) then
    if (rna.window.active_middle_frame~=mfp and rna.window.active_middle_frame~=mfi) then
      rna.window.active_middle_frame=mfp
    else
      if (rna.window.active_middle_frame==mfp) then
        rna.window.active_middle_frame=mfi
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[44]
      elseif (rna.window.active_middle_frame==mfi) then
        rna.window.active_middle_frame=mfp
        vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[37]
      end
    end
  else
    if (rna.window.active_middle_frame~=mfp) then
      rna.window.active_middle_frame=mfp
    else
      rna.window.active_middle_frame=mfm
    end    
  end
end

local function akm_button_dial_add_timer()
  if not rnt:has_timer(akm_button_dial_add_timer) then
    rnt:add_timer(akm_button_dial_add_timer,700)
  else
    if (rna.window.instrument_editor_is_detached) then
      rna.window.instrument_editor_is_detached=false
      vws.AKM_TXT_DIGITAL_1.text="Instrument editor\nwindow tached"
    else
      rna.window.instrument_editor_is_detached=true
      vws.AKM_TXT_DIGITAL_1.text="Instrument editor\nwindow unttached"
    end
    if rnt:has_timer(akm_button_dial_add_timer) then
      rnt:remove_timer(akm_button_dial_add_timer)
    end
  end
end

local function akm_button_dial_remove_timer()
  if rnt:has_timer(akm_button_dial_add_timer) then
    akm_button_dial()
    rnt:remove_timer(akm_button_dial_add_timer)
  end
end



local AKM_WINDOW_FRAME=3
--4 left dial --> (main tabs left navigador)
local function akm_left_dial()
  local mfp=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  local mfm=renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
  local mfi1=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
  local mfi2=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES
  local mfi3=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  local mfi4=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
  local mfi5=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
  local mfi6=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR
  local mfi7=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR
  if not (rna.window.instrument_editor_is_detached) then
    if (rna.window.active_middle_frame==mfi7) then
      rna.window.active_middle_frame=mfi6
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[44]
    elseif (rna.window.active_middle_frame==mfi6) then
      rna.window.active_middle_frame=mfi5
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[43]
    elseif (rna.window.active_middle_frame==mfi5) then
      rna.window.active_middle_frame=mfi4
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[42]
    elseif (rna.window.active_middle_frame==mfi4) then
      rna.window.active_middle_frame=mfi3
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[41]
    elseif (rna.window.active_middle_frame==mfi3) then
      rna.window.active_middle_frame=mfi2 
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[40]
    elseif (rna.window.active_middle_frame==mfi2) then
      rna.window.active_middle_frame=mfi1
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[39]
    elseif (rna.window.active_middle_frame==mfi1) then
      rna.window.active_middle_frame=mfm
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[38]
    elseif (rna.window.active_middle_frame==mfm) then
      rna.window.active_middle_frame=mfp
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[37]
    elseif (rna.window.active_middle_frame==mfp) then
      rna.window.active_middle_frame=mfi7
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[45]
    end
  else
    if (AKM_WINDOW_FRAME==mfi7) then
      AKM_WINDOW_FRAME=mfi6
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[44]
    elseif (AKM_WINDOW_FRAME==mfi6) then
      AKM_WINDOW_FRAME=mfi5
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[43]
    elseif (AKM_WINDOW_FRAME==mfi5) then
      AKM_WINDOW_FRAME=mfi4
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[42]
    elseif (AKM_WINDOW_FRAME==mfi4) then
      AKM_WINDOW_FRAME=mfi3
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[41]
    elseif (AKM_WINDOW_FRAME==mfi3) then
      AKM_WINDOW_FRAME=mfi2 
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[40]
    elseif (AKM_WINDOW_FRAME==mfi2) then
      AKM_WINDOW_FRAME=mfi1
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[39]
    elseif (AKM_WINDOW_FRAME==mfi1) then
      AKM_WINDOW_FRAME=mfi7
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[45]
    end
    rna.window.active_middle_frame=AKM_WINDOW_FRAME
    vws.AKM_ROT_DIAL.value=AKM_WINDOW_FRAME-1
  end
end



--5 right dial --> (main tabs right navigador)
local function akm_right_dial()
  local mfp=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  local mfm=renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
  local mfi1=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
  local mfi2=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES
  local mfi3=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  local mfi4=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
  local mfi5=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
  local mfi6=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR
  local mfi7=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR
  if not (rna.window.instrument_editor_is_detached) then
    if (rna.window.active_middle_frame==mfp) then
      rna.window.active_middle_frame=mfi5
      rna.window.active_middle_frame=mfm
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[38]
    elseif (rna.window.active_middle_frame==mfm) then
      rna.window.active_middle_frame=mfi1
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[39]
    elseif (rna.window.active_middle_frame==mfi1) then
      rna.window.active_middle_frame=mfi2
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[40]
    elseif (rna.window.active_middle_frame==mfi2) then
      rna.window.active_middle_frame=mfi3
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[41]
    elseif (rna.window.active_middle_frame==mfi3) then
      rna.window.active_middle_frame=mfi4
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[42]
    elseif (rna.window.active_middle_frame==mfi4) then
      rna.window.active_middle_frame=mfi5
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[43]
    elseif (rna.window.active_middle_frame==mfi5) then
      rna.window.active_middle_frame=mfi6
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[44]
    elseif (rna.window.active_middle_frame==mfi6) then
      rna.window.active_middle_frame=mfi7
     vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[45]
    elseif (rna.window.active_middle_frame==mfi7) then
      rna.window.active_middle_frame=mfp
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[37]
    end
  else
    if (AKM_WINDOW_FRAME==mfi1) then
      AKM_WINDOW_FRAME=mfi2
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[40]
    elseif (AKM_WINDOW_FRAME==mfi2) then
      AKM_WINDOW_FRAME=mfi3
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[41]
    elseif (AKM_WINDOW_FRAME==mfi3) then
      AKM_WINDOW_FRAME=mfi4
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[42]
    elseif (AKM_WINDOW_FRAME==mfi4) then
      AKM_WINDOW_FRAME=mfi5
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[43]
    elseif (AKM_WINDOW_FRAME==mfi5) then
      AKM_WINDOW_FRAME=mfi6
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[44]
    elseif (AKM_WINDOW_FRAME==mfi6) then
      AKM_WINDOW_FRAME=mfi7
     vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[45]
    elseif (AKM_WINDOW_FRAME==mfi7) then
      AKM_WINDOW_FRAME=mfi1
      vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[37]
    end
    rna.window.active_middle_frame=AKM_WINDOW_FRAME
    vws.AKM_ROT_DIAL.value=AKM_WINDOW_FRAME-1
  end
end



--- ---live/bank circular buttons
--1 previous line
local function akm_live_part_1()
  local value=-1
  local sli=song.selected_line_index
  local ssi=song.selected_sequence_index
  local sti=song.selected_track_index
  if (1<=sli+value) then
    song.selected_line_index=sli+value
    vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(sti,ssi-1,sli-2)
  else
    if (ssi-1>=1) then
      local nol=song:pattern(song.sequencer:pattern(ssi-1)).number_of_lines
      song.selected_sequence_index=ssi-1
      song.selected_line_index=nol
      vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(sti,ssi-1,nol-1)
    end
  end
end



local function akm_live_part_1_repeat(release)
  if not release then
    if rnt:has_timer(akm_live_part_1_repeat) then
      rnt:remove_timer(akm_live_part_1_repeat)
      if not (rnt:has_timer(akm_live_part_1)) then
        rnt:add_timer(akm_live_part_1,AKM_LNE_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_live_part_1_repeat) then
        rnt:remove_timer(akm_live_part_1_repeat)
      elseif rnt:has_timer(akm_live_part_1) then
        rnt:remove_timer(akm_live_part_1)
      end
      akm_live_part_1()
      rnt:add_timer(akm_live_part_1_repeat,AKM_LNE_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[46]    
  else
    if rnt:has_timer(akm_live_part_1_repeat) then
      rnt:remove_timer(akm_live_part_1_repeat)
    elseif rnt:has_timer(akm_live_part_1) then
      rnt:remove_timer(akm_live_part_1)
    end
  end
end



--2 next line
local function akm_live_part_2()
  local value=1
  local sli=song.selected_line_index
  local ssi=song.selected_sequence_index
  local nol=song.selected_pattern.number_of_lines
  if (nol>=sli+value) then
    song.selected_line_index=sli+value
    vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(song.selected_track_index,ssi-1,sli)
  else
    if (ssi+1<=#song.sequencer.pattern_sequence) then
      song.selected_sequence_index=ssi+1
      song.selected_line_index=1
      vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(song.selected_track_index,ssi-1,0)
    end
  end
  
end

local function akm_live_part_2_repeat(release)
  if not release then
    if rnt:has_timer(akm_live_part_2_repeat) then
      rnt:remove_timer(akm_live_part_2_repeat)
      if not (rnt:has_timer(akm_live_part_2)) then
        rnt:add_timer(akm_live_part_2,AKM_LNE_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_live_part_2_repeat) then
        rnt:remove_timer(akm_live_part_2_repeat)
      elseif rnt:has_timer(akm_live_part_2) then
        rnt:remove_timer(akm_live_part_2)
      end
      akm_live_part_2()
      rnt:add_timer(akm_live_part_2_repeat,AKM_LNE_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[47]
  else
    if rnt:has_timer(akm_live_part_2_repeat) then
      rnt:remove_timer(akm_live_part_2_repeat)
    elseif rnt:has_timer(akm_live_part_2) then
      rnt:remove_timer(akm_live_part_2)
    end
  end
end



--3 bank next --> (previous instrument)
local function akm_bank_next()
  if (AKM_INS_REPEAT[3]) then
    if (song.selected_instrument_index>1) then
      song.selected_instrument_index=song.selected_instrument_index-1
    else
      song.selected_instrument_index=#song.instruments
    end
  end
  if (song.selected_instrument_index==1) then
    AKM_INS_REPEAT[3]=false
  end
end

local function akm_bank_next_repeat(release)
  if not release then
    if rnt:has_timer(akm_bank_next_repeat) then
      rnt:remove_timer(akm_bank_next_repeat)
      if not (rnt:has_timer(akm_bank_next)) then
        rnt:add_timer(akm_bank_next,AKM_INS_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_bank_next_repeat) then
        rnt:remove_timer(akm_bank_next_repeat)
      elseif rnt:has_timer(akm_bank_next) then
        rnt:remove_timer(akm_bank_next)
      end
      AKM_INS_REPEAT[3]=true
      akm_bank_next()
      rnt:add_timer(akm_bank_next_repeat,AKM_INS_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[48]
  else
    if rnt:has_timer(akm_bank_next_repeat) then
      rnt:remove_timer(akm_bank_next_repeat)
    elseif rnt:has_timer(akm_bank_next) then
      rnt:remove_timer(akm_bank_next)
    end
  end
end



--4 bank previous --> (next instrument)
local function akm_bank_previous()
  if (AKM_INS_REPEAT[4]) then
    if (song.selected_instrument_index<#song.instruments) then
      song.selected_instrument_index=song.selected_instrument_index+1
    else
      song.selected_instrument_index=1
    end
  end
  if (song.selected_instrument_index==#song.instruments) then
    AKM_INS_REPEAT[4]=false
  end  
end

local function akm_bank_previous_repeat(release)
  if not release then
    if rnt:has_timer(akm_bank_previous_repeat) then
      rnt:remove_timer(akm_bank_previous_repeat)
      if not (rnt:has_timer(akm_bank_previous)) then
        rnt:add_timer(akm_bank_previous,AKM_INS_REPEAT[1])
      end
    else
      if rnt:has_timer(akm_bank_previous_repeat) then
        rnt:remove_timer(akm_bank_previous_repeat)
      elseif rnt:has_timer(akm_bank_previous) then
        rnt:remove_timer(akm_bank_previous)
      end
      AKM_INS_REPEAT[4]=true
      akm_bank_previous()
      rnt:add_timer(akm_bank_previous_repeat,AKM_INS_REPEAT[2])
    end
    vws.AKM_TXT_DIGITAL_1.text=akm_tbl_dm1[49]
  else
    if rnt:has_timer(akm_bank_previous_repeat) then
      rnt:remove_timer(akm_bank_previous_repeat)
    elseif rnt:has_timer(akm_bank_previous) then
      rnt:remove_timer(akm_bank_previous)
    end
  end
end



--- ---encoders (8+1 rotary knobs)
local function akm_mnt_nte_ins(nte,ins)
  vws.AKM_TXT_DIGITAL_2.text=("Note: %s\nInstrument: %s"):format(akm_note_tostring(nte),akm_instrument_tostring(ins))
end

local function akm_mnt_vpd(vol,pan,dly)
  vws.AKM_TXT_DIGITAL_2.text=("Vol: %s  Pan: %s\nDelay: %s"):format(akm_volume_tostring(vol),akm_panning_tostring(pan),akm_delay_tostring(dly))
end



--1 knob for note
local function akm_nc_previous_note()
  if (song.transport.edit_mode and AKM_VAL_LOCK[1]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.note_value<=121) then
        if (snc.note_value>0) then
          if (snc.note_value==120) then
            snc.note_value=48
          else
            snc.note_value=snc.note_value-1
          end
        end
      end
      if (snc.note_value<120) then
        snc.instrument_value=song.selected_instrument_index-1
      else
        snc.instrument_value=255
      end
      vws.AKM_RTY_1.value=snc.note_value
      akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
    end
  end
end

local function akm_nc_next_note()
  if (song.transport.edit_mode and AKM_VAL_LOCK[1]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.note_value<=121) then
        if (snc.note_value<=120) then
          snc.note_value=snc.note_value+1
        end
      end
      if (snc.note_value<120) then
        snc.instrument_value=song.selected_instrument_index-1
      else
        snc.instrument_value=255
      end
      vws.AKM_RTY_1.value=snc.note_value
      akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
    end
  end
end



--2 knob for instrument
local function akm_nc_previous_instrument()
  if (song.transport.edit_mode and AKM_VAL_LOCK[2]) then
    --print("previous_instrument")
    local snc=song.selected_note_column
    if (snc) then
      if (snc.instrument_value>0) and (snc.instrument_value<=#song.instruments) then
        snc.instrument_value=snc.instrument_value-1
        song.selected_instrument_index=snc.instrument_value+1
      elseif (snc.instrument_value>#song.instruments-1) then
        snc.instrument_value=#song.instruments-1
        song.selected_instrument_index=#song.instruments
      end
      vws.AKM_RTY_2.value=snc.instrument_value
      akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
    end
  end
end

local function akm_nc_next_instrument()
  if (song.transport.edit_mode and AKM_VAL_LOCK[2]) then
    --print("next_instrument")
    local snc=song.selected_note_column
    if (snc) then
      if (snc.instrument_value<#song.instruments-1) then
        snc.instrument_value=snc.instrument_value+1
        song.selected_instrument_index=snc.instrument_value+1
      elseif (snc.instrument_value==#song.instruments-1) then
        snc.instrument_value=255
      end
      vws.AKM_RTY_2.value=snc.instrument_value
      akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
    end
  end
end



--3 knob for volume
local function akm_nc_visible_volume()
  local sst=song.selected_track
  if not (sst.volume_column_visible) then
    sst.volume_column_visible=true
  end
end

local function akm_nc_previous_volume()
  if (song.transport.edit_mode and AKM_VAL_LOCK[3]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.volume_value>0) and (snc.volume_value<=127) then
        snc.volume_value=snc.volume_value-1
      elseif (snc.volume_value==255) then
        snc.volume_value=127
      end
      akm_nc_visible_volume()
      if (snc.volume_value<=127) then
        vws.AKM_RTY_3.value=snc.volume_value*2
      elseif (snc.volume_value==255) then
        vws.AKM_RTY_3.value=snc.volume_value
      end
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end
local function akm_nc_next_volume()
  if (song.transport.edit_mode and AKM_VAL_LOCK[3]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.volume_value<127) then
        snc.volume_value=snc.volume_value+1
      else
        snc.volume_value=255
      end
      akm_nc_visible_volume()
      if (snc.volume_value<=127) then
        vws.AKM_RTY_3.value=snc.volume_value*2
      elseif (snc.volume_value==255) then
        vws.AKM_RTY_3.value=snc.volume_value
      end
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end



--4 knob for panning
local function akm_nc_visible_panning()
  local sst=song.selected_track
  if not (sst.panning_column_visible) then
    sst.panning_column_visible=true
  end
end

local function akm_nc_previous_panning()
  if (song.transport.edit_mode and AKM_VAL_LOCK[4]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.panning_value>0) and (snc.panning_value<=127) then
        snc.panning_value=snc.panning_value-1
      elseif (snc.panning_value==255) then
        snc.panning_value=64--127
      end
      akm_nc_visible_panning()
      if (snc.panning_value<=127) then
        vws.AKM_RTY_4.value=snc.panning_value*2
      elseif (snc.panning_value==255) then
        vws.AKM_RTY_4.value=snc.panning_value
      end
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end
local function akm_nc_next_panning()
  if (song.transport.edit_mode and AKM_VAL_LOCK[4]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.panning_value<127) then
        snc.panning_value=snc.panning_value+1
      else
        snc.panning_value=255
      end
      akm_nc_visible_panning()
      if (snc.panning_value<=127) then
        vws.AKM_RTY_4.value=snc.panning_value*2
      elseif (snc.panning_value==255) then
        vws.AKM_RTY_4.value=snc.panning_value
      end
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end



--5 knob for delay
local function akm_nc_visible_delay()
  local sst=song.selected_track
  if not (sst.delay_column_visible) then
    sst.delay_column_visible=true
  end
end

local function akm_nc_previous_delay()
  if (song.transport.edit_mode and AKM_VAL_LOCK[5]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.delay_value>0) then
        snc.delay_value=snc.delay_value-1
      end
      akm_nc_visible_delay()
      vws.AKM_RTY_5.value=snc.delay_value
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end
local function akm_nc_next_delay()
  if (song.transport.edit_mode and AKM_VAL_LOCK[5]) then
    local snc=song.selected_note_column
    if (snc) then
      if (snc.delay_value<255) then
        snc.delay_value=snc.delay_value+1
      end
      akm_nc_visible_delay(select)
      vws.AKM_RTY_5.value=snc.delay_value
      akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
    end
  end
end


--6 knob for sfx-fx
local function akm_nc_visible_sfx()
  local sst=song.selected_track
  if not (sst.sample_effects_column_visible) then
    sst.sample_effects_column_visible=true
  end
end

local function akm_previous_fx_val()
  if (song.transport.edit_mode and AKM_VAL_LOCK[6]) then
    local snc,sec=song.selected_note_column,song.selected_effect_column
    if (snc) then
      for val=#AKM_SFX,2,-1 do
        if (snc.effect_number_string==AKM_SFX[val]) then
          snc.effect_number_string=AKM_SFX[val-1]
          if (vws.AKM_RTY_6.max~=#AKM_SFX) then
            vws.AKM_RTY_6.max=#AKM_SFX-1
          end
          vws.AKM_RTY_6.value=val-2
          vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
          break
        end
      end
      akm_nc_visible_sfx()
    end
    if (sec) then
      for val=#AKM_EFF,2,-1 do
        if (sec.number_string==AKM_EFF[val]) then
          sec.number_string=AKM_EFF[val-1]
          if (vws.AKM_RTY_6.max~=#AKM_EFF) then
            vws.AKM_RTY_6.max=#AKM_EFF-1
          end
          vws.AKM_RTY_6.value=val-2
          if (string.sub(sec.number_string,1,1)=="Z") then
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
          else
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
          end
          break
        end
      end
    end
  end
end

local function akm_next_fx_val()
  if (song.transport.edit_mode and AKM_VAL_LOCK[6]) then
    local snc,sec=song.selected_note_column,song.selected_effect_column
    if (snc) then
      for val=1,#AKM_SFX-1 do
        if (snc.effect_number_string==AKM_SFX[val]) then
          snc.effect_number_string=AKM_SFX[val+1]
          if (vws.AKM_RTY_6.max~=#AKM_SFX) then
            vws.AKM_RTY_6.max=#AKM_SFX-1
          end
          vws.AKM_RTY_6.value=val
          vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
          break
        end
      end
      akm_nc_visible_sfx()
    end
    if (sec) then
      for val=1,#AKM_EFF-1 do
        if (sec.number_string==AKM_EFF[val]) then
          sec.number_string=AKM_EFF[val+1]
          if (vws.AKM_RTY_6.max~=#AKM_EFF) then
            vws.AKM_RTY_6.max=#AKM_EFF-1
          end
          vws.AKM_RTY_6.value=val
          if (string.sub(sec.number_string,1,1)=="Z") then
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
          else
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
          end
          break
        end
      end
    end
  end
end


--7 knob for amount
local function akm_previous_fx_amo()
  if (song.transport.edit_mode and AKM_VAL_LOCK[7]) then
    local snc,sec=song.selected_note_column,song.selected_effect_column
    if (snc) then
      if (snc.effect_amount_value>0) then
        snc.effect_amount_value=snc.effect_amount_value-1
      end
      vws.AKM_RTY_7.value=snc.effect_amount_value
      vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
      akm_nc_visible_sfx()
    end
    if (sec) then
      if (sec.amount_value>0) then
        sec.amount_value=sec.amount_value-1
      end
      vws.AKM_RTY_7.value=sec.amount_value
      if (string.sub(sec.number_string,1,1)=="Z") then
        vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
      else
        vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
      end
    end
  end
end

local function akm_next_fx_amo()
  if (song.transport.edit_mode and AKM_VAL_LOCK[7]) then
    local snc,sec=song.selected_note_column,song.selected_effect_column
    if (snc) then
      if (snc.effect_amount_value<255) then
        snc.effect_amount_value=snc.effect_amount_value+1
      end
      vws.AKM_RTY_7.value=snc.effect_amount_value
      vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
      akm_nc_visible_sfx()
    end
    if (sec) then
      if (sec.amount_value<255) then
        sec.amount_value=sec.amount_value+1
      end
      vws.AKM_RTY_7.value=sec.amount_value
      if (string.sub(sec.number_string,1,1)=="Z") then
        vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
      else
        vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
      end
    end
  end
end



--8 knob for note/effect columns navigation
local function akm_collapse_col_trk(bol)
  local sti=song.selected_track_index
  local trk=song.selected_track
  local sub=string.sub
  local reverse=string.reverse
  local match=string.match
  local find=string.find
  local max=math.max
  local floor=math.floor
  local has_nc=trk.type==renoise.Track.TRACK_TYPE_SEQUENCER
  local max_nc=1
  local max_ec
  if (has_nc) then
    max_ec=1
  else
    max_ec=1
  end
  for _,pattern in ipairs(song.patterns) do
    local patterntrack=pattern:track(sti)
    if not (patterntrack.is_empty) then
      local lns=patterntrack:lines_in_range(1,pattern.number_of_lines)
      for _,lne in ipairs(lns) do
        if not (lne.is_empty) then
          local lne_str=tostring(lne)
          --note columns
          if (has_nc) then
            local ncol_lne_str=sub(lne_str,0,214)
            ncol_lne_str=reverse(ncol_lne_str)
            local first_match=match(ncol_lne_str,"%d.[1-G]")
            max_nc=(first_match and max(max_nc, 12-floor(find(ncol_lne_str,first_match) / 18))) or max_nc         
          end
          --effect columns
          local ecol_lne_str=reverse(lne_str)
          local ecol_first_match=match(ecol_lne_str,"[1-Z]")
          max_ec=(ecol_first_match and math.max(max_ec, 8-floor(find(ecol_lne_str,ecol_first_match)/7))) or max_ec
        end
      end
    end
  end
  if (bol) then
    if (has_nc) then
      if (song.selected_note_column) then
        trk.visible_note_columns=max_nc
      else
        trk.visible_effect_columns=max_ec
      end
    else
      trk.visible_effect_columns=max_ec
    end
  else
    trk.visible_effect_columns=max_ec
  end
end

local function akm_previous_nc_ec()
  if (AKM_VAL_LOCK[8]) then
    local trk=song.selected_track
    if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      if (song.selected_note_column) then
        if (song.selected_note_column_index>1) then
          song.selected_note_column_index=song.selected_note_column_index-1
          trk.visible_note_columns=song.selected_note_column_index
          vws.AKM_RTY_8.value=math.floor((song.selected_note_column_index)*127/21)
          vws.AKM_TXT_DIGITAL_2.text=("Note Column %s"):format(song.selected_note_column_index)
        end
      else
        if (song.selected_effect_column_index>1) then
          song.selected_effect_column_index=song.selected_effect_column_index-1
          trk.visible_effect_columns=song.selected_effect_column_index
          vws.AKM_RTY_8.value=math.floor((song.selected_effect_column_index+12)*127/21)
          vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
        end
      end
    else
      if (song.selected_effect_column_index>1) then
        song.selected_effect_column_index=song.selected_effect_column_index-1
        trk.visible_effect_columns=song.selected_effect_column_index
        vws.AKM_RTY_8.value=math.floor((song.selected_effect_column_index+12)*127/21)
        vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
      end
    end
    --[[
    if (song.selected_note_column_index==1 or song.selected_effect_column_index==1) then
      akm_collapse_col_trk(true)
    end
    ]]
  end
end

local function akm_next_nc_ec()
  if (AKM_VAL_LOCK[8]) then
    if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      if (song.selected_note_column) then
        if (song.selected_track.visible_note_columns<12 and song.selected_track.visible_note_columns==song.selected_note_column_index) then
          song.selected_track.visible_note_columns=song.selected_note_column_index+1
        end
        if (song.selected_note_column_index<song.selected_track.visible_note_columns) then
          song.selected_note_column_index=song.selected_note_column_index+1
          vws.AKM_RTY_8.value=math.floor((song.selected_note_column_index+1)*127/21)
          vws.AKM_TXT_DIGITAL_2.text=("Note Column %s"):format(song.selected_note_column_index)
        end
      else
        if (song.selected_track.visible_effect_columns<8 and song.selected_track.visible_effect_columns==song.selected_effect_column_index) then
          song.selected_track.visible_effect_columns=song.selected_effect_column_index+1
        end
        if (song.selected_effect_column_index<song.selected_track.visible_effect_columns) then
          song.selected_effect_column_index=song.selected_effect_column_index+1
          vws.AKM_RTY_8.value=math.floor((song.selected_effect_column_index+1+12)*127/21)
          vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
        end
      end
    else
      if (song.selected_track.visible_effect_columns<8 and song.selected_track.visible_effect_columns==song.selected_effect_column_index) then
        song.selected_track.visible_effect_columns=song.selected_effect_column_index+1
      end
      if (song.selected_effect_column_index<song.selected_track.visible_effect_columns) then
        song.selected_effect_column_index=song.selected_effect_column_index+1
        vws.AKM_RTY_8.value=math.floor((song.selected_effect_column_index+1+12)*127/21)
        vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
      end
    end
  end
end



--9 knob for step lenght
local function akm_step_lenght(value)
  if (AKM_VAL_LOCK[9]) then
    local sli=song.selected_line_index
    local ssi=song.selected_sequence_index
    local nol=song.selected_pattern.number_of_lines
    local edit_step=song.transport.edit_step
    if (value>0) then
      if (nol>=sli+edit_step) then
        song.selected_line_index=sli+edit_step
      else
        local difference=edit_step-(nol-sli)
        --print(difference)
        if (ssi+1<=#song.sequencer.pattern_sequence) then
          song.selected_sequence_index=ssi+1
          if (difference<=song.selected_pattern.number_of_lines) then
            song.selected_line_index=difference
          else
            song.selected_line_index=1
          end
        else
          song.selected_line_index=song.selected_pattern.number_of_lines
        end
      end
    else
      local difference=edit_step-sli
      --print(difference)
      if (sli>edit_step) then
        song.selected_line_index=song.selected_line_index-edit_step
      else
        if (ssi-1>=1) then
          song.selected_sequence_index=ssi-1
          if (1<=song.selected_pattern.number_of_lines-difference) then
            song.selected_line_index=song.selected_pattern.number_of_lines-difference
          end
        else
          song.selected_line_index=1
        end
      end
    end
    vws.AKM_RTY_9.value=edit_step*127/64
    vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(song.selected_track_index,ssi-1,sli-1)
  end
end


--- ---faders (8+1 faders)
--1 fader --> (note value)
local function akm_nc_note_val(val,lvl)
  if (AKM_VAL_LOCK[1]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      if (snc) then
        snc.note_value=val
        if (snc.note_value<120) then
          snc.instrument_value=song.selected_instrument_index-1
        else
          snc.instrument_value=255
        end
        akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
      end
    end
    if (lvl==1) then vws.AKM_SLD_1.value=vws.AKM_SLD_1.max
    elseif (lvl==2) then vws.AKM_SLD_1.value=vws.AKM_SLD_1.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_1.value=vws.AKM_SLD_1.max/2 
    elseif (lvl==4) then vws.AKM_SLD_1.value=vws.AKM_SLD_1.max/4
    elseif (lvl==5) then vws.AKM_SLD_1.value=vws.AKM_SLD_1.min
    end
  end
end

--2 fader --> (instrument value)
local function akm_nc_instrument_val(val,lvl)
  if (AKM_VAL_LOCK[2]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      if (snc) then
        snc.instrument_value=val
        akm_mnt_nte_ins(snc.note_value,snc.instrument_value)
      end
    end
    if (lvl==1) then vws.AKM_SLD_2.value=vws.AKM_SLD_2.max
    elseif (lvl==2) then vws.AKM_SLD_2.value=vws.AKM_SLD_2.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_2.value=vws.AKM_SLD_2.max/2 
    elseif (lvl==4) then vws.AKM_SLD_2.value=vws.AKM_SLD_2.max/4
    elseif (lvl==5) then vws.AKM_SLD_2.value=vws.AKM_SLD_2.min
    end
  end
end

--3 fader --> (volume value)
local function akm_nc_volume_val(val,lvl)
  if (AKM_VAL_LOCK[3]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      if (snc) then
        if (val>127 and val<255) then
          snc.volume_value=127
        else
          snc.volume_value=val
        end
        akm_nc_visible_volume()
        akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
      end
    end
    if (lvl==1) then vws.AKM_SLD_3.value=vws.AKM_SLD_3.max
    elseif (lvl==2) then vws.AKM_SLD_3.value=vws.AKM_SLD_3.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_3.value=vws.AKM_SLD_3.max/2 
    elseif (lvl==4) then vws.AKM_SLD_3.value=vws.AKM_SLD_3.max/4
    elseif (lvl==5) then vws.AKM_SLD_3.value=vws.AKM_SLD_3.min
    end
  end
end

--4 fader --> (panning value)
local function akm_nc_panning_val(val,lvl)
  if (AKM_VAL_LOCK[4]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      if (snc) then
        if (val>127 and val<255) then
          snc.panning_value=128
        else
          snc.panning_value=val
        end
        akm_nc_visible_panning()
        akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
      end
    end
    if (lvl==1) then vws.AKM_SLD_4.value=vws.AKM_SLD_4.max
    elseif (lvl==2) then vws.AKM_SLD_4.value=vws.AKM_SLD_4.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_4.value=vws.AKM_SLD_4.max/2 
    elseif (lvl==4) then vws.AKM_SLD_4.value=vws.AKM_SLD_4.max/4
    elseif (lvl==5) then vws.AKM_SLD_4.value=vws.AKM_SLD_4.min
    end
  end
end

--5 fader --> (delay value)
local function akm_nc_delay_val(val,lvl)
  if (AKM_VAL_LOCK[5]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      if (snc) then
        snc.delay_value=val
        akm_nc_visible_delay()
        akm_mnt_vpd(snc.volume_value,snc.panning_value,snc.delay_value)
      end
    end
    if (lvl==1) then vws.AKM_SLD_5.value=vws.AKM_SLD_5.max
    elseif (lvl==2) then vws.AKM_SLD_5.value=vws.AKM_SLD_5.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_5.value=vws.AKM_SLD_5.max/2 
    elseif (lvl==4) then vws.AKM_SLD_5.value=vws.AKM_SLD_5.max/4
    elseif (lvl==5) then vws.AKM_SLD_5.value=vws.AKM_SLD_5.min
    end
  end
end

--6 fader --> (sfx/fx)
local function akm_sfx_fx_val(val,lvl)
  if (AKM_VAL_LOCK[6]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      local sec=song.selected_effect_column
      if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
        if (snc) then
          if (vws.AKM_SLD_6.max~=#AKM_SFX) then
            vws.AKM_SLD_6.max=#AKM_SFX
          end
          if (val<=#AKM_SFX) then
            snc.effect_number_string=AKM_SFX[val]
          end
          akm_nc_visible_sfx()
          vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
        else
          if (vws.AKM_SLD_6.max~=#AKM_EFF) then
            vws.AKM_SLD_6.max=#AKM_EFF
          end
          sec.number_string=AKM_EFF[val]
          if (string.sub(sec.number_string,1,1)=="Z") then
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
          else
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
          end
        end
      else
        if (vws.AKM_SLD_6.max~=#AKM_EFF) then
          vws.AKM_SLD_6.max=#AKM_EFF
        end
        sec.number_string=AKM_EFF[val]
        if (string.sub(sec.number_string,1,1)=="Z") then
          vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
        else
          vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
        end
      end
    end
    if (lvl==1) then vws.AKM_SLD_6.value=vws.AKM_SLD_6.max
    elseif (lvl==2) then vws.AKM_SLD_6.value=vws.AKM_SLD_6.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_6.value=vws.AKM_SLD_6.max/2 
    elseif (lvl==4) then vws.AKM_SLD_6.value=vws.AKM_SLD_6.max/4
    elseif (lvl==5) then vws.AKM_SLD_6.value=vws.AKM_SLD_6.min
    end
  end
end

--7 fader --> (amount effect)
local function akm_amount_val(val,lvl)
  if (AKM_VAL_LOCK[7]) then
    if (song.transport.edit_mode) then
      local snc=song.selected_note_column
      local sec=song.selected_effect_column
      if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
        if (snc) then
          snc.effect_amount_value=val
          akm_nc_visible_sfx()
          vws.AKM_TXT_DIGITAL_2.text=("sFX: %s%.2X"):format(string.sub(snc.effect_number_string,2),snc.effect_amount_value)
        else
          sec.amount_value=val
          if (string.sub(sec.number_string,1,1)=="Z") then
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
          else
            vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
          end
        end
      else
        sec.amount_value=val
        if (string.sub(sec.number_string,1,1)=="Z") then
          vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(sec.number_string,sec.amount_value)
        else
          vws.AKM_TXT_DIGITAL_2.text=("FX: %s%.2X"):format(string.sub(sec.number_string,2),sec.amount_value)
        end
      end
    end
    if (lvl==1) then vws.AKM_SLD_7.value=vws.AKM_SLD_7.max
    elseif (lvl==2) then vws.AKM_SLD_7.value=vws.AKM_SLD_7.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_7.value=vws.AKM_SLD_7.max/2 
    elseif (lvl==4) then vws.AKM_SLD_7.value=vws.AKM_SLD_7.max/4
    elseif (lvl==5) then vws.AKM_SLD_7.value=vws.AKM_SLD_7.min
    end
  end
end

--8 fader --> (note/effect column)
local function akm_nc_ec_val(val,lvl)
  if (AKM_VAL_LOCK[8]) then
    local snc=song.selected_note_column
    local sec=song.selected_effect_column
    if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
      if (val<=12) then
        if (song.selected_track.visible_note_columns<val) then
          song.selected_track.visible_note_columns=val
        end
        song.selected_note_column_index=val
        vws.AKM_TXT_DIGITAL_2.text=("Note Column %s"):format(song.selected_note_column_index)
      else
        if (song.selected_track.visible_effect_columns<val-12) then
          song.selected_track.visible_effect_columns=val-12
        end
        song.selected_effect_column_index=val-12
        vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
      end
    else
      if (val>=13) then
        if (song.selected_track.visible_effect_columns<val-12) then
          song.selected_track.visible_effect_columns=val-12
        end
        song.selected_effect_column_index=val-12
        vws.AKM_TXT_DIGITAL_2.text=("Effect Column %s"):format(song.selected_effect_column_index)
      end
    end
    --[[
    if (val==1 or val==13) then
      akm_collapse_col_trk(true)
    end
    ]]
    if (lvl==1) then vws.AKM_SLD_8.value=vws.AKM_SLD_8.max
    elseif (lvl==2) then vws.AKM_SLD_8.value=vws.AKM_SLD_8.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_8.value=vws.AKM_SLD_8.max/2 
    elseif (lvl==4) then vws.AKM_SLD_8.value=vws.AKM_SLD_8.max/4
    elseif (lvl==5) then vws.AKM_SLD_8.value=vws.AKM_SLD_8.min
    end
  end
end

--9 fader --> (step lenght)
local function akm_sq_step_val(val,lvl)
  if (AKM_VAL_LOCK[9]) then
    local nol=song.selected_pattern.number_of_lines
    if (val<nol) then
      song.selected_line_index=val+1
    else
      song.selected_line_index=nol
    end
    vws.AKM_TXT_DIGITAL_2.text=("Track %2d | Sequence %.2d\nLine %.2d"):format(song.selected_track_index,song.selected_sequence_index-1,song.selected_line_index-1)
    if (lvl==1) then vws.AKM_SLD_9.value=vws.AKM_SLD_9.max
    elseif (lvl==2) then vws.AKM_SLD_9.value=vws.AKM_SLD_9.max/4*3
    elseif (lvl==3) then vws.AKM_SLD_9.value=vws.AKM_SLD_9.max/2 
    elseif (lvl==4) then vws.AKM_SLD_9.value=vws.AKM_SLD_9.max/4
    elseif (lvl==5) then vws.AKM_SLD_9.value=vws.AKM_SLD_9.min
    end
  end
end

--- ---filter/select buttons (8+1 multicolor buttuns)



-------------------------------------------------------------------------------------------------
--output device
-------------------------------------------------------------------------------------------------
local AKM_MIDI_DEVICE_OUT=nil
local function akm_output_midi(out_device_name)
  if not table.is_empty(AKM_OUTPUTS) then
    if not out_device_name then
      return
    else
      AKM_MIDI_DEVICE_OUT=renoise.Midi.create_output_device(out_device_name)
    end 
  end
end


local function akm_output_midi_invoke(tbl)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    --local message={0x90,0x5E,0x7F}--{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6D,0x7F,0xF7}
    AKM_MIDI_DEVICE_OUT:send(tbl[1]) --{tbl[1],tbl[2],tbl[3]} --send(message)
    print(("%X %X %X | %s"):format(tbl[1][1],tbl[1][2],tbl[1][3],AKM_MIDI_DEVICE_OUT.name))
  end
end


local akm_tbl_rules={
  --track controls
  {{0x90,0x08,0x7F}, "solo_sel1_on"},
  {{0x90,0x08,0x00}, "solo_sel1_off"},
  {{0x90,0x09,0x7F}, "solo_sel2_on"},
  {{0x90,0x09,0x00}, "solo_sel2_off"},
  {{0x90,0x0A,0x7F}, "solo_sel3_on"},
  {{0x90,0x0A,0x00}, "solo_sel3_off"},
  {{0x90,0x0B,0x7F}, "solo_sel4_on"},
  {{0x90,0x0B,0x00}, "solo_sel4_off"},
  {{0x90,0x0C,0x7F}, "solo_sel5_on"},
  {{0x90,0x0C,0x00}, "solo_sel5_off"},
  {{0x90,0x0D,0x7F}, "solo_sel6_on"},
  {{0x90,0x0D,0x00}, "solo_sel6_off"},
  {{0x90,0x0E,0x7F}, "solo_sel7_on"},
  {{0x90,0x0E,0x00}, "solo_sel7_off"},
  {{0x90,0x0F,0x7F}, "solo_sel8_on"},
  {{0x90,0x0F,0x00}, "solo_sel8_off"},
    
  {{0x90,0x10,0x7F}, "mute_sel1_on"},
  {{0x90,0x10,0x00}, "mute_sel1_off"},
  {{0x90,0x11,0x7F}, "mute_sel2_on"},
  {{0x90,0x11,0x00}, "mute_sel2_off"},
  {{0x90,0x12,0x7F}, "mute_sel3_on"},
  {{0x90,0x12,0x00}, "mute_sel3_off"},
  {{0x90,0x13,0x7F}, "mute_sel4_on"},
  {{0x90,0x13,0x00}, "mute_sel4_off"},
  {{0x90,0x14,0x7F}, "mute_sel5_on"},
  {{0x90,0x14,0x00}, "mute_sel5_off"},
  {{0x90,0x15,0x7F}, "mute_sel6_on"},
  {{0x90,0x15,0x00}, "mute_sel6_off"},
  {{0x90,0x16,0x7F}, "mute_sel7_on"},
  {{0x90,0x16,0x00}, "mute_sel7_off"},
  {{0x90,0x17,0x7F}, "mute_sel8_on"},
  {{0x90,0x17,0x00}, "mute_sel8_off"},
  
  {{0x90,0x00,0x7F}, "record_sel1_on"},
  {{0x90,0x00,0x00}, "record_sel1_off"},
  {{0x90,0x01,0x7F}, "record_sel2_on"},
  {{0x90,0x01,0x00}, "record_sel2_off"},
  {{0x90,0x02,0x7F}, "record_sel3_on"},
  {{0x90,0x02,0x00}, "record_sel3_off"},
  {{0x90,0x03,0x7F}, "record_sel4_on"},
  {{0x90,0x03,0x00}, "record_sel4_off"},
  {{0x90,0x04,0x7F}, "record_sel5_on"},
  {{0x90,0x04,0x00}, "record_sel5_off"},
  {{0x90,0x05,0x7F}, "record_sel6_on"},
  {{0x90,0x05,0x00}, "record_sel6_off"},
  {{0x90,0x06,0x7F}, "record_sel7_on"},
  {{0x90,0x06,0x00}, "record_sel7_off"},
  {{0x90,0x07,0x7F}, "record_sel8_on"},
  {{0x90,0x07,0x00}, "record_sel8_off"},
  
  
  {{0x90,0x4A,0x7F}, "read_on"},
  {{0x90,0x4A,0x00}, "read_off"},
  
  {{0x90,0x4B,0x7F}, "write_on"},
  {{0x90,0x4B,0x00}, "write_off"},

  --global controls
  {{0x90,0x50,0x7F}, "save_on"},
  {{0x90,0x50,0x00}, "save_off"},
  
  {{0x90,0x57,0x7F}, "in_on"},
  {{0x90,0x57,0x00}, "in_off"},
  
  {{0x90,0x58,0x7F}, "out_on"},
  {{0x90,0x58,0x00}, "out_off"},
  
  --[[
  {{0x90,0x59,0x7F}, "metro_on"},
  {{0x90,0x59,0x00}, "metro_off"},
  
  {{0x90,0x51,0x7F}, "undo_on"},
  {{0x90,0x51,0x00}, "undo_off"},
  ]]

  --transport
  {{0x90,0x5B,0x7F}, "rewind_on"},
  {{0x90,0x5B,0x00}, "rewind_off"},

  {{0x90,0x5C,0x7F}, "forward_on"},
  {{0x90,0x5C,0x00}, "forward_off"},

  {{0x90,0x5D,0x7F}, "stop_on"},
  {{0x90,0x5D,0x00}, "stop_off"},
  
  --[[
  {{0x90,0x5E,0x7F}, "play_on"},
  {{0x90,0x5E,0x00}, "play_off"},

  {{0x90,0x5F,0x7F}, "rec_on"},
  {{0x90,0x5F,0x00}, "rec_off"},

  {{0x90,0x56,0x7F}, "loop_on"},
  {{0x90,0x56,0x00}, "loop_off"},
  ]]
  
  --browses center controls
  {{0x90,0x62,0x7F}, "left_button_on"},   --{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1A,0x7F,0xF7}
  {{0x90,0x62,0x00}, "left_button_off"},  --{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1A,0x00,0xF7}

  {{0x90,0x63,0x7F}, "right_button_on"},  --{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1B,0x7F,0xF7}
  {{0x90,0x63,0x00}, "right_button_off"}, --{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1B,0x00,0xF7}
  
  --{{0x90,0x54,0x7F}, "dial_button_on"},
  --{{0x90,0x54,0x00}, "dial_button_off"},
  
  --live/bank circular buttons
  {{0x90,0x31,0x7F}, "live_part_1_on"},
  {{0x90,0x31,0x00}, "live_part_1_off"},

  {{0x90,0x30,0x7F}, "live_part_2_on"},
  {{0x90,0x30,0x00}, "live_part_2_off"},
  
  {{0x90,0x2F,0x7F}, "bank_next_on"},
  {{0x90,0x2F,0x00}, "bank_next_off"},
  
  {{0x90,0x2E,0x7F}, "bank_previous_on"},
  {{0x90,0x2E,0x00}, "bank_previous_off"},

  
  --filter/select buttons
  {{0x90,0x18,0x7F}, "select_btn1_on"},
  {{0x90,0x18,0x00}, "select_btn1_off"},
  
  {{0x90,0x19,0x7F}, "select_btn2_on"},
  {{0x90,0x19,0x00}, "select_btn2_off"},
  
  {{0x90,0x1A,0x7F}, "select_btn3_on"},
  {{0x90,0x1A,0x00}, "select_btn3_off"},
  
  {{0x90,0x1B,0x7F}, "select_btn4_on"},
  {{0x90,0x1B,0x00}, "select_btn4_off"},
  
  {{0x90,0x1C,0x7F}, "select_btn5_on"},
  {{0x90,0x1C,0x00}, "select_btn5_off"},
  
  {{0x90,0x1D,0x7F}, "select_btn6_on"},
  {{0x90,0x1D,0x00}, "select_btn6_off"},
  
  {{0x90,0x1E,0x7F}, "select_btn7_on"},
  {{0x90,0x1E,0x00}, "select_btn7_off"},
  
  {{0x90,0x1F,0x7F}, "select_btn8_on"},
  {{0x90,0x1F,0x00}, "select_btn8_off"},
}



local function akm_x3_sel_leds(num)
  local led={1,3,5,7,9,11,13,15}
  local time={200,120,3}
  local function led_off()
    if (AKM_MIDI_DEVICE_OUT) then
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]+33][1])
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]+17][1])
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]+1][1])
    end
    for sel=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(sel)].color=AKM_CLR.DEFAULT
    end
  end
  local function led_on()
    if (AKM_MIDI_DEVICE_OUT) then
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]+32][1])
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]+16][1])
      AKM_MIDI_DEVICE_OUT:send(akm_tbl_rules[led[num]][1])
    end
    for sel=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(sel)].color=AKM_CLR.MARKER
    end  
  end

  local function step_4()
    led_off()
    if rnt:has_timer(step_4) then
      rnt:remove_timer(step_4)
    end
    --[[
    if not rnt:has_timer(step_5) then
      rnt:add_timer(step_5,time[2])
    end
    ]]
  end  
  local function step_3()
    led_on()
    if rnt:has_timer(step_3) then
      rnt:remove_timer(step_3)
    end
    if not rnt:has_timer(step_4) then
      rnt:add_timer(step_4,time[2])
    end
  end
  local function step_2()
    led_off()
    if rnt:has_timer(step_2) then
      rnt:remove_timer(step_2)
    end
    if not rnt:has_timer(step_3) then
      rnt:add_timer(step_3,time[2])
    end
  end
  local function step_1()
    led_on()
    if rnt:has_timer(step_1) then
      rnt:remove_timer(step_1)
    end  
    if not rnt:has_timer(step_2) then
      rnt:add_timer(step_2,time[2])
    end
  end
  local function launch()
    if not rnt:has_timer(step_1) then
      rnt:add_timer(step_1,time[1])
    end
  end
  return launch()
end


--state x3 buttons
local function akm_state_select(num)
  local state={
    "Select 1 (Sound)\nSolo | Mute | Record",
    "Select 2 (Clear)\nRow | NC/EC | Ptt-Tr",
    "Select 3\nn/a",
    "Select 4\nn/a",
    "Select 5\nn/a",
    "Select 6\nn/a",
    "Select 7\nn/a",
    "Select 8\nn/a"
  }
  vws.AKM_TXT_DIGITAL_1.text=state[num]
  if (num==1) then
    local btt={"Solo","Mute","Record"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  if (num==2) then
    local btt={"Row","NC/EC","Ptt-Tr"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  ---
  if (num>=3) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  --[[
  if (num==4) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  if (num==5) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  if (num==6) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  if (num==7) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  if (num==8) then
    local btt={"n/a","n/a","n/a"}
    for i=1,3 do
      vws[("AKM_BTT_DAW_A_%s"):format(i)].text=btt[i]
    end
  end
  ]]
end



--general functions
local function akm_fun_gen(rule)
  --print("rule:",rule)
  if (rule=="solo_sel1_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_1() end
  if (rule=="solo_sel1_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel1_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_1() end
  if (rule=="mute_sel1_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02})end
  if (rule=="record_sel1_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_1_add_timer() end
  if (rule=="record_sel1_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_record_1_remove_timer(), akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel2_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_2() end
  if (rule=="solo_sel2_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel2_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_2() end
  if (rule=="mute_sel2_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel2_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_2() end
  if (rule=="record_sel2_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel3_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_3() end
  if (rule=="solo_sel3_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel3_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_3() end
  if (rule=="mute_sel3_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel3_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_3() end
  if (rule=="record_sel3_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel4_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_4() end
  if (rule=="solo_sel4_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel4_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_4() end
  if (rule=="mute_sel4_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel4_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_4() end
  if (rule=="record_sel4_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel5_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_5() end
  if (rule=="solo_sel5_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel5_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_5() end
  if (rule=="mute_sel5_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel5_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_5() end
  if (rule=="record_sel5_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel6_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_6() end
  if (rule=="solo_sel6_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel6_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_6() end
  if (rule=="mute_sel6_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel6_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_6() end
  if (rule=="record_sel6_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
     
  if (rule=="solo_sel7_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_7() end
  if (rule=="solo_sel7_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel7_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_7() end
  if (rule=="mute_sel7_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel7_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_7() end
  if (rule=="record_sel7_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="solo_sel8_on") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.MARKER return akm_solo_8() end
  if (rule=="solo_sel8_off") then vws.AKM_BTT_DAW_A_1.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="mute_sel8_on") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.MARKER return akm_mute_8() end
  if (rule=="mute_sel8_off") then vws.AKM_BTT_DAW_A_2.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  if (rule=="record_sel8_on") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.MARKER return akm_record_8() end
  if (rule=="record_sel8_off") then vws.AKM_BTT_DAW_A_3.color=AKM_CLR.DEFAULT return akm_led_rgb_sel({0x22,0x29},{0x02,0x02,0x02}) end
  
  if (rule=="read_on") then vws.AKM_BTT_DAW_A_4.color=AKM_CLR.MARKER return akm_read_add_timer() end
  if (rule=="read_off") then vws.AKM_BTT_DAW_A_4.color=AKM_CLR.DEFAULT return akm_read_remove_timer() end

  if (rule=="write_on") then vws.AKM_BTT_DAW_A_5.color=AKM_CLR.MARKER return akm_write_add_timer() end
  if (rule=="write_off") then vws.AKM_BTT_DAW_A_5.color=AKM_CLR.DEFAULT return akm_write_remove_timer() end
  
  if (rule=="save_on") then vws.AKM_BTT_DAW_A_6.color=AKM_CLR.MARKER return akm_save_on() end
  if (rule=="save_off") then vws.AKM_BTT_DAW_A_6.color=AKM_CLR.DEFAULT return akm_save_off() end

  if (rule=="in_on") then vws.AKM_BTT_DAW_A_7.color=AKM_CLR.MARKER return end
  if (rule=="in_off") then vws.AKM_BTT_DAW_A_7.color=AKM_CLR.DEFAULT return akm_in() end

  if (rule=="out_on") then vws.AKM_BTT_DAW_A_8.color=AKM_CLR.MARKER return end
  if (rule=="out_off") then vws.AKM_BTT_DAW_A_8.color=AKM_CLR.DEFAULT return akm_out() end
  
  if (rule=="rewind_on") then vws.AKM_BTT_DAW_B_1.color=AKM_CLR.MARKER return akm_rewind_repeat() end
  if (rule=="rewind_off") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6A,0x07,0xF7} vws.AKM_BTT_DAW_B_1.color=AKM_CLR.DEFAULT return akm_rewind_repeat(true) end

  if (rule=="forward_on") then vws.AKM_BTT_DAW_B_2.color=AKM_CLR.MARKER return akm_forward_repeat() end
  if (rule=="forward_off") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6B,0x07,0xF7} vws.AKM_BTT_DAW_B_2.color=AKM_CLR.DEFAULT return akm_forward_repeat(true) end

  if (rule=="stop_on") then vws.AKM_BTT_DAW_B_3.color=AKM_CLR.MARKER AKM_STOP_STATUS=true return akm_stop() end
  if (rule=="stop_off") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6C,0x07,0xF7} vws.AKM_BTT_DAW_B_3.color=AKM_CLR.DEFAULT AKM_STOP_STATUS=false end
  
  if (rule=="left_button_on") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1A,0x7F,0xF7} vws.AKM_BTT_LEFT.color=AKM_CLR.MARKER return akm_left_button_repeat() end
  if (rule=="left_button_off") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1A,0x07,0xF7} vws.AKM_BTT_LEFT.color=AKM_CLR.DEFAULT return akm_left_button_repeat(true) end

  if (rule=="right_button_on") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1B,0x7F,0xF7} vws.AKM_BTT_RIGHT.color=AKM_CLR.MARKER return akm_right_button_repeat() end
  if (rule=="right_button_off") then AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x1B,0x07,0xF7} vws.AKM_BTT_RIGHT.color=AKM_CLR.DEFAULT return akm_right_button_repeat(true) end
  
  --if (rule=="dial_button_on") then vws.AKM_BMP_DIAL.visible=false return end  --dial logo off
  --if (rule=="dial_button_off") then vws.AKM_BMP_DIAL.visible=true return end  --dial logo on
  
  if (rule=="live_part_1_on") then vws.AKM_PN_UP_DOWN_2.visible=false vws.AKM_PN_UP_DOWN_1.visible=true vws.AKM_BTT_LIVE_1.color=AKM_CLR.MARKER return akm_live_part_1_repeat() end
  if (rule=="live_part_1_off") then vws.AKM_PN_UP_DOWN_2.visible=false vws.AKM_PN_UP_DOWN_1.visible=true vws.AKM_BTT_LIVE_1.color=AKM_CLR.DEFAULT return akm_live_part_1_repeat(true) end

  if (rule=="live_part_2_on") then vws.AKM_PN_UP_DOWN_2.visible=false vws.AKM_PN_UP_DOWN_1.visible=true vws.AKM_BTT_LIVE_2.color=AKM_CLR.MARKER return akm_live_part_2_repeat() end
  if (rule=="live_part_2_off") then vws.AKM_PN_UP_DOWN_2.visible=false vws.AKM_PN_UP_DOWN_1.visible=true vws.AKM_BTT_LIVE_2.color=AKM_CLR.DEFAULT return akm_live_part_2_repeat(true) end
  
  if (rule=="bank_next_on") then vws.AKM_PN_UP_DOWN_1.visible=false vws.AKM_PN_UP_DOWN_2.visible=true vws.AKM_BTT_BANK_1.color=AKM_CLR.MARKER return akm_bank_next_repeat() end
  if (rule=="bank_next_off") then vws.AKM_PN_UP_DOWN_1.visible=false vws.AKM_PN_UP_DOWN_2.visible=true vws.AKM_BTT_BANK_1.color=AKM_CLR.DEFAULT return akm_bank_next_repeat(true) end

  if (rule=="bank_previous_on") then vws.AKM_PN_UP_DOWN_1.visible=false vws.AKM_PN_UP_DOWN_2.visible=true vws.AKM_BTT_BANK_2.color=AKM_CLR.MARKER return akm_bank_previous_repeat() end
  if (rule=="bank_previous_off") then vws.AKM_PN_UP_DOWN_1.visible=false vws.AKM_PN_UP_DOWN_2.visible=true vws.AKM_BTT_BANK_2.color=AKM_CLR.DEFAULT return akm_bank_previous_repeat(true) end
  
  local function distribute_select(num)
    for sel=1,8 do
      if (num==sel) then
        vws[("AKM_BTN_%s"):format(sel)].color=AKM_CLR.MARKER
        akm_state_select(num)
      else
        vws[("AKM_BTN_%s"):format(sel)].color=AKM_CLR.DEFAULT
      end
    end
  end
  for num=1,8 do
    if (rule=="select_btn"..num.."_on") then return distribute_select(num) end
    if (rule=="select_btn"..num.."_off") then AKM_BTT_SEL_RBG[1]=num print(AKM_BTT_SEL_RBG[1]) return akm_x3_sel_leds(num) end
  end
end



-------------------------------------------------------------------------------------------------
--keylab mkii 49. rules
-------------------------------------------------------------------------------------------------
local function akm_fun_rules(r)
  for i=1,#akm_tbl_rules do
    if (r==i) then
      akm_output_midi_invoke(akm_tbl_rules[i])
      akm_fun_gen(akm_tbl_rules[i][2])
      --print("------>",i)
      break
    end
  end
end



-------------------------------------------------------------------------------------------------
--midi functions
-------------------------------------------------------------------------------------------------
local function akm_pad_rgb_clr(pad,rgb)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x16, pad, rgb[1],rgb[2],rgb[3], 0xF7}
  end
end

local AKM_MIDI_DEVICE_IN_1=nil

local function akm_input_midi_1(in_device_name_1)
  if not table.is_empty(AKM_INPUTS) then
    if (in_device_name_1==nil) then
      if (AKM_MIDI_DEVICE_IN_1 and AKM_MIDI_DEVICE_IN_1.is_open) then AKM_MIDI_DEVICE_IN_1:close() end
      return
    else
      local function midi_callback(message)
        assert(#message==3)
        assert(message[1]>=00 and message[1]<=0xFF)
        assert(message[2]>=00 and message[2]<=0xFF)
        assert(message[3]>=00 and message[3]<=0xFF)
        --print(("%X %X %X || %s"):format(message[1],message[2],message[3],in_device_name_2))
        local rgb={}
        for p=1,16 do
              rgb["pad_"..p]={tonumber(("0x%.2X"):format(AKM_PREF["akm_pad_rgb_"..p][1].value)),
                              tonumber(("0x%.2X"):format(AKM_PREF["akm_pad_rgb_"..p][2].value)),
                              tonumber(("0x%.2X"):format(AKM_PREF["akm_pad_rgb_"..p][3].value))
                             }
        end
        rgb["pad_17"]={0x00,0x00,0x00}
        --pad x16 
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x24 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x70,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x24 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x70,rgb["pad_1"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x25 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x71,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x25 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x71,rgb["pad_2"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x26 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x72,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x26 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x72,rgb["pad_3"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x27 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x73,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x27 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x73,rgb["pad_4"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x28 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x74,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x28 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x74,rgb["pad_5"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x29 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x75,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x29 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x75,rgb["pad_6"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2A and message[3]<=0x7F) then return akm_pad_rgb_clr(0x76,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2A and message[3]<=0x7F) then return akm_pad_rgb_clr(0x76,rgb["pad_7"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2B and message[3]<=0x7F) then return akm_pad_rgb_clr(0x77,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2B and message[3]<=0x7F) then return akm_pad_rgb_clr(0x77,rgb["pad_8"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2C and message[3]<=0x7F) then return akm_pad_rgb_clr(0x78,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2C and message[3]<=0x7F) then return akm_pad_rgb_clr(0x78,rgb["pad_9"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2D and message[3]<=0x7F) then return akm_pad_rgb_clr(0x79,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2D and message[3]<=0x7F) then return akm_pad_rgb_clr(0x79,rgb["pad_10"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2E and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7A,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2E and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7A,rgb["pad_11"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x2F and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7B,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x2F and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7B,rgb["pad_12"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x30 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7C,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x30 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7C,rgb["pad_13"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x31 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7D,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x31 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7D,rgb["pad_14"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x32 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7E,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x32 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7E,rgb["pad_15"]) end
        if (message[1]>=0x90 and message[1]<=0x99 and message[2]==0x33 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7F,rgb["pad_17"]) end
        if (message[1]>=0x80 and message[1]<=0x89 and message[2]==0x33 and message[3]<=0x7F) then return akm_pad_rgb_clr(0x7F,rgb["pad_16"]) end

      end
      -- note: sysex callback would be a optional 2nd arg...
      if (AKM_MIDI_DEVICE_IN_1 and AKM_MIDI_DEVICE_IN_1.is_open) then
        return
      else
        AKM_MIDI_DEVICE_IN_1=renoise.Midi.create_input_device(in_device_name_1,midi_callback)
      end
    end
  end
  -- stop dumping with 'AKM_MIDI_DEVICE_IN_2:close()' ...
end


local AKM_MIDI_DEVICE_IN_2=nil

local function akm_input_midi_2(in_device_name_2)
  if not table.is_empty(AKM_INPUTS) then
    if (in_device_name_2==nil) then
      if (AKM_MIDI_DEVICE_IN_2 and AKM_MIDI_DEVICE_IN_2.is_open) then AKM_MIDI_DEVICE_IN_2:close() end
      return
    else
      local function midi_callback(message)
        assert(#message==3)
        assert(message[1]>=00 and message[1]<=0xFF)
        assert(message[2]>=00 and message[2]<=0xFF)
        assert(message[3]>=00 and message[3]<=0xFF)
        --print(("%X %X %X || %s"):format(message[1],message[2],message[3],in_device_name_2))
        
        --- ---pressed & released (led)
        for r=1,#akm_tbl_rules do
          local rule=akm_tbl_rules[r][1]
          if (message[1]==rule[1] and message[2]==rule[2] and message[3]==rule[3]) then
            --print(tbl_rules[r][2])
            return akm_fun_rules(r)
          end          
        end
        
        --[[
        --pad x16
        if (message[1]==0x99 and message[2]==0x24 and message[3]<=0x7F) then print("pad_1 pressed") return end
        
        if (message[1]==0x89 and message[2]==0x24 and message[3]<=0x7F) then 
        
          local sel,ran,rgb=0x80,{0x70,0x7F},{0x7F,0x00,0x00} --red
          akm_led_rgb_pad(sel,ran,rgb)
                
        return end
        ]]
        --- ---invoke commands
        --play, record, loop
        if (message[1]==0x90 and message[2]==0x5E and message[3]==0x00) then return akm_play() end
        if (message[1]==0x90 and message[2]==0x5F and message[3]==0x00) then return akm_edit_mode() end
        if (message[1]==0x90 and message[2]==0x56 and message[3]==0x00) then return akm_loop() end
        
        --metro, undo --> (follow the player's position)
        if (message[1]==0x90 and message[2]==0x59 and message[3]==0x00) then return akm_metro() end
        if (message[1]==0x90 and message[2]==0x51 and message[3]==0x00) then return akm_undo() end
        
        --browses center controls, dial (instruments navigator)
        if (message[1]==0x90 and message[2]==0x54 and message[3]==0x7F) then vws.AKM_BMP_DIAL.visible=false return akm_button_dial_add_timer() end
        if (message[1]==0x90 and message[2]==0x54 and message[3]==0x00) then vws.AKM_BMP_DIAL.visible=true return akm_button_dial_remove_timer() end
        if (message[1]==0xB0 and message[2]==0x3C and message[3]>=0x41) then return akm_left_dial() end
        if (message[1]==0xB0 and message[2]==0x3C and message[3]<=0x40) then return akm_right_dial() end
        
        --encoder 1 note
        if (message[1]==0xB0 and message[2]==0x10 and message[3]>=0x41) then return akm_nc_previous_note() end
        if (message[1]==0xB0 and message[2]==0x10 and message[3]<=0x40) then return akm_nc_next_note() end
        
        --encoder 2 instrument
        if (message[1]==0xB0 and message[2]==0x11 and message[3]>=0x41) then return akm_nc_previous_instrument() end
        if (message[1]==0xB0 and message[2]==0x11 and message[3]<=0x40) then return akm_nc_next_instrument() end
        
        --encoder 3 volume
        if (message[1]==0xB0 and message[2]==0x12 and message[3]>=0x41) then return akm_nc_previous_volume() end
        if (message[1]==0xB0 and message[2]==0x12 and message[3]<=0x40) then return akm_nc_next_volume() end
        
        --encoder 4 panning
        if (message[1]==0xB0 and message[2]==0x13 and message[3]>=0x41) then return akm_nc_previous_panning() end
        if (message[1]==0xB0 and message[2]==0x13 and message[3]<=0x40) then return akm_nc_next_panning() end
        
        --encoder 5 delay
        if (message[1]==0xB0 and message[2]==0x14 and message[3]>=0x41) then return akm_nc_previous_delay() end
        if (message[1]==0xB0 and message[2]==0x14 and message[3]<=0x40) then return akm_nc_next_delay() end
        
        --encoder 6 sample fx
        if (message[1]==0xB0 and message[2]==0x15 and message[3]>=0x41) then return akm_previous_fx_val() end
        if (message[1]==0xB0 and message[2]==0x15 and message[3]<=0x40) then return akm_next_fx_val() end
        
        --encoder 7 effects
        if (message[1]==0xB0 and message[2]==0x16 and message[3]>=0x41) then return akm_previous_fx_amo() end
        if (message[1]==0xB0 and message[2]==0x16 and message[3]<=0x40) then return akm_next_fx_amo() end
        
        --encoder 8 note columns navigation
        if (message[1]==0xB0 and message[2]==0x17 and message[3]>=0x41) then return akm_previous_nc_ec() end
        if (message[1]==0xB0 and message[2]==0x17 and message[3]<=0x40) then return akm_next_nc_ec() end
        
        if (message[1]==0xB0 and message[2]==0x18 and message[3]>=0x41) then return akm_step_lenght(-1) end
        if (message[1]==0xB0 and message[2]==0x18 and message[3]<=0x40) then return akm_step_lenght(1) end
        
        --fader 1 note
        if (message[1]==0xE0 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_note_val(vws.AKM_VFD_VAL_1_1.value,1) end
        if (message[1]==0xE0 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_note_val(vws.AKM_VFD_VAL_1_2.value,2) end
        if (message[1]==0xE0 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_note_val(vws.AKM_VFD_VAL_1_3.value,3) end
        if (message[1]==0xE0 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_note_val(vws.AKM_VFD_VAL_1_4.value,4) end
        if (message[1]==0xE0 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_note_val(vws.AKM_VFD_VAL_1_5.value,5) end
        
        --fader 2 instrument
        --if (message[1]==0xE1 and message[2]<=0x7F and message[3]>=0x40) then return akm_nc_instrument_val(song.selected_instrument_index-1) end
        --if (message[1]==0xE1 and message[2]<=0x7F and message[3]<0x40) then return  akm_nc_instrument_val(255) end
        if (message[1]==0xE1 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_instrument_val(vws.AKM_VFD_VAL_2_1.value,1) end
        if (message[1]==0xE1 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_instrument_val(vws.AKM_VFD_VAL_2_2.value,2) end
        if (message[1]==0xE1 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_instrument_val(vws.AKM_VFD_VAL_2_3.value,3) end
        if (message[1]==0xE1 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_instrument_val(vws.AKM_VFD_VAL_2_4.value,4) end
        if (message[1]==0xE1 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_instrument_val(vws.AKM_VFD_VAL_2_5.value,5) end
        
        --fader 3 volume
        --if (message[1]==0xE2 and message[2]<=0x7F and message[3]>=0x40) then return akm_nc_volume_val(AKM_VPD_VALUES[1]) end
        --if (message[1]==0xE2 and message[2]<=0x7F and message[3]<0x40) then return akm_nc_volume_val(255) end
        if (message[1]==0xE2 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_volume_val(vws.AKM_VFD_VAL_3_1.value,1) end
        if (message[1]==0xE2 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_volume_val(vws.AKM_VFD_VAL_3_2.value,2) end
        if (message[1]==0xE2 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_volume_val(vws.AKM_VFD_VAL_3_3.value,3) end
        if (message[1]==0xE2 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_volume_val(vws.AKM_VFD_VAL_3_4.value,4) end
        if (message[1]==0xE2 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_volume_val(vws.AKM_VFD_VAL_3_5.value,5) end
        
        --fader 4 panning
        --if (message[1]==0xE3 and message[2]<=0x7F and message[3]>=0x5F) then return akm_nc_panning_val(AKM_VPD_VALUES[2]) end
        --if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x5F and message[3]>=0x3F) then return akm_nc_panning_val(AKM_VPD_VALUES[3]) end
        --if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x3F and message[3]>=0x0F) then return akm_nc_panning_val(AKM_VPD_VALUES[4]) end
        --if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x0F) then return akm_nc_panning_val(255) end
        if (message[1]==0xE3 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_panning_val(vws.AKM_VFD_VAL_4_1.value,1) end
        if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_panning_val(vws.AKM_VFD_VAL_4_2.value,2) end
        if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_panning_val(vws.AKM_VFD_VAL_4_3.value,3) end
        if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_panning_val(vws.AKM_VFD_VAL_4_4.value,4) end
        if (message[1]==0xE3 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_panning_val(vws.AKM_VFD_VAL_4_5.value,5) end
        
        --fader 5 delay
        --if (message[1]==0xE4 and message[2]<=0x7F and message[3]>=0x40) then return akm_nc_delay_val(AKM_VPD_VALUES[5]) end
        --if (message[1]==0xE4 and message[2]<=0x7F and message[3]<0x40) then return akm_nc_delay_val(0) end
        if (message[1]==0xE4 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_delay_val(vws.AKM_VFD_VAL_5_1.value,1) end
        if (message[1]==0xE4 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_delay_val(vws.AKM_VFD_VAL_5_2.value,2) end
        if (message[1]==0xE4 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_delay_val(vws.AKM_VFD_VAL_5_3.value,3) end
        if (message[1]==0xE4 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_delay_val(vws.AKM_VFD_VAL_5_4.value,4) end
        if (message[1]==0xE4 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_delay_val(vws.AKM_VFD_VAL_5_5.value,5) end
        
        --fader 6 sfx/fx
        if (message[1]==0xE5 and message[2]<=0x7F and message[3]>0x64) then return akm_sfx_fx_val(vws.AKM_VFD_VAL_6_1.value,1) end
        if (message[1]==0xE5 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_sfx_fx_val(vws.AKM_VFD_VAL_6_2.value,2) end
        if (message[1]==0xE5 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_sfx_fx_val(vws.AKM_VFD_VAL_6_3.value,3) end
        if (message[1]==0xE5 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_sfx_fx_val(vws.AKM_VFD_VAL_6_4.value,4) end
        if (message[1]==0xE5 and message[2]<=0x7F and message[3]<0x19) then return akm_sfx_fx_val(vws.AKM_VFD_VAL_6_5.value,5) end
        
        --fader 7 amount sfx/fx
        if (message[1]==0xE6 and message[2]<=0x7F and message[3]>0x64) then return akm_amount_val(vws.AKM_VFD_VAL_7_1.value,1) end
        if (message[1]==0xE6 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_amount_val(vws.AKM_VFD_VAL_7_2.value,2) end
        if (message[1]==0xE6 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_amount_val(vws.AKM_VFD_VAL_7_3.value,3) end
        if (message[1]==0xE6 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_amount_val(vws.AKM_VFD_VAL_7_4.value,4) end
        if (message[1]==0xE6 and message[2]<=0x7F and message[3]<0x19) then return akm_amount_val(vws.AKM_VFD_VAL_7_5.value,5) end
        
        --fader 8 note/effect column
        if (message[1]==0xE7 and message[2]<=0x7F and message[3]>0x64) then return akm_nc_ec_val(vws.AKM_VFD_VAL_8_1.value,1) end
        if (message[1]==0xE7 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_nc_ec_val(vws.AKM_VFD_VAL_8_2.value,2) end
        if (message[1]==0xE7 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_nc_ec_val(vws.AKM_VFD_VAL_8_3.value,3) end
        if (message[1]==0xE7 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_nc_ec_val(vws.AKM_VFD_VAL_8_4.value,4) end
        if (message[1]==0xE7 and message[2]<=0x7F and message[3]<0x19) then return akm_nc_ec_val(vws.AKM_VFD_VAL_8_5.value,5) end
        
        --fader 9 step lenght
        if (message[1]==0xE8 and message[2]<=0x7F and message[3]>0x64) then return akm_sq_step_val(vws.AKM_VFD_VAL_9_1.value,1) end
        if (message[1]==0xE8 and message[2]<=0x7F and message[3]<0x64 and message[3]>=0x4B) then return akm_sq_step_val(vws.AKM_VFD_VAL_9_2.value,2) end
        if (message[1]==0xE8 and message[2]<=0x7F and message[3]<0x4B and message[3]>=0x32) then return akm_sq_step_val(vws.AKM_VFD_VAL_9_3.value,3) end
        if (message[1]==0xE8 and message[2]<=0x7F and message[3]<0x32 and message[3]>=0x19) then return akm_sq_step_val(vws.AKM_VFD_VAL_9_4.value,4) end
        if (message[1]==0xE8 and message[2]<=0x7F and message[3]<0x19) then return akm_sq_step_val(vws.AKM_VFD_VAL_9_5.value,5) end
        
        --text sysex
        --if (message[1]==0xB0 and message[2]==0x74 and message[3]==0x7F) then print("Category") end
        --if (message[1]==0xB0 and message[2]==0x75 and message[3]==0x7F) then print("Preset") end
        --if (message[1]==0xB0 and message[2]==0x76 and message[3]==0x7F) then print("Analog Lab") end
        --{0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x00,0x15,0x7F,0xF7}
        
        
        

        
        
        
        
        
        
      end
      -- note: sysex callback would be a optional 2nd arg...
      if (AKM_MIDI_DEVICE_IN_2 and AKM_MIDI_DEVICE_IN_2.is_open) then
        return
      else
        AKM_MIDI_DEVICE_IN_2=renoise.Midi.create_input_device(in_device_name_2,midi_callback)
      end
    end
  end
  -- stop dumping with 'AKM_MIDI_DEVICE_IN_2:close()' ...
end


local function akm_check_midi_on()
  --AKM_INPUTS=renoise.Midi.available_input_devices()
  for i=1,#renoise.Midi.available_input_devices() do
    AKM_INPUTS[i]=(" %s"):format(renoise.Midi.available_input_devices()[i])
  end
  
  
  if not table.is_empty(AKM_INPUTS) then
    vws.AKM_PP_DEVICE_IN_1.items=AKM_INPUTS
    vws.AKM_PP_DEVICE_IN_2.items=AKM_INPUTS
  end
  local function show_mess()
    AKM_ON_OFF=true akm_on_off()
    if (vws.AKM_PP_DEVICE_NAME.value==1) then
      return rna:show_warning("AKM: The in device \"MIDIIN2 (KeyLab mkII 49)\" is not conected!\n\n"
                            .."Do you have the \"KeyLab mkII 49\" MIDI controller\nconnected correctly?")
    end
    if (vws.AKM_PP_DEVICE_NAME.value==2) then
      return rna:show_warning("AKM: The in device \"MIDIIN2 (KeyLab mkII 61)\" is not conected!\n\n"
                            .."Do you have the \"KeyLab mkII 61\" MIDI controller\nconnected correctly?")
    end
    if (vws.AKM_PP_DEVICE_NAME.value==3) then
      return rna:show_warning("AKM: The in device \"MIDIIN2 (KeyLab mkII 88)\" is not conected!\n\n"
                            .."Do you have the \"KeyLab mkII 88\" MIDI controller\nconnected correctly?")
    end
  end
  
  if (AKM_LOCK_IO_DEVICES) then
    --selecte default number of in device
    local in_device_name_1=AKM_INPUTS[vws.AKM_PP_DEVICE_IN_1.value]
    local in_device_name_2=AKM_INPUTS[vws.AKM_PP_DEVICE_IN_2.value]
    --print("AKM dev_in:",vws.AKM_PP_DEVICE_IN_2.value,in_device_name_2)
    AKM_ACTIVATE=true
    akm_input_midi_2(string.sub(in_device_name_2,2))
  else
    --autoselect number of in device
    if table.is_empty(AKM_INPUTS) then
      return show_mess()
    else
      local status=true
      if (vws.AKM_PP_DEVICE_NAME.value==1) then
        for dev=1,#AKM_INPUTS do
          if (AKM_INPUTS[dev]==" MIDIIN2 (KeyLab mkII 49)") then
            vws.AKM_PP_DEVICE_IN_2.value=dev
            local in_device_name_2=AKM_INPUTS[dev]
            --print("AKM dev_in:",dev,in_device_name_2)
            AKM_ACTIVATE=true
            akm_input_midi_2(string.sub(in_device_name_2,2))
            status=false
            break
          end
        end
        for dev=1,#AKM_INPUTS do
          if (AKM_INPUTS[dev]==" KeyLab mkII 49") then
            vws.AKM_PP_DEVICE_IN_1.value=dev
            local in_device_name_1=AKM_INPUTS[dev]
            --print("AKM dev_in:",dev,in_device_name_2)
            --AKM_ACTIVATE=true
            akm_input_midi_1(string.sub(in_device_name_1,2))
            --status=false
            break
          end
        end
      end
      if (vws.AKM_PP_DEVICE_NAME.value==2) then
        for dev=1,#AKM_INPUTS do
          if (AKM_INPUTS[dev]==" MIDIIN2 (KeyLab mkII 61)") then
            vws.AKM_PP_DEVICE_IN_2.value=dev
            local in_device_name_2=AKM_INPUTS[dev]
            --print("AKM dev_in:",dev,in_device_name_2)
            AKM_ACTIVATE=true
            akm_input_midi_2(string.sub(in_device_name_2,2))
            status=false
            break
          end
        end
      end
      if (vws.AKM_PP_DEVICE_NAME.value==3) then
        for dev=1,#AKM_INPUTS do
          if (AKM_INPUTS[dev]==" MIDIIN2 (KeyLab mkII 88)") then
            vws.AKM_PP_DEVICE_IN_2.value=dev
            local in_device_name_2=AKM_INPUTS[dev]
            --print("AKM dev_in:",dev,in_device_name_2)
            AKM_ACTIVATE=true
            akm_input_midi_2(string.sub(in_device_name_2,2))
            status=false
            break
          end
        end
      end
      if (status) then
        show_mess()
      end
    end
  end
  --- ---
  --AKM_OUTPUTS=renoise.Midi.available_output_devices()
  for i=1,#renoise.Midi.available_output_devices() do
    AKM_OUTPUTS[i]=(" %s"):format(renoise.Midi.available_output_devices()[i])
  end
  if not table.is_empty(AKM_OUTPUTS) then
    vws.AKM_PP_DEVICE_OUT.items=AKM_OUTPUTS
  end
  if (AKM_LOCK_IO_DEVICES) then
    --selecte default number of out device
    local out_device_name=AKM_OUTPUTS[vws.AKM_PP_DEVICE_OUT.value]
    --print("AKM dev_out:",vws.AKM_PP_DEVICE_OUT.value,out_device_name)
    akm_output_midi(string.sub(out_device_name,2))
  else
    --autoselect number of out device
    if table.is_empty(AKM_OUTPUTS) then
      return show_mess()
    else
      if (vws.AKM_PP_DEVICE_NAME.value==1) then
        for dev=1,#AKM_OUTPUTS do
          if (AKM_OUTPUTS[dev]==" MIDIOUT2 (KeyLab mkII 49)") then
            vws.AKM_PP_DEVICE_OUT.value=dev
            local out_device_name=AKM_OUTPUTS[dev]
            --print("AKM dev_out:",dev,out_device_name)
            AKM_ACTIVATE=true
            akm_output_midi(string.sub(out_device_name,2))
            break
          end
        end
      end
      if (vws.AKM_PP_DEVICE_NAME.value==2) then
        for dev=1,#AKM_OUTPUTS do
          if (AKM_OUTPUTS[dev]==" MIDIOUT2 (KeyLab mkII 61)") then
            vws.AKM_PP_DEVICE_OUT.value=dev
            local out_device_name=AKM_OUTPUTS[dev]
            --print("AKM dev_out:",dev,out_device_name)
            AKM_ACTIVATE=true
            akm_output_midi(string.sub(out_device_name,2))
            break
          end
        end
      end
      if (vws.AKM_PP_DEVICE_NAME.value==2) then
        for dev=1,#AKM_OUTPUTS do
          if (AKM_OUTPUTS[dev]==" MIDIOUT2 (KeyLab mkII 88)") then
            vws.AKM_PP_DEVICE_OUT.value=dev
            local out_device_name=AKM_OUTPUTS[dev]
            --print("AKM dev_out:",dev,out_device_name)
            AKM_ACTIVATE=true
            akm_output_midi(string.sub(out_device_name,2))
            break
          end
        end
      end
    end
  end
end


local function akm_check_midi_off()
  --midi in
  if (AKM_MIDI_DEVICE_IN_2 and AKM_MIDI_DEVICE_IN_2.is_open) then
    AKM_MIDI_DEVICE_IN_2:close()
    AKM_MIDI_DEVICE_IN_2=nil
    --print("AKM: dev_in: off")
  else
    --print("AKM: dev_in: this in device not exist!")
  end 
  --midi out 
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    AKM_MIDI_DEVICE_OUT:close()
    AKM_MIDI_DEVICE_OUT=nil
    --print("AKM dev_out: off")
  else
    --print("AKM dev_out: this out device not exist!")
  end
end



-------------------------------------------------------------------------------------------------
--api notifiers
-------------------------------------------------------------------------------------------------
local function akm_ntf_play()
  local play_on={{0x90,0x5E,0x7F}, "play_on"}
  local play_off={{0x90,0x5E,0x00}, "play_off"}
  if (song.transport.playing) then
    akm_output_midi_invoke(play_on)
    vws.AKM_BTT_DAW_B_4.color=AKM_CLR.MARKER
  else
    akm_output_midi_invoke(play_off)
    AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6D,0x07,0xF7}   
    vws.AKM_BTT_DAW_B_4.color=AKM_CLR.DEFAULT
  end
end

local function akm_ntf_rec()
  local rec_on={{0x90,0x5F,0x7F}, "rec_on"}
  local rec_off={{0x90,0x5F,0x00}, "rec_off"}
  if (song.transport.edit_mode) then
    akm_output_midi_invoke(rec_on)
    vws.AKM_BTT_DAW_B_5.color=AKM_CLR.RED--MARKER
  else
    akm_output_midi_invoke(rec_off)
    AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6E,0x07,0xF7}
    vws.AKM_BTT_DAW_B_5.color=AKM_CLR.DEFAULT
  end
end

local function akm_ntf_loop()
  local loop_on={{0x90,0x56,0x7F}, "loop_on"}
  local loop_off={{0x90,0x56,0x00}, "loop_off"}
  if (song.transport.loop_pattern) then
    akm_output_midi_invoke(loop_on)
    vws.AKM_BTT_DAW_B_6.color=AKM_CLR.MARKER
  else
    akm_output_midi_invoke(loop_off)
    AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10,0x6F,0x07,0xF7}
    vws.AKM_BTT_DAW_B_6.color=AKM_CLR.DEFAULT
  end
end

local function akm_ntf_metro()
  local metro_on={{0x90,0x59,0x7F}, "metro_on"}
  local metro_off={{0x90,0x59,0x00}, "metro_off"}
  if (song.transport.metronome_enabled) then
    akm_output_midi_invoke(metro_on)
    vws.AKM_BTT_DAW_A_9.color=AKM_CLR.MARKER
  else
    akm_output_midi_invoke(metro_off)
    vws.AKM_BTT_DAW_A_9.color=AKM_CLR.DEFAULT
  end
end

local function akm_ntf_undo()
  local undo_on={{0x90,0x51,0x7F}, "metro_on"}
  local undo_off={{0x90,0x51,0x00}, "metro_off"}
  if (song.transport.follow_player) then
    akm_output_midi_invoke(undo_on)
    vws.AKM_BTT_DAW_A_10.color=AKM_CLR.MARKER
  else
    akm_output_midi_invoke(undo_off)
    vws.AKM_BTT_DAW_A_10.color=AKM_CLR.DEFAULT
  end
end

local function akm_ntf_middle_frame()
  if not (rna.window.instrument_editor_is_detached) then
    for sel=1,9 do
      if (rna.window.active_middle_frame==sel) then
        vws.AKM_ROT_DIAL.value=sel-1
        break
      end
    end
  else
    if (rna.window.active_middle_frame<=2) then
      vws.AKM_ROT_DIAL.value=rna.window.active_middle_frame-1
    else
      --for 3 to 9 NOT WORK!! API bug
      --vws.AKM_ROT_DIAL.value=AKM_WINDOW_FRAME
    end
  end
end

local AKM_SRV=false
local function akm_ntf_sample_record_visible()
  if (AKM_SRV~=rna.window.sample_record_dialog_is_visible) then
    AKM_SRV=rna.window.sample_record_dialog_is_visible
  else
    return
  end
  if (AKM_SRV) then
    vws.AKM_BTT_DAW_A_4.text="Start"
    vws.AKM_BTT_DAW_A_5.text="Cancel"
  else
    vws.AKM_BTT_DAW_A_4.text="u View"
    vws.AKM_BTT_DAW_A_5.text="l View"
  end
end


local function akm_check_notifiers_on()
  --1 check song play
  if not song.transport.playing_observable:has_notifier(akm_ntf_play) then
    song.transport.playing_observable:add_notifier(akm_ntf_play)
  end
  akm_ntf_play()
  --2 check rec
  if not song.transport.edit_mode_observable:has_notifier(akm_ntf_rec) then
    song.transport.edit_mode_observable:add_notifier(akm_ntf_rec)
  end
  akm_ntf_rec()
  --3 check loop
  if not song.transport.loop_pattern_observable:has_notifier(akm_ntf_loop) then
    song.transport.loop_pattern_observable:add_notifier(akm_ntf_loop)
  end
  akm_ntf_loop()
  
  --4 check metro
  if not song.transport.metronome_enabled_observable:has_notifier(akm_ntf_metro) then
    song.transport.metronome_enabled_observable:add_notifier(akm_ntf_metro)
  end
  akm_ntf_metro()
  --5 check undo (follow the player's position)
  if not song.transport.follow_player_observable:has_notifier(akm_ntf_undo) then
    song.transport.follow_player_observable:add_notifier(akm_ntf_undo)
  end
  akm_ntf_undo()
  
  --6 check middle frame selection
  if not rna.window.active_middle_frame_observable:has_notifier(akm_ntf_middle_frame) then
    rna.window.active_middle_frame_observable:add_notifier(akm_ntf_middle_frame)
  end
  akm_ntf_middle_frame()
  
  --7 check sample recording window
  if not rnt:has_timer(akm_ntf_sample_record_visible) then
    rnt:add_timer(akm_ntf_sample_record_visible,100)
  end
end

local function akm_check_notifiers_off()
  --1 check song play
  if song.transport.playing_observable:has_notifier(akm_ntf_play) then
    song.transport.playing_observable:remove_notifier(akm_ntf_play)
  end
  --2 check rec
  if song.transport.edit_mode_observable:has_notifier(akm_ntf_rec) then
    song.transport.edit_mode_observable:remove_notifier(akm_ntf_rec)
  end
  --3 check loop
  if song.transport.loop_pattern_observable:has_notifier(akm_ntf_loop) then
    song.transport.loop_pattern_observable:remove_notifier(akm_ntf_loop)
  end
  
  --4 check metro
  if song.transport.metronome_enabled_observable:has_notifier(akm_ntf_metro) then
    song.transport.metronome_enabled_observable:remove_notifier(akm_ntf_metro)
  end  
  --5 check undo --> (follow the player's position)
  if song.transport.follow_player_observable:has_notifier(akm_ntf_undo) then
    song.transport.follow_player_observable:remove_notifier(akm_ntf_undo)
  end
  --6 check middle frame selection
  if rna.window.active_middle_frame_observable:has_notifier(akm_ntf_middle_frame) then
    rna.window.active_middle_frame_observable:remove_notifier(akm_ntf_middle_frame)
  end
  --7 check sample recording window
  if rnt:has_timer(akm_ntf_sample_record_visible) then
    rnt:remove_timer(akm_ntf_sample_record_visible)
  end 
end



local function akm_force_daw_mode()
  --NOT WORK!!
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then 
    AKM_MIDI_DEVICE_OUT:send {0xB0,0x76,0x7F}
    AKM_MIDI_DEVICE_OUT:send {0xF0,0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x00,0x15,0x7F,0xF7}
  end
end



--transport clr control
function akm_led_clr_trans(ran,sel,clr)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    for s=ran[1],ran[2] do
      if (s~=sel) then
        if (s==0x6D and not song.transport.playing) then
          AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10, s, clr, 0xF7}
        end
        if (s==0x6E and not song.transport.edit_mode) then
          AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10, s, clr, 0xF7}
        end
        if (s==0x6F and not song.transport.loop_pattern) then
          AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10, s, clr, 0xF7}
        end
        if s<=0x6C then
          AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10, s, clr, 0xF7}
        end
      end
    end
  end
end



function akm_led_clr(ran,sel,clr)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    for s=ran[1],ran[2] do
      if (s~=sel) then
        AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x10, s, clr, 0xF7}
      end
    end
  end
end



function akm_led_rgb_sel(ran,rgb)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    for s=ran[1],ran[2] do
      if s~=AKM_BTT_SEL_RBG[2][AKM_BTT_SEL_RBG[1]] then
        AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x16, s, rgb[1],rgb[2],rgb[3], 0xF7}
      else
        AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x16, s, 0x7F,0x7F,0x7F, 0xF7}
      end
    end
  end
end



function akm_led_rgb_pad(sel,ran,rgb)
  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    --for s=0x22,0x29 do
    for s=ran[1],ran[2] do
      if (s~=sel) then
        AKM_MIDI_DEVICE_OUT:send {0xF0, 0x00,0x20,0x6B,0x7F,0x42,0x02,0x00,0x16, s, rgb[1],rgb[2],rgb[3], 0xF7}
      end
    end
  end
end



local function akm_pads_load_clr_rgb()
  for p=1,16 do
    vws["AKM_BT_PADS_"..p].color={
      AKM_PREF["akm_pad_rgb_"..p][1].value*2,
      AKM_PREF["akm_pad_rgb_"..p][2].value*2,
      AKM_PREF["akm_pad_rgb_"..p][3].value*2,
    }
  end
  for rgb=1,3 do
    vws["AKM_VB_PADS_"..rgb].value=AKM_PREF["akm_pad_rgb_"..vws.AKM_VF_PADS_RGB.value][rgb].value 
  end
end



--pad sel rgb control
local function akm_first_select_on()
  --transport buttons
  local ran,sel,clr={0x6A,0x6F},0x70, 0x07
  akm_led_clr_trans(ran,sel,clr)


  --left/right buttons
  local ran,sel,clr={0x1A,0x1B},0x70, 0x07
  akm_led_clr(ran,sel,clr)

  if (AKM_MIDI_DEVICE_OUT and AKM_MIDI_DEVICE_OUT.is_open) then
    AKM_MIDI_DEVICE_OUT:send {0x90,0x18,0x7F}
    vws.AKM_BTN_1.color=AKM_CLR.MARKER 
  end
  --select buttons 1-8, master
  local ran,rgb={0x23,0x29},{0x02,0x02,0x02}
  akm_led_rgb_sel(ran,rgb)
  
  --local sel,ran,rgb=0x80,{0x70,0x7F},{0x7F,0x00,0x00} --red
  --akm_led_rgb_pad(sel,ran,rgb)
  
  akm_pads_load_clr_rgb()
end



local function akm_restore_controls()
  vws.AKM_TXT_DIGITAL_1.text="Daw\nStandard   MCU"
  vws.AKM_TXT_DIGITAL_2.text="Arturia KeyLab\nmkII"
  
  vws.AKM_BTT_LEFT.color=AKM_CLR.DEFAULT
  vws.AKM_BTT_RIGHT.color=AKM_CLR.DEFAULT
  vws.AKM_ROT_DIAL.visible=true
  vws.AKM_BTT_LIVE_1.color=AKM_CLR.DEFAULT
  vws.AKM_BTT_LIVE_2.color=AKM_CLR.DEFAULT
  vws.AKM_BTT_BANK_1.color=AKM_CLR.DEFAULT
  vws.AKM_BTT_BANK_2.color=AKM_CLR.DEFAULT
  
  for num=1,10 do
    vws[("AKM_BTT_DAW_A_%s"):format(num)].color=AKM_CLR.DEFAULT
  end
  for num=1,6 do
    vws[("AKM_BTT_DAW_B_%s"):format(num)].color=AKM_CLR.DEFAULT
  end

  for num=1,9 do
    vws[("AKM_BTN_%s"):format(num)].color=AKM_CLR.DEFAULT
  end  
  
end


-------------------------------------------------------------------------------------------------
--viewbuilder
-------------------------------------------------------------------------------------------------
AKM_ON_OFF=false
function akm_on_off()
  if (AKM_ON_OFF) then
    --akm_test_off()
    akm_check_notifiers_off()
    akm_check_midi_off()
    akm_restore_controls()
    vws.AKM_BT_ON_OFF.text="OFF"
    vws.AKM_BT_ON_OFF.color=AKM_CLR.DEFAULT
    AKM_ON_OFF=false
    AKM_ACTIVATE=false
    --abort repetitions
    akm_rewind_repeat(true)
    akm_forward_repeat(true)
    akm_left_button_repeat(true)
    akm_right_button_repeat(true)
    AKM_STOP_STATUS=false
  else
    akm_check_midi_on()
    if (AKM_ACTIVATE) then
      akm_check_notifiers_on()
      akm_first_select_on()
      --akm_force_daw_mode()
      vws.AKM_BT_ON_OFF.text="ON"
      vws.AKM_BT_ON_OFF.color=AKM_CLR.MARKER
      AKM_ON_OFF=true
    end
  end
end


local function akm_lock_io_devices()
  if (AKM_LOCK_IO_DEVICES) then
    AKM_LOCK_IO_DEVICES=false
    vws.AKM_BT_LOCK_IO_DEVICES.bitmap="ico/padlock_close_ico.png"
    vws.AKM_BT_LOCK_IO_DEVICES.color=AKM_CLR.MARKER
    vws.AKM_PP_DEVICE_IN_1.active=false
    vws.AKM_PP_DEVICE_IN_2.active=false
    vws.AKM_PP_DEVICE_OUT.active=false
  else
    AKM_LOCK_IO_DEVICES=true
    vws.AKM_BT_LOCK_IO_DEVICES.color=AKM_CLR.DEFAULT
    vws.AKM_BT_LOCK_IO_DEVICES.bitmap="ico/padlock_open_ico.png"
    vws.AKM_PP_DEVICE_IN_1.active=true
    vws.AKM_PP_DEVICE_IN_2.active=true
    vws.AKM_PP_DEVICE_OUT.active=true
  end
end



local AKM_SHOW_HIDE_PADS=true
local function akm_show_hide_pads()
  if (AKM_SHOW_HIDE_PADS) then
    vws.AKM_PNL_PADS.visible=false
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.DEFAULT
    AKM_SHOW_HIDE_PADS=false  
  else
    vws.AKM_PNL_PADS.visible=true
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.MARKER
    AKM_SHOW_HIDE_PADS=true
  end
end



local AKM_SHOW_HIDE_FADERS=true
local function akm_show_hide_faders()
  if (AKM_SHOW_HIDE_FADERS) then
    vws.AKM_PNL_FADERS.visible=false
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.DEFAULT
    AKM_SHOW_HIDE_FADERS=false  
  else
    vws.AKM_PNL_FADERS.visible=true
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.MARKER
    AKM_SHOW_HIDE_FADERS=true
  end
end



local AKM_SHOW_HIDE_ALL=true
local function akm_show_hide_all()
  if (AKM_SHOW_HIDE_ALL) then
    vws.AKM_PNL_PADS.visible=false
    AKM_SHOW_HIDE_PADS=false
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.DEFAULT
    vws.AKM_PNL_DIAL.visible=false
    vws.AKM_PNL_FADERS.visible=false
    AKM_SHOW_HIDE_FADERS=false
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.DEFAULT
    vws.AKM_PNL_PAD_FAD.visible=false
    vws.AKM_BT_SHOW_HIDE_ALL.bitmap="ico/compact_off_ico.png"
    vws.AKM_BT_SHOW_HIDE_ALL.color=AKM_CLR.MARKER
    AKM_SHOW_HIDE_ALL=false
    vws.AKM_BT_PREFERENCES.visible=false
  else
    vws.AKM_PNL_PADS.visible=true
    AKM_SHOW_HIDE_PADS=true
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.MARKER
    vws.AKM_PNL_DIAL.visible=true
    vws.AKM_PNL_FADERS.visible=true
    AKM_SHOW_HIDE_FADERS=true
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.MARKER
    vws.AKM_PNL_PAD_FAD.visible=true
    vws.AKM_BT_SHOW_HIDE_ALL.bitmap="ico/compact_on_ico.png"
    vws.AKM_BT_SHOW_HIDE_ALL.color=AKM_CLR.DEFAULT
    AKM_SHOW_HIDE_ALL=true
    vws.AKM_BT_PREFERENCES.visible=true
  end
end



local function akm_preferences()
  if (vws.AKM_PNL_LOWER.visible) then
    vws.AKM_BT_PREFERENCES.color=AKM_CLR.DEFAULT
    vws.AKM_PNL_LOWER.visible=false
    vws.AKM_PNL_PADS.visible=true
    AKM_SHOW_HIDE_PADS=true
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.MARKER
    vws.AKM_PNL_DIAL.visible=true
    vws.AKM_PNL_FADERS.visible=true
    AKM_SHOW_HIDE_FADERS=true
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.MARKER
    vws.AKM_PNL_PAD_FAD.visible=true
    vws.AKM_BT_SHOW_HIDE_ALL.visible=true
  else    
    vws.AKM_BT_PREFERENCES.color=AKM_CLR.MARKER
    vws.AKM_PNL_PADS.visible=false
    AKM_SHOW_HIDE_PADS=false
    vws.AKM_BT_SHOW_HIDE_PADS.color=AKM_CLR.DEFAULT
    vws.AKM_PNL_DIAL.visible=false
    vws.AKM_PNL_FADERS.visible=false
    AKM_SHOW_HIDE_FADERS=false
    vws.AKM_BT_SHOW_HIDE_FADERS.color=AKM_CLR.DEFAULT
    vws.AKM_PNL_PAD_FAD.visible=false
    vws.AKM_PNL_LOWER.visible=true
    vws.AKM_BT_SHOW_HIDE_ALL.visible=false
  end
end



local function akm_mp_daw()
  class "Akm_Button_A"
  function Akm_Button_A:__init(num)
    local tbl_txt_a={"Solo","Mute","Record","u View","l View","Save","Undo","Redo","Metro","Follow"}
    local tbl_tlt_a={
      "Select 1: Solo On/Off current track.\n"..
      "Select 2: Clear current row.\n"..
      "Select 3: n/a.\n"..
      "Select 4: n/a.\n"..
      "Select 5: n/a.\n"..
      "Select 6: n/a.\n"..
      "Select 7: n/a.\n"..
      "Select 8: n/a.",
      
      "Select 1: Mute/On/Off current track.\n"..
      "Select 2: Clear current note/effect column.\n"..
      "Select 3: n/a.\n"..
      "Select 4: n/a.\n"..
      "Select 5: n/a.\n"..
      "Select 6: n/a.\n"..
      "Select 7: n/a.\n"..
      "Select 8: n/a.",
      
      "Select 1: Show/hide \"Sample Recorder\" window. Press & hold to insert new sample.\n"..
      "Select 2: Clear current pattern-track.\n"..
      "Select 3: n/a.\n"..
      "Select 4: n/a.\n"..
      "Select 5: n/a.\n"..
      "Select 6: n/a.\n"..
      "Select 7: n/a.\n"..
      "Select 1: n/a.",
      
      "u View: Show/hide (& permute) upper panel (Scope/Spectrum views).\nStart: Start/stop recording take.",
      "l View: Show/hide (& permute) lower panel (DSP/Automation Editor views).\nCancel: Cancel recording take.",
      --- ---
      "Save: Show \"Save current Song as\" window.",
      "Undo: Back operation.",
      "Redo: Recover operation.",
      "Metro: Enable/disable Metronome.",
      "Follow: Enable/disable follow the player's position."
    }
    local BTT_DAW=vb:button{
      id=("AKM_BTT_DAW_A_%s"):format(num),
      active=false,
      height=19,
      width=55,
      text=tbl_txt_a[num],
      tooltip=tbl_tlt_a[num]
    }
    self.cnt=BTT_DAW
  end

  class "Akm_Button_B"
  function Akm_Button_B:__init(num)
    local tbl_tlt_b={
    "Previous track.\nPress & hold to repeat this operation.",
    "Next track.\nPress & hold to repeat this operation.",
    "Stop Song.\nPress & hold with \"Restore Song\" to playing song from the current line.",
    "Restore Song.\nAfter, press & hold with \"Stop Song\" to playing song from the current line.",
    "On/off Edit Mode for Pattern Editor.",
    "On/off Loop Mode to repeat the current pattern."
    }
    local BTT_DAW=vb:button{
      id=("AKM_BTT_DAW_B_%s"):format(num),
      active=false,
      height=23,
      width=52,
      bitmap=("ico/transport_%s_ico.png"):format(num),
      tooltip=tbl_tlt_b[num]
    }
    self.cnt=BTT_DAW
  end
  local FILE_1=vb:row{spacing=18}
  local FILE_2=vb:row{spacing=18}
  local FILE_3=vb:row{spacing=7}
  for num=1,5 do
    FILE_1:add_child(
      Akm_Button_A(num).cnt
    )
  end

  for num=6,10 do
    FILE_2:add_child(
      Akm_Button_A(num).cnt
    )
  end

  for num=1,6 do
    FILE_3:add_child(
      Akm_Button_B(num).cnt
    )
  end
  local daw_panel=vb:column{
    id="AKM_PNL_DAW",
    spacing=1,
    vb:column{
      spacing=-3,
      vb:horizontal_aligner{
        mode="center",
        vb:text{
          height=21,
          --font="bold",
          style="strong",
          text="TRACK/VIEW CONTROLS"
        }
      },
      FILE_1
    },
    vb:column{
      spacing=-3,
      vb:horizontal_aligner{
        mode="center",
        vb:text{
          height=21,
          --font="bold",
          style="strong",
          text="GLOBAL CONTROLS"
        }
      },
      FILE_2
    },
    --vb:space{height=9},
    vb:column{
      spacing=-3,
      vb:horizontal_aligner{
        mode="center",
        vb:text{
          height=21,
          font="bold",
          style="strong",
          text="TRANSPORT"
        }
      },
      FILE_3
    }
  }
  return daw_panel
end



local function akm_pads_change_rgb(val)
  for rgb=1,3 do
    vws["AKM_VB_PADS_"..rgb].value=AKM_PREF["akm_pad_rgb_"..val][rgb].value
  end
end



local function akm_pads_clr_rgb(val,p)
  AKM_PREF["akm_pad_rgb_"..vws.AKM_VF_PADS_RGB.value][p].value=val--vws["AKM_VB_PADS_"..p].value
  
  vws["AKM_BT_PADS_"..vws.AKM_VF_PADS_RGB.value].color={
    AKM_PREF["akm_pad_rgb_"..vws.AKM_VF_PADS_RGB.value][1].value*2,
    AKM_PREF["akm_pad_rgb_"..vws.AKM_VF_PADS_RGB.value][2].value*2,
    AKM_PREF["akm_pad_rgb_"..vws.AKM_VF_PADS_RGB.value][3].value*2
  }
end



local function akm_pads_clr_rgb_all()
  for pad=1,16 do
    for p=1,3 do
      AKM_PREF["akm_pad_rgb_"..pad][p].value=vws["AKM_VB_PADS_"..p].value
    end
    vws["AKM_BT_PADS_"..pad].color={
      AKM_PREF["akm_pad_rgb_"..pad][1].value*2,
      AKM_PREF["akm_pad_rgb_"..pad][2].value*2,
      AKM_PREF["akm_pad_rgb_"..pad][3].value*2
    }
  end
end



local function akm_mp_pads()
  local pads_panel=vb:column{
    margin=5,
    style="group",
    id="AKM_PNL_PADS",
    vb:row{
      id="AKM_RW_PADS_1",
    },
    vb:row{
      id="AKM_RW_PADS_2",
    },
    vb:row{
      id="AKM_RW_PADS_3",
    },
    vb:row{
      id="AKM_RW_PADS_4",
    }
  }
 
  for p=1,4 do
    vws.AKM_RW_PADS_1:add_child(
      vb:button{
        id="AKM_BT_PADS_"..p,
        height=52,
        width=52,
        --color={0x7F*2,0x7F*2,0x00*2},
        text=("%s"):format(p),
        notifier=function() vws.AKM_VF_PADS_RGB.value=p end
      }
    )
  end

  for p=5,8 do
    vws.AKM_RW_PADS_2:add_child(
      vb:button{
        id="AKM_BT_PADS_"..p,
        height=52,
        width=52,
        text=("%s"):format(p),
        notifier=function() vws.AKM_VF_PADS_RGB.value=p end
      }
    )
  end
  
  for p=9,12 do
    vws.AKM_RW_PADS_3:add_child(
      vb:button{
        id="AKM_BT_PADS_"..p,
        height=52,
        width=52,
        text=("%s"):format(p),
        notifier=function() vws.AKM_VF_PADS_RGB.value=p end
      }
    )
  end
  
  for p=13,16 do
    vws.AKM_RW_PADS_4:add_child(
      vb:button{
        id="AKM_BT_PADS_"..p,
        height=52,
        width=52,
        text=("%s"):format(p),
        notifier=function() vws.AKM_VF_PADS_RGB.value=p end
      }
    )
  end
  vws.AKM_PNL_PADS:add_child(
    vb:space{height=3}
  )
  vws.AKM_PNL_PADS:add_child(
    vb:row{
      id="AKM_RW_PADS_RGB",
      spacing=-2,
      vb:valuefield{
        id="AKM_VF_PADS_RGB",
        height=21,
        width=31,
        min=1,
        max=16,
        value=1,
        align="center",
        tostring=function(value) return ("%.d"):format(value) end,
        tonumber=function(value) return tonumber(value) end,
        notifier=function(value) akm_pads_change_rgb(value) end,
      },
      vb:space{width=4},
      vb:valuebox{
        id="AKM_VB_PADS_1",
        height=21,
        width=49,
        min=0,
        max=127,
        value=0,
        tostring=function(value) return ("%.2X"):format(value) end,
        tonumber=function(value) return tonumber(value,16) end,
        notifier=function(value) akm_pads_clr_rgb(value,1) end,
      },
      vb:valuebox{
        id="AKM_VB_PADS_2",
        height=21,
        width=49,
        min=0,
        max=127,
        value=0,
        tostring=function(value) return ("%.2X"):format(value) end,
        tonumber=function(value) return tonumber(value,16) end,
        notifier=function(value) akm_pads_clr_rgb(value,2) end,
      },
      vb:valuebox{
        id="AKM_VB_PADS_3",
        height=21,
        width=49,
        min=0,
        max=127,
        value=0,
        tostring=function(value) return ("%.2X"):format(value) end,
        tonumber=function(value) return tonumber(value,16) end,
        notifier=function(value) akm_pads_clr_rgb(value,3) end,
      },
      vb:button{
        height=21,
        width=36,
        text="All",
        notifier=function() akm_pads_clr_rgb_all() end
      }
    }
  )
  
  return pads_panel
end


local function akm_mp_top()
  local top_panel=vb:row{
    --id="AKM_ROW_TOP_2",
    spacing=-2,
    vb:button{
      id="AKM_BT_ON_OFF",
      height=21,
      width=37,
      text="OFF",
      notifier=function() akm_on_off() end,
      tooltip=("On/off the %s.\nMake a bridge between the selected device & Renoise."):format(akm_main_title)
    },
    vb:text{
      height=21,
      width=54,
      align="right",
      text="Name "
    },
    vb:popup{
      id="AKM_PP_DEVICE_NAME",
      height=21,
      width=165,
      value=1,
      items=AKM_DEVICE_NAME,
      notifier=function() if (AKM_ON_OFF) then return akm_check_midi_off(), akm_check_midi_on() end end,
      tooltip="List of the names of supported devices."
    },
    vb:space{width=8},
    vb:row{
      id="AKM_PNL_PAD_FAD",
      spacing=-2,
      vb:button{
        id="AKM_BT_SHOW_HIDE_PADS",
        height=21,
        width=25,
        bitmap="ico/pads_ico.png",
        color=AKM_CLR.MARKER,
        notifier=function() akm_show_hide_pads() end,
        tooltip="Show/hide the Pads panel."
      },
      vb:button{
        id="AKM_BT_SHOW_HIDE_FADERS",
        height=21,
        width=25,
        bitmap="ico/faders_ico.png",
        color=AKM_CLR.MARKER,
        notifier=function() akm_show_hide_faders() end,
        tooltip="Show/hide the Faders panel."
      },
      vb:space{width=8}
    },
    vb:button{
      id="AKM_BT_SHOW_HIDE_ALL",
      height=21,
      width=25,
      bitmap="ico/compact_on_ico.png",
      notifier=function() akm_show_hide_all() end,
      tooltip="Show/hide all panels."
    },
    vb:button{
      id="AKM_BT_PREFERENCES",
      height=21,
      width=25,
      bitmap="ico/preferences_ico.png",
      notifier=function() akm_preferences() end,
      tooltip="Show/hide Preferences & About panels."
    }
  }
  return top_panel
end


local function akm_mp_dial()
  local dial_panel=vb:column{
    style="group",
    id="AKM_PNL_DIAL",
    vb:column{
      spacing=-217,
      vb:vertical_aligner{
        vb:bitmap{
          active=false,
          mode="body_color",
          height=217,
          width=264,
          bitmap="ico/arturia_background_ico.png"
        }
      },
      vb:column{
        margin=4,
        spacing=-2,
        vb:horizontal_aligner{
          margin=2,
          mode="center",
          vb:row{
            style="plain",
            margin=2,
            spacing=-3,
            vb:column{
              --style="group",
              width=193,
              vb:text{
                id="AKM_TXT_DIGITAL_1",
                width=193,
                height=33,
                font="big",
                text="Daw\nStandard   MCU"
              }
            },
            vb:space{width=8},
            vb:column{
              --style="group",
              width=143,
              vb:text{
                id="AKM_TXT_DIGITAL_2",
                width=143,
                height=33,
                align="right",
                font="big",
                text="Arturia KeyLab\nmkII"
              }
            },
            vb:space{width=5}
          }
        },
        vb:space{height=6},
        vb:column{
          spacing=-55,
          width=347,
          vb:horizontal_aligner{
            mode="center",
            height=55,
            vb:row{
              spacing=9,
              vb:vertical_aligner{
                mode="center",
                vb:button{
                  id="AKM_BTT_LEFT",
                  active=false,
                  height=21,
                  width=55,
                  bitmap="ico/arrow_left_ico.png",
                  tooltip="Previous Pattern Sequence.\nPress & hold to repeat this operation."
                }
              },
              vb:column{
                spacing=-38,
                width=53,
                vb:rotary{
                  id="AKM_ROT_DIAL",
                  active=false,
                  min=0,
                  max=8,
                  value=0,
                  height=51,
                  width=51,
                  tooltip="Main tabs navigation.\nSwitch between the different Renoise panels, turning right or left. "..
                          "Press the central button for two shortcuts (Pattern Editor or Plugin panel).\n"..
                          "Press & hold the central button to unttach/tach the Instrument Editor panel."
                },
                vb:row{
                  vb:space{width=13},
                  vb:bitmap{
                    id="AKM_BMP_DIAL",
                    active=false,
                    mode="body_color",
                    height=23,
                    width=23,
                    bitmap="ico/arturia_logo_ico.png"
                  }
                }
              },
              vb:vertical_aligner{
                mode="center",
                vb:button{
                  id="AKM_BTT_RIGHT",
                  active=false,
                  height=21,
                  width=55,
                  bitmap="ico/arrow_right_ico.png",
                  tooltip="Next Pattern Sequence.\nPress & hold to repeat this operation."
                }
              }
            }
          },
          vb:horizontal_aligner{
            mode="right",
            width=347,
            vb:row{
              id="AKM_PN_UP_DOWN_1",
              vb:text{
                height=47,
                width=37,
                align="right",
                font="bold",
                text="Line"
              },
              vb:column{
                spacing=-3,
                vb:button{
                  id="AKM_BTT_LIVE_1",
                  active=false,
                  height=26,
                  width=29,
                  bitmap="ico/arrow_up_ico.png",
                  tooltip="Previous line.\nPress & hold to repeat this operation."
                },
                vb:button{
                  id="AKM_BTT_LIVE_2",
                  active=false,
                  height=26,
                  width=29,
                  bitmap="ico/arrow_down_ico.png",
                  tooltip="Next line.\nPress & hold to repeat this operation."
                }
              }
            },
            vb:row{
              id="AKM_PN_UP_DOWN_2",
              visible=false,
              vb:text{
                height=42,
                width=37,
                align="right",
                font="bold",
                text="Instr."
              },
              vb:column{
                spacing=-3,
                vb:button{
                  id="AKM_BTT_BANK_1",
                  active=false,
                  height=26,
                  width=29,
                  bitmap="ico/arrow_up_ico.png",
                  tooltip="Previous instrument.\nPress & hold to repeat this operation."
                },
                vb:button{
                  id="AKM_BTT_BANK_2",
                  active=false,
                  height=26,
                  width=29,
                  bitmap="ico/arrow_down_ico.png",
                  tooltip="Next instrument.\nPress & hold to repeat this operation."
                }
              }
            }
          }
        },
        akm_mp_daw()
      }
    }
  }
  return dial_panel
end

local AKM_RTY_TOOLTIP={
  "Note value.\nRange=C-0 to B-9, OFF or EMP.",
  "Instrument value.\nRange=00 to FE, or EMP.",
  "Volume value.\nRange=00 to 7F or EMP.",
  "Panning value.\nRange=00 to 80 or EMP.",
  "Delay value.\nRange=01 to FF or EMP",
  "sFX/FX parameter.\n"..
    --sample
    "   A: Set arpeggio, x/y = first/second note offset in semitones, 00 = repeat.\n"..
    "   U: Slide pitch up by xx 1/16ths of a semitone, 00 = repeat.\n"..
    "   D: Slide pitch down by xx 1/16ths of a semitone, 00 = repeat.\n"..
    "   G: Glide towards given note by xx 1/16ths of a semitone, 00 = repeat.\n"..
    "   V: Set vibrato (regular pitch variation), x = speed, y = depth, 00 = repeat.\n"..
    "   I: Fade volume in by xx volume units, 00 = repeat.\n"..
    "   O: Fade volume out by xx volume units, 00 = repeat.\n"..
    "   T: Set tremolo (regular volume variation), x = speed, y = depth, 00 = repeat.\n"..
    "   C: Cut volume to x after y ticks (x = volume factor: 0=0%, F=100%).\n"..
    "   S: Trigger sample slice number xx or offset xx.\n"..
    "   B: Play sample backwards (xx = 00) or forwards (xx = 01).\n"..
    "   E: Set the position of all active Envelope, AHDSR & Fader Modulation devices...\n"..
    "   N: Set auto pan (regular pan variation), x = speed, y = depth, 00 = repeat\n\n"..
    --instrument
    "   M: Set channel volume level, 00 = -60dB, FF = +3dB.\n"..
    "   Z: Trigger phrase number xx (01 - 7E, 00 = no phrase, 7F = keymap mode).\n"..
    "   Q: Delay playback of the line by xx ticks (00 - TPL).\n"..
    "   Y: MaYbe trigger the line with probability xx. 00 = mutually exclusive mode...\n"..
    "   R: Retrigger instruments that are currently playing.\n\n"..
    --device
    "   L: Set track pre-mixer's volume level, 00 = -INF, C0 = 0dB, FF = +3dB.\n"..
    "   P: Set track pre-mixer's panning, 00 = left, 80 = center, FF = right.\n"..
    "   W: Set track pre-mixer's surround width, 00 = off, 01 - FF.\n"..
    "   X: Stop all notes & FX (X00), or a specific effect (Xxx, where xx > 00).\n"..
    "   J: Set track's output routing to channel xx, 00 = Master, 01 = hardware, FF = parent group.\n\n"..
    --global
    "   ZT: BPM, set tempo (20 - FF, 00 = stop song).\n"..
    "   ZL: LPB, set Lines Per Beat (01 - FF, 00 = stop song).\n"..
    "   ZK: TPL, set Ticks Per Line (01 - 10).\n"..
    "   ZG: Toggle song Groove on/off (00 = turn off, 01 or higher = turn on).\n"..
    "   ZB: Break pattern. The pattern finishes & jumps to next pattern at line xx (hex).\n"..
    "   ZD: Delay (pause) pattern playback by xx lines.\n",--..
    --"Empty."
  "sFX/FX amount.\nRange=00 to FF, according to the effect parameter.",
  "Note/effect column.\nRange=N1 to N12 or E1 to E8.",
  "Step length.\nRange=00 to 64 lines.\nChange the value to jump of \"Step length used in the pattern editor\"."
}



local function akm_btt_val_lock(num)
  for i=1,9 do
    if (i==num) then
      if (AKM_VAL_LOCK[num]) then
        vws[("AKM_BTT_VAL_LOCK_%s"):format(num)].bitmap="ico/padlock_close_ico.png"
        vws[("AKM_BTT_VAL_LOCK_%s"):format(num)].color=AKM_CLR.MARKER
        AKM_VAL_LOCK[num]=false
      else
        vws[("AKM_BTT_VAL_LOCK_%s"):format(num)].bitmap="ico/padlock_open_ico.png"
        vws[("AKM_BTT_VAL_LOCK_%s"):format(num)].color=AKM_CLR.DEFAULT
        AKM_VAL_LOCK[num]=true
      end
      return
    end
  end
end

local function akm_btt_val_lock_state()
  local state={1,2,6,7}
  for i=1,#state do
    akm_btt_val_lock(state[i])
  end
end



local function akm_mp_faders()
  local text_val={"Note","Ins","Vol","Pan","Dly", "sFX-FX","Amo","NC-EC", "Step"}
  local vfd_val_val={
    {121,120,060,048,036}, --note
    {255,255,000,000,000}, --instrument
    {255,127,096,064,032}, --volume
    {255,255,128,064,000}, --panning
    {000,128,096,064,032}, --delay
    
    {002,006,009,013,001}, --sfx/fx
    {004,003,002,001,000}, --amount
    {001,002,003,004,013}, --nc/ec
    
    {000,016,032,048,063}  --step
  }
  local sld_min_val={000,000,000,000,000, 000,000,000, 000 }
  local sld_max_val={121,255,255,255,255, 030,255,127, 127 }
  local sld_val_val={121,255,255,255,255, 000,000,000, 127 }

  class "Akm_Fader"
  function Akm_Fader:__init(num)
    local function fdr_tostring(val,num)
      if (num==1) then
        return akm_note_tostring(val)
      elseif (num==2) then
        return akm_instrument_tostring(val)
      elseif (num==3) then
        return akm_volume_tostring(val)
      elseif (num==4) then
        return akm_panning_tostring(val)
      elseif (num==5) then
        return akm_delay_tostring(val)
      elseif (num==6) then
        return akm_sfx_fx_tostring(val)
      elseif (num==7) then
        return akm_amount_tostring(val)
      elseif (num==8) then
        return akm_nc_ec_tostring(val)
      elseif (num==9) then
        return akm_step_tostring(val)
      end
    end
    local function fdr_tonumber(val,num)
      if (num==1) then
        return akm_note_tonumber(val)
      elseif (num==2) then
        return akm_instrument_tonumber(val)
      elseif (num==3) then
        return akm_volume_tonumber(val)
      elseif (num==4) then
        return akm_panning_tonumber(val)
      elseif (num==5) then
        return akm_delay_tonumber(val)
      elseif (num==6) then
        return akm_sfx_fx_tonumber(val)
      elseif (num==7) then
        return akm_amount_tonumber(val)
      elseif (num==8) then
        return akm_nc_ec_tonumber(val)
      elseif (num==9) then
        return akm_step_tonumber(val)
      end
    end
    local FDR_MAIN=vb:column{}
    local FDR_VAL=vb:column{spacing=4}
    FDR_MAIN:add_child(FDR_VAL)
    local lvl={5,4,3,2,1}
    for i=1,5 do
      FDR_VAL:add_child(
        vb:valuefield{
          id=("AKM_VFD_VAL_%s_%s"):format(num,i),
          height=21,
          width=35,
          align="right",
          min=sld_min_val[num],
          max=sld_max_val[num],
          value=vfd_val_val[num][i],
          tostring=function(val) return fdr_tostring(val,num) end,
          tonumber=function(val) return fdr_tonumber(val,num) end,
          notifier=function(val) end,
          tooltip=("Level %s to \"%s\" panel"):format(lvl[i],text_val[num])
        }
      )
    end
    FDR_MAIN:add_child(
      vb:button{
        id=("AKM_BTT_VAL_LOCK_%s"):format(num),
        height=19,
        width=21,
        bitmap="ico/padlock_open_ico.png",
        notifier=function() akm_btt_val_lock(num) end,
        tooltip=("Lock/unlock the rotary & slider controls of panel %s."):format(num)
      }
    )
    local MAIN_FDR=vb:column{
      spacing=-2,
      width=54,
      style="group",
      margin=4,
      vb:text{
        height=21,
        width=54,
        align="center",
        font="bold",
        style="strong",
        text=text_val[num]
      },
      vb:horizontal_aligner{
        mode="center",
        vb:rotary{
          id=("AKM_RTY_%s"):format(num),
          active=false,
          height=43,
          width=43, 
          min=sld_min_val[num],
          max=sld_max_val[num],
          value=sld_val_val[num],
          tooltip=AKM_RTY_TOOLTIP[num]
        }
      },
      vb:row{
        spacing=-2,
        FDR_MAIN,
        vb:slider{
          id=("AKM_SLD_%s"):format(num),
          active=false,
          height=140,
          width=21,
          min=sld_min_val[num],
          max=sld_max_val[num],
          value=sld_val_val[num],
          tooltip=("Fader %s"):format(num)
        }
      }
    }
    self.cnt=MAIN_FDR
  end
  local SEL_X=vb:row{
    style="group",
    margin=4,
    spacing=10,
  }
  for num=1,8 do
    SEL_X:add_child(
      vb:button{
        active=false,
        id=("AKM_BTN_%s"):format(num),
        height=21,
        width=56,
        text=("Sel %s"):format(num),
        tooltip=("Select %s"):format(num)
      }
    )
  end
  SEL_X:add_child(
    vb:button{
      active=false,
      id="AKM_BTN_9",
      height=21,
      width=54,
      text="Mst",
      tooltip="Master\n(Undefined)"
    }
  )
  local FADERS=vb:row{
    spacing=4
  }
  for num=1,#sld_min_val do
    FADERS:add_child(
      Akm_Fader(num).cnt
    )
  end

  local faders_panel=vb:column{
    id="AKM_PNL_FADERS",
    spacing=5,
    FADERS,
    SEL_X
  }
  akm_btt_val_lock_state()
  return faders_panel
end

local function akm_top_panel()
  local top_panel=vb:row{
    id="AKM_PNL_TOP",
    spacing=4,
    akm_mp_pads(),
    vb:column{
      spacing=4,
      akm_mp_top(),
      akm_mp_dial(),
    },
    akm_mp_faders()
  }
  return top_panel
end


local function akm_lower_panel()
  local lower_panel=vb:column{
    id="AKM_PNL_LOWER",
    visible=false,
    spacing=5,
    vb:column{
      style="group",
      margin=5,
      vb:horizontal_aligner{
        mode="center",
        vb:text{
          font="bold",
          style="strong",
          text="Preferences"
        },
      },
      vb:row{
        id="AKM_ROW_TOP_1",
        vb:text{
          height=21,
          width=72,
          align="right",
          text="In Device 1 "
        },
        vb:popup{
          id="AKM_PP_DEVICE_IN_1",
          active=false,
          height=21,
          width=165,
          value=1,
          items=AKM_INPUTS,
          notifier=function() if (AKM_ON_OFF) then return akm_check_midi_off(), akm_check_midi_on() end end,
          tooltip="List of available in devices."
        },
        vb:text{
          height=21,
          width=72,
          align="right",
          text="In Device 2 "
        },
        vb:popup{
          id="AKM_PP_DEVICE_IN_2",
          active=false,
          height=21,
          width=165,
          value=1,
          items=AKM_INPUTS,
          notifier=function() if (AKM_ON_OFF) then return akm_check_midi_off(), akm_check_midi_on() end end,
          tooltip="List of available in devices."
        },
        vb:text{
          height=21,
          width=81,
          align="right",
          text="Out Device "
        },
        vb:popup{
          id="AKM_PP_DEVICE_OUT",
          active=false,
          height=21,
          width=165,
          value=1,
          items=AKM_OUTPUTS,
          notifier=function() if (AKM_ON_OFF) then return akm_check_midi_off(), akm_check_midi_on() end end,
          tooltip="List of available out devices."
        },
        vb:space{width=4},
        vb:button{
          id="AKM_BT_LOCK_IO_DEVICES",
          height=21,
          width=25,
          bitmap="ico/padlock_close_ico.png",
          color=AKM_CLR.MARKER,
          notifier=function() akm_lock_io_devices() end,
          tooltip="Lock/unlock the selection of in/out devices.\nAlways use the \"MIDIIN2 (device)\" & \"MIDIOUT2 (device)\" to the correct control.\n"..
                  "Do not use the the \"MIDIIN2 (device)\" & \"MIDIOUT2 (device)\" in:\nReniose: Edit / Preferences / MIDI: \"In device X...\" & \"Out device...\"."
        }
      }
    },
    vb:column{
      style="group",
      margin=5,
      vb:horizontal_aligner{
        mode="center",
        vb:text{
          font="bold",
          style="strong",
          text="About"
        },
      },
      vb:row{
        vb:text{
          height=150,
          width=429,
          text=AKM_ABOUT_TTP
        },
        vb:bitmap{
          height=150,
          width=320,
          bitmap="ico/keylab_mkii_ico.png"
        }
      }
    }
  }
  return lower_panel
end



local function akm_main_content()
  AKM_MAIN_CONTENT=vb:column{
    style="panel",
    margin=5,
    spacing=4,
    vb:column{
      id="AKM_MAIN_PANELS",
      akm_top_panel(),      
    },
    akm_lower_panel()
  }
  return AKM_MAIN_CONTENT
end



--standby for new song
local function akm_on_off_standby()
  if (AKM_ON_OFF) then
    akm_on_off()
  end
end



-------------------------------------------------------------------------------------------------
--show main_dialog
-------------------------------------------------------------------------------------------------
local function akm_main_dialog()
  --main content gui
  if (AKM_MAIN_CONTENT==nil) then
    akm_capture_clr_mrk()
    akm_main_content()
    require("lua/keyhandler")
  end
  --avoid showing the same window several times!
  if (AKM_MAIN_DIALOG) and (AKM_MAIN_DIALOG.visible) then AKM_MAIN_DIALOG:show() return end
  --custom dialog
  AKM_MAIN_DIALOG=rna:show_custom_dialog(("%s"):format(akm_main_title),AKM_MAIN_CONTENT,akm_keyhandler)
  --reload show_tool_dialog() in new song
  if not rnt.app_new_document_observable:has_notifier(akm_on_off_standby) then
    rnt.app_new_document_observable:add_notifier(akm_on_off_standby)
  end
end
_AUTO_RELOAD_DEBUG=function() akm_main_dialog() end



-------------------------------------------------------------------------------------------------
--register menu entry
-------------------------------------------------------------------------------------------------
rnt:add_menu_entry{
  name=("Main Menu:Tools:%s..."):format(akm_main_title),
  invoke=function() akm_main_dialog() end
}



-------------------------------------------------------------------------------------------------
--register keybinding
-------------------------------------------------------------------------------------------------
rnt:add_keybinding{
  name=("Global:Tools:%s"):format(akm_main_title),
  invoke=function() akm_main_dialog() end
}


----------------------------------------
--collectgarbage<bottom>
 --print("collectgarbage:",collectgarbage("count"),("KBytes(%s)"):format(akm_main_title))
 --collectgarbage("restart")
----------------------------------------
--rprint(_G)
