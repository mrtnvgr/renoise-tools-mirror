--[[============================================================================
com.duncanhemingway.ExportToUnreal.xrnx (main.lua)
============================================================================]]--

--------------------------------------------------------------------------------
-- global declarations
--------------------------------------------------------------------------------

ready = true
the_gui = nil
process = nil
require "process_slicer"

class "Preferences"(renoise.Document.DocumentNode)
  function Preferences:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("doc_directory", "")
  end

doc = Preferences() -- need to create a specific instance, otherwise every call will just create new instances
doc:load_from("preferences.xml")
vb = renoise.ViewBuilder() -- need to create a specific instance, otherwise every call will just create new instances

--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- get directory and filename

function get_dir_and_file()
  local dir, file = renoise.song().file_name:match'(.*\\)(.*)'
  if doc.doc_directory.value ~= "" then dir = doc.doc_directory.value end
  if file == nil then
    file = "Untitled"
  else
    file = file:sub(1, -6)
  end
  vb.views.export_filename.text = file
  if dir == nil then dir = "Please select a directory to save to..." end
  shorten_dir(dir, true)
end

-- shorten directory text

function shorten_dir(dir, loaded)
  local shortdir
  if #dir > 45 then
    shortdir = dir:sub(1, 3) .. "..." .. dir:sub(-40)
  else
    shortdir = dir
  end
  vb.views.export_path.text = shortdir
  vb.views.dir_tooltip.tooltip = dir
  if not loaded and dir ~= "Please select a directory to save to..." then
    doc.doc_directory.value = dir
    doc:save_as("preferences.xml")
  end
end

-- change directory and filename if song is changed

song_loaded = function() get_dir_and_file() end

-- show exporting progress

function export_progress(message)
  renoise.app():show_status("Export To Unreal: " .. message)
  vb.views.export_progress.text = message
  coroutine.yield()
end

-- main exporting code

