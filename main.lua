local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local control_example_dialog = nil
local vb = nil;
local cbtns={};
local last_button=nil;

function findstartnote()
   local currentpattern;
   local currentline;
   local li;
   local li2;
   local cadfound=false;
   local nte;
   currentpattern=renoise.song().transport.playback_pos.sequence;
   currentline=renoise.song().selected_line_index;
   while (cadfound==false) and (currentpattern>0) do
    while (cadfound==false) and (currentline>0) do
     nte=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[currentpattern]].tracks[renoise.song().selected_track_index].lines[currentline].note_columns[1].note_value;
     if nte<120 then cadfound=true end;     
      currentline=currentline-1;
     end
    currentpattern=currentpattern-1;
    if currentpattern>0 then currentline=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[currentpattern]].number_of_lines end
   end
   if cadfound==true then
    local noct;
    local ntn; 
      --print(nte);
      noct=math.floor(nte/12);
      ntn=nte-noct*12;
      vb.views.starttone.value=ntn+1;
      vb.views.octave.value=noct; 
   else
      print("no cadences found"); 
   end   

end

function set_interval(interval)

--print(interval);
if last_button==1 then vb.views.c1.color={0,0,0} end;
if last_button==2 then vb.views.c2.color={0,0,0} end;
if last_button==3 then vb.views.c3.color={0,0,0} end;
if last_button==4 then vb.views.c4.color={0,0,0} end;
if last_button==5 then vb.views.c5.color={0,0,0} end;
if last_button==6 then vb.views.c6.color={0,0,0} end;
if last_button==7 then vb.views.c7.color={0,0,0} end;
if last_button==8 then vb.views.c8.color={0,0,0} end;
if last_button==9 then vb.views.c9.color={0,0,0} end;
if last_button==10 then vb.views.c10.color={0,0,0} end;
if last_button==11 then vb.views.c11.color={0,0,0} end;
if last_button==12 then vb.views.c12.color={0,0,0} end;
if last_button==13 then vb.views.c13.color={0,0,0} end;
if last_button==14 then vb.views.c14.color={0,0,0} end;
if last_button==15 then vb.views.c15.color={0,0,0} end;
if last_button==16 then vb.views.c16.color={0,0,0} end;
if last_button==17 then vb.views.c17.color={0,0,0} end;
if last_button==18 then vb.views.c18.color={0,0,0} end;
if last_button==19 then vb.views.c19.color={0,0,0} end;
if last_button==20 then vb.views.c20.color={0,0,0} end;
if last_button==21 then vb.views.c21.color={0,0,0} end;

if interval==0 then vb.views.c1.color={255,255,0}; last_button=1 end;
if interval==-7 then vb.views.c2.color={255,255,0}; last_button=2 end;
if interval==7 then vb.views.c3.color={255,255,0}; last_button=3 end;
if interval==-4 then vb.views.c4.color={255,255,0}; last_button=4 end;
if interval==-5 then vb.views.c5.color={255,255,0}; last_button=5 end;
if interval==5 then vb.views.c6.color={255,255,0}; last_button=6 end;
if interval==4 then vb.views.c7.color={255,255,0}; last_button=7 end;
if interval==-3 then vb.views.c8.color={255,255,0}; last_button=8 end;
if interval==-8 then vb.views.c9.color={255,255,0}; last_button=9 end;
if interval==-9 then vb.views.c10.color={255,255,0}; last_button=10 end;
if interval==-10 then vb.views.c11.color={255,255,0}; last_button=11 end;
if interval==10 then vb.views.c12.color={255,255,0}; last_button=12 end;
if interval==9 then vb.views.c13.color={255,255,0}; last_button=13 end;
if interval==8 then vb.views.c14.color={255,255,0}; last_button=14 end;
if interval==3 then vb.views.c15.color={255,255,0}; last_button=15 end;
if interval==-2 then vb.views.c16.color={255,255,0}; last_button=16 end;
if interval==2 then vb.views.c17.color={255,255,0}; last_button=17 end;
if interval==-1 then vb.views.c18.color={255,255,0}; last_button=18 end;
if interval==1 then vb.views.c19.color={255,255,0}; last_button=19 end;
if interval==-6 then vb.views.c20.color={255,255,0}; last_button=20 end;
if interval==6 then vb.views.c21.color={255,255,0}; last_button=21 end;

