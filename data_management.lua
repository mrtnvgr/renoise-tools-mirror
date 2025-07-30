--[[============================================================================
com.elmex.ClipComposingLanguage.xrnx/data_management.lua
============================================================================]]--

require 'serializer'

--[[============================================================================
CLIP PART
============================================================================]]--

CLIPS = {}

local CLIPS_DIRTY  = 1
local CLIPS_STATIC = nil
local CLIPARR_INSTRUMENT_NAME = "NO ACCESS: ClipComposingLanguage Data"

-- Creates a new clip id
function find_new_clip_id ()
   for i = 1,9000 do
      if (CLIPS[i] == nil) then
         return i
      end
   end
   error ("Ouch, you ran out of clips. This is bad! :)")
end

-- Updates the CLIPS data from pattern
function update_clips ()
   if (CLIPS_DIRTY) then
--      local diag =
--         show_message (
--            "Please wait!", "Going to fetch clip marks from song. This may take a while...")

      if (not CLIPS_STATIC) then
         local db = InstrumentDB (CLIPARR_INSTRUMENT_NAME)
         CLIPS_STATIC = db:get ()
      end

      find_clips ()

      CLIPS_DIRTY = false
   end
end

-- Mark CLIPS dirty, so that it is updated
function touch_clips (kill_static)
   CLIPS_DIRTY = true
   if (kill_static) then
      CLIPS_STATIC = nil
   end
end

-- Synchronizes changes in a clip, should update the static data too
-- TODO: Check if performance is okay
function sync_clip (clip_id)
   local clip = CLIPS[clip_id];
   if (clip == nil)  then
      return
   end

   clip.data = serialize_table (clip, {
      "lines",
      "start",
      "data"
   })

   CLIPS_STATIC[clip_id] = clip

   local db = InstrumentDB (CLIPARR_INSTRUMENT_NAME)
   db:set (CLIPS_STATIC)
end

-- Set the starting location of a clip. And create the clip if it does not exist.
function set_clip_start (clip_id, start_pos)
   local clip = CLIPS[clip_id]

   start_pos = clone_pos (start_pos)

   if (clip == nil) then
      if (CLIPS_STATIC[clip_id]) then
         clip = CLIPS_STATIC[clip_id]
         clip.start = start_pos
         clip.lines = 1
      else
         clip = {
            id      = clip_id,
            name    = renoise.song():track(start_pos.track).name,
            start   = clone_pos (start_pos),
            lines   = 1,
         }
      end

      CLIPS[clip_id] = clip
   else
      clip.start = start_pos
      clip.lines = 1
   end
end

-- Set end location of a clip
function set_clip_end (clip_id, latest_pos)
   -- if no clip exists: ignore, otherwise update if latest_pos is ok (see find_clips())
   local clip = CLIPS[clip_id]
   if (clip == nil) then
      return nil
   end

   if (clip.start.pattern == latest_pos.pattern
       and clip.start.track == latest_pos.track
       and clip.start.line < latest_pos.line)
   then
      local new_lines = (latest_pos.line - clip.start.line) + 1
      -- XXX: the clip.lines < new_lines check is a vague assertion, might be buggy!
      if (clip.lines == nil or clip.lines < new_lines) then
         clip.lines = new_lines
      end
   end

end

-- Fetches the clip positions from the pattern
function find_clips ()
   local pattern_iter = renoise.song().pattern_iterator
   CLIPS = {}

   local cnt_lines, cnt_cols = 0, 0
   for pos, line in pattern_iter:lines_in_song (true) do
      cnt_lines = cnt_lines + 1
     for col_idx, fx_column in pairs (line.effect_columns) do
 -- FIXME: I would love to limit this to visible fx columns. but this method is too slow:
 --      if (col_idx <= renoise.song():track(pos.track).visible_effect_columns) then
         cnt_cols = cnt_cols + 1
          if (fx_column.number_string:sub (1, 1) == "Y") then

            local id   = fx2id (fx_column)
            local clip = CLIPS[id]
            if (clip == nil) then
               set_clip_start (id, pos)
            else
               set_clip_end (id, pos)
            end
          end
 --      end
     end
   end
   --d-- print ("ITERATED OVER " .. cnt_lines .. " lines and " .. cnt_cols .. " columns!")
end

-- Iterates over the selected patterntracklines
function for_selected_lines (action)
   local pattern_iter  = renoise.song().pattern_iterator
   local pattern_index = renoise.song().selected_pattern_index
   local sel           = renoise.song().selection_in_pattern
   if (sel == nil) then
      return
   end

   local track = nil
   local first_sel_col = nil
   local i
   local first
   for pos, line in pattern_iter:lines_in_pattern(pattern_index) do
      if (pos.line >= sel.start_line
          and pos.line <= sel.end_line
          and pos.track >= sel.start_track
          and pos.track <= sel.end_track)
      then
         if (track == nil or track ~= pos.track) then
            i = 1
            track = pos.track
            if (first == nil) then
               first = track
            end
         end
         action (pos, line, i, first == pos.track)
         i = i + 1
      end
   end
end

-- Iterates over the selected effect columns
function for_first_selected_track_fx_cols (action)
   local first_sel_col

   for_selected_lines (function (pos, line, i, is_first)
      if (is_first) then
         for col_idx, effect_column in pairs(line.effect_columns) do
            if (effect_column.is_selected) then
               if (first_sel_col == nil) then
                  first_sel_col = col_idx
               end

               if (col_idx == first_sel_col) then
                  action (pos, line, effect_column)
               end
            end
         end
      end
   end)
end

--[[============================================================================
CODE COLLECTION PART
============================================================================]]--

local CCOLL_INSTRUMENT_NAME = "NO ACCESS: ClipComposingLanguage Clip Composer Data"

function config_access (func)
   local db = InstrumentDB (CCOLL_INSTRUMENT_NAME)
   local cfg = db:get_value ()
   func (cfg)
   db:set_value (cfg)
end
