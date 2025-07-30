local width = 280
local control_help = [[
keys                +ctrl +shift  +both
space = arm - play  solo  stop    next
enter = arm   solo
backs = arm   stop
+alt  = swap  =========================
tab   = same as space for current row

              +ctrl +shift +both
up    = move  next  ----   all next
down  = move  prev  ----   all prev
left  = move  ----  ----   ----
right = move  ----  ----   ----
+alt  = ----  swap  ----   swap


alt+n = add set as new pattern at end

alt+x = toggle on/off
]]

-- back  = arm  previous set
-- +alt = swap

local spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
local margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local cspacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
local cmargin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

local function cell_button(c, color)
  return {
    text = ifthen(c.empty, "", (c.alias - 1)..""),
    color = ifthen(c.empty, nil,color),
  }
end
local function next_button(c, color)
  if c.next ~= nil then
    return {
      text = ifthen(c.next.empty, " ", (c.next.alias - 1)..""),
      -- color = ifthen(c.next.empty, nil, color)
    }
  else
    return {
      text = "",
      color = nil
    }
  end
end

---@type fun(m:Model):renoise.Views.View --TODO narrow type
local function lanes_view(m)
  local s = renoise.song()
  local vb = renoise.ViewBuilder()
  if s == nil then return vb:space{} end
  local map_row = vb:row{
    spacing = 0,
    uniform = true,
    margin = 0,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
  }
  local next_row = vb:row{
    spacing = 0,
    uniform = true,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
  }
  for t = 1, #m.map do
    local c = m.map[t]
    local col = vb:column {
      uniform = true,
    }
    map_row:add_child(col)
    col:add_child(vb:button{
      visible = c.empty,
      color = s:track(t).color,
      height = ifthen(c.next and not c.next.empty, 18, 6),
    })
    col:add_child(vb:button(cell_button(c, s:track(t).color)))
    col:add_child(vb:button(next_button(c, s:track(t).color)))

  end
  return vb:column{
    map_row,
    next_row
  }
end

local function update_map_view(m)
  -- if view and view.map_container and view.map_view.visible then
  --   view.map_container:remove_child(view.map_view)
  --   view.map_view = lanes_view(m)
  --   view.map_container:add_child(view.map_view)
  -- end
end

local function toggle_row(vb, key, text)
  return vb:row{
    vb:checkbox{
      bind = prefs[key],
      value = prefs[key].value
    },
    vb:text{
      text = " " .. text
    }
  }
end

local function spacer(vb, x) return vb:row{height = cspacing * x} end
local function label(vb, t) return vb:text({text = t, align = "center"}) end

local function pref_switch(vb, key, items, text, tooltip, notif)
  return vb:row{
    tooltip = tooltip,
    vb:text {
      text = text
    },
    vb:switch{
      width = width - 1,
      bind = prefs[key],
      value = prefs[key].value,
      items = items,
      notifier = notif
    }
  }
end

local function row_key_text(vb, y)
  return vb:row{   
    vb:textfield{
      tooltip = "Keys for each track in row " .. y,
      value = prefs["cell_keys"..y].value,
      bind = prefs["cell_keys"..y]
    },
    vb:textfield{
      width = 20,
      tooltip = "Key for row " .. y,
      value = prefs["row_key"..y].value,
      bind = prefs["row_key"..y]
    }
  }
end


local function tab_keys(vb, v)
  return vb:column{
    width = "100%",
    visible = false,
    -- uniform = true,
    vb:column{
      width = "100%",
      style = "body",
      spacing = spacing,
      vb:column{
        margin = cmargin,
        vb:row{
          -- margin = cmargin,
          vb:text{
            text = "Track Keys & Rows"
          }
        },
        row_key_text(vb, 1),
        row_key_text(vb, 2),
        row_key_text(vb, 3),
        row_key_text(vb, 4),
      },
      vb:column{
        margin = cmargin,
        vb:text{
          text = "Play Mode: Once | Loop | Step"
        },
        vb:textfield{
          value = prefs.mode_keys.value,
          bind = prefs.mode_keys
        }
      },
      vb:row{
        margin = cmargin,
        vb:button{
          height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
          text = "Reset Defaults",
          pressed = reset_defaults
        }
      },
      vb:column{
        width = "100%",
        height = 200,
        margin = margin,
        vb:multiline_text{
          font = "mono",
          width = "100%",
          height = 200,
          text = control_help
        },
      },
    },
  }
