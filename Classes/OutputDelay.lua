--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 10/10/2010
  Last modified : 10/13/2015

----------------------------------------------------------------------------]]--

local samplerates = {
  "22.050",
  "44.100",
  "48.000",
  "88.200",
  "96.000",
  "192.000"
}

local rd = renoise.Document

--[[ OutputDelay class ]]---------------------------------------------------]]--

class "OutputDelay"

  function OutputDelay:__init()

    self.__dialog_title = "Set Output Delay In Samples"
    self.__vb = nil
    self.__dialog = nil
    self.__dialog_content = nil
    self.__last_track = nil
    self.__ms = 0

    self.preferences = OutputDelayPreferences()
    self.help = table.create()

    self:__install()

  end

  function OutputDelay:__install()

    local rt = renoise.tool()
    local menu_path = "Mixer:Track:"
    local menu_name = self.__dialog_title

    if not rt:has_menu_entry(menu_path .. menu_name .. "...") then
      rt:add_menu_entry{
        name = "--" .. menu_path .. menu_name .. "...",
        invoke = function()
          self:show()
          self:__selected_track_changed()
        end,
        active = function()
          return self:__can_set()
        end
      }
    end

    if not rt:has_keybinding(menu_path .. menu_name) then
      rt:add_keybinding{
        name = menu_path .. menu_name,
        invoke = function(repeated)
          if not repeated then
            self:show()
            self:__selected_track_changed()
          end
        end
      }
    end

  end

  function OutputDelay:__create()

    local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

    self.__vb = renoise.ViewBuilder()

    local gui_delay_values = self.__vb:column{
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:horizontal_aligner{
        margin = CONTROL_MARGIN,
        mode = "justify",
        width = "100%",

        self.__vb:column{
          width = "50%",

          self.__vb:text{
            text = "Samplerate:"
          },
          self.__vb:space{
            height = CONTROL_MARGIN
          },
          self.__vb:popup{
            id = "samplerate",
            width = "100%",
            items = samplerates,
            value = self.preferences.samplerate.value,
            bind = self.preferences.samplerate,
            notifier = function(value)
              self:__refresh()
            end
          }
        },
        self.__vb:column{
          width = "50%",

          self.__vb:text{
            text = "Samples:"
          },
          self.__vb:space{
            height = CONTROL_MARGIN
          },
          self.__vb:valuebox{
            id = "samples",
            width = "100%",
            notifier = function(value)
              self:__refresh()
            end
          }
        }
      }
    }

    local gui_delay_status = self.__vb:column{
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:vertical_aligner{
        margin = CONTROL_MARGIN,
        width = "100%",

        self.__vb:text{
          id = "ms"
        }
      }
    }

    local gui_delay_buttons = self.__vb:horizontal_aligner{
      mode = "justify",

      self.__vb:button{
        width = BUTTON_HEIGHT,
        height = BUTTON_HEIGHT,
        text = "?",
        tooltip = "Help [F12]",
        notifier = function()
          self:__help()
        end
      },
      self.__vb:row{

        self.__vb:button{
          id = "set",
          width = BUTTON_HEIGHT * 4,
          height = BUTTON_HEIGHT,
          text = "Set",
          notifier = function()
            self:__set()
          end
        },
        self.__vb:button{
          width = BUTTON_HEIGHT * 4,
          height = BUTTON_HEIGHT,
          text = "Close",
          notifier = function()
            self:__close()
          end
        }
      }
    }

    self.__dialog_content = self.__vb:column{
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,

      gui_delay_values,
      gui_delay_status,
      gui_delay_buttons
    }

    self:__refresh()

  end

  function OutputDelay:__refresh(selected_track_changed)

    if self:__can_set() then

      local samplerate = samplerates[self.__vb.views.samplerate.value]
      local min = -100 / (1 / samplerate)
      local max = 100 / (1 / samplerate)

      self.__vb.views.samplerate.items = samplerates
      self.__vb.views.samplerate.value = self.preferences.samplerate.value
      self.__vb.views.samplerate.active = true

      self.__vb.views.samples.min = min
      self.__vb.views.samples.max = max

      if selected_track_changed then

        local rs = renoise.song()
        local delay = rs.selected_track.output_delay

        self.__vb.views.samples.value = delay / (1 / samplerate)

      end

      if self.__vb.views.samples.value < min then
        self.__vb.views.samples.value = min
      elseif self.__vb.views.samples.value > max then
        self.__vb.views.samples.value = max
      end

      self.__vb.views.samples.active = true
      self.__ms = self.__vb.views.samples.value * (1 / samplerate)
      self.__vb.views.ms.text = self.__ms .. " ms"
      self.__vb.views.set.active = true

    else

      self.__vb.views.samplerate.active = false
      self.__vb.views.samplerate.items = {""}
      self.__vb.views.samples.active = false
      self.__vb.views.samples.min = 0
      self.__vb.views.samples.max = 0
      self.__vb.views.samples.value = 0
      self.__vb.views.ms.text = "0 ms"
      self.__vb.views.set.active = false

    end

  end

  function OutputDelay:__selected_track_changed()

    local rs = renoise.song()

    if self.__last_track and
       rs.tracks[self.__last_track].output_delay_observable:has_notifier(
         OutputDelay.__output_delay_changed, self
       ) then

      rs.tracks[self.__last_track].output_delay_observable:remove_notifier(
        OutputDelay.__output_delay_changed, self
      )
      self.__last_track = nil
    end

    if self:__can_set() then

      self.__last_track = rs.selected_track_index

      if not rs.tracks[self.__last_track].output_delay_observable:has_notifier(
           OutputDelay.__output_delay_changed, self
         ) then

        rs.tracks[self.__last_track].output_delay_observable:add_notifier(
          OutputDelay.__output_delay_changed, self
        )
      end

      self:__refresh(true)

    else
      self:__refresh()
    end

  end

  function OutputDelay:__output_delay_changed()
    self:__refresh(true)
  end

  function OutputDelay:__can_set()

    local rs = renoise.song()

    if rs.selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      return true
    end

    return false

  end

  function OutputDelay:__help()
    self.help[1]:read(self.help[2])
  end

  function OutputDelay:__set()

    local rs = renoise.song()

    if self:__can_set() then
      rs.selected_track.output_delay = self.__ms
    end

  end

  function OutputDelay:__close()

    local rt = renoise.tool()
    local rs = renoise.song()

    if rt.app_release_document_observable:has_notifier(
       OutputDelay.__close, self
       ) then

      rt.app_release_document_observable:remove_notifier(
        OutputDelay.__close, self
      )
    end

    if self.__last_track and
       rs.tracks[self.__last_track].output_delay_observable:has_notifier(
         OutputDelay.__output_delay_changed, self
       ) then

      rs.tracks[self.__last_track].output_delay_observable:remove_notifier(
        OutputDelay.__output_delay_changed, self
      )
      self.__last_track = nil
    end

    if rs.selected_track_index_observable:has_notifier(
         OutputDelay.__selected_track_changed, self
       ) then

      rs.selected_track_index_observable:remove_notifier(
        OutputDelay.__selected_track_changed, self
      )
    end

    if self.__dialog and self.__dialog.visible then
      self.__dialog:close()
    end

  end

  function OutputDelay:__key_handler(dialog, key)

    if key.repeated then
      return
    end

    if key.modifiers == "" then

      if self:__can_set() then

        local samples_min = self.__vb.views.samples.min
        local samples_max = self.__vb.views.samples.max

        if key.name == "up" then
          if self.__vb.views.samples.value + 1 > samples_max then
            self.__vb.views.samples.value = samples_max
          else
            self.__vb.views.samples.value = self.__vb.views.samples.value + 1
          end
        elseif key.name == "down" then
          if self.__vb.views.samples.value - 1 < samples_min then
            self.__vb.views.samples.value = samples_min
          else
            self.__vb.views.samples.value = self.__vb.views.samples.value - 1
          end
        elseif key.name == "prior" then
          if self.__vb.views.samples.value + 10 > samples_max then
            self.__vb.views.samples.value = samples_max
          else
            self.__vb.views.samples.value = self.__vb.views.samples.value + 10
          end
        elseif key.name == "next" then
          if self.__vb.views.samples.value - 10 < samples_min then
            self.__vb.views.samples.value = samples_min
          else
            self.__vb.views.samples.value = self.__vb.views.samples.value - 10
          end
        elseif key.name == "home" then
          self.__vb.views.samples.value = samples_max
        elseif key.name == "end" then
          self.__vb.views.samples.value = samples_min
        elseif key.name == "numpad 0" then
          self.__vb.views.samples.value = 0
        elseif key.name == "return" then
          self:__set()
        end

      end

      if key.name == "f12" then
        self:__help()
      elseif key.name == "esc" then
        self:__close()
      end

    end

  end

  function OutputDelay:show()

    if not self:__can_set() then
      return
    end

    local rt = renoise.tool()
    local rs = renoise.song()

    if not rt.app_release_document_observable:has_notifier(
       OutputDelay.__close, self
       ) then

      rt.app_release_document_observable:add_notifier(
        OutputDelay.__close, self
      )
    end

    if not rs.selected_track_index_observable:has_notifier(
         OutputDelay.__selected_track_changed, self
       ) then

      rs.selected_track_index_observable:add_notifier(
        OutputDelay.__selected_track_changed, self
      )
    end

    if not self.__dialog or not self.__dialog.visible then

      self:__create()

      self.__dialog = renoise.app():show_custom_dialog(
        self.__dialog_title, self.__dialog_content,
        function(dialog, key)
          self:__key_handler(dialog, key)
        end
      )
    else
      self.__dialog:show()
    end

  end

--[[ OutputDelayPreferences class ]]----------------------------------------]]--

class "OutputDelayPreferences"(rd.DocumentNode)

  function OutputDelayPreferences:__init()

    rd.DocumentNode.__init(self)

    self:add_property("samplerate", 2)

  end

---------------------------------------------------------------------[[ EOF ]]--
