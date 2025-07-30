local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local control_example_dialog = nil
local j; -- losowany interwal
local s; -- losowany kierunek odmierzania interwału - w górę czy w dół
local a; -- suma interwałów
local i; -- losowana długość drogi
local t; -- licznik pętli długości drogi
local o; -- wylosowany interwał
local d; -- dysonansowy interwał kadencji
local w={}; -- [8] lista interwałów drogi
local scale={}; -- [12] definicja skali
local tony={}; -- lista tonow drogi
local tonylen; -- dlugosc sciezki
local shots; -- ilosc stralow
local injected; --ile tonow wbito
local vb = nil;
local notation={"C-0","C#0","D-0","D#0","E-0","F-0","F#0","G-0","G#0","A-0","A#0","B-0",
                "C-1","C#1","D-1","D#1","E-1","F-1","F#1","G-1","G#1","A-1","A#1","B-1",
                "C-2","C#2","D-2","D#2","E-2","F-2","F#2","G-2","G#2","A-2","A#2","B-2",
                "C-3","C#3","D-3","D#3","E-3","F-3","F#3","G-3","G#3","A-3","A#3","B-3",
                "C-4","C#4","D-4","D#4","E-4","F-4","F#4","G-4","G#4","A-4","A#4","B-4",
                "C-5","C#5","D-5","D#5","E-5","F-5","F#5","G-5","G#5","A-5","A#5","B-5",
                "C-6","C#6","D-6","D#6","E-6","F-6","F#6","G-6","G#6","A-6","A#6","B-6",
                "C-7","C#7","D-7","D#7","E-7","F-7","F#7","G-7","G#7","A-7","A#7","B-7",
                "C-8","C#8","D-8","D#8","E-8","F-8","F#8","G-8","G#8","A-8","A#8","B-8",
                "C-9","C#9","D-9","D#9","E-9","F-9","F#9","G-9","G#9","A-9","A#9","B-9"};
local lista={"","","","","","","","","","","","","","","","","","","","",""};
local qual={"90%","10%","63%","73%","60%","85%","10%","80%","73%","70%","53%","5%",
            "95%",
            "5%","53%","70%","73%","80%","10%","85%","60%","73%","63%","10%","90%"};

function testlist()
 local eeee=0;

  if lista[vb.views.cadence.value]=="---" then
   while lista[vb.views.cadence.value+eeee]=="---" do
    eeee=eeee+1;
   end 
   vb.views.cadence.value=vb.views.cadence.value+eeee;
  end;
  if lista[vb.views.cadence.value]=="----" then
   while lista[vb.views.cadence.value+eeee]=="----" do
    eeee=eeee-1;
   end 
   vb.views.cadence.value=vb.views.cadence.value+eeee;
  end; 
end
            
function generatelist()
 local lipe;
 local nuta;
 local indx;
 local itm;
 local indxitm;
 for lipe=-12,12 do
  indxitm=(vb.views.octave.value-1)*12+(vb.views.starttone.value)+lipe+12;
  nuta=notation[indxitm];
  if indxitm>0 and indxitm<120 then
   indx=lipe+13;
   itm=lipe.." - "..nuta.." - "..qual[indx]
   lista[indx]=itm;
  else
   indx=lipe+13;
   lista[indx]="---";   
  end
  if indxitm>119 then
   indx=lipe+13;
   lista[indx]="----";   
  end  
 end
 vb.views.cadence.items=lista;
end

