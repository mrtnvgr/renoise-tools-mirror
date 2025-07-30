local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local line
local basenote
local chord={{}}
local typ={"dur","mol","dim","dimdur","dim2","aug"}
local func={{}}
local tt1,tt2,tt3,tt4
local tonbyfunction={{}}
local vb = nil;
local control_example_dialog = nil

tonbyfunction={{0,7,4,11,2,5,9,1,3,6,8,10},
               {0,7,3,10,2,5,9,1,4,6,8,11},
               {0,6,3,9,2,5,11,1,4,7,8,10},
               {0,6,4,10,2,5,11,1,3,7,8,9},
               {0,6,2,9,4,5,11,1,3,7,8,10},
               {0,8,4,10,2,5,11,1,3,6,7,9}}


func={{1,8,5,9,3,6,10,2,11,7,12,4},
      {1,8,5,3,9,6,10,2,11,7,4,12},
      {1,8,5,3,9,6,2,10,11,4,12,7},
      {1,8,5,9,3,6,2,10,11,12,4,7},
      {1,8,3,9,5,6,2,10,11,4,12,7},
      {1,8,5,9,3,6,10,11,2,12,4,7}}


chord={{0,4,7,11},  -- dur
       {0,3,7,10},  -- mol
       {0,3,6,9},   -- dim
       {0,4,6,10},  -- dimdur
       {0,2,6,9},   -- dim2
       {0,4,8,10}}  -- aug

function ilelinii(pattern1,line1,pattern2,line2)
 local linie
 local p,l
 linie=0
 repeat
 p,l=skiplines(pattern1-1,line1,linie)
 if p==pattern2-1 and l==line2 then
  return linie
 end
 linie=linie+1
 until true==false

end

function skiplines(pattern,line,lines)
 local f
 if lines>0 then
  for f=1,lines do
   line = line + 1
   if (line > renoise.song().patterns[renoise.song().sequencer.pattern_sequence[pattern+1]].number_of_lines-1) then
    line = 0;
    pattern=pattern+1
   end
  if pattern>renoise.song().transport.song_length.sequence then
   return -1,-1  
  end
  end 
 end
 return pattern,line
end

function sort3(array)
 local t;
 if array[2]<array[1] then t=array[1]; array[1]=array[2]; array[2]=t; end;
 if array[3]<array[2] then t=array[2]; array[2]=array[3]; array[3]=t; end;
 if array[2]<array[1] then t=array[1]; array[1]=array[2]; array[2]=t; end;
 if array[3]<array[2] then t=array[2]; array[2]=array[3]; array[3]=t; end;
 return array;
end

function sort4(array)
 local t;
 if array[2]<array[1] then t=array[1]; array[1]=array[2]; array[2]=t; end;
 if array[3]<array[2] then t=array[2]; array[2]=array[3]; array[3]=t; end;
 if array[4]<array[3] then t=array[3]; array[3]=array[4]; array[4]=t; end; 
 if array[2]<array[1] then t=array[1]; array[1]=array[2]; array[2]=t; end;
 if array[3]<array[2] then t=array[2]; array[2]=array[3]; array[3]=t; end;
 if array[4]<array[3] then t=array[3]; array[3]=array[4]; array[4]=t; end;
 if array[2]<array[1] then t=array[1]; array[1]=array[2]; array[2]=t; end;
 if array[3]<array[2] then t=array[2]; array[2]=array[3]; array[3]=t; end;
 if array[4]<array[3] then t=array[3]; array[3]=array[4]; array[4]=t; end;
 return array;
end

function mod3(array)
 array[1]=math.fmod(array[1],12)
 array[2]=math.fmod(array[2],12)
 array[3]=math.fmod(array[3],12) 
 return array
end

function mod4(array)
 array[1]=math.fmod(array[1],12)
 array[2]=math.fmod(array[2],12)
 array[3]=math.fmod(array[3],12) 
 array[4]=math.fmod(array[4],12)  
 return array
end