local octave
local tone
local note
local set
local newnote
local newoctave
local newtone
local volume;
volume=renoise.song().transport.keyboard_velocity;

octave=vb.views.octave.value;
tone=vb.views.starttone.value-1;
note=octave*12+tone;
newnote=note+interval;
newoctave=math.floor(newnote/12);
newtone=newnote-newoctave*12;

vb.views.octave.value=newoctave;
vb.views.starttone.value=newtone+1;

renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=newnote;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;

end

function test_buttons()
local octave
local tone
local note
local set

octave=vb.views.octave.value;
tone=vb.views.starttone.value-1;
note=octave*12+tone;

-- jesli note plus interwal modulo 12 wypada na zaznaczonym klawiszu to klawisz ma numer w innym wypadku myslnik

set=false;
if math.fmod(note+0,12)==0 and vb.views.s0.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==1 and vb.views.s1.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==2 and vb.views.s2.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==3 and vb.views.s3.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==4 and vb.views.s4.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==5 and vb.views.s5.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==6 and vb.views.s6.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==7 and vb.views.s7.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==8 and vb.views.s8.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==9 and vb.views.s9.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==10 and vb.views.s10.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
if math.fmod(note+0,12)==11 and vb.views.s11.value==true then vb.views.c1.text='0'; set=true else if set==false then vb.views.c1.text='-' end end;
cbtns[1]=set;

set=false;
if math.fmod(note-7,12)==0 and vb.views.s0.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==1 and vb.views.s1.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==2 and vb.views.s2.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==3 and vb.views.s3.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==4 and vb.views.s4.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==5 and vb.views.s5.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==6 and vb.views.s6.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==7 and vb.views.s7.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==8 and vb.views.s8.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==9 and vb.views.s9.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==10 and vb.views.s10.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
if math.fmod(note-7,12)==11 and vb.views.s11.value==true then vb.views.c2.text='-7'; set=true else if set==false then vb.views.c2.text='-' end end;
cbtns[2]=set;

set=false;
if math.fmod(note+7,12)==0 and vb.views.s0.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==1 and vb.views.s1.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==2 and vb.views.s2.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==3 and vb.views.s3.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==4 and vb.views.s4.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==5 and vb.views.s5.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==6 and vb.views.s6.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==7 and vb.views.s7.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==8 and vb.views.s8.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==9 and vb.views.s9.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==10 and vb.views.s10.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if math.fmod(note+7,12)==11 and vb.views.s11.value==true then vb.views.c3.text='+7'; set=true else if set==false then vb.views.c3.text='-' end end;
if note+7>119 then vb.views.c3.text='-'; set=false; end;
cbtns[3]=set;

set=false;
if math.fmod(note-4,12)==0 and vb.views.s0.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==1 and vb.views.s1.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==2 and vb.views.s2.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==3 and vb.views.s3.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==4 and vb.views.s4.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==5 and vb.views.s5.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==6 and vb.views.s6.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==7 and vb.views.s7.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==8 and vb.views.s8.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==9 and vb.views.s9.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==10 and vb.views.s10.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
if math.fmod(note-4,12)==11 and vb.views.s11.value==true then vb.views.c4.text='-4'; set=true else if set==false then vb.views.c4.text='-' end end;
cbtns[4]=set;

set=false;
if math.fmod(note-5,12)==0 and vb.views.s0.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==1 and vb.views.s1.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==2 and vb.views.s2.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==3 and vb.views.s3.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==4 and vb.views.s4.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==5 and vb.views.s5.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==6 and vb.views.s6.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==7 and vb.views.s7.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==8 and vb.views.s8.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==9 and vb.views.s9.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==10 and vb.views.s10.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
if math.fmod(note-5,12)==11 and vb.views.s11.value==true then vb.views.c5.text='-5'; set=true else if set==false then vb.views.c5.text='-' end end;
cbtns[5]=set;

set=false;
if math.fmod(note+5,12)==0 and vb.views.s0.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==1 and vb.views.s1.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==2 and vb.views.s2.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==3 and vb.views.s3.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==4 and vb.views.s4.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==5 and vb.views.s5.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==6 and vb.views.s6.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==7 and vb.views.s7.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==8 and vb.views.s8.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==9 and vb.views.s9.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==10 and vb.views.s10.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if math.fmod(note+5,12)==11 and vb.views.s11.value==true then vb.views.c6.text='+5'; set=true else if set==false then vb.views.c6.text='-' end end;
if note+5>119 then vb.views.c6.text='-'; set=false; end;
cbtns[6]=set;