end

local function tab_options(vb, v)
  return vb:row{
    width = "100%",
    visible = true,
    vb:column{
      spacing = cspacing,
      uniform = true,
      width = 45,
      label(vb, "After"),
      label(vb, "Wrap"),
      label(vb, "Highlight"),
    },
    vb:column{
      spacing = cspacing,
      width = "100%",
      uniform = true,
      pref_switch(vb, "post_step", {"Keep", "Right", "Last"}, "", "What to do with the cursor after launching a pattern?\n- Keep it where it was\n- Move it right\n- Move it in the left or right depending on where you moved last"),
      pref_switch(vb, "wrap", {"None", "Track", "Pattern", "Both"}, "", "Wrap around the pattern matrix while navigating, horizontally (Track), vertically (Pattern) or both"),
      pref_switch(vb, "highlight", {"None", "Slot Colors", "Selection"}, "", "What technique to use for highlighting the currently playing and armed tracks\n- Slot Colors uses the slot colors in the pattern matrix, it looks good but messes up the undo stack with lots of color changes\n- Selection uses the pattern selection, it makes selecting pattern slots impossible and can be rather hard to see depending on your theme (and eye-sight) but it leaves your undo stack alone"
      ),
    }
  }
end

local prefbox = function(vb,key, text)
  return vb:row{
    width = width,
    vb:checkbox{
      value = prefs[key].value,
      bind = prefs[key]
    },
    vb:text{
      text = text.."  ",
      align = "center"
    },
  }
end
local function tab_controls(vb, v)
  return vb:row{
    width = "100%",
    visible = true,
    vb:column{
      spacing = cspacing,
      uniform = true,
      width = 45,
      label(vb, "Length"),
      -- spacer(vb, 4),
      label(vb, "Mode"),
      label(vb, "On Gap"),
      label(vb, "Gaps"),
    },
    vb:column{
      spacing = cspacing,
      width = "100%",
      uniform = true,
      vb:row{
        tooltip = "Copy played pattern length automatically or lock it to a fixed value",
        -- spacing = spacing,
        width = "100%",
        vb:text{
          text = ""
        },
        v.length_switch,
        vb:row{
          vb:valuebox{
            width = width / 3,
            min = 1,
            tooltip = "Pattern Length",
            max = renoise.Pattern.MAX_NUMBER_OF_LINES,
            bind = prefs.length,
            value = prefs.length.value,
          }
        },
      },
      -- spacer(vb, 4),
      pref_switch(vb, "play_mode", {"Once", "Loop", "Step"}, "", "Mode for launching\n- Play the pattern once then stop\n- Keep looping the started tracks\n- Step downwards on the pattern sequence (set Gaps to customize)"),
      pref_switch(vb, "gap_mode", {"Ignore", "Jump", "Stop", "Wrap"}, "", "What to do when gaps are encountered in the song while stepping?\n- Continue through empty patterns\n- Jump over gaps to the next non-gap\n- Stop playing at the edge\n- Wrap around to start playing from the previous gap (this will loop \"pattern islands\")\nSet what are gaps below."),
      vb:row{
        tooltip = "Set what is interpreted as a gap.\nEmpty patterns, muted patterns, section boundaries or patterns with only automation",
        spacing = cspacing,
        margin = cmargin,
        vb:text{
          text = ""
        },
        prefbox(vb,"empty_is_gap", "Empty"),
        prefbox(vb,"muted_is_gap", "Muted"),
        prefbox(vb,"section_is_gap", "Section"),
        prefbox(vb,"automation_is_gap", "Automation"),
      },
      spacer(vb, 4),
    }
  }
end


