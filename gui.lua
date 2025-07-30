--------------------------------------------------------------------------------
-- Frontier AlphaTrack Support for Renoise
--
-- Copyright 2011 Martin Bealby
--
-- GUI support code
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
vb = renoise.ViewBuilder()
pref_dialog = nil
pref_dialog_content = nil


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
function pref_dialog_init()
  pref_dialog_content = vb:column {
    id = "main_container",
    vb:horizontal_aligner {
      mode = "justify",
      id = "row_autoconnect",
      vb:text {
        text = "Auto connect on startup:"
      },
      vb:checkbox {
        value = parameters.auto_connect.value,
        notifier = function(v)
          parameters.auto_connect.value = v
        end
      },
    },
    --[[vb:horizontal_aligner {
      mode = "justify",
      id = "row_autoselect",
      vb:text {
        text = "Auto select window:"
      },
      vb:checkbox {
        value = parameters.auto_select_window.value,
        notifier = function(v)
          parameters.auto_select_window.value = v
        end
      },
    },]]--
    --[[vb:horizontal_aligner {
      mode = "justify",
      id = "row_stickyshift",
      vb:text {
        text = "Sticky shift (n/a):"
      },
      vb:checkbox {
        value = parameters.sticky_shift.value,
        notifier = function(v)
          parameters.sticky_shift = v
        end
      },
    },
    ]]--
    vb:horizontal_aligner {
      id = "row_displayholdtime",
      mode = "justify",
      vb:text {
        text = "Display hold time (sec):"
      },
      vb:valuebox {
        min = 1,
        max = 5,
        value = parameters.display_hold_time.value,
        notifier = function(v)
          parameters.display_hold_time = v
        end
      },
    },
    vb:horizontal_aligner {
      id = "row_commands",
      mode = "justify",
      vb:button {
        text = "Save",
        released = function()
          save_parameters()
        end
      },
      vb:button {
        text = "Close",
        released = function()
          pref_dialog:close()
        end
      },
    }
  }
end
