--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/main.lua
============================================================================]]--
require 'data_management'
require 'util'
require 'ccl'

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:CCL Editor...",
   invoke = function() show_dialog() end
}

renoise.tool():add_menu_entry {
   name = "--- Pattern Editor:Make Clip",
   invoke = function() make_clip() end
}

renoise.tool():add_keybinding {
   name = "Pattern Editor:Selection:Make Clip",
   invoke = function (repeated)
      if (not repeated) then -- we ignore soft repeated keys here
         make_clip ()
      end
   end
}

renoise.tool():add_keybinding {
   name = "Global:Tools:Show CCL Editor",
   invoke = function (repeated)
      if (not repeated) then -- we ignore soft repeated keys here
         show_dialog ()
      end
   end
}

local CLIP_ARRANGER_DIALOG   = nil  -- global dialog object, to check if dialog is visible
local CLIP_ARRANGER_DIALOG_O = nil  -- global support object, to mess with the gui at runtime

local CURRENT_SONG = nil

-- This function is a GUI function, that will create a clip-selection
function make_clip ()
   update_clips ()

   -- First find if there is already some clip id in the selection (for extension)
   local id = nil
   for_first_selected_track_fx_cols (function (pos, line, col)
      if (id == nil) then
         id = fx2id (col)
      end
   end)

   -- If no existing clip id, make a new one
   if (id == nil) then
      id = find_new_clip_id ()
   end

   -- And last but not least: put in new clip id in the fx column
   for_first_selected_track_fx_cols (function (pos, line, col)
      id2fx (id, col)
   end)

   -- And dirtify CLIPS, for update
   touch_clips ()

   update_clip_matrix ()
   update_clip_props (id)
end

-- Returns a matrix of selected matrix slots.
function get_selected_pattern_matrix_slots ()

   local patterns = {}
   local tracks   = {}

   local first_sel_pattern = true
   for _,p in ipairs (renoise.song ().sequencer.pattern_sequence) do
      local selected_pattern = false

      for trknum = 1,renoise.song().sequencer_track_count do
         if (renoise.song().sequencer:track_sequence_slot_is_selected (trknum, p)) then
            if (first_sel_pattern) then
               table.insert (tracks, { idx = trknum, track = renoise.song().tracks [trknum] })
            end
            selected_pattern = true
         end
      end


      if (selected_pattern) then
         local patnr = renoise.song().sequencer:pattern (p)
         table.insert (patterns, { idx = patnr, pattern = renoise.song ().patterns[patnr] })
         first_sel_pattern = false
      end
   end

   return tracks, patterns
end

-- Get a part of the existing tracks
function get_tracks_for_matrix (offs, cols)
   local tracks = {}

   for track_index, track in pairs(renoise.song().tracks) do
      if (offs > 0) then
         offs = offs - 1
      elseif (cols > 0) then
         cols = cols - 1
         table.insert (tracks, { idx = track_index, track = track })
      else
         break
      end
   end

   return tracks
end

function get_track_idx_by_track (strack)
   for track_index, track in pairs(renoise.song().tracks) do
      if (track == strack) then
         return track_index
      end
   end
   return nil
end

function get_track_idx_by_name (name)
   for track_index, track in pairs(renoise.song().tracks) do
      if (track.name == name) then
         return track_index
      end
   end
   return nil
end

function get_clip_track_idx (name)
   for _, clip in pairs (CLIPS) do
      if (clip.name == name) then
         return clip.start.track
      end
   end
   return nil
end

-- Get the clip matrix
function get_clip_matrix (tracks)
   update_clips ()

   local matrix = {}

   for _, track in ipairs (tracks) do
      local track_clips = {}
      for _, clip in pairs (CLIPS) do
         if (clip.start.track == track.idx) then
            table.insert (track_clips, clip)
         end
      end
      table.insert (matrix, {
         track = track,
         clips = track_clips
      })
   end

   return matrix
end

-- Execute a click in the clip matrix
function matrix_select_clip (clip_id)
   update_clip_props (clip_id)
end

local last_clip_props_id

