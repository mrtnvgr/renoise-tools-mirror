require("util")
require("step")

_AUTO_RELOAD_DEBUG = function() end

local name = "value_stepper"
local dialog = nil

---@class ValueStepperSettings : renoise.Document.DocumentNode
---@field size renoise.Document.ObservableNumber
---@field relative renoise.Document.ObservableBoolean
---@field start_relative_with_last renoise.Document.ObservableBoolean
---@field append_instrument_to_note renoise.Document.ObservableBoolean
---@field ignore_edit_mode renoise.Document.ObservableBoolean
---@field block_step_mode renoise.Document.ObservableNumber
---@field use_empty_on_vol_pan renoise.Document.ObservableBoolean
---@field select_instrument_on_step renoise.Document.ObservableBoolean
---@field step_fx_commands renoise.Document.ObservableBoolean
---@field fx_order renoise.Document.ObservableString
---@field fx_array renoise.Document.ObservableStringList
-- @field trigger_line_on_step renoise.Document.ObservableBoolean

---@type fun() : ValueStepperSettings
local function default_settings()
  return renoise.Document.create("ScriptingToolPreferences") {
    size = 1,
    relative = false,
    start_relative_with_last = true,
    append_instrument_to_note = true,
    ignore_edit_mode = true,
    block_step_mode = 1,
    use_empty_on_vol_pan = true,
    select_instrument_on_step = false,
    step_fx_commands = false,
    fx_order = "A,U,D,G,V,I,O,T,C,S,B,E,N,M,Z,Q,Y,R,L,P,W,X,J,ZT,ZL,ZK,ZG,ZB,ZD",
    fx_array = { "A" },
    trigger_line_on_step = false
  }
end


local function toggle_relative_mode(prefs)
  prefs.relative.value = not prefs.relative.value

  local s = "value stepper : relative mode "
  if prefs.relative.value then
    s = s .. "enabled"
  else
    s = s .. "disabled"
  end

  renoise.app():show_status(s)
end

---@type ValueStepperSettings
local settings = default_settings()

renoise.tool().preferences = settings

renoise.tool():add_keybinding({
  name = "Pattern Editor:Column Operations:Step value up",
  invoke = function(_)
    Step_values_in_selection(math.floor(settings.size.value), false, settings)
  end,
})
renoise.tool():add_keybinding({
  name = "Pattern Editor:Column Operations:Step value down",
  invoke = function(_)
    Step_values_in_selection(-1 * math.floor(settings.size.value), false, settings)
  end,
})

renoise.tool():add_keybinding({
  name = "Pattern Editor:Column Operations:Step value up (by 16)",
  invoke = function(_)
    Step_values_in_selection(16, true, settings)
  end,
})
renoise.tool():add_keybinding({
  name = "Pattern Editor:Column Operations:Step value down (by 16)",
  invoke = function(_)
    Step_values_in_selection(-16, true, settings)
  end,
})

renoise.tool():add_keybinding({
  name = "Phrase Editor:Column Operations:Step value up",
  invoke = function(_)
    Step_values_in_phrase_selection(math.floor(settings.size.value), false, settings)
  end,
})
renoise.tool():add_keybinding({
  name = "Phrase Editor:Column Operations:Step value down",
  invoke = function(_)
    Step_values_in_phrase_selection(-1 * math.floor(settings.size.value), false, settings)
  end,
})

renoise.tool():add_keybinding({
  name = "Phrase Editor:Column Operations:Step value up (by 16)",
  invoke = function(_)
    Step_values_in_phrase_selection(16, true, settings)
  end,
})
renoise.tool():add_keybinding({
  name = "Phrase Editor:Column Operations:Step value down (by 16)",
  invoke = function(_)
    Step_values_in_phrase_selection(-16, true, settings)
  end,
})

renoise.tool():add_keybinding({
  name = "Phrase Editor:Tools:Toggle relative mode (value stepper)",
  invoke = function()
    toggle_relative_mode(settings)
  end,
})

renoise.tool():add_keybinding({
  name = "Pattern Editor:Tools:Toggle relative mode (value stepper)",
  invoke = function()
    toggle_relative_mode(settings)
  end,
})

-- GUI

local function load_settings()
  local zero_pad = function(s)
    if #s == 1 then
      return "0" .. s
    else
      return s
    end
  end
  settings.fx_array = table:map(string:split(settings.fx_order.value, ","), zero_pad)
  -- rprint(settings.fx_array)
end

-- renoise.tool().app_new_document_observable:add_notifier(init_edit_listener)


local function toggle_row(vb, key, text)
  return vb:row({
    margin = 10,
    spacing = 10,
    vb:checkbox({
      bind = settings[key],
    }),
    vb:text({
      text = text,
    }),
  })
end

local function show_dialog()
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  local vb = renoise.ViewBuilder()

  local dialog_content = vb:column({
    vb:row({
      margin = 15,
      spacing = 15,

      vb:text({ text = "step size : " }),
      vb:valuebox({
        id = "Size",
        width = 60,
        bind = settings.size,
        min = 1,
        max = 16,
        tooltip = "size of steps",
        tostring = function(value)
          return ("%d"):format(value)
        end,
        tonumber = function(str)
          return tonumber(str, 0x10)
        end,
        -- notifier = function(_)
        --   -- save_settings()
        -- end,
      }),
    }),
    toggle_row(vb, "ignore_edit_mode", "ignore edit mode"),
    toggle_row(vb, "select_instrument_on_step", "select instrument with step"),
    toggle_row(vb, "use_empty_on_vol_pan", "auto-blank"),
    vb:row({
      margin = 15,
      spacing = 10,
      vb:text({
        text = "block stepping : ",
      }),
      vb:popup({
        width = 140,
        bind = settings.block_step_mode,
        items = {
          "step non-empty values",
          "step values with notes",
          "step all values",
        },
      }),
    }),
    toggle_row(vb, "relative", "relative mode"),
    toggle_row(vb, "start_relative_with_last", "repeat last"),
    toggle_row(vb, "trigger_line_on_step", "experimental: trigger line inside pattern (while not playing)"),

    -- toggle_row(vb, "step_fx_commands", "step through fx commands"),
    -- vb:row{
    --   margin = 15,
    --   spacing = 15,
    --   vb:text { text = " fx_order : " },
    --   vb:textfield {
    --     id = "fx_order",
    --     width = 200,
    --     bind = settings.fx_order,
    --     notifier = function(v)
    --       load_settings()
    --     end
    --   }
    -- }
  })

  dialog = renoise.app():show_custom_dialog(name, dialog_content)
end

renoise.tool():add_menu_entry({
  name = "Main Menu:Tools:" .. name,
  invoke = function()
    show_dialog()
  end,
})

load_settings()

print(name .. " loaded.")