function analyze_chord3(t1,t2,t3)
local a,b
local outbn,outmod,outtone
local mode

 a=sort3(mod3({t1,t2,t3}));
 --print(a[1],a[2],a[3]);
 for mode=1,6 do
  for basenote=0,11 do
   --print(chord[1][1]+basenote,chord[1][2]+basenote,chord[1][3]+basenote)
   b=sort3(mod3({chord[mode][1]+basenote,chord[mode][2]+basenote,chord[mode][3]+basenote})); 
   if a[1]==b[1] and a[2]==b[2] and a[3]==b[3] then
    --print(basenote,typ[mode]); 
    outbn=basenote;
    outmod=mode;
    if math.fmod(t1,12)==outbn then outtone=t1 end
    if math.fmod(t2,12)==outbn then outtone=t2 end
    if math.fmod(t3,12)==outbn then outtone=t3 end    
   end
  end 
 end
return outbn,outmod,outtone
end

function analyze_chord4(t1,t2,t3,t4)
local a,b
local outbn,outmod,outtone
local mode

 a=sort4(mod4({t1,t2,t3,t4}));
 --print(a[1],a[2],a[3]);
 for mode=1,6 do
  for basenote=0,11 do
   --print(chord[1][1]+basenote,chord[1][2]+basenote,chord[1][3]+basenote)
   b=sort4(mod4({chord[mode][1]+basenote,chord[mode][2]+basenote,chord[mode][3]+basenote,chord[mode][4]+basenote})); 
   if a[1]==b[1] and a[2]==b[2] and a[3]==b[3] and a[4]==b[4] then
    --print(basenote,typ[mode]); 
    outbn=basenote;
    outmod=mode;
    if math.fmod(t1,12)==outbn then outtone=t1 end
    if math.fmod(t2,12)==outbn then outtone=t2 end
    if math.fmod(t3,12)==outbn then outtone=t3 end
    if math.fmod(t4,12)==outbn then outtone=t4 end
   end
  end 
 end
return outbn,outmod,outtone
end

--a=sort3(mod3({100,3,12}))
--print(a[1],a[2],a[3])

function findfunction(tonbasu,basetone,typemode)
 local w;
  w=func[typemode][math.fmod(12+tonbasu-basetone+60,12)+1]; 
  --print(w);
  --print(math.floor((tonbasu-basetone)/12)*12);
  --print(" ");
  w=w+math.floor((tonbasu-basetone)/12)*12;
  --print(w);
  return w;
end 

function findtone(functi,basetone,typemode)
 local v,w;
 local outp;
 for v=0,119 do
  w=func[typemode][math.fmod(120+v-basetone+60,12)+1]; 
  w=w+math.floor((v-basetone)/12)*12;  
  if w==functi then outp=v; end;
 end
 return outp;
end

function scanbackchord()
local ton=-1
local type=-1
local basetone=-1

for line=vb.views.ssl.value,0,-1 do
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
  tt4=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[4].note_value;
 end
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
 end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then  
   if tt1<120 and tt2<120 and tt3<120 and tt4<120 then
    ton,type,basetone=analyze_chord4(tt1,tt2,tt3,tt4);
    --print(ton,typ[type])
    return ton,type,basetone
   end
  end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
   if tt1<120 and tt2<120 and tt3<120 then
    ton,type,basetone=analyze_chord3(tt1,tt2,tt3);
    --print(ton,typ[type])
    return ton,type,basetone
   end 
  end  

end


return ton,type,basetone
end

function scanbackchord2()
local ton=-1
local type=-1
local basetone=-1
local gotopattern,gotolin

for line=vb.views.psl.value,0,-1 do
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
  tt4=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[4].note_value;
 end
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
 end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then  
   if tt1<120 and tt2<120 and tt3<120 and tt4<120 then
    ton,type,basetone=analyze_chord4(tt1,tt2,tt3,tt4);
    --print(ton,typ[type])
    return ton,type,basetone
   end
  end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
   if tt1<120 and tt2<120 and tt3<120 then
    ton,type,basetone=analyze_chord3(tt1,tt2,tt3);
    --print(ton,typ[type])
    return ton,type,basetone
   end 
  end  

end


return ton,type,basetone
end

function arpegiate()

local ton,type;
local basnote;
local f={{}};
local lineoffset={};
local olbasenote;
local instr={{}};
local noteoff={{}};
local pan={{}};
local delay={{}};
local empty={{}};
local i,v,p,d,e1,e2;
local z;
local volume={{}};
local effectnumber={{}};
local effectamount={{}};
local commandeffectnumber={{}};
local commandeffectamount={{}};
local vnc,basetone,nt;
local a,b;
local gotopattern,gotoline
local seqlength

