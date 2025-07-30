--global/local
ASC_MAIN_CONTENT=nil
ASC_MAIN_DIALOG=nil
local ASC_VB_HEIGHT=17
local ASC_VB_HEIGHT_0=19
local ASC_VB_HEIGHT_1=21
local ASC_VB_HEIGHT_2=23
local MATH_FLOOR=math.floor

local ASC_JUMP_LINES=false
local ASC_RANDOM_LINES=false
local ASC_UP_DOWN_BYPASS=true
local ASC_PROFILE_BYPASS=true
local ASC_PROFILE_CAPTURE_INS=true

local ASC_TXT_INFO=("TOOL NAME: %s or ASC.\n"..
                    "VERSION: %s %s.\n"..
                    "LICENSE: Free.\n"..
                    "DISTRIBUTION: Full version (without registry).\n"..
                    "COMPATIBILITY: Renoise 3.3.2 (tested under Windows 10 x64).\n"..
                    "CODE: LUA 5.1 + API 6 (Renoise 3.2.2).\n"..
                    "DEVELOPMENT DATE: April 2020 - November 2020.\n"..
                    "PUBLISHED: December 2021.\n"..
                    "PROGRAMMER / CODE OWNER: ulneiz.\n"..
                    "LOCATE: Spain.\n"..
                    "CONTACT: \"https://forum.renoise.com/\" & search: \"ulneiz\".\n\n"..
                    "DONATIONS: If you love this tool and want to make a donation\n"..
                    "                       through Paypal, contact the author directly. Thanks! :)"..
                    ""):format(asc_main_title,asc_version,asc_build)
                    


--key commands
local ASC_TXT_KEYS={
  KEYS={
    "Transport & Navigation",                            "",
    "[SPACE] Restart/stop song",                         "[ALT SPACE] Continue/stop song",
    "[CTRL Z],[CTRL Y] Undo/redo",                       "[ESC] Enable/disable edit mode",
    "[F1 to F12] Open/close/jump note columns",          "[LEFT],[RIGHT] Left/right note/effect columns",
    "[UP],[DOWN] Up/down line",                          "[HOME],[END] Jumpt first/last line",
    "[CTRL UP],[CTRL DOWN] Up/down sequence",            "[CTRL HOME],[CTRL END] Jumpt first/last sequence",
    "[ALT UP],[ALT DOWN] Jump firt/last line steps",     "[TAB],[SHIFT TAB] Left/right track",
    "[NUMPAD -] Up instrument",                          "[NUMPAD +] Down instrument",
    "[ALT NUMPAD -] Up preset plugin (if exist)",        "[ALT NUMPAD +] Down preset plugin  (if exist)",
    "Edition Controls",                                  "",
    "[RETURN] Steps navigation in loop",                 "[BACK],[SHIFT BACK] Import data",
    "[INSERT], [mod. INSERT] Insert Steps... ",          "[CTRL SHIFT INSERT] On/off Auto Grown Sequence",
    "[DEL] [mod. DEL] Clear steps...",                   "[PRIOR],[NEXT] Transpose up/down notes",
    "[R.CTRL] On/off Steps Marker",                      "",
    "Window Controls",                                   "",
    "*[CTRL SHIFT A] Open window",                       "[CTRL SHIFT A] Close window"   
  },
  ASSIGNABLE="*Assignable: Preferences/Keys:Global/Tools/"..asc_main_title
}

local function asc_txt_keys()
  local main,col_1,col_2=vb:column{spacing=-3},vb:column{spacing=-3},vb:column{spacing=-3}
  local keys=vb:row{}
  keys:add_child(col_1)
  keys:add_child(col_2)
  main:add_child(keys)
  for i=1,32,2 do
    if (i==1) or (i==19) or (i==29) then
      col_1:add_child(
        vb:text{height=ASC_VB_HEIGHT, width=260, text=ASC_TXT_KEYS.KEYS[i], style="strong"}
      )
    else
      col_1:add_child(
        vb:text{height=ASC_VB_HEIGHT, width=260, text=ASC_TXT_KEYS.KEYS[i]}
      )
    end    
  end
  for i=2,32,2 do
    col_2:add_child(
      vb:text{height=ASC_VB_HEIGHT, width=282, text=ASC_TXT_KEYS.KEYS[i]}
    )
  end
  main:add_child(
    vb:text{height=ASC_VB_HEIGHT, width=544, text=ASC_TXT_KEYS.ASSIGNABLE}
  )
  return main
end



--note convert tostring
local function asc_note_tostring(val) --return a string,Range val: 0 to 119
  if (val<120) then
    local note_name={"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
    return ("%s%s"):format(note_name[MATH_FLOOR(val) %12+1],MATH_FLOOR(val/12))
  else
    return "--"
  end
end

--note convert tonumber
local function asc_note_tonumber(val) --return a number
  if (val~="--" and val~="-") then
    local nte_name_1={"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
    local nte_name_2={"c-","c#","d-","d#","e-","f-","f#","g-","g#","a-","a#","b-"}
    local nte_name_3={"C", "C#","D", "D#","E", "F" ,"F#","G", "G#","A", "A#","B" }
    local nte_name_4={"c", "c#","d", "d#","e", "f", "f#","g", "g#","a", "a#","b" }
    for i=1,12 do
      for oct = 0,9 do
        if (val==("%s%s"):format(nte_name_1[i],oct)) or
           (val==("%s%s"):format(nte_name_2[i],oct)) or
           (val==("%s%s"):format(nte_name_3[i],oct)) or
           (val==("%s%s"):format(nte_name_4[i],oct)) then
          return i+(oct*12)-1
        end
      end
    end
  else
    return 121
  end
end



--convert string characters
local function asc_tf_save_profile(text,id)
  --valid characters: () {} [] + - @ # $ % &
  --no valid characters:
  local char="[<>\"\\\/|:*¡!¿?·'`´^¨€çñ]"  --characters inside [ ]
  --convert characters
  local txt=text:gsub("á","a"):gsub("Á","A"):gsub("à","a"):gsub("À","A"):gsub("ä","a"):gsub("Ä","A"):gsub("â","a"):gsub("Â","A")
         txt=txt:gsub("é","e"):gsub("É","E"):gsub("è","e"):gsub("È","E"):gsub("ë","e"):gsub("Ë","E"):gsub("ê","e"):gsub("Ê","E")
         txt=txt:gsub("í","i"):gsub("Í","I"):gsub("ì","i"):gsub("Ì","I"):gsub("ï","i"):gsub("Ï","I"):gsub("î","i"):gsub("Î","I")
         txt=txt:gsub("ó","o"):gsub("Ó","O"):gsub("ò","o"):gsub("Ò","O"):gsub("ö","o"):gsub("Ö","O"):gsub("ô","o"):gsub("Ô","O")
         txt=txt:gsub("ú","u"):gsub("Ú","U"):gsub("ù","u"):gsub("Ù","U"):gsub("ü","u"):gsub("Ü","U"):gsub("û","u"):gsub("Û","U")
  --clear no valid characters
         txt=txt:gsub(char,"")
  vws[id].text=txt
end



local ASC_FX_TOOLTIP="sFX/FX parameter:\n"..
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
  "   ZD: Delay (pause) pattern playback by xx lines."



local ASC_SFX_EFF={" A"," U"," D"," G"," V"," I"," O"," T"," C"," S"," B"," E"," N"," M"," Z"," Q"," Y"," R"," .."," L"," P"," W"," X"," J"," ZT"," ZL"," ZK"," ZG"," ZB"," ZD"}
local ASC_SFX_EF2={"0A","0U","0D","0G","0V","0I","0O","0T","0C","0S","0B","0E","0N","0M","0Z","0Q","0Y","0R","00","0L","0P","0W","0X","0J","ZT","ZL","ZK","ZG","ZB","ZD"} --19


local ASC_STEPS_SEL={
  {true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true},
  {true,false,true,false,true,false,true,false, true,false,true,false,true,false,true,false, true,false,true,false,true,false,true,false, true,false,true,false,true,false,true,false},
  {false,true,false,true,false,true,false,true, false,true,false,true,false,true,false,true, false,true,false,true,false,true,false,true, false,true,false,true,false,true,false,true},
  {false,false,false,false,false,false,false,false, false,false,false,false,false,false,false,false, false,false,false,false,false,false,false,false, false,false,false,false,false,false,false,false},
  {true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true}
}

local ASC_RESTORE_BYPASS=true
local ASC_IMPORT_BYPASS=true
local ASC_SAVE_PROFILE_BYPASS=true
local ASC_VISIBLE_SUB_COLUMN_BYPASS=true
local ASC_RANDOM_BYPASS=true
local ASC_AUTOCAP_INS_BYPASS=true



-------------------------------------------------------------------------------------------------
--status bar
local function asc_status_bar_off()
  vws.ASC_TX_STATUS_BAR.visible=false
  if rnt:has_timer(asc_status_bar_off) then
    rnt:remove_timer(asc_status_bar_off)
  end
end
local function asc_status_bar_on(time,val,string,idx)
  local STATUS_TBL={
    ("The profile \"%s\" not exist. Please, charge one!"):format(string), --1
    "There are no profiles. Please create some!", --2
    ("The folder \"../%s\" not exist. Please, restore it!"):format(string), --3
    ("The profile \"../%s\" has been removed!"):format(string), --4
    ("The profile \"../%s\" has been saved!"):format(string), --5
    "Enable the Edit Mode to insert!", --6
    "Enable the Edit Mode to clear!", --7
    "Enable the Edit Mode to transpose!", --8
    "Select first a note column to import!", --9
    "Select first a note column to insert!", --10
    "Select first a note column to transpose!", --11
    ("The profile \"%s\" has ben charged in the favorite slot profile %s!"):format(string,idx), --12
    "Steps Marker disabled!", --13
    "Steps Marker enabled!", --14
    "Random fill down disabled!", --15
    "Random fill down enabled!", --16
    "Profile instrument capture disabled!", --17
    "Profile instrument capture enabled!", --18
    ("Current reference line from the pattern editor: line %s."):format(string), --19
    "Auto grown sequence enabled!", --20
    "Auto grown sequence disabled!", --21
    ("The folder \"../%s\" has been saved!"):format(string), --22
    ("The folder \"%s\" contains %s file or folders. Please empty this folder before deleting it."):format(string,idx), --23
    ("The folder \"%s\" contains %s files or folders. Please empty this folder before deleting it."):format(string,idx), --24
    ("The folder \"../%s\" has been removed!"):format(string), --25
    ("The folder \"%s\" not contain profiles!"):format(string), --26
    ("The folder \"%s\" has been created to save profiles!"):format(string), --27
    "Data not imported. The current note column does not contain steps!", --28
    ("The current note column data has been imported! (%s steps)"):format(string), --29
  }
  vws.ASC_TX_STATUS_BAR.visible=true
  vws.ASC_TX_STATUS_BAR.text=STATUS_TBL[val]
  if rnt:has_timer(asc_status_bar_off) then
    rnt:remove_timer(asc_status_bar_off)
  end
  if not rnt:has_timer(asc_status_bar_off) then
    rnt:add_timer(asc_status_bar_off,time)
  end
end


local ASC_STEP={
  LNE_A={},
  LNE_B={},
  OFF={},
  NTE={},
  INS={},
  VOL={},
  PAN={},
  DLY={},
  SFX_EFF={},
  SFX_AMO={}
}
for l=0,32 do
  ASC_STEP.LNE_A[l]=ASC_PREF.nol_top_note.value
  ASC_STEP.LNE_B[l]=ASC_PREF.nol_top_note.value
end



-------------------------------------------------------------------------------------------------
--control/transport/navigation functions

--undo
function asc_undo()
  if (song:can_undo()) then
    song:undo()
  end
end

--redo
function asc_redo()
  if (song:can_redo()) then
    song:redo()
  end
end

--edit mode
function asc_edit_mode()
  if (song.transport.edit_mode) then
    song.transport.edit_mode=false
  else
    song.transport.edit_mode=true
  end
end

--play/stop
--[[
local ASC_PLAY_MODE=1
local function asc_play_delay()
  if not song.transport.playing then
    song.transport:start(ASC_PLAY_MODE)
  else
    song.transport:stop()
  end
  if (rnt:has_timer(asc_play_delay)) then
    rnt:remove_timer(asc_play_delay)
  end
end
function asc_play_stop(mode)
  --print("play",song.transport.playing)
  if (not rnt:has_timer(asc_play_delay)) then
    ASC_PLAY_MODE=mode
    rnt:add_timer(asc_play_delay,10)
  end
end
]]

--[[
function asc_play_stop(mode)
  --print("play",song.transport.playing)
  if not song.transport.playing then
    song.transport:start(mode)
  else
    song.transport:stop()
  end
end
]]


function asc_play_stop(mode)
  --print("play",song.transport.playing)
  if (not song.transport.playing) then
    song.transport:start(mode)
    return
  end
  if (song.transport.playing) then
    song.transport:stop()
  end
end


--jump steps first/last lines navigation
local function asc_jump_first_lne()
  if (ASC_STEP.LNE_A[1]<=song.selected_pattern.number_of_lines) then
    song.selected_line_index=ASC_STEP.LNE_A[1]
  end
end
local function asc_jump_last_lne()
  if (ASC_STEP.OFF[vws.ASC_VB_STEPS.value]>ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]) then
    if (ASC_STEP.OFF[vws.ASC_VB_STEPS.value]<=song.selected_pattern.number_of_lines) then
      song.selected_line_index=ASC_STEP.OFF[vws.ASC_VB_STEPS.value]
    end
  else
    if (ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]<=song.selected_pattern.number_of_lines) then
      song.selected_line_index=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
    end
  end
end



--steps navigation
local function asc_steps_nav()
  local pos=song.transport.playback_pos
  --pos.sequence=1
  --pos.line=20
  --song.transport.playback_pos=pos
  for s=1,#ASC_STEP.LNE_A+1 do
    if (s<=vws.ASC_VB_STEPS.value) then
      if (ASC_STEP.LNE_A[s]>song.selected_line_index) then
        if (ASC_STEP.LNE_A[s]<=song.selected_pattern.number_of_lines) then
          pos.sequence=song.selected_sequence_index
          pos.line=ASC_STEP.LNE_A[s]
          song.transport.playback_pos=pos
          song.selected_line_index=pos.line
        else
          pos.sequence=song.selected_sequence_index
          pos.line=ASC_STEP.LNE_A[1]
          song.transport.playback_pos=pos
          song.selected_line_index=pos.line          
        end
        break
      end
    else
      pos.sequence=song.selected_sequence_index
      pos.line=ASC_STEP.LNE_A[1]
      song.transport.playback_pos=pos
      song.selected_line_index=pos.line
      return
    end
  end
end



-------------------------------------------------------------------------------------------------
--functions with timers/notifiers

local ASC_LOOP_LNS={1,1,1,1,1,1} --start lne, end lne, pos.seq, pos.lne, dly, nol

local function asc_play_loop_last_lne_dly()
  if (song.transport.playback_pos.line~=ASC_LOOP_LNS[1]) and (ASC_LOOP_LNS[1]<=ASC_LOOP_LNS[6]) and (song.transport.playing) then
    --local songpos=song.transport.playback_pos
    --songpos.sequence=ASC_LOOP_LNS[3]
    --songpos.line=ASC_LOOP_LNS[1]
    --song.transport:start_at(songpos)
    song.transport:start_at(ASC_LOOP_LNS[1])
  end
  if (rnt:has_timer(asc_play_loop_last_lne_dly)) then
    rnt:remove_timer(asc_play_loop_last_lne_dly)
  end
  --print("asc_play_loop_last_lne_dly",ASC_LOOP_LNS[1])  
end



--playback loop marker with timer
local function asc_play_loop()
  local tra=song.transport
  local pos=tra.playback_pos
  --start line
  if (ASC_LOOP_LNS[1]~=ASC_STEP.LNE_A[1]) then
    ASC_LOOP_LNS[1]=ASC_STEP.LNE_A[1]
  end
  --end line  
  if (ASC_STEP.OFF[vws.ASC_VB_STEPS.value]>ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]) then
    if (ASC_LOOP_LNS[2]~=ASC_STEP.OFF[vws.ASC_VB_STEPS.value]) then
      ASC_LOOP_LNS[2]=ASC_STEP.OFF[vws.ASC_VB_STEPS.value]
    end
  else
    if (ASC_LOOP_LNS[2]~=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]) then
      ASC_LOOP_LNS[2]=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
    end
  end
  ASC_LOOP_LNS[4]=pos.line
  if (ASC_LOOP_LNS[4]>=ASC_LOOP_LNS[2]) or (ASC_LOOP_LNS[4]>=ASC_LOOP_LNS[6]) then
    if (song.selected_sequence_index~=ASC_LOOP_LNS[3]) then
      song.selected_sequence_index=ASC_LOOP_LNS[3]
    end
    if (not rnt:has_timer(asc_play_loop_last_lne_dly)) then
      rnt:add_timer(asc_play_loop_last_lne_dly,ASC_LOOP_LNS[5])
    end

  end  
end



local function asc_play_lop_bpm_lpb()
  if (ASC_LOOP_LNS[3]~=song.selected_sequence_index) then
    ASC_LOOP_LNS[3]=song.selected_sequence_index
  end
  if (ASC_LOOP_LNS[6]~=song.selected_pattern.number_of_lines) then
    ASC_LOOP_LNS[6]=song.selected_pattern.number_of_lines  
  end
  local tra=song.transport
  ASC_LOOP_LNS[5]=math.floor(1000*((60/tra.bpm)/tra.lpb)-90)
  if (ASC_LOOP_LNS[5]<1) then
    ASC_LOOP_LNS[5]=1
  end
end



--on/off play loop marker
local function asc_play_loop_on_off()
  local tra=song.transport
  if (not rnt:has_timer(asc_play_loop)) then
    if (not tra.playing) and (ASC_PREF.mark_play.value) then
      if (ASC_LOOP_LNS[1]~=ASC_STEP.LNE_A[1]) then
        ASC_LOOP_LNS[1]=ASC_STEP.LNE_A[1]
      end
      tra:start_at(ASC_LOOP_LNS[1])
    end
    if (ASC_PREF.mark_loop.value) then
      ASC_LOOP_LNS[3]=song.selected_sequence_index
      asc_play_lop_bpm_lpb()
      if (not song.selected_pattern_observable:has_notifier(asc_play_lop_bpm_lpb)) then
        song.selected_pattern_observable:add_notifier(asc_play_lop_bpm_lpb)
      end
      if (not song.selected_pattern.number_of_lines_observable:has_notifier(asc_play_lop_bpm_lpb)) then
        song.selected_pattern.number_of_lines_observable:add_notifier(asc_play_lop_bpm_lpb)
      end
      if (not tra.bpm_observable:has_notifier(asc_play_lop_bpm_lpb)) then
        tra.bpm_observable:add_notifier(asc_play_lop_bpm_lpb)
      end
      if (not tra.lpb_observable:has_notifier(asc_play_lop_bpm_lpb)) then
        tra.lpb_observable:add_notifier(asc_play_lop_bpm_lpb)
      end
      rnt:add_timer(asc_play_loop,1)    
    end
  else
    if (tra.lpb_observable:has_notifier(asc_play_lop_bpm_lpb)) then
      tra.lpb_observable:remove_notifier(asc_play_lop_bpm_lpb)
    end    
    if (tra.bpm_observable:has_notifier(asc_play_lop_bpm_lpb)) then
      tra.bpm_observable:remove_notifier(asc_play_lop_bpm_lpb)
    end
    if (song.selected_pattern.number_of_lines_observable:has_notifier(asc_play_lop_bpm_lpb)) then
      song.selected_pattern.number_of_lines_observable:remove_notifier(asc_play_lop_bpm_lpb)
    end
    if (song.selected_pattern_observable:has_notifier(asc_play_lop_bpm_lpb)) then
      song.selected_pattern_observable:remove_notifier(asc_play_lop_bpm_lpb)
    end
    rnt:remove_timer(asc_play_loop)
  end
end



-------------------------------------------------------------------------------------------------
--main functions
local function asc_show_pattern_editor()
  local mfr=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
  if (rna.window.active_middle_frame~=mfr) then
    rna.window.active_middle_frame=mfr
  end
end



--distribute lines
local function asc_distribute_lns(min,max)
  local n=0
  if (ASC_JUMP_LINES) then
    n=song.selected_line_index-1
  end
  --lines notes
  ASC_STEP.LNE_A[1]=vws.ASC_VF_START_LNE.value+n
  for step=min,max do
    --lne_a
    if (step>=2) then
      ASC_STEP.LNE_A[step]=ASC_STEP.LNE_A[step-1]+vws["ASC_VF_LNS_"..step-1].value
    end
    --lne_b
    ASC_STEP.LNE_B[step]=ASC_STEP.LNE_A[step]+vws["ASC_VF_LNS_"..step].value-1
    --lines note-offs
    ASC_STEP.OFF[step]=ASC_STEP.LNE_A[step]+vws["ASC_VF_OFF_"..step].value
    --print(ASC_STEP.LNE_A[step],ASC_STEP.LNE_B[step])
    if (ASC_STEP.LNE_A[step]>song.selected_pattern.number_of_lines) then --512) then
      vws["ASC_VF_STEP_LNE_"..step].value=513
    else
      vws["ASC_VF_STEP_LNE_"..step].value=ASC_STEP.LNE_A[step]
    end
  end
  vws.ASC_VF_STEP_LNE_0.value=vws.ASC_VF_STEP_LNE_1.value
end



--check if all note column is empty
local function asc_check_note_column_is_empty()
  local bol=true
  local spt=song.selected_pattern_track
  local snci=song.selected_note_column_index
  if (song.selected_note_column) then
    for lne=1,song.selected_pattern.number_of_lines do
      --if (not spt:line(lne):note_column(snci).is_empty) then
      if (spt:line(lne):note_column(snci).note_value<120) then
        bol=false
        return bol
      end
    end
    return bol
  end
end



--copy/paste (import/insert) nested lines
local ASC_NESTED_LINES_TBL={}
local ASC_NESTED_LINES_ON={false,1}
local function asc_nc_nested_lines_import()
  if (ASC_PREF.insert_nested_lines.value) then
    --asc_distribute_lns(1,vws.ASC_VB_STEPS.value)
    --rprint(ASC_STEP.LNE_B)
    local min=ASC_STEP.LNE_A[1]
    local max=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
    ASC_NESTED_LINES_ON[2]=vws.ASC_VB_STEPS.value
    --print("min",min,"max",max)
    if (ASC_STEP.OFF[vws.ASC_VB_STEPS.value]>ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]) then
      max=ASC_STEP.OFF[vws.ASC_VB_STEPS.value]
    end
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    
    table.clear(ASC_NESTED_LINES_TBL)
    local tbl_lne=0
    for lne=min,max do
      tbl_lne=tbl_lne+1
      ASC_NESTED_LINES_TBL[tbl_lne]=tostring(spt:line(lne):note_column(snci))
    end
    --rprint(ASC_NESTED_LINES_TBL)
  end
  ASC_NESTED_LINES_ON[1]=true
end

local function asc_nc_nested_lines_insert(nol,spt,snci,snc,emod)
  if (ASC_PREF.insert_nested_lines.value) then
    --rprint(ASC_NESTED_LINES_TBL)
    if (emod and ASC_UP_DOWN_BYPASS and ASC_NESTED_LINES_ON[1]) then
      local tbl_lne=0
      for step=1,vws.ASC_VB_STEPS.value do
        local min=ASC_STEP.LNE_A[step]
        local max=ASC_STEP.LNE_B[step]
        if (step==vws.ASC_VB_STEPS.value) and (ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step]) then
          max=ASC_STEP.OFF[step]
        end
        --print("min",min,"max",max)
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          for lne=min,max do
            tbl_lne=tbl_lne+1
            if (lne>min) and (lne<=nol) and (step<=ASC_NESTED_LINES_ON[2]) then
              local nc=spt:line(lne):note_column(snci) --(snci+1)
              nc.note_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],1,3)
              nc.instrument_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],4,5)
              nc.volume_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],6,7)
              nc.panning_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],8,9)
              nc.delay_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],10,11)
              nc.effect_number_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],12,13)
              nc.effect_amount_string=string.sub(ASC_NESTED_LINES_TBL[tbl_lne],14,15)
              --print(string.sub(ASC_NESTED_LINES_TBL[lne],1,3))
              --print(lne,i)
            end
          end
        end
      end
    end
  end
end



