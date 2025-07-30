class "CclCollection"

function CclCollection:__init (eval)
   self.coll = { }
   self.eval = eval
end

function CclCollection:err (msg)
   if (self.eval ~= nil) then
      self.eval:err (msg)
   else
      error (msg)
   end
end

function CclCollection:add_selection ()
   for_selected_lines (function (pos, line)
      self:touch_track (pos.track)
      self:add_track_line (pos.track, line)
   end)
end

function CclCollection:touch_track (trackidx, clear_flag)
   if ((clear_flag ~= nil and clear_flag) or self.coll[trackidx] == nil) then
      self.coll[trackidx] = {
         i = trackidx,
         name = renoise.song ():track (trackidx).name,
      }
   end
end

function CclCollection:add_track_line (trackidx, line)
   local new_line = CclLine (trackidx)
   new_line:from_line (line)
   table.insert (self.coll[trackidx], new_line)
end

function CclCollection:append_reversed_track (trackidx, track)
   if (self.coll[trackidx] == nil) then
      self:touch_track (trackidx)
   end

   for _, l in ipairs (track) do
      -- no clone here, because we should clone before changing
      table.insert (self.coll[trackidx], 1, l)
   end
end

function CclCollection:append_track (trackidx, track)
   if (self.coll[trackidx] == nil) then
      self:touch_track (trackidx)
   end

   for _, l in ipairs (track) do
      -- no clone here, because we should clone before changing
      table.insert (self.coll[trackidx], l)
   end
end

function CclCollection:append_track_empty (trackidx, n)
   if (self.coll[trackidx] == nil) then
      self:touch_track (trackidx)
   end

   for i = 1, n do
      table.insert (self.coll[trackidx], CclLine (trackidx))
   end
end

function CclCollection:remove_track (trackidx)
   self.coll[trackidx] = nil
end

function CclCollection:track (trackidx)
   return self.coll[trackidx]
end