set=false;
if math.fmod(note+4,12)==0 and vb.views.s0.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==1 and vb.views.s1.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==2 and vb.views.s2.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==3 and vb.views.s3.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==4 and vb.views.s4.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==5 and vb.views.s5.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==6 and vb.views.s6.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==7 and vb.views.s7.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==8 and vb.views.s8.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==9 and vb.views.s9.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==10 and vb.views.s10.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if math.fmod(note+4,12)==11 and vb.views.s11.value==true then vb.views.c7.text='+4'; set=true else if set==false then vb.views.c7.text='-' end end;
if note+4>119 then vb.views.c7.text='-'; set=false; end;
cbtns[7]=set;

set=false;
if math.fmod(note-3,12)==0 and vb.views.s0.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==1 and vb.views.s1.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==2 and vb.views.s2.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==3 and vb.views.s3.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==4 and vb.views.s4.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==5 and vb.views.s5.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==6 and vb.views.s6.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==7 and vb.views.s7.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==8 and vb.views.s8.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==9 and vb.views.s9.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==10 and vb.views.s10.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
if math.fmod(note-3,12)==11 and vb.views.s11.value==true then vb.views.c8.text='-3'; set=true else if set==false then vb.views.c8.text='-' end end;
cbtns[8]=set;

set=false;
if math.fmod(note-8,12)==0 and vb.views.s0.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==1 and vb.views.s1.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==2 and vb.views.s2.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==3 and vb.views.s3.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==4 and vb.views.s4.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==5 and vb.views.s5.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==6 and vb.views.s6.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==7 and vb.views.s7.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==8 and vb.views.s8.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==9 and vb.views.s9.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==10 and vb.views.s10.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
if math.fmod(note-8,12)==11 and vb.views.s11.value==true then vb.views.c9.text='-8'; set=true else if set==false then vb.views.c9.text='-' end end;
cbtns[9]=set;

set=false;
if math.fmod(note-9,12)==0 and vb.views.s0.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==1 and vb.views.s1.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==2 and vb.views.s2.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==3 and vb.views.s3.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==4 and vb.views.s4.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==5 and vb.views.s5.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==6 and vb.views.s6.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==7 and vb.views.s7.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==8 and vb.views.s8.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==9 and vb.views.s9.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==10 and vb.views.s10.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
if math.fmod(note-9,12)==11 and vb.views.s11.value==true then vb.views.c10.text='-9'; set=true else if set==false then vb.views.c10.text='-' end end;
cbtns[10]=set;

set=false;
if math.fmod(note-10,12)==0 and vb.views.s0.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==1 and vb.views.s1.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==2 and vb.views.s2.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==3 and vb.views.s3.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==4 and vb.views.s4.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==5 and vb.views.s5.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==6 and vb.views.s6.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==7 and vb.views.s7.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==8 and vb.views.s8.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==9 and vb.views.s9.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==10 and vb.views.s10.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
if math.fmod(note-10,12)==11 and vb.views.s11.value==true then vb.views.c11.text='-10'; set=true else if set==false then vb.views.c11.text='-' end end;
cbtns[11]=set;

set=false;
if math.fmod(note+10,12)==0 and vb.views.s0.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==1 and vb.views.s1.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==2 and vb.views.s2.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==3 and vb.views.s3.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==4 and vb.views.s4.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==5 and vb.views.s5.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==6 and vb.views.s6.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==7 and vb.views.s7.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==8 and vb.views.s8.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==9 and vb.views.s9.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==10 and vb.views.s10.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if math.fmod(note+10,12)==11 and vb.views.s11.value==true then vb.views.c12.text='+10'; set=true else if set==false then vb.views.c12.text='-' end end;
if note+10>119 then vb.views.c12.text='-'; set=false; end;
cbtns[12]=set;

