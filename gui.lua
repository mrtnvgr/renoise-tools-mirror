require "util"
dialog = nil
margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
width = 60

function label(vb, text)
  return vb:text({
    text = "   " .. text
  })
end

function switch_row(vb, key, text, items)
  return vb:row({
    spacing = spacing,
    width = width,
    vb:column{
      width = width * 1.5,
      label(vb, text)
    },
    vb:column{
      vb:switch({
        value = prefs[key].value,
        width = width,
        bind = prefs[key],
        items = items,
      }),
    },
  })
end

function toggle_row(vb, key, text, tooltip, notif)
  return vb:row({
    spacing = spacing,
    width = width,
    tooltip = tooltip,
    vb:row{
      vb:column{
        width = width * 1.5,
        label(vb, text)
      },
      vb:column{
        vb:checkbox({
          value = prefs[key].value,
          bind = prefs[key],
          notifier = notif
        }),
      },
    }
  })
end

function integer_setting(vb, key, text, min, max, fn, tooltip)
  return vb:row({
      spacing = spacing,
      tooltip = tooltip,
      vb:column{
        width = width * 1.5,
        label(vb, text)
      },
      vb:column{
        vb:valuebox({
          width = width,
          min = min,
          max = max,
          bind = prefs[key],
          notifier = fn,
        }),
      },
    })
end

function button(vb, text, callback, tooltip)
  local w = with_default(width, 50)
  return vb:row({
    spacing = spacing,
    vb:row {
      margin = margin,
      vb:button({
        tooltip = tooltip,
        width = w,
        height = height,
        pressed = callback,
        text = text
      }),
    }
  })
end
function title(vb, text)
  return vb:text {

    text = text
  }
end


function color_row(vb, color, text, fn)
  return vb:row{
    spacing = spacing,
    vb:button {
      width = width * 2,
      text = text,
      pressed = function()
        local s = renoise.song()
        local c = s.selected_track.color
        prefs[color .. "_r"].value = c[1]
        prefs[color .. "_g"].value = c[2]
        prefs[color .. "_b"].value = c[3]
        fn()
      end
    },
    vb:button {
      width = width * 0.5,
      color = pref_color(prefs, color)
    },
  }
end

function text_row(vb, key, text, tooltip)
  return vb:row({
    spacing = spacing,
    tooltip = tooltip,
    vb:column{
      width = width * 1.5,
      label(vb, text)
    },
    vb:column{
      vb:textfield({
        width = width,
        value = prefs[key].value,
        bind = prefs[key],
        notifier = function()
          if prefs[key].value == "" then
            prefs[key].value = default_prefs()[key]
          end
        end,
      }),
    },
  })
end

function open_dialog(name, prefs)
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  local reopen = function()
    if dialog then
      dialog:close()
      dialog = nil
    end
    open_dialog(name, prefs)
  end
  local vb = renoise.ViewBuilder()
  local help_text = vb:multiline_text({
    width = 280,
    height = 400,
    font = "normal",
    -- font = text_font(),
    text = command_cheat,
  })
  local set_help_text = function()
    if prefs.help.value == 1 then 
      help_text.text = usage
    else
      help_text.text = command_cheat
    end
  end
  set_help_text()
  local help_view = vb:column({
    visible = true,
    margin = 20,
    width = 300,
    height = 400,
    style = "group",
    vb:row{
      width = 200,
      vb:switch{
        width = 200,
        items = {"Help", "Commands"},
        value = prefs.help.value,
        bind = prefs.help,
        notifier = set_help_text
      }
    },
    help_text,
  })
  local view = vb:column {
    margin = margin,
    spacing = spacing,
    text_row(vb, "prefix", "Track Prefix", "prefix to determine whether or not a track should be parsed as a chunk track"),
    vb:column {
      margin = margin / 2,
      style = "group",
      title(vb, "Render"),
      toggle_row(vb, "auto_render", "On Change", "automatically render chops when editing a chunk track", toggle_auto_render),
      integer_setting(vb, "auto_render_delay", "Watch Interval", 0, 100, nil, "delay auto rendering to allow for multiple edits between renders"),
      button(vb, "Render", function()render_pattern(1) end),
    },
    vb:column {
      margin = margin / 2,
      style = "group",
      title(vb, "Randomness"),
      toggle_row(vb, "keep_seed", "Lock Seed", "keep the seed from changing each render to preserve randomly generated chunks (see manual for more details)"),
      toggle_row(vb, "write_seed", "$eed to Track", "append the seed to the chunk track's name to preserve a unique seed for every song"),
      -- integer_setting(vb, "seed", "Seed", 0, 2^1023, function()render_pattern(0) end, "seed for random generation"),
    },
    vb:column {
      margin = margin / 2,
      style = "group",
      title(vb, "Pattern"),
      switch_row(vb, "hex_pattern", "Pattern Format", {"Dec", "Hex"}, "parse pattern indices as decimal or hexadecimal numbers"),
      switch_row(vb, "hex_line", "Line Format", {"Dec", "Hex"},"parse line indices as decimal or hexadecimal numbers"),
      toggle_row(vb, "automation", "Automation", "try chunking automation points as well (can lead to slow downs if you have a lot and results are not always desirable)"),
    },
    vb:column {
      spacing = spacing,
      style = "group",
      margin = margin / 2,
      title(vb, "Colors"),
      toggle_row(vb, "change_color", "Change", "manipulate the chunk track's color to indicate edited/rendered status"),
      color_row(vb, "dirty_color", "Assign Edited", reopen),
      color_row(vb, "idle_color", "Assign Rendered", reopen)
    },
    button(vb, "Reset Defaults", function()
      reset_defaults()
      reopen()
    end
    ),
    button(vb, "Open Manual", function()
      renoise.app():open_url("https://gitlab.com/unlessgames/unless_renoise/#chunk_chops")
    end
    ),
  }
  

  view = vb:row({
    width = 600 + margin * 2,
    height = 400 + margin * 6,
    view,
    help_view
  })

  dialog = renoise.app():show_custom_dialog(name, view)
end