function CclCollection:get_track_line (trackidx, lineidx)
   local trk = self.coll[trackidx]
   if (trk == nil) then
      return CclLine (trackidx)
   end
   if (lineidx <= 0 or lineidx > #trk) then
      return CclLine (trackidx)
   end
   return trk[lineidx]
end

function CclCollection:foreach_track (func)
   for i, track in pairs (self.coll) do
      func (i, track)
   end
end

function CclCollection:add_track_lines (pattern, track, from, to)
   self:touch_track (track)

   for i = from, to do
      self:add_track_line (track,
         renoise.song():pattern(pattern):track(track):line(i))
   end
end

function CclCollection:add_clip (name)
   local c_clip
   for _, clip in pairs (CLIPS) do
      if (clip.name == name) then
         c_clip = clip
      end
   end
   if (c_clip == nil) then
      self:err ("Clip " .. name .. " does not exist!")
   end

   local pos = c_clip.start
   self:add_track_lines (
      pos.pattern, pos.track, pos.line, (pos.line + c_clip.lines) - 1)

   local main_track = renoise.song():track(pos.track)
   if (main_track.type == renoise.Track.TRACK_TYPE_GROUP) then
      local cnt_members = #main_track.members
      for i = 1, #main_track.members do
         local mem_trk_idx = pos.track - i
         self:add_track_lines (
            pos.pattern, mem_trk_idx, pos.line, (pos.line + c_clip.lines) - 1)
      end
   end
end

function CclCollection:clone ()
   local clone = CclCollection (self.eval)
   for i, trk in pairs (self.coll) do
      local new_trk = { i = trk.i, name = trk.name }
      clone.coll[i] = new_trk

      for i, l in ipairs (trk) do
         new_trk[i] = l:clone ()
      end
   end
   return clone
end

function CclCollection:write (selected_tracks, patterns)
   for _, track in pairs (selected_tracks) do
      local track_lines = self.coll[track.idx]
      if (not track_lines) then
         track_lines = { }
      end
      local i = 1

      for _, pattern in ipairs (patterns) do
         for pos, pattern_line in renoise.song().pattern_iterator:lines_in_pattern_track(pattern.idx, track.idx) do
            local line = track_lines[i]
            if (line == nil) then
               pattern_line:clear ()
            else
               line:write (i, pattern.pattern, pattern_line)
            end
            i = i + 1
         end
      end
   end
end

function CclCollection:write_selection ()
   for_selected_lines (function (pos, pattern_line, i, is_first, pattern)
      local track_lines = self.coll[pos.track]
      if (track_lines ~= nil) then
         local line = track_lines[i]
         if (line ~= nil) then
            line:write (pos.line, renoise.song().selected_pattern, pattern_line)
         else
         print ("CLEAR " .. i .. "," .. pos.line .. ":" .. pos.track)
            pattern_line:clear ()
         end
      end
   end)
end

function CclCollection:debug_dump ()
   local s = ""
   table_for_idx_ordered (self.coll, function (i, trk)
      s = s .. string.format ("**** %s [%d] (%d) ****\n", trk.name, i, #trk)
      for i, l in ipairs (trk) do
         s = s .. string.format ("%4d:%s\n", i, l:debug_dump ())
      end
   end)
   return s
end

function trk_apply_offs (track, offs)
   offs = math.floor (offs)
   if (offs < 0) then
      for i = 1, -offs do
         table.remove (track, 1)
      end
   elseif (offs > 0) then
      for i = 1, offs do
         table.insert (track, 1, CclLine (track.i))
      end
   end
end

function CclCollection:align (n, offs, pos)
   local new_coll = self:clone ()

   if (pos == "top") then
      for _, track in pairs (new_coll.coll) do
         local p = 0
         p = p + offs
         trk_apply_offs (track, p)
      end

   elseif (pos == "bottom") then
      for _, track in pairs (new_coll.coll) do
         local p = n - #track
         p = p + offs
         trk_apply_offs (track, p)
      end

   elseif (pos == "middle") then
      for _, track in pairs (new_coll.coll) do
         local p = n - #track
         p = p / 2
         p = p + offs
         trk_apply_offs (track, p)
      end
   else
      self:err ("align: unknown mode: " .. pos)
   end

   return new_coll
end

function CclCollection:append_looped (mode, n, src_coll)
   if (mode == "clone") then
      local collection = src_coll (self.eval)
      for i, track in pairs (collection.coll) do
         while (self.coll[i] == nil or #self.coll[i] < n) do
            self:append_track (i, track)
         end
      end

   else -- mode == repeat
      local too_short = true
      while (too_short) do
         too_short = false

         local collection = src_coll (self.eval)
         for i, track in pairs (collection.coll) do
            if (self.coll[i] == nil or #self.coll[i] < n) then
               self:append_track (i, track)
               too_short = true
            end
         end
      end
   end
end

function CclCollection:append (src_coll)
   for i, track in pairs (src_coll.coll) do
      self:append_track (i, track)
   end
end

function CclCollection:merge (src_coll)
   for i, track in pairs (src_coll.coll) do
      if (#track > 0) then
         self:touch_track (i, true)
         self:append_track (i, track)
      end
   end
end

function CclCollection:adjust_length (n)
   local new_coll = self:clone ()

   for i, track in pairs (new_coll.coll) do
      if (#track > n) then
         while (#track > n) do
            table.remove (track)
         end
      elseif (#track < n) then
         while (#track < n) do
            table.insert (track, CclLine (i))
         end
      end
      if (#track == 0) then
         new_coll.coll[i] = nil
      end
   end

   return new_coll
end

function CclCollection:reverse ()
   local new_coll = CclCollection (self.eval)
   for i, track in pairs (self.coll) do
      new_coll:append_reversed_track (i, track)
   end
   return new_coll
end

function CclCollection:remove_track_lines (tracknr, kill_lines)
   if (#kill_lines <= 0) then
      return
   end

   local track = self.coll[tracknr]
   if (track == nil) then
      return
   end

   for i = #kill_lines, 1, -1 do
      table.remove (track, kill_lines[i])
   end

   if (#track == 0) then
      self.coll[tracknr] = nil
   end
end

class "CclLine"

function CclLine:__init (trackidx)
   self.track = trackidx
   self.nc  = { } -- note columns
   self.xc  = { } -- fx columns
   self.atm = { } -- automation data
end

function CclLine:from_line (line)
   for i, c in ipairs (line.note_columns) do
      if (not c.is_empty) then
         self.nc[i] = {
            c.note_value, c.instrument_value, c.volume_value,
            c.panning_value, c.delay_value
         }
      end
   end
   for i, c in ipairs (line.effect_columns) do
      if ((not c.is_empty) and c.number_string:sub (1, 1) ~= "Y") then
         self.xc[i] = { c.number_value, c.amount_value }
      end
   end
end

CCL_N_LINE_EMPTY  = { 121, 0, 0xff, 0xff, 0 }
CCL_FX_LINE_EMPTY = { 0, 0 }

function CclLine:note_col (col, idx, new_val)
   local c = self.nc[col]

   if (new_val ~= nil) then
      if (c == nil) then
         self.nc[col] = table_shallow_clone (CCL_N_LINE_EMPTY)
      end
      self.nc[col][idx] = new_val
      return new_val
   end

   if (c == nil) then
      return CCL_N_LINE_EMPTY[idx]
   end
   return c[idx]
end

function CclLine:fx_col (col, idx, new_val)
   local c = self.xc[col]

   if (new_val ~= nil) then
      if (c == nil) then
         self.xc[col] = table_shallow_clone (CCL_FX_LINE_EMPTY)
      end
      self.xc[col][idx] = new_val
      return new_val
   end

   if (c == nil) then
      return CCL_FX_LINE_EMPTY[idx]
   end
   return c[idx]
end

function CclLine:clone ()
   local clone = CclLine (self.track)
   clone.nc  = { }
   clone.xc  = { }
   clone.atm = { }
   for i, v in pairs (self.nc) do
      clone.nc[i] = v
   end
   for i, v in pairs (self.xc) do
      clone.xc[i] = v
   end
   for i, v in pairs (self.atm) do
      -- XXX: this is ok, automation is never adjusted (hopefully :)
      clone.atm[i] = v
   end
   return clone
end

function CclLine:apply_automation (atm)
   table.insert (self.atm, atm)
end

function CclLine:write (line_idx, pattern, pattern_line)
   pattern_line:clear ()

   for i, v in pairs (self.nc) do
      local nc = pattern_line:note_column(i)
      nc.note_value       = v[1]
      nc.instrument_value = v[2]
      nc.volume_value     = v[3]
      nc.panning_value    = v[4]
      nc.delay_value      = v[5]
   end

   for i, v in pairs (self.xc) do
      local xc = pattern_line:effect_column(i)
      xc.number_value = v[1]
      xc.amount_value = v[2]
   end

   for _, atm in ipairs (self.atm) do
      -- find
      local ptrack = pattern:track (self.track)
      local autom = ptrack:find_automation (atm.param)
      if (autom == nil) then
         autom = ptrack:create_automation (atm.param)
      end

      -- clear
      for _, pt in ipairs (autom.points) do
         if (math.floor (pt.time) == line_idx) then
            autom:remove_point_at (pt.time)
         end
      end

      -- write
      for _, pt in ipairs (atm) do
         autom:add_point_at (line_idx + pt[1], pt[2])
      end
   end
end

function CclLine:debug_dump ()
   local s = ""

   local empty = true
   table_for_idx_ordered (self.nc, function (i, v)
      s = s ..
         string.format (" [%d: %-4s %02x %04x %04x %02x]",
            i, num2note (v[1]), v[2], v[3], v[4], v[5])
      empty = false
   end)

   table_for_idx_ordered (self.xc, function (i, v)
      s = s .. string.format (" {%d: %02x %02x}", i, v[1], v[2])
      empty = false
   end)

   table_for_idx_ordered (self.atm, function (i, atm)
      s = s .. string.format (" (%s:", atm.param.name)
      -- write
      for _, a in ipairs (atm) do
         s = s .. string.format (" %6.4f=%7.5f", a[1], a[2])
      end
      s = s .. ")"
      empty = false
   end)

   if (empty) then
      s = s .. " <empty>"
   end

   return s
end