set=false;
if math.fmod(note+9,12)==0 and vb.views.s0.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==1 and vb.views.s1.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==2 and vb.views.s2.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==3 and vb.views.s3.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==4 and vb.views.s4.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==5 and vb.views.s5.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==6 and vb.views.s6.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==7 and vb.views.s7.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==8 and vb.views.s8.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==9 and vb.views.s9.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==10 and vb.views.s10.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if math.fmod(note+9,12)==11 and vb.views.s11.value==true then vb.views.c13.text='+9'; set=true else if set==false then vb.views.c13.text='-' end end;
if note+9>119 then vb.views.c13.text='-'; set=false; end;
cbtns[13]=set;

set=false;
if math.fmod(note+8,12)==0 and vb.views.s0.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==1 and vb.views.s1.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==2 and vb.views.s2.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==3 and vb.views.s3.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==4 and vb.views.s4.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==5 and vb.views.s5.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==6 and vb.views.s6.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==7 and vb.views.s7.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==8 and vb.views.s8.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==9 and vb.views.s9.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==10 and vb.views.s10.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if math.fmod(note+8,12)==11 and vb.views.s11.value==true then vb.views.c14.text='+8'; set=true else if set==false then vb.views.c14.text='-' end end;
if note+8>119 then vb.views.c14.text='-'; set=false; end;
cbtns[14]=set;

set=false;
if math.fmod(note+3,12)==0 and vb.views.s0.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==1 and vb.views.s1.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==2 and vb.views.s2.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==3 and vb.views.s3.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==4 and vb.views.s4.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==5 and vb.views.s5.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==6 and vb.views.s6.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==7 and vb.views.s7.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==8 and vb.views.s8.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==9 and vb.views.s9.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==10 and vb.views.s10.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if math.fmod(note+3,12)==11 and vb.views.s11.value==true then vb.views.c15.text='+3'; set=true else if set==false then vb.views.c15.text='-' end end;
if note+3>119 then vb.views.c15.text='-'; set=false; end;
cbtns[15]=set;

set=false;
if math.fmod(note-2,12)==0 and vb.views.s0.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==1 and vb.views.s1.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==2 and vb.views.s2.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==3 and vb.views.s3.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==4 and vb.views.s4.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==5 and vb.views.s5.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==6 and vb.views.s6.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==7 and vb.views.s7.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==8 and vb.views.s8.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==9 and vb.views.s9.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==10 and vb.views.s10.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
if math.fmod(note-2,12)==11 and vb.views.s11.value==true then vb.views.c16.text='-2'; set=true else if set==false then vb.views.c16.text='-' end end;
cbtns[16]=set;

set=false;
if math.fmod(note+2,12)==0 and vb.views.s0.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==1 and vb.views.s1.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==2 and vb.views.s2.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==3 and vb.views.s3.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==4 and vb.views.s4.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==5 and vb.views.s5.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==6 and vb.views.s6.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==7 and vb.views.s7.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==8 and vb.views.s8.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==9 and vb.views.s9.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==10 and vb.views.s10.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if math.fmod(note+2,12)==11 and vb.views.s11.value==true then vb.views.c17.text='+2'; set=true else if set==false then vb.views.c17.text='-' end end;
if note+2>119 then vb.views.c17.text='-'; set=false; end;
cbtns[17]=set;

set=false;
if math.fmod(note-1,12)==0 and vb.views.s0.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==1 and vb.views.s1.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==2 and vb.views.s2.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==3 and vb.views.s3.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==4 and vb.views.s4.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==5 and vb.views.s5.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==6 and vb.views.s6.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==7 and vb.views.s7.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==8 and vb.views.s8.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==9 and vb.views.s9.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==10 and vb.views.s10.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
if math.fmod(note-1,12)==11 and vb.views.s11.value==true then vb.views.c18.text='-1'; set=true else if set==false then vb.views.c18.text='-' end end;
cbtns[18]=set;

set=false;
if math.fmod(note+1,12)==0 and vb.views.s0.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==1 and vb.views.s1.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==2 and vb.views.s2.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==3 and vb.views.s3.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==4 and vb.views.s4.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==5 and vb.views.s5.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==6 and vb.views.s6.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==7 and vb.views.s7.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==8 and vb.views.s8.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==9 and vb.views.s9.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==10 and vb.views.s10.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if math.fmod(note+1,12)==11 and vb.views.s11.value==true then vb.views.c19.text='+1'; set=true else if set==false then vb.views.c19.text='-' end end;
if note+1>119 then vb.views.c19.text='-'; set=false; end;
cbtns[19]=set;

