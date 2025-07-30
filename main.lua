--[[============================================================================
com.elmex.Pianolol.xrnx/main.lua
============================================================================]]--

require 'scale_scalefinder'
require 'scale_util'

renoise.tool():add_menu_entry {
   name = "--- Pattern Editor:Melody Editor...",
   invoke = function() show_dialog() end
}

SCALE = 1
ROOT  = 4

snames = { }
for key, scale in ipairs (scales) do
  table.insert (snames, scale['name'])
end

function get_selected_notes()
   local pattern_iter  = renoise.song().pattern_iterator
   local pattern_index = renoise.song().selected_pattern_index
   local lines, min, max =
         {},    200, 0 -- 200 > 120, 121 note_value!

   -- print "start"
   for pos,line in pattern_iter:lines_in_pattern(pattern_index) do
      local cols
      if (lines[pos.line] == nil) then
         lines[pos.line] = { }
      end

      cols = lines[pos.line]

      -- print ("LINE " .. pos.line .. " : " .. pos.track .. " : " .. table.count (line.note_columns))
      -- collect selected cols
      for i=1, table.count (line.note_columns) do
         if (line.note_columns[i].is_selected) then
            local nval = line.note_columns[i].note_value

            if (nval < 120) then
               if (nval < min) then min = nval; end
               if (nval > max) then max = nval; end
               table.insert (cols, { pos.track, i, line.note_columns[i] })
            end
         end
      end
   end
   -- print "end"

   return { min, max, lines }
end
-- show_dialog

function octaves_to_notes(min, max, scale)
   if (min > 0) then
      min = min - 1
   end
   if (max < 9) then
      max = max + 1
   end

   if (max > 9) then max = 9; end

   local notes = {}

   local first_note = min * 12 + 4
   local last_note  = max * 12 + 15

   for val = first_note, last_note do
      table.insert (notes, {
         val,
         get_nname (val),
         num2note (get_note_value (val), "\n"),
         scale[get_note (val)],
         BLACKS[get_note (val)],
         get_note (val) == ROOT
      })
   end

   return notes
end

function get_note_color(note, selected)
   local values = { 255, 127 }
   local value = values[1]

   if (selected) then
      local value = 255
      if (note[4]) then
         if (note[6]) then
            return { value, value, 1 }
         else
            return { 1, value, 1 }
         end
      else
         return { value, 1, 1 }
      end
   else
      local value = 60
      if (note[5]) then
         value = 30
      end
      local green_value = value + 10
      if (note[4]) then
         return { value, green_value, value }
      else
         return { green_value, value, value }
      end
   end
end

function update(vb, vbo)
   local lines = get_selected_notes ()
   local min   = lines[1]
   local max   = lines[2]
   lines       = lines[3]

   local min_oct, max_oct =
         math.floor (min / 12),
         math.floor (max / 12)

   local scale     = get_scale (ROOT, scales[SCALE])
   local oct_notes = octaves_to_notes (min_oct, max_oct, scale)
   local hdr, nts =
         {},  {}

   local row_fmt = "%03d | %02d/%01d"

   vbo.lines = lines;

   table.insert (hdr, vb:text { text = string.format (row_fmt, 0, 0, 0) })
   table.insert (hdr, vb:text { text = "p\no\ns" })
   for _,n in ipairs (oct_notes) do
      local style, keyclr = { 255, 1, 1 }, { 255, 255, 255 }
      if (n[4]) then
         if (n[6]) then
            style = { 255, 255, 1 }
         else
            style = { 1, 255, 1 }
         end
      end
      if (n[5]) then
         keyclr = { 1, 1, 1 }
      end
      table.insert (hdr, vb:column {
         vb:text   { text = n[3] },
         vb:button { color = style },
         vb:button { color = keyclr }
      })
   end

   vbo.PLAY_POS_ROWS = {}
   vbo.PAT_IDX = renoise.song().selected_pattern_index

   for line_no,l in ipairs (lines) do
      local column = {}

      for ic,col in ipairs (l) do
         local ext_trk_nr = col[1]
         local ext_col_nr = col[2]
         local ext_col    = col[3]

         local ppos = vb:button { color = { 1, 1, 1} }
         local but_items = {
            vb:text { text = string.format (row_fmt, line_no - 1, ext_trk_nr, ext_col_nr) },
            ppos
         }

         table.insert (vbo.PLAY_POS_ROWS, { line_no, ppos })

         for k, note in ipairs (oct_notes) do
            local ext_i    = k
            local ext_note = note

            local sel_color =
               get_note_color (ext_note,
                               get_note_value (ext_note[1]) == ext_col.note_value)

            table.insert (but_items, vb:button {
               color = sel_color,
               notifier = function ()
                  vbo.IGN_CHANGES = 1

                  for i, b in ipairs (but_items) do
                     if (i ~= 1 and i ~= 2 and (i - 2) ~= ext_i) then
                        but_items[i].color = get_note_color (oct_notes[i - 2], false)
                     end
                  end

                  ext_col.note_value = get_note_value (ext_note[1])
                  but_items[ext_i + 2].color = get_note_color (ext_note, true)
                  vbo.IGN_CHANGES = 0
               end
            })
         end

         table.insert (column, vb:row (but_items))
      end

      if (table.count (column) > 0) then
         table.insert (nts, vb:column (column))
      end
   end

   nts["spacing"] = 5

   if (vbo.HDR_CHLD ~= nil) then
      vbo.MAIN_COL:remove_child (vbo.HDR_CHLD)
   end
   if (vbo.NTS_CHLD ~= nil) then
      vbo.MAIN_COL:remove_child (vbo.NTS_CHLD)
   end

   vbo.HDR_CHLD = vb:row (hdr)
   vbo.NTS_CHLD = vb:column (nts)

   vbo.MAIN_COL:add_child (vbo.HDR_CHLD)
   vbo.MAIN_COL:add_child (vbo.NTS_CHLD)
   vbo.MAIN_COL:resize ()

   init_pattern_notifier ()