--import note column
local function asc_import_nc(max)
  ASC_IMPORT_BYPASS=false
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    local step=0
    local ASC_IMP={
      OFF_LNE={},
      NTE_LNE={},
      NTE={},
      INS={},
      VOL={},
      PAN={},
      DLY={},
      SFX={},
      AMO={}
    }
    local function update_lns(key_sta)
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or
        (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released" and ASC_RANDOM_BYPASS) then
         ASC_JUMP_LINES=true
      end
      --update lines position
      if (not ASC_JUMP_LINES) then
        for lne=1,nol do
          local nc=spt:line(lne):note_column(snci)
          if (nc.note_value<120) then
            vws.ASC_VF_START_LNE.value=lne
            break
          end
        end
      end
      asc_distribute_lns(1,32)
      ASC_JUMP_LINES=false
    end

    if (asc_check_note_column_is_empty()) then
      if not ASC_RANDOM_LINES then
        asc_status_bar_on(4000,28,"",0)
      end
      update_lns(key_sta)
      ASC_IMPORT_BYPASS=true
      return 
    else
      local l=1      
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") then
        l=song.selected_line_index
      end
      for lne=l,nol do
        local nc=spt:line(lne):note_column(snci)
        if (nc.note_value<120) then
         step=step+1
         --if (step>32) then
         if (step>max) then
           break
         end
         ASC_STEP.LNE_A[step]=lne
         ASC_IMP.NTE_LNE[step]=lne
         ASC_IMP.NTE[step]=nc.note_value
         ASC_IMP.INS[step]=nc.instrument_value
         ASC_IMP.VOL[step]=nc.volume_value
         ASC_IMP.PAN[step]=nc.panning_value
         ASC_IMP.DLY[step]=nc.delay_value
         ASC_IMP.SFX[step]=nc.effect_number_string
         ASC_IMP.AMO[step]=nc.effect_amount_value
         --print(ASC_STEP.LNE_A[step],ASC_IMP.NTE_LNE[step])
         --print(ASC_IMP.NTE[step])
        end
      end
      --show steps
      if (ASC_RANDOM_BYPASS and #ASC_IMP.NTE~=0) then
        vws.ASC_VB_STEPS.value=#ASC_IMP.NTE
      end
      --apply note values
      local function apply_values(step)
        vws["ASC_VB_NTE_"..step].value=ASC_IMP.NTE[step]
        vws["ASC_VF_INS_"..step].value=ASC_IMP.INS[step]
        if (ASC_IMP.VOL[step]==255) then
          vws["ASC_VF_VOL_"..step].value=0
        elseif (ASC_IMP.VOL[step]<=127) then
          vws["ASC_VF_VOL_"..step].value=ASC_IMP.VOL[step]+1
        end
        if (ASC_IMP.PAN[step]==255) then
          vws["ASC_VF_PAN_"..step].value=0
        elseif (ASC_IMP.PAN[step]<=128) then
          vws["ASC_VF_PAN_"..step].value=ASC_IMP.PAN[step]+1
        end
        vws["ASC_VF_DLY_"..step].value=ASC_IMP.DLY[step]
        vws["ASC_VF_SFX_AMO_"..step].value=ASC_IMP.AMO[step]
        
        for t=1,19 do --#ASC_SFX_EF2 do
          if (ASC_SFX_EF2[t]==ASC_IMP.SFX[step]) then
            vws["ASC_PP_SFX_EFF_"..step].value=t
            break
          end
        end
      end
      for step=2,#ASC_IMP.NTE do
        if (ASC_IMP.NTE_LNE[step]-ASC_IMP.NTE_LNE[step-1]<=99) then
          vws["ASC_VF_LNS_"..step-1].value=ASC_IMP.NTE_LNE[step]-ASC_IMP.NTE_LNE[step-1]
        else
          break
        end
      end
      for step=1,#ASC_IMP.NTE do
        apply_values(step)
      end
      
      --apply off values
      for step=1,#ASC_IMP.NTE do
        if (step<#ASC_IMP.NTE) then
          if (ASC_IMP.NTE_LNE[step]<ASC_IMP.NTE_LNE[step+1]) then
            for lne=ASC_IMP.NTE_LNE[step]+1,ASC_IMP.NTE_LNE[step+1] do
              local nc=spt:line(lne):note_column(snci)
              if (nc.note_value==120) then
                ASC_IMP.OFF_LNE[step]=lne-ASC_IMP.NTE_LNE[step]
                break
              elseif (nc.note_value<119) then
                ASC_IMP.OFF_LNE[step]=0
                break
              end
            end
          end
        elseif (step==#ASC_IMP.NTE) then
          if (ASC_IMP.NTE_LNE[step]<nol) then
            for lne=ASC_IMP.NTE_LNE[step]+1,nol do
              local nc=spt:line(lne):note_column(snci)
              if (nc.note_value==120) then
                ASC_IMP.OFF_LNE[step]=lne-ASC_IMP.NTE_LNE[step]
                
                break
              elseif (nc.note_value<119) then
                ASC_IMP.OFF_LNE[step]=0
                break
              elseif lne==nol and (nc.note_value==121) then
                ASC_IMP.OFF_LNE[step]=0
              end
            end
          end
        end
      end    
      --rprint(ASC_IMP.NTE_LNE)
      --rprint(ASC_IMP.OFF_LNE)
      for step=1,#ASC_IMP.NTE do
        --print(step)
        if (ASC_IMP.OFF_LNE[step]) then
          if (ASC_IMP.OFF_LNE[step]<=99) then
            vws["ASC_VF_OFF_"..step].value=ASC_IMP.OFF_LNE[step]
          end
        end
      end
      if not ASC_RANDOM_LINES then
        asc_status_bar_on(4000,29,("%s"):format(#ASC_IMP.NTE),0)
      end
      update_lns(key_sta)
      --rprint(ASC_STEP.OFF)
      asc_nc_nested_lines_import()
      ASC_IMPORT_BYPASS=true
      return 
    end
  else
    if not ASC_RANDOM_LINES then
      asc_status_bar_on(4000,9,"",0)
    end
  end
  ASC_IMPORT_BYPASS=true
end



--jump step
local function asc_jump_step(step,nol)
  local key_sta=rna.key_modifier_states
  --asc_distribute_lns(step,step)
  --jump line
  if (ASC_RANDOM_BYPASS) then
    if (step~=0) and (ASC_STEP.LNE_A[step]<=nol) then
      song.selected_line_index=ASC_STEP.LNE_A[step]
    elseif (step==0) and (ASC_STEP.LNE_A[1]<=nol) then
      song.selected_line_index=ASC_STEP.LNE_A[1]
    end
  end
end



--auto grown
local function asc_auto_sequence()
  local ssi=song.selected_sequence_index
  if (ssi==#song.sequencer.pattern_sequence and ssi<1000) then
    song.sequencer:insert_new_pattern_at(ssi+1)
    --clear if exist a pattern not visible
    --if (ssi+1<=#song.sequencer.pattern_sequence) then
    if (ssi+1<=#song.patterns) then
      song:pattern(ssi+1):clear()
      song:pattern(ssi+1).number_of_lines = song:pattern(ssi).number_of_lines
    end
  end
end
---
local ASC_AUTO_SEQUENCE=false
function asc_auto_sequence_obs()
  local trans=song.transport
  if (ASC_AUTO_SEQUENCE==false) then
    if not rnt:has_timer(asc_auto_sequence) then
      rnt:add_timer(asc_auto_sequence,5)
    end
    asc_auto_sequence()
    trans.follow_player=true
    trans.wrapped_pattern_edit=true
    trans:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
    rna.window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
    rna.window.pattern_matrix_is_visible=true
    ASC_AUTO_SEQUENCE=true
    vws.ASC_BT_INSERT_STEPS_AUTO_GROUND.bitmap="ico/apply_grown_ico.png"
    vws.ASC_BM_RDM.bitmap="ico/button_blue2_ico.png"
    asc_status_bar_on(4000,20,"",0)
  else
    if rnt:has_timer(asc_auto_sequence) then
      rnt:remove_timer(asc_auto_sequence)
    end
    trans:stop()
    ASC_AUTO_SEQUENCE=false
    vws.ASC_BT_INSERT_STEPS_AUTO_GROUND.bitmap="ico/apply_ico.png"
    vws.ASC_BM_RDM.bitmap="ico/button_green2_ico.png"
    asc_status_bar_on(4000,21,"",0)
  end
end



local function asc_update_ins_idx()
  if (ASC_PREF.cap_ins_idx.value) then
    local sii=song.selected_instrument_index-1
    ASC_AUTOCAP_INS_BYPASS=false
    for step=0,vws.ASC_VB_STEPS.value do
      if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
        if (vws["ASC_VF_INS_"..step].value~=sii) then
          vws["ASC_VF_INS_"..step].value=sii
        end
      end
    end
    ASC_AUTOCAP_INS_BYPASS=true
  end
end



local ASC_WRITE_ALL_BYPASS=true
local function asc_write_all(step,insert)
  --print("asc_write_all()")
  --local x=os.clock()
  local emod=song.transport.edit_mode
  local spt=song.selected_pattern_track
  local nol=song.selected_pattern.number_of_lines
  local snc=song.selected_note_column
  local sec=song.selected_effect_column
  local key_sta=rna.key_modifier_states
  
  if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
     (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") or --control
     (key_sta.alt=="pressed" and key_sta.control=="pressed" and key_sta.shift=="released") or --control alt
     (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released" and ASC_RANDOM_BYPASS) then
    ASC_JUMP_LINES=true
  end

  --update instrument index
  asc_update_ins_idx()

  --update lines position
  asc_distribute_lns(1,32)

  --force nol
  if (snc and emod) then
    if (step==0) then
      if(key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then --alt
        if (ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]<512) then
          song.selected_pattern.number_of_lines=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
          nol=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
          local snci=song.selected_note_column_index
          for lne=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]+1,512 do
            if not spt:line(lne):note_column(snci).is_empty then
              spt:line(lne):note_column(snci):clear()
            end
          end
        else
          song.selected_pattern.number_of_lines=512
        end
        asc_distribute_lns(1,32)
      end
    end
  end
  
  --modify values
  if (step~=0) then
    for step=0,vws.ASC_VB_STEPS.value do
      --nte
      if (vws["ASC_VB_NTE_"..step].value<120) then
        ASC_STEP.NTE[step]=vws["ASC_VB_NTE_"..step].value
      elseif (vws["ASC_VB_NTE_"..step].value==120) then
        ASC_STEP.NTE[step]=121
      end
      --ins
      ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
      --vol
      if (vws["ASC_VF_VOL_"..step].value==0) then
        ASC_STEP.VOL[step]=255
      else
        ASC_STEP.VOL[step]=vws["ASC_VF_VOL_"..step].value-1
      end
      --pan
      if (vws["ASC_VF_PAN_"..step].value==0) then
        ASC_STEP.PAN[step]=255
      else
        ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
      end
      --dly
      ASC_STEP.DLY[step]=vws["ASC_VF_DLY_"..step].value
      --sfx eff
      if (snc) and (vws["ASC_PP_SFX_EFF_"..step].value>19) then
        vws["ASC_PP_SFX_EFF_"..step].value=19
      end
      ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
      --sfx amo
      ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
    end
  else
    for step=0,vws.ASC_VB_STEPS.value do
      --nte
      ASC_STEP.NTE[step]=vws["ASC_VB_NTE_"..step].value
      --ins
      ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
      --vol
      if (vws["ASC_VF_VOL_"..step].value==0) then
        ASC_STEP.VOL[step]=255
      else
        ASC_STEP.VOL[step]=vws["ASC_VF_VOL_"..step].value-1
      end
      --pan
      if (vws["ASC_VF_PAN_"..step].value==0) then
        ASC_STEP.PAN[step]=255
      else
        ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
      end
      --dly
      ASC_STEP.DLY[step]=vws["ASC_VF_DLY_"..step].value
      --sfx eff
      if (snc) and (vws["ASC_PP_SFX_EFF_"..step].value>19) then
        vws["ASC_PP_SFX_EFF_"..step].value=19
      end
      ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
      --sfx amo
      ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
    end
  end

  local function nc_clear(nol,spt,snci)
    --clear lines top
    if (not ASC_JUMP_LINES) then
      if (ASC_STEP.LNE_A[1]>1) then
        for lne=1,ASC_STEP.LNE_A[1] do
          if not spt:line(lne):note_column(snci).is_empty then
            spt:line(lne):note_column(snci):clear()
          end
        end
      end
    else
      local lne=ASC_STEP.LNE_A[1]-1
      if (lne>=song.selected_line_index) then
        if not spt:line(lne):note_column(snci).is_empty then
          spt:line(lne):note_column(snci):clear()
        end
      end
    end

    --clear lines bottom
    local function clear_lines_bottom()
      if (not ASC_JUMP_LINES) then --or not ASC_UP_DOWN_BYPASS) then
        if (ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]<=nol and ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]>1) then
          for lne=ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]-1,nol do
            if not spt:line(lne):note_column(snci).is_empty then
              spt:line(lne):note_column(snci):clear()
            end
          end
        end
      end
    end    
    --clear steps all
    local function clear_steps_all()
      for step=1,vws.ASC_VB_STEPS.value do
        for lne=ASC_STEP.LNE_A[step],ASC_STEP.LNE_B[step] do
          if (lne<=nol) then
            if not spt:line(lne):note_column(snci).is_empty then
              spt:line(lne):note_column(snci):clear()
            end
          end
        end
      end    
    end
    --clear steps custom
    local function clear_steps_custom()
      for step=1,vws.ASC_VB_STEPS.value do
        if (not ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          for lne=ASC_STEP.LNE_A[step],ASC_STEP.LNE_B[step] do
            if (lne<=nol) then
              if not spt:line(lne):note_column(snci).is_empty then
                spt:line(lne):note_column(snci):clear()
              end
            end
          end
        end
      end
    end
    if (vws.ASC_PP_SELECT.value==1) or (vws.ASC_PP_SELECT.value==5) then
      clear_lines_bottom()
      clear_steps_all()
    else
      if (not ASC_UP_DOWN_BYPASS) then
        clear_lines_bottom()
        clear_steps_all()
      elseif (vws.ASC_PP_SELECT.value==2) or (vws.ASC_PP_SELECT.value==3) then
        if (not ASC_PREF.odd_even_not_clear.value) then
          clear_lines_bottom()
          clear_steps_custom()
        end
      elseif (vws.ASC_PP_SELECT.value==4) then
        if (not ASC_PREF.custom_not_clear.value) then
          clear_lines_bottom()
          clear_steps_custom()
        end
      end
    end
  end
  
  local function nc_insert(nol,spt,snci,insert)
    if (insert) then
      --insert steps
      local function insert(step)
        if (ASC_STEP.LNE_A[step]<=nol) then
          local nc=spt:line(ASC_STEP.LNE_A[step]):note_column(snci)
          if (ASC_STEP.OFF[step]~=nil) then
            if (ASC_STEP.OFF[step]<=nol) then
              local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
              if (step<vws.ASC_VB_STEPS.value) then
                if (ASC_STEP.OFF[step]<ASC_STEP.LNE_A[step+1]) then
                  nc_off.note_value=120
                end
              else
                nc_off.note_value=120
              end
            end
          end
          --note 0-119 or empty
          nc.note_value=ASC_STEP.NTE[step]
          --instrument
          nc.instrument_value=ASC_STEP.INS[step]
          --vol, pan, dly
          nc.volume_value=ASC_STEP.VOL[step]
          --print(ASC_STEP.PAN[step])
          nc.panning_value=ASC_STEP.PAN[step]
          nc.delay_value=ASC_STEP.DLY[step]
          --sfx eff, sfx amo
          nc.effect_number_string=ASC_STEP.SFX_EFF[step]
          nc.effect_amount_value=ASC_STEP.SFX_AMO[step]
        end
      end
      if (not ASC_UP_DOWN_BYPASS) then
        for step=1,vws.ASC_VB_STEPS.value do
          insert(step)
        end
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            insert(step)
          end
        end
      end
    end
  end

  local function nc_reverse(nol,spt,snci)
    if (ASC_PREF.reverse_all.value) then
      local function reverse_lns()
        --print("lne_a original-----------")
        --rprint(ASC_STEP.LNE_A)
        --print("off original-------------")
        --rprint(ASC_STEP.OFF)
        local step_wide={}
        local off_wide={}
        local s=0
        for step=vws.ASC_VB_STEPS.value,1,-1 do
          s=s+1
          if (vws.ASC_VB_STEPS.value) then
            if (ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step]) then
              step_wide[s]=ASC_STEP.OFF[step]-ASC_STEP.LNE_A[step]
            else
              step_wide[s]=ASC_STEP.LNE_B[step]-ASC_STEP.LNE_A[step]
            end
          else
            step_wide[s]=ASC_STEP.LNE_B[step]-ASC_STEP.LNE_A[step]
          end
          off_wide[s]  =ASC_STEP.OFF[step]-ASC_STEP.LNE_A[step]
        end
        --print("step_wide----------------")
        --rprint(step_wide)
        local n=0
        if (ASC_JUMP_LINES) then
          n=song.selected_line_index-1
        end
        --lines notes
        ASC_STEP.LNE_A[1]=vws.ASC_VF_START_LNE.value+n
        
        --ASC_STEP.LNE_B[1]=ASC_STEP.LNE_A[1]+step_wide[1]
        --define lne_a
        for step=2,vws.ASC_VB_STEPS.value do
          ASC_STEP.LNE_A[step]=ASC_STEP.LNE_A[step-1]+step_wide[step-1]+1
        end
        --print("lne_a reversed-----------")
        --rprint(ASC_STEP.LNE_A)

        --dfine off
        for step=1,vws.ASC_VB_STEPS.value do
          ASC_STEP.OFF[step]=ASC_STEP.LNE_A[step]+off_wide[step]
        end
        --print("off reversed-----------")
        --rprint(ASC_STEP.OFF)
      end
      reverse_lns() 
    end
    --insert steps in note reverse
    for step=1,vws.ASC_VB_STEPS.value do
      if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
        --print(step, ASC_STEP.OFF[step])
        if (ASC_STEP.LNE_A[step]<=nol) then
          local nc=spt:line(ASC_STEP.LNE_A[step]):note_column(snci)
          if (ASC_STEP.OFF[step]~=nil) then
            if (ASC_STEP.OFF[step]<=nol) then
              local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
              if (step<vws.ASC_VB_STEPS.value) then
                if (ASC_STEP.OFF[step]<ASC_STEP.LNE_A[step+1]) then
                  nc_off.note_value=120
                end
              else
                nc_off.note_value=120
              end
            end
          end
          
          local step_=vws.ASC_VB_STEPS.value+1-step
          --note 0-119 or empty
          nc.note_value=ASC_STEP.NTE[step_]
          --instrument
          nc.instrument_value=ASC_STEP.INS[step_]
          --vol, pan, dly
          --print(ASC_STEP.VOL[step])
          nc.volume_value=ASC_STEP.VOL[step_]
          --print(ASC_STEP.PAN[step])
          nc.panning_value=ASC_STEP.PAN[step_]
          nc.delay_value=ASC_STEP.DLY[step_]
          --sfx eff, sfx amo
          nc.effect_number_string=ASC_STEP.SFX_EFF[step_]
          nc.effect_amount_value=ASC_STEP.SFX_AMO[step_]
        end
      end
    end
  end
 
  local function nc_continuous_paste(nol,spt,snci)
    local cont=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]
    if (ASC_PREF.continuous_off.value) then
      --print("continuous_off")
      if (ASC_STEP.OFF[vws.ASC_VB_STEPS.value]>ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value]) then
        cont=ASC_STEP.OFF[vws.ASC_VB_STEPS.value]
      end
    end
    local ini=ASC_STEP.LNE_A[1]
    for lne=ini,cont do
      for n=cont-ini+1,nol,cont-ini+1 do
        if (lne+n<=nol) then
          spt:line(lne+n):note_column(snci):copy_from(spt:line(lne):note_column(snci))
        end
      end
    end
  end
  
  local function nc_visible(nol,spt,snci)
    --visible sub-columns
    if (ASC_VISIBLE_SUB_COLUMN_BYPASS) then
      local sst=song.selected_track
      for step=1,vws.ASC_VB_STEPS.value do
        if (sst.volume_column_visible) then
          break
        elseif (ASC_STEP.VOL[step]~=255) then
          sst.volume_column_visible=true
          break
        end
      end
      for step=1,vws.ASC_VB_STEPS.value do
        if (sst.panning_column_visible) then
          break
        elseif (ASC_STEP.PAN[step]~=255) then
          sst.panning_column_visible=true
          break
        end
      end
      for step=1,vws.ASC_VB_STEPS.value do
        if (sst.delay_column_visible) then
          break
        elseif (ASC_STEP.DLY[step]~=0) then
          sst.delay_column_visible=true
          break
        end
      end
      for step=1,vws.ASC_VB_STEPS.value do
        if (sst.sample_effects_column_visible) then
          break
        elseif (vws["ASC_PP_SFX_EFF_"..step].value~=19) then
          sst.sample_effects_column_visible=true
          break
        end
      end
      for step=1,vws.ASC_VB_STEPS.value do        
        if (sst.sample_effects_column_visible) then
          break
        elseif (ASC_STEP.SFX_AMO[step]~=0) then
          sst.sample_effects_column_visible=true
          break
        end
      end
    end
  end

  local function ec_clear(nol,spt,seci)
    --clear lines top
    if (not ASC_JUMP_LINES) then
      if (ASC_STEP.LNE_A[1]>=1) then
        for lne=1,ASC_STEP.LNE_A[1] do
          if not spt:line(lne):effect_column(seci).is_empty then
            spt:line(lne):effect_column(seci):clear()
          end
        end
      end
    else
      local lne=ASC_STEP.LNE_A[1]-1
      if (lne>=song.selected_line_index) then
        if not spt:line(lne):effect_column(seci).is_empty then
          spt:line(lne):effect_column(seci):clear()
        end
      end
    end
    if (not ASC_JUMP_LINES) then --or not ASC_UP_DOWN_BYPASS) then
      --clear lines bottom
      if (ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]<=nol and ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]>1) then
        for lne=ASC_STEP.LNE_A[vws.ASC_PP_SELECT.value+1]-1,nol do
          if not spt:line(lne):effect_column(seci).is_empty then
            spt:line(lne):effect_column(seci):clear()
          end
        end
      end
    end
    --clear steps
    for step=1,vws.ASC_VB_STEPS.value do
      for lne=ASC_STEP.LNE_A[step],ASC_STEP.LNE_B[step] do
        if (lne<=nol) then
          if not spt:line(lne):effect_column(seci).is_empty then
            spt:line(lne):effect_column(seci):clear()
          end
        end
      end
    end
  end

  local function ec_insert(nol,spt,seci)
    --insert steps
    for step=1,vws.ASC_VB_STEPS.value do
      --print(step, ASC_STEP.OFF[step])
      if (ASC_STEP.LNE_A[step]<=nol) then
        local ec=spt:line(ASC_STEP.LNE_A[step]):effect_column(seci)
        --sfx eff, sfx amo
        ec.number_string=ASC_STEP.SFX_EFF[step]
        ec.amount_value=ASC_STEP.SFX_AMO[step]
      end
    end
  end

  local function ec_reverse(nol,spt,seci)
    --insert steps
    for step=1,vws.ASC_VB_STEPS.value do
      --print(step, ASC_STEP.OFF[step])
      if (ASC_STEP.LNE_A[step]<=nol) then
        local ec=spt:line(ASC_STEP.LNE_A[step]):effect_column(seci)
        local step_=vws.ASC_VB_STEPS.value+1-step
        --sfx eff, sfx amo
        ec.number_string=ASC_STEP.SFX_EFF[step_]
        ec.amount_value=ASC_STEP.SFX_AMO[step_]
      end
    end  
  end  

  local function ec_continuous_paste(nol,spt,seci)
    for lne=1,ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value] do
      for n=ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value],nol,ASC_STEP.LNE_B[vws.ASC_VB_STEPS.value] do
        if (lne+n<=nol) then
          spt:line(lne+n):effect_column(seci):copy_from(spt:line(lne):effect_column(seci))
        end
      end
    end  
  end
  
  if (emod) then
    if (snc) then
      local snci=song.selected_note_column_index
      --for direct insert
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") or
         (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") or
         (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") then
        nc_clear(nol,spt,snci)
        nc_insert(nol,spt,snci,insert)
        nc_visible(nol,spt,snci)
        asc_nc_nested_lines_insert(nol,spt,snci,snc,emod)
      end
      --for continuous paste
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
        nc_clear(nol,spt,snci)
        nc_insert(nol,spt,snci,insert)
        nc_continuous_paste(nol,spt,snci)
        nc_visible(nol,spt,snci)
        asc_nc_nested_lines_insert(nol,spt,snci,snc,emod)
      end
      --for reverse insert
      if (key_sta.alt=="pressed" and key_sta.control=="pressed" and key_sta.shift=="released") then
        nc_clear(nol,spt,snci)
        nc_reverse(nol,spt,snci)
        nc_visible(nol,spt,snci)
        asc_nc_nested_lines_insert(nol,spt,snci,snc,emod)
      end
    end
    if (sec) then
      local seci=song.selected_effect_column_index
      --for direct insert
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") or
         (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") or
         (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") then
        ec_clear(nol,spt,seci)
        ec_insert(nol,spt,seci)
      end
      --for continuous paste
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
        ec_clear(nol,spt,seci)
        ec_insert(nol,spt,seci)
        ec_continuous_paste(nol,spt,seci)
      end
      --for reverse insert
      if (key_sta.alt=="pressed" and key_sta.control=="pressed" and key_sta.shift=="released") then
        ec_clear(nol,spt,seci)
        ec_reverse(nol,spt,seci)
      end
    end
    --jump line
    if (not ASC_JUMP_LINES) then
      asc_jump_step(step,nol)
    else
      ASC_JUMP_LINES=false
    end
  end
  
  if not ASC_AUTO_SEQUENCE then
    if (not emod) then
      asc_status_bar_on(4000,6,"",0)
    else
      local string=("%.2d"):format(ASC_STEP.LNE_A[1]-1)
      asc_status_bar_on(5000,19,string,0)
    end
  end
  if (step~=0) and (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="pressed") then
    asc_auto_sequence_obs()
  end
  asc_show_pattern_editor()
  --rprint(ASC_STEP.OFF)
  --print(string.format("write_all: %.2f ms\n",(os.clock()- x)*1000))
end



local function asc_clear_all()
  if (song.transport.edit_mode) then
    local spt=song.selected_pattern_track
    local nol=song.selected_pattern.number_of_lines
    local sli=song.selected_line_index
    local snc=song.selected_note_column
    local sec=song.selected_effect_column
    local key_sta=rna.key_modifier_states

    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or
       (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released" and ASC_RANDOM_BYPASS) then
      ASC_JUMP_LINES=true
    end
  
    --update lines position
    asc_distribute_lns(1,32)

    if (snc) then
      local snci=song.selected_note_column_index
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then --any
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              --print(lne)
              if (not spt:line(lne):note_column(snci).is_empty) and (lne<=nol) then
                spt:line(lne):note_column(snci):clear()
              end
            end
          end
        end
        song.selected_line_index=1
        return
      end
      if (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then --alt
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              if (not spt:line(lne):note_column(snci).is_empty) and (lne<=nol) then
                if (lne~=a) then
                  if (spt:line(lne):note_column(snci).note_value~=120) then
                    spt:line(lne):note_column(snci):clear()
                  end
                end
              end
            end
          end
        end
        --jump line
        if (not ASC_JUMP_LINES) then
          asc_jump_step(1,nol)
        else
          ASC_JUMP_LINES=false
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") then --shift
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              if (not spt:line(lne):note_column(snci).is_empty) and (lne<=nol) then
                spt:line(lne):note_column(snci):clear()
              end
            end
          end
        end
        --jump line
        if (not ASC_JUMP_LINES) then
          asc_jump_step(1,nol)
        else
          ASC_JUMP_LINES=false
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
        for lne=sli,nol do
          if (not spt:line(lne):note_column(snci).is_empty) then
            spt:line(lne):note_column(snci):clear()
          end
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="pressed") then --control shift
        local vnc=song.selected_track.visible_note_columns
        for lne=sli,nol do
          for c=1,vnc do
            if (not spt:line(lne):note_column(c).is_empty) then
              spt:line(lne):note_column(c):clear()
            end
          end
        end
        return
      end
    end
    
    if (sec) then
      local seci=song.selected_effect_column_index
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              --print(lne)
              if (not spt:line(lne):effect_column(seci).is_empty) and (lne<=nol) then
                spt:line(lne):effect_column(seci):clear()
              end
            end
          end
        end
        song.selected_line_index=1
        return
      end
      if (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              if (not spt:line(lne):effect_column(seci).is_empty) and (lne<=nol) then
                if (lne~=ASC_STEP.LNE_A[step]) then
                  spt:line(lne):effect_column(seci):clear()
                end
              end
            end
          end
        end
        --jump line
        if (not ASC_JUMP_LINES) then
          asc_jump_step(1,nol)
        else
          ASC_JUMP_LINES=false
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") then
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            local a=ASC_STEP.LNE_A[step]
            local b=ASC_STEP.LNE_B[step]
            if ASC_STEP.OFF[step]>ASC_STEP.LNE_B[step] then
              b=ASC_STEP.OFF[step]
            end
            for lne=a,b do
              if (not spt:line(lne):effect_column(seci).is_empty) and (lne<=nol) then
                spt:line(lne):effect_column(seci):clear()
              end
            end
          end
        end
        --jump line
        if (not ASC_JUMP_LINES) then
          asc_jump_step(1,nol)
        else
          ASC_JUMP_LINES=false
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
        for lne=sli,nol do
          if (not spt:line(lne):effect_column(seci).is_empty) then
            spt:line(lne):effect_column(seci):clear()
          end
        end
        return
      end
      if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="pressed") then
        local vec=song.selected_track.visible_effect_columns
        for lne=sli,nol do
          for e=1,vec do
            if (not spt:line(lne):effect_column(e).is_empty) then
              spt:line(lne):effect_column(e):clear()
            end
          end
        end
        return
      end
    end
  else
    asc_status_bar_on(4000,7,"",0)
  end
  --print(string.format("asc_write_all: %.2f ms\n",(os.clock()- x)*1000))
end



--transpose notes up/down
local function asc_transpose_up()
  if (song.selected_note_column) then
    local nol=song.selected_pattern.number_of_lines
    for step=vws.ASC_VB_STEPS.value,1,-1 do
      if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) and (ASC_STEP.LNE_A[step]<=nol) then
        if (vws["ASC_VB_NTE_"..step].value<=119) then
          vws["ASC_VB_NTE_"..step].value=vws["ASC_VB_NTE_"..step].value+1
        end
      end
    end
  else
    asc_status_bar_on(4000,11,"",0)
  end
  if (not song.transport.edit_mode) then
    asc_status_bar_on(4000,8,"",0)
  end
end

local function asc_transpose_down()
  if (song.selected_note_column) then
    local nol=song.selected_pattern.number_of_lines
    for step=vws.ASC_VB_STEPS.value,1,-1 do
      if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) and (ASC_STEP.LNE_A[step]<=nol) then
        if (vws["ASC_VB_NTE_"..step].value>0 and vws["ASC_VB_NTE_"..step].value<120) then
          vws["ASC_VB_NTE_"..step].value=vws["ASC_VB_NTE_"..step].value-1
        end
      end
    end
  else
    asc_status_bar_on(4000,11,"",0)
  end
  if (not song.transport.edit_mode) then
    asc_status_bar_on(4000,8,"",0)
  end
end

function asc_transpose_up_repeat(release)
  if not release then
    if rnt:has_timer(asc_transpose_up_repeat) then
      rnt:remove_timer(asc_transpose_up_repeat)
      if not (rnt:has_timer(asc_transpose_up)) then
        rnt:add_timer(asc_transpose_up,40)
      end
    else
      if rnt:has_timer(asc_transpose_up_repeat) then
        rnt:remove_timer(asc_transpose_up_repeat)
      elseif rnt:has_timer(asc_transpose_up) then
        rnt:remove_timer(asc_transpose_up)
      end
      asc_transpose_up()
      rnt:add_timer(asc_transpose_up_repeat,300)
    end
  else
    if rnt:has_timer(asc_transpose_up_repeat) then
      rnt:remove_timer(asc_transpose_up_repeat)
    elseif rnt:has_timer(asc_transpose_up) then
      rnt:remove_timer(asc_transpose_up)
    end
  end
end
function asc_transpose_down_repeat(release)
  if not release then
    if rnt:has_timer(asc_transpose_down_repeat) then
      rnt:remove_timer(asc_transpose_down_repeat)
      if not (rnt:has_timer(asc_transpose_down)) then
        rnt:add_timer(asc_transpose_down,40)
      end
    else
      if rnt:has_timer(asc_transpose_down_repeat) then
        rnt:remove_timer(asc_transpose_down_repeat)
      elseif rnt:has_timer(asc_transpose_down) then
        rnt:remove_timer(asc_transpose_down)
      end
      asc_transpose_down()
      rnt:add_timer(asc_transpose_down_repeat,300)
    end
  else
    if rnt:has_timer(asc_transpose_down_repeat) then
      rnt:remove_timer(asc_transpose_down_repeat)
    elseif rnt:has_timer(asc_transpose_down) then
      rnt:remove_timer(asc_transpose_down)
    end
  end
end



local function asc_write_ins(step)
  --print("asc_write_ins(step)")
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).instrument_value=ASC_STEP.INS[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
      else
        ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_INS_"..step].value=vws.ASC_VF_INS_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_INS_"..step].value=vws.ASC_VF_INS_0.value
              ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).instrument_value=ASC_STEP.INS[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_VF_INS_"..step].value=vws.ASC_VF_INS_0.value
            ASC_STEP.INS[step]=vws.ASC_VF_INS_0.value
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
end



local function asc_write_nte(step)
  --print("asc_write_nte(step)")
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          if (vws["ASC_VB_NTE_"..step].value==120) then
            ASC_STEP.NTE[step]=121
          else
            ASC_STEP.NTE[step]=vws["ASC_VB_NTE_"..step].value
          end
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).note_value=ASC_STEP.NTE[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
      else
        if (vws["ASC_VB_NTE_"..step].value==120) then
          ASC_STEP.NTE[step]=121
        else
          ASC_STEP.NTE[step]=vws["ASC_VB_NTE_"..step].value
        end
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=vws.ASC_VB_STEPS.value,1,-1 do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VB_NTE_"..step].value=vws.ASC_VB_NTE_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              if (vws.ASC_VB_NTE_0.value==120) then
                vws["ASC_VB_NTE_"..step].value=120
                ASC_STEP.NTE[step]=121
              else
                vws["ASC_VB_NTE_"..step].value=vws.ASC_VB_NTE_0.value
                ASC_STEP.NTE[step]=vws.ASC_VB_NTE_0.value
              end
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).note_value=ASC_STEP.NTE[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            if (vws.ASC_VB_NTE_0.value==120) then
              vws["ASC_VB_NTE_"..step].value=120
              ASC_STEP.NTE[step]=121
            else
              vws["ASC_VB_NTE_"..step].value=vws.ASC_VB_NTE_0.value
              ASC_STEP.NTE[step]=vws.ASC_VB_NTE_0.value
            end
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
end



local function asc_write_vol(step)
  --local x=os.clock()
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          if (vws["ASC_VF_VOL_"..step].value==0) then
            ASC_STEP.VOL[step]=255
          else
            ASC_STEP.VOL[step]=vws["ASC_VF_VOL_"..step].value-1
          end
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).volume_value=ASC_STEP.VOL[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
        if (not song.selected_track.volume_column_visible) and (vws["ASC_VF_VOL_"..step].value~=0) then
          song.selected_track.volume_column_visible=true
        end
      else
        if (vws["ASC_VF_VOL_"..step].value==0) then
          ASC_STEP.VOL[step]=255
        else
          ASC_STEP.VOL[step]=vws["ASC_VF_VOL_"..step].value-1
        end
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_VOL_"..step].value=vws.ASC_VF_VOL_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              if (vws.ASC_VF_VOL_0.value==0) then
                vws["ASC_VF_VOL_"..step].value=0
                ASC_STEP.VOL[step]=255
              else
                vws["ASC_VF_VOL_"..step].value=vws.ASC_VF_VOL_0.value
                ASC_STEP.VOL[step]=vws.ASC_VF_VOL_0.value-1
              end
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).volume_value=ASC_STEP.VOL[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
        if (not song.selected_track.volume_column_visible) and (vws.ASC_VF_VOL_0.value~=0) then
          song.selected_track.volume_column_visible=true
        end
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            if (vws.ASC_VF_VOL_0.value==0) then
              vws["ASC_VF_VOL_"..step].value=0
              ASC_STEP.VOL[step]=255
            else
              vws["ASC_VF_VOL_"..step].value=vws.ASC_VF_VOL_0.value
              ASC_STEP.VOL[step]=vws.ASC_VF_VOL_0.value-1
            end
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
  --print(string.format("write_vol: %.2f ms\n",(os.clock()- x)*1000))
end



local function asc_write_pan(step)
  --local x=os.clock()
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          if (vws["ASC_VF_PAN_"..step].value==0) then
            ASC_STEP.PAN[step]=255
          else
            ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
          end
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
        if (not song.selected_track.panning_column_visible) and (vws["ASC_VF_PAN_"..step].value~=0) then
          song.selected_track.panning_column_visible=true
        end
      else
        if (vws["ASC_VF_PAN_"..step].value==0) then
          ASC_STEP.PAN[step]=255
        else
          ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
        end      
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_PAN_"..step].value=vws.ASC_VF_PAN_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              if (vws.ASC_VF_PAN_0.value==0) then
                vws["ASC_VF_PAN_"..step].value=0
                ASC_STEP.PAN[step]=255
              else
                vws["ASC_VF_PAN_"..step].value=vws.ASC_VF_PAN_0.value
                ASC_STEP.PAN[step]=vws.ASC_VF_PAN_0.value-1
              end
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
        if (not song.selected_track.panning_column_visible) and (vws.ASC_VF_PAN_0.value~=0) then
          song.selected_track.panning_column_visible=true
        end        
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            if (vws.ASC_VF_PAN_0.value==0) then
              vws["ASC_VF_PAN_"..step].value=0
              ASC_STEP.PAN[step]=255
            else
              vws["ASC_VF_PAN_"..step].value=vws.ASC_VF_PAN_0.value
              ASC_STEP.PAN[step]=vws.ASC_VF_PAN_0.value-1
            end
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
  --print(string.format("write_pan: %.2f ms\n",(os.clock()- x)*1000))
end



local function asc_write_dly(step)
  --local x=os.clock()
  local snc=song.selected_note_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          ASC_STEP.DLY[step]=vws["ASC_VF_DLY_"..step].value
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).delay_value=ASC_STEP.DLY[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
        if (not song.selected_track.delay_column_visible) and (vws["ASC_VF_DLY_"..step].value~=0) then
          song.selected_track.delay_column_visible=true
        end
      else
        ASC_STEP.DLY[step]=vws["ASC_VF_DLY_"..step].value
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_DLY_"..step].value=vws.ASC_VF_DLY_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_DLY_"..step].value=vws.ASC_VF_DLY_0.value
              ASC_STEP.DLY[step]=vws.ASC_VF_DLY_0.value
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).delay_value=ASC_STEP.DLY[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
        if (not song.selected_track.delay_column_visible) and (vws.ASC_VF_DLY_0.value~=0) then
          song.selected_track.delay_column_visible=true
        end
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_VF_DLY_"..step].value=vws.ASC_VF_DLY_0.value
            ASC_STEP.DLY[step]=vws.ASC_VF_DLY_0.value
          end
        end
      end
    end
  ASC_JUMP_LINES=false
  end
  --print(string.format("write_dly: %.2f ms\n",(os.clock()- x)*1000))
end



local function asc_write_sfx_eff(step)
  --print("asc_write_sfx_eff(step)")
  local snc=song.selected_note_column
  local sec=song.selected_effect_column
  if (snc) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          if (vws["ASC_PP_SFX_EFF_"..step].value>19) then
            vws["ASC_PP_SFX_EFF_"..step].value=19
            ASC_JUMP_LINES=false
            return
          end
          ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_number_string=ASC_STEP.SFX_EFF[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
        if (not song.selected_track.sample_effects_column_visible) and (vws["ASC_PP_SFX_EFF_"..step].value~=19) then
          song.selected_track.sample_effects_column_visible=true
        end
      else
        if (vws["ASC_PP_SFX_EFF_"..step].value>19) then
          vws["ASC_PP_SFX_EFF_"..step].value=19
          ASC_JUMP_LINES=false
          return
        end
        ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_PP_SFX_EFF_"..step].value=vws.ASC_PP_SFX_EFF_0.value
            end
          end
        else
          --local sli=song.selected_line_index
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              if (vws.ASC_PP_SFX_EFF_0.value>19) then
                vws.ASC_PP_SFX_EFF_0.value=19
                ASC_JUMP_LINES=false
                return
              end
              vws["ASC_PP_SFX_EFF_"..step].value=vws.ASC_PP_SFX_EFF_0.value
              ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
              if (ASC_STEP.LNE_A[step]<=nol and emod) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_number_string=ASC_STEP.SFX_EFF[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
        if (not song.selected_track.sample_effects_column_visible) and (vws.ASC_PP_SFX_EFF_0.value~=19) then
          song.selected_track.sample_effects_column_visible=true
        end
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            if (vws.ASC_PP_SFX_EFF_0.value>19) then
              vws.ASC_PP_SFX_EFF_0.value=19
              ASC_JUMP_LINES=false
              return
            end
            vws["ASC_PP_SFX_EFF_"..step].value=vws.ASC_PP_SFX_EFF_0.value
            ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
  if (sec) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local seci=song.selected_effect_column_index
    if (step~=0) then
      if (emod) then
        ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
        if (ASC_STEP.LNE_A[step]<=nol) then
          spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).number_string=ASC_STEP.SFX_EFF[step]
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[step]
          end
          asc_show_pattern_editor()
        end
      else
        ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
      end
    else
      if (emod) then
        for step=0,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_PP_SFX_EFF_"..step].value=vws.ASC_PP_SFX_EFF_0.value
            ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            if (ASC_STEP.LNE_A[step]<=nol) then
              spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).number_string=ASC_STEP.SFX_EFF[step]
            end
          end
        end
        if (not ASC_JUMP_LINES) then
          song.selected_line_index=ASC_STEP.LNE_A[1]
        end
        asc_show_pattern_editor()
      else
        for step=0,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_PP_SFX_EFF_"..step].value=vws.ASC_PP_SFX_EFF_0.value
            ASC_STEP.SFX_EFF[step]=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
end



local function asc_write_sfx_amo(step)
  --print("asc_write_sfx_amo(step)")
  local snc=song.selected_note_column
  local sec=song.selected_effect_column
  if (snc) then
    local key_sta=rna.key_modifier_states
        if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snci=song.selected_note_column_index
    if (step~=0) then
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          if (ASC_RESTORE_BYPASS) then asc_write_all(step,true) end
        else
          ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
          if (ASC_STEP.LNE_A[step]<=nol) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_amount_value=ASC_STEP.SFX_AMO[step]
            if (not ASC_JUMP_LINES) then
              song.selected_line_index=ASC_STEP.LNE_A[step]
            end
            asc_show_pattern_editor()
          end
        end
        if (not song.selected_track.sample_effects_column_visible) and (vws["ASC_VF_SFX_AMO_"..step].value~=0) then
          song.selected_track.sample_effects_column_visible=true
        end
      else
        ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
      end
    else
      if (emod) then
        if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_SFX_AMO_"..step].value=vws.ASC_VF_SFX_AMO_0.value
            end
          end
        else
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              vws["ASC_VF_SFX_AMO_"..step].value=vws.ASC_VF_SFX_AMO_0.value
              ASC_STEP.SFX_AMO[step]=vws.ASC_VF_SFX_AMO_0.value
              if (ASC_STEP.LNE_A[step]<=nol) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_amount_value=ASC_STEP.SFX_AMO[step]
              end
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[1]
          end
        end
        asc_show_pattern_editor()
        if (not song.selected_track.sample_effects_column_visible) and (vws.ASC_VF_SFX_AMO_0.value~=0) then
          song.selected_track.sample_effects_column_visible=true
        end
      else
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_VF_SFX_AMO_"..step].value=vws.ASC_VF_SFX_AMO_0.value
            ASC_STEP.SFX_AMO[step]=vws.ASC_VF_SFX_AMO_0.value    
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
  if (sec) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
      (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
      ASC_JUMP_LINES=true
    end
    asc_distribute_lns(1,32)
    local emod=song.transport.edit_mode
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local seci=song.selected_effect_column_index
    if (step~=0) then
      if (emod) then
        ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
        if (ASC_STEP.LNE_A[step]<=nol) then
          spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).amount_value=ASC_STEP.SFX_AMO[step]
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[step]
          end
          asc_show_pattern_editor()
        end
      else
      ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
      end
    else
      if (emod) then
        for step=0,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_VF_SFX_AMO_"..step].value=vws.ASC_VF_SFX_AMO_0.value
            ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
            if (ASC_STEP.LNE_A[step]<=nol) then
              spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).amount_value=ASC_STEP.SFX_AMO[step]
            end
          end
        end
        if (not ASC_JUMP_LINES) then
          song.selected_line_index=ASC_STEP.LNE_A[1]
        end
        asc_show_pattern_editor()
      else
        for step=0,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            vws["ASC_VF_SFX_AMO_"..step].value=vws.ASC_VF_SFX_AMO_0.value
            ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
          end
        end
      end
    end
    ASC_JUMP_LINES=false
  end
