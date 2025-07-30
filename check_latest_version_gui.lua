

function show_latestversion_dialog()

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
  
  local CONTENT_WIDTH = 250

  if latest_version_dialog and latest_version_dialog.visible then
    latest_version_dialog:show()
    return
  end
  
  local dialog_title = "Xrns2XMod Latest Version Info"
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,    
    
    vb:column
    {      
      style = "panel",
      margin = CONTENT_MARGIN,  
      width = CONTENT_WIDTH,
       
      vb:horizontal_aligner
      {
        margin = CONTENT_MARGIN,
        mode = "right",        
        
        vb:text
        {
          text = "Version number",            
        },
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:textfield
        { 
          align = 'center',
          active = false,     
          width = 80,
          value = version_number        
        }     
         
      },    
      
      vb:space {height = (CONTENT_MARGIN)},
      
      vb:horizontal_aligner
      {
        margin = CONTENT_MARGIN,
        mode = "right",
        
        vb:text
        {
          text = "Release date",            
        },
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:textfield
        { 
          align = 'center',
          active = false,     
          width = 80,
          value = release_date
        }     
         
      },    
      
      vb:space {height = (CONTENT_MARGIN)},
      
    },
    
    vb:horizontal_aligner
    {
      margin = CONTENT_MARGIN,
      mode = "center",
      
      vb:button
      {
        text = "Download",    
        width = 100,   
        notifier = function()
          renoise.app():open_url(download_url);
        end,
      }
    }
    
  }
  
  latest_version_dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)  
  
end
