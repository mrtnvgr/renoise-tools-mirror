--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------


function show_converter_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.  
  
  -- The ViewBuilder is the basis
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
  
  
  if converter_dialog and converter_dialog.visible then
    converter_dialog:show()
    return
  end
  
  
   ---- CONTROL ROWS
   
  -- text app located status
  local text_app_located_status = vb:text {
    align = "right",
    text = is_app_located and "application found" or "application not found";            
  }
  
  -- download button
  local button_download = vb:button {
    id = "button_download",
    text = "Download",    
    width = 100,   
    visible = is_app_located == false,
    notifier = function()
      renoise.app():open_url(XRNS2XMOD_URL);
    end,
  }
   
  -- button locate
  local button_locate_app = vb:button {    
    text = "Locate",   
    width = 100,   
    notifier = function()
      locate_app();
    end,
  }
  
  -- button check for updates
  --[[
  local button_check_for_updates = vb:button {    
    id = "button_check_for_updates",
    text = "Check Version",   
    --bitmap = "images/world.bmp",    
    width = 100,   
    --height = 20,
    visible = is_app_located == true,
    notifier = function()
      get_last_app_version();
    end,
  }
  ]]
  -- button video tutorial
  local button_video_tutorial = vb:button {    
    id = "button_video_tutorial",
    text = "Tutorial video",   
    --bitmap = "images/world.bmp",    
    width = 100,   
    --height = 20,
    visible = is_app_located == true,
    notifier = function()
      renoise.app():open_url(XRNS2MOD_TUTORIAL_VIDEO_URL);      
    end,
  }
  
  -- button open documentation
  local button_open_documentation = vb:button {    
    id = "button_open_documentation",
    text = "Documentation",   
    --bitmap = "images/world.bmp",    
    width = 100,   
    --height = 20,
    visible = is_app_located == true,
    notifier = function()
      renoise.app():open_url(XRNS2XMOD_DOC_URL);
    end,
  }
  
  -- text app version
  local text_app_version = vb:text {
    id = "text_app_version"
  }
  
  -- checkbox convert frequency
  --[[
  local checkbox_convfreq = vb:checkbox {
    active = conv_type_value == TYPE_MOD,
    value = convfreq,
    notifier = function(value)      
      --convfreq = value;
      my_options.convfreq.value = value;
    end,
  }
  ]]
  
  -- checkbox pro tracker compatibility
  -- deprecated
  --[[
  local checkbox_protracker_comp = vb:checkbox {
    -- active = conv_type_value == TYPE_MOD,
    value = ptmode,
    notifier = function(value)
      my_options.ptmode.value = value;
    end,
  }
  ]]
  
  -- popup protracker compatibility mode
  local popup_protracker_comp_mode = vb:popup {
      id = "popup_protracker_comp_mode",           
      items = { "None", "Software", "Hardware" },
      value = pt_comp_mode,
      notifier = function(new_index)
         
         pt_comp_mode = new_index
         
         renoise.app():show_status(("Protracker compatibility mode changed to %s"): format(vb.views.popup_protracker_comp_mode.items[new_index]))
               
      end
  }
  
  -- popup frequency mode
  local popup_protracker_freq_mode = vb:popup {
      id = "popup_protracker_freq_mode",           
      items = { "PAL", "NTSC" },
      value = pt_freq_mode,
      notifier = function(new_index)
         
         pt_freq_mode = new_index
         
         renoise.app():show_status(("Protracker frequency mode changed to %s"): format(vb.views.popup_protracker_freq_mode.items[new_index]))
               
      end
  }
  
  -- valuebox portamento accuracy threshold value for mod
  local valuebox_portamento_acc_threshold = vb:valuebox {
    -- active = conv_type_value == TYPE_MOD,
    value = portamento_accuracy_threshold,
    min = 0,
    max = 4,
    notifier = function(value)
      my_options.portamento_accuracy_threshold.value = value;
    end
  }
  
  -- checkbox resample volume
  --[[
  local checkbox_resample_vol = vb:checkbox {
    value = modvol,
    notifier = function(value)
      my_options.modvol.value = value
    end,
  }
  ]]
  
  
  -- valuebox initial_tempo value
  local valuebox_tempo = vb:valuebox {
    id = "valuebox_tempo",
    min = 32,
    max = MAX_BPM,        
    value = initial_tempo,
    -- active = conv_type_value == TYPE_XM,
    
    notifier = function(value)
      renoise.app():show_status(("Initial tempo value changed to '%d'"):
          format(value))
      my_options.initial_tempo.value = value;
    end
  }  
  
  
  -- valuebox initial ticks value
  local valuebox_ticks = vb:valuebox {
    id = "valuebox_ticks",
    min = 1,
    max = 32,        
    value = initial_ticks,
    -- active = conv_type_value == TYPE_XM,
    
    notifier = function(value)
      renoise.app():show_status(("Initial ticks value changed to '%d'"):
          format(value))
      my_options.initial_ticks.value = value;
    end
  }  
  
  -- group box settings for mod
  local group_mod_options = vb:horizontal_aligner
  {
      mode = "right",        
      margin = 3,
      visible = conv_type_value == TYPE_MOD,
      
        vb:column
        {
          style = "group",
          margin = 8,   
          
          vb:horizontal_aligner {
            mode = "right",
            spacing = 3,
            
            vb:text {
              text = "ProTracker compatibility mode",        
            },
            
            -- checkbox_protracker_comp
            popup_protracker_comp_mode
          },      
          
          vb:horizontal_aligner {
            mode = "right",
            spacing = 3,
            
            vb:text {
              text = "Frequency mode",        
            },
            
            popup_protracker_freq_mode
          },      
          
          vb:horizontal_aligner {
            mode = "right",
            spacing = 3,
            
            vb:text {
              text = "Portamento accuracy threshold",        
            },
            
            valuebox_portamento_acc_threshold
          },      
      }
  }   
  
  -- group box settings for xm
  local group_xm_options = vb:horizontal_aligner {
    mode = "right",   
    margin = 3,             
    visible = conv_type_value == TYPE_XM,
    
      vb:column
      {
        style = "group",
        margin = 8,   
        
        vb:horizontal_aligner {
          mode = "right",
          spacing = 3,
          
          vb:text {
            text = "Initial tempo",        
          },
          
          valuebox_tempo
        },    
    
        vb:horizontal_aligner {
          mode = "right",
          spacing = 3,
          
          vb:text {
            text = "Initial ticks",        
          },
          
          valuebox_ticks
        },  
          
      },
  }
  
  -- popup format
  local popup_format = vb:popup {
      id = "popup",           
      value = conv_type_value,
      items = {"XM", "MOD"},
      notifier = function(new_index)
      
        my_options.conv_type_value.value = new_index;
        
        output_file = ""
      
        local popup = vb.views.popup
        
        local cur_value = popup.items[new_index];
        
        renoise.app():show_status(("format value changed to %s"): format(cur_value))
        
        if cur_value == "XM" then
          group_mod_options.visible = false
          group_xm_options.visible = true
          --conv_type = "xm";
          --checkbox_convfreq.active = false;
          
          --[[
          checkbox_protracker_comp.active = false
          valuebox_portamento_acc_threshold.active = false
          valuebox_tempo.active = true
          valuebox_ticks.active = true
          ]]          
        elseif cur_value == "MOD" then
          group_mod_options.visible = true
          group_xm_options.visible = false
          --conv_type = "mod";
          --checkbox_convfreq.active = true;
          --[[
          checkbox_protracker_comp.active = true
          valuebox_portamento_acc_threshold.active = true
          valuebox_tempo.value = DEFAULT_BPM
          valuebox_ticks.value = DEFAULT_TICKS_ROW            
          valuebox_tempo.active = false
          valuebox_ticks.active = false
          ]]
        end
        
        vb.views.popup_volume_scaling.items = get_volume_scaling_items(cur_value)
        
        vb.views.popup_volume_scaling.value = VOLUME_SCALING_SAMPLE
                 
      end
  }
  
  -- popup volume_scaling
  local popup_volume_scaling = vb:popup {
      id = "popup_volume_scaling",           
      items = get_volume_scaling_items(popup_format.items[popup_format.value]),
      value = volume_scaling,      
      notifier = function(new_index)
         
         volume_scaling = new_index
         
         renoise.app():show_status(("volume scaling changed to %s"): format(vb.views.popup_volume_scaling.items[new_index]))
               
      end
  }
  
  
  -- convert button   
  local button_convert = 
    vb:button {
      id = "button_convert",
      active = is_app_located,
      text = "Convert",
      width = 60,
      height = DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
        start_conversion();
      end,
    }
  
  
  
  -- close button   
  local close_button_row = vb:horizontal_aligner {
    mode = "right",
    
    vb:button {
      text = "Close",
      width = 60,
      height = DEFAULT_DIALOG_BUTTON_HEIGHT,
      notifier = function()
        converter_dialog:close()
      end,
    }
  }
  
  local button_bass_registration = vb:button {
    text = "Bass Audio",
    notifier = function()
      init_bass_dialog();      
    end
  }
  
  
  --[[
  local button_downgrade = vb:button {
    text = "Downgrade",     
    width = 100,   
    active = renoise.song().transport.timing_model == renoise.Transport.TIMING_MODEL_LPB,
    notifier = function()    
      show_downgrade_dialog()
    end
  }
  ]]
  
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
  
   ---- MAIN CONTENT & LAYOUT
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    --[[
    vb:horizontal_aligner {      
      mode = "center",      
      
      bitmap_logo
    },
    ]]
    
    --[[
    vb:space {height = (CONTENT_MARGIN)},              
      
    vb:horizontal_aligner {
      mode = "distribute",
      
      button_download,            
      --button_check_for_updates,
      button_video_tutorial,
      button_open_documentation
    },
    
    vb:space {height = (CONTENT_MARGIN)},    
        
    vb:horizontal_aligner {            
      mode = "center",
                  
      button_locate_app,                         
    },
    
    vb:horizontal_aligner {            
      mode = "center",
                  
      button_downgrade,                         
    },
    ]]
    
    vb:space {height = (CONTENT_MARGIN)},    
         
    vb:column 
    {
      style = "panel",
      margin = 8,   
      
      vb:horizontal_aligner {
        mode = "right",
        spacing = 8,
        
        vb:text {
          text = "Destination Format",        
        },
        
        popup_format,
        
      },          
         
      vb:horizontal_aligner {
        mode = "right",
        spacing = 3,
        
        vb:text {
          text = "Volume scaling mode",        
        },
        
        --checkbox_resample_vol      
        popup_volume_scaling
      },   
      
      group_mod_options,
      
      group_xm_options
            
      
      --[[
      vb:horizontal_aligner {
        mode = "right",
        spacing = 3,
        
        vb:text {
          text = "Convert all samples to 8363 Hz (MOD only)",        
        },
        
        checkbox_convfreq
      },      
      ]]
      
          
         
    },
      
    vb:space {height = (CONTENT_MARGIN)},              
    
    vb:horizontal_aligner {
      mode = "right",
      spacing = 3,
            
      button_bass_registration,      
    },   
    
    vb:horizontal_aligner {
      mode = "center",      
      
      button_convert
    },   
  
    -- close    
    -- close_button_row
  }
  
  -- DIALOG  
  converter_dialog = renoise.app():show_custom_dialog("Xrns2XMod Converter", dialog_content)
  
end

function show_conversion_log_dialog(message)

  --local vb = renoise.ViewBuilder()
  local dialog_title = "Conversion Log"
  local dialog_buttons = {"Close", "Open file location"};
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN 
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local conversion_log_dialog = nil
  
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
          conversion_log_dialog:close();          
        end      
      },
      
      vb:button {      
        height = DEFAULT_DIALOG_BUTTON_HEIGHT,
        active = io.exists(output_file),
        text = "Open file location",
        notifier = function()
          if io.exists(output_file) then
            renoise.app():open_path(output_file);
          end
        end      
      }
    }
    
  }

  conversion_log_dialog = renoise.app():show_custom_dialog(dialog_title, dialog_content)  
  
end