end


local function asc_bt_sfx_insert(step)
  --print("asc_bt_sfx_insert(step)")
  local emod=song.transport.edit_mode
  if (emod) then
    local snc=song.selected_note_column
    local sec=song.selected_effect_column
    local nol=song.selected_pattern.number_of_lines
    if (snc) then
      local key_sta=rna.key_modifier_states
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
        (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
        ASC_JUMP_LINES=true
      end
      asc_distribute_lns(1,32)
      local spt=song.selected_pattern_track
      local snci=song.selected_note_column_index
      local function apply_lns(step)
        local a=ASC_STEP.LNE_A[step]+1
        local b=ASC_STEP.LNE_B[step]
        if (step==vws.ASC_VB_STEPS.value) then
          b=nol
        end
        for lne=a,b do
          local nc=spt:line(lne):note_column(snci)
          if (nc.note_value<120) then
            break
          elseif (nc.note_value==120) and (nc.delay_value>0) then
            nc.effect_number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            nc.effect_amount_value=vws["ASC_VF_SFX_AMO_"..step].value
            break
          elseif (nc.note_value==120) then
            break
          else
            nc.effect_number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            nc.effect_amount_value=vws["ASC_VF_SFX_AMO_"..step].value
          end
        end
      end        
      if (step~=0) then
        if (step<=vws.ASC_VB_STEPS.value) then
          apply_lns(step)
        end
        if (not ASC_JUMP_LINES) then
          song.selected_line_index=ASC_STEP.LNE_A[step]
        end
        asc_show_pattern_editor()
      else
        local sli=song.selected_line_index
        for step=1,vws.ASC_VB_STEPS.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            apply_lns(step)
          end
        end
        if (not ASC_JUMP_LINES) then
          song.selected_line_index=sli
        end
        asc_show_pattern_editor()
      end
      ASC_JUMP_LINES=false
    elseif (sec) then
      local key_sta=rna.key_modifier_states
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or --shift
        (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then --control
        ASC_JUMP_LINES=true
      end
      asc_distribute_lns(1,32)
      if (song.selected_track.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
        --print("sec",sec)
        local spt=song.selected_pattern_track
        local seci=song.selected_effect_column_index
        local function apply_lns(step)
          local a=ASC_STEP.LNE_A[step]+1
          local b=ASC_STEP.LNE_B[step]
          if (step==vws.ASC_VB_STEPS.value) then
            b=nol
            if (ASC_STEP.OFF[step]-1<b) and (vws["ASC_VF_OFF_"..step].value~=0) then
              b=ASC_STEP.OFF[step]-1
            end
          end
          for lne=a,b do
            local ec=spt:line(lne):effect_column(seci)
            for clm=1,12 do
              local nc=spt:line(lne):note_column(clm)
              if (nc.note_value==121) then
                ec.number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
                ec.amount_value=vws["ASC_VF_SFX_AMO_"..step].value
              end
            end
          end
        end
        if (step~=0) then
          if (step<=vws.ASC_VB_STEPS.value) then
            apply_lns(step)
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[step]
          end
        else
          local sli=song.selected_line_index
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              apply_lns(step)
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=sli
          end
        end
        asc_show_pattern_editor()
      else
        local spt=song.selected_pattern_track
        local seci=song.selected_effect_column_index
        local function apply_lns(step)
          local a=ASC_STEP.LNE_A[step]+1
          local b=ASC_STEP.LNE_B[step]
          if (step==vws.ASC_VB_STEPS.value) then
            b=nol
          end
          for lne=a,b do
            local ec=spt:line(lne):effect_column(seci)
            ec.number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            ec.amount_value=vws["ASC_VF_SFX_AMO_"..step].value
          end
        end
        if (step~=0) then
          apply_lns(step)
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=ASC_STEP.LNE_A[step]
          end
        else
          local sli=song.selected_line_index
          for step=1,vws.ASC_VB_STEPS.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              apply_lns(step)
            end
          end
          if (not ASC_JUMP_LINES) then
            song.selected_line_index=sli
          end
        end
        asc_show_pattern_editor()
      end
      ASC_JUMP_LINES=false
    end
  end
end



local ASC_RND_TBL={
  NTE={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  INS={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  VOL={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  PAN={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  DLY={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  SFX_AMO={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  },
  LNS={
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true, true,true,true,true,true,true,true,true
  }
}
ASC_RND_TBL.NTE[0]=true
ASC_RND_TBL.INS[0]=true
ASC_RND_TBL.VOL[0]=true
ASC_RND_TBL.PAN[0]=true
ASC_RND_TBL.DLY[0]=true
ASC_RND_TBL.SFX_AMO[0]=true
ASC_RND_TBL.LNS[0]=true



local function asc_restore_values(step)
  local emod=song.transport.edit_mode
  ASC_RESTORE_BYPASS=false
  local snc=song.selected_note_column
  if (step~=0) then
    --note column only
    vws["ASC_VF_VOL_"..step].value=0
    vws["ASC_VF_PAN_"..step].value=0
    vws["ASC_VF_DLY_"..step].value=0
    if (snc) then
      if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.VOL[step]) then asc_write_vol(step) end
      if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.PAN[step]) then asc_write_pan(step) end
      if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.DLY[step]) then asc_write_dly(step) end
    end
    --note column & effect column
    vws["ASC_PP_SFX_EFF_"..step].value=19
    vws["ASC_VF_SFX_AMO_"..step].value=0    
    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS) then asc_write_sfx_eff(step) end
    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.SFX_AMO[step]) then asc_write_sfx_amo(step) end
  else
    for step=vws.ASC_VB_STEPS.value,0,-1 do
      --note column only
      if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) or (step==0) then
        vws["ASC_VF_VOL_"..step].value=0
        vws["ASC_VF_PAN_"..step].value=0
        vws["ASC_VF_DLY_"..step].value=0
        if (snc) then
          if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.VOL[step]) then asc_write_vol(step) end
          if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.PAN[step]) then asc_write_pan(step) end
          if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.DLY[step]) then asc_write_dly(step) end
        end
        --note column & effect column
        vws["ASC_PP_SFX_EFF_"..step].value=19
        vws["ASC_VF_SFX_AMO_"..step].value=0
        if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS) then asc_write_sfx_eff(step) end
        if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.SFX_AMO[step]) then asc_write_sfx_amo(step) end
      end
    end
  end
  ASC_RESTORE_BYPASS=true
  if (emod) then
    if (asc_check_note_column_is_empty()) and (ASC_PREF.auto_insert_first.value) then
      asc_write_all(step,true)
    end
  end
end



local function asc_rnd_select_value_type(value)
  for idx=1,7 do
    if (idx==value) then
      vws["ASC_BT_RND_FILL_DOWN_"..idx].visible=true
      vws["ASC_VB_RND_MIN_"..idx].visible=true
      vws["ASC_VB_RND_MAX_"..idx].visible=true
    else
      vws["ASC_BT_RND_FILL_DOWN_"..idx].visible=false
      vws["ASC_VB_RND_MIN_"..idx].visible=false
      vws["ASC_VB_RND_MAX_"..idx].visible=false
    end
  end
end



local ASC_RND_FILL_DOWN={false,false,false,false,false,false,false}
local function asc_rnd_fill_down_on_off(idx)
  if (ASC_RND_FILL_DOWN[idx]) then
    vws["ASC_BT_RND_FILL_DOWN_"..idx].color=ASC_CLR.DEFAULT
    ASC_RND_FILL_DOWN[idx]=false
    asc_status_bar_on(3000,15,"",0)
  else
    vws["ASC_BT_RND_FILL_DOWN_"..idx].color=ASC_CLR.MARKER
    ASC_RND_FILL_DOWN[idx]=true
    asc_status_bar_on(3000,16,"",0)
  end
end



local function asc_lne(step)
  if (step==0) then
    for step=2,32 do
      vws["ASC_VF_LNS_"..step].value=vws.ASC_VF_LNS_0.value
    end
  end
  asc_write_all(1,true)
end