function generatepath()
    local init; --ton od którego podążamy
    local itlwt; --ilość tonów leżących w tonacji
    local twt; --ton w tonacji
    local ss; --licznik pętli    
    local interwaly={}; --interwaly drogi - definicja interwałów z których będziemy budować drogi
    local lngth; --dlugosc drogi
    local ptl; --licznik petli
    local i;

    injected=0;

    if vb.views.s0.value==true then scale[0]=1 else scale[0]=0 end;
    if vb.views.s1.value==true then scale[1]=1 else scale[1]=0 end;
    if vb.views.s2.value==true then scale[2]=1 else scale[2]=0 end;
    if vb.views.s3.value==true then scale[3]=1 else scale[3]=0 end;
    if vb.views.s4.value==true then scale[4]=1 else scale[4]=0 end;
    if vb.views.s5.value==true then scale[5]=1 else scale[5]=0 end;
    if vb.views.s6.value==true then scale[6]=1 else scale[6]=0 end;
    if vb.views.s7.value==true then scale[7]=1 else scale[7]=0 end;
    if vb.views.s8.value==true then scale[8]=1 else scale[8]=0 end;    
    if vb.views.s9.value==true then scale[9]=1 else scale[9]=0 end; 
    if vb.views.s10.value==true then scale[10]=1 else scale[10]=0 end; 
    if vb.views.s11.value==true then scale[11]=1 else scale[11]=0 end; 

    init=vb.views.starttone.value-1; --ton od którego podążamy
    
    d=vb.views.cadence.value-13; --kadencja docelowa
    
    local ileguzikow=0;
    
    if vb.views.int0.value==true then interwaly[ileguzikow]=0; ileguzikow=ileguzikow+1; end
    if vb.views.int1.value==true then interwaly[ileguzikow]=12; ileguzikow=ileguzikow+1; end
    if vb.views.int2.value==true then interwaly[ileguzikow]=7; ileguzikow=ileguzikow+1; end
    if vb.views.int3.value==true then interwaly[ileguzikow]=5; ileguzikow=ileguzikow+1; end
    if vb.views.int4.value==true then interwaly[ileguzikow]=4; ileguzikow=ileguzikow+1; end
    if vb.views.int5.value==true then interwaly[ileguzikow]=9; ileguzikow=ileguzikow+1; end
    if vb.views.int6.value==true then interwaly[ileguzikow]=3; ileguzikow=ileguzikow+1; end
    if vb.views.int7.value==true then interwaly[ileguzikow]=10; ileguzikow=ileguzikow+1; end
    if vb.views.int8.value==true then interwaly[ileguzikow]=8; ileguzikow=ileguzikow+1; end
    if vb.views.int9.value==true then interwaly[ileguzikow]=2; ileguzikow=ileguzikow+1; end
    if vb.views.int10.value==true then interwaly[ileguzikow]=6; ileguzikow=ileguzikow+1; end 
    if vb.views.int11.value==true then interwaly[ileguzikow]=11; ileguzikow=ileguzikow+1; end
    if vb.views.int12.value==true then interwaly[ileguzikow]=1; ileguzikow=ileguzikow+1; end
       
    if ileguzikow==0 then tonylen=-1; return end;
       
    lngth=vb.views.ln.value+1;
    --srand( (unsigned)time( NULL ) );

    for ptl=0,12 do
     tony[ptl]=-1;
    end
    tonylen=-1;

    for ptl=1,200000 do
     i = math.random(0,7);
     if i==lngth then --poządana długość drogi +1
      o=0;
      w[0]=0;
      w[1]=0;
      w[2]=0;
      w[3]=0;
      w[4]=0;
      w[5]=0;
      w[6]=0;
      w[7]=0;
      for t=0,i-1 do
       j = math.random(0,ileguzikow-1); -- 0 - 12
       s = math.random(0,1);
       s=(s*2)-1;
       a=s*interwaly[j];
       w[t]=a;
       o=o+a;
      end;
      if o==d then
       --print(o);
       twt=init;
       itlwt=0;
       --print("-----------");
       for ss=0,i-1 do
        --print(w[ss]);
        twt=twt+w[ss];
        if (scale[math.fmod(120+twt,12)]==1) and (vb.views.octave.value*12+twt>-1) and (vb.views.octave.value*12+twt<120) then
         itlwt=itlwt+1;
        end;
       end;
       --//cout << " itlwt:" << itlwt << " i:" << i;
       --print("-----------");
       --print(itlwt);
       --print(i);
       if itlwt==i then
        --//cout << "pass\n" ;
        twt=init;
        itlwt=0;
        --print(init);--cout << init << " ";
        tony[0]=twt;
        for ss=0,i-1 do
         --//cout << w[ss] << " ";
         --print(w[ss]);
         twt=twt+w[ss];
         --print(twt);
         tony[ss+1]=twt;
         tonylen=ss+1;
         --cout << twt << " ";
         --if (scale[(120+twt) % 12]==1) {
          --itlwt=itlwt+1;
         -- cout << ".";                 
         --};
        end;
        --cout << "\n";
        --print(" ");
        for ss=0,i-1 do
         --print(w[ss]);
         --cout << w[ss] << " ";
        end;
        --print("---------");
        --cout << "\n\n";
        --system("PAUSE");         
       end;
     end;
    end;