set=false;
if math.fmod(note-6,12)==0 and vb.views.s0.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==1 and vb.views.s1.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==2 and vb.views.s2.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==3 and vb.views.s3.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==4 and vb.views.s4.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==5 and vb.views.s5.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==6 and vb.views.s6.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==7 and vb.views.s7.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==8 and vb.views.s8.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==9 and vb.views.s9.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==10 and vb.views.s10.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
if math.fmod(note-6,12)==11 and vb.views.s11.value==true then vb.views.c20.text='-6'; set=true else if set==false then vb.views.c20.text='-' end end;
cbtns[20]=set;

set=false;
if math.fmod(note+6,12)==0 and vb.views.s0.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==1 and vb.views.s1.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==2 and vb.views.s2.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==3 and vb.views.s3.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==4 and vb.views.s4.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==5 and vb.views.s5.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==6 and vb.views.s6.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==7 and vb.views.s7.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==8 and vb.views.s8.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==9 and vb.views.s9.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==10 and vb.views.s10.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if math.fmod(note+6,12)==11 and vb.views.s11.value==true then vb.views.c21.text='+6'; set=true else if set==false then vb.views.c21.text='-' end end;
if note+1>119 then vb.views.c21.text='-'; set=false; end;
cbtns[21]=set;

end

function mainproc()