-- Update the clip property view
function update_clip_props (clip_id)
   if (not CLIP_ARRANGER_DIALOG_O) then
      return
   end

   update_clips ()
   local vb, vbo = CLIP_ARRANGER_DIALOG_O.vb, CLIP_ARRANGER_DIALOG_O

   if (vbo.clip_props_in ~= nil) then
      vbo.clip_props:remove_child (vbo.clip_props_in)
      vbo.clip_props_in = nil
   end

   if (clip_id == nil
       and last_clip_props_id ~= nil
       and CLIPS[last_clip_props_id] ~= nil)
   then
      clip_id = last_clip_props_id
   end

   if (clip_id == nil) then
      vbo.clip_props:resize ();
      vbo.clip_lbl.text = "?: ?"
      return
   end

   last_clip_props_id = clip_id

   vbo.clip_props_in = vb:column {}
   vbo.clip_props:add_child (vbo.clip_props_in)

   local clip = CLIPS[clip_id]

   if (clip == nil) then
      vbo.clip_props_in:add_child (vb:text { text = "No such clip!" })
      vbo.clip_props:resize ();
      return
   end

   vbo.clip_lbl.text = clip2str (clip)
   vbo.clip_props_in:add_child (vb:row {
      vb:text { text = "Name: " },
      vb:textfield {
         text = clip.name,
         notifier = function (text)
            clip.name = text
            sync_clip (clip_id)
            update_clip_props ()
            update_clip_matrix ()
         end
      },
      vb:text { text = ("Length in Lines: %d"):format (clip.lines) }
   })

   vbo.clip_props:resize ();
end

-- just build the matrix part .)
function build_clip_matrix (vb, row_container, tracks, select_cb, need_addition)
   local matrix = get_clip_matrix (tracks)

   local column_addition = { }

   local col_idx = 1
   for _, col in ipairs (matrix) do
      local my_col_idx = col_idx
      local my_col_track = col.track
      local clip_col = vb:column {
         spacing = 2,
         margin  = 2,
         style   = "border",
         vb:text { text = col.track.track.name },
      }

      for _,clip in ipairs (col.clips) do
         local clip_id = clip.id

         clip_col:add_child (vb:button {
            text = "" .. clip2str (clip),
            notifier = function () select_cb (clip_id, my_col_idx, col.track) end
         })
      end

      if (need_addition) then
         local addcol = vb:column { }
         clip_col:add_child (addcol)
         column_addition[col_idx] = addcol
      end

      row_container:add_child (clip_col)
      col_idx = col_idx + 1
   end

   return column_addition
end

-- Update the clip matrix
function update_clip_matrix (offs)
   if (not CLIP_ARRANGER_DIALOG_O) then
      return
   end

   local vb, vbo = CLIP_ARRANGER_DIALOG_O.vb, CLIP_ARRANGER_DIALOG_O

   if (not offs or offs < 0) then
      offs = 0
   end

   if (vbo.matrix_in ~= nil) then
      vbo.matrix:remove_child (vbo.matrix_in)
   end
   vbo.matrix_in = vb:row {}
   vbo.matrix:add_child (vbo.matrix_in)

   -- build interface:

   local matrix_cols = 12

   vbo.matrix_in:add_child (vb:button {
      text = "<",
      notifier = function ()
         update_clip_matrix (offs - matrix_cols)
      end
   })

   local matrix_tracks = get_tracks_for_matrix (offs, matrix_cols)
   build_clip_matrix (vb, vbo.matrix_in, matrix_tracks, function (clip_id)
      matrix_select_clip (clip_id)
   end)

   vbo.matrix_in:add_child (vb:button {
      text = ">",
      notifier = function ()
         update_clip_matrix (offs + matrix_cols)
      end
   })
   vbo.matrix:resize ()
end

renoise.tool().app_release_document_observable:add_notifier(function()
   close_clip_arranger ()
   touch_clips (true)
end)

function show_message (title, msg, temp)
   local vb = renoise.ViewBuilder()
   local cont = vb:text {
      text = msg
   }
   if (temp) then
      local diag = renoise.app():show_custom_dialog (title, cont)
      diag:show ()
      return diag
   else
      renoise.app():show_custom_prompt (title, cont, { "OK" })
   end
end

local LOG_VIEW