end;
 
end;

function dumppath()
local ed;
local edo;
local strar={"","","","","",""};
local ttn;
if tonylen>-1 then
 shots=tonylen-1;
  if vb.views.startcadence.value==true then shots=shots+1 end;
  if vb.views.endcadence.value==true then shots=shots+1 end; 
  vb.views.gunshots.text="Shot ("..shots..")";
  if vb.views.startcadence.value==true then
   if vb.views.endcadence.value==true then
    for ed=0,tonylen do
     --print(tony[ed]);
     edo=ed+1;
     ttn=vb.views.octave.value*12+tony[ed];
     strar[ed+1]=edo.." - "..notation[ttn+1];
    end;
    for ed=tonylen+1,8 do
     strar[ed+1]="";   
    end
   else
    for ed=0,tonylen-1 do
     --print(tony[ed]);
     edo=ed+1;
     ttn=vb.views.octave.value*12+tony[ed];
     strar[ed+1]=edo.." - "..notation[ttn+1];
    end;
    for ed=tonylen,8 do
     strar[ed+1]="";   
    end  
   end
  else
   if vb.views.endcadence.value==true then
    for ed=0,tonylen-1 do
     --print(tony[ed]);
     edo=ed+1;
     ttn=vb.views.octave.value*12+tony[ed+1];
     strar[ed+1]=edo.." - "..notation[ttn+1];
    end;  
    for ed=tonylen,8 do
     strar[ed+1]="";   
    end
   else
    for ed=0,tonylen-2 do
      --print(tony[ed]);
     edo=ed+1;
     ttn=vb.views.octave.value*12+tony[ed+1];
     strar[ed+1]=edo.." - "..notation[ttn+1];
    end;  
    for ed=tonylen-1,8 do
     strar[ed+1]="";   
    end  
   end
  end;
  --multiline_text.text
  --print("-------");
  vb.views.lista.paragraphs=strar;
else
 vb.views.gunshots.text="Gun";
 --print('no path');
 vb.views.lista.paragraphs={"no path"};   
end;
end;

function inject_note()
local trackindex;
local pattern;
local tone;
local we;
local volume;
volume=renoise.song().transport.keyboard_velocity;
if vb.views.startcadence.value==true then
 if vb.views.endcadence.value==true then
  if tonylen>-1 then
   tone=vb.views.octave.value*12+tony[0]; 
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
   for we=0,10 do
    tony[we]=tony[we+1];
   end;
   tonylen=tonylen-1;
   injected=injected+1;
   dumppath();
  end
 else
  if tonylen>0 then
   tone=vb.views.octave.value*12+tony[0]; 
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
   for we=0,10 do
    tony[we]=tony[we+1];
   end;
   tonylen=tonylen-1;
   injected=injected+1;
   dumppath();
  end
  if tonylen==0 then  
   vb.views.gunshots.text="Gun";
   --print('no path');
   vb.views.lista.paragraphs={"no path"};  
  end
 end
else
 if vb.views.endcadence.value==true then
  if tonylen>1 then
   tone=vb.views.octave.value*12+tony[1]; 
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
   for we=0,10 do
    tony[we]=tony[we+1];
   end;
   tonylen=tonylen-1;
   injected=injected+1;
   dumppath();
  else
     tone=vb.views.octave.value*12+tony[1]; 
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
   for we=0,10 do
    tony[we]=tony[we+1];
   end;
   tonylen=tonylen-1;
   injected=injected+1;
   dumppath();
     vb.views.gunshots.text="Gun";
   --print('no path');
   vb.views.lista.paragraphs={"no path"};  
  end
 else
  if tonylen>1 then
   tone=vb.views.octave.value*12+tony[1]; 
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].volume_value=volume;
renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].instrument_value=renoise.song().selected_instrument_index-1;
   for we=0,10 do
    tony[we]=tony[we+1];
   end;
   tonylen=tonylen-1;
   injected=injected+1;
   dumppath();
  end
  if (tonylen==1) then
   vb.views.gunshots.text="Gun";
   --print('no path');
   vb.views.lista.paragraphs={"no path"};  
  end
 end
end
end

