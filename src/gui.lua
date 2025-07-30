---@diagnostic disable: lowercase-global, undefined-global

COLUMN_SPACING = 2
COLUMN_MARGIN = 2
TEXT_WIDTH = 90
BUTTON_WIDTH = 120
POPUP_WIDTH = 100
FIRST_RUN = true

function key_actions(dialog, key)
    return key
end


function prepare_for_start()
  if (dialog and dialog.visible) then
      dialog:show()
      return

  else

    dialog = renoise.app():show_custom_dialog("Harmoniks", make_gui, key_actions)
  
    if FIRST_RUN == false then
      return
    end

    for page=0, 225, 32 do
      for i=page+1, page + 32 do
        vbs["harmony"..page]:add_child(
          vb:column{
            width=12,
            vb:minislider{
              width=12,
              id = "Harmony" .. i,
              height=120,
              min=-1,
              max=1,
              value=HARMONIC_SERIES[i],
              notifier=function(value)
                vbs["Harmony" .. i].value = value
                HARMONIC_SERIES[i] = value
                if vbs["Harmony"..i].value > 0 or vbs["Harmony"..i].value < 0 then
                  vbs["Harmony_btn"..i].color = {0,math.abs(math.floor(255 * value)),0}
                else
                  vbs["Harmony_btn"..i].color = {0,0,0}
                end
                draw_sample()
              end
            },
            vb:button{
              id="Harmony_btn"..i,
              width=12,
              height=12,
              color={0, 0, 0},
              notifier = function(bool)
                vbs["Harmony_btn"..i].color = {0, 0, 0}
                vbs["Harmony"..i].value = 0
                draw_sample()
              end
            },
        })
      end
    end

    vbs.harmony0.visible=true
    vbs.harmony32.visible=false
    vbs.harmony64.visible=false
    vbs.harmony96.visible=false
    vbs.harmony128.visible=false
    vbs.harmony160.visible=false
    vbs.harmony192.visible=false
    vbs.harmony224.visible=false
  end
  FIRST_RUN = false
  Notifiers:add(rnt.app_idle_observable, app_idle)
end

function reset_harmonies()
  RENDER_ENABLED = false
  for i=1, 256 do
    HARMONIC_SERIES[i] = 0
    vb.views["Harmony"..i].value = 0
  end
  HARMONIC_SERIES[1] = 1
  vb.views["Harmony1"].value = 1
  RENDER_ENABLED = true
  draw_sample()
end

make_gui =
    vb:column{
      style="invisible",
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT,
      vb:column{
        style="group",
        spacing=4,
        margin=4,
        vb:horizontal_aligner{
          mode="left",
          spacing=4,
          vb:text{text="Buffer Len", width=50, align="left"},
          vb:popup{
            id="buffer_len",
            width=60,
            items=BUFFERS,
            value=1,
            notifier = function(len)
              draw_sample()
            end  
          },
          vb:text{text="Wave Type", width=50, align="left"},
          vb:popup{
            id="wave_selector",
            width=60,
            items={"Sine", "Saw", "Square", "Triangle"}, --"White noise"}, --"Actual wave"},
            value=1,
            notifier = function(w)
              draw_sample()
            end
          },
          vb:text{text="Wovel", width=50, align="center"},
          vb:popup{
            id="wovel_selector",
            width=60,
            items={"None", "A", "E", "I", "O", "U"}, --"White noise"}, --"Actual wave"},
            value=1,
            notifier = function(w)
              draw_sample()
            end
          },
          vb:button{
            text="Reset H.",
            width=82,
            notifier=function()
              reset_harmonies()
              draw_sample()
            end
          },
        },
      },
      --vb:space{height=5},
      vb:column{
        style="group",
        spacing=4,
        margin=4,
        vb:horizontal_aligner{
          mode="distribute",
          vb:switch{
            width=400,
            height=22,
            items={"1-32", "33-64", "65-96", "97-128", "129-160", "161-192", "193-224", "225-256"},
            value=HARMONY_OFFSET,
            notifier=function(page)
              vbs.harmony0.visible=false
              vbs.harmony32.visible=false
              vbs.harmony64.visible=false
              vbs.harmony96.visible=false
              vbs.harmony128.visible=false
              vbs.harmony160.visible=false
              vbs.harmony192.visible=false
              vbs.harmony224.visible=false
              vb.views["harmony"..(page-1)*32].visible = true
              vbs.from_harmonies.value = (page - 1) * 32 + 1
              vbs.to_harmonies.value = page * 32
            end
          },
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony0",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony32",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony64",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony96",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony128",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony160",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony192",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
        vb:horizontal_aligner{
          mode="distribute",
          id="harmony224",
          spacing=COLUMN_SPACING,
          margin = COLUMN_MARGIN,
        },
      },
      vb:column{
        style="group",
        spacing=COLUMN_SPACING,
        margin=4,
        vb:horizontal_aligner{
          mode="left",
          vb:text{text="Saturate", width=TEXT_WIDTH},
          vb:popup{
            id="saturate_selector",
            width=120,
            items={"None", "Tanh", "Overdrive", "Distort"},
            value = 1,
            notifier=function(value)
              draw_sample()
            end
          },
          vb:text{text="Amount", width=BUTTON_WIDTH, align="center"},
          vb:slider{
            width=BUTTON_WIDTH,
            id="saturation_amount",
            min=0.001,
            max=0.999,
            value=0.2,
            default=0.2,
            steps={0.001, 0.01},
            notifier=function(value)
              if vbs.saturate_selector.value > 1 then
                draw_sample()
              end
            end
          },
        },
      },
      vb:column{
        style="group",
        spacing=COLUMN_SPACING,
        margin=4,
        vb:horizontal_aligner{
          mode="left",
          vb:text{text="Select harmonies", width=TEXT_WIDTH},
          vb:valuebox{
            id="from_harmonies",
            width=60,
            --height=22,
            min=1,
            max=256,
            value=1,
          },
          vb:valuebox{
            id="to_harmonies",
            width=60,
            --height=22,
            min=1,
            max=256,
            value=8,
          },
          vb:slider{
            width=BUTTON_WIDTH,
            height = 18,
            id="morph_amount",
            min = 0.001,
            max = 0.5,
            value = 0.1,
            default=0.1,
          },
          vb:button{
            text="Morph",
            width=BUTTON_WIDTH,
            color={50, 50, 50},
            notifier=function()
              morph_harmonic_values()
            end
          },
        },
      },
      vb:column{
        style="group",
        spacing=COLUMN_SPACING,
        margin=4,
        vb:horizontal_aligner{
          mode="left",
          vb:text{text="Master Volume", width=TEXT_WIDTH},
          vb:slider{
            id="master_volume",
            width=360,
            min=0.0,
            max=1.0,
            value=0.2,
            default =0.2,
            notifier=function(value)
              draw_sample()
            end
          },
        },
      },
    }