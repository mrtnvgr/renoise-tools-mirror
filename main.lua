-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--
-- Tool name: SAI & Phrases Importer
-- Version: 1.0 build 000
-- Compatibility: Renoise v3.1.1
-- Development date: August 2019
-- Published: August 2019
-- Locate: Spain
-- Programmer: ulneiz
-- Description: Provides two separate panels for:
--              - "Save all instruments": save all XRNI instruments of the current song in a folder of your choice (use coroutines).
--              - "Phrases Importer": import all XRNZ phrases between selected instruments. Select a origin and a destiny instrument index to import.
--
--              Access: Instrument box: "~Save All Instruments..." or "~Phrases Importer..."
--
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------
--locals/globals
-------------------------------------------------------------------------------------------------
local rna=renoise.app()
local rnt=renoise.tool()
local vb=renoise.ViewBuilder()
local vws=vb.views

--global song
song=nil
  local function pre_sng() song=renoise.song() end --define global "song"
  rnt.app_new_document_observable:add_notifier(pre_sng) --catching start renoise or new song
  pcall(pre_sng) --catching installation


local SAI_MAIN_DIALOG=nil
local SAI_MAIN_CONTENT=nil
local SAI_MAIN_TITLE="SAI & Phrases Importer"
local SAI_NOI=1
local SAI_IDX={ORI=1,DES=1}



-------------------------------------------------------------------------------------------------
--process slicer (courutines)
-------------------------------------------------------------------------------------------------
local process
class "ProcessSlicer"
function ProcessSlicer:__init(process_func, ...)
  assert(type(process_func)=="function","expected a function as first argument")
  self.__process_func=process_func
  self.__process_func_args=arg
  self.__process_thread=nil
end

function ProcessSlicer:running()
  return (self.__process_thread~=nil)
end

function ProcessSlicer:start()
  assert(not self:running(),"process already running")
  self.__process_thread=coroutine.create(self.__process_func)
  rnt.app_idle_observable:add_notifier(ProcessSlicer.__on_idle, self)
end

function ProcessSlicer:stop()
  assert(self:running(),"process not running")
  rnt.app_idle_observable:remove_notifier(ProcessSlicer.__on_idle,self)
  self.__process_thread = nil
end

function ProcessSlicer:__on_idle()
  assert(self.__process_thread~=nil,"ProcessSlicer internal error: expected no idle call with no thread running") 
  if (coroutine.status(self.__process_thread)=='suspended') then
    local succeeded,error_message=coroutine.resume(self.__process_thread,unpack(self.__process_func_args))
    if (not succeeded) then
      self:stop()
      error(error_message) 
    end
  elseif (coroutine.status(self.__process_thread)=='dead') then
    self:stop()
  end
end



-------------------------------------------------------------------------------------------------
--save all instruments
-------------------------------------------------------------------------------------------------
SAI_PATH_FOLDER=""

local function sai_path_rejected()
  rna:show_error("Save All Instruments\n\nPlease make sure you correctly select a valid & existent path to save the files!\nNo using a protected path (as \"C:\\\")")
  SAI_PATH_FOLDER=""
  vws.SAI_TXT_PATH_FOLDER.text="Destiny folder..."
end

local function sai_path_ins()
  --rearm
  SAI_PATH_FOLDER=""
  vws.SAI_TXT_PATH_FOLDER.text="Destiny folder..."
  --create path
  local path_folder=rna:prompt_for_path(("Select or create + select a folder to save all the instruments XRNI\n"
                                       .."of the current song: \"%s\"\n(matching files will be overwritten!!!)"):format(song.name))
  if (path_folder=="" or path_folder=="C:\\") then
    sai_path_rejected()
  else
    SAI_PATH_FOLDER=path_folder
    vws.SAI_TXT_PATH_FOLDER.text=path_folder
  end
end



