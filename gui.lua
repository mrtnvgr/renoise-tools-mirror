--[[============================================================================
gui.lua
============================================================================]]--

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

vb = nil 
dialog = nil

local dec_to_hex = nil
local hex_to_dec = nil

local notifier_active = true

--notifiers
hex_to_dec = function()

  if not notifier_active then return end

  local hex_value = tonumber(vb.views.txtHex.text, 16)
	
  notifier_active = false
		
  if hex_value then
	vb.views.txtDec.text = (hex_value) and string.format("%d", hex_value) or "NaN"
  else
	renoise.app():show_warning('Invalid hexadecimal number!')
	vb.views.txtDec.text = ''
	vb.views.txtHex.text = ''
  end

  notifier_active = true
    
end

dec_to_hex = function()

  if not notifier_active then return end

  local dec_value = tonumber(vb.views.txtDec.text,10)
  
  notifier_active = false

  if dec_value then
	vb.views.txtHex.text = (dec_value) and string.format("%X", dec_value) or "NaN"
  else
	renoise.app():show_warning('Invalid decimal number!')
	vb.views.txtDec.text = ''
	vb.views.txtHex.text = ''
  end
  
  notifier_active = true

end

--end notifiers


function show_dialog()

  if (dialog and dialog.visible) then
    -- already showing a dialog. bring it to front:
    dialog:show()
    return
  end

  local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local SPACING_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local TEXT_LABEL_WIDTH = 80
  local CONTROL_WIDTH = 100
  local CONTENT_WIDTH = TEXT_LABEL_WIDTH + CONTROL_WIDTH

  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

  vb = renoise.ViewBuilder()

  -- create_global_properties

  local row_Txt = vb:row {
    vb:textfield {
	  id = "txtHex",
      width = TEXT_LABEL_WIDTH,
      notifier = hex_to_dec
    },
	vb:text {
	  id="lblHex",
	  text="< Hex - Dec >"
	},
    vb:textfield {
      id = "txtDec",
      width = TEXT_LABEL_WIDTH,
      notifier = dec_to_hex
    }
  }  
  
  local dialog_content = vb:column {
    id = "colContainer",
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
    row_Txt
  }
    
  dialog = renoise.app():show_custom_dialog (
    "Hex-Dec Converter",
    dialog_content
  )

end