function export_song_data(dir, file)
  local s = renoise.song()
  local f = io.open(dir .. file .. ".json","w")
  if f == nil then
    renoise.app():show_warning("Cannot export to this directory. The most likely cause is that it is protected and you do not have permission. Please select another directory.")
    return
  end
  local name = 0
  local no_of_lines = 0
  local no_of_tracks = s.sequencer_track_count + s.send_track_count + 1
  ready = false
  export_progress("Exporting Global Song Data...")
  local json = "[\n  {\n    \"Name\": \"" .. s.name .. "\",\n    \"BPM\": " .. s.transport.bpm .. ",\n    \"LPB\": " .. s.transport.lpb .. ",\n    \"Tracks\": ["

  for t = 1, no_of_tracks do
    json = json .. "\n      {\n"
    json = json .. "        \"Name\": \"" .. s:track(t).name .. "\",\n"
    json = json .. "        \"Type\": " .. s:track(t).type - 1 .. ",\n"
    json = json .. "        \"Colour\": \"(R=" .. s:track(t).color[1] / 255 .. ",G=" .. s:track(t).color[2] / 255 .. ",B=" .. s:track(t).color[3] / 255 .. ",A=1)\",\n"
    json = json .. "        \"Delay\": " .. s:track(t).output_delay .. ",\n"
    json = json .. "        \"Note Column Names\": ["
    if s:track(t).type > 1 then
      json = json .. " ] "
    else

      for c = 1, s:track(t).visible_note_columns do
        name = s:track(t):column_name(c)
        if name == "" then
          name = "Note"
        end
        json = json .. "\n          \"" .. name .. "\","
      end

      json = json:sub(1, -2)
      json = json .. "\n        ]"
    end
    json = json .. "\n      },"
  end

  json = json:sub(1, -2)
  json = json .. "\n    ],\n    \"Pattern Sequence\": ["

  for p = 1, #s.sequencer.pattern_sequence do
    json = json .. "\n      {\n"
    json = json .. "        \"Pattern\": " .. s.sequencer.pattern_sequence[p] - 1 .. ",\n"
    json = json .. "        \"Section Header\": \""
    if s.sequencer:sequence_is_start_of_section(p) then
      json = json .. s.sequencer:sequence_section_name(p)
    end
    json = json .. "\",\n        \"Muted Tracks\": ["

    for t = 1, no_of_tracks do
      if s.sequencer:track_sequence_slot_is_muted(t, p) then
        json = json .. " " .. t - 1 .. ","
      end
    end

    if string.sub(json, -1) == "," then
      json = json:sub(1, -2)
    end
    json = json .. " ]\n      },"
  end

  json = json:sub(1, -2)
  json = json .. "\n    ],\n    \"Patterns\": ["

  for p = 1, #s.patterns do
    no_of_lines = s:pattern(p).number_of_lines
    json = json .. "\n      {\n        \"Name\": \"" .. s:pattern(p).name .. "\",\n        \"Length\": " .. no_of_lines .. ",\n        \"Tracks\": ["

    for t = 1, no_of_tracks do
      export_progress("Exporting Pattern " .. p - 1 .. " Track " .. t - 1 .. "...")
      f:write(json)
      json = "" -- clear old data
      json = json .. "\n          {\n            \"Lines\": ["

      for l = 1, no_of_lines do
        json = json .. "\n              {\n                \"Note Columns\": ["
        if (s:track(t).type > 1) then
          json = json .. " ],\n"
        else
          local wnc = write_note_column(s, p, t, l, s:pattern(p):track(t):line(l))
          json = json .. wnc
        end
        json = json .. "                \"Master FX Columns\": ["
        local wmc = write_masterfx_column(s, p, t, l, s:pattern(p):track(t):line(l))
        json = json .. wmc
      end

      if string.sub(json, -1) == "," then
        json = json:sub(1, -2)
      end
      json = json .. "\n            ],\n            \"Automation\": ["
      if #s:pattern(p):track(t).automation == 0 then
        json = json .. " ]"
      else
        local wa = write_automation(s, p, t)
        json = json .. wa
      end
      json = json .. "\n          },"
    end

    if string.sub(json, -1) == "," then
      json = json:sub(1, -2)
    end
    json = json .. "\n        ]\n      },"
  end

  json = json:sub(1, -2)
  json = json .. "\n    ]\n  }\n]"
  f:write(json)
  f:close()
  export_progress("Finished exporting song data to .json file.")
  ready = true
  process:stop()
end

-- write note column

function write_note_column(s, p, t, l, line)
  local json = ""
  
  for c = 1, s:track(t).visible_note_columns do
    if not line.note_columns[c].is_empty then
      json = json .. "\n                  {\n                    \"Note\": \"" .. line:note_column(c).note_string .. "\",\n                    \"Instrument\": " .. line:note_column(c).instrument_value .. ",\n                    \"Volume\": \"" .. line:note_column(c).volume_string .. "\",\n                    \"Panning\": \"" .. line:note_column(c).panning_string .. "\",\n                    \"Delay\": " .. line:note_column(c).delay_value .. ",\n                    \"Local FX Effect\": \"" .. line:note_column(c).effect_number_string .. "\",\n                    \"Local FX Value\": " .. line:note_column(c).effect_amount_value .. "\n                  },"
    else
     json = json .. "\n                  {\n                    \"Note\": \"---\",\n                    \"Instrument\": 255,\n                    \"Volume\": \"..\",\n                    \"Panning\": \"..\",\n                    \"Delay\": 0,\n                    \"Local FX Effect\": \"00\",\n                    \"Local FX Value\": 0\n                  },"
    end
  end

  json = json:sub(1, -2)
  json = json .. "\n                ],\n"
  return json
end

-- write master fx column