-- ---@type fun(vb:ViewBuilderInstance, key:string, text:string, bitmap:DefaultIcons):renoise.Views.View
-- local bitmap_check = function(vb, key, text, bitmap)
--   local bm = vb:bitmap{
--       tooltip = text.."  ",
--       bitmap = bitmap,
--       mode = ifthen(prefs[key].value, "body_color", "button_color"),
--       height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
--       -- align = "center"
--     }
--   bm:add_notifier(function()
--       prefs[key].value = not prefs[key].value
--       bm.mode = ifthen(prefs[key].value, "body_color", "button_color")
--     end)
--   return vb:row{
--     width = width,
--     -- vb:checkbox{
--     --   value = prefs[key].value,
--     --   bind = prefs[key]
--     -- },
--     bm,
--   }
-- end

---@type fun(vb:ViewBuilderInstance, fn:function, items:string[][]):renoise.Views.View
local function bitmap_switch(vb, fn, items)
  local buttons = {}
  local r = vb:horizontal_aligner{
    width = width - renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.25,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.3,
    mode = "distribute"
  }
  for i, v in pairs(items) do
    local b = vb:bitmap{
      width = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
      height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
      bitmap = v[1],
      tooltip = v[2],
      -- color = {0,0,0},
      mode = ifthen(i == 4, "body_color", "button_color"),
      notifier = function()
        fn(i)
        -- prefs[key].value = i
        for j, bb in pairs(buttons) do
          bb.mode = ifthen(j == i, "body_color", "button_color")
        end
      end
    }
    table.insert(buttons, b)
    r:add_child(b)
  end
  return r
end

---@type fun(n : string):LLView
function create_view(n)
  local vb = renoise.ViewBuilder()
  ---@type LLView
  local v = {}


  -- v.map_view = lanes_view(model)
  -- v.map_container = vb:column{
  --   -- width = "100%",
  --   v.map_view
  -- }
  v.current_length = vb:text{
    -- width = "100%",
    width = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    -- items = "center",
    -- style = "disabled",
    text = prefs.length.value..""
  }

  v.enabled_check = vb:checkbox{
    -- width = width,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    -- width = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    width = 40,
    -- items = {"On", "Off"},
    -- width = 50,
    value = lanes_exist(n),
    tooltip = "Toggle Lanes",
    -- bitmap = "Icons/TrackIsOff.bmp",
    notifier = function(value)
      toggle_lanes(value, true)
    end
  }
  v.length_switch = vb:switch{
    width = (width / 3) * 2,
    value = prefs.length_mode.value,
    bind = prefs.length_mode,
    items = {"Auto", "Fixed"},
  }
  v.clock = vb:rotary{
    tooltip = "Clock",
    active = false,
    min = 0,
    max = 128,
    value = 64,
    width = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.5,
    -- notifier = on_clock_change
  }


  v.tabs = {
    -- vb:row({height = 1}),
    tab_keys(vb, v),
    tab_options(vb, v),
    tab_controls(vb, v),
  }

  local show_tab = function (value)
    for i = 1, #v.tabs do
      v.tabs[i].visible = i + 1 == value
    end
  end

  show_tab(4)

  v.main = vb:column{
    -- width = width + 100,
    spacing = spacing,
    margin = margin,
    -- v.map_container, 
    vb:row{
      -- width = 310,
      spacing = cspacing,
      vb:column{
        margin = cmargin,
        spacing = cspacing * 2.0,
      },
      vb:column{
        vb:row{
          spacing = spacing,
          -- vb:text{
          -- },
          v.enabled_check,
          bitmap_switch(vb, show_tab, {
            {"Icons/Minimize.bmp", "Minimize"},
            {"Icons/Transport_ComputerKeyboard.bmp", "Keymap"},
            {"Icons/MiddleFrame_Mix.bmp", "Settings"},
            {"Icons/Transport_EditStep.bmp", "Play Controls"}
          }),
          -- v.current_length,
          v.clock,
          -- vb:switch{
          --   width = width,
          --   height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT * 1.3,
          --   items = {"None",  "Keys", "Options", "Controls"},
          --   value = 4,
          --   notifier = show_tab
          -- }
        },
        -- spacer(vb, 5),

        -- vb:row{
        --   vb:text{
        --     text = ""
        --   },
        -- },
      }
    },
    v.tabs[1],
    v.tabs[2],
    v.tabs[3],
    v.tabs[4],
  }
  return v
end