end

function update_play_pos (vb, vbo)
   local pos = renoise.song().transport.playback_pos

   local last_btn
   for _,btn in ipairs (vbo.PLAY_POS_ROWS) do
      btn[2].color = { 1, 1, 1 }
      if (btn[1] <= pos.line) then
         last_btn = btn
      end
   end

   -- catch all columns:
   local pat_nr = renoise.song().sequencer:pattern(pos.sequence)
   if (vbo.PAT_IDX == pat_nr and last_btn ~= nil) then
      for _,btn in ipairs (vbo.PLAY_POS_ROWS) do
         if (btn[1] == last_btn[1]) then
            btn[2].color = { 255, 255, 255 }
         end
      end
   end
end

function transpose(offs, vbo)
  vbo.IGN_CHANGES = 1
   for _,l in ipairs (vbo.lines) do
      for ic,col in ipairs (l) do
         local ncol = col[3]
         if (ncol.note_value ~= nil) then
            if (ncol.note_value < 120) then
               local val = ncol.note_value

               val = val + offs;

               if (val < 0) then
                  val = 0
               elseif (val > 119) then
                  val = 119
               end

               ncol.note_value = val
            end
         end
      end
   end
   vbo.IGN_CHANGES = 0
end

------------------------------------------------------------------------

EVENT_RECEIVERS = {}
SEL_PAT = nil
PATTERN_CHANGED = false

function timer_update ()
   for i,recv in ipairs (EVENT_RECEIVERS) do
      if (not recv.vb.visible) then
         table.remove (EVENT_RECEIVERS, i)
         timer_update () -- re-iterate over changed table!
         return
      end

      recv.update (PATTERN_CHANGED)
   end
   PATTERN_CHANGED = false
end

renoise.tool():add_timer (timer_update, 100)

function pattern_changed ()
   PATTERN_CHANGED = true
end

function remove_old_line_notifier ()
   if (SEL_PAT ~= nil) then
      SEL_PAT:remove_line_notifier (pattern_changed)
   end
end

function update_selected_pattern ()
   pcall (remove_old_line_notifier)
   SEL_PAT = renoise.song().selected_pattern
   SEL_PAT:add_line_notifier (pattern_changed)
end

function init_pattern_notifier ()
   if (renoise.app().current_song ~= nil) then
      if (renoise.song().selected_pattern_observable:has_notifier (update_selected_pattern)) then
         renoise.song().selected_pattern_observable:remove_notifier (update_selected_pattern)
      end
      renoise.song().selected_pattern_observable:add_notifier (update_selected_pattern)
      update_selected_pattern ()
   end
end

------------------------------------------------------------------------

function show_dialog()
   local vb = renoise.ViewBuilder()

   local vbo = {
      MAIN_COL = vb:column {},
   }

   local refresh_btn =
      vb:button {
        text = "Refresh",
        notifier = function () update (vb, vbo) end
      }

   local dialog_title = "Pianolol Melody Editor"
   local dialog_content = vb:column {
      vb:row {
         vb:row {
           spacing = 5,
           margin = 5,
           style = 'group',
           vb:text { text = 'Key:' },
           vb:popup {
             items = notes,
             value = ROOT,
             notifier = function (i) ROOT = i; update(vb, vbo) end
           },
           vb:text { text = ' Scale:' },
           vb:popup {
             items = snames,
             value = SCALE,
             notifier = function (i) SCALE = i; update(vb, vbo) end
           },
         },
         vb:row {
           spacing = 5,
           margin = 5,
           style = 'group',
           vb:text { text = 'Transpose: ' },
           vb:button {
             text = "-12",
             notifier = function () transpose (-12, vbo); update (vb, vbo) end
           },
           vb:button {
             text = "-1",
             notifier = function () transpose (-1, vbo); update (vb, vbo) end
           },
           vb:button {
             text = "+1",
             notifier = function () transpose (1, vbo); update (vb, vbo) end
           },
           vb:button {
             text = "+12",
             notifier = function () transpose (12, vbo); update (vb, vbo) end
           },
         },
         refresh_btn
      },
      vbo.MAIN_COL
   }

   update (vb, vbo)

   local diag = renoise.app():show_custom_dialog(dialog_title, dialog_content)

   table.insert (EVENT_RECEIVERS, {
      vb = diag,
      update = function (pat_changed)
         if (pat_changed) then
            if (not vbo.IGN_CHANGES) then
               update (vb, vbo)
            end
            return
         end
         update_play_pos (vb, vbo)
      end
   })
end