vb = renoise.ViewBuilder()
  local scale_row = vb:horizontal_aligner {
     mode = "center",
      vb:text{
      text='Scale: '
      }
      ,
      vb:checkbox{--c
       id="s0",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }
     ,
      vb:checkbox{--c#
       id="s1",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--d
       id="s2",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--d#
       id="s3",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--e
       id="s4",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--f
       id="s5",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--f#
       id="s6",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--g
       id="s7",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--g#
       id="s8",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--a
       id="s9",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--a#
       id="s10",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     ,
      vb:checkbox{--b
       id="s11",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
       test_buttons()
       end
      }       
     }
     
  local tone_start_row = vb:horizontal_aligner {
  mode = "center",
  vb:text{
  text='Start tone: '
  },
  vb:popup{
      id = "starttone",
      width = 50,
      value = 1,
      items = {--[["-", ]]"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#" ,"B"},
      notifier = function()
      test_buttons()
      end
  },
  vb:valuebox{
   id="octave",
   min=0,
   max=9,
   value=renoise.song().transport.octave,
   notifier = function()
   test_buttons()
   end  
  },
  vb:button{
  id="scan",
  text='Scan',
     notifier = function()
   findstartnote()
   end  
  },
  vb:button{
  id='drop',
  text='Drop',
  notifier=function()
  local volume;
volume=renoise.song().transport.keyboard_velocity;

renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=vb.views.octave.value*12+vb.views.starttone.value-1;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
  end
  }
  }

local cadences1=vb:horizontal_aligner {
 mode='center',
 vb:button{
 id='c1',
 text='0',
 width=35,
 notifier=function()
 if cbtns[1]==true then
  set_interval(0)
  end 
 end
 }
}
local cadences2=vb:horizontal_aligner {
 mode='center',
 vb:button{
 id='c5',
 text='-5',
 width=35,
 notifier=function()
 if cbtns[5]==true then
  set_interval(-5)
  end 
 end
 },
 vb:button{
 id='c2',
 text='-7',
 width=35,
 notifier=function()
 if cbtns[2]==true then
  set_interval(-7)
  end 
 end
 },
 vb:button{
 id='c3',
 text='+7',
 width=35,
 notifier=function()
 if cbtns[3]==true then
  set_interval(7)
  end 
 end
 },
 vb:button{
 id='c6',
 text='+5',
 width=35,
 notifier=function()
 if cbtns[6]==true then
  set_interval(5)
  end 
 end
 }
}
local cadences3=vb:horizontal_aligner{
  mode='center',
 vb:button{
 id='c20',
 text='-6',
 width=35,
 height=30,
 notifier=function()
 if cbtns[20]==true then
  set_interval(-6)
  end 
 end
 },
 vb:button{
 id='c21',
 text='+6',
 width=35,
 height=30,
 notifier=function()
 if cbtns[21]==true then
  set_interval(6)
  end 
 end
 } 
}
local cadences4=vb:horizontal_aligner {
 mode='center',
 vb:button{
 id='c8',
 text='-3',
 width=35,
 notifier=function()
 if cbtns[8]==true then
  set_interval(-3)
  end 
 end
 },
 vb:button{
 id='c4',
 text='-4',
 width=35,
 notifier=function()
 if cbtns[4]==true then
  set_interval(-4)
  end 
 end
 },
 vb:button{
 id='c9',
 text='-8',
 width=35,
 notifier=function()
 if cbtns[9]==true then
  set_interval(-8)
  end 
 end
 },
 vb:button{
 id='c10',
 text='-9',
 width=35,
 notifier=function()
 if cbtns[10]==true then
  set_interval(-9)
  end 
 end
 },
 vb:button{
 id='c11',
 text='-10',
 width=35,
 notifier=function()
 if cbtns[11]==true then
  set_interval(-10)
  end 
 end
 },
 vb:button{
 id='c12',
 text='+10',
 width=35,
 notifier=function()
 if cbtns[12]==true then
  set_interval(10)
  end 
 end
 },
 vb:button{
 id='c13',
 text='+9',
 width=35,
 notifier=function()
 if cbtns[13]==true then
  set_interval(9)
  end 
 end
 },
 vb:button{
 id='c14',
 text='+8',
 width=35,
 notifier=function()
 if cbtns[14]==true then
  set_interval(8)
  end 
 end
 },
 vb:button{
 id='c7',
 text='+4',
 width=35,
 notifier=function()
 if cbtns[7]==true then
  set_interval(4)
  end 
 end
 },
 vb:button{
 id='c15',
 text='+3',
 width=35,
 notifier=function()
 if cbtns[15]==true then
  set_interval(3)
  end 
 end
 }
}
local cadences5=vb:horizontal_aligner {
 mode='center',
 vb:button{
 id='c16',
 text='-2',
 width=35,
 notifier=function()
 if cbtns[16]==true then
  set_interval(-2)
  end 
 end
 },
 vb:button{
 id='c17',
 text='+2',
 width=35,
 notifier=function()
 if cbtns[17]==true then
  set_interval(2)
  end 
 end
 }
}
local cadences6=vb:horizontal_aligner {
 mode='center',
 vb:button{
 id='c18',
 text='-1',
 width=35,
 notifier=function()
 if cbtns[18]==true then
  set_interval(-1)
  end 
 end
 },
 vb:button{
 id='c19',
 text='+1',
 width=35,
 notifier=function()
 if cbtns[19]==true then
  set_interval(1)
  end 
 end
 }
}


local urlrow = vb:horizontal_aligner {
    mode = "center",
   vb:button {
    width = 204,
     text = "http://www.laffik.com/",
     notifier = function()
     renoise.app():open_url('http://www.laffik.com/')
     end
   } 
}
local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    uniform = true,
    spacing=8,
    scale_row,
    tone_start_row,
    vb:column{
    cadences1,
    cadences2,
    cadences4,     
    cadences5,
    cadences6,
    cadences3
    },
    urlrow
  }

 if (control_example_dialog and control_example_dialog.visible) then 
  control_example_dialog:show();
 else  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Premier v0.3 by Laffik of Dreamolers", dialog_content,
    function(dialog, key)
    
    
   if (key.modifiers == "" and key.name == "up") then
    
      -- move up a line.
      local edit_pos = renoise.song().transport.edit_pos
      edit_pos.line = edit_pos.line - 1
      if (edit_pos.line < 1) then
        edit_pos.line = renoise.song().selected_pattern.number_of_lines
      end
      renoise.song().transport.edit_pos = edit_pos  
   end      
   if (key.modifiers == "" and key.name == "down") then
      
      -- move down a line.
      local edit_pos = renoise.song().transport.edit_pos
      edit_pos.line = edit_pos.line + 1
      if (edit_pos.line > renoise.song().selected_pattern.number_of_lines) then
        edit_pos.line = 1
      end
      renoise.song().transport.edit_pos = edit_pos
    end
    return key
    end
  )
  end
  
 test_buttons()
end
----[[
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Premier...",
  invoke = function() mainproc() end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Premier...",
  invoke = function() mainproc() end
}
--]]--
