--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------
 

function show_helper_dialog()

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

  if helper_dialog and helper_dialog.visible then
    helper_dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()
  
  -- tpl
  local tpl_valuebox = vb:text {
    id = "tpl_valuebox",
    text = tostring(renoise.song().transport.tpl),    
    align = "center",    
    width=30,        
    --active = false,  
    --[[
    notifier = function(value)
    
      --value = math.floor(value)
    
      --local message = 'Ticks = '
      
      --message = message .. value
      
      --value = renoise.song().transport.tpl
      
    end,
    min = 1,
    max = 31
    ]]
  }
  
  -- portamento up / down
  local portamento_slider = vb:valuebox {
    value = 0,
     tostring = function(val) 
        local sign = ''
        if (val < 0) then sign = '-' end
        return ("%s0x%.2X"):format(sign, math.abs(val))
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,
    notifier = portamento_changed,
    min = -0xff,
    max = 0xff
  }
  
  -- tempo
  local tempo_valuebox = vb:valuebox {
    value = 0x7D,
     tostring = function(val) 
        return ("0x%.2X"):format(val)
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,
    notifier = tempo_changed,
    min = 0x20,
    max = 0xFF
  }
  
  -- volume slide up / down
  local volume_valuebox = vb:valuebox {
    value = 0,
    tostring = function(val)     
        local sign = ''
        if (val < 0) then sign = '-' end
        return ("%s0x%.2X"):format(sign, math.abs(val))
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,
    notifier = volume_changed,
    min = -0x0f,
    max = 0x0f
  }
  
  
  -- fine portamento up / down
  local fine_portamento = vb:valuebox {
    value = 0,
    tostring = function(val) 
        local sign = ''
        if (val < 0) then sign = '-' end
        return ("%s0x%.2X"):format(sign, math.abs(val))
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,     
    notifier = fine_portamento_changed,
    min = -0x0f,
    max = 0x0f
  }
  
  -- fine volume slide up / down
  local fine_volslide = vb:valuebox {
    value = 0,    
    tostring = function(val) 
        local sign = ''
        if (val < 0) then sign = '-' end
        return ("%s0x%.2X"):format(sign, math.abs(val))
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,     
    notifier = fine_volumeslide_changed,
    min = -0x0f,
    max = 0x0f
  }
  
  -- checkbox note validation
  local checkbox_note_validation = vb:checkbox {
    --value = note_validation,
    notifier = function(value)
      my_options.note_validation.value = value;
    end,
  }
  
  
  
  -- bpm valuebox
  --[[
  local bpm_valuebox = vb:valuebox {    
    id = "bpm_valuebox",
    tostring = function(val) 
        local sign = ''
        if (val < 0) then sign = '-' end
        return ("%s0x%.2X"):format(sign, math.abs(val))
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,
    value = renoise.song().transport.bpm,    
    min = 20,
    max = 0xff   
  }  
  ]]
  
  -- popup format for note validation
  local popup_fmt_val = vb:popup {
      id = "popup_fmt_val",           
      value = fmt_note_validation,
      items = {"XM", "MOD (Ext)", "MOD (Amiga)", "None"},
      active = enable_note_validation,
      notifier = function(new_index)
        
        my_options.fmt_note_validation.value = new_index
      
        local popup = vb.views.popup_fmt_val
        
        local cur_value = popup.items[new_index]
        
      end
  }  
  
  -- close button   
  local close_button_row = vb:horizontal_aligner {
    mode = "center",
    
    vb:button {
      text = "Close",
      width = 60,
      height = DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
        helper_dialog:close()
      end,
    }
  }
  
  -- dialog content
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    vb:horizontal_aligner {
      mode = "center",
      spacing = CONTENT_SPACING,
      
      vb:text {
        text = "Ticks ",        
      },
      
      vb:column {    
        style="border",                        
        tpl_valuebox
      },
      
    },        

    --[[    
    vb:space {
        height = DEFAULT_CONTROL_HEIGHT
    },
    ]]
        
    vb:column 
    {
    
      style = "panel",
      margin = CONTENT_MARGIN,            
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        vb:text {
          text = "Portamento",        
        },
              
        portamento_slider,
        
        vb:button
        {
          text="O",
          notifier= function() portamento_changed(portamento_slider.value) end
        },              
        
      },    
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        vb:text {
          text = "Fine Portamento",        
        },
        
        fine_portamento,
        
        vb:button
        {
          text="O",
          notifier= function() fine_portamento_changed(fine_portamento.value) end
        },
        
      },    
            
      vb:space {
          height = DEFAULT_CONTROL_HEIGHT          
      },
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        
        vb:text {
          text = "Volume slide",        
        },
        
        volume_valuebox,
        
        vb:button
        {
          text="O",
          notifier= function() volume_changed(volume_valuebox.value) end
        },        
        
      },          
            
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        vb:text {
          text = "Fine Volume slide",        
        },
        
        fine_volslide,
        
        vb:button
        {
          text="O",
          notifier= function() fine_volumeslide_changed(fine_volslide.value) end
        },         
        
      },    
      
      vb:space {
          height = DEFAULT_CONTROL_HEIGHT          
      },
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        
        vb:text {
           text = "Default volume",                 
        },
        
        vb:valuebox {
          id = "default_volume",
          value = g_default_volume,           
          notifier = function(val)
            g_default_volume = val
          end,
          min = 0,
          max = 64
        },
        
        vb:button
        {
          text="O",
          notifier = function() 
            default_volume()
          end
        },        
        
      },          
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        
        vb:text {
           text = "Range note validation",              
        },
        
        popup_fmt_val            
        
      },          
      
      --[[
      vb:column
      {                
        spacing = CONTENT_SPACING,
        
        vb:row {
          vb:text {
            text = "Default volume",     
            width = 110     
          },
          
          vb:valuebox {
            id = "default_volume",
            value = g_default_volume,           
            notifier = function(val)
              g_default_volume = val
            end,
            min = 0,
            max = 64
          },
          vb:button
          {
            text="O",
            notifier = function() 
              default_volume()
            end
          },        
        },
        vb:row {
          vb:text {
            text = "Range note validation",        
            width = 110 
          },
          
          popup_fmt_val            
        },       
        
      },
      ]]
      
      vb:space {
          height = DEFAULT_CONTROL_HEIGHT          
      },
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = CONTENT_SPACING,
        
        
        vb:text {
          text = "Module tempo",        
        },
        
        tempo_valuebox,
        
        vb:button
        {
          text="O",
          notifier= function() match_tempo_with_ticks(tempo_valuebox.value) end
        },        
        
      },          
      
      
    },
    
    vb:horizontal_aligner {      
      mode = "distribute",        
      margin = CONTENT_MARGIN,
      
      vb:text
      {
        text = "Key bindings available",
        font = "italic"          
      },
    }
    
    --[[
    vb:horizontal_aligner {
      mode = "center",
      spacing = CONTENT_SPACING,
      margin=CONTENT_MARGIN,
      
      close_button_row
      
    },    
    ]] 
    
  }
  
  helper_dialog = renoise.app():show_custom_dialog(
    "Xrns2XMod Helper", dialog_content
  ) 
  
end