function mainproc() --------------------------------------- here

  vb = renoise.ViewBuilder()
  local scale_row = vb:horizontal_aligner {
     mode = "right",
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
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }
     ,
      vb:checkbox{--c#
       id="s1",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--d
       id="s2",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--d#
       id="s3",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--e
       id="s4",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--f
       id="s5",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--f#
       id="s6",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--g
       id="s7",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--g#
       id="s8",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--a
       id="s9",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--a#
       id="s10",
       width = 10,
       value=false,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     ,
      vb:checkbox{--b
       id="s11",
       width = 15,
       value=true,
       height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
       notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
       end
      }       
     }
     
  local tone_start_row = vb:horizontal_aligner {
  mode = "right",
  vb:text{
  text='Start tone: '
  },
  vb:popup{
      id = "starttone",
      width = 50,
      value = 1,
      items = {--[["-", ]]"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#" ,"B"},
      notifier = function()
        if vb.views.autorematch.value==true then
         generatelist();
         generatepath();
         dumppath();
        end
      end
  },
  vb:valuebox{
   id="octave",
   min=0,
   max=9,
   value=renoise.song().transport.octave,
   notifier = function()
    if vb.views.autorematch.value==true then
     generatelist();
     generatepath();
     dumppath();
    end
   end  
  }
  }
  local arrow_row = vb:horizontal_aligner {
  mode = "right",
  vb:button{
   text="f.s.e.",
   notifier = function()
   local currentpattern;
   local currentline;
   local li;
   local li2;
   local cadfound=false;
   local nte;
   currentpattern=renoise.song().transport.playback_pos.sequence;
   print(currentpattern)
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
      --print("no cadences found"); 
   end       
      
   local sl;
   cadfound=false;

   currentpattern=renoise.song().transport.playback_pos.sequence;
   currentline=renoise.song().selected_line_index;
   sl=renoise.song().transport.song_length.sequence;
   --print("sl: "..sl);
   while (cadfound==false) and (currentpattern<sl+1) do
    while (cadfound==false) and (currentline<renoise.song().patterns[currentpattern].number_of_lines) do
     nte=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[currentpattern]].tracks[renoise.song().selected_track_index].lines[currentline].note_columns[1].note_value;
     if nte<120 then cadfound=true end;     
     currentline=currentline+1;
    end
    currentpattern=currentpattern+1;
    if currentpattern<sl then currentline=1 end
   end
   if cadfound==true then
    local noct;
    local ntn; 
    local sn;
      --print(nte);
      noct=vb.views.octave.value;
      ntn=vb.views.starttone.value;
      sn=noct*12+ntn-1;
      vb.views.cadence.value=13+math.fmod(nte-sn,12);
   else
      --print("no cadences found"); 
   end 
         
      
      
       --renoise.song().patterns[renoise.song().selected_pattern_index].tracks[renoise.song().selected_track_index].lines[renoise.song().selected_line_index].note_columns[1].note_value=tone;
   end
  },
  vb:button{
   text="f.s.",
   notifier = function()
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
    if currentpattern>0 then currentline=renoise.song().patterns[currentpattern].number_of_lines end
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
  },
  vb:button{
   text="f.e.",
   notifier = function()
   local currentpattern;
   local currentline;
   local li;
   local li2;
   local cadfound=false;
   local nte;
   local sl;
   currentpattern=renoise.song().transport.playback_pos.sequence;
   currentline=renoise.song().selected_line_index;
   sl=renoise.song().transport.song_length.sequence;
   --print("sl: "..sl);
   while (cadfound==false) and (currentpattern<sl+1) do
    while (cadfound==false) and (currentline<renoise.song().patterns[currentpattern].number_of_lines) do
     nte=renoise.song().patterns[renoise.song().sequencer.pattern_sequence[currentpattern]].tracks[renoise.song().selected_track_index].lines[currentline].note_columns[1].note_value;
     print(nte);
     if nte<120 then cadfound=true end;     
     currentline=currentline+1;
    end
    currentpattern=currentpattern+1;
    if currentpattern<sl then currentline=1 end
   end
   if cadfound==true then
    local noct;
    local ntn; 
    local sn;
      print(nte);
      noct=vb.views.octave.value;
      ntn=vb.views.starttone.value;
      sn=noct*12+ntn-1;
      vb.views.cadence.value=13+math.fmod(nte-sn,12);
   else
      print("no cadences found"); 
   end        
   end
  },  
  vb:button{
   text="^",
   notifier = function()
    local ile;
    local tonnn;
    local newtone;
    local noct;
    local ntn;
    ile=vb.views.cadence.value-13;
    tonnn=vb.views.octave.value*12+vb.views.starttone.value-1;
    newtone=tonnn+ile;
    if newtone>119 then newtone=119 end;
    if newtone<0 then newtone=0 end;
    noct=math.floor(newtone/12);
    ntn=newtone-noct*12;
    vb.views.starttone.value=ntn+1;
    vb.views.octave.value=noct;
    vb.views.cadence.value=vb.views.cadence.value-ile;    
    if vb.views.autorematch.value==true then
     testlist();
     generatelist();
     generatepath();
     dumppath();
    end
   end
  }
  }
  
    local tone_end_row = vb:horizontal_aligner {
  mode = "right",
  vb:text{
  text='   Cadence Interval: '
  },
  vb:popup{
  id="cadence",
  width=110;
  items=lista,
  value=20;
  notifier = function()
        if vb.views.autorematch.value==true then
         testlist();
         generatepath();
         dumppath();
        end
  end
  
  }  
  
  }
  
  local intervals_row = vb:horizontal_aligner {
    mode = "right",  
   vb:text{
  text='Path Intervals: '
  },   
    vb:popup{
    id="jakosc",
      width = 140,
      value = 3,
      items = {--[["-", ]]"consonant: 5, 4", "consonant: 7, 5, 4", "medium: 5, 4, 3", "medium: 7, 5, 4, 3", "medium: 10, 9, 8", "medium: 10, 9, 8, 7" , "dissonant: 3, 2, 1", "dissonant: 4, 3, 2, 1", "disoonant: 6, 2, 1", "dissonant: 11, 6, 2, 1", "full rng.: 7, 5, 4, 3, 2, 1"},    
      notifier = function()
        if vb.views.jakosc.value==1 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=true;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=false;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==2 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=true;
         vb.views.int3.value=true;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=false;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==3 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=true;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=true;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==4 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=true;
         vb.views.int3.value=true;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=true;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==5 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=false;
         vb.views.int4.value=false;
         vb.views.int5.value=true;
         vb.views.int6.value=false;
         vb.views.int7.value=true;
         vb.views.int8.value=true;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==6 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=true;
         vb.views.int3.value=false;
         vb.views.int4.value=false;
         vb.views.int5.value=true;
         vb.views.int6.value=false;
         vb.views.int7.value=true;
         vb.views.int8.value=true;
         vb.views.int9.value=false;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=false;
        end;
        if vb.views.jakosc.value==7 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=false;
         vb.views.int4.value=false;
         vb.views.int5.value=false;
         vb.views.int6.value=true;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=true;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=true;
        end;
        if vb.views.jakosc.value==8 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=false;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=true;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=true;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=true;
        end;
        if vb.views.jakosc.value==9 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=false;
         vb.views.int4.value=false;
         vb.views.int5.value=false;
         vb.views.int6.value=false;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=true;
         vb.views.int10.value=true;
         vb.views.int11.value=false;
         vb.views.int12.value=true;
        end;
        if vb.views.jakosc.value==10 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=false;
         vb.views.int3.value=false;
         vb.views.int4.value=false;
         vb.views.int5.value=false;
         vb.views.int6.value=false;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=true;
         vb.views.int10.value=true;
         vb.views.int11.value=true;
         vb.views.int12.value=true;
        end;
        if vb.views.jakosc.value==11 then
         vb.views.int0.value=false;
         vb.views.int1.value=false;
         vb.views.int2.value=true;
         vb.views.int3.value=true;
         vb.views.int4.value=true;
         vb.views.int5.value=false;
         vb.views.int6.value=true;
         vb.views.int7.value=false;
         vb.views.int8.value=false;
         vb.views.int9.value=true;
         vb.views.int10.value=false;
         vb.views.int11.value=false;
         vb.views.int12.value=true;
        end;
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
      end
    }
  }  

  local interwals_switches_row = vb:horizontal_aligner {
  mode = "right",  
  vb:vertical_aligner {
   vb:text{
   text="0",
   }, 
   vb:checkbox{
   id="int0",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="12",
   }, 
   vb:checkbox{
   id="int1",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="7",
   }, 
   vb:checkbox{
   id="int2",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="5",
   }, 
   vb:checkbox{
   id="int3",
   value=true,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="4",
   }, 
   vb:checkbox{
   id="int4",
   value=true,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="9",
   }, 
   vb:checkbox{
   id="int5",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="3",
   }, 
   vb:checkbox{
   id="int6",
   value=true,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="10",
   }, 
   vb:checkbox{
   id="int7",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="8",
   }, 
   vb:checkbox{
   id="int8",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="2",
   }, 
   vb:checkbox{
   id="int9",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="6",
   }, 
   vb:checkbox{
   id="int10",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="11",
   }, 
   vb:checkbox{
   id="int11",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  vb:vertical_aligner {
   vb:text{
   text="1",
   }, 
   vb:checkbox{
   id="int12",
   value=false,
   notifier = function() 
    if vb.views.autorematch.value==true then
     generatepath();
     dumppath();
    end
   end
   }  
  },
  
  }
  
  local length_row = vb:horizontal_aligner {
    mode = "right",  
        vb:text{
  text='Path length: '
  },
  vb:valuebox{
  id="ln",
  min=0,
  max=6,
  value=2,
  notifier = function()
        if vb.views.autorematch.value==true then
         generatepath();
         dumppath();
        end
  end  
  }   
  
  }  
  local close_button_row = vb:horizontal_aligner {
    mode = "right",
 vb:text {
 text="Auto rematch:",
 },    
 vb:checkbox {
  id="autorematch",
  value=true;
 },
    
        vb:button {
        id="match";
      text = "Rematch",
      width = 60,
      height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
       generatepath();
       dumppath();
      end
    }
, 
    vb:button {
      text = "Gun",
      id="gunshots";
      width = 60,
      height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
       inject_note()
      end
    }
,
    vb:button {
      text = "Close",
      width = 60,
      height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
       control_example_dialog:close()
      end
    }
  }

local includecadencesrow = vb:horizontal_aligner {
 mode = "right",
 vb:text {
 text="Start cadence:",
 },
 vb:checkbox {
 id="startcadence",
 value=true,
 notifier = function()
  if vb.views.gunshots.text=="Gun" then
  else
   if injected==0 then
    shots=tonylen-1;
    if vb.views.startcadence.value==true then shots=shots+1 end;
    if vb.views.endcadence.value==true then shots=shots+1 end; 
    vb.views.gunshots.text="Shot ("..shots..")";
    dumppath();
   end
  end
  generatepath();
  dumppath();
 end
 },
 vb:text {
 text="End cadence:",
 }, 
 vb:checkbox {
 id="endcadence",
 value=true,
 notifier = function()
  if vb.views.gunshots.text=="Gun" then
  else
   shots=tonylen-1;
   if vb.views.startcadence.value==true then shots=shots+1 end;
   if vb.views.endcadence.value==true then shots=shots+1 end; 
   vb.views.gunshots.text="Shot ("..shots..")";
   dumppath();
  end
  generatepath();
  dumppath();
 end
 }
}

local urlrow = vb:horizontal_aligner {
    mode = "right",
   vb:button {
    width = 204,
     text = "http://www.laffik.com/",
     notifier = function()
     renoise.app():open_url('http://www.laffik.com/')
     end
   } 
}

local pathdisplaybox = vb:horizontal_aligner {
 mode = "right",
 vb:bitmap {
 bitmap="logo.png"
 },
 vb:multiline_text {
 id="lista",
 width=100,
 height=130,
 style="border",
 paragraphs={""},
 }
}

local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    uniform = true,
    scale_row,
    tone_start_row,
    arrow_row,
    tone_end_row,
    intervals_row,
    interwals_switches_row,
    length_row,
    includecadencesrow,
    pathdisplaybox,
    close_button_row,
    urlrow
  }

 if (control_example_dialog and control_example_dialog.visible) then 
  control_example_dialog:show();
 else  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Pathfinder v0.8 by Laffik of Dreamolers", dialog_content,
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

generatelist();
generatepath();
dumppath(); 

end -------------------------------- here

----[[  -----------------------------------------------------------------------------------------------------------------------here
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Pathfinder...",
  invoke = function() mainproc() end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Pathfinder...",
  invoke = function() mainproc() end
}
  
--]]-- ---------------------------------------------------------------------------here