local function asc_random_values()
  ASC_RANDOM_BYPASS=false
  --print("asc_random_values()")
  local emod=song.transport.edit_mode
  local MATH_RND=math.random
  local sst=song.selected_track
  local spt=song.selected_pattern_track
  local nol=song.selected_pattern.number_of_lines
  local snc=song.selected_note_column
  local sec=song.selected_effect_column
  local key_sta=rna.key_modifier_states
  if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") and not ASC_AUTO_SEQUENCE or
     (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") and not ASC_AUTO_SEQUENCE then
    ASC_JUMP_LINES=true
  end
  asc_distribute_lns(1,32)
  if (snc) then
    local snci=song.selected_note_column_index
    --note
    if (vws.ASC_PP_RND_VALUE.value==1) then
      --1. note random
      if (ASC_CHANGE_RDM_OP["VAL"][1]==1) then
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.NTE[step]=false
            vws["ASC_VB_NTE_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_1.value,vws.ASC_VB_RND_MAX_1.value)
            ASC_STEP.NTE[step]=vws["ASC_VB_NTE_"..step].value
            ASC_RND_TBL.NTE[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).note_value=ASC_STEP.NTE[step]
            end
          end
        end
      --2. note increase
      elseif (ASC_CHANGE_RDM_OP["VAL"][1]==2) then
        local m=math.ceil(vws.ASC_VB_RND_MAX_1.value-vws.ASC_VB_RND_MIN_1.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
        --print("m",m)
        local t={}
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if step==(vws.ASC_VB_RND_STEP_MIN.value) then
            t[step]=vws.ASC_VB_RND_MIN_1.value
          elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
            t[step]=vws.ASC_VB_RND_MAX_1.value
          else
            t[step]=t[step-1]+m
          end
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.NTE[step]=false
            vws["ASC_VB_NTE_"..step].value=t[step]
            ASC_STEP.NTE[step]=t[step]
            ASC_RND_TBL.NTE[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).note_value=ASC_STEP.NTE[step]
            end
          end
        end
      --3. note decrease
      elseif (ASC_CHANGE_RDM_OP["VAL"][1]==3) then
        local m=math.ceil(vws.ASC_VB_RND_MAX_1.value-vws.ASC_VB_RND_MIN_1.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
        --print("m",m)
        local t={}
        for step=vws.ASC_VB_RND_STEP_MAX.value,vws.ASC_VB_RND_STEP_MIN.value,-1 do
          if step==(vws.ASC_VB_RND_STEP_MIN.value) then
            t[step]=vws.ASC_VB_RND_MAX_1.value
          elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
            t[step]=vws.ASC_VB_RND_MIN_1.value
          else
            t[step]=t[step+1]+m
          end
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.NTE[step]=false
            vws["ASC_VB_NTE_"..step].value=t[step]
            ASC_STEP.NTE[step]=t[step]
            ASC_RND_TBL.NTE[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).note_value=ASC_STEP.NTE[step]
            end
          end
        end
      end      
    --instrument
    elseif (vws.ASC_PP_RND_VALUE.value==2) then
      --1. instrument random
      if (ASC_CHANGE_RDM_OP["VAL"][2]==1) then
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.INS[step]=false
            vws["ASC_VF_INS_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_2.value,vws.ASC_VB_RND_MAX_2.value)
            ASC_STEP.INS[step]=vws["ASC_VF_INS_"..step].value
            ASC_RND_TBL.INS[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).instrument_value=ASC_STEP.INS[step]
            end
          end
        end
      end
    --volume
    elseif (vws.ASC_PP_RND_VALUE.value==3) then
      --1. volume random
      if (ASC_CHANGE_RDM_OP["VAL"][3]==1) then
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.VOL[step]=false
            vws["ASC_VF_VOL_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_3.value,vws.ASC_VB_RND_MAX_3.value)+1
            ASC_STEP.VOL[step]=vws["ASC_VF_VOL_"..step].value-1
            ASC_RND_TBL.VOL[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).volume_value=ASC_STEP.VOL[step]
              if (ASC_RND_FILL_DOWN[3]) then
                for lne=ASC_STEP.LNE_A[step]+1,nol do
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.volume_value=MATH_RND(vws.ASC_VB_RND_MIN_3.value,vws.ASC_VB_RND_MAX_3.value)
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.volume_value=MATH_RND(vws.ASC_VB_RND_MIN_3.value,vws.ASC_VB_RND_MAX_3.value)
                  end
                end
              end
            end
          end
        end
      --2. volume increase
      elseif (ASC_CHANGE_RDM_OP["VAL"][3]==2) then
        --------------
        if (not ASC_RND_FILL_DOWN[3]) then
          local m=math.ceil(vws.ASC_VB_RND_MAX_3.value-vws.ASC_VB_RND_MIN_3.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
          --print("m",m)
          local t={}
          for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
            if step==(vws.ASC_VB_RND_STEP_MIN.value) then
              t[step]=vws.ASC_VB_RND_MIN_3.value
            elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
              t[step]=vws.ASC_VB_RND_MAX_3.value
            else
              t[step]=t[step-1]+m
            end
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              ASC_RND_TBL.VOL[step]=false
              vws["ASC_VF_VOL_"..step].value=t[step]
              ASC_STEP.VOL[step]=t[step]
              ASC_RND_TBL.VOL[step]=true
              if (ASC_STEP.LNE_A[step]<=nol and emod) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).volume_value=ASC_STEP.VOL[step]
              end
            end
          end
        else
          for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              local min=ASC_STEP.LNE_A[step]
              local max=ASC_STEP.LNE_B[step]
              if (ASC_STEP.OFF[step]>min) then
                if (ASC_STEP.OFF[step]<max) then
                  max=ASC_STEP.OFF[step]
                elseif (step==vws.ASC_VB_RND_STEP_MAX.value) then
                  max=ASC_STEP.OFF[step]
                end
                if spt:line(max):note_column(snci).delay_value==0 then
                  max=max-1
                end
              end
              local m=math.ceil(vws.ASC_VB_RND_MAX_3.value-vws.ASC_VB_RND_MIN_3.value)/(max-min)
              --print("m",m)
              local t={}
              for lne=min,max do
                if lne==min then
                  t[lne]=vws.ASC_VB_RND_MIN_3.value
                elseif (lne==max) then
                  t[lne]=vws.ASC_VB_RND_MAX_3.value
                else
                  t[lne]=t[lne-1]+m
                end
                if (lne<=nol) then
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120 and lne>min) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.volume_value=t[lne]
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.volume_value=t[lne]
                  end
                end
              end
            end
          end
        end
        --------------
      --3. volume decrease
      elseif (ASC_CHANGE_RDM_OP["VAL"][3]==3) then
        --------------
        if (not ASC_RND_FILL_DOWN[3]) then
          local m=math.ceil(vws.ASC_VB_RND_MAX_3.value-vws.ASC_VB_RND_MIN_3.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
          --print("m",m)
          local t={}
          for step=vws.ASC_VB_RND_STEP_MAX.value,vws.ASC_VB_RND_STEP_MIN.value,-1 do
            if step==(vws.ASC_VB_RND_STEP_MIN.value) then
              t[step]=vws.ASC_VB_RND_MAX_3.value
            elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
              t[step]=vws.ASC_VB_RND_MIN_3.value
            else
              t[step]=t[step+1]+m
            end
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              ASC_RND_TBL.VOL[step]=false
              vws["ASC_VF_VOL_"..step].value=t[step]
              ASC_STEP.VOL[step]=t[step]
              ASC_RND_TBL.VOL[step]=true
              if (ASC_STEP.LNE_A[step]<=nol and emod) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).volume_value=ASC_STEP.VOL[step]
              end
            end
          end
        else
          for step=vws.ASC_VB_RND_STEP_MAX.value,vws.ASC_VB_RND_STEP_MIN.value,-1 do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              local min=ASC_STEP.LNE_A[step]
              local max=ASC_STEP.LNE_B[step]
              if (ASC_STEP.OFF[step]>min) then
                if (ASC_STEP.OFF[step]<max) then
                  max=ASC_STEP.OFF[step]
                elseif (step==vws.ASC_VB_RND_STEP_MAX.value) then
                  max=ASC_STEP.OFF[step]
                end
                if spt:line(max):note_column(snci).delay_value==0 then
                  max=max-1
                end
              end
              local m=math.ceil(vws.ASC_VB_RND_MAX_3.value-vws.ASC_VB_RND_MIN_3.value)/(max-min)
              --print("m",m)
              local t={}
              for lne=max,min,-1 do
                if lne==min then
                  t[lne]=vws.ASC_VB_RND_MAX_3.value
                elseif (lne==max) then
                  t[lne]=vws.ASC_VB_RND_MIN_3.value
                else
                  t[lne]=t[lne+1]+m
                end
                if (lne<=nol) then
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120 and lne>min) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.volume_value=t[lne]
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.volume_value=t[lne]
                  end
                end
              end
            end
          end
        end
        --------------
      end
      if (not sst.volume_column_visible and emod) then
        sst.volume_column_visible=true
      end
    --[[
    --panning
    elseif (vws.ASC_PP_RND_VALUE.value==4) then
      for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          ASC_RND_TBL.PAN[step]=false
          vws["ASC_VF_PAN_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)+1
          ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
          ASC_RND_TBL.PAN[step]=true
          if (ASC_STEP.LNE_A[step]<=nol and emod) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
            if (ASC_RND_FILL_DOWN[4]) then
              for lne=ASC_STEP.LNE_A[step]+1,nol do
                local nc=spt:line(lne):note_column(snci)
                if (nc.note_value<120) then
                  break
                elseif (nc.note_value==120) and (nc.delay_value>0) then
                  nc.panning_value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)
                  break
                elseif (nc.note_value==120) then
                  break
                else
                  nc.panning_value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)
                end
              end
            end
          end
        end
      end
      if (not sst.panning_column_visible and emod) then
        sst.panning_column_visible=true
      end
    ]]
    
    
    
    
    
        --panning
    elseif (vws.ASC_PP_RND_VALUE.value==4) then
      --1. panning random
      if (ASC_CHANGE_RDM_OP["VAL"][4]==1) then
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.PAN[step]=false
            vws["ASC_VF_PAN_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)+1
            ASC_STEP.PAN[step]=vws["ASC_VF_PAN_"..step].value-1
            ASC_RND_TBL.PAN[step]=true
            if (ASC_STEP.LNE_A[step]<=nol and emod) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
              if (ASC_RND_FILL_DOWN[3]) then
                for lne=ASC_STEP.LNE_A[step]+1,nol do
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.panning_value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.panning_value=MATH_RND(vws.ASC_VB_RND_MIN_4.value,vws.ASC_VB_RND_MAX_4.value)
                  end
                end
              end
            end
          end
        end
      --2. panning increase
      elseif (ASC_CHANGE_RDM_OP["VAL"][4]==2) then
        --------------
        if (not ASC_RND_FILL_DOWN[4]) then
          local m=math.ceil(vws.ASC_VB_RND_MAX_4.value-vws.ASC_VB_RND_MIN_4.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
          --print("m",m)
          local t={}
          for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
            if step==(vws.ASC_VB_RND_STEP_MIN.value) then
              t[step]=vws.ASC_VB_RND_MIN_4.value
            elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
              t[step]=vws.ASC_VB_RND_MAX_4.value
            else
              t[step]=t[step-1]+m
            end
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              ASC_RND_TBL.PAN[step]=false
              vws["ASC_VF_PAN_"..step].value=t[step]
              ASC_STEP.PAN[step]=t[step]
              ASC_RND_TBL.PAN[step]=true
              if (ASC_STEP.LNE_A[step]<=nol and emod) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
              end
            end
          end
        else
          for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              local min=ASC_STEP.LNE_A[step]
              local max=ASC_STEP.LNE_B[step]
              if (ASC_STEP.OFF[step]>min) then
                if (ASC_STEP.OFF[step]<max) then
                  max=ASC_STEP.OFF[step]
                elseif (step==vws.ASC_VB_RND_STEP_MAX.value) then
                  max=ASC_STEP.OFF[step]
                end
                if spt:line(max):note_column(snci).delay_value==0 then
                  max=max-1
                end
              end
              local m=math.ceil(vws.ASC_VB_RND_MAX_4.value-vws.ASC_VB_RND_MIN_4.value)/(max-min)
              --print("m",m)
              local t={}
              for lne=min,max do
                if lne==min then
                  t[lne]=vws.ASC_VB_RND_MIN_4.value
                elseif (lne==max) then
                  t[lne]=vws.ASC_VB_RND_MAX_4.value
                else
                  t[lne]=t[lne-1]+m
                end
                if (lne<=nol) then
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120 and lne>min) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.panning_value=t[lne]
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.panning_value=t[lne]
                  end
                end
              end
            end
          end
        end
        --------------
      --3. volume decrease
      elseif (ASC_CHANGE_RDM_OP["VAL"][4]==3) then
        --------------
        if (not ASC_RND_FILL_DOWN[4]) then
          local m=math.ceil(vws.ASC_VB_RND_MAX_4.value-vws.ASC_VB_RND_MIN_4.value)/(vws.ASC_VB_RND_STEP_MAX.value-vws.ASC_VB_RND_STEP_MIN.value)
          --print("m",m)
          local t={}
          for step=vws.ASC_VB_RND_STEP_MAX.value,vws.ASC_VB_RND_STEP_MIN.value,-1 do
            if step==(vws.ASC_VB_RND_STEP_MIN.value) then
              t[step]=vws.ASC_VB_RND_MAX_4.value
            elseif step==(vws.ASC_VB_RND_STEP_MAX.value) then
              t[step]=vws.ASC_VB_RND_MIN_4.value
            else
              t[step]=t[step+1]+m
            end
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              ASC_RND_TBL.PAN[step]=false
              vws["ASC_VF_PAN_"..step].value=t[step]
              ASC_STEP.PAN[step]=t[step]
              ASC_RND_TBL.PAN[step]=true
              if (ASC_STEP.LNE_A[step]<=nol and emod) then
                spt:line(ASC_STEP.LNE_A[step]):note_column(snci).panning_value=ASC_STEP.PAN[step]
              end
            end
          end
        else
          for step=vws.ASC_VB_RND_STEP_MAX.value,vws.ASC_VB_RND_STEP_MIN.value,-1 do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              local min=ASC_STEP.LNE_A[step]
              local max=ASC_STEP.LNE_B[step]
              if (ASC_STEP.OFF[step]>min) then
                if (ASC_STEP.OFF[step]<max) then
                  max=ASC_STEP.OFF[step]
                elseif (step==vws.ASC_VB_RND_STEP_MAX.value) then
                  max=ASC_STEP.OFF[step]
                end
                if spt:line(max):note_column(snci).delay_value==0 then
                  max=max-1
                end
              end
              local m=math.ceil(vws.ASC_VB_RND_MAX_4.value-vws.ASC_VB_RND_MIN_4.value)/(max-min)
              --print("m",m)
              local t={}
              for lne=max,min,-1 do
                if lne==min then
                  t[lne]=vws.ASC_VB_RND_MAX_4.value
                elseif (lne==max) then
                  t[lne]=vws.ASC_VB_RND_MIN_4.value
                else
                  t[lne]=t[lne+1]+m
                end
                if (lne<=nol) then
                  local nc=spt:line(lne):note_column(snci)
                  if (nc.note_value<120 and lne>min) then
                    break
                  elseif (nc.note_value==120) and (nc.delay_value>0) then
                    nc.panning_value=t[lne]
                    break
                  elseif (nc.note_value==120) then
                    break
                  else
                    nc.panning_value=t[lne]
                  end
                end
              end
            end
          end
        end
        --------------
      end
      if (not sst.panning_column_visible and emod) then
        sst.panning_column_visible=true
      end
    
    
    
    --delay
    elseif (vws.ASC_PP_RND_VALUE.value==5) then
      for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          ASC_RND_TBL.DLY[step]=false
          vws["ASC_VF_DLY_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_5.value,vws.ASC_VB_RND_MAX_5.value)
          ASC_STEP.DLY[step]=vws["ASC_VF_DLY_"..step].value
          ASC_RND_TBL.DLY[step]=true
          if (ASC_STEP.LNE_A[step]<=nol and emod) then
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).delay_value=ASC_STEP.DLY[step]
            if (ASC_RND_FILL_DOWN[5]) then
              local a=ASC_STEP.LNE_A[step]+1
              local b=ASC_STEP.LNE_B[step]
              if (step==vws.ASC_VB_RND_STEP_MAX.value) then
                b=nol
              end
              for lne=a,b do
                local nc=spt:line(lne):note_column(snci)
                if (nc.note_value<120) then
                  break
                elseif (nc.note_value==120) then
                  nc.delay_value=MATH_RND(vws.ASC_VB_RND_MIN_5.value,vws.ASC_VB_RND_MAX_5.value)
                  break
                end
              end
            end
          end
        end
      end
      if (not sst.delay_column_visible and emod) then
        sst.delay_column_visible=true
      end
    --fx amount
    elseif (vws.ASC_PP_RND_VALUE.value==6) then
      for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          ASC_RND_TBL.SFX_AMO[step]=false
          vws["ASC_VF_SFX_AMO_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_6.value,vws.ASC_VB_RND_MAX_6.value)
          ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
          ASC_RND_TBL.SFX_AMO[step]=true
          if (vws["ASC_PP_SFX_EFF_"..step].value>19) then
            vws["ASC_PP_SFX_EFF_"..step].value=19
          end
          if (ASC_STEP.LNE_A[step]<=nol and emod) then
            if (ASC_PREF.random_fx_param.value) then
              spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            end
            spt:line(ASC_STEP.LNE_A[step]):note_column(snci).effect_amount_value=ASC_STEP.SFX_AMO[step]
            if (ASC_RND_FILL_DOWN[6]) then
              for lne=ASC_STEP.LNE_A[step]+1,ASC_STEP.LNE_B[step] do
                local nc=spt:line(lne):note_column(snci)
                if (nc.note_value<120) then
                  break
                elseif (nc.note_value==120) and (nc.delay_value>0) then
                  if (ASC_PREF.random_fx_param.value) then
                    nc.effect_number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
                  end                  
                  nc.effect_amount_value=MATH_RND(vws.ASC_VB_RND_MIN_6.value,vws.ASC_VB_RND_MAX_6.value)
                  break
                elseif (nc.note_value==120) then
                  break
                else
                  if (ASC_PREF.random_fx_param.value) then
                    nc.effect_number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
                  end
                  nc.effect_amount_value=MATH_RND(vws.ASC_VB_RND_MIN_6.value,vws.ASC_VB_RND_MAX_6.value)
                end
              end
            end
          end
        end
      end
      if (not sst.sample_effects_column_visible and emod) then
        sst.sample_effects_column_visible=true
      end
    --lines
    elseif (vws.ASC_PP_RND_VALUE.value==7) then
      ASC_RANDOM_LINES=true
      if (not ASC_PREF.random_lines.value) then
        --distribute
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
            ASC_RND_TBL.LNS[step]=false
            vws["ASC_VF_LNS_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_7.value,vws.ASC_VB_RND_MAX_7.value)
            ASC_RND_TBL.LNS[step]=true
            asc_lne(step)
          end
        end
      else
        local sli=song.selected_line_index
        local snci=song.selected_note_column_index
        local lne_tbl={}
        for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
          lne_tbl[step]=MATH_RND(vws.ASC_VB_RND_MIN_7.value,vws.ASC_VB_RND_MAX_7.value)
        end
        local function distribute_lines_all_nc(c)
          --select note column
          song.selected_note_column_index=c
          --import
            asc_import_nc(vws.ASC_VB_RND_STEP_MAX.value)          
          --distribute
          for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
            if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
              ASC_RND_TBL.LNS[step]=false
              vws["ASC_VF_LNS_"..step].value=lne_tbl[step]
              ASC_RND_TBL.LNS[step]=true
              asc_lne(step)              
            end
          end
        end
        --- ---
        for c=1,song.selected_track.visible_note_columns do
          distribute_lines_all_nc(c)
        end
        song.selected_note_column_index=snci
        asc_import_nc(vws.ASC_VB_RND_STEP_MAX.value)
      end
      ASC_RANDOM_LINES=false
    end
    if (emod) then
      if (ASC_STEP.LNE_A[vws.ASC_VB_RND_STEP_MIN.value]<=nol) then
        if (ASC_JUMP_LINES) then
          --song.selected_line_index=ASC_STEP.LNE_A[1]
        else
          song.selected_line_index=ASC_STEP.LNE_A[vws.ASC_VB_RND_STEP_MIN.value]
        end
      else
        song.selected_line_index=nol
      end
    end
  end
  if (sec) then
    -- --
    if (vws.ASC_PP_RND_VALUE.value==6) then
      local seci=song.selected_effect_column_index
      for step=vws.ASC_VB_RND_STEP_MIN.value,vws.ASC_VB_RND_STEP_MAX.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          ASC_RND_TBL.SFX_AMO[step]=false
          vws["ASC_VF_SFX_AMO_"..step].value=MATH_RND(vws.ASC_VB_RND_MIN_6.value,vws.ASC_VB_RND_MAX_6.value)
          ASC_STEP.SFX_AMO[step]=vws["ASC_VF_SFX_AMO_"..step].value
          ASC_RND_TBL.SFX_AMO[step]=true
          if (ASC_STEP.LNE_A[step]<=nol and emod) then
            if (ASC_PREF.random_fx_param.value) then
              spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
            end
            spt:line(ASC_STEP.LNE_A[step]):effect_column(seci).amount_value=ASC_STEP.SFX_AMO[step]
            if (ASC_RND_FILL_DOWN[6]) then
              for lne=ASC_STEP.LNE_A[step]+1,ASC_STEP.LNE_B[step] do
                local ec=spt:line(lne):effect_column(seci)
                if (ASC_PREF.random_fx_param.value) then
                  ec.number_string=ASC_SFX_EF2[vws["ASC_PP_SFX_EFF_"..step].value]
                end
                ec.amount_value=MATH_RND(vws.ASC_VB_RND_MIN_6.value,vws.ASC_VB_RND_MAX_6.value)
              end
            end
          end
        end
      end      
    end
    -- --
  end
  if(key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
    asc_write_all(1,true)
  end
  ASC_JUMP_LINES=false
  ASC_RANDOM_BYPASS=true
end



local function asc_off(step)
  if (song.transport.edit_mode) then
    local key_sta=rna.key_modifier_states
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or
       (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
      ASC_JUMP_LINES=true
    end
    local nol=song.selected_pattern.number_of_lines
    local spt=song.selected_pattern_track
    local snc=song.selected_note_column
    local snci=song.selected_note_column_index
    if (snc) then
      if (step<vws.ASC_VB_STEPS.value) then
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) and (ASC_STEP.OFF[step]<=ASC_STEP.LNE_B[step]) and (ASC_STEP.OFF[step]<=nol) then
          --first clear current note-off line
          local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
          if (nc_off.note_value==120) then
            nc_off:clear()
          end
        end
        --distribute lines and clear bottom
        asc_distribute_lns(step,step)
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) then
          for lne=ASC_STEP.OFF[step],ASC_STEP.LNE_B[step] do
            if (lne<=nol) then
              if not spt:line(lne):note_column(snci).is_empty then
                spt:line(lne):note_column(snci):clear()
              end
            end
          end
        end
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) and (ASC_STEP.OFF[step]<=ASC_STEP.LNE_B[step]) and (ASC_STEP.OFF[step]<=nol) then
          --insert new note-off
          local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
          nc_off.note_value=120
        end
      elseif (step==vws.ASC_VB_STEPS.value) then
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) and (ASC_STEP.OFF[step]<=nol) then
          --first clear current note-off line
          local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
          if (nc_off.note_value==120) then
            nc_off:clear()
          end
        end
        --distribute lines and clear bottom
        asc_distribute_lns(step,step)
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) then
          for lne=ASC_STEP.OFF[step],nol do
            if not spt:line(lne):note_column(snci).is_empty then
              spt:line(lne):note_column(snci):clear()
            end
          end
        end
        if (ASC_STEP.OFF[step]>ASC_STEP.LNE_A[step]) and (ASC_STEP.OFF[step]<=nol) then
          --insert new note-off
          local nc_off=spt:line(ASC_STEP.OFF[step]):note_column(snci)
          nc_off.note_value=120
        end
      end
    end
    ASC_JUMP_LINES=false
    asc_show_pattern_editor()
  end
end

local function asc_in_off(step)
  local nol=song.selected_pattern.number_of_lines
  local key_sta=rna.key_modifier_states
  if (step~=0) then
    asc_off(step)
    asc_jump_step(step,nol)
  else
    for step=1,32 do
      vws["ASC_VF_OFF_"..step].value=vws.ASC_VF_OFF_0.value
      asc_off(step)
    end
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
      asc_jump_step(1,nol)
    end
  end
end

local ASC_UP_OFF=0
local function asc_up_off()
  local step=ASC_UP_OFF
  local nol=song.selected_pattern.number_of_lines
  local key_sta=rna.key_modifier_states
  ASC_WRITE_ALL_BYPASS=false
  if (step~=0) then
    if (vws["ASC_VF_OFF_"..step].value>0) then
      vws["ASC_VF_OFF_"..step].value=vws["ASC_VF_OFF_"..step].value-1
      asc_off(step)
      asc_jump_step(step,nol)
    end
  else
    if (vws.ASC_VF_OFF_0.value>0) then
      vws.ASC_VF_OFF_0.value=vws.ASC_VF_OFF_0.value-1
      for step=1,32 do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_OFF_"..step].value=vws.ASC_VF_OFF_0.value
          asc_off(step)
        end
      end
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
        asc_jump_step(1,nol)
      end
    end
  end
  ASC_WRITE_ALL_BYPASS=true
end

local ASC_DOWN_OFF=0
local function asc_down_off()
  local step=ASC_DOWN_OFF
  local nol=song.selected_pattern.number_of_lines
  local key_sta=rna.key_modifier_states
  ASC_WRITE_ALL_BYPASS=false
  if (step~=0) then
    if (vws["ASC_VF_OFF_"..step].value<vws["ASC_VF_OFF_"..step].max) then
      vws["ASC_VF_OFF_"..step].value=vws["ASC_VF_OFF_"..step].value+1
      asc_off(step)
      asc_jump_step(step,nol)
    end
  else
    if (vws.ASC_VF_OFF_0.value<vws.ASC_VF_OFF_0.max) then
      vws.ASC_VF_OFF_0.value=vws.ASC_VF_OFF_0.value+1
      for step=1,32 do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_OFF_"..step].value=vws.ASC_VF_OFF_0.value
          asc_off(step)
        end
      end
      if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
        asc_jump_step(1,nol)
      end
    end
  end
  ASC_WRITE_ALL_BYPASS=true
end

function asc_up_off_repeat(release)
  if not release then
    if rnt:has_timer(asc_up_off_repeat) then
      rnt:remove_timer(asc_up_off_repeat)
      if not (rnt:has_timer(asc_up_off)) then
        rnt:add_timer(asc_up_off,40)
      end
    else
      if rnt:has_timer(asc_up_off_repeat) then
        rnt:remove_timer(asc_up_off_repeat)
      elseif rnt:has_timer(asc_up_off) then
        rnt:remove_timer(asc_up_off)
      end
      asc_up_off()
      rnt:add_timer(asc_up_off_repeat,300)
    end
  else
    if rnt:has_timer(asc_up_off_repeat) then
      rnt:remove_timer(asc_up_off_repeat)
    elseif rnt:has_timer(asc_up_off) then
      rnt:remove_timer(asc_up_off)
    end
  end
end

function asc_down_off_repeat(release)
  if not release then
    if rnt:has_timer(asc_down_off_repeat) then
      rnt:remove_timer(asc_down_off_repeat)
      if not (rnt:has_timer(asc_down_off)) then
        rnt:add_timer(asc_down_off,40)
      end
    else
      if rnt:has_timer(asc_down_off_repeat) then
        rnt:remove_timer(asc_down_off_repeat)
      elseif rnt:has_timer(asc_down_off) then
        rnt:remove_timer(asc_down_off)
      end
      asc_down_off()
      rnt:add_timer(asc_down_off_repeat,300)
    end
  else
    if rnt:has_timer(asc_down_off_repeat) then
      rnt:remove_timer(asc_down_off_repeat)
    elseif rnt:has_timer(asc_down_off) then
      rnt:remove_timer(asc_down_off)
    end
  end
end



local ASC_UP_LNE=0
local function asc_up_lne()
  local key_sta=rna.key_modifier_states
  ASC_WRITE_ALL_BYPASS=false
  local function up(step,insert)
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") or
       (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or
       (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
      ASC_UP_DOWN_BYPASS=false
      asc_write_all(step,insert)
      ASC_UP_DOWN_BYPASS=true
    end
  end
  if (ASC_UP_LNE~=0) then
    if (vws["ASC_VF_LNS_"..ASC_UP_LNE].value>1) then
      vws["ASC_VF_LNS_"..ASC_UP_LNE].value=vws["ASC_VF_LNS_"..ASC_UP_LNE].value-1
    end
    up(ASC_UP_LNE,true)
  else
    if (vws.ASC_VF_LNS_0.value>1) then
      vws.ASC_VF_LNS_0.value=vws.ASC_VF_LNS_0.value-1
      for step=vws.ASC_VB_STEPS.value,1,-1 do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_LNS_"..step].value=vws.ASC_VF_LNS_0.value
        end
        up(step,false)
      end
      up(0,true)
    end
  end
  ASC_WRITE_ALL_BYPASS=true
end

local ASC_DOWN_LNE=0
local function asc_down_lne()
  local key_sta=rna.key_modifier_states
  ASC_WRITE_ALL_BYPASS=false
  local function down(step,insert)
    if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") or
       (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="pressed") or
       (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
      ASC_UP_DOWN_BYPASS=false
      asc_write_all(step,insert)
      ASC_UP_DOWN_BYPASS=true
    end
  end
  if (ASC_DOWN_LNE~=0) then
    if (vws["ASC_VF_LNS_"..ASC_DOWN_LNE].value<vws["ASC_VF_LNS_"..ASC_DOWN_LNE].max) then
      vws["ASC_VF_LNS_"..ASC_DOWN_LNE].value=vws["ASC_VF_LNS_"..ASC_DOWN_LNE].value+1
    end
    down(ASC_DOWN_LNE,true)
  else
    if (vws.ASC_VF_LNS_0.value<vws.ASC_VF_LNS_0.max) then
      vws.ASC_VF_LNS_0.value=vws.ASC_VF_LNS_0.value+1
      for step=vws.ASC_VB_STEPS.value,1,-1 do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_LNS_"..step].value=vws.ASC_VF_LNS_0.value
        end
        down(step,false)
      end
      down(0,true)
    end
  end
  ASC_WRITE_ALL_BYPASS=true
end

function asc_up_lne_repeat(release)
  if not release then
    if rnt:has_timer(asc_up_lne_repeat) then
      rnt:remove_timer(asc_up_lne_repeat)
      if not (rnt:has_timer(asc_up_lne)) then
        rnt:add_timer(asc_up_lne,40)
      end
    else
      if rnt:has_timer(asc_up_lne_repeat) then
        rnt:remove_timer(asc_up_lne_repeat)
      elseif rnt:has_timer(asc_up_lne) then
        rnt:remove_timer(asc_up_lne)
      end
      asc_up_lne()
      rnt:add_timer(asc_up_lne_repeat,300)
    end
  else
    if rnt:has_timer(asc_up_lne_repeat) then
      rnt:remove_timer(asc_up_lne_repeat)
    elseif rnt:has_timer(asc_up_lne) then
      rnt:remove_timer(asc_up_lne)
    end
  end
end

function asc_down_lne_repeat(release)
  if not release then
    if rnt:has_timer(asc_down_lne_repeat) then
      rnt:remove_timer(asc_down_lne_repeat)
      if not (rnt:has_timer(asc_down_lne)) then
        rnt:add_timer(asc_down_lne,40)
      end
    else
      if rnt:has_timer(asc_down_lne_repeat) then
        rnt:remove_timer(asc_down_lne_repeat)
      elseif rnt:has_timer(asc_down_lne) then
        rnt:remove_timer(asc_down_lne)
      end
      asc_down_lne()
      rnt:add_timer(asc_down_lne_repeat,300)
    end
  else
    if rnt:has_timer(asc_down_lne_repeat) then
      rnt:remove_timer(asc_down_lne_repeat)
    elseif rnt:has_timer(asc_down_lne) then
      rnt:remove_timer(asc_down_lne)
    end
  end
end



--start line
local function asc_up_start_lne()
  if (vws.ASC_VF_START_LNE.value>1) then
    vws.ASC_VF_START_LNE.value=vws.ASC_VF_START_LNE.value-1
  end
  asc_write_all(1,true)
end

local function asc_down_start_lne()
  if (vws.ASC_VF_START_LNE.value<vws.ASC_VF_START_LNE.max) then
    vws.ASC_VF_START_LNE.value=vws.ASC_VF_START_LNE.value+1
  end
  asc_write_all(1,true)
end


local function asc_up_start_lne_repeat(release)
  if not release then
    if rnt:has_timer(asc_up_start_lne_repeat) then
      rnt:remove_timer(asc_up_start_lne_repeat)
      if not (rnt:has_timer(asc_up_start_lne)) then
        rnt:add_timer(asc_up_start_lne,40)
      end
    else
      if rnt:has_timer(asc_up_start_lne_repeat) then
        rnt:remove_timer(asc_up_start_lne_repeat)
      elseif rnt:has_timer(asc_up_start_lne) then
        rnt:remove_timer(asc_up_start_lne)
      end
      asc_up_start_lne()
      rnt:add_timer(asc_up_start_lne_repeat,300)
    end
  else
    if rnt:has_timer(asc_up_start_lne_repeat) then
      rnt:remove_timer(asc_up_start_lne_repeat)
    elseif rnt:has_timer(asc_up_start_lne) then
      rnt:remove_timer(asc_up_start_lne)
    end
  end
end

local function asc_down_start_lne_repeat(release)
  if not release then
    if rnt:has_timer(asc_down_start_lne_repeat) then
      rnt:remove_timer(asc_down_start_lne_repeat)
      if not (rnt:has_timer(asc_down_start_lne)) then
        rnt:add_timer(asc_down_start_lne,40)
      end
    else
      if rnt:has_timer(asc_down_start_lne_repeat) then
        rnt:remove_timer(asc_down_start_lne_repeat)
      elseif rnt:has_timer(asc_down_start_lne) then
        rnt:remove_timer(asc_down_start_lne)
      end
      asc_down_start_lne()
      rnt:add_timer(asc_down_start_lne_repeat,300)
    end
  else
    if rnt:has_timer(asc_down_start_lne_repeat) then
      rnt:remove_timer(asc_down_start_lne_repeat)
    elseif rnt:has_timer(asc_down_start_lne) then
      rnt:remove_timer(asc_down_start_lne)
    end
  end
end



local ASC_RND_SHOW=false
local ASC_RND_SHOW_IN_RACK=2

--permute random rack 1 or 2
local function asc_permute_rnd_rack(value)
  if (ASC_RND_SHOW) then
    if (value>7) then
      vws.ASC_RACK_2.visible=false
      vws.ASC_RACK_1.visible=true
      if (ASC_RND_SHOW_IN_RACK==1) then
        vws.ASC_RACK_2:remove_child(vws.ASC_CL_PANEL_2)
        vws.ASC_RACK_1:add_child(vws.ASC_CL_PANEL_2)
        ASC_RND_SHOW_IN_RACK=2
      end
    else
      vws.ASC_RACK_1.visible=false
      vws.ASC_RACK_2.visible=true
      if (ASC_RND_SHOW_IN_RACK==2) then
        vws.ASC_RACK_1:remove_child(vws.ASC_CL_PANEL_2)
        vws.ASC_RACK_2:add_child(vws.ASC_CL_PANEL_2)
        ASC_RND_SHOW_IN_RACK=1
      end
    end
  else
    vws.ASC_RACK_2.visible=false
    vws.ASC_RACK_1.visible=false
  end
end



local function asc_add_sel_01_16()
  local rw=vb:row{
    id="ASC_ADD_SEL_01_16",
    spacing=-3
  }
  for step=1,16 do
    rw:add_child(Asc_Step_Sel(step).cnt)
    if step==8 then
      rw:add_child(vb:space{width=4})
    end
  end
  rw:add_child(
    vb:space{
      id="ASC_ADD_SEL_01_16_SEP",
      width=11
    }
  )
  return rw
end



local function asc_add_sel_17_32()
  local rw=vb:row{
    id="ASC_ADD_SEL_17_32",
    spacing=-3
  }
  for step=17,32 do
    rw:add_child(Asc_Step_Sel(step).cnt)
    if step==24 then
      rw:add_child(vb:space{width=4})
    end
  end
  return rw
end



local ASC_STEP_SEL=1
local function asc_permute_sel_rack(value)
  if (value>7) then
    if (ASC_STEP_SEL==2) then
      vws.ASC_RACK_17_32:remove_child(vws.ASC_ADD_SEL_17_32)
      vws.ASC_RACK_01_16:add_child(vws.ASC_ADD_SEL_17_32)
      vws.ASC_ADD_SEL_01_16_SEP.visible=true
      vws.ASC_SUBRACK_3.height=ASC_VB_HEIGHT_2
      ASC_STEP_SEL=1
    end
  else
    if (ASC_STEP_SEL==1) then
      vws.ASC_RACK_01_16:remove_child(vws.ASC_ADD_SEL_17_32)
      vws.ASC_RACK_17_32:add_child(vws.ASC_ADD_SEL_17_32)
      vws.ASC_ADD_SEL_01_16_SEP.visible=false
      ASC_STEP_SEL=2
    end
  end
end



--show info panel
local ASC_RND_SHOW_STATE=false
local ASC_COMPACT=false
local function asc_info_panel()
  if (vws.ASC_CL_PANEL_3.visible) then
    vws.ASC_CL_PANEL_3.visible=false
    vws.ASC_CL_PANEL_1.visible=true
    vws.ASC_BT_INFO.color=ASC_CLR.DEFAULT
    if (vws.ASC_PP_SELECT.value~=1 and vws.ASC_PP_SELECT.value~=5) then
      if not (vws.ASC_RACK_3.visible) then
        vws.ASC_RACK_3.visible=true
      end
    end
    if (ASC_RND_SHOW_STATE) then
      vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.MARKER
      vws.ASC_CL_PANEL_2.visible=true
      ASC_RND_SHOW=true
      asc_permute_rnd_rack(vws.ASC_VB_STEPS.value)
      ASC_RND_SHOW_STATE=false
    end
  else
    vws.ASC_CL_PANEL_1.visible=false
    vws.ASC_CL_PANEL_3.visible=true
    vws.ASC_BT_INFO.color=ASC_CLR.MARKER
    if (vws.ASC_RACK_3.visible) then
      vws.ASC_RACK_3.visible=false
    end
    if (ASC_RND_SHOW) then
      ASC_RND_SHOW_STATE=true
      vws.ASC_CL_PANEL_2.visible=false
      vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.DEFAULT
      ASC_RND_SHOW=false
      vws.ASC_RACK_2.visible=false
      vws.ASC_RACK_1.visible=false
    end
    if (ASC_COMPACT) then
      vws.ASC_BT_COMPACT.color=ASC_CLR.DEFAULT
      ASC_COMPACT=false
    end
  end
end



--show random panel
local function asc_show_rdm_pnl()
  if (ASC_RND_SHOW) then
    vws.ASC_CL_PANEL_2.visible=false
    vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.DEFAULT
    ASC_RND_SHOW=false
  else
    vws.ASC_CL_PANEL_2.visible=true
    vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.MARKER
    ASC_RND_SHOW=true
  end
  if (ASC_COMPACT) then
    asc_permute_rnd_rack(4)
  else
    asc_permute_rnd_rack(vws.ASC_VB_STEPS.value)
  end
  if (vws.ASC_CL_PANEL_3.visible) then asc_info_panel() end
end



--change random operation
ASC_CHANGE_RDM_OP={VAL={1,1,1,1,1,1,1},MAX={3,1,3,3,3,3,1}} --VAL is variable, MAX is fixed
local function asc_update_rdm_ico(val)
  if (val==1) then vws.ASC_BP_RND_ICO.bitmap="ico/random_ico.png"           vws.ASC_BT_SHOW_RANDOM_PNL.bitmap="ico/random_ico.png" end
  if (val==2) then vws.ASC_BP_RND_ICO.bitmap="ico/linear_increment_ico.png" vws.ASC_BT_SHOW_RANDOM_PNL.bitmap="ico/linear_increment_ico.png" end
  if (val==3) then vws.ASC_BP_RND_ICO.bitmap="ico/linear_decrement_ico.png" vws.ASC_BT_SHOW_RANDOM_PNL.bitmap="ico/linear_decrement_ico.png" end
end


local function asc_change_rdm_op()
  local val=vws.ASC_PP_RND_VALUE.value
  local function change_val(val)
    for o=1,ASC_CHANGE_RDM_OP["MAX"][val] do
      if (o==ASC_CHANGE_RDM_OP["VAL"][val]) then
        if (o==ASC_CHANGE_RDM_OP["MAX"][val]) then
          ASC_CHANGE_RDM_OP["VAL"][val]=1
          break
        else
          ASC_CHANGE_RDM_OP["VAL"][val]=ASC_CHANGE_RDM_OP["VAL"][val]+1
          break
        end
      end
    end
    --print(ASC_CHANGE_RDM_OP["VAL"][val])
    asc_update_rdm_ico(ASC_CHANGE_RDM_OP["VAL"][val])
  end
  if (val==1) then
    change_val(val)
  elseif (val==2) then
    change_val(val)
  elseif (val==3) then
    change_val(val)
  elseif (val==4) then
    change_val(val)
  elseif (val==5) then
    change_val(val)
  elseif (val==6) then
    change_val(val)
  elseif (val==7) then
    change_val(val)
  end
end






--compact
local function asc_compact()
  if (ASC_COMPACT) then
    vws.ASC_CL_PANEL_1.visible=true
    vws.ASC_BT_COMPACT.bitmap="ico/compact_on_ico.png"
    vws.ASC_BT_COMPACT.color=ASC_CLR.DEFAULT
    asc_permute_rnd_rack(vws.ASC_VB_STEPS.value)
    asc_permute_sel_rack(vws.ASC_VB_STEPS.value)
    ASC_COMPACT=false
  else
    if (vws.ASC_CL_PANEL_3.visible) then
      vws.ASC_CL_PANEL_3.visible=false
      vws.ASC_BT_INFO.color=ASC_CLR.DEFAULT
    end
    vws.ASC_CL_PANEL_1.visible=false
    vws.ASC_BT_COMPACT.bitmap="ico/compact_off_ico.png"
    vws.ASC_BT_COMPACT.color=ASC_CLR.MARKER
    asc_permute_sel_rack(4)
    if (ASC_RND_SHOW) then
      asc_permute_rnd_rack(4)
    end
    ASC_COMPACT=true
    if (ASC_RND_SHOW_STATE) then
      vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.MARKER
      vws.ASC_CL_PANEL_2.visible=true
      ASC_RND_SHOW=true
      asc_permute_rnd_rack(4)
      ASC_RND_SHOW_STATE=false
    end
    if (vws.ASC_PP_SELECT.value~=1 and vws.ASC_PP_SELECT.value~=5) then
      if not (vws.ASC_RACK_3.visible) then
        vws.ASC_RACK_3.visible=true
      end
    end
  end
end



local function asc_step_active(step,bol)
  --vws["ASC_TX_STEP_NAME_"..step].active=bol
  --vws["ASC_MP_JUMP_STEP_"..step].active=bol
  
  vws["ASC_BT_INS_DOWN_"..step].active=bol
  vws["ASC_BT_INS_UP_"..step].active=bol
  vws["ASC_VF_INS_"..step].active=bol
  
  vws["ASC_VB_NTE_"..step].active=bol
  vws["ASC_PP_SFX_EFF_"..step].active=bol
  vws["ASC_BT_VAL_EMPTY_"..step].active=bol
  
  vws["ASC_BT_OFF_UP_"..step].active=bol
  vws["ASC_VF_OFF_"..step].active=bol
  vws["ASC_BT_OFF_DOWN_"..step].active=bol
  
  vws["ASC_BT_LNS_UP_"..step].active=bol
  vws["ASC_VF_LNS_"..step].active=bol
  vws["ASC_BT_LNS_DOWN_"..step].active=bol
  
  vws["ASC_VF_VOL_"..step].active=bol
  vws["ASC_SL_VOL_"..step].active=bol
  
  vws["ASC_VF_PAN_"..step].active=bol
  vws["ASC_SL_PAN_"..step].active=bol
  
  vws["ASC_VF_DLY_"..step].active=bol
  vws["ASC_SL_DLY_"..step].active=bol
  
  vws["ASC_VF_VOL_"..step].active=bol
  vws["ASC_SL_VOL_"..step].active=bol
  
  vws["ASC_VF_SFX_AMO_"..step].active=bol
  vws["ASC_BT_SFX_INSERT_"..step].active=bol
  vws["ASC_SL_SFX_AMO_"..step].active=bol
end



--select visible/active
local function asc_select_visible(value)
  if (value==1) then --all
    for step=1,32 do
      asc_step_active(step,true)
    end
    vws.ASC_RACK_5.visible=false
    vws.ASC_RACK_3.visible=false
  elseif (value==2) then --even
    for step=1,32 do
      vws["ASC_BT_STEP_SEL_"..step].active=false
      if (ASC_STEPS_SEL[2][step]) and (step<=vws.ASC_VB_STEPS.value) then
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.MARKER
        asc_step_active(step,true)
      else
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.DEFAULT
        asc_step_active(step,false)
      end
    end
    vws.ASC_RACK_5.visible=false
    vws.ASC_RACK_3.visible=true
  elseif (value==3) then --odd
    for step=1,32 do
      vws["ASC_BT_STEP_SEL_"..step].active=false
      if (ASC_STEPS_SEL[3][step]) and (step<=vws.ASC_VB_STEPS.value) then
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.MARKER
        asc_step_active(step,true)
      else
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.DEFAULT
        asc_step_active(step,false)
      end
    end
    vws.ASC_RACK_5.visible=false
    vws.ASC_RACK_3.visible=true
  elseif (value==4) then --custom
    for step=1,32 do
      vws["ASC_BT_STEP_SEL_"..step].active=true
      if (ASC_STEPS_SEL[4][step])  then
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.MARKER
        asc_step_active(step,true)
      else
        vws["ASC_BT_STEP_SEL_"..step].color=ASC_CLR.DEFAULT
        asc_step_active(step,false)
      end
    end
    vws.ASC_RACK_5.visible=false
    vws.ASC_RACK_3.visible=true
  elseif (value==5) then --profile
    for step=1,32 do
      asc_step_active(step,true)
    end
    vws.ASC_RACK_3.visible=false
    vws.ASC_RACK_5.visible=true
  end
  if (vws.ASC_CL_PANEL_3 and vws.ASC_CL_PANEL_3.visible) then
    vws.ASC_CL_PANEL_3.visible=false
    vws.ASC_CL_PANEL_1.visible=true
    vws.ASC_BT_INFO.color=ASC_CLR.DEFAULT
  end
  if (vws.ASC_CL_PANEL_1 and vws.ASC_CL_PANEL_1.visible) then
    asc_permute_sel_rack(vws.ASC_VB_STEPS.value)
  end
  
  --restore random panel
  if (ASC_RND_SHOW_STATE) then
    vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.MARKER
    vws.ASC_CL_PANEL_2.visible=true
    ASC_RND_SHOW=true
    asc_permute_rnd_rack(vws.ASC_VB_STEPS.value)
    ASC_RND_SHOW_STATE=false
  end
  
end



--master step
local ASC_MST=false
local function asc_mst_on_off()
  if (ASC_MST) then
    vws.ASC_STEP_PNL_0.visible=false
    vws.ASC_STEP_PNL_1.visible=true
    vws.ASC_BT_MST.color=ASC_CLR.DEFAULT
    if (vws.ASC_STEP_MARK_1.visible) then
      vws.ASC_STEP_MARK_1.visible=false
    end
    ASC_MST=false
  else
    if (vws.ASC_VB_STEPS.value>3) then
      vws.ASC_STEP_PNL_1.visible=false
    end
    vws.ASC_STEP_PNL_0.visible=true
    vws.ASC_BT_MST.color=ASC_CLR.MARKER
    ASC_MST=true
    if (ASC_COMPACT) then
      asc_compact()
    end
  end
  if (vws.ASC_CL_PANEL_3.visible) then asc_info_panel() end
end



--steps visible
local function asc_steps_visible(value)
  if (ASC_MST) then
    if (value>3) then
      vws.ASC_STEP_PNL_1.visible=false
    else
      vws.ASC_STEP_PNL_1.visible=true
    end
  end
  for step=2,32 do
    if (value>=step) then
      vws["ASC_STEP_PNL_"..step].visible=true
    else
      vws["ASC_STEP_PNL_"..step].visible=false
    end
  end
  if (value<25) then
    vws.ASC_RW_PANEL_STEPS_25.visible=false
  else
    vws.ASC_RW_PANEL_STEPS_25.visible=true
  end
  if (value<17) then
    vws.ASC_RW_PANEL_STEPS_17.visible=false
  else
    vws.ASC_RW_PANEL_STEPS_17.visible=true
  end
  if (value<9) then
    vws.ASC_RW_PANEL_STEPS_9.visible=false
  else
    vws.ASC_RW_PANEL_STEPS_9.visible=true
  end
  --max random
  if (vws.ASC_VB_RND_STEP_MAX.value>=value) then
    vws.ASC_VB_RND_STEP_MAX.value=value
  end
  if (not ASC_COMPACT) then
    asc_permute_rnd_rack(value)
  end
  asc_select_visible(vws.ASC_PP_SELECT.value)
  
  --restore random panel
  if (ASC_RND_SHOW_STATE) then
    vws.ASC_BT_SHOW_RANDOM_PNL.color=ASC_CLR.MARKER
    vws.ASC_CL_PANEL_2.visible=true
    ASC_RND_SHOW=true
    asc_permute_rnd_rack(vws.ASC_VB_STEPS.value)
    ASC_RND_SHOW_STATE=false
  end
end



--steps selector
local function asc_steps_selector(value)
  asc_select_visible(value)
  if (value==4) then
    for step=32,2,-1 do
      if (ASC_STEPS_SEL[4][step]) then
        vws.ASC_VB_STEPS.value=step
        return
      end
    end
  end
  if (value==5) and (vws.ASC_CHB_LOAD_PROFILE.value) then
    asc_pp_preload_list_profile()
    ASC_PROFILE_BYPASS=false asc_load_profile() ASC_PROFILE_BYPASS=true
  end
  if (value==1) or (value==5) then
    vws.ASC_VF_START_LNE.active=true
    vws.ASC_BT_START_LNE_UP.active=true
    vws.ASC_BT_START_LNE_DOWN.active=true
  else
    vws.ASC_VF_START_LNE.active=false
    vws.ASC_BT_START_LNE_UP.active=false
    vws.ASC_BT_START_LNE_DOWN.active=false
  end
end



--select button
local function asc_bt_select_step_on_off(step)
  local key_sta=rna.key_modifier_states
  if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
    if (ASC_STEPS_SEL[4][step]) then
      ASC_STEPS_SEL[4][step]=false
    else
      ASC_STEPS_SEL[4][step]=true
    end
    for step=32,1,-1 do
      if (step>=2) then
        if (ASC_STEPS_SEL[4][step]) then
          vws.ASC_VB_STEPS.value=step
          asc_steps_visible(step)
          break
        end
      else
        vws.ASC_VB_STEPS.value=4
        asc_steps_visible(4)
      end
    end
  end
  if (key_sta.alt=="pressed" and key_sta.control=="released" and key_sta.shift=="released") then
    if (vws.ASC_VB_STEPS.value<step) then
      vws.ASC_VB_STEPS.value=step
    end
    for step=vws.ASC_VB_STEPS.value,1,-1 do
      ASC_STEPS_SEL[4][step]= not ASC_STEPS_SEL[4][step]
    end
    asc_steps_visible(vws.ASC_VB_STEPS.value)
  end
  if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
    for step_a=1,32 do
      if (step_a<=step) then
        ASC_STEPS_SEL[4][step_a]=true
      else
        ASC_STEPS_SEL[4][step_a]=false
      end
    end
    if (step~=1) then
      vws.ASC_VB_STEPS.value=step
      asc_steps_visible(step)
    else
      vws.ASC_VB_STEPS.value=2
      asc_steps_visible(2)
    end
  end
end


--class step selection
class "Asc_Step_Sel"
function Asc_Step_Sel:__init(step)
  self.cnt=vb:row{
    spacing=-37,
    vb:row{
      spacing=-37,
      vb:button{
        id="ASC_BT_STEP_SEL_"..step,
        height=ASC_VB_HEIGHT_0,
        width=37,
        text=""..step,
        color=ASC_CLR.MARKER,
        notifier=function() asc_bt_select_step_on_off(step) end,
        tooltip="Select/deselect the step.\nFor \"Custom\":\n"..
                "  ⚫[Click] Select/deselect.\n"..
                "  ⚫[ALT Click] Invert the global selection.\n"..
                "  ⚫[CTRL Click] Select all steps up to the selected one."
      },
      vb:bitmap{
        active=false,
        height=8,
        width=8,
        mode="plain",
        bitmap="ico/tab_switch_ico.png"
      }
    },
    vb:bitmap{
      id="ASC_STEP_MARK_SWITCHES_"..step,
      visible=false,
      active=false,
      height=ASC_VB_HEIGHT_0,
      width=37,
      bitmap="ico/button_green3_ico.png"
    }
  }
end



--down/up instrument index
local ASC_DOWN_INS=0
local function asc_down_ins()
  ASC_WRITE_ALL_BYPASS=false
  if (ASC_DOWN_INS~=0) then
    if (vws["ASC_VF_INS_"..ASC_DOWN_INS].value>0) then
      vws["ASC_VF_INS_"..ASC_DOWN_INS].value=vws["ASC_VF_INS_"..ASC_DOWN_INS].value-1
    end
  else
    if (vws.ASC_VF_INS_0.value>0) then
      vws.ASC_VF_INS_0.value=vws.ASC_VF_INS_0.value-1
      for step=1,vws.ASC_VB_STEPS.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_INS_"..step].value=vws.ASC_VF_INS_0.value
        end
      end
    end
  end
  ASC_WRITE_ALL_BYPASS=true
  asc_write_ins(ASC_DOWN_INS)
end

local ASC_UP_INS=0
local function asc_up_ins()
  ASC_WRITE_ALL_BYPASS=false
  if (ASC_UP_INS~=0) then
    if (vws["ASC_VF_INS_"..ASC_UP_INS].value<vws["ASC_VF_INS_"..ASC_UP_INS].max) then
      vws["ASC_VF_INS_"..ASC_UP_INS].value=vws["ASC_VF_INS_"..ASC_UP_INS].value+1
    end
  else
    if (vws.ASC_VF_INS_0.value<vws.ASC_VF_INS_0.max) then
      vws.ASC_VF_INS_0.value=vws.ASC_VF_INS_0.value+1
      for step=1,vws.ASC_VB_STEPS.value do
        if (ASC_STEPS_SEL[vws.ASC_PP_SELECT.value][step]) then
          vws["ASC_VF_INS_"..step].value=vws.ASC_VF_INS_0.value
        end
      end
    end
  end
  ASC_WRITE_ALL_BYPASS=true
  asc_write_ins(ASC_UP_INS)
end

function asc_down_ins_repeat(release)
  if not release then
    if rnt:has_timer(asc_down_ins_repeat) then
      rnt:remove_timer(asc_down_ins_repeat)
      if not (rnt:has_timer(asc_down_ins)) then
        rnt:add_timer(asc_down_ins,40)
      end
    else
      if rnt:has_timer(asc_down_ins_repeat) then
        rnt:remove_timer(asc_down_ins_repeat)
      elseif rnt:has_timer(asc_down_ins) then
        rnt:remove_timer(asc_down_ins)
      end
      asc_down_ins()
      rnt:add_timer(asc_down_ins_repeat,300)
    end
  else
    if rnt:has_timer(asc_down_ins_repeat) then
      rnt:remove_timer(asc_down_ins_repeat)
    elseif rnt:has_timer(asc_down_ins) then
      rnt:remove_timer(asc_down_ins)
    end
  end
end

function asc_up_ins_repeat(release)
  if not release then
    if rnt:has_timer(asc_up_ins_repeat) then
      rnt:remove_timer(asc_up_ins_repeat)
      if not (rnt:has_timer(asc_up_ins)) then
        rnt:add_timer(asc_up_ins,40)
      end
    else
      if rnt:has_timer(asc_up_ins_repeat) then
        rnt:remove_timer(asc_up_ins_repeat)
      elseif rnt:has_timer(asc_up_ins) then
        rnt:remove_timer(asc_up_ins)
      end
      asc_up_ins()
      rnt:add_timer(asc_up_ins_repeat,300)
    end
  else
    if rnt:has_timer(asc_up_ins_repeat) then
      rnt:remove_timer(asc_up_ins_repeat)
    elseif rnt:has_timer(asc_up_ins) then
      rnt:remove_timer(asc_up_ins)
    end
  end
end



--preload list profile
function asc_pp_preload_list_profile()
  --check main folders members
  local main_folder="Profiles"--os.currentdir()
  if not io.exists(main_folder) then
    os.mkdir(main_folder)
  end
  if io.exists(main_folder) then
    --create default subfolder
    local default_nme="Default Profiles"
    if not io.exists(("%s/%s"):format(main_folder,default_nme)) then
      os.mkdir(("%s/%s"):format(main_folder,default_nme))
      ASC_PREF.subfolder_profiles.value=default_nme
    end
    --check subfolders members
    local subfolders_members=os.dirnames(main_folder)
    --print("subfolders_options",subfolders_options)
    --rprint(os.dirnames(main_folder))
    local XML_TBL_FLD={}
    --if (subfolders_options>=3) then
      for x=1,#subfolders_members do
        XML_TBL_FLD[x]=subfolders_members[x]
      end
      --print(XML_TBL_FLD)
      vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items=XML_TBL_FLD
      --select value
      if io.exists(("%s/%s"):format(main_folder,ASC_PREF.subfolder_profiles.value)) then
        vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value=table.find(vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items,ASC_PREF.subfolder_profiles.value)
      end
    --end
  end

  --empty tables
  vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items={}
  vws.ASC_PP_SELECT_PROFILE_FILE.items={}

  --check subfolder
  local subfolder=("%s/%s"):format(main_folder,ASC_PREF.subfolder_profiles.value)
  if io.exists(subfolder) then
    local xml_destiny_folder=os.dirnames(subfolder)
    --print(xml_destiny_folder)
    if (#xml_destiny_folder>=1) then
      local XML_TBL_DIR={}
      local n=1
      for x=1,#xml_destiny_folder do
        XML_TBL_DIR[x]=xml_destiny_folder[x]
      end
      vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items=XML_TBL_DIR

      --check destiny directory
      local destiny_folder=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
      if (destiny_folder) then
        local directory=("%s/%s"):format(subfolder,destiny_folder)
        --print(directory)
        if io.exists(directory) then
          --print(directory)
          local xml_files=os.filenames(directory)
          if (#xml_files>=1) then
            local XML_TBL={}
            local n=1
            for x=1,#xml_files do
              local nme=xml_files[x]
              if (nme:sub(-4)==".xml") then
                local path=("%s/%s"):format(directory,nme)
                if (io.exists(path)) then
                  local file=io.open(path)
                  local i,line_2=0,""
                  for line in file:lines() do
                    i=i+1
                    if (i==2) then
                      line_2=line
                    end
                  end 
                  file:close()  -- close that file now
                  if (line_2:sub(2,12)=="ASC_Profile") then
                    XML_TBL[x]=("%s"):format(nme:sub(1,-5))--nme
                    --XML_TBL[x]=(" %.2d: %s"):format(n,nme:sub(1,-5))--nme
                    n=n+1
                  end
                end
                --[[
                if (io.exists(path)) then
                  local i,line_2=0,""
                  for line in io.lines(path) do  --ERROR
                    i=i+1
                    if (i==2) then
                      line_2=line
                    end
                  end
                  if (line_2:sub(2,12)=="ASC_Profile") then
                    XML_TBL[x]=(" %.2d: %s"):format(n,nme:sub(1,-5))--nme
                    n=n+1
                  end
                end
                ]]
              end
            end
            vws.ASC_PP_SELECT_PROFILE_FILE.items=XML_TBL
            local file="ASC Profile (Default).xml"
            if io.exists(("%s/%s"):format(subfolder,file)) then
              vws.ASC_PP_SELECT_PROFILE_FILE.value=table.find(vws.ASC_PP_SELECT_PROFILE_FILE.items,file)
            end  
          elseif (xml_files==0) then
            vws.ASC_PP_SELECT_PROFILE_FILE.items={}
          end
          if (xml_files==1) then
            vws.ASC_PP_SELECT_PROFILE_FILE.value=1
          end
        end
      end
    else
      vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items={}
    end
  end
end



--write name profile to edit
local function asc_write_name_profile()
  vws.ASC_TF_SAVE_PROFILE.text=vws.ASC_PP_SELECT_PROFILE_FILE.items[vws.ASC_PP_SELECT_PROFILE_FILE.value]
  vws.ASC_TF_SAVE_PROFILE.edit_mode=true
end


--open profile folder
local ASC_FOLDER_PROFILE=true
local function asc_open_profile_folder()
  local key_sta=rna.key_modifier_states
  if (key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
    if (ASC_FOLDER_PROFILE) then
      vws.ASC_BT_FOLDER_PROFILE.bitmap="ico/folder_p_ico.png"
      ASC_FOLDER_PROFILE=false
      vws.ASC_PP_SELECT_PROFILE_FILE.active=false
      vws.ASC_BT_WRITE_NAME_PROFILE.active=false
    else
      vws.ASC_BT_FOLDER_PROFILE.bitmap="ico/file_ico.png"
      ASC_FOLDER_PROFILE=true
      vws.ASC_PP_SELECT_PROFILE_FILE.active=true
      vws.ASC_BT_WRITE_NAME_PROFILE.active=true
    end
    vws.ASC_TF_SAVE_PROFILE.text=""
    vws.ASC_TF_SAVE_PROFILE.edit_mode=true
  end
  if (key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
    local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
    if (directory) then
      if io.exists("Profiles") then
        local path_directory_name=("Profiles/%s/%s"):format(ASC_PREF.subfolder_profiles.value,directory)
        rna:open_path(path_directory_name)
      end
    end
  end
end


--autoselect directory/file
local function asc_autoselect_profile()
  if not ASC_FOLDER_PROFILE then
    local t=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items
    if #t>=1 then
      for i=1,#t do
        --print(vws.ASC_PP_SELECT_PROFILE_FILE.items[i])
        --print(vws.ASC_TF_SAVE_PROFILE.text)
        if (vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[i]==vws.ASC_TF_SAVE_PROFILE.text) then
          vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value=i
          --print(i)
        return
        end
      end
    end    
  else
    local t=vws.ASC_PP_SELECT_PROFILE_FILE.items
    if #t>=1 then
      for i=1,#t do
        --print(vws.ASC_PP_SELECT_PROFILE_FILE.items[i])
        --print(vws.ASC_TF_SAVE_PROFILE.text)
        if (vws.ASC_PP_SELECT_PROFILE_FILE.items[i]==vws.ASC_TF_SAVE_PROFILE.text) then
          vws.ASC_PP_SELECT_PROFILE_FILE.value=i
          --print(i)
        return
        end
      end
    end
  end
end



--profile remove
local function asc_remove_profile()
  if not ASC_FOLDER_PROFILE then
    local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
    if (directory) then
      if io.exists("Profiles") then
        local path_directory_name=("Profiles/%s/%s"):format(ASC_PREF.subfolder_profiles.value,directory)
        if io.exists(path_directory_name) then
          local num=#os.filenames(path_directory_name)
          if (num>0) then
            --print("1",num)
            if (num==1) then
              asc_status_bar_on(7000,23,directory,num)
            else
              asc_status_bar_on(7000,24,directory,num)
            end
            return
          else
            --print("2",num)
            local mpt=rna:show_prompt("Acid Step Sequencer",("Are you sure you want to delete the folder \"%s\"?\n\nPath: \"../%s\""):format(directory,path_directory_name),{"Ok","Cancel"})
            if (mpt=="Cancel") then
              return
            end
            os.remove(path_directory_name)
            asc_status_bar_on(6000,25,path_directory_name,0)
          end
        end
      end
    end
  else
    local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
    local file=vws.ASC_PP_SELECT_PROFILE_FILE.items[vws.ASC_PP_SELECT_PROFILE_FILE.value]
    if (directory and file) then
      if io.exists("Profiles") then
        local path_file_name=("Profiles/%s/%s/%s.xml"):format(ASC_PREF.subfolder_profiles.value,directory,file)
        if io.exists(path_file_name) then
          local mpt=rna:show_prompt("Acid Step Sequencer",("Are you sure you want to delete the profile \"%s\"?\n\nPath: \"../%s\""):format(file,path_file_name),{"Ok","Cancel"})
          if (mpt=="Cancel") then
            return
          end
          os.remove(path_file_name)
          asc_status_bar_on(5000,4,path_file_name,0)
        else
          asc_status_bar_on(5000,26,directory,0)
        end
      end
    end
  end
end



--profile load/save
local function asc_save_profile()
  if not ASC_FOLDER_PROFILE then
    if (vws.ASC_TF_SAVE_PROFILE.text=="" or vws.ASC_TF_SAVE_PROFILE.text=="None") then
      vws.ASC_TF_SAVE_PROFILE.text="New Folder"
    end
    local nme=vws.ASC_TF_SAVE_PROFILE.text
    if io.exists("Profiles") then
      local path_directory_name=("Profiles/%s/%s"):format(ASC_PREF.subfolder_profiles.value,nme)
      if io.exists(path_directory_name) then
        local mpt=rna:show_prompt("Acid Step Sequencer",("The directory \"%s\" already exist.\nPlease write another folder name!"):format(path_directory_name),{"Ok"})
        return
      end
      --print("overwrite")
      os.mkdir(path_directory_name)
      asc_status_bar_on(4000,22,path_directory_name,0)
    end
  else
    local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
    if io.exists("Profiles") then
      if (directory) then
        local path_directory=("Profiles/%s/%s"):format(ASC_PREF.subfolder_profiles.value,directory)
        if io.exists(path_directory) then
          local path_file_name=("%s/%s.xml"):format(path_directory,vws.ASC_TF_SAVE_PROFILE.text)
          if (vws.ASC_TF_SAVE_PROFILE.text=="") then
            vws.ASC_TF_SAVE_PROFILE.text="Untitled Profile"
            path_file_name=("%s/%s/Untitled Profile.xml"):format(ASC_PREF.subfolder_profiles.value,directory)
          end
          --if (SMC_PREF.smc_redirect_path.value) then
          --  path_file_name=("%s%s.xml"):format(SMC_PREF.smc_songs_path.value,vws.SMC_MAN_TF_SAVE.text)
          --end
          if io.exists(path_file_name) then
            local mpt=rna:show_prompt("Acid Step Sequencer",("The XML file \"%s\" already exist.\nDo you want to overwrite it?\n\nPath: \"../%s\""):format(vws.ASC_TF_SAVE_PROFILE.text,path_file_name),{"Ok","Cancel"})
            if (mpt=="Cancel") then
              return
            end
          end
          local doc=renoise.Document.create("ASC_Profile"){}
          doc:add_property("name",vws.ASC_TF_SAVE_PROFILE.text)
          doc:add_property("stlne",vws.ASC_VF_START_LNE.value)
          doc:add_property("steps",vws.ASC_VB_STEPS.value)
          doc:add_property("bpm",song.transport.bpm)
          doc:add_property("lpb",song.transport.lpb)
          doc:add_property("nol",song.selected_pattern.number_of_lines)
        
          local sst=song.selected_track
          if (sst.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
            --doc:add_property("nte_col",sst.visible_note_columns)
            doc:add_property("vol_col",sst.volume_column_visible)
            doc:add_property("pan_col",sst.panning_column_visible)
            doc:add_property("dly_col",sst.delay_column_visible)
            doc:add_property("sfx_col",sst.sample_effects_column_visible)
            --doc:add_property("tfx_col",sst.visible_effect_columns)
            if (song.selected_note_column) then
              doc:add_property("nme_col",sst:column_name(song.selected_note_column_index))
            else
              doc:add_property("nme_col","")
            end
          else
            --doc:add_property("nte_col",1)
            doc:add_property("vol_col",false)
            doc:add_property("pan_col",false)
            doc:add_property("dly_col",false)
            doc:add_property("sfx_col",false)
            --doc:add_property("tfx_col",0)
            doc:add_property("nme_col","")
          end
          
          local node={}
          for step=1,32 do
            node[step]=renoise.Document.create("MySubDoc"){}
            node[step]:add_property("ins",vws["ASC_VF_INS_"..step].value)
            node[step]:add_property("nte",vws["ASC_VB_NTE_"..step].value)
            node[step]:add_property("lns",vws["ASC_VF_LNS_"..step].value)
            node[step]:add_property("off",vws["ASC_VF_OFF_"..step].value)
            node[step]:add_property("vol",vws["ASC_SL_VOL_"..step].value)
            node[step]:add_property("pan",vws["ASC_SL_PAN_"..step].value)
            node[step]:add_property("dly",vws["ASC_SL_DLY_"..step].value)
            node[step]:add_property("eff",vws["ASC_PP_SFX_EFF_"..step].value)
            node[step]:add_property("amo",vws["ASC_SL_SFX_AMO_"..step].value)
            doc:add_property("Step_"..step, node[step])
          end
          doc:save_as(path_file_name)
          asc_status_bar_on(5000,5,path_file_name,0)
        else
          os.mkdir(("Profiles/%s/Default Profiles"):format(ASC_PREF.subfolder_profiles.value))
          asc_status_bar_on(6000,27,"Default Profiles",0)
        end
      end
    end
  end
end


function asc_load_profile()
  --print("asc_load_profile")
  local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
  --print("directory",directory)
  local file=vws.ASC_PP_SELECT_PROFILE_FILE.items[vws.ASC_PP_SELECT_PROFILE_FILE.value]
  --file=string.sub(file,string.find(file," "))
  if (directory and file) then
    if (io.exists("Profiles")) then
      local path_file_name=("Profiles/%s/%s/%s.xml"):format(ASC_PREF.subfolder_profiles.value,directory,file)
      --print(path_file_name)
      if (io.exists(path_file_name)) then
        local doc=renoise.Document.create("ASC_Profile"){}
        doc:add_property("name","")
        doc:add_property("stlne",1)
        doc:add_property("steps",2)
        doc:add_property("bpm",0)
        doc:add_property("lpb",0)
        doc:add_property("nol",0)
        
        --doc:add_property("nte_col",1)
        doc:add_property("vol_col",false)
        doc:add_property("pan_col",false)
        doc:add_property("dly_col",false)
        doc:add_property("sfx_col",false)
        --doc:add_property("tfx_col",0)
        doc:add_property("nme_col","")
    
        local node={}
        for step=1,32 do
          node[step]=renoise.Document.create("MySubDoc"){}
          node[step]:add_property("ins",1)
          node[step]:add_property("nte",1)
          node[step]:add_property("lns",1)
          node[step]:add_property("off",1)
          node[step]:add_property("vol",1)
          node[step]:add_property("pan",1)
          node[step]:add_property("dly",1)
          node[step]:add_property("eff",1)
          node[step]:add_property("amo",1)
          doc:add_property("Step_"..step, node[step])
        end
        doc:load_from(path_file_name)
    
        --vws.ASC_TF_SAVE_PROFILE.text=doc:property("name").value
        vws.ASC_VF_START_LNE.value=doc:property("stlne").value
        vws.ASC_VB_STEPS.value=doc:property("steps").value
        for step=1,32 do
          if (ASC_PROFILE_CAPTURE_INS) then
            vws["ASC_VF_INS_"..step].value=song.selected_instrument_index-1
          else
            vws["ASC_VF_INS_"..step].value=doc:property("Step_"..step)["ins"].value
          end
          vws["ASC_VB_NTE_"..step].value=doc:property("Step_"..step)["nte"].value
          vws["ASC_VF_LNS_"..step].value=doc:property("Step_"..step)["lns"].value
          vws["ASC_VF_OFF_"..step].value=doc:property("Step_"..step)["off"].value
          vws["ASC_SL_VOL_"..step].value=doc:property("Step_"..step)["vol"].value
          vws["ASC_SL_PAN_"..step].value=doc:property("Step_"..step)["pan"].value
          vws["ASC_SL_DLY_"..step].value=doc:property("Step_"..step)["dly"].value
          vws["ASC_PP_SFX_EFF_"..step].value=doc:property("Step_"..step)["eff"].value
          vws["ASC_SL_SFX_AMO_"..step].value=doc:property("Step_"..step)["amo"].value
        end
        if (song.transport.edit_mode and ASC_PREF.insert_steps.value) then
          if (ASC_PREF.change_bpm_lpb.value) then
            if (doc:property("bpm").value~=0) then
              song.transport.bpm=doc:property("bpm").value
            end
            if (doc:property("lpb").value~=0) then
              song.transport.lpb=doc:property("lpb").value
            end
          end
          if (ASC_PREF.change_nol.value) then
            if (doc:property("nol").value~=0) then
              song.selected_pattern.number_of_lines=doc:property("nol").value
            end
          end
          if (ASC_PREF.hide_sub_columns.value) then
            local sst=song.selected_track
            if (sst.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
              --sst.visible_note_columns=doc:property("nte_col").value
              sst.volume_column_visible=doc:property("vol_col").value
              sst.panning_column_visible=doc:property("pan_col").value
              sst.delay_column_visible=doc:property("dly_col").value
              sst.sample_effects_column_visible=doc:property("sfx_col").value
              --sst.visible_effect_columns=doc:property("tfx_col").value
            end
          end
          if (ASC_PREF.note_column_name.value) then
            local sst=song.selected_track
            if (sst.type==renoise.Track.TRACK_TYPE_SEQUENCER) then
              if (song.selected_note_column) then
                if (doc:property("nme_col").value~="") then
                  sst:set_column_name(song.selected_note_column_index,doc:property("nme_col").value)
                end
              end
            end
          end
        end
      end
    end
  end
end



--profile select
local function asc_select_profile_file()
  ASC_PROFILE_BYPASS=false asc_load_profile() ASC_PROFILE_BYPASS=true
  if (ASC_SAVE_PROFILE_BYPASS) and (vws.ASC_CHB_INSERT_STEPS.value) then
    if (ASC_PREF.hide_sub_columns.value) then
      ASC_VISIBLE_SUB_COLUMN_BYPASS=false
      asc_write_all(1,true)
      ASC_VISIBLE_SUB_COLUMN_BYPASS=true
    else
      asc_write_all(1,true)
    end
  end
end



local function asc_return_favorite_profile_tooltip(idx,main,dir,val)
  --print("tooltip")
  local path=("\"%s/%s/%s\""):format(main,dir,val)
  if (path=="\"//\"") then
    path="None"
  end
  local tooltip=("Favorite slot profile %s: %s.\n"..
                 "Select or charge the favorite slot profile:\n"..
                 "  ⚫[Click] Select the favorite slot profile.\n"..
                 "  ⚫[CTRL Click] Charge the selected profile in the favorite slot profile."):format(idx,path)
  return tooltip
end


local function asc_bt_select_profile(idx)
  local key_sta=rna.key_modifier_states
  local main_directory=vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items
  local directory=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items
  if (#main_directory==1) and (main_directory[1]=="None") then
    asc_status_bar_on(5000,26,directory[1],0)
    return
  else
    if (#directory==1) and (directory[1]=="None") then
      asc_status_bar_on(5000,26,directory[1],0)
      return
    else
      local tab=vws.ASC_PP_SELECT_PROFILE_FILE.items
      --print(#tab,tab[1])
      if(key_sta.alt=="released" and key_sta.control=="released" and key_sta.shift=="released") then
        for i=1,#main_directory do
          if (vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items[i]==ASC_PREF["favorite_main_directory_"..idx].value) then
            vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value=i
            break
          end
        end
        for i=1,#directory do
          if (vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[i]==ASC_PREF["favorite_directory_"..idx].value) then
            vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value=i
            break
          end
        end
        if (#tab==1) and tab[1]=="None" then
          vws["ASC_BT_PROFILE_SEL_"..idx].tooltip=asc_return_favorite_profile_tooltip(idx,"","","")
        else
          --select profile directly or change popup
          if (ASC_PREF["favorite_main_directory_"..idx].value==vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items[vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value]) and 
             (ASC_PREF["favorite_directory_"..idx].value==vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]) and 
             (ASC_PREF["favorite_profile_"..idx].value==vws.ASC_PP_SELECT_PROFILE_FILE.items[vws.ASC_PP_SELECT_PROFILE_FILE.value]) then
            asc_select_profile_file()
            return
          end
          for i=1,#tab do
            if (ASC_PREF["favorite_profile_"..idx].value==vws.ASC_PP_SELECT_PROFILE_FILE.items[i]) then
              vws.ASC_PP_SELECT_PROFILE_FILE.value=i
              return
            end
          end
          --not profile
          vws["ASC_BT_PROFILE_SEL_"..idx].tooltip=asc_return_favorite_profile_tooltip(idx,"","","")
          asc_status_bar_on(4000,1,ASC_PREF["favorite_profile_"..idx].value,0)
          ASC_PREF["favorite_profile_"..idx].value=""
        end
      end
      if(key_sta.alt=="released" and key_sta.control=="pressed" and key_sta.shift=="released") then
        if (#tab==1) and tab[1]=="None" then
          ASC_PREF["favorite_profile_"..idx].value=""
          vws["ASC_BT_PROFILE_SEL_"..idx].tooltip=asc_return_favorite_profile_tooltip(idx,"","","")
          asc_status_bar_on(4000,2,"",0)
        else
          ASC_PREF["favorite_main_directory_"..idx].value=vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items[vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value]
          ASC_PREF["favorite_directory_"..idx].value=vws.ASC_PP_SELECT_PROFILE_DIRECTORY.items[vws.ASC_PP_SELECT_PROFILE_DIRECTORY.value]
          ASC_PREF["favorite_profile_"..idx].value=vws.ASC_PP_SELECT_PROFILE_FILE.items[vws.ASC_PP_SELECT_PROFILE_FILE.value]
          vws["ASC_BT_PROFILE_SEL_"..idx].tooltip=asc_return_favorite_profile_tooltip(
            idx,
            ASC_PREF["favorite_main_directory_"..idx].value,
            ASC_PREF["favorite_directory_"..idx].value,
            ASC_PREF["favorite_profile_"..idx].value
          )
          asc_status_bar_on(5000,12,ASC_PREF["favorite_profile_"..idx].value,idx)
        end
      end
    end
  end
end



--class profile selection
class "Acd_Profile_Sel"
function Acd_Profile_Sel:__init(idx)
  self.cnt=vb:button{
    id="ASC_BT_PROFILE_SEL_"..idx,
    height=ASC_VB_HEIGHT_0,
    width=19,
    text=""..idx,
    notifier=function() asc_bt_select_profile(idx) end,
    tooltip=asc_return_favorite_profile_tooltip(idx,ASC_PREF["favorite_main_directory_"..idx].value,ASC_PREF["favorite_directory_"..idx].value,ASC_PREF["favorite_profile_"..idx].value)    
  }
end

local function asc_bt_select_profiles(num)
  local rw=vb:row{spacing=-3}
  for idx=1,num do
    rw:add_child(Acd_Profile_Sel(idx).cnt)
  end
  return rw
end


--profile capture instrument
local function asc_bt_profile_capture_ins()
  if (ASC_PROFILE_CAPTURE_INS) then
    vws.ASC_BT_PROFILE_CAPTURE_INS.color=ASC_CLR.DEFAULT
    ASC_PROFILE_CAPTURE_INS=false
    asc_status_bar_on(3000,17,"",0)
  else
    vws.ASC_BT_PROFILE_CAPTURE_INS.color=ASC_CLR.MARKER
    ASC_PROFILE_CAPTURE_INS=true
    asc_status_bar_on(3000,18,"",0)
  end
  ASC_PROFILE_BYPASS=false asc_load_profile() ASC_PROFILE_BYPASS=true
end



--clear main subfolder for profiles
local function asc_remove_main_subfolder_profile()
  local main_folder="Profiles"
  local nme=vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items[vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value]
  if io.exists(main_folder) then
    local subfolder_directory=("%s/%s"):format(main_folder,nme)
    local num=#os.dirnames(subfolder_directory)
    if (num>0) then
      if (num==1) then
        asc_status_bar_on(4000,23,nme,num)
      else
        asc_status_bar_on(4000,24,nme,num)
      end
      return
    else
      os.remove(subfolder_directory)
      asc_status_bar_on(4000,25,nme,0)
      return
    end
  else
    asc_status_bar_on(4000,9,nme,0) 
  end
end



--save main subfolder for profiles
local function asc_save_main_subfolder_profile()
  local main_folder="Profiles"
  local nme=vws.ASC_TF_SAVE_MAIN_FOLDER_PROFILE.text
  if io.exists(main_folder) then
    local subfolder_directory=("%s/%s"):format(main_folder,nme)
    if io.exists(subfolder_directory) then
      local mpt=rna:show_prompt("Acid Step Sequencer",("The directory \"%s\" already exist.\nPlease write another main subfolder name!"):format(nme),{"Ok"})
      return
    else
      --create directory
      os.mkdir(subfolder_directory)
      --check subfolders members
      local subfolders_members=os.dirnames(main_folder)
      local XML_TBL_FLD={}
      for x=1,#subfolders_members do
        XML_TBL_FLD[x]=subfolders_members[x]
      end
      vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items=XML_TBL_FLD
      --select value      
      vws.ASC_PP_DEFAULT_FOLDER_PROFILES.value=table.find(vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items,nme)
    end
  end
end



-------------------------------------------------------------------------------------------------
--gui parts
class "Asc_Step"
function Asc_Step:__init(step)
  self.cnt=vb:row{
    id="ASC_STEP_PNL_"..step,
    spacing=-135,
    vb:column{
      style="group",
      margin=2,
      vb:row{
        vb:row{
          vb:row{
            spacing=-82,
            vb:row{
              spacing=-3,
              vb:text{
                id="ASC_TX_STEP_NAME_"..step,
                height=ASC_VB_HEIGHT_1,
                width=53,
                style="strong",
                font="bold",
                text="Step "..step
              },
              vb:valuefield{
                id="ASC_VF_STEP_LNE_"..step,
                active=false,
                height=ASC_VB_HEIGHT_1,
                width=29,
                min=1,
                max=513,
                value=1,
                align="right",
                tostring=function(value) if (value>512) then return "--" else return ("%.2d"):format(value-1) end end,
                tonumber=function(value) return tonumber(value) end,
              }
            },
            vb:bitmap{
              id="ASC_MP_JUMP_STEP_"..step,
              height=ASC_VB_HEIGHT_1,
              width=82,
              bitmap="ico/transparent_ico.png",
              notifier=function() asc_jump_step(step,song.selected_pattern.number_of_lines) end,
              tooltip="Jump to Note Step "..step.."."
            }
          },
          vb:row{
            spacing=-2,
            vb:button{
              id="ASC_BT_INS_DOWN_"..step,
              height=ASC_VB_HEIGHT_1,
              width=15,
              bitmap="ico/mini_left_ico.png",
              pressed=function() ASC_DOWN_INS=step asc_down_ins_repeat() end,
              released=function() asc_down_ins_repeat(true) end,
              tooltip="Decrease the Instrument Index."
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  id="ASC_VF_INS_"..step,
                  height=ASC_VB_HEIGHT_0,
                  width=24,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_instrument.value,
                  tostring=function(value) if (value==255) then return "--" else return ("%.2X"):format(value) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(255,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16) end end end,
                  notifier=function() if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_AUTOCAP_INS_BYPASS and ASC_RND_TBL.INS[step]) then asc_write_ins(step) end end,
                  tooltip="Instrument Index\n(00 to FE. FF or \"--\"=empty)"
                }
              }
            },
            vb:button{
              id="ASC_BT_INS_UP_"..step,
              height=ASC_VB_HEIGHT_1,
              width=15,
              bitmap="ico/mini_right_ico.png",
              pressed=function() ASC_UP_INS=step asc_up_ins_repeat() end,
              released=function()asc_up_ins_repeat(true) end,
              tooltip="Increase the Instrument Index."
            }
          }
        }
      },
      vb:row{
        vb:valuebox{
          id="ASC_VB_NTE_"..step,
          height=ASC_VB_HEIGHT_0,
          width=59,
          min=0,
          max=120,
          value=ASC_PREF.initial_note.value, --vws.ASC_VLB_INITIAL_NOTE.value, --48,
          tostring=function(value) return asc_note_tostring(value) end,
          tonumber=function(value) return asc_note_tonumber(value) end,
          notifier=function() if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.NTE[step]) then asc_write_nte(step) end end,
          tooltip="Note Step\n(C-0 to B-9. \"--\"=empty)"
        },
        vb:row{
          vb:text{
            height=ASC_VB_HEIGHT_0,
            width=20,
            align="right",
            text="FX"
          },
          vb:popup{
            id="ASC_PP_SFX_EFF_"..step,
            height=ASC_VB_HEIGHT_0,
            width=52,
            items=ASC_SFX_EFF,
            value=ASC_PREF.initial_effect.value, --#ASC_SFX_EF2,
            notifier=function() if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS) then asc_write_sfx_eff(step) end end,
            tooltip=ASC_FX_TOOLTIP
          }
        }
      },
      vb:space{height=1},
      vb:row{
        spacing=2,
        vb:column{
          spacing=1,
          vb:button{
            id="ASC_BT_VAL_EMPTY_"..step,
            height=ASC_VB_HEIGHT_0,
            width=26,
            text="--",
            notifier=function() asc_restore_values(step) end,
            tooltip="Empty the Volume, Panning, Delay, Effect & Amount values."
          },
          vb:column{
            spacing=-3,
            vb:column{
              spacing=-2,
              vb:button{
                id="ASC_BT_LNS_UP_"..step,
                height=15,
                width=26,
                bitmap="ico/mini_up_ico.png",
                pressed=function() ASC_UP_LNE=step asc_up_lne_repeat() end,
                released=function() asc_up_lne_repeat(true) end,
                --notifier=function() asc_up_lne(step) end,
                tooltip="Up LNS Value"
              },
              vb:row{
                margin=1,
                vb:row{
                  style="plain",
                  vb:valuefield{
                    id="ASC_VF_LNS_"..step,
                    height=ASC_VB_HEIGHT,
                    width=24,
                    align="center",
                    min=1,
                    max=99,--64,
                    value=ASC_STEP.LNE_A[step],--4,
                    tostring=function(value) return ("%d"):format(value) end,
                    tonumber=function(value) return tonumber(value) end,
                    notifier=function()
                      if (ASC_NESTED_LINES_ON[1]) then ASC_NESTED_LINES_ON[1]=false end
                      if (ASC_IMPORT_BYPASS and ASC_WRITE_ALL_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.LNS[step]) then asc_lne(step) end
                    end,
                    tooltip="LNS\nNumber of lines of the current step."
                  }
                }
              },
              vb:button{
                id="ASC_BT_LNS_DOWN_"..step,
                height=15,
                width=26,
                bitmap="ico/mini_down_ico.png",
                pressed=function() ASC_DOWN_LNE=step asc_down_lne_repeat() end,
                released=function() asc_down_lne_repeat(true) end,
                --notifier=function() asc_down_lne(step) end,
                tooltip="Down LNS Value"
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=26,
              align="center",
              text="LNS"
            }
          },
          vb:space{height=4},
          vb:column{
            spacing=-3,
            vb:column{
              spacing=-2,
              vb:button{
                id="ASC_BT_OFF_UP_"..step,
                height=15,
                width=26,
                bitmap="ico/mini_up_ico.png",
                pressed=function() ASC_UP_OFF=step asc_up_off_repeat() end,
                released=function() asc_up_off_repeat(true) end,
                tooltip="Up OFF Value"
              },
              vb:row{
                margin=1,
                vb:row{
                  style="plain",
                  vb:valuefield{
                    id="ASC_VF_OFF_"..step,
                    height=ASC_VB_HEIGHT_0,
                    width=24,
                    align="center",
                    min=0,
                    max=99,
                    value=ASC_PREF.nol_note_off.value,
                    tostring=function(value) return ("%d"):format(value) end,
                    tonumber=function(value) return tonumber(value) end,
                    notifier=function()
                      if (ASC_NESTED_LINES_ON[1]) then ASC_NESTED_LINES_ON[1]=false end
                      if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_WRITE_ALL_BYPASS) then asc_in_off(step) end
                    end,
                    tooltip="OFF\nNumber of lines of the note-off.\n(00 to 99)"
                  }
                }
              }, 
              vb:button{
                id="ASC_BT_OFF_DOWN_"..step,
                height=15,
                width=26,
                bitmap="ico/mini_down_ico.png",
                pressed=function() ASC_DOWN_OFF=step asc_down_off_repeat() end,
                released=function() asc_down_off_repeat(true) end,
                tooltip="Down OFF Value"
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=26,
              align="center",
              text="OFF"
            }
          }
        },
        vb:row{
          spacing=-2,
          vb:column{
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  id="ASC_VF_VOL_"..step,
                  height=ASC_VB_HEIGHT,
                  width=25,
                  align="center",
                  min=0,
                  max=128,
                  value=ASC_PREF.initial_volume.value,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value-1) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16)+1 end end end,
                  notifier=function(value)
                    if (vws["ASC_SL_VOL_"..step].value~=value) then
                      vws["ASC_SL_VOL_"..step].value=value
                    end
                    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.VOL[step]) then asc_write_vol(step) end
                  end,
                  tooltip="Volume Value\n(00 to 7F. \"--\"=empty)"
                }
              }
            },
            vb:row{
              vb:space{width=3},
              vb:column{
                spacing=-3,
                vb:slider{
                  id="ASC_SL_VOL_"..step,
                  height=115,
                  width=21,
                  min=0,
                  max=128,
                  value=ASC_PREF.initial_volume.value,
                  notifier=function(value)
                    if (vws["ASC_VF_VOL_"..step].value~=value) then
                      vws["ASC_VF_VOL_"..step].value=value
                    end
                  end,
                  tooltip=""
                },
                vb:text{
                  height=ASC_VB_HEIGHT_0,
                  width=19,
                  align="center",
                  text="V"
                }
              }
            }
          },
          vb:column{
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  id="ASC_VF_PAN_"..step,
                  height=ASC_VB_HEIGHT,
                  width=25,
                  align="center",
                  min=0,
                  max=129,
                  value=ASC_PREF.initial_panning.value,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value -1) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16)+1 end end end,
                  notifier=function(value)
                    if (vws["ASC_SL_PAN_"..step].value~=value) then
                      vws["ASC_SL_PAN_"..step].value=value
                    end
                    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.PAN[step]) then asc_write_pan(step) end
                  end,
                  tooltip="Panning Value\n(00 to 80. \"--\"=empty)"
                }
              }
            },
            vb:row{
              vb:space{width=3},
              vb:column{
                spacing=-3,
                vb:slider{
                  id="ASC_SL_PAN_"..step,
                  height=115,
                  width=21,
                  min=0,
                  max=129,
                  value=ASC_PREF.initial_panning.value,
                  notifier=function(value)
                    if (vws["ASC_VF_PAN_"..step].value~=value) then
                      vws["ASC_VF_PAN_"..step].value=value
                    end
                  end,
                  tooltip=""
                },
                vb:text{
                  height=ASC_VB_HEIGHT_0,
                  width=19,
                  align="center",
                  text="P"
                }
              }
            }
          },
          vb:column{
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  id="ASC_VF_DLY_"..step,
                  height=ASC_VB_HEIGHT,
                  width=25,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_delay.value,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16) end end end,
                  notifier=function(value)
                    if (vws["ASC_SL_DLY_"..step].value~=value) then
                      vws["ASC_SL_DLY_"..step].value=value
                    end
                    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.DLY[step]) then asc_write_dly(step) end
                  end,
                  tooltip="Delay Value\n(01 to 255. \"--\"=empty)"
                }
              }
            }, 
            vb:row{
              vb:space{width=3},
              vb:column{
                spacing=-3,
                vb:slider{
                  id="ASC_SL_DLY_"..step,
                  height=115,
                  width=21,
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_delay.value,
                  notifier=function(value)
                    if (vws["ASC_VF_DLY_"..step].value~=value) then
                      vws["ASC_VF_DLY_"..step].value=value
                    end
                  end,
                  tooltip=""
                },
                vb:text{
                  height=ASC_VB_HEIGHT_0,
                  width=19,
                  align="center",
                  text="D"
                }
              }
            }
          },
          vb:column{
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  id="ASC_VF_SFX_AMO_"..step,
                  height=ASC_VB_HEIGHT,
                  width=25,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_amount.value,
                  tostring=function(value) return ("%.2X"):format(value) end,
                  tonumber=function(value) return tonumber(value,16) end,
                  notifier=function(value)
                    if (vws["ASC_SL_SFX_AMO_"..step].value~=value) then
                      vws["ASC_SL_SFX_AMO_"..step].value=value
                    end
                    if (ASC_IMPORT_BYPASS and ASC_PROFILE_BYPASS and ASC_RND_TBL.SFX_AMO[step]) then asc_write_sfx_amo(step) end
                  end,
                  tooltip="FX Amount Value\n(00 to 255)"
                }
              }
            }, 
            vb:column{
              spacing=-3,
              vb:space{height=4},
              vb:row{
                vb:space{width=3},
                vb:column{
                  spacing=-3,
                  vb:button{
                    id="ASC_BT_SFX_INSERT_"..step,
                    height=15,
                    width=21,
                    bitmap="ico/mini_insert_ico.png",
                    notifier=function() asc_bt_sfx_insert(step) end,
                    tooltip="Nested lines.\nFill down the effect & amount."
                  },
                  vb:slider{
                    id="ASC_SL_SFX_AMO_"..step,
                    height=102,
                    width=21,
                    min=0,
                    max=255,
                    value=ASC_PREF.initial_amount.value,
                    notifier=function(value)
                      if (vws["ASC_VF_SFX_AMO_"..step].value~=value) then
                        vws["ASC_VF_SFX_AMO_"..step].value=value
                      end
                    end,
                    tooltip=""
                  },
                  vb:text{
                    height=ASC_VB_HEIGHT_0,
                    width=19,
                    align="center",
                    text="A"
                  }
                }
              }
            }
          }
        }
      }
    },
    vb:bitmap{
      id="ASC_STEP_MARK_"..step,
      visible=false,
      active=false,
      height=194,
      width=135,
      bitmap="ico/marker_green_ico.png",
    }
  }
