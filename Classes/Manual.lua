--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 09/09/2011
  Last modified : 01/30/2012
  Version : 1.0

----------------------------------------------------------------------------]]--

--[[ Manual class ]]--------------------------------------------------------]]--

class "Manual"

  function Manual:__init()

    self.__dialog_title = "Mixer Show Automated Sliders Manual"
    self.__vb = nil
    self.__dialog = nil
    self.__dialog_content = nil

    self.__filename = "Resources/manual.txt"
    self.__headline = table.create()
    self.__pages = table.create()

    self:__install()

  end

  function Manual:__install()

    local rt = renoise.tool()
    local menu_path = "Main Menu:Help:Tools:"
    local menu_name = self.__dialog_title

    if not io.exists(self.__filename) then
      return
    end

    for line in io.lines(self.__filename) do
      if not line:find("@@(.-)@@") then
        if not self.__pages:is_empty() then
          self.__pages[#self.__pages].lines:insert(line)
        else
          self.__headline:insert(line)
        end
      else
         self.__pages:insert(table.create())
         self.__pages[#self.__pages] = {
           title = line:match("@@(.-)@@"),
           lines = table.create()
         }
         line = line:gsub("@@", "")
         self.__pages[#self.__pages].lines:insert(line)
      end
    end

    if self.__pages:is_empty() then

      if not rt:has_menu_entry(menu_path .. menu_name .. "...") then
        rt:add_menu_entry{
          name = "--" .. menu_path .. menu_name .. "...",
          invoke = function()
            self:read()
          end
        }
      end

    else

      for p, page in ipairs(self.__pages) do
        if not rt:has_menu_entry(
          menu_path .. menu_name .. ":" .. page.title .. "..."
        ) then
          rt:add_menu_entry{
            name = menu_path .. menu_name .. ":" .. page.title .. "...",
            invoke = function()
              self:read(p)
            end
          }
        end
      end

    end

  end

  function Manual:__create()

    local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

    self.__vb = renoise.ViewBuilder()

    local gui_navigation = self.__vb:column{
      id = "navigation",
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:horizontal_aligner{
        margin = CONTROL_MARGIN,
        mode = "justify",

        self.__vb:valuebox {
          id = "page_index",
          width = "10%",
          min = 0,
          max = 0,
          notifier = function(value)
            self.__vb.views.page_titles.value = value
            self:__load_page(value)
          end
        },
        self.__vb:popup {
          id = "page_titles",
          width = "90%",
          items = {},
          notifier = function(index)
            self.__vb.views.page_index.value = index
          end
        }
      }
    }

    local gui_page = self.__vb:column{
      margin = CONTROL_MARGIN,
      style = "group",

      self.__vb:horizontal_aligner {
        margin = CONTROL_MARGIN,

        self.__vb:multiline_text {
          id = "page_text",
          font = "mono",
          width = 506,
          height = 250
        }
      }
    }

    self.__dialog_content = self.__vb:column{
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,

      gui_navigation,
      gui_page
    }

    if self.__pages:is_empty() then
      self.__vb.views.navigation.visible = false
    else

      local page_titles = table.create()

      for _, page in ipairs(self.__pages) do
        page_titles:insert(page.title)
      end

      self.__vb.views.page_titles.items = page_titles
      self.__vb.views.page_index.min = 1
      self.__vb.views.page_index.max = #self.__pages
      self.__vb.views.page_index.value = 1

    end

  end

  function Manual:__close()

    local rt = renoise.tool()

    if rt.app_release_document_observable:has_notifier(
       Manual.__close, self
       ) then

      rt.app_release_document_observable:remove_notifier(
        Manual.__close, self
      )
    end

    if self.__dialog and self.__dialog.visible then
      self.__dialog:close()
    end

  end

  function Manual:__key_handler(dialog, key)

    if key.repeated then
      return
    end

    if key.modifiers == "" then

      if self.__vb.views.navigation.visible then

        local new_index

        if key.name == "left" then

          new_index = self.__vb.views.page_index.value - 1
          if new_index < self.__vb.views.page_index.min then
            new_index = self.__vb.views.page_index.max
          end
          self.__vb.views.page_index.value = new_index

        elseif key.name == "right" then

          new_index = self.__vb.views.page_index.value + 1
          if new_index > self.__vb.views.page_index.max then
            new_index = self.__vb.views.page_index.min
          end
          self.__vb.views.page_index.value = new_index

        end
      end

      if key.name == "home" then
        self.__vb.views.page_text:scroll_to_first_line()
      elseif key.name == "end" then
        self.__vb.views.page_text:scroll_to_last_line()
      elseif key.name == "esc" then
        self:__close()
      end

    end

  end

  function Manual:__show()

    local rt = renoise.tool()

    if not rt.app_release_document_observable:has_notifier(
       Manual.__close, self
       ) then

      rt.app_release_document_observable:add_notifier(
        Manual.__close, self
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

  function Manual:__load_page(page_index)

    self.__vb.views.page_text:clear()
    self.__vb.views.page_text.paragraphs = self.__headline

    if not self.__pages:is_empty() then
      self.__vb.views.page_index.value = page_index
      for _, line in ipairs(self.__pages[page_index].lines) do
        self.__vb.views.page_text:add_line(line)
      end
    end

  end

  function Manual:read(page_index)

    if not io.exists(self.__filename) then
      renoise.app():show_warning (
        "The " .. self.__dialog_title .. " could not be found, please " ..
        "reinstall this tool.\nMissing file: " .. self.__filename
      )
      return
    end

    page_index = page_index or 1
    self:__show()

    if not self.__pages:is_empty() then
      self.__vb.views.page_index.value = page_index
    else
      self:__load_page()
    end

  end

---------------------------------------------------------------------[[ EOF ]]--