--print(findtone(findfunction(48,60,1),60,1))
--print(findtone(findfunction(49,60,1),60,1))
--print(findtone(findfunction(50,60,1),60,1))
--print(findtone(findfunction(51,60,1),60,1))
--print(findtone(findfunction(52,60,1),60,1))
--print(findtone(findfunction(53,60,1),60,1))
--print(findtone(findfunction(54,60,1),60,1))
--print(findtone(findfunction(55,60,1),60,1))
--print(findtone(findfunction(56,60,1),60,1))
--print(findtone(findfunction(57,60,1),60,1))
--print(findtone(findfunction(58,60,1),60,1))
--print(findtone(findfunction(59,60,1),60,1))
--print(findtone(findfunction(60,60,1),60,1))
--print(findtone(findfunction(61,60,1),60,1))


for a=0,511 do
volume[a]={};
instr[a]={};
delay[a]={};
empty[a]={};
pan[a]={};
noteoff[a]={};
f[a]={};
effectnumber[a]={};
effectamount[a]={};
commandeffectnumber[a]={};
commandeffectamount[a]={};
for b=0,12 do
volume[a][b]=nil;
instr[a][b]=nil;
delay[a][b]=nil;
empty[a][b]=nil;
pan[a][b]=nil;
noteoff[a][b]=nil;
f[a][b]=nil;
effectnumber[a][b]=nil;
effectamount[a][b]=nil;
commandeffectnumber[a][b]=nil;
commandeffectamount[a][b]=nil;
end
end

seqlength=vb.views.sel.value-vb.views.ssl.value+1;

--print(seqlength);

ton,type,basetone=scanbackchord()



for line=vb.views.ssl.value,vb.views.sel.value do
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
  tt4=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[4].note_value;
 end
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.chordstrack.value].lines[line+1].note_columns[3].note_value;
 end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then  
   if tt1<120 and tt2<120 and tt3<120 and tt4<120 then
    ton,type,basetone=analyze_chord4(tt1,tt2,tt3,tt4);
    --print(ton,typ[type])
   end
  end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
   if tt1<120 and tt2<120 and tt3<120 then
    ton,type,basetone=analyze_chord3(tt1,tt2,tt3);
    --print(ton,typ[type])
   end 
  end
  --ton,type
  --print(ton)
  --print(type)
  --print(basetone)
  
  if ton==-1 or type==-1 or basetone==-1 then return end
  vnc=renoise.song().tracks[vb.views.rifftrack.value].visible_note_columns;
  for z=1,vnc do
  basnote=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].note_value;
  if basnote<120 then
   --print(line-1)
   --print(z)
   --print(f[line][z])
   f[line-vb.views.ssl.value][z]=findfunction(basnote,basetone,type);
  else
   if basnote==120 then
    noteoff[line-vb.views.ssl.value][z]=true;
   end
   if basnote==121 then
    empty[line-vb.views.ssl.value][z]=true;
   end
  end  
  --print(line)
  --print(z)
  --print(volume[2][1])
  v=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].volume_value;
  p=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].panning_value;
  d=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].delay_value;  
  i=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].instrument_value;
  e1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].effect_number_value;
  e2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].note_columns[z].effect_amount_value;
  volume[line-vb.views.ssl.value][z]=v;
  pan[line-vb.views.ssl.value][z]=p;
  delay[line-vb.views.ssl.value][z]=d;
  instr[line-vb.views.ssl.value][z]=i;
  commandeffectnumber[line-vb.views.ssl.value][z]=e1;
  commandeffectamount[line-vb.views.ssl.value][z]=e2;
  --print(instr[line-1]);
  --print(instr[line])
  end
end
vnc=renoise.song().tracks[vb.views.rifftrack.value].visible_effect_columns;
if vnc>0 then
 for z=1,vnc do
  for line=vb.views.ssl.value,vb.views.sel.value do
   effectnumber[line-vb.views.ssl.value][z]=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].effect_columns[z].number_value;
   effectamount[line-vb.views.ssl.value][z]=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].tracks[vb.views.rifftrack.value].lines[line+1].effect_columns[z].amount_value;
  end
 end