function show_log (log)
   if  (string.match (log, "[^%s]") == nil) then
      return
   end

   if (LOG_VIEW and LOG_VIEW.visible) then
      LOG_VIEW:close ()
      LOG_VIEW = nil
   end
   local vb = renoise.ViewBuilder()
   local save = vb:button {
      text = "Save",
      notifier = function ()
         local fn =
            renoise.app():prompt_for_filename_to_write (
               "txt", "Save Log to Textfile")
         if (fn ~= nil) then
            local f = io.open (fn, "wb")
            if (f ~= nil) then
               f:write (log)
               f:close ()
            end
         end
      end
   }

   local cont = vb:multiline_text {
      text = log,
      font = "mono",
      style = "border",
      width = 600,
      height = 600,
   }

   local vbcol = vb:column {
      save,
      cont
   }
   local diag = renoise.app():show_custom_dialog ("Log", vbcol)
   diag:show ()
   LOG_VIEW = diag
   return diag
end

function close_clip_arranger ()
   if (CLIP_ARRANGER_DIALOG and CLIP_ARRANGER_DIALOG.visible) then
      CLIP_ARRANGER_DIALOG:close ()
   end
end

function run_ccl (text, write_selection)
   parser:init (text)
   local p = parser:p_prog ()

   local lines = 0
   if (write_selection) then
      local sel = renoise.song().selection_in_pattern
      if (sel ~= nil) then
         lines = (sel.end_line - sel.start_line) + 1
      end
   else
      local tracks, patterns = get_selected_pattern_matrix_slots ()
      for _, pattern in pairs (patterns) do
         lines = lines + pattern.pattern.number_of_lines
      end
   end

   ccl_eval:init (text, parser.syms, parser.rsyms, parser.defs, parser.mfunc, lines)
   ccl_eval:init_input ()
   local collection = p (ccl_eval)
   if (write_selection) then
      collection:write_selection ()
   else
      local tracks, patterns = get_selected_pattern_matrix_slots ()
      collection:write (tracks, patterns)
   end
end

function run_test (file)
   local src = io.open (file, "rb")
   local code = src:read ("*all")
   local cmp = io.open (file .. ".res", "rb")
   local result = ""
   if (cmp ~= nil) then
      result = cmp:read ("*all")
   end

   math.randomseed (1)
   ccl_eval.log_str = ""
   local status, err = pcall (run_ccl, code)
   if (err == nil) then
      err = ""
   else
      err = err .. "\n"
   end
   local resstr = err .. ccl_eval.log_str
   if (resstr ~= result) then
      local fail = io.open (file .. ".fail", "wb")
      fail:write (resstr)
      fail:close ()
      return false, "FAIL " .. file .. "\n"
   else
      return true, "OK " .. file .. "\n"
   end
end

function find_automation_parameter (tracknr, devname, paramname)
   local track = renoise.song():track (tracknr)
   if (track == nil) then
      return nil, "No such track."
   end
   local devices = track.devices
   local device
   for devnum = 1, #devices do
      if (devices[devnum].display_name == devname) then
         device = devices[devnum]
         break
      end
   end
   if (device == nil) then
      return nil, "Can't find device."
   end
   local params = device.parameters
   local param
   for parnum = 1, #params do
      if (params[parnum].name == paramname) then
         param = params[parnum]
         break
      end
   end
   if (param == nil) then
      return nil, "Can't find parameter."
   end
   if (not param.is_automatable) then
      return nil, "Parameter is not automatable."
   end
   return param, nil
end

function list_automation_devices ()
   local list = ""

   local tracks = renoise.song().tracks
   for trknum = 1, #tracks do
      local devices = tracks[trknum].devices
      list = list .. "Track " .. trknum .. "\n"
      for devnum = 1, #devices do
         list = list .. "   * " .. devices[devnum].name
                .. "/" .. devices[devnum].display_name .. "\n"
         local params = devices[devnum].parameters
         for parnum = 1, #params do
            list = list .. "     - " .. params[parnum].name
            if (not params[parnum].is_automatable) then
               list = list .. " (not automatable)"
            end
            list = list .. "\n"
         end
      end
   end
   return list
end