end



--steps marker
local ASC_POS_LINE=0
local ASC_POS_MARKER={
  false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false
}
local function asc_marker_rem_timer()
  if rnt:has_timer(asc_marker_rem_timer) then
    rnt:remove_timer(asc_marker_rem_timer)
  end
  for step=1,32 do
    if (ASC_POS_MARKER[step]) then
      vws["ASC_STEP_MARK_"..step].visible=false
      vws["ASC_STEP_MARK_SWITCHES_"..step].visible=false
      ASC_POS_MARKER[step]=false
    end
  end
end


local function asc_marker()
  local tpl=song.transport.playback_pos.line
  if (ASC_POS_LINE~=tpl) then
    ASC_POS_LINE=tpl
    for step=1,32 do
      if ASC_POS_LINE==ASC_STEP.LNE_A[step] then
        --print(ASC_STEP.LNE_A[step])
        vws["ASC_STEP_MARK_"..step].visible=true
        vws["ASC_STEP_MARK_SWITCHES_"..step].visible=true
        ASC_POS_MARKER[step]=true
        if not rnt:has_timer(asc_marker_rem_timer) then
          rnt:add_timer(asc_marker_rem_timer,150)
        end
      end
    end
  end
end

local ASC_MARKER=false
local function asc_bt_marker()
  if (ASC_MARKER) then
    if rnt:has_timer(asc_marker) then
      rnt:remove_timer(asc_marker)
    end
    vws.ASC_BT_MARKER.color=ASC_CLR.DEFAULT
    ASC_MARKER=false
    asc_status_bar_on(3000,13,"",0)
  else
    asc_distribute_lns(1,32)
    if not rnt:has_timer(asc_marker) then
      rnt:add_timer(asc_marker,5)
    end
    vws.ASC_BT_MARKER.color=ASC_CLR.MARKER
    ASC_MARKER=true
    asc_status_bar_on(3000,14,"",0)
  end
  if (vws.ASC_CL_PANEL_3.visible) then asc_info_panel() end