end
--print(" ");

ton,type,basetone=scanbackchord2()

 if ton==-1 or type==-1 or basetone==-1 then return end

vnc=renoise.song().tracks[vb.views.rifftrack.value].visible_note_columns;
for z=1,vnc do

for line=0,ilelinii(vb.views.psp.value+1,vb.views.psl.value,vb.views.pep.value+1,vb.views.pel.value) do

gotopattern,gotoline=skiplines(vb.views.psp.value,vb.views.psl.value,line)

 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[3].note_value;
  tt4=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[4].note_value;
 end
 if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
  tt1=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[1].note_value;
  tt2=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[2].note_value;
  tt3=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.chordstrack.value].lines[gotoline+1].note_columns[3].note_value;
 end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==4 then  
   if tt1<120 and tt2<120 and tt3<120 and tt4<120 then
    ton,type,basetone=analyze_chord4(tt1,tt2,tt3,tt4);
    --print(ton,typ[type])
   end
  end
  if renoise.song().tracks[vb.views.chordstrack.value].visible_note_columns==3 then
   if tt1<120 and tt2<120 and tt3<120 then
    ton,type,basetone=analyze_chord3(tt1,tt2,tt3);
    --print(ton,typ[type])
   end 
  end
  if ton==-1 or type==-1 or basetone==-1 then return end
  if f[math.fmod(line,seqlength)][z]==nil then
   if noteoff[math.fmod(line,seqlength)][z]==true then renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].note_value=120; end
  else
   nt=findtone(f[math.fmod(line,seqlength)][z],basetone,type)--ton+tonbyfunction[type][f[math.fmod(line,16)]] 
   --print(nt);
   --print(basetone);
   renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].note_value=nt;
   --print(i);
  end
  v=volume[math.fmod(line,seqlength)][z];
  p=pan[math.fmod(line,seqlength)][z];
  d=delay[math.fmod(line,seqlength)][z];
  --print(" ")
  --print(line)
  --print(math.fmod(line-1,16))
  --print(v)
  --print(p)
  --print(d)
  e1=commandeffectnumber[math.fmod(line,seqlength)][z];
  e2=commandeffectamount[math.fmod(line,seqlength)][z];
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].volume_value=v;
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].panning_value=p;
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].delay_value=d;
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].effect_number_value=e1;
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].effect_amount_value=e2;
  if empty[math.fmod(line,seqlength)][z]==true then renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].note_value=121; end;
   i=instr[math.fmod(line,seqlength)][z];
  if i==255 then renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].instrument_value=255; else renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].note_columns[z].instrument_value=i; end;
end
end
vnc=renoise.song().tracks[vb.views.rifftrack.value].visible_effect_columns;
for z=1,vnc do
 for line=0,ilelinii(vb.views.psp.value+1,vb.views.psl.value,vb.views.pep.value+1,vb.views.pel.value) do

  gotopattern,gotoline=skiplines(vb.views.psp.value,vb.views.psl.value,line)
  
  --print(effectnumber[math.fmod(line,16)][z])
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].effect_columns[z].number_value=effectnumber[math.fmod(line,seqlength)][z];
  renoise.song().patterns[renoise.song().sequencer.pattern_sequence[gotopattern+1]].tracks[vb.views.rifftrack.value].lines[gotoline+1].effect_columns[z].amount_value=effectamount[math.fmod(line,seqlength)][z];
 end
end
end

function mainproc()

vb = renoise.ViewBuilder()
local tracks_row = vb:horizontal_aligner {
  mode = "right", 
  vb:text{
  text='Chords track: '
  },
  vb:valuebox{
   id="chordstrack",
   min=1,
   max=renoise.song().sequencer_track_count,
   value=1,
   notifier = function()
   end  
  },  
  vb:text{  
    text='Riff track: '
  },
  vb:valuebox{
   id="rifftrack",
   min=1,
   max=renoise.song().sequencer_track_count,
   value=1,
   notifier = function()
   vb.views.sel.max=renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines-1;
   end  
  },    
}