-- Show the main dialog!
function show_dialog()
   -- Only one arranger window pls
   if (CLIP_ARRANGER_DIALOG and CLIP_ARRANGER_DIALOG.visible) then
      CLIP_ARRANGER_DIALOG:show ()
      return
   end

   CURRENT_SONG = renoise.app ().current_song

   local vb = renoise.ViewBuilder()

   local vbo = {
      vb         = vb,
      matrix     = vb:row {},
      clip_lbl   = vb:text { text = "?: ?", font = "bold" },
      clip_props = vb:row {},
      scenes     = vb:row {},
   }

   local refresh_btn =
      vb:button {
        text = "Refresh",
        notifier = function ()
            -- Refresh everything!
            touch_clips (true)
            update_clip_props ()
            update_clip_matrix ()
        end
      }

   local code
   config_access (function (cfg) code = cfg.code end)
   local editor = vb:multiline_textfield {
      text = code,
      font = "mono",
      style = "border",
      width = 500,
      height = 450,
   }

   local import_btn = vb:button {
      text = "Import",
      notifier = function ()
         local fn =
            renoise.app():prompt_for_filename_to_read (
               { "txt" }, "Load CCL from Textfile")
         if (fn ~= nil) then
            config_access (function (cfg) cfg.last_import = fn end)
            local f = io.open (fn, "rb")
            if (f ~= nil) then
               editor.text = f:read ("*all")
               f:close ()
            end
         end
      end
   }
   local export_btn = vb:button {
      text = "Export",
      notifier = function ()
         local fn =
            renoise.app():prompt_for_filename_to_write (
               "txt", "Save CCL to Textfile")
         if (fn ~= nil) then
            config_access (function (cfg) cfg.last_import = fn end)
            local f = io.open (fn, "wb")
            if (f ~= nil) then
               f:write (editor.text)
               f:close ()
            end
         end
      end
   }
   local import_last_btn = vb:button {
      text = "Import Last",
      notifier = function ()
         local fn
         config_access (function (cfg) fn = cfg.last_import end)
         if (fn ~= nil) then
            local f = io.open (fn, "rb")
            if (f ~= nil) then
               editor.text = f:read ("*all")
               f:close ()
            end
         end
      end
   }


   local save_btn = vb:button {
      text = "Save",
      notifier = function ()
         config_access (function (cfg) cfg.code = editor.text end)
      end
   }

   local list_devs = vb:button {
      text = "List Devices",
      notifier = function ()
         show_log (list_automation_devices ())
      end
   }

   local exec = vb:button {
      text = "Save & Execute",
      notifier = function ()
         config_access (function (cfg) cfg.code = editor.text end)
         local status, err = pcall (run_ccl, editor.text)
         if (status) then
            show_log (ccl_eval.log_str)
         else
            if (ccl_eval.log_str ~= nil) then
               show_log (err .. "\n\nLog:" .. ccl_eval.log_str)
            else
               show_log (err)
            end
         end
      end
   }

   local execsel = vb:button {
      text = "Save & Exec Selection",
      notifier = function ()
         config_access (function (cfg) cfg.code = editor.text end)
         local status, err = pcall (run_ccl, editor.text, true)
         if (status) then
            show_log (ccl_eval.log_str)
         else
            if (ccl_eval.log_str ~= nil) then
               show_log (err .. "\n\nLog:" .. ccl_eval.log_str)
            else
               show_log (err)
            end
         end
      end
   }

   local test_btn = vb:button {
      text = "Test",
      notifier = function ()
         local log = ""
         local got_err = false
         for line in io.lines ("ccl_main_test.txt") do
            local res, msg = run_test (line)
            log = log .. msg
            if (not res) then
               got_err = true
            end
         end
         if (got_err) then
            log = log .. "*** FAIL ***\n"
         else
            log = log .. "ALL OK\n"
         end
         show_log (log)
      end
   }

   local btnbar_tbl = {
      refresh_btn,
      import_btn,
      export_btn,
      import_last_btn,
      save_btn,
      exec,
      execsel,
      list_devs
   }

   if (code ~= nil and code:sub(1, 7) == "# ELMEX") then
      table.insert (btnbar_tbl, test_btn)
   end

   local btnbar = vb:row (btnbar_tbl)

   local dialog_title = "CCL Editor"
   local dialog_content = vb:column {
      style = "body",
      btnbar,
      editor,
      vb:horizontal_aligner {
         mode = "center",
         vb:column {
            vb:row {
               vb:text { text = "Clip Properties", font = "big" },
               vbo.clip_lbl
            },
            spacing = 5,
            margin = 5,
            style = "group",
            vbo.clip_props
         },
      },
      vb:column {
         vb:text { text = "Clip Matrix", font = "big" },
         spacing = 5,
         margin = 5,
         style = "group",
         vbo.matrix
      }
   }

   CLIP_ARRANGER_DIALOG_O = vbo
   update_clip_matrix ()
   update_clip_props ()

   CLIP_ARRANGER_DIALOG = renoise.app():show_custom_dialog(dialog_title, dialog_content)
end