end



--show/hide edit profile panel
local function asc_edit_profile(bol)
  if not (vws.ASC_RW_EDIT_PROFILE.visible==bol) then
    vws.ASC_RW_EDIT_PROFILE.visible=bol
    vws.ASC_BT_EDIT_PROFILE_SUBPANEL.visible=not bol
    vws.ASC_BT_WRITE_NAME_PROFILE.visible=bol
    vws.ASC_BT_REMOVE_SELECTED_PROFILE.visible=bol
  end
  if (bol) then
    vws.ASC_TF_SAVE_PROFILE.edit_mode=bol
    vws.ASC_PP_SELECT_PROFILE_DIRECTORY.width=115
    vws.ASC_PP_SELECT_PROFILE_FILE.width=115
  else
    vws.ASC_PP_SELECT_PROFILE_DIRECTORY.width=152
    vws.ASC_PP_SELECT_PROFILE_FILE.width=152
    ---
    vws.ASC_BT_FOLDER_PROFILE.bitmap="ico/file_ico.png"
    ASC_FOLDER_PROFILE=true
    vws.ASC_PP_SELECT_PROFILE_FILE.active=true
    vws.ASC_BT_WRITE_NAME_PROFILE.active=true
    vws.ASC_TF_SAVE_PROFILE.text=""    
  end
