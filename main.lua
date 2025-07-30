local ss,se,sl,sr,bl
local tempo="---";
local t
local t1,t2,tf;
local olt1,olt2,oltf,olss,olse,olsr;
local control_example_dialog = nil
local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local vb = nil;

function calculate_bpm()
if renoise.song().selected_instrument_index==0 or renoise.song().selected_sample_index==0 then
if vb then
vb.views.bpmcounter.text="---";
end
else
ss=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].sample_buffer.selection_start;
se=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].sample_buffer.selection_end;
sl=se-ss+1;
sr=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].sample_buffer.sample_rate;
t1=renoise.song().instruments[renoise.song().selected_instrument_index].transpose;
t2=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].transpose;
tf=(renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].fine_tune/127);
t=t1+t2+tf;
bl=60000/(sl/sr*1000);
tempo=bl*2^(t/12);
if tempo<60 then
repeat
 tempo=tempo*2;
until tempo>60
end
if tempo>190 then
repeat
tempo=tempo/2;
until tempo<190
end
if vb then
vb.views.bpmcounter.text=""..tempo;
end
end
end

function mainproc()

calculate_bpm()

vb = renoise.ViewBuilder()
 local tmp = vb:horizontal_aligner {  
  mode = "right", 
  vb:text{  
    text='Tempo: '
  },
  vb:button{
   id="bpmcounter",
   text=""..tempo,
   notifier=function()
   calculate_bpm()

   end
  },
  vb:text{  
    text='BPM'
  },
  vb:button{
   text="x2",
   notifier=function()
    tempo=tempo*2;
    vb.views.bpmcounter.text=""..tempo;
   end
  },
  vb:button{
   text=":2",
   notifier=function()
    tempo=tempo/2;
    vb.views.bpmcounter.text=""..tempo;
   end
  },  
  vb:button{
   text="Set song BPM",
   notifier=function()
    if tempo>32 and tempo<999 or tempo==32 or tempo==999 then
    renoise.song().transport.bpm=tempo
    end
   end
   },
   vb:button{
    text="Set sample BPM to song",
    notifier=function()
     local res;
     local ress;
     local resc;
     local rs;
     local rc;
     local rst;
     local rct;
     local rctfu;
     local rctfr
     --calculate_bpm()
     res=math.log(renoise.song().transport.bpm/tempo)/math.log(2^(1/12));
     --print(res);
     if res>0 then
      ress=math.floor(res);
      resc=res-ress;
     end
     if res<0 then
      ress=math.ceil(res);
      resc=res-ress;
     end
     if res==0 then
      ress=0;
      resc=0;
     end
     --print(ress);
     --print(resc);
     rs=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].transpose;
     rc=renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].fine_tune;
     rst=rs+ress;
     rct=rc+(resc*127);
     if rct>127 then
      rctfu=math.floor(rct/127);
      rctfr=rct-(rctfu*127);
      rst=rst+rctfu;
      rct=rctfr;
     end
     if rct<-127 then
      --print("rct: ",rct)
      rctfu=math.ceil(rct/127);
      --print("rctfu: ",rctfu)
      rctfr=rct-(rctfu*127)
      --print("rctfr: ",rctfr)
      rst=rst+rctfu;
      --print(rst)
      rct=rctfr;
      --print(rct)
     end     
     if rst>120 then rst=120 end
     if rst<-120 then rst=-120 end
     renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].transpose=rst;
     renoise.song().instruments[renoise.song().selected_instrument_index].samples[renoise.song().selected_sample_index].fine_tune=rct;
     calculate_bpm()
    end
    }
  }

local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    uniform = true,
    tmp
    
}

if (control_example_dialog and control_example_dialog.visible) then 
  control_example_dialog:show();
else  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Selection to BPM v0.6 by Laffik of Dreamolers",dialog_content
  )
end

end

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Selection to BPM...",
  invoke = function() mainproc() end
}
renoise.tool():add_menu_entry {
  name = "Sample Editor:Selection to BPM...",
  invoke = function() mainproc() end
}
