--
--main.lua
--


--globals
asc_main_title="Advanced Step Composer"
asc_version="1.0"
asc_build="build 105"
asc_reg_title=""
rns_version=string.sub(renoise.RENOISE_VERSION,1,5)
api_version=renoise.API_VERSION
vb=renoise.ViewBuilder()
vws=vb.views
rna=renoise.app()
rnt=renoise.tool()



--global song
song=nil
  local function asc_sng() song=renoise.song() end 
  rnt.app_new_document_observable:add_notifier(asc_sng)
  pcall(asc_sng)



--colors
ASC_CLR={
  GREEN_ON={080,180,040},
  GREEN_OFF={030,090,000},
  RED_ON={180,030,000},
  RED_OFF={090,030,000},
  BLACK={001,000,000},
  WHITE={235,235,235},
  DEFAULT={000,000,000},
  MARKER={235,235,235},
}



--capture marker color
function asc_capture_clr_mrk_main()
  local filename=""
  if (os.platform()=="WINDOWS") then
    filename=("%s\\Renoise\\V%s\\Config.xml"):format(os.getenv("APPDATA"),rns_version)
  elseif (os.platform()=="MACINTOSH") then
    filename=("%s/Library/Preferences/Renoise/V%s/Config.xml"):format(os.getenv("HOME"),rns_version)
  elseif (os.platform()=="LINUX") then
    filename=("%s/.renoise/V%s/Config.xml"):format(os.getenv("HOME"),rns_version)
  end
  if (io.exists(filename)) then
    local pref_data=renoise.Document.create("RenoisePrefs"){SkinColors={Selected_Button_Back="",Scrollbar=""}}
    pref_data:load_from(filename)
    local rgb_1=tostring(pref_data.SkinColors.Selected_Button_Back)
    local r_1,g_1,b_1=rgb_1:match("([^,]+),([^,]+),([^,]+)")
    ASC_CLR.MARKER[1]=tonumber(r_1)
    ASC_CLR.MARKER[2]=tonumber(g_1)
    ASC_CLR.MARKER[3]=tonumber(b_1)
  end
end


--preferences
ASC_PREF=renoise.Document.create("Preferences"){}
for n=1,8 do
  ASC_PREF:add_property("favorite_main_directory_"..n,"")
  ASC_PREF:add_property("favorite_directory_"..n,"")
  ASC_PREF:add_property("favorite_profile_"..n,"")
end
ASC_PREF:add_property("subfolder_profiles","Default Profiles")

ASC_PREF:add_property("note_steps",4)
ASC_PREF:add_property("initial_note",48)
ASC_PREF:add_property("nol_top_note",4)
ASC_PREF:add_property("nol_note_off",0)

ASC_PREF:add_property("initial_instrument",0)
ASC_PREF:add_property("initial_volume",128)
ASC_PREF:add_property("initial_panning",65)
ASC_PREF:add_property("initial_delay",0)
ASC_PREF:add_property("initial_effect",19)
ASC_PREF:add_property("initial_amount",0)

ASC_PREF:add_property("cap_ins_idx",true)
ASC_PREF:add_property("continuous_off",false)
ASC_PREF:add_property("reverse_all",false)
ASC_PREF:add_property("auto_insert_first",true)
ASC_PREF:add_property("insert_nested_lines",false)


ASC_PREF:add_property("mark_loop",true)
ASC_PREF:add_property("mark_play",true)

ASC_PREF:add_property("odd_even_not_clear",false)
ASC_PREF:add_property("custom_not_clear",false)

ASC_PREF:add_property("random_fx_param",true)
ASC_PREF:add_property("random_lines",false)

ASC_PREF:add_property("load_profile",true)
ASC_PREF:add_property("insert_steps",true)
ASC_PREF:add_property("change_bpm_lpb",false)
ASC_PREF:add_property("change_nol",false)
ASC_PREF:add_property("hide_sub_columns",false)
ASC_PREF:add_property("note_column_name",false)
rnt.preferences=ASC_PREF



--require("lua/generator")
require("lua/asc")
require("lua/keyhandler")
