local dialog_about = nil
local title_about = " PhraseTouch:  About  &  User Guide"



------------------------------------------------------------------------------------------------
--about
local PHT_ABOUT_TFD = 
  "TOOL NAME: PhraseTouch\n"..
  "MODULES: Step Sequencer & FavTouch\n"..
  "VERSION: "..pht_version.." \n"..
  "COMPATIBILITY: Renoise "..rns_version.." (tested under Windows 10)\n"..
  "OPEN SOURCE: Yes\n"..
  "LICENCE: GNU GPL (GNU General Public Licence). Prohibited any use of commercial ambit.\n"..
  "CODE: LUA 5.1 + API Renoise "..rns_version.."\n"..
  "DEVELOPMENT DATE: February to May 2018\n"..
  "PUBLISHED: June 2018\n"..
  "LOCATE: Spain\n"..
  "PROGRAMMER: ulneiz\n"..
  "CONTACT AUTHOR: in the Renoise Forums ( http://forum.renoise.com/ ), search: \"ulneiz\" member"
---
local PHT_ABOUT = vb:column { spacing = 3,
  vb:text {
    font = "big",
    text = "About PhraseTouch"
  },
  vb:row { spacing = -96,
    vb:row { style = "plain", margin = 5,
      vb:text {
        --height = 100,
        width = 550,
        text = PHT_ABOUT_TFD
      }
    },
    vb:row { spacing = -3,
      vb:button {
        height = 29,
        width = 34,
        bitmap = "./ico/phr_ico.png",
        notifier = function() show_tool_dialog() end,
        tooltip = "Show PhraseTouch window...[Ctrl + Alt + P, assignable by the user!]"
      },
      vb:button {
        height = 29,
        width = 34,
        bitmap = "./ico/seq_ico.png",
        notifier = function() show_tool_dialog_sequencer() end,
        tooltip = "Show Step Sequencer window...\n[Ctrl + Q]  [Ctrl + Alt + Q, to close]"
      },
      vb:button {
        height = 29,
        width = 34,
        bitmap = "./ico/fav_ico.png",
        notifier = function() show_tool_dialog_fav() end,
        tooltip = "Show FavTouch window...\n[Ctrl + F]  [Ctrl + Alt + F, to close]"
      }      
    }
  }
}



------------------------------------------------------------------------------------------------
--user guide
local function pht_user_guide_path()
  local dir = os.currentdir() --dir for tool
  local html = "user_guide/phrasetouch_user_guide_en.html"
  local guide = "file:///"..dir..html
  --print("guide", guide)
  return guide
end
---
local function pht_user_guide_folder()
  local dir = os.currentdir()
  local folder = dir.."user_guide/"
  return folder
end
---
local PHT_USER_GUIDE = vb:column { spacing = 3,
  vb:text {
    font = "big",
    text = "PhraseTouch User Guide"
  },
  vb:row { style = "plain", margin = 5,
    vb:text {
      height = 25,
      width = 300,
      text = "Use a browser to read the HTML PhraseTouch User Guide:"
    },
    vb:row { spacing = -2,
      vb:button {
        height = 25,
        width = 218,
        text = "Show PhraseTouch User Guide (HTML)",
        notifier = function() rna:open_url( pht_user_guide_path() ) end,
        tooltip = ""..pht_user_guide_path()
      },
      vb:button {
        height = 25,
        width = 34,
        bitmap = "./ico/folder_g_ico.png",
        notifier = function() rna:open_path( pht_user_guide_folder() ) end,
        tooltip = "Open the folder that contains the User Guide:\n"..pht_user_guide_folder()
      }
    }
  }
}



local content_about = vb:column { margin = 5, spacing = 5,
  PHT_ABOUT,
  PHT_USER_GUIDE
}



------------------------------------------------------------------------------------------------
--show dialog_about
function show_tool_dialog_about()
  --Avoid showing the same window several times!
  if ( dialog_about and dialog_about.visible ) then dialog_about:show() return end
  dialog_about = rna:show_custom_dialog( title_about, content_about, pht_keyhandler )
end