local function sai_save_all_ins()
  --save all
  local function save_all_ins(update_progress_func)
    local sii=song.selected_instrument_index
    song.selected_instrument_index=1
    for ins=1,#song.instruments do
      local ins_name=song:instrument(ins).name
      local invalid_char={"%\\","%/","%\:","%*","%?","%\"","%<","%>","%|"} --WINDOWS
      --correct invalid characters
      local ins_name_2=ins_name
      for char=1,#invalid_char do
        ins_name_2=ins_name_2:gsub(invalid_char[char],"") --
      end
      --define filename path
      local filename=("%s%.3d-%.2X-%s"):format(SAI_PATH_FOLDER,ins,ins-1,ins_name_2)
      local plug_prop=song:instrument(ins).plugin_properties
      --with plugin or not
      if not (plug_prop.plugin_loaded) then
        rna:save_instrument(filename)
      else
        if (vws.SAI_CBX_VST_REGISTRY.value) then
          --registry vst instruments
          if (string.match(ins_name,"\:")) then
            --path invalid characters: ("\\/:*?\"<>|")
            filename=("%s%.3d-%.2X-%s"):format(SAI_PATH_FOLDER,ins,ins-1,ins_name_2)
          end
          local file=io.open(filename..".txt","w")
          if (file) then
            local hex_ins=("%.2X"):format(ins-1)
            local vsti_name=plug_prop.plugin_device.name
            local vsti_active_preset=("%.2X"):format(plug_prop.plugin_device.active_preset-1)
            file:write(
              "Song name: "..song.name..".\n"..
              "Song author: "..song.artist..".\n\n"..
              "Instrument index: "..hex_ins..".\n"..
              "Instrument name: "..ins_name..".\n\n"..
              "VSTi name: "..vsti_name..".\n"..
              "VSTi active preset: "..vsti_active_preset.."."
            )
          end
          file:close()
        end
      end
      --unitary progress instrument index
      if (song.selected_instrument_index<#song.instruments) then
        song.selected_instrument_index=song.selected_instrument_index+1
      end
      --show the progress in the GUI
      update_progress_func(ins/(#song.instruments))
      --and periodically give time back to renoise
      coroutine.yield()
    end
    song.selected_instrument_index=sii
    rna:open_path(SAI_PATH_FOLDER)
    rna:show_status(("Save All Instruments: All XRNI instruments have been saved correctly inside the folder: \"%s\"."):format(SAI_PATH_FOLDER))
    vws.SAI_BMP_PROCESS.visible=false
    vws.SAI_BMP_PROCESS.width=5
    vws.SAI_BTT_SAVE.text="Save"
  end

  --bang!
  if io.exists(SAI_PATH_FOLDER) then
    --print("SAI_PATH_FOLDER:",SAI_PATH_FOLDER)
    local function update_progress(progress)
      --print("progress:",progress)
      if (not SAI_MAIN_DIALOG or not SAI_MAIN_DIALOG.visible) then
        --abort processing when the dialog was closed
        process:stop()
        vws.SAI_BMP_PROCESS.visible=false
        vws.SAI_BMP_PROCESS.width=5
        vws.SAI_BTT_SAVE.text="Save"
        return
      end
      --print(255*progress)
      vws.SAI_BMP_PROCESS.width=255*progress
    end
    --start/stop proccess
    local function start_stop_process()
      if (not process or not process:running()) then
        --start
        vws.SAI_BMP_PROCESS.visible=true
        vws.SAI_BTT_SAVE.text="Stop"
        process = ProcessSlicer(save_all_ins, update_progress)
        process:start()
      elseif (process and process:running()) then
        --stop
        process:stop()
        vws.SAI_BMP_PROCESS.visible=false
        vws.SAI_BMP_PROCESS.width=5
        vws.SAI_BTT_SAVE.text="Save"
        rna:open_path(SAI_PATH_FOLDER)
      end
    end
    start_stop_process()
  else
    sai_path_rejected()
  end
end



local function sai_open_folder_ins()
  if io.exists(SAI_PATH_FOLDER) then
    rna:open_path(SAI_PATH_FOLDER)
  else
    sai_path_rejected()
  end
end



local function sai_gui_xrni()
  local gui=vb:column{
    style="group",
    margin=4,
    spacing=3,
    vb:horizontal_aligner{
      mode="center",
      vb:text{
        height=19,
        align="center",
        font="bold",
        --style="strong",
        text="Save All Instruments"
      }
    },
    vb:row{
      vb:button{
        height=19,
        width=59,
        text="Path",
        notifier=function() sai_path_ins() end,
        tooltip="Choose a destination path."
      },
      vb:row{
        margin=1,
        spacing=-255,
        vb:row{
          style="plain",
          margin=-1,
          vb:text{
            id="SAI_TXT_PATH_FOLDER",
            height=19,
            width=257,
            align="center",
            text="Destiny folder..."
          }
        },
        vb:column{
          id="SAI_BMP_PROCESS",
          visible=false,
          width=5,
          vb:bitmap{
            bitmap="ico/process_ico.png"
          }
        }
      },
      vb:row{
        spacing=-1,
        vb:button{
          id="SAI_BTT_SAVE",
          height=19,
          width=59,
          text="Save",
          notifier=function() sai_save_all_ins() end,
          tooltip="Save all instruments of the current song inside the destiny folder.\n(matching files will be overwritten!!!)"
        },
        vb:button{
          height=19,
          width=11,
          notifier=function() sai_open_folder_ins() end,
          tooltip="Open the path window."
        }
      }
    },
    vb:row{
      vb:checkbox{
        id="SAI_CBX_VST_REGISTRY",
        height=19,
        width=19,
        value=true,
      },
      vb:text{
        height=19,
        width=59,
        text="Save the TXT registry of the VST instruments also."
      }
    }
  }
  return gui
end



-------------------------------------------------------------------------------------------------
--phrases importer
-------------------------------------------------------------------------------------------------
local function origin_destiny_xrnz()
  if (SAI_IDX.DES~=SAI_IDX.ORI) then
    --print(SAI_IDX.ORI,SAI_IDX.DES)
    local phrs=#song:instrument(SAI_IDX.ORI).phrases
    --print("phrases:",phrs)
    if (phrs>=1) then
      for phr=1,phrs do
        if (#song:instrument(SAI_IDX.DES).phrases<phr) then
          song:instrument(SAI_IDX.DES):insert_phrase_at(phr)
        end
        song:instrument(SAI_IDX.DES):phrase(phr):copy_from(song:instrument(SAI_IDX.ORI):phrase(phr))
      end
      song.selected_instrument_index=SAI_IDX.DES
      song.selected_phrase_index=1
      rna.window.active_middle_frame=renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR
      vws.SAI_TXT_NAME_DES.text=("[%s xrnz]  %s"):format(#song.selected_instrument.phrases,song.selected_instrument.name)
      vws.SAI_TXT_NAME_DES.width=129
      SAI_MAIN_CONTENT.width=401
    else
      rna:show_error("Phrases Importer\n\nThe origin instrument has no phrases to import!\nPlease select a origin instrument that contains one or more phrases.")
    end
  else
    rna:show_error("Phrases Importer\n\nThe \"Origin\" instrument is the same as the \"Destiny\" instrument!\nSelect two different instruments to import.")
  end
end

local function sai_restart()
  vws.SAI_VBX_NAME_ORI.max=SAI_NOI
  vws.SAI_VBX_NAME_ORI.value=0
  vws.SAI_TXT_NAME_ORI.text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
  vws.SAI_TXT_NAME_ORI.width=261
  ---
  vws.SAI_VBX_NAME_DES.max=SAI_NOI
  vws.SAI_VBX_NAME_DES.value=0
  vws.SAI_TXT_NAME_DES.text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
  vws.SAI_TXT_NAME_DES.width=261
  SAI_MAIN_CONTENT.width=401
end



local function sai_gui_xrnz()
  local gui=vb:column{
    style="group",
    margin=4,
    spacing=3,
    vb:horizontal_aligner{
      mode="center",
      vb:text{
        height=19,
        align="center",
        font="bold",
        --style="strong",
        text="Import All Phrases Between Instruments"
      }
    },
    vb:column{
      spacing=-1,
      vb:row{
        vb:text{
          height=19,
          width=59,
          align="right",
          text="Origin:"
        },
        vb:row{
          spacing=-1,
          vb:valuebox{
            id="SAI_VBX_NAME_ORI",
            height=19,
            width=51,
            min=0,
            max=SAI_NOI,
            value=0,
            tostring=function(value) return("%.2X"):format(value) end,
            tonumber=function(value) return tonumber(value,16) end,
            notifier=function(value)
              SAI_IDX.ORI=value+1
              song.selected_instrument_index=value+1
              vws.SAI_TXT_NAME_ORI.text=("[%s xrnz]  %s"):format(#song.selected_instrument.phrases,song.selected_instrument.name)
              vws.SAI_TXT_NAME_ORI.width=261
              SAI_MAIN_CONTENT.width=401
            end
          },
          vb:button{
            height=19,
            width=11,
            notifier=function() song.selected_instrument_index=vws.SAI_VBX_NAME_ORI.value+1 end,
            tooltip="Select the origin instrument."
          }
        },
        vb:space{width=4},
        vb:text{
          id="SAI_TXT_NAME_ORI",
          height=19,
          width=261,
          align="left",
          text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
        }
      },
      vb:row{
        vb:text{
          height=19,
          width=59,
          align="right",
          text="Destiny:"
        },
        vb:row{
          spacing=-1,
          vb:valuebox{
            id="SAI_VBX_NAME_DES",
            height=19,
            width=51,
            min=0,
            max=SAI_NOI,
            value=0,
            tostring=function(value) return("%.2X"):format(value) end,
            tonumber=function(value) return tonumber(value,16) end,
            notifier=function(value)
              SAI_IDX.DES=value+1
              song.selected_instrument_index=value+1
              vws.SAI_TXT_NAME_DES.text=("[%s xrnz]  %s"):format(#song.selected_instrument.phrases,song.selected_instrument.name)
              vws.SAI_TXT_NAME_DES.width=261
              SAI_MAIN_CONTENT.width=401
            end
          },
          vb:button{
            height=19,
            width=11,
            notifier=function() song.selected_instrument_index=vws.SAI_VBX_NAME_DES.value+1 end,
            tooltip="Select the destiny instrument."
          }
        },
        vb:space{width=4},
        vb:text{
          id="SAI_TXT_NAME_DES",
          height=19,
          width=261,
          align="left",
          text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
        }
      }
    },
    --vb:space{height=4},
    vb:horizontal_aligner{
      mode="center",
      spacing=4,
      vb:button{
        height=19,
        width=59,
        text="Restart",
        notifier=function() sai_restart() end,
        tooltip="Rearm the Origin and Destiny instruments indexes."
      },
      vb:button{
        height=19,
        width=159,
        text="Import All Phrases XRNZ",
        notifier=function() return origin_destiny_xrnz(SAI_IDX.ORI,SAI_IDX.DES) end,
        tooltip="Overwrite existing phrases into the destiny instrument!"
      }
    }
  }
  return gui
end



--main gui
local function sai_main_gui()
  SAI_MAIN_CONTENT=vb:column{
    margin=4,
    spacing=4,
    width=401,
    sai_gui_xrni(),
    sai_gui_xrnz()
  }
  return SAI_MAIN_CONTENT
end



--check number_of_instruments
local function sai_noi()
  SAI_NOI=#song.instruments-1
  --print("SAI_NOI",SAI_NOI)
  vws.SAI_VBX_NAME_ORI.max=SAI_NOI
  if (vws.SAI_VBX_NAME_ORI.value>SAI_NOI) then
    vws.SAI_VBX_NAME_ORI.value=SAI_NOI
  end
  vws.SAI_VBX_NAME_DES.max=SAI_NOI
  if (vws.SAI_VBX_NAME_DES.value>SAI_NOI) then
    vws.SAI_VBX_NAME_DES.value=SAI_NOI
  end  
  --print(vws.SAI_VBX_NAME_ORI.value)
  --print(vws.SAI_VBX_NAME_DES.value)
end

local function sai_noi_obs()
  if not song.instruments_observable:has_notifier(sai_noi) then
    song.instruments_observable:add_notifier(sai_noi)
    sai_noi()
  end
end



--check name of instrument
local function sai_nme()
  --print(song.selected_instrument_index-1,vws.SAI_VBX_NAME_ORI.value)
  if (song.selected_instrument_index-1==vws.SAI_VBX_NAME_ORI.value) then
    vws.SAI_TXT_NAME_ORI.text=("[%s xrnz]  %s"):format(#song.selected_instrument.phrases,song.selected_instrument.name)
  end
  if (song.selected_instrument_index-1==vws.SAI_VBX_NAME_DES.value) then
    vws.SAI_TXT_NAME_ORI.text=("[%s xrnz]  %s"):format(#song.selected_instrument.phrases,song.selected_instrument.name)
  end
end

local function sai_nme_obs()
  if not song.selected_instrument.name_observable:has_notifier(sai_nme) then
    song.selected_instrument.name_observable:add_notifier(sai_nme)
  end
end



local function sai_sii()
  local noi=#song.instruments
  for ins=1,noi do
    if song:instrument(ins).name_observable:has_notifier(sai_nme) then
      song:instrument(ins).name_observable:remove_notifier(sai_nme)
    end
  end
  if not song.selected_instrument.name_observable:has_notifier(sai_nme) then
    song.selected_instrument.name_observable:add_notifier(sai_nme)
  end
end

local function sai_sii_obs()
  if not song.selected_instrument_index_observable:has_notifier(sai_sii) then
    song.selected_instrument_index_observable:add_notifier(sai_sii)
  end
end



local function sai_noi_restart()
  SAI_NOI=#song.instruments-1
  --print("SAI_NOI",SAI_NOI)
  vws.SAI_VBX_NAME_ORI.max=SAI_NOI
  vws.SAI_VBX_NAME_ORI.value=0
  vws.SAI_TXT_NAME_ORI.text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
  vws.SAI_VBX_NAME_DES.max=SAI_NOI
  vws.SAI_VBX_NAME_DES.value=0
  vws.SAI_TXT_NAME_DES.text=("[%s xrnz]  %s"):format(#song:instrument(1).phrases,song:instrument(1).name)
  --print(vws.SAI_VBX_NAME_ORI.value)
  --print(vws.SAI_VBX_NAME_DES.value)

  --check noi & nme
  sai_noi_obs()
  sai_nme_obs()
  sai_sii_obs()
end



--launch gui
local function sai_main_dialog()
  --main gui
  if (SAI_MAIN_CONTENT==nil) then
    sai_main_gui()
  end

  --check noi & nme
  sai_noi_obs()
  sai_nme_obs()
  sai_sii_obs()

  --avoid showing the same window several times!
  if (SAI_MAIN_DIALOG) and (SAI_MAIN_DIALOG.visible) then SAI_MAIN_DIALOG:show() return end

  --custom dialog
  SAI_MAIN_DIALOG=rna:show_custom_dialog(("%s"):format(SAI_MAIN_TITLE),SAI_MAIN_CONTENT)

  --restart noi in new song
  if not rnt.app_new_document_observable:has_notifier(sai_noi_restart) then
    rnt.app_new_document_observable:add_notifier(sai_noi_restart)
  end
end
_AUTO_RELOAD_DEBUG=function() sai_main_dialog() end



-------------------------------------------------------------------------------------------------
--register menu entry
rnt:add_menu_entry{
  name="Instrument Box:Save All Instruments...",
  invoke=function() sai_main_dialog() end
}



-------------------------------------------------------------------------------------------------
--register menu entry
rnt:add_menu_entry{
  name="Instrument Box:Phrases Importer...",
  invoke=function() sai_main_dialog() end
}