local riff_pattern_row = vb:horizontal_aligner { 
  mode = "right", 
  vb:text{  
    text='Riff pattern: '
  },
  vb:valuebox{
   id="riffpattern",
   min=0,
   value=0,
   max=renoise.song().transport.song_length.sequence-1,
   notifier = function()
    vb.views.ssl.max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].number_of_lines-1;
    if vb.views.ssl.value>vb.views.ssl.max then vb.views.ssl.value=vb.views.ssl.max end
    vb.views.sel.max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.riffpattern.value+1]].number_of_lines-1;
    if vb.views.sel.value>vb.views.sel.max then vb.views.sel.value=vb.views.sel.max end    
   end  
  }
}

local sequence_lines_row = vb:horizontal_aligner { 
  mode = "right", 
  vb:text{  
    text='Start line: '
  },
  vb:valuebox{
   id="ssl",
   min=0,
   value=0,
   max=renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines-1,
   notifier = function()
    if vb.views.ssl.value>vb.views.sel.value then vb.views.ssl.value=vb.views.sel.value end
   end  
  },
  vb:text{  
    text='End line: '
  },
  vb:valuebox{
   id="sel",
   min=0,
   max=renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines-1,
   value=math.ceil((renoise.song().patterns[renoise.song().selected_pattern_index].number_of_lines)/4)-1,
   notifier = function()
    if vb.views.sel.value<vb.views.ssl.value then vb.views.sel.value=vb.views.ssl.value end
   end  
  }  
}

local paste_start_row = vb:horizontal_aligner { 
  mode = "right", 
  vb:text{  
    text='Paste start pattern: '
  },   
  vb:valuebox{
   id="psp",
   min=0,
   max=renoise.song().transport.song_length.sequence-1,
   value=0,
   notifier = function()
    if vb.views.psp.value>vb.views.pep.value then vb.views.psp.value=vb.views.pep.value end
    vb.views.psl.max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].number_of_lines-1
    if vb.views.psl.value>vb.views.psl.max then vb.views.psl.value=vb.views.psl.max end
   end  
  },
  vb:text{  
    text='line: '
  },   
  vb:valuebox{
   id="psl",
   min=0,
   max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.psp.value+1]].number_of_lines-1,
   value=0,
   notifier = function()
   if vb.views.psp.value==vb.views.pep.value then
    if vb.views.psl.value>vb.views.pel.value then vb.views.psl.value=vb.views.pel.value end  
   end
   end  
  }
}
  
 local paste_end_row = vb:horizontal_aligner {  
  mode = "right", 
  vb:text{  
    text='Paste end pattern: '
  },
  vb:valuebox{
   id="pep",
   min=0,
   max=renoise.song().transport.song_length.sequence-1,
   value=0,
   notifier = function()
       if vb.views.pep.value<vb.views.psp.value then vb.views.pep.value=vb.views.psp.value end
    vb.views.pel.max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.pep.value+1]].number_of_lines-1
    if vb.views.pel.value>vb.views.pel.max then vb.views.pel.value=vb.views.pel.max end
   end  
  },
  vb:text{  
    text='line: '
  },   
  vb:valuebox{
   id="pel",
   min=0,
   max=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.pep.value+1]].number_of_lines-1,
   value=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[vb.views.pep.value+1]].number_of_lines-1,
   notifier = function()
   if vb.views.psp.value==vb.views.pep.value then
    if vb.views.pel.value<vb.views.psl.value then vb.views.pel.value=vb.views.psl.value end  
   end
   end  
  },

}

local go_row = vb:horizontal_aligner { 
 mode = "right", 
 vb:button{
 id="go",
 width=100,
 height=50,
 text="Replicate",
    notifier = function()
    arpegiate()
   end  
}
}

local urlrow = vb:horizontal_aligner {
    mode = "right",
   vb:button {
    width = 204,
     text = "http://www.laffik.com/",
     notifier = function()
     renoise.app():open_url('http://www.laffik.com/');
     end
   } 
}


local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    uniform = true,
    tracks_row,
    riff_pattern_row,
    sequence_lines_row,
    paste_start_row,
    paste_end_row,
    go_row,
    urlrow,
}


if (control_example_dialog and control_example_dialog.visible) then 
  control_example_dialog:show();
else  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Processor v0.6 by Laffik of Dreamolers", dialog_content,
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
end

----[[
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Processor...",
  invoke = function() mainproc() end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Processor...",
  invoke = function() mainproc() end
}
--]]--
