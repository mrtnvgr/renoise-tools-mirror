
--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------

local BASS_REGISTRATION_URL = "http://www.bass.radio42.com/bass_register.html";

--------------------------------------------------------------------------------
-- gui
--------------------------------------------------------------------------------

function show_bass_dialog()

  local dialog_title = "Bass registration"
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN 
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local button_labels = {"Save", "Close"};
  
  -- bitmap
  local bitmap_logo = vb:button {
    -- recolor to match the GUI theme:
    --mode = "plain",
    width = 104,
    height = 50,
    bitmap = "images/logo_bass.bmp",
    notifier = function()
      renoise.app():open_url(BASS_REGISTRATION_URL);
    end
  }
  
  -- textfield_bass_email 
  local textfield_bass_email = vb:textfield {
    --id="bass_email",
    value = bass_email,    
    width=150,    
    notifier = function(value)
      bass_email = value
    end
  }
  
  --textfield_bass_code
  local textfield_bass_code = vb:textfield {
    --id="bass_code",
    value = bass_code,
    width=150,
    notifier = function(value)
      bass_code = value
    end    
  }
  
  --button save
  local button_save = vb:button {
    text="Save",
    height = DEFAULT_DIALOG_BUTTON_HEIGHT,
    
    notifier = function()
      
    end
    
  }
  
  --button close
  local button_close = vb:button {
    text="Close",
    height = DEFAULT_DIALOG_BUTTON_HEIGHT,
    
    notifier = function()
      --bass_dialog:close();
    end    
  }
  
  local dialog_content = vb:column {
    margin = DEFAULT_MARGIN,
    
    vb:horizontal_aligner
    {
      mode = "center",
      
      bitmap_logo
    },
    
    vb:space {height = (CONTENT_MARGIN)},       
    vb:space {height = (CONTENT_MARGIN)},             
    
    vb:horizontal_aligner
    {
      spacing=8,
      vb:text {
        text="Email"
      },
      textfield_bass_email
    },
    
    vb:horizontal_aligner
    {
      spacing=8,      
      vb:text {
        text="Code"
      },
      textfield_bass_code
    },
    
    vb:horizontal_aligner
    {
      mode="center",
      vb:text {
        text="Register to disable splash window";
      }
    }
  }
  
  local ret = renoise.app():show_custom_prompt(dialog_title, dialog_content, button_labels );  
  
  if (ret == "Save") then
    my_options.bass_email.value = bass_email
    my_options.bass_code.value = bass_code
  else
    bass_email = my_options.bass_email.value 
    bass_code = my_options.bass_code.value 
  end
  
end
