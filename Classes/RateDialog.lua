--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 04/10/2011
  Last modified : 04/05/2016

----------------------------------------------------------------------------]]--

TRACK = 0
SAMPLE = 1

--[[ RateDialog class ]]----------------------------------------------------]]--

class "RateDialog"

  function RateDialog:__init()

    self.__dialog_title = "Set Rate"
    self.__vb = nil
    self.__dialog = nil
    self.__dialog_content = nil
    self.__device_type = nil
    self.__parameter = nil
    self.help = table.create()

  end

  function RateDialog:__create()

    local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

    self.__vb = renoise.ViewBuilder()

    local gui_input_value = self.__vb:column{
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:horizontal_aligner{
        margin = CONTROL_MARGIN,
        mode = "justify",
        width = "100%",

        self.__vb:valuebox{
          id = "input",
          width = "80%",
          value = 0,
          tostring = function(value)
            if (tonumber(value) ~= nil) then
              return tostring(string.format("%.4f", tonumber(value)))
            end
            return tostring(value)
          end,
          tonumber = function(value)
            if (tonumber(value) ~= nil) then
              return tonumber(string.format("%.4f", tonumber(value)))
            end
            return tonumber(value)
          end,
          notifier = function(value)
            self:__refresh()
          end
        },
        self.__vb:text{
          id = "input_text",
          width = "20%"
        }
      }
    }

    local gui_output_status = self.__vb:column{
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:vertical_aligner{
        margin = CONTROL_MARGIN,
        width = "100%",

        self.__vb:text{
          id = "output"
        }
      }
    }

    local gui_buttons = self.__vb:horizontal_aligner{
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
      self.__vb:button{
        id = "set",
        width = BUTTON_HEIGHT * 3,
        height = BUTTON_HEIGHT,
        text = "Set",
        notifier = function()
          self:__set()
        end
      },
      self.__vb:button{
        width = BUTTON_HEIGHT * 3,
        height = BUTTON_HEIGHT,
        text = "Close",
        notifier = function()
          self:__close()
        end
      }
    }

    self.__dialog_content = self.__vb:column{
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,

      gui_input_value,
      gui_output_status,
      gui_buttons
    }

    self:__refresh()

  end

  function RateDialog:__refresh(parameter_value_changed)

    if self.__parameter then

      local input_value = self.__vb.views.input.value

      if self.__parameter.name ~= "Frequency" then

        self.__vb.views.input_text.text = "LPC"
        self.__vb.views.input.min = self:__convert(self.__parameter.value_max)
        self.__vb.views.input.max = self:__convert(self.__parameter.value_min)

        if input_value == 0 then
          input_value = self:__convert(self.__parameter.value)
        end

        if parameter_value_changed then
          input_value = self:__convert(self.__parameter.value)
        end

      else

        self.__vb.views.input_text.text = "Hz"
        self.__vb.views.input.min = self:__convert(
          60 / self.__parameter.value_min
        )
        self.__vb.views.input.max = self:__convert(
          60 / self.__parameter.value_max
        )

        if input_value == 0 then
          input_value = self:__convert(60 / self.__parameter.value)
        end

        if parameter_value_changed then
          input_value = self:__convert(60 / self.__parameter.value)
        end

      end

      if input_value < self.__vb.views.input.min then
        input_value = self.__vb.views.input.min
      elseif input_value > self.__vb.views.input.max then
        input_value = self.__vb.views.input.max
      end

      self.__vb.views.input.value = input_value
      self.__vb.views.input.active = true

      if self.__parameter.name ~= "Frequency" then

        self.__vb.views.output.text = string.format("%.4f", self:__convert(
          self.__vb.views.input.value
        )) .. " Hz"

      else

        self.__vb.views.output.text = string.format("%.4f", self:__convert(
          self.__vb.views.input.value
        )) .. " LPC"

      end

      self.__vb.views.set.active = true

    else

      self.__vb.views.input_text.text = ""
      self.__vb.views.input.min = 0
      self.__vb.views.input.max = 0
      self.__vb.views.input.value = 0
      self.__vb.views.input.active = false
      self.__vb.views.output.text = "disabled"
      self.__vb.views.set.active = false

    end

  end

  function RateDialog:__selected_track_device_changed()
    print("Track Device changed.")
    self.__device_type = TRACK
    self:__selected_device_changed()
  end

  function RateDialog:__selected_sample_device_changed()
    print("Sample Device changed.")
    self.__device_type = SAMPLE
    self:__selected_device_changed()
  end

  function RateDialog:__selected_sample_device_chain_changed()
    print("Sample Device Chain changed.")
    self.__device_type = SAMPLE
    self:__selected_device_changed()
  end

  function RateDialog:__clear_selected()
    self.__device_type = nil
    self:__selected_device_changed()
  end

  function RateDialog:__selected_device_changed()

    local rt = renoise.tool()
    local rs = renoise.song()
    local menu_device = "--- DSP Device:" .. self.__dialog_title .. "..."
    local menu_mixer = "--- Mixer:" .. self.__dialog_title .. "..."
    local menu_sample_mixer = "--- Sample FX Mixer:" .. self.__dialog_title .. "..."
    local selected_device = nil
    
    if rt:has_menu_entry(menu_device) then
      rt:remove_menu_entry(menu_device)
    end

    if rt:has_menu_entry(menu_mixer) then
      rt:remove_menu_entry(menu_mixer)
    end

    if rt:has_menu_entry(menu_sample_mixer) then
      rt:remove_menu_entry(menu_sample_mixer)
    end

    if self.__parameter and
       self.__parameter.value_observable:has_notifier(
       RateDialog.__parameter_value_changed, self
      ) then

      self.__parameter.value_observable:remove_notifier(
        RateDialog.__parameter_value_changed, self
      )
    end

    self.__parameter = nil

    if self.__device_type == TRACK then
      if rs.selected_track_device_index > 1 then
        selected_device = rs.selected_track_device
      end
    elseif self.__device_type == SAMPLE then
      if rs.selected_sample_device_index > 1 then
        selected_device = rs.selected_sample_device
      end
    else
      selected_device = nil
    end

    if selected_device then

      if selected_device.name == "Chorus" or
         selected_device.name == "Flanger" or
         selected_device.name == "Phaser" or
         selected_device.name == "*LFO" then

        if not rt:has_menu_entry(menu_device) then
          rt:add_menu_entry{
            name = menu_device,
            invoke = function()
              self:__show()
            end
          }
        end

        if self.__device_type == TRACK then
          if not rt:has_menu_entry(menu_mixer) then
            rt:add_menu_entry{
              name = menu_mixer,
              invoke = function()
                self:__show()
              end
            }
          end
        elseif self.__device_type == SAMPLE then
          if not rt:has_menu_entry(menu_sample_mixer) then
            rt:add_menu_entry{
              name = menu_sample_mixer,
              invoke = function()
                self:__show()
              end
            }
          end
        end

        if selected_device.name == "Chorus" or
           selected_device.name == "Flanger" or
           selected_device.name == "Phaser" then
          for _, parameter in ipairs(selected_device.parameters) do
            if parameter.name == "Rate" then
              self.__parameter = parameter
            end
          end
        elseif selected_device.name == "*LFO" then
          for _, parameter in ipairs(selected_device.parameters) do
            if parameter.name == "Frequency" then
              self.__parameter = parameter
            end
          end
        end

        if not self.__parameter.value_observable:has_notifier(
           RateDialog.__parameter_value_changed, self
          ) then

          self.__parameter.value_observable:add_notifier(
            RateDialog.__parameter_value_changed, self
          )
        end

      end
    end

    self:__parameter_value_changed()

  end

  function RateDialog:__parameter_value_changed()
    if self.__dialog and self.__dialog.visible then
      self:__refresh(true)
    end
  end

  function RateDialog:__help()
    self.help[1]:read(self.help[2])
  end

  function RateDialog:__set()
    if self.__parameter then
      if self.__parameter.name ~= "Frequency" then
        self.__parameter.value = self:__convert(self.__vb.views.input.value)
      else
        self.__parameter.value = 60 / self:__convert(
          self.__vb.views.input.value
        )
      end
    end
  end

  function RateDialog:__close()
    if self.__dialog and self.__dialog.visible then
      self.__dialog:close()
    end
  end

  function RateDialog:__key_handler(dialog, key)

    if key.repeated then
      return
    end

    if key.modifiers == "" then

      if self.__vb.views.set.active then

        local rs = renoise.song()
        local input_min = self.__vb.views.input.min
        local input_max = self.__vb.views.input.max
        local small_step = 1
        local big_step = rs.transport.lpb

        if self.__parameter.name == "Frequency" then
          small_step = small_step / (rs.transport.lpb * 2)
          big_step = big_step / rs.transport.lpb
        end

        if key.name == "up" then
          if self.__vb.views.input.value + small_step > input_max then
            self.__vb.views.input.value = input_max
          else
            self.__vb.views.input.value = self.__vb.views.input.value
              + small_step
          end
        elseif key.name == "down" then
          if self.__vb.views.input.value - small_step < input_min then
            self.__vb.views.input.value = input_min
          else
            self.__vb.views.input.value = self.__vb.views.input.value
              - small_step
          end
        elseif key.name == "prior" then
          if self.__vb.views.input.value + big_step > input_max then
            self.__vb.views.input.value = input_max
          else
            self.__vb.views.input.value = self.__vb.views.input.value + big_step
          end
        elseif key.name == "next" then
          if self.__vb.views.input.value - big_step < input_min then
            self.__vb.views.input.value = input_min
          else
            self.__vb.views.input.value = self.__vb.views.input.value - big_step
          end
        elseif key.name == "home" then
          self.__vb.views.input.value = input_max
        elseif key.name == "end" then
          self.__vb.views.input.value = input_min
        elseif key.name == "numpad 0" then
          local pattern_value = rs.selected_pattern.number_of_lines
          if self.__parameter.name == "Frequency" then
            pattern_value = self:__convert(pattern_value)
          end
          if pattern_value < input_min then
            pattern_value = input_min
          elseif pattern_value > input_max then
            pattern_value = input_max
          end
          self.__vb.views.input.value = pattern_value
        elseif key.name == "f12" then
          self:__help()
        elseif key.name == "return" then
          self:__set()
        end

      end

      if key.name == "esc" then
        self:__close()
      end

    end

  end

  function RateDialog:__show()

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

  function RateDialog:__convert(value)
    local rs = renoise.song()
    return 1 / value * rs.transport.lpb * (rs.transport.bpm / 60)
  end

  function RateDialog:install()

    local rs = renoise.song()

    if not rs.selected_track_device_observable:has_notifier(
       RateDialog.__selected_track_device_changed, self
      ) then

      rs.selected_track_device_observable:add_notifier(
        RateDialog.__selected_track_device_changed, self
      )
    end

    if not rs.selected_sample_device_observable:has_notifier(
       RateDialog.__selected_sample_device_changed, self
      ) then

      rs.selected_sample_device_observable:add_notifier(
        RateDialog.__selected_sample_device_changed, self
      )
    end

    if not rs.selected_track_observable:has_notifier(
       RateDialog.__clear_selected, self
      ) then

      rs.selected_track_observable:add_notifier(
        RateDialog.__clear_selected, self
      )
    end

    if not rs.selected_track_index_observable:has_notifier(
       RateDialog.__clear_selected, self
      ) then

      rs.selected_track_index_observable:add_notifier(
        RateDialog.__clear_selected, self
      )
    end

    if not rs.selected_sample_device_chain_observable:has_notifier(
       RateDialog.__selected_sample_device_chain_changed, self
      ) then

      rs.selected_sample_device_chain_observable:add_notifier(
        RateDialog.__selected_sample_device_chain_changed, self
      )
    end

    if not rs.transport.bpm_observable:has_notifier(
       RateDialog.__parameter_value_changed, self
      ) then

      rs.transport.bpm_observable:add_notifier(
        RateDialog.__parameter_value_changed, self
      )
    end

    if not rs.transport.lpb_observable:has_notifier(
       RateDialog.__parameter_value_changed, self
      ) then

      rs.transport.lpb_observable:add_notifier(
        RateDialog.__parameter_value_changed, self
      )
    end

    self.__device_type = nil
    self.__parameter = nil
    self:__clear_selected()

  end

  function RateDialog:uninstall()

    local rs = renoise.song()

    if rs.selected_track_device_observable:has_notifier(
       RateDialog.__selected_track_device_changed, self
      ) then

      rs.selected_track_device_observable:remove_notifier(
        RateDialog.__selected_track_device_changed, self
      )
    end

    if rs.selected_sample_device_observable:has_notifier(
       RateDialog.__selected_sample_device_changed, self
      ) then

      rs.selected_sample_device_observable:remove_notifier(
        RateDialog.__selected_sample_device_changed, self
      )
    end

    if rs.selected_track_observable:has_notifier(
       RateDialog.__clear_selected, self
      ) then

      rs.selected_track_observable:remove_notifier(
        RateDialog.__clear_selected, self
      )
    end

    if rs.selected_track_index_observable:has_notifier(
       RateDialog.__clear_selected, self
      ) then

      rs.selected_track_index_observable:remove_notifier(
        RateDialog.__clear_selected, self
      )
    end

    if rs.selected_sample_device_chain_observable:has_notifier(
       RateDialog.__selected_sample_device_chain_changed, self
      ) then

      rs.selected_sample_device_chain_observable:remove_notifier(
        RateDialog.__selected_sample_device_chain_changed, self
      )
    end

    if rs.transport.bpm_observable:has_notifier(
       RateDialog.__parameter_value_changed, self
      ) then

      rs.transport.bpm_observable:remove_notifier(
        RateDialog.__parameter_value_changed, self
      )
    end

    if rs.transport.lpb_observable:has_notifier(
       RateDialog.__parameter_value_changed, self
      ) then

      rs.transport.lpb_observable:remove_notifier(
        RateDialog.__parameter_value_changed, self
      )
    end

    self:__close()

  end

---------------------------------------------------------------------[[ EOF ]]--
