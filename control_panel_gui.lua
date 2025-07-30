--------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------- 

local function get_app_path(value)

  local output = nil

  if value == "" then
    output = "Click .. button"
  elseif is_app_located == false then
    output = "Application path is invalid"
  else
    output = string.len(app_path) > 50 and string.sub(app_path, 1, 50) .. '..' or app_path
  end
  
  return output
end

--------------------------------------------------------------------------------
-- gui
-------------------------------------------------------------------------------- 

function show_controlpanel_dialog()

  vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  
  local CONTENT_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  local CONTENT_MARGIN = 
    renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  
  local DEFAULT_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  
  local DEFAULT_DIALOG_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local DEFAULT_MINI_CONTROL_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  
  local TEXT_ROW_WIDTH = 80     

  if controlpanel_dialog and controlpanel_dialog.visible then
    controlpanel_dialog:show()
    return
  end
  
  local dialog_title = "Xrns2XMod Control Panel"
  
  -- bitmap
  local bitmap_logo = vb:button {
    -- recolor to match the GUI theme:
    --mode = "plain",
    width = 180,
    height = 43,
    bitmap = "images/xrns2xmod_logo.bmp",
    notifier = function()
      renoise.app():open_url(XRNS2XMOD_URL);
    end
  }  
  
  local text_app_path = vb:text
  {
    id = "text_app_path",
    width = 140,
    align = "center",
    text = get_app_path(app_path),
    tooltip = app_path,          
  }     
  
  -- download button
  local button_download = vb:button {
    id = "button_download",
    text = "Download",    
    width = 100,   
    height = DEFAULT_DIALOG_BUTTON_HEIGHT,
    notifier = function()
      renoise.app():open_url(XRNS2XMOD_URL);
    end,
  }
   
  -- button locate
  local button_locate_app = vb:button {    
    text = "...",   
    width = 30,   
    notifier = function()
    
      local exe_file = renoise.app():prompt_for_filename_to_read({XRNS2XMOD_EXE}, "Locate Xrns2XMod Path");
  
      local is_app_found = #exe_file > 0
      
      if (is_app_found) then
        my_options.app_path.value = exe_file;            
        text_app_path.text = get_app_path(app_path)              
      end  
      
    end,
  }
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:horizontal_aligner {      
      mode = "center",      
      
      bitmap_logo
    },
    
    --vb:space {height = (CONTENT_MARGIN)},              
      
    vb:horizontal_aligner {
    
      mode = "distribute",
      --spacing = 20,
      margin = CONTENT_MARGIN,
      button_download,           
             
    },
    
    --vb:space {height = (CONTENT_MARGIN)},    
    
    vb:column
    {
      style = "group",
      
      vb:horizontal_aligner {      
        mode = "center",        
        margin = CONTENT_MARGIN,
        spacing = CONTENT_SPACING,
        
        vb:text
        {
          text = "Path",          
        },          
        
        vb:column {          
          style = "plain",      
          text_app_path     
        },     
        
        button_locate_app,         
        
      },   
      
      vb:horizontal_aligner {      
        mode = "right",        
        margin = CONTENT_MARGIN,
        
        vb:text
        {
          text = "Enable note validation"
        },
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:checkbox
        {
          value = enable_note_validation,          
          notifier = function(value)
            
            my_options.enable_note_validation.value = value
            
            toggle_notifier_for_note_validation(value)
            
          end          
        }
        
      },
      
      vb:horizontal_aligner {      
        mode = "right",        
        margin = CONTENT_MARGIN,
        
        vb:text
        {
          text = "Enable instrument settings"          
        },
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:checkbox
        {
          value = enable_instrument_settings,
          notifier = function(value)
            
            my_options.enable_instrument_settings.value = value
            
            toggle_notifier_for_instrument_settings(value)
            
          end          
        }
        
      },
      
      vb:horizontal_aligner {      
        mode = "distribute",        
        margin = CONTENT_MARGIN,
        
        vb:text
        {
          text = "* Disable features to avoid unused routines call",
          font = "italic"          
        },
      }
      
    },
    
       
    
  }
  
  controlpanel_dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)  
  
end