end



--show/hide edit main folder profile panel
local function asc_edit_main_subfolder_profile(bol)
  if not (vws.ASC_RW_EDIT_MAIN_FOLDER_PROFILE.visible==bol) then
    vws.ASC_RW_EDIT_MAIN_FOLDER_PROFILE.visible=bol
    vws.ASC_BT_EDIT_MAIN_FOLDER_PROFILE.visible=not bol
    vws.ASC_BT_REMOVE_SELECTED_MAIN_FOLDER_PROFILE.visible=bol
  end
  if (bol) then
    vws.ASC_TF_SAVE_MAIN_FOLDER_PROFILE.edit_mode=bol
  else
    vws.ASC_TF_SAVE_MAIN_FOLDER_PROFILE.text=""
  end
end



--test -----------------------------------------------------------------------
--[[
class "Asc_Test"
function Asc_Test:__init()
  self.cnt={}
end
]]

--Asc_Test().cnt
--ASC_NESTED_LINES_TBL={}
local function asc_test()
end
--test -----------------------------------------------------------------------



--steps gui
local function asc_steps()
  local content=vb:column{
    spacing=4,
    vb:row{
      id="ASC_RW_PANEL_1",
      spacing=4,
      vb:row{
        vb:row{
          spacing=-29,
          vb:button{
            id="ASC_BT_MST",
            height=ASC_VB_HEIGHT_2,
            width=29,
            text="M",
            notifier=function() asc_mst_on_off() end,
            tooltip="Enable/disable the Master Step.\nThe Master Step works with all Note Steps displayed."
          },
          vb:bitmap{
            active=false,
            height=8,
            width=8,
            mode="plain",
            bitmap="ico/tab_switch_ico.png"
          }
        },
        vb:row{
          spacing=-2,
          vb:row{
            spacing=-26,
            vb:valuebox{
              id="ASC_VB_STEPS",
              height=ASC_VB_HEIGHT_2,
              width=67,
              min=1,--2,--4,
              max=32,
              value=ASC_PREF.note_steps.value,
              tostring=function(value) return ("%.d"):format(value) end,
              tonumber=function(value) return tonumber(value) end,
              notifier=function(value) asc_steps_visible(value) asc_distribute_lns(1,32) end,
              tooltip="Maximum number of Note Steps (1 to 32).\nThe Note Steps range = 1 to this maximum number."
            },
            vb:bitmap{
              height=ASC_VB_HEIGHT_2,
              active=false,
              width=26,
              mode="body_color",
              bitmap="ico/steps_ico.png"
            }
          },
          vb:popup{
            id="ASC_PP_SELECT",
            height=ASC_VB_HEIGHT_2,
            width=88,
            value=1,
            items={" All Sel."," Odd Sel."," Even Sel."," Custom Sel.", " Profile"},
            notifier=function(value) asc_steps_selector(value) end,
            tooltip="Steps Selector"
          },
          vb:row{
          spacing=-29,
            vb:button{
              id="ASC_BT_MARKER",
              height=ASC_VB_HEIGHT_2,
              width=29,
              bitmap="ico/chrono_ico.png",
              notifier=function() asc_bt_marker() asc_play_loop_on_off() end,
              tooltip="Enable/disable the Steps Marker.\n"..
                      "The marker will always loop from Start Line."
            },
            vb:bitmap{
              active=false,
              height=8,
              width=8,
              bitmap="ico/tab_switch_ico.png"
            }
          }
        }
      },
      vb:row{
        spacing=-2,
        vb:row{
          margin=1,
          vb:row{
            style="plain",
            vb:valuefield{
              id="ASC_VF_START_LNE",
              height=ASC_VB_HEIGHT_1,
              width=27,
              align="center",
              min=1,
              max=100,
              value=1,
              tostring=function(value) return ("%.2d"):format(value-1) end,
              tonumber=function(value) if tonumber(value) then return tonumber(value)+1 end end,
              tooltip="Start Line.\nNumber of lines to start inserting steps."
            }
          }
        },
        vb:column{
          spacing=-3,
          vb:button{
            id="ASC_BT_START_LNE_UP",
            height=13,
            width=29,
            bitmap="ico/mini_up_ico.png",
            pressed=function() asc_up_start_lne_repeat() end,
            released=function() asc_up_start_lne_repeat(true) end,
            --notifier=function() asc_up_start_lne_repeat() end,
            tooltip="Up the start line."
          },
          vb:button{
            id="ASC_BT_START_LNE_DOWN",
            height=13,
            width=29,
            bitmap="ico/mini_down_ico.png",
            pressed=function() asc_down_start_lne_repeat() end,
            released=function() asc_down_start_lne_repeat(true) end,
            --notifier=function() asc_down_start_lne() end,
            tooltip="Down the start line."
          }
        }
      },
      vb:row{
        spacing=-2,
        vb:row{
          spacing=-29,
          vb:button{
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/charge_ico.png",
            notifier=function() asc_import_nc(32) end,
            tooltip="Import data from the selected note column of track.\n"..
                "  ⚫[Click] Import data starting from the first line.\n"..
                "  ⚫[SHIFT Click] Import data starting from the current line.\n"..
                "[Back] & [SHIFT Back]."
          },
          vb:bitmap{
            mode="transparent",
            active=false,
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/button_yellow_ico.png",
          }
        },
        vb:row{
          spacing=-45,
          vb:button{
            id="ASC_BT_INSERT_STEPS_AUTO_GROUND",
            height=ASC_VB_HEIGHT_2,
            width=45,
            bitmap="ico/apply_ico.png",
            notifier=function() asc_write_all(1,true) end,
            tooltip="Insert Note Steps or Auto Grown Sequence\n"..
                    "  ⚫[Click] \"Normal Insertion\" the Note Steps starting from the first line.\n"..
                    "  ⚫[SHIFT Click] \"Normal Insertion\" of the Note Steps starting from the current line.\n"..
                    "  ⚫[CRTL Click] \"Continuous Insertion\" of the Note Steps starting from the current line.\n"..
                    "  ⚫[CRTL ALT Click] \"Reverse Insertion\" of the Note Steps starting from the current line.\n\n"..
                    "  ⚫[CTRL SHIFT Click] Enable/disable \"Auto Grown Sequence\". Always include a pattern at the end.\n"..
                    "[Insert], [SHIFT Insert], [CTRL Insert] & [CTRL ALT Insert].    [CTRL SHIFT Insert]"
            
          },
          vb:bitmap{
            mode="transparent",
            active=false,
            height=ASC_VB_HEIGHT_2,
            width=45,
            bitmap="ico/button_green_ico.png",
          }
        },
        vb:row{
          spacing=-29,
          vb:button{
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/clear_data_ico.png",
            notifier=function() asc_clear_all() end,
            tooltip="Clear steps in note column/effect column.\n"..
                    "  ⚫[Click] Clear all the steps of the range starting from the first line.\n"..
                    "  ⚫[SHIFT Click] Clear all the steps of the range starting from the current line.\n"..
                    "  ⚫[ALT Click] Clear the steps of the range except the lines with notes.\n"..
                    "  ⚫[CTRL Click] Clear all the note column/effect column starting from the current line.\n"..
                    "  ⚫[CTRL SHIFT Click] Clear all the visible note columns/effect columns starting from the current line.\n"..
                    "[Delete], [SHIFT Delete], [ALT Delete], [CTRL Delete] & [CTRL SHIFT Delete]."
          },
          vb:bitmap{
            mode="transparent",
            active=false,
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/button_red_ico.png",
          }
        },
        vb:column{
          spacing=-3,
          vb:button{
            height=13,
            width=29,
            bitmap="ico/mini_up_ico.png",
            pressed=function() asc_transpose_up_repeat() end,
            released=function() asc_transpose_up_repeat(true) end,
            --notifier=function() asc_transpose_up() end,
            tooltip="Transpose up the selected Note Steps when the Edit Mode is enabled.\n[Prior]"
          },
          vb:button{
            height=13,
            width=29,
            bitmap="ico/mini_down_ico.png",
            pressed=function() asc_transpose_down_repeat() end,
            released=function() asc_transpose_down_repeat(true) end,
            --notifier=function() asc_transpose_down() end,
            tooltip="Transpose down the selected Note Steps when the Edit Mode is enabled.\n[Next]"
          }
        }
      },
      vb:row{
        spacing=-29,
        vb:button{
          id="ASC_BT_SHOW_RANDOM_PNL",
          height=ASC_VB_HEIGHT_2,
          width=29,
          bitmap="ico/random_ico.png",
          notifier=function() asc_show_rdm_pnl() end,
          tooltip="Show/hide the Random Panel."
        },
        vb:bitmap{
          active=false,
          height=8,
          width=8,
          bitmap="ico/tab_switch_ico.png"
        }
      },
      vb:row{
        id="ASC_RACK_1",
        visible=false,
        vb:column{
          id="ASC_CL_PANEL_2",
          visible=false,
          vb:row{
            style="group",
            margin=2,
            vb:bitmap{
              id="ASC_BP_RND_ICO",
              height=ASC_VB_HEIGHT_0,
              --active=false,
              width=26,
              mode="body_color",
              bitmap="ico/random_ico.png",
              notifier=function() asc_change_rdm_op() end,
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=45,
              align="right",
              text="From/To",
            },
            vb:row{
              spacing=-2,
              vb:valuebox{
                id="ASC_VB_RND_STEP_MIN",
                height=ASC_VB_HEIGHT_0,
                width=53,
                min=1,
                max=32,
                value=1,
                tostring=function(value) return ("%.d"):format(value) end,
                tonumber=function(value) return tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_STEP_MAX.value<value) then
                    vws.ASC_VB_RND_STEP_MAX.value=value
                  end
                end,
                tooltip="Minimum Note Step range."
              },
              vb:valuebox{
                id="ASC_VB_RND_STEP_MAX",
                height=ASC_VB_HEIGHT_0,
                width=53,
                min=1,
                max=32,
                value=4,
                tostring=function(value) return ("%.d"):format(value) end,
                tonumber=function(value) return tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_STEPS.value~=value) then
                    if (value>=2) then
                      vws.ASC_VB_STEPS.value=value
                    else
                      vws.ASC_VB_STEPS.value=2
                    end
                  end
                  if (vws.ASC_VB_RND_STEP_MIN.value>value) then
                    vws.ASC_VB_RND_STEP_MIN.value=value
                  end
                end,
                tooltip="Maximum Note Step range."
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=39,
              align="right",
              text="Value"
            },
            vb:row{
              spacing=-2,
              vb:popup{
                id="ASC_PP_RND_VALUE",
                --active=false,
                height=ASC_VB_HEIGHT_0,
                width=109,
                items={" Note"," Instrument"," Volume"," Panning"," Delay"," FX Amount"," Lines"},
                value=1,
                notifier=function(value) asc_rnd_select_value_type(value) asc_update_rdm_ico(ASC_CHANGE_RDM_OP["VAL"][value]) end,
                tooltip="Value type to randomize."
              },
              vb:row{
                spacing=-23,
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_1",
                  active=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(1) end,
                  --tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_2",
                  visible=false,
                  active=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(2) end,
                  --tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_3",
                  visible=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(3) end,
                  tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_4",
                  visible=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(4) end,
                  tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_5",
                  visible=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(5) end,
                  tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_6",
                  visible=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(6) end,
                  tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:button{
                  id="ASC_BT_RND_FILL_DOWN_7",
                  visible=false,
                  active=false,
                  height=ASC_VB_HEIGHT_0,
                  width=23,
                  bitmap="ico/mini_insert_ico.png",
                  notifier=function() asc_rnd_fill_down_on_off(7) end,
                  --tooltip="Nested lines.\nEnable/disable the fill down values."
                },
                vb:bitmap{
                  active=false,
                  height=8,
                  width=8,
                  bitmap="ico/tab_switch_ico.png"
                }
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=53,
              align="right",
              text="Min/Max",
            },
            vb:row{
              spacing=-2,
              vb:valuebox{
                id="ASC_VB_RND_MIN_1",
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=120,
                value=36,
                tostring=function(value) return asc_note_tostring(value) end,
                tonumber=function(value) return asc_note_tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_1.value<value) then
                    vws.ASC_VB_RND_MAX_1.value=value
                  end
                end,
                tooltip="Minimum Note Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_2",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=254,
                value=0,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_2.value<value) then
                    vws.ASC_VB_RND_MAX_2.value=value
                  end
                end,
                tooltip="Minimum Instrument Index"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_3",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=127,
                value=64,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_3.value<value) then
                    vws.ASC_VB_RND_MAX_3.value=value
                  end
                end,
                tooltip="Minimum Volume Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_4",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=128,
                value=32,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_4.value<value) then
                    vws.ASC_VB_RND_MAX_4.value=value
                  end
                end,
                tooltip="Minimum Panning Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_5",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=255,
                value=1,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_5.value<value) then
                    vws.ASC_VB_RND_MAX_5.value=value
                  end
                end,
                tooltip="Minimum Delay Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_6",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=255,
                value=0,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_6.value<value) then
                    vws.ASC_VB_RND_MAX_6.value=value
                  end
                end,
                tooltip="Minimum FX Amount"
              },
              vb:valuebox{
                id="ASC_VB_RND_MIN_7",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=1,
                max=99,
                value=1,
                tostring=function(value) return ("%.2d"):format(value) end,
                tonumber=function(value) return tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MAX_7.value<value) then
                    vws.ASC_VB_RND_MAX_7.value=value
                  end
                end,
                tooltip="Minimum Lines for the Note Duration"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_1",
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=120,
                value=59,
                tostring=function(value) return asc_note_tostring(value) end,
                tonumber=function(value) return asc_note_tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_1.value>value) then
                    vws.ASC_VB_RND_MIN_1.value=value
                  end
                end,
                tooltip="Maximum Note Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_2",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=254,
                value=8,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_2.value>value) then
                    vws.ASC_VB_RND_MIN_2.value=value
                  end
                end,
                tooltip="Maximum Instrument Index"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_3",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=127,
                value=127,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_3.value>value) then
                    vws.ASC_VB_RND_MIN_3.value=value
                  end
                end,
                tooltip="Maximum Volume Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_4",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=128,
                value=96,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_4.value>value) then
                    vws.ASC_VB_RND_MIN_4.value=value
                  end
                end,
                tooltip="Maximum Panning Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_5",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=255,
                value=64,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_5.value>value) then
                    vws.ASC_VB_RND_MIN_5.value=value
                  end
                end,
                tooltip="Maximum Delay Value"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_6",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=0,
                max=255,
                value=127,
                tostring=function(value) return ("%.2X"):format(value) end,
                tonumber=function(value) return tonumber(value,16) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_6.value>value) then
                    vws.ASC_VB_RND_MIN_6.value=value
                  end
                end,
                tooltip="Maximum FX Amount"
              },
              vb:valuebox{
                id="ASC_VB_RND_MAX_7",
                visible=false,
                height=ASC_VB_HEIGHT_0,
                width=59,
                min=1,
                max=99,
                value=4,
                tostring=function(value) return ("%.2d"):format(value) end,
                tonumber=function(value) return tonumber(value) end,
                notifier=function(value)
                  if (vws.ASC_VB_RND_MIN_7.value>value) then
                    vws.ASC_VB_RND_MIN_7.value=value
                  end
                end,
                tooltip="Maximum Lines for the Note Duration"
              }
            },
            vb:row{
              spacing=-35,
              vb:button{
                height=ASC_VB_HEIGHT_0,
                width=35,
                bitmap="ico/apply_ico.png",
                notifier=function() asc_random_values() end,
                tooltip="Randomize the steps range of the selected value type.\n"..
                        "To randomize, first activate the Edit Mode of pattern editor! For all value types except \"lines\":\n"..
                        "  ⚫[Click] (green/blue) Insert only the selected value type starting from the first line.\n"..
                        "  ⚫[SHIFT Click] (green) Insert the value type starting from the current line.\n"..
                        "  ⚫[ALT Click] (green) Insert all full Note Steps starting from the current line.\n"..
                        "  ⚫[ALT Click] (blue) Insert all full Note Steps starting from first line for \"auto grown sequence\"."
              },
              vb:bitmap{
                id="ASC_BM_RDM",
                mode="transparent",
                active=false,
                height=ASC_VB_HEIGHT_0,
                width=35,
                bitmap="ico/button_green2_ico.png",
              }
            }
          }
        }
      },
      vb:row{
        spacing=-2,
        vb:button{
          height=ASC_VB_HEIGHT_2,
          width=29,
          bitmap="ico/undo_ico.png",
          notifier=function() asc_undo() end,
          tooltip="Undo\n[CTRL Z]"
        },
        vb:button{
          height=ASC_VB_HEIGHT_2,
          width=29,
          bitmap="ico/redo_ico.png",
          notifier=function() asc_redo() end,
          tooltip="Redo\n[CTRL Y]"
        }
      },
      vb:row{
        spacing=-2,
        vb:row{
          spacing=-29,
          vb:button{
            id="ASC_BT_COMPACT",
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/compact_on_ico.png",
            notifier=function() asc_compact() end,
            tooltip="Compact window.\nShow/hide the Steps panels."
          },
          vb:bitmap{
            active=false,
            height=8,
            width=8,
            bitmap="ico/tab_switch_ico.png"
          }
        },
        vb:row{
          spacing=-29,
          vb:button{
            id="ASC_BT_INFO",
            height=ASC_VB_HEIGHT_2,
            width=29,
            bitmap="ico/preferences_ico.png",
            notifier=function() asc_info_panel() end,
            tooltip=("Show/hide \"Preferences\", \"Profile\", \"Keyboard Commands\" & \"About %s\"."):format(asc_main_title)
          },
          vb:bitmap{
            active=false,
            height=8,
            width=8,
            bitmap="ico/tab_switch_ico.png"
          }
        },
        vb:button{
          visible=false, --true
          height=ASC_VB_HEIGHT_2,
          width=29,
          text="Test",
          notifier=function() asc_test() end,
        }
      }
    },
    vb:row{
      id="ASC_RACK_3",
      visible=false,
      spacing=4,
      vb:column{
        id="ASC_SUBRACK_3",
        style="group",
        margin=2,
        spacing=-3,
        vb:row{
          id="ASC_RACK_01_16",
          asc_add_sel_01_16(),
          asc_add_sel_17_32()
        },
        vb:row{
          id="ASC_RACK_17_32",          
        }
      },
      vb:column{
        id="ASC_RACK_4",
        visible=false,
        style="group",
        margin=2,
        spacing=-3,
      }
    },
    vb:row{
      id="ASC_RACK_5",
      visible=false,
      style="group",
      margin=2,
      vb:text{
        height=ASC_VB_HEIGHT_0,
        width=45,
        align="right",
        text="Profile",
      },
      vb:row{
      spacing=-2,
        vb:popup{
          id="ASC_PP_SELECT_PROFILE_DIRECTORY",
          height=ASC_VB_HEIGHT_0,
          width=152,
          notifier=function()
            asc_pp_preload_list_profile()
            if (not vws.ASC_RW_EDIT_PROFILE.visible) then ASC_PROFILE_BYPASS=false asc_load_profile() ASC_PROFILE_BYPASS=true end
            if (ASC_SAVE_PROFILE_BYPASS) and (vws.ASC_CHB_INSERT_STEPS.value) then
              if (ASC_PREF.hide_sub_columns.value) then
                ASC_VISIBLE_SUB_COLUMN_BYPASS=false
                asc_write_all(1,true)
                ASC_VISIBLE_SUB_COLUMN_BYPASS=true
              else
                asc_write_all(1,true)
              end
            end
          end,
          tooltip="Subfolders XML profiles list (Instrument Type).\nSelect a subfolder to load your XML profiles."
        },
        vb:row{
          spacing=-3,
          vb:popup{
            id="ASC_PP_SELECT_PROFILE_FILE",
            height=ASC_VB_HEIGHT_0,
            width=152,
            notifier=function() asc_select_profile_file() end,
            tooltip="XML profiles list.\nSelect a profile to insert steps."
          },
          vb:button{
            id="ASC_BT_WRITE_NAME_PROFILE",
            visible=false,
            height=ASC_VB_HEIGHT_0,
            width=24,
            bitmap="ico/mini_arrow_right_ico.png",
            notifier=function() asc_write_name_profile() end,
            tooltip="Write the name profile to edit it."
          }
        },
        vb:button{
          id="ASC_BT_REMOVE_SELECTED_PROFILE",
          visible=false,
          height=ASC_VB_HEIGHT_0,
          width=24,
          bitmap="ico/clear_data_ico.png",
          notifier=function() asc_remove_profile() asc_pp_preload_list_profile() end,
          tooltip="Remove selected profile."
        },
      },
      -------------
      vb:row{
        id="ASC_RW_EDIT_PROFILE",
        visible=false,
        vb:text{
          height=ASC_VB_HEIGHT_0,
          width=37,
          align="right",
          text="Edit"
        },
        vb:row{
          spacing=-24,
          vb:button{
            id="ASC_BT_FOLDER_PROFILE",
            height=ASC_VB_HEIGHT_0,
            width=24,
            bitmap="ico/file_ico.png",
            notifier=function() asc_open_profile_folder() end,
            tooltip="Switch between file or folder.\n"..
                    "  ⚫[CTRL Click] Open the selected folder."
          },
          vb:bitmap{
            active=false,
            height=8,
            width=8,
            mode="plain",
            bitmap="ico/tab_switch_ico.png"
          }
        },
        vb:textfield{
          id="ASC_TF_SAVE_PROFILE",
          height=ASC_VB_HEIGHT_0,
          width=123,
          text="",
          notifier=function(text) asc_tf_save_profile(text,"ASC_TF_SAVE_PROFILE") end,
          tooltip="Insert a name to add a new profile.\nPlease, use simple names without strange characters!"
        },
        vb:space{width=2},
        vb:row{
          spacing=-2,
          vb:button{
            height=ASC_VB_HEIGHT_0,
            width=24,
            bitmap="ico/save_ico.png",
            notifier=function() asc_save_profile() asc_pp_preload_list_profile() ASC_SAVE_PROFILE_BYPASS=false asc_autoselect_profile() ASC_SAVE_PROFILE_BYPASS=true end,
            tooltip="Save a new profile or folder & update the XML profile list."
          },
          vb:button{
            height=ASC_VB_HEIGHT_0,
            width=24,
            bitmap="ico/close_ico.png",
            notifier=function() asc_edit_profile(false) end,
            tooltip="Close edit profile panel."
          }
        }
      },
      vb:row{
        id="ASC_BT_EDIT_PROFILE_SUBPANEL",
        vb:button{
          height=ASC_VB_HEIGHT_0,
          width=46,
          text="Edit",
          notifier=function() asc_edit_profile(true) end,
          tooltip="Show edit profile panel."
        },
        asc_bt_select_profiles(8),
        vb:row{
          spacing=-24,
          vb:button{
            id="ASC_BT_PROFILE_CAPTURE_INS",
            height=ASC_VB_HEIGHT_0,          
            width=24,
            color=ASC_CLR.MARKER,
            bitmap="ico/instrument_capture_ico.png",
            notifier=function() asc_bt_profile_capture_ins() end,
            tooltip="Enable/disable the instrument capture for the selected profile.\n"..
                    "  ⚫Disabled: use the instrument index values of the profile.\n"..
                    "  ⚫Enabled: use the instrument index value selected inside the instrument box."
          },
          vb:bitmap{
            active=false,
            height=8,
            width=8,
            mode="plain",
            bitmap="ico/tab_switch_ico.png"
          }
        }
      }
      ---------------
    },
    vb:row{
      id="ASC_RACK_2",
      visible=false,
    },
    vb:column{
      id="ASC_CL_PANEL_1",
      spacing=4,
      vb:row{
        id="ASC_RW_PANEL_STEPS_1",
        spacing=4
      },
      vb:horizontal_aligner{
        id="ASC_RW_PANEL_STEPS_9",
        spacing=4
      },
      vb:row{
        id="ASC_RW_PANEL_STEPS_17",
        spacing=4
      },
      vb:row{
        id="ASC_RW_PANEL_STEPS_25",
        spacing=4
      }
    }
  }
  vws.ASC_RW_PANEL_STEPS_1:add_child(Asc_Step(0).cnt)
  vws.ASC_STEP_PNL_0.visible=false
  vws.ASC_TX_STEP_NAME_0.text="Master"
  vws.ASC_MP_JUMP_STEP_0.tooltip="Jump to first step."
  for step=1,8 do
    vws.ASC_RW_PANEL_STEPS_1:add_child(Asc_Step(step).cnt)
  end
  for step=9,16 do
    vws.ASC_RW_PANEL_STEPS_9:add_child(Asc_Step(step).cnt)
  end
  for step=17,24 do
    vws.ASC_RW_PANEL_STEPS_17:add_child(Asc_Step(step).cnt)
  end
  for step=25,32 do
    vws.ASC_RW_PANEL_STEPS_25:add_child(Asc_Step(step).cnt)
  end
  vws.ASC_STEP_MARK_0.bitmap="ico/marker_red_ico.png"
  vws.ASC_STEP_MARK_0.visible=true
  asc_steps_visible(vws.ASC_VB_STEPS.value)
  vws.ASC_BT_LNS_UP_0.tooltip="Up LNS Value\n  ⚫[Click] Up lines.\n  ⚫[ALT Click] Up lines & auto-adjust the number of lines of the pattern."
  vws.ASC_BT_LNS_DOWN_0.tooltip="Down LNS Value\n  ⚫[Click] Down lines.\n  ⚫[ALT Click] Down lines & auto-adjust the number of lines of the pattern."
  --asc_select_visible(vws.ASC_PP_SELECT.value) 
  return content
