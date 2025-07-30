--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------
 

function show_instrument_settings_dialog()

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

  if instrument_settings_dialog and instrument_settings_dialog.visible then
    instrument_settings_dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()
  
  local POPUP_INSTR_SAMPLE_HANDLER = 1
  local POPUP_FREQ_HANDLER = 2
  local VALUEBOX_FREQ_HANDLER = 3
  local POPUP_BASENOTE_HANDLER = 4
  
  local disable_set_instrument = false -- flag for enable/disable save value settings
  
  -- triggered on instrument / sample change
  local function load_instrument_settings(instument, sample, handler)

    print('load_instrument_settings [start]' .. instument, sample, handler)
    
    local volume = load_instrument_volume(instument, sample)
    --local freq = load_instrument_frequency(instument, sample)
    vb.views.valuebox_volume.value = tonumber(volume)    
    vb.views.popup_sinc.value = load_instrument_sinc(instument, sample)
  
    --if handler == POPUP_INSTR_SAMPLE_HANDLER then
      disable_set_instrument = true
      --print('status disable_set_instrument: ' .. tostring(disable_set_instrument))
      vb.views.popup_sample_frequency.value = load_instrument_frequency(instument, sample)
      --print('status disable_set_instrument: ' .. tostring(disable_set_instrument))
      vb.views.valuebox_frequency.value = load_instrument_frequency_rate(instument, sample)
      --print('status disable_set_instrument: ' .. tostring(disable_set_instrument))
      vb.views.popup_basenote.value = load_instrument_basenote(instument, sample)    
      disable_set_instrument = false
    --end
    
    print('load_instrument_settings [end]' .. instument, sample, handler)
    
  end
  
  -- dialog content
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,    
    
    vb:horizontal_aligner {
          mode = "center",
          spacing = CONTENT_SPACING,
          
          vb:text {
            text = "Output module settings",       
            font = "bold" 
          },          
          
        },        
    
    vb:column 
    {
      style = "panel",
      margin = CONTENT_MARGIN,  
      
       --[[
       vb:horizontal_aligner {
          mode = "center",
          spacing = CONTENT_SPACING,
          
          vb:text {
            text = "Output",       
            font = "bold" 
          },          
          
        },        
      ]]    
    
      vb:horizontal_aligner
      {
        margin = CONTENT_MARGIN,
        mode = "right",        
       
        vb:popup
        {          
          id = "instrument_list",
          width = 150,
          items = get_instrument_names(),          
          notifier = function(val)
            vb.views.sample_list.items = get_samples(val)            
            load_instrument_settings(val, vb.views.sample_list.value, POPUP_INSTR_SAMPLE_HANDLER)
          end
        },          
    
        vb:popup
        {
          id = "sample_list",
          width = 150,
          items = get_samples(vb.views.instrument_list.value),
          notifier = function(val)
            load_instrument_settings(vb.views.instrument_list.value, val, POPUP_INSTR_SAMPLE_HANDLER)
          end
        },    
      },
      
      vb:horizontal_aligner
      {
        margin = CONTENT_MARGIN,
        mode = "right",
        
        vb:text
        {
          text = "Default volume",            
        },
        vb:space
        {
          width = CONTENT_MARGIN + 30,
        },
        vb:valuebox
        {
          id = "valuebox_volume",
          width = 50,
          value = load_instrument_volume(vb.views.instrument_list.value, vb.views.sample_list.value),
          max = DEFAULT_VOLUME,
          min = 0,
          notifier = function(val)
          
            local ki = vb.views.instrument_list.value
            local ks = vb.views.sample_list.value
          
            set_instrument_volume(ki, ks, val)
          
          end
        }              
      },        
      
      vb:horizontal_aligner
      {
        margin = CONTENT_MARGIN,
        mode = "right",
        
        vb:text
        {
          text = "Sample rate interpolation",            
        },
        vb:space
        {
          width = CONTENT_MARGIN + 30,
        },
        vb:popup
        {
          id = "popup_sinc",
          width = 100,
          items = get_sinc_values(),
          value = load_instrument_sinc(vb.views.instrument_list.value, vb.views.sample_list.value),
          notifier = function(val)
          
            local ki = vb.views.instrument_list.value
            local ks = vb.views.sample_list.value
          
            set_instrument_sinc(ki, ks, val)
          
          end
        }              
      },
      
      vb:horizontal_aligner
      {        
        margin = CONTENT_MARGIN,
        mode = "right",        
        
        vb:text
        {
          text = "Adjust sample frequency (MOD)",            
        },
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:popup
        {          
          id = "popup_sample_frequency",
          width = 80,
          items = get_sample_frequency_settings(),     
          value = load_instrument_frequency(vb.views.instrument_list.value, vb.views.sample_list.value),
          notifier = function(val)
            -- NOTE to avoid space issues, first set all controls visibility to false
            
            local ki = vb.views.instrument_list.value
            local si = vb.views.sample_list.value
            
            if val == SAMPLE_FREQUENCY_ORIGINAL then
              vb.views.valuebox_frequency.active = false
              vb.views.valuebox_frequency.visible = false
              vb.views.popup_basenote.active = false
              vb.views.popup_basenote.visible = false
              vb.views.valuebox_frequency.active = false
              vb.views.valuebox_frequency.visible = true
              
              if not disable_set_instrument then
                set_instrument_frequency_alias(ki, si, val)
              end
              
              vb.views.valuebox_frequency.value = load_instrument_frequency_rate(ki, si)
            
            elseif val == SAMPLE_FREQUENCY_CUSTOM then
              vb.views.valuebox_frequency.active = false
              vb.views.valuebox_frequency.visible = false
              vb.views.popup_basenote.active = false
              vb.views.popup_basenote.visible = false
              vb.views.valuebox_frequency.active = true
              vb.views.valuebox_frequency.visible = true
              
              if not disable_set_instrument then
                set_instrument_frequency(ki, si, vb.views.valuebox_frequency.value)
              end
              
            elseif val == SAMPLE_FREQUENCY_BASENOTE then
              vb.views.valuebox_frequency.visible = false
              vb.views.valuebox_frequency.active = false
              vb.views.popup_basenote.active = false
              vb.views.popup_basenote.visible = false
              vb.views.popup_basenote.active = true
              vb.views.popup_basenote.visible = true
              
              if not disable_set_instrument then
                set_instrument_basenote(ki, si, vb.views.popup_basenote.value)
              end
              
            else -- LOW, HIGH, MAXIMUM
              vb.views.valuebox_frequency.visible = false
              vb.views.popup_basenote.visible = true
              vb.views.popup_basenote.active = false
              vb.views.valuebox_frequency.active = false              
              
              if not disable_set_instrument then
                set_instrument_frequency_alias(ki, si, val)
              end
              
              local old_disable_set_instrument = disable_set_instrument
              
              disable_set_instrument = true
              vb.views.popup_basenote.value = load_instrument_basenote(ki, si)    
              disable_set_instrument = old_disable_set_instrument
              
            end
            
          end
        },          
        vb:space
        {
          width = CONTENT_MARGIN,
        },
        vb:horizontal_aligner {
          mode = "right",
          width = 80,          
          vb:valuebox
          {
            id = "valuebox_frequency",
            active = vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_CUSTOM,    
            visible = vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_CUSTOM or 
                      vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_ORIGINAL,                     
            value = load_instrument_frequency_rate(vb.views.instrument_list.value, vb.views.sample_list.value),
            max = MAX_SAMPLE_RATE,
            min = MIN_SAMPLE_RATE,
            notifier = function(val)
            
              local ki = vb.views.instrument_list.value
              local ks = vb.views.sample_list.value
                        
              --if vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_CUSTOM then
                -- set_instrument_frequency(ki, ks, val)
              --end
            
              if not disable_set_instrument then
                set_instrument_frequency(ki, ks, val)
              end
            
            end
          },       
          vb:popup
          {
            id = "popup_basenote",
            visible = vb.views.popup_sample_frequency.value ~= SAMPLE_FREQUENCY_CUSTOM and 
                      vb.views.popup_sample_frequency.value ~= SAMPLE_FREQUENCY_ORIGINAL,                     
            items = get_base_note(),
            value = load_instrument_basenote(vb.views.instrument_list.value, vb.views.sample_list.value),
            active = vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_BASENOTE,         
            notifier = function(val)
            
              local ki = vb.views.instrument_list.value
              local ks = vb.views.sample_list.value
            
              --if vb.views.popup_sample_frequency.value == SAMPLE_FREQUENCY_BASENOTE then
                -- set_instrument_basenote(ki, ks, val)
              --end
              
              if not disable_set_instrument then
                set_instrument_basenote(ki, ks, val)
              end
              
            end
          }    
        },
        
                           
      },      
      
      vb:horizontal_aligner
      {        
        margin = CONTENT_MARGIN,
        mode = "distribute",  
        
        vb:button
        {
          text = "Reset to default",
          notifier = function()
            reset_instrument_values(vb.views.instrument_list.value, vb.views.sample_list.value)
            local volume = load_instrument_volume(vb.views.instrument_list.value, vb.views.sample_list.value)
            local freq = load_instrument_frequency(vb.views.instrument_list.value, vb.views.sample_list.value)
            local sinc = load_instrument_sinc(vb.views.instrument_list.value, vb.views.sample_list.value)
            vb.views.valuebox_volume.value = tonumber(volume)
            vb.views.popup_sample_frequency.value = freq
            vb.views.popup_sinc.value = sinc
          end
        }          
      }           
    },
    
    vb:horizontal_aligner
    {
      margin = CONTENT_MARGIN,
      mode = "distribute",    
      vb:button
        {
          text = "Reset all",
          notifier = function()
            reset_instrument_settings()
            local volume = load_instrument_volume(vb.views.instrument_list.value, vb.views.sample_list.value)
            local freq = load_instrument_frequency(vb.views.instrument_list.value, vb.views.sample_list.value)
            local sinc = load_instrument_sinc(vb.views.instrument_list.value, vb.views.sample_list.value)
            vb.views.valuebox_volume.value = tonumber(volume)
            vb.views.popup_sample_frequency.value = tonumber(freq)
            vb.views.popup_sinc.value = sinc
          end
        },      
    },
    
    vb:horizontal_aligner
    {
        margin = CONTENT_MARGIN,
        mode = "distribute",                   
        vb:button
        {
          text = "Load settings",
          notifier = function()
            load_ini_settings(true)
            local volume = load_instrument_volume(vb.views.instrument_list.value, vb.views.sample_list.value)
            local freq = load_instrument_frequency(vb.views.instrument_list.value, vb.views.sample_list.value)
            local sinc = load_instrument_sinc(vb.views.instrument_list.value, vb.views.sample_list.value)
            vb.views.valuebox_volume.value = tonumber(volume)
            vb.views.popup_sample_frequency.value = freq
            vb.views.popup_sinc.value = sinc            
          end
        },
        vb:button
        {
          text = "Open settings folder",
          notifier = function()
            open_settings_folder()
          end
        },
        vb:button
        {
          active = renoise.song().file_name ~= '',
          text = "Save settings",
          notifier = function()
            save_ini_settings()            
          end
        },                                            
     } 
    
  }
  
  instrument_settings_dialog = renoise.app():show_custom_dialog(
    "Xrns2XMod Instrument Settings", dialog_content
  ) 
  
end
