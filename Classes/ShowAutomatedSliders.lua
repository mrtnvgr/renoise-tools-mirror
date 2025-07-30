--[[----------------------------------------------------------------------------

  Author : Alexander Stoica
  Creation Date : 10/11/2010
  Last modified : 04/04/2016

----------------------------------------------------------------------------]]--

local ALL_TRACKS = 1
local CURRENT_TRACK = 2

--[[ ShowAutomatedSliders class ]]------------------------------------------]]--

class "ShowAutomatedSliders"

  function ShowAutomatedSliders:__init()

    self.__track = nil
    self:__install()

  end

  function ShowAutomatedSliders:__install()

    local rt = renoise.tool()
    local menu_path_at = "Mixer:Mixer:"
    local menu_path_ct = "Mixer:Track:"
    local menu_names = table.create({
      "Show Automated Sliders",
      "Show Modulated Sliders",
      "Show Automated And Modulated Sliders",
      "Show Midi Mapped Sliders",
      "Hide Sliders"
    })

    if not rt:has_menu_entry(menu_path_at .. menu_names[1]) then
      rt:add_menu_entry{
        name = "--" .. menu_path_at .. menu_names[1],
        invoke = function()
          self.__track = ALL_TRACKS
          self:__hide()
          self:__automated()
        end,
        active = function()
          self.__track = ALL_TRACKS
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_at .. menu_names[1]) then
      rt:add_keybinding{
        name = menu_path_at .. menu_names[1],
        invoke = function(repeated)
          if not repeated then
            self:__hide()
            self:__automated()
            self.__track = ALL_TRACKS
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_ct .. menu_names[1]) then
      rt:add_menu_entry{
        name = "--" .. menu_path_ct .. menu_names[1],
        invoke = function()
          self.__track = CURRENT_TRACK
          self:__hide()
          self:__automated()
        end,
        active = function()
          self.__track = CURRENT_TRACK
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_ct .. menu_names[1]) then
      rt:add_keybinding{
        name = menu_path_ct .. menu_names[1],
        invoke = function(repeated)
          if not repeated then
            self.__track = CURRENT_TRACK
            self:__hide()
            self:__automated()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_at .. menu_names[2]) then
      rt:add_menu_entry{
        name = menu_path_at .. menu_names[2],
        invoke = function()
          self.__track = ALL_TRACKS
          self:__hide()
          self:__modulated()
        end,
        active = function()
          self.__track = ALL_TRACKS
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_at .. menu_names[2]) then
      rt:add_keybinding{
        name = menu_path_at .. menu_names[2],
        invoke = function(repeated)
          if not repeated then
            self.__track = ALL_TRACKS
            self:__hide()
            self:__modulated()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_ct .. menu_names[2]) then
      rt:add_menu_entry{
        name = menu_path_ct .. menu_names[2],
        invoke = function()
          self.__track = CURRENT_TRACK
          self:__hide()
          self:__modulated()
        end,
        active = function()
          self.__track = CURRENT_TRACK
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_ct .. menu_names[2]) then
      rt:add_keybinding{
        name = menu_path_ct .. menu_names[2],
        invoke = function(repeated)
          if not repeated then
            self.__track = CURRENT_TRACK
            self:__hide()
            self:__modulated()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_at .. menu_names[3]) then
      rt:add_menu_entry{
        name = menu_path_at .. menu_names[3],
        invoke = function()
          self.__track = ALL_TRACKS
          self:__hide()
          self:__automated()
          self:__modulated()
        end,
        active = function()
          self.__track = ALL_TRACKS
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_at .. menu_names[3]) then
      rt:add_keybinding{
        name = menu_path_at .. menu_names[3],
        invoke = function(repeated)
          if not repeated then
            self.__track = ALL_TRACKS
            self:__hide()
            self:__automated()
            self:__modulated()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_ct .. menu_names[3]) then
      rt:add_menu_entry{
        name = menu_path_ct .. menu_names[3],
        invoke = function()
          self.__track = CURRENT_TRACK
          self:__hide()
          self:__automated()
          self:__modulated()
        end,
        active = function()
          self.__track = CURRENT_TRACK
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_ct .. menu_names[3]) then
      rt:add_keybinding{
        name = menu_path_ct .. menu_names[3],
        invoke = function(repeated)
          if not repeated then
            self.__track = CURRENT_TRACK
            self:__hide()
            self:__automated()
            self:__modulated()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_at .. menu_names[4]) then
      rt:add_menu_entry{
        name = menu_path_at .. menu_names[4],
        invoke = function()
          self.__track = ALL_TRACKS
          self:__hide()
          self:__midi_mapped()
        end,
        active = function()
          self.__track = ALL_TRACKS
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_at .. menu_names[4]) then
      rt:add_keybinding{
        name = menu_path_at .. menu_names[4],
        invoke = function(repeated)
          if not repeated then
            self.__track = ALL_TRACKS
            self:__hide()
            self:__midi_mapped()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_ct .. menu_names[4]) then
      rt:add_menu_entry{
        name = menu_path_ct .. menu_names[4],
        invoke = function()
          self.__track = CURRENT_TRACK
          self:__hide()
          self:__midi_mapped()
        end,
        active = function()
          self.__track = CURRENT_TRACK
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_ct .. menu_names[4]) then
      rt:add_keybinding{
        name = menu_path_ct .. menu_names[4],
        invoke = function(repeated)
          if not repeated then
            self.__track = CURRENT_TRACK
            self:__hide()
            self:__midi_mapped()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_at .. menu_names[5]) then
      rt:add_menu_entry{
        name = menu_path_at .. menu_names[5],
        invoke = function()
          self.__track = ALL_TRACKS
          self:__hide()
        end,
        active = function()
          self.__track = ALL_TRACKS
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_at .. menu_names[5]) then
      rt:add_keybinding{
        name = menu_path_at .. menu_names[5],
        invoke = function(repeated)
          if not repeated then
            self.__track = ALL_TRACKS
            self:__hide()
          end
        end
      }
    end

    if not rt:has_menu_entry(menu_path_ct .. menu_names[5]) then
      rt:add_menu_entry{
        name = menu_path_ct .. menu_names[5],
        invoke = function()
          self.__track = CURRENT_TRACK
          self:__hide()
        end,
        active = function()
          self.__track = CURRENT_TRACK
          return self:__active()
        end
      }
    end

    if not rt:has_keybinding(menu_path_ct .. menu_names[5]) then
      rt:add_keybinding{
        name = menu_path_ct .. menu_names[5],
        invoke = function(repeated)
          if not repeated then
            self.__track = CURRENT_TRACK
            self:__hide()
          end
        end
      }
    end

  end

  function ShowAutomatedSliders:__active()

    local rs = renoise.song()

    if self.__track == ALL_TRACKS then

      for _, track in ipairs(rs.tracks) do
        if #track.devices > 1 then
          return true
        end
      end

    elseif self.__track == CURRENT_TRACK then

      if #rs.selected_track.devices > 1 then
        return true
      end

    end

    return false

  end

  function ShowAutomatedSliders:__hide()

    if not self:__active() then
      return
    end

    local rs = renoise.song()

    if self.__track == ALL_TRACKS then

      for _, track in ipairs(rs.tracks) do
        for _, device in ipairs(track.devices) do
          for _, parameter in ipairs(device.parameters) do
            parameter.show_in_mixer = false
          end
        end
      end

    elseif self.__track == CURRENT_TRACK then

      for _, device in ipairs(rs.selected_track.devices) do
        for _, parameter in ipairs(device.parameters) do
          parameter.show_in_mixer = false
        end
      end

    end

  end

  function ShowAutomatedSliders:__automated()

    if not self:__active() then
      return
    end

    local rs = renoise.song()

    if self.__track == ALL_TRACKS then

      for _, track in ipairs(rs.tracks) do
        for _, device in ipairs(track.devices) do
          for _, parameter in ipairs(device.parameters) do
            if not parameter.is_automated then
              parameter.show_in_mixer = false
            else
              parameter.show_in_mixer = true
            end
          end
        end
      end

    elseif self.__track == CURRENT_TRACK then

      for _, device in ipairs(rs.selected_track.devices) do
        for _, parameter in ipairs(device.parameters) do
          if not parameter.is_automated then
            parameter.show_in_mixer = false
          else
            parameter.show_in_mixer = true
          end
        end
      end

    end

  end

  function ShowAutomatedSliders:__modulated()

    if not self:__active() then
      return
    end

    local rs = renoise.song()
    local known_devices = table.create({
      "*Formula",
      "*Hydra",
      "*Key-Tracker",
      "*LFO",
      "*Meta Mixer",
      "*Signal Follower",
      "*Velocity Tracker",
      "*XY Pad"
    })

    for t, track in ipairs(rs.tracks) do
      for _, device in ipairs(track.devices) do
        if known_devices:find(device.name) then
          for p, parameter in ipairs(device.parameters) do

            if parameter.name:find("Parameter") and
               device.parameters[p - 1].name:find("Effect") and
               device.parameters[p - 2].name:find("Track") then

              if parameter.value > -1 then

                local track_index = device.parameters[p - 2].value + 1
                local device_index = device.parameters[p - 1].value + 1
                local parameter_index = parameter.value
                local d = nil

                if self.__track == ALL_TRACKS then

                  if track_index == 0 then
                    d = track.devices[device_index]
                    d.parameters[parameter_index].show_in_mixer = true
                  else
                    d = rs.tracks[track_index].devices[device_index]
                    d.parameters[parameter_index].show_in_mixer = true
                  end

                elseif self.__track == CURRENT_TRACK then

                  if track_index == 0 and t == rs.selected_track_index then
                    track_index = rs.selected_track_index
                  end

                  if track_index == renoise.song().selected_track_index then
                    d = rs.selected_track.devices[device_index]
                    d.parameters[parameter_index].show_in_mixer = true
                  end

                end

              end
            end
          end
        end
      end
    end

  end

  function ShowAutomatedSliders:__midi_mapped()

    if not self:__active() then
      return
    end

    local rs = renoise.song()

    if self.__track == ALL_TRACKS then

      for _, track in ipairs(rs.tracks) do
        for _, device in ipairs(track.devices) do
          for _, parameter in ipairs(device.parameters) do
            if not parameter.is_midi_mapped then
              parameter.show_in_mixer = false
            else
              parameter.show_in_mixer = true
            end
          end
        end
      end

    elseif self.__track == CURRENT_TRACK then

      for _, device in ipairs(rs.selected_track.devices) do
        for _, parameter in ipairs(device.parameters) do
          if not parameter.is_midi_mapped then
            parameter.show_in_mixer = false
          else
            parameter.show_in_mixer = true
          end
        end
      end

    end

  end

---------------------------------------------------------------------[[ EOF ]]--