function write_masterfx_column(s, p, t, l, line)
  local json = ""

  for c = 1, s:track(t).visible_effect_columns do
    if not line.effect_columns[c].is_empty then
      json = json .. "\n                  {\n                    \"Effect\": \"" .. line:effect_column(c).number_string .. "\",\n                    \"Value\": " .. line:effect_column(c).amount_value .. "\n                  },"
    else
      json = json .. "\n                  {\n                    \"Effect\": \"00\",\n                    \"Value\": 0\n                  },"
    end
  end

  if s:track(t).visible_effect_columns > 0 then
    json = json:sub(1, -2)
    json = json .. "\n                ]\n"
  else
    json = json .. " ]\n"
  end
  json = json .. "              },"
  return json
end

-- write automation

function write_automation(s, p, t)
  local json = ""

  for _, a in pairs(s:pattern(p):track(t).automation) do
    json = json .. "\n              {\n                \"Device\": \"" .. a.dest_device.display_name .. "\",\n                \"Parameter\": \"" .. a.dest_parameter.name .. "\",\n                \"Play Mode\": " .. a.playmode - 1 .. ",\n               \"Points\": ["

    for _, point in pairs(a.points) do
      json = json .. "\n                  {\n                    \"Line\": " .. math.floor(point.time - 1) .. ",\n                    \"Delay\": " .. (point.time - math.floor(point.time)) * 256 .. ",\n                    \"Value\": " .. point.value .. ",\n                    \"Scaling\": " .. point.scaling .. "\n                  },"
    end

    json = json:sub(1, -2)
    json = json .. "\n                ]\n              },"
  end

  json = json:sub(1, -2)
  json = json .. "\n            ]"
  return json
end

--------------------------------------------------------------------------------
-- menu entry
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Export To Unreal",
  invoke = function()
    if not the_gui or not the_gui.visible then
      get_dir_and_file()
      vb.views.export_progress.text = "Export Progress"
      the_gui = renoise.app():show_custom_dialog("Export To Unreal", dialog_content)
      if not renoise.tool().app_new_document_observable:has_notifier(song_loaded) then
        renoise.tool().app_new_document_observable:add_notifier(song_loaded)
      end
    end
  end
}

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
dialog_content = vb:column {
  margin = DEFAULT_MARGIN,

  vb:column {
    style = "group",
    width = 310,
    margin = DEFAULT_MARGIN,

    vb:text {
      text = "Destination",
      width = "100%",
      align = "center",
      font = "bold"
    },

    vb:horizontal_aligner {
      width = "100%",

      vb:button {
        text = "Browse",
        width = 60,
        notifier = function()
                     if ready then
                       local tempdir = renoise.app():prompt_for_path("Browse For Folder")
                       if tempdir ~= "" then shorten_dir(tempdir) end
                     end
                   end
      },

      vb:column {
        id = "dir_tooltip",
        tooltip = "",

        vb:text {
          id = "export_path",
          text = "",
        },
      },
    },

    vb:space { height = 4 },
    vb:textfield {
      id = "export_filename",
      text = "",
      width = "100%",
      notifier = function()
                   if vb.views.export_filename.text == "" then vb.views.export_filename.text = "Untitled" end
                 end
    },
  },

  vb:space { height = 10 },
  vb:horizontal_aligner {
    width = "100%",
    mode = "justify",

    vb:button {
      text = "Start", 
      width = "16%",
      height = 36,
      pressed = function()
                  if ready then
                    if (vb.views.export_path.text == "Please select a directory to save to...") then
                      renoise.app():show_warning("Please select a directory to save to.")
                    else
                      doc.doc_directory.value = vb.views.dir_tooltip.tooltip  -- in case the user just uses
                      doc:save_as("preferences.xml")                          -- the song's path without browsing
                      process = ProcessSlicer(export_song_data, vb.views.dir_tooltip.tooltip, vb.views.export_filename.text)
                      process:start() -- process slicing for main exporting code so the GUI has time to apply text updates
                    end
                  end
                end
      },

      vb:column {
        style = "border",
        width = "82%",
        
        vb:text {
          id = "export_progress",
          text = "Export Progress",
          align = "center",
          height = 36,
          width = "100%",
        },
      },
    },
  vb:space { height = 4 },
}
