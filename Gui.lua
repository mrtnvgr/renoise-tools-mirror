--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------
GUI = {}

GUI.dialog = nil
GUI.vb = {}
GUI.guid = nil
GUI.current_text = ""

GUI.show_dialog = function()
  
  if GUI.dialog and GUI.dialog.visible then
    GUI.dialog:show()
    return
  else
    GUI.dialog = {}
  end
  
  GUI.vb = renoise.ViewBuilder()
  GUI.guid = TPC.find_nearest_commnent_guid()
  GUI.current_text = ""  

  local title = "New Comment"

  if (GUI.guid ~= nil ) then
    title = "Comments for TP Comments " .. GUI.guid  .. " (" .. GUI.guid  .. ")"
  end

  local content = GUI.vb:column {
    margin = 3,
    GUI.vb:multiline_textfield {
      id = "text_field",
      width = 300,
      height = 200,
      text = TPC.get_comments(GUI.guid ),
      notifier = function()
        GUI.current_text = GUI.vb.views.text_field.text
      end
    }
  } 
  
  GUI.dialog = renoise.app():show_custom_dialog(title, content)  
  
end

renoise.tool().app_idle_observable:add_notifier(function()
  if GUI.dialog and not GUI.dialog.visible then
    TPC.update_comments(GUI.guid, GUI.current_text)
    -- Setting it to nil keeps this from endlessly fireing.
    GUI.dialog  = nil
  end
end)

return GUI