end



local function asc_swt_info(value)
  if (value==1) then
    vws.ASC_CL_INFO_4.visible=false
    vws.ASC_CL_INFO_3.visible=false
    vws.ASC_CL_INFO_2.visible=false
    vws.ASC_CL_INFO_1.visible=true
  elseif (value==2) then
    vws.ASC_CL_INFO_4.visible=false
    vws.ASC_CL_INFO_3.visible=false
    vws.ASC_CL_INFO_1.visible=false
    vws.ASC_CL_INFO_2.visible=true
  elseif (value==3) then
    vws.ASC_CL_INFO_4.visible=false
    vws.ASC_CL_INFO_2.visible=false
    vws.ASC_CL_INFO_1.visible=false
    vws.ASC_CL_INFO_3.visible=true
  elseif (value==4) then
    vws.ASC_CL_INFO_3.visible=false
    vws.ASC_CL_INFO_2.visible=false
    vws.ASC_CL_INFO_1.visible=false
    vws.ASC_CL_INFO_4.visible=true
  end
end



local function asc_pref_change_properties(value)
  if (value) then
    vws.ASC_CHB_BPM_LPB.active=true
    vws.ASC_CHB_CHANGE_NOL.active=true
    vws.ASC_CHB_HIDE_SUB_COLUMNS.active=true
    vws.ASC_CHB_NOTE_COLUMN_NAME.active=true
  else
    vws.ASC_CHB_BPM_LPB.active=false
    vws.ASC_CHB_CHANGE_NOL.active=false
    vws.ASC_CHB_HIDE_SUB_COLUMNS.active=false
    vws.ASC_CHB_NOTE_COLUMN_NAME.active=false
  end
end



local function asc_info()
  local content=vb:column{
    id="ASC_CL_PANEL_3",
    visible=false,
    vb:column{
      spacing=3,
      vb:switch{
        height=ASC_VB_HEIGHT_0,
        width=552,
        items={"Preferences","Profile","Key Commands","About"},
        notifier=function(value) asc_swt_info(value) end
      },
      vb:column{
        id="ASC_CL_INFO_1",
        spacing=3,
        vb:column{
          style="group",
          margin=3,
          vb:horizontal_aligner{
            mode="center",
            vb:text{
              height=ASC_VB_HEIGHT_0,
              style="strong",
              font="bold",
              text="General Preferences",
            }
          },
          vb:text{
            style="strong",
            text="Initial Configuration"
          },
          vb:row{
            vb:valuebox{
              height=ASC_VB_HEIGHT,
              width=59,
              min=1,--2,
              max=32,
              tostring=function(value) return ("%d"):format(value) end,
              tonumber=function(value) return tonumber(value) end,
              value=ASC_PREF.note_steps.value, --4
              bind=ASC_PREF.note_steps
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=487,
              text="STEPS. maximum number of note steps when restarting (1 to 32, default: 4)."
            }
          },
          vb:row{
            vb:valuebox{
              height=ASC_VB_HEIGHT,
              width=59,
              min=0,
              max=119,
              tostring=function(value) return asc_note_tostring(value) end,
              tonumber=function(value) return asc_note_tonumber(value) end,
              value=ASC_PREF.initial_note.value, --48 (C-4)
              bind=ASC_PREF.initial_note
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=487,
              text="NOTE. Note for all steps when restarting (C-0 to B-9, default C-4)."
            }
          },
          vb:row{
            vb:valuebox{
              height=ASC_VB_HEIGHT,
              width=59,
              min=1,
              max=99,
              tostring=function(value) return ("%d"):format(value) end,
              tonumber=function(value) return tonumber(value) end,
              value=ASC_PREF.nol_top_note.value, --4
              bind=ASC_PREF.nol_top_note
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=487,
              text="LNS. Number of lines of the current step (1 to 99, default: 4)."
            }
          },
          vb:row{
            vb:valuebox{
              height=ASC_VB_HEIGHT,
              width=59,
              min=0,
              max=99,
              tostring=function(value) return ("%d"):format(value) end,
              tonumber=function(value) return tonumber(value) end,
              value=ASC_PREF.nol_note_off.value, --0
              bind=ASC_PREF.nol_note_off
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=487,
              text="OFF. Number of lines of the note-off (0 to 99, default: 0)."
            }
          },
          vb:row{
            vb:text{
              height=ASC_VB_HEIGHT,
              width=61,
              align="right",
              text="Instrument"
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  height=ASC_VB_HEIGHT,
                  width=22,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_instrument.value, --0
                  bind=ASC_PREF.initial_instrument,
                  tostring=function(value) if (value==255) then return "--" else return ("%.2X"):format(value) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(255,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16) end end end,
                  tooltip="Initial Instrument Index\n(00 to FE. FF or \"--\"=empty. Default=00)"
                }
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=47,
              align="right",
              text="Volume"
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  height=ASC_VB_HEIGHT,
                  width=22,
                  align="center",
                  min=0,
                  max=128,
                  value=ASC_PREF.initial_volume.value, --128
                  bind=ASC_PREF.initial_volume,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value-1) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16)+1 end end end,
                  tooltip="Initial Volume Value\n(00 to 7F. \"--\"=empty. Default=7F)"
                }
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=53,
              align="right",
              text="Panning"
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  height=ASC_VB_HEIGHT,
                  width=22,
                  align="center",
                  min=0,
                  max=129,
                  value=ASC_PREF.initial_panning.value, --65
                  bind=ASC_PREF.initial_panning,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value -1) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16)+1 end end end,
                  tooltip="Initial Panning Value\n(00 to 80. \"--\"=empty. Default=40)"
                }
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=43,
              align="right",
              text="Delay"
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  height=ASC_VB_HEIGHT,
                  width=22,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_delay.value, --0
                  bind=ASC_PREF.initial_delay,
                  tostring=function(value) if (value==0) then return "--" else return ("%.2X"):format(value) end end,
                  tonumber=function(value) if (value=="--" or value=="-") then return tonumber(0,16) else if (tonumber(value,16)~=nil) then return tonumber(value,16) end end end,
                  tooltip="Initial Delay Value\n(01 to 255. \"--\"=empty. Default=--)"
                }
              }
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=45,
              align="right",
              text="Effect"
            },
            vb:popup{
              height=ASC_VB_HEIGHT,
              width=52,
              items=ASC_SFX_EFF,
              value=ASC_PREF.initial_effect.value, --19
              bind=ASC_PREF.initial_effect,
              tooltip=("Initial %s\n\n   --: Empty (Default)"):format(ASC_FX_TOOLTIP)
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=51,
              align="right",
              text="Amount"
            },
            vb:row{
              margin=1,
              vb:row{
                style="plain",
                vb:valuefield{
                  height=ASC_VB_HEIGHT,
                  width=22,
                  align="center",
                  min=0,
                  max=255,
                  value=ASC_PREF.initial_amount.value, --0
                  bind=ASC_PREF.initial_amount,
                  tostring=function(value) return ("%.2X"):format(value) end,
                  tonumber=function(value) return tonumber(value,16) end,
                  tooltip="Initial FX Amount Value\n(00 to 255. Default=00)"
                }
              }
            }
          },
          vb:space{
            height=3
          },
          vb:text{
            style="strong",
            text="Insert Steps Options"
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.cap_ins_idx.value, --true
              bind=ASC_PREF.cap_ins_idx
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Auto capture the instrument index within the instrument box before inserting steps."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.continuous_off.value, -- false
              bind=ASC_PREF.continuous_off
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Continuous Insertion: insert the steps from the note-off of the last step to avoid overlap."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.reverse_all.value, -- false
              bind=ASC_PREF.reverse_all
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Reverse Insertion: disable to reverse only the notes. Enable to reverse notes & lines."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.auto_insert_first.value, -- false
              bind=ASC_PREF.auto_insert_first
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Individual Parameters Insertion: auto insert first the steps when the note column is empty."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.insert_nested_lines.value, -- false
              bind=ASC_PREF.insert_nested_lines
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Nested Lines Clipboard: import/insert the nested lines also."
            }
          },
          vb:text{
            style="strong",
            text="Steps Marker Options"
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.mark_loop.value, --false
              bind=ASC_PREF.mark_loop,
              notifier=function(value) if (ASC_MARKER) then asc_play_loop_on_off() end end
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Steps Marker in loop. Repeat the current steps continually."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.mark_play.value, --false
              bind=ASC_PREF.mark_play
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Steps Marker Player. Auto play the current steps for Steps Marker."
            }
          },
          vb:text{
            style="strong",
            text="Steps Selector Options"
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.odd_even_not_clear.value, --false
              bind=ASC_PREF.odd_even_not_clear
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Odd & Even: overlapping insertion. Do not clean unmarked steps when inserting."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.custom_not_clear.value, --false
              bind=ASC_PREF.custom_not_clear
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Custom: overlapping insertion. Do not clean unmarked steps when inserting."
            }
          },
          vb:space{
            height=3
          },
          vb:text{
            style="strong",
            text="Randomization Options"
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.random_fx_param.value, --true
              bind=ASC_PREF.random_fx_param
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Randomize FX Amount: include the FX parameter also."
            }
          },
          vb:row{
            vb:checkbox{
              height=ASC_VB_HEIGHT,
              width=ASC_VB_HEIGHT,
              value=ASC_PREF.random_lines.value, --true
              bind=ASC_PREF.random_lines
            },
            vb:text{
              height=ASC_VB_HEIGHT,
              width=529,
              text="Randomize Lines: include all visible note columns with existent notes."
            }
          }
        }
      },
      vb:column{
        id="ASC_CL_INFO_2",
        visible=false,
        style="group",
        margin=4,
        width=556,
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            height=ASC_VB_HEIGHT_0,
            style="strong",
            font="bold",
            text="Profile Options",
          }
        },
        vb:text{
          style="strong",
          text="Profiles Main Folder"
        },
        vb:row{
          vb:bitmap{
            height=ASC_VB_HEIGHT_0,
            width=16,
            mode="body_color",
            bitmap="ico/folder_p_ico.png",
            notifier=function() 
              local path=("%s/Profiles"):format(os.currentdir())
              if io.exists(path) then
                rna:open_path(path)
              end
            end
          },
          vb:space{
            width=1
          },
          vb:row{
            spacing=-2,
            vb:textfield{
              active=false,
              height=ASC_VB_HEIGHT_0,
              width=69,
              align="right",
              text="../Profiles/ ",
              tooltip="Main folder: \"Profiles\"."
            },
            vb:popup{
              id="ASC_PP_DEFAULT_FOLDER_PROFILES",
              height=ASC_VB_HEIGHT_0,
              width=133,
              notifier=function(value) ASC_PREF.subfolder_profiles.value=vws.ASC_PP_DEFAULT_FOLDER_PROFILES.items[value] asc_pp_preload_list_profile() end,
              tooltip="Main subfolders list (Musical Style).\nSelect a main subfolder to load the subfolders XML profiles."
            },
            vb:button{
              id="ASC_BT_REMOVE_SELECTED_MAIN_FOLDER_PROFILE",
              visible=false,
              height=ASC_VB_HEIGHT_0,
              width=21,
              bitmap="ico/clear_data_ico.png",
              notifier=function() asc_remove_main_subfolder_profile() asc_pp_preload_list_profile() end,
              tooltip="Remove selected main folder profile."
            }
          },
          vb:button{
            id="ASC_BT_EDIT_MAIN_FOLDER_PROFILE",
            height=ASC_VB_HEIGHT_0,
            width=46,
            text="Edit",
            notifier=function() asc_edit_main_subfolder_profile(true) end,
            tooltip="Show edit main subfolder options for profiles."
          },
          vb:row{
            id="ASC_RW_EDIT_MAIN_FOLDER_PROFILE",
            visible=false,
            vb:text{
              height=ASC_VB_HEIGHT_0,
              width=37,
              align="right",
              text="Edit"
            },
            vb:textfield{
              id="ASC_TF_SAVE_MAIN_FOLDER_PROFILE",
              height=ASC_VB_HEIGHT_0,
              width=133,
              text="",
              notifier=function(text) asc_tf_save_profile(text,"ASC_TF_SAVE_MAIN_FOLDER_PROFILE") end,
              tooltip="Insert a name to add a new main subfolder.\nPlease, use simple names without strange characters!"
            },
            vb:space{width=2},
            vb:row{
              spacing=-2,
              vb:button{
                height=ASC_VB_HEIGHT_0,
                width=21,
                bitmap="ico/save_ico.png",
                notifier=function() asc_save_main_subfolder_profile() asc_pp_preload_list_profile() ASC_SAVE_PROFILE_BYPASS=false asc_autoselect_profile() ASC_SAVE_PROFILE_BYPASS=true end,
                tooltip="Save a new main folder profile & update the XML profile list."
              },
              vb:button{
                height=ASC_VB_HEIGHT_0,
                width=21,
                bitmap="ico/close_ico.png",
                notifier=function() asc_edit_main_subfolder_profile(false) end,
                tooltip="Close edit main subfolder panel."
              }
            }
          }
        },
        vb:text{
          style="strong",
          text="Profile Automatic Options"
        },
        vb:row{
          vb:checkbox{
            id="ASC_CHB_LOAD_PROFILE",
            height=ASC_VB_HEIGHT,
            width=ASC_VB_HEIGHT,
            value=ASC_PREF.load_profile.value, --true
            bind=ASC_PREF.load_profile
          },
          vb:text{
            height=ASC_VB_HEIGHT,
            width=527,
            text="Auto load the selected profile when choose \"Profile\" from the \"Steps Selector\"."
          }
        },
        vb:row{
          vb:checkbox{
            id="ASC_CHB_INSERT_STEPS",
            height=ASC_VB_HEIGHT,
            width=ASC_VB_HEIGHT,
            value=ASC_PREF.insert_steps.value, --true
            bind=ASC_PREF.insert_steps,
            notifier=function(value) asc_pref_change_properties(value) end
          },
          vb:text{
            height=ASC_VB_HEIGHT,
            width=527,
            text="Auto insert steps when charging profiles."
          }
        },
        vb:row{
          vb:space{
            width=17
          },
          vb:column{
            vb:row{
              vb:checkbox{
                id="ASC_CHB_BPM_LPB",
                active=false,
                height=ASC_VB_HEIGHT,
                width=ASC_VB_HEIGHT,
                value=ASC_PREF.change_bpm_lpb.value, --false
                bind=ASC_PREF.change_bpm_lpb
              },
              vb:text{
                height=ASC_VB_HEIGHT,
                width=509,
                text="Change the BPM & LPB values of the song when insert profile."
              }
            },
            vb:row{
              vb:checkbox{
                id="ASC_CHB_CHANGE_NOL",
                active=false,
                height=ASC_VB_HEIGHT,
                width=ASC_VB_HEIGHT,
                value=ASC_PREF.change_nol.value, --false
                bind=ASC_PREF.change_nol
              },
              vb:text{
                height=ASC_VB_HEIGHT,
                width=509,
                text="Change the number of lines of the current pattern when insert profile."
              }
            },
            vb:row{
              vb:checkbox{
                id="ASC_CHB_HIDE_SUB_COLUMNS",
                active=false,
                height=ASC_VB_HEIGHT,
                width=ASC_VB_HEIGHT,
                value=ASC_PREF.hide_sub_columns.value, --false
                bind=ASC_PREF.hide_sub_columns
              },
              vb:text{
                height=ASC_VB_HEIGHT,
                width=509,
                text="Change the VOL-PAN-DLY-sFX visible sub-columns of the track when insert profile."
              }
            },
            vb:row{
              vb:checkbox{
                id="ASC_CHB_NOTE_COLUMN_NAME",
                active=false,
                height=ASC_VB_HEIGHT,
                width=ASC_VB_HEIGHT,
                value=ASC_PREF.note_column_name.value, --false
                bind=ASC_PREF.note_column_name
              },
              vb:text{
                height=ASC_VB_HEIGHT,
                width=509,
                text="Change the note column name when insert profile."
              }
            },
          }
        }
      },
      vb:column{
        id="ASC_CL_INFO_3",
        visible=false,
        style="plain",
        margin=4,
        width=492,
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            height=ASC_VB_HEIGHT_0,
            style="strong",
            font="bold",
            text="Keyboard Commands"
          }
        },
        asc_txt_keys()
      },
      vb:column{
        id="ASC_CL_INFO_4",
        visible=false,
        style="plain",
        margin=4,
        width=556,
        vb:horizontal_aligner{
          mode="center",
          vb:text{
            height=ASC_VB_HEIGHT_0,
            style="strong",
            font="bold",
            text="About "..asc_main_title
          }
        },
        vb:row{
          vb:text{
            width=410,
            text=ASC_TXT_INFO
            
          },
          vb:bitmap{
            --height=150,
            --width=150,
            mode="body_color",
            bitmap="ico/logo_asc_ico.png"
          }
        },
      }
    }
  }
  return content
end



local function asc_status_bar()
  local content=vb:text{
    id="ASC_TX_STATUS_BAR",
    visible=false,
    height=ASC_VB_HEIGHT_0,
    width=488,
    style="strong"
  }
  return content
end


--viewbuilder
local function asc_main_content()
  ASC_MAIN_CONTENT=vb:column{
    margin=4,
    spacing=4,
    asc_steps(),
    asc_info(),
    asc_status_bar()
  }
  return ASC_MAIN_CONTENT
end



--initial configuration view
--local function asc_config_ini()
--end



--main dialog
local function asc_main_dialog()
  if (ASC_MAIN_CONTENT==nil) then
    asc_capture_clr_mrk_main()
    asc_main_content()
    asc_pref_change_properties(vws.ASC_CHB_INSERT_STEPS.value)
    asc_pp_preload_list_profile()--asc_save_profile()
    asc_distribute_lns(1,32)
    --asc_config_ini()
  end
  if (ASC_MAIN_DIALOG) and (ASC_MAIN_DIALOG.visible) then ASC_MAIN_DIALOG:show() return end
  local options={send_key_repeat=true,send_key_release=true}
  ASC_MAIN_DIALOG=rna:show_custom_dialog(asc_main_title,ASC_MAIN_CONTENT,asc_keyhandler,options)
end
_AUTO_RELOAD_DEBUG=function() asc_main_dialog() end



local ASC_MENU_NAME_1=("Main Menu:Tools:%s..."):format(asc_main_title)
if not rnt:has_menu_entry(ASC_MENU_NAME_1) then
  rnt:add_menu_entry{
    name=ASC_MENU_NAME_1,
    invoke=function() asc_main_dialog() end
  }
end



local ASC_MENU_NAME_2=("Global:Tools:%s"):format(asc_main_title)
if not rnt:has_keybinding(ASC_MENU_NAME_2) then
  rnt:add_keybinding{
    name=ASC_MENU_NAME_2,
    invoke=function() asc_main_dialog() end
  }
end



--key links
function asc_key_back()
  return asc_import_nc(32)
end

function asc_key_ins()
  return asc_write_all(1,true)
end

function asc_key_del()
  return asc_clear_all()
end

function asc_key_prior(bol)
  return asc_transpose_up_repeat(bol)
end

function asc_key_next(bol)
  return asc_transpose_down_repeat(bol)
end

function asc_nav_step_first_lne()
  return asc_jump_first_lne()
end

function asc_nav_step_last_lne()
  return asc_jump_last_lne()
end

function asc_key_return()
  return asc_steps_nav()
end

function asc_key_rctrl()
  return asc_bt_marker(), asc_play_loop_on_off()
end  
