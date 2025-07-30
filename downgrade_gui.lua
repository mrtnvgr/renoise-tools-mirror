--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------
 

function show_downgrade_dialog()

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
  
  local CONTROL_MARGIN = 
    renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  
  local TEXT_ROW_WIDTH = 80     

  if helper_dialog and helper_dialog.visible then
    helper_dialog:show()
    return
  end
  
  local dialog_title = "Convert song to speed model"
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,    
    
    vb:column 
    {
      style = "panel",
      margin = CONTROL_MARGIN,
      
      vb:horizontal_aligner {
        mode = "center",
        spacing = CONTENT_SPACING,
        
        vb:checkbox {
          value = true,
          id="checkbox_replace_zk"
        },
        
        vb:text {
          width = 180,
          text = "Replace ZK command with ZL"
        },
      },        
    },
        
    vb:horizontal_aligner {
      margin = CONTROL_MARGIN,      
      mode = "center",         
      vb:button {
        width = 100,
        height = DEFAULT_DIALOG_BUTTON_HEIGHT,
        text = "Downgrade",   
        notifier = function()
          call_downgrade(vb.views.checkbox_replace_zk.value)
        end     
      },
    },
  }
  
  downgrade_dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)  
  
end




function show_downgrade_log_dialog(message)

  --local vb = renoise.ViewBuilder()
  local dialog_title = "Downgrade Log"
  local dialog_buttons = {"Close"};
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN 
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local downgrade_log_dialog = nil

  local dialog_content = vb:column {
    margin = DEFAULT_MARGIN,

    vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,
      
      vb:multiline_textfield {        
        width = 500,
        height = 200, 
        value = message
      }      
    },
    
    vb:horizontal_aligner {
      mode = "distribute",
      margin = 8,
      spacing = 8,
      
      vb:button {      
        height = DEFAULT_DIALOG_BUTTON_HEIGHT,
        text = "Close",
        notifier = function()          
          downgrade_log_dialog:close();          
        end      
      },      
    }
    
  }

  downgrade_log_dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)  
  
end
