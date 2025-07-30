--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 09/10/2011
  Last modified : 09/14/2011

----------------------------------------------------------------------------]]--

--[[ CopyAutomation class ]]------------------------------------------------]]--

class "CopyAutomation"

  function CopyAutomation:__init()

    self.__cache = table.create({
      envelopes = table.create(),
      pcommands = table.create()
    })

    self.__empty_column_index = nil

    self:__install()

  end

  function CopyAutomation:__install()

    local rt = renoise.tool()
    local rs = renoise.song()
    local menu_path = "Track Automation List:"
    local menu_copy_envelopes = "Copy All Envelopes in Song"
    local menu_paste_envelopes = "Paste All Envelopes in Song"
    local menu_copy_pcommands = "Copy All Pattern Commands in Song"
    local menu_paste_pcommands = "Paste All Pattern Commands in Song"
    local menu_convert_pcommands = menu_paste_pcommands .. " as Envelopes"
    local menu_copy_all = "Copy All Automation in Song"
    local menu_paste_all = "Paste All Automation in Song"

    if not rt:has_menu_entry(menu_path .. menu_copy_envelopes) then
      rt:add_menu_entry{
        name = "---" .. menu_path .. menu_copy_envelopes,
        invoke = function()
          self:__clear_cache()
          self:__copy_envelopes()
          if self.__cache.envelopes:is_empty() then
            renoise.app():show_status(
              "Nothing was copied! This paramater uses pattern " ..
              "command automation."
            )
          end
        end,
        active = function()
          return self:__copy_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_paste_envelopes) then
      rt:add_menu_entry{
        name = menu_path .. menu_paste_envelopes,
        invoke = function()
          self:__paste_envelopes()
        end,
        active = function()
          return self:__paste_envelopes_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_copy_pcommands) then
      rt:add_menu_entry{
        name = "---" .. menu_path .. menu_copy_pcommands,
        invoke = function()
          self:__clear_cache()
          self:__copy_pcommands()
          if self.__cache.pcommands:is_empty() then
            renoise.app():show_status(
              "Nothing was copied! This paramater uses envelope automation."
            )
          end
        end,
        active = function()
          return self:__copy_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_paste_pcommands) then
      rt:add_menu_entry{
        name = menu_path .. menu_paste_pcommands,
        invoke = function()
          self:__paste_pcommands()
        end,
        active = function()
          return self:__paste_pcommands_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_convert_pcommands) then
      rt:add_menu_entry{
        name = menu_path .. menu_convert_pcommands,
        invoke = function()
          self:__convert_pcommands()
          self:__paste_envelopes()
        end,
        active = function()
          return self:__convert_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_copy_all) then
      rt:add_menu_entry{
        name = "---" .. menu_path .. menu_copy_all,
        invoke = function()
          self:__clear_cache()
          self:__copy_envelopes()
          self:__copy_pcommands()
        end,
        active = function()
          return self:__copy_active()
        end
      }
    end

    if not rt:has_menu_entry(menu_path .. menu_paste_all) then
      rt:add_menu_entry{
        name = menu_path .. menu_paste_all,
        invoke = function()
          self:__paste_envelopes()
          self:__paste_pcommands()
        end,
        active = function()
          return self:__paste_all_active()
        end
      }
    end

    if not rt.app_new_document_observable:has_notifier(
       self.__pattern_changed, self) then

      rt.app_new_document_observable:add_notifier(
        self.__pattern_changed, self
      )
    end

    if not rs.patterns_observable:has_notifier(
       self.__pattern_changed, self) then

      rs.patterns_observable:add_notifier(
        self.__pattern_changed, self
      )
    end

    if not rs.selected_track_index_observable:has_notifier(
       self.__track_changed, self) then

      rs.selected_track_index_observable:add_notifier(
        self.__track_changed, self
      )
    end

  end

  function CopyAutomation:__copy_active()

    local rs = renoise.song()

    if rs.selected_parameter ~= nil then
      if rs.selected_parameter.is_automatable and
         rs.selected_parameter.is_automated then

        return true
      end
    end

    return false

  end

  function CopyAutomation:__paste_envelopes_active()

    local rs = renoise.song()

    if rs.selected_parameter ~= nil then
      if rs.selected_parameter.is_automatable and
         not self.__cache.envelopes:is_empty() then

        return true
      end
    end

    return false

  end

  function CopyAutomation:__paste_pcommands_active()

    local rs = renoise.song()

    if rs.selected_parameter ~= nil then
      if rs.selected_parameter.is_automatable and
         not self.__cache.pcommands:is_empty() then

        if self:__parameter_to_pcommand() == nil then

          renoise.app():show_status(
            "Pasting not possible, target parameter is out of bounds! " ..
            "Convert the pattern command automation to an envelope for " ..
            "this parameter."
          )

          return false
        end

        if self:__find_empty_effect_column() == nil then

          renoise.app():show_status(
            "Pasting not possible, all effect columns are in use! " ..
            "Either free a column or convert the pattern command " ..
            "automation to an envelope for this parameter."
          )

          return false
        end

        return true
      end
    end

    return false

  end

  function CopyAutomation:__convert_active()

    if not self.__cache.pcommands:is_empty() then
      return true
    end

    return false

  end

  function CopyAutomation:__paste_all_active()

    if self:__paste_envelopes_active() and
       self:__paste_pcommands_active() then

      return true
    end

    return false

  end

  function CopyAutomation:__copy_envelopes()

    local rs = renoise.song()

    if rs.selected_parameter == nil then
      return
    end

    for p, pattern in ipairs(rs.patterns) do

      local track = pattern:track(rs.selected_track_index)
      local automation = track:find_automation(rs.selected_parameter)

      if automation then
        self.__cache.envelopes:insert(p, table.create({
          playmode = automation.playmode,
          points = automation.points
        }))
      end

    end

  end

  function CopyAutomation:__paste_envelopes()

    local rs = renoise.song()

    if rs.selected_parameter == nil then
      return
    end

    for p, pattern in ipairs(rs.patterns) do

      local track = pattern:track(rs.selected_track_index)
      local automation = track:find_automation(rs.selected_parameter)

      if automation then
        track:delete_automation(rs.selected_parameter)
      end

      if self.__cache.envelopes[p] then

        automation = track:create_automation(rs.selected_parameter)
        automation.playmode = self.__cache.envelopes[p].playmode
        automation.points = self.__cache.envelopes[p].points

      end
    end

  end

  function CopyAutomation:__copy_pcommands()

    local rs = renoise.song()
    local cache = self.__cache.pcommands
    local parameter = self:__parameter_to_pcommand()
    local iterator = rs.pattern_iterator:effect_columns_in_track(
                       rs.selected_track_index, false
                     )

    for position, column in iterator do
      if column.number_string == parameter then

        if cache[position.pattern] == nil then
          cache[position.pattern] = table.create()
        end

        if cache[position.pattern][position.line] == nil then
          cache[position.pattern]:insert(
            position.line, column.amount_value
          )
        else
          cache[position.pattern][position.line] = column.amount_value
        end

      end
    end

  end

  function CopyAutomation:__paste_pcommands()

    if self.__empty_column_index == nil then
      return
    end

    local rs = renoise.song()
    local cache = self.__cache.pcommands
    local parameter = self:__parameter_to_pcommand()
    local iterator = rs.pattern_iterator:effect_columns_in_track(
                       rs.selected_track_index, false
                     )

    if rs.selected_track.visible_effect_columns < self.__empty_column_index then
      rs.selected_track.visible_effect_columns = self.__empty_column_index
    end

    for position, column in iterator do
      if position.column == self.__empty_column_index then
        if cache[position.pattern] ~= nil then
          if cache[position.pattern][position.line] ~= nil then

            column.number_string = parameter
            column.amount_value = cache[position.pattern][position.line]

          end
        end
      end
    end

  end

  function CopyAutomation:__convert_pcommands()

    self.__cache.envelopes:clear()

    for pattern, lines in pairs(self.__cache.pcommands) do

      local envelope = table.create({
        playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS,
        points = table.create()
      })

      for line, value in pairs(lines) do
        envelope.points:insert(table.create({
          time = line,
          value = value / 255
        }))
      end

      self.__cache.envelopes:insert(pattern, envelope)

    end

  end

  function CopyAutomation:__parameter_to_pcommand()

    local rs = renoise.song()

    if rs.selected_parameter == nil then
      return
    end

    for d, device in ipairs(rs.selected_track.devices) do
      for p, parameter in ipairs(device.parameters) do
        if rawequal(rs.selected_parameter, parameter) then

          if d > 16 or p > 16 then
            return nil
          end

          local result = table.create({
            device = d - 1,
            parameter = p - 1
          })

          if result.device == 0 then
            if result.parameter == 0 then
              result.parameter = 8
            elseif result.parameter == 1 then
              result.parameter = 12
            elseif result.parameter == 2 then
              result.parameter = 10
            end
          end

          return string.upper(
            bit.tohex(result.device, 1) .. bit.tohex(result.parameter, 1)
          )

        end
      end
    end

  end

  function CopyAutomation:__find_empty_effect_column()

    if self.__empty_column_index ~= nil then
      return self.__empty_column_index
    end

    local rs = renoise.song()
    local columns = table.create()
    local iterator = rs.pattern_iterator:effect_columns_in_track(
                       rs.selected_track_index, false
                     )

    renoise.app():show_status(
      "Scanning for empty effect column..."
    )

    for position, column in iterator do
      if columns[position.column] == nil then
        columns:insert(position.column, column.is_empty)
      elseif columns[position.column] == true then
        columns[position.column] = column.is_empty
      end
    end

    self.__empty_column_index = columns:find(true)

    renoise.app():show_status(
      "Scanning for empty effect column... done."
    )

    return self.__empty_column_index

  end

  function CopyAutomation:__pattern_changed()

    local rs = renoise.song()

    for _, pattern in ipairs(rs.patterns) do
      if not pattern:has_line_notifier(
         self.__track_changed, self) then

         pattern:add_line_notifier(
          self.__track_changed, self
        )
      end
    end

    self:__track_changed()
    self:__clear_cache()

  end

  function CopyAutomation:__track_changed()
    self.__empty_column_index = nil
  end

  function CopyAutomation:__clear_cache()

    self.__cache.envelopes:clear()
    self.__cache.pcommands:clear()

  end

---------------------------------------------------------------------[[ EOF ]]--
