--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------
GUI = {}

GUI.dialog = nil
GUI.vb = {}
GUI.current_text = ""
GUI.col1_vol = "70"
GUI.col2_vol = "70"
GUI.lines_list = ""



function line_nums_to_table(lines_str)
  print("In line_nums_to_table")
  local nums_table = string.int_list_to_numeric(lines_str)
  local paired_table = {}

  for k,v in pairs(nums_table ) do
    paired_table[v] = v
  end

  return paired_table 
end


GUI.show_dialog = function()

  if GUI.dialog and GUI.dialog.visible then
    GUI.dialog:show()
    return
  else
    GUI.dialog = {}
  end

  GUI.vb = renoise.ViewBuilder()
  GUI.current_text = ""  

  local title = "Raw values. Very alpha"

  local function_row = GUI.vb:row {
        GUI.vb:text {
          text = "Function",
          tooltip = "Function to generate line numbers",
        },

        GUI.vb:textfield {
          text = "",
          id = "func_text",
          notifier = function()
            GUI.func_text = string.upper(GUI.vb.views.func_text.text)
            print("Updated GUI.func_text: " .. GUI.func_text)
          end,
        },
GUI.vb:button {
    text = "Generate",
    released = function()
      GUI.generate_values()
    end
  } 
      } -- end of row 



  local button_clear = GUI.vb:button {
    text = "Clear",
    released = function()
      GUI.vb.views.lines_list_field.text = ""
    end
  } 

  local button_go = GUI.vb:button {
    text = "Go",
    released = function()
      Core.set_swap_values(GUI)
      GUI.dialog:close()
    end
  }

-- ********************************** ROW 
  local content = GUI.vb:row {

    GUI.vb:column {
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,

      GUI.vb:row {
        GUI.vb:text {
          text = "Volume 1",
          tooltip = "Volume value for column 1",
        },
        GUI.vb:textfield {
          text = GUI.col1_vol,
          id = "col1_vol",
          notifier = function()
            GUI.col1_vol = string.upper(GUI.vb.views.col1_vol.text)
          end,
        },

      },

      -- ******************************** ROW 
      GUI.vb:row {

        GUI.vb:text {
          text = "Volume 2",
          tooltip = "Volume value for column 2",
        },
        GUI.vb:textfield {
          text = GUI.col2_vol,
          id = "col2_vol",
          notifier = function()
            GUI.col2_vol = string.upper(GUI.vb.views.col2_vol.text)
          end,
        },
      } ,
      
      function_row,

    },
    GUI.vb:column {
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,


      
      GUI.vb:text {
        text = "Swap on lines:",
        tooltip = "Series of line numbers",
      },

      GUI.vb:multiline_textfield {
        id = "lines_list_field",
        width = 400,
        height = 50,
        text = "",
        notifier = function()
          GUI.lines_list = GUI.vb.views.lines_list_field.text
        end
      },

      GUI.vb:horizontal_aligner {
        mode = "left",

        button_clear,
        button_go, 
      },
    },

  } -- end of main row


  GUI.dialog = renoise.app():show_custom_dialog(title, content)  

end


GUI.generate_values = function() 

  local current_set = line_nums_to_table(GUI.vb.views.lines_list_field.text)
  -- Need to turn this into a table, then generate new values, then merge the tables, sort, and remove dupes

  local function_str = string.trim(GUI.func_text)

  if U.is_empty_string(function_str) then
  print("Function string is empty, returning.")
    return 
  end

  -- Need to get the new list and populate the text box

  local new_set = Core.new_set_from_funct_string(function_str, current_set)
  print("New, generated, set: ")

  rprint(new_set)

  GUI.vb.views.lines_list_field.text = table.concat(new_set, " ")
  GUI.lines_list  = GUI.vb.views.lines_list_field.text
end

return GUI